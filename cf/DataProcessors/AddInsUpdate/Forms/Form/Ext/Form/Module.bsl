///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	UpdateMode = ModeUpdateFromService();
	
	If Not Users.IsFullUser() Then
		Items.GroupPages.CurrentPage        = Items.UpdateResultsGroup;
		Items.ResultDetailsDecoration.Title =
			NStr("ru = 'Недостаточно прав доступа для обновления внешних компонент.';
				|en = 'Insufficient access rights for add-in update.';");
		Items.PictureResultDecoration.Picture   = PictureLib.Error32;
		Items.BackButton.Visible                 = False;
		Items.NextButton.Visible                 = False;
		Return;
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Items.GroupPages.CurrentPage        = Items.UpdateResultsGroup;
		Items.ResultDetailsDecoration.Title =
			NStr("ru = 'Использование обработки недоступно при работе в модели сервиса.';
				|en = 'The data processor cannot be used in SaaS.';");
		Items.PictureResultDecoration.Picture   = PictureLib.Error32;
		Items.BackButton.Visible                 = False;
		Items.NextButton.Visible                 = False;
		Return;
	EndIf;
	
	PopulateFormByParameters();
	
	If Common.IsWebClient() Then
		
		If UpdateMode = ModeUpdateFromFile() Then
			
			UpdateMode = ModeUpdateFromService();
			Items.GroupPages.CurrentPage        = Items.UpdateResultsGroup;
			Items.ResultDetailsDecoration.Title =
				NStr("ru = 'Загрузка из файла недоступна при работе в веб-клиенте.';
					|en = 'Import from a file is unavailable in the web client.';");
			Items.PictureResultDecoration.Picture   = PictureLib.Error32;
			Items.BackButton.Visible                 = False;
			Items.NextButton.Visible                 = False;
			Return;
		EndIf;
		
		InformationOnAvailableUpdatesFromService();
		
	ElsIf UpdateMode = ModeUpdateFromService() Then
		
		If AddInsIDs.Count() > 0 Then
			InformationOnAvailableUpdatesFromService();
			Return;
		EndIf;
		
		CanSelectUpdateMode = True;
		SetFormItemsView(ThisObject);
		
	ElsIf ValueIsFilled(AddressOfUpdateFile) Then
		InformationOnAvailableUpdatesFromFileAtServer();
	Else
		Items.GroupPages.CurrentPage = Items.TimeConsumingOperationGroup;
		Items.UpdateIndicator.Visible  = False;
		Items.StateDecoration.Title   = NStr("ru = 'Обработка файла внешних компонент.';
														|en = 'Processing add-in file.';");
		SetFormItemsView(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If UpdateMode = ModeUpdateFromFile()
			And Not IsBlankString(UpdateFile) Then
		AttachIdleHandler("InformationOnAvailableUpdatesFromFile", 0.5, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UpdateModeOnChange(Item)
	
	SetFormItemsView(ThisObject);
	
EndProcedure

&AtClient
Procedure UpdateFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FileDialog = New FileDialog(FileDialogMode.Open);
	FileDialog.Filter = NStr("ru = 'Архив';
									|en = 'Archive';") + "(*.zip)|*.zip";
	
	NotifyDescription = New NotifyDescription(
		"UpdateFileStartChoiceCompletion",
		ThisObject);
	
	FileSystemClient.ShowSelectionDialog(
		NotifyDescription,
		FileDialog);
	
EndProcedure

&AtClient
Procedure ResultDetailsDecorationURLProcessing(
		Item,
		FormattedStringURL,
		StandardProcessing)
	
	If FormattedStringURL = "action:openLog" Then
		
		StandardProcessing = False;
		Filter = New Structure;
		Filter.Insert("Level", "Error");
		Filter.Insert("EventLogEvent", GetAddInsClient.EventLogEventName());
		EventLogClient.OpenEventLog(Filter);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ActivationAuthorizationNotesLabelURLProcessing(
		Item,
		FormattedStringURL,
		StandardProcessing)
	
	If FormattedStringURL = "action:openPortal" Then
		StandardProcessing = False;
		OnlineUserSupportClient.OpenWebPage(
			OnlineUserSupportClientServer.LoginServicePageURL(
				,
				OnlineUserSupportClient.ServersConnectionSettings()));
	EndIf;
	
EndProcedure

&AtClient
Procedure LoginOnChange(Item)
	
	SaveAuthenticationData = True;
	
EndProcedure

&AtClient
Procedure PasswordOnChange(Item)
	
	SaveAuthenticationData = True;
	OnlineUserSupportClient.OnChangeSecretData(Item);
	
EndProcedure

&AtClient
Procedure PasswordStartChoice(Item, ChoiceData, StandardProcessing)
	
	OnlineUserSupportClient.ShowSecretData(
		ThisObject,
		Item,
		"Password");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAddInsData

&AtClient
Procedure AddInsDataBeforeAddRow(
		Item,
		Cancel,
		Copy,
		Parent,
		Var_Group,
		Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure AddInsDataBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	ClearMessages();
	
	If Items.GroupPages.CurrentPage = Items.ConnectionToPortalGroup Then
		
		Result = OnlineUserSupportClientServer.VerifyAuthenticationData(
			New Structure("Login, Password",
			Login, Password));
		
		If Result.Cancel Then
			CommonClient.MessageToUser(
				Result.ErrorMessage,
				,
				Result.Field);
		EndIf;
		
		If Result.Cancel Then
			Return;
		EndIf;
		
		CheckConnectionTo1CITSPortal();
		
	ElsIf Items.GroupPages.CurrentPage = Items.UpdateModeSelectionGroup Then
		If UpdateMode = ModeUpdateFromService() Then
			InformationOnAvailableUpdatesFromService();
		Else
			InformationOnAvailableUpdatesFromFile();
		EndIf;
	ElsIf Items.GroupPages.CurrentPage = Items.GroupAddInsChoice Then
		If UpdateMode = ModeUpdateFromService() Then
			StartUpdateAddInsService();
		Else
			If IsBlankString(UpdateFile) Then
				StartUpdateAddInsFromFileAfterDownload(
					AddressOfUpdateFile,
					Undefined);
			Else
				StartUpdateAddInsFromFile();
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	If CanSelectUpdateMode Then
		Items.GroupPages.CurrentPage = Items.UpdateModeSelectionGroup;
		SetFormItemsView(ThisObject);
		Login  = "";
		Password = "";
	Else
		If UpdateMode = ModeUpdateFromService() Then
			InformationOnAvailableUpdatesFromService();
		Else
			InformationOnAvailableUpdatesFromFile();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckAll(Command)
	
	SetCheck(True);
	
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	SetCheck(False);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure PopulateFormByParameters()
	
	If TypeOf(Parameters.IDs) = Type("Array") Then
		
		For Each Id In Parameters.IDs Do
			AddInsIDs.Add(Id);
		EndDo;
		
	EndIf;
	
	If Not IsBlankString(Parameters.UpdateFile) Then
		
		UpdateMode = ModeUpdateFromFile();
		If IsTempStorageURL(Parameters.UpdateFile) Then
			Items.UpdateFile.Visible = False;
			AddressOfUpdateFile = Parameters.UpdateFile;
		Else
			UpdateFile = Parameters.UpdateFile;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateFileStartChoiceCompletion(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles <> Undefined
		And SelectedFiles.Count() <> 0 Then
		UpdateFile = SelectedFiles[0];
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckConnectionTo1CITSPortal()
	
	AddInsData.Clear();
	
	ReceivingParameters = PrepareParametersOfGetInformationOnUpdates(
		AddInsIDs);
	
	If ReceivingParameters.VersionsOfExternalComponents.Count() = 0 Then
		SetErrorInformationDisplay(
			ThisObject,
			NStr("ru = 'Отсутствуют внешние компоненты доступные для обновления.';
				|en = 'There are no add-ins available for update.';"));
		SetFormItemsView(ThisObject);
		Return;
	EndIf;
	
	// Get information from the add-in service.
	OperationResult = GetAddIns.InternalAddInsAvailableUpdates(
		ReceivingParameters.VersionsOfExternalComponents,
		New Structure("Login, Password",
			Login, Password));
	
	If OperationResult.ErrorCode = "InvalidUsernameOrPassword" Then
		Common.MessageToUser(
			OperationResult.ErrorMessage,
			,
			"Login");
		Return;
	EndIf;
	
	FillInformationOnAvailableUpdates(
		OperationResult,
		ReceivingParameters.VersionsOfExternalComponents);
	
EndProcedure

&AtServer
Procedure InformationOnAvailableUpdatesFromService()
	
	If Not OnlineUserSupport.AuthenticationDataOfOnlineSupportUserFilled() Then
		SaveAuthenticationData = True;
		Items.GroupPages.CurrentPage = Items.ConnectionToPortalGroup;
		SetFormItemsView(ThisObject);
		Return;
	EndIf;
	
	AddInsData.Clear();
	
	ReceivingParameters = PrepareParametersOfGetInformationOnUpdates(AddInsIDs);
	
	If ReceivingParameters.VersionsOfExternalComponents.Count() = 0 Then
		SetErrorInformationDisplay(
			ThisObject,
			NStr("ru = 'Отсутствуют внешние компоненты доступные для обновления.';
				|en = 'There are no add-ins available for update.';"));
		SetFormItemsView(ThisObject);
		Return;
	EndIf;
	
	// Get information from the add-in service.
	OperationResult = GetAddIns.InternalAddInsAvailableUpdates(
		ReceivingParameters.VersionsOfExternalComponents);
	FillInformationOnAvailableUpdates(
		OperationResult,
		ReceivingParameters.VersionsOfExternalComponents);
	
EndProcedure

&AtServer
Procedure FillInformationOnAvailableUpdates(OperationResult, VersionsOfExternalComponents)
	
	// Process operation errors.
	If ValueIsFilled(OperationResult.ErrorCode) Then
		If OperationResult.ErrorCode = "InvalidUsernameOrPassword" Then
			SaveAuthenticationData = True;
			Items.GroupPages.CurrentPage = Items.ConnectionToPortalGroup;
			SetFormItemsView(ThisObject);
		Else
			// If authorization is successful, clear the form attributes.
			If SaveAuthenticationData Then
				Login  = "";
				Password = "";
				SaveAuthenticationData = False;
			EndIf;
			SetErrorInformationDisplay(
				ThisObject,
				OperationResult.ErrorMessage,
				True);
			SetFormItemsView(ThisObject);
		EndIf;
		Return;
	EndIf;
	
	// If authorization is successful, clear the form attributes.
	If SaveAuthenticationData Then
		
		// Write data.
		SetPrivilegedMode(True);
		OnlineUserSupport.ServiceSaveAuthenticationData(
			New Structure(
				"Login, Password",
				Login,
				Password));
		SetPrivilegedMode(False);
		
		Login  = "";
		Password = "";
		SaveAuthenticationData = False;
		
	EndIf;
	
	// Filling in a table with updates.
	For Each AddInDetails In VersionsOfExternalComponents Do
		
		For Each VersionDetails In OperationResult.AvailableVersions Do
			If VersionDetails.Id = AddInDetails.Id Then
				
				AddInRow = AddInsData.Add();
				FillPropertyValues(
					AddInRow,
					AddInDetails,
					"Id");
				
				AddInRow.Checksum   = VersionDetails.FileID.Checksum;
				AddInRow.FileID = VersionDetails.FileID.FileID;
				AddInRow.Description       = VersionDetails.Description;
				AddInRow.Version             = VersionDetails.Version;
				AddInRow.VersionDate         = VersionDetails.VersionDate;
				AddInRow.VersionDetails     = VersionDetails.VersionDetails;
				AddInRow.Size             = VersionDetails.Size;
				AddInRow.Used       = True;
				
				If AddInDetails.VersionDate >= VersionDetails.VersionDate Then
					AddInRow.Version        = AddInDetails.Version;
					AddInRow.Presentation = NoUpdateRequired(AddInRow.Description);
				Else
					AddInRow.UpdateRequired = True;
					AddInRow.Mark             = True;
					AddInRow.Presentation = AddInRow.Description;
				EndIf;
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	If AddInsData.Count() <> 0 Then
		AddInsData.Sort("Mark Desc, Description");
		Items.GroupPages.CurrentPage = Items.GroupAddInsChoice;
		SetFormItemsView(ThisObject);
	Else
		SetErrorInformationDisplay(
			ThisObject,
			NStr("ru = 'Не найдены доступные обновления внешних компонент.';
				|en = 'Available add-in updates are not found.';"));
	EndIf;
	
EndProcedure

&AtServer
Procedure InformationOnAvailableUpdatesFromFileAtServer()
	
	AddInsData.Clear();
	
	NameUpdateFile = GetTempFileName(".zip");
	FileData = GetFromTempStorage(AddressOfUpdateFile);
	FileData.Write(NameUpdateFile);
	FileData = Undefined;
	
	VersionsOfExternalComponents = GetAddIns.AddInsVersionsFromFile(
		NameUpdateFile);
	FileSystem.DeleteTempFile(NameUpdateFile);
	
	VersionsOfExternalComponents = VersionsOfExternalComponents.AddInsData;
	If VersionsOfExternalComponents.Count() = 0 Then
		Common.MessageToUser(
			NStr("ru = 'Не удалось получить описание внешних компонент из файла (подробнее см. Журнал регистрации).';
				|en = 'Cannot get add-in details from the file. For more information, see the event log.';"));
		Return;
	EndIf;
	
	DeleteUnavailableAddInsVersionsAtServer(
		VersionsOfExternalComponents,
		AddInsIDs);
	
	If VersionsOfExternalComponents.Count() = 0 Then
		Common.MessageToUser(
			NStr("ru = 'Не найдены доступные обновления указанных внешних компонент.';
				|en = 'Available updates are not found for the specified add-ins.';"));
		Return;
	EndIf;
	
	FillInfoOnAvailableUpdatesAtServer(VersionsOfExternalComponents);
	
EndProcedure

&AtServerNoContext
Procedure DeleteUnavailableAddInsVersionsAtServer(
		AddInsVersions,
		IDs)
	
	If IDs.Count() = 0 Then
		Return;
	EndIf;
	
	DeleteRows_ = New Array;
	For Each VersionComponents In AddInsVersions Do
		If IDs.FindByValue(VersionComponents.Id) = Undefined Then
			DeleteRows_.Add(VersionComponents);
		EndIf;
	EndDo;
	
	For Each VersionComponents In DeleteRows_ Do
		AddInsVersions.Delete(VersionComponents);
	EndDo;
	
EndProcedure

&AtClient
Procedure InformationOnAvailableUpdatesFromFile()
	
	AddInsData.Clear();
	
	If Not ValueIsFilled(UpdateFile) Then
		CommonClient.MessageToUser(
			NStr("ru = 'Не выбран файл обновления.';
				|en = 'Update file not selected.';"),
			,
			"UpdateFile");
		Return;
	EndIf;
	
	PathComponents = CommonClientServer.ParseFullFileName(UpdateFile);
	If PathComponents.Extension <> ".zip" Then
		CommonClient.MessageToUser(
			NStr("ru = 'Неверный формат файла.';
				|en = 'Invalid file format.';"),
			,
			"UpdateFile");
		Return;
	EndIf;
	
	VersionsOfExternalComponents = GetAddInsClient.AddInsVersionsInFile(
		UpdateFile);
	If VersionsOfExternalComponents.Count() = 0 Then
		CommonClient.MessageToUser(
			NStr("ru = 'Не удалось получить описание внешних компонент из файла (подробнее см. Журнал регистрации).';
				|en = 'Cannot get add-in details from the file. For more information, see the event log.';"),
			,
			"UpdateFile");
		Return;
	EndIf;
	
	DeleteUnavailableAddInsVersions(VersionsOfExternalComponents, AddInsIDs);
	If VersionsOfExternalComponents.Count() = 0 Then
		CommonClient.MessageToUser(
			NStr("ru = 'Не найдены доступные обновления указанных внешних компонент.';
				|en = 'Available updates are not found for the specified add-ins.';"));
		Return;
	EndIf;
	
	FillInfoOnAvailableUpdatesAtServer(VersionsOfExternalComponents);
	
EndProcedure

&AtClient
Procedure DeleteUnavailableAddInsVersions(AddInsVersions, IDs)
	
	If IDs.Count() = 0 Then
		Return;
	EndIf;
	
	Result = New Array;
	
	For Each VersionComponents In AddInsVersions Do
		If IDs.FindByValue(VersionComponents.Id) <> Undefined Then
			Result.Add(VersionComponents);
		EndIf;
	EndDo;
	
	AddInsVersions = Result;
	
EndProcedure

&AtServer
Procedure FillInfoOnAvailableUpdatesAtServer(Val VersionsOfExternalComponents)
	
	InfobaseAddInsVersions = GetAddIns.AddInsDataForInteractiveUpdate(
		AddInsIDs);
	
	For Each AddInVersion In VersionsOfExternalComponents Do
		
		UpdateRequired = True;
		IsAddInUsed = False;
		For Each InfobaseAddInVersion In InfobaseAddInsVersions Do
			If InfobaseAddInVersion.Id = AddInVersion.Id Then
				IsAddInUsed = True;
				If InfobaseAddInVersion.VersionDate >= AddInVersion.VersionDate Then
					UpdateRequired = False;
				EndIf;
				Break;
			EndIf;
		EndDo;
		
		AddInDetails = AddInsData.Add();
		AddInDetails.Mark      = IsAddInUsed And UpdateRequired;
		AddInDetails.Description = AddInVersion.Description;
		If Not IsAddInUsed Then
			AddInDetails.Presentation = ComponentNotUsed(AddInVersion.Description);
		ElsIf UpdateRequired Then
			AddInDetails.Presentation = AddInVersion.Description;
		Else
			AddInDetails.Presentation = NoUpdateRequired(AddInVersion.Description);
		EndIf;
		
		AddInDetails.Version              = AddInVersion.Version;
		AddInDetails.VersionDate          = AddInVersion.VersionDate;
		AddInDetails.UpdateRequired = UpdateRequired;
		AddInDetails.Used        = IsAddInUsed;
		AddInDetails.Id       = AddInVersion.Id;
		AddInDetails.FileID  = AddInVersion.FileName;
		
	EndDo;
	
	If AddInsData.Count() <> 0 Then
		AddInsData.Sort("Mark Desc, Description");
		Items.GroupPages.CurrentPage = Items.GroupAddInsChoice;
	Else
		SetErrorInformationDisplay(
			ThisObject,
			NStr("ru = 'Не найдены доступные обновления внешних компонент.';
				|en = 'Available add-in updates are not found.';"));
	EndIf;
	
	SetFormItemsView(ThisObject);
	
EndProcedure

&AtClient
Procedure StartUpdateAddInsFromFileAfterDownload(
		PlacedFiles,
		AdditionalParameters) Export
	
	If IsTempStorageURL(PlacedFiles) Then
		FileAddress = PlacedFiles;
	ElsIf PlacedFiles = Undefined
		Or PlacedFiles.Count() = 0 Then
		CommonClient.MessageToUser(
			NStr("ru = 'Файл с обновлениями не загружен.';
				|en = 'File with updates is not imported.';"));
		Return;
	Else
		FileAddress = PlacedFiles[0].Location
	EndIf;
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	ExecutionResult = InteractiveUpdateOfAddInsFromFile(
		FileAddress);
	
	CallbackOnCompletion = New NotifyDescription(
		"StartUpdateAddInsCompletion",
		ThisObject);
		
	If ExecutionResult.Status = "Completed2"
		Or ExecutionResult.Status = "Error" Then
		StartUpdateAddInsCompletion(ExecutionResult, Undefined);
		Return;
	EndIf;
	
	// Set up the long-running operation page.
	Items.GroupPages.CurrentPage = Items.TimeConsumingOperationGroup;
	Items.UpdateIndicator.Visible  = False;
	Items.StateDecoration.Title   = NStr("ru = 'Обработка файлов внешней компоненты на сервере.';
													|en = 'Processing add-in files on the server.';");
	SetFormItemsView(ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(
		ExecutionResult,
		CallbackOnCompletion,
		IdleParameters);
	
EndProcedure

&AtServer
Function InteractiveUpdateOfAddInsFromFile(Val FileAddress)
	
	Filter = New Structure("Mark", True);
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("FileData", GetFromTempStorage(FileAddress));
	ProcedureParameters.Insert("AddInsData", AddInsData.Unload(Filter));
	DeleteFromTempStorage(FileAddress);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Обработка файлов внешней компоненты на сервере.';
															|en = 'Process add-in files on the server.';");
	
	ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
		"GetAddIns.InteractiveUpdateOfAddInsFromFile",
		ProcedureParameters,
		ExecutionParameters);
	
	Return ExecutionResult;
	
EndFunction

&AtClient
Procedure StartUpdateAddInsService()
	
	UpdateIndicator = 0;
	ExecutionProgressNotification = New NotifyDescription(
		"RefreshImportIndicator",
		ThisObject);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow           = False;
	IdleParameters.ExecutionProgressNotification = ExecutionProgressNotification;
	
	ExecutionResult = AddInsInteractiveUpdateFromService();
	
	CallbackOnCompletion = New NotifyDescription(
		"StartUpdateAddInsCompletion",
		ThisObject);
		
	If ExecutionResult.Status = "Completed2"
		Or ExecutionResult.Status = "Error" Then
		StartUpdateAddInsCompletion(ExecutionResult, Undefined);
		Return;
	EndIf;
	
	// Set up the long-running operation page.
	Items.GroupPages.CurrentPage = Items.TimeConsumingOperationGroup;
	Items.UpdateIndicator.Visible = True;
	Items.StateDecoration.Title  = NStr("ru = 'Выполняется обновление внешних компонент. Обновление может занять от
		|нескольких минут до нескольких часов в зависимости от размера обновления.';
		|en = 'Updating the add-ins. The update might take from
		|several minutes to several hours depending on the update size.';");
	
	SetFormItemsView(ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(
		ExecutionResult,
		CallbackOnCompletion,
		IdleParameters);
	
EndProcedure

&AtServer
Function AddInsInteractiveUpdateFromService()
	
	AddInsDataPreparation = AddInsData.Unload();
	AddInsDataPreparation.Columns.Add("FileData");
	DeleteRows_ = New Array;
	For Each AddInDetails In AddInsDataPreparation Do
		If Not AddInDetails.Mark Then
			DeleteRows_.Add(AddInDetails);
		EndIf;
	EndDo;
	
	For Each AddInDetails In DeleteRows_ Do
		AddInsDataPreparation.Delete(AddInDetails);
	EndDo;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("AddInsData", AddInsDataPreparation);
	ProcedureParameters.Insert("UpdateMode",        UpdateMode);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Обновление данных внешних компонент.';
															|en = 'Update add-in data.';");
	
	ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
		"GetAddIns.AddInsInteractiveUpdateFromService",
		ProcedureParameters,
		ExecutionParameters);
	
	Return ExecutionResult;
	
EndFunction

&AtClient
Procedure StartUpdateAddInsFromFile()
	
	NotifyDescription = New NotifyDescription(
		"StartUpdateAddInsFromFileAfterDownload",
		ThisObject);
	
	TransferableFileDescription = New TransferableFileDescription(UpdateFile);
	
	UpdatesFiles = New Array;
	UpdatesFiles.Add(TransferableFileDescription);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Interactively = False;
	
	FileSystemClient.ImportFiles(
		NotifyDescription,
		ImportParameters,
		UpdatesFiles);
	
EndProcedure

&AtClient
Procedure RefreshImportIndicator(ExecutionStatus, AdditionalParameters) Export
	
	Result = ReadProgress(ExecutionStatus.JobID);
	If Result = Undefined Then
		Return;
	EndIf;
	
	UpdateIndicator = Result.Percent;
	
EndProcedure

&AtServerNoContext
Function ReadProgress(Val JobID)
	
	Return TimeConsumingOperations.ReadProgress(JobID);
	
EndFunction

&AtClient
Procedure StartUpdateAddInsCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		
		OperationResult = UpdateResult(Result.ResultAddress);
		If HasAddInUpdateError(OperationResult) Then
			SetErrorInformationDisplay(
				ThisObject,
				AddInsUpdateErrorMessage(OperationResult));
		Else
			SetSuccessfulCompletionDisplay(ThisObject);
		EndIf;
		
		// Update the open add-in forms.
		IDs = New Array;
		For Each TableRow In AddInsData Do
			If TableRow.Mark Then
				IDs.Add(TableRow.Id);
			EndIf;
		EndDo;
		
		Notify(
			GetAddInsClient.ImportNotificationEventName(),
			IDs,
			ThisObject);
		
	ElsIf Result.Status = "Error" Then
		ErrorInfo = Result.BriefErrorDescription;
		SetErrorInformationDisplay(
			ThisObject,
			ErrorInfo,
			True);
	EndIf;
	
	SetFormItemsView(ThisObject);
	
EndProcedure

&AtClient
Function UpdateResult(Address)
	
	OperationResult = GetFromTempStorage(Address);
	
	Result = New Structure;
	Result.Insert("Errors", New Map);
	Result.Insert("ErrorCode", "");
	Result.Insert("ErrorMessage", "");
	
	FillPropertyValues(Result, OperationResult);
	
	Return Result
	
EndFunction

&AtClient
Function HasAddInUpdateError(OperationResult)
	
	Return OperationResult.Errors.Count() = 0
		And Not IsBlankString(OperationResult.ErrorCode);
	
EndFunction

&AtClient
Function AddInsUpdateErrorMessage(OperationResult)
	
	Result = "";
	If OperationResult.Errors.Count() > 0 Then
		
		OperationErrors = New Array;
		OperationErrors.Add(NStr("ru = 'При обновлении внешних компонент возникли ошибки:';
									|en = 'Errors occurred when updating the add-ins:';"));
		For Each OperationError In OperationResult.Errors Do
			OperationErrors.Add(OperationError.Value);
		EndDo;
		Result = StrConcat(OperationErrors, Chars.LF);
		
	ElsIf Not IsBlankString(OperationResult.ErrorMessage) Then
		Result = OperationResult.ErrorMessage;
	Else
		Raise NStr("ru = 'Неизвестный результат операции обновления внешних компонент.';
								|en = 'Unknown result of the add-in update operation.';");
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetFormItemsView(Form)
	
	Items = Form.Items;
	If Items.GroupPages.CurrentPage = Items.UpdateModeSelectionGroup Then
		Items.BackButton.Visible = False;
		Items.NextButton.Visible = True;
	ElsIf Items.GroupPages.CurrentPage = Items.ConnectionToPortalGroup Then
		Items.BackButton.Visible = Form.CanSelectUpdateMode;
		Items.NextButton.Visible = True;
	ElsIf Items.GroupPages.CurrentPage = Items.GroupAddInsChoice Then
		Items.BackButton.Visible = Form.CanSelectUpdateMode;
		Items.NextButton.Visible = True;
	ElsIf Items.GroupPages.CurrentPage = Items.TimeConsumingOperationGroup Then
		Items.BackButton.Visible = False;
		Items.NextButton.Visible = False;
	ElsIf Items.GroupPages.CurrentPage = Items.UpdateResultsGroup Then
		Items.BackButton.Visible = Form.CanSelectUpdateMode;
		Items.NextButton.Visible = False;
	EndIf;
	
	If Form.UpdateMode = ModeUpdateFromService() Then
		Items.UpdateFile.Enabled = False;
	Else
		Items.UpdateFile.Enabled = True;
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure SetErrorInformationDisplay(
		Form,
		ErrorInfo,
		Error = False)
	
	ErrorPresentation = OnlineUserSupportClientServer.FormattedStringFromHTML(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1
				|
				|Подробную информацию см. в <a href = ""action:openLog"">Журнале регистрации</a>.';
				|en = '%1
				|
				|For more information, see <a href = ""action:openLog"">Event log</a>.';"),
			ErrorInfo));
	
	Form.Items.GroupPages.CurrentPage        = Form.Items.UpdateResultsGroup;
	Form.Items.ResultDetailsDecoration.Title = ErrorPresentation;
	Form.Items.PictureResultDecoration.Picture   = ?(
		Error,
		PictureLib.Error32,
		PictureLib.Warning32);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSuccessfulCompletionDisplay(Form)
	
	Form.Items.GroupPages.CurrentPage        = Form.Items.UpdateResultsGroup;
	Form.Items.PictureResultDecoration.Picture   = PictureLib.Success32;
	Form.Items.ResultDetailsDecoration.Title = NStr("ru = 'Обновление внешних компонент успешно завершено.';
																|en = 'The add-ins are updated.';");
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AddInsDataVersion.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AddInsDataPresentation.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AddInsDataMark.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AddInsData.UpdateRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue(
		"TextColor",
		Metadata.StyleItems.InactiveLineColor.Value);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AddInsDataVersion.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AddInsDataPresentation.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AddInsDataMark.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AddInsData.Used");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue(
		"TextColor",
		Metadata.StyleItems.InactiveLineColor.Value);
	
EndProcedure

&AtClient
Procedure SetCheck(Value)
	
	For Each AddInRow In AddInsData Do
		AddInRow.Mark = Value;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function ModeUpdateFromService()
	
	Return 1;
	
EndFunction

&AtClientAtServerNoContext
Function ModeUpdateFromFile()
	
	Return 2;
	
EndFunction

&AtClientAtServerNoContext
Function NoUpdateRequired(Description)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = '%1 (обновление не требуется)';
			|en = '%1 (no update is required)';"),
		Description);
	
EndFunction

&AtClientAtServerNoContext
Function ComponentNotUsed(Description)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = '%1 (не используется)';
			|en = '%1 (not used)';"),
		Description);
	
EndFunction

&AtServerNoContext
Function PrepareParametersOfGetInformationOnUpdates(Val AddInsFilter)
	
	VersionsOfExternalComponents = GetAddIns.AddInsDataForInteractiveUpdate(
		AddInsFilter);
	
	ReceivingParameters = New Structure;
	ReceivingParameters.Insert("VersionsOfExternalComponents", VersionsOfExternalComponents);
	
	Return ReceivingParameters;
	
EndFunction

#EndRegion
