#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var CurHandlers;
Var HandlersAvailability; // Map of MetadataObject: Structure
Var ManagerIsInitialized;

#EndRegion

#Region Internal

Procedure Initialize() Export
	
	If ManagerIsInitialized Then
		Raise NStr("ru = 'Менеджер обработчиков загрузки данных уже был инициализирован ранее.';
								|en = 'The data import handler manager has been previously initialized.';");
	EndIf;
	
	BooleanType = New TypeDescription("Boolean");
	HandlerColumnsNames = HandlerColumnsNames();
	
	CurHandlers = New ValueTable;

	CurHandlers.Columns.Add("MetadataObject");
	CurHandlers.Columns.Add("Handler");
	CurHandlers.Columns.Add("Version", New TypeDescription("String"));
	
	For Each ColumnName In HandlerColumnsNames Do
		CurHandlers.Columns.Add(ColumnName, BooleanType);
	EndDo;

	// Integrated handlers.
	ExportImportValueStoragesData.OnRegisterDataImportHandlers(CurHandlers);
	ExportImportSequencesBoundaryData.OnRegisterDataImportHandlers(CurHandlers);
	ExportImportPredefinedData.OnRegisterDataImportHandlers(CurHandlers);
	ExportImportSharedPredefinedData.OnRegisterDataImportHandlers(CurHandlers);
	ExportImportCommonSeparatedData.OnRegisterDataImportHandlers(CurHandlers);
	ExportImportDataTotalsManagement.OnRegisterDataImportHandlers(CurHandlers);
	ExportImportUserFavorites.OnRegisterDataImportHandlers(CurHandlers);

	// Library event handlers
	CTLSubsystemsIntegration.OnRegisterDataImportHandlers(CurHandlers);

	// Overridable procedure.
	ExportImportDataOverridable.OnRegisterDataImportHandlers(CurHandlers);
	
	CurHandlers.Columns.Add("LineNumber");
	CurrentRowNumber1 = 1;
	
	For Each String In CurHandlers Do
		
		String.LineNumber = CurrentRowNumber1;
		CurrentRowNumber1 = CurrentRowNumber1 + 1;
		
		If IsBlankString(String.Version) Then
			String.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_0();
		EndIf;
		
	EndDo;
	
	CurHandlers.Indexes.Add("BeforeImportObject, MetadataObject");
	CurHandlers.Indexes.Add("AfterImportObject, MetadataObject");
	
	HandlersAvailability = ExportImportDataInternal.MetadataObjectsHandlersAvailability(
		CurHandlers, HandlerColumnsNames);
	ManagerIsInitialized = True;
		
EndProcedure

// 
//
Procedure BeforeImportData(Container) Export
		
	// RegisteredHandlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeImportData", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeImportData(Container);
	EndDo;
	
	// Library event handlers
	CTLSubsystemsIntegration.BeforeImportData(Container);
	
	// Overridable procedure.
	ExportImportDataOverridable.BeforeImportData(Container);
	
EndProcedure

// Executes a number of actions upon importing the infobase user.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - Container manager used for data export.
//		For details, see comments to the API of ExportImportDataContainerManager handler.
//		
//
Procedure AfterImportData(Container) Export
		
	// RegisteredHandlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterImportData", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterImportData(Container);
	EndDo;
	
	// Library event handlers
	CTLSubsystemsIntegration.AfterImportData(Container);
	
	// Overridable procedure.
	ExportImportDataOverridable.AfterImportData(Container);
	
EndProcedure

Procedure BeforeMapRefs(Container, MetadataObject, SourceRefsTable, StandardProcessing, NonStandardHandler, Cancel) Export
		
	// RegisteredHandlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeMapRefs", True);
	FilterHandlers_.Insert("MetadataObject", MetadataObject);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		
		HandlerDetails.Handler.BeforeMapRefs(Container, MetadataObject, SourceRefsTable, StandardProcessing, Cancel);
		
		If Not StandardProcessing Or Cancel Then
			NonStandardHandler = HandlerDetails.Handler;
			Return;
		EndIf;
		
	EndDo;
	
EndProcedure

// Actions to be executed upon replacing references.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used 
//	 for data export. For more information, see the comment to data processor API.
//	RefsMap - Map - See description of DataProcessorObject.ExportImportDataReferenceReplacementStream.
//
Procedure WhenReplacingLinks(Container, RefsMap) Export
		
	// RegisteredHandlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("WhenReplacingLinks", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.WhenReplacingLinks(Container, RefsMap);
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
		
	// RegisteredHandlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeImportType", True);
	FilterHandlers_.Insert("MetadataObject", MetadataObject);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeImportType(Container, MetadataObject, Cancel);
	EndDo;
	
EndProcedure

// Called before an object export.
// See "OnRegisterDataExportHandlers".
//
Procedure BeforeImportObject(Container, Object, Artifacts, Cancel) Export
		
	If TypeOf(Object) = Type("ObjectDeletion") Then
		Return;
	EndIf;
	
	// RegisteredHandlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeImportObject", True);
	FilterHandlers_.Insert("MetadataObject", Object.Metadata());

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeImportObject(Container, Object, Artifacts, Cancel);
	EndDo;
	
EndProcedure

// Executes handlers after object import.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container
//		manager used for data export. For more information, see the comment
//		to ExportImportDataContainerManager handler interface.
//	Object - Arbitrary - an object of data being imported.
//	Artifacts - Array of XDTODataObject - an array of artifacts (XDTO data objects).
//
Procedure AfterImportObject(Container, Object, Artifacts) Export
	
	If TypeOf(Object) = Type("ObjectDeletion") Then
		Return;
	EndIf;
	
	// RegisteredHandlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterImportObject", True);
	FilterHandlers_.Insert("MetadataObject", Object.Metadata());

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterImportObject(Container, Object, Artifacts);
	EndDo;
	
EndProcedure

// See description of the OnAddInternalEvents() procedure in the ExportImportDataInternalEvents common module.
//
Procedure AfterLoadingType(Container, MetadataObject) Export
		
	// RegisteredHandlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterLoadingType", True);
	FilterHandlers_.Insert("MetadataObject", MetadataObject);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterLoadingType(Container, MetadataObject);
	EndDo;
	
EndProcedure

Procedure BeforeLoadingSettingsStore(Container, NameOfSettingsStore, SettingsStorage, Cancel) Export

	// RegisteredHandlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeLoadingSettingsStore", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeLoadingSettingsStore(Container, NameOfSettingsStore, SettingsStorage, Cancel);
	EndDo;
	
EndProcedure

Procedure BeforeDownloadingSettings(Container, NameOfSettingsStore, SettingsKey, ObjectKey, Settings, User, Presentation, Artifacts, Cancel) Export
	
	// RegisteredHandlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeDownloadingSettings", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeDownloadingSettings(
			Container,
			NameOfSettingsStore,
			SettingsKey,
			ObjectKey,
			Settings,
			User,
			Presentation,
			Artifacts,
			Cancel);
	EndDo;
	
EndProcedure

Procedure AfterLoadingSettings(Container, NameOfSettingsStore, SettingsKey, ObjectKey, Settings, User, Presentation, Artifacts) Export
	
	// RegisteredHandlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterLoadingSettings", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterLoadingSettings(
			Container,
			NameOfSettingsStore,
			SettingsKey,
			ObjectKey,
			Settings,
			User,
			Presentation,
			Artifacts);
	EndDo;
	
EndProcedure

Procedure AfterLoadingSettingsStore(Container, NameOfSettingsStore, SettingsStorage) Export
	
	// RegisteredHandlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterLoadingSettingsStore", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterLoadingSettingsStore(Container, NameOfSettingsStore, SettingsStorage);
	EndDo;
	
EndProcedure

// Availability of handlers by a metadata object.
// 
// Parameters:
//  MetadataObject - MetadataObject - Metadata object.
// 
// Returns:
//  Structure - Availability of handlers by a metadata object.
Function MetadataObjectHandlersAvailability(MetadataObject) Export
	
	ObjectHandlersAvailability = HandlersAvailability.Get(MetadataObject);
	
	If ObjectHandlersAvailability = Undefined Then
		ObjectHandlersAvailability = ExportImportDataInternal.NewMetadataObjectHandlersAvailabilityData(
			HandlerColumnsNames());
	EndIf;
	
	Return ObjectHandlersAvailability;
	
EndFunction

#EndRegion

#Region Private

Function HandlerDescriptions(FilterHandlers_)
	FoundHandlers = CurHandlers.Copy(FilterHandlers_);
	FoundHandlers.Sort("LineNumber");
	Return FoundHandlers;
EndFunction

// Handler column names.
// 
// Returns:
//  Array of String - Column name.
Function HandlerColumnsNames()
	
	ColumnsNames = New Array();
	ColumnsNames.Add("BeforeImportData");
	ColumnsNames.Add("AfterImportData");
	ColumnsNames.Add("BeforeMapRefs");
	ColumnsNames.Add("WhenReplacingLinks");
	ColumnsNames.Add("BeforeImportType");
	ColumnsNames.Add("BeforeImportObject");
	ColumnsNames.Add("AfterImportObject");
	ColumnsNames.Add("AfterLoadingType");
	ColumnsNames.Add("BeforeLoadingSettingsStore");
	ColumnsNames.Add("BeforeDownloadingSettings");
	ColumnsNames.Add("AfterLoadingSettings");
	ColumnsNames.Add("AfterLoadingSettingsStore");
	
	Return ColumnsNames;
	
EndFunction

#EndRegion

#Region Initialize
	ManagerIsInitialized = False;
#EndRegion

#EndIf