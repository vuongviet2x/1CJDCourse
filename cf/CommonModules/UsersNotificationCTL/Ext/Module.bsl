
#Region Internal

// The procedure of the scheduled job ProcessUsersNotifications.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure HandlingUserAlerts() Export
	
EndProcedure

// Sends notifications to user sessions.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure DeliverAlerts(DeliveredAlerts) Export
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
// 	Settings - See ScheduledJobsOverridable.OnDefineScheduledJobSettings.Settings
//
Procedure OnDefineScheduledJobSettings(Settings) Export
	
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export 	
EndProcedure

// See MessageInterfacesSaaSOverridable.FillInReceivedMessageHandlers.
// @skip-warning EmptyMethod - Implementation feature.
// 
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
	
EndProcedure

#EndRegion