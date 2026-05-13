///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Notification = New NotifyDescription("CommandProcessingCompletion", ThisObject);
	SoftwareLicenseCheckClient.ShowLegitimateSoftwareCheck(Notification);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CommandProcessingCompletion(Result, AdditionalParameters) Export
	Var MessageText;
	
	If Result = True Then
		MessageText = NStr("ru = 'Легальность получения обновления подтверждена.';
								|en = 'The legality of receiving update is confirmed.';");
	Else
		MessageText = NStr("ru = 'Обновление получено нелегально.';
								|en = 'Update is received illegally.';");
	EndIf;
	
	ShowMessageBox(,MessageText);
	
EndProcedure

#EndRegion