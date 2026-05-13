//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DialogTitle = "";
	If Parameters.Property("DialogTitle", DialogTitle) And ValueIsFilled(DialogTitle) Then
		ThisObject.Title = DialogTitle;
		ThisObject.AutoTitle = False;
	EndIf;

	Parameters.Property("FileNameOrAddress", FileNameOrAddress);
	FileProperties = FilesCTL.TemporaryStorageFileProperties(FileNameOrAddress);
	If FileProperties.Registered Then
		WindowsFilePath = FileProperties.WindowsPath;
		LinuxFilePath = FileProperties.LinuxPath;
	Else
		Parameters.Property("WindowsFilePath", WindowsFilePath);
		Parameters.Property("LinuxFilePath", LinuxFilePath);
	EndIf;

	Parameters.Property("FileNameAtClient", FileNameAtClient);
	Parameters.Property("FileSize", FileSize);

	FilePresentation = "";
	Parameters.Property("FilePresentation", FilePresentation);

	Items.TimeConsumingOperationNoteTextDecoration.Title = StrTemplate(NStr("ru = 'Загрузка файла %1';
																					|en = 'Import file %1';"),
		FilePresentation);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("StartFileUpload", 0.1, True);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	If Not ImportCompleted Then
		Cancel = True;
		CancelImport = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure StartFileUpload()
	
	Notification = New NotifyDescription("AfterOpeningStream", ThisObject, , "InCaseOfError", ThisObject);
	FileStreams.BeginOpen(Notification, FileNameAtClient, FileOpenMode.Open, FileAccess.Read);
	
EndProcedure

// After opening the stream.
// 
// Parameters:
//  Stream - FileStream
//  AdditionalParameters - Structure
&AtClient
Procedure AfterOpeningStream(Stream, AdditionalParameters) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Stream", Stream);
	AdditionalParameters.Insert("Buffer", New BinaryDataBuffer(FilesCTLClientServer.ProcessingPortionSize(
		FileSize)));

	ReadNextBatch(AdditionalParameters);

EndProcedure

// Parameters:
// 	AdditionalParameters - Structure:
// * Stream - FileStream
// * Buffer - BinaryDataBuffer
&AtClient
Procedure ReadNextBatch(AdditionalParameters)
	
	If CancelImport Then
		CancelDownload();
		ImportCompleted = True;
		Close();
		Return;
	EndIf;

	Notification = New NotifyDescription("NextPartIsRead", ThisObject, AdditionalParameters, "InCaseOfError",
		ThisObject);
	AdditionalParameters.Stream.BeginRead(Notification, AdditionalParameters.Buffer, 0,
		AdditionalParameters.Buffer.Size);

EndProcedure

// Next data chunk is read.
// 
// Parameters:
//  Count -Number
// 	AdditionalParameters - Structure:
// * Stream - FileStream
// * Buffer - BinaryDataBuffer
&AtClient
Procedure NextPartIsRead(Count, AdditionalParameters) Export
	
	Position = AdditionalParameters.Stream.CurrentPosition();

	Buffer = ?(AdditionalParameters.Buffer.Size = Count, AdditionalParameters.Buffer,
		AdditionalParameters.Buffer.Read(0, Count));
	SendAnotherPortion(GetBinaryDataFromBinaryDataBuffer(Buffer), Position - Count, Position);

	If Position = FileSize Then
		CompleteDownload();
		Return;
	EndIf;

	ReadNextBatch(AdditionalParameters);

EndProcedure

&AtClient
Procedure SendAnotherPortion(BinaryData, Begin, End)
	
	Progress = ?(FileSize > 0, 100 * Begin / FileSize, 100);
	SendNextPortionToServer(FileNameOrAddress, WindowsFilePath, LinuxFilePath, BinaryData, Begin);
	
EndProcedure

&AtServerNoContext
Procedure SendNextPortionToServer(FileNameOrAddress, WindowsFilePath, LinuxFilePath, Val BinaryData,
	Val Begin)

	If Begin = 0 Then
		OpeningMode = FileOpenMode.Create; // FileOpenMode
	Else
		OpeningMode = FileOpenMode.Append;
	EndIf;

	FileNameAtServer = FilesCTL.FullNameOfFileInSession(FileNameOrAddress, WindowsFilePath, LinuxFilePath);
	WriteStream = FileStreams.Open(FileNameAtServer, OpeningMode, FileAccess.Write);
	SizeOfRecordedFragment = WriteStream.Size();
	If SizeOfRecordedFragment <> Begin Then
		Raise StrTemplate(NStr("ru = 'Размер файла %1 не соответствует ожидаемому %2';
										|en = 'Size of file %1 does not match the expected size %2';"),
			SizeOfRecordedFragment, Begin);
	EndIf;

	DataStream = BinaryData.OpenStreamForRead();
	DataStream.CopyTo(WriteStream);
	WriteStream.Close();
	DataStream.Close();
	WriteStream = Undefined;
	DataStream = Undefined;

EndProcedure

&AtClient
Procedure CompleteDownload()
	
	Progress = 100;
	Status(NStr("ru = 'Файл помещен';
					|en = 'File placed';"));
	ImportCompleted = True;
	Close(New Structure("FileNameOrAddress, FileNameAtClient", FileNameOrAddress, FileNameAtClient));
	
EndProcedure

&AtServer
Procedure CancelDownload()
	
	FileProperties = FilesCTL.TemporaryStorageFileProperties(FileNameOrAddress);
	If FileProperties.Registered Then
		FilesCTL.DeleteTemporaryStorageFile(FileNameOrAddress);
	Else
		FileNameAtServer = FilesCTL.FullNameOfFileInSession(FileNameOrAddress, WindowsFilePath, LinuxFilePath);
		// @skip-check module-nstr-camelcase - Check error.
		EventNameLR = NStr("ru = 'Удаление файла.Отмена загрузки';
							|en = 'Delete file.Cancel import';", Common.DefaultLanguageCode());
		FilesCTL.DeleteFilesInAttempt(FileNameAtServer, EventNameLR);
	EndIf;
	
EndProcedure

// In case of an error.
// 
// Parameters:
//  ErrorInfo - ErrorInfo
//  StandardProcessing - Boolean
//  AdditionalParameters - Structure
&AtClient
Procedure InCaseOfError(ErrorInfo, StandardProcessing, AdditionalParameters) Export
	
	CancelDownload();
	ImportCompleted = True;
	Close();
		
EndProcedure

#EndRegion
