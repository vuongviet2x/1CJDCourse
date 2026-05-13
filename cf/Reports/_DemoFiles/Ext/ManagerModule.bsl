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
	ReportSettings.Location.Delete(Metadata.Subsystems._DemoOrganizer.Subsystems._DemoFilesOperations);
	ReportSettings.Location.Insert(ReportsOptionsClientServer.HomePageID(), "Important");
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.LongDesc = NStr("ru = 'Список файлов и их авторов в иерархии папок.';
										|en = 'List of files and their authors in the folder hierarchy.';");
	OptionSettings.SearchSettings.Keywords =
		NStr("ru = 'Файловые функции
		|Динамика изменений файлов';
		|en = 'File functions
		|Dynamics of file changes';");
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "BySize");
	OptionSettings.LongDesc = NStr("ru = 'Топ-10 самых больших файлов, отредактированных за указанный период.';
										|en = 'Top 10 of the biggest files edited during the specified period.';");
	OptionSettings.SearchSettings.Keywords =
		NStr("ru = 'Топ-10
		|Крупные файлы';
		|en = 'Top 10
		|Large files';");
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "ByTypes");
	OptionSettings.LongDesc = NStr("ru = 'Круговая диаграмма использующихся типов файлов.';
										|en = 'Pie chart of used file types.';");
	OptionSettings.SearchSettings.Keywords =
		NStr("ru = 'Расширения';
			|en = 'Extensions';");
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "ByVersions");
	OptionSettings.LongDesc = NStr("ru = 'Список версий, файлов и папок в табличном виде.';
										|en = 'List of versions, files, and folders as a table.';");
	OptionSettings.SearchSettings.Keywords =
		NStr("ru = 'Версии
		|Загруженные файлы';
		|en = 'Versions
		|Imported files';");
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "Auxiliary");
	OptionSettings.Enabled = False;
EndProcedure

// Defines the list of report commands.
//
// Parameters:
//  ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//  Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	If AccessRight("View", Metadata.Reports._DemoFiles) Then
		Command = ReportsCommands.Add();
		Command.VariantKey      = "ByVersions";
		Command.FormParameterName = "Filter.Ref";
		Command.Presentation     = NStr("ru = 'Демо: Отчет по версиям';
										|en = 'Demo: Versions report';");
		Command.Id     = "_DemoReportByVersions";
		Command.Importance          = "Important";
	EndIf;
	
EndProcedure

// End StandardSubsystems.ReportsOptions

// StandardSubsystems.AttachableCommands

// Defines settings for integrating the report with configuration functionality. 
//
// Parameters:
//  InterfaceSettings4 - See AttachableCommands.AttachableObjectSettings
//
Procedure OnDefineSettings(InterfaceSettings4) Export
	InterfaceSettings4.CustomizeReportOptions = True;
	InterfaceSettings4.DefineFormSettings = True;
	InterfaceSettings4.AddReportCommands = True;
	InterfaceSettings4.Location.Add(Metadata.Catalogs.Files);
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#EndIf