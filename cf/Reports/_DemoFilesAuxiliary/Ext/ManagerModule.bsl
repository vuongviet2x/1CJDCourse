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
	ReportSettings.Location.Insert(ReportsOptionsClientServer.HomePageID(), "Important");
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.LongDesc = NStr("ru = 'Список файлов и их авторов в табличном виде.';
										|en = 'List of files and their authors as a table.';");
	OptionSettings.SearchSettings.Keywords =
		NStr("ru = 'Вспомогательные файловые отчеты
		|Модифицированные файлы';
		|en = 'Secondary file reports
		|Modified files';");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf