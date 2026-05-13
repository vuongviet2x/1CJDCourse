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
	
	ReportsOptionsAvailable = PerformanceMonitorInternal.SubsystemExists("StandardSubsystems.ReportsOptions");
	If ReportsOptionsAvailable Then
		ModuleReportsOptions = PerformanceMonitorInternal.CommonModule("ReportsOptions");
		
		OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "PerformanceMonitorByKeyOperations"); // See ReportsOptions.OptionDetails		
		OptionSettings.LongDesc = 
			NStr("ru = 'Предоставляет информацию об оценке производительности';
				|en = 'Provides Apdex metrics.';");
			
		OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "PerformanceMonitorComparison"); // See ReportsOptions.OptionDetails
		OptionSettings.LongDesc = 
			NStr("ru = 'Предоставляет информацию о сравнении оценки производительности за период';
				|en = 'Compares Apdex metrics during a period';");
			
		OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "PerformanceMonitorPeriodInColumns"); // See ReportsOptions.OptionDetails
		OptionSettings.LongDesc = 
			NStr("ru = 'Предоставляет информацию об оценке производительности в разрезе периодов. Периоды представлены в колонках';
				|en = 'Provides Apdex metrics by period.';");
	EndIf;
			
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf
