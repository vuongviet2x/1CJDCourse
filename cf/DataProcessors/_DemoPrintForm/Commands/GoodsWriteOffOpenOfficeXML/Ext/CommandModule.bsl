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
	
	NotifyDescription = New NotifyDescription("PrintGoodsWriteOff", ThisObject);
	PrintManagementClient.CheckDocumentsPosting(NotifyDescription, CommandParameter, CommandExecuteParameters.Source);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure PrintGoodsWriteOff(DocumentsList, AdditionalParameters) Export
	
	If DocumentsList.Count() = 0 Then
		Return;
	EndIf;
	
	MessageText = ?(DocumentsList.Count() > 1, 
		NStr("ru = 'Выполняется формирование печатных форм...';
			|en = 'Generating print forms…';"),
		NStr("ru = 'Выполняется формирование печатной формы...';
			|en = 'Generating a print form…';"));
	Status(MessageText);
		
	PrintManagementClient.ExecutePrintCommand("DataProcessor._DemoPrintForm", "GoodsWriteOffOpenOfficeXML", DocumentsList, Undefined);
	
EndProcedure

#EndRegion

