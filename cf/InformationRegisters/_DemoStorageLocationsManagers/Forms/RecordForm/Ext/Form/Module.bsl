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
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Record);
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	NationalLanguageSupportClient.OnOpen(ThisObject, Record, Item, StandardProcessing);
EndProcedure

#EndRegion

