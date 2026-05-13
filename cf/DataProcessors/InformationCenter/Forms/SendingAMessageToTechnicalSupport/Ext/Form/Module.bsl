#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Parameters.UserCode) Then
		UserCode = Parameters.UserCode;
	Else
		UserCode = InformationCenterServer.UserCodeForAccess();
	EndIf;
	
	DataArea = SaaSOperations.SessionSeparatorValue();
	
	CreateSupportRequest = Parameters.CreateSupportRequest;
	SupportRequestID = Parameters.SupportRequestID;
	
	MaximumFileSize = 
		InformationCenterServer.MaximumSizeOfAttachmentsForSendingMessagesToSupport();
	
	MessageText = "";
	
	If ValueIsFilled(Parameters.Subject) Then
		Subject = Parameters.Subject;
	EndIf;
	
	If ValueIsFilled(Parameters.Content) Then
		MessageText = EscapeCharacters(Parameters.Content);
	EndIf;
		
	If ValueIsFilled(Parameters.Attachments) Then
		For Each Attachment In Parameters.Attachments Do
			File = New File(Attachment.FileName);
			PlaceFilesWithoutExtensionOnServer(Attachment.Data, New Structure("Name, Extension", File.BaseName, File.Extension));
		EndDo;
	EndIf;
	
	FillInContent(MessageText);
	
	ResponseAddress = InformationCenterServer.DetermineUserSEmailAddress();
	If IsBlankString(ResponseAddress) Then 
		Items.ReplyToAddress.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetCursorInTextTemplate();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// Parameters:
// 	Item - FormDecoration - Form item.
//
&AtClient
Procedure Attachable_DeleteFile(Item)
	
	ButtonName = Item.Name;
	DeleteFileServer(ButtonName);
	
EndProcedure

&AtClient
Procedure Attachable_DownloadFile(Item, RowIndex, StandardProcessing)
	
	StandardProcessing = False;
	RowIndex = Number(RowIndex);
		
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Dialog.Title = NStr("ru = 'Выберите файл для сохранения';
												|en = 'Select file to download';");
	SavingParameters.Dialog.Filter    = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Файлы (*%1)|*%1|Все файлы (%2)|%2';
			|en = 'Files (*%1)|*%1|All files (%2)|%2';"), SelectedFiles_SSLyf[RowIndex].Extension, GetAllFilesMask());
		
	FileSystemClient.SaveFile(
		New NotifyDescription("AfterFileSaved", ThisObject),
		SelectedFiles_SSLyf.Get(RowIndex).StorageAddress,
		SelectedFiles_SSLyf[RowIndex].FileName + SelectedFiles_SSLyf[RowIndex].Extension, 
		SavingParameters);
			
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Send(Command)
	
	If Items.ReplyToAddress.Visible Then
		 
		If IsBlankString(ResponseAddress) Then 
			Raise NStr("ru = 'Необходимо ввести адрес электронной почты для ответа';
									|en = 'Enter email address for the response';");
		EndIf;
		
		Result = ParseStringWithEmailAddresses(ResponseAddress);
		
		If Result.Count() = 0 Then
			 
			Notification = New NotifyDescription("SendingMessageToSupport", ThisObject);
			QueryText = NStr("ru = 'Адрес электронной почты возможно введен неверно. Отправить сообщение?';
								|en = 'Email address might be incorrect. Send the message?';");
			ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
			
			Return;
			
		EndIf;
		
	EndIf;
	
	SendMessageServer();
	ShowUserNotification(NStr("ru = 'Сообщение в службу поддержки отправлено.';
										|en = 'Message to the technical support is sent.';"));
	Notify("SendingAMessageToTechnicalSupport");
	Close(True);
	
EndProcedure

&AtClient
Procedure AttachFile_SSLyf(Command)
	
#If WebClient Then
	NotifyDescription = New NotifyDescription("AttachAlertFile", ThisObject);
	BeginAttachingFileSystemExtension(NotifyDescription);
#Else
	AddExternalFiles(True);
#EndIf
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterFileSaved(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		FileSystemClient.OpenExplorer(Result[0].FullName);
	EndIf;
	
EndProcedure

&AtServer
Function EscapeCharacters(Val Text)
	
	Result = StrReplace(Text,     "&",  "&amp;");
	Result = StrReplace(Result, "'",  "&apos;");
	Result = StrReplace(Result, "<",  "&lt;");
	Result = StrReplace(Result, ">",  "&gt;");
	Result = StrReplace(Result, """", "&quot;");
	Return Result;
	
EndFunction

&AtServer
Procedure DeleteFileServer(DeleteButtonName)
	
	Filter = New Structure("DeleteButtonName", DeleteButtonName);
	FoundRows = SelectedFiles_SSLyf.FindRows(Filter);
	If FoundRows.Count() = 0 Then 
		Return;
	EndIf;
	
	FoundRow = FoundRows.Get(0);
	NameIndex = GetIndexOfFormElement(DeleteButtonName);
	RemoveAllSubordinateElements(NameIndex);
	DeleteFromTempStorage(FoundRow.StorageAddress);
	
	IndexOf = SelectedFiles_SSLyf.IndexOf(FoundRow);
	SelectedFiles_SSLyf.Delete(IndexOf);
	
EndProcedure

&AtClient
Procedure SendingMessageToSupport(Result) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	SendMessageServer();
	ShowUserNotification(NStr("ru = 'Сообщение в службу поддержки отправлено.';
										|en = 'Message to the technical support is sent.';"));
	Notify("SendingAMessageToTechnicalSupport");
	Close(True);
	
EndProcedure

&AtServer
Procedure FillInContent(MessageText)
	
	Text = InformationCenterServer.TextTemplateInTech(MessageText);
	LineCursorPosition = "CursorPosition";
	CursorPosition = StrFind(Text, LineCursorPosition)- 9;
	Text = StrReplace(Text, LineCursorPosition, "");
	Content.SetHTML(Text, New Structure);
	
EndProcedure

&AtServer
Procedure RemoveAllSubordinateElements(ElementIndex)
	
	FoundItem_ = Items.Find("FileGroup_" + String(ElementIndex));
	If FoundItem_ <> Undefined Then 
		Items.Delete(FoundItem_);
	EndIf;
	
	FoundItem_ = Items.Find("FileNameText" + String(ElementIndex));
	If FoundItem_ <> Undefined Then 
		Items.Delete(FoundItem_);
	EndIf;
	
	FoundItem_ = Items.Find("DeleteFileButton" + String(ElementIndex));
	If FoundItem_ <> Undefined Then 
		Items.Delete(FoundItem_);
	EndIf;
	
EndProcedure

&AtServer
Function GetIndexOfFormElement(TagName)
	
	StartOfPosition = StrLen("DeleteFileButton") + 1;
	Return Number(Mid(TagName, StartOfPosition));
	
EndFunction

&AtClient
Procedure AttachAlertFile(Attached, Context) Export
	
	AddExternalFiles(Attached);
	
EndProcedure

&AtClient
Procedure AddExternalFiles(ExtensionAttached)
	
	If ExtensionAttached Then 
		PlaceFilesWithExtension();
	Else
		PlaceFilesWithoutExtension();
	EndIf;
	
EndProcedure

&AtClient
Procedure PlaceFilesWithExtension()
	
	// Calling a file choice dialog.
	Dialog = New FileDialog(FileDialogMode.Open);
	Dialog.Title = NStr("ru = 'Выберите файл';
							|en = 'Select file';");
	Dialog.Multiselect = False;
	
	NotifyDescription = New NotifyDescription("PlaceFileWithAlertExtension", ThisObject);
	InformationCenterClient.PlacingFiles(NotifyDescription,, Dialog, True, UUID);
	
EndProcedure

&AtClient
Procedure PlaceFileWithAlertExtension(SelectedFiles, CompletionHandler) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	SelectedFile = SelectedFiles.Get(0); // TransferredFileDescription
	FullName = SelectedFile.FullName;
	FullFileName = ?(IsBlankString(FullName), SelectedFile.Name, FullName);
	StorageAddress = SelectedFile.Location;
	
	// Checking if the total file size is correct.
	File = New File;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FullFileName", FullFileName);
	AdditionalParameters.Insert("StorageAddress", StorageAddress);
	
	NotifyDescription = New NotifyDescription("StartInitializationAlert", ThisObject, AdditionalParameters);
	//@skip-warning ObsoleteMethod - Implementation feature.
	File.BeginInitialization(NotifyDescription, FullFileName);
	
	
EndProcedure

// Parameters:
// 	File - File - File. 
// 	AdditionalParameters - Structure - Additional parameters.
//
&AtClient
Procedure StartInitializationAlert(File, AdditionalParameters) Export
	
	NotifyDescription = New NotifyDescription(
		"PlaceFileWithExtensionAlertSizeAlert", ThisObject, AdditionalParameters);
	File.BeginGettingSize(NotifyDescription);
	
EndProcedure

&AtClient
Procedure PlaceFileWithExtensionAlertSizeAlert(Size, AdditionalParameters) Export
	
	If Size = 0 Then
		
		Return;
		
	EndIf;
	
	If Not TotalFileSizeIsOptimal(Size) Then 
		
		WarningText = NStr("ru = 'Не удалось добавить файл. Размер выбранных файлов превышает предел в %1 Мб';
									|en = 'Cannot add a file. Size of the selected files exceeds the limit of %1 MB';");
		WarningText = StrTemplate(WarningText, MaximumFileSize);
		ClearMessages();
		ShowMessageToUser(WarningText);
		
	EndIf;
	
	Status(NStr("ru = 'Файл добавляется к сообщению.';
					|en = 'The file is being attached to the message.';"));

	// Add files into the table.
	FileNameAndExtension = GetFileNameAndExtension(AdditionalParameters.FullFileName);
	PlaceFilesWithoutExtensionOnServer(AdditionalParameters.StorageAddress, FileNameAndExtension);
	
	Status();
	
	CreateFormElementsForAttachedFile();
	
EndProcedure

&AtClient
Procedure PlaceFilesWithoutExtension()
	
	AfterPutFile = New NotifyDescription("AfterPutFiles", ThisObject);
	
	InformationCenterClient.PuttingFile(AfterPutFile,,, True, UUID);
	
EndProcedure

&AtClient
Procedure AfterPutFiles(Result, StorageAddress, SelectedFileName, AdditionalParameters) Export
	
	If Result Then
		
		FileNameAndExtension = GetFileNameAndExtension(SelectedFileName);
		PlaceFilesWithoutExtensionOnServer(StorageAddress, FileNameAndExtension);
		
	EndIf;
	
EndProcedure

&AtServer
Function GetFileNameAndExtension(Val SelectedFileName)
	
	Result = CommonClientServer.ParseFullFileName(SelectedFileName);
	
	FileNameAndExtension = New Structure;
	FileNameAndExtension.Insert("Name", Result.BaseName);
	FileNameAndExtension.Insert("Extension", Result.Extension);
	
	Return FileNameAndExtension;
	
EndFunction

&AtServer
Procedure PlaceFilesWithoutExtensionOnServer(StorageAddress, FileNameAndExtension)
	
	NewFile = GetFromTempStorage(StorageAddress);
	
	// Checking if the total file size is correct.
	FileSize = NewFile.Size();
	
	If Not TotalFileSizeIsOptimal(FileSize) Then
		 
		WarningText = NStr("ru = 'Размер выбранных файлов превышает предел в %1 Мб';
									|en = 'Size of the selected files exceeds the limit of %1 MB';");
		WarningText = StrTemplate(WarningText, MaximumFileSize);
		ShowMessageToUser(WarningText);
		DeleteFromTempStorage(StorageAddress);
		
		Return;
		
	EndIf;
	
	TableRow = SelectedFiles_SSLyf.Add();
	TableRow.FileName = FileNameAndExtension.Name;
	TableRow.Extension = FileNameAndExtension.Extension;
	TableRow.Size = FileSize;
	TableRow.StorageAddress = StorageAddress;
	
	CreateFormElementsForAttachedFile();
	
EndProcedure

&AtServer
Function TotalFileSizeIsOptimal(FileSize)
	
	Size = FileSize / 1024;
	
	// Counting the total size of marked files attached to the email.
	For Iteration = 0 To SelectedFiles_SSLyf.Count() - 1 Do
		Size = Size + (SelectedFiles_SSLyf.Get(Iteration).Size / 1024);
	EndDo;
	
	SizeInMegabytes = Size / 1024;
	
	If SizeInMegabytes > MaximumFileSize Then 
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

&AtServer
Procedure SendMessageServer()
	
	HTMLText = "";
	HTMLAttachments = New Structure;
	Content.GetHTML(HTMLText, HTMLAttachments);
    Base64Attachments = ConvertPicturesToBase64(HTMLAttachments);
    DataProcessors.InformationCenter.AddAppInformation(HTMLText, Base64Attachments);
        
	MessageText = Content.GetText();
    If IsBlankString(MessageText) Then 
		Raise NStr("ru = 'Текст сообщения не может быть пустым.';
								|en = 'Message text cannot be blank.';");
	EndIf;
	
	If IsBlankString(Subject) Then 
		MessageSubject1 = DefineTheme();
	Else
		MessageSubject1 = Subject;
	EndIf;
	
	Try
		
		WSProxy = InformationCenterServer.GetSupportProxy();
		
		ListOfXDTOFiles = GenerateListOfXDTOFiles(WSProxy.XDTOFactory);
		
		WSProxy.addComments(UserCode, String(SupportRequestID), MessageSubject1, 
			HTMLText, CreateSupportRequest,  ListOfXDTOFiles, DataArea, ResponseAddress);
		
	Except
		
		ErrorText = InformationCenterInternal.DetailedErrorText(ErrorInfo());
		WriteLogEvent(InformationCenterServer.GetEventNameForLog(), 
		                         EventLogLevel.Error,,, ErrorText);
		OutputText_ = InformationCenterServer.TextOfErrorInformationOutputInSupportService();
		
		Raise OutputText_;
		
	EndTry;
	
EndProcedure

&AtServer 
Function ConvertPicturesToBase64(Attachments)
	
	Base64Attachments = New Structure;
	For Each KiZ In Attachments Do
		Base64Attachments.Insert(KiZ.Key,Base64String(KiZ.Value.GetBinaryData()));
	EndDo;
	
	Return Base64Attachments;
	
EndFunction

&AtServer
Function DefineTheme()
	
	If Not IsBlankString(Subject) Then 
		Return Subject;
	EndIf;
	
	MessageText = Content.GetText();
	MessageText = StrReplace(MessageText, "Hello.", "");
	MessageText = Left(MessageText, 500);
	MessageText = StrReplace(MessageText, Chars.LF, " ");
	MessageText = StrReplace(MessageText, "  ", " ");
	
	Return TrimAll(MessageText);
	
EndFunction

&AtServer
Function GenerateListOfXDTOFiles(Factory)
	
	FileListType = Factory.Type("http://www.1c.ru/1cFresh/InformationCenter/SupportServiceData/1.0.0.1", "ListFile");
	ListOfFiles = Factory.Create(FileListType);
	
	For Each CurrentFile In SelectedFiles_SSLyf Do 
		
		FileType = Factory.Type("http://www.1c.ru/1cFresh/InformationCenter/SupportServiceData/1.0.0.1", "File");
		FileObject1 = Factory.Create(FileType);
		FileObject1.Name = CurrentFile.FileName;
		FileObject1.Data = GetFromTempStorage(CurrentFile.StorageAddress);
		FileObject1.Extension = CurrentFile.Extension;
		FileObject1.Size = CurrentFile.Size;
		
		DataProcessors.InformationCenter.AddValueToXDTOList(ListOfFiles, "Files", FileObject1);
		
	EndDo;
	
	Return ListOfFiles;
	
EndFunction

&AtClient
Procedure SetCursorInTextTemplate()
	
	AttachIdleHandler("HandlerSetCursorInTextTemplate", 0.5, True);
	
EndProcedure

&AtClient
Procedure HandlerSetCursorInTextTemplate()
	
	CurrentItem = Items.Content;
	Bookmark = Content.GetPositionBookmark(CursorPosition);
	Items.Content.SetTextSelectionBounds(Bookmark, Bookmark);
	
EndProcedure

&AtServer
Procedure CreateFormElementsForAttachedFile()
	
	For Each SelectedFile_ In SelectedFiles_SSLyf Do
		
		If Not IsBlankString(SelectedFile_.DeleteButtonName) Then 
			Continue;
		EndIf;
		
		FilePresentation = SelectedFile_.FileName + SelectedFile_.Extension
			+ " (" + Round(SelectedFile_.Size / 1024, 2) + " " + NStr("ru = 'Кб';
																		|en = 'kB';") +")";
		
		IndexOf = SelectedFile_.GetID();
		
		FileGroup_ = 
			Items.Add("FileGroup_" + String(IndexOf), Type("FormGroup"), Items.AttachedFileGroup);
		FileGroup_.Type = FormGroupType.UsualGroup;
		FileGroup_.ShowTitle = False;
		FileGroup_.Group = ChildFormItemsGroup.Horizontal;
		FileGroup_.Representation = UsualGroupRepresentation.None;
		
		FileNameText = Items.Add("FileNameText" + String(IndexOf), Type("FormDecoration"), FileGroup_);
		FileNameText.Type = FormDecorationType.Label;
		FileNameText.Title = StringFunctions.FormattedString("<a href=""%1"">%2</a>", String(IndexOf), FilePresentation);
		FileNameText.AutoMaxWidth = False;
		FileNameText.HorizontalStretch = True; 
		FileNameText.SetAction("URLProcessing", "Attachable_DownloadFile");
		
		DeleteFileButton = 
			Items.Add("DeleteFileButton" + String(IndexOf), Type("FormDecoration"), FileGroup_);
		DeleteFileButton.Type = FormDecorationType.Picture;
		DeleteFileButton.Picture = PictureLib.DeleteDirectly;
		DeleteFileButton.ToolTip = NStr("ru = 'Удалить файл';
											|en = 'Delete file';");
		DeleteFileButton.Width = 2;
		DeleteFileButton.Height = 1;
		DeleteFileButton.PictureSize = PictureSize.Stretch;
		DeleteFileButton.Hyperlink = True;
		DeleteFileButton.SetAction("Click", "Attachable_DeleteFile");
		
		SelectedFile_.DeleteButtonName = DeleteFileButton.Name;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ShowMessageToUser(Text)
	
	Message = New UserMessage;
	Message.Text = Text;
	Message.Message();
	
EndProcedure

&AtServer
Function ParseStringWithEmailAddresses(ResponseAddress)
	
	Return CommonClientServer.ParseStringWithEmailAddresses(ResponseAddress, False);
	
EndFunction

#EndRegion