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
		_DemoStandardSubsystems.OnEnterNewItemFillCompany(ThisObject);
	EndIf;
EndProcedure

Procedure OnCopy(CopiedObject)
	TaxInvoice = Undefined;
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	GenerateRegisterRecordsByStorageLocations();
	
	GenerateAccountingRegisteredRecords();
	
EndProcedure

#EndRegion

#Region Private

Procedure GenerateRegisterRecordsByStorageLocations()
	
	RegisterRecords._DemoGoodsBalancesInStorageLocations.Write = True;
	
	For Each LineProducts_ In Goods Do
		
		Movement = RegisterRecords._DemoGoodsBalancesInStorageLocations.Add();
		
		Movement.Period        = Date;
		Movement.RecordType   = AccumulationRecordType.Receipt;
		
		Movement.Organization   = Organization;
		Movement.StorageLocation = StorageLocation;
		
		Movement.Products  = LineProducts_.Products;
		Movement.Count    = LineProducts_.Count;
		
	EndDo;
	
EndProcedure

Procedure GenerateAccountingRegisteredRecords()
	
	ForeignExchangeDocument = Common.ObjectAttributeValue(Currency, "Code") <> "643";
	If Currency.IsEmpty() Then
		DocumentCurrency  = New Structure("Rate, Repetition", 1, 1,);
	Else
		DocumentCurrency  = CurrencyRateOperations.GetCurrencyRate(Currency, Date);
	EndIf;
	
	ProcessVAT = ConsiderVAT And Not ForeignExchangeDocument;
	
	RegisterRecords._DemoAccountingTransactionLog.Write = True;
	RegisterRecords._DemoAccountingEntriesJournalWithoutCorrespondence.Write = True;
	
	For Each RowOfProduct In Goods Do
		
		GenerateMovementOfReceiptOfGoodsByRegisterOfMain(RowOfProduct, ForeignExchangeDocument, DocumentCurrency);   
		ToFormMovementOfReceiptOfGoodsByRegisterOfMainWithoutCorrespondence(RowOfProduct, ForeignExchangeDocument, DocumentCurrency);
		
		If ProcessVAT Then
			GenerateMovementOfIncomingVATAccountingAccordingToBasicRegister(RowOfProduct); 
			GenerateMovementOfIncomingVATAccordingToBasicRegisterWithoutCorrespondence(RowOfProduct);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure GenerateMovementOfReceiptOfGoodsByRegisterOfMain(Val RowOfProduct, Val CurrencyAccounting, Val DocumentCurrency)
	
	CurrencyAmount = RowOfProduct.Price * RowOfProduct.Count;
	RubleAmount = CurrencyAmount * DocumentCurrency.Rate / DocumentCurrency.Repetition;
	
	Movement = RegisterRecords._DemoAccountingTransactionLog.Add();
	Movement.Period      = Date;
	Movement.Organization = Organization;
	Movement.Content  = NStr("ru = 'Поступление товаров';
								|en = 'Receipt of goods';");
	Movement.Sum       = RubleAmount;
	
	Movement.AccountDr = ChartsOfAccounts._DemoMain.ProductStock;
	
	Movement.ExtDimensionsDr.Counterparties  = Counterparty;
	Movement.ExtDimensionsDr.Products = RowOfProduct.Products;
	Movement.ExtDimensionsDr.Warehouses       = StorageLocation;
	
	Movement.CountDr = RowOfProduct.Count;
	
	If CurrencyAccounting Then
		Movement.AccountCr          = ChartsOfAccounts._DemoMain.SettlementsWithSuppliersCurr;
		Movement.CurrencyCr        = Currency;
		Movement.CurrencyAmountCr = CurrencyAmount;
	Else
		Movement.AccountCr = ChartsOfAccounts._DemoMain.VendorsARAPAccounting;
	EndIf;
	
	Movement.ExtDimensionsCr.Counterparties = Counterparty;
	Movement.ExtDimensionsCr.Contracts    = Contract;
	
	Movement.CountCr = RowOfProduct.Count;
	
EndProcedure

Procedure GenerateMovementOfIncomingVATAccountingAccordingToBasicRegister(Val RowOfProduct)
	
	RubleAmount = RowOfProduct.Price * RowOfProduct.Count;
	VATAmount = RubleAmount / 100 * Common.ObjectAttributeValue(VATRate, "Rate1");
	
	Movement = RegisterRecords._DemoAccountingTransactionLog.Add();
	Movement.Period      = Date;
	Movement.Organization = Organization;
	Movement.Content  = NStr("ru = 'Поступление товаров';
								|en = 'Receipt of goods';");
	Movement.Sum       = VATAmount;
	
	Movement.AccountDr = ChartsOfAccounts._DemoMain.VATOnPurchasedInventory;
	Movement.ExtDimensionsDr.Counterparties = Counterparty;
	
	Movement.AccountCr = ChartsOfAccounts._DemoMain.VendorsARAPAccounting;
	Movement.ExtDimensionsCr.Counterparties = Counterparty;
	Movement.ExtDimensionsCr.Contracts    = Contract;
	
EndProcedure

Procedure ToFormMovementOfReceiptOfGoodsByRegisterOfMainWithoutCorrespondence(Val RowOfProduct, Val CurrencyAccounting, Val DocumentCurrency)
	
	CurrencyAmount = RowOfProduct.Price * RowOfProduct.Count;
	RubleAmount = CurrencyAmount * DocumentCurrency.Rate / DocumentCurrency.Repetition;
	
	Movement = RegisterRecords._DemoAccountingEntriesJournalWithoutCorrespondence.Add();
	Movement.Period      = Date;
	Movement.Organization = Organization;
	Movement.Content  = NStr("ru = 'Поступление товаров';
								|en = 'Receipt of goods';");
	Movement.Sum       = RubleAmount;	
	Movement.Account = ChartsOfAccounts._DemoMain.ProductStock;	
	Movement.ExtDimensions.Counterparties  = Counterparty;
	Movement.ExtDimensions.Products = RowOfProduct.Products;
	Movement.ExtDimensions.Warehouses       = StorageLocation;	
	Movement.Count = RowOfProduct.Count;
		
	Movement = RegisterRecords._DemoAccountingEntriesJournalWithoutCorrespondence.Add();
	Movement.Period      = Date;
	Movement.Organization = Organization;
	Movement.Content  = NStr("ru = 'Поступление товаров';
								|en = 'Receipt of goods';");
	Movement.Sum       = RubleAmount;	
	
	If CurrencyAccounting Then
		Movement.Account          = ChartsOfAccounts._DemoMain.SettlementsWithSuppliersCurr;
		Movement.Currency        = Currency;
		Movement.CurrencyAmount = CurrencyAmount;
	Else
		Movement.Account = ChartsOfAccounts._DemoMain.VendorsARAPAccounting;
	EndIf;
	
	Movement.ExtDimensions.Counterparties = Counterparty;
	Movement.ExtDimensions.Contracts    = Contract;
	
	Movement.Count = RowOfProduct.Count; 
		
EndProcedure

Procedure GenerateMovementOfIncomingVATAccordingToBasicRegisterWithoutCorrespondence(Val RowOfProduct)
	
	RubleAmount = RowOfProduct.Price * RowOfProduct.Count;
	VATAmount = RubleAmount / 100 * Common.ObjectAttributeValue(VATRate, "Rate1");
	
	Movement = RegisterRecords._DemoAccountingEntriesJournalWithoutCorrespondence.Add();
	Movement.Period      = Date;
	Movement.Organization = Organization;
	Movement.Content  = NStr("ru = 'Поступление товаров';
								|en = 'Receipt of goods';");
	Movement.Sum       = VATAmount;
	Movement.Account = ChartsOfAccounts._DemoMain.VATOnPurchasedInventory;
	Movement.ExtDimensions.Counterparties = Counterparty;      
	
	Movement = RegisterRecords._DemoAccountingEntriesJournalWithoutCorrespondence.Add();
	Movement.Period      = Date;
	Movement.Organization = Organization;
	Movement.Content  = NStr("ru = 'Поступление товаров';
								|en = 'Receipt of goods';");
	Movement.Sum       = VATAmount;	
	Movement.Account = ChartsOfAccounts._DemoMain.VendorsARAPAccounting;
	Movement.ExtDimensions.Counterparties = Counterparty;
	Movement.ExtDimensions.Contracts    = Contract;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf