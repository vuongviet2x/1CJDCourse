// @strict-types

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Main procedures and functions.

// API methods can only manipulate job parameters. 
// Each method has access to certain parameters (parameters might affect the scope).
// For details, see the comments on the methods.
// For parameter details, see "NewJobParameters".

// Receives the jobs filtered from the queue.
// The received data might be inconsistent.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  Filter - Structure - Filter values (combined by AND). Allowed structure keys:
//            * DataArea - Number - Data area.
//            * MethodName - String - Method name.
//            * Id - UUID - Job ID.
//            * JobState - EnumRef.JobsStates - Job status.
//            * Key - String - Job key.
//            * Template - CatalogRef.QueueJobTemplates - Job template.
//            * Use - Boolean - Usage flag.
//        - Array of Structure - Details.:
//            * ComparisonType - ComparisonType - Valid values are:
//                ComparisonType.Equal, ComparisonType.NotEqual - To compare with a value,
//                ComparisonType.InList, ComparisonType.NotInList - To compare with an array.
//            * Value - Arbitrary - Comparison value for Equal and NotEqual.
//            			 - Array -  For the InList and NotInList comparison types.
//
// Returns:
//  ValueTable - Identified job table. Each column corresponds to a job parameter:
//	 * Id - CatalogRef.JobsQueue - - Catalog reference.
//	 …
//
Function GetJobs(Val Filter) Export
EndFunction

// Adds a new job to the queue.
// If it is called within a transaction, object lock is set for the job.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters: 
//  JobParameters - Structure - Parameters of the job to be added. Details:
//  * DataArea - Number - Data area number.
//  * Use - Boolean - Usage flag.
//  * ScheduledStartTime - Date - Startup time (DateTime).
//  * ExclusiveExecution - Boolean - Exclusive mode flag.
//  * MethodName - String - Method name. Required for the job.
//  * Parameters - Array - Method parameters.
//  * Key - String - Job uniqueness key.
//  * RestartIntervalOnFailure - Number - Repeat period in seconds.
//  * Schedule - JobSchedule - Job execution schedules.
//  * RestartCountOnFailure - Number - Number of attempts.
//
// Returns: 
//  CatalogRef.JobsQueue - added job ID.
// 
Function AddJob(JobParameters) Export
EndFunction

// Modifies the job with the given ID.
// If it is called within a transaction, object lock is set for the job.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters: 
//	Id - CatalogRef.JobsQueue - Job ID.
//	JobParameters - Structure - Parameters required for the job. Valid keys:
//						* Use - Boolean -
//						* ScheduledStartTime - Date -
//						* ExclusiveExecution - Boolean - 
//						* MethodName - String - 
//						* Parameters - Array - 
//  					* Key - String - 
//						* RestartIntervalOnFailure - Number - 
//						* Schedule - JobSchedule - 
//						* RestartCountOnFailure - Number - 
//   				- Structure - If the job is based on a template, only the following keys are allowed:
//						* Use - Boolean - 
//						* ScheduledStartTime - Date - 
//						* ExclusiveExecution - Boolean - 
//						* RestartIntervalOnFailure - Number - 
//						* Schedule - JobSchedule - 
//						* RestartCountOnFailure - Number - 
// 
Procedure ChangeJob(Id, JobParameters) Export
EndProcedure

// Deletes a job from the jobs queue.
// Deleting jobs with the specified template is denied.
// If it is called within a transaction, object lock is set for the job.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  Id - CatalogRef.JobsQueue - Job ID.
//
Procedure DeleteJob(Id) Export
EndProcedure

// Returns a template of the queue job by the name of the predefined scheduled job, from which it is created.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  Name - String - name of the predefined scheduled job.
//
// Returns:
//  CatalogRef.QueueJobTemplates - job template.
//
Function TemplateByName_(Val Name) Export
EndFunction

// Returns an error text on an attempt to execute two jobs with one key at the same time.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//   String - an exception text.
//
Function GetExceptionTextJobsWithSameKeyDuplication() Export
EndFunction

// Returns a list of the queue job templates.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//  Array of String - names of predefined shared scheduled jobs to be used 
//           as queue job templates.
//
//
Function QueueJobTemplates() Export
EndFunction

// Returns a manager of the JobsQueue catalog.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//	CatalogManager.JobsQueue - a manager of the catalog.
//
Function CatalogJobsQueue() Export
EndFunction

#EndRegion
