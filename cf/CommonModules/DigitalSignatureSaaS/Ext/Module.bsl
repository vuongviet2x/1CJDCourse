////////////////////////////////////////////////////////////////////////////////
// "Digital signature in SaaS" subsystem.
//  
////////////////////////////////////////////////////////////////////////////////
//


#Region Public

// Availability of digital signatures in SaaS.
// 
// Returns: 
//  Boolean
Function UsageAllowed() Export
	
	Return GetFunctionalOption("UseDigitalSignatureSaaS");
	
EndFunction

// Durable token availability.
// 
// Returns: 
//  Boolean
Function LongTermTokenUsageIsPossible() Export
	
	Result = False;
 
	SubsystemName = "RegulatedReporting";
	If Common.SubsystemExists(SubsystemName) Then
		SubsystemVersion = InfobaseUpdate.IBVersion(SubsystemName);
		Try
			Result = SubsystemVersion > "1.1.14.01";
		Except
		EndTry;	
	EndIf;	
	
	Return Result;
	
EndFunction

// Returns certificate settings: usage of a durable token and its value.
//
// Parameters:
//   Certificate - Structure, String - Contains certificate properties. ID is required.
//
// Returns:
//   Structure - Contains the following fields:
//   * CryptoOperationsConfirmationMethod - Arbitrary -
//   * Token - Arbitrary -
//   * Id - Arbitrary -
//   * Thumbprint - Arbitrary -
//
Function CertificateSigningDecryptionProperties(Certificate) Export
	
	Result = DigitalSignatureSaaSInternal.CertificateSigningDecryptionProperties(Certificate);
	
	Return Result;
	
EndFunction

// Clears durable token usage settings.
//
// Parameters:
//   Certificate - Structure - The following fields:
//					* Id - String - required.
//	 		    - String - Contains certificate properties. ID is required.
//
Procedure DeleteSigningDecryptionProperties(Certificate) Export
	
	DigitalSignatureSaaSInternal.DeleteSigningDecryptionProperties(Certificate);
	
EndProcedure

// Saves durable token usage settings.
//
// Parameters:
//	Certificate - Structure - The following fields:
//					* Id - String - required.
//	 		   - String - Contains certificate properties. ID is required.
//
Procedure SetSigningDecryptionProperties(Certificate) Export
	
	DigitalSignatureSaaSInternal.SetSigningDecryptionProperties(Certificate);
	
EndProcedure

Procedure ConfigureUseOfLongTermToken(CryptoOperationsConfirmationMethod, Certificate) Export
	
	DigitalSignatureSaaSInternal.ConfigureUseOfLongTermToken(CryptoOperationsConfirmationMethod, Certificate);
	
EndProcedure

// Find a certificate by its ID.
// 
// Parameters:
//  Certificate - Arbitrary
// 
// Returns:
//  BinaryData - Find a certificate by its ID.
Function FindCertificateById(Certificate) Export
	
	Result = DigitalSignatureSaaSInternal.FindCertificateById(Certificate);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Internal

// Parameters:
//  ParameterName - String
//  SpecifiedParameters - Array of String
//
Procedure SessionParametersSetting(Val ParameterName, SpecifiedParameters) Export
	
	If ParameterName = "SecurityTokens" Then
		SessionParameters.SecurityTokens = New FixedMap(New Map);
		SpecifiedParameters.Add("SecurityTokens");
	EndIf;
	
EndProcedure

// Generates the list of infobase parameters.
//
// Parameters:
//	ParametersTable - See SaaSOperations.IBParameters
//
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
		
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "UseDigitalSignatureSaaS");
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "DigitalSignatureAddingServiceAddressSaaS");
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "CryptoServiceAddress");	
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "DigitalSignatureServiceInSaaSUserName";
	ParameterString.LongDesc = "DigitalSignatureServiceInSaaSUserName";
	ParameterString.Type = New TypeDescription("String");
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "DigitalSignatureAttachmentSaaSServiceUserPassword";
	ParameterString.LongDesc = "DigitalSignatureAttachmentSaaSServiceUserPassword";
	ParameterString.Type = New TypeDescription("String");
	
EndProcedure

// Called before an attempt to write infobase parameters as
// constants with the same name.
//
// Parameters:
// ParameterValues - Structure - Parameter values to assign.
// If the value is assigned in this procedure, delete the corresponding KeyAndValue pair from the structure.
// 
//
Procedure OnSetIBParametersValues(Val ParameterValues) Export
	
	Owner = Common.MetadataObjectID("Constant.DigitalSignatureAddingServiceAddressSaaS");
	If ParameterValues.Property("DigitalSignatureServiceInSaaSUserName") Then
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Owner, ParameterValues.DigitalSignatureServiceInSaaSUserName, "Login");
		SetPrivilegedMode(False);
		ParameterValues.Delete("DigitalSignatureServiceInSaaSUserName");
	EndIf;
	
	If ParameterValues.Property("DigitalSignatureAttachmentSaaSServiceUserPassword") Then
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Owner, ParameterValues.DigitalSignatureAttachmentSaaSServiceUserPassword, "Password");
		SetPrivilegedMode(False);
		ParameterValues.Delete("DigitalSignatureAttachmentSaaSServiceUserPassword");
	EndIf;
	
EndProcedure

// Fills the structure with arrays of the supported versions of APIs that are subject to versioning,
// using API names as keys.
// Implements the InterfaceVersion web service functionality.
// When integrating, change the procedure body so that it returns current version sets (see the example below).
//
// Parameters:
// SupportedVersionsStructure - Structure - Where::
//  Key - API name.
//  Value - Array of String - Supported API versions.
//
// Use case:
//
//  FileTransferService
//  VersionsArray = New Array;
//  VersionsArray.Add("1.0.1.1");
//  VersionsArray.Add("1.0.2.1");
//  SupportedVersionsStructure.Insert("FileTransferService", VersionsArray);
//  End FileTransferService
//
Procedure OnDefineSupportedInterfaceVersions(SupportedVersionsStructure) Export
	
	VersionsArray = New Array;
	VersionsArray.Add("1.0.1.1");
	SupportedVersionsStructure.Insert("DigitalSignatureSaaS", VersionsArray);	
	
EndProcedure

// Returns the structure of parameters required for the operation of the client code
// configuration,
// - that is in the BeforeStart,
// - OnStart event handlers.
//
// Important: when starting the application, do not use cache reset commands of modules
// that reuse return values as this can lead
// to unpredictable errors and unnecessary service calls.
//
// Parameters:
//   Parameters - Structure - Return value. Structure of client startup parameters.
//
// Use case::
//   To set client parameters, you can use the following template:
//
//     Parameters.Insert(<ParameterName>, <Code for receiving a parameter value>);
//
//
Procedure OnAddClientParameters(Parameters) Export
	
	Parameters.Insert("UsingElectronicSignatureInServiceModelIsPossible", UsageAllowed());
	
EndProcedure

// Sets connection with an online server using http(s).
//
// Parameters:
//  ConnectionParameters - Structure - additional parameters for the thin setting:
//    * Schema - String - a value of the "HTTP" constant
//    * Host - String - 
//    * Port - Number -  
//    * Login - String - 
//    * Password - String - 
//    * Timeout - Number - determines a time-out of the connection and operations, in seconds.
//
// Returns:
//	HTTPConnection - join.
Function ConnectingToInternetServer(ConnectionParameters) Export

	Timeout = 30;
	If ConnectionParameters.Property("Timeout") Then
		Timeout = ConnectionParameters.Timeout;
	EndIf;
	
	Try
		CACertificates = New OSCertificationAuthorityCertificates;
		
		Join = New HTTPConnection(
			ConnectionParameters.Host,
			ConnectionParameters.Port,
			ConnectionParameters.Login,
			ConnectionParameters.Password, 
			GetFilesFromInternet.GetProxy(ConnectionParameters.Schema),
			Timeout,
			?(Lower(ConnectionParameters.Schema) = "http", Undefined, New OpenSSLSecureConnection(, CACertificates)));
	Except
		ErrorInfo = ErrorInfo();	
		// @skip-check module-nstr-camelcase - Check error.
		WriteLogEvent(
			NStr("ru = 'Электронная подпись в модели сервиса.Соединение с сервером интернета';
				|en = 'Digital signature SaaS.Connect to online server';", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo));
		Raise;
	EndTry;
	
	Return Join;
	
EndFunction

// Converts a string in the JSON format into structure. 
//
// Parameters:
//  JSONString              - String - a string in the JSON format.
//  ConversionParameters - Structure - additional parameters to set up conversion:
//    * PropertiesToReviveNames - Array, FixedArray - a list of properties 
//                                      that must be converted from Base64 into binary data.
// Returns:
//	Structure:
//	 * Field - Arbitrary - Arbitrary list of fields.
//
Function JSONToStructure(JSONString, ConversionParameters = Undefined) Export
	
	JSONReader = New JSONReader;
	JSONReader.SetString(JSONString);
	
	If TypeOf(ConversionParameters) = Type("Structure")
		And ConversionParameters.Property("PropertiesToReviveNames")
		And ValueIsFilled(ConversionParameters.PropertiesToReviveNames) Then
		Object = ReadJSON(
			JSONReader,,,, 
			"ConvertBase64ToBinaryData", 
			DigitalSignatureSaaS, 
			ConversionParameters,
			ConversionParameters.PropertiesToReviveNames);
	Else
		Object = ReadJSON(JSONReader);
	EndIf;
	
	JSONReader.Close();
	
	Return Object;
	
EndFunction

// Converts a structure into a JSON string. Binary data is converted into Base64 strings.
//
// Parameters:
//  Object - Structure - Structure to be converted into a JSON string.
//  ConversionParameters - Structure - Additional parameters that will be passed to the function that restores values.
//
// Returns:
//	String - in the JSON format.
//
Function StructureInJSON(Object, ConversionParameters = Undefined) Export
	
	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(
		JSONWriter, 
		Object,, 
		"ConvertBinaryDataToBase64", 
		DigitalSignatureSaaS, 
		ConversionParameters);
	
	Return JSONWriter.Close();
	
EndFunction

Procedure RaiseStandardException() Export
	
	Raise(NStr("ru = 'Сервис временно недоступен. Обратитесь в службу поддержки или повторите попытку позже.';
							|en = 'The service is temporarily unavailable. Contact the technical support or try again later.';"));
	
EndProcedure

#EndRegion

#Region Private

#Region WorkWithJSON

// Internal function to be used in the WriteJSON object.
// Serves as a function for converting binary data to base64 and contains the required 
// parameters.
// 
// Parameters: 
// 	Property 				- String - Parameter takes a property name when writing Structure or Map.
// 	Value 				- Arbitrary - Expected type is BinaryData.
// 	AdditionalParameters - Structure - Additional parameters specified in the WriteJSON call.:
//   * ReplaceBinaryData - Boolean - Replaces binary data.
// 	Cancel - Boolean	- Write cancel flag.
// 
// Returns: 
//  String
//
Function ConvertBinaryDataToBase64(Property, Value, AdditionalParameters, Cancel) Export
	
	If TypeOf(Value) = Type("BinaryData") Then
		If TypeOf(AdditionalParameters) = Type("Structure")
			And AdditionalParameters.Property("ReplaceBinaryData")
			And AdditionalParameters.ReplaceBinaryData Then
			Return Value.Size();
		Else
			Return Base64String(Value);
		EndIf;
	EndIf;
		
EndFunction

// Internal function to be used in the ReadJSON object.
// Serves as a function for restoring the base64 string in BinaryData and contains the required 
// parameters.
// 
// Parameters: 
//	Property 				- String - Specified only when reading JSON objects.
//	Value 				- Arbitrary - Valid serialization type.
//	AdditionalParameters - Arbitrary - Contains additional parameters. 
// 
// Returns: 
//  BinaryData
//
Function ConvertBase64ToBinaryData(Property, Value, AdditionalParameters) Export
	
	If TypeOf(Value) = Type("String") Then
		Return Base64Value(Value);
	ElsIf TypeOf(Value) = Type("Array") Then
		For IndexOf = 0 To Value.UBound() Do
			Value[IndexOf] = Base64Value(Value[IndexOf]);	
		EndDo;
		Return Value;
	EndIf;
	
	Return Value;
	
EndFunction

#EndRegion

#EndRegion
