///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "OnlineUserSupport.ClassifiersOperations" subsystem.
// CommonModule.ClassifiersOperationsClientServer.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Returns the key ID of the common settings storage object.
//
// Returns:
//  String
//
Function CommonSettingsID() Export
	
	Return "OnlineSupport_ClassifierManagement";
	
EndFunction

// Returns the ID of the setting key of the common storage containing the date when 
// the user was notified on the start of the update download.
//
// Returns:
//  String
//
Function DateOfNotificationOnGetUpdatesEnabledSettingKey() Export
	
	Return "DateOfNotificationOnGetUpdatesEnabled";
	
EndFunction

#EndRegion