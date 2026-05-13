///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	If AdditionalProperties.Property("PredefinedObjectsFilling") Then
		CheckPredefinedReportOptionFilling(Cancel);
	EndIf;
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not AdditionalProperties.Property("PredefinedObjectsFilling") Then
		Raise NStr("ru = 'Запись в справочник ""Предопределенные варианты отчетов"" запрещена. Его данные заполняются автоматически.';
								|en = 'Cannot save to ""Predefined report options"" catalog. It is populated automatically.';");
	EndIf;
EndProcedure

// Basic validation of predefined report options.
Procedure CheckPredefinedReportOptionFilling(Cancel)
	
	If DeletionMark Then
		Return;
	EndIf;
	If ValueIsFilled(Report) Then
		Return;
	EndIf;
		
	Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не заполнено поле ""%1"".';
																					|en = 'Field %1 is required.';"), "Report");
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf