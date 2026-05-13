#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Exports the infobase data.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container
//		manager used for data export. For more information, see the comment
//		to ExportImportDataContainerManager handler interface.
//	Handlers - DataProcessorObject.ExportImportDataDataExportHandlersManager - a data export handler 
//		manager. 
//	Serializer - XDTOSerializer - an XDTO serializer with type annotation. 
//
Procedure UploadDatabaseData(Container, Handlers, Serializer) Export
	
	ExportProcessParameters = NewInfoBaseDataExportProcessParameters(
		Container, Handlers, Serializer);
	NodesBC = GetBackupNodes(Container, ExportProcessParameters.TypesToExclude);
	
	CommitExportMetadataObjects(ExportProcessParameters);
	
	If ExportProcessParameters.UseMultithreading Then
		
		Jobs = StartDataExportThread(ExportProcessParameters, NodesBC);
		
		ExportImportDataInternal.WaitExportImportDataInThreads(
			Jobs, ExportProcessParameters.Container);
		
	Else
		
		ExportMainData(ExportProcessParameters, NodesBC.MainNode);
		
	EndIf;
	
	If NodesBC.AdditionalNode = Undefined Then
		
		// Export in standalone mode.
		CompleteUpload(ExportProcessParameters, NodesBC.MainNode);
				
	Else
		 
		// Import objects that were modified while the import was running.
		// If many objects were modified, import them outside a transaction.
		ExportAccumulatedMainData(ExportProcessParameters, NodesBC.AdditionalNode);
		
		UnloadingInTransactionIsCompleted = False;
		
		For AttemptNumber = 1 To 3 Do
			
			UnloadingInTransactionIsCompleted = CompleteUnloadingInTransaction(
				ExportProcessParameters, 
				NodesBC.AdditionalNode);
			
			If UnloadingInTransactionIsCompleted Then
				Break;
			EndIf;
			
			CommonCTL.Pause(60);
			
		EndDo;
		
		If Not UnloadingInTransactionIsCompleted Then
			Raise NStr("ru = 'Не удалось заблокировать область, резервная копия не сделана.';
									|en = 'Cannot lock the area. Not backed up.';");
		EndIf;
		
	EndIf;
	
	UploadGeneralData(ExportProcessParameters);
	
	ExportProcessParameters.StreamRecordingOfReCreatedLinks.Close();
	ExportProcessParameters.RecordFlowOfMappedLinks.Close();
	
	If ExportProcessParameters.Container.FixState() Then
		Container.RecordEndOfProcessingMetadataObjects();	
	EndIf;
	
EndProcedure

// Export the infobase data in the stream.
// 
// Parameters:
//  StreamParameters - Structure - See the Parameters property in the StartDataExportThread function.
// 
Procedure ExportInfoBaseDataInThread(StreamParameters) Export
	
	Container = DataProcessors.ExportImportDataContainerManager.Create();
	Container.InitializeUploadInThread(StreamParameters.Container);
	
	Handlers = DataProcessors.ExportImportDataDataExportHandlersManager.Create();
	Handlers.Initialize(Container);
	
	Serializer = ExportImportDataInternal.XdtoSerializerWithTypeAnnotation();
	
	ExportProcessParameters = NewInfoBaseDataExportProcessParameters(
		Container, Handlers, Serializer, StreamParameters.RecordFlowOfMappedLinks);
	
	ExportMainDataInThread(ExportProcessParameters, StreamParameters.MainNode);
	
	ExportProcessParameters.StreamRecordingOfReCreatedLinks.Close();
	ExportProcessParameters.RecordFlowOfMappedLinks.Close();
	
	MessageData = New Structure();
	MessageData.Insert(
		"Content",
		Common.ValueTableToArray(ExportProcessParameters.Container.Content()));
	MessageData.Insert(
		"FilesUsed",
		New FixedArray(ExportProcessParameters.Container.FilesUsed()));
	MessageData.Insert(
		"Warnings",
		New FixedArray(ExportProcessParameters.Container.Warnings()));
	MessageData.Insert(
		"DuplicatesOfPredefinedItems",
		Common.ValueToXMLString(ExportProcessParameters.Container.DuplicatesOfPredefinedItems()));
	
	ExportImportDataInternal.SendMessageToParentThread(
		ExportProcessParameters.Container.ProcessID(),
		"ExportEnd",
		MessageData);
	
EndProcedure

// Returns the differential copy availability flag.
// 
// Returns:
// 	Boolean - Details.
Function UnloadingDifferentialCopyIsPossible() Export
	
	Node = ExchangePlans.ApplicationsMigration.FindByCode(MainNodeCode());
	
	Return ValueIsFilled(Node);
	
EndFunction

#EndRegion

#Region Private

// New parameters of the infobase data export process.
// 
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - Container.
//  Handlers - DataProcessorObject.ExportImportDataDataExportHandlersManager - Handlers.
//  Serializer - XDTOSerializer - XDTO serializer with type annotation.
//  LinkMappingInitializationParameters - See DataProcessorObject.ExportImportDataMappedReferencesWritingStream.GetInitialParametersInThread
// 
// Returns:
//  Structure - New parameters of the infobase data export process.:
// * Container - DataProcessorObject.ExportImportDataContainerManager 
// * Handlers - DataProcessorObject.ExportImportDataDataExportHandlersManager 
// * Serializer - XDTOSerializer 
// * StreamRecordingOfReCreatedLinks - DataProcessorObject.ExportImportDataRegeneratedReferencesWritingStream
// * RecordFlowOfMappedLinks - DataProcessorObject.ExportImportDataMappedReferencesWritingStream
// * TypesToExport - Array of MetadataObject
// * TypesToExclude - Array of MetadataObject
// * UseMultithreading - Boolean
Function NewInfoBaseDataExportProcessParameters(
	Container, Handlers, Serializer, LinkMappingInitializationParameters = Undefined)
	
	StreamRecordingOfReCreatedLinks = DataProcessors.ExportImportDataRegeneratedReferencesWritingStream.Create();
	StreamRecordingOfReCreatedLinks.Initialize(Container, Serializer);
	
	RecordFlowOfMappedLinks = DataProcessors.ExportImportDataMappedReferencesWritingStream.Create();
	RecordFlowOfMappedLinks.Initialize(Container, Serializer, LinkMappingInitializationParameters);
	
	ExportProcessParameters = New Structure();
	ExportProcessParameters.Insert("Container", Container);
	ExportProcessParameters.Insert("Handlers", Handlers);
	ExportProcessParameters.Insert("Serializer", Serializer);
	ExportProcessParameters.Insert("StreamRecordingOfReCreatedLinks", StreamRecordingOfReCreatedLinks);
	ExportProcessParameters.Insert("RecordFlowOfMappedLinks", RecordFlowOfMappedLinks);
	
	If Container.IsChildThread() Then
		
		ExportProcessParameters.Insert("TypesToExport", New Array());
		ExportProcessParameters.Insert("TypesToExclude", New Array());
		ExportProcessParameters.Insert("UseMultithreading", False);
		
	Else
		
		ExportingParameters = Container.ExportingParameters();
		TypesToExclude = ExportImportDataInternalEvents.GetTypesExcludedFromUploadUpload();
		UseMultithreading = ExportImportDataInternal.UseMultithreading(ExportingParameters);
		
		ExportProcessParameters.Insert("TypesToExport", ExportingParameters.TypesToExport);
		ExportProcessParameters.Insert("TypesToExclude", TypesToExclude);
		ExportProcessParameters.Insert("UseMultithreading", UseMultithreading);
		
	EndIf;
	
	Return ExportProcessParameters;
	
EndFunction

// Export the main data.
// 
// Parameters:
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
//  Node - ExchangePlanRef.ApplicationsMigration, Undefined - Exchange plan node.
Procedure ExportMainData(ExportProcessParameters, Node)
	
	ObjectSelection = InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection();
	
	While ObjectSelection.Next() Do
		InformationRegisters.ExportImportMetadataObjects.CommitObjectProcessingStart(ObjectSelection);
		UploadMetadataObjectData(ObjectSelection, ExportProcessParameters, Node);
	EndDo;
	
EndProcedure

// Export the main data in the stream.
// 
// Parameters:
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
//  Node - ExchangePlanRef.ApplicationsMigration, Undefined - Exchange plan node.
Procedure ExportMainDataInThread(ExportProcessParameters, Node)
	
	While True Do
		
		GetResult1 = InformationRegisters.ExportImportMetadataObjects.GetObjectToProcessing();
		
		If Not GetResult1.HasObjectsToProcessing Then
			Break;
		EndIf;
		
		If GetResult1.Object <> Undefined Then
			UploadMetadataObjectData(GetResult1.Object, ExportProcessParameters, Node);
		EndIf;
		
	EndDo;
	
EndProcedure

// Export metadata object data.
// 
// Parameters:
//  ObjectSelection - QueryResultSelection - Object selection.
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
//  Node - ExchangePlanRef.ApplicationsMigration, Undefined - Exchange plan node.
Procedure UploadMetadataObjectData(ObjectSelection, ExportProcessParameters, Node)
	
	MetadataObject = Metadata.FindByFullName(ObjectSelection.MetadataObject);
	UploadMetadataObject(ExportProcessParameters, MetadataObject, Node);
	
	InformationRegisters.ExportImportMetadataObjects.DeleteRecord(ObjectSelection);
	
EndProcedure

// Export accumulated main data.
// 
// Parameters:
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
//  AdditionalNode - ExchangePlanRef.ApplicationsMigration - Exchange plan node.
//  IsExportEnd - Boolean - Indicates whether export is completed.
Procedure ExportAccumulatedMainData(ExportProcessParameters, AdditionalNode, IsExportEnd = False)
	
	ModifiedObjectsData = ApplicationsMigration.GetModifiedObjectsData(AdditionalNode);
	MinimumChangesCount = ?(IsExportEnd, 0, 99);
	
	If ModifiedObjectsData.ObjectCount <= MinimumChangesCount Then
		Return;
	EndIf;
	
	CheckAndRecordExportedObjectsTable(
		ModifiedObjectsData.ObjectsTable,
		ExportProcessParameters.TypesToExclude);
	
	If ExportProcessParameters.Container.FixState() Then
		ExportProcessParameters.Container.AddTotalNumberOfObjects(
			ModifiedObjectsData.ObjectsTable.Total("ObjectCount"));
	EndIf;
	
	ExportMainData(ExportProcessParameters, AdditionalNode);
	
	If Not IsExportEnd Then
		ExchangePlans.DeleteChangeRecords(AdditionalNode, 1);
	EndIf;
	
EndProcedure

// Start data import streams.
// 
// Parameters:
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
//  NodesBC - See GetBackupNodes
// 
// Returns:
//  Array of BackgroundJob - Start data export streams.
Function StartDataExportThread(ExportProcessParameters, NodesBC)
	
	StreamParameters = ExportImportDataInternal.NewExportImportDataThreadsParameters();
	StreamParameters.IsExport = True;
	StreamParameters.ThreadsCount = ExportProcessParameters.Container.ThreadsCount();
	
	StreamParameters.Parameters.Insert(
		"Container",
		ExportProcessParameters.Container.GetInitialParametersInThread());
	StreamParameters.Parameters.Insert(
		"RecordFlowOfMappedLinks",
		ExportProcessParameters.RecordFlowOfMappedLinks.GetInitialParametersInThread());
	StreamParameters.Parameters.Insert("MainNode", NodesBC.MainNode);
	
	Return ExportImportDataInternal.StartDataExportImportThreads(StreamParameters);
	
EndFunction

// Save metadata objects to export.
// 
// Parameters:
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
Procedure CommitExportMetadataObjects(ExportProcessParameters)
	
	ObjectsTable = New ValueTable();
	ObjectsTable.Columns.Add("FullName", New TypeDescription("String"));
	ObjectsTable.Columns.Add("ObjectCount", New TypeDescription("Number"));
	
	For Each MetadataObject In ExportProcessParameters.TypesToExport Do
		
		If MetadataObjectExcludedFromExport(MetadataObject, ExportProcessParameters.TypesToExclude) Then
			Continue;
		EndIf;
		
		TableRow = ObjectsTable.Add();
		TableRow.FullName = MetadataObject.FullName();
		
		If ExportProcessParameters.UseMultithreading Then
			TableRow.ObjectCount
				= ExportProcessParameters.Container.ObjectsToBeProcessedByMetadataObject(MetadataObject);
		EndIf;
		
	EndDo;
	
	RecordExportObjectsTable(ObjectsTable);
		
EndProcedure

// Check and save the table of objects to export.
// 
// Parameters:
//  ObjectsTable - ValueTable - Object table.:
// * FullName - String - Full name of the metadata object.
// * ObjectCount - Number - Number of objects.
//  TypesToExclude - FixedArray of MetadataObject - Types to exclude.
Procedure CheckAndRecordExportedObjectsTable(ObjectsTable, TypesToExclude)
	
	RowIndex = ObjectsTable.Count() - 1;
	
	While RowIndex >= 0 Do
		
		TableRow = ObjectsTable[RowIndex];
		MetadataObject = Metadata.FindByFullName(TableRow.FullName);
		
		If MetadataObjectExcludedFromExport(MetadataObject, TypesToExclude) Then
			ObjectsTable.Delete(RowIndex);
		EndIf;
		
		RowIndex = RowIndex - 1;
		
	EndDo;
	
	RecordExportObjectsTable(ObjectsTable);
	
EndProcedure

// Save a table of objects to export.
// 
// Parameters:
//  ObjectsTable - ValueTable - Object table.:
// * FullName - String - Full name of the metadata object.
// * ObjectCount - Number - Number of objects.
Procedure RecordExportObjectsTable(ObjectsTable)
	
	If Not ValueIsFilled(ObjectsTable) Then
		Return;
	EndIf;
	
	ObjectsTable.Sort("ObjectCount DESC, FullName");
	
	ProcessingProcedure_ = 0;
	RecordSet = InformationRegisters.ExportImportMetadataObjects.CreateRecordSet();
	
	For Each TableRow In ObjectsTable Do
		
		ProcessingProcedure_ = ProcessingProcedure_ + 1;
		
		SetRecord = RecordSet.Add();
		SetRecord.ProcessingProcedure_ = ProcessingProcedure_;
		SetRecord.MetadataObject = TableRow.FullName;
		
	EndDo;
	
	RecordSet.Write();
	
EndProcedure

// Get backup nodes.
// 
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - Container.
//  TypesToExclude - FixedArray of MetadataObject - Types to exclude.
// 
// Returns:
//  Structure - Get backup nodes.:
// * MainNode - ExchangePlanRef.ApplicationsMigration, Undefined - Main node.
// * AdditionalNode - ExchangePlanRef.ApplicationsMigration, Undefined - Additional node.
Function GetBackupNodes(Container, TypesToExclude)
	
	// Export via an exchange plan:
	//   - With exclusive mode enabled, made in a single step.
	//   - With exclusive mode disabled: first, export all data, then export data from the additional node.
	
	If Container.ThisIsBackup() And Not Container.UnloadDifferentialCopy() Then
		
		Node = ExchangePlans.ApplicationsMigration.FindByCode(MainNodeCode());
		UseDifferentialBackup
			= Constants.UseDifferentialBackup.Get();
		
		If ValueIsFilled(Node) Then
			
			BeginTransaction();
			
			Try
				
				BlockAllUnloadedObjects(TypesToExclude, Container);
				
				ExchangePlans.DeleteChangeRecords(Node);
				
				If Not UseDifferentialBackup Then
					
					ObjectNode = Node.GetObject();
					ObjectNode.DataExchange.Load = True;
					ObjectNode.Delete();
					
				EndIf;
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				Raise;
				
			EndTry;
			
		ElsIf UseDifferentialBackup Then
			 
			ObjectNode = ExchangePlans.ApplicationsMigration.CreateNode();
			ObjectNode.Code = MainNodeCode();
			ObjectNode.Description = NStr(
				"ru = 'Резервное копирование (основной узел)';
				|en = 'Backup (master node)';",
				Common.DefaultLanguageCode());
			ObjectNode.Write();
			
		EndIf;
		
	EndIf;
	
	AdditionalNode = Undefined;
	
	If Not ExclusiveMode() Then
		
		// Before export starts, create an additional node to register objects that will be modified during the export. 
		// 
		Block = New DataLock();
		LockItem = Block.Add("ExchangePlan.ApplicationsMigration");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("Code", AdditionalNodeCode());
		
		BeginTransaction();
		
		Try
			
			Block.Lock();
			
			AdditionalNode = ExchangePlans.ApplicationsMigration.FindByCode(AdditionalNodeCode());
			
			If ValueIsFilled(AdditionalNode) Then
				
				// Meaning there's a node created on the last time.			
				BlockAllUnloadedObjects(TypesToExclude, Container);
				ExchangePlans.DeleteChangeRecords(AdditionalNode);
				
			Else
				
				ObjectNode = ExchangePlans.ApplicationsMigration.CreateNode();
				ObjectNode.Code = AdditionalNodeCode();
				ObjectNode.Description = NStr(
					"ru = 'Резервное копирование (дополнительный узел)';
					|en = 'Backup (additional node)';",
					Common.DefaultLanguageCode());
				ObjectNode.Write();
				
				AdditionalNode = ObjectNode.Ref;
				
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			Raise;
			
		EndTry;
		
		Try
			LockDataForEdit(AdditionalNode);
		Except
			Raise NStr("ru = 'Не удалось запустить выгрузку данных, выгрузка уже выполняется другим заданием.
				|Дождитесь его завершения или принудительно завершите сеанс.';
				|en = 'Cannot start data export because another export job is currently in progress.
				|Please wait for the current job to complete or forcefully close the session.';")
				+ Chars.LF + CloudTechnology.DetailedErrorText(ErrorInfo());
		EndTry;
		
	EndIf;
	
	MainNode = Undefined; // Node is not used for a full backup.
	
	If Container.UnloadDifferentialCopy() Then
		MainNode = ExchangePlans.ApplicationsMigration.FindByCode(MainNodeCode());
	EndIf;
	
	NodesBC = New Structure();
	NodesBC.Insert("MainNode", MainNode);
	NodesBC.Insert("AdditionalNode", AdditionalNode);
	
	Return NodesBC;

EndFunction

// Metadata object is excluded from export.
// 
// Parameters:
//  MetadataObject - MetadataObject - Metadata object.
//  TypesToExclude - Array of MetadataObject - Types to exclude.
// 
// Returns:
//  Boolean - Metadata object is excluded from export.
Function MetadataObjectExcludedFromExport(MetadataObject, TypesToExclude)
	
	If MetadataObject = Metadata.Catalogs.Users
		Or Metadata.ExchangePlans.Contains(MetadataObject) Then
		Return True;
	EndIf;
	
	If ThisIsExcludedType(TypesToExclude, MetadataObject) Then
		Return True;
	EndIf;
	
	// If an object that is not included in the "ApplicationsMigration" plan was added by an extension,
	// then export its data after setting the exclusive mode at the export finalization.
	If Not ExclusiveMode()
		And MetadataObject.ConfigurationExtension() <> Undefined
		And Not Metadata.ExchangePlans.ApplicationsMigration.Content.Contains(MetadataObject) Then
		Return True;	
	EndIf;
	
	Return False;
	
EndFunction

// Export shared data.
// 
// Parameters:
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
Procedure UploadGeneralData(ExportProcessParameters)
	
	TypesToExport = ExportProcessParameters.Container.ExportingParameters().UnloadedTypesOfSharedData;
	
	For Each MetadataObject In TypesToExport Do
		
		If ThisIsExcludedType(ExportProcessParameters.TypesToExclude, MetadataObject) Then
			Continue;
		EndIf;
		
		UploadMetadataObject(ExportProcessParameters, MetadataObject);
		
	EndDo;
	
EndProcedure

// Export accumulated main data.
// 
// Parameters:
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
//  AdditionalNode - ExchangePlanRef.ApplicationsMigration, Undefined - Exchange plan node.
Function CompleteUnloadingInTransaction(ExportProcessParameters, AdditionalNode)
	
	NotifyUsersAboutExportEnd();
	
	BeginTransaction();
	
	Try
		
		Try
			
			BlockAllUnloadedObjects(
				ExportProcessParameters.TypesToExclude,
				ExportProcessParameters.Container);
			
		Except
			
			RollbackTransaction();
			Return False;
			
		EndTry;
		
		ExportAccumulatedMainData(ExportProcessParameters, AdditionalNode, True);
		CompleteUpload(ExportProcessParameters, AdditionalNode);
			
		AdditionalNode.GetObject().Delete();
					
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
	Return True;
	
EndFunction

Procedure NotifyUsersAboutExportEnd()
	
	If Not Common.DataSeparationEnabled()
		Or Metadata.CommonModules.Find("UsersNotificationCTL") = Undefined Then
		Return;
	EndIf;
	
	BackgroundJob = GetCurrentInfoBaseSession().GetBackgroundJob();
	
	If BackgroundJob = Undefined Then
		Return;
	EndIf;
	
	CurrentInfobaseUser = InfoBaseUsers.CurrentUser();
	CurrentUserID = Undefined;
	 
	If CurrentInfobaseUser <> Undefined Then
		CurrentUserID = CurrentInfobaseUser.UUID;
	EndIf;
	
	SessionSeparatorValue = SaaSOperations.SessionSeparatorValue();
	InteractiveApplicationNames = CommonCTL.InteractiveApplicationNames();
	
	UserNotification = New Structure();
	UserNotification.Insert("NotificationKind", "WarningAboutBlockingWork");
	UserNotification.Insert("JobID", String(BackgroundJob.UUID));
	
	Notifications = New Array();
	
	For Each Session In GetInfoBaseSessions() Do
		
		SessionUser = Session.User;
		
		If SessionUser = Undefined 
			Or SessionUser.UUID = CurrentUserID Then
			Continue;
		EndIf;
		
		If InteractiveApplicationNames.Find(Session.ApplicationName) = Undefined Then
			Continue;
		EndIf;
			
		Notification = New Structure();
		Notification.Insert("DataArea", SessionSeparatorValue);
		Notification.Insert("UserName", Session.User.Name);
		Notification.Insert("SessionNumber", Session.SessionNumber);
		Notification.Insert("UserNotification", UserNotification);
		
		Notifications.Add(Notification);

	EndDo;
	
	If ValueIsFilled(Notifications) Then
		
		ModuleUsersNotificationCTL = Common.CommonModule("UsersNotificationCTL");
		ModuleUsersNotificationCTL.DeliverAlerts(Notifications);
		
		CommonCTL.Pause(30);
		
	EndIf;
	
EndProcedure

Procedure CompleteUpload(ExportProcessParameters, Node)
	
	MetadataObject_Users = Metadata.Catalogs.Users;
	UploadExtensionData = ValueIsFilled(Node);
	
	For Each MetadataObject In ExportProcessParameters.TypesToExport Do
		
		If ThisIsExcludedType(ExportProcessParameters.TypesToExclude, MetadataObject) Then
			Continue;
		EndIf;
		
		If CommonCTL.IsSequenceRecordSet(MetadataObject) Then
			
			ExportImportSequencesBoundaryData.BeforeUnloadingType(
				ExportProcessParameters.Container,
				ExportProcessParameters.Serializer,
				MetadataObject,
				False);
				
			Continue;
			
		EndIf;
		
		ExportMetadataObject = MetadataObject = MetadataObject_Users
			Or Metadata.ExchangePlans.Contains(MetadataObject);
			
		If Not ExportMetadataObject And UploadExtensionData Then
			ExportMetadataObject = MetadataObject.ConfigurationExtension() <> Undefined
				And Not Metadata.ExchangePlans.ApplicationsMigration.Content.Contains(MetadataObject);
		EndIf;
		
		If ExportMetadataObject Then
			UploadMetadataObject(ExportProcessParameters, MetadataObject);
		EndIf;
		
	EndDo;
	
EndProcedure

Function MainNodeCode()
	
	Return "c191c628-b094-11ea-a48c-0242ac130016";
		
EndFunction

Function AdditionalNodeCode()
	
	Return "974d5c6d-2d7e-4067-9614-dac005823e0e";
		
EndFunction

Function ThisIsExcludedType(TypesToExclude, MetadataObject)
	
	If TypesToExclude.Find(MetadataObject) = Undefined Then
		Return False;
	EndIf;
	
	Event = NStr(
		"ru = 'Выгрузка загрузка данных. Выгрузка объекта пропущена';
		|en = 'Data export and import. Object export skipped';",
		Common.DefaultLanguageCode());
	Comment = StrTemplate(
		NStr("ru = 'Выгрузка данных объекта метаданных %1 пропущена, т.к. он включен в
			 |список объектов метаданных, исключаемых из выгрузки и загрузки данных';
			|en = 'Data export skipped for metadata object %1, as the object is in
			|the list of metadata objects to be excluded from data import and export procedures';"),
		MetadataObject.FullName());
	
	WriteLogEvent(Event, EventLogLevel.Information, MetadataObject, , Comment);
		
	Return True;
	
EndFunction

// Export a metadata object.
// 
// Parameters:
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
//  MetadataObject - MetadataObject - Metadata object to be exported.
//  Node - ExchangePlanRef.ApplicationsMigration, Undefined - Node.
Procedure UploadMetadataObject(ExportProcessParameters, MetadataObject, Node = Undefined)
			
	ObjectExportManager = Create();
	
	ObjectExportManager.Initialize(
		ExportProcessParameters.Container,
		MetadataObject,
		Node,
		ExportProcessParameters.Handlers,
		ExportProcessParameters.Serializer,
		ExportProcessParameters.StreamRecordingOfReCreatedLinks,
		ExportProcessParameters.RecordFlowOfMappedLinks);
	
	ObjectExportManager.ExportData();
	
	ObjectExportManager.Close();
	
EndProcedure

Procedure BlockAllUnloadedObjects(TypesToExclude, Container)
	
	Block = New DataLock();
	For Each MetadataObject In Container.ExportingParameters().TypesToExport Do
		If TypesToExclude.Find(MetadataObject) = Undefined Then
			If SaaSOperations.ThisIsFullNameOfRecalculation(MetadataObject.FullName()) Then
				LockSpaceByParts = New Array;
				LockSpaceByParts.Add("Recalculation");
				LockSpaceByParts.Add(MetadataObject.Name);
				LockSpaceByParts.Add("RecordSet");
				Block.Add(StrConcat(LockSpaceByParts, "."));
			Else
				Block.Add(MetadataObject.FullName());
			EndIf;
		EndIf;
	EndDo;
	//@skip-check lock-out-of-try
	Block.Lock();
	
EndProcedure

#EndRegion

#EndIf
