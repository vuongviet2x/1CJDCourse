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
	Settings.Print.TopMargin = 5;
	Settings.Print.LeftMargin = 5;
	Settings.Print.BottomMargin = 5;
	Settings.Print.RightMargin = 5;
	Settings.Events.BeforeImportSettingsToComposer = True;
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.OnDefineSelectionParameters = True;
	Settings.Events.WhenDefiningTheMainFields = True;
EndProcedure

// Runs in the same-name event handler of a report form after executing the form code.
//  See also ClientApplicationForm.OnCreateAtServer in Syntax Assistant 
// and ReportsOverridable.OnCreateAtServer.
//
// Parameters:
//   Form - See CommonForm.ReportForm.
//   Cancel - Boolean - The value is passed "as is" from the handler parameters.
//   StandardProcessing - Boolean - The value is passed "as is" from the handler parameters.
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	Form.Items.SendGroup.ToolTip = NStr("ru = '<Демо: Тест>';
													|en = '<Demo: Test>';");
	If Form.Parameters.VariantKey = "ByVersions" Then
		CommandDetails = CommonClientServer.StructureProperty(Form.Parameters, "CommandDetails"); // See AttachableCommands.CommandDetails
		If CommandDetails <> Undefined And CommandDetails.Id = "_DemoReportByVersions" Then
			File = FormParameters(Form);
			Form.ParametersForm.Filter.Insert("Folder", FilesOwners(File.Ref));
		EndIf;
	EndIf;
	
	Command = Form.Commands.Add("_DemoCommand");
	Command.Action  = "Attachable_Command"; // Command handler See ReportsClientOverridable.HandlerCommands.
	Command.Title = NStr("ru = 'Изменить табличный документ';
							|en = 'Change spreadsheet document';");
	Command.Picture  = PictureLib.Change;
	
	ReportsServer.OutputCommand(Form, Command, "SpreadsheetDocumentOperations");
EndProcedure

// Called before importing new settings. Used for modifying DCS reports.
//
// Parameters:
//   Context - Arbitrary
//   SchemaKey - String
//   VariantKey - String
//                - Undefined
//   NewDCSettings - DataCompositionSettings
//                    - Undefined
//   NewDCUserSettings - DataCompositionUserSettings
//                                    - Undefined
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	SpecifyChangeDate(NewDCSettings);
	
	If SchemaKey = "1" Then
		Return;
	EndIf;
	
	SchemaKey = "1";
	
	// Replace a list of available values so that DCS knows about presentations of these values.
	AllKnownFilesTypes = FilesTypes();
	DCSchemaDataSetField = DataCompositionSchema.DataSets.DataSet1.Fields.Find("Type");
	If TypeOf(DCSchemaDataSetField) = Type("DataCompositionSchemaDataSetField") Then
		DCSchemaDataSetField.SetAvailableValues(AllKnownFilesTypes);
	EndIf;
	
	// Do the same for the nested schema.
	NestedSchema = DataCompositionSchema.NestedDataCompositionSchema.Nested; // NestedDataCompositionSchema 
	DCSchemaDataSetField = NestedSchema.Schema.DataSets.DataSet1.Fields.Find("Type");
	If TypeOf(DCSchemaDataSetField) = Type("DataCompositionSchemaDataSetField") Then
		DCSchemaDataSetField.SetAvailableValues(AllKnownFilesTypes);
	EndIf;
	ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
EndProcedure

// See ReportsOverridable.OnDefineSelectionParameters.
Procedure OnDefineSelectionParameters(Form, SettingProperties) Export
	FieldName = String(SettingProperties.DCField);
	If FieldName = "DataParameters.Size" Then
		SettingProperties.ValuesForSelection.Add(10000000, NStr("ru = 'Больше 10 Мб';
																	|en = 'Exceeds 10 MB';"));
	ElsIf FieldName = "Author" And SettingProperties.TypeDescription.ContainsType(Type("CatalogRef.Users")) Then
		SettingProperties.RestrictSelectionBySpecifiedValues = True;
		SettingProperties.SelectionValuesQuery.Text =
		"SELECT Ref FROM Catalog.Users WHERE NOT DeletionMark AND NOT Invalid AND NOT IsInternal";
	ElsIf FieldName = "Type" Then
		SettingProperties.ValuesForSelection.Clear();
		AllKnownFilesTypes = FilesTypes();
		Query = New Query;
		Query.Text = "SELECT ALLOWED DISTINCT Extension FROM Catalog.FilesVersions";
		Table = Query.Execute().Unload();
		For Each TableRow In Table Do
			Type = Lower(TableRow.Extension);
			If SettingProperties.ValuesForSelection.FindByValue(Type) <> Undefined Then
				Continue;
			EndIf;
			Item = AllKnownFilesTypes.FindByValue(Type);
			If Item = Undefined Then
				Continue;
			EndIf;
			SettingProperties.ValuesForSelection.Add(Item.Value, Item.Presentation);
		EndDo;
	EndIf;
EndProcedure

// See ReportsOverridable.WhenDefiningTheMainFields.
Procedure WhenDefiningTheMainFields(Form, MainField) Export 
	
	MainField.Add("Ref");
	MainField.Add("FileOwner");
	MainField.Add("Type");
	MainField.Add("Author");
	MainField.Add("CreationDate");
	MainField.Add("CurrentVersion");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region Private

// Form parameters.
// 
// Parameters:
//  Form - ClientApplicationForm - Form
// 
// Returns:
//  Structure:
//   * Ref 
//
Function FormParameters(Form)
	Result = New Structure;
	Result.Insert("Ref");
	FillPropertyValues(Result, Form.ParametersForm.Filter);
	Return Result;
EndFunction

// Returns a list of values, where a value is a lowercase file extension.
//
Function FilesTypes()
	Result = New ValueList;
	Result.Add("txt",  NStr("ru = 'Текстовый документ (.txt)';
									|en = 'Text document (.txt)';"));
	Result.Add("xls",  NStr("ru = 'Таблица Excel 97-2003 (.xls)';
									|en = 'Excel 97-2003 spreadsheet (.xls)';"));
	Result.Add("xlsx", NStr("ru = 'Таблица Excel 2007 (.xlsx)';
									|en = 'Excel 2007 spreadsheet (.xlsx)';"));
	Result.Add("mxl",  NStr("ru = 'Таблица 1С (.mxl)';
									|en = '1C spreadsheet (.mxl)';"));
	Result.Add("doc",  NStr("ru = 'Документ Word 97-2003 (.doc)';
									|en = 'Word 97-2003 document (.doc)';"));
	Result.Add("docx", NStr("ru = 'Документ Word 2007 (.docx)';
									|en = 'Word 2007 document (.docx)';"));
	Result.Add("pdf",  NStr("ru = 'Документ Adobe (.pdf)';
									|en = 'Adobe document (.pdf)';"));
	Result.Add("htm",  NStr("ru = 'Веб-страница (.htm)';
									|en = 'Web page (.htm)';"));
	Result.Add("html", NStr("ru = 'Веб-страница (.html)';
									|en = 'Web page (.html)';"));
	Result.Add("png",  NStr("ru = 'Картинка (.png)';
									|en = 'Image (.png)';"));
	Return Result;
EndFunction

Function FilesOwners(FilesArray)
	Query = New Query("SELECT ALLOWED DISTINCT FileOwner FROM Catalog.Files WHERE Ref IN (&FilesArray)");
	Query.SetParameter("FilesArray", FilesArray);
	Return Query.Execute().Unload().UnloadColumn("FileOwner");
EndFunction

Procedure SpecifyChangeDate(Settings)
	
	If TypeOf(Settings) <> Type("DataCompositionSettings") Then 
		Return;
	EndIf;
	
	DataParameters = Settings.DataParameters;
	Period = DataParameters.Items.Find("Period");
	
	If Period = Undefined Then 
		Return;
	EndIf;
	
	SecondsToLocalTime = DataParameters.Items.Find("SecondsToLocalTime");
	
	If SecondsToLocalTime = Undefined Then 
		Return;
	EndIf;
	
	UniversalDate = CurrentSessionDate();
	SecondsToLocalTime.Value = ToLocalTime(UniversalDate, SessionTimeZone()) - UniversalDate;
	SecondsToLocalTime.Use = Period.Use;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf