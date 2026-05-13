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
	 Or Not AccessRight("View", Metadata.Reports.EditAccessGroupMembers)
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return;
	EndIf;
	
	ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
	ParametersForReports = ModuleAccessManagementInternal.ParametersForReports();
	
	If Parameters.FormName <> "Catalog.Users.Form.ListForm"
	   And Parameters.FormName <> "Catalog.Users.Form.ItemForm"
	   And Parameters.FormName <> "Catalog.ExternalUsers.Form.ListForm"
	   And Parameters.FormName <> "Catalog.ExternalUsers.Form.ItemForm"
	   And Parameters.FormName <> ParametersForReports.AccessGroupsListFormFullName
	   And Parameters.FormName <> ParametersForReports.AccessGroupsItemFormFullName
	   And Parameters.FormName <> ParametersForReports.ProfilesListFormFullName
	   And Parameters.FormName <> ParametersForReports.ProfilesItemFormFullName Then
		Return;
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.Presentation = NStr("ru = 'Изменение участников групп доступа';
								|en = 'Changes in access group membership';");
	Command.Manager = "Report.EditAccessGroupMembers";
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
		NStr("ru = 'Выводит изменения участников групп доступа с учетом изменения групп пользователей за указанный период по событиям журнала регистрации.';
			|en = 'Reads the event log and displays the changes in user group membership for the given time period.';");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf
