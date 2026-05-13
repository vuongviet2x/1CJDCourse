#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var CurContainer;
Var CurHandlers; // DataProcessorObject.ExportImportDataDataImportHandlersManager
Var CurFlowOfLinkReplacement; // DataProcessorObject.ExportImportDataReferenceReplacementStream
Var ProcessedDuplicatesOfPredefined; // Map
Var FixObjectProcessing;
Var HandlersAvailability; // Structure

#EndRegion

#Region Internal

Procedure Initialize(Container, LoadableTypes, TypesToExclude, Handlers,
	RefsMap = Undefined) Export
	
	CurContainer = Container;
	CurHandlers = Handlers;
	
	FixObjectProcessing = Container.FixState();
	
	If Not CurContainer.ThisIsContinuationOfDownload() And Not CurContainer.IsChildThread() Then
		CommitImportMetadataObjects(LoadableTypes, TypesToExclude);
	EndIf;
	
	CurFlowOfLinkReplacement = DataProcessors.ExportImportDataReferenceReplacementStream.Create();
	CurFlowOfLinkReplacement.Initialize(CurContainer, CurHandlers, RefsMap);
		
	ProcessedDuplicatesOfPredefined = New Map();
	
EndProcedure

Procedure ImportData() Export
	
	PerformLinkReplacement();
	
	If UseMultithreading() Then
		Jobs = StartDataImportThreads();
		ExportImportDataInternal.WaitExportImportDataInThreads(Jobs, CurContainer);
	Else
		RunDataImport();
	EndIf;
	
	If FixObjectProcessing Then
		CurContainer.RecordEndOfProcessingMetadataObjects();
	EndIf;
			
EndProcedure

Procedure ImportDataInThread() Export
	
	While True Do
		
		GetResult1 = InformationRegisters.ExportImportMetadataObjects.GetObjectToProcessing(True);
		
		If Not GetResult1.HasObjectsToProcessing Then
			Break;
		EndIf;
		
		If GetResult1.Object = Undefined Then
			// Wait for the end of data import of the previous priority and receive the object for import again.
			CommonCTL.Pause(5);
			Continue;
		EndIf;
		
		ExecuteImportMetadataObject(GetResult1.Object);
		
	EndDo;
	
EndProcedure

// Returns: 
//  DataProcessorObject.ExportImportDataReferenceReplacementStream - Current reference replace thread.
Function CurFlowOfLinkReplacement() Export
	
	Return CurFlowOfLinkReplacement;
	
EndFunction

//@skip-warning EmptyMethod - Implementation feature.
//
Procedure Close() Export
	
EndProcedure

#EndRegion

#Region Private

Function StartDataImportThreads()
	
	StreamParameters = ExportImportDataInternal.NewExportImportDataThreadsParameters();
	StreamParameters.ThisIsDownload = True;
	StreamParameters.ThreadsCount = CurContainer.ThreadsCount();
	
	StreamParameters.Parameters.Insert(
		"Container",
		CurContainer.GetInitialParametersInThread());
	StreamParameters.Parameters.Insert(
		"LinkReplacementFlow",
		CurFlowOfLinkReplacement.GetInitialParametersInThread());
	
	Return ExportImportDataInternal.StartDataExportImportThreads(StreamParameters);
	
EndFunction

Procedure CommitImportMetadataObjects(LoadableTypes, TypesToExclude)
	
	TypesTable = New ValueTable();
	TypesTable.Columns.Add("Priority", New TypeDescription("Number"));
	TypesTable.Columns.Add("FullName", New TypeDescription("String"));
	TypesTable.Columns.Add("ObjectCount", New TypeDescription("Number"));
	
	MessageTemplate = NStr(
		"ru = 'Загрузка данных объекта метаданных %1 пропущена, т.к. он включен в
		|список объектов метаданных, исключаемых из выгрузки и загрузки данных';
		|en = 'Data import skipped for metadata object %1, as the object is in
		|the list of metadata objects to be excluded from data import and export procedures';",
		Common.DefaultLanguageCode());
	LREvent = NStr(
		"ru = 'Выгрузка загрузка данных. Загрузка объекта пропущена';
		|en = 'Data export and import. Object import skipped';",
		Common.DefaultLanguageCode());
		
	UseMultithreading = UseMultithreading();
	
	For Each MetadataObject In LoadableTypes Do
		
		If TypesToExclude.Find(MetadataObject) <> Undefined Then
			
			WriteLogEvent(
				LREvent,
				EventLogLevel.Information,
				MetadataObject,
				,
				StrTemplate(MessageTemplate, MetadataObject.FullName()));
			
			Continue;
			
		EndIf;
		
		TableRow = TypesTable.Add();
		TableRow.Priority = ExportingMetadataObjectPriority(MetadataObject);
		TableRow.FullName = MetadataObject.FullName();
		
		If UseMultithreading Then
			TableRow.ObjectCount = CurContainer.ObjectsToBeProcessedByMetadataObject(MetadataObject);
		EndIf;
		
	EndDo;
	
	TypesTable.Sort("Priority, ObjectCount DESC, FullName");
	
	CurPriority = Undefined;
	RecordSet = InformationRegisters.ExportImportMetadataObjects.CreateRecordSet();
	
	For Each TableRow In TypesTable Do
		
		If TableRow.Priority <> CurPriority Then
			CurPriority = TableRow.Priority;
			ProcessingProcedure_ = 10000 * TableRow.Priority;
		EndIf;
		
		ProcessingProcedure_ = ProcessingProcedure_ + 1;
		
		SetRecord = RecordSet.Add();
		SetRecord.ProcessingProcedure_ = ProcessingProcedure_;
		SetRecord.MetadataObject = TableRow.FullName;
		
	EndDo;
	
	RecordSet.Write();
	
EndProcedure

Function ExportingMetadataObjectPriority(MetadataObject)
	
	If CommonCTL.IsConstant(MetadataObject) Then
		Priority = 0;
	ElsIf CommonCTL.IsRefData(MetadataObject) Then
		
		If CommonCTL.IsChartOfCharacteristicTypes(MetadataObject) Then
			Priority = 1;
		ElsIf CommonCTL.IsChartOfAccounts(MetadataObject) Then
			Priority = 2;
		ElsIf CommonCTL.IsChartOfCalculationTypes(MetadataObject) Then
			Priority = 3;
		ElsIf CommonCTL.IsCatalog(MetadataObject) Then
			Priority = 4;
		Else
			Priority = 5;
		EndIf;
			
	ElsIf Metadata.CalculationRegisters.Contains(MetadataObject.Parent()) Then // Recalculations.
		Priority = 7;
	ElsIf Metadata.Sequences.Contains(MetadataObject) Then
		Priority = 8;
	ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
		Priority = 6;
	Else
		
		MessageText = StrTemplate(
			NStr("ru = 'Выгрузка объекта метаданных не поддерживается %1';
				|en = 'Import of the %1 metadata object is not supported';"),
			MetadataObject.FullName());
		
		Raise(MessageText);
		
	EndIf;
	
	Return Priority;
	
EndFunction

Procedure PerformLinkReplacement()
	
	LinkReCreationManager = DataProcessors.ExportImportDataReferenceRegenerationManager.Create();
	LinkReCreationManager.Initialize(CurContainer, CurFlowOfLinkReplacement);
	LinkReCreationManager.ReCreateLinks();
	
	RefsMapManager = DataProcessors.ExportImportDataReferenceMappingManager.Create();
	RefsMapManager.Initialize(CurContainer, CurFlowOfLinkReplacement, CurHandlers);
	RefsMapManager.PerformLinkMatching();
	
	ExportImportDataInternal.FixLinkMatching(CurFlowOfLinkReplacement.RefsMap());
	
EndProcedure

Procedure RunDataImport()
	
	ObjectSelection = InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection();
	
	While ObjectSelection.Next() Do
		InformationRegisters.ExportImportMetadataObjects.CommitObjectProcessingStart(ObjectSelection);
		ExecuteImportMetadataObject(ObjectSelection);
	EndDo;
	
EndProcedure

// Import the metadata object.
// 
// Parameters:
//  ObjectSelection - See InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection
Procedure ExecuteImportMetadataObject(ObjectSelection)
	
	If FixObjectProcessing Then
		CurContainer.RecordStartOfMetadataObjectProcessing(ObjectSelection.MetadataObject);
	EndIf;
	
	Cancel = False;
	
	MetadataObject = Metadata.FindByFullName(ObjectSelection.MetadataObject);
	HandlersAvailability = CurHandlers.MetadataObjectHandlersAvailability(MetadataObject);
	
	If HandlersAvailability.BeforeImportType Then
		CurHandlers.BeforeImportType(CurContainer, MetadataObject, Cancel);
	EndIf;
	
	If Cancel And FixObjectProcessing Then
		CurContainer.ObjectsAreProcessed(
			CurContainer.ObjectsToBeProcessedByMetadataObject(MetadataObject));
	ElsIf Not Cancel Then
		UploadDataForInformationBaseObject(MetadataObject);		
	EndIf;
	
	If HandlersAvailability.AfterLoadingType Then
		CurHandlers.AfterLoadingType(CurContainer, MetadataObject);
	EndIf;
	
	If FixObjectProcessing Then
		CurContainer.CommitMetadataObjectProcessingEnd(ObjectSelection.MetadataObject);
	EndIf;
	
	InformationRegisters.ExportImportMetadataObjects.DeleteRecord(ObjectSelection);
	
EndProcedure

// Imports data required for the infobase object.
//
// Parameters:
//	MetadataObject - MetadataObject - Metadata object being imported.
//
Procedure UploadDataForInformationBaseObject(Val MetadataObject)
	
	WriteLogEvent(
		NStr("ru = 'Выгрузка загрузка данных. Загрузка объекта метаданных';
			|en = 'Data export and import. Metadata object import';", Common.DefaultLanguageCode()),
		EventLogLevel.Information,
		MetadataObject,
		,
		StrTemplate(NStr("ru = 'Начало загрузки данных объекта метаданных: %1';
						|en = 'Starting to import metadata object data: %1';", Common.DefaultLanguageCode()),
			MetadataObject.FullName()));
	
	ObjectCount = 0;
	DeferredSets = New Map;
	ParametersForRecordingChanges = Undefined;

	If Common.IsExchangePlan(MetadataObject) Then

		WriteLogEvent(
			NStr("ru = 'Выгрузка загрузка данных. Загрузка объекта метаданных';
				|en = 'Data export and import. Metadata object import';", Common.DefaultLanguageCode()),
			EventLogLevel.Information,
			MetadataObject,
			,
			StrTemplate(NStr("ru = 'Очистка данных объекта метаданных: %1';
							|en = 'Clear metadata object data: %1';", Common.DefaultLanguageCode()),
				MetadataObject.FullName()));
		
		SaaSOperations.ClearMetadataObjectData(MetadataObject.FullName(), MetadataObject);
		
	EndIf;
		
	For Each FileDetails In CurContainer.GetFileDescriptionsFromFolder(ExportImportDataInternal.InfobaseData(), MetadataObject.FullName()) Do
		
		CurContainer.UnzipFile(FileDetails);
		
		CurFlowOfLinkReplacement.ReplaceLinksInFile(FileDetails);
		
		ReaderStream = DataProcessors.ExportImportDataInfobaseDataReadingStream.Create();
		ReaderStream.OpenFile(FileDetails.FullName);
				
		While ReaderStream.ReadInformationDatabaseDataObject() Do
			
			Object = ReaderStream.CurrentObject();
			Artifacts = ReaderStream.CurObjectArtifacts();
			
			If ReaderStream.TypeOfCurrentObject() = ExportImportDataInternal.InfobaseData() Then
			
				WriteObjectToInformationBase(Object, Artifacts, DeferredSets, MetadataObject);
				
			ElsIf ReaderStream.TypeOfCurrentObject() = ExportImportDataInternal.InfobaseDataChanges() Then
				
				If ParametersForRecordingChanges = Undefined Then
					
					ParametersForRecordingChanges = ParametersForRecordingChanges(MetadataObject);
					
				EndIf;
				
				If ParametersForRecordingChanges.IsConstant Then
					
					RecordConstantChange(MetadataObject, Object, Artifacts);
					
				ElsIf ParametersForRecordingChanges.IsRefData Then
					
					RecordLinkChange(MetadataObject, Object, Artifacts);
					
				ElsIf ParametersForRecordingChanges.IsRecordSet Then
					
					RecordRecordsetChange(MetadataObject, ParametersForRecordingChanges.FilterFields, Object, Artifacts);
					
				EndIf;
				
			EndIf;
			
			ObjectCount = ObjectCount + 1;
			
		EndDo;
		
		ReaderStream.Close();
		DeleteFiles(FileDetails.FullName);
		
	EndDo;
	
	For Each KeyAndValue In DeferredSets Do
		
		Object = KeyAndValue.Value.Object; // CatalogObject, DocumentObject
		ObjectArtifacts = KeyAndValue.Value.ObjectArtifacts;
		ObjectCount = ObjectCount + 1;
		
		Try
			Object.Write();
		Except
		
			Comment = StrTemplate(
				NStr("ru = 'Объекта метаданных %1 с представлением ""%2"" не загружен по причине: %3';
					|en = 'Metadata object %1 with presentation ""%2"" is not imported. Reason: %3';", Common.DefaultLanguageCode()),
				MetadataObject.FullName(),
				String(Object),
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			// @skip-check module-nstr-camelcase - Check error.
			WriteLogEvent(
				NStr("ru = 'Выгрузка загрузка данных. Загрузка объекта метаданных.Ошибка';
					|en = 'Data export and import. Metadata object import.Error';", Common.DefaultLanguageCode()),
				EventLogLevel.Error,
				MetadataObject,
				,
				Comment);
			
			Raise Comment;
				
		EndTry;
			
		If HandlersAvailability.AfterImportObject Then
			CurHandlers.AfterImportObject(CurContainer, Object, ObjectArtifacts);
		EndIf;
		
	EndDo;
	
	Comment = StrTemplate(
		NStr("ru = 'Окончание загрузки данных объекта метаданных: %1
					|Загружено объектов: %2';
					|en = 'Finish importing metadata object data: %1
					|Objects imported: %2';", Common.DefaultLanguageCode()),
		MetadataObject.FullName(), 
		ObjectCount);
	WriteLogEvent(
		NStr("ru = 'Выгрузка загрузка данных. Загрузка объекта метаданных';
			|en = 'Data export and import. Metadata object import';", Common.DefaultLanguageCode()),
		EventLogLevel.Information,
		MetadataObject,
		,
		Comment);
	
EndProcedure

Procedure WriteObjectToInformationBase(Object, ObjectArtifacts, DeferredSets, MetadataObject)
	
	SaveObjectToInformationDatabaseInternal(
		Object,
		ObjectArtifacts,
		DeferredSets,
		MetadataObject);
	
	If FixObjectProcessing Then
		CurContainer.ObjectProcessed();	
	EndIf;
		
EndProcedure

Procedure SaveObjectToInformationDatabaseInternal(Object, ObjectArtifacts, DeferredSets, MetadataObject)
	
	Cancel = False;
	
	If HandlersAvailability.BeforeImportObject Then
		CurHandlers.BeforeImportObject(CurContainer, Object, ObjectArtifacts, Cancel);
	EndIf;
	
	If Not Cancel Then
		
		If CommonCTL.IsConstant(MetadataObject) Then
			
			If Not ValueIsFilled(Object.Value) Then
				// Do not rewrite empty values as the constants were pre-cleared.
				// 
				Return;
			EndIf;
			
		EndIf;
		
		Object.DataExchange.Load = True;
		
		If TypeOf(Object) <> Type("ObjectDeletion") Then
			Object.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		EndIf;
		
		DuplicatesOfPredefinedItems = FindDuplicatesOfPredefined(MetadataObject, Object);
		
		Try
			
			If ValueIsFilled(DuplicatesOfPredefinedItems) Then
			
				BeginTransaction();
				
				Try
					
					For Each MapItem In DuplicatesOfPredefinedItems Do
						
						DuplicateOfPredefined = MapItem.Key;
						LinksParent = MapItem.Value;
						NewParent = GetLinkToObject(Object);
						
						For Each LinkToDuplicate In LinksParent Do
							SubordinateObject = LinkToDuplicate.GetObject();
							SubordinateObject.Parent = NewParent;
							SubordinateObject.DataExchange.Load = True;
							SubordinateObject.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
							SubordinateObject.Write();
						EndDo;
						
						DuplicateOfPredefinedObject = DuplicateOfPredefined.GetObject();
						DuplicateOfPredefinedObject.DataExchange.Load = True;
						DuplicateOfPredefinedObject.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
						DuplicateOfPredefinedObject.Delete();
						
					EndDo;
					
					Object.Write();
					
					CommitTransaction();
						
				Except
					RollbackTransaction();
					Raise;
				EndTry;
				
			ElsIf CommonCTL.IsInformationRegister(MetadataObject)
				And MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate 
				And MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.RecorderPosition Then
				
				Recorder = Object.Filter.Recorder.Value;
				Try
					Object.Write();
					DeferredSets.Delete(Recorder);
				Except
					DeferredSets.Insert(Recorder, New Structure("Object, ObjectArtifacts", Object, ObjectArtifacts));
					Return;
				EndTry;
			
			Else 
				Object.Write();
			EndIf;
			
		Except
			
			LanguageCode = Common.DefaultLanguageCode();
			Comment = StrTemplate(
				NStr("ru = 'Объекта метаданных %1 с представлением ""%2"" не загружен по причине: %3';
					|en = 'Metadata object %1 with presentation ""%2"" is not imported. Reason: %3';", LanguageCode),
				MetadataObject.FullName(),
				String(Object),
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			// @skip-check module-nstr-camelcase - Check error.
			WriteLogEvent(
				NStr("ru = 'Выгрузка загрузка данных. Загрузка объекта метаданных.Ошибка';
					|en = 'Data export and import. Metadata object import.Error';", LanguageCode),
				EventLogLevel.Error,
				MetadataObject,
				,
				Comment);
					
			Raise Comment;
			
		EndTry;
		
	EndIf;
	
	If HandlersAvailability.AfterImportObject Then
		CurHandlers.AfterImportObject(CurContainer, Object, ObjectArtifacts);
	EndIf;
		
EndProcedure

Function ParametersForRecordingChanges(MetadataObject)
	
	Result = New Structure;
	Result.Insert("IsConstant", False);
	Result.Insert("IsRefData", False);
	Result.Insert("IsRecordSet", False);
	Result.Insert("FilterFields", New Array);
	
	If CommonCTL.IsConstant(MetadataObject) Then
		
		Result.IsConstant = True;
		
	ElsIf CommonCTL.IsRefData(MetadataObject) Then
		
		Result.IsRefData = True;
		
	ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
		
		Result.IsRecordSet = True;
		
		If Metadata.InformationRegisters.Contains(MetadataObject)
			And MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
			
			If MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical
				And MetadataObject.MainFilterOnPeriod Then
				
				Result.FilterFields.Add("Period");
				
			EndIf;
			
			For Each Dimension In MetadataObject.Dimensions Do
				
				If Dimension.MainFilter Then
					
					Result.FilterFields.Add(Dimension.Name);
					
				EndIf;
				
			EndDo;
			
		ElsIf Metadata.CalculationRegisters.Contains(MetadataObject.Parent()) Then
			
			Result.FilterFields.Add("RecalculationObject");
			
		Else
			
			Result.FilterFields.Add("Recorder");
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure RecordConstantChange(MetadataObject, Changes, Artifacts)
	
	ExchangePlans.RecordChanges(Changes.Node, MetadataObject);
	
	If ValueIsFilled(Changes.MessageNo) Then
		
		ExchangePlans.SelectChanges(Changes.Node, Changes.MessageNo, MetadataObject);
		
	EndIf;
	
EndProcedure

Procedure RecordLinkChange(MetadataObject, Changes, Artifacts)
	
	ExchangePlans.RecordChanges(Changes.Node, Changes.Ref);
	
	If ValueIsFilled(Changes.MessageNo) Then
		
		ExchangePlans.SelectChanges(Changes.Node, Changes.MessageNo, Changes.Ref);
		
	EndIf;
	
EndProcedure

Procedure RecordRecordsetChange(MetadataObject, FilterFields, Changes, Artifacts)
	
	ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
	RecordSet = ObjectManager.CreateRecordSet();
	
	For Each FilterField In FilterFields Do
		
		FilterElement = RecordSet.Filter[FilterField]; // FilterItem
		FilterElement.Set(Changes[FilterField]);
		
	EndDo;
	
	ExchangePlans.RecordChanges(Changes.Node, RecordSet);
	
	If ValueIsFilled(Changes.MessageNo) Then
		
		ExchangePlans.SelectChanges(Changes.Node, Changes.MessageNo, RecordSet);
		
	EndIf;
	
EndProcedure

Function UseMultithreading()
	
	If CurContainer.IsChildThread() Then
		Return False;
	EndIf;
	
	Return ExportImportDataInternal.UseMultithreading(CurContainer.ImportParameters());
	
EndFunction

Function FindDuplicatesOfPredefined(MetadataObject, Object)
	
	If TypeOf(Object) = Type("ObjectDeletion")
		Or Not CommonCTL.IsRefDataSupportingPredefinedItems(MetadataObject)
		Or Not Object.Predefined Then
		
		Return Undefined;
		
	EndIf;
	
	FullMetadataObjectName = MetadataObject.FullName();
	PredefinedItemName = Object.PredefinedDataName;
	FullPredefinedItemName = StrTemplate("%1.%2", FullMetadataObjectName, PredefinedItemName);
	
	If ProcessedDuplicatesOfPredefined.Get(FullPredefinedItemName) <> Undefined Then
		Return Undefined;
	EndIf;
	
	ProcessedDuplicatesOfPredefined.Insert(FullPredefinedItemName, True);
	Hierarchical = Not CommonCTL.IsChartOfCalculationTypes(MetadataObject) 
		And (CommonCTL.IsChartOfAccounts(MetadataObject) Or MetadataObject.Hierarchical);
	
	If Hierarchical Then
		
		QueryText = StrReplace(
			"SELECT
			|	ObjectTable.Ref AS Ref,
			|	ISNULL(TableParent.Ref, UNDEFINED) AS LinkParent
			|FROM
			|	&Table AS ObjectTable
			|		LEFT JOIN &Table AS TableParent
			|		ON ObjectTable.Ref = TableParent.Parent
			|WHERE
			|	ObjectTable.PredefinedDataName = &PredefinedItemName
			|	AND ObjectTable.Ref <> &Ref
			|TOTALS BY
			|	Ref",
			"&Table",
		 	FullMetadataObjectName);
		
	Else
		
		QueryText = StrReplace(
			"SELECT
			|	ObjectTable.Ref AS Ref,
			|	UNDEFINED AS LinkParent
			|FROM
			|	&Table AS ObjectTable
			|WHERE 
			|	ObjectTable.PredefinedDataName = &PredefinedItemName
			|	AND ObjectTable.Ref <> &Ref",
			"&Table",
		 	FullMetadataObjectName);
		 
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("PredefinedItemName", PredefinedItemName);
	Query.SetParameter("Ref", GetLinkToObject(Object));
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	DuplicatesOfPredefinedItems = New Map();
	DuplicatesSelection = Result.Select(QueryResultIteration.ByGroups);
	
	While DuplicatesSelection.Next() Do
		
		LinksParent = New Array();
		DuplicatesOfPredefinedItems.Insert(DuplicatesSelection.Ref, LinksParent);
		
		ParentSelection = DuplicatesSelection.Select();
		
		While ParentSelection.Next() Do
			
			If ValueIsFilled(ParentSelection.LinkParent) Then
				LinksParent.Add(ParentSelection.LinkParent);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return DuplicatesOfPredefinedItems;
	
EndFunction

Function GetLinkToObject(Object)
	
	Return ?(Object.IsNew(), Object.GetNewObjectRef(), Object.Ref);
	
EndFunction

#EndRegion

#EndIf
