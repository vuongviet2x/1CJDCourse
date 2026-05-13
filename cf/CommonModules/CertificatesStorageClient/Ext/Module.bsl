////////////////////////////////////////////////////////////////////////////////
// "Certificate storage" subsystem.
//  
////////////////////////////////////////////////////////////////////////////////
//


#Region Public

// Adds a certificate to the certificate store.
// 
// Parameters:
//   CallbackOnCompletion - NotifyDescription - * ErrorDetails - String - Error description.
//     
//       
//       * ErrorDetails - String - Error description.
//
//   Certificate - BinaryData - a certificate file.
//                String - a certificate file address in a temporary storage.
//   StoreType - String, EnumRef.CertificatesStorageType - - Type of the storage to add the certificate to.
//
Procedure Add(CallbackOnCompletion, Certificate, StoreType) Export
	
	CertificatesStorageInternalClient.Add(CallbackOnCompletion, Certificate, StoreType);
	
EndProcedure

// Gets certificates from the storage.
// 
// Parameters:
//   CallbackOnCompletion - NotifyDescription - Description of the procedure that takes the result.
//     Result - String - Runtime result.
//       * Executed - Boolean - If True, the procedure is completed. Otherwise, see ErrorDetails.
//       Description of the procedure that takes the result.
//       Result - String - Runtime result.
//           * Executed - Boolean - If True, the procedure is completed. Otherwise, see ErrorDetails.
//           
//           
//           
//                 
//                 
//                 
//                 
//                 
//                 
//                 
//                 
//                 
//                
//                
//                
//                
//                
//                
//                
//                   
//           
//           
//           
//           
//                
//           
//           
//           
//           
//                                  
//
//   StoreType - String, EnumRef.CertificatesStorageType - - Type of the storage to get certificates from.
//                                                                If not specified, get all certificates.
//                                                                
//
Procedure Get(CallbackOnCompletion, StoreType = Undefined) Export
	
	CertificatesStorageInternalClient.Get(CallbackOnCompletion, StoreType);
	
EndProcedure

// Searches for a certificate in the storage.
//
// Parameters:
//   CallbackOnCompletion - NotifyDescription -  Description of the procedure that takes the result.
//     Result - String - Runtime result.
//       * Executed - Boolean - If True, the procedure is completed. Otherwise, see ErrorDescription.
//        Description of the procedure that takes the result.
//       Result - String - Runtime result.
//       * Executed - Boolean - If True, the procedure is completed. Otherwise, see ErrorDescription.
// 
//   Certificate - Structure - Key certificate parameters used for the search.
//                            Thumbprint or SerialNumber and Issuer pair.
//     * Thumbprint - BinaryData - Certificate thumbprint.
//                   Key certificate parameters used for the search.
//     Thumbprint or SerialNumber and Issuer pair.
//                       * Thumbprint - BinaryData - Certificate thumbprint.
//     
//                  
//
Procedure FindCertificate(CallbackOnCompletion, Certificate) Export
	
	CertificatesStorageInternalClient.FindCertificate(CallbackOnCompletion, Certificate);
	
EndProcedure

#EndRegion