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

// Runs in SaaS to get info about predefined report options.
//
// Returns:
//  Array of Structure:
//    * Name           - String - Report option name. For example, "Main".
//    * Presentation - String - Report option name. For example: NStr("en = 'File change dynamics'").
//
Function SettingVariants() Export
	Result = New Array;
	Result.Add(New Structure("Name, Presentation", "Main", NStr("ru = 'Демо: Динамика изменений файлов';
																				|en = 'Demo: file-changing dynamics';")));
	Result.Add(New Structure("Name, Presentation", "Additional1", NStr("ru = 'Демо: Дополнительный 1';
																					|en = 'Demo: Additional 1';")));
	Result.Add(New Structure("Name, Presentation", "Additional2", NStr("ru = 'Демо: Дополнительный 2';
																					|en = 'Demo: Additional 2';")));
	Result.Add(New Structure("Name, Presentation", "Additional3", NStr("ru = 'Демо: Дополнительный 3';
																					|en = 'Demo: Additional 3';")));
	Result.Add(New Structure("Name, Presentation", "Additional4", NStr("ru = 'Демо: Дополнительный 4';
																					|en = 'Demo: Additional 4';")));
	Result.Add(New Structure("Name, Presentation", "Additional5", NStr("ru = 'Демо: Дополнительный 5';
																					|en = 'Demo: Additional 5';")));
	Return Result;
EndFunction

// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	ReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	ReportSettings.DefineFormSettings = True;
	ReportSettings.Location.Delete(Metadata.Subsystems._DemoOrganizer.Subsystems._DemoFilesOperations);
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.LongDesc = NStr("ru = 'Динамика прироста количества и размера файлов в виде наглядного графика по дням или месяцам.';
										|en = 'The dynamics of increase in the number and size of files in the form of a visual graph by days or months.';");
	OptionSettings.FunctionalOptions.Add("UseNotes");
	OptionSettings.Location.Insert(Metadata.Subsystems._DemoOrganizer.Subsystems._DemoReportsOptions, "Important");
	
	// Hide a report option with a developer setting.
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "Additional1");
	OptionSettings.LongDesc = NStr("ru = 'Дополнительный 1.';
										|en = 'Additional 1.';");
	OptionSettings.DefaultVisibility = False;
	
	// Hide a report option with an administrator setting.
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "Additional2");
	OptionSettings.LongDesc = NStr("ru = 'Дополнительный 2.';
										|en = 'Additional 2.';");
	OptionSettings.DefaultVisibility = True;
	
	// Hiding a report option with a user setting.
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "Additional3");
	OptionSettings.LongDesc = NStr("ru = 'Дополнительный 3.';
										|en = 'Additional 3.';");
	OptionSettings.DefaultVisibility = True;
	
	// Disable a report option (unconditionally).
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "Additional4");
	OptionSettings.LongDesc = NStr("ru = 'Дополнительный 4.';
										|en = 'Additional 4.';");
	OptionSettings.Enabled = False;
	
	// Disable a report option (depending on a functional option).
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "Additional5");
	OptionSettings.LongDesc = NStr("ru = 'Дополнительный 5.';
										|en = 'Additional 5.';");
	OptionSettings.FunctionalOptions.Add("UseExternalUsers");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf