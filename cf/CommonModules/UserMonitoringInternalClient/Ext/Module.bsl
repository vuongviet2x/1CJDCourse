///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Client events of the report form.

// See ReportsClientOverridable.DetailProcessing
Procedure OnProcessDetails(ReportForm, Item, Details, StandardProcessing) Export
	If Details = Undefined Then
		Return;
	EndIf;
	
	If ReportForm.ReportSettings.FullName <> "Report.EventLogAnalysis" Then
		Return;
	EndIf;
	
	If TypeOf(Item.CurrentArea) = Type("SpreadsheetDocumentDrawing") Then
		If TypeOf(Item.CurrentArea.Object) = Type("Chart") Then
			StandardProcessing = False;
			Return;
		EndIf;
	EndIf;
	
	ReportOptionParameter = ReportsClientServer.FindParameter(
		ReportForm.Report.SettingsComposer.Settings,
		ReportForm.Report.SettingsComposer.UserSettings,
		"ReportVariant");
	If ReportOptionParameter = Undefined
	 Or ReportOptionParameter.Value <> "ScheduledJobsDuration" Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	DetailsType = Details.Get(0);
	If DetailsType = "ScheduledJobDetails1" Then
		
		DetailsOption = New ValueList;
		DetailsOption.Add("ScheduledJobInfo", NStr("ru = 'Сведения о регламентном задании';
																		|en = 'Scheduled job info';"));
		DetailsOption.Add("OpenEventLog", NStr("ru = 'Перейти к журналу регистрации';
																	|en = 'Go to event log';"));
		
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Details", Details);
		HandlerParameters.Insert("ReportForm", ReportForm);
		Handler = New NotifyDescription("ResultDetailProcessingCompletion", ThisObject, HandlerParameters);
		ReportForm.ShowChooseFromMenu(Handler, DetailsOption);
		
	ElsIf DetailsType <> Undefined Then
		ShowScheduledJobInfo(Details);
	EndIf;
	
EndProcedure

// See ReportsClientOverridable.AdditionalDetailProcessing
Procedure OnProcessAdditionalDetails(ReportForm, Item, Details, StandardProcessing) Export
	If ReportForm.ReportSettings.FullName <> "Report.EventLogAnalysis" Then
		Return;
	EndIf;
	If TypeOf(Item.CurrentArea) = Type("SpreadsheetDocumentDrawing") Then
		If TypeOf(Item.CurrentArea.Object) = Type("Chart") Then
			StandardProcessing = False;
			Return;
		EndIf;
	EndIf;
EndProcedure

// See ReportsClientOverridable.AtStartValueSelection
Procedure AtStartValueSelection(ReportForm, SelectionConditions, ClosingNotification1, StandardProcessing) Export
	
	If ReportForm.ReportSettings.FullName = "Report.ProfilesRolesChanges" Then
		OnStartSelectValuesInProfilesRolesChangesReport(ReportForm,
			SelectionConditions, ClosingNotification1, StandardProcessing);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
//  SelectedOption - ValueList:
//    * Value - String
//  HandlerParameters - Structure:
//    * Details - DataCompositionDetailsID
//    * ReportForm - ClientApplicationForm
//                  - ManagedFormExtensionForReports:
//        ** ReportSpreadsheetDocument - SpreadsheetDocument
//
Procedure ResultDetailProcessingCompletion(SelectedOption, HandlerParameters) Export
	If SelectedOption = Undefined Then
		Return;
	EndIf;
	
	Action = SelectedOption.Value;
	If Action = "ScheduledJobInfo" Then
		
		Chart = HandlerParameters.ReportForm.ReportSpreadsheetDocument.Areas.GanttChart; // SpreadsheetDocumentDrawing
		ChartObject = Chart.Object; // GanttChart
		PointsList = ChartObject.Points;
		
		PointsList = ChartObject.Points;
		For Each GanttChartPoint In PointsList Do
			
			DetailsPoint = GanttChartPoint.Details;
			If GanttChartPoint.Value = NStr("ru = 'Фоновые задания';
													|en = 'Background jobs';") Then // ACC:1391 Localizable chart point value.
				Continue;
			EndIf;
			
			If DetailsPoint.Find(HandlerParameters.Details.Get(2)) <> Undefined Then
				ShowScheduledJobInfo(DetailsPoint);
				Break;
			EndIf;
			
		EndDo;
		
	ElsIf Action = "OpenEventLog" Then
		
		ScheduledJobSession = New ValueList;
		ScheduledJobSession.Add(HandlerParameters.Details.Get(1));
		StartDate = HandlerParameters.Details.Get(3);
		EndDate = HandlerParameters.Details.Get(4);
		EventLogFilter = New Structure("Session, StartDate, EndDate", 
			ScheduledJobSession, StartDate, EndDate);
		OpenForm("DataProcessor.EventLog.Form.EventLog", EventLogFilter);
		
	EndIf;
	
EndProcedure

Procedure ShowScheduledJobInfo(Details)
	FormParameters = New Structure("DetailsFromReport", Details);
	OpenForm("Report.EventLogAnalysis.Form.ScheduledJobInfo", FormParameters);
EndProcedure

// Intended for procedure "OnValueChoiceStart".
Procedure OnStartSelectValuesInProfilesRolesChangesReport(ReportForm, SelectionConditions, ClosingNotification1, StandardProcessing)
	
	If SelectionConditions.FieldName <> "Role" Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	Selected_ = CommonClient.CopyRecursive(SelectionConditions.Marked);
	DeleteEmptyValues(Selected_);
	
	Collections = New ValueList;
	Collections.Add("Roles");
	
	PickingParameters = StandardSubsystemsClientServer.MetadataObjectsSelectionParameters();
	PickingParameters.ChooseRefs = True;
	PickingParameters.SelectedMetadataObjects = Selected_;
	PickingParameters.MetadataObjectsToSelectCollection = Collections;
	PickingParameters.ObjectsGroupMethod = "ByKinds";
	PickingParameters.Title = NStr("ru = 'Подбор ролей';
										|en = 'Pick roles';");
	
	StandardSubsystemsClient.ChooseMetadataObjects(PickingParameters, ClosingNotification1);
	
EndProcedure

// Intended for the "OnStartSelectValuesInProfilesRolesChangesReport" procedure.
Procedure DeleteEmptyValues(MarkedValues)
	
	IndexOf = MarkedValues.Count() - 1;
	
	While IndexOf >= 0 Do 
		Item = MarkedValues[IndexOf];
		IndexOf = IndexOf - 1;
		
		If Not ValueIsFilled(Item.Value) Then
			MarkedValues.Delete(Item);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion