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

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.LockedAttributes = Undefined Then
		AttributesToLock = ObjectAttributesLock.ObjectAttributesToLock(Metadata.Documents._DemoSalesOrder.FullName());
		Parameters.LockedAttributes = New FixedArray(AttributesToLock);
	EndIf;
	
	For Each Attribute In Parameters.LockedAttributes Do
		Items[Attribute].Visible = True;
	EndDo;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	EndIf;
	
EndProcedure

&AtClient
Procedure EnableEdit(Command)
	
	AttributesToUnlock = New Array;
	
	For Each Attribute In Parameters.LockedAttributes Do
		If Items[Attribute].Visible And ThisObject[Attribute] Then
			AttributesToUnlock.Add(Attribute);
		EndIf;
	EndDo;
	
	Close(AttributesToUnlock);
	
EndProcedure

#EndRegion
