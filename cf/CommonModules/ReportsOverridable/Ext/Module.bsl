///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// Called in the same-name event handler after executing the report form code.
// See "ReportsClientOverridable.CommandHandler" and "ClientApplicationForm.OnCreateAtServer" in Syntax Assistant.
//
// Parameters:
//   Form - ClientApplicationForm - Report form.
//         - ManagedFormExtensionForReports
//         - Structure:
//           * ReportSettings - See ReportsClientServer.DefaultReportSettings
//   Cancel - Boolean - Flag indicating that the form creation is canceled.
//   StandardProcessing - Boolean - Flag indicating whether standard (system) event processing is executed.
//
// Example:
//	Add a command with a handler to ReportsClientOverridable.CommandHandler:
//	Command = ReportForm.Commands.Add("MySpecialCommand");
//	Command.Action = Attachable_Command;
//	Command.Header = NStr("en = 'My command…'");
//	
//	Button = ReportForm.Items.Add(Command.Name, Type("FormButton"), ReportForm.Items.<SubmenuName>);
//	Button.CommandName = Command.Name;
//	
//	ReportForm.ConstantCommands.Add(CreateCommand.Name);
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	// _Demo Example Start
	FullReportName = Form.ReportSettings.FullName;
	If StrFind(FullReportName, "_Demo") = 0 Then 
		Return;
	EndIf;
	
	Command = Form.Commands.Add("_DemoRegisterFaultyData");
	Command.Action = "Attachable_Command";
	Command.Title = NStr("ru = 'Оформить как ошибочные данные';
							|en = 'Format as invalid input';");
	Command.ToolTip = NStr("ru = 'Закрашивание выделенных ячеек цветом, подчеркивающим некорректность данных';
							|en = 'Highlight the cells with the color that indicates incorrect data.';");
	Command.Picture = PictureLib.Appearance;
	Command.Representation = ButtonRepresentation.Picture;
	If Common.IsMobileClient() Then
		OnlyInAllActions = True;
	Else
		OnlyInAllActions = False;
	EndIf;
	ReportsServer.OutputCommand(Form, Command, "Other", , OnlyInAllActions);
	
	Command = Form.Commands.Add("_DemoRegisterCorrectData");
	Command.Action = "Attachable_Command";
	Command.Title = NStr("ru = 'Оформить как корректные данные';
							|en = 'Format as valid input';");
	Command.ToolTip = NStr("ru = 'Закрашивание выделенных ячеек цветом доверия';
							|en = 'Highlight the cells with the color that indicates correct data.';");
	ReportsServer.OutputCommand(Form, Command, "Other", , True);
	
	Command = Form.Commands.Add("_DemoRegisterDubiousData");
	Command.Action = "Attachable_Command";
	Command.Title = NStr("ru = 'Оформить как сомнительные данные';
							|en = 'Format as ambiguous input';");
	Command.ToolTip = NStr("ru = 'Закрашивание выделенных ячеек предупреждающим цветом';
							|en = 'Highlight the cells with the color that indicates ambiguous data.';");
	ReportsServer.OutputCommand(Form, Command, "Other", , True);
	// _Demo Example End
	
EndProcedure

// Called in the event handler of the report form and the report settings form.
// See "Client application form extension for reports.BeforeLoadVariantAtServer" in Syntax Assistant.
//
// Parameters:
//   Form - ClientApplicationForm - Report form or a report settings form.
//   NewDCSettings - DataCompositionSettings - Settings to load into the Settings Composer.
//
Procedure BeforeLoadVariantAtServer(Form, NewDCSettings) Export
	
	// _Demo Example Start
	LayoutTemplateParameter = NewDCSettings.OutputParameters.Items.Find("AppearanceTemplate");
	If LayoutTemplateParameter.Value = "Main" Or LayoutTemplateParameter.Value = "Main" Then
		LayoutTemplateParameter.Value      = "_DemoReportAppearanceBeige";
		LayoutTemplateParameter.Use = True;
	EndIf;
	
	For Each StructureItem In NewDCSettings.Structure Do
		
		If TypeOf(StructureItem) = Type("DataCompositionNestedObjectSettings") Then
			
			LayoutTemplateParameter = StructureItem.Settings.OutputParameters.Items.Find("AppearanceTemplate");
			If LayoutTemplateParameter.Value = "Main" 
				Or LayoutTemplateParameter.Value = "Main" Then
				LayoutTemplateParameter.Value      = "_DemoReportAppearanceBeige";
				LayoutTemplateParameter.Use = True;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// A form can be not a report form but a report setting form.
	If Form.Items.Find("ReportSpreadsheetDocument") <> Undefined Then 
		Form.Items.ReportSpreadsheetDocument.ViewScalingMode = ViewScalingMode.Normal;
	EndIf;
	
	// _Demo Example End
	
EndProcedure

// Called in the report form and report settings form before displaying the setting 
// for specifying additional choice parameters.
// Obsolete, use the AfterLoadSettingsInLinker event of the report module instead.
// 
// Parameters:
//  Form - ClientApplicationForm
//        - ManagedFormExtensionForReports
//        - Undefined - Report form.
//  SettingProperties - Structure - Details of the report setting to be displayed in the report form, where::
//      * DCField - DataCompositionField - Setting to be output.
//      * TypeDescription - TypeDescription - Type of a setting to be output.
//      * ValuesForSelection - ValueList - Objects to be prompted to a user in the choice list.
//                            The parameter adds items to the list of objects previously selected by a user.
//                            Note: Do not assign new value lists to this parameter.
//      * SelectionValuesQuery - Query - Query to obtain objects to be added to ValuesForSelection. 
//                               As the first column (with 0 index), select the object,
//                               that has to be added to the ValuesForSelection.Value.
//                               To disable autofilling, assign the SelectionValuesQuery.Text property
//                               to a blank string.
//      * RestrictSelectionBySpecifiedValues - Boolean - Pass True to restrict user selection
//                                                with values specified in ValuesForSelection (its final state).
//      * Type - String
//
// Example:
//   1. For all CatalogRef.Users settings, hide and do not allow selecting users marked for deletion, 
//   inactive users, and utility users.
//
//   If SettingProperties.TypeDescription.ContainsType(Type("CatalogRef.Users")) Then
//     SettingProperties.RestrictSelectionBySpecifiedValues = True;
//     SettingProperties.ValuesForSelection.Clear();
//     SettingProperties.SelectionValuesQuery.Text =
//       "SELECT Ref FROM Catalog.Users
//       |WHERE NOT DeletionMark AND NOT Invalid AND NOT IsInternal";
//   EndIf;
//
//   2. Provide an additional value for selection for the Size setting.
//
//   If SettingProperties.DCField = New DataCompositionField("DataParameters.Size") Then
//     SettingProperties.ValuesForSelection.Add(10000000, NStr("en = 'Over 10 MB'"));
//   EndIf;
//
Procedure OnDefineSelectionParameters(Form, SettingProperties) Export
	
EndProcedure

// Allows to set a list of frequently used fields displayed in the submenu for context menu commands 
// "Insert field to the left", "Insert grouping below", etc.  
//
// Parameters:
//   Form - ClientApplicationForm - Report form.
//   MainField - Array of String - Names of the most frequently used report fields.
//
Procedure WhenDefiningTheMainFields(Form, MainField) Export 
	
	// _Demo Example Start
	If StrStartsWith(Form.WindowOptionsKey, "Report._DemoFiles") Then 
		
		MainField.Add("Ref");
		MainField.Add("Owner");
		MainField.Add("Recorder");
		
	EndIf;
	// _Demo Example End
	
EndProcedure

#EndRegion
