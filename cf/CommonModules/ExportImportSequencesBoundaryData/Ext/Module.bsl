////////////////////////////////////////////////////////////////////////////////
// Subsystem "Export import data".
// 
// This module's procedures and functions allow the import and export of sequence boundaries.
// 
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called upon registration of arbitrary data export handlers.
// This procedure requires complementing	the handler table with information about arbitrary data export
// handlers to be registered.
//
// Parameters:
//	HandlersTable - ValueTable - Details:
//	 * MetadataObject - MetadataObject - Metadata object during whose data export the handler is called.
//   * Handler - CommonModule - Common module that contains the implementation of a custom data export handler. 
//      The list of export procedures to be implemented in the handler depends on the values in the following value table columns.
//      
//   * Version - String - Version of data import/export handler API supported by the handler.
//   * BeforeUnloadingType - Boolean - a flag specifying whether the handler must be called before exporting all infobase objects
//      associated with this metadata object. If set to True, the common module of the handler must include
//      the exportable procedure BeforeExportType() supporting the following parameters:
//        Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used 
//          for data export. For more information, see the comment to data processor API.
//        Serializer - XDTOSerializer - a serializer initialized with reference annotation support.
//          If you need to export additional data 
//          in an arbitrary export handler, use XDTOSerializer, passed to the BeforeExportType() procedure
//          as the Serializer parameter value, and not obtained using global context property XDTOSerializer.
//        MetadataObject - MetadataObject - a handler is called before the object data is exported.
//        Cancel - Boolean - If the parameter value is set to True 
//          in the BeforeExportType() procedure, the objects corresponding to the current metadata object are not exported.
//   * BeforeExportObject - Boolean - Indicates whether the handler must be called before exporting a specific 
//      infobase object. If True, the common module of the handler must include the 
//      BeforeExportObject() exportable procedure that supports the following parameters:
//        Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used 
//          for data export. For more information, see the comment to the data processor API.
//        ObjectExportManager - DataProcessorObject.ExportImportDataInfobaseDataExportManager -
//          an export manager of the current object. For more information, see the comment to the
//          ExportImportDataInfobaseDataExportManager data processor API. The parameter is passed only
//          if procedures of handlers with version not earlier than 1.0.0.1 specified upon registration are called.
//        Serializer - XDTOSerializer - a serializer initialized with reference annotation support. If 
//          the arbitrary export handler requires exporting additional data, 
//          use XDTOSerializer passed to the BeforeExportObject() procedure as a value of the 
//          Serializer parameter and not obtained using the XDTOSerializer global context property,
//        Object - ManagerOfConstantValue, CatalogObject, DocumentObject, BusinessProcessObject, TaskObject, 
//                 ChartOfAccountsObject, ExchangePlanObject, ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, 
//                 InformationRegisterRecordSet, AccumulationRegisterRecordSet, AccountingRegisterRecordSet,
//                 CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet - an infobase
//                 data object exported after calling the handler.
//          The value passed to the BeforeExportObject() procedure. It can be
//          changed as the Object parameter value in the BeforeExportObject() handler. The changes will be reflected
//          in the object serialization in export files, but not in the infobase.
//        Artifacts - Array Of XDTODataObject - a set of additional information logically associated with the object
//          but not contained in it (object artifacts). Artifacts must be generated inside the BeforeExportObject() handler 
//          and added to the array passed as the Artifacts parameter value. 
//          Each artifact must be an XDTO data object, for whose type an 
//          abstract XDTO type {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact is used as the base type. You can use 
//          XDTO packages that are not included in the ExportImportData subsystem.
//          The artifacts generated in the BeforeExportObject() procedure will be available in
//          the data import handler procedures (see the comment to the OnRegisterDataImportHandlers() procedure).
//        Cancel - Boolean - if you set this parameter value to True in the BeforeExportObject() procedure, 
//           the object that called a handler will not be exported.
//   * AfterUnloadingType - Boolean - a flag specifying whether the handler is called after all infobase
//      objects associated with this metadata object are exported. If set to True, the common module of the handler 
//      must include the exportable procedure BeforeExportType() supporting the following parameters:
//        Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used 
//          for data export. For more information, see the comment to data processor API
//        Serializer - XDTOSerializer initialized with reference annotation support. n case 
//          the arbitrary export handler requires exporting additional data, 
//          use XDTOSerializer passed to the AfterExportType() procedure as value of the
//          Serializer parameter and not obtained using the XDTOSerializer global context property,
//        MetadataObject - MetadataObject - a handler is called after the object data is exported.
//
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	For Each Sequence In Metadata.Sequences Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Sequence;
		NewHandler.Handler = ExportImportSequencesBoundaryData;
		NewHandler.BeforeUnloadingType = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
		
	EndDo;
	
EndProcedure

// Handler of the "BeforeExportType" event.
// 
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager
//	Serializer - XDTOSerializer
//	MetadataObject - MetadataObject
//	Cancel - Boolean
//
Procedure BeforeUnloadingType(Container, Serializer, MetadataObject, Cancel) Export
	
	If CommonCTL.IsSequenceRecordSet(MetadataObject) Then
		
		Filter     = New Array;
		State = Undefined;
		
		While True Do
			
			ArrayOfTables = CloudTechnologyInternalQueries.GetChunkOfDataFromIndependentRecordset(
				MetadataObject, Filter, 10000, False, State, ".Boundaries"); // @query-part-1
			If ArrayOfTables.Count() <> 0 Then
				
				FirstTable = ArrayOfTables.Get(0); // ValueTable
				
				RecordsCount = FirstTable.Count();
				
				FileName = Container.CreateFile(ExportImportDataInternal.SequenceBoundary(), MetadataObject.FullName());
				ExportImportData.WriteObjectToFile(FirstTable, FileName);
				Container.SetNumberOfObjects(FileName, RecordsCount);
				Container.FileRecorded(FileName);
				
				Continue;
				
			EndIf;
			
			Break;
		
		EndDo;
		
	Else
		
		Raise StrTemplate(NStr("ru = 'Объект метаданных %1 не может быть обработан обработчиком %2';
										|en = 'The %2 handler cannot process the %1 metadata object';"),
			MetadataObject.FullName(),
			"ExportImportSequencesBoundaryData.BeforeExportObject");
		
	EndIf;
	
EndProcedure

// Called upon registration of arbitrary data import handlers.
// In this procedure, it is necessary to complete the value table with information about 
// arbitrary data import handlers to register. 
//
// Parameters:
//  HandlersTable - ValueTable - Columns:
//		* MetadataObject - MetadataObject - Metadata object during whose data import the handler is called.
//    	* Handler - CommonModule - Common module that contains the implementation of a custom data import handler.
//       	The list of export procedures to be implemented in the handler depends on the values in the following value table columns.
//       	
//       	
//    	* Version - String - Version of data import/export handler API supported by the handler.
//       	
//    	* BeforeMapRefs - Boolean - Flag specifying whether the handler must be called
//       	before mapping the source infobase references and the current infobase references associated with this metadata
//       	object. If set to True, the common module of the handler must include
//       	the BeforeMapRefs() exportable procedure
//       	supporting the following parameters::
//        		Container - DataProcessorObject.ExportImportDataContainerManager - Container
//          		manager used for data import. For more information, see the comment
//          		to the ExportImportDataContainerManager handler API.
//        		MetadataObject - MetadataObject - Handler is called
//          		before the object references are mapped.
//        		StandardProcessing - Boolean - If set to False in BeforeMapRefs(),
//          		the MapRefs() function of the corresponding
//          		common module will be called instead of the standard
//          		reference mapping (searching the current infobase for objects with the natural key values
//          		identical to the values exported from the source infobase) in the
//          		BeforeMapRefs() procedure whose StandardProcessing parameter value
//          		was set to False.
//          		MapRefs() function parameters:
//            			Container - DataProcessorObject.ExportImportDataContainerManager - Container
//              			manager used for data import. For more information, see the comment
//              			to the ExportImportDataContainerManager handler API.
//            			SourceRefsTable - ValueTable - Contains details on references
//              			exported from the original infobase. Columns:
//                		SourceRef - AnyRef - Source infobase object reference
//                  		to be mapped to the current infobase reference.
//                	The other columns are identical to the object's natural key fields
//                  that were passed to the
//                  DataProcessor.ExportImportInfobaseData.MustMapRefOnImport() function.
//          MapRefs function returns ValueTable. Columns:
//            SourceRef - AnyRef - Object reference exported from the source infobase.
//            Ref - AnyRef - Reference mapped to the original reference in the current infobase.
//        	Cancel - Boolean - If set to True in BeforeMapRefs(), references matching
//          	the current metadata object
//          	are not mapped.
//		* BeforeImportType - Boolean - Flag indicating whether to call the handler before importing all data objects associated with the given metadata object.
//       	If True, the common module requires the export procedure BeforeImportType() with the following parameters
//       	Container - DataProcessorObject.ExportImportDataContainerManager - Container manager used for data import.
//       	For details, see comments to the API of ExportImportDataContainerManager.
//       	MetadataObject - MetadataObject - Object whose data is to be imported.:
//        		Cancel - Boolean - If True, the import will be canceled.
//          		
//          		
//        		
//          		
//        		
//          		
//          		
//		* BeforeImportObject - Boolean - a flag specifying whether the handler must be called before
//       	importing the data object associated with this
//       	metadata object. If set to True, the common module of the handler must
//       	include the exportable procedure BeforeImportObject()
//       	supporting the following parameters:
//        		Container - DataProcessorObject.ExportImportDataContainerManager - a container
//          		manager used for data export. For more information, see the comment
//          		to ExportImportDataContainerManager data processor API.
//        		Object - ConstantValueManager, CatalogObject, DocumentObject,
//          		BusinessProcessObject, TaskObject, ChartOfAccountsObject, ExchangePlanObject,
//          		ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet,
//          		AccumulationRegisterRecordSet, AccountingRegisterRecordSet,
//          		CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet -
//          		an infobase data object imported after the handler is called.
//          		The value passed to the BeforeImportObject() procedure as a Object parameter value
//          		can be modified inside the BeforeImportObject() handler procedure.
//        		Artifacts - Array of XDTODataObject - additional data logically associated
//          		with the data object but not contained in it. Generated in exportable procedures
//          		BeforeExportObject() of data export handlers (see comment to the
//          		OnRegisterDataExportHandlers() procedure. Each artifact must be an XDTO object
//          		with an abstract XDTO type used as a base type
//          		{http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. You can use XDTO packages
//          		that are not included in the ExportImportData subsystem.
//        		Cancel - Boolean - if set this
//          		parameter to True in the BeforeImportObject() procedure, the data object is not imported.
//		* AfterImportObject - Boolean - a flag specifying whether the handler must be called after
//       	importing a data object associated with this metadata
//       	object. If set to True, the common module of the handler
//       	must include the exportable procedure BeforeExportType()
//       	supporting the following parameters:
//        		Container - DataProcessorObject.ExportImportDataContainerManager - a container
//          		manager used for data import. For more information, see the comment
//          		to ExportImportDataContainerManager handler interface.
//        		Object - ConstantValueManager, CatalogObject, DocumentObject,
//          		BusinessProcessObject, TaskObject, ChartOfAccountsObject, ExchangePlanObject,
//          		ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet,
//          		AccumulationRegisterRecordSet, AccountingRegisterRecordSet,
//          		CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet -
//          		an infobase data object exported after calling the handler.
//        		Artifacts - Array of XDTODataObject - additional data logically associated
//          		with the data object but not contained in it. Generated in exportable procedures
//          		BeforeExportObject() of data export handlers (see comment to the
//          		OnRegisterDataExportHandlers() procedure. Each artifact must be an XDTO object
//          		with an abstract XDTO type used as a base type
//          		{http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. You can use XDTO packages
//          		that are not included in the ExportImportData subsystem.
//		* AfterLoadingType - Boolean - a flag specifying whether the handler must be called
//       	after importing all data objects associated with this metadata
//       	object. If set to True, the common module of the handler
//       	must include the exportable procedure AfterImportType()
//       	supporting the following parameters:
//        		Container - DataProcessorObject.ExportImportDataContainerManager - a container
//          		manager used for data import. For more information, see the comment
//          		to ExportImportDataContainerManager data processor API.
//        		MetadataObject - MetadataObject - a handler is called after all its objects
//          		are imported.
//
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
	
	For Each Sequence In Metadata.Sequences Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Sequence;
		NewHandler.Handler = ExportImportSequencesBoundaryData;
		NewHandler.AfterLoadingType = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
		
	EndDo;
	
EndProcedure

// 
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager
//	MetadataObject - MetadataObject
// 
Procedure AfterLoadingType(Container, MetadataObject) Export
	
	If CommonCTL.IsSequenceRecordSet(MetadataObject) Then
		
		SequenceManager = Common.ObjectManagerByFullName(
			MetadataObject.FullName()); // SequenceManagerSequenceName 
		
		BoundaryFiles = Container.GetFilesFromDirectory(
			ExportImportDataInternal.SequenceBoundary(), MetadataObject.FullName());
		
		For Each FileBoundaries In BoundaryFiles Do
			
			BorderTable = Container.ReadObjectFromFile(FileBoundaries);
			
			For Each TableRow In BorderTable Do 
				
				SequenceKey = GetSequenceKey(MetadataObject, TableRow);
				
				PointInTime = New PointInTime(TableRow.Period, TableRow.Recorder);
				SequenceManager.SetBound(PointInTime, SequenceKey);
				
			EndDo;
			
		EndDo;
		
	Else
		
		Raise StrTemplate(NStr("ru = 'Объект метаданных %1 не может быть обработан обработчиком %2';
										|en = 'The %2 handler cannot process the %1 metadata object';"),
			MetadataObject.FullName(),
			"ExportImportSequencesBoundaryData.BeforeExportObject");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Generates a sequence key that consists of its dimensions.
//
// Parameters:
//	MetadataObject - MetadataObjectSequence - Metadata object from the sequence.
//	TableRow - ValueTableRow - Row that stores sequence border records.
//
// Returns:
//	Structure - a sequence key: Key is a dimension name and Value is a dimension value.
//
Function GetSequenceKey(Val MetadataObject, Val TableRow)
	
	SequenceKey = New Structure;
	
	For Each Field In MetadataObject.Dimensions Do
		SequenceKey.Insert(Field.Name, TableRow[Field.Name]);
	EndDo;
	
	Return SequenceKey;
	
EndFunction

#EndRegion