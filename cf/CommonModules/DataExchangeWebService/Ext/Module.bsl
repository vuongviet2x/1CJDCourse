///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Internal

// Gets an exchange message from the correspondent infobase via web service to the temporary directory of
// OS user.
//
// Parameters:
//  Cancel                   - Boolean - indicates whether an error occurred on data exchange.
//  InfobaseNode  - ExchangePlanRef - an exchange plan node for which the exchange message is being received.
//  FileID      - UUID - file ID.
//  TimeConsumingOperation      - Boolean - indicates that long-running operation is used.
//  OperationID   - UUID - an UUID of the long-running operation.
//  AuthenticationParameters - Structure - contains web service authentication parameters (User, Password).
//
//  Returns:
//   Structure with the following keys:
//     * TempExchangeMessagesDirectoryName - a full name of the exchange directory that stores the exchange message.
//     * ExchangeMessageFileName              - a full name of the exchange message file.
//     * DataPackageFileID       - date of changing the exchange message file.
//
Function GetExchangeMessageToTempDirectoryFromCorrespondentInfobaseViaWebService(
											Cancel,
											InfobaseNode,
											FileID,
											TimeConsumingOperation,
											OperationID,
											AuthenticationParameters = Undefined) Export
	
	DataExchangeServer.CheckCanSynchronizeData();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	// Function return value.
	Result = New Structure;
	Result.Insert("TempExchangeMessagesDirectoryName", "");
	Result.Insert("ExchangeMessageFileName",              "");
	Result.Insert("DataPackageFileID",       Undefined);
	
	// Parameters to be defined in the function.
	ExchangeMessageDirectoryName = "";
	ExchangeMessageFileName = "";
	ExchangeMessageFileDate = Date('00010101');
	
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(
		InfobaseNode, "GettingExchangeMessage", Enums.ExchangeMessagesTransportTypes.WS, False);
		
	ExchangeSettingsStructure.EventLogMessageKey =
		DataExchangeServer.EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange.DataImport);
	ExchangeSettingsStructure.ActionOnExchange = Undefined;
		
	ProxyParameters = New Structure;
	ProxyParameters.Insert("AuthenticationParameters", AuthenticationParameters);
	
	Proxy = Undefined;
	SetupStatus = Undefined;
	ErrorMessage = "";
	InitializeWSProxyToManageDataExchange(Proxy, 
		ExchangeSettingsStructure, ProxyParameters, Cancel, SetupStatus, ErrorMessage);
	
	If Cancel Then
		DataExchangeServer.WriteEventLogDataExchange(ErrorMessage, ExchangeSettingsStructure, True);
		Return Result;
	EndIf;
	
	ExchangeParameters = New Structure;
	ExchangeParameters.Insert("FileID",          FileID);
	ExchangeParameters.Insert("TimeConsumingOperation",          TimeConsumingOperation);
	ExchangeParameters.Insert("OperationID",       OperationID);
	ExchangeParameters.Insert("TimeConsumingOperationAllowed", True);
	
	Try
		
		RunDataExport(Proxy, ProxyParameters.CurrentVersion, ExchangeSettingsStructure, ExchangeParameters);
		
		FileID = ExchangeParameters.FileID;
		TimeConsumingOperation = ExchangeParameters.TimeConsumingOperation;
		OperationID = ExchangeParameters.OperationID;
		
	Except
		
		Cancel = True;
		Message = NStr("ru = 'При выгрузке данных возникли ошибки во второй информационной базе: %1';
						|en = 'Errors occurred in the peer infobase during data export: %1';", Common.DefaultLanguageCode());
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		DataExchangeServer.WriteEventLogDataExchange(Message, ExchangeSettingsStructure, True);
		
		Return Result;
	EndTry;
	
	If ExchangeParameters.TimeConsumingOperation Then
		DataExchangeServer.WriteEventLogDataExchange(NStr("ru = 'Ожидание получения данных от базы-корреспондента...';
																		|en = 'Waiting for data from the peer infobase…';",
			Common.DefaultLanguageCode()), ExchangeSettingsStructure);
		Return Result;
	EndIf;
	
	Try
		FilesTransferServiceFileName = GetFileFromStorageInService(
			New UUID(ExchangeParameters.FileID),
			ExchangeSettingsStructure.InfobaseNode,, AuthenticationParameters);
	Except
		
		Cancel = True;
		Message = NStr("ru = 'Возникли ошибки при получении сообщения обмена из сервиса передачи файлов: %1';
						|en = 'Errors occurred while receiving an exchange message from the file transfer service: %1';", Common.DefaultLanguageCode());
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		DataExchangeServer.WriteEventLogDataExchange(Message, ExchangeSettingsStructure, True);
		
		Return Result;
	EndTry;
	
	Try
		ExchangeMessageDirectoryName = DataExchangeServer.CreateTempExchangeMessagesDirectory();
	Except
		Cancel = True;
		Message = NStr("ru = 'При получении сообщения обмена возникли ошибки: %1';
						|en = 'Errors occurred while receiving an exchange message: %1';", Common.DefaultLanguageCode());
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		DataExchangeServer.WriteEventLogDataExchange(Message, ExchangeSettingsStructure, True);
		
		Return Result;
	EndTry;
	
	MessageFileNameTemplate = DataExchangeServer.MessageFileNameTemplate(ExchangeSettingsStructure.CurrentExchangePlanNode,
		ExchangeSettingsStructure.InfobaseNode, False);
	
	ExchangeMessageFileName = CommonClientServer.GetFullFileName(ExchangeMessageDirectoryName, MessageFileNameTemplate + ".xml");
	
	MoveFile(FilesTransferServiceFileName, ExchangeMessageFileName);
	
	FileExchangeMessages = New File(ExchangeMessageFileName);
	If FileExchangeMessages.Exists() Then
		ExchangeMessageFileDate = FileExchangeMessages.GetModificationTime();
	EndIf;
	
	Result.TempExchangeMessagesDirectoryName = ExchangeMessageDirectoryName;
	Result.ExchangeMessageFileName              = ExchangeMessageFileName;
	Result.DataPackageFileID       = ExchangeMessageFileDate;
	
	Return Result;
EndFunction

// The function receives an exchange message from the correspondent infobase using web service
// and saves it to the temporary directory.
// It is used if the exchange message receipt is a part of a background job in the
// correspondent infobase.
//
// Parameters:
//  Cancel                   - Boolean - indicates whether an error occurred on data exchange.
//  InfobaseNode  - ExchangePlanRef - an exchange plan node for which the exchange message is being received.
//  FileID      - UUID - file ID.
//  AuthenticationParameters - Structure - contains web service authentication parameters (User, Password).
//
//  Returns:
//   Structure with the following keys:
//     * TempExchangeMessagesDirectoryName - a full name of the exchange directory that stores the exchange message.
//     * ExchangeMessageFileName              - a full name of the exchange message file.
//     * DataPackageFileID       - date of changing the exchange message file.
//
Function GetExchangeMessageToTempDirectoryFromCorrespondentInfobaseViaWebServiceTimeConsumingOperationCompletion(
							Cancel,
							InfobaseNode,
							FileID,
							Val AuthenticationParameters = Undefined) Export
	
	// Function return value.
	Result = New Structure;
	Result.Insert("TempExchangeMessagesDirectoryName", "");
	Result.Insert("ExchangeMessageFileName",              "");
	Result.Insert("DataPackageFileID",       Undefined);
	
	// Parameters to be defined in the function.
	ExchangeMessageDirectoryName = "";
	ExchangeMessageFileName = "";
	ExchangeMessageFileDate = Date('00010101');
	
	Try
		
		FilesTransferServiceFileName = GetFileFromStorageInService(New UUID(FileID), InfobaseNode,, AuthenticationParameters);
		
	Except
		
		Cancel = True;
		Message = NStr("ru = 'Возникли ошибки при получении сообщения обмена из сервиса передачи файлов: %1';
						|en = 'Errors occurred while receiving an exchange message from the file transfer service: %1';", Common.DefaultLanguageCode());
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		ExchangeSettingsStructure = New Structure("EventLogMessageKey");
		ExchangeSettingsStructure.EventLogMessageKey = 
			DataExchangeServer.EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange.DataImport);
		DataExchangeServer.WriteEventLogDataExchange(Message, ExchangeSettingsStructure, True);
		
		Return Result;
		
	EndTry;
	
	Try
		ExchangeMessageDirectoryName = DataExchangeServer.CreateTempExchangeMessagesDirectory();
	Except
		Cancel = True;
		Message = NStr("ru = 'При получении сообщения обмена возникли ошибки: %1';
						|en = 'Errors occurred while receiving an exchange message: %1';", Common.DefaultLanguageCode());
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		ExchangeSettingsStructure = New Structure("EventLogMessageKey");
		ExchangeSettingsStructure.EventLogMessageKey = 
			DataExchangeServer.EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange.DataImport);
		DataExchangeServer.WriteEventLogDataExchange(Message, ExchangeSettingsStructure, True);
		
		Return Result;
	EndTry;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(InfobaseNode);
	CurrentExchangePlanNode = DataExchangeCached.GetThisExchangePlanNode(ExchangePlanName);
	
	MessageFileNameTemplate = DataExchangeServer.MessageFileNameTemplate(CurrentExchangePlanNode, InfobaseNode, False);
	
	ExchangeMessageFileName = CommonClientServer.GetFullFileName(ExchangeMessageDirectoryName, MessageFileNameTemplate + ".xml");
	FileExchangeMessages = New File(ExchangeMessageFileName);
	If Not FileExchangeMessages.Exists() Then
		// Probably the file can be received if you apply the virtual code of the node.
		MessageFileNameTemplatePrevious = MessageFileNameTemplate;
		MessageFileNameTemplate = DataExchangeServer.MessageFileNameTemplate(CurrentExchangePlanNode, InfobaseNode, False,, True);
		If MessageFileNameTemplate <> MessageFileNameTemplatePrevious Then
			ExchangeMessageFileName = CommonClientServer.GetFullFileName(ExchangeMessageDirectoryName, MessageFileNameTemplate + ".xml");
			FileExchangeMessages = New File(ExchangeMessageFileName);
		EndIf;
	EndIf;
	
	MoveFile(FilesTransferServiceFileName, ExchangeMessageFileName);
	
	If FileExchangeMessages.Exists() Then
		ExchangeMessageFileDate = FileExchangeMessages.GetModificationTime();
	EndIf;
	
	Result.TempExchangeMessagesDirectoryName = ExchangeMessageDirectoryName;
	Result.ExchangeMessageFileName              = ExchangeMessageFileName;
	Result.DataPackageFileID       = ExchangeMessageFileDate;
	
	Return Result;
EndFunction

Procedure ExecuteExchangeActionForInfobaseNodeUsingWebService(Cancel,
		InfobaseNode, ActionOnExchange, ExchangeParameters) Export
	
	ParametersOnly = ExchangeParameters.ParametersOnly;
	
	SetPrivilegedMode(True);
	
	// DATA EXCHANGE INITIALIZATION
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(
		InfobaseNode, ActionOnExchange, Enums.ExchangeMessagesTransportTypes.WS, False);
	DataExchangeServer.RecordExchangeStartInInformationRegister(ExchangeSettingsStructure);
	
	If ExchangeSettingsStructure.Cancel Then
		// If a setting contains errors, canceling the exchange, Canceled status.
		DataExchangeServer.WriteExchangeFinish(ExchangeSettingsStructure);
		Cancel = True;
		Return;
	EndIf;
	
	ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
	
	MessageString = NStr("ru = 'Начало процесса обмена данными для узла %1';
							|en = 'Data exchange started. Node: %1.';", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeSettingsStructure.InfobaseNodeDescription);
	DataExchangeServer.WriteEventLogDataExchange(MessageString, ExchangeSettingsStructure);
	
	If ExchangeSettingsStructure.DoDataImport Then
				
		// {Handler: BeforeReadExchangeMessage} Start
		FileExchangeMessages = "";
		StandardProcessing = True;
		
		DataExchangeServer.BeforeReadExchangeMessage(ExchangeSettingsStructure.InfobaseNode, FileExchangeMessages, StandardProcessing);
		// {Handler: BeforeReadExchangeMessage} End
		
		If StandardProcessing Then
			
			Proxy = Undefined;
			
			ProxyParameters = New Structure;
			ProxyParameters.Insert("AuthenticationParameters", ExchangeParameters.AuthenticationParameters);
			
			SetupStatus = Undefined;
			ErrorMessage  = "";
			InitializeWSProxyToManageDataExchange(Proxy,
				ExchangeSettingsStructure, ProxyParameters, Cancel, SetupStatus, ErrorMessage);

			If Cancel Then
				DataExchangeServer.WriteEventLogDataExchange(ErrorMessage, ExchangeSettingsStructure, True);
				ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
				DataExchangeServer.WriteExchangeFinish(ExchangeSettingsStructure);
				Return;
			EndIf;
			
			FileExchangeMessages = "";
			
			Try
				
				RunDataExport(Proxy, ProxyParameters.CurrentVersion, ExchangeSettingsStructure, ExchangeParameters);
				
				If ExchangeParameters.TimeConsumingOperation Then
					
					WaitingForTheOperationToComplete(ExchangeSettingsStructure, ExchangeParameters, Proxy, ProxyParameters, Enums.ActionsOnExchange.DataImport);
					
				EndIf;
				
				UIDOfTheMessageFile = New UUID(ExchangeParameters.FileID);
				FileExchangeMessages = GetFileFromStorageInService(UIDOfTheMessageFile, InfobaseNode, 1024, ExchangeParameters.AuthenticationParameters);
				
			Except
				
				DataExchangeServer.WriteEventLogDataExchange(
					ErrorProcessing.DetailErrorDescription(ErrorInfo()),ExchangeSettingsStructure, True);
				ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
				Cancel = True;
				
			EndTry;
			
		EndIf;
		
		If Not Cancel Then
			
			DataExchangeServer.ReadMessageWithNodeChanges(ExchangeSettingsStructure, FileExchangeMessages,, ParametersOnly);
			
		EndIf;
		
		// {Handler: AfterReadExchangeMessage} Start
		StandardProcessing = True;
		
		DataExchangeServer.AfterReadExchangeMessage(
					ExchangeSettingsStructure.InfobaseNode,
					FileExchangeMessages,
					DataExchangeServer.ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult),
					StandardProcessing,
					Not ParametersOnly);
		// {Handler: AfterReadExchangeMessage} End
		
		If StandardProcessing Then
			
			Try
				If Not IsBlankString(FileExchangeMessages) 
					And TypeOf(DataExchangeServer.DataExchangeMessageFromMasterNode()) <> Type("Structure") Then
					DeleteFiles(FileExchangeMessages);
				EndIf;
			Except
				WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
					EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EndTry;
			
		EndIf;
					
	ElsIf ExchangeSettingsStructure.DoDataExport Then
		
		Proxy = Undefined;
		
		ProxyParameters = New Structure;
		ProxyParameters.Insert("AuthenticationParameters", ExchangeParameters.AuthenticationParameters);
		If ExchangeParameters.MessageForDataMapping Then
			ProxyParameters.Insert("MinVersion", "3.0.1.1");
		EndIf;
		
		SetupStatus = Undefined;
		ErrorMessage  = "";
		InitializeWSProxyToManageDataExchange(Proxy,
			ExchangeSettingsStructure, ProxyParameters, Cancel, SetupStatus, ErrorMessage);
		
		If Cancel Then
			DataExchangeServer.WriteEventLogDataExchange(ErrorMessage, ExchangeSettingsStructure, True);
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
			DataExchangeServer.WriteExchangeFinish(ExchangeSettingsStructure);
			Return;
		EndIf;
		
		TempDirectory = GetTempFileName();
		CreateDirectory(TempDirectory);
		
		FileExchangeMessages = CommonClientServer.GetFullFileName(
			TempDirectory, DataExchangeServer.UniqueExchangeMessageFileName());
		
		Try
			DataExchangeServer.WriteMessageWithNodeChanges(ExchangeSettingsStructure, FileExchangeMessages);
		Except
			DataExchangeServer.WriteEventLogDataExchange(
				ErrorProcessing.DetailErrorDescription(ErrorInfo()), ExchangeSettingsStructure, True);
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			Cancel = True;
		EndTry;
		
		// Sending an exchange message only if data is exported successfully.
		If DataExchangeServer.ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) And Not Cancel Then
			
			Try
				
				UIDFileID = PutFileInStorageInService(Proxy, ProxyParameters.CurrentVersion,
					ExchangeSettingsStructure, FileExchangeMessages, InfobaseNode, 1024);
				
				FileIDAsString = String(UIDFileID);
				
				Try
					DeleteFiles(TempDirectory);
				Except
					WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
						EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				EndTry;
					
				If ExchangeParameters.MessageForDataMapping
					And (SetupStatus.DataMappingSupported
						Or Not SetupStatus.DataSynchronizationSetupCompleted) Then
					
					PutMessageForDataMapping(Proxy, ProxyParameters.CurrentVersion,
						ExchangeSettingsStructure, FileIDAsString);
				
				Else
					
					RunDataImport(Proxy, ProxyParameters.CurrentVersion,
						ExchangeSettingsStructure, ExchangeParameters, FileIDAsString);
						
					If ExchangeParameters.TimeConsumingOperation Then
						
						WaitingForTheOperationToComplete(ExchangeSettingsStructure, ExchangeParameters, Proxy, ProxyParameters, Enums.ActionsOnExchange.DataExport);
						
					EndIf;
					
				EndIf;
				
			Except
				
				DataExchangeServer.WriteEventLogDataExchange(
					ErrorProcessing.DetailErrorDescription(ErrorInfo()), ExchangeSettingsStructure, True);
				ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
				Cancel = True;
				
			EndTry;
			
		EndIf;
		
		Try
			DeleteFiles(TempDirectory);
		Except
			WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
			
	EndIf;
	
	DataExchangeServer.WriteExchangeFinish(ExchangeSettingsStructure);
	
	If Not DataExchangeServer.ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) Then
		Cancel = True;
	EndIf;
	
EndProcedure

// Gets exchange message file from a correspondent infobase using web service.
// Imports exchange message file to the current infobase.
//
// Parameters:
//  Cancel                   - Boolean - indicates whether an error occurred on data exchange.
//  InfobaseNode  - ExchangePlanRef - an exchange plan node for which the exchange message is being received.
//  FileID      - UUID - file ID.
//  OperationStartDate      - Date - import start date.
//  AuthenticationParameters - Structure - contains web service authentication parameters (User, Password).
//
Procedure ExecuteDataExchangeForInfobaseNodeTimeConsumingOperationCompletion(
															Cancel,
															Val InfobaseNode,
															Val FileID,
															Val OperationStartDate,
															Val AuthenticationParameters = Undefined,
															ShowError = False) Export
	
	DataExchangeServer.CheckCanSynchronizeData();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	Try
		FileExchangeMessages = GetFileFromStorageInService(New UUID(FileID),
			InfobaseNode,, AuthenticationParameters);
	Except
		DataExchangeServer.WriteExchangeFinishWithError(InfobaseNode,
			Enums.ActionsOnExchange.DataImport,
			OperationStartDate,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		If ShowError Then
			Raise;
		Else
			Cancel = True;
		EndIf;
		Return;
	EndTry;
	
	// Importing the exchange message file into the current infobase.
	DataExchangeParameters = DataExchangeServer.DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.InfobaseNode        = InfobaseNode;
	DataExchangeParameters.FullNameOfExchangeMessageFile = FileExchangeMessages;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataImport;
	DataExchangeParameters.OperationStartDate            = OperationStartDate;
	
	Try
		DataExchangeServer.ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	Except
		DataExchangeServer.WriteExchangeFinishWithError(InfobaseNode,
			Enums.ActionsOnExchange.DataImport,
			OperationStartDate,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		If ShowError Then
			Raise;
		Else
			Cancel = True;
		EndIf;
	EndTry;
	
	Try
		DeleteFiles(FileExchangeMessages);
	Except
		WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

// The function downloads the file from the file transfer service by the passed ID.
//
// Parameters:
//  FileID       - UUID - an ID of the file being received.
//  InfobaseNode   - ExchangePlanRef - The exchange plan node that should receive the file.
//  PartSize              - Number - part size in kilobytes. If the passed value is 0,
//                             the file is not split into parts.
//  AuthenticationParameters  - A structure: "ServiceAddress", "UserName", "UserPassword".
//
// Returns:
//  String - The path to the received file.
//
Function GetFileFromStorageInService(Val FileID, Val InfobaseNode,
	Val PartSize = 1024, Val AuthenticationParameters = Undefined) Export
	
	// Function return value.
	ResultFileName = "";
	
	AdditionalParameters = New Structure("AuthenticationParameters", AuthenticationParameters);
	
	ErrorMessage = "";
	Proxy = WSProxyForInfobaseNode(InfobaseNode, ErrorMessage, AdditionalParameters);
	
	If Proxy = Undefined Then
		Raise ErrorMessage;
	EndIf;
	
	SessionID = Undefined;
	PartCount    = Undefined;
	
	ProxyParameters = New Structure("CurrentVersion", AdditionalParameters.CurrentVersion);
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(InfobaseNode, 
		Enums.ActionsOnExchange.DataExport, Enums.ExchangeMessagesTransportTypes.WS, False);

	PrepareFileForReceipt(Proxy, ProxyParameters.CurrentVersion, ExchangeSettingsStructure,
		FileID, PartSize, SessionID, PartCount);
	
	FilesNames = New Array;
	
	BuildDirectory = GetTempFileName();
	CreateDirectory(BuildDirectory);
	
	FileNameTemplate = "data.zip.[n]";
	
	// Log exchange events.
	ExchangeSettingsStructure.EventLogMessageKey = 
		DataExchangeServer.EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange.DataImport);
	
	Comment = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Начало получения сообщения обмена из Интернета (количество частей файла %1).';
			|en = 'Start receiving an exchange message from the Internet. The message is split into %1 parts.';"),
		Format(PartCount, "NZ=0; NG=0"));
	DataExchangeServer.WriteEventLogDataExchange(Comment, ExchangeSettingsStructure);
	
	For PartNumber = 1 To PartCount Do
		PartData = Undefined; // BinaryData
		Try
			GetFileChunk(Proxy, ProxyParameters.CurrentVersion, ExchangeSettingsStructure, SessionID, PartNumber, PartData);
		Except
			Proxy.ReleaseFile(SessionID);
			Raise;
		EndTry;
		
		FileName = StrReplace(FileNameTemplate, "[n]", Format(PartNumber, "NG=0"));
		PartFileName = CommonClientServer.GetFullFileName(BuildDirectory, FileName);
		
		PartData.Write(PartFileName);
		FilesNames.Add(PartFileName);
	EndDo;
	PartData = Undefined;
	
	Proxy.ReleaseFile(SessionID);
	
	ArchiveName = CommonClientServer.GetFullFileName(BuildDirectory, "data.zip");
	
	MergeFiles(FilesNames, ArchiveName);
	
	InformationRegisters.ArchiveOfExchangeMessages.PackMessageToArchive(InfobaseNode, ArchiveName);
	
	Dearchiver = New ZipFileReader(ArchiveName);
	If Dearchiver.Items.Count() = 0 Then
		Try
			DeleteFiles(BuildDirectory);
		Except
			WriteLogEvent(TempFileDeletionEventLogEvent(),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		Raise(NStr("ru = 'Файл архива не содержит данных.';
								|en = 'The archive file is empty.';"));
	EndIf;
	
	// Log exchange events.
	ArchiveFile1 = New File(ArchiveName);
	
	Comment = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Окончание получения сообщения обмена из Интернета (размер сжатого сообщения обмена %1 Мб).';
			|en = 'Complete receiving an exchange message from the Internet. Compressed message size: %1 MB.';"),
		Format(Round(ArchiveFile1.Size() / 1024 / 1024, 3), "NZ=0; NG=0"));
	DataExchangeServer.WriteEventLogDataExchange(Comment, ExchangeSettingsStructure);
	
	ArchiveItem = Dearchiver.Items.Get(0);
	FileName = CommonClientServer.GetFullFileName(BuildDirectory, ArchiveItem.Name);
	
	Dearchiver.Extract(ArchiveItem, BuildDirectory);
	Dearchiver.Close();
	
	File = New File(FileName);
	
	TempDirectory = GetTempFileName(); //ACC:441 - The directory is deleted when the peer infobase receives the exchange data
	CreateDirectory(TempDirectory);
	
	ResultFileName = CommonClientServer.GetFullFileName(TempDirectory, File.Name);
	
	MoveFile(FileName, ResultFileName);
	
	Try
		DeleteFiles(BuildDirectory);
	Except
		WriteLogEvent(TempFileDeletionEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
		
	Return ResultFileName;
EndFunction

// Passes the specified file to the file transfer service.
//
// Parameters:
//  Proxy                   - 
//  ProxyVersion             - String - The web service version
//  ExchangeSettingsStructure  - Structure - a structure with all necessary data and objects to execute exchange.
//  FileName                 - String - The path to the file.
//  InfobaseNode   - ExchangePlanRef - The exchange plan node that should receive the file. 
//  PartSizeKB            - Number - part size in kilobytes. If the passed value is 0,
//                             the file is not split into parts.
//  FileID       - UUID - The id of the file being uploaded to the service.
//
// Returns:
//  UUID  - The id of the file in the file transfer service.
//
Function PutFileInStorageInService(Proxy, ProxyVersion, ExchangeSettingsStructure, Val FileName, 
	Val InfobaseNode, Val PartSizeKB = 1024, FileID = Undefined) Export
	
	If Proxy = Undefined Then
		
		Raise NStr("ru = 'Не определен WS-прокси передачи файла выгрузки в базу приемник. 
			|Обратитесь к администратору.';
			|en = 'The WS proxy of transferring the export file to the destination infobase is not defined. 
			|Contact the administrator.';", Common.DefaultLanguageCode());
		
	EndIf;
	
	FilesDirectory = GetTempFileName();
	CreateDirectory(FilesDirectory);
	
	// Archive the file.
	SharedFileName = CommonClientServer.GetFullFileName(FilesDirectory, "data.zip");
	Archiver = New ZipFileWriter(SharedFileName,,,, ZIPCompressionLevel.Maximum);
	Archiver.Add(FileName);
	Archiver.Write();
	
	// Splitting a file into parts.
	SessionID = New UUID;
	
	TheSizeOfThePartInBytes = PartSizeKB * 1024;
	FilesNames = SplitFile(SharedFileName, TheSizeOfThePartInBytes);
	
	PartCount = FilesNames.Count();
	For PartNumber = 1 To PartCount Do
		
		PartFileName = FilesNames[PartNumber - 1];
		FileData = New BinaryData(PartFileName);
		PutFileChunk(Proxy, ProxyVersion, ExchangeSettingsStructure, SessionID, PartNumber, FileData);
		
	EndDo;
	
	Try
		DeleteFiles(FilesDirectory);
	Except
		WriteLogEvent(TempFileDeletionEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	AssembleFileFromParts(Proxy, ProxyVersion, ExchangeSettingsStructure, SessionID, PartCount, FileID);
	
	Return FileID;
	
EndFunction

// Initializes WS proxy to execute managing data exchange commands,
// but before that is checks if there is an exchange node.
//
// Parameters:
//   Proxy - WSProxy - a WS proxy to pass managing commands.
//   SettingsStructure_ - Structure - A structure of parameters used to connect the peer infobase and identify exchange settings:
//     * ExchangePlanName - String - name of the exchange plan used during synchronization.
//     * InfobaseNode - ExchangePlanRef - an exchange plan node matching the correspondent.
//     * EventLogMessageKey - String - name of an event to write errors to the event log.
//     * CurrentExchangePlanNode - ExchangePlanRef - a reference to ThisNode of the exchange plan.
//     * CurrentExchangePlanNodeCode1 - String - an ID of the current exchange plan node.
//     * ActionOnExchange - EnumRef.ActionsOnExchange - indicates the exchange direction.
//   ProxyParameters - Structure:
//     * AuthenticationParameters - String
//                               - Structure - The password for authentication on the web-server.
//     * AuthenticationSettingsStructure - Structure - contains a setting structure for authentication on the web-server.
//     * MinVersion - String - number of the earliest version of the DataExchange interface required to perform actions.
//     * CurrentVersion - String - an outgoing one, the actual interface version of the initialized WS proxy.
//   Cancel - Boolean - indicates a failed WS proxy initialization.
//   SetupStatus - Structure - An output parameter. Returns the status of the sync setting described in "SettingsStructure".:
//     * SettingExists - Boolean - True if a setting with the specified exchange plan and node ID exists.
//     * DataSynchronizationSetupCompleted - Boolean - True, if synchronization setup is successfully completed.
//     * DataMappingSupported - Boolean - True if a correspondent supports data mapping.
//     * MessageReceivedForDataMapping - Boolean - True, an email for mapping is imported to correspondent.
//   ErrorMessageString - String - a WS-proxy initialization error.
//
Procedure InitializeWSProxyToManageDataExchange(Proxy,
		SettingsStructure_, ProxyParameters, Cancel, SetupStatus, ErrorMessageString = "") Export
	
	MinVersion = "0.0.0.0";
	If ProxyParameters.Property("MinVersion") Then
		MinVersion = ProxyParameters.MinVersion;
	EndIf;
	
	AuthenticationParameters = Undefined;
	ProxyParameters.Property("AuthenticationParameters", AuthenticationParameters);
	
	AuthenticationSettingsStructure = Undefined;
	ProxyParameters.Property("AuthenticationSettingsStructure", AuthenticationSettingsStructure);
	
	ProxyParameters.Insert("CurrentVersion", Undefined);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("AuthenticationParameters",         AuthenticationParameters);
	AdditionalParameters.Insert("MinVersion",               MinVersion);
	AdditionalParameters.Insert("AuthenticationSettingsStructure", AuthenticationSettingsStructure);
	
	Proxy = WSProxyForInfobaseNode(
		SettingsStructure_.InfobaseNode,
		ErrorMessageString,
		AdditionalParameters);
		
	If Proxy = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	ProxyParameters.CurrentVersion = AdditionalParameters.CurrentVersion;
	
	If DataExchangeServer.IsXDTOExchangePlan(SettingsStructure_.ExchangePlanName) Then
		
		NodeAlias = DataExchangeServer.PredefinedNodeAlias(SettingsStructure_.InfobaseNode);
		If ValueIsFilled(NodeAlias) Then
			// Checking a setting with an old ID (prefix).
			SettingsStructureOfPredefined = Common.CopyRecursive(SettingsStructure_, False); // Structure
			SettingsStructureOfPredefined.Insert("CurrentExchangePlanNodeCode1", NodeAlias);
			SetupStatus = SynchronizationSetupStatusInCorrespondent(Proxy, ProxyParameters, SettingsStructureOfPredefined);
				
			If Not SetupStatus.SettingExists Then
				If ObsoleteExchangeSettingsOptionInCorrespondent(
						Proxy, ProxyParameters, SetupStatus, SettingsStructure_, NodeAlias, Cancel, ErrorMessageString)
					Or Cancel Then
					Return;
				EndIf;
			Else
				SettingsStructure_.CurrentExchangePlanNodeCode1 = NodeAlias;
				Return;
			EndIf;
		EndIf;
		
		SetupStatus = SynchronizationSetupStatusInCorrespondent(Proxy, ProxyParameters, SettingsStructure_);
			
		If Not SetupStatus.SettingExists Then
			If ObsoleteExchangeSettingsOptionInCorrespondent(
					Proxy, ProxyParameters, SetupStatus, SettingsStructure_, SettingsStructure_.CurrentExchangePlanNodeCode1, Cancel, ErrorMessageString)
				Or Cancel Then
				Return;
			EndIf;
		EndIf;
		
	Else
		
		SetupStatus = SynchronizationSetupStatusInCorrespondent(Proxy, ProxyParameters, SettingsStructure_);
			
	EndIf;
	
	If Not SetupStatus.SettingExists Then
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не найдена настройка синхронизации данных ""%1"" с идентификатором ""%2"".';
				|en = 'Data synchronization setting with ID ""%2"" is not found. Exchange plan: %1.';"),
			SettingsStructure_.ExchangePlanName,
			SettingsStructure_.CurrentExchangePlanNodeCode1);
		Cancel = True;
	EndIf;
	
EndProcedure

Function WSProxyForInfobaseNode(InfobaseNode, ErrorMessageString = "", AdditionalParameters = Undefined) Export
		
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	
	AuthenticationParameters = Undefined;
	AdditionalParameters.Property("AuthenticationParameters", AuthenticationParameters);
	
	AuthenticationSettingsStructure = Undefined;
	AdditionalParameters.Property("AuthenticationSettingsStructure", AuthenticationSettingsStructure);
	
	MinVersion = Undefined;
	If Not AdditionalParameters.Property("MinVersion", MinVersion) Then
		MinVersion = "0.0.0.0";
	EndIf;
	
	AdditionalParameters.Insert("CurrentVersion");
		
	If AuthenticationSettingsStructure = Undefined Then
		If DataExchangeCached.IsMessagesExchangeNode(InfobaseNode) Then
			ModuleMessagesExchangeTransportSettings = Common.CommonModule("InformationRegisters.MessageExchangeTransportSettings");
			AuthenticationSettingsStructure = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(
				InfobaseNode, AuthenticationParameters);
		Else
			AuthenticationSettingsStructure = InformationRegisters.DataExchangeTransportSettings.TransportSettingsWS(
				InfobaseNode, AuthenticationParameters);
		EndIf;
	EndIf;
	
	Try
		CorrespondentVersions = DataExchangeCached.CorrespondentVersions(AuthenticationSettingsStructure);
	Except
		ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EstablishWebServiceConnectionEventLogEvent(),
			EventLogLevel.Error,,, ErrorMessageString);
		Return Undefined;
	EndTry;
	
	AvailableVersions = New Map;
	For Each Version In StrSplit("3.0.2.2;3.0.2.1;3.0.1.1;2.1.1.7;2.0.1.6", ";", False) Do
		AvailableVersions.Insert(Version, CorrespondentVersions.Find(Version) <> Undefined
			And (CommonClientServer.CompareVersions(Version, MinVersion) >= 0));
	EndDo;
	
	AvailableVersions.Insert("0.0.0.0", CommonClientServer.CompareVersions("0.0.0.0", MinVersion) >= 0);
	
	If AvailableVersions.Get("3.0.2.2") = True Then
		CurrentVersion = "3.0.2.2";
	ElsIf AvailableVersions.Get("3.0.2.1") = True Then
		CurrentVersion = "3.0.2.1";
	ElsIf AvailableVersions.Get("3.0.1.1") = True Then
		CurrentVersion = "3.0.1.1";
	ElsIf AvailableVersions.Get("2.1.1.7") = True Then
		CurrentVersion = "2.0.1.6";
	ElsIf AvailableVersions.Get("2.0.1.6") = True Then
		CurrentVersion = "2.0.1.6";
	ElsIf AvailableVersions.Get("0.0.0.0") = True Then
		CurrentVersion = "0.0.0.0";
	Else
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Корреспондент не поддерживает требуемую версию ""%1"" интерфейса ""ОбменДанными"".';
				|en = 'The peer application does not support DataExchange v%1.';"),
			MinVersion);
		Return Undefined;
	EndIf;

	AdditionalParameters.CurrentVersion = CurrentVersion;
	
	If CurrentVersion = "0.0.0.0" Then
		VersionForAddress = "";
	Else
		VersionForAddress = "_" + StrReplace(CurrentVersion, ".", "_");		
	EndIf;
	
	//
	DataExchangeServer.DeleteInsignificantCharactersInConnectionSettings(AuthenticationSettingsStructure);
	
	AuthenticationSettingsStructure.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SSL/Exchange" + VersionForAddress);
	AuthenticationSettingsStructure.Insert("WSServiceName",                 "Exchange" + VersionForAddress);
	AuthenticationSettingsStructure.Insert("WSTimeout",                    600);
	
	Return GetWSProxyByConnectionParameters(AuthenticationSettingsStructure, ErrorMessageString, ErrorMessageString, True);
	
EndFunction

Function GetWSProxyByConnectionParameters(
					SettingsStructure_,
					ErrorMessageString = "",
					UserMessage = "",
					ProbingCallRequired = False) Export
	
	Try
		CheckWSProxyAddressFormatCorrectness(SettingsStructure_.WSWebServiceURL);
	Except
		UserMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EstablishWebServiceConnectionEventLogEvent(), EventLogLevel.Error,,, ErrorMessageString);
		Return Undefined;
	EndTry;

	Try
		CheckProhibitedCharsInWSProxyUsername(SettingsStructure_.WSUserName);
	Except
		UserMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EstablishWebServiceConnectionEventLogEvent(), EventLogLevel.Error,,, ErrorMessageString);
		Return Undefined;
	EndTry;
	
	WSDLLocation = "[WebServiceURL]/ws/[ServiceName]?wsdl";
	WSDLLocation = StrReplace(WSDLLocation, "[WebServiceURL]", SettingsStructure_.WSWebServiceURL);
	WSDLLocation = StrReplace(WSDLLocation, "[ServiceName]",    SettingsStructure_.WSServiceName);
	
	ConnectionParameters = Common.WSProxyConnectionParameters();
	ConnectionParameters.WSDLAddress = WSDLLocation;
	ConnectionParameters.NamespaceURI = SettingsStructure_.WSServiceNamespaceURL;
	ConnectionParameters.ServiceName = SettingsStructure_.WSServiceName;
	ConnectionParameters.UserName = SettingsStructure_.WSUserName; 
	ConnectionParameters.Password = SettingsStructure_.WSPassword;
	ConnectionParameters.Timeout = SettingsStructure_.WSTimeout;
	ConnectionParameters.ProbingCallRequired = ProbingCallRequired;
	
	Try
		WSProxy = Common.CreateWSProxy(ConnectionParameters);
	Except
		UserMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EstablishWebServiceConnectionEventLogEvent(), EventLogLevel.Error,,, ErrorMessageString);
		Return Undefined;
	EndTry;
	
	Return WSProxy;
EndFunction

Function CorrespondentConnectionEstablished(Val Peer,
		Val SettingsStructure_,
		UserMessage = "",
		DataSynchronizationSetupCompleted = True,
		MessageReceivedForDataMapping = False) Export
		
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(
		Peer, Enums.ActionsOnExchange.DataExport, Enums.ExchangeMessagesTransportTypes.WS, False);
		
	ExchangeSettingsStructure.Insert("EventLogMessageKey", 
		NStr("ru = 'Обмен данными.Проверка подключения';
			|en = 'Data exchange.Connection test';", Common.DefaultLanguageCode()));

	ProxyParameters = New Structure;
	ProxyParameters.Insert("AuthenticationParameters",         Undefined);
	ProxyParameters.Insert("AuthenticationSettingsStructure", SettingsStructure_);
	
	Proxy = Undefined;
	SetupStatus = Undefined;
	Cancel = False;
	InitializeWSProxyToManageDataExchange(Proxy, 
		ExchangeSettingsStructure, ProxyParameters, Cancel, SetupStatus, UserMessage);
	
	If Cancel Then
		ResetDataSynchronizationPassword(Peer);
		DataSynchronizationSetupCompleted = False;
		Return False;
	EndIf;
	
	SetDataSynchronizationPassword(Peer, SettingsStructure_.WSPassword);
	
	DataSynchronizationSetupCompleted   = SetupStatus.DataSynchronizationSetupCompleted;
	MessageReceivedForDataMapping = SetupStatus.MessageReceivedForDataMapping;
	
	Return SetupStatus.SettingExists;
	
EndFunction

Procedure ExportToFileTransferServiceForInfobaseNode(ProcedureParameters, StorageAddress) Export
	
	ExchangePlanName            = ProcedureParameters["ExchangePlanName"];
	InfobaseNodeCode = ProcedureParameters["InfobaseNodeCode"];
	FileID        = ProcedureParameters["FileID"];
	
	UseCompression = ProcedureParameters.Property("UseCompression") And ProcedureParameters["UseCompression"];
	
	SetPrivilegedMode(True);
	
	MessageFileName = CommonClientServer.GetFullFileName(
		DataExchangeServer.TempFilesStorageDirectory(),
		DataExchangeServer.UniqueExchangeMessageFileName());
	
	DataExchangeParameters = DataExchangeServer.DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.FullNameOfExchangeMessageFile = MessageFileName;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataExport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	
	DataExchangeServer.ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	
	NameOfFileToPutInStorage = MessageFileName;
	If UseCompression Then
		NameOfFileToPutInStorage = CommonClientServer.GetFullFileName(
			DataExchangeServer.TempFilesStorageDirectory(),
			DataExchangeServer.UniqueExchangeMessageFileName("zip"));
		
		Archiver = New ZipFileWriter(NameOfFileToPutInStorage, , , , ZIPCompressionLevel.Maximum);
		Archiver.Add(MessageFileName);
		Archiver.Write();
		
		DeleteFiles(MessageFileName);
	EndIf;
	
	DataExchangeServer.PutFileInStorage(NameOfFileToPutInStorage, FileID);
	
EndProcedure

Procedure ImportFromFileTransferServiceForInfobaseNode(ProcedureParameters, StorageAddress) Export
	
	ExchangePlanName            = ProcedureParameters["ExchangePlanName"];
	InfobaseNodeCode = ProcedureParameters["InfobaseNodeCode"];
	FileID        = ProcedureParameters["FileID"];
	
	SetPrivilegedMode(True);
	
	TempFileName = DataExchangeServer.GetFileFromStorage(FileID);
	
	DataExchangeParameters = DataExchangeServer.DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.FullNameOfExchangeMessageFile = TempFileName;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataImport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	
	Try
		DataExchangeServer.ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	Except
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		DeleteFiles(TempFileName);
		Raise ErrorPresentation;
	EndTry;
	
	DeleteFiles(TempFileName);
EndProcedure

// An analog of the "UploadData" operation
Procedure RunDataExport(Proxy, ProxyVersion, ExchangeSettingsStructure, ExchangeParameters) Export
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.UploadData(
			ExchangeSettingsStructure.CorrespondentExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			ExchangeParameters.FileID,
			ExchangeParameters.TimeConsumingOperation,
			ExchangeParameters.OperationID,
			ExchangeParameters.TimeConsumingOperationAllowed,
			ExchangeSettingsStructure.TransportSettings.WSCorrespondentDataArea);

	Else
					
		Proxy.UploadData(
			ExchangeSettingsStructure.ExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			ExchangeParameters.FileID,
			ExchangeParameters.TimeConsumingOperation,
			ExchangeParameters.OperationID,
			ExchangeParameters.TimeConsumingOperationAllowed);
			
	EndIf;

EndProcedure

// Matches the DownloadData web service operation.
Procedure RunDataImport(Proxy, ProxyVersion, ExchangeSettingsStructure, ExchangeParameters, FileIDAsString) Export
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.DownloadData(
			ExchangeSettingsStructure.CorrespondentExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			FileIDAsString,
			ExchangeParameters.TimeConsumingOperation,
			ExchangeParameters.OperationID,
			ExchangeParameters.TimeConsumingOperationAllowed,
			ExchangeSettingsStructure.TransportSettings.WSCorrespondentDataArea);
		
	Else
		
		Proxy.DownloadData(
			ExchangeSettingsStructure.ExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			FileIDAsString,
			ExchangeParameters.TimeConsumingOperation,
			ExchangeParameters.OperationID,
			ExchangeParameters.TimeConsumingOperationAllowed);
			
	EndIf;

EndProcedure

// Matches the GetIBParameters web service operation.
Function GetParametersOfInfobase(Proxy, ProxyVersion, ExchangePlanName, NodeCode, ErrorMessage,
	DataArea, AdditionalParameters = Undefined) Export
	
	If Version3_0_2_2(ProxyVersion) Then
		
		If AdditionalParameters = Undefined Then
			AdditionalParameters = New Structure;
		EndIf;
		
		AdditionalXDTOParameters = XDTOSerializer.WriteXDTO(AdditionalParameters);
		
		Return Proxy.GetIBParameters(ExchangePlanName, NodeCode, ErrorMessage, DataArea, AdditionalXDTOParameters);
		
	ElsIf Version3_0_2_1(ProxyVersion) Then
		
		Return Proxy.GetIBParameters(ExchangePlanName, NodeCode, ErrorMessage, DataArea);
			
	Else
		
		Return Proxy.GetIBParameters(ExchangePlanName, NodeCode, ErrorMessage);
		
	EndIf;
	
EndFunction 

// An analog of the "GetContinuousOperationStatus" operation
Function GetLongRunningOperationStatus(Proxy, ProxyVersion, ExchangeSettingsStructure, ExchangeParameters, ErrorMessageString) Export
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Return Proxy.GetContinuousOperationStatus(ExchangeParameters.OperationID,
			ErrorMessageString, 
			ExchangeSettingsStructure.TransportSettings.WSCorrespondentDataArea);
		
	Else
	
		Return Proxy.GetContinuousOperationStatus(ExchangeParameters.OperationID, ErrorMessageString);
		
	EndIf;
	
EndFunction

// An analog of the "PutMessageForDataMatching" operation
Procedure PutMessageForDataMapping(Proxy, ProxyVersion, ExchangeSettingsStructure, FileIDAsString) Export
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.PutMessageForDataMatching(ExchangeSettingsStructure.CorrespondentExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			FileIDAsString,
			ExchangeSettingsStructure.TransportSettings.WSCorrespondentDataArea);

		
	Else
		
		Proxy.PutMessageForDataMatching(ExchangeSettingsStructure.ExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			FileIDAsString);
	
	EndIf;
	
EndProcedure

// An analog of the "RemoveExchangeNode" operation
Procedure DeleteExchangeNode(Proxy, ProxyVersion, ExchangeSettingsStructure) Export
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.RemoveExchangeNode(ExchangeSettingsStructure.CorrespondentExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			ExchangeSettingsStructure.TransportSettings.WSCorrespondentDataArea);
			   
	Else
	
		Proxy.RemoveExchangeNode(ExchangeSettingsStructure.ExchangePlanName, ExchangeSettingsStructure.CurrentExchangePlanNodeCode1);
		
	EndIf;
	
EndProcedure

// An analog of the "CreateExchangeNode" operation
Procedure CreateExchangeNode(Proxy, ProxyVersion, ConnectionParameters, DataArea) Export
	
	Serializer = New XDTOSerializer(Proxy.XDTOFactory);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.CreateExchangeNode(Serializer.WriteXDTO(ConnectionParameters), DataArea);
		
	Else
		
		Proxy.CreateExchangeNode(Serializer.WriteXDTO(ConnectionParameters));
		
	EndIf;
	
EndProcedure

// Returns:
//   String
//
Function EstablishWebServiceConnectionEventLogEvent() Export
	
	Return NStr("ru = 'Обмен данными.Установка подключения к web-сервису';
				|en = 'Data exchange.Establish web service connection';", Common.DefaultLanguageCode());
	
EndFunction

// Returns:
//   String
//
Function TempFileDeletionEventLogEvent() Export
	
	Return NStr("ru = 'Обмен данными.Удаление временного файла';
				|en = 'Data exchange.Delete temporary file';", Common.DefaultLanguageCode());
	
EndFunction

// Returns:
//   String
//
Function EventLogEventTransportChangedOnWS() Export
	
	Return NStr("ru = 'Обмен данными.Изменение транспорта на WS';
				|en = 'Data exchange.Change transport to WS';", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#Region Private

Procedure WaitingForTheOperationToComplete(ExchangeSettingsStructure, ExchangeParameters, Proxy, ProxyParameters, ActionWhenExchangingInThisInformationSystem = Undefined)
	
	If ExchangeParameters.TheTimeoutOnTheServer = 0 Then
		
		If ActionWhenExchangingInThisInformationSystem <> Undefined Then
			
			// For this infobase, "Import". Therefore, for the peer infobase, "Export".
			If ActionWhenExchangingInThisInformationSystem = Enums.ActionsOnExchange.DataImport Then
				
				ActionInTheCorrespondentLine = NStr("ru = 'выгрузка';
														|en = 'export';", Common.DefaultLanguageCode());
				
			Else
				
				ActionInTheCorrespondentLine = NStr("ru = 'загрузка';
														|en = 'import';", Common.DefaultLanguageCode());
				
			EndIf;
			
			MessageTemplate = NStr("ru = 'Ожидание выполнения операции (%1 данных в базе-корреспонденте)...';
									|en = 'Waiting for the operation to be executed (%1 of the data in the peer infobase)…';", Common.DefaultLanguageCode());
			DataExchangeServer.WriteEventLogDataExchange(StrTemplate(MessageTemplate, ActionInTheCorrespondentLine), ExchangeSettingsStructure);
			
		EndIf;
		
		Return;
		
	EndIf;
	
	While ExchangeParameters.TimeConsumingOperation Do // Replace recursion.
		
		DataExchangeServer.Pause(ExchangeParameters.TheTimeoutOnTheServer);
		
		ErrorMessageString = "";
	
		ActionState = GetLongRunningOperationStatus(Proxy, ProxyParameters.CurrentVersion,
			ExchangeSettingsStructure, ExchangeParameters, ErrorMessageString);
			
			If ActionState = "Active" Then
			
			ExchangeParameters.TheTimeoutOnTheServer = Min(ExchangeParameters.TheTimeoutOnTheServer + 30, 180);
			
		ElsIf ActionState = "Completed" Then
			
			ExchangeParameters.TheTimeoutOnTheServer = 15;
			ExchangeParameters.TimeConsumingOperation = False; 
			ExchangeParameters.OperationID = Undefined;
			
		Else
			
			Raise StrTemplate(NStr("ru = 'Ошибка в базе-корреспонденте:%1 %2';
											|en = 'Peer infobase error:%1 %2';"), Chars.LF, ErrorMessageString);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function Version3_0_2_1(ProxyVersion)
	
	Return CommonClientServer.CompareVersions(ProxyVersion, "3.0.2.1") >= 0;
		
EndFunction

Function Version3_0_2_2(ProxyVersion)
	
	Return CommonClientServer.CompareVersions(ProxyVersion, "3.0.2.2") >= 0;
		
EndFunction


// An analog of the "PrepareGetFile" operation
Function PrepareFileForReceipt(Proxy, ProxyVersion, ExchangeSettingsStructure,
	FileID, PartSize, SessionID, PartCount)
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Return Proxy.PrepareGetFile(FileID,
			PartSize,
			SessionID,
			PartCount, 
			ExchangeSettingsStructure.TransportSettings.WSCorrespondentDataArea);
		
	Else
	
		Return Proxy.PrepareGetFile(FileID, PartSize, SessionID, PartCount);
	
	EndIf;
	
EndFunction

// An analog of the "GetFilePart" operation
Procedure GetFileChunk(Proxy, ProxyVersion, ExchangeSettingsStructure, SessionID, PartNumber, PartData)
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.GetFilePart(SessionID,
			PartNumber, PartData,
			ExchangeSettingsStructure.TransportSettings.WSCorrespondentDataArea);
			
	Else
	
		Proxy.GetFilePart(SessionID, PartNumber, PartData);
		
	EndIf;
	
EndProcedure

// An analog of the "PutFilePart" operation
Procedure PutFileChunk(Proxy, ProxyVersion, ExchangeSettingsStructure, SessionID, PartNumber, FileData)
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.PutFilePart(SessionID, PartNumber, FileData,
			ExchangeSettingsStructure.TransportSettings.WSCorrespondentDataArea);
		
	Else
	
		Proxy.PutFilePart(SessionID, PartNumber, FileData);
		
	EndIf;
	
EndProcedure

// An analog of the "SaveFileFromParts" operation
Procedure AssembleFileFromParts(Proxy, ProxyVersion, ExchangeSettingsStructure, SessionID, PartCount, FileID)
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.SaveFileFromParts(SessionID, PartCount, FileID,
			ExchangeSettingsStructure.TransportSettings.WSCorrespondentDataArea);
	Else
		
		Proxy.SaveFileFromParts(SessionID, PartCount, FileID);
		
	EndIf; 
	
EndProcedure

// Matches the TestConnection web service operation
Function ConnectionTesting(Proxy, ProxyVersion, ExchangeSettingsStructure, ErrorMessage)
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Return Proxy.TestConnection(
			ExchangeSettingsStructure.CorrespondentExchangePlanName, 
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1, 
			ErrorMessage, 
			ExchangeSettingsStructure.TransportSettings.WSCorrespondentDataArea);
			
	Else
		
		Return Proxy.TestConnection(ExchangeSettingsStructure.ExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			ErrorMessage);
		
	EndIf;
	
EndFunction

Procedure CheckProhibitedCharsInWSProxyUsername(Val UserName)
	
	InvalidChars = ProhibitedCharsInWSProxyUsername();
	
	If StringContainsCharacter(UserName, InvalidChars) Then
		
		MessageString = NStr("ru = 'В имени пользователя %1 содержатся недопустимые символы.
			|Имя пользователя не должно содержать символы %2.';
			|en = 'Username ""%1"" contains illegal characters:
			|%2';");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, UserName, InvalidChars);
		
		Raise MessageString;
		
	EndIf;
	
EndProcedure

Function StringContainsCharacter(Val String, Val CharacterString)
	
	For IndexOf = 1 To StrLen(CharacterString) Do
		Char = Mid(CharacterString, IndexOf, 1);
		
		If StrFind(String, Char) <> 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function ProhibitedCharsInWSProxyUsername()
	
	Return ":";
	
EndFunction

Procedure CheckWSProxyAddressFormatCorrectness(Val WSProxyAddress)
	
	IsInternetAddress           = False;
	AllowedWSProxyPrefixes = AllowedWSProxyPrefixes();
	
	For Each Prefix In AllowedWSProxyPrefixes Do
		If Left(Lower(WSProxyAddress), StrLen(Prefix)) = Lower(Prefix) Then
			IsInternetAddress = True;
			Break;
		EndIf;
	EndDo;
	
	If Not IsInternetAddress Then
		PrefixesString = "";
		For Each Prefix In AllowedWSProxyPrefixes Do
			PrefixesString = PrefixesString + ?(IsBlankString(PrefixesString), """", " or """) + Prefix + """";
		EndDo;
		
		MessageString = NStr("ru = 'Неверный формат адреса ""%1"".
			|Адрес должен начинаться с префикса Интернет протокола %2 (например: ""http://myserver.com/service"").';
			|en = 'Invalid address format: ""%1"".
			|An address must start with an Internet protocol prefix: %2. For example, ""http://myserver.com/service"".';");
			
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, WSProxyAddress, PrefixesString);
		
		Raise MessageString;
	EndIf;
	
EndProcedure

Function AllowedWSProxyPrefixes()
	
	Result = New Array();
	
	Result.Add("http");
	Result.Add("https");
	
	Return Result;
	
EndFunction

Function SynchronizationSetupStatusInCorrespondent(Proxy, ProxyParameters, SettingsStructure_)
	
	Result = New Structure;
	Result.Insert("SettingExists",                     False);
	
	Result.Insert("DataSynchronizationSetupCompleted",   True);
	Result.Insert("MessageReceivedForDataMapping", False);
	Result.Insert("DataMappingSupported",       True);
		
	ErrorMessageString = "";
	If CommonClientServer.CompareVersions(ProxyParameters.CurrentVersion, "2.0.1.6") >= 0 Then
		
		SettingExists = ConnectionTesting(Proxy, ProxyParameters.CurrentVersion, SettingsStructure_, ErrorMessageString);
		
		If SettingExists
			And CommonClientServer.CompareVersions(ProxyParameters.CurrentVersion, "3.0.1.1") >= 0 Then
			
			ProxyDestinationParameters = GetParametersOfInfobase(Proxy, ProxyParameters.CurrentVersion,
				SettingsStructure_.CorrespondentExchangePlanName,
				SettingsStructure_.CurrentExchangePlanNodeCode1,
				ErrorMessageString,
				SettingsStructure_.TransportSettings.WSCorrespondentDataArea);
			
			DestinationParameters = XDTOSerializer.ReadXDTO(ProxyDestinationParameters);
			
			FillPropertyValues(Result, DestinationParameters);
		EndIf;
		
		Result.SettingExists = SettingExists;
	Else
		
		ProxyDestinationParameters = GetParametersOfInfobase(Proxy, ProxyParameters.CurrentVersion,
				SettingsStructure_.ExchangePlanName,
				SettingsStructure_.CurrentExchangePlanNodeCode1,
				ErrorMessageString,
				SettingsStructure_.TransportSettings.WSCorrespondentDataArea);
			
		DestinationParameters = ValueFromStringInternal(ProxyDestinationParameters);
		
		If DestinationParameters.Property("NodeExists") Then
			Result.SettingExists = DestinationParameters.NodeExists;
		Else
			Result.SettingExists = True;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

Function ObsoleteExchangeSettingsOptionInCorrespondent(Proxy, ProxyParameters, SetupStatus, SettingsStructure_, NodeCode, Cancel, ErrorMessageString = "")
	
	StateOfOptionSetup = New Structure();
	StateOfOptionSetup.Insert("TransportSettings", SettingsStructure_.TransportSettings);
	
	// Checking if migration is possible.
	For Each SettingsMode In ObsoleteExchangeSettingsOptions(SettingsStructure_.InfobaseNode) Do
		
		StateOfOptionSetup.Insert("ExchangePlanName", SettingsMode.ExchangePlanName);
		StateOfOptionSetup.Insert("CurrentExchangePlanNodeCode1", NodeCode);
				
		SetupStatus = SynchronizationSetupStatusInCorrespondent(
			Proxy, ProxyParameters, StateOfOptionSetup);
		
		If SetupStatus.SettingExists Then
			If SettingsStructure_.ActionOnExchange = Enums.ActionsOnExchange.DataExport Then
				SettingsStructure_.ExchangePlanName = SettingsMode.ExchangePlanName;
				If NodeCode <> SettingsStructure_.CurrentExchangePlanNodeCode1 Then
					SettingsStructure_.CurrentExchangePlanNodeCode1 = NodeCode;
				EndIf;
			Else
				// This infobase has switched to another exchange plan, and its peer hasn't.
				// Data import is aborted.
				ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В программе ""%1"" выполняется обновление настроек синхронизации.
					|Загрузка данных отменена. Запустите синхронизацию данных повторно.';
					|en = 'Synchronization settings are being updated in ""%1"" application.
					|The data import is canceled. Restart the data synchronization later.';"),
					String(SettingsStructure_.InfobaseNode));
				Cancel = True;
			EndIf;
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function ObsoleteExchangeSettingsOptions(ExchangeNode)
	
	Result = New Array;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeNode);
	
	SettingsMode = "";
	If Common.HasObjectAttribute("SettingsMode", ExchangeNode.Metadata()) Then
		SettingsMode = Common.ObjectAttributeValue(ExchangeNode, "SettingsMode");
	EndIf;
	
	If ValueIsFilled(SettingsMode) Then
		For Each PreviousExchangePlanName In DataExchangeCached.SSLExchangePlans() Do
			If PreviousExchangePlanName = ExchangePlanName Then
				Continue;
			EndIf;
			If DataExchangeCached.IsDistributedInfobaseExchangePlan(PreviousExchangePlanName) Then
				Continue;
			EndIf;
			
			PreviousExchangePlanSettings = DataExchangeServer.ExchangePlanSettingValue(PreviousExchangePlanName,
				"ExchangePlanNameToMigrateToNewExchange,ExchangeSettingsOptions");
			
			If PreviousExchangePlanSettings.ExchangePlanNameToMigrateToNewExchange = ExchangePlanName Then
				SettingsOption = PreviousExchangePlanSettings.ExchangeSettingsOptions.Find(SettingsMode, "SettingID");
				If Not SettingsOption = Undefined Then
					Result.Add(New Structure("ExchangePlanName, SettingID", 
						PreviousExchangePlanName, SettingsOption.SettingID));
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

// Sets the data synchronization password for the specified node.
// Saves the password to a session parameter.
//
Procedure SetDataSynchronizationPassword(Val InfobaseNode, Val Password)
	
	SetPrivilegedMode(True);
	
	DataSynchronizationPasswords = New Map;
	
	For Each Item In SessionParameters.DataSynchronizationPasswords Do
		
		DataSynchronizationPasswords.Insert(Item.Key, Item.Value);
		
	EndDo;
	
	DataSynchronizationPasswords.Insert(InfobaseNode, Password);
	
	SessionParameters.DataSynchronizationPasswords = New FixedMap(DataSynchronizationPasswords);
	
EndProcedure

// Resets the data synchronization password for the specified node.
//
Procedure ResetDataSynchronizationPassword(Val InfobaseNode)
	
	SetDataSynchronizationPassword(InfobaseNode, Undefined);
	
EndProcedure

#EndRegion

