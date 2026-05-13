// @strict-types

#Region Internal

// DeleteCTLJobsQueueProcessing scheduled job handler.
//
// Parameters:
//	JobParameters - CatalogRef.JobsQueueHandlers - job parameters.
//
Procedure STLJobQueueProcessing(JobParameters) Export
	
	Raise NStr("ru = 'Процедура не используется';
							|en = 'The procedure is not used';");
	
EndProcedure

// Plans execution of jobs from the JobsQueue information register.
// @skip-check module-empty-method - Implementation feature.
// 
Procedure JobsProcessingPlanning() Export
	
EndProcedure

// The procedure executes a job from the JobsQueue catalog.
// @skip-check module-empty-method - Implementation feature. 
// 
// Parameters: 
//  JobParameters - Structure - Parameters required to execute the job.
//
Procedure RoutineTaskQueueProcessing(JobParameters) Export
	
EndProcedure

// Returns possible methods to use in the job queue.
// Returns:
//	Array of String - an array of method names.
Function PossibleMethods() Export
	
	Return New Array;
	
EndFunction

// See SaaSOperationsOverridable.OnEnableSeparationByDataAreas.
// @skip-check module-empty-method - Implementation feature.
//
Procedure OnEnableSeparationByDataAreas() Export
	
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport
// @skip-check module-empty-method - Implementation feature.
//
// Parameters:
//	CatalogsToImport - ValueTable -
//
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
// @skip-check module-empty-method - Implementation feature.
//
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
EndProcedure

// JobsProcessingStart scheduled job handler.
// @skip-check module-empty-method - Implementation feature.
//
Procedure JobsProcessingStart() Export
	
EndProcedure


#EndRegion
