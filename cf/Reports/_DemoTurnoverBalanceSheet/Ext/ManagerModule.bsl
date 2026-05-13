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

// StandardSubsystems.ReportsOptions

// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.LongDesc = NStr("ru = 'Регистр бухгалтерского учета: остатки и обороты по дебету и кредиту за период.';
										|en = 'Accounting register: debit and credit balance and turnovers for the period.';");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

// StandardSubsystems.AttachableCommands

// See AttachableCommandsOverridable.OnDefineAttachableObjectsSettingsComposition
Procedure OnDefineSettings(InterfaceSettings4) Export
	
	InterfaceSettings4.DefineFormSettings = True;
	
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#EndIf