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
	FillPropertyValues(ThisObject, FormAttributeToValue("Object").DefaultSettings());
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure StartWithControl(Command)
	CheckFilling = True;
	StartAtClient();
EndProcedure

&AtClient
Procedure StartWithoutControl(Command)
	CheckFilling = False;
	StartAtClient();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure StartAtClient()
	
	StartAtServer();
	
	NotifyChanged(Type("CatalogRef._DemoProducts"));
	If InformationRegistersUsage Then
		NotifyChanged(Type("CatalogRef._DemoCompanies"));
		NotifyChanged(Type("CatalogRef._DemoDepartments"));
		NotifyChanged(Type("CatalogRef.Users"));
	EndIf;
	
	If SimpleDuplicatesUsage Or AccumulationRegistersUsage Then
		FormParameters = New Structure("DuplicatesSearchArea", "Catalog._DemoProducts");
		OpenForm("DataProcessor.DuplicateObjectsDetection.Form.SearchForDuplicates", FormParameters, , True, , , , FormWindowOpeningMode.Independent);
	EndIf;
	
	If InformationRegistersUsage Then
		FormParameters = New Structure("DuplicatesSearchArea", "Catalog._DemoIndividuals");
		OpenForm("DataProcessor.DuplicateObjectsDetection.Form.SearchForDuplicates", FormParameters, , True, , , , FormWindowOpeningMode.Independent);
		
		FormParameters = New Structure("DuplicatesSearchArea", "Catalog.Users");
		OpenForm("DataProcessor.DuplicateObjectsDetection.Form.SearchForDuplicates", FormParameters, , True, , , , FormWindowOpeningMode.Independent);
	EndIf;
	
EndProcedure

&AtServer
Procedure StartAtServer()
	FormAttributeToValue("Object").Generate(ThisObject);
EndProcedure

#EndRegion
