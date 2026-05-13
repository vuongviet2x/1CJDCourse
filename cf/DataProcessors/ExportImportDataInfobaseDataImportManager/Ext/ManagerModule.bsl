#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Imports the infobase data.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container
//		manager used for data export. For more information, see the comment
//		to ExportImportDataContainerManager handler interface.
//	Handlers - CommonModule
//				- DataProcessorManager
//	RefsMap - Map of AnyRef - Link mapping.
// Returns:
//	DataProcessorObject.ExportImportDataReferenceReplacementStream
//
Function DownloadDatabaseData(Container, Handlers, RefsMap = Undefined) Export
	
	LoadableTypes = Container.ImportParameters().LoadableTypes;
	TypesToExclude = ExportImportDataInternalEvents.GetTypesExcludedFromUploadUpload();
	
	DownloadManager = Create();
	DownloadManager.Initialize(
		Container,
		LoadableTypes,
		TypesToExclude,
		Handlers,
		RefsMap);
	DownloadManager.ImportData();
	
	Return DownloadManager.CurFlowOfLinkReplacement();
	
EndFunction

// Import the infobase data in the stream.
// 
// Parameters:
//  StreamParameters - Structure - See the Parameters property in
//  	DataProcessorObject.ExportImportDataInfobaseDataImportManager.StartDataImportThreads.
// 
Procedure ImportInfoBaseDataInThread(StreamParameters) Export
	
	Container = DataProcessors.ExportImportDataContainerManager.Create();
	Container.InitializeImportInThread(StreamParameters.Container);
	
	Handlers = DataProcessors.ExportImportDataDataImportHandlersManager.Create();
	Handlers.Initialize();
	
	LoadableTypes = Undefined;
	TypesToExclude = Undefined;
	RefsMap = New Map(StreamParameters.LinkReplacementFlow.RefsMap);
		
	DownloadManager = Create();
	DownloadManager.Initialize(
		Container,
		LoadableTypes,
		TypesToExclude,
		Handlers,
		RefsMap);
	DownloadManager.ImportDataInThread();
	
EndProcedure

#EndRegion

#EndIf
