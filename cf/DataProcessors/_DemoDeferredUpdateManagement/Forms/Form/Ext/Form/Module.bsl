///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	GenerateOrdersAtServer();
EndProcedure

&AtClient
Procedure CloseForm(Command)
	Close();
EndProcedure

&AtClient
Procedure ClearChanges(Command)
	ResetChangesAtServer();
EndProcedure

&AtClient
Procedure OpenDeferredUpdateStartForm(Command)
	OpenForm("DataProcessor.ApplicationUpdateResult.Form.ApplicationUpdateResult");
EndProcedure

&AtClient
Procedure ClearUpdateInformation(Command)
	
	ResetUpdateInfoAtServer();
	
EndProcedure

&AtClient
Procedure LockObject(Command)
	LockObjectAtServer();
EndProcedure

&AtClient
Procedure AddErrorOnDeferredUpdate(Command)
	
	AddErrorAtServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AddErrorAtServer()
	
	Common.CommonSettingsStorageSave("DeferredIBUpdate", "SimulateError", True,, UserName());
	
EndProcedure

&AtServer
Procedure GenerateOrdersAtServer()
	
	// Get currencies.
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Currencies.Ref AS Ref
	|FROM
	|	Catalog.Currencies AS Currencies";
	Currencies = Query.Execute().Unload();
	
	// Get a company.
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	Companies.Ref AS Ref
	|FROM
	|	Catalog._DemoCompanies AS Companies";
	Companies = Query.Execute().Unload();
	
	// Get a partner.
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	_DemoPartners.Ref
	|FROM
	|	Catalog._DemoPartners AS _DemoPartners";
	Partners = Query.Execute().Unload();
	
	// Get a counterparty.
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	_DemoCounterparties.Ref
	|FROM
	|	Catalog._DemoCounterparties AS _DemoCounterparties";
	Counterparties = Query.Execute().Unload();
	
	// Get contracts.
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	_DemoCounterpartiesContracts.Ref
	|FROM
	|	Catalog._DemoCounterpartiesContracts AS _DemoCounterpartiesContracts";
	Contracts = Query.Execute().Unload();
	
	DeliveryAddress = "<ContactInformation xmlns=""http://www.v8.1c.ru/ssl/contactinfo"""
		+ " xmlns:xs=""http://www.w3.org/2001/XMLSchema"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"""
		+ " Presentation=""127434, MOSCOW g, Dmitrovskoe motorway, house № 9""><Comment/><Content xsi:type=""Address"""
		+ " Country=""RUSSIA""><Content xsi:type=""LocalAddress""><TerritorialEntity>MOSCOW g</TerritorialEntity><County/><MunicipalEntityDistrictProperty><District/>"
		+ "</MunicipalEntityDistrictProperty><City/><Settlmnt/><Street>Dmitrovskoe motorway</Street><MUNICIPALTERRITORIESCLASSIFIER>0</MUNICIPALTERRITORIESCLASSIFIER><AddlAddressItem><Number Type=""1010"""
		+ " Value=""9""/></AddlAddressItem><AddlAddressItem AddressItemType2=""10100000"" Value=""127434""/></Content></Content></ContactInformation>";
	
	IndexOf = 1;
	BeginTransaction();
	Try
		While IndexOf <= OrdersCount Do
			NewDoc = Documents._DemoSalesOrder.CreateDocument();
			IndexOf = IndexOf + 1;
			NewDoc.Date = CreationDate;
			NewDoc.DeleteOrderClosed = OrderClosed;
			NewDoc.Posted = OrderPosted;
			
			RNG = New RandomNumberGenerator;
			NewDoc.Currency = Currencies.Get(RNG.RandomNumber(0, Currencies.Count() - 1)).Ref;
			NewDoc.Organization = Companies.Get(0).Ref;
			NewDoc.Partner = Partners.Get(0).Ref;
			NewDoc.Counterparty = Counterparties.Get(0).Ref;
			NewDoc.Contract = Contracts.Get(0).Ref;
			NewDoc.DocumentAmount = RNG.RandomNumber(100, 1000);
			NewDoc.Comment = NStr("ru = 'Комментарий документа';
										|en = 'Document comment';");
			
			NewDoc.DeliveryAddress = DeliveryAddress;
			NewDoc.DeliveryAddressString = "";
			
			NewDoc.Write();
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtServer
Procedure ResetChangesAtServer()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	_DemoSalesOrder.Ref AS Ref
	|FROM
	|	Document._DemoSalesOrder AS _DemoSalesOrder";
	Result = Query.Execute().Unload();
	
	DeliveryAddress = "<ContactInformation xmlns=""http://www.v8.1c.ru/ssl/contactinfo"""
		+ " xmlns:xs=""http://www.w3.org/2001/XMLSchema"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"""
		+ " Presentation=""127434, MOSCOW g, Dmitrovskoe motorway, house № 9""><Comment/><Content xsi:type=""Address"""
		+ " Country=""RUSSIA""><Content xsi:type=""LocalAddress""><TerritorialEntity>MOSCOW g</TerritorialEntity><County/><MunicipalEntityDistrictProperty><District/>"
		+ "</MunicipalEntityDistrictProperty><City/><Settlmnt/><Street>Dmitrovskoe motorway</Street><MUNICIPALTERRITORIESCLASSIFIER>0</MUNICIPALTERRITORIESCLASSIFIER><AddlAddressItem><Number Type=""1010"""
		+ " Value=""9""/></AddlAddressItem><AddlAddressItem AddressItemType2=""10100000"" Value=""127434""/></Content></Content></ContactInformation>";
	
	For Each DocumentRef In Result Do
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add("Document._DemoSalesOrder");
			LockItem.SetValue("Ref", DocumentRef.Ref);
			Block.Lock();
			
			DocumentObject = DocumentRef.Ref.GetObject();
			DocumentObject.DataExchange.Load = True;
			DocumentObject.OrderStatus = Enums._DemoCustomerOrderStatuses.EmptyRef();
			DocumentObject.DeliveryAddress = DeliveryAddress;
			DocumentObject.DeliveryAddressString = "";
			DocumentObject.Write();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
EndProcedure

&AtServer
Procedure ResetUpdateInfoAtServer()
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	
	UpdateInfo.SessionNumber = New ValueList;
	UpdateInfo.DeferredUpdateStartTime = Undefined;
	UpdateInfo.DeferredUpdatesEndTime = Undefined;
	UpdateInfo.DeferredUpdateCompletedSuccessfully = Undefined;
	Constants.DeferredUpdateCompletedSuccessfully.Set(False);
	
	InfobaseUpdateInternal.WriteInfobaseUpdateInfo(UpdateInfo);
	
	BeginTransaction();
	Try
		Block = New DataLock;
		Block.Add("InformationRegister.UpdateHandlers");
		Block.Lock();
		
		SetOfHandlers = InformationRegisters.UpdateHandlers.CreateRecordSet();
		SetOfHandlers.Read();
		For Each Handler In SetOfHandlers Do
			Handler.Status = Enums.UpdateHandlersStatuses.NotPerformed;
		EndDo;
		SetOfHandlers.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	LockedObjectsInfo = InfobaseUpdateInternal.LockedObjectsInfo();
	Handlers = LockedObjectsInfo.Handlers;
	For Each KeyAndValue In Handlers Do
		KeyAndValue.Value.Completed = False;
	EndDo;
	InfobaseUpdateInternal.WriteLockedObjectsInfo(LockedObjectsInfo);
	
	InfobaseUpdateInternal.ReregisterDataForDeferredUpdate();
	
EndProcedure

&AtServer
Procedure LockObjectAtServer()
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	_DemoSalesOrder.Ref AS Ref
	|FROM
	|	Document._DemoSalesOrder AS _DemoSalesOrder
	|WHERE
	|	_DemoSalesOrder.OrderStatus = VALUE(Enum._DemoCustomerOrderStatuses.EmptyRef)";
	
	Result = Query.Execute().Unload();
	For Each BuyerSOrder In Result Do
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add("Document._DemoSalesOrder");
			LockItem.SetValue("Ref", BuyerSOrder.Ref);
			Block.Lock();
			
			NewDate = CurrentSessionDate() + 10*60;
			While NewDate >= CurrentSessionDate() Do
				// Lock a document for 10 minutes.
			EndDo;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
EndProcedure

#EndRegion
