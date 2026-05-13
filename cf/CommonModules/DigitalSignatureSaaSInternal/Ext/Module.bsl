////////////////////////////////////////////////////////////////////////////////
// "Digital signature in SaaS" subsystem.
//  
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Generates a name to search settings of a certificate ID in the safe storage.
// 
// Parameters:
//	CertificateID - String - settings search key
//
// Returns:
//	String - a setting name.
//
Function NameForConfiguringLongTermCertificateToken(CertificateID)

	Return "DigitalSignature.DigitalSignatureSaaS." + CertificateID;

EndFunction

// Returns a storage structure of token check settings.
//
// Returns:
//	Structure - Contains the following required properties:
//	* CryptoOperationsConfirmationMethod - EnumRef.CryptoOperationsConfirmationMethods
//	* Id - String
//	* Thumbprint - String
//	* Token - String
//
Function BasicPropertiesOfDecryption()
	
	Result = New Structure();
	Result.Insert("CryptoOperationsConfirmationMethod", Enums.CryptoOperationsConfirmationMethods.SessionToken);
	Result.Insert("Id", "");
	Result.Insert("Thumbprint", "");
	Result.Insert("Token", "");
	
	Return Result;
	
EndFunction

// Internal function to determine the certificate ID in the passed parameters.
//
// Parameters:
//	Certificate - String, Structure - data containing a certificate ID:
//	 * Id - String - Certificate ID.
//
// Returns:
//   String - contains a certificate ID or a blank string.
//
Function IDOfPropertyCertificate(Certificate, CurrentProperties = Undefined)
	
	Result = "";
	Thumbprint = "";
	
	If TypeOf(Certificate) = Type("Structure") Then
		If Certificate.Property("Id") Then
			Result = CryptographyServiceInternal.Id(Certificate);
		ElsIf Certificate.Property("Thumbprint") Then
			Thumbprint = Certificate.Thumbprint;
			CertificateStructure = CertificatesStorage.FindCertificate(Certificate);
			If CertificateStructure <> Undefined Then
				Result = CertificateStructure.Id;
			EndIf;	
		EndIf;
		
	Else
		Result = Certificate;
		
	EndIf;
	
	If CurrentProperties <> Undefined Then
		CurrentProperties.Thumbprint 		= Thumbprint;
		CurrentProperties.Id 	= Result;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns certificate settings: usage of a durable token and its value.
//
// Parameters:
//   Certificate - String, Structure - Contains certificate properties. ID is required.:
//    * Id - String
//    
// Returns:
//  See BasicPropertiesOfDecryption
//
Function CertificateSigningDecryptionProperties(Certificate) Export
	
	Result 					= BasicPropertiesOfDecryption();
	CertificateID    = IDOfPropertyCertificate(Certificate, Result);
	
	If Not ValueIsFilled(CertificateID) Then
		Return Result;
	EndIf;
	
	Try
		SetPrivilegedMode(True);
		
		// Saving a long-term security token to the secure password storage.
		ConfigurationData = Common.ReadDataFromSecureStorage(NameForConfiguringLongTermCertificateToken(CertificateID), "Settings");
		
		SetPrivilegedMode(False);
		
		If ConfigurationData <> Undefined Then
			FillPropertyValues(Result, ConfigurationData);
		EndIf;
		
	Except
		
	EndTry;
	
	Return Result;
	
EndFunction

// Clears durable token usage settings.
//
// Parameters:
//	Certificate - Structure, String - Contains certificate properties. ID is required.
//
Procedure DeleteSigningDecryptionProperties(Certificate) Export
	
	CertificateID    = IDOfPropertyCertificate(Certificate);
	
	If Not ValueIsFilled(CertificateID) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	Common.DeleteDataFromSecureStorage(NameForConfiguringLongTermCertificateToken(CertificateID));
	SetPrivilegedMode(False);
	
EndProcedure

// Saves durable token usage settings.
//
// Parameters:
//   Certificate - Structure, String - Contains certificate properties. ID is required.
//
Procedure SetSigningDecryptionProperties(Certificate) Export
	
	NewSettings1 				= BasicPropertiesOfDecryption();
	CertificateID    = IDOfPropertyCertificate(Certificate, NewSettings1);
	
	If Not ValueIsFilled(CertificateID) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	SettingName	= CryptographyServiceInternal.ConfigurationNameAndCertificateSecurityToken(CertificateID);
	CurrentToken	= Common.ReadDataFromSecureStorage(SettingName, "UseLongLastingSecurityToken");
						
	NewSettings1.CryptoOperationsConfirmationMethod = Enums.CryptoOperationsConfirmationMethods.LongLivedToken;
	If CurrentToken <> Undefined Then
		NewSettings1.Token = CurrentToken;
	EndIf;						
	
	SettingName = NameForConfiguringLongTermCertificateToken(CertificateID);
	Common.WriteDataToSecureStorage(SettingName, NewSettings1, "Settings");
	SetPrivilegedMode(False);
	
EndProcedure

Procedure ConfigureUseOfLongTermToken(CryptoOperationsConfirmationMethod, Certificate) Export
	
	CertificateID    = IDOfPropertyCertificate(Certificate);
	
	If Not ValueIsFilled(CertificateID) Then
		Return;
	
	ElsIf CryptoOperationsConfirmationMethod = Enums.CryptoOperationsConfirmationMethods.LongLivedToken Then
		SetSigningDecryptionProperties(CertificateID);
		
	Else
		DeleteSigningDecryptionProperties(CertificateID);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	Certificate - See CryptographyServiceInternal.Id.Certificate
// Returns:
// 	BinaryData - certificate data.
Function FindCertificateById(Certificate) Export
	
	If Certificate.Property("Thumbprint")
		And ValueIsFilled(Certificate.Thumbprint) Then
		Result = Certificate.Thumbprint;
		
	Else
		SetPrivilegedMode(True);
		
		QueryText = 
		"SELECT TOP 1
		|	CertificatesStorage.Thumbprint AS Thumbprint
		|FROM
		|	InformationRegister.CertificatesStorage AS CertificatesStorage
		|WHERE
		|	CertificatesStorage.Id = &Id
		|	AND CertificatesStorage.StoreType = VALUE(Enum.CertificatesStorageType.PersonalCertificates)";
		
		Query 	= New Query(QueryText);
		Query.SetParameter("Id", CryptographyServiceInternal.Id(Certificate));
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			Result = Selection.Thumbprint;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion
