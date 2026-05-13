///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ReportsOptions

// See ReportsOptionsOverridable.BeforeAddReportCommands.
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions")
	 Or Not Common.SubsystemExists("StandardSubsystems.AccessManagement")
	 Or Not AccessRight("View", Metadata.Reports.ProfilesRolesChanges)
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return;
	EndIf;
	
	ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
	ParametersForReports = ModuleAccessManagementInternal.ParametersForReports();
	
	If Parameters.FormName <> ParametersForReports.ProfilesListFormFullName
	   And Parameters.FormName <> ParametersForReports.ProfilesItemFormFullName Then
		Return;
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.Presentation = NStr("ru = 'Изменение ролей профилей';
								|en = 'Changes in profile roles';");
	Command.Manager = "Report.ProfilesRolesChanges";
	Command.VariantKey = "Main";
	Command.OnlyInAllActions = True;
	Command.Importance = "SeeAlso";
	
EndProcedure

// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		Return;
	EndIf;
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ReportSettings.DefineFormSettings = True;
	ReportSettings.GroupByReport = False;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.Enabled = Common.SubsystemExists("StandardSubsystems.AccessManagement");
	OptionSettings.LongDesc =
		NStr("ru = 'Выводит изменения ролей профилей с учетом изменения состава ролей в метаданных за указанный период по событиям журнала регистрации.';
			|en = 'Reads the event log and displays the changes in profile roles considering the changes or role lists in metadata objects for the given time period.';");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf
