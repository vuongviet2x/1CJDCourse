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
	
	// Verify that the form is opened with the required parameters
	If Not Parameters.Property("MappingFieldsList") Then
		
		Raise NStr("ru = 'Эта форма не предназначена для непосредственного открытия.';
								|en = 'This is a dependent form and opens from a different form.';", Common.DefaultLanguageCode());
		
	EndIf;
	
	MappingFieldsList = Parameters.MappingFieldsList;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateCommentLabelText();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MappingFieldsListOnChange(Item)
	
	UpdateCommentLabelText();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RunMapping(Command)
	
	NotifyChoice(MappingFieldsList.Copy());
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	NotifyChoice(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateCommentLabelText()
	
	MarkedListItemArray = CommonClientServer.MarkedItems(MappingFieldsList);
	
	If MarkedListItemArray.Count() = 0 Then
		
		NoteLabel = NStr("ru = 'Сопоставление будет выполнено только по внутренним идентификаторам объектов.';
								|en = 'Mapping will be performed by internal object UUIDs only.';");
		
	Else
		
		NoteLabel = NStr("ru = 'Сопоставление будет выполнено по внутренним идентификаторам объектов и по выбранным полям.';
								|en = 'Mapping will be performed by internal object UUIDs and the selected fields.';");
		
	EndIf;
	
EndProcedure

#EndRegion
