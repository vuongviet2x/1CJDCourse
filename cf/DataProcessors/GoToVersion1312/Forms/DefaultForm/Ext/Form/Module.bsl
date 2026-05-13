///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	UserName = UserName();
	Items.User.InputHint = UserName;
	Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
	ExportFilesToDirectory = 1;
	If UserName = "" Then
		Items.User.Visible = False;
		Items.Password.Visible       = False;
	EndIf;
	
	StartExecutionParametersPreparationInBackground(ThisObject);
	
	VisibleEnabled();
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	VisibleEnabled();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
#If WebClient Or MobileClient Then
	ShowMessageBox(, NStr("ru = 'Запуск в веб-клиенте или в мобильном клиенте невозможен.
		|Запустите тонкий клиент.';
		|en = 'Cannot start in web client or mobile client.
		|Start thin client.';"));
	Cancel = True;
	Return;
#EndIf
	
	CompleteExecutionParametersPreparationInBackground(ThisObject);
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	If Exit Then
		Return;
	EndIf;
	If Not ValueIsFilled(WorkingDirectory) And ValueIsFilled(WorkingDirectory(ThisObject)) Then
		Status(NStr("ru = 'Очистка каталога временных файлов...';
						|en = 'Cleaning up temporary file directory…';"));
		ClearTemporaryDirectory();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// "Module analysis" page.

&AtClient
Procedure ExportFilesToDirectoryOnChange(Item)
	VisibleEnabled();
EndProcedure

&AtClient
Procedure DirectoryOfConfigurationExportToFilesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	ChoiceDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	ChoiceDialog.Title          = NStr("ru = 'Выберите каталог, в который выгружены файлы конфигурации';
											|en = 'Select a directory, to which the configuration files are exported';");
	ChoiceDialog.Directory            = WorkingDirectory(ThisObject);
	ChoiceDialog.Multiselect = False;
	Handler = New NotifyDescription("SelectDirectoryToDumpConfigurationCompletion", ThisObject);
	FileSystemClient.ShowSelectionDialog(Handler, ChoiceDialog);
EndProcedure

&AtClient
Procedure DirectoryOfConfigurationExportToFilesOpen(Item, StandardProcessing)
	StandardProcessing = False;
#If Not WebClient Then
		Directory = WorkingDirectory(ThisObject);
		If Not ValueIsFilled(Directory) Then
			Return;
		EndIf;
		FileSystemClient.OpenExplorer(Directory);
#EndIf
EndProcedure

&AtClient
Procedure DirectoryOfConfigurationExportToFilesOnChange(Item)
	If ValueIsFilled(WorkingDirectory) Then
		WorkingDirectory = AddLastPathSeparator(WorkingDirectory);
	Else
		ExportFilesToDirectory = 1;
	EndIf;
	VisibleEnabled();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Navigate between pages only.

&AtClient
Procedure BackCommand(Command)
	GoToPage(-1);
EndProcedure

&AtClient
Procedure CloseCommand(Command)
	Close();
EndProcedure

// "Integration parameter setup" page.

&AtClient
Procedure Refresh(Command)
	VisibleEnabled();
EndProcedure

&AtClient
Procedure ArrangeCodeSnippets(Command)
	BackgroundJobPercentage   = 0;
	BackgroundJobStatus2 = "";
	GoToPage(+1);
	AttachIdleHandler("RunBackgroundJob1Client", 0.1, True);
EndProcedure

// "Integration end wait" page.

&AtClient
Procedure CancelIntegration(Command)
	GoToPage(-1);
	AttachIdleHandler("StopBackgroundJobClient", 0.1, True);
EndProcedure

// "View integration results" page.

&AtClient
Procedure RunDesigner(Command)
	
#If Not WebClient Then
	
	StartupCommand = New Array;
	StartupCommand.Add(BinDir() + "1cv8.exe");
	StartupCommand.Add("DESIGNER");
	StartupCommand.Add("/IBConnectionString");
	StartupCommand.Add(InfoBaseConnectionString());
	StartupCommand.Add("/N");
	StartupCommand.Add(User);
	StartupCommand.Add("/P");
	StartupCommand.Add(Password);
	
	ApplicationStartupParameters = FileSystemClient.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = False;
	
	FileSystemClient.StartApplication(StartupCommand, ApplicationStartupParameters);
	
#EndIf
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure VisibleEnabled()
	CurrentPage = Items.Pages.CurrentPage;
	
	If CurrentPage = Items.ModulesAnalysisPage Then
		DesignerIsOpen = FormAttributeToValue("Object").DesignerIsOpen();
		
		Items.BackButton.Visible = False;
		
		Items.NextButton.Visible  = True;
		Items.NextButton.CommandName = "ArrangeCodeSnippets";
		Items.NextButton.DefaultButton = Not DesignerIsOpen;
		
		Items.CancelButton.Visible  = True;
		Items.CancelButton.CommandName = "CloseCommand";
		
		Items.DesignerOpenedGroup.Visible   = DesignerIsOpen;
		Items.ConfigurationModifiedGroup.Visible = DataBaseConfigurationChangedDynamically() Or ConfigurationChanged();
		Items.WorkingDirectory.MarkIncomplete = ?(ExportFilesToDirectory, False, Not ValueIsFilled(WorkingDirectory));
		
	ElsIf CurrentPage = Items.WaitForImplementationCompletionPage Then
		Items.BackButton.Visible = False;
		
		Items.NextButton.Visible = False;
		
		Items.CancelButton.Visible  = True;
		Items.CancelButton.CommandName = "CancelIntegration";
		Items.CancelButton.DefaultButton = False;
		
	ElsIf CurrentPage = Items.ViewImplementationResultsPage Then
		Items.BackButton.Visible = False;
		
		Items.NextButton.Visible = True;
		Items.NextButton.CommandName = "RunDesigner";
		Items.NextButton.DefaultButton = Not FormAttributeToValue("Object").DesignerIsOpen();
		
		Items.CancelButton.Visible  = True;
		Items.CancelButton.CommandName = "CloseCommand";
	EndIf;
EndProcedure

&AtClient
Procedure GoToPage(ShiftOrPage)
	If TypeOf(ShiftOrPage) = Type("FormGroup") Then
		Items.Pages.CurrentPage = ShiftOrPage;
	ElsIf TypeOf(ShiftOrPage) = Type("Number") Then
		AvailablePages = Items.Pages.ChildItems;
		IndexOf = AvailablePages.IndexOf(Items.Pages.CurrentPage) + ShiftOrPage;
		If IndexOf < 0 Or IndexOf >= AvailablePages.Count() Then
			Return;
		EndIf;
		Items.Pages.CurrentPage = AvailablePages[IndexOf];
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Некорректное значение параметра ""%1"": ""%2"".';
				|en = 'Incorrect value of the %1 parameter: %2.';"),
			"ShiftOrPage",
			ShiftOrPage);
	EndIf;
	VisibleEnabled();
EndProcedure

&AtClient
Procedure SelectDirectoryToDumpConfigurationCompletion(SelectedFiles, ExecutionParameters) Export
	If TypeOf(SelectedFiles) <> Type("Array") Or SelectedFiles.Count() = 0 Then
		Return;
	EndIf;
	WorkingDirectory = AddLastPathSeparator(SelectedFiles[0]);
	VisibleEnabled();
EndProcedure

&AtClientAtServerNoContext
Function AddLastPathSeparator(Val DirectoryPath)
	If IsBlankString(DirectoryPath) Then
		Return DirectoryPath;
	EndIf;
	
	CharToAdd = GetPathSeparator();
	
	If StrEndsWith(DirectoryPath, CharToAdd) Then
		Return DirectoryPath;
	Else
		Return DirectoryPath + CharToAdd;
	EndIf;
EndFunction

&AtClient
Procedure RunBackgroundJob1Client()
	Job = RunBackgroundJob1();
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	WaitSettings.OutputProgressBar = True;
	WaitSettings.ExecutionProgressNotification = New NotifyDescription("OnUpdateBackgroundJobProgress", ThisObject);
	WaitSettings.Interval = 1;
	
	Handler = New NotifyDescription("AfterCompleteBackgroundJob1", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(Job, Handler, WaitSettings);
EndProcedure

&AtClientAtServerNoContext
Function WorkingDirectory(Form)
	If ValueIsFilled(Form.WorkingDirectory) Then
		Return Form.WorkingDirectory;
	ElsIf StrStartsWith(Form.Items.WorkingDirectory.InputHint, "<") Then
		Return "";
	Else
		Return Form.Items.WorkingDirectory.InputHint;
	EndIf;
EndFunction

&AtServer
Function RunBackgroundJob1()
	CurrentPage = Items.Pages.CurrentPage;
	If CurrentPage <> Items.WaitForImplementationCompletionPage Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Со страницы ""%1"" невозможно запустить длительную операцию';
				|en = 'Cannot start a long-running operation from page %1';"),
			CurrentPage.Name);
	EndIf;
	
	JobParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	JobParameters.WaitCompletion = 0;
	JobParameters.BackgroundJobDescription = Title;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ExportFilesToDirectory", ExportFilesToDirectory);
	ProcedureParameters.Insert("WorkingDirectory",         WorkingDirectory(ThisObject));
	If Items.User.Visible Then
		ProcedureParameters.Insert("User", User);
		ProcedureParameters.Insert("Password",       Password);
	Else
		ProcedureParameters.Insert("User", "");
		ProcedureParameters.Insert("Password",       "");
	EndIf;
	
	ProcedureName = FormAttributeToValue("Object").Metadata().FullName() + ".ObjectModule.Integrate";
	Job = TimeConsumingOperations.ExecuteInBackground(ProcedureName, ProcedureParameters, JobParameters); 
	JobID = Job.JobID;
	Return Job;
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.LongRunningOperationNewState
//  AdditionalParameters - Undefined
//
&AtClient
Procedure OnUpdateBackgroundJobProgress(Result, AdditionalParameters) Export

	If Result.Status = "Running"
	   And Result.Progress <> Undefined Then
		
		BackgroundJobPercentage   = Result.Progress.Percent;
		BackgroundJobStatus2 = Result.Progress.Text;
	EndIf;
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure AfterCompleteBackgroundJob1(Result, AdditionalParameters) Export
	Activate();
	If Result = Undefined Then
		GoToPage(-1);
		Return;
	EndIf;
	If Result.Status = "Completed2" Then
		If Items.Pages.CurrentPage = Items.WaitForImplementationCompletionPage Then
			ImportIntegrationResult(Result.ResultAddress);
		EndIf;
		GoToPage(+1);
	Else
		GoToPage(-1);
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
	EndIf;
EndProcedure

&AtClient
Procedure StopBackgroundJobClient()
	If JobID <> Undefined Then
		StopBackgroundJob(JobID);
		JobID = Undefined;
	EndIf;
EndProcedure

&AtServerNoContext
Procedure StopBackgroundJob(JobID)
	TimeConsumingOperations.CancelJobExecution(JobID);
EndProcedure

&AtServer
Procedure ClearTemporaryDirectory()
	If Not ValueIsFilled(WorkingDirectory) And ValueIsFilled(WorkingDirectory(ThisObject)) Then
		FileSystem.DeleteTemporaryDirectory(WorkingDirectory(ThisObject));
	EndIf;
EndProcedure

&AtServer
Procedure ImportIntegrationResult(ResultAddress)
	Result = GetFromTempStorage(ResultAddress);
	SpreadsheetDocument = Result.SpreadsheetDocument;
EndProcedure

#Region ProcedureExecutionInBackground

&AtServerNoContext
Procedure StartExecutionParametersPreparationInBackground(Form)
	BackgroundExecutionParameters = New Structure("IsExternalDataProcessor, DataProcessorName, DataProcessorAddress, DataProcessorAvailableOnServer");
	
	DataProcessorObject = Form.FormAttributeToValue("Object"); // ExternalDataProcessor, DataProcessorObject.GoToVersion1312
	SubstringsArray = StrSplit(DataProcessorObject.Metadata().FullName(), ".");
	BackgroundExecutionParameters.DataProcessorName = SubstringsArray[1];
	BackgroundExecutionParameters.IsExternalDataProcessor = Lower(SubstringsArray[0]) = Lower("ExternalDataProcessor");
	If BackgroundExecutionParameters.IsExternalDataProcessor Then
		BackgroundExecutionParameters.DataProcessorName = DataProcessorObject.UsedFileName;
		File = New File(DataProcessorObject.UsedFileName);
		BackgroundExecutionParameters.DataProcessorAvailableOnServer = File.Exists();
	Else
		BackgroundExecutionParameters.DataProcessorAvailableOnServer = True;
	EndIf;
	
	Form.BackgroundExecutionParameters = BackgroundExecutionParameters;
EndProcedure

&AtClient
Procedure CompleteExecutionParametersPreparationInBackground(Form)
	BackgroundExecutionParameters = Form.BackgroundExecutionParameters;
	If BackgroundExecutionParameters.IsExternalDataProcessor And Not BackgroundExecutionParameters.DataProcessorAvailableOnServer Then
#If Not WebClient Then
			BackgroundExecutionParameters.DataProcessorAddress = PutToTempStorage(New BinaryData(BackgroundExecutionParameters.DataProcessorName), UUID);
#EndIf
	EndIf;
EndProcedure

#EndRegion

#EndRegion
