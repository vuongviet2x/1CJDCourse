///////////////////////////////////////////////////////////////////////////////////////////////////////////
// ExportImportDataOverridable: Export and import event handling in the area.
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//@strict-types

#Region Public

// Fills in an array of types for which the reference
// annotation in files must be used upon export.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Types - Array of MetadataObject - Array of MetadataObject types.
//
Procedure OnFillTypesThatRequireRefAnnotationOnImport(Types) Export
EndProcedure

// Fills in an array of shared data types that support reference mapping
// upon data import to another infobase.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Types - Array of MetadataObject - Array of MetadataObject types.
//
Procedure OnFillCommonDataTypesSupportingRefMappingOnExport(Types) Export
EndProcedure

// Fills in the array of shared data types that do not require reference mapping
// upon data import to another infobase because the correct reference mapping
// is provided by other tools.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Types - Array of MetadataObject - Array of MetadataObject types.
//
Procedure OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport(Types) Export
EndProcedure

// Fills in an array of types excluded from data import and export.
//
// Parameters:
//  Types - Array of MetadataObject, FixedStructure: 
//		* Type - MetadataObject
//		* Action - String - 
//	To add a structure, we recommend that you use ExportImportData.
Procedure OnFillTypesExcludedFromExportImport(Types) Export
EndProcedure

// Called before data export.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - Container manager used for data export.
//   For details, see comments to the API of ExportImportDataContainerManager.
//
Procedure BeforeExportData(Container) Export
	
EndProcedure

// Called upon registration of arbitrary data export handlers. 
// In this procedure, it is necessary to complete the handler table with information 
// about arbitrary data export handlers to register.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//	HandlersTable - ValueTable - Details:
//	 * MetadataObject - MetadataObject - Metadata object during whose data export the handler is called.
//	 * Handler - CommonModule - Common module that contains the implementation of a custom data export handler. 
//		The list of export procedures to be implemented in the handler depends on the values in the following value table columns. 
//		
//	 * Version - String - Version of data import/export handler API supported by the handler.
//	 * BeforeUnloadingType - Boolean - Flag indicating whether the handler must be called before exporting all infobase objects associated with this metadata
//      	object. If set to True, the common module of the handler must include
//      	the exportable procedure BeforeExportType()
//      	supporting the following parameters
//      	Container - DataProcessorObject.ExportImportDataContainerManager - a container:
//        		manager used for data export. For more information, see the comment
//          		to ExportImportDataContainerManager data processor API,
//          		Serializer - XDTOSerializer - a serializer initialized with reference
//        		annotation support. If you need to export additional data
//          		in an arbitrary export handler, use XDTOSerializer,
//          		passed to the BeforeExportType() procedure
//          	    as the Serializer parameter value, and not obtained using global
//          		context property XDTOSerializer,
//          		MetadataObject - MetadataObject - a handler is called
//        		before the object data is exported.
//          		Cancel - Boolean - If the parameter value is set to True
//        		in the BeforeExportType() procedure, the objects corresponding
//          		to the current metadata object are not exported.
//          		
//	 * BeforeExportObject - Boolean - Flag specifying whether to call the handler before
//      	exporting a specific infobase object. If set to
//      	True, the common module of the handler must implement the
//      	BeforeExportType() exportable procedure supporting the following parameters::
//        		Container - DataProcessorObject.ExportImportDataContainerManager - Container
//          		manager used for data export. For more information, see the comment
//          		to the ExportImportDataContainerManager data processor API.
//        		ObjectExportManager - DataProcessorObject.ExportImportDataInfobaseDataExportManager -
//          		Export manager of the current object. For more information, see the comment to the
//          		data processor API. Parameter is passed only if procedures of handlers
//          		with version not earlier than 1.0.0.1 specified upon registration are called.
//        		Serializer - XDTOSerializer initialized with
//          		reference annotation support. If an arbitrary export handler requires
//          		additional data export, use
//          	    XDTOSerializer passed to the BeforeExportObject() procedure as the
//          		Serializer parameter value, not obtained using the XDTOSerializer global
//          		context property.
//        		Object - ConstantValueManager, CatalogObject, DocumentObject,
//          		BusinessProcessObject, TaskObject, ChartOfAccountsObject, ExchangePlanObject,
//          		ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet,
//          		AccumulationRegisterRecordSet, AccountingRegisterRecordSet,
//          		CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet -
//          		Infobase data object exported after calling the handler.
//          		Value passed to the BeforeExportObject() procedure. It can be changed as the
//          		Object parameter value in the BeforeExportObject() handler.
//          		The changes will be reflected in the object serialization in export files, but
//          		not in the infobase.
//        		Artifacts - Array of XDTODataObject - Set of additional information logically
//          		associated with the object but not contained in it (object artifacts). Artifacts must be
//          		created in the BeforeExportObject() handler and added to the array passed
//          		as the Artifacts parameter value. Each artifact must be an XDTO object
//          		with an abstract {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact XDTO type used as a base type
//          		. You can use XDTO packages
//          		that are not included in the ExportImportData subsystem.
//          		The artifacts generated in the BeforeExportObject() procedure will be available in the data import handler
//          		procedures (see the comment to the OnRegisterDataImportHandlers() procedure).
//        		Cancel - Boolean - If set
//           		to True in the BeforeExportObject() procedure, the object, which required calling the handler,
//           		is not exported.
//	 * AfterUnloadingType - Boolean - a flag specifying whether the handler must be called before exporting
//      	all infobase objects associated with this metadata object. If set to True,
//      	the common module of the handler must include the exportable procedure
//      	AfterExportType() supporting the following parameters:
//        		Container - DataProcessorObject.ExportImportDataContainerManager - a container
//          		manager used for data export. For more information, see the comment
//          		to ExportImportDataContainerManager data processor API,
//        		Serializer - XDTOSerializer - a serializer initialized with reference
//          		annotation support. If you need to export additional data
//          		in an arbitrary export handler,
//          	    use XDTOSerializer, passed to the BeforeExportType() procedure
//          		as the Serializer parameter value, and not obtained using global
//          		context property XDTOSerializer,
//        		MetadataObject - MetadataObject - a handler is called
//          		before the object data is exported.
//
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
EndProcedure

// Called after data export.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - Container manager used for data export.
//   For details, see comments to the API of ExportImportDataContainerManager.
//
Procedure AfterExportData(Container) Export
EndProcedure

// Called before data import.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - Container manager used for data import. 
//  For details, see comments to the API of ExportImportDataContainerManager.
//
Procedure BeforeImportData(Container) Export
EndProcedure

// Called upon registration of arbitrary data import handlers. 
// In this procedure, it is necessary to complete this value table with information 
// about arbitrary data import handlers to register.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  HandlersTable - ValueTable - Details:
//	 * MetadataObject - MetadataObject - Metadata object during whose data import the handler is called.
//	 * Handler - CommonModule - Common module that contains the implementation of a custom data import handler.
//      The list of export procedures to be implemented in the handler depends on the values in the following value table columns.
//      
//      
//	 * Version - String - Version of data import/export handler API supported by the handler.
//	 * BeforeMapRefs - Boolean - Flag specifying whether the handler must be called
//      before mapping the source infobase references and the current infobase references associated with this metadata
//      object. If set to True, the common module of the handler must include
//      the BeforeMapRefs() exportable procedure
//      supporting the following parameters::
//        Container - DataProcessorObject.ExportImportDataContainerManager - Container
//          manager used for data import. For more information, see the comment
//          to the ExportImportDataContainerManager handler API.
//        MetadataObject - MetadataObject - Handler is called
//        before the object references are mapped.
//          StandardProcessing - Boolean - If set to False in BeforeMapRefs(),
//          the MapRefs() function of the corresponding
//          common module will be called instead of the standard
//          reference mapping (searching the current infobase for objects with the natural key values
//          identical to the values exported from the source infobase) in the
//          BeforeMapRefs() procedure whose StandardProcessing parameter value
//          was set to False.
//            MapRefs() function parameters:
//              Container - DataProcessorObject.ExportImportDataContainerManager - Container
//              manager used for data import. For more information, see the comment
//            to the ExportImportDataContainerManager handler API.
//              SourceRefsTable - ValueTable - Contains details on references
//                exported from the original infobase. Columns:
//                  SourceRef - AnyRef - Source infobase object reference
//                to be mapped to the current infobase reference.
//                  The other columns are identical to the object's natural key fields
//                  that were passed to the
//          DataProcessor.ExportImportInfobaseData.MustMapRefOnImport() function.
//            MapRefs function returns ValueTable. Columns:
//            SourceRef - AnyRef - Object reference exported from the source infobase.
//        Ref - AnyRef - Reference mapped to the original reference in the current infobase.
//          Cancel - Boolean - If set to True in BeforeMapRefs(), references matching
//          the current metadata object
//                                         are not mapped.
//	 * BeforeImportType - Boolean - a flag specifying whether the handler must be called
//      before importing all data objects associated with this metadata
//      object. If set to True, the common module of the handler
//      must include the exportable procedure BeforeImportType()
//      supporting the following parameters:
//        Container - DataProcessorObject.ExportImportDataContainerManager - a container
//          manager used for data import. For more information, see the comment
//          to ExportImportDataContainerManager data processor API.
//        MetadataObject - MetadataObject. The handler is called
//          before the object data is imported.
//        Cancel - Boolean - if the parameter is set to True in the BeforeImportType() procedure,
//          all data objects related to the current metadata
//          object will not be imported.
//	 * BeforeImportObject - Boolean - a flag specifying whether the handler must be called before
//      importing the data object associated with this
//      metadata object. If set to True, the common module of the handler must
//      include the exportable procedure BeforeImportObject()
//      supporting the following parameters:
//        Container - DataProcessorObject.ExportImportDataContainerManager - a container
//          manager used for data export. For more information, see the comment
//          to ExportImportDataContainerManager data processor API.
//        Object - ConstantValueManager, CatalogObject, DocumentObject,
//          BusinessProcessObject, TaskObject, ChartOfAccountsObject, ExchangePlanObject,
//          ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet,
//          AccumulationRegisterRecordSet, AccountingRegisterRecordSet,
//          CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet -
//          an infobase data object imported after the handler is called.
//          The value passed to the BeforeImportObject() procedure as a Object parameter value
//          can be modified inside the BeforeImportObject() handler procedure.
//        Artifacts - Array of XDTODataObject - additional data logically associated
//          with the data object but not contained in it. Generated in exportable procedures
//          BeforeExportObject() of data export handlers (see comment to the
//          OnRegisterDataExportHandlers() procedure. Each artifact must be an XDTO object
//          with an abstract XDTO type used as a base type
//          {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. You can use XDTO packages
//          that are not included in the ExportImportData subsystem.
//        Cancel - Boolean - if set this
//          parameter to True in the BeforeImportObject() procedure, the data object is not imported.
//	 * AfterImportObject - Boolean - a flag specifying whether the handler must be called after
//      importing a data object associated with this metadata
//      object. If set to True, the common module of the handler must
//      include the exportable procedure AfterImportObject()
//      supporting the following parameters:
//        Container - DataProcessorObject -ExportImportDataContainerManager - a container
//          manager used for data import. For more information, see the comment
//          to ExportImportDataContainerManager handler interface.
//        Object - ConstantValueManager, CatalogObject, DocumentObject,
//          BusinessProcessObject, TaskObject, ChartOfAccountsObject, ExchangePlanObject,
//          ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet,
//          AccumulationRegisterRecordSet, AccountingRegisterRecordSet,
//          CalculationRegisterRecordSet*, SequenceRecordSet, RecalculationRecordSet -
//          an infobase data object imported before the handler is called.
//        Artifacts - Array of XDTODataObject - additional data logically associated
//          with the data object but not contained in it. Generated in exportable procedures
//          BeforeExportObject() of data export handlers (see comment to the
//          OnRegisterDataExportHandlers() procedure). Each artifact must be a XDTO data object,
//          for whose type an abstract XDTO type
//          {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact is used as the base type. You can use XDTO packages
//          that are not included in the ExportImportData subsystem.
//	 * AfterLoadingType - Boolean - a flag specifying whether the handler must be called
//      after importing all data objects associated with this metadata
//      object. If set to True, the common module of the handler
//      must include the exportable procedure AfterImportType()
//      supporting the following parameters:
//        Container - DataProcessorObject.ExportImportDataContainerManager - a container
//          manager used for data import. For more information, see the comment
//          to ExportImportDataContainerManager data processor API.
//        MetadataObject - MetadataObject - a handler is called after all its objects
//          are imported.
//
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
EndProcedure

// Called after data import.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - Container manager used for data import.
//   For details, see comments to the API of ExportImportDataContainerManager.
//
Procedure AfterImportData(Container) Export
EndProcedure

// Runs before the infobase user is imported.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - Container manager used for data import.
//    For details, see comments to the API of ExportImportDataContainerManager.
//    
//  Serialization - XDTODataObject - {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}InfoBaseUser,
//    infobase user serialization,
//  IBUser - InfoBaseUser - User deserialized from the export.
//  Cancel - Boolean - If False, the procedure skips infobase user import.
//    
//
Procedure OnImportInfobaseUser(Container, Serialization, IBUser, Cancel) Export
EndProcedure

// Runs after the infobase user is imported.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - Container manager used for data import.
//    For details, see comments to the API of ExportImportDataContainerManager.
//    
//  Serialization - XDTODataObject - {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}InfoBaseUser,
//    infobase user serialization,
//  IBUser - InfoBaseUser - User deserialized from the export.
//
Procedure AfterImportInfobaseUser(Container, Serialization, IBUser) Export
EndProcedure

// Runs after all infobase users are imported.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - Container manager used for data import.
//    For details, see comments to the API of ExportImportDataContainerManager.
//    
//
Procedure AfterImportInfobaseUsers(Container) Export
EndProcedure

// Fills in an array of metadata excluded from the export in the mode for technical support.
// Links to excluded reference data will also be cleared
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Types - Array of MetadataObject - Array of MetadataObject types.
//
Procedure WhenFillingInMetadataExcludedFromUploadingInTechnicalSupportMode(Types) Export
EndProcedure

#EndRegion