
#Region Public

// Returns a table of modules to be checked.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//   RestoreSettings_ - Boolean - Flag indicating whether to restore the saved data processor settings.
//   GettingPastResult - Boolean - Flag indicating whether to get the saved result.
//
// Returns:
//   ValueTable - Table with the following columns:
//     * Id - UUID - Check ID.
//     * Check - Boolean - To select a check, this field value must be True.
//     * Name - String - Module name.
//     * Description - String - Brief user-readable check description.
//     * LongDesc - String - User-readable check details.
//     * SettingsForm - String - Settings form name. Details:
//          See CheckingAndCorrectingDataOverridable.OnFillChecks.
//     * Settings - Structure - Structure that contains a type to be serialized. Details:
//       ** Fields - Arbitrary - Arbitrary list of fields.
//          See CheckingAndCorrectingDataOverridable.OnFillChecks.
//     * TemporaryData - Structure - Structure that contains a type to be serialized. Details:
//       ** Fields - Arbitrary - Arbitrary list of fields.
//          See CheckingAndCorrectingDataOverridable.OnFillChecks.
//     * YouNeedToFillInSettings - Boolean - True for the rows that require settings values. 
//          
//     * Date - Date - Last check date.
//     * Correct - Boolean - Last check flag.
//     * IssuesFound - Boolean - Last check result.
//     * ResultPresentation - String - Last check result.
//     * SpreadsheetDocument - Arbitrary - File containing the last check result.
//
Function Checks(RestoreSettings_ = False, Val GettingPastResult = False) Export
EndFunction

// Searches for issues in the given rows and populates the Result column.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//   Checks - ValueTable - Table retrieved by the Checks() function.
//   Correct - Boolean - If True, data issues need to be fixed.
//   SaveResult - Boolean - If True, save the result to the attachment.
//
// Returns:
//   Boolean - True means that a check is executed, False means that you must fill in the settings.
//
Function CheckData_(Checks, Correct = False, SaveResult = False) Export
EndFunction

// Extracts a spreadsheet document from an attached ZIP archive.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//   AttachedFile - CatalogRef.DataCheckAndAdjustmentHistoryAttachedFiles - File to extract a spreadsheet document from.
//      
//
// Returns:
//   SpreadsheetDocument - a spreadsheet document extracted from the archive. If a spreadsheet document
//      is not found, an exception will be raised.
//
Function TableDocumentFromAttachedFile(AttachedFile) Export
EndFunction

// Returns the SSL integration flag.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//   Boolean - True if integrated, False if not integrated.
//
Function ImplementedSSL() Export
EndFunction

// Returns a module by name.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//   Name - String - Common module name.
//
// Returns:
//   CommonModule - CommonModule.
//
Function Module(Name) Export
EndFunction

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
		
	ExportImportData.AddTypeExcludedFromUploadingUploads(
		Types,
		Metadata.Catalogs["DataCheckAndAdjustmentHistory"],
		ExportImportData.ActionWithLinksDoNotUnloadObject());	
	
	ExportImportData.AddTypeExcludedFromUploadingUploads(
		Types,
		Metadata.Catalogs["DataCheckAndAdjustmentHistoryAttachedFiles"],
		ExportImportData.ActionWithLinksDoNotUnloadObject());	
	
EndProcedure

#EndRegion
