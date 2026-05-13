#Region Internal

// See ExportImportDataOverridable.AfterImportData.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure AfterImportData(Container) Export
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export
EndProcedure

// Creates jobs by templates in the current data area.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure CreateQueueJobsUsingTemplatesInCurScope() Export
EndProcedure

// See SaaSOperationsOverridable.OnEnableSeparationByDataAreas.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure OnEnableSeparationByDataAreas() Export
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
//	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
//
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	ExportImportData.AddTypeExcludedFromUploadingUploads(
		Types,
		Metadata.Catalogs.JobsQueue,
		ExportImportData.ActionWithLinksDoNotChange());

	Types.Add(Metadata.InformationRegisters.HistoryOfStartsOfJobsInQueue);
	Types.Add(Metadata.Constants.LogLaunchesJobsInQueue);
	Types.Add(Metadata.Constants.StoragePeriodForHistoryOfQueueJobLaunchesHours);
	
	ExportImportData.AddTypeExcludedFromUploadingUploads(
		Types,
		Metadata.Catalogs.DeleteJobsQueue,
		ExportImportData.ActionWithLinksDoNotChange());
	
EndProcedure

#EndRegion
