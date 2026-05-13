///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Internal

// For internal use only.
// Verifies the cryptographic certificate.
// Intended only for operation using 1C:Enterprise tools (CryptoManager).
//
// Parameters:
//   CryptoManager - Undefined - get the crypto manager automatically.
//                        - CryptoManager - use the specified crypto manager.
//
//   Certificate           - CryptoCertificate - Certificate.
//                        - BinaryData - certificate binary data.
//                        - String - Temp storage address that contains certificate binary data.
//
//   ErrorDescription       - Null - raise an exception if an error occurs during the check.
//                        - String - Contains error details (if occurred).
//
//   OnDate               - Date - check the certificate on the specified date.
//                          If parameter is not specified or a blank date is specified,
//                          check on the current session date.
//   AdditionalVerificationParameters_ - See AdditionalCertificateVerificationParameters
//
// Returns:
//  Boolean - True if the check is completed successfully.
//           False if the cryptographic manager is not received (because it is not specified).
//
Function CheckCertificate(CryptoManager, Certificate, ErrorDescription = Null, OnDate = Undefined, AdditionalVerificationParameters_ = Undefined) Export
	
	RaiseException1 = ErrorDescription = Null;
	CryptoManagerToCheck = CryptoManager;
	
	CertificateToCheck = Certificate;
	
	If TypeOf(Certificate) = Type("String") Then
		CertificateToCheck = GetFromTempStorage(Certificate);
	EndIf;
	
	If TypeOf(CertificateToCheck) = Type("BinaryData") Then
		CertificateData = CertificateToCheck;
		CertificateToCheck = New CryptoCertificate(CertificateToCheck);
	Else
		CertificateData = CertificateToCheck.Unload();
	EndIf;
	
	If CryptoManagerToCheck = Undefined Then
		UseDigitalSignatureSaaS =
			UseDigitalSignatureSaaS();
		
		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.ShowError = RaiseException1 And Not UseDigitalSignatureSaaS;
		If TypeOf(CertificateData) = Type("BinaryData") Then
			CreationParameters.SignAlgorithm =
				DigitalSignatureInternalClientServer.CertificateSignAlgorithm(CertificateData);
		EndIf;
		
		CryptoManagerToCheck = CryptoManager(
			"CertificateCheck", CreationParameters);
		
		If CryptoManagerToCheck = Undefined Then
			ErrorDescription = CreationParameters.ErrorDescription;
			
			If Not UseDigitalSignatureSaaS Then
				Return False;
			EndIf;
		EndIf;
	EndIf;
	
	AdditionalParameters = AdditionalCertificateVerificationParameters();
	If AdditionalVerificationParameters_ <> Undefined Then
		FillPropertyValues(AdditionalParameters, AdditionalVerificationParameters_);
		
		If TypeOf(AdditionalParameters.PerformCAVerification) = Type("Boolean") Then // Intended for compatibility purposes.
			AdditionalParameters.PerformCAVerification = ?(
				AdditionalParameters.PerformCAVerification,
				DigitalSignatureInternalClientServer.VerifyQualified(), 
				DigitalSignatureInternalClientServer.NotVerifyCertificate());
		EndIf;
		
		ExpectedValues = New Array;
		ExpectedValues.Add(DigitalSignatureInternalClientServer.VerifyQualified());
		ExpectedValues.Add(DigitalSignatureInternalClientServer.QualifiedOnly());
		ExpectedValues.Add(DigitalSignatureInternalClientServer.NotVerifyCertificate());
		CommonClientServer.CheckParameter("DigitalSignatureInternal.CheckCertificate",
			"AdditionalVerificationParameters_.PerformCAVerification", AdditionalParameters.PerformCAVerification,
			Type("String"),, ExpectedValues);
	EndIf;
	
	CertificateCheckModes = DigitalSignatureInternalClientServer.CertificateCheckModes(
		ValueIsFilled(OnDate), AdditionalParameters.IgnoreCertificateRevocationStatus);
	
	If CryptoManagerToCheck = Undefined
	 Or CryptoManagerToCheck = "CryptographyService" Then
		
		ModuleCryptographyService = Common.CommonModule("CryptographyService");
		CheckParameters = DigitalSignatureInternalClientServer.CertificateVerificationParametersInTheService(
			DigitalSignature.CommonSettings(), CertificateCheckModes);
		Try
			If CheckParameters <> Undefined Then
				// ACC:287-off - No.640. It's acceptable to call a non-existent CTL procedure.
				// It's checked against CTL v.2.0.3, where the procedure exists.
				Result = ModuleCryptographyService.VerifyCertificateWithParameters(CertificateData, CheckParameters);
				// ACC:287-on
			Else
				Result = ModuleCryptographyService.CheckCertificate(CertificateData);
			EndIf;
		Except
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			If RaiseException1 Then
				Raise;
			EndIf;
			Return False;
		EndTry;
		If Not Result Then
			ErrorDescription = DigitalSignatureInternalClientServer.ServiceErrorTextCertificateInvalid();
			If RaiseException1 Then
				Raise ErrorDescription;
			EndIf;
			Return False;
		EndIf;
	Else
		ValidationResult = ValidateCertificate(CryptoManagerToCheck, CertificateToCheck, 
			CertificateCheckModes, ErrorDescription, RaiseException1);
		If Not ValidationResult Then
			If RaiseException1 Then
				Raise ErrorDescription;
			EndIf;
			Return False;
		EndIf;
	EndIf;
	
	OverdueError = DigitalSignatureInternalClientServer.CertificateOverdue(CertificateToCheck,
		OnDate, UTCOffset());
	
	If ValueIsFilled(OverdueError) Then
		ErrorDescription = OverdueError;
		If RaiseException1 Then
			Raise ErrorDescription;
		EndIf;
		Return False;
	EndIf;
	
	CertificateProperties = Undefined;
	If AdditionalParameters.ToVerifySignature Then
		
		CertificateProperties = DigitalSignatureInternalClientServer.CertificateProperties(
			CertificateToCheck, UTCOffset(), CertificateData);
			
		OverdueError = DigitalSignatureInternalClientServer.PrivateKeyExpired(CertificateProperties, OnDate);

		If ValueIsFilled(OverdueError) Then
			ErrorDescription = OverdueError;
			If RaiseException1 Then
				Raise ErrorDescription;
			EndIf;
			Return False;
		EndIf;
	EndIf;
	
	If AdditionalParameters.PerformCAVerification <> DigitalSignatureInternalClientServer.NotVerifyCertificate() Then
		
		CertificateAuthorityVerificationParameters = New Structure;
		CertificateAuthorityVerificationParameters.Insert("ThisVerificationSignature", AdditionalParameters.ToVerifySignature);
		CertificateAuthorityVerificationParameters.Insert("VerifyCertificate", AdditionalParameters.PerformCAVerification);
		
		Result = ResultofCertificateAuthorityVerification(CertificateToCheck, OnDate,
			CertificateAuthorityVerificationParameters, CertificateProperties);
		
		If Not Result.Valid_SSLyf Or ValueIsFilled(AdditionalParameters.Certificate) And ValueIsFilled(Result.Warning.ErrorText)
				And Not AdditionalParameters.ToVerifySignature Then
			
			CertificateCustomSettings = DigitalSignatureInternalServerCall.CertificateCustomSettings(
					CertificateToCheck.Thumbprint);

			If Not Result.Valid_SSLyf Then
				
				If CertificateCustomSettings.SigningAllowed <> True Then
					ErrorDescription = Result.Warning.ErrorText;
					AdditionalParameters.Warning = Result.Warning;
					AdditionalParameters.Certificate = CertificateCustomSettings.CertificateRef;
					If RaiseException1 Then
						Raise ErrorDescription;
					EndIf;
					Return False;
				EndIf;
				
			EndIf;

			If ValueIsFilled(AdditionalParameters.Certificate) 
			And ValueIsFilled(Result.Warning.ErrorText)
				And Not AdditionalParameters.ToVerifySignature Then
				
				If CertificateCustomSettings.IsNotified
					Or CertificateCustomSettings.CertificateRef = Undefined Then
					AdditionalParameters.Warning = Undefined;
				Else
					AdditionalParameters.Warning = Result.Warning;
					AdditionalParameters.Certificate = CertificateCustomSettings.CertificateRef;
				EndIf;
			EndIf;
			
		EndIf;
	EndIf;
	
	If RaiseException1 Then
		ErrorDescription = Null;
	Else
		ErrorDescription = "";
	EndIf;
	
	Return True;
	
EndFunction

Function AdditionalCertificateVerificationParameters() Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("PerformCAVerification", DigitalSignatureInternalClientServer.QualifiedOnly());
	AdditionalParameters.Insert("ToVerifySignature", False);
	AdditionalParameters.Insert("IgnoreCertificateRevocationStatus", False);
	AdditionalParameters.Insert("Warning");
	AdditionalParameters.Insert("Certificate");
	
	Return AdditionalParameters;
	
EndFunction

// For internal use only.
Function Encrypt(Data, Certificate, CryptoManager) Export

	ErrorDescription = "";

	Try
		ResultBinaryData = CryptoManager.Encrypt(Data, Certificate);
		DigitalSignatureInternalClientServer.BlankEncryptedData(ResultBinaryData, ErrorDescription);
	Except
		ErrorDescription = ErrorInfo();
	EndTry;
	
	If ValueIsFilled(ErrorDescription) Then
		Raise ErrorDescription;
	EndIf;
	
	Return ResultBinaryData;

EndFunction

// For internal use only.
Function EncryptInCloudSignatureService(Data, Certificate, Account = Undefined) Export
	
	If UseCloudSignatureService() Then

		TheDSSCryptographyServiceModule = Common.CommonModule("DSSCryptographyService");
		
		If Account = Undefined Then
			DSSAccountResult = TheDSSCryptographyServiceModule.ServiceAccountConnectionSettings();
			If Not DSSAccountResult.Completed2 Then
				Raise  StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Сервис DSS:
					|%1';
					|en = 'DSS service:
					|%1';"), DSSAccountResult.Error);
			EndIf;
			DSSAccount = DSSAccountResult.Result;
		Else
			DSSAccount = Account;
		EndIf;
		
		ErrorDescription = "";
		Try
			Result = TheDSSCryptographyServiceModule.Encrypt(
						DSSAccount, Data, Certificate, "CMS");
			If Result.Completed2 Then
				ResultBinaryData = Result.Result;
				DigitalSignatureInternalClientServer.BlankEncryptedData(ResultBinaryData, ErrorDescription);
			Else
				ErrorDescription = Result.Error;
			EndIf;
		Except
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;

	Else
		ErrorDescription = NStr("ru = 'Не настроен сервис DSS.';
								|en = 'DSS service is not configured.';");
	EndIf;
	
	If ValueIsFilled(ErrorDescription) Then
		Raise  StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Сервис DSS:
					|%1';
					|en = 'DSS service:
					|%1';"), ErrorDescription);
	EndIf;
		
	Return ResultBinaryData;
	
EndFunction

// For internal use only.
Function EncryptByBuiltInCryptoProvider(Data, Certificate) Export

	If UseDigitalSignatureSaaS() Then
		ModuleCryptographyService = Common.CommonModule("CryptographyService");
		ErrorDescription = "";
		Try
			ResultBinaryData = ModuleCryptographyService.Encrypt(Data, Certificate);
			DigitalSignatureInternalClientServer.BlankEncryptedData(ResultBinaryData, ErrorDescription);
		Except
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
	Else
		ErrorDescription = NStr("ru = 'Не настроен встроенный криптопровайдер.';
								|en = 'The built-in cryptographic service provider is not configured.';");
	EndIf;
	
	If ValueIsFilled(ErrorDescription) Then
		Raise  StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Встроенный криптопровайдер:
					|%1';
					|en = 'Built-in cryptographic service provider:
					|%1';"), ErrorDescription);
	EndIf;
		
	Return ResultBinaryData;
	
EndFunction

// Adds certificates to the passed object.
Procedure AddEncryptionCertificates(ObjectRef, ThumbprintsArray) Export
	SetPrivilegedMode(True);
	
	SequenceNumber = 1;
	For Each ThumbprintStructure In ThumbprintsArray Do
		RecordManager = InformationRegisters.EncryptionCertificates.CreateRecordManager();
		RecordManager.EncryptedObject = ObjectRef;
		RecordManager.Thumbprint = ThumbprintStructure.Thumbprint;
		RecordManager.Presentation = ThumbprintStructure.Presentation;
		RecordManager.Certificate = New ValueStorage(ThumbprintStructure.Certificate);
		RecordManager.SequenceNumber = SequenceNumber;
		SequenceNumber = SequenceNumber + 1;
		RecordManager.Write();
	EndDo;

EndProcedure

// Clears records about encryption certificates after object decryption.
Procedure ClearEncryptionCertificates(ObjectRef) Export
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.EncryptionCertificates.CreateRecordSet();
	RecordSet.Filter.EncryptedObject.Set(ObjectRef);
	RecordSet.Write(True);

EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - ClientApplicationForm
//  SignaturesListName - String
//
Procedure RegisterSignaturesList(Form, SignaturesListName) Export
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(SignaturesListName);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(SignaturesListName + ".SignatureCorrect");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
EndProcedure

// Returns the details of files with data, signatures, and LOAs, extracted from the signing result.
// The result is returned in the notification specified in  See DigitalSignatureClient.Sign.ResultProcessing. 
// . In the array, a file of the Data type is followed by its signature. 
// 
// Parameters:
//  SigningResult - See DigitalSignatureClient.Sign.DataDetails
//  FilesReceiptParameters - Structure
//   * ExportCertificate - Boolean
//   * ExportLOA - Boolean
//   * ExportCertificate - Boolean
//   * ExportLOA - Boolean
//  UUID - UUID - Intended for storing in a temporary storage.
// 
// Returns:
//  Array of Structure:
//   * Data   - String - Address in the temporary storage. Depending on how it was passed to See DigitalSignatureClient.Sign.DataDetails.
//              - BinaryData 
//   * FileName - String 
//   * FileType - String - "Data", "Signature", "LetterOfAuthority", "LetterOfAuthoritySignature", "Certificate".
//
Function GetFilesFromSigningResult(SigningResult, FilesReceiptParameters, UUID) Export
	
	If SigningResult.Property("DataSet") Then
		DataSet = SigningResult.DataSet;
	Else
		DataSet = CommonClientServer.ValueInArray(SigningResult);
	EndIf;
	
	SignatureFilesExtension = DigitalSignature.PersonalSettings().SignatureFilesExtension;
	
	Result = New Array;
	
	
	CertificateFileDetailsStructure = Undefined;
		
	For Each SignedFile In DataSet Do
		
		SignatureProperties = SignedFile.SignatureProperties;
		If IsTempStorageURL(SignatureProperties) Then
			SignatureProperties = GetFromTempStorage(SignatureProperties);
		EndIf;
		
		File = New File(SignedFile.Presentation);
		
		If FilesReceiptParameters.ExportCertificate And CertificateFileDetailsStructure = Undefined Then
			
			CertificateData = PutToTempStorage(SignatureProperties.Certificate, UUID);
			CertificateOwner = ?(ValueIsFilled(SignatureProperties.CertificateOwner), SignatureProperties.CertificateOwner, NStr("ru = 'Сертификат';
																																		|en = 'Certificate';"));
			If FilesReceiptParameters.TransliterateFilesNames Then
				CertificateOwner = StringFunctions.LatinString(CertificateOwner);
			EndIf;

			CertificateFileName = DigitalSignatureInternalClientServer.CertificateFileName(
				"", CertificateOwner, "cer", False);

			CertificateFileDetailsStructure = New Structure("Data, FileName, FileType");
			CertificateFileDetailsStructure.Data = CertificateData;
			CertificateFileDetailsStructure.FileName = CertificateFileName;
			CertificateFileDetailsStructure.FileType = "Certificate";
			
		EndIf;
		
		StructureOfFileDetails = New Structure("Data, FileName, FileType");
		StructureOfFileDetails.Data = SignedFile.Data;
		StructureOfFileDetails.FileName = SignedFile.Presentation;
		StructureOfFileDetails.FileType = "Data";
		Result.Add(StructureOfFileDetails);
		
		SignatureData = PutToTempStorage(SignatureProperties.Signature, UUID);
		SignatureFileName = DigitalSignatureInternalClientServer.SignatureFileName(File.BaseName,
				CertificateOwner, SignatureFilesExtension);
		
		StructureOfFileDetails = New Structure("Data, FileName, FileType");
		StructureOfFileDetails.Data = SignatureData;
		StructureOfFileDetails.FileName = SignatureFileName;
		StructureOfFileDetails.FileType = "Signature";
		Result.Add(StructureOfFileDetails);
	
	EndDo;
	
	If CertificateFileDetailsStructure <> Undefined Then
		Result.Add(CertificateFileDetailsStructure);
	EndIf;
	
	Return Result;
	
EndFunction

Function FilesReceiptParameters() Export
	
	Structure = New Structure;
	Structure.Insert("TransliterateFilesNames", False);
	Structure.Insert("ExportCertificate", True);
	Structure.Insert("ExportLOA", True);
	
	Return Structure;
	
EndFunction


// Determines digital signature availability for an object (by its type)
// 
// Parameters:
//  ObjectType - Type
// 
// Returns:
//  Boolean - Electronic signature is available.
//
Function DigitalSignatureAvailable(ObjectType) Export
	
	Return DigitalSignatureInternalCached.OwnersTypes().Get(ObjectType) <> Undefined;
	
EndFunction

// Returns a certificate address in the temporary storage and its extension.
//
// Parameters:
//  DigitalSignatureInfo - Structure - a string with signatures from the array received by the DigitalSIgnature.SetSignatures method.
//  UUID     - UUID - a form ID.
// 
// Returns:
//  Structure:
//   * CertificateExtension - String - a certificate file extension.
//   * CertificateAddress      - String - an address in the temporary storage, by which the certificate was placed.
//
Function DataByCertificate(DigitalSignatureInfo, UUID) Export
	
	Result = New Structure("CertificateExtension, CertificateAddress");
	CertificateData = DigitalSignatureInfo.Certificate.Get();
		
		If TypeOf(CertificateData) = Type("String") Then
			Result.CertificateExtension = "txt";
			Result.CertificateAddress = PutToTempStorage(
				RowBinaryData(CertificateData), UUID);
		Else
			Result.CertificateExtension = "cer";
			Result.CertificateAddress = PutToTempStorage(
				CertificateData, UUID);
		EndIf;
		
	Return Result;
	
EndFunction

// Returns the capability flag of interactive use of digital signatures and encryption 
// for the current user.
//
// Returns:
//  Boolean - if True, you can use digital signatures and encryption interactively.
//
Function InteractiveUseofElectronicSignaturesandEncryption() Export
	
	Return AccessRight("View", Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates);
	
EndFunction

// Names of the data files and names of their signatures are extracted from the passed file names.
// Mapping is executed according to the signature name generation and signature file extension rules (p7s).
// For example:
//  The data file name is "example.txt"
//  the signature file name is "example-Ivanov Petr.p7s"
//  the signature file name is "example-Ivanov Petr (1).p7s".
//
// Parameters:
//  FilesNames - Array - file names of the Row type.
//
// Returns:
//  Map of KeyAndValue:
//   * Key     - String - a file name.
//   * Value - Array - signature file names of the Row type.
// 
Function SignaturesFilesNamesOfDataFilesNames(FilesNames) Export
	
	SignatureFilesExtension = DigitalSignature.PersonalSettings().SignatureFilesExtension;
	
	Result = New Map;
	
	// Dividing files by extension.
	DataFilesNames = New Array;
	SignatureFilesNames = New Array;
	
	For Each FileName In FilesNames Do
		If StrEndsWith(FileName, SignatureFilesExtension) Then
			SignatureFilesNames.Add(FileName);
		Else
			DataFilesNames.Add(FileName);
		EndIf;
	EndDo;
	
	// Sorting data file names by their length in characters, descending.
	
	For IndexA = 1 To DataFilesNames.Count() Do
		IndexMAX = IndexA; // Assume that the current file has the maximum number of characters.
		For IndexB = IndexA+1 To DataFilesNames.Count() Do
			If StrLen(DataFilesNames[IndexMAX-1]) > StrLen(DataFilesNames[IndexB-1]) Then
				IndexMAX = IndexB;
			EndIf;
		EndDo;
		swap = DataFilesNames[IndexA-1];
		DataFilesNames[IndexA-1] = DataFilesNames[IndexMAX-1];
		DataFilesNames[IndexMAX-1] = swap;
	EndDo;
	
	// Searching for file name mapping.
	For Each DataFileName In DataFilesNames Do
		Result.Insert(DataFileName, FindSignatureFilesNames(DataFileName, SignatureFilesNames));
	EndDo;
	
	// The remaining signature files are not recognized as signatures related to a specific file.
	For Each SignatureFileName In SignatureFilesNames Do
		Result.Insert(SignatureFileName, New Array);
	EndDo;
	
	Return Result;
	
EndFunction

// For internal use only.
// 
// Parameters:
//  CertificatesData - Array of BinaryData
// 
// Returns:
//  Array of BinaryData - Certificates up to the root one.
//
Function CertificatesInOrderToRoot(CertificatesData) Export
	
	By_Order = New Array;
	CertificatesDetails = New Map;
	CertificatesBySubjects = New Map;
	
	For Each CertificateData In CertificatesData Do
		Certificate = New CryptoCertificate(CertificateData);
		By_Order.Add(CertificateData);
		CertificatesDetails.Insert(Certificate, CertificateData);
		CertificatesBySubjects.Insert(
			DigitalSignatureInternalClientServer.IssuerKey(Certificate.Subject),
			CertificateData);
	EndDo;
	
	For Counter = 1 To By_Order.Count() Do
		HasChanges = False;
		DigitalSignatureInternalClientServer.SortCertificates(
			By_Order, CertificatesDetails, CertificatesBySubjects, HasChanges); 
		If Not HasChanges Then
			Break;
		EndIf;
	EndDo;
		
	Return By_Order;

EndFunction

// For internal use only.
// 
// Parameters:
//  CryptoCertificate
//  OnDate - Undefined, Date
//  CheckParameters - Structure
//   * VerifyCertificate - String - "QualifiedOnly", "VerifyQualified", "DoNotVerifyCertificate".
//   * VerifyCertificate - String - "QualifiedOnly", "VerifyQualified", "DoNotVerifyCertificate". 
//  CertificateProperties - See DigitalSignature.CertificateProperties
// 
// Returns:
//   See DigitalSignatureInternalClientServer.DefaultCAVerificationResult
//
Function ResultofCertificateAuthorityVerification(CryptoCertificate, OnDate = Undefined, 
	Val CheckParameters = Undefined, CertificateProperties = Undefined) Export
	
	Result = DigitalSignatureInternalClientServer.DefaultCAVerificationResult();
	

	Return Result;
	
EndFunction

// For internal use only.
Procedure EditMarkONReminder(Certificate, Remind, ReminderID) Export
	
	CurrentUser = Users.CurrentUser();
	
	UserRemindersAvailable = False;
	If Common.SubsystemExists("StandardSubsystems.UserReminders") Then
		ModuleUserReminder = Common.CommonModule("UserReminders");
		UserRemindersAvailable = ModuleUserReminder.UsedUserReminders();
	EndIf;
	
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.CertificateUsersNotifications.CreateRecordSet();
	RecordSet.Filter.Certificate.Set(Certificate);
	RecordSet.Filter.User.Set(CurrentUser); 
	
	Record = RecordSet.Add();
	Record.Certificate = Certificate;
	Record.User = CurrentUser;
	Record.IsNotified = Not Remind;
	If UserRemindersAvailable Then
		RecordSet.AdditionalProperties.Insert("ReminderID", ReminderID);
	EndIf;
	RecordSet.Write();
	
	SetPrivilegedMode(False);
	
EndProcedure

// For internal use only.
Procedure ChangeRegulatoryTaskExtensionCredibilitySignatures(RefineSignaturesAutomatically = Undefined,
	AddTimestampsAutomatically = Undefined, CryptoSignatureTypeDefault = Undefined) Export

	JobParameters = New Structure;
	JobParameters.Insert("Metadata", Metadata.ScheduledJobs.ExtendSignatureValidity);
	If Common.DataSeparationEnabled() Then
		JobParameters.Insert("MethodName", Metadata.ScheduledJobs.ExtendSignatureValidity.MethodName);
	EndIf;
	
	If RefineSignaturesAutomatically = Undefined Then
		RefineSignaturesAutomatically = Constants.RefineSignaturesAutomatically.Get();
	EndIf;
	
	If AddTimestampsAutomatically = Undefined Then
		AddTimestampsAutomatically = Constants.AddTimestampsAutomatically.Get();
	EndIf;
	
	If RefineSignaturesAutomatically = 1 And CryptoSignatureTypeDefault = Undefined Then
		CryptoSignatureTypeDefault = Constants.CryptoSignatureTypeDefault.Get();
	EndIf;
		
	If Not Common.DataSeparationEnabled() Then
		Use = AddTimestampsAutomatically 
			Or RefineSignaturesAutomatically = 1 
				And (CryptoSignatureTypeDefault = Enums.CryptographySignatureTypes.WithTimeCAdEST
					Or CryptoSignatureTypeDefault = Enums.CryptographySignatureTypes.ArchivalCAdESAv3)
	Else
		// In SaaS, can be upgraded only to CAdES-T.
		Use = RefineSignaturesAutomatically = 1 
				And CryptoSignatureTypeDefault = Enums.CryptographySignatureTypes.WithTimeCAdEST;
	EndIf;
	
	SetPrivilegedMode(True);
	
	JobsList = ScheduledJobsServer.FindJobs(JobParameters);
	If JobsList.Count() = 0 Then
		JobParameters.Insert("Use", Use);
		ScheduledJobsServer.AddJob(JobParameters);
	Else
		JobParameters = New Structure("Use", Use);
		For Each Job In JobsList Do
			ScheduledJobsServer.ChangeJob(Job, JobParameters);
		EndDo;
	EndIf;

EndProcedure

// For the form of the Administration subsystem's common settings.
// 
// Parameters:
//  Form - ClientApplicationForm - 
//  DataPathAttribute - String - Attribute data path that was modified in the form.
//
Procedure ConfigureCommonSettingsForm(Form, DataPathAttribute) Export
	
	Items = Form.Items;
	ConstantsSet = Form.ConstantsSet;
	CommonSettings = DigitalSignature.CommonSettings();
	AvailableAdvancedSignature = CommonSettings.AvailableAdvancedSignature;
	
	If Common.DataSeparationEnabled() 
		And (DataPathAttribute = "ConstantsSet.UseDigitalSignature"
			Or DataPathAttribute = "ConstantsSet.UseEncryption"
			Or DataPathAttribute = "ConstantsSet.UseDSSService"
			Or DataPathAttribute = "") Then
				
		Items.VerifyDigitalSignaturesOnTheServer.Visible = UseCloudSignatureService()
			Or UseDigitalSignatureSaaS();
		
	EndIf;

	If DataPathAttribute = "ConstantsSet.UseDigitalSignature" Or DataPathAttribute
		= "ConstantsSet.UseEncryption" Or DataPathAttribute = "" Then

		Items.DigitalSignatureAndEncryptionSettings.Enabled = ConstantsSet.UseDigitalSignature
			Or ConstantsSet.UseEncryption;
		Items.GroupAdvancedSignature.Enabled = ConstantsSet.UseDigitalSignature;
		Items.CheckSignaturesAtServerGroup.Enabled = ConstantsSet.UseDigitalSignature
			Or ConstantsSet.UseEncryption;

		If ConstantsSet.UseDigitalSignature And (DataPathAttribute
			= "ConstantsSet.UseDigitalSignature" Or DataPathAttribute = "") Then
			If AvailableAdvancedSignature Then
				Form.ConstantTimestampServersAddresses = StrConcat(CommonSettings.TimestampServersAddresses, Chars.LF);
				Form.ConstantRefineSignaturesAutomatically = Constants.RefineSignaturesAutomatically.Get();
				Form.ConstantAddTimestampsAutomatically = Constants.AddTimestampsAutomatically.Get();
				Form.ConstantRefineSignaturesDates = Constants.RefineSignaturesDates.Get();
				SignatureType = Constants.CryptoSignatureTypeDefault.Get();
				Form.ConstantCryptoSignatureTypeDefault = SignatureType;
				SetHeaderTipsImprovements(Form, SignatureType);
			EndIf;
			If Items.GenerateDigitalSignaturesAtServer.Visible Then
				Form.ConstantGenerateDigitalSignaturesAtServer = Constants.GenerateDigitalSignaturesAtServer.Get();
			EndIf;
			If Items.VerifyDigitalSignaturesOnTheServer.Visible Then
				Form.ConstantVerifyDigitalSignaturesOnTheServer = Constants.VerifyDigitalSignaturesOnTheServer.Get();
			EndIf;
		EndIf;
		
		SetHeaderElectronicSignatureOnServer(Form);
		
	ElsIf (DataPathAttribute = "ConstantCryptoSignatureTypeDefault" Or DataPathAttribute
		= "ConstantRefineSignaturesAutomatically") And AvailableAdvancedSignature Then
		
		Form.ConstantRefineSignaturesAutomatically = Constants.RefineSignaturesAutomatically.Get();
		SignatureType = Constants.CryptoSignatureTypeDefault.Get();
		Form.ConstantCryptoSignatureTypeDefault = SignatureType;
		SetHeaderTipsImprovements(Form, SignatureType);
		
	EndIf;

	If Common.SubsystemExists("StandardSubsystems.DSSElectronicSignatureService")
	 And AvailableAdvancedSignature
		And (DataPathAttribute = "ConstantsSet.UseDSSService" Or DataPathAttribute = "") Then

		If Common.DataSeparationEnabled() Then
			
			ThisistheServiceModelwithEnhancementAvailable = CommonSettings.ThisistheServiceModelwithEnhancementAvailable;
			Items.GroupAutomaticProcessingSignatures.Visible = ThisistheServiceModelwithEnhancementAvailable;
			Items.GroupAddLabelsAutomatically.Visible = False;
			Items.CryptoSignatureTypeDefault.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
			If ThisistheServiceModelwithEnhancementAvailable Then
				Items.CryptoSignatureTypeDefault.Visible = True;
				Items.CryptoSignatureTypeDefault1.Visible = False;
				
				FillListSignatureTypesCryptography(
					Items.CryptoSignatureTypeDefault.ChoiceList, "Settings");
				Items.CryptoSignatureTypeDefaultExtendedTooltip.Title = StringFunctions.FormattedString(
						NStr(
					"ru = 'В приложении в Интернете архивная подпись по умолчанию недоступна, этот тип подписи можно выбрать при подписании <a href=%1>сертификатом</a>, установленным на компьютер с помощью <a href=Программы>приложения электронной подписи</a>.';
					|en = 'In the web app, archival signatures are unavailable by default. You can select this signature type when signing with a <a href=%1>certificate</a> installed on the computer with a <a href=Программы>digital signing app</a>.';"), "Certificates");
			Else
				Items.CryptoSignatureTypeDefault.Visible = False;
				Items.CryptoSignatureTypeDefault1.Visible = True;
				Items.CryptoSignatureTypeDefault1ExtendedTooltip.Title = StringFunctions.FormattedString(
						NStr(
					"ru = 'В приложении в Интернете по умолчанию установлен тип подписи Базовая, типы подписи с метками времени можно выбрать при подписании <a href=%1>сертификатом</a>, установленным на компьютер с помощью <a href=Программы>приложения электронной подписи</a>.';
					|en = 'In the web app, the default signature type is ""Basic"". You can select signature types with timestamps when signing with a href=%1>certificate</a> installed on the computer with a <a href=Программы>digital signing app</a>.';"), "Certificates");
			EndIf;
			
		Else
			
			FillListSignatureTypesCryptography(
					Items.CryptoSignatureTypeDefault.ChoiceList, "Settings");
			Items.CryptoSignatureTypeDefault.ToolTipRepresentation = ToolTipRepresentation.None;
			Items.CryptoSignatureTypeDefault.Visible = True;
			Items.CryptoSignatureTypeDefault1.Visible = False;
			
		EndIf;
	Else
		
		Items.CryptoSignatureTypeDefault.ToolTipRepresentation = ToolTipRepresentation.None;
		
		If DataPathAttribute = "" And AvailableAdvancedSignature Then
			Items.CryptoSignatureTypeDefault.Visible = True;
			Items.CryptoSignatureTypeDefault1.Visible = False;
			FillListSignatureTypesCryptography(
					Items.CryptoSignatureTypeDefault.ChoiceList, "Settings");
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns a selection of individuals' certificates.
// 
// Parameters:
//  Persons - Array of DefinedType.Individual
// 
// Returns:
//   QueryResultSelection:
//     * Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//     * Individual - DefinedType.Individual
//
Function CertificatesOfIndividuals(Persons) Export

	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	DigitalSignatureAndEncryptionKeysCertificates.Ref AS Certificate,
	|	DigitalSignatureAndEncryptionKeysCertificates.Individual AS Individual
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS DigitalSignatureAndEncryptionKeysCertificates
	|WHERE
	|	DigitalSignatureAndEncryptionKeysCertificates.Individual IN(&IndividualsArray)
	|	AND NOT DigitalSignatureAndEncryptionKeysCertificates.DeletionMark
	|	AND DigitalSignatureAndEncryptionKeysCertificates.ValidBefore > &CurrentSessionDate";

	Query.SetParameter("IndividualsArray", Persons);
	Query.SetParameter("CurrentSessionDate", CurrentSessionDate());
	QueryResult = Query.Execute();

	Return QueryResult.Select();

EndFunction

// Returns a selection of individuals' (users') certificates.
// 
// Parameters:
//  Users - Array of CatalogRef.Users
// 
// Returns:
//   QueryResultSelection:
//     * Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//     * User - CatalogRef.Users
//
Function CertificatesOfIndividualsUsers(Users) Export

	Query = New Query;
	Query.Text = "SELECT ALLOWED
	|	DigitalSignatureAndEncryptionKeysCertificates.Ref AS Certificate,
	|	UsersCatalog.Ref AS User
	|FROM
	|	Catalog.Users AS UsersCatalog
	|		INNER JOIN Catalog.DigitalSignatureAndEncryptionKeysCertificates AS
	|			DigitalSignatureAndEncryptionKeysCertificates
	|		ON (DigitalSignatureAndEncryptionKeysCertificates.Individual = UsersCatalog.Individual
	|		AND UsersCatalog.Ref IN (&UsersArray)
	|		AND UsersCatalog.Individual <> &EmptyIndividual
	|		AND NOT DigitalSignatureAndEncryptionKeysCertificates.DeletionMark
	|		AND DigitalSignatureAndEncryptionKeysCertificates.ValidBefore > &CurrentSessionDate)";

	
	If DigitalSignature.CommonSettings().IndividualUsed Then
		TypesIndividuals = Metadata.DefinedTypes.Individual.Type.Types();
		Query.SetParameter("EmptyIndividual", New (TypesIndividuals[0]));
	Else
		Query.SetParameter("EmptyIndividual", "");
	EndIf;

	Query.SetParameter("CurrentSessionDate", CurrentSessionDate());
	Query.SetParameter("UsersArray", Users);
	QueryResult = Query.Execute();

	Return QueryResult.Select();

EndFunction

// Returns a value indicating whether it is possible (depending on the app locale) 
// to display a link to the guide with the app common issues.
// 
// Returns:
//  Boolean
//
Function VisibilityOfRefToAppsTroubleshootingGuide() Export
	
	URL = "";
	DigitalSignatureClientServerLocalization.OnDefiningRefToAppsTroubleshootingGuide(
		URL);
	Return Not IsBlankString(URL);
	
EndFunction

Function GetAddInData(TemplateName) Export
	Return Catalogs.DigitalSignatureAndEncryptionKeysCertificates.GetTemplate(TemplateName);
EndFunction

Function TimestampServerAddressesByDefault() Export
	
	If Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined Then
		Return DataProcessors["DigitalSignatureAndEncryptionApplications"].TimestampServerAddressesByDefault();
	EndIf;
	
	Return "";
	
EndFunction

Function CheckSignaturesByMachineReadableLOA(Signatures, SignedObject) Export

	If Not Common.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		Return New Array;
	EndIf;

	ChecksResults = New Array;
	DigitalSignatureLocalization.OnVerifySignaturesOnMRLOA(Signatures, SignedObject, ChecksResults);
	Return ChecksResults;

EndFunction

#Region SuppliedData

// See SuppliedDataOverridable.GetHandlersForSuppliedData
Procedure OnDefineSuppliedDataHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.DataKind = "CryptoError3";
	Handler.HandlerCode = "CryptoError";
	Handler.Handler = DigitalSignatureInternal;
	
EndProcedure

// The procedure is called when a new data notification is received.
// In the procedure body, check whether the app requires this data. 
// If it requires, select the Import check box.
// 
// Parameters:
//   Descriptor - XDTODataObject
//   ToImport - Boolean - If True, run import. Otherwise, False.
//
Procedure NewDataAvailable(Val Descriptor, ToImport) Export
	
	ToImport = Descriptor.DataType = "CryptoError3";
	
EndProcedure

// The procedure is called after calling NewDataAvailable, it parses the data.
//
// Parameters:
//   Descriptor - XDTODataObject
//   PathToFile - String - Full name of the extracted file. 
//                  The file is automatically deleted once the procedure is completed.
//                  If a file is not specified, it is set to Undefined.
//
Procedure ProcessNewData(Val Descriptor, Val PathToFile) Export
	
	If Descriptor.DataType = "CryptoError3" Then
		WriteClassifierData(New BinaryData(PathToFile));
	EndIf;
	
EndProcedure

// The procedure is called if data processing is canceled due to an error.
//
// Parameters:
//   Descriptor - XDTODataObject
//
Procedure DataProcessingCanceled(Val Descriptor) Export 
	
EndProcedure

#EndRegion

#Region CloudSignature

// Determines the availability of the cloud signature subsystem
//
// Returns:
//  Boolean
//
Function UseCloudSignatureService() Export
	
	Result = False;
	
	
	Return Result;
	
EndFunction

// Determines the type of the cloud signature app.
//
// Returns:
//  Undefined 
//  Type
//
Function ServiceProgramTypeSignatures() Export
	
	Result = Undefined;
	
	
	Return Result;
	
EndFunction

#EndRegion

#Region ConfigurationSubsystemsEventHandlers

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "Catalogs.DigitalSignatureAndEncryptionApplications.FillInitialSettings";
	Handler.ExecutionMode = "Exclusively";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.6.20";
	Handler.Procedure = "DigitalSignatureInternal.ReplaceRoleAddingChangeElectronicSignaturesAndEncryption";
	Handler.ExecutionMode = "Seamless";
	
	If Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined Then
		Handler = Handlers.Add();
		Handler.Version = "3.1.6.69";
		Handler.Comment = NStr("ru = 'Обновление сведений о приложениях электронной подписи и шифрования.';
										|en = 'Updating info on digital signing and encryption apps.';");
		Handler.Procedure = "DataProcessors.DigitalSignatureAndEncryptionApplications.UpdateNameOfBuiltInCryptoprovider";
		Handler.ExecutionMode = "Seamless";
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.6.128";
	Handler.InitialFilling = True;
	Handler.Comment = NStr("ru = 'Заполнение настроек для усовершенствования подписей.';
									|en = 'Fill in settings for signature enhancement.';");
	Handler.Procedure = "DigitalSignatureInternal.FillinSettingsToImproveSignatures";
	Handler.ExecutionMode = "Seamless";
	
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.8.58";
	Handler.Comment =
		NStr("ru = 'Устанавливает режим использования для приложений электронной подписи и шифрования.';
			|en = 'Sets the usage mode for digital signature and encryption apps.';");
	Handler.Id = New UUID("ddaf9603-7641-470b-93cc-8754c9a64a99");
	Handler.Procedure = "Catalogs.DigitalSignatureAndEncryptionApplications.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs.DigitalSignatureAndEncryptionApplications.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead      = "Catalog.DigitalSignatureAndEncryptionApplications";
	Handler.ObjectsToChange    = "Catalog.DigitalSignatureAndEncryptionApplications";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.9.122";
	Handler.Comment = NStr("ru = 'Удаление путей из заполненных имен файлов подписей. Заполнение идентификатора подписи в регистре Электронные подписи.';
									|en = 'Delete paths from filled in signature file names. Populate the signature ID in the ""Digital signatures"" register.';");
	Handler.Id = New UUID("927d1ffb-682a-474d-b3ea-5a40fd20ff08");
	Handler.Procedure = "InformationRegisters.DigitalSignatures.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "InformationRegisters.DigitalSignatures.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead      = "InformationRegister.DigitalSignatures";
	Handler.ObjectsToChange    = "InformationRegister.DigitalSignatures";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";

	Handler = Handlers.Add();
	Handler.Version = "3.1.10.185";
	Handler.Comment = NStr(
		"ru = 'Перенос оповещений об окончании срока действия сертификата, данных заявлений в регистры сведений, заполнение срока действия сертификата с учетом срока действия закрытого ключа, очистка некорректно выбранного приложения электронной подписи.';
		|en = 'Transfer certificate expiration notifications and certificate application data to information registers. Fill in the certificate validity period considering the validity period of the private key. Discard digital signing apps selected by mistake.';");
	Handler.Id = New UUID("a6c42e6b-4824-4f5e-a35d-aa0922b253f3");
	Handler.Procedure = "Catalogs.DigitalSignatureAndEncryptionKeysCertificates.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs.DigitalSignatureAndEncryptionKeysCertificates.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead      = "Catalog.DigitalSignatureAndEncryptionKeysCertificates";
	ObjectsToChange = New Array;
	ObjectsToChange.Add("Catalog.DigitalSignatureAndEncryptionKeysCertificates");
	ObjectsToChange.Add("InformationRegister.CertificateUsersNotifications");
	If Metadata.InformationRegisters.Find("CertificateIssuanceApplications") <> Undefined Then
		ObjectsToChange.Add("InformationRegister.CertificateIssuanceApplications");
	EndIf;
	Handler.ObjectsToChange = StrConcat(ObjectsToChange, ",");
	Handler.ObjectsToLock = "Catalog.DigitalSignatureAndEncryptionKeysCertificates";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
EndProcedure

// See CommonOverridable.OnAddMetadataObjectsRenaming.
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	Library = "StandardSubsystems";
	
	OldName = "Role.UsingEDS";
	NewName  = "Role.UsingItemInstance";
	Common.AddRenaming(Total, "2.2.1.7", OldName, NewName, Library);
	
	OldName = "Subsystem.StandardSubsystems.Subsystem.DigitalSignature1";
	NewName  = "Subsystem.StandardSubsystems.Subsystem.DigitalSignature";
	Common.AddRenaming(Total, "2.2.1.7", OldName, NewName, Library);
	
	OldName = "Role.UsingItemInstance";
	NewName  = "Role.UseOfElectronicSignatureAndEncryption";
	Common.AddRenaming(Total, "2.3.1.10", OldName, NewName, Library);
	
	OldName = "Role.UseOfElectronicSignatureAndEncryption";
	NewName  = "Role.AddEditDigitalSignaturesAndEncryption";
	Common.AddRenaming(Total, "2.3.3.2", OldName, NewName, Library);
	
EndProcedure

// See CommonOverridable.OnAddClientParameters.
Procedure OnAddClientParameters(Parameters) Export
	
	If Common.SeparatedDataUsageAvailable() Then
		SubsystemSettings = New Structure;
		SubsystemSettings.Insert("PersonalSettings", DigitalSignature.PersonalSettings());
		SubsystemSettings.Insert("CommonSettings",        DigitalSignature.CommonSettings());
		SubsystemSettings = New FixedStructure(SubsystemSettings);
		Parameters.Insert("DigitalSignature", SubsystemSettings);
	EndIf;
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplateList.
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add(Metadata.ScheduledJobs.ExtendSignatureValidity.Name);
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases.
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.ExtendSignatureValidity.MethodName);
	
	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.OnDefineHandlerAliases(NamesAndAliasesMap)
	EndIf;
	
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport.
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	// Cannot import to the DigitalSignatureAndEncryptionApplications catalog.
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.DigitalSignatureAndEncryptionApplications.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
	// Cannot import to the DigitalSignatureAndEncryptionKeysCertificates catalog.
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.DigitalSignatureAndEncryptionApplications.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates.FullName(), "AttributesToSkipInBatchProcessing");
EndProcedure

// Overrides shared data exceptions for the SaaSTechnology subsystem 
// 
// Parameters:
//  Exceptions - Array of MetadataObject - Exceptions.
//
Procedure OnDefineSharedDataExceptions(Exceptions) Export

	Exceptions.Add(Metadata.InformationRegisters.CertificateRevocationLists);
	
EndProcedure

// See GetAddInsSaaSOverridable.OnDefineAddInsVersionsToUse.
Procedure OnDefineAddInsVersionsToUse(IDs) Export

	IDs.Add(DigitalSignatureInternalClientServer.ComponentDetails().ObjectName);

EndProcedure

// See SSLSubsystemsIntegration.OnDefineUsedAddIns.
Procedure OnDefineUsedAddIns(Components) Export

	NewRow = Components.Add();
	NewRow.Id = DigitalSignatureInternalClientServer.ComponentDetails().ObjectName;
	NewRow.AutoUpdate = True;
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
Procedure OnDefineScheduledJobSettings(Settings) Export

	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
			ProcessingApplicationForNewQualifiedCertificateIssue.OnDefineScheduledJobSettings(Settings);
	EndIf;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ExtendSignatureValidity;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseDigitalSignature;
	
EndProcedure

// See ClassifiersOperationsOverridable.OnAddClassifiers.
Procedure OnAddClassifiers(Classifiers) Export
	
	If Metadata.CommonModules.Find("DigitalSignatureInternalLocalization") = Undefined Then
		Return;
	EndIf;
	
	LongDesc = Undefined;
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		LongDesc = ModuleClassifiersOperations.ClassifierDetails();
	EndIf;
	If LongDesc = Undefined Then
		Return;
	EndIf;

	LongDesc.Id = ClassifierID();
	LongDesc.Description = NStr("ru = 'Список аккредитованных удостоверяющих центров';
								|en = 'List of accredited certificate authorities';");
	LongDesc.AutoUpdate = True;
	LongDesc.SharedData = True;
	LongDesc.SharedDataProcessing = False;
	LongDesc.SaveFileToCache = False;
	
	Classifiers.Add(LongDesc);
	
EndProcedure

// See ClassifiersOperationsOverridable.OnImportClassifier.
Procedure OnImportClassifier(Id, Version, Address, Processed, AdditionalParameters) Export
	
	If Id <> ClassifierID() Then
		Return;
	EndIf;
	
	If Metadata.CommonModules.Find("DigitalSignatureInternalLocalization") = Undefined Then
		Processed = True;
		Return;
	EndIf;
	
	ModuleDigitalSignatureInternalLocalization = Common.CommonModule("DigitalSignatureInternalLocalization");
	ModuleDigitalSignatureInternalLocalization.UploadDataAccreditedCA(Version, Address, Processed, AdditionalParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// ToDoList subsystem event handlers.

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Users.IsExternalUserSession() Then
		Return;
	EndIf;
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.CommonForms.DigitalSignatureAndEncryptionSettings.FullName());
	
	If DigitalSignature.ManageAlertsCertificates() Then
		
		NumberofCertificatesWithexpiringValidity = NumberofCertificatesWithexpiringValidity(); 
		
		For Each Section In Sections Do
			ToDoItem = ToDoList.Add ();
			ToDoItem.Id  = "CertificateRenewalRequired";
			ToDoItem.HasToDoItems       = NumberofCertificatesWithexpiringValidity > 0;
			ToDoItem.Presentation  = NStr("ru = 'Требуется продление сертификата';
										|en = 'Certificate needs to be renewed';");
			ToDoItem.Count     = NumberofCertificatesWithexpiringValidity;
			ToDoItem.Important         = False;
			ToDoItem.Form          = "CommonForm.DigitalSignatureAndEncryptionSettings";
			ToDoItem.FormParameters = New Structure("CertificatesShow", "MyCertificatesWithexpiringValidity");
			ToDoItem.Owner       = Section;
		EndDo;
		
		If DigitalSignature.CommonSettings().CertificateIssueRequestAvailable Then
			
			NumberofApplicationsInProgress = NumberofApplicationsInProgress();
			
			For Each Section In Sections Do
				ToDoItem = ToDoList.Add();
				ToDoItem.Id  = "CertificateIssuanceApplicationsInProgress";
				ToDoItem.HasToDoItems       = NumberofApplicationsInProgress > 0;
				ToDoItem.Presentation  = NStr("ru = 'Заявления на выпуск сертификата в работе';
											|en = 'Submitted certificate applications';");
				ToDoItem.Count     = NumberofApplicationsInProgress;
				ToDoItem.Important         = False;
				ToDoItem.Form          = "CommonForm.DigitalSignatureAndEncryptionSettings";
				ToDoItem.FormParameters = New Structure("CertificatesShow", "MyStatementsInProgress");
				ToDoItem.Owner       = Section;
			EndDo;
			
		EndIf;
		
	EndIf;
	
	If DigitalSignature.AvailableAdvancedSignature() Then
		RefineSignaturesAutomatically = Constants.RefineSignaturesAutomatically.Get();
		
		If RefineSignaturesAutomatically = 2 Then
			
			Numberofsignaturesforimprovements = SignaturesCount("RequireImprovementSignatures");
			For Each Section In Sections Do
				ToDoItem = ToDoList.Add ();
				ToDoItem.Id  = "RequireImprovementSignatures";
				ToDoItem.HasToDoItems       = Numberofsignaturesforimprovements > 0;
				ToDoItem.Presentation  = NStr("ru = 'Усовершенствовать подписи';
											|en = 'Enhance signatures';");
				ToDoItem.Count     = Numberofsignaturesforimprovements;
				ToDoItem.Important         = False;
				ToDoItem.Form          = "CommonForm.RenewDigitalSignatures";
				ToDoItem.FormParameters = New Structure("ExtensionMode", "RequireImprovementSignatures");
				ToDoItem.Owner       = Section;
			EndDo;
			
			NumberofRawSignatures = SignaturesCount("rawsignatures");
			For Each Section In Sections Do
				ToDoItem = ToDoList.Add ();
				ToDoItem.Id  = "rawsignatures";
				ToDoItem.HasToDoItems       = NumberofRawSignatures > 0;
				ToDoItem.Presentation  = NStr("ru = 'Продлить ранее добавленные подписи';
											|en = 'Renew previously added signatures';");
				ToDoItem.Count     = NumberofRawSignatures;
				ToDoItem.Important         = False;
				ToDoItem.Form          = "CommonForm.RenewDigitalSignatures";
				ToDoItem.FormParameters = New Structure("ExtensionMode", "rawsignatures");
				ToDoItem.Owner       = Section;
			EndDo;
			
		ElsIf RefineSignaturesAutomatically = 1 Or Constants.AddTimestampsAutomatically.Get() Then
			
			NumberofErrorsonAutomaticRenewal = SignaturesCount("ErrorsOnAutoRenewal");
			For Each Section In Sections Do
				ToDoItem = ToDoList.Add ();
				ToDoItem.Id  = "ErrorsOnAutoRenewal";
				ToDoItem.HasToDoItems       = NumberofErrorsonAutomaticRenewal > 0;
				ToDoItem.Presentation  = NStr("ru = 'Ошибки при автоматическом продлении подписей';
											|en = 'Automatic signature renewal errors';");
				ToDoItem.Count     = NumberofErrorsonAutomaticRenewal;
				ToDoItem.Important         = True;
				ToDoItem.Form          = "CommonForm.RenewDigitalSignatures";
				ToDoItem.FormParameters = New Structure("ExtensionMode", "ErrorsOnAutoRenewal");
				ToDoItem.Owner       = Section;
			EndDo;
			
		EndIf;
		
		Numberofsignaturestoaddarchivaltags = SignaturesCount("RequiredAddArchiveTags");
		For Each Section In Sections Do
			ToDoItem = ToDoList.Add ();
			ToDoItem.Id  = "RequiredAddArchiveTags";
			ToDoItem.HasToDoItems       = Numberofsignaturestoaddarchivaltags > 0;
			ToDoItem.Presentation  = NStr("ru = 'Продлить архивные подписи';
										|en = 'Renew archival signatures';");
			ToDoItem.Count     = Numberofsignaturestoaddarchivaltags;
			ToDoItem.Important         = False;
			ToDoItem.Form          = "CommonForm.RenewDigitalSignatures";
			ToDoItem.FormParameters = New Structure("ExtensionMode", "RequiredAddArchiveTags");
			ToDoItem.Owner       = Section;
		EndDo;
		
	EndIf;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Event handlers of the ReportsOptions subsystem.

// See ReportsOptionsOverridable.CustomizeReportsOptions.
Procedure OnSetUpReportsOptions(Settings) Export
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.RenewDigitalSignatures);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.DigitalSignatureCertificates);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// For internal use only.
// 
// Parameters:
//  ContainerSignatures - CryptoSignaturesContainer
//  UTCOffset - Number
//  SessionDate - Date
// 
// Returns:
//  Structure - Cryptographic signature parameters:
//   * SignatureType          - EnumRef.CryptographySignatureTypes
//   * DateActionLastTimestamp - Date, Undefined - Filled only using the cryptographic manager.
//   * DateSignedFromLabels - Date, Undefined - Date of the earliest timestamp.
//   * UnverifiedSignatureDate - Date - Unconfirmed signature data.
//                                 - Undefined - Unconfirmed signature data is missing from the signature data.
//   * DateLastTimestamp - Date - Date of the latest timestamp.
//   * Certificate   - CryptoCertificate - Signatory's certificate.
//   * CertificateDetails - See DigitalSignatureClient.CertificateProperties.
//
Function ParametersCryptoSignatures(ContainerSignatures, UTCOffset, SessionDate) Export

	SignatureParameters = DigitalSignatureInternalClientServer.NewSettingsSignaturesCryptography();
		
	Signature = ContainerSignatures.Signatures[0];
	
	IsCertificateExists = DigitalSignatureInternalClientServer.IsCertificateExists(Signature.SignatureCertificate);
	
	If IsCertificateExists Then
		SignatureParameters.Certificate = Signature.SignatureCertificate;
		SignatureParameters.CertificateDetails = DigitalSignature.CertificateProperties(Signature.SignatureCertificate);
	EndIf;
	
	Return DigitalSignatureInternalClientServer.ParametersCryptoSignatures(SignatureParameters, Signature, IsCertificateExists, UTCOffset, SessionDate);
	
EndFunction

// Obtains signature properties from the signature data. If the Cryptography service failed to obtain the properties, 
// it returns the properties read from the binary data.
// 
// Returns:
//   See DigitalSignatureInternalClientServer.ResultOfReadSignatureProperties
//   Map - If a signature array is passed.
//
Function SignatureProperties(Signatures, ShouldReadCertificates, UseCryptoManager = True) Export
	
	If TypeOf(Signatures) = Type("String") Or TypeOf(Signatures) = Type("BinaryData") Then
		SignaturesArray = CommonClientServer.ValueInArray(Signatures);
		Map = Undefined;
	Else
		SignaturesArray = Signatures;
		Map = New Map;
	EndIf;
	
	IsReadingByCryptoManager = UseCryptoManager 
		And (DigitalSignature.CommonSettings().VerifyDigitalSignaturesOnTheServer
			Or DigitalSignature.CommonSettings().GenerateDigitalSignaturesAtServer
			Or Common.FileInfobase());
	
	For Each Signature In SignaturesArray Do
	
		Result = DigitalSignatureInternalClientServer.ResultOfReadSignatureProperties();

		If IsReadingByCryptoManager Then
			ErrorDescription = "";
			CryptoManager = DigitalSignature.CryptoManager("ReadSignature", False, ErrorDescription,
				Signature); // CryptoManager
			If CryptoManager = Undefined Then
				Result.ErrorText = ErrorDescription;
			Else
				Result = SignaturePropertiesReadByCryptoManager(Signature, CryptoManager, ShouldReadCertificates);
				If Result.Success = True Then
					If Map = Undefined Then
						Return Result;
					Else
						Map.Insert(Signature, Result);
						Continue;
					EndIf;
				Else
					Result.Success = Undefined;
				EndIf;
			EndIf;
		EndIf;
		
		SignaturePropertiesFromBinaryData = SignaturePropertiesFromBinaryData(Signature, ShouldReadCertificates);
		FillPropertyValues(Result, SignaturePropertiesFromBinaryData, , "Success, ErrorText");

		If SignaturePropertiesFromBinaryData.Success = False Then
			Result.Success = False;
			Result.ErrorText = ?(IsBlankString(Result.ErrorText), "", Result.ErrorText + Chars.LF)
				+ SignaturePropertiesFromBinaryData.ErrorText;
		EndIf;
		
		If Map = Undefined Then
			Return Result;
		Else
			Map.Insert(Signature, Result);
		EndIf;
	
	EndDo;
	
	Return Map;
	
EndFunction

Function SignaturePropertiesReadByCryptoManager(Signature, CryptoManager, ShouldReadCertificates) Export
	
	Result = DigitalSignatureInternalClientServer.ResultOfReadSignatureProperties();
	
	BinaryData = DigitalSignatureInternalClientServer.BinaryDataFromTheData(Signature,
		"DigitalSignatureInternal.SignaturePropertiesReadByCryptoManager");
	
	Try
		ContainerSignatures = CryptoManager.GetCryptoSignaturesContainer(BinaryData);
	Except
		Result.Success = False;
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'При чтении данных подписи: %1';
						|en = 'When reading the signature data: %1';"), ErrorProcessing.BriefErrorDescription(
					ErrorInfo()));
		Return Result;
	EndTry;

	ParametersCryptoSignatures = ParametersCryptoSignatures(
						ContainerSignatures, UTCOffset(), CurrentSessionDate());

	Result.SignatureType = ParametersCryptoSignatures.SignatureType;
	Result.DateActionLastTimestamp = ParametersCryptoSignatures.DateActionLastTimestamp;
	Result.UnverifiedSignatureDate = ParametersCryptoSignatures.UnverifiedSignatureDate;
	Result.DateSignedFromLabels = ParametersCryptoSignatures.DateSignedFromLabels;
	If ParametersCryptoSignatures.CertificateDetails <> Undefined Then
		Result.Thumbprint = ParametersCryptoSignatures.CertificateDetails.Thumbprint;
		Result.CertificateOwner = ParametersCryptoSignatures.CertificateDetails.IssuedTo;
	EndIf;

	If ShouldReadCertificates Then
		SignatureRow = ContainerSignatures.Signatures[0];
		If DigitalSignatureInternalClientServer.IsCertificateExists( 
					SignatureRow.SignatureCertificate) Then
			Result.Certificate = SignatureRow.SignatureCertificate.Unload();
		EndIf;
		For Each Certificate In SignatureRow.SignatureVerificationCertificates Do
			If DigitalSignatureInternalClientServer.IsCertificateExists(Certificate) Then
				Result.Certificates.Add(Certificate.Unload());
			EndIf;
		EndDo;
	EndIf;

	Result.Success = True;
	Return Result;
	
EndFunction

Function SignaturePropertiesFromBinaryData(Signature, ShouldReadCertificates) Export
	
	Result = DigitalSignatureInternalClientServer.ResultOfReadSignatureProperties();
	
	Try
		SignaturePropertiesFromBinaryData = DigitalSignatureInternalClientServer.SignaturePropertiesFromBinaryData(
			Signature, UTCOffset(), ShouldReadCertificates);
		If Not ValueIsFilled(SignaturePropertiesFromBinaryData.SignatureType) Then
			Result.ErrorText = NStr("ru = 'Данные не являются подписью';
										|en = 'The data is not a signature.';");
			Result.Success = False;
			Return Result;
		EndIf;
	Except
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось прочитать свойства подписи: %1';
				|en = 'Cannot read the signature properties: %1';"), ErrorProcessing.BriefErrorDescription(
			ErrorInfo()));
		Return Result;
	EndTry;

	Result.SignatureType = SignaturePropertiesFromBinaryData.SignatureType;

	If ValueIsFilled(SignaturePropertiesFromBinaryData.SigningDate) Then
		Result.UnverifiedSignatureDate = SignaturePropertiesFromBinaryData.SigningDate;
	EndIf;
	If ValueIsFilled(SignaturePropertiesFromBinaryData.DateOfTimeStamp) Then
		Result.DateSignedFromLabels = SignaturePropertiesFromBinaryData.DateOfTimeStamp;
	EndIf;

	If SignaturePropertiesFromBinaryData.Certificates.Count() > 0 Then
		
		If SignaturePropertiesFromBinaryData.Certificates.Count() > 1 Then
			Try
				Result.Certificates = CertificatesInOrderToRoot(
					SignaturePropertiesFromBinaryData.Certificates);
				Result.Certificate = Result.Certificates[0];
			Except
				Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось прочитать свойства сертификатов: %1';
						|en = 'Cannot read the certificate properties: %1';"),
					ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			EndTry;
		Else
			Result.Certificate = SignaturePropertiesFromBinaryData.Certificates[0];
		EndIf;
		
		Try
			Certificate = New CryptoCertificate(Result.Certificate);
			Result.Certificate = Certificate.Unload();
			CertificateProperties = DigitalSignature.CertificateProperties(Certificate);
			Result.Thumbprint = CertificateProperties.Thumbprint;
			Result.CertificateOwner = CertificateProperties.IssuedTo;
		Except
			Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось прочитать свойства сертификата: %1';
						|en = 'Cannot read the certificate properties: %1';"),
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;

	EndIf;

	Result.Success = IsBlankString(Result.ErrorText);
	
	Return Result;

EndFunction

Procedure SetVisibilityOfRefToAppsTroubleshootingGuide(InstructionItem) Export
	
	URL = "";
	DigitalSignatureClientServerLocalization.OnDefineRefToAppsGuide("", URL);
	InstructionItem.Visible = Not IsBlankString(URL);
	
EndProcedure

Function InfoHeadingForSupport() Export
	
	If VisibilityOfRefToAppsTroubleshootingGuide() Then
		Title = StringFunctions.FormattedString(
			NStr("ru = 'При возникновении затруднений ознакомьтесь со списком <a href = %1>типичных проблем при работе с приложениями электронной подписи и их решений</a>.
				|
				|В иных случаях <a href = %2>обратитесь в службу поддержки фирмы ""1С""</a>';
				|en = 'Facing issues? Learn how to <a href = %1>troubleshoot digital signing apps</a> (in Russian).
				|
				|If you didn''t find a solution, <a href = %2>contact the 1C support team</a>.';"),
				"TypicalIssues", "TechnicalInformation");
	Else
		Title = StringFunctions.FormattedString(
			NStr("ru = '<a href = %1>Обратитесь в службу поддержки фирмы ""1С""</a>';
				|en = '<a href = %1>Contact 1C support</a>';"),
				"TechnicalInformation");
	EndIf;
	
	Return Title;
	
EndFunction

// Returns the internal classifier ID for the ClassifiersOperations subsystem.
//
// Returns:
//  String - Classifier ID.
//
Function ClassifierID()
	
	ModuleDigitalSignatureInternalLocalization = Common.CommonModule("DigitalSignatureInternalLocalization");
	If ModuleDigitalSignatureInternalLocalization <> Undefined Then
		Return ModuleDigitalSignatureInternalLocalization.ClassifierID();
	EndIf;
	
	Return Undefined;
	
EndFunction

// For internal use only.
Function ErrorCertificateMarkedAsRevoked() Export
	
	ErrorPresentation = New Structure;
	ErrorPresentation.Insert("ErrorText", NStr("ru = 'Сертификат помечен как отозванный.';
													|en = 'The certificate is revoked.';"));
	ErrorPresentation.Insert("Cause", NStr("ru = 'Возможно, подано заявление на отзыв сертификата.';
												|en = 'Probably, a certificate revocation application is submitted.';"));
	ErrorPresentation.Insert("Decision", StringFunctions.FormattedString(
		NStr("ru = 'В меню <b>Еще</b> в <a href=""%1"">карточке сертификата</a> можно снять пометку <b>Сертификат отозван</b>. Но если сертификат отозван в удостоверяющем центре, сделать подпись таким сертификатом будет все равно невозможно.';
			|en = 'In the <b>More actions</b> menu, in <a href=""%1"">certificate card</a>, you can clear the <b>Certificate revoked</b> mark. However, if a certificate is revoked by a certificate authority, you will not be able to sign with this certificate.';"),
		"OpenCertificate"));
	Return ErrorPresentation;
	
EndFunction

// Returns additional parameters of the crypto manager creation.
//
// Returns:
//   Structure:
//    * ShowError     - Boolean - if True, throw an exception that contains the error description.
//
//    * ErrorDescription     - String - an error description that is returned when the function returns Undefined.
//                         - Structure - See DigitalSignatureInternalClientServer.NewErrorsDescription
//
//    * Application          - Undefined - returns a crypto manager of the first
//                         app from the catalog for which it was possible to create it.
//                         - CatalogRef.DigitalSignatureAndEncryptionApplications - App for which
//                         a crypto manager must be created and returned.
//                         - Structure - See DigitalSignature.NewApplicationDetails
//
//    * SignAlgorithm    - String - If specified, returns an app that uses this signature algorithm.
//    * EncryptAlgorithm - String - If specified, returns an application with the given encryption algorithm.
//    * AutoDetect    - Boolean - Flag indicating whether to detect installed apps.
//
Function CryptoManagerCreationParameters() Export
	
	CryptoManagerCreationParameters = New Structure;
	CryptoManagerCreationParameters.Insert("Application", Undefined);
	CryptoManagerCreationParameters.Insert("ShowError", False);
	CryptoManagerCreationParameters.Insert("ErrorDescription", "");
	CryptoManagerCreationParameters.Insert("SignAlgorithm", "");
	CryptoManagerCreationParameters.Insert("EncryptAlgorithm", "");
	CryptoManagerCreationParameters.Insert("AutoDetect", True);
	
	Return CryptoManagerCreationParameters;
	
EndFunction

// Returns the crypto manager (on the server) for the specified app.
//
// Parameters:
//  Operation                       - String - If not blank, it must contain one of the strings that determine
//                                 the operation to be inserted in the error details: Signing, SignatureCheck, Encryption,
//                                 Decryption, CertificateCheck, and GetCertificates.
//  CryptoManagerParameters - See DigitalSignatureInternal.CryptoManagerCreationParameters.
//
// Returns:
//   CryptoManager - -a crypto manager.
//   Undefined - an error occurred. The error description is in the ErrorDescription parameter.
//
Function CryptoManager(Operation, CryptoManagerCreationParameters = Undefined) Export
	
	If CryptoManagerCreationParameters = Undefined Then
		CryptoManagerCreationParameters = CryptoManagerCreationParameters();
	EndIf;
	
	Application			= CryptoManagerCreationParameters.Application;
	ShowError		= CryptoManagerCreationParameters.ShowError;
	SignAlgorithm		= CryptoManagerCreationParameters.SignAlgorithm;
	EncryptAlgorithm	= CryptoManagerCreationParameters.EncryptAlgorithm;
	AutoDetect		= CryptoManagerCreationParameters.AutoDetect;
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("Operation", Operation);
	AdditionalParameters.Insert("AutoDetect", AutoDetect);
	AdditionalParameters.Insert("SignAlgorithm", SignAlgorithm);
	AdditionalParameters.Insert("EncryptAlgorithm", EncryptAlgorithm);
	
	ComputerName = ComputerName();
	ErrorsDescription = DigitalSignatureInternalClientServer.NewErrorsDescription(ComputerName);
	Manager = NewCryptoManager(Application, ErrorsDescription.Errors, AdditionalParameters);
	
	If Manager <> Undefined Then
		Return Manager;
	EndIf;
	
	If Operation = "Signing" Then
		ErrorTitle = NStr("ru = 'Не удалось подписать данные на сервере %1 по причине:';
								|en = 'Cannot sign data on server %1 due to:';");
		
	ElsIf Operation = "CheckSignature" Then
		ErrorTitle = NStr("ru = 'Не удалось проверить подпись на сервере %1 по причине:';
								|en = 'Cannot verify the signature on server %1 due to:';");
	
	ElsIf Operation = "Encryption" Then
		ErrorTitle = NStr("ru = 'Не удалось зашифровать данные на сервере %1 по причине:';
								|en = 'Cannot encrypt data on server %1 due to:';");
		
	ElsIf Operation = "Details" Then
		ErrorTitle = NStr("ru = 'Не удалось расшифровать данные на сервере %1 по причине:';
								|en = 'Cannot decrypt data on server %1 due to:';");
		
	ElsIf Operation = "CertificateCheck" Then
		ErrorTitle = NStr("ru = 'Не удалось проверить сертификат на сервере %1 по причине:';
								|en = 'Cannot verify the certificate on server %1 due to:';");
		
	ElsIf Operation = "GetCertificates" Then
		ErrorTitle = NStr("ru = 'Не удалось получить сертификаты на сервере %1 по причине:';
								|en = 'Cannot receive certificates on server %1 due to:';");
	
	ElsIf Operation = "ReadSignature" Then
		ErrorTitle = NStr("ru = 'Не удалось прочитать все свойства подписи на сервере %1 по причине:';
								|en = 'Cannot read all the signature properties on the %1 server due to:';");
		
	ElsIf Operation = "ExtensionValiditySignature" Then
		ErrorTitle = NStr("ru = 'Не удалось усовершенствовать подписи на сервере %1 по причине:';
								|en = 'Couldn''t enhance signatures on server %1 due to:';");
		
	ElsIf Operation <> "" Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка вызова функции %1.
			           |Неверное значение параметра Операция ""%2"".';
						|en = 'The %1 function call error.
						|The ""Operation"" parameter has invalid value ""%2"".';"), "CryptoManager", Operation);
		
	ElsIf TypeOf(CryptoManagerCreationParameters.ErrorDescription) = Type("Structure")
		And CryptoManagerCreationParameters.ErrorDescription.Property("ErrorTitle") Then
		
		ErrorTitle = CryptoManagerCreationParameters.ErrorDescription.ErrorTitle;
	Else
		ErrorTitle = NStr("ru = 'Не удалось выполнить операцию на сервере %1 по причине:';
								|en = 'Cannot perform the operation on server %1. Reason:';");
	EndIf;
	
	ErrorTitle = StrReplace(ErrorTitle, "%1", ComputerName);
	ErrorsDescription.ErrorTitle = ErrorTitle;
	
	DigitalSignatureInternalClientServer.CryptoManagerFillErrorsPresentation(
		ErrorsDescription,
		Application,
		SignAlgorithm,
		Users.IsFullUser(,, False),
		True);
	
	If TypeOf(CryptoManagerCreationParameters.ErrorDescription) = Type("Structure") Then
		CryptoManagerCreationParameters.ErrorDescription = ErrorsDescription;
	Else
		CryptoManagerCreationParameters.ErrorDescription = ErrorsDescription.ErrorDescription;
	EndIf;
	
	If ShowError Then
		Raise ErrorsDescription.ErrorDescription;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns an array with the server-side certificate thumbprint.
//
Function CertificateThumbprints(OnlyPersonal, ErrorDescription) Export
	
	ThumbprintsArray = New Array;
	
	If DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		
		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.ShowError = ErrorDescription;
		CryptoManager = CryptoManager("GetCertificates", CreationParameters);
		
		Error = CreationParameters.ErrorDescription;
		If CryptoManager <> Undefined Then
			
			ThumbprintsArray = GetCertificateThumbprintsInStorage(
				CryptoManager, CryptoCertificateStoreType.PersonalCertificates, Error);
			
			If Not OnlyPersonal Then
				CommonClientServer.SupplementArray(ThumbprintsArray,
					GetCertificateThumbprintsInStorage(
						CryptoManager, CryptoCertificateStoreType.RecipientCertificates, Error),
					True);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return ThumbprintsArray;
	 
EndFunction

// Returns an array with the service-side certificate thumbprint.
//
Function ServiceCertificateThumbprints() Export
	
	ThumbprintsArray = New Array;
	
	If UseCloudSignatureService() Then
		
		
	EndIf;
	
	Return ThumbprintsArray;
	
EndFunction

// Finds a certificate on the computer by a thumbprint string.
//
// Parameters:
//   Thumbprint              - String - a Base64 coded certificate thumbprint.
//   InPersonalStorageOnly - Boolean - if True, search in the Personal store, otherwise, search everywhere.
//
// Returns:
//   CryptoCertificate - certificate of digital signature and encryption.
//   Undefined - the certificate does not exist.
//
Function GetCertificateByThumbprint(Thumbprint, InPersonalStorageOnly,
			ShowError = True, Application = Undefined, ErrorDescription = "") Export
	
	CreationParameters = CryptoManagerCreationParameters();
	CreationParameters.Application = Application;
	CreationParameters.ShowError = ShowError;
	CreationParameters.ErrorDescription = ErrorDescription;
	
	CryptoManager = CryptoManager("GetCertificates", CreationParameters);
	
	ErrorDescription = CreationParameters.ErrorDescription;
	If CryptoManager = Undefined Then
		Return Undefined;
	EndIf;
	
	StoreType = DigitalSignatureInternalClientServer.StorageTypeToSearchCertificate(InPersonalStorageOnly);
	
	Try
		ThumbprintBinaryData = Base64Value(Thumbprint);
	Except
		If ShowError Then
			Raise;
		EndIf;
		ErrorInfo = ErrorInfo();
		ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	EndTry;
	
	If Not ValueIsFilled(ErrorPresentation) Then
		Try
			CryptoCertificateStore = CryptoManager.GetCertificateStore(StoreType);
		Except
			If ShowError Then
				Raise;
			EndIf;
			ErrorInfo = ErrorInfo();
			ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		EndTry;
	EndIf;
	
	If Not ValueIsFilled(ErrorPresentation) Then
		Try
			Certificate = CryptoCertificateStore.FindByThumbprint(ThumbprintBinaryData);
		Except
			If ShowError Then
				Raise;
			EndIf;
			ErrorInfo = ErrorInfo();
			ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		EndTry;
	EndIf;
	
	If TypeOf(Certificate) = Type("CryptoCertificate") Then
		Return Certificate;
	EndIf;
	
	If ValueIsFilled(ErrorPresentation) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Сертификат не установлен на сервере по причине:
			           |%1';
						|en = 'The certificate was not installed on the server due to:
						|%1';")
			+ Chars.LF,
			ErrorPresentation);
	Else
		ErrorText = NStr("ru = 'Сертификат не установлен на сервере.';
							|en = 'The certificate was not installed on the server.';");
	EndIf;
		
	If Not Users.IsFullUser(,, False) Then
		ErrorText = ErrorText + Chars.LF + NStr("ru = 'Обратитесь к администратору.';
														|en = 'Please contact the application administrator.';")
	EndIf;
	
	ErrorText = TrimR(ErrorText);
	
	If TypeOf(ErrorDescription) = Type("Structure") Then
		ErrorDescription = New Structure;
		ErrorDescription.Insert("ErrorDescription", ErrorText);
	Else
		ErrorDescription = ErrorPresentation;
	EndIf;
	
	Return Undefined;
	
EndFunction

// For internal use only.
Function UTCOffset() Export
	
	Return CurrentSessionDate() - CurrentUniversalDate();
	
EndFunction

// Saves the current user settings to work with the digital signature.
Procedure SavePersonalSettings(PersonalSettings) Export
	
	SubsystemKey = SettingsStorageKey();
	
	For Each KeyAndValue In PersonalSettings Do
		Common.CommonSettingsStorageSave(SubsystemKey, KeyAndValue.Key,
			KeyAndValue.Value);
	EndDo;
	
EndProcedure

// The key that is used to store subsystem settings.
Function SettingsStorageKey() Export
	
	Return "DS1"; // Do not replace with "ES". Intended for the backward compatibility purposes.
	
EndFunction

// Returns:
//  Structure:
//   * ReadOnly     - Boolean - if you set True, editing will be prohibited.
//   * FillChecking - Boolean - if you set True, filling will be checked.
//   * Visible          - Boolean - if you set True, the attribute will become hidden.
//   * FillValue - Arbitrary - an initial attribute value of the new object.
//                        - Undefined - filling is not required.
//
Function TheNewSettingsOfTheRequisiteCertificate()
	
	Parameters = New Structure;
	Parameters.Insert("ReadOnly", False);
	Parameters.Insert("FillChecking", False);
	Parameters.Insert("Visible", False);
	Parameters.Insert("FillValue", Undefined);
	
	Return Parameters;
	
EndFunction

// Returns:
//  Structure:
//   * Description - See TheNewSettingsOfTheRequisiteCertificate
//   * Organization  - See TheNewSettingsOfTheRequisiteCertificate
//   * EnterPasswordInDigitalSignatureApplication - See TheNewSettingsOfTheRequisiteCertificate
//
Function NewParametersForCertificateDetails() Export
	
	Return New Structure;
	
EndFunction

// For internal use only.
// Parameters:
//  Ref - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//  Certificate - CryptoCertificate
//  AttributesParameters - See NewParametersForCertificateDetails
//
Procedure BeforeStartEditKeyCertificate(Ref, Certificate, AttributesParameters) Export
	
	Table = New ValueTable;
	Table.Columns.Add("AttributeName",       New TypeDescription("String"));
	Table.Columns.Add("ReadOnly",     New TypeDescription("Boolean"));
	Table.Columns.Add("FillChecking", New TypeDescription("Boolean"));
	Table.Columns.Add("Visible",          New TypeDescription("Boolean"));
	Table.Columns.Add("FillValue");
	
	DigitalSignatureOverridable.BeforeStartEditKeyCertificate(Ref, Certificate, Table);
	
	AttributesParameters = NewParametersForCertificateDetails();
	
	For Each TableRow In Table Do
		Parameters = TheNewSettingsOfTheRequisiteCertificate();
		FillPropertyValues(Parameters, TableRow);
		AttributesParameters.Insert(TableRow.AttributeName, Parameters);
	EndDo;
	
EndProcedure

// For internal use only.
Procedure CheckPresentationUniqueness(Presentation, CertificateReference, Field, Cancel) Export
	
	If Not ValueIsFilled(Presentation) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Ref",       CertificateReference);
	Query.SetParameter("Description", Presentation);
	
	Query.Text =
	"SELECT
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|WHERE
	|	Certificates.Ref <> &Ref
	|	AND Certificates.Description = &Description";
	
	If Not Query.Execute().IsEmpty() Then
		MessageText = NStr("ru = 'Сертификат с таким представлением уже существует.';
								|en = 'Certificate with such presentation already exists';");
		Common.MessageToUser(MessageText,, Field,, Cancel);
	EndIf;
	
EndProcedure

// For internal use only.
Function SignatureInfoForEventLog(SignatureDate, SignatureProperties, IsSigningError = False) Export
	
	CertificateProperties = New Structure;
	CertificateProperties.Insert("SerialNumber", Base64Value(""));
	CertificateProperties.Insert("IssuedBy", "");
	CertificateProperties.Insert("IssuedTo", "");
	CertificateProperties.Insert("StartDate", '00010101');
	CertificateProperties.Insert("EndDate", '00010101');
	CertificateProperties.Insert("ValidBefore", '00010101');
	
	NewSignatureProperties = DigitalSignatureClientServer.NewSignatureProperties();
	FillPropertyValues(NewSignatureProperties, SignatureProperties);
	
	If NewSignatureProperties.CertificateDetails <> Undefined Then
		FillPropertyValues(CertificateProperties, NewSignatureProperties.CertificateDetails);
		If Not ValueIsFilled(CertificateProperties.ValidBefore) Then
			CertificateProperties.ValidBefore = CertificateProperties.EndDate;
		EndIf;
	Else
		
		If TypeOf(NewSignatureProperties.Certificate) = Type("String")
		   And IsTempStorageURL(NewSignatureProperties.Certificate) Then
			Certificate = GetFromTempStorage(NewSignatureProperties.Certificate);
		Else
			Certificate = NewSignatureProperties.Certificate;
		EndIf;
		
		If TypeOf(Certificate) = Type("BinaryData") Then
			CryptoCertificate = New CryptoCertificate(Certificate);
			CertificateProperties = DigitalSignature.CertificateProperties(CryptoCertificate);
		Else
			CertificateProperties.IssuedTo = NewSignatureProperties.CertificateOwner;
		EndIf;
	EndIf;
	
	If IsSigningError Then
		SignatureInformation = "";
	Else
		SignatureInformation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Дата подписи: %1';
				|en = 'Signed on: %1';"), Format(SignatureDate, "DLF=DT")) + Chars.LF;
	EndIf;
	
	SignatureInformation = SignatureInformation + DigitalSignatureInternalClientServer.DetailsCertificateString(CertificateProperties);
	
	Return SignatureInformation;
	
EndFunction

// For internal use only.
Procedure RegisterDataSigningInLog(DataElement, ErrorDescription = "") Export
	
	IsSigningError = ValueIsFilled(ErrorDescription);
	
	If TypeOf(DataElement.SignatureProperties) = Type("String") Then
		SignatureProperties = GetFromTempStorage(DataElement.SignatureProperties);
	Else
		SignatureProperties = DataElement.SignatureProperties;
	EndIf;
	
	EventLogMessage = SignatureInfoForEventLog(
		SignatureProperties.SignatureDate, SignatureProperties, IsSigningError);
	
	If IsSigningError Then
		EventName = NStr("ru = 'Электронная подпись.Ошибка подписания данных';
							|en = 'Digital signature.Data signing error';",
			Common.DefaultLanguageCode());
		
		EventLogMessage = EventLogMessage + "
		|
		|" + ErrorDescription;
	Else
		EventName = NStr("ru = 'Электронная подпись.Подписание данных';
							|en = 'Digital signature.Data signing';",
			Common.DefaultLanguageCode());
	EndIf;
	
	If Common.IsReference(TypeOf(DataElement.DataPresentation)) Then
		DataItemMetadata = DataElement.DataPresentation.Metadata();
	Else
		DataItemMetadata = Undefined;
	EndIf;
	
	WriteLogEvent(EventName,
		EventLogLevel.Information,
		DataItemMetadata,
		DataElement.DataPresentation,
		EventLogMessage);
	
EndProcedure
	
// For internal use only.
//
// Parameters:
//  ChoiceList - ValueList - List to be populated.
//  Operation     - String - Enhancement, Signing, Settings - Operations the list is generated for.
//               - Undefined - Default value. Used to generate a list without exceptions.
//  SignatureType   - EnumRef.CryptographySignatureTypes - SignatureType that defines what signatures are
//                                                              available for this operation.
//
Procedure FillListSignatureTypesCryptography(ChoiceList, Operation = Undefined, SignatureType = Undefined) Export
	
	ChoiceList.Clear();
	If Operation <> "Improvement"
		And (Not ValueIsFilled(SignatureType) Or SignatureType = Enums.CryptographySignatureTypes.BasicCAdESBES) Then
		SignaturePresentation = "";
		DigitalSignatureLocalization.WhenFillingOutSignatureTypeView(Enums.CryptographySignatureTypes.BasicCAdESBES, SignaturePresentation);
		If SignaturePresentation = "" Then
			SignaturePresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Базовая подпись (%1)
					 |становится недействительной после окончания срока действия сертификата подписанта (обычно в течение 1 года).';
					|en = 'Basic electronic signature (%1)
					|becomes invalid after the signer''s certificate expires (usually within a year).';"),
			"CAdES-BES");
		EndIf;
		ChoiceList.Add(Enums.CryptographySignatureTypes.BasicCAdESBES, SignaturePresentation);
	EndIf;

	DataSeparationEnabled = Common.DataSeparationEnabled();
	AddSignatureType = False;
	
	If DataSeparationEnabled Then
		ThisistheServiceModelwithEnhancementAvailable = DigitalSignature.CommonSettings().ThisistheServiceModelwithEnhancementAvailable;
		AddSignatureType = ThisistheServiceModelwithEnhancementAvailable Or Not Operation = "Settings";
	Else
		If Not ValueIsFilled(SignatureType) Or SignatureType = Enums.CryptographySignatureTypes.WithTimeCAdEST
			And Operation <> "Improvement" Or SignatureType = Enums.CryptographySignatureTypes.BasicCAdESBES Then
			AddSignatureType = True;
		EndIf;
	EndIf;
	
	If AddSignatureType Then
		
		SignaturePresentation = "";
		DigitalSignatureLocalization.WhenFillingOutSignatureTypeView(Enums.CryptographySignatureTypes.WithTimeCAdEST, SignaturePresentation);
		If SignaturePresentation = "" Then
			SignaturePresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Подпись с меткой доверенного времени (%1)
					 |действует после окончания срока действия сертификата подписанта.';
					|en = 'Electronic signature with time (%1)
					|is valid after the signer''s certificate expires.';"), "CAdES-T");
		EndIf;
		
		ChoiceList.Add(Enums.CryptographySignatureTypes.WithTimeCAdEST,
			SignaturePresentation);
			
	EndIf;

	If Operation = Undefined Or Not (DataSeparationEnabled And Operation = "Settings") Then
		
		SignaturePresentation = "";
		DigitalSignatureLocalization.WhenFillingOutSignatureTypeView(Enums.CryptographySignatureTypes.ArchivalCAdESAv3, SignaturePresentation);
		If SignaturePresentation = "" Then
			SignaturePresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Архивная подпись (%1)
					 |содержит полный набор доказательств подлинности, в том числе цепочку сертификатов, и автоматически продлевается.';
					|en = 'Archival electronic signature (%1)
					|contains the full authenticity proof set, including a certificate chain, and is renewed automatically.';"),
			"CAdES-A");
		EndIf;
		
		ChoiceList.Add(Enums.CryptographySignatureTypes.ArchivalCAdESAv3, SignaturePresentation);
		
	EndIf;

EndProcedure

// For internal use only.
Procedure UpdateCertificatesList(Certificates, CertificatesPropertiesAtClient, ButAlreadyAddedOnes,
				Personal, Error, NoFilter, AdditionalParameters = Undefined) Export
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FilterByCompany = AdditionalParameters.FilterByCompany;
		ExecuteAtServer = AdditionalParameters.ExecuteAtServer;
	Else
		FilterByCompany = Undefined;
		ExecuteAtServer = Undefined;
	EndIf;
	
	CertificatesPropertiesTable = New ValueTable;
	CertificatesPropertiesTable.Columns.Add("Thumbprint", New TypeDescription("String", , New StringQualifiers(255)));
	CertificatesPropertiesTable.Columns.Add("IssuedBy");
	CertificatesPropertiesTable.Columns.Add("Presentation");
	CertificatesPropertiesTable.Columns.Add("AtClient",            New TypeDescription("Boolean"));
	CertificatesPropertiesTable.Columns.Add("AtServer",            New TypeDescription("Boolean"));
	CertificatesPropertiesTable.Columns.Add("IsRequest",         New TypeDescription("Boolean"));
	CertificatesPropertiesTable.Columns.Add("InCloudService",     New TypeDescription("Boolean"));
	CertificatesPropertiesTable.Columns.Add("LocationType",        New TypeDescription("Number"));
	CertificatesPropertiesTable.Columns.Add("CertificateStatus", New TypeDescription("Number"));
	CertificatesPropertiesTable.Columns.Add("Isinthedirectory",     New TypeDescription("Boolean"));
	
	For Each CertificateProperties In CertificatesPropertiesAtClient Do
		NewRow = CertificatesPropertiesTable.Add();
		FillPropertyValues(NewRow, CertificateProperties);
		NewRow.AtClient = True;
	EndDo;
	
	CertificatesPropertiesTable.Indexes.Add("Thumbprint");
	
	If DigitalSignature.GenerateDigitalSignaturesAtServer()
	   And ExecuteAtServer <> False Then
		
		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.ErrorDescription = Error;
		
		CryptoManager = CryptoManager("GetCertificates", CreationParameters);
		
		Error = CreationParameters.ErrorDescription;
		If CryptoManager <> Undefined Then
			
			Try
				CertificatesArray = CryptoManager.GetCertificateStore(
					CryptoCertificateStoreType.PersonalCertificates).GetAll();
				DigitalSignatureInternalClientServer.AddCertificatesProperties(CertificatesPropertiesTable,
					CertificatesArray, NoFilter, UTCOffset(), CurrentSessionDate());
			Except
				ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
				If TypeOf(Error) = Type("Structure") Then
					Error = DigitalSignatureInternalClientServer.NewErrorsDescription(ComputerName());
					Error.ErrorDescription = ErrorDescription;
				Else
					Error = ErrorDescription;
				EndIf;
			EndTry;

			If Not Personal Then
				Try
					CertificatesArray = CryptoManager.GetCertificateStore(
						CryptoCertificateStoreType.RecipientCertificates).GetAll();
					DigitalSignatureInternalClientServer.AddCertificatesProperties(CertificatesPropertiesTable,
						CertificatesArray, NoFilter, UTCOffset(), CurrentSessionDate());
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
		
	EndIf;
	
	If UseDigitalSignatureSaaS() Then
		
		ModuleCertificateStore = Common.CommonModule("CertificatesStorage");
		CertificatesArray = ModuleCertificateStore.Get("PersonalCertificates");
		
		PropertiesAddingOptions = New Structure("InCloudService", True);
		DigitalSignatureInternalClientServer.AddCertificatesProperties(CertificatesPropertiesTable,
			CertificatesArray, NoFilter, UTCOffset(), CurrentSessionDate(), PropertiesAddingOptions);
		
		If Not Personal Then
			CertificatesArray = ModuleCertificateStore.Get("RecipientCertificates");
			
			DigitalSignatureInternalClientServer.AddCertificatesProperties(CertificatesPropertiesTable,
				CertificatesArray, NoFilter, UTCOffset(), CurrentSessionDate(), PropertiesAddingOptions);
		EndIf;
		
	EndIf;
	
	If UseCloudSignatureService() Then
	EndIf;
	
	ProcessAddedCertificates(CertificatesPropertiesTable, Not NoFilter And ButAlreadyAddedOnes, FilterByCompany);
	
	CertificatesPropertiesTable.Indexes.Add("Presentation");
	CertificatesPropertiesTable.Sort("Presentation Asc");
	
	ProcessedRows  = New Map;
	IndexOf = 0;
	Filter = New Structure("Thumbprint", "");
	
	For Each CertificateProperties In CertificatesPropertiesTable Do
		Filter.Thumbprint = CertificateProperties.Thumbprint;
		Rows = Certificates.FindRows(Filter);
		If Rows.Count() = 0 Then
			If Certificates.Count()-1 < IndexOf Then
				String = Certificates.Add();
			Else
				String = Certificates.Insert(IndexOf);
			EndIf;
		Else
			String = Rows[0];
			RowIndex = Certificates.IndexOf(String);
			If RowIndex <> IndexOf Then
				Certificates.Move(RowIndex, IndexOf - RowIndex);
			EndIf;
		EndIf;
		// Updating only changed values not to update the form table once again.
		UpdateValue(String.Thumbprint,            CertificateProperties.Thumbprint);
		UpdateValue(String.Presentation,        CertificateProperties.Presentation);
		UpdateValue(String.IssuedBy,             CertificateProperties.IssuedBy);
		UpdateValue(String.AtClient,            CertificateProperties.AtClient);
		UpdateValue(String.AtServer,            CertificateProperties.AtServer);
		UpdateValue(String.IsRequest,         CertificateProperties.IsRequest);
		UpdateValue(String.InCloudService,     CertificateProperties.InCloudService);
		UpdateValue(String.LocationType,        CertificateProperties.LocationType);
		UpdateValue(String.CertificateStatus, CertificateProperties.CertificateStatus);
		UpdateValue(String.Isinthedirectory,     CertificateProperties.Isinthedirectory);
		ProcessedRows.Insert(String, True);
		IndexOf = IndexOf + 1;
	EndDo;
	
	IndexOf = Certificates.Count()-1;
	While IndexOf >=0 Do
		String = Certificates.Get(IndexOf);
		If ProcessedRows.Get(String) = Undefined Then
			Certificates.Delete(IndexOf);
		EndIf;
		IndexOf = IndexOf-1;
	EndDo;
	
EndProcedure

// For the CheckCertificate function.
Function ValidateCertificate(CryptoManagerToCheck, CertificateToCheck, 
	CertificateCheckModes, ErrorDescription, RaiseException1)
	
	Try
		CryptoManagerToCheck.CheckCertificate(CertificateToCheck, CertificateCheckModes);
		Return True;
	Except
		ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	
	If Not ValueIsFilled(ErrorDescription) Then
		Return False;
	EndIf;

	ClassifierError = ClassifierError(ErrorDescription, True);
	If ClassifierError = Undefined Then
		Return False;
	EndIf;

	If ClassifierError.CertificateRevoked Then
		Try
			DoWriteCertificateRevocationMark(Base64String(CertificateToCheck.Thumbprint));
		Except
			ErrorDescription = ErrorDescription + Chars.LF + ErrorProcessing.BriefErrorDescription(
				ErrorInfo());
		EndTry;
		Return False;
	EndIf;

	If ValueIsFilled(ClassifierError.RemedyActions) Then
		Return RevalidateCertificate(CryptoManagerToCheck, CertificateToCheck,
			CertificateCheckModes, ErrorDescription, RaiseException1,
			ClassifierError.RemedyActions);
	EndIf;
	
	Return False;
	
EndFunction

// For the CheckCertificate function.
Function RevalidateCertificate(CryptoManagerToCheck, CertificateToCheck, 
	CertificateCheckModes, ErrorDescription, RaiseException1, RemedyActions)
	
	ShouldInstallRevocationList = False;
	
	If TypeOf(CryptoManagerToCheck) = Type("CryptoManager") Then
		If ValueIsFilled(RemedyActions) And RemedyActions.Find("SetListOfCertificateRevocation") <> Undefined Then
			CertificateAuthorityName = Lower(DigitalSignature.CertificateIssuerProperties(CertificateToCheck).CommonName);
			If ValueIsFilled(CertificateAuthorityName) Then
				
				CertificateAuthorityName = StringFunctions.LatinString(CertificateAuthorityName);
				
				RevocationListInternalAddress = DigitalSignatureInternalClientServer.RevocationListInternalAddress(
					CertificateAuthorityName,
					CertificateToCheck.Unload(), 
					DigitalSignatureInternalCached.CataloguesOfReviewListsOfUTS());
					
				If ValueIsFilled(RevocationListInternalAddress.InternalAddress) Then
					ShouldInstallRevocationList = True;
				EndIf;
				
			EndIf;
		EndIf;
	EndIf;
	
	If ShouldInstallRevocationList Then
		
		CertificateProperties = DigitalSignature.CertificateProperties(CertificateToCheck);
		DetailsCertificateString = DigitalSignatureInternalClientServer.DetailsCertificateString(CertificateProperties);
		
		Try
			SetListOfCertificateRevocation(CertificateToCheck,
				RevocationListInternalAddress.ExternalAddress, RevocationListInternalAddress.InternalAddress);
		Except
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось установить список отзыва на сервере при проверке сертификата: %1
				|%2.';
				|en = 'Couldn''t find a revocation list on the server when checking the certificate: %1
				|%2.';"),
				
				ErrorProcessing.BriefErrorDescription(ErrorInfo()),
				DetailsCertificateString);
			
			WriteLogEvent(
					NStr("ru = 'Электронная подпись.Обновление списков отзыва';
						|en = 'Digital signature.Update revocation list';",
					Common.DefaultLanguageCode()),
					EventLogLevel.Error, , ,
					ErrorText);
			
			Return False;
		EndTry;
		
		WriteLogEvent(
					NStr("ru = 'Электронная подпись.Обновление списков отзыва';
						|en = 'Digital signature.Update revocation list';",
					Common.DefaultLanguageCode()),
					EventLogLevel.Information, , ,
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Установлен список отзыва на сервере при проверке сертификата: %1';
							|en = 'Certificate revocation list was installed  on server during the certificate validation: %1';"),
						DetailsCertificateString));
		
		// Re-check after a certificate revocation list has been set.
		Try
			CryptoManagerToCheck.CheckCertificate(CertificateToCheck, CertificateCheckModes);
		Except

			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());

			If RaiseException1 Then
				Raise;
			EndIf;
			Return False;
		EndTry;
		
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

// For internal use only.
//
// Parameters:
//   Context - Structure:
//     * ErrorAtServer - Structure:
//         ** Errors - Array
//
Function WriteCertificateAfterCheck(Context) Export
	
	CreationParameters = CryptoManagerCreationParameters();
	CreationParameters.ErrorDescription = New Structure;
	CreationParameters.SignAlgorithm = Context.SignAlgorithm;
	
	CryptoManager = CryptoManager("", CreationParameters);
	
	Context.Insert("ErrorAtServer",
		DigitalSignatureInternalClientServer.NewErrorsDescription());
	
	ApplicationErrorTitle = DigitalSignatureInternalClientServer.CertificateAddingErrorTitle(
			?(Context.ToEncrypt = True, "Encryption", "Signing"), ComputerName());
	
	If TypeOf(CryptoManager) <> Type("CryptoManager")
		And CreationParameters.ErrorDescription.Shared3 Then
		
		Context.ErrorAtServer = CreationParameters.ErrorDescription;
		Context.ErrorAtServer.ErrorTitle = ApplicationErrorTitle;
		Return Undefined;
	EndIf;
	
	ApplicationsDetailsCollection = DigitalSignature.CommonSettings().ApplicationsDetailsCollection;
	CertificateApplicationResult = AppForCertificate(
		Context.CertificateData, True);
	
	If ValueIsFilled(CertificateApplicationResult.Application) Then
		ApplicationsDetailsCollection = DigitalSignatureInternalClientServer.CryptoManagerApplicationsDetails(
			CertificateApplicationResult.Application, Context.ErrorAtServer.Errors, ApplicationsDetailsCollection);
	Else
		
		DigitalSignatureInternalClientServer.CryptoManagerAddError(
			Context.ErrorAtServer.Errors, Undefined, CertificateApplicationResult.Error, True);
		
	EndIf;
	
	CryptoCertificate = New CryptoCertificate(Context.CertificateData);
	IsFullUser = Users.IsFullUser(,, False);
	
	For Each ApplicationDetails In ApplicationsDetailsCollection Do
		
		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.Application = ApplicationDetails.Ref;
		CreationParameters.ErrorDescription = New Structure;
		CreationParameters.SignAlgorithm = Context.SignAlgorithm;
		
		CryptoManager = CryptoManager("", CreationParameters);
		
		If CryptoManager = Undefined Then
			Errors = CreationParameters.ErrorDescription.Errors;
			
			If Errors.Count() > 0
			   And Not (ValueIsFilled(Context.SignAlgorithm)
			         And Errors[0].NoAlgorithm) Then
				
				Errors[0].ErrorTitle = ApplicationErrorTitle;
				Context.ErrorAtServer.Errors.Add(Errors[0]);
			EndIf;
			
			Continue;
			
		EndIf;
		
		CryptoManager.PrivateKeyAccessPassword = Context.CertificatePassword;
		
		If Context.ToEncrypt = True Then
			Success = CheckEncryptionAndDecryption(CryptoManager, Context.CertificateData,
				CryptoCertificate, ApplicationDetails, Context.ErrorAtServer, IsFullUser);
		Else
			Success = CheckSigning(CryptoManager, Context.CertificateData,
				CryptoCertificate, ApplicationDetails, Context.ErrorAtServer, IsFullUser);
		EndIf;
		
		If Not Success Then
			Continue;
		EndIf;
		
		Context.Insert("ApplicationDetails", ApplicationDetails);
		Return DigitalSignatureInternalClientServer.WriteCertificateToCatalog(Context,
			Context.ErrorAtServer);
		
	EndDo;
	
	Return Undefined;
	
EndFunction

// For internal use only.
// 
// Parameters:
//  Thumbprint - String - Certificate thumbprint in the Base64String format. 
//
Function DoWriteCertificateRevocationMark(Thumbprint) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("Thumbprint", Thumbprint);
	Query.Text =
	"SELECT
	|	Certificates.Ref AS Ref
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|WHERE
	|	Certificates.Thumbprint = &Thumbprint
	|	AND NOT Certificates.Revoked";
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	CertificateRef = Selection.Ref;
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.DigitalSignatureAndEncryptionKeysCertificates");
	LockItem.SetValue("Ref", CertificateRef);
	
	BeginTransaction();
	Try
		
		Block.Lock();
		CertificateObject = CertificateRef.GetObject();
		
		If CertificateObject.Revoked <> True Then
			CertificateObject.Revoked = True;
			CertificateObject.DataExchange.Load = True;
			CertificateObject.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		ErrorInfo = ErrorInfo();
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось записать отметку об отзыве сертификата %1: %2';
				|en = 'Cannot save the %1 certificate revocation mark: %2';"), CertificateRef, 
			ErrorProcessing.BriefErrorDescription(ErrorInfo));
		
		WriteLogEvent(
			NStr("ru = 'Электронная подпись.Установка отметки об отзыве сертификата.';
				|en = 'Digital signature.Set certificate revocation mark.';",
			Common.DefaultLanguageCode()),
			EventLogLevel.Error, , CertificateRef,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		Raise ErrorText;
	EndTry;
	
	Return CertificateRef;
	
EndFunction

// For internal use only.
Function BuiltinCryptoprovider() Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	Programs.Ref AS Ref
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS Programs
	|WHERE
	|	Programs.IsBuiltInCryptoProvider
	|	AND NOT Programs.DeletionMark
	|
	|ORDER BY
	|	Programs.Description";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		BuiltinCryptoprovider = Selection.Ref;
	Else
		BuiltinCryptoprovider = Undefined;
	EndIf;
	
	Return BuiltinCryptoprovider;
	
EndFunction

// For internal use only.
Function CloudPasswordConfirmed(Certificate)
	
	If Not UseDigitalSignatureSaaS() Then
		Return False;
	EndIf;
	
	If TypeOf(Certificate) = Type("BinaryData") Then
		CertificateData = Certificate;
		
	ElsIf TypeOf(Certificate) = Type("CryptoCertificate") Then
		CertificateData = Certificate.Unload();
	Else
		CertificateData = GetFromTempStorage(Certificate);
	EndIf;
	
	ModuleCryptographyService = Common.CommonModule("CryptographyService");
	CertificateProperties = ModuleCryptographyService.GetCertificateProperties(CertificateData);
	
	SecurityTokens = SecurityTokens(CertificateProperties.Id);
	
	Return ValueIsFilled(SecurityTokens.SecurityToken);
	
EndFunction

// For the CloudPasswordConfirmed function.
Function SecurityTokens(CertificateID)

	Result = New Structure();
	Result.Insert("SecurityToken");
	
	SetPrivilegedMode(True);
	Result.SecurityToken = SessionParameters["SecurityTokens"].Get(CertificateID);
	
	SetPrivilegedMode(False);
	
	// Replacing blank values with blank strings to pass to the crypto service.
	If Not ValueIsFilled(Result.SecurityToken) Then
		Result.SecurityToken = "";
	EndIf;
	
	Return Result;

EndFunction

// In Linux and MacOS, when creating a crypto manager,
// it is required to specify the path to the app.
//
// Returns:
//  Boolean
//
Function RequiresThePathToTheProgram(AtClient = False) Export
	
	If AtClient Then
		Return Common.IsLinuxClient()
		    Or Common.IsMacOSClient();
	EndIf;
	
	SystemInfo = New SystemInfo;
	
	Return Common.IsLinuxServer()
		Or SystemInfo.PlatformType = PlatformType.MacOS_x86
		Or SystemInfo.PlatformType = PlatformType.MacOS_x86_64;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Common procedures and functions for client application forms.

// For internal use only.
// 
// Parameters:
//  CertificatesList - ValueList - Certificate list to add Personal store certificates to.
//  Error - String - Error.
//
Procedure AddListofCertificatesInPersonalStorageOnServer(CertificatesList, Error = "") Export
	
	If DigitalSignature.GenerateDigitalSignaturesAtServer() Then

		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.ErrorDescription = Error;
		
		CryptoManager = CryptoManager("GetCertificates", CreationParameters);
		
		Error = CreationParameters.ErrorDescription;
		If CryptoManager <> Undefined Then
			
			Try
				CertificatesArray = CryptoManager.GetCertificateStore(
					CryptoCertificateStoreType.PersonalCertificates).GetAll();
				For Each Item In CertificatesArray Do
					CertificatesList.Add(Base64String(Item.Thumbprint));
				EndDo;
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
	
	If UseDigitalSignatureSaaS() Then
		
		ModuleCertificateStore = Common.CommonModule("CertificatesStorage");
		CertificatesArray = ModuleCertificateStore.Get("PersonalCertificates");
		For Each Item In CertificatesArray Do
			CertificatesList.Add(Base64String(Item.Thumbprint));
		EndDo;
		
	EndIf;
	
	If UseCloudSignatureService() Then
		TheDSSCryptographyServiceModuleInternal = Common.CommonModule("DSSCryptographyServiceInternal");
		CertificatesArray = TheDSSCryptographyServiceModuleInternal.GetCertificateData_(False);
		For Each Item In CertificatesArray Do
			CertificatesList.Add(Base64String(Item.Thumbprint));
		EndDo;
	EndIf;
	
EndProcedure

// For internal use only.
Procedure SetSigningEncryptionDecryptionForm(Form, Encryption = False, Details = False) Export
	
	Items  = Form.Items;
	Parameters = Form.Parameters;
	
	Items.Certificate.DropListButton = True;
	Items.Certificate.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInDropList;
	
	Form.Title = Parameters.Operation;
	Form.ExecuteAtServer = Parameters.ExecuteAtServer;
	
	If Encryption Then
		If Form.SpecifiedImmutableCertificateSet Then
			Form.NoConfirmation = Parameters.NoConfirmation;
		EndIf;
	Else
		Form.CertificatesFilter = New ValueList;
		If TypeOf(Parameters.CertificatesFilter) = Type("Array") Then
			Form.CertificatesFilter.LoadValues(Parameters.CertificatesFilter);
		ElsIf TypeOf(Parameters.CertificatesFilter) = Type("Structure") Then
			Form.CertificatesFilter = Parameters.CertificatesFilter.Organization;
		EndIf;
		Form.NoConfirmation = Parameters.NoConfirmation;
	EndIf;
	
	ItemDataPresentation = Items.DataPresentation; // FormField, FormFieldExtensionForALabelField
	If ValueIsFilled(Parameters.DataTitle) Then
		ItemDataPresentation.Title = Parameters.DataTitle;
	Else
		ItemDataPresentation.TitleLocation = FormItemTitleLocation.None;
	EndIf;
	
	Form.DataPresentation = Parameters.DataPresentation;
	ItemDataPresentation.Hyperlink = Parameters.DataPresentationCanOpen;
	
	If Not ValueIsFilled(Form.DataPresentation) Then
		ItemDataPresentation.Visible = False;
	EndIf;
	
	If Details Then
		FillThumbprintsFilter(Form);
	ElsIf Not Encryption Then // Signing.
		Items.Comment.Visible = Parameters.ShowComment And Not Form.NoConfirmation;
	EndIf;
	
	If Not Encryption Then
		FillExistingUserCertificates(Form.CertificatePicklist,
			Parameters.CertificatesThumbprintsAtClient, Form.CertificatesFilter,
			Form.ThumbprintsFilter, Details, Form.ExecuteAtServer);
	EndIf;
	
	Certificate = Undefined;
	
	If Details Then
		For Each ListItem In Form.CertificatePicklist Do
			If TypeOf(ListItem.Value) = Type("String") Then
				Continue;
			EndIf;
			Certificate = ListItem.Value;
			Break;
		EndDo;
		
	ElsIf AccessRight("SaveUserData", Metadata) Then
		If Encryption Then
			Certificate = CommonSettingsStorage.Load("Cryptography", "CertificateToEncrypt");
		Else
			Certificate = CommonSettingsStorage.Load("Cryptography", "CertificateToSign");
		EndIf;
	EndIf;
	
	If Not Encryption And TypeOf(Form.CertificatesFilter) = Type("ValueList") Then
		If Form.CertificatePicklist.Count() = 0 Then
			Certificate = Undefined;
		Else
			Certificate = Form.CertificatePicklist[0].Value;
		EndIf;
	EndIf;
	
	If Not (Encryption And Form.SpecifiedImmutableCertificateSet) Then
		Form.Certificate = Certificate;
	EndIf;
	
	If ValueIsFilled(Form.Certificate)
	   And Common.ObjectAttributeValue(Form.Certificate, "Ref") <> Form.Certificate Then
		
		Form.Certificate = Undefined;
	EndIf;
	
	If ValueIsFilled(Form.Certificate) Then
		If Encryption Then
			Form.DefaultFieldNameToActivate = "EncryptionCertificates";
		Else
			Form.DefaultFieldNameToActivate = "Password";
		EndIf;
	Else
		If Not (Encryption And Form.SpecifiedImmutableCertificateSet) Then
			Form.DefaultFieldNameToActivate = "Certificate";
		EndIf;
	EndIf;
	
	FillCertificateAdditionalProperties(Form);
	
	Form.CryptographyManagerOnServerErrorDescription = New Structure;
	If DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		
		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.ErrorDescription = New Structure;
		
		CryptoManager("GetCertificates", CreationParameters);
		Form.CryptographyManagerOnServerErrorDescription = CreationParameters.ErrorDescription;
		
	EndIf;
	
	If Not Encryption Then
		DigitalSignatureOverridable.BeforeOperationStart(?(Details, "Details", "Signing"),
			Parameters.AdditionalActionParameters, Form.AdditionalActionsOutputParameters);
	EndIf;
	
EndProcedure

// For internal use only.
Procedure CertificateOnChangeAtServer(Form, CertificatesThumbprintsAtClient, Encryption = False, Details = False) Export
	
	If (TypeOf(Form.CertificatesFilter) <> Type("ValueList")
		Or TypeOf(Form.CertificatesFilter) = Type("ValueList") And Form.CertificatesFilter.Count() = 0)
		And AccessRight("SaveUserData", Metadata) Then
		
		If Encryption Then
			CommonSettingsStorage.Save("Cryptography", "CertificateToEncrypt", Form.Certificate);
		ElsIf Not Details Then
			CommonSettingsStorage.Save("Cryptography", "CertificateToSign", Form.Certificate);
		EndIf;
		
	EndIf;
	
	FillExistingUserCertificates(Form.CertificatePicklist,
		CertificatesThumbprintsAtClient, Form.CertificatesFilter,
		Form.ThumbprintsFilter, Details, Form.ExecuteAtServer);
	
	FillCertificateAdditionalProperties(Form);
	
EndProcedure

// For internal use only.
Function SavedCertificateProperties(Thumbprint, Address, AttributesParameters, ToEncrypt = False) Export
	
	SavedProperties = New Structure;
	SavedProperties.Insert("Ref");
	SavedProperties.Insert("Description");
	SavedProperties.Insert("User");
	SavedProperties.Insert("Organization");
	SavedProperties.Insert("Individual");
	SavedProperties.Insert("EnterPasswordInDigitalSignatureApplication");
	
	Query = New Query;
	Query.SetParameter("Thumbprint", Thumbprint);
	Query.Text =
	"SELECT
	|	Certificates.Ref AS Ref,
	|	Certificates.Description AS Description,
	|	Certificates.User,
	|	Certificates.Organization,
	|	Certificates.Individual,
	|	Certificates.EnterPasswordInDigitalSignatureApplication,
	|	Certificates.CertificateData
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|WHERE
	|	Certificates.Thumbprint = &Thumbprint";
	
	CryptoCertificate = New CryptoCertificate(GetFromTempStorage(Address));
	
	FillingValues = AttributesParameters;
	AttributesParameters = Undefined; // It is filled in the BeforeStartEditKeyCertificate procedure.
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(SavedProperties, Selection);
	Else
		SavedProperties.Ref = Catalogs.DigitalSignatureAndEncryptionKeysCertificates.EmptyRef();
		
		If TypeOf(FillingValues) = Type("Structure")
		   And FillingValues.Property("Organization")
		   And ValueIsFilled(FillingValues.Organization) Then
			
			SavedProperties.Organization = FillingValues.Organization;
			
		ElsIf Not Metadata.DefinedTypes.Organization.Type.ContainsType(Type("String")) Then
			FullName = Metadata.FindByType(Metadata.DefinedTypes.Organization.Type.Types()[0]).FullName();
			CompanyCatalogName = "Catalogs." + StrSplit(FullName, ".")[1];
			ModuleOrganization = Common.CommonModule(CompanyCatalogName);
			If Not ToEncrypt Then
				SavedProperties.Organization = ModuleOrganization.DefaultCompany();
			EndIf;
		EndIf;
		
		CertificateProperties = DigitalSignature.CertificateProperties(CryptoCertificate);
		SavedProperties.Description = CertificateProperties.Presentation;
		
		If Not ToEncrypt Then
			SavedProperties.User = Users.CurrentUser();
		EndIf;
	EndIf;
	
	BeforeStartEditKeyCertificate(
		SavedProperties.Ref, CryptoCertificate, AttributesParameters);
	
	If Not ValueIsFilled(SavedProperties.Ref) Then
		FillAttribute(SavedProperties, AttributesParameters, "Description");
		FillAttribute(SavedProperties, AttributesParameters, "User");
		FillAttribute(SavedProperties, AttributesParameters, "Organization");
		FillAttribute(SavedProperties, AttributesParameters, "EnterPasswordInDigitalSignatureApplication");
	EndIf;
	
	If Not ValueIsFilled(SavedProperties.Ref)
	   And TypeOf(FillingValues) = Type("Structure")
	   And FillingValues.Property("Organization")
	   And ValueIsFilled(FillingValues.Organization)
	   And Not AttributesParameters.Property("Organization") Then
	
		Parameters = New Structure;
		Parameters.Insert("ReadOnly",     True);
		Parameters.Insert("FillChecking", False);
		Parameters.Insert("Visible",          True);
		AttributesParameters.Insert("Organization", Parameters);
	EndIf;
	
	Return SavedProperties;
	
EndFunction

// For internal use only.
// 
// Parameters:
//  Form - ClientApplicationForm:
//    * CertificateAttributeParameters - See NewParametersForCertificateDetails
//  Application - Undefined
//  ToEncrypt - Boolean
//
Procedure WriteCertificateToCatalog(Form, Application = Undefined, ToEncrypt = False) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Description",   Form.DescriptionCertificate);
	AdditionalParameters.Insert("User",   Form.CertificateUser1);
	AdditionalParameters.Insert("Organization",    Form.CertificateCompany);
	AdditionalParameters.Insert("Individual", Form.CertificateIndividual);
	
	If Not ToEncrypt Then
		AdditionalParameters.Insert("Application", Application);
		AdditionalParameters.Insert("EnterPasswordInDigitalSignatureApplication",
			Form.CertificateEnterPasswordInElectronicSignatureProgram);
	EndIf;
	
	If Not ValueIsFilled(Form.Certificate) Then
		AttributesToSkip1 = New Map;
		AttributesToSkip1.Insert("Ref",         True);
		AttributesToSkip1.Insert("Description",   True);
		AttributesToSkip1.Insert("Organization",    True);
		AttributesToSkip1.Insert("Individual", True);
		AttributesToSkip1.Insert("EnterPasswordInDigitalSignatureApplication", True);
		If Not ToEncrypt And Form.PersonalListOnAdd Then
			AttributesToSkip1.Insert("User",  True);
		EndIf;
		For Each KeyAndValue In Form.CertificateAttributeParameters Do
			AttributeName = KeyAndValue.Key;
			Properties     = KeyAndValue.Value; // See TheNewSettingsOfTheRequisiteCertificate
			If AttributesToSkip1.Get(AttributeName) <> Undefined Then
				Continue;
			EndIf;
			If Properties.FillValue = Undefined Then
				Continue;
			EndIf;
			AdditionalParameters.Insert(AttributeName, Properties.FillValue);
		EndDo;
	EndIf;
	
	Form.Certificate = DigitalSignature.WriteCertificateToCatalog(Form.AddressOfCertificate,
		AdditionalParameters);
	
EndProcedure

// For internal use only.
//
// Parameters:
//   List - DynamicList
//
Procedure SetCertificateListConditionalAppearance(List, ExcludeApplications = False) Export
	
	ConditionalAppearanceItem = List.ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	AppearanceColorItem.Use = True;
	
	If ExcludeApplications And Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.SetCertificateListConditionalAppearance(
			ConditionalAppearanceItem);
	EndIf;
	
	FilterItemsGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterItemsGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	
	DataFilterItem = FilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Revoked");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use  = True;
	
	DataFilterItem = FilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("ValidBefore");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Greater;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("");
	AppearanceFieldItem.Use = True;
	
EndProcedure

// For internal use only.
//
// Parameters:
//   CertificateData - BinaryData
//
Function CertificateFromBinaryData(CertificateData) Export
	
	If TypeOf(CertificateData) <> Type("BinaryData") Then
		Return Undefined;
	EndIf;
	
	Try
		CryptoCertificate = New CryptoCertificate(CertificateData);
	Except
		CryptoCertificate = Undefined;
	EndTry;
	
	If CryptoCertificate <> Undefined Then
		Return CryptoCertificate;
	EndIf;
	
	TempFileFullName = GetTempFileName("cer");
	CertificateData.Write(TempFileFullName);
	Text = New TextDocument;
	Text.Read(TempFileFullName);
	
	Try
		DeleteFiles(TempFileFullName);
	Except
		WriteLogEvent(
			NStr("ru = 'Электронная подпись.Удаление временного файла';
				|en = 'Digital signature.Delete temporary file';",
				Common.DefaultLanguageCode()),
			EventLogLevel.Error, , ,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	If StrStartsWith(Text.GetLine(1), "MII") Then
		Base64Row = Text.GetText();
	Else
		If Text.LineCount() < 3
			Or Text.GetLine(1) <> "-----BEGIN CERTIFICATE-----"
			Or Text.GetLine(Text.LineCount()) <> "-----END CERTIFICATE-----" Then
			
			Return Undefined;
		EndIf;
		
		Text.DeleteLine(1);
		Text.DeleteLine(Text.LineCount());
		Base64Row = Text.GetText();
	EndIf;
	
	Try
		CertificateData = Base64Value(Base64Row);
	Except
		Return Undefined;
	EndTry;
	
	If TypeOf(CertificateData) <> Type("BinaryData") Then
		Return Undefined;
	EndIf;
	
	Try
		CryptoCertificate = New CryptoCertificate(CertificateData);
	Except
		CryptoCertificate = Undefined;
	EndTry;
	
	Return CryptoCertificate;
	
EndFunction

// For internal use only.
//
// Parameters:
//   Form - ClientApplicationForm
//
Procedure SetPasswordEntryNote(Form, ItemNameEnterPasswordInElectronicSignatureProgram = "", ItemNameEnhancedPasswordNote = "") Export
	
	If ValueIsFilled(ItemNameEnterPasswordInElectronicSignatureProgram) Then
		Item = Form.Items[ItemNameEnterPasswordInElectronicSignatureProgram]; // FormField
		Item.Title = NStr("ru = 'Вводить пароль в приложении электронной подписи';
								|en = 'Protect digital signing app with password';");
		Item.ToolTip =
			NStr("ru = '- Приложение электронной подписи запрашивает пароль и позволяет его сохранить.
			           |- Отключается запрос пароля в приложении 1С:Предприятие.
			           |
			           |Обязательно для закрытых ключей сертификатов, для которых в операционной системе включена усиленная защита.';
						|en = '- The digital signing app prompts for a password and allows you to save it.
						|- 1C:Enterprise never prompts for a password.
						|
						|It is required for private keys of the certificates with strong protection enabled in the OS.';");
	EndIf;
	
	If ValueIsFilled(ItemNameEnhancedPasswordNote) Then
		Item = Form.Items[ItemNameEnhancedPasswordNote];
		Item.ToolTip =
			NStr("ru = 'Для выбранного сертификата указано ""Вводить пароль в приложении электронной подписи"".';
				|en = 'The option ""Protect digital signing app with password"" is set for this certificate.';");
	EndIf;
	
EndProcedure

// Parameters:
//  Form - ClientApplicationForm
//  Title - String
//
Procedure ToSetTheTitleOfTheBug(Form, Title) Export
	
	Form.Title = Title;
	
	TitleWidth = StrLen(Form.Title);
	If TitleWidth > 80 Then
		TitleWidth = 80;
	EndIf;
	If TitleWidth > Form.Width Then
		Form.Width = TitleWidth;
	EndIf;
	
EndProcedure

// For internal use only.
Procedure ExecuteDataProcessingRegularTask(QueryOptions, ExecutionParameters) Export

	Query = RequestForExtensionSignatureCredibility(QueryOptions);

	If Query = Undefined Then
		Return;
	EndIf;
	
	While True Do
		SetPrivilegedMode(True);
		QueryResult = Query.Execute();
		SetPrivilegedMode(False);
		If QueryResult.IsEmpty() Then
			Break;
		EndIf;
		Selection = QueryResult.Select();
		ImproveRegularTask(Selection, ExecutionParameters);
	EndDo;
		
EndProcedure

// For internal use only.
Procedure ImproveRegularTask(Selection, ExecutionParameters)
	
	SignatureType = ExecutionParameters.SignatureType;
	AddArchiveTimestamp = ExecutionParameters.RequiredAddArchiveTags;
	
	While Selection.Next() Do
		
		Signature = Selection.Signature.Get();
		
		If ExecutionParameters.ServiceAccountDSS = Undefined Then
			
			CreationParameters = CryptoManagerCreationParameters();
			CreationParameters.SignAlgorithm =
				DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(Signature);
			CryptoManager = CryptoManager(
				"ExtensionValiditySignature", CreationParameters);
			
			If CryptoManager = Undefined Then
				SignatureProperties = New Structure("SignedObject, SequenceNumber",
					Selection.SignedObject, Selection.SequenceNumber);
				LogErrorImprovementsSignaturesInLog(CreationParameters.ErrorDescription, SignatureProperties);
				Raise CreationParameters.ErrorDescription;
			EndIf;
			
			CryptoManager.TimestampServersAddresses = ExecutionParameters.TimestampServersAddresses;
			
			Result = DigitalSignature.EnhanceSignature(
				Signature, SignatureType, AddArchiveTimestamp, CryptoManager);
				
		Else
			Result = RefineSignatureInService(Signature, ExecutionParameters);
		EndIf;
		
		SignatureProperties = Result.SignatureProperties;
			
		If Not Result.Success Then
			If SignatureProperties = Undefined Then
				SignatureProperties = DigitalSignatureClientServer.NewSignatureProperties();
			EndIf;
			SignatureProperties.SignedObject = Selection.SignedObject;
			SignatureProperties.SequenceNumber = Selection.SequenceNumber;
			SignatureProperties.IsErrorOccurredDuringAutomaticRenewal = True;
			
			LogErrorImprovementsSignaturesInLog(Result.ErrorText, SignatureProperties);
			
			ErrorPresentation = UpdateAdvancedSignature(SignatureProperties);
			If Not IsBlankString(ErrorPresentation) Then
				Raise ErrorPresentation;
			EndIf;
			Continue;
		EndIf;
		
		SignatureProperties.SignedObject = Selection.SignedObject;
		SignatureProperties.SequenceNumber = Selection.SequenceNumber;
		ErrorPresentation = UpdateAdvancedSignature(SignatureProperties);
		If Not IsBlankString(ErrorPresentation) Then
			Raise ErrorPresentation;
		EndIf;
		
		If ValueIsFilled(SignatureProperties.Signature) Then
			RegisterImprovementSignaturesInJournal(SignatureProperties);
		EndIf;
		
	EndDo;
	
EndProcedure

// For internal use only.
Procedure RegisterImprovementSignaturesInJournal(SignatureProperties) Export
	
	SignedObject = SignatureProperties.SignedObject;
	SignedObjectMetadata = SignedObject.Metadata();
	
	EventName = NStr("ru = 'Электронная подпись.УсовершенствованиеПодписи';
						|en = 'Digital signature. EnhanceSignatures';",
		Common.DefaultLanguageCode());
		
	EventLogMessage = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Порядковый номер подписи %1, тип подписи %2, срок действия %3';
			|en = 'Signature sequence number %1, signature type %2, validity period %3';"), 
		SignatureProperties.SequenceNumber, SignatureProperties.SignatureType, SignatureProperties.DateActionLastTimestamp);
	
	WriteLogEvent(EventName,
		EventLogLevel.Information,
		SignedObjectMetadata,
		SignedObject,
		EventLogMessage);
	
EndProcedure 
	
// For internal use only.
Procedure LogErrorImprovementsSignaturesInLog(ErrorDescription, SignatureProperties = Undefined) 
	
	If SignatureProperties <> Undefined Then
		ErrorDescription = ErrorDescription + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Порядковый номер подписи %1';
				|en = 'Signature sequence number %1';"), SignatureProperties.SequenceNumber);
		SignedObject = SignatureProperties.SignedObject;
		SignedObjectMetadata = SignedObject.Metadata();
	Else
		SignedObject = Undefined;
		SignedObjectMetadata = Undefined;
	EndIf;
	
	EventName = NStr("ru = 'Электронная подпись.Усовершенствование подписи';
						|en = 'Digital signature.Enhance signature';",
			Common.DefaultLanguageCode());
	WriteLogEvent(EventName,
		EventLogLevel.Warning,
		SignedObjectMetadata,
		SignedObject,
		ErrorDescription);

EndProcedure

// For internal use only.
Function UpdateAdvancedSignature(SignatureProperties) Export
	
	ErrorPresentation = ""; 
	Try
		DigitalSignature.UpdateSignature(SignatureProperties.SignedObject, SignatureProperties, True);
	Except
		ErrorInfo = ErrorInfo();
		ErrorPresentation = NStr("ru = 'Не удалось записать подписи по причине:';
									|en = 'Cannot save the signatures due to:';")
			+ Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo);
	EndTry;

	Return ErrorPresentation;
	
EndFunction

// For internal use only.
Function RefineSignatureInService(Signature, ExecutionParameters)
	
	Result = New Structure("Success, ErrorText, SignatureProperties", 
		False,, DigitalSignatureClientServer.NewSignatureProperties());
	
	If ExecutionParameters.SignatureType <> Enums.CryptographySignatureTypes.WithTimeCAdEST Then
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Невозможно усовершенствовать подпись в приложении в Интернете до типа: %1.';
				|en = 'Couldn''t enhance the signature in the web application to type: %1.';"), 
				ExecutionParameters.SignatureType);
		Return Result;
	EndIf;
		
	Try
		ModuleServiceCryptographyDSSASNClientServer = Common.CommonModule("DssasnClientServerCryptographyService");
		SignatureProperties = ModuleServiceCryptographyDSSASNClientServer.GetSignatureProperties(
			Signature, New Structure("CertificateData", True));
		Certificate = SignatureProperties[0].Certificate;
		CryptoCertificate = New CryptoCertificate(Certificate);
		SignatureType = ServiceSignatureType(SignatureProperties[0].SignatureType);
	Except
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось усовершенствовать подпись в приложении в Интернете по причине:
			|%1';
			|en = 'Cannot enhance the signature in the web application due to:
			|%1';"), ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return Result;
	EndTry;
	
	Result.SignatureProperties.SignatureType = SignatureType;
	
	CertificateProperties = DigitalSignature.CertificateProperties(CryptoCertificate);
	
	If SignatureType <> Enums.CryptographySignatureTypes.BasicCAdESBES Then
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Нельзя усовершенствовать подпись с типом %1 в приложении в Интернете';
				|en = 'Cannot enhance the signature with type %1 in the web application';"), SignatureType);
			
		If SignatureType = Enums.CryptographySignatureTypes.NormalCMS Then
			Result.SignatureProperties.DateActionLastTimestamp = CertificateProperties.ValidBefore;
		EndIf;
		Return Result;
	EndIf;
	
	If Not ExecutionParameters.ShouldIgnoreCertificateValidityPeriod 
		And CertificateProperties.ValidBefore < CurrentSessionDate() Then 
		InformationAboutCertificate =
			DigitalSignatureInternalClientServer.DetailsCertificateString(CertificateProperties);
	
		Result.SignatureProperties.DateActionLastTimestamp = CertificateProperties.ValidBefore;
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Срок действия сертификата подписи истек:
			|%1';
			|en = 'Certificate expired:
			|%1';"), InformationAboutCertificate);
			
		Return Result;
		
	EndIf;
	
	TheDSSCryptographyServiceModule = Common.CommonModule("DSSCryptographyService");
	CertificateVerificationResult = TheDSSCryptographyServiceModule.CheckCertificate(
		ExecutionParameters.ServiceAccountDSS, Certificate);
			
	If CertificateVerificationResult.Completed2 = False Or CertificateVerificationResult.Result <> True Then
		InformationAboutCertificate =
			DigitalSignatureInternalClientServer.DetailsCertificateString(CertificateProperties);
		Result.SignatureProperties.DateActionLastTimestamp = CertificateProperties.EndDate;
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось проверить сертификат в приложении в Интернете, подробности см. в журнале регистрации:
				|%1';
				|en = 'Cannot verify the certificate in the web application. For more information, see the event log:
				|%1';"), InformationAboutCertificate);
	
		Return Result;
	EndIf;
	
	SignatureParameters = ExecutionParameters.ParametersSignatureCAdEST;
	QueryResult = TheDSSCryptographyServiceModule.EnhanceSignature(
		ExecutionParameters.ServiceAccountDSS, Signature, SignatureParameters);
	If QueryResult.Completed2 Then
		SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(
			QueryResult.Result, False, True);
		If Not ValueIsFilled(SignAlgorithm) Then
			Result.ErrorText = NStr("ru = 'При усовершенствовании подписи в приложении в Интернете получен некорректный ответ:';
										|en = 'When enhancing the signature in the web application, an invalid response is received:';") 
				+ Chars.LF + QueryResult.Result;
		Else
			Result.Success = True;
			Result.SignatureProperties.SignatureType = ExecutionParameters.SignatureType;
			Result.SignatureProperties.Signature = QueryResult.Result;
		EndIf;
	Else
		Result.ErrorText = 
			NStr("ru = 'Не удалось усовершенствовать подпись в приложении в Интернете. Описание ошибки см. в журнале регистрации.';
				|en = 'Cannot enhance the signature in the web application. For the error details, see the event log.';");
	EndIf;
	
	If QueryResult.MarkerUpdated Then
		ExecutionParameters.ServiceAccountDSS = QueryResult.UserSettings;
	EndIf;
		
	Return Result;
	
EndFunction 

// For internal use only.
Function ServiceSignatureType(SignatureType)
	
	If SignatureType = "CAdES-BES" Then
		Return Enums.CryptographySignatureTypes.BasicCAdESBES;
	ElsIf SignatureType = "CadES-T" Then
		Return Enums.CryptographySignatureTypes.WithTimeCAdEST;
	ElsIf SignatureType = "CMS" Then
		Return Enums.CryptographySignatureTypes.NormalCMS;
	ElsIf SignatureType = "CAdES-Av3" Then
		Return Enums.CryptographySignatureTypes.ArchivalCAdESAv3;
	ElsIf SignatureType = "CadES-X Long Type 2" Then
		Return Enums.CryptographySignatureTypes.ExtendedLongCAdESXLongType2;
	ElsIf SignatureType = "CadES-From1" Then
		Return Enums.CryptographySignatureTypes.WithCompleteValidationDataReferencesCAdESC;
	EndIf;
	
	Return Undefined;
	
EndFunction

// For internal use only.
Function ServiceAccountSettingsToImproveSignatures(FormIdentifier = Undefined) Export
	
	ServiceAccountSettings = New Structure("ServiceAccountDSS, Error, ParametersSignatureCAdEST");
	
	TheDSSCryptographyServiceModule = Common.CommonModule("DSSCryptographyService");
	ConnectionSettings = TheDSSCryptographyServiceModule.ServiceAccountConnectionSettings();
	
	If ValueIsFilled(ConnectionSettings.Error) Then
		ServiceAccountSettings.Error = ConnectionSettings.Error;
		Return ServiceAccountSettings;
	EndIf;
	
	TheDSSCryptographyServiceModuleClientServer = Common.CommonModule("DSSCryptographyServiceClientServer");
	Result = TheDSSCryptographyServiceModule.LoginAuthentication(ConnectionSettings.Result);

	If Result.Completed2 Then
		TimestampServersAddresses = TheDSSCryptographyServiceModuleClientServer.GetServerStampsTime(
			Result.UserSettings);
			
		If TimestampServersAddresses.Count() = 0 Then
			ServiceAccountSettings.Error =
				NStr("ru = 'В служебной учетной записи нет доступных адресов серверов меток времени';
					|en = 'Service account does not contain available timestamp server addresses';");
			Return ServiceAccountSettings;
		EndIf;
		
		If FormIdentifier = Undefined Then
			ServiceAccountSettings.ServiceAccountDSS = Result.UserSettings;
		Else
			ServiceAccountSettings.ServiceAccountDSS = 
				PutToTempStorage(Result.UserSettings, FormIdentifier);
		EndIf;
		
	Else
		ServiceAccountSettings.Error = Result.Error;
		Return ServiceAccountSettings;
	EndIf;
		
	ServiceAccountSettings.ParametersSignatureCAdEST = 
		TheDSSCryptographyServiceModuleClientServer.GetCAdESSignatureProperty(
			"T", True, False, "Signature", TimestampServersAddresses[0].Address);

	Return ServiceAccountSettings;
	
EndFunction

// For internal use only.
Function EnhanceServerSide(Parameters) Export
	
	Result = New Structure;
	Result.Insert("Success", False);
	Result.Insert("ErrorText", "");
	Result.Insert("SignatureProperties", DigitalSignatureClientServer.NewSignatureProperties());
	Result.Insert("SignAlgorithm");
	Result.Insert("ErrorCreatingCryptoManager", False);
	Result.Insert("OperationStarted", Parameters.OperationStarted);
	
	Signature = Parameters.DataItemForSErver.Signature;
	If TypeOf(Signature) = Type("String") Then
		Try
			Signature = GetFromTempStorage(Signature);
		Except
			ErrorInfo = ErrorInfo();
			Result.ErrorText = DigitalSignatureInternalClientServer.DataGettingErrorTitle("ExtensionValiditySignature")
			 + Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo);
			Return Result;
		EndTry;
	EndIf;
	
	SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(Signature);
	Result.SignAlgorithm = SignAlgorithm;
	
	If Parameters.ThisistheServiceModelwithEnhancementAvailable Then
	
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("SignatureType", Parameters.SignatureType);
		ExecutionParameters.Insert("ParametersSignatureCAdEST", Parameters.ParametersSignatureCAdEST);
		ExecutionParameters.Insert("ServiceAccountDSS", Parameters.ServiceAccountDSS);
		ExecutionParameters.Insert("ShouldIgnoreCertificateValidityPeriod", Parameters.ShouldIgnoreCertificateValidityPeriod);
		
		QueryResult = RefineSignatureInService(Signature, ExecutionParameters);
		FillPropertyValues(Result, QueryResult);

		If Result.Success Then
			If Parameters.DataItemForSErver.Property("SignedObject") Then
				
				Result.SignatureProperties.SignedObject = Parameters.DataItemForSErver.SignedObject;
				Result.SignatureProperties.SequenceNumber = Parameters.DataItemForSErver.SequenceNumber;
				ErrorPresentation = UpdateAdvancedSignature(Result.SignatureProperties);
				
				If ValueIsFilled(ErrorPresentation) Then
					Result.Success = False;
					Result.ErrorText = ErrorPresentation;
					Return Result;
				EndIf;
				
				If ValueIsFilled(Result.SignatureProperties.Signature) Then
					RegisterImprovementSignaturesInJournal(Result.SignatureProperties);
				EndIf;
				
			EndIf; 
		Else
			Return Result;
		EndIf;
		
		PutToTempStorage(ExecutionParameters.ServiceAccountDSS, Parameters.ServiceAccountDSSSaddress);
		
	Else
		
		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.ErrorDescription = New Structure;
		CreationParameters.SignAlgorithm = SignAlgorithm;
		
		CryptoManager = CryptoManager("ExtensionValiditySignature", CreationParameters);
		
		If CryptoManager = Undefined Then
			Result.ErrorText = CreationParameters.ErrorDescription;
			Result.ErrorCreatingCryptoManager = True;
			Return Result;
		EndIf;
		
		CryptoManager.TimestampServersAddresses = DigitalSignature.CommonSettings().TimestampServersAddresses;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("CryptoManager", CryptoManager);
		AdditionalParameters.Insert("ShouldIgnoreCertificateValidityPeriod", Parameters.ShouldIgnoreCertificateValidityPeriod);
		
		If Parameters.DataItemForSErver.Property("SignedObject") Then
			QueryResult = DigitalSignature.ImproveObjectSignature(Parameters.DataItemForSErver.SignedObject,
				Parameters.DataItemForSErver.SequenceNumber, Parameters.SignatureType,
				Parameters.AddArchiveTimestamp, Parameters.FormIdentifier, AdditionalParameters);
		Else
			QueryResult = DigitalSignature.EnhanceSignature(Signature, Parameters.SignatureType,
				Parameters.AddArchiveTimestamp, AdditionalParameters);
		EndIf;
		
		FillPropertyValues(Result, QueryResult);
		
	EndIf;
	
	If Not Result.Success Then
		Return Result;
	EndIf;
	
	Result.OperationStarted = True;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Infobase update.

////////////////////////////////////////////////////////////////////////////////
// XMLDSig operations.

// Signs the message by inserting the signature data into the XMLEnvelope.
//
// Parameters:
//  XMLEnvelope             - See DigitalSignatureClient.XMLEnvelope
//  XMLDSigParameters       - See DigitalSignatureClient.XMLDSigParameters
//  CryptoCertificate - CryptoCertificate - a crypto certificate to be used.
//  CryptoManager   - CryptoManager   - a crypto manager
//                           that matches the private key of the certificate with the set password.
//
// Returns:
//  String - the signed XMLEnvelope.
//
Function Sign(Val XMLEnvelope, XMLDSigParameters, CryptoCertificate, CryptoManager) Export
	
	Password = CryptoManager.PrivateKeyAccessPassword;
	
	ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
	
	CryptoProviderProperties = CryptoProviderProperties(CryptoManager);
	ComponentObject.CryptoProviderPath = CryptoProviderProperties.Path;
	
	XMLEnvelopeProperties = XMLEnvelopeProperties(XMLEnvelope, XMLDSigParameters, False);
	If XMLEnvelopeProperties <> Undefined
	   And ValueIsFilled(XMLEnvelopeProperties.ErrorText) Then
		Raise XMLEnvelopeProperties.ErrorText;
	EndIf;
	
	Base64CryptoCertificate = DigitalSignatureInternalClientServer.Base64CryptoCertificate(
		CryptoCertificate.Unload());
	
	SigningAlgorithmData = New Structure(New FixedStructure(XMLDSigParameters));
	DigitalSignatureInternalClientServer.CheckChooseSignAlgorithm(
		Base64CryptoCertificate, SigningAlgorithmData, True, XMLEnvelopeProperties);
	
	XMLEnvelope = StrReplace(XMLEnvelope, "%BinarySecurityToken%", Base64CryptoCertificate);
	XMLEnvelope = StrReplace(XMLEnvelope, "%SignatureMethod%", SigningAlgorithmData.SelectedSignatureAlgorithm);
	XMLEnvelope = StrReplace(XMLEnvelope, "%DigestMethod%",    SigningAlgorithmData.SelectedHashAlgorithm);
	
	If XMLEnvelopeProperties <> Undefined Then
		For IndexOf = 0 To XMLEnvelopeProperties.AreasToHash.UBound() Do
			HashedArea = XMLEnvelopeProperties.AreasToHash[IndexOf];
			CanonizedTextXMLBody = CanonizedXMLText(ComponentObject,
				XMLEnvelopeProperties.AreasBody[IndexOf], HashedArea.TransformationAlgorithms);
			DigestValueAttribute = HashResult(ComponentObject, CanonizedTextXMLBody,
				SigningAlgorithmData.SelectedHashAlgorithmOID, CryptoProviderProperties.Type);

			XMLEnvelope = StrReplace(XMLEnvelope, HashedArea.HashValue, DigestValueAttribute);
		EndDo;
	Else
		CanonizedTextXMLBody = C14N(ComponentObject, XMLEnvelope,
			SigningAlgorithmData.XPathTagToSign);
		
		DigestValueAttribute = HashResult(ComponentObject, CanonizedTextXMLBody,
			SigningAlgorithmData.SelectedHashAlgorithmOID, CryptoProviderProperties.Type);

		XMLEnvelope = StrReplace(XMLEnvelope, "%DigestValue%", DigestValueAttribute);
	EndIf;
	
	If XMLEnvelopeProperties = Undefined Then
		CanonizedTextXMLSignedInfo = C14N(ComponentObject,
			XMLEnvelope, SigningAlgorithmData.XPathSignedInfo);
	Else
		SignedInfoArea = DigitalSignatureInternalClientServer.XMLScope(XMLEnvelope,
			XMLEnvelopeProperties.SignedInfoArea.TagName);
		SignedInfoArea.NamespacesUpToANode =
			XMLEnvelopeProperties.SignedInfoArea.NamespacesUpToANode;
		
		If ValueIsFilled(SignedInfoArea.ErrorText) Then
			Raise SignedInfoArea.ErrorText;
		EndIf;
		
		CanonizedTextXMLSignedInfo = CanonizedXMLText(ComponentObject,
			SignedInfoArea,
			CommonClientServer.ValueInArray(XMLEnvelopeProperties.TheCanonizationAlgorithm));
	EndIf;
	
	SignatureValueAttribute = SignResult(ComponentObject,
		CanonizedTextXMLSignedInfo,
		CryptoCertificate,
		Password);
	
	XMLEnvelope = StrReplace(XMLEnvelope, "%SignatureValue%", SignatureValueAttribute);
	
	Return XMLEnvelope;
	
EndFunction

// Returns a certificate, by which the signature was made.
// If the signature check fails, an exception is generated.
//
// Parameters:
//  XMLEnvelope           - See DigitalSignatureClient.XMLEnvelope
//  XMLDSigParameters     - See DigitalSignatureClient.XMLDSigParameters
//  CryptoManager - CryptoManager - a crypto manager
//                         that supports the algorithms of the signature to be checked.
//  XMLEnvelopeProperties  - See XMLEnvelopeProperties
//
// Returns:
//  Structure:
//   * Certificate     - CryptoCertificate
//   * SigningDate - Date
//
Function VerifySignature(Val XMLEnvelope, XMLDSigParameters, CryptoManager, XMLEnvelopeProperties = Undefined) Export
	
	ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
	
	CryptoProviderProperties = CryptoProviderProperties(CryptoManager);
	ComponentObject.CryptoProviderPath = CryptoProviderProperties.Path;
	SigningAlgorithmData = New Structure(New FixedStructure(XMLDSigParameters));
	
	If XMLEnvelopeProperties = Undefined Then
		CanonizedTextXMLSignedInfo = C14N(ComponentObject,
			XMLEnvelope, SigningAlgorithmData.XPathSignedInfo);
		CanonizedTextXMLBody = C14N(ComponentObject,
			XMLEnvelope, SigningAlgorithmData.XPathTagToSign);
		Base64CryptoCertificate = DigitalSignatureInternalClientServer.CertificateFromSOAPEnvelope(XMLEnvelope);
		SignatureValue = DigitalSignatureInternalClientServer.FindInXML(XMLEnvelope, "SignatureValue");
		HashValue    = DigitalSignatureInternalClientServer.FindInXML(XMLEnvelope, "DigestValue");
	Else
		CanonizedTextXMLSignedInfo = CanonizedXMLText(ComponentObject,
			XMLEnvelopeProperties.SignedInfoArea,
			CommonClientServer.ValueInArray(XMLEnvelopeProperties.TheCanonizationAlgorithm));
		
		SignatureValue = XMLEnvelopeProperties.SignatureValue;
		Base64CryptoCertificate = XMLEnvelopeProperties.Certificate.CertificateValue;
		
	EndIf;
	
	DigitalSignatureInternalClientServer.CheckChooseSignAlgorithm(
		Base64CryptoCertificate, SigningAlgorithmData, True, XMLEnvelopeProperties);
		
	SignatureCorrect = VerifySignResult(ComponentObject,
		CanonizedTextXMLSignedInfo,
		SignatureValue,
		Base64CryptoCertificate,
		CryptoProviderProperties.Type);

	If XMLEnvelopeProperties <> Undefined Then
		
		Counter = 1;
		For Each HashedArea In XMLEnvelopeProperties.AreasToHash Do
			CanonizedTextXMLBody = CanonizedXMLText(ComponentObject,
				XMLEnvelopeProperties.AreasBody[Counter-1], HashedArea.TransformationAlgorithms);
			HashValue = HashedArea.HashValue; 
			
			DigestValueAttribute = HashResult(ComponentObject,
				CanonizedTextXMLBody,
				SigningAlgorithmData.SelectedHashAlgorithmOID,
				CryptoProviderProperties.Type);
				
			HashMaps = (DigestValueAttribute = HashValue);
			
			If Not HashMaps Or Not SignatureCorrect Then
				Raise DigitalSignatureInternalClientServer.XMLSignatureVerificationErrorText(SignatureCorrect, HashMaps);
			EndIf;
			Counter = Counter + 1;
		EndDo;
		
		Return XMLSignatureVerificationResult(Base64CryptoCertificate);
		
	EndIf;
	
	DigestValueAttribute = HashResult(ComponentObject,
		CanonizedTextXMLBody,
		SigningAlgorithmData.SelectedHashAlgorithmOID,
		CryptoProviderProperties.Type);
	
	HashMaps = (DigestValueAttribute = HashValue);
	
	If HashMaps And SignatureCorrect Then
		Return XMLSignatureVerificationResult(Base64CryptoCertificate);
	Else
		Raise DigitalSignatureInternalClientServer.XMLSignatureVerificationErrorText(SignatureCorrect, HashMaps);
	EndIf;
	
EndFunction

Function XMLSignatureVerificationResult(Base64CryptoCertificate)
	
	BinaryData = Base64Value(Base64CryptoCertificate);

	Result = New Structure;
	Result.Insert("Certificate", New CryptoCertificate(BinaryData));
	Result.Insert("SigningDate", Undefined);

	Return Result;
		
EndFunction

// Calculates and checks the properties of the XML envelope for signing and checking the signature.
//
// Parameters:
//  XMLEnvelope             - See DigitalSignatureClient.XMLEnvelope
//  XMLDSigParameters       - See DigitalSignatureClient.XMLDSigParameters
//  CheckSignature  - Boolean - If False, the envelope is checked for 
//                                substitution parameters and canonicalization algorithms.
//                              If True, the envelope contains correct algorithms of
//                                canonicalization, signing, and hashing, and filled in
//                                values of signature, hash, and certificate.
//
// Returns:
//   See ReturnedPropertiesOfTheXMLEnvelope
//
Function XMLEnvelopeProperties(XMLEnvelope, XMLDSigParameters, CheckSignature) Export
	
	If ValueIsFilled(XMLDSigParameters.XPathSignedInfo)
	 Or ValueIsFilled(XMLDSigParameters.XPathTagToSign) Then
		Return Undefined; // Backward compatibility.
	EndIf;
	
	XMLReader = New XMLReader;
	XMLReader.SetString(XMLEnvelope);
	
	DOMBuilder = New DOMBuilder;
	DOMDocument = DOMBuilder.Read(XMLReader);
	
	XMLReader.Close();
	
	XMLEnvelopeProperties = ServicePropertiesOfTheXMLEnvelope(CheckSignature);
	
	SignatureNodeName = "Signature";
	NameOfTheSignatureNodeNamespace = "http://www.w3.org/2000/09/xmldsig#";
	NamespacesUpToAndIncludingTheSignatureNode = New Array;
	
	ExcludedNodes = New Array;
	NumberSingnature = 0;
	While True Do
		NumberSingnature = NumberSingnature + 1;
		SignatureNode = FindANodeByName(DOMDocument,
			SignatureNodeName, NameOfTheSignatureNodeNamespace,
			XMLEnvelopeProperties.ErrorText, ExcludedNodes, NamespacesUpToAndIncludingTheSignatureNode);
		If SignatureNode = Undefined Then
			Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
		EndIf;
		
		// If the node's text contains the signature value, this means that signature overlapping is used.
		// Find a different node.
		If StrFind(SignatureNode.TextContent, "%SignatureValue%") = 0 And Not CheckSignature Then
			ExcludedNodes.Add(SignatureNode);
			Continue;
		Else
			Break;
		EndIf;
	EndDo;
	
	For Each ChildNode In SignatureNode.ChildNodes Do
		If ChildNode.LocalName = "SignedInfo" Then
			If Not ProcessTheSignedInfoNode(ChildNode, XMLEnvelopeProperties) Then
				Break;
			EndIf;
		ElsIf ChildNode.LocalName = "SignatureValue" Then
			If Not GetValue(ChildNode, XMLEnvelopeProperties, "SignatureValue") Then
				Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
			EndIf;
		ElsIf ChildNode.LocalName = "KeyInfo" Then
			If Not ProcessTheKeyInfoNode(ChildNode, XMLEnvelopeProperties) Then
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	If ValueIsFilled(XMLEnvelopeProperties.ErrorText) Then
		Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
	EndIf;
	
	For Each KeyAndValue In XMLEnvelopeProperties.RequiredNodes Do
		If KeyAndValue.Value <> Undefined Then
			Continue;
		EndIf;
		NameParts = StrSplit(KeyAndValue.Key, "_");
		If NameParts.Count() > 1 Then
			XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В документе XML не найден узел ""%1"" в узле ""%2"".';
					|en = '%1 node is not found in %2 node in XML document.';"), KeyAndValue.Key);
		Else
			XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В документе XML не найден узел ""%1"".';
					|en = '%1 node is not found in XML document.';"), NameParts[0]);
		EndIf;
		Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
	EndDo;
	
	If ValueIsFilled(XMLEnvelopeProperties.Certificate.NodeID)
	   And ValueIsFilled(XMLEnvelopeProperties.Certificate.CertificateValue) Then
		
		XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В документе XML сертификат объявлен дважды:
			           |- в виде URI ссылки на элемент ""%1"";
			           |- в виде данных ""%2"".';
						|en = 'The certificate is declared twice in the XML document:
						|-as a URI link to %1 item;
						|-as %2 data.';"),
			XMLEnvelopeProperties.Certificate.NodeID,
			XMLEnvelopeProperties.Certificate.CertificateValue);
		
		Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
		
	ElsIf Not ValueIsFilled(XMLEnvelopeProperties.Certificate.NodeID)
	        And Not ValueIsFilled(XMLEnvelopeProperties.Certificate.CertificateValue) Then
		
		XMLEnvelopeProperties.ErrorText =
			NStr("ru = 'В документе XML не найден сертификат.';
				|en = 'The certificate is not found in the XML document.';");
		
		Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
	EndIf;

	ExcludedNodes.Add(SignatureNode);
	
	If ValueIsFilled(XMLEnvelopeProperties.Certificate.NodeID) Then
		CertificateNode = FindANodeByID(DOMDocument,
			XMLEnvelopeProperties.Certificate.NodeID,
			XMLEnvelopeProperties.ErrorText,
			ExcludedNodes);
		If ValueIsFilled(XMLEnvelopeProperties.ErrorText) Then
			Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
		EndIf;
		If Not GetValue(CertificateNode, XMLEnvelopeProperties,
					"CertificateValue", XMLEnvelopeProperties.Certificate) Then
			Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
		EndIf;
		ExcludedNodes.Add(CertificateNode);
	EndIf;
	
	NodesBody = New Array;
	
	For Each HashedArea In XMLEnvelopeProperties.AreasToHash Do
		NamespacesUpToTheBodyNode = New Array;
		BodyNode = FindANodeByID(DOMDocument,
			HashedArea.NodeID,
			XMLEnvelopeProperties.ErrorText,
			ExcludedNodes,
			NamespacesUpToTheBodyNode);
		If ValueIsFilled(XMLEnvelopeProperties.ErrorText) Then
			Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
		EndIf;
		ExcludedNodes.Add(BodyNode);
		NodesBody.Add(BodyNode);
	EndDo;
	
	For Each HashedArea In XMLEnvelopeProperties.AreasToHash Do
		NodeBody2 = FindANodeByID(DOMDocument,
			HashedArea.NodeID,
			XMLEnvelopeProperties.ErrorText, ExcludedNodes, , True);
		If NodeBody2 <> Undefined Then
			Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
		EndIf;
	EndDo;
	
	TheSignedInfoNode = XMLEnvelopeProperties.UniqueNodes.SignedInfo; // DOMElement
	SignedInfoArea = DigitalSignatureInternalClientServer.XMLScope(XMLEnvelope,
		TheSignedInfoNode.TagName, NumberSingnature);
	If ValueIsFilled(SignedInfoArea.ErrorText) Then
		XMLEnvelopeProperties.ErrorText = SignedInfoArea.ErrorText;
		Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
	EndIf;
	SignedInfoArea.NamespacesUpToANode = NamespacesUpToAndIncludingTheSignatureNode;
	XMLEnvelopeProperties.SignedInfoArea = SignedInfoArea;
	
	For Each ItemAreaBody In NodesBody Do
		BodyArea = DigitalSignatureInternalClientServer.XMLScope(XMLEnvelope,
			ItemAreaBody.TagName);
		If ValueIsFilled(BodyArea.ErrorText) Then
			XMLEnvelopeProperties.ErrorText = BodyArea.ErrorText;
			Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
		EndIf;
		BodyArea.NamespacesUpToANode = NamespacesUpToTheBodyNode;
		XMLEnvelopeProperties.AreasBody.Add(BodyArea);
	EndDo;
	
	Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
	
EndFunction

Function AnObjectOfAnExternalComponentOfTheExtraCryptoAPI()
	
	ComponentDetails = DigitalSignatureInternalClientServer.ComponentDetails();
	ComponentObject = Common.AttachAddInFromTemplate(ComponentDetails.ObjectName,
		ComponentDetails.FullTemplateName);
	
	If ComponentObject = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось подключить внешнюю компоненту %1.';
				|en = 'Couldn''t attach add-in ""%1"".';"), ComponentDetails.ObjectName);
		Raise ErrorText;
	EndIf;
	
	ConfigureTheComponent(ComponentObject);
	
	Return ComponentObject;
	
EndFunction

Procedure ConfigureTheComponent(ComponentObject)
	
	Try
		ComponentObject.OIDMap =
			DigitalSignatureInternalClientServer.IdentifiersOfHashingAlgorithmsAndThePublicKey();
	Except
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось установить свойство %1 компоненты %2 по причине:
				|%3';
				|en = 'Cannot set the %1 property of the %2 add-in due to:
				|%3';"), "OIDMap", "ExtraCryptoAPI", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
EndProcedure

// Signs the data and returns a signature with or without data.
//
// Parameters:
//  Data - String - an arbitrary string for signing,
//         - BinaryData - binary data for signing.
//
//  CMSParameters            - Structure - returns the DigitalSignature.CMSParameters function.
//  CryptoCertificate  - CryptoCertificate - a crypto certificate to be used.
//  CryptoManager    - CryptoManager   - a crypto manager to be used.
// 
// Returns:
//  String - a string in the Base64 format.
//
Function SignCMS(Val Data, CMSParameters, CryptoCertificate, CryptoManager) Export
	
	Password = CryptoManager.PrivateKeyAccessPassword;
	
	ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
	
	CryptoProviderProperties = CryptoProviderProperties(CryptoManager);
	ComponentObject.CryptoProviderPath = CryptoProviderProperties.Path;
	
	SignatureValueAttribute = CMSSignResult(ComponentObject,
		Data,
		CMSParameters,
		CryptoCertificate,
		Password);
	
	Return SignatureValueAttribute;
	
EndFunction

Function CheckCMSSignature(Signature, Data, CMSParameters, CryptoManager) Export
	
	ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
	
	CryptoProviderProperties = CryptoProviderProperties(CryptoManager);
	ComponentObject.CryptoProviderPath = CryptoProviderProperties.Path;
	
	Result = CMSVerifySignResult(ComponentObject,
		Signature,
		Data,
		CMSParameters,
		CryptoProviderProperties.Type);
	
	Return Result;
	
EndFunction

// Installed cryptographic service providers
// 
// Returns:
//  Structure:
//   * CheckCompleted - Boolean
//   * Error - String - If "CheckCompleted" is False
//   * Cryptoproviders - Array of Structure:
//      ** Ref - Undefined, CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//      ** Presentation - String
//      ** ApplicationName - String
//      ** ApplicationType - Number
//      ** SignAlgorithm - String
//      ** HashAlgorithm - String
//      ** EncryptAlgorithm - String
//      ** Id - String
//      ** ApplicationPath - String
//      ** Version - String - Library version
//      ** ILicenseInfo - Boolean - App license presence flag
//      ** AutoDetect - Boolean
//
Function InstalledCryptoProviders(ComponentObject = Undefined) Export
	
	Result = New Structure;
	Result.Insert("CheckCompleted", False);
	Result.Insert("Cryptoproviders", New Array);
	Result.Insert("Error", "");
	
	Settings = DigitalSignature.CommonSettings();
	
	If (Not Common.FileInfobase() Or Common.ClientConnectedOverWebServer())
		And Not DigitalSignature.VerifyDigitalSignaturesOnTheServer()
		And Not DigitalSignature.GenerateDigitalSignaturesAtServer() Then
			Result.Error = NStr("ru = 'Не настроена криптография на сервере.';
									|en = 'Cryptography is not configured on the server.';");
			Return Result;
	EndIf;
	
	Try
		If ComponentObject = Undefined Then
			ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
		EndIf; 
		ResultList = ComponentObject.GetListCryptoProviders();
		ApplicationsByNamesWithType = Settings.ApplicationsByNamesWithType;
		InstalledCryptoProviders = DigitalSignatureInternalClientServer.InstalledCryptoProvidersFromAddInResponse(
			ResultList, ApplicationsByNamesWithType, False);
		Result.CheckCompleted = True;
		Result.Cryptoproviders = InstalledCryptoProviders;
	Except
		Result.CheckCompleted = False;
		Result.Error = ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	
	Return Result;
		
EndFunction

Function CryptoProviderProperties(CryptoManager)
	
	CryptoModuleInformation = CryptoManager.GetCryptoModuleInformation();
	
	CryptoProviderName = CryptoModuleInformation.Name;
	
	ErrorDescription = "";
	CryptoProvidersResult = DigitalSignatureInternalCached.InstalledCryptoProviders();
	AppsAuto = DigitalSignatureInternalClientServer.CryptoProvidersSearchResult(CryptoProvidersResult, ComputerName());
		
	If TypeOf(AppsAuto) = Type("String") Then
		ErrorDescription = AppsAuto;
		AppsAuto = Undefined;
	EndIf;
	
	ApplicationDetails = DigitalSignatureInternalClientServer.ApplicationDetailsByCryptoProviderName(CryptoProviderName,
		DigitalSignature.CommonSettings().ApplicationsDetailsCollection, AppsAuto); // See DigitalSignatureInternalCached.ApplicationDetails
	
	If ApplicationDetails = Undefined Then
		If Not IsBlankString(ErrorDescription) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось определить тип криптопровайдера %1. %2';
					|en = 'Cannot determine the type of cryptographic service provider %1. %2';"), CryptoModuleInformation.Name, ErrorDescription);
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось определить тип криптопровайдера %1';
					|en = 'Cannot determine the type of cryptographic service provider %1';"), CryptoModuleInformation.Name);
		EndIf;
		Raise ErrorText;
	EndIf;
	
	If ApplicationDetails.Property("AutoDetect") Then
		DescriptionOfWay = New Structure("ApplicationPath, Exists, ErrorText", ApplicationDetails.PathToAppAuto, True, "");
	Else
		DescriptionOfWay = ApplicationPath(ApplicationDetails.Ref);
	EndIf;
	
	If ValueIsFilled(DescriptionOfWay.ErrorText) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось определить путь к приложению электронной подписи
			           |""%1"" по причине:
			           |%2';
						|en = 'Cannot determine the path to digital signing app
						|""%1"" due to:
						|%2';"),
			ApplicationDetails.Ref,
			DescriptionOfWay.ErrorText);
		Raise ErrorText;
	EndIf;
	
	Properties = New Structure("Type, Path", ApplicationDetails.ApplicationType, "");
	Properties.Path = DescriptionOfWay.ApplicationPath;
	
	Return Properties;
	
EndFunction

Function C14N(ComponentObject, XMLEnvelope, XPath)
	
	Try
		CanonizedXMLText = ComponentObject.C14N(XMLEnvelope, XPath);
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("C14N",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If CanonizedXMLText = Undefined Then
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("C14N",
			ComponentObject.GetLastError());
		Raise ErrorText;
	EndIf;
	
	Return CanonizedXMLText;
	
EndFunction

Function CanonizedXMLText(ComponentObject, XMLScope, Algorithms)
	
	Result = Undefined;
	HigherLevelNamespacesHaveBeenAdded = False;
	
	For Each Algorithm In Algorithms Do
		If Algorithm.Kind = "envsig" Then
			Continue;
		ElsIf Algorithm.Kind = "C14N"
		      Or Algorithm.Kind = "smev" Then
			
			If Not HigherLevelNamespacesHaveBeenAdded Then
				DescriptionOfTheBeginningOfTheArea = DigitalSignatureInternalClientServer.ExtendedBeginningOfTheXMLArea(
					XMLScope, Algorithm, Result);
				If ValueIsFilled(DescriptionOfTheBeginningOfTheArea.ErrorText) Then
					Raise DescriptionOfTheBeginningOfTheArea.ErrorText;
				EndIf;
				XMLText = DigitalSignatureInternalClientServer.XMLAreaText(XMLScope,
					DescriptionOfTheBeginningOfTheArea.Begin);
				HigherLevelNamespacesHaveBeenAdded = True;
				
			ElsIf Result = Undefined Then
				XMLText = DigitalSignatureInternalClientServer.XMLAreaText(XMLScope);
			Else
				XMLText = Result;
			EndIf;
			
			If Algorithm.Kind = "C14N" Then
				Result = C14N_body(ComponentObject, XMLText, Algorithm);
			Else
				Result = CanonizationSMEV(ComponentObject, XMLText);
			EndIf;
		EndIf;
	EndDo;
	
	If Result = Undefined Then
		Result = DigitalSignatureInternalClientServer.XMLAreaText(XMLScope);
	EndIf;
	
	Return Result;
	
EndFunction

Function C14N_body(ComponentObject, XMLText, Algorithm)
	
	Try
		CanonizedXMLText = ComponentObject.c14n_body(XMLText,
			Algorithm.Version, Algorithm.WithComments);
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("C14N_body",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If CanonizedXMLText = Undefined Then
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("C14N_body",
			ComponentObject.GetLastError());
		Raise ErrorText;
	EndIf;
	
	Return CanonizedXMLText;
	
EndFunction

Function CanonizationSMEV(ComponentObject, XMLText)
	
	Try
		CanonizedXMLText = ComponentObject.TransformSMEV(XMLText);
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("TransformSMEV",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If CanonizedXMLText = Undefined Then
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("TransformSMEV",
			ComponentObject.GetLastError());
		Raise ErrorText;
	EndIf;
	
	Return CanonizedXMLText;
	
EndFunction

Function HashResult(ComponentObject, CanonizedTextXMLBody, HashingAlgorithmOID, CryptoProviderType)
	
	Try
		DigestValueAttribute = ComponentObject.Hash(
			CanonizedTextXMLBody,
			HashingAlgorithmOID,
			CryptoProviderType);
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("Hash",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If DigestValueAttribute = Undefined Then
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("Hash",
			ComponentObject.GetLastError());
		Raise ErrorText;
	EndIf;
	
	Return DigestValueAttribute;
	
EndFunction

Function SignResult(ComponentObject, CanonizedTextXMLSignedInfo,
	CryptoCertificate, PrivateKeyAccessPassword)
	
	Base64CryptoCertificate = DigitalSignatureInternalClientServer.Base64CryptoCertificate(
		CryptoCertificate.Unload());
	
	Try
		SignatureValueAttribute = ComponentObject.Sign(
			CanonizedTextXMLSignedInfo,
			Base64CryptoCertificate,
			PrivateKeyAccessPassword);
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("Sign",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If SignatureValueAttribute = Undefined Then
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("Sign",
			ComponentObject.GetLastError());
		Raise ErrorText;
	EndIf;
	
	Return SignatureValueAttribute;
	
EndFunction

Function VerifySignResult(ComponentObject, CanonizedTextXMLSignedInfo,
	SignatureValueAttribute, Base64CryptoCertificate, CryptoProviderType)
	
	Try
		SignatureCorrect = ComponentObject.VerifySign(
			CanonizedTextXMLSignedInfo,
			SignatureValueAttribute,
			Base64CryptoCertificate,
			CryptoProviderType);
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("VerifySign",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If SignatureCorrect = Undefined Then
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("VerifySign",
			ComponentObject.GetLastError());
		Raise ErrorText;
	EndIf;
	
	Return SignatureCorrect;
	
EndFunction

Function CMSSignResult(ComponentObject, DataToSign, CMSParameters, CryptoCertificate, PrivateKeyAccessPassword)
	
	AddInParameters = DigitalSignatureInternalClientServer.AddInParametersCMSSign(CMSParameters, DataToSign);
	
	Base64CryptoCertificate = DigitalSignatureInternalClientServer.Base64CryptoCertificate(
		CryptoCertificate.Unload());
	
	Try
		SignatureValueAttribute = ComponentObject.CMSSign(
			AddInParameters.Data,
			Base64CryptoCertificate,
			PrivateKeyAccessPassword,
			AddInParameters.SignatureType,
			AddInParameters.DetachedAddIn,
			AddInParameters.IncludeCertificatesInSignature);
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("CMSSign",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If Not ValueIsFilled(SignatureValueAttribute) Then
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("CMSSign",
			ComponentObject.GetLastError());
		Raise ErrorText;
	EndIf;
	
	Return SignatureValueAttribute;
	
EndFunction

Function CMSVerifySignResult(ComponentObject, Signature, Data, CMSParameters, CryptoProviderType)
	
	Certificate = Null;
	Try
		SignatureCorrect = ComponentObject.CMSVerifySign(Signature,
			CMSParameters.DetachedAddIn, Data, CryptoProviderType, Certificate);
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("CMSVerifySign",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If SignatureCorrect = Undefined Then
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("CMSVerifySign",
			ComponentObject.GetLastError());
		Raise ErrorText;
		
	ElsIf Not SignatureCorrect Then
		ErrorText = NStr("ru = 'Подпись неверна.';
							|en = 'Invalid signature.';");
		Raise ErrorText;
		
	ElsIf TypeOf(Certificate) <> Type("BinaryData") Then
		ErrorText = NStr("ru = 'Подпись верна, но не содержит данных сертификата.';
							|en = 'The signature is valid but does not contain the certificate data.';");
		Raise ErrorText;
	EndIf;
	
	SigningDate = DigitalSignature.SigningDate(Signature);
	If Not ValueIsFilled(SigningDate) Then
		SigningDate = Undefined;
	EndIf;
	
	ReturnValue = New Structure;
	ReturnValue.Insert("Certificate", New CryptoCertificate(Certificate));
	ReturnValue.Insert("SigningDate", SigningDate);
	
	Return ReturnValue;
	
EndFunction


////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions.

// Intended for: UpdateCertificatesList procedure.
Procedure ProcessAddedCertificates(CertificatesPropertiesTable, ButAlreadyAddedOnes, FilterByCompany = Undefined)
	
	Query = New Query;
	Query.SetParameter("Thumbprints", CertificatesPropertiesTable.Copy(, "Thumbprint"));
	Query.Text =
	"SELECT
	|	Thumbprints.Thumbprint
	|INTO Thumbprints
	|FROM
	|	&Thumbprints AS Thumbprints
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Certificates.Thumbprint,
	|	Certificates.Description AS Presentation,
	|	FALSE AS IsRequest,
	|	Certificates.Organization
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|		INNER JOIN Thumbprints AS Thumbprints
	|		ON Certificates.Thumbprint = Thumbprints.Thumbprint
	|		AND &OptionalConnection";
	
	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.AddRequestWhenAddingCertificates(
			Query.Text);
	Else
		Query.Text = StrReplace(Query.Text, "AND &OptionalConnection", "");
	EndIf;
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		String = CertificatesPropertiesTable.Find(Selection.Thumbprint, "Thumbprint");
		If ButAlreadyAddedOnes Then
			If String <> Undefined Then // Protection against data errors (duplicate certificates).
				CertificatesPropertiesTable.Delete(String);
			EndIf;
		ElsIf ValueIsFilled(FilterByCompany) Then
			If String <> Undefined And Selection.Organization <> FilterByCompany Then // Protection against data errors (duplicate certificates).
				CertificatesPropertiesTable.Delete(String);
			EndIf;
		Else
			String.Presentation = Selection.Presentation;
			String.IsRequest  = Selection.IsRequest;
			String.Isinthedirectory = True;
		EndIf;
	EndDo;
	
EndProcedure

// Intended for: UpdateCertificatesList procedure.
Procedure UpdateValue(PreviousValue2, NewValue, SkipNotDefinedValues = False)
	
	If NewValue = Undefined And SkipNotDefinedValues Then
		Return;
	EndIf;
	
	If PreviousValue2 <> NewValue Then
		PreviousValue2 = NewValue;
	EndIf;
	
EndProcedure

Procedure FillAttribute(SavedProperties, AttributesParameters, AttributeName)
	
	If AttributesParameters.Property(AttributeName) Then
		AttributeParameters =  AttributesParameters[AttributeName]; // Structure
		If AttributeParameters.FillValue <> Undefined Then

			SavedProperties[AttributeName] = AttributeParameters.FillValue;
			
		EndIf;
	EndIf;
	
EndProcedure

// Intended for: SetSigningEncryptionDecryptionForm procedure.
Procedure FillThumbprintsFilter(Form)
	
	Parameters = Form.Parameters;
	
	Filter = New Map;
	
	If TypeOf(Parameters.EncryptionCertificates) = Type("Array") Then
		DetailsList1 = New Map;
		Thumbprints = New Map;
		ThumbprintsPresentations = New Map;
		
		EncryptedObjects = New Array;
		
		For Each LongDesc In Parameters.EncryptionCertificates Do
			If DetailsList1[LongDesc] <> Undefined Then
				Continue;
			EndIf;
			DetailsList1.Insert(LongDesc, True);

			If TypeOf(LongDesc) = Type("String") Then
				Certificates = GetFromTempStorage(LongDesc);
				For Each Properties In Certificates Do
					Value = Thumbprints[Properties.Thumbprint];
					Value = ?(Value = Undefined, 1, Value + 1);
					Thumbprints.Insert(Properties.Thumbprint, Value);
					ThumbprintsPresentations.Insert(Properties.Thumbprint, Properties.Presentation);
				EndDo;
			Else
				EncryptedObjects.Add(LongDesc);
			EndIf;

		EndDo;
		
		If EncryptedObjects.Count() > 0 Then
			Certificates = EncryptionCertificatesFromDetails(EncryptedObjects);
			For Each Properties In Certificates Do
				Value = Thumbprints[Properties.Thumbprint];
				Value = ?(Value = Undefined, 1, Value + 1);
				Thumbprints.Insert(Properties.Thumbprint, Value);
				ThumbprintsPresentations.Insert(Properties.Thumbprint, Properties.Presentation);
			EndDo;
		EndIf;
		
		DataItemsCount = Parameters.EncryptionCertificates.Count();
		For Each KeyAndValue In Thumbprints Do
			If KeyAndValue.Value = DataItemsCount Then
				Filter.Insert(KeyAndValue.Key, ThumbprintsPresentations[KeyAndValue.Key]);
			EndIf;
		EndDo;
		
	ElsIf Parameters.EncryptionCertificates <> Undefined Then
		
		Certificates = EncryptionCertificatesFromDetails(Parameters.EncryptionCertificates);
		For Each Properties In Certificates Do
			Filter.Insert(Properties.Thumbprint, Properties.Presentation);
		EndDo;
	EndIf;
	
	Form.ThumbprintsFilter = PutToTempStorage(Filter, Form.UUID);
	
EndProcedure

// Intended for: FillThumbprintsFilter procedure.
Function EncryptionCertificatesFromDetails(LongDesc)
	
	If TypeOf(LongDesc) = Type("String") Then
		Return GetFromTempStorage(LongDesc);
	EndIf;
	
	Certificates = New Array;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	EncryptionCertificates.Presentation,
		|	EncryptionCertificates.Thumbprint,
		|	EncryptionCertificates.Certificate
		|FROM
		|	InformationRegister.EncryptionCertificates AS EncryptionCertificates
		|WHERE
		|	EncryptionCertificates.EncryptedObject IN (&EncryptedObjects)";
		
	If TypeOf(LongDesc) <> Type("Array") Then
		EncryptedObjects = CommonClientServer.ValueInArray(LongDesc);
	Else
		EncryptedObjects = LongDesc;
	EndIf;
	
	Query.SetParameter("EncryptedObjects", EncryptedObjects);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		CertificateProperties = New Structure("Thumbprint, Presentation, Certificate");
		FillPropertyValues(CertificateProperties, SelectionDetailRecords);
		CertificateProperties.Certificate = CertificateProperties.Certificate.Get();
		Certificates.Add(CertificateProperties);
	EndDo;
	
	Return Certificates;
	
EndFunction

Function RowBinaryData(RowData)
	
	TempFile = GetTempFileName();
	
	TextWriter = New TextWriter(TempFile, TextEncoding.UTF8);
	TextWriter.Write(RowData);
	TextWriter.Close();
	
	CertificateBinaryData = New BinaryData(TempFile);
	
	DeleteFiles(TempFile);
	
	Return CertificateBinaryData;
	
EndFunction

// For the SetSigningEncryptionDecryptionForm and CertificateOnChangeAtServer procedures.

Procedure FillExistingUserCertificates(ChoiceList, CertificatesThumbprintsAtClient,
			CertificatesFilter, ThumbprintsFilter, Details, ExecuteAtServer)
	
	ChoiceList.Clear();
	CurrentSessionDate = ?(Details And ValueIsFilled(ThumbprintsFilter), Undefined, CurrentSessionDate());
	
	If DigitalSignature.GenerateDigitalSignaturesAtServer()
	   And ExecuteAtServer <> False Then
		
		CryptoManager = CryptoManager("GetCertificates");
		
		If CryptoManager <> Undefined Then
			StoreType = CryptoCertificateStoreType.PersonalCertificates;
			
			Try
				CertificatesArray = CryptoManager.GetCertificateStore(StoreType).GetAll();
				DigitalSignatureInternalClientServer.AddCertificatesThumbprints(CertificatesThumbprintsAtClient,
					CertificatesArray, UTCOffset(), CurrentSessionDate);
			Except // ACC:280
				// Do not handle the exception as the error is displayed on the certificate pick form.
			EndTry;
			
		EndIf;
		
	EndIf;
	
	If UseDigitalSignatureSaaS() Then
		ModuleCertificateStore = Common.CommonModule("CertificatesStorage");
		CertificatesArray = ModuleCertificateStore.Get("PersonalCertificates");
		
		DigitalSignatureInternalClientServer.AddCertificatesThumbprints(
			CertificatesThumbprintsAtClient, CertificatesArray, UTCOffset(), CurrentSessionDate);
	EndIf;
	
	If UseCloudSignatureService() Then
		
			
	EndIf;	
	
	FilterByCompany = False;
	
	If TypeOf(CertificatesFilter) = Type("ValueList") Then
		If CertificatesFilter.Count() > 0 Then
			CurrentList = New ValueList;
			For Each ListItem In CertificatesFilter Do
				Properties = Common.ObjectAttributesValues(
					ListItem.Value, "Ref, Description, Thumbprint, User");
				
				If CertificatesThumbprintsAtClient.Find(Properties.Thumbprint) <> Undefined Then
					CurrentList.Add(Properties.Ref, Properties.Description,
						Properties.User = Users.AuthorizedUser());
				EndIf;
			EndDo;
			For Each ListItem In CurrentList Do
				If ListItem.Check Then
					ChoiceList.Add(ListItem.Value, ListItem.Presentation);
				EndIf;
			EndDo;
			For Each ListItem In CurrentList Do
				If Not ListItem.Check Then
					ChoiceList.Add(ListItem.Value, ListItem.Presentation);
				EndIf;
			EndDo;
			Return;
		EndIf;
	ElsIf Metadata.DefinedTypes.Organization.Type.ContainsType(TypeOf(CertificatesFilter)) Then
		FilterByCompany = True;
	EndIf;
	
	If ThumbprintsFilter <> Undefined Then
		Filter = GetFromTempStorage(ThumbprintsFilter);
		For Each Thumbprint In CertificatesThumbprintsAtClient Do
			If Filter[Thumbprint] = Undefined Then
				Continue;
			EndIf;
			ChoiceList.Add(Thumbprint, Filter[Thumbprint]);
		EndDo;
		Query = New Query;
		Query.Parameters.Insert("Thumbprints", ChoiceList.UnloadValues());
		Query.Text =
		"SELECT
		|	Certificates.Ref AS Ref,
		|	Certificates.Description AS Description,
		|	Certificates.Thumbprint
		|FROM
		|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
		|WHERE
		|	Certificates.Thumbprint IN(&Thumbprints)";
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ListItem = ChoiceList.FindByValue(Selection.Thumbprint);
			If ListItem <> Undefined Then
				ListItem.Value = Selection.Ref;
				ListItem.Presentation = Selection.Description;
			EndIf;
		EndDo;
		ChoiceList.SortByPresentation();
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	Certificates.Ref AS Ref,
	|	Certificates.User AS User,
	|	Certificates.Description AS Description
	|INTO AllCertificates
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|WHERE
	|	Certificates.Revoked = FALSE
	|	AND Certificates.Thumbprint IN(&Thumbprints)
	|	AND TRUE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllCertificates.Ref AS Ref,
	|	AllCertificates.Description AS Description
	|FROM
	|	AllCertificates AS AllCertificates
	|WHERE
	|	AllCertificates.Ref IN
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
	
	If FilterByCompany Then
		QueryText = StrReplace(QueryText, "TRUE", "Certificates.Organization = &Organization");
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("User", Users.CurrentUser());
	Query.SetParameter("Thumbprints", CertificatesThumbprintsAtClient);
	Query.SetParameter("Organization", CertificatesFilter);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ChoiceList.Add(Selection.Ref, Selection.Description);
	EndDo;
	
EndProcedure

Function GetCertificateThumbprintsInStorage(CryptoManager, StoreType, Error)
	
	ThumbprintsArray = New Array;
	Try
		CertificatesArray = CryptoManager.GetCertificateStore(StoreType).GetAll();
	Except
		ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		If TypeOf(Error) = Type("Structure") Then
			Error = DigitalSignatureInternalClientServer.NewErrorsDescription(ComputerName());
			Error.ErrorDescription = ErrorDescription;
		Else
			Error = ErrorDescription;
		EndIf;
		Return ThumbprintsArray;
	EndTry;

	For Each Certificate In CertificatesArray Do
		ThumbprintsArray.Add(Base64String(Certificate.Thumbprint));
	EndDo;
	
	Return ThumbprintsArray;
	
EndFunction

Procedure FillCertificateAdditionalProperties(Form)
	
	If Not ValueIsFilled(Form.Certificate) Then
		Return;
	EndIf;
	
	AttributesValues = Common.ObjectAttributesValues(Form.Certificate,
		"EnterPasswordInDigitalSignatureApplication, Thumbprint, Application,
		|ValidBefore, CertificateData, Revoked");
	
	Try
		CertificateBinaryData = AttributesValues.CertificateData.Get();
		Certificate = New CryptoCertificate(CertificateBinaryData);
	Except
		ErrorInfo = ErrorInfo();
		Certificate = Form.Certificate;
		Form.Certificate = Undefined;
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить данные сертификата ""%1""
			           |по причине:
			           |%2';
						|en = 'Cannot receive the ""%1"" certificate data
						|due to:
						|%2';"),
			Certificate,
			ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndTry;
	
	IsBuiltInCryptoProvider = AttributesValues.Application = BuiltinCryptoprovider();
	
	If Form.NoConfirmation
	   And IsBuiltInCryptoProvider Then
		
		Properties = New Structure("CloudPasswordConfirmed",
			CloudPasswordConfirmed(CertificateBinaryData));
		
		FillPropertyValues(Form, Properties);
	EndIf;
	
	Form.AddressOfCertificate = PutToTempStorage(CertificateBinaryData, Form.UUID);
	
	Form.ThumbprintOfCertificate      = AttributesValues.Thumbprint;
	Form.CertificateApp      = AttributesValues.Application;
	Form.ExecuteInSaaS  = IsBuiltInCryptoProvider;
	Form.CertificateExpiresOn = AttributesValues.ValidBefore;
	If CommonClientServer.HasAttributeOrObjectProperty(Form, "CertificateRevoked") Then
		Form.CertificateRevoked        = AttributesValues.Revoked;
	EndIf;
	Form.CertificateEnterPasswordInElectronicSignatureProgram = AttributesValues.EnterPasswordInDigitalSignatureApplication;
	
	If CommonClientServer.HasAttributeOrObjectProperty(Form, "CertificationAuthorityAuditResult") Then
		CheckParameters = Undefined;
		If CommonClientServer.HasAttributeOrObjectProperty(Form, "VerifyCertificate") Then
			CheckParameters = New Structure;
			CheckParameters.Insert("ThisVerificationSignature", False);
			CheckParameters.Insert("VerifyCertificate", Form.VerifyCertificate);
		EndIf;
		Form.CertificationAuthorityAuditResult = ResultofCertificateAuthorityVerification(Certificate,,CheckParameters);
	EndIf;
	
	IsParameterNotifyOnExpirationofValidity = Form.Parameters.Property("NotifyOfCertificateAboutToExpire");
	If IsParameterNotifyOnExpirationofValidity And Form.Parameters.NotifyOfCertificateAboutToExpire 
		Or Not IsParameterNotifyOnExpirationofValidity Then
			
		If CommonClientServer.HasAttributeOrObjectProperty(Form, "CertificationAuthorityAuditResult")
			And Form.CertificationAuthorityAuditResult <> Undefined
			And Form.CertificationAuthorityAuditResult.Valid_SSLyf
			And (ValueIsFilled(Form.CertificationAuthorityAuditResult.Warning.ErrorText) 
			Or ValueIsFilled(Form.CertificationAuthorityAuditResult.Warning.AdditionalInfo)) Then
			Form.NotifyOfCertificateAboutToExpire = Not InformationRegisters.CertificateUsersNotifications.UserAlerted(Form.Certificate)
				And Not CertificateReissued(Form.Certificate);
		Else
			Form.NotifyOfCertificateAboutToExpire = 
				Form.CertificateExpiresOn <= CurrentUniversalDate() + NumberofDaysforEndofTermAlert()*24*60*60
				And Not InformationRegisters.CertificateUsersNotifications.UserAlerted(Form.Certificate)
				And Not CertificateReissued(Form.Certificate);
		EndIf;
		
	EndIf;
	
	Form.CertificateAtServerErrorDescription = New Structure;
	
	If Not DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Form.CertificateApp) Then
		CertificateApplicationResult = AppForCertificate(Form.AddressOfCertificate);
		If CertificateApplicationResult.Application = Undefined Then
			ErrorText = DigitalSignatureInternalClientServer.ErrorTextFailedToDefineApp(
				CertificateApplicationResult.Error);
			Form.CertificateAtServerErrorDescription.Insert("ErrorDescription", ErrorText);
			Return;
		ElsIf CommonClientServer.HasAttributeOrObjectProperty(Form, "AppAutoAtServer") Then
			Form.AppAutoAtServer = CertificateApplicationResult.Application;
		EndIf;
		Application = CertificateApplicationResult.Application;
	Else
		Application = Form.CertificateApp;
	EndIf;
	
	GetCertificateByThumbprint(Form.ThumbprintOfCertificate,
		True, False, Application, Form.CertificateAtServerErrorDescription);
	
EndProcedure

Function NumberofDaysforEndofTermAlert()
	Return 30;
EndFunction

// For the CryptoManager function.
Function NewCryptoManager(Application, Errors, AdditionalParameters)
	
	AppsAuto		= Undefined;
	Operation			= AdditionalParameters.Operation;
	AutoDetect		= AdditionalParameters.AutoDetect;
	SignAlgorithm		= AdditionalParameters.SignAlgorithm;
	EncryptAlgorithm	= AdditionalParameters.EncryptAlgorithm;
	
	If TypeOf(Application) = Type("String") Or TypeOf(Application) = Type("BinaryData") Then
		
		ErrorDescription = "";
		IsPrivateKeyRequied = Operation = "Signing"
			Or Operation = "Details";
		PopulateParametersForCreatingCryptoManager(Application, SignAlgorithm, ErrorDescription, IsPrivateKeyRequied);
		
		If ValueIsFilled(ErrorDescription) Then
			ErrorProperties = DigitalSignatureInternalClientServer.NewErrorProperties();
			ErrorProperties.LongDesc = ErrorDescription;
			Errors.Add(ErrorProperties);
			
			If Application = Undefined And IsPrivateKeyRequied Then
				Return Undefined;
			EndIf;
		EndIf;
		
	EndIf;
	
	If AutoDetect And TypeOf(Application) <> Type("Structure") And TypeOf(Application) <> Type("FixedStructure") Then
		
		CryptoProvidersResult = DigitalSignatureInternalCached.InstalledCryptoProviders();
		AppsAuto = DigitalSignatureInternalClientServer.CryptoProvidersSearchResult(
			CryptoProvidersResult, ComputerName());
		
		If TypeOf(AppsAuto) = Type("String") Then
			ErrorProperties = DigitalSignatureInternalClientServer.NewErrorProperties();
			ErrorProperties.LongDesc = AppsAuto;
			Errors.Add(ErrorProperties);
			AppsAuto = Undefined;
		EndIf;
	
	EndIf;
	
	ApplicationsDetailsCollection = DigitalSignatureInternalClientServer.CryptoManagerApplicationsDetails(
		Application, Errors, DigitalSignature.CommonSettings().ApplicationsDetailsCollection, AppsAuto);
	
	If ApplicationsDetailsCollection = Undefined Then
		Return Undefined;
	EndIf;
	
	IsLinux = RequiresThePathToTheProgram();
	
	Manager = Undefined;
	For Each ApplicationDetails In ApplicationsDetailsCollection Do
		
		If ValueIsFilled(SignAlgorithm) Then
			SignAlgorithmSupported =
				DigitalSignatureInternalClientServer.CryptoManagerSignAlgorithmSupported(ApplicationDetails,
					Operation, SignAlgorithm, Errors, True, Application <> Undefined);
			
			If Not SignAlgorithmSupported Then
				Manager = Undefined;
				Continue;
			EndIf;
		EndIf;
		
		If ApplicationDetails.Property("AutoDetect") Then
			
			ApplicationProperties1 = New Structure;
			ApplicationProperties1.Insert("ApplicationName",   ApplicationDetails.ApplicationName);
			ApplicationProperties1.Insert("ApplicationPath", ApplicationDetails.AppPathAtServerAuto);
			ApplicationProperties1.Insert("ApplicationType",   ApplicationDetails.ApplicationType);
			
		Else

			IDOfTheProgramPath = ?(ValueIsFilled(ApplicationDetails.Ref),
				ApplicationDetails.Ref, ApplicationDetails.Id);
		
			ApplicationProperties1 = DigitalSignatureInternalClientServer.CryptoManagerApplicationProperties(
				ApplicationDetails, IsLinux, Errors, True, ApplicationPath(IDOfTheProgramPath));

		EndIf;
		
		If ApplicationProperties1 = Undefined Then
			Continue;
		EndIf;
		
		Try
			ModuleInfo = CryptoTools.GetCryptoModuleInformation(
				ApplicationProperties1.ApplicationName,
				ApplicationProperties1.ApplicationPath,
				ApplicationProperties1.ApplicationType);
		Except
			DigitalSignatureInternalClientServer.CryptoManagerAddError(Errors,
				ApplicationDetails.Ref, ErrorProcessing.BriefErrorDescription(ErrorInfo()),
				True, True, True);
			Continue;
		EndTry;
		
		If ModuleInfo = Undefined Then
			DigitalSignatureInternalClientServer.CryptoManagerApplicationNotFound(
				ApplicationDetails, Errors, True);
			
			Manager = Undefined;
			Continue;
		EndIf;
		
		If Not IsLinux Then
			ApplicationNameReceived = ModuleInfo.Name;
			
			ApplicationNameMatches = DigitalSignatureInternalClientServer.CryptoManagerApplicationNameMaps(
				ApplicationDetails, ApplicationNameReceived, Errors, True);
			
			If Not ApplicationNameMatches Then
				Manager = Undefined;
				Continue;
			EndIf;
		EndIf;
		
		Try
			Manager = New CryptoManager(
				ApplicationProperties1.ApplicationName,
				ApplicationProperties1.ApplicationPath,
				ApplicationProperties1.ApplicationType);
		Except
			DigitalSignatureInternalClientServer.CryptoManagerAddError(Errors,
				ApplicationDetails.Ref, ErrorProcessing.BriefErrorDescription(ErrorInfo()),
				True, True, True);
			Continue;
		EndTry;
		
		AlgorithmsSet = DigitalSignatureInternalClientServer.CryptoManagerAlgorithmsSet(
			ApplicationDetails, Manager, Errors, EncryptAlgorithm);
		
		If Not AlgorithmsSet Then
			Continue;
		EndIf;
		
		Break; // The required crypto manager is received.
	EndDo;
	
	Return Manager;
	
EndFunction

// For the NewCryptoManager function.
Procedure PopulateParametersForCreatingCryptoManager(Application, SignAlgorithm, ErrorDescription, IsPrivateKeyRequied)
	
	Data = Application;
	
	Try
		
		DataType = DigitalSignatureInternalClientServer.DefineDataType(Data);
		
	Except
		
		Application = Undefined;
		ErrorDescription = StringFunctionsClientServer.InsertParametersIntoString(
			NStr("ru = 'Не удалось определить приложение электронной подписи и шифрования для переданных данных: %1';
				|en = 'Couldn''t determine digital signing and encryption app for the passed data: %1';"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	If DataType = "Certificate" Then
		
		CertificateApplicationResult = AppForCertificate(Data, IsPrivateKeyRequied);
		If ValueIsFilled(CertificateApplicationResult.Error) Then
			
			ErrorDescription = DigitalSignatureInternalClientServer.ErrorTextFailedToDefineApp(
				CertificateApplicationResult.Error);
			SignAlgorithm = DigitalSignatureInternalClientServer.CertificateSignAlgorithm(Data);
			Application = Undefined;
			
		Else
			Application = CertificateApplicationResult.Application;
		EndIf;
		
		Return;
		
	ElsIf DataType = "Signature" Then
		
		Application = Undefined;
		SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(Data);
		Return;
		
	ElsIf DataType = "EncryptedData" Then
		
		Application = Undefined;
		ErrorDescription = NStr("ru = 'Для определения приложения для расшифровки в процедуру должны быть переданы данные сертификата.';
								|en = 'To determine a decryption app, pass the certificate data to the procedure.';");
		Return;
		
	EndIf;
	
	Application = Undefined;
	ErrorDescription = NStr("ru = 'Не удалось определить приложение электронной подписи и шифрования для переданных данных.';
							|en = 'Couldn''t determine digital signing and encryption app for the passed data.';");
	
EndProcedure

Function AppForCertificate(Val Certificate, IsPrivateKeyRequied = Undefined,  ComponentObject = Undefined) Export

	Result = New Structure("Application, Error");

	Certificate = CertificateBase64String(Certificate);

	If ComponentObject = Undefined Then
		Try
			ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
		Except
			Result.Error = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось подключить компоненту %1 на сервере %2.';
					|en = 'Cannot attach the %1 add-in on the %2 server.';"), "ExtraCryptoAPI", ComputerName());
			Return Result;
		EndTry;
	EndIf;
	
	If IsPrivateKeyRequied <> False Then
		
		Try
			CryptoProviderProperties = ComponentObject.GetCryptoProviderProperties(Certificate);
			CurCryptoProvider = DigitalSignatureInternalServerCall.ReadAddInResponce(
				CryptoProviderProperties);
		Except
			Result.Error = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			Return Result;
		EndTry;
		
		ApplicationsByNamesWithType = DigitalSignature.CommonSettings().ApplicationsByNamesWithType;
		ExtendedApplicationDetails = DigitalSignatureInternalClientServer.ExtendedApplicationDetails(
			CurCryptoProvider, ApplicationsByNamesWithType);
		
		If ExtendedApplicationDetails <> Undefined Then
			Result.Application = ExtendedApplicationDetails;
			Return Result;
		ElsIf IsPrivateKeyRequied = True And CurCryptoProvider.Get("type") <> 0 Then
			Result.Error = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Сертификат связан с приложением %1 с типом %2 на сервере %3, настройте его для использования и выберите в сертификате.';
					|en = 'The certificate is connected to the app %1 (of ""%2"" type) on the server %3. Configure the app and select it in the certificate.';"),
				CurCryptoProvider.Get("name"),
				CurCryptoProvider.Get("type"), ComputerName());
			Return Result;
		EndIf;
		
	EndIf;
	
	If IsPrivateKeyRequied = True Then
		Result.Error = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось определить приложение по закрытому ключу сертификата на сервере %1.';
				|en = 'Couldn''t determine app by the private key on the server %1.';"), ComputerName());
		Return Result;
	EndIf;
		
	CertificatePropertiesExtended = CertificatePropertiesExtended(Certificate, ComponentObject);
	ResultCryptoProviders = DigitalSignatureInternalCached.InstalledCryptoProviders();
	
	If ResultCryptoProviders.CheckCompleted Then
		
		Error = "";
		
		Result.Application = DigitalSignatureInternalClientServer.DefineApp(
			CertificatePropertiesExtended.CertificateProperties, ResultCryptoProviders.Cryptoproviders,
			DigitalSignature.CommonSettings().ApplicationsByPublicKeyAlgorithmsIDs, Error);
	
		If Result.Application = Undefined Then
			Result.Error = Error;
		EndIf;
	
		Return Result;
	Else
		Result.Error = ResultCryptoProviders.Error;
		Return Result;
	EndIf;
	
EndFunction

Function UseDigitalSignatureSaaS() Export
	
	If Not Common.SubsystemExists("CloudTechnology.DigitalSignatureSaaS") Then
		Return False;
	EndIf;
	
	ModuleDigitalSignatureSaaS =
		Common.CommonModule("DigitalSignatureSaaS");
	
	Return ModuleDigitalSignatureSaaS.UsageAllowed() And Common.DataSeparationEnabled();
	
EndFunction

Function ApplicationPath(ProgramLink)
	
	Result = New Structure("ApplicationPath, Exists, ErrorText", "", False, "");
	
	If Not RequiresThePathToTheProgram() Then
		Return Result;
	EndIf;
	
	ApplicationsPaths = DigitalSignatureInternalCached.ApplicationsPathsAtLinuxServers(ComputerName());
	DescriptionOfWay = ApplicationsPaths.Get(ProgramLink);
	
	If DescriptionOfWay <> Undefined Then
		Result = DescriptionOfWay;
	EndIf;
	
	Return Result;
	
EndFunction

// For the GetFilesAndSignaturesMap function.
Function FindSignatureFilesNames(DataFileName, SignatureFilesNames)
	
	SignatureNames = New Array;
	
	NameStructure = CommonClientServer.ParseFullFileName(DataFileName);
	BaseName = NameStructure.BaseName;
	
	For Each SignatureFileName In SignatureFilesNames Do
		If StrFind(SignatureFileName, BaseName) > 0 Then
			SignatureNames.Add(SignatureFileName);
		EndIf;
	EndDo;
	
	For Each SignatureFileName In SignatureNames Do
		SignatureFilesNames.Delete(SignatureFilesNames.Find(SignatureFileName));
	EndDo;
	
	Return SignatureNames;
	
EndFunction

// Intended for: WriteCertificateAfterCheck procedure.

Function CheckEncryptionAndDecryption(CryptoManager, CertificateBinaryData,
			CryptoCertificate, ApplicationDetails, ErrorAtServer, IsFullUser)
	
	ErrorPresentation = "";
	Try
		EncryptedData = CryptoManager.Encrypt(CertificateBinaryData, CryptoCertificate);
	Except
		ErrorInfo = ErrorInfo();
		ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	EndTry;
	
	If ValueIsFilled(ErrorPresentation) Then
		DigitalSignatureInternalClientServer.FillErrorAddingCertificate(
			ErrorAtServer,
			ApplicationDetails,
			"Encryption",
			ErrorPresentation,
			IsFullUser,
			False,
			ComputerName());
		
		Return False;
	EndIf;
	
	ErrorInfo = Undefined;
	ErrorPresentation = "";
	Try
		DecryptedData = CryptoManager.Decrypt(EncryptedData);
		DigitalSignatureInternalClientServer.BlankDecryptedData(DecryptedData, ErrorPresentation);
	Except
		ErrorInfo = ErrorInfo();
		ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	EndTry;
	
	If ValueIsFilled(ErrorPresentation) Then
		DigitalSignatureInternalClientServer.FillErrorAddingCertificate(
			ErrorAtServer,
			ApplicationDetails,
			"Details",
			ErrorPresentation,
			IsFullUser,
			ErrorInfo = Undefined,
			ComputerName());
		
		Return False;
	EndIf;
		
	Return True;
	
EndFunction

Function CheckSigning(CryptoManager, CertificateBinaryData,
			CryptoCertificate, ApplicationDetails, ErrorAtServer, IsFullUser)
	
	ErrorInfo = Undefined;
	ErrorPresentation = "";
	Try
		SignatureData = CryptoManager.Sign(CertificateBinaryData, CryptoCertificate);
		DigitalSignatureInternalClientServer.BlankSignatureData(SignatureData, ErrorPresentation);
	Except
		ErrorInfo = ErrorInfo();
		ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	EndTry;
	
	If ValueIsFilled(ErrorPresentation) Then
		DigitalSignatureInternalClientServer.FillErrorAddingCertificate(
			ErrorAtServer,
			ApplicationDetails,
			"Signing",
			ErrorPresentation,
			IsFullUser,
			ErrorInfo = Undefined,
			ComputerName());
		
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Returns:
//   ValueTable:
//     * SignAlgorithms     - Array
//     * HashAlgorithms - Array
//     * EncryptAlgorithms  - Array
//     * SignatureVerificationAlgorithms - Array
//     * NotInWindows - Boolean
//     * NotOnLinux   - Boolean
//     * NotInMacOS   - Boolean
//
Function ApplicationsSettingsToSupply() Export
	
	Settings = New ValueTable;
	Settings.Columns.Add("Presentation");
	Settings.Columns.Add("ApplicationName");
	Settings.Columns.Add("ApplicationType");
	Settings.Columns.Add("SignAlgorithm");
	Settings.Columns.Add("HashAlgorithm");
	Settings.Columns.Add("EncryptAlgorithm");
	Settings.Columns.Add("Id");
	
	Settings.Columns.Add("SignAlgorithms",     New TypeDescription("Array"));
	Settings.Columns.Add("HashAlgorithms", New TypeDescription("Array"));
	Settings.Columns.Add("EncryptAlgorithms",  New TypeDescription("Array"));
	Settings.Columns.Add("SignatureVerificationAlgorithms", New TypeDescription("Array"));
	Settings.Columns.Add("NotInWindows", New TypeDescription("Boolean"));
	Settings.Columns.Add("NotOnLinux",   New TypeDescription("Boolean"));
	Settings.Columns.Add("NotInMacOS",   New TypeDescription("Boolean"));
	Settings.Columns.Add("Irrelevant", New TypeDescription("Boolean"));
	
	Return Settings;
	
EndFunction

// Returns:
//   Structure:
//     * Key - String - Prefix of the app ID. For example "CryptoPro".
//     * Value - FixedMap of KeyAndValue:
//         * Key - PlatformType
//         * Value - FixedArray of String - the paths
//             with module names separated by colon.
//
Function SupplyThePathToTheProgramModules() Export
	
	Return New Structure;
	
EndFunction

// Runs when a configuration is updated to v.3.1.5.220 and during the initial data population.
// 
Procedure FillinSettingsToImproveSignatures() Export
	
	ValueManager = Constants.CryptoSignatureTypeDefault.CreateValueManager();
	ValueManager.Value = Enums.CryptographySignatureTypes.BasicCAdESBES;
	InfobaseUpdate.WriteData(ValueManager);

	FillinServerAddressesTimestamps();
	
EndProcedure

// Runs when a configuration is updated to v.3.1.6.180. 
// Called from PopulateSignatureEnhancementSettings procedure
// 
Procedure FillinServerAddressesTimestamps() Export

	If Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined Then
		TimestampServersAddresses = DataProcessors["DigitalSignatureAndEncryptionApplications"].TimestampServerAddressesForInitialPopulation();
		If Not IsBlankString(TimestampServersAddresses) Then
			ValueManager = Constants.TimestampServersAddresses.CreateValueManager();
			ValueManager.Value = TimestampServersAddresses;
			InfobaseUpdate.WriteData(ValueManager);
		EndIf;
	EndIf;

EndProcedure

Function CertificateReissued(Certificate)
	
	If DigitalSignature.CommonSettings().CertificateIssueRequestAvailable Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		IssuedCertificates = ProcessingApplicationForNewQualifiedCertificateIssue.IssuedCertificates(Certificate);
		If IssuedCertificates.Count() > 0 Then
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

Function NumberofCertificatesWithexpiringValidity()

	Query = New Query;
	Query.Text =
	"SELECT
	|	DigitalSignatureAndEncryptionKeysCertificates.Ref
	|INTO UserCertificates
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS DigitalSignatureAndEncryptionKeysCertificates
	|WHERE
	|	DigitalSignatureAndEncryptionKeysCertificates.User = &User
	|
	|UNION ALL
	|
	|SELECT
	|	ElectronicSignatureAndEncryptionKeyCertificatesUsers.Ref
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates.Users AS
	|		ElectronicSignatureAndEncryptionKeyCertificatesUsers
	|WHERE
	|	ElectronicSignatureAndEncryptionKeyCertificatesUsers.User = &User
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(DISTINCT DigitalSignatureAndEncryptionKeysCertificates.Ref) AS Count
	|FROM
	|	UserCertificates AS UserCertificates
	|		INNER JOIN Catalog.DigitalSignatureAndEncryptionKeysCertificates AS
	|			DigitalSignatureAndEncryptionKeysCertificates
	|		ON UserCertificates.Ref = DigitalSignatureAndEncryptionKeysCertificates.Ref
	|WHERE
	|	NOT DigitalSignatureAndEncryptionKeysCertificates.DeletionMark
	|	AND DigitalSignatureAndEncryptionKeysCertificates.ValidBefore >= &CurrentDate
	|	AND DigitalSignatureAndEncryptionKeysCertificates.ValidBefore <= &Date
	|	AND NOT DigitalSignatureAndEncryptionKeysCertificates.Revoked";

	CurrentDate = CurrentUniversalDate();
	Query.SetParameter("CurrentDate", CurrentDate);
	Query.SetParameter("Date", CurrentDate + 30*24*60*60);
	Query.SetParameter("User", Users.CurrentUser());
	
	Return Query.Execute().Unload()[0].Count;
	
EndFunction

Function NumberofApplicationsInProgress()
	
	ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
				
	Return ProcessingApplicationForNewQualifiedCertificateIssue.NumberofApplicationsInProgress();
	
EndFunction

Function SignaturesCount(Parameter) Export
	
	QueryOptions = New Structure;
	QueryOptions.Insert(Parameter, True);
	QueryOptions.Insert("OnlyQuantity", True);
	
	Query = RequestForExtensionSignatureCredibility(QueryOptions);
		
	If Query = Undefined Then
		Return 0;
	EndIf;
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	Return QueryResult.Unload()[0].Count;
	
EndFunction

Function RequestForExtensionSignatureCredibility(Parameters) Export
	
	QueryOptions = New Structure;
	QueryOptions.Insert("RequireImprovementSignatures", False);
	QueryOptions.Insert("RequiredAddArchiveTags", False);
	QueryOptions.Insert("rawsignatures", False);
	QueryOptions.Insert("ErrorsOnAutoRenewal", False);
	QueryOptions.Insert("OnlyQuantity", False);
	QueryOptions.Insert("RefineToType", Undefined);
	QueryOptions.Insert("ScheduledJob", False);
	
	FillPropertyValues(QueryOptions, Parameters);
	
	Query = New Query;
	QueryText = "";
	
	RefineSignaturesDates = Constants.RefineSignaturesDates.Get();
	
	If QueryOptions.RequireImprovementSignatures Then
		
		QueryText =
		"SELECT
		|	COUNT(*) AS Count
		|FROM
		|	InformationRegister.DigitalSignatures AS DigitalSignatures
		|WHERE
		|	DigitalSignatures.SignatureType IN(&SignatureType)
		|	AND DigitalSignatures.SignatureCorrect
		|	AND NOT DigitalSignatures.IsErrorOccurredDuringAutomaticRenewal
		|	AND NOT DigitalSignatures.SkipUponRenewal
		|	AND (DigitalSignatures.DateActionLastTimestamp = DATETIME(1, 1, 1)
		|			OR DigitalSignatures.DateActionLastTimestamp > &CurrentSessionDate)
		|	AND DigitalSignatures.SignatureDate >= &RefineSignaturesDates";

		Query.SetParameter("CurrentSessionDate", CurrentSessionDate());
		Query.SetParameter("RefineSignaturesDates", RefineSignaturesDates);
		
		RefineToType = QueryOptions.RefineToType;
		If RefineToType = Undefined Then
			RefineToType = Constants.CryptoSignatureTypeDefault.Get();
		EndIf;
		
		SignatureType = New Array;
		If RefineToType = Enums.CryptographySignatureTypes.WithTimeCAdEST Then
			SignatureType.Add(Enums.CryptographySignatureTypes.BasicCAdESBES);
		ElsIf RefineToType = Enums.CryptographySignatureTypes.ArchivalCAdESAv3 Then
			SignatureType.Add(Enums.CryptographySignatureTypes.BasicCAdESBES);
			SignatureType.Add(Enums.CryptographySignatureTypes.WithTimeCAdEST);
			SignatureType.Add(Enums.CryptographySignatureTypes.WithCompleteValidationDataReferencesCAdESC);
			SignatureType.Add(Enums.CryptographySignatureTypes.CAdESXType1);
			SignatureType.Add(Enums.CryptographySignatureTypes.CAdESXType2);
			SignatureType.Add(Enums.CryptographySignatureTypes.CAdESXLong);
			SignatureType.Add(Enums.CryptographySignatureTypes.CAdESXLongType1);
			SignatureType.Add(Enums.CryptographySignatureTypes.ExtendedLongCAdESXLongType2);
		Else
			QueryText = "";
		EndIf;
		Query.SetParameter("SignatureType", SignatureType);
		
	EndIf;
	
	If QueryOptions.RequiredAddArchiveTags Then
	
		QueryText = ?(QueryText = "", "", QueryText + "
		|
		|UNION ALL
		|
		|")
		+
		"SELECT
		|	COUNT(*) AS Count
		|FROM
		|	InformationRegister.DigitalSignatures AS DigitalSignatures
		|WHERE
		|	DigitalSignatures.SignatureType = VALUE(Enum.CryptographySignatureTypes.ArchivalCAdESAv3)
		|	AND DigitalSignatures.DateActionLastTimestamp <= &Date
		|	AND NOT DigitalSignatures.IsErrorOccurredDuringAutomaticRenewal
		|	AND NOT DigitalSignatures.SkipUponRenewal
		|	AND DigitalSignatures.SignatureCorrect
		|
		|UNION ALL
		|
		|SELECT
		|	COUNT(*)
		|FROM
		|	InformationRegister.DigitalSignatures AS DigitalSignatures
		|WHERE
		|	DigitalSignatures.SignatureType = VALUE(Enum.CryptographySignatureTypes.CAdESAv2)
		|	AND DigitalSignatures.DateActionLastTimestamp <= &Date
		|	AND NOT DigitalSignatures.IsErrorOccurredDuringAutomaticRenewal
		|	AND NOT DigitalSignatures.SkipUponRenewal
		|	AND DigitalSignatures.SignatureCorrect";
		
		Query.SetParameter("Date", AddMonth(CurrentSessionDate(), 1));
		
	EndIf; 
	
	If QueryOptions.rawsignatures Then
		
		QueryText = ?(QueryText = "", "", QueryText + "
		|
		|UNION ALL
		|
		|")
		+
		"SELECT
		|	COUNT(*) AS Count
		|FROM
		|	InformationRegister.DigitalSignatures AS DigitalSignatures
		|WHERE
		|	DigitalSignatures.SignatureType = VALUE(Enum.CryptographySignatureTypes.EmptyRef)
		|	AND DigitalSignatures.SignatureCorrect
		|	AND NOT DigitalSignatures.IsErrorOccurredDuringAutomaticRenewal
		|	AND NOT DigitalSignatures.SkipUponRenewal
		|	AND (DigitalSignatures.DateActionLastTimestamp = DATETIME(1, 1, 1)
		|			OR DigitalSignatures.DateActionLastTimestamp > &CurrentSessionDate)
		|	AND DigitalSignatures.SignatureDate >= &RefineSignaturesDates";
		
		Query.SetParameter("CurrentSessionDate", CurrentSessionDate());
		Query.SetParameter("RefineSignaturesDates", RefineSignaturesDates);
		
	EndIf;
	
	If QueryOptions.ErrorsOnAutoRenewal Then
		
		QueryText = ?(QueryText = "", "", QueryText + "
		|
		|UNION ALL
		|
		|")
		+
		"SELECT
		|	COUNT(*) AS Count
		|FROM
		|	InformationRegister.DigitalSignatures AS DigitalSignatures
		|WHERE
		|	DigitalSignatures.IsErrorOccurredDuringAutomaticRenewal";
		
	EndIf;
	
	If IsBlankString(QueryText) Then
		QueryText = 
		"SELECT
		|	COUNT(*) AS Count
		|FROM
		|	InformationRegister.DigitalSignatures AS DigitalSignatures
		|WHERE
		|	FALSE"
	EndIf;
	
	If Not QueryOptions.OnlyQuantity Then
		
		SearchString = "COUNT(*) AS Count";
		ReplacementString = "DigitalSignatures.SignedObject AS SignedObject,
		|	DigitalSignatures.SequenceNumber AS SequenceNumber,
		|	DigitalSignatures.SignatureDate AS SignatureDate,
		|	DigitalSignatures.CertificateOwner AS CertificateOwner,
		|	DigitalSignatures.SignatureType AS SignatureType,
		|	DigitalSignatures.IsErrorOccurredDuringAutomaticRenewal AS IsErrorOccurredDuringAutomaticRenewal,
		|	DigitalSignatures.DateActionLastTimestamp AS DateActionLastTimestamp";
		
		If QueryOptions.ScheduledJob Then
			ReplacementString = ReplacementString +",
			|	DigitalSignatures.Signature AS Signature";
		EndIf;
		
		QueryText = StrReplace(QueryText, SearchString, ReplacementString);
		
		SearchString = "COUNT(*)";
		QueryText = StrReplace(QueryText, SearchString, ReplacementString);
		
		If QueryOptions.ScheduledJob Then
			QueryText = QueryText + "
						|ORDER BY
						|	SignatureDate
						|";
		EndIf;

	EndIf;
	
	If QueryOptions.ScheduledJob Then
		QueryText = StrReplace(QueryText, "SELECT", "SELECT TOP 1000"); // @query-part-1 @query-part-2
	Else
		QueryText = StrReplace(QueryText, "AND NOT DigitalSignatures.IsErrorOccurredDuringAutomaticRenewal", "");
	EndIf;
	
	Query.Text = QueryText;
	
	Return Query;
	
EndFunction

// Looks up for individuals by description.
// 
// Parameters:
//   IssuedTo - Array of String
//             - String
//
// Returns:
//   Map of KeyAndValue:
//     * Key     - String - Individual's name
//     * Value - Array of DefinedType.Individual - References to the individuals catalog specified in the
//                                                             "Individual" type collection.
//
Function GetIndividualsByCertificateFieldIssuedTo(IssuedTo) Export

	IndividualsByFullName = New Map;

	If DigitalSignature.CommonSettings().IndividualUsed Then
		TypesIndividuals = Metadata.DefinedTypes.Individual.Type.Types();
		IndividualEmptyRef = New (TypesIndividuals[0]);
	Else
		Return IndividualsByFullName;
	EndIf;
	
	IndividualMetadataName = Common.TableNameByRef(IndividualEmptyRef);
	
	Query = New Query;
	QueryText = 
	"SELECT
	|	Persons.Ref AS Ref,
	|	Persons.Description AS Description
	|FROM
	|	Catalog.Users AS Persons
	|WHERE
	|	Persons.Description IN(&IssuedTo)
	|TOTALS BY
	|	Description";
	
	QueryText = StrReplace(QueryText, "Catalog.Users", IndividualMetadataName);
		
	Query.SetParameter("IssuedTo", IssuedTo);
	
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	
	SelectionDescription = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While SelectionDescription.Next() Do
		
		Selection = SelectionDescription.Select();
		Persons = New Array;
		
		While Selection.Next() Do
			Persons.Add(Selection.Ref);
		EndDo;
		
		IndividualsByFullName.Insert(SelectionDescription.Description, Persons); 

	EndDo;
	
	Return IndividualsByFullName;
	
EndFunction

// Intended for: ConfigureCommonSettingsForm procedure.
Procedure SetHeaderTipsImprovements(Form, SignatureType)
	
	Items = Form.Items;
	
	If ValueIsFilled(SignatureType) Then
		
		Items.GroupImproveSignatures.Enabled = 
			SignatureType <> PredefinedValue("Enum.CryptographySignatureTypes.NormalCMS")
			And SignatureType <> PredefinedValue("Enum.CryptographySignatureTypes.BasicCAdESBES");
		
		If Items.GroupImproveSignatures.Enabled Then
			
			Items.DecorationImprovementExtendedTooltip.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Подписи, добавленные ранее и полученные извне, будут усовершенствованы для длительного хранения до выбранного типа: %1.';
					|en = 'Previously added and external signatures will be enhanced for long-term storage up to the selected type: %1.';"),
				SignatureType);
			
		Else
			Items.DecorationImprovementExtendedTooltip.Title = 
				NStr("ru = 'Подписи, добавленные ранее и полученные извне, будут усовершенствованы для длительного хранения до выбранного типа.';
					|en = 'Previously added and external signatures will be enhanced for long-term storage up to the selected type.';");
		EndIf;
		
	Else
		Items.DecorationImprovementExtendedTooltip.Title = 
			NStr("ru = 'Не выбран тип подписи для документов.';
				|en = 'Signature type for documents is not selected.';");
		Items.GroupImproveSignatures.Enabled = False;
	EndIf;

EndProcedure

// Intended for: ConfigureCommonSettingsForm procedure.
Procedure SetHeaderElectronicSignatureOnServer(Form)
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	FileInfobase = Common.FileInfobase();
	
	ConstantsSet = Form.ConstantsSet;
	Items = Form.Items;
	
	If ConstantsSet.UseDigitalSignature Then
		CheckBoxTitle = NStr("ru = 'Проверять подписи и сертификаты на сервере';
								|en = 'Verify signatures and certificates on server';");
		CheckBoxTooltip =
			NStr("ru = 'Позволяет не устанавливать приложение электронной подписи на компьютер пользователя для проверки электронных подписей и сертификатов.';
				|en = 'Allows verifying digital signatures and certificates without installing a digital signing app on the user''s computer.';");
	Else
		CheckBoxTitle = NStr("ru = 'Проверять сертификаты на сервере';
								|en = 'Verify certificates on server';");
		CheckBoxTooltip =
			NStr("ru = 'Позволяет не устанавливать приложение электронной подписи на компьютер пользователя для проверки сертификатов.';
				|en = 'Allows verifying certificates without installing a digital signing app on the user''s computer.';");
	EndIf;
	
	Items.VerifyDigitalSignaturesOnTheServer.Title = CheckBoxTitle;
	
	If FileInfobase Then
		HintOnServer = NStr("ru = 'Важно: на компьютер, где работает веб-сервер, подключенный к файловой информационной базе, должно быть установлено хотя бы одно <a href=%1>приложение электронной подписи</a> из списка.';
									|en = 'Important: At least one href=%1>digital signing app</a> from the list must be installed on the computer running the web server connected to the file infobase.';");
	Else
		HintOnServer = NStr("ru = 'Важно: на каждый компьютер, где работает сервер 1С:Предприятия, должно быть установлено хотя бы одно <a href=%1>приложение электронной подписи</a> из списка.';
									|en = 'Important: At least one href=%1>digital signing app</a> from the list must be installed on each computer running 1C:Enterprise server.';");
	EndIf;
	
	CheckBoxTooltip = CheckBoxTooltip + Chars.LF + Chars.LF + HintOnServer;
	
	Items.VerifyDigitalSignaturesOnTheServerExtendedTooltip.Title = 
		StringFunctions.FormattedString(CheckBoxTooltip, "Application");
	
	If Not ConstantsSet.UseDigitalSignature Then
		CheckBoxTitle = NStr("ru = 'Шифровать и расшифровывать на сервере';
								|en = 'Encrypt and decrypt on the server';");
		CheckBoxTooltip =
			NStr("ru = 'Позволяет не устанавливать приложение электронной подписи и сертификат на компьютер пользователя для шифрования и расшифровки.';
				|en = 'Allows encryption and decryption without installing a digital signing app and a certificate on the user''s computer.';");
		
	ElsIf Not ConstantsSet.UseEncryption Then
		CheckBoxTitle = NStr("ru = 'Подписывать на сервере';
								|en = 'Sign on the server';");
		CheckBoxTooltip =
		NStr("ru = 'Позволяет не устанавливать приложение электронной подписи и сертификат на компьютер пользователя для подписания.';
			|en = 'Allows signing without installing a digital signing app and a certificate on the user''s computer.';");
	Else
		CheckBoxTitle = NStr("ru = 'Подписывать и шифровать на сервере';
								|en = 'Sign and encrypt on server';");
		CheckBoxTooltip =
			NStr("ru = 'Позволяет не устанавливать приложение электронной подписи и сертификат на компьютер пользователя для подписания, шифрования и расшифровки.';
				|en = 'Allows encryption decryption, and signing without installing a digital signing app and a certificate on the user''s computer.';");
	EndIf;
		
	Items.GenerateDigitalSignaturesAtServer.Title = CheckBoxTitle;
	
	If FileInfobase Then
		HintOnServer = NStr("ru = 'Важно: на компьютер, где работает веб-сервер, подключенный к файловой информационной базе, должна быть установлена <a href=%1>программа электронной подписи</a> и <a href=%2>сертификат</a> с закрытым ключом.';
									|en = 'Important: A <a href=%1>digital signing app</a> and <a href=%2>a certificate</a> with a private key must be installed on the computer running the web server connected to the file infobase.';");
	Else
		HintOnServer = NStr("ru = 'Важно: на каждый компьютер, где работает сервер 1С:Предприятия, должна быть установлена <a href=%1>программа электронной подписи</a> и <a href=%2>сертификат</a> с закрытым ключом.';
									|en = 'Important: A <a href=%1>digital signing app</a> and <a href=%2>a certificate</a> with a private key must be installed on each computer running 1C:Enterprise server.';"); 
	EndIf;
	
	CheckBoxTooltip = CheckBoxTooltip + Chars.LF + Chars.LF + HintOnServer;
	
	Items.GenerateDigitalSignaturesAtServerExtendedTooltip.Title = 
		StringFunctions.FormattedString(CheckBoxTooltip, "Programs", "Certificates");
		
EndProcedure

#Region XMLEnvelopeProperties

Function ProcessTheSignedInfoNode(TheSignedInfoNode, XMLEnvelopeProperties)
	
	If Not CheckTheUniquenessOfTheNode(TheSignedInfoNode, XMLEnvelopeProperties) Then
		Return False;
	EndIf;
	
	NodesArrayReference = New Array;
	
	For Each ChildNode In TheSignedInfoNode.ChildNodes Do
		If ChildNode.LocalName = "CanonicalizationMethod" Then
			If Not GetAttribute(ChildNode, "Algorithm", XMLEnvelopeProperties,
						"TheCanonizationAlgorithm", XMLEnvelopeProperties.CheckSignature) Then
				Return False;
			EndIf;
		ElsIf ChildNode.LocalName = "SignatureMethod" Then
			If Not GetAttribute(ChildNode, "Algorithm", XMLEnvelopeProperties,
						"SignAlgorithm", XMLEnvelopeProperties.CheckSignature) Then
				Return False;
			EndIf;
		ElsIf ChildNode.LocalName = "Reference" Then
			NodesArrayReference.Add(ChildNode);
		EndIf;
	EndDo;
	
	Return ProcessReferenceNodes(NodesArrayReference, XMLEnvelopeProperties);
		
EndFunction

Function ProcessReferenceNodes(NodesArrayReference, XMLEnvelopeProperties)
	
	For Each TheReferenceNode In NodesArrayReference Do
		HashedArea = DescriptionOfTheHashedArea();
		
		AdditionalParameters = AttributeAdditionalParameters(True, HashedArea, True);
		If Not GetAttribute(TheReferenceNode, "URI", XMLEnvelopeProperties,
					"NodeID", False, AdditionalParameters) Then
			Return False;
		EndIf;
		
		For Each ChildNode In TheReferenceNode.ChildNodes Do
			If ChildNode.LocalName = "Transforms" Then
				If Not ProcessTheTransformsNode(ChildNode, XMLEnvelopeProperties, HashedArea) Then
					Return False;
				EndIf;
			ElsIf ChildNode.LocalName = "DigestMethod" Then
				AdditionalParameters = AttributeAdditionalParameters(True, HashedArea);
				If Not GetAttribute(ChildNode, "Algorithm", XMLEnvelopeProperties, "HashAlgorithm",
							XMLEnvelopeProperties.CheckSignature, AdditionalParameters) Then
					Return False;
				EndIf;
			ElsIf ChildNode.LocalName = "DigestValue" Then
				AdditionalParameters = AttributeAdditionalParameters(False, HashedArea);
				If Not GetValue(ChildNode, XMLEnvelopeProperties,
						"HashValue", HashedArea, True) Then
					Return False;
				EndIf;
			EndIf;
		EndDo;
		XMLEnvelopeProperties.AreasToHash.Add(HashedArea);
	EndDo;
	
	Return True;
	
EndFunction

Function ProcessTheTransformsNode(TheTransformsNode, XMLEnvelopeProperties, HashedArea)
	
	AdditionalParameters = AttributeAdditionalParameters(True);
	If Not CheckTheUniquenessOfTheNode(TheTransformsNode, XMLEnvelopeProperties, AdditionalParameters) Then
		Return False;
	EndIf;
	
	For Each ChildNode In TheTransformsNode.ChildNodes Do
		If ChildNode.LocalName = "Transform" Then
			AdditionalParameters = AttributeAdditionalParameters(True, HashedArea);
			If Not GetAttribute(ChildNode, "Algorithm", XMLEnvelopeProperties, "TransformationAlgorithms",
						XMLEnvelopeProperties.CheckSignature, AdditionalParameters) Then
				Return False;
			EndIf;
		EndIf;
	EndDo;
	
	Return True;

EndFunction

Function ProcessTheKeyInfoNode(KeyInfoNode, XMLEnvelopeProperties)
	
	If Not CheckTheUniquenessOfTheNode(KeyInfoNode, XMLEnvelopeProperties) Then
		Return False;
	EndIf;
	
	For Each ChildNode In KeyInfoNode.ChildNodes Do
		If ChildNode.LocalName = "X509Data" Then
			If Not ProcessNodeX509Data(ChildNode, XMLEnvelopeProperties) Then
				Break;
			EndIf;
		ElsIf ChildNode.LocalName = "KeyInfoReference"
		      Or ChildNode.LocalName = "SecurityTokenReference" Then
			If Not ProcessANodeWithACertificateReference(ChildNode, XMLEnvelopeProperties) Then
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Function ProcessNodeX509Data(NodeX509Data, XMLEnvelopeProperties)
	
	If Not CheckTheUniquenessOfTheNode(NodeX509Data, XMLEnvelopeProperties) Then
		Return False;
	EndIf;
	
	For Each ChildNode In NodeX509Data.ChildNodes Do
		If ChildNode.LocalName <> "X509Certificate" Then
			Continue;
		EndIf;
		If Not GetValue(ChildNode, XMLEnvelopeProperties,
					"CertificateValue", XMLEnvelopeProperties.Certificate) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Function ProcessANodeWithACertificateReference(NodeWithALinkToTheCertificate, XMLEnvelopeProperties)
	
	If Not CheckTheUniquenessOfTheNode(NodeWithALinkToTheCertificate, XMLEnvelopeProperties) Then
		Return False;
	EndIf;
	
	AdditionalParameters = AttributeAdditionalParameters(False);
	
	For Each ChildNode In NodeWithALinkToTheCertificate.ChildNodes Do
		If ChildNode.LocalName <> "Reference" Then
			Continue;
		EndIf;
		AdditionalParameters.Properties = XMLEnvelopeProperties.Certificate;
		If Not GetAttribute(ChildNode, "URI", XMLEnvelopeProperties,
				"NodeID", False, AdditionalParameters) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

// Parameters:
//  DOMDocument      - DOMDocument
//  LocalName     - String
//  Namespace - String
//  ErrorText      - String
//  ExcludedNodes  - Undefined
//                   - Array of DOMElement
//  ErrorIfFound - Boolean
//
// Returns:
//  DOMElement
//
Function FindANodeByName(DOMDocument, LocalName, Namespace,
			ErrorText, ExcludedNodes = Undefined,
			NamespacesUpToAndIncludingTheNode = Undefined, ErrorIfFound = False)
	
	NodeFound = False;
	NamespacesUpToANode =
		?(NamespacesUpToAndIncludingTheNode <> Undefined, New Array, Undefined);
	
	For Each Node In DOMDocument.ChildNodes Do
		If ExcludedNodes <> Undefined
		   And ExcludedNodes.Find(Node) <> Undefined Then
			Continue;
		EndIf;
		If Node.LocalName = LocalName
		   And Node.NamespaceURI = Namespace Then
			Result = Node;
			NodeFound = True;
			Break;
		EndIf;
		NamespacesOfNestedNodes =
			?(NamespacesUpToANode <> Undefined, New Array, Undefined);
		Result = FindANodeByName(Node, LocalName, Namespace,
			Null, ExcludedNodes, NamespacesOfNestedNodes);
		If Result <> Undefined Then
			NodeFound = True;
			AddNamespaces(NamespacesUpToANode,
				Node, NamespacesOfNestedNodes);
			Break;
		EndIf;
	EndDo;
	
	If Not NodeFound Then
		Result = Undefined;
	EndIf;
	
	If ErrorText = Null Then
		NamespacesUpToAndIncludingTheNode = NamespacesUpToANode;
		Return Result;
	EndIf;
	
	If NodeFound And ErrorIfFound Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В документе XML найдено более одного узла ""%1"" с пространством имен ""%2"".';
				|en = 'More than one %1 node with %2 namespace is found in the XML document.';"),
			LocalName,
			Namespace);
	ElsIf Not NodeFound And Not ErrorIfFound Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В документе XML не найден узел ""%1"" с пространством имен ""%2"".';
				|en = '%1 node with %2 namespace is not found in the XML document.';"),
			LocalName,
			Namespace);
	EndIf;
	
	If Result <> Undefined
	   And NamespacesUpToAndIncludingTheNode <> Undefined Then
		
		AddNamespaces(NamespacesUpToAndIncludingTheNode,
			Result, NamespacesUpToANode);
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  DOMDocument       - DOMDocument
//  NodeID - String
//  ErrorText       - String
//  ExcludedNodes   - Array of DOMElement
//  NamespacesUpToANode - Undefined
//                         - Array of String
//  ErrorIfFound - Boolean
//
// Returns:
//  DOMElement
//
Function FindANodeByID(DOMDocument, NodeID, ErrorText,
			ExcludedNodes = Undefined, NamespacesUpToANode = Undefined, ErrorIfFound = False)
	
	NodeFound = False;
	NameOfTheIDAttribute = "Id";
	
	For Each Node In DOMDocument.ChildNodes Do
		If Node.Attributes = Undefined
		 Or ExcludedNodes <> Undefined
		   And ExcludedNodes.Find(Node) <> Undefined Then
			Continue;
		EndIf;
		For Each Attribute In Node.Attributes Do
			If Upper(Attribute.LocalName) = Upper(NameOfTheIDAttribute)
			   And Attribute.NodeValue = NodeID Then
				Result = Node;
				NodeFound = True;
				Break;
			EndIf;
		EndDo;
		If NodeFound Then
			Break;
		EndIf;
		NamespacesOfNestedNodes =
			?(NamespacesUpToANode <> Undefined, New Array, Undefined);
		Result = FindANodeByID(Node,
			NodeID, Null, ExcludedNodes, NamespacesOfNestedNodes);
		If Result <> Undefined Then
			NodeFound = True;
			AddNamespaces(NamespacesUpToANode,
				Node, NamespacesOfNestedNodes);
			Break;
		EndIf;
	EndDo;
	
	If Not NodeFound Then
		Result = Undefined;
	EndIf;
	
	If ErrorText = Null Then
		Return Result;
	EndIf;
	
	If NodeFound And ErrorIfFound Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В документе XML найдено более одного узла с атрибутом ""%1"" и значением ""%2"".';
				|en = 'More than one node with the %1 attribute and the %2 value is found in the XML document.';"),
			NameOfTheIDAttribute,
			NodeID);
	ElsIf Not NodeFound And Not ErrorIfFound Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В документе XML не найден узел с атрибутом ""%1"" и значением ""%2"".';
				|en = 'Node with the %1 attribute and the %2 value is not found in the XML document.';"),
			NameOfTheIDAttribute,
			NodeID);
	EndIf;
	
	Return Result;
	
EndFunction

Procedure AddNamespaces(Namespaces, Node, NamespacesOfNestedNodes)
	
	If Namespaces <> Undefined Then
		For Each Attribute In Node.Attributes Do
			If Attribute.Prefix <> "xmlns" Then
				Continue;
			EndIf;
			Namespace = Attribute.NodeName + "=""" + Attribute.NodeValue + """";
			If Namespaces.Find(Namespace) = Undefined Then
				Namespaces.Add(Namespace);
			EndIf;
		EndDo;
		For Each Namespace In NamespacesOfNestedNodes Do
			If Namespaces.Find(Namespace) = Undefined Then
				Namespaces.Add(Namespace);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Function GetValue(DOMElement, XMLEnvelopeProperties, PropertyName, Properties = Undefined, MultipleSigning = False)
	
	Value = DOMElement.TextContent;
	
	AdditionalParameters = AttributeAdditionalParameters(MultipleSigning, Properties);
	
	Result = CheckSetValue(Value,
		DOMElement, "", XMLEnvelopeProperties, PropertyName, AdditionalParameters);
	
	Return Result;
	
EndFunction

Function AttributeAdditionalParameters(MultipleSigning, Properties = Undefined, NameWithParent = False)
	
	Structure = New Structure;
	Structure.Insert("MultipleSigning", MultipleSigning);
	Structure.Insert("Properties", Properties);
	Structure.Insert("NameWithParent", NameWithParent);
	
	Return Structure;
	
EndFunction

Function GetAttribute(DOMElement, AttributeName, XMLEnvelopeProperties, PropertyName,
			LowercaseValue = False, AdditionalParameters = Undefined)
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AttributeAdditionalParameters(False);
	EndIf;
	
	Attribute = DOMElement.Attributes.GetNamedItem(AttributeName);
	If Attribute = Undefined Then
		XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В документе XML для узла ""%1"" не найден атрибут ""%2"".';
				|en = 'The %2 attribute is not found for the %1 node in the XML document.';"),
			DOMElement.LocalName, AttributeName);
		Return False;
	EndIf;
	Value = Attribute.NodeValue;
	
	If LowercaseValue Then
		Value = Lower(Value);
	EndIf;
	
	Result = CheckSetValue(Value,
		DOMElement, AttributeName, XMLEnvelopeProperties, PropertyName,
		AdditionalParameters);
	
	Return Result;
	
EndFunction

Function CheckSetValue(Value, DOMElement, AttributeName, XMLEnvelopeProperties, PropertyName, AdditionalParameters)
	
	If Not CheckTheUniquenessOfTheNode(DOMElement, XMLEnvelopeProperties, AdditionalParameters) Then
		Return False;
	EndIf;
	
	If XMLEnvelopeProperties.AvailableProperties.Property(PropertyName) Then
		AvailableValues = XMLEnvelopeProperties.AvailableProperties[PropertyName];
		If AvailableValues.ThisIsBase64String Or AvailableValues.ThisIsTheURI Then
			Value = TrimAll(Value);
		EndIf;
		
		If Not XMLEnvelopeProperties.CheckSignature
		   And ValueIsFilled(AvailableValues.ParameterName) Then
		   
			If Value <> AvailableValues.ParameterName And Not AdditionalParameters.MultipleSigning Then
				If ValueIsFilled(AttributeName) Then
					XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'В документе XML для узла ""%1"" в атрибуте ""%2"" должно быть указано значение ""%3"".';
							|en = 'The %1 node requires the %3 value in the %2 attribute in the XML document.';"),
						DOMElement.LocalName, AttributeName, AvailableValues.ParameterName);
				Else
					XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'В документе XML для узла ""%1"" должно быть указано значение ""%2"".';
							|en = 'The %1 node requires the %2 value in the XML document.';"),
						DOMElement.LocalName, AvailableValues.ParameterName);
				EndIf;
				Return False;
			EndIf;
		
		ElsIf AvailableValues.ThisIsBase64String Then
			Try
				Base64Value = Base64Value(Value);
			Except
				Base64Value = "";
			EndTry;
			If Not ValueIsFilled(Base64Value) Then
				If ValueIsFilled(AttributeName) Then
					XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'В документе XML для узла ""%1"" в атрибуте ""%2"" указано не Base64 значение ""%3"".';
							|en = 'The %3 Base64 value is not specified for the %1 node in the %2 attribute in the XML document.';"),
						DOMElement.LocalName, AttributeName, Value);
				Else
					XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'В документе XML для узла ""%1"" указано не Base64 значение ""%2"".';
							|en = 'The %2 Base64 value is not specified for the %1 node in the XML document.';"),
						DOMElement.LocalName, AttributeName, Value);
				EndIf;
				Return False;
			EndIf;
			
		ElsIf AvailableValues.ThisIsTheURI Then
			If Not StrStartsWith(Value, "#")
			 Or StrLen(Value) < 2 Then
				If ValueIsFilled(AttributeName) Then
					XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'В документе XML для узла ""%1"" в атрибуте ""%2"" указан некорректный URI ""%3"".';
							|en = 'The %1 node has invalid %3 URI in the %2 attribute in the XML document.';"),
						DOMElement.LocalName, AttributeName, Value);
				Else
					XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'В документе XML для узла ""%1"" указан некорректный URI ""%2"".';
							|en = 'The %1 node has invalid %2 URI in the XML document.';"),
						DOMElement.LocalName, AttributeName, Value);
				EndIf;
				Return False;
			EndIf;
			Value = Mid(Value, 2);
			
		ElsIf ValueIsFilled(AvailableValues.Values) Then
			LongDesc = AvailableValues.Values.Get(Value);
			If LongDesc = Undefined Then
				If ValueIsFilled(AttributeName) Then
					XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'В документе XML для узла ""%1"" в атрибуте ""%2"" указано недопустимое значение ""%3"".';
							|en = 'The %1 node has invalid %3 value in the %2 attribute in the XML document.';"),
						DOMElement.LocalName, AttributeName, Value);
				Else
					XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'В документе XML для узла ""%1"" указано недопустимое значение ""%2"".';
							|en = 'The %1 node has invalid %2 value in the XML document.';"),
						DOMElement.LocalName, AttributeName, Value);
				EndIf;
				Return False;
			Else
				Value = LongDesc;
			EndIf;
		EndIf;
	EndIf;
	
	If AdditionalParameters.Properties = Undefined Then
		PropertiesSet = XMLEnvelopeProperties;
	Else
		PropertiesSet = AdditionalParameters.Properties;
	EndIf;
	
	If TypeOf(PropertiesSet[PropertyName]) = Type("Array") Then
		If PropertiesSet[PropertyName].Find(Value) = Undefined Then
			PropertiesSet[PropertyName].Add(Value);
		EndIf;
	Else
		PropertiesSet[PropertyName] = Value;
	EndIf;
	
	Return True;
	
EndFunction

Function CheckTheUniquenessOfTheNode(DOMElement, XMLEnvelopeProperties, AdditionalParameters = Undefined)
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AttributeAdditionalParameters(False);
	EndIf;
	
	PropertyName = DOMElement.LocalName;
	If AdditionalParameters.NameWithParent Then
		PropertyName = DOMElement.ParentNode.LocalName + "_" + PropertyName;
	EndIf;
	
	If XMLEnvelopeProperties.RequiredNodes.Property(PropertyName) Then
		XMLEnvelopeProperties.RequiredNodes[PropertyName] = DOMElement;
	EndIf;
	
	If Not XMLEnvelopeProperties.UniqueNodes.Property(PropertyName) Then
		Return True;
	EndIf;
	
	If AdditionalParameters.MultipleSigning Then
		If PropertyName = "SignedInfo_Reference" Then
			If XMLEnvelopeProperties.UniqueNodes[PropertyName] = Undefined Then
				XMLEnvelopeProperties.UniqueNodes[PropertyName] = New Array;
			EndIf;
			XMLEnvelopeProperties.UniqueNodes[PropertyName].Add(DOMElement);
		Else
			XMLEnvelopeProperties.UniqueNodes[PropertyName] = DOMElement;
		EndIf;
	Else
		
		If XMLEnvelopeProperties.UniqueNodes[PropertyName] <> Undefined Then
			If AdditionalParameters.NameWithParent Then
				XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В документе XML узел ""%1"" встречается более одного раза в узле ""%2"".';
						|en = 'The %1 node appears more than once in the %2 node in the XML document.';"),
					DOMElement.LocalName,
					DOMElement.ParentNode.LocalName);
			Else
				XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В документе XML узел ""%1"" встречается более одного раза.';
						|en = 'The %1 node appears more than once in the XML document.';"),
					PropertyName);
			EndIf;
			Return False;
		EndIf;
		XMLEnvelopeProperties.UniqueNodes[PropertyName] = DOMElement;
	EndIf;
	
	Return True;
	
EndFunction

// Parameters:
//  ServicePropertiesOfTheXMLEnvelope - See ServicePropertiesOfTheXMLEnvelope
//
// Returns:
//  Structure:
//   * ErrorText         - String
//   * SignedInfoArea   - See DigitalSignatureInternalClientServer.XMLScope
//   * AreasBody         - Array of See DigitalSignatureInternalClientServer.XMLScope
//   * TheCanonizationAlgorithm - See TheCanonizationAlgorithm
//   * SignAlgorithm     - See SignatureAndHashingAlgorithm
//   * AreasToHash   - Array of See DescriptionOfTheHashedArea
//   * SignatureValue     - String - the Base64 string.
//   * Certificate          - See CertificateDetails
//   * CheckSignature     - Boolean - when False, signing.
//
Function ReturnedPropertiesOfTheXMLEnvelope(ServicePropertiesOfTheXMLEnvelope = Undefined)
	
	Result = New Structure;
	Result.Insert("ErrorText", "");
	Result.Insert("SignedInfoArea");
	Result.Insert("AreasBody", New Array);
	Result.Insert("TheCanonizationAlgorithm");
	Result.Insert("SignAlgorithm");
	Result.Insert("AreasToHash", New Array);
	Result.Insert("SignatureValue", "");
	Result.Insert("Certificate", CertificateDetails());
	Result.Insert("CheckSignature", False);
	
	If TypeOf(ServicePropertiesOfTheXMLEnvelope) = Type("Structure") Then
		FillPropertyValues(Result, ServicePropertiesOfTheXMLEnvelope);
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  CheckSignature - Boolean
//
// Returns:
//  Structure:
//   * ErrorText         - String
//   * SignedInfoArea   - See DigitalSignatureInternalClientServer.XMLScope
//   * AreasBody         - Array of See DigitalSignatureInternalClientServer.XMLScope
//   * TheCanonizationAlgorithm - See TheCanonizationAlgorithm
//   * SignAlgorithm     - See SignatureAndHashingAlgorithm
//   * AreasToHash   - Array of See DescriptionOfTheHashedArea
//   * SignatureValue     - String - the Base64 string.
//   * Certificate          - See CertificateDetails
//   * CheckSignature     - Boolean - when False, signing.
//   * AvailableProperties   - See AvailableXMLEnvelopeProperties
//   * RequiredNodes    - Structure of KeyAndValue:
//       * Key     - String - a node name or a parent node name with a node name.
//       * Value - DOMElement
//                  - Undefined
//   * UniqueNodes      - Structure of KeyAndValue:
//       * Key     - String - a node name or a parent node name with a node name.
//       * Value - DOMElement
//                  - Undefined
//
Function ServicePropertiesOfTheXMLEnvelope(CheckSignature)
	
	Result = ReturnedPropertiesOfTheXMLEnvelope();
	Result.CheckSignature = CheckSignature;
	Result.Insert("AvailableProperties", AvailableXMLEnvelopeProperties(CheckSignature));
	Result.Insert("RequiredNodes", New Structure(
		"SignedInfo,SignatureValue,KeyInfo,
		|CanonicalizationMethod,SignatureMethod,SignedInfo_Reference,
		|DigestMethod,DigestValue"));
	Result.Insert("UniqueNodes", New Structure(
		"SignedInfo,SignatureValue,KeyInfo,
		|CanonicalizationMethod,SignatureMethod,SignedInfo_Reference,
		|Transforms,DigestMethod,DigestValue,
		|X509Data,X509Certificate,SecurityTokenReference,Reference"));
	
	Return Result;
	
EndFunction

// Returns:
//  Structure:
//   * NodeID      - String
//   * TransformationAlgorithms - Array of See TheCanonizationAlgorithm
//   * HashAlgorithm    - See SignatureAndHashingAlgorithm
//   * HashValue           - String - the Base64 string.
//
Function DescriptionOfTheHashedArea()
	
	Result = New Structure;
	Result.Insert("NodeID", "");
	Result.Insert("TransformationAlgorithms", New Array);
	Result.Insert("HashAlgorithm", "");
	Result.Insert("HashValue", "");
	
	Return Result;
	
EndFunction

// Returns:
//  Structure:
//   * NodeID   - String
//   * CertificateValue - String - the Base64 string.
//
Function CertificateDetails()
	
	Result = New Structure;
	Result.Insert("NodeID",   "");
	Result.Insert("CertificateValue", "");
	
	Return Result;
	
EndFunction

// Parameters:
//  CheckSignature - Boolean
//
// Returns:
//  Structure:
//   * NodeID      - See AvailableValues
//   * TheCanonizationAlgorithm    - See AvailableValues
//   * TransformationAlgorithms - See AvailableValues
//   * HashValue           - See AvailableValues
//   * SignatureValue        - See AvailableValues
//   * CertificateValue    - See AvailableValues
//   * SignAlgorithm        - See AvailableValues
//   * HashAlgorithm    - See AvailableValues
//
Function AvailableXMLEnvelopeProperties(CheckSignature)
	
	Result = New Structure;
	Result.Insert("NodeID", AvailableValues("", , True));
	
	Result.Insert("TheCanonizationAlgorithm", AvailableValues(""));
	// Canonical XML 1.0.
	Values = Result.TheCanonizationAlgorithm.Values;
	Values.Insert("http://www.w3.org/TR/2001/REC-xml-c14n-20010315", TheCanonizationAlgorithm("C14N", 0, 0));
	If CheckSignature Then
		Values.Insert("http://www.w3.org/TR/2001/REC-xml-c14n-20010315#", TheCanonizationAlgorithm("C14N", 0, 0));
	EndIf;
	Values.Insert("http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments", TheCanonizationAlgorithm("C14N", 0, 1));
	// Canonical XML 1.1.
	Values.Insert("http://www.w3.org/2006/12/xml-c14n11", TheCanonizationAlgorithm("C14N", 2, 0));
	If CheckSignature Then
		Values.Insert("http://www.w3.org/2006/12/xml-c14n11#", TheCanonizationAlgorithm("C14N", 2, 0));
	EndIf;
	Values.Insert("http://www.w3.org/2006/12/xml-c14n11#WithComments", TheCanonizationAlgorithm("C14N", 2, 1));
	// Exclusive XML Canonicalization 1.0.
	Values.Insert("http://www.w3.org/2001/10/xml-exc-c14n#", TheCanonizationAlgorithm("C14N", 1, 0));
	If CheckSignature Then
		Values.Insert("http://www.w3.org/2001/10/xml-exc-c14n", TheCanonizationAlgorithm("C14N", 1, 0));
	EndIf;
	Values.Insert("http://www.w3.org/2001/10/xml-exc-c14n#WithComments", TheCanonizationAlgorithm("C14N", 1, 1));
	If CheckSignature Then
		BringKeysToLowercase(Result.TheCanonizationAlgorithm.Values);
	EndIf;
	
	Result.Insert("TransformationAlgorithms", AvailableValues(""));
	Values = New Map(New FixedMap(Values));
	Result.TransformationAlgorithms.Values = Values;
	Values.Insert("urn://smev-gov-ru/xmldsig/transform", TheCanonizationAlgorithm("smev", 0, 0));
	Values.Insert("http://www.w3.org/2000/09/xmldsig#enveloped-signature", TheCanonizationAlgorithm("envsig", 0, 0));
	If CheckSignature Then
		BringKeysToLowercase(Result.TransformationAlgorithms.Values);
	EndIf;
	
	Result.Insert("HashValue",        AvailableValues("%DigestValue%", True));
	Result.Insert("SignatureValue",     AvailableValues("%SignatureValue%", True));
	Result.Insert("CertificateValue", AvailableValues("%BinarySecurityToken%", True));
	
	Result.Insert("SignAlgorithm",     AvailableValues("%SignatureMethod%"));
	Result.Insert("HashAlgorithm", AvailableValues("%DigestMethod%"));
	
	Sets = DigitalSignatureInternalClientServer.SetsOfAlgorithmsForCreatingASignature();
	For Each Set In Sets Do
		Result.SignAlgorithm.Values.Insert(Set.NameOfTheXMLSignatureAlgorithm,
			SignatureAndHashingAlgorithm(Set.NameOfTheXMLSignatureAlgorithm, Set.IDOfTheSignatureAlgorithm));
		Result.HashAlgorithm.Values.Insert(Set.NameOfTheXMLHashingAlgorithm,
			SignatureAndHashingAlgorithm(Set.NameOfTheXMLHashingAlgorithm, Set.IdOfTheHashingAlgorithm));
	EndDo;
	If CheckSignature Then
		BringKeysToLowercase(Result.SignAlgorithm.Values);
		BringKeysToLowercase(Result.HashAlgorithm.Values);
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  Name           - String
//  Id - String
//
// Returns:
//  Structure:
//   * Name           - String
//   * Id - String
//
Function SignatureAndHashingAlgorithm(Name, Id)
	
	Result = New Structure;
	Result.Insert("Name", Name);
	Result.Insert("Id", Id);
	
	Return Result;
	
EndFunction

// Parameters:
//  Kind            - String
//  Version         - Number
//  WithComments - Number
//
// Returns:
//  Structure:
//   * Kind            - String
//   * Version         - Number
//   * WithComments - Number
//
Function TheCanonizationAlgorithm(Kind, Version, WithComments) Export
	
	Result = New Structure;
	Result.Insert("Kind", Kind);
	Result.Insert("Version", Version);
	Result.Insert("WithComments", WithComments);
	
	Return Result;
	
EndFunction

// Parameters:
//  ParameterName    - String
//  ThisIsBase64String - Boolean
//  ThisIsTheURI          - Boolean
//
// Returns:
//  Structure:
//   * ParameterName    - String
//   * ThisIsBase64String - Boolean
//   * ThisIsTheURI          - Boolean
//   * Values - Map of KeyAndValue:
//       ** Key     - String
//       ** Value - Structure
//
Function AvailableValues(ParameterName, ThisIsBase64String = False, ThisIsTheURI = False)
	
	Result = New Structure;
	Result.Insert("ParameterName", ParameterName);
	Result.Insert("Values", New Map);
	Result.Insert("ThisIsBase64String", ThisIsBase64String);
	Result.Insert("ThisIsTheURI", ThisIsTheURI);
	
	Return Result;
	
EndFunction

Procedure BringKeysToLowercase(Values)
	
	NewValues = New Map;
	
	For Each KeyAndValue In Values Do
		NewValues.Insert(Lower(KeyAndValue.Key), KeyAndValue.Value);
	EndDo;
	
	Values = NewValues;
	
EndProcedure

#EndRegion

#Region CryptoErrorsClassifier

Function ClassifierError(TextToSearchInClassifier, ErrorAtServer = False, SignatureVerificationError = False) Export
	
	ClassifierError = DigitalSignatureInternalCached.ClassifierError(
		TextToSearchInClassifier, ErrorAtServer, SignatureVerificationError);
		
	If ClassifierError = Undefined Then
		Return Undefined;
	EndIf;
	
	ErrorPresentation = ErrorPresentation();
	FillPropertyValues(ErrorPresentation, ClassifierError);
	
	Return ErrorPresentation;
	
EndFunction

Function ErrorPresentation() Export
	
	ErrorPresentation = New Structure;
	ErrorPresentation.Insert("Ref", "");
	ErrorPresentation.Insert("Cause", "");
	ErrorPresentation.Insert("Decision", "");
	ErrorPresentation.Insert("Remedy", "");
	ErrorPresentation.Insert("RemedyActions");
	ErrorPresentation.Insert("IsCheckRequired", False);
	ErrorPresentation.Insert("CertificateRevoked", False);
	ErrorPresentation.Insert("InvalidSignatureHash", False);
	ErrorPresentation.Insert("UnknownCryptographyAlgorithm", False);
	
	Return ErrorPresentation;
	
EndFunction

Function CryptoErrorsClassifier() Export
	
	SetPrivilegedMode(True);
	
	Version = Undefined;
	
	If Metadata.CommonModules.Find("DigitalSignatureInternalLocalization") <> Undefined Then
		
		ModuleDigitalSignatureInternalLocalization = Common.CommonModule("DigitalSignatureInternalLocalization");
		
		If Not Common.DataSeparationEnabled() 
			And Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
			
			Try
				ErrorText = ModuleDigitalSignatureInternalLocalization.UpdateClassifier();
			Except
				ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndTry;
			
			If ValueIsFilled(ErrorText) Then
				Comment = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось обновить классификатор ошибок криптографии по причине:
					           |%1';
								|en = 'Cannot update the cryptography error classifier due to:
								|%1';"), ErrorText);
				WriteLogEvent(
					NStr("ru = 'Электронная подпись.Обновление классификатора ошибок';
						|en = 'Digital signature.Error classifier update';",
					Common.DefaultLanguageCode()),
					EventLogLevel.Error,,,
					Comment);
			EndIf;
		EndIf;
		
		Version = ModuleDigitalSignatureInternalLocalization.ClassifierVersion();
		
	EndIf;
	
	ClassifierData = Constants.CryptoErrorsClassifier.Get().Get();
	
	If TypeOf(ClassifierData) = Type("Structure") Then
		Try
			If ValueIsFilled(Version)
				And CommonClientServer.CompareVersions(ClassifierData.Version, Version) < 0 Then
				
				Version = Undefined;
			Else
				Version = ClassifierData.Version;
			EndIf;
		Except
			Version = Undefined;
		EndTry;
	Else
		ClassifierData = Undefined;
	EndIf;
	
	If Not ValueIsFilled(ClassifierData)
		Or Version = Undefined Then
		
		If Metadata.CommonModules.Find("DigitalSignatureInternalLocalization") = Undefined Then
			Return Undefined;
		EndIf;
		
		ModuleDigitalSignatureInternalLocalization = Common.CommonModule("DigitalSignatureInternalLocalization");
		ClassifierData = ModuleDigitalSignatureInternalLocalization.CryptoErrorsClassifier();
		If Not ValueIsFilled(ClassifierData) Then
			Return Undefined;
		EndIf;
	EndIf;
	
	Result = NewClassifierOfCryptoErrors();
	For Each TableRow In ClassifierData.Classifier Do
		NewRow = Result.Add();
		FillPropertyValues(NewRow, TableRow);
	EndDo;
	
	Return Result;
	
EndFunction

Function NewClassifierOfCryptoErrors()
	
	Result = New ValueTable;
	Result.Columns.Add("ErrorText",
		New TypeDescription("String", New StringQualifiers(500)));
	Result.Columns.Add("ErrorTextLowerCase",
		New TypeDescription("String", New StringQualifiers(500)));
	Result.Columns.Add("Cause",
		New TypeDescription("String", New StringQualifiers(500)));
	Result.Columns.Add("Decision",
		New TypeDescription("String", New StringQualifiers(750)));
	Result.Columns.Add("Remedy",
		New TypeDescription("String", New StringQualifiers(500)));
	Result.Columns.Add("Ref",
		New TypeDescription("String", New StringQualifiers(500)));
		
	Result.Columns.Add("OnlyServer",    New TypeDescription("Boolean"));
	Result.Columns.Add("OnlyClient",    New TypeDescription("Boolean"));
	Result.Columns.Add("IsCheckRequired", New TypeDescription("Boolean"));
	Result.Columns.Add("CertificateRevoked",  New TypeDescription("Boolean"));
	Result.Columns.Add("InvalidSignatureHash", New TypeDescription("Boolean"));
	Result.Columns.Add("IsSignatureVerificationError", New TypeDescription("Boolean"));
	Result.Columns.Add("UnknownCryptographyAlgorithm", New TypeDescription("Boolean"));
	
	Return Result;
	
EndFunction

// For internal use only.
Procedure WriteClassifierData(ClassifierData, LastChangeDate = Undefined) Export
	
	If ClassifierData <> Undefined Then
		
		Constants.CryptoErrorsClassifier.Set(
			New ValueStorage(RepresentationOfErrorClassifier(ClassifierData), New Deflation(9)));
	
	EndIf;
	
	If LastChangeDate <> Undefined Then
		Constants.LatestErrorsClassifierUpdateDate.Set(
			LastChangeDate);
	EndIf;
	
EndProcedure

// For internal use only.
Function RepresentationOfErrorClassifier(ClassifierData) Export
	
	JSONReader = New JSONReader;
	If TypeOf(ClassifierData) = Type("String") Then
		JSONReader.SetString(ClassifierData);
	Else
		JSONReader.OpenStream(ClassifierData.OpenStreamForRead());
	EndIf;
	
	ErrorsClassifier = ReadJSON(JSONReader,, "LastChangeDate");
	ClassifierVersion = CommonClientServer.StructureProperty(
		ErrorsClassifier, "Version", Undefined);
	JSONReader.Close();
	
	Classifier = NewClassifierOfCryptoErrors();
	
	For Each KnownError In ErrorsClassifier.Classifier Do
		
		NewError = Classifier.Add();
		NewError.Ref           = KnownError.Anchor;
		NewError.Cause          = KnownError.Reason;
		NewError.Decision          = KnownError.Solution;
		NewError.OnlyServer     = CommonClientServer.StructureProperty(KnownError, "Server", False);
		NewError.OnlyClient     = CommonClientServer.StructureProperty(KnownError, "Client", False);
		NewError.IsSignatureVerificationError     = CommonClientServer.StructureProperty(KnownError, "Sign", False);
		Category = CommonClientServer.StructureProperty(KnownError, "Category", Undefined);
		If ValueIsFilled(Category) Then
			NewError.InvalidSignatureHash = ErrorInvalidSignatureHash(Category);
			If Not NewError.InvalidSignatureHash Then
				NewError.IsCheckRequired   = IsErrorRecheckRequired(Category);
				If Not NewError.IsCheckRequired Then
					NewError.CertificateRevoked = ErrorCertificateRevoked(Category);
					If Not NewError.CertificateRevoked Then
						NewError.UnknownCryptographyAlgorithm = ErrorUnknownCryptographyAlgorithm(Category);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		NewError.ErrorText      = KnownError.ErrorText;
		NewError.Remedy = KnownError.RepairMethods;
		NewError.ErrorTextLowerCase = Lower(NewError.ErrorText);
		
		ErrorTextInEnglish = CommonClientServer.StructureProperty(KnownError, "En", Undefined);
		If ValueIsFilled(ErrorTextInEnglish) Then
			NewErrorInEnglish = Classifier.Add();
			FillPropertyValues(NewErrorInEnglish, NewError);
			NewErrorInEnglish.ErrorText = KnownError.En;
			NewErrorInEnglish.ErrorTextLowerCase = Lower(NewErrorInEnglish.ErrorText);
		EndIf;
		
	EndDo;
	
	Return New Structure("Classifier, Version", Classifier, ClassifierVersion);
	
EndFunction

Function IsErrorRecheckRequired(Category)
	
	If Category = "untrustedroot" Or Category = "no_revocation_check" Or Category = "chaining" Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function ErrorCertificateRevoked(Category)
	
	If Category = "cert_revoked" Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function ErrorInvalidSignatureHash(Category)
	
	If Category = "hash_value" Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function ErrorUnknownCryptographyAlgorithm(Category)
	
	If Category = "unknown_algo" Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#Region DigitalSignatureDiagnostics

Procedure SupplementWithTechnicalInformationAboutServer(TechnicalInformation,
			VerifiedPathsToProgramModulesOnTheClient) Export
	
	If Not DigitalSignature.GenerateDigitalSignaturesAtServer()
		And Not DigitalSignature.VerifyDigitalSignaturesOnTheServer() Then
		
		TechnicalInformation = TechnicalInformation + Chars.LF
			+ NStr("ru = 'Электронная подпись на сервере не используется.';
					|en = 'Digital signature is not used on the server.';") + Chars.LF;
	Else
		TechnicalInformation = TechnicalInformation
			+ Chars.LF + TechnicalInformationOnComputer()
			+ Chars.LF + Chars.LF + TechnicalInformationAboutTheComponent()
			+ Chars.LF + TechnicalInformationOnApplications();
		
		TechnicalInformation = TechnicalInformation
			+ Chars.LF + DigitalSignatureInternalServerCall.TimestampServersDiagnosticsResult();
		
	EndIf;
	
	TechnicalInformation = TechnicalInformation + Chars.LF
		+ TechnicalInformationAboutProgramSettingsInTheReferenceGuide(VerifiedPathsToProgramModulesOnTheClient);
	
	If Common.FileInfobase() Then
		WorkMode = ?(Common.ClientConnectedOverWebServer(),
			NStr("ru = 'Файловый через веб';
				|en = 'File mode via web';"), NStr("ru = 'Файловый';
													|en = 'File';"));
	Else
		WorkMode = NStr("ru = 'Клиент-серверный';
							|en = 'Client/server';");
	EndIf;
	
	TechnicalInformation = TechnicalInformation
		+ Chars.LF + NStr("ru = 'Режим работы информационной базы';
							|en = 'Infobase operation mode';")+ " - " + WorkMode
		+ Chars.LF + Chars.LF + StandardSubsystemsServer.TechnicalInfoOnExtensionsAndSubsystemsVersions();
	
EndProcedure

Function TechnicalInformationOnComputer()
	
	StartupParameters = FileSystem.ApplicationStartupParameters();
	StartupParameters.WaitForCompletion = True;
	StartupParameters.GetOutputStream = True;
	StartupParameters.ThreadsEncoding = TextEncoding.UTF8;
	
	If Common.IsWindowsServer() Then
		Command = "echo %username%";
	Else
		Command = "whoami";
	EndIf;
	
	Result = FileSystem.StartApplication(Command, StartupParameters);
	If Result.ReturnCode = 0 Then
		OSUserName = TrimAll(Result.OutputStream);
	Else
		OSUserName = "";
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Сервер (%1):';
			|en = 'Server (%1):';"), ComputerName() + "\" + OSUserName) + Chars.LF
		+ DigitalSignatureInternalClientServer.DiagnosticsInformationOnComputer();
	
EndFunction

Function TechnicalInformationAboutTheComponent()
	
	VersionComponents = "";
	Try 
		VersionComponents = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI().GetVersion();
	Except
		VersionComponents = ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Версия компоненты %1 на сервере - %2';
			|en = 'Add-in ""%1"" version on server: %2';"), "ExtraCryptoAPI", VersionComponents); 
	
EndFunction

Function TechnicalInformationOnApplications()
	
	DiagnosticsInformation = "";
	
	InstalledAppsResult = InstalledCryptoProviders();
	
	If Not InstalledAppsResult.CheckCompleted Then
		DiagnosticsInformation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось автоматически определить приложения электронной подписи и шифрования на ""%1"": %2';
				|en = 'Couldn''t determine digital signing and encryption app on ""%1"": %2';"),
			ComputerName(), InstalledAppsResult.Error);
	Else
		
		If InstalledAppsResult.Cryptoproviders.Count() = 0 Then
			DiagnosticsInformation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Приложения электронной подписи и шифрования на ""%1"" не установлены.';
					|en = 'No data signing and encryption apps are installed on ""%1"".';"),
				ComputerName());
		Else
			DiagnosticsInformation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Автоматически определенные приложения электронной подписи и шифрования на сервере ""%1"":';
					|en = 'Digital signing and encryption apps automatically detected on server ""%1"":';"), ComputerName()) + Chars.LF;
			
			For Each Application In InstalledAppsResult.Cryptoproviders Do
				
				CreationParameters = CryptoManagerCreationParameters();
				CreationParameters.AutoDetect = False;
				CreationParameters.Application = Application;
				CreationParameters.ShowError = False;
				CreationParameters.ErrorDescription = New Structure;
				
				CryptoManager = CryptoManager("", CreationParameters);
				
				DiagnosticsInformation = DiagnosticsInformation
					+ DigitalSignatureInternalClientServer.DiagnosticInformationAboutTheProgram(Application,
						CryptoManager, CreationParameters.ErrorDescription);
			EndDo;
		EndIf;
	EndIf;
	
	UsedApplications = DigitalSignatureInternalServerCall.UsedApplications();
	
	If UsedApplications.Count() = 0 Then
		Return DiagnosticsInformation;
	EndIf;
	
	DiagnosticsInformation = DiagnosticsInformation + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Программы на сервере из справочника ""%1"":';
			|en = 'Applications on the server from the ""%1"" catalog:';"), ComputerName()) + Chars.LF;
	
	For Each Application In UsedApplications Do
		
		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.AutoDetect = False;
		CreationParameters.Application = Application;
		CreationParameters.ShowError = False;
		CreationParameters.ErrorDescription = New Structure;
		
		CryptoManager = CryptoManager("", CreationParameters);
		
		DiagnosticsInformation = DiagnosticsInformation
			+ DigitalSignatureInternalClientServer.DiagnosticInformationAboutTheProgram(Application,
				CryptoManager, CreationParameters.ErrorDescription);
	EndDo;
	
	Return DiagnosticsInformation;
	
EndFunction

Function TechnicalInformationAboutProgramSettingsInTheReferenceGuide(VerifiedPathsToProgramModulesOnTheClient)
	
	DiagnosticsInformation = Chars.LF
		+ NStr("ru = 'Настройки приложений электронной подписи и шифрования:';
				|en = 'Digital signing and encryption app settings:';") + Chars.LF;
	
	UsedApplications = DigitalSignatureInternalServerCall.UsedApplications();
	If UsedApplications.Count() = 0 Then
		DiagnosticsInformation = DiagnosticsInformation
			+ NStr("ru = 'В справочнике нет ни одного приложения электронной подписи и шифрования.';
					|en = 'The catalog contains no digital signing and encryption apps.';");
		Return DiagnosticsInformation;
	EndIf;
	
	For Each Application In UsedApplications Do
		DiagnosticsInformation = DiagnosticsInformation + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1:
			           |	Приложение: %2
			           |	Тип приложения: %3
			           |	Алгоритм подписи: %4
			           |	Алгоритм хеширования: %5
			           |	Алгоритм шифрования: %6
			           |	Режим использования %7';
						|en = '%1:
						|	App: %2
						|	Type: %3
						|	Signature algorithm: %4
						|	Hashing algorithm: %5
						|	Encryption algorithm: %6
						|	Usage mode %7';"),
			Application.Presentation,
			Application.ApplicationName,
			Application.ApplicationType,
			Application.SignAlgorithm,
			Application.HashAlgorithm,
			Application.EncryptAlgorithm,
			Application.UsageMode) + Chars.LF;
		
		If RequiresThePathToTheProgram(True) Then
			AddInformationAboutTheProgramPath(DiagnosticsInformation,
				NStr("ru = 'Пути к модулям приложения на клиенте:';
					|en = 'Paths to app''s modules on the client:';"),
				VerifiedPathsToProgramModulesOnTheClient.Get(Application.Ref).ApplicationPath);
		EndIf;
		If RequiresThePathToTheProgram() Then
			AddInformationAboutTheProgramPath(DiagnosticsInformation,
				NStr("ru = 'Пути к модулям приложения на сервере:';
					|en = 'Paths to the app modules on the server:';"),
				ApplicationPath(Application.Ref).ApplicationPath);
		EndIf;
	EndDo;
	
	Return DiagnosticsInformation;
	
EndFunction

Procedure AddInformationAboutTheProgramPath(DiagnosticsInformation, Title, ApplicationPath)
	
	ThePathToTheModules = StrSplit(ApplicationPath, ":", False);
	
	DiagnosticsInformation = DiagnosticsInformation
		+ Chars.Tab + Title + Chars.LF
		+ Chars.Tab + Chars.Tab + """" + StrConcat(ThePathToTheModules,
			"""" + Chars.LF + Chars.Tab + Chars.Tab + """") + """"
		+ Chars.LF;
	
EndProcedure

// Download the revocation list file on server.
// 
// Parameters:
//  Addresses - Array of String
//  InternalAddress - String
// 
// Returns:
//  Structure - Download the revocation list file on server:
//   * FileAddress - String - Address the file was downloaded from. 
//   * FileName - String - file name 
//   * FileData - BinaryData
//   * ErrorMessage - String
//
Function DownloadRevocationListFileAtServer(Val Addresses, InternalAddress = Undefined) Export
	
	ImportResult1 = New Structure;
	ImportResult1.Insert("FileAddress", "");
	ImportResult1.Insert("FileName", "");
	ImportResult1.Insert("FileData", Undefined);
	ImportResult1.Insert("ErrorMessage", "");
	
	If Addresses.Count() = 0 Then
		ImportResult1.ErrorMessage = NStr("ru = 'В сертификате не указаны адреса списков отзыва.';
													|en = 'Revocation list addresses are not specified in the certificate.';");
		Return ImportResult1;
	EndIf;
	
	DataFromCache = Undefined;

	If ValueIsFilled(InternalAddress) Then
		DataFromCache = RevocationListDataFromDatabase(InternalAddress);
	
		If ValueIsFilled(DataFromCache.CheckDate) Then
			
			PopulateResultOfRevocationListImportFromCacheData(ImportResult1, DataFromCache);
			
			CheckDate = CurrentUniversalDate();
			
			If ValueIsFilled(ImportResult1.ErrorMessage) Then
				If DataFromCache.CheckDate + 1200 > CheckDate Then 
					// Run check upon error no more than once every 20 minutes.
					Return ImportResult1;
				EndIf;
			Else
				If DataFromCache.CheckDate + 1800 > CheckDate Then
					// Return the file if it was uploaded less than 30 min ago.
					Return ImportResult1;
				EndIf;
			EndIf;
			
			ImportResult1.ErrorMessage = "";
			
		EndIf;
	EndIf;
	
	If ValueIsFilled(InternalAddress) Then
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.CertificateRevocationLists");
		LockItem.SetValue("InternalAddress", InternalAddress);
		
		BeginTransaction();
		
		Try
			IsLockEnabled = True;
 			Block.Lock();
 			IsLockEnabled = False;
			
			NewDataFromCache = RevocationListDataFromDatabase(InternalAddress);
			If NewDataFromCache.CheckDate <> DataFromCache.CheckDate Then
				// Infobase data had been modified before the lock was applied.
				PopulateResultOfRevocationListImportFromCacheData(ImportResult1, NewDataFromCache);
				CommitTransaction();
				Return ImportResult1; 
			EndIf;
			
			LastChangeDate = Date(2021,1,1);
			DownloadRevocationListFile(Addresses, ImportResult1, DataFromCache, LastChangeDate);
			
			SetPrivilegedMode(True);
			RecordManager = InformationRegisters.CertificateRevocationLists.CreateRecordManager();
			
			If ValueIsFilled(DataFromCache) And DataFromCache.LastChangeDate = LastChangeDate And LastChangeDate <> Undefined Then
				
				FillPropertyValues(RecordManager, DataFromCache);
				PopulateResultOfRevocationListImportFromCacheData(ImportResult1, DataFromCache);
				
			ElsIf ImportResult1.FileData = Undefined Then

				If ValueIsFilled(DataFromCache) Then
					// Update the previous revocation list data.
					FillPropertyValues(RecordManager, DataFromCache);
					PopulateResultOfRevocationListImportFromCacheData(ImportResult1, DataFromCache);
				Else
					ImportResult1.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Ошибки при попытке загрузить файл(ы):
							 |%1
							 |Подробности см. в Журнале регистрации.';
							|en = 'Errors occurred when trying to import file(s):
							|%1
							|For more information, see the event log.';"), StrConcat(Addresses, Chars.LF));
				EndIf;
				
			Else
				
				RevocationListValidityPeriod = DigitalSignatureInternalClientServer.RevocationListProperties(ImportResult1.FileData);
				
				If RevocationListValidityPeriod = Undefined Then
					ImportResult1.FileData = Undefined;
					ImportResult1.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Файл %1 не является списком отзыва.';
							|en = 'This file is not a revocation list: %1.';"), ImportResult1.FileAddress);
				Else
					RecordManager.RevocationListAddress = ImportResult1.FileAddress;
					RecordManager.RevocationList = New ValueStorage(ImportResult1.FileData,
						New Deflation(9));
					RecordManager.LastChangeDate = LastChangeDate;
					RecordManager.ValidityStartDate      = RevocationListValidityPeriod.StartDate;
					RecordManager.ValidityEndDate   = RevocationListValidityPeriod.EndDate;
				EndIf;

			EndIf;
			
			RecordManager.InternalAddress = InternalAddress;
			RecordManager.CheckDate = CurrentUniversalDate();
			RecordManager.Write();
			CommitTransaction();

		Except
			
			RollbackTransaction();
			
			If IsLockEnabled Then // Revocation list is being updated.
				If Not ValueIsFilled(DataFromCache) Then
					ImportResult1.ErrorMessage = NStr("ru = 'Список отзыва находится в процессе обновления.';
																|en = 'Revocation list is being updated.';");
				EndIf;
			Else
				ErrorInfo = ErrorInfo();
				
				ImportResult1.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибки при загрузке списка отзыва:
						|%1
						|Подробности см. в Журнале регистрации.';
						|en = 'An error occurred when importing a revocation list:
						|%1
						|For more information, see the event log.';"),
					ErrorProcessing.BriefErrorDescription(ErrorInfo));
					
				WriteLogEvent(
					NStr("ru = 'Электронная подпись.Обновление списков отзыва';
						|en = 'Digital signature.Update revocation list';",
					Common.DefaultLanguageCode()),
					EventLogLevel.Error, , ,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
			EndIf;
			
			Return ImportResult1;
			
		EndTry;
	Else
		DownloadRevocationListFile(Addresses, ImportResult1);
	EndIf;
	
	Return ImportResult1;

EndFunction


// Intended for: DownloadRevocationListFileAtServer procedure
Procedure DownloadRevocationListFile(Addresses, ImportResult1, DataFromCache = Undefined, LastChangeDate = Undefined)
	
	ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
	ModuleNetworkDownloadClientServer = Common.CommonModule("GetFilesFromInternetClientServer");
	
	For Each CurrentAddress In Addresses Do
		
		If StrStartsWith(Lower(CurrentAddress), "ldap://") Then
			Continue;
		EndIf;
		
		FileGettingParameters = ModuleNetworkDownloadClientServer.FileGettingParameters();
		
		If ValueIsFilled(DataFromCache)
			And ValueIsFilled(DataFromCache.LastChangeDate)
			And DataFromCache.RevocationListAddress = CurrentAddress Then
			
			LastChangeDate = DataFromCache.LastChangeDate;
		EndIf;
		
		If ValueIsFilled(LastChangeDate) Then
			FileGettingParameters.Headers.Insert("If-Modified-Since", 
					CommonClientServer.HTTPDate(LastChangeDate));
		EndIf;
		
		ImportResult1.FileAddress = CurrentAddress;
		Result = ModuleNetworkDownload.DownloadFileAtServer(CurrentAddress, FileGettingParameters);
		
		If Result.StatusCode = 304 And ValueIsFilled(DataFromCache) Then // The file wasn't updated.
			PopulateResultOfRevocationListImportFromCacheData(ImportResult1, DataFromCache);
			Return;
		EndIf;
			
		If Result.Status Then
			LastChangeDate = FileLastModifiedDate(Result);
			
			FileName = RevocationListFilename(CurrentAddress);
			
			PathToFile = Result.Path;
			
			TempDirectory = Undefined;
			If StrEndsWith(FileName, ".zip") Then
				TempDirectory = FileSystem.CreateTemporaryDirectory(
					String(New UUID));
				ZipFileReader = New ZipFileReader(PathToFile);
				
				For Each ArchiveItem In ZipFileReader.Items Do
					FileNameInArchive = ArchiveItem.Name;
					ZipFileReader.Extract(ArchiveItem, TempDirectory);
					PathToFile = TempDirectory + FileNameInArchive;
					Break;
				EndDo;
				
				ZipFileReader.Close();
			EndIf;
			
			ImportResult1.FileName = FileName;
			ImportResult1.FileData = New BinaryData(PathToFile);
			If TempDirectory <> Undefined Then
				FileSystem.DeleteTemporaryDirectory(TempDirectory);
			EndIf;
			FileSystem.DeleteTempFile(Result.Path);
			
			Break;
		Else
			LastChangeDate = Undefined;
			ImportResult1.Insert("ErrorMessage", Result.ErrorMessage);
		EndIf;
	EndDo;
	
EndProcedure

Function RevocationListFilename(RevocationListAddress)
	
	PathAtServer = CommonClientServer.URIStructure(RevocationListAddress).PathAtServer;
	
	PathElements = StrSplit(PathAtServer, "/");
	
	Return CommonClientServer.ReplaceProhibitedCharsInFileName(PathElements[PathElements.UBound()]);

EndFunction

// Intended for: DownloadRevocationListFileAtServer procedure
Function RevocationListDataFromDatabase(InternalAddress)
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	RevocationLists.InternalAddress,
		|	RevocationLists.RevocationList,
		|	RevocationLists.CheckDate,
		|	RevocationLists.RevocationListAddress,
		|	RevocationLists.LastChangeDate,
		|	RevocationLists.ValidityStartDate,
		|	RevocationLists.ValidityEndDate
		|FROM
		|	InformationRegister.CertificateRevocationLists AS RevocationLists
		|WHERE
		|	RevocationLists.InternalAddress = &InternalAddress";
	
	Query.SetParameter("InternalAddress", InternalAddress);
	
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	Result = New Structure("InternalAddress, RevocationList, CheckDate, 
		|LastChangeDate, RevocationListAddress, ValidityStartDate, ValidityEndDate");
	
	If QueryResult.IsEmpty() Then
		Return Result;
	EndIf;
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		FillPropertyValues(Result, SelectionDetailRecords);
	EndDo;
	
	Return Result;
	
EndFunction

// Intended for: DownloadRevocationListFileAtServer procedure
Procedure PopulateResultOfRevocationListImportFromCacheData(ImportResult1, DataFromCache)
	
	If Not ValueIsFilled(DataFromCache.RevocationList) Then
		
		ImportResult1.FileAddress = Undefined;
		ImportResult1.FileName = Undefined;
		ImportResult1.FileData = Undefined;
		ImportResult1.ErrorMessage = NStr("ru = 'Список отзыва не загружен.';
													|en = 'Revocation list is not imported.';");
		Return;
		
	EndIf;
	
	FileData = DataFromCache.RevocationList.Get();
	
	If Not ValueIsFilled(FileData) Then
		
		ImportResult1.FileAddress = Undefined;
		ImportResult1.FileName = Undefined;
		ImportResult1.FileData = Undefined;
		ImportResult1.ErrorMessage = NStr("ru = 'Список отзыва не загружен.';
													|en = 'Revocation list is not imported.';");
		Return;
		
	EndIf;
	
	If Not ValueIsFilled(DataFromCache.ValidityEndDate) 
		Or DataFromCache.ValidityEndDate < CurrentUniversalDate() Then
		
		ImportResult1.FileAddress = Undefined;
		ImportResult1.FileName = Undefined;
		ImportResult1.FileData = Undefined;
		ImportResult1.ErrorMessage = NStr("ru = 'Список отзыва просрочен. Обратитесь в удостоверяющий центр, выдавший сертификат.';
													|en = 'The certificate revocation list is expired. Contact the certificate issuer.';");
		Return;
		
	EndIf;
	
	ImportResult1.FileAddress = DataFromCache.RevocationListAddress;
	ImportResult1.FileName = RevocationListFilename(DataFromCache.RevocationListAddress);
	ImportResult1.FileData = FileData;
	
EndProcedure

Function CertificatesChain(Val Certificate, FormIdentifier = Undefined, ComponentObject = Undefined) Export
	
	Certificate = CertificateBase64String(Certificate);
	Result = New Structure("Certificates, Error", New Array, ""); 
	
	Try
		If ComponentObject = Undefined Then
			ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
		EndIf;
		
		CertificatesResult = ComponentObject.GetCertificateChain(Certificate);
		
		Error = ComponentObject.ErrorList;
		If ValueIsFilled(Error) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить цепочку сертификатов: %1 (%2).';
					|en = 'Cannot receive the certificate chain: %1 (%2).';"), Error, ComputerName());
		EndIf;
		
		If CertificatesResult = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить цепочку сертификатов (%1).';
					|en = 'Cannot receive the certificate chain (%1).';"), ComputerName());
		EndIf;
		
		Result = DigitalSignatureInternalClientServer.CertificatesChainFromAddInResponse(
			CertificatesResult, FormIdentifier);
	Except
		Result.Error = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Return Result;
	EndTry;

	Return Result;
	
EndFunction

Function CertificatePropertiesExtended(Val Certificate, FormIdentifier = Undefined, ComponentObject = Undefined) Export
	
	Certificate = CertificateBase64String(Certificate);
	
	Result = New Structure("Error, CertificateProperties, CertificateBase64String", "");
	Result.CertificateBase64String = Certificate;
		
	Try
		
		CertificateProperties = New Structure;
		CertificateProperties.Insert("AddressesOfRevocationLists", New Array);
		
		If ComponentObject = Undefined Then
			ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
		EndIf;
	
		CertificatePropertiesResult = ComponentObject.GetCertificateProperties(Certificate);
		
		CertificateProperties = DigitalSignatureInternalClientServer.CertificatePropertiesFromAddInResponse(
			CertificatePropertiesResult);
	
		Result.CertificateProperties = CertificateProperties;
		
	Except
		
		Result.Error = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при получении расширенных свойств сертификата: %1';
				|en = 'An error occurred when receiving the extended certificate properties: %1';"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return Result;
		
	EndTry;
	
	Return Result;
	
EndFunction

// Base64String certificate.
// 
// Parameters:
//  Certificate - BinaryData
//             - String - Address in the temp storage.
//             - String - Certificate in the Base64String format.
//             - CryptoCertificate
// 
// Returns:
//  String - Base64String certificate
//
Function CertificateBase64String(Val Certificate)
	
	If TypeOf(Certificate) = Type("String") And IsTempStorageURL(Certificate) Then
		Certificate = GetFromTempStorage(Certificate);
	EndIf;

	If TypeOf(Certificate) = Type("String") Then
		Return Certificate;
	EndIf;
	
	If TypeOf(Certificate) = Type("CryptoCertificate") Then
		Certificate = Certificate.Unload();
	EndIf;
	
	Certificate = Base64String(Certificate);
	Certificate = StrReplace(Certificate, Chars.CR, "");
	Certificate = StrReplace(Certificate, Chars.LF, "");

	Return Certificate;
	
EndFunction

Function FileLastModifiedDate(ImportResult1) Export
	
	Headers = Undefined;
	If TypeOf(ImportResult1) = Type("Structure") Then
		Headers = CommonClientServer.StructureProperty(ImportResult1, "Headers", Undefined);
	ElsIf TypeOf(ImportResult1) = Type("HTTPResponse") Then
		Headers = ImportResult1.Headers;
	EndIf;
	
	If Headers = Undefined Then
		Return Undefined;
	EndIf;
	
	Headers = StandardSubsystemsServer.HTTPHeadersInLowercase(Headers);
	DateLastModifiedString = Headers["last-modified"];
	If DateLastModifiedString <> Undefined Then
		Return CommonClientServer.RFC1123Date(DateLastModifiedString);
	EndIf;
	
	Return Undefined;

EndFunction

Function SupplementErrorClassifierSolutionWithDetails(ClassifierError,
	AdditionalData, ClassifierErrorSolutionTextSupplementOptionsAtClient, ErrorLocation = Undefined) Export

	Result = New Structure("ClassifierError, ClassifierErrorSolutionTextSupplementOptionsAtClient",
		ClassifierError, ClassifierErrorSolutionTextSupplementOptionsAtClient);

	If Not ValueIsFilled(ClassifierError.RemedyActions) Then
		Return Result;
	EndIf;

	Decision = New Array;
	Cause = New Array;
	If ClassifierError.RemedyActions.Find(
					"MentionLinkToCAInSolution") <> Undefined Then
		CertificateIssuer = CertificateIssuer(AdditionalData.CertificateData);
		If ValueIsFilled(CertificateIssuer) Then

			Decision.Add(ClassifierError.Decision);
			Decision.Add(Chars.LF);
			Decision.Add(StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Удостоверяющий центр, выдавший сертификат: %1.';
								|en = 'Certificate authority that issued the certificate: %1.';"), CertificateIssuer));
		EndIf;
	EndIf;

#If Not MobileAppServer And Not MobileClient Then
	If ClassifierError.RemedyActions.Find(
					"CheckCertificateInLocalStore") <> Undefined Then

		SystemInfo = New SystemInfo;
		AppVersion = SystemInfo.AppVersion;
		If CommonClientServer.CompareVersions(AppVersion, "8.3.24.0") < 0 Then
			If ErrorLocation = "Server" Then
				If DigitalSignature.CommonSettings().VerifyDigitalSignaturesOnTheServer
					Or DigitalSignature.CommonSettings().GenerateDigitalSignaturesAtServer Then
					IsLocalStoreCertificate = IsLocalStoreCertificate(
						AdditionalData.CertificateData);
					If IsLocalStoreCertificate = True Then
						Decision = New Array;
						Decision.Add(StringFunctions.FormattedString(
							LocalStoreCertificateSolutionText(ErrorLocation)));
							
						Cause = New Array;
						Cause.Add(StringFunctions.FormattedString(
							LocalStoreCertificateReasonText(ErrorLocation)));
					EndIf;
				EndIf;
			Else
				Result.ClassifierErrorSolutionTextSupplementOptionsAtClient.CheckCertificateInClientLocalStore = True;
			EndIf;
		EndIf;
	EndIf;
#EndIf

	If ClassifierError.RemedyActions.Find(
					"TimestampServersDiagnosticsServer") <> Undefined Then

		Decision.Add(StringFunctions.FormattedString(
			NStr("ru = '<a href = ""%1"">Проверьте доступность</a> серверов меток времени на сервере %2.';
				|en = '<a href = ""%1"">Check the availability</a> of timestamps on server %2.';"),
			"TimestampServersDiagnosticsServer", ComputerName()));
	EndIf;

	If ClassifierError.RemedyActions.Find(
					"TimestampServersDiagnosticsClient") <> Undefined Then

		If Common.IsWebClient() Then
			
			TimestampServersAddresses = DigitalSignature.CommonSettings().TimestampServersAddresses;
			
			Array = New Array;
			
			For Each ServerAddress In TimestampServersAddresses Do
				
				RefStructure = CommonClientServer.URIStructure(ServerAddress);
				Array.Add(StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '<a href = ""%1"">%1</a>';
						|en = '<a href = ""%1"">%1</a>';"), ServerAddress));
				
			EndDo;
			
			Decision.Add(StringFunctions.FormattedString(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Проверьте доступность серверов меток времени на компьютере: %1.';
						|en = 'Check the availability of timestamps on computer: %1.';"),
					StrConcat(Array, ", "))));
			
		Else
			Decision.Add(StringFunctions.FormattedString(
				NStr("ru = '<a href = ""%1"">Проверьте доступность</a> серверов меток времени на компьютере.';
					|en = '<a href = ""%1"">Check the availability</a> of timestamps on computer.';"),
					"TimestampServersDiagnosticsClient"));
		EndIf;

	EndIf;

	If Decision.Count() > 0 Then
		Result.ClassifierError.Decision = New FormattedString(Decision);
	EndIf;
	
	If Cause.Count() > 0 Then
		Result.ClassifierError.Cause = New FormattedString(Cause);
	EndIf;

	Return Result;

EndFunction


Function LocalStoreCertificateSolutionText(Location)
	
	If Location = "Server" Then

		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Удалите сертификат из локального хранилища сервера %1.';
				|en = 'Delete the certificate from the local store on server %1.';"), ComputerName());

	EndIf;

	Return DigitalSignatureInternalClientServer.LocalStoreCertificateSolutionText();

EndFunction

Function LocalStoreCertificateReasonText(Location) Export
	
	If Location = "Server" Then

		Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr(
			"ru = 'На сервере %1 сертификат установлен в локальное хранилище, вместо хранилища текущего пользователя, под которым работает сервер.';
			|en = 'On server %1, the certificate is installed to the local store instead of the current user store.';"),
			ComputerName());

	EndIf;

	Return DigitalSignatureInternalClientServer.LocalStoreCertificateReasonText();
	
EndFunction

Function CertificateIssuer(CertificateData)
	
	If Not ValueIsFilled(CertificateData) Then
		Return Undefined;
	EndIf;
	
	If ValueIsFilled(CertificateData) Then
		CertificateAuthorityProperties = DigitalSignature.CertificateIssuerProperties(New CryptoCertificate(CertificateData));
		Return CertificateAuthorityProperties.CommonName;
	EndIf;
	
	Return Undefined;
EndFunction

Function IsLocalStoreCertificate(CertificateData)
	
#If Not MobileAppServer And Not MobileClient Then
	
	If Not ValueIsFilled(CertificateData) Then
		Return Undefined;
	EndIf;
	
	CryptoManager = CryptoManager("GetCertificates");
	Try
		LocalComputerStore = CryptoManager.GetCertificateStore(
			CryptoCertificateStoreType.PersonalCertificates,
			CryptoCertificateStorePlacement.ComputerData);
		CryptoCertificate = New CryptoCertificate(CertificateData);
	Except
		WriteLogEvent(NStr("ru = 'Электронная подпись.Диагностика ошибок';
										|en = 'Digital signature.Error troubleshooting';",
			Common.DefaultLanguageCode()), EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Return Undefined;
	EndTry;
	
	If LocalComputerStore.FindByThumbprint(CryptoCertificate.Thumbprint) <> Undefined Then
		Return True;
	EndIf;
	
#EndIf
	
	Return Undefined;
	
EndFunction

Procedure SetListOfCertificateRevocation(Certificate, Addresses = Undefined, InternalAddress = Undefined) Export
	
	ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
	
	If TypeOf(ComponentObject) = Type("String") Then
		Raise ComponentObject;
	EndIf;
	
	If ValueIsFilled(Addresses) Then
		If TypeOf(Addresses) = Type("String") Then
			Addresses = StrSplit(Addresses, ";");
		EndIf;
	Else
		Addresses = New Array;
	EndIf;
	
	AddressesOfRevocationLists = AddressesOfRevocationLists(Certificate, ComponentObject);
	If TypeOf(AddressesOfRevocationLists) = Type("String") And Not ValueIsFilled(Addresses) Then
		Raise AddressesOfRevocationLists;
	EndIf;
	
	For Each Address In AddressesOfRevocationLists Do
		If Addresses.Find(Address) = Undefined Then
			Addresses.Add(Address);
		EndIf;
	EndDo;
	
	Result = DownloadRevocationListFileAtServer(Addresses, InternalAddress);
	
	If ValueIsFilled(Result.ErrorMessage) Then
		Raise Result.ErrorMessage;
	EndIf;
	
	InstallResult = False;
	ErrorDescription = "";
	
	FileData = Result.FileData;
	
	RevocationListProperties = DigitalSignatureInternalClientServer.RevocationListProperties(FileData);
	
	If RevocationListProperties = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Файл %1 не является списком отзыва.';
				|en = 'This file is not a revocation list: %1.';"), Result.FileAddress);
	EndIf;
	
	If ValueIsFilled(RevocationListProperties.EndDate) And RevocationListProperties.EndDate < CurrentUniversalDate() Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Список отзыва %1 просрочен. Обратитесь в удостоверяющий центр, выдавший сертификат.';
				|en = 'The certificate revocation list %1 is expired. Contact the certificate issuer.';"), Result.FileAddress);
	EndIf;
	
	TempFileName = GetTempFileName(".crl");
	FileData.Write(TempFileName);
	
	Try
		ComponentObject.ImportCRLA(TempFileName, "CA");
		InstallResult = True;
	Except
		ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		InstallResult = False;
	EndTry;
	
	FileSystem.DeleteTempFile(TempFileName);
	
	If Not InstallResult Then
		Raise ErrorDescription;
	EndIf;
	
EndProcedure

Function AddressesOfRevocationLists(Certificate, ComponentObject)

	CertificatePropertiesExtended = CertificatePropertiesExtended(Certificate, ComponentObject);

	If ValueIsFilled(CertificatePropertiesExtended.Error) Then
		Return CertificatePropertiesExtended.Error;
	EndIf;

	AddressesOfRevocationLists = CertificatePropertiesExtended.CertificateProperties.AddressesOfRevocationLists;
	If AddressesOfRevocationLists.Count() = 0 Then
		Return NStr("ru = 'В сертификате не указаны адреса списков отзыва.';
					|en = 'Revocation list addresses are not specified in the certificate.';");
	EndIf;
	
	Return AddressesOfRevocationLists;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// Replaces in all profiles the role AddEditDigitalSignaturesAndEncryption with the roles:
// AddEditDigitalSignatures, AddEditDigitalSignatureAndEncryptionKeyCertificates,
// and EncryptAndDecryptData.
//
Procedure ReplaceRoleAddingChangeElectronicSignaturesAndEncryption() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Return;
	EndIf;
	
	ModuleAccessManagement = Common.CommonModule("AccessManagement");
	
	NewRoles = New Array;
	NewRoles.Add("AddEditDigitalSignatures");
	NewRoles.Add("EncryptAndDecryptData");
	NewRoles.Add("AddEditDigitalSignatureAndEncryptionKeyCertificates");
	RolesToReplace = New Map;
	RolesToReplace.Insert("? AddEditDigitalSignaturesAndEncryption", NewRoles);
	
	ModuleAccessManagement.ReplaceRolesInProfiles(RolesToReplace);
	
EndProcedure

#EndRegion

#Region CertificateContents

// Extended data for certificate print.
// 
// Parameters:
//  Data - BinaryData - Certificate data.
// 
// Returns:
//  Structure - Extended data for printing the certificate:
//   * IdentificationType - Number
//   * CIPF - String
//   * ClosingStatement - String
//   * CIPF_UC - String
//   * Conclusion - String
//   * Signature - BinaryData
//
Function ExtendedDataForCertificatePrint(Data) Export
	
	Structure = New Structure("IdentificationType, CIPF, ClosingStatement, CIPF_UC, Conclusion, Signature");
	
	DataAnalysis = DigitalSignatureInternalClientServer.NewDataAnalysis(Data);
	// SEQUENCE (Certificate).
	DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 16);
		// SEQUENCE (tbsCertificate).
		DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 16);
			// [0] EXPLICIT (version).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 2, 0);
			// INTEGER  (serialNumber         CertificateSerialNumber).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 0, 2);
			// SEQUENCE (signature            AlgorithmIdentifier).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 0, 16);
			// SEQUENCE (issuer               Name).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 0, 16);
			// SEQUENCE (validity             Validity).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 0, 16);
			// SEQUENCE (subject              Name).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 0, 16);
			// SEQUENCE (subjectPublicKeyInfo SubjectPublicKeyInfo).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 0, 16);
			// [1] IMPLICIT UniqueIdentifier OPTIONAL (issuerUniqueID).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 2, 1, False);
			// [2] IMPLICIT UniqueIdentifier OPTIONAL (subjectUniqueID).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 2, 2, False);
			// [3] EXPLICIT SEQUENCE SIZE (1..MAX) OF Extension (extensions). 
			DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 2, 3);
				// SEQUENCE OF
				DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 16);
				OffsetOfTheFollowing = DataAnalysis.Parents[0].OffsetOfTheFollowing;
				While DataAnalysis.Offset < OffsetOfTheFollowing Do
					// SEQUENCE (extension).
					DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 16);
					If DataAnalysis.HasError Then
						Break;
					EndIf; 
						// OBJECT IDENTIFIER
						DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 6);
							DataSize = DataAnalysis.Parents[0].DataSize;
							Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
							BufferString = GetHexStringFromBinaryDataBuffer(Buffer); // Id
						DigitalSignatureInternalClientServer.SkipTheParentBlock(DataAnalysis); // OBJECT IDENTIFIER

						If BufferString = "2A85036470" Then // 1.2.643.100.112
							DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 4); // OCTET STRING
								// IssuerSignTool ::= SEQUENCE {
								//  signTool     UTF8String SIZE(1..200),
								//  cATool       UTF8String SIZE(1..200),
								//  signToolCert UTF8String SIZE(1..100),
								//  cAToolCert   UTF8String SIZE(1..100) }.
								// SEQUENCE (IssuerSignTool).
								DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 16); // SEQUENCE
									Structure.CIPF = StringUTF8(DataAnalysis);
									Structure.CIPF_UC = StringUTF8(DataAnalysis);
									Structure.ClosingStatement = StringUTF8(DataAnalysis);
									Structure.Conclusion = StringUTF8(DataAnalysis);
								DataAnalysis.Parents.Delete(0); // SEQUENCE
							DataAnalysis.Parents.Delete(0); // OCTET STRING
						ElsIf BufferString = "2A85036472" Then // 1.2.643.100.114
							DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 4); // OCTET STRING
								DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 2); // INTEGER
									Structure.IdentificationType = DigitalSignatureInternalClientServer.ToReadTheWholeStream(DataAnalysis);
								DataAnalysis.Parents.Delete(0); // INTEGER
							DataAnalysis.Parents.Delete(0); // OCTET STRING
						EndIf;
							
					DigitalSignatureInternalClientServer.SkipTheParentBlock(DataAnalysis); // SEQUENCE
				EndDo; 
				DigitalSignatureInternalClientServer.SkipTheParentBlock(DataAnalysis); // SEQUENCE OF
			DigitalSignatureInternalClientServer.SkipTheParentBlock(DataAnalysis); // EXPLICIT SEQUENCE
		DigitalSignatureInternalClientServer.SkipTheParentBlock(DataAnalysis); // SEQUENCE (tbsCertificate)
	DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 0, 16); // signatureAlgorithm
	
	DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 3); // signatureValue
	If Not DataAnalysis.HasError Then
		DataSize = DataAnalysis.Parents[0].DataSize;
		Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
		Structure.Signature = GetBinaryDataFromBinaryDataBuffer(Buffer);
	Else 
		Raise NStr("ru = 'Непредвиденная ситуация при чтении расширенных данных сертификата.';
								|en = 'An unexpected error occurred when reading the extended certificate data.';");
	EndIf;

	Return Structure;
	
EndFunction

Function StringUTF8(DataAnalysis)
	
	DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 12); // UTF8String
	
	DataSize = DataAnalysis.Parents[0].DataSize;
	Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
	String = GetStringFromBinaryDataBuffer(Buffer, "UTF-8");
	
	DigitalSignatureInternalClientServer.SkipTheParentBlock(DataAnalysis); // UTF8String
	
	Return String;
	
EndFunction

#EndRegion

#EndRegion