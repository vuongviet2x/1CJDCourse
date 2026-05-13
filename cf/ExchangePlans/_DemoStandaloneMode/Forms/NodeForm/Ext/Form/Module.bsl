///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DataSynchronizationMode =
		?(Object.UseFilterByCompanies, "SynchronizeDataForSelectedCompaniesOnly", "SynchronizeDataForAllCompanies");
		
	SetVisibilityOnServer();
	UpdateNameOfFormCommands();
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	DataExchangeClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_StandaloneWorkstation");
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	UpdateObjectData(ValueSelected);
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CatalogSelectionSwitchWithSelectionOnChange(Item)
	SynchronizationRestrictionConditions();
	SetVisibilityOnServer();
EndProcedure

&AtClient
Procedure CatalogsFilterRadioButtonsWithoutFilterOnChange(Item)
	SynchronizationRestrictionConditions();
	SetVisibilityOnServer();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenSelectedCompaniesList(Command)
	
	FilterCollection = Undefined;
	
	FormParameters = New Structure();
	FormParameters.Insert("NameOfFormElementToFillIn",          "Companies");
	FormParameters.Insert("NameOfFormElementDetailsToFillIn", "Organization");
	FormParameters.Insert("NameOfSelectionTable",                       "Catalog._DemoCompanies");
	FormParameters.Insert("SelectionFormHeader",                   NStr("ru = 'Выберите организации для отбора:';
																			|en = 'Select companies for filter:';"));
	FormParameters.Insert("ArrayOfSelectedValues_",                GenerateArrayOfSelectedValues(FormParameters));
	FormParameters.Insert("ExternalConnectionParameters",            Undefined);
	FormParameters.Insert("FilterCollection",                      FilterCollection);
	
	OpenForm("CommonForm._DemoAdditionalConditionsChoiceForm",
		FormParameters,
		ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SynchronizationRestrictionConditions()
	Object.UseFilterByCompanies = DataSynchronizationMode = "SynchronizeDataForSelectedCompaniesOnly";
EndProcedure

&AtServer
Procedure SetVisibilityOnServer()
		
	CommonClientServer.SetFormItemProperty(
		Items,
		"OpenSelectedCompaniesList",
		"Enabled",
		Object.UseFilterByCompanies);
		
EndProcedure

&AtServer
Procedure UpdateNameOfFormCommands()
	
	// Update the titles of selected companies.
	If Object.Companies.Count() > 0 Then
		
		SelectedCompanies = Object.Companies.Unload().UnloadColumn("Organization");
		NewOrganizationsTitle = StrConcat(SelectedCompanies, ",");
		
	Else
		
		NewOrganizationsTitle = NStr("ru = 'Выбрать организации';
										|en = 'Select companies';");
		
	EndIf;
	
	Items.OpenSelectedCompaniesList.Title = NewOrganizationsTitle;
	
EndProcedure

&AtServer
Procedure UpdateObjectData(ParametersStructure)
	
	Object[ParametersStructure.NameOfTableToFillIn].Clear();
	
	SelectedValuesList = GetFromTempStorage(ParametersStructure.AddressOfTableInTemporaryStorage); // ValueTable
	
	If SelectedValuesList.Count() > 0 Then
		ColumnPresentation = SelectedValuesList.Columns.Presentation; // ValueTableColumn
		ColumnPresentation.Name = ParametersStructure.NameOfColumnToFillIn;
		Object[ParametersStructure.NameOfTableToFillIn].Load(SelectedValuesList);
	EndIf;
	
	UpdateNameOfFormCommands();
	
EndProcedure

&AtServer
Function GenerateArrayOfSelectedValues(FormParameters)
	
	TabularSection           = Object[FormParameters.NameOfFormElementToFillIn];
	TableOfSelectedValues = TabularSection.Unload(,FormParameters.NameOfFormElementDetailsToFillIn);
	ArrayOfSelectedValues_  = TableOfSelectedValues.UnloadColumn(FormParameters.NameOfFormElementDetailsToFillIn);
	
	Return ArrayOfSelectedValues_;
	
EndFunction

#EndRegion


