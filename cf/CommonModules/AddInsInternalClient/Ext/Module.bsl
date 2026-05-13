///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Internal

Procedure CheckTheLocationOfTheComponent(Id, Location) Export
	
	If StrStartsWith(Location, "e1cib/data/Catalog.AddIns.AddInStorage") Then
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.SaaSOperations.AddInsSaaS") Then
		ModuleAddInsSaaSInternalClient = CommonClient.CommonModule("AddInsSaaSInternalClient");
		If ModuleAddInsSaaSInternalClient.IsComponentFromStorage(Location) Then
			Return;
		EndIf;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" в клиентском приложении
		           |по причине:
		           |указано некорректное местоположение внешней компоненты
		           |%2';
					|en = 'Cannot attach the %1 add-in in the client application
					|due to:
					|Add-in
					|%2 location is incorrect';"),
		Id, Location);

EndProcedure

// Parameters:
//  Notification - NotifyDescription
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Procedure CheckAddInAvailability(Notification, Context) Export
	
	ThePathToTheLayoutToSearchForTheLatestVersion = Undefined;
	SearchForAComponentOfTheLatestVersion = ValueIsFilled(Context.OriginalLocation) And Not Context.ASearchForANewVersionHasBeenPerformed; 
	If SearchForAComponentOfTheLatestVersion Then
		ThePathToTheLayoutToSearchForTheLatestVersion = Context.OriginalLocation;
	EndIf;
	
	Information = AddInsInternalServerCall.SavedAddInInformation(
		Context.Id, Context.Version, ThePathToTheLayoutToSearchForTheLatestVersion);
	
	Context.Location = Information.Location;
	
	// Information.State:
	// * IsNotFound
	// * FoundInStorage
	// * FoundInSharedStorage
	// * DisabledByAdministrator
	
	Result = AddInAvailabilityResult();
	Result.TheComponentOfTheLatestVersion = Information.TheLatestVersionOfComponentsFromTheLayout;
	Result.Location = Information.Location;
	
	If Information.State = "DisabledByAdministrator" Then 
		
		Result.ErrorDescription = NStr("ru = 'Отключена администратором.';
										|en = 'Disabled by administrator.';");
		ExecuteNotifyProcessing(Notification, Result);
		
	ElsIf Information.State = "NotFound1" Then 
		
		If Information.CanImportFromPortal 
			And Context.SuggestToImport Then 
			
			SearchContext = New Structure;
			SearchContext.Insert("Notification", Notification);
			SearchContext.Insert("Context", Context);
			
			NotificationForms = New NotifyDescription(
				"CheckAddInAvailabilityAfterSearchingAddInOnPortal",
				ThisObject, 
				SearchContext);
				
			Notification = New NotifyDescription("AddInSearchOnPortalOnGenerateResult", ThisObject, NotificationForms);
			AddInsClientLocalization.ComponentSearchOnPortal(Notification, Context);
			
		Else 
			Result.ErrorDescription = NStr("ru = 'Компонента отсутствует в списке разрешенных внешних компонент.';
											|en = 'The add-in is missing from the list of allowed add-ins.';");
			ExecuteNotifyProcessing(Notification, Result);
		EndIf;
		
	Else
		
		Result.Insert("Version", Information.Attributes.Version);
		ShouldAttachAddInFromTemplate = False;
		If SearchForAComponentOfTheLatestVersion Then
			ReplaceWithCurrentComponentFromCatalog(Result, Context.Id, Information.Location, ShouldAttachAddInFromTemplate);
		EndIf;
		
		If ShouldAttachAddInFromTemplate
			Or Not Information.IsTargetPlatformsFilled
			Or CurrentClientIsSupportedByAddIn(Information.Attributes.TargetPlatforms) Then
			
			Result.Available = True;
			ExecuteNotifyProcessing(Notification, Result);
			
		Else 
			
			NotificationParameters = New Structure;
			NotificationParameters.Insert("Notification", Notification);
			NotificationParameters.Insert("Result", Result);
			
			NotificationForms = New NotifyDescription(
				"CheckAddInAvailabilityAfterDisplayingAvailableClientTypes",
				ThisObject,
				NotificationParameters);
				
			If Not Context.SuggestInstall Then
				ExecuteNotifyProcessing(NotificationForms, False);
				Return;
			EndIf;
			
			FormParameters = New Structure;
			FormParameters.Insert("ExplanationText", Context.ExplanationText);
			FormParameters.Insert("SupportedClients", Information.Attributes.TargetPlatforms);
			
			OpenForm("CommonForm.CannotInstallAddIn",
				FormParameters,,,,, NotificationForms);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Async Function AddInAvailabilityCheckResult(Context) Export
	
	ThePathToTheLayoutToSearchForTheLatestVersion = Undefined;
	SearchForAComponentOfTheLatestVersion = ValueIsFilled(Context.OriginalLocation) And Not Context.ASearchForANewVersionHasBeenPerformed; 
	If SearchForAComponentOfTheLatestVersion Then
		ThePathToTheLayoutToSearchForTheLatestVersion = Context.OriginalLocation;
	EndIf;
	
	Information = AddInsInternalServerCall.SavedAddInInformation(
		Context.Id, Context.Version, ThePathToTheLayoutToSearchForTheLatestVersion);
	
	Context.Location = Information.Location;
	
	// Information.State:
	// * IsNotFound
	// * FoundInStorage
	// * FoundInSharedStorage
	// * DisabledByAdministrator
	
	Result = AddInAvailabilityResult();
	Result.TheComponentOfTheLatestVersion = Information.TheLatestVersionOfComponentsFromTheLayout;
	Result.Location = Information.Location;
	
	If Information.State = "DisabledByAdministrator" Then 
		
		Result.ErrorDescription = NStr("ru = 'Отключена администратором.';
										|en = 'Disabled by administrator.';");
		Return Result;
		
	ElsIf Information.State = "NotFound1" Then 
		
		Result.ErrorDescription = NStr("ru = 'Компонента отсутствует в списке разрешенных внешних компонент.';
										|en = 'The add-in is missing from the list of allowed add-ins.';");
		
		Return Result;
		
	Else
		
		Result.Insert("Version", Information.Attributes.Version);
			
		ShouldAttachAddInFromTemplate = False;
		If SearchForAComponentOfTheLatestVersion Then
			ReplaceWithCurrentComponentFromCatalog(Result, Context.Id, Information.Location, ShouldAttachAddInFromTemplate);
		EndIf;
		
		If ShouldAttachAddInFromTemplate
			Or Not Information.IsTargetPlatformsFilled
			Or CurrentClientIsSupportedByAddIn(Information.Attributes.TargetPlatforms) Then
			
			Result.Available = True;
			Return Result;
		
		Else
			
			ErrorDescription = StringFunctionsClient.FormattedString(
				NStr("ru = 'Не предусмотрена работа внешней компоненты 
					 |в клиентском приложении <b>%1</b>.
					 |Обратитесь к разработчику внешней компоненты.';
					|en = 'Client application <b>%1</b>
					|does not support the add-in.
					|Contact the add-in developer.';"), PresentationOfCurrentClient());

			If Not Context.SuggestInstall Then
				Result.Available = False;
				Result.ErrorDescription = ErrorDescription;
			Else
				QuestionButtons = New ValueList;
				QuestionButtons.Add("Close", NStr("ru = 'Закрыть';
														|en = 'Close';"));
				QuestionButtons.Add("ResumeInstallationAttempt", NStr("ru = 'Продолжить попытку установки';
																			|en = 'Install anyway';"));

				QuestionTitle = Context.ExplanationText;
				If IsBlankString(QuestionTitle) Then
					QuestionTitle = NStr("ru = 'Установка внешней компоненты невозможна.';
											|en = 'Cannot install the add-in.';");
				EndIf;

				Response = Await DoQueryBoxAsync(ErrorDescription, QuestionButtons,, "Close", QuestionTitle);

				If Response = "ResumeInstallationAttempt" Then
					Result.Available = True;
				Else
					Result.Available = False;
					Result.ErrorDescription = ErrorDescription;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// See StandardSubsystemsClient.OnReceiptServerNotification
Procedure OnReceiptServerNotification(NameOfAlert, Result) Export
	
	If NameOfAlert <> "StandardSubsystems.AddIns" Then
		Return;
	EndIf;
	
	ApplicationParameters.Insert("StandardSubsystems.AddIns.SymbolicNames",
		New FixedMap(New Map));
	
	ApplicationParameters.Insert("StandardSubsystems.AddIns.Objects",
		New FixedMap(New Map));
	
EndProcedure

// Compatibility error with add-in from template.
// 
// Parameters:
//  Location - String - Template that contains the add-in.
// 
// Returns:
//  String - Compatibility error with add-in from template
//
Function TemplateAddInCompatibilityError(Location) Export
	
	AddInInfo = AddInsInternalServerCall.TemplateAddInInfo(Location);
		 
	If AddInInfo <> Undefined 
		And Not CurrentClientIsSupportedByAddIn(AddInInfo.Attributes.TargetPlatforms) Then
			Return AddInCompatibilityErrorDetails();
	EndIf;
	
	Return "";
	
EndFunction

// Check if the add-in from template is compatible.
// 
// Parameters:
//  Notification - NotifyDescription - Notify on the compatibility check and show a warning.
//  AddInAttachmentContext - See CommonInternalClient.AddInAttachmentContext
//
Procedure CheckTemplateAddInForCompatibility(Notification, AddInAttachmentContext) Export
	
	AddInInfo = AddInsInternalServerCall.TemplateAddInInfo(
		AddInAttachmentContext.Location);
		
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("ErrorDescription", "");
		 
	If AddInInfo <> Undefined 
		And Not CurrentClientIsSupportedByAddIn(AddInInfo.Attributes.TargetPlatforms) Then
		
		Context.ErrorDescription = AddInCompatibilityErrorDetails();
		
		If AddInAttachmentContext.SuggestInstall Then
			NotifyDescription = New NotifyDescription("AfterCompatibilityInfoDisplayed", ThisObject, Context);
			
			FormParameters = New Structure;
			FormParameters.Insert("ExplanationText", AddInAttachmentContext.ExplanationText);
			FormParameters.Insert("SupportedClients", AddInInfo.Attributes.TargetPlatforms);
			FormParameters.Insert("AfterConnectionErrorOccurred", True);
			
			OpenForm("CommonForm.CannotInstallAddIn",
				FormParameters,,,,, NotifyDescription);
			Return;
		EndIf;
	EndIf;
	
	AfterCompatibilityInfoDisplayed(Undefined, Context);
	
EndProcedure

#EndRegion

#Region Private

#Region CheckAddInAvailability

Procedure AfterCompatibilityInfoDisplayed(Result, Context) Export
	
	ExecuteNotifyProcessing(Context.Notification, Context.ErrorDescription);
	
EndProcedure

Function AddInCompatibilityErrorDetails()
	Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не предусмотрена работа внешней компоненты в клиентском приложении %1. Обратитесь к разработчику внешней компоненты';
				|en = 'Client application %1 does not support the add-in. Contact the add-in developer.';"),
			CommonInternalClient.ApplicationKind());
EndFunction

Procedure CheckAddInAvailabilityAfterSearchingAddInOnPortal(Imported1, SearchContext) Export
	
	Notification = SearchContext.Notification;
	Context   = SearchContext.Context;
	
	If Imported1 Then
		Context.SuggestToImport = False;
		CheckAddInAvailability(Notification, Context);
	Else 
		ExecuteNotifyProcessing(Notification, AddInAvailabilityResult());
	EndIf;
	
EndProcedure

Procedure CheckAddInAvailabilityAfterDisplayingAvailableClientTypes(Result, Context) Export
	
	AddInAvailabilityResult = Context.Result;
	AddInAvailabilityResult.Available = Result = True;
	ExecuteNotifyProcessing(Context.Notification, AddInAvailabilityResult);
	
EndProcedure

// Returns:
//  Structure:
//   * Available - Boolean
//   * Version - String
//   * TheComponentOfTheLatestVersion - See StandardSubsystemsServer.TheComponentOfTheLatestVersion
//   * ErrorDescription - String
//   * Location - String
//
Function AddInAvailabilityResult() Export
	
	Result = New Structure;
	Result.Insert("Available", False);
	Result.Insert("Version", "");
	Result.Insert("TheComponentOfTheLatestVersion", Undefined);
	Result.Insert("ErrorDescription", "");
	Result.Insert("Location", "");
	
	Return Result;
	
EndFunction

Procedure ReplaceWithCurrentComponentFromCatalog(Result, Id, Location, ShouldAttachAddInFromTemplate)
	
	If StringFunctionsClientServer.OnlyNumbersInString(StrReplace(Result.Version, ".", "")) Then
		VersionParts = StrSplit(Result.Version, ".");
		If VersionParts.Count() = 4 And CommonClientServer.CompareVersions(Result.Version,
			Result.TheComponentOfTheLatestVersion.Version) <= 0 Then
				ShouldAttachAddInFromTemplate = True;
			Return;
		EndIf;
	EndIf;
		
	// Use the add-in from the catalog if the add-in version is greater than the template version or it mismatches the template.
	Result.TheComponentOfTheLatestVersion = New Structure("Id, Version, Location", Id,
		Result.Version, Location);
		
EndProcedure

// The add-in supports the client.
// 
// Parameters:
//  Attributes - 
// 
// Returns:
//  Boolean - Flag indicating whether the add-in supports the client.
//
Function CurrentClientIsSupportedByAddIn(Attributes)
	
	SystemInfo = New SystemInfo;
	Browser = Undefined;
#If WebClient Then
	String = SystemInfo.UserAgentInformation;
	If StrFind(String, "YaBrowser/") > 0 Then
		Browser = "YandexBrowser";
	ElsIf StrFind(String, "Chrome/") > 0 Then
		Browser = "Chrome";
	ElsIf StrFind(String, "MSIE") > 0 Then
		Browser = "MSIE";
	ElsIf StrFind(String, "Safari/") > 0 Then
		Browser = "Safari";
	ElsIf StrFind(String, "Firefox/") > 0 Then
		Browser = "Firefox";
	EndIf;
#EndIf

	NameOfThePlatformType = CommonClientServer.NameOfThePlatformType(SystemInfo.PlatformType);
	
	If NameOfThePlatformType = "Linux_x86" Then
		
		If Browser = Undefined Then
			Return Attributes.Linux_x86;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.Linux_x86_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Linux_x86_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Linux_x86_YandexBrowser;
		EndIf;
	
	ElsIf NameOfThePlatformType = "Linux_x86_64" Then
		
		If Browser = Undefined Then
			Return Attributes.Linux_x86_64;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.Linux_x86_64_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Linux_x86_64_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Linux_x86_64_YandexBrowser;
		EndIf;
	
	ElsIf NameOfThePlatformType = "MacOS_x86_64" Then
		
		If Browser = Undefined Then
			Return Attributes.MacOS_x86_64;
		EndIf;
		
		If Browser = "Safari" Then
			Return Attributes.MacOS_x86_64_Safari;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.MacOS_x86_64_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.MacOS_x86_64_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.MacOS_x86_64_YandexBrowser;
		EndIf;
	
	ElsIf NameOfThePlatformType = "Windows_x86" Then
		
		If Browser = Undefined Then
			Return Attributes.Windows_x86;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.Windows_x86_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Windows_x86_Chrome;
		EndIf;
		
		If Browser = "MSIE" Then
			Return Attributes.Windows_x86_MSIE;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Windows_x86_YandexBrowser;
		EndIf;
		
	ElsIf NameOfThePlatformType = "Windows_x86_64" Then
		
		If Browser = Undefined Then
			Return Attributes.Windows_x86_64;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.Windows_x86_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Windows_x86_Chrome;
		EndIf;
		
		If Browser = "MSIE" Then
			Return Attributes.Windows_x86_64_MSIE;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Windows_x86_64_YandexBrowser;
		EndIf;
	
	ElsIf NameOfThePlatformType = "MacOS_x86" Then
		// Browsers may misdefine the OS.
	
		If Browser = "Firefox" Then
			Return Attributes.MacOS_x86_64_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.MacOS_x86_64_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.MacOS_x86_64_YandexBrowser;
		EndIf;
		
	ElsIf NameOfThePlatformType = "Linux_E2K" Then
		
		If Browser = Undefined Then
			Return Attributes.Linux_E2K;
		EndIf;
	
		If Browser = "Firefox" Then
			Return Attributes.Linux_E2K_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Linux_E2K_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Linux_E2K_YandexBrowser;
		EndIf;
		
	ElsIf NameOfThePlatformType = "Linux_ARM64" Then
	
		If Browser = Undefined Then
			Return Attributes.Linux_ARM64;
		EndIf;
	
		If Browser = "Firefox" Then
			Return Attributes.Linux_ARM64_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Linux_ARM64_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Linux_ARM64_YandexBrowser;
		EndIf;
		
	ElsIf NameOfThePlatformType = "iOS_ARM" Then
	
		Return Attributes.iOS_ARM;
	
	ElsIf NameOfThePlatformType = "iOS_ARM64" Then
	
		Return Attributes.iOS_ARM64;
	
	ElsIf NameOfThePlatformType = "Android_ARM" Then
	
		Return Attributes.Android_ARM;
	
	ElsIf NameOfThePlatformType = "Android_ARM_64" Then
	
		Return Attributes.Android_ARM64;
		
	ElsIf NameOfThePlatformType = "Android_x86" Then
	
		Return Attributes.Android_x86;
		
	ElsIf NameOfThePlatformType = "Android_x86_64" Then
	
		Return Attributes.Android_x86_64;
		
	ElsIf NameOfThePlatformType = "WinRT_ARM" Then
	
		Return Attributes.WindowsRT_ARM;
		
	ElsIf NameOfThePlatformType = "WinRT_x86" Then
	
		Return Attributes.WindowsRT_x86;
		
	ElsIf NameOfThePlatformType = "WinRT_x86_64" Then
	
		Return Attributes.WindowsRT_x86_64;
	
	EndIf;
	
	Return False;
	
EndFunction

Function TextCannotInstallAddIn(Val ExplanationText) Export

	If IsBlankString(ExplanationText) Then
		ExplanationText = NStr("ru = 'Установка внешней компоненты невозможна.';
								|en = 'Cannot install the add-in.';");
	EndIf;

	Return StringFunctionsClient.FormattedString(NStr("ru = '%1
			  |
			  |Не предусмотрена работа внешней компоненты 
			  |в клиентском приложении <b>%2</b>.
			  |Используйте <a href = about:blank>поддерживаемое клиентское приложение</a> или обратитесь к разработчику внешней компоненты.';
				|en = '%1
				|
				|The add-in is not supported 
				|in the client application <b>%2</b>.
				|Use <a href = about:blank>a supported client application</a> or contact the add-in developer.';"),
		ExplanationText, PresentationOfCurrentClient());
		
EndFunction

Function PresentationOfCurrentClient() 
	
	SystemInfo = New SystemInfo;
	
#If WebClient Then
	String = SystemInfo.UserAgentInformation;
	
	If StrFind(String, "YaBrowser/") > 0 Then
		Browser = NStr("ru = 'Яндекс Браузер';
						|en = 'Yandex Browser';");
	ElsIf StrFind(String, "Chrome/") > 0 Then
		Browser = NStr("ru = 'Chrome';
						|en = 'Chrome';");
	ElsIf StrFind(String, "MSIE") > 0 Then
		Browser = NStr("ru = 'Internet Explorer';
						|en = 'Internet Explorer';");
	ElsIf StrFind(String, "Safari/") > 0 Then
		Browser = NStr("ru = 'Safari';
						|en = 'Safari';");
	ElsIf StrFind(String, "Firefox/") > 0 Then
		Browser = NStr("ru = 'Firefox';
						|en = 'Firefox';");
	EndIf;
	
	Package = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'веб-клиент %1';
																				|en = 'web client %1';"), Browser);
#ElsIf MobileAppClient Then
	Package = NStr("ru = 'мобильное приложение';
						|en = 'mobile application';");
#ElsIf MobileClient Then
	Package = NStr("ru = 'мобильный клиент';
						|en = 'mobile client';");
#ElsIf ThinClient Then
	Package = NStr("ru = 'тонкий клиент';
						|en = 'thin client';");
#ElsIf ThickClientOrdinaryApplication Then
	Package = NStr("ru = 'толстый клиент (обычное приложение)';
						|en = 'thick client (standard application)';");
#ElsIf ThickClientManagedApplication Then
	Package = NStr("ru = 'толстый клиент';
						|en = 'thick client';");
#EndIf

	NameOfThePlatformType = CommonClientServer.NameOfThePlatformType(SystemInfo.PlatformType);
	If NameOfThePlatformType = "Windows_x86" Then
		Platform = NStr("ru = 'Windows x86';
						|en = 'Windows x86';");
	ElsIf NameOfThePlatformType = "Windows_x86_64" Then
		Platform = NStr("ru = 'Windows x86-64';
						|en = 'Windows x86-64';");
	ElsIf NameOfThePlatformType = "Linux_x86" Then
		Platform = NStr("ru = 'Linux x86';
						|en = 'Linux x86';");
	ElsIf NameOfThePlatformType = "Linux_x86_64" Then
		Platform = NStr("ru = 'Linux x86-64';
						|en = 'Linux x86-64';");
	ElsIf NameOfThePlatformType = "MacOS_x86" Then
		Platform = NStr("ru = 'macOS x86';
						|en = 'macOS x86';");
	ElsIf NameOfThePlatformType = "MacOS_x86_64" Then
		Platform = NStr("ru = 'macOS x86-64';
						|en = 'macOS x86-64';");
	ElsIf NameOfThePlatformType = "Linux_ARM64" Then
		Platform = NStr("ru = 'Linux ARM64';
						|en = 'Linux ARM64';");
	ElsIf NameOfThePlatformType = "Linux_E2K" Then
		Platform = NStr("ru = 'Linux E2K';
						|en = 'Linux E2K';");
	ElsIf NameOfThePlatformType = "Android_ARM" Then
		Platform = NStr("ru = 'Android ARM';
						|en = 'Android ARM';");
	ElsIf NameOfThePlatformType = "Android_ARM_64" Then
		Platform = NStr("ru = 'Android_ARM64';
						|en = 'Android_ARM64';");
	ElsIf NameOfThePlatformType = "Android_x86" Then
		Platform = NStr("ru = 'Android x86';
						|en = 'Android x86';");
	ElsIf NameOfThePlatformType = "Android_x86_64" Then
		Platform = NStr("ru = 'Android x86-64';
						|en = 'Android x86-64';");
	ElsIf NameOfThePlatformType = "iOS_ARM" Then
		Platform = NStr("ru = 'iOS ARM';
						|en = 'iOS ARM';");
	ElsIf NameOfThePlatformType = "iOS_ARM_64" Then
		Platform = NStr("ru = 'iOS ARM64';
						|en = 'iOS ARM64';");
	ElsIf NameOfThePlatformType = "WinRT_ARM" Then
		Platform = NStr("ru = 'WinRT ARM';
						|en = 'WinRT ARM';");
	ElsIf NameOfThePlatformType = "WinRT_x86" Then
		Platform = NStr("ru = 'WinRT x86';
						|en = 'WinRT x86';");
	ElsIf NameOfThePlatformType = "WinRT_x86_64" Then
		Platform = NStr("ru = 'WinRT x86-64';
						|en = 'WinRT x86-64';");
	EndIf;
	
	// Example:
	// Firefox Windows x86 web client
	// Windows x86-64 thin client
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 %2';
																		|en = '%1 %2';"), Package, Platform);
	
EndFunction

#EndRegion

#Region AttachAddInSSL

// Parameters:
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Async Function AttachAddInSSLAsync(Context) Export 
	
	Result = Await AddInAvailabilityCheckResult(Context);
	
	If Result.Available Then 
		Return Await CommonInternalClient.AttachAddInSSLAsync(Context);
	Else
		If Not IsBlankString(Result.ErrorDescription) Then 
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
				           |из хранилища внешних компонент
				           |по причине:
				           |%2';
							|en = 'Cannot attach the ""%1"" add-in
							|on the client from the add-in storage.
							|Reason:
							|%2';"),
				Context.Id,
				Result.ErrorDescription);
		EndIf;
		
		Return CommonInternalClient.AddInAttachmentError(ErrorText);
		
	EndIf;
	
EndFunction

Procedure AttachAddInSSL(Context) Export 
	
	Notification = New NotifyDescription(
		"AttachAddInAfterAvailabilityCheck", 
		ThisObject, 
		Context);
	
	CheckAddInAvailability(Notification, Context);
	
EndProcedure

// Parameters:
//  Result - Structure - add-in attachment result:
//    * Attached - Boolean - attachment flag.
//    * Attachable_Module - AddInObject - an instance of the add-in.
//    * ErrorDescription - String - brief error message. Empty string on cancel by user
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Procedure AttachAddInAfterAvailabilityCheck(Result, Context) Export
	
	If Result.Available Then 
		CommonInternalClient.AttachAddInSSL(Context);
	Else
		If Not IsBlankString(Result.ErrorDescription) Then 
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
				           |из хранилища внешних компонент
				           |по причине:
				           |%2';
							|en = 'Cannot attach the ""%1"" add-in
							|on the client from the add-in storage.
							|Reason:
							|%2';"),
				Context.Id,
				Result.ErrorDescription);
		EndIf;
		
		CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
	EndIf;
	
EndProcedure

#EndRegion

#Region AttachAddInFromWindowsRegistry

// Returns:
//  Structure:
//   * Notification - NotifyDescription
//   * Id - String
//   * ObjectCreationID - String
//
Function ConnectionContextComponentsFromTheWindowsRegistry() Export
	
	Context = New Structure;
	Context.Insert("Notification", Undefined);
	Context.Insert("Id", "");
	Context.Insert("ObjectCreationID", "");
	Return Context;
		
EndFunction

// Intended to be called from AddInClient.AttachAddInFromWindowsRegisterAsync.
// 
// Parameters:
//  Context - See ConnectionContextComponentsFromTheWindowsRegistry.
//
Async Function AttachAddInFromWindowsRegistryAsync(Context) Export
	
	If AttachAddInFromWindowsRegistryAttachmentAvailable() Then
		
		Try
			
			Attached = Await AttachAddInAsync("AddIn." + Context.Id);
			
		Except
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
					 |из реестра Windows
					 |по причине:
					 |%2';
					|en = 'Cannot attach the ""%1"" add-in on the client
					|from Windows registry.
					|Reason:
					|%2';"), Context.Id, ErrorProcessing.BriefErrorDescription(ErrorInfo()));

			Return CommonInternalClient.AddInAttachmentError(ErrorText);
		EndTry;
		
		If Attached Then

			ObjectCreationID = Context.ObjectCreationID;

			If ObjectCreationID = Undefined Then
				ObjectCreationID = Context.Id;
			EndIf;

			Try
				Attachable_Module = New ("AddIn." + ObjectCreationID);
				If Attachable_Module = Undefined Then
					Raise NStr("ru = 'Оператор Новый вернул Неопределено';
											|en = 'The New operator returned Undefined.';");
				EndIf;
			Except
				Attachable_Module = Undefined;
				ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			EndTry;

			If Attachable_Module = Undefined Then

				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось создать объект внешней компоненты ""%1"", подключенной на клиенте
					 |из реестра Windows,
					 |по причине:
					 |%2';
					|en = 'Cannot create object of the ""%1"" add-in attached on the client
					|from Windows registry.
					|Reason:
					|%2';"), Context.Id, ErrorText);

				Return CommonInternalClient.AddInAttachmentError(ErrorText);

			Else
				
				Result = CommonInternalClient.AddInAttachmentResult();
				Result.Attached = True;
				Result.Attachable_Module = Attachable_Module;
				Return Result;
				
			EndIf;

		Else

			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
				 |из реестра Windows
				 |по причине:
				 |Метод %2 вернул %3.';
				|en = 'Couldn''t attach add-in ""%1"" on the client
				|from Windows registry.
				|Reason:
				|Method ""%2"" returned ""%3"".';"), Context.Id, "AttachAddInAsync", "False");

			Return CommonInternalClient.AddInAttachmentError(ErrorText);

		EndIf;
		
	Else 
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
			           |из реестра Windows
			           |по причине:
			           |Подключить компоненту из реестра Windows возможно только в тонком или толстом клиентах Windows.';
						|en = 'Cannot attach the ""%1"" add-in
						|on the client from Windows registry.
						|Reason:
						|Attaching add-ins from Windows is allowed only in the thin and thick clients.';"),
			Context.Id);
		
		Return CommonInternalClient.AddInAttachmentError(ErrorText);
		
	EndIf;
	
EndFunction

// For calls from See AddInsClient.AttachAddInFromWindowsRegistry.
// 
// Parameters:
//  Context - See ConnectionContextComponentsFromTheWindowsRegistry.
//
Procedure AttachAddInFromWindowsRegistry(Context) Export
	
	If AttachAddInFromWindowsRegistryAttachmentAvailable() Then
		
		Notification = New NotifyDescription(
		"AttachAddInFromWindowsRegistryAfterAttachmentAttempt", ThisObject, Context,
		"AttachAddInFromWIndowsRegisterOnProcessError", ThisObject);
		
		BeginAttachingAddIn(Notification, "AddIn." + Context.Id);
		
	Else 
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
			           |из реестра Windows
			           |по причине:
			           |Подключить компоненту из реестра Windows возможно только в тонком или толстом клиентах Windows.';
						|en = 'Cannot attach the ""%1"" add-in
						|on the client from Windows registry.
						|Reason:
						|Attaching add-ins from Windows is allowed only in the thin and thick clients.';"),
		Context.Id);
		
		CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
		
	EndIf;
	
EndProcedure

// Continues the AttachAddInFromWindowsRegistry procedure.
//
// Parameters:
//  Attached - Boolean
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Procedure AttachAddInFromWindowsRegistryAfterAttachmentAttempt(Attached, Context) Export
	
	If Attached Then 
		
		ObjectCreationID = Context.ObjectCreationID;
			
		If ObjectCreationID = Undefined Then 
			ObjectCreationID = Context.Id;
		EndIf;
		
		Try
			Attachable_Module = New("AddIn." + ObjectCreationID);
			If Attachable_Module = Undefined Then 
				Raise NStr("ru = 'Оператор Новый вернул Неопределено';
										|en = 'The New operator returned Undefined';");
			EndIf;
		Except
			Attachable_Module = Undefined;
			ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
		
		If Attachable_Module = Undefined Then 
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось создать объект внешней компоненты ""%1"", подключенной на клиенте
				           |из реестра Windows,
				           |по причине:
				           |%2';
							|en = 'Cannot create object of the ""%1"" add-in attached on the client
							|from Windows registry.
							|Reason:
							|%2';"),
				Context.Id,
				ErrorText);
				
			CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
			
		Else 
			CommonInternalClient.AttachAddInSSLNotifyOnAttachment(Attachable_Module, Context);
		EndIf;
		
	Else 
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
			           |из реестра Windows
			           |по причине:
			           |Метод %2 вернул %3.';
						|en = 'Couldn''t attach add-in ""%1"" on the client
						|from Windows registry.
						|Reason:
						|Method ""%2"" returned ""%3"".';"),
			Context.Id, "BeginAttachingAddIn", "False");
			
		CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
		
	EndIf;
	
EndProcedure

// Continues the AttachAddInFromWindowsRegistry procedure.
//
// Parameters:
//  ErrorInfo - ErrorInfo
//  StandardProcessing - Boolean
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Procedure AttachAddInFromWIndowsRegisterOnProcessError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
		           |из реестра Windows
		           |по причине:
		           |%2';
					|en = 'Cannot attach the ""%1"" add-in on the client
					|from Windows registry.
					|Reason:
					|%2';"),
		Context.Id,
		ErrorProcessing.BriefErrorDescription(ErrorInfo));
		
	CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
	
EndProcedure

// Continues the AttachAddInFromWindowsRegistry procedure.
Function AttachAddInFromWindowsRegistryAttachmentAvailable()
	
#If WebClient Then
	Return False;
#Else
	Return CommonClient.IsWindowsClient();
#EndIf
	
EndFunction

#EndRegion

#Region InstallAddInSSL

// Parameters:
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Async Function InstallAddInSSLAsync(Context) Export
	
	CheckResult = Await AddInAvailabilityCheckResult(Context);
	
	If CheckResult.Available Then 
		Return Await CommonInternalClient.InstallAddInSSLAsync(Context);
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
			           |из хранилища внешних компонент
			           |по причине:
			           |%2';
						|en = 'Cannot attach the ""%1"" add-in
						|on the client from the add-in storage.
						|Reason:
						|%2';"),
			Context.Id,
			CheckResult.ErrorDescription);
			
		Return CommonInternalClient.AddInInstallationError(ErrorText);
	EndIf;
	
EndFunction

Procedure InstallAddInSSL(Context) Export
	
	Notification = New NotifyDescription(
		"InstallAddInAfterAvailabilityCheck", 
		ThisObject, 
		Context);
	
	CheckAddInAvailability(Notification, Context);
	
EndProcedure

// Parameters:
//  Result - Structure - add-in attachment result:
//    * Attached - Boolean - attachment flag.
//    * Attachable_Module - AddInObject - an instance of the add-in.
//    * ErrorDescription - String - brief error message. Empty string on cancel by user.
//  Context - See CommonInternalClient.AddInAttachmentContext 
//
Procedure InstallAddInAfterAvailabilityCheck(Result, Context) Export
	
	If Result.Available Then 
		CommonInternalClient.InstallAddInSSL(Context);
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
			           |из хранилища внешних компонент
			           |по причине:
			           |%2';
						|en = 'Cannot attach the ""%1"" add-in
						|on the client from the add-in storage.
						|Reason:
						|%2';"),
			Context.Id,
			Result.ErrorDescription);
			
		CommonInternalClient.InstallAddInSSLNotifyOnError(ErrorText, Context);
	EndIf;
	
EndProcedure

#EndRegion

#Region ImportAddInFromFile

// Returns:
//  Structure:
//   * Notification - NotifyDescription
//   * Id - String
//   * Version - String
//   * AdditionalInformationSearchParameters - Map
//
Function ContextForLoadingComponentsFromAFile() Export
	
	Context = New Structure;
	Context.Insert("Notification", Undefined);
	Context.Insert("Id", "");
	Context.Insert("Version", "");
	Context.Insert("AdditionalInformationSearchParameters", New Map);
	Return Context;
	
EndFunction
	
// To be called from AddInClient.ImportAddInFromFile.
// 
// Parameters:
//  Context - See ContextForLoadingComponentsFromAFile.
//
Procedure ImportAddInFromFile(Context) Export 
	
	Information = AddInsInternalServerCall.SavedAddInInformation(Context.Id, Context.Version);
	
	If Information.ImportFromFileIsAvailable Then
		
		AdditionalInformationSearchParameters = Context.AdditionalInformationSearchParameters;
		
		FormParameters = New Structure;
		FormParameters.Insert("ShowImportFromFileDialogOnOpen", True);
		FormParameters.Insert("ReturnImportResultFromFile", True);
		FormParameters.Insert("AdditionalInformationSearchParameters", AdditionalInformationSearchParameters);
		
		If Information.State = "FoundInStorage"
			Or Information.State = "DisabledByAdministrator" Then
			
			FormParameters.Insert("ShowImportFromFileDialogOnOpen", False);
			FormParameters.Insert("Key", Information.Ref);
		EndIf;
		
		Notification = New NotifyDescription("ImportAddInFromFileAfterImport", ThisObject, Context);
		OpenForm("Catalog.AddIns.ObjectForm", FormParameters,,,,, Notification);
		
	Else 
		
		Notification = New NotifyDescription("ImportAddInFromFileAfterAvailabilityWarnings", ThisObject, Context);
		ShowMessageBox(Notification, 
			NStr("ru = 'Загрузка внешней компоненты прервана
			           |по причине:
			           |Требуются права администратора';
						|en = 'Add-in import is canceled
						|due to:
						|You must have administrative rights';"));
		
	EndIf;
	
EndProcedure

// Continues the ImportAddInFromFile procedure.
Procedure ImportAddInFromFileAfterAvailabilityWarnings(Context) Export
	
	Result = AddInImportResult();
	Result.Imported1 = False;
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// Continues the ImportAddInFromFile procedure.
Procedure ImportAddInFromFileAfterImport(Result, Context) Export
	
	// Result: 
	// - Structure - Add-in attached.
	// - Undefined - Close the dialog. 
	
	UserClosedDialogBox = (Result = Undefined);
	
	Notification = Context.Notification;
	
	If UserClosedDialogBox Then 
		Result = AddInImportResult();
		Result.Imported1 = False;
	EndIf;
	
	ExecuteNotifyProcessing(Notification, Result);
	
EndProcedure

// Continues the ImportAddInFromFile procedure.
Function AddInImportResult() Export
	
	Result = New Structure;
	Result.Insert("Imported1", False);
	Result.Insert("Id", "");
	Result.Insert("Version", "");
	Result.Insert("Description", "");
	Result.Insert("AdditionalInformation", New Map);
	
	Return Result;
	
EndFunction

#EndRegion

#Region ComponentSearchOnPortal

Procedure AddInSearchOnPortalOnGenerateResult(Result, Notification) Export
	
	Imported1 = (Result = True); // When the form is closed, it is set to "Undefined".
	ExecuteNotifyProcessing(Notification, Imported1);
	
EndProcedure

#EndRegion

#Region UpdateAddInsFromPortal

// Parameters:
//  Notification - NotifyDescription
//  AddInsToUpdate - Array of CatalogRef.AddIns
//
Procedure UpdateAddInsFromPortal(Notification, AddInsToUpdate) Export
	
	NotificationForms = New NotifyDescription("UpdateAddInFromPortalOnGenerateResult", ThisObject, Notification);
	AddInsClientLocalization.UpdateAddInsFromPortal(NotificationForms, AddInsToUpdate);
	
EndProcedure

Procedure UpdateAddInFromPortalOnGenerateResult(Result, Notification) Export
	
	ExecuteNotifyProcessing(Notification, Undefined);
	
EndProcedure

#EndRegion

#Region SaveAddInToFile

// Parameters:
//  AddInRef - CatalogRef.AddIns
//                          - Array of CatalogRef.AddIns
//
Procedure SaveAddInToFile(AddInRef) Export
	
	If TypeOf(AddInRef) = Type("Array") Then
		References = AddInRef;
	Else
		References = CommonClientServer.ValueInArray(AddInRef);
	EndIf;
	FilesDetails = AddInsInternalServerCall.AddInsFilesDetails(References);

	If References.Count() = 1 Then
		
		SavingParameters = FileSystemClient.FileSavingParameters();
		SavingParameters.Dialog.Title = NStr("ru = 'Выберите файл для сохранения внешней компоненты';
													|en = 'Select a file to save the add-in to';");
		SavingParameters.Dialog.Filter    = NStr("ru = 'Файлы внешних компонент (*.zip)|*.zip';
													|en = 'Add-in files (*.zip)|*.zip';")+"|"
			+ StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Все файлы (%1)|%1';
																			|en = 'All files (%1)|%1';"), GetAllFilesMask());
		
		Notification = New NotifyDescription("SaveAddInToFileAfterReceivingFiles", ThisObject);
		FileSystemClient.SaveFile(Notification, FilesDetails[0].Location, FilesDetails[0].Name, SavingParameters);
		
		Return;
	EndIf;
	
	Notification = New NotifyDescription("SaveAddInsToFileAfterDirectorySelected", ThisObject, FilesDetails);
	FileSystemClient.SelectDirectory(Notification, NStr("ru = 'Выберите каталог для сохранения внешних компонент';
															|en = 'Select a directory to save the add-ins';"));
	
EndProcedure

// Continuation of the SaveAddInToFile procedure.
Procedure SaveAddInsToFileAfterDirectorySelected(Directory, FilesDetails) Export
	
	If IsBlankString(Directory) Then
		Return;
	EndIf;
	
	FilesToSave = New Array;
	For Each FileDetails In FilesDetails Do
		FilesToSave.Add(New TransferableFileDescription(FileDetails.Name, FileDetails.Location));
	EndDo;
	
	SavingParameters = FileSystemClient.FilesSavingParameters();
	SavingParameters.Interactively = False;
	SavingParameters.Dialog.Directory = Directory;
	FileSystemClient.SaveFiles(New NotifyDescription(
		"SaveAddInToFileAfterReceivingFiles", ThisObject), 
		FilesToSave, SavingParameters);

EndProcedure

// Continuation of the SaveAddInToFile procedure.
Procedure SaveAddInToFileAfterReceivingFiles(ObtainedFiles, Context) Export
	
	If ObtainedFiles <> Undefined 
		And ObtainedFiles.Count() > 0 Then
		
		MessageText = ?(ObtainedFiles.Count() = 1, 
			NStr("ru = 'Внешняя компонента успешно сохранена в файл.';
				|en = 'The add-in is saved to the file.';"),
			NStr("ru = 'Внешние компоненты успешно сохранены в файлы.';
				|en = 'The add-ins are saved to the files.';"));
		
		ShowUserNotification(NStr("ru = 'Сохранение в файл';
											|en = 'Save to file';"),,
			MessageText, PictureLib.Success32);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

