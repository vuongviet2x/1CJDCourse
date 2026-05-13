#Region Internal

// Fills in an array of types for which the reference annotation
// in files must be used upon export.
//
// Parameters:
//  Types - Array of MetadataObject - metadata objects. 
//
Procedure OnFillTypesThatRequireRefAnnotationOnImport(Types) Export
	
	ObjectsWithPredefinedItems = ExportImportPredefinedDataCached.MetadataObjectsWithPredefinedElements();
	For Each TypeName In ObjectsWithPredefinedItems Do
		
		If ReferenceMappingToPredefinedElementsIsRequired(TypeName) Then
			Types.Add(Metadata.FindByFullName(TypeName));
		EndIf;
		
	EndDo;
	
EndProcedure

// Called upon registration of arbitrary data export handlers.
// This procedure requires that you add information on the arbitrary data export handlers 
// being registered to the value table.
// 
// Parameters:
//	HandlersTable - ValueTable - Columns:
//	 * MetadataObject - MetadataObject - Metadata object during whose data export the handler is called.
//	 * Handler - CommonModule - Common module that contains the implementation of a custom data export handler. 
//	    The list of export procedures to be implemented in the handler depends on the values in the following value table columns. 
//	    
//	 * Version - String - Version of data import/export handler API supported by the handler.
//	 * BeforeUnloadingType - Boolean - a flag specifying whether the handler must be called before exporting all infobase objects
//	    associated with this metadata object. If set to True, the common module of the handler must include 
//	    the exportable procedure BeforeExportType() supporting the following parameters:
//        Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used 
//          for data export. For more information, see the comment to data processor API. 
//        Serializer - XDTOSerializer - a serializer initialized with reference annotation support. If you need 
//          to export additional data in an arbitrary export handler, 
//          use XDTOSerializer, passed to the BeforeExportType() procedure 
//          as the Serializer parameter value, and not obtained using global context property XDTOSerializer.
//        MetadataObject - MetadataObject - a handler is called before the object data is exported.
//        Cancel - Boolean - If the parameter value is set to True 
//          in the BeforeExportType() procedure, the objects corresponding to the current metadata object are not exported.
//	 * BeforeExportObject - Boolean - Flag specifying whether the handler must be called before exporting a specific infobase 
//	    object. If set to True, the common handler module must include 
//	    the BeforeExportObject() exportable procedure supporting the following parameters::
//        Container - DataProcessorObject.ExportImportDataContainerManager - Container manager used 
//          for data export. For more information, see the comment to the data processor API.
//        ObjectExportManager - DataProcessorObject.ExportImportDataInfobaseDataExportManager -
//          Export manager of the current object. For more information, see the comment to the data processor API.
//          ExportImportDataInfobaseDataExportManager. Parameter is passed only if
//          procedures of handlers with version not earlier than 1.0.0.1 specified upon registration are called.
//        Serializer - XDTOSerializer - Serializer initialized with reference annotation support. If 
//          you need to export additional data in an arbitrary export handler, 
//          use XDTOSerializer, passed to the BeforeExportObject() procedure as the Serializer 
//          parameter value, and not obtained using the XDTOSerializer global context property.
//        Object - ManagerOfConstantValue, CatalogObject, DocumentObject, BusinessProcessObject, TaskObject, 
//          ChartOfAccountsObject, ExchangePlanObject, ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, 
//          InformationRegisterRecordSet, AccumulationRegisterRecordSet, AccountingRegisterRecordSet,
//          CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet - Infobase 
//          data object exported after calling the handler. Value passed to 
//          the BeforeExportObject() procedure. It can be changed as the Object parameter value in 
//          the BeforeExportObject() handler. The changes will be reflected in the object serialization in export 
//          files, but not in the infobase
//        Artifacts - Array of XDTODataObject - Set of additional information logically associated with the object
//          but not contained in it (object artifacts). Artifacts must be created in 
//          the BeforeExportObject() handler and added to the array passed as the Artifacts parameter value. 
//          Each artifact must be an XDTO data object, for whose type 
//          an abstract {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact XDTO type is used as the base type. You can use 
//          XDTO packages that are not included in the ExportImportData subsystem. The artifacts
//          generated in the BeforeExportObject() procedure will be available in the data import handler
//          procedures (see the comment to the OnRegisterDataImportHandlers() procedure).
//        Cancel - Boolean - If set to 
//        True in the BeforeExportObject() Procedure, the object, which required calling the handler, is not exported.
//	 * AfterUnloadingType - Boolean - a flag specifying whether the handler is called after all infobase 
//	    objects associated with this metadata object are exported. If set to True, the common module of the handler 
//	    must include the exportable procedure BeforeExportType() supporting the following parameters:
//        Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used 
//          for data export. For more information, see the comment to data processor API
//        Serializer - XDTOSerializer initialized with reference annotation support. n case 
//          the arbitrary export handler requires exporting additional data, 
//          use XDTOSerializer passed to the AfterExportType() procedure as value of the 
//          Serializer parameter and not obtained using the XDTOSerializer global context property,
//        MetadataObject - MetadataObject - a handler is called after the object data is exported.
//
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	ObjectsWithPredefinedItems = ExportImportPredefinedDataCached.MetadataObjectsWithPredefinedElements();
	For Each MetadataObjectName In ObjectsWithPredefinedItems Do
		
		If ReferenceMappingToPredefinedElementsIsRequired(MetadataObjectName) Then
			
			NewHandler = HandlersTable.Add();
			NewHandler.MetadataObject = Metadata.FindByFullName(MetadataObjectName);
			NewHandler.Handler = ExportImportPredefinedData;
			NewHandler.AfterExportObject = True;
			NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure AfterExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts) Export
	
	ObjectMetadata = Object.Metadata();
	If CommonCTL.IsRefDataSupportingPredefinedItems(Object.Metadata()) Then
		
		If ReferenceMappingToPredefinedElementsIsRequired(ObjectMetadata.FullName()) Then
			
			If Object.Predefined Then
				
				NaturalKey = New Structure("PredefinedDataName", Object.PredefinedDataName);
				ObjectExportManager.YouNeedToMatchLinkWhenDownloading(Object.Ref, NaturalKey);
				
			EndIf;
			
		Else
			
			Raise StrTemplate(
			NStr("ru = 'Объект метаданных %1 не может быть обработан обработчиком
                  |%2,
                  |т.к. не требуется обеспечивать сопоставление ссылок на его предопределенные элементы.';
					|en = 'The %1 metadata object cannot be processed by the handler
					|%2
					|as the mapping of references to its predefined items is not required.';", Metadata.DefaultLanguage.LanguageCode),
			ObjectMetadata.FullName(),
			"ExportImportPredefinedData.BeforeExportObject");
			
		EndIf;
		
	Else
		Raise StrTemplate(
			NStr("ru = 'Объект метаданных %1 не может быть обработан обработчиком
                  |%2,
                  |т.к. не может содержать предопределенных элементов.';
					|en = 'The %1 metadata object cannot be processed by the handler
					|%2
					|as it cannot contain predefined items.';", Metadata.DefaultLanguage.LanguageCode),
			ObjectMetadata.FullName(),
			"ExportImportPredefinedData.BeforeExportObject");
		
	EndIf;
	
EndProcedure

// Parameters:
// 	HandlersTable - See ExportImportDataOverridable.OnRegisterDataImportHandlers.HandlersTable
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
		
	ObjectsWithPredefinedItems = ExportImportPredefinedDataCached.MetadataObjectsWithPredefinedElements();
	For Each MetadataObjectName In ObjectsWithPredefinedItems Do
		
		If ReferenceMappingToPredefinedElementsIsRequired(MetadataObjectName) Then
			
			NewHandler = HandlersTable.Add();
			NewHandler.MetadataObject = Metadata.FindByFullName(MetadataObjectName);
			NewHandler.Handler = ExportImportPredefinedData;
			NewHandler.BeforeMapRefs = True;
			NewHandler.BeforeImportObject = True;
			NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
// 	Container - DataProcessorObject.ExportImportDataContainerManager - a container manager.
// 	MetadataObject - MetadataObject - Metadata object.
// 	SourceRefsTable - ValueTable - reference table.
// 	StandardProcessing - Boolean - a flag of standard processing.
// 	Cancel - Boolean - indicates that processing is canceled.
Procedure BeforeMapRefs(Container, MetadataObject, SourceRefsTable, StandardProcessing, Cancel) Export
	
	If CommonCTL.IsRefDataSupportingPredefinedItems(MetadataObject)
			And SourceRefsTable.Columns.Find("PredefinedDataName") <> Undefined Then
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used 
//	 for data import. For more information, see the comment to data processor API.
//	RefsMapManager - DataProcessorObject.ExportImportDataReferenceMappingManager - 
//	SourceRefsTable - ValueTable - containing information about references exported from the original infobase. Columns:
//	* SourceRef1 - AnyRef - a source infobase object reference to be mapped to the current infobase reference,
//		Other columns are equal to the fields of a natural object key.
// Returns:
//	ValueTable - Columns:
//	 * SourceRef1 - AnyRef -  an object reference exported from the source infobase,
//	 * Ref - AnyRef - a reference mapped to the original reference in the current infobase.
Function MapRefs(Container, RefsMapManager, SourceRefsTable) Export
	
	SourceLinksForStandardProcessing = New ValueTable();
	For Each Column In SourceRefsTable.Columns Do
		If Column.Name <> "PredefinedDataName" Then
			SourceLinksForStandardProcessing.Columns.Add(Column.Name, Column.ValueType);
		EndIf;
	EndDo;
	
	ColumnName = RefsMapManager.SourceLinkColumnName_();
	
	Result = New ValueTable();
	Result.Columns.Add(ColumnName, SourceRefsTable.Columns.Find(ColumnName).ValueType);
	Result.Columns.Add("Ref", SourceRefsTable.Columns.Find(ColumnName).ValueType);
	
	MetadataObject = Undefined;
	
	For Each SourceRefsTableRow In SourceRefsTable Do
		
		If ValueIsFilled(SourceRefsTableRow.PredefinedDataName) Then
			
			Query = New Query;
			Query.Text = 
				"SELECT
				|	Table.Ref AS Ref
				|FROM
				|	&RefsTable AS Table
				|WHERE
				|	Table.PredefinedDataName = &PredefinedDataName";
			Query.SetParameter("PredefinedDataName", SourceRefsTableRow.PredefinedDataName);
			MetadataObject = SourceRefsTableRow[ColumnName].Metadata(); // MetadataObject
			Query.Text = StrReplace(Query.Text, "&RefsTable", MetadataObject.FullName());
			QueryResult = Query.Execute();
			If Not QueryResult.IsEmpty() Then
				
				Selection = QueryResult.Select();
				
				If Selection.Count() = 1 Then
					
					Selection.Next();
					
					ResultString1 = Result.Add();
					ResultString1.Ref = Selection.Ref;
					ResultString1[ColumnName] = SourceRefsTableRow[ColumnName];
					
				Else
					
					Raise StrTemplate(
						NStr("ru = 'Обнаружено дублирование предопределенных элементов %1 в таблице %2.';
							|en = 'Duplicate predefined items %1 are found in table %2.';", Metadata.DefaultLanguage.LanguageCode),
						SourceRefsTableRow.PredefinedDataName,
						MetadataObject.FullName());
					
				EndIf;
				
			EndIf;
			
		Else
			
			If MetadataObject = Undefined Then
				MetadataObject = SourceRefsTableRow[ColumnName].Metadata();
			EndIf;
			
			ReferenceForStandardProcessing = SourceLinksForStandardProcessing.Add();
			FillPropertyValues(ReferenceForStandardProcessing, SourceRefsTableRow);
			
		EndIf;
		
	EndDo;
	
	If SourceLinksForStandardProcessing.Count() > 0 Then
		
		Selection = DataProcessors.ExportImportDataReferenceMappingManager.FetchingLinkMatching(
			MetadataObject, SourceLinksForStandardProcessing, ColumnName);
		
		While Selection.Next() Do
			
			ResultString1 = Result.Add();
			ResultString1.Ref = Selection.Ref;
			ResultString1[ColumnName] = Selection[ColumnName];
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure BeforeImportObject(Container, Object, Artifacts, Cancel) Export
	
	MetadataObject = Object.Metadata(); // MetadataObject
	
	If Not CommonCTL.IsRefDataSupportingPredefinedItems(MetadataObject) Then
		
		Raise StrTemplate(
			NStr("ru = 'Объект метаданных %1 не может быть обработан обработчиком
                  |%2,
                  |т.к. не может содержать предопределенных элементов.';
					|en = 'The %1 metadata object cannot be processed by the handler
					|%2
					|as it cannot contain predefined items.';", Metadata.DefaultLanguage.LanguageCode),
			MetadataObject.FullName(),
			"ExportImportPredefinedData.BeforeImportObject");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function ReferenceMappingToPredefinedElementsIsRequired(TypeName)
	
	If SaaSOperations.IsSeparatedMetadataObject(TypeName, SaaSOperations.MainDataSeparator())
		Or SaaSOperations.IsSeparatedMetadataObject(TypeName, SaaSOperations.AuxiliaryDataSeparator()) Then
		
		Return False;
			
	Else
		
		// For shared objects, mapping references to predefined items is always required.
		Return True;
		
	EndIf;
	
EndFunction

#EndRegion