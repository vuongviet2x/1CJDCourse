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

// StandardSubsystems.ObjectAttributesLock

// Returns:
//   See ObjectAttributesLockOverridable.OnDefineLockedAttributes.LockedAttributes.
//
Function GetObjectAttributesToLock() Export
	
	AttributesToLock = New Array;
	
	Attribute = ObjectAttributesLock.NewAttributeToLock();
	Attribute.Group = "CommonLabel";
	Attribute.GroupPresentation = NStr("ru = 'Пример измененной общей надписи формы';
										|en = 'An example of a modified shared form label';"); // If the string is empty, the text is removed.
	AttributesToLock.Add(Attribute);
	
	Attribute = ObjectAttributesLock.NewAttributeToLock();
	Attribute.Name = "Code";
	Attribute.Warning =
		NStr("ru = 'Пример предупреждения для поля Код';
			|en = 'A warning example for the Code field';");
	AttributesToLock.Add(Attribute);
	
	AttributesToLock.Add("Parent");
	
	Attribute = ObjectAttributesLock.NewAttributeToLock();
	Attribute.Group = "AccountSettings";
	Attribute.GroupPresentation = NStr("ru = 'Настройки счета (пример заголовка группы)';
										|en = 'Account settings (a group title example)';");
	Attribute.Warning =
		NStr("ru = 'Настройки счета не рекомендуется изменять, если счет уже используются
		           |(пример предупреждения отображаемого для группы и реквизитов группы)';
					|en = 'We do not recommend you to change the account settings if the account is already used
					|(a warning example for a group and group attributes)';");
	AttributesToLock.Add(Attribute);
	
	AttributesToLock.Add("Kind;;AccountSettings");
	AttributesToLock.Add("OffBalance;;AccountSettings");
	AttributesToLock.Add("Currency1;;AccountSettings");
	AttributesToLock.Add("Quantitative;;AccountSettings");
	
	AttributesToLock.Add("ExtDimensionTypes");
	
	Return AttributesToLock;
	
EndFunction

// End StandardSubsystems.ObjectAttributesLock

#EndRegion

#EndRegion

#Region Internal

// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.
// 
// Parameters:
//  Settings - See InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.Settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
EndProcedure

// See also InfobaseUpdateOverridable.OnInitialItemsFilling
// 
// Parameters:
//   LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//   Items - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//   TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	Item = Items.Add(); // ChartOfAccountsObject._DemoMain
	Item.PredefinedDataName = "Auxiliary";
	Item.Order = "00";
	Item.OffBalance = False;
	Item.Description = NStr("ru = 'Вспомогательный';
								|en = 'Auxiliary';");
	Item.Code = "00";
	Item.Type = AccountType.ActivePassive;

	Item = Items.Add(); // ChartOfAccountsObject._DemoMain
	Item.PredefinedDataName = "VATOnPurchasedCommodities";
	Item.Order = "19";
	Item.OffBalance = False;
	Item.Description = NStr("ru = 'НДС по приобретенным ценностям';
								|en = 'VAT on purchased assets';");
	Item.Code = "19";
	Item.Type = AccountType.Active;

	Item = Items.Add(); // ChartOfAccountsObject._DemoMain
	Item.PredefinedDataName = "VATOnPurchasedInventory";
	Item.Order = "19.03";
	Item.OffBalance = False;
	Item.Description = NStr("ru = 'НДС по приобретенным материально-производственным запасам';
								|en = 'VAT on purchased inventory';");
	Item.Code = "19.03";
	Item.Parent = ChartsOfAccounts._DemoMain.VATOnPurchasedCommodities;
	Item.Type = AccountType.Active;

	Item = Items.Add(); // ChartOfAccountsObject._DemoMain
	Item.PredefinedDataName = "Goods";
	Item.Order = "41";
	Item.OffBalance = False;
	Item.Description = NStr("ru = 'Товары';
								|en = 'Goods';");
	Item.Code = "41";
	Item.Type = AccountType.Active;

	Item = Items.Add(); // ChartOfAccountsObject._DemoMain
	Item.PredefinedDataName = "ProductStock";
	Item.Order = "41.01";
	Item.OffBalance = False;
	Item.Description = NStr("ru = 'Товары на складах';
								|en = 'Goods in warehouses';");
	Item.Code = "41.01";
	Item.Parent = ChartsOfAccounts._DemoMain.Goods;
	Item.Type = AccountType.Active;

	Item = Items.Add(); // ChartOfAccountsObject._DemoMain
	Item.PredefinedDataName = "SettlementsWithSuppliersAndContractors";
	Item.Order = "60";
	Item.OffBalance = False;
	Item.Description = NStr("ru = 'Расчеты с поставщиками и подрядчиками';
								|en = 'Settlements with vendors and contractors';");
	Item.Code = "60";
	Item.Type = AccountType.ActivePassive;

	Item = Items.Add(); // ChartOfAccountsObject._DemoMain
	Item.PredefinedDataName = "VendorsARAPAccounting";
	Item.Order = "60.01";
	Item.OffBalance = False;
	Item.Description = NStr("ru = 'Расчеты с поставщиками и подрядчиками';
								|en = 'Settlements with vendors and contractors';");
	Item.Code = "60.01";
	Item.Parent = ChartsOfAccounts._DemoMain.SettlementsWithSuppliersAndContractors;
	Item.Type = AccountType.Passive;

	Item = Items.Add(); // ChartOfAccountsObject._DemoMain
	Item.PredefinedDataName = "SettlementsWithSuppliersCurr";
	Item.Order = "60.21";
	Item.OffBalance = False;
	Item.Description = NStr("ru = 'Расчеты с поставщиками и подрядчиками (в валюте)';
								|en = 'Settlements with vendors and contractors (in foreign currency)';");
	Item.Code = "60.21";
	Item.Parent = ChartsOfAccounts._DemoMain.SettlementsWithSuppliersAndContractors;
	Item.Type = AccountType.Passive;

	Item = Items.Add(); // ChartOfAccountsObject._DemoMain
	Item.PredefinedDataName = "SettlementsWithCustomersAndClients";
	Item.Order = "62";
	Item.OffBalance = False;
	Item.Description = NStr("ru = 'Расчеты с покупателями и заказчиками';
								|en = 'Settlements with customers';");
	Item.Code = "62";
	Item.Type = AccountType.ActivePassive;

	Item = Items.Add(); // ChartOfAccountsObject._DemoMain
	Item.PredefinedDataName = "SettlementsWithCustomers";
	Item.Order = "62.01";
	Item.OffBalance = False;
	Item.Description = NStr("ru = 'Расчеты с покупателями';
								|en = 'Settlements with customers';");
	Item.Code = "62.01";
	Item.Parent = ChartsOfAccounts._DemoMain.SettlementsWithCustomersAndClients;
	Item.Type = AccountType.Active;

	Item = Items.Add(); // ChartOfAccountsObject._DemoMain
	Item.PredefinedDataName = "SettlementsWithCustomersCurr";
	Item.Order = "62.21";
	Item.OffBalance = False;
	Item.Description = NStr("ru = 'Расчеты с покупателями и заказчиками (в валюте)';
								|en = 'Settlements with customers (in foreign currency)';");
	Item.Code = "62.21";
	Item.Parent = ChartsOfAccounts._DemoMain.SettlementsWithCustomersAndClients;
	Item.Type = AccountType.Active;

	Item = Items.Add(); // ChartOfAccountsObject._DemoMain
	Item.PredefinedDataName = "FiscalSettlements";
	Item.Order = "68";
	Item.OffBalance = False;
	Item.Description = NStr("ru = 'Расчеты по налогам и сборам';
								|en = 'Settlements for taxes and fees';");
	Item.Code = "68";
	Item.Type = AccountType.ActivePassive;

	Item = Items.Add(); // ChartOfAccountsObject._DemoMain
	Item.PredefinedDataName = "VAT";
	Item.Order = "68.02";
	Item.OffBalance = False;
	Item.Description = NStr("ru = 'Налог на добавленную стоимость';
								|en = 'VAT';");
	Item.Code = "68.02";
	Item.Parent = ChartsOfAccounts._DemoMain.FiscalSettlements;
	Item.Type = AccountType.ActivePassive;

	Item = Items.Add(); // ChartOfAccountsObject._DemoMain
	Item.PredefinedDataName = "Sales";
	Item.Order = "90";
	Item.OffBalance = False;
	Item.Description = NStr("ru = 'Продажи';
								|en = 'Sales';");
	Item.Code = "90";
	Item.Type = AccountType.ActivePassive;

	Item = Items.Add(); // ChartOfAccountsObject._DemoMain
	Item.PredefinedDataName = "Revenue";
	Item.Order = "90.01";
	Item.OffBalance = False;
	Item.Description = NStr("ru = 'Выручка';
								|en = 'Revenue';");
	Item.Code = "90.01";
	Item.Parent = ChartsOfAccounts._DemoMain.Sales;
	Item.Type = AccountType.Passive;

	Item = Items.Add(); // ChartOfAccountsObject._DemoMain
	Item.PredefinedDataName = "SaleCost";
	Item.Order = "90.02";
	Item.OffBalance = False;
	Item.Description = NStr("ru = 'Себестоимость продаж';
								|en = 'Cost of goods sold';");
	Item.Code = "90.02";
	Item.Parent = ChartsOfAccounts._DemoMain.Sales;
	Item.Type = AccountType.Active;

	Item = Items.Add(); // ChartOfAccountsObject._DemoMain
	Item.PredefinedDataName = "Sales_VAT";
	Item.Order = "90.03";
	Item.OffBalance = False;
	Item.Description = NStr("ru = 'Продажи НДС';
								|en = 'VAT sales';");
	Item.Code = "90.03";
	Item.Parent = ChartsOfAccounts._DemoMain.Sales;
	Item.Type = AccountType.Active;
	
EndProcedure

// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.
//
// Parameters:
//  Object                  - ChartOfAccountsObject._DemoMain - Object to populate.
//  Data                  - ValueTableRow - Object fill data.
//  AdditionalParameters - Structure:
//   * PredefinedData - ValueTable - Data populated in the OnInitialItemsFilling procedure.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	
EndProcedure

#EndRegion

#EndIf
