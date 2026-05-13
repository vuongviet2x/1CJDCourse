///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Private

// See PropertyManagerOverridable.FillObjectPropertiesSets
Procedure FillObjectPropertiesSets(Object, RefType, PropertiesSets, StandardProcessing, AssignmentKey) Export
	
	If RefType = Type("CatalogRef._DemoPartners") Then
		FillPartnerPropertiesSets(Object, RefType, PropertiesSets);
		
	ElsIf RefType = Type("CatalogRef._DemoProducts") Then
		FillPropertiesSetByProductKind(Object, RefType, PropertiesSets);
		
	ElsIf RefType = Type("CatalogRef._DemoCounterparties") Then
		
		FillCounterpartiesPropertiesSet(Object, RefType, PropertiesSets);
	EndIf;
	
EndProcedure

// See PropertyManagerOverridable.OnGetPredefinedPropertiesSets
Procedure OnGetPredefinedPropertiesSets(Sets) Export
	
	// Demo: Counterparties catalog sets.
	Set = Sets.Rows.Add();
	Set.Name = "Catalog__DemoCounterparties";
	Set.IsFolder = True;
	Set.Id = New UUID("3001280c-f6ec-4fa9-bc4a-5eee8f177b60");
	
	ChildSet = Set.Rows.Add();
	ChildSet.Name = "Catalog_DemoCounterpartiesMain";
	ChildSet.Id = New UUID("766448ee-5143-4c28-820d-1d272302ab61");
	
	ChildSet = Set.Rows.Add();
	ChildSet.Name = "Catalog_DemoCounterpartiesOther";
	ChildSet.Id = New UUID("3b4e0dcd-b7a6-4257-bc69-5118e7fb47e0");
	
	Set = Sets.Rows.Add();
	Set.Name = "Catalog__DemoCompanies";
	Set.Id = New UUID("a4632c5e-a6c9-4141-83bc-be8e77ff1690");
	
EndProcedure

// See PropertyManagerOverridable.OnGetPropertiesSetsDescriptions.
Procedure OnGetPropertiesSetsDescriptions(Descriptions, LanguageCode) Export
	
	Descriptions["Catalog_DemoCounterpartiesMain"] = NStr("ru = 'Основное';
																|en = 'Main';", LanguageCode);
	Descriptions["Catalog_DemoCounterpartiesOther"]   = NStr("ru = 'Прочее';
																|en = 'Other';", LanguageCode);
EndProcedure

// See PropertyManagerOverridable.OnInitialItemsFilling
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	// Demo: Partners catalog sets.
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog__DemoPartners";
	Set.IsFolder = True;
	Set.Used = True;
	Set.Ref = New UUID("2c8d6c08-1d35-43ce-a690-32ccf53b03f2");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
			"ru = 'Демо: Партнеры';
			|en = 'Demo: Partners';", LanguagesCodes); // @NStr-1
	
	ChildSet = Items.Add();
	ChildSet.Parent = New UUID("2c8d6c08-1d35-43ce-a690-32ccf53b03f2");
	ChildSet.PredefinedSetName = "Catalog_Partners_Clients";
	ChildSet.Used = True;
	ChildSet.Ref = New UUID("277e1f06-e4f6-4c23-8d31-0d4347e207a2");
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildSet, "Description",
		"ru = 'Клиент';
		|en = 'Client';", LanguagesCodes); // @NStr-1
	
	ChildSet = Items.Add();
	ChildSet.Parent = New UUID("2c8d6c08-1d35-43ce-a690-32ccf53b03f2");
	ChildSet.PredefinedSetName = "Catalog_Partners_Competitors";
	ChildSet.Used = True;
	ChildSet.Ref = New UUID("0bf6c2ff-000e-44ff-aae3-a41c7f9cb33a");
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildSet, "Description",
		"ru = 'Конкурент';
		|en = 'Competitor';", LanguagesCodes); // @NStr-1
	
	ChildSet = Items.Add();
	ChildSet.Parent = New UUID("2c8d6c08-1d35-43ce-a690-32ccf53b03f2");
	ChildSet.PredefinedSetName = "Catalog_Partners_General";
	ChildSet.Used = True;
	ChildSet.Ref = New UUID("b6f8b9f2-087d-4429-9f19-25f1df5498f7");
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildSet, "Description",
		"ru = 'Общие';
		|en = 'Common';", LanguagesCodes); // @NStr-1
	
	ChildSet = Items.Add();
	ChildSet.Parent = New UUID("2c8d6c08-1d35-43ce-a690-32ccf53b03f2");
	ChildSet.PredefinedSetName = "Catalog_Partners_Suppliers";
	ChildSet.Used = True;
	ChildSet.Ref = New UUID("d225a089-e318-494d-bdd8-d6a5c63cde23");
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildSet, "Description",
		"ru = 'Поставщик';
		|en = 'Supplier';", LanguagesCodes); // @NStr-1
	
	ChildSet = Items.Add();
	ChildSet.Parent = New UUID("2c8d6c08-1d35-43ce-a690-32ccf53b03f2");
	ChildSet.PredefinedSetName = "Catalog_Partners_Other";
	ChildSet.Used = True;
	ChildSet.Ref = New UUID("d63aa128-926f-4e94-b3ad-d4e0f07d3d39");
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildSet, "Description",
		"ru = 'Прочее';
		|en = 'Other';", LanguagesCodes); // @NStr-1
	
	// Demo: Products catalog sets.
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog__DemoProducts";
	Set.IsFolder = True;
	Set.Used = True;
	Set.Ref = New UUID("c7cd91d8-6f8a-4d10-82bf-c6fba8475a98");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"ru = 'Демо: Номенклатура';
		|en = 'Demo: Products';", LanguagesCodes); // @NStr-1
	
	ChildSet = Items.Add();
	ChildSet.Parent = New UUID("c7cd91d8-6f8a-4d10-82bf-c6fba8475a98");
	ChildSet.PredefinedSetName = "Catalog___Products_General";
	ChildSet.Used = True;
	ChildSet.Ref = New UUID("9265848a-53cc-470a-8778-20995e98f1ae");
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildSet, "Description",
		"ru = 'Общие';
		|en = 'Common';", LanguagesCodes); // @NStr-1
	
	// Demo: Customer proforma invoices document sets.
	Set = Items.Add();
	Set.PredefinedSetName = "Document__DemoCustomerProformaInvoice";
	Set.Used = True;
	Set.Ref = New UUID("aa635963-6b4d-4635-845d-100100ca2d4a");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"ru = 'Демо: Счета на оплату покупателям';
		|en = 'Demo: Sales proforma invoices';", LanguagesCodes); // @NStr-1
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions.

// Gets partner property sets by selected check boxes.
// 
Procedure FillPartnerPropertiesSets(Object, RefType, PropertiesSets)
	
	If TypeOf(Object) = RefType Then
		Partner = Common.ObjectAttributesValues(
			Object, "Client, Competitor, Vendor, OtherRelations, IsFolder");
	Else
		Partner = Object;
	EndIf;
	
	If Partner.IsFolder = False Then
		
		String = PropertiesSets.Add();
		String.Set = PropertyManager.PropertiesSetByName("Catalog_Partners_General");
		String.Representation = UsualGroupRepresentation.WeakSeparation;
		String.ShowTitle = True;
		String.SharedSet = True;
		String.Title  = NStr("ru = 'Для всех партнеров';
								|en = 'For all partners';");
		
		If Partner.Client Then
			String = PropertiesSets.Add();
			String.Set = PropertyManager.PropertiesSetByName("Catalog_Partners_Clients");
			String.Representation = UsualGroupRepresentation.WeakSeparation;
			String.Title = NStr("ru = 'Для клиентов';
									|en = 'For customers';");
			String.ShowTitle = True;
		EndIf;
		
		If Partner.Competitor Then
			String = PropertiesSets.Add();
			String.Set = PropertyManager.PropertiesSetByName("Catalog_Partners_Competitors");
			String.Representation = UsualGroupRepresentation.WeakSeparation;
			String.ShowTitle = True;
			String.Title = NStr("ru = 'Для конкурентов';
									|en = 'For competitors';");
		EndIf;
		
		If Partner.Vendor Then
			String = PropertiesSets.Add();
			String.Set = PropertyManager.PropertiesSetByName("Catalog_Partners_Suppliers");
			String.Representation = UsualGroupRepresentation.WeakSeparation;
			String.ShowTitle = True;
			String.Title = NStr("ru = 'Для поставщиков';
									|en = 'For vendors';");
		EndIf;
		
		If Partner.OtherRelations Then
			String = PropertiesSets.Add();
			String.Set = PropertyManager.PropertiesSetByName("Catalog_Partners_Other");
			String.Representation = UsualGroupRepresentation.WeakSeparation;
			String.ShowTitle = True;
			String.Title = NStr("ru = 'Для прочих';
									|en = 'For other';");
		EndIf;
		
		// Properties of deleted attribute group.
		String = PropertiesSets.Add();
		String.Set = Catalogs.AdditionalAttributesAndInfoSets.EmptyRef();
		String.Representation = UsualGroupRepresentation.WeakSeparation;
		String.ShowTitle = True;
		String.Title = NStr("ru = 'Более неиспользуемые реквизиты';
								|en = 'Attributes no longer in use';");
	EndIf;
	
EndProcedure

// Gets an object property set by a product kind.
Procedure FillPropertiesSetByProductKind(Object, RefType, PropertiesSets)
	
	String = PropertiesSets.Add();
	String.Set = PropertyManager.PropertiesSetByName("Catalog___Products_General");
	String.SharedSet = True;
	
	If TypeOf(Object) = RefType Then
		Products = Common.ObjectAttributesValues(
			Object, "IsFolder, ProductKind");
	Else
		Products = Object;
	EndIf;
	
	If Products.IsFolder = False Then
		String = PropertiesSets.Add();
		String.Set = Common.ObjectAttributeValue(
			Products.ProductKind, "PropertiesSet");
	EndIf;
	
EndProcedure

Procedure FillCounterpartiesPropertiesSet(Object, RefType, PropertiesSets)
	
	String = PropertiesSets.Add();
	String.Set = PropertyManager.PropertiesSetByName("Catalog_DemoCounterpartiesMain");
	
	String = PropertiesSets.Add();
	String.Set = PropertyManager.PropertiesSetByName("Catalog_DemoCounterpartiesOther");
	
EndProcedure

#EndRegion