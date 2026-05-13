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
// CommonModule.OnlineUserSupportClientOverridable.
//
// Client overridable procedures and functions:
//  - Define the functionality for navigating to integrated websites
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Overrides a web page opening in the configuration if there is
// own functionality for opening web pages in the configuration.
// If the configuration does not use its own functionality for opening
// web pages, you need to leave the procedure body blank,
// otherwise, set the StandardProcessing parameter
// to False.
//
// Parameters:
//	PageAddress - String - URL of a web page to open.
//	WindowTitle - String - Title of the window
//		in which a web page is displayed if an internal configuration form
//		is used to open the web page.
//	StandardProcessing - Boolean - Flag indicating whether
//		a notification must be shown is returned in the parameter.
//		The default value is True.
//
//@skip-warning
Procedure OpenInternetPage(PageAddress, WindowTitle, StandardProcessing) Export
	
	
	
EndProcedure

#EndRegion
