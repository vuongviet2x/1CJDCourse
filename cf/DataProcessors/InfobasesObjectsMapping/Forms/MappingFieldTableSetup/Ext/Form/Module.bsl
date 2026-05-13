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
	
	Cancel = False;
	
	MarkedListItemArray = CommonClientServer.MarkedItems(FieldList);
	
	If MarkedListItemArray.Count() = 0 Then
		
		NString = NStr("ru = 'Укажите хотя бы одно поле';
						|en = 'Specify at least one field';");
		
		CommonClient.MessageToUser(NString,,"FieldList",, Cancel);
		
	ElsIf MarkedListItemArray.Count() > MaxUserFields() Then
		
		// The value must not exceed the specified number.
		MessageString = NStr("ru = 'Уменьшите количество полей (можно выбирать не более [FieldsCount] полей)';
								|en = 'Reduce the number of fields (you can select no more than [FieldsCount] fields)';");
		MessageString = StrReplace(MessageString, "[FieldsCount]", String(MaxUserFields()));
		CommonClient.MessageToUser(MessageString,,"FieldList",, Cancel);
		
	EndIf;
	
	If Not Cancel Then
		
		NotifyChoice(FieldList.Copy());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	NotifyChoice(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function MaxUserFields()
	
	Return DataExchangeClient.MaxObjectsMappingFieldsCount();
	
EndFunction

#EndRegion
