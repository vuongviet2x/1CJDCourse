////////////////////////////////////////////////////////////////////////////////
// "Certificate storage" subsystem.
//  
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Adds a certificate to the certificate store.
// 
// Parameters:
//   Certificate - BinaryData - a certificate file.
//              - String - a certificate file address in a temporary storage.
//   StoreType - String, EnumRef.CertificatesStorageType - - Type of the storage to add the certificate to.
//
Procedure Add(Certificate, StoreType) Export

	If TypeOf(StoreType) = Type("String") Then
		StoreType = XMLValue(Type("EnumRef.CertificatesStorageType"), StoreType);
	EndIf;

	AddIncomingParameterVerification(Certificate, StoreType);

	If TypeOf(Certificate) = Type("String") Then
		CertificateBinaryData_ = GetFromTempStorage(Certificate);
	Else
		CertificateBinaryData_ = Certificate;
	EndIf;
		
	CertificateProperties = CryptographyService.GetCertificateProperties(CertificateBinaryData_);
	
	RecordSet = InformationRegisters.CertificatesStorage.CreateRecordSet();
	RecordSet.Filter.StoreType.Set(StoreType);
	RecordSet.Filter.Id.Set(CertificateProperties.Id);
	
	NewRecord = RecordSet.Add();
	NewRecord.StoreType  = StoreType;
	NewRecord.Id = CertificateProperties.Id;	
	NewRecord.StartDate    = CertificateProperties.StartDate;
	NewRecord.EndDate = CertificateProperties.EndDate;
	NewRecord.SerialNumber = Lower(StrReplace(CertificateProperties.SerialNumber, " ", ""));
	NewRecord.Thumbprint     = Lower(StrReplace(CertificateProperties.Thumbprint, " ", ""));
	If CertificateProperties.Subject.Property("CN") Then
		NewRecord.Description  = CertificateProperties.Subject.CN;
	EndIf;

	NewRecord.Certificate = New ValueStorage(CertificateProperties, New Deflation(9));
	
	RecordSet.Write();
	
EndProcedure

// Gets certificates from the storage.
// 
// Parameters:
//   StoreType - String, EnumRef.CertificatesStorageType - - Type of the storage to get certificates from.
//                                                                If not specified, get all certificates.
//                                                                
//
// Returns:
//	 Array of FixedStructure - Certificate properties.:
//    * Version - String - a certificate version.
//    * StartDate - Date - a start date of a certificate.
//    * EndDate - Date - the date the certificate will expire.
//    * Issuer - FixedStructure - Issuer information:
//        ** CN - String - commonName 
//        ** O - String - organizationName 
//        ** OU - String - organizationUnitName 
//        ** C - String - countryName 
//        ** ST - String - stateOrProvinceName 
//        ** L - String - localityName 
//        ** E - String - emailAddress 
//        ** SN - String - surname 
//        ** GN - String - givenName 
//        ** T - String - title
//        ** STREET - String - streetAddress
//        ** OGRN - String - Registration number
//        ** OGRNIP - String - Registration number of IE
//        ** INN - String - TIN (optional).
//        ** INNLE - String - Legal entity's TIN (optional).
//        ** SNILS - String - SNILS
//    * UseToSign - Boolean - indicates whether this certificate can be used for signing.
//    * UseToEncrypt - Boolean - indicates whether this certificate can be used for encryption.
//    * Thumbprint - BinaryData - Contains thumbprint data. It is calculated dynamically using the SHA-1 algorithm.
//    * Extensions - FixedStructure - extended certificate properties:
//        ** EKU - FixedArray of String - Enhanced Key Usage.
//    * SerialNumber - BinaryData - a serial number of a certificate.
//    * Subject - FixedStructure - Information about the certificate subject:
//        ** CN - String - commonName and so on. See Issuer.
//    * Certificate - BinaryData - Certificate file in the DER encoding.
//    * Id - String - Calculated from key Issuer properties and a serial number using the SHA1 algorithm.
//                               Used to identify a certificate in the crypto service.
//
Function Get(StoreType = Undefined) Export
		
	If TypeOf(StoreType) = Type("String") Then
		StoreType = XMLValue(Type("EnumRef.CertificatesStorageType"), StoreType);
	EndIf;
	
	If ValueIsFilled(StoreType) Then
		CommonClientServer.CheckParameter(
			"CertificatesStorage.Get", 
			"StoreType",
			StoreType, 
			New TypeDescription("EnumRef.CertificatesStorageType"));
	EndIf;
			
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	CertificatesStorage.Certificate,
	|	CertificatesStorage.StoreType
	|FROM
	|	InformationRegister.CertificatesStorage AS CertificatesStorage
	|WHERE
	|	(NOT &UseSelectionByStorageType
	|			OR CertificatesStorage.StoreType = &StoreType)";
	Query.SetParameter("StoreType", StoreType);
	Query.SetParameter("UseSelectionByStorageType", ValueIsFilled(StoreType));
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();	
	SetPrivilegedMode(False);
	
	Certificates = New Array;
	While Selection.Next() Do
		Certificates.Add(Selection.Certificate.Get());
	EndDo;
		
	Return Certificates;
		
EndFunction

// Searches for a certificate in the storage.
//
// Parameters:
//   Certificate - Structure - Key certificate parameters used for the search.:
//                            Thumbprint or SerialNumber and Issuer pair.
//     * Thumbprint - BinaryData - a certificate thumbprint.
//                 - String - a string presentation of the thumbprint.
//     * SerialNumber - BinaryData - a serial number of a certificate.
//                     - String - a string presentation of the serial number.
//     * Issuer - Structure - Issuer properties
//                - String - String presentation of the issuer.
//
// Returns: 
//   Undefined, FixedStructure - Certificate is not found or properties of the found certificate are the following:
//    * Description - String - a certificate description.
//    * Version - String - a certificate version.
//    * StartDate - Date - a start date of a certificate.
//    * EndDate - Date - the date the certificate will expire.
//    * Issuer - FixedStructure - Issuer information:
//        ** CN - String - commonName; 
//        ** O - String - organizationName; 
//        ** OU - String - organizationUnitName; 
//        ** C - String - countryName; 
//        ** ST - String - stateOrProvinceName; 
//        ** L - String - localityName; 
//        ** E - String - emailAddress; 
//        ** SN - String - surname; 
//        ** GN - String - givenName; 
//        ** T - String - title;
//        ** STREET - String - streetAddress;
//        ** OGRN - String - Registration number;
//        ** OGRNIP - String - Registration number of IE;
//        ** INN - String -  TIN (optional).
//        ** INNLE - String - Legal entity's TIN (optional).
//        ** SNILS - String - SNILS;
//           …
//    * UseToSign - Boolean - indicates whether this certificate can be used for signing.
//    * UseToEncrypt - Boolean - indicates whether this certificate can be used for encryption.
//    * Thumbprint - BinaryData - Contains thumbprint data. It is calculated dynamically using the SHA-1 algorithm.
//    * Extensions - FixedStructure -  extended certificate properties:
//        ** EKU - FixedArray of String - Enhanced Key Usage.
//    * SerialNumber - BinaryData - a serial number of a certificate.
//    * Subject - FixedStructure - Certificate subject information. For content, see Issuer.:
//        ** CN - String - commonName and so on.
//    * Certificate - BinaryData - Certificate file in the DER encoding.
//    * Id - String - Calculated from key Issuer properties and a serial number using the SHA1 algorithm.
//                               Used to identify a certificate in the crypto service.
//
Function FindCertificate(Certificate) Export
	
	FindCertificateCheckingIncomingParameters(Certificate);
	
	If Certificate.Property("Thumbprint") Then
		Thumbprint = Lower(StrReplace(Certificate.Thumbprint, " ", ""));
		
		Query = New Query;
		Query.Text =
		"SELECT ALLOWED
		|	CertificatesStorage.Certificate
		|FROM
		|	InformationRegister.CertificatesStorage AS CertificatesStorage
		|WHERE
		|	CertificatesStorage.Thumbprint = &Thumbprint";
		Query.SetParameter("Thumbprint", Thumbprint);
	Else
		If TypeOf(Certificate.Issuer) = Type("String") Then
			Issuer = ParsePublisherString(Certificate.Issuer);
		Else
			Issuer = Certificate.Issuer;
		EndIf;
		
		ListOfOIDs = New ValueList;
		For Each KeyValue In Issuer Do
			ListOfOIDs.Add(KeyValue.Value, KeyValue.Key);
		EndDo;
		
		Id = CryptographyServiceInternal.CalculateCertificateID(
			Certificate.SerialNumber, ListOfOIDs);
		
		Query = New Query;
		Query.Text =
		"SELECT ALLOWED
		|	CertificatesStorage.Certificate
		|FROM
		|	InformationRegister.CertificatesStorage AS CertificatesStorage
		|WHERE
		|	CertificatesStorage.Id = &Id";
		Query.SetParameter("Id", Id);		
	EndIf;
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	If Result.IsEmpty() Then
		Return Undefined;
	Else
		Selection = Result.Select();
		Selection.Next();
		
		Return Selection.Certificate.Get();
	EndIf;
	
EndFunction

#EndRegion


#Region Internal

// Returns certificate data in DER encoding.
// 
// Parameters:
// 	Certificate - BinaryData - certificate data.
// 	VerificationChar - String - 
// Returns:
// 	BinaryData - certificate data in DER encoding
// 
Function DERCertificate(Certificate, VerificationChar = "") Export
	
	FileName = GetTempFileName("cer");
	Certificate.Write(FileName);
	
	Text = New TextDocument;
	Text.Read(FileName);
	TextOfCertificate = Text.GetText();
	
	Try
		DeleteFiles(FileName);
	Except
		WriteLogEvent(
			NameOfDeleteFileEvent(),
			EventLogLevel.Error,,, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
		
	If StrFind(TextOfCertificate, "-----BEGIN CERTIFICATE-----") > 0 Then
		TextOfCertificate = StrReplace(TextOfCertificate, "-----BEGIN CERTIFICATE-----" + VerificationChar, "");
		TextOfCertificate = StrReplace(TextOfCertificate, VerificationChar + "-----END CERTIFICATE-----", "");
		Return Base64Value(TextOfCertificate);
	Else		
		Return Certificate;
	EndIf;
	
EndFunction

#EndRegion


#Region Private
	
Function NameOfDeleteFileEvent()
	
	Return NStr("ru = 'Хранилище сертификатов.Удаление файла';
				|en = 'Certificate store.Delete file';", Common.DefaultLanguageCode());
	
EndFunction

Procedure FindCertificateCheckingIncomingParameters(Certificate)
	
	CommonClientServer.CheckParameter(
		"CertificatesStorage.FindCertificate", 
		"Certificate",
		Certificate, 
		New TypeDescription("Structure, FixedStructure")
	);
	
	If Certificate.Property("Thumbprint") Then
		TypesOfCertificateProperties = New Structure;
		TypesOfCertificateProperties.Insert("Thumbprint", New TypeDescription("String, BinaryData"));
	Else
		TypesOfCertificateProperties = New Structure;
		TypesOfCertificateProperties.Insert("SerialNumber", New TypeDescription("String, BinaryData"));
		TypesOfCertificateProperties.Insert("Issuer", New TypeDescription("String, Structure, FixedStructure"));
	EndIf;

	CommonClientServer.CheckParameter(
		"CertificatesStorage.FindCertificate", 
		"Certificate",
		Certificate, 
		New TypeDescription("Structure, FixedStructure"),
		TypesOfCertificateProperties
	);
	
EndProcedure

Function ParsePublisherString(PublisherByLine)
	
	Components = New Map;
	
	SubstringForParsing = PublisherByLine;
	
	IndexIsEqualTo = StrFind(SubstringForParsing, "=", SearchDirection.FromEnd);
	While IndexIsEqualTo Do
		Value = Mid(SubstringForParsing, IndexIsEqualTo + 1);
		If Right(Value, 1) = "," Then
			StringFunctionsClientServer.DeleteLastCharInString(Value);
		EndIf;
		
		SubstringForParsing = Left(SubstringForParsing, IndexIsEqualTo - 1);
		
		CommaIndex = StrFind(SubstringForParsing, ",", SearchDirection.FromEnd);
		If CommaIndex Then
			Var_Key = Mid(SubstringForParsing, CommaIndex + 1);
			SubstringForParsing = Left(SubstringForParsing, CommaIndex);
		Else
			Var_Key = SubstringForParsing;	
		EndIf;
		IndexIsEqualTo = StrFind(SubstringForParsing, "=", SearchDirection.FromEnd);
		
		Components.Insert(TrimAll(Var_Key), TrimAll(Value));
	EndDo;
	
	Return Components;	
	
EndFunction

Procedure AddIncomingParameterVerification(Certificate, StoreType)
		
	CommonClientServer.CheckParameter(
		"CertificatesStorage.Add", 
		"Certificate",
		Certificate, 
		New TypeDescription("BinaryData, String"));
		
	CommonClientServer.CheckParameter(
		"CertificatesStorage.Add", 
		"StoreType",
		StoreType, 
		New TypeDescription("EnumRef.CertificatesStorageType"));
		
	If TypeOf(Certificate) = Type("String") Then
		CommonClientServer.Validate(
			IsTempStorageURL(Certificate),
			NStr("ru = 'Недопустимое значение параметра Сертификат (указан адрес, который не является адресом временного хранилища)';
				|en = 'Invalid value of the Certificate parameter (specified address is not a temporary storage address)';"), 
			"CertificatesStorage.Add");
	EndIf;
	
EndProcedure

#EndRegion