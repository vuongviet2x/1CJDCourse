////////////////////////////////////////////////////////////////////////////////
// "Data import and export" subsystem.
//
////////////////////////////////////////////////////////////////////////////////
//

// This module's procedures and functions provide the functionality for mapping
// and re-generating references stored in value storages.
// The comparison requires additional processing as all values are serialized into Base64 in the storage.
// 
// 

#Region Internal

#Region RegisteringDataUploadAndDownloadHandlers

// Called upon registration of arbitrary data export handlers.
// This procedure requires that you add information on the arbitrary data export handlers 
// being registered to the value table.
// 
// Parameters:
//   HandlersTable - ValueTable - Columns:
//    * MetadataObject - MetadataObject - Metadata object during whose data export the handler is called.
//    * Handler - CommonModule - a common module implementing an arbitrary data export handler. The set
//       of export procedures to be implemented in the handler depends on the values of the following
//       value table columns.
//    * Version - String - a number of the interface version of data export/import handlers supported by the handler,
//    * BeforeUnloadingType - Boolean - a flag specifying whether the handler must be called before exporting all infobase objects
//       associated with this metadata object. If set to True, the common module of the handler must include 
//       the exportable procedure BeforeExportType() supporting the following parameters:
//        Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used 
//         for data export. For more information, see the comment to data processor API.
//        Serializer - XDTOSerializer - a serializer initialized with reference annotation support. If you need to export
//         additional data in an arbitrary export handler,
//         use XDTOSerializer, passed to the BeforeExportType() procedure as the Serializer parameter value, 
//         and not obtained using global context property XDTOSerializer.
//        MetadataObject - MetadataObject - a handler is called before the object data is exported.
//        Cancel - Boolean - If the parameter value is set to True 
//         in the BeforeExportType() procedure, the objects corresponding to the current metadata object are not exported.
//    * BeforeExportObject - Boolean - Flag specifying whether the handler must be called before exporting a specific 
//       infobase object. If set to True, the common handler module must include 
//       the exportable procedure BeforeExportObject() supporting the following parameters::
//        Container - DataProcessorObject.ExportImportDataContainerManager - Container manager 
//        used for data export. For more information, see the data processor API comment.
//        ObjectExportManager - DataProcessorObject.ExportImportDataInfobaseDataExportManager -
//          Export manager of the current object. For more information, see the comment to the
//          ExportImportDataInfobaseDataExportManager data processor API. Parameter is passed only
//          if procedures of handlers with version not earlier than 1.0.0.1 specified upon registration are called.
//        Serializer - XDTOSerializer - Serializer initialized with reference annotation support. If you need
//         to export additional data in an arbitrary export handler, use
//          XDTOSerializer passed to the BeforeExportObject() procedure as the Serializer parameter value,
//          and not obtained using the XDTOSerializer global context property.
//        Object - ManagerOfConstantValue, CatalogObject, DocumentObject,
//          BusinessProcessObject, TaskObject, ChartOfAccountsObject, ExchangePlanObject, ChartOfCharacteristicTypesObject, 
//          ChartOfCalculationTypesObject, InformationRegisterRecordSet, AccumulationRegisterRecordSet, 
//          AccountingRegisterRecordSet, CalculationRegisterRecordSet, SequenceRecordSet, 
//          RecalculationRecordSet - Infobase data object exported after calling the handler.
//          Value passed to the BeforeExportObject() procedure. It can be changed 
//          as the Object parameter value in the BeforeExportObject() handler. The changes will be reflected 
//          in the object serialization in export files, but not in the infobase.
//        Artifacts - Array of XDTODataObject - Set of additional information logically associated with the object but
//          not contained in it (object artifacts). Artifacts must be created 
//          in the BeforeExportObject() handler and added to the array passed as the Artifacts parameter value. 
//          Each artifact must be an XDTO data object, for whose type 
//          an abstract {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact XDTO type is used as the base type. You can use XDTO packages 
//          that are not included in the ExportImportData subsystem. The artifacts
//          generated in the BeforeExportObject() procedure will be available in the data import 
//          handler procedures (See OnRegisterDataImportHandlers)
//        . 
//          Cancel - Boolean - If set to True in the BeforeExportObject() procedure, the object,
//                                       which required calling the handler, is not exported.
//    * AfterUnloadingType - Boolean - a flag specifying whether the handler is called after all infobase 
//       objects associated with this metadata object are exported. If set to True, the common module of the handler 
//       must include the exportable procedure BeforeExportType() supporting the following parameters:
//        Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used 
//         for data export. For more information, see the comment to data processor API
//        Serializer - XDTOSerializer initialized with reference annotation support. In case 
//         the arbitrary export handler requires exporting additional data, use
//          XDTOSerializer passed to the AfterExportType() procedure as value of the Serializer parameter 
//          and not obtained using the XDTOSerializer global context property,
//        MetadataObject - MetadataObject - a handler is called after the object data is exported.
//
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	MetadataList = ExportImportValueStoragesDataCached.ListOfMetadataObjectsThatHaveValueStore();
	
	For Each ListItem In MetadataList Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Metadata.FindByFullName(ListItem.Key);
		NewHandler.Handler = ExportImportValueStoragesData;
		NewHandler.BeforeExportObject = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
		
	EndDo;
	
	NewHandler = HandlersTable.Add();
	NewHandler.Handler = ExportImportValueStoragesData;
	NewHandler.BeforeUploadingSettings = True;
	NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
	
EndProcedure

// Called upon registration of arbitrary data import handlers.
// This procedure requires that you add information on the arbitrary data import handlers being registered
// to the value table.
// 
// Parameters:
//   HandlersTable - ValueTable - Columns:
//   * MetadataObject - MetadataObject - a handler to be registered is called when the object data is exported,
//   * Handler - CommonModule - a common module implementing an arbitrary data import handler. The set 
//      of export procedures to be implemented in the handler depends on the values of the following
//      value table columns.
//   * Version - String - a number of the interface version of data export/import handlers supported by the handler,
//   * BeforeMapRefs - Boolean - Flag specifying whether the handler must be called before mapping the source 
//      infobase references and the current infobase references associated with this metadata object. If set to True, the common
//      module of the handler must include the BeforeMapRefs() exportable procedure, supporting 
//      the following parameters::
//        Container - DataProcessorObject.ExportImportDataContainerManager - Container manager 
//          used for data import. For more information, see the comment to the data processor API.
//          MetadataObject - MetadataObject - Handler is called before the object references are mapped.
//        StandardProcessing - Boolean - If set to False in BeforeMapRefs(), the MapRefs() function of the corresponding common module 
//          will be called instead of the standard reference mapping (searching the current infobase for objects
//          with the natural key values identical to the values exported 
//          from the source infobase) in the BeforeMapRefs() procedure whose StandardProcessing parameter 
//          value was set to False.
//          MapRefs() function parameters:
//            Container - DataProcessorObject.ExportImportDataContainerManager - Container manager
//              used for data import. For more information, see the comment to the data processor API.
//            SourceRefsTable - ValueTable - Contains information on references exported from the source infobase. 
//              Columns:
//                SourceRef - AnyRef - Source infobase object reference 
//                  to be mapped to the current infobase reference. 
//                The other columns are identical to the object's natural key fields that were passed 
//                  to the ExportImportInfobaseData.MustMapRefOnImport() function.
//          MapRefs function returns ValueTable. Columns:
//            SourceRef - AnyRef - Object reference exported from the source infobase.
//            Ref - AnyRef - Reference mapped to the original reference in the current infobase.
//        Cancel - Boolean - If set to True in BeforeMapRefs(), 
//          references matching the current metadata object are not mapped.
//   * BeforeImportType - Boolean - a flag specifying whether the handler must be called before importing all data objects 
//      associated with this metadata object. If set to True, the common module of the handler
//      must include the exportable procedure BeforeImportType() supporting the following parameters:
//        Container - DataProcessorObject.ExportImportDataContainerManager - a container manager 
//          used for data import. For more information, see the comment to data processor API.
//        MetadataObject - MetadataObject. The handler is called before the object data is imported.
//        Cancel - Boolean - if the parameter is set to True 
//          in the BeforeImportType() procedure, all data objects related to the current metadata object will not be imported.
//   * BeforeImportObject - Boolean - Flag specifying whether the handler must be called before importing the data object 
//       associated with this metadata object. If set to True, the common module of the handler must include
//       the BeforeImportObject() exportable procedure supporting the following parameters::
//        Container - DataProcessorObject.ExportImportDataContainerManager - Container manager 
//          used for data import. For more information, see the comment to the data processor API.
//        Object - ManagerOfConstantValue, CatalogObject, DocumentObject, BusinessProcessObject, TaskObject, 
//          ChartOfAccountsObject, ExchangePlanObject, ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, 
//          InformationRegisterRecordSet, AccumulationRegisterRecordSet, AccountingRegisterRecordSet,
//          CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet - Infobase data object 
//          imported after the handler is called.
//          Value passed to the BeforeImportObject() procedure as the Object parameter value 
//          can be modified inside the BeforeImportObject() handler procedure.
//        Artifacts - Array of XDTODataObject - Additional data logically associated with the data object 
//          but not contained in it. Generated in the BeforeExportObject() exportable procedures of data export 
//          handlers (see comment to the OnRegisterDataExportHandlers() procedure. Each artifact 
//          must be an XDTO object with an abstract {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact XDTO type used as a base type.
//          You can use XDTO packages 
//          that are not included in the ExportImportData subsystem.
//        Cancel - Boolean - If you set this 
//          parameter to True in the BeforeImportObject() procedure, the data object is not imported.
//   * AfterImportObject - Boolean - Flag specifying whether the handler must be called after importing a data object
//      associated with this metadata object. If set to True, the common module of the handler must include the 
//      AfterImportObject() exportable procedure supporting the following parameters::
//        Container - DataProcessorObject -ExportImportDataContainerManager - Container manager
//          used for data import. For more information, see the comment to the data processor API.
//        Object - ManagerOfConstantValue, CatalogObject, DocumentObject, BusinessProcessObject, TaskObject, 
//          ChartOfAccountsObject, ExchangePlanObject, ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, 
//          InformationRegisterRecordSet, AccumulationRegisterRecordSet, AccountingRegisterRecordSet,
//          CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet - Infobase data object 
//          imported before the handler is called.
//        Artifacts - Array of XDTODataObject - Additional data logically associated with the data object 
//          but not contained in it. Generated in the BeforeExportObject() exportable procedures of data export 
//          handlers (see comment to the OnRegisterDataExportHandlers() procedure). 
//          Each artifact must be the XDTO object with an abstract {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact XDTO 
//          type used as a base type. You can use XDTO packages 
//          that are not included in the ExportImportData subsystem.
//   * AfterLoadingType - Boolean - a flag specifying whether the handler must be called after importing all data objects 
//     associated with this metadata object. If set to True, the common module of the handler
//     must include the exportable procedure AfterImportType() supporting the following parameters:
//        Container - DataProcessorObject.ExportImportDataContainerManager - a container manager 
//        used for data import. For more information, see the processor API comment.
//        MetadataObject - MetadataObject - a handler is called after all its objects are imported.
//
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
	
	MetadataList = ExportImportValueStoragesDataCached.ListOfMetadataObjectsThatHaveValueStore();
	
	For Each ListItem In MetadataList Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Metadata.FindByFullName(ListItem.Key);
		NewHandler.Handler = ExportImportValueStoragesData;
		NewHandler.BeforeImportObject = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
		
	EndDo;
	
	NewHandler = HandlersTable.Add();
	NewHandler.Handler = ExportImportValueStoragesData;
	NewHandler.BeforeDownloadingSettings = True;
	NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
	
EndProcedure

#EndRegion

#EndRegion


#Region Private

#Region DataUploadAndDownloadHandlers

// Runs prior to object export.
// See OnRegisterDataExportHandlers
//
Procedure BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel) Export
	
	MetadataObject = Object.Metadata();
	PropsWithValueStorage = DetailsOfObjectWithValueStore(Container, MetadataObject);
	
	If PropsWithValueStorage = Undefined Then
		
		Raise StrTemplate(NStr("ru = 'Объект метаданных %1 не может быть обработан обработчиком %2.';
										|en = 'The %2 handler cannot process the %1 metadata object.';"),
			MetadataObject.FullName(),
			"ExportImportValueStoragesData.BeforeExportObject");
		
	EndIf;
	
	If CommonCTL.IsConstant(MetadataObject) Then
		
		BeforeUnloadingConstant(Container, Object, Artifacts, PropsWithValueStorage);
		
	ElsIf CommonCTL.IsRefData(MetadataObject) Then
		
		BeforeUnloadingReferenceObject(Container, Object, Artifacts, PropsWithValueStorage);
		
	ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
		
		BeforeExportRecordSet(Container, Object, Artifacts, PropsWithValueStorage);
		
	Else
		
		Raise StrTemplate(NStr("ru = 'Неожиданный объект метаданных: %1.';
										|en = 'Unexpected metadata object: %1.';"),
			MetadataObject.FullName);
		
	EndIf;
	
EndProcedure



// It is performed before importing settings.
// 
// Parameters:
// 	Container - DataProcessorObject.ExportImportDataUserSettingsImportManager - 
// 	Serializer - XDTOSerializer - 
// 	NameOfSettingsStore - String - 
// 	SettingsKey - String - See the Syntax Assistant.
// 	ObjectKey - String - See the Syntax Assistant.
// 	Settings - ValueStorage - 
// 	User - InfoBaseUser - 
// 	Presentation - String - 
// 	Artifacts - Array of XDTODataObject - additional data.
// 	Cancel - Boolean - indicates that processing is canceled.
Procedure BeforeUploadingSettings(Container, Serializer, NameOfSettingsStore, SettingsKey, ObjectKey, Settings, User, Presentation, Artifacts, Cancel) Export
	
	If TypeOf(Settings) = Type("ValueStorage") Then
		
		NewArtifact = XDTOFactory.Create(ValueStoreArtifactType());
		NewArtifact.Owner = XDTOFactory.Create(TypeOwnerBody());
		
		If UnloadValueStorage(Container, Settings, NewArtifact.Data) Then
			Settings = Undefined;
			Artifacts.Add(NewArtifact);
		EndIf;
		
	EndIf;
	
EndProcedure

// See OnRegisterDataExportHandlers
// Runs prior to object export.
//
Procedure BeforeImportObject(Container, Object, Artifacts, Cancel) Export
	
	MetadataObject = Object.Metadata();
	
	For Each Artifact In Artifacts Do
		
		If Artifact.Type() <> ValueStoreArtifactType() Then
			Continue;
		EndIf;
		
		If CommonCTL.IsConstant(MetadataObject) Then
			
			BeforeLoadingConstant(Container, Object, Artifact);
			
		ElsIf CommonCTL.IsRefData(MetadataObject) Then
			
			BeforeLoadingReferenceObject(Container, Object, Artifact);
			
		ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
			
			BeforeLoadingRecordset(Container, Object, Artifact);
			
		Else
			
			Raise StrTemplate(NStr("ru = 'Неожиданный объект метаданных: %1.';
											|en = 'Unexpected metadata object: %1.';"),
				MetadataObject.FullName);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure BeforeDownloadingSettings(Container, NameOfSettingsStore, SettingsKey, ObjectKey, Settings, User, Presentation, Artifacts, Cancel) Export
	
	For Each Artifact In Artifacts Do
		
		If Artifact.Type() = ValueStoreArtifactType() And Artifact.Owner.Type() = TypeOwnerBody() Then
			
			LoadValueStore_(Container, Settings, Artifact);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// Exporting value storage data

// It is called before exporting a constant with a value storage.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used
//	 for data export. For more information, see the comment to ExportImportDataContainerManager data processor API.
//	Object - Arbitrary - an object of the data being exported.
//	Artifacts - Array - an array of artifacts (XDTO data objects).
//	PropsWithValueStorage - Array of Structure - see StructureOfAttributesWithValueStorage
//
Procedure BeforeUnloadingConstant(Container, Object, Artifacts, PropsWithValueStorage)
	
	NewArtifact = XDTOFactory.Create(ValueStoreArtifactType());
	NewArtifact.Owner = XDTOFactory.Create(TypeOwnerConstant());
	
	If UnloadValueStorage(Container, Object.Value, NewArtifact.Data) Then
		Object.Value = New ValueStorage(Undefined);
		Artifacts.Add(NewArtifact);
	EndIf;
	
EndProcedure

// It is called before exporting a reference object with a value storage.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used
//	 for data export. For more information, see the comment to ExportImportDataContainerManager data processor API.
//	Object - Arbitrary - an object of the data being exported.
//	Artifacts - Array - an array of artifacts (XDTO data objects).
//	PropsWithValueStorage - Array of Structure - see StructureOfAttributesWithValueStorage.
//
Procedure BeforeUnloadingReferenceObject(Container, Object, Artifacts, PropsWithValueStorage)
	
	For Each CurrentAttribute In PropsWithValueStorage Do
		
		If CurrentAttribute.TabularSectionName = Undefined Then
			
			AttributeName = CurrentAttribute.AttributeName;
			
			NewArtifact = XDTOFactory.Create(ValueStoreArtifactType());
			NewArtifact.Owner = XDTOFactory.Create(OwnerObjectType());
			NewArtifact.Owner.Property = AttributeName;
			
			If UnloadValueStorage(Container, Object[AttributeName], NewArtifact.Data) Then
				Object[AttributeName] = New ValueStorage(Undefined);
				Artifacts.Add(NewArtifact);
			EndIf;
			
		Else
			
			AttributeName      = CurrentAttribute.AttributeName;
			TabularSectionName = CurrentAttribute.TabularSectionName;
			
			For Each LineOfATabularSection In Object[TabularSectionName] Do 
				
				NewArtifact = XDTOFactory.Create(ValueStoreArtifactType());
				NewArtifact.Owner = XDTOFactory.Create(TypeOwnerTabularPart());
				NewArtifact.Owner.TabularSection = TabularSectionName;
				NewArtifact.Owner.Property = AttributeName;
				NewArtifact.Owner.LineNumber = LineOfATabularSection.LineNumber;
				
				If UnloadValueStorage(Container, LineOfATabularSection[AttributeName], NewArtifact.Data) Then
					LineOfATabularSection[AttributeName] = New ValueStorage(Undefined);
					Artifacts.Add(NewArtifact);
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// It is called before exporting an object record set with a value storage.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used
//	 for data export. For more information, see the comment to ExportImportDataContainerManager data processor API.
//	RecordSet - InformationRegisterRecordSet, CalculationRegisterRecordSet, AccountingRegisterRecordSet - 
//               - CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet - a set of data to be exported.
//	Artifacts - Array - an array of artifacts (XDTO data objects).
//	PropsWithValueStorage - Array of Structure - see StructureOfAttributesWithValueStorage.
//
Procedure BeforeExportRecordSet(Container, RecordSet, Artifacts, PropsWithValueStorage)
	
	For Each CurrentAttribute In PropsWithValueStorage Do
		
		PropertyName = CurrentAttribute.AttributeName;
		
		For Each Record In RecordSet Do
			
			NewArtifact = XDTOFactory.Create(ValueStoreArtifactType());
			NewArtifact.Owner = XDTOFactory.Create(TypeOwnerRecordset());
			NewArtifact.Owner.Property = PropertyName;
			NewArtifact.Owner.LineNumber = RecordSet.IndexOf(Record);
			
			If UnloadValueStorage(Container, Record[PropertyName], NewArtifact.Data) Then
				Record[PropertyName] = New ValueStorage(Undefined);
				Artifacts.Add(NewArtifact);
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Exports a value storage.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used 
//	 for data export. For more information, see the comment to ExportImportDataContainerManager data processor API.
//	ValueStorage - ValueStorage - storage.
//	Artifact - XDTODataObject - artifact.
//
// Returns:
//	Boolean - True if it is exported.
//
Function UnloadValueStorage(Container, ValueStorage, Artifact)
	
	If ValueStorage = Null Then
		
		// For example, attribute values used only for catalog items read from the catalog group.
		// 
		Return False;
		
	EndIf;
	
	Try
		
		Value = ValueStorage.Get();
		
	Except
		
		// If failed to obtain the saved value from the storage,
		// do not serialized and keep it in the object.
		Return False;
		
	EndTry;
	
	If Value = Undefined
		Or (CommonCTL.IsPrimitiveType(TypeOf(Value)) And Not ValueIsFilled(Value)) Then
		
		Return False;
		
	Else
		
		Try
			
			Artifact = WriteValueStoreToArtifact(Container, Value);
			Return True;
			
		Except
			
			Return False; // If you cannot serialize a storage, leave it in the object.
			
		EndTry;
		
	EndIf;
	
EndFunction

// Writes a value storage to an artifact.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used 
//	 for data export. For more information, see the comment to ExportImportDataContainerManager data processor API.
//	StorageValue - Arbitrary - a storage value.
//
// Returns:
//	XDTODataObject - artifact.
//
Function WriteValueStoreToArtifact(Container, Val StorageValue)
	
	UploadAsBinary = TypeOf(StorageValue) = Type("BinaryData");
	
	If UploadAsBinary Then
		
		Return WriteBinaryValueStorageToArtifact(Container, StorageValue);
		
	Else
		
		Return WriteSerializableValueStorageToArtifact(Container, StorageValue);
		
	EndIf;
	
EndFunction

// Writes a value being serialized to an artifact.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used 
//	 for data export. For more information, see the comment to ExportImportDataContainerManager data processor API.
//	StorageValue - Arbitrary - a storage value.
//
// Returns:
//	XDTODataObject - artifact.
//
Function WriteSerializableValueStorageToArtifact(Container, Val StorageValue)
	
	ValueDescription = XDTOFactory.Create(TypeSerializableValue());
	ValueDescription.Data = XDTOSerializer.WriteXDTO(StorageValue);
	
	Return ValueDescription;
	
EndFunction

// Writes a binary value to an artifact.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - Container	manager used
//	 for data export. For more information, see the comment	to the ExportImportDataContainerManager data processor API.	
//	StorageValue - BinaryData - a storage value.
//
// Returns:
//	XDTODataObject - artifact.
//
Function WriteBinaryValueStorageToArtifact(Container, Val StorageValue)
	
	FileName = Container.CreateCustomFile("bin");
	StorageValue.Write(FileName);
	
	ValueDescription = XDTOFactory.Create(TypeBinaryValue());
	ValueDescription.RelativeFilePath = Container.GetRelativeFileName(FileName);
	
	Container.FileRecorded(FileName);
	
	Return ValueDescription;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Importing value storage data

// It is called before importing a constant.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used 
//	 for data export. For more information, see the comment to ExportImportDataContainerManager data processor API.
//	Object - ConstantValueManager - a constant value manager.
//	Artifact - XDTODataObject - artifact:
//	 * Owner - XDTODataObject - an artifact owner…
//
Procedure BeforeLoadingConstant(Container, Object, Artifact)
	
	If Artifact.Owner.Type() = TypeOwnerConstant() Then
		LoadValueStore_(Container, Object.Value, Artifact);
	Else
		
		Raise StrTemplate(NStr("ru = 'Тип владельца {%1}%2 не должен использоваться для объекта метаданных %3.';
										|en = 'Type of owner {%1}%2 cannot be used for metadata object %3.';"),
			Artifact.Owner.Type().NamespaceURI,
			Artifact.Owner.Type().Name,
			Object.Metadata().FullName());
		
	EndIf;
	
EndProcedure

// It is called before importing a reference object.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used
//	 for data export. For more information, see the comment to ExportImportDataContainerManager data processor API.
//	Object - Arbitrary - object of reference type.
//	Artifact - XDTODataObject - artifact:
//	 * Owner - XDTODataObject - an artifact owner…
//
Procedure BeforeLoadingReferenceObject(Container, Object, Artifact)
	
	If Artifact.Owner.Type() = OwnerObjectType() Then
		LoadValueStore_(Container, Object[Artifact.Owner.Property], Artifact);
	ElsIf Artifact.Owner.Type() = TypeOwnerTabularPart() Then
		LoadValueStore_(Container,
			Object[Artifact.Owner.TabularSection].Get(Artifact.Owner.LineNumber - 1)[Artifact.Owner.Property],
			Artifact);
	Else
		
		Raise StrTemplate(NStr("ru = 'Тип владельца {%1}%2 не должен использоваться для объекта метаданных %3.';
										|en = 'Type of owner {%1}%2 cannot be used for metadata object %3.';"),
			Artifact.Owner.Type().NamespaceURI,
			Artifact.Owner.Type().Name,
			Object.Metadata().FullName());
		
	EndIf;
	
EndProcedure

// It is called before importing a record set.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used
//	 for data export. For more information, see the comment to ExportImportDataContainerManager data processor API.
//  RecordSet - InformationRegisterRecordSet, CalculationRegisterRecordSet, AccountingRegisterRecordSet -
//               - CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet - record set.
//	Artifact - XDTODataObject - artifact:
//	 * Owner - XDTODataObject - an artifact owner….
Procedure BeforeLoadingRecordset(Container, RecordSet, Artifact)
	
	If Artifact.Owner.Type() = TypeOwnerRecordset() Then
		LoadValueStore_(Container,
			RecordSet.Get(Artifact.Owner.LineNumber)[Artifact.Owner.Property],
			Artifact);
	Else
		
		Raise StrTemplate(NStr("ru = 'Тип владельца {%1}%2 не должен использоваться для объекта метаданных %3.';
										|en = 'Type of owner {%1}%2 cannot be used for metadata object %3.';"),
			Artifact.Owner.Type().NamespaceURI,
			Artifact.Owner.Type().Name,
			RecordSet.Metadata().FullName());
		
	EndIf;
	
EndProcedure

// Imports a value storage value from the artifact.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used
//	 for data export. For more information, see the comment to ExportImportDataContainerManager data processor API.
//	RecordSet - a record set.
//	Artifact - XDTODataObject - artifact:
//	 * Data - XDTODataObject - an artifact data….
//
Procedure LoadValueStore_(Container, ValueStorage, Artifact)
	
	If Artifact.Data.Type() = TypeBinaryValue() Then
		FileName = Container.GetFullFileName(Artifact.Data.RelativeFilePath);
		Value = New BinaryData(FileName);
	ElsIf Artifact.Data.Type() = TypeSerializableValue() Then
		Value = LoadSerializableValueData(Artifact.Data.Data);
	Else
		
		Raise StrTemplate(NStr("ru = 'Неожиданный тип размещения данных хранилища значений в контейнере выгрузки: {%1}%2.';
										|en = 'Unexpected placement type of value storage data in export container: {%1}%2.';"),
			Artifact.Data.Type().NamespaceURI,
			Artifact.Data.Type().Name);
		
	EndIf;
	
	ValueStorage = New ValueStorage(Value);
	
EndProcedure

Function LoadSerializableValueData(ArtifactValue)
	
	If TypeOf(ArtifactValue) = Type("XDTODataObject") Then
		Try
			Value = XDTOSerializer.ReadXDTO(ArtifactValue);
		Except
			If ArtifactValue.Type() = XDTOTypeOfDataAlignmentSettings() Then
				Value = Undefined;
			Else
				Raise;
			EndIf;
		EndTry;
	Else
		Value = ArtifactValue;
	EndIf;	
	
	Return Value;
	
EndFunction

Function XDTOTypeOfDataAlignmentSettings()
	
	Return XDTOFactory.Type("http://v8.1c.ru/8.1/data-composition-system/settings", "Settings");
	
EndFunction

// Returns an array of structures, in which names of attributes and tabular sections
// that have value storages are stored.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container manager used
//	 for data export. For more information, see the comment to ExportImportDataContainerManager data processor API.
//	ObjectMetadata - MetadataObject - object metadata.
//
// Returns:
//	Array - Array of Structure - see StructureOfAttributesWithValueStorage.
//
Function DetailsOfObjectWithValueStore(Container, Val ObjectMetadata)
	
	FullMetadataName = ObjectMetadata.FullName();
	
	MetadataList = ExportImportValueStoragesDataCached.ListOfMetadataObjectsThatHaveValueStore();
	
	PropsWithValueStorage = MetadataList.Get(FullMetadataName);
	If PropsWithValueStorage = Undefined Then 
		Return Undefined;
	EndIf;
	
	Return PropsWithValueStorage;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Functions determining XDTO object types.

// Type of a value storage artifact.
//
// Returns:
//	XDTOObjectType - a type of the object to be returned.
//
Function ValueStoreArtifactType()
	
	Return XDTOFactory.Type(Package(), "ValueStorageArtefact");
	
EndFunction

// Type of a binary value.
//
// Returns:
//	XDTOObjectType - a type of the object to be returned.
//
Function TypeBinaryValue()
	
	Return XDTOFactory.Type(Package(), "BinaryValueStorageData");
	
EndFunction

// Type of a value to be serialized.
//
// Returns:
//	XDTOObjectType - a type of the object to be returned.
//
Function TypeSerializableValue()
	
	Return XDTOFactory.Type(Package(), "SerializableValueStorageData");
	
EndFunction

// Constant owner type.
//
// Returns:
//	XDTOObjectType - a type of the object to be returned.
//
Function TypeOwnerConstant()
	
	Return XDTOFactory.Type(Package(), "OwnerConstant");
	
EndFunction

// Type of a reference object owner.
//
// Returns:
//	XDTOObjectType - a type of the object to be returned.
//
Function OwnerObjectType()
	
	Return XDTOFactory.Type(Package(), "OwnerObject");
	
EndFunction

// Type of a tabular section owner.
//
// Returns:
//	XDTOObjectType - a type of the object to be returned.
//
Function TypeOwnerTabularPart()
	
	Return XDTOFactory.Type(Package(), "OwnerObjectTabularSection");
	
EndFunction

// Type of a record set owner.
//
// Returns:
//	XDTOObjectType - a type of the object to be returned.
//
Function TypeOwnerRecordset()
	
	Return XDTOFactory.Type(Package(), "OwnerRecordset");
	
EndFunction

Function TypeOwnerBody()
	
	Return XDTOFactory.Type(Package(), "OwnerBody");
	
EndFunction

// Returns a XDTO package namespace for value storages.
//
// Returns:
//	String - an XDTO package namespace for value storages.
//
Function Package()
	
	Return "http://www.1c.ru/1cFresh/Data/Artefacts/ValueStorage/1.0.0.1";
	
EndFunction

#EndRegion
