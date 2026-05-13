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
// CommonModule.OnlineUserSupportClientServer.
//
// Client/server procedures and functions:
//  - Determine library settings
//  - General checks of authentication data
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns a library version number.
//
// Returns:
//  String - a library version number.
//
Function LibraryVersion() Export
	
	Return "2.7.3.21";
	
EndFunction

// Returns "1C:ITS Portal" service supplier ID
// for integration with the "Tariff management in SaaS" subsystem
// of the Service technology library.
//
// Returns:
//	String - a service provider ID.
//
Function ServiceProviderID1sitsPortal() Export
	
	Return "Portal1CITS";
	
EndFunction

// Checks authentication data of an online support user.
// Call before checking a username and a password in the service
// and saving data in the infobase.
//
// Parameters:
//  AuthenticationData - Structure - Structure containing a username and a password
//                         of an online support user:
//   * Login - String - Username of an online support user.
//   * Password - String - Password of an online support user.
//
// Returns:
//  Structure - Authentication data check results:
//   *Cancel - Boolean - if True, errors occurred during the check;
//   *ErrorMessage - String - a message for an application user;
//   *Field - String - an ID of the field where an error occurred:
//                      - "Логин" - an error occurred when checking data in the Username field;
//                      - "Пароль" - an error occurred when checking data in the Password field;
//
Function VerifyAuthenticationData(AuthenticationData) Export
	
	Result = New Structure;
	Result.Insert("Cancel", False);
	Result.Insert("ErrorMessage", "");
	Result.Insert("Field", "");
	
	If IsBlankString(AuthenticationData.Login) Then
		Result.Cancel = True;
		Result.ErrorMessage = NStr("ru = 'Поле ""Логин"" не заполнено.';
											|en = 'Username is not filled in.';");
		Result.Field = "Login";
	ElsIf IsBlankString(AuthenticationData.Password) Then
		Result.Cancel = True;
		Result.ErrorMessage = NStr("ru = 'Поле ""Пароль"" не заполнено.';
											|en = 'Password is not filled in.';");
		Result.Field = "Password";
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Internal

#Region Common

// Adds an OUS server domain to a text according to the current server connection settings.
//
// Parameters:
//  Text - String
//  DomainZone - Undefined - The domain cannot be changed.
//               - Number - The numeric code of the domain zone. Valid values:
//                   "1" for the European domain.
//
// Returns:
//  String
//
Function SubstituteDomain(Text, Val DomainZone = Undefined) Export

	If DomainZone = 1 Then
		Result = StrReplace(Text, "webits-info@1c.eu", "webits-info@1c.ua");
		Return StrReplace(Result, ".1c.ru", ".1c.eu");
	Else
		Return Text;
	EndIf;

EndFunction

// Returns a file size string presentation.
//
Function FileSizePresentation(Val Size) Export

	If Size < 1024 Then
		Return Format(Size, "NFD=1") + " " + NStr("ru = 'байт';
													|en = 'bytes';");
	ElsIf Size < 1024 * 1024 Then
		Return Format(Size / 1024, "NFD=1") + " " + NStr("ru = 'КБ';
															|en = 'KB';");
	ElsIf Size < 1024 * 1024 * 1024 Then
		Return Format(Size / (1024 * 1024), "NFD=1") + " " + NStr("ru = 'МБ';
																	|en = 'MB';");
	Else
		Return Format(Size / (1024 * 1024 * 1024), "NFD=1") + " " + NStr("ru = 'ГБ';
																			|en = 'GB';");
	EndIf;

EndFunction

// Converts the passed string:
// to a formatted string if the string starts with "<body>" and ends with "</body>";
// otherwise, the string remains without changes.
//
// Parameters:
//  MessageText - String - Source string.
//
// Returns:
//  String
//
Function FormattedHeader(MessageText) Export

	If Left(MessageText, 6) <> "<body>" Then
		Return MessageText;
	Else
		#If WebClient Then
		Return OnlineUserSupportServerCall.FormattedStringFromHTML(MessageText);
		#Else
		Return FormattedStringFromHTML(MessageText);
		#EndIf
	EndIf;

EndFunction

// Defines a URL to call a authentication service.
//
// Parameters:
//  Operation - String - a resource path.
//  ConnectionSetup - Structure, Undefined - connection settings.
//
// Returns:
//  String - an operation URL.
//
Function LoginServicePageURL(Path = "", Val ConnectionSetup = Undefined) Export
	
	If ConnectionSetup = Undefined Then
		Domain = 0;
	Else
		Domain = ConnectionSetup.OUSServersDomain;
	EndIf;
	Return "https://"
		+ LoginServiceHost(Domain)
		+ Path;
	
EndFunction

// Defines a URL to navigate to a 1C:ITS Portal page.
//
// Parameters:
//  Operation  - String - a resource path.
//  Domain     - Number, Undefined  - Domain ID.
//
// Returns:
//  String - an operation URL.
//
Function SupportPortalPageURL(Path = "", Val Domain = Undefined) Export
	
	If Domain = Undefined Then
		Domain = 0;
	EndIf;
	Return "https://"
		+ SupportPortalHost(Domain)
		+ Path;
	
EndFunction

// Generates a user presentation of the schedule.
//
// Parameters:
//  Schedule - Structure of See CommonClientServer.StructureToSchedule
//             - JobSchedule
//
// Returns:
//  String - a schedule presentation.
//
Function SchedulePresentation(Schedule) Export

	If Schedule = Undefined Then
		Return NStr("ru = 'Настроить расписание';
					|en = 'Set schedule';");
	Else
		If TypeOf(Schedule) = Type("Structure") Then
			Return String(CommonClientServer.StructureToSchedule(Schedule));
		Else
			Return String(Schedule);
		EndIf;
	EndIf;

EndFunction

// Converts the passed string:
// to a formatted string if the string starts with "<body>" and ends with "</body>";
// otherwise, the string remains without changes.
//
// Parameters:
//  MessageText - String - the source string.
//
// Returns:
//  String - a conversion result.
//
Function FormattedStringFromHTML(MessageText) Export
	
	Document = New FormattedDocument;
	Document.SetHTML("<html>" + MessageText + "</html>", New Structure);
	Return Document.GetFormattedString();
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Defines a host of 1C:ITS Portal.
//
// Parameters:
//  Domain - Number  - Domain ID.
//
// Returns:
//  String - a connection host.
//
Function SupportPortalHost(Domain)


	If Domain = 0 Then
		Return "portal.1c.eu";
	Else
		Return "portal.1c.eu";
	EndIf;

EndFunction

// Defines a host of the authentication service.
//
// Parameters:
//  Domain - Number  - Domain ID.
//
// Returns:
//  String - a connection host.
//
Function LoginServiceHost(Domain) Export


	If Domain = 0 Then
		Return "login.1c.ru";
	Else
		Return "login.1c.eu";
	EndIf;

EndFunction

#EndRegion
