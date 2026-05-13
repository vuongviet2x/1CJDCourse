////////////////////////////////////////////////////////////////////////////////
// Subsystem "Cryptography Service Manager".
//
////////////////////////////////////////////////////////////////////////////////
// 
//@strict-types

#Region Public

// Creates a key pair and generates data for a certificate request.
//
// Parameters:
//   CallbackOnCompletion - NotifyDescription - Details of the procedure that obtains the selection result:
//     * Result - Structure - Procedure runtime result:
//       ** Completed2      		- Boolean - If True, the procedure is completed and the result is received. Otherwise, see ErrorInfo. 
//       						  
//       ** ErrorDescription 		- ErrorInfo - Runtime error details. 
//								  If an error occurs, the following fields are not generated.
//       ** CertificateRequest1 	- BinaryData - File binary data in the PKCS10 format.
//       ** PublicKey 		- BinaryData - Data of the key.
//       ** ProviderName 		- String - Contains the provider name used to generate the key.
//       ** ProviderType 		- Number - Provider type used to generate the key.
//   ApplicationID		- String - Usually, a UUID. Used for certificate installation. The length is 36 characters.
//   RequestContent 			- String - Details of the certificate request fields.
//   SubscriberID 		- String - UUID. The length is 36 characters.
//   NotaryLawyerHeadOfFarm	- Boolean - Required to generate an OGRN.
//
Procedure CreateContainerAndRequestCertificate(CallbackOnCompletion, 
										ApplicationID, 
										RequestContent, 
										SubscriberID = Undefined,
										NotaryLawyerHeadOfFarm = False) Export
	
	CryptographyServiceManagerInternalClient.CreateContainerAndRequestCertificate(
			CallbackOnCompletion,
			ApplicationID,
			RequestContent,
			SubscriberID,
			NotaryLawyerHeadOfFarm);
	
EndProcedure

// Installs a certificate in a secured storage.
//
// Parameters:
//   CallbackOnCompletion - NotifyDescription - Details of the procedure that obtains the selection result:
//     * Result - Structure - Procedure runtime result:
//       ** Completed2      	- Boolean - If True, the procedure is completed and the result is received. Otherwise, see ErrorInfo.
//       ** ErrorDescription 	- ErrorInfo - Runtime error details (if an error occurred).
//   ApplicationID - String - Usually, a UUID used for private key mapping. The length is 36 characters.
//   CertificateData 		- BinaryData - Binary data in the DER or PEM encoding.
//
Procedure BindCertToContainerAndSystemStore(CallbackOnCompletion, 
												ApplicationID, 
												CertificateData) Export
	
	CryptographyServiceManagerInternalClient.BindCertToContainerAndSystemStore(
			CallbackOnCompletion,
			ApplicationID,
			CertificateData);
		
EndProcedure

#EndRegion