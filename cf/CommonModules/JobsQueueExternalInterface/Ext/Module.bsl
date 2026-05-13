
#Region Public

// See InfobaseUpdateSSL.OnAddUpdateHandlers
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
Procedure OnAddUpdateHandlers(Handlers) Export
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.JobsProperties);
	
EndProcedure

// Returns the storage ID as String.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//	String - Storage ID. 
//
Function StorageID() Export
EndFunction

#EndRegion 
