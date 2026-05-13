#Region Public

// Creates a structure of the issue type details, which must be populated and passed to the CreateTypeRecord function.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  TypeName	 - String - Issue type unique name. For example: Configuration1.Subsystem1.Incident1.
// 
// Returns:
//   - Structure - Structure with the following fields:
// 		* IncidentType - String - Type name.
//		* IncidentLevel - String - Information, Warning (by default), Error, CriticalError.
//		* Subsystem - String - a subsystem from the QMC point of view
//		* InformationBaseContext - Boolean - Connection context definition flag. By default, False.
//		* CheckProcedure - String - Name of a procedure that runs repeatedly if there are open issues of the given type, and checks their relevance.
//			If set to Auto, it checks the relevance by the Actual field in the open issue register.
//		* MinutesBetweenIncidents - Number - Limit the frequency of sending issues. By default, "0" (no limit).
//		* Tags - Structure - with the following fields::
//		   ** Equipment - Boolean - 
//		   ** Enabled - Boolean - 
//		   ** Performance - Boolean - 
//		   ** ApplicationError - Boolean - 
//		   ** Additional - String - Space-delimited arbitrary tags.
//
Function CreateIncidentTypeDescription(TypeName) Export
EndFunction

// Creates an issue type record and adds it to the dictionary. If the type already exists, it is overwritten.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DictionaryOfTypes - Map of KeyAndValue:
//  * Key - String - Issue type name.
//  * Value - See CreateIncidentTypeDescription
//  LongDesc - Structure:
//  * IncidentType - String
//  * IncidentLevel - String
//  * Subsystem - String
//  * InformationBaseContext - Boolean
//  * CheckProcedure - String
//  * MinutesBetweenIncidents - Number
//  * Tags - Structure:
//    ** Equipment - Boolean
//    ** Enabled - Boolean
//    ** Performance - Boolean
//    ** ApplicationError - Boolean
//    ** Additional - String
Procedure CreateRecordLike(Val DictionaryOfTypes, Val LongDesc) Export
EndProcedure

// Registers types of infobase issues.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure RegisterIncidentTypesInQCC() Export
EndProcedure

// Creates an issue. If QMC address is not specified, it does nothing. If the issue sending frequency exceeds the limit, skips sending the issue. 
// If Asynchronously=True, the method is executed by the background job manager. 
// @skip-warning EmptyMethod - Implementation feature.
// 
//
// Parameters:
//  IncidentType - String - Issue type ID. Must be one of the registered types.
//  IncidentCode - String - Issue ID. Must be unique within the type. 
//  						When the same ID is passed again, the issue counter in QMC is incremented by 1.
//  MessageText - String - Issue message text.
//  Asynchronously - Boolean - Asynchronous execution flag.
//
Procedure OpenIncident(Val IncidentType, Val IncidentCode, Val MessageText, Val Asynchronously = False) Export
EndProcedure

// Marks an issue as no longer valid in the OpenedIncidents register. 
// QMC will close the issue during the next validity check.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  IncidentType - String - Issue type ID.
//  IncidentCode - String - Issue ID. 
//
Procedure MarkIncidentAsIrrelevant(Val IncidentType, Val IncidentCode) Export
EndProcedure

// Sends a counter to QMC using InputStatistics/InputStatisticsDate (SYNCHRONOUS ACCOUNT SENDING).
// When arrays in the CounterID/CounterValue parameters are specified, the whole
// array is passed in one call.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  TagID - String - Dot-delimited counter IDs.
//  TagValue - Number - Counter value at the given point in time.
//  Data - Map of KeyAndValue:
//	 * Key - String - Counter ID.
//	 * Value - Number - Counter value. If specified, it has a priority.
//  TagDate - Date - If specified, use InputStatisticsDate. Otherwise InputStatistics.
//
Procedure SendStatistics(Val TagID, Val TagValue, Val Data = Undefined, Val TagDate = Undefined) Export
EndProcedure

#EndRegion

#Region Internal

// Called from the scheduled QMCMonitoring procedure
// @skip-warning EmptyMethod - Implementation feature.
// 
Procedure ExecuteQCCMonitoring() Export
EndProcedure

// See SaaSOperations.OnDefineSharedDataExceptions
// 
// Parameters:
//	Exceptions - Array of MetadataObject - Exceptions.
//
Procedure OnDefineSharedDataExceptions(Exceptions) Export

	Exceptions.Add(Metadata.InformationRegisters.IncidentsSendingSpeedLimit);
	Exceptions.Add(Metadata.InformationRegisters.OpenedIncidents);
	Exceptions.Add(Metadata.InformationRegisters.IncidentsDeferredChecks);
	Exceptions.Add(Metadata.Constants.QCCIncidentsTypesRelevant);
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.IncidentsSendingSpeedLimit);
	Types.Add(Metadata.InformationRegisters.OpenedIncidents);
	Types.Add(Metadata.InformationRegisters.IncidentsDeferredChecks);
	Types.Add(Metadata.Constants.QCCIncidentsTypesRelevant);
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
// Parameters:
//	Settings - See ScheduledJobsOverridable.OnDefineScheduledJobSettings.Settings
Procedure OnDefineScheduledJobSettings(Settings) Export
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.QCCMonitoring;
	Setting.UseExternalResources = True;
	
EndProcedure

#EndRegion