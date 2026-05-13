////////////////////////////////////////////////////////////////////////////////
// The "Data export and import" subsystem.
// 
// This module's procedures and functions allow importing and exporting
// additional reports and data processors.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Called upon registration of arbitrary data export handlers.
// This procedure requires complementing	the handler table with information about arbitrary data export
// handlers to be registered. See ExportImportDataOverridable.OnRegisterDataExportHandlers.
// @skip-check module-empty-method - Implementation feature.
//
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
EndProcedure

#EndRegion