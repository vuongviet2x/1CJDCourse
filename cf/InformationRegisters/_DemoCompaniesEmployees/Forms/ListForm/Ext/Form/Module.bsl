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
	
	If Parameters.OpenFromFormMode Then
		Title = NStr("ru = 'Демо: Работники организации';
						|en = 'Demo: Company employees';");
		Items.Organization.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShowMessage(Command)
	
	If Items.List.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CommonClient.MessageToUser(NStr("ru = 'Сообщение связанное с ключом регистра сведений.';
													|en = 'Message related to information register key.';"),
			Items.List.CurrentRow);
	
EndProcedure

#EndRegion
