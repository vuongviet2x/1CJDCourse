///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Variables

&AtClient
Var ClientParameters Export;

&AtClient
Var DataDetails, ObjectForm, CurrentPresentationsList;

&AtClient
Var DataRepresentationRefreshed;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	AutoTitle = False;
	If Common.IsMobileClient() Then
		Title = NStr("ru = 'Добавление электронных подписей из файлов на устройстве';
						|en = 'Add digital signature from device''s files';");
		Items.SignaturesAdd.Title = NStr("ru = 'Выбрать файлы с устройства...';
													|en = 'Select files on disk…';");
	Else
		Title = NStr("ru = 'Добавление электронных подписей из файлов на компьютере';
						|en = 'Add digital signatures from device''s files';");
	EndIf;
	
	If ValueIsFilled(Parameters.DataTitle) Then
		Items.DataPresentation.Title = Parameters.DataTitle;
	Else
		Items.DataPresentation.TitleLocation = FormItemTitleLocation.None;
	EndIf;
	
	DataPresentation = Parameters.DataPresentation;
	Items.DataPresentation.Hyperlink = Parameters.DataPresentationCanOpen;
	
	If Not ValueIsFilled(DataPresentation) Then
		Items.DataPresentation.Visible = False;
	EndIf;
	
	If Not Parameters.ShowComment Then
		Items.Signatures.Header = False;
		Items.SignaturesComment.Visible = False;
	EndIf;
	
	CryptographyManagerOnServerErrorDescription = New Structure;
	
	If DigitalSignature.VerifyDigitalSignaturesOnTheServer()
	 Or DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		
		CreationParameters = DigitalSignatureInternal.CryptoManagerCreationParameters();
		CreationParameters.ErrorDescription = New Structure;
		
		DigitalSignatureInternal.CryptoManager("", CreationParameters);
		CryptographyManagerOnServerErrorDescription = CreationParameters.ErrorDescription;
		
	EndIf;
	
	DigitalSignatureLocalization.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ClientParameters = Undefined Then
		Cancel = True;
	Else
		DataDetails             = ClientParameters.DataDetails;
		ObjectForm               = ClientParameters.Form;
		CurrentPresentationsList = ClientParameters.CurrentPresentationsList;
		AttachIdleHandler("AfterOpen", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DataPresentationClick(Item, StandardProcessing)
	
	DigitalSignatureInternalClient.DataPresentationClick(ThisObject,
		Item, StandardProcessing, CurrentPresentationsList);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSignatures

&AtClient
Procedure SignaturesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	If DataRepresentationRefreshed = True Then
		SelectFiles(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure SignaturesPathToFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectFiles();
	
EndProcedure

&AtClient
Procedure SignaturesMachineReadableLetterOfAuthorityStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SignaturesMRLOAStartChoiceFollowUp(Item, ChoiceData);
	
EndProcedure

&AtClient
Async Procedure SignaturesMRLOAStartChoiceFollowUp(Item, ChoiceData)
	
	CurrentData = Items.Signatures.CurrentData;
	
	ChoiceList = New ValueList;
	DigitalSignatureClientLocalization.OnGetChoiceListWithMRLOAs(
		ThisObject, CurrentData, ChoiceList);
	
	If ChoiceList.Count() > 0 Then
		ChoiceList.Add("ChooseFromCatalog", NStr("ru = 'Выбрать из справочника...';
															|en = 'Select from catalog…';"));
		Result = Await ChooseFromListAsync(ChoiceList, Items.SignaturesMachineReadableLetterOfAuthority);
		If Result <> Undefined Then
			If Result.Value = "ChooseFromCatalog" Then
				MRLOASelectFromCatalog();
				Return;
			EndIf;
			
			CurrentData.MachineReadableLetterOfAuthority = Result.Presentation;
			CurrentData.PowerOfAttorneyNumber_ = Result.Value;
			AttachIdleHandler("SignaturesMRLOAOnChange", 0.1, True);
		EndIf;
	Else
		MRLOASelectFromCatalog();
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PickLOAs(Command)
	
	If DataDetails.Property("Object") And TypeOf(DataDetails.Object) <> Type("NotifyDescription") Then
		FillMRLOAs(DataDetails.Object);
	Else
		FillMRLOAs();
	EndIf;
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	If Signatures.Count() = 0 Then
		ShowMessageBox(, NStr("ru = 'Не выбрано ни одного файла подписи';
										|en = 'No signature file is selected';"));
		Return;
	EndIf;
	
	ImportMRLOAs();
		
	If Not DataDetails.Property("Object") Then
		DataDetails.Insert("Signatures", SignaturesToBeAdded());
		Close(True);
		Return;
	EndIf;
	
	If TypeOf(DataDetails.Object) <> Type("NotifyDescription") Then
		ObjectVersion = Undefined;
		DataDetails.Property("ObjectVersion", ObjectVersion);
		Try
			SignaturesArray = AddSignature(DataDetails.Object, ObjectVersion);
		Except
			ErrorInfo = ErrorInfo();
			OKCompletion(New Structure("ErrorDescription", ErrorProcessing.BriefErrorDescription(ErrorInfo)));
			Return;
		EndTry;
		DataDetails.Insert("Signatures", SignaturesArray);
		NotifyChanged(DataDetails.Object);
	Else
		DataDetails.Insert("Signatures", SignaturesToBeAdded());
		
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("DataDetails", DataDetails);
		ExecutionParameters.Insert("Notification", New NotifyDescription("OKCompletion", ThisObject));
		
		Try
			ExecuteNotifyProcessing(DataDetails.Object, ExecutionParameters);
			Return;
		Except
			ErrorInfo = ErrorInfo();
			OKCompletion(New Structure("ErrorDescription", ErrorProcessing.BriefErrorDescription(ErrorInfo)));
			Return;
		EndTry;
	EndIf;
	
	OKCompletion(New Structure);
	
EndProcedure

// Continues the OK procedure.
&AtClient
Procedure OKCompletion(Result, Context = Undefined) Export
	
	If Result.Property("ErrorDescription") Then
		DataDetails.Delete("Signatures");
		
		Error = New Structure("ErrorDescription",
			NStr("ru = 'Не удалось записать подпись по причине:';
				|en = 'Cannot save the signature due to:';") + Chars.LF + Result.ErrorDescription);
			
		DigitalSignatureInternalClient.ShowApplicationCallError(
			NStr("ru = 'Не удалось добавить электронную подпись из файла';
				|en = 'Cannot add a digital signature from the file';"), "", Error, New Structure);
		Return;
	EndIf;
	
	If ValueIsFilled(DataPresentation) Then
		DigitalSignatureClient.ObjectSigningInfo(
			DigitalSignatureInternalClient.FullDataPresentation(ThisObject),, True);
	EndIf;
	
	Close(True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterOpen()
	
	DataRepresentationRefreshed = True;
	SelectFiles(True);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SignaturesPathToFile.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Signatures.PathToFile");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

&AtClient
Procedure SelectFiles(MultipleChoice = False)
	
	ErrorOnLOAsImport = "";
	LettersOfAuthority.Clear();
	
	Context = New Structure;
	Context.Insert("AddNewRows", MultipleChoice);
	
	Notification = New NotifyDescription("SelectFilesAfterPutFiles", ThisObject, Context);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	
	If MultipleChoice Then
		ImportParameters.Dialog.Title = NStr("ru = 'Выберите файлы электронной подписи';
													|en = 'Select digital signature files';");
	Else
		ImportParameters.Dialog.Title = NStr("ru = 'Выберите файл электронной подписи';
													|en = 'Select a digital signature file';");
	EndIf;
	ImportParameters.Dialog.Multiselect = MultipleChoice;
	
	FilterForSelectingSignatures = NStr("ru = 'Файлы подписи (*.p7s, *.sig%1)|*.p7s;*.sig%2';
									|en = 'SIgnature files (*.p7s, *.sig%1)|*.p7s;*.sig%2';");
	DigitalSignatureClientLocalization.OnGetFilterForSelectingSignatures(FilterForSelectingSignatures);
		
	SignatureFilesExtension = DigitalSignatureClient.PersonalSettings().SignatureFilesExtension;
	If StrFind(FilterForSelectingSignatures, SignatureFilesExtension) = 0 Then
		FilterForSelectingSignatures= StringFunctionsClientServer.SubstituteParametersToString(FilterForSelectingSignatures,
			", *." + SignatureFilesExtension, ";*." + SignatureFilesExtension);
	Else		
		FilterForSelectingSignatures= StringFunctionsClientServer.SubstituteParametersToString(FilterForSelectingSignatures, "", "");
	EndIf;
	
	ImportParameters.Dialog.Filter = FilterForSelectingSignatures;
	ImportParameters.Dialog.Filter = ImportParameters.Dialog.Filter + "|" + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Все файлы (%1)|%1';
																																			|en = 'All files (%1)|%1';"), GetAllFilesMask());
	
	If Not MultipleChoice Then
		ImportParameters.Dialog.FullFileName = Items.Signatures.CurrentData.PathToFile;
	EndIf;
	
	FileSystemClient.ImportFiles(Notification, ImportParameters);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure SelectFilesAfterPutFiles(PlacedFiles, Context) Export
	
	If PlacedFiles = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(PlacedFiles) = Type("File") Then
		PlacedFiles = CommonClientServer.ValueInArray(PlacedFiles);
	EndIf;
		
	Result = AddRowsOnServer(PlacedFiles, Context.AddNewRows);
	
	Context.Insert("PlacedFiles", PlacedFiles);
	Context.Insert("DataToValidateSignature", Undefined);
	Context.Insert("SignaturesAdditionResult", Result);
	Context.Insert("OtherFiles", Result);
	Context.Insert("Errors", New Structure("ErrorsAtClient, ErrorsAtServer", New Map, New Map));
	Context.Insert("IndexOf", -1);
	SelectFilesLoopStart(Context);
	
EndProcedure

&AtClient
Procedure SelectFilesLoopStart(Context)
	
	If Context.PlacedFiles.Count() <= Context.IndexOf + 1 Then
		SelectFilesAfterLoop(Context);
		Return;
	EndIf;
	
	Context.IndexOf = Context.IndexOf + 1;
	
	FileThatWasPut = Context.PlacedFiles[Context.IndexOf];
	
	NameContent = CommonClientServer.ParseFullFileName(FileThatWasPut.Name);

	SignatureAdditionResult = Context.SignaturesAdditionResult.Get(FileThatWasPut.Name);
	
	If SignatureAdditionResult = Undefined Then
		SelectFilesLoopStart(Context);
		Return;
	EndIf;
	
	Context.Insert("SignatureAdditionResult", SignatureAdditionResult);
	
	If SignatureAdditionResult.Success Then
		SelectFileAfterAddRow(Context);
		Return;
	EndIf;
	
	CreationParameters = DigitalSignatureInternalClient.CryptoManagerCreationParameters();
	CreationParameters.SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(
			Context.SignatureAdditionResult.SignatureData);
	CreationParameters.ShowError = Undefined;

	DigitalSignatureInternalClient.CreateCryptoManager(
			New NotifyDescription("ChooseFileAfterCreateCryptoManager", ThisObject, Context), "",
		CreationParameters);
	
EndProcedure

&AtClient
Procedure SelectFilesAfterLoop(Context)
	
	FillMRLOAs();
	
	If Context.Errors.ErrorsAtClient.Count() = 0
		And Context.Errors.ErrorsAtServer.Count() = 0
		And ErrorOnLOAsImport = "" Then
		Return;
	EndIf;
	
	ErrorAtClient = DigitalSignatureInternalClientServer.NewErrorsDescription();
	ErrorAtClient.ErrorTitle = NStr("ru = 'Не удалось добавить файлы';
											|en = 'Couldn''t add files';");
	
	For Each KeyAndValue In Context.Errors.ErrorsAtClient Do
		
		ErrorProperties = DigitalSignatureInternalClientServer.NewErrorProperties();
		If ValueIsFilled(KeyAndValue.Value.AdditionalParameters) Then
			FillPropertyValues(ErrorProperties, KeyAndValue.Value.AdditionalParameters);
		EndIf;
		
		ErrorProperties.LongDesc = StrTemplate("%1:
			|%2", KeyAndValue.Key, StrConcat(KeyAndValue.Value.Files, Chars.LF));
		ErrorAtClient.Errors.Add(ErrorProperties);
		
	EndDo;
	
	ErrorAtServer = DigitalSignatureInternalClientServer.NewErrorsDescription();
	ErrorAtServer.ErrorTitle = NStr("ru = 'Не удалось добавить файлы';
											|en = 'Couldn''t add files';");
	
	If ErrorOnLOAsImport <> "" Then
		
		ErrorProperties = DigitalSignatureInternalClientServer.NewErrorProperties();
		ErrorProperties.LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось загрузить доверенности:
			|%1';
			|en = 'Couldn''t import the LOAs:
			|%1';"), ErrorOnLOAsImport);
		ErrorAtServer.Errors.Add(ErrorProperties);
	EndIf;
	
	For Each KeyAndValue In Context.Errors.ErrorsAtServer Do
		
		ErrorProperties = DigitalSignatureInternalClientServer.NewErrorProperties();
		If ValueIsFilled(KeyAndValue.Value.AdditionalParameters) Then
			FillPropertyValues(ErrorProperties, KeyAndValue.Value.AdditionalParameters);
		EndIf;
		
		ErrorProperties.LongDesc = StrTemplate("%1:
			|%2", KeyAndValue.Key, StrConcat(KeyAndValue.Value.Files, Chars.LF));
		ErrorAtServer.Errors.Add(ErrorProperties);
		
	EndDo;
	
	ShowError(ErrorAtClient, ErrorAtServer);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure ChooseFileAfterCreateCryptoManager(CryptoManager, Context) Export
	
	If TypeOf(CryptoManager) <> Type("CryptoManager") Then
		CreationParameters = DigitalSignatureInternalClient.CryptoManagerCreationParameters();  
		CreationParameters.ShowError = Undefined;
		DigitalSignatureInternalClient.ReadSignatureProperties(New NotifyDescription(
			"SelectFileAfterSignaturePropertiesRead", ThisObject, Context),
			Context.SignatureAdditionResult.SignatureData, True, False);
		Return;
	EndIf;
	
	Context.Insert("CryptoManager", CryptoManager);
	
	If DigitalSignatureClient.CommonSettings().AvailableAdvancedSignature Then
		CryptoManager.BeginGettingCryptoSignaturesContainer(New NotifyDescription(
			"SelectFileAfterGettingContainerSignature", ThisObject, Context,
			"SelectFileAfterReceivingSignatureContainerError", ThisObject), Context.SignatureAdditionResult.SignatureData);
		Return;
	EndIf;
	
	Context.Insert("SignatureParameters", Undefined);
	CryptoManager.BeginGettingCertificatesFromSignature(New NotifyDescription(
		"ChooseFilesAfterGetCertificatesFromSignature", ThisObject, Context,
		"SelectFileAfterGetCertificateFromSignatureError", ThisObject), Context.SignatureAdditionResult.SignatureData);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure SelectFileAfterSignaturePropertiesRead(Result, Context) Export
	
	If Result.Success = False Then
		AddError(New Structure("ErrorDescription", Result.ErrorText), Context);
		Return;
	EndIf;
	
	Context.Insert("CryptoManager", Undefined);
	Context.Insert("SignatureParameters", Result);
	
	If Result.Certificate <> Undefined Then
		
		CertificateProperties = New Structure;
		CertificateProperties.Insert("BinaryData", Result.Certificate);
		CertificateProperties.Insert("Thumbprint", Result.Thumbprint);
		CertificateProperties.Insert("IssuedTo", Result.CertificateOwner);
		
		SignatureProperties = DigitalSignatureInternalClientServer.SignatureProperties(Context.SignatureAdditionResult.SignatureData,
			CertificateProperties, "", UsersClient.AuthorizedUser(), Context.SignatureAdditionResult.FileName,
			Context.SignatureParameters, True);

		AddRow(ThisObject, Context.AddNewRows, SignatureProperties, Context.SignatureAdditionResult.FileName,
			Context.SignatureAdditionResult.SignaturePropertiesAddress);

		SelectFileAfterAddRow(Context);
	Else
		ErrorAtClient = New Structure("ErrorDescription", NStr("ru = 'В файле подписи нет ни одного сертификата.';
																|en = 'The signature file contains no certificates.';"));

		AddError(ErrorAtClient, Context);
		
	EndIf;
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure SelectFileAfterReceivingSignatureContainerError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	ErrorAtClient = New Structure("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось получить контейнер подписи из файла подписи по причине:
		           |%1';
					|en = 'Cannot receive the signature container from the signature file due to:
					|%1';"),
		ErrorProcessing.BriefErrorDescription(ErrorInfo)));
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ShowInstruction", True);
	AdditionalParameters.Insert("Signature", Context.SignatureAdditionResult.SignatureData);
	
	AddError(ErrorAtClient, Context, AdditionalParameters);
		
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Async Procedure SelectFileAfterGettingContainerSignature(ContainerSignatures, Context) Export
	
	SessionDate = CommonClient.SessionDate();
	UTCOffset = SessionDate - CommonClient.UniversalDate();
	SignatureParameters = Await DigitalSignatureInternalClient.ParametersCryptoSignatures(
		ContainerSignatures, UTCOffset, SessionDate);
			
	Context.Insert("SignatureParameters", SignatureParameters);
	SignatureDate = SignatureParameters.UnverifiedSignatureDate;
	If ValueIsFilled(SignatureDate) Then
		Context.SignatureAdditionResult.SignatureDate = SignatureDate;
	EndIf;
	
	Certificates = New Array;
	If SignatureParameters.CertificateDetails <> Undefined Then
		Certificates.Add(ContainerSignatures.Signatures[0].SignatureCertificate);
	EndIf;

	ChooseFilesAfterGetCertificatesFromSignature(Certificates, Context);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure SelectFileAfterGetCertificateFromSignatureError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	ErrorAtClient = New Structure("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось получить сертификаты из файла подписи по причине:
		           |%1';
					|en = 'Cannot receive the certificates from the signature file due to:
					|%1';"),
		ErrorProcessing.BriefErrorDescription(ErrorInfo)));
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ShowInstruction", True);
	AdditionalParameters.Insert("Signature", Context.SignatureAdditionResult.SignatureData);
	
	AddError(ErrorAtClient, Context, AdditionalParameters);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure ChooseFilesAfterGetCertificatesFromSignature(Certificates, Context) Export
	
	If Certificates.Count() = 0 Then
		ErrorAtClient = New Structure("ErrorDescription",
			NStr("ru = 'В файле подписи нет ни одного сертификата.';
				|en = 'The signature file contains no certificates.';"));
		
		AddError(ErrorAtClient, Context);
		Return;
	EndIf;
	
	Try
		If Certificates.Count() = 1 Then
			Certificate = Certificates[0];
		ElsIf Certificates.Count() > 1 Then
			Certificate = DigitalSignatureInternalClientServer.CertificatesInOrderToRoot(Certificates)[0];
		EndIf;
	Except
		ErrorAtClient = New Structure("ErrorDescription",
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		AddError(ErrorAtClient, Context);
		Return;
	EndTry;
	
	Context.Insert("Certificate", Certificate);
	
	CurrentCertificate = Context.Certificate; // CryptoCertificate
	CurrentCertificate.BeginUnloading(New NotifyDescription(
		"ChooseFileAfterCertificateExport", ThisObject, Context));
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Async Procedure ChooseFileAfterCertificateExport(CertificateData, Context) Export
	
	CertificateProperties = Await DigitalSignatureInternalClient.CertificateProperties(Context.Certificate);
	CertificateProperties.Insert("BinaryData", CertificateData);
	
	SignatureProperties = DigitalSignatureInternalClientServer.SignatureProperties(Context.SignatureAdditionResult.SignatureData,
		CertificateProperties, "", UsersClient.AuthorizedUser(), 
		Context.SignatureAdditionResult.FileName, Context.SignatureParameters, True);
	
	AddRow(ThisObject, Context.AddNewRows, SignatureProperties,
		Context.SignatureAdditionResult.FileName, Context.SignatureAdditionResult.SignaturePropertiesAddress);
	
	SelectFileAfterAddRow(Context);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure SelectFileAfterAddRow(Context)
	
	If Not DataDetails.Property("Data") Or Context.DataToValidateSignature = False Then
		SelectFilesLoopStart(Context);
		Return; // If data is not specified, the signature cannot be checked.
	EndIf;
	
	If Context.DataToValidateSignature = Undefined Then
		DigitalSignatureInternalClient.GetDataFromDataDetails(New NotifyDescription(
			"ChooseFileAfterGetData", ThisObject, Context),
		ThisObject, DataDetails, DataDetails.Data, True);
	Else
		ChooseFileAfterGetData(Context.DataToValidateSignature, Context);
	EndIf;
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure ChooseFileAfterGetData(Result, Context) Export
	
	If TypeOf(Result) = Type("Structure") Then
		Context.DataToValidateSignature = False;
		SelectFilesLoopStart(Context);
		Return; // Cannot get data. Signature check is impossible.
	EndIf;
	
	If Context.DataToValidateSignature = Undefined Then
		Context.DataToValidateSignature = Result;
	EndIf;
	
	ParametersForCheck = DigitalSignatureClient.SignatureVerificationParameters();
	ParametersForCheck.ShowCryptoManagerCreationError = False;
	ParametersForCheck.ResultAsStructure = True;
	DigitalSignatureInternalClient.VerifySignature(New NotifyDescription(
			"ChooseFileAfterCheckSignature", ThisObject, Context),
		Context.DataToValidateSignature, Context.SignatureAdditionResult.SignatureData, ,
		Context.SignatureAdditionResult.SignatureDate, ParametersForCheck);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure ChooseFileAfterCheckSignature(CheckResult, Context) Export
	
	If CheckResult.Result = Undefined Then
		SelectFilesLoopStart(Context);
		Return; // Cannot check the signature.
	EndIf;
	
	UpdateCheckSignatureResult(Context.SignatureAdditionResult.SignaturePropertiesAddress, CheckResult);
	SelectFilesLoopStart(Context);
	
EndProcedure

&AtServer
Procedure UpdateCheckSignatureResult(SignaturePropertiesAddress, CheckResult)
	
	CurrentSessionDate = CurrentSessionDate(); 
	
	SignatureProperties = GetFromTempStorage(SignaturePropertiesAddress);
	
	NewSignatureProperties = DigitalSignatureClientServer.NewSignatureProperties();
	FillPropertyValues(NewSignatureProperties, SignatureProperties);
	FillPropertyValues(NewSignatureProperties, CheckResult);
	NewSignatureProperties.SignatureValidationDate = CurrentSessionDate;
	
	PutToTempStorage(NewSignatureProperties, SignaturePropertiesAddress);
	
EndProcedure

&AtServer
Function AddRowsOnServer(PlacedFiles, AddNewRows)
	
	Map = New Map;
	OtherFiles = New Map;
	
	DigitalSignatureLocalization.OnAddRowsAtServer(
		ThisObject, PlacedFiles, OtherFiles, ErrorOnLOAsImport, UUID);
	
	For Each FileThatWasPut In PlacedFiles Do
		
		NameContent = CommonClientServer.ParseFullFileName(FileThatWasPut.Name);
		
		If OtherFiles.Get(NameContent.Name) <> Undefined Then
			Continue;
		EndIf;

		RowAdditionResult = New Structure;

		RowAdditionResult.Insert("Success", False);
		RowAdditionResult.Insert("Address", FileThatWasPut.Location);
		RowAdditionResult.Insert("FileName", NameContent.Name);
		RowAdditionResult.Insert("ErrorAtServer", New Structure);
		RowAdditionResult.Insert("SignatureData", Undefined);
		RowAdditionResult.Insert("SignatureDate", Undefined);
		RowAdditionResult.Insert("SignaturePropertiesAddress", Undefined);
		
		RowAdditionResult = AddRowAtServer(RowAdditionResult, AddNewRows);
		Map.Insert(FileThatWasPut.Name, RowAdditionResult);
		
	EndDo;
	
	Return Map;
	
EndFunction

&AtServer
Function AddRowAtServer(Val RowAdditionResult, AddNewRow)
	
	Try
		RowAdditionResult.SignatureData = DigitalSignature.DERSignature(RowAdditionResult.Address);
	Except
		ErrorInfo = ErrorInfo();
		RowAdditionResult.ErrorAtServer.Insert("ErrorDescription", ErrorProcessing.BriefErrorDescription(ErrorInfo));
		Return RowAdditionResult;
	EndTry;
	
	RowAdditionResult.SignatureDate = DigitalSignature.SigningDate(RowAdditionResult.SignatureData);
	
	If Not DigitalSignature.VerifyDigitalSignaturesOnTheServer()
		And Not DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		
		Return RowAdditionResult;
	EndIf;
	
	CreationParameters = DigitalSignatureInternal.CryptoManagerCreationParameters();
	CreationParameters.ErrorDescription = RowAdditionResult.ErrorAtServer;
	CreationParameters.SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(
		RowAdditionResult.SignatureData);
	
	CryptoManager = DigitalSignatureInternal.CryptoManager("", CreationParameters);
	
	RowAdditionResult.ErrorAtServer = CreationParameters.ErrorDescription;
	If CryptoManager = Undefined Then
		Return RowAdditionResult;
	EndIf;
	
	SignatureParameters = Undefined;
	If DigitalSignature.CommonSettings().AvailableAdvancedSignature Then
		
		Try
			ContainerSignatures = CryptoManager.GetCryptoSignaturesContainer(RowAdditionResult.SignatureData);
		Except
			ErrorInfo = ErrorInfo();
			RowAdditionResult.ErrorAtServer.Insert("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить контейнер подписи из файла подписи по причине:
				|%1';
				|en = 'Couldn''t receive the signature container from the signature file due to:
				|%1';"),
				ErrorProcessing.BriefErrorDescription(ErrorInfo)));
			Return RowAdditionResult;
		EndTry;
		
		SignatureParameters = DigitalSignatureInternal.ParametersCryptoSignatures(ContainerSignatures,
			DigitalSignatureInternal.UTCOffset(), CurrentSessionDate());
		
		If ValueIsFilled(SignatureParameters.UnverifiedSignatureDate) Then
			RowAdditionResult.SignatureDate = SignatureParameters.UnverifiedSignatureDate;
		EndIf;
		
	EndIf;
	
	If SignatureParameters = Undefined Then
		
		Try
			
			Certificates = CryptoManager.GetCertificatesFromSignature(RowAdditionResult.SignatureData);
			
			If Certificates.Count() = 0 Then
				Raise NStr("ru = 'В файле подписи нет ни одного сертификата.';
										|en = 'The signature file contains no certificates.';");
			EndIf;
			
			If Certificates.Count() = 1 Then
				Certificate = Certificates[0];
			ElsIf Certificates.Count() > 1 Then
				CertificatesData = New Array;
				For Each Certificate In Certificates Do
					CertificatesData.Add(Certificate.Unload());
				EndDo;
			
				CertificateBinaryData = DigitalSignatureInternal.CertificatesInOrderToRoot(
						CertificatesData)[0];
				Certificate = New CryptoCertificate(CertificateBinaryData);
			EndIf;
			
		Except
			ErrorInfo = ErrorInfo();
			RowAdditionResult.ErrorAtServer.Insert("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить сертификаты из файла подписи по причине:
				           |%1';
							|en = 'Cannot receive the certificates from the signature file due to:
							|%1';"),
				ErrorProcessing.BriefErrorDescription(ErrorInfo)));
			Return RowAdditionResult;
		EndTry;
		
		CertificateProperties = DigitalSignature.CertificateProperties(Certificate);
		
	Else
		
		CertificateProperties = SignatureParameters.CertificateDetails;
		Certificate = ContainerSignatures.Signatures[0].SignatureCertificate;
	EndIf;
	
	CertificateProperties.Insert("BinaryData", Certificate.Unload());
	
	SignatureProperties = DigitalSignatureInternalClientServer.SignatureProperties(RowAdditionResult.SignatureData,
		CertificateProperties, "", Users.AuthorizedUser(), RowAdditionResult.FileName, SignatureParameters, True);
	
	AddRow(ThisObject, AddNewRow, SignatureProperties, RowAdditionResult.FileName,
		RowAdditionResult.SignaturePropertiesAddress);
	RowAdditionResult.Success = True;
	
	Return RowAdditionResult;
	
EndFunction

&AtClientAtServerNoContext
Procedure AddRow(Form, AddNewRow, SignatureProperties, FileName, SignaturePropertiesAddress)
	
	NewSignatureProperties = DigitalSignatureClientServer.NewSignatureProperties();
	FillPropertyValues(NewSignatureProperties, SignatureProperties);
	
	SignaturePropertiesAddress = PutToTempStorage(NewSignatureProperties, Form.UUID);
	
	If AddNewRow Then
		CurrentData = Form.Signatures.Add();
	Else
		CurrentData = Form.Signatures.FindByID(Form.Items.Signatures.CurrentRow);
	EndIf;
	
	CurrentData.PathToFile = FileName;
	CurrentData.SignaturePropertiesAddress = SignaturePropertiesAddress;
	
EndProcedure

&AtServer
Function SignaturesToBeAdded()
	
	Result = New Array;
	For Each Signature In Signatures Do
		SignatureProperties = GetFromTempStorage(Signature.SignaturePropertiesAddress);
		SignatureProperties.Insert("Comment", Signature.Comment);
		Result.Add(PutToTempStorage(SignatureProperties, UUID));
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Function AddSignature(ObjectReference, ObjectVersion)
	
	Result = SignaturesToBeAdded();
	DigitalSignature.AddSignature(ObjectReference, Result, UUID, ObjectVersion);
	Return Result;
	
EndFunction

&AtClient
Procedure AddError(ErrorAtClient, Context, AdditionalParameters = Undefined)
	
	If ValueIsFilled(ErrorAtClient.ErrorDescription) Then
		Found4 = Context.Errors.ErrorsAtClient.Get(ErrorAtClient.ErrorDescription);
		If Found4 = Undefined Then
			Found4 = New Structure("Files, AdditionalParameters", New Array);
		EndIf;

		Found4.Files.Add(Context.SignatureAdditionResult.FileName);
		Found4.AdditionalParameters = AdditionalParameters;
		Context.Errors.ErrorsAtClient.Insert(ErrorAtClient.ErrorDescription, Found4);
	EndIf;

	If ValueIsFilled(Context.SignatureAdditionResult.ErrorAtServer) Then
		ErrorAtServer = Context.SignatureAdditionResult.ErrorAtServer;
		If ErrorAtServer.ErrorDescription <> ErrorAtClient.ErrorDescription Then
			Found4 = Context.Errors.ErrorsAtServer.Get(ErrorAtServer.ErrorDescription);
			If Found4 = Undefined Then
				Found4 = New Structure("Files, AdditionalParameters", New Array);
			EndIf;

			Found4.Files.Add(Context.SignatureAdditionResult.FileName);
			Found4.AdditionalParameters = AdditionalParameters;
			Context.Errors.ErrorsAtServer.Insert(ErrorAtServer.ErrorDescription, Found4);
		EndIf;
	EndIf;

	SelectFilesLoopStart(Context);
	
EndProcedure

&AtClient
Procedure ShowError(ErrorAtClient, ErrorAtServer, AdditionalParameters = Undefined)
	
	DigitalSignatureInternalClient.ShowApplicationCallError(
		NStr("ru = 'Не удалось получить подпись из файла';
			|en = 'Cannot receive a signature from the file';"),
		"", ErrorAtClient, ErrorAtServer, AdditionalParameters);
	
EndProcedure

&AtServer
Procedure ImportMRLOAs()
	
	DigitalSignatureLocalization.OnImportMRLOAs(ThisObject);
	
EndProcedure

&AtServer
Procedure FillMRLOAs(SignedObject = Undefined)
	
	DigitalSignatureLocalization.OnFillMRLOAs(ThisObject);
	
EndProcedure

&AtClient
Procedure MRLOASelectFromCatalog()
	
	CurrentData = Items.Signatures.CurrentData;
	CompletionHandler = New NotifyDescription("MRLOAEndOfSelection", ThisObject);
	DigitalSignatureClientLocalization.OnSelectMRLOA(CompletionHandler, CurrentData);
	
EndProcedure

&AtClient
Procedure MRLOAEndOfSelection(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	CurrentData = Items.Signatures.CurrentData;
	CurrentData.MachineReadableLetterOfAuthority = Result;
	SignaturesMRLOAOnChange();
	
EndProcedure

&AtClient
Procedure SignaturesMRLOAOnChange()
	
	If DataDetails.Property("Object") And TypeOf(DataDetails.Object) <> Type("NotifyDescription") Then
		FillMRLOAInRow(Items.Signatures.CurrentRow, DataDetails.Object);
	Else
		FillMRLOAInRow(Items.Signatures.CurrentRow);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillMRLOAInRow(RowID, SignedObject = Undefined)
	
	DigitalSignatureLocalization.OnFillMRLOAInRow(ThisObject, RowID, SignedObject);
		
EndProcedure

&AtClient
Procedure SignaturesMachineReadableLetterOfAuthorityAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion