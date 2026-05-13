///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.NationalLanguageSupport
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.NationalLanguageSupport

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.NationalLanguageSupport
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.NationalLanguageSupport
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.NationalLanguageSupport
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.NationalLanguageSupport
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.NationalLanguageSupport
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.NationalLanguageSupport

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	// StandardSubsystems.NationalLanguageSupport
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.NationalLanguageSupport

EndProcedure

#EndRegion

