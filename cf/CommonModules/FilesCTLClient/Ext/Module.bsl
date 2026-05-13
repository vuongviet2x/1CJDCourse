//@strict-types

#Region Public

// Initializes a structure of parameters for receiving a file from the server on the client.
// To be used in CTLFilesClient.GetFileInteractively.
//
// Returns:
//  Structure - File receipt parameters.:
//    * FileNameOrAddress - String - Address in the temporary storage or a file name on the server (without the path).
//        For the temporary storage, throws an exception if the file size exceeds 4 GB.
//        
//    * WindowsFilePath - String - Path to the file on the Windows server.
//        The value is ignored if the FileNameOrAddress parameter contains an address to the temporary storage or a name of the registered
//        temporary storage file.
//    * LinuxFilePath - String - Path to the file on the Linux server.
//        The value is ignored if the FileNameOrAddress parameter contains an address to the temporary storage or a name of the registered
//        temporary storage file.
//    * NotifyDescriptionOnCompletion - NotifyDescription, Undefined - Contains details of the procedure that
//        is called after a file is received. If Undefined is specified, no handler
//        is started. The procedure to be called must contain the following parameters::
//           Result - Structure, Undefined - On denial to receive the file, or a structure with the following properties:
//             FileNameOrAddress - String - Address in temporary storage or a file name on the server (without a path).
//             FileNameAtClient - String - Full name of a client file received by a client.
//           AdditionalParameters - Arbitrary - the value that was specified when creating
//            the NotifyDescription object.
//    * BlockedForm - ClientApplicationForm, Undefined - Owner of the form that receives a file to be locked.
//        If Undefined, the API is locked during import.
//    * TitleOfSaveDialog - String, Undefined - a title of a selection dialog box and of a form for importing a file.
//        If Undefined is specified, titles are generated automatically.
//    * GetOperationHeader - String, Undefined - Title of the form that displays the long-running operation.
//    * FilterSaveDialog - String, Undefined - a dialog box filter to select a file for saving.
//        If Undefined is specified, you can select any file in the dialog box.
//    * FileNameOfSaveDialog - String - Client filename to suggest to the user in the file save dialog. 
//        
//    * ShowQuestionOpenSave - Boolean - indicates that it is required
//        to ask an additional question when receiving a file and, if the response is positive, to open a file immediately. If False is specified,
//        no question is asked. If an address in a temporary storage is specified in the FileNameOrAddress parameter,
//        the parameter value is ignored and the behavior is regulated by the platform.
Function FileGettingParameters() Export
	
	Result = New Structure();
	Result.Insert("FileNameOrAddress", "");
	Result.Insert("WindowsFilePath", "");
	Result.Insert("LinuxFilePath", "");
	Result.Insert("NotifyDescriptionOnCompletion", Undefined);
	Result.Insert("BlockedForm", Undefined);
	Result.Insert("TitleOfSaveDialog", Undefined);
	Result.Insert("GetOperationHeader", Undefined);
	Result.Insert("FilterSaveDialog", Undefined);
	Result.Insert("FileNameOfSaveDialog", "");
	Result.Insert("ShowQuestionOpenSave", False);
	
	Return Result;
	
EndFunction

// Initializes a structure of parameters to put a file from the client file system to the server.
// To be used in CTLFilesClient.PutFileInteractively.
//
// Returns:
//  Structure - Has the following properties:
//    * FileNameOrAddress - String - Address in the temporary storage or the name of a file on the server (without a path).
//        For the temporary storage, throws an exception if a file exceeds 4 GB and requires 1C:Enterprise Extension to store files over 100 MB.
//        For files on the server, the result is saved to the file, and operations in the web client
//        also require 1C:Enterprise Extension to be installed. 
//        
//    * WindowsFilePath - String - Path to the file on the Windows server.
//        The value is ignored if the FileNameOrAddress parameter contains an address to the temporary storage or a name of the registered
//        temporary storage file.
//    * LinuxFilePath - String - Path to the file on the Windows server.
//        The value is ignored if the FileNameOrAddress parameter contains an address to the temporary storage or a name of the registered
//        temporary storage file.
//    * NotifyDescriptionOnCompletion - NotifyDescription, Undefined - Contains details of the procedure that is called after a file is put.
//        If Undefined, no handler is started.
//        The procedure to be called must contain the following parameters::
//           Result - Structure, Undefined on denial, or a structure with the following properties:
//             FileNameOrAddress - String - Address in the temporary storage or a file name on the server (without a path)
//             FileNameAtClient - String - Full name of a client file that is put to the server
//          AdditionalParameters - Arbitrary - Value that was specified when creating the NotifyDescription object.
//            
//    * BlockedForm - ClientApplicationForm, Undefined - Owner of the form that imports files to be locked.
//        If Undefined, the API is locked during import.
//    * TitleOfSelectionDialog - String, Undefined - Title of the file selection dialog box.
//    * PutOperationHeader - String, Undefined - Title of the form that displays the long-running import operation.
//    * SelectionDialogFilter - String, Undefined - Dialog box filter to select a file. If Undefined is specified, you can
//        select any file in the dialog box.
//    * FileNameOfSelectionDialog - String - Name of the client file to be suggested in the file selection dialog.
//    * MaximumSize - Number, Undefined - Maximum size of a client file available to be put
//      to the server. If Undefined is specified, size of the client file is not controlled.
Function FileLocationParameters() Export
	
	Result = New Structure();
	Result.Insert("FileNameOrAddress", "");
	Result.Insert("WindowsFilePath", "");
	Result.Insert("LinuxFilePath", "");
	Result.Insert("NotifyDescriptionOnCompletion", Undefined);
	Result.Insert("BlockedForm", Undefined);
	Result.Insert("TitleOfSelectionDialog", Undefined);
	Result.Insert("PutOperationHeader", Undefined);
	Result.Insert("SelectionDialogFilter", Undefined);
	Result.Insert("FileNameOfSelectionDialog", "");
	Result.Insert("MaximumSize", Undefined);
	
	Return Result;
	
EndFunction

// Receives a file that is placed to a temporary storage or to the server and saves it to the client
// in the local file system of a user.
//
// Parameters:
//   FileGettingParameters - See FileGettingParameters
Procedure GetFileInteractively(FileGettingParameters) Export
	
	AllParameters = AllFileReceiptParameters();
	FillPropertyValues(AllParameters, FileGettingParameters);
	
	If Not ValueIsFilled(AllParameters.FileNameOrAddress) Then
		ErrorText = NStr("ru = 'Не укано исходное хранение файла на сервере';
							|en = 'Original file storage on the server is not specified';");
		Raise ErrorText;
	EndIf;

	If IsTempStorageURL(AllParameters.FileNameOrAddress) 
		Or StrStartsWith(AllParameters.FileNameOrAddress, "e1cib/data/") Then
		UseBatchTransfer = False;
	Else
		UseBatchTransfer = True;
	EndIf;
	AllParameters.UseBatchTransfer = UseBatchTransfer;

	Notification = New NotifyDescription("AfterConnectingExtensionToGet", ThisObject, AllParameters);
	FileSystemClient.AttachFileOperationsExtension(Notification, , Not UseBatchTransfer);

EndProcedure

// Puts a file selected on the client from the local file system of a user to a temporary storage
// or a file on the server.
//
// Parameters:
//   FileLocationParameters - See FileLocationParameters
Procedure PlaceFileInteractively(FileLocationParameters) Export
	
	AllParameters = AllFileLocationParameters();
	FillPropertyValues(AllParameters, FileLocationParameters);

	If Not ValueIsFilled(AllParameters.FileNameOrAddress) Then
		ErrorText = NStr("ru = 'Не указано целевое хранение файла на сервере';
							|en = 'Targeted file storage on the server is not specified';");
		Raise ErrorText;
	EndIf;

	If IsTempStorageURL(AllParameters.FileNameOrAddress) Then
		UseBatchTransfer = False;
		MaximumSize = FilesCTLClientServer.MaximumSizeOfTemporaryStorage();
		If AllParameters.MaximumSize = Undefined Then
			AllParameters.MaximumSize = MaximumSize;
		Else
			AllParameters.MaximumSize = Min(FileLocationParameters.MaximumSize, MaximumSize);
		EndIf;
	Else
		UseBatchTransfer = True;
	EndIf;

	AllParameters.UseBatchTransfer = UseBatchTransfer;

	SuggestionText = StrTemplate(NStr("ru = 'Для загрузки файлов, размером более %1, требуется установить расширение для работы с 1С:Предприятием.
									  |С этим расширением работа в веб-клиенте станет удобней не только при работе с большими файлами.';
										|en = 'To import files with the size more than %1, install 1C:Enterprise Extension.
										|This extension improves file management in web client.';"),
		FilesCTLClientServer.FileSizePresentation(FilesCTLClientServer.AcceptableSizeOfTemporaryStorage()));

	Notification = New NotifyDescription("AfterConnectingExtensionForRoom", ThisObject, AllParameters);
	FileSystemClient.AttachFileOperationsExtension(Notification, SuggestionText,
		Not UseBatchTransfer);

EndProcedure

#EndRegion

#Region Private

// After attaching 1C:Enterprise Extension to receive files.
// 
// Parameters:
//  Attached - Boolean
//  AdditionalParameters See AllFileReceiptParameters
Procedure AfterConnectingExtensionToGet(Attached, AdditionalParameters) Export
	
	AdditionalParameters.ExtensionAttached = Attached;

	If Not AdditionalParameters.UseBatchTransfer Then

		If Attached Then

			Notification = New NotifyDescription("AfterGettingFileFromRepository", ThisObject, AdditionalParameters);
			FilesToObtain = New Array; // Array of TransferableFileDescription 
			FilesToObtain.Add(New TransferableFileDescription(AdditionalParameters.FileNameOfSaveDialog,
				AdditionalParameters.FileNameOrAddress));
			Dialog = New FileDialog(FileDialogMode.Save);
			Dialog.Title = AdditionalParameters.TitleOfSaveDialog;
			Dialog.FullFileName = AdditionalParameters.FileNameOfSaveDialog;
			Dialog.Filter = AdditionalParameters.FilterSaveDialog;
			BeginGettingFiles(Notification, FilesToObtain, Dialog, True);

		Else

			GetFile(AdditionalParameters.FileNameOrAddress, AdditionalParameters.FileNameOfSaveDialog,
				True);

			FileDetails = New Structure;
			FileDetails.Insert("FileNameOrAddress", AdditionalParameters.FileNameOrAddress);
			FileDetails.Insert("FileNameAtClient", Undefined);
			ExecuteNotifyProcessing(AdditionalParameters.NotifyDescriptionOnCompletion, FileDetails);

		EndIf;

		Return;

	EndIf;

	If Not Attached Then
		ExecuteNotifyProcessing(AdditionalParameters.NotifyDescriptionOnCompletion, Undefined);
		Return;
	EndIf;

	If AdditionalParameters.ShowQuestionOpenSave Then
		ReceivingParameters = New Structure;
		ReceivingParameters.Insert("FileNameOrAddress", AdditionalParameters.FileNameOrAddress);
		ReceivingParameters.Insert("WindowsFilePath", AdditionalParameters.WindowsFilePath);
		ReceivingParameters.Insert("LinuxFilePath", AdditionalParameters.LinuxFilePath);
		If ValueIsFilled(AdditionalParameters.GetOperationHeader) Then
			ReceivingParameters.Insert("DialogTitle", AdditionalParameters.GetOperationHeader);
		Else
			ReceivingParameters.Insert("DialogTitle", AdditionalParameters.TitleOfSaveDialog);
		EndIf;
		ReceivingParameters.Insert("FilterSaveDialog", AdditionalParameters.FilterSaveDialog);
		ReceivingParameters.Insert("FileNameOfSaveDialog", AdditionalParameters.FileNameOfSaveDialog);
		OpenForm("DataProcessor.FilesCTL.Form.GetFile", ReceivingParameters,
			AdditionalParameters.BlockedForm, , , , AdditionalParameters.NotifyDescriptionOnCompletion);
		Return;
	EndIf;

	Dialog = New FileDialog(FileDialogMode.Save);
	Dialog.Title = AdditionalParameters.TitleOfSaveDialog;
	Dialog.FullFileName = AdditionalParameters.FileNameOfSaveDialog;
	Dialog.Filter = AdditionalParameters.FilterSaveDialog;
	Dialog.Show(New NotifyDescription("AfterSelectingFileNameToGet", ThisObject, AdditionalParameters));

EndProcedure

// After selecting the name of the file to receive.
// 
// Parameters:
//  SelectedFiles - Array of String, Undefined - Selected names or Undefined if nothing is selected.
//  AdditionalParameters See AllFileReceiptParameters
Procedure AfterSelectingFileNameToGet(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		ExecuteNotifyProcessing(AdditionalParameters.NotifyDescriptionOnCompletion, Undefined);
		Return;
	EndIf;

	ReceivingParameters = New Structure;
	ReceivingParameters.Insert("FileNameOrAddress", AdditionalParameters.FileNameOrAddress);
	ReceivingParameters.Insert("WindowsFilePath", AdditionalParameters.WindowsFilePath);
	ReceivingParameters.Insert("LinuxFilePath", AdditionalParameters.LinuxFilePath);
	If ValueIsFilled(AdditionalParameters.GetOperationHeader) Then
		ReceivingParameters.Insert("DialogTitle", AdditionalParameters.GetOperationHeader);
	Else
		ReceivingParameters.Insert("DialogTitle", AdditionalParameters.TitleOfSaveDialog);
	EndIf;
	ReceivingParameters.Insert("FileNameAtClient", SelectedFiles[0]);
	OpenForm("DataProcessor.FilesCTL.Form.GetFile", ReceivingParameters,
		AdditionalParameters.BlockedForm, , , , AdditionalParameters.NotifyDescriptionOnCompletion);

EndProcedure

// After getting the file from the storage.
// 
// Parameters:
//  ObtainedFiles - Array of TransferredFileDescription, Undefined
//  AdditionalParameters See AllFileReceiptParameters
Procedure AfterGettingFileFromRepository(ObtainedFiles, AdditionalParameters) Export

	If ValueIsFilled(ObtainedFiles) Then
		FileDetails = New Structure();
		FileDetails.Insert("FileNameOrAddress", AdditionalParameters.FileNameOrAddress);
		FileDetails.Insert("FileNameAtClient", ObtainedFiles[0].FullName);
	Else
		FileDetails = Undefined;
	EndIf;
	
	ExecuteNotifyProcessing(AdditionalParameters.NotifyDescriptionOnCompletion, FileDetails);

EndProcedure

// After attaching 1C:Enterprise Extension to place files.
// 
// Parameters:
//  Attached - Boolean
//  AdditionalParameters See AllFileLocationParameters
Procedure AfterConnectingExtensionForRoom(Attached, AdditionalParameters) Export
	
	AdditionalParameters.ExtensionAttached = Attached;

	If AdditionalParameters.BlockedForm = Undefined Then
		FormID = New UUID;
	Else
		FormID = AdditionalParameters.BlockedForm.UUID;
	EndIf;
	AdditionalParameters.Insert("FormIdentifier", FormID);

	Dialog = New FileDialog(FileDialogMode.Open);
	Dialog.Title = AdditionalParameters.TitleOfSelectionDialog;
	Dialog.Filter = AdditionalParameters.SelectionDialogFilter;
	Dialog.FullFileName = AdditionalParameters.FileNameOfSelectionDialog;
	Dialog.CheckFileExist = True;
	AdditionalParameters.Insert("FileDialog", Dialog);

	If AdditionalParameters.UseBatchTransfer = Undefined
		Or Not AdditionalParameters.UseBatchTransfer Then

		NotificationAfter = New NotifyDescription("AfterPlacingFileInStorage", ThisObject, AdditionalParameters);
		NotificationBefore = New NotifyDescription("BeforePuttingFileInStorage", ThisObject,
			AdditionalParameters);
		BeginPutFile(NotificationAfter, Undefined, Dialog, True, AdditionalParameters.FormIdentifier,
			NotificationBefore);

		Return;

	EndIf;

	If Not Attached Then
		ExecuteNotifyProcessing(AdditionalParameters.NotifyDescriptionOnCompletion, Undefined);
		Return;
	EndIf;

	Dialog.Show(New NotifyDescription("AfterSelectingFileNameInDialog", ThisObject, AdditionalParameters));

EndProcedure

// After placing the file in the storage.
// 
// Parameters:
//  SelectionDone - Boolean - False if the user refused to perform the operation in the file selection dialog box.
//  Address - String - Location of the new file.
//  SelectedFileName - String
//  ImportParameters See AllFileLocationParameters
Procedure AfterPlacingFileInStorage(SelectionDone, Address, SelectedFileName, ImportParameters) Export
	
	If SelectionDone Then
		FileDetails = New Structure();
		FileDetails.Insert("FileNameOrAddress", Address);
		FileDetails.Insert("FileNameAtClient", SelectedFileName);
	Else
		FileDetails = Undefined;
	EndIf;
	
	TimeConsumingOperation = ImportParameters.TimeConsumingOperation; // See DataProcessor.FilesCTL.Form.TimeConsumingOperation
	If TimeConsumingOperation <> Undefined Then
		If TimeConsumingOperation.OperationAborted Then
			DeleteFromTempStorage(Address);
			FileDetails = Undefined;
		EndIf;
		If TimeConsumingOperation.IsOpen() Then
			TimeConsumingOperation.AbortAllowed = True;
			TimeConsumingOperation.Close();
		EndIf;
		TimeConsumingOperation = Undefined;
	EndIf;
	
	ExecuteNotifyProcessing(ImportParameters.NotifyDescriptionOnCompletion, FileDetails);
	
EndProcedure

// Before placing the file in the storage.
// 
// Parameters:
//  FileRef - FileRef - Link to a file ready to be placed in the temporary storage.
//  Cancel - Boolean - Indicates that file putting was canceled.
//  ImportParameters See AllFileLocationParameters
Procedure BeforePuttingFileInStorage(FileRef, Cancel, ImportParameters) Export
	
	FileProperties = NewFileProperties(FileRef.Name, FileRef.Extension, FileRef.Size());

	CheckingFileBeforePlacing(FileProperties, Cancel, ImportParameters);

	If Cancel Then
		Return;
	EndIf;

	OperationProperties = New Structure;
	OperationProperties.Insert("DialogTitle", ImportParameters.PutOperationHeader);
	OperationProperties.Insert("AbortAllowed", True);
	ImportParameters.TimeConsumingOperation = OpenForm("DataProcessor.FilesCTL.Form.TimeConsumingOperation",
		OperationProperties, ImportParameters.BlockedForm);

EndProcedure

// After selecting the file name in the dialog box.
// 
// Parameters:
//  SelectedFiles - Array of String
//  AdditionalParameters See AllFileLocationParameters
Procedure AfterSelectingFileNameInDialog(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		ExecuteNotifyProcessing(AdditionalParameters.NotifyDescriptionOnCompletion, Undefined);
		Return;
	EndIf;
	
	FileNameAtClient = SelectedFiles[0];
	AdditionalParameters.FileNameAtClient = FileNameAtClient;
	
	Notification = New NotifyDescription("AfterCheckingExistence", ThisObject, AdditionalParameters);
	FSObject = New File(FileNameAtClient);
	FSObject.BeginCheckingExistence(Notification);
	
EndProcedure

// After checking whether the file exists.
// 
// Parameters:
//  Exists - Boolean
//  AdditionalParameters See AllFileLocationParameters
Procedure AfterCheckingExistence(Exists, AdditionalParameters) Export
	
	If Not Exists Then
		ExecuteNotifyProcessing(AdditionalParameters.NotifyDescriptionOnCompletion, Undefined);
		Return;
	EndIf;
		
	Notification = New NotifyDescription("AfterCheckIsFile", ThisObject, AdditionalParameters);
	FSObject = New File(AdditionalParameters.FileNameAtClient);
	FSObject.BeginCheckingIsFile(Notification);

EndProcedure

// After checking whether it is a file.
// 
// Parameters:
//  IsFile - Boolean
//  AdditionalParameters See AllFileLocationParameters
Procedure AfterCheckIsFile(IsFile, AdditionalParameters) Export

	If Not IsFile Then
		ExecuteNotifyProcessing(AdditionalParameters.NotifyDescriptionOnCompletion, Undefined);
		Return;
	EndIf;

	Notification = New NotifyDescription("AfterGettingSize", ThisObject, AdditionalParameters);
	FSObject = New File(AdditionalParameters.FileNameAtClient);
	FSObject.BeginGettingSize(Notification);
	
EndProcedure

// After getting the size.
// 
// Parameters:
//  Size - Number
//  AdditionalParameters See AllFileLocationParameters
Procedure AfterGettingSize(Size, AdditionalParameters) Export
	
	AdditionalParameters.Insert("FileSize", Size);

	FSObject = New File(AdditionalParameters.FileNameAtClient);

	FileProperties = NewFileProperties(FSObject.Name, FSObject.Extension, Size);

	Cancel = False;
	CheckingFileBeforePlacing(FileProperties, Cancel, AdditionalParameters);

	If Cancel Then
		ExecuteNotifyProcessing(AdditionalParameters.NotifyDescriptionOnCompletion, Undefined);
		Return;
	EndIf;

	ReceivingParameters = New Structure;
	ReceivingParameters.Insert("FileNameOrAddress", AdditionalParameters.FileNameOrAddress);
	ReceivingParameters.Insert("WindowsFilePath", AdditionalParameters.WindowsFilePath);
	ReceivingParameters.Insert("LinuxFilePath", AdditionalParameters.LinuxFilePath);
	ReceivingParameters.Insert("DialogTitle", AdditionalParameters.PutOperationHeader);
	ReceivingParameters.Insert("FileNameAtClient", AdditionalParameters.FileNameAtClient);
	ReceivingParameters.Insert("FilePresentation", FilesCTLClientServer.FilePresentation(
		AdditionalParameters.FileNameAtClient, Size));
	ReceivingParameters.Insert("FileSize", Size);
	OpenForm("DataProcessor.FilesCTL.Form.PuttingFile", ReceivingParameters,
		AdditionalParameters.BlockedForm, , , , AdditionalParameters.NotifyDescriptionOnCompletion);

EndProcedure

// New file properties.
// 
// Parameters:
//  Name - String
//  Extension - String
//  Size - Number
// 
// Returns:
//  Structure:
// * Name - String
// * Extension - String
// * Size - Number
Function NewFileProperties(Name, Extension, Size)
	
	FileProperties = New Structure;
	FileProperties.Insert("Name", Name);
	FileProperties.Insert("Extension", Extension);
	FileProperties.Insert("Size", Size);
	
	Return FileProperties;
	
EndFunction

// Check the file before placement.
// 
// Parameters:
//  FileRef - See NewFileProperties
//  Cancel - Boolean
//  CheckParameters See AllFileLocationParameters
Procedure CheckingFileBeforePlacing(FileRef, Cancel, CheckParameters)
	
	If FileRef = Undefined Then
		HandleValidationError(Cancel, NStr("ru = 'Не указана ссылка на файл';
											|en = 'Reference to the file is not specified';"));
		Return;
	EndIf;

	FilterProperties = DialogFilterProperties(CheckParameters.SelectionDialogFilter);
	If FilterProperties <> Undefined And FilterProperties.Extensions.Find(Lower(FileRef.Extension)) = Undefined
		And FilterProperties.Extensions.Find("*") = Undefined Then
		HandleValidationError(Cancel, StrTemplate(NStr("ru = 'Выбран неверный тип файла. Выберите:
													   |%1';
														|en = 'Incorrect file type is selected. Select:
														|%1';"), StrConcat(FilterProperties.Presentations, Chars.LF)));
		Return;
	EndIf;

	If Not CheckParameters.ExtensionAttached Then
		MaxSizeWithoutExtension = FilesCTLClientServer.AcceptableSizeOfTemporaryStorage();
		If FileRef.Size > MaxSizeWithoutExtension Then
			HandleValidationError(Cancel, StrTemplate(NStr("ru = 'Выбран файл %1 больше %2
				|Для работы в веб клиенте с такими файлами требуется установка расширения 1С:Предприятия.
				|Воспользуйтесь тонким клиентом, либо установите расширение';
				|en = 'File %1 with size more than %2 is selected
				|To use such files in web client, install 1C:Enterprise Extension.
				|Use thin client or install the extension';"),
				FileRef.Name, FilesCTLClientServer.FileSizePresentation(MaxSizeWithoutExtension)));
		EndIf;
	EndIf;

	MaximumSize = CheckParameters.MaximumSize;
	If MaximumSize = Undefined Then
		Return;
	EndIf;

	If FileRef.Size > MaximumSize Then
		If MaximumSize <= 0 Then
			ErrorText = StrTemplate(NStr("ru = 'Размер файла должен быть равен %1';
										|en = 'File size must be %1';"),
				FilesCTLClientServer.FileSizePresentation(0));
		Else
			ErrorText = StrTemplate(NStr("ru = 'Файл %1 слишком большой. Выберите файл менее %2';
										|en = 'File %1 is too large. Select a file with size less than %2';"), FileRef.Name,
				FilesCTLClientServer.FileSizePresentation(MaximumSize));
		EndIf;
		HandleValidationError(Cancel, ErrorText);
		Return;
	EndIf;

EndProcedure

Procedure HandleValidationError(Cancel, WarningText)
	
	Cancel = True;
	ShowMessageBox(Undefined, WarningText);
	
EndProcedure

Function DialogFilterProperties(DIalogBoxFilter)
	
	If Not ValueIsFilled(DIalogBoxFilter) Then
		Return Undefined;
	EndIf;

	Presentations = New Array; // Array of String
	Masks = New Array; // Array of String
	Extensions = New Array; // Array of String
	Result = New Structure("Presentations, Masks, Extensions", Presentations, Masks, Extensions);

	FilterElements = StrSplit(DIalogBoxFilter, "|");
	While FilterElements.UBound() > 0 Do

		Presentation = FilterElements[0];
		Mask = FilterElements[1];

		Result.Presentations.Add(Presentation);
		Result.Masks.Add(Mask);

		MaskElements = StrSplit(Mask, ";");
		For Each MaskElement In MaskElements Do
			If MaskElement = "*.*" Or MaskElement = "*" Then
				Result.Extensions.Add("*");
				Break;
			Else
				Pos = StrFind(MaskElement, ".", SearchDirection.FromEnd);
				If Pos > 0 Then
					Result.Extensions.Add(Lower(Mid(MaskElement, Pos)));
				Else
					Result.Extensions.Add("");
				EndIf;
			EndIf;
		EndDo;

		FilterElements.Delete(0);
		FilterElements.Delete(0);

	EndDo;

	Return Result;

EndFunction

// All file receipt parameters.
//
// Returns:
//  Structure:
//    * FileNameOrAddress - String
//    * WindowsFilePath - String
//    * LinuxFilePath - String
//    * NotifyDescriptionOnCompletion - NotifyDescription, Undefined -
//    * BlockedForm - ClientApplicationForm, Undefined -
//    * TitleOfSaveDialog - String
//    * GetOperationHeader - String
//    * FilterSaveDialog - String
//    * FileNameOfSaveDialog - String
//    * ShowQuestionOpenSave - Boolean
//    * UseBatchTransfer - Boolean 
//    * ExtensionAttached - Boolean
Function AllFileReceiptParameters()
	
	Result = New Structure();
	Result.Insert("FileNameOrAddress", "");
	Result.Insert("WindowsFilePath", "");
	Result.Insert("LinuxFilePath", "");
	Result.Insert("NotifyDescriptionOnCompletion", Undefined);
	Result.Insert("BlockedForm", Undefined);
	Result.Insert("TitleOfSaveDialog", "");
	Result.Insert("GetOperationHeader", "");
	Result.Insert("FilterSaveDialog", "");
	Result.Insert("FileNameOfSaveDialog", "");
	Result.Insert("ShowQuestionOpenSave", False);
	Result.Insert("UseBatchTransfer", False);
	Result.Insert("ExtensionAttached", False);
	
	Return Result;
	
EndFunction

// All file storage parameters.
// 
// Returns:
//  Structure:
// * FileNameOrAddress - String
// * WindowsFilePath - String
// * LinuxFilePath - String
// * NotifyDescriptionOnCompletion - NotifyDescription, Undefined -
// * BlockedForm - ClientApplicationForm, Undefined -
// * TitleOfSelectionDialog - String
// * PutOperationHeader - String
// * SelectionDialogFilter - String
// * FileNameOfSelectionDialog - String
// * MaximumSize - Number, Undefined -
// * UseBatchTransfer - Boolean
// * ExtensionAttached - Boolean
// * TimeConsumingOperation - ClientApplicationForm, Undefined -
// * FileNameAtClient - String
Function AllFileLocationParameters()
	
	Result = New Structure();
	Result.Insert("FileNameOrAddress", "");
	Result.Insert("WindowsFilePath", "");
	Result.Insert("LinuxFilePath", "");
	Result.Insert("NotifyDescriptionOnCompletion", Undefined);
	Result.Insert("BlockedForm", Undefined);
	Result.Insert("TitleOfSelectionDialog", "");
	Result.Insert("PutOperationHeader", "");
	Result.Insert("SelectionDialogFilter", "");
	Result.Insert("FileNameOfSelectionDialog", "");
	Result.Insert("MaximumSize", Undefined);
	Result.Insert("UseBatchTransfer", False);
	Result.Insert("ExtensionAttached", False);
	Result.Insert("TimeConsumingOperation", Undefined);
	Result.Insert("FileNameAtClient", "");
	
	Return Result;
	
EndFunction

#EndRegion