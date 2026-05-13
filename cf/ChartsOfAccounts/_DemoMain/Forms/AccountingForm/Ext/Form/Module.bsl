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
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.ObjectAttributesLock

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ObjectAttributesLockClient.AllowObjectAttributeEdit(ThisObject);
	
EndProcedure

// End StandardSubsystems.ObjectAttributesLock

#EndRegion
