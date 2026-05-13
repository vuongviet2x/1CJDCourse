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
// CommonModule.OnlineUserSupportClient.
//
// Client procedures and functions:
//  - Determine connection settings
//  - Navigate to connecting Online Support
//  - Navigate to integrated websites
//  - Handle app events
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Common

// Returns settings of connection to online support servers.
//
// Returns:
//  Structure - connection settings. Structure fields:
//      * EstablishConnectionAtServer - Boolean - True if connection
//        is established on 1C:Enterprise server.
//      * ConnectionTimeout - Number - Timeout of connection to servers in seconds.
//      * OUSServersDomain - Number - if 0, connect
//        to OUS servers in 1c.ru domain zone. If 1, connect in 1c.eu domain zone.
//
Function ServersConnectionSettings() Export
	
	ClientRunParameters = StandardSubsystemsClient.ClientRunParameters().OnlineUserSupport;
	Result = New Structure("OUSServersDomain");
	FillPropertyValues(Result, ClientRunParameters);
	Result.Insert("EstablishConnectionAtServer", True);
	Result.Insert("ConnectionTimeout"               , 30);
	Return Result;
	
EndFunction

#EndRegion

#Region OnlineSupportServicesAuthentication

// Connects to online support service: entering
// authentication data (username and password) to connect to services of
// online support.
// Upon successful completion, the entered username is returned via
// the NotifyDescription object.
//
// Parameters:
//  CallbackOnCompletion - NotifyDescription - A completion notification handler.
//          The following value is returned to the notification handler:
//          Undefined - If a user clicks Cancel.
//          Structure - If a user entered the correct credentials.
//          Structure fields:
//            * Login - String - the entered username.
//  FormOwner - ClientApplicationForm - an owner of the
//          online support connection form. As online support connection form opens
//          in the "Lock owner window" mode, it is recommended that you fill in
//          this parameter value.
//
Procedure EnableInternetUserSupport(
		CallbackOnCompletion = Undefined,
		FormOwner = Undefined) Export
	
	If StandardSubsystemsClient.ClientRunParameters().DataSeparationEnabled Then
		
		NotificationAuthorizationUnavailable = New NotifyDescription(
			"OnOUSConnectionUnavailability",
			ThisObject,
			CallbackOnCompletion);
		
		ShowMessageBox(
			NotificationAuthorizationUnavailable,
			NStr("ru = 'Использование Интернет-поддержки пользователей недоступно при работе в модели сервиса.';
				|en = 'Online support cannot be used in SaaS.';"));
		Return;
		
	EndIf;
	
	// Checking user rights for interactive authorization.
	If Not CanConnectOnlineUserSupport() Then
		
		NotificationAuthorizationUnavailable = New NotifyDescription(
			"OnOUSConnectionUnavailability",
			ThisObject,
			CallbackOnCompletion);
		
		ShowMessageBox(
			NotificationAuthorizationUnavailable,
			NStr("ru = 'Недостаточно прав для подключения Интернет-поддержки пользователей. Обратитесь к администратору.';
				|en = 'Insufficient rights to enable online support. Contact the administrator.';"));
		Return;
		
	EndIf;
	
	// Opening an OUS connection form.
	OpenForm("CommonForm.CanEnableOnlineSupport",
		,
		FormOwner,
		,
		,
		,
		CallbackOnCompletion);
	
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
	
	ClientRunParameters = StandardSubsystemsClient.ClientRunParameters().OnlineUserSupport;
	Return ClientRunParameters.CanConnectOnlineUserSupport;
	
EndFunction

#EndRegion

#Region ClickOnTheLinkToThePortal

// Opens a page of the website whose authentication system is integrated with
// 1C:ITS Portal.
// Depending on the current infobase mode and whether
// the current infobase user has the appropriate rights,
// the page can be opened with accountant data of 1C:ITS Portal user,
// for which online support is enabled.
//
// Parameters:
//  WebsitePageURL - String - Website page URL.
//  WindowTitle - String - Window title for methods:
//      - ИнтернетПоддержкаПользователейКлиентПереопределяемый.ОткрытьИнтернетСтраницу()
//      - ИнтеграцияПодсистемБИПКлиент.ОткрытьИнтернетСтраницу(),
//        if used.
//
Procedure OpenIntegratedWebsitePage(WebsitePageURL, WindowTitle = "") Export
	
	Status(, , NStr("ru = 'Пожалуйста, подождите...';
						|en = 'Please wait…';"));
	URLGetResult =
		OnlineUserSupportServerCall.InternalURLToNavigateToIntegratedWebsitePage(
			WebsitePageURL);
	Status();
	
	If Not IsBlankString(URLGetResult.ErrorCode)
		And URLGetResult.ErrorCode <> "InvalidUsernameOrPassword" Then
		ShowUserNotification(
			,
			,
			NStr("ru = 'Ошибка входа на Портал 1С:ИТС.
				|Подробнее см. в журнале регистрации.';
				|en = 'An error occurred while logging on to 1C:ITS Portal.
				|See the event log for details.';"),
			PictureLib.Error32);
	EndIf;
	
	StandardProcessing = True;
	OSLSubsystemsIntegrationClient.OpenInternetPage(
		URLGetResult.URL,
		WindowTitle,
		StandardProcessing);
	OnlineUserSupportClientOverridable.OpenInternetPage(
		URLGetResult.URL,
		WindowTitle,
		StandardProcessing);
	
	If StandardProcessing = True Then
		// Opening a web page using a standard way.
		FileSystemClient.OpenURL(URLGetResult.URL);
	EndIf;
	
EndProcedure

// Opens a Portal home page.
//
Procedure OpenPortalMainPage() Export
	
	OpenWebPage(
		OnlineUserSupportClientServer.SupportPortalPageURL(
			"?needAccessToken=true",
			ServersConnectionSettings().OUSServersDomain),
		NStr("ru = 'Портал 1С:ИТС';
			|en = '1C:ITS Portal';"));
	
EndProcedure

// Opens a Portal page to register a new user.
//
Procedure OpenNewUserRegistrationPage() Export
	
	OpenWebPage(
		OnlineUserSupportClientServer.LoginServicePageURL(
			"/registration",
			ServersConnectionSettings()),
		NStr("ru = 'Регистрация';
			|en = 'Registration';"));
	
EndProcedure

// Opens a Portal page to recover a password.
//
Procedure OpenPasswordRecoveryPage() Export
	
	OpenWebPage(
		OnlineUserSupportClientServer.LoginServicePageURL(
			"/remind_request",
			ServersConnectionSettings()),
		NStr("ru = 'Восстановление пароля';
			|en = 'Password recovery';"));
	
EndProcedure

#EndRegion

#Region IntegrationWithStandardSubsystemsLibrary

// See the CommonClientOverridable.OnStart procedure.
//
Procedure OnStart(Parameters) Export
	
	// EnableMaintenanceServices
	If CommonClient.SubsystemExists("OnlineUserSupport.EnableMaintenanceServices") Then
		ModuleMaintenanceServicesActivationClient = CommonClient.CommonModule("EnableMaintenanceServicesClient");
		ModuleMaintenanceServicesActivationClient.OnStart();
	EndIf;
	// End EnableMaintenanceServices
	
	// GetApplicationsUpdates
	If CommonClient.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		ModuleGetApplicationUpdatesClient = CommonClient.CommonModule("GetApplicationUpdatesClient");
		ModuleGetApplicationUpdatesClient.OnStart();
	EndIf;
	// End GetApplicationUpdatesClient
	
	// OneCITSPortalDashboard
	If CommonClient.SubsystemExists("OnlineUserSupport.PortalMonitor1CITS") Then
		ModuleOneCITSPortalDashboardClient = CommonClient.CommonModule("PortalMonitor1CITSClient");
		ModuleOneCITSPortalDashboardClient.OnStart();
	EndIf;
	// End OneCITSPortalDashboard
	
	// SPARKRisks
	If CommonClient.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		ModuleSPARKRisksClient = CommonClient.CommonModule("SparkRisksClient");
		ModuleSPARKRisksClient.OnStart();
	EndIf;
	// End SPARKRisks
	
	// CloudArchive20
	If CommonClient.SubsystemExists("OnlineUserSupport.CloudArchive20") Then
		ModuleCloudArchive20Client = CommonClient.CommonModule("CloudArchive20Client");
		ModuleCloudArchive20Client.OnStart(Parameters);
	EndIf;
	// End CloudArchive20
	
	// ClassifiersOperations
	If CommonClient.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperationsClient = CommonClient.CommonModule("ClassifiersOperationsClient");
		ModuleClassifiersOperationsClient.OnStart();
	EndIf;
	// End ClassifiersOperations
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

#Region Common

// Converts a value from the fixed type.
// Parameters:
//  FixedTypeValue - Arbitrary - Fixed type value,
//       from which an unfixed type value must be received.
//
// Returns:
//  Arbitrary - a received value of a similar unfixed type.
//
Function ValueFromFixedType(FixedTypeValue) Export

	Result = Undefined;
	ValueType = TypeOf(FixedTypeValue);

	If ValueType = Type("FixedStructure") Then

		Result = New Structure;
		For Each KeyValue In FixedTypeValue Do
			Result.Insert(KeyValue.Key, ValueFromFixedType(KeyValue.Value));
		EndDo;

	ElsIf ValueType = Type("FixedMap") Then

		Result = New Map;
		For Each KeyValue In FixedTypeValue Do
			Result.Insert(KeyValue.Key, ValueFromFixedType(KeyValue.Value));
		EndDo;

	ElsIf ValueType = Type("FixedArray") Then

		Result = New Array;
		For Each ArrayElement In FixedTypeValue Do
			Result.Add(ValueFromFixedType(ArrayElement));
		EndDo;

	Else

		Result = FixedTypeValue;

	EndIf;

	Return Result;

EndFunction

// client application parameters.
//
// Sets an application parameter value.
//
// Parameters:
//  ParameterName - String - Parameter ID.
//  DefaultValue - Arbitrary - default parameter value;
//
// Returns:
//  Arbitrary - a parameter value.
//
Function ApplicationParameterValue(ParameterName, DefaultValue = Undefined) Export

	LibraryParameters = ApplicationParameters.Get("OnlineUserSupport");
	If LibraryParameters = Undefined Then
		Return DefaultValue;
	EndIf;

	ParameterValue = LibraryParameters.Get(ParameterName);
	Return ?(ParameterValue = Undefined, DefaultValue, ParameterValue);

EndFunction

// Sets an application parameter value.
//
// Parameters:
//  ParameterName - String - Parameter ID.
//  ParameterValue - Arbitrary - a new parameter value.
//
Procedure SetApplicationParameterValue(ParameterName, ParameterValue) Export

	LibraryParameters = ApplicationParameters.Get("OnlineUserSupport");
	If LibraryParameters = Undefined Then
		LibraryParameters = New Map;
		ApplicationParameters.Insert(
			"OnlineUserSupport",
			LibraryParameters);
	EndIf;

	LibraryParameters.Insert(ParameterName, ParameterValue);

EndProcedure

// Returns a title text of a form item from a string or a formatted string.
//
Function FormattedHeaderText(Title) Export
	
	If TypeOf(Title) <> Type("FormattedString") Then
		Return Title;
	EndIf;
	
	FormattedDoc = New FormattedDocument;
	FormattedDoc.SetFormattedString(Title);
	Return FormattedDoc.GetText();
	
EndFunction

// Controls the visibility of the "Copy to clipboard" button.
//
// Parameters:
//  Items - FormAllItems - Owner form items.
//
Procedure SetDisplayOfButtonCopyToClipboard(Items) Export
	
	ClientPlatformType = CommonClient.ClientPlatformType();	
	#If WebClient Then 
		IsWebClient = True;
	#Else
		IsWebClient = False;
	#EndIf
		
	ShowButtonCopyToClipboard = (ClientPlatformType = PlatformType.Windows_x86 
		Or ClientPlatformType = PlatformType.Windows_x86_64)
		And Not IsWebClient;
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"DoCopyToClipboard",
		"Visible",
		ShowButtonCopyToClipboard);
		
EndProcedure

#EndRegion

#Region ClickOnTheLinkToThePortal

// Opens a web page in the browser.
//
// Parameters:
//  PageAddress - String - URL of a page to open.
//  WindowTitle - String - Title of the page
//   being opened if the internal configuration form is used to open the page.
//  Login - String - Username to authorize on the online support portal.
//  Password - String - Password to authorize on the online support portal.
//
Procedure OpenWebPage(
		Val PageAddress,
		WindowTitle = "",
		Login = Undefined,
		Password = Undefined) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("WindowTitle", WindowTitle);
	AdditionalParameters.Insert("Login"        , Login);
	AdditionalParameters.Insert("Password"       , Password);
	
	OpenWebPageWithAdditionalParameters(
		PageAddress,
		AdditionalParameters);
	
EndProcedure

// Opens a web page in the browser.
//
// Parameters:
//  PageAddress - String - URL of a page to open.
//  AdditionalParameters - Structure, Undefined - additional page opening parameters.
//
Procedure OpenWebPageWithAdditionalParameters(
	Val PageAddress,
	Val AdditionalParameters = Undefined) Export
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("WindowTitle"              , "");
	OpeningParameters.Insert("Login"                      , "");
	OpeningParameters.Insert("Password"                     , "");
	OpeningParameters.Insert("IsFullUser", Undefined);
	OpeningParameters.Insert("ProxySettings"            , Undefined);
	OpeningParameters.Insert("ConnectionSetup"        , Undefined);
	OpeningParameters.Insert("DataSeparationEnabled"         , False);
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FillPropertyValues(OpeningParameters, AdditionalParameters);
	EndIf;
	
	If OpeningParameters.IsFullUser = Undefined Then
		ClientRunParameters = StandardSubsystemsClient.ClientRunParameters();
		OpeningParameters.IsFullUser =
			ClientRunParameters.IsFullUser;
		OpeningParameters.DataSeparationEnabled = ClientRunParameters.DataSeparationEnabled;
	EndIf;
	
	AuthorizationRequired = (StrFind(PageAddress, "?needAccessToken=true") > 0
		Or StrFind(PageAddress, "&needAccessToken=true") > 0);
	
	If AuthorizationRequired Then
		// Deleting a parameter from URL
		
		PageAddress = StrReplace(PageAddress, "?needAccessToken=true&", "");
		PageAddress = StrReplace(PageAddress, "?needAccessToken=true" , "");
		PageAddress = StrReplace(PageAddress, "&needAccessToken=true&", "");
		PageAddress = StrReplace(PageAddress, "&needAccessToken=true" , "");
		
	EndIf;
	
	URL = PageAddress;
	If AuthorizationRequired And OpeningParameters.IsFullUser Then
		
		// Getting a URL to open the page.
		Status(, , NStr("ru = 'Переход на Портал 1С:ИТС';
							|en = 'Go to 1C:ITS Portal';"));
		URLGetResult =
			OnlineUserSupportServerCall.InternalURLToNavigateToIntegratedWebsitePage(PageAddress);
		Status();
		
		If Not IsBlankString(URLGetResult.ErrorCode)
			And URLGetResult.ErrorCode <> "InvalidUsernameOrPassword" Then
			ShowUserNotification(
				,
				,
				NStr("ru = 'Ошибка входа на Портал 1С:ИТС.
					|Подробнее см. в журнале регистрации.';
					|en = 'An error occurred while logging on to 1C:ITS Portal.
					|See the event log for details.';"),
				PictureLib.Error32);
		EndIf;
		
		URL = URLGetResult.URL;
		
	EndIf;
	
	StandardProcessing = True;
	OSLSubsystemsIntegrationClient.OpenInternetPage(
		URL,
		OpeningParameters.WindowTitle,
		StandardProcessing);
	OnlineUserSupportClientOverridable.OpenInternetPage(
		URL,
		OpeningParameters.WindowTitle,
		StandardProcessing);
	
	If StandardProcessing = True Then
		// Opening a web page using a standard way.
		FileSystemClient.OpenURL(URL);
	EndIf;
	
EndProcedure

// Opens a user account in the browser.
//
Procedure OpenUserPersonalAccount() Export
	
	OpenWebPage(
		OnlineUserSupportClientServer.SupportPortalPageURL(
			"/software?needAccessToken=true",
			ServersConnectionSettings().OUSServersDomain),
		NStr("ru = 'Личный кабинет пользователя';
			|en = 'User account';"));
	
EndProcedure

// Opens a user account in the browser.
//
Procedure OpenOfficialSupportPage() Export
	
	OpenWebPage(
		OnlineUserSupportClientServer.SupportPortalPageURL(
			"/support?needAccessToken=true",
			ServersConnectionSettings().OUSServersDomain),
		NStr("ru = 'Официальная поддержка';
			|en = 'Official support';"));
	
EndProcedure

#EndRegion

#Region DisplayOfSecretDataOnForm

// Controls the visibility of the conceal button.
//
// Parameters:
//  Item  - FormField - The form item containing confidential data.
//
Procedure OnChangeSecretData(Item) Export
	
	If Item.ChoiceButton = Undefined Then
		Item.ChoiceButtonPicture = PictureLib.CharsBeingTypedShown;
		Item.ChoiceButton = True;
	EndIf;
	
EndProcedure

// Toggles the visibility of the confidential data characters.
//
// Parameters:
//  Form - ClientApplicationForm - The form that processes confidential data.
//  Item - FormField - The form item containing confidential data.
//  AttributeName - String - The name of the form attribute for data update.
//
Procedure ShowSecretData(Form, Item, AttributeName) Export
	
	Item.PasswordMode = Not Item.PasswordMode;
	Form[AttributeName] = Item.EditText;
	If Item.PasswordMode Then
		Item.ChoiceButtonPicture = PictureLib.CharsBeingTypedShown;
	Else
		Item.ChoiceButtonPicture = PictureLib.CharsBeingTypedHidden;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Processing a notification of the online support connection unavailability.
//
// Parameters:
//  CallbackOnCompletion - NotifyDescription - a notification for a call.
//
Procedure OnOUSConnectionUnavailability(CallbackOnCompletion) Export

	If CallbackOnCompletion <> Undefined Then
		ExecuteNotifyProcessing(CallbackOnCompletion, Undefined);
	EndIf;

EndProcedure

#EndRegion
