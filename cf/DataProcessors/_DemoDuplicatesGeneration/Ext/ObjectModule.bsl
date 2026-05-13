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

#Region Internal

Function DefaultSettings() Export
	Result = New Structure;
	
	Result.Insert("CheckFilling", False);
	
	Result.Insert("SimpleDuplicatesUsage", True);
	Result.Insert("SimpleDuplicatesCount", 10);
	Result.Insert("SimpleDuplicatesPrefix", NStr("ru = 'Тест поиска дублей %1';
													|en = 'Duplicate search text %1';"));
	
	Result.Insert("InformationRegistersUsage", True);
	Result.Insert("InformationRegistersCount", 1);
	Result.Insert("InformationRegistersPrefix", NStr("ru = 'Дубли в регистрах сведений %1';
														|en = 'Duplicates in information registers %1';"));
	
	Result.Insert("AccumulationRegistersUsage", True);
	Result.Insert("AccumulationRegistersCount", 1);
	Result.Insert("AccumulationRegistersPrefix", NStr("ru = 'Дубли в регистрах накопления %1';
														|en = 'Duplicates in accumulation registers %1';"));
	
	Return Result;
EndFunction

Function Generate(SettingsCollection) Export
	Settings = DefaultSettings();
	If SettingsCollection <> Undefined Then
		FillPropertyValues(Settings, SettingsCollection);
	EndIf;
	
	Result = Result();
	CreatedObjects = Result.CreatedObjects;
	
	CheckBoxBeforeStart = Constants.UsePeriodClosingDates.Get();
	Constants.UsePeriodClosingDates.Set(False);
	RefreshReusableValues();
	
	BeginTransaction();
	Try
		
		If Settings.SimpleDuplicatesUsage Then
			GenerateSimpleDuplicates(Settings, Result);
		EndIf;
		
		If Settings.InformationRegistersUsage Then
			CreateRecordsInInformationRegisterExchangeRates(Settings, Result);
			CreateRecordsIn_DemoStorageLocationsInformationRegister(Settings, Result);
			CreateRecordsInInformationRegisterCompaniesEmployees(Settings, Result);
		EndIf;
		
		If Settings.AccumulationRegistersUsage Then
			CreateDuplicatesUsedInAccumulationRegisters(Settings, Result);
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		Constants.UsePeriodClosingDates.Set(CheckBoxBeforeStart);
		RefreshReusableValues();
		
		Raise;
		
	EndTry;
	
	Constants.UsePeriodClosingDates.Set(CheckBoxBeforeStart);
	RefreshReusableValues();
	
	// Set random deletion marks.
	ItemsToMarkForDeletion = CreatedObjects.FindRows(New Structure("Check", True));
	
	LeftToMark = ItemsToMarkForDeletion.Count();
	RNG = New RandomNumberGenerator;
	While LeftToMark > 0 Do
		LeftToMark = LeftToMark - 1;
		IndexOf = RNG.RandomNumber(0, LeftToMark);
		ItemsToMarkForDeletion[IndexOf].Ref.GetObject().SetDeletionMark(True);
		ItemsToMarkForDeletion.Delete(IndexOf);
	EndDo;
	
	// Set random deletion marks.
	ObjectsToUnmark = CreatedObjects.FindRows(New Structure("Check, Referential", False, True));
	
	LeftToUnmark = ObjectsToUnmark.Count();
	While LeftToUnmark > 0 Do
		LeftToUnmark = LeftToUnmark - 1;
		IndexOf = RNG.RandomNumber(0, LeftToUnmark);
		ObjectsToUnmark[IndexOf].Ref.GetObject().SetDeletionMark(False);
		ObjectsToUnmark.Delete(IndexOf);
	EndDo;
	
	Return Result;
EndFunction

#EndRegion

#Region Private

// Returns:
//  Structure:
//   * DuplicatesTypes - Array
//   * CreatedObjects - ValueTable
//
Function Result()
	CreatedObjects = New ValueTable;
	CreatedObjects.Columns.Add("Scenario", New TypeDescription("String"));
	CreatedObjects.Columns.Add("Type", New TypeDescription("Type"));
	CreatedObjects.Columns.Add("Ref");
	CreatedObjects.Columns.Add("Check", New TypeDescription("Boolean"));
	CreatedObjects.Columns.Add("Kind", New TypeDescription("String"));
	CreatedObjects.Columns.Add("Referential", New TypeDescription("Boolean"));
	CreatedObjects.Columns.Add("IsDuplicate", New TypeDescription("Boolean"));
	CreatedObjects.Columns.Add("Original");
	
	Result = New Structure;
	Result.Insert("CreatedObjects", CreatedObjects);
	Result.Insert("DuplicatesTypes", New Array);
	
	Return Result;
EndFunction

// CAC:1328-off a shared lock for readable data is not required for these texts.

Procedure GenerateSimpleDuplicates(Settings, Result)
	Scenario = "SimpleDuplicates";
	
	CatalogManager = Catalogs._DemoProducts;
	DescriptionTemplate = Settings.SimpleDuplicatesPrefix;
	
	DescriptionTemplateForQuery = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, "%");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	_DemoProducts.Ref,
	|	_DemoProducts.Description,
	|	_DemoProducts.SKU
	|FROM
	|	Catalog._DemoProducts AS _DemoProducts
	|WHERE
	|	_DemoProducts.Description LIKE &DescriptionTemplate ESCAPE ""~""";
	Query.SetParameter("DescriptionTemplate", Common.GenerateSearchQueryString(DescriptionTemplateForQuery));
	
	AlreadyGeneratedObjects = Query.Execute().Unload();
	
	For ItemNumber = 1 To Settings.SimpleDuplicatesCount Do
		Description = StringFunctionsClientServer.SubstituteParametersToString(
			DescriptionTemplate,
			Format(ItemNumber, "NG="));
		
		FoundItems = AlreadyGeneratedObjects.FindRows(New Structure("Description, SKU", Description, "Original"));
		If FoundItems.Count() = 0 Then
			OriginalObject = CatalogManager.CreateItem();
			OriginalObject.Description = Description;
			OriginalObject.SKU = "Original";
			OriginalObject.Write();
			OriginalRef = OriginalObject.Ref;
		Else
			OriginalRef = FoundItems[0].Ref;
		EndIf;
		Register(Result, Scenario, OriginalRef, False);
		
		FoundItems = AlreadyGeneratedObjects.FindRows(New Structure("Description, SKU", Description, "Duplicate1"));
		If FoundItems.Count() = 0 Then
			DuplicateObject = CatalogManager.CreateItem();
			DuplicateObject.Description = Description;
			DuplicateObject.SKU = "Duplicate1";
			DuplicateObject.Write();
			DuplicateRef = DuplicateObject.Ref;
		Else
			DuplicateRef = FoundItems[0].Ref;
		EndIf;
		Register(Result, Scenario, DuplicateRef, False);
	EndDo;
	
EndProcedure

Procedure CreateRecordsInInformationRegisterExchangeRates(Settings, Result)
	
	// Test the ExchangeRates register for a search exception in leading dimensions.
	Scenario = "MasterDimensionsInInformationRegisters";
	
	DescriptionTemplate = NStr("ru = 'Валюта %1';
								|en = 'Currency %1';");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Currencies.Ref,
	|	Currencies.Description,
	|	Currencies.Code
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.Description LIKE &DescriptionTemplate ESCAPE ""~""";
	DescriptionTemplateForQuery = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, "%");
	Query.SetParameter("DescriptionTemplate", Common.GenerateSearchQueryString(DescriptionTemplateForQuery));
	AlreadyGeneratedObjects = Query.Execute().Unload(); 
	
	For ItemNumber = 1 To Settings.InformationRegistersCount Do
		Description = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, Format(ItemNumber, "NG="));
		
		Code = "About" + String(ItemNumber);
		FoundItems = AlreadyGeneratedObjects.FindRows(New Structure("Description, Code", Description, Code));
		If FoundItems.Count() = 0 Then
			OriginalObject = Catalogs.Currencies.CreateItem();
			OriginalObject.Code = Code;
			OriginalObject.Description = Description;
			OriginalObject.DescriptionFull = Description;
			OriginalObject.RateSource = Enums.RateSources.ManualInput;
			WriteObject(Settings, OriginalObject);
			Original = OriginalObject.Ref;
		Else
			Original = FoundItems[0].Ref;
		EndIf;
		Register(Result, Scenario, Original, True);
		
		Code = "D" + String(ItemNumber);
		FoundItems = AlreadyGeneratedObjects.FindRows(New Structure("Description, Code", Description, Code));
		If FoundItems.Count() = 0 Then
			DuplicateObject = Catalogs.Currencies.CreateItem();
			DuplicateObject.Code = Code;
			DuplicateObject.Description = Description;
			DuplicateObject.DescriptionFull = Description;
			DuplicateObject.RateSource = Enums.RateSources.ManualInput;
			WriteObject(Settings, DuplicateObject);
			Duplicate1 = DuplicateObject.Ref;
		Else
			Duplicate1 = FoundItems[0].Ref;
		EndIf;
		Register(Result, Scenario, Duplicate1, True, Original);
		
		Set1 = InformationRegisters.ExchangeRates.CreateRecordSet();
		Set1.Filter.Currency.Set(Original);
		
		Record1 = Set1.Add();
		Record1.Period = Date(2001, 01, 01);
		Record1.Currency = Original;
		Record1.Rate   = 10;
		
		Set2 = InformationRegisters.ExchangeRates.CreateRecordSet();
		Set2.Filter.Currency.Set(Duplicate1);
		
		Record2 = Set2.Add();
		Record2.Period = Date(2001, 01, 01);
		Record2.Currency = Duplicate1;
		Record2.Rate   = 20;
		
		Record2 = Set2.Add();
		Record2.Period = Date(2014, 01, 01);
		Record2.Currency = Duplicate1;
		Record2.Rate   = 80;
		
		Set1.Write(True);
		Set2.Write(True);
	EndDo;
	
EndProcedure

Procedure CreateRecordsInInformationRegisterCompaniesEmployees(Settings, Result)
	// Test register _DemoCompaniesEmployees for ref search exception.
	Scenario = "ReferenceReplacementInInformationRegisters";
	
	CompanyDescriptionTemplate = NStr("ru = 'Организация %1 (тест дублей)';
										|en = 'Company %1 (duplicate test)';");
	
	// Dimensions as directives.
	RecordsOptions = New Array;
	RecordsOptions.Add(New Structure("CreateOriginal, CreateDuplicate", True, False));
	RecordsOptions.Add(New Structure("CreateOriginal, CreateDuplicate", False, True));
	RecordsOptions.Add(New Structure("CreateOriginal, CreateDuplicate", True, True));
	
	// Resource CompanyDepartment requires two unique references.
	DepartmentsRefs = New Array;
	DescriptionTemplate = NStr("ru = 'Ресурс %1 (тест дублей)';
								|en = 'Resource %1 (duplicate test)';");
	For ItemNumber = 1 To 5 Do
		Description = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, Format(ItemNumber, "NG="));
		Department = Catalogs._DemoDepartments.FindByDescription(Description);
		If Not ValueIsFilled(Department) Then
			CatalogObject = Catalogs._DemoDepartments.CreateItem();
			CatalogObject.Description = Description;
			WriteObject(Settings, CatalogObject);
			Department = CatalogObject.Ref;
		EndIf;
		DepartmentsRefs.Add(Department);
		Register(Result, Scenario, Department, True);
	EndDo;
	
	// Resources are more specific as references.
	OptionsByDepartments = New Array;
	OptionsByDepartments.Add(New Structure("Original, Duplicate1", Undefined, DepartmentsRefs[0]));
	OptionsByDepartments.Add(New Structure("Original, Duplicate1", DepartmentsRefs[1], Undefined));
	OptionsByDepartments.Add(New Structure("Original, Duplicate1", DepartmentsRefs[2], DepartmentsRefs[2]));
	OptionsByDepartments.Add(New Structure("Original, Duplicate1", DepartmentsRefs[3], DepartmentsRefs[4]));
	
	OptionsByRates = New Array;
	OptionsByRates.Add(New Structure("Original, Duplicate1", 0, 1));
	OptionsByRates.Add(New Structure("Original, Duplicate1", 2, 0));
	OptionsByRates.Add(New Structure("Original, Duplicate1", 3, 3));
	OptionsByRates.Add(New Structure("Original, Duplicate1", 4, 5));
	
	OptionsByNumbers = New Array;
	OptionsByNumbers.Add(New Structure("Original, Duplicate1", "", "A"));
	OptionsByNumbers.Add(New Structure("Original, Duplicate1", "B", ""));
	OptionsByNumbers.Add(New Structure("Original, Duplicate1", "In", "In"));
	OptionsByNumbers.Add(New Structure("Original, Duplicate1", "G", "D"));
	
	DescriptionTemplate = Settings.InformationRegistersPrefix;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	_DemoIndividuals.Ref,
	|	_DemoIndividuals.Description,
	|	_DemoIndividuals.WhoIssuedDocument
	|FROM
	|	Catalog._DemoIndividuals AS _DemoIndividuals
	|WHERE
	|	_DemoIndividuals.Description LIKE &DescriptionTemplate ESCAPE ""~""";
	DescriptionTemplateForQuery = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, "%");
	Query.SetParameter("DescriptionTemplate", Common.GenerateSearchQueryString(DescriptionTemplateForQuery));
	AlreadyGeneratedObjects = Query.Execute().Unload();
	
	For ItemNumber = 1 To Settings.InformationRegistersCount Do
		Description = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, Format(ItemNumber, "NG="));
		
		FoundItems = AlreadyGeneratedObjects.FindRows(New Structure("Description, WhoIssuedDocument", Description, "Original"));
		If FoundItems.Count() = 0 Then
			CatalogObject = Catalogs._DemoIndividuals.CreateItem();
			CatalogObject.Description = Description;
			CatalogObject.WhoIssuedDocument = "Original";
			WriteObject(Settings, CatalogObject);
			Original = CatalogObject.Ref;
		Else
			Original = FoundItems[0].Ref;
		EndIf;
		Register(Result, Scenario, Original, True);
		
		FoundItems = AlreadyGeneratedObjects.FindRows(New Structure("Description, WhoIssuedDocument", Description, "Duplicate1"));
		If FoundItems.Count() = 0 Then
			CatalogObject = Catalogs._DemoIndividuals.CreateItem();
			CatalogObject.Description = Description;
			CatalogObject.WhoIssuedDocument = "Duplicate1";
			WriteObject(Settings, CatalogObject, , False);
			Duplicate1 = CatalogObject.Ref;
		Else
			Duplicate1 = FoundItems[0].Ref;
		EndIf;
		Register(Result, Scenario, Duplicate1, True, Original);
		
		Set1 = InformationRegisters._DemoCompaniesEmployees.CreateRecordSet();
		Set1.Filter.Individual.Set(Original);
		Set2 = InformationRegisters._DemoCompaniesEmployees.CreateRecordSet();
		Set2.Filter.Individual.Set(Duplicate1);
		
		Period = BegOfYear(CurrentSessionDate());
		
		//   - There are three options for dimension overlapping:
		//       - There's a record of the duplicate, and there's no record of the original item.
		//       - There's a record of the original item, and there's no record of the duplicate.
		//       - Both records are present.
		OptionNumber = 0;
		For Each RecordSetting In RecordsOptions Do
			For Each DepartmentSetting In OptionsByDepartments Do
				For Each RateSetting In OptionsByRates Do
					For Each NumberSetting In OptionsByNumbers Do
						OptionNumber = OptionNumber + 1;
						
						// A reference for the Company dimension.
						Description = StringFunctionsClientServer.SubstituteParametersToString(CompanyDescriptionTemplate, Format(ItemNumber*OptionNumber, "NG="));
						Organization = Catalogs._DemoCompanies.FindByDescription(Description);
						If Not ValueIsFilled(Organization) Then
							CatalogObject = Catalogs._DemoCompanies.CreateItem();
							CatalogObject.Description            = Description;
							CatalogObject.AbbreviatedDescription = Description;
							Address = CatalogObject.ContactInformation.Add();
							Address.Type = Enums.ContactInformationTypes.Address;
							Address.Kind = ContactsManager.ContactInformationKindByName("_DemoCompanyLegalAddress");
							Address.FieldValues = ContactsManager.ContactsByPresentation(NStr("ru = 'г.Москва, Дмитровское шоссе, д.9';
																															|en = 'Moscow, Dmitrovskoye Highway, 9';"), Address.Kind);
							Address.Presentation = NStr("ru = 'Тестовый Адрес';
														|en = 'Test Address';");
							WriteObject(Settings, CatalogObject);
							Organization = CatalogObject.Ref;
						EndIf;
						Register(Result, Scenario, Organization, True);
						
						If RecordSetting.CreateOriginal Then
							Record1 = Set1.Add();
							Record1.Period         = Period;
							Record1.Active     = True;
							Record1.Organization    = Organization;
							Record1.Individual = Original;
							Record1.Department_Company = DepartmentSetting.Original;
							Record1.OccupiedRates         = RateSetting.Original;
							Record1.EmployeeCode           = NumberSetting.Original;
						EndIf;
						
						If RecordSetting.CreateDuplicate Then
							Record2 = Set2.Add();
							Record2.Period         = Period;
							Record2.Active     = True;
							Record2.Organization    = Organization;
							Record2.Individual = Duplicate1;
							Record2.Department_Company = DepartmentSetting.Duplicate1;
							Record2.OccupiedRates         = RateSetting.Duplicate1;
							Record2.EmployeeCode           = NumberSetting.Duplicate1;
						EndIf;
						
					EndDo;
				EndDo;
			EndDo;
		EndDo;
		
		Set1.Write(True);
		Set2.Write(True);
	EndDo;
	
EndProcedure

Procedure CreateRecordsIn_DemoStorageLocationsInformationRegister(Settings, Result)
	// Test the _DemoStorageLocationsManagers register with a closing date (02/29/2012).
	Scenario = "ReferenceReplacementInInformationRegisters";
	
	// Dimension StorageLocation requires one reference.
	Suffix = " (" + NStr("ru = 'Тест поиска и удаления дублей № 3';
							|en = 'Duplicate cleaner test No. 3';") + ")";
	Description = NStr("ru = 'Склад';
						|en = 'Warehouse';") + Suffix;
	Warehouse = Catalogs._DemoStorageLocations.FindByDescription(Description);
	If Not ValueIsFilled(Warehouse) Then
		CatalogObject = Catalogs._DemoStorageLocations.CreateItem();
		CatalogObject.Description = Description;
		WriteObject(Settings, CatalogObject);
		Warehouse = CatalogObject.Ref;
	EndIf;
	Register(Result, Scenario, Warehouse, True);
	
	DescriptionTemplate = Settings.InformationRegistersPrefix;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Users.Ref,
	|	Users.Description,
	|	Users.Comment
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Description LIKE &DescriptionTemplate ESCAPE ""~""";
	DescriptionTemplateForQuery = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, "%");
	Query.SetParameter("DescriptionTemplate", Common.GenerateSearchQueryString(DescriptionTemplateForQuery));
	AlreadyGeneratedObjects = Query.Execute().Unload();
	
	For ItemNumber = 1 To Settings.InformationRegistersCount Do
		Description = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, Format(ItemNumber, "NG="));
		
		FoundItems = AlreadyGeneratedObjects.FindRows(New Structure("Description, Comment", Description, "Original"));
		If FoundItems.Count() = 0 Then
			OriginalObject = Catalogs.Users.CreateItem();
			OriginalObject.Description = Description;
			OriginalObject.Comment = "Original";
			WriteObject(Settings, OriginalObject);
			Original = OriginalObject.Ref;
		Else
			Original = FoundItems[0].Ref;
		EndIf;
		Register(Result, Scenario, Original, True);
		
		FoundItems = AlreadyGeneratedObjects.FindRows(New Structure("Description, Comment", Description, "Duplicate1"));
		If FoundItems.Count() = 0 Then
			DuplicateObject = Catalogs.Users.CreateItem();
			DuplicateObject.Description = Description;
			DuplicateObject.Comment = "Duplicate1";
			DuplicateObject.Write();
			Duplicate1 = DuplicateObject.Ref;
		Else
			Duplicate1 = FoundItems[0].Ref;
		EndIf;
		Register(Result, Scenario, Duplicate1, True, Original);
		
		Set = InformationRegisters._DemoStorageLocationsManagers.CreateRecordSet();
		Set.Filter.StorageLocation.Set(Warehouse);
		
		Record = Set.Add();
		Record.Period        = Date(2001, 01, 01);
		Record.User  = Original;
		Record.StorageLocation = Warehouse;
		
		Record = Set.Add();
		Record.Period        = Date(2004, 02, 01);
		Record.User  = Duplicate1;
		Record.StorageLocation = Warehouse;
		
		Record = Set.Add();
		Record.Period        = Date(2006, 02, 01);
		Record.User  = Original;
		Record.StorageLocation = Warehouse;
		
		Set.Write(True);
	EndDo;
EndProcedure

Procedure CreateDuplicatesUsedInAccumulationRegisters(Settings, Result)
	// ACCUMULATION REGISTER.
	Scenario = "ReferenceReplacementInAccumulationRegisters";
	
	// Test the following options using the "_DemoGoodsBalancesInStorageLocations" register:
	//   Two dimension types:
	//     * Recorder (DocumentRef._DemoGoodsReceipt).
	//     * Company (CatalogRef._DemoCompanies).
	//     Test 3 types of dimension data overlapping:
	//       - There's a record of the duplicate, and there's no record of the original item.
	//       - There's a record of the original item, and there's no record of the duplicate.
	//       - Both records are present.
	//     However, since "Company" is specified in the header of "_DemoGoodsReceipt", then the "Company" dimension cannot be different for the same recorder.
	//     Therefore, skip testing the "Company" dimension: generate 1 company only.
	//     One resource type:
	//   * Count (Number, 15, 3).
	//     Test 4 dimension filling types:
	//     - FIlled and mismatch.
	//       - Unfilled in the duplicate.
	//       - Unfiled in the original item.
	//       - Couldn't test unfilled options as documents with no products cannot be posted.
	//     In total, 12 options (3^1*4^1).
	// For each option, create a separate instance of the "_DemoGoodsReceipt" document.
	//   
	
	// A reference for the "Company" dimension.
	DescriptionTemplate = NStr("ru = 'Организация %1 (тест дублей)';
								|en = 'Company %1 (duplicate test)';");
	Description = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, Format(1, "NG="));
	Organization = Catalogs._DemoCompanies.FindByDescription(Description);
	If Not ValueIsFilled(Organization) Then
		CatalogObject = Catalogs._DemoCompanies.CreateItem();
		CatalogObject.Description            = Description;
		CatalogObject.AbbreviatedDescription = Description;
		WriteObject(Settings, CatalogObject);
		Organization = CatalogObject.Ref;
	EndIf;
	Register(Result, Scenario, Organization, True);
	
	// Dimension StorageLocation requires one reference.
	DescriptionTemplate = NStr("ru = 'Склад %1 (тест дублей)';
								|en = 'Warehouse %1 (duplicate test)';");
	Description = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, Format(1, "NG="));
	StorageLocation = Catalogs._DemoStorageLocations.FindByDescription(Description);
	If Not ValueIsFilled(StorageLocation) Then
		CatalogObject = Catalogs._DemoStorageLocations.CreateItem();
		CatalogObject.Description = Description;
		WriteObject(Settings, CatalogObject);
		StorageLocation = CatalogObject.Ref;
	EndIf;
	Register(Result, Scenario, StorageLocation, True);
	
	// Document _DemoGoodsReceipt requires one partner.
	DescriptionTemplate = NStr("ru = 'Партнер %1 (тест дублей)';
								|en = 'Partner %1 (duplicate test)';");
	Description = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, Format(1, "NG="));
	Partner = Catalogs._DemoPartners.FindByDescription(Description);
	If Not ValueIsFilled(Partner) Then
		CatalogObject = Catalogs._DemoPartners.CreateItem();
		CatalogObject.Description = Description;
		CatalogObject.PartnerKind = Enums._DemoBusinessEntityIndividual.BusinessEntity;
		WriteObject(Settings, CatalogObject);
		Partner = CatalogObject.Ref;
	EndIf;
	Register(Result, Scenario, Partner, True);
	
	// Document _DemoGoodsReceipt requires one counterparty.
	DescriptionTemplate = NStr("ru = 'Контрагент %1 (тест дублей)';
								|en = 'Counterparty %1 (duplicate test)';");
	Description = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, Format(1, "NG="));
	Counterparty = Catalogs._DemoCounterparties.FindByDescription(Description);
	If Not ValueIsFilled(Counterparty) Then
		CatalogObject = Catalogs._DemoCounterparties.CreateItem();
		CatalogObject.Description = Description;
		CatalogObject.CounterpartyKind = Enums._DemoBusinessEntityIndividual.BusinessEntity;
		WriteObject(Settings, CatalogObject);
		Counterparty = CatalogObject.Ref;
	EndIf;
	Register(Result, Scenario, Counterparty, True);
	
	// A contract requires one currency.
	Currency = Catalogs.Currencies.FindByDescription("RUB");
	If Not ValueIsFilled(Currency) Then
		CatalogObject = Catalogs.Currencies.CreateItem();
		CatalogObject.Description = "RUB";
		CatalogObject.DescriptionFull = NStr("ru = 'Российский рубль';
													|en = 'Russian Ruble';");
		CatalogObject.Write();
		WriteObject(Settings, CatalogObject);
		Currency = CatalogObject.Ref;
	EndIf;
	Register(Result, Scenario, Currency, False);
	
	// Document _DemoGoodsReceipt requires one currency.
	DescriptionTemplate = NStr("ru = 'Договор %1 (тест дублей)';
								|en = 'Contract %1 (duplicate test)';");
	Description = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, Format(1, "NG="));
	Contract = Catalogs._DemoCounterpartiesContracts.FindByDescription(Description);
	If Not ValueIsFilled(Contract) Then
		CatalogObject = Catalogs._DemoCounterpartiesContracts.CreateItem();
		CatalogObject.Description = Description;
		CatalogObject.Organization = Organization;
		CatalogObject.Owner = Counterparty;
		CatalogObject.Partner = Partner;
		CatalogObject.SettlementsCurrency = Currency;
		CatalogObject.Write();
		WriteObject(Settings, CatalogObject);
		Contract = CatalogObject.Ref;
	EndIf;
	Register(Result, Scenario, Contract, True);
	
	// Catalog _DemoProducts requires one product type.
	DescriptionTemplate = NStr("ru = 'Вид номенклатуры %1 (тест дублей)';
								|en = 'Product kind %1 (duplicate test)';");
	Description = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, Format(1, "NG="));
	ProductKind = Catalogs._DemoProductsKinds.FindByDescription(Description);
	If Not ValueIsFilled(ProductKind) Then
		CatalogObject = Catalogs._DemoProductsKinds.CreateItem();
		CatalogObject.Description = Description;
		WriteObject(Settings, CatalogObject);
		ProductKind = CatalogObject.Ref;
	EndIf;
	Register(Result, Scenario, ProductKind, True);
	
	DescriptionTemplate = Settings.AccumulationRegistersPrefix;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	_DemoProducts.Ref,
	|	_DemoProducts.Description,
	|	_DemoProducts.SKU
	|FROM
	|	Catalog._DemoProducts AS _DemoProducts
	|WHERE
	|	_DemoProducts.Description LIKE &DescriptionTemplate ESCAPE ""~""";
	DescriptionTemplateForQuery = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, "%");
	Query.SetParameter("DescriptionTemplate", Common.GenerateSearchQueryString(DescriptionTemplateForQuery));
	AlreadyGeneratedObjects = Query.Execute().Unload();
	
	Period = BegOfYear(CurrentSessionDate());
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	UninvoicedReceipt.Ref
	|FROM
	|	Document._DemoGoodsReceipt AS UninvoicedReceipt
	|WHERE
	|	UninvoicedReceipt.Date = &Period
	|	AND UninvoicedReceipt.Organization = &Organization
	|	AND UninvoicedReceipt.StorageLocation = &StorageLocation
	|	AND UninvoicedReceipt.Partner = &Partner
	|	AND UninvoicedReceipt.Counterparty = &Counterparty
	|	AND UninvoicedReceipt.Contract = &Contract";
	Query.SetParameter("Period", Period);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("StorageLocation", StorageLocation);
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("Contract", Contract);
	AlreadyCreatedDocuments = Query.Execute().Unload();
	
	For ItemNumber = 1 To Settings.AccumulationRegistersCount Do
		Description = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, Format(ItemNumber, "NG="));
		
		FoundItems = AlreadyGeneratedObjects.FindRows(New Structure("Description, SKU", Description, "Original"));
		If FoundItems.Count() = 0 Then
			CatalogObject = Catalogs._DemoProducts.CreateItem();
			CatalogObject.Description    = Description;
			CatalogObject.ProductKind = ProductKind;
			CatalogObject.SKU = "Original";
			WriteObject(Settings, CatalogObject);
			Original = CatalogObject.Ref;
		Else
			Original = FoundItems[0].Ref;
		EndIf;
		Register(Result, Scenario, Original, True);
		
		FoundItems = AlreadyGeneratedObjects.FindRows(New Structure("Description, SKU", Description, "Duplicate1"));
		If FoundItems.Count() = 0 Then
			CatalogObject = Catalogs._DemoProducts.CreateItem();
			CatalogObject.Description    = Description;
			CatalogObject.ProductKind = ProductKind;
			CatalogObject.SKU = "Duplicate1";
			WriteObject(Settings, CatalogObject, False, False);
			Duplicate1 = CatalogObject.Ref;
		Else
			Duplicate1 = FoundItems[0].Ref;
		EndIf;
		Register(Result, Scenario, Duplicate1, True, Original);
		
		If AlreadyCreatedDocuments.Count() = 0 Then
			DocumentObject = Documents._DemoGoodsReceipt.CreateDocument();
			DocumentObject.Date          = Period;
			DocumentObject.Organization   = Organization;
			DocumentObject.StorageLocation = StorageLocation;
			DocumentObject.Partner       = Partner;
			DocumentObject.Counterparty    = Counterparty;
			DocumentObject.Contract       = Contract;
		Else
			DocumentObject = AlreadyCreatedDocuments[0].Ref.GetObject();
		EndIf;
		
		// There are three options for dimension overlapping:
		// - There's a record of the duplicate, and there's no record of the original item.
		// - There's a record of the original item, and there's no record of the duplicate.
		// - Both records are present.
		FillingStructure = New Structure("Products, Count, Price", Original, 3, 1);
		FoundItems = DocumentObject.Goods.FindRows(FillingStructure);
		If FoundItems.Count() = 0 Then
			FillPropertyValues(DocumentObject.Goods.Add(), FillingStructure);
		EndIf;
		
		FillingStructure = New Structure("Products, Count, Price", Duplicate1, 5, 1);
		FoundItems = DocumentObject.Goods.FindRows(FillingStructure);
		If FoundItems.Count() = 0 Then
			FillPropertyValues(DocumentObject.Goods.Add(), FillingStructure);
		EndIf;
		
		WriteObject(Settings, DocumentObject);
		DocumentObject.Write(DocumentWriteMode.Posting, DocumentPostingMode.Regular);
		Register(Result, Scenario, DocumentObject.Ref, False);
	EndDo;
	
EndProcedure

Procedure WriteObject(Settings, Object, CheckFilling = Undefined, EnableBusinessLogic = True)
	If CheckFilling = Undefined Then
		CheckFilling = Settings.CheckFilling;
	EndIf;
	If CheckFilling And Not Object.CheckFilling() Then
		Messages = GetUserMessages(True);
		More = "";
		For Each MessageFromObject In Messages Do
			More = TrimR(More + Chars.LF + Chars.LF + TrimL(MessageFromObject.Text));
		EndDo;
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось записать %1 ""%2"" по причине:
				|%3';
				|en = 'Couldn''t save %1 %2 due to:
				|%3';"),
			TypeOf(Object),
			String(Object), More);
	EndIf;
	InfobaseUpdate.WriteObject(Object, True, EnableBusinessLogic);
EndProcedure

Procedure Register(Result, Scenario, Ref, Check, OriginalRef = Undefined)
	TableRow = Result.CreatedObjects.Add();
	TableRow.Scenario = Scenario;
	TableRow.Ref = Ref;
	TableRow.Type = TypeOf(Ref);
	TableRow.Check = Check;
	
	If OriginalRef <> Undefined Then
		TableRow.IsDuplicate = True;
		TableRow.Original = OriginalRef;
		If Result.DuplicatesTypes.Find(TableRow.Type) = Undefined Then
			Result.DuplicatesTypes.Add(TableRow.Type);
		EndIf;
	EndIf;
	
	MetadataObject = Metadata.FindByType(TableRow.Type);
	FullName = Upper(MetadataObject.FullName());
	TableRow.Kind = Left(FullName, StrFind(FullName, ".")-1);
	If TableRow.Kind = "CATALOG"
		Or TableRow.Kind = "DOCUMENT"
		Or TableRow.Kind = "ENUM"
		Or TableRow.Kind = "CHARTOFCHARACTERISTICTYPES"
		Or TableRow.Kind = "CHARTOFACCOUNTS"
		Or TableRow.Kind = "CHARTOFCALCULATIONTYPES"
		Or TableRow.Kind = "BUSINESSPROCESS"
		Or TableRow.Kind = "TASK"
		Or TableRow.Kind = "EXCHANGEPLAN" Then
		TableRow.Referential = True;
	EndIf;
	
EndProcedure

// ACC:1328-on

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf