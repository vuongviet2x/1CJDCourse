
#Region Internal

// Called upon registration of arbitrary data import handlers.
//
// Parameters:
//   HandlersTable - ValueTable - This procedure requires that you
//  add information on the arbitrary
//  data import handlers to be registered to the value table. Columns::
//    MetadataObject - MetadataObject - Handler to be registered
//      is called when the object data is imported.
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
//        Container - DataProcessorObject.ExportImportContainerManagerData - Container
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
//            Container - DataProcessorObject.ExportImportContainerManagerData - Container
//              manager used for data import. For more information, see the comment
//              to the ExportImportDataContainerManager data processor API.
//            SourceRefsTable - ValueTable - Table containing details on references
//              exported from the original infobase. Columns:
//                SourceRef - AnyRef - Source infobase object reference to be mapped
//                  to the current infobase reference.
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
//          to ExportImportDataContainerManager data processor API.
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
//        Object - ManagerOfConstantValue - CatalogObject, DocumentObject,
//          BusinessProcessObject, TaskObject, ChartOfAccountsObject, ExchangePlanObject,
//          ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet,
//          AccumulationRegisterRecordSet, AccountingRegisterRecordSet,
//          CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet -
//          Infobase data object imported after the handler is called.
//          The value passed to the BeforeImportObject() procedure as a parameter value.
//          An object can be modified inside the BeforeImportObject() handler procedure.
//        Artifacts - Array of XDTODataObject - Additional data logically associated
//          with the data object but not contained in it. Generated in the
//          BeforeExportObject() exportable procedures of data export handlers (see comment to the
//          OnRegisterDataExportHandlers() procedure). Each artifact must be an XDTO data object,
//          for whose type an abstract XDTO type
//          {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact is used as the base type. You can use XDTO packages
//          that are not included in the ExportImportData subsystem.
//        Cancel - Boolean - if set this
//          parameter to True in the BeforeImportObject() procedure, the data object is not imported.
//    AfterImportObject - Boolean - a flag specifying whether the handler must be called after
//      importing a data object associated with this metadata
//      object. If set to True, the common module of the handler must
//      include the exportable procedure AfterImportObject()
//      supporting the following parameters:
//        Container - DataProcessorObject -ExportImportContainerManagerData - a container
//          manager used for data import. For more information, see the comment
//          to ExportImportDataContainerManager data processor API.
//        Object - ConstantValueManager - CatalogObject, DocumentObject,
//          BusinessProcessObject, TaskObject, ChartOfAccountsObject, ExchangePlanObject,
//          ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet,
//          AccumulationRegisterRecordSet, AccountingRegisterRecordSet,
//          CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet -
//          an infobase data object imported before the handler is called.
//        Artifacts - Array of XDTODataObject - additional data logically associated
//          with the data object but not contained in it. Generated in exportable procedures
//          BeforeExportObject() of data export handlers (see comment to procedure
//          OnRegisterDataExportHandlers(). Each artifact must be a XDTO data object,
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
	
	NewHandler = HandlersTable.Add();
	NewHandler.Handler = ExportImportSharedPredefinedData;
	NewHandler.BeforeImportData = True;
	NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
	
EndProcedure

// Parameters:
// 	Container - DataProcessorObject.ExportImportDataContainerManager - a container manager.
Procedure BeforeImportData(Container) Export
	
	If Not Common.DataSeparationEnabled() Then
		
		FileName = Container.GetCustomFile(DataTypeForTableOfAdditionallyUnloadedData());
		NamesOfAdditionallyLoadedFiles = ExportImportData.ReadObjectFromFile(FileName);
		DeleteFiles(FileName);
		
		ImportParameters = New Structure(Container.ImportParameters()); // See ExportImportData.DownloadCurAreaDataFromArchive.ImportParameters
		
		For Each NameOfObjectToLoadAdditionally In NamesOfAdditionallyLoadedFiles Do
			ImportParameters.LoadableTypes.Add(Metadata.FindByFullName(NameOfObjectToLoadAdditionally));
		EndDo;
		
		Container.SetDownloadParameters(ImportParameters);
		
	EndIf;
	
EndProcedure

#Region InternalEventsHandlers

// Called upon registration of arbitrary data export handlers.
//
// Parameters:
//   HandlersTable - ValueTable - This procedure requires
//  that you add information on the arbitrary data export handlers being registered
//  to the value table. Columns::
//    MetadataObject - MetadataObject - Metadata object whose data export
//      calls a handler to be registered.
//    Handler - CommonModule - Common module implementing an arbitrary
//      data export handler. The set of export procedures to be implemented
//      in the handler depends on the values of the following
//      value table columns:
//    Version - String - Number of the interface version of data export/import handlers,
//      supported by the handler.
//    BeforeExportType - Boolean - Flag specifying whether the handler must be called
//      before exporting all infobase objects associated with this metadata
//      object. If set to True, the common module of the handler must include
//      the BeforeExportType() exportable procedure
//      supporting the following parameters:
//        Container - DataProcessorObject - ExportImportContainerManagerData - Container
//          manager used for data export. For more information, see the comment
//          to the ExportImportDataContainerManager handler interface.
//        Serializer - XDTOSerializer - Serializer initialized with reference
//          annotation support. If you need to export
//          additional data in an arbitrary export handler, use
//          XDTOSerializer passed to the BeforeExportType() procedure
//          as the Serializer parameter value, and not obtained using the XDTOSerializer global
//          context property.
//        MetadataObject - MetadataObject - Handler is called
//          before the object data is exported.
//        Cancel - Boolean - If set to True
//          in the BeforeExportType() procedure, the objects matching
//          the current metadata object are not exported.
//    BeforeExportObject - Boolean - Flag specifying whether the handler
//      must be called before exporting a specific infobase object. If set to True,
//      the common module of the handler must include the BeforeExportType() exportable procedure
//       supporting the following parameters:
//        Container - DataProcessorObject.ExportImportContainerManagerData - Container
//          manager used for data export. For more information, see the comment
//          to the ExportImportDataContainerManager handler interface.
//        ObjectExportManager - DataProcessorObject - ExportImportDataInfobaseDataExportManager -
//          Export manager of the current object. For more information, see the comment to the
//          ExportImportDataInfobaseDataExportManager data processor API. Parameter is passed only if
//          procedures of handlers with version not earlier than 1.0.0.1 specified upon registration are called.
//        Serializer - XDTOSerializer - Serializer initialized with reference
//          annotation support. If you need to export
//          additional data in an arbitrary export handler, use
//          XDTOSerializer passed to the BeforeExportObject() procedure
//          as the Serializer parameter value, and not obtained using the XDTOSerializer global
//          context property.
//        Object - ManagerOfConstantValue, CatalogObject, DocumentObject,
//          BusinessProcessObject, TaskObject, ChartOfAccountsObject, ExchangePlanObject,
//          ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet,
//          AccumulationRegisterRecordSet, AccountingRegisterRecordSet,
//          CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet -
//          Infobase data object imported before the handler is called.
//          Value passed to the BeforeExportObject() procedure.
//          It can be changed as the Object parameter value in the BeforeExportObject() handler.
//          The changes will be reflected in the object serialization in export files,
//          but not in the infobase.
//        Artifacts - Array of XDTODataObject - Set of additional information logically
//          associated with the object but not contained in it (object artifacts). Artifacts must be created
//          in the BeforeExportObject() handler and added to the array
//          passed as the Artifacts parameter value. Each artifact must be an XDTO data object,
//          for whose type an abstract XDTO {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact type
//          is used as the base type. You can use XDTO packages
//          that are not included in the ExportImportData subsystem. The artifacts
//          generated in the BeforeExportObject() procedure will be available in the data import handler
//          procedures (see the comment to the OnRegisterDataImportHandlers() procedure).
//        Cancel - Boolean - If set to True
//           in the BeforeExportObject() Procedure, the object, which required
//           calling the handler, is not exported.
//    AfterExportType - Boolean - Flag specifying whether the handler is called after all
//      infobase objects associated with this metadata object are exported. If set to True,
//      the common module of the handler must include the
//      AfterExportType() exportable procedure supporting the following parameters:
//        Container - DataProcessorObject -ExportImportContainerManagerData - Container
//          manager used for data export. For more information, see the comment
//          to the ExportImportDataContainerManager handler interface.
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
	
	NewHandler = HandlersTable.Add();
	NewHandler.Handler = ExportImportSharedPredefinedData;
	NewHandler.BeforeExportData = True;
	NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
	
EndProcedure

Procedure BeforeExportData(Container) Export
	
	ExportingParameters = New Structure(Container.ExportingParameters());
	
	AdditionallyUnloaded = New Array();
	
	ControlRules = ExportImportSharedDataCached.ControlReferencesToUnsharedDataInPartitionedDataWhenUnloading();
	
	For Each ControlRule In ControlRules Do
		
		MetadataObject = Metadata.FindByFullName(ControlRule.Key);
		
		If ExportingParameters.TypesToExport.Find(MetadataObject) <> Undefined Then
			
			For Each FieldName In ControlRule.Value Do
				
				FieldNameStructure = StrSplit(FieldName, ".");
				
				If CommonCTL.IsConstant(MetadataObject) Then
					
					FieldSubstring = "Value";
					TableSubstring = MetadataObject.FullName();
					
				ElsIf CommonCTL.IsRefData(MetadataObject) Then
					
					If FieldNameStructure[2] = "Attribute" Or FieldNameStructure[2] = "Attribute" Then // Not localizable.
						
						FieldSubstring = FieldNameStructure[3];
						TableSubstring = MetadataObject.FullName();
						
					ElsIf FieldNameStructure[2] = "TabularSection" Or FieldNameStructure[2] = "TabularSection" Then // Not localizable.
						
						TabularSectionName = FieldNameStructure[3];
						
						If FieldNameStructure[4] = "Attribute" Or FieldNameStructure[4] = "Attribute" Then // Not localizable.
							
							FieldSubstring = FieldNameStructure[5];
							TableSubstring = MetadataObject.FullName() + "." + TabularSectionName;
							
						Else
							
							RaiseExceptionFailedToDefineField(FieldName, MetadataObject.FullName());
							
						EndIf;
						
					Else
						
						RaiseExceptionFailedToDefineField(FieldName, MetadataObject.FullName());
						
					EndIf;
					
				ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
					
					If FieldNameStructure[2] = "Dimension" Or FieldNameStructure[2] = "Dimension"
							Or FieldNameStructure[2] = "Resource" Or FieldNameStructure[2] = "Resource"
							Or FieldNameStructure[2] = "Attribute" Or FieldNameStructure[2] = "Attribute" Then // Not localizable.
						
						FieldSubstring = FieldNameStructure[3];
						TableSubstring = MetadataObject.FullName();
						
					Else
						
						RaiseExceptionFailedToDefineField(FieldName, MetadataObject.FullName());
						
					EndIf;
					
				Else
					
					Raise StrTemplate(NStr("ru = 'Объект метаданных %1 не поддерживается';
													|en = 'Metadata object %1 is not supported';"), 
						MetadataObject.FullName());
					
				EndIf;
				
				PossibleFieldTypes = Metadata.FindByFullName(FieldName).Type.Types();
				CheckedFieldTypes = New Array();
				For Each PossibleFieldType In PossibleFieldTypes Do
					
					ObjectOfPossibleType = Metadata.FindByType(PossibleFieldType);
					
					If ObjectOfPossibleType = Undefined Then
						// A primitive type.
						Continue;
					EndIf;
					
					If ExportingParameters.TypesToExport.Find(ObjectOfPossibleType) <> Undefined Then
						// The object was originally included in the types being exported
						Continue;
					EndIf;
					
					If AdditionallyUnloaded.Find(ObjectOfPossibleType) <> Undefined Then
						// The object has already been added to the types being additionally exported
						Continue;
					EndIf;
					
					If Not CommonCTL.IsRefDataSupportingPredefinedItems(
						ObjectOfPossibleType) Then
						// The object cannot have predefined items
						Continue;
					EndIf;
					
					CheckedFieldTypes.Add(PossibleFieldType);
					
				EndDo;
				
				If CheckedFieldTypes.Count() = 0 Then
					Continue;
				EndIf;
				
				QueryText = "";
				QueryTextTemplate2 =
				"SELECT TOP 1
				|	VALUETYPE(&FieldName) AS Type
				|FROM
				|	&Table AS T
				|		INNER JOIN &TabPredefined AS TPredefined
				|		ON &FieldName = TPredefined.Ref
				|			AND (TPredefined.Predefined)";
				
				For Each FieldTypeToCheck In CheckedFieldTypes Do
					
					If Not IsBlankString(QueryText) Then
						
						QueryText = QueryText + Chars.LF + "UNION ALL" + Chars.LF;
						
					EndIf;
					
					QueryText = QueryText + QueryTextTemplate2;
					QueryText = StrReplace(QueryText, "&Table", TableSubstring);
					QueryText = StrReplace(QueryText, "&TabPredefined", 
						Metadata.FindByType(FieldTypeToCheck).FullName());
					QueryText = StrReplace(QueryText, "&FieldName", "T." + FieldSubstring);
					
				EndDo;
				
				Query = New Query(QueryText);
				Selection = Query.Execute().Select();
				While Selection.Next() Do
					
					AdditionalMetadataObject = Metadata.FindByType(Selection.Type);
					If AdditionalMetadataObject <> Undefined Then
						AdditionallyUnloaded.Add(AdditionalMetadataObject);
					EndIf;
					
				EndDo;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	UnloadedTypesOfSharedData = New Array(ExportingParameters.UnloadedTypesOfSharedData);
	CommonClientServer.SupplementArray(UnloadedTypesOfSharedData, AdditionallyUnloaded, True);
	ExportingParameters.UnloadedTypesOfSharedData = New FixedArray(UnloadedTypesOfSharedData);
	
	Container.SetUploadParameters(ExportingParameters);
	
	NamesOfAdditionalUnloads = New Array();
	For Each AdditionallyUnloadedObject In AdditionallyUnloaded Do
		NamesOfAdditionalUnloads.Add(AdditionallyUnloadedObject.FullName());
	EndDo;
	
	FileName = Container.CreateCustomFile("xml", DataTypeForTableOfAdditionallyUnloadedData());
	ExportImportData.WriteObjectToFile(NamesOfAdditionalUnloads, FileName);
	Container.FileRecorded(FileName);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function DataTypeForTableOfAdditionallyUnloadedData()
	
	Return "1cfresh\UnseparatedPredefined\AdditionalObjects";
	
EndFunction

Procedure RaiseExceptionFailedToDefineField(Val FieldName, Val ObjectName)
	
	Raise StrTemplate(NStr("ru = 'Не удалось построить запрос получения значения поля %1 объекта метаданных %2';
									|en = 'Cannot build request to get the %1 field value of the %2 metadata object';"),
		FieldName, ObjectName);
	
EndProcedure

#EndRegion