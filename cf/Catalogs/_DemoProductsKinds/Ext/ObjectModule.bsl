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

#Region EventHandlers

Procedure OnCopy(CopiedObject)

	PropertiesSet = Undefined;

EndProcedure

Procedure BeforeWrite(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteObjectKind(ThisObject, "Catalog__DemoProducts");
	// End StandardSubsystems.Properties

EndProcedure

Procedure BeforeDelete(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeDeleteObjectKind(ThisObject);
	// End StandardSubsystems.Properties

EndProcedure

#EndRegion

#Else
	Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
							|en = 'Invalid object call on the client.';");
#EndIf