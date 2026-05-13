////////////////////////////////////////////////////////////////////////////////
// The "Cryptography service" subsystem.
//  
////////////////////////////////////////////////////////////////////////////////
//


#Region Public

// Encrypts data for the specified recipient list.
//
// Parameters:
//   Data - BinaryData, String, Array - one or several files to be encrypted.
//                                             Binary data or an address in a temporary storage of a data file
//                                     		   that needs to be encrypted.
//
//   Recipients - BinaryData - of certificate files 
//              - Structure, FixedStructure - Parameters to search for certificates in the storage.:
//			       * Thumbprint     - BinaryData, String - Certificate thumbprint,
//			       or
//				   * SerialNumber - BinaryData, String - Serial number of the certificate,
//			       * Issuer      - Structure, FixedStructure, String - Issuer properties, 
//			       or  
//			       * Certificate    - BinaryData - Certificate file.
//				- Array, FixedArray - Certificates of the encrypted message recipients.
//
//   EncryptionType - String - Encryption type. Only CMS supported.
//
//   EncryptionParameters - Structure, FixedStructure - allows to specify additional encryption parameters.
//
// Returns:
//	 BinaryData, String - Encrypted data. If data is passed using a temporary storage,
//                            the result will be returned the same way.
//
Function Encrypt(Data, Recipients, EncryptionType = "CMS", EncryptionParameters = Undefined) Export
	
	Try
		EncryptCheckIncomingParameters(
			Data, 
			Recipients, 
			EncryptionType, 
			EncryptionParameters);
			
		ReturnResultAsAddress = CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(Data);
		ReturnResultAsArray = TypeOf(Data) = Type("Array");
		Data = CryptographyServiceInternal.ExtractBinaryDataIfNecessary(Data);			
		
		If Not ReturnResultAsArray Then 
			Data = CommonClientServer.ValueInArray(Data);
		EndIf;
		
		MethodParameters = New Structure;
		MethodParameters.Insert("data", Data);
		MethodParameters.Insert("certificates", GetBinaryDataOfCertificates(Recipients));
		
		Result = ExecuteCryptoserviceMethod("crypto/encryptor", MethodParameters);
	Except
		Parameters = New Structure;
		Parameters.Insert("Data", Data);
		Parameters.Insert("Recipients", Recipients);
		Parameters.Insert("EncryptionType", EncryptionType);
		Parameters.Insert("EncryptionParameters", EncryptionParameters);
		
		WriteErrorToEventLog(EventNameEncryption(), ErrorInfo(), Parameters);
		Raise;
	EndTry;
	
	If ReturnResultAsAddress Then
		For IndexOf = 0 To Result.UBound() Do
			Result[IndexOf] = PutToTempStorage(Result[IndexOf], New UUID);
		EndDo;
	EndIf;
	If Not ReturnResultAsArray And Result.Count() = 1 Then
		Result = Result[0];
	EndIf;
	
	Return Result;
	
EndFunction

// Encrypts a data block for the recipient.
//
// Parameters:
//   Data - BinaryData, String - binary data or an address in a temporary storage of a data file
//                                     that needs to be encrypted.
//
//   Recipient - BinaryData - of certificate files 
//              - Structure, FixedStructure - Parameters to search for certificates in the storage.:
//				   * Thumbprint     - BinaryData, String - Certificate thumbprint,
//				   or
//				   * SerialNumber - BinaryData, String - Serial number of the certificate,
//				   * Issuer      - Structure, FixedStructure, String - Issuer properties,
//				   or
//				   * Certificate    - BinaryData - Certificate file.
//
// Returns:
//	 BinaryData, String - Encrypted data. If data is passed using a temporary storage,
//                            the result will be returned the same way.
//
Function EncryptBlock(Data, Recipient) Export
	
	Try
		EncryptCheckIncomingParametersBlock(
			Data, 
			Recipient);
			
		ReturnResultAsAddress = CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(Data);
		Data = CryptographyServiceInternal.ExtractBinaryDataIfNecessary(Data);			
	
		MethodParameters = New Structure;
		MethodParameters.Insert("certificate", GetBinaryCertificateData(Recipient));
		MethodParameters.Insert("data", Data);
				
		Result = ExecuteCryptoserviceMethod("crypto/encryptor_block", MethodParameters);
	Except
		Parameters = New Structure;
		Parameters.Insert("Data", Data);
		Parameters.Insert("Recipient", Recipient);
				
		WriteErrorToEventLog(EventNameBlockEncryption(), ErrorInfo(), Parameters);
		Raise;
	EndTry;
	
	Try
		Result.ephemeral_key = Base64Value(Result.ephemeral_key);
		Result.iv_data = Base64Value(Result.iv_data);
		Result.session_key = Base64Value(Result.session_key);	
	Except
		Parameters = New Structure;
		Parameters.Insert("Data", Data);
		Parameters.Insert("Recipient", Recipient);
				
		WriteErrorToEventLog(EventNameBlockEncryption(), ErrorInfo(), Parameters);
		Raise;
	EndTry;
	
	If ReturnResultAsAddress Then
		Result = PutToTempStorage(Result, New UUID);
	EndIf;

	Return Result;
	
EndFunction

// Decrypts data.
//
// Parameters:
//   EncryptedData - BinaryData, String - binary data or an address in a temporary storage of a data file
//                                                  that needs to be decrypted.
//
//   Certificate - Structure - a certificate to be used for decryption:
//     * Id - String - Certificate ID.
//
//   EncryptionType - String - only CMS is supported.
//
//   EncryptionParameters - Structure, FixedStructure - allows to specify additional encryption parameters:
//     * UseLongLastingSecurityToken - Boolean - If True, you can use a long-term security token for decryption.
//                                                           By default, False.
//
// Returns:
//	 BinaryData - Decrypted data.
//   String - Decrypted data if data is passed using a temporary storage.
//	 Structure - Runtime error details.:
//     * ReturnCode - String - error code.
//     * Id - String - Certificate ID.
//
Function Decrypt(EncryptedData, Certificate, EncryptionType = "CMS", EncryptionParameters = Undefined) Export

	Try
		DecryptCheckingIncomingParameters(
			EncryptedData, 
			EncryptionType, 
			EncryptionParameters);

		UseLongLastingSecurityToken = CommonClientServer.StructureProperty(
			EncryptionParameters, "UseLongLastingSecurityToken", False);

		SecurityTokens = SecurityTokens(Certificate.Id, UseLongLastingSecurityToken);

		If Not ValueIsFilled(SecurityTokens.SecurityToken)
			And Not ValueIsFilled(SecurityTokens.LongLastingSecurityToken) Then
			Return New Structure("ReturnCode, Id", "AuthenticationRequired", Certificate.Id);
		EndIf;

		ReturnResultAsAddress = CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(EncryptedData);
		
		MethodParameters = New Structure;
		MethodParameters.Insert("data", EncryptedData);
		MethodParameters.Insert("security_token", SecurityTokens.SecurityToken);
		MethodParameters.Insert("long_security_token", SecurityTokens.LongLastingSecurityToken);
		
		Result = ExecuteCryptoserviceMethod("crypto/decryptor", MethodParameters);
		
		If Not ValueIsFilled(Result) Then
			Raise(NStr("ru = 'Не удалось выполнить расшифровку сообщения';
									|en = 'Cannot decrypt a message';"));
		EndIf;
		
		If ReturnResultAsAddress Then
			Result = PutToTempStorage(Result, New UUID);
		EndIf;
		
		Return Result;
		
	Except
		ErrorInfo = ErrorInfo();
		ExceptionText = CloudTechnology.DetailedErrorText(ErrorInfo);
		If StrFind(ExceptionText, "InvalidSecurityTokenError") Then
			Return New Structure("ReturnCode, Id", "AuthenticationRequired", Certificate.Id);
		EndIf;
		
		Parameters = New Structure;
		Parameters.Insert("EncryptedData", EncryptedData);
		Parameters.Insert("Certificate", Certificate);
		Parameters.Insert("EncryptionType", EncryptionType);
		Parameters.Insert("EncryptionParameters", EncryptionParameters);
	
		WriteErrorToEventLog(EventNameDecryption(), ErrorInfo, Parameters);
		
		Raise;
	EndTry;
	
EndFunction

// Decrypts data by iterating over certificates from the cryptomessage.
//
// Parameters:
//   EncryptedData - BinaryData, String - binary data or an address in a temporary storage of a data file
//                                                  that needs to be decrypted.
//
//   EncryptionType - String - only CMS is supported.
//
//   EncryptionParameters - Structure, FixedStructure - The default value is False.
//     
//                                                           The default value is False.
//
// Returns:
//	 BinaryData, String - Decrypted data.
//                            If data is passed using a temporary storage, the result will be returned the same way.
//   Structure - Runtime error details.
//     * ReturnCode - String - Error code.
//     Decrypted data.
//     If data is passed using a temporary storage, the result will be returned the same way.
//     Structure - Runtime error details.
//     * ReturnCode - String - Error code.
//
Function DecryptByIteratingOverCertificates(EncryptedData, EncryptionType = "CMS", EncryptionParameters = Undefined) Export

	ReturnResultAsAddress = CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(EncryptedData);

	CryptoMessage = CryptographyServiceInternal.ExtractBinaryDataIfNecessary(EncryptedData);

	MessageProperties = GetCryptoMessageProperties(CryptoMessage, True);
	
	IDs = New Array;
	If MessageProperties.Type = "envelopedData" Then
		Recipients = MessageProperties.Recipients; // See GetCertificatePropertiesFromJson
		For Each Recipient In Recipients Do 
			If Recipient.Property("Id") Then 
				IDs.Add(Recipient.Id);
			EndIf;
		EndDo;
	Else
		Raise StrTemplate(NStr("ru = 'Недопустимое значение параметра %1 - файл не является криптосообщением';
										|en = 'Incorrect value of the %1 parameter. The file is not a crypto message';"),
			"EncryptedData");
	EndIf;
	
	If Not ValueIsFilled(IDs) Then
		Raise(NStr("ru = 'В хранилище отсутствуют сертификаты для расшифровки сообщения.';
								|en = 'There are no certificates for message decryption in storage.';"));
	EndIf;
	
	IDs = CryptographyServiceInternal.DetermineOrderOfCertificates(IDs);

	DecryptedData = Undefined;

	For Each CurrentID In IDs Do

		Try
			Certificate = New Structure("Id", CurrentID);
			DecryptedData = Decrypt(CryptoMessage, Certificate, EncryptionType, EncryptionParameters);
		Except
			// Disable logging. If the certificate is irrelevant,
			// and an error occurs, try the next certificate in the list.
		EndTry;

		If DecryptedData <> Undefined Then
			// If decryption is successful or an error that prevents from further execution occurred, stop iterating certificates.
			Break;
		EndIf;
		
	EndDo;
	
	If TypeOf(DecryptedData) = Type("Structure") Then
		// A special error of crypto service, stop execution and pass information about it to the calling method.
		Return DecryptedData;
	EndIf;
	
	If ReturnResultAsAddress Then
		DecryptedData = PutToTempStorage(DecryptedData, New UUID);
	EndIf;
	
	Return DecryptedData;

EndFunction

// Decrypts a data block.
//
// Parameters:
//   EncryptedData - BinaryData, String - binary data or an address in a temporary storage of a data file
//                                                  that needs to be decrypted.
//
//   Recipient - BinaryData - a certificate file of the encrypted message recipient
//              - Structure, FixedStructure - Parameters to search for certificates in the storage.:
//                 * Id - String - Certificate ID.
//
//   KeyInformation - Structure, FixedStructure - allows to pass data about the encryption key to the query:
//       * ephemeral_key - BinaryData, String - in base64, ephemeral key
//       * session_key - BinaryData, String - in base64, session key
//       * iv_data - BinaryData, String - in base64, initialization vector data
//
//   EncryptionParameters - Structure, FixedStructure - allows to specify additional encryption parameters.
//
// Returns:
//	 BinaryData - Decrypted data.
//	 String - Decrypted data if data is passed using a temporary storage.
//   Structure - Runtime error details.:
//     * ReturnCode - String - error code.
//     * Id - String - Certificate ID.
//
Function DecryptBlock(EncryptedData, Recipient, KeyInformation, EncryptionParameters = Undefined) Export
	
	Try
		DecryptCheckIncomingParametersBlock(
			EncryptedData, 
			Recipient,
			KeyInformation, 
			EncryptionParameters);
			
		UseLongLastingSecurityToken = CommonClientServer.StructureProperty(
			EncryptionParameters, "UseLongLastingSecurityToken", False);
			
		Certificate = FindCertificate(Recipient);
		If Not ValueIsFilled(Certificate) Then
			Raise(NStr("ru = 'Сертификат подписанта не найден в хранилище сертификатов.';
									|en = 'The signer certificate is not found in the certificate store.';"));
		EndIf;
		
		SecurityTokens = SecurityTokens(Certificate.Id, UseLongLastingSecurityToken);

		If Not ValueIsFilled(SecurityTokens.SecurityToken)
			And Not ValueIsFilled(SecurityTokens.LongLastingSecurityToken) Then
			Return New Structure("ReturnCode, Id", "AuthenticationRequired", Certificate.Id);
		EndIf;
						
		clear_padding = True;
		If ValueIsFilled(EncryptionParameters) Then 
			EncryptionParameters.Property("ClearPaddingBytes", clear_padding);
			clear_padding = ?(TypeOf(clear_padding) = Type("Boolean"), clear_padding, True);
		EndIf;		
		
		ReturnResultAsAddress = CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(EncryptedData);
		
		MethodParameters = New Structure;
		MethodParameters.Insert("security_token", SecurityTokens.SecurityToken);
		MethodParameters.Insert("long_security_token", SecurityTokens.LongLastingSecurityToken);
		MethodParameters.Insert("data", EncryptedData);
		MethodParameters.Insert("ephemeral_key", 
			CryptographyServiceInternal.BinaryDataInBase64IfNecessary(KeyInformation.ephemeral_key));
		MethodParameters.Insert("session_key", 
			CryptographyServiceInternal.BinaryDataInBase64IfNecessary(KeyInformation.session_key));
		MethodParameters.Insert("iv_data", 
			CryptographyServiceInternal.BinaryDataInBase64IfNecessary(KeyInformation.iv_data));
		MethodParameters.Insert("clear_padding", clear_padding);
		
		Result = ExecuteCryptoserviceMethod("crypto/decryptor_block", MethodParameters);
		
		If Not ValueIsFilled(Result) Then
			Raise(NStr("ru = 'Не удалось выполнить расшифровку блока данных';
									|en = 'Cannot decrypt data block';"));
		EndIf;
		
		If ReturnResultAsAddress Then
			Result = PutToTempStorage(Result, New UUID);
		EndIf;
		
		Return Result;
		
	Except
		ErrorInfo = ErrorInfo();
		ExceptionText = CloudTechnology.DetailedErrorText(ErrorInfo);
		If StrFind(ExceptionText, "InvalidSecurityTokenError") Then
			Return New Structure("ReturnCode, Id", "AuthenticationRequired", Recipient.Id);
		EndIf;
		
		Parameters = New Structure;
		Parameters.Insert("EncryptedData", EncryptedData);
		Parameters.Insert("Recipient", Recipient);
		Parameters.Insert("KeyInformation", KeyInformation);
		Parameters.Insert("EncryptionParameters", EncryptionParameters);
	
		WriteErrorToEventLog(EventNameBlockDecryption(), ErrorInfo, Parameters);
		
		Raise;
	EndTry;
	
EndFunction

// Signs data.
//
// Parameters:
//   Data - BinaryData, String, Array - one or several files to be signed. 
//                                             Binary data or an address in a temporary storage of a data file
//                                             that needs to be signed.
//
//   Signatory - BinaryData - of a file of the certificate to be signed. 
//             - Structure, FixedStructure - Certificate search parameters.
//		          * Thumbprint - BinaryData, String - Certificate thumbprint.
//		          Or:
//		          * SerialNumber - BinaryData, String - Certificate serial number.
//		          * Issuer - Structure, FixedStructure, String - Issuer properties.
//		          Or:
//		          * Certificate - BinaryData - Certificate file.
//
//   SignatureType - String - a signature type. Only "CMS" or "GOST3410" is supported.
//
//   SigningParameters - Structure, FixedStructure - allows to specify additional signing parameters:
//     * DisconnectedSignature - Boolean - Supports only CMS. If True, generates a disconnected signature.
//                                       Otherwise, generates a connected signature. By default, True.
//     * UseLongLastingSecurityToken - Boolean - If True, you can use a long-term security token for decryption.
//                                                           By default, False.
//
// Returns:
//	 BinaryData - Signature. 
//	 String - Signature if data is passed using a temporary storage.
//   Structure - Runtime error details.:
//     * ReturnCode - String - error code.
//     * Id - String - Certificate ID.
//
Function Sign(Data, Signatory, SignatureType = "CMS", SigningParameters = Undefined) Export

	SignCheckIncomingParameters(
		Data, 
		Signatory, 
		SignatureType, 
		SigningParameters);

	UseLongLastingSecurityToken = CommonClientServer.StructureProperty(
		SigningParameters, "UseLongLastingSecurityToken", False);
	
	Certificate = FindCertificate(Signatory);
	If Not ValueIsFilled(Certificate) Then
		Raise(NStr("ru = 'Сертификат подписанта не найден в хранилище сертификатов.';
								|en = 'The signer certificate is not found in the certificate store.';"));
	EndIf;
	
	SecurityTokens = SecurityTokens(Certificate.Id, UseLongLastingSecurityToken);
	
	If Not ValueIsFilled(SecurityTokens.SecurityToken)
		And Not ValueIsFilled(SecurityTokens.LongLastingSecurityToken) Then
		Return New Structure("ReturnCode, Id", "AuthenticationRequired", Certificate.Id);
	EndIf;
	
	ReturnResultAsAddress = CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(Data);
	ReturnResultAsArray = TypeOf(Data) = Type("Array");
		
	Try
		If ValueIsFilled(SigningParameters) 
			And SigningParameters.Property("DisconnectedSignature") Then
			DisconnectedSignature = SigningParameters.DisconnectedSignature;
		Else
			DisconnectedSignature = True;
		EndIf;
		
		If Not ReturnResultAsArray Then 
			Data = CommonClientServer.ValueInArray(Data);
		EndIf;
	
	    MethodParameters = New Structure;
		MethodParameters.Insert("security_token",      SecurityTokens.SecurityToken);
		MethodParameters.Insert("long_security_token", SecurityTokens.LongLastingSecurityToken);
		MethodParameters.Insert("data",                Data);
		MethodParameters.Insert("type",                SignatureType);
		MethodParameters.Insert("include_data",        Not DisconnectedSignature);
		
		Result = ExecuteCryptoserviceMethod("crypto/signature", MethodParameters);
		
		If ReturnResultAsAddress Then
			For IndexOf = 0 To Result.UBound() Do
				Result[IndexOf] = PutToTempStorage(Result[IndexOf], New UUID);
			EndDo;
		EndIf;
		If Not ReturnResultAsArray And Result.Count() = 1 Then
			Result = Result[0];
		EndIf;
		
		Return Result;
		
	Except
		ErrorInfo = ErrorInfo();
		ExceptionText = CloudTechnology.DetailedErrorText(ErrorInfo);
		If StrFind(ExceptionText, "InvalidSecurityTokenError") Then
			Return New Structure("ReturnCode, Id", "AuthenticationRequired", Certificate.Id);
		EndIf;
		
		Parameters = New Structure;
		Parameters.Insert("Data", Data);
		Parameters.Insert("Signatory", Signatory);
		Parameters.Insert("SignatureType", SignatureType);
		Parameters.Insert("SigningParameters", SigningParameters);
	
		WriteErrorToEventLog(EventNameSigning(), ErrorInfo, Parameters);
		
		Raise;
	EndTry;
	
EndFunction

// Checks the signature.
//
// Parameters:
//   Signature - BinaryData - a signature that needs to be checked.
//
//   Data - BinaryData - source data required for a signature check. It is used to check DisconnectedSignature.
//
//   SignatureType - String - a signature type. Only "CMS" or "GOST3410" is supported.
//
//   SigningParameters - Structure, FixedStructure - Allows specifying additional signature parameters.
//     * DisconnectedSignature - Boolean - Used when SignatureType = "CMS". If True, the signature will be checked using Data.
//                                       Allows specifying additional signature parameters.
//     * DisconnectedSignature - Boolean - Used when SignatureType = "CMS". If True, the signature will be checked using Data.
//
// Returns:
//	 Boolean - if True, the signature is valid.
//
Function VerifySignature(Signature, Data = Undefined, SignatureType = "CMS", SigningParameters = Undefined) Export
	
	CheckSignatureCheckingIncomingParameters(
		Signature, 
		Data, 
		SignatureType, 
		SigningParameters);
	
	Try
		MethodParameters = New Structure;
		MethodParameters.Insert("signature", Signature);
		MethodParameters.Insert("data", Data);
		MethodParameters.Insert("type", SignatureType);
		
		If SignatureType = "GOST3410" Then
			MethodParameters.Insert("certificate", SigningParameters.Certificate);
		EndIf;
		
		Return ExecuteCryptoserviceMethod("crypto/verification/signature", MethodParameters);
		
	Except
		
		Parameters = New Structure;
		Parameters.Insert("Data", Data);
		Parameters.Insert("Signature", Signature);
		Parameters.Insert("SignatureType", SignatureType);
		Parameters.Insert("SigningParameters", SigningParameters);
	
		WriteErrorToEventLog(EventNameSignatureVerification(), ErrorInfo(), Parameters);
		
		Raise;
	EndTry;
	
EndFunction

//  Calculates a hash sum by the passed data.
//
// Parameters:
//   Data - BinaryData, String - binary data or an address in a temporary storage of a file of data,
//                                     by which you need to calculate a hash sum.
//   HashAlgorithm - String - a constant from the list "GOST R 34.11-94", "GOST R 34.11-2012 256", "GOST R 34.11-2012 512".
//
//   HashingParameters - Structure, FixedStructure - For example, direct order is 62 FB and reverse order is 26 BF.
//     The default value is True.
//                                For example, direct order is 62 FB and reverse order is 26 BF.
//                                The default value is True.
//
// Returns:
//	 BinaryData - a hash sum value.
//
Function DataHashing(Data, HashAlgorithm = "GOST R 34.11-94", HashingParameters = Undefined) Export
	
	HashingDataCheckingIncomingParameters(
		Data, 
		HashAlgorithm, 
		HashingParameters);
	
	Try
		If ValueIsFilled(HashingParameters) 
			And HashingParameters.Property("InvertNibbles") Then
			InvertNibbles = HashingParameters.InvertNibbles;
		Else
			InvertNibbles = True;
		EndIf;
		
		MethodParameters = New Structure;
		MethodParameters.Insert("data", Data);
		MethodParameters.Insert("algorithm", HashAlgorithm);
		MethodParameters.Insert("inverted_halfbytes", InvertNibbles);
		
		Return ExecuteCryptoserviceMethod("crypto/hash", MethodParameters);
		
	Except
		ErrorInfo = ErrorInfo();
		
		Parameters = New Structure;
		Parameters.Insert("Data", Data);
		Parameters.Insert("HashAlgorithm", HashAlgorithm);
		Parameters.Insert("HashingParameters", HashingParameters);
	
		WriteErrorToEventLog(EventNameHashing(), ErrorInfo, Parameters);
		
		Raise;
	EndTry;
	
EndFunction

// Checks the certificate.
//
// Parameters:
//   Certificate - BinaryData - a certificate file.
//
// Returns:
//	 Boolean - if True, the certificate is valid.
//
Function CheckCertificate(Certificate) Export
	
	CheckCertificateCheckIncomingParameters(Certificate);
	
	Try
		MethodParameters = New Structure;
		MethodParameters.Insert("certificate", CertificatesStorage.DERCertificate(Certificate));
		
		Result = CryptographyServiceInternal.ExecuteCryptoserviceMethod("crypto/verification/certificate", MethodParameters);
		
		Return Result;
	Except
		Parameters = New Structure("Certificate", Certificate);
		CryptographyServiceInternal.WriteErrorToEventLog(NameOfCertificateVerificationEvent(), ErrorInfo(), Parameters);
		
		Raise;
	EndTry;
	
	Return Undefined;
		
EndFunction

// Checks a certificate with additional parameters.
//
// Parameters:
//   Certificate - BinaryData - Certificate file.
//   CheckParameters - Structure - "IgnoreSignatureValidity",
//		"IgnoreCertificateRevocationStatus",
//                                   "AllowTestCertificates"
//												"IgnoreSignatureValidity", 
//												"IgnoreCertificateRevocationStatus",
//												"AllowTestCertificates"
//
// Returns:
//	 Boolean - if True, the certificate is valid.
//
Function VerifyCertificateWithParameters(Certificate, CheckParameters) Export
	
	CheckCertificateCheckIncomingParameters(Certificate);
	
	Try
		MethodParameters = New Structure;
		MethodParameters.Insert("certificate", CertificatesStorage.DERCertificate(Certificate));
		
		CertificateVerificationMode = CommonClientServer.StructureProperty(CheckParameters, "CertificateVerificationMode", "");
		If ValueIsFilled(CertificateVerificationMode) Then
			MethodParameters.Insert("mode", PrepareCertificateVerificationModes(CertificateVerificationMode));
		EndIf;
		
		Result = CryptographyServiceInternal.ExecuteCryptoserviceMethod("crypto/verification/certificate", MethodParameters);
		
		Return Result;
	Except
		Parameters = New Structure("Certificate", Certificate);
		CryptographyServiceInternal.WriteErrorToEventLog(NameOfCertificateVerificationEvent(), ErrorInfo(), Parameters);
		
		Raise;
	EndTry;
	
	Return Undefined;
		
EndFunction

// Gets main properties of the passed certificate.
// 
// Parameters:
//   Certificate - BinaryData - a certificate whose properties you need to get.
//
// Returns:
//	 FixedStructure - Certificate properties.:
//    * Version - String - a certificate version.
//    * StartDate - Date - a start date of a certificate (UTC).
//    * EndDate - Date - a certificate end date (UTC).
//    * Issuer - FixedStructure - Issuer information:
//        ** CN - String - commonName 
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
//        ** OGRNIP - String - Registration number of IE
//        ** INN - String - TIN (optional).
//        ** INNLE - String - Legal entity's TIN (optional).
//        ** SNILS - String - SNILS;
//           …
//    * UseToSign - Boolean - indicates whether this certificate can be used for signing.
//    * UseToEncrypt - Boolean - indicates whether this certificate can be used for encryption.
//    * PublicKey - BinaryData - Contains public key data.
//    * Thumbprint - BinaryData - Contains thumbprint data. It is calculated dynamically using the SHA-1 algorithm.
//    * Extensions - FixedStructure -  extended certificate properties:
//        ** EKU - FixedArray of Arbitrary - Enhanced Key Usage.
//    * SerialNumber - BinaryData - a serial number of a certificate.
//    * Subject - FixedStructure - Certificate subject information. For content, see Issuer.:
//        ** CN - String - commonName ...
//    * Certificate - BinaryData - Certificate file in the DER encoding.
//    * Id - String - Calculated from key Issuer properties and a serial number using the SHA1 algorithm.
//                               Used to identify a certificate in the crypto service.
//
Function GetCertificateProperties(Certificate) Export
	
	GetCertificatePropertiesCheckIncomingParameters(Certificate);
	
	Try
		DERCertificate = CertificatesStorage.DERCertificate(Certificate);
		
		MethodParameters = New Structure;
		MethodParameters.Insert("certificate", DERCertificate);
		
		Result = CryptographyServiceInternal.ExecuteCryptoserviceMethod("crypto/certificate", MethodParameters);
		
		Properties = New Structure;
		Properties.Insert("Version"                   , StrTemplate("V%1", Result.version + 1));
		Properties.Insert("StartDate"            	 , XMLValue(Type("Date"), Left(Result.valid_from, 19)));
		Properties.Insert("EndDate"            , XMLValue(Type("Date"), Left(Result.valid_to, 19)));
		Properties.Insert("Issuer"                 , ConvertOID(Result.issuer));
		Properties.Insert("UseToSign"   , Result.use_to_sign);
		Properties.Insert("UseToEncrypt", Result.use_to_encrypt);
		Properties.Insert("PublicKey"             , Result.public_key);
		Properties.Insert("Thumbprint"                , Result.thumbprint);
		Properties.Insert("Extensions"      , ExtendedCertificateProperties(Result.extensions));
		Properties.Insert("SerialNumber"            , Result.serial_number);
		Properties.Insert("Subject"                  , ConvertOID(Result.subject));
		Properties.Insert("Description"             , CertificateDescription(Result.subject));
		Properties.Insert("Certificate"               , DERCertificate);
		Properties.Insert("Id"            , CalculateJSONCertificateID(Result));
		
		Return New FixedStructure(Properties);
	
	Except
		Parameters = New Structure("Certificate", Certificate);
		CryptographyServiceInternal.WriteErrorToEventLog(NameOfCertificatePropertyEvent(), ErrorInfo(), Parameters);
		
		Raise;
	EndTry;
		
EndFunction

// Extracts a certificate array from the signature data.
//
// Parameters:
//   Signature - BinaryData - a signature file.
//
// Returns:
//	 Array of FixedStructure - Has the following certificate properties:
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
//        ** INN - String - TIN;
//        ** INNLE - String - Legal entity's TIN (optional).
//        ** SNILS - String - SNILS;
//    * SerialNumber - BinaryData - a serial number of a certificate.
//    * Certificate - BinaryData - Certificate file in the DER encoding.
//    * Id - String - Calculated from key Issuer properties and a serial number using the SHA1 algorithm.
//                               Used to identify a certificate in the crypto service.
//
Function GetCertificatesFromSignature(Signature) Export
	
	GetCertificatesFromSigningCheckIncomingParameters(Signature);
	
	If TypeOf(Signature) = Type("String") Then
		Signature = GetFromTempStorage(Signature);
	EndIf;
	
	CryptoMessageProperties = GetCryptoMessageProperties(Signature);
	If CryptoMessageProperties.Type = "signedData" Then
		Return CryptoMessageProperties.Certificates;	
	Else
		Raise(NStr("ru = 'Параметр <Подпись> не является файлом подписи';
								|en = 'The <Signature> parameter is not a signature file';"));
	EndIf;
	
EndFunction

// Extracts properties from a crypto message file.
//
// Parameters:
//   CryptoMessage - BinaryData, String - binary data or an address in the temporary storage of crypto message file.
//   OnlyKeyProperties - Boolean - if True, Content will always be returned blank.
//
// Returns:
// 	Structure - Properties of a crypto message:
// 	 * Size - Number - File size in bytes.
// 	 * Type - String - specifies a message type: envelopedData, signedData, unknown.
// 	 * Recipients - FixedArray of Structure - Details of encrypted message recipient certificates. Applicable if Type="envelopedData":
//   	** Id - String - Calculated from key Issuer properties and a serial number using the SHA1 algorithm. 
//   								For other fields See GetCertificateProperties.
// 	 * Signatories - FixedArray of Structure - Details of encrypted message recipient certificates. Applicable if Type="signedData":
// 	    ** Id - String - Calculated from key Issuer properties and a serial number using the SHA1 algorithm.
//   								For other fields See GetCertificateProperties.
// 	 * Content - BinaryData - crypto message content.
//
Function GetCryptoMessageProperties(CryptoMessage, OnlyKeyProperties = False) Export
	
	CryptoMessageProperties = New Structure;
	CryptoMessageProperties.Insert("Type", "unknown");
	
	Try
		GetPropertiesOfCryptographicMessageCheckingIncomingParameters(CryptoMessage);
		
		CryptoMessageProperties.Insert("Size", CryptoMessage.Size());
		
		MethodParameters = New Structure;
		MethodParameters.Insert("message", CryptoMessage);
		
		Result = CryptographyServiceInternal.ExecuteCryptoserviceMethod("crypto/crypto_message", MethodParameters);
		
		CryptoMessageProperties.Insert("Type", Result.type);	
		
		Recipients = GetCertificatePropertiesFromJson(Result.recipient_infos);
		CryptoMessageProperties.Insert("Recipients", New FixedArray(Recipients));
		
		Signatories = GetCertificatePropertiesFromJson(Result.signer_infos);
		CryptoMessageProperties.Insert("Signatories", New FixedArray(Signatories));			
		
		If Not OnlyKeyProperties Then
			Certificates = New Array;
			For Each certificate In Result.certificates Do
				Certificates.Add(certificate);		
			EndDo;
			CryptoMessageProperties.Insert("Certificates", New FixedArray(Certificates));
			If Not ValueIsFilled(Result.content) Then
				Result.content = Base64Value("");
			EndIf;
			
			CryptoMessageProperties.Insert("Content", Result.content);
		EndIf;
	Except
		CryptographyServiceInternal.WriteErrorToEventLog(EventNamePropertiesOfCryptoMessage(), ErrorInfo(), CryptoMessageProperties);
	EndTry;
	
	Return CryptoMessageProperties;
	
EndFunction

// Gets possible methods of delivering temporary passwords.
//
// Parameters:
//   CertificateID - String - a certificate ID, for which it is required to get methods of password delivery.
//
// Returns:
//   Structure - Contains the following keys:
//     * Phone          - String - a masked presentation of a phone for receiving temporary passwords in text messages.
//     * Email - String - a masked presentation of an email for receiving temporary passwords in emails.
//
Function GetSettingsForGettingTemporaryPasswords(CertificateID) Export
	
	Try
		MethodParameters = New Structure;
		MethodParameters.Insert("certificate_id", CertificateID);
		
		Result = CryptographyServiceInternal.ExecuteCryptoserviceMethod("crypto/auth_parameters", MethodParameters);
		
		WaysToDeliverPasswords = New Structure("Phone,Email", "", "");
		For Each ResultItem In Result Do 
			If ResultItem.type = "phone" Then
				WaysToDeliverPasswords.Phone = ResultItem.value;
			ElsIf ResultItem.type = "email" Then
				WaysToDeliverPasswords.Email = ResultItem.value;
			EndIf;	
		EndDo;
		
		Return WaysToDeliverPasswords;
	Except
		Parameters = New Structure("CertificateID", CertificateID);
		CryptographyServiceInternal.WriteErrorToEventLog(EventNameAuthentication(), ErrorInfo(), Parameters);
		
		Raise;
	EndTry;
	
EndFunction

// Requests sending a temporary password from the crypto service.
//
// Parameters:
//	CertificateID - String - ID of the certificate that needs a temporary password.
//	Resending - Boolean - If True, the query is repeated.
//	PasswordsDeliveryMethod - String - Either phone or email.
//	SessionID - String - a session ID
//
// Returns:
//	Structure - Contains the following keys:
//		* DelayBeforeResending - Number - Timeout before the next password request.
//		* PasswordValidityPeriod - Number - Password validity period in seconds.
//		* SessionID - String - if there is "session_id".
//
Function GetTemporaryPassword(CertificateID, Resending, PasswordsDeliveryMethod, SessionID = Undefined) Export

	ExecutionResult = New Structure();
	ExecutionResult.Insert("DelayBeforeResending", 0);
	ExecutionResult.Insert("PasswordValidityPeriod",             0);

	MethodParameters = New Structure;
	MethodParameters.Insert("certificate_id", CertificateID);
	MethodParameters.Insert("repeat",         Resending);
	MethodParameters.Insert("type",           PasswordsDeliveryMethod);
	
	If ValueIsFilled(SessionID) Then
		Headers = New Map;
		Headers.Insert("X-Auth-Session", SessionID);
	Else
		Headers = Undefined;
	EndIf;		
		
	Try

		GetTemporaryPasswordCheckIncomingParameters(CertificateID, Resending, PasswordsDeliveryMethod);
		
		Result = CryptographyServiceInternal.ExecuteCryptoserviceMethod("crypto/password", MethodParameters, Headers);
		
		ExecutionResult.DelayBeforeResending = Result.delay;
		ExecutionResult.PasswordValidityPeriod             = Result.life_time;
		
		If Result.Property("session_id") Then 
			ExecutionResult.Insert("SessionID", Result.session_id);
		EndIf;
		
	Except
		
		CryptographyServiceInternal.WriteErrorToEventLog(EventNameAuthentication(), ErrorInfo(), MethodParameters);
		Raise;
	
	EndTry;
	
	Return ExecutionResult;

EndFunction

// Sends a temporary password received earlier to the crypto service and requests security tokens for it.
//
// Parameters:
//	CertificateID - String - ID of the certificate to be used for signing.
//	TemporaryPassword - String - Temporary password sent by the crypto service.
//
Procedure ConfirmTemporaryPassword(CertificateID, TemporaryPassword) Export

	CryptographyServiceInternal.ConfirmTemporaryPassword(CertificateID, TemporaryPassword);

EndProcedure

// Attempts to receive the previously saved security tokens: session and long-term
//
// Parameters:
//	CertificateID - String - ID of the certificate used for signing.
//	UseLongLastingSecurityToken - Boolean - indicates that a long-term token is searched for.
//	
// Returns:
//	Structure - Token.:
//   * SecurityToken - String
//   * LongLastingSecurityToken - String
Function SecurityTokens(CertificateID, UseLongLastingSecurityToken) Export

	Result = New Structure();
	Result.Insert("SecurityToken");
	Result.Insert("LongLastingSecurityToken");
	
	SetPrivilegedMode(True);
	Result.SecurityToken = SessionParameters.SecurityTokens.Get(CertificateID);
	
	If UseLongLastingSecurityToken Then 
		Result.LongLastingSecurityToken = Common.ReadDataFromSecureStorage(
			CryptographyServiceInternal.ConfigurationNameAndCertificateSecurityToken(CertificateID),
			"LongLastingSecurityToken",
			False);
	EndIf;
	
	SetPrivilegedMode(False);
	
	// Replacing blank values with blank strings to pass to the crypto service.
	If Not ValueIsFilled(Result.SecurityToken) Then
		Result.SecurityToken = "";
	EndIf;
	
	If Not ValueIsFilled(Result.LongLastingSecurityToken) Then
		Result.LongLastingSecurityToken = "";
	EndIf;
	
	Return Result;

EndFunction

#EndRegion

#Region Private

Function SoftwareInterfaceVersion()
	
	Return "v3.1";
	
EndFunction

Function ClientName()
	
	Return StrTemplate("%1 (%2):%3", Metadata.Name, Metadata.Version, Format(SaaSOperations.SessionSeparatorValue(), "NG="));
	
EndFunction

Function GetPropertyNamesToRestore(Method)
	
	PropertiesForConversion = New Array;
	If StrSplit("crypto/hash", ",").Find(Method) <> Undefined Then
		PropertiesForConversion.Add("data");
	ElsIf Method = "crypto/certificate" Then
		PropertiesForConversion.Add("public_key");
		PropertiesForConversion.Add("thumbprint");
		PropertiesForConversion.Add("serial_number");
	ElsIf Method = "crypto/crypto_message" Then
		PropertiesForConversion.Add("certificates");
		PropertiesForConversion.Add("serial_number");
	EndIf;
	
	Return PropertiesForConversion;
	
EndFunction

Function FindCertificate(Certificate)
	
	CertificateProperties = Undefined;
	If TypeOf(Certificate) = Type("BinaryData") Then
		CertificateProperties = GetCertificateProperties(Certificate);
	ElsIf (TypeOf(Certificate) = Type("Structure")
		Or  TypeOf(Certificate) = Type("FixedStructure"))
		And Certificate.Property("Certificate") Then
		CertificateProperties = GetCertificateProperties(Certificate.Certificate);
	Else
		CertificateProperties = CertificatesStorage.FindCertificate(Certificate);
	EndIf;
	
	Return CertificateProperties;
	
EndFunction

Function GetBinaryCertificateData(Certificate)
	
	CertificateBinaryData = Undefined;
	
	If TypeOf(Certificate) = Type("BinaryData") Then
		CertificateBinaryData = CertificatesStorage.DERCertificate(Certificate);
	ElsIf (TypeOf(Certificate) = Type("Structure") Or TypeOf(Certificate) = Type("FixedStructure"))
		And Certificate.Property("Certificate") Then
		CertificateBinaryData = CertificatesStorage.DERCertificate(Certificate.Certificate);
	Else
		CertificateBinaryData = CertificatesStorage.FindCertificate(Certificate).Certificate;
	EndIf;
	
	If Not ValueIsFilled(CertificateBinaryData) Then
		Raise(NStr("ru = 'Не удалось извлечь двоичные данные сертификата';
								|en = 'Cannot extract binary certificate data.';"));
	EndIf;
	
	Return CertificateBinaryData;
	
EndFunction

Function GetBinaryDataOfCertificates(Certificates)
	
	BinaryCertificateData = New Array;
	
	If TypeOf(Certificates) = Type("Array") Or TypeOf(Certificates) = Type("FixedArray") Then
		CertificatesArray = Certificates;
	Else
		CertificatesArray = New Array;
		CertificatesArray.Add(Certificates);
	EndIf;
	
	For Each Certificate In CertificatesArray Do 
		BinaryCertificateData.Add(GetBinaryCertificateData(Certificate));	
	EndDo;
	
	Return BinaryCertificateData;
	
EndFunction

// Execute the cryptography service method.
// 
// Parameters: 
//  Method - String
//  MethodParameters - Structure:
//   * session_key - String
//   * ephemeral_key - String
//   * data - BinaryData
//          - String
// 
// Returns:
//  Arbitrary
Function ExecuteCryptoserviceMethod(Method, MethodParameters) Export
	
	SetPrivilegedMode(True);
	ServiceAddress = Constants.CryptoServiceAddress.Get();
	SetPrivilegedMode(False);
	
	ConnectionParameters = CryptographyServiceManager.GetConnectionParameters(ServiceAddress);
	Join = DigitalSignatureSaaS.ConnectingToInternetServer(ConnectionParameters);
	
	UploadDataForProcessingToServer(Join, MethodParameters);
	
	Result = ExecuteServiceMethod(Join, Method, MethodParameters);
	
	DownloadProcessingResultFromServer(Join, Result);
	
	Return Result;
			
EndFunction

Procedure UploadDataForProcessingToServer(Join, MethodParameters)
	
	For Each Parameter In MethodParameters Do
		If TypeOf(Parameter.Value) = Type("BinaryData") Then
			MethodParameters.Insert(Parameter.Key, SendFileToServer(Join, Parameter.Value)); 
		ElsIf TypeOf(Parameter.Value) = Type("Array") Then
			For IndexOf = 0 To Parameter.Value.UBound() Do
				Parameter.Value[IndexOf] = SendFileToServer(Join, Parameter.Value[IndexOf]);				
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

Function ResourceAddress(Method)
	
	Return StrTemplate("/api/%1/%2", SoftwareInterfaceVersion(), Method);
	
EndFunction

Function CallHTTPMethod(Join, Method_HTTP, Query)
	
	Try		
		Response = Join.CallHTTPMethod(Method_HTTP, Query);
	Except
		// @skip-check module-nstr-camelcase - Check error.
		WriteLogEvent(
			NStr("ru = 'Электронная подпись в модели сервиса.Сервис криптографии.Выполнение запроса';
				|en = 'Digital signature SaaS.Cryptography service.Query execution';", Common.DefaultLanguageCode()), 
			EventLogLevel.Error,,,
			CommentOnException(
				DetailErrorDescription(ErrorInfo()),
				New Structure("ResourceAddress", Query.ResourceAddress)));	 
		
		DigitalSignatureSaaS.RaiseStandardException();
	EndTry;

	Return Response;
	
EndFunction

// Parameters: 
//  Join - HTTPConnection
//  Method - String
//  MethodParameters - Structure:
// * ephemeral_key - String
// * data - BinaryData
// 		  - String
// 
// Returns: 
//  Arbitrary -Execute the service method.
Function ExecuteServiceMethod(Join, Method, MethodParameters)
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/json");
	MethodParameters.Insert("client", ClientName());
	Query = New HTTPRequest(ResourceAddress(Method), Headers);
	Query.SetBodyFromString(
		DigitalSignatureSaaS.StructureInJSON(MethodParameters),,
		ByteOrderMarkUse.DontUse);
	
	Response = CallHTTPMethod(Join, "POST", Query);
	
	If Response.StatusCode <> 200 And Response.StatusCode <> 400 Then
		LogErroneousResponseFromService(Query.ResourceAddress, Response.GetBodyAsString());
	EndIf;
		
	ConversionParameters = New Structure;
	If Response.StatusCode = 200 Then
		ConversionParameters.Insert("PropertiesToReviveNames", GetPropertyNamesToRestore(Method));
	EndIf;
			
	Result = DigitalSignatureSaaS.JSONToStructure(Response.GetBodyAsString(), ConversionParameters);
	
	If Result.status = "success" Then		
		Return Result.data;
	ElsIf Result.status = "fail" Then
		Raise(Result.data);
	EndIf;

EndFunction

Procedure WriteErrorToEventLog(EventName, ErrorInfo, Parameters) Export
	
	Comment = CommentOnException(DetailErrorDescription(ErrorInfo), Parameters);
	WriteLogEvent(EventName, EventLogLevel.Error,,, Comment);
	
EndProcedure

Function CommentOnException(ErrorPresentation, Parameters)
	
	RecordTemplate = 
	"Parameters:
	|%1
	|
	|ErrorPresentation:
	|%2";
	
	Return StrTemplate(
		RecordTemplate, 
		DigitalSignatureSaaS.StructureInJSON(Parameters, New Structure("ReplaceBinaryData", True)),
		TrimAll(ErrorPresentation));
		
	EndFunction
	
Procedure LogErroneousResponseFromService(ResourceAddress, ServerResponse1)
	
	// @skip-check module-nstr-camelcase - Check error.
	WriteLogEvent(
		NStr("ru = 'Электронная подпись в модели сервиса.Сервис криптографии.Выполнение запроса';
			|en = 'Digital signature SaaS.Cryptography service.Query execution';", Common.DefaultLanguageCode()), 
		EventLogLevel.Error,,,
		CommentOnException(ServerResponse1, New Structure("ResourceAddress", ResourceAddress)));	 
	
	DigitalSignatureSaaS.RaiseStandardException();
	
EndProcedure

Function SendFileToServer(Join, File)
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/octet-stream");
	Query = New HTTPRequest("/upload", Headers);
	Query.SetBodyFromBinaryData(File);
	
	Response = CallHTTPMethod(Join, "PUT", Query);
	
	If Response.StatusCode <> 201 Then
		LogErroneousResponseFromService(Query.ResourceAddress, Response.GetBodyAsString());
	EndIf;
	
	FileName = CommonCTL.HTTPHeader(Response, "X-New-Name");

	Return FileName;
	
EndFunction

Function GetFileFromServer(Join, FileName)
		
	Headers = New Map;
	Query = New HTTPRequest("/download/" + FileName, Headers);
	
	Response = CallHTTPMethod(Join, "GET", Query);
	
	If Response.StatusCode <> 200 Then
		LogErroneousResponseFromService(Query.ResourceAddress, Response.GetBodyAsString());
	EndIf;
	
	File = Response.GetBodyAsBinaryData();

	Return File;
	
EndFunction

Procedure DownloadProcessingResultFromServer(Join, Parameters)
	
	If TypeOf(Parameters) = Type("Array") Then
		For IndexOf = 0 To Parameters.UBound() Do
			If TypeOf(Parameters[IndexOf]) = Type("String") And StrFind(Parameters[IndexOf], "out_") Then
				Parameters[IndexOf] = GetFileFromServer(Join, Parameters[IndexOf]);
			Else
				DownloadProcessingResultFromServer(Join, Parameters[IndexOf]);
			EndIf;
		EndDo;
	ElsIf TypeOf(Parameters) = Type("Structure") Then
		For Each Parameter In Parameters Do
			If TypeOf(Parameter.Value) = Type("String") And StrFind(Parameter.Value, "out_") Then
				Parameters.Insert(Parameter.Key, GetFileFromServer(Join, Parameter.Value));
			Else
				DownloadProcessingResultFromServer(Join, Parameter.Value);
			EndIf;
		EndDo; 
	ElsIf TypeOf(Parameters) = Type("String") And StrFind(Parameters, "out_") Then
		Parameters = GetFileFromServer(Join, Parameters);
	EndIf;
		
EndProcedure

Function ConvertOID(ListOfOIDs)
	
	Properties = New Structure;
	For Each RDN In ListOfOIDs Do
		Properties.Insert(GetNameByOID(RDN.OID), RDN.Value);
	EndDo;
	
	Return New FixedStructure(Properties);
	
EndFunction

Function ExtendedCertificateProperties(ListOfOIDs)
	
	EKU = New Array;
	For Each OID In ListOfOIDs Do
		Name = GetNameByOID(OID, "");
		If ValueIsFilled(Name) Then
			EKU.Add(StrTemplate("%1 (%2)", Name, OID));
		Else
			EKU.Add(OID);
		EndIf;
	EndDo;

	EKU = New FixedArray(EKU);
	
	Return New FixedStructure(New Structure("EKU", EKU));
	
EndFunction

// Returns certificate properties.
// 
// Parameters:
// 	ListOfSerialNumberPublisherPairs - FixedArray of Structure - Issuer data.
// Returns:
// 	Array of FixedStructure - Details.:
//	* SerialNumber - String - 
//	* Issuer - String - 
//	* Id - String - 
Function GetCertificatePropertiesFromJson(ListOfSerialNumberPublisherPairs) Export
	
	Certificates = New Array;
	
	For Each Pair In ListOfSerialNumberPublisherPairs Do
		Certificate = New Structure;
		Certificate.Insert("SerialNumber", Pair.serial_number);
		Certificate.Insert("Issuer", ConvertOID(Pair.issuer));
		If Pair.Property("certificate_id") Then
			Certificate.Insert("Id", (Pair.certificate_id));
		EndIf;
		
		Certificates.Add(New FixedStructure(Certificate));
	EndDo;
	
	Return Certificates;

EndFunction

Function GetNameByOID(OID, DefaultName = Undefined)
	
	Name = MatchingOIDName().Get(OID);
	If Name = Undefined Then
		If DefaultName <> Undefined Then
			Name = DefaultName;
		Else
			Name = "_" + StrReplace(OID, ".", "_");
		EndIf;
	EndIf;
	
	Return Name;
	
EndFunction

// Prepares the map between names and OID.
//
// Returns:
//	Map
//
Function MatchingOIDName()
	
	OIDMap = New Map;
	OIDMap.Insert("2.5.4.3", "CN"); // commonName
	OIDMap.Insert("2.5.4.6", "C"); // countryName
	OIDMap.Insert("2.5.4.8", "ST"); // stateOrProvinceName
	OIDMap.Insert("2.5.4.7", "L"); // localityName
	OIDMap.Insert("2.5.4.9", "STREET"); // streetAddress
	OIDMap.Insert("2.5.4.10", "O"); // organizationName
	OIDMap.Insert("2.5.4.11", "OU"); // organizationUnitName
	OIDMap.Insert("2.5.4.12", "T"); // title
	OIDMap.Insert("1.2.643.100.1", "OGRN"); // Registration number
	OIDMap.Insert("1.2.643.100.5", "OGRNIP"); // Registration number of IE
	OIDMap.Insert("1.2.643.100.3", "SNILS"); // SNILS
	OIDMap.Insert("1.2.643.3.131.1.1", "INN"); // TIN
	OIDMap.Insert("1.2.643.100.4", "INNLE"); // Legal entity's TIN
	OIDMap.Insert("1.2.840.113549.1.9.1", "E"); // emailAddress	
	OIDMap.Insert("2.5.4.4", "SN"); // surname
	OIDMap.Insert("2.5.4.42", "GN"); // givenName
	
	Return OIDMap;
	
EndFunction

Function MatchingOIDName_()
	
	OIDMap = New Map;
	OIDMap.Insert("CN", "2.5.4.3"); // commonName
	OIDMap.Insert("C", "2.5.4.6"); // countryName
	OIDMap.Insert("ST", "2.5.4.8"); // stateOrProvinceName
	OIDMap.Insert("L", "2.5.4.7"); // localityName
	OIDMap.Insert("STREET", "2.5.4.9"); // streetAddress
	OIDMap.Insert("O", "2.5.4.10"); // organizationName
	OIDMap.Insert("OU", "2.5.4.11"); // organizationUnitName
	OIDMap.Insert("T", "2.5.4.12"); // title
	OIDMap.Insert("OGRN", "1.2.643.100.1"); // Registration number
	OIDMap.Insert("OGRNIP", "1.2.643.100.5"); // Registration number of IE
	OIDMap.Insert("SNILS", "1.2.643.100.3"); // SNILS
	OIDMap.Insert("INN", "1.2.643.3.131.1.1"); // TIN
	OIDMap.Insert("INNLE", "1.2.643.100.4"); // Legal entity's TIN
	OIDMap.Insert("E", "1.2.840.113549.1.9.1"); // emailAddress	
	OIDMap.Insert("SN", "2.5.4.4"); // surname
	OIDMap.Insert("GN", "2.5.4.42"); // givenName
	
	Return OIDMap;
	
EndFunction

// Computes and returns the certificate ID.
// 
// Parameters: 
//  SerialNumber - String
//  Issuer - ValueList of String
// 
// Returns:
//  String
Function CalculateCertificateID(SerialNumber, Issuer) Export
	
	MatchingOIDName_ = MatchingOIDName_();
	For Each Item In Issuer Do
		If MatchingOIDName_.Get(Item.Presentation) <> Undefined Then
			Item.Presentation = MatchingOIDName_.Get(Item.Presentation);
		EndIf;
	EndDo;
	
	Return CertificateID(SerialNumber, Issuer);
	
EndFunction

Function CertificateID(SerialNumber, ListOfOIDs)
	
	Keys = StrSplit("2.5.4.3,2.5.4.4,2.5.4.6,2.5.4.7,2.5.4.8,2.5.4.10,2.5.4.11,2.5.4.12,2.5.4.42,1.2.840.113549.1.9.1", ",");
	Properties = New ValueList;
	For Each Item In ListOfOIDs Do
		If Keys.Find(Item.Presentation) <> Undefined Then
			Properties.Add(Item.Value, Item.Presentation);
		EndIf;
	EndDo;
	
	SerialNumberString = Lower(StrReplace(SerialNumber, " ", ""));
	
	Properties.SortByPresentation(SortDirection.Asc);
	
	ArrayOfValues = Properties.UnloadValues();
	
	ArrayOfValues.Add(SerialNumberString);
	
	CertificateAuthorityAndSerialNumber = StrConcat(ArrayOfValues, "#");
	
	Hashing = New DataHashing(HashFunction.SHA1);
	Hashing.Append(CertificateAuthorityAndSerialNumber);
	
	Return Lower(StrReplace(Hashing.HashSum, " ", ""));	
	
EndFunction

Function CalculateJSONCertificateID(CertificateProperties)
	
	Properties = New ValueList;
	For Each RDN In CertificateProperties.issuer Do
		Properties.Add(RDN.value, RDN.oid);
	EndDo;
	
	Return CertificateID(CertificateProperties.serial_number, Properties)
	
EndFunction

Function PrepareCertificateVerificationModes(CertificateCheckModes)
	
	RowsArray = StrSplit(CertificateCheckModes, ",", False);
	ArrayOfModes = New Array;
	For Each ArrayRow In RowsArray Do
		CurrentValue = Lower(TrimAll(ArrayRow));
		NewValue = "";
		If CurrentValue = Lower("IgnoreTimeValidity") Then
			NewValue = "IgnoreTimeValidity";
		ElsIf CurrentValue = Lower("IgnoreSignatureValidity") Then
			NewValue = "IgnoreSignatureValidity";
		ElsIf CurrentValue = Lower("IgnoreCertificateRevocationStatus") Then
			NewValue = "IgnoreCertificateRevocationStatus";
		ElsIf CurrentValue = Lower("AllowTestCertificates") Then
			NewValue = "AllowTestCertificates";
		Else
			NewValue = TrimAll(ArrayRow);
		EndIf;
		
		If ValueIsFilled(NewValue) Then
			ArrayOfModes.Add(NewValue);
		EndIf;
		
	EndDo;
	
	Result = StrConcat(ArrayOfModes, ",");
	
	Return Result;
	
EndFunction

#Region CheckingInputParameters

Procedure EncryptCheckIncomingParameters(Data, Recipients, EncryptionType, EncryptionParameters)

	CommonClientServer.CheckParameter(
		"CryptographyService.Encrypt", 
		"Data",
		Data, 
		New TypeDescription("BinaryData, Array, String"));
	
	CommonClientServer.CheckParameter(
		"CryptographyService.Encrypt", 
		"Recipients",
		Recipients, 
		New TypeDescription("BinaryData, Structure, FixedStructure, Array, FixedArray"));
	
	CommonClientServer.CheckParameter(
		"CryptographyService.Encrypt", 
		"EncryptionType",
		EncryptionType, 
		New TypeDescription("String"));
	
	CommonClientServer.Validate(
		EncryptionType = "CMS",
		StrTemplate(NStr("ru = 'Недопустимое значение параметра %1 (неизвестный тип шифрования)';
						|en = 'Incorrect value of the %1 parameter (unknown encryption type)';"),
			"EncryptionType"),
		"CryptographyService.Encrypt");
	
	If ValueIsFilled(EncryptionParameters) Then
		CommonClientServer.CheckParameter(
			"CryptographyService.Encrypt", 
			"EncryptionParameters",
			EncryptionParameters, 
			New TypeDescription("Structure, FixedStructure"));
	EndIf;
	
	If TypeOf(Data) = Type("String") Then 
		CommonClientServer.Validate(
				IsTempStorageURL(Data),
				NStr("ru = 'Недопустимое значение параметра Данные (указан адрес, который не является адресом временного хранилища)';
					|en = 'Invalid value of the Data parameter (the specified address is not a temporary storage address).';"), 
				"CryptographyService.Encrypt");
	EndIf;	
	If TypeOf(Data) <> Type("Array") Then 
		Return;
	EndIf;
	
	IndexOf = 0;
	For Each Item In Data Do
		CommonClientServer.CheckParameter(
			"CryptographyService.Encrypt", 
			StrTemplate("Data[%1]", IndexOf),
			Item, 
			New TypeDescription("String, BinaryData"));
		
		If TypeOf(Item) = Type("String") Then
			CommonClientServer.Validate(
				IsTempStorageURL(Item),
				StrTemplate(NStr("ru = 'Недопустимое значение параметра Данные[%1] (указан адрес, который не является адресом временного хранилища)';
								|en = 'Invalid value of the Data [%1] parameter (the specified address is not a temporary storage address).';"), IndexOf), 
				"CryptographyService.Encrypt");
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
	
EndProcedure

Procedure EncryptCheckIncomingParametersBlock(Data, Recipient)

	CommonClientServer.CheckParameter(
		"CryptographyService.EncryptBlock", 
		"Data",
		Data, 
		New TypeDescription("BinaryData, String"));
	
	CommonClientServer.CheckParameter(
		"CryptographyService.EncryptBlock", 
		"Recipient",
		Recipient, 
		New TypeDescription("BinaryData, Structure, FixedStructure"));
	
	If TypeOf(Data) = Type("String") Then 
		CommonClientServer.Validate(
				IsTempStorageURL(Data),
				NStr("ru = 'Недопустимое значение параметра Данные (указан адрес, который не является адресом временного хранилища)';
					|en = 'Invalid value of the Data parameter (the specified address is not a temporary storage address).';"), 
				"CryptographyService.EncryptBlock");
	EndIf;	
			
EndProcedure

Procedure DecryptCheckingIncomingParameters(EncryptedData, EncryptionType, EncryptionParameters)
	
	CommonClientServer.CheckParameter(
		"CryptographyService.Decrypt", 
		"EncryptedData",
		EncryptedData, 
		New TypeDescription("BinaryData, String"));
	
	CommonClientServer.CheckParameter(
		"CryptographyService.Decrypt", 
		"EncryptionType",
		EncryptionType, 
		New TypeDescription("String"));
	
	CommonClientServer.Validate(
		EncryptionType = "CMS",
		StrTemplate(NStr("ru = 'Недопустимое значение параметра %1 (неизвестный тип шифрования)';
						|en = 'Incorrect value of the %1 parameter (unknown encryption type)';"),
			"EncryptionType"),
		"CryptographyService.Decrypt");
	
	If ValueIsFilled(EncryptionParameters) Then
		CommonClientServer.CheckParameter(
			"CryptographyService.Decrypt", 
			"EncryptionParameters",
			EncryptionParameters, 
			New TypeDescription("Structure, FixedStructure"));
	EndIf;
	
	If TypeOf(EncryptedData) = Type("String") Then
		CommonClientServer.Validate(
			IsTempStorageURL(EncryptedData),
			StrTemplate(NStr("ru = 'Недопустимое значение параметра %1 (указан адрес, который не является адресом временного хранилища)';
							|en = 'Incorrect value of the %1 parameter (the specified address is not a temporary storage address)';"),
				"EncryptedData"),
			"CryptographyService.Decrypt");
	EndIf;
		
EndProcedure

Procedure DecryptCheckIncomingParametersBlock(EncryptedData, Recipient, KeyInformation, EncryptionParameters)
	
	CommonClientServer.CheckParameter(
		"CryptographyService.DecryptBlock", 
		"EncryptedData",
		EncryptedData, 
		New TypeDescription("BinaryData, String"));
		
	CommonClientServer.CheckParameter(
		"CryptographyService.DecryptBlock", 
		"Recipient",
		Recipient, 
		New TypeDescription("BinaryData, Structure, FixedStructure"));
	
	CommonClientServer.CheckParameter(
		"CryptographyService.DecryptBlock", 
		"KeyInformation",
		KeyInformation, 
		New TypeDescription("Structure"));
	
	CommonClientServer.Validate(
		KeyInformation.Property("ephemeral_key")
		And KeyInformation.Property("iv_data")
		And KeyInformation.Property("session_key"),
		StrTemplate(NStr("ru = 'Отсутствует одно и/или более обязательных свойств параметра %1 (%2)';
						|en = 'One or more required properties of the %1 (%2) parameter are missing';"),
			"KeyInformation", "ephemeral_key|session_key|iv_data"),
		"CryptographyService.DecryptBlock");
		
	CommonClientServer.CheckParameter(
		"CryptographyService.DecryptBlock", 
		"KeyInformation.ephemeral_key",
		KeyInformation.ephemeral_key, 
		New TypeDescription("BinaryData, String"));
		
	CommonClientServer.CheckParameter(
		"CryptographyService.DecryptBlock", 
		"KeyInformation.session_key",
		KeyInformation.session_key, 
		New TypeDescription("BinaryData, String"));
		
	CommonClientServer.CheckParameter(
		"CryptographyService.DecryptBlock", 
		"KeyInformation.iv_data",
		KeyInformation.iv_data, 
		New TypeDescription("BinaryData, String"));
		
	If ValueIsFilled(EncryptionParameters) Then
		CommonClientServer.CheckParameter(
			"CryptographyService.DecryptBlock", 
			"EncryptionParameters",
			EncryptionParameters, 
			New TypeDescription("Structure, FixedStructure"));
	EndIf;
	
	If TypeOf(EncryptedData) = Type("String") Then
		CommonClientServer.Validate(
			IsTempStorageURL(EncryptedData),
			StrTemplate(NStr("ru = 'Недопустимое значение параметра %1 (указан адрес, который не является адресом временного хранилища)';
							|en = 'Incorrect value of the %1 parameter (the specified address is not a temporary storage address)';"),
				"EncryptedData"),
			"CryptographyService.DecryptBlock");
	EndIf;
		
EndProcedure

Procedure HashingDataCheckingIncomingParameters(Data, HashAlgorithm, HashingParameters)

	CommonClientServer.CheckParameter(
		"CryptographyService.DataHashing", 
		"Data",
		Data, 
		New TypeDescription("BinaryData, String"));
	
	If TypeOf(Data) = Type("String") Then
		CommonClientServer.Validate(
			IsTempStorageURL(Data),
			NStr("ru = 'Недопустимое значение параметра Данные (указан адрес, который не является адресом временного хранилища)';
				|en = 'Invalid value of the Data parameter (the specified address is not a temporary storage address).';"), 
			"CryptographyService.DataHashing");
	EndIf;
	
	CommonClientServer.Validate(
		StrSplit("GOST R 34.11-94^GOST R 34.11-2012 256^GOST R 34.11-2012 512", "^").Find(HashAlgorithm) <> Undefined,
		StrTemplate(NStr("ru = 'Недопустимое значение параметра %1 (неизвестный алгоритм хеширования)';
						|en = 'Invalid value of the %1 parameter (unknown hashing algorithm)';"),
			"HashAlgorithm"),
		"CryptographyService.DataHashing");
		
	If ValueIsFilled(HashingParameters) Then
		CommonClientServer.CheckParameter(
			"CryptographyService.DataHashing", 
			"HashingParameters",
			HashingParameters, 
			New TypeDescription("Structure, FixedStructure"));
	EndIf;
	
EndProcedure

Procedure SignCheckIncomingParameters(Data, Signatory, SignatureType, SigningParameters)

	CommonClientServer.CheckParameter(
		"CryptographyService.Sign", 
		"Data",
		Data, 
		New TypeDescription("BinaryData, Array, String"));
	
	CommonClientServer.CheckParameter(
		"CryptographyService.Sign", 
		"Signatory",
		Signatory, 
		New TypeDescription("BinaryData, Structure, FixedStructure"));
	
	CommonClientServer.CheckParameter(
		"CryptographyService.Sign", 
		"SignatureType",
		SignatureType, 
		New TypeDescription("String"));
	
	CommonClientServer.Validate(
		SignatureType = "CMS" Or SignatureType = "GOST3410",
		StrTemplate(NStr("ru = 'Недопустимое значение параметра %1 (неизвестный тип подписи)';
						|en = 'Invalid value of the %1 parameter (unknown signature type)';"),
			"SignatureType"),
		"CryptographyService.Sign");
	
	If ValueIsFilled(SigningParameters) Then
		CommonClientServer.CheckParameter(
			"CryptographyService.Sign", 
			"SigningParameters",
			SigningParameters, 
			New TypeDescription("Structure, FixedStructure"));
	EndIf;
	
	If TypeOf(Data) = Type("String") Then 
		CommonClientServer.Validate(
				IsTempStorageURL(Data),
				NStr("ru = 'Недопустимое значение параметра Данные (указан адрес, который не является адресом временного хранилища)';
					|en = 'Invalid value of the Data parameter (the specified address is not a temporary storage address).';"), 
				"CryptographyService.Sign");
	EndIf;	
	If TypeOf(Data) <> Type("Array") Then 
		Return;
	EndIf;
	
	IndexOf = 0;
	For Each Item In Data Do
		CommonClientServer.CheckParameter(
			"CryptographyService.Sign", 
			StrTemplate("Data[%1]", IndexOf),
			Item, 
			New TypeDescription("String, BinaryData"));
		
		If TypeOf(Item) = Type("String") Then
			CommonClientServer.Validate(
				IsTempStorageURL(Item),
				StrTemplate(NStr("ru = 'Недопустимое значение параметра Данные[%1] (указан адрес, который не является адресом временного хранилища)';
								|en = 'Invalid value of the Data [%1] parameter (the specified address is not a temporary storage address).';"), IndexOf), 
				"CryptographyService.Sign");
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
		
EndProcedure

Procedure CheckSignatureCheckingIncomingParameters(Signature, Data, SignatureType, SigningParameters)

	CommonClientServer.CheckParameter(
		"CryptographyService.VerifySignature", 
		"Signature",
		Signature, 
		New TypeDescription("BinaryData, String"));
	
	If ValueIsFilled(SigningParameters) Then
		CommonClientServer.CheckParameter(
			"CryptographyService.VerifySignature", 
			"SigningParameters",
			SigningParameters, 
			New TypeDescription("Structure, FixedStructure"));
	EndIf;
	
	If Not ValueIsFilled(SigningParameters)
		Or Not SigningParameters.Property("DisconnectedSignature")
		Or Not SigningParameters.DisconnectedSignature Then
		CommonClientServer.CheckParameter(
			"CryptographyService.VerifySignature", 
			"Data",
			Data, 
			New TypeDescription("BinaryData, String"));
	EndIf;
	
	CommonClientServer.CheckParameter(
		"CryptographyService.VerifySignature", 
		"SignatureType",
		SignatureType, 
		New TypeDescription("String"));
	
	CommonClientServer.Validate(
		SignatureType = "CMS" Or SignatureType = "GOST3410",
		StrTemplate(NStr("ru = 'Недопустимое значение параметра %1 (неизвестный тип подписи)';
						|en = 'Invalid value of the %1 parameter (unknown signature type)';"),
			"SignatureType"),
		"CryptographyService.VerifySignature");
	
	If TypeOf(Signature) = Type("String") Then
		CommonClientServer.Validate(
			IsTempStorageURL(Signature),
			NStr("ru = 'Недопустимое значение параметра Подпись (указан адрес, который не является адресом временного хранилища)';
				|en = 'Invalid value of the Signature parameter (the specified address is not a temporary storage address).';"), 
			"CryptographyService.VerifySignature");
	EndIf;
		
	If TypeOf(Data) = Type("String") Then
		CommonClientServer.Validate(
			IsTempStorageURL(Data),
			NStr("ru = 'Недопустимое значение параметра Данные (указан адрес, который не является адресом временного хранилища)';
				|en = 'Invalid value of the Data parameter (the specified address is not a temporary storage address).';"), 
			"CryptographyService.VerifySignature");
	EndIf;
	
	If SignatureType = "GOST3410" Then 
		CommonClientServer.Validate(
			ValueIsFilled(SigningParameters) And SigningParameters.Property("Certificate"),
			NStr("ru = 'Для проверки подписи по ГОСТ Р 34.10-94 необходимо указание сертификата';
				|en = 'To check the signature according to GOST R 34.10-94, specify the certificate';"), 
			"CryptographyService.VerifySignature");
	EndIf;
		
EndProcedure

Procedure GetPropertiesOfCryptographicMessageCheckingIncomingParameters(CryptoMessage)

	CommonClientServer.CheckParameter(
		"CryptographyService.GetCryptoMessageProperties", 
		"CryptoMessage",
		CryptoMessage, 
		New TypeDescription("BinaryData, String"));
	
	If TypeOf(CryptoMessage) = Type("String") Then
		CommonClientServer.Validate(
			IsTempStorageURL(CryptoMessage),
			NStr("ru = 'Недопустимое значение параметра Криптосообщение (указан адрес, который не является адресом временного хранилища)';
				|en = 'Invalid value of the CryptoMessage parameter (the specified address is not a temporary storage address).';"), 
			"CryptographyService.GetCryptoMessageProperties");
	EndIf;
		
EndProcedure

Procedure GetCertificatesFromSigningCheckIncomingParameters(Signature)
		
	CommonClientServer.CheckParameter(
		"CryptographyService.GetCertificatesFromSignature", 
		"Signature",
		Signature, 
		New TypeDescription("BinaryData, String"));
	
	If TypeOf(Signature) = Type("String") Then
		CommonClientServer.Validate(
			IsTempStorageURL(Signature),
			NStr("ru = 'Недопустимое значение параметра Подпись (указан адрес, который не является адресом временного хранилища)';
				|en = 'Invalid value of the Signature parameter (the specified address is not a temporary storage address).';"), 
			"CryptographyService.GetCertificatesFromSignature");
	EndIf;
		
EndProcedure

Procedure CheckCertificateCheckIncomingParameters(Certificate)
		
	CommonClientServer.CheckParameter(
		"CryptographyService.CheckCertificate", 
		"Certificate",
		Certificate, 
		New TypeDescription("BinaryData, Structure"));
		
EndProcedure

Procedure GetCertificatePropertiesCheckIncomingParameters(Certificate)
	
	CommonClientServer.CheckParameter(
		"CryptographyService.GetCertificateProperties", 
		"Certificate",
		Certificate, 
		New TypeDescription("BinaryData, Structure"));
	
EndProcedure

Procedure GetTemporaryPasswordCheckIncomingParameters(CertificateID, Resending, PasswordsDeliveryMethod)

	CommonClientServer.CheckParameter(
		"CryptographyService.GetTemporaryPassword", 
		"CertificateID",
		CertificateID, 
		New TypeDescription("String"));

	CommonClientServer.CheckParameter(
		"CryptographyService.GetTemporaryPassword", 
		"Resending",
		Resending, 
		New TypeDescription("Boolean"));

	CommonClientServer.CheckParameter(
		"CryptographyService.GetTemporaryPassword", 
		"PasswordsDeliveryMethod",
		PasswordsDeliveryMethod, 
		New TypeDescription("String"));
		
	If TypeOf(PasswordsDeliveryMethod) = Type("String") Then
		CommonClientServer.Validate(
			PasswordsDeliveryMethod = "phone" Or PasswordsDeliveryMethod = "email",
			StrTemplate(NStr("ru = 'Недопустимое значение параметра %1, допустимые значения ""%2"" или ""%3""';
							|en = 'Incorrect value of the %1 parameter. Valid values are ""%2"" or ""%3""';"),
				"PasswordsDeliveryMethod", "phone", "email"),
			"CryptographyService.GetTemporaryPassword");
	EndIf;
		
EndProcedure
	
Function CertificateDescription(ListOfOIDs)
	
	For Each OIDElement In ListOfOIDs Do
		If OIDElement.OID = "2.5.4.3" Then
			Return OIDElement.Value;
		EndIf;
	EndDo;	
	
	Return "";
	
EndFunction
	
#EndRegion

#Region EventNames

Function EventNameEncryption()
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Сервис криптографии.Шифрование';
				|en = 'Cryptography service.Encryption';", Common.DefaultLanguageCode());
	
EndFunction

Function EventNameBlockEncryption()
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Сервис криптографии.Шифрование блока';
				|en = 'Cryptography service.Block encryption';", Common.DefaultLanguageCode());
	
EndFunction

Function EventNameDecryption()
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Сервис криптографии.Расшифровка';
				|en = 'Cryptography service.Decryption';", Common.DefaultLanguageCode());
	
EndFunction

Function EventNameBlockDecryption()
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Сервис криптографии.Расшифровка блока';
				|en = 'Cryptography service.Block decryption';", Common.DefaultLanguageCode());
	
EndFunction

Function EventNameAuthentication()
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Сервис криптографии.Аутентификация';
				|en = 'Cryptography service.Authentication';", Common.DefaultLanguageCode());
	
EndFunction

Function EventNamePropertiesOfCryptoMessage()
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Сервис криптографии.Свойства криптосообщения';
				|en = 'Cryptography service.Crypto message properties';", Common.DefaultLanguageCode());
	
EndFunction

Function NameOfCertificateVerificationEvent()
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Сервис криптографии.Проверка сертификата';
				|en = 'Cryptography service.Certificate check';", Common.DefaultLanguageCode());
	
EndFunction

Function NameOfCertificatePropertyEvent()
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Сервис криптографии.Свойства сертификата';
				|en = 'Cryptography service.Certificate properties';", Common.DefaultLanguageCode());
	
EndFunction

Function EventNameSignatureVerification()
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Сервис криптографии.Проверка подписи';
				|en = 'Cryptography service.Signature check';", Common.DefaultLanguageCode());
	
EndFunction

Function EventNameHashing()
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Сервис криптографии.Хеширование';
				|en = 'Cryptography service.Hashing';", Common.DefaultLanguageCode());
	
EndFunction

Function EventNameSigning()
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Сервис криптографии.Подписание';
				|en = 'Cryptography service.Signing';", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#EndRegion