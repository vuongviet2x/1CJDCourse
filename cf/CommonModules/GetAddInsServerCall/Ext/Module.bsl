///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "OnlineUserSupport.SaaS.GetAddIns" subsystem.
// CommonModule.GetAddInsServerCall.
//
// Server procedures and functions for importing add-ins:
//  - Set up add-in update mode
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Determines the schedule of a add-in update job.
//
// Returns:
//  Structure - The settings of the add-in update schedule job.
//              See GetAddIns.AddInsUpdateSettings.
//
Function AddInsUpdateSettings() Export
	
	Return GetAddIns.AddInsUpdateSettings();
	
EndFunction

// Changes the add-in update settings.
//
// Parameters:
//  Settings - Structure - **AddInsFile - String - The path to a add-ins file.
//    **Schedule - JobSchedule - The update schedule.
//    **AddInsFile - String - The path to a add-ins file.
//    **Schedule - JobSchedule - The update schedule.
//
Procedure ChangeAddInsUpdateSettings(Val Settings) Export
	
	GetAddIns.ChangeAddInsUpdateSettings(Settings);
	
EndProcedure

#EndRegion
