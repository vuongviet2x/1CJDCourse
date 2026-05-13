////////////////////////////////////////////////////////////////////////////////
// Subsystem "Cryptography service".
//  
////////////////////////////////////////////////////////////////////////////////
// 
//@strict-types

#Region Public

// Encrypts data for the specified recipient list.
//
// Parameters:
//   CallbackOnCompletion - NotifyDescription - Details of the procedure that obtains the selection result:
//    * Result - Structure - Procedure runtime result:
//       ** Completed2           - Boolean - If True, the procedure is completed and the result is received. Otherwise, see ErrorInfo.
//       ** ErrorInfo  - ErrorInfo - execution error details.
//       ** EncryptedData - BinaryData, String, Array - one or several files.
//                                                                If data is passed using a temporary storage,
//                                                                the result will be returned the same way.
//  
//   Data - BinaryData, String, Array - one or several files to be encrypted.
//                                             Binary data or an address in a temporary storage of a data file
//                                     		   that needs to be encrypted.
//
//   Recipients - BinaryData, Structure, FixedStructure, Array, FixedArray - Certificates of the encrypted message recipients.
//                Either BinaryData of certificate files or Structure with parameters to search for certificates in the store.
//     Structure - Key certificate parameters used for the search.
//                 Thumbprint, or SerialNumber and Issuer pair, or Certificate with binary data.
//       * Thumbprint - BinaryData, String - Certificate thumbprint.
//       Certificates of the encrypted message recipients.
//       Either BinaryData of certificate files or Structure with parameters to search for certificates in the store.
//       Structure - Key certificate parameters used for the search.
//       Thumbprint, or SerialNumber and Issuer pair, or Certificate with binary data.
//       * Thumbprint - BinaryData, String - Certificate thumbprint.
//
//   EncryptionType - String - an encryption type. Only CMS is supported.
//
//   EncryptionParameters - Structure, FixedStructure - allows to specify additional encryption parameters.
//
Procedure Encrypt(CallbackOnCompletion, Data, Recipients, EncryptionType = "CMS", EncryptionParameters = Undefined) Export
	
	CryptographyServiceInternalClient.Encrypt(CallbackOnCompletion, Data, Recipients, EncryptionType, EncryptionParameters);
	
EndProcedure

// Encrypts a data block for the recipient.
//
// Parameters:
//   CallbackOnCompletion - NotifyDescription - Details of the procedure that obtains the selection result:
//    * Result - Structure - Procedure runtime result:
//       ** Completed2           - Boolean - If True, the procedure is completed and the result is received. Otherwise, see ErrorInfo.
//       ** ErrorInfo  - ErrorInfo - execution error details.
//       ** EncryptedData - BinaryData, String, Array - one or several files.
//                                                                If data is passed using a temporary storage,
//                                                                the result will be returned the same way.
//  
//   Data - BinaryData, String - Binary data or a temporary storage address of the data to encrypt.
//                                     		   
//
//   Recipient - BinaryData, Structure, FixedStructure  - * SerialNumber - BinaryData, String - Certificate serial number.
//                * Issuer - Structure, FixedStructure, String - Issuer properties.
//     * Certificate - BinaryData - Certificate file.
//                 
//       
//       * SerialNumber - BinaryData, String - Certificate serial number.
//       * Issuer - Structure, FixedStructure, String - Issuer properties.
//       * Certificate - BinaryData - Certificate file.
//
Procedure EncryptBlock(CallbackOnCompletion, Data, Recipient) Export
	
	CryptographyServiceInternalClient.EncryptBlock(CallbackOnCompletion, Data, Recipient);
	
EndProcedure

// Decrypts data.
//
// Parameters:
//   CallbackOnCompletion - NotifyDescription - Details of the procedure that obtains the selection result:
//    * Result - Structure - Procedure runtime result:
//       ** Completed2            - Boolean - If True, the procedure is completed and the result is received. Otherwise, see ErrorInfo.
//       ** ErrorInfo   - ErrorInfo - execution error details.
//       ** DecryptedData - BinaryData, String - if data is passed using a temporary storage,
//                                                        the result will be returned the same way.
//       * Recipients           - FixedArray - certificates, using which data is encrypted.
//
//   EncryptedData - BinaryData, String - binary data or an address in a temporary storage of a data file
//                                                  that needs to be decrypted.
//
//   EncryptionType - String - only CMS is supported.
//
//   EncryptionParameters - Structure, FixedStructure - allows to specify additional encryption parameters.
//
Procedure Decrypt(CallbackOnCompletion, EncryptedData, EncryptionType = "CMS", EncryptionParameters = Undefined) Export
	
	CryptographyServiceInternalClient.Decrypt(CallbackOnCompletion, EncryptedData, EncryptionType, EncryptionParameters);
	
EndProcedure

// Decrypts a data block.
//
// Parameters:
//   CallbackOnCompletion - NotifyDescription - Details of the procedure that obtains the selection result:
//    * Result - Structure - Procedure runtime result:
//       ** Completed2            - Boolean - If True, the procedure is completed and the result is received. Otherwise, see ErrorInfo.
//       ** ErrorInfo   - ErrorInfo - execution error details.
//       ** DecryptedData - BinaryData, String - if data is passed using a temporary storage,
//                                                        the result will be returned the same way.
//       ** Recipients           - FixedArray - certificates, using which data is encrypted.
//
//   EncryptedData - BinaryData, String - binary data or an address in a temporary storage of a data file
//                                                  that needs to be decrypted.
//
//   Recipient - BinaryData - data of certificate files of the encrypted message recipient.
//				- Structure, FixedStructure - parameters to search for certificates in the storage.
//
//   KeyInformation - Structure, FixedStructure - allows to pass data about the encryption key to the query:
//       * ephemeral_key - BinaryData, String - in base64, ephemeral key
//       * session_key - BinaryData, String - in base64, session key
//       * iv_data - BinaryData, String - in base64, initialization vector data
//
//   EncryptionParameters - Structure, FixedStructure - allows you to specify additional hash parameters:
//       * ClearPaddingBytes - Boolean - indicates whether additional bytes will be deleted. They are deleted by default.
//
Procedure DecryptBlock(CallbackOnCompletion, EncryptedData, Recipient, KeyInformation, EncryptionParameters = Undefined) Export
	
	CryptographyServiceInternalClient.DecryptBlock(CallbackOnCompletion, EncryptedData, Recipient, KeyInformation, EncryptionParameters);
	
EndProcedure

// Signs data.
//
// Parameters:
//   CallbackOnCompletion - NotifyDescription - Details of the procedure that obtains the selection result:
//    * Result - Structure - Procedure runtime result:
//       ** Completed2      - Boolean - If True, the procedure is completed and the result is received. Otherwise, see ErrorInfo.
//       ** ErrorInfo - ErrorInfo - execution error details.
//       ** Signature        - BinaryData, String , Array of BinaryData - 
//       				   - Array of String - one or several files.
//                           If data is passed using a temporary storage, the result will be returned the same way.
//
//   Data - BinaryData, String, Array - one or several files to be signed. 
//                                             Binary data or an address in a temporary storage of a data file
//                                             that needs to be signed.
//
//   Signatory - BinaryData - of a file of the certificate to be signed.
//             - Structure, FixedStructure - Parameters to search for certificates in the storage.:
//       		  * Thumbprint     - BinaryData, String - a certificate thumbprint, or
//       		  * SerialNumber - BinaryData, String - a serial number of a certificate.
//       		  * Issuer      - Structure, FixedStructure, String - Issuer properties, or
//       		  * Certificate    - BinaryData - a certificate file.
//
//   SignatureType - String - a signature type. Only CMS or GOST3410 is supported.
//
//   SigningParameters - Structure, FixedStructure - allows to specify additional signing parameters:
//     * DisconnectedSignature - Boolean - Supports only CMS. If True, generates a disconnected signature.
//                                       Otherwise, generates a connected signature. By default, True.
//
Procedure Sign(CallbackOnCompletion, Data, Signatory, SignatureType = "CMS", SigningParameters = Undefined) Export
	
	CryptographyServiceInternalClient.Sign(CallbackOnCompletion, Data, Signatory, SignatureType, SigningParameters);
	
EndProcedure

// Checks the signature.
//
// Parameters:
//   CallbackOnCompletion - NotifyDescription - Details of the procedure that obtains the selection result:
//    * Result - Structure - Procedure runtime result:
//       ** Completed2 - Boolean - If True, the procedure is completed and the result is received. Otherwise, see ErrorInfo.
//       ** ErrorInfo - ErrorInfo - execution error details.
//       ** SignatureIsValid - Boolean - True - a signature check result.
//
//   Signature - BinaryData - a signature that needs to be checked.
//
//   Data - BinaryData - source data required for a signature check. It is used to check DisconnectedSignature.
//
//   SignatureType - String - a signature type. Only "CMS" or "GOST3410" is supported.
//
//   SigningParameters - Structure, FixedStructure - By default, True.
//     * Certificate - BinaryData - Certificate file. Must be used with SignatureType = "GOST3410".
//                                       By default, True.
//     * Certificate - BinaryData - Certificate file. Must be used with SignatureType = "GOST3410".
//
Procedure VerifySignature(CallbackOnCompletion, Signature, Data = Undefined, SignatureType = "CMS", SigningParameters = Undefined) Export
	
	CryptographyServiceInternalClient.VerifySignature(CallbackOnCompletion, Signature, Data, SignatureType, SigningParameters);
	
EndProcedure

// Checks the certificate.
//
// Parameters:
//   CallbackOnCompletion - NotifyDescription - Details of the procedure that obtains the selection result:
//    * Result - Structure - Procedure runtime result:
//       ** Completed2 - Boolean - If True, the procedure is completed and the result is received. Otherwise, see ErrorInfo.
//       ** ErrorInfo - ErrorInfo - execution error details.
//       ** Valid1 - Boolean - the certificate meets the check requirements.
//  
//   Certificate - BinaryData - a certificate file.
//
Procedure CheckCertificate(CallbackOnCompletion, Certificate) Export
	
	CryptographyServiceInternalClient.CheckCertificate(CallbackOnCompletion, Certificate);
	
EndProcedure

// Checks a certificate with additional parameters.
//
// Parameters:
//   CallbackOnCompletion - NotifyDescription - Details of the procedure that obtains the selection result:
//    * Result - Structure - Procedure runtime result:
//       ** Completed2 - Boolean - If True, the procedure is completed and the result is received. Otherwise, see ErrorInfo.
//       ** ErrorInfo - ErrorInfo - execution error details.
//       ** Valid1 - Boolean - the certificate meets the check requirements.
//  
//   Certificate - BinaryData - Certificate file.
//
//   CheckParameters 				- Structure, FixedStructure -  Allows specifying additional certificate check parameters.
//     * CertificateCheckMode - String - Comma-delimited check modes. 
//									 Allows specifying additional certificate check parameters.
//         * CertificateCheckMode - String - Comma-delimited check modes.
//
Procedure VerifyCertificateWithParameters(CallbackOnCompletion, Certificate, CheckParameters) Export
	
	CryptographyServiceInternalClient.VerifyCertificateWithParameters(CallbackOnCompletion, Certificate, CheckParameters);
	
EndProcedure

// Gets main properties of the passed certificate.
// 
// Parameters:
//   CallbackOnCompletion - NotifyDescription - Details of the procedure that obtains the selection result:
//     * Result - Structure - Procedure runtime result:
//       ** Completed2 - Boolean - If True, the procedure is completed and the result is received. Otherwise, see ErrorInfo.
//       ** ErrorInfo - ErrorInfo - execution error details.
//       ** Certificate - FixedStructure - Certificate file in the DER encoding.:
//           *** Version - String - a certificate version.
//           *** StartDate - Date - a start date of a certificate (UTC).
//           *** EndDate - Date - a certificate end date (UTC).
//           *** Issuer - FixedStructure - Issuer information:
//                *** CN - String - commonName; 
//                *** O - String - organizationName; 
//                *** OU - String - organizationUnitName; 
//                *** C - String - countryName; 
//                *** ST - String - stateOrProvinceName; 
//                *** L - String - localityName; 
//                *** E - String - emailAddress; 
//                *** SN - String - surname; 
//                *** GN - String - givenName; 
//                *** T - String - title;
//                *** STREET - String - streetAddress;
//                *** OGRN - String - Registration number;
//                *** OGRNIP - String - Registration number of IE;
//                *** INN - String - TIN (optional).
//                *** INNLE - String - Legal entity's TIN (optional).
//                *** SNILS - String - SNILS;
//                   …
//           ** UseToSign - Boolean - indicates whether this certificate can be used for signing.
//           ** UseToEncrypt - Boolean - indicates whether this certificate can be used for encryption.
//           ** PublicKey - BinaryData - Contains public key data.
//           ** Thumbprint - BinaryData - Contains thumbprint data. It is calculated dynamically using the SHA-1 algorithm.
//           ** Extensions - FixedStructure -  extended certificate properties:
//                *** EKU - FixedArray - Enhanced Key Usage.
//           ** SerialNumber - BinaryData - a serial number of a certificate.
//           ** Subject - FixedStructure - Certificate subject information. For content, see Issuer.
//           ** Certificate - BinaryData - Certificate file in the DER encoding.
//           ** Id - String - Calculated from key Issuer properties and a serial number using the SHA1 algorithm.
//                                  Used to identify a certificate in the crypto service.
//
//   Certificate - BinaryData - a certificate whose properties you need to get.
//
Procedure GetCertificateProperties(CallbackOnCompletion, Certificate) Export
	
	CryptographyServiceInternalClient.GetCertificateProperties(CallbackOnCompletion, Certificate);
	
EndProcedure

// Extracts a certificate array from the signature data.
//
// Parameters:
//   CallbackOnCompletion - NotifyDescription - Details of the procedure that obtains the selection result:
//     * Result - Structure - Procedure runtime result:
//       ** Completed2 - Boolean - If True, the procedure is completed and the result is received. Otherwise, see ErrorInfo.
//       ** ErrorInfo - ErrorInfo - execution error details.
//       ** Certificates - Array of BinaryData - Certificate content.
//  
//   Signature - BinaryData - a signature file.
//           - String - address in temporary storage.
//
Procedure GetCertificatesFromSignature(CallbackOnCompletion, Signature) Export
	
	CryptographyServiceInternalClient.GetCertificatesFromSignature(CallbackOnCompletion, Signature);
	
EndProcedure

// Calculates a hash sum by the passed data.
//
// Parameters:
//   CallbackOnCompletion - NotifyDescription - Details of the procedure that obtains the selection result:
//     * Result - Structure - Procedure runtime result:
//       ** Completed2      - Boolean - If True, the procedure is completed and the result is received. Otherwise, see ErrorInfo.
//       ** ErrorInfo - ErrorInfo - execution error details.
//       ** Hash  - BinaryData - a hash sum value.
//
//   Data - BinaryData, String - binary data or an address in a temporary storage of a file of data,
//                                     by which you need to calculate a hash sum.
//   HashAlgorithm - String - a constant from the list "GOST R 34.11-94", "GOST R 34.11-2012 256", "GOST R 34.11-2012 512".
//
//   HashingParameters - Structure, FixedStructure - allows you to specify additional hash parameters:
//     * InvertNibbles - Boolean - Manages nibble inversion into a hash sum value. Applicable for GOST R 34.11-94.
//                                For example, the direct order is 62 FB, the reversed order is 26 BF.
//                                By default, True.
//
Procedure DataHashing(CallbackOnCompletion, Data, HashAlgorithm = "GOST R 34.11-94", HashingParameters = Undefined) Export

	CryptographyServiceInternalClient.DataHashing(CallbackOnCompletion, Data, HashAlgorithm, HashingParameters);
	
EndProcedure

#EndRegion
