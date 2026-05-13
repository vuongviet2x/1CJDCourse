#Region Public

// Runs during a generation of a list of available check and correction handlers.
// Supports appending the list with custom data processors.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   Handlers - Map - Map with the following elements:
//     * Key - UUID - Check ID.
//     * Value - String - Name of the check module that contains the following export procedures::
//         DataCheckAndAdjustment_FillInfo. Procedure parameters
//              * InformationRecords - Structure - Structure with the following keys:
//                   ** Description - String - Check description.
//                   ** LongDesc - String - Check details (optional).
//                   ** SeparatedData - Boolean - Determines which data will be checked.
//                           Different modes include different check sets.
//                   ** Settings - Structure - User customizable settings.
//                         Applicable if a settings form is specified. The settings are saved upon changes.
//                   ** SettingsForm - String - Settings form full name (optional).
//                         Takes the following parameters:
//                           * Settings - String - Settings obtained from the FillInfo procedure. 
//                           * TemporaryData - String - Temporary settings obtained from the setting form.
//                                 
//                           * Correct - Boolean - If True, data correction is required.
//                         In the settings form, after editing, put all the settings in the temporary storage with
//                         new addresses and return the structure with the keys.:
//                           * Settings - String - Settings obtained from the FillInfo procedure. 
//                           * TemporaryData - String - Temporary settings obtained from the setting form.
//         :
//              * Settings - Structure - Settings obtained from the FillInfo procedure.
//              * TemporaryData - Structure - Temporary settings obtained from the setting form.
//              * Correct - Boolean - If True, data correction is required.
//                                      In the settings form, after editing, put all the settings in the temporary storage with
//                                      new addresses and return the structure with the keys.
//              * Cancel - Boolean - If True, the settings have errors.
//         DataCheckAndAdjustment_CheckData, procedure parameters:
//              * Settings - Structure - Settings obtained from the FillInfo procedure.
//              * TemporaryData - Structure - Temporary settings obtained from the setting form.
//              * Correct - Boolean - If True, data correction is required.
//                                      In the settings form, after editing, put all the settings in the temporary storage with
//                                      new addresses and return the structure with the keys.
//              * Result - Structure - Structure with the following keys:
//                 ** IssuesFound - Boolean - By default, False.
//                 ** ResultPresentation - String - Brief result presentation. 
//                    Required if IssuesFound = True.
//                 ** SpreadsheetDocument - SpreadsheetDocument - Detailed presentation (optional).
//
// Example:
//   Handlers.Insert(New UUID("2b1043e2-9e00-4518-ac0d-1a2befdcce1x"), 
//   					  "DataProcessors.CheckChangesInAccountingRegisters");
//
Procedure OnFillChecks(Handlers) Export
EndProcedure

#EndRegion
