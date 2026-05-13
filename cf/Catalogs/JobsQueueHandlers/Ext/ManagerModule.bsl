#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Internal
	
// Returns:
// 	JobSchedule
//
Function DefaultSchedule() Export
	
	Schedule = New JobSchedule;
	Schedule.DaysRepeatPeriod = 1;
	Schedule.RepeatPeriodInDay = 60;
	
	Return Schedule;
	
EndFunction

// Update handler
//
Procedure TransferDataFromRoutineTask() Export
	
	Filter = New Structure("Metadata", Metadata.ScheduledJobs.DeleteJobsQueueProcessingCTL);
	FoundJobs = ScheduledJobs.GetScheduledJobs(Filter);
	For Each Job In FoundJobs Do
		Ref = Catalogs.JobsQueueHandlers.GetRef(New UUID(Job.Key));
		TaskQueueHandler = Ref.GetObject();
		If TaskQueueHandler <> Undefined Then
			TaskQueueHandler.Use = Job.Use;
			TaskQueueHandler.Schedule = New ValueStorage(Job.Schedule);
			TaskQueueHandler.DataExchange.Load = True;
			TaskQueueHandler.Write();
		EndIf;
		Job.Delete();
	EndDo;
	
EndProcedure

#EndRegion
	
#EndIf
