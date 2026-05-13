
#Region Public

// @skip-warning EmptyMethod - Implementation feature.
// Returns:
//	ExchangePlanRef.MessagesExchange - a reference to the node.
Function ThisNode() Export
EndFunction

// See DataExchangeOverridable.OnDataExport
// @skip-warning EmptyMethod - Implementation feature.
// 
Procedure OnDataExport(StandardProcessing, Recipient, MessageFileName,
		MessageData, TransactionItemsCount,
		EventLogEventName, SentObjectsCount) Export
EndProcedure

// See DataExchangeOverridable.OnDataImport
// @skip-warning EmptyMethod - Implementation feature.
// 
Procedure OnDataImport(StandardProcessing, Sender,
		MessageFileName, MessageData, TransactionItemsCount,
		EventLogEventName, ReceivedObjectsCount) Export
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export
EndProcedure

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//	Objects - See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.Objects
//
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport
// 
// Parameters:
//	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
//
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	If SaaSOperationsCached.IsSeparatedConfiguration() Then
		ExportImportData.AddTypeExcludedFromUploadingUploads(
			Types,
			Metadata.Catalogs.DataAreaMessages,
			ExportImportData.ActionWithLinksDoNotChange());	
	EndIf;
	
	ExportImportData.AddTypeExcludedFromUploadingUploads(
		Types,
		Metadata.Catalogs.SystemMessages,
		ExportImportData.ActionWithLinksDoNotChange());	
	
	ExportImportData.AddTypeExcludedFromUploadingUploads(
		Types,
		Metadata.ExchangePlans.MessagesExchange,
		ExportImportData.ActionWithLinksDoNotChange());	
	
EndProcedure

// See CommonOverridable.OnDefineSupportedInterfaceVersions.SupportedVersions
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//	SupportedVersionsStructure - See CommonOverridable.OnDefineSupportedInterfaceVersions.SupportedVersions 
//
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export
EndProcedure

// Sets a code of this endpoint if it is not set.
// @skip-warning EmptyMethod - Implementation feature.
// 
Procedure InstallCodeOfThisEndpoint() Export
EndProcedure

// Moves message exchange transport settings to a new register.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure MigrateMessagingTransportSettings() Export
EndProcedure

#EndRegion

#Region Internal

// Handler of the scheduled job to send and receive system messages.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure SendAndReceiveMessagesForRoutineTasks() Export
EndProcedure

#EndRegion

