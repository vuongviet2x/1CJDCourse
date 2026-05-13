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
// CommonModule.OnlineUserSupportInternalCached.
//
// Server memoization procedures and functions:
//  - Get app settings
//  - Cache the availability of services
//  - General procedures and functions
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns a base64-string: infobase configuration ID.
//
Function ConfigurationID() Export
	
	If OnlineUserSupport.OperationWithLicensingClientSettingsAvailable() Then
		Return LicensingClient.ConfigurationID();
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Returns the current settings of connection to online support servers.
//
Function OUSServersConnectionSettings() Export
	
	Result = New Structure;
	SetPrivilegedMode(True);
	Result.Insert("OUSServersDomain"     , OnlineUserSupport.OUSServersDomain());
	Result.Insert("EstablishConnectionAtServer", True);
	Result.Insert("ConnectionTimeout"               , 30);
	
	Return Result;
	
EndFunction

// Caches the Common.DefaultLanguageCode() call.
// Returns the code of the default configuration language, for example, "en".
//
// Returns:
//  String - language code.
//
Function DefaultLanguageCode() Export

	Return Common.DefaultLanguageCode();

EndFunction

#EndRegion

#Region Private

// See OnlineUserSupport.InternalCheckURLAvailable.
//
Function CheckURLAvailable(URL, Method, ErrorName, ErrorMessage, ErrorInfo) Export
	
	OnlineUserSupport.InternalCheckURLAvailable(
		URL,
		Method,
		ErrorName,
		ErrorMessage,
		ErrorInfo);
	
	If Not IsBlankString(ErrorName) Then
		Raise ErrorName;
	EndIf;
	
	Return "";
	
EndFunction

// Returns a flag indicating if there are any common separators in the configuration.
//
// Returns:
//   Boolean - True if the configuration is separated.
//
Function IsSeparatedConfiguration() Export
	
	If Common.SubsystemExists("OnlineUserSupport.SaaSOperations") Then
		ModuleOSLSaaS = Common.CommonModule("SaaSOSL");
		HasSeparators = ModuleOSLSaaS.IsSeparatedConfiguration();
	Else
		HasSeparators = False;
	EndIf;
	
	Return HasSeparators;
	
EndFunction

// Determines if the session was started without separators.
//
// Returns:
//   Boolean - If True, the session is started without separators.
//
Function SessionWithoutSeparators() Export
	
	If Common.SubsystemExists("OnlineUserSupport.SaaSOperations") Then
		ModuleOSLSaaS = Common.CommonModule("SaaSOSL");
		SessionWithoutSeparators = ModuleOSLSaaS.SessionWithoutSeparators();
	Else
		SessionWithoutSeparators = True;
	EndIf;
	
	Return SessionWithoutSeparators;
	
EndFunction

#EndRegion