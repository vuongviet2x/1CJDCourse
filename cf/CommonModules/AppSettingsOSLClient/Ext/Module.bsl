///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

//////////////////////////////////////////////////////////////////////////////////
// The "App settings" subsystem.
// CommonModule.AppSettingsOSLClient.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Opens the setup dialog for Online Support and OSL services.
//
// Parameters:
//  CommandExecuteParameters - CommandExecuteParameters
//
Procedure OpenSettingsOnlineSupportAndServices(CommandExecuteParameters) Export
	
	OpenForm(
		"DataProcessor.OSLAdministrationPanel.Form.InternetSupportAndServices",
		,
		CommandExecuteParameters.Source,
		"DataProcessor.OSLAdministrationPanel.Form.InternetSupportAndServices"
			+ ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
