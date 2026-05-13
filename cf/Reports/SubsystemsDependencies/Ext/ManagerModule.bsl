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
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.LongDesc = NStr("ru = 'Поиск недокументированных связей между подсистемами БСП.';
										|en = 'Search for undocumented links between SSL subsystems.';");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region Private

// For internal use only.
Function InvalidSSLSubsystemsDependencies(ModulesExportDirectory) Export
	
	ReportObject = Create();
	Result = ReportObject.ReportOnDependencies(ModulesExportDirectory);
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf