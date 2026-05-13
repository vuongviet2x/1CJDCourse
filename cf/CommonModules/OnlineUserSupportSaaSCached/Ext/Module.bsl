///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "SaaS.OSL core" subsystem.
// CommonModule.OnlineUserSupportSaaSCached.
//
// Online Support cache server procedures and functions:
//  - Determine data area settings
//
////////////////////////////////////////////////////////////////////////////////

#Region Private

// Defines a data area based on the passed separator.
//
// Parameters:
//  SeparatorValue - Number - Separator.
//
// Returns:
//  Number - an area key.
//
Function DataAreaKey(SeparatorValue) Export
	
	SaaSOSL.SetSessionSeparation(True, SeparatorValue);
	
	SetPrivilegedMode(True);
	
	// Get the constant by name to bypass the syntax check
	// in configurations that don't support the SaaS mode.
	Result = Constants["DataAreaKey"].Get();
	
	SetPrivilegedMode(False);
	
	SaaSOSL.SetSessionSeparation(False);
	
	Return Result;
	
EndFunction

#EndRegion