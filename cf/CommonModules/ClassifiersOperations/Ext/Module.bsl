///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "OnlineUserSupport.ClassifiersOperations" subsystem.
// CommonModule.ClassifiersOperations.
//
// Server procedures and functions for importing classifiers:
//  - Get modified classifier files by a scheduled job in silent mode
//  - Get and process up-to-date classifier files
//  - Get information on the latest classifier versions
//  - Import classifier files
//  - Configure classifier import
//  - Manage classifier cache
//  - Handle CTL events
//  - Handle SSL events
//  
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Imports the classifier update and processes data.
//
// Parameters:
//  IDs - Array of String - classifier IDs in the service
//                   whose update needs to be imported.
//
// Returns:
//  Structure - The classifier update result:
//    * ErrorCode - String - String code of the occurred error that
//                  can be processed by the calling functionality:
//                    - <Пустая строка> - Updated successfully.
//                    - "ОбновлениеНеТребуется" - an update is not found.
//                    - "НеверныйЛогинИлиПароль" - invalid username or password.
//                    - "ПревышеноКоличествоПопыток" - you exceeded the number of attempts
//                      to receive updates with incorrect username and password.
//                    - "ОшибкаПодключения" - an error occurred when connecting to the service.
//                    - "ОшибкаСервиса" - an internal service error.
//                    - "НеизвестнаяОшибка" - an unknown (unprocessable) error
//                      occurred when receiving information.
//                    - "НеОбработан" - A classifier file is successfully imported but not processed.
//                      An error can occur if file processing algorithms are missing.
//                      See the ClassifiersOperationsOverridable.OnImportClassifier
//                      and OSLSubsystemsIntegration.OnImportClassifier procedures.
//                    - "СервисВременноНеДоступен" - the service is temporarily unavailable due to maintenance.
//                    - "НеизвестныйКлассификаторИлиПрограмма" - a classifier or an application
//                      is not found in the service by the passed ID.
//                    - "ФайлНеЗагружен" - errors occurred when importing classifier files.
//                    - "НетДоступаКПрограмме" - there is no access to the application on 1C:ITS portal.
//    *ErrorMessage  - String, FormattedString - an error message for the user.
//    *ErrorInfo - String, FormattedString - an error message for the administrator.
//
Function RunClassifierUpdate(IDs) Export
	
	UpdateResult = New Structure;
	UpdateResult.Insert("ErrorCode",          "");
	UpdateResult.Insert("ErrorMessage",  "");
	UpdateResult.Insert("ErrorInfo", "");
	
	If Common.DataSeparationEnabled() Then
		AuthenticationData = Undefined;
	Else
		Result = AuthenticationData();
		If Result.Error Then
			UpdateResult.ErrorCode = InvalidUsernameOrPasswordErrorCode();
			UpdateResult.ErrorMessage = Result.ErrorInfo;
			UpdateResult.ErrorInfo = Result.ErrorInfo;
			Return UpdateResult;
		EndIf;
		AuthenticationData = Result.AuthenticationData;
	EndIf;
	
	// 1. Check update availability.
	CheckUpdateAvailability();
	
	// 2. Populate versions for new classifiers.
	// 
	SetInitialVersionNumberOfClassifiers(IDs);
	
	// 3. Get the info on the latest classifier versions and import the files from the service or cache.
	// 
	If Common.DataSeparationEnabled() Then
		OperationResult = InternalDetermineClassifiersDataInSaaS(
			IDs);
	Else
		OperationResult = InternalDetermineClassifiersData(
			IDs,
			AuthenticationData);
	EndIf;
	
	If OperationResult.Error Then
		FillPropertyValues(
			UpdateResult,
			OperationResult,
			"ErrorCode, ErrorMessage, ErrorInfo");
		Return UpdateResult;
	EndIf;
	
	// 4. Process files by the subsystem consumers.
	UnprocessedClassifiers = ProcessClassifiersFiles(
		OperationResult.ClassifiersData);
	
	If UnprocessedClassifiers.Count() > 0 Then
		UpdateResult.ErrorCode = ErrorCodeUnprocessed();
		UpdateResult.ErrorMessage  = NStr("ru = 'Не удалось обработать обновления классификаторов.';
														|en = 'Couldn''t process classifier updates.';");
		UpdateResult.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'При обработке загруженных обновлений классификаторов %1 возникли ошибки.';
				|en = 'Errors occurred when processing imported updates of the %1 classifiers.';"),
			StrConcat(UnprocessedClassifiers, ","));
	EndIf;
	
	Return UpdateResult;
	
EndFunction

// Checks for available classifier updates in the classifier service
// or in the  default master data cache. In SaaS, saving information on
// latest classifier versions to cache will be optional, that is,
// depending on the classifier setup in the overridable
// ClassifiersOperationsOverridable.OnAddClassifiers method and in the
// OSLSubsystemsIntegration.OnAddClassifiers(Classifiers) method. If
//  the SaveFileToCache value is set to True in the classifier settings,
// receiving files of latest classifier versions will be available, otherwise, the method will return the
// blank AvailableVersions table.
//
// Parameters:
//  IDs - Array of String - classifier IDs in the service
//                   whose update needs to be imported.
//
// Returns:
//  Structure - information on available updates.:
//    * ErrorCode - String - String code of the occurred error that
//                  can be processed by the calling functionality:
//                    - <Пустая строка> - Updated successfully.
//                    - "НеверныйЛогинИлиПароль" - invalid username or password.
//                    - "ПревышеноКоличествоПопыток" - you exceeded the number of attempts
//                      to receive updates with incorrect username and password.
//                    - "ОшибкаПодключения" - an error occurred when connecting to the service.
//                    - "ОшибкаСервиса" - an internal service error.
//                    - "НеизвестнаяОшибка" - an unknown (unprocessable) error
//                      occurred when receiving information.
//                    - "СервисВременноНеДоступен" - the service is temporarily unavailable due to maintenance.
//                    - "НеизвестныйКлассификаторИлиПрограмма" - a classifier or an application
//                      is not found in the service by the passed ID.
//                    - "НетДоступаКПрограмме" - there is no access to the application on 1C:ITS portal.
//                    - "ОбновлениеНеТребуется" - latest classifier versions are imported.
//    *ErrorMessage  - String, FormattedString - an error message for the user.
//    *ErrorInfo - String, FormattedString - an error message for the administrator.
//    *AvailableVersions - Array - contains information on available updates
//      **ID      - String - classifier ID in the service.
//      **Version             - String - Relevant version number.
//      **VersionDescription     - String - details of version changes.
//      **FileId - Structure - The details of the classifier file to be imported.
//                             ClassifiersOperations.GetClassifiersFiles
//      **FileId - String - The details of the classifier file to be imported.
//                                      ClassifiersOperations.GetClassifiersFiles
//      **Size             - String - File size.
//      **Name       - String - Classifier name.
//
Function AvailableClassifiersUpdates(IDs) Export
	
	Return InternalAvailableClassifiersUpdates(
		IDs,
		Undefined,
		True);
	
EndFunction

// Imports a classifier update file and processes it.
// Use it together with the ClassifiersOperations.AvailableClassifiersUpdates function.
//
// Parameters:
//  Id      - String - classifier ID in the service.
//  Version             - String - Relevant version number.
//  FileID - String - A file ID that will be used for import.
//                       See the ClassifiersOperations.AvailableClassifiersUpdates function.
//
// Returns:
//  Structure - A classifier update result:
//    * ErrorCode - String - String code of the occurred error that
//                  can be processed by the calling functionality:
//                    - <Пустая строка> - Updated successfully.
//                    - "НеверныйЛогинИлиПароль" - invalid username or password.
//                    - "ПревышеноКоличествоПопыток" - you exceeded the number of attempts
//                      to receive updates with incorrect username and password.
//                    - "ОшибкаПодключения" - an error occurred when connecting to the service.
//                    - "ОшибкаСервиса" - an internal service error.
//                    - "НеизвестнаяОшибка" - an unknown (unprocessable) error
//                      occurred when receiving information.
//                    - "НеОбработан" - A classifier file is successfully imported but not processed.
//                      An error can occur if file processing algorithms are missing.
//                      See the ClassifiersOperationsOverridable.OnImportClassifier
//                      and OSLSubsystemsIntegration.OnImportClassifier procedures.
//                    - "СервисВременноНеДоступен" - the service is temporarily unavailable due to maintenance.
//                    - "НеизвестныйКлассификаторИлиПрограмма" - a classifier or an application
//                      is not found in the service by the passed ID.
//                    - "ФайлНеЗагружен" - errors occurred when importing classifier files.
//                    - "НетДоступаКПрограмме" - there is no access to the application on 1C:ITS portal.
//    *ErrorMessage  - String, FormattedString - an error message for the user.
//    *ErrorInfo - String, FormattedString - an error message for the administrator.
//
// Example:
//	IDs = New Array;
//	IDs.Add(Parameters.ID);
//
//	CheckResult = ClassifiersOperations.AvailableClassifiersUpdates(IDs);
//	If ValueFilled(CheckResult.ErrorCode) Then
//		ShowWarning(, CheckResult.ErrorMessage);
//	ElsIf CheckResult.AvailableVersions.Count() = 0 Then
//		Return;
//	Else
//		ClassifiersOperations.ProcessClassifierUpdate(
//			CheckResult.AvailableVersions[0].ID
//			CheckResult.AvailableVersions[0].Version
//			CheckResult.AvailableVersions[0].FileID)
//	EndIf;
//
Function ProcessClassifierUpdate(
		Id,
		Version,
		FileID) Export
	
	UpdateResult = New Structure;
	UpdateResult.Insert("ErrorCode",          "");
	UpdateResult.Insert("ErrorMessage",  "");
	UpdateResult.Insert("ErrorInfo", "");
	
	If Not Common.DataSeparationEnabled() Then
		
		Result = AuthenticationData();
		If Result.Error Then
			UpdateResult.ErrorCode = InvalidUsernameOrPasswordErrorCode();
			FillPropertyValues(UpdateResult, Result, "ErrorInfo");
			UpdateResult.ErrorMessage = Result.ErrorInfo;
			Return UpdateResult;
		EndIf;
		
		AuthenticationData = Result.AuthenticationData;
		
	Else
		
		// Update will be received from cache.
		AuthenticationData = Undefined;
		
	EndIf;
	
	// 1. Check update availability.
	CheckUpdateAvailability();
	
	// 2. Get classifier files by references found at step 1.
	If Common.DataSeparationEnabled() Then
		
		OperationResult = ImportClassifierFileFromCache(Id);
		
		// Populate version data.
		ClassifiersData = ClassifiersDataDetails();
		
		VersionSpecifier = ClassifiersData.Add();
		VersionSpecifier.Id    = Id;
		VersionSpecifier.Version           = Version;
		VersionSpecifier.FileAddress       = OperationResult.FileAddress;
		
	Else
		
		// Filling file request data.
		ClassifiersData = ClassifiersDataDetails();
		
		VersionSpecifier = ClassifiersData.Add();
		VersionSpecifier.Id      = Id;
		VersionSpecifier.Version             = Version;
		VersionSpecifier.FileID = FileID.FileID;
		VersionSpecifier.Checksum   = FileID.Checksum;
		VersionSpecifier.Size             = FileID.Size;
		VersionSpecifier.VersionDetails     = FileID.VersionDetails;
		
		OperationResult = ImportClassifiersFiles(
			ClassifiersData,
			AuthenticationData);
		
	EndIf;
	
	If OperationResult.Error Then
		FillPropertyValues(
			UpdateResult,
			OperationResult,
			"ErrorCode, ErrorMessage, ErrorInfo");
		Return UpdateResult;
	EndIf;
	
	// 3. Process files by the subsystem consumers.
	UnprocessedClassifiers = ProcessClassifiersFiles(ClassifiersData);
	
	If UnprocessedClassifiers.Count() > 0 Then
		OperationResult.ErrorCode = ErrorCodeUnprocessed();
		OperationResult.ErrorMessage  = NStr("ru = 'Не удалось обработать обновления классификаторов.';
													|en = 'Couldn''t process classifier updates.';");
		OperationResult.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'При обработке загруженных обновлений классификаторов %1 возникли ошибки.';
				|en = 'Errors occurred when processing imported updates of the %1 classifiers.';"),
			StrConcat(UnprocessedClassifiers, ","));
	EndIf;
	
	Return UpdateResult;

EndFunction

// Receives the latest versions of file classifiers from the classifier service
// or the default master data cache. In SaaS mode, saving information on
// latest classifier versions to cache will be optional, that is,
// depending on the classifier setup in the overridable
// ClassifiersOperationsOverridable.OnAddClassifiers method and in the
// OSLSubsystemsIntegration.OnAddClassifiers(Classifiers) method. If
//  the SaveFileToCache value is set to True,
// receiving files of latest classifier versions will be available, otherwise, the method will return
// the blank ClassifiersData table.
//
// Parameters:
//  IDs - Array of String - classifier IDs in the service
//                   whose files need to be imported.
//
// Returns:
//  Structure - Information on available updates.:
//    *ErrorCode - String - String code of the occurred error that
//                  can be processed by the calling functionality:
//                    - <Пустая строка> - Updated successfully.
//                    - "ОбновлениеНеТребуется" - an update is not found.
//                    - "НеверныйЛогинИлиПароль" - invalid username or password.
//                    - "ПревышеноКоличествоПопыток" - you exceeded the number of attempts
//                      to receive updates with incorrect username and password.
//                    - "ОшибкаПодключения" - an error occurred when connecting to the service.
//                    - "ОшибкаСервиса" - an internal service error.
//                    - "НеизвестнаяОшибка" - an unknown (unprocessable) error
//                      occurred when receiving information.
//                    - "НеОбработан" - A classifier file is successfully imported but not processed.
//                      An error can occur if file processing algorithms are missing.
//                      See the ClassifiersOperationsOverridable.OnImportClassifier
//                      and OSLSubsystemsIntegration.OnImportClassifier procedures.
//                    - "СервисВременноНеДоступен" - the service is temporarily unavailable due to maintenance.
//                    - "НеизвестныйКлассификаторИлиПрограмма" - a classifier or an application
//                      is not found in the service by the passed ID.
//                    - "ФайлНеЗагружен" - errors occurred when importing classifier files.
//                    - "НетДоступаКПрограмме" - there is no access to the application on 1C:ITS portal.
//    *ErrorMessage     - String, FormattedString - an error message for the user.
//    *ErrorInfo    - String, FormattedString - an error message for the administrator.
//    *ClassifiersData - ValueTable, Undefined - contains information on available updates
//      **ID    - String - classifier ID in the service.
//      **Version           - String - Relevant version number.
//      **FileAddress       - String - File address in a temporary storage.
//      **VersionDescription   - String - details of version changes.
//      **Checksum - String - details of version changes.
//      **Size           - String - details of version changes.
//
Function GetClassifierFiles(IDs) Export
	
	// 1. Get classifier files from the subsystem cache.
	// 
	UpdateResult = ClassifiersDataFromCache(IDs);
	
	// 2. In SaaS, classifier files can be obtained only from cache.
	// 
	If Not ValueIsFilled(UpdateResult.ErrorCode)
		Or Common.DataSeparationEnabled() Then
		Return UpdateResult;
	EndIf;
	
	// 2. Define the parameters of the service authentication.
	Result = AuthenticationData();
	If Result.Error Then
		UpdateResult.ErrorCode = InvalidUsernameOrPasswordErrorCode();
		FillPropertyValues(UpdateResult, Result, "ErrorInfo");
		UpdateResult.ErrorMessage = Result.ErrorInfo;
		Return UpdateResult;
	EndIf;
	
	UpdateResult = New Structure;
	UpdateResult.Insert("ErrorCode",             "");
	UpdateResult.Insert("ErrorMessage",     "");
	UpdateResult.Insert("ErrorInfo",    "");
	UpdateResult.Insert("ClassifiersData", ClassifiersDataDetails());
	
	AuthenticationData = Result.AuthenticationData;
	
	// 3. Import classifier versions.
	OperationResult = RelevantClassifiersVersionsInformation(
		IDs,
		AuthenticationData);
	
	If OperationResult.Error Then
		FillPropertyValues(
			UpdateResult,
			OperationResult,
			"ErrorCode, ErrorMessage, ErrorInfo");
		Return UpdateResult;
	EndIf;
	
	// 4. Get classifier files by references found at step 1.
	ImportResult1 = ImportClassifiersFiles(
		OperationResult.ClassifiersData,
		AuthenticationData);
	
	If ImportResult1.Error Then
		FillPropertyValues(
			UpdateResult,
			ImportResult1,
			"ErrorCode, ErrorMessage, ErrorInfo");
		Return UpdateResult;
	EndIf;
	
	// 5. Prepare a classifier table.
	OperationResult.ClassifiersData.Columns.Delete("FileID");
	UpdateResult.ClassifiersData = OperationResult.ClassifiersData;
	
	Return UpdateResult;
	
EndFunction

// Creates details of the classifier used in the application.
//
// Returns:
//   Structure - A list of values required to activate a trial period:
//     *Description               - String - User classifier presentation.
//                                   Length is not more than 150 characters.
//     *Id              - String - FileAddress - String - a file address in a temporary storage.
//                                   The field is required. If a blank string is passed,
//                                   an exception will be thrown when migrating to a new version. Length is not more than
//                                   50 characters.
//     *AutoUpdate     - Boolean - Setting that enables or disables
//                                   service data autoupdate.
//     *SharedData                - Boolean - regulates a method of processing the default master data.
//                                   If False, the classifier data will be imported into each area of the database.
//                                   The parameter is used only in SaaS mode.
//                                   
//     *SharedDataProcessing - Boolean - Indicates that additional processing of the areas is required after importing the classifier.
//                                   Applicable only for common classifiers in the SaaS mode
//                                   (if property "SharedData" is set to False, the setting is ignored).
//                                   Otherwise, the overridable method ClassifiersOperationsSaaSOverridable.OnProcessDataArea and
//                                   the OSLSubsystemsIntegration.OnProcessDataArea method will be called after the classifier update is processed in each data area.
//                                   Areas are processed by an asynchronous scheduled job
//                                   (see the JobsQueue subsystem), which is created after processing
//                                   shared data.
//                                   
//                                   
//                                   
//     *SaveFileToCache          - Boolean  - indicates whether the file is saved to the cache.
//                                   If True, the
//                                   file will be saved to cache after classifier data is processed. Data is obtained from cache when calling
//                                   the ClassifiersOperations.GetClassifiersFiles API.
//                                   As files are physically stored in the infobase, do not use
//                                   cache to store big classifiers. If a classifier is big,
//                                   it is better to create a separate metadata object to store its data.
//
Function ClassifierDetails() Export
	
	Specifier = New Structure;
	Specifier.Insert("Description",               "");
	Specifier.Insert("Id",              "");
	Specifier.Insert("AutoUpdate",     True);
	Specifier.Insert("SharedData",                True);
	Specifier.Insert("SharedDataProcessing", False);
	Specifier.Insert("SaveFileToCache",          False);
	
	Return Specifier;
	
EndFunction

// Changes a number of the imported classifier version. Use the procedure
// if data is being updated not from the classifier service. In SaaS
// mode, availability of shared data will be automatically determined. If shared data
// is not available, a version change is registered for the data area.
//
// Parameters:
//  Id - String - Classifier ID in the classifier service.
//  Version        - Number - a new version number that needs to be set.
//
Procedure SetClassifierVersion(Id, Version) Export
	
	UseAreaData = UseAreaData();
	RegisterName = StringFunctionsClientServer.SubstituteParametersToString(
		"InformationRegister.%1",
		?(UseAreaData,
			"DataAreasClassifiersVersions",
			"ClassifiersVersions"));
	
	BeginTransaction();
	
	Try
		Block = New DataLock;
		LockItem = Block.Add(RegisterName);
		LockItem.SetValue("Id", Id);
		Block.Lock();
		
		If UseAreaData Then
			Record = InformationRegisters.DataAreasClassifiersVersions.CreateRecordManager();
			Record.Id = Id;
			Record.Read();
		Else
			Record = InformationRegisters.ClassifiersVersions.CreateRecordManager();
			Record.Id = Id;
			Record.Read();
			If Not Record.Selected() Then
				Raise NStr("ru = 'Классификатор по идентификатору не обнаружен.';
										|en = 'Classifier by ID is not found.';");
			EndIf;
		EndIf;
		
		Record.Version = Version;
		Record.Write();
		
		CommitTransaction();
	Except
		
		RollbackTransaction();
		ErrorInfo = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteInformationToEventLog(ErrorInfo, True);
		Raise ErrorInfo;
		
	EndTry;
	
EndProcedure

// Sets an update date of the classifier file. The procedure must be called
// after the next update of the classifier data or if an update is not required,
// meaning that up-to-date data is imported into the infobase. When calling the procedure in the exclusive
// update handler, consider that information about the classifier will be registered
// after updating the Classifiers subsystem.
//
// Parameters:
//  Id  - String - Classifier ID in the classifier service.
//  UpdateDate - Date - Classifier update date.
//
Procedure SetClassifierUpdateDate(Id, UpdateDate) Export
	
	UseAreaData = UseAreaData();
	RegisterName = StringFunctionsClientServer.SubstituteParametersToString(
		"InformationRegister.%1",
		?(UseAreaData,
			"DataAreasClassifiersVersions",
			"ClassifiersVersions"));
	
	BeginTransaction();
	
	Try
		Block = New DataLock;
		LockItem = Block.Add(RegisterName);
		LockItem.SetValue("Id", Id);
		Block.Lock();
		
		If UseAreaData Then
			Record = InformationRegisters.DataAreasClassifiersVersions.CreateRecordManager();
			Record.Id = Id;
			Record.Read();
		Else
			Record = InformationRegisters.ClassifiersVersions.CreateRecordManager();
			Record.Id = Id;
			Record.Read();
			If Not Record.Selected() Then
				Raise NStr("ru = 'Классификатор по идентификатору не обнаружен.';
										|en = 'Classifier by ID is not found.';");
			EndIf;
		EndIf;
		
		Record.UpdateDate = UpdateDate;
		Record.Write();
		
		CommitTransaction();
	Except
		
		RollbackTransaction();
		ErrorInfo = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteInformationToEventLog(ErrorInfo, True);
		Raise ErrorInfo;
		
	EndTry;
	
EndProcedure

// Gets a version number of the classifier imported from the service. If the version number
// is not found by ID, it updates data of the
// ClassifiersVersions information register.
//
// Parameters:
//  Id      - String - Classifier ID in the classifier service.
//  RaiseException1 - Boolean - if it is True and a classifier ID is not found, an exception will be raised.
//
// Returns:
//   Number, Undefined - Classifier version number.
//
Function ClassifierVersion(Id, RaiseException1 = False) Export
	
	// Classifier versions are not private. Any of the infobase users can access it.
	// 
	SetPrivilegedMode(True);

	SharedData = Not (Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable());
	
	RegisterName = ?(SharedData,
		"ClassifiersVersions",
		"DataAreasClassifiersVersions");
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	RegClassifierVersions.Version AS Version
		|FROM
		|	InformationRegister.%1 AS RegClassifierVersions
		|WHERE
		|	RegClassifierVersions.ID = &Id";
	
	Query.Text = StringFunctionsClientServer.SubstituteParametersToString(
		Query.Text,
		RegisterName);
	
	Query.SetParameter("Id", Id);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	If SelectionDetailRecords.Next() Then
		Return SelectionDetailRecords.Version;
	EndIf;
	
	// The settings of the "ClassifiersVersions" information register are not updated.
	// (Perhaps, the subsystems were integrated in the wrong order.)
	// If the configuration uses the classifier, its settings will be partially updated.
	If SharedData Then
		
		Classifiers = New Array;
		OnAddClassifiers(Classifiers);
		
		For Each Specifier In Classifiers Do
			If Specifier.Id = Id Then
				Record = InformationRegisters.ClassifiersVersions.CreateRecordManager();
				FillPropertyValues(Record, Specifier);
				Record.Write();
				Return 0;
			EndIf;
		EndDo;
	EndIf;
	
	If RaiseException1 Then
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Классификатор %1 не зарегистрирован.';
				|en = 'Classifier %1 is not registered.';"),
			Id);
		Raise ExceptionText;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Gets date of the last classifier update. If the update date
// is not found by ID, it updates the
// ClassifiersVersions information register data.
//
// Parameters:
//  Id      - String - Classifier ID in the classifier service.
//  RaiseException1 - Boolean - if it is True and a classifier ID is not found, an exception will be raised.
//
// Returns:
//   Date, Undefined - Classifier update date.
//
Function ClassifierUpdateDate(Id, RaiseException1 = False) Export
	
	// The classifier update dates are not private. Any of the infobase users can access it.
	// 
	SetPrivilegedMode(True);
	
	SharedData = Not (Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable());
	
	RegisterName = ?(SharedData,
		"ClassifiersVersions",
		"DataAreasClassifiersVersions");
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	RegClassifierVersions.UpdateDate AS UpdateDate
		|FROM
		|	InformationRegister.%1 AS RegClassifierVersions
		|WHERE
		|	RegClassifierVersions.ID = &Id";
	
	Query.Text = StringFunctionsClientServer.SubstituteParametersToString(
		Query.Text,
		RegisterName);
	
	Query.SetParameter("Id", Id);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	If SelectionDetailRecords.Next() Then
		Return SelectionDetailRecords.UpdateDate;
	EndIf;
	
	// The settings of the "ClassifiersVersions" information register are not updated.
	// (Perhaps, the subsystems were integrated in the wrong order.)
	// If the configuration uses the classifier, its settings will be partially updated.
	If SharedData Then
		
		Classifiers = New Array;
		OnAddClassifiers(Classifiers);
		
		For Each Specifier In Classifiers Do
			If Specifier.Id = Id Then
				Record = InformationRegisters.ClassifiersVersions.CreateRecordManager();
				FillPropertyValues(Record, Specifier);
				Record.Write();
				Return Date(1, 1, 1, 0, 0, 0);
			EndIf;
		EndDo;
	EndIf;
	
	If RaiseException1 Then
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Классификатор %1 не зарегистрирован.';
				|en = 'Classifier %1 is not registered.';"),
			Id);
		Raise ExceptionText;
	Else
		Return Date(1, 1, 1, 0, 0, 0);
	EndIf;
	
EndFunction

// It determines availability of using interactive classifier
// import processing.
//
// Returns:
//  Boolean - defines if the ClassifiersUpdate data processor can be used.
//           If True, the data processor can be used.
// 
Function InteractiveClassifiersImportAvailable() Export
	
	Return Not Common.DataSeparationEnabled()
		And ClassifiersImportAvailable();
	
EndFunction

#EndRegion

#Region Internal

#Region ApplicationSettings

// Returns the environmental parameters of the OSL administration panel.
//
// Returns:
//  Structure:
//    * IsInteractiveImportAvailable - Boolean
//    * ClassifiersUpdateOption - Undefined - Interactive download is unavailable.
//                                       - Number 
//    * ClassifiersFile - Undefined - Interactive download is unavailable.
//                          - String
//    * SchedulePresentation - Undefined - Interactive download is unavailable.
//                              - String
//
Function OnlineSupportAndServicesFormEnvironmentParameters() Export
	
	IsInteractiveImportAvailable = InteractiveClassifiersImportAvailable();
	
	Result = New Structure();
	Result.Insert("IsInteractiveImportAvailable"   , IsInteractiveImportAvailable);
	Result.Insert("ClassifiersUpdateOption", Undefined);
	Result.Insert("ClassifiersFile"             , Undefined);
	Result.Insert("SchedulePresentation"         , Undefined);
	
	If Not IsInteractiveImportAvailable Then
		Return Result;
	EndIf;
	
	Result.ClassifiersUpdateOption = Constants.ClassifiersUpdateOption.Get();
	Result.ClassifiersFile              = Constants.ClassifiersFile.Get();
	
	SetPrivilegedMode(True);
	UpdateJobs = JobsUpdateClassifiers();
	If UpdateJobs.Count() = 0 Then
		AddClassifiersUpdateScheduledJob(False);
		UpdateJobs = JobsUpdateClassifiers();
	EndIf;
	
	If UpdateJobs.Count() <> 0 Then
		Result.SchedulePresentation = OnlineUserSupportClientServer.SchedulePresentation(
			UpdateJobs[0].Schedule);
	EndIf;
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

#EndRegion

#Region IntegrationWithStandardSubsystemsLibrary

#Region SSLCore

// Integration with the StandardSubsystems.Core subsystem.
//
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	NewPermissions = New Array;
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Resolution = ModuleSafeModeManager.PermissionToUseInternetResource(
		"HTTPS",
		ClassifiersServiceHost(0),
		443,
		NStr("ru = 'Сервис классификаторов (ru)';
			|en = 'Classifier service (ru)';"));
	NewPermissions.Add(Resolution);
	
	Resolution = ModuleSafeModeManager.PermissionToUseInternetResource(
		"HTTPS",
		ClassifiersServiceHost(1),
		443,
		NStr("ru = 'Сервис классификаторов (eu)';
			|en = 'Classifier service (eu)';"));
	NewPermissions.Add(Resolution);
	
	PermissionsRequests.Add(ModuleSafeModeManager.RequestToUseExternalResources(NewPermissions));
	
EndProcedure

// See the procedure details in the
// CommonOverridable.OnAddMetadataObjectsRenaming common module.
//
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	Common.AddRenaming(
		Total,
		"2.2.5.5",
		"Role.UpdateClassifiers",
		"Role.GetClassifiersUpdates",
		"OnlineUserSupport");
	
EndProcedure

#EndRegion

#Region SSLInfobaseUpdate

// Fills in a list of infobase update handlers.
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version              = "*";
	Handler.Procedure           = "ClassifiersOperations.UpdateClassifierSettings";
	Handler.SharedData         = True;
	Handler.InitialFilling = False;
	Handler.ExecutionMode     = "Seamless";
	Handler.Comment         = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = '%1. Обновление списка классификаторов.';
			|en = '%1. Update classifier list.';"),
		EventLogEventName());
	
	If Common.DataSeparationEnabled() Then
		
		Handler = Handlers.Add();
		Handler.Version              = "*";
		Handler.Procedure           = "ClassifiersOperations.UpdateDataAreaClassifierSettings";
		Handler.SharedData         = False;
		Handler.InitialFilling = False;
		Handler.ExecutionMode     = "Deferred";
		Handler.Id       = New UUID("0589c734-f2a8-4af1-97b1-6e8deb4830d6");
		Handler.Comment         = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1. Обновление списка классификаторов областей данных.';
				|en = '%1. Update list of data area classifiers.';"),
			EventLogEventName());
		
		Handler = Handlers.Add();
		Handler.Version              = "2.2.5.3";
		Handler.Procedure           = "ClassifiersOperations.FillDataAreasClassifiersVersionsRegisterData";
		Handler.SharedData         = False;
		Handler.InitialFilling = False;
		Handler.ExecutionMode     = "Deferred";
		Handler.Id       = New UUID("21d75419-ac2a-4d5f-8b61-45509c3c340e");
		Handler.Comment         = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1. Перенос настроек в регистр сведений ВерсииКлассификаторовОбластейДанных.';
				|en = '%1. Transfer settings to the DataAreasClassifiersVersions information register.';"),
			EventLogEventName());
		
		Handler = Handlers.Add();
		Handler.Version              = "2.4.1.13";
		Handler.Procedure           = "ClassifiersOperationsInternalSaaS.MoveClassifiersDataCache";
		Handler.SharedData         = True;
		Handler.InitialFilling = False;
		Handler.ExecutionMode     = "Exclusively";
		Handler.Comment         = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1. Перенос кэша поставляемых данных в подсистему ""Работа с классификаторами"".';
				|en = '%1. Move default master data cache to the Classifiers subsystem.';"),
			EventLogEventName());
	Else
		
		Handler = Handlers.Add();
		Handler.Version              = "2.4.1.13";
		Handler.Procedure           = "ClassifiersOperations.SetUpClassifiersUpdate";
		Handler.SharedData         = True;
		Handler.InitialFilling = False;
		Handler.ExecutionMode     = "Exclusively";
		Handler.Comment         = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1. Перенос кэша поставляемых данных в подсистему ""Работа с классификаторами"".';
				|en = '%1. Move default master data cache to the Classifiers subsystem.';"),
			EventLogEventName());
		
	EndIf;
	
EndProcedure

// Updates data of the ClassifiersVersions information register and
// adds a scheduled job to check classifier updates.
//
Procedure UpdateClassifierSettings() Export
	
	SetPrivilegedMode(True);
	
	WriteInformationToEventLog(
		NStr("ru = 'Обновление настроек подсистемы ""Работа с классификаторами"". Начало обновления.';
			|en = 'Update the Classifiers subsystem settings. Update started.';"),
		False);
	
	Classifiers = New Array;
	OnAddClassifiers(Classifiers);
	
	// Updating a list of classifiers and update settings.
	UpdateClassifiersVersions(Classifiers);
	
	WriteInformationToEventLog(
		NStr("ru = 'Обновление настроек подсистемы ""Работа с классификаторами"". Успешно завершено.';
			|en = 'Update the Classifiers subsystem settings. Completed successfully.';"),
		False);
	
EndProcedure

// Updates data of the DataAreasClassifiersVersions information register.
//
Procedure UpdateDataAreaClassifierSettings(Parameters) Export
	
	// Write the classifier information into the register
	// in a deferred update from data areas.
	If Not Common.DataSeparationEnabled()
		Or Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	WriteInformationToEventLog(
		NStr("ru = 'Обновление настроек областей подсистемы ""Работа с классификаторами"". Начало обновления.';
			|en = 'Update settings of the Classifiers subsystem areas. Update started.';"),
		False);
	
	Classifiers = New Array;
	OnAddClassifiers(Classifiers);
	
	ClassifiersToUse = New Array;
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.DataAreasClassifiersVersions");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		Query = New Query;
		Query.Text =
			"SELECT
			|	DataAreasClassifiersVersions.Id AS Id,
			|	DataAreasClassifiersVersions.Version AS Version
			|FROM
			|	InformationRegister.DataAreasClassifiersVersions AS DataAreasClassifiersVersions";
		
		QueryResult       = Query.Execute();
		SelectionDetailRecords = QueryResult.Select();
		
		For Each Specifier In Classifiers Do
			
			If Specifier.SharedData Then
				Continue;
			EndIf;
			
			Filter = New Structure;
			Filter.Insert("Id", Specifier.Id);
			
			If Not SelectionDetailRecords.FindNext(Filter) Then
				Record = InformationRegisters.DataAreasClassifiersVersions.CreateRecordManager();
				FillPropertyValues(Record, Specifier, "Id");
				Record.Write();
			EndIf;
			
			SelectionDetailRecords.Reset();
			ClassifiersToUse.Add(Specifier.Id);
			
		EndDo;
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	DataAreasClassifiersVersions.Id AS Id
			|FROM
			|	InformationRegister.DataAreasClassifiersVersions AS DataAreasClassifiersVersions
			|WHERE
			|	NOT DataAreasClassifiersVersions.Id IN (&ClassifiersToUse)";
		
		Query.SetParameter("ClassifiersToUse", ClassifiersToUse);
		
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		
		While SelectionDetailRecords.Next() Do
			Set = InformationRegisters.DataAreasClassifiersVersions.CreateRecordSet();
			Set.Filter.Id.Set(SelectionDetailRecords.Id);
			Set.Write();
		EndDo;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		ErrorInfo = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteInformationToEventLog(
			ErrorInfo,
			True,
			Metadata.InformationRegisters.DataAreasClassifiersVersions);
		Raise ErrorInfo;
	EndTry;
	
	WriteInformationToEventLog(
		NStr("ru = 'Обновление настроек областей подсистемы ""Работа с классификаторами"". Успешно завершено.';
			|en = 'Update settings of the Classifiers subsystem areas. Completed successfully.';"),
		False);
	
EndProcedure

// Moves data from the DeleteDataAreasClassifiersVersions information register
// to the DeleteDataAreasClassifiersVersions information register.
//
Procedure FillDataAreasClassifiersVersionsRegisterData(Parameters) Export
	
	// Write the classifier information into the register
	// in a deferred update from data areas.
	If Not Common.DataSeparationEnabled()
		Or Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	WriteInformationToEventLog(
		NStr("ru = 'Перенос настроек в регистр сведений ВерсииКлассификаторовОбластейДанных. Начало обновления.';
			|en = 'Transfer settings to the DataAreasClassifiersVersions information register. Update started.';"),
		False);
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock;
		DataLockItem = DataLock.Add("InformationRegister.DeleteDataAreasClassifiersVersions");
		DataLockItem.Mode = DataLockMode.Exclusive;
		DataLock.Lock();
		
		// The register does not contain a lot of records.
		Query = New Query;
		Query.Text = 
			"SELECT
			|	DeleteDataAreasClassifiersVersions.Id AS Id,
			|	DeleteDataAreasClassifiersVersions.Version AS Version
			|FROM
			|	InformationRegister.DeleteDataAreasClassifiersVersions AS DeleteDataAreasClassifiersVersions";
		
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		
		ClassifiersVersions = InformationRegisters.DataAreasClassifiersVersions.CreateRecordSet();
		While SelectionDetailRecords.Next() Do
			FillPropertyValues(ClassifiersVersions.Add(), SelectionDetailRecords);
		EndDo;
		
		DeleteClassifiersVersions = InformationRegisters.DeleteDataAreasClassifiersVersions.CreateRecordSet();
		
		ClassifiersVersions.Write();
		DeleteClassifiersVersions.Write();
		
		CommitTransaction();
	Except
		
		RollbackTransaction();
		ErrorInfo = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteInformationToEventLog(ErrorInfo, True);
		Raise ErrorInfo;
		
	EndTry;
	
	WriteInformationToEventLog(
		NStr("ru = 'Перенос настроек в регистр сведений ВерсииКлассификаторовОбластейДанных. Успешно завершено.';
			|en = 'Transfer settings to the DataAreasClassifiersVersions information register. Completed successfully.';"),
		False);
	
EndProcedure

// Fills in the ClassifiersUpdateOption constant.
//
Procedure SetUpClassifiersUpdate() Export
	
	SetPrivilegedMode(True);
	
	WriteInformationToEventLog(
		NStr("ru = 'Установка значения константы ВариантОбновленияКлассификаторов и добавление
			|регламентного задания ОбновлениеКлассификаторов. Начало обновления.';
			|en = 'Set the ClassifiersUpdateOption constant value
			|and add the UpdateClassifiers scheduled job. Update started.';"),
		False);
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	UpdateJobs = JobsUpdateClassifiers();
	If UpdateJobs.Count() <> 0 Then
		If UpdateJobs[0].Use
			And OnlineUserSupport.AuthenticationDataOfOnlineSupportUserFilled() Then
			EnableClassifierAutoUpdateFromService();
		EndIf;
	Else
		AddClassifiersUpdateScheduledJob(False);
	EndIf;
	
	WriteInformationToEventLog(
		NStr("ru = 'Установка значения константы ВариантОбновленияКлассификаторов и добавление
			|регламентного задания ОбновлениеКлассификаторов. Успешно завершено.';
			|en = 'Set the ClassifiersUpdateOption constant value 
			|and add the UpdateClassifiers scheduled job. Completed successfully.';"),
		False);
	
EndProcedure

#EndRegion

#Region SSLJobsQueue

// See details of the same procedure in the
// JobsQueueOverridable common module.
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert(
		"DeleteCacheOfSuppliedClassifiers",
		"ClassifiersOperationsInternalSaaS.DeleteCacheOfSuppliedClassifiers");
	NamesAndAliasesMap.Insert(
		"ScheduleDataAreasUpdate",
		"ClassifiersOperationsInternalSaaS.ScheduleDataAreasUpdate");
	NamesAndAliasesMap.Insert(
		"UpdatingTheSplitClassifier",
		"ClassifiersOperationsInternalSaaS.UpdatingTheSplitClassifier");
	NamesAndAliasesMap.Insert(
		"UpdatingTheSplitDataOfANonSplitClassifier",
		"ClassifiersOperationsInternalSaaS.UpdatingTheSplitDataOfANonSplitClassifier");
	
EndProcedure

#EndRegion

#Region SaaSSSL

// See SuppliedDataOverridable.GetHandlersForSuppliedData.
//
Procedure OnDefineSuppliedDataHandlers(Handlers) Export
	
	DataKinds = KindsOf1CSuppliedDataClassifiers();
	For Each DataKind In DataKinds Do
		StrHandler = Handlers.Add();
		StrHandler.DataKind      = DataKind;
		StrHandler.HandlerCode = DataKind;
		StrHandler.Handler     = Common.CommonModule("ClassifiersOperationsInternalSaaS");
	EndDo;
	
EndProcedure

#EndRegion

#Region SSLToDoList

// Integration with the StandardSubsystems.ToDoList subsystem.
// Fills a user's to-do list.
//
// Parameters:
//  ToDoList - ValueTable - A value table with the following columns:
//    * Id - String - An internal to-do item ID used by the "To-do list" feature.
//    * HasToDoItems      - Boolean - If True, the to-do item is displayed in the user's to-do list.
//    * Important        - Boolean - If True, the to-do item is highlighted in red.
//    * Presentation - String - The to-do item presentation displayed to a user.
//    * Count    - Number  - The to-do item counter displayed in the To-do list header.
//    * Form         - String - The full path to the form that is displayed when a user
//                               clicks a to-do item hyperlink in the "To-do list" panel.
//    * FormParameters - Structure - Indicator form's opening parameters.
//    * Owner      - String, MetadataObject - A string ID of the to-do item that is the owner of the current to-do item,
//                      or a subsystem metadata object.
//    * ToolTip     - String - A tooltip text.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ToDoList")
		Or Common.DataSeparationEnabled()
		Or Common.IsStandaloneWorkplace()
		Or UserUpdateSettings().DisableNotifications
		Or Not ClassifiersImportAvailable() Then
		
		Return;
	EndIf;
	
	ToDoItemID = "ClassifiersScheduledUpdateEnabling";
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If ModuleToDoListServer.UserTaskDisabled(ToDoItemID) Then
		Return;
	EndIf;
	
	Subsystem = Metadata.Subsystems.Find("Administration");
	If Subsystem = Undefined
		Or Not AccessRight("View", Subsystem)
		Or Not Common.MetadataObjectAvailableByFunctionalOptions(Subsystem) Then
		Sections = ModuleToDoListServer.SectionsForObject(Metadata.DataProcessors.UpdateClassifiers.FullName());
	Else
		Sections = CommonClientServer.ValueInArray(Subsystem);
	EndIf;
	
	If Sections.Count() > 0 Then
		
		DateOfInforming = Common.CommonSettingsStorageLoad(
			ClassifiersOperationsClientServer.CommonSettingsID(),
			ClassifiersOperationsClientServer.DateOfNotificationOnGetUpdatesEnabledSettingKey(),
			'00010101');
		
		HasToDoItems = (DateOfInforming <= CurrentSessionDate()
			And Not IsUpdatesAutoDownloadEnabled());
		
		For Each Section In Sections Do
			
			ToDoItem = ToDoList.Add();
			ToDoItem.Id  = ToDoItemID;
			ToDoItem.HasToDoItems       = HasToDoItems;
			ToDoItem.Important         = True;
			ToDoItem.Owner       = Section;
			ToDoItem.Presentation  = NStr("ru = 'Автоматическое обновление классификаторов';
										|en = 'Automatic classifier update';");
			ToDoItem.Form          = "DataProcessor.UpdateClassifiers.Form.UpdatesDownloadSettings";
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region OnlineUserSupportSubsystemsIntegration

// It is called when changing a username and a password of an OUS user
// to the infobase from all library usage contexts.
//
Procedure OnChangeAuthenticationData(Login, Password) Export
	
	If ValueIsFilled(Login) Then
		If Not IsUpdatesAutoDownloadEnabled() Then
			EnableClassifierAutoUpdateFromService()
		Else
			SetScheduledJobsUsage(True);
		EndIf;
	Else
		If Not IsUpdatesAutoDownloadEnabled() Then
			SetScheduledJobsUsage(False);
		EndIf;
	EndIf;
	
EndProcedure

// Populates the details of the hosts used in Online Support services.
//
// Parameters:
//  OnlineSupportServicesHosts - Map - The name and host of a service.
//
Procedure OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts) Export
	
	OnlineSupportServicesHosts.Insert(
		ClassifiersServiceHost(0),
		NStr("ru = 'Получение классификаторов';
			|en = 'Get classifiers';"));
	OnlineSupportServicesHosts.Insert(
		ClassifiersServiceHost(1),
		NStr("ru = 'Получение классификаторов';
			|en = 'Get classifiers';"));
	
EndProcedure

// Adds the required client parameters upon startup.
// Added parameters are available in
// StandardSubsystemsClient.ClientRunParametersOnStart().OnlineUserSupport.<ParameterName>;
// It is used if the subsystem implements the scenario executed
// upon the system startup.
// See OSLSubsystemsIntegration.OnAddClientParametersOnStart
//
// Parameters:
//	Parameters - Structure - The parameters to be filled.
//
Procedure ClientParametersOnStart(Parameters) Export
	
	Parameters.Insert("ClassifiersUpdateNotification", False);
	
	If Common.DataSeparationEnabled()
		Or Common.IsStandaloneWorkplace()
		Or Common.SubsystemExists("StandardSubsystems.ToDoList")
		Or UserUpdateSettings().DisableNotifications
		Or Not ClassifiersImportAvailable()
		Or IsUpdatesAutoDownloadEnabled() Then
		Return;
	EndIf;
	
	DateOfInforming = Common.CommonSettingsStorageLoad(
		ClassifiersOperationsClientServer.CommonSettingsID(),
		ClassifiersOperationsClientServer.DateOfNotificationOnGetUpdatesEnabledSettingKey(),
		'00010101');
	Parameters.ClassifiersUpdateNotification = (DateOfInforming <= CurrentSessionDate());
	
EndProcedure

#Region SaaSOperations

// The algorithms for processing the file imported from the classifier service are called,
// and the classifier update date is recorded.
//
// Parameters:
//  FileDetails           - Structure - see the ClassifierFileDataDetails function.
//  Processed               - Boolean - if False, errors occurred when processing the update file
//                            and it needs to be imported again.
//  AdditionalParameters - Structure - contains additional processing parameters.
//                            Use it to pass values to the
//                            ClassifiersOperationsSaaSOverridable.OnProcessDataArea overridable method
//                            and the OSLSubsystemsIntegration.OnProcessDataArea method.
//
Procedure OnImportClassifier(
		FileDetails,
		Processed,
		AdditionalParameters) Export
	
	Try
		
		OSLSubsystemsIntegration.OnImportClassifier(
				FileDetails.Id,
				FileDetails.Version,
				FileDetails.FileAddress,
				Processed,
				AdditionalParameters);
		
		ClassifiersOperationsOverridable.OnImportClassifier(
			FileDetails.Id,
			FileDetails.Version,
			FileDetails.FileAddress,
			Processed,
			AdditionalParameters);
		
	Except
		
		WriteInformationToEventLog(
			ErrorProcessing.DetailErrorDescription(
				ErrorInfo()),
			True);
		Raise ErrorProcessing.ErrorDescriptionForUser(
			ErrorInfo());
		
	EndTry;
	
	If Processed Then
		
		// Regardless of user rights, data in the following information registers
		// should be updated after the classifier file is processed:
		// "Classifier versions," "Versions of data area classifiers," and "Classifier data cache."
		// 
		SetPrivilegedMode(True);
		UpdateInternalClassifierData(FileDetails);
		SetPrivilegedMode(False);
		
	EndIf;
	
EndProcedure

// It determines classifier update settings.
//
// Parameters:
//  IDs  - Array - contains a list of classifier IDs,
//                    for which you need to get the settings.
//
// Returns:
//  Structure - classifier settings.
//
Function ClassifierSettings(Id) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ClassifiersVersions.Version AS Version,
		|	ClassifiersVersions.AutoUpdate AS AutoUpdate,
		|	ClassifiersVersions.SharedData AS SharedData,
		|	ClassifiersVersions.SharedDataProcessing AS SharedDataProcessing,
		|	ClassifiersVersions.SaveFileToCache AS SaveFileToCache
		|FROM
		|	InformationRegister.ClassifiersVersions AS ClassifiersVersions
		|WHERE
		|	ClassifiersVersions.Id = &Id";
	
	Query.SetParameter("Id", Id);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	If SelectionDetailRecords.Next() Then
		
		Settings = New Structure;
		Settings.Insert("Version",                     SelectionDetailRecords.Version);
		Settings.Insert("AutoUpdate",     SelectionDetailRecords.AutoUpdate);
		Settings.Insert("SharedData",                SelectionDetailRecords.SharedData);
		Settings.Insert("SharedDataProcessing", SelectionDetailRecords.SharedDataProcessing);
		Settings.Insert("SaveFileToCache",          SelectionDetailRecords.SaveFileToCache);
		
		Return Settings;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Creates a structure with details of actual versions file data.
//
// Returns:
//  Structure      - Contains information that is used to update classifier data.
//                   *FileAddress - String - The file address in a temporary storage.
//   
//   Contains information that is used to update classifier data.
//   *FileAddress - String - The file address in a temporary storage.
//   
//   
//   
//
Function ClassifierFileDataDetails(
		FileAddress,
		Id = "",
		Version = "",
		Checksum = "",
		Size = "",
		VersionDetails = "") Export
	
	FileDetails = New Structure;
	FileDetails.Insert("Id",    Id);
	FileDetails.Insert("Version",           Version);
	FileDetails.Insert("Checksum", Checksum);
	FileDetails.Insert("Size",           Size);
	FileDetails.Insert("VersionDetails",   VersionDetails);
	FileDetails.Insert("FileAddress",      FileAddress);
	
	Return FileDetails;
	
EndFunction 

// Defines the data type and code of the default master data handler.
//
// Parameters:
//  Id - String - The classifier ID in the service.
//
// Returns:
//  String - data kind description.
//
Function SuppliedDataKindClassifiers(Id = "") Export
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		"Classifiers.%1",
		Id);
	
EndFunction

// Saves or updates classifier data in cache.
//
// Parameters:
//  FileDetails - Structure - data to write to cache. See the
//                  ClassifiersOperations.ClassifierFileDataDetails function.
//
Procedure UpdateClassifierCache(FileDetails) Export
	
	Record = InformationRegisters.ClassifiersDataCache.CreateRecordManager();
	Record.Id    = FileDetails.Id;
	Record.Version           = StringFunctionsClientServer.StringToNumber(
		StrReplace(FileDetails.Version, Chars.NBSp, ""));
	Record.Checksum = FileDetails.Checksum;
	Record.VersionDetails   = FileDetails.VersionDetails;
	Record.Size           = StringFunctionsClientServer.StringToNumber(
		StrReplace(FileDetails.Size, Chars.NBSp, ""));
	Record.FileData      = New ValueStorage(
		GetFromTempStorage(
			FileDetails.FileAddress));
	
	Record.Write();
	
EndProcedure

// Adds an entry to the event log.
//
// Parameters:
//  ErrorMessage - String - Comment to the event log entry.
//  Error - Boolean - if True, the Error event log level will be set.
//  MetadataObject - MetadataObject - a metadata object, for which an error is registered.
//
Procedure WriteInformationToEventLog(
		ErrorMessage,
		Error = True,
		MetadataObject = Undefined) Export
	
	ELLevel = ?(Error, EventLogLevel.Error, EventLogLevel.Information);
	
	WriteLogEvent(
		EventLogEventName(),
		ELLevel,
		MetadataObject,
		,
		Left(ErrorMessage, 5120));
	
EndProcedure

// Defines and registers a version number of the imported classifier
//
// Parameters:
//  Id - String - classifier ID in the service.
//
// Returns:
//  Number - a defined version number.
//
Function ProcessInitialClassifierVersion(Id) Export
	
	VersionNumber = 0;
	OSLSubsystemsIntegration.OnDefineInitialClassifierVersionNumber(
		Id,
		VersionNumber);
	ClassifiersOperationsOverridable.OnDefineInitialClassifierVersionNumber(
		Id,
		VersionNumber);
	
	If TypeOf(VersionNumber) = Type("Number") And VersionNumber <> 0 Then
		
		SetPrivilegedMode(True);
		SetClassifierVersion(Id, VersionNumber);
		SetPrivilegedMode(False);
		
		Return VersionNumber;
		
	EndIf;
	
	Return 0;
	
EndFunction

// Defines the number of version for the classifier saved to cache.
//
// Parameters:
//  Id - String - Classifier version number.
//
// Returns:
//  Версия - Number - a classifier version number in the cache.
//
Function ClassifierVersionCache(Id) Export
	
	// Classifier versions are not private. Any of the infobase users can access it.
	// 
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ClassifiersDataCache.Version AS Version
		|FROM
		|	InformationRegister.ClassifiersDataCache AS ClassifiersDataCache
		|WHERE
		|	ClassifiersDataCache.Id = &Id";
	
	Query.SetParameter("Id", Id);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return -1;
	EndIf;
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		Return SelectionDetailRecords.Version;
	EndDo;
	
EndFunction 

// Gets classifier file from cache.
//
// Parameters:
//  Id - String - an ID of the classifier that requires getting file.
//
// Returns:
//  Structure - contains the result of classifier data import:
//    * FileAddress - String - Classifier file address in the temporary storage.
//    * Error - Boolean - indicates a data import error.
//    * ErrorCode - String - String code of the occurred error that
//                  can be processed by the calling functionality:
//                    - <Пустая строка> - files are successfully received.
//                    - "ФайлНеЗагружен" - errors occurred when importing classifier files.
//    *ErrorMessage - String - an error message for the user.
//    *ErrorInfo - String - an error message for the administrator.
//
Function ImportClassifierFileFromCache(Id) Export
	
	// The classifier cache is not private. Any of the infobase users can access it.
	// 
	SetPrivilegedMode(True);
	
	OperationResult = New Structure;
	OperationResult.Insert("Error",             False);
	OperationResult.Insert("ErrorCode",          "");
	OperationResult.Insert("ErrorMessage",  "");
	OperationResult.Insert("ErrorInfo", "");
	OperationResult.Insert("FileAddress",         "");
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ClassifiersDataCache.FileData AS FileData
		|FROM
		|	InformationRegister.ClassifiersDataCache AS ClassifiersDataCache
		|WHERE
		|	ClassifiersDataCache.Id = &Id";
	
	Query.SetParameter("Id", Id);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		OperationResult.Error = True;
		OperationResult.ErrorCode = ErrorCodeFileNotImported();
		OperationResult.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при получении файла классификатора. Файл классификатора %1 в кэше не обнаружен.';
				|en = 'Error getting classifier file. Classifier file %1 not found in cache.';"),
			Id);
		OperationResult.ErrorInfo = OperationResult.ErrorMessage;
		Return OperationResult;
	EndIf;
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		OperationResult.FileAddress = PutToTempStorage(
			SelectionDetailRecords.FileData.Get());
	EndDo;
	
	Return OperationResult;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#Region Private

#Region ScheduledJobsHandlers

// The UpdateClassifiers scheduled job handler.
//
Procedure UpdateClassifiers() Export
	
	// Lock scheduled jobs while performing internal infobase operations.
	// 
	Common.OnStartExecuteScheduledJob(
		Metadata.ScheduledJobs.UpdateClassifiers);
		
	UpdateMode = Constants.ClassifiersUpdateOption.Get();
	If UpdateMode = UpdateOptionFromFile() Then
		
		FileName = Constants.ClassifiersFile.Get();
		If Not ValueIsFilled(FileName) Then
			WriteInformationToEventLog(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Файл %1 с классификаторами не найден.';
						|en = 'File %1 with classifiers is not found.';"),
					FileName),
				True,
				Metadata.ScheduledJobs.UpdateClassifiers);
			Return;
		EndIf;
		
		ClassifiersFile = New File(FileName);
		If Not ClassifiersFile.Exists() Then
			WriteInformationToEventLog(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Файл %1 с классификаторами не существует.';
						|en = 'File %1 with classifiers does not exist.';"),
					FileName),
				True,
				Metadata.ScheduledJobs.UpdateClassifiers);
			Return;
		EndIf;
		
		UpdateClassifiersFromFile(FileName);
		
	ElsIf UpdateMode = OptionsOfUpdateFromService() Then
		
		If Not OnlineUserSupport.AuthenticationDataOfOnlineSupportUserFilled() Then
			WriteInformationToEventLog(
				NStr("ru = 'Не заполнены данные аутентификации Интернет-поддержки пользователей.
					|Обновление классификаторов из сервиса не возможно.';
					|en = 'Online support authentication credentials are not completed.
					|Cannot update classifiers from the service.';"),
			False,
			Metadata.ScheduledJobs.UpdateClassifiers);
			Return;
		EndIf;
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	ClassifiersVersions.Id AS Id
			|FROM
			|	InformationRegister.ClassifiersVersions AS ClassifiersVersions
			|WHERE
			|	ClassifiersVersions.AutoUpdate";
		
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		IDs         = New Array;
		
		While SelectionDetailRecords.Next() Do
			IDs.Add(SelectionDetailRecords.Id);
		EndDo;
		
		If IDs.Count() = 0 Then
			WriteInformationToEventLog(
				NStr("ru = 'Отсутствуют классификаторы для автоматического обновления.';
					|en = 'No classifiers for automatic update.';"),
				False,
				Metadata.ScheduledJobs.UpdateClassifiers);
			Return;
		EndIf;
		
		RunClassifierUpdate(IDs);
		
	EndIf;
	
EndProcedure

// Creates the UpdateClassifiers scheduled job 
// when updating an infobase or enabling online support.
//
// Parameters:
//  Use - Boolean - indicates whether a scheduled job is used.
//
Procedure AddClassifiersUpdateScheduledJob(Use = True)
	
	// In the on-premises version, classifiers are updated
	// with a scheduled job.
	If Not Common.DataSeparationEnabled() Then
		
		Filter = New Structure;
		Filter.Insert("Metadata", Metadata.ScheduledJobs.UpdateClassifiers);
		UpdateJobs = ScheduledJobsServer.FindJobs(Filter);
		
		If UpdateJobs.Count() = 0 Then
			
			// To mitigate the service load, the update time is picked randomly
			// from the time period between 00:00 and 06:00 a.m.
			// 
			Generator = New RandomNumberGenerator;
			Schedule = New JobSchedule;
			Schedule.BeginTime       = Date("00010101") + Generator.RandomNumber(0, 21600);
			Schedule.DaysRepeatPeriod = 1;
			
			JobParameters = New Structure;
			JobParameters.Insert("Use", Use);
			JobParameters.Insert("Metadata",    Metadata.ScheduledJobs.UpdateClassifiers);
			JobParameters.Insert("Schedule",    Schedule);
			JobParameters.Insert("Description",  NStr("ru = 'Обновление классификаторов';
															|en = 'Update classifiers';"));
			
			BeginTransaction();
			
			Try
				ScheduledJobsServer.AddJob(JobParameters);
				If Use
					And Not IsUpdatesAutoDownloadEnabled() Then
					EnableClassifierAutoUpdateFromService();
				EndIf;
				CommitTransaction();
			Except
				RollbackTransaction();
				ErrorInfo = ErrorProcessing.DetailErrorDescription(ErrorInfo());
					WriteInformationToEventLog(
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Не удалось создать регламентное задание обновления классификаторов по причине:
								|%1';
								|en = 'Cannot create a scheduled job for updating classifiers due to:
								|%1';"),
							ErrorInfo),
						True,
						Metadata.ScheduledJobs.UpdateClassifiers);
				Raise ErrorInfo;
			EndTry;
			
			WriteInformationToEventLog(
				NStr("ru = 'Создано регламентное задание обновления классификаторов.';
					|en = 'Scheduled job of classifier update was created.';"),
				False,
				Metadata.ScheduledJobs.UpdateClassifiers);
		EndIf;
		
	EndIf;
	
EndProcedure

// Enables or disables the UpdateClassifiers scheduled job.
//
// Parameters:
//  Use - Boolean - indicates whether a scheduled job is used.
//
Procedure SetScheduledJobsUsage(Use) Export
	
	SetPrivilegedMode(True);
	Jobs = JobsUpdateClassifiers();
	If Jobs.Count() <> 0 Then
		For Each Job In Jobs Do
			ScheduledJobsServer.SetScheduledJobUsage(
				Job,
				Use);
		EndDo;
	Else
		AddClassifiersUpdateScheduledJob(Use);
	EndIf;
	
EndProcedure

// Determines created scheduled jobs UpdateClassifiers.
//
// Returns:
//   Array - an array of scheduled jobs. See details of the ScheduledJob method
//   in the Syntax Assistant.
//
Function JobsUpdateClassifiers() Export
	
	Filter = New Structure;
	Filter.Insert("Metadata", Metadata.ScheduledJobs.UpdateClassifiers);
	Return ScheduledJobsServer.FindJobs(Filter);
	
EndFunction

// Enables the automatic classifier update from the service.
//
Procedure EnableClassifierAutoUpdateFromService() Export
	
	Constants.ClassifiersUpdateOption.Set(OptionsOfUpdateFromService());
	
EndProcedure

#EndRegion

#Region IBUpdate

// Determines a list of classifiers used in the configuration.
// Main info: update ID and setting automatically.
// It updates the ClassifiersVersions catalog information register data.
//
// Parameters:
//  Classifiers - Array - Classifier specifiers.
//                   See the ClassifierDetails() function.
//
Procedure UpdateClassifiersVersions(Classifiers)
	
	// ACC:499-off
	
	// The lock is not required because the procedure is called in exclusive mode upon update.
	
	ClassifiersToUse = New Array;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	ClassifiersVersions.Id AS Id,
		|	ClassifiersVersions.Version AS Version,
		|	ClassifiersVersions.AutoUpdate AS AutoUpdate,
		|	ClassifiersVersions.SharedData AS SharedData,
		|	ClassifiersVersions.Description AS Description,
		|	ClassifiersVersions.SharedDataProcessing AS SharedDataProcessing,
		|	ClassifiersVersions.SaveFileToCache AS SaveFileToCache
		|FROM
		|	InformationRegister.ClassifiersVersions AS ClassifiersVersions";
	
	QueryResult       = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	
	For Each Specifier In Classifiers Do
		
		Updated = False;
		Filter = New Structure;
		Filter.Insert("Id", Specifier.Id);
		
		// Update classifier settings.
		If SelectionDetailRecords.FindNext(Filter) Then
			
			If SelectionDetailRecords.AutoUpdate <> Specifier.AutoUpdate
				Or SelectionDetailRecords.SharedData <> Specifier.SharedData
				Or SelectionDetailRecords.Description <> Specifier.Description
				Or SelectionDetailRecords.SharedDataProcessing <> Specifier.SharedDataProcessing
				Or SelectionDetailRecords.SaveFileToCache <> Specifier.SaveFileToCache Then
				
				Record = InformationRegisters.ClassifiersVersions.CreateRecordManager();
				FillPropertyValues(Record, SelectionDetailRecords, "Id, Version");
				Record.AutoUpdate     = Specifier.AutoUpdate;
				Record.SharedData                = Specifier.SharedData;
				Record.Description               = Specifier.Description;
				Record.SharedDataProcessing = Specifier.SharedDataProcessing;
				Record.SaveFileToCache          = Specifier.SaveFileToCache;
				Record.Write();
			EndIf;
			
			Updated = True;
			
		EndIf;
		
		// Add new classifiers.
		If Not Updated Then
			Record = InformationRegisters.ClassifiersVersions.CreateRecordManager();
			SpecifierProperties = "
				|Id,
				|AutoUpdate,
				|SharedData,
				|Description,
				|SharedDataProcessing,
				|SaveFileToCache";
			FillPropertyValues(Record, Specifier, SpecifierProperties);
			Record.Write();
		EndIf;
		
		SelectionDetailRecords.Reset();
		ClassifiersToUse.Add(Specifier.Id);
		
	EndDo;
	
	// Delete obsolete classifier IDs from the "Classifier versions" register.
	// 
	Query = New Query;
	Query.Text =
		"SELECT
		|	ClassifiersVersions.Id AS Id
		|FROM
		|	InformationRegister.ClassifiersVersions AS ClassifiersVersions
		|WHERE
		|	NOT ClassifiersVersions.Id IN (&ClassifiersToUse)";
	
	Query.SetParameter("ClassifiersToUse", ClassifiersToUse);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		Set = InformationRegisters.ClassifiersVersions.CreateRecordSet();
		Set.Filter.Id.Set(SelectionDetailRecords.Id);
		Set.Write();
		
		Set = InformationRegisters.ClassifiersDataCache.CreateRecordSet();
		Set.Filter.Id.Set(SelectionDetailRecords.Id);
		Set.Write();
	EndDo;
	
	// ACC:499-on
	
EndProcedure

#EndRegion

#Region ClassifiersDataImport

// Imports classifier data from service.
//
// Parameters:
//  IDs - Array - classifier IDs in the service
//                   whose update needs to be imported;
//  AuthenticationData - Structure - Username and a password for authorization in the classifier service.
//
// Returns:
//  Structure - The result of importing classifier data:
//    * Error    - Boolean - indicates a data import error.
//    * ErrorCode - String - String code of the occurred error that
//                  can be processed by the calling functionality:
//                    - <Пустая строка> - an update is determined successfully.
//                    - "ОбновлениеНеТребуется" - an update is not found.
//                    - "НеверныйЛогинИлиПароль" - invalid username or password.
//                    - "ПревышеноКоличествоПопыток" - you exceeded the number of attempts
//                      to receive updates with incorrect username and password.
//                    - "ОшибкаПодключения" - an error occurred when connecting to the service.
//                    - "ОшибкаСервиса" - an internal service error.
//                    - "НеизвестнаяОшибка" - an unknown (unprocessable) error
//                      occurred when receiving information.
//                    - "СервисВременноНеДоступен" - the service is temporarily unavailable due to maintenance.
//                    - "НеизвестныйКлассификаторИлиПрограмма" - a classifier or an application
//                      is not found in the service by the passed ID.
//                    - "ФайлНеЗагружен" - errors occurred when importing classifier files.
//                    - "НетДоступаКПрограмме" - there is no access to the application on 1C:ITS portal.
//    *ErrorMessage  - String, FormattedString - an error message for the user.
//    *ErrorInfo - String, FormattedString - an error message for the administrator.
//
Function InternalDetermineClassifiersData(IDs, AuthenticationData, ImportFiles = True)
	
	OperationResult = RelevantClassifiersVersionsInformation(
		IDs,
		AuthenticationData);
	
	If OperationResult.Error Then
		Return OperationResult;
	EndIf;
	
	// Don't update if the classifier version in the infobase matches the version in the service.
	// 
	DeleteLatestVersions(OperationResult.ClassifiersData, IDs);
	
	If OperationResult.ClassifiersData.Count() = 0 Then
		OperationResult.Error             = True;
		OperationResult.ErrorCode          = "NoUpdateRequired";
		OperationResult.ErrorMessage  = NStr("ru = 'Обновление не требуется. Загружена актуальная версия классификатора.';
													|en = 'No update is required. Classifier version is up-to-date.';");
		OperationResult.ErrorInfo = NStr("ru = 'Обновление не требуется. Загружена актуальная версия классификатора.';
													|en = 'No update is required. Classifier version is up-to-date.';");
		Return OperationResult;
	EndIf;
	
	ImportResult1 = ImportClassifiersFiles(
		OperationResult.ClassifiersData,
		AuthenticationData);
	
	If ImportResult1.Error Then
		FillPropertyValues(
			OperationResult,
			ImportResult1,
			"ErrorCode, ErrorMessage, ErrorInfo");
		OperationResult.Error = True;
		Return OperationResult;
	EndIf;
	
	Return OperationResult;
	
EndFunction

// Imports classifier data from cache.
//
// Parameters:
//  IDs - Array - classifier IDs in the service
//                   whose update needs to be imported.
//
// Returns:
//  Structure - The result of importing classifier data:
//    * ClassifiersData - ValueTable - see the ClassifiersOperations.ClassifiersDataDetails function.
//    * Error    - Boolean - indicates a data import error.
//    * ErrorCode - String - String code of the occurred error that
//                  can be processed by the calling functionality:
//                    - <Пустая строка> - an update is determined successfully.
//                    - "ОбновлениеНеТребуется" - latest classifier versions are imported.
//                    - "ФайлНеЗагружен" - errors occurred when importing classifier files.
//    *ErrorMessage  - String, FormattedString - an error message for the user.
//    *ErrorInfo - String, FormattedString - an error message for the administrator.
//
Function InternalDetermineClassifiersDataInSaaS(IDs)
	
	OperationResult = ClassifiersDataFromCache(IDs);
	
	If OperationResult.Error Then
		Return OperationResult;
	EndIf;
	
	// Don't update if the classifier version in the infobase matches the version in the service.
	// 
	DeleteLatestVersions(OperationResult.ClassifiersData, IDs);
	
	If OperationResult.ClassifiersData.Count() = 0 Then
		OperationResult.Error = True;
		OperationResult.ErrorCode = "NoUpdateRequired";
		OperationResult.ErrorMessage  = NStr("ru = 'Обновление не требуется. Загружена актуальная версия классификатора.';
													|en = 'No update is required. Classifier version is up-to-date.';");
		OperationResult.ErrorInfo = NStr("ru = 'Обновление не требуется. Загружена актуальная версия классификатора.';
													|en = 'No update is required. Classifier version is up-to-date.';");
		Return OperationResult;
	EndIf;
	
	Return OperationResult;
	
EndFunction

#EndRegion

#Region ServiceOperationsCall

////////////////////////////////////////////////////////////////////////////////
// Calling the /version/latest operation

// Returns the list of details of latest classifier versions that are
// currently available to the user.
//
// Parameters:
//  IDs         - Array - contains a list of classifier IDs,
//                          for which you need to check if there are updates.
//  AuthenticationData  - Structure - parameters of online support user authentication.
//
// Returns:
//   Structure - The operation result:
//    *Error - Boolean - True if you cannot receive information from the service.
//    *ErrorMessage - String - error details for the user.
//    *ErrorInfo - String - error details for the administrator.
//    *ClassifiersData - ValueTable - see the ClassifiersDataDetails() function.
//
Function RelevantClassifiersVersionsInformation(
		IDs,
		AuthenticationData)
	
	TextEventLog = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Начало получения информации об актуальных версиях классификаторов: %1';
			|en = 'Start getting information on latest classifier versions: %1';"),
		StrConcat(IDs, ","));
	
	WriteInformationToEventLog(
		TextEventLog,
		False);
	
	OperationResult = New Structure;
	OperationResult.Insert("ErrorCode",             "");
	OperationResult.Insert("Error",                False);
	OperationResult.Insert("ErrorMessage",     "");
	OperationResult.Insert("ErrorInfo",    "");
	OperationResult.Insert("ClassifiersData", ClassifiersDataDetails());
	
	ConnectionParameters = InitializeClassifiersUpdateParameters();
	
	URLOperations = ClassifiersServiceOperationURL(
		"/version/latest",
		ConnectionParameters.ConnectionSetup.OUSServersDomain);
	
	JSONQueryParameters = versionlatest(
		IDs,
		AuthenticationData,
		OnlineUserSupport.AdditionalParametersOfServiceOperationsCall());
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/json");
	
	SendOptions = New Structure;
	SendOptions.Insert("Method"                   , "POST");
	SendOptions.Insert("AnswerFormat"            , 1);
	SendOptions.Insert("Headers"               , Headers);
	SendOptions.Insert("DataForProcessing"      , JSONQueryParameters);
	SendOptions.Insert("DataFormatToProcess", 1);
	SendOptions.Insert("ProxySettings"         , ConnectionParameters.ProxyServerSettings);
	SendOptions.Insert("Timeout"                 , 30);
	
	// Call a service operation.
	SendingResult = OnlineUserSupport.DownloadContentFromInternet(
		URLOperations,
		,
		,
		SendOptions);
	
	If Not IsBlankString(SendingResult.ErrorCode) Then
		
		OperationResult.ErrorCode         = OverrideServiceErrorCode(SendingResult.StatusCode);
		OperationResult.Error            = True;
		OperationResult.ErrorMessage = OverrideUserMessage(OperationResult.ErrorCode);
		
		OperationResult.ErrorInfo = New FormattedString(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить актуальные версии классификаторов.
					|
					|%1
					|
					|Техническая информация об ошибке:
					|При получении информации об актуальных версиях классификаторов сервис вернул ошибку.
					|URL: %2
					|Код ошибки: %3
					|Подробная информация:
					|%4';
					|en = 'Failed to get latest classifier versions.
					|
					|%1
					|
					|Technical information on the error:
					| When getting information on latest classifier versions, the service returned an error.
					|URL: %2
					|Error code: %3
					|Details:
					|%4';"),
				String(OperationResult.ErrorMessage),
				URLOperations,
				SendingResult.ErrorCode,
				SendingResult.ErrorInfo));
		
		WriteInformationToEventLog(
			String(OperationResult.ErrorInfo),
			True);
		
		Return OperationResult;
		
	EndIf;
	
	ReadDataversionlatest(
		SendingResult.Content,
		OperationResult.ClassifiersData,
		ConnectionParameters.ConnectionSetup.OUSServersDomain);
	
	TextEventLog = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Завершено получение актуальных версий классификаторов: %1';
			|en = 'Latest classifier versions received: %1';"),
		StrConcat(IDs, ","));
	
	WriteInformationToEventLog(
		TextEventLog,
		False);
	
	Return OperationResult;
	
EndFunction

// Generates request parameters for the
// classifiers/version/latest operation.
//
Function versionlatest(IDs, AuthenticationData, AdditionalParameters)
	
	// {
	//    "programNick":"nick",
	//    "classifierNickList":[nick1,nick2],
	//    "authenticationInfo": {
	//            "login": "User",
	//            "password":"Pass",
	//    },
	//    "additionalParameters" : {
	//        "key":"value"
	//    }
	// }
	
	ApplicationName = OnlineUserSupport.InternalApplicationName();
	
	MessageDataWriter = New JSONWriter;
	MessageDataWriter.SetString();
	MessageDataWriter.WriteStartObject();
	
	RecordAuthenticationData(MessageDataWriter, AuthenticationData);
	
	MessageDataWriter.WritePropertyName("programNick");
	MessageDataWriter.WriteValue(ApplicationName);
	
	MessageDataWriter.WritePropertyName("classifierNickList");
	MessageDataWriter.WriteStartArray();
	For Each Id In IDs Do
		MessageDataWriter.WriteValue(Id);
	EndDo;
	MessageDataWriter.WriteEndArray();
	
	OnlineUserSupport.WriteAdditionalQueryParameters(
		AdditionalParameters,
		MessageDataWriter);
	
	MessageDataWriter.WriteEndObject();
	
	Return MessageDataWriter.Close();
	
EndFunction

// Reading the /version/latest operation response.
//
Procedure ReadDataversionlatest(
		JSONBody,
		ClassifiersData,
		OUSServersDomain = 1)
	
	// Response body:
	// classifierNick - Classifier ID in the service
	// version - The up-to-date version number
	// fileUrl - The up-to-date version download link
	// hashSum - File checksum
	// versionDescription - Classifier version description
	// fileSize - The file size
	// classifierName - The classifier name.
	//
	// {
	//  [
	//     {
	//      "classifierNick": "ID",
	//      "version":1,
	//      "fileUrl": "https://fileUrl",
	//      "hashSum": "Checksum",
	//      "versionDescription": "Description",
	//      "fileSize": "Size in bytes",
	//      "classifierName": "Classifier name"
	//     }
	//  ]
	// }
	
	TextEventLog = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Получен ответ Сервиса классификаторов:
			|%1';
			|en = 'Response is received from the classifier service:
			|%1';"),
		JSONBody);
	
	WriteInformationToEventLog(
		TextEventLog,
		False);
	
	ReadResponse = New JSONReader;
	ReadResponse.SetString(JSONBody);
	CurrentLevel = 0;
	While ReadResponse.Read() Do
		
		If ReadResponse.CurrentValueType = JSONValueType.ArrayStart Then
			CurrentLevel = CurrentLevel + 1;
		ElsIf ReadResponse.CurrentValueType = JSONValueType.ArrayEnd Then
			CurrentLevel = CurrentLevel - 1;
		ElsIf ReadResponse.CurrentValueType = JSONValueType.PropertyName
			And CurrentLevel = 1 Then
			
			If ReadResponse.CurrentValue = "classifierNick" Then
				VersionSpecifier = ClassifiersData.Add();
				VersionSpecifier.Id = JSONPropertyValue(ReadResponse, "");
			ElsIf ReadResponse.CurrentValue = "version" Then
				VersionSpecifier.Version = JSONPropertyValue(ReadResponse, 0);
			ElsIf ReadResponse.CurrentValue = "fileUrl" Then
				VersionSpecifier.FileID = JSONPropertyValue(ReadResponse, "");
			ElsIf ReadResponse.CurrentValue = "hashSum" Then
				VersionSpecifier.Checksum = JSONPropertyValue(ReadResponse, "");
			ElsIf ReadResponse.CurrentValue = "versionDescription" Then
				VersionSpecifier.VersionDetails = JSONPropertyValue(ReadResponse, "");
			ElsIf ReadResponse.CurrentValue = "fileSize" Then
				VersionSpecifier.Size = JSONPropertyValue(ReadResponse, 0);
			ElsIf ReadResponse.CurrentValue = "classifierName" Then
				VersionSpecifier.Description = JSONPropertyValue(ReadResponse, 0);
			EndIf;
		EndIf;
		
	EndDo;
	
	// Check the response format.
	ServiceHost = ClassifiersServiceHost(OUSServersDomain);
	For Each VersionSpecifier In ClassifiersData Do
		If Not ValueIsFilled(VersionSpecifier.Id)
			Or Not ValueIsFilled(VersionSpecifier.Version)
			Or Not ValueIsFilled(VersionSpecifier.FileID) Then
			
			ErrorMessage = NStr("ru = 'Неверный формат ответа Сервиса классификаторов.';
									|en = 'Incorrect classifier service response format.';");
			WriteInformationToEventLog(ErrorMessage);
			Raise ErrorMessage;
			
		EndIf;
		
		URIStructure = CommonClientServer.URIStructure(VersionSpecifier.FileID);
		If Right(Lower(TrimAll(URIStructure.Host)), 6) <> Right(Lower(TrimAll(ServiceHost)), 6) Then
			
			ErrorMessage = NStr("ru = 'Неверный адрес файла обновления классификатора.';
									|en = 'Incorrect address of classifier update file.';");
			WriteInformationToEventLog(ErrorMessage);
			Raise ErrorMessage;
			
		EndIf;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Calling file import operation /version/download/

// Imports files via URLs passed earlier.
//
// Parameters:
//  ClassifiersData - ValueTable - see the ClassifiersDataDetails() function.
//  AuthenticationData  - Structure - parameters of online support user authentication.
//
// Returns:
//   Structure - The operation result:
//    *Error - Boolean - True if you cannot receive information from the service.
//    *ErrorMessage - String - error details for the user.
//    *ErrorInfo - String - error details for the administrator.
//
Function ImportClassifiersFiles(ClassifiersData, AuthenticationData)
	
	OperationResult = New Structure;
	OperationResult.Insert("ErrorCode",          "");
	OperationResult.Insert("Error",             False);
	OperationResult.Insert("ErrorMessage",  "");
	OperationResult.Insert("ErrorInfo", "");
	
	JSONQueryParameters = versiondownload(AuthenticationData);
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/json");
	
	SendOptions = New Structure;
	SendOptions.Insert("Method",                    "POST");
	SendOptions.Insert("Timeout",                  1280);
	SendOptions.Insert("AnswerFormat",             2);
	SendOptions.Insert("DataFormatToProcess", 1);
	SendOptions.Insert("DataForProcessing",       JSONQueryParameters);
	SendOptions.Insert("Headers",                Headers);
	
	For Each ClassifierSpecifier In ClassifiersData Do
		
		If ClassifierSpecifier.Size = 0 Then
			SendOptions.Timeout = 30;
		Else
			// Development standard No.748 "Time-outs for external resource management."
			// If the file size is known, the time-out is the size in MB * 128.
			// Otherwise, the maximum download time, but no more than 43200.
			SendOptions.Timeout = ClassifierSpecifier.Size / 1024 /1024 *128;
			If SendOptions.Timeout > 43200 Then
				SendOptions.Timeout = 43200;
			ElsIf SendOptions.Timeout < 30 Then
				SendOptions.Timeout = 30;
			EndIf;
		EndIf;
		
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Получение файла классификатора: %1';
					|en = 'Receive classifier file: %1';"),
				ClassifierSpecifier.FileID),
			False);
		
		OnlineUserSupport.CheckURL(ClassifierSpecifier.FileID);
		
		SendingResult = OnlineUserSupport.DownloadContentFromInternet(
			ClassifierSpecifier.FileID,
			,
			,
			SendOptions);
		
		If Not IsBlankString(SendingResult.ErrorCode) Then
			
			OperationResult.ErrorCode          = ErrorCodeFileNotImported();
			OperationResult.Error             = True;
			OperationResult.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при получении файла классификатора %1: 
					|%2';
					|en = 'An error occurred when receiving the %1 classifier file:
					|%2';"),
				ClassifierSpecifier.Id,
				SendingResult.ErrorMessage);
				
			OperationResult.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить файл классификатора %1.
					|%2
					|
					|Техническая информация об ошибке:
					|При загрузке файла сервис вернул ошибку.
					|Код ошибки: %3.
					|URL Файла: %4
					|Подробная информация:
					|%5';
					|en = 'Cannot get %1 classifier file.
					|%2
					|
					|Technical information on the error:
					|Service returned an error when importing file.
					|Error code: %3
					|File URL: %4
					|Details:
					|%5';"),
				ClassifierSpecifier.Id,
				OperationResult.ErrorMessage,
				OperationResult.ErrorCode,
				ClassifierSpecifier.FileID,
				SendingResult.ErrorInfo);
			WriteInformationToEventLog(
				OperationResult.ErrorInfo,
				True);
			
			Return OperationResult;
			
		EndIf;
		
		ChecksumFile = OnlineUserSupport.FileChecksum(SendingResult.Content);
		If ClassifierSpecifier.Checksum <> ChecksumFile Then
			OperationResult.ErrorCode          = ErrorCodeFileNotImported();
			OperationResult.Error             = True;
			OperationResult.ErrorMessage  = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при получении файла классификатора %1: 
					|%2';
					|en = 'An error occurred when receiving the %1 classifier file:
					|%2';"),
				ClassifierSpecifier.Id,
				NStr("ru = 'Получен некорректный файл.';
					|en = 'Incorrect file is received.';"));
				
			OperationResult.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить файл классификатора %1.
					|Контрольная сумма полученного файла отличается от ожидаемой.';
					|en = 'Cannot get the %1 classifier file.
					|Received file checksum differs from the expected one.';"),
				ClassifierSpecifier.Id);
			WriteInformationToEventLog(OperationResult.ErrorInfo);
			
			Return OperationResult;
		EndIf;
		
		ClassifierSpecifier.FileAddress = PutToTempStorage(SendingResult.Content);
		
	EndDo;
	
	Return OperationResult;
	
EndFunction

// Generates request parameters for the
// /classifiers/version/download/ operation.
//
Function versiondownload(AuthenticationData)
	
	// {
	//  "programNick":"nick",
	//  "login": "User",
	//  "password":"Pass"
	// }
	
	ApplicationName = OnlineUserSupport.InternalApplicationName();
	
	MessageDataWriter = New JSONWriter;
	MessageDataWriter.SetString();
	MessageDataWriter.WriteStartObject();
	
	MessageDataWriter.WritePropertyName("programNick");
	MessageDataWriter.WriteValue(ApplicationName);
	
	MessageDataWriter.WritePropertyName("login");
	MessageDataWriter.WriteValue(AuthenticationData.Login);
	
	MessageDataWriter.WritePropertyName("password");
	MessageDataWriter.WriteValue(AuthenticationData.Password);
	
	MessageDataWriter.WriteEndObject();
	
	Return MessageDataWriter.Close();
	
EndFunction

#EndRegion

#Region InteractiveClassifiersUpdate

// Checks for available classifier updates in the Classifier service.
//
// Parameters:
//  IDs - Array - classifier IDs in the service
//                   whose update needs to be imported;
//  AuthenticationData - Structure - Username and a password for authorization in the classifier service.
//  DeleteRelevantClassifiers - Boolean - indicates that relevant classifier versions are deleted.
//
// Returns:
//  Structure - Information on available updates.:
//    * ErrorCode - String - String code of the occurred error that
//                  can be processed by the calling functionality:
//                    - <Пустая строка> - Updated successfully.
//                    - "НеверныйЛогинИлиПароль" - invalid username or password.
//                    - "ПревышеноКоличествоПопыток" - you exceeded the number of attempts
//                      to receive updates with incorrect username and password.
//                    - "ОшибкаПодключения" - an error occurred when connecting to the service.
//                    - "ОшибкаСервиса" - an internal service error.
//                    - "НеизвестнаяОшибка" - an unknown (unprocessable) error
//                      occurred when receiving information.
//                    - "СервисВременноНеДоступен" - the service is temporarily unavailable due to maintenance.
//                    - "НеизвестныйКлассификаторИлиПрограмма" - a classifier or an application
//                      is not found in the service by the passed ID.
//                    - "НетДоступаКПрограмме" - there is no access to the application on 1C:ITS portal.
//                    - "ОбновлениеНеТребуется" - latest classifier versions are imported.
//    *ErrorMessage  - String, FormattedString - an error message for the user.
//    *ErrorInfo - String, FormattedString - an error message for the administrator.
//    *AvailableVersions - Array - contains information on available updates
//      **ID      - String - classifier ID in the service.
//      **Version             - String - Relevant version number.
//      **Checksum   - Number - File checksum.
//      **VersionDescription     - String - details of version changes.
//      **FileId - String - File ID that will be used for import.
//      **Size             - String - File size.
//      **Name       - String - Classifier name.
//
Function InternalAvailableClassifiersUpdates(
		IDs,
		AuthenticationData,
		DeleteRelevantClassifiers = False) Export
	
	// 1. Check update availability.
	CheckUpdateAvailability();
	
	// 2. Populate versions for new classifiers.
	// 
	SetInitialVersionNumberOfClassifiers(IDs);
	
	// 3. Determine authentication data.
	CheckResult = New Structure;
	CheckResult.Insert("ErrorCode",          "");
	CheckResult.Insert("ErrorMessage",  "");
	CheckResult.Insert("ErrorInfo", "");
	CheckResult.Insert("AvailableVersions ",   New Array);
	
	If Not Common.DataSeparationEnabled() Then
		If AuthenticationData = Undefined Then
			Result = AuthenticationData();
			If Result.Error Then
				CheckResult.ErrorCode = InvalidUsernameOrPasswordErrorCode();
				FillPropertyValues(CheckResult, Result, "ErrorInfo");
				CheckResult.ErrorMessage = Result.ErrorInfo;
				Return CheckResult;
			EndIf;
			AuthenticationData = Result.AuthenticationData;
		EndIf;
	Else
		// Update will be received from cache.
		AuthenticationData = Undefined;
	EndIf;
	
	// 4. Import from the service information on the up-to-date classifier versions and their download links.
	// 
	If Common.DataSeparationEnabled() Then
		OperationResult = ClassifiersDataFromCache(
			IDs,
			False);
	Else
		OperationResult = RelevantClassifiersVersionsInformation(
			IDs,
			AuthenticationData);
	EndIf;
		
	If OperationResult.Error Then
		FillPropertyValues(
			CheckResult,
			OperationResult,
			"ErrorCode, ErrorMessage, ErrorInfo");
		Return CheckResult;
	EndIf;
	
	// 5. Don't update if the classifier version in the infobase matches the version in the service.
	// 
	If DeleteRelevantClassifiers Then
		DeleteLatestVersions(
			OperationResult.ClassifiersData,
			IDs);
	EndIf;
	
	For Each VersionSpecifier In OperationResult.ClassifiersData Do
		
		FileID = New Structure;
		FileID.Insert("FileID", VersionSpecifier.FileID);
		FileID.Insert("Checksum",   VersionSpecifier.Checksum);
		FileID.Insert("Size",             VersionSpecifier.Size);
		FileID.Insert("VersionDetails",     VersionSpecifier.VersionDetails);
		
		VersionData = New Structure;
		VersionData.Insert("Id",      VersionSpecifier.Id);
		VersionData.Insert("Description",       VersionSpecifier.Description);
		VersionData.Insert("Version",             VersionSpecifier.Version);
		VersionData.Insert("VersionDetails",     VersionSpecifier.VersionDetails);
		VersionData.Insert("Size",             VersionSpecifier.Size);
		VersionData.Insert("FileID", FileID);
		CheckResult.AvailableVersions.Add(VersionData);
		
	EndDo;
	
	Return CheckResult;
	
EndFunction

// Refreshes classifier data in a background job.
//
// Parameters:
//  ProcedureParameters - Structure - data for update.
//  StorageAddress - String - an address of the update result storage.
//
Procedure InteractiveClassifiersUpdateFromService(ProcedureParameters, StorageAddress) Export
	
	UpdateResult = New Structure;
	UpdateResult.Insert("ErrorCode",         "");
	UpdateResult.Insert("ErrorMessage", "");
	UpdateResult.Insert("ErrorInfo", "");
	
	ClassifiersData = ProcedureParameters.ClassifiersData;
	ClassifiersData.Columns.Add("FileAddress", Common.StringTypeDetails(250));
	
	If ProcedureParameters.UpdateMode = 0 Then
		
		Result = AuthenticationData();
		If Result.Error Then
			UpdateResult.ErrorCode = InvalidUsernameOrPasswordErrorCode();
			UpdateResult.ErrorMessage = Result.ErrorInfo;
			PutToTempStorage(UpdateResult, StorageAddress);
			Return;
		EndIf;
		
		ImportResult1 = ImportClassifiersFiles(
			ClassifiersData,
			Result.AuthenticationData);
		
		If ImportResult1.Error Then
			FillPropertyValues(
				UpdateResult,
				ImportResult1,
				"ErrorCode, ErrorMessage, ErrorInfo");
			PutToTempStorage(UpdateResult, StorageAddress);
			Return;
		EndIf;
	Else
		For Each ClassifierDetails In ClassifiersData Do
			If ClassifierDetails.FileData.Size() = 0 Then
				ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Файл классификатора %1 (%2) имеет размер равный 0.
						|Загрузка данных остановлена.';
						|en = 'The size of the %1 classifier file (%2) is 0. 
						|Data import is stopped.';"),
					ClassifierDetails.Description,
					ClassifierDetails.Id);
				WriteInformationToEventLog(
					ExceptionText,
					True,
					Metadata.DataProcessors.UpdateClassifiers);
				Raise ExceptionText;
			EndIf;
			ClassifierDetails.FileAddress = PutToTempStorage(ClassifierDetails.FileData);
		EndDo;
	EndIf;
	
	ProcessFilesAtInteractiveImport(
		ClassifiersData,
		UpdateResult);
	
	PutToTempStorage(UpdateResult, StorageAddress);
	
EndProcedure

// Processing a file with classifier updates in a background job.
//
// Parameters:
//  ProcedureParameters - Structure - data for update.
//  StorageAddress - String - an address of the update result storage.
//
Procedure InteractiveClassifiersUpdateFromFile(ProcedureParameters, StorageAddress) Export
	
	UpdateResult = New Structure;
	UpdateResult.Insert("ErrorCode",         "");
	UpdateResult.Insert("ErrorMessage", "");
	
	FileData           = ProcedureParameters.FileData;
	ClassifiersData = ProcedureParameters.ClassifiersData;
	
	ClassifiersData.Columns.Add("FileAddress", Common.StringTypeDetails(250));
	
	UpdateDirectory = FileSystem.CreateTemporaryDirectory(
		String(New UUID));
	
	ClassifiersFiles = GetTempFileName(".zip");
	FileData.Write(ClassifiersFiles);
	FileData = Undefined;
	
	ZipFileReader = New ZipFileReader(ClassifiersFiles);
	For Each VersionDetails In ClassifiersData Do
		
		ArchiveItem = ZipFileReader.Items.Find(VersionDetails.FileID);
		If ArchiveItem = Undefined Then
			WriteInformationToEventLog(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось найти файл классификатора %1 в архиве %2.';
						|en = 'Failed to find classifier file %1 in archive %2.';"),
					VersionDetails.Id,
					ClassifiersFiles),
				True,
				Metadata.DataProcessors.UpdateClassifiers);
			Continue;
		EndIf;
		
		ZipFileReader.Extract(ArchiveItem, UpdateDirectory);
		FileData = New BinaryData(UpdateDirectory + VersionDetails.FileID);
		
		If FileData.Size() = 0 Then
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Файл классификатора %1 (%2) имеет размер равный 0.
					|Загрузка данных остановлена.';
					|en = 'The size of the %1 classifier file (%2) is 0. 
					|Data import is stopped.';"),
				VersionDetails.Description,
				VersionDetails.Id);
			WriteInformationToEventLog(
				ExceptionText,
				True,
				Metadata.DataProcessors.UpdateClassifiers);
			Raise ExceptionText;
		EndIf;
		
		VersionDetails.Size           = FileData.Size();
		VersionDetails.Checksum = OnlineUserSupport.FileChecksum(FileData);
		VersionDetails.FileAddress       = PutToTempStorage(FileData);
		
	EndDo;
	
	DeleteFiles(ClassifiersFiles);
	
	ProcessFilesAtInteractiveImport(
		ClassifiersData,
		UpdateResult);
	
	PutToTempStorage(UpdateResult, StorageAddress);
	
EndProcedure

// Imports classifier files upon interactive data processing.
//
// Parameters:
//  ClassifiersData - ValueTable - see the ClassifiersOperations.ClassifiersDataDetails function.
//                 <parameter details continuation>
//  UpdateResult - Structure - contains import result.
//
Procedure ProcessFilesAtInteractiveImport(ClassifiersData, UpdateResult)
	
	UnprocessedClassifiers = ProcessClassifiersFiles(ClassifiersData, True);
	
	For Each ClassifierDetails In ClassifiersData Do
		DeleteFromTempStorage(ClassifierDetails.FileAddress);
	EndDo;
	
	If UnprocessedClassifiers.Count() > 0 Then
		Cnt = 1;
		ErrorMessage = "";
		For Each ClassifierDetails In ClassifiersData Do
			If UnprocessedClassifiers.Find(ClassifierDetails.Id) <> Undefined Then
				ErrorMessage = ErrorMessage
					+ StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = '%1. Версия %2 классификатора %3 не загружена;';
							|en = '%1.Version %2 of classifier %3 is not imported.';"),
							Cnt,
							ClassifierDetails.Version,
							ClassifierDetails.Description)
						+ Chars.LF;
				Cnt = Cnt + 1;
			EndIf;
		EndDo;
		UpdateResult.ErrorCode         = ErrorCodeUnprocessed();
			UpdateResult.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать обновления классификаторов:
					|
					|%1';
					|en = 'Couldn''t process classifier updates:
					|
					|%1';"),
				ErrorMessage);
	EndIf;
	
EndProcedure

// Getting all IDs of classifiers, descriptions,
// and versions that are used in the configuration. The function is used for
// interactive data import from the "Classifier update" data processor.
//
// Parameters:
//  IDs - Array - classifier IDs in the service.
//
// Returns:
//  Array - contains classifier settings.
//
Function ClassifiersDataForInteractiveUpdate() Export
	
	If Common.DataSeparationEnabled() Then
		Raise NStr("ru = 'Использование функции при работе в модели сервиса запрещено.';
								|en = 'The function cannot be used in SaaS.';");
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	RegClassifierVersions.Id AS Id,
		|	RegClassifierVersions.Version AS Version,
		|	RegClassifierVersions.Description AS Description
		|FROM
		|	InformationRegister.ClassifiersVersions AS RegClassifierVersions
		|WHERE
		|	RegClassifierVersions.AutoUpdate";
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	ClassifiersVersions = New Array;
	While SelectionDetailRecords.Next() Do
		
		ClassifierDetails = New Structure;
		ClassifierDetails.Insert("Id", SelectionDetailRecords.Id);
		ClassifierDetails.Insert("Version",        SelectionDetailRecords.Version);
		ClassifierDetails.Insert("Description",  SelectionDetailRecords.Description);
		
		ClassifiersVersions.Add(ClassifierDetails);
	EndDo;
	
	Return ClassifiersVersions;
	
EndFunction

#EndRegion

#Region ImportClassifiersFromFiles

// Imports the classifier update and data processor from file.
//
// Parameters:
//  FileName - String - Path to a file with classifier data.
//
Procedure UpdateClassifiersFromFile(FileName)
	
	ClassifiersVersionsFile = ClassifiersVersionsInFile(FileName);
	
	// Populate versions for new classifiers.
	// 
	For Each ClassifierDetails In ClassifiersVersionsFile Do
		If ClassifierDetails.Version = 0 Then
			ClassifierDetails.Version = ProcessInitialClassifierVersion(
				ClassifierDetails.Id);
		EndIf;
	EndDo;
	
	IBClassifiersVersions = ClassifiersDataForInteractiveUpdate();
	
	ClassifiersData = ClassifiersDataDetails();
	ClassifiersDirectory = FileSystem.CreateTemporaryDirectory();
	
	ZipFileReader = New ZipFileReader(FileName);
	For Each VersionDetails In ClassifiersVersionsFile Do
		
		ImportRequired         = True;
		ClassifierInUse = False;
		
		For Each ClassifierVersion In IBClassifiersVersions Do
			If ClassifierVersion.Id = VersionDetails.Id Then
				ClassifierInUse = True;
				If ClassifierVersion.Version >= VersionDetails.Version Then
					ImportRequired = False;
				EndIf;
				Break;
			EndIf;
		EndDo;
		
		If Not ClassifierInUse Or Not ImportRequired Then
			Continue;
		EndIf;
		
		ArchiveItem = ZipFileReader.Items.Find(VersionDetails.Name);
		If ArchiveItem = Undefined Then
			WriteInformationToEventLog(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось найти файл классификатора %1 в архиве %2.';
						|en = 'Failed to find classifier file %1 in archive %2.';"),
					VersionDetails.Id,
					FileName),
				True,
				Metadata.ScheduledJobs.UpdateClassifiers);
			Continue;
		EndIf;
		
		ZipFileReader.Extract(ArchiveItem, ClassifiersDirectory);
		FileData = New BinaryData(ClassifiersDirectory + VersionDetails.Name);
		
		DataString1 = ClassifiersData.Add();
		DataString1.FileAddress       = PutToTempStorage(FileData);
		DataString1.Version           = VersionDetails.Version;
		DataString1.Id    = VersionDetails.Id;
		DataString1.Size           = FileData.Size();
		DataString1.Checksum = OnlineUserSupport.FileChecksum(FileData);
		
	EndDo;
	
	FileSystem.DeleteTempFile(ClassifiersDirectory);
	ProcessClassifiersFiles(ClassifiersData);
	
EndProcedure

// Defines IDs and numbers of versions that contain files with updates.
//
// Parameters:
//  FileName - String - a location of classifier archive.
//
// Returns:
//  Array - contains classifier IDs and version number.
//
Function ClassifiersVersionsInFile(FileName)
	
	ClassifiersVersions = New Array;
	
	If CommonClientServer.GetFileNameExtension(FileName) <> "zip" Then
		Return ClassifiersVersions;
	EndIf;
	
	ZipFileReader = New ZipFileReader(FileName);
	For Each Item In ZipFileReader.Items Do
		
		// Encrypted archive items are not processed.
		If Item.Encrypted Then
			Continue;
		EndIf;
		
		SeparatorPosition = StrFind(Item.BaseName, "_", SearchDirection.FromEnd);
		
		// If the filename format is not [ID]_[Version], the subsystem must skip it.
		// 
		If SeparatorPosition = 0 Then
			Continue;
		EndIf;
		
		Try
			Version        = Number(StrReplace(Mid(Item.BaseName, SeparatorPosition + 1), Chars.NBSp, ""));
			Id = Left(Item.BaseName, SeparatorPosition - 1);
		Except
			Version = Undefined;
			Id = Undefined;
		EndTry;
		
		// If the filename contains invalid data, the subsystem must skip it.
		// 
		If Not ValueIsFilled(Id) Or Not ValueIsFilled(Version) Then
			Continue;
		EndIf;
		
		VersionDetails = New Structure;
		VersionDetails.Insert("Id", Id);
		VersionDetails.Insert("Version",        Version);
		VersionDetails.Insert("Name",           Item.Name);
		ClassifiersVersions.Add(VersionDetails);
		
	EndDo;
	
	ZipFileReader.Close();
	
	Return ClassifiersVersions;
	
EndFunction

#EndRegion

#Region InternalClassifiersDataProcessing

// Refreshes classifier data and, if necessary,
// creates a job that processes data areas.
//
// Parameters:
//  ClassifiersData - ValueTable - see the
//                          ClassifiersOperations.ClassifiersDataDetails function.
//  ReportProgress - Boolean - if classifiers are imported in a long-running operation,
//                     report the update progress.
//
// Returns:
//  Array - classifiers whose data failed to be updated.
//
Function ProcessClassifiersFiles(ClassifiersData, ReportProgress = False)
	
	// Generate a list of classifiers that require a data area update.
	// 
	If Common.DataSeparationEnabled() Then
		IDs = ClassifiersData.UnloadColumn("Id");
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	ClassifiersVersions.Id AS Id
			|FROM
			|	InformationRegister.ClassifiersVersions AS ClassifiersVersions
			|WHERE
			|	ClassifiersVersions.Id IN(&IDs)
			|	AND ClassifiersVersions.SharedDataProcessing = TRUE
			|	AND ClassifiersVersions.SharedData = TRUE";
		
		Query.SetParameter("IDs", IDs);
		
		IDs = Query.Execute().Unload().UnloadColumn("Id");
	Else
		IDs = New Array;
	EndIf;
	
	UnprocessedClassifiers = New Array;
	UpdateAreasData = New Array;
	Cnt = 1;
	For Each FileData In ClassifiersData Do
		
		Processed               = False;
		AdditionalParameters = New Structure;
		
		FileDetails = ClassifierFileDataDetails(
			FileData.FileAddress,
			FileData.Id,
			FileData.Version,
			FileData.Checksum,
			FileData.Size,
			FileData.VersionDetails);
		
		OnImportClassifier(
			FileDetails,
			Processed,
			AdditionalParameters);
		
		If Processed Then
			
			If IDs.Find(FileData.Id) <> Undefined Then
				ClassifierSettings = New Structure;
				ClassifierSettings.Insert("Id",           FileData.Id);
				ClassifierSettings.Insert("Version",                  FileData.Version);
				ClassifierSettings.Insert("AdditionalParameters", AdditionalParameters);
				UpdateAreasData.Add(ClassifierSettings);
			EndIf;
			
		Else
			UnprocessedClassifiers.Add(FileData.Id);
		EndIf;
		
		If ReportProgress Then
			TimeConsumingOperations.ReportProgress(100 * Cnt / ClassifiersData.Count());
		EndIf;
		Cnt = Cnt + 1;
	EndDo;
	
	If Common.DataSeparationEnabled() And UpdateAreasData.Count() <> 0 Then
		
		ModuleClassifiersOperationsInternalSaaS = Common.CommonModule(
			"ClassifiersOperationsInternalSaaS");
		
		ModuleClassifiersOperationsInternalSaaS.ScheduleDataAreasUpdate(
			UpdateAreasData);
		
	EndIf;
	
	Return UnprocessedClassifiers;
	
EndFunction

// An overriding is called for the list and settings of classifiers whose updates must be
// imported from the classifier service. To get an ID,
// translate
// into English a description of the metadata object whose data is planned to be updated. When translating, it is recommended that you use professional
// text translation applications or make use of translator services, since
// if semantic errors in the ID are detected, it is required to create a new classifier
// and change the configuration code.
//
// Parameters:
//  Classifiers  - Array - contains classifier import settings.
//                    For the composition of settings, see the ClassifiersOperations.ClassifierDetails function.
//
//
Procedure OnAddClassifiers(Classifiers)
	
	OSLSubsystemsIntegration.OnAddClassifiers(Classifiers);
	ClassifiersOperationsOverridable.OnAddClassifiers(Classifiers);
	
EndProcedure

// Changes the imported version number and its update date, and
// caches classifier data in the information register if necessary. In SaaS 
// mode, availability of shared data will be automatically determined.
// If shared data is not available, a version change is registered
// for the data area.
//
// Parameters:
//  FileDetails - Structure - see the ClassifierFileDataDetails function.
//
Procedure UpdateInternalClassifierData(FileDetails)
		
		If UseAreaData() Then
			Record = InformationRegisters.DataAreasClassifiersVersions.CreateRecordManager();
			Record.Id = FileDetails.Id;
			Record.Version         = Number(FileDetails.Version);
			Record.UpdateDate = CurrentSessionDate();
			Record.Write();
		Else
			
			BeginTransaction();
			
			Try
				
				Block = New DataLock;
				LockItem = Block.Add("InformationRegister.ClassifiersVersions");
				LockItem.SetValue("Id", FileDetails.Id);
				LockItem.Mode = DataLockMode.Exclusive;
				Block.Lock();
				
				Record = InformationRegisters.ClassifiersVersions.CreateRecordManager();
				Record.Id = FileDetails.Id;
				Record.Read();
				If Not Record.Selected() Then
					Raise NStr("ru = 'Классификатор по идентификатору не обнаружен.';
											|en = 'Classifier by ID is not found.';");
				EndIf;
				
				Record.Version         = Number(FileDetails.Version);
				Record.UpdateDate = CurrentSessionDate();
				
				Record.Write();
				
				// Do cache data only if the classifier assignee explicitly enabled caching.
				// 
				If Record.SaveFileToCache Then
					UpdateClassifierCache(FileDetails);
				EndIf;
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				ErrorInfo = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				WriteInformationToEventLog(ErrorInfo, True);
				Raise ErrorInfo;
				
			EndTry;
			
		EndIf;
		
EndProcedure

// Defines a version number of the imported classifier.
//
// Parameters:
//  IDs - Array - classifier IDs in the service.
//
Procedure SetInitialVersionNumberOfClassifiers(IDs)
	
	ClassifiersVersions = ClassifiersVersions(IDs);
	For Each ClassifierDetails In ClassifiersVersions Do
		
		If ClassifierDetails.Version <> 0 Then
			Continue;
		EndIf;
		
		ProcessInitialClassifierVersion(ClassifierDetails.Id);
		
	EndDo;
	
EndProcedure

// Getting all IDs of classifiers
// and versions that are used in the configuration.
//
// Parameters:
//  IDs - Array - classifier IDs in the service.
//
// Returns:
//  Array - contains classifier settings.
//
Function ClassifiersVersions(IDs = Undefined)
	
	ClassifiersVersions = New Array;
	
	SharedData = Not (Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable());
	
	RegisterName = ?(
		SharedData,
		"ClassifiersVersions",
		"DataAreasClassifiersVersions");
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	RegClassifierVersions.Id AS Id,
		|	RegClassifierVersions.Version AS Version
		|FROM
		|	InformationRegister.%1 AS RegClassifierVersions
		|	%2";
	
	Query.Text = StringFunctionsClientServer.SubstituteParametersToString(
		Query.Text,
		RegisterName,
		?(IDs = Undefined,
			"",
			"WHERE
			|	RegClassifierVersions.Id IN (&IDs)"));
	
	Query.SetParameter("IDs", IDs);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		
		ClassifierDetails = New Structure;
		ClassifierDetails.Insert("Id", SelectionDetailRecords.Id);
		ClassifierDetails.Insert("Version",        SelectionDetailRecords.Version);
		
		ClassifiersVersions.Add(ClassifierDetails);
	EndDo;
	
	Return ClassifiersVersions;
	
EndFunction

// Deletes the latest classifier versions
// that are determined based on the infobase data.
//
// Parameters:
//  ClassifiersData - ValueTable - see the
//                          ClassifiersDataDetails() function.
//  IDs - Array - a list of imported classifier
//                   IDs that need to be updated.
//
Procedure DeleteLatestVersions(ClassifiersData, IDs)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	RegClassifierVersions.Id AS Id,
		|	RegClassifierVersions.Version AS Version
		|FROM
		|	InformationRegister.%1 AS RegClassifierVersions
		|WHERE
		|	RegClassifierVersions.ID IN(&IDs)";
	
	TableName = ?(UseAreaData(),
		"DataAreasClassifiersVersions",
		"ClassifiersVersions");
	
	Query.Text = StringFunctionsClientServer.SubstituteParametersToString(
		Query.Text,
		TableName);
	
	Query.SetParameter("IDs", IDs);
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	LatestVersions = New Array;
	
	While SelectionDetailRecords.Next() Do
		
		Filter = New Structure;
		Filter.Insert("Id", SelectionDetailRecords.Id);
		
		FoundRows = ClassifiersData.FindRows(Filter);
		For Each VersionSpecifier In FoundRows Do
			If VersionSpecifier.Version <= SelectionDetailRecords.Version Then
				LatestVersions.Add(VersionSpecifier);
			EndIf;
		EndDo;
	EndDo;
	
	SetPrivilegedMode(True);
	For Each VersionSpecifier In LatestVersions Do
		SetClassifierUpdateDate(
			VersionSpecifier.Id,
			CurrentSessionDate());
		ClassifiersData.Delete(VersionSpecifier);
	EndDo;
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region ClassifiersCacheManagement

// Imports classifier data from cache.
//
// Parameters:
//  IDs - Array - classifier IDs in the service
//                   whose update needs to be imported.
//
// Returns:
//  Structure - The result of importing classifier data:
//    * ClassifiersData - ValueTable - see the ClassifiersOperations.ClassifiersDataDetails function.
//    * Error - Boolean - indicates a data import error.
//    * ErrorCode - String - String code of the occurred error that
//                  can be processed by the calling functionality:
//                    - <Пустая строка> - files are successfully received.
//                    - "ФайлНеЗагружен" - errors occurred when importing classifier files.
//    *ErrorMessage - String - an error message for the user.
//    *ErrorInfo - String - an error message for the administrator.
//
Function ClassifiersDataFromCache(IDs, ImportFiles = True)
	
	// The classifier cache is not private. Any of the infobase users can access it.
	// 
	SetPrivilegedMode(True);
	
	OperationResult = New Structure;
	OperationResult.Insert("Error",                False);
	OperationResult.Insert("ErrorCode",             "");
	OperationResult.Insert("ErrorMessage",     "");
	OperationResult.Insert("ErrorInfo",    "");
	OperationResult.Insert("ClassifiersData", ClassifiersDataDetails());
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	ClassifiersDataCache.Id AS Id,
		|	ClassifiersDataCache.Version AS Version,
		|	ClassifiersDataCache.Checksum AS Checksum,
		|	ClassifiersDataCache.VersionDetails AS VersionDetails,
		|	ClassifiersDataCache.Size AS Size,
		|	&FileData AS FileData,
		|	ClassifiersVersions.Description AS Description
		|FROM
		|	InformationRegister.ClassifiersDataCache AS ClassifiersDataCache
		|		INNER JOIN InformationRegister.ClassifiersVersions AS ClassifiersVersions
		|		ON ClassifiersDataCache.Id = ClassifiersVersions.Id
		|WHERE
		|	ClassifiersDataCache.Id IN(&IDs)";
	
	FieldFileData = ?(ImportFiles, "ClassifiersDataCache.FileData", """""");
	Query.Text = StrReplace(Query.Text, "&FileData", FieldFileData);
	Query.SetParameter("IDs", IDs);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	For Each Id In IDs Do
		
		Filter = New Structure("Id", Id);
		If SelectionDetailRecords.FindNext(Filter) Then
			
			VersionDetails = OperationResult.ClassifiersData.Add();
			VersionDetails.Id    = SelectionDetailRecords.Id;
			VersionDetails.Version           = SelectionDetailRecords.Version;
			VersionDetails.Checksum = SelectionDetailRecords.Checksum;
			VersionDetails.VersionDetails   = SelectionDetailRecords.VersionDetails;
			VersionDetails.Size           = SelectionDetailRecords.Size;
			VersionDetails.Description     = SelectionDetailRecords.Description;
			
			If ImportFiles Then
				
				FileData = SelectionDetailRecords.FileData.Get();
				
				If TypeOf(FileData) <> Type("BinaryData") Then
					
					OperationResult.Error = True;
					OperationResult.ErrorCode = ErrorCodeFileNotImported();
					OperationResult.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Ошибка при получении файла классификатора. Файл классификатора %1 в кэше не обнаружен.';
							|en = 'Error getting classifier file. Classifier file %1 not found in cache.';"),
						Id);
					OperationResult.ErrorInfo = OperationResult.ErrorMessage;
					OperationResult.ClassifiersData.Clear();
					
					Return OperationResult;
					
				EndIf;
				
				VersionDetails.FileAddress = PutToTempStorage(
					SelectionDetailRecords.FileData.Get());
				
			EndIf;
			
		Else
			OperationResult.Error = True;
			OperationResult.ErrorCode = ErrorCodeFileNotImported();
			OperationResult.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при получении файла классификатора. Файл классификатора %1 в кэше не обнаружен.';
					|en = 'Error getting classifier file. Classifier file %1 not found in cache.';"),
				Id);
			OperationResult.ErrorInfo = OperationResult.ErrorMessage;
			OperationResult.ClassifiersData.Clear();
			Return OperationResult;
		EndIf;
		
		SelectionDetailRecords.Reset();
		
	EndDo;
	
	Return OperationResult;
	
EndFunction

#EndRegion

#Region OtherServiceProceduresFunctions

// Creates a table with details of latest versions data.
//
// Returns:
//  ValueTable      - contains information that is used
//                         to get information on external systems.
//   *ID - String - a classifier ID in the classifier service.
//   contains information that is used
//   to get information on external systems.
//   *ID - String - a classifier ID in the classifier service.
//   
//   
//   
//   
//
Function ClassifiersDataDetails()
	
	ClassifiersData = New ValueTable;
	ClassifiersData.Columns.Add("Id",      Common.StringTypeDetails(50));
	ClassifiersData.Columns.Add("Version",             Common.TypeDescriptionNumber(11));
	ClassifiersData.Columns.Add("Checksum",   Common.StringTypeDetails(50));
	ClassifiersData.Columns.Add("FileID", Common.StringTypeDetails(800));
	ClassifiersData.Columns.Add("FileAddress",         Common.StringTypeDetails(250));
	ClassifiersData.Columns.Add("Size",             Common.TypeDescriptionNumber(32));
	ClassifiersData.Columns.Add("Description",       Common.StringTypeDetails(100));
	ClassifiersData.Columns.Add("VersionDetails",     Common.StringTypeDetails(800));
	
	Return ClassifiersData;
	
EndFunction

// Defines a service error type by the status code.
//
// Parameters:
//  StatusCode - Number - Status code of service response.
//
// Returns:
//  String - service error code.
//
Function OverrideServiceErrorCode(StatusCode)
	
	If StatusCode = 200 Then
		Return "";
	ElsIf StatusCode = 400 Then
		Return "UnknownClassifierOrApplication";
	ElsIf StatusCode = 401 Then
		Return "NoApplicationAccess";
	ElsIf StatusCode = 403 Then
		Return InvalidUsernameOrPasswordErrorCode();
	ElsIf StatusCode = 429 Then
		Return "AttemptLimitExceeded";
	ElsIf StatusCode = 503 Then
		Return "ServiceTemporarilyUnavailable";
	ElsIf StatusCode = 500
		Or StatusCode = 501
		Or StatusCode = 502
		Or StatusCode > 503 Then
		Return "ServiceError";
	ElsIf StatusCode = 0 Then
		Return "AttachmentError";
	Else
		Return "UnknownError";
	EndIf;
	
EndFunction

// Defines a message to user by the error code.
//
// Parameters:
//  ErrorCode - String - Service error, see the
//              OverrideServiceErrorCode procedure.
//
// Returns:
//  String - message to user.
//
Function OverrideUserMessage(ErrorCode)
	
	If ErrorCode = "UnknownClassifierOrApplication" Then
		Return NStr("ru = 'Классификатор или программа по идентификатору не обнаружены.';
					|en = 'Classifier or application were not found by ID.';");
	ElsIf ErrorCode = "NoApplicationAccess" Then
		Return StringFunctions.FormattedString(
			NStr("ru = 'Доступ к обновлению классификатора невозможен, так как ваша программа не находится на <a href = ""https://portal.1c.eu/support/"">официальной поддержке</a>.';
				|en = 'Cannot access classifier updates as your application is not officially supported.';"));
	ElsIf ErrorCode = InvalidUsernameOrPasswordErrorCode() Then
		Return NStr("ru = 'Ошибка авторизации на Портале 1С:ИТС.
			|Подробнее см. в журнале регистрации.';
			|en = 'An error occurred while authorizing on 1C:ITS Portal.
			|See the event log for details.';");
	ElsIf ErrorCode = "AttemptLimitExceeded" Then
		Return NStr("ru = 'Превышено количество попыток ввода логина и пароля.
			|Проверьте правильность данных авторизации и повторите
			|попытку через 30 минут.';
			|en = 'Exceeded maximum number of authorization attempts.
			|Check if the authorization data is correct and try
			|again in 30 minutes.';");
	ElsIf ErrorCode = "ServiceTemporarilyUnavailable" Then
		Return NStr("ru = 'Не удалось подключиться к сервису классификаторов. Сервис временно недоступен.
			|Повторите попытку подключения позже.';
			|en = 'Cannot connect to classifier service. The service is temporarily unavailable.
			|Please try again later.';");
	ElsIf ErrorCode = "ServiceError" Then
		Return NStr("ru = 'Ошибка работы с сервисом классификаторов.';
					|en = 'An error occurred while using the classifier service.';");
	ElsIf ErrorCode = "AttachmentError" Then
		Return NStr("ru = 'Отсутствует доступ в сеть интернет по причине:
							|- компьютер не подключен к интернету;
							|- неполадки у интернет-провайдера;
							|- подключение к интернету блокирует межсетевой экран, 
							|  антивирусная программа или другое программное обеспечение.';
							|en = 'No Internet access. Possible reasons:
							|- The computer is not connected to the Internet.
							| - Internet service provider issues.
							|- A firewall, antivirus, or another software
							| is blocking the connection.';");
	Else
		Return NStr("ru = 'Неизвестная ошибка при подключении к сервису.';
					|en = 'An unknown error occurred while connecting to the service.';");
	EndIf;
	
EndFunction

// Checks access rights to update classifier data.
// Update can be unavailable if:
//  - The user has insufficient to get updates.
//  - In SaaS mode, updates are imported from the default master data.
//
Procedure CheckUpdateAvailability()
	
	If Not ClassifiersImportAvailable() Then
		Raise NStr("ru = 'Нарушение прав доступа.';
								|en = 'Access violation.';");
	EndIf;
	
EndProcedure

// Checks access rights to update classifier data.
// Update can be unavailable if:
//  - The user has insufficient rights to get updates.
//  - In SaaS mode, updates are imported from the default master data.
//
// Returns:
//  Boolean - True if classifier import is available, if False,
//           not authorized to import classifiers.
//
Function ClassifiersImportAvailable()
	
	MetadataObject = ?(UseAreaData(),
		Metadata.InformationRegisters.DataAreasClassifiersVersions,
		Metadata.InformationRegisters.ClassifiersVersions);
	
	If Not AccessRight("Read", MetadataObject) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Creates a structure of classifier service connection settings
//
Function InitializeClassifiersUpdateParameters()
	
	ImportParameters = New Structure;
	ImportParameters.Insert("ConnectionSetup"   , OnlineUserSupport.ServersConnectionSettings());
	ImportParameters.Insert("ProxyServerSettings", GetFilesFromInternet.ProxySettingsAtServer());
	
	Return ImportParameters;
	
EndFunction

// Determines a property value from reading JSON.
//
// Parameters:
//  ReadJSONObject    - JSONReader - reading JSON to define a value.
//  DefaultValue  - Undefined, String, Number, Boolean - defines
//                         the default value.
//
// Returns:
//  Undefined, String, Number, Boolean - a value.
//
Function JSONPropertyValue(ReadJSONObject, DefaultValue = Undefined)
	
	PropertyName = ReadJSONObject.CurrentValue;
	
	ReadJSONObject.Read();
	If ReadJSONObject.CurrentValueType = JSONValueType.String Then
		Return TrimAll(ReadJSONObject.CurrentValue);
	ElsIf ReadJSONObject.CurrentValueType = JSONValueType.Number
		Or ReadJSONObject.CurrentValueType = JSONValueType.Boolean Then
		Return ReadJSONObject.CurrentValue;
	ElsIf ReadJSONObject.CurrentValueType = JSONValueType.Null
		Or ReadJSONObject.CurrentValueType = JSONValueType.None Then
		Return DefaultValue;
	Else
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось прочитать значение свойства %1.
				|Некорректный тип значения свойства (%2).';
				|en = 'Cannot read value of the %1 property.
				|Property value type is incorrect (%2).';"),
			PropertyName,
			String(String(ReadJSONObject.CurrentValueType)));
		Raise ExceptionText;
	EndIf;
	
EndFunction

// Returns a username and a password of online support.
//
// Returns:
//  Structure - A structure that contains results of defining the
//              authentication parameters for an Online Support user:
//    *AuthenticationData - Structure - parameters of online support user authentication.
//    *ErrorInfo   - String    - error details for the user.
//    *Error               - String    - indicates whether there is an error.
//
Function AuthenticationData()
	
	Result = New Structure;
	Result.Insert("AuthenticationData", New Structure);
	Result.Insert("ErrorInfo",   "");
	Result.Insert("Error",               False);
	
	If Common.DataSeparationEnabled() Then
		
		Raise NStr("ru = 'При работе в модели сервиса информация о классификаторах
			|загружается из поставляемых данных.';
			|en = 'In SaaS, classifier information is imported
			|from the default master data.';");
		
	Else
		SetPrivilegedMode(True);
		Result.AuthenticationData = OnlineUserSupport.OnlineSupportUserAuthenticationData();
		SetPrivilegedMode(False);
		If Result.AuthenticationData = Undefined Then
			Result.Error             = True;
			Result.ErrorInfo =
				NStr("ru = 'Для получения обновлений классификаторов необходимо подключить Интернет-поддержку пользователей.';
					|en = 'To update classifiers, enable online support.';");
			WriteInformationToEventLog(Result.ErrorInfo);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// It is added to authentication data JSON record.
//
// Parameters:
//  MessageDataWriter  - JSONWriter - Record to
//                           add authentication data to.
//  AuthenticationData   - Structure - Authentication parameters of the Online Support user.
//                         (). See AuthenticationData
//
Procedure RecordAuthenticationData(MessageDataWriter, AuthenticationData)
	
	MessageDataWriter.WritePropertyName("authenticationInfo");
	
	MessageDataWriter.WriteStartObject();
	
	MessageDataWriter.WritePropertyName("login");
	MessageDataWriter.WriteValue(AuthenticationData.Login);
	
	MessageDataWriter.WritePropertyName("password");
	MessageDataWriter.WriteValue(AuthenticationData.Password);
	
	MessageDataWriter.WriteEndObject();
	
EndProcedure

// Defines a URL to call a classifier service.
//
// Parameters:
//  Operation  - String - Resource path.
//  Domain     - Number  - Domain ID.
//
// Returns:
//  String - an operation URL.
//
Function ClassifiersServiceOperationURL(Operation, Domain)
	
	Return "https://"
		+ ClassifiersServiceHost(Domain)
		+ "/external-api"
		+ Operation;
	
EndFunction

// Defines a host to call a classifier service.
//
// Parameters:
//  Domain - Number  - Domain ID.
//
// Returns:
//  String - a connection host.
//
Function ClassifiersServiceHost(Domain)
	
	
	If Domain = 0 Then
		Return "classifier-repository.1c.ru";
	Else
		Return "classifier-repository.1c.eu";
	EndIf;
	
EndFunction

// Defines availability of using classifier versions
// imported to the data area.
//
// Returns:
//  Boolean - if True, use the
//           DataAreasClassifiersVersions information register to determine versions.
//
Function UseAreaData()
	
	Return (Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable());
	
EndFunction

// Returns an event name for the event log
//
// Returns:
//  String - Event name.
//
Function EventLogEventName()
	
	Return NStr("ru = 'Работа с классификаторами';
				|en = 'Classifiers';",
		Common.DefaultLanguageCode());
	
EndFunction

// Returns the Unprocessed error code.
//
// Returns:
//  String - error code.
//
Function ErrorCodeUnprocessed()
	
	Return "NotProcessed";
	
EndFunction

// Returns the FileNotImported error code.
//
// Returns:
//  String - error code.
//
Function ErrorCodeFileNotImported()
	
	Return "FileNotImported";
	
EndFunction

// Returns the InvalidUsernameOrPassword error code.
//
// Returns:
//  String - error code.
//
Function InvalidUsernameOrPasswordErrorCode()
	
	Return "InvalidUsernameOrPassword";
	
EndFunction

// Determines classifier data kinds for the 1C-supplied data.
//
// Returns:
//  Array of String- Data kind descriptions.
//
Function KindsOf1CSuppliedDataClassifiers()
	
	DataKinds = New Array;
	
	Classifiers = New Array;
	OnAddClassifiers(Classifiers);
	
	IDs = New Array;
	For Each Specifier In Classifiers Do
		IDs.Add(Specifier.Id);
	EndDo;
	
	If Common.SubsystemExists("OnlineUserSupport.SaaSOperations.ClassifiersOperations") Then
		ModuleClassifiersOperationsInternalSaaS = Common.CommonModule(
			"ClassifiersOperationsInternalSaaS");
		ModuleClassifiersOperationsInternalSaaS.AddClassifiersIDs(
			IDs);
	EndIf;
	
	For Each Id In IDs Do
		DataKind = SuppliedDataKindClassifiers(Id);
		DataKinds.Add(DataKind);
	EndDo;
	
	Return DataKinds;
	
EndFunction

// Returns the number of the disabled update option.
// 
// Returns:
//  Number - An update option value.
//
Function UpdateOptionDisabled()
	Return 0;
EndFunction

// Returns the number of the update option from the service.
// 
// Returns:
//  Number - An update option value.
//
Function OptionsOfUpdateFromService()
	Return 1;
EndFunction

// Returns the number of the update option from the file.
// 
// Returns:
//  Number - An update option value.
//
Function UpdateOptionFromFile()
	Return 2;
EndFunction

// Returns custom classifier update settings.
//
// Returns:
//  Structure - Notification settings:
//    * DisableNotifications - Boolean - If True, the notification on enabling auto-download of classifiers will be disabled in the ToDoList subsystem
//        and the user will not be notified if the ToDoList subsystem is not integrated in the configuration on startup.
//        By default, False.
//        
//
Function UserUpdateSettings()
	
	Settings = New Structure();
	Settings.Insert("DisableNotifications", False);
	
	ClassifiersOperationsOverridable.OnDefineUserSettings(Settings);
	
	Return Settings;
	
EndFunction

// Returns the classifier auto-update flag.
//
// Returns:
//  Boolean - False if it is disabled.
//
Function IsUpdatesAutoDownloadEnabled()
	Return Constants.ClassifiersUpdateOption.Get() <> UpdateOptionDisabled();
EndFunction

#EndRegion

#EndRegion
