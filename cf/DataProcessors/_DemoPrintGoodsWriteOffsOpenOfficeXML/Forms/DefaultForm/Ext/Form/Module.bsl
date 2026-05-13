///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// Assignable client command handler.
//
// Parameters:
//   CommandID - String - Command name as it is given in function ExternalDataProcessorInfo of the object module.
//   DocumentsArray - Array - References the command runs for.
//
&AtClient
Procedure Print(CommandID, DocumentsArray) Export
	
	If DocumentsArray.Count() = 0 Then
		Return;
	EndIf;
	
	Status(NStr("ru = 'Формирование печатных форм...';
					|en = 'Generating print forms…';"));
	PrintManagementClient.ExecutePrintCommand("DataProcessor._DemoPrintForm", "GoodsWriteOffOpenOfficeXML", DocumentsArray, ThisObject);
	
EndProcedure

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Parameters.RelatedObjects) Then
		For Each Ref In Parameters.RelatedObjects Do
			RelatedObjects.Add(Ref);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GeneratePrintForm(Command)
	
	Print("GoodsWriteOffOpenOfficeXML", RelatedObjects.UnloadValues());
	
EndProcedure

#EndRegion
