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
	
#Region Private

Procedure ExecuteAction(Parameters, ResultAddress) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DemoTimeConsumingOperationMeasurement1");
	MeasurementDetailsVariant2 = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DemoTimeConsumingOperationMeasurementOption2");
	CounterpartiesCount = Parameters.CounterpartiesCount;
	CounterpartyBankAccountCount = Parameters.CounterpartyBankAccountCount;
	DeleteCreatedObjects = Parameters.DeleteCreatedObjects;
	
	NameOfTheCounterparty = NStr("ru = 'Контрагент %1';
									|en = 'Counterparty %1';");
	NameOfAccount = NStr("ru = 'Банковский счет контрагента %1';
							|en = 'Counterparty bank account %1';");
	ObjectsArray = New Array;
	
	BeginTransaction();
	Try
		For CounterpartyCounter = 1 To CounterpartiesCount Do
			CounterpartyObject = Catalogs._DemoCounterparties.CreateItem();
			
			CounterpartyObject.Description = StringFunctionsClientServer.SubstituteParametersToString(NameOfTheCounterparty, Format(CounterpartyCounter, "NG="));
			CounterpartyObject.Write();
			PerformanceMonitor.FixTimeConsumingOperationMeasure(MeasurementDetails, 1, "CounterpartyRecord");
			ObjectsArray.Add(CounterpartyObject.Ref);
			For AccountCounter = 1 To CounterpartyBankAccountCount Do			
				ObjectAccount = Catalogs._DemoBankAccounts.CreateItem();
				ObjectAccount.Owner = CounterpartyObject.Ref;
				ObjectAccount.Description = StringFunctionsClientServer.SubstituteParametersToString(NameOfAccount, Format(CounterpartyCounter, "NG="));
				ObjectAccount.Write();                       
				PerformanceMonitor.FixTimeConsumingOperationMeasure(MeasurementDetails, 1, "WriteBankAccount");
			EndDo;
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
	EndTry;
		
	If DeleteCreatedObjects Then
		CounterpartiesTable = New ValueTable;
		CounterpartiesTable.Columns.Add("Counterparty", New TypeDescription("CatalogRef._DemoCounterparties"));
		CounterpartiesTable.LoadColumn(ObjectsArray, "Counterparty");
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add("Catalog._DemoCounterparties");
			LockItem.DataSource = CounterpartiesTable;
			LockItem.UseFromDataSource("Ref", "Counterparty");
			Block.Lock();
			For Each Item In ObjectsArray Do
				ObjectElement = Item.GetObject();
				ObjectElement.Delete();
			EndDo;	
			CommitTransaction();
		Except
			RollbackTransaction();
		EndTry;
	EndIf;
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, ObjectsArray.Count(), "DeleteCounterparties");
	TotalActions = CounterpartiesCount * (2 + CounterpartyBankAccountCount);
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetailsVariant2, TotalActions);
	
EndProcedure

#EndRegion

#EndIf
