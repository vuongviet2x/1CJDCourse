///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Private

// Creates a reminder that goes off 5 minute before the event.
// 
// Parameters:
//  SubjectOf - TaskRef.PerformerTask
//  Parameters - Arbitrary - not used.
//  
Procedure Remind5MinAhead(SubjectOf, Parameters) Export
	
	UserRemindersClient.RemindTillSubjectTime(String(SubjectOf), 5*60, SubjectOf, "TaskDueDate");
	ShowUserNotification(NStr("ru = 'Создано напоминание:';
										|en = 'Reminder created:';"), , String(SubjectOf), PictureLib.DialogInformation);

EndProcedure

// Creates a reminder that goes off 10 minutes after its creation.
// 
// Parameters:
//  SubjectOf - CatalogRef._DemoCounterparties
//  Parameters - Arbitrary - not used.
//  
Procedure RemindIn10Min(SubjectOf, Parameters) Export
	
	ReminderText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '""%1"" требует внимания';
																					|en = '%1 requires attention';"),
		SubjectOf);
	UserRemindersClient.RemindInSpecifiedTime(ReminderText, 
		CommonClient.SessionDate() + 10 * 60, SubjectOf);

	ShowUserNotification(NStr("ru = 'Создано напоминание:';
										|en = 'Reminder created:';"),, ReminderText,
		PictureLib.DialogInformation);
		
EndProcedure

// Creates a birthday reminder that goes off 3 days before the date.
// 
// Parameters:
//  SubjectOf - CatalogRef._DemoIndividuals
//  Parameters - Arbitrary - not used.
//  
Procedure RemindOfBirthday3DaysAhead(SubjectOf, Parameters) Export

	ReminderText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
		"ru = 'День рождения сотрудника: %1';
		|en = '%1 is celebrating birthday!';"), String(SubjectOf));
	UserRemindersClient.RemindOfAnnualSubjectEvent(
		ReminderText, 60 * 60 * 24 * 3, SubjectOf, "BirthDate");

	ShowUserNotification(NStr("ru = 'Создано напоминание:';
										|en = 'Reminder created:';"),, ReminderText,
		PictureLib.DialogInformation);
		
EndProcedure

#EndRegion