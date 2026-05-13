///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.Print

// Overrides object's print settings.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// Defines the list of print commands.
//
// Parameters:
//  PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	Command = PrintCommands.Add();
	Command.Id = "_DemoCheckPrintingPermission";
	Command.Presentation = NStr("ru = 'Демо: Проверить разрешение на печать';
								|en = 'Demo: Check print permission';");
	Command.Handler    = "_DemoStandardSubsystemsClient.CheckPrintPermission";
EndProcedure

// End StandardSubsystems.Print

// StandardSubsystems.AttachableCommands

// Defines the list of population commands.
//
// Parameters:
//   FillingCommands - See ObjectsFillingOverridable.BeforeAddFillCommands.FillingCommands.
//   Parameters - See ObjectsFillingOverridable.BeforeAddFillCommands.Parameters.
//
Procedure AddFillCommands(FillingCommands, Parameters) Export
	
EndProcedure

// End StandardSubsystems.AttachableCommands

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowRead
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(StorageLocation)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(EmployeeResponsible)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf