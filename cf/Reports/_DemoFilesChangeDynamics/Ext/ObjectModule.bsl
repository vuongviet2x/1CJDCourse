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

// Specify the report form settings.
//
// Parameters:
//   Form - ClientApplicationForm
//         - Undefined
//   VariantKey - String
//                - Undefined
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.GenerateImmediately = True;
	Settings.OutputSelectedCellsTotal = Not Common.DebugMode();
	Settings.Events.OnDefineSelectionParameters = True;
EndProcedure

// See ReportsOverridable.OnDefineSelectionParameters.
Procedure OnDefineSelectionParameters(Form, SettingProperties) Export
	If SettingProperties.TypeDescription.ContainsType(Type("CatalogRef._DemoCompanies")) Then
		SettingProperties.RestrictSelectionBySpecifiedValues = True;
		SettingProperties.ValuesForSelection.Clear();
		SettingProperties.SelectionValuesQuery.Text =
		"SELECT ALLOWED Ref FROM Catalog._DemoCompanies WHERE NOT DeletionMark";
	EndIf;
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(SpreadsheetDocument, DetailsData, StandardProcessing)
	DCSettings = SettingsComposer.GetSettings();
	Delay = FindParameter(DCSettings, Undefined, "MinGenerationSpeed").Value;
	EndDateInMilliseconds = CurrentUniversalDateInMilliseconds() + 1000*Delay;
	
	StandardProcessing = False;
	GenerateReport(SpreadsheetDocument, DetailsData, DCSettings);
	
	Cell = SpreadsheetDocument.Area(SpreadsheetDocument.TableHeight + 2, 1, SpreadsheetDocument.TableHeight + 2, 2);
	Cell.Merge();
	ReportsServer.OutputHyperlink(Cell, "e1cib/list/Catalog.Files", NStr("ru = 'Список файлов';
																				|en = 'File list';"));
	
	While CurrentUniversalDateInMilliseconds() < EndDateInMilliseconds Do
	EndDo;
EndProcedure

#EndRegion

#Region Private

Procedure GenerateReport(SpreadsheetDocument, DetailsData, DCSettings)
	DCTemplateComposer = New DataCompositionTemplateComposer;
	DCTemplate = DCTemplateComposer.Execute(DataCompositionSchema, DCSettings, DetailsData);
	
	DCProcessor = New DataCompositionProcessor;
	DCProcessor.Initialize(DCTemplate, , DetailsData, True);
	
	DCResultOutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	DCResultOutputProcessor.SetDocument(SpreadsheetDocument);
	DCResultOutputProcessor.Output(DCProcessor);
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, DCProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
EndProcedure

Function FindParameter(DCSettings, DCUserSettings, ParameterName) Export
	Return FindParameters(DCSettings, DCUserSettings, ParameterName)[ParameterName];
EndFunction

// Parameters:
//  DCSettings - DataCompositionSettings
//  DCUserSettings - DataCompositionUserSettings
//  ParameterNames - String
// Returns:
//  Structure
//
Function FindParameters(DCSettings, DCUserSettings, ParameterNames)
	Result = New Structure;
	RequiredParameters1 = New Map;
	NamesArray = StrSplit(ParameterNames, ",", False);
	Count = 0;
	For Each ParameterName In NamesArray Do
		RequiredParameters1.Insert(TrimAll(ParameterName), True);
		Count = Count + 1;
	EndDo;
	
	If DCUserSettings <> Undefined Then
		For Each DCItem In DCUserSettings.Items Do
			If TypeOf(DCItem) = Type("DataCompositionSettingsParameterValue") Then
				ParameterName = String(DCItem.Parameter);
				If RequiredParameters1[ParameterName] = True Then
					Result.Insert(ParameterName, DCItem);
					RequiredParameters1.Delete(ParameterName);
					Count = Count - 1;
					If Count = 0 Then
						Break;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	If Count > 0 Then
		For Each KeyAndValue In RequiredParameters1 Do
			If DCSettings <> Undefined Then
				DCItem = DCSettings.DataParameters.Items.Find(KeyAndValue.Key);
			Else
				DCItem = Undefined;
			EndIf;
			Result.Insert(KeyAndValue.Key, DCItem);
		EndDo;
	EndIf;
	
	Return Result;
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf