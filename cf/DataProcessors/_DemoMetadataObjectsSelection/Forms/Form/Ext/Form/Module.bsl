///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SelectedObjectStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	FormParameters = FormParameters(SelectedObject, True);
	NotifyDescription = New NotifyDescription("SelectedObjectStartChoiceCompletion", ThisObject);
	StandardSubsystemsClient.ChooseMetadataObjects(FormParameters, NotifyDescription);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	FormParameters = FormParameters(Object.MetadataObjects, False);
	NotifyDescription = New NotifyDescription("SelectCompletion", ThisObject);
	StandardSubsystemsClient.ChooseMetadataObjects(FormParameters, NotifyDescription);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectedObjectStartChoiceCompletion(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		SelectedObject = Result;
	EndIf;
EndProcedure

&AtClient
Procedure SelectCompletion(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		Object.MetadataObjects = Result;
	EndIf;
EndProcedure

&AtClient
Function FormParameters(SelectedObjects, SelectSingle)
	
	MetadataFilter = Undefined;
	If CatalogsAndDocumentsOnly Then
		MetadataFilter = New ValueList;
		MetadataFilter.Add("Catalogs");
		MetadataFilter.Add("Documents");
	EndIf;
	
	FormParameters = StandardSubsystemsClientServer.MetadataObjectsSelectionParameters();
	FormParameters.MetadataObjectsToSelectCollection = MetadataFilter;
	FormParameters.SelectedMetadataObjects = SelectedObjects;
	FormParameters.SelectSingle = SelectSingle;
	
	Return FormParameters;
	
EndFunction

#EndRegion