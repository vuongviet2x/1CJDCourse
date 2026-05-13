///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)

	// StandardSubsystems.NationalLanguageSupport
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	// End StandardSubsystems.NationalLanguageSupport

EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)

	// StandardSubsystems.NationalLanguageSupport
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	// End StandardSubsystems.NationalLanguageSupport

EndProcedure

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)

	// StandardSubsystems.NationalLanguageSupport
	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.ChartsOfCalculationTypes._DemoBaseEarnings);
	// End StandardSubsystems.NationalLanguageSupport

EndProcedure

#EndIf

#EndRegion

#Region Private

// Determines the initial item population settings.
//
// Parameters:
//  Settings - Structure:
//    * OnInitialItemFilling - Boolean - If set to True, the OnInitialItemFilling
//      population procedure is called for each item individually.
//
Procedure OnSetUpInitialItemsFilling(Settings) Export

EndProcedure

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// See also InfobaseUpdateOverridable.OnInitialItemsFilling
// 
// Parameters:
//   LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//   Items - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//   TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	Item = Items.Add();
	Item.PredefinedDataName = "BaseSalaryByDays";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Оклад по дням';
		|en = 'Daily income';", LanguagesCodes); // @NStr-1
	Item.Code = NStr("ru = '00001';
						|en = '00001';", Common.DefaultLanguageCode());

	Item = Items.Add();
	Item.PredefinedDataName = "BusinessTripReimbursement";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Оплата командировки';
		|en = 'Business trip payment';", LanguagesCodes); // @NStr-1
	Item.Code = NStr("ru = '00002';
						|en = '00002';", Common.DefaultLanguageCode());
	
EndProcedure

#EndIf

// Called during the initial population of an object's item
// (if the property "OnInitialItemFilling" is set to "True" in "OnSetUpInitialItemsFilling").
//
// Parameters:
//  Object                  - Arbitrary - Object to populate.
//  Data                  - ValueTableRow - Filling data.
//  AdditionalParameters - Structure - Additional parameters.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export

EndProcedure

#EndRegion

