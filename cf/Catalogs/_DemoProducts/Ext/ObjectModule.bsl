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

#Region Variables

Var OldPrice;

#EndRegion

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.AccessManagement

// Parameters:
//   Table - See AccessManagement.AccessValuesSetsTable
//
Procedure FillAccessValuesSets(Table) Export
	
	// The restriction logic:
	// "Read": Unrestricted.
	// "Update": Unrestricted.
	
	// Read, Insert, Update: Set #0.
	String = Table.Add();
	String.AccessValue = Enums.AdditionalAccessValues.AccessAllowed;
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;

	OldPrice = Common.ObjectAttributeValue(Ref, "Price");

EndProcedure

Procedure OnWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;

	If OldPrice <> Price Then
		CurrentSessionDate = CurrentSessionDate();
		RecordSet = InformationRegisters._DemoProductsPrices.CreateRecordSet();
		RecordSet.Filter.Period.Set(CurrentSessionDate);
		RecordSet.Filter.Products.Set(Ref);
		Record = RecordSet.Add();
		Record.Period = CurrentSessionDate;
		Record.Products = Ref;
		Record.Price = Price;
		RecordSet.Write();
	EndIf;

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	// Check for duplicates by description and product type.
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Mode", "ControlByDescription");
	AdditionalParameters.Insert("Ref", Ref);

	Duplicates = DuplicateObjectsDetection.FindItemDuplicates(Metadata.Catalogs._DemoProducts.FullName(), ThisObject,
		AdditionalParameters);
	If Duplicates.Count() > 0 Then
		Error = NStr("ru = 'Номенклатура с таким наименованием и видом уже существует.';
						|en = 'Product with the same description and kind already exists.';");
		Common.MessageToUser(Error,, "Object.Description",, Cancel);
	EndIf;

	If IsFolder Then
		AttributesNotToCheck = New Array;
		AttributesNotToCheck.Add("ProductKind");
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	EndIf;

EndProcedure

Procedure OnReadPresentationsAtServer() Export
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
EndProcedure

#EndRegion

#Else
	Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
							|en = 'Invalid object call on the client.';");
#EndIf