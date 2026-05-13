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
	
	Result.Insert("LinearDependencyUsage", True);
	Result.Insert("LinearDependencyCount", 1);
	Result.Insert("LinearDependencyLength", 5);
	Result.Insert("LinearDependencyPrefix", NStr("ru = 'Тест удаления 1: Линия %1 (используется в %2)';
															|en = 'Deletion test 1: Line %1 (is used in %2)';"));
	
	Result.Insert("SolvableCircularDependencyUsage", True);
	Result.Insert("SolvableCircularDependencyCount", 1);
	Result.Insert("SolvableCircularDependencyLength", 10);
	Result.Insert("SolvableCircularDependencyPrefix", NStr("ru = 'Тест удаления 2: Кольцо %1 (используется в %2)';
																	|en = 'Deletion test 2: Circle %1 (used in %2)';"));
	
	Result.Insert("NotSolvableCircularDependencyUsage", True);
	Result.Insert("NotSolvableCircularDependencyCount", 1);
	Result.Insert("NotSolvableCircularDependencyLength", 10);
	Result.Insert("NotSolvableCircularDependencyPrefix", NStr("ru = 'Тест удаления 3: Кольцо %1 (используется в %2)';
																	|en = 'Deletion test 3: Circle %1 (used in %2)';"));
	
	Result.Insert("NoDependenciesUsage", True);
	Result.Insert("NoDependenciesCount", 10);
	Result.Insert("NoDependenciesPrefix", NStr("ru = 'Объект без зависимостей: %1';
														|en = 'Object without dependencies: %1';"));
	
	Result.Insert("OtherScenariosUsage", True);
	Result.Insert("OtherScenariosPrefix1", NStr("ru = 'Удаляемая организация';
														|en = 'Company to be deleted';"));
	Result.Insert("OtherScenariosPrefix2", NStr("ru = 'Удаляемое физ. лицо';
														|en = 'Individual to be deleted';"));
	Result.Insert("OtherScenariosPrefix3", NStr("ru = 'Удаляемый доп. реквизит';
														|en = 'Additional attribute to be deleted';"));
	Result.Insert("OtherScenariosPrefix4", NStr("ru = 'Удаляемый вид субконто';
														|en = 'Extra dimension type to be deleted';"));
	Result.Insert("OtherScenariosPrefix5", NStr("ru = 'Удаляемый вид расчета';
														|en = 'Calculation type to be deleted';"));
	
	Return Result;
EndFunction

Function Generate(SettingsCollection) Export
	Settings = DefaultSettings();
	If SettingsCollection <> Undefined Then
		FillPropertyValues(Settings, SettingsCollection);
	EndIf;
	
	CreatedObjects = New ValueTable;
	CreatedObjects.Columns.Add("Scenario", New TypeDescription("String"));
	CreatedObjects.Columns.Add("Type", New TypeDescription("Type"));
	CreatedObjects.Columns.Add("Ref");
	CreatedObjects.Columns.Add("Check", New TypeDescription("Boolean"));
	CreatedObjects.Columns.Add("Kind", New TypeDescription("String"));
	CreatedObjects.Columns.Add("Referential", New TypeDescription("Boolean"));
	
	Result = New Structure;
	Result.Insert("CreatedObjects", CreatedObjects);
	
	ItemsToMarkForDeletion = New Array;
	
	// Linear dependency.
	If Settings.LinearDependencyUsage Then
		CreateLineOfMarkedObjects(Settings, Result);
	EndIf;
	
	// Resolvable circular dependency.
	If Settings.SolvableCircularDependencyUsage Then
		CreateCircleOfMarkedObjects(Settings, Result, True);
	EndIf;
	
	// Unresolvable circular dependency.
	If Settings.SolvableCircularDependencyUsage Then
		CreateCircleOfMarkedObjects(Settings, Result, False);
	EndIf;
	
	// Single objects without dependencies.
	If Settings.NoDependenciesUsage Then
		DescriptionTemplate = Settings.NoDependenciesPrefix;
		For NumberOfGroup = 1 To Settings.NoDependenciesCount Do
			CatalogObject = Catalogs._DemoProducts.CreateItem();
			CatalogObject.Description = StringFunctionsClientServer.SubstituteParametersToString(
				DescriptionTemplate,
				Format(NumberOfGroup, "NG="));
			CatalogObject.Write();
			Register(CatalogObject.Ref, True, "Point", Result);
		EndDo;
	EndIf;
	
	If Settings.OtherScenariosUsage Then
		CreateMarkedObjectsForOtherScenarios(Settings, Result);
	EndIf;
	
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

// CAC:1328-off a shared lock for readable data is not required for these texts.

Procedure Register(Ref, Check, Scenario, Result)
	TableRow = Result.CreatedObjects.Add();
	TableRow.Scenario = Scenario;
	TableRow.Ref = Ref;
	TableRow.Type = TypeOf(Ref);
	TableRow.Check = Check;
	
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

Procedure CreateLineOfMarkedObjects(Settings, Result)
	Scenario = "Line";
	DescriptionTemplate = Settings.LinearDependencyPrefix;
	For NumberOfGroup = 1 To Settings.LinearDependencyCount Do
		LastRef = Undefined;
		For ItemNumber = 1 To Settings.LinearDependencyLength Do
			CatalogObject = Catalogs._DemoProducts.CreateItem();
			CatalogObject.Description = StringFunctionsClientServer.SubstituteParametersToString(
				DescriptionTemplate,
				Format(ItemNumber, "NG="),
				?(ItemNumber = 1, "-", "" + Format(ItemNumber-1, "NG=")));
			CatalogObject.Substitutes.Add().Substitute = LastRef;
			CatalogObject.Write();
			LastRef = CatalogObject.Ref;
			Register(CatalogObject.Ref, True, Scenario, Result);
		EndDo;
		Result.Insert(Scenario + "_LastMarked", LastRef);
	EndDo;
EndProcedure

Procedure CreateCircleOfMarkedObjects(Settings, Result, Solvable)
	If Solvable Then
		Scenario = "SolvableDependencyCircular";
		
		DescriptionTemplate = Settings.SolvableCircularDependencyPrefix;
		GroupCount = Settings.SolvableCircularDependencyCount;
		CircleLength = Settings.SolvableCircularDependencyLength;
		RandomObjectNumber = 0;
	Else
		Scenario = "UnsolvableDependencyCircular";
		
		DescriptionTemplate = Settings.NotSolvableCircularDependencyPrefix;
		GroupCount = Settings.NotSolvableCircularDependencyCount;
		CircleLength = Settings.NotSolvableCircularDependencyLength;
		RNG = New RandomNumberGenerator;
		RandomObjectNumber = RNG.RandomNumber(1, CircleLength);
		
		ObjectToPreventDeletionDescription = NStr("ru = 'Тест удаления: Объект, не помеченный на удаление';
													|en = 'Deletion text: An object not marked for deletion';");
		ObjectToPreventDeletionRef = Catalogs._DemoProducts.FindByDescription(ObjectToPreventDeletionDescription);
		If ValueIsFilled(ObjectToPreventDeletionRef) Then
			ObjectToPreventDeletion1 = ObjectToPreventDeletionRef.GetObject();
		Else
			ObjectToPreventDeletion1 = Catalogs._DemoProducts.CreateItem();
			ObjectToPreventDeletion1.Description = ObjectToPreventDeletionDescription;
			ObjectToPreventDeletion1.Write();
			ObjectToPreventDeletionRef = ObjectToPreventDeletion1.Ref;
		EndIf;
		Register(ObjectToPreventDeletionRef, False, Scenario, Result);
		Result.Insert(Scenario + "_NotMarked", ObjectToPreventDeletionRef);
	EndIf;
	
	For NumberOfGroup = 1 To GroupCount Do
		
		RandomObject = Undefined;
		FirstObject = Undefined;
		LastRef = Undefined;
		For ItemNumber = 1 To CircleLength Do
			CatalogObject = Catalogs._DemoProducts.CreateItem();
			CatalogObject.Description = StringFunctionsClientServer.SubstituteParametersToString(
				DescriptionTemplate,
				Format(ItemNumber, "NG="),
				"" + Format(?(ItemNumber = 1, CircleLength, ItemNumber-1), "NG="));
			CatalogObject.Substitutes.Add().Substitute = LastRef;
			CatalogObject.Write();
			LastRef = CatalogObject.Ref;
			If ItemNumber = 1 Then
				FirstObject = CatalogObject;
			EndIf;
			If ItemNumber = RandomObjectNumber Then
				RandomObject = CatalogObject;
			EndIf;
			Register(CatalogObject.Ref, True, Scenario, Result);
		EndDo;
		FirstObject.Substitutes.Add().Substitute = LastRef;
		FirstObject.Write();
		
		Result.Insert(Scenario + "_LastMarked", LastRef);
		
		If Not Solvable Then
			ObjectToPreventDeletion1.Substitutes.Add().Substitute = RandomObject.Ref;
			ObjectToPreventDeletion1.Write();
			TemplatePrefix = Left(DescriptionTemplate, StrFind(DescriptionTemplate, ":")+1);
			RandomObject.Description = TemplatePrefix + NStr("ru = 'Номенклатура использована в не помеченном объекте';
																|en = 'Product is used in the non-marked object';");
			RandomObject.Write();
			Result.Insert(Scenario + "_UsedInNotMarked", RandomObject.Ref);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CreateMarkedObjectsForOtherScenarios(Settings, Result)
	Scenario = "OtherItems";
	
	// Main objects taking part in a scenario of deleting marked items.
	
	CompanyLink = Catalogs._DemoCompanies.FindByDescription(Settings.OtherScenariosPrefix1);
	If ValueIsFilled(CompanyLink) Then
		OrganizationObject = CompanyLink.GetObject();
	Else
		OrganizationObject = Catalogs._DemoCompanies.CreateItem();
		OrganizationObject.Description = Settings.OtherScenariosPrefix1;
		OrganizationObject.Write();
		CompanyLink = OrganizationObject.Ref;
	EndIf;
	Register(CompanyLink, True, Scenario, Result);
	Result.Insert(Scenario + "_Organization", CompanyLink);
	
	IndividualRef = Catalogs._DemoIndividuals.FindByDescription(Settings.OtherScenariosPrefix2);
	If ValueIsFilled(IndividualRef) Then
		IndividualObject = IndividualRef.GetObject();
	Else
		IndividualObject = Catalogs._DemoIndividuals.CreateItem();
		IndividualObject.Description = Settings.OtherScenariosPrefix2;
		IndividualObject.Write();
		IndividualRef = IndividualObject.Ref;
	EndIf;
	Register(IndividualRef, True, Scenario, Result);
	Result.Insert(Scenario + "_Individual", IndividualRef);
	
	AddlAttribute1Ref = ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.FindByDescription(Settings.OtherScenariosPrefix3);
	If ValueIsFilled(AddlAttribute1Ref) Then
		AddlAttribute1Object = AddlAttribute1Ref.GetObject();
	Else
		AddlAttribute1Object = ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.CreateItem();
		AddlAttribute1Object.Description = Settings.OtherScenariosPrefix3;
		AddlAttribute1Object.ValueType = New TypeDescription("CatalogRef.ObjectsPropertiesValues");
		AddlAttribute1Object.isVisible = True;
		AddlAttribute1Object.AdditionalValuesUsed = True;
		AddlAttribute1Object.Available = True;
		AddlAttribute1Object.Title = AddlAttribute1Object.Description;
		AddlAttribute1Object.Write();
		AddlAttribute1Ref = AddlAttribute1Object.Ref;
	EndIf;
	Register(AddlAttribute1Ref, True, Scenario, Result);
	Result.Insert(Scenario + "_AdditionalAttribute51", AddlAttribute1Ref);
	
	ExtDimensionKindRef = ChartsOfCharacteristicTypes._DemoExtDimensionTypes.FindByDescription(Settings.OtherScenariosPrefix4);
	If ValueIsFilled(ExtDimensionKindRef) Then
		ExtDimensionKindObject = ExtDimensionKindRef.GetObject();
	Else
		ExtDimensionKindObject = ChartsOfCharacteristicTypes._DemoExtDimensionTypes.CreateItem();
		ExtDimensionKindObject.Description = Settings.OtherScenariosPrefix4;
		ExtDimensionKindObject.ValueType = ExtDimensionKindObject.Metadata().Type;
		ExtDimensionKindObject.Write();
		ExtDimensionKindRef = ExtDimensionKindObject.Ref;
	EndIf;
	Register(ExtDimensionKindRef, True, Scenario, Result);
	Result.Insert(Scenario + "_ExtDimensionType", ExtDimensionKindRef);
	
	CalculationType1Ref = ChartsOfCalculationTypes._DemoBaseEarnings.FindByDescription(Settings.OtherScenariosPrefix5);
	If ValueIsFilled(CalculationType1Ref) Then
		CalculationType1Object = CalculationType1Ref.GetObject();
	Else
		CalculationType1Object = ChartsOfCalculationTypes._DemoBaseEarnings.CreateCalculationType();
		CalculationType1Object.Description = Settings.OtherScenariosPrefix5;
		CalculationType1Object.Write();
		CalculationType1Ref = CalculationType1Object.Ref;
	EndIf;
	Register(CalculationType1Ref, True, Scenario, Result);
	Result.Insert(Scenario + "_CalculationType1", CalculationType1Ref);
	
	// Auxiliary catalogs required for writing required attributes.
	
	Period = BegOfDay(CurrentSessionDate());
	Author = Users.CurrentUser();
	
	Description = NStr("ru = 'Контрагент/Удаление помеченных/5';
						|en = 'Counterparty/Marked objects deletion/5';");
	CounterpartyRef = Catalogs._DemoCounterparties.FindByDescription(Description);
	If Not ValueIsFilled(CounterpartyRef) Then
		CounterpartyObject = Catalogs._DemoCounterparties.CreateItem();
		CounterpartyObject.Description = Description;
		CounterpartyObject.CounterpartyKind = Enums._DemoBusinessEntityIndividual.BusinessEntity;
		CounterpartyObject.Write();
		CounterpartyRef = CounterpartyObject.Ref;
	EndIf;
	Register(CounterpartyRef, False, Scenario, Result);
	
	Description = NStr("ru = 'Подразделение/Удаление помеченных/5';
						|en = 'Department/Marked objects deletion/5';");
	UnitReference_ = Catalogs._DemoDepartments.FindByDescription(Description);
	If Not ValueIsFilled(UnitReference_) Then
		DivisionObject = Catalogs._DemoDepartments.CreateItem();
		DivisionObject.Description = Description;
		DivisionObject.Write();
		UnitReference_ = DivisionObject.Ref;
	EndIf;
	Register(UnitReference_, False, Scenario, Result);
	
	Description = NStr("ru = 'Склад/Удаление помеченных/5';
						|en = 'Warehouse/Marked objects deletion/5';");
	WarehouseReference = Catalogs._DemoStorageLocations.FindByDescription(Description);
	If Not ValueIsFilled(WarehouseReference) Then
		WarehouseObject = Catalogs._DemoStorageLocations.CreateItem();
		WarehouseObject.Description = Description;
		WarehouseObject.Write();
		WarehouseReference = WarehouseObject.Ref;
	EndIf;
	Register(WarehouseReference, False, Scenario, Result);
	
	Description = NStr("ru = 'Партнер/Удаление помеченных/5';
						|en = 'Partner/Marked object deletion/5';");
	PartnerLink = Catalogs._DemoPartners.FindByDescription(Description);
	If Not ValueIsFilled(PartnerLink) Then
		PartnerObject_ = Catalogs._DemoPartners.CreateItem();
		PartnerObject_.Description = Description;
		PartnerObject_.Write();
		PartnerLink = PartnerObject_.Ref;
	EndIf;
	Register(PartnerLink, False, Scenario, Result);
	
	Description = NStr("ru = 'Вид номенклатуры/Удаление помеченных/5';
						|en = 'Product kind/Marked object deletion/5';");
	ProductKindReference = Catalogs._DemoProductsKinds.FindByDescription(Description);
	If Not ValueIsFilled(ProductKindReference) Then
		ItemProductType = Catalogs._DemoProductsKinds.CreateItem();
		ItemProductType.Description = Description;
		ItemProductType.Write();
		ProductKindReference = ItemProductType.Ref;
	EndIf;
	Register(ProductKindReference, True, Scenario, Result);
	
	Description = NStr("ru = 'Номенклатура/Удаление помеченных/5';
						|en = 'Product/Marked object deletion/5';");
	ProductsLink = Catalogs._DemoProducts.FindByDescription(Description);
	If Not ValueIsFilled(ProductsLink) Then
		ItemProducts_ = Catalogs._DemoProducts.CreateItem();
		ItemProducts_.Description    = Description;
		ItemProducts_.ProductKind = ProductKindReference;
		ItemProducts_.Write();
		ProductsLink = ItemProducts_.Ref;
	EndIf;
	Register(ProductsLink, False, Scenario, Result);
	
	// Constant.
	
	Constants._DemoMainCompany.Set(CompanyLink);
	
	// Subordinate catalog.
	
	Description = NStr("ru = 'Банковский счет/Удаление помеченных/5';
						|en = 'Bank account/Marked object deletion/5';");
	BankAccountRef = Catalogs._DemoBankAccounts.FindByDescription(Description);
	If ValueIsFilled(BankAccountRef) Then
		BankingAccountObject = BankAccountRef.GetObject();
	Else
		BankingAccountObject = Catalogs._DemoBankAccounts.CreateItem();
		BankingAccountObject.Description = Description;
	EndIf;
	BankingAccountObject.Owner = CompanyLink;
	BankingAccountObject.Write();
	Register(BankingAccountObject.Ref, False, Scenario, Result);
	
	// A catalog subordinate to another object.
	
	Description = NStr("ru = 'Договор/Удаление помеченных/5';
						|en = 'Contract/Marked object deletion/5';");
	ContractLink = Catalogs._DemoCounterpartiesContracts.FindByDescription(Description);
	If ValueIsFilled(ContractLink) Then
		ObjectAgreement = ContractLink.GetObject();
	Else
		ObjectAgreement = Catalogs._DemoCounterpartiesContracts.CreateItem();
		ObjectAgreement.Description = Description;
	EndIf;
	ObjectAgreement.Organization = CompanyLink;
	ObjectAgreement.Owner = CounterpartyRef;
	ObjectAgreement.Write();
	Register(ObjectAgreement.Ref, False, Scenario, Result);
	
	// A document with information register records.
	// The PersonalDataProcessingConsents register is written implicitly.
	
	
	// An independent information register with a leading dimension.
	
	EmployeesRecordSet = InformationRegisters._DemoCompaniesEmployees.CreateRecordSet();
	EmployeesRecordSet.Filter.Organization.Set(CompanyLink);
	
	EmployeesWriter = EmployeesRecordSet.Add();
	EmployeesWriter.Period         = Period;
	EmployeesWriter.Active     = True;
	EmployeesWriter.Organization    = CompanyLink;
	EmployeesWriter.Individual = IndividualRef;
	EmployeesWriter.Department_Company = UnitReference_;
	EmployeesWriter.OccupiedRates         = 3;
	EmployeesWriter.EmployeeCode           = "7";
	
	EmployeesRecordSet.Write(True);
	
	Register(EmployeesRecordSet, False, Scenario, Result);
	
	// A document with accumulation register records.
	// The "_DemoGoodsBalancesInStorageLocations" is written implicitly.
	
	DocumentRef = Documents._DemoGoodsReceipt.FindByAttribute("Organization", CompanyLink);
	If ValueIsFilled(DocumentRef) Then
		DocumentObject = DocumentRef.GetObject();
	Else
		DocumentObject = Documents._DemoGoodsReceipt.CreateDocument();
	EndIf;
	DocumentObject.Date          = Period;
	DocumentObject.Organization   = CompanyLink;
	DocumentObject.StorageLocation = WarehouseReference;
	DocumentObject.Partner       = PartnerLink;
	DocumentObject.DeletionMark = False;
	DocumentObject.Comment   = NStr("ru = 'Поступление/Удаление помеченных/5';
										|en = 'Receipt/Marked object deletion/5';");
	
	TableRow = DocumentObject.Goods.Add();
	TableRow.Products = ProductsLink;
	TableRow.Count   = 10;
	TableRow.Price         = 50;
	
	DocumentObject.Write(DocumentWriteMode.Posting);
	Register(DocumentObject.Ref, False, Scenario, Result);
	
	// Chart of characteristic types AdditionalAttributesAndInfo.
	
	Description = NStr("ru = 'Доп. реквизит/Удаление помеченных/5';
						|en = 'Additional attribute/Marked object deletion/5';");
	AddlAttribute2Ref = ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.FindByDescription(Description);
	If ValueIsFilled(AddlAttribute2Ref) Then
		AddlAttribute2Object = AddlAttribute2Ref.GetObject();
	Else
		AddlAttribute2Object = ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.CreateItem();
		FillPropertyValues(AddlAttribute2Object, AddlAttribute1Object, "ValueType, isVisible, AdditionalValuesUsed, Available");
		AddlAttribute2Object.Description = Description;
		AddlAttribute2Object.Title = Description;
	EndIf;
	AddlAttribute2Object.AdditionalAttributesDependencies.Clear();
	
	TableRow = AddlAttribute2Object.AdditionalAttributesDependencies.Add();
	TableRow.Attribute = AddlAttribute1Ref;
	TableRow.Condition = "Equal";
	
	AddlAttribute2Object.Write();
	Register(AddlAttribute2Object.Ref, False, Scenario, Result);
	
	// "Duty" business process and "PerformerTask" task.
	
	ChiefAccountantRole = Catalogs.PerformerRoles._DemoChiefAccountant;
	
	Query = New Query;
	Query.Text = "SELECT Ref FROM Catalog.TaskPerformersGroups WHERE PerformerRole = &Role AND MainAddressingObject = &Object";
	Query.SetParameter("Role", ChiefAccountantRole);
	Query.SetParameter("Object", CompanyLink);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		PerformersGroupRef = Selection.Ref;
	Else
		PerformersGroupObject = Catalogs.TaskPerformersGroups.CreateItem();
		PerformersGroupObject.Description = NStr("ru = 'Группа исполнителей/Удаление помеченных/5';
													|en = 'Assignee group/Marked object deletion/5';");
		PerformersGroupObject.PerformerRole = ChiefAccountantRole;
		PerformersGroupObject.MainAddressingObject = CompanyLink;
		PerformersGroupObject.Write();
		PerformersGroupRef = PerformersGroupObject.Ref;
	EndIf;
	Register(PerformersGroupRef, False, Scenario, Result);
	
	ImportanceNormal = Enums.TaskImportanceOptions.Ordinary;
	ActiveState = Enums.BusinessProcessStates.Running;
	
	Description = NStr("ru = 'Задание/Удаление помеченных/5';
						|en = 'Duty/Marked object deletion/5';");
	BPJobRef = BusinessProcesses.Job.FindByAttribute("Description", Description);
	If ValueIsFilled(BPJobRef) Then
		BPJobObject = BPJobRef.GetObject();
	Else
		BPJobObject = BusinessProcesses.Job.CreateBusinessProcess();
		BPJobObject.Description = Description;
	EndIf;
	BPJobObject.Importance                = ImportanceNormal;
	BPJobObject.Date                    = Period;
	BPJobObject.Author                   = Author;
	BPJobObject.AuthorAsString            = String(Author);
	BPJobObject.Performer             = ChiefAccountantRole;
	BPJobObject.MainAddressingObject = CompanyLink;
	BPJobObject.TaskDueDate          = EndOfYear(Period);
	BPJobObject.State               = ActiveState;
	BPJobObject.Started               = True;
	BPJobObject.OnValidation              = True;
	BPJobObject.IterationNumber           = 1;
	BPJobObject.Supervisor             = Author;
	BPJobObject.Write();
	BPJobRef = BPJobObject.Ref;
	Register(BPJobRef, False, Scenario, Result);
	
	Description = NStr("ru = 'Задача исполнителя/Удаление помеченных/5';
						|en = 'Assignee task/Marked object deletion/5';");
	PerformerTaskRef = Tasks.PerformerTask.FindByDescription(Description);
	If ValueIsFilled(PerformerTaskRef) Then
		PerformerTaskObject = PerformerTaskRef.GetObject();
	Else
		PerformerTaskObject = Tasks.PerformerTask.CreateTask();
		PerformerTaskObject.Description = Description;
	EndIf;
	PerformerTaskObject.Date                    = Period;
	PerformerTaskObject.BusinessProcess           = BPJobRef;
	PerformerTaskObject.Importance                = ImportanceNormal;
	PerformerTaskObject.Author                   = Author;
	PerformerTaskObject.AuthorAsString            = String(Author);
	PerformerTaskObject.RoutePoint           = BusinessProcesses.Job.RoutePoints.Execute;
	PerformerTaskObject.TaskPerformersGroup = PerformersGroupRef;
	PerformerTaskObject.MainAddressingObject = CompanyLink;
	PerformerTaskObject.PerformerRole         = ChiefAccountantRole;
	PerformerTaskObject.BusinessProcessState = ActiveState;
	PerformerTaskObject.TaskDueDate          = EndOfYear(Period);
	PerformerTaskObject.Write();
	Register(PerformerTaskObject.Ref, False, Scenario, Result);
	
	// Chart of accounts _DemoMain.
	
	Description = NStr("ru = 'Забалансовый счет/Удаление помеченных/5';
						|en = 'Off-balance account/Marked object deletion/5';");
	Code = "DEL";
	OffBalanceAccountRef = ChartsOfAccounts._DemoMain.FindByDescription(Description);
	If Not ValueIsFilled(OffBalanceAccountRef) Then
		OffBalanceAccountRef = ChartsOfAccounts._DemoMain.FindByCode(Code);
	EndIf;
	If ValueIsFilled(OffBalanceAccountRef) Then
		OffBalanceAccountObject = OffBalanceAccountRef.GetObject();
	Else
		OffBalanceAccountObject = ChartsOfAccounts._DemoMain.CreateAccount();
		OffBalanceAccountObject.Description = Description;
		OffBalanceAccountObject.Code = Code;
	EndIf;
	OffBalanceAccountObject.Type = AccountType.ActivePassive;
	OffBalanceAccountObject.OffBalance = True;
	
	OffBalanceAccountObject.ExtDimensionTypes.Clear();
	TableRow = OffBalanceAccountObject.ExtDimensionTypes.Add();
	TableRow.ExtDimensionType = ExtDimensionKindRef;
	
	OffBalanceAccountObject.Write();
	Register(OffBalanceAccountObject.Ref, False, Scenario, Result);
	
	// Chart of calculation types _DemoBaseEarnings.
	
	// A dependent calculation type not marked for deletion.
	Description = NStr("ru = 'Зависимый расчет/Удаление помеченных/5';
						|en = 'Dependent calculation/Marked object deletion/5';");
	CalculationType2Ref = ChartsOfCalculationTypes._DemoBaseEarnings.FindByDescription(Description);
	If ValueIsFilled(CalculationType2Ref) Then
		CalculationType2Object = CalculationType2Ref.GetObject();
	Else
		CalculationType2Object = ChartsOfCalculationTypes._DemoBaseEarnings.CreateCalculationType();
		CalculationType2Object.Description = Description;
	EndIf;
	CalculationType2Object.LeadingCalculationTypes.Clear();
	
	TableRow = CalculationType2Object.LeadingCalculationTypes.Add();
	TableRow.CalculationType = CalculationType1Ref;
	
	CalculationType2Object.Write();
	Register(CalculationType2Object.Ref, False, Scenario, Result);
	
	// A basic calculation type not marked for deletion.
	CalculationType3Ref = Common.PredefinedItem("ChartOfCalculationTypes._DemoBaseEarnings.BusinessTripReimbursement");
	CalculationType3Object = CalculationType3Ref.GetObject();
	CalculationType3Object.BaseCalculationTypes.Clear();
	
	TableRow = CalculationType3Object.BaseCalculationTypes.Add();
	TableRow.CalculationType = CalculationType1Ref;
	
	CalculationType3Object.Write();
	
EndProcedure

// ACC:1328-on

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf