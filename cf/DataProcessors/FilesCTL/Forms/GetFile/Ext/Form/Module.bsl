//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("FileNameOrAddress", FileNameOrAddress);
	FileProperties = FilesCTL.TemporaryStorageFileProperties(FileNameOrAddress);
	If FileProperties.Registered Then
		WindowsFilePath = FileProperties.WindowsPath;
		LinuxFilePath = FileProperties.LinuxPath;
	Else
		Parameters.Property("WindowsFilePath", WindowsFilePath);
		Parameters.Property("LinuxFilePath", LinuxFilePath);
	EndIf;
	
	FileNameAtServer = FilesCTL.FullNameOfFileInSession(FileNameOrAddress, WindowsFilePath, LinuxFilePath);
	FSObject = New File(FileNameAtServer);
	If Not FSObject.Exists() Or Not FSObject.IsFile() Then
		Raise NStr("ru = 'Файл на сервере не найден';
								|en = 'File is not found on the server';");
	EndIf;
	
	Parameters.Property("FileNameOfSaveDialog", FileNameOfSaveDialog);
	If IsBlankString(FileNameOfSaveDialog) Then 
		FileNameOfSaveDialog = FSObject.Name;
	EndIf;
	FileSize = FSObject.Size();
	PortionSize = FilesCTLClientServer.ProcessingPortionSize(FileSize);
	
	Parameters.Property("DialogTitle", DialogTitle);
	If ValueIsFilled(DialogTitle) Then
		Title = DialogTitle;
		AutoTitle = False;
	EndIf;
	
	Parameters.Property("FilterSaveDialog", DIalogBoxFilter);
	
	If Parameters.Property("FileNameAtClient", FileNameAtClient) Then
		FilePresentation = FilesCTLClientServer.FilePresentation(FileNameAtClient, FileSize);
		Items.Pages.CurrentPage = Items.ProgressPage;
	Else
		FilePresentation = FilesCTLClientServer.FilePresentation(FileNameOfSaveDialog, FileSize);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(FileNameAtClient) Then
		WriteFile(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	CancelWrite = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenCommand(Command)
	
	DownloadFile(True);
	
EndProcedure

&AtClient
Procedure Save(Command)
	
	DownloadFile(False);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure DownloadFile(Open)
	
	If Open Then
		
		BeginGettingTempFilesDir(New NotifyDescription("AfterGettingTemporaryDirectory", ThisObject));
		
	Else
		
		Dialog = New FileDialog(FileDialogMode.Save);
		Dialog.Title = DialogTitle;
		Dialog.FullFileName = FileNameOfSaveDialog;
		Dialog.Filter = DIalogBoxFilter;
		Dialog.Show(New NotifyDescription("AfterFileNameChoice", ThisObject));
		
	EndIf;
	
EndProcedure

// After getting a temporary directory.
// 
// Parameters:
//  Directory - String
//  AdditionalParameters - Structure
&AtClient
Procedure AfterGettingTemporaryDirectory(Directory, AdditionalParameters) Export
	
	If Not StrEndsWith(Directory, GetPathSeparator()) Then
		Directory = Directory + GetPathSeparator();
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Directory", Directory);
	AdditionalParameters.Insert("FileNumber", -1);
	AdditionalParameters.Insert("FileName", "");
	AfterCheckingExistenceOfTemporaryFile(True, AdditionalParameters);
		
EndProcedure

// After checking whether the temporary file exists.
// 
// Parameters:
//  Exists - Boolean - Exists.
//  AdditionalParameters - Structure - More:
// * Directory - String
// * FileNumber - Number
// * FileName - String
&AtClient
Procedure AfterCheckingExistenceOfTemporaryFile(Exists, AdditionalParameters) Export
	
	If Exists Then
		AdditionalParameters.FileNumber = AdditionalParameters.FileNumber + 1;
		File = New File(FileNameOfSaveDialog);
		Parts = New Array; // Array of String
		Parts.Add(AdditionalParameters.Directory);
		Parts.Add(File.BaseName);
		If AdditionalParameters.FileNumber > 0 Then
			Parts.Add("~");
			Parts.Add(Format(AdditionalParameters.FileNumber, "NG=0"));
		EndIf;
		Parts.Add(File.Extension);
		AdditionalParameters.FileName = StrConcat(Parts);
		File = New File(AdditionalParameters.FileName);
		File.BeginCheckingExistence(New NotifyDescription("AfterCheckingExistenceOfTemporaryFile",
			ThisObject, AdditionalParameters));
	Else
		Items.Pages.CurrentPage = Items.ProgressPage;
		FileNameAtClient = AdditionalParameters.FileName;
		WriteFile(True);
	EndIf;

EndProcedure

// After selecting the file name.
// 
// Parameters:
//  SelectedFiles - Array of String, Undefined
//  AdditionalParameters - Structure
&AtClient
Procedure AfterFileNameChoice(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Close();
		Return;
	EndIf;
	
	FileNameAtClient = SelectedFiles[0];
	FilePresentation = FilesCTLClientServer.FilePresentation(FileNameAtClient, FileSize);
	Items.Pages.CurrentPage = Items.ProgressPage;
	WriteFile(False);
	
EndProcedure

&AtClient
Procedure WriteFile(Open)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Open", Open);

	File = New File(FileNameAtClient);
	File.BeginCheckingExistence(New NotifyDescription("AfterCheckingExistenceOfFile", ThisObject,
		AdditionalParameters));

EndProcedure

// After checking whether the file exists.
// 
// Parameters:
//  Exists - Boolean
//  AdditionalParameters - Structure
&AtClient
Procedure AfterCheckingExistenceOfFile(Exists, AdditionalParameters) Export
	
	If Exists Then
		Notification = New NotifyDescription("AfterDeletingFile", ThisObject, AdditionalParameters);
		BeginDeletingFiles(Notification, FileNameAtClient);
	Else
		WriteFileAfterVerification(AdditionalParameters);
	EndIf;
	
EndProcedure

// After deleting the file.
// 
// Parameters:
//  AdditionalParameters - Structure
&AtClient
Procedure AfterDeletingFile(AdditionalParameters) Export
	
	WriteFileAfterVerification(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure WriteFileAfterVerification(AdditionalParameters)
	
	BatchesCount = Int(FileSize / PortionSize) + ?(FileSize % PortionSize > 0, 1, 0);

	Notification = New NotifyDescription("AfterOpeningStream", ThisObject, AdditionalParameters, "InCaseOfError",
		ThisObject);
	FileStreams.BeginOpenForWrite(Notification, FileNameAtClient);

EndProcedure

// After opening the stream.
// 
// Parameters:
//  Stream - FileStream
//  AdditionalParameters - Structure
&AtClient
Procedure AfterOpeningStream(Stream, AdditionalParameters) Export
	
	AdditionalParameters.Insert("PortionNumber", 0);
	AdditionalParameters.Insert("WriteStream", Stream);
	AdditionalParameters.Insert("Address", PutToTempStorage(Undefined, UUID));
	
	RecordPortion_(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure RecordPortion_(AdditionalParameters) Export
	
	If CancelWrite Then
		AdditionalParameters.WriteStream.BeginClose(New NotifyDescription("AfterClosingStream", ThisObject,
			AdditionalParameters));
		Return;
	EndIf;

	Progress = Round(AdditionalParameters.PortionNumber * PortionSize / FileSize * 100, 0);

	If AdditionalParameters.PortionNumber = BatchesCount Then
		AdditionalParameters.WriteStream.BeginClose(New NotifyDescription("AfterClosingStream", ThisObject,
			AdditionalParameters));
		Return;
	EndIf;
	
	Batch = GetServing(FileNameOrAddress, WindowsFilePath, LinuxFilePath, AdditionalParameters.PortionNumber,
		AdditionalParameters.Address, PortionSize);

	AdditionalParameters.PortionNumber = AdditionalParameters.PortionNumber + 1;
	Notification = New NotifyDescription("RecordPortion_", ThisObject, AdditionalParameters, "InCaseOfError",
		ThisObject);
	Buffer = GetBinaryDataBufferFromBinaryData(Batch);
	AdditionalParameters.WriteStream.BeginWrite(Notification, Buffer, 0, Buffer.Size);

EndProcedure

// After closing the stream.
// 
// Parameters:
//  AdditionalParameters - Structure:
//   * Open - Boolean
&AtClient
Procedure AfterClosingStream(AdditionalParameters) Export
	
	If CancelWrite Then
		Notification = New NotifyDescription("AfterDeletingFileOnInterrupt", ThisObject, FileNameAtClient);
		BeginDeletingFiles(Notification, FileNameAtClient);
	ElsIf AdditionalParameters.Open Then
		Notification = New NotifyDescription("AfterLaunchingFileApplication", ThisObject, FileNameAtClient);
		BeginRunningApplication(Notification, FileNameAtClient);
		Close(New Structure("FileNameOrAddress, FileNameAtClient", FileNameOrAddress, FileNameAtClient));
	Else
		Status(NStr("ru = 'Файл получен';
						|en = 'File received';"));
		Close(New Structure("FileNameOrAddress, FileNameAtClient", FileNameOrAddress, FileNameAtClient));
	EndIf;
	
EndProcedure

// After deleting the file upon interruption.
// 
// Parameters:
//  FileNameAtClient - String
&AtClient
Procedure AfterDeletingFileOnInterrupt(FileNameAtClient) Export
	
	Status(NStr("ru = 'Получение прервано';
					|en = 'Receiving interrupted';"));
	
EndProcedure

// After launching the file application.
// 
// Parameters:
//  ReturnCode - Number
//  FileNameAtClient - String
&AtClient
Procedure AfterLaunchingFileApplication(ReturnCode, FileNameAtClient) Export
	
	Status(NStr("ru = 'Файл получен для открытия';
					|en = 'File is received for opening';"));
	
EndProcedure

&AtServerNoContext
Function GetServing(FileNameOrAddress, WindowsFilePath, LinuxFilePath, Val Number, Val Address, Val PortionSize)

	FileNameAtServer = FilesCTL.FullNameOfFileInSession(FileNameOrAddress, WindowsFilePath, LinuxFilePath);

	DataReader = New DataReader(FileNameAtServer);
	DataReader.Skip(Number * PortionSize);
	Buffer = DataReader.ReadIntoBinaryDataBuffer(PortionSize);
	BinaryData = GetBinaryDataFromBinaryDataBuffer(Buffer);
	DataReader.Close();

	Return BinaryData;

EndFunction

// In case of an error.
// 
// Parameters:
//  ErrorInfo - ErrorInfo
//  StandardProcessing - Boolean
//  AdditionalParameters - Structure:
//   * WriteStream - FileStream
&AtClient
Procedure InCaseOfError(ErrorInfo, StandardProcessing, AdditionalParameters) Export

	CancelWrite = True;
	If AdditionalParameters.Property("WriteStream") Then
		AdditionalParameters.WriteStream.BeginClose(New NotifyDescription("AfterClosingStream", ThisObject,
			AdditionalParameters));
	EndIf;
	Close();

EndProcedure

#EndRegion
