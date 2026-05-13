///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The Online Support subsystem.
// CommonModule.OnlineUserSupportOverridable.
//
// Server overridable procedures:
//  - Determine library settings
//  - Handle library events
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Common

// The procedure fills in a code of the configuration interface language (Metadata.Languages)
// that is passed to online support services.
// Language code is filled in ISO-639-1 format.
// If codes of the configuration interface language are defined in ISO-639-1 format,
// the method body is not required.
//
// Parameters:
//	LanguageCode - String - a language code specified in
//		Metadata.Languages is passed in the parameter.
//	LanguageCodeInISO6391Format - String - in the parameter, the language code is returned
//		in ISO-639-1 format.
//
// Example:
//	If LanguageCode = "rus" Then
//		LanguageCodeInISO639_1Format = "ru";
//	ElsIf LanguageCode = "english" Then
//		LanguageCodeInISO639_1Format = "en";
//	EndIf;
//
//@skip-warning
Procedure OnDefineConfigurationInterfaceLanguageCode(LanguageCode, LanguageCodeInISO6391Format) Export
	
	
	
EndProcedure

// In the procedure, specify the application version number that is passed
//  to online support services. If not specified,
// it is retrieved from the configuration metadata properties.
//
// Parameters:
//  ApplicationVersion - String - an application version number.
//
// Example:
//	VersionAddIns = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ApplicationVersion, "/");
//	If ApplicationVersion.Count() > 0 Then
//		ApplicationVersion = VersionAddIns[0];
//	EndIf;
//
//@skip-warning
Procedure WhenDeterminingTheVersionNumberOfTheProgram(ApplicationVersion) Export
	
	
	
EndProcedure

#EndRegion

#Region LibEventsProcessing

// Implements processing of saving events of authentication
// credentials of an online support user in the infobase (a username and a password
// for connection to the online support services).
//
// Parameters:
//  UserData - Structure, Undefined - If "Undefined", the authentication data was deleted.
//                       The structure has the following fields:
//    * Username - String - A username.
//    If "Undefined", the authentication data was deleted.
//
//The structure has the following fields:
//    * Username - String - A username.
Procedure OnChangeOnlineSupportAuthenticationData(UserData) Export
	
	
	
EndProcedure

#EndRegion

#EndRegion
