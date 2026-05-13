////////////////////////////////////////////////////////////////////////////////
// "Data import export" subsystem.
//
////////////////////////////////////////////////////////////////////////////////
//

// The module contains API procedures and functions
// for calling data import and export processes.


#Region Public

// Exports application data to a ZIP archive.
//  The archived data can be imported to another infobase or data area by function ExportImportData.ImportDataFromArchive().
//  
//
// Parameters:
//  ExportingParameters - Structure - Structure containing data export parameters:
//		* TypesToExport - Array of MetadataObject - Data must be exported to archive.
//      * UnloadUsers - Boolean - Export infobase users information.
//      * ExportUserSettings - Boolean - this parameter is ignored if ExportUsers = False.
//    The structure can also contain additional keys that can be processed
//      by arbitrary data export handlers.
//
// Returns:		
//  Structure - with the following fields::
//  * FileName - String - Archive file name.
//  * Warnings - Array of String - User notifications following the export.
//
Function UploadCurAreaDataToArchive(Val ExportingParameters) Export
	
	If Not CheckForRights() Then
		Raise NStr("ru = 'Недостаточно прав доступа для выгрузки данных';
								|en = 'Insufficient access rights to export data';");
	EndIf;
	
	If Not ExportingParameters.Property("TypesToExport") Then
		ExportingParameters.Insert("TypesToExport", New Array());
	EndIf;
	
	If Not ExportingParameters.Property("UnloadedTypesOfSharedData") Then
		ExportingParameters.Insert("UnloadedTypesOfSharedData", New Array());
	EndIf;
	
	If Not ExportingParameters.Property("UnloadUsers") Then
		ExportingParameters.Insert("UnloadUsers", False);
	EndIf;
	
	If Not ExportingParameters.Property("ExportUserSettings") Then
		ExportingParameters.Insert("ExportUserSettings", False);
	EndIf;
	
	If Not ExportingParameters.Property("UploadRegisteredChangesForExchangePlanNodes") Then
		ExportingParameters.Insert("UploadRegisteredChangesForExchangePlanNodes", False);
	EndIf;
	
	If Not ExportingParameters.Property("ThreadsCount") Then
		ExportingParameters.Insert("ThreadsCount", 0);
	EndIf;
			
	If ExportingParameters.ThreadsCount < 1 Then
		ExportingParameters.ThreadsCount = 1;
	EndIf;
	
	If Not ExportingParameters.Property("SkipCheckingExportedData") Then
		
		DataUploadErrors = DataUploadErrors(
 			ExportingParameters.TypesToExport,
 			ExportingParameters.UnloadedTypesOfSharedData);

		If ValueIsFilled(DataUploadErrors) Then

			PartsOfErrorText = New Array;
			PartsOfErrorText.Add(NStr("ru = 'Обнаруженные ошибки:';
											|en = 'Detected errors:';"));
			PartsOfErrorText.Add(Chars.LF);

			For Each DataUploadError In DataUploadErrors Do
				PartsOfErrorText.Add("● ");
				PartsOfErrorText.Add(DataUploadError);
				PartsOfErrorText.Add(Chars.LF);
			EndDo;

			ErrorText = StrConcat(PartsOfErrorText);

			WriteLogEvent(NStr("ru = 'Выгрузка данных. Обнаружены ошибки в выгружаемых данных';
											|en = 'Data export. Errors are found in data to export';",
				Common.DefaultLanguageCode()), EventLogLevel.Error, , , ErrorText);

			If SaaSOperations.DataSeparationEnabled() Then
				ErrorText = StrTemplate(
				NStr("ru = 'Перед исправлением рекомендуется создать резервную копию информационной базы средствами СУБД.
					 |
					 |%1';
					|en = 'Before fixing, create an infobase backup using the database management system.
					|
					|%1';"), ErrorText);
			EndIf;
			
			Raise ErrorText;

		EndIf;
		
	EndIf;
		
	Return ExportImportDataInternal.UploadCurAreaDataToArchive(ExportingParameters);
	
EndFunction

// Imports data from a ZIP archive containing XML files.
//
// Parameters:
//  ArchiveName - String, UUID, Structure - Filename, file ID, or file data retrieved from the file using ZIPArchives.ReadArchive().
//  ImportParameters - Structure - Structure containing data import parameters:
//		* LoadableTypes - Array of MetadataObject - Array of metadata objects whose data is to be extracted.
//        	If the parameter is assigned a value, the data of objects not included in the array will not be imported.
//        	If the parameter is empty, all the data from the export file will be imported.
//        	
//      * UploadUsers - Boolean - Import infobase users information.
//      * UploadUserSettings_ - Boolean - ignored if ImportUsers = False.
//      * UserMatching - ValueTable - Table with the following columns:
//        ** User - CatalogRef.Users - ID of the user obtained from the archive.
//        ** ServiceUserID - UUID - service user ID.
//        ** OldIBUserName - String - Old username of the infobase user.
//        ** NewIBUserName - String - New username of the infobase user.
//    Might contain additional keys that can be processed by custom data import handlers.
//      
//
// Returns:		
//  Structure - with the following fields::
//  * Warnings - Array of String - User notifications following the import.
//
Function DownloadCurAreaDataFromArchive(Val ArchiveName, Val ImportParameters) Export
	
	If Not CheckForRights() Then
		Raise NStr("ru = 'Недостаточно прав доступа для загрузки данных';
								|en = 'Insufficient rights for data import';");
	EndIf;
	
	SetPrivilegedMode(True);
	
	ExternalMonopolyMode = ExclusiveMode();
	UseMultithreading = ExportImportDataInternal.UseMultithreading(ImportParameters);
	
	Try
		
		If Not ExternalMonopolyMode Then
			SaaSOperations.SetExclusiveLock(UseMultithreading);
		EndIf;
		
		ImportResult1 = ExportImportDataInternal.DownloadCurAreaDataFromArchive(
			ArchiveName, ImportParameters);
		
		If Not ExternalMonopolyMode Then
			SaaSOperations.RemoveExclusiveLock(UseMultithreading);
		EndIf;
		
		Return ImportResult1;
		
	Except
		
		ExceptionText = CloudTechnology.DetailedErrorText(ErrorInfo());
		
		WriteLogEvent(NStr("ru = 'Загрузка данных из архива';
										|en = 'Data import from archive';", Common.DefaultLanguageCode()), 
			EventLogLevel.Error, , , ExceptionText);
		
		If Not ExternalMonopolyMode Then
			SaaSOperations.RemoveExclusiveLock(UseMultithreading);
		EndIf;
		
		Raise ExceptionText;
		
	EndTry;
	
EndFunction

// Checks whether the exported data is compatible with the infobase configuration.
//
// Parameters:
//  ArchiveName - String - path to export file.
//
// Returns: 
//	Boolean - True if the archive data can be imported to the current configuration.
//
Function UploadingToArchiveIsCompatibleWithCurConfiguration(Val ArchiveName) Export
	
	Directory = GetTempFileName();
	CreateDirectory(Directory);
	Directory = Directory + GetPathSeparator();
	
	Archiver = New ZipFileReader(ArchiveName);
	
	Try
		
		UploadDescriptionElement = Archiver.Items.Find("DumpInfo.xml");
		
		If UploadDescriptionElement = Undefined Then
			Raise StrTemplate(NStr("ru = 'В файле выгрузки отсутствует файл %1';
											|en = 'The %1 file is missing from the export file';"), "DumpInfo.xml");
		EndIf;
		
		Archiver.Extract(UploadDescriptionElement, Directory, ZIPRestoreFilePathsMode.Restore);
		
		UploadDescriptionFile = Directory + "DumpInfo.xml";
		
		UploadInformation = ExportImportDataInternal.ReadXDTOObjectFromFile(
			UploadDescriptionFile, XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "DumpInfo"));
		
		Result = ExportImportDataInternal.UploadingToArchiveIsCompatibleWithCurConfiguration(UploadInformation)
			And ExportImportDataInternal.UploadingToArchiveIsCompatibleWithCurVersionOfConfiguration(UploadInformation);
		
		DeleteFiles(Directory);
		Archiver.Close();
		
		Return Result;
		
	Except
		
		ExceptionText = CloudTechnology.DetailedErrorText(ErrorInfo());
		
		DeleteFiles(Directory);
		Archiver.Close();
		
		Raise ExceptionText;
		
	EndTry;
	
EndFunction

// Writes an object to file.
//
// Parameters:
//	Object - Arbitrary - Object being written.
//	FileName - String - File path.
//	Serializer - XDTOSerializer - Serializer.
//
Procedure WriteObjectToFile(Val Object, Val FileName, Serializer = Undefined) Export
	
	WriteStream = New XMLWriter();
	WriteStream.OpenFile(FileName);
	
	ExportImportDataInternal.WriteObjectToStream(Object, WriteStream, Serializer);
	
	WriteStream.Close();
	
EndProcedure

// Returns an object from file.
//
// Parameters:
//	FileName - String - File path.
//
// Returns:
//	Arbitrary - an object containing the read data
//
Function ReadObjectFromFile(Val FileName) Export
	
	ReaderStream = New XMLReader();
	ReaderStream.OpenFile(FileName);
	ReaderStream.MoveToContent();
	
	Object = ExportImportDataInternal.ReadObjectFromStream(ReaderStream);
	
	ReaderStream.Close();
	
	Return Object;
	
EndFunction

#Region HandlingReferencesToTypesExcludedFromUnloading

// Complements the array of types excluded from export and import.
// Intended for use in data processors OnFillTypesExcludedFromExportImport.
//
// Parameters:
// 	Types - Array of FixedStructure
//	Type - MetadataObject - Metadata objects excluded from export and import.
//	ActionWithLinks - String -  Action that should be taken upon detecting a reference to an object excluded from export.
//		Valid values are:
//			ExportImportData.OperationsWithRefsDontModify - No action will be taken.  
//			ExportImportData.OperationsWithRefsClear - Reference to the non-exportable object will be cleared.  
//			ExportImportData.OperationsWithRefsDontExportObject - Object containing the reference won't be exported.
//		  
// Use cases:
//  Procedure OnFillTypesExcludedFromExportImport(Types) Export
//		ExportImportData.AppendWithTypeExcludedFromImportExport(
//			Types,
//			Metadata.Catalogs.DataCheckAndAdjustmentHistoryAttachedFiles,
//			ExportImportData.OperationsWithRefsDontExportObject());
//	EndProcedure 
//
Procedure AddTypeExcludedFromUploadingUploads(Types, Type, ActionWithLinks) Export

	If Not (ActionWithLinks = ActionWithLinksDoNotChange() 
		Or ActionWithLinks = ActionWithClearLinks() 
		Or ActionWithLinks = ActionWithLinksDoNotUnloadObject()) Then	
		
		Raise StrTemplate(
			NStr("ru = 'Обнаружено неподдерживаемое действие ''%1'' при обнаружении ссылки на тип ''%2'' исключаемый из выгрузки';
				|en = 'Unsupported action ''%1'' was detected when a reference to the ''%2 '' type to be excluded from the export was detected';"),
			ActionWithLinks,
			Type);	
					
	EndIf;
	
	TypeDetails = New Structure("Type, Action", Type, ActionWithLinks);
	Types.Add(
		New FixedStructure(TypeDetails))
	
EndProcedure
	
// Returns:
//  String -
Function ActionWithLinksDoNotChange() Export
	Return "DontChange";	
EndFunction

// Returns:
//  String -
Function ActionWithClearLinks() Export
	Return "Clear";	
EndFunction

// Returns:
//  String -
Function ActionWithLinksDoNotUnloadObject() Export
	Return "NotExportObject";	
EndFunction

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated. Instead, use ExportImportData. Exports application data to a ZIP archive.
// The archived data can be imported to another infobase or data area by function ExportImportData.ImportDataFromArchive().
//  
//  
//
// Parameters:
//  ExportingParameters - Structure - Structure containing data export parameters:
//		* TypesToExport - Array of MetadataObject - Array of metadata objects whose data is to be archived.
//      * UnloadUsers - Boolean - Export infobase users information.
//      * ExportUserSettings - Boolean - this parameter is ignored if ExportUsers = False.
//    The structure can also contain additional keys that can be processed
//      by arbitrary data export handlers.
//
// Returns:
//	String - path to export file.
//
Function UploadDataToArchive(Val ExportingParameters) Export
	
	Return UploadCurAreaDataToArchive(ExportingParameters).FileName;
	
EndFunction

// Deprecated. Instead, use ExportImportData.
// 
//
// Parameters:
//  ArchiveName - String - Full name of the archive file.
//  ImportParameters - Structure - Structure containing data import parameters:
//		* LoadableTypes - Array of MetadataObject - Array of metadata objects whose data is to be extracted.
//        	If the parameter is assigned a value, the data of objects not included in the array will not be imported.
//        	If the parameter is empty, all the data from the export file will be imported.
//        	
//      * UploadUsers - Boolean - Import infobase users information.
//      * UploadUserSettings_ - Boolean - ignored if ImportUsers = False.
//      * UserMatching - ValueTable - Table with the following columns:
//        ** User - CatalogRef.Users - ID of the user obtained from the archive.
//        ** ServiceUserID - UUID - service user ID.
//        ** OldIBUserName - String - Old username of the infobase user.
//        ** NewIBUserName - String - New username of the infobase user.
//    Might contain additional keys that can be processed by custom data import handlers.
//      
//
Procedure DownloadDataFromArchive(Val ArchiveName, Val ImportParameters) Export
	
	DownloadCurAreaDataFromArchive(ArchiveName, ImportParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

Procedure PlaceErrorsOfExportedDataToTemporaryStorage(StorageAddress) Export 
	DataModelTypes = ExportImportDataAreas.GetAreaDataModelTypes();
	TypesOfSharedData = ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading();
	DataUploadErrors = DataUploadErrors(DataModelTypes, TypesOfSharedData);
	PutToTempStorage(DataUploadErrors, StorageAddress);
EndProcedure

// Parameters:
// 	DataModelTypes - Array of MetadataObject:
// 	TypesOfSharedData - FixedArray of MetadataObject:
// 	
// Returns:
// 	Array of String
Function DataUploadErrors(DataModelTypes, TypesOfSharedData) Export
	
	DataUploadErrors = New Array;
	
	Query = New Query;
	FileInfobase = Common.FileInfobase();

	RequestTextTemplateCheckLogger =
	"SELECT
	|	MIN(Table.Recorder) AS Recorder
	|FROM
	|	&Table AS Table
	|WHERE
	|	Table.Recorder.Ref IS NULL
	|
	|HAVING
	|	NOT MIN(Table.Recorder) IS NULL";

	For Each ToExportType In DataModelTypes Do

		If Not CommonCTL.IsRecordSet(ToExportType) 
			Or CommonCTL.IsIndependentRecordSet(ToExportType)
			Or CommonCTL.IsRecalculationRecordSet(ToExportType) Then
			Continue;
		EndIf;

		FullName = ToExportType.FullName();

		Query.Text = StrReplace(RequestTextTemplateCheckLogger, "&Table", FullName);

		Selection = Query.Execute().Select();

		If Selection.Next() And Not ValueIsFilled(Selection.Recorder) Then

			ErrorText = StrTemplate(
				NStr("ru = 'Обнаружены отсутствующие регистраторы в таблице %1.
					 |Рекомендуется выполнить удаление записей с отсутствующими регистраторами.';
					|en = 'Missing recorders are found in the %1 table.
					|We recommend that you delete records with missing recorders.';"), FullName) + " ";
			DataUploadErrors.Add(ErrorText);

		EndIf;

	EndDo;

	QueryTextTemplateCheckingForDuplicateDimensions = 
	"SELECT
	|	TRUE
	|FROM
	|	(SELECT TOP 1
	|		&TableFields
	|	FROM
	|		&RegisterTable AS RegisterTable
	|	
	|	GROUP BY
	|	&TableFields
	|	
	|	HAVING
	|		COUNT(*) > 1) AS NestedQuery";
	
	For Each DataModelType In DataModelTypes Do
		
		FullName = DataModelType.FullName();

		If CommonCTL.IsInformationRegister(DataModelType) Then
			
			CheckForDuplicateRecords = FileInfobase;
			If Not FileInfobase Then
				CheckForDuplicateRecords = DataModelType.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate
				And DataModelType.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.RecorderPosition;  
			EndIf;
			
			If Not CheckForDuplicateRecords Then
				Continue;
			EndIf;
						
			Dimensions = New Array;
			
			If DataModelType.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
				
				Dimensions.Add("RegisterTable.Period");
				
				If DataModelType.InformationRegisterPeriodicity = Metadata.ObjectProperties.InformationRegisterPeriodicity.RecorderPosition Then
					Dimensions.Add("RegisterTable.Recorder");				
				EndIf;
				
			EndIf;
			
			For Each MetadataDimensions In DataModelType.Dimensions Do
				Dimensions.Add("RegisterTable" + "." + MetadataDimensions.Name);
			EndDo;
			
			If Not ValueIsFilled(Dimensions) Then
				Continue;
			EndIf;
			
			Query.Text = StrReplace(QueryTextTemplateCheckingForDuplicateDimensions, "&RegisterTable", FullName);
			Query.Text = StrReplace(Query.Text, "&TableFields", StrConcat(Dimensions, ", "));
			
			If Not Query.Execute().IsEmpty() Then
				ErrorText = StrTemplate(
					NStr("ru = 'Обнаружено дублирование данных в таблице %1.
					|Рекомендуется выполнить удаление дублирующихся записей.';
					|en = 'Duplicate data is found in the %1 table.
					|We recommend that you delete duplicate records.';"),
					FullName) + " ";
				DataUploadErrors.Add(ErrorText);
			EndIf;
			
		EndIf;
		
	EndDo; 

	For Each TypeOfSharedData In TypesOfSharedData Do

		Try
			ExportImportSharedData.BeforeUnloadingType(
				Undefined, 
				Undefined, 
				TypeOfSharedData, 
				False);
		Except
			DataUploadErrors.Add(CloudTechnology.ShortErrorText(ErrorInfo()));
		EndTry;

	EndDo;
	
	For Each MetadataNotIncludedInExchangePlanError In MetadataErrorsNotIncludedInExchangePlan(DataModelTypes, False) Do
		DataUploadErrors.Add(MetadataNotIncludedInExchangePlanError);
	EndDo;
			
	Return DataUploadErrors;

EndFunction

// Checks if the passed metadata objects are included in the "ApplicationsMigration" exchange plan.
// 
// Parameters:
//  DataModelTypes - Array of MetadataObject - Data model types.:
// * Name - String -
// * Dimensions - Array of MetadataObject -
// ConsiderAddedInExtension - Boolean - Toggles the check for extension metadata objects.
// 
// Returns:
//  Array of String - Text error presentations.
Function MetadataErrorsNotIncludedInExchangePlan(DataModelTypes, ConsiderAddedInExtension = True) Export
	
	Errors = New Array;
	TypesToExclude = ExportImportDataInternalEvents.GetTypesExcludedFromUploadUpload();
		
	For Each TypeOfSharedData In DataModelTypes Do
	
		If Metadata.ExchangePlans.ApplicationsMigration.Content.Contains(TypeOfSharedData)
			Or Metadata.ScheduledJobs.Contains(TypeOfSharedData)
			Or Metadata.ExternalDataSources.Contains(TypeOfSharedData)
			Or Metadata.ExchangePlans.Contains(TypeOfSharedData) 
			Or (Not ConsiderAddedInExtension And TypeOfSharedData.ConfigurationExtension() <> Undefined)
			Or TypesToExclude.Find(TypeOfSharedData) <> Undefined Then
			Continue;
		EndIf;
			
		ModuleName = "ExportImportDataOverridable.OnFillTypesExcludedFromExportImport";
		ErrorTextTemplate = NStr("ru = 'Объект метаданных %1 не включен в план обмена Миграция приложений. 
			|Его необходимо включить в состав плана обмена Миграция приложений с запрещенной авторегистрацей. 
			|В случае, если объект не должен выгружаться, необходимо дополнительно добавить его в исключаемые из выгрузки. См. %2';
			|en = 'The %1 metadata object is not included in the Application migration exchange plan. 
			|Include it in the Application migration exchange plan with the disabled autoregistration. 
			|If the object must not be exported, exclude it from the export. For more information, see %2';");
		Errors.Add(StrTemplate(ErrorTextTemplate, TypeOfSharedData.FullName(), ModuleName));
		
	EndDo;
	
	Return Errors;
	
EndFunction

Function NeedToCountObjectsNumber(ExportImportParameters) Export
	
	Return ItIsNecessaryToRecordExportImportDataAreaState(ExportImportParameters)
		Or UseMultithreadedExportImport(ExportImportParameters);
	
EndFunction

Function UseMultithreadedExportImport(ExportImportParameters) Export
	
	If Not ValueIsFilled(ExportImportParameters) Then
		Return False;
	EndIf;
	
	If ExportImportParameters.Property("ThreadsCount")
		And ExportImportParameters.ThreadsCount > 1 Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function ItIsNecessaryToRecordExportImportDataAreaState(ExportImportParameters) Export
	
	If Not ValueIsFilled(ExportImportParameters) Then
		Return False;
	EndIf;
	
	StateID = Undefined;
	ExportImportParameters.Property("StateID", StateID);
	
	Return ValueIsFilled(StateID);
	
EndFunction

Function DataAreaExportImportState(StateID) Export
	
	Query = New Query("SELECT
	|	ExportImportDataAreasStates.DataAreaAuxiliaryData AS DataArea,
	|	ExportImportDataAreasStates.importDataArea AS importDataArea,
	|	ExportImportDataAreasStates.EndPercentage,
	|	ExportImportDataAreasStates.EstimatedEndDate,
	|	ExportImportDataAreasStates.NameOfMetadataObjectBeingProcessed,
	|	ExportImportDataAreasStates.ProcessedObjectsCount1,
	|	ExportImportDataAreasStates.ProcessedObjectsUpToCurrentMetadataObject,
	|	ExportImportDataAreasStates.StartDate,
	|	ExportImportDataAreasStates.ObjectProcessingStartedDate <> DATETIME(1, 1, 1) AS
	|		ObjectProcessingStarted,
	|	ExportImportDataAreasStates.ObjectProcessingEndDate <> DATETIME(1, 1, 1) AS
	|		ObjectProcessingCompleted,
	|	ExportImportDataAreasStates.ActualEndDate AS ActualEndDate
	|FROM
	|	InformationRegister.ExportImportDataAreasStates AS ExportImportDataAreasStates
	|WHERE
	|	ExportImportDataAreasStates.Id = &Id");
	
	Query.SetParameter("Id", StateID);

	ResultTable2 = Query.Execute().Unload();
	
	If Not ValueIsFilled(ResultTable2) Then
		Return Undefined;		
	EndIf;
	
	Return Common.ValueTableToArray(ResultTable2)[0];
	
EndFunction

Function DataAreaExportImportStateView(DataAreaExportImportState, TimeZone = Undefined) Export
		
	If Not DataAreaExportImportState.ObjectProcessingStarted Then
		
		Return ExportImportDataClientServer.ExportImportDataAreaPreparationStateView(
			DataAreaExportImportState.importDataArea);
				
	ElsIf DataAreaExportImportState.ObjectProcessingCompleted Then
		
		If DataAreaExportImportState.importDataArea Then
			StatusPresentation = NStr("ru = 'Выполняется завершение загрузки данных.';
											|en = 'Completing the data import.';");
		Else
			StatusPresentation = NStr("ru = 'Выполняется завершение выгрузки данных.';
											|en = 'Completing the data export.';");
		EndIf;	
		
	Else
		
		StateViewParts = New Array();
		
		If DataAreaExportImportState.importDataArea Then
			FirstPartOfStateRepresentation = NStr("ru = 'Выполняется загрузка данных.';
													|en = 'Importing data.';");
		Else
			FirstPartOfStateRepresentation = NStr("ru = 'Выполняется выгрузка данных.';
													|en = 'Exporting data.';");
		EndIf;
		
		StateViewParts.Add(FirstPartOfStateRepresentation);		
		
		EstimatedEndDate = DataAreaExportImportState.EstimatedEndDate;
		If ValueIsFilled(EstimatedEndDate) Then
			
			If TimeZone = Undefined Then 
				TimeZone = SessionTimeZone();
			EndIf;
			
			EstimatedEndDateInLocalTime = ToLocalTime(EstimatedEndDate, TimeZone);
			CurrentDateInLocalTime = ToLocalTime(CurrentUniversalDate(), TimeZone);
			
			If BegOfDay(CurrentDateInLocalTime) = BegOfDay(EstimatedEndDateInLocalTime) Then
				EndDatePresentationTemplate = NStr("ru = 'Расчетное время завершения %1.';
														|en = 'Estimated completion time: %1.';");
				FormatString = "DF='HH:mm';";
			Else
				EndDatePresentationTemplate = NStr("ru = 'Расчетная дата завершения %1.';
														|en = 'Estimated completion date: %1.';");
				FormatString = "DF='dd MMMM HH:mm';";
			EndIf;

			StateRepresentationSecondPart = StrTemplate(
				EndDatePresentationTemplate,
				Format(EstimatedEndDateInLocalTime, FormatString));
			
			StateViewParts.Add(StateRepresentationSecondPart);			
		
		EndIf;

		StatusPresentation = StrConcat(StateViewParts, " ");
		
	EndIf;
		
	Return StatusPresentation;
	
EndFunction

Function ExportImportDataAreaEndPercentage(DataAreaExportImportState) Export
		
	If DataAreaExportImportState = Undefined 
		Or Not DataAreaExportImportState.ObjectProcessingStarted
		Or DataAreaExportImportState.ObjectProcessingCompleted Then	
		Return Undefined;
	EndIf;
	
	Return DataAreaExportImportState.EndPercentage;
			
EndFunction

#EndRegion

#Region Private

// Checks whether the user has the DataAdministration right
//
// Returns:
//	Boolean - True if it exists, otherwise, False.
//
Function CheckForRights()
	
	Return AccessRight("DataAdministration", Metadata);
	
EndFunction

#EndRegion