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

// StandardSubsystems.AdditionalReportsAndDataProcessors

// Returns info about an external report.
//
// Returns:
//   See AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo.
//
Function ExternalDataProcessorInfo() Export
	RegistrationParameters = AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo("2.3.1.1");
	
	RegistrationParameters.Kind = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalReport();
	RegistrationParameters.Version = "1.0";
	RegistrationParameters.DefineFormSettings = True;
	
	Return RegistrationParameters;
EndFunction

// End StandardSubsystems.AdditionalReportsAndDataProcessors

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
	Settings.Print.TopMargin = 5;
	Settings.Print.LeftMargin = 5;
	Settings.Print.BottomMargin = 5;
	Settings.Print.RightMargin = 5;
	Settings.GenerateImmediately = False;
	Settings.Events.BeforeImportSettingsToComposer = True;
	Settings.Events.OnDefineSelectionParameters = True;
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
	If SchemaKey <> "1" Then
		SchemaKey = "1";
		DCSchema = Reports._DemoFiles.GetTemplate("MainDataCompositionSchema");
		DCParameter = DCSchema.Parameters.Add();
		DCParameter.Name = "OrderStatusOrOperationKind";
		DCParameter.Title = NStr("ru = 'Статус заказа или вид операции';
									|en = 'Order status or operation type';");
		DCParameter.ValueType = New TypeDescription("EnumRef._DemoCustomerOrderStatuses, EnumRef._DemoBusinessOperations");
		ReportsServer.AttachSchema(ThisObject, Context, DCSchema, SchemaKey);
	EndIf;
	If VariantKey = "Main" And NewDCSettings <> Undefined And NewDCSettings.Structure.Count() = 0 Then
		SetPrivilegedMode(True);
		OptionRef = Catalogs.ReportsOptions.FindByDescription(NStr("ru = 'Демо: Версии файлов (подробно)';
																			|en = 'Demo: file versions (detailed)';"));
		If ValueIsFilled(OptionRef) Then
			NewDCSettings = Common.ObjectAttributeValue(OptionRef, "Settings").Get();
		Else
			DCSchema = Reports._DemoFiles.GetTemplate("MainDataCompositionSchema");
			NewDCSettings = DCSchema.SettingVariants.ByVersions.Settings;
		EndIf;
		SetPrivilegedMode(False);
	EndIf;
EndProcedure

// See ReportsOverridable.OnDefineSelectionParameters.
Procedure OnDefineSelectionParameters(Form, SettingProperties) Export
	FieldName = String(SettingProperties.DCField);
	If FieldName = "Author" And SettingProperties.TypeDescription.ContainsType(Type("CatalogRef.Users")) Then
		SettingProperties.RestrictSelectionBySpecifiedValues = True;
		SettingProperties.ValuesForSelection.Clear();
		SettingProperties.SelectionValuesQuery.Text =
		"SELECT Ref FROM Catalog.Users WHERE NOT DeletionMark AND NOT Invalid AND NOT IsInternal";
	ElsIf FieldName = "TestGroup1.TestFieldInGroup" Then
		SettingProperties.UserSetting.ItemsType = "LinkWithComposer";
	ElsIf FieldName = "Test" Then
		Item = SettingProperties.ValuesForSelection.FindByValue(-1);
		If Item <> Undefined Then
			SettingProperties.ValuesForSelection.Delete(Item);
		EndIf;
	EndIf;
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf