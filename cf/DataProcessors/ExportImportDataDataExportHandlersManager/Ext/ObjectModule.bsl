#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var CurHandlers;
Var HandlersAvailability; // Map of MetadataObject: Structure
Var ManagerIsInitialized;

#EndRegion
	
#Region Internal

Procedure Initialize(Val Container) Export
	
	If ManagerIsInitialized Then
		Raise NStr("ru = 'Менеджер обработчиков выгрузки данных уже был инициализирован ранее.';
								|en = 'The data export handler manager has been previously initialized.';");
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
	DataAreasExportForTechnicalSupport.BeforeExportData(Container, CurHandlers);
	ProcessingTypesExcludedFromUpload.OnRegisterDataExportHandlers(CurHandlers);
	ExportImportSharedData.OnRegisterDataExportHandlers(CurHandlers);
	ExportImportPredefinedData.OnRegisterDataExportHandlers(CurHandlers);
	ExportImportSharedPredefinedData.OnRegisterDataExportHandlers(CurHandlers);
	ExportImportCommonSeparatedData.OnRegisterDataExportHandlers(CurHandlers);
	ExportImportUserFavorites.OnRegisterDataExportHandlers(CurHandlers);
	ExportImportValueStoragesData.OnRegisterDataExportHandlers(CurHandlers);
	ExportImportExchangePlansNodes.OnRegisterDataExportHandlers(CurHandlers);
	ExportImportDataOfAdditionalReportsAndDataProcessors.OnRegisterDataExportHandlers(CurHandlers);

	// Library event handlers
	CTLSubsystemsIntegration.OnRegisterDataExportHandlers(CurHandlers);

	// Overridable procedure.
	ExportImportDataOverridable.OnRegisterDataExportHandlers(CurHandlers);

	CurHandlers.Columns.Add("LineNumber");
	CurrentRowNumber1 = 1;
	
	For Each String In CurHandlers Do
		
		String.LineNumber = CurrentRowNumber1;
		CurrentRowNumber1 = CurrentRowNumber1 + 1;
		
		If IsBlankString(String.Version) Then
			String.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_0();
		EndIf;

	EndDo;
	
	CurHandlers.Indexes.Add("BeforeExportObject, MetadataObject");
	CurHandlers.Indexes.Add("AfterExportObject, MetadataObject");

	HandlersAvailability = ExportImportDataInternal.MetadataObjectsHandlersAvailability(
		CurHandlers, HandlerColumnsNames);
	ManagerIsInitialized = True;
	
EndProcedure

Procedure BeforeExportData(Container) Export
	
	If Not ManagerIsInitialized Then
		Raise NStr("ru = 'Менеджер обработчиков выгрузки данных не инициализирован.';
								|en = 'The data export handler manager is not initialized.';");
	EndIf;
	
	// RegisteredHandlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeExportData", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeExportData(Container);
	EndDo;
	
	// Library event handlers.
	CTLSubsystemsIntegration.BeforeExportData(Container);
	
	// Overridable procedure.
	ExportImportDataOverridable.BeforeExportData(Container);
		
EndProcedure

// Called after data export.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - a container
//    manager used for data export. For more information, see the comment
//    to ExportImportDataContainerManager handler interface.
//
Procedure AfterExportData(Container) Export
	
	// RegisteredHandlers
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterExportData", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterExportData(Container);
	EndDo;
	
	// Library event handlers
	CTLSubsystemsIntegration.AfterExportData(Container);
	
	// Overridable procedure.
	ExportImportDataOverridable.AfterExportData(Container);
	
EndProcedure

// 
//
Procedure BeforeUnloadingType(Container, Serializer, MetadataObject, Cancel) Export
	
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeUnloadingType", True);
	FilterHandlers_.Insert("MetadataObject", MetadataObject);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeUnloadingType(Container, Serializer, MetadataObject, Cancel);
	EndDo;
	
EndProcedure

// Called before an object export.
// See "OnRegisterDataExportHandlers".
//
Procedure BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel) Export
	
	If TypeOf(Object) = Type("ObjectDeletion") Then
		Return;
	EndIf;
	
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeExportObject", True);
	FilterHandlers_.Insert("MetadataObject", Object.Metadata());
	
	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		
		If HandlerDetails.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_0() Then
			
			HandlerDetails.Handler.BeforeExportObject(Container, Serializer, Object, Artifacts, Cancel);
			
		Else
			
			HandlerDetails.Handler.BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Called before an object export.
//  See "OnRegisterDataExportHandlers".
//
Procedure AfterExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts) Export
	
	If TypeOf(Object) = Type("ObjectDeletion") Then
		Return;
	EndIf;
	
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterExportObject", True);
	FilterHandlers_.Insert("MetadataObject", Object.Metadata());
	
	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		
		If HandlerDetails.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_0() Then
			
			HandlerDetails.Handler.AfterExportObject(Container, Serializer, Object, Artifacts);
			
		Else
			
			HandlerDetails.Handler.AfterExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Executes handlers after exporting a particular data type.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container
//		manager used for data export. For more information, see the comment
//		to ExportImportDataContainerManager handler interface.
//	Serializer - XDTOSerializer - Serializer.
//	MetadataObject - MetadataObject - Metadata object.
//
Procedure AfterUnloadingType(Container, Serializer, MetadataObject) Export
		
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterUnloadingType", True);
	FilterHandlers_.Insert("MetadataObject", MetadataObject);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterUnloadingType(Container, Serializer, MetadataObject);
	EndDo;
	
EndProcedure

Procedure BeforeUnloadingSettingsStore(Container, Serializer, NameOfSettingsStore, Val SettingsStorage, Cancel) Export
	
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeUnloadingSettingsStore", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeUnloadingSettingsStore(Container, Serializer, NameOfSettingsStore, SettingsStorage, Cancel);
	EndDo;
	
EndProcedure

// It is performed before importing settings.
// 
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - 
//	Serializer - XDTOSerializer - Serializer.
//	NameOfSettingsStore - String -
//	SettingsKey - String - See the Syntax Assistant.
//	ObjectKey - String - See the Syntax Assistant.
//	Settings - ValueStorage - 
//	User - InfoBaseUser - 
//	Presentation - String - 
// 	Artifacts - Array of XDTODataObject - additional data.
// 	Cancel - Boolean - indicates that processing is canceled.
//
Procedure BeforeUploadingSettings(Container, Serializer, NameOfSettingsStore, SettingsKey, ObjectKey, Settings, User, Presentation, Artifacts, Cancel) Export
	
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("BeforeUploadingSettings", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.BeforeUploadingSettings(
			Container,
			Serializer,
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

Procedure AfterUnloadingSettings(Container, Serializer, NameOfSettingsStore, SettingsKey, ObjectKey, Settings, User, Presentation) Export
	
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterUnloadingSettings", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterUnloadingSettings(
			Container,
			Serializer,
			NameOfSettingsStore,
			SettingsKey,
			ObjectKey,
			Settings,
			User,
			Presentation);
	EndDo;
	
EndProcedure

Procedure AfterUnloadingSettingsStore(Container, Serializer, NameOfSettingsStore, Val SettingsStorage) Export
	
	FilterHandlers_ = New Structure();
	FilterHandlers_.Insert("AfterUnloadingSettingsStore", True);

	For Each HandlerDetails In HandlerDescriptions(FilterHandlers_) Do
		HandlerDetails.Handler.AfterUnloadingSettingsStore(Container, Serializer, NameOfSettingsStore, SettingsStorage);
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
	ColumnsNames.Add("BeforeExportData");
	ColumnsNames.Add("AfterExportData");
	ColumnsNames.Add("BeforeUnloadingType");
	ColumnsNames.Add("BeforeExportObject");
	ColumnsNames.Add("AfterExportObject");
	ColumnsNames.Add("AfterUnloadingType");
	ColumnsNames.Add("BeforeUnloadingSettingsStore");
	ColumnsNames.Add("BeforeUploadingSettings");
	ColumnsNames.Add("AfterUnloadingSettings");
	ColumnsNames.Add("AfterUnloadingSettingsStore");
	
	Return ColumnsNames;
	
EndFunction

#EndRegion

#Region Initialize
	ManagerIsInitialized = False;
#EndRegion

#EndIf
