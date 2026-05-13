///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "OnlineUserSupport.SaaS.ClassifiersOperations" subsystem.
// CommonModule.ClassifiersOperationsServerCall.
//
// Server procedures and functions for importing classifiers:
//  - Set up classifier update mode
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Defines schedule of the scheduled classifier update job.
//
// Returns:
//  Structure:
//   * Schedule - Undefined, JobSchedule - Schedule of the classifier update.
//   * UpdateOption - Number
//
Function ClassifiersUpdateSettings() Export
	
	// The classifier update options and schedules are not private. Any of the infobase users can access it.
	// 
	If ClassifiersOperations.InteractiveClassifiersImportAvailable() Then
		SetPrivilegedMode(True);
	EndIf;
	
	Result = New Structure;
	Result.Insert("Schedule",        Undefined);
	Result.Insert("UpdateOption", Constants.ClassifiersUpdateOption.Get());
	
	UpdateJobs = ClassifiersOperations.JobsUpdateClassifiers();
	If UpdateJobs.Count() <> 0 Then
		Result.Schedule = UpdateJobs[0].Schedule;
	EndIf;
	
	Return Result;
	
EndFunction

// Sets a scheduled job schedule.
//
// Parameters:
//  Schedule - JobSchedule - Schedule of the classifier update.
//
Procedure WriteUpdateSchedule(Val Schedule) Export
	
	If ClassifiersOperations.InteractiveClassifiersImportAvailable() Then
		SetPrivilegedMode(True);
	EndIf;
	
	UpdateJobs = ClassifiersOperations.JobsUpdateClassifiers();
	If UpdateJobs.Count() <> 0 Then
		ScheduledJobsServer.SetJobSchedule(
			UpdateJobs[0],
			Schedule);
	EndIf;
	
EndProcedure

// Enables the automatic classifier update from the service.
//
Procedure EnableClassifierAutoUpdateFromService() Export
	
	ClassifiersOperations.EnableClassifierAutoUpdateFromService();
	
EndProcedure

#EndRegion
