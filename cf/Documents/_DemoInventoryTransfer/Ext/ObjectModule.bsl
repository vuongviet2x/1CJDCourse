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
	// "Read": Company AND (StorageLocation OR StorageLocationDestination).
	// "Edit": Company AND StorageLocation AND StorageLocationDestination AND EmployeeResponsible.
	
	// Read: Set #1.
	String = Table.Add();
	String.SetNumber     = 1;
	String.Read          = True;
	String.AccessValue = Organization;
	
	String = Table.Add();
	String.SetNumber     = 1;
	String.AccessValue = StorageSource;
	
	// Read: Set #2.
	String = Table.Add();
	String.SetNumber     = 2;
	String.Read          = True;
	String.AccessValue = Organization;
	
	String = Table.Add();
	String.SetNumber     = 2;
	String.AccessValue = StorageLocationDestination;
	
	// Update: Set #3.
	String = Table.Add();
	String.SetNumber     = 3;
	String.Update       = True;
	String.AccessValue = Organization;
	
	String = Table.Add();
	String.SetNumber     = 3;
	String.AccessValue = StorageSource;
	
	String = Table.Add();
	String.SetNumber     = 3;
	String.AccessValue = StorageLocationDestination;
	
	String = Table.Add();
	String.SetNumber     = 3;
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
		DocumentObject = FillingData.GetObject();
		
		Organization = DocumentObject.Organization;
		StorageSource = DocumentObject.StorageLocation;
		EmployeeResponsible = Users.CurrentUser();
		For Each LineProducts_ In DocumentObject.Goods Do
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, LineProducts_);
		EndDo;
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	GenerateRegisterRecordsToDocumentsRegistry();

	GenerateRegisterRecordsByStorageLocations();
	
EndProcedure

#EndRegion

#Region Private

Procedure GenerateRegisterRecordsToDocumentsRegistry()
	
	SetPrivilegedMode(True);

	Movement = InformationRegisters._DemoDocumentsRegistry.CreateRecordManager();
	Movement.RefType = Common.MetadataObjectID(Ref.Metadata());
	Movement.Organization = Organization;
	Movement.StorageLocation = StorageLocationDestination;
	Movement.IBDocumentDate = Date;
	Movement.Ref = Ref;
	Movement.IBDocumentNumber = Number;
	Movement.EmployeeResponsible = EmployeeResponsible;
	Movement.More = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Перемещение с ""%1""';
																							|en = 'Transfer from ""%1""';"),
		StorageSource);
	Movement.Comment = Comment;
	Movement.Posted = True;
	Movement.DeletionMark = False;
	Movement.SourceDocumentDate = Date;
	Movement.SourceDocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Number, True, True);
	Movement.RecordingInAccountingDate = Date;
	Movement.Write();

EndProcedure

Procedure GenerateRegisterRecordsByStorageLocations()
	
	RegisterRecords._DemoGoodsBalancesInStorageLocations.Write = True;
	
	For Each LineProducts_ In Goods Do
		
		Movement = RegisterRecords._DemoGoodsBalancesInStorageLocations.Add();
		
		Movement.Period        = Date;
		Movement.RecordType   = AccumulationRecordType.Expense;
		
		Movement.Organization   = Organization;
		Movement.StorageLocation = StorageSource;
		
		Movement.Products  = LineProducts_.Products;
		Movement.Count    = LineProducts_.Count;
		
		Movement = RegisterRecords._DemoGoodsBalancesInStorageLocations.Add();
		
		Movement.Period        = Date;
		Movement.RecordType   = AccumulationRecordType.Receipt;
		
		Movement.Organization   = Organization;
		Movement.StorageLocation = StorageLocationDestination;
		
		Movement.Products  = LineProducts_.Products;
		Movement.Count    = LineProducts_.Count;
	EndDo;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf