///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2021, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "Application update" subsystem.
// CommonModule.GetApplicationUpdatesOverridable.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Determines the parameters for functionality of getting application updates.
//
// Parameters:
//	UpdatesGetParameters - Structure - parameters of getting updates:
//		* GetConfigurationUpdates - Boolean - enable functionality
//			of getting configuration updates in a working application
//			update scenario. Configuration update receipt is always used in scenarios of migration to a new configuration edition
//			or a new configuration.
//			Default parameter value is True.
//		* GetPatches - Boolean - use functionality of getting
//			configuration patches.
//			Default parameter value is True.
//		* SelectDirectoryToSavePlatformDistributionPackage - Boolean - in non-base configuration version,
//			offer to save 1C:Enterprise platform distribution package
//			to a directory on a hard drive or LAN. The setting is not used in a base version, 1C:Enterprise platform distribution package
//			is saved to a default directory.
//			Default parameter value is True.
//
//@skip-warning
Procedure OnDefineUpdatesGetParameters(UpdatesGetParameters) Export
	
EndProcedure

// Overrides the parameters of the patches being downloaded and installed.
//
// Parameters:
//  Settings - Structure:
//    * DisableNotifications - Boolean - If True, the task on enabling auto-download of patches will be disabled in the ToDoList subsystem
//        and the user will not be notified if the ToDoList subsystem is not integrated in the configuration on startup.
//        
//    * Subsystems - Array of Structure - A list of apps whose patches should be downloaded and installed:
//        ** SubsystemName - String - The subsystem name. For example, "StandardSubsystems".
//        ** OnlineSupportID - String - The app name in Online Support services.
//        ** Version - String - A 4-digit version number. For example, "2.1.3.1".
//
//@skip-warning
Procedure OnDefinePatchesDownloadSettings(Settings) Export
	
	
EndProcedure

#EndRegion
