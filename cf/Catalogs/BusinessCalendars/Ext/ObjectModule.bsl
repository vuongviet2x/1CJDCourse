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

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	CheckBasicCalendarUse(Cancel);
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	CalendarSchedules.UpdateMultipleBusinessCalendarsUsage();
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckBasicCalendarUse(Cancel)
	
	If Ref.IsEmpty() Or Not ValueIsFilled(BasicCalendar) Then
		Return;
	EndIf;
	
	// The reference to itself is prohibited.
	If Ref = BasicCalendar Then
		MessageText = NStr("ru = 'В качестве базового не может быть выбран тот же самый календарь.';
								|en = 'Cannot select a calendar as a source for itself.';");
		Common.MessageToUser(MessageText, , , "Object.BasicCalendar", Cancel);
		Return;
	EndIf;
	
	// If another calendar is based on this one, forbid populating it 
	// to avoid circular dependencies.
	
	Query = New Query;
	Query.SetParameter("Calendar", Ref);
	Query.Text = 
		"SELECT TOP 1
		|	Ref
		|FROM
		|	Catalog.BusinessCalendars AS BusinessCalendars
		|WHERE
		|	BusinessCalendars.BasicCalendar = &Calendar";
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Календарь уже является базовым для календаря ""%1"" и не может зависеть от другого.';
			|en = 'The calendar is a source for ""%1."" It cannot depend on another calendar.';"),
		Selection.Ref);
	Common.MessageToUser(MessageText, Selection.Ref, , "Object.BasicCalendar", Cancel);
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf