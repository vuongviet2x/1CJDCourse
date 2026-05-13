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

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If FillingData = Undefined Then // Create a new item.
		_DemoStandardSubsystems.OnEnterNewItemFillCompany(ThisObject, "ParentCompany");
	EndIf;
	
	If TypeOf(FillingData) = Type("DocumentRef._DemoGoodsReceipt") Then
		UninvoicedReceipt = FillingData.GetObject();
		FillPropertyValues(ThisObject, UninvoicedReceipt, , "Number,Date,EmployeeResponsible,Comment");
		ParentCompany = UninvoicedReceipt.Organization;
		EmployeeResponsible = Users.CurrentUser();
		For Each LineProducts_ In UninvoicedReceipt.Goods Do
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, LineProducts_);
			NewRow.DocumentInflow = FillingData;
		EndDo;
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	GenerateRegisterRecordsByStorageLocations();
	
	GenerateAccountingRegisteredRecords();
	
	GenerateRegisterRecordsToDocumentsRegistry();
	
EndProcedure

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	Prefix = "A";
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	For Each LineProducts_ In Goods Do
	
		If Not ValueIsFilled(LineProducts_.DimensionKey) Then
			ParametersOfKey = New Structure("Products, StorageLocation", LineProducts_.Products, StorageLocation);
			LineProducts_.DimensionKey = Catalogs._DemoProductDimensionKeys.CreateKey(ParametersOfKey);
		EndIf;
	
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Procedure GenerateRegisterRecordsByStorageLocations()
	
	RegisterRecords._DemoGoodsBalancesInStorageLocations.Write = True;
	
	For Each LineProducts_ In Goods Do
		
		Movement = RegisterRecords._DemoGoodsBalancesInStorageLocations.Add();
		
		Movement.Period        = Date;
		Movement.RecordType   = AccumulationRecordType.Expense;
		
		Movement.Organization   = ParentCompany;
		Movement.StorageLocation = StorageLocation;
		
		Movement.Products  = LineProducts_.Products;
		Movement.Count    = LineProducts_.Count;
		
	EndDo;
	
EndProcedure
//
Procedure GenerateRegisterRecordsToDocumentsRegistry()
	
	SetPrivilegedMode(True);
	
	Movement = InformationRegisters._DemoDocumentsRegistry.CreateRecordManager();
	Movement.RefType = Common.MetadataObjectID(Ref.Metadata());
	Movement.Organization = ParentCompany;
	Movement.Partner = Partner;
	Movement.StorageLocation = StorageLocation;
	Movement.Counterparty = Counterparty;
	Movement.Department = Department;
	Movement.IBDocumentDate = Date;
	Movement.Contract = Contract;
	Movement.Ref = Ref;
	Movement.IBDocumentNumber = Number;
	Movement.EmployeeResponsible = EmployeeResponsible;
	Movement.Comment = Comment;
	Movement.Posted = True;
	Movement.DeletionMark = False;
	Movement.More = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'По договору ""%1""';
																							|en = 'Under the ""%1"" contract';"), Contract);
	Movement.SourceDocumentDate = Date;
	Movement.SourceDocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Number, True, True);
	Movement.Sum = Goods.Total("Price")*Goods.Total("Count");
	Movement.Currency = Currency;
	Movement.RecordingInAccountingDate = Date;
	Movement.Write();
	
EndProcedure

Procedure GenerateAccountingRegisteredRecords()
	
	ForeignExchangeDocument = Common.ObjectAttributeValue(Currency, "Code") <> "643";
	If Currency.IsEmpty() Then
		DocumentCurrency  = New Structure("Rate, Repetition", 1, 1,);
	Else
		DocumentCurrency  = CurrencyRateOperations.GetCurrencyRate(Currency, Date);
	EndIf;
	
	ProcessVAT = GetFunctionalOption("_DemoIncludeVAT") And Not ForeignExchangeDocument;
	
	RegisterRecords._DemoAccountingTransactionLog.Write = True;
	RegisterRecords._DemoAccountingEntriesJournalWithoutCorrespondence.Write = True;
	
	ItemKinds = New Map;
	For Each RowOfProduct In Goods Do
		
		ToFormMovementOfSaleOfGoodsAccordingToRegisterOfMain(RowOfProduct, ForeignExchangeDocument, DocumentCurrency, ItemKinds);
		ToFormMovementOfSaleOfGoodsAccordingToRegisterOfMainOneWithoutCorrespondence(RowOfProduct, ForeignExchangeDocument, DocumentCurrency, 
			ItemKinds);
		
		If ProcessVAT Then
			GenerateMovementOfAccountingForAccruedVATAccordingToBasicRegister(RowOfProduct, ItemKinds);
			GenerateMovementOfAccountingForAccruedVATAccordingToBasicRegisterWithoutCorrespondence(RowOfProduct, ItemKinds);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ToFormMovementOfSaleOfGoodsAccordingToRegisterOfMain(Val RowOfProduct, Val CurrencyAccounting, Val DocumentCurrency,
	Val ItemKinds)
	
	CurrencyAmount = RowOfProduct.Price * RowOfProduct.Count;
	RubleAmount = CurrencyAmount * DocumentCurrency.Rate / DocumentCurrency.Repetition;
	Product_Category = Product_Category(RowOfProduct.Products, ItemKinds);
	
	// ---
	Movement = RegisterRecords._DemoAccountingTransactionLog.Add();
	Movement.Period      = Date;
	Movement.Organization = ParentCompany;
	Movement.Content  = NStr("ru = 'Реализация товаров';
								|en = 'Goods sales';");
	Movement.Sum       = RubleAmount;
	
	If CurrencyAccounting Then
		Movement.AccountDr          = ChartsOfAccounts._DemoMain.SettlementsWithCustomersCurr;
		Movement.CurrencyDr        = Currency;
		Movement.CurrencyAmountDr = CurrencyAmount;
	Else
		Movement.AccountDr = ChartsOfAccounts._DemoMain.SettlementsWithCustomers;
	EndIf;
	
	Movement.ExtDimensionsDr.Counterparties = Counterparty;
	Movement.ExtDimensionsDr.Contracts    = Contract;
	
	Movement.AccountCr = ChartsOfAccounts._DemoMain.Revenue;
	Movement.ExtDimensionsCr.ProductRangeGroups = Product_Category;
	
	If Not CurrencyAccounting Then
		Movement.ExtDimensionsCr.VATRates = VATRate;
	EndIf;
	
	// ---
	Movement = RegisterRecords._DemoAccountingTransactionLog.Add();
	Movement.Period      = Date;
	Movement.Organization = ParentCompany;
	Movement.Content  = NStr("ru = 'Реализация товаров';
								|en = 'Goods sales';");
	Movement.Sum       = RubleAmount;
	
	Movement.AccountDr = ChartsOfAccounts._DemoMain.SaleCost;
	Movement.ExtDimensionsDr.ProductRangeGroups = Product_Category;
	
	Movement.AccountCr = ChartsOfAccounts._DemoMain.ProductStock;
	
	Movement.ExtDimensionsCr.Counterparties  = Counterparty;
	Movement.ExtDimensionsCr.Products = RowOfProduct.Products;
	Movement.ExtDimensionsCr.Warehouses       = StorageLocation;
	
	Movement.CountCr = RowOfProduct.Count;
	
EndProcedure

Procedure GenerateMovementOfAccountingForAccruedVATAccordingToBasicRegister(Val RowOfProduct, Val ItemKinds)
	
	RubleAmount = RowOfProduct.Price * RowOfProduct.Count;
	VATAmount = RubleAmount / 100 * Common.ObjectAttributeValue(VATRate, "Rate1");
	Product_Category = Product_Category(RowOfProduct.Products, ItemKinds);
	
	Movement = RegisterRecords._DemoAccountingTransactionLog.Add();
	Movement.Period      = Date;
	Movement.Organization = ParentCompany;
	Movement.Sum       = VATAmount;
	
	Movement.AccountDr = ChartsOfAccounts._DemoMain.Sales_VAT;
	Movement.ExtDimensionsDr.ProductRangeGroups = Product_Category;
	
	Movement.AccountCr = ChartsOfAccounts._DemoMain.VAT;
	Movement.ExtDimensionsCr.PaymentsToBudgetTypes = Enums._DemoBudgetPaymentKinds.Tax;
	
	Values = New Structure;
	Values.Insert("Content", "ru = 'Реализация товаров';
									|en = 'Goods sales';"); // @NStr-2
	
	Common.SetAttributesValues(Movement, Values);
	
EndProcedure

Procedure ToFormMovementOfSaleOfGoodsAccordingToRegisterOfMainOneWithoutCorrespondence(Val RowOfProduct, Val CurrencyAccounting, 
	Val DocumentCurrency, Val ItemKinds)
	
	CurrencyAmount = RowOfProduct.Price * RowOfProduct.Count;
	RubleAmount = CurrencyAmount * DocumentCurrency.Rate / DocumentCurrency.Repetition;
	Product_Category = Product_Category(RowOfProduct.Products, ItemKinds);
	
	// ---
	Movement = RegisterRecords._DemoAccountingEntriesJournalWithoutCorrespondence.Add();
	Movement.Period      = Date;
	Movement.Organization = ParentCompany;
	Movement.Content  = NStr("ru = 'Реализация товаров';
								|en = 'Goods sales';");
	Movement.Sum       = RubleAmount;
	
	If CurrencyAccounting Then
		Movement.Account          = ChartsOfAccounts._DemoMain.SettlementsWithCustomersCurr;
		Movement.Currency        = Currency;
		Movement.CurrencyAmount = CurrencyAmount;
	Else
		Movement.Account = ChartsOfAccounts._DemoMain.SettlementsWithCustomers;
	EndIf; 
	
	Movement.ExtDimensions.Counterparties = Counterparty;
	Movement.ExtDimensions.Contracts    = Contract;
	
	Movement = RegisterRecords._DemoAccountingEntriesJournalWithoutCorrespondence.Add();
	Movement.Period      = Date;
	Movement.Organization = ParentCompany;
	Movement.Content  = NStr("ru = 'Реализация товаров';
								|en = 'Goods sales';");
	Movement.Sum       = RubleAmount;
	Movement.Account = ChartsOfAccounts._DemoMain.Revenue;
	Movement.ExtDimensions.ProductRangeGroups = Product_Category;
	
	If Not CurrencyAccounting Then
		Movement.ExtDimensions.VATRates = VATRate;
	EndIf;
	
	// ---
	Movement = RegisterRecords._DemoAccountingEntriesJournalWithoutCorrespondence.Add();
	Movement.Period      = Date;
	Movement.Organization = ParentCompany;
	Movement.Content  = NStr("ru = 'Реализация товаров';
								|en = 'Goods sales';");
	Movement.Sum       = RubleAmount;
	Movement.Account = ChartsOfAccounts._DemoMain.SaleCost;
	Movement.ExtDimensions.ProductRangeGroups = Product_Category;
		
	Movement = RegisterRecords._DemoAccountingEntriesJournalWithoutCorrespondence.Add();
	Movement.Period      = Date;
	Movement.Organization = ParentCompany;
	Movement.Content  = NStr("ru = 'Реализация товаров';
								|en = 'Goods sales';");
	Movement.Sum       = RubleAmount;
	Movement.Account = ChartsOfAccounts._DemoMain.ProductStock;
	Movement.ExtDimensions.Counterparties  = Counterparty;
	Movement.ExtDimensions.Products = RowOfProduct.Products;
	Movement.ExtDimensions.Warehouses       = StorageLocation;	
	Movement.Count = RowOfProduct.Count;
	
EndProcedure

Procedure GenerateMovementOfAccountingForAccruedVATAccordingToBasicRegisterWithoutCorrespondence(Val RowOfProduct, Val ItemKinds)
	
	RubleAmount = RowOfProduct.Price * RowOfProduct.Count;
	VATAmount = RubleAmount / 100 * Common.ObjectAttributeValue(VATRate, "Rate1");
	Product_Category = Product_Category(RowOfProduct.Products, ItemKinds);
	
	Values = New Structure;
	Values.Insert("Content", "ru = 'Реализация товаров';
									|en = 'Goods sales';"); // @NStr-2
	
	Movement = RegisterRecords._DemoAccountingEntriesJournalWithoutCorrespondence.Add();
	Movement.Period      = Date;
	Movement.Organization = ParentCompany;
	Movement.Sum       = VATAmount;
	Movement.Account = ChartsOfAccounts._DemoMain.Sales_VAT;
	Movement.ExtDimensions.ProductRangeGroups = Product_Category; 
	Common.SetAttributesValues(Movement, Values);
	
	Movement = RegisterRecords._DemoAccountingEntriesJournalWithoutCorrespondence.Add();
	Movement.Period      = Date;
	Movement.Organization = ParentCompany;
	Movement.Sum       = VATAmount;
	Movement.Account = ChartsOfAccounts._DemoMain.VAT;
	Movement.ExtDimensions.PaymentsToBudgetTypes = Enums._DemoBudgetPaymentKinds.Tax;		
	Common.SetAttributesValues(Movement, Values);
	
EndProcedure

Function Product_Category(Val Products, Val ItemKinds)
	Product_Category = ItemKinds[Products];
	If Product_Category <> Undefined Then
		Product_Category = Common.ObjectAttributeValue(Products, "ProductKind");
		ItemKinds[Products] = Product_Category;
	EndIf;
	Return Product_Category;
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf