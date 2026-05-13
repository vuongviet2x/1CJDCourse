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

// StandardSubsystems.BatchEditObjects

// Returns the object attributes that are not recommended to be edited
// using a bulk attribute modification data processor.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export

	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("PropertiesSet");

	Return NotAttributesToEdit;

EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE
	|	TRUE
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Internal

// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling
// 
// Parameters:
//  Settings - See InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.Settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export

	Settings.OnInitialItemFilling = False;

EndProcedure

// See also InfobaseUpdateOverridable.OnInitialItemsFilling
// 
// Parameters:
//   LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//   Items - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//   TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	Item = Items.Add();
	Item.Description = NStr("ru = 'Товар';
								|en = 'Goods';", Common.DefaultLanguageCode());
	Item.Code          = "00-000009";

	Item = Items.Add();
	Item.Description = NStr("ru = 'Услуга';
								|en = 'Service';", Common.DefaultLanguageCode());
	Item.Code          = "DM-000010";

EndProcedure
#EndRegion

#EndIf