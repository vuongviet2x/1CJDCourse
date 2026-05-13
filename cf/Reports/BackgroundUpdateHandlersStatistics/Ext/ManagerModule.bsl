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
	OptionSettings.LongDesc = NStr("ru = 'Длительность обработчиков обновления в разрезе библиотек и версий.';
										|en = 'The duration of update handlers broken down by libraries and versions.';");
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "ByDuration");
	OptionSettings.LongDesc = NStr("ru = 'Длительность обработчиков обновления плоским списком.';
										|en = 'The duration of update handlers as a flat list.';");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf