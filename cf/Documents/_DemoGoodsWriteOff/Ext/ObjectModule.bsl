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

// StandardSubsystems.AccessManagement

// Parameters:
//   Table - See AccessManagement.AccessValuesSetsTable
//
Procedure FillAccessValuesSets(Table) Export
	
	// The restriction logic:
	// "Read": Company AND StorageLocation.
	// "Update": Company AND StorageLocation AND EmployeeResponsible.
	
	// Read: Set #1.
	String = Table.Add();
	String.SetNumber     = 1;
	String.Read          = True;
	String.AccessValue = Organization;
	
	String = Table.Add();
	String.SetNumber     = 1;
	String.AccessValue = StorageLocation;
	
	// Update: Set #2.
	String = Table.Add();
	String.SetNumber     = 2;
	String.Update       = True;
	String.AccessValue = Organization;
	
	String = Table.Add();
	String.SetNumber     = 2;
	String.AccessValue = StorageLocation;
	
	String = Table.Add();
	String.SetNumber     = 2;
	String.AccessValue = EmployeeResponsible;
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If FillingData = Undefined Then // Create a new item.
		_DemoStandardSubsystems.OnEnterNewItemFillCompany(ThisObject);
	EndIf;
	
	If TypeOf(FillingData) = Type("DocumentRef._DemoGoodsReceipt") Then
		DocumentBasis = FillingData.GetObject();
		FillPropertyValues(ThisObject, DocumentBasis, "Organization,StorageLocation");
		EmployeeResponsible = Users.CurrentUser();
		For Each LineProducts_ In DocumentBasis.Goods Do
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, LineProducts_);
		EndDo;
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	GenerateRegisterRecordsByStorageLocations();
	
EndProcedure

#EndRegion

#Region Private

Procedure GenerateRegisterRecordsByStorageLocations()
	
	RegisterRecords._DemoGoodsBalancesInStorageLocations.Write = True;
	
	For Each LineProducts_ In Goods Do
		
		Movement = RegisterRecords._DemoGoodsBalancesInStorageLocations.Add();
		
		Movement.Period        = Date;
		Movement.RecordType   = AccumulationRecordType.Expense;
		
		Movement.Organization   = Organization;
		Movement.StorageLocation = StorageLocation;
		
		Movement.Products  = LineProducts_.Products;
		Movement.Count    = LineProducts_.Count;
	EndDo;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf