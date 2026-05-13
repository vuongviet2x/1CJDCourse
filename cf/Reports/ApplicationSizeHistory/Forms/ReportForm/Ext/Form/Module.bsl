#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ApplicationsSize.CheckSupportForAppSizeCalculation();
	
	UpdateAppSizeGroupVisibility();
	UpdateInformationAboutAppSizeCalculation();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EnableCalculationWaitingHandler();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GenerateReport(Command)
	
	If CalculationIsRunning Or ThereIsDataForGeneratingReport() Then
		
		GenerateReportContinued();
		
	Else
		
		QueryText = NStr("ru = 'Расчет размера приложения не выполнялся.
							|Выполнить сейчас?';
							|en = 'Application size was not calculated.
							|Do you want to calculate it now?';");
		Handler = New NotifyDescription("HandlerForCalculationIssue", ThisObject);
		ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Calculate_ApplicationSize(Command)
	
	If Not AppCalculationIsAvailable() Then
		Raise NStr("ru = 'В неразделенном сеансе недоступен расчет размера приложения';
								|en = 'Application size calculation is not available in a shared session';");
	EndIf;
	
	RunCalculationApplicationSize();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GenerateReportContinued()
	
	GenerateReportAfterPerformingCalculation = False;
	ThisObject.ComposeResult(ResultCompositionMode.Background);
	
EndProcedure

#Region CalculatingApplicationSize

&AtClient
Procedure EnableCalculationWaitingHandler(IncreaseInterval = 0)
	
	If Not CalculationIsRunning Then
		Return;
	EndIf;
	
	WaitingIntervalForCalculation = Max(5 + IncreaseInterval, 300);
	AttachIdleHandler("CheckResultOfApplicationSizeCalculationTask",
		WaitingIntervalForCalculation, True);
	
EndProcedure

&AtClient
Procedure CheckResultOfApplicationSizeCalculationTask()
	
	If ThereIsScheduledJobCalculatingSizeOfApplication() Then
		
		EnableCalculationWaitingHandler(WaitingIntervalForCalculation);
		
	Else
		
		UpdateInformationAboutAppSizeCalculation();
		
		If GenerateReportAfterPerformingCalculation Then
			GenerateReportContinued();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure HandlerForCalculationIssue(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		GenerateReportAfterPerformingCalculation = True;
		RunCalculationApplicationSize();
		
	Else
		
		GenerateReportContinued();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RunCalculationApplicationSize()
	
	If IsSeparatedSession() Then
		
		ScheduleApplicationSizeCalculation();
		EnableCalculationWaitingHandler();
		
	Else
		
		TimeConsumingOperation = StartBackgroundCalculationOfAppSize(ThisForm.UUID);
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisForm);
		IdleParameters.MessageText = NStr("ru = 'Выполняется расчет размера приложения';
												|en = 'Calculating the application size';");
		
		CallbackOnCompletion = New NotifyDescription("CalculatingApplicationSizeCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculatingApplicationSizeCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	 
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	ElsIf Result.Status = "Completed2" Then
		
		UpdateInformationAboutAppSizeCalculation();
		
		If GenerateReportAfterPerformingCalculation Then
			GenerateReportContinued();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function StartBackgroundCalculationOfAppSize(Val FormIdentifier)
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormIdentifier);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Расчет размера приложения';
															|en = 'Calculate application size';");
	ExecutionParameters.BackgroundJobKey = String(New UUID);
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"Reports.ApplicationSizeHistory.CalculateApplicationSize",
		Undefined,
		ExecutionParameters);
	
EndFunction

&AtServer
Procedure ScheduleApplicationSizeCalculation()
	
	ApplicationsSize.ScheduleApplicationSizeCalculation();
	UpdateApplicationCalculationExecution();
	
EndProcedure

#EndRegion

#Region InterfaceUpdate

&AtServer
Procedure UpdateAppSizeGroupVisibility()
	
	CalculationAvailable = AppCalculationIsAvailable();
	Items.ApplicationSizeGroup.Visible = CalculationAvailable;
	
	If Not CalculationAvailable Then
		Return;
	EndIf;
	
	MinimumStepChanges = ApplicationsSize.CalculationSettingValue("MinimumStepChanges", 0);
	If MinimumStepChanges > 0 Then
		
		Items.Calculate_ApplicationSize.ToolTipRepresentation = ToolTipRepresentation.Button;
		Items.Calculate_ApplicationSizeExtendedTooltip.Title = StrTemplate(
			NStr("ru = 'Изменения в размере объекта метаданных меньше %1 Мб не отображаются';
				|en = 'Changes in the metadata object size less than %1 MB are not displayed';"),
			MinimumStepChanges / 1024 / 1024);
		
	Else 
		
		Items.Calculate_ApplicationSize.ToolTipRepresentation = ToolTipRepresentation.None;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateInformationAboutAppSizeCalculation()
	
	UpdateRelevanceOfAppCalculation();
	UpdateApplicationCalculationExecution();
	
EndProcedure

&AtServer
Procedure UpdateApplicationCalculationExecution()
	
	If Not AppCalculationIsAvailable() Then
		Return;
	EndIf;
	
	CalculationIsRunning = ?(IsSeparatedSession(), ThereIsScheduledJobCalculatingSizeOfApplication(), False);

	Items.Calculate_ApplicationSize.Visible = Not CalculationIsRunning; 
	Items.HowApplicationCalculationIsPerformed.Visible = CalculationIsRunning;
	
EndProcedure

&AtServer
Procedure UpdateRelevanceOfAppCalculation()
	
	If Not AppCalculationIsAvailable() Then
		Return;
	EndIf;
	
	DateOfCalculation = ApplicationsSize.RelevanceOfApplicationSizeCalculation();
	InfoRelevanceOfCalculation = ?(ValueIsFilled(DateOfCalculation),
		StrTemplate(NStr("ru = 'Расчет размера приложения выполнен: %1';
						|en = 'Application size is calculated: %1';"), Format(DateOfCalculation, NStr("ru = 'ДФ=dd.MM.yyyy;';
																									|en = 'DF=MM/dd/yyyy;';"))),
		NStr("ru = 'Расчет размера приложения не выполнялся';
			|en = 'Application size was not calculated';"));

EndProcedure

#EndRegion

#Region Other

&AtServerNoContext
Function ThereIsScheduledJobCalculatingSizeOfApplication()
	
	Return ApplicationsSize.ThereIsScheduledJobCalculatingSizeOfApplication();
	
EndFunction

&AtServerNoContext
Function AppCalculationIsAvailable()
	
	If SaaSOperations.DataSeparationEnabled()
		And Not SaaSOperations.SeparatedDataUsageAvailable() Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtServerNoContext
Function IsSeparatedSession()
	
	Return SaaSOperations.DataSeparationEnabled() And SaaSOperations.SeparatedDataUsageAvailable();
	
EndFunction

&AtServerNoContext
Function ThereIsDataForGeneratingReport()
	
	If Not AppCalculationIsAvailable() Then
		Return True;
	EndIf;
	
	DateOfCalculation = ApplicationsSize.RelevanceOfApplicationSizeCalculation();
	Return ValueIsFilled(DateOfCalculation);
	
EndFunction

#EndRegion

#EndRegion
