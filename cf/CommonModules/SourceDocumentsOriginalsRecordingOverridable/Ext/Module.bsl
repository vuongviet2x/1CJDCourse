///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// Defines configuration objects whose list forms contain commands of source document tracking,
//
// Parameters:
//  ListOfObjects - Array of String - object managers with the AddPrintCommands procedure.
//
Procedure OnDefineObjectsWithOriginalsAccountingCommands(ListOfObjects) Export
	
	// _Demo Example Start
	ListOfObjects.Add("Document._DemoEmployeesLeaves.ListForm");
	ListOfObjects.Add("Document._DemoGoodsSales.ListForm");
	ListOfObjects.Add("Document._DemoInventoryTransfer.ListForm");
	ListOfObjects.Add("DataProcessor._DemoSourceDocumentsOriginalsRecordingJournal.Form.DocumentsList");
	// _Demo Example End

EndProcedure

// Determines configuration objects that should be tracked with a breakdown by employee.
//
// Parameters:
//  ListOfObjects - Map of KeyAndValue:
//          * Key - MetadataObject
//          * Value - String - a description of the table where employees are stored.
//
Procedure WhenDeterminingMultiEmployeeDocuments(ListOfObjects) Export
	
	// _Demo Example Start
	ListOfObjects.Insert(Metadata.Documents._DemoEmployeesLeaves.FullName(), "Employees_");
	// _Demo Example End

EndProcedure

// Fills in the originals recording table
// If you leave the procedure body blank - states will be tracked by all print forms of attached objects.
// If you add objects attached to the originals recording subsystem and their print forms to the value table,
// states will be tracked only by them.
//  
// Parameters:
//   AccountingTableForOriginals - ValueTable - a collection of objects and templates to track originals:
//              * MetadataObject - MetadataObject
//              * Id - String - a template ID.
//
// Example:
//	 NewRow = OriginalsRecordingTable.Add();
//	 NewRow.MetadataObject = Metadata.Documents.GoodsSales;
//	 NewRow.ID = "SalesInvoice";
//
Procedure FillInTheOriginalAccountingTable(AccountingTableForOriginals) Export	
	
	// _Demo Example Start
	NewRow = AccountingTableForOriginals.Add();
	NewRow.MetadataObject = Metadata.Documents._DemoGoodsSales;									
	NewRow.Id = "ExpenseToPrint";
	// _Demo Example End

EndProcedure

#EndRegion
