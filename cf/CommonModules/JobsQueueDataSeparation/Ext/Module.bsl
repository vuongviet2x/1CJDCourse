// @strict-types

#Region Public

// Deprecated. Selects a catalog to be used for adding a queue job.
//
// Parameters:
//	JobParameters - Structure - Job parameters. Valid keys are:
//	 * DataArea - Number - data area
//	 * Use - Boolean - the fact of usage
//	 * ScheduledStartTime - Date - a startup date
//	 * ExclusiveExecution - Boolean - the fact of exclusive execution
//	 * MethodName - String - a method name for a job (required.)
//	 * Parameters - Array - job parameters array
//	 * Key - String - job key
//	 * RestartIntervalOnFailure - Number - specified in seconds.
//	 * Schedule - JobSchedule - job execution schedules
//	 * RestartCountOnFailure - Number - a number of retries.
//	 
// Returns:
//	CatalogManager.JobsQueue - manager.
Function WhenSelectingReferenceCatalogForTask(Val JobParameters) Export
	
	Return Undefined;
	
EndFunction

#EndRegion
