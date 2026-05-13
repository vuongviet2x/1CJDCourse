///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The Online Support subsystem.
// CommonModule.OnlineUserSupport.
//
// Server procedures and functions:
//  - Define app settings and service connection settings
//  - Handle authentication in Online Support services
//  - Set up authentication in Online Support services
//  - Navigate to integrated websites
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Common

// Returns a name, by which the application is identified in
// online support services.
//
// Returns:
//  String - an application name. <Blank string> if the application name is not filled in.
//
Function ApplicationName() Export
	
	Result = InternalApplicationName();
	Return ?(Result = "Unknown", "", Result);
	
EndFunction

// Returns settings of connection to online support servers.
//
// Returns:
//  Structure - Connection settings. Structure fields:
//    * EstablishConnectionAtServer - Boolean - True if connection
//      is established on 1C:Enterprise server.
//    * ConnectionTimeout - Number - Timeout of connection to servers in seconds.
//    * OUSServersDomain - Number - if 0, connect
//      to OUS servers in 1c.ru domain zone. If 1, connect in 1c.eu domain zone.
//
Function ServersConnectionSettings() Export
	
	Return OnlineUserSupportInternalCached.OUSServersConnectionSettings();
	
EndFunction

#EndRegion

#Region OnlineSupportServicesAuthentication

// Returns the username and password of an Online Support user from the infobase.
// Before calling, the calling code must set the privileged mode.
//
// Returns:
//  Structure - Structure - The user's username and password.:
//    * Login - String - Username of an online support user.
//    * Password - String - Password of online support user.
//  Undefined - if saved authentication data is missing.
//
Function OnlineSupportUserAuthenticationData() Export

	DataInSafeStorage = Common.ReadDataFromSecureStorage(
		SubsystemID(),
		"login,password");

	If DataInSafeStorage.login <> Undefined
		And DataInSafeStorage.password <> Undefined Then
		Return New Structure(
			"Login, Password",
			DataInSafeStorage.login,
			DataInSafeStorage.password);
	EndIf;

EndFunction

// Returns a user authentication ticket on the support portal.
// The returned ticket can be checked by calling the checkTicket operation
// of the https://login.1c.ru or https://login.1c.eu service
//
// For details, See https://login.1c.ru/rest/public/swagger
//
// -ui.html.
// Ticket is received according to the library settings
//  - Server domain zone (1c.ru or 1c.eu).
// The calling code must set the privileged mode prior to making the call.
//
// Parameters:
//  TicketOwner - String - an arbitrary name of a service, for which
//      user authentication is performed. The same name must be
//      used when calling the checkTicket operation.
//      Parameter value is required.
//
// Returns:
//  Structure - The result of receiving a ticket. Structure fields:
//        * Ticket1 - String - Received authentication ticket. If when receiving a ticket,
//          an error occurred (incorrect username or password or other error),
//          a field value is a blank row.
//        * ErrorCode - String - String code of the occurred error that
//          can be processed by the calling functionality:
//              - <Пустая строка> - a ticket is successfully received.
//              - "НеверныйЛогинИлиПароль" - invalid username or password.
//              - "ПревышеноКоличествоПопыток" - you exceeded the limit of attempts to
//                 get a ticket with invalid username and password.
//              - "ОшибкаПодключения" - an error occurred when connecting to the service.
//              - "ОшибкаСервиса" - an internal service error.
//              - "НеизвестнаяОшибка" - an unknown error occurred
//                 when getting the ticket (an error that cannot be processed),
//              - "ОперацияНеПоддерживается" - The service is not integrated with 1C:ITS Portal.
//                The error might occur in the SaaS mode.
//        * ErrorMessage - String - brief details of an error, which
//          can be displayed to user,
//        * ErrorInfo - String - details of an error, which
//          can be written to the event log.
//
Function AuthenticationTicketOnSupportPortal(TicketOwner) Export

	If Not ValueIsFilled(TicketOwner) Then
		Raise NStr("ru = 'Не заполнено значение параметра ""ВладелецТикета""';
								|en = 'The TicketOwner parameter is blank.';");
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		
		// SaaS.
		ModuleOnlineUserSupportSaaS =
			Common.CommonModule("OnlineUserSupportSaaS");
		Result = ModuleOnlineUserSupportSaaS.AuthenticationTicketOnSupportPortal(
			TicketOwner);
		
	Else
		
		Result = InternalAuthenticationTicket(
			"",
			"",
			TicketOwner,
			ServersConnectionSettings());
		
	EndIf;
	
	Return Result;
	
EndFunction

// Checks filling of authentication data of
// an online support user.
//
// Returns:
//  Boolean - indicates whether authentication data is filled.
//      True - authentication data is filled,
//      otherwise, False.
//
Function AuthenticationDataOfOnlineSupportUserFilled() Export
	
	If Common.DataSeparationEnabled() Then
		Return True;
	EndIf;
	
	SetPrivilegedMode(True);
	Return (OnlineSupportUserAuthenticationData() <> Undefined);
	
EndFunction

#EndRegion

#Region SettingUpAuthentication

// Checks authentication data of
// an online support user.
//
// Parameters:
//  Login - String - Username of an online support user;
//  Password - String - Password of an online support user.
//
// Returns:
//  Structure - Authentication data check result:
//   *Result - Boolean - Check result, if True, a username and a password are entered correctly,
//   *ErrorCode - String - an error ID if a username and a password are entered correctly
//                or errors occurred during the check;
//   *ErrorMessage - String - details of an error that occurred when checking authentication data.
//
Function CheckUsernameAndPassword(Login, Password) Export
	
	Result = New Structure("ErrorCode, ErrorMessage, Result", "", "", False);
	
	AuthenticationData = New Structure;
	AuthenticationData.Insert("Login", Login);
	AuthenticationData.Insert("Password", Password);
	
	CheckResult = OnlineUserSupportClientServer.VerifyAuthenticationData(
		AuthenticationData);
	If CheckResult.Cancel Then
		Result.ErrorCode = "InvalidUsernameOrPassword";
		Result.ErrorMessage = CheckResult.ErrorMessage;
		Return Result;
	EndIf;
	
	ServersConnectionSettings = ServersConnectionSettings();
	URLOfService = PasswordsCheckServiceURL(ServersConnectionSettings.OUSServersDomain);
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/json");
	
	AdditionalRequestParameters = New Structure;
	AdditionalRequestParameters.Insert("Method"                   , "POST");
	AdditionalRequestParameters.Insert("Headers"               , Headers);
	AdditionalRequestParameters.Insert("AnswerFormat"            , 1);
	AdditionalRequestParameters.Insert("DataForProcessing"      , AuthJSONParameters(Login, Password));
	AdditionalRequestParameters.Insert("DataFormatToProcess", 1);
	AdditionalRequestParameters.Insert("Timeout"                 , 30);
	
	FileGetResult = DownloadContentFromInternet(
		URLOfService,
		,
		,
		AdditionalRequestParameters);
	
	If FileGetResult.StatusCode = 200 Then
		
		Result.Result = True;
		
	ElsIf FileGetResult.StatusCode = 403 Then
		
		Result.ErrorCode = "InvalidUsernameOrPassword";
		Result.ErrorMessage = NStr("ru = 'Неверный логин или пароль.';
											|en = 'Incorrect username or password.';");
		
	ElsIf FileGetResult.StatusCode = 429 Then
		
		Result.ErrorCode = "AttemptLimitExceeded";
		Result.ErrorMessage = NStr("ru = 'Превышено количество попыток ввода логина и пароля.
			|Проверьте правильность указанных данных и повторите
			|попытку через 30 минут.';
			|en = 'Exceeded maximum number of login attempts.
			|Make sure the data is specified correctly and
			|try again in 30 minutes.';");
		
	Else
		
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось проверить логин и пароль в сервисе %1. %2';
					|en = 'Cannot check username and password on service %1. %2';"),
				URLOfService,
				FileGetResult.ErrorInfo));
		
		Result.ErrorCode         = FileGetResult.ErrorCode;
		Result.ErrorMessage = FileGetResult.ErrorMessage;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Saves a username and a password in the secure storage in the Online Support subsystem.
// Before writing the data, the calling code must do the following:
// - Call OnlineUserSupport.CanConnectOnlineUserSupport
//   - to ensure the availability of Online Support.
//     - Call either OnlineUserSupportClientServer.CheckAuthenticationData 
//   - or OnlineUserSupport.CheckUsernameAndPassword
//     to validate the credentials data.
//     - Set the privileged mode.
//   - When developing a custom Online Support connection form,
//
// to minimize confidential data on the client,
// make sure the form deletes the user input.
// 
//
// Parameters:
//  AuthenticationData - Structure, Undefined - Password - String - Password of an online support user. 
//  
//  
//   
//   Password - String - Password of an online support user.
//
Procedure SaveAuthenticationData(AuthenticationData) Export
	
	If Not CanConnectOnlineUserSupport() Or Not PrivilegedMode() Then
		Raise NStr("ru = 'Подключение Интернет-поддержки недоступно.';
								|en = 'Online support is unavailable.';");
	EndIf;
	
	If AuthenticationData <> Undefined Then
		CheckResult = OnlineUserSupportClientServer.VerifyAuthenticationData(
			AuthenticationData);
		If CheckResult.Cancel Then
			Raise CheckResult.ErrorMessage;
		EndIf;
	EndIf;
	
	ServiceSaveAuthenticationData(AuthenticationData);
	
EndProcedure

// Indicates whether the current user can interactively
// connect to online support, based on the current operation mode
// and user rights.
//
// Returns:
//  Boolean - If True, interactive connection is available.
//           Otherwise, False.
//
Function CanConnectOnlineUserSupport() Export
	
	If Common.DataSeparationEnabled() Then
		Return False;
	EndIf;
	
	If Users.RolesAvailable("CanEnableOnlineSupport", , False) Then
		Return True;
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.Connecting1CTaxi") Then
		ModuleOneCTaxcomConnectionServerCall = Common.CommonModule("Подключение1СТакскомВызовСервера");
		If ModuleOneCTaxcomConnectionServerCall.YouCanUse1CTaxiService() Then
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#Region ClickOnLinks

// Returns a URL to go to a page of the website whose authentication system
// is integrated with 1C:ITS portal.
// Depending on the current infobase mode and whether
// the current infobase user has the appropriate rights,
// the page can be opened with accountant data of 1C:ITS Portal user,
// for which online support is enabled.
// If there is no access, inconsistency of the operation mode, or occurrence of errors,
// the passed URL is returned unchanged.
//
// Important. The received URL must be used right after receiving as
// a URL is valid during a short period of time (calculated in seconds).
//
// Parameters:
//  WebsitePageURL - String - Website page URL.
//
// Returns:
//  String - a URL to navigate to a website page.
//
Function URLToNavigateToIntegratedWebsitePage(WebsitePageURL) Export
	
	URLGetResult = InternalURLToNavigateToIntegratedWebsitePage(WebsitePageURL);
	Return URLGetResult.URL;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

#Region Authentication

// Generates a title for the "Basic" authentication scheme.
//
// Parameters:
//  Login - String - The username of a FPS participant.
//  Password - String - The password of a FPS participant.
//
// Returns:
//  String - Authentication title.
//
Function AuthenticationBasicSchemeHeader(Login, Password) Export
	
	Title = "Basic "
		+ GetBase64StringFromBinaryData(
			GetBinaryDataFromString(
				Login + ":" + Password));
	
	Return StrReplace(
		StrReplace(
			Title,
			Chars.CR,
			""),
		Chars.LF,
		"");
	
EndFunction

// Generates a title for the "Bearer" authentication scheme.
//
// Parameters:
//  Token - String - The token of a FPS participant.
//
// Returns:
//  String - Authentication title.
//
Function AuthenticationBearerHeader(Token) Export
	
	Return "Bearer " + Token;
	
EndFunction

#EndRegion

#Region UtilityGeneralPurpose

// Saves a username and password in the secure storage in the "Online support" subsystem.
//  Before writing the data,
// check access rights and set the privileged mode in the calling code.
//
// Parameters:
// AuthenticationData - Structure, Undefined - Password - String - Password of an online support user. 
//                        
//                        
//   
//   Password - String - Password of an online support user.
//
Procedure ServiceSaveAuthenticationData(AuthenticationData) Export
	
	If AuthenticationData = Undefined Then
		
		// Deleting all data for a username from the safe storage.
		Common.DeleteDataFromSecureStorage(SubsystemID());
		
		WriteInformationToEventLog(
			NStr("ru = 'Очищены данные аутентификации.';
				|en = 'Authentication credentials are cleared.';"),
			Undefined,
			False);
		
		OnChangeAuthenticationData(
			"",
			"");
		
	Else
	
		// Writing data to safe storage
		SubsystemID1 = SubsystemID();
		BeginTransaction();
		Try
			Common.DeleteDataFromSecureStorage(SubsystemID1);
			Common.WriteDataToSecureStorage(
				SubsystemID1,
				AuthenticationData.Login,
				"login");

			Common.WriteDataToSecureStorage(
				SubsystemID1,
				AuthenticationData.Password,
				"password");
			CommitTransaction();
		Except
			RollbackTransaction();
			WriteInformationToEventLog(
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Raise;
		EndTry;
		
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Записаны данные аутентификации, логин ""%1"".';
					|en = 'Authentication credentials are written, the %1 username.';"),
				AuthenticationData.Login),
			Undefined,
			False);
		
		OnChangeAuthenticationData(
			AuthenticationData.Login,
			AuthenticationData.Password);
		
	EndIf;
	
EndProcedure

// Checks whether the passed object has the CatalogObject.MetadataObjectIDs type.
//
// Parameters:
//  Object - Arbitrary - an object to be checked.
//
// Returns:
//  Boolean - if True, the type matches CatalogObject.MetadataObjectIDs.
//
Function IsMetadataObjectID(Object) Export
	
	Return TypeOf(Object) = Type("CatalogObject.MetadataObjectIDs");
	
EndFunction

// Returns a flag indicating if there are any common separators in the configuration.
//
// Returns:
//   Boolean - True if the configuration is separated.
//
Function IsSeparatedConfiguration() Export
	
	Return OnlineUserSupportInternalCached.IsSeparatedConfiguration();
	
EndFunction

// Determines if the session was started without separators.
//
// Returns:
//   Boolean - If True, the session is started without separators.
//
Function SessionWithoutSeparators() Export
	
	Return OnlineUserSupportInternalCached.SessionWithoutSeparators();
	
EndFunction

// Returns a session separator value.
//
// Returns:
//  Number - a separator value.
//
Function SessionSeparatorValue() Export
	
	If Not Common.DataSeparationEnabled() Then
		Return 0;
	EndIf;
	
	ModuleOSLSaaS = Common.CommonModule("SaaSOSL");
	Return ModuleOSLSaaS.SessionSeparatorValue();
	
EndFunction

// Returns an application name in online support services.
//
// Returns:
//  String - an application name.
//
Function InternalApplicationName() Export
	
	Result = Common.ConfigurationOnlineSupportID();
	If Result = Undefined Or IsBlankString(Result) Then
		Result = "Unknown";
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a configuration synonym to use in other subsystems.
//
// Returns:
//  String - an application synonym.
//
Function ConfigurationSynonym() Export
	
	Return Metadata.Synonym;
	
EndFunction

// Checks if it is possible to change the online support parameters.
//
// Returns:
//  Boolean - True if the current user has a right to write the OUS parameters.
//           Otherwise, False.
//
Function RightToWriteOUSParameters() Export

	Return Users.IsFullUser(, , False)
		Or Users.RolesAvailable("CanEnableOnlineSupport", , False)
		Or Common.SubsystemExists("OnlineUserSupport.Connecting1CTaxi")
		And Users.RolesAvailable("Taxcom1CServiceUsage", , False);

EndFunction

// Incrementally calculates hash and encoding into base64 format.
// Calculation method and type of the value being calculated are determined by the hash function type.
//
// Parameters:
//  Data  - String, BinaryData - data for calculating a hash sum.
//
// Returns:
//  String - a calculated hash sum encoded by the base64 algorithm.
//
Function FileChecksum(Data) Export
	
	DataHashing = New DataHashing(HashFunction.MD5);
	If TypeOf(Data) = Type("BinaryData") Then
		DataHashing.Append(Data);
	ElsIf TypeOf(Data) = Type("String") Then
		DataHashing.AppendFile(Data);
	Else
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Некорректное значение параметра Данные (%1)';
				|en = 'Incorrect value of the Data parameter (%1)';"),
			String(Data));
		Raise ExceptionText;
	EndIf;
		
	Return Base64String(DataHashing.HashSum);
	
EndFunction

// Returns a subsystem ID in the catalog of metadata
// objects.
//
// Returns:
//  String - a subsystem ID.
//
Function SubsystemID() Export
	
	Return "OnlineUserSupport.CoreISL";
	
EndFunction

// Returns the Metadata.Name property value
//
// Returns:
//  String - Configuration name.
//
Function ConfigurationName() Export

	Return Metadata.Name;

EndFunction

// Returns the Metadata.Version property value
//
// Returns:
//  String - Configuration version.
//
Function ConfigurationVersion() Export
	
	ApplicationVersion = Metadata.Version;
	OSLSubsystemsIntegration.WhenDeterminingTheVersionNumberOfTheProgram(
		ApplicationVersion);
	OnlineUserSupportOverridable.WhenDeterminingTheVersionNumberOfTheProgram(
		ApplicationVersion);
	
	Return ApplicationVersion;
	
EndFunction

// Checks availability of the passed URL by the following criteria:
//  - Response code is 200;
//  - Response timeout is 10 seconds.
//
// Parameters:
//  URL - String - URL to be checked;
//  ProxyServerSettings - Structure, Undefined - proxy settings;
//  Method - String - HTTP check method.
//
// Returns:
//  Boolean - True if URL is available.
//
Function CheckURLAvailable(
		URL,
		ProxyServerSettings = Undefined,
		Method = Undefined) Export
	
	CheckResult = New Structure;
	CheckResult.Insert("ErrorName"         , "");
	CheckResult.Insert("ErrorMessage" , "");
	CheckResult.Insert("ErrorInfo", "");
	If ProxyServerSettings = Undefined Then
		Try
			OnlineUserSupportInternalCached.CheckURLAvailable(
				URL,
				Method,
				CheckResult.ErrorName,
				CheckResult.ErrorMessage,
				CheckResult.ErrorInfo);
		Except
			Return CheckResult;
		EndTry;
	Else
		InternalCheckURLAvailable(
			URL,
			Method,
			CheckResult.ErrorName,
			CheckResult.ErrorMessage,
			CheckResult.ErrorInfo,
			ProxyServerSettings);
	EndIf;
	
	Return CheckResult;
	
EndFunction

// Returns a number of 1C:Enterprise platform version.
//
// Returns:
//  String - a platform version.
//
Function Current1CPlatformVersion() Export
	
	SystInfo = New SystemInfo;
	Return SystInfo.AppVersion;
	
EndFunction

// Checks a host for URL received  from external sources.
//
// Parameters:
//  URL - String - URL from an external source.
//
Procedure CheckURL(URL) Export
	
	URIStructure = CommonClientServer.URIStructure(URL);
	HostDomain = Right(Lower(TrimAll(URIStructure.Host)), 6);
	If HostDomain <> ".1c.ru" And HostDomain <> ".1c.eu" Then
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неизвестный хост (%1)';
				|en = 'Unknown host (%1)';"),
			URIStructure.Host);
		Raise ExceptionText;
	EndIf;
	
EndProcedure

// Supplements a JSON record with additional parameters.
//
// Parameters:
//  AdditionalRequestParameters - Structure - additional query parameters.
//  MessageDataWriter - JSONWriter - Write stream of query to the service.
//
Procedure WriteAdditionalQueryParameters(AdditionalRequestParameters, MessageDataWriter) Export
	
	MessageDataWriter.WritePropertyName("additionalParameters");
	MessageDataWriter.WriteStartArray();
	For Each KeyValue In AdditionalRequestParameters Do
		MessageDataWriter.WriteStartObject();
		MessageDataWriter.WritePropertyName("key");
		MessageDataWriter.WriteValue(KeyValue.Key);
		MessageDataWriter.WritePropertyName("value");
		MessageDataWriter.WriteValue(String(KeyValue.Value));
		MessageDataWriter.WriteEndObject();
	EndDo;
	MessageDataWriter.WriteEndArray();
	
EndProcedure

// Pauses the code execution for the specified time.
//
// Parameters:
//  Seconds - Number - Suspend time in seconds.
//
Procedure Pause(Seconds) Export
	
	CurrentInfobaseSession1 = GetCurrentInfoBaseSession();
	BackgroundJob = CurrentInfobaseSession1.GetBackgroundJob();
	
	If BackgroundJob = Undefined Then
		Parameters = New Array;
		Parameters.Add(Seconds);
		BackgroundJob = BackgroundJobs.Execute("OnlineUserSupport.Pause", Parameters);
	EndIf;
	
	BackgroundJob.WaitForExecutionCompletion(Seconds);
	
EndProcedure

// Writes an information message to the event log
// with the User online support.Error event name.
//
// Parameters:
//  Message - String - String presentation of the error.
//  Data - Arbitrary - data to which an error message refers.
//  Error - Boolean - defines event log level.
//
Procedure WriteInformationToEventLog(
		Message,
		Data = Undefined,
		Error = True) Export
	
	ELLevel = ?(Error, EventLogLevel.Error, EventLogLevel.Information);
	
	WriteLogEvent(
		EventLogEventName(),
		ELLevel,
		,
		Data,
		Message);
	
EndProcedure

#EndRegion

#Region Tariffication

// Defines whether the service is available by the passed ID
//
// Parameters:
//  ServiceID  - String - Service ID in the service;
//  SeparatorValue - Number - Data area ID.
//
// Returns:
//  Boolean - if True, the service is available.
//
Function ServiceActivated(ServiceID, SeparatorValue = Undefined) Export
	
	If Not Common.DataSeparationEnabled() Then
		// The hosted mode has no tools for checking in infobase data.
		// 
		Return True;
	Else
		
		SeparationRequired = Not Common.SeparatedDataUsageAvailable();
		If SeparationRequired Then
			If SeparatorValue = Undefined Then
				Raise NStr("ru = 'Не заполнено значение параметра ""ЗначениеРазделителя"".';
										|en = 'The SeparatorValue parameter is blank.';");
			EndIf;
			ModuleOSLSaaS = Common.CommonModule("SaaSOSL");
			ModuleOSLSaaS.SetSessionSeparation(True, SeparatorValue);
		EndIf;
		
		ModuleTariffication = Common.CommonModule("Tariffication");
		Result = ModuleTariffication.UnlimitedServiceLicenseRegistered(
			OnlineUserSupportClientServer.ServiceProviderID1sitsPortal(),
			ServiceID);
		
		If SeparationRequired Then
			ModuleOSLSaaS.SetSessionSeparation(False);
		EndIf;
		
		If Not Result Then
			WriteInformationToEventLog(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Услуга с идентификатором %1 не подключена.';
						|en = 'Service with the %1 ID is not connected.';"),
					ServiceID),
				Undefined,
				False);
		EndIf;
		
		Return Result;
		
	EndIf;
	
EndFunction

#EndRegion

#Region GetContentFromInternet

// Imports content from the Internet via HTTP(S)
// using the GET, POST, or PUT methods. Supports
// redirection processing.
//
// Parameters:
//  URL - String - URL of the operation called;
//  Login - String - Username upon basic authentication;
//  Password - String - Password upon basic authentication.
//  QueryOptions - Structure, Undefined - specifying query parameters:
//   *AnswerFormat - Number - defines a return format of the operation response content:
//      - 0 - response file name (default response format);
//      - 1 - as a string,
//      - 2 - as binary data.
//   *Method - String - an HTTP method: "GET", "POST", or "PUT". GET is used by default;
//   *DataForProcessing - String, BinaryData - data for sending methods
//                         that is sent using the POST or PUT method;
//   *DataFormatToProcess - Number - data sending format:
//      - 0 - a file name (default response format);
//      - 1 - as a string,
//      - 2 - as binary data.
//   *Headers - Map - query headers.
//   *RespondFileName - String - path to the file for writing the result;
//   *Timeout - Number - time-out of the operation completion
//   *ProxySettings - Structure - proxy server connection settings.
//
// Returns:
//   Structure - Contains the operation result:
//    *ErrorCode - String - an error ID.
//    *ErrorMessage - String - error details for the user.
//    *ErrorInfo - String - error details for the administrator.
//    *Content - String, BinaryData, Undefined - Response body.
//    *StatusCode - Number - a HTTP status code that the server returned;
//    *AnswerFormat - Number - defines a return format of the operation response content:
//      - 0 - a response file name,
//      - 1 - as a string,
//      - 2 - as binary data.
//   *Headers - Map - response headers.
//
Function DownloadContentFromInternet(
		Val URL,
		Val Login = Undefined,
		Val Password = Undefined,
		QueryOptions = Undefined) Export
	
	Result = New Structure;
	Result.Insert("ErrorCode"         , "");
	Result.Insert("ErrorMessage" , "");
	Result.Insert("ErrorInfo", "");
	Result.Insert("Content"        , Undefined);
	Result.Insert("StatusCode"      , 0);
	Result.Insert("AnswerFormat"      , 0);
	Result.Insert("Headers"         , New Map);
	
	ReceivingParameters = New Structure;
	ReceivingParameters.Insert("AnswerFormat"            , 0);
	ReceivingParameters.Insert("Method"                   , "GET");
	ReceivingParameters.Insert("DataForProcessing"      , Undefined);
	ReceivingParameters.Insert("DataFormatToProcess", 0);
	ReceivingParameters.Insert("Headers"               , Undefined);
	ReceivingParameters.Insert("RespondFileName"          , Undefined);
	ReceivingParameters.Insert("Timeout"                 , -1);
	ReceivingParameters.Insert("ProxySettings"         , Undefined);
	ReceivingParameters.Insert("IsPackageDeliveryCheckOnErrorEnabled", True);
	
	If QueryOptions <> Undefined Then
		FillPropertyValues(ReceivingParameters, QueryOptions);
	EndIf;
	 
	If ReceivingParameters.Timeout = -1 Then
		// Default timeout.
		ReceivingParameters.Timeout = 30;
	EndIf;
	
	Result.AnswerFormat = ReceivingParameters.AnswerFormat;
	
	RedirectionsCount  = 0;
	MaxRedirectionsCount   = 7;
	Redirections            = New Array;
	ExecutedRedirections = New Map;
	ProxyBySchemes             = New Map;
	SecureConnectionCache    = Undefined;
	
	If Not CanManageHost(URL) Then
		
		ThereIsRightOfAdministration = Users.IsFullUser(, True, False);
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Обращение к сервисам Интернет-поддержки запрещено. %1';
				|en = 'Accessing online support services is not allowed. %1';"),
			?(ThereIsRightOfAdministration,
				NStr("ru = 'См. Журнал регистрации';
					|en = 'See the event log.';"),
				NStr("ru = 'Обратитесь к администратору.';
					|en = 'Please contact the administrator.';")));
		ErrorInfo = NStr("ru = 'Обращение к сервисам Интернет-поддержки запрещено.
			|Для разрешения работы с сервисами откройте раздел Интернет-поддержка и сервисы и нажмите ""Настроить"".';
			|en = 'Accessing online support services is not allowed.
			|To allow operations with the services, open the Online support and services section and click Configure.';");
			
		SetErrorDescription(
			Result,
			"0",
			ErrorMessage,
			ErrorInfo,
			Redirections);
		
		Return Result;
	EndIf;
	
	URLForReceiving = URL;
	HTTPRequest = New HTTPRequest;
	If ReceivingParameters.Headers <> Undefined Then
		HTTPRequest.Headers = ReceivingParameters.Headers;
	EndIf;
	BodyIsSet = False;
	Response = Undefined;
	While RedirectionsCount < MaxRedirectionsCount Do

		URIStructure = CommonClientServer.URIStructure(URLForReceiving);
		If URIStructure.Schema <> "https" Then
			SecureConnection = Undefined;
		Else
			If SecureConnectionCache = Undefined Then
				SecureConnectionCache = CommonClientServer.NewSecureConnection(
					Undefined,
					New OSCertificationAuthorityCertificates);
			EndIf;
			SecureConnection = SecureConnectionCache;
		EndIf;

		If Not IsBlankString(URIStructure.Login) Then
			UsernameToGet  = URIStructure.Login;
			PasswordToGet = URIStructure.Password;
		Else
			UsernameToGet  = Login;
			PasswordToGet = Password;
		EndIf;

		If URIStructure.Port = Undefined Or IsBlankString(URIStructure.Port) Then
			Port = ?(SecureConnection = Undefined, 80, 443);
		Else
			Port = Number(URIStructure.Port);
		EndIf;

		Proxy = ProxyBySchemes.Get(URIStructure.Schema);
		If Proxy = Undefined Then
			If ReceivingParameters.ProxySettings = Undefined Then
				Proxy = GetFilesFromInternet.GetProxy(URIStructure.Schema);
			Else
				Proxy = GenerateInternetProxy(ReceivingParameters.ProxySettings, URIStructure.Schema);
			EndIf;
			ProxyBySchemes.Insert(URIStructure.Schema, Proxy);
		EndIf;

		Join = New HTTPConnection(
			URIStructure.Host,
			Port,
			UsernameToGet,
			PasswordToGet,
			Proxy,
			ReceivingParameters.Timeout,
			SecureConnection);

		Try

			HTTPRequest.ResourceAddress = URIStructure.PathAtServer;

			If ReceivingParameters.Method = "GET" Then
				Response = Join.Get(HTTPRequest, ReceivingParameters.RespondFileName);
			ElsIf ReceivingParameters.Method = "HEAD" Then
				Response = Join.Head(HTTPRequest);
			Else
			
				If Not BodyIsSet Then

					If ReceivingParameters.DataForProcessing <> Undefined Then

						If ReceivingParameters.DataFormatToProcess = 0 Then

							HTTPRequest.SetBodyFileName(ReceivingParameters.DataForProcessing);

						ElsIf ReceivingParameters.DataFormatToProcess = 1 Then

							HTTPRequest.SetBodyFromString(ReceivingParameters.DataForProcessing);

						Else

							HTTPRequest.SetBodyFromBinaryData(ReceivingParameters.DataForProcessing);

						EndIf;

					EndIf;

					BodyIsSet = True;

				EndIf;

				If ReceivingParameters.Method = "PUT" Then
					Response = Join.Put(HTTPRequest);
				Else
					// POST
					Response = Join.Post(HTTPRequest, ReceivingParameters.RespondFileName);
				EndIf;

			EndIf;

		Except
			
			ErrorPresentation = ErrorProcessing.BriefErrorDescription(
				ErrorInfo());
			DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось загрузить содержимое (%1). %2';
					|en = 'Cannot download content (%1). %2';"),
				URL,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			// Diagnostics of connection to the resource.
			Try
				
				DiagnosticsResult = GetFilesFromInternet.ConnectionDiagnostics(URL);
				DiagnosticsResultDetails = NStr("ru = 'Результаты диагностики соединения:';
													|en = 'Connection diagnostics results:';")
					+ Chars.LF + DiagnosticsResult.ErrorDescription;
				
			Except
				
				DiagnosticsResultDetails = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось выполнить диагностику соединения. %1';
						|en = 'Cannot run connection diagnostics. %1';"),
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
			EndTry;
			
			SetErrorDescription(
				Result,
				"ConnectError",
				ErrorPresentation,
				DetailedErrorDetails + Chars.LF + DiagnosticsResultDetails,
				Redirections);
			Return Result;
			
		EndTry;

		Result.StatusCode = Response.StatusCode;

		If Response.StatusCode = 301 // 301 Moved Permanently
			Or Response.StatusCode = 302 // 302 Found, 302 Moved Temporarily
			Or Response.StatusCode = 303 // 303 See Other by GET
			Or Response.StatusCode = 307 Then // 307 Temporary Redirect

			RedirectionsCount = RedirectionsCount + 1;

			If RedirectionsCount > MaxRedirectionsCount Then
				SetErrorDescription(
					Result,
					"ServerError",
					NStr("ru = 'Превышено количество перенаправлений.';
						|en = 'Redirections limit exceeded.';"),
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Ошибка сервера при получении файла (%1). Превышено количество перенаправлений (%2).';
							|en = 'Server error occurred while receiving file (%1). Redirections limit exceeded (%2).';"),
						URL,
						MaxRedirectionsCount),
					Redirections);
				Return Result;
			Else
				Location = Response.Headers.Get("Location");
				If Location = Undefined Then
					SetErrorDescription(
						Result,
						"ServerError",
						NStr("ru = 'Некорректное перенаправление.';
							|en = 'Incorrect redirection.';"),
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Ошибка сервера (%1) при получении файла (%2). Некорректное перенаправление, отсутствует HTTP-заголовок ответа ""Location"".';
								|en = 'Server (%1) error occurred while receiving file (%2). Incorrect redirect. No HTTP header of the ""Location"" response.';"),
							Response.StatusCode,
							URL),
						Redirections);
					Return Result;
				Else
					Location = TrimAll(Location);
					If IsBlankString(Location) Then
						SetErrorDescription(
							Result,
							"ServerError",
							NStr("ru = 'Некорректное перенаправление.';
								|en = 'Incorrect redirection.';"),
							StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = 'Ошибка сервера (%1) при получении файла (%2). Некорректное перенаправление, пустой HTTP-заголовок ответа ""Location"".';
									|en = 'Server (%1) error occurred while receiving file (%2). Incorrect redirect. Empty HTTP header of the ""Location"" response.';"),
								Response.StatusCode,
								URL),
							Redirections);
						Return Result;
					EndIf;

					If ExecutedRedirections.Get(Location) <> Undefined Then
						SetErrorDescription(
							Result,
							"ServerError",
							NStr("ru = 'Циклическое перенаправление.';
								|en = 'Circular redirection.';"),
							StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = 'Ошибка сервера (%1) при получении файла (%2). Циклическое перенаправление (%3).';
									|en = 'Server (%1) error occurred while receiving file (%2). Circular redirect (%3).';"),
								Response.StatusCode,
								URL,
								Location),
							Redirections);
						Return Result;
					EndIf;

					ExecutedRedirections.Insert(Location, True);
					URLForReceiving = Location;

					Redirections.Add(String(Response.StatusCode) + ": " + Location);

				EndIf;
				
			EndIf;

		Else

			Break;

		EndIf;

	EndDo;

	If ReceivingParameters.AnswerFormat = 0 Then
		Result.Content = Response.GetBodyFileName();
	ElsIf ReceivingParameters.AnswerFormat = 1 Then
		Result.Content = Response.GetBodyAsString();
	ElsIf ReceivingParameters.AnswerFormat = 2 Then
		Result.Content = Response.GetBodyAsBinaryData();
	Else
		Result.Content = Response;
	EndIf;
	
	If Response <> Undefined Then
		Result.Headers = Response.Headers;
	EndIf;
	
	// Process the response.
	If Response.StatusCode < 200 Or Response.StatusCode >= 300 Then

		// Analyze the error.
		If Response.StatusCode = 407 Then

			// Connection error: proxy server authentication failed.
			SetErrorDescription(
				Result,
				"ConnectError",
				NStr("ru = 'Ошибка аутентификации на прокси-сервере.';
					|en = 'Proxy server authentication error.';"),
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка клиента (%1) при выполнении запроса к ресурсу (%2).
						|Тело ответа: %3';
						|en = 'Client error (%1) occurred while executing a resource query (%2).
						|Response body: %3';"),
					Response.StatusCode,
					URL,
					Left(Response.GetBodyAsString(), 5120)),
				Redirections);

		ElsIf Response.StatusCode < 200
			Or Response.StatusCode >= 300
			And Response.StatusCode < 400 Then

			// Server response format is not supported.
			SetErrorDescription(
				Result,
				"ServerError",
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Некорректный ответ сервера (%1).';
						|en = 'Incorrect server response (%1).';"),
					Response.StatusCode),
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка сервера при получении файла (%1). Некорректный (неподдерживаемый) ответ (%2).
						|Тело ответа: %3';
						|en = 'Server error occurred while receiving file (%1). Incorrect (unsupported) response (%2).
						|Response body: %3';"),
					URL,
					Response.StatusCode,
					Left(Response.GetBodyAsString(), 5120)),
				Redirections);

		ElsIf Response.StatusCode >= 400 And Response.StatusCode < 500 Then

			// Client side error: incorrect request.
			SetErrorDescription(
				Result,
				"ClientError",
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка (%1) при выполнении запроса к ресурсу.';
						|en = 'An error (%1) occurred while executing a resource query.';"),
					String(Response.StatusCode)),
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка клиента (%1) при выполнении запроса к ресурсу (%2).
						|Тело ответа: %3';
						|en = 'Client error (%1) occurred while executing a resource query (%2).
						|Response body: %3';"),
					Response.StatusCode,
					URL,
					Left(Response.GetBodyAsString(), 5120)),
				Redirections);

		Else

			// Server error - 5xx
			SetErrorDescription(
				Result,
				"ServerError",
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Код ошибки: %1.';
						|en = 'Error code: %1.';"),
					String(Response.StatusCode)),
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка сервера (%1) при обработке запроса к ресурсу (%2).
						|Тело ответа: %3';
						|en = 'Server (%1) error occurred while processing a resource request (%2).
						|Response body: %3';"),
					Response.StatusCode,
					URL,
					Left(Response.GetBodyAsString(), 5120)),
				Redirections);

		EndIf;

		AddRedirectionsListToErrorInformation(
			Result.ErrorInfo,
			Redirections);

	EndIf;

	Return Result;

EndFunction

// Returns WSProxy after checking the resource access restrictions.
//
// Parameters:
//  ConnectionParameters - Structure - See Common.WSProxyConnectionParameters.
//
// Returns:
//  WSProxy - See Common.CreateWSProxy.
//
Function CreateWSProxy(ConnectionParameters) Export
	
	If Not CanManageHost(ConnectionParameters.WSDLAddress) Then
		
		ThereIsRightOfAdministration = Users.IsFullUser(, True, False);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Обращение к сервисам Интернет-поддержки запрещено. %1';
				|en = 'Accessing online support services is not allowed. %1';"),
			?(ThereIsRightOfAdministration,
				NStr("ru = 'См. Журнал регистрации';
					|en = 'See the event log.';"),
				NStr("ru = 'Обратитесь к администратору.';
					|en = 'Please contact the administrator.';")));
			
		Raise ErrorText;
	EndIf;
	
	Return Common.CreateWSProxy(ConnectionParameters);
	
EndFunction

// Returns HTTPConnection after checking the resource access restrictions.
//
// Parameters:
//  ConnectionParameters - Structure - Properties of HTTPConnection.
//
// Returns:
//  HTTPConnection - HTTPConnection created with the given parameters.
//
Function CreateHTTPConnection(ConnectionParameters) Export
	
	If Not CanManageHost(ConnectionParameters.Server) Then
		
		ThereIsRightOfAdministration = Users.IsFullUser(, True, False);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Обращение к сервисам Интернет-поддержки запрещено. %1';
				|en = 'Accessing online support services is not allowed. %1';"),
			?(ThereIsRightOfAdministration,
				NStr("ru = 'См. Журнал регистрации';
					|en = 'See the event log.';"),
				NStr("ru = 'Обратитесь к администратору.';
					|en = 'Please contact the administrator.';")));
			
		Raise ErrorText;
	EndIf;
	
	Result = New HTTPConnection(
		ConnectionParameters.Server,
		ConnectionParameters.Port,
		ConnectionParameters.User,
		ConnectionParameters.Password,
		ConnectionParameters.Proxy,
		ConnectionParameters.Timeout,
		ConnectionParameters.SecureConnection);
	
	Return Result;
	
EndFunction

#EndRegion

#Region ServicesOperationsCall

// Generates a structure of additional parameters to transfer to services.
//
// Parameters:
//  ValuesFormatString - Boolean - an offset format.
//
// Returns:
//  Map - Additional parameters.
//
Function AdditionalParametersOfServiceOperationsCall(ValuesFormatString = True) Export
	
	Result = New Map;
	SystemInfo = New SystemInfo;
	
	If Common.FileInfobase()
		And Not Common.IsWebClient() Then
		
		Result.Insert("ClientPlatformType",
			CommonClientServer.NameOfThePlatformType(
				SystemInfo.PlatformType));
		Result.Insert("ClientOSVersion", SystemInfo.OSVersion);
		
	Else
		
		SystemInfoClient = Common.ClientSystemInfo();
		If SystemInfoClient <> Undefined Then
			Result.Insert("ClientPlatformType", SystemInfoClient.PlatformType);
			Result.Insert("ClientOSVersion", SystemInfoClient.OSVersion);
		EndIf;
		
		Result.Insert("ServerPlatformType",
			CommonClientServer.NameOfThePlatformType(
				SystemInfo.PlatformType));
		Result.Insert("ServerOSVersion", SystemInfo.OSVersion);
		
	EndIf;
	
	Result.Insert("PlatformVersion", SystemInfo.AppVersion);
	
	Result.Insert("LibraryVersion",
		OnlineUserSupportClientServer.LibraryVersion());
	Result.Insert("ConfigName", ConfigurationName());
	Result.Insert("ConfigVersion", ConfigurationVersion());
	Result.Insert("Vendor", Metadata.Vendor);
	If Common.SeparatedDataUsageAvailable() Then
		Result.Insert("IBID",
			StandardSubsystemsServer.InfoBaseID());
	EndIf;
	Result.Insert("ConfigLanguage", ConfigurationInterfaceLanguageCode());
	Result.Insert("ConfigMainLanguage", ConfigurationInterfaceDefaultLanguageCode());
	Result.Insert("CurLocalizationCode", CurrentLocaleCode());
	Result.Insert("SystemLanguage", CurrentSystemLanguage());
	Result.Insert("ClientTimeOffsetGMT",
		?(ValuesFormatString,
		  Format((CurrentSessionDate() - CurrentUniversalDate()), "NG=0"),
		  (CurrentSessionDate() - CurrentUniversalDate())));
	
	Result.Insert("countryId", "");
	
	Result.Insert(
		"IBIsSeparated",
		?(ValuesFormatString,
		  ?(Common.DataSeparationEnabled(), "true", "false"),
		  Common.DataSeparationEnabled()));
	Result.Insert("IBUserName", String(UserName()));
	
	ConnectionSetup = OnlineUserSupportInternalCached.OUSServersConnectionSettings();
	If ConnectionSetup.OUSServersDomain = 0 Then
		Result.Insert("DomainZone", "ru");
	ElsIf ConnectionSetup.OUSServersDomain = 1 Then
		Result.Insert("DomainZone", "eu");
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region LicensingClientSettings

// Returns the flag indicating whether operations with licensing client settings are available
// in OSL.
//
// Returns:
//  Boolean - True if 1C:Enterprise platform version is 8.3.7 or later, and SaaS mode is unavailable.
//
Function OperationWithLicensingClientSettingsAvailable() Export

	Return Not Common.DataSeparationEnabled();

EndFunction

#EndRegion

#Region MessageTemplates

// See MessageTemplatesOverridable.OnPrepareMessageTemplate.
//
Procedure OnPrepareMessageTemplate(
		Attributes,
		Attachments,
		TemplateAssignment,
		AdditionalParameters) Export
	
	If Common.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		ModuleOnlinePayment = Common.CommonModule("OnlinePayment");
		ModuleOnlinePayment.OnPrepareMessageTemplate(Attributes, Attachments, TemplateAssignment, AdditionalParameters);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.InstantPayments.FPSc2bTransfers") Then
		ModuleFPSc2bTransfersInternal 
			= Common.CommonModule("FPSc2bTransfersInternal");
		ModuleFPSc2bTransfersInternal.OnPrepareMessageTemplate(
			Attributes,
			Attachments,
			TemplateAssignment,
			AdditionalParameters);
	EndIf;
	
EndProcedure

// See MessageTemplatesOverridable.OnCreateMessage.
//
Procedure OnCreateMessage(
		Message,
		TemplateAssignment,
		MessageSubject,
		TemplateParameters) Export
	
	If Common.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		ModuleOnlinePayment = Common.CommonModule("OnlinePayment");
		ModuleOnlinePayment.OnCreateMessage(Message, TemplateAssignment, MessageSubject, TemplateParameters);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.InstantPayments.FPSc2bTransfers") Then
		ModuleFPSc2bTransfersInternal
			= Common.CommonModule("FPSc2bTransfersInternal");
		ModuleFPSc2bTransfersInternal.OnCreateMessage(
			Message,
			TemplateAssignment,
			MessageSubject,
			TemplateParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region SSLFunctionalOptions

// Checks whether the "Business interactions" subsystem is integrated and enables the text message functional option.
//
Procedure SetSMSUsage() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.Interactions") Then
		Return;
	EndIf;
	
	ModuleInteractions = Common.CommonModule("Interactions");
	
	SetPrivilegedMode(True);
	
	If Not ModuleInteractions.AreOtherInteractionsUsed() Then
		ModuleInteractions.SetUsageOfOtherInteraction(True);
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Checks whether the "Message templates" subsystem is integrated and enables the related functional option.
//
Procedure SetUsageOfMessagesTemplates() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.MessageTemplates") Then
		Return;
	EndIf;
	
	ModuleMessageTemplates = Common.CommonModule("MessageTemplates");
	
	SetPrivilegedMode(True);
	
	If Not ModuleMessageTemplates.MessageTemplatesUsed() Then
		ModuleMessageTemplates.SetUsageOfMessagesTemplates(True);
		RefreshReusableValues();
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Checks whether the "Business interactions" subsystem is integrated and enables the digital signature functional option.
//
Procedure SetEmailUsage() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.Interactions") Then
		Return;
	EndIf;
	
	ModuleInteractions = Common.CommonModule("Interactions");
	
	SetPrivilegedMode(True);
	
	If Not ModuleInteractions.EmailClientUsed() Then
		ModuleInteractions.SetEmailClientUsage(True);
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Checks whether the "Business interactions" subsystem is integrated and enables the HTML email functional option.
// 
//
Procedure SetSendingHTMLEmailMessages() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.Interactions") Then
		Return;
	EndIf;
	
	ModuleInteractions = Common.CommonModule("Interactions");
	
	SetPrivilegedMode(True);

	If Not ModuleInteractions.IsSendingHTMLEmailMessagesEnabled() Then
		ModuleInteractions.EnableSendingHTMLEmailMessages(True);
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Returns the value of the SendEmailsInHTMLFormat functional option
//
// Returns:
//  Boolean - The usage flag of the SendEmailsInHTMLFormat functional option.
//
Function SendEmailsInHTMLFormat() Export
	
	If Common.SubsystemExists("StandardSubsystems.Interactions") Then
		ModuleInteractions = Common.CommonModule("Interactions");
		Return ModuleInteractions.IsSendingHTMLEmailMessagesEnabled();
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Authentication

// Defines a URL of the operation for getting a ticket depending on the passed domain.
//
// Parameters:
//  Domain - Number - Domain ID.
//
// Returns:
//  String - a URL of the operation for getting a ticket.
//
Function GetTicketOperationURL(Domain)

	Return "https://"
		+ OnlineUserSupportClientServer.LoginServiceHost(Domain)
		+ "/rest/public/ticket/get";

EndFunction

// Defines a URL of the authentication data check operation depending on the passed domain.
//
// Parameters:
//  Domain - Number - Domain ID.
//
// Returns:
//  String - a URL of the authentication data check operation.
//
Function PasswordsCheckServiceURL(Domain)

	Return "https://"
		+ OnlineUserSupportClientServer.LoginServiceHost(Domain)
		+ "/rest/public/user/auth";

EndFunction

// Internal function for getting authentication tickets.
//
// Parameters:
//  Login - String - Username of an online support user;
//  Password - String - Password of an online support user.
//  TicketOwner - String - an arbitrary name of a service for which
//      user authentication is performed. The same name must be
//      used when calling the checkTicket operation;
//      Parameter value is required.
//  ConnectionSetup - Structure - See ServersConnectionSettings
//                                    ;
//
// Returns:
//  Structure - The result of the ticket receiving. Structure fields:
//        * Ticket1 - String - Received authentication ticket. If when receiving a ticket,
//          an error occurred (incorrect username or password or other error),
//          a field value is a blank row.
//        * ErrorCode - String - String code of the occurred error that
//          can be processed by the calling functionality:
//              - <Пустая строка> - a ticket is successfully received;
//              - "НеверныйЛогинИлиПароль" - invalid username or password;
//              - "ПревышеноКоличествоПопыток" - you exceeded the limit of attempts to
//                 receive a ticket with invalid username and password;
//              - "ОшибкаПодключения" - an error occurred when connecting to the service.
//              - "ОшибкаСервиса" - an internal service error.
//              - "НеизвестнаяОшибка" - an unknown error occurred
//                 when getting the ticket (an error that cannot be processed),
//        * ErrorMessage - String - brief details of an error, which
//          can be displayed to user,
//        * ErrorInfo - String - details of an error, which
//          can be written to the event log.
//
Function InternalAuthenticationTicket(
	Val Login,
	Val Password,
	Val ServiceName,
	ConnectionSetup)
	
	Result = New Structure;
	Result.Insert("ErrorCode"         , "");
	Result.Insert("ErrorMessage" , "");
	Result.Insert("ErrorInfo", "");
	Result.Insert("Ticket1"             , Undefined);
	
	If Not ValueIsFilled(Login) Then
		AuthenticationData = OnlineSupportUserAuthenticationData();
		If AuthenticationData <> Undefined Then
			Login  = AuthenticationData.Login;
			Password = AuthenticationData.Password;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Login) Then
		Result.ErrorCode = "InvalidUsernameOrPassword";
		Result.ErrorMessage  = NStr("ru = 'Неверный логин или пароль.';
											|en = 'Invalid username or password.';");
		Result.ErrorInfo = Result.ErrorMessage;
		Return Result;
	EndIf;
	
	If ConnectionSetup = Undefined Then
		ConnectionSetup = ServersConnectionSettings();
	EndIf;
	
	URLOfService = GetTicketOperationURL(
		ConnectionSetup.OUSServersDomain);
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/json");
	
	AdditionalRequestParameters = New Structure;
	AdditionalRequestParameters.Insert("Method"                   , "POST");
	AdditionalRequestParameters.Insert("Headers"               , Headers);
	AdditionalRequestParameters.Insert("AnswerFormat"            , 1);
	AdditionalRequestParameters.Insert("DataForProcessing"      , TicketGetJSONParameters(Login, Password, ServiceName));
	AdditionalRequestParameters.Insert("DataFormatToProcess", 1);
	AdditionalRequestParameters.Insert("Timeout"                 , 30);

	OperationResult = DownloadContentFromInternet(
		URLOfService,
		,
		,
		AdditionalRequestParameters);

	If OperationResult.StatusCode = 200 Then
		
		Try
			
			JSONReader = New JSONReader;
			JSONReader.SetString(OperationResult.Content);
			ResponseObject = ReadJSON(JSONReader);
			JSONReader.Close();
			
			Result.Ticket1 = ResponseObject.ticket;
			
		Except
			
			ErrorInfo = ErrorInfo();
			Result.ErrorCode = "ServiceError";
			Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить тикет аутентификации в сервисе %1.
					|Некорректный ответ сервиса.
					|Ошибка при обработке ответа сервиса:
					|%2
					|Код состояния: %3;
					|Тело ответа: %4';
					|en = 'Cannot receive an authentication ticket in the %1 service. 
					|Incorrect service response.
					|An error occurred while processing the service response:
					|%2
					|State code: %3;
					|Response body: %4';"),
				URLOfService,
				ErrorProcessing.DetailErrorDescription(ErrorInfo),
				OperationResult.StatusCode,
				Left(OperationResult.Content, 5120));
			WriteInformationToEventLog(
				Result.ErrorInfo);
			Result.ErrorMessage =
				NStr("ru = 'Ошибка аутентификации в сервисе.
					|Подробнее см. в журнале регистрации.';
					|en = 'Authentication error.
					|See the event log for details.';");
			
		EndTry;
		
	ElsIf OperationResult.StatusCode = 403 Then
		
		Result.ErrorCode = "InvalidUsernameOrPassword";
		Result.ErrorMessage  = NStr("ru = 'Неверный логин или пароль.';
											|en = 'Invalid username or password.';");
		Result.ErrorInfo = Result.ErrorMessage;
		
	ElsIf OperationResult.StatusCode = 429 Then
		
		Result.ErrorCode = "AttemptLimitExceeded";
		Result.ErrorMessage = NStr("ru = 'Превышено количество попыток аутентификации.
			|Повторите попытку позже.';
			|en = 'Exceeded maximum number of authentication attempts.
			|Try again later.';");
		Result.ErrorInfo = Result.ErrorMessage;
		
	ElsIf OperationResult.StatusCode = 500 Then
		
		Result.ErrorCode          = "ServiceError";
		Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить тикет аутентификации в сервисе %1.
				|Внутренняя ошибка сервиса.
				|Код состояния: %2;
				|Тело ответа: %3';
				|en = 'Cannot receive an authentication ticket in the %1 service. 
				|Internal service error. 
				|State code: %2;
				|Response body: %3';"),
			URLOfService,
			OperationResult.StatusCode,
			Left(OperationResult.Content, 5120));
		WriteInformationToEventLog(
			Result.ErrorInfo);
		
		Result.ErrorMessage =
			NStr("ru = 'Ошибка аутентификации. Внутренняя ошибка сервиса.
				|Подробнее см. в журнале регистрации.';
				|en = 'Authentication error. Internal service error.
				|See the event log for details.';");
		
	ElsIf OperationResult.StatusCode = 0 Then
		
		Result.ErrorCode         = "AttachmentError";
		Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить тикет аутентификации в сервисе %1.
				|%2';
				|en = 'Cannot receive an authentication ticket in the %1 service.
				|%2';"),
			URLOfService,
			OperationResult.ErrorInfo);
		WriteInformationToEventLog(
			Result.ErrorInfo);
		Result.ErrorMessage = NStr("ru = 'Ошибка подключения к сервису.
			|Подробнее см. в журнале регистрации.';
			|en = 'An error occurred while connecting to the service.
			|See the event log for details.';");
		
	Else
		
		Result.ErrorCode = "UnknownError";
		Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить тикет аутентификации в сервисе %1.
				|Неизвестный код состояния ответа сервиса.
				|Код состояния: %2;
				|Тело ответа: %3';
				|en = 'Cannot receive an authentication ticket in the %1 service. 
				|Unknown code of the service response state. 
				|State code: %2;
				|Response body: %3';"),
			URLOfService,
			OperationResult.StatusCode,
			Left(OperationResult.Content, 5120));
		WriteInformationToEventLog(
			Result.ErrorInfo);
		Result.ErrorMessage =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка аутентификации в сервисе (%1).
					|Подробнее см. в журнале регистрации.';
					|en = 'Authentication error (%1).
					|See the event log for details.';"),
				OperationResult.StatusCode);
		
	EndIf;

	Return Result;

EndFunction

// Generates a query body for receiving an authentication ticket.
//
// Parameters:
//  Login - String - Username of an online support user;
//  Password - String - Password of an online support user.
//  TicketOwner - String - an arbitrary name of a service for which
//      user authentication is performed. The same name must be
//      used when calling the checkTicket operation;
//      Parameter value is required.
//
// Returns:
//  String - a query body
//
Function TicketGetJSONParameters(Login, Password, TicketOwner)

	MessageDataWriter = New JSONWriter;
	MessageDataWriter.SetString();
	MessageDataWriter.WriteStartObject();

	MessageDataWriter.WritePropertyName("login");
	MessageDataWriter.WriteValue(Login);

	MessageDataWriter.WritePropertyName("password");
	MessageDataWriter.WriteValue(Password);
	
	MessageDataWriter.WritePropertyName("serviceNick");
	MessageDataWriter.WriteValue(TicketOwner);
	
	MessageDataWriter.WriteEndObject();

	Return MessageDataWriter.Close();

EndFunction

// Generates a query body for the authentication data check.
//
// Parameters:
//  Login - String - Username of an online support user;
//  Password - String - Password of an online support user.
//
// Returns:
//  String - a query body
//
Function AuthJSONParameters(Login, Password)
	
	MessageDataWriter = New JSONWriter;
	MessageDataWriter.SetString();
	MessageDataWriter.WriteStartObject();
	
	MessageDataWriter.WritePropertyName("login");
	MessageDataWriter.WriteValue(Login);
	
	MessageDataWriter.WritePropertyName("password");
	MessageDataWriter.WriteValue(Password);
	
	MessageDataWriter.WriteEndObject();
	
	Return MessageDataWriter.Close();
	
EndFunction

// See OnlineUserSupport.URLToNavigateToIntegratedWebsitePage
//
Function InternalURLToNavigateToIntegratedWebsitePage(WebsitePageURL) Export
	
	Result = New Structure;
	Result.Insert("ErrorCode", "");
	Result.Insert("URL"      , WebsitePageURL);
	
	TicketResult = Undefined;
	If Common.DataSeparationEnabled() Or Users.IsFullUser(, True, False) Then
		SetPrivilegedMode(True);
		TicketResult = AuthenticationTicketOnSupportPortal(WebsitePageURL);
		SetPrivilegedMode(False);
	EndIf;
	
	If TicketResult <> Undefined Then
		If IsBlankString(TicketResult.ErrorCode) Then
			Result.URL =
				OnlineUserSupportClientServer.LoginServicePageURL(
					"/ticket/auth?token=" + TicketResult.Ticket1,
					ServersConnectionSettings());
		Else
			Result.ErrorCode = TicketResult.ErrorCode;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region LibEventsProcessing

// It is called when changing a username and a password of an OUS user
// to the infobase from all library usage contexts.
//
// Parameters:
//  Login - String - Username of an online support user;
//  Password - String - Password of an online support user.
//
Procedure OnChangeAuthenticationData(Login, Password)
	
	If OperationWithLicensingClientSettingsAvailable() Then
		SetPrivilegedMode(True);
		LicensingClient.OnChangeAuthenticationData(Login, Password);
		SetPrivilegedMode(False);
	EndIf;
	
	// OneCITSPortalDashboard
	If Common.SubsystemExists("OnlineUserSupport.PortalMonitor1CITS") Then
		ModuleOneCITSPortalDashboard = Common.CommonModule("PortalMonitor1CITS");
		ModuleOneCITSPortalDashboard.OnChangeAuthenticationData(Login, Password);
	EndIf;
	// End OneCITSPortalDashboard
	
	// SPARKRisks
	If Common.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		ModuleSPARKRisks = Common.CommonModule("SparkRisks");
		ModuleSPARKRisks.OnChangeAuthenticationData(Login, Password);
	EndIf;
	// End SPARKRisks
	
	// ClassifiersOperations
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		ModuleClassifiersOperations.OnChangeAuthenticationData(Login, Password);
	EndIf;
	// End ClassifiersOperations
	
	// GetAddIns
	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		ModuleGetAddIns = Common.CommonModule("GetAddIns");
		ModuleGetAddIns.OnChangeAuthenticationData(Login, Password);
	EndIf;
	// End GetAddIns
	
	// EnableMaintenanceServices
	If Common.SubsystemExists("OnlineUserSupport.EnableMaintenanceServices") Then
		ModuleMaintenanceServicesActivation = Common.CommonModule("EnableMaintenanceServices");
		ModuleMaintenanceServicesActivation.OnChangeAuthenticationData();
	EndIf;
	// End EnableMaintenanceServices
	
	// GetApplicationUpdates
	If Common.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		ModuleGetApplicationUpdates = Common.CommonModule("GetApplicationUpdates");
		ModuleGetApplicationUpdates.OnChangeAuthenticationData(Login);
	EndIf;
	// End GetApplicationUpdates
	
	// InstantPayments.BasicFPSFeatures
	If Common.SubsystemExists("OnlineUserSupport.InstantPayments.BasicFPSFeatures") Then
		ModuleFasterPaymentSystemInternal = Common.CommonModule("InstantPaymentsInternal");
		ModuleFasterPaymentSystemInternal.OnChangeAuthenticationData(Login);
	EndIf;
	// End InstantPayments.BasicFPSFeatures
	
	// InstantPayments.BasicFPSFeatures
	If Common.SubsystemExists("OnlineUserSupport.InstantPayments.FPSc2bTransfers") Then
		ModuleFPSc2bTransfersInternal = Common.CommonModule("FPSc2bTransfersInternal");
		ModuleFPSc2bTransfersInternal.OnChangeAuthenticationData(Login);
	EndIf;
	// End InstantPayments.BasicFPSFeatures
	
	// GettingStatutoryReports
	If Common.SubsystemExists("OnlineUserSupport.GettingStatutoryReports") Then
		StatutoryReportsGetterModule = Common.CommonModule("GettingStatutoryReports");
		StatutoryReportsGetterModule.OnChangeAuthenticationData(Login, Password);
	EndIf;
	// End GettingStatutoryReports
	
	// Overridable event processing.
	If ValueIsFilled(Login) Then 
		AuthenticationData = New Structure("Login, Password", Login, Password);
		OSLSubsystemsIntegration.OnChangeOnlineSupportAuthenticationData(
			AuthenticationData);
		OnlineUserSupportOverridable.OnChangeOnlineSupportAuthenticationData(
			AuthenticationData);
	Else
		OSLSubsystemsIntegration.OnChangeOnlineSupportAuthenticationData(
			Undefined);
		OnlineUserSupportOverridable.OnChangeOnlineSupportAuthenticationData(
			Undefined);
	EndIf;
	
EndProcedure

#EndRegion

#Region GetContentFromInternet

// Defines error details in the operation execution result.
//
// Parameters:
//  Result - Structure - an operation execution result;
//  ErrorCode - String - an error ID
//  ErrorMessage - String - error details for the user.
//  ErrorInfo - String - error details for the administrator.
//  Redirections - Array - redirection data.
//
Procedure SetErrorDescription(
		Result,
		ErrorCode,
		ErrorMessage,
		ErrorInfo,
		Redirections)
	
	Result.ErrorCode          = ErrorCode;
	Result.ErrorMessage  = ErrorMessage;
	Message = "";
	If ErrorCode = "ConnectError" Then
		Message = NStr("ru = 'Ошибка при подключении к серверу.';
						|en = 'An error occurred while connecting to the server.';");
	ElsIf ErrorCode = "ServerError" Then
		Message = NStr("ru = 'На сервере возникла внутренняя ошибка при обработке запроса.';
						|en = 'An internal error occurred on the server while processing the query.';");
	ElsIf ErrorCode = "ClientError" Then
		Message = NStr("ru = 'Некорректный запрос.';
						|en = 'Incorrect query.';");
	ElsIf ErrorCode = "InternalError" Then
		Message = NStr("ru = 'Внутренняя ошибка.';
						|en = 'Internal error.';");
	ElsIf ErrorCode = "LoginError" Then
		Message = NStr("ru = 'Ошибка аутентификации на сервере.';
						|en = 'Server authentication error.';");
	EndIf;
	
	Result.ErrorMessage =
		?(IsBlankString(Message), "", Message + " ")
		+ ErrorMessage;
	
	Result.ErrorInfo = ErrorInfo;
	
	If Redirections.Count() > 0 Then
		Result.ErrorInfo = Result.ErrorInfo + Chars.LF
			+ NStr("ru = 'Перенаправления:';
					|en = 'Redirections:';") + Chars.LF
			+ StrConcat(Redirections, ", " + Chars.LF);
	EndIf;
	
EndProcedure

// Defines redirection details when executing the operation.
//
// Parameters:
//  ErrorInfo - String - error details for the administrator.
//  Redirections - Array - redirection data.
//
Procedure AddRedirectionsListToErrorInformation(
		ErrorInfo,
		Redirections)
	
	If Redirections.Count() = 0 Then
		Return;
	EndIf;
	
	ErrorInfo = ErrorInfo + Chars.LF
		+ NStr("ru = 'Перенаправления:';
				|en = 'Redirections:';") + Chars.LF
		+ StrConcat(Redirections, ", " + Chars.LF);
	
EndProcedure

// Checks availability of the passed URL by the following criteria:
//  - Response code is 200;
//  - Response timeout is 10 seconds.
//
// Parameters:
//  URL - String - URL to be checked;
//  Method - String - HTTP check method;
//  ErrorName - String - an error ID;
//  ErrorMessage - String - error details for the user;
//  ErrorInfo - String - error details for the administrator;
//  ProxyServerSettings - Structure, Undefined - proxy settings;
//
Procedure InternalCheckURLAvailable(
		URL,
		Method,
		ErrorName,
		ErrorMessage,
		ErrorInfo,
		ProxyServerSettings = Undefined) Export
	
	AddlFileReceiptParameters = New Structure("AnswerFormat, Timeout", 1, 10);
	AddlFileReceiptParameters.Insert("ProxySettings", ProxyServerSettings);
	
	If Method <> Undefined Then
		AddlFileReceiptParameters.Insert("Method", Method);
	EndIf;
	
	Try
		ImportResult1 = DownloadContentFromInternet(
			URL,
			,
			,
			AddlFileReceiptParameters);
	Except
		ErrorName = "Unknown";
		ErrorMessage = NStr("ru = 'Неизвестная ошибка. Подробнее см. в журнале регистрации.';
								|en = 'Unknown error. See the event log for details.';");
		ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неизвестная ошибка при проверке доступности URL.
				|%1';
				|en = 'An unknown error occurred when checking URL availability.
				|%1';"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	If Not IsBlankString(ImportResult1.ErrorCode) Then
		ErrorName          = ImportResult1.ErrorCode;
		ErrorMessage  = ImportResult1.ErrorMessage;
		ErrorInfo = ImportResult1.ErrorInfo;
	EndIf;
	
EndProcedure

// Generates InternetProxy based on the passed settings.
//
// Parameters:
//  ProxyServerSetting - String, Map - proxy connection parameters;
//  Protocol - String - proxy connection protocol.
//
// Returns:
//  InternetProxy - a prepared proxy object.
//
Function GenerateInternetProxy(
		ProxyServerSetting,
		Protocol)
	
	If ProxyServerSetting = Undefined
		Or ProxyServerSetting = "<SystemInstallations>" Then
		// Proxy server system settings.
		Return Undefined;
	EndIf;	
	
	UseProxy = ProxyServerSetting.Get("UseProxy");
	If Not UseProxy Then
		// Do not use proxy servers.
		Return New InternetProxy(False);
	EndIf;
	
	UseSystemSettings = ProxyServerSetting.Get("UseSystemSettings");
	If UseSystemSettings Then
		// Proxy server system settings.
		Return New InternetProxy(True);
	EndIf;
			
	// Manually configured proxy settings.
	Proxy = New InternetProxy;
	
	// Detecting a proxy server address and port.
	AdditionalSettings = ProxyServerSetting.Get("AdditionalProxySettings");
	ProxyByProtocol = Undefined;
	If TypeOf(AdditionalSettings) = Type("Map") Then
		ProxyByProtocol = AdditionalSettings.Get(Protocol);
	EndIf;
	
	UseOSAuthentication = ProxyServerSetting.Get("UseOSAuthentication");
	UseOSAuthentication = ?(UseOSAuthentication = True, True, False);
	
	If TypeOf(ProxyByProtocol) = Type("Structure") Then
		Proxy.Set(Protocol, ProxyByProtocol.Address, ProxyByProtocol.Port,
			ProxyServerSetting["User"], ProxyServerSetting["Password"], UseOSAuthentication);
	Else
		Proxy.Set(Protocol, ProxyServerSetting["Server"], ProxyServerSetting["Port"], 
			ProxyServerSetting["User"], ProxyServerSetting["Password"], UseOSAuthentication);
	EndIf;
	
	Proxy.BypassProxyOnLocal = ProxyServerSetting["BypassProxyOnLocal"];
	
	ExceptionsAddresses = ProxyServerSetting.Get("BypassProxyOnAddresses");
	If TypeOf(ExceptionsAddresses) = Type("Array") Then
		For Each ExceptionAddress In ExceptionsAddresses Do
			Proxy.BypassProxyOnAddresses.Add(ExceptionAddress);
		EndDo;
	EndIf;
	
	Return Proxy;
	
EndFunction

// Defines a domain ID based on
// external resource use mode.
//
// Returns:
//  Number - Domain ID.
//
Function OUSServersDomain() Export
	
	UsageMode = GetExternalResourcesMode();
	If Upper(UsageMode) = "D" Then
		Return 0;
	Else
		Return 1;
	EndIf;
	
EndFunction

#EndRegion

#Region Localization

// Code of the current configuration interface language
// in ISO-639-1 format is returned.
//
// Returns:
//  String - a code of the configuration interface language.
//
Function ConfigurationInterfaceLanguageCode()

	Language = CurrentLanguage();
	If Language = Undefined Then
		// Language is not specified for the infobase user.
		Return ConfigurationInterfaceDefaultLanguageCode();
	EndIf;

	LanguageCodeInMetadata = ?(TypeOf(Language) = Type("String"), Language, Language.LanguageCode);
	LanguageCodeInISO6391Format = Undefined;
	
	OSLSubsystemsIntegration.OnDefineConfigurationInterfaceLanguageCode(
		LanguageCodeInMetadata,
		LanguageCodeInISO6391Format);
	OnlineUserSupportOverridable.OnDefineConfigurationInterfaceLanguageCode(
		LanguageCodeInMetadata,
		LanguageCodeInISO6391Format);

	Return ?(LanguageCodeInISO6391Format = Undefined, LanguageCodeInMetadata, LanguageCodeInISO6391Format);

EndFunction

// Code of the main configuration interface language
// in ISO-639-1 format is returned.
//
// Returns:
//  String - a code of the configuration interface language.
//
Function ConfigurationInterfaceDefaultLanguageCode()

	LanguageCodeInMetadata = Common.DefaultLanguageCode();
	LanguageCodeInISO6391Format = Undefined;
	
	OSLSubsystemsIntegration.OnDefineConfigurationInterfaceLanguageCode(
		LanguageCodeInMetadata,
		LanguageCodeInISO6391Format);
	OnlineUserSupportOverridable.OnDefineConfigurationInterfaceLanguageCode(
		LanguageCodeInMetadata,
		LanguageCodeInISO6391Format);

	Return ?(LanguageCodeInISO6391Format = Undefined, LanguageCodeInMetadata, LanguageCodeInISO6391Format);

EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version    = "2.1.7.1";
	Handler.Procedure =
		"OnlineUserSupport.InfobaseUpdateMoveOnlineSupportParametersToSecureDataStorage2171";
	Handler.SharedData         = False;
	Handler.InitialFilling = False;
	Handler.ExecutionMode     = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version    = "2.1.8.14";
	Handler.Procedure =
		"OnlineUserSupport.InfobaseUpdateReplaceSubsystemIDInSecureDataStorage21814";
	Handler.SharedData         = False;
	Handler.InitialFilling = False;
	Handler.ExecutionMode     = "Seamless";
	
EndProcedure

// Moves data from the DeleteOnlineUserSupportParameters information register
// to the secure storage.
//
Procedure InfobaseUpdateMoveOnlineSupportParametersToSecureDataStorage2171() Export
	
	If Common.DataSeparationEnabled() Then
		// Not used in SaaS mode
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.DeleteOnlineUserSupportParameters");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		OUSParametersQuery = New Query;
		OUSParametersQuery.Text =
		"SELECT TOP 1
		|	DeleteOnlineUserSupportParameters.Name AS ParameterName,
		|	DeleteOnlineUserSupportParameters.Value AS ParameterValue
		|FROM
		|	InformationRegister.DeleteOnlineUserSupportParameters AS DeleteOnlineUserSupportParameters
		|WHERE
		|	DeleteOnlineUserSupportParameters.Name = ""login""
		|	AND DeleteOnlineUserSupportParameters.User = &BlankID
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	DeleteOnlineUserSupportParameters.Name,
		|	DeleteOnlineUserSupportParameters.Value
		|FROM
		|	InformationRegister.DeleteOnlineUserSupportParameters AS DeleteOnlineUserSupportParameters
		|WHERE
		|	DeleteOnlineUserSupportParameters.Name = ""password""
		|	AND DeleteOnlineUserSupportParameters.User = &BlankID
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	DeleteOnlineUserSupportParameters.Name,
		|	DeleteOnlineUserSupportParameters.Value
		|FROM
		|	InformationRegister.DeleteOnlineUserSupportParameters AS DeleteOnlineUserSupportParameters
		|WHERE
		|	DeleteOnlineUserSupportParameters.Name = ""regnumber""
		|	AND DeleteOnlineUserSupportParameters.User = &BlankID";
		
		OUSParametersQuery.SetParameter(
			"BlankID",
			New UUID("00000000-0000-0000-0000-000000000000"));
		
		SetPrivilegedMode(True);
		SelectingParameters = OUSParametersQuery.Execute().Select();
		
		// Writing data to safe storage
		OSLSubsystemID = SubsystemID();
		While SelectingParameters.Next() Do
			Common.WriteDataToSecureStorage(
				OSLSubsystemID,
				SelectingParameters.ParameterValue,
				SelectingParameters.ParameterName);
		EndDo;
		
		// Clearing an unused OUS parameter register
		RecordSet = InformationRegisters.DeleteOnlineUserSupportParameters.CreateRecordSet();
		RecordSet.Write();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		ErrorInfo = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteInformationToEventLog(ErrorInfo);
		
		Raise ErrorInfo;
		
	EndTry;
	
EndProcedure

// Replaces a subsystem ID in the secure storage.
//
Procedure InfobaseUpdateReplaceSubsystemIDInSecureDataStorage21814() Export

	If Common.DataSeparationEnabled() Then
		// Not used in SaaS mode.
		Return;
	EndIf;
	
	OSLSubsystemIDObsolete =
		Common.MetadataObjectID(
			"Subsystem.OnlineUserSupport.Subsystem.CoreISL");
	DataInSafeStorageObsolete =
		Common.ReadDataFromSecureStorage(
			OSLSubsystemIDObsolete,
			"login,password,regnumber");
	
	SubsystemID = SubsystemID();
	For Each KeyValue In DataInSafeStorageObsolete Do
		If KeyValue.Value <> Undefined Then
			Common.WriteDataToSecureStorage(
				SubsystemID,
				KeyValue.Value,
				KeyValue.Key);
		EndIf;
	EndDo;
	
	// Deleting obsolete data after migration.
	Common.DeleteDataFromSecureStorage(OSLSubsystemIDObsolete);
	
EndProcedure

#EndRegion

#Region OnlineSupportServicesAccessLock

// Called upon locking operations with external resources.
// Allows enabling arbitrary features that cannot be performed
// in the infobase copy.
//
Procedure WhenYouAreForbiddenToWorkWithExternalResources() Export
	
	BeginTransaction();
	Try
		
		LockParameters = OnlineSupportServicesNewLockParameters();
		LockParameters.IsOnlineSupportServicesAccessLocked = True;
		SaveLockParameters(LockParameters);
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Called upon unlocking operations with external resources.
// To enable features disabled in the OnProhibitWorkWithExternalResources procedure.
//
Procedure WhenAllowingWorkWithExternalResources() Export
	
	BeginTransaction();
	Try
		
		BlockLockParametersData();
		
		LockParameters = OnlineSupportServicesNewLockParameters();
		SaveLockParameters(LockParameters);
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Unlocks the Online Support services that were allowed for the copy.
//
// Parameters:
//  Services - Array of Structure - The list of allowed resources.
//
Procedure UnlockAccessToOnlineSupportServices(Services) Export
	
	BeginTransaction();
	Try
		BlockLockParametersData();
		
		LockParameters = LockParametersWithOnlineSupportServices();
		
		For Each Service In Services Do
			
			OnlineSupportService = LockParameters.OnlineSupportServices.Get(Service.Name1);
			If OnlineSupportService <> Undefined Then
				OnlineSupportService.CanBeManaged = Service.CanBeManaged;
			EndIf;
		EndDo;
		
		SaveLockParameters(LockParameters);
		RefreshReusableValues();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Checks the permission to work with the service by the passed URL.
// The permission is considered granted if one of the conditions is met:
//  - External resources are not locked.
//  - Online Supports services are not locked.
//  - The service defined by the passed URL is permitted.
//
// Parameters:
//  URL - String - URL of the operation called;
// 
// Returns:
//  Boolean - Service permission flag.
//
Function CanManageHost(URL)
	
	If Not ScheduledJobsServer.OperationsWithExternalResourcesLocked() Then
		Return True;
	EndIf;
	
	LockParameters = LockParametersWithOnlineSupportServices();
	If Not LockParameters.IsOnlineSupportServicesAccessLocked Then
		Return True;
	EndIf;
	
	URIStructure = CommonClientServer.URIStructure(URL);
	OnlineSupportService = LockParameters.OnlineSupportServicesHosts.Get(URIStructure.ServerName);
	If OnlineSupportService = Undefined Then
		Return True;
	EndIf;
	
	ServiceParameters = LockParameters.OnlineSupportServices.Get(OnlineSupportService);
	CanManageHost = (ServiceParameters = Undefined
		Or ServiceParameters.CanBeManaged);
	
	If Not CanManageHost Then
		
		ErrorInfo = NStr("ru = 'Обращение к сервисам Интернет-поддержки запрещено.
			|Для разрешения работы с сервисами откройте раздел Интернет-поддержка и сервисы и нажмите ""Настроить"".';
			|en = 'Accessing online support services is not allowed.
			|To allow operations with the services, open the Online support and services section and click Configure.';");
		
		WriteLogEvent(
			EventLogEventName(),
			EventLogLevel.Warning,,,
			ErrorInfo);
		
	EndIf;
	
	Return CanManageHost;
	
EndFunction

// Returns the saved lock parameters of the Online Support services.
// If there are no saved parameters, then it initializes the parameter with the default values.
// 
// Returns:
//  Structure - See OnlineSupportServicesNewLockParameters.
//
Function LockParametersWithOnlineSupportServices() Export
	
	SetPrivilegedMode(True);
	SavedParameters = Constants.OnlineSupportServicesAccessLockParameters.Get().Get();
	SetPrivilegedMode(False);
	
	Result = OnlineSupportServicesNewLockParameters();
	
	If SavedParameters = Undefined Then
		SaveLockParameters(Result);
	EndIf;
	
	If TypeOf(SavedParameters) = Type("Structure") Then
		FillPropertyValues(Result, SavedParameters);
	EndIf;
	
	Return Result;
	
EndFunction

// Initiates the lock parameters of online support services.
// 
// Returns:
//  Structure - The default lock parameters.:
//    * IsOnlineSupportServicesAccessLocked - Boolean - Resource lock flag.
//    * OnlineSupportServicesHosts - FixedMap - See OnlineSupportServicesHosts
//                                                                   ;
//    * OnlineSupportServices - Map - See OnlineSupportServices
//                                                ;
//
Function OnlineSupportServicesNewLockParameters()
	
	OnlineSupportServicesHosts = OnlineSupportServicesHosts();
	OnlineSupportServices = OnlineSupportServices(OnlineSupportServicesHosts);
	
	Result = New Structure;
	Result.Insert("IsOnlineSupportServicesAccessLocked", False);
	Result.Insert("OnlineSupportServicesHosts", OnlineSupportServicesHosts);
	Result.Insert("OnlineSupportServices", OnlineSupportServices);
	
	Return Result;
	
EndFunction

// Initiates the details of the used Online Support resources.
// 
// Returns:
//  FixedMap - The details of the used resources.
//
Function OnlineSupportServicesHosts()
	
	OnlineSupportServicesHosts = New Map;
	
	If Not Common.DataSeparationEnabled() Then
		
		OnlineSupportServicesHosts.Insert(
			OnlineUserSupportClientServer.LoginServiceHost(0),
			NStr("ru = 'Сервисы аутентификации';
				|en = 'Authentication services';"));
		OnlineSupportServicesHosts.Insert(
			OnlineUserSupportClientServer.LoginServiceHost(1),
			NStr("ru = 'Сервисы аутентификации';
				|en = 'Authentication services';"));
	
		If Common.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
			ModuleGetApplicationUpdates = Common.CommonModule("GetApplicationUpdates");
			ModuleGetApplicationUpdates.OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts);
		EndIf;
		
		If Common.SubsystemExists("OnlineUserSupport.PortalMonitor1CITS") Then
			ModuleOneCITSPortalDashboard = Common.CommonModule("PortalMonitor1CITS");
			ModuleOneCITSPortalDashboard.OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts);
		EndIf;
		
		If Common.SubsystemExists("OnlineUserSupport.MessagesToTechSupportService") Then
			TheModuleOfTheMessageToTheTechnicalSupportService = Common.CommonModule("MessagesToTechSupportService");
			TheModuleOfTheMessageToTheTechnicalSupportService.OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts);
		EndIf;
		
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.EnableMaintenanceServices") Then
		ModuleMaintenanceServicesActivation = Common.CommonModule("EnableMaintenanceServices");
		ModuleMaintenanceServicesActivation.OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.Connecting1CTaxi") Then
		ModuleOneCTaxcomConnection = Common.CommonModule("Connecting1CTaxi");
		ModuleOneCTaxcomConnection.OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.WorkingWithCounterparties") Then
		ModuleCounterpartiesFunctions = Common.CommonModule("WorkingWithCounterparties");
		ModuleCounterpartiesFunctions.OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		ModuleSPARKRisksService = Common.CommonModule("СервисСПАРКРиски");
		ModuleSPARKRisksService.OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.News_") Then
		ModuleNewsProcessingInternal = Common.CommonModule("ОбработкаНовостейСлужебный");
		ModuleNewsProcessingInternal.OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		ModuleClassifiersOperations.OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		ModuleGetAddIns = Common.CommonModule("GetAddIns");
		ModuleGetAddIns.OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.InstantPayments") Then
		ModuleFasterPaymentSystemInternal = Common.CommonModule("InstantPaymentsInternal");
		ModuleFasterPaymentSystemInternal.OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		ModuleOnlinePaymentInternal = Common.CommonModule("OnlinePaymentInternal");
		ModuleOnlinePaymentInternal.OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.FDO") Then
		ModuleFDOInternal = Common.CommonModule("FDOInternal");
		ModuleFDOInternal.OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.ИнтеграцияСЦРПТ") Then
		ModuleIntegrationOfTheSRPT = Common.CommonModule("ИнтеграцияСЦРПТ");
		ModuleIntegrationOfTheSRPT.OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.GettingStatutoryReports") Then
		StatutoryReportsGetterModule = Common.CommonModule("GettingStatutoryReports");
		StatutoryReportsGetterModule.OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.CloudArchive20") Then
		ModuleCloudArchive20 = Common.CommonModule("CloudArchive20");
		ModuleCloudArchive20.OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts);
	EndIf;
	
	Result = New FixedMap(OnlineSupportServicesHosts);
	
	Return Result;
	
EndFunction

// Initiates the details of the used Online Support services.
//
// Parameters:
//  OnlineSupportServicesHosts - FixedMap - See OnlineSupportServicesHosts.
// 
// Returns:
//  Map - The details of the used services.
//
Function OnlineSupportServices(OnlineSupportServicesHosts)
	
	Result = New Map;
	For Each ServiceHost In OnlineSupportServicesHosts Do
		Result.Insert(
			ServiceHost.Value,
			New Structure(
				"NameOfService, CanBeManaged",
				ServiceHost.Value,
				False));
	EndDo;
	
	Return Result;
	
EndFunction

// Saves the passed parameters for the Online Support service lock.
//
// Parameters:
//  LockParameters - Structure - See OnlineSupportServicesNewLockParameters.
//
Procedure SaveLockParameters(LockParameters)
	
	SetPrivilegedMode(True);
	
	ValueStorage = New ValueStorage(LockParameters);
	Constants.OnlineSupportServicesAccessLockParameters.Set(ValueStorage);
	
	SetPrivilegedMode(False);
	
EndProcedure

// Lock of the stored parameters for online support services.
//
Procedure BlockLockParametersData()
	
	Block = New DataLock;
	Block.Add("Constant.OnlineSupportServicesAccessLockParameters");
	Block.Lock();
	
EndProcedure

#EndRegion

#Region OtherServiceProceduresFunctions

// Returns the name of an event for logging
// online support errors.
//
// Returns:
//	String - Name of the online support error event.
//
Function EventLogEventName()
	
	Return NStr("ru = 'Интернет-поддержка пользователей';
				|en = 'Online support';",
		Common.DefaultLanguageCode());
	
EndFunction

// Returns the minimum SSL version
// that supports OSL.
//
// Returns:
//   String - SSL version number
//
Function MinSSLVersion() Export
	
	Return "3.1.9.34";
	
EndFunction

#EndRegion

#EndRegion
