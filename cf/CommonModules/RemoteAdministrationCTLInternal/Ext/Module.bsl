////////////////////////////////////////////////////////////////////////////////
// Remote administration subsystem.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Fills a structure with arrays of supported versions of the subsystems that are subject to versioning.
// Subsystem names are used as structure keys.
// Implements the InterfaceVersion web service functionality.
// When integrating, change the procedure body so that it returns current version sets (see the example below).
//
// Parameters:
//  SupportedVersionsStructure - Structure - Supported versions structure:
//	  * Keys - String - a subsystem name. 
//	  * Values - Array - Supported version names.
//
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export

	VersionsArray = New Array;
	VersionsArray.Add("1.0.0.1");
	SupportedVersionsStructure.Insert("ManagedApplication", VersionsArray);

EndProcedure

#EndRegion 

#Region Internal

// Checks if the session belongs to the current data area.
//
// Parameters:
//  SessionNumber - Number - a session number whose belonging to the current data area is being checked.
//
// Returns:
//  Boolean - indicates whether the session belongs to the current data area.
//
Function CheckWhetherSessionBelongsToCurDataArea(Val SessionNumber) Export
	
	AreaSessions = GetInfoBaseSessions();
	For Each SessionArea In AreaSessions Do
		If SessionArea.SessionNumber = SessionNumber Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Terminates session of a data area user.
//
// Parameters:
//  SessionsNumbers - Array - an array of session numbers.
//  UserPassword - String - a password of the current data area user.
//  MessageToUsers - String - Session end user message.
//
Procedure EndDataAreaSessions(Val SessionsNumbers, Val UserPassword, Val MessageToUsers) Export

	AuthorizationParameters = AuthorizationParametersForManagingApplication(UserPassword);
	ServiceVersionOfManagingApplication = VersionOfManagementApplicationServiceUsed(AuthorizationParameters);
	If CommonClientServer.CompareVersions(ServiceVersionOfManagingApplication, "1.0.3.3") < 0 Then
		Raise NStr(
			"ru = 'Текущая версия управляющего приложения не поддерживает завершение сеанса из приложений.';
			|en = 'The current version of the managing application does not support closing sessions from applications.';");
	EndIf;

	Proxy = ProxyServiceOfManagingApplication(AuthorizationParameters);
	SetPrivilegedMode(True);
	CurrentDataArea = SaaSOperations.SessionSeparatorValue();
	KeyCurDataArea = Constants.DataAreaKey.Get();
	SetPrivilegedMode(False);

	If CommonClientServer.CompareVersions(ServiceVersionOfManagingApplication, "1.0.3.4") >= 0 Then

		ErrorInfo = Undefined;
		InformationAboutSessionNumbers = GiveSessionNumbers(SessionsNumbers, Proxy.XDTOFactory);

		If CommonClientServer.CompareVersions(ServiceVersionOfManagingApplication, "1.0.3.6") >= 0 Then
			OperationName = "TerminateSessionsWithMessage";
			Proxy.TerminateSessionsWithMessage(
				CurrentDataArea,
				KeyCurDataArea,
				InformationAboutSessionNumbers,
				MessageToUsers,
				ErrorInfo); 
		Else
			OperationName = "TerminateSessions";
			Proxy.TerminateSessions(
				CurrentDataArea,
				KeyCurDataArea,
				InformationAboutSessionNumbers,
				ErrorInfo);
		EndIf;
		
		SaaSOperations.HandleWebServiceErrorInfo(
			ErrorInfo,
			Metadata.Subsystems.CloudTechnology.Subsystems.RemoteAdministration,
			ServiceInterfaceOfManagingApplication(),
			OperationName);

	Else

		For Each SessionNumber In SessionsNumbers Do

			ErrorInfo = Undefined;
			Proxy.TerminateSession(
				CurrentDataArea,
				KeyCurDataArea,
				SessionNumber,
				ErrorInfo);

			SaaSOperations.HandleWebServiceErrorInfo(
				ErrorInfo,
				Metadata.Subsystems.CloudTechnology.Subsystems.RemoteAdministration,
				ServiceInterfaceOfManagingApplication(),
				"TerminateSession");

		EndDo;

	EndIf;

EndProcedure

// Returns a name of the managing application interface.
//
// Returns:
//  String - an interface name.
//
Function ServiceInterfaceOfManagingApplication() Export

	Return "ManageApplication"; // Not localizable.

EndFunction

// Managing application authentication parameters.
// 
// Parameters:
// 	UserPassword - String - User password. 
// 	If not specified or empty string, then takes the active user's username. 
// Returns:
// 	Structure - Details.:
// * Address - String - Internal Service Manager URL.
// * User - String - Username.
// * Password - String
Function AuthorizationParametersForManagingApplication(Val UserPassword = Undefined) Export

	SetPrivilegedMode(True);
	Address = SaaSOperations.InternalServiceManagerURL();
	If Not ValueIsFilled(Address) Then
		Raise NStr("ru = 'Не указан внутренний адрес Менеджера сервиса';
								|en = 'Internal Service Manager URL is not specified';");
	EndIf;
	If UserPassword <> Undefined Then
		User = UserName();
		Password = UserPassword;
	Else
		User = SaaSOperations.ServiceManagerInternalUserName();
		Password = SaaSOperations.ServiceManagerInternalUserPassword();
	EndIf;
	SetPrivilegedMode(False);
	If Not ValueIsFilled(User) Then
		Raise NStr("ru = 'Не указан пользователь для авторизации в Менеджере сервиса';
								|en = 'No user is specified for authorization in Service Manager';");
	EndIf;

	Return New Structure("Address, User, Password", Address, User, Password);

EndFunction

// The used version of the managing application service.
// 
// Parameters:
// 	AuthorizationParameters - Structure - See AuthorizationParametersForManagingApplication
//                                     ()
// 	RequiredVersion - String, Undefined - If not specified, gets the latest of the supported versions.
// Returns:
// 	String - Version of Service Manager ws ManageApplication_a_b_c_d.
Function VersionOfManagementApplicationServiceUsed(AuthorizationParameters, RequiredVersion = Undefined) Export

	InterfaceName = ServiceInterfaceOfManagingApplication();
	SupportedVersions = Common.GetInterfaceVersions(AuthorizationParameters.Address,
		AuthorizationParameters.User, AuthorizationParameters.Password, InterfaceName);

	If Not ValueIsFilled(SupportedVersions) Then
		Raise StrTemplate(NStr("ru = 'Корреспондент %1 не поддерживает интерфейс %2';
										|en = 'Peer infobase %1 does not support interface %2';"),
			AuthorizationParameters.Address, InterfaceName);
	EndIf;

	VersionUsed_ = Undefined;

	For Each SupportedVersion In SupportedVersions Do
		If Not ValueIsFilled(RequiredVersion) Then
			If VersionUsed_ = Undefined Or CommonClientServer.CompareVersions(SupportedVersion,
				VersionUsed_) > 0 Then
				VersionUsed_ = SupportedVersion;
			EndIf;
		ElsIf RequiredVersion = SupportedVersion Then
			VersionUsed_ = SupportedVersion;
			Break;
		EndIf;
	EndDo;

	If ValueIsFilled(RequiredVersion) And Not ValueIsFilled(VersionUsed_) Then
		Raise StrTemplate(NStr("ru = 'Корреспондент %1 не поддерживает интерфейс %2 требуемой версии %3';
										|en = 'Peer infobase %1 does not support interface %2 of required version %3';"),
			AuthorizationParameters.Address, InterfaceName, RequiredVersion);
	EndIf;

	Return VersionUsed_;

EndFunction

// Returns the proxy for the latest of the supported Service Manager versions.
// 
// Parameters:
// 	AuthorizationParameters - Structure - See AuthorizationParametersForManagingApplication
//                                     ()
// 	RequiredVersion - String, Undefined - If not specified, gets the proxy for the latest of the supported versions.
// Returns:
// 	WSProxy - Proxy of Service Manager ws ManageApplication_a_b_c_d.
Function ProxyServiceOfManagingApplication(AuthorizationParameters, RequiredVersion = Undefined) Export

	VersionUsed_ = VersionOfManagementApplicationServiceUsed(AuthorizationParameters, RequiredVersion);
	ConnectionParameters = Common.WSProxyConnectionParameters();
	ConnectionParameters.WSDLAddress = AuthorizationParameters.Address + "/ws/ManageApplication_" + StrReplace(
		VersionUsed_, ".", "_") + "?wsdl";
	ConnectionParameters.NamespaceURI = "http://www.1c.ru/SaaS/ManageApplication/" + VersionUsed_;
	ConnectionParameters.ServiceName = "ManageApplication_" + StrReplace(VersionUsed_, ".", "_");
	ConnectionParameters.EndpointName = "";
	ConnectionParameters.UserName = AuthorizationParameters.User;
	ConnectionParameters.Password = AuthorizationParameters.Password;
	ConnectionParameters.Timeout = 60;

	Return Common.CreateWSProxy(ConnectionParameters);

EndFunction

#EndRegion

#Region Private

// Casts an array of session numbers to XDTOObject.
//
// Parameters:
//  SessionsNumbers - Array of Number - an array of session numbers.
//  Factory - XDTOFactory - XDTO factory.
//
// Returns:
//  XDTODataObject - a list of session numbers.
//
Function GiveSessionNumbers(Val SessionsNumbers, Val Factory) Export
	
	SessionNumberListType = Factory.Type("http://www.1c.ru/1cFresh/ManageApplication/1.0.3.4", "SessionNumberList");
	ListOfSessionNumbers = Factory.Create(SessionNumberListType);
	
	For Each SessionNumber In SessionsNumbers Do
		NumbersList = ListOfSessionNumbers.SessionNumbers; // XDTOList
		NumbersList.Add(SessionNumber);
	EndDo;
	
	Return ListOfSessionNumbers;
	
EndFunction

#EndRegion
