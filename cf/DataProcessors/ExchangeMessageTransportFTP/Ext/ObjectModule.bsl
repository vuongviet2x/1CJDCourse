///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables
Var ErrorMessageString Export;
Var ErrorMessageStringEL Export;

Var ErrorsMessages; // Map that contains predefined error messages.
Var ObjectName;		// Metadata object name.
Var FTPServerName;		// FTP server name or IP address.
Var DirectoryAtFTPServer;// FTP server address is a name or address.

Var TempExchangeMessageFile; // A temporary exchange message file.
Var TempExchangeMessagesDirectory; // Temporary exchange message file for importing and exporting data.

Var SendGetDataTimeout; // Timeout for exchanging data with a FTP server.
Var ConnectionCheckTimeout; // Timeout that is used for FTP connection when sending and receiving data.

Var DirectoryID;
#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Internal export procedures and functions.

// Creates a temporary directory in the temporary file directory of the operating system user.
//
// Parameters:
//  No.
// 
//  Returns:
//    Boolean - True if the function is executed successfully, False if an error occurred.
// 
Function ExecuteActionsBeforeProcessMessage() Export
	
	InitMessages();
	
	DirectoryID = Undefined;
	
	Return CreateTempExchangeMessagesDirectory();
	
EndFunction

// Sends the exchange message to the specified resource from the temporary exchange message directory.
//
// Parameters:
//  No.
// 
//  Returns:
//    Boolean - True if the function is executed successfully, False if an error occurred.
// 
Function SendMessage() Export
	
	InitMessages();
	
	Try
		Result = SendExchangeMessage();
	Except
		Result = False;
	EndTry;
	
	Return Result;
	
EndFunction

// Gets an exchange message from the specified resource and puts it in the temporary exchange message directory.
//
// Parameters:
//  ExistenceCheck - Boolean - True if it is necessary to check whether exchange messages exist without their import.
// 
//  Returns:
//    Boolean - True if the function is executed successfully, False if an error occurred.
// 
Function GetMessage(ExistenceCheck = False) Export
	
	InitMessages();
	
	Try
		Result = GetExchangeMessage(ExistenceCheck);
	Except
		Result = False;
	EndTry;
	
	Return Result;
	
EndFunction

// Deletes the temporary exchange message directory after performing data import or export.
//
// Parameters:
//  No.
// 
//  Returns:
//    Boolean - True
//
Function ExecuteActionsAfterProcessMessage() Export
	
	InitMessages();
	
	DeleteTempExchangeMessagesDirectory();
	
	Return True;
	
EndFunction

// Initializes data processor properties with initial values and constants.
//
// Parameters:
//  No.
// 
Procedure Initialize() Export
	
	InitMessages();
	
	ServerNameAndDirectoryAtServer = SplitFTPResourceToServerAndDirectory(TrimAll(FTPConnectionPath));
	FTPServerName			= ServerNameAndDirectoryAtServer.ServerName;
	DirectoryAtFTPServer	= ServerNameAndDirectoryAtServer.DirectoryName;
	
EndProcedure

// Checks whether the connection to the specified resource can be established.
//
// Parameters:
//  No.
// 
//  Returns:
//    Boolean - True if connection can be established. Otherwise, False.
//
Function ConnectionIsSet() Export
	
	// Function return value.
	Result = True;
	
	If Common.DataSeparationEnabled() Then
		Return Result;
	EndIf;
	
	InitMessages();
	
	If IsBlankString(FTPConnectionPath) Then
		
		GetErrorMessage(101);
		Return False;
		
	EndIf;
	
	// Creating a file in the temporary directory.
	TempConnectionTestFileName = GetTempFileName("tmp");
	FileNameForDestination = DataExchangeServer.TempConnectionTestFileName();
	
	TextWriter = New TextWriter(TempConnectionTestFileName);
	TextWriter.WriteLine(FileNameForDestination);
	TextWriter.Close();
	
	// Copying a file to the external resource from the temporary directory.
	Result = CopyFileToFTPServer(TempConnectionTestFileName, FileNameForDestination, ConnectionCheckTimeout);
	
	// Deleting a file from the external resource.
	If Result Then
		
		Result = DeleteFileAtFTPServer(FileNameForDestination, True);
		
	EndIf;
	
	// Deleting a file from the temporary directory.
	DeleteFiles(TempConnectionTestFileName);
	
	Return Result;
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Functions for retrieving properties.

// Function for retrieving property: the time of changing the exchange file message.
//
// Returns:
//  Date - time exchange message file changed.
//
Function ExchangeMessageFileDate() Export
	
	Result = Undefined;
	
	If TypeOf(TempExchangeMessageFile) = Type("File") Then
		
		If TempExchangeMessageFile.Exists() Then
			
			Result = TempExchangeMessageFile.GetModificationTime();
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Retrieves the full name of the exchange message file.
//
// Returns:
//  String - full exchange message file name.
//
Function ExchangeMessageFileName() Export
	
	Name = "";
	
	If TypeOf(TempExchangeMessageFile) = Type("File") Then
		
		Name = TempExchangeMessageFile.FullName;
		
	EndIf;
	
	Return Name;
	
EndFunction

// Retrieves the full name of the exchange message directory.
//
// Returns:
//  String - full exchange message directory name.
//
Function ExchangeMessageDirectoryName() Export
	
	Name = "";
	
	If TypeOf(TempExchangeMessagesDirectory) = Type("File") Then
		
		Name = TempExchangeMessagesDirectory.FullName;
		
	EndIf;
	
	Return Name;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Local internal procedures and functions.

Function CreateTempExchangeMessagesDirectory()
	
	// Creating the temporary exchange message directory.
	Try
		TempDirectoryName = DataExchangeServer.CreateTempExchangeMessagesDirectory(DirectoryID);
	Except
		GetErrorMessage(4);
		SupplementErrorMessage(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	TempExchangeMessagesDirectory = New File(TempDirectoryName);
	
	MessageFileName = CommonClientServer.GetFullFileName(ExchangeMessageDirectoryName(), MessageFileNameTemplate + ".xml");
	
	TempExchangeMessageFile = New File(MessageFileName);
	
	Return True;
EndFunction

Function DeleteTempExchangeMessagesDirectory()
	
	Try
		If Not IsBlankString(ExchangeMessageDirectoryName()) Then
			DeleteFiles(ExchangeMessageDirectoryName());
			TempExchangeMessagesDirectory = Undefined;
		EndIf;
		
		If Not DirectoryID = Undefined Then
			DataExchangeServer.GetFileFromStorage(DirectoryID);
			DirectoryID = Undefined;
		EndIf;
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Function SendExchangeMessage()
	
	Result = True;
	
	Extension = ?(CompressOutgoingMessageFile(), ".zip", ".xml");
	
	OutgoingMessageFileName = MessageFileNameTemplate + Extension;
	
	If CompressOutgoingMessageFile() Then
		
		// Getting the temporary archive file name.
		ArchiveTempFileName = CommonClientServer.GetFullFileName(ExchangeMessageDirectoryName(), MessageFileNameTemplate + ".zip");
		
		Try
			
			Archiver = New ZipFileWriter(ArchiveTempFileName, ArchivePasswordExchangeMessages, NStr("ru = 'Файл сообщения обмена';
																										|en = 'Exchange message file';"));
			Archiver.Add(ExchangeMessageFileName());
			Archiver.Write();
			
		Except
			
			Result = False;
			GetErrorMessage(3);
			SupplementErrorMessage(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
		EndTry;
		
		Archiver = Undefined;
		
		If Result Then
			
			// Checking that the exchange message size does not exceed the maximum allowed size.
			If DataExchangeServer.ExchangeMessageSizeExceedsAllowed(ArchiveTempFileName, MaxMessageSize()) Then
				GetErrorMessage(108);
				Result = False;
			EndIf;
			
		EndIf;
		
		If Result Then
			
			// Copying the archive file to the FTP server in the data exchange directory.
			If Not CopyFileToFTPServer(ArchiveTempFileName, OutgoingMessageFileName, SendGetDataTimeout) Then
				Result = False;
			EndIf;
			
		EndIf;
		
	Else
		
		If Result Then
			
			// Checking that the exchange message size does not exceed the maximum allowed size.
			If DataExchangeServer.ExchangeMessageSizeExceedsAllowed(ExchangeMessageFileName(), MaxMessageSize()) Then
				GetErrorMessage(108);
				Result = False;
			EndIf;
			
		EndIf;
		
		If Result Then
			
			// Copying the archive file to the FTP server in the data exchange directory.
			If Not CopyFileToFTPServer(ExchangeMessageFileName(), OutgoingMessageFileName, SendGetDataTimeout) Then
				Result = False;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function GetExchangeMessage(ExistenceCheck)
	
	ExchangeMessagesFilesTable = New ValueTable;
	ExchangeMessagesFilesTable.Columns.Add("File");
	ExchangeMessagesFilesTable.Columns.Add("Modified");
	
	Try
		FTPConnection = GetFTPConnection(SendGetDataTimeout);
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		GetErrorMessage(102);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	MessageFileNameTemplateForSearch = StrReplace(MessageFileNameTemplate, "Message", "Message*");

	Try
		FoundFileArray = FTPConnection.FindFiles(DirectoryAtFTPServer, MessageFileNameTemplateForSearch + ".*", False);
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		GetErrorMessage(104);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	
	For Each CurrentFile In FoundFileArray Do
		
		// Checking the required extension.
		If ((Upper(CurrentFile.Extension) <> ".ZIP")
			And (Upper(CurrentFile.Extension) <> ".XML")) Then
			
			Continue;
			
		// Checking that it is a file, not a directory.
		ElsIf Not CurrentFile.IsFile() Then
			
			Continue;
			
		// Checking that the file size is greater than 0.
		ElsIf (CurrentFile.Size() = 0) Then
			
			Continue;
			
		EndIf;
		
		// The file is a required exchange message. Adding the file to the table.
		TableRow = ExchangeMessagesFilesTable.Add();
		TableRow.File           = CurrentFile;
		TableRow.Modified = CurrentFile.GetModificationTime();
		
	EndDo;
	
	If ExchangeMessagesFilesTable.Count() = 0 Then
		
		If Not ExistenceCheck Then
			GetErrorMessage(1);
		
			MessageString = NStr("ru = 'Каталог обмена информацией на сервере: ""%1""';
									|en = 'The data exchange directory on the server is %1.';");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, DirectoryAtFTPServer);
			SupplementErrorMessage(MessageString);
			
			MessageString = NStr("ru = 'Имя файла сообщения обмена: ""%1"" или ""%2""';
									|en = 'Exchange message file name is %1 or %2';");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, MessageFileNameTemplate + ".xml", MessageFileNameTemplate + ".zip");
			SupplementErrorMessage(MessageString);
		EndIf;
		
		Return False;
		
	Else
		
		If ExistenceCheck Then
			Return True;
		EndIf;
		
		ExchangeMessagesFilesTable.Sort("Modified Desc");
		
		// Obtaining the newest exchange message file from the table.
		IncomingMessageFile = ExchangeMessagesFilesTable[0].File;
		
		FilePacked = (Upper(IncomingMessageFile.Extension) = ".ZIP");
		
		InformationRegisters.ArchiveOfExchangeMessages.PackMessageToArchive(InfobaseNode, IncomingMessageFile.FullName);
		
		If FilePacked Then
			
			// Getting the temporary archive file name.
			ArchiveTempFileName = CommonClientServer.GetFullFileName(ExchangeMessageDirectoryName(), MessageFileNameTemplate + ".zip");
			
			Try
				FTPConnection.Get(IncomingMessageFile.FullName, ArchiveTempFileName);
			Except
				ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				GetErrorMessage(105);
				SupplementErrorMessage(ErrorText);
				Return False;
			EndTry;
			
			// Unpacking the temporary archive file.
			SuccessfullyUnpacked = DataExchangeServer.UnpackZipFile(ArchiveTempFileName, ExchangeMessageDirectoryName(), ArchivePasswordExchangeMessages);
			
			If Not SuccessfullyUnpacked Then
				GetErrorMessage(2);
				Return False;
			EndIf;
			
			// Checking that the message file exists.
			File = New File(ExchangeMessageFileName());
			
			If Not File.Exists() Then
				// The archive name probably does not match name of the file inside.
				ArchiveFileNameStructure = CommonClientServer.ParseFullFileName(IncomingMessageFile.Name,False);
				MessageFileNameStructure = CommonClientServer.ParseFullFileName(ExchangeMessageFileName(),False);
				
				If ArchiveFileNameStructure.BaseName <> MessageFileNameStructure.BaseName Then
					UnpackedFilesArray = FindFiles(ExchangeMessageDirectoryName(), "*.xml", False);
					If UnpackedFilesArray.Count() > 0 Then
						UnpackedFile = UnpackedFilesArray[0];
						MoveFile(UnpackedFile.FullName,ExchangeMessageFileName());
					Else
						GetErrorMessage(7);
						Return False;
					EndIf;
				Else
					GetErrorMessage(7);
					Return False;
				EndIf;
				
			EndIf;
			
		Else
			Try
				FTPConnection.Get(IncomingMessageFile.FullName, ExchangeMessageFileName());
			Except
				ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				GetErrorMessage(105);
				SupplementErrorMessage(ErrorText);
				Return False;
			EndTry;
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

Procedure GetErrorMessage(MessageNo)
	
	SetErrorMessageString(ErrorsMessages[MessageNo]);
	
EndProcedure

Procedure SetErrorMessageString(Val Message)
	
	If Message = Undefined Then
		Message = NStr("ru = 'Внутренняя ошибка';
						|en = 'Internal error';");
	EndIf;
	
	ErrorMessageString   = Message;
	ErrorMessageStringEL = ObjectName + ": " + Message;
	
EndProcedure

Procedure SupplementErrorMessage(Message)
	
	ErrorMessageStringEL = ErrorMessageStringEL + Chars.LF + Message;
	
EndProcedure

// The overridable function, returns the maximum allowed size of
// a message to be sent.
// 
Function MaxMessageSize()
	
	Return FTPConnectionMaxMessageSize;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Functions for retrieving properties.

Function CompressOutgoingMessageFile()
	
	Return FTPCompressOutgoingMessageFile;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Initialization.

Procedure InitMessages()
	
	ErrorMessageString   = "";
	ErrorMessageStringEL = "";
	
EndProcedure

Procedure ErrorMessageInitialization()
	
	ErrorsMessages = New Map;
	
	// General error codes
	ErrorsMessages.Insert(001, NStr("ru = 'В каталоге обмена информацией не был обнаружен файл сообщения с данными.';
										|en = 'No message file with data was found in the exchange directory.';"));
	ErrorsMessages.Insert(002, NStr("ru = 'Ошибка при распаковке сжатого файла сообщения.';
										|en = 'Error extracting message file.';"));
	ErrorsMessages.Insert(003, NStr("ru = 'Ошибка при сжатии файла сообщения обмена.';
										|en = 'Error packing the exchange message file.';"));
	ErrorsMessages.Insert(004, NStr("ru = 'Ошибка при создании временного каталога.';
										|en = 'An error occurred when creating a temporary directory.';"));
	ErrorsMessages.Insert(005, NStr("ru = 'Архив не содержит файл сообщения обмена.';
										|en = 'The archive does not contain the exchange message file.';"));
	
	// Transport-specific error codes.
	ErrorsMessages.Insert(101, NStr("ru = 'Не задан путь на сервере.';
										|en = 'Path on the server is not specified.';"));
	ErrorsMessages.Insert(102, NStr("ru = 'Ошибка инициализации подключения к FTP-серверу.';
										|en = 'An error occurred when initializing connection to the FTP server.';"));
	ErrorsMessages.Insert(103, NStr("ru = 'Ошибка подключения к FTP-серверу, проверьте правильность задания пути и права доступа к ресурсу.';
										|en = 'An error occurred when establishing connection to the FTP server. Check whether the path is specified correctly and access rights are sufficient.';"));
	ErrorsMessages.Insert(104, NStr("ru = 'Ошибка при поиске файлов на FTP-сервере.';
										|en = 'Error searching for files on the FTP server.';"));
	ErrorsMessages.Insert(105, NStr("ru = 'Ошибка при получении файла с FTP-сервера.';
										|en = 'Error receiving the file from the FTP server.';"));
	ErrorsMessages.Insert(106, NStr("ru = 'Ошибка удаления файла на FTP-сервере, проверьте права доступа к ресурсу.';
										|en = 'Error deleting the file from the FTP server. Check whether resource access rights are sufficient.';"));
	
	ErrorsMessages.Insert(108, NStr("ru = 'Превышен допустимый размер сообщения обмена.';
										|en = 'The maximum allowed exchange message size is exceeded.';"));
	
	ErrorsMessages.Insert(109, NStr("ru = 'Ошибка при попытке установить активное соединение с FTP-сервером. Попробуйте использовать пассивное соединение.';
										|en = 'An error occurred during the attempt to establish an active connection to the FTP server. Try establishing a passive connection.';"));
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// FTP management.

Function GetFTPConnection(Timeout)
	
	FTPSettings = DataExchangeServer.FTPConnectionSetup(Timeout);
	FTPSettings.Server               = FTPServerName;
	FTPSettings.Port                 = FTPConnectionPort;
	FTPSettings.UserName      = FTPConnectionUser;
	FTPSettings.UserPassword   = FTPConnectionPassword;
	FTPSettings.PassiveConnection  = FTPConnectionPassiveConnection;
	FTPSettings.SecureConnection = DataExchangeServer.SecureConnection(FTPConnectionPath);
	
	Return DataExchangeServer.FTPConnection(FTPSettings);
	
EndFunction

Function CopyFileToFTPServer(Val SourceFileName, ReceiverFileName, Val Timeout)
	
	Var DirectoryAtServer;
	
	ServerAndDirectoryAtServer = SplitFTPResourceToServerAndDirectory(TrimAll(FTPConnectionPath));
	DirectoryAtServer = ServerAndDirectoryAtServer.DirectoryName;
	
	Try
		FTPConnection = GetFTPConnection(Timeout);
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		GetErrorMessage(102);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	
	If Timeout = ConnectionCheckTimeout 
		And FTPConnection.PassiveMode 
		And Not FTPConnectionPassiveConnection Then	
		ErrorText = "";
		GetErrorMessage(109);
		SupplementErrorMessage(ErrorText);		
		Return False;
	EndIf;
	
	CreateDirectoryIfNecessary(FTPConnection, DirectoryAtServer);
	
	Try
		FTPConnection.Put(SourceFileName, DirectoryAtServer + ReceiverFileName);
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		GetErrorMessage(103);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	
	If Common.DataSeparationEnabled() Then
		Return True;
	EndIf;
	
	Try
		FilesArray = FTPConnection.FindFiles(DirectoryAtServer, ReceiverFileName, False);
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		GetErrorMessage(104);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	
	Return FilesArray.Count() > 0;
	
EndFunction

Procedure CreateDirectoryIfNecessary(FTPConnection, DirectoryAtServer)
	
	If DirectoryAtServer = "/" Then
		Return;
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		
		// In SaaS mode, checking if a directory exists is a resource-intensive operation.
		// Instead, run "CreateDirectory", and if it already exists, throw an exception and exit. 
		// 
		Try
			FTPConnection.CreateDirectory(DirectoryAtServer);
		Except
			// No action required
		EndTry;
		
	Else	
		
		NamesArray = StrSplit(DirectoryAtServer, "/", False);
		DirectoryName = "";
		
		For Each Name In NamesArray Do
		
			DirectoryName = DirectoryName + "/" + Name;
		
			If FTPConnection.FindFiles(DirectoryName).Count() = 0 Then
				FTPConnection.CreateDirectory(DirectoryName);
			EndIf;
		
		EndDo;
	
	EndIf;
	
EndProcedure

Function DeleteFileAtFTPServer(Val FileName, ConnectionCheckUp = False)
	
	Var DirectoryAtServer;
	
	ServerAndDirectoryAtServer = SplitFTPResourceToServerAndDirectory(TrimAll(FTPConnectionPath));
	DirectoryAtServer = ServerAndDirectoryAtServer.DirectoryName;
	
	Try
		FTPConnection = GetFTPConnection(ConnectionCheckTimeout);
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		GetErrorMessage(102);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	
	Try
		FTPConnection.Delete(DirectoryAtServer + FileName);
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		GetErrorMessage(106);
		SupplementErrorMessage(ErrorText);
		
		If ConnectionCheckUp Then
			
			ErrorMessage = NStr("ru = 'Не удалось проверить подключение с помощью тестового файла ""%1"".
			|Возможно, заданный каталог не существует или не доступен.
			|Рекомендуется также обратиться к документации по FTP-серверу для настройки поддержки имен файлов с кириллицей.';
			|en = 'Cannot check connection using test file ""%1"".
			|Maybe, the specified directory does not exist or is unavailable.
			|Check FTP server documentation to configure support of Cyrillic file names.';");
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessage, FileName);
			SupplementErrorMessage(ErrorMessage);
			
		EndIf;
		
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Function SplitFTPResourceToServerAndDirectory(Val FullPath)
	
	Result = New Structure("ServerName, DirectoryName");
	
	FTPParameters = DataExchangeServer.FTPServerNameAndPath(FullPath);
	
	Result.ServerName  = FTPParameters.Server;
	Result.DirectoryName = FTPParameters.Path;
	
	Return Result;
EndFunction

#EndRegion

#Region Initialize

InitMessages();
ErrorMessageInitialization();

TempExchangeMessagesDirectory = Undefined;
TempExchangeMessageFile    = Undefined;

FTPServerName       = Undefined;
DirectoryAtFTPServer = Undefined;

ObjectName = NStr("ru = 'Обработка: %1';
					|en = 'Data processor: %1';");
ObjectName = StringFunctionsClientServer.SubstituteParametersToString(ObjectName, Metadata().Name);

SendGetDataTimeout = 12*60*60;
ConnectionCheckTimeout = 10;

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf