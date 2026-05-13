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
	If Not Parameters.Property("FieldList") Then
		
		Raise NStr("ru = 'Эта форма не предназначена для непосредственного открытия.';
								|en = 'This is a dependent form and opens from a different form.';", Common.DefaultLanguageCode());
		
	EndIf;
	
	FieldList = Parameters.FieldList;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Apply(Command)
	
	MarkedListItemArray = CommonClientServer.MarkedItems(FieldList);
	
	If MarkedListItemArray.Count() = 0 Then
		
		NString = NStr("ru = 'Укажите хотя бы одно поле';
						|en = 'Specify at least one field';");
		
		CommonClient.MessageToUser(NString,,"FieldList");
		
		Return;
		
	EndIf;
	
	NotifyChoice(FieldList.Copy());
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	NotifyChoice(Undefined);
	
EndProcedure

#EndRegion
