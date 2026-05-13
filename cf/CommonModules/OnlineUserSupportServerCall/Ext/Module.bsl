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
// CommonModule.OnlineUserSupportSaaSCached.
//
// Server procedures and functions:
//  - Determine connection availability
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Determines whether the current user can connect to
// online support: user authorization and registration and registration
// of software in accordance with the current operation mode
// and user rights.
//
// Returns:
//  Boolean - True - Online support connection is available,
//           otherwise, False.
//
Function CanConnectOnlineUserSupport() Export
	
	Return OnlineUserSupport.CanConnectOnlineUserSupport();
	
EndFunction

#EndRegion

#Region Internal

#Region ApplicationSettings

// Process the online support deactivation event.
//
Procedure ExitOUS() Export
	
	// Checking the right to write data
	If Not OnlineUserSupport.RightToWriteOUSParameters() Then
		Raise NStr("ru = 'Недостаточно прав для записи данных аутентификации Интернет-поддержки.';
								|en = 'Insufficient rights to save authentication credentials for online support.';");
	EndIf;
	
	// Write data.
	SetPrivilegedMode(True);
	OnlineUserSupport.ServiceSaveAuthenticationData(Undefined);
	
EndProcedure

#EndRegion

#Region Tariffication

// See OnlineUserSupport.ServiceActivated.
//
Function ServiceActivated(Val ServiceID, Val SeparatorValue = Undefined) Export
	
	Return OnlineUserSupport.ServiceActivated(ServiceID, SeparatorValue);
	
EndFunction

#EndRegion

#Region ApplicationSettings

// Returns the value of the SendEmailsInHTMLFormat functional option
//
// Returns:
//  Boolean - The usage flag of the SendEmailsInHTMLFormat functional option.
//
Function SendEmailsInHTMLFormat() Export
	
	Return OnlineUserSupport.SendEmailsInHTMLFormat();
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region OtherPrivate

// See OnlineUserSupport.InternalURLToNavigateToIntegratedWebsitePage.
//
Function InternalURLToNavigateToIntegratedWebsitePage(Val WebsitePageURL) Export
	
	Return OnlineUserSupport.InternalURLToNavigateToIntegratedWebsitePage(WebsitePageURL);
	
EndFunction

// See OnlineUserSupportClientServer.FormattedStringFromHTML
//
Function FormattedStringFromHTML(Val MessageText) Export
	
	Return OnlineUserSupportClientServer.FormattedStringFromHTML(
		MessageText);
	
EndFunction

#EndRegion

#EndRegion
