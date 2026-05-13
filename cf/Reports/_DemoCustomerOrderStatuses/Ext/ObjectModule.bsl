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
	Settings.Events.OnDefineSelectionParameters = True;
	Settings.Events.OnDefineUsedTables = True;
	Settings.Print.TopMargin = 5;
	Settings.Print.LeftMargin = 5;
	Settings.Print.BottomMargin = 5;
	Settings.Print.RightMargin = 5;
	Settings.GenerateImmediately = True;
EndProcedure

// See ReportsOverridable.OnDefineSelectionParameters.
Procedure OnDefineSelectionParameters(Form, SettingProperties) Export
	Custom_2 = SettingProperties.UserSetting;
	If Custom_2 <> Undefined
		And Custom_2.ItemsType = "ListWithPicking" Then // Instead of a list with flags and command bar...
		Custom_2.ItemsType = "LinkWithComposer"; // ...show DCS-linked input field.
	EndIf;
	
	If SettingProperties.TypeDescription.ContainsType(Type("CatalogRef.Users")) Then
		SettingProperties.RestrictSelectionBySpecifiedValues = True;
		SettingProperties.ValuesForSelection.Clear();
		SettingProperties.SelectionValuesQuery.Text =
			"SELECT Ref FROM Catalog.Users
			|WHERE NOT DeletionMark AND NOT Invalid AND NOT IsInternal";
	EndIf;
EndProcedure

// Parameters:
//   VariantKey - String
//                - Undefined
//   TablesToUse - Array of String
//
Procedure OnDefineUsedTables(VariantKey, TablesToUse) Export
	
	TablesToUse.Add(Metadata.Documents._DemoSalesOrder.FullName());
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf