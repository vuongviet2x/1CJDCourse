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
	
	If Common.DataSeparationEnabled() Then
		Items.GroupPages.CurrentPage        = Items.UpdateResultsGroup;
		Items.ResultDetailsDecoration.Title =
			NStr("ru = 'Использование обработки недоступно при работе в модели сервиса.';
				|en = 'The data processor cannot be used in SaaS.';");
		Items.PictureResultDecoration.Picture   = PictureLib.Error32;
		Items.BackButton.Visible                 = False;
		Items.NextButton.Visible                 = False;
	Else
		SetFormItemsView(ThisObject);
	EndIf;
	
	// Import from a file in the web client is impossible.
	If Common.IsWebClient() Then
		InformationOnAvailableUpdatesFromService();
	EndIf;
	
	CanContactTechnicalSupport = Common.SubsystemExists("OnlineUserSupport.MessagesToTechSupportService");
	
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

&AtClient
Procedure DecorationNavigateToEventLogURLProcessing(
		Item,
		FormattedStringURL,
		StandardProcessing)
	
	If FormattedStringURL = "action:openLog" Then
		StandardProcessing = False;
		Filter = New Structure;
		Filter.Insert("Level", "Error");
		Filter.Insert("EventLogEvent", ClassifiersOperationsClient.EventLogEventName());
		EventLogClient.OpenEventLog(Filter);
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationTechnicalSupportURLProcessing(
		Item,
		FormattedStringURL,
		StandardProcessing)
	
		If FormattedStringURL = "action:support" Then
			
			StandardProcessing = False;
			If CommonClient.SubsystemExists("OnlineUserSupport.MessagesToTechSupportService") Then
				TheModuleOfTheMessageToTheTechnicalSupportServiceClientServer =
					CommonClient.CommonModule("MessagesToTechSupportServiceClientServer");
				MessageData = TheModuleOfTheMessageToTheTechnicalSupportServiceClientServer.MessageData();
				MessageData.Recipient = "webIts";
				MessageData.Subject = NStr("ru = 'Интернет-поддержка. Обновление классификаторов';
											|en = 'Online support. Classifier update';");
				MessageData.Message = ErrorMessage;
				
				If ErrorInfo <> "" Then
					TheModuleOfTheMessageToTheTechnicalSupportServiceClientServer.FillCannedResponseSearchSettings(
						ErrorInfo,
						MessageData.CannedResponseSearchSettings);
				EndIf;
				
				TheModuleOfTheMessageToTheTechnicalSupportServiceClient =
					CommonClient.CommonModule("MessagesToTechSupportServiceClient");
				TheModuleOfTheMessageToTheTechnicalSupportServiceClient.SendMessage(
					MessageData);
			EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersClassifiersData

&AtClient
Procedure ClassifiersDataBeforeAddRow(
		Item,
		Cancel,
		Copy,
		Parent,
		Var_Group,
		Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ClassifiersDataBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	ClearMessages();
	ErrorInfo = "";
	ErrorMessage = "";
	
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
		If UpdateMode = OnlineUpdateMode() Then
			InformationOnAvailableUpdatesFromService();
		Else
			InformationOnAvailableUpdatesFromFile();
		EndIf;
	ElsIf Items.GroupPages.CurrentPage = Items.ClassifiersSelectionGroup Then
		If UpdateMode = OnlineUpdateMode() Then
			StartClassifiersUpdateService();
		Else
			StartClassifiersUpdateFromFile();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	Items.GroupPages.CurrentPage = Items.UpdateModeSelectionGroup;
	SetFormItemsView(ThisObject);
	Login = "";
	Password = "";
	ErrorInfo = "";
	ErrorMessage = "";
	
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

&AtClient
Procedure UpdateFileStartChoiceCompletion(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles <> Undefined And SelectedFiles.Count() <> 0 Then
		UpdateFile = SelectedFiles[0];
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckConnectionTo1CITSPortal()
	
	ReceivingParameters = PrepareParametersOfGetInformationOnUpdates();
	
	If ReceivingParameters.IDs.Count() = 0 Then
		SetErrorInformationDisplay(
			ThisObject,
			NStr("ru = 'Отсутствуют классификаторы доступные для обновления.';
				|en = 'There are no classifiers available for updating.';"),
			False,
			False);
		SetFormItemsView(ThisObject);
		Return;
	EndIf;
	
	// Getting information from a classifier service.
	OperationResult = ClassifiersOperations.InternalAvailableClassifiersUpdates(
		ReceivingParameters.IDs,
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
		ReceivingParameters.ClassifiersVersions);
	
EndProcedure

&AtServer
Procedure InformationOnAvailableUpdatesFromService()
	
	If Not OnlineUserSupport.AuthenticationDataOfOnlineSupportUserFilled() Then
		SaveAuthenticationData = True;
		Items.GroupPages.CurrentPage = Items.ConnectionToPortalGroup;
		SetFormItemsView(ThisObject);
		Return;
	EndIf;
	
	ReceivingParameters = PrepareParametersOfGetInformationOnUpdates();
	
	If ReceivingParameters.IDs.Count() = 0 Then
		SetErrorInformationDisplay(
			ThisObject,
			NStr("ru = 'Отсутствуют классификаторы доступные для обновления.';
				|en = 'There are no classifiers available for updating.';"),
			False,
			False);
		SetFormItemsView(ThisObject);
		Return;
	EndIf;
	
	// Getting information from a classifier service.
	OperationResult = ClassifiersOperations.InternalAvailableClassifiersUpdates(
		ReceivingParameters.IDs,
		Undefined);
	FillInformationOnAvailableUpdates(
		OperationResult,
		ReceivingParameters.ClassifiersVersions);
	
EndProcedure

&AtServer
Procedure FillInformationOnAvailableUpdates(OperationResult, ClassifiersVersions)
	
	ErrorInfo = OperationResult.ErrorInfo;
	
	// Process operation errors.
	If ValueIsFilled(OperationResult.ErrorCode) Then
		If OperationResult.ErrorCode = "InvalidUsernameOrPassword" Then
			SaveAuthenticationData = True;
			Items.GroupPages.CurrentPage = Items.ConnectionToPortalGroup;
			SetFormItemsView(ThisObject);
		Else
			// If authorization is successful, clear the form attributes.
			If SaveAuthenticationData Then
				Login = "";
				Password = "";
				SaveAuthenticationData = False;
			EndIf;
			SetErrorInformationDisplay(
				ThisObject,
				OperationResult.ErrorMessage);
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
		
		Login = "";
		Password = "";
		SaveAuthenticationData = False;
		
	EndIf;
	
	// Filling in a table with updates.
	For Each ClassifierDetails In ClassifiersVersions Do
		
		For Each VersionDetails In OperationResult.AvailableVersions Do
			If VersionDetails.Id = ClassifierDetails.Id Then
				
				ClassifierRow = ClassifiersData.Add();
				FillPropertyValues(
					ClassifierRow,
					ClassifierDetails,
					"Id, Description");
				
				ClassifierRow.Checksum   = VersionDetails.FileID.Checksum;
				ClassifierRow.FileID = VersionDetails.FileID.FileID;
				ClassifierRow.Version             = VersionDetails.Version;
				ClassifierRow.VersionDetails     = VersionDetails.VersionDetails;
				ClassifierRow.Size             = VersionDetails.Size;
				
				If ClassifierDetails.Version >= VersionDetails.Version Then
					ClassifierRow.Version        = ClassifierDetails.Version;
					ClassifierRow.Description = NoUpdateRequired(ClassifierDetails.Description);
				Else
					ClassifierRow.UpdateRequired = True;
					ClassifierRow.Mark             = True;
				EndIf;
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	If ClassifiersData.Count() <> 0 Then
		ClassifiersData.Sort("Mark Desc, Description");
		Items.GroupPages.CurrentPage = Items.ClassifiersSelectionGroup;
		SetFormItemsView(ThisObject);
	Else
		SetErrorInformationDisplay(
			ThisObject,
			NStr("ru = 'Не найдены доступные обновления классификаторов.';
				|en = 'Available classifier updates not found.';"),
			False,
			False);
	EndIf;
	
EndProcedure

&AtClient
Procedure InformationOnAvailableUpdatesFromFile()
	
	ClassifiersData.Clear();
	
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
	
	ClassifiersVersions = ClassifiersOperationsClient.ClassifiersVersionsInFile(
		UpdateFile);
	InformationOnAvailableUpdatesFromFileAtServer(ClassifiersVersions);
	
	If ClassifiersData.Count() <> 0 Then
		ClassifiersData.Sort("Mark Desc, Description");
		Items.GroupPages.CurrentPage = Items.ClassifiersSelectionGroup;
		SetFormItemsView(ThisObject);
	Else
		SetErrorInformationDisplay(
			ThisObject,
			NStr("ru = 'Не найдены доступные обновления классификаторов.';
				|en = 'Available classifier updates not found.';"),
			False,
			False);
	EndIf;
	SetFormItemsView(ThisObject);
	
EndProcedure

&AtServer
Procedure InformationOnAvailableUpdatesFromFileAtServer(Val ClassifiersVersions)
	
	// Populate versions for new classifiers.
	// 
	IBClassifiersVersions = ClassifiersOperations.ClassifiersDataForInteractiveUpdate();
	For Each ClassifierDetails In ClassifiersVersions Do
		If ClassifierDetails.Version = 0 Then
			ClassifierDetails.Version = ClassifiersOperations.ProcessInitialClassifierVersion(
				ClassifierDetails.Id);
		EndIf;
	EndDo;
	
	For Each ClassifierVersion In ClassifiersVersions Do
		
		UpdateRequired       = True;
		ClassifierInUse = False;
		For Each IBClassifierVersion In IBClassifiersVersions Do
			If IBClassifierVersion.Id = ClassifierVersion.Id Then
				ClassifierInUse = True;
				If IBClassifierVersion.Version >= ClassifierVersion.Version Then
					UpdateRequired = False;
				EndIf;
				Break;
			EndIf;
		EndDo;
		
		If ClassifierInUse Then
			LoadingString = ClassifiersData.Add();
			LoadingString.Mark             = UpdateRequired;
			If UpdateRequired Then
				LoadingString.Description = IBClassifierVersion.Description;
			Else
				LoadingString.Description = NoUpdateRequired(IBClassifierVersion.Description);
			EndIf;
			LoadingString.Version              = ClassifierVersion.Version;
			LoadingString.UpdateRequired = UpdateRequired;
			LoadingString.Id       = ClassifierVersion.Id;
			LoadingString.FileID  = ClassifierVersion.Name;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure StartClassifiersUpdateFromFileAfterImport(PlacedFiles, AdditionalParameters) Export
	
	If PlacedFiles = Undefined Or PlacedFiles.Count() = 0 Then
		CommonClient.MessageToUser(
			NStr("ru = 'Файл с обновлениями не загружен.';
				|en = 'File with updates is not imported.';"));
		Return;
	EndIf;
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow           = False;
	
	ExecutionResult = InteractiveClassifiersUpdateFromFile(
		PlacedFiles[0].Location);
	
	CallbackOnCompletion = New NotifyDescription(
		"StartClassifiersUpdateCompletion",
		ThisObject);
		
	If ExecutionResult.Status = "Completed2" Or ExecutionResult.Status = "Error" Then
		StartClassifiersUpdateCompletion(ExecutionResult, Undefined);
		Return;
	EndIf;
	
	// Set up the long-running operation page.
	Items.GroupPages.CurrentPage = Items.TimeConsumingOperationGroup;
	Items.UpdateIndicator.Visible  = False;
	Items.StateDecoration.Title   = NStr("ru = 'Обработка файлов классификатора на сервере.';
													|en = 'Process classifier files on server.';");
	SetFormItemsView(ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(
		ExecutionResult,
		CallbackOnCompletion,
		IdleParameters);
	
EndProcedure

&AtServer
Function InteractiveClassifiersUpdateFromFile(Val FileAddress)
	
	Filter = New Structure;
	Filter.Insert("Mark", True);
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("FileData", GetFromTempStorage(FileAddress));
	ProcedureParameters.Insert("ClassifiersData", ClassifiersData.Unload(Filter));
	DeleteFromTempStorage(FileAddress);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Обработка файлов классификатора на сервере.';
															|en = 'Process classifier files on server.';");
	
	ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
		"ClassifiersOperations.InteractiveClassifiersUpdateFromFile",
		ProcedureParameters,
		ExecutionParameters);
	
	Return ExecutionResult;
	
EndFunction

&AtClient
Procedure StartClassifiersUpdateService()
	
	UpdateIndicator = 0;
	ExecutionProgressNotification = New NotifyDescription(
		"RefreshImportIndicator",
		ThisObject);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow           = False;
	IdleParameters.ExecutionProgressNotification = ExecutionProgressNotification;
	
	ExecutionResult = InteractiveClassifiersUpdateFromService();
	
	CallbackOnCompletion = New NotifyDescription(
		"StartClassifiersUpdateCompletion",
		ThisObject);
		
	If ExecutionResult.Status = "Completed2" Or ExecutionResult.Status = "Error" Then
		StartClassifiersUpdateCompletion(ExecutionResult, Undefined);
		Return;
	EndIf;
	
	// Set up the long-running operation page.
	Items.GroupPages.CurrentPage = Items.TimeConsumingOperationGroup;
	Items.UpdateIndicator.Visible = True;
	Items.StateDecoration.Title  = NStr("ru = 'Выполняется обновление классификаторов. Обновление может занять от
		|нескольких минут до нескольких часов в зависимости от размера обновления.';
		|en = 'Classifiers are being updated. The update can take from
		|several minutes to several hours depending on the update size.';");
	
	SetFormItemsView(ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(
		ExecutionResult,
		CallbackOnCompletion,
		IdleParameters);
	
EndProcedure

&AtServer
Function InteractiveClassifiersUpdateFromService()
	
	ClassifiersDataPreparation = ClassifiersData.Unload();
	ClassifiersDataPreparation.Columns.Add("FileData");
	DeleteRows_ = New Array;
	For Each ClassifierDetails In ClassifiersDataPreparation Do
		If Not ClassifierDetails.Mark Then
			DeleteRows_.Add(ClassifierDetails);
		EndIf;
	EndDo;
	
	For Each ClassifierDetails In DeleteRows_ Do
		ClassifiersDataPreparation.Delete(ClassifierDetails);
	EndDo;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ClassifiersData", ClassifiersDataPreparation);
	ProcedureParameters.Insert("UpdateMode",       UpdateMode);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Обновление данных классификаторов.';
															|en = 'Update classifier data.';");
	
	ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
		"ClassifiersOperations.InteractiveClassifiersUpdateFromService",
		ProcedureParameters,
		ExecutionParameters);
	
	Return ExecutionResult;
	
EndFunction

&AtClient
Procedure StartClassifiersUpdateFromFile()
	
	NotifyDescription = New NotifyDescription(
		"StartClassifiersUpdateFromFileAfterImport",
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
Procedure StartClassifiersUpdateCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		
		OperationResult = GetFromTempStorage(Result.ResultAddress);
		If ValueIsFilled(OperationResult.ErrorCode) Then
			ErrorInfo = OperationResult.ErrorInfo;
			SetErrorInformationDisplay(
				ThisObject,
				OperationResult.ErrorMessage,
				False,
				False);
		Else
			SetSuccessfulCompletionDisplay(ThisObject);
		EndIf;
		
		// Updating open classifier forms.
		IDs = New Array;
		For Each TableRow In ClassifiersData Do
			If TableRow.Mark Then
				IDs.Add(TableRow.Id);
			EndIf;
		EndDo;
		
		Notify(
			ClassifiersOperationsClient.ImportNotificationEventName(),
			IDs,
			ThisObject);
		
	ElsIf Result.Status = "Error" Then
		ErrorInfo = Result.BriefErrorDescription;
		SetErrorInformationDisplay(ThisObject, ErrorInfo);
	EndIf;
	
	SetFormItemsView(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetFormItemsView(Form)
	
	Items = Form.Items;
	If Items.GroupPages.CurrentPage = Items.UpdateModeSelectionGroup Then
		Items.BackButton.Visible = False;
		Items.NextButton.Visible = True;
	ElsIf Items.GroupPages.CurrentPage = Items.ConnectionToPortalGroup Then
		Items.BackButton.Visible = True;
		Items.NextButton.Visible = True;
	ElsIf Items.GroupPages.CurrentPage = Items.ClassifiersSelectionGroup Then
		Items.BackButton.Visible = True;
		Items.NextButton.Visible = True;
	ElsIf Items.GroupPages.CurrentPage = Items.TimeConsumingOperationGroup Then
		Items.BackButton.Visible = False;
		Items.NextButton.Visible = False;
	ElsIf Items.GroupPages.CurrentPage = Items.UpdateResultsGroup Then
		Items.BackButton.Visible = True;
		Items.NextButton.Visible = False;
	EndIf;
	
	If Form.UpdateMode = 0 Then
		Items.UpdateFile.Enabled = False;
	Else
		Items.UpdateFile.Enabled = True;
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure SetErrorInformationDisplay(
		Form,
		ErrorInfo,
		Error = True,
		DisplayEventLog = True)
	
	Form.ErrorMessage = ErrorInfo;
	Form.Items.DecorationNavigateToEventLog.Visible = DisplayEventLog;
	Form.Items.DecorationTechnicalSupport.Visible = Form.CanContactTechnicalSupport;
	Form.Items.GroupPages.CurrentPage = Form.Items.UpdateResultsGroup;
	Form.Items.ResultDetailsDecoration.Title = ErrorInfo;
	Form.Items.PictureResultDecoration.Picture = ?(
		Error,
		PictureLib.Error32,
		PictureLib.Warning32);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSuccessfulCompletionDisplay(Form)
	
	Form.Items.GroupPages.CurrentPage = Form.Items.UpdateResultsGroup;
	Form.Items.PictureResultDecoration.Picture = PictureLib.Success32;
	Form.Items.ResultDetailsDecoration.Title = NStr("ru = 'Обновление классификаторов успешно завершено.';
																|en = 'Classifiers are successfully updated.';");
	Form.Items.DecorationTechnicalSupport.Visible = False;
	Form.Items.DecorationNavigateToEventLog.Visible = False;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ClassifiersDataVersion.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ClassifiersDataDescription.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ClassifiersDataMark.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ClassifiersData.UpdateRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue(
		"TextColor",
		Metadata.StyleItems.InactiveLineColor.Value);
	
EndProcedure

&AtClient
Procedure SetCheck(Value)
	
	For Each ClassifierRow In ClassifiersData Do
		ClassifierRow.Mark = Value;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function OnlineUpdateMode()
	
	Return 0;
	
EndFunction

&AtClientAtServerNoContext
Function NoUpdateRequired(Description)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = '%1 (обновление не требуется)';
			|en = '%1 (no update is required)';"),
		Description);
	
EndFunction

&AtServer
Function PrepareParametersOfGetInformationOnUpdates()
	
	ClassifiersData.Clear();
	
	ClassifiersVersions = ClassifiersOperations.ClassifiersDataForInteractiveUpdate();
	IDs = New Array;
	
	For Each ClassifierDetails In ClassifiersVersions Do
		IDs.Add(ClassifierDetails.Id);
	EndDo;
	
	ReceivingParameters = New Structure;
	ReceivingParameters.Insert("ClassifiersVersions", ClassifiersVersions);
	ReceivingParameters.Insert("IDs",        IDs);
	
	Return ReceivingParameters;
	
EndFunction

#EndRegion
