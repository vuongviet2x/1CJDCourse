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
	
	ErrorAtClient = Parameters.ErrorAtClient;
	
	If ValueIsFilled(Parameters.CertificateAddress) Then

		CertificateData = GetFromTempStorage(Parameters.CertificateAddress);
		If TypeOf(CertificateData) = Type("String") Then
			CertificateData = Base64Value(CertificateData);
		EndIf;
		Certificate = New CryptoCertificate(CertificateData);
		CertificateAddress = PutToTempStorage(CertificateData, UUID);
		
	ElsIf ValueIsFilled(Parameters.Ref) Then
		CertificateAddress = CertificateAddress(Parameters.Ref, UUID);
		
		If Not ValueIsFilled(CertificateAddress) Then
			ErrorAtServer = New Structure;
			ErrorAtServer.Insert("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Сертификат ""%1"",
				           |не найден в справочнике сертификатов.';
							|en = 'Certificate ""%1"",
							|not found in the certificate catalog.';"), Parameters.Ref));
			Return;
		EndIf;
	Else // Thumbprint.
		CertificateAddress = CertificateAddress(Parameters.Thumbprint, UUID);
		
		If Not ValueIsFilled(CertificateAddress) Then
			ErrorAtServer = New Structure;
			ErrorAtServer.Insert("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Сертификат не найден по отпечатку ""%1"".';
					|en = 'Certificate not found by thumbprint ""%1"".';"), Parameters.Thumbprint));
			Return;
		EndIf;
	EndIf;
	
	If CertificateData = Undefined Then
		CertificateData = GetFromTempStorage(CertificateAddress);
		Certificate = New CryptoCertificate(CertificateData);
	EndIf;
	
	CertificateProperties = DigitalSignature.CertificateProperties(Certificate);
	CertificateAdditionalProperties = DigitalSignatureInternalClientServer.CertificateAdditionalProperties(
		CertificateData);
	
	AssignmentSign = Certificate.UseToSign;
	AssignmentEncryption = Certificate.UseToEncrypt;
	
	Thumbprint      = CertificateProperties.Thumbprint;
	IssuedTo      = CertificateProperties.IssuedTo;
	IssuedBy       = CertificateProperties.IssuedBy;
	EndDate  = CertificateProperties.EndDate;
	PrivateKeyExpirationDate = CertificateProperties.PrivateKeyExpirationDate;
	Items.PrivateKeyExpirationDate.Visible = ValueIsFilled(PrivateKeyExpirationDate);
	
	SignAlgorithm = DigitalSignatureInternalClientServer.CertificateSignAlgorithm(
		CertificateData, True);
	
	Items.SignAlgorithm.ToolTip =
		Metadata.Catalogs.DigitalSignatureAndEncryptionApplications.Attributes.SignAlgorithm.Tooltip;
	
	Items.GroupLicenseCryptoPro.Visible = CertificateAdditionalProperties.ContainsEmbeddedLicenseCryptoPro;
	
	FillCertificatePurposeCodes(CertificateProperties.Purpose, AssignmentCodes);
	
	FillSubjectProperties(Certificate);
	FillIssuerProperties(Certificate);
	
	InternalFieldsGroup = "Overall";
	FillInternalCertificateFields();
	
	ComponentObject = Undefined;
	
	If DigitalSignature.CommonSettings().VerifyDigitalSignaturesOnTheServer
		Or DigitalSignature.CommonSettings().GenerateDigitalSignaturesAtServer Then
		
		ResultCertificatesChain = DigitalSignatureInternal.CertificatesChain(
			CertificateData, UUID, ComponentObject);
			
		If Not ValueIsFilled(ResultCertificatesChain.Error) Then
			For Each CurrentCertificate In ResultCertificatesChain.Certificates Do
				CryptoCertificate = New CryptoCertificate(
					Base64Value(GetFromTempStorage(CurrentCertificate.CertificateData)));
				NewRow = CertificationPath.Insert(0);
				CertificateProperties = DigitalSignature.CertificateProperties(CryptoCertificate);
				NewRow.Presentation = CertificateProperties.Presentation;
				NewRow.CertificateData = CurrentCertificate.CertificateData;
			EndDo;
			Items.GroupErrorGettingCertificatesChain.Visible = False;
		Else
			ErrorGettingCertificationPathAtServer = ResultCertificatesChain.Error;
			Items.GroupErrorGettingCertificatesChain.Visible = True;
		EndIf;
		
		CertificatePropertiesExtended = DigitalSignatureInternal.CertificatePropertiesExtended(
			CertificateData, UUID, ComponentObject);
		ErrorWhenGettingReviewListAddressesOnServer = CertificatePropertiesExtended.Error;
		HasError = ValueIsFilled(CertificatePropertiesExtended.Error);
		Items.GroupErrorGettingReviewLists.Visible = HasError;
		Items.RevocationLists.Visible = Not HasError;
		If Not HasError Then
			For Each CurrentAddress In CertificatePropertiesExtended.CertificateProperties.AddressesOfRevocationLists Do
				NewRow = RevocationLists.Add();
				NewRow.Address = CurrentAddress;
			EndDo;
		EndIf;
	
	EndIf;
	
	If Parameters.Property("OpeningFromCertificateItemForm") Then
		Items.FormSaveToFile.Visible = False;
		Items.FormValidate.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(ErrorAtServer) Then
		Cancel = True;
		DigitalSignatureInternalClient.ShowApplicationCallError(
			NStr("ru = 'Не удалось открыть сертификат';
				|en = 'Cannot open the certificate';"), "", 
			ErrorAtClient, ErrorAtServer);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InternalFieldsGroupOnChange(Item)
	
	FillInternalCertificateFields();
	
EndProcedure

&AtClient
Procedure InternalFieldsGroupClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.PageRootCertificates 
		And (ValueIsFilled(ErrorGettingCertificationPathAtServer) Or CertificationPath.Count() = 0) Then
			
		PopulateRootCertificates();
		
	EndIf;
	
	If CurrentPage = Items.PageRevocationLists 
		And RevocationLists.Count() = 0 Then

		FillInReviewLists();
		
	EndIf;
		
EndProcedure

&AtClient
Procedure DecorationErrorGettingCertificatesChainClick(Item)
	
	DigitalSignatureInternalClient.ShowApplicationCallError(
		NStr("ru = 'Не удалось получить путь сертификации';
			|en = 'Cannot receive a certification path';"), "", 
		New Structure("ErrorDescription", ErrorGettingCertificationPaths),
		New Structure("ErrorDescription", ErrorGettingCertificationPathAtServer));
		
EndProcedure

&AtClient
Procedure DecorationErrorGettingReviewListsClick(Item)
	
	DigitalSignatureInternalClient.ShowApplicationCallError(
		NStr("ru = 'Не удалось получить адреса списков отзыва сертификата';
			|en = 'Could not receive the addresses of certificate revocation lists';"), "", 
		New Structure("ErrorDescription", ErrorGettingListOfRevocationListsAddresses),
		New Structure("ErrorDescription", ErrorWhenGettingReviewListAddressesOnServer));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRevocationLists

&AtClient
Procedure RevocationListsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRootCertificates

&AtClient
Procedure RootCertificatesChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.CertificationPath.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CertificateAddress", CurrentData.CertificateData);
	
	DigitalSignatureInternalClient.OpenCertificateForm(FormParameters);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveToFile(Command)
	
	DigitalSignatureInternalClient.SaveCertificate(Undefined, CertificateAddress);
	
EndProcedure

&AtClient
Procedure Validate(Command)
	
	AdditionalInspectionParameters = DigitalSignatureInternalClient.AdditionalCertificateVerificationParameters();
	AdditionalInspectionParameters.MergeCertificateDataErrors = False;
	DigitalSignatureInternalClient.CheckCertificate(New NotifyDescription(
		"ValidateCompletion", ThisObject), CertificateAddress,,, AdditionalInspectionParameters);
	Items.FormValidate.Enabled = False;
	
EndProcedure

&AtClient
Procedure SetRevocationList(Command)
	
	RevocationListInstallationParameters = DigitalSignatureInternalClient.RevocationListInstallationParameters(CertificateAddress);
	DigitalSignatureInternalClient.SetListOfCertificateRevocation(RevocationListInstallationParameters);

EndProcedure

&AtClient
Procedure InstallCertificate(Command)
	
	CurrentData = Items.CertificationPath.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;

	BinaryData = Base64Value(GetFromTempStorage(CurrentData.CertificateData));
	CertificateInstallationParameters = DigitalSignatureInternalClient.CertificateInstallationParameters(
		PutToTempStorage(BinaryData, UUID));
		
	If CertificationPath.Count() > 1 Then
		
		If CurrentData.GetID() = CertificationPath[0].GetID() Then
			InstallationOptions = New ValueList;
			InstallationOptions.Add("ROOT", NStr("ru = 'Доверенные корневые сертификаты';
													|en = 'Trusted root certificates';"));
			InstallationOptions.Add("CA", NStr("ru = 'Промежуточные сертификаты';
													|en = 'Intermediate certificates';"));
			InstallationOptions.Add("MY", NStr("ru = 'Личное хранилище сертификатов';
													|en = 'Personal certificate store';"));
			InstallationOptions.Add("Container", NStr("ru = 'Контейнер и личное хранилище';
														|en = 'Container and Personal store';"));
			CertificateInstallationParameters.InstallationOptions = InstallationOptions;
		ElsIf CurrentData.GetID() <> CertificationPath[CertificationPath.Count() - 1].GetID() Then
			InstallationOptions = New ValueList;
			InstallationOptions.Add("CA", NStr("ru = 'Промежуточные сертификаты';
													|en = 'Intermediate certificates';"));
			InstallationOptions.Add("ROOT", NStr("ru = 'Доверенные корневые сертификаты';
													|en = 'Trusted root certificates';"));
			InstallationOptions.Add("MY", NStr("ru = 'Личное хранилище сертификатов';
													|en = 'Personal certificate store';"));
			InstallationOptions.Add("Container", NStr("ru = 'Контейнер и личное хранилище';
														|en = 'Container and Personal store';"));
			CertificateInstallationParameters.InstallationOptions = InstallationOptions;
		EndIf;
	EndIf;
	
	DigitalSignatureInternalClient.InstallCertificate(CertificateInstallationParameters);
	
EndProcedure

#EndRegion

#Region Private

// Continues the Check procedure.
&AtClient
Procedure ValidateCompletion(Result, Context) Export
	
	If Result = True Then
		ShowMessageBox(, NStr("ru = 'Сертификат действителен.';
										|en = 'Certificate is valid.';"));
	ElsIf Result <> Undefined Then
		
		AdditionalData = DigitalSignatureInternalClient.AdditionalDataForErrorClassifier();
		AdditionalData.CertificateData = CertificateAddress;
		
		WarningParameters = New Structure;
		WarningParameters.Insert("AdditionalData", AdditionalData);
		
		WarningParameters.Insert("WarningTitle",
			NStr("ru = 'Сертификат недействителен по причине:';
				|en = 'Certificate is invalid due to:';"));
		
		If TypeOf(Result) = Type("Structure") Then
			WarningParameters.Insert("ErrorTextClient",
				Result.ErrorDetailsAtClient);
			WarningParameters.Insert("ErrorTextServer",
				Result.ErrorDescriptionAtServer);
		Else
			WarningParameters.Insert("ErrorTextClient",
				Result);
		EndIf;
		
		DigitalSignatureInternalClient.OpenExtendedErrorPresentationForm(WarningParameters, ThisObject);
		
	EndIf;
	
	Items.FormValidate.Enabled = True;
	
EndProcedure

&AtServer
Procedure FillSubjectProperties(Certificate)
	
	Collection = DigitalSignature.CertificateSubjectProperties(Certificate);
	
	PropertiesPresentations = New Map;
	PropertiesPresentations["CommonName"] = NStr("ru = 'Общее имя';
											|en = 'Common name';");
	PropertiesPresentations["Country"] = NStr("ru = 'Страна';
											|en = 'Country';");
	PropertiesPresentations["State"] = NStr("ru = 'Регион';
											|en = 'State';");
	PropertiesPresentations["Locality"] = NStr("ru = 'Населенный пункт';
													|en = 'Locality';");
	PropertiesPresentations["Street"] = NStr("ru = 'Улица';
										|en = 'Street';");
	PropertiesPresentations["Organization"] = NStr("ru = 'Организация';
												|en = 'Company';");
	PropertiesPresentations["Department"] = NStr("ru = 'Подразделение';
												|en = 'Department';");
	PropertiesPresentations["Email"] = NStr("ru = 'Электронная почта';
													|en = 'Email';");
	
	If Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined Then
		CommonClientServer.SupplementMap(PropertiesPresentations,
			DataProcessors["DigitalSignatureAndEncryptionApplications"].PresentationOfCertificateSubjectProperties(), True);
	EndIf;
	
	For Each ListItem In PropertiesPresentations Do
		PropertyValue = CommonClientServer.StructureProperty(Collection, ListItem.Key);
		If Not ValueIsFilled(PropertyValue) Then
			Continue;
		EndIf;
		String = Subject.Add();
		String.Property = ListItem.Value;
		String.Value = PropertyValue;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillIssuerProperties(Certificate)
	
	Collection = DigitalSignature.CertificateIssuerProperties(Certificate);
	
	PropertiesPresentations = New Map;
	PropertiesPresentations["CommonName"] = NStr("ru = 'Общее имя';
											|en = 'Common name';");
	PropertiesPresentations["Country"] = NStr("ru = 'Страна';
											|en = 'Country';");
	PropertiesPresentations["State"] = NStr("ru = 'Регион';
											|en = 'State';");
	PropertiesPresentations["Locality"] = NStr("ru = 'Населенный пункт';
													|en = 'Locality';");
	PropertiesPresentations["Street"] = NStr("ru = 'Улица';
										|en = 'Street';");
	PropertiesPresentations["Organization"] = NStr("ru = 'Организация';
												|en = 'Company';");
	PropertiesPresentations["Department"] = NStr("ru = 'Подразделение';
												|en = 'Department';");
	PropertiesPresentations["Email"] = NStr("ru = 'Электронная почта';
													|en = 'Email';");
	
	If Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined Then
		CommonClientServer.SupplementMap(PropertiesPresentations,
			DataProcessors["DigitalSignatureAndEncryptionApplications"].CertificatePublisherPropertyPresentations(), True);
	EndIf;
	
	For Each ListItem In PropertiesPresentations Do
		PropertyValue = CommonClientServer.StructureProperty(Collection, ListItem.Key);
		If Not ValueIsFilled(PropertyValue) Then
			Continue;
		EndIf;
		String = Issuer.Add();
		String.Property = ListItem.Value;
		String.Value = PropertyValue;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInternalCertificateFields()
	
	InternalContent.Clear();
	CertificateBinaryData = GetFromTempStorage(CertificateAddress);
	Certificate = New CryptoCertificate(CertificateBinaryData);
	
	If InternalFieldsGroup = "Overall" Then
		Items.InternalContentId.Visible = False;
		
		AddProperty(Certificate, "Version",                    NStr("ru = 'Версия';
																		|en = 'Version';"));
		AddProperty(Certificate, "ValidFrom",                NStr("ru = 'Дата начала';
																		|en = 'Start date';"));
		AddProperty(Certificate, "ValidTo",             NStr("ru = 'Дата окончания';
																		|en = 'End date';"));
		
		If ValueIsFilled(CertificateAdditionalProperties.PrivateKeyStartDate) Then
			AddProperty(CertificateAdditionalProperties, "PrivateKeyStartDate",    NStr("ru = 'Дата начала закрытого ключа';
																									|en = 'Private key start date';"));
		EndIf;
		If ValueIsFilled(CertificateAdditionalProperties.PrivateKeyExpirationDate) Then
			AddProperty(CertificateAdditionalProperties, "PrivateKeyExpirationDate", NStr("ru = 'Дата окончания закрытого ключа';
																									|en = 'Private key end date';"));
		EndIf;
		
		AddProperty(Certificate, "UseToSign",    NStr("ru = 'Использовать для подписи';
																		|en = 'Use for signature';"));
		AddProperty(Certificate, "UseToEncrypt", NStr("ru = 'Использовать для шифрования';
																		|en = 'Use for encryption';"));
		AddProperty(Certificate, "PublicKey",              NStr("ru = 'Открытый ключ';
																		|en = 'Public key';"), True);
		AddProperty(Certificate, "Thumbprint",                 NStr("ru = 'Отпечаток';
																		|en = 'Thumbprint';"), True);
		AddProperty(Certificate, "SerialNumber",             NStr("ru = 'Серийный номер';
																		|en = 'Serial number';"), True);
		
	ElsIf InternalFieldsGroup = "Extensions" Then
		Items.InternalContentId.Visible = False;
		
		Collection = Certificate.Extensions;
		For Each KeyAndValue In Collection Do
			AddProperty(Collection, KeyAndValue.Key, KeyAndValue.Key);
		EndDo;
	Else
		Items.InternalContentId.Visible = True;
		
		IDsNames = New ValueList;
		IDsNames.Add("OID2_5_4_3",              "CN");
		IDsNames.Add("OID2_5_4_6",              "C");
		IDsNames.Add("OID2_5_4_8",              "ST");
		IDsNames.Add("OID2_5_4_7",              "L");
		IDsNames.Add("OID2_5_4_9",              "Street");
		IDsNames.Add("OID2_5_4_10",             "O");
		IDsNames.Add("OID2_5_4_11",             "OU");
		IDsNames.Add("OID2_5_4_12",             "T");
		IDsNames.Add("OID1_2_840_113549_1_9_1", "E");
		
		IDsNames.Add("OID1_2_643_100_1",     "OGRN");
		IDsNames.Add("OID1_2_643_100_5",     "OGRNIP");
		IDsNames.Add("OID1_2_643_100_3",     "SNILS");
		IDsNames.Add("OID1_2_643_3_131_1_1", "INN");
		IDsNames.Add("OID1_2_643_100_4",     "INNLE");
		IDsNames.Add("OID2_5_4_4",           "SN");
		IDsNames.Add("OID2_5_4_42",          "GN");
		
		NamesAndIDs = New Map;
		Collection = Certificate[InternalFieldsGroup];
		
		For Each ListItem In IDsNames Do
			If Collection.Property(ListItem.Value) Then
				AddProperty(Collection, ListItem.Value, ListItem.Presentation);
			EndIf;
			NamesAndIDs.Insert(ListItem.Value, True);
			NamesAndIDs.Insert(ListItem.Presentation, True);
		EndDo;
		
		For Each KeyAndValue In Collection Do
			If NamesAndIDs.Get(KeyAndValue.Key) = Undefined Then
				AddProperty(Collection, KeyAndValue.Key, KeyAndValue.Key);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure AddProperty(PropertiesValues, Property, Presentation, Lowercase = Undefined)
	
	Value = PropertiesValues[Property];
	If TypeOf(Value) = Type("Date") Then
		Value = ToLocalTime(Value, SessionTimeZone());
	ElsIf TypeOf(Value) = Type("FixedArray") Then
		FixedArray = Value;
		Value = "";
		For Each ArrayElement In FixedArray Do
			Value = Value + ?(Value = "", "", Chars.LF) + TrimAll(ArrayElement);
		EndDo;
	EndIf;
	
	String = InternalContent.Add();
	If StrStartsWith(Property, "OID") Then
		String.Id = StrReplace(Mid(Property, 4), "_", ".");
		If Property <> Presentation Then
			String.Property = Presentation;
		EndIf;
	Else
		String.Property = Presentation;
	EndIf;
	
	If Lowercase = True Then
		String.Value = Lower(Value);
	Else
		String.Value = Value;
	EndIf;
	
EndProcedure

// Transforms certificate purposes into purpose codes.
//
// Parameters:
//  Purpose    - String - Multiline certificate purpose. For example:
//                           "Microsoft Encrypted File System (1.3.6.1.4.1.311.10.3.4)
//                           |E-mail Protection (1.3.6.1.5.5.7.3.4)
//                           |TLS Web Client Authentication (1.3.6.1.5.5.7.3.2)".
//  
//  PurposeCodes - String - purpose codes "1.3.6.1.4.1.311.10.3.4, 1.3.6.1.5.5.7.3.4, 1.3.6.1.5.5.7.3.2".
//
&AtServer
Procedure FillCertificatePurposeCodes(Purpose, PurposeCodes)
	
	SetPrivilegedMode(True);
	
	Codes = "";
	
	For IndexOf = 1 To StrLineCount(Purpose) Do
		
		String = StrGetLine(Purpose, IndexOf);
		CurrentCode = "";
		
		Position = StrFind(String, "(", SearchDirection.FromEnd);
		If Position <> 0 Then
			CurrentCode = Mid(String, Position + 1, StrLen(String) - Position - 1);
		EndIf;
		
		If ValueIsFilled(CurrentCode) Then
			Codes = Codes + ?(Codes = "", "", ", ") + TrimAll(CurrentCode);
		EndIf;
		
	EndDo;
	
	PurposeCodes = Codes;
	
EndProcedure

&AtClient
Procedure PopulateRootCertificates()
	
	DigitalSignatureInternalClient.GetCertificateChain(New NotifyDescription("AfterGotCertificatesChain", ThisObject),
		CertificateAddress, UUID);
	
EndProcedure

&AtClient
Async Procedure AfterGotCertificatesChain(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result.Error) Then
		For Each CurrentCertificate In Result.Certificates Do
			CryptoCertificate = New CryptoCertificate();
			Await CryptoCertificate.InitializeAsync(
				Base64Value(GetFromTempStorage(CurrentCertificate.CertificateData)));
			NewRow = CertificationPath.Insert(0);
			
			CertificateProperties = Await DigitalSignatureInternalClient.CertificateProperties(CryptoCertificate);
			
			NewRow.Presentation = CertificateProperties.Presentation;
			NewRow.CertificateData = CurrentCertificate.CertificateData;
		EndDo;
		Items.GroupErrorGettingCertificatesChain.Visible = False;
	Else
		ErrorGettingCertificationPaths = Result.Error;
		Items.GroupErrorGettingCertificatesChain.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Async Procedure FillInReviewLists()
	
	ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr(
		"ru = 'Для получения данных об адресах списков отзыва сертификата требуется установка внешней компоненты %1.';
		|en = 'To receive addresses of certificate revocation lists, install the %1 add-in.';"),
		"ExtraCryptoAPI");

	Try
		ComponentObject = Await DigitalSignatureInternalClient.AnObjectOfAnExternalComponentOfTheExtraCryptoAPI(True, ExplanationText);
	Except
		ErrorGettingListOfRevocationListsAddresses = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Items.GroupErrorGettingReviewLists.Visible = True;
		Items.RevocationLists.Visible = False;
		Return;
	EndTry;
	
	CertificatePropertiesExtended = Await DigitalSignatureInternalClient.GetCertificatePropertiesAsync(
		CertificateAddress, ComponentObject);
		
	If ValueIsFilled(CertificatePropertiesExtended.Error) Then
		ErrorGettingListOfRevocationListsAddresses = CertificatePropertiesExtended.Error;
		Items.GroupErrorGettingReviewLists.Visible = True;
		Items.RevocationLists.Visible = False;
		Return;
	EndIf;
	
	Items.GroupErrorGettingReviewLists.Visible = False;
	Items.RevocationLists.Visible = True;
		
	AddressesOfRevocationLists = CertificatePropertiesExtended.CertificateProperties.AddressesOfRevocationLists;
	For Each CurrentAddress In CertificatePropertiesExtended.CertificateProperties.AddressesOfRevocationLists Do
		NewRow = RevocationLists.Add();
		NewRow.Address = CurrentAddress;
	EndDo;
	
EndProcedure

&AtServer
Function CertificateAddress(RefThumbprint, FormIdentifier = Undefined)
	
	CertificateData = Undefined;
	
	If TypeOf(RefThumbprint) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates") Then
		Store = Common.ObjectAttributeValue(RefThumbprint, "CertificateData");
		If TypeOf(Store) = Type("ValueStorage") Then
			CertificateData = Store.Get();
		EndIf;
	Else
		Query = New Query;
		Query.SetParameter("Thumbprint", RefThumbprint);
		Query.Text =
		"SELECT
		|	Certificates.CertificateData
		|FROM
		|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
		|WHERE
		|	Certificates.Thumbprint = &Thumbprint";
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			CertificateData = Selection.CertificateData.Get();
		Else
			Certificate = DigitalSignatureInternal.GetCertificateByThumbprint(RefThumbprint, False, False);
			If Certificate <> Undefined Then
				CertificateData = Certificate.Unload();
			EndIf;
		EndIf;
	EndIf;
	
	If TypeOf(CertificateData) = Type("BinaryData") Then
		Return PutToTempStorage(CertificateData, FormIdentifier);
	EndIf;
	
	Return "";
	
EndFunction

#EndRegion
