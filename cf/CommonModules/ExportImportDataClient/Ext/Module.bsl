#Region Internal

Procedure BeforeStart(Parameters) Export
	
	If Parameters.Cancel Then
		Return;
	EndIf;
	
	StartupOptions = StandardSubsystemsClient.ClientParametersOnStart();
	
	If Not StartupOptions.SeparatedDataUsageAvailable Then
		Return;
	EndIf;
	
	DownloadAborted = False;
	If Not StartupOptions.Property("UnloadingLoadingDataLoadingAborted", DownloadAborted) Then
		 DownloadAborted = CommonServerCallCTL.DownloadAborted(); 
	EndIf;
	
	If Not DownloadAborted Then
		Return;
	EndIf;
		
	Parameters.InteractiveHandler = New NotifyDescription(
		"ShowAbortedBootDialogBeforeStartingSystem",
		ThisObject);

	
EndProcedure

Procedure ShowAbortedDownloadDialogIfNecessary() Export
	
	DownloadAborted = CommonServerCallCTL.DownloadAborted();	
	
	If Not DownloadAborted Then
		Return;	
	EndIf;
	 
	ShowAbortedDownloadDialog();
		
EndProcedure

#EndRegion

#Region Private

Procedure ShowAbortedBootDialogBeforeStartingSystem(Parameters, AdditionalParameters) Export
	ShowAbortedDownloadDialog();
EndProcedure

Procedure ShowAbortedDownloadDialog()

	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.PromptDontAskAgain = False;
	QuestionParameters.Picture = PictureLib.Warning32;
	QuestionParameters.Title = NStr("ru = 'Процедура загрузки была прервана';
										|en = 'Import procedure was interrupted';");
		
	NotifyDescriptionOnCompletion = New NotifyDescription(
		"QuestionAboutInterruptedDownloadCompletion",
		ThisObject);

	StandardSubsystemsClient.ShowQuestionToUser(
		NotifyDescriptionOnCompletion,
		NStr("ru = 'Для продолжения нужно будет снова указать файл, из которого загружались данные.';
			|en = 'To continue, you will need to specify the file from which the data was imported again.';"),
		QuestionDialogMode.OK,
		QuestionParameters);
		
EndProcedure

Procedure QuestionAboutInterruptedDownloadCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = Undefined Then
		Return;
	EndIf;
	
	OpenForm("CommonForm.DataImportFromService",
		New Structure("DownloadProcedureAborted", True),,,,,,
		FormWindowOpeningMode.LockWholeInterface);
		
EndProcedure

#EndRegion