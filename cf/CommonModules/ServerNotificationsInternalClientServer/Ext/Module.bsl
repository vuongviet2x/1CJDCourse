///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Private

Function ClientNotificationsAreAvailable() Export
	
	If ForTestingPurposesOnly() Then
		Return False;
	EndIf;
	
	SystemInfo = New SystemInfo;
	Version = SystemInfo.AppVersion;
	
	Return CommonClientServer.CompareVersions(Version, "8.3.26.1398") >= 0
	      And CommonClientServer.CompareVersions(Version, "8.3.27.0") < 0
	    Or CommonClientServer.CompareVersions(Version, "8.3.27.1025") >= 0;
	
EndFunction

Function ForTestingPurposesOnly()
	Return True;
EndFunction

Function KeyForServerSideNotifications() Export
	
	Return "StandardSubsystems.Core.ServerNotifications";
	
EndFunction

#EndRegion
