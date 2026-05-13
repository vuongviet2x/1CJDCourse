// @strict-types

#Region Internal

// Called upon registration of arbitrary data import handlers.
// This procedure requires that you add information on the arbitrary data import handlers
// being registered to the value table.
// Parameters:
//	HandlersTable - ValueTable - Columns:
//	* MetadataObject - MetadataObject - a handler to be registered is called
//      when the object data is exported.
//	* Handler - CommonModule - Common module that contains the implementation of a custom data import handler.
//      The list of export procedures to be implemented in the handler depends on the values in the following value table columns.
//      
//      
//	* Version - String - Version of data import/export handler API supported by the handler.
//      
//	* BeforeMapRefs - Boolean - Flag specifying whether the handler must be called
//      before mapping the source infobase references and the current infobase references associated with this metadata
//      object. If set to True, the common module of the handler must include
//      the BeforeMapRefs() exportable procedure
//      supporting the following parameters::
//        Container - DataProcessorObject.ExportImportDataContainerManager - Container
//          manager used for data import. For more information, see the comment
//          to the ExportImportDataContainerManager handler API.
//        MetadataObject - MetadataObject - Handler is called
//          before the object references are mapped.
//        StandardProcessing - Boolean - If set to False in BeforeMapRefs(),
//          the MapRefs() function of the corresponding
//          common module will be called instead of the standard
//          reference mapping (searching the current infobase for objects with the natural key values
//          identical to the values exported from the source infobase) in the
//          BeforeMapRefs() procedure whose StandardProcessing parameter value
//          was set to False.
//          MapRefs() function parameters:
//            Container - DataProcessorObject.ExportImportDataContainerManager - Container
//              manager used for data import. For more information, see the comment
//              to the ExportImportDataContainerManager handler API.
//            SourceRefsTable - ValueTable - Contains details on references
//              exported from the original infobase. Columns:
//                SourceRef - AnyRef - Source infobase object reference
//                  to be mapped to the current infobase reference.
//                The other columns are identical to the object's natural key fields
//                  that were passed to the
//                  ExportImportInfobaseData.MustMapRefOnImport() function.
//          MapRefs function returns ValueTable. Columns:
//            SourceRef - AnyRef - Object reference exported from the source infobase.
//            Ref - AnyRef - Reference mapped to the original reference in the current infobase.
//        Cancel - Boolean - If set to True in BeforeMapRefs(), references matching
//          the current metadata object
//          are not mapped.
//	* BeforeImportType - Boolean - a flag specifying whether the handler must be called
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
//	* BeforeImportObject - Boolean -  a flag specifying whether the handler must be called before
//      importing the data object associated with this metadata
//      object. If set to True, the common module of the handler must
//      include the exportable procedure BeforeImportObject()
//      supporting the following parameters:
//        Container - DataProcessorObject.ExportImportDataContainerManager -
//          a container manager used for data import. For more information, see the comment
//          to ExportImportDataContainerManager data processor API.
//        Object - ConstantValueManager, CatalogObject, DocumentObject,
//          BusinessProcessObject, TaskObject, ChartOfAccountsObject, ExchangePlanObject,
//          ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet,
//          AccumulationRegisterRecordSet, AccountingRegisterRecordSet,
//          CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet -
//          an infobase data object imported after the handler is called.
//          The value passed to the BeforeImportObject() procedure as an
//          Object parameter value can be modified inside the BeforeImportObject() handler procedure.
//        Artifacts - Array of XDTODataObject - additional data logically associated
//          with the data object but not contained in it. Generated in the
//          BeforeExportObject() exportable procedures of data export handlers (see comment to the
//          OnRegisterDataExportHandlers() procedure). Each artifact must be a XDTO data object,
//          for whose type an abstract XDTO type
//          {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact is used as the base type. You can use XDTO packages
//          that are not included in the ExportImportData subsystem.
//        Cancel - Boolean - if set this parameter
//          to True in the BeforeImportObject() procedure, the data object is not imported.
//	* AfterImportObject - Boolean - a flag specifying whether the handler must be called
//      after importing a data object associated with this metadata
//      object. If set to True, the common module of the handler must include
//      the exportable procedure AfterImportObject()
//      supporting the following parameters:
//        Container - DataProcessorObject -ExportImportDataContainerManager - a container
//          manager used for data import. For more information, see the comment
//          to ExportImportDataContainerManager handler interface.
//        Object - ConstantValueManager, CatalogObject, DocumentObject,
//          BusinessProcessObject, TaskObject, ChartOfAccountsObject, ExchangePlanObject,
//          ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet,
//          AccumulationRegisterRecordSet, AccountingRegisterRecordSet,
//          CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet -
//          an infobase data object exported after calling the handler.
//        Artifacts - Array of XDTODataObject - additional data logically associated with the data object
//          but not contained in it. Generated in exportable procedures
//          BeforeExportObject() of data export handlers (see comment to the
//          OnRegisterDataExportHandlers() procedure. Each artifact must be an XDTO object
//          with an abstract XDTO type used as a base type
//          {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. You can use XDTO packages
//          that are not included in the ExportImportData subsystem.
//	* AfterLoadingType - Boolean - a flag specifying whether the handler must be called
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
	
	For Each Table In RecordsetTablesWithSupportForTotals() Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Table;
		NewHandler.Handler = ExportImportDataTotalsManagement;
		NewHandler.BeforeImportType = True;
		NewHandler.AfterLoadingType = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
		
	EndDo;
	
EndProcedure

// Executes handlers before importing a particular data type.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container
//		manager used for data export. For more information, see the comment
//		to ExportImportDataContainerManager handler interface.
//	MetadataObject - MetadataObject - Metadata object.
//	Cancel - Boolean - indicates if the operation is completed.
//
Procedure BeforeImportType(Container, MetadataObject, Cancel) Export
	
	Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
	
	If CommonCTL.IsAccumulationRegister(MetadataObject)
		And MetadataObject.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers
		And Manager.GetAggregatesMode() Then
			
		Manager.SetAggregatesUsing(False);
		
	Else		
		
		Manager.SetTotalsUsing(False);
			
	EndIf;
	
EndProcedure

// See description of the OnAddInternalEvents() procedure in the ExportImportDataInternalEvents common module.
// 
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager -
//	MetadataObject - MetadataObjectAccumulationRegister, MetadataObjectAccountingRegister, MetadataObjectInformationRegister -
//
Procedure AfterLoadingType(Container, MetadataObject) Export
	
	Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
	
	If CommonCTL.IsAccumulationRegister(MetadataObject)
		And MetadataObject.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers
		And Manager.GetAggregatesMode() Then
			
		Manager.SetAggregatesUsing(True);
		
	Else		
		
		Manager.SetTotalsUsing(True);
			
	EndIf;
	
	If (CommonCTL.IsAccumulationRegister(MetadataObject) 
		And MetadataObject.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Balance) 
		Or CommonCTL.IsAccountingRegister(MetadataObject) Then
		
		If Not Manager.GetPresentTotalsUsing() Then
			Manager.SetPresentTotalsUsing(True);
		EndIf;
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region Private

// Returns:
// 	Array of MetadataObject - 
//
Function RecordsetTablesWithSupportForTotals()
	
	Result = New Array; // Array of MetadataObject
	
	FillInSetsTableByMetadataCollection(Result, Metadata.InformationRegisters);
	FillInSetsTableByMetadataCollection(Result, Metadata.AccumulationRegisters);
	FillInSetsTableByMetadataCollection(Result, Metadata.AccountingRegisters);
	
	Return Result;
	
EndFunction

Procedure FillInSetsTableByMetadataCollection(Sets, Collection)
	
	For Each MetadataObject In Collection Do
		
		If CommonCTL.IsRecordSetSupportingTotals(MetadataObject) Then
			Sets.Add(MetadataObject);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion