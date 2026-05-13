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
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ListReadingAllowed(RefType)
	|	AND ValueAllowed(Organization)
	|	AND ValueAllowed(StorageLocation)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

// Parameters:
//   Document - DocumentObject
//
Procedure UpdateWarehouseDocumentsRegistry(Document) Export
	
	SetPrivilegedMode(True);
	
	If Common.IsReference(TypeOf(Document)) Then
		Ref = Document;
		
		Attributes = "Ref, DeletionMark, Posted, Date, Number, Organization, EmployeeResponsible, Comment";
		
		If TypeOf(Ref) = Type("DocumentRef._DemoInventoryTransfer") Then
			Attributes = Attributes + ", StorageSource, StorageLocationDestination";
		Else
			Attributes = Attributes + ", StorageLocation";
		EndIf;
		
		Data = Common.ObjectAttributesValues(Ref, Attributes);
		If Not ValueIsFilled(Data.Ref) Then
			Return; // The object is deleted, 1C:Enterprise deletes the linked record.
		EndIf;
	Else
		Ref = Document.Ref;
		Data = Document;
	EndIf;
	
	RecordSet = CreateRecordSet();
	RecordSet.Filter.Ref.Set(Ref);
	Record = RecordSet.Add();
	FillPropertyValues(Record, Data);
	Record.RefType = Common.MetadataObjectID(TypeOf(Record.Ref));
	
	If TypeOf(Ref) = Type("DocumentRef._DemoInventoryTransfer") Then
		Record.StorageLocation = Data.StorageSource;
		// Additional record for the transfer operation.
		SecondRecord = RecordSet.Add();
		FillPropertyValues(SecondRecord, Data);
		SecondRecord.RefType = Record.RefType;
		SecondRecord.StorageLocation = Data.StorageLocationDestination;
		SecondRecord.AdditionalRecord = True;
	EndIf;
	
	RecordSet.Write();
	
EndProcedure

#EndRegion

#EndIf
