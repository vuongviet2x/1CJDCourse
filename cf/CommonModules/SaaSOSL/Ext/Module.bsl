///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2021, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "OnlineUserSupport.SaaSOperations.CoreISL" subsystem.
// CommonModule.SaaSOSL.
//
// Server procedures and functions for calling CTL:
//  - Call the core functionality
//    
//
///////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Returns the internal Service Manager URL.
//
// Returns:
//  String - Internal Service Manager URL.
//
Function InternalServiceManagerURL() Export
	
	CheckCallPossibility();
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	Return ModuleSaaSOperations.InternalServiceManagerURL();
	
EndFunction

// Returns the username of the Service Manager utility user.
//
// Returns:
//  String - Username of the Service Manager utility user.
//
Function ServiceManagerInternalUserName() Export
	
	CheckCallPossibility();
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	Return ModuleSaaSOperations.ServiceManagerInternalUserName();
	
EndFunction

// Returns the password of the Service Manager utility user.
//
// Returns:
//  String - Password of the Service Manager utility user.
//
Function ServiceManagerInternalUserPassword() Export
	
	CheckCallPossibility();
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	Return ModuleSaaSOperations.ServiceManagerInternalUserPassword();
	
EndFunction

// Returns a value of the current data area separator.
// An error occurs if the value is not set.
// 
// Returns: 
// Separator value type.
// Value of the current data area separator. 
// 
Function SessionSeparatorValue() Export
	
	If Not Common.DataSeparationEnabled() Then
		Return 0;
	EndIf;
	
	CheckCallPossibility();
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	Return ModuleSaaSOperations.SessionSeparatorValue();
	
EndFunction

// Sets session separation.
//
// Parameters:
// Use - Boolean - Flag that shows whether the DataArea separator is used in the session.
// DataArea - Number - DataArea separator value.
//
Procedure SetSessionSeparation(Use = Undefined, DataArea = Undefined) Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	CheckCallPossibility();
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleSaaSOperations.SetSessionSeparation(Use, DataArea);
	
EndProcedure

// Determines if the session was started without separators.
//
// Returns:
//   Boolean - If True, the session is started without separators.
//
Function SessionWithoutSeparators() Export
	
	If CanCallCTLFunctionality() Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		SessionWithoutSeparators = ModuleSaaSOperations.SessionWithoutSeparators();
	Else
		SessionWithoutSeparators = True;
	EndIf;
	
	Return SessionWithoutSeparators;
	
EndFunction

// Returns a flag indicating if there are any common separators in the configuration.
//
// Returns:
//   Boolean - True if the configuration is separated.
//
Function IsSeparatedConfiguration() Export
	
	If CanCallCTLFunctionality() Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		HasSeparators = ModuleSaaSOperations.IsSeparatedConfiguration();
	Else
		HasSeparators = False;
	EndIf;
	
	Return HasSeparators;
	
EndFunction

#EndRegion

#Region Private

// Checks if it is possible to call application interface
// of the SaaS technology core. If the following subsystems
// are not built in the configuration:
//  - SaaSTechnology.Core
//  - StandardSubsystems.SaaS.CoreSaaS
// an exception will be raised.
//
Procedure CheckCallPossibility()
	
	Subsystems = New Array;
	If Not Common.SubsystemExists("CloudTechnology.Core") Then
		Subsystems.Add(NStr("ru = 'ТехнологияСервиса.БазоваяФункциональность';
								|en = 'CloudTechnology.Core';"));
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		Subsystems.Add(NStr("ru = 'СтандартныеПодсистемы.РаботаВМоделиСервиса.БазоваяФункциональностьВМоделиСервиса';
								|en = 'StandardSubsystems.SaaSOperations.CoreSaaS';"));
	EndIf;
	
	If Subsystems.Count() = 0 Then
		Return;
	EndIf;
	
	ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Для работы Интернет-поддержки пользователей в модели сервиса необходимо встроить
			|%1:';
			|en = 'To use online support in SaaS, integrate 
			|%1:';"),
		?(Subsystems.Count() > 1,
			NStr("ru = 'подсистемы';
				|en = 'subsystems';"),
			NStr("ru = 'подсистему';
				|en = 'subsystem';")));
	
	For Each Subsystem In Subsystems Do
		ExceptionText = ExceptionText + Chars.LF + Subsystem;
	EndDo;
	
	Raise ExceptionText;
	
EndProcedure

// Checks if it is possible to call application interface
// of the SaaS technology core. If the following subsystems
// are not built in the configuration:
//  - SaaSTechnology.Core
//  - StandardSubsystems.SaaS.CoreSaaS
// the function will return False.
//
// Returns:
//  Boolean - check result.
//
Function CanCallCTLFunctionality()
	
	Return Common.SubsystemExists("CloudTechnology.Core")
		And Common.SubsystemExists("StandardSubsystems.SaaSOperations");
	
EndFunction

#EndRegion
