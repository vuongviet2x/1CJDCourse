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

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the ObjectsVersioning subsystem.
//
// Parameters:
//  Settings - Structure - Subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndRegion

#Region Private

// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.
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
	Item.PredefinedDataName = "Counterparties";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef._DemoCounterparties"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("ru = 'Контрагенты';
								|en = 'Counterparties';", Common.DefaultLanguageCode());
	Item.Code = "000000001";
	
	Item = Items.Add();
	Item.PredefinedDataName = "Products";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef._DemoProducts"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("ru = 'Номенклатура';
								|en = 'Product';", Common.DefaultLanguageCode());
	Item.Code = "000000002";
	
	Item = Items.Add();
	Item.PredefinedDataName = "Warehouses";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef._DemoStorageLocations"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("ru = 'Склады';
								|en = 'Warehouses';", Common.DefaultLanguageCode());
	Item.Code = "000000003";
	
	Item = Items.Add();
	Item.PredefinedDataName = "VATRates";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef._DemoVATRates"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("ru = 'Ставки НДС';
								|en = 'VAT rates';", Common.DefaultLanguageCode());
	Item.Code = "000000004";
	
	Item = Items.Add();
	Item.PredefinedDataName = "ProductRangeGroups";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef._DemoProductsKinds"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("ru = 'Номенклатурные группы';
								|en = 'Product groups';", Common.DefaultLanguageCode());
	Item.Code = "000000005";
	
	Item = Items.Add();
	Item.PredefinedDataName = "PaymentsToBudgetTypes";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef._DemoBudgetPaymentKinds"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("ru = 'Виды платежей в бюджет';
								|en = 'Types of payments to budget';", Common.DefaultLanguageCode());
	Item.Code = "000000006";
	
	Item = Items.Add();
	Item.PredefinedDataName = "Contracts";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef._DemoCounterpartiesContracts"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("ru = 'Договоры';
								|en = 'Contracts';", Common.DefaultLanguageCode());
	Item.Code = "000000007";
	
EndProcedure

#EndRegion


#EndIf