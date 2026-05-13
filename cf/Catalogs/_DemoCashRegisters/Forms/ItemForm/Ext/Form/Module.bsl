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
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock

	If Common.IsMobileClient() Then
		Items.Description.TitleLocation = FormItemTitleLocation.Top;
	EndIf;

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	If Object.AcceptRevenueAsTotalAmount Then
		AcceptRevenueAsTotalAmountRadioButton = "AsTotalAmount";
	Else
		AcceptRevenueAsTotalAmountRadioButton = "Separately";
	EndIf;
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	If AcceptRevenueAsTotalAmountRadioButton = "AsTotalAmount" Then
		CurrentObject.AcceptRevenueAsTotalAmount = True;
	Else
		CurrentObject.AcceptRevenueAsTotalAmount = False;
	EndIf;

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.ObjectAttributesLock
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)

	ObjectAttributesLockClient.AllowObjectAttributeEdit(ThisObject);

EndProcedure
// End StandardSubsystems.ObjectAttributesLock

#EndRegion