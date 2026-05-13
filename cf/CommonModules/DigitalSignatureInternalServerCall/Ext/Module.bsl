///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Private

// For internal use only
Function CertificateThumbprints(OnlyPersonal, ErrorDescription = Null, Service = True) Export
	
	Return DigitalSignature.CertificateThumbprints(OnlyPersonal, ErrorDescription, Service);
	
EndFunction

// For internal use only
Function ServiceCertificateThumbprints() Export
	
	Return DigitalSignatureInternal.ServiceCertificateThumbprints();
	
EndFunction

// For internal use only
Function PersonalCertificates(CertificatesPropertiesAtClient, Filter, Error = "") Export
	
	CertificatesPropertiesTable = New ValueTable;
	CertificatesPropertiesTable.Columns.Add("Thumbprint", New TypeDescription("String", , , , New StringQualifiers(255)));
	CertificatesPropertiesTable.Columns.Add("IssuedBy");
	CertificatesPropertiesTable.Columns.Add("Presentation");
	CertificatesPropertiesTable.Columns.Add("AtClient",        New TypeDescription("Boolean"));
	CertificatesPropertiesTable.Columns.Add("AtServer",        New TypeDescription("Boolean"));
	CertificatesPropertiesTable.Columns.Add("IsRequest",     New TypeDescription("Boolean"));
	CertificatesPropertiesTable.Columns.Add("InCloudService", New TypeDescription("Boolean"));
	CertificatesPropertiesTable.Columns.Add("LocationType",	New TypeDescription("Number"));
	
	For Each CertificateProperties In CertificatesPropertiesAtClient Do
		NewRow = CertificatesPropertiesTable.Add();
		FillPropertyValues(NewRow, CertificateProperties);
		NewRow.AtClient = True;
	EndDo;
	
	CertificatesPropertiesTable.Indexes.Add("Thumbprint");
	
	If DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		
		CreationParameters = DigitalSignatureInternal.CryptoManagerCreationParameters();
		CryptoManager = DigitalSignatureInternal.CryptoManager("GetCertificates", CreationParameters);
		
		Error = CreationParameters.ErrorDescription;
		If CryptoManager <> Undefined Then
			
			Try
				CertificatesArray = CryptoManager.GetCertificateStore(
					CryptoCertificateStoreType.PersonalCertificates).GetAll();
				DigitalSignatureInternalClientServer.AddCertificatesProperties(CertificatesPropertiesTable, CertificatesArray, True,
					DigitalSignatureInternal.UTCOffset(), CurrentSessionDate());
			Except
				ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
				If TypeOf(Error) = Type("Structure") Then
					Error = DigitalSignatureInternalClientServer.NewErrorsDescription(ComputerName());
					Error.ErrorDescription = ErrorDescription;
				Else
					Error = ErrorDescription;
				EndIf;
			EndTry;
		EndIf;
		
	EndIf;
	
	If DigitalSignatureInternal.UseDigitalSignatureSaaS() Then
		
		ModuleCertificateStore = Common.CommonModule("CertificatesStorage");
		CertificatesArray = ModuleCertificateStore.Get("PersonalCertificates");
		
		PropertiesAddingOptions = New Structure("InCloudService", True);
		DigitalSignatureInternalClientServer.AddCertificatesProperties(CertificatesPropertiesTable, CertificatesArray, True,
			DigitalSignatureInternal.UTCOffset(), CurrentSessionDate(), PropertiesAddingOptions);
			
	EndIf;
	
	If DigitalSignatureInternal.UseCloudSignatureService() Then
	EndIf;
	
	Return ProcessPersonalCertificates(CertificatesPropertiesTable, Filter);
	
EndFunction

// For internal use only         
Function ProcessPersonalCertificates(CertificatesPropertiesTable, Filter)
	
	Query = New Query;
	Query.SetParameter("Thumbprints", CertificatesPropertiesTable.Copy(, "Thumbprint"));
	Query.Text =
		"SELECT
		|	Thumbprints.Thumbprint AS Thumbprint
		|INTO Thumbprints
		|FROM
		|	&Thumbprints AS Thumbprints
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Thumbprints.Thumbprint AS Thumbprint,
		|	Certificates.Description AS Description,
		|	Certificates.Organization AS Organization,
		|	Certificates.User AS User,
		|	Certificates.Ref AS Ref,
		|	Certificates.CertificateData AS CertificateData
		|INTO AllCertificates
		|FROM
		|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
		|		INNER JOIN Thumbprints AS Thumbprints
		|		ON Certificates.Thumbprint = Thumbprints.Thumbprint
		|WHERE
		|	NOT Certificates.Application = VALUE(Catalog.DigitalSignatureAndEncryptionApplications.EmptyRef)
		|	AND Certificates.Organization = &Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Certificates.Thumbprint AS Thumbprint,
		|	Certificates.Description AS Description,
		|	Certificates.Organization AS Organization,
		|	Certificates.Ref AS Ref,
		|	Certificates.CertificateData AS CertificateData
		|FROM
		|	AllCertificates AS Certificates
		|WHERE
		|	Certificates.Ref IN
		|			(SELECT
		|				AllCertificates.Ref AS Ref
		|			FROM
		|				AllCertificates AS AllCertificates
		|			WHERE
		|				AllCertificates.User = &User
		|		
		|			UNION ALL
		|		
		|			SELECT
		|				AllCertificates.Ref
		|			FROM
		|				AllCertificates AS AllCertificates
		|					INNER JOIN Catalog.DigitalSignatureAndEncryptionKeysCertificates.Users AS ElectronicSignatureAndEncryptionKeyCertificatesUsers
		|					ON
		|						AllCertificates.Ref = ElectronicSignatureAndEncryptionKeyCertificatesUsers.Ref
		|			WHERE
		|				ElectronicSignatureAndEncryptionKeyCertificatesUsers.User = &User)";
	
	Query.SetParameter("User", Users.CurrentUser());
	
	If Not Filter.CertificatesWithFilledProgramOnly Then
		Query.Text = StrReplace(Query.Text, "NOT Certificates.Application = VALUE(Catalog.DigitalSignatureAndEncryptionApplications.EmptyRef)", "TRUE");
	EndIf;
	
	If Filter.IncludeCertificatesWithBlankUser Then
		
		Query.Text = Query.Text + "
		|UNION ALL
		|" + 
		"SELECT
		|	AllCertificates.Thumbprint AS Thumbprint,
		|	AllCertificates.Description AS Description,
		|	AllCertificates.Organization AS Organization,
		|	AllCertificates.Ref AS Ref,
		|	AllCertificates.CertificateData AS CertificateData
		|FROM
		|	AllCertificates AS AllCertificates
		|		LEFT JOIN Catalog.DigitalSignatureAndEncryptionKeysCertificates.Users AS ElectronicSignatureAndEncryptionKeyCertificatesUsers
		|		ON AllCertificates.Ref = ElectronicSignatureAndEncryptionKeyCertificatesUsers.Ref
		|WHERE
		|	AllCertificates.User = VALUE(Catalog.Users.EmptyRef)
		|	AND ElectronicSignatureAndEncryptionKeyCertificatesUsers.Ref IS NULL";
		
	EndIf;
	
	If ValueIsFilled(Filter.Organization) Then
		Query.SetParameter("Organization", Filter.Organization);
	Else
		Query.Text = StrReplace(Query.Text, "Certificates.Organization = &Organization", "TRUE");
	EndIf;
	
	Selection = Query.Execute().Select();
	
	PersonalCertificatesArray = New Array;
	
	While Selection.Next() Do
		String = CertificatesPropertiesTable.Find(Selection.Thumbprint, "Thumbprint");
		If String <> Undefined Then
			CertificateStructure1 = New Structure("Ref, Description, Thumbprint, Data, Organization");
			FillPropertyValues(CertificateStructure1, Selection);
			CertificateStructure1.Data = PutToTempStorage(Selection.CertificateData, Undefined);
			PersonalCertificatesArray.Add(CertificateStructure1);
		EndIf;
	EndDo;
	
	Return PersonalCertificatesArray;
	
EndFunction

// For internal use only.
Function VerifySignature(SourceDataAddress, SignatureAddress, ErrorDescription, OnDate, CheckResult = Undefined) Export
	
	Return DigitalSignature.VerifySignature(Undefined, SourceDataAddress, SignatureAddress, ErrorDescription, OnDate, CheckResult);
	
EndFunction

// For internal use only.
Function CheckCertificate(CertificateAddress, ErrorDescription, OnDate, AdditionalParameters = Undefined) Export
	
	Return DigitalSignatureInternal.CheckCertificate(Undefined, CertificateAddress, ErrorDescription, OnDate, AdditionalParameters);
	
EndFunction

// For internal use only.
Function SignatureProperties(SignaturesAddress, ShouldReadCertificates, UseCryptoManager = True) Export
	
	Signatures = GetFromTempStorage(SignaturesAddress);
	Result = DigitalSignatureInternal.SignatureProperties(
		Signatures, ShouldReadCertificates, UseCryptoManager);
	Return PutToTempStorage(Result);
	
EndFunction

// For internal use only.
Function CertificateRef(Thumbprint, CertificateAddress) Export
	
	If ValueIsFilled(CertificateAddress) Then
		BinaryData = GetFromTempStorage(CertificateAddress);
		Certificate = New CryptoCertificate(BinaryData);
		Thumbprint = Base64String(Certificate.Thumbprint);
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Thumbprint", Thumbprint);
	Query.Text =
	"SELECT
	|	Certificates.Ref AS Ref
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|WHERE
	|	Certificates.Thumbprint = &Thumbprint";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	
	Return Undefined;
	
EndFunction

Function AddedCertificates(NewCertificate) Export
	
	Result = New Array;
	
	If TypeOf(NewCertificate) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates") Then
		Certificates = CommonClientServer.ValueInArray(NewCertificate);
	Else
		Certificates = NewCertificate;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Certificates", Certificates);
	Query.Text =
	"SELECT ALLOWED
	|	DigitalSignatureAndEncryptionKeysCertificates.CertificateData AS OldCertificateData,
	|	ElectronicSignatureAndEncryptionKeyCertificatesNew.CertificateData AS NewCertificateData,
	|	DigitalSignatureAndEncryptionKeysCertificates.Ref AS OldCertificateLink,
	|	ElectronicSignatureAndEncryptionKeyCertificatesNew.Ref AS NewCertificateLink
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS ElectronicSignatureAndEncryptionKeyCertificatesNew
	|		LEFT JOIN Catalog.DigitalSignatureAndEncryptionKeysCertificates AS DigitalSignatureAndEncryptionKeysCertificates
	|		ON (ElectronicSignatureAndEncryptionKeyCertificatesNew.IssuedTo <> """"
	|				OR ElectronicSignatureAndEncryptionKeyCertificatesNew.Firm <> """")
	|			AND ElectronicSignatureAndEncryptionKeyCertificatesNew.Ref <> DigitalSignatureAndEncryptionKeysCertificates.Ref
	|			AND ElectronicSignatureAndEncryptionKeyCertificatesNew.IssuedTo = DigitalSignatureAndEncryptionKeysCertificates.IssuedTo
	|			AND ElectronicSignatureAndEncryptionKeyCertificatesNew.Firm = DigitalSignatureAndEncryptionKeysCertificates.Firm
	|			AND ElectronicSignatureAndEncryptionKeyCertificatesNew.ValidBefore > DigitalSignatureAndEncryptionKeysCertificates.ValidBefore
	|			AND (DigitalSignatureAndEncryptionKeysCertificates.ValidBefore <> DATETIME(1, 1, 1))
	|WHERE
	|	ElectronicSignatureAndEncryptionKeyCertificatesNew.Ref IN(&Certificates)
	|
	|ORDER BY
	|	DigitalSignatureAndEncryptionKeysCertificates.ValidBefore DESC
	|TOTALS BY
	|	NewCertificateLink";
	
	QueryResult = Query.Execute();
	
	SelectionIsNew = QueryResult.Select(QueryResultIteration.ByGroups);
	While SelectionIsNew.Next() Do
		
		Structure = New Structure("NewCertificate, OldCertificate", SelectionIsNew.NewCertificateLink);
		PropertiesOfNewSubject = Undefined;
		Selection = SelectionIsNew.Select();
		While Selection.Next() Do
			If Selection.OldCertificateData = Null Then
				Break;
			EndIf;
			
			If PropertiesOfNewSubject = Undefined Then
				CertificateData = Selection.NewCertificateData.Get();
				If TypeOf(CertificateData) <> Type("BinaryData") Then
					Break;
				EndIf;
				CryptoCertificate = New CryptoCertificate(CertificateData);
				PropertiesOfNewSubject = DigitalSignature.CertificateSubjectProperties(CryptoCertificate);
			EndIf;

			CertificateData = Selection.OldCertificateData.Get();
			CryptoCertificate = New CryptoCertificate(CertificateData);
			PropertiesOfOldSubject = DigitalSignature.CertificateSubjectProperties(CryptoCertificate);

			If DigitalSignatureInternalClientServer.ThisIsCertificateReplacement(PropertiesOfNewSubject,
				PropertiesOfOldSubject) Then
				
				Structure.OldCertificate = Selection.OldCertificateLink;
				Break;
			EndIf;
		EndDo;
		
		Result.Add(Structure);
		
	EndDo;

	Return Result;
	
EndFunction

// For internal use only.
Function SubjectPresentation(CertificateAddress) Export
	
	CertificateData = GetFromTempStorage(CertificateAddress);
	
	CryptoCertificate = New CryptoCertificate(CertificateData);
	
	CertificateAddress = PutToTempStorage(CertificateData, CertificateAddress);
	
	Return DigitalSignature.SubjectPresentation(CryptoCertificate);
	
EndFunction

// For internal use only.
Function ExecuteAtServerSide(Val Parameters, ResultAddress, OperationStarted, ErrorAtServer) Export
	
	If Not ValueIsFilled(Parameters.CertificateApp)
		And Parameters.Property("DataToCreateCryptographyManager") Then
		
		If Parameters.Operation = "Signing" Or Parameters.Operation = "Details" Then
			IsPrivateKeyRequied = True;
		Else
			IsPrivateKeyRequied = Undefined;
		EndIf;
		
		CertificateApplicationResult = DigitalSignatureInternal.AppForCertificate(
			Parameters.DataToCreateCryptographyManager, IsPrivateKeyRequied);

		If Not ValueIsFilled(CertificateApplicationResult.Application) Then
			ErrorAtServer = DigitalSignatureInternalClientServer.NewErrorsDescription();
			ErrorAtServer.Insert("ErrorDescription",
				DigitalSignatureInternalClientServer.ErrorTextFailedToDefineApp(
				CertificateApplicationResult.Error));
			Return False;
		EndIf;

		Parameters.CertificateApp = CertificateApplicationResult.Application;
	EndIf;
	
	CreationParameters = DigitalSignatureInternal.CryptoManagerCreationParameters();
	CreationParameters.Application = Parameters.CertificateApp;
	CreationParameters.ErrorDescription = New Structure;
	
	If Parameters.Operation = "Encryption" Then
		CreationParameters.EncryptAlgorithm = Parameters.EncryptAlgorithm;
	EndIf;
	
	CryptoManager = DigitalSignatureInternal.CryptoManager(Parameters.Operation, CreationParameters);
	
	ErrorAtServer = CreationParameters.ErrorDescription;
	If CryptoManager = Undefined Then
		Return False;
	EndIf;
	
	// If a personal crypto certificate is not used, it does not need to be searched for.
	If Parameters.Operation <> "Encryption"
	 Or ValueIsFilled(Parameters.ThumbprintOfCertificate) Then
		
		CryptoCertificate = DigitalSignatureInternal.GetCertificateByThumbprint(
			Parameters.ThumbprintOfCertificate, True, False, Parameters.CertificateApp, ErrorAtServer);
		
		If CryptoCertificate = Undefined Then
			Return False;
		EndIf;
	EndIf;
	
	If Parameters.Operation = "Signing" Then
		
		CertificateBinaryData = CryptoCertificate.Unload();
		
		CertificateProperties = DigitalSignatureInternalClientServer.CertificateProperties(
			CryptoCertificate, DigitalSignatureInternal.UTCOffset(), CertificateBinaryData);
		CertificateProperties.Insert("BinaryData", CertificateBinaryData);

		CertificateAlgorithm = DigitalSignatureInternalClientServer.CertificateSignAlgorithm(
			CertificateBinaryData, False, True);
		IsCorrespondingAlgorithm = DigitalSignatureInternalClientServer.SignAlgorithmCorrespondsToCertificate(
			CertificateProperties.Presentation, CertificateAlgorithm, CryptoManager.SignAlgorithm);

		If IsCorrespondingAlgorithm <> True Then

			ErrorAtServer.Insert("ErrorDescription", IsCorrespondingAlgorithm);
			Return False;

		EndIf;
	EndIf;
	
	Try
		Data = GetFromTempStorage(Parameters.DataItemForSErver.Data);
	Except
		ErrorInfo = ErrorInfo();
		ErrorAtServer.Insert("ErrorDescription",
			DigitalSignatureInternalClientServer.DataGettingErrorTitle(Parameters.Operation)
			+ Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo));
		Return False;
	EndTry;
	
	IsXMLDSig = (TypeOf(Data) = Type("Structure")
	            And Data.Property("XMLDSigParameters"));
	
	If IsXMLDSig And Not Data.Property("XMLEnvelope") Then
		Data = New Structure(New FixedStructure(Data));
		Data.Insert("XMLEnvelope", Data.SOAPEnvelope);
	EndIf;
	
	IsCMS = (TypeOf(Data) = Type("Structure")
	            And Data.Property("CMSParameters"));
	
	If IsXMLDSig Then
		
		If Parameters.Operation <> "Signing" Then
			ErrorAtServer.Insert("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Внешняя компонента %1 может использоваться только для подписания.';
					|en = '%1 add-in is intended for signing only.';"), "ExtraCryptoAPI"));
			Return False;
		EndIf;
		
		CryptoManager.PrivateKeyAccessPassword = Parameters.PasswordValue;
		Try
			ResultBinaryData = DigitalSignatureInternal.Sign(
				Data.XMLEnvelope,
				Data.XMLDSigParameters,
				CryptoCertificate,
				CryptoManager);
		Except
			ErrorInfo = ErrorInfo();
		EndTry;
		
	ElsIf IsCMS Then
		
		If Parameters.Operation <> "Signing" Then
			ErrorAtServer.Insert("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Внешняя компонента %1 может использоваться только для подписания.';
					|en = '%1 add-in is intended for signing only.';"), "ExtraCryptoAPI"));
			Return False;
		EndIf;
		
		CryptoManager.PrivateKeyAccessPassword = Parameters.PasswordValue;
		Try
			ResultBinaryData = DigitalSignatureInternal.SignCMS(
				Data.Data,
				Data.CMSParameters,
				CryptoCertificate,
				CryptoManager);
		Except
			ErrorInfo = ErrorInfo();
		EndTry;
	
	Else
		
		ErrorDescription = "";
		If Parameters.Operation = "Signing" Then
			CryptoManager.PrivateKeyAccessPassword = Parameters.PasswordValue;
			Try
				If DigitalSignature.AvailableAdvancedSignature() Then
					SettingsSignatures = DigitalSignatureInternalClientServer.SignatureCreationSettings(Parameters.SignatureType,
						DigitalSignature.CommonSettings().TimestampServersAddresses);
					If ValueIsFilled(SettingsSignatures.TimestampServersAddresses) Then
						CryptoManager.TimestampServersAddresses = SettingsSignatures.TimestampServersAddresses;
					EndIf;
					ResultBinaryData = CryptoManager.Sign(Data, CryptoCertificate,
						SettingsSignatures.SignatureType);
				Else
					ResultBinaryData = CryptoManager.Sign(Data, CryptoCertificate);
				EndIf;
				DigitalSignatureInternalClientServer.BlankSignatureData(ResultBinaryData, ErrorDescription);
			Except
				ErrorInfo = ErrorInfo();
			EndTry;
		ElsIf Parameters.Operation = "Encryption" Then
			Certificates = CryptoCertificates(Parameters.CertificatesAddress);
			Try
				ResultBinaryData = CryptoManager.Encrypt(Data, Certificates);
				DigitalSignatureInternalClientServer.BlankEncryptedData(ResultBinaryData, ErrorDescription);
			Except
				ErrorInfo = ErrorInfo();
			EndTry;
		Else // Decryption.
			CryptoManager.PrivateKeyAccessPassword = Parameters.PasswordValue;
			Try
				ResultBinaryData = CryptoManager.Decrypt(Data);
			Except
				ErrorInfo = ErrorInfo();
			EndTry;
		EndIf;
	
	EndIf;
	
	If ErrorInfo <> Undefined Then
		ErrorAtServer.Insert("ErrorDescription", ErrorProcessing.BriefErrorDescription(ErrorInfo));
		ErrorAtServer.Insert("Instruction", True);
		Return False;
	EndIf;
	
	If ValueIsFilled(ErrorDescription) Then
		ErrorAtServer.Insert("ErrorDescription", ErrorDescription);
		Return False;
	EndIf;
	
	OperationStarted = True;
	
	If Parameters.Operation = "Signing" Then
		
		If DigitalSignature.AvailableAdvancedSignature() Then
			SignatureProperties = DigitalSignatureInternal.SignaturePropertiesReadByCryptoManager(
				ResultBinaryData, CryptoManager, False);
				
			If SignatureProperties.Success = False Then
				
				SignatureData = Base64String(ResultBinaryData);
				ErrorPresentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '%1.
					|Результат подписи: %2';
					|en = '%1.
					|Signature result: %2';"), SignatureProperties.ErrorText, SignatureData);
				ErrorAtServer.Insert("ErrorDescription", ErrorPresentation);
				ErrorAtServer.Insert("Instruction", True);
				Return False;
				
			EndIf;
		Else
			SignatureProperties = DigitalSignatureInternal.SignaturePropertiesFromBinaryData(ResultBinaryData, False);
		EndIf;
		
		SignatureProperties = DigitalSignatureInternalClientServer.SignatureProperties(ResultBinaryData,
			CertificateProperties, Parameters.Comment, Users.AuthorizedUser(),,SignatureProperties);
			
		SignatureProperties.SignatureDate = ?(ValueIsFilled(SignatureProperties.UnverifiedSignatureDate),
			SignatureProperties.UnverifiedSignatureDate, CurrentSessionDate());
			
		If Parameters.CertificateValid <> Undefined Then
			SignatureProperties.SignatureValidationDate = SignatureProperties.SignatureDate;
			SignatureProperties.SignatureCorrect = Parameters.CertificateValid;
		EndIf;
		
		SignatureProperties.IsVerificationRequired = Parameters.IsVerificationRequired;
		
		ResultAddress = PutToTempStorage(SignatureProperties, Parameters.FormIdentifier);
		
		If Parameters.DataItemForSErver.Property("Object") Then
			ObjectVersion = Undefined;
			SignatureProperties.SignatureID = New UUID;
			Parameters.DataItemForSErver.Property("ObjectVersion", ObjectVersion);

			
			ErrorPresentation = AddSignature(Parameters.DataItemForSErver.Object,
				SignatureProperties, Parameters.FormIdentifier, ObjectVersion);
			If ValueIsFilled(ErrorPresentation) Then
				ErrorAtServer.Insert("ErrorDescription", ErrorPresentation);
				Return False;
			EndIf;
		EndIf;
	Else
		ResultAddress = PutToTempStorage(ResultBinaryData, Parameters.FormIdentifier);
	EndIf;
	
	Return True;
	
EndFunction

// For internal use only.
Function StartImprovementOnServer(Val Parameters) Export
	
	Signature = Parameters.DataItemForSErver.Signature;
	If TypeOf(Parameters.DataItemForSErver.Signature) = Type("String") Then
		Try
			Signature = GetFromTempStorage(Signature);
		Except
			Result = New Structure;
			Result.Insert("Success", False);
			Result.Insert("ErrorText", ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			Result.Insert("ErrorCreatingCryptoManager", False);
			Return Result;
		EndTry;
	EndIf;
	
	Parameters.DataItemForSErver.Signature = Signature;
	Parameters.Insert("ServiceAccountDSSSaddress", Parameters.ServiceAccountDSS);
	Parameters.ServiceAccountDSS = GetFromTempStorage(Parameters.ServiceAccountDSS);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(Parameters.FormIdentifier);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Усовершенствование подписи';
															|en = 'Enhance signature';");
	
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters, "DigitalSignatureInternal.EnhanceServerSide", Parameters);

EndFunction

// For internal use only.
Function EnhanceServerSide(Parameters) Export
	
	Return DigitalSignatureInternal.EnhanceServerSide(Parameters);
	
EndFunction

// For internal use only.
Function ServiceAccountSettingsToImproveSignatures(FormIdentifier = Undefined) Export
	
	Return DigitalSignatureInternal.ServiceAccountSettingsToImproveSignatures(FormIdentifier);
	
EndFunction

// For internal use only.
Function CertificateCustomSettings(Certificate) Export
	
	Result = New Structure;
	Result.Insert("IsNotified", True);
	Result.Insert("SigningAllowed", Undefined);
	Result.Insert("CertificateRef",  Undefined);
	
	If TypeOf(Certificate) = Type("BinaryData") Then // Thumbprint
		CertificateRef = CertificateRef(Base64String(Certificate), Undefined);
	ElsIf TypeOf(Certificate) = Type("String") Then
		CertificateRef = CertificateRef(Undefined, Certificate);
	Else
		CertificateRef = Certificate;
	EndIf;
	
	If CertificateRef = Undefined Then
		Return Result;
	EndIf;
	
	Result.SigningAllowed = Common.CommonSettingsStorageLoad(
		CertificateRef, "AllowSigning", Undefined);
	Result.IsNotified = InformationRegisters.CertificateUsersNotifications.UserAlerted(CertificateRef);
	Result.CertificateRef = CertificateRef;
	
	Return Result;
	
EndFunction

// See DigitalSignatureInternal.XMLEnvelopeProperties
Function XMLEnvelopeProperties(Val XMLEnvelope, Val XMLDSigParameters, Val CheckSignature) Export
	
	Return DigitalSignatureInternal.XMLEnvelopeProperties(XMLEnvelope, XMLDSigParameters, CheckSignature);
	
EndFunction

// For internal use only.
Function AddSignature(ObjectReference, SignatureProperties, FormIdentifier, ObjectVersion) Export
	
	DataElement = New Structure;
	DataElement.Insert("SignatureProperties",     SignatureProperties);
	DataElement.Insert("DataPresentation", ObjectReference);
	
	DigitalSignatureInternal.RegisterDataSigningInLog(DataElement);
	
	ErrorPresentation = "";
	Try
		DigitalSignature.AddSignature(ObjectReference, SignatureProperties, FormIdentifier, ObjectVersion);
	Except
		ErrorInfo = ErrorInfo();
		ErrorPresentation = NStr("ru = 'Не удалось записать подпись по причине:';
									|en = 'Cannot save the signature due to:';")
			+ Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo);
	EndTry;
	
	Return ErrorPresentation;
	
EndFunction

// For internal use only.
Function ConvertSignaturestoArray(Signatures, FormIdentifier) Export
	
	Array = New Array; 
	For Each CurrentItem In Signatures Do
		SetSignatures = DigitalSignature.SetSignatures(
			CurrentItem.SignedObject, CurrentItem.SequenceNumber);
		For Each CurrentSignature In SetSignatures Do
			If Not CurrentSignature.SignatureCorrect Then
				Continue;
			EndIf;
			Structure = New Structure("SignedObject, SequenceNumber, Signature, SignatureType, DateActionLastTimestamp");
			Structure.SignedObject = CurrentItem.SignedObject;
			Structure.SequenceNumber = CurrentSignature.SequenceNumber;
			Structure.Signature = PutToTempStorage(CurrentSignature.Signature, FormIdentifier);
			Array.Add(Structure);
		EndDo;
	EndDo;
	
	Return Array;
	
EndFunction

// For internal use only.
Procedure RegisterDataSigningInLog(DataElement) Export
	
	DigitalSignatureInternal.RegisterDataSigningInLog(DataElement);
	
EndProcedure

// For internal use only.
Procedure RegisterImprovementSignaturesInJournal(SignatureProperties) Export
	
	DigitalSignatureInternal.RegisterImprovementSignaturesInJournal(SignatureProperties);
	
EndProcedure

// For internal use only.
Function UpdateAdvancedSignature(SignatureProperties) Export
	
	Return DigitalSignatureInternal.UpdateAdvancedSignature(SignatureProperties);
	
EndFunction

// For the ExecuteAtServerSide function.
Function CryptoCertificates(Val CertificatesProperties)
	
	If TypeOf(CertificatesProperties) = Type("String") Then
		CertificatesProperties = GetFromTempStorage(CertificatesProperties);
	EndIf;
	
	Certificates = New Array;
	For Each Properties In CertificatesProperties Do
		Certificates.Add(New CryptoCertificate(Properties.Certificate));
	EndDo;
	
	Return Certificates;
	
EndFunction

Function InstalledCryptoProviders() Export
	
	Return DigitalSignatureInternal.InstalledCryptoProviders();
	
EndFunction

Function FindInstalledPrograms(ApplicationsDetails, CheckAtServer1) Export
	
	If CheckAtServer1 = Undefined Then
		CheckAtServer1 = DigitalSignature.VerifyDigitalSignaturesOnTheServer()
		                 Or DigitalSignature.GenerateDigitalSignaturesAtServer();
	EndIf;
	
	Programs = FillApplicationsListForSearch(ApplicationsDetails);
	
	If Not CheckAtServer1 Then
		Return Programs;
	EndIf;
	
	For Each Application In Programs Do
		CreationParameters = DigitalSignatureInternal.CryptoManagerCreationParameters();
		CreationParameters.Application = Application;
		CreationParameters.ErrorDescription = New Structure;
		Manager = DigitalSignatureInternal.CryptoManager("", CreationParameters);
		If Manager = Undefined Then
			Application.CheckResultAtServer =
				DigitalSignatureInternalClientServer.TextOfTheProgramSearchError(
					NStr("ru = 'Не установлена на сервере %1.';
						|en = 'Not installed on the %1 server.';"), CreationParameters.ErrorDescription);
		Else
			Application.CheckResultAtServer = "";
			Application.Use = True;
		EndIf;
	EndDo;
	
	Return Programs;
	
EndFunction

// Intended for: FindInstalledApplications procedure.
Function FillApplicationsListForSearch(ApplicationsDetails)
	
	SettingsToSupply = Catalogs.DigitalSignatureAndEncryptionApplications.ApplicationsSettingsToSupply();
	
	UpdatedApplicationsDetails = New Array;
	
	ExceptionsArray = New Array;
	ExceptionsArray.Add("Use");
	ExceptionsArray.Add("Ref");
	ExceptionsArray.Add("Id");
	ExceptionsArray.Add("CheckResultAtClient");
	ExceptionsArray.Add("CheckResultAtServer");
	
	For Each ApplicationDetails In ApplicationsDetails Do
		Filter = New Structure;
		Filter.Insert("ApplicationName", ApplicationDetails.ApplicationName);
		Filter.Insert("ApplicationType", ApplicationDetails.ApplicationType);
	
		Rows = SettingsToSupply.FindRows(Filter);
		If Rows.Count() = 0 Then
			NewApplicationDetails = ExtendedApplicationDetails();
			FillPropertyValues(NewApplicationDetails, ApplicationDetails);
			UpdatedApplicationsDetails.Add(NewApplicationDetails);
		Else
			For Each KeyAndValue In ApplicationDetails Do
				If ExceptionsArray.Find(KeyAndValue.Key) <> Undefined Then
					Continue;
				EndIf;
				If KeyAndValue.Value <> Undefined Then
					Rows[0][KeyAndValue.Key] = KeyAndValue.Value;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	ConfiguredApplicationsDetails = DigitalSignature.CommonSettings().ApplicationsDetailsCollection; // Array of See DigitalSignatureInternalCached.ApplicationDetails
	
	For Each ApplicationToSupply In SettingsToSupply Do
		ApplicationDetails = ExtendedApplicationDetails();
		FillPropertyValues(ApplicationDetails, ApplicationToSupply);
		
		For Each ConfiguredApplicationDetails In ConfiguredApplicationsDetails Do
			If ApplicationDetails.ApplicationName = ConfiguredApplicationDetails.ApplicationName
			   And ApplicationDetails.ApplicationType = ConfiguredApplicationDetails.ApplicationType Then
				ApplicationDetails.Ref = ConfiguredApplicationDetails.Ref;
				Break;
			EndIf;
		EndDo;
		UpdatedApplicationsDetails.Add(ApplicationDetails);
	EndDo;
	
	Return UpdatedApplicationsDetails;
	
EndFunction

// Intended for: FindInstalledApplications procedure.
Function ExtendedApplicationDetails()
	
	ApplicationDetails = DigitalSignature.NewApplicationDetails();
	ApplicationDetails.Insert("Ref", Undefined);
	ApplicationDetails.Insert("Id", Undefined);
	ApplicationDetails.Insert("Use", False);
	ApplicationDetails.Insert("CheckResultAtClient", "");
	ApplicationDetails.Insert("CheckResultAtServer", Undefined);
	
	Return ApplicationDetails;
	
EndFunction

Function WriteCertificateAfterCheck(Context) Export
	
	Return DigitalSignatureInternal.WriteCertificateAfterCheck(Context);
	
EndFunction

Function WriteCertificateToCatalog(Val Certificate, AdditionalParameters = Undefined) Export
	
	Return DigitalSignature.WriteCertificateToCatalog(Certificate, AdditionalParameters);
	
EndFunction

// For internal use only.
// 
// Parameters:
//  Thumbprint - String
//
Function DoWriteCertificateRevocationMark(Thumbprint) Export
	
	Return DigitalSignatureInternal.DoWriteCertificateRevocationMark(Thumbprint);
	
EndFunction

Function TheCloudSignatureServiceIsConfigured() Export
	
	Result = False;
	
	If Common.SubsystemExists("StandardSubsystems.DSSElectronicSignatureService") Then
	EndIf;
	
	Return Result;
	
EndFunction

Procedure EditMarkONReminder(Certificate, Remind, ReminderID) Export
	
	DigitalSignatureInternal.EditMarkONReminder(Certificate, Remind, ReminderID);
	
EndProcedure

Function AccreditedCertificationCenters() Export
	
	Return DigitalSignatureInternalCached.AccreditedCertificationCenters();
	
EndFunction

// For internal use only
Function AbbreviatedFileName(FileName, RequiredLength) Export
	
	Return Common.TrimStringUsingChecksum(FileName, RequiredLength);
	
EndFunction

// Looks up for individuals by description.
// 
// Parameters:
//   IssuedTo - Array of String
//             - String
//
// Returns:
//   Structure:
//     * Persons - See DigitalSignatureInternal.GetIndividualsByCertificateFieldIssuedTo
//     * IndividualChoiceFormPath - String
//
Function GetIndividualsByCertificateFieldIssuedTo(IssuedTo) Export

	Result = New Structure;

	If Not DigitalSignature.CommonSettings().IndividualUsed Then
		Return Result;
	EndIf;

	TypesIndividuals = Metadata.DefinedTypes.Individual.Type.Types();
	IndividualEmptyRef = New (TypesIndividuals[0]);
	
	Result.Insert("Persons", DigitalSignatureInternal.GetIndividualsByCertificateFieldIssuedTo(IssuedTo));
	Result.Insert("IndividualChoiceFormPath", Common.TableNameByRef(
		IndividualEmptyRef) + ".ChoiceForm");

	Return Result;

EndFunction

#Region DigitalSignatureDiagnostics

Function SupplementErrorClassifierSolutionWithDetails(Val ClassifierError,
	Val AdditionalData, Val ClassifierErrorSolutionTextSupplementOptionsAtClient, Val ErrorLocation = Undefined) Export
	
	Return DigitalSignatureInternal.SupplementErrorClassifierSolutionWithDetails(ClassifierError,
		AdditionalData, ClassifierErrorSolutionTextSupplementOptionsAtClient, ErrorLocation);
		
EndFunction

Function CertificateData(Certificate) Export
	
	Return Common.ObjectAttributeValue(Certificate, "CertificateData").Get();
	
EndFunction

Function ClassifierError(ErrorText) Export
	
	Return DigitalSignatureInternal.ClassifierError(ErrorText);
	
EndFunction

Function ReadAddInResponce(Text) Export
	
	Try
		Result = Common.JSONValue(Text);
	Except
		
		ErrorInfo = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		
		WriteLogEvent(
				NStr("ru = 'Электронная подпись.Работа с компонентой.';
					|en = 'Digital signature.Operations with add-in.';",
				Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось прочитать ответ компоненты: %1
					|%2';
					|en = 'Cannot read the add-in response: %1
					|%2';"), Text, ErrorInfo));
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось прочитать ответ компоненты: %1';
				|en = 'Cannot read the add-in response: %1';"), ErrorInfo);
		
	EndTry;
	
	Return Result;
	
EndFunction

Procedure AddADescriptionOfAdditionalData(AdditionalData, FilesDetails, InformationRecords) Export
	
	Text = "";
	
	Certificates = Undefined;
	AdditionalData.Property("Certificate", Certificates);
	
	If Certificates = Undefined Then
		AdditionalData.Property("CertificateData", Certificates);
	EndIf;
	
	If TypeOf(Certificates) = Type("Array") Then
		Number = 1;
		For Each Certificate In Certificates Do
			AddADescriptionOfTheCertificate(Certificate, FilesDetails, Text, Number);
			Number = Number + 1;
		EndDo;
	ElsIf Certificates <> Undefined Then
		AddADescriptionOfTheCertificate(Certificates, FilesDetails, Text, 1);
	EndIf;
	
	Signatures = Undefined;
	AdditionalData.Property("Signature", Signatures);
	
	If Signatures = Undefined Then
		AdditionalData.Property("SignatureData", Signatures);
	EndIf;
	
	If TypeOf(Signatures) = Type("Array") Then
		Number = 1;
		For Each Signature In Signatures Do
			AddASignatureDescription(Signature, FilesDetails, Text, Number);
			Number = Number + 1;
		EndDo;
	ElsIf Signatures <> Undefined Then
		AddASignatureDescription(Signatures, FilesDetails, Text, 1);
	EndIf;
	
	
	If ValueIsFilled(Text) Then
		InformationRecords = InformationRecords + Text + Chars.LF;
	EndIf;
	
EndProcedure

// Parameters:
//  Certificate - BinaryData
//             - String
//  FilesDetails - Array
//  InformationRecords - String
//  Number - Number
//
Procedure AddADescriptionOfTheCertificate(Certificate, FilesDetails, InformationRecords, Number)
	
	If TypeOf(Certificate) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates") Then
		AttributesValues = Common.ObjectAttributesValues(
			Certificate, "Description, Application, EnterPasswordInDigitalSignatureApplication, CertificateData");
		
		If TypeOf(AttributesValues.CertificateData) = Type("ValueStorage") Then
			CertificateData = AttributesValues.CertificateData.Get();
		Else
			CertificateData = Null;
		EndIf;
		CertificatePresentation = AttributesValues.Description;
	Else
		If TypeOf(Certificate) = Type("String") And IsTempStorageURL(Certificate) Then
			CertificateData = GetFromTempStorage(Certificate);
		Else
			CertificateData = Certificate;
		EndIf;
	EndIf;
	
	If TypeOf(CertificateData) = Type("BinaryData") Then
		If Not ValueIsFilled(CertificatePresentation) Then
			Try
				CryptoCertificate = New CryptoCertificate(CertificateData);
				CertificateProperties = DigitalSignature.CertificateProperties(CryptoCertificate);
				CertificatePresentation = CertificateProperties.Presentation;
			Except
				CertificatePresentation = "";
			EndTry;
		EndIf;
		Extension = "cer";
		SignAlgorithm = DigitalSignatureInternalClientServer.CertificateSignAlgorithm(
			CertificateData, True);
		CertificateData = GetBinaryDataFromString("-----BEGIN CERTIFICATE-----" + Chars.LF + Base64String(
			CertificateData) + Chars.LF + "-----END CERTIFICATE-----");
	Else
		Extension = "txt";
		XMLCertificateData = XMLString(New ValueStorage(CertificateData));
		CertificateData = GetBinaryDataFromString(XMLCertificateData, TextEncoding.ANSI, False);
		SignAlgorithm = "";
	EndIf;
	If Not ValueIsFilled(CertificatePresentation) Then
		CertificatePresentation = NStr("ru = 'Сертификат';
										|en = 'Certificate';") + Format(Number, "NG=");
	EndIf;
	
	CertificateFileName = DigitalSignatureInternalClientServer.CertificateFileName(CertificatePresentation, "", Extension);
	
	FileDetails = New Structure;
	FileDetails.Insert("Data", CertificateData);
	FileDetails.Insert("Name",    CertificateFileName);
	
	InformationRecords = InformationRecords + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Сертификат: ""%1""';
			|en = 'Certificate: ""%1""';"), CertificateFileName) + Chars.LF;
	
	InformationRecords = InformationRecords + StringFunctionsClientServer.SubstituteParametersToString(
		Chars.Tab + NStr("ru = 'Алгоритм подписи: %1';
							|en = 'Signature algorithm: %1';"), SignAlgorithm) + Chars.LF;
	
	If TypeOf(Certificate) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates") Then
		InformationRecords = InformationRecords + StringFunctionsClientServer.SubstituteParametersToString(
			Chars.Tab + NStr("ru = 'Программа: %1';
								|en = 'Application: %1';"), String(AttributesValues.Application)) + Chars.LF;
		
		InformationRecords = InformationRecords + StringFunctionsClientServer.SubstituteParametersToString(
			Chars.Tab + NStr("ru = 'Вводить пароль в приложении электронной подписи: %1';
								|en = 'Protect digital signing app with password: %1';"),
			?(AttributesValues.EnterPasswordInDigitalSignatureApplication = True, NStr("ru = 'Да';
																							|en = 'Yes';"), NStr("ru = 'Нет';
																											|en = 'No';"))) + Chars.LF;
	EndIf;
	
	FilesDetails.Add(FileDetails);
	
EndProcedure

// Parameters:
//  Signature - BinaryData
//          - String
//  FilesDetails - Array
//  Number - Number
//
Procedure AddASignatureDescription(Signature, FilesDetails, InformationRecords, Number)
	
	If TypeOf(Signature) = Type("String") And IsTempStorageURL(Signature) Then
		SignatureData = GetFromTempStorage(Signature);
	Else
		SignatureData = Signature;
	EndIf;
	
	If TypeOf(SignatureData) = Type("BinaryData") Then
		Extension = ".p7s";
		SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(
			SignatureData, True);
		HashAlgorithm = DigitalSignatureInternalClientServer.HashAlgorithm(
			SignatureData, True);
		SignatureData = GetBinaryDataFromString("-----BEGIN CMS-----" + Chars.LF + Base64String(SignatureData)
			+ Chars.LF + "-----END CMS-----");
	Else
		Extension = ".txt";
		XMLSignatureData = XMLString(New ValueStorage(SignatureData));
		SignatureData = GetBinaryDataFromString(XMLSignatureData, TextEncoding.ANSI, False);
		SignAlgorithm = "";
		HashAlgorithm = "";
	EndIf;
	
	SignatureFileName = DigitalSignatureInternalClientServer.PrepareStringForFileName(
		NStr("ru = 'Подпись';
			|en = 'Signature';") + Format(Number, "NG=")) + Extension;
	
	FileDetails = New Structure;
	FileDetails.Insert("Data", SignatureData);
	FileDetails.Insert("Name",    SignatureFileName);
	
	InformationRecords = InformationRecords + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Подпись: ""%1""';
			|en = 'Signature: ""%1""';"), SignatureFileName) + Chars.LF;
	
	InformationRecords = InformationRecords + StringFunctionsClientServer.SubstituteParametersToString(
		Chars.Tab + NStr("ru = 'Алгоритм подписи: %1';
							|en = 'Signature algorithm: %1';"), SignAlgorithm) + Chars.LF;
	
	InformationRecords = InformationRecords + StringFunctionsClientServer.SubstituteParametersToString(
		Chars.Tab + NStr("ru = 'Алгоритм хеширования: %1';
							|en = 'Hashing algorithm: %1';"), HashAlgorithm) + Chars.LF;
	
	FilesDetails.Add(FileDetails);
	
EndProcedure

// Returns:
//   Array of Structure:
//   * Ref - CatalogRef.DigitalSignatureAndEncryptionApplications
//   * Presentation - String
//
Function UsedApplications() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DigitalSignatureAndEncryptionApplications.Ref AS Ref,
	|	DigitalSignatureAndEncryptionApplications.Presentation AS Presentation,
	|	DigitalSignatureAndEncryptionApplications.ApplicationName AS ApplicationName,
	|	DigitalSignatureAndEncryptionApplications.ApplicationType AS ApplicationType,
	|	DigitalSignatureAndEncryptionApplications.SignAlgorithm AS SignAlgorithm,
	|	DigitalSignatureAndEncryptionApplications.HashAlgorithm AS HashAlgorithm,
	|	DigitalSignatureAndEncryptionApplications.EncryptAlgorithm AS EncryptAlgorithm,
	|	DigitalSignatureAndEncryptionApplications.UsageMode
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS DigitalSignatureAndEncryptionApplications
	|WHERE
	|	NOT DigitalSignatureAndEncryptionApplications.DeletionMark
	|	AND NOT DigitalSignatureAndEncryptionApplications.IsBuiltInCryptoProvider";
	
	Return Common.ValueTableToArray(Query.Execute().Unload());
	
EndFunction

Function TechnicalInformationArchiveAddress(
			Val AdditionalFiles, Val AccompanyingText = Undefined, Val VerifiedPathsToProgramModulesOnTheClient = Undefined) Export
	
	TemporaryFiles = New Array;
	InformationArchive = New ZipFileWriter();
	
	If TypeOf(AccompanyingText) = Type("String") Then
		DigitalSignatureInternal.SupplementWithTechnicalInformationAboutServer(AccompanyingText,
			VerifiedPathsToProgramModulesOnTheClient);
		StateText = New TextDocument;
		StateText.SetText(AccompanyingText);
		FileName = GetTempFileName("txt"); // ACC:441 - Temporary files are deleted downstream.
		StateText.Write(FileName);
		TemporaryFiles.Add(FileName);
		InformationArchive.Add(TemporaryFiles[0]);
	EndIf;
	
	TempDirectory = FileSystem.CreateTemporaryDirectory();
	
	If AdditionalFiles <> Undefined Then
		
		If TypeOf(AdditionalFiles) = Type("Array") Then
			For Each AdditionalFile In AdditionalFiles Do
				AddFileToArchive(InformationArchive, AdditionalFile,
					StateText, TempDirectory, TemporaryFiles);
			EndDo;
		Else
			AddFileToArchive(InformationArchive, AdditionalFiles,
				StateText, TempDirectory, TemporaryFiles);
		EndIf;
		
	EndIf;
		
	ArchiveAddress = PutToTempStorage(InformationArchive.GetBinaryData(),
		New UUID);
	
	For Each TempFile In TemporaryFiles Do
		FileSystem.DeleteTempFile(TempFile);
	EndDo;
	
	FileSystem.DeleteTemporaryDirectory(TempDirectory);
	
	Return ArchiveAddress;
	
EndFunction

Function TechnicalSupportLog()
	
	SelectionForMagazine = New Structure;
	SelectionForMagazine.Insert("Users", Users.CurrentUser());
	SelectionForMagazine.Insert("StartDate", CurrentSessionDate() - 10*60);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	TechnicalSupportLog = EventLog.TechnicalSupportLog(SelectionForMagazine, 100);
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	Return TechnicalSupportLog;
	
EndFunction

// Addresses of files containing technical information.
// 
// Returns:
//  Structure - Addresses of files containing technical information:
// * TechnicalInformation - String
// * EventLog - String
//
Function AddressesOfTechnicalInformationFiles(Val AccompanyingText,
			Val VerifiedPathsToProgramModulesOnTheClient) Export
	
	Addresses = New Structure("TechnicalInformation, EventLog");
	
	DigitalSignatureInternal.SupplementWithTechnicalInformationAboutServer(AccompanyingText,
		VerifiedPathsToProgramModulesOnTheClient);
	
	FileName = GetTempFileName("txt");
	
	StateText = New TextDocument;
	StateText.SetText(AccompanyingText);
	StateText.Write(FileName);
	
	FileAddress = PutToTempStorage(New BinaryData(FileName),
		New UUID);
	
	FileSystem.DeleteTempFile(FileName);
	Addresses.TechnicalInformation = FileAddress;
	Addresses.EventLog = TechnicalSupportLog();
	
	Return Addresses;
	
EndFunction

Procedure AddFileToArchive(Archive, FileInfo, StateText, TempDirectory, TemporaryFiles)
	
	Separator = GetPathSeparator();
	TempFile = TempDirectory
		+ ?(StrEndsWith(TempDirectory, Separator), "", Separator)
		+ FileInfo.Name;
	
	If TypeOf(FileInfo.Data) = Type("String") Then
		
		If IsTempStorageURL(FileInfo.Data) Then
			FileData = GetFromTempStorage(FileInfo.Data);
		Else
			StateText.AddLine(
				StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось добавить %1. Данные файла не являются двоичными данными или адресом во временном хранилище.';
					|en = 'Cannot add %1. The file data is not binary data or an address in the temporary storage.';"),
				FileInfo.Name));
		EndIf;
		
	Else
		FileData = FileInfo.Data;
	EndIf;
	
	If TypeOf(FileData) = Type("BinaryData") Then
		TemporaryFiles.Add(TempFile);
		FileData.Write(TempFile);
		Archive.Add(TempFile);
	EndIf;
	
EndProcedure

#EndRegion

Function StartDownloadFileAtServer(Parameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = Parameters.NameOfTheOperation;
	
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters, 
		"DigitalSignatureInternal.DownloadRevocationListFileAtServer", Parameters.ResourceAddress, Parameters.InternalAddress);
	
EndFunction


Function TimestampServersDiagnosticsResult() Export
		
	TimestampServersAddresses = DigitalSignature.CommonSettings().TimestampServersAddresses;
	
	If TimestampServersAddresses.Count() = 0 Then
		Return NStr("ru = 'Адреса серверов меток времени не заполнены в настройках электронной подписи.';
					|en = 'The addresses of timestamp servers are unfilled in digital signature settings.';");
	Else
		StringForConnection = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Подключение к серверам меток времени на сервере <%1>.';
						|en = 'Accessing timestamp servers on server <%1>.';"), ComputerName());
		
		Return DigitalSignatureInternalClientServer.TimestampServersDiagnostics(TimestampServersAddresses, StringForConnection);
	EndIf;
	
EndFunction

#EndRegion