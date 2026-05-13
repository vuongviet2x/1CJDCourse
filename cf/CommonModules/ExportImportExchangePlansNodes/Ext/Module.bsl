///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2021, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Fills in an array of types for which the reference annotation
// in files must be used upon export.
//
// Parameters:
//  Types - Array of MetadataObject - metadata objects.
//
Procedure OnFillTypesThatRequireRefAnnotationOnImport(Types) Export
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		Types.Add(ExchangePlan);
		
	EndDo;
	
EndProcedure

// For internal use.
// Parameters:
//  HandlersTable - See ExportImportDataOverridable.OnRegisterDataExportHandlers.HandlersTable
//
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = ExchangePlan;
		NewHandler.Handler = ExportImportExchangePlansNodes;
		NewHandler.BeforeExportObject = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
			
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = ExchangePlan;
		NewHandler.Handler = ExportImportExchangePlansNodes;
		NewHandler.AfterExportObject = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
		
	EndDo;
	
EndProcedure

// For internal use.
//
Procedure BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel) Export
	
	NewDelimiterValues = New Structure;
	NewDelimiterValues.Insert(SaaSOperations.MainDataSeparator(), 0);
	NewDelimiterValues.Insert(SaaSOperations.AuxiliaryDataSeparator(), 0);
	
	FillPropertyValues(Object, NewDelimiterValues);
	
EndProcedure

// For internal use.
//
Procedure AfterExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts) Export
	
	ObjectMetadata = Object.Metadata(); // MetadataObject
	
	If CommonCTL.IsExchangePlan(ObjectMetadata) Then
	
		ObjectExportManager.YouNeedToRecreateLinkWhenUploading(Object.Ref);
		
	Else
		
		Raise StrTemplate(
			NStr("ru = 'Объект метаданных %1 не может быть обработан обработчиком
				|ВыгрузкаЗагрузкаУзловПлановОбменов.ПослеВыгрузкиОбъекта()';
				|en = 'The ExportImportExchangePlansNodes.AfterExportObject() handler
				|cannot process the %1 metadata object';", Metadata.DefaultLanguage.LanguageCode),
			ObjectMetadata.FullName());
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function UploadRegisteredChangesForExchangePlanNodes(Container) Export
	
	ExportingParameters = Container.ExportingParameters();
	
	UploadRegisteredChangesForExchangePlanNodes = False;
	
	Return ExportingParameters.Property("UploadRegisteredChangesForExchangePlanNodes", UploadRegisteredChangesForExchangePlanNodes) And UploadRegisteredChangesForExchangePlanNodes = True;
	
EndFunction

Function TypesOfUploadedMetadataObjectExchangePlans(Container, MetadataObject)
	
	TypesOfUploadedExchangePlans = New Array;
	
	TypesToExport = Container.ExportingParameters().TypesToExport;
	TypesToExclude = ExportImportDataInternalEvents.GetTypesExcludedFromUploadUpload();
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		If TypesToExport.Find(ExchangePlan) <> Undefined
			And TypesToExclude.Find(ExchangePlan) = Undefined
			And ExchangePlan.Content.Find(MetadataObject) <> Undefined Then
			
			TypesOfUploadedExchangePlans.Add(Type("ExchangePlanRef." + ExchangePlan.Name));
			
		EndIf;
		
	EndDo;
	
	Return TypesOfUploadedExchangePlans;
	
EndFunction

Procedure UploadChanges(Container, MetadataObject, Serializer) Export
	
	If Not UploadRegisteredChangesForExchangePlanNodes(Container) Then
		
		Return;
		
	EndIf;
	
	TypesOfUploadedExchangePlans = TypesOfUploadedMetadataObjectExchangePlans(Container, MetadataObject);
	
	If TypesOfUploadedExchangePlans.Count() = 0 Then
		
		Return;
		
	EndIf;
	
	WriteStream = StartRecordingFile(Container, MetadataObject, Serializer);
		
	Query = New Query(
	"SELECT
	|	*
	|FROM
	|	#ChangesTable1 AS ChangesTable1
	|WHERE
	|	VALUETYPE(ChangesTable1.Node) IN (&TypesOfUploadedExchangePlans)");
	
	Query.Text = StrReplace(Query.Text, "#ChangesTable1", MetadataObject.FullName() + ".Changes");
	Query.SetParameter("TypesOfUploadedExchangePlans", TypesOfUploadedExchangePlans);
	
	QueryResult = Query.Execute();
	
	RecordingChange = New Structure;
	
	For Each Column In QueryResult.Columns Do
		
		RecordingChange.Insert(Column.Name);
		
	EndDo;
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		FillPropertyValues(RecordingChange, Selection);
		WriteStream.WriteInformationDatabaseDataObject(RecordingChange, New Array);
		
	EndDo;
	
	CompleteFileRecording(Container, MetadataObject, WriteStream);
		
EndProcedure

Function StartRecordingFile(Container, MetadataObject, Serializer)
	
	FileName = Container.CreateFile(
		ExportImportDataInternal.InfobaseData(), MetadataObject.FullName());
	
	WriteStream = DataProcessors.ExportImportDataInfobaseDataWritingStream.Create();
	WriteStream.OpenFile(FileName, Serializer, ExportImportDataInternal.InfobaseDataChanges());
	
	Return WriteStream;
	
EndFunction

Procedure CompleteFileRecording(Container, MetadataObject,  WriteStream)
	
	WriteStream.Close();
	
	ObjectCount = WriteStream.ObjectCount();
	
	If ObjectCount = 0 Then
		
		Container.ExcludeFile(WriteStream.FileName());
	Else
		
		Container.SetNumberOfObjects(WriteStream.FileName(), ObjectCount);
		
	EndIf;
	
	WriteLogEvent(
		NStr("ru = 'ВыгрузкаЗагрузкаДанных.ВыгрузкаИзмененийОбъектаМетаданных';
			|en = 'ExportImportData.ExportMetadataObjectChanges';", Common.DefaultLanguageCode()),
		EventLogLevel.Information,
		MetadataObject,
		,
		StrTemplate(NStr("ru = 'Окончание выгрузки изменений объекта метаданных: %1
		|Выгружено объектов: %2';
		|en = 'Finish exporting metadata object changes: %1
		|Objects exported: %2';", Common.DefaultLanguageCode()),
			MetadataObject.FullName(), ObjectCount));
	
EndProcedure

#EndRegion