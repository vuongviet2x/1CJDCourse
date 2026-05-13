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
	FillPropertyValues(ThisObject, FormAttributeToValue("Object").DefaultSettings());
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateObjects(Command)
	CreateObjectsAtServer();
	NotifyChanged(Type("CatalogRef._DemoProducts"));
	FileSystemClient.OpenURL(
		"e1cib/navigationpoint/Administration/DataProcessor.MarkedObjectsDeletion.Command.MarkedObjectsDeletion");
EndProcedure

&AtClient
Procedure ScheduleScheduledTask(Command)
	Time = ScheduleScheduledTaskServer();
	ShowUserNotification(NStr("ru = 'Удаление помеченных';
										|en = 'Marked object deletion';"),
		"e1cib/app/DataProcessor.EventLog",
		StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Запуск запланирован на %1';
			|en = 'Start is scheduled for %1';"), Time));
	FileSystemClient.OpenURL("e1cib/app/DataProcessor.EventLog");
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CreateObjectsAtServer()
	FormAttributeToValue("Object").Generate(ThisObject);
EndProcedure

&AtServerNoContext
Function ScheduleScheduledTaskServer()
	
	If Common.DataSeparationEnabled() Then // In SaaS mode, run immediately.
		TimeConsumingOperations.ExecuteProcedure(, Metadata.ScheduledJobs.MarkedObjectsDeletion.MethodName);
		Return CurrentDate(); // ACC:143 - Scheduled jobs use the computer date (not the session date).
	Else
		Result = CurrentDate() + 2 * 60; // ACC:143 - Scheduled jobs use the computer date (not the session date).
		Parameters = MarkedObjectsDeletionInternalServerCall.ModeDeleteOnSchedule();
		Parameters.Use = True;
		Parameters.Schedule.BeginTime = Date(1, 1, 1, Hour(Result), Minute(Result), Second(Result));
		Parameters.Schedule.CompletionTime = Date(1, 1, 1, 0, 0, 0);
		Parameters.Schedule.EndTime = Date(1, 1, 1, 0, 0, 0);
		MarkedObjectsDeletionInternalServerCall.SetDeleteOnScheduleMode(Parameters);
	EndIf;
	
	Return Result;
		
EndFunction

#EndRegion
