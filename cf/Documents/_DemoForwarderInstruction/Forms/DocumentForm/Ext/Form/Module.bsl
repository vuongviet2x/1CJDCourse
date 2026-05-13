///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		Object.ExecutionDate = BegOfDay(CurrentSessionDate());
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_InstructionForShippingAgent", WriteParameters, Object.Ref);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PointOnChange(Item)
	ItemWhenChangingOnServer();
EndProcedure

&AtClient
Procedure PointStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ShowChooseFromList(New NotifyDescription("ItemStartSelectionStartSelectionEnd", ThisObject), PointsSelectionList, Item);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	
	If Object.ExecutionDate < Object.Date Then
		Object.ExecutionDate = Object.Date;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	If Not ValueIsFilled(Object.EmployeeResponsible) Then
		Object.EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
	PointsSelectionList.Clear();
	If AccessRight("View", Metadata.Catalogs._DemoPartners) Then
		PointsSelectionList.Add("SelectPartner", NStr("ru = '<Выбрать партнера>';
															|en = '<Select a partner>';"));
	EndIf;
	If AccessRight("View", Metadata.Catalogs._DemoStorageLocations) Then
		PointsSelectionList.Add("ChooseStorageLocation", NStr("ru = '<Выбрать место хранения>';
																	|en = '<Select storage location>';"));
	EndIf;
	PointsSelectionList.Add("EnterArbitraryText", NStr("ru = '<Ввести произвольный текст>';
																|en = '<Type any text>';"));
	
	SetItemsAvailability();
	
EndProcedure

&AtServer
Procedure ItemWhenChangingOnServer()
	
	Items.ItemAddress.ChoiceList.Clear();
	
	CheckFillInContactPerson();
	
	SetItemsAvailability();
	
EndProcedure

&AtServer
Procedure SetItemsAvailability()
	
	Items.ContactPerson.Enabled = (TypeOf(Object.Point) = Type("CatalogRef._DemoPartners"));
	
EndProcedure

&AtServer
Procedure CheckFillInContactPerson()
	
	If TypeOf(Object.Point) <> Type("CatalogRef._DemoPartners") Then
		Object.ContactPerson = Catalogs._DemoPartnersContactPersons.EmptyRef();
	EndIf;
	
EndProcedure

&AtClient
Procedure ItemStartSelectionStartSelectionEnd(SelectedElement, AdditionalParameters) Export
	
	If SelectedElement = Undefined Then
		Return;
	EndIf;
	
	ValueSelected = SelectedElement.Value;
	NotifyDescription = New NotifyDescription("AfterSelectingItem",ThisObject);
	
	If ValueSelected = Undefined Then
		Return;
		
	ElsIf ValueSelected = "SelectPartner" Then
		OpenForm("Catalog._DemoPartners.ChoiceForm",,ThisObject,,,,
			NotifyDescription,FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf ValueSelected = "ChooseStorageLocation" Then
		OpenForm("Catalog._DemoStorageLocations.ChoiceForm",,ThisObject,,,,
			NotifyDescription,FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf ValueSelected = "EnterArbitraryText" Then
		Object.Point = "";
	Else
		Object.Point = ValueSelected;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterSelectingItem(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	Object.Point = ValueSelected;
	ItemWhenChangingOnServer();
	
EndProcedure

#EndRegion
