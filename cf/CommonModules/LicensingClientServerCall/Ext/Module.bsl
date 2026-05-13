///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2021, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The Online Support subsystem.
// CommonModule.LicensingClientServerCall.
//
// Server procedures and functions for setting up the licensing client.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Returns a flag of synchronization of licensing client settings
// and a flag of connecting online support by the current user.
//
Function CheckLicensingClientSettings() Export
	
	CheckResult = LicensingClient.CheckLicensingClientSettings();
	Return New Structure(
		"SettingsSynchronized, EnableOUSRight",
		CheckResult,
		OnlineUserSupport.CanConnectOnlineUserSupport());
	
EndFunction

#EndRegion
