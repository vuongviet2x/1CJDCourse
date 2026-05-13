
#Region Public

// Runs upon determining services that support migration.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   Services - ValueList - Value is the service address; presentation is the service presentation.
//
Procedure OnDefineServices(Services) Export
EndProcedure

// Data export handler.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   Object - ConstantValueManager, CatalogObject, DocumentObject, ChartOfAccountsObject -
//			- ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet -
//          - AccumulationRegisterRecordSet, AccountingRegisterRecordSet, CalculationRegisterRecordSet -
//			- SequenceRecordSet, RecalculationRecordSet, BusinessProcessObject, TaskObject - Object being exported.
//   Cancel - Boolean - If True, the object will not be exported.
//
Procedure OnExportObject(Object, Cancel) Export
EndProcedure

// Data import handler.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   Object - ConstantValueManager, CatalogObject, DocumentObject, ChartOfAccountsObject -
//			- ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet -
//          - AccumulationRegisterRecordSet, AccountingRegisterRecordSet, CalculationRegisterRecordSet -
//			- SequenceRecordSet, RecalculationRecordSet, BusinessProcessObject, TaskObject - Object being imported.
//   Cancel - Boolean - If True, the object will not be imported.
//
Procedure OnImportObject(Object, Cancel) Export
EndProcedure

#EndRegion
	
