#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ForUnloading;
Var ForImport;
Var IsChildThread;

Var ContainerInitialized;
Var TempDirectory;
Var UploadFileName;
Var Archive;
Var NumberOfFilesByType;
Var UploadStartTime;
Var Content; // ValueTable
Var FilesUsed; // Array of String
Var Warnings; // See Warnings
Var UploadTo;
Var ExportToClient;
Var PartsExportedToClient;
Var MultipartUpload; // See NewMultipartUpload
Var UploadExtensionData;
Var UnloadDifferentialCopy;
Var ForTechnicalSupport;
Var Parameters;
Var ExtensionsFrameVersions;
Var ImportFileData;
Var DuplicatesOfPredefinedItems; // Map
Var ProcessID;

Var FixState;
Var StateRecording;
Var NextStateRecordMinimumDate;
Var ProcessedObjectsAfterCalculatingState;
Var ObjectsProcessedDuringCurrentSession;
Var ObjectsAtCompletionPercentage;
Var ProcessingObjectsCount;
Var ProcessedObjectsByMetadata; // Map
Var MetadataObjectForProcessingFullName; // String

#EndRegion

#Region Internal

#Region Upload0

// Initializes an export procedure.
//
// Parameters:
//	ExportingParameters - See ExportImportData.UploadCurAreaDataToArchive.ExportingParameters
//
Procedure InitializeUpload(Val ExportingParameters) Export
	
	CheckingContainerInitialization(True);
	
	ForUnloading = True;
	Parameters = ExportingParameters;
	ProcessID = New UUID();
	
	InitializeExportVariables();
	InitializeAdditionalUploadProperties();
		
	UploadStartTime = CurrentSessionDate();	

	TempDirectory = GetTempFileName("zip") + GetPathSeparator();
	CreateDirectory(TempDirectory);
	
	UploadFileName = Undefined;
	ExportingParameters.Property("UploadFileName", UploadFileName);
	
	If Not ValueIsFilled(UploadFileName) Then
		UploadFileName = GetTempFileName("zip");
	EndIf;
	
	Archive = ZipArchives.Create(UploadFileName);
		
	If Not ExportingParameters.Property("UploadTo", UploadTo) Then
		UploadTo = False;
	EndIf;
	
	If Not ExportingParameters.Property("ExportToClient", ExportToClient) Then
		ExportToClient = False;
	EndIf;
	PartsExportedToClient = 0;
	
	If Not ExportingParameters.Property("UploadExtensionData", UploadExtensionData) Then
		UploadExtensionData = False;
	EndIf;
	
	If Not ExportingParameters.Property("UnloadDifferentialCopy", UnloadDifferentialCopy) Then
		UnloadDifferentialCopy = False;
	EndIf;
	
	If Not ExportingParameters.Property("ExtensionsFrameVersions", ExtensionsFrameVersions) Then
		ExtensionsFrameVersions = New Map();
	EndIf;
	
	If Not ExportingParameters.Property("ExportModeForTechnicalSupport", ForTechnicalSupport) Then
		ForTechnicalSupport = False;
	EndIf;
	
	SetCountOfProcessedObjects();
	InitializeState();
	
	ContainerInitialized = True;
	
EndProcedure

Procedure InitializeUploadInThread(StreamParameters) Export
	
	InitializeVariablesInThread(StreamParameters);
	InitializeExportVariables();
	InitializeAdditionalUploadProperties();
	InitializeStateVariables();
	
	ContainerInitialized = True;
	
EndProcedure

// Export parameters.
// 
// Returns: 
//  Structure - Structure containing data export parameters.:
//		* TypesToExport - Array of MetadataObject  - Data must be exported to archive.
//      * UnloadUsers - Boolean - Export infobase users information.
//      * ExportUserSettings - Boolean - This parameter is ignored if ExportUsers = False.
//    The structure can contain additional keys that can be processed by arbitrary export handlers.
//      
Function ExportingParameters() Export
	
	CheckingContainerInitialization();
	
	If ForUnloading Then
		Return New FixedStructure(Parameters);
	Else
		Raise NStr("ru = 'Контейнер не инициализирован для выгрузки данных.';
								|en = 'The container is not initialized for data export.';");
	EndIf;
	
EndFunction

Function ForTechnicalSupport() Export
	
	Return ForTechnicalSupport;
	
EndFunction

Procedure SetUploadParameters(ExportingParameters) Export
	
	Parameters = ExportingParameters;
	
EndProcedure

// Creates a file in the export directory.
//
// Parameters:
//	FileKind - String - Export file type.
//	DataType - String - Data type.
//
// Returns:
//	String - a file name.
//
Function CreateFile(Val FileKind, Val DataType = Undefined) Export
	
	CheckingContainerInitialization();
	
	Return AppendFile(FileKind, "xml", DataType);
	
EndFunction

// Creates an arbitrary export file.
//
// Parameters:
//	Extension - String - File extension.
//	DataType - String - Data type.
//
// Returns:
//	String - a file name.
//
Function CreateCustomFile(Val Extension, Val DataType = Undefined) Export
	
	CheckingContainerInitialization();
	
	Return AppendFile(ExportImportDataInternal.CustomData(), Extension, DataType);
	
EndFunction

Procedure SetNumberOfObjects(Val FullFilePath, Val NumberOfObjects = Undefined) Export
	
	CheckingContainerInitialization();
	
	CompositionRow = FindCompositionLine(FullFilePath, "FullName");
	If CompositionRow = Undefined Then
		Raise NStr("ru = 'Файл не найден';
								|en = 'File not found';");
	EndIf;
	
	CompositionRow.NumberOfObjects = NumberOfObjects;
	
EndProcedure

Procedure ExcludeFile(Val FullFilePath) Export
	
	CheckingContainerInitialization();
	
	CompositionRow = FindCompositionLine(FullFilePath, "FullName");
	If CompositionRow = Undefined Then
		Raise StrTemplate(NStr("ru = 'Файл %1 не найден в составе контейнера.';
										|en = 'File %1 is not found in the container.';"), FullFilePath);
	EndIf;
		
	FilesCount = NumberOfFilesByType[CompositionRow.FileKind];
	NumberOfFilesByType.Insert(CompositionRow.FileKind, FilesCount - 1);
		
	Content.Delete(CompositionRow);
	FilesUsed.Delete(FilesUsed.Find(FullFilePath));
	DeleteFiles(FullFilePath);
	
EndProcedure

Procedure FileRecorded(Val FullFilePath) Export
	
	File = New File(FullFilePath);
	
	CompositionRow = FindCompositionLine(FullFilePath, "FullName");
	If CompositionRow <> Undefined Then
		CompositionRow.Size = File.Size();
	EndIf;
	
	RelativeName = Mid(FullFilePath, StrLen(TempDirectory));
	ArchiveDirectory = GetTempFileName("zip");
	Parts = StrSplit(RelativeName, GetPathSeparator());
	Parts.Delete(Parts.UBound());
	CreateDirectory(ArchiveDirectory + StrConcat(Parts, GetPathSeparator()));
	MoveFile(FullFilePath, ArchiveDirectory + RelativeName);
	FilesUsed.Delete(FilesUsed.Find(FullFilePath));
	
	If IsChildThread() Then
		
		MessageData = New Structure();
		MessageData.Insert("ArchiveDirectory", ArchiveDirectory);
		
		ExportImportDataInternal.SendMessageToParentThread(
			ProcessID(),
			"FileRecorded",
			MessageData);
		
	Else
		
		AddFileToArchive(ArchiveDirectory);
		
	EndIf;
	
EndProcedure

// Returns the differential copy export flag.
// 
// Returns:
// 	Boolean - 
Function UnloadDifferentialCopy() Export
	
	Return UnloadDifferentialCopy;
	
EndFunction

Function ThisIsBackup() Export
	
	If Parameters.Property("ThisIsBackup") Then
		Return Parameters.ThisIsBackup;
	EndIf;
	
	Return False;
	
EndFunction

// Finalizes the export procedure. Writes export information to a file.
//
// Returns:
//   String - Full filename or file ID.
//
Function FinalizeUpload() Export
	
	CheckingContainerInitialization();
	
	DigestFileName = CreateFile(ExportImportDataInternal.Digest(), "CustomData");
	RecordDigest(DigestFileName);
	
	RecordUploadWarnings();
	RecordDuplicatesOfPredefined();
	
	RecordInformationAboutExtensions();
	
	NameOfContentFile = CreateFile(ExportImportDataInternal.PackageContents());
	WriteContainerContentsToFile(NameOfContentFile);
	
	For Each FoundFile In FindFiles(TempDirectory, "*", True) Do
		If FoundFile.IsFile() Then
			FileRecorded(FoundFile.FullName);
		EndIf;
	EndDo;
	
	DeleteFiles(TempDirectory);
	
	ZipArchives.ExitApp(Archive);
	
	If UploadTo Then
		If MultipartUpload = Undefined Then
			File = New File(Archive.FileName);
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("FileName", File.Name);
			AdditionalParameters.Insert("FileSize", File.Size());
			AdditionalParameters.Insert("FileType", "BackupDataArea_");
			AdditionalParameters.Insert("DataArea", SaaSOperations.SessionSeparatorValue());
			AdditionalParameters.Insert("DataAreaKey", Constants.DataAreaKey.Get());
			AdditionalParameters.Insert("S3Support", True);
			
			FileID = SaaSOperations.PlaceFileInStorageOfServiceManager(File, , AdditionalParameters);
			DeleteFiles(Archive.FileName);
			Return FileID;
		Else
			Result = ServiceProgrammingInterface.NewPart(MultipartUpload.FileID, MultipartUpload.Parts.Count() + 1);
			If Result.Type = "s3" Then
				SendPartOfS3File(Result, Archive.FileName);
				ServiceProgrammingInterface.CompleteMultipartUpload(MultipartUpload.FileID, MultipartUpload.Parts);
			Else
				SendPartOfDTFile(Result, Archive.FileName, True);
			EndIf;
			DeleteFiles(Archive.FileName);
			Return MultipartUpload.FileID;
		EndIf;
	ElsIf ExportToClient Then
		
		PartsExportedToClient = PartsExportedToClient + 1;
		Prefix = StrTemplate("data2xml-%1", Format(PartsExportedToClient, "NG=0"));
		TemporaryStorageFileName = FilesCTL.NewTemporaryStorageFile(Prefix, "zip", 120);
		UploadFileName = FilesCTL.FullTemporaryStorageFileName(TemporaryStorageFileName);
		MoveFile(Archive.FileName, UploadFileName);
		RegisterExportPart(PartsExportedToClient, TemporaryStorageFileName);
		
	EndIf;
	
	If FixState Then
		SaveEndState();
	EndIf;
	
	Return Archive.FileName;
	
EndFunction

#EndRegion

#Region Load

// Initializes an import procedure.
//
// Parameters:
//	FileData - String, UUID, Structure - Filename, file ID, or file data retrieved from the file using ZIPArchives.ReadArchive().
//	ImportParameters - See ExportImportData.DownloadCurAreaDataFromArchive.ImportParameters
//
Procedure InitializeDownload(Val FileData, Val ImportParameters) Export
	
	CheckingContainerInitialization(True);
	
	ForImport = True;
	ImportFileData = FileData;
	Parameters = ImportParameters;
	ProcessID = New UUID();
	
	InitializeImportVariables(FileData);

	PathSeparator = GetPathSeparator();
	 
	TempDirectory = GetTempFileName("zip") + PathSeparator;
	CreateDirectory(TempDirectory);
	
	CompositionFileName = GetFileName(ExportImportDataInternal.PackageContents());
	UnzipFileByName(CompositionFileName);
	
	Content = ExportImportDataInternal.ArchiveContent(TempDirectory + CompositionFileName);
	
	Content.Columns.Add("FullName", New TypeDescription("String"));
	For Each CompositionRow In Content Do
		CompositionRow.FullName = TempDirectory + CompositionRow.Directory + PathSeparator + CompositionRow.Name;
	EndDo;
		
	Content.Indexes.Add("FileKind, DataType");
	Content.Indexes.Add("FileKind");
	Content.Indexes.Add("FullName");
	Content.Indexes.Add("Directory");
	Content.Indexes.Add("Name");
	
	SearchParameters = ExportImportDataInternal.NewFileFromArchiveSearchParameters();
	SearchParameters.Name = GetFileName(ExportImportDataInternal.Digest());
	
	DigestFileParameters = ExportImportDataInternal.GetFileParametersFromArchive(
		Content, SearchParameters);
	DigestFileName = DigestFileParameters.Name;
	DigestDirectoryName = DigestFileParameters.Directory;
	
	UnzipFileByName(DigestFileName, DigestDirectoryName);
	
	ForTechnicalSupport = ExportImportDataInternal.ExportForTechnicalSupportMode(
		TempDirectory + DigestDirectoryName + PathSeparator + DigestFileName);
			
	SetCountOfProcessedObjects();
	InitializeState();
	
	ContainerInitialized = True;
	
EndProcedure

Procedure InitializeImportInThread(StreamParameters) Export
	
	InitializeVariablesInThread(StreamParameters);
	InitializeImportVariables(StreamParameters.FileData);
	InitializeStateVariables();
	
	ContainerInitialized = True;
	
EndProcedure

// Import parameters.
// 
// Returns: See ExportImportData.DownloadCurAreaDataFromArchive.ImportParameters
Function ImportParameters() Export
	
	CheckingContainerInitialization();
	
	If ForImport Then
		Return New FixedStructure(Parameters);
	Else
		Raise NStr("ru = 'Контейнер не инициализирован для загрузки данных.';
								|en = 'Export container is not initialized for data import.';");
	EndIf;
	
EndFunction

Procedure SetDownloadParameters(ImportParameters) Export
	
	Parameters = ImportParameters;
	
EndProcedure

// Gets a file from a directory.
//
// Parameters:
//	FileKind - String - Export file type.
//	DataType - String - Data type.
//
// Returns:
//	ValueTableRow
//
Function GetFileFromFolder(Val FileKind, Val DataType = Undefined) Export
	
	CheckingContainerInitialization();
	
	Files = GetFilesFromComposition(FileKind, DataType);
	If Files.Count() = 0 Then
		Return Undefined;
	ElsIf Files.Count() > 1 Then
		Template = NStr("ru = 'В выгрузке содержатся дубли файлов, вид файла: %1, тип данных: %2, количество: %3';
						|en = 'Export contains duplicate files, file type: %1, data type: %2, quantity: %3';");
		Raise StrTemplate(Template, FileKind, DataType, Files.Count());
	EndIf;
	
	Return Files[0];
	
EndFunction

// Gets an arbitrary file from directory.
//
// Parameters:
//	DataType - String - Data type.
//
// Returns:
//	String
//
Function GetCustomFile(Val DataType = Undefined) Export
	
	CheckingContainerInitialization();
	
	Files = GetFilesFromComposition(ExportImportDataInternal.CustomData() , DataType);
	If Files.Count() = 0 Then
		Raise StrTemplate(NStr("ru = 'В выгрузке отсутствует произвольный файл с типом данным %1.';
										|en = 'There is no arbitrary file with the %1 data type in export.';"),
			DataType);
	ElsIf Files.Count() > 1 Then
		Template = NStr("ru = 'В выгрузке содержатся дубли произвольных файлов, тип данных: %1, количество: %2';
						|en = 'Export contains duplicate arbitrary files, data type: %1, quantity: %2';");
		Raise StrTemplate(Template, DataType, Files.Count());
	EndIf;
	
	UnzipFile(Files[0]);
	
	Return Files[0].FullName;
	
EndFunction

// Get files from a catalog.
// 
// Parameters: 
//	FileKind - String - Export file type.
//	DataType - String - Data type.
// 
// Returns:  
//  See GetFileDescriptionsFromFolder
Function GetFilesFromDirectory(Val FileKind, Val DataType = Undefined) Export
	
	CheckingContainerInitialization();
	
	Return GetFileDescriptionsFromFolder(FileKind, DataType);
	
EndFunction

// Get file details from the catalog.
// 
// Parameters: 
//	FileKind - String - Export file type.
//	DataType - String - Data type.
// 
// Returns: 
//  ValueTable:
// * Name - String
// * Directory - String
// * FullName - String
// * Size - Number
// * FileKind - String
// * Hash - String
// * NumberOfObjects - Number
// * DataType - String
Function GetFileDescriptionsFromFolder(Val FileKind, Val DataType = Undefined) Export
	
	CheckingContainerInitialization();
	
	TableWithFiles = ExportImportDataInternal.NewContent();
	
	If TypeOf(FileKind) = Type("Array") Then 
		
		For Each SeparateView In FileKind Do
			AddFilesToValueTable(TableWithFiles, GetFilesFromComposition(SeparateView , DataType));
		EndDo;
		Return TableWithFiles;
		
	ElsIf TypeOf(FileKind) = Type("String") Then 
		
		Return GetFilesFromComposition(FileKind, DataType);
		
	Else
		
		Raise NStr("ru = 'Неизвестный вид файла';
								|en = 'Unknown file type';");
		
	EndIf;
	
EndFunction

// Get arbitrary files.
// 
// Parameters: 
//  DataType - String - Data type.
// 
// Returns: 
//  Array of String
Function GetArbitraryFiles(Val DataType = Undefined) Export
	
	CheckingContainerInitialization();
	
	Return GetDescriptionsOfArbitraryFiles(DataType).UnloadColumn("FullName");
	
EndFunction

// Get the full filename.
// 
// Parameters: 
//  RelativeFileName - String
// 
// Returns: 
//  String - Full filename.
Function GetFullFileName(Val RelativeFileName) Export
	
	CheckingContainerInitialization();
	
	CompositionRow = Content.Find(RelativeFileName, "Name");
	
	If CompositionRow = Undefined Then
		Raise StrTemplate(NStr("ru = 'В контейнере не обнаружен файл с относительным именем %1.';
										|en = 'There is no file with the %1 relative name in the container.';"),
			RelativeFileName);
	Else
		UnzipFile(CompositionRow);
		Return CompositionRow.FullName;
	EndIf;
	
EndFunction

// Gets the relative filename.
// 
// Parameters: 
//  FullFileName - String
// 
// Returns: 
//  String - Relative filename.
Function GetRelativeFileName(Val FullFileName) Export
	
	CheckingContainerInitialization();
	
	CompositionRow = FindCompositionLine(FullFileName, "FullName");
	
	If CompositionRow = Undefined Then
		Raise StrTemplate(NStr("ru = 'В контейнере не обнаружен файл %1.';
										|en = 'There is no file %1 in the container.';"),
			FullFileName);
	Else
		Return CompositionRow.Name;
	EndIf;
	
EndFunction

Procedure FinalizeDownload() Export
	
	CheckingContainerInitialization();
	ClearTemporaryImportingData();
		
	If FixState Then
		SaveEndState();
	EndIf;
	
EndProcedure

Procedure ClearTemporaryImportingData() Export
	
	DeleteFiles(TempDirectory);
	
EndProcedure

Procedure UnzipFile(FileRow) Export
	
	For ReverseIndex = 1 - FilesUsed.Count() To 0 Do
		FullFileName = FilesUsed[-ReverseIndex];
		File = New File(FullFileName);
		If Not File.Exists() Then
			FilesUsed.Delete(-ReverseIndex);
		ElsIf FileIsWritable(FullFileName) Then
			DeleteFiles(FullFileName);
			FilesUsed.Delete(-ReverseIndex);
		EndIf;
	EndDo;
	
	UnzipFileByName(FileRow.Name, FileRow.Directory);
	FilesUsed.Add(FileRow.FullName);
	
EndProcedure

// Reads an object from a file.
// 
// Parameters: 
//  File - ValueTableRow
// 
// Returns:
//  Arbitrary
Function ReadObjectFromFile(File) Export
	
	UnzipFile(File);
	Result = ExportImportData.ReadObjectFromFile(File.FullName);
	DeleteFiles(File.FullName);
	
	Return Result;
	
EndFunction

Function ThisIsContinuationOfDownload() Export
	
	ThisIsContinuationOfDownload = False;
	
	If Parameters.Property("ItIsPossibleToContinueLoadingProcedure") Then
		ThisIsContinuationOfDownload = Parameters.ItIsPossibleToContinueLoadingProcedure;
	EndIf;
	
	Return ThisIsContinuationOfDownload;
	
EndFunction

#EndRegion

#Region ExportImportState

Function FixState() Export
	Return FixState;	
EndFunction

Procedure SetNumberOfProcessedObjects(ProcessedObjectsCount1) Export
	StateRecording.ProcessedObjectsCount1 = ProcessedObjectsCount1;
	RefreshStatus(CurrentUniversalDate());
EndProcedure

Procedure SetStartDate(StartDate) Export
	StateRecording.StartDate = StartDate;
EndProcedure

Procedure AddTotalNumberOfObjects(Count) Export
	
	StateRecording.TotalObjectCount = StateRecording.TotalObjectCount + Count;
	
	CalculateObjectsByCompletionPercentage();
	
	AdditionDate = CurrentUniversalDate();
		
	RefreshStatus(AdditionDate);
	
	RecordState(AdditionDate);
	
EndProcedure

// Commit the start of the metadata object processing.
// 
// Parameters:
//  MetadataObject - String - Full name of the metadata object.
Procedure RecordStartOfMetadataObjectProcessing(MetadataObject) Export
	
	ProcessingStartDate = CurrentUniversalDate();
	MetadataObjectForProcessingFullName = MetadataObject;
	
	If IsChildThread() Then
		
		MessageData = New Structure();
		MessageData.Insert("ProcessingStartDate", DateToString(ProcessingStartDate));
		MessageData.Insert("MetadataObject", MetadataObject);
		
		ExportImportDataInternal.SendMessageToParentThread(
			ProcessID(),
			"RecordStartOfMetadataObjectProcessing",
			MessageData);
		
	Else
	
		CommitMetadataObjectProcessingStartInParentThread(MetadataObject, ProcessingStartDate);
		
	EndIf;
	
EndProcedure

// Commit the end of the metadata object processing.
// 
// Parameters:
//  MetadataObject - String - Full name of the metadata object.
Procedure CommitMetadataObjectProcessingEnd(MetadataObject) Export
	
	EndProcessingDate = CurrentUniversalDate();
	
	If IsChildThread() Then
		
		MessageData = New Structure();
		MessageData.Insert("EndProcessingDate", DateToString(EndProcessingDate));
		MessageData.Insert("MetadataObject", MetadataObject);
		MessageData.Insert("ProcessedObjectsCount1", ProcessedObjectsAfterCalculatingState);
		
		ExportImportDataInternal.SendMessageToParentThread(
			ProcessID(),
			"CommitMetadataObjectProcessingEnd",
			MessageData);
		
		ProcessedObjectsAfterCalculatingState = 0;
		
	Else
		
		CommitMetadataObjectProcessingEndInParentThread(
			MetadataObject,
			EndProcessingDate);
		
	EndIf;
	
EndProcedure

Function ObjectsToBeProcessedByMetadataObject(MetadataObject) Export
		
	NumberOfProcessedObjectsCountString = ProcessingObjectsCount.Find(
		MetadataObject.FullName(),
		"FullName");
		
	If NumberOfProcessedObjectsCountString = Undefined Then
		Return 0;
	EndIf;
	
	Return NumberOfProcessedObjectsCountString.NumberOfObjects;
	
EndFunction

Procedure ObjectProcessed() Export
	
	ObjectsAreProcessed(1);
	
EndProcedure

Procedure ObjectsAreProcessed(Count) Export
	
	ObjectProcessedDate = CurrentUniversalDate();
	
	If IsChildThread() Then
		
		ProcessedObjectsAfterCalculatingState = ProcessedObjectsAfterCalculatingState + Count;
		
		If ObjectProcessedDate < NextStateRecordMinimumDate Then
			Return;
		EndIf;
					
		MessageData = New Structure();
		MessageData.Insert("DateOfProcessing", DateToString(ObjectProcessedDate));
		MessageData.Insert("MetadataObject", MetadataObjectForProcessingFullName);
		MessageData.Insert("ProcessedObjectsCount1", ProcessedObjectsAfterCalculatingState);
		
		ExportImportDataInternal.SendMessageToParentThread(
			ProcessID(),
			"ObjectsAreProcessed",
			MessageData);
		
		ProcessedObjectsAfterCalculatingState = 0;
		NextStateRecordMinimumDate = ObjectProcessedDate + 5;
		
	Else
			
		CommitObjectsProcessingInParentThread(
			MetadataObjectForProcessingFullName,
			ObjectProcessedDate,
			Count);
		 
	EndIf;
	
EndProcedure

Procedure RecordEndOfProcessingMetadataObjects() Export
	
	ProcessingEndDate = CurrentUniversalDate();
	
	AddObjectsProcessedAfterCalculatingState();		

	If ForUnloading Or Not ExportImportDataInternal.IsFullBackup(Parameters) Then 
		StateRecording.EndPercentage = 100;	
	EndIf;
	
	StateRecording.ProcessedObjectsUpToCurrentMetadataObject = Undefined;
	StateRecording.NameOfMetadataObjectBeingProcessed = Undefined;
	StateRecording.ObjectProcessingEndDate = ProcessingEndDate;
	
	RecordState(ProcessingEndDate);
	
EndProcedure

#EndRegion

#Region ParallelExportImport

Function GetInitialParametersInThread() Export
	
	ParametersProperties = New Array();
	ParametersProperties.Add("ThreadsCount");
	
	InitializationParameters = New Structure();
	InitializationParameters.Insert("ForUnloading", ForUnloading);
	InitializationParameters.Insert("ForImport", ForImport);
	InitializationParameters.Insert("TempDirectory", TempDirectory);
	InitializationParameters.Insert("ForTechnicalSupport", ForTechnicalSupport);
	InitializationParameters.Insert("FixState", FixState);
	InitializationParameters.Insert("ProcessingObjectsCount", ProcessingObjectsCount);
	InitializationParameters.Insert("ProcessID", ProcessID);
	InitializationParameters.Insert("Parameters", New Structure());
	
	If ForImport Then
		InitializationParameters.Insert("FileData", ImportFileData);
		InitializationParameters.Insert("Content", Content);
	EndIf;
	
	For Each PropertyName In ParametersProperties Do
		
		If Parameters.Property(PropertyName) Then
			InitializationParameters.Parameters.Insert(PropertyName, Parameters[PropertyName]);
		EndIf;
		
	EndDo;
	
	Return New FixedStructure(InitializationParameters);
	
EndFunction

// Process the stream message.
// 
// Parameters:
//  MethodName - String - Method name.
//  MessageData - Structure - Message data.
Procedure ProcessThreadMessage(MethodName, MessageData) Export
	
	If MethodName = "RecordStartOfMetadataObjectProcessing" Then
		
		CommitMetadataObjectProcessingStartInParentThread(
			MessageData.MetadataObject,
			Date(MessageData.ProcessingStartDate));
			
	ElsIf MethodName = "CommitMetadataObjectProcessingEnd" Then
		
		CommitObjectsProcessing(
			MessageData.MetadataObject,
			MessageData.ProcessedObjectsCount1);
		CommitMetadataObjectProcessingEndInParentThread(
			MessageData.MetadataObject,
			Date(MessageData.EndProcessingDate));
			
	ElsIf MethodName = "ObjectsAreProcessed" Then
		
		CommitObjectsProcessingInParentThread(
			MessageData.MetadataObject,
			Date(MessageData.DateOfProcessing),
			MessageData.ProcessedObjectsCount1);
		
	ElsIf MethodName = "FileRecorded" Then
		
		AddFileToArchive(MessageData.ArchiveDirectory);
		
	ElsIf MethodName = "ExportEnd" Then 
		
		For Each ElementComposition In MessageData.Content Do
			FillPropertyValues(Content.Add(), ElementComposition);
		EndDo;
		
		For Each ArrayElement In MessageData.FilesUsed Do
			FilesUsed.Add(ArrayElement);
		EndDo;
		
		For Each ArrayElement In MessageData.Warnings Do
			Warnings.Add(ArrayElement);
		EndDo;
		
		DuplicatesOfPredefinedFromThread = Common.ValueFromXMLString(MessageData.DuplicatesOfPredefinedItems);
		
		For Each MapItem In DuplicatesOfPredefinedFromThread Do
			DuplicatesOfPredefinedItems.Insert(MapItem.Key, MapItem.Value);
		EndDo;
		
	Else
		Raise StrTemplate(NStr("ru = 'Неизвестный метод обработки сообщения потока: %1';
										|en = 'Unknown thread message processing method: %1';"), MethodName);
	EndIf;
	
EndProcedure

Function ProcessID() Export
	
	Return ProcessID;
	
EndFunction

Function IsChildThread() Export
	
	Return IsChildThread;
	
EndFunction

Function ThreadsCount() Export
	
	ThreadsCount = 0;
	
	If Parameters.Property("ThreadsCount") Then
		ThreadsCount = Parameters.ThreadsCount;
	EndIf;
	
	If Not ValueIsFilled(ThreadsCount) Or ThreadsCount < 1 Then
		ThreadsCount = 1;
	EndIf;
	
	Return ThreadsCount;
	
EndFunction

#EndRegion

#Region Other

// Returns: 
//  Array of String
Function Warnings() Export
	
	Return Warnings;
	
EndFunction

// Returns:
//  ValueTable
Function Content() Export
	
	Return Content;
	
EndFunction

// Returns:
//  Array of String
Function FilesUsed() Export
	
	Return FilesUsed;
	
EndFunction

// Returns:
//  Map
Function DuplicatesOfPredefinedItems() Export
	
	Return DuplicatesOfPredefinedItems;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Parameters:
// 	FileID - UUID
// 	
// Returns:
// 	Structure:
// 	* FileID - UUID
// 	* Parts - Array of String
// 	* Sent - Number
// 	
Function NewMultipartUpload(FileID) 
	
	NewMultipartUpload = New Structure;
	NewMultipartUpload.Insert("FileID", FileID);
	NewMultipartUpload.Insert("Parts", New Array);
	NewMultipartUpload.Insert("Sent", 0);

	Return NewMultipartUpload;
	
EndFunction

Function GetFilesFromComposition(Val FileKind = Undefined, Val DataType = Undefined)
	
	Filter = New Structure;
	If FileKind <> Undefined Then
		Filter.Insert("FileKind", FileKind);
	EndIf;
	If DataType <> Undefined Then
		Filter.Insert("DataType", DataType);
	EndIf;
	
	Return Content.Copy(Filter);
	
EndFunction

Procedure CheckingContainerInitialization(Val DuringInitialization = False)
	
	If ForUnloading And ForImport Then
		Raise NStr("ru = 'Некорректная инициализация контейнера.';
								|en = 'Incorrect container initialization.';");
	EndIf;
	
	If DuringInitialization Then
		
		If ContainerInitialized <> Undefined And ContainerInitialized Then
			Raise NStr("ru = 'Контейнер выгрузки уже был инициализирован ранее.';
									|en = 'Export container has been initialized.';");
		EndIf;
		
	Else
		
		If Not ContainerInitialized Then
			Raise NStr("ru = 'Контейнер выгрузки не инициализирован.';
									|en = 'Export container is not initialized.';");
		EndIf;
		
	EndIf;
	
EndProcedure

#Region ContainerFilesOperations

// Parameters: 
//  FileKind - String - File type.
//  Extension - String - Extension.
//  DataType - Undefined, String - Data type.
// 
// Returns: 
//  String - Full filename.
//
Function AppendFile(Val FileKind, Val Extension = "xml", Val DataType = Undefined)
	
	For ReverseIndex = 1 - FilesUsed.Count() To 0 Do
		FullFileName = FilesUsed[-ReverseIndex];
		File = New File(FullFileName);
		If File.Exists() And FileIsWritable(FullFileName) Then
			FileRecorded(FullFileName);
		EndIf;
	EndDo;
	
	FileName = GetFileName(FileKind, Extension, DataType);
	
	Directory = "";
	
	If FileKind = ExportImportDataInternal.Digest()
		Or FileKind = ExportImportDataInternal.Extensions() 
		Or FileKind = ExportImportDataInternal.CustomExtensions()
		Or FileKind = ExportImportDataInternal.DumpWarnings()
		Or FileKind = ExportImportDataInternal.PredefinedDataDuplicates() Then
		
		FileKind = "CustomData";
		
	EndIf;
	
	If Not ExportImportDataInternal.RulesForCreatingDirectoryStructure().Property(FileKind, Directory) Then
		Raise StrTemplate(NStr("ru = 'Вид файла %1 не поддерживается.';
										|en = 'The %1 file type is not supported.';"), FileKind);
	EndIf;
	
	If IsBlankString(Directory) Then
		FullName = TempDirectory + FileName;
	Else
			
		FilesCount = 0;
		If Not NumberOfFilesByType.Property(FileKind, FilesCount) Then
			FilesCount = 0;
		EndIf;
		FilesCount = FilesCount + 1;
		NumberOfFilesByType.Insert(FileKind, FilesCount);
		
		MaximumNumberOfFilesInDirectory = 1000;
		
		DirectoryNumber = Int((FilesCount - 1) / MaximumNumberOfFilesInDirectory) + 1;
		Directory = Directory + ?(DirectoryNumber = 1, "", Format(DirectoryNumber, "NG=0"));
		
		If FilesCount % MaximumNumberOfFilesInDirectory = 1 Then
			CreateDirectory(TempDirectory + Directory);
		EndIf;
		
		FullName = TempDirectory + Directory + GetPathSeparator() + FileName;
		
	EndIf;
	
	File = Content.Add();
	File.Name = FileName;
	File.Directory = Directory;
	File.FullName = FullName;
	File.DataType = DataType;
	File.FileKind = FileKind;
	
	FilesUsed.Add(FullName);
	
	Return FullName;
	
EndFunction

Procedure AddFileToArchive(ArchiveDirectory)
	
	ZipArchives.AppendFile(Archive, ArchiveDirectory);
	DeleteFiles(ArchiveDirectory);
	
	If UploadTo And ZipArchives.Size(Archive) > 1024 * 1024 * 1024 Then
		
		TimeFile = GetTempFileName();
		ZipArchives.SeparatePart(Archive, TimeFile);
		
		If MultipartUpload = Undefined Then
			Result = ServiceProgrammingInterface.StartMultipartUpload(
				ExportImportDataClientServer.NameOfDataUploadFile(), 0, 
				"DataAreaBackup", SaaSOperations.SessionSeparatorValue());
			MultipartUpload = NewMultipartUpload(Result.FileID);
		Else
			Result = ServiceProgrammingInterface.NewPart(MultipartUpload.FileID, 
				MultipartUpload.Parts.Count() + 1);
		EndIf;
		
		If Result.Type = "s3" Then
			SendPartOfS3File(Result, TimeFile);
		Else
			SendPartOfDTFile(Result, TimeFile, False);
		EndIf;
		
		DeleteFiles(TimeFile);
		
	ElsIf ExportToClient And ZipArchives.Size(Archive) > 10 * 1024 * 1024 Then 
		
		PartsExportedToClient = PartsExportedToClient + 1;
		Prefix = StrTemplate("data2xml-%1", Format(PartsExportedToClient, "NG=0"));
		TemporaryStorageFileName = FilesCTL.NewTemporaryStorageFile(Prefix, "zip", 120);
		UploadFileName = FilesCTL.FullTemporaryStorageFileName(TemporaryStorageFileName);
		ZipArchives.SeparatePart(Archive, UploadFileName);
		RegisterExportPart(PartsExportedToClient, TemporaryStorageFileName);
		ExpectPartsDownloading();
		
	EndIf;
	
EndProcedure 

Procedure RegisterExportPart(PartNumber, TemporaryStorageFileName)
	
	Record = InformationRegisters.ExportImportDataAreasParts.CreateRecordManager();
	Record.Id = StateRecording.Id;
	Record.PartNumber = PartNumber;
	Record.TemporaryStorageFileName = TemporaryStorageFileName;
	Record.Write();
	
EndProcedure

Procedure ExpectPartsDownloading()
	
	Query = New Query;
	Query.SetParameter("Id", StateRecording.Id);
	Query.Text =
	"SELECT
	|	COUNT(*) AS Count
	|FROM
	|	InformationRegister.ExportImportDataAreasParts AS ExportImportDataAreasParts
	|WHERE
	|	ExportImportDataAreasParts.Id = &Id";
	
	While True Do
		Selection = Query.Execute().Select();
		If Not Selection.Next() Or Selection.Count < 3 Then
			Return;
		EndIf;
		CommonCTL.Pause(5);
	EndDo;
	
EndProcedure

Function FileIsWritable(FileName)
	
	Try
		DataWriter = New DataWriter(FileName);
		DataWriter.Close();
		Return True;
	Except
		Return False;
	EndTry;
	
EndFunction

Function GetFileName(Val FileKind, Val Extension = "xml", Val DataType = Undefined)
	
	Return ExportImportDataInternal.GetFileName(
		FileKind,
		Extension,
		DataType);
	
EndFunction

#EndRegion

#Region ContainerContentsDescriptionOperations

Procedure WriteContainerContentsToFile(FileName)
	
	WriteStream = New XMLWriter();
	WriteStream.OpenFile(FileName);
	WriteStream.WriteXMLDeclaration();
	WriteStream.WriteStartElement("Data");
	
	FileType_ = XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "File");
	For Each String In Content Do
		
		FileInformation = XDTOFactory.Create(FileType_);
		
		FileInformation.Name = String.Name;
		FileInformation.Type = String.FileKind;
		If ValueIsFilled(String.Directory) Then
			FileInformation.Directory = String.Directory;
		EndIf;
		If ValueIsFilled(String.Size) Then
			FileInformation.Size = String.Size;
		EndIf;
		If ValueIsFilled(String.NumberOfObjects) Then
			FileInformation.Count = String.NumberOfObjects;
		EndIf;
		If ValueIsFilled(String.DataType) Then
			FileInformation.DataType = String.DataType;
		EndIf;
		
		XDTOFactory.WriteXML(WriteStream, FileInformation);
		
	EndDo;
	
	WriteStream.WriteEndElement();
	WriteStream.Close();
	
EndProcedure

Procedure RecordDigest(FileName)
	
	ConfigurationInformation = New SystemInfo();
	
	NumberOfObjects = Content.Total("NumberOfObjects");
	DataSize  = Content.Total("Size");
	
	DurationOfUnloading = CurrentSessionDate() - UploadStartTime;
	
	WriteStream = New XMLWriter();
	WriteStream.OpenFile(FileName);
	WriteStream.WriteXMLDeclaration();
	WriteStream.WriteStartElement("Digest");
	
	WriteStream.WriteStartElement("Platform");
	WriteStream.WriteText(ConfigurationInformation.AppVersion);
	WriteStream.WriteEndElement(); 
	
	If SaaSOperations.DataSeparationEnabled() Then
		WriteStream.WriteStartElement("Zone");
		WriteStream.WriteText(XMLString(SaaSOperations.SessionSeparatorValue()));
		WriteStream.WriteEndElement();
	EndIf; 
	
	WriteStream.WriteStartElement("ObjectCount");
	WriteStream.WriteText(Format(NumberOfObjects, "NG=0"));
	WriteStream.WriteEndElement();

	WriteStream.WriteStartElement("DataSize");
	WriteStream.WriteAttribute("Measure", "Byte");
	WriteStream.WriteText(Format(DataSize, "NFD=1; NG=0"));
	WriteStream.WriteEndElement();
	
	WriteStream.WriteStartElement("Duration");
	WriteStream.WriteAttribute("Measure", "Second");
	WriteStream.WriteText(Format(DurationOfUnloading, "NG=0"));
	WriteStream.WriteEndElement();
	
	If DurationOfUnloading <>0 Then
		WriteStream.WriteStartElement("SerializationSpeed");
		WriteStream.WriteAttribute("Measure", "Byte/Second");
		WriteStream.WriteText(Format(DataSize / DurationOfUnloading, "NFD=1; NG=0"));
		WriteStream.WriteEndElement();
	EndIf;
	
	If ForTechnicalSupport Then
		ExportType = "TechnicalSupport"
	Else                                  
		ExportType = "Ordinary"	
	EndIf;
	
	WriteStream.WriteStartElement("DataDumpType");	
	WriteStream.WriteText(ExportType); 
	WriteStream.WriteEndElement(); 
	
	WriteStream.WriteStartElement("DumpWarningsCount");
	WriteStream.WriteText(Format(Warnings.Count(), "NZ=0; NG=0;"));
	WriteStream.WriteEndElement();
	
	WriteStream.WriteStartElement("ContainsRegisteredChangesForExchangePlanNodes");
	WriteStream.WriteText(XMLString(ExportImportExchangePlansNodes.UploadRegisteredChangesForExchangePlanNodes(ThisObject)));
	WriteStream.WriteEndElement();
		
	WriteStream.WriteEndElement();
	WriteStream.Close();
	
EndProcedure

Procedure RecordUploadWarnings()
	
	NameOfUploadWarningsFile = AppendFile(ExportImportDataInternal.DumpWarnings(), "json",
		"CustomData");
	
	RecordingWarnings = New JSONWriter;
	RecordingWarnings.OpenFile(NameOfUploadWarningsFile);
	WriteJSON(RecordingWarnings, Warnings);
	RecordingWarnings.Close();
	
	FileRecorded(NameOfUploadWarningsFile);
	
EndProcedure

Procedure RecordInformationAboutExtensions()

	FileNameOfSuppliedExtensions = CreateFile(ExportImportDataInternal.Extensions(), "CustomData");
	RecordingSuppliedExtensions = New XMLWriter;
	RecordingSuppliedExtensions.OpenFile(FileNameOfSuppliedExtensions);
	RecordingSuppliedExtensions.WriteXMLDeclaration();
	RecordingSuppliedExtensions.WriteStartElement("Data");

	InformationAboutCustomExtensions = New Array;
	DataSeparationEnabled = SaaSOperations.DataSeparationEnabled();

	If DataSeparationEnabled Then
		SuppliedExtensions = ExtensionsSaaS.CurDataAreaExtensions();
	EndIf;
	
	NamesOfInstalledFixes = NamesOfInstalledFixes();
	
	AllAreaExtensionsList = New Array;
	For Each ConfigurationExtension In ConfigurationExtensions.Get() Do
		
		If DataSeparationEnabled
			And ConfigurationExtension.Scope <> ConfigurationExtensionScope.DataSeparation Then
			Continue;
		EndIf;
		
		ModifiesDataStructure = ConfigurationExtension.ModifiesDataStructure();
		If ModifiesDataStructure And Not ConfigurationExtension.Active Then
			Continue;
		EndIf;
		
		AllAreaExtensionsList.Add(ConfigurationExtension.Name);
		
	EndDo;
	
	ActivveExtensions = ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionApplied);
	For Each ConfigurationExtension In ActivveExtensions Do

		If DataSeparationEnabled Then
		
			If ConfigurationExtension.Scope <> ConfigurationExtensionScope.DataSeparation  Then
				Continue
			EndIf;
			
			RecordingSuppliedExtension = SuppliedExtensions.Find(ConfigurationExtension.UUID,
				"ExtensionToUse");
		
		Else
			RecordingSuppliedExtension = ExtensionsFrameVersions.Get(
				ConfigurationExtension.UUID);
		EndIf;
		
		ModifiesDataStructure = ConfigurationExtension.ModifiesDataStructure();
		
		If (ModifiesDataStructure And Not ConfigurationExtension.Active)
			Or AllAreaExtensionsList.Find(ConfigurationExtension.Name) = Undefined Then
			Continue;
		EndIf;
		
		If DataOfSuppliedExtensionIsSufficientForBackup(RecordingSuppliedExtension) Then

			ExtensionName = ?(ValueIsFilled(RecordingSuppliedExtension.Description),
				RecordingSuppliedExtension.Description,
				ConfigurationExtension.Synonym);
			
			RecordingSuppliedExtensions.WriteStartElement("Extension");
			RecordingSuppliedExtensions.WriteAttribute("ModifiesDataStructure", Format(ModifiesDataStructure,
				"BF=false; BT=true"));
			RecordingSuppliedExtensions.WriteAttribute("Name", ExtensionName);
			RecordingSuppliedExtensions.WriteAttribute("VersionUUID", String(
				RecordingSuppliedExtension.VersionID));
			
			If ModifiesDataStructure Then
				
				FrameData = GetFrameworkForExtensionVersion(RecordingSuppliedExtension.VersionID);
				If FrameData = Undefined Then
					If ExtensionsFrameVersions[ConfigurationExtension.UUID] <> Undefined Then
						FrameData = ConfigurationExtension.GetData();
						AddInformationAboutFrames(RecordingSuppliedExtensions, FrameData);
					Else
						WriteLogEvent(NStr("ru = 'Выгрузка данных. Не найдена каркасная версия расширения';
														|en = 'Data export. Extension framework version is not found';", 
							Common.DefaultLanguageCode()), 
							EventLogLevel.Warning, , ,
							StrTemplate(NStr("ru = 'Имя расширения: %1, Идентификатор версии: %2';
											|en = 'Extension name: %1. Version ID: %2';"), 
								ExtensionName,
								String(RecordingSuppliedExtension.VersionID)));
					EndIf;
				Else
					AddInformationAboutFrames(RecordingSuppliedExtensions, FrameData);
				EndIf;
				
			EndIf;
			
			RecordingSuppliedExtensions.WriteEndElement();

		Else
		
			If NamesOfInstalledFixes.Find(ConfigurationExtension.Name) <> Undefined Then
				Continue;
			EndIf;
			
			UserExtensionInformation = New Structure;
			UserExtensionInformation.Insert("Active", ConfigurationExtension.Active);
			UserExtensionInformation.Insert("SafeMode", ConfigurationExtension.SafeMode);
			UserExtensionInformation.Insert("UnsafeOperationWarnings",
				ConfigurationExtension.UnsafeActionProtection.UnsafeOperationWarnings);
			UserExtensionInformation.Insert("Name", ConfigurationExtension.Name);
			UserExtensionInformation.Insert("UseDefaultRolesForAllUsers", 
				ConfigurationExtension.UseDefaultRolesForAllUsers);
			UserExtensionInformation.Insert("UsedInDistributedInfoBase", 
				ConfigurationExtension.UsedInDistributedInfoBase);
			UserExtensionInformation.Insert("Synonym", ConfigurationExtension.Synonym);
			UserExtensionInformation.Insert("ModifiesDataStructure", ModifiesDataStructure);
			
			If UploadExtensionData Then
				NameOfUserExtensionDataFile = CreateCustomFile("cfe", "ExtensionData");
				
				ExtensionData = ConfigurationExtension.GetData();
				If ExtensionData = Undefined Then
					Raise StrTemplate(NStr("ru = 'Не удалось получить данные расширения: %1
						|Необходимо удалить данное расширение и повторить выгрузку.';
						|en = 'Cannot receive the extension data: %1
						|Delete the extension and try to export again.';"),
					ConfigurationExtension.Name);
				Else
					ExtensionData.Write(NameOfUserExtensionDataFile);
				EndIf;
				
				FileRecorded(NameOfUserExtensionDataFile);			
				UserExtensionInformation.Insert("FileName", GetRelativeFileName(
					NameOfUserExtensionDataFile));
			EndIf;
			
			UserExtensionInformation.Insert("UUID", XMLString(ConfigurationExtension.UUID));
				
			InformationAboutCustomExtensions.Add(UserExtensionInformation);

		EndIf;
	EndDo;

	RecordingSuppliedExtensions.WriteEndElement();
	RecordingSuppliedExtensions.Close();
	FileRecorded(FileNameOfSuppliedExtensions);

	FileNameOfCustomExtensions = AppendFile(ExportImportDataInternal.CustomExtensions(), "json",
		"CustomData");
	WritingCustomExtensions = New JSONWriter;
	WritingCustomExtensions.OpenFile(FileNameOfCustomExtensions);
	WriteJSON(WritingCustomExtensions, InformationAboutCustomExtensions);
	WritingCustomExtensions.Close();
	FileRecorded(FileNameOfCustomExtensions);

EndProcedure

Procedure AddInformationAboutFrames(RecordingSuppliedExtensions, FrameData)	
	FrameDataFileName = CreateCustomFile("cfe", "ExtensionData");
	FrameData.Write(FrameDataFileName);
	RecordingSuppliedExtensions.WriteAttribute("FileName", GetRelativeFileName(FrameDataFileName));
	RecordingSuppliedExtensions.WriteAttribute("IsFrame", Format(True, "BF=false; BT=true"));
EndProcedure

#EndRegion

Function GetFrameworkForExtensionVersion(VersionID)
	
	LinkExtensionVersion = Catalogs.BuiltInExtensionVersions.GetRef(VersionID);
	If Common.RefExists(LinkExtensionVersion) Then
		
		Return LinkExtensionVersion.ExtensionFrameworkStorage.Get();
				
	EndIf;
	
	Return Undefined;
		
EndFunction

Function DataOfSuppliedExtensionIsSufficientForBackup(RecordingSuppliedExtension)

	Result = False;
	BlankID = CommonClientServer.BlankUUID();
	If ValueIsFilled(RecordingSuppliedExtension)
		And RecordingSuppliedExtension.VersionID <> BlankID Then
	
		Result = True;
	
	EndIf;
	
	Return Result;

EndFunction

Function NamesOfInstalledFixes()

	Result = New Array;
	
	If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then 
		
		ModuleConfigurationUpdate = Common.CommonModule("ConfigurationUpdate");		
		InstalledPatches = ModuleConfigurationUpdate.InstalledPatches();
		
		For Each Patch In InstalledPatches Do
			Result.Add(Patch.Description);	
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function GetDescriptionsOfArbitraryFiles(Val DataType = Undefined)
	
	CheckingContainerInitialization();
	
	Return GetFilesFromComposition(ExportImportDataInternal.CustomData(), DataType);
	
EndFunction

Procedure AddFilesToValueTable(TableWithFiles, Val FilesFromComposition)
	
	If TableWithFiles = Undefined Then 
		TableWithFiles = FilesFromComposition;
		Return;
	EndIf;
	
	CommonClientServer.SupplementTable(FilesFromComposition, TableWithFiles);
	
EndProcedure

Procedure UnzipFileByName(Val Name, Val Path = "")
	
	ExportImportDataInternal.UnzipArchiveFile(
		Archive,
		TempDirectory,
		Name,
		Path);
	
EndProcedure

Procedure SendPartOfS3File(Result, FileName)
	
	URIStructure = CommonClientServer.URIStructure(Result.Address);
	If URIStructure.Schema = "https" Then
		SecureConnection = CommonClientServer.NewSecureConnection( , New OSCertificationAuthorityCertificates);
	EndIf;
	Join = New HTTPConnection(URIStructure.Host, URIStructure.Port, , , GetFilesFromInternet.GetProxy(URIStructure.Schema), 600, SecureConnection);
	Query = New HTTPRequest(URIStructure.PathAtServer, Result.Headers);
	Query.SetBodyFileName(FileName);
	Response = Join.CallHTTPMethod("PUT", Query);
	If Response.StatusCode <> 200 Then
		ServiceProgrammingInterface.CancelMultipartUpload(MultipartUpload.FileID);
		Raise StrTemplate(NStr("ru = 'Не удалось отправить часть файла, код ответа: %1%2%3';
										|en = 'Cannot send the file part. Response code: %1%2%3';"), 
			Response.StatusCode, Chars.LF, Response.GetBodyAsString());
	EndIf;
	MultipartUpload.Parts.Add(CommonCTL.HTTPHeader(Response, "ETag"));
			
EndProcedure

Procedure SendPartOfDTFile(Result, FileName, LastPart)
	
	SetPrivilegedMode(True);
	AccessParameters = New Structure;
	AccessParameters.Insert("URL", SaaSOperations.InternalServiceManagerURL());
	AccessParameters.Insert("UserName", SaaSOperations.ServiceManagerInternalUserName());
	AccessParameters.Insert("Password", SaaSOperations.ServiceManagerInternalUserPassword());
	SetPrivilegedMode(False);
	
	SendOptions = New Structure;
	SendOptions.Insert("Location", Result.Address);
	SendOptions.Insert("SetCookie", CommonCTL.HTTPHeader(Result, "SetCookie"));
	
	Result = DataTransferServer.SendPartOfFileToLogicalStorage(AccessParameters, SendOptions, FileName, LastPart, MultipartUpload.Sent);
	If Result = Undefined Then
		Raise NStr("ru = 'Не удалось отправить часть файла';
								|en = 'Cannot send the file part';");		
	EndIf;
	
	If Not LastPart Then
		MultipartUpload.Sent = Result;
	EndIf;		
	
EndProcedure

// Searches for a row from the end when the row count is more than 100K.
Function FindCompositionLine(Value, Column)
	
	For ReverseIndex = 1 - Content.Count() To Min(4 - Content.Count(), 0) Do
		If Content[-ReverseIndex][Column] = Value Then
			Return Content[-ReverseIndex];
		EndIf;
	EndDo;
	
	Return Content.Find(Value, Column);
	
EndFunction

Procedure AddWarning(Warning) Export
	
	Warnings.Add(Warning);
	
EndProcedure

Procedure AddDuplicatesOfPredefined(MetadataObject, Duplicates) Export
	
	DuplicatesOfPredefinedItems.Insert(MetadataObject.FullName(), Duplicates);
	
EndProcedure

Procedure RecordDuplicatesOfPredefined()
	
	If DuplicatesOfPredefinedItems.Count() = 0 Then
		Return;
	EndIf;
	
	FileName = AppendFile(ExportImportDataInternal.PredefinedDataDuplicates(), "json", "CustomData");
	
	JSONWriter = New JSONWriter;
	JSONWriter.OpenFile(FileName);
	WriteJSON(JSONWriter, DuplicatesOfPredefinedItems);
	JSONWriter.Close();
	
	FileRecorded(FileName);
	
EndProcedure

Procedure InitializeImportVariables(FileData)
	
	Archive = ExportImportDataInternal.ReadArchive(FileData);
	Warnings = New Array();

EndProcedure

Procedure InitializeExportVariables()
	
	Content = ExportImportDataInternal.NewContent();
	Content.Columns.Add("FullName", New TypeDescription("String"));
	
	Warnings = New Array();
	DuplicatesOfPredefinedItems = New Map();
	
EndProcedure

Procedure InitializeAdditionalUploadProperties()
	
	AdditionalProperties.Insert(
		"GeneralDataRequiringLinkMatching",
		ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading());
	
	AdditionalProperties.Insert(
		"LocalCacheOfDelimiterCompositions",
		New Map());
	
EndProcedure

Function DateToString(Date)
	
	Return Format(Date, "DF=yyyyMMddHHmmss;");
	
EndFunction

#Region ExportImportState

Procedure RefreshStatus(UpdateDate)
	
	AddObjectsProcessedAfterCalculatingState();
	
	TotalObjectCount = StateRecording.TotalObjectCount;
	ProcessedObjectsCount1 = StateRecording.ProcessedObjectsCount1;
	
	If TotalObjectCount = 0 Or ProcessedObjectsCount1 <= ObjectsAtCompletionPercentage  Then
		Return;
	EndIf;
	
	StateRecording.EndPercentage = Min(Int(ProcessedObjectsCount1 / TotalObjectCount * 100), 100); 	
	
	If ProcessedObjectsCount1 >= TotalObjectCount Or ObjectsProcessedDuringCurrentSession <= ObjectsAtCompletionPercentage Then
		Return;
	EndIf;
	
	SecondsSinceStartOfObjectProcessing = UpdateDate - StateRecording.ObjectProcessingStartedDate;
	ProcessObjectsRemaining = TotalObjectCount - ObjectsProcessedDuringCurrentSession;
	ProcessObjectsTimeLeft = Int(
		SecondsSinceStartOfObjectProcessing * ProcessObjectsRemaining / ObjectsProcessedDuringCurrentSession);
	StateRecording.EstimatedEndDate = UpdateDate + Max(ProcessObjectsTimeLeft, 5);
			
EndProcedure

Procedure RecordState(UpdateDate)
	
	StateRecording.UpdateDate = UpdateDate;
	StateRecording.Write();

EndProcedure

Procedure SaveEndState()
	CompletedOn = CurrentUniversalDate();
	StateRecording.ActualEndDate = CompletedOn;
	RecordState(CompletedOn);	
EndProcedure

Procedure CalculateObjectsByCompletionPercentage()
	ObjectsAtCompletionPercentage = Int(StateRecording.TotalObjectCount / 100);		
EndProcedure

Procedure AddObjectsProcessedAfterCalculatingState()
	StateRecording.ProcessedObjectsCount1 = StateRecording.ProcessedObjectsCount1 + ProcessedObjectsAfterCalculatingState;
	ObjectsProcessedDuringCurrentSession = ObjectsProcessedDuringCurrentSession + ProcessedObjectsAfterCalculatingState;
	ProcessedObjectsAfterCalculatingState = 0;
EndProcedure

Procedure SetCountOfProcessedObjects()
	
	If Not ExportImportData.NeedToCountObjectsNumber(Parameters) Then
		Return;
	EndIf;
	
	If ForImport Then
		
		ProcessingObjectsCount = ExportImportDataInternal.NumberOfImportObjectsByMetadataObjects(
			Content,
			Parameters.LoadableTypes,
			ForTechnicalSupport);
		
	Else
		
		ProcessingObjectsCount = ExportImportDataInternal.ImportObjectsdByMetadataObjectsCount(
			Parameters.TypesToExport,
			Parameters.UnloadedTypesOfSharedData,
			ForTechnicalSupport);
		
	EndIf;
	
	ProcessingObjectsCount.Indexes.Add("FullName");

EndProcedure

Procedure InitializeState()
	
	FixState = ExportImportData.ItIsNecessaryToRecordExportImportDataAreaState(
		Parameters); 

	If Not FixState Then
		Return;
	EndIf;
	
	InitializeStateVariables();
	
	TotalObjectCount = Undefined;
	
	If Not Parameters.Property("TotalObjectCount", TotalObjectCount) Then
		TotalObjectCount = ProcessingObjectsCount.Total("NumberOfObjects");
	EndIf;
		
	StateRecording = InformationRegisters.ExportImportDataAreasStates.CreateRecordManager();
	StateRecording.Id = Parameters.StateID;
	StateRecording.importDataArea = ForImport;
	StateRecording.StartDate = CurrentUniversalDate();
	StateRecording.TotalObjectCount = TotalObjectCount;
	
	CalculateObjectsByCompletionPercentage();
	
EndProcedure

Procedure InitializeStateVariables()
	
	NextStateRecordMinimumDate = Date(1, 1, 1);
	ProcessedObjectsAfterCalculatingState = 0;
	ObjectsProcessedDuringCurrentSession = 0;
	MetadataObjectForProcessingFullName = "";
	ProcessedObjectsByMetadata = New Map();
	
EndProcedure

// Commit the start of the metadata object processing in the parent thread.
// 
// Parameters:
//  MetadataObject - String - Full name of the metadata object.
//  ProcessingStartDate - Date - Processing start date.
Procedure CommitMetadataObjectProcessingStartInParentThread(MetadataObject, ProcessingStartDate)
	
	ProcessedObjectsByMetadata.Insert(MetadataObject, 0);
	
	If Not ValueIsFilled(StateRecording.ObjectProcessingStartedDate) Then
		StateRecording.ObjectProcessingStartedDate = ProcessingStartDate;
	EndIf;
	
	StateRecording.NameOfMetadataObjectBeingProcessed = GetMetadataObjectNameForProcessing(MetadataObject);
	
	RecordState(ProcessingStartDate);
	
EndProcedure

// Commit the end of the metadata object processing in the parent thread.
// 
// Parameters:
//  MetadataObject - String - Full name of the metadata object.
//  EndProcessingDate - Date - Processing end date.
Procedure CommitMetadataObjectProcessingEndInParentThread(MetadataObject, EndProcessingDate)
	
	AddObjectsProcessedAfterCalculatingState();
	
	ProcessedObjectsUpToCurrentMetadataObject = StateRecording.ProcessedObjectsUpToCurrentMetadataObject
		+ ProcessedObjectsByMetadata.Get(MetadataObject);
	ProcessedObjectsByMetadata.Delete(MetadataObject);
	
	StateRecording.ProcessedObjectsUpToCurrentMetadataObject = ProcessedObjectsUpToCurrentMetadataObject;
	StateRecording.NameOfMetadataObjectBeingProcessed = GetMetadataObjectNameForProcessing("");
	
	RecordState(EndProcessingDate);
	
EndProcedure

// Commit the object processing in the parent thread.
// 
// Parameters:
//  MetadataObject - String - Full name of the metadata object.
//  DateOfProcessing - Date - Object processing date.
//  Count - Number - Objects processed.
Procedure CommitObjectsProcessingInParentThread(MetadataObject, DateOfProcessing, Count)
	
	CommitObjectsProcessing(MetadataObject, Count);
	
	If ProcessedObjectsAfterCalculatingState <= ObjectsAtCompletionPercentage Then
		Return;
	EndIf;
		
	RefreshStatus(DateOfProcessing);
					
	If DateOfProcessing < NextStateRecordMinimumDate Then
		Return;
	EndIf;
				
	RecordState(DateOfProcessing);
	
	NextStateRecordMinimumDate = DateOfProcessing + 5;
	
EndProcedure

// Commit the object processing.
// 
// Parameters:
//  MetadataObject - String - Full name of the metadata object.
//  Count - Number - Objects processed.
Procedure CommitObjectsProcessing(MetadataObject, Count)
	
	ProcessedObjectsAfterCalculatingState = ProcessedObjectsAfterCalculatingState + Count;
	ProcessedObjectsCount1 = ProcessedObjectsByMetadata.Get(MetadataObject) + Count;
	
	ProcessedObjectsByMetadata.Insert(MetadataObject, ProcessedObjectsCount1);
	
EndProcedure

// Get the name of the metadata object to process.
// 
// Parameters:
//  MetadataObject - String - Full name of the metadata object.
// 
// Returns:
//  String - Name of the metadata object to process.
Function GetMetadataObjectNameForProcessing(MetadataObject)
	
	If ProcessedObjectsByMetadata.Count() <= 1 Then
		Return MetadataObject;
	EndIf;
	
	MaximumNameLength = 255;
	NameSeparator = ", ";
	ObjectsToProcess = New Array();
	
	For Each ProcessingElement In ProcessedObjectsByMetadata Do
		ObjectsToProcess.Add(ProcessingElement.Key);
	EndDo;
	
	NameOfMetadataObjectBeingProcessed = StrConcat(ObjectsToProcess, NameSeparator);
	
	If StrLen(NameOfMetadataObjectBeingProcessed) > MaximumNameLength Then
		
		NameOfMetadataObjectBeingProcessed = "";
		NameEnding = NStr("ru = 'и другие';
								|en = 'and other';");
		NameEndingLength = StrLen(NameEnding) + 1;
		NameSeparatorLength = StrLen(NameSeparator);
		
		For Each MetadataObjectName In ObjectsToProcess Do
			
			FutureNameLength = StrLen(NameOfMetadataObjectBeingProcessed)
				+ NameSeparatorLength
				+ StrLen(MetadataObjectName)
				+ NameEndingLength;
			
			If FutureNameLength > MaximumNameLength Then
				NameOfMetadataObjectBeingProcessed = NameOfMetadataObjectBeingProcessed + " " + NameEnding;
				Break;
			EndIf;
			
			NameOfMetadataObjectBeingProcessed = NameOfMetadataObjectBeingProcessed
				+ NameSeparator
				+ MetadataObjectName;
			
		EndDo;
		
	EndIf;
	
	Return NameOfMetadataObjectBeingProcessed;
	
EndFunction

#EndRegion

#Region ParallelExportImport

Procedure InitializeVariablesInThread(ContainerParameters)
	
	CheckingContainerInitialization(True);
	
	IsChildThread = True;
	ForUnloading = ContainerParameters.ForUnloading;
	ForImport = ContainerParameters.ForImport;
	TempDirectory = ContainerParameters.TempDirectory;
	ForTechnicalSupport = ContainerParameters.ForTechnicalSupport;
	FixState = ContainerParameters.FixState;
	ProcessingObjectsCount = ContainerParameters.ProcessingObjectsCount;
	ProcessID = ContainerParameters.ProcessID;
	Parameters = ContainerParameters.Parameters;
	
	If ForImport Then
		Content = ContainerParameters.Content;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Initialize

// Default container state initialization.

AdditionalProperties = New Structure();

NumberOfFilesByType = New Structure();
FilesUsed = New Array;

ForUnloading = False;
ForImport = False;
IsChildThread = False;

ExtensionsFrameVersions = New Map();

#EndRegion

#EndIf