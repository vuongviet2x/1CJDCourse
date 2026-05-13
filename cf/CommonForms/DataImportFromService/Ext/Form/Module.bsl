///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2019, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.DownloadTheExtensionConfiguration.Visible = Not SaaSOperations.DataSeparationEnabled();
	
	ParallelLoadingOptions = ExportImportDataInternal.ParallelDataExportImportParameters();
	
	If ParallelLoadingOptions.UsageAvailable Then
		ImportDataJobsCount = ParallelLoadingOptions.ThreadsCount;
	Else
		ImportDataJobsCount = 1;
		Items.ParallelLoadingGroup.Visible = False;
	EndIf;
	
	HandleInterruptedBootProcedure();

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(TheHashSumOfTheFile) Then
		OpenFileSelection(
			NStr("ru = 'Для продолжения необходимо повторно загрузить файл';
				|en = 'To continue, import the file again';"));
	EndIf;
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Or Not ValueIsFilled(JobID) Then
		Return;
	EndIf;
	
	Cancel = True;
	NotifyDescription = New NotifyDescription("QuestionBeforeClosingCompletion", ThisObject);
	QueryText = NStr("ru = 'Прервать загрузку данных?';
						|en = 'Do you want to cancel the data import?';");
	ShowQueryBox(
		NotifyDescription,
		QueryText,
		QuestionDialogMode.OKCancel,,
		DialogReturnCode.Cancel);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If RestartProgramAtClosing Then
		RestartApplication();
	Else
		ExportImportDataClient.ShowAbortedDownloadDialogIfNecessary();
	EndIf;
	
EndProcedure


#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OpenActiveUsersForm(Item)
	
	OpenForm("DataProcessor.ActiveUsers.Form.ActiveUsers");
	
EndProcedure

&AtClient
Procedure DecorationWithFramesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	OpenFormHelp();	
	
EndProcedure

&AtClient
Procedure DecorationWithoutFramesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	OpenFormHelp();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CommandContinue(Command)

	CurrentPage = Items.Pages.CurrentPage;
	
	If CurrentPage = Items.PageMain Then
		OpenFileSelection(
			NStr("ru = 'Загрузка файла';
				|en = 'Import file';"));
	ElsIf CurrentPage = Items.ExtensionsPage Then
		CheckingUnloadingModeForTechnicalSupport();
	ElsIf CurrentPage = Items.ErrorWarningPage Then
		Close();
	EndIf;
		
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure RestartApplication()
	Terminate(True);
EndProcedure

&AtServer
Procedure ConfigureWarningsByExtensionsVisibility(Extensions)
	
	DisplayWithoutFrames = Extensions.WithoutFrames.Count() > 0;
	Items.DecorationWithoutFrames.Visible = DisplayWithoutFrames;
	Items.DecorationWithoutFramesBottom.Visible = DisplayWithoutFrames;
	Items.ListWithoutFramesGroup.Visible = DisplayWithoutFrames;
	If Extensions.WithoutFrames.Count() > 0 Then
		
		Items.DecorationListWithoutFrames.Title = StrConcat(Extensions.WithoutFrames, Chars.LF);
		
	EndIf;
		
	DisplayWithFrames = Extensions.WithFrames.Count() > 0;
	Items.DecorationWithFrames.Visible = DisplayWithFrames;
	Items.FramesListGroup.Visible = DisplayWithFrames;
	If Extensions.WithFrames.Count() > 0 Then
		
		Items.DecorationFramesList.Title = StrConcat(Extensions.WithFrames, Chars.LF);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenFileSelection(Var_Title)

	TemporaryStorageFileName = GetTemporaryStorageFile(UUID);

	TransferParameters = FilesCTLClient.FileLocationParameters();
	TransferParameters.FileNameOrAddress = TemporaryStorageFileName;
	TransferParameters.NotifyDescriptionOnCompletion = New NotifyDescription("ProcessFilePlacement", ThisObject);
	TransferParameters.BlockedForm = ThisObject;
	TransferParameters.TitleOfSelectionDialog = Var_Title;
	TransferParameters.SelectionDialogFilter = StrTemplate(NStr("ru = 'Архивы %1';
															|en = 'Archives %1';"), "(*.zip)|*.zip");
	TransferParameters.FileNameOfSelectionDialog = ExportImportDataClientServer.NameOfDataUploadFile();

	FilesCTLClient.PlaceFileInteractively(TransferParameters);
	
EndProcedure

&AtClient
Procedure ProcessFilePlacement(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		DeleteTemporaryDataAfterUpload(TemporaryStorageFileName);
		Return;
	EndIf;
	
	If ValueIsFilled(TheHashSumOfTheFile) Then
		
		If HashAmountOfTemporaryFileMatches(TemporaryStorageFileName, TheHashSumOfTheFile) Then
			StartDataImport();	
		Else
			
			NotifyDescription = New NotifyDescription("ConfirmingDownloadOfAnotherFileEnds", ThisObject);
		
			ShowQueryBox(NotifyDescription,
				NStr("ru = 'Файл данных не совпадает с тем из которого загрузка запускалась ранее. Продолжение загрузки будет не возможно и она будет запущена с начала.
				|Продолжить?';
				|en = 'The data file does not match the one from which the import was started earlier. The import will not continue and it will start from the beginning.
				|Continue?';"),
				QuestionDialogMode.OKCancel,,
				DialogReturnCode.Cancel);
		
		EndIf;
		
	Else		
		
		ProcessFileConfirmation();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfirmingDownloadOfAnotherFileEnds(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.OK Then
		Return;
	EndIf;
	
	TheHashSumOfTheFile = Undefined;
	Items.DownloadTheExtensionConfiguration.WarningOnEditRepresentation = WarningOnEditRepresentation.DontShow;
	ProcessFileConfirmation();
	
EndProcedure

&AtClient
Procedure ProcessFileConfirmation() Export
	
	CheckResult = CheckUploadConfiguration(TemporaryStorageFileName);
	
	If Not CheckResult.Success Then

		DeleteTemporaryDataAfterUpload(TemporaryStorageFileName);

		QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionParameters.PromptDontAskAgain = False;
		QuestionParameters.Picture = PictureLib.Error32;
		QuestionParameters.Title = NStr("ru = 'Ошибка загрузки файла';
											|en = 'File import error';");

		StandardSubsystemsClient.ShowQuestionToUser(
			Undefined,
			CheckResult.CheckErrorText,
			QuestionDialogMode.OK,
			QuestionParameters);

		Return;
	EndIf;

	If DataFileContainsSuppliedExtensions() Then

		Items.Pages.CurrentPage = Items.ExtensionsPage;

	Else

		CheckingUnloadingModeForTechnicalSupport();

	EndIf;
	
EndProcedure

&AtServerNoContext
Function CheckUploadConfiguration(TemporaryStorageFileName)
	
	FileNameAtServer = FilesCTL.FullTemporaryStorageFileName(TemporaryStorageFileName);	
	
	ReadingArchiveData = New ZipFileReader(FileNameAtServer);

	Try
		CheckResult = CheckConfigurationOfInternalUpload(ReadingArchiveData)
	Except
		ReadingArchiveData.Close();
		Raise;
	EndTry;
	
	ReadingArchiveData.Close();
		
	Return CheckResult;

EndFunction

&AtServerNoContext
Function CheckConfigurationOfInternalUpload(ReadingArchiveData)
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Success", True);
	ReturnStructure.Insert("CheckErrorText", "");

	PathToContentFile = ExtractFileFromZipArchive(ReadingArchiveData, "PackageContents.xml");
	If PathToContentFile = Undefined Then
		Raise StrTemplate(NStr("ru = 'В архиве отсутствует файл содержимого (%1)';
										|en = 'The content file (%1) is missing in the archive';"), "PackageContents.xml");
	EndIf;

	ExceptionTextNoInformationAboutUpload = StrTemplate(
		NStr("ru = 'В архиве отсутствует файл информации о выгрузке (%1)';
			|en = 'The export information file (%1) is missing in the archive';"), "DumpInfo.xml");
	FileNameOfUploadInformation = GetFileNameFromContentData(
		PathToContentFile, 
		ExportImportDataInternal.DumpInfo(), 
		Undefined); 
	If FileNameOfUploadInformation = Undefined Then
		Raise ExceptionTextNoInformationAboutUpload;
	EndIf;
	
	PathToUploadInformationFile = ExtractFileFromZipArchive(ReadingArchiveData, FileNameOfUploadInformation);
	If PathToUploadInformationFile = Undefined Then
		Raise ExceptionTextNoInformationAboutUpload;
	EndIf;
	
	UploadInformation =  ExportImportDataInternal.ReadXDTOObjectFromFile(
		PathToUploadInformationFile,
		XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "DumpInfo"));
	
	DeleteFilesInAttempt(PathToUploadInformationFile);
	
	//Only identical versions can be checked	
	If UploadInformation.Configuration.Name <> Metadata.Name 
		Or UploadInformation.Configuration.Version <> Metadata.Version Then
		Return ReturnStructure;
	EndIf;
		
	NameOfConfigurationSchemaFile = GetFileNameFromContentData(
		PathToContentFile, 
		"CustomData", 
		"ConfigScheme"); 
	
	DeleteFilesInAttempt(PathToContentFile);

	If NameOfConfigurationSchemaFile = Undefined Then
		WarningText = NStr("ru = 'Конфигурация поддерживает проверку схемы данных, но файл схемы не найден в файле выгрузки.
					 | Структура файла выгрузки не соответствует ожидаемой.';
					|en = 'The configuration supports ER diagram check but the diagram file is not found in the export file.
					| The export file structure does not match the expected one.';");
		WriteLogEvent(EventLogEventName(),
			EventLogLevel.Warning, , , WarningText);
		Return ReturnStructure;
	EndIf;
	
	PathToUploadConfigurationSchemaFile = ExtractFileFromZipArchive(ReadingArchiveData, NameOfConfigurationSchemaFile); 
	If PathToUploadConfigurationSchemaFile = Undefined Then
		Return ReturnStructure;
	EndIf;
		
	BinaryConfigurationSchemaData = ConfigurationSchema.SchemaBinaryData(False, False);	

	HashingConfigurationSchemaData = New DataHashing(HashFunction.CRC32);
	HashingConfigurationSchemaData.Append(BinaryConfigurationSchemaData);
	
	If HashingConfigurationSchemaData.HashSum = TheHashSumOfTheFile(PathToUploadConfigurationSchemaFile) Then
		DeleteFilesInAttempt(PathToUploadConfigurationSchemaFile);
		Return ReturnStructure;
	EndIf;
	 	
	DescriptionsOfDifferences = AnalyzeConfigurationSchemas.DescriptionsOfDifferencesInConfigurationSchemes(
		New BinaryData(PathToUploadConfigurationSchemaFile),
		BinaryConfigurationSchemaData);
	
	DeleteFilesInAttempt(PathToUploadConfigurationSchemaFile);
	
	If ValueIsFilled(DescriptionsOfDifferences) Then
		
		PartsOfErrorText = New Array;	
		
		PartsOfErrorText.Add(NStr("ru = 'Файл выгрузки не может быть загружен в информационную базу: его конфигурация отличается от конфигурации информационной базы. 
			|Для устранения различий необходимо обратиться к своей обслуживающей организации или администратору информационной базы.';
			|en = 'Cannot import the export file to the infobase as its configuration differs from the infobase configuration.
			| To eliminate the differences, contact your service provider or the infobase administrator.';"));		
		
		PartsOfErrorText.Add(Chars.LF);
		PartsOfErrorText.Add(Chars.LF);

		For Each DescriptionsOfDifference In DescriptionsOfDifferences Do
			PartsOfErrorText.Add("● ");
			PartsOfErrorText.Add(DescriptionsOfDifference);
			PartsOfErrorText.Add(Chars.LF);
		EndDo;
		
		ReturnStructure.CheckErrorText = StrConcat(PartsOfErrorText);
		ReturnStructure.Success = False;
		
	EndIf;
	
	Return ReturnStructure;

EndFunction

&AtClient
Procedure CheckingUnloadingModeForTechnicalSupport()
	
	If ExportForTechnicalSupportMode(TemporaryStorageFileName) Then
		NotifyDescription = New NotifyDescription("CheckingUnloadingModeForTechnicalSupportCompletion", ThisObject);
		
		ShowQueryBox(NotifyDescription, NStr("ru = 'Файл данных создан в режиме выгрузки для технической поддержки.
      		|Приложение полученное из такой выгрузки предназначено только для целей тестирования и разбора проблем. Продолжить загрузку?';
				|en = 'Data file was created in the export mode for the technical support.
				|An application got from such an export must be used only for testing and analysis of problems. Do you want to continue importing?';"),
			QuestionDialogMode.OKCancel,,
			DialogReturnCode.Cancel);
		
	Else		
		StartDataImport();
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckingUnloadingModeForTechnicalSupportCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.OK Then
		Return;
	EndIf;
	
	StartDataImport();
	
EndProcedure

&AtServer
Procedure HandleInterruptedBootProcedure()
		
	If Not Parameters.DownloadProcedureAborted Then
		Return;
	EndIf;
	
	ParametersForLaunchingInteractiveImportProcedure
		= Constants.ParametersForLaunchingInteractiveImportProcedure.Get().Get();
		
	If ParametersForLaunchingInteractiveImportProcedure = Undefined Then
		Return;	
	EndIf;	
	
	FillPropertyValues(
		ThisObject,
		ParametersForLaunchingInteractiveImportProcedure);	
	
	Items.DownloadTheExtensionConfiguration.WarningOnEditRepresentation
		= WarningOnEditRepresentation.Show;
	
EndProcedure

&AtClient
Procedure StartDataImport()
	
	SetExclusiveModeAtServer();
	
	Try
		StartDataImportAtServer();
	Except
		
		CancelImportAtServer();
				
		ErrorInfo = ErrorInfo();
			
		HandleError(ErrorProcessing.DetailErrorDescription(ErrorInfo));
		
		ErrorWarningText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		ShowWarningErrors(
			True,
			NStr("ru = 'При запуске загрузки данных произошла ошибка:';
				|en = 'An error occurred when starting the data import:';"),
			NStr("ru = 'Рекомендуется повторить попытку загрузки';
				|en = 'We recommend that you try to import again';"));
		
		Return;
		
	EndTry;
	
	CommandBarLocation = FormCommandBarLabelLocation.None;	
	Items.Pages.CurrentPage = Items.PageWait;
		
	AttachIdleHandler("ImportReadyCheck", 5);
	
EndProcedure

&AtClient
Procedure ImportReadyCheck()
	 
	Try
		ImportState = ImportState(JobID, StateID, StorageAddress);
	Except
		
		CancelImportAtServer();
			
		ErrorInfo = ErrorInfo();
		
		DetachIdleHandler("ImportReadyCheck");
		
		HandleError(ErrorProcessing.DetailErrorDescription(ErrorInfo));
		
		ErrorWarningText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		ShowWarningErrors(
			True,
			NStr("ru = 'При загрузке данных произошла ошибка:';
				|en = 'An error occurred when importing the data:';"),
			NStr("ru = 'При продолжении будет предложено повторить попытку загрузки';
				|en = 'If you continue, you will be prompted to try to import again';"));
		
		Return;
		
	EndTry;
	
	If ImportState.StatusPresentation <> Undefined Then	
		StatusPresentation  = ImportState.StatusPresentation
			+ Chars.LF 
			+ ExportImportDataClientServer.LongTermOperationHint();
	EndIf;
						
	EndPercentage = ImportState.EndPercentage;
	Items.GroupEndPercentage.Visible = ImportState.EndPercentage <> Undefined;
		
	If Not ImportState.Completed_ Then 
		Return;
	EndIf;
	
	DetachIdleHandler("ImportReadyCheck");	
		 
	ProcessImportResultOnServer();

	If ValueIsFilled(ErrorWarningText) Then
		
		RestartProgramAtClosing = True;
		ShowWarningErrors(
			False,
			NStr("ru = 'Загрузка данных завершена. В процессе загрузки получены предупреждения:';
				|en = 'Data is imported. During the operation, the following warnings were received:';"),
			NStr("ru = 'Подробная информация записана в журнал регистрации. При продолжении программа будет перезапущена';
				|en = 'Detailed information is saved to the event log. If you continue, the application will be restarted';"));

	Else
		RestartApplication();	
	EndIf;

EndProcedure

&AtServerNoContext
Procedure HandleError(Val DetailedPresentation)
	
	GRRecordingTemplate = NStr("ru = 'При загрузке данных произошла ошибка:
		|
		|-----------------------------------------
		|%1
		|-----------------------------------------';
		|en = 'An error occurred when importing data:
		|
		|-----------------------------------------
		|%1
		|-----------------------------------------';");
		
	TextOfLREntry = StrTemplate(GRRecordingTemplate, DetailedPresentation);
	
	WriteLogEvent(
		NStr("ru = 'Загрузка данных';
			|en = 'Data import';", Common.DefaultLanguageCode()),
		EventLogLevel.Error,
		,
		,
		TextOfLREntry);
		
EndProcedure

&AtClient
Procedure ShowWarningErrors(Error, ToolTip, Recommendation)
	
	Items.ErrorsWarningsHint.Title = ToolTip;
	Items.ErrorsWarningsRecommendation.Title = Recommendation;
	
 	Items.Continue.Title = "OK";
 	Items.Cancel.Visible = False;
 	 
	CommandBarLocation = FormCommandBarLabelLocation.Bottom;

	If Error Then
		Picture = PictureLib.Error32;	
	Else
		Picture = PictureLib.Warning32;	
	EndIf;
	Items.ErrorsWarningsPicture.Picture = Picture;
	
	Items.Pages.CurrentPage = Items.ErrorWarningPage; 
	
EndProcedure

&AtServerNoContext																	
Function ImportState(JobID, StateID, StorageAddress)
	
	ImportState = New Structure();
	ImportState.Insert("Completed_", False);
	ImportState.Insert("StatusPresentation", Undefined);
	ImportState.Insert("EndPercentage", Undefined);
			
	Job = BackgroundJobs.FindByUUID(JobID);
	
	JobActive = False;
			
	If Job = Undefined Then
		ImportResult1 = GetFromTempStorage(StorageAddress);
		If ImportResult1 = Undefined Then
			Raise NStr("ru = 'При загрузке данных произошла ошибка - не найдено задание выполняющее загрузку.';
									|en = 'An error occurred when importing data. No import job is found.';");
		EndIf;
	Else
		
		If Job.State = BackgroundJobState.Active Then		
			JobActive = True;				
		ElsIf Job.State = BackgroundJobState.Failed Then
			JobError = Job.ErrorInfo;
			If JobError <> Undefined Then
				Raise ErrorProcessing.DetailErrorDescription(JobError);
			Else
				Raise
					NStr("ru = 'При загрузке данных произошла ошибка - задание выполняющее загрузку завершилось с неизвестной ошибкой.';
						|en = 'An error occurred when importing data. The job executing the import was completed with an unknown error.';");
			EndIf;
		ElsIf Job.State = BackgroundJobState.Canceled Then
			Raise NStr("ru = 'При загрузке данных произошла ошибка - задание выполняющее загрузку было отменено администратором.';
									|en = 'An error occurred when importing data. The job executing the import was canceled by the administrator.';");
		EndIf;
				
	EndIf;
	
 	ImportState.Completed_ = Not JobActive;
 				
	DataAreaExportImportState = ExportImportData.DataAreaExportImportState(
		StateID);	
				
	If ValueIsFilled(DataAreaExportImportState) Then
		ImportState.StatusPresentation = ExportImportData.DataAreaExportImportStateView(
			DataAreaExportImportState);
		ImportState.EndPercentage = ExportImportData.ExportImportDataAreaEndPercentage(
			DataAreaExportImportState);
	EndIf;
 	
	Return ImportState;

EndFunction

&AtServerNoContext
Procedure DeleteTemporaryDataAfterUpload(TemporaryStorageFileName)

	If Not ValueIsFilled(TemporaryStorageFileName) Then
		Return;
	EndIf;
		
	FilesCTL.DeleteTemporaryStorageFile(TemporaryStorageFileName);

EndProcedure

&AtServer
Function DataFileContainsSuppliedExtensions()
	
	FileNameAtServer = FilesCTL.FullTemporaryStorageFileName(TemporaryStorageFileName);	
	
	PathToExtensionsFile = ExtractFileFromZipArchive(FileNameAtServer, "Extensions.xml");
		
	XMLReader = New XMLReader;
	XMLReader.OpenFile(PathToExtensionsFile);
	XMLReader.MoveToContent();
	
	If XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.Name <> "Data" Then
		DeleteFilesInAttempt(PathToExtensionsFile);
		Return False;
	EndIf;
	
	VersionsArray = New Array;
	Extensions = New Structure("WithFrames, WithoutFrames", New Array, New Array);
	
	While XMLReader.Read() Do
		
		If XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.Name <> "Extension" Then		
			Continue;	
		EndIf;
		
		ModifiesDataStructure = XMLValue(Type("Boolean"), XMLReader.AttributeValue("ModifiesDataStructure"));
		Description = XMLValue(Type("String"), XMLReader.AttributeValue("Name"));
		
		If Not ModifiesDataStructure Then
			Continue;
		EndIf;

		VersionsArray.Add(Description);
		If XMLReader.AttributeValue("IsFrame") <> Undefined Then
			If XMLValue(Type("Boolean"), XMLReader.AttributeValue("IsFrame")) = True Then
				Extensions.WithFrames.Add(Description);
			Else
				Extensions.WithoutFrames.Add(Description);
			EndIf;
		Else
			Extensions.WithoutFrames.Add(Description);
		EndIf;
		
	EndDo;
	
	DeleteFilesInAttempt(PathToExtensionsFile);
	
	If VersionsArray.Count() = 0 Then
		Return False;
	EndIf;
	
	ConfigureWarningsByExtensionsVisibility(Extensions);
	
	Return True;
	
EndFunction

&AtServer
Procedure SetExclusiveModeAtServer()
	
	SaaSOperations.SetExclusiveLock(UseMultithreading());
	
EndProcedure

&AtServer
Procedure StartDataImportAtServer()
		
	Try
			
		FileNameAtServer = FilesCTL.FullTemporaryStorageFileName(TemporaryStorageFileName);
		
		ExportImportDataAreas.CheckIfUploadingToArchiveIsCompatibleWithCurConfiguration(FileNameAtServer);
		
		RestoreInformationBaseExtensions(FileNameAtServer);
		
		ParametersForLaunchingInteractiveImportProcedure = New Structure();
		ParametersForLaunchingInteractiveImportProcedure.Insert(
			"TheHashSumOfTheFile",
			TheHashSumOfTheFile(FileNameAtServer));
		ParametersForLaunchingInteractiveImportProcedure.Insert(
			"DownloadTheExtensionConfiguration",
			DownloadTheExtensionConfiguration);
		ParametersForLaunchingInteractiveImportProcedure.Insert(
			"ImportDataJobsCount",
			ImportDataJobsCount);
		
		Constants.ParametersForLaunchingInteractiveImportProcedure.Set(
			New ValueStorage(ParametersForLaunchingInteractiveImportProcedure));	
		
		StateID = New UUID();
		StorageAddress = PutToTempStorage(Undefined, UUID);
		
		ImportParameters = New Structure();
		ImportParameters.Insert("StateID", StateID);
		ImportParameters.Insert("SkipExtensionsRestoring", True);
		ImportParameters.Insert("ResultStorageAddress_", StorageAddress);
		ImportParameters.Insert("ThreadsCount", ImportDataJobsCount);
			
		JobParameters = New Array();
		JobParameters.Add(FileNameAtServer);
		JobParameters.Add(True);
		JobParameters.Add(True);
		JobParameters.Add(Undefined);
		JobParameters.Add(Undefined);
		JobParameters.Add(ImportParameters);
			
		StatusPresentation = ExportImportDataClientServer.ExportImportDataAreaPreparationStateView(True) 
			+ Chars.LF 
			+ ExportImportDataClientServer.LongTermOperationHint();	
							 
		BackgroundJob = ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions(
			"ExportImportDataAreas.ImportCurrentAreaFromArchive",
			JobParameters);
		JobID = BackgroundJob.UUID;
						
	Except
				
		SaaSOperations.RemoveExclusiveLock(UseMultithreading());
		
		DeleteTemporaryDataAfterUpload(TemporaryStorageFileName);
		
		Raise;
		
	EndTry;
	
EndProcedure

&AtServer
Procedure RestoreInformationBaseExtensions(FileNameAtServer)
	
	ExtensionData_ = New Structure();
		
	If DownloadTheExtensionConfiguration Then
		RecoveryExtensions = RecoveryExtensions(FileNameAtServer);
		If ValueIsFilled(RecoveryExtensions) Then
			ExtensionData_.Insert("RecoveryExtensions", RecoveryExtensions);
		EndIf;
	EndIf;
		
	ExtensionsFrameForRecovery = ExtensionsFrameForRecovery(FileNameAtServer);
	If ValueIsFilled(ExtensionsFrameForRecovery) Then	
		ExtensionData_.Insert("ExtensionsFrameForRecovery", ExtensionsFrameForRecovery);
	EndIf;
	
	If Not ValueIsFilled(ExtensionData_) Then
		Return;
	EndIf;
	
	ExportImportDataInternal.RestoreInformationBaseExtensions(ExtensionData_);	
	
EndProcedure


&AtServerNoContext
Function ExtensionsFrameForRecovery(FileNameAtServer)
	
	ReadingArchiveData = New ZipFileReader(FileNameAtServer);
	
	Try
		RecoveryExtensions = ExtensionFrameworksForRestoringInternal(ReadingArchiveData);
	Except
		ReadingArchiveData.Close();
		Raise;
	EndTry;
	
	ReadingArchiveData.Close();
	
	Return RecoveryExtensions; 
	
EndFunction

&AtServerNoContext
Function ExtensionFrameworksForRestoringInternal(ReadingArchiveData)
	
	RecoveryExtensions = New Array;

	PathToExtensionsFile = ExtractFileFromZipArchive(ReadingArchiveData, "Extensions.xml");
	If PathToExtensionsFile = Undefined Then
		Return RecoveryExtensions;
	EndIf;

	XMLReader = New XMLReader;
	XMLReader.OpenFile(PathToExtensionsFile);
	XMLReader.MoveToContent();

	If XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.Name <> "Data" Then
		DeleteFilesInAttempt(PathToExtensionsFile);
		Return RecoveryExtensions;
	EndIf;

	While XMLReader.Read() Do

		If XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.Name <> "Extension" Then
			Continue;
		EndIf;

		ModifiesDataStructure = XMLValue(Type("Boolean"), XMLReader.AttributeValue("ModifiesDataStructure"));
		Description = XMLValue(Type("String"), XMLReader.AttributeValue("Name"));
		FrameAttribute = XMLReader.AttributeValue("IsFrame");
		FileNameAttribute = XMLReader.AttributeValue("FileName");
		If Not ModifiesDataStructure Or FrameAttribute = Undefined Or FileNameAttribute = Undefined Then
			Continue;
		EndIf;

		IsFrame = XMLValue(Type("Boolean"), FrameAttribute);
		ExtensionFileName = XMLValue(Type("String"), FileNameAttribute);

		If Not ValueIsFilled(ExtensionFileName) Or Not IsFrame Then
			Continue;
		EndIf;

		PathToExtensionFile = ExtractFileFromZipArchive(ReadingArchiveData, ExtensionFileName);
		If PathToExtensionFile = Undefined Then
			Raise StrTemplate(NStr("ru = 'Не найден файл данных расширения %1';
											|en = 'The %1 extension data file is not found';"), ExtensionFileName);
		EndIf;

		ExtensionForRecovery = New Structure;
		ExtensionForRecovery.Insert("Name", Description);
		
		UserExtensionFileData = New BinaryData(PathToExtensionFile);
		ExtensionForRecovery.Insert("Data", UserExtensionFileData);

		RecoveryExtensions.Add(ExtensionForRecovery);

		DeleteFilesInAttempt(PathToExtensionFile);
		
	EndDo;
	
	DeleteFilesInAttempt(PathToExtensionsFile);
	
	Return RecoveryExtensions;
	
EndFunction


// Checks whether a temporary file's checksum matches the passed value.
// 
// Parameters:
//  TemporaryStorageFileName - String - Filename
//  TheHashSumOfTheFile - Number - File hash
// 
// Returns:
//  Boolean - Indicates whether the checksum matches the passed value.
&AtServerNoContext
Function HashAmountOfTemporaryFileMatches(TemporaryStorageFileName, TheHashSumOfTheFile)
		
	FullNameOfFileInSession = FilesCTL.FullTemporaryStorageFileName(TemporaryStorageFileName);

	Return TheHashSumOfTheFile(FullNameOfFileInSession) = TheHashSumOfTheFile;
	
EndFunction

// File hashsum.
// 
// Parameters: 
//  FileName - String - File name.
// 
// Returns: 
//  Number - File hash
&AtServerNoContext
Function TheHashSumOfTheFile(FileName)
			
	DataHashing = New DataHashing(HashFunction.CRC32);
	DataHashing.AppendFile(FileName);
	
	Return DataHashing.HashSum;
	
EndFunction

&AtServerNoContext
Procedure DeleteFilesInAttempt(FolderOrFileName)
	
	// @skip-check module-nstr-camelcase - Check error
	EventNameLR = NStr("ru = 'Удаление файла.Загрузка файла выгрузки';
						|en = 'Delete file.Import export file';", Common.DefaultLanguageCode());
	FilesCTL.DeleteFilesInAttempt(FolderOrFileName, EventNameLR);
	
EndProcedure

&AtServerNoContext
Function RecoveryExtensions(FileNameAtServer)

	ReadingArchiveData = New ZipFileReader(FileNameAtServer);

	Try
		RecoveryExtensions = ExtensionsForInternalRecovery(ReadingArchiveData);
	Except
		ReadingArchiveData.Close();
		Raise;
	EndTry;
	
	ReadingArchiveData.Close();
		
	Return RecoveryExtensions;
EndFunction

&AtServerNoContext
Function ExtensionsForInternalRecovery(ReadingArchiveData)

	RecoveryExtensions = New Array;

	UUIDType = Type("UUID");

	PathToCustomExtensionsFile = ExtractFileFromZipArchive(ReadingArchiveData, "CustomExtensions.json");
	If PathToCustomExtensionsFile = Undefined Then
		Return RecoveryExtensions;
	EndIf;

	ReadingCustomExtensionFile = New JSONReader;
	ReadingCustomExtensionFile.OpenFile(PathToCustomExtensionsFile);

	InformationAboutCustomExtensions = ReadJSON(ReadingCustomExtensionFile);
	ReadingCustomExtensionFile.Close();

	For Each UserExtensionInformation In InformationAboutCustomExtensions Do

		NameOfCustomExtensionFile = Undefined;
		If Not UserExtensionInformation.Property("FileName", NameOfCustomExtensionFile)
			Or Not ValueIsFilled(NameOfCustomExtensionFile) Then
			Continue;
		EndIf;

		PathToUserExtensionFile = ExtractFileFromZipArchive(ReadingArchiveData,
			NameOfCustomExtensionFile);
		If PathToUserExtensionFile = Undefined Then
			Raise StrTemplate(NStr("ru = 'Не найден файл данных расширения %1';
											|en = 'The %1 extension data file is not found';"),
				NameOfCustomExtensionFile);
		EndIf;

		ExtensionForRecovery = New Structure;
		ExtensionForRecovery.Insert("Active", UserExtensionInformation.Active);
		ExtensionForRecovery.Insert("SafeMode", UserExtensionInformation.SafeMode);

		UnsafeActionProtection = New UnsafeOperationProtectionDescription;
		UnsafeActionProtection.UnsafeOperationWarnings = UserExtensionInformation.UnsafeOperationWarnings;
		ExtensionForRecovery.Insert("UnsafeActionProtection", UnsafeActionProtection);

		ExtensionForRecovery.Insert("Name", UserExtensionInformation.Name);
		ExtensionForRecovery.Insert("UseDefaultRolesForAllUsers",
			UserExtensionInformation.UseDefaultRolesForAllUsers);
		ExtensionForRecovery.Insert("UsedInDistributedInfoBase",
			UserExtensionInformation.UsedInDistributedInfoBase);
		ExtensionForRecovery.Insert("Synonym", UserExtensionInformation.Synonym);
		ExtensionForRecovery.Insert("ModifiesDataStructure",
			UserExtensionInformation.ModifiesDataStructure);
		ExtensionForRecovery.Insert("UUID", XMLValue(UUIDType,
			UserExtensionInformation.UUID));
		UserExtensionFileData =  New BinaryData(PathToUserExtensionFile);
		ExtensionForRecovery.Insert("Data", UserExtensionFileData);

		RecoveryExtensions.Add(ExtensionForRecovery);

		DeleteFilesInAttempt(PathToUserExtensionFile);

	EndDo;
	
	DeleteFilesInAttempt(PathToCustomExtensionsFile);
		
	Return RecoveryExtensions;
EndFunction

&AtServerNoContext
Function GetTemporaryStorageFile(ThisFormID)
	
	FileName = FilesCTL.NewTemporaryStorageFile("xml2data", "zip", 120);
	FilesCTL.LocATemporaryStorageFile(FileName, ThisFormID);
	
	Return FileName;
	
EndFunction

&AtServerNoContext
Function GetFileNameFromContentData(PathToContentFile, FileType, TypeOfData)

	XMLReader = New XMLReader;
	XMLReader.OpenFile(PathToContentFile);

	XMLReader.MoveToContent();

	If XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.Name <> "Data" Then
		Raise NStr("ru = 'Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента ""Data"".';
								|en = 'XML reading error. Invalid file format. Start of ""Data"" element is expected.';");
	EndIf;

	XMLReader.Read();
	While XMLReader.NodeType = XMLNodeType.StartElement Do
		XDTODataObject = XDTOFactory.ReadXML(XMLReader);

		If XDTODataObject.Type = FileType And (TypeOfData = Undefined Or XDTODataObject.Properties().Get("DataType")
			<> Undefined And XDTODataObject.DataType = TypeOfData) Then

			Return XDTODataObject.Name;
		EndIf;
	EndDo;

	Return Undefined;

EndFunction

&AtServerNoContext
Function ExtractFileFromZipArchive(ArchiveOrRead, FileName)

	If TypeOf(ArchiveOrRead) = Type("ZipFileReader") Then
		ReadingArchiveData = ArchiveOrRead;
	Else
		ReadingArchiveData = New ZipFileReader(ArchiveOrRead);
	EndIf;
	
	Try
		PathToFile = ExtractFileFromZipArchiveExt(ReadingArchiveData, FileName)
	Except
		If TypeOf(ArchiveOrRead) <> Type("ZipFileReader") Then
			ReadingArchiveData.Close();
		EndIf;
		Raise;
	EndTry;
	
	If TypeOf(ArchiveOrRead) <> Type("ZipFileReader") Then
		ReadingArchiveData.Close();
	EndIf;	
		
	Return PathToFile;

EndFunction

&AtServerNoContext
Function ExtractFileFromZipArchiveExt(ReadingArchiveData, FileName)
	
	ZipElement = ReadingArchiveData.Items.Find(FileName);
	If ZipElement = Undefined Then
		Return Undefined;
	EndIf;

	TempDirectoryName = GetTempFileName();
	ReadingArchiveData.Extract(ZipElement, TempDirectoryName, ZIPRestoreFilePathsMode.DontRestore);
	
	TempFileName = GetTempFileName();
	MoveFile(TempDirectoryName + GetPathSeparator() + FileName, TempFileName);
	
	DeleteFilesInAttempt(TempDirectoryName);	
				
	Return TempFileName;

EndFunction

&AtServerNoContext
Function EventLogEventName()
	Return NStr("ru = 'Загрузка данных из сервиса';
				|en = 'Import data from the service';", Common.DefaultLanguageCode());
EndFunction

&AtServer
Procedure ProcessImportResultOnServer() 
	
	JobID = Undefined;
	
	SaaSOperations.RemoveExclusiveLock(UseMultithreading());
			
	DeleteTemporaryDataAfterUpload(TemporaryStorageFileName);
	
	Constants.ParametersForLaunchingInteractiveImportProcedure.Set(
		Undefined);	
	
	ImportResult1 = GetFromTempStorage(StorageAddress);
	
	If ImportResult1 = Undefined Then
		Raise(NStr("ru = 'При загрузке данных произошла ошибка - не найден результат загрузки';
								|en = 'An error occurred when importing data. The import result is not found';"));
	EndIf;
	
	DeleteFromTempStorage(StorageAddress);
	
	Warnings = ImportResult1.Warnings;
	
	If ValueIsFilled(Warnings) Then
		
		Separator = "
		|-----------------------------------------------
		|";

		ErrorWarningText = StrConcat(Warnings, Separator);
	
	EndIf;
			
EndProcedure

&AtClient
Procedure QuestionBeforeClosingCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	CancelImportAtServer();
	
	Close();
	
EndProcedure

&AtServer
Procedure CancelImportAtServer()
	
	If ValueIsFilled(JobID) Then
		ImportingBackgroundJob = BackgroundJobs.FindByUUID(JobID);
		If ImportingBackgroundJob <> Undefined 
			And ImportingBackgroundJob.State = BackgroundJobState.Active Then
			ImportingBackgroundJob.Cancel();
		EndIf;
		JobID = Undefined;
	EndIf;

	DeleteTemporaryDataAfterUpload(TemporaryStorageFileName);
				
EndProcedure

&AtServerNoContext
Function ExportForTechnicalSupportMode(TemporaryStorageFileName)
	
	PathSeparator = GetPathSeparator();
	
	//@skip-check missing-temporary-file-deletion
	TempDirectory = GetTempFileName() + PathSeparator;
	CreateDirectory(TempDirectory);
	
	FileNameAtServer = FilesCTL.FullTemporaryStorageFileName(TemporaryStorageFileName);	
    Archive = ExportImportDataInternal.ReadArchive(FileNameAtServer);
	
	CompositionFileName = ExportImportDataInternal.GetFileName(
		ExportImportDataInternal.PackageContents());
	ExportImportDataInternal.UnzipArchiveFile(
		Archive,
		TempDirectory,
		CompositionFileName);
	Content = ExportImportDataInternal.ArchiveContent(
		TempDirectory + CompositionFileName);
	
	SearchParameters = ExportImportDataInternal.NewFileFromArchiveSearchParameters();
	SearchParameters.Name = ExportImportDataInternal.GetFileName(ExportImportDataInternal.Digest());
	
	DigestFileParameters = ExportImportDataInternal.GetFileParametersFromArchive(
		Content, SearchParameters);
	DigestFileName = DigestFileParameters.Name;
	DigestDirectoryName = DigestFileParameters.Directory;
	
	ExportImportDataInternal.UnzipArchiveFile(
		Archive,
		TempDirectory,
		DigestFileName, 
		DigestDirectoryName);
		
	UploadingForTechnicalSupport = ExportImportDataInternal.ExportForTechnicalSupportMode(
		TempDirectory + DigestDirectoryName + PathSeparator + DigestFileName);
	
	DeleteFilesInAttempt(TempDirectory);
	
	Return UploadingForTechnicalSupport;
	
EndFunction

&AtServer
Function UseMultithreading()
	
	Return ImportDataJobsCount > 1;
	
EndFunction

#EndRegion