///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2020, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "Application update" subsystem.
// CommonModule.GetApplicationUpdatesClientOverridable.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Defines whether it is necessary to show a pop-up notification about
// an available application update. It is called only if
// the StandardSubsystems.ToDoList built-in subsystem is present.
//
// Parameters:
//	Use - Boolean - Flag indicating whether a
//		notification must be shown is returned in the parameter. True- show, otherwise, False.
//		The default value is False.
//
//@skip-warning
Procedure OnDefineIsNecessaryToShowAvailableUpdatesNotifications(Use) Export
	
	
EndProcedure

#EndRegion
