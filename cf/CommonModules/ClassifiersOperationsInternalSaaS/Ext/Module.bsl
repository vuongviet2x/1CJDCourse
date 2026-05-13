///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "OnlineUserSupport.SaaS.ClassifiersOperations" subsystem.
// CommonModule.ClassifiersOperationsInternalSaaS.
//
// Server procedures and functions for importing classifiers from 1C-supplied data:
//  - Process 1C-supplied data descriptors
//  - Import shared classifiers
//  - Distribute separated classifiers by areas
//  - Handle classifier data in areas
//  - Handle CTL events
//  - Handle SSL events
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region IntegrationWithStandardSubsystemsLibrary

#Region SSLInfobaseUpdate

// StandardSubsystems.IBVersionUpdate

// Moves data from the default master data cache to the ClassifiersDataCache information register.
// 
//
Procedure MoveClassifiersDataCache() Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	ClassifiersOperations.WriteInformationToEventLog(
		NStr("ru = 'Перенос кэша поставляемых данных в подсистему ""Работа с классификаторами"". Начало обновления.';
			|en = 'Move default master data cache to the Classifiers subsystem. Update started.';"),
		False);
	
	ModuleSuppliedData = Common.CommonModule("SuppliedData");
	Descriptors = ModuleSuppliedData.DescriptorsOfSuppliedDataFromCache("Classifiers");
	
	For Each Descriptor In Descriptors Do
		
		FileData = ModuleSuppliedData.SuppliedDataFromCache(
			Descriptor.FileID);
		
		// If the file is missing from the cache, it cannot be cached to the "ClassifiersOperations" subsystem.
		// 
		If FileData = Undefined Then
			Continue;
		EndIf;
		
		FileDetails = ClassifiersOperations.ClassifierFileDataDetails(
			PutToTempStorage(FileData));
		
		For Each Characteristic In Descriptor.Characteristics Do
			If Characteristic.Code = "Id" Then
				FileDetails.Id = Characteristic.Value;
			ElsIf Characteristic.Code = "Version" Then
				FileDetails.Version = Number(Characteristic.Value);
			ElsIf Characteristic.Code = "Checksum" Then
				FileDetails.Checksum = Characteristic.Value;
			ElsIf Characteristic.Code = "VersionDetails" Then
				FileDetails.VersionDetails = Characteristic.Value;
			ElsIf Characteristic.Code = "Size" Then
				FileDetails.Size = Characteristic.Value;
			EndIf;
		EndDo;
		
		// Skipping incorrect cache data.
		If Not ValueIsFilled(FileDetails.Id) Then
			Continue;
		EndIf;
		
		ClassifiersOperations.UpdateClassifierCache(FileDetails);
		
	EndDo;
	
	// In SaaS, classifier files are cached in the 1C-supplied data.
	// When upgrading to v.2.4.1.10, the cache is moved to the information register "ClassifiersDataCache".
	// The obsolete data will be deleted using the job queue.
	JobParameters = New Structure;
	JobParameters.Insert("MethodName", "DeleteCacheOfSuppliedClassifiers");
	JobParameters.Insert("DataArea", -1);
	JobParameters.Insert("ScheduledStartTime", CurrentUniversalDate());
	JobParameters.Insert("RestartCountOnFailure", 3);
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	ModuleJobsQueue.AddJob(JobParameters);
	
	ClassifiersOperations.WriteInformationToEventLog(
		NStr("ru = 'Перенос кэша поставляемых данных в подсистему ""Работа с классификаторами"". Успешно завершено.';
			|en = 'Move default master data cache to the Classifiers subsystem. Completed successfully.';"),
		False);
	
EndProcedure

// In SaaS mode, classifier files are cached in the default master data.
// Therefore, you need to delete the cache for the removed classifiers.
//
// Parameters:
//  IDs - Array - Filter to narrow down default master data.
//              
//
Procedure DeleteCacheOfSuppliedClassifiers() Export
	
	SetPrivilegedMode(True);
	
	ModuleSuppliedData = Common.CommonModule("SuppliedData");
	Descriptors = ModuleSuppliedData.DescriptorsOfSuppliedDataFromCache("Classifiers");
		
	For Each Descriptor In Descriptors Do
		ModuleSuppliedData.DeleteSuppliedDataFromCache(
			Descriptor.FileID);
	EndDo;
	
	ClassifiersOperations.WriteInformationToEventLog(
		NStr("ru = 'Удален кэш поставляемых данных классификаторов при
			|переходе на версию БИП 2.4.1.10.';
			|en = 'During the update to OSL v.2.4.1.10,
			|the cache of the classifier default master data was cleaned up.';"),
		False);
	
EndProcedure

// End StandardSubsystems.IBVersionUpdate

#EndRegion

#EndRegion

#Region SaaSLibraryIntegration

#Region CTLSuppliedData

// The procedure is called when a new data notification is received.
// In the procedure body, check whether the application requires this data.
//  If it requires, select the Import check box.
// 
// Parameters:
//   Descriptor   - XDTODataObject Descriptor.
//   ToImport    - Boolean - A return value.
//
Procedure NewDataAvailable(Val Descriptor, ToImport) Export
	
	DataKind = Descriptor.DataType;
	If StrFind(DataKind, ClassifiersOperations.SuppliedDataKindClassifiers()) = 0 Then
		Return;
	EndIf;
	
	Id = "";
	Version        = "";
	For Each Characteristic In Descriptor.Properties.Property Do
		If Characteristic.Code = "Id" Then
			Id = Characteristic.Value;
		ElsIf Characteristic.Code = "Version" Then
			Version = Number(Characteristic.Value);
		EndIf;
	EndDo;
	
	// The classifier will be imported if new data was published in the service.
	Settings = ClassifiersOperations.ClassifierSettings(Id);
	ToImport = Settings <> Undefined;
	
	If Not ToImport Then
		Return;
	EndIf;
	
	// Populate versions for new classifiers.
	// 
	If Settings.Version = 0 Then
		Settings.Version = ClassifiersOperations.ProcessInitialClassifierVersion(Id);
	EndIf;
	
	ToImport = (Settings <> Undefined
		And Settings.Version < Version);
	
	If Not ToImport Then
		Return;
	EndIf;
	
	// The files of classifiers that are not auto-updated are cached in the "ClassifiersOperations" subsystem.
	// Therefore, the classifier version number is checked against the cache before importing.
	// This is intended to optimize the import of 1C-supplied files because after
	// updating the configuration, 1C-supplied data are imported from the Service Manager.
	// If the check is disabled, the files will be re-imported, which is excessive.
	// 
	// 
	// 
	If Not Settings.AutoUpdate Then
		VersionCache = ClassifiersOperations.ClassifierVersionCache(Id);
		If VersionCache >= Version Then
			ToImport = False;
		EndIf;
	EndIf;
	
EndProcedure

// The procedure is called after calling NewDataAvailable, it parses the data.
//
// Parameters:
//   Descriptor   - XDTODataObject Descriptor.
//   PathToFile   - String - The full name of the extracted file. 
//                  The file is deleted when the procedure completes.
//
Procedure ProcessNewData(Val Descriptor, Val PathToFile) Export
	
	DataKind = Descriptor.DataType;
	If StrFind(DataKind, ClassifiersOperations.SuppliedDataKindClassifiers()) = 0 Then
		Return;
	EndIf;
	
	FileDetails = ClassifiersOperations.ClassifierFileDataDetails(
		PutToTempStorage(
			New BinaryData(PathToFile)));
	
	For Each Characteristic In Descriptor.Properties.Property Do
		If Characteristic.Code = "Id" Then
			FileDetails.Id = Characteristic.Value;
		ElsIf Characteristic.Code = "Version" Then
			FileDetails.Version = Number(Characteristic.Value);
		ElsIf Characteristic.Code = "Checksum" Then
			FileDetails.Checksum = Characteristic.Value;
		ElsIf Characteristic.Code = "VersionDetails" Then
			FileDetails.VersionDetails = Characteristic.Value;
		ElsIf Characteristic.Code = "Size" Then
			FileDetails.Size = Characteristic.Value;
		EndIf;
	EndDo;
	
	ModuleSuppliedData = Common.CommonModule("SuppliedData");
	Settings = ClassifiersOperations.ClassifierSettings(FileDetails.Id);
	
	// The update will be performed interactively by the user.
	If Not Settings.AutoUpdate Then
		ClassifiersOperations.UpdateClassifierCache(FileDetails);
		ClassifiersOperations.WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Обработка классификатора %1 не требуется, т.к. настройка ОбновлятьАвтоматически имеет значение  False
					|подробнее см. реализацию метода РаботаСКлассификаторамиПереопределяемый.ПриДобавленииКлассификаторов
					|и ИнтеграцияПодсистемБИП.ПриДобавленииКлассификаторов.';
					|en = 'Processing the %1 classifier is not required, as the AutoUpdate setting is set to False
					|for more information, see the ClassifiersOperationsOverridable.OnAddClassifiers
					|and OSLSubsystemsIntegration.OnAddClassifiers method implementation.';"),
				FileDetails.Id),
			False);
		Return;
	EndIf;
	
	If Settings.SaveFileToCache
		Or Not Settings.SharedData Then
		ClassifiersOperations.UpdateClassifierCache(FileDetails);
		ClassifiersOperations.WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Данные классификатора %1 сохранены в кэше.';
					|en = 'Data of the %1 classifier is saved to cache.';"),
				FileDetails.Id),
			False);
	EndIf;
	
	ClassifiersOperations.WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Начало обработки Файл классификатора %1.';
				|en = 'Starting to process Classifier file %1.';"),
			FileDetails.Id),
		False);
	
	If Settings.SharedData Then
		
		Processed = False;
		AdditionalParameters = New Structure;
		
		ClassifiersOperations.OnImportClassifier(
			FileDetails,
			Processed,
			AdditionalParameters);
		
		If Processed Then
			
			If Settings.SharedDataProcessing Then
				UpdateAreasData = New Array;
				
				ClassifierSettings = New Structure;
				ClassifierSettings.Insert("Id",           FileDetails.Id);
				ClassifierSettings.Insert("Version",                  FileDetails.Version);
				ClassifierSettings.Insert("AdditionalParameters", AdditionalParameters);
				UpdateAreasData.Add(ClassifierSettings);
				
				UpdateClassifierInDataAreas(
					UpdateAreasData,
					Descriptor.FileGUID);
			EndIf;
			
		Else
			
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать поставляемые данные классификатора:
					|Идентификатор: %1
					|Версия: %2';
					|en = 'Failed to process default master data for the classifier.
					|ID: %1
					|Version: %2';"),
				FileDetails.Id,
				FileDetails.Version);
			
			ClassifiersOperations.WriteInformationToEventLog(ErrorMessage);
			
		EndIf;
	Else
		
		AreasForUpdate = ModuleSuppliedData.AreasRequiringProcessing(
			Descriptor.FileGUID,
			DataKind);
		
		PlanTheDistributionOfTheClassifierByOD(
			FileDetails,
			Descriptor.FileGUID,
			AreasForUpdate,
			DataKind);
		
		SetPrivilegedMode(True);
		ClassifiersOperations.SetClassifierVersion(
			FileDetails.Id,
			FileDetails.Version);
		SetPrivilegedMode(False);
		
	EndIf;
	
	ClassifiersOperations.WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Завершена обработка файла классификатора %1.';
				|en = 'Processing of the %1 classifier file is completed.';"),
			FileDetails.Id),
		False);
	
EndProcedure

// Runs if data processing is failed due to an error.
//
Procedure DataProcessingCanceled(Val Descriptor) Export
	
	ModuleSuppliedData = Common.CommonModule("SuppliedData");
	
	ClassifiersOperations.WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Обработка поставляемых данных не выполнена.
				|Поставляемые данные:
				|%1';
				|en = 'Failed to process default master data.
				|Default master data:
				|%1';"),
			ModuleSuppliedData.GetDataDescription(Descriptor)));
	
EndProcedure

#EndRegion

#Region BTSTaskQueue

// Updates the separated classifier data
// in the data area.
//
// Parameters:
//  FileDetails - Structure - see the ClassifiersOperations.ClassifierFileDataDetails function.
//  FileID   - UUID - File of the classifier being processed.
//  DataArea - Number - an infobase data area.
//  HandlerCode - String - handler code.
//
Procedure UpdatingTheSplitClassifier(
		FileDetails,
		FileID,
		DataArea,
		HandlerCode) Export
	
	// Before updating data, restore the classifier file from the cache.
	// 
	ResultOfGettingTheCache = ClassifiersOperations.ImportClassifierFileFromCache(
		FileDetails.Id);
	If Not ResultOfGettingTheCache.Error Then
		FileDetails.FileAddress = ResultOfGettingTheCache.FileAddress;
	Else
		Raise ResultOfGettingTheCache.ErrorMessage;
	EndIf;
	
	ModuleSuppliedData = Common.CommonModule("SuppliedData");
	Settings_Version = ClassifiersOperations.ClassifierVersion(
		FileDetails.Id);
	
	If Settings_Version = Undefined Then
		Settings_Version = 0;
	EndIf;
	
	// Populate versions for new classifiers.
	// 
	If Settings_Version = 0 Then
		Settings_Version = ClassifiersOperations.ProcessInitialClassifierVersion(
			FileDetails.Id);
	EndIf;
	
	// Skip if the latest classifier version is already imported to the area.
	// 
	If Settings_Version >= Number(FileDetails.Version) Then
		ModuleSuppliedData.AreaProcessed(
			FileID,
			HandlerCode,
			DataArea);
		Return;
	EndIf;
	
	Try
		
		Processed = False;
		ClassifiersOperations.OnImportClassifier(
			FileDetails,
			Processed,
			New Structure);
		
		If TransactionActive() Then
			
			While TransactionActive() Do
				RollbackTransaction();
			EndDo;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'По завершении выполнения обработчика ПриЗагрузкеКлассификатора классификатора %1 не была закрыта транзакция.';
					|en = 'The transaction was not closed after the OnImportClassifier handler of the %1 classifier had been finished.';"),
				FileDetails.Id);
			ClassifiersOperations.WriteInformationToEventLog(
				MessageText,
				True);
			
		EndIf;
		
		If Processed Then
			ModuleSuppliedData.AreaProcessed(
				FileID,
				HandlerCode,
				DataArea);
		Else
			
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать поставляемые данные классификатора:
					|Идентификатор: %1
					|Версия: %2
					|Область данных: %3';
					|en = 'Couldn''t process default master classifier data:
					|ID: %1
					|Version: %2
					|Data area: %3';"),
				FileDetails.Id,
				FileDetails.Version,
				DataArea);
			
			ClassifiersOperations.WriteInformationToEventLog(
				ErrorMessage,
				True);
			
			// Should rerun the operation.
			Raise ErrorMessage;
			
		EndIf;
		
	Except
		
		While TransactionActive() Do
			RollbackTransaction();
		EndDo;
		
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось обработать поставляемые данные классификатора:
				|Идентификатор: %1
				|Версия: %2
				|Область данных: %3,
				|Подробная информация об ошибке:
				|В результате выполнения обработчика ПриЗагрузкеКлассификатора возникло исключение:
				|%4';
				|en = 'Couldn''t process default master classifier data:
				|ID: %1
				|Version: %2
				|Data area: %3,
				|Detailed error information:
				|An exception is thrown after the OnImportClassifier handler is finished:
				|%4';"),
			FileDetails.Id,
			FileDetails.Version,
			DataArea,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		ClassifiersOperations.WriteInformationToEventLog(ErrorMessage);
		
		// Should rerun the operation.
		Raise ErrorMessage;
		
	EndTry;
	
EndProcedure

// Runs additional processing of separated classifier data
// after updating the classifier data.
//
// Parameters:
//  UpdateAreasData - Array - contains classifier update settings:
//    *Id - String - Classifier ID in the service.
//    *Version - Number  - a number of the imported classifier version.
//    *AdditionalParameters - Structure - additional parameters of processing areas.
//  FileID - UUID - Default master data file ID.
//  DataArea - Number - an infobase data area.
//  HandlerCode - String - handler code.
//
Procedure UpdatingTheSplitDataOfANonSplitClassifier(
		UpdateAreasData,
		FileID,
		DataArea,
		HandlerCode) Export
	
	ModuleSuppliedData = Common.CommonModule("SuppliedData");
	
	For Each ClassifierSettings In UpdateAreasData Do
		
		Try
			
			OSLSubsystemsIntegration.OnProcessDataArea(
				ClassifierSettings.Id,
				ClassifierSettings.Version,
				ClassifierSettings.AdditionalParameters);
			
			ClassifiersOperationsSaaSOverridable.OnProcessDataArea(
				ClassifierSettings.Id,
				ClassifierSettings.Version,
				ClassifierSettings.AdditionalParameters);
			
			If TransactionActive() Then
				
				While TransactionActive() Do
					RollbackTransaction();
				EndDo;
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'По завершении выполнения обработчика ПриОбработкеОбластиДанных классификатора %1 не была закрыта транзакция.';
						|en = 'The transaction was not closed after the OnProcessDataArea handler of the %1 classifier is finished.';"),
					ClassifierSettings.Id);
				ClassifiersOperations.WriteInformationToEventLog(
					MessageText,
					True);
				
			EndIf;
			
		Except
		
			While TransactionActive() Do
				RollbackTransaction();
			EndDo;
			
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать разделенные данные классификатора:
					|Идентификатор: %1
					|Версия: %2
					|Область данных: %3,
					|Подробная информация об ошибке:
					|В результате выполнения обработчика ПриОбработкеОбластиДанных возникло исключение:
					|%4';
					|en = 'Couldn''t process separated classifier data:
					|ID: %1
					|Version: %2
					|Data area: %3,
					|Detailed error information:
					|An exception is thrown after the OnProcessDataArea handler is finished:
					|%4';"),
				ClassifierSettings.Id,
				ClassifierSettings.Version,
				DataArea,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			ClassifiersOperations.WriteInformationToEventLog(
				ErrorMessage);
			
		EndTry;
		
	EndDo;
	
	ModuleSuppliedData.AreaProcessed(
		FileID,
		HandlerCode,
		DataArea);
	
EndProcedure

#EndRegion

#EndRegion

#Region OnlineUserSupportSubsystemsIntegration

// Adds a job for updating classifier data in areas.
//
// Parameters:
//  ClassifiersSettings - Array - contains classifier update settings:
//    *Id - String - Classifier ID in the service.
//    *Version - Number  - a number of the imported classifier version.
//    *AdditionalParameters - Structure - additional parameters of processing areas.
//
Procedure ScheduleDataAreasUpdate(ClassifiersSettings) Export
	
	If ClassifiersSettings.Count() > 0 Then
		
		MethodParameters = New Array;
		MethodParameters.Add(ClassifiersSettings);
		MethodParameters.Add(New UUID);
		
		JobParameters = New Structure;
		JobParameters.Insert("MethodName", "UpdateClassifierInDataAreas");
		JobParameters.Insert("Parameters", MethodParameters);
		JobParameters.Insert("DataArea", -1);
		JobParameters.Insert("ScheduledStartTime", CurrentUniversalDate());
		JobParameters.Insert("RestartCountOnFailure", 3);
		
		ModuleJobsQueue = Common.CommonModule("JobsQueue");
		ModuleJobsQueue.AddJob(JobParameters);
		
	EndIf;
	
EndProcedure

// Creates jobs for processing classifier data in areas.
//
// Parameters:
//  UpdateAreasData - Array - contains classifier update settings:
//    *Id - String - classifier ID in the service.
//    *Version - Number  - a number of the imported classifier version.
//    *AdditionalParameters - Structure - additional parameters of processing areas.
//  FileID - UUID - Default master data file ID.
//
Procedure UpdateClassifierInDataAreas(
		UpdateAreasData,
		FileID) Export
	
	ModuleSuppliedData = Common.CommonModule("SuppliedData");
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	
	For Each UpdateDataArea In UpdateAreasData Do
		
		HandlerCode = ClassifiersOperations.SuppliedDataKindClassifiers(
			UpdateDataArea.Id);
		
		AreasForUpdate = ModuleSuppliedData.AreasRequiringProcessing(
			FileID,
			HandlerCode);
			
		For Each DataArea In AreasForUpdate Do
			MethodParameters = New Array;
			MethodParameters.Add(UpdateAreasData);
			MethodParameters.Add(FileID);
			MethodParameters.Add(DataArea);
			MethodParameters.Add(HandlerCode);
			
			JobParameters = New Structure;
			JobParameters.Insert("MethodName", "UpdatingTheSplitDataOfANonSplitClassifier");
			JobParameters.Insert("Parameters", MethodParameters);
			JobParameters.Insert("DataArea", DataArea);
			JobParameters.Insert("ScheduledStartTime", CurrentUniversalDate());
			JobParameters.Insert("RestartCountOnFailure", 3);
			
			ModuleJobsQueue.AddJob(JobParameters);
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Adds classifier IDs that must be included to the configuration manifest for the Service Manager.
// 
//
// Parameters:
//  IDs - Array of String - A classifier ID to add to the manifest.
//
Procedure AddClassifiersIDs(IDs) Export
	
	SaaSIDs = New Array;
	OSLSubsystemsIntegration.OnDefineClassifiersIDs(
		SaaSIDs);
	ClassifiersOperationsSaaSOverridable.OnDefineClassifiersIDs(
		SaaSIDs);
	
	CommonClientServer.SupplementArray(
		IDs,
		SaaSIDs);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Creates jobs for updating classifiers in the
// infobase data areas.
//
// Parameters:
//  FileDetails - Structure - see the ClassifiersOperations.ClassifierFileDataDetails function.
//  FileID   - UUID - File of the classifier being processed.
//  AreasForUpdate - Массив с- contains a list of area codes.
//  HandlerCode       - String -  handler code.
//
Procedure PlanTheDistributionOfTheClassifierByOD(
		FileDetails,
		FileID,
		AreasForUpdate,
		HandlerCode)
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	
	For Each DataArea In AreasForUpdate Do
		
		MethodParameters = New Array;
		MethodParameters.Add(FileDetails);
		MethodParameters.Add(FileID);
		MethodParameters.Add(DataArea);
		MethodParameters.Add(HandlerCode);
		
		JobParameters = New Structure;
		JobParameters.Insert("MethodName", "UpdatingTheSplitClassifier");
		JobParameters.Insert("Parameters", MethodParameters);
		JobParameters.Insert("DataArea", DataArea);
		JobParameters.Insert("ScheduledStartTime", CurrentUniversalDate());
		JobParameters.Insert("RestartCountOnFailure", 3);
		
		ModuleJobsQueue.AddJob(JobParameters);
		
	EndDo;
	
EndProcedure

#EndRegion
