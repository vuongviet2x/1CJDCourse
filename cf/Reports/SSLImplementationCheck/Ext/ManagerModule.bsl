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
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsOptions = Common.CommonModule("ReportsOptions");
		OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ByConfigurationSubsystems");
		OptionSettings.LongDesc = NStr("ru = 'Проверка внедрения по подсистемам конфигурации.';
											|en = 'Check integration by configuration subsystem.';");
		OptionSettings.SearchSettings.Keywords = NStr("ru = 'Проверка внедрения по подсистемам конфигурации';
																	|en = 'Check integration by configuration subsystem';");
		
		OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "BySSLSubsystems");
		OptionSettings.LongDesc = NStr("ru = 'Проверка внедрения по подсистемам БСП.';
											|en = 'Check integration by SSL subsystem.';");
		OptionSettings.SearchSettings.Keywords = NStr("ru = 'Проверка внедрения по подсистемам БСП';
																	|en = 'Check integration by SSL subsystem';");
	EndIf;
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf