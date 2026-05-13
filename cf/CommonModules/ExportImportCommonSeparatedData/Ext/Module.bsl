////////////////////////////////////////////////////////////////////////////////
// "Data import and export" subsystem.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Fills in an array of types for which the reference annotation
// in files must be used upon export.
//
// Parameters:
//  Types - Array of MetadataObject - metadata objects. 
//
Procedure OnFillTypesThatRequireRefAnnotationOnImport(Types) Export
	
	ListOfSharedMetadataObjects = ExportImportCommonSeparatedDataCached.SharedMetadataObjects_();
	
	For Each KeyAndValue In ListOfSharedMetadataObjects Do
		
		For Each TypeName In KeyAndValue.Value.Objects Do
			
			Types.Add(Metadata.FindByFullName(TypeName));
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Called upon registration of arbitrary data export handlers.
//
// Parameters:
//   HandlersTable - ValueTable -  This procedure requires
//  that you add information on the arbitrary data export handlers being registered
//  to the value table. Columns::
//    MetadataObject - MetadataObject - Metadata object, whose data export
//      calls a handler to be exported.
//    Handler - CommonModule - Common module implementing an arbitrary
//      data export handler. The set of export procedures to be implemented
//      in the handler depends on the values of the following
//      value table columns:
//    Version - String - Number of the interface version of data export/import handlers
//      supported by the handler.
//    BeforeExportType - Boolean - Flag specifying whether the handler must be called
//      before exporting all infobase objects associated with this metadata
//      object. If set to True, the common module of the handler must include
//      the BeforeExportType() exportable procedure
//      supporting the following parameters:
//        Container - DataProcessorObject -ExportImportContainerManagerData - Container
//          manager used for data export. For more information, see the comment
//          to the ExportImportDataContainerManager handler interface.
//        Serializer - XDTOSerializer - Serializer initialized with reference
//          annotation support. If you need to export
//          additional data in an arbitrary export handler, use
//          XDTOSerializer, passed to the BeforeExportType() procedure
//          as the Serializer parameter value, and not obtained using the XDTOSerializer global
//          context property.
//        MetadataObject - MetadataObject - Handler is called
//          before the object data is exported.
//        Cancel - Boolean - If set to True
//          in the BeforeExportType() procedure, the objects matching
//          the current metadata object are not exported.
//    BeforeExportObject - Boolean - Flag specifying whether the handler
//      must be called before exporting a specific infobase object. If set to True,
//      the common module of the handler must include the
//      BeforeExportType() exportable procedure supporting the following parameters:
//        Container - DataProcessorObject -ExportImportContainerManagerData - Container
//          manager used for data export. For more information, see the comment
//          to the ExportImportDataContainerManager handler interface.
//        ObjectExportManager - DataProcessorObject - ExportImportDataInfobaseDataExportManager -
//          Export manager of the current object. For more information, see the comment to the
//          ExportImportDataInfobaseDataExportManager data processor API. Parameter is passed only if
//          procedures of handlers with version not earlier than 1.0.0.1 specified upon registration are called.
//        Serializer - XDTOSerializer - Serializer initialized with reference
//          annotation support. If you need to export
//          additional data in an arbitrary export handler, use
//          XDTOSerializer, passed to the BeforeExportObject() procedure
//          as the Serializer parameter value, and not obtained using the XDTOSerializer global
//          context property.
//        Object - ManagerOfConstantValue.* - CatalogObject.*, DocumentObject.*,
//          BusinessProcessObject.*, TaskObject.*, ChartOfAccountsObject.*, ExchangePlanObject.*,
//          ChartOfCharacteristicTypesObject.*, ChartOfCalculationTypesObject.*, InformationRegisterRecordSet.*,
//          AccumulationRegisterRecordSet.*, AccountingRegisterRecordSet.*,
//          CalculationRegisterRecordSet*, SequenceRecordSet*, RecalculationRecordSet* -
//          Infobase data object imported before the handler is called.
//          Value passed to the BeforeExportObject() procedure.
//          It can be changed as the Object parameter value in the BeforeExportObject() handler.
//          The changes will be reflected in the object serialization in export files,
//          but not in the infobase.
//        Artifacts - Array of XDTODataObject - Set of additional information logically
//          associated with the object but not contained in it (object artifacts). Artifacts must be created
//          in the BeforeExportObject() handler and added to the array
//          passed as the Artifacts parameter value. Each artifact must be an XDTO data object,
//          for whose type an abstract {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact XDTO type
//          is used as the base type. You can use XDTO packages
//          that are not included in the ExportImportData subsystem. The artifacts
//          generated in the BeforeExportObject() procedure will be available in the data import handler
//          procedures (see the comment to the OnRegisterDataImportHandlers() procedure).
//        Cancel - Boolean - If set to True
//           in the BeforeExportObject() procedure, the object, which required
//           calling the handler, is not exported.
//    AfterExportType - Boolean - Flag specifying whether the handler is called after all
//      infobase objects associated with this metadata object are exported. If set to True,
//      the common module of the handler must include the
//      AfterExportType() exportable procedure supporting the following parameters:
//        Container - DataProcessorObject -ExportImportContainerManagerData - Container
//          manager used for data export. For more information, see the comment
//          to ExportImportDataContainerManager handler interface.
//        Serializer - XDTOSerializer - Serializer initialized with reference
//          annotation support. If an arbitrary export handler requires
//          additional data export, use XDTOSerializer
//          passed to the BeforeExportType() procedure
//          as the Serializer parameter value, not obtained using
//          the XDTOSerializer global context property.
//        MetadataObject - MetadataObject - Handler is called after the object
//          data is exported.
//
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	ListOfSharedMetadataObjects = ExportImportCommonSeparatedDataCached.SharedMetadataObjects_();
	
	For Each KeyAndValue In ListOfSharedMetadataObjects Do
		
		For Each MetadataObjectName In KeyAndValue.Value.Objects Do
			
			NewHandler = HandlersTable.Add();
			NewHandler.MetadataObject = Metadata.FindByFullName(MetadataObjectName);
			NewHandler.Handler = ExportImportCommonSeparatedData;
			NewHandler.AfterExportObject = True;
			NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure AfterExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts) Export
	
	ListOfSharedMetadataObjects = ExportImportCommonSeparatedDataCached.SharedMetadataObjects_();
	
	ObjectFoundInCache = False;
	MetadataObject = Object.Metadata(); // MetadataObject
	
	For Each KeyAndValue In ListOfSharedMetadataObjects Do
		For Each MetadataObjectName In KeyAndValue.Value.Objects Do
			If MetadataObjectName = MetadataObject.FullName() Then
				ObjectFoundInCache = True;
			EndIf;
		EndDo;
	EndDo;
	
	If Not ObjectFoundInCache Then
		
		Raise StrTemplate(
			NStr("ru = 'Объект метаданных %1 не может быть обработчиком %2,
                  |т.к. отсутствует в кэше совместно-разделенных объектов.
                  |Если после редактирования структуры метаданных конфигурации кэш не обновлялся - необходимо выполнять
                  |обновление кэша совместно-разделенных объектов с помощью вызова метода
                  |%3';
					|en = 'The %1 metadata object cannot be the %2 handler
					|as it is missing from the cache of objects separated together.
					|If the cache is not updated after the metadata structure is edited,
					|update the cache of objects separated together by calling the method
					|%3';", Metadata.DefaultLanguage.LanguageCode),
			MetadataObject.FullName(),
			"UploadingSharedData.BeforeExportObject",
			"ExportImportCommonSeparatedData.FillCacheOfSharedObjects");
		
	EndIf;
	
	ObjectExportManager.YouNeedToRecreateLinkWhenUploading(Object.Ref);
	
EndProcedure

// Called upon registration of arbitrary data import handlers.
//
// Parameters:
//   HandlersTable - ValueTable -  This procedure requires that you
//  add information on the arbitrary
//  data import handlers being registered to the value table. Columns::
//    MetadataObject - MetadataObject - Handler to be registered
//      is called when the object data is exported.
//    Handler - CommonModule - Common module implementing
//      an arbitrary data import handler. The set of export procedures to be
//      implemented in the handler depends on the values of the following
//      value table columns:
//    Version - String - Number of the interface version of data export/import handlers
//      supported by the handler.
//    BeforeMapRefs - Boolean - Flag specifying whether the handler must be called before
//      mapping the source infobase references and the current infobase references associated with this metadata
//      object. If set to True, the common module of the handler must
//      include the BeforeMapRefs() exportable procedure
//      supporting the following parameters:
//        Container - DataProcessorObject -ExportImportContainerManagerData - Container
//          manager used for data import. For more information, see the comment
//          to the ExportImportDataContainerManager data processor API.
//        MetadataObject - MetadataObject - Handler is called
//          before the object references are mapped.
//        StandardProcessing - Boolean - If set to False in BeforeMapRefs(),
//          the MapRefs() function of the corresponding common module will be called instead of the standard
//          reference mapping (searching the current infobase for objects with the natural key
//          values identical to the values exported from the source infobase)
//          in the
//          BeforeMapRefs() procedure whose StandardProcessing
//          parameter value was set to False.
//          MapRefs() function parameters:
//            Container - DataProcessorObject -ExportImportContainerManagerData - Container
//              manager used for data import. For more information, see the comment
//              to the ExportImportDataContainerManager data processor API.
//            SourceRefsTable - ValueTable - Table containing details on references
//              exported from the original infobase. Columns:
//                SourceRef - AnyRef - Source infobase object reference to be mapped
//                  to the current infobase reference,
//                The other columns are identical to the object's natural key fields that
//                  were passed to the
//                  DataProcessor.ExportImportDataInfobaseDataExportManager.MustMapRefOnImport() function.
//          MapRefs function returns ValueTable. Columns:
//            SourceRef - AnyRef - Object reference exported from the source infobase.
//            Ref - AnyRef - Reference mapped to the original reference in the current infobase.
//        Cancel - Boolean - If set to True in BeforeMapRefs(),
//          references matching
//          the current metadata object are not mapped.
//    BeforeImportType - Boolean - Flag specifying whether the handler must be called before
//      importing all data objects associated with this metadata
//      object. If set to True, the common module of the handler must
//      include the BeforeImportType() exportable procedure
//      supporting the following parameters:
//        Container - DataProcessorObject -ExportImportContainerManagerData - Container
//          manager used for data import. For more information, see the comment
//          to the ExportImportDataContainerManager data processor API.
//        MetadataObject - MetadataObject - Handler is called
//          before object data is imported.
//        Cancel - Boolean - If set to True in the BeforeImportType() procedure,
//          the data objects matching the current
//          metadata object are not imported.
//    BeforeImportObject - Boolean - Flag specifying whether the handler must be called before
//      importing the data object associated with this metadata
//      object. If set to True, the common module of the handler must
//      include the BeforeImportObject() exportable procedure
//      supporting the following parameters:
//        Container - DataProcessorObject -ExportImportContainerManagerData - Container
//          manager used for data import. For more information, see the comment
//          to the ExportImportDataContainerManager data processor API.
//        Object - ManagerOfConstantValue.* - CatalogObject.*, DocumentObject.*,
//          BusinessProcessObject.*, TaskObject.*, ChartOfAccountsObject.*, ExchangePlanObject.*,
//          ChartOfCharacteristicTypesObject.*, ChartOfCalculationTypesObject.*, InformationRegisterRecordSet.*,
//          AccumulationRegisterRecordSet.*, AccountingRegisterRecordSet.*,
//          CalculationRegisterRecordSet.*, SequenceRecordSet.*, RecalculationRecordSet.* -
//          Infobase data object imported after the handler is called.
//          The value passed to the BeforeImportObject() procedure as a parameter value.
//          An object can be modified inside the BeforeImportObject() handler procedure.
//        Artifacts - Array of XDTODataObject - Additional data logically associated
//          with the data object but not contained in it. Generated in the
//          BeforeExportObject() exportable procedures of data export handlers (see the comment to the
//          OnRegisterDataExportHandlers() procedure). Each artifact must be an XDTO data object,
//          for whose type an abstract {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact XDTO type
//          is used as the base type. You can use XDTO packages
//          that are not included in the ExportImportData subsystem.
//        Cancel - Boolean - If set this
//          parameter to True in the BeforeImportObject() procedure, the data object is not imported.
//    AfterImportObject - Boolean - Flag specifying whether the handler must be called after
//      importing a data object associated with this metadata
//      object. If set to True, the common module of the handler must
//      include the AfterImportObject() exportable procedure
//      supporting the following parameters:
//        Container - DataProcessorObject -ExportImportContainerManagerData - Container
//          manager used for data import. For more information, see the comment
//          to the ExportImportDataContainerManager data processor API.
//        Object - ManagerOfConstantValue.* - CatalogObject.*, DocumentObject.*,
//          BusinessProcessObject.*, TaskObject.*, ChartOfAccountsObject.*, ExchangePlanObject.*,
//          ChartOfCharacteristicTypesObject.*, ChartOfCalculationTypesObject.*, InformationRegisterRecordSet.*,
//          AccumulationRegisterRecordSet.*, AccountingRegisterRecordSet.*,
//          CalculationRegisterRecordSet.*, SequenceRecordSet.*, RecalculationRecordSet.* -
//          Infobase data object imported before the handler is called.
//        Artifacts - Array of XDTODataObject - Additional data logically associated
//          with the data object but not contained in it. Generated in the
//          BeforeExportObject() exportable procedures of data export handlers (see the comment to the
//          OnRegisterDataExportHandlers() procedure). Each artifact must be an XDTO data object,
//          for whose type an abstract {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact XDTO type
//          is used as the base type. You can use XDTO packages
//          that are not included in the ExportImportData subsystem.
//    AfterImportType - Boolean - Flag specifying whether the handler must be called after
//      importing all data objects associated with this metadata
//      object. If set to True, the common module of the handler must
//      include the AfterImportType() exportable procedure
//      supporting the following parameters:
//        Container - DataProcessorObject -ExportImportContainerManagerData - Container
//          manager used for data import. For more information, see the comment
//          to the ExportImportDataContainerManager data processor API.
//        MetadataObject - MetadataObject - Handler is called
//          after all its objects are imported.
//
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
	
	ListOfSharedMetadataObjects = ExportImportCommonSeparatedDataCached.SharedMetadataObjects_();
	
	For Each KeyAndValue In ListOfSharedMetadataObjects Do
		
		For Each MetadataObjectName In KeyAndValue.Value.Constants Do
			
			NewHandler = HandlersTable.Add();
			NewHandler.MetadataObject = Metadata.FindByFullName(MetadataObjectName);
			NewHandler.Handler = ExportImportCommonSeparatedData;
			NewHandler.BeforeImportObject = True;
			NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
			
		EndDo;
		
		For Each MetadataObjectName In KeyAndValue.Value.Objects Do
			
			NewHandler = HandlersTable.Add();
			NewHandler.MetadataObject = Metadata.FindByFullName(MetadataObjectName);
			NewHandler.Handler = ExportImportCommonSeparatedData;
			NewHandler.BeforeImportObject = True;
			NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
			
		EndDo;
		
		For Each MetadataObjectName In KeyAndValue.Value.RecordSets Do
			
			NewHandler = HandlersTable.Add();
			NewHandler.MetadataObject = Metadata.FindByFullName(MetadataObjectName);
			NewHandler.Handler = ExportImportCommonSeparatedData;
			NewHandler.BeforeImportObject = True;
			NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure BeforeImportObject(Container, Object, Artifacts, Cancel) Export
	
	If CommonCTL.IsRecordSet(Object.Metadata()) Then
		If CommonCTL.IsIndependentRecordSet(Object.Metadata()) Then
			Object.Filter.DataAreaAuxiliaryData.Use = False;
		EndIf;
		For Each Record In Object Do
			Record.DataAreaAuxiliaryData = 0;
		EndDo;
	Else
		
		Object.DataAreaAuxiliaryData = 0;
		
	EndIf;
	
EndProcedure

#EndRegion
