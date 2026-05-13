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
	
	If Parameters.ChoiceMode Then
		Items.List.ChoiceMode = True;
	EndIf;
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.DuplicateObjectsDetection

&AtClient
Procedure MergeSelectedItems(Command)
	
	DuplicateObjectsDetectionClient.MergeSelectedItems(Items.List);
	
EndProcedure

&AtClient
Procedure ShowUsageInstances(Command)
	
	DuplicateObjectsDetectionClient.ShowUsageInstances(Items.List);
	
EndProcedure

// End StandardSubsystems.DuplicateObjectsDetection

#EndRegion