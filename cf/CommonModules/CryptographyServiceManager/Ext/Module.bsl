////////////////////////////////////////////////////////////////////////////////
// Subsystem "Cryptography Service Manager".
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ConnectionApplication

// Send a connection application.
//
// Parameters:
//  ApplicationForm_ - Structure - Application.
// 
// Returns:
//  Structure - Result.:
//  * Completed2 - Boolean
//  * ErrorCode - String
//  * ErrorDescription - String
//
Function SendApplicationForActivation(ApplicationForm_) Export
	
	URL = ServiceAddress() + StrTemplate("/hs/requests/%1/request_sender", SoftwareInterfaceVersion_v2_0());
	
	QueryOptions = ApplicationForm_;
	QueryOptions.Insert("client", GetClientDescription());
	
	ResponseFields = New Structure("req_id", "Id");
	
	Return CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);

EndFunction

// Generate an application.
//
// Parameters:
//  ApplicationForm_ - Structure - Application.
// 
// Returns:
//  Structure - Result.:
//  * Completed2 - Boolean
//  * ErrorCode - String
//  * ErrorDescription - String
//
Function FormApplicationForSigning(ApplicationForm_) Export
	
	URL = ServiceAddress() + StrTemplate("/hs/requests/%1/request", SoftwareInterfaceVersion_v2_0());
	
	QueryOptions = ApplicationForm_;
	QueryOptions.Insert("client", GetClientDescription());
	
	ResponseFields = New Structure("req_id, request", "Id", "ApplicationForm_");
	ConversionParameters = New Structure("PropertiesToReviveNames", StrSplit("request", ","));
	
	Return CallHTTPMethod("POST", URL, QueryOptions, ResponseFields,, ConversionParameters);

EndFunction

// Send a signed application.
//
// Parameters:
//  ApplicationForm_ - Structure - Application.
// 
// Returns:
//  Structure - Result.:
//  * Completed2 - Boolean
//  * ErrorCode - String
//  * ErrorDescription - String
//
Function SendSignedStatement(ApplicationForm_) Export
	
	URL = ServiceAddress() + StrTemplate("/hs/requests/%1/signed_request_sender", SoftwareInterfaceVersion_v2_0());
	
	QueryOptions = ApplicationForm_;
	QueryOptions.Insert("client", GetClientDescription());
	
	ResponseFields = New Structure;
	
	Return CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);

EndFunction

// Function - Get the status of the connection application.
//
// Parameters:
//  ApplicationID - String - Application ID.
// 
// Returns:
//  Structure - Result.:
//  * Completed2 - Boolean
//  * ErrorCode - String
//  * ErrorDescription - String
///
///
Function GetStatusOfActivationRequest(ApplicationID) Export
	
	URL = ServiceAddress() + StrTemplate("/hs/requests/%1/request/%2",
										SoftwareInterfaceVersion_v1_1(),
										ApplicationID);
										
	ResponseFields = New Structure();
	ResponseFields.Insert("status", "Status");
	ResponseFields.Insert("details", "Explanation");
	ResponseFields.Insert("token_id", "CertificateID");
	ResponseFields.Insert("token_value", "Token");
	
	Return CallHTTPMethod("GET", URL, Undefined, ResponseFields);

EndFunction

#EndRegion

#Region PhoneAndEmailVerification

// Get a phone number verification code.
//
// Parameters:
//  Phone - String - Phone number.
//  Id - String - ID.
// 
// Returns:
//  Structure - Result with the following fields:
// 	 * Id - String - 
// 	 * CodeNumber - Number - 
// 	 * CodeValidityPeriod - Number - 
// 	 * DelayBeforeResending - Number -  
Function GetPhoneVerificationCode(Phone, Id = "") Export
	
	URL = ServiceAddress() + StrTemplate("/hs/verification/%1/phone/code", SoftwareInterfaceVersion_v1_1());
	
	QueryOptions = New Structure("phone,req_id,repeat", Phone, Id, ValueIsFilled(Id));
	
	ResponseFields = New Structure;
	ResponseFields.Insert("req_id", "Id");
	ResponseFields.Insert("num", "CodeNumber");
	ResponseFields.Insert("life_time", "CodeValidityPeriod");
	ResponseFields.Insert("delay", "DelayBeforeResending");
	
	Return CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);

EndFunction

// Verify a phone number with a code.
//
// Parameters:
//  Id - String - ID.
//  Code - String - Code.
// 
// Returns:
//  Structure - Result.:
//  * Completed2 - Boolean
//  * ErrorCode - Number
//  * ErrorDescription - String
///
///
Function CheckPhoneNumberByCode(Id, Code) Export
	
	URL = ServiceAddress() + StrTemplate("/hs/verification/%1/phone", SoftwareInterfaceVersion_v1_1());
	
	QueryOptions = New Structure("req_id,code", Id, Code);
	
	ResponseFields = New Structure;
	
	Return CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);
	
EndFunction

// Get an email verification code.
//
// Parameters:
//  Email - String - Email.
//  Id - String - ID.
// 
// Returns:
//  Structure - Result.:
//   * Id - String - 
//	 * CodeNumber - Number - 
//	 * CodeValidityPeriod - Number - 
//	 * DelayBeforeResending - Number -  
Function GetEmailVerificationCode(Email, Id = "") Export
	
	URL = ServiceAddress() + StrTemplate("/hs/verification/%1/email/code", SoftwareInterfaceVersion_v1_1());
	
	QueryOptions = New Structure("email,req_id,repeat", Email, Id, ValueIsFilled(Id));
	
	If Not Common.SubsystemExists("RegulatedReporting.ElectronicDocumentManagementSupervisoryAuthorities") Then
		QueryOptions.Insert("subject", NStr("ru = 'Проверочный код подтверждения электронной почты в 1С';
													|en = 'Email confirmation code in 1C';"));
	EndIf;

	ResponseFields = New Structure;
	ResponseFields.Insert("req_id", "Id");
	ResponseFields.Insert("num", "CodeNumber");
	ResponseFields.Insert("life_time", "CodeValidityPeriod");
	ResponseFields.Insert("delay", "DelayBeforeResending");
	
	Return CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);
	
EndFunction

// Verify an email with a code.
//
// Parameters:
//  Id - String - ID.
//  Code - String - Code.
// 
// Returns:
//  Structure - Result.:
//  * Completed2 - Boolean
//  * ErrorCode - Number
//  * ErrorDescription - String
///
///
Function CheckEmailByCode(Id, Code) Export
	
	URL = ServiceAddress() + StrTemplate("/hs/verification/%1/email", SoftwareInterfaceVersion_v1_1());
	
	QueryOptions = New Structure("req_id,code", Id, Code);
	
	ResponseFields = New Structure;
	
	Return CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);

EndFunction

#EndRegion

#Region ChangingSettingsForReceivingTemporaryPasswordsByProvider

// Print the application.
//
// Parameters:
//  ApplicationID - String - Application ID.
//  CheckID - String - Check ID.
//  CertificateID - String - Certificate ID.
// 
// Returns:
//  Structure - Result.:
//  * Completed2 - Boolean
//  * ErrorCode - Number
//  * ErrorDescription - String
//
Function PrintStatement(ApplicationID, CheckID, CertificateID) Export
	
	URL = ServiceAddress() + StrTemplate("/hs/otp/%1/phone/request/%2",
										SoftwareInterfaceVersion_v1_1(),
										ApplicationID);
										
	QueryOptions = New Structure("client", GetClientDescription());
	QueryOptions.Insert("phone", CheckID);
	QueryOptions.Insert("cert_id", CertificateID);
	
	Result = CallHTTPMethod("POST", URL, QueryOptions, New Structure);
	If Result.Completed2 Then
		TempFileName = GetTempFileName("mxl");
		ResultData = Result.File; // BinaryData
		ResultData.Write(TempFileName);
		
		SpreadsheetDocument = New SpreadsheetDocument;
		SpreadsheetDocument.Read(TempFileName);
		
		DeleteFiles(TempFileName);
		
		Result.File = SpreadsheetDocument;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Send application.
//
// Parameters:
//  ApplicationID - String - Application ID.
//  ApplicationFile - String - Application file.
// 
// Returns:
//  Structure - Result.:
//  * Completed2 - Boolean
//  * ErrorCode - Number
//  * ErrorDescription - String
//
Function SendApplication(ApplicationID, ApplicationFile) Export
	
	URL = ServiceAddress() + StrTemplate("/hs/otp/%1/phone/request/%2",
										SoftwareInterfaceVersion_v1_1(),
										ApplicationID);
										
	Headers = New Map;
	Headers.Insert("Content-Disposition", 
		StrTemplate("attachment; filename=%1", EncodeString(ApplicationFile.Name, StringEncodingMethod.URLEncoding)));
		
	Result = CallHTTPMethod("PUT", URL, GetFromTempStorage(ApplicationFile.Address), New Structure, Headers);
	
	Return Result;
	
EndFunction

#EndRegion

#Region ChangingSettingsForObtainingTemporaryPasswordsByUser

// Start modifying settings of obtaining temporary passwords.
//
// Parameters:
//  CertificateID - String - Certificate ID.
//  Phone - String - Phone number.
//  Email - String - Email.
//  Id - String - ID.
// 
// Returns:
//  Structure - Result with the following fields:
// 	 * Id - String - 
// 	 * CodeValidityPeriod - Number - 
// 	 * DelayBeforeResending - Number -  
Function StartChangingSettingsForGettingTemporaryPasswords(CertificateID, Phone, Email, Id = "") Export
	
	URL = ServiceAddress() + StrTemplate("/hs/otp/%1/users_requests", SoftwareInterfaceVersion_v1_1());
	
	QueryOptions = New Structure("client", GetClientDescription());
	If ValueIsFilled(Id) Then
		QueryOptions.Insert("req_id", Id);
	Else
		QueryOptions.Insert("cert_id", CertificateID);
		If Phone <> Undefined Then
			QueryOptions.Insert("phone", Phone);
		EndIf;
		If Email <> Undefined Then
			QueryOptions.Insert("email", Email);
		EndIf;
	EndIf;

	ResponseFields = New Structure("req_id,life_time,delay", "Id", "CodeValidityPeriod", "DelayBeforeResending");
	
	Return CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);
	
EndFunction

// Finish modifying settings of obtaining temporary passwords.
//
// Parameters:
//  Id - String - ID.
//  Code - String - Code.
// 
// Returns:
//  Structure - Result.:
//  * Completed2 - Boolean
//  * ErrorCode - Number
//  * ErrorDescription - String
//
Function FinishChangingSettingsForGettingTemporaryPasswords(Id, Code) Export
			
	URL = ServiceAddress() + StrTemplate("/hs/otp/%1/user_request/%2", SoftwareInterfaceVersion_v1_1(), Id);
										
	QueryOptions = New Structure("req_id,code", Id, Code);
	
	Return CallHTTPMethod("PUT", URL, QueryOptions, New Structure);
	
EndFunction

#EndRegion

#Region CertificateApplications

// Creates a container for the private key and the certificate request.
//
// Parameters:
//	StatementParameters - Structure - Contains fields required to generate an application for certificate issuance:
// 	 * ApplicationID   - String - ID of a certificate request search.
//	 * RequestContent 		- String - Contains OID fields.
//	 * PhoneNumber			- String - Contains a confirmed phone ID.
//	 * Email			- String - Contains a confirmed email ID.
//	 * NotaryLawyerHeadOfFarm	- Boolean - 
//	 * SubscriberID	- String - ID.
//	ResultAddress - String - Temp storage address to add the result of the Structure function to.
// 
Procedure CreateContainerAndRequestCertificate(StatementParameters, ResultAddress) Export
	
	URL = ServiceAddress() + StrTemplate("/hs/certificate/new_request/%1", StatementParameters.ApplicationID);
	
	EncodedString 	= XDTOSerializer.XMLString(New ValueStorage(StatementParameters.RequestContent));
	QueryOptions 	= New Structure();
	QueryOptions.Insert("NotaryLawyerHeadOfFarm", StatementParameters.NotaryLawyerHeadOfFarm);
	QueryOptions.Insert("SubscriberID", StatementParameters.SubscriberID);
	QueryOptions.Insert("Email", StatementParameters.Email);
	QueryOptions.Insert("CellPhone", StatementParameters.PhoneNumber);
	QueryOptions.Insert("RequestContent", EncodedString);
	QueryOptions.Insert("client", GetClientDescription());
	
	ResponseFields 				= New Structure("request, public_key, provider, provtype", 
												"CertificateRequest", "PublicKey", "ProviderName", "ProviderType");
	ConversionParameters = New Structure("PropertiesToReviveNames", StrSplit("request,public_key", ","));
	Result				= CallHTTPMethod("PUT", URL, QueryOptions, ResponseFields, , ConversionParameters);
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure	

// Assigns a certificate to a private key in the cloud storage.
//
// Parameters:
//  StatementParameters - Structure - Contains fields required to generate an application for certificate issuance:
//   * ApplicationID   - String - ID of a certificate request search.
//   * CertificateData - BinaryData - Contains certificate data in the PEM encoding.
//
//  ResultAddress - String - Temp storage address to add the result of the Structure function to.
//
Procedure BindCertToContainerAndSystemStore(StatementParameters, ResultAddress) Export
	
	URL 		= ServiceAddress() + StrTemplate("/hs/certificate/initialize_request/%1", StatementParameters.ApplicationID);
	
	CertificateData		= CertificatesStorage.DERCertificate(StatementParameters.CertificateData, Chars.LF);
	QueryOptions 		= New Structure("data", CertificateData);
	ConversionParameters = New Structure("PropertiesToReviveNames", StrSplit("data", ","));
	
	ResponseFields 	= New Structure("success", "Success");
	Result	= CallHTTPMethod("PUT", URL, QueryOptions, ResponseFields, , ConversionParameters);
	
	Try
		If Result.Completed2 Then
			CertificatesStorage.Add(CertificateData, Enums.CertificatesStorageType.PersonalCertificates);	
		EndIf;
	Except
		Result.Completed2 = False;
		Result.Insert("ErrorCode", "ErrorAccessingServer");
		Result.Insert("ErrorDescription", CloudTechnology.ShortErrorText(ErrorInfo()));
		// @skip-check module-nstr-camelcase - Check error
		WriteLogEvent(
			NStr("ru = 'Электронная подпись в модели сервиса.Менеджер сервиса криптографии';
				|en = 'Digital signature SaaS.Cryptography service manager';", Common.DefaultLanguageCode()), 
			EventLogLevel.Error,,, CloudTechnology.DetailedErrorText(ErrorInfo()));
	EndTry;	
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

#EndRegion

#Region SubscriberCertificatesByVerificationIDTIN

//  Subscriber's certificates by TIN check ID.
// 
// Parameters: 
//  TIN - String
//  Id - String
//  OnlyValidOnes - Boolean - Only valid certificates.
// 
// Returns: 
//  Structure - Subscriber's certificates by TIN check ID.:
// * Certificates - Array of Structure:
// 	  ** ID - String
// Or, if an error occurred: 
// * ErrorDescription - String
// * ErrorCode - String
// * Completed2 - Boolean
Function SubscriberCertificatesByVerificationIDTIN(TIN, Id, OnlyValidOnes = True) Export
	
	URL = ServiceAddress() + StrTemplate("/hs/requests/%1/abonent_certificates", SoftwareInterfaceVersion_v2_0());
	
	QueryOptions = New Structure("client", GetClientDescription());
	QueryOptions.Insert("req_id", Id);
	QueryOptions.Insert("inn", TIN);
	QueryOptions.Insert("valid", OnlyValidOnes);

	ResponseFields = New Structure("certificates", "Certificates");
	
	Result = CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);
	
	If Result.Completed2 Then 
		For Each Certificate In Result.Certificates Do 
			Certificate.ValidTo = XMLValue(Type("Date"), Certificate.ValidTo);
			Certificate.ValidFrom = XMLValue(Type("Date"), Certificate.ValidFrom);
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region CertificateSearch

// Search for a certificate by thumbprint or ID.
// 
// Parameters: 
//  Thumbprint - String
//  SerialNumber - String
//  Abbreviated - Boolean
// 
// Returns: 
//  Structure :
// * Completed2 - Boolean
// * ErrorCode - String
// * ErrorDescription - String
Function SearchForCertificateByFingerprintOrSerialNumber(
			Thumbprint = Undefined, 
			SerialNumber = Undefined, 
			Abbreviated = False) Export
	
	URL = ServiceAddress() + StrTemplate("/hs/requests/%1/find_certificate", SoftwareInterfaceVersion_v2_0());
	
	QueryOptions = New Structure("client", GetClientDescription());
	If ValueIsFilled(Thumbprint) Then 
		QueryOptions.Insert("thumbprint", Thumbprint);
	EndIf;
	If ValueIsFilled(SerialNumber) Then 
		QueryOptions.Insert("serialnumber", SerialNumber);
	EndIf;
	If Abbreviated Then 
		QueryOptions.Insert("important_only", True);
	EndIf;
	
	If Not ValueIsFilled(Thumbprint) And Not ValueIsFilled(SerialNumber) Then 
		Return New Structure("Completed2, ErrorCode, ErrorDescription", 
						False, 
						"ParametersNotFilledIn", 
						NStr("ru = 'Необходимо заполнить thumbprint или serialnumber.';
							|en = 'Fill in thumbprint or serialnumber.';", Common.DefaultLanguageCode()));
	EndIf;
	
	ResponseFields = New Structure("certificates", "Certificates");
	
	Result = CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);
	
	If Result.Completed2 Then 
		For Each Certificate In Result.Certificates Do 
			If Not Certificate.Property("ValidTo") Then 
				Continue;
			EndIf;
			Certificate.ValidTo = XMLValue(Type("Date"), Certificate.ValidTo);
			Certificate.ValidFrom = XMLValue(Type("Date"), Certificate.ValidFrom);
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function GetClientDescription()
	
	ClientDescription = New Structure;
	ClientDescription.Insert("version", Metadata.Version);
	ClientDescription.Insert("name", Metadata.Name);
	ClientDescription.Insert("id", Format(SaaSOperations.SessionSeparatorValue(), "NG="));
	
	Return ClientDescription;
	
EndFunction

// Get connection parameters.
// 
// Parameters:
//  URL - String
// 
// Returns: See CommonClientServer.URIStructure
Function GetConnectionParameters(URL) Export
	
	ConnectionParameters = CommonClientServer.URIStructure(URL);
	ConnectionParameters.Schema = ?(ValueIsFilled(ConnectionParameters.Schema), ConnectionParameters.Schema, "http");	
	ConnectionParameters.Insert("Timeout", 180);
	
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID(Metadata.Constants.DigitalSignatureAddingServiceAddressSaaS);
	ConnectionParameters.Insert("Login", Common.ReadDataFromSecureStorage(Owner, "Login", True));
	ConnectionParameters.Insert("Password", Common.ReadDataFromSecureStorage(Owner, "Password", True));
	SetPrivilegedMode(False);
	
	Return ConnectionParameters;
	
EndFunction

Function ServiceAddress()
	
	SetPrivilegedMode(True);

	Return Constants.DigitalSignatureAddingServiceAddressSaaS.Get();
	
EndFunction

Function SoftwareInterfaceVersion_v1_1()
	
	Return "v1.1";
	
EndFunction

Function SoftwareInterfaceVersion_v2_0()
	
	Return "v2.0";
	
EndFunction

Function CallHTTPMethod(HTTPMethod, URL, QueryOptions, MatchingResponseFields, Headers = Undefined, ConversionParameters = Undefined)
	
	Result = New Structure;	
	
	ConnectionParameters = GetConnectionParameters(URL);
	Try
		Join = DigitalSignatureSaaS.ConnectingToInternetServer(ConnectionParameters);
	Except
		ErrorInfo = ErrorInfo();
		// @skip-check module-nstr-camelcase - Check error.
		WriteLogEvent(
			NStr("ru = 'Электронная подпись в модели сервиса.Менеджер сервиса криптографии';
				|en = 'Digital signature SaaS.Cryptography service manager';", Common.DefaultLanguageCode()), 
			EventLogLevel.Error,,, CloudTechnology.DetailedErrorText(ErrorInfo));
			
		Result.Insert("Completed2", False);
		Result.Insert("ErrorCode", "CouldnTEstablishConnection");
		Result.Insert("ErrorDescription", NStr("ru = 'Не удалось установить соединение с сервером.';
													|en = 'Cannot connect to the server.';"));		
		Return Result;
	EndTry;

	Query = New HTTPRequest(ConnectionParameters.PathAtServer);
	If TypeOf(QueryOptions) = Type("Structure") Then
		Query.Headers.Insert("Content-Type", "application/json");
		Query.SetBodyFromString(DigitalSignatureSaaS.StructureInJSON(QueryOptions));
	ElsIf TypeOf(QueryOptions) = Type("BinaryData") Then
		Query.Headers.Insert("Content-Type", "application/octet-stream");
		Query.SetBodyFromBinaryData(QueryOptions);
	EndIf;
	If ValueIsFilled(Headers) Then
		For Each Title In Headers Do
			Query.Headers.Insert(Title.Key, Title.Value);
		EndDo;
	EndIf;
	
	Try
		Response = Join.CallHTTPMethod(HTTPMethod, Query);
	Except
		ErrorInfo = ErrorInfo();
		// @skip-check module-nstr-camelcase - Check error.
		WriteLogEvent(
			NStr("ru = 'Электронная подпись в модели сервиса.Менеджер сервиса криптографии';
				|en = 'Digital signature SaaS.Cryptography service manager';", Common.DefaultLanguageCode()), 
			EventLogLevel.Error,,, CloudTechnology.DetailedErrorText(ErrorInfo));
		
		Result.Insert("Completed2", False);
		Result.Insert("ErrorCode", "ErrorAccessingServer");
		Result.Insert("ErrorDescription", CloudTechnology.DetailedErrorText(ErrorInfo));		
		Return Result;
	EndTry;

	If Response.StatusCode = 200 Then
		Result.Insert("Completed2", True);
		
		ContentType = CommonCTL.HTTPHeader(Response, "Content-Type");
		
		If (ContentType = "application/json") Or (ContentType = "application/javascript") Then
			AnswerParameters = DigitalSignatureSaaS.JSONToStructure(Response.GetBodyAsString(), ConversionParameters);
			For Each Field In MatchingResponseFields Do
				If AnswerParameters.Property(Field.Key) Then
					Result.Insert(Field.Value, AnswerParameters[Field.Key]);
				EndIf;
			EndDo;
		ElsIf ContentType = "application/octet-stream" Then
			Result.Insert("File", Response.GetBodyAsBinaryData());
			Result.Insert("Name", StrReplace(CommonCTL.HTTPHeader(Response, "Content-Disposition"), "attachment; filename=", ""));
		EndIf;
	ElsIf Response.StatusCode = 400 Then
		Result.Insert("Completed2", False);
		AnswerParameters = DigitalSignatureSaaS.JSONToStructure(Response.GetBodyAsString());
		Result.Insert("ErrorCode", GetErrorCode(AnswerParameters.err_code));
		Result.Insert("ErrorDescription", TrimAll(AnswerParameters.err_msg));
	Else
		// @skip-check module-nstr-camelcase - Check error.
		WriteLogEvent(
			NStr("ru = 'Электронная подпись в модели сервиса.Менеджер сервиса криптографии';
				|en = 'Digital signature SaaS.Cryptography service manager';", Common.DefaultLanguageCode()), 
			EventLogLevel.Error,,, Response.GetBodyAsString());
		Result.Insert("Completed2", False);
		Result.Insert("ErrorCode", "UnknownError");
		Result.Insert("ErrorDescription", NStr("ru = 'Сервис временно недоступен. Обратитесь в службу поддержки или повторите попытку позже.';
													|en = 'The service is temporarily unavailable. Contact the technical support or try again later.';"));
	EndIf;
	
	Return Result;
	
EndFunction

Function GetErrorCode(err_code)
	
	ErrorCodes = New Map;
	ErrorCodes.Insert("CertificateNotFound", "CertificateNotFound");
	ErrorCodes.Insert("RequestNotFound", "ApplicationNotFound");
	ErrorCodes.Insert("NewPhoneIsEqualToTheCurrent", "NewPhoneIsEqualToCur");
	ErrorCodes.Insert("NewEmailIsEqualToTheCurrent", "NewEmailIsEqualToCur");
	ErrorCodes.Insert("MaxAttemptsInputCodeExceeded", "CodeAttemptLimitExceeded");
	ErrorCodes.Insert("CodeExpired", "CodeExpired");
	ErrorCodes.Insert("CodeIsWrong", "InvalidCode");
	ErrorCodes.Insert("TooFrequentCodeRequests", "ReSendingTooOften");
	
	ErrorCode = ErrorCodes.Get(err_code);
	If Not ValueIsFilled(ErrorCode) Then
		ErrorCode = err_code;
	EndIf;
	
	Return ErrorCode;
	
EndFunction

#EndRegion

