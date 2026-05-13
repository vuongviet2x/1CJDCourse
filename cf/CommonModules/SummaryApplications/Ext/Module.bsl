#Region Internal

// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//  HandlersArray - Array - Message handlers.
//
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
EndProcedure

// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  HandlersArray - Array - Message handlers.
//
Procedure RecordingOutgoingMessageInterfaces(HandlersArray) Export
EndProcedure

//@skip-warning
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export
EndProcedure

// Process incoming messages whose type is {http://www.1c.ru/1cFresh/ManageSynopticExchange/a.b.c.d}SetSynopticExchange.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataAreaCode - Number - code of data area,
//  Parameters - Structure - backup ID,
//
Procedure ConfigureUploadingToSummaryApp_(DataAreaCode, Parameters) Export
EndProcedure

// Process incoming messages whose type is {http://www.1c.ru/1cFresh/ManageSynopticExchange/a.b.c.d}SetCorrSynopticExchange.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataAreaCode - Number - code of data area,
//  Parameters - Structure - backup ID,
//
Procedure ConfigureUploadingToSummaryApp(DataAreaCode, Parameters) Export
EndProcedure

// Process incoming messages whose type is {http://www.1c.ru/1cFresh/ManageSynopticExchange/a.b.c.d}PushSynopticExchangeStep1.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataAreaCode - Number - code of data area,
//  Parameters - Structure - backup ID,
//
Procedure InteractiveLaunchOfUploadingToSummaryApplication(DataAreaCode, Parameters) Export 
EndProcedure

// Process incoming messages whose type is {http://www.1c.ru/1cFresh/ManageSynopticExchange/a.b.c.d}PushSynopticExchangeStep2.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataAreaCode - Number - code of data area,
//  Parameters - Structure - backup ID,
//
Procedure InteractiveLaunchOfDownloadToSummaryApplication(DataAreaCode, Parameters) Export 
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - Array of MetadataObject
//
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	Types.Add(Metadata.InformationRegisters.SummaryApplicationsImportQueue);
	Types.Add(Metadata.InformationRegisters.SummaryApplicationsImportState);
	Types.Add(Metadata.InformationRegisters.SummaryApplicationsExportState);
	Types.Add(Metadata.Constants.UseExportToSummaryApplication);
	Types.Add(Metadata.InformationRegisters.DeleteSummaryApplicationsObjectsExportOrder);
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//	Settings - See ScheduledJobsOverridable.OnDefineScheduledJobSettings.Settings
//
Procedure OnDefineScheduledJobSettings(Settings) Export
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export
EndProcedure

// Scheduled job ConsolidationApplicationsExport.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure ExportJob() Export
EndProcedure

// The ConsolidationApplicationsScheduledImport scheduled job.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure TaskLoadPlanning() Export
EndProcedure

// The handler of the BeforeWriteObject event subscription.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure BeforeWriteObject(Source, Cancel) Export
EndProcedure

// The handler of the WriteDocument event subscription.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure BeforeWritingDocument(Source, Cancel, WriteMode, PostingMode) Export
EndProcedure

// The handler of the BeforeWriteSet event subscription.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure BeforeRecordingSet(Source, Cancel, Replacing) Export
EndProcedure

// The handler of the BeforeWriteCalculationSet event subscription.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure BeforeRecordingCalculationSet(Source, Cancel, Replacing, WriteOnly, WriteActualActionPeriod, WriteRecalculations) Export
EndProcedure

// The handler of the BeforeDeleteObject event subscription.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure BeforeDeleteObject(Source, Cancel) Export
EndProcedure

#Region DataTransferSubsystemIntegration

// Returns the details of binary data stored in the logical storage.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  StorageID - String - Logical storage ID.
//  DataID    - String - Storage data ID.
// 
// Returns:
//   Structure - Details of the queue job status:
//    * FileName - String - Filename.
//    * Size - Number - File size in bytes.
//    * Data - BinaryData - Binary data of job details file.
//
Function LongDesc(StorageID, DataID) Export
EndFunction

// Returns binary data stored in the logical storage.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataDetails - Structure - Storage data details.
// 
// Returns:
//   BinaryData -
//
Function Data(DataDetails) Export
EndFunction

// Writes data to logical storage.
// @skip-warning EmptyMethod - Implementation feature.
// Executes the following actions:
// - Saves a data file to a file storage
// - Schedules a job queue job for processing a file
// - Returns the job ID.
// 
// Parameters:
//	DataDetails - Structure - Storage data details:
//	 * FileName - String - Filename.
//	 * Size - Number - File size in bytes.
//	 * Data - BinaryData, String - Binary file data or file location on the hard drive.
// 
// Returns:
//   Structure:
//     * ConfigurationName - String - Configuration name.
//     * ConfigurationVersion - String - Configuration version.
//     * LoadingIsInProgress - Boolean - Import running flag.
//     * ReceivedMessageNumber - Number - Processed message count.
//     * ObjectsImported - Number - Imported object count.
//     * CompletedWithErrors - Boolean - Completed with error flag.
//     * ErrorDescription - String - Error details.
//     * ResendingRequired - Boolean - If True, resent data pending in the queue.
//                                             
Function Load(DataDetails) Export
EndFunction

#EndRegion

#EndRegion
