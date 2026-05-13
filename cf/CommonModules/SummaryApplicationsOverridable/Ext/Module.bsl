#Region Public

// Handler upon data export.
//
// Parameters:
//   Object - ConstantValueManager, CatalogObject, DocumentObject, ChartOfAccountsObject -
//			- ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet -
//          - AccumulationRegisterRecordSet, AccountingRegisterRecordSet, CalculationRegisterRecordSet -
//			- SequenceRecordSet, RecalculationRecordSet, BusinessProcessObject, TaskObject - Object being exported.
//   ExportingParameters - Structure - Export parameters.
//   XMLWriter - XMLWriter - For manual serialization.
//   ObjectCount - Number - Counter to increase to export the object.
//   Cancel - Boolean - If this parameter is set to True, the object will not be exported. You can serialize the object manually, for example, using ExportParameters.Serializer in XMLWriter.
//   				@skip-check module-empty-method - Overridable method.
//
Procedure OnExportObject(Object, ExportingParameters, XMLWriter, ObjectCount, Cancel) Export
EndProcedure

// Data import handler.
//
// Parameters:
//   Object - ConstantValueManager, CatalogObject, DocumentObject, ChartOfAccountsObject -
//			- ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet -
//          - AccumulationRegisterRecordSet, AccountingRegisterRecordSet, CalculationRegisterRecordSet -
//			- SequenceRecordSet, RecalculationRecordSet, BusinessProcessObject, TaskObject - Object being imported.
//   Cancel - Boolean - If True, the object will not be imported.
//@skip-check module-empty-method - Overridable method.
Procedure OnImportObject(Object, Cancel) Export
EndProcedure

// Handler for registering changes.
//
// Parameters:
//   Source - ConstantValueManager, CatalogObject, DocumentObject, ChartOfAccountsObject -
//			- ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet -
//          - AccumulationRegisterRecordSet, AccountingRegisterRecordSet, CalculationRegisterRecordSet -
//			- SequenceRecordSet, RecalculationRecordSet, BusinessProcessObject, TaskObject - 
//			Object to be registered.
//   Cancel - Boolean - If True, the object will not be registered.
//@skip-check module-empty-method - Overridable method.
Procedure AtRegisteringObjectChanges(Source, Cancel) Export	
EndProcedure

// When determining which metadata objects are allowed to be exported.
// Used for metadata objects added in the extension that cannot be filtered from the 
// Service Manager.
// 
// Parameters:
//  MetadataObjects - Map of KeyAndValue - Collection of the following metadata objects:
//   * Key - String - The metadata object name.
//   * Value - Boolean - Indicates whether it is allowed to export this object.
//@skip-check module-empty-method - Overridable method.
Procedure OnDefineMetadataObjectsAllowedForExport(MetadataObjects) Export
EndProcedure

#EndRegion
	
