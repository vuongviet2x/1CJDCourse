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
	// "Read": Company AND Partner.
	// "Edit": Company AND Partner.
	
	// Read, Update: Set #1.
	String = Table.Add();
	String.AccessValue = Organization;
	
	String = Table.Add();
	String.AccessValue = Partner;
	
EndProcedure 

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array();
	If DocumentAmount = 0 Then
		
		Message = New UserMessage();
    	Message.Text = NStr("ru = 'Не указана сумма документа.';
								|en = 'Document amount is not specified.';");
    	Message.Field = "DocumentAmount";
    	Message.SetData(ThisObject);
        Message.Message();
		
		Cancel = True;
		AttributesNotToCheck.Add("DocumentAmount");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	If FillingData = Undefined Then // Create a new item.
		_DemoStandardSubsystems.OnEnterNewItemFillCompany(ThisObject);
	EndIf;
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	// Demo of API that processes local objects.
	BeforeWriteLocalContactInformation();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Interactions.SetActiveFlag(Ref,Not DeleteOrderClosed);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	RegisterRecords.Write();
	
EndProcedure

#EndRegion

#Region Private

// Sets auxiliary attributes by data of object header contact information.
//
Procedure BeforeWriteLocalContactInformation()
	
	// 1. Address.
	DeliveryCountryStructure = ContactsManager.ContactInformationAddressCountry(DeliveryAddress);
	DeliveryCountry = DeliveryCountryStructure.Ref;
	
	// 2. Email.
	ServerDomainName = ContactsManager.ContactInformationAddressDomain(Email);
	
	DeliveryAddressString = ContactsManager.ContactInformationPresentation(DeliveryAddress);
	EmailString = ContactsManager.ContactInformationPresentation(Email);
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf