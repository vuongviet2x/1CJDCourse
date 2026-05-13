///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DigitalSignatureInternal.SetPasswordEntryNote(ThisObject,
		Items.EnterPasswordInDigitalSignatureApplication.Name);
	
	CloudSignatureCertificate = CloudSignatureInformation(Object.Application);
	FillApplicationsListServer();
	
	If Common.SubsystemExists("StandardSubsystems.DSSElectronicSignatureService")
		And DigitalSignatureInternal.UseCloudSignatureService() Then
		Items.Application.Title = NStr("ru = 'Приложение или сервис';
											|en = 'App or service';");
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.OnCreateAtServer(
			Object, OpenRequest);
		RequestFormName = "DataProcessor.ApplicationForNewQualifiedCertificateIssue.Form.Form";
		CanOpenRequest = True;
		If Not OpenRequest Then
			IssuedCertificates = ProcessingApplicationForNewQualifiedCertificateIssue.IssuedCertificates(Object.Ref);
		EndIf;
		If Not AccessRight("Insert", Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates) Then
		CommonClientServer.SetFormItemProperty(Items,
			"FormCopy", "Visible", False);
		EndIf;
	Else
		CommonClientServer.SetFormItemProperty(Items,
				"FormCopy", "Visible", False);
	EndIf;
	
	BuiltinCryptoprovider = DigitalSignatureInternal.BuiltinCryptoprovider();
	UpdateItemVisibilityEnterPasswordInElectronicSignatureProgram(ThisObject);
	
	HasCompanies = DigitalSignature.CommonSettings().IsCompanyUsed;
	Items.GroupInidividual.Visible = DigitalSignature.CommonSettings().IndividualUsed;
	OnCreateAtServerOnReadAtServer();
	
	If Items.FieldsAutoPopulatedFromCertificateData.Visible Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "CustomCertificate");
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not ValueIsFilled(Object.Ref) Then
		Cancel = True;
		StandardSubsystemsClient.SetFormStorageOption(ThisObject, True);
		AttachIdleHandler("IdleHandlerAddCertificate", 0.1, True);
		Return;
		
	ElsIf OpenRequest Then
		Cancel = True;
		StandardSubsystemsClient.SetFormStorageOption(ThisObject, True);
		AttachIdleHandler("IdleHandlerOpenApplication", 0.1, True);
		Return;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	CreateAListOfUsers();
	
	AttachIdleHandler("WaitHandlerShowCertificateStatus", 0.1, True);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = Common.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	If CertificateAddress <> Undefined Then
		OnCreateAtServerOnReadAtServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	WriteParameters.Insert("IsNew", Not ValueIsFilled(Object.Ref));
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	AdditionalParameters = DigitalSignatureInternalClient.ParametersNotificationWhenWritingCertificate();
	If WriteParameters.IsNew Then
		AdditionalParameters.IsNew = True;
	EndIf;
	
	Notify("Write_DigitalSignatureAndEncryptionKeysCertificates", AdditionalParameters, Object.Ref);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_DigitalSignatureAndEncryptionApplications" Or EventName = "DSSAccountEntry" Then
		FillApplicationsListServer();
		Return;
	EndIf;

	If EventName = "Write_DigitalSignatureAndEncryptionKeysCertificates" And Source = Object.Ref Then
		If Not ValueIsFilled(Parameter) Then
			Return;
		EndIf;
		If Parameter.Revoked Then
			RefreshVisibilityWarnings();
		EndIf;
		If Parameter.Is_Specified Then
			AttachIdleHandler("WaitHandlerShowCertificateStatus", 0.1, True);
		EndIf;
		Return;
	EndIf;
	
	If EventName = "Write_ConstantsSet" And Source = "AllowedNonAccreditedUS" Then
		
		RefreshVisibilityWarnings();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// Checking description for uniqueness.
	If Not Items.Description.ReadOnly Then
		DigitalSignatureInternal.CheckPresentationUniqueness(
			Object.Description, Object.Ref, "Object.Description", Cancel);
	EndIf;
	
	If TypeOf(AttributesParameters) <> Type("Structure") Then
		Return;
	EndIf;
	
	For Each KeyAndValue In AttributesParameters Do
		AttributeName = KeyAndValue.Key;
		Properties     = KeyAndValue.Value;
		
		If Not Properties.FillChecking
		 Or ValueIsFilled(Object[AttributeName]) Then
			
			Continue;
		EndIf;
		
		Item = Items[AttributeName]; // FormField
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Поле %1 не заполнено.';
																						|en = 'The ""%1"" field is not filled in.';"),
			Item.Title);
		
		Common.MessageToUser(MessageText,, AttributeName,, Cancel);
	EndDo;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ApplicationOnChange(Item)
	
	CloudSignatureCertificate = CloudSignatureInformation(Object.Application);
	UpdateItemVisibilityEnterPasswordInElectronicSignatureProgram(ThisObject);
	
EndProcedure

&AtClient
Procedure UsersStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenTheListOfUsers(False);
	
EndProcedure

&AtClient
Procedure UsersOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenTheListOfUsers(True);
	
EndProcedure

&AtClient
Procedure RemindAboutReissueOnChange(Item)
	
	DigitalSignatureInternalClient.EditMarkONReminder(Object.Ref, RemindAboutReissue, ThisObject);
	
EndProcedure

&AtClient
Procedure DecorationReissuedURLProcessing(Item, FormattedStringURL, StandardProcessing)
		
	StandardProcessing = False;
	If IssuedCertificates.Count() = 1 Then
		OpenCertificateAfterSelectionFromList(IssuedCertificates[0], Undefined);
	Else	
		NotifyDescription = New NotifyDescription("OpenCertificateAfterSelectionFromList", ThisObject, Item);
		ShowChooseFromList(NotifyDescription, IssuedCertificates);
	EndIf;
	
EndProcedure

&AtClient
Procedure WarningURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	AdditionalParameters = New Structure("Certificate", Object.Ref);
	DigitalSignatureInternalClient.HandleNaviLinkClassifier(
		Item, FormattedStringURL, StandardProcessing, AdditionalParameters);
		
EndProcedure

&AtClient
Procedure SigningAllowedOnChange(Item)
	
	CommonServerCall.CommonSettingsStorageSave(
			Object.Ref, "AllowSigning", SigningAllowed);
	
EndProcedure

&AtClient
Async Procedure ApplicationOpening(Item, StandardProcessing)
	
	If ValueIsFilled(Object.Application) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	AppAuto = Undefined;
	ErrorAtClient = "";
	ErrorAtServer = "";
	
	CertificateApplicationResult = Await DigitalSignatureInternalClient.AppForCertificate(CertificateAddress, Undefined, Undefined, True);
	If CertificateApplicationResult.Application = Undefined Then
		ErrorAtClient = DigitalSignatureInternalClientServer.ErrorTextFailedToDefineApp(
			CertificateApplicationResult.Error);
		If DigitalSignatureClient.CommonSettings().VerifyDigitalSignaturesOnTheServer 
			Or DigitalSignatureClient.CommonSettings().GenerateDigitalSignaturesAtServer  Then
			AppAuto = AppForCertificate(CertificateAddress, ErrorAtServer);
		EndIf;
	Else
		AppAuto = CertificateApplicationResult.Application;
	EndIf;
	
	If AppAuto <> Undefined Then
		If ValueIsFilled(AppAuto.Ref) Then
			ShowValue(,AppAuto.Ref);
		Else
			DigitalSignatureInternalClient.OpenAppForm(AppAuto, ThisObject);
		EndIf;
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("WarningTitle", NStr("ru = 'Не удалось определить программу автоматически';
															|en = 'Cannot determine an application automatically';"));
	FormParameters.Insert("ErrorTextClient", ErrorAtClient);
	FormParameters.Insert("ErrorTextServer", ErrorAtServer);
	
	DigitalSignatureInternalClient.OpenExtendedErrorPresentationForm(FormParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShowAutoPopulatedAttributes(Command)
	
	Show = Not Items.FormShowAutoPopulatedAttributes.Check;
	
	Items.FormShowAutoPopulatedAttributes.Check = Show;
	Items.FieldsAutoPopulatedFromCertificateData.Visible = Show;
	
	If HasCompanies Then
		Items.Organization.Visible = Show;
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowCertificateData(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("OpeningFromCertificateItemForm");
	FormParameters.Insert("CertificateAddress", CertificateAddress);
	
	DigitalSignatureInternalClient.OpenCertificateForm(FormParameters, ThisObject);

EndProcedure

&AtClient
Procedure ShowCertificateApplication(Command)
	
	If CanOpenRequest Then
		FormParameters = New Structure;
		FormParameters.Insert("CertificateReference", Object.Ref);
		OpenForm(RequestFormName, FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckCertificate(Command)
	
	If Not ValueIsFilled(Object.Ref) Then
		ShowMessageBox(, NStr("ru = 'Сертификат еще не записан.';
										|en = 'Certificate has not been recorded yet.';"));
		Return;
	EndIf;
	
	If Modified And Not Write() Then
		Return;
	EndIf;
	
	DigitalSignatureClient.CheckCatalogCertificate(Object.Ref,
		New Structure("NoConfirmation, SignatureType", True, SignatureTypeByDefault()));
	
EndProcedure

&AtClient
Procedure SaveCertificateDataToFile(Command)
	
	DigitalSignatureInternalClient.SaveCertificate(Undefined, CertificateAddress);
	
EndProcedure

&AtClient
Procedure CertificateRevoked(Command)
	
	If Not Object.Revoked Then
		TheDescriptionIsAsFollows = New NotifyDescription("AfterAnsweringQuestionCertificateRevoked", ThisObject);
		ShowQueryBox(TheDescriptionIsAsFollows, NStr("ru = 'Сертификат будет помечен как отозванный, его нельзя будет использовать для подписи. 
		|Рекомендуется устанавливать этот признак, когда подано, но еще не исполнено заявление на отзыв сертификата.
		|Продолжить?';
		|en = 'The certificate will be marked as revoked, and you will not be able to use it for signing.
		|Select this flag when the certificate revocation application is submitted but not fulfilled.
		|Continue?';"), QuestionDialogMode.YesNo);
	Else
		TheDescriptionIsAsFollows = New NotifyDescription("AfterAnsweringQuestionCertificateRevoked", ThisObject);
		ShowQueryBox(TheDescriptionIsAsFollows, NStr("ru = 'Если сертификат отозван в удостоверяющем центре, сделать подпись таким сертификатом будет невозможно, даже если снять отметку в приложении.
		|Продолжить?';
		|en = 'If a certificate is revoked by the certificate authority, you will not be able to use it for signing even after clearing the checkmark.
		|Continue?';"), QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure Copy(Command)
	
	CreationParameters = New Structure;
	CreationParameters.Insert("CreateRequest", True);
	CreationParameters.Insert("CertificateBasis", Object.Ref);
	
	DigitalSignatureInternalClient.ToAddCertificate(CreationParameters);
	
EndProcedure

&AtClient
Procedure ResetPassword(Command)
	
	DigitalSignatureInternalClient.ResetThePasswordInMemory(Object.Ref);
	
EndProcedure

&AtClient
Procedure ChangePIN(Command)
	
	TheDSSCryptographyServiceModuleClientServer = CommonClient.CommonModule("DSSCryptographyServiceClientServer");
	TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
	
	FingerprintRepresentation = TheDSSCryptographyServiceModuleClientServer.TransformFingerprint(Object.Thumbprint);
	TheDescriptionIsAsFollows = New NotifyDescription("AfterChangingThePINCode", ThisObject);
	TheDSSCryptographyServiceModuleClient.ChangeCertificatePin(
			TheDescriptionIsAsFollows,
			Object.Application,
			New Structure("Thumbprint", FingerprintRepresentation));
	
EndProcedure

&AtClient
Procedure EditFirstNameAndPatronymic(Command)
	
	OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.EditFirstNameAndPatronymic",
		New Structure("Name, MiddleName", Object.Name, Object.MiddleName), ThisObject,,,,
		New NotifyDescription("EditFirstNameAndPatronymicContinuation", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PickIndividual(Command)
	
	DigitalSignatureInternalClient.PickIndividualForCertificate(ThisObject, Object.IssuedTo, Object.Individual);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
    ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = CommonClient.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	EndIf;
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure OnCreateAtServerOnReadAtServer()
	
	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.OnCreateAtServerOnReadAtServer(
			Object, Items);
	EndIf;
	
	CertificateBinaryData = Common.ObjectAttributeValue(
		Object.Ref, "CertificateData").Get();
	
	If TypeOf(CertificateBinaryData) = Type("BinaryData") Then
		
		Certificate = New CryptoCertificate(CertificateBinaryData);
		If ValueIsFilled(CertificateAddress) Then
			PutToTempStorage(CertificateBinaryData, CertificateAddress);
		Else
			CertificateAddress = PutToTempStorage(CertificateBinaryData, UUID);
		EndIf;
			
		DigitalSignatureInternalClientServer.FillCertificateDataDetails(CertificateDataDetails,
			DigitalSignature.CertificateProperties(Certificate));
		RefreshVisibilityWarnings(Certificate);
		
	Else
		CertificateAddress = "";
		Items.ShowCertificateData.Enabled  = False;
		Items.GroupWarning.Visible = False;
		Items.FormCheckCertificate.Enabled = ValueIsFilled(CertificateBinaryData);
		Items.FormSaveCertificateDataToFile.Enabled = False;
		Items.FieldsAutoPopulatedFromCertificateData.Visible = True;
		Items.FormShowAutoPopulatedAttributes.Check = True;
		If ValueIsFilled(CertificateBinaryData) Then
			// Supporting display of main properties of non-standard certificates (iBank2 system).
			DigitalSignatureInternalClientServer.FillCertificateDataDetails(CertificateDataDetails, Object);
		EndIf;
	EndIf;
	
	Items.FormCertificateRevoked.Check = Object.Revoked;

	If Not Users.IsFullUser() Then
		ThisIsTheAuthor = Object.Added = Users.CurrentUser();
		CertificateIsAvailable = TheCertificateIsAvailableToTheUser();
		
		If Not ThisIsTheAuthor And Not CertificateIsAvailable Then
			// Standard users can change only their own certificates.
			ReadOnly = True;
			Items.EditFirstNameAndPatronymic.Visible = False;
			
		Else
			// Standard users cannot change access rights.
			Items.Individual.ReadOnly       =  ValueIsFilled(Object.Individual);
			Items.PickIndividual.Enabled =  Not Items.Individual.ReadOnly;
			If Not ThisIsTheAuthor Then
				// An ordinary user cannot change the "User" attribute
				// unless the user added the certificate.
				Items.Users.ReadOnly = True;
				Items.Users.OpenButton = True;
			EndIf;
		EndIf;
	EndIf;
	
	HasCompanies = DigitalSignature.CommonSettings().IsCompanyUsed;
	Items.Organization.Visible = HasCompanies;
	
	If Not ValueIsFilled(CertificateAddress) Then
		Return; // Certificate = Undefined.
	EndIf;
	
	EditFirstNameAndPatronymic = False;
	SubjectProperties = DigitalSignature.CertificateSubjectProperties(Certificate);
	If SubjectProperties.LastName <> Undefined Then
		Items.LastName.ReadOnly = True;
	EndIf;
	If SubjectProperties.Name <> Undefined Then
		If StrFind(SubjectProperties.Name, " ") <> 0 Then
			EditFirstNameAndPatronymic = True;
		EndIf;
		Items.Name.ReadOnly = True;
	EndIf;
	If SubjectProperties.Property("MiddleName") And SubjectProperties.MiddleName <> Undefined Then
		If StrFind(SubjectProperties.MiddleName, " ") <> 0 Then
			EditFirstNameAndPatronymic = True;
		EndIf;
		Items.MiddleName.ReadOnly = True;
	EndIf;
	If SubjectProperties.Organization <> Undefined Then
		Items.Firm.ReadOnly = True;
	EndIf;
	If SubjectProperties.Property("JobTitle") And SubjectProperties.JobTitle <> Undefined Then
		Items.JobTitle.ReadOnly = True;
	EndIf;
	
	AttributesParameters = Undefined;
	DigitalSignatureInternal.BeforeStartEditKeyCertificate(
		Object.Ref, Certificate, AttributesParameters);
	
	For Each KeyAndValue In AttributesParameters Do
		AttributeName = KeyAndValue.Key;
		Properties     = KeyAndValue.Value;
		
		If Not Properties.Visible Then
			Items[AttributeName].Visible = False;
			
		ElsIf Properties.ReadOnly Then
			Items[AttributeName].ReadOnly = True
		EndIf;
		If Properties.FillChecking Then
			Items[AttributeName].AutoMarkIncomplete = True;
		EndIf;
	EndDo;
	
	Items.FieldsAutoPopulatedFromCertificateData.Visible =
		    Not Items.LastName.ReadOnly   And Not ValueIsFilled(Object.LastName)
		Or Not Items.Name.ReadOnly       And Not ValueIsFilled(Object.Name)
		Or Not Items.MiddleName.ReadOnly  And Not ValueIsFilled(Object.MiddleName)
		Or EditFirstNameAndPatronymic And Items.EditFirstNameAndPatronymic.Visible;
	
	Items.FormShowAutoPopulatedAttributes.Check =
		Items.FieldsAutoPopulatedFromCertificateData.Visible;
	
	If Not OpenRequest Then
		InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
		Items.CertificateStatusGroup.Visible = False;
		CertificatesInPersonalStorage = New ValueList;
		DigitalSignatureInternal.AddListofCertificatesInPersonalStorageOnServer(CertificatesInPersonalStorage);
		If CertificatesInPersonalStorage.FindByValue(Object.Thumbprint) <> Undefined Then
			EnableCertificateStatusVisibility(ThisObject, CurrentUniversalDate());
		EndIf; 
		If DigitalSignature.ManageAlertsCertificates() Then
			Items.RemindAboutReissue.Visible = True;
			RemindAboutReissue = Not InformationRegisters.CertificateUsersNotifications.UserAlerted(Object.Ref);
		Else
			Items.RemindAboutReissue.Visible = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure IdleHandlerAddCertificate()
	
	StandardSubsystemsClient.SetFormStorageOption(ThisObject, False);
	
	CreationParameters = New Structure;
	CreationParameters.Insert("ToPersonalList", True);
	CreationParameters.Insert("Organization", Object.Organization);
	CreationParameters.Insert("HideApplication", Not CanOpenRequest);
	
	DigitalSignatureInternalClient.ToAddCertificate(CreationParameters);
	
EndProcedure

&AtClient
Procedure IdleHandlerOpenApplication()
	
	StandardSubsystemsClient.SetFormStorageOption(ThisObject, False);
	
	If CanOpenRequest Then
		FormParameters = New Structure;
		FormParameters.Insert("CertificateReference", Object.Ref);
		Notification = New NotifyDescription("NotificationClosedStatements", ThisObject);
		OpenForm(RequestFormName, FormParameters,,,,, Notification);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationClosedStatements(Result, AdditionalParameters) Export
	
	If Result <> Undefined And Result.Added And Not IsOpen() Then
		OpenRequest = False;
		StandardSubsystemsClient.SetFormStorageOption(ThisObject, True);
		OnCreateAtServerOnReadAtServer();
		Open();
	EndIf;
	
EndProcedure

&AtClient
Procedure WaitHandlerShowCertificateStatus()
	
	If Items.CertificateStatusGroup.Visible = True Then
		Return;
	EndIf;
	
	Notification = New NotifyDescription(
		"VisibilityCertificateStatusAfterGettingCertificatesInPersonalStorage", ThisObject);
	DigitalSignatureInternalClient.GetCertificatesPropertiesAtClient(
		Notification, True, True, True);
	
EndProcedure

&AtClient
Procedure OpenCertificateAfterSelectionFromList(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.ObjectForm", 
			New Structure("Key", Result.Value));
	EndIf;
		
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateItemVisibilityEnterPasswordInElectronicSignatureProgram(Form)
	
	Form.Items.EnterPasswordInDigitalSignatureApplication.Visible = Not Form.CloudSignatureCertificate.CloudSignature
		And Not (ValueIsFilled(Form.BuiltinCryptoprovider) And Form.Object.Application = Form.BuiltinCryptoprovider);

	Form.Items.FormChangePIN.Visible = Form.CloudSignatureCertificate.CloudSignature;
	
EndProcedure

&AtServer
Procedure RefreshVisibilityWarnings(Val CryptoCertificate = Undefined)
	
	If Object.Revoked Then
		
		Items.GroupWarning.Visible = True;
		Items.Warning.Title = 
			NStr("ru = 'Сертификат помечен в приложении как отозванный. Подписи, сделанные таким сертификатом верны, если содержат метку доверенного времени, добавленную ранее даты отзыва сертификата. Чтобы узнать причину и дату отзыва, обратитесь в удостоверяющий центр, выдавший сертификат.';
				|en = 'The certificate is marked as revoked: signatures created with it are valid if their timestamp date is earlier than the revocation date. To find out the revocation reason and date, contact the issuing authority.';");
		Items.SigningAllowed.Visible = False;
	
	ElsIf Object.ValidBefore > CurrentSessionDate() Then
	
		If ValueIsFilled(CertificateAddress) Then
			
			If CryptoCertificate = Undefined Then
				CryptoCertificate = New CryptoCertificate(GetFromTempStorage(CertificateAddress));
			EndIf;
			
			ResultofCertificateAuthorityVerification = DigitalSignatureInternal.ResultofCertificateAuthorityVerification(
					CryptoCertificate);
			
			DataWarnings = ResultofCertificateAuthorityVerification.Warning;
			
			If ResultofCertificateAuthorityVerification.Valid_SSLyf
				And Not ValueIsFilled(DataWarnings.ErrorText) Then
					
				Items.GroupWarning.Visible = ValueIsFilled(DataWarnings.AdditionalInfo);
				Items.Warning.Title = DataWarnings.AdditionalInfo;
				Items.SigningAllowed.Visible = False;
				
			Else
				Items.GroupWarning.Visible = True;
				RowsArray = New Array;
				RowsArray.Add(DataWarnings.ErrorText);
				If ValueIsFilled(DataWarnings.Cause) Then
					RowsArray.Add(Chars.LF);
					RowsArray.Add(DataWarnings.Cause);
				EndIf;
				If ValueIsFilled(DataWarnings.Decision) Then
					RowsArray.Add(Chars.LF);
					RowsArray.Add(DataWarnings.Decision);
				EndIf;
				Items.Warning.Title = New FormattedString(RowsArray);
				
				If DataWarnings.AllowSigning
					And DigitalSignature.AddEditDigitalSignatures() Then
					
					SettingAllowSigning = Common.CommonSettingsStorageLoad(
						Object.Ref, "AllowSigning", Undefined);
					Items.SigningAllowed.Visible = True;
					SigningAllowed = SettingAllowSigning;
				Else
					Items.SigningAllowed.Visible = False;
				EndIf;
			EndIf;
			
		Else
			Items.GroupWarning.Visible = False;
		EndIf;
	
	Else
		Items.GroupWarning.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateAListOfUsers()
	
	UsersCount = Object.Users.Count();
	If UsersCount = 1 Then
		PresentationUsers = TrimAll(Object.Users[0].User);
	ElsIf UsersCount > 1 Then
		PresentationUsers = DigitalSignatureInternalClientServer.UsersCertificateString(
			Object.Users[0].User, Object.Users[1].User, UsersCount);
	ElsIf ValueIsFilled(Object.User) Then
		PresentationUsers = TrimAll(Object.User);
	Else
		PresentationUsers = NStr("ru = 'Не указаны';
											|en = 'Not specified';");
	EndIf;
	
EndProcedure	

&AtClient
Procedure UsersListCompletion(SelectionResult, AdditionalParameters) Export
	
	If SelectionResult <> Undefined And TypeOf(SelectionResult) = Type("Structure") Then
		Object.Users.Clear();
		Object.User = SelectionResult.User;
		CommonClientServer.SupplementTableFromArray(Object.Users, SelectionResult.Users, "User");
		CreateAListOfUsers();
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure VisibilityCertificateStatusAfterGettingCertificatesInPersonalStorage(Result, AdditionalParameters) Export
	
	For Each KeyAndValue In Result.CertificatesPropertiesAtClient Do
		If KeyAndValue.Key = Object.Thumbprint Then
			EnableCertificateStatusVisibility(ThisObject, CommonClient.UniversalDate());
			Return;
		EndIf;	
	EndDo;
		
EndProcedure

&AtClientAtServerNoContext
Procedure EnableCertificateStatusVisibility(Form, CurrentDate)
	
	Form.Items.CertificateStatusGroup.Visible = True;
	
	If Form.Object.ValidBefore < CurrentDate Then
		Form.Items.CertificateImage.Picture = PictureLib.CertificateOverdue;
		Form.Items.CertificateStatus.Title = NStr("ru = 'Сертификат просрочен';
															|en = 'Certificate is expired';");
	ElsIf	Form.Object.ValidBefore <= CurrentDate + 30*24*60*60 Then
		Form.Items.CertificateImage.Picture = PictureLib.CertificateExpiring;
		Form.Items.CertificateStatus.Title = NStr("ru = 'Срок действия сертификата скоро закончится';
															|en = 'Certificate is expiring';");
	Else
		Form.Items.CertificateImage.Picture = PictureLib.CertificatePersonalStorage;
		Form.Items.CertificateStatus.Title = NStr("ru = 'Сертификат в личном хранилище';
															|en = 'Certificate in Personal store';");
	EndIf;
		
	If Form.IssuedCertificates.Count() > 0 Then
		Form.Items.DecorationReissued.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterChangingThePINCode(CallResult, AdditionalParameters) Export
	
	TheDSSCryptographyServiceModuleClientServer = CommonClient.CommonModule("DSSCryptographyServiceClientServer");
	TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
	
	If CallResult.Completed2 Then
		ShowMessageBox(Undefined, 
				NStr("ru = 'Смена пин-кода выполнена успешно.';
					|en = 'PIN is successfully changed.';", CommonClient.DefaultLanguageCode()), 30);
				
	ElsIf Not TheDSSCryptographyServiceModuleClientServer.ThisIsFailureError(CallResult.ErrorStatus) Then
		TheDSSCryptographyServiceModuleClient.OutputError(Undefined, CallResult.ErrorStatus);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterAnsweringQuestionCertificateRevoked(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Object.Revoked = Not Object.Revoked;
	Items.FormCertificateRevoked.Check = Object.Revoked;
	RefreshVisibilityWarnings();
	
EndProcedure

&AtClient
Procedure OpenTheListOfUsers(ViewMode)
	
	UsersArray = New Array;
	For Each TableRow In Object.Users Do
		UsersArray.Add(TableRow.User);
	EndDo;	
	
	CompletionNotification = New NotifyDescription("UsersListCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("User", Object.User);
	FormParameters.Insert("Users", UsersArray);
	FormParameters.Insert("ViewMode", ViewMode Or ReadOnly);
	
	OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.UsersList", 
			FormParameters, ThisObject, , , , CompletionNotification);
			
EndProcedure

&AtServer
Function TheCertificateIsAvailableToTheUser()
	
	If Not AccessRight("Update", Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates) Then
		Return False;
	EndIf;
	
	CurUser = Users.CurrentUser();
	
	FoundTheLines = Object.Users.FindRows(New Structure("User", CurUser));
	Result = FoundTheLines.Count() > 0 Or Object.User = CurUser;
		
	Return Result;
	
EndFunction

&AtServer
Procedure FillApplicationsListServer()
	
	ChoiceList = Items.Application.ChoiceList;
	ChoiceList.Clear();
	TheWholeList = FillApplicationsList(Object.Application);
	
	For Each ListLine In TheWholeList Do
		NewRow = ChoiceList.Add(ListLine.Value);
		NewRow.Picture = ListLine.Picture;
		NewRow.Presentation = ListLine.Presentation;
	EndDo;
	
EndProcedure

&AtServerNoContext
Function CloudSignatureInformation(CurrentApplication)
	
	Result = New Structure();
	Result.Insert("CloudSignature", False);
	Result.Insert("ChangePINCode", False);
	
	If ValueIsFilled(CurrentApplication) 
		And TypeOf(CurrentApplication) = DigitalSignatureInternal.ServiceProgramTypeSignatures() Then
		TheDSSCryptographyServiceModuleInternalServerCall = Common.CommonModule("DSSCryptographyServiceInternalServerCall");
		AccountData = TheDSSCryptographyServiceModuleInternalServerCall.GetUserSettings(CurrentApplication);
		Result.CloudSignature = True;
		Result.ChangePINCode = AccountData.Policy.PINCodeMode <> "Prohibited";
	EndIf;
	
	Return Result;
	
EndFunction	

&AtServerNoContext
Function FillApplicationsList(Val SelectedProgram)

	UseDigitalSignatureSaaS = DigitalSignatureInternal.UseDigitalSignatureSaaS();	
	AddPicture = DigitalSignatureInternal.UseCloudSignatureService() Or UseDigitalSignatureSaaS;
	ComputerPicture = New Picture;
	ServicePicture = New Picture;
	PictureOfACloud = New Picture;
	If DigitalSignatureInternal.UseCloudSignatureService() Then
		TheDSSCryptographyServiceModule = Common.CommonModule("DSSCryptographyService");
		ComputerPicture = TheDSSCryptographyServiceModule.GetPictureOfSubsystem("ComputerClient");
		ServicePicture = TheDSSCryptographyServiceModule.GetPictureOfSubsystem("ServiceSignature");
		PictureOfACloud = TheDSSCryptographyServiceModule.GetPictureOfSubsystem("SignatureCloud");
	EndIf;
	
	Result = New ValueList;
	Result.Add(Catalogs.DigitalSignatureAndEncryptionApplications.EmptyRef(), NStr("ru = 'По умолчанию';
																								|en = 'Default';"));
	
	QueryText = 
	"SELECT
	|	DigitalSignatureAndEncryptionApplications.Ref AS Ref,
	|	DigitalSignatureAndEncryptionApplications.IsBuiltInCryptoProvider AS IsBuiltInCryptoProvider,
	|	DigitalSignatureAndEncryptionApplications.ApplicationType AS ApplicationType,
	|	FALSE AS CloudSignature
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS DigitalSignatureAndEncryptionApplications";
	
	Query = New Query(QueryText);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If Not UseDigitalSignatureSaaS And Selection.IsBuiltInCryptoProvider Then
			Continue;
		EndIf;
		NewRow = Result.Add(Selection.Ref);
		If Selection.IsBuiltInCryptoProvider And AddPicture Then
			NewRow.Picture = ServicePicture;
		ElsIf AddPicture Then
			NewRow.Picture = ComputerPicture;
		EndIf;	
	EndDo;
	
	If DigitalSignatureInternal.UseCloudSignatureService() Then
		TheDSSCryptographyServiceModuleInternal = Common.CommonModule("DSSCryptographyServiceInternal");
		TheDSSCryptographyServiceModule = Common.CommonModule("DSSCryptographyService");
		ArrayOfAccounts = TheDSSCryptographyServiceModuleInternal.GetAllAccounts();
		
		For Each ArrayRow In ArrayOfAccounts Do
			NewRow = Result.Add(ArrayRow.Ref);
			If AddPicture Then
				NewRow.Picture = PictureOfACloud;
			EndIf;	
		EndDo;
			
	EndIf;	
	
	If Result.FindByValue(SelectedProgram) = Undefined Then
		ApplicationPresentation = ?(ValueIsFilled(SelectedProgram),
								TrimL(SelectedProgram),
								NStr("ru = 'По умолчанию';
									|en = 'Default';"));
		Result.Add(SelectedProgram, ApplicationPresentation);
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure EditFirstNameAndPatronymicContinuation(ClosingResult, AdditionalParameters) Export
	
	If TypeOf(ClosingResult) = Type("Structure") Then
		
		Object.Name = ClosingResult.Name;
		Object.MiddleName = ClosingResult.MiddleName;
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCloseIndividualChoiceForm(Value, Var_Parameters) Export

	If Value = Undefined Then
		Return;
	EndIf;
	
	Object.Individual = Value;

EndProcedure

&AtServerNoContext
Function AppForCertificate(CertificateAddress, ErrorAtServer)
	
	CertificateApplicationResult = DigitalSignatureInternal.AppForCertificate(CertificateAddress);
	
	If CertificateApplicationResult.Application = Undefined Then
		ErrorAtServer = DigitalSignatureInternalClientServer.ErrorTextFailedToDefineApp(
			CertificateApplicationResult.Error);
		Return Undefined;
	EndIf;
	
	Return CertificateApplicationResult.Application;
	
EndFunction

&AtServerNoContext
Function SignatureTypeByDefault()
	
	Return Constants.CryptoSignatureTypeDefault.Get();
	
EndFunction

#EndRegion
