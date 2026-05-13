///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2020, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "OnlineUserSupport.SaaS.GetAddIns" subsystem.
// CommonModule.GetAddInsSaaSOverridable.
//
// Overridable server procedures for importing add-ins:
//  - Add-ins used in the app
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// IDs of add-ins used in the configuration are overridden.
// The specified add-ins will be imported upon default master data processing.
//
// Parameters:
//  IDs - Array of String - contains add-in IDs.
//
//@skip-warning
Procedure OnDefineAddInsVersionsToUse(IDs) Export
	
	
EndProcedure

#EndRegion
