///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Web service operation handlers.

// Matches the Upload web service operation.
Function ExecuteExport(ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage, DataArea)
	
	SignInToDataArea(DataArea);
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	ExchangeMessage = "";
	
	DataExchangeServer.ExportForInfobaseNodeViaString(ExchangePlanName, InfobaseNodeCode, ExchangeMessage);
	
	ExchangeMessageStorage = New ValueStorage(ExchangeMessage, New Deflation(9));
	
	SignOutOfDataArea(DataArea);
	
	Return "";
	
EndFunction

// Matches the UploadData web service operation.
Function RunDataExport(ExchangePlanName,
								InfobaseNodeCode,
								FileIDAsString,
								TimeConsumingOperation,
								OperationID,
								TimeConsumingOperationAllowed,
								DataArea)
								
	SignInToDataArea(DataArea);								
								
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	FileID = New UUID;
	FileIDAsString = String(FileID);
	
	RunExportDataInClientServerMode(ExchangePlanName, InfobaseNodeCode, FileID, TimeConsumingOperation, OperationID, TimeConsumingOperationAllowed);
	
	SignOutOfDataArea(DataArea);
	
	Return "";
	
EndFunction

// An analog of the "UploadDataInt" operation.
Function RunDataExportInternalPublication(ExchangePlanName,
													InfobaseNodeCode,
													TaskID__,
													DataArea)
														
	SetPrivilegedMode(True);
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
		
	ExportDataInClientServerModeInternalPublication(
		ExchangePlanName, InfobaseNodeCode, TaskID__, DataArea);
		
	Return "";
	
EndFunction

// Matches the Download web service operation.
Function ExecuteImport(ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage, DataArea)
	
	SignInToDataArea(DataArea);
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	DataExchangeServer.ImportForInfobaseNodeViaString(ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage.Get());
	
	SignOutOfDataArea(DataArea);
	
	Return "";
	
EndFunction

// Matches the DownloadData web service operation.
Function RunDataImport(ExchangePlanName,
								InfobaseNodeCode,
								FileIDAsString,
								TimeConsumingOperation,
								OperationID,
								TimeConsumingOperationAllowed,
								DataArea)
								
	SignInToDataArea(DataArea);
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	FileID = New UUID(FileIDAsString);
	
	RunImportDataInClientServerMode(ExchangePlanName, InfobaseNodeCode, FileID, TimeConsumingOperation, OperationID, TimeConsumingOperationAllowed);	
	
	SignOutOfDataArea(DataArea);
	
	Return "";
	
EndFunction

// An analog of the "DownloadDataInt" operation.
Function RunDataImportInternalPublication(ExchangePlanName,
													InfobaseNodeCode,
													TaskID__,
													FileIDAsString,
													DataArea)
													
	SetPrivilegedMode(True);
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	FileID = New UUID(FileIDAsString);
	
	ImportDataInClientServerModeInternalPublication(
		ExchangePlanName,	InfobaseNodeCode, TaskID__, FileID, DataArea);	

	Return "";
	
EndFunction

// Matches the GetIBParameters web service operation.
Function GetInfobaseParameters(ExchangePlanName, NodeCode, ErrorMessage, DataArea, AdditionalXDTOParameters) 
	
	SignInToDataArea(DataArea);
	
	AdditionalParameters = XDTOSerializer.ReadXDTO(AdditionalXDTOParameters);
	
	Result = DataExchangeServer.InfoBaseAdmParams(ExchangePlanName, NodeCode, ErrorMessage, AdditionalParameters);
	
	SignOutOfDataArea(DataArea);
	
	Return XDTOSerializer.WriteXDTO(Result);
	
EndFunction

// Matches the CreateExchangeNode web service operation.
Function CreateDataExchangeNode(XDTOParameters, DataArea)
	
	SignInToDataArea(DataArea);
	
	SetPrivilegedMode(True);
	  	
	DataExchangeServer.CheckDataExchangeUsage(True);
	
	Parameters = XDTOSerializer.ReadXDTO(XDTOParameters);
	
	ConnectionSettings = Parameters.ConnectionSettings;
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	Try
		ModuleSetupWizard.FillConnectionSettingsFromXMLString(
			ConnectionSettings, Parameters.XMLParametersString, , True);
			
		If ValueIsFilled(ConnectionSettings.WSCorrespondentEndpoint) Then
			ConnectionSettings.WSCorrespondentEndpoint = 
				ExchangePlans["MessagesExchange"].FindByCode(ConnectionSettings.WSCorrespondentEndpoint);
			ConnectionSettings.Insert("ExchangeMessagesTransportKind", Enums.ExchangeMessagesTransportTypes.WS);	
		Else	
			ConnectionSettings.Insert("ExchangeMessagesTransportKind", Enums.ExchangeMessagesTransportTypes.WSPassiveMode);
		EndIf;
			
		ModuleSetupWizard.ConfigureDataExchange(
			ConnectionSettings);
	Except
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , ErrorMessage);
			
		Raise ErrorMessage;
	EndTry;
	
	SignOutOfDataArea(DataArea);
	
	Return "";
	
EndFunction

// Matches the RemoveExchangeNode web service operation.
Function DeleteDataExchangeNode(ExchangePlanName, NodeID, DataArea)
	
	SignInToDataArea(DataArea);
	
	SetPrivilegedMode(True);
		
	ExchangeNode = DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, NodeID);
		
	If ExchangeNode = Undefined Then
		ApplicationPresentation = ?(Common.DataSeparationEnabled(),
			Metadata.Synonym, DataExchangeCached.ThisInfobaseName());
			
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В ""%1"" не найден узел плана обмена ""%2"" с идентификатором ""%3"".';
				|en = 'Exchange plan node ""%2"" with ID %3 is not found in %1.';"),
			ApplicationPresentation, ExchangePlanName, NodeID);
	EndIf;
	
	DataExchangeServer.DeleteSynchronizationSetting(ExchangeNode);
	
	SignOutOfDataArea(DataArea);
	
	Return "";
	
EndFunction

// Matches the GetContinuousOperationStatus web service operation.
Function GetTimeConsumingOperationState(OperationID, ErrorMessageString, DataArea)
	
	SignInToDataArea(DataArea);
	
	SetPrivilegedMode(True);
		
	BackgroundJobStates = New Map;
	BackgroundJobStates.Insert(BackgroundJobState.Active,           "Active");
	BackgroundJobStates.Insert(BackgroundJobState.Completed,         "Completed");
	BackgroundJobStates.Insert(BackgroundJobState.Failed, "Failed");
	BackgroundJobStates.Insert(BackgroundJobState.Canceled,          "Canceled");
		
	BackgroundJob = BackgroundJobs.FindByUUID(New UUID(OperationID));
	
	If BackgroundJob = Undefined Then
		
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не найдено длительной операции с идентификатором %1.';
				|en = 'No long-running operation with ID %1 was found.';"),
			OperationID);
			
		SignOutOfDataArea(DataArea);
		
		Return BackgroundJobStates.Get(BackgroundJobState.Canceled);
		
	EndIf;
	
	If BackgroundJob.ErrorInfo <> Undefined Then
		
		ErrorMessageString = ErrorProcessing.DetailErrorDescription(BackgroundJob.ErrorInfo);
		
	EndIf;
	
	SignOutOfDataArea(DataArea);
	
	Return BackgroundJobStates.Get(BackgroundJob.State);
	
EndFunction

// Matches the PrepareGetFile web service operation.
Function PrepareGetFile(FileId, BlockSize, TransferId, PartQuantity, Zone)
	
	SignInToDataArea(Zone);
	
	SetPrivilegedMode(True);
	
	TransferId = New UUID;
	
	SourceFileName1 = DataExchangeServer.GetFileFromStorage(FileId);
	
	TempDirectory = TemporaryExportDirectory(TransferId);
	
	SourceFileNameInTemporaryDirectory = CommonClientServer.GetFullFileName(TempDirectory, "data.zip");
	
	CreateDirectory(TempDirectory);
		
	MoveFile(SourceFileName1, SourceFileNameInTemporaryDirectory);
	
	If BlockSize <> 0 Then
		// Splitting a file into parts
		FilesNames = SplitFile(SourceFileNameInTemporaryDirectory, BlockSize * 1024);
		PartQuantity = FilesNames.Count();
		
		DeleteFiles(SourceFileNameInTemporaryDirectory);
	Else
		PartQuantity = 1;
		MoveFile(SourceFileNameInTemporaryDirectory, SourceFileNameInTemporaryDirectory + ".1");
	EndIf;
	
	SignOutOfDataArea(Zone);
		
	Return "";
	
EndFunction

// Matches the GetFilePart web service operation.
Function GetFilePart(TransferId, PartNumber, PartData, Zone)
	
	SignInToDataArea(Zone);
	
	FilesNames = FindPartFile(TemporaryExportDirectory(TransferId), PartNumber);
	
	If FilesNames.Count() = 0 Then
		
		MessageTemplate = NStr("ru = 'Не найден фрагмент %1 сессии передачи с идентификатором %2';
								|en = 'Part %1 of the transfer session with ID %2 is not found';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, String(PartNumber), String(TransferId));
		Raise(MessageText);
		
	ElsIf FilesNames.Count() > 1 Then
		
		MessageTemplate = NStr("ru = 'Найдено несколько фрагментов %1 сессии передачи с идентификатором %2';
								|en = 'Multiple parts %1 of the transfer session with ID %2 are not found';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, String(PartNumber), String(TransferId));
		Raise(MessageText);
		
	EndIf;
	
	PartFileName = FilesNames[0].FullName;
	PartData = New BinaryData(PartFileName);
	
	SignOutOfDataArea(Zone);
	
	Return "";
	
EndFunction

// Matches the ReleaseFile web service operation.
Function ReleaseFile(TransferId)
	
	Try
		DeleteFiles(TemporaryExportDirectory(TransferId));
	Except
		WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return "";
	
EndFunction

// Matches the PutFilePart web service operation.
//
// Parameters:
//   TransferId - UUID - data transfer session UUID.
//   PartNumber - Number - the file part number.
//   PartData - BinaryData - the file part details.
//
Function PutFilePart(TransferId, PartNumber, PartData, Zone)
	
	SignInToDataArea(Zone);
	
	TempDirectory = TemporaryExportDirectory(TransferId);
	
	If PartNumber = 1 Then
		
		CreateDirectory(TempDirectory);
		
	EndIf;
	
	FileName = CommonClientServer.GetFullFileName(TempDirectory, GetPartFileName(PartNumber));
	
	PartData.Write(FileName);
	
	SignOutOfDataArea(Zone);
	
	Return "";
	
EndFunction

// Matches the SaveFileFromParts web service operation.
Function SaveFileFromParts(TransferId, PartQuantity, FileId, Zone)
	
	SignInToDataArea(Zone);
	
	SetPrivilegedMode(True);
	
	TempDirectory = TemporaryExportDirectory(TransferId);
	
	PartsFilesToMerge = New Array;
	
	For PartNumber = 1 To PartQuantity Do
		
		FileName = CommonClientServer.GetFullFileName(TempDirectory, GetPartFileName(PartNumber));
		
		If FindFiles(FileName).Count() = 0 Then
			MessageTemplate = NStr("ru = 'Не найден фрагмент %1 сессии передачи с идентификатором %2.
					|Необходимо убедиться, что в настройках программы заданы параметры
					|""Каталог временных файлов для Linux"" и ""Каталог временных файлов для Windows"".';
					|en = 'Part %1 of the transfer session with ID %2 is not found. 
					|Make sure that the ""Directory of temporary files for Linux""
					|and ""Directory of temporary files for Windows"" parameters are specified in the application settings.';");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, String(PartNumber), String(TransferId));
			Raise(MessageText);
		EndIf;
		
		PartsFilesToMerge.Add(FileName);
		
	EndDo;
	
	ArchiveName = CommonClientServer.GetFullFileName(TempDirectory, "data.zip");
	
	MergeFiles(PartsFilesToMerge, ArchiveName);
	
	Dearchiver = New ZipFileReader(ArchiveName);
	
	If Dearchiver.Items.Count() = 0 Then
		
		Try
			DeleteFiles(TempDirectory);
		Except
			WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogEvent(),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));	
		EndTry;
		
		SignOutOfDataArea(Zone);
		Raise(NStr("ru = 'Файл архива не содержит данных.';
								|en = 'The archive file is empty.';"));
		
	EndIf;
	
	DumpDirectory = DataExchangeServer.TempFilesStorageDirectory();
	
	ArchiveItem = Dearchiver.Items.Get(0);
	FileName = CommonClientServer.GetFullFileName(DumpDirectory, ArchiveItem.Name);
	
	Dearchiver.Extract(ArchiveItem, DumpDirectory);
	Dearchiver.Close();
	
	FileId = DataExchangeServer.PutFileInStorage(FileName, FileId);
	
	Try
		DeleteFiles(TempDirectory);
	Except
		WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));	
	EndTry;	
	
	SignOutOfDataArea(Zone);
	
	Return "";
	
EndFunction

// Matches the PutMessageForDataMatching web service operation.
Function PutMessageForDataMatching(ExchangePlanName, NodeID, FileID, DataArea)
	
	SignInToDataArea(DataArea);
	
	SetPrivilegedMode(True);
	
	ExchangeNode = DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, NodeID);
		
	If ExchangeNode = Undefined Then
		
		ApplicationPresentation = ?(Common.DataSeparationEnabled(),
			Metadata.Synonym, DataExchangeCached.ThisInfobaseName());
			
		SignOutOfDataArea(DataArea);	
			
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В ""%1"" не найден узел плана обмена ""%2"" с идентификатором ""%3"".';
				|en = 'Exchange plan node ""%2"" with ID %3 is not found in %1.';"),
			ApplicationPresentation, ExchangePlanName, NodeID);
			
	EndIf;
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	DataExchangeInternal.PutMessageForDataMapping(ExchangeNode, FileID);
	
	// The web client and the thin client have dedicated temporary directories. 
	// Configuring syncing from the thin client will result in an error due to the missing file
	// in the temporary directory.
	// 
	MoveTheMessageFileForTheFileIB(FileID);
	
	SignOutOfDataArea(DataArea);
	
	Return "";
	
EndFunction

// Matches the Ping web service operation.
Function Ping()
	// Test connection.
	Return "";
EndFunction

// Matches the TestConnection web service operation.
Function TestConnection(ExchangePlanName, NodeCode, Result, DataArea)
	
	SignInToDataArea(DataArea);
	
	SetPrivilegedMode(True);
	
	// Checking whether a user has rights to perform the data exchange.
	Try
		DataExchangeServer.CheckCanSynchronizeData(True);
	Except
		Result = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	
	// Checking whether the infobase is locked for update.
	Try
		CheckInfobaseLockForUpdate();
	Except
		Result = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	
	// Checking whether the exchange plan node exists (it might be deleted).
	NodeRef1 = DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, NodeCode); 
	If NodeRef1 = Undefined
		Or Common.ObjectAttributeValue(NodeRef1, "DeletionMark") Then
		ApplicationPresentation = ?(Common.DataSeparationEnabled(),
			Metadata.Synonym, DataExchangeCached.ThisInfobaseName());
			
		ExchangePlanPresentation1 = Metadata.ExchangePlans[ExchangePlanName].Presentation();
			
		Result = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В ""%1"" не найдена настройка синхронизации данных ""%2"" с идентификатором ""%3"".';
				|en = 'Data synchronization setting ""%2"" with ID %3 is not found in %1.';"),
			ApplicationPresentation, ExchangePlanPresentation1, NodeCode);
			
		SignOutOfDataArea(DataArea);
			
		Return False;
	EndIf;
	
	SignOutOfDataArea(DataArea);
		
	Return True;
EndFunction

// An analog of the "ChangeNodeTransportToWSPass" operation.
Function ChangeNodeTransportToWSInt(XDTOParameters, DataArea)
	
	SignInToDataArea(DataArea);
	
	SetPrivilegedMode(True);
	
	Parameters = XDTOSerializer.ReadXDTO(XDTOParameters);
	
	ExchangeNode = DataExchangeServer.ExchangePlanNodeByCode(Parameters.ExchangePlanName, Parameters.CorrespondentNodeCode);
		
	If ExchangeNode = Undefined Then
		
		ApplicationPresentation = ?(Common.DataSeparationEnabled(),
			Metadata.Synonym, DataExchangeCached.ThisInfobaseName());
			
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В ""%1"" не найден узел плана обмена ""%2"" с идентификатором ""%3"".';
				|en = 'Exchange plan node ""%2"" with ID %3 is not found in %1.';"),
			ApplicationPresentation, Parameters.ExchangePlanName, Parameters.CorrespondentNodeCode);
			
	EndIf;
		
	Endpoint = ExchangePlans["MessagesExchange"].FindByCode(Parameters.CorrespondentEndpoint);	
	
	RecordStructure = New Structure;
	RecordStructure.Insert("Peer", ExchangeNode);
	RecordStructure.Insert("DefaultExchangeMessagesTransportKind", Enums.ExchangeMessagesTransportTypes.WS);
	RecordStructure.Insert("WSCorrespondentEndpoint", Endpoint);
	RecordStructure.Insert("WSCorrespondentDataArea", Parameters.CorrespondentDataArea);
	RecordStructure.Insert("WSUseLargeVolumeDataTransfer", True);
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Изменение транспорта узла ""%1"" плана обмена ""%2"" в области данных %3 на ""Интернет"".';
			|en = 'Change the transport for node ""%1"" of exchange plan ""%2"" in data area %3 to ""Internet connection"".';"),
		Parameters.CorrespondentNodeCode, Parameters.ExchangePlanName, DataArea);
			
	WriteLogEvent(DataExchangeWebService.EventLogEventTransportChangedOnWS(),
		EventLogLevel.Information, , , MessageText);
	
	InformationRegisters.DataExchangeTransportSettings.AddRecord(RecordStructure);
	
	RecordStructure = New Structure("Peer", ExchangeNode);
	DataExchangeInternal.DeleteRecordSetFromInformationRegister(RecordStructure, "DataAreaExchangeTransportSettings");
	
	SignOutOfDataArea(DataArea);
	
EndFunction

// An analog of the "Callback" operation.
Function Callback(TaskID, Error, Zone)
	
	SignInToDataArea(Zone);
	
	SetPrivilegedMode(True);
	
	ModuleDataExchangeInternalPublication = Common.CommonModule("DataExchangeInternalPublication");	
	ModuleDataExchangeInternalPublication.MarkTaskAsCompleted(TaskID, Error);
		
	If Error = "" Then
		
		Task = ModuleDataExchangeInternalPublication.NextTask(TaskID);
		JobPrev = TaskID;
		
		If Task = Undefined Then
			Return "";	
		EndIf;
		
		ProcedureParameters = New Array;
		ProcedureParameters.Add(Task);
		ProcedureParameters.Add(JobPrev);

		Var_Key = Task.TaskID__;

		JobParameters = New Structure;
		JobParameters.Insert("Key", Left(Var_Key, 120));	
		JobParameters.Insert("MethodName"    , "DataExchangeInternalPublication.RunTaskQueue");
		JobParameters.Insert("DataArea", Zone);
		JobParameters.Insert("Use", True);
		JobParameters.Insert("ScheduledStartTime", CurrentSessionDate());
		JobParameters.Insert("Parameters", ProcedureParameters);
		JobParameters.Insert("RestartCountOnFailure", 3);
		JobParameters.Insert("RestartIntervalOnFailure", 900);

		ModuleJobsQueue = Common.CommonModule("JobsQueue");
		ModuleJobsQueue.AddJob(JobParameters);
	
	Else
		
		Task = ModuleDataExchangeInternalPublication.TaskByID(TaskID);
		
		Cancel = False;
		ExchangeSettingsStructure = 
			ModuleDataExchangeInternalPublication.ExchangeSettingsForInfobaseNode(Task.InfobaseNode, Task.Action, Cancel);
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
		
		DataExchangeServer.WriteEventLogDataExchange(Error, ExchangeSettingsStructure, True);
		DataExchangeServer.WriteExchangeFinish(ExchangeSettingsStructure);
		
	EndIf;
	
	SignOutOfDataArea(Zone);
	
EndFunction

// Matches the "TaskStatus" operation.
Function TaskStatus(TaskID)
	
	SetPrivilegedMode(True);
	
	JobParameters = New Structure("Key", TaskID);
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	Jobs = ModuleJobsQueue.GetJobs(JobParameters);
	
	If Jobs.Count() > 0 Then
		
		State = Common.ObjectAttributeValue(Jobs[0].Id, "JobState");
		Return Common.EnumerationValueName(State);
		
	Else
		
		Return "";
		
	EndIf;
	
EndFunction

// An analog of the "StopTasks" operation.
Function StopTasks(TasksID, Zone)
	
	SignInToDataArea(Zone);
	
	SetPrivilegedMode(True);
	
	TasksIDs = XDTOSerializer.ReadXDTO(TasksID);
	
	For Each TaskID__ In TasksIDs Do
		
		Filter = New Structure("Key", TaskID__);
		ModuleJobsQueue = Common.CommonModule("JobsQueue");
		Jobs = ModuleJobsQueue.GetJobs(Filter);
	
		For Each Job In Jobs Do
			
			JobParameters = New Structure;
			JobParameters.Insert("RestartCountOnFailure", 0);
			
			ModuleJobsQueue.ChangeJob(Job.Id, JobParameters);
			ModuleJobsQueue.DeleteJob(Job.Id);
			
			BackgrJobUUID = Common.ObjectAttributeValue(
				Job.Id, "ActiveBackgroundJob");
			
			TimeConsumingOperations.CancelJobExecution(BackgrJobUUID);
		
		EndDo;
		
	EndDo;
	
	SignOutOfDataArea(Zone);
	
	Return "";
		
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Local internal procedures and functions.

Procedure CheckInfobaseLockForUpdate()
	
	If ValueIsFilled(InfobaseUpdateInternal.InfobaseLockedForUpdate()) Then
		
		Raise NStr("ru = 'Синхронизация данных временно недоступна в связи с обновлением приложения в Интернете.';
								|en = 'Data synchronization is temporarily unavailable due to online application update.';");
		
	EndIf;
	
EndProcedure

Procedure RunExportDataInClientServerMode(ExchangePlanName,
														InfobaseNodeCode,
														FileID,
														TimeConsumingOperation,
														OperationID,
														TimeConsumingOperationAllowed)
	
	BackgroundJobKey = ExportImportDataBackgroundJobKey(ExchangePlanName,
		InfobaseNodeCode,
		NStr("ru = 'Выгрузка';
			|en = 'Export';"));
	
	If HasActiveDataSynchronizationBackgroundJobs(BackgroundJobKey) Then
		Raise NStr("ru = 'Синхронизация данных уже выполняется.';
								|en = 'Data synchronization is already running.';");
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ExchangePlanName", ExchangePlanName);
	ProcedureParameters.Insert("InfobaseNodeCode", InfobaseNodeCode);
	ProcedureParameters.Insert("FileID", FileID);
	ProcedureParameters.Insert("UseCompression", True);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Выгрузка данных через веб-сервис.';
															|en = 'Export data via web service.';");
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	
	ExecutionParameters.RunNotInBackground1 = Not TimeConsumingOperationAllowed;
	ExecutionParameters.RunInBackground   = TimeConsumingOperationAllowed;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataExchangeWebService.ExportToFileTransferServiceForInfobaseNode",
		ProcedureParameters,
		ExecutionParameters);
		
	If BackgroundJob.Status = "Running" Then
		OperationID = String(BackgroundJob.JobID);
		TimeConsumingOperation = True;
		Return;
	ElsIf BackgroundJob.Status = "Completed2" Then
		TimeConsumingOperation = False;
		Return;
	Else
		Message = NStr("ru = 'Ошибка при выгрузке данных через веб-сервис.';
						|en = 'Error exporting data via web service.';");
		If ValueIsFilled(BackgroundJob.DetailErrorDescription) Then
			Message = BackgroundJob.DetailErrorDescription;
		EndIf;
		
		WriteLogEvent(DataExchangeServer.ExportDataToFilesTransferServiceEventLogEvent(),
			EventLogLevel.Error, , , Message);
		
		Raise Message;
	EndIf;
	
EndProcedure

Procedure ExportDataInClientServerModeInternalPublication(ExchangePlanName,
		InfobaseNodeCode, TaskID__, DataArea)
			
	ProcedureParameters = New Array;
	ProcedureParameters.Add(ExchangePlanName);
	ProcedureParameters.Add(InfobaseNodeCode);
	ProcedureParameters.Add(TaskID__);
	
	Var_Key = TaskID__;
	
	JobParameters = New Structure;
	JobParameters.Insert("Key", Left(Var_Key, 120));
	JobParameters.Insert("MethodName"    , "DataExchangeInternalPublication.ExportToFileTransferServiceForInfobaseNode");
	JobParameters.Insert("DataArea", DataArea);
	JobParameters.Insert("Use", True);
	JobParameters.Insert("ScheduledStartTime", CurrentSessionDate());
	JobParameters.Insert("Parameters", ProcedureParameters);
	JobParameters.Insert("RestartCountOnFailure", 3);
	JobParameters.Insert("RestartIntervalOnFailure", 900);
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	ModuleJobsQueue.AddJob(JobParameters);
	
EndProcedure

Procedure RunImportDataInClientServerMode(ExchangePlanName,
													InfobaseNodeCode,
													FileID,
													TimeConsumingOperation,
													OperationID,
													TimeConsumingOperationAllowed)
	
													
	BackgroundJobKey = ExportImportDataBackgroundJobKey(ExchangePlanName,
		InfobaseNodeCode,
		NStr("ru = 'Загрузка';
			|en = 'Import';"));
	
	If HasActiveDataSynchronizationBackgroundJobs(BackgroundJobKey) Then
		Raise NStr("ru = 'Синхронизация данных уже выполняется.';
								|en = 'Data synchronization is already running.';");
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ExchangePlanName", ExchangePlanName);
	ProcedureParameters.Insert("InfobaseNodeCode", InfobaseNodeCode);
	ProcedureParameters.Insert("FileID", FileID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Загрузка данных через веб-сервис.';
															|en = 'Import data via web service.';");
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	
	ExecutionParameters.RunNotInBackground1 = Not TimeConsumingOperationAllowed;
	ExecutionParameters.RunInBackground   = TimeConsumingOperationAllowed;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataExchangeWebService.ImportFromFileTransferServiceForInfobaseNode",
		ProcedureParameters,
		ExecutionParameters);
		
	If BackgroundJob.Status = "Running" Then
		OperationID = String(BackgroundJob.JobID);
		TimeConsumingOperation = True;
		Return;
	ElsIf BackgroundJob.Status = "Completed2" Then
		TimeConsumingOperation = False;
		Return;
	Else
		
		Message = NStr("ru = 'Ошибка при загрузке данных через веб-сервис.';
						|en = 'Error importing data via web service.';");
		If ValueIsFilled(BackgroundJob.DetailErrorDescription) Then
			Message = BackgroundJob.DetailErrorDescription;
		EndIf;
		
		WriteLogEvent(DataExchangeServer.ImportDataFromFilesTransferServiceEventLogEvent(),
			EventLogLevel.Error, , , Message);
		
		Raise Message;
	EndIf;
	
EndProcedure

Procedure ImportDataInClientServerModeInternalPublication(ExchangePlanName,
		InfobaseNodeCode, TaskID__, FileID, DataArea)
		
	ProcedureParameters = New Array;
	ProcedureParameters.Add(ExchangePlanName);
	ProcedureParameters.Add(InfobaseNodeCode);
	ProcedureParameters.Add(TaskID__);
	ProcedureParameters.Add(FileID);
	
	Var_Key = TaskID__;
	
	JobParameters = New Structure;
	JobParameters.Insert("Key", Left(Var_Key, 120));
	JobParameters.Insert("MethodName"    , "DataExchangeInternalPublication.ImportFromFileTransferServiceForInfobaseNode");
	JobParameters.Insert("DataArea", DataArea);
	JobParameters.Insert("Use", True);
	JobParameters.Insert("ScheduledStartTime", CurrentSessionDate());
	JobParameters.Insert("Parameters", ProcedureParameters);
	JobParameters.Insert("RestartCountOnFailure", 3);
	JobParameters.Insert("RestartIntervalOnFailure", 900);
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	ModuleJobsQueue.AddJob(JobParameters);
	
EndProcedure

Function ExportImportDataBackgroundJobKey(ExchangePlan, NodeCode, Action)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'ПланОбмена:%1 КодУзла:%2 Действие:%3';
			|en = 'ExchangePlan:%1 NodeCode:%2 Action:%3';"),
		ExchangePlan,
		NodeCode,
		Action);
	
EndFunction

Function HasActiveDataSynchronizationBackgroundJobs(BackgroundJobKey)
	
	Filter = New Structure;
	Filter.Insert("Key", BackgroundJobKey);
	Filter.Insert("State", BackgroundJobState.Active);
	
	ActiveBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	
	Return (ActiveBackgroundJobs.Count() > 0);
	
EndFunction

Function GetPartFileName(PartNumber)
	
	Result = "data.zip.[n]";
	
	Return StrReplace(Result, "[n]", Format(PartNumber, "NG=0"));
EndFunction

Function TemporaryExportDirectory(Val SessionID)
	
	SetPrivilegedMode(True);
	
	TempDirectory = "{SessionID}";
	TempDirectory = StrReplace(TempDirectory, "SessionID", String(SessionID));
	
	Result = CommonClientServer.GetFullFileName(DataExchangeServer.TempFilesStorageDirectory(), TempDirectory);
	
	Return Result;
EndFunction

Function FindPartFile(Val Directory, Val FileNumber)
	
	For DigitsCount = NumberDigitsCount(FileNumber) To 5 Do
		
		FormatString = StringFunctionsClientServer.SubstituteParametersToString("ND=%1; NLZ=; NG=0", String(DigitsCount));
		
		FileName = StringFunctionsClientServer.SubstituteParametersToString("data.zip.%1", Format(FileNumber, FormatString));
		
		FilesNames = FindFiles(Directory, FileName);
		
		If FilesNames.Count() > 0 Then
			
			Return FilesNames;
			
		EndIf;
		
	EndDo;
	
	Return New Array;
EndFunction

Function NumberDigitsCount(Val Number)
	
	Return StrLen(Format(Number, "NFD=0; NG=0"));
	
EndFunction

Procedure MoveTheMessageFileForTheFileIB(FileID)
	
	If Not Common.FileInfobase() Then
		Return;
	EndIf;
		
	QueryText =
		"SELECT
		|	DataExchangeMessages.MessageFileName AS FileName
		|FROM
		|	InformationRegister.DataExchangeMessages AS DataExchangeMessages
		|WHERE
		|	DataExchangeMessages.MessageID = &MessageID";

	Query = New Query;
	Query.SetParameter("MessageID", String(FileID));
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	FileName = Selection.FileName;
	MessageFileName = CommonClientServer.GetFullFileName(DataExchangeServer.TempFilesStorageDirectory(), FileName);
	
	DirectoryName = DataExchangeServer.TheNameOfTheDirectoryToMapToTheFileInformationSystem();
	
	Directory = New File(DirectoryName);
	If Not Directory.Exists() Then
		CreateDirectory(DirectoryName);	
	EndIf;

	NameOfTheNewMessageFile = DataExchangeServer.TheFullNameOfTheFileToBeMappedIsFileInformationSystem(FileName);
	
	MoveFile(MessageFileName, NameOfTheNewMessageFile);	
	
EndProcedure

Procedure SignInToDataArea(DataArea)
	
	If DataArea = 0 
		Or Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");

	ModuleSaaSTechnology = Common.CommonModule("CloudTechnology");
	CTLVersion = ModuleSaaSTechnology.LibraryVersion();

	If CommonClientServer.CompareVersions(CTLVersion, "2.0.7.46") >= 0 Then
		ModuleSaaSOperations.SignInToDataArea(DataArea); //ACC:287
	Else
		ModuleSaaSOperations.SetSessionSeparation(True, DataArea); //ACC:222
	EndIf;
	
EndProcedure

Procedure SignOutOfDataArea(DataArea)
	
	If DataArea = 0 
		Or Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");

	ModuleSaaSTechnology = Common.CommonModule("CloudTechnology");
	CTLVersion = ModuleSaaSTechnology.LibraryVersion();

	If CommonClientServer.CompareVersions(CTLVersion, "2.0.7.46") >= 0 Then
		ModuleSaaSOperations.SignOutOfDataArea(); //ACC:287
	Else
		ModuleSaaSOperations.SetSessionSeparation(False); //ACC:222
	EndIf;
	
EndProcedure


#EndRegion
