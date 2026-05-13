////////////////////////////////////////////////////////////////////////////////
// "Data import and export" subsystem.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Adds update handler procedures required by this subsystem to the Handlers list.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//   Handlers - See InfobaseUpdate.NewUpdateHandlerTable
// 
Procedure RegisterUpdateHandlers(Handlers) Export
	
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export

	Parameters.Insert("UnloadingLoadingDataLoadingAborted", CommonServerCallCTL.DownloadAborted());
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// Data import export.

// Deletes a temporary file, errors upon deletion are ignored.
//
// Parameters:
//  Path - String - a path to the file to be deleted.
//
Procedure DeleteTempFile(Val Path) Export
	
	Info = New File(Path);
	If Not Info.Exists() Then
		Return;
	EndIf;
	
	Try
		DeleteFiles(Path);
	Except
		WriteLogEvent(NStr("ru = 'Удаление файла';
										|en = 'Delete file';", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			,
			,
			ErrorInfo().Description);
	EndTry;
	
EndProcedure

// Returns an array of all metadata objects contained in the configuration.
//  It is used to start data export and data import procedures in configurations that do not include SSL.
//
// Returns:
//   Array of MetadataObject - types.
//
// Example:
//  ExportParameters = New Structure();
//  ExportParameters.Insert("TypesToExport", ExportImportDataInternal.GetAllConfigurationTypes());
//  ExportParameters.Insert("ExportUsers", True);
//  ExportParameters.Insert("ExportUserSettings", True);
//  FileName = ExportImportData.ExportDataToArchive(ExportParameters);
//
//  ImportParameters = New Structure();
//  ImportParameters.Insert("TypesToImport", ExportImportDataInternal.GetAllConfigurationTypes());
//  ImportParameters.Insert("ImportUsers", True);
//  ImportParameters.Insert("ImportUsersSettings", True);
//  ExportImportData.ImportDataFromArchive(FileName, ImportParameters);
//
Function GetAllConfigurationTypes() Export
	
	ArrayOfMetadataCollections = New Array();
	
	FillCollectionsOfConstants(ArrayOfMetadataCollections);
	PopulateCollectionsOfReferenceObjects(ArrayOfMetadataCollections);
	PopulateRecordsetCollections(ArrayOfMetadataCollections);
	
	Return ArrayOfMetadataCollections;
	
EndFunction

// Exports data to a directory.
//
// Parameters:
//	ExportingParameters - Structure - Contains data export parameters.
//		Keys:
//			TypesToExport - Array of MetadataObject - Array of metadata objects whose data must be exported to the archive,
//				ExportUsers - Boolean - Export information on infobase users,
//			ExportUsersSettings - Boolean - Ignore the parameter if ExportUsers = False.
//			The structure can also contain additional keys that can be processed
//			in arbitrary data export handlers.
//				
//
// Returns:		
//  Structure - with the following fields::
//  * FileName - String - Archive file name.
//  * Warnings - Array of String - User notifications following the export.
//
Function UploadCurAreaDataToArchive(Val ExportingParameters) Export
	
	Container = DataProcessors.ExportImportDataContainerManager.Create();
	Container.InitializeUpload(ExportingParameters);
	
	Serializer = XdtoSerializerWithTypeAnnotation();
	
	Handlers = DataProcessors.ExportImportDataDataExportHandlersManager.Create();
	Handlers.Initialize(Container);
	
	Handlers.BeforeExportData(Container);
	
	SaveUploadDescription(Container);
	
	DataProcessors.ExportImportDataInfobaseDataExportManager.UploadDatabaseData(
		Container, Handlers, Serializer);
	
	If ExportingParameters.UnloadUsers Then
		
		ExportImportInfobaseUsers.UnloadUsersOfInformationBase(Container);
		
		If ExportingParameters.ExportUserSettings Then
			
			DataProcessors.ExportImportDataUserSettingsExportManager.UploadInformationDatabaseUserSettings(
				Container, Handlers, Serializer);
			
		EndIf;
		
	EndIf;
	
	UnloadConfigurationDiagram(Container, ExportingParameters);
	
	Handlers.AfterExportData(Container);
	
	Return New Structure("FileName, Warnings",
		Container.FinalizeUpload(),
		Container.Warnings());
	
EndFunction

// Imports data from the directory.
//
// Parameters:
//	FileData - String, UUID, Structure - Filename, file ID, or file data retrieved from the file using ZIPArchives.ReadArchive().
//	ImportParameters - See ExportImportData.DownloadCurAreaDataFromArchive.ImportParameters.
//
// Returns:
//  Structure:
//  * Warnings - Array of String - User notifications following the import.
//
Function DownloadCurAreaDataFromArchive(Val FileData, Val ImportParameters) Export
	
	DataSeparationEnabled = Common.DataSeparationEnabled();

	SkipExtensionsRestoring = ImportParameters.Property("SkipExtensionsRestoring") 
		And ImportParameters.SkipExtensionsRestoring;

	HashSumOfSource = HashSumOfSource(ReadArchive(FileData));
	ImportParameters.Insert("HashSumOfSource", HashSumOfSource);
	
	HashSumOfParameters = HashSumOfParameters(ImportParameters);
	ImportParameters.Insert("HashSumOfParameters", HashSumOfParameters);
	
	ItIsPossibleToContinueLoadingProcedure = ItIsPossibleToContinueLoadingProcedure(
		HashSumOfSource,
		HashSumOfParameters);	
	ImportParameters.Insert("ItIsPossibleToContinueLoadingProcedure", ItIsPossibleToContinueLoadingProcedure);
		
	If Not (ItIsPossibleToContinueLoadingProcedure Or IsDifferentialBackup(ImportParameters)) Then
			
		If DataSeparationEnabled Then
						
			SaaSOperations.ClearAreaData();
		
		Else
				
			SaaSOperations.ClearInformationDatabaseData(
				Not SkipExtensionsRestoring);
							
		EndIf;
	
		If Not SkipExtensionsRestoring Then
			
			ExtensionData_ = Undefined;
			ImportParameters.Property("ExtensionData_", ExtensionData_);
			
			If ValueIsFilled(ExtensionData_) Then
				
				If DataSeparationEnabled Then
					RestoreAreaExtensions(ExtensionData_);
				Else
					RestoreInformationBaseExtensions(ExtensionData_);
				EndIf;
				
			EndIf;
			
		EndIf;
			
	EndIf;	
		
	If Not SkipExtensionsRestoring 
		And ExtensionsSaaS.ThereAreInstalledExtensionsModifyingDataStructure() Then
		ImportResult1 = LoadCurAreaDataFromArchiveInBackground(FileData, ImportParameters);	
	Else
		ImportResult1 = StartLoadingCurAreaDataFromArchive(FileData, ImportParameters);
	EndIf;
	
	Return ImportResult1;

EndFunction

Procedure RestoreInformationBaseExtensions(ExtensionData_) Export
			
	RecoveryExtensions = Undefined;	
	
	If ExtensionData_.Property("RecoveryExtensions", RecoveryExtensions) Then
		
		RestoreExtensions(RecoveryExtensions);
			
	EndIf;
	
	ExtensionsFrameForRecovery = Undefined;
	
	If ExtensionData_.Property("ExtensionsFrameForRecovery", ExtensionsFrameForRecovery)  Then
		
		RestoreExtensionFrames(ExtensionsFrameForRecovery);
		
	EndIf;
		
EndProcedure

// Compares whether export data is compatible with the current configuration.
//
// Parameters:
//	UploadInformation - XDTODataObject - see the SaveExportDetails procedure.
//
// Returns:
//	Boolean - True if the types match.
//
Function UploadingToArchiveIsCompatibleWithCurConfiguration(Val UploadInformation) Export
	
	Return UploadInformation.Configuration.Name = Metadata.Name;
	
EndFunction

// Compares whether configuration version is compatible with the exported one.
//
// Parameters:
//	UploadInformation - XDTODataObject - see the SaveExportDetails procedure.
//
// Returns:
//	Boolean - True if the types match.
//
Function UploadingToArchiveIsCompatibleWithCurVersionOfConfiguration(Val UploadInformation) Export
	
	Return UploadInformation.Configuration.Version = Metadata.Version;
	
EndFunction

// Compares whether export data is compatible with the current configuration.
//
// Parameters:
//	UploadInformation - XDTODataObject - see the SaveExportDetails procedure.
//
Procedure CheckIfUploadingToArchiveIsCompatibleWithCurConfiguration(UploadInformation) Export
	
	If Not UploadingToArchiveIsCompatibleWithCurConfiguration(UploadInformation) Then
		
		Raise StrTemplate(NStr("ru = 'Невозможно загрузить данные из файла, т.к. файл был выгружен из другой конфигурации (файл выгружен из конфигурации %1 и не может быть загружен в конфигурацию %2)';
										|en = 'Cannot import data from a file as the file was exported from another configuration (the file is exported from configuration %1 and cannot be imported to configuration%2)';"),
			UploadInformation.Configuration.Name,
			Metadata.Name);
		
	EndIf;
	
EndProcedure

// Compares whether configuration version is compatible with the exported one.
//
// Parameters:
//	UploadInformation - XDTODataObject - see the SaveExportDetails procedure.
//  StrictVerification - Boolean - If True, checks for equality. If False, the export versions must be earlier than or equal to the current version.
//
Procedure CheckIfUploadingToArchiveIsCompatibleWithCurVersionOfConfiguration(Val UploadInformation, Val StrictVerification = False) Export
	
	UnloadingIsCompatible = False;
	If StrictVerification Then
		UnloadingIsCompatible = UploadInformation.Configuration.Version = Metadata.Version
	Else
		UnloadingIsCompatible = CommonClientServer.CompareVersions(UploadInformation.Configuration.Version, Metadata.Version) <= 0;
	EndIf;
	
	If Not UnloadingIsCompatible Then
		
		Raise StrTemplate(NStr("ru = 'Невозможно загрузить данные из файла, т.к. файл был выгружен из другой версии конфигурации (файл выгружен из конфигурации версии %1 и не может быть загружен в конфигурацию версии %2)';
										|en = 'Cannot import data from a file as the file was exported from another configuration version (the file is exported from configuration version %1 and cannot be imported to configuration version %2)';"),
			UploadInformation.Configuration.Version,
			Metadata.Version);
		
	EndIf;
	
EndProcedure

// Data type of a file, in which the column name is stored with the source reference.
//
// Returns:
//	String - type name.
//
Function DataTypeForColumnNameOfValueTable() Export
	
	Return "1cfresh\ReferenceMapping\ValueTableColumnName";
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// File types and structure of import and export directories.

// Returns file type description with export information.
// Returns:
//  String - type name.
Function DumpInfo() Export
	Return "DumpInfo";
EndFunction

// Returns file type description with information on export composition.
// Returns:
//  String - type name.
Function PackageContents() Export
	Return "PackageContents";
EndFunction

// Returns file type description with information on mapping references.
// Returns:
//  String - type name.
Function ReferenceMapping() Export
	Return "ReferenceMapping";
EndFunction

// Returns file type description with information on reference recreation.
// Returns:
//  String - type name.
Function ReferenceRebuilding() Export
	Return "ReferenceRebuilding";
EndFunction

// Returns description of the file type that stores infobase serialized data.
// Returns:
//  String - type name.
Function InfobaseData() Export
	Return "InfobaseData";
EndFunction

// Returns the name of the file type that stores serialized infobase data changes.
// Returns:
//  String - Type name.
Function InfobaseDataChanges() Export
	Return "InfobaseDataChanges";
EndFunction

// Returns description of the file type that stores serialized data of sequence borders.
// Returns:
//	String - type name.
Function SequenceBoundary() Export
	Return "SequenceBoundary";
EndFunction

// Returns description of the file type that stores serialized data of user settings.
// Returns:
//	String - type name.
Function UserSettings() Export
	Return "UserSettings";
EndFunction

// Returns description of the file type that stores user serialized data.
// Returns:
//	String - type name.
Function Users() Export
	Return "Users";
EndFunction

// Returns description of the file type that stores arbitrary data.
// Returns:
//	String - type name.
Function CustomData() Export
	Return "CustomData";
EndFunction

// The function generates directory structure rules in the export.
//
// Returns:
//	FixedStructure - Directory structure.:
//	 * DumpInfo - String
//	 * Digest - String
//	 * Extensions - String
//	 * CustomExtensions - String
//	 * DumpWarnings - String
//	 * PackageContents - String
//	 * ReferenceMapping - String
//	 * ReferenceRebuilding - String
//	 * InfobaseData - String
//	 * SequenceBoundary - String
//	 * Users - String
//	 * UserSettings - String
//	 * CustomData - String
Function RulesForCreatingDirectoryStructure() Export
	
	RootDirectory1 = "";
	DataDirectory = "Data";
	
	Result = New Structure();
	Result.Insert(DumpInfo(), RootDirectory1);
	Result.Insert(Digest(), RootDirectory1);
	Result.Insert(Extensions(), RootDirectory1);
	Result.Insert(CustomExtensions(), RootDirectory1);
	Result.Insert(DumpWarnings(), RootDirectory1);
	Result.Insert(PackageContents(), RootDirectory1);
	Result.Insert(ReferenceMapping(), ReferenceMapping());
	Result.Insert(ReferenceRebuilding(), ReferenceRebuilding());
	Result.Insert(InfobaseData(), DataDirectory);
	Result.Insert(SequenceBoundary(), DataDirectory);
	Result.Insert(Users(), RootDirectory1);
	Result.Insert(UserSettings(), UserSettings());
	Result.Insert(CustomData(), CustomData());
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns types of files that support reference replacement.
//
// Returns:
//	Array of String - an array of file types.
//
Function FileTypesThatSupportLinkReplacement() Export
	
	Result = New Array();
	
	Result.Add(InfobaseData());
	Result.Add(SequenceBoundary());
	Result.Add(UserSettings());
	
	Return Result;
	
EndFunction

// Returns a name of the type that will be used in an xml file for the specified metadata object.
// Used for reference search and replacement upon import, and for current-config schema editing upon writing.
// 
// Parameters:
//  Value - CatalogRef, DocumentRef, MetadataObject - Metadata object or Ref.
//
// Returns:
//  String - a string that describes a metadata object (in format similar to AccountingRegisterRecordSet.SelfFinancing).
//
Function XMLRefType(Val Value) Export
	
	If TypeOf(Value) = Type("MetadataObject") Then
		MetadataObject = Value;
		ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
		Ref = ObjectManager.GetRef();
	Else
		MetadataObject = Value.Metadata();
		Ref = Value;
	EndIf;
	
	If CommonCTL.IsRefData(MetadataObject) Then
		
		Return XDTOSerializer.XMLTypeOf(Ref).TypeName;
		
	Else
		
		Raise StrTemplate(NStr("ru = 'Ошибка при определении XML типа ссылки для объекта %1: объект не является ссылочным';
										|en = 'An error occurred when determining an XML reference type for the %1 object: this is not a reference object';"),
			MetadataObject.FullName());
		
	EndIf;
	
EndFunction

// Returns a metadata object by a field type.
//
// Parameters:
//	FieldType - Type - a field type
//
// Returns:
//	MetadataObject - a metadata object.
//
Function MetadataObjectByRefType(Val FieldType) Export
	
	BusinessProcessesRoutePointsRefs = BusinessProcessesRoutePointsRefs();
	
	BusinessProcess = BusinessProcessesRoutePointsRefs.Get(FieldType);
	If BusinessProcess = Undefined Then
		Ref = New(FieldType);
		RefMetadata = Ref.Metadata();
	Else
		RefMetadata = BusinessProcess;
	EndIf;
	
	Return RefMetadata;
	
EndFunction

// Returns a full list of configuration constants
//
// Returns:
//  Array of MetadataObject - metadata objects.
//
Function AllConstants() Export
	
	ObjectsMetadata = New Array;
	FillCollectionsOfConstants(ObjectsMetadata);
	Return AllCollectionMetadata(ObjectsMetadata);
	
EndFunction

// Returns a full list of configuration reference types
//
// Returns:
//  Array of MetadataObject
//
Function AllReferenceData() Export
	
	ObjectsMetadata = New Array;
	PopulateCollectionsOfReferenceObjects(ObjectsMetadata);
	Return AllCollectionMetadata(ObjectsMetadata);
	
EndFunction

// Returns a full list of configuration record sets
//
// Returns:
//  Array of MetadataObject
//
Function AllRecordSets() Export
	
	ObjectsMetadata = New Array;
	PopulateRecordsetCollections(ObjectsMetadata);
	Return AllCollectionMetadata(ObjectsMetadata);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Data writing and reading.

// Writes an object to write stream.
//
// Parameters:
//	Object - Arbitrary - Object being written.
//	WriteStream - XMLWriter - a write stream.
//	Serializer - XDTOSerializer - Serializer.
//
Procedure WriteObjectToStream(Val Object, WriteStream, Serializer = Undefined) Export
	
	If Serializer = Undefined Then
		Serializer = XDTOSerializer;
	EndIf;
	
	WriteStream.WriteStartElement(NameOfElementContainingObject());
	
	NamespacesPrefixes = NamespacesPrefixes();
	For Each NamespacesPrefix In NamespacesPrefixes Do
		WriteStream.WriteNamespaceMapping(NamespacesPrefix.Value, NamespacesPrefix.Key);
	EndDo;
	
	Serializer.WriteXML(WriteStream, Object, XMLTypeAssignment.Explicit);
	
	WriteStream.WriteEndElement();
	
EndProcedure

// Returns an object from file.
//
// Parameters:
//	ReaderStream - XMLReader - a reader stream.
//
// Returns:
//	Arbitrary - read object.
//
Function ReadObjectFromStream(ReaderStream) Export
	
	If ReaderStream.NodeType <> XMLNodeType.StartElement
			Or ReaderStream.Name <> NameOfElementContainingObject() Then
		
		Raise StrTemplate(NStr("ru = 'Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента %1.';
										|en = 'XML reading error. Invalid file format. Start of ""%1"" element is expected.';"),
			NameOfElementContainingObject());
		
	EndIf;
	
	If Not ReaderStream.Read() Then
		Raise NStr("ru = 'Ошибка чтения XML. Обнаружено завершение файла.';
								|en = 'XML reading error. File end is detected.';");
	EndIf;
	
	Object = XDTOSerializer.ReadXML(ReaderStream);
	
	Return Object;
	
EndFunction

// Reads XDTODataObject from the file.
//
// Parameters:
//	FileName - String - full path to the file.
//	XDTOType - XDTOObjectType - an XDTO object type.
//
// Returns:
//	XDTODataObject - read object.
//
Function ReadXDTOObjectFromFile(Val FileName, Val XDTOType) Export
	
	ReaderStream = New XMLReader();
	ReaderStream.OpenFile(FileName);
	ReaderStream.MoveToContent();
	
	If ReaderStream.NodeType <> XMLNodeType.StartElement
			Or ReaderStream.Name <> NameOfElementContainingXDTOObject() Then
		
		Raise StrTemplate(NStr("ru = 'Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента %1.';
										|en = 'XML reading error. Invalid file format. Start of ""%1"" element is expected.';"),
			NameOfElementContainingXDTOObject());
		
	EndIf;
	
	If Not ReaderStream.Read() Then
		Raise NStr("ru = 'Ошибка чтения XML. Обнаружено завершение файла.';
								|en = 'XML reading error. File end is detected.';");
	EndIf;
	
	XDTODataObject = XDTOFactory.ReadXML(ReaderStream, XDTOType);
	
	ReaderStream.Close();
	
	Return XDTODataObject;
	
EndFunction

// Returns prefixes to frequently used namespaces.
//
// Returns:
//	Map of KeyAndValue:
//	* Key - String - a namespace.
//	* Value - String - prefix.
//
Function NamespacesPrefixes() Export
	
	Result = New Map();
	
	Result.Insert("http://www.w3.org/2001/XMLSchema", "xs");
	Result.Insert("http://www.w3.org/2001/XMLSchema-instance", "xsi");
	Result.Insert("http://v8.1c.ru/8.1/data/core", "v8");
	Result.Insert("http://v8.1c.ru/8.1/data/enterprise", "ns");
	Result.Insert("http://v8.1c.ru/8.1/data/enterprise/current-config", "cc");
	Result.Insert("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "dmp");
	
	Return New FixedMap(Result);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Miscellaneous.

// Returns a settings record template.
// 
// Returns:
// 	Structure:
// * Settings - ValueStorage
// * SerializationViaValueStorage - Boolean
// * Presentation - String
// * User - String
// * ObjectKey - String
// * SettingsKey - String
Function NewSettingsEntry() Export

	RecordingSettings = New Structure();
	RecordingSettings.Insert("SettingsKey", "");
	RecordingSettings.Insert("ObjectKey", "");
	RecordingSettings.Insert("User", "");
	RecordingSettings.Insert("Presentation", "");
	RecordingSettings.Insert("SerializationViaValueStorage", False);
	RecordingSettings.Insert("Settings", New ValueStorage(Undefined));

	Return RecordingSettings;
	
EndFunction

// Standard storage settings types.
// 
// Returns: 
//  FixedArray of String
Function TypesOfStandardSettingsRepositories() Export
	
	Result = New Array();
	
	Result.Add("CommonSettingsStorage");
	Result.Add("SystemSettingsStorage");
	Result.Add("ReportsUserSettingsStorage");
	Result.Add("ReportsVariantsStorage");
	Result.Add("FormDataSettingsStorage");
	Result.Add("DynamicListsUserSettingsStorage");
	
	Return New FixedArray(Result);
	
EndFunction

// Import is aborted.
// 
// Returns:
//  Boolean
Function DownloadAborted() Export
	Return InformationAboutImportProcedure() <> Undefined;
EndFunction

Procedure FixLinkMatching(RefsMap) Export
	InformationAboutImportProcedure =  InformationAboutImportProcedure();
	InformationAboutImportProcedure.RefsMap = RefsMap; 
	RecordInformationAboutBootProcedure(InformationAboutImportProcedure);
EndProcedure

// Parameters:
//	MetadataObjects - Array of MetadataObject
//	
// Returns: 
//	See ExportImportDataInternal.ReferencesToTypes
//
Function ReferencesToMetadataObjects(MetadataObjects) Export
		
	AllReferenceData = AllReferenceData();
	
	Types = New Array;
	
	For Each MetadataObject In MetadataObjects Do
		If AllReferenceData.Find(MetadataObject) = Undefined Then
			Continue;
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(
			MetadataObject.FullName());
		Type = TypeOf(ObjectManager.EmptyRef());
		
		Types.Add(Type);
			
	EndDo;
	
	Return ReferencesToTypes(Types);
	
EndFunction

// Parameters:
//	Types - Array of Type
//	
// Returns: 
//	FixedMap of KeyAndValue:
//	 * Key - String - Metadata object name.
//	 * Value - Array Из Структура
//
Function ReferencesToTypes(Types) Export
				
	MetadataList = New Map;
	For Each ObjectMetadata In AllConstants() Do
		AddConstantToMetadataList(ObjectMetadata, MetadataList, Types);
	EndDo;
	
	For Each ObjectMetadata In AllReferenceData() Do
		AddReferenceTypeToMetadataList(ObjectMetadata, MetadataList, Types);
	EndDo;
	
	For Each ObjectMetadata In AllRecordSets() Do
		AddRegisterToMetadataTable(ObjectMetadata, MetadataList, Types);
	EndDo;
	
	Return New FixedMap(MetadataList);
	
EndFunction

Function ReadArchive(ArchiveData) Export
	
	ArchiveDataType = TypeOf(ArchiveData);
	
	If ArchiveDataType = Type("Structure") Then
		
		If ArchiveData.Property("IDOfSourceFile") Then
			FullArchiveFileName_ = ExportImportDataAreas.FullArchiveFileName_();
			CopyArchive = ZipArchives.ReadArchive(ArchiveData.IDOfSourceFile);
			Archive = ZipArchives.ReadAttachedUncompressedArchive(CopyArchive, FullArchiveFileName_);
		Else
			Archive = ArchiveData;
		EndIf;
		
	ElsIf ArchiveDataType = Type("UUID") Then
		Archive = ZipArchives.ReadArchive(ArchiveData);
	Else
		Archive = ZipArchives.ReadArchive(FileStreams.OpenForRead(ArchiveData));
	EndIf;
	
	Return Archive;
	
EndFunction

Procedure UnzipArchiveFile(Val Archive, Val TargetDirectory, Val Name, Val Path = "") Export
	
	If Not IsBlankString(Path) Then
		Path = Path + "/";
	EndIf;
	
	FileNameInArchive = ?(IsBlankString(Path), Name, Path + Name);
		
	If Not ZipArchives.ExtractFile(Archive, FileNameInArchive, TargetDirectory) Then
		Raise StrTemplate(NStr("ru = 'Файл %1 не найден';
										|en = 'File %1 is not found';"), FileNameInArchive);
	EndIf;
	
EndProcedure

Function GetFileName(Val FileKind, Val Extension = "xml", Val DataType = Undefined) Export
	
	If FileKind = DumpInfo() Then
		FileName = DumpInfo();
	ElsIf FileKind = Digest() Then
		FileName = Digest();
	ElsIf FileKind = Extensions() Then
		FileName = Extensions();	
	ElsIf FileKind = CustomExtensions() Then
		FileName = CustomExtensions();
	ElsIf FileKind = DumpWarnings() Then
		FileName = DumpWarnings();	
	ElsIf FileKind = PackageContents() Then
		FileName = PackageContents();
	ElsIf FileKind = Users() Then
		FileName = Users();
	ElsIf FileKind = PredefinedDataDuplicates() Then
		FileName = PredefinedDataDuplicates();
	Else
		FileName = String(New UUID);
	EndIf;
	
	For CharacterNumber = 1 To StrLen(Extension) Do
		Char = CharCode(Extension, CharacterNumber);
		// Only Latin letters and digits. See standard 542, item 3.1.
		If Not (Char >= 48 And Char <= 57)
			And Not (Char >= 65 And Char <= 90)
			And Not (Char >= 97 And Char <= 122) Then
			Extension = "bin";
			Break;
		EndIf;
	EndDo;
	
	If Extension <> "" Then
		
		FileName = FileName + "." + Extension;
		
	EndIf;
	
	Return FileName;
	
EndFunction

Function NumberOfImportObjectsByMetadataObjects(Content, LoadableTypes, ForTechnicalSupport) Export
	
	ImportingObjectsCountTable = NewTableOfNumberOfProcessedObjects();
	
	ImportingTypesFullNames = FullTypeNames(LoadableTypes);
	
	FullNamesOfExcludedTypes = FullTypeNames(
		TypesToExclude(ForTechnicalSupport));
	
	IBDataFileType = InfobaseData();		
	For Each CompositionRow In Content Do 
		
		DataType = CompositionRow.DataType;
		
		If CompositionRow.FileKind <> IBDataFileType
			Or ImportingTypesFullNames.Get(DataType) = Undefined
			Or FullNamesOfExcludedTypes.Get(DataType) <> Undefined Then
			Continue;
		EndIf;
		
		ImportingObjectString = ImportingObjectsCountTable.Add();
		ImportingObjectString.FullName = DataType;
		ImportingObjectString.NumberOfObjects = CompositionRow.NumberOfObjects;
	
	EndDo;
		
	ImportingObjectsCountTable.GroupBy("FullName", "NumberOfObjects");
	
	Return ImportingObjectsCountTable;
	
EndFunction

Function NumberOfBackupObjectsToImport(Archive, BackupType, ForTechnicalSupport) Export
	
	TempDirectory = GetTempFileName();
	
	NameOfContentFile = GetFileName(PackageContents()); 
	
	UnzipArchiveFile(
		ReadArchive(Archive),
		TempDirectory,
		NameOfContentFile);
	
	ArchiveContent = ArchiveContent(
		TempDirectory + GetPathSeparator() + NameOfContentFile);
	
	DeleteFiles(TempDirectory);
	
	LoadableTypes = LoadableTypes(BackupType);
	
	NumberOfImportObjectsByMetadataObjects = NumberOfImportObjectsByMetadataObjects(
		ArchiveContent,
		LoadableTypes,
		ForTechnicalSupport);
		
	Return NumberOfImportObjectsByMetadataObjects.Total("NumberOfObjects"); 
	
EndFunction

Function ImportObjectsdByMetadataObjectsCount(TypesToExport, UnloadedTypesOfSharedData, ForTechnicalSupport) Export
	
	ExportingObjectsCountTable = NewTableOfNumberOfProcessedObjects();
				
	SubqueryTemplate = "SELECT
		|	 ""%1"" AS FullName,
		|	 %2 AS NumberOfObjects
		|FROM
		|	%3";
				
	Subqueries = New Array; 
	
	UniqueExportingTypes = New Array;
	CommonClientServer.SupplementArray(UniqueExportingTypes, TypesToExport);
	CommonClientServer.SupplementArray(UniqueExportingTypes, UnloadedTypesOfSharedData);
	UniqueExportingTypes = CommonClientServer.CollapseArray(UniqueExportingTypes);
		
	FullNamesOfExcludedTypes = FullTypeNames(
		TypesToExclude(ForTechnicalSupport));

	For Each ToExportType In UniqueExportingTypes Do   
			
		FullNameOfExportingType = ToExportType.FullName();
				
		If FullNamesOfExcludedTypes.Get(FullNameOfExportingType) <> Undefined Then
			Continue;
		EndIf;
		
		If CommonCTL.IsConstant(ToExportType) Then
			StringConsts = ExportingObjectsCountTable.Add();
			StringConsts.FullName = FullNameOfExportingType;
			StringConsts.NumberOfObjects = 1;
			Continue; 
		EndIf;
		
		If CommonCTL.IsRefData(ToExportType) 
			Or CommonCTL.IsIndependentRecordSet(ToExportType) Then		
			
			QuantityCalculationExpression = "Count(*)";
			TableName = ToExportType.FullName();
		
		ElsIf CommonCTL.IsRecordSet(ToExportType) Then 
			
			If CommonCTL.IsRecalculationRecordSet(ToExportType) Then
				
				QuantityCalculationExpression = "Count(Distinct RecalculationObject)";
				
				Substrings = StrSplit(ToExportType.FullName(), ".");
				TableName = Substrings[0] + "." + Substrings[1] + "." + Substrings[3];
				
			Else
				
				QuantityCalculationExpression = "Count(Distinct Recorder)";
				TableName = ToExportType.FullName();
				
			EndIf;
						
		Else
			Raise StrTemplate(NStr("ru = 'Объект метаданных не поддерживается: %1';
											|en = 'The metadata object is not supported: %1';"),
				ToExportType.FullName());		
		EndIf;     
		
		Subqueries.Add(
				StrTemplate(SubqueryTemplate, FullNameOfExportingType, QuantityCalculationExpression, TableName));
	
		If Subqueries.Count() >= 100 Then
			AddTableOfProcessedObjectsNumber(
				ExportingObjectsCountTable,
				TableOfNumberOfExportedObjectsBySubqueries(Subqueries));
			Subqueries.Clear();			
		EndIf;
		
	EndDo; 
	
	If ValueIsFilled(Subqueries) Then
		AddTableOfProcessedObjectsNumber(
			ExportingObjectsCountTable,
			TableOfNumberOfExportedObjectsBySubqueries(Subqueries));			
	EndIf;
		
	Return ExportingObjectsCountTable;
		
EndFunction

Function IsDifferentialBackup(ImportParameters) Export
	
	Return BackupType(ImportParameters) = BackupTypeDifferential();
	
EndFunction

Function IsFullBackup(ImportParameters) Export
	
	Return BackupType(ImportParameters) = BackupTypeFull();
	
EndFunction

Function BackupTypeDifferential() Export
	
	Return "Differential";
	
EndFunction

Function BackupTypeFull() Export
	
	Return "Full";
	
EndFunction

Function BackupTypeNormal() Export
	
	Return "Ordinary";
	
EndFunction

// Get file data from the archive.
// 
// Parameters:
//  Content - See ArchiveContent
//  SearchParameters - See NewFileFromArchiveSearchParameters
// 
// Returns:
//  ValueTableRow - File parameters.:
// * Name - String
// * Directory - String
// * Size - Number
// * FileKind - String
// * NumberOfObjects - Number
// * DataType - String
Function GetFileParametersFromArchive(Content, SearchParameters) Export
	
	FilterParameters = New Structure();
	
	For Each SearchParameter In SearchParameters Do
		
		If ValueIsFilled(SearchParameter.Value) Then
			FilterParameters.Insert(SearchParameter.Key, SearchParameter.Value);
		EndIf;
		
	EndDo;
	
	If Not ValueIsFilled(FilterParameters) Then
		Raise NStr("ru = 'Неверные параметры поиска файла состава архива';
								|en = 'Incorrect archive file search parameters';");
	EndIf;
	
	FoundRows = Content.FindRows(FilterParameters);
	FilesCount = FoundRows.Count();
	
	If FilesCount = 0 Then
		Raise NStr("ru = 'В составе архива не найден искомый файл';
								|en = 'The required file is not found in the archive';");
	ElsIf FilesCount > 1 Then
		 Raise NStr("ru = 'В составе архива найдено несколько искомых файлов';
								|en = 'Multiple required files are found in the archive';");
	EndIf;
	
	FileParameters = FoundRows[0]; // ValueTableRow
	
	Return FileParameters;
	
EndFunction

// Archive composition.
// 
// Parameters:
//  CompositionFilePath - String - Composition file path.
// 
// Returns:
//  See NewContent
Function ArchiveContent(CompositionFilePath) Export
	
	ReaderStream = New XMLReader();
	ReaderStream.OpenFile(CompositionFilePath);
	ReaderStream.MoveToContent();
	
	If ReaderStream.NodeType <> XMLNodeType.StartElement
			Or ReaderStream.Name <> "Data" Then
		
		Raise StrTemplate(NStr("ru = 'Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента %1.';
										|en = 'XML reading error. Invalid file format. Start of ""%1"" element is expected.';"),
			"Data");
		
	EndIf;
	
	If Not ReaderStream.Read() Then
		Raise NStr("ru = 'Ошибка чтения XML. Обнаружено завершение файла.';
								|en = 'XML reading error. File end is detected.';");
	EndIf;
	
	ArchiveContent = NewContent();
	
	While ReaderStream.NodeType = XMLNodeType.StartElement Do
		
		ContainerElement = XDTOFactory.ReadXML(
			ReaderStream,
			XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "File"));
			
		File = ArchiveContent.Add();
		File.Name = ContainerElement.Name;
		File.Directory = ContainerElement.Directory;
		File.Size = ContainerElement.Size;
		File.FileKind = ContainerElement.Type;
		File.NumberOfObjects = ContainerElement.Count;
		File.DataType = ContainerElement.DataType;
		
	EndDo;
	
	ReaderStream.Close();	
			
	Return ArchiveContent;
	
EndFunction

// New composition.
// 
// Returns:
//  ValueTable - New composition.:
// * Name - String
// * Directory - String
// * Size - Number
// * FileKind - String
// * NumberOfObjects - Number
// * DataType - String
Function NewContent() Export
	
	TypesDetailsString = New TypeDescription("String");
	TypesDetailsNumber = New TypeDescription("Number");
	
	NewContent = New ValueTable;
	NewContent.Columns.Add("Name", TypesDetailsString);
	NewContent.Columns.Add("Directory", TypesDetailsString);
	NewContent.Columns.Add("Size", TypesDetailsNumber);
	NewContent.Columns.Add("FileKind", TypesDetailsString);
	NewContent.Columns.Add("NumberOfObjects", TypesDetailsNumber);
	NewContent.Columns.Add("DataType", TypesDetailsString);
	
	Return NewContent;
	
EndFunction

// New archive file search parameters.
// 
// Returns:
//  Structure - New archive file search parameters.:
// * Name - String
// * Directory - String
// * FileKind - String
// * DataType - String
Function NewFileFromArchiveSearchParameters() Export
	
	SearchParameters = New Structure();
	SearchParameters.Insert("Name", "");
	SearchParameters.Insert("Directory", "");
	SearchParameters.Insert("FileKind", "");
	SearchParameters.Insert("DataType", "");
	
	Return SearchParameters;
	
EndFunction

Function LoadableTypes(BackupType) Export
	
	LoadableTypes = New Array();
	CommonClientServer.SupplementArray(
		LoadableTypes,
		ExportImportDataAreas.GetAreaDataModelTypes());
	
	If Not SaaSOperationsCached.DataSeparationEnabled() Then
		CommonClientServer.SupplementArray(
			LoadableTypes, 
			ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading(),
			True);
	EndIf;
		
	If BackupType = BackupTypeFull() Then
		For ReverseIndex = 1 - LoadableTypes.Count() To 0 Do
			MetadataObject = LoadableTypes[-ReverseIndex];
			If Metadata.ExchangePlans.Contains(MetadataObject)
				Or MetadataObject.ConfigurationExtension() <> Undefined Then
				LoadableTypes.Delete(-ReverseIndex);
			EndIf;
		EndDo;
	EndIf;
	
	Return LoadableTypes;
	
EndFunction

Function TypesToExclude(ForTechnicalSupport) Export
	TypesToExclude = New Array;
	CommonClientServer.SupplementArray(
 		TypesToExclude,
 		ExportImportDataInternalEvents.GetTypesExcludedFromUploadUpload());
 	If ForTechnicalSupport Then
 		CommonClientServer.SupplementArray(
 			TypesToExclude,
 			DataAreasExportForTechnicalSupportCached.MetadataExcludedFromUploadingInTechnicalSupportMode(),
 			True);
 	EndIf;
 	Return TypesToExclude;
EndFunction

Function FullTypeNames(Types) Export
	FullTypeNames = New Map();
	For Each Type In Types Do
		FullTypeNames.Insert(Type.FullName(), True);
	EndDo;
	Return FullTypeNames;
EndFunction

Function ExportForTechnicalSupportMode(PathToDigestFile) Export
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(PathToDigestFile);
	
	DOMBuilder = New DOMBuilder;
	UploadDigest = DOMBuilder.Read(XMLReader);
	
	XMLReader.Close();
	
	If UploadDigest <> Undefined Then
		ItemsList = UploadDigest.GetElementByTagName("DataDumpType");
		UploadingForTechnicalSupport = ValueIsFilled(ItemsList) And ItemsList[0].TextContent = "TechnicalSupport";	
	Else
		UploadingForTechnicalSupport = False;
	EndIf;
	
	Return UploadingForTechnicalSupport;

EndFunction  

// Returns XDTOSerializer with type annotation.
//
// Returns:
//	XDTOSerializer - serializer.
//
Function XdtoSerializerWithTypeAnnotation() Export
	
	SchemaBinaryData = ConfigurationSchema.SchemaBinaryData(True, True);
	XMLSchema = XMLSchema(SchemaBinaryData);	
	Factory = FactoryByScheme(XMLSchema);	
	Return New XDTOSerializer(Factory);
	
EndFunction

// Availability of handlers by metadata objects.
// 
// Parameters:
//  CurHandlers - ValueTable - Current handlers.
//  HandlerColumnsNames - Array of String -  Handler column names.
// 
// Returns:
//  Map of MetadataObject: Структура - Availability of handlers by metadata objects.
Function MetadataObjectsHandlersAvailability(CurHandlers, HandlerColumnsNames) Export
	
	HandlersAvailability = New Map();
	
	For Each TableRow In CurHandlers Do
		
		ObjectHandlersAvailability = HandlersAvailability.Get(TableRow.MetadataObject);
		
		If ObjectHandlersAvailability = Undefined Then
			ObjectHandlersAvailability = NewMetadataObjectHandlersAvailabilityData(HandlerColumnsNames);
			HandlersAvailability.Insert(TableRow.MetadataObject, ObjectHandlersAvailability);
		EndIf;
		
		For Each HandlerName In HandlerColumnsNames Do
			ObjectHandlersAvailability[HandlerName] = Max(
				ObjectHandlersAvailability[HandlerName], TableRow[HandlerName]);
		EndDo;
		
	EndDo;
	
	Return HandlersAvailability;
	
EndFunction

// New data on the availability of handlers by a metadata object.
// 
// Parameters:
//  HandlerColumnsNames - Array of String - Handler column names.
// 
// Returns:
//  Structure - New data on the availability of handlers by a metadata object.
Function NewMetadataObjectHandlersAvailabilityData(HandlerColumnsNames) Export
	
	HandlersAvailability = New Structure();
	
	For Each ColumnName In HandlerColumnsNames Do
		HandlersAvailability.Insert(ColumnName, False);
	EndDo;
	
	Return HandlersAvailability;
	
EndFunction

#Region ParallelExportImport

// Parameters of parallel data import.
// 
// Returns:
//  Structure - Parameters of parallel data import.:
// * UsageAvailable - Boolean -
// * ThreadsCount - Number -
Function ParallelDataExportImportParameters() Export
	
	UsageAvailable = Not Common.DataSeparationEnabled()
		And Not Common.FileInfobase();
	
	Parameters = New Structure();
	Parameters.Insert("UsageAvailable", UsageAvailable);
	Parameters.Insert("ThreadsCount", 4);
	
	Return Parameters;
	
EndFunction

Function UseMultithreading(ExportImportParameters) Export
	
	ThreadsCount = 0;
	
	If ExportImportParameters.Property("ThreadsCount") Then
		ThreadsCount = ExportImportParameters.ThreadsCount;
	EndIf;
	
	Return ValueIsFilled(ThreadsCount) And ThreadsCount > 1;
	
EndFunction

// Runs streams of data export and import.
// 
// Parameters:
//  ThreadsParameters - See NewExportImportDataThreadsParameters
// 
// Returns:
//  Array of BackgroundJob - Launched background jobs.
Function StartDataExportImportThreads(ThreadsParameters) Export
	
	If Not ValueIsFilled(ThreadsParameters.ThreadsCount) Then
		Raise NStr("ru = 'Некорректные параметры потоков, не указано количество потоков.';
								|en = 'Incorrect thread parameters. The number of threads is not specified.';");
	EndIf;
	
	If ThreadsParameters.IsExport Then
		KeyTemplate = "ExportInfoBaseData_Thread_%1";
		DescriptionTemplate = NStr("ru = 'Выгрузка данных информационной базы (поток: %1)';
									|en = 'Export infobase data (thread: %1)';");
	ElsIf ThreadsParameters.ThisIsDownload Then
		KeyTemplate = "ImportInfoBaseData_Thread_%1";
		DescriptionTemplate = NStr("ru = 'Загрузка данных информационной базы (поток: %1)';
									|en = 'Import infobase data (thread: %1)';");
	Else
		Raise NStr("ru = 'Некорректные параметры потоков, не указан признак выгрузки или загрузки.';
								|en = 'Incorrect thread parameters. An export or import flag is not selected.';");
	EndIf;
	
	JobParameters = New Array();
	JobParameters.Add(ThreadsParameters);
	
	Jobs = New Array();
	
	For ThreadNumber = ThreadsParameters.InitialThreadNumber To ThreadsParameters.ThreadsCount Do
		
		ThreadNumberAsString = Format(ThreadNumber, "NG=0;");
		Job = BackgroundJobs.Execute(
			ExportImportDataInThreadMethodName(),
			JobParameters,
			StrTemplate(KeyTemplate, ThreadNumberAsString),
			StrTemplate(DescriptionTemplate, ThreadNumberAsString));
		
		Jobs.Add(Job);
		
		If ThreadNumber < ThreadsParameters.ThreadsCount Then
			// Distribute the start of jobs by time.
			CommonCTL.Pause(1);
		EndIf;
		
	EndDo;
	
	Return Jobs;
	
EndFunction

Function ExportImportDataInThreadMethodName() Export
	
	Return "ExportImportDataInternal.ExportImportInfoBaseDataInThread";
	
EndFunction

// Waits for data export and import in streams.
// 
// Parameters:
//  Jobs - Array of BackgroundJob - Launched jobs.
//  Container - DataProcessorObject.ExportImportDataContainerManager - Current container.
Procedure WaitExportImportDataInThreads(Jobs, Container) Export
	
	Timeout = 5; // sec.
	ProcessID = Container.ProcessID();
	
	While True Do
		
		Jobs = BackgroundJobs.WaitForExecutionCompletion(Jobs, Timeout);
		JobNumber = Jobs.Count();
		
		Errors = New Array();
		MessageTable = NewThreadMessagesTable();
		
		While JobNumber > 0 Do
			
			JobNumber = JobNumber - 1;
			Job = Jobs[JobNumber];
			
			If Job.State <> BackgroundJobState.Active Then
				Jobs.Delete(JobNumber);
			EndIf;
			
			ReceiveThreadMessages(MessageTable, Job, ProcessID);
			
			ErrorText = Undefined;
			
			If Job.State = BackgroundJobState.Failed Then
				
				ErrorInfo = ?(Job.ErrorInfo = Undefined,
					NStr("ru = 'Отсутствует информация об ошибке.';
						|en = 'No error information available.';"),
					ErrorProcessing.DetailErrorDescription(Job.ErrorInfo));
				ErrorText = StrTemplate(
					NStr("ru = 'Поток %1, фоновое задание завершилось аварийно.
						 |%2';
						|en = 'Thread %1, background job crashed.
						|%2';"),
					ThreadNumberFromJobKey(Job.Key),
					ErrorInfo);
				
			ElsIf Job.State = BackgroundJobState.Canceled Then
				
				ErrorText = StrTemplate(
					NStr("ru = 'Поток %1, фоновое задание отменено.';
						|en = 'Thread %1, background job is canceled.';"),
					ThreadNumberFromJobKey(Job.Key));
				
			EndIf;
			
			If ValueIsFilled(ErrorText) Then
				Errors.Add(ErrorText);
			EndIf;
			
		EndDo;
		
		If ValueIsFilled(Errors) Then
			
			For Each Job In Jobs Do
				
				ErrorText = StrTemplate(
					NStr("ru = 'Поток %1, фоновое задание прервано из-за ошибки в другом потоке.';
						|en = 'Thread %1, background job was interrupted due to an error in another thread.';"),
					ThreadNumberFromJobKey(Job.Key));
				
				Job.Cancel();
				Errors.Add(ErrorText);
				
				ReceiveThreadMessages(MessageTable, Job, ProcessID);
				
			EndDo;
			
			ProcessThreadMessages(MessageTable, Container);
			
			ErrorSeparator = Chars.LF + Chars.LF;
			ErrorText = StrConcat(Errors, ErrorSeparator);
			
			Raise ErrorText;
			
		EndIf;
		
		ProcessThreadMessages(MessageTable, Container);
		
		If Not ValueIsFilled(Jobs) Then
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

// New parameters of streams of data export and import.
// 
// Returns:
//  Structure - New parameters of streams of data export and import.:
// * IsExport - Boolean -
// * ThisIsDownload - Boolean -
// * ThreadsCount - Number -
// * InitialThreadNumber - Number -
// * Parameters - Structure -
Function NewExportImportDataThreadsParameters() Export
	
	StreamParameters = New Structure();
	StreamParameters.Insert("IsExport", False);
	StreamParameters.Insert("ThisIsDownload", False);
	StreamParameters.Insert("ThreadsCount", 0);
	StreamParameters.Insert("InitialThreadNumber", 1);
	StreamParameters.Insert("Parameters", New Structure());
	
	Return StreamParameters;
	
EndFunction

// Infobase data export and import in the stream.
// 
// Parameters:
//  StreamParameters - See ExportImportDataInternal.ExportImportInfoBaseDataInThread
Procedure ExportImportInfoBaseDataInThread(StreamParameters) Export
	
	If StreamParameters.IsExport Then
		DataProcessors.ExportImportDataInfobaseDataExportManager.ExportInfoBaseDataInThread(
			StreamParameters.Parameters);
	ElsIf StreamParameters.ThisIsDownload Then
		DataProcessors.ExportImportDataInfobaseDataImportManager.ImportInfoBaseDataInThread(
			StreamParameters.Parameters);
	Else
		Raise NStr("ru = 'Некорректные параметры потока.';
								|en = 'Incorrect thread parameters.';");
	EndIf;
	
EndProcedure

// Send a message to a parent thread.
// 
// Parameters:
//  ProcessID - UUID - Export \ import process ID.
//  MethodName - String - Method name.
//  MessageData - Structure - Message data.
Procedure SendMessageToParentThread(ProcessID, MethodName, MessageData) Export
	
	ThreadMessage = New Structure();
	ThreadMessage.Insert("DateSent", CurrentUniversalDateInMilliseconds());
	ThreadMessage.Insert("MethodName", MethodName);
	ThreadMessage.Insert("MessageData", MessageData);
	
	MessageDataWriter = New JSONWriter();
	MessageDataWriter.SetString();
	WriteJSON(MessageDataWriter, ThreadMessage);
	
	Message = New UserMessage();
	Message.TargetID = ProcessID;
	Message.Text = MessageDataWriter.Close();
	Message.Message();
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function StartLoadingCurAreaDataFromArchive(Val FileData, Val ImportParameters, Val ResultAddress = Undefined) Export 
	
	SetPrivilegedMode(True);
	
	ImportParameters.Insert(
		"LoadableTypes",
		LoadableTypes(BackupType(ImportParameters)));
		
	Handlers = DataProcessors.ExportImportDataDataImportHandlersManager.Create();
	Handlers.Initialize();
	
	Container = DataProcessors.ExportImportDataContainerManager.Create();
	Container.InitializeDownload(FileData, ImportParameters);	
	
	If ImportParameters.ItIsPossibleToContinueLoadingProcedure Then
		RefsMap = ContinueLoadingProcedure(ImportParameters, Container, Handlers);
	Else
		RefsMap = StartImportProcedure(ImportParameters, Container, Handlers);
	EndIf;
	
	ImportResult1 = New Structure(
		"Warnings, RefsMap",
		Container.Warnings(),
		RefsMap);
	
	If ResultAddress <> Undefined Then
		PutToTempStorage(ImportResult1, ResultAddress);
	EndIf;
	
	Return ImportResult1;
	
EndFunction

Function LoadCurAreaDataFromArchiveInBackground(Val FileData, Val ImportParameters)
		
	If Common.FileInfobase() 
		And GetCurrentInfoBaseSession().ApplicationName = "BackgroundJob" Then
		Raise NStr("ru = 'Невозможно выполнить загрузку в фоновом режиме: файловая информационная база поддерживает одновременное выполнение только одного фонового задания.';
								|en = 'Cannot import data in the background. The file infobase can run only one background job at a time.';");
	EndIf;			
			
	ResultAddress = PutToTempStorage(Undefined);
	
	JobParameters = New Array();
	JobParameters.Add(FileData);
	JobParameters.Add(ImportParameters);
	JobParameters.Add(ResultAddress);
	
	MethodName = "ExportImportDataInternal.StartLoadingCurAreaDataFromArchive";
	
	Job = CloudTechnology.CompleteTaskWithExtensions(
		MethodName,
		JobParameters,
		New UUID,
		NStr("ru = 'Восстановление области данных из архива';
			|en = 'Restore data area from archive';"))
		.WaitForExecutionCompletion();
	
	If Job.State = BackgroundJobState.Canceled Then
		Raise NStr("ru = 'Задание отменено';
								|en = 'Job is canceled';");
	ElsIf Job.State = BackgroundJobState.Failed Then
		Raise ErrorProcessing.DetailErrorDescription(Job.ErrorInfo);
	EndIf;
	
	Return GetFromTempStorage(ResultAddress);	
	
EndFunction

Function ItIsPossibleToContinueLoadingProcedure(HashSumOfSource, HashSumOfParameters)
	
	InformationAboutImportProcedure =  InformationAboutImportProcedure();
	CheckResult = AbilityToContinueAreaDataImportingCheckingResult(
		InformationAboutImportProcedure,
		HashSumOfSource,
		HashSumOfParameters);
	
	EventLogEvent = NStr(
		"ru = 'Выгрузка загрузка данных. Продолжение процедуры загрузки невозможно';
		|en = 'Data export and import. Cannot continue import procedure';",
		Common.DefaultLanguageCode());
	
	If Not CheckResult.ThisIsContinuationOfDownload Then 
		WriteLogEvent(
			EventLogEvent,
			EventLogLevel.Warning,,,
			NStr("ru = 'Отсутствует информация о прошлой процедуре загрузки';
				|en = 'No information about the previous import procedure';"));
		Return False;
	EndIf;
	
	If CheckResult.ConfigurationVersionDiffers Then
		
		WarningText = StrTemplate(
			NStr("ru = 'Изменилось имя или версия конфигурации 
			|Прошлые значения: %1 %2
			|Текущие значения: %3 %4';
			|en = 'Configuration name or version changed 
			|Previous values: %1 %2
			|Current values: %3 %4';"),
			InformationAboutImportProcedure.Configuration,
			InformationAboutImportProcedure.ConfigurationVersion,
			Metadata.Name,
			Metadata.Version);
			
		WriteLogEvent(
			EventLogEvent,
			EventLogLevel.Warning,,,
			WarningText);
		Return False;
	EndIf;
	
	If CheckResult.HashSumOfSourceDiffers Then
		
		WarningText = StrTemplate(
			NStr("ru = 'Изменился источник загрузки 
				 |Прошлое значение хеш суммы: %1 
				 |Текущее значение хеш суммы: %2';
				|en = 'Import source changed 
				|Previous hash value: %1 
				|Current hash value: %2';"),
			InformationAboutImportProcedure.HashSumOfSource,
			HashSumOfSource);
			
		WriteLogEvent(
			EventLogEvent,
			EventLogLevel.Warning,,,
			WarningText);
			
		Return False;
	EndIf;

	If CheckResult.HashSumOfParametersDiffers Then
		
		WarningText = StrTemplate(
			NStr("ru = 'Изменились параметры загрузки
				 |Прошлое значение хеш суммы: %1 
				 |Текущее значение хеш суммы: %2';
				|en = 'Import parameters changed
				|Previous hash value: %1 
				|Current hash value: %2';"),
			InformationAboutImportProcedure.HashSumOfParameters,
			HashSumOfParameters);
			
		WriteLogEvent(
			EventLogEvent,
			EventLogLevel.Warning,,,
			WarningText);
			
		Return False;
	EndIf;
	
	If Not CheckResult.LastImportedMetadataObjectDetermined Then
	
		WriteLogEvent(
			EventLogEvent,
			EventLogLevel.Warning,,,
			NStr("ru = 'Процесс загрузки был прерван не на загрузке метаданных';
				|en = 'Import process was interrupted not on metadata import';"));
		
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function AbilityToContinueAreaDataImportingCheckingResult(
	InformationAboutImportProcedure, HashSumOfSource, HashSumOfParameters)
	
	Result = New Structure();
	Result.Insert("ThisIsContinuationOfDownload", False);
	Result.Insert("LastImportedMetadataObjectDetermined", False);
	Result.Insert("ConfigurationVersionDiffers", False);
	Result.Insert("HashSumOfSourceDiffers", False);
	Result.Insert("HashSumOfParametersDiffers", False);
	
	Result.ThisIsContinuationOfDownload = InformationAboutImportProcedure <> Undefined;
	
	If Result.ThisIsContinuationOfDownload Then
		
		Result.LastImportedMetadataObjectDetermined
			= InformationRegisters.ExportImportMetadataObjects.HasProcessedMetadataObjects();
		Result.ConfigurationVersionDiffers = InformationAboutImportProcedure.Configuration <> Metadata.Name 
			Or InformationAboutImportProcedure.ConfigurationVersion <> Metadata.Version;
		Result.HashSumOfSourceDiffers
			= InformationAboutImportProcedure.HashSumOfSource <> HashSumOfSource;
		Result.HashSumOfParametersDiffers
			= InformationAboutImportProcedure.HashSumOfParameters <> HashSumOfParameters;
	
	EndIf;
	
	Return Result;
	
EndFunction

Procedure FixStartOfBootProcedure(HashSumOfSource, HashSumOfParameters, StateID)
		
	InformationAboutImportProcedure = New Structure();
	InformationAboutImportProcedure.Insert("StartDate", CurrentSessionDate());
	InformationAboutImportProcedure.Insert("Configuration", Metadata.Name);
	InformationAboutImportProcedure.Insert("ConfigurationVersion", Metadata.Version);
	InformationAboutImportProcedure.Insert("HashSumOfSource", HashSumOfSource);
	InformationAboutImportProcedure.Insert("HashSumOfParameters", HashSumOfParameters);
	InformationAboutImportProcedure.Insert("RefsMap", Undefined);
	InformationAboutImportProcedure.Insert("StateID", StateID);
		
	RecordInformationAboutBootProcedure(InformationAboutImportProcedure);
	
EndProcedure

Function InformationAboutImportProcedure() 
	Return Constants.InformationAboutImportProcedure.Get().Get();
EndFunction

Procedure RecordInformationAboutBootProcedure(Value)
	Constants.InformationAboutImportProcedure.Set(
		New ValueStorage(Value));
EndProcedure

Procedure FixCompletionOfBootProcedure()
	RecordInformationAboutBootProcedure(Undefined);
EndProcedure

Function StartImportProcedure(ImportParameters, Container, Handlers)
	
	If Container.FixState() And IsDifferentialBackup(ImportParameters) Then
		
		StateID = StateID(ImportParameters);
		
		ImportState = ExportImportData.DataAreaExportImportState(StateID);
	
		If ValueIsFilled(ImportState) Then
			Container.SetStartDate(
				ImportState.StartDate);	
			Container.SetNumberOfProcessedObjects(
				ImportState.ProcessedObjectsCount1);	
		Else
			RecordEventOfPreviousRecordStateAbsence(
				StateID);
		EndIf;
		
	EndIf;
			
	UploadInformation = ReadUploadInformation(Container);
	
	CheckIfUploadingToArchiveIsCompatibleWithCurConfiguration(
		UploadInformation);
	CheckIfUploadingToArchiveIsCompatibleWithCurVersionOfConfiguration(
		UploadInformation,
		BackupType(ImportParameters) <> BackupTypeFull());
	
	FixStartOfBootProcedure(
		ImportParameters.HashSumOfSource,
		ImportParameters.HashSumOfParameters,
		StateID(ImportParameters));
					
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.DisableAccessKeysUpdate(True, False);
	EndIf;
	
	Handlers.BeforeImportData(Container);
				
	RefsMap = Undefined;
	ImportParameters.Property("RefsMap", RefsMap);
				
	Return DownloadDatabaseData(
		ImportParameters,
		Container,
		Handlers,
		RefsMap);

EndFunction
	
Function ContinueLoadingProcedure(ImportParameters, Container, Handlers)
	
	InformationAboutImportProcedure = InformationAboutImportProcedure();
	ObjectSelection = InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection(True);
	DownloadableMetadataObjects = New Array();
	
	While ObjectSelection.Next() Do
		DownloadableMetadataObjects.Add(ObjectSelection.MetadataObject);
	EndDo;
	
	EventLogEvent = NStr(
		"ru = 'Выгрузка загрузка данных. Продолжение процедуры загрузки';
		|en = 'Data export and import. Continue import procedure';",
		Common.DefaultLanguageCode());
	WarningText = StrTemplate(
			NStr("ru = 'Процедура загрузки продолжена с объектов метаданных: %1';
				|en = 'Import procedure continued from metadata objects: %1';"),
			StrConcat(DownloadableMetadataObjects, ", "));
	WriteLogEvent(
		EventLogEvent,
		EventLogLevel.Warning,,, 
		WarningText);
	
	ObjectSelection.Reset();

	While ObjectSelection.Next() Do
		
		SaaSOperations.ClearMetadataObjectData(
			ObjectSelection.MetadataObject,
			Metadata.FindByFullName(ObjectSelection.MetadataObject));
		
		InformationRegisters.ExportImportMetadataObjects.RecordObjectProcessingEnd(
			ObjectSelection);
		
	EndDo;
		
	If Container.FixState() Then
		
		DownloadProcedureStateId = InformationAboutImportProcedure.StateID;
		
		If ValueIsFilled(DownloadProcedureStateId) Then
			
			ImportState = ExportImportData.DataAreaExportImportState(
				DownloadProcedureStateId);
			
			If ValueIsFilled(ImportState) Then
				Container.SetStartDate(
					ImportState.StartDate);	
				Container.SetNumberOfProcessedObjects(
					ImportState.ProcessedObjectsUpToCurrentMetadataObject);	
			Else
				RecordEventOfPreviousRecordStateAbsence(
					DownloadProcedureStateId);
			EndIf;
			
			DownloadParametersStateId = StateID(ImportParameters);
			If DownloadProcedureStateId <> DownloadParametersStateId Then
				InformationAboutImportProcedure.StateID = DownloadParametersStateId;
				RecordInformationAboutBootProcedure(InformationAboutImportProcedure);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return DownloadDatabaseData(
		ImportParameters,
		Container,
		Handlers,
		InformationAboutImportProcedure.RefsMap);
	
EndFunction

Function DownloadDatabaseData(
	ImportParameters,
	Container,
	Handlers,
	RefsMap = Undefined)
		
	LinkReplacementFlow = DataProcessors.ExportImportDataInfobaseDataImportManager.DownloadDatabaseData(
		Container,
		Handlers,
		RefsMap);
		
	AfterLoadingDatabaseData(
		ImportParameters,
		Container,
		Handlers,
		LinkReplacementFlow);
	
	Return LinkReplacementFlow.RefsMap();
	
EndFunction

Procedure AfterLoadingDatabaseData(ImportParameters, Container, Handlers, LinkReplacementFlow)
	
	UserMatching = Undefined;
	If ImportParameters.UploadUsers Then
		
		ExportImportInfobaseUsers.UploadInformationBaseUsers(Container);
		
		If ImportParameters.UploadUserSettings_ Then
			
			DataProcessors.ExportImportDataUserSettingsImportManager.DownloadInformationDatabaseUserSettings(
				Container, Handlers, LinkReplacementFlow);
			
		EndIf;
		
	ElsIf ImportParameters.Property("UserMatching", UserMatching) Then
		
		// Clearing IDs if they are used.
		Query = New Query;
		Query.SetParameter("Users", UserMatching.UnloadColumn("User"));
		Query.SetParameter("IDs", UserMatching.UnloadColumn("ServiceUserID"));
		Query.Text =
		"SELECT
		|	Users.Ref AS User
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	NOT Users.Ref IN (&Users)
		|	AND Users.ServiceUserID IN(&IDs)";
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			UserObject = Selection.User.GetObject(); // CatalogObject.Users
			UserObject.ServiceUserID = Undefined;
			UserObject.DataExchange.Load = True;
			UserObject.Write();
		EndDo;
		
		// Updating IDs for used users.
		For Each UserMapping In UserMatching Do
			If Not ValueIsFilled(UserMapping.User) Then
				Continue;
			EndIf;
			UserObject = UserMapping.User.GetObject(); // CatalogObject.Users
			If UserObject.ServiceUserID <> UserMapping.ServiceUserID Then
				UserObject.ServiceUserID = UserMapping.ServiceUserID;
				UserObject.DataExchange.Load = True;
				UserObject.Write();
			EndIf;
		EndDo;
		
		// Import settings replacing infobase username.
		ReplaceUserInSettings = New Map;
		For Each UserMapping In UserMatching Do
			If ValueIsFilled(UserMapping.OldIBUserName) 
				And ValueIsFilled(UserMapping.NewIBUserName) Then
				ReplaceUserInSettings.Insert(UserMapping.OldIBUserName, UserMapping.NewIBUserName);
			EndIf;
		EndDo;
		DataProcessors.ExportImportDataUserSettingsImportManager.DownloadInformationDatabaseUserSettings(
			Container, Handlers, LinkReplacementFlow, ReplaceUserInSettings);
		
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.DisableAccessKeysUpdate(True);
	EndIf;
	
	DataSeparationEnabled = SaaSOperations.DataSeparationEnabled(); 
	If DataSeparationEnabled Then
		LockParameters = IBConnections.GetDataAreaSessionLock();
		If Not LockParameters.Use Then
			LockParameters.Use = True;
			IBConnections.SetDataAreaSessionLock(LockParameters);		
		EndIf;
	EndIf;
	
	JobsQueueInternalDataSeparation.AfterImportData(Container);
	
	Handlers.AfterImportData(Container);
	
	If DataSeparationEnabled Then
		LockParameters.Use = False;
		IBConnections.SetDataAreaSessionLock(LockParameters);	
	EndIf;

	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.DisableAccessKeysUpdate(False);
	EndIf;
	
	Container.FinalizeDownload();	
	
	FixCompletionOfBootProcedure();
	
EndProcedure

// Writes configuration description
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container
//		manager used for data export. For more information, see the comment
//		to ExportImportDataContainerManager handler interface.
//
Procedure SaveUploadDescription(Val Container)
	
	DumpInfoType = XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "DumpInfo");
	ConfigurationInfoType = XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "ConfigurationInfo");
	
	UploadInformation = XDTOFactory.Create(DumpInfoType);
	UploadInformation.Created = CurrentUniversalDate();
	
	ConfigurationInformation = XDTOFactory.Create(ConfigurationInfoType);
	ConfigurationInformation.Name = Metadata.Name;
	ConfigurationInformation.Version = Metadata.Version;
	ConfigurationInformation.Vendor = Metadata.Vendor;
	ConfigurationInformation.Presentation = Metadata.Presentation();
	
	UploadInformation.Configuration = ConfigurationInformation;
	
	FileName = Container.CreateFile(DumpInfo());
	WriteXDTOObjectToFile(UploadInformation, FileName);
	Container.FileRecorded(FileName);
	
EndProcedure

// Reads configuration details
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - a container
//		manager used for data export. For more information, see the comment
//		to ExportImportDataContainerManager handler interface.
//
Function ReadUploadInformation(Container)
	
	File = Container.GetFileFromFolder(DumpInfo());
	
	Container.UnzipFile(File);
	
	Result =  ReadXDTOObjectFromFile(File.FullName, XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "DumpInfo"));
	
	DeleteFiles(File.FullName);
	
	Return Result;
	
EndFunction

// Returns an item name in a write or read stream, in which XDTODataObject is stored.
//
// Returns:
//	String - item name.
//
Function NameOfElementContainingXDTOObject()
	
	Return "XDTODataObject";
	
EndFunction

// Returns an item name in a write or read stream, in which the object is stored.
//
// Returns:
//	String - item name.
//
Function NameOfElementContainingObject()
	
	Return "Data";
	
EndFunction

// Returns a namespace array to write packages.
//
// Parameters:
//	NamespaceURI - String - a namespace.
//
// Returns:
//	Array of String - a namespace array.
//
Function GetNamespacesForPackageEntries(Val NamespaceURI)
	
	Result = New Array();
	Result.Add(NamespaceURI);
	
	Dependencies = XDTOFactory.Packages.Get(NamespaceURI).Dependencies;
	For Each Dependence In Dependencies Do
		DependentNamespaces = GetNamespacesForPackageEntries(Dependence.NamespaceURI);
		CommonClientServer.SupplementArray(Result, DependentNamespaces, True);
	EndDo;
	
	Return Result;
	
EndFunction

// Fills in an array with a collection of reference object metadata.
//
// Parameters:
//	ArrayOfMetadataCollections - Array of MetadataObject - metadata objects.
//
Procedure PopulateCollectionsOfReferenceObjects(ArrayOfMetadataCollections)

	ArrayOfMetadataCollections.Add(Metadata.Catalogs);
	ArrayOfMetadataCollections.Add(Metadata.Documents);
	ArrayOfMetadataCollections.Add(Metadata.BusinessProcesses);
	ArrayOfMetadataCollections.Add(Metadata.Tasks);
	ArrayOfMetadataCollections.Add(Metadata.ChartsOfAccounts);
	ArrayOfMetadataCollections.Add(Metadata.ExchangePlans);
	ArrayOfMetadataCollections.Add(Metadata.ChartsOfCharacteristicTypes);
	ArrayOfMetadataCollections.Add(Metadata.ChartsOfCalculationTypes);
	
EndProcedure

// Fills an array with collection of record set metadata.
//
// Parameters:
//	ArrayOfMetadataCollections - Array of MetadataObjectCollection - array.
//
Procedure PopulateRecordsetCollections(ArrayOfMetadataCollections)
	
	ArrayOfMetadataCollections.Add(Metadata.InformationRegisters);
	ArrayOfMetadataCollections.Add(Metadata.AccumulationRegisters);
	ArrayOfMetadataCollections.Add(Metadata.AccountingRegisters);
	ArrayOfMetadataCollections.Add(Metadata.Sequences);
	ArrayOfMetadataCollections.Add(Metadata.CalculationRegisters);
	For Each CalculationRegister In Metadata.CalculationRegisters Do
		ArrayOfMetadataCollections.Add(CalculationRegister.Recalculations);
	EndDo;
	
EndProcedure

// Fills in an array with a constant metadata collection.
//
// Parameters:
//	ArrayOfMetadataCollections - Array of MetadataObjectCollection - array.
//
Procedure FillCollectionsOfConstants(ArrayOfMetadataCollections)
	
	ArrayOfMetadataCollections.Add(Metadata.Constants);
	
EndProcedure

// Returns a full list of objects from the specified collections
//
// Parameters:
//  Collections - Array of MetadataObjectCollection - Collections.
//
// Returns:
//  Array of MetadataObject - Metadata objects.
//
Function AllCollectionMetadata(Val Collections)
	
	Result = New Array;
	For Each Collection In Collections Do
		
		For Each Object In Collection Do
			Result.Add(Object);
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Returns business process point references
//
// Returns:
//	Map of KeyAndValue:
//	  *Key - Type - Reference type of the business process point.
//	  *Value - MetadataObject - Business process.
//
Function BusinessProcessesRoutePointsRefs()
	
	Result = New Map();
	
	For Each BusinessProcess In Metadata.BusinessProcesses Do
		
		Result.Insert(Type("BusinessProcessRoutePointRef." + BusinessProcess.Name), BusinessProcess);
		
	EndDo;
	
	Return Result;
	
EndFunction

// Returns a file description with export digest.
//
// Returns:
//	String - name
Function Digest() Export
	Return "Digest";
EndFunction

// Returns a file name with export warnings.
//
// Returns:
//	String - Name.
Function DumpWarnings() Export
	Return "DumpWarnings";
EndFunction

// Extensions
// 
// Returns:
//  String
Function Extensions() Export
	Return "Extensions";
EndFunction

// Custom extensions
// 
// Returns:
//  String
Function CustomExtensions() Export 
	Return "CustomExtensions";	
EndFunction

// Returns a name of the file with duplicates of predefined items.
//
// Returns:
//	String - Name.
Function PredefinedDataDuplicates() Export
	Return "PredefinedDataDuplicates";
EndFunction

// Writes XDTODataObject to file.
//
// Parameters:
//	XDTODataObject - XDTODataObject - XDTODataObject to be written.
//	FileName - String - full path to the file.
//	DefaultNamespacePrefix - String - prefix.
//
Procedure WriteXDTOObjectToFile(Val XDTODataObject, Val FileName, Val DefaultNamespacePrefix = "")
	
	WriteStream = New XMLWriter();
	WriteStream.OpenFile(FileName);
	
	NamespacesPrefixes = NamespacesPrefixes();
	ObjectNamespace = XDTODataObject.Type().NamespaceURI;
	If IsBlankString(DefaultNamespacePrefix) Then
		DefaultNamespacePrefix = NamespacesPrefixes.Get(ObjectNamespace);
	EndIf;
	NamespacesUsed = GetNamespacesForPackageEntries(ObjectNamespace);
	
	WriteStream.WriteStartElement(NameOfElementContainingXDTOObject());
	
	For Each NamespaceUsed In NamespacesUsed Do
		NamespacesPrefix = NamespacesPrefixes.Get(NamespaceUsed);
		If NamespacesPrefix = DefaultNamespacePrefix Then
			WriteStream.WriteNamespaceMapping("", NamespaceUsed);
		Else
			WriteStream.WriteNamespaceMapping(NamespacesPrefix, NamespaceUsed);
		EndIf;
	EndDo;
	
	XDTOFactory.WriteXML(WriteStream, XDTODataObject);
	
	WriteStream.WriteEndElement();
	
	WriteStream.Close();
	
EndProcedure

Function XMLSchema(SchemaBinaryData)
	
	ReadStream = SchemaBinaryData.OpenStreamForRead();
	
	Read = New XMLReader;
	Read.OpenStream(ReadStream);
	
	Builder = New DOMBuilder;
	Document = Builder.Read(Read); // DOMElement
	
	ReadStream.Close();
	
	CircuitBuilder = New XMLSchemaBuilder;	
	
	Return CircuitBuilder.CreateXMLSchema(Document);

EndFunction

Function FactoryByScheme(Schema)
	
	SetOfSchemes = New XMLSchemaSet;
	SetOfSchemes.Add(Schema);
	
	Return New XDTOFactory(SetOfSchemes);

EndFunction

Procedure UnloadConfigurationDiagram(Container, ExportingParameters)
	
	ConfigurationSchemaData = Undefined;
	If Not ExportingParameters.Property("ConfigurationSchemaData", ConfigurationSchemaData) Then
		ConfigurationSchemaData = ConfigurationSchema.SchemaBinaryData(False, False);	
	EndIf;
	
	FullFileName = Container.CreateCustomFile("xsd", "ConfigScheme");
	ConfigurationSchemaData.Write(FullFileName);
	
	Container.SetNumberOfObjects(FullFileName, 1);
	
EndProcedure

Procedure RestoreExtensions(RecoveryExtensions)

	StukturaOfSelection = New Structure("Name");

	For Each ExtensionForRecovery In RecoveryExtensions Do

		StukturaOfSelection.Name = ExtensionForRecovery.Name;

		DataOfRestoredExtension = ExtensionForRecovery.Data;

		InstalledExtensions = ConfigurationExtensions.Get(StukturaOfSelection,
			ConfigurationExtensionsSource.Database);

		If ValueIsFilled(InstalledExtensions) Then

			InstalledExtension = InstalledExtensions[0];

			If InstalledExtension.Active = ExtensionForRecovery.Active
				And InstalledExtension.SafeMode = ExtensionForRecovery.SafeMode
				And InstalledExtension.UseDefaultRolesForAllUsers = ExtensionForRecovery.UseDefaultRolesForAllUsers
				And InstalledExtension.UsedInDistributedInfoBase = ExtensionForRecovery.UsedInDistributedInfoBase
				And InstalledExtension.UnsafeActionProtection.UnsafeOperationWarnings = ExtensionForRecovery.UnsafeActionProtection.UnsafeOperationWarnings Then			
					
				If InstalledExtension.UUID = ExtensionForRecovery.UUID Then
					Continue;
				EndIf;
												
				MetadataOfInstalledExtension = New ConfigurationMetadataObject(InstalledExtension.GetData());
				MetadataOfExtensionBeingRestored = New ConfigurationMetadataObject(DataOfRestoredExtension);

				If MetadataOfInstalledExtension.Version = MetadataOfExtensionBeingRestored.Version Then									
					Continue;
				EndIf;

			EndIf;
			
			InstalledExtension.Delete();

		EndIf;

		RecoverableExtension = ConfigurationExtensions.Create();
		FillPropertyValues(RecoverableExtension, ExtensionForRecovery);
		RecoverableExtension.Write(DataOfRestoredExtension);
			
	EndDo;

EndProcedure

Procedure RestoreExtensionFrames(RecoveryExtensions)

	StukturaOfSelection = New Structure("Name");

	For Each ExtensionForRecovery In RecoveryExtensions Do

		DataOfRestoredExtension = ExtensionForRecovery.Data;
		MetadataOfExtensionBeingRestored = New ConfigurationMetadataObject(DataOfRestoredExtension);
		
		StukturaOfSelection.Name = MetadataOfExtensionBeingRestored.Name;	

		InstalledExtensions = ConfigurationExtensions.Get(StukturaOfSelection,
			ConfigurationExtensionsSource.Database);	
		
		If ValueIsFilled(InstalledExtensions) Then

			InstalledExtension = InstalledExtensions[0];

			MetadataOfInstalledExtension = New ConfigurationMetadataObject(InstalledExtension.GetData());

			If MetadataOfInstalledExtension.Version = MetadataOfExtensionBeingRestored.Version Then
				Continue;
			EndIf;
			
			InstalledExtension.Delete();

		EndIf;

		RecoverableExtension = ConfigurationExtensions.Create();
		RecoverableExtension.SafeMode = False;
		
		UnsafeActionProtection = New UnsafeOperationProtectionDescription;
		UnsafeActionProtection.UnsafeOperationWarnings = False;
		RecoverableExtension.UnsafeActionProtection = UnsafeActionProtection;
		
		RecoverableExtension.Write(DataOfRestoredExtension);
				
	EndDo;
	
EndProcedure

Procedure AddConstantToMetadataList(ObjectMetadata, MetadataList, Types)
	
	For Each Type In Types Do
		
		If ObjectMetadata.Type.ContainsType(Type) Then 
			MetadataList.Insert(ObjectMetadata.FullName(), New Array);		
			Return;
		EndIf;

	EndDo;
		
EndProcedure

Procedure AddReferenceTypeToMetadataList(ObjectMetadata, MetadataList, Types)
	
	StructuresArray = New Array;
	
	For Each Attribute In ObjectMetadata.Attributes Do 
		
		AddPropsToArray(StructuresArray, Attribute,, Types);
		
	EndDo;
	
	For Each TabularSection In ObjectMetadata.TabularSections Do 
		
		For Each Attribute In TabularSection.Attributes Do
			
			AddPropsToArray(StructuresArray, Attribute, TabularSection, Types);
			
		EndDo;
		
	EndDo;
	
	InsertMetadataObjectIntoMatch(ObjectMetadata.FullName(), MetadataList, StructuresArray);
	
EndProcedure

Procedure AddRegisterToMetadataTable(ObjectMetadata, Val MetadataList, Types)
	
	StructuresArray = New Array;
	This_Is_Recalculation = Metadata.CalculationRegisters.Contains(ObjectMetadata.Parent());
	
	For Each Dimension In ObjectMetadata.Dimensions Do 
		
		If This_Is_Recalculation Then
			Dimension = Dimension.RegisterDimension;
		EndIf;
		
		AddPropsToArray(StructuresArray, Dimension,, Types);
		
	EndDo;
		
	If Metadata.Sequences.Contains(ObjectMetadata) Then 
		
		For Each DocumentMetadata In ObjectMetadata.Documents Do
			
			ManagerOfDocument = Common.ObjectManagerByFullName(
				DocumentMetadata.FullName());
			DocumentType = TypeOf(ManagerOfDocument.EmptyRef());
			
			If Types.Find(DocumentType) <> Undefined Then 
				
				Structure = AttributesStructure1();
				Structure.AttributeName = "Recorder";
				
				StructuresArray.Add(Structure);
				
				Break;
			EndIf;
			
		EndDo;
		
	ElsIf Not This_Is_Recalculation Then
		
		For Each Attribute In ObjectMetadata.Attributes Do 
			
			AddPropsToArray(
				StructuresArray,
				Attribute,,
				Types);
			
		EndDo;
		
		For Each Resource In ObjectMetadata.Resources Do 
			
			AddPropsToArray(
				StructuresArray,
				Resource,,
				Types);
			
		EndDo;
		
		If Not CommonCTL.IsIndependentRecordSet(ObjectMetadata) Then
			AddPropsToArray(
				StructuresArray,
				ObjectMetadata.StandardAttributes.Recorder,,
				Types);	
		EndIf;
		
		If CommonCTL.IsAccountingRegister(ObjectMetadata)
			And ObjectMetadata.ChartOfAccounts <> Undefined Then
			
			ChartOfAccountsManager = Common.ObjectManagerByFullName(
				ObjectMetadata.ChartOfAccounts.FullName());
			ChartOfAccountsType = TypeOf(ChartOfAccountsManager.EmptyRef());
			
			If Types.Find(ChartOfAccountsType) <> Undefined Then 
				
				If ObjectMetadata.Correspondence Then 
					Structure = AttributesStructure1();
					Structure.AttributeName = "AccountDr";		
					StructuresArray.Add(Structure);
					
					Structure = AttributesStructure1();
					Structure.AttributeName = "AccountCr";		
					StructuresArray.Add(Structure);
				Else		
					Structure = AttributesStructure1();
					Structure.AttributeName = "Account";		
					StructuresArray.Add(Structure);
				EndIf;
				
			EndIf;
	
		EndIf;
				
	EndIf;
	
	InsertMetadataObjectIntoMatch(ObjectMetadata.FullName(), MetadataList, StructuresArray);
	
EndProcedure

Procedure AddPropsToArray(StructuresArray, Attribute, TabularSection = Undefined, Types)
	
	For Each Type In Types Do
		
		If Attribute.Type.ContainsType(Type) Then 
			AttributeName      = Attribute.Name;
			TabularSectionName = ?(TabularSection = Undefined, Undefined, TabularSection.Name);
			
			Structure = AttributesStructure1();
			Structure.TabularSectionName = TabularSectionName;
			Structure.AttributeName      = AttributeName;
			
			StructuresArray.Add(Structure);
			
			Return;
		EndIf;
		
	EndDo;
			
EndProcedure

Procedure InsertMetadataObjectIntoMatch(FullMetadataName, MetadataList, StructuresArray)
	
	If StructuresArray.Count() = 0 Then 
		Return;
	EndIf;
	
	MetadataList.Insert(FullMetadataName, StructuresArray);
	
EndProcedure

// Returns:
// 	Structure:
// * AttributeName - String
// * TabularSectionName - String
// 
Function AttributesStructure1()
	
	Result = New Structure;
	Result.Insert("TabularSectionName");
	Result.Insert("AttributeName");
	
	Return Result;
	
EndFunction

// Returns the backup type based on import parameters.
// Parameters:
//  ImportParameters - Structure - Parameters.
//
// Returns:
//  String - One of the values: Standard, Full, or Differential.
Function BackupType(ImportParameters) 

	If ImportParameters.Property("BackupType") Then
		Return ImportParameters.BackupType;
	EndIf;
		
	Return BackupTypeNormal();
  
EndFunction

Function StateID(ImportParameters)
	
	If Not ValueIsFilled(ImportParameters) Then
		Return Undefined;
	EndIf;
	
	StateID = Undefined;
	ImportParameters.Property("StateID", StateID);
	
	Return StateID;
	
EndFunction

Procedure RestoreAreaExtensions(ExtensionData_)
		
	ExtensionsDirectory.ReadDataOfRecoverableAreaExtensions(ExtensionData_);

	DataAreaKey = Undefined;
	If ExtensionData_.Property("DataAreaKey", DataAreaKey) Then
		Constants.DataAreaKey.Set(DataAreaKey);
	EndIf;

	RecoveryExtensions = Undefined;
	If ExtensionData_.Property("RecoveryExtensions", RecoveryExtensions) Then

		ExtensionsDirectory.RestoreExtensionsToNewArea(RecoveryExtensions);

	EndIf;

	ExtensionsDirectory.RecordDataOfRecoverableAreaExtensions(RecoveryExtensions);
	
EndProcedure

Procedure RecordEventOfPreviousRecordStateAbsence(StateID)
	
	WriteLogEvent(
		NStr("ru = 'Выгрузка загрузка данных. Не найдена запись предыдущего состояния';
			|en = 'Data export and import. Cannot find previous state record';", Common.DefaultLanguageCode()),
		EventLogLevel.Warning,,
		StateID,
		NStr("ru = 'Восстановление состояния пропущено';
			|en = 'State recovery is skipped';"));
		
EndProcedure

Function HashSumOfSource(Archive)
	
	NameOfContentFile = GetFileName(PackageContents());
	
	TempDirectory = GetTempFileName();
	CreateDirectory(TempDirectory);
	
	UnzipArchiveFile(Archive, TempDirectory, NameOfContentFile);

	DataHashing = New DataHashing(HashFunction.CRC32);
	DataHashing.AppendFile(
		TempDirectory + GetPathSeparator() + NameOfContentFile);
	
	DeleteFiles(TempDirectory);
	
	Return DataHashing.HashSum;

EndFunction

Function HashSumOfParameters(ImportParameters)
	
	ControlledLoadingParameters = New Structure(
		"UploadUserSettings_, UploadUsers, CollapseSeparatedUsers");
	FillPropertyValues(ControlledLoadingParameters, ImportParameters);
	
	DataHashing = New DataHashing(HashFunction.CRC32);
	DataHashing.Append(
		Common.ValueToXMLString(ControlledLoadingParameters));
	
	Return DataHashing.HashSum;
	
EndFunction

Function NewTableOfNumberOfProcessedObjects()
	NumberOfProcessedObjectsTable = New ValueTable;
	NumberOfProcessedObjectsTable.Columns.Add("FullName", New TypeDescription("String"));
	NumberOfProcessedObjectsTable.Columns.Add("NumberOfObjects", New TypeDescription("Number"));
	Return NumberOfProcessedObjectsTable;
EndFunction

Function TableOfNumberOfExportedObjectsBySubqueries(Subqueries)
	SubquerySeparator_ = Chars.LF + " UNION ALL " + Chars.LF;		
	Query = New Query(StrConcat(Subqueries, SubquerySeparator_));
	Return Query.Execute().Unload();
EndFunction

Procedure AddTableOfProcessedObjectsNumber(NumberOfProcessedObjectsTable, Supplement_Table)
	For Each SupplementTableRow In Supplement_Table Do
		FillPropertyValues(NumberOfProcessedObjectsTable.Add(), SupplementTableRow);
	EndDo;
EndProcedure

#Region ParallelExportImport

// Process stream messages.
// 
// Parameters:
//  MessageTable - See NewThreadMessagesTable
//  Container - DataProcessorObject.ExportImportDataContainerManager - Current container.
Procedure ProcessThreadMessages(MessageTable, Container)
	
	If Not ValueIsFilled(MessageTable) Then
		Return;
	EndIf;
	
	MessageTable.Sort("DateSent");
	
	For Each TableRow In MessageTable Do
		Container.ProcessThreadMessage(TableRow.MethodName, TableRow.MessageData);
	EndDo;
	
EndProcedure

// Get stream messages.
// 
// Parameters:
//  MessageTable - See NewThreadMessagesTable
//  Job - BackgroundJob - Export \ import job.
//  ProcessID - UUID - Export \ import process ID.
Procedure ReceiveThreadMessages(MessageTable, Job, ProcessID)
	
	ThreadMessages = Job.GetUserMessages(True);
	
	If Not ValueIsFilled(ThreadMessages) Then
		Return;
	EndIf;
	
	ThreadMessageReading = New JSONReader();
	
	For Each Message In ThreadMessages Do
		
		If Message.TargetID <> ProcessID Then
			Continue;
		EndIf;
		
		ThreadMessageReading.SetString(Message.Text);
		ThreadMessage = ReadJSON(ThreadMessageReading);
		
		FillPropertyValues(MessageTable.Add(), ThreadMessage);
		
	EndDo;
	
	ThreadMessageReading.Close();
	
EndProcedure

// New stream message table.
// 
// Returns:
//  ValueTable - New stream message table.:
// * DateSent - Number - Universal date in milliseconds.
// * MethodName - String - Method name.
// * MessageData - Structure - Message data.
Function NewThreadMessagesTable()
	
	MessageTable = New ValueTable();
	MessageTable.Columns.Add("DateSent");
	MessageTable.Columns.Add("MethodName");
	MessageTable.Columns.Add("MessageData");
	
	Return MessageTable;
	
EndFunction

// Stream number from the job key.
// 
// Parameters:
//  JobKey - String - Job key.
// 
// Returns:
//  String - Stream number from the job key.
Function ThreadNumberFromJobKey(JobKey)
	
	ThreadNumber = "";
	KeyParts = StrSplit(JobKey, "_", False);
	
	If KeyParts.Count() = 3 Then
		ThreadNumber = KeyParts[2];
	EndIf;
	
	Return ThreadNumber;
	
EndFunction

#EndRegion

#EndRegion
