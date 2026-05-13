#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AgreeOnChange(Item)
	
	Items.CancelRegistration.Enabled = Agree;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CancelRegistration(Command)
	
	YouCanStartCancelingRegistration = True;
	
	If IntegrationWithCollaborationSystemUsedSaaS Then
		
		CheckResult = CheckPossibilityOfDisablingDatabase();
		
		If Not CheckResult.CanBeDisabled Then
			Message(CheckResult.MessageText);
			YouCanStartCancelingRegistration = False;
			Return;
		EndIf;
		
	EndIf;
	
	If YouCanStartCancelingRegistration Then
		CollaborationSystem.BeginInfoBaseUnregistration(New NotifyDescription("CancellationOfRegistrationCompletion", ThisForm, , "RegistrationCancellationError", ThisForm));
		ThisForm.Enabled = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure Initialize(IntegrationWithInteractionSystemIsUsed) Export
	
	IntegrationWithCollaborationSystemUsedSaaS = IntegrationWithInteractionSystemIsUsed;
	
EndProcedure

&AtClient
Procedure CancellationOfRegistrationCompletion(AdditionalParameters) Export
	
	If IntegrationWithCollaborationSystemUsedSaaS Then
		ReportDatabaseDisconnectionToServiceManager(True);
	EndIf;
	
	NotifyDescription = New NotifyDescription("CancelRegistrationWarning", ThisForm);
	ShowMessageBox(NotifyDescription, NStr("ru = 'Регистрация отменена';
													|en = 'Registration canceled';"));
	
EndProcedure

&AtClient
Procedure CancelRegistrationWarning(AdditionalParameters) Export
	
	Close(1);
	
EndProcedure

&AtClient
Procedure RegistrationCancellationError(ErrorInfo, StandardProcessing, AdditionalParameters) Export
	
	If IntegrationWithCollaborationSystemUsedSaaS Then
		ReportDatabaseDisconnectionToServiceManager(False, ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndIf;

	StandardProcessing = False;
	ShowErrorInfo(ErrorInfo);

	Close(0);
	
EndProcedure

// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//	Structure:
//	 * CanBeDisabled - Boolean
//	 * MessageText - String
//
&AtServer
Function CheckPossibilityOfDisablingDatabase()
	
EndFunction

// @skip-warning EmptyMethod - Implementation feature.
&AtServer
Procedure ReportDatabaseDisconnectionToServiceManager(Success, MessageText = "")
	
EndProcedure

#EndRegion

