////////////////////////////////////////////////////////////////////////////////
// Subsystem "Cryptography Service Manager".
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// (See CryptographyServiceManager.CreateContainerAndRequestCertificate)
// 
// Parameters: 
//  ApplicationID - String - ID of a certificate request search.
//  RequestContent - String - Contains OID fields.
//  PhoneNumber - String - Contains a confirmed phone ID.
//  Email - String - Contains a confirmed email ID.
//  SubscriberID - String -Subscriber ID.
//  NotaryLawyerHeadOfFarm - Boolean -Notary, lawyer, head of a farm enterprise.
// 
// Returns: 
//  Structure:
// * BriefErrorDescription - String
// * AdditionalResultAddress - String
// * ResultAddress - String
// * JobID - Undefined
// * Status - String
// (See TimeConsumingOperations.ExecuteInBackground)
Function CreateContainerAndRequestCertificate(ApplicationID,
										RequestContent,
										PhoneNumber,
										Email,
										SubscriberID = Undefined,
										NotaryLawyerHeadOfFarm = False) Export
	
	ProcedureParameters 	= New Structure;
	ProcedureParameters.Insert("ApplicationID", 	ApplicationID);
	ProcedureParameters.Insert("RequestContent", 		RequestContent);
	ProcedureParameters.Insert("PhoneNumber", 			PhoneNumber);
	ProcedureParameters.Insert("Email", 		Email);
	ProcedureParameters.Insert("SubscriberID", 	SubscriberID);
	ProcedureParameters.Insert("NotaryLawyerHeadOfFarm", 	NotaryLawyerHeadOfFarm);
		
	Return CryptographyServiceInternal.ExecuteInBackground("CryptographyServiceManager.CreateContainerAndRequestCertificate", 
						ProcedureParameters);
	
EndFunction	

// (See CryptographyServiceManager.BindCertToContainerAndSystemStore)
// 
// Parameters: 
//  ApplicationID - String - ID of a certificate request search.
//  CertificateData - BinaryData - Contains certificate data in the PEM encoding.
// 
// Returns: 
//  Structure - Set the certificate for a container and storage:
// * ResultAddress - String -
// * JobID - Undefined -
// * Status - String -
// (See TimeConsumingOperations.ExecuteFunction)
Function BindCertToContainerAndSystemStore(ApplicationID, CertificateData) Export
	
	ProcedureParameters 	= New Structure;
	ProcedureParameters.Insert("ApplicationID",	ApplicationID);
	ProcedureParameters.Insert("CertificateData", 		CertificateData);
		
	Return CryptographyServiceInternal.ExecuteInBackground("CryptographyServiceManager.BindCertToContainerAndSystemStore", 
					ProcedureParameters);
	
EndFunction

#EndRegion
