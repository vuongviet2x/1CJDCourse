///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "Get add-ins" subsystem.
// CommonModule.GetAddIns.
//
// Server function for importing add-in files:
//  - Get modified add-in files with a scheduled job in silent mode
//  - Get up-to-date add-in files
//  - Get files with add-in versions
//  - Handle CTL events
//  - Handle SSL events
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Creates an add-in details table to use for an update from the service.
//
// Returns:
//  ValueTable - Add-in query details:
//    **ID - String - contains an add-in UUID
//                    specified by a user in the publication base.
//    **Version        - String - The add-in version.
//    **Name  - String - The add-in description.
//    *VersionDate_SSLs    - Date - The date the add-in version (build) was released.
//    *UpdateAutomatically_SSLs - Boolean - Add-in auto-update flag.
//
Function AddInsDetails() Export
	
	AddInsSpecifier = New ValueTable;
	AddInsSpecifier.Columns.Add("Id", Common.StringTypeDetails(50));
	AddInsSpecifier.Columns.Add("Version",        Common.StringTypeDetails(25));
	AddInsSpecifier.Columns.Add("Description",  Common.StringTypeDetails(150));
	AddInsSpecifier.Columns.Add("VersionDate",    Common.DateTypeDetails(DateFractions.DateTime));
	AddInsSpecifier.Columns.Add("AutoUpdate", New TypeDescription("Boolean"));
	
	Return AddInsSpecifier;
	
EndFunction

// Downloads files of latest add-in versions.
//
// Parameters:
//  AddInsDetails - ValueTable - details of add-ins to import
//                             to the infobase. See the GetAddIns.AddInsDetails function.
//                             If the add-in version is filled in the table, the version number
//                             will be checked. If the version number in the service is the same as the version number
//                             in the infobase, the file will not be imported and the LatestVersion error will be set for the version.
//
// Returns:
//  Structure - Contains the result of downloading add-ins:
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
//                    - "НетДоступаКПрограмме" - there is no access to the application on 1C:ITS portal.
//    *ErrorMessage      - String, FormattedString - an error message for the user.
//    *ErrorInfo     - String, FormattedString - an error message for the administrator.
//    *AddInsData - ValueTable, Undefined - contains information on downloaded
//                                add-ins:
//     **Id        - String - contains an add-in ID
//                              specified by the user upon creation of a new add-in.
//     **Version               - String, Undefined - contains a version number of the downloaded add-in.
//     **VersionDate           - Date, Undefined - contains an issue date of the imported add-in version
//                              set when filling in information about
//                              the add-in version.
//     **Description         - String, Undefined - contains description of the add-in, to which
//                              the version belongs.
//     **FileName             - String, Undefined - contains a file name set when
//                              creating an add-in version.
//     **Size               - Number - File size.
//     **FileAddress           - String, Undefined - contains an add-in file address
//                              in a temporary storage.
//     **ErrorCode            - String - contains an error code of downloading the add-in:
//                               - <Пустая строка> - update is imported successfully.
//                               - ОтсутствуетКомпонента - an add-in is not found
//                                 in the add-in service by the passed ID.
//                               - ФайлНеЗагружен - an error occurred while
//                                 trying to import add-in file from service;
//                               - АктуальнаяВерсия - when receiving the latest version of the add-in,
//                                 no later version was found.
//
// Example:
//	1. Version update
//
//	ModuleGetAddIns = Common.CommonModule("GetAddIns");
//	AddInsDetails = ModuleGetAddIns.AddInsDetails();
//
//	TableRow = AddInsDetails.Add();
//	TableRow.ID = "InputDevice";
//	TableRow.Version = "8_1_7_0"; // Version number is optional (might be blank).
//
//	Result = ModuleGetAddIns.RelevantAddInsVersions(AddInsDetails);
//
//	Import result
//	Result.ErrorCode = "";
//	Result.ErrorMessage = "";
//	Result.ErrorInfo = "";
//
//	ResultString = Result.AddInsDetails[0];
//	ResultString.ID = "InputDevice";
//	ResultString.Version = "8_1_8_0";
//	ResultString.VersionDate = '01/10/2017 6:00';
//	ResultString.Description = "1C:Barcode scanners (NativeApi)";
//	ResultString.FileName = "NativeInputDevice1CDriver_8_1_8_0.zip";
//	ResultString.FileAddress = [temporary storage uid];
//	ResultString.ErrorCode = "";
//
//	2. An error occurred while using the service
//
//	ModuleGetAddIns = Common.CommonModule("GetAddIns");
//	AddInsDetails = ModuleGetAddIns.AddInsDetails();
//
//	TableRow = AddInsDetails.Add();
//	TableRow.ID = "ProtonScanner";
//	TableRow.Version = "1_1";
//
//	Result = ModuleGetAddIns.RelevantAddInsVersions(AddInsDetails);
//
//	Import result
//	Result.ErrorCode = "ServiceTemporarilyUnavailable";
//	Result.ErrorMessage = "The service is temporarily unavailable due to maintenance.;
//	Result.ErrorInfo = "Cannot connect to the add-in service. Service is temporarily unavailable.";
//		Result.AddInsDetails = Undefined;
//	3. An error occurred when downloading the add-in
//
//	ModuleGetAddIns = Common.CommonModule("GetAddIns");
//
//	AddInsDetails = ModuleGetAddIns.AddInsDetails();
//	TableRow = AddInsDetails.Add();
//
//	TableRow.ID = "ProtonScanner";
//	TableRow.Version = "1_2";
//	Result = ModuleGetAddIns.RelevantAddInsVersions(AddInsDetails);
//
//	Import result
//
//	Result.ErrorCode = "";
//	Result.ErrorMessage = "";
//	Result.ErrorInfo = "";
//	Result.AddInsDetails = Undefined;
//	ResultString = Result.AddInsDetails[0];
//
//	ResultString.ID = "ProtonScanner";
//	ResultString.Version = Undefined;
//	ResultString.VersionDate = Undefined;
//	ResultString.Description = Undefined;
//	ResultString.FileName = Undefined;
//	ResultString.FileAddress = Undefined;
//	ResultString.ErrorCode = "LatestVersion";
//	
//
Function CurrentVersionsOfExternalComponents(AddInsDetails) Export
	
	// 1. Check the possibility to get add-ins from the service.
	// 
	CheckImportAvailability();
	
	// 2. Check an add-in request.
	If AddInsDetails.Count() = 0 Then
		OperationResult = ImportResultDetails();
		DeleteInternalDataOfAddIns(OperationResult.AddInsData);
		Return ImportResultDetails();
	EndIf;
	
	// 3. Check data for an add-in request.
	OperationResult = CheckTheDataFillingOfExternalComponents(
		AddInsDetails);
	If ValueIsFilled(OperationResult.ErrorCode) Then
		Return OperationResult;
	EndIf;
	
	// 4. Get information about the most up-to-date add-in versions in the service.
	// 
	ActivationData = AuthenticationData();
	If ActivationData.Error Then
		OperationResult.ErrorCode = InvalidUsernameOrPasswordErrorCode();
		FillPropertyValues(OperationResult, ActivationData, "ErrorInfo");
		OperationResult.ErrorMessage = ActivationData.ErrorInfo;
		Return OperationResult;
	EndIf;
	OperationResult = RelevantAddInsVersionsInformation(
		AddInsDetails,
		ActivationData.AuthenticationData);
	
	If ValueIsFilled(OperationResult.ErrorCode) Then
		Return OperationResult;
	EndIf;
	
	// 5. Determine relevant versions.
	ProcessLatestVersions(AddInsDetails, OperationResult.AddInsData);
	
	// 6. Import add-in files.
	ImportAddInsFiles(OperationResult);
	
	// 7. Prepare import result.
	DeleteInternalDataOfAddIns(OperationResult.AddInsData);
	
	Return OperationResult;
	
EndFunction

// Imports files of add-in versions.
//
// Parameters:
//  AddInsDetails - ValueTable - details of add-ins
//                             to import to the infobase. See the GetAddIns.AddInsDetails function.
//
// Returns:
//  Structure - Contains the result of downloading add-ins:
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
//                    - "НетДоступаКПрограмме" - there is no access to the application on 1C:ITS portal.
//    *ErrorMessage      - String, FormattedString - an error message for the user.
//    *ErrorInfo     - String, FormattedString - an error message for the administrator.
//    *AddInsData - ValueTable, Undefined - contains information on downloaded
//                              add-ins:
//     **Id        - String - contains an add-in ID
//                              specified by the user upon creation of a new add-in.
//     **Version               - String, Undefined - contains a version number of the downloaded add-in.
//     **VersionDate           - Date, Undefined - contains an issue date of the imported add-in version
//                              set when filling in information about
//                              the add-in version.
//     **Description         - String, Undefined - contains description of the add-in, to which
//                              the version belongs.
//     **FileName             - String, Undefined - contains a file name set when
//                              creating an add-in version.
//     **Size               - Number - File size.
//     **FileAddress           - String, Undefined - contains an add-in file address
//                              in a temporary storage.
//     **ErrorCode            - String - contains an error code of downloading the add-in:
//                               - <Пустая строка> - update is imported successfully.
//                               - ОтсутствуетКомпонента - an add-in is not found
//                                 in the add-in service by the passed ID.
//                               - ФайлНеЗагружен - an error occurred while
//                                 trying to import add-in file from service;
//                               - ОтсутствуетВерсия - The add-in version matching the passed version is not found in the add-in service.
//                                 
//
// Example:
//	ОтсутствуетВерсия1. Version update
//
//	ModuleGetAddIns = Common.CommonModule("GetAddIns");
//	AddInsDetails = ModuleGetAddIns.AddInsDetails();
//
//	TableRow = AddInsDetails.Add();
//	TableRow.ID = "InputDevice";
//	TableRow.Version = "8_1_8_0";
//
//	Result = ModuleGetAddIns.RelevantAddInsVersions(AddInsDetails);
//
//	Import result:
//	Result.ErrorCode = "";
//	Result.ErrorMessage = "";
//	Result.ErrorInfo = "";
//
//	ResultString = Result.AddInsDetails[0];
//	ResultString.ID = "InputDevice";
//	ResultString.Version = "8_1_8_0";
//	ResultString.VersionDate = '01/10/2017 6:00';
//	ResultString.Description = "1C:Barcode scanners (NativeApi)";
//	ResultString.FileName = "NativeInputDevice1CDriver_8_1_8_0.zip";
//	ResultString.FileAddress = [temporary storage uid];
//	ResultString.ErrorCode = "";
//
//	2. An error occurred while using the service
//
//	ModuleGetAddIns = Common.CommonModule("GetAddIns");
//	AddInsDetails = ModuleGetAddIns.AddInsDetails();
//
//	TableRow = AddInsDetails.Add();
//	TableRow.ID = "ProtonScanner";
//	TableRow.Version = "1_1";
//
//	Result = ModuleGetAddIns.RelevantAddInsVersions(AddInsDetails);
//
//	// Import result:
//	Result.ErrorCode = "ServiceTemporarilyUnavailable";
//	Result.ErrorMessage = "The service is temporarily unavailable due to maintenance.;
//	Result.ErrorInfo = "When connecting to the XXXXXXXX service, errors XXXXXXX occurred.";
//	Result.AddInsDetails = Undefined;
//
//	3. An error occurred when downloading the add-in
//
//	ModuleGetAddIns = Common.CommonModule("GetAddIns");
//	AddInsDetails = ModuleGetAddIns.AddInsDetails();
//
//	TableRow = AddInsDetails.Add();
//	TableRow.ID = "ProtonScanner";
//	TableRow.Version = "1_2";
//
//	Result = ModuleGetAddIns.RelevantAddInsVersions(AddInsDetails);
//
//	Import result:
//	Result.ErrorCode = "";
//	Result.ErrorMessage = "";
//	Result.ErrorInfo = "";
//	Result.AddInsDetails = Undefined;
//
//	ResultString = Result.AddInsDetails[0];
//	ResultString.ID = "ProtonScanner";
//	ResultString.Version = Undefined;
//	ResultString.VersionDate = Undefined;
//	ResultString.Description = Undefined;
//	ResultString.FileName = Undefined;
//	ResultString.FileAddress = Undefined;
//	ResultString.ErrorCode = "VersionNotFound";
//
Function VersionsOfExternalComponents(AddInsDetails) Export
	
	// 1. Check the possibility to get add-ins from the service.
	// 
	CheckImportAvailability();
	
	// 2. Check the add-in query.
	If AddInsDetails.Count() = 0 Then
		OperationResult = ImportResultDetails();
		DeleteInternalDataOfAddIns(OperationResult.AddInsData);
		Return ImportResultDetails();
	EndIf;
	
	// 3. Check data for an add-in request.
	OperationResult = CheckTheDataFillingOfExternalComponents(
		AddInsDetails);
	If ValueIsFilled(OperationResult.ErrorCode) Then
		Return OperationResult;
	EndIf;
	
	// 4. Get information about the most up-to-date add-in versions in the service.
	// 
	OperationResult = AddInsVersionsInformation(AddInsDetails);
	
	If ValueIsFilled(OperationResult.ErrorCode) Then
		Return OperationResult;
	EndIf;
	
	// 5. Import add-in files.
	ImportAddInsFiles(OperationResult);
	
	// 6. Prepare import result.
	DeleteInternalDataOfAddIns(OperationResult.AddInsData);
	
	Return OperationResult;
	
EndFunction

// Checks if it is possible to import add-ins.
//
// Returns:
//  Boolean - if True, add-ins can be imported.
//
Function LoadingExternalComponentsIsAvailable() Export
	
	If Common.DataSeparationEnabled() Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Checks whether the add-in update handler can be started.
//
// Returns:
//  Boolean - If True, the add-ins can be updated.
//
Function CanDownloadAddInsInteractively() Export
	
	If LoadingExternalComponentsIsAvailable()
		And Users.IsFullUser() Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Returns the details of the add-ins that have an update in the add-in service.
// 
//
// Parameters:
//  IDs - Array of String, Undefined - List of add-in UUIDs.
//                   
// 
// Returns:
//  Structure - Contains the add-ins check result.:
//    * ErrorCode - String - String code of the occurred error that
//                  can be processed by the calling functionality:
//                    - <Пустая строка> - No errors occurred.
//                    - "НеверныйЛогинИлиПароль" - Invalid username or password.
//                    - "ПревышеноКоличествоПопыток" - The number of login attempts is exceeded.
//                      
//                    - "ОшибкаПодключения" - Service connection error.
//                    - "ОшибкаСервиса" - Internal service error.
//                    - "НеизвестнаяОшибка" - Unknown (unprocessable) error occurred when
//                      obtaining data.
//                    - "СервисВременноНеДоступен" - Server is unavailable due to maintenance.
//                    - "НетДоступаКПрограмме" - App is unavailable on 1C:ITS Portal.
//    *ErrorMessage      - String, FormattedString - an error message for the user.
//    *ErrorInfo     - String, FormattedString - an error message for the administrator.
//    *AddInsData - ValueTable, Undefined - Contains add-ins information.
//                                See AddInsDetails.
//
Function AddInsUpdateAvailable(IDs = Undefined) Export
	
	OperationResult = New Structure;
	OperationResult.Insert("ErrorCode",          "");
	OperationResult.Insert("ErrorMessage",  "");
	OperationResult.Insert("ErrorInfo", "");
	
	// 1. Check the possibility to get add-ins from the service.
	CheckImportAvailability();
	
	// 2. Update the add-ins list for querying the service.
	ModuleAddInsServer = Common.CommonModule("AddInsServer");
	AddInsDetails = ModuleAddInsServer.ComponentsToUse("ForImport");
	
	DeleteRows_ = New Array;
	If IDs <> Undefined Then
		
		For Each AddInDetails In AddInsDetails Do
			If IDs.Find(AddInDetails.Id) = Undefined Then
				DeleteRows_.Add(AddInDetails);
			EndIf;
		EndDo;
		
		For Each AddInDetails In DeleteRows_ Do
			AddInsDetails.Delete(AddInDetails);
		EndDo;
		
	EndIf;
	
	// 3. Update the cache data from the add-in service.
	UpdateResult = UpdateAddInsCacheData(AddInsDetails);
	If ValueIsFilled(UpdateResult.ErrorCode) Then
		FillPropertyValues(
			UpdateResult,
			OperationResult,
			"ErrorCode,ErrorMessage,ErrorInfo");
		Return OperationResult;
	EndIf;
	
	// 4. Populate with cached data.
	AddInsData = AddInsDetails();
	For Each AddInDetails In AddInsDetails Do
		
		CacheDataVersions = InformationRegisters.AddInsDataCache.DataOfCache(AddInDetails.Id);
		If CacheDataVersions = Undefined Then
			Continue;
		EndIf;
		
		If CacheDataVersions.VersionDate > AddInDetails.VersionDate Then
			AddInDetails = AddInsData.Add();
			FillPropertyValues(
				AddInDetails,
				CacheDataVersions);
		EndIf;
		
	EndDo;
	OperationResult.Insert(
		"AddInsData",
		AddInsData);
	
	Return OperationResult;
	
EndFunction

// Returns add-in settings.
// 
// Returns:
//  Structure - 0 - Disabled.
//    1 - Via internet, on schedule.
//              2 - Via file, on schedule.
//              **AddInsFile - String - The path to an add-ins file.
//              **Schedule - JobSchedule - Update schedule.
//              **SchedulePresentation - String - The user presentation of the schedule.
//              **AddInsImportAvailable - Boolean - Add-in import availability flag.
//                    0 - Disabled.
//                    1 - Via internet, on schedule.
//                    2 - Via file, on schedule.
//    **AddInsFile - String - The path to an add-ins file.
//    **Schedule - JobSchedule - Update schedule.
//    **SchedulePresentation - String - The user presentation of the schedule.
//    **AddInsImportAvailable - Boolean - Add-in import availability flag.
//
Function AddInsUpdateSettings() Export
	
	Result = New Structure;
	Result.Insert("UpdateOption",       ModeUpdateDisabled());
	Result.Insert("AddInsFile",    "");
	Result.Insert("Schedule",              Undefined);
	Result.Insert("SchedulePresentation", NStr("ru = 'Настроить расписание';
														|en = 'Configure schedule';"));
	Result.Insert(
		"LoadingExternalComponentsIsAvailable",
		LoadingExternalComponentsIsAvailable());
	
	If Not Result.LoadingExternalComponentsIsAvailable Then
		Return Result;
	EndIf;
	
	If AccessRight("Read", Metadata.Constants.AddInsUpdateOption) Then
		Result.UpdateOption    = Constants.AddInsUpdateOption.Get();
		Result.AddInsFile = Constants.AddInsFile.Get();
	EndIf;
	
	SetPrivilegedMode(True);
	
	UpdateJobs = JobsAddInsUpdate();
	If UpdateJobs.Count() = 0 Then
		AddUpdateScheduledJob(False);
		UpdateJobs = JobsAddInsUpdate();
	EndIf;
	
	If UpdateJobs.Count() <> 0 Then
		Result.Schedule = UpdateJobs[0].Schedule;
		Result.SchedulePresentation =
			OnlineUserSupportClientServer.SchedulePresentation(
				Result.Schedule);
	EndIf;
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

// Changes the add-in update settings.
//
// Parameters:
//  Settings - Structure - Add-in update scheduled job settings.
//    **UpdateOption - Number - Update option number.
//    Add-in update scheduled job settings.
//    **UpdateOption - Number - Update option number.
//
Procedure ChangeAddInsUpdateSettings(Settings) Export
	
	If Not LoadingExternalComponentsIsAvailable() Then
		Return;
	EndIf;
	
	SettingsOfUpdate = New Structure("Schedule,UpdateOption,AddInsFile");
	FillPropertyValues(SettingsOfUpdate, Settings);
	
	If SettingsOfUpdate.Schedule <> Undefined Then
		WriteUpdateSchedule(Settings.Schedule);
	EndIf;
	
	If Not CanModifyScheduledJobSettings() Then
		Return;
	EndIf;
	
	If SettingsOfUpdate.UpdateOption <> Undefined Then
		Constants.AddInsUpdateOption.Set(Settings.UpdateOption);
	EndIf;
	
	If SettingsOfUpdate.AddInsFile <> Undefined Then
		Constants.AddInsFile.Set(Settings.AddInsFile);
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

#Region IntegrationWithStandardSubsystemsLibrary

#Region SSLCore

// Integration with the StandardSubsystems.Core subsystem.
//
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	NewPermissions = New Array;
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Resolution = ModuleSafeModeManager.PermissionToUseInternetResource(
		"HTTPS",
		AddInsServiceHost(0),
		443,
		NStr("ru = 'Сервис внешних компонент (ru)';
			|en = 'Add-in service (ru)';"));
	NewPermissions.Add(Resolution);
	
	Resolution = ModuleSafeModeManager.PermissionToUseInternetResource(
		"HTTPS",
		AddInsServiceHost(1),
		443,
		NStr("ru = 'Сервис внешних компонент (eu)';
			|en = 'Add-in service (eu)';"));
	NewPermissions.Add(Resolution);
	
	PermissionsRequests.Add(ModuleSafeModeManager.RequestToUseExternalResources(NewPermissions));
	
EndProcedure

#EndRegion

#Region SSLInfobaseUpdate

// Fills in a list of infobase update handlers.
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	If Not Common.DataSeparationEnabled() Then
		Handler = Handlers.Add();
		Handler.Version              = "2.3.1.7";
		Handler.Procedure           = "GetAddIns.UpdateGetAddInsSettings";
		Handler.SharedData         = False;
		Handler.InitialFilling = False;
		Handler.ExecutionMode     = "Deferred";
		Handler.Id       = New UUID("0589c734-f2a8-4af1-97b1-6e8deb4830d6");
		Handler.Comment         = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1. Обновление настроек получения внешних компонент.';
				|en = '%1. Update add-in import settings.';"),
			EventLogEventName());
	EndIf;
	
	If Not Common.DataSeparationEnabled() Then
		Handler = Handlers.Add();
		Handler.Version              = "2.7.2.23";
		Handler.Procedure           = "GetAddIns.SetAddInsObtainSettings";
		Handler.SharedData         = False;
		Handler.InitialFilling = False;
		Handler.ExecutionMode     = "Deferred";
		Handler.Id       = New UUID("71c61b49-5110-49d7-99ea-9c038445df88");
		Handler.Comment         = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1. Установка настроек получения внешних компонент.';
				|en = '%1. Configure add-in import settings.';"),
			EventLogEventName());
	EndIf;
	
EndProcedure

// Adds a scheduled job of checking add-in updates.
//
Procedure UpdateGetAddInsSettings(Parameters) Export
	
	SetPrivilegedMode(True);
	
	WriteInformationToEventLog(
		NStr("ru = 'Обновление настроек подсистемы ""Получение внешних компонент"". Начало обновления.';
			|en = 'Update settings of the ""Get add-ins"" subsystem. Update started.';"),
		False);
	
	AddUpdateScheduledJob();
	
	WriteInformationToEventLog(
		NStr("ru = 'Обновление настроек подсистемы ""Получение внешних компонент"". Успешно завершено.';
			|en = 'Update settings of the ""Get add-ins"" subsystem. Completed successfully.';"),
		False);
	
EndProcedure

// Sets the initial value of the AddInsUpdateOption constant.
//
Procedure SetAddInsObtainSettings(Parameters) Export
	
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	WriteInformationToEventLog(
		NStr("ru = 'Обновление настроек подсистемы ""Получение внешних компонент"". Начало обновления.';
			|en = 'Update settings of the ""Get add-ins"" subsystem. Update started.';"),
		False);
	
	If Not OnlineUserSupport.AuthenticationDataOfOnlineSupportUserFilled() Then
		Return;
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("Metadata", Metadata.ScheduledJobs.AddInsUpdate);
	Filter.Insert("Use", True);
	
	UpdateJobs = ScheduledJobsServer.FindJobs(Filter);
	
	If UpdateJobs.Count() > 0 Then
		
		BeginTransaction();
		
		Try
			Constants.AddInsUpdateOption.Set(ModeUpdateFromService());
			CommitTransaction();
		Except
			RollbackTransaction();
			ErrorInfo = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				WriteInformationToEventLog(
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Не удалось задать вариант обновления внешних компонент по причине:
							|%1';
							|en = 'Cannot set an add-in update option due to:
							|%1';"),
						ErrorInfo));
			Raise ErrorInfo;
		EndTry;
		
		WriteInformationToEventLog(
			NStr("ru = 'Установлен вариант обновления внешних компонент.';
				|en = 'Add-in update option set.';"),
			False);
		
	Else
		AddUpdateScheduledJob();
	EndIf;
	
	WriteInformationToEventLog(
		NStr("ru = 'Обновление настроек подсистемы ""Получение внешних компонент"". Успешно завершено.';
			|en = 'Update settings of the ""Get add-ins"" subsystem. Completed successfully.';"),
		False);
	
EndProcedure

#EndRegion

#EndRegion

#Region OnlineUserSupportSubsystemsIntegration

// It is called when changing a username and a password of an OUS user
// to the infobase from all library usage contexts.
//
Procedure OnChangeAuthenticationData(Login, Password) Export
	
	If ValueIsFilled(Login) Then
		If Constants.AddInsUpdateOption.Get() = ModeUpdateDisabled() Then
			Constants.AddInsUpdateOption.Set(
				ModeUpdateFromService());
			// The usages of scheduled jobs will be enabled in the constant manager.
		Else
			SetScheduledJobsUsage(True);
		EndIf;
	Else
		If Constants.AddInsUpdateOption.Get() = ModeUpdateFromService() Then
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
		AddInsServiceHost(0),
		NStr("ru = 'Получение внешних компонент';
			|en = 'Get add-ins';"));
	OnlineSupportServicesHosts.Insert(
		AddInsServiceHost(1),
		NStr("ru = 'Получение внешних компонент';
			|en = 'Get add-ins';"));
	
EndProcedure

// It is called from the OnCreateAtServer() handler of the OSL administration panel.
// Sets display of controls for OUSL library subsystems.
// 
//
// Parameters:
//  Form - ClientApplicationForm - Form of management panel.
//
Procedure OnlineSupportAndServicesOnCreateAtServer(Form) Export
	
	Items = Form.Items;
	
	If Not Users.IsFullUser() Then
		Items.AddInsUpdate.Visible = False;
	EndIf;
	
	SettingsOfUpdate = AddInsUpdateSettings();
	
	If SettingsOfUpdate.LoadingExternalComponentsIsAvailable
			And CanModifyScheduledJobSettings() Then
		Items.GroupAddInsUpdate.Visible = True;
	Else
		Items.GroupAddInsUpdate.Visible = False;
		Return;
	EndIf;
	
	Form.AddInsUpdateOption = SettingsOfUpdate.UpdateOption;
	Form.AddInsFile = SettingsOfUpdate.AddInsFile;
	Form.AddInsUpdateOptionPreviousValue = SettingsOfUpdate.UpdateOption;
	
	Items.DecorationAddInsUpdateSchedule.Title = SettingsOfUpdate.SchedulePresentation;
	
	If Not OnlineUserSupport.AuthenticationDataOfOnlineSupportUserFilled()
			And Form.AddInsUpdateOption = ModeUpdateFromService() Then
		Items.DecorationAddInsUpdateNotRunning.Visible = True;
	Else
		Items.DecorationAddInsUpdateNotRunning.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region ScheduledJobsHandlers

// AddInsUpdate scheduled job handler.
//
Procedure AddInsUpdate() Export
	
	Common.OnStartExecuteScheduledJob(
		Metadata.ScheduledJobs.AddInsUpdate);
		
	UpdateMode = Constants.AddInsUpdateOption.Get();
	If UpdateMode = ModeUpdateFromService() Then
		
		If Not OnlineUserSupport.AuthenticationDataOfOnlineSupportUserFilled() Then
			WriteInformationToEventLog(
				NStr("ru = 'Не заполнены данные аутентификации Интернет-поддержки пользователей.
					|Обновление внешних компонент из сервиса невозможно.';
					|en = 'Online support authentication credentials are not completed.
					|Cannot update add-ins from the service.';"),
			False,
			Metadata.ScheduledJobs.AddInsUpdate);
			Return;
		EndIf;
		
		UpdateAddIns();
		
	ElsIf UpdateMode = ModeUpdateFromFile() Then
		
		FileName = Constants.AddInsFile.Get();
		If Not ValueIsFilled(FileName) Then
			WriteInformationToEventLog(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Файл %1 с внешними компонентами не найден.';
						|en = 'The %1 file with add-ins is not found.';"),
					FileName),
				True,
				Metadata.ScheduledJobs.AddInsUpdate);
			Return;
		EndIf;
		
		AddInsFile = New File(FileName);
		If Not AddInsFile.Exists() Then
			WriteInformationToEventLog(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Файл %1 с внешними компонентами не существует.';
						|en = 'The %1 file with add-ins does not exist.';"),
					FileName),
				True,
				Metadata.ScheduledJobs.AddInsUpdate);
			Return;
		EndIf;
		
		UpdateAddInsFromFile(FileName);
		
	EndIf;
	
EndProcedure

// Enables or disables the AddInsUpdate scheduled job.
//
// Parameters:
//  Use - Boolean - indicates whether a scheduled job is used.
//
Procedure SetScheduledJobsUsage(Use) Export
	
	SetPrivilegedMode(True);
	Jobs = JobsAddInsUpdate();
	If Jobs.Count() <> 0 Then
		For Each Job In Jobs Do
			ScheduledJobsServer.SetScheduledJobUsage(
				Job,
				Use);
		EndDo;
	Else
		AddUpdateScheduledJob(Use);
	EndIf;
	
EndProcedure

#EndRegion

#Region SaaSOperations

// See SuppliedDataOverridable.GetHandlersForSuppliedData.
//
Procedure OnDefineSuppliedDataHandlers(Handlers) Export
	
	DataKinds = KindsOf1CSuppliedDataAddIns();
	For Each DataKind In DataKinds Do 
		StrHandler = Handlers.Add();
		StrHandler.DataKind      = DataKind;
		StrHandler.HandlerCode = DataKind;
		StrHandler.Handler     = Common.CommonModule("GetAddIns");
	EndDo;
	
EndProcedure

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
	If StrFind(DataKind, SuppliedDataKindAddIns()) = 0 Then
		Return;
	EndIf;
	
	Id = "";
	For Each Characteristic In Descriptor.Properties.Property Do
		If Characteristic.Code = "Id" Then
			Id = Characteristic.Value;
			Break;
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(Id) Then
		Return;
	EndIf;
	
	ComponentsToUse = ComponentsToUse();
	
	ToImport = (ComponentsToUse.Find(Id) <> Undefined);
	
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
	If StrFind(DataKind, SuppliedDataKindAddIns()) = 0 Then
		Return;
	EndIf;
	
	ModuleAddIns = Common.CommonModule("AddInsServer");
	ComponentDetails      = ModuleAddIns.SuppliedSharedAddInDetails();
	
	For Each Characteristic In Descriptor.Properties.Property Do
		If Characteristic.Code = "Id" Then
			ComponentDetails.Id = Characteristic.Value;
		ElsIf Characteristic.Code = "Version" Then
			ComponentDetails.Version = Characteristic.Value;
		ElsIf Characteristic.Code = "VersionDate" Then
			ComponentDetails.VersionDate = StringToDate(Characteristic.Value);
		ElsIf Characteristic.Code = "Description" Then
			ComponentDetails.Description = Characteristic.Value;
		ElsIf Characteristic.Code = "FileName" Then
			ComponentDetails.FileName = Characteristic.Value;
		EndIf;
	EndDo;
	
	ComponentDetails.PathToFile = PathToFile;
	ModuleAddIns.UpdateSharedAddIn(ComponentDetails);
	
EndProcedure

// Runs if data processing is failed due to an error.
//
Procedure DataProcessingCanceled(Val Descriptor) Export
	
	ModuleSuppliedData = Common.CommonModule("SuppliedData");
	
	WriteInformationToEventLog(
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

#Region DataProcessorAddInsUpdate

// Gets the IDs and versions of the add-ins user in the configuration.
// Intended for interactive data import from the "Updating add-ins" data processor.
// 
//
// Parameters:
//  AddInsFilter - ValueList - Add-in ID filter.
//
// Returns:
//  ValueTable - Contains add-in settings.
//
Function AddInsDataForInteractiveUpdate(
		AddInsFilter) Export
	
	If Common.DataSeparationEnabled() Then
		Raise NStr("ru = 'Использование функции при работе в модели сервиса запрещено.';
								|en = 'The function cannot be used in SaaS.';");
	EndIf;
	
	ModuleAddInsServer = Common.CommonModule("AddInsServer");
	AddInsDetails = ModuleAddInsServer.ComponentsToUse("ForImport");
	
	IsFilterApplied = AddInsFilter.Count() > 0;
	DeleteRows_ = New Array;
	For Each AddInDetails In AddInsDetails Do
		
		If IsFilterApplied
				And AddInsFilter.FindByValue(AddInDetails.Id) = Undefined Then
			DeleteRows_.Add(AddInDetails);
		EndIf;
		
	EndDo;
	
	For Each AddInDetails In DeleteRows_ Do
		AddInsDetails.Delete(AddInDetails);
	EndDo;
	
	Return AddInsDetails;
	
EndFunction

// Updates add-in data in a background job.
//
// Parameters:
//  ProcedureParameters - Structure - data for update.
//  StorageAddress - String - an address of the update result storage.
//
Procedure AddInsInteractiveUpdateFromService(
		ProcedureParameters,
		StorageAddress) Export
	
	UpdateResult = New Structure;
	UpdateResult.Insert("ErrorCode",         "");
	UpdateResult.Insert("ErrorMessage", "");
	
	AddInsData = ProcedureParameters.AddInsData;
	AddInsData.Columns.Add("FileAddress", Common.StringTypeDetails(250));
	AddInsData.Columns.Add("ErrorCode", Common.StringTypeDetails(150));
	
	Result = AuthenticationData();
	If Result.Error Then
		UpdateResult.ErrorCode = "InvalidUsernameOrPassword";
		UpdateResult.ErrorMessage = Result.ErrorInfo;
		PutToTempStorage(UpdateResult, StorageAddress);
		Return;
	EndIf;
	
	ImportResult1 = New Structure;
	ImportResult1.Insert("ErrorCode",         "");
	ImportResult1.Insert("ErrorMessage", "");
	ImportResult1.Insert("ErrorInfo",     "");
	ImportResult1.Insert("AddInsData", AddInsData);
	ImportAddInsFiles(
		ImportResult1);
	
	If ValueIsFilled(ImportResult1.ErrorCode) Then
		FillPropertyValues(
			UpdateResult,
			ImportResult1,
			"ErrorCode, ErrorMessage");
		PutToTempStorage(UpdateResult, StorageAddress);
		Return;
	EndIf;
	
	If Not ValueIsFilled(ImportResult1.ErrorCode) Then
		ModuleAddInsServer = Common.CommonModule("AddInsServer");
		ModuleAddInsServer.UpdateAddIns(ImportResult1.AddInsData, StorageAddress);
	EndIf;
	
EndProcedure

// Processes files containing add-in updates in a background job.
//
// Parameters:
//  ProcedureParameters - Structure - data for update.
//  StorageAddress - String - an address of the update result storage.
//
Procedure InteractiveUpdateOfAddInsFromFile(
		ProcedureParameters,
		StorageAddress) Export
	
	FileData            = ProcedureParameters.FileData;
	AddInsData = ProcedureParameters.AddInsData;
	
	AddInsData.Columns.Add("FileAddress", Common.StringTypeDetails(250));
	AddInsData.Columns.Add("ErrorCode", Common.StringTypeDetails(150));
	
	AddInFileName = GetTempFileName(".zip");
	FileData.Write(AddInFileName);
	FileData = Undefined;
	
	PuttingAddInsFilesToStorage(
		AddInFileName,
		AddInsData);
	
	FileSystem.DeleteTempFile(AddInFileName);
	
	ModuleAddInsServer = Common.CommonModule("AddInsServer");
	ModuleAddInsServer.UpdateAddIns(AddInsData, StorageAddress);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region ScheduledJobsHandlers

// Creates the AddInsUpdate scheduled job
// when updating an infobase or connecting to online support.
//
// Parameters:
//  Use - Boolean - Scheduled job usage flag.
//
Procedure AddUpdateScheduledJob(Use = True)
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	If Not OnlineUserSupport.AuthenticationDataOfOnlineSupportUserFilled() Then
		Return;
	EndIf;
		
	Filter = New Structure;
	Filter.Insert("Metadata", Metadata.ScheduledJobs.AddInsUpdate);
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
		JobParameters.Insert("Metadata",    Metadata.ScheduledJobs.AddInsUpdate);
		JobParameters.Insert("Schedule",    Schedule);
		JobParameters.Insert("Description",  NStr("ru = 'Обновление внешних компонент';
														|en = 'Updating add-ins';"));
		
		BeginTransaction();
		
		Try
			ScheduledJobsServer.AddJob(JobParameters);
			If Use
					And Constants.AddInsUpdateOption.Get() = ModeUpdateDisabled() Then
				Constants.AddInsUpdateOption.Set(
					ModeUpdateFromService());
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			ErrorInfo = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				WriteInformationToEventLog(
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Не удалось создать регламентное задание обновления внешних компонент по причине:
							|%1';
							|en = 'Cannot create a scheduled job for updating add-ins due to:
							|%1';"),
						ErrorInfo),
					True,
					Metadata.ScheduledJobs.AddInsUpdate);
			Raise ErrorInfo;
		EndTry;
		
		WriteInformationToEventLog(
			NStr("ru = 'Создано регламентное задание обновления внешних компонент.';
				|en = 'Scheduled job for add-in update was created.';"),
			False,
			Metadata.ScheduledJobs.AddInsUpdate);
	EndIf;
	
EndProcedure

// Sets a scheduled job schedule.
//
// Parameters:
//  Schedule - JobSchedule - Add-in update schedule.
//
Procedure WriteUpdateSchedule(Schedule)
	
	RepeatPeriodInDay = Schedule.RepeatPeriodInDay;
	If RepeatPeriodInDay > 0
		And RepeatPeriodInDay < 300 Then
		Common.MessageToUser(
			NStr("ru = 'Интервал обновления не может быть задан чаще, чем один раз 5 минут.';
				|en = 'The update interval cannot be shorter than 5 minutes.';"));
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	UpdateJobs = JobsAddInsUpdate();
	If UpdateJobs.Count() <> 0 Then
		ScheduledJobsServer.SetJobSchedule(
			UpdateJobs[0],
			Schedule);
	EndIf;
	
EndProcedure

// Determines the created AddInsUpdate scheduled jobs.
//
// Returns:
//  Array of ScheduledJob - An array of scheduled jobs.
//  See the "ScheduledJob" method in Syntax Assistant.
//
Function JobsAddInsUpdate()
	
	Filter = New Structure;
	Filter.Insert("Metadata", Metadata.ScheduledJobs.AddInsUpdate);
	Return ScheduledJobsServer.FindJobs(Filter);
	
EndFunction

#EndRegion

#Region ServiceOperationsCall

////////////////////////////////////////////////////////////////////////////////
// Calling the /external-components/version/latest operation.

// Returns a list of details of relevant component versions that are
// currently available to the user.
//
// Parameters:
//  AddInsDetails  - ValueTable - see the GetAddIns.AddInsDetails function.
//
// Returns:
//   Structure - Contains the operation result:
//    *ErrorCode              - String -an error code of add-in service.
//    *ErrorMessage      - String - error details for the user.
//    *ErrorInfo     - String - error details for the administrator.
//    *AddInsData - ValueTable - information on add-ins:
//      **Id       - String - contains an add-in UUID that is
//                              specified by the user when creating an add-in.
//      **Version              - String, Undefined - contains a version number of the downloaded add-in.
//      **VersionDate          - Date, Undefined - contains an issue date of the imported add-in version
//                              set when filling in information about
//                              the add-in version.
//       **Description       - String, Undefined - contains description of the add-in, to which
//                              the version belongs.
//      **FileName            - String, Undefined - contains a file name set when
//                             creating an add-in version.
//      **FileID  - String - contains URL, by which you can download
//                             an add-in file.
//      **Checksum    - String - contains MD5 hash encoded to base64 string.
//                             Used to check file integrity.
//      **FileAddress          - String, Undefined - contains an add-in file address
//                              in a temporary storage.
//      **ErrorCode           - String - contains an error code of downloading the add-in.
//
Function RelevantAddInsVersionsInformation(AddInsDetails, AuthenticationData)
	
	IDs = AddInsDetails.UnloadColumn("Id");
	
	TextEventLog = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Начало получения информации об актуальных версиях внешних компонент: %1';
			|en = 'Start getting information on latest add-in versions: %1';"),
		StrConcat(IDs, ","));
	
	WriteInformationToEventLog(
		TextEventLog,
		False);
	
	OperationResult    = ImportResultDetails();
	ConnectionParameters = InitializeUpdateParameters();
	
	URLOperations = AddInsServiceOperationURL(
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
		OperationResult.ErrorMessage = OverrideUserMessage(OperationResult.ErrorCode);
		
		OperationResult.ErrorInfo = StringFunctions.FormattedString(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить актуальные версии внешних компонент.
					|
					|%1
					|
					|Техническая информация об ошибке:
					|При получении информации об актуальных версиях внешних компонент сервис вернул ошибку.
					|URL: %2
					|Код ошибки: %3
					|Подробная информация:
					|%4';
					|en = 'Failed to get latest add-in versions.
					|
					|%1
					|
					|Technical information on the error:
					| When getting information on latest add-in versions, the service returned an error.
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
	
	ProcessServiceResponse(
		SendingResult.Content,
		OperationResult.AddInsData,
		ConnectionParameters.ConnectionSetup.OUSServersDomain);
	
	TextEventLog = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Завершено получение актуальных версий внешних компонент: %1';
			|en = 'Latest add-in versions received: %1';"),
		StrConcat(IDs, ","));
	
	WriteInformationToEventLog(
		TextEventLog,
		False);
	
	Return OperationResult;

EndFunction

// Generates request parameters for the
// /external-components/version/latest operation.
//
Function versionlatest(IDs, AuthenticationData, AdditionalParameters)
	
	// {
	//    "programNick":"nick",
	//    "externalComponentList":[nick1,nick2],
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
	
	MessageDataWriter.WritePropertyName("externalComponentNickList");
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

////////////////////////////////////////////////////////////////////////////////
// Calling the /external-components/version operation.

// Returns a list of details of relevant component versions that are
// currently available to the user.
//
// Parameters:
//  AddInsDetails  - ValueTable - see the GetAddIns.AddInsDetails function.
//
// Returns:
//   Structure - Contains the operation result:
//    *ErrorCode              - String -an error code of add-in service.
//    *ErrorMessage      - String - error details for the user.
//    *ErrorInfo     - String - error details for the administrator.
//    *AddInsData - ValueTable - information on add-ins:
//      **Id       - String - contains an add-in UUID that is
//                              specified by the user when creating an add-in.
//      **Version              - String, Undefined - contains a version number of the downloaded add-in.
//      **VersionDate          - Date, Undefined - contains an issue date of the imported add-in version
//                              set when filling in information about
//                              the add-in version.
//      **Description       - String, Undefined - contains description of the add-in, to which
//                              the version belongs.
//      **FileName            - String, Undefined - contains a file name set when
//                             creating an add-in version.
//      **FileID  - String - contains URL, by which you can download
//                             an add-in file.
//      **Checksum    - String - contains MD5 hash encoded to base64 string.
//                             Used to check file integrity.
//      **FileAddress          - String, Undefined - contains an add-in file address
//                              in a temporary storage.
//      **ErrorCode           - String - contains an error code of downloading the add-in.
//
Function AddInsVersionsInformation(AddInsDetails)
	
	IDs = AddInsDetails.UnloadColumn("Id");
	
	TextEventLog = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Начало получения информации о версиях внешних компонент: %1';
			|en = 'Start getting information on add-in versions: %1';"),
		StrConcat(IDs, ","));
	
	WriteInformationToEventLog(
		TextEventLog,
		False);
	
	OperationResult    = ImportResultDetails();
	ConnectionParameters = InitializeUpdateParameters();
	
	URLOperations = AddInsServiceOperationURL(
		"/version",
		ConnectionParameters.ConnectionSetup.OUSServersDomain);
	
	Result = AuthenticationData();
	If Result.Error Then
		OperationResult.ErrorCode = "InvalidUsernameOrPassword";
		FillPropertyValues(OperationResult, Result, "Error, ErrorInfo");
		OperationResult.ErrorMessage = Result.ErrorInfo;
		Return OperationResult;
	EndIf;
	
	AuthenticationData = Result.AuthenticationData;
	
	JSONQueryParameters = version(
		AddInsDetails,
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
		OperationResult.ErrorMessage = OverrideUserMessage(OperationResult.ErrorCode);
		
		OperationResult.ErrorInfo = StringFunctions.FormattedString(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить информацию о версиях внешних компонент.
					|
					|При получении информации о версиях внешних компонент сервис вернул ошибку.
					|
					|Техническая информация об ошибке:
					|При получении информации о версиях внешних компонент сервис вернул ошибку.
					|URL: %1
					|Код ошибки: %2
					|Подробная информация:
					|%3';
					|en = 'Failed to get information on add-in versions.
					|
					|When getting information on add-in versions, the service returned an error.
					|
					|Technical information on the error:
					|When getting information on add-in versions, the service returned an error.
					|URL: %1
					|Error code: %2
					|Details:
					|%3';"),
				URLOperations,
				SendingResult.ErrorCode,
				SendingResult.ErrorInfo));
		
		WriteInformationToEventLog(
			String(OperationResult.ErrorInfo),
			True);
		
		Return OperationResult;
		
	EndIf;
	
	ProcessServiceResponse(
		SendingResult.Content,
		OperationResult.AddInsData,
		ConnectionParameters.ConnectionSetup.OUSServersDomain);
	
	TextEventLog = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Завершено получение версий внешних компонент: %1';
			|en = 'Add-in versions received: %1';"),
		StrConcat(IDs, ","));
	
	WriteInformationToEventLog(
		TextEventLog,
		False);
	
	Return OperationResult;

EndFunction

// Generates request parameters for the
// /external-components/version operation.
//
Function version(AddInsDetails, AuthenticationData, AdditionalParameters)
	
	// {
	// "programNick":"nick",
	// "externalComponents": {
	// [
	//   {
	//    "externalComponentNick": "nick1",
	//    "version": "1"
	//    }
	//   {
	//   "externalComponentNick": "nick2",
	//   "version": "2"
	//   }
	// ],
	// "authenticationInfo": {
	//   "login": "User",
	//   "password":"Pass"},
	// "additionalParameters" : {
	//   "key":"value"}
	// }
	
	ApplicationName = OnlineUserSupport.InternalApplicationName();
	
	MessageDataWriter = New JSONWriter;
	MessageDataWriter.SetString();
	MessageDataWriter.WriteStartObject();
	
	RecordAuthenticationData(MessageDataWriter, AuthenticationData);
	
	MessageDataWriter.WritePropertyName("programNick");
	MessageDataWriter.WriteValue(ApplicationName);
	
	MessageDataWriter.WritePropertyName("externalComponents");
	MessageDataWriter.WriteStartArray();
	For Each AddInDetails In AddInsDetails Do
		
		MessageDataWriter.WriteStartObject();
		
		MessageDataWriter.WritePropertyName("externalComponentNick");
		MessageDataWriter.WriteValue(AddInDetails.Id);
		
		MessageDataWriter.WritePropertyName("version");
		MessageDataWriter.WriteValue(AddInDetails.Version);
		
		MessageDataWriter.WriteEndObject();
		
	EndDo;
	MessageDataWriter.WriteEndArray();
	
	OnlineUserSupport.WriteAdditionalQueryParameters(
		AdditionalParameters,
		MessageDataWriter);
	
	MessageDataWriter.WriteEndObject();
	
	Return MessageDataWriter.Close();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Process the service response.

// Reading response of the /external-components/version/latest
// and /external-components/version operation.
//
Procedure ProcessServiceResponse(
		JSONBody,
		AddInsData,
		OUSServersDomain = 1)
	
	// Service responses:
	// externalComponentNick - The add-in ID in the service
	// externalComponentName - The add-in's name
	// version - The up-to-date add-in version
	// fileUrl - The URL for downloading the up-to-date add-in version
	// hashSum - File's hashsum
	// buildDate - The version creation date
	// fileSize - The add-in file size
	// errorCode - Error code
	//
	// {
	//   [
	//     {
	//      "externalComponentNick": "ID",
	//      "externalComponentName": "Digital signature",
	//      "version": "1",
	//      "buildData": "2017120212122323",
	//      "fileName": "ElectronicSignature_1_1_2_1.zip",
	//      "fileUrl": "https://fileUrl",
	//      "hashSum": "Hashsum",
	//      "fileSize": "Size in bytes",
	//      "errorCode": "Error code"
	//     }
	//   ]
	// }
	
	TextEventLog = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Получен ответ Сервиса внешних компонент:
			|%1';
			|en = 'Response from the add-in service is received:
			|%1';"),
		JSONBody);
	
	WriteInformationToEventLog(
		TextEventLog,
		False);
	
	ReadResponse = New JSONReader;
	ReadResponse.SetString(JSONBody);
	CurrentLevel = 0;
	ErrorText    = "";
	
	While ReadResponse.Read() Do
		
		If ReadResponse.CurrentValueType = JSONValueType.ArrayStart Then
			CurrentLevel = CurrentLevel + 1;
		ElsIf ReadResponse.CurrentValueType = JSONValueType.ArrayEnd Then
			CurrentLevel = CurrentLevel - 1;
		ElsIf ReadResponse.CurrentValueType = JSONValueType.PropertyName
			And CurrentLevel = 1 Then
			
			If ReadResponse.CurrentValue = "externalComponentName" Then
				VersionSpecifier = AddInsData.Add();
				VersionSpecifier.Description = JSONPropertyValue(ReadResponse, 0);
			ElsIf ReadResponse.CurrentValue = "externalComponentNick" Then
				VersionSpecifier.Id = JSONPropertyValue(ReadResponse, "");
			ElsIf ReadResponse.CurrentValue = "version" Then
				VersionSpecifier.Version = JSONPropertyValue(ReadResponse, 0);
			ElsIf ReadResponse.CurrentValue = "fileUrl" Then
				VersionSpecifier.FileID = JSONPropertyValue(ReadResponse, "");
			ElsIf ReadResponse.CurrentValue = "hashSum" Then
				VersionSpecifier.Checksum = JSONPropertyValue(ReadResponse, "");
			ElsIf ReadResponse.CurrentValue = "buildDate" Then
				VersionSpecifier.VersionDate = CastValueToDate(
					JSONPropertyValue(ReadResponse, ""));
			ElsIf ReadResponse.CurrentValue = "fileSize" Then
				VersionSpecifier.Size = JSONPropertyValue(ReadResponse, 0);
			ElsIf ReadResponse.CurrentValue = "fileName" Then
				VersionSpecifier.FileName = JSONPropertyValue(ReadResponse, 0);
			ElsIf ReadResponse.CurrentValue = "errorCode" Then
				VersionSpecifier.ErrorCode = OverrideAddInErrorCode(JSONPropertyValue(ReadResponse, ""));
				If ValueIsFilled(VersionSpecifier.ErrorCode) Then
					ErrorText = ErrorText + StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = '- при загрузке внешней компоненты %1 сервис вернул ошибку %2;';
							|en = '- when importing the %1 add-in, the service returned error %2;';"),
						VersionSpecifier.Id,
						VersionSpecifier.ErrorCode);
					ErrorText = ErrorText + Chars.LF;
				EndIf;
			EndIf;
		EndIf;
		
	EndDo;
	
	If ValueIsFilled(ErrorText) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибки при получении информации о внешних компонентах:
				|%1';
				|en = 'Errors occurred while getting add-in information:
				|%1';"),
			ErrorText);
		WriteInformationToEventLog(ErrorText);
	EndIf;
	
	// Check the response format.
	ServiceHost = AddInsServiceHost(OUSServersDomain);
	For Each VersionSpecifier In AddInsData Do
		If Not ValueIsFilled(VersionSpecifier.Id) Then
			
			ErrorMessage = NStr("ru = 'Неверный формат ответа Сервиса внешних компонент.';
									|en = 'Invalid format of add-in service response.';");
			WriteInformationToEventLog(ErrorMessage);
			Raise ErrorMessage;
			
		EndIf;
		
		If Not ValueIsFilled(VersionSpecifier.FileID) Then
			Continue;
		EndIf;
		
		URIStructure = CommonClientServer.URIStructure(VersionSpecifier.FileID);
		If Right(Lower(TrimAll(URIStructure.Host)), 6) <> Right(Lower(TrimAll(ServiceHost)), 6) Then
			
			ErrorMessage = NStr("ru = 'Неверный адрес файла обновления внешней компоненты.';
									|en = 'Invalid address of add-in update file.';");
			WriteInformationToEventLog(ErrorMessage);
			Raise ErrorMessage;
			
		EndIf;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Calling file import operation /version/download/.

// Imports files via URLs passed earlier.
//
// Parameters:
//  OperationResult  - Structure - see the GetAddIns.ImportResultDetails() function.
//
Procedure ImportAddInsFiles(OperationResult)
	
	AuthenticationData = AuthenticationData();
	
	Result = AuthenticationData();
	If Result.Error Then
		OperationResult.ErrorCode = "InvalidUsernameOrPassword";
		OperationResult.ErrorInfo = Result.ErrorInfo;
		OperationResult.ErrorMessage  = Result.ErrorInfo;
		Return;
	EndIf;
	
	AuthenticationData = Result.AuthenticationData;
	JSONQueryParameters = versiondownload(AuthenticationData);
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/json");
	
	SendOptions = New Structure;
	SendOptions.Insert("Method",                    "POST");
	SendOptions.Insert("Timeout",                  2560);
	SendOptions.Insert("AnswerFormat",             2);
	SendOptions.Insert("DataFormatToProcess", 1);
	SendOptions.Insert("DataForProcessing",       JSONQueryParameters);
	SendOptions.Insert("Headers",                Headers);
	
	For Each AddInDetails In OperationResult.AddInsData Do
		
		// If the infobase contains the up-to-date add-in, don't import it.
		// 
		If ValueIsFilled(AddInDetails.ErrorCode) Then
			Continue;
		EndIf;
		
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Получение файла внешней компоненты: %1';
					|en = 'Get add-in file: %1';"),
				AddInDetails.FileID),
			False);
		
		OnlineUserSupport.CheckURL(AddInDetails.FileID);
		
		SendingResult = OnlineUserSupport.DownloadContentFromInternet(
			AddInDetails.FileID,
			,
			,
			SendOptions);
		
		If Not IsBlankString(SendingResult.ErrorCode) Then
			
			OperationResult.ErrorCode          = ErrorCodeFileNotImported();
			OperationResult.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при получении файла внешней компоненты %1: 
					|%2';
					|en = 'An error occurred when getting the %1 add-in file:
					|%2';"),
				AddInDetails.Id,
				SendingResult.ErrorMessage);
				
			OperationResult.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить файл внешней компоненты %1.
					|%2
					|
					|Техническая информация об ошибке:
					|При загрузке файла сервис вернул ошибку.
					|Код ошибки: %3.
					|URL Файла: %4
					|Подробная информация:
					|%5';
					|en = 'Cannot get the %1 add in file.
					|%2
					|
					|Technical information on the error:
					|Service returned an error when importing the file.
					|Error code: %3
					|File URL: %4
					|Details:
					|%5';"),
				AddInDetails.Id,
				String(OperationResult.ErrorMessage),
				OperationResult.ErrorCode,
				AddInDetails.FileID,
				SendingResult.ErrorInfo);
			WriteInformationToEventLog(
				OperationResult.ErrorInfo,
				True);
			
			Continue;
			
		EndIf;
		
		ChecksumFile = OnlineUserSupport.FileChecksum(SendingResult.Content);
		If AddInDetails.Checksum <> ChecksumFile Then
			OperationResult.ErrorCode          = ErrorCodeFileNotImported();
			OperationResult.ErrorMessage  = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при получении файла внешней компоненты %1: 
					|%2';
					|en = 'An error occurred when getting the %1 add-in file:
					|%2';"),
				AddInDetails.Id,
				NStr("ru = 'Получен некорректный файл.';
					|en = 'Incorrect file is received.';"));
				
			OperationResult.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить файл внешней компоненты %1.
					|Контрольная сумма полученного файла отличается от ожидаемой.';
					|en = 'Cannot get the %1 add-in file.
					|Received file checksum differs from the expected one.';"),
				AddInDetails.Id);
			WriteInformationToEventLog(OperationResult.ErrorInfo);
			
			Continue;
		EndIf;
		
		AddInDetails.FileAddress = PutToTempStorage(SendingResult.Content);
		
	EndDo;
	
EndProcedure

// Generates request parameters for the
// /version/download/ operation.
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

#Region ProcessAddInsFromFile

// Imports add-in updates and processes file data.
//
// Parameters:
//  FileName - String - The path to an add-in file.
//
Procedure UpdateAddInsFromFile(FileName)
	
	// 1. Check the possibility to get add-ins from the service.
	CheckImportAvailability();
	
	// 2. Generate a list of add-ins pending an update.
	ModuleAddInsServer = Common.CommonModule("AddInsServer");
	InfobaseAddInsVersions = ModuleAddInsServer.ComponentsToUse("ForUpdate");
	If InfobaseAddInsVersions.Count() = 0 Then
		Return;
	EndIf;
	
	// 3. Get the information about the most up-to-date add-in versions from the file.
	OperationResult = AddInsVersionsFromFile(FileName);
	If ValueIsFilled(OperationResult.ErrorCode) Then
		Return;
	EndIf;
	
	// 4. Determine the most up-to-date versions for update.
	AddInsDataForUpdate(InfobaseAddInsVersions, OperationResult);
	
	// 5. Copy the add-in version files.
	PuttingAddInsFilesToStorage(
		FileName,
		OperationResult.AddInsData);
	
	// 6. Prepare the import result.
	DeleteInternalDataOfAddIns(OperationResult.AddInsData);
	
	// 7. Process imported add-ins.
	If Not ValueIsFilled(OperationResult.ErrorCode) Then
		ModuleAddInsServer.UpdateAddIns(OperationResult.AddInsData);
	EndIf;
	
EndProcedure

// Returns the details of add-in versions from the archive.
//
// Parameters:
//  FileName - String - File path.
// 
// Returns:
//  Structure - See ImportResultDetails.
//
Function AddInsVersionsFromFile(FileName) Export
	
	OperationResult = ImportResultDetails();
	
	If CommonClientServer.GetFileNameExtension(FileName) <> "zip" Then
		Return OperationResult;
	EndIf;
	
	ManifestFile = Undefined;
	
	ZipFileReader = New ZipFileReader(FileName);
	For Each ArchiveItem In ZipFileReader.Items Do
		
		If Upper(ArchiveItem.Name) = "EXTERNAL-COMPONENTS.JSON" Then
			ManifestFile = ArchiveItem;
			Break;
		EndIf;
		
	EndDo;
	
	If ManifestFile = Undefined Then
		
		OperationResult.ErrorCode          = "AddInsDetailsFileMissing";
		OperationResult.ErrorMessage  = NStr("ru = 'Отсутствует файл с описанием внешних компонент.';
													|en = 'No file with add-in details.';");
		OperationResult.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить описание внешних компонент из файла по причине:
				|%1';
				|en = 'Cannot get add-in details from the file due to:
				|%1';"),
			OperationResult.ErrorMessage);
		WriteInformationToEventLog(
			OperationResult.ErrorInfo);
		
		ZipFileReader.Close();
		Return OperationResult;
		
	EndIf;
	
	DetailsDirectory = CommonClientServer.AddLastPathSeparator(
		GetTempFileName(ManifestFile.BaseName));
	ZipFileReader.Extract(ManifestFile, DetailsDirectory, ZIPRestoreFilePathsMode.DontRestore);
	DescriptionFileName = DetailsDirectory + ManifestFile.Name;
	
	OperationResult = VersionsInfoForAddInsFromFile(DescriptionFileName);
	DeleteFiles(DetailsDirectory);
	
	ZipFileReader.Close();
	
	Return OperationResult;
	
EndFunction

// Returns the details of add-in versions from a JSON manifest file.
//
// Parameters:
//  FileName - String - File path.
// 
// Returns:
//  Structure - See ImportResultDetails.
//
Function VersionsInfoForAddInsFromFile(FileName)
	
	OperationResult = ImportResultDetails();
	
	Try
		
		JSONReader = New JSONReader;
		JSONReader.OpenFile(FileName);
		VersionsOfExternalComponents = ReadJSON(JSONReader, , "buildDate");
		
		// Filling in a table with updates.
		For Each AddInDetails In VersionsOfExternalComponents Do
			
			VersionSpecifier = OperationResult.AddInsData.Add();
			VersionSpecifier.Id      = AddInDetails.externalComponentNick;
			VersionSpecifier.Description       = AddInDetails.externalComponentName;
			VersionSpecifier.Version             = AddInDetails.version;
			VersionSpecifier.VersionDate         = AddInDetails.buildDate;
			VersionSpecifier.FileName           = AddInDetails.fileName;
			VersionSpecifier.FileID = AddInDetails.fileName;
			
		EndDo;
	
	Except
		
		OperationResult.ErrorCode = "AddInsDetailsFileInvalid";
		OperationResult.ErrorMessage  = NStr("ru = 'Ошибка обработки файла описания внешних компонент.';
													|en = 'An error occurred when processing the add-in details file.';");
		OperationResult.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить описание внешних компонент из файла по причине:
				|%1';
				|en = 'Cannot get add-in details from the file due to:
				|%1';"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		WriteInformationToEventLog(
			OperationResult.ErrorInfo);
		
	EndTry;
	
	JSONReader.Close();
	
	Return OperationResult;
	
EndFunction

// Filters the table keeping only the add-ins that require an update.
//
// Parameters:
//  InfobaseAddInsVersions - ValueTable - Add-ins to be updated.
//                             See GetAddIns.AddInsDetails
//  OperationResult - Structure - Add-ins data stored in the file.
//                             See ImportResultDetails.
//
Procedure AddInsDataForUpdate(InfobaseAddInsVersions, OperationResult)
	
	DeleteRows_ = New Array;
	For Each AddInDetails In OperationResult.AddInsData Do
		
		UpdateRequired = True;
		IsAddInUsed = False;
		For Each InfobaseAddInVersion In InfobaseAddInsVersions Do
			If InfobaseAddInVersion.Id = AddInDetails.Id Then
				IsAddInUsed = True;
				If InfobaseAddInVersion.VersionDate >= AddInDetails.VersionDate Then
					UpdateRequired = False;
				EndIf;
				Break;
			EndIf;
		EndDo;
		
		If Not IsAddInUsed Or Not UpdateRequired Then
			DeleteRows_.Add(AddInDetails);
		EndIf;
		
	EndDo;
	
	For Each AddInDetails In DeleteRows_ Do
		OperationResult.AddInsData.Delete(AddInDetails);
	EndDo;
	
EndProcedure

// Puts add-ins files to a temporary storage.
//
// Parameters:
//  AddInFileName - String - The path to an add-ins file.
//  AddInsData - ValueTable - See ImportResultDetails.
//
Procedure PuttingAddInsFilesToStorage(
		AddInFileName,
		AddInsData)
	
	AddInsDirectory = FileSystem.CreateTemporaryDirectory(
		String(New UUID));
	
	ZipFileReader = New ZipFileReader(AddInFileName);
	For Each AddInDetails In AddInsData Do
		
		ArchiveItem = ZipFileReader.Items.Find(AddInDetails.FileID);
		If ArchiveItem = Undefined Then
			WriteInformationToEventLog(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось найти файл внешней компоненты %1 в архиве %2.';
						|en = 'Cannot find the %1 add-in file in the %2 archive.';"),
					AddInDetails.Id,
					AddInFileName));
			Continue;
		EndIf;
		
		ZipFileReader.Extract(ArchiveItem, AddInsDirectory);
		FileData = New BinaryData(AddInsDirectory + AddInDetails.FileID);
		
		If FileData.Size() = 0 Then
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Файл внешней компоненты %1 (%2) имеет размер равный 0.
					|Загрузка данных остановлена.';
					|en = 'The size of the %1 add-in file (%2) is 0.
					|Data import is stopped.';"),
				AddInDetails.Description,
				AddInDetails.Id);
			WriteInformationToEventLog(
				ExceptionText);
			Raise ExceptionText;
		EndIf;
		
		AddInDetails.Size           = FileData.Size();
		AddInDetails.Checksum = OnlineUserSupport.FileChecksum(FileData);
		AddInDetails.FileAddress       = PutToTempStorage(FileData);
		
	EndDo;
	
	FileSystem.DeleteTempFile(AddInsDirectory);
	
EndProcedure

#EndRegion

#Region OtherServiceProceduresFunctions

// A list of IDs of add-ins used in the configuration.
// The specified add-ins will be imported upon 1C-supplied data processing.
// 
// Returns:
//  Array of String - Add-in IDs.
//
Function ComponentsToUse() Export
	
	ComponentsToUse = New Array;
	
	ModuleAddInsServer = Common.CommonModule("AddInsServer");
	Used1CSuppliedAddIns = ModuleAddInsServer.ComponentsToUse("Supplied1");
	For Each UsedAddIn In Used1CSuppliedAddIns Do
		ComponentsToUse.Add(UsedAddIn);
	EndDo;
	
	OSLSubsystemsIntegration.OnDefineAddInsVersionsToUse(
		ComponentsToUse);
	
	ModuleGetAddInsInSaaS = Common.CommonModule(
		"GetAddInsSaaSOverridable");
	ModuleGetAddInsInSaaS.OnDefineAddInsVersionsToUse(
		ComponentsToUse);
		
	ComponentsToUse = CommonClientServer.CollapseArray(
		ComponentsToUse);
		
	Return ComponentsToUse;
	
EndFunction

// Deletes from the result internal data that was used
// to import add-ins.
//
// Parameters:
//  AddInsData - ValueTable - see the
//                               GetAddIns.ImportResultDetails function.
Procedure DeleteInternalDataOfAddIns(AddInsData)
	
	AddInsData.Columns.Delete("FileID");
	AddInsData.Columns.Delete("Checksum");
	
EndProcedure

// Defines versions that do not require update and
// are defined on the basis of infobase data.
//
// Parameters:
//  AddInsDetails - ValueTable - see the
//                          GetAddIns.AddInsDetails() function.
//  AddInsData - ValueTable - see the
//                          GetAddIns.ImportResultDetails() function.
//
Procedure ProcessLatestVersions(AddInsDetails, AddInsData)
	
	ErrorText = "";
	For Each QueryDetails In AddInsDetails Do
		
		Filter = New Structure;
		Filter.Insert("Id", QueryDetails.Id);
		
		FoundRows = AddInsData.FindRows(Filter);
		For Each VersionSpecifier In FoundRows Do
			If VersionSpecifier.Version = QueryDetails.Version Then
				VersionSpecifier.ErrorCode = "LatestVersion";
				ErrorText = ErrorText + StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = '- при загрузке внешней компоненты %1 сервис вернул ошибку %2;';
							|en = '- when importing the %1 add-in, the service returned error %2;';"),
						VersionSpecifier.Id,
						VersionSpecifier.ErrorCode);
					ErrorText = ErrorText + Chars.LF;
			EndIf;
		EndDo;
	EndDo;
	
	If ValueIsFilled(ErrorText) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибки при получении информации о внешних компонентах:
				|%1';
				|en = 'Errors occurred while getting add-in information:
				|%1';"),
			ErrorText);
		WriteInformationToEventLog(
			ErrorText,
			False);
	EndIf;
	
EndProcedure

// Creates a structure to be used as
// a return value (see functions GetAddIns.RelevantAddInsVersions
// and GetAddIns.AddInsVersions).
//
// Returns:
//   Structure - The result of downloading the add-ins:
//    *ErrorCode              - String - contains an error code of add-in service.
//    *ErrorMessage      - String - contains an add-in service error description.
//                                This message is designed to output error information to a
//                                regular configuration user.
//    *ErrorInfo     - String - contains a full add-in service error description.
//                                The message is designed to be written to the event log. 
//    *AddInsData - ValueTable, Undefined - contains information on downloaded
//                                add-ins:
//     **Id          - String - contains an add-in UUID that is
//                                specified by the user when creating an add-in.
//     **Version                 - String, Undefined - contains a version number of the downloaded add-in.
//     **VersionDate             - Date, Undefined - contains an issue date of the imported add-in version
//                                set when filling in information about
//                                the add-in version.
//     **Description           - String, Undefined - contains description of the add-in, to which
//                                the version belongs.
//     **FileName               - String, Undefined - contains a file name set when
//                                creating an add-in version.
//     **FileID     - String - contains URL, by which you can download
//                                an add-in file.
//     **Size                 - Number - file size;
//     **Checksum       - String - contains MD5 hash encoded to base64 string.
//                                Used to check file integrity.
//     **FileAddress             - String, Undefined - contains an add-in file address
//                                in a temporary storage.
//     **ErrorCode              - String - contains an error code of downloading the add-in;
//
Function ImportResultDetails()
	
	AddInsData = New ValueTable;
	AddInsData.Columns.Add("Id", Common.StringTypeDetails(150));
	AddInsData.Columns.Add("Version",        Common.StringTypeDetails(20));
	AddInsData.Columns.Add("VersionDate",    Common.DateTypeDetails(DateFractions.DateTime));
	AddInsData.Columns.Add("Description",  Common.StringTypeDetails(150));
	AddInsData.Columns.Add("FileName",      Common.StringTypeDetails(260));
	AddInsData.Columns.Add("FileAddress",    Common.StringTypeDetails(250));
	AddInsData.Columns.Add("ErrorCode",     Common.StringTypeDetails(25));
	AddInsData.Columns.Add("Size",        Common.TypeDescriptionNumber(32));
	
	// Internal columns, will be deleted after importing files.
	AddInsData.Columns.Add("FileID", Common.StringTypeDetails(500));
	AddInsData.Columns.Add("Checksum",   Common.StringTypeDetails(64));
	
	ImportResultSpecifier = New Structure;
	ImportResultSpecifier.Insert("ErrorCode",              "");
	ImportResultSpecifier.Insert("ErrorMessage",      "");
	ImportResultSpecifier.Insert("ErrorInfo",     "");
	ImportResultSpecifier.Insert("AddInsData", AddInsData);
	
	Return ImportResultSpecifier;
	
EndFunction

// Creates a structure of settings of connection to the add-in service.
//
Function InitializeUpdateParameters()
	
	ImportParameters = New Structure;
	ImportParameters.Insert("ConnectionSetup"   , OnlineUserSupport.ServersConnectionSettings());
	ImportParameters.Insert("ProxyServerSettings", GetFilesFromInternet.ProxySettingsAtServer());
	
	Return ImportParameters;
	
EndFunction

// Defines a service error type by a status code.
//
// Parameters:
//  StatusCode - Number - Status code of service response.
//
// Returns:
//  String - service error code.
//
Function OverrideServiceErrorCode(StatusCode)
	
	If IsBlankString(StatusCode) Then
		Return "";
	EndIf;
	
	If StatusCode = 200 Then
		Return "";
	ElsIf StatusCode = 403 Then
		Return "NoApplicationAccess";
	ElsIf StatusCode = 401 Then
		Return "InvalidUsernameOrPassword";
	ElsIf StatusCode = 429 Then
		Return "AttemptLimitExceeded";
	ElsIf StatusCode = 500 Then
		Return "ServiceError";
	ElsIf StatusCode = 503 Then
		Return "ServiceTemporarilyUnavailable";
	ElsIf StatusCode = 0 Then
		Return "AttachmentError";
	Else
		Return ErrorCodeUnknownError();
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
	
	If ErrorCode = "NoApplicationAccess" Then
		Return StringFunctions.FormattedString(
			NStr("ru = 'Доступ к обновлениям внешних компонент невозможен, так как ваша программа не находится на <a href = ""https://portal.1c.eu/support/"">официальной поддержке</a>.';
				|en = 'Cannot access add-in updates as your application is not officially supported.';"));
	ElsIf ErrorCode = "InvalidUsernameOrPassword" Then
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
		Return NStr("ru = 'Не удалось подключиться к сервису внешних компонент. Сервис временно недоступен.
			|Повторите попытку подключения позже.';
			|en = 'Cannot connect to add-in service. The service is temporarily unavailable.
			|Please try again later.';");
	ElsIf ErrorCode = "ServiceError" Then
		Return NStr("ru = 'Ошибка работы с сервисом внешних компонент.
			|Подробнее см. в журнале регистрации.';
			|en = 'An error occurred while using add-in service.
			|See the event log for details.';");
	ElsIf ErrorCode = "AttachmentError" Then
		Return NStr("ru = 'Не удалось подключиться к сервису внешних компонент.
			|Подробнее см. в журнале регистрации.';
			|en = 'Cannot connect to add-in service.
			|See the event log for details.';");
	Else
		Return NStr("ru = 'Неизвестная ошибка при подключении к сервису.
			|Подробнее см. в журнале регистрации.';
			|en = 'An unknown error occurred while connecting to the service.
			|See the event log for details.';");
	EndIf;
	
EndFunction

// Defines a subsystem error type by the service error code.
//
// Parameters:
//  ErrorCode - String - Service response error code.
//
// Returns:
//  String - a subsystem error code.
//
Function OverrideAddInErrorCode(ErrorCode)
	
	If Not ValueIsFilled(ErrorCode) Then
		Return "";
	ElsIf Upper(ErrorCode) = Upper("Component_not_found") Then
		Return "ComponentNotFound";
	ElsIf Upper(ErrorCode) = Upper("Component_version_not_found")
		Or Upper(ErrorCode) = Upper("Actual_component_version_not_found") Then
		Return "VersionNotFound";
	Else
		Return ErrorCodeUnknownError();
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
		
		Raise NStr("ru = 'При работе в модели сервиса информация о внешних компонентах
			|загружается из поставляемых данных.';
			|en = 'In SaaS, add-in information is imported
			|from the default master data.';");
		
	Else
		SetPrivilegedMode(True);
		Result.AuthenticationData = OnlineUserSupport.OnlineSupportUserAuthenticationData();
		SetPrivilegedMode(False);
		If Result.AuthenticationData = Undefined Then
			Result.Error                = True;
			Result.ErrorInfo    =
				NStr("ru = 'Для обновления внешних компонент необходимо подключить Интернет-поддержку пользователей.';
					|en = 'To update add-ins, enable online support.';");
			WriteInformationToEventLog(Result.ErrorInfo);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Checks whether add-in version files can be downloaded.
//
Procedure CheckImportAvailability()
	
	If Not LoadingExternalComponentsIsAvailable() Then
		ExceptionText = NStr("ru = 'Получение внешних компонент недоступно при работе в модели сервиса.';
								|en = 'Cannot get add-ins in SaaS.';");
		Raise ExceptionText;
	EndIf;
	
EndProcedure

// Checks the parameters of an add-in query before accessing the service.
//
// Parameters:
//  AddInsDetails - ValueTable - see the AddInsDetails function.
//
// Returns:
//  Structure - see the ImportResultDetails function.
//
Function CheckTheDataFillingOfExternalComponents(AddInsDetails)
	
	ErrorMessage = "";
	OperationResult = ImportResultDetails();
	
	For Each ComponentDetails In AddInsDetails Do
		If Not ValueIsFilled(ComponentDetails.Id) Then
			ErrorMessage = NStr("ru = 'В запросе на загрузку внешних компонент отсутствует идентификаторы компоненты. Заполните идентификатор и повторите загрузку.';
									|en = 'Add-in IDs are missing in the query to import add-ins. Fill in the ID and import again.';");
			Break;
		EndIf;
	EndDo;
	
	If ValueIsFilled(ErrorMessage) Then
		OperationResult.ErrorCode = ErrorCodeUnknownError();
		DeleteInternalDataOfAddIns(OperationResult.AddInsData);
		OperationResult.ErrorMessage  = ErrorMessage;
		OperationResult.ErrorInfo = ErrorMessage;
		Return OperationResult;
	EndIf;
	
	Return OperationResult;
	
EndFunction

// Converts format YYYY-MM-DDThh:mm:ss±hh:mm
// into a date.
//
// Parameters:
//  Value - String - a value to be converted.
//
// Returns:
//  Date - a conversion result.
//
Function CastValueToDate(Val Value)
	
	If Not ValueIsFilled(Value) Then
		Return Date(1, 1, 1);
	EndIf;
	
	// Ignore the time zone (it's also ignored during interactive import).
	// 
	DateValue = Left(Value, StrLen(Value) - 10);
	DateValue = TrimAll(StrReplace(DateValue, ".", ""));
	DateValue = TrimAll(StrReplace(DateValue, "-", ""));
	DateValue = TrimAll(StrReplace(DateValue, ":", ""));
	DateValue = TrimAll(StrReplace(DateValue, "T", ""));
	
	TypeDetails = New TypeDescription("Date");
	
	Return TypeDetails.AdjustValue(DateValue);
	
EndFunction

// Adding authentication data to JSON record.
//
// Parameters:
//  MessageDataWriter  - JSONWriter - Record to
//                         add authentication data to.
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

// Defines a URL to call a service of getting add-ins.
//
// Parameters:
//  Operation  - String - Resource path.
//  Domain     - Number  - Domain ID.
//
// Returns:
//  String - an operation URL.
//
Function AddInsServiceOperationURL(Operation, Domain)
	
	Return "https://"
		+ AddInsServiceHost(Domain)
		+ "/api/external-components"
		+ Operation;
	
EndFunction 

// Defines a host to call a service of getting add-ins.
//
// Parameters:
//  Domain - Number  - Domain ID.
//
// Returns:
//  String - a connection host.
//
Function AddInsServiceHost(Domain)
	
	
	If Domain = 0 Then
		Return "external-components-manager.1c.ru";
	Else
		Return "external-components-manager.1c.eu";
	EndIf;
	
EndFunction

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
		MetadataObject = Undefined)
	
	ELLevel = ?(Error, EventLogLevel.Error, EventLogLevel.Information);
	
	WriteLogEvent(
		EventLogEventName(),
		ELLevel,
		MetadataObject,
		,
		Left(ErrorMessage, 5120));
	
EndProcedure

// Returns an event name for the event log
//
// Returns:
//  String - Event name.
//
Function EventLogEventName()
	
	Return NStr("ru = 'Получение внешних компонент.';
				|en = 'Get add-ins.';", Common.DefaultLanguageCode());
	
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
	If ReadJSONObject.CurrentValueType = JSONValueType.String
		Or ReadJSONObject.CurrentValueType = JSONValueType.Number
		Or ReadJSONObject.CurrentValueType = JSONValueType.Boolean Then
		Return ReadJSONObject.CurrentValue;
	ElsIf ReadJSONObject.CurrentValueType = JSONValueType.Null
		Or ReadJSONObject.CurrentValueType = JSONValueType.None Then
		Return DefaultValue;
	Else
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось прочитать значение свойства %1. Некорректный тип значения свойства (%2).';
				|en = 'Cannot read value of the %1 property. Property value type is incorrect (%2).';"),
			PropertyName,
			String(String(ReadJSONObject.CurrentValueType)));
		Raise ExceptionText;
	EndIf;
	
EndFunction

// Determines data types.
//
// Returns:
//  Array of String - Data type name.
//
Function KindsOf1CSuppliedDataAddIns()
	
	DataKinds = New Array;
	
	ComponentsToUse = ComponentsToUse();
	For Each Id In ComponentsToUse Do
		DataKind = SuppliedDataKindAddIns(Id);
		DataKinds.Add(DataKind);
	EndDo;
	
	Return DataKinds;
	
EndFunction

// Defines the data type and code of the default master data handler.
//
// Parameters:
//  Id - String - Add-in ID in the service.
//
// Returns:
//  String - data kind description.
//
Function SuppliedDataKindAddIns(Id = "")
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		"ExtComponents.%1",
		Id);
	
EndFunction

// Returns the FileNotImported error code.
//
// Returns:
//  String - error code.
//
Function ErrorCodeFileNotImported()
	
	Return "FileNotImported";
	
EndFunction

// Returns the UnknownError error code.
//
// Returns:
//  String - error code.
//
Function ErrorCodeUnknownError()
	
	Return "UnknownError";
	
EndFunction

// Returns the InvalidUsernameOrPassword error code.
//
// Returns:
//  String - error code.
//
Function InvalidUsernameOrPasswordErrorCode()
	
	Return "InvalidUsernameOrPassword";
	
EndFunction

// Converts a source string into a date.
//
// Parameters:
//  Value - String - String to be converted into a date.
//                      Date format must be formatted as DD.MM.YYYY hh:mm:ss.
//
// Returns:
//  Date - a received date.
//
Function StringToDate(Value)
	
	Time = Mid(Value, StrFind(Value, " ", SearchDirection.FromEnd));
	Time = StrReplace(Time, ":", "");
	Time = StrReplace(Time, " ", "");
	Date  = Left(Value,  StrFind(Value, " "));
	Date  = StrReplace(Date, " ", "");
	Date  = Mid(Date, 7) + Mid(Date, 4, 2) + Left(Date, 2);
	
	TypeDetails = New TypeDescription("Date");
	Result    = TypeDetails.AdjustValue(Date + Time);
	
	Return Result;
	
EndFunction

// Returns the number of the disabled update option.
// 
// Returns:
//  Number - An update option value.
//
Function ModeUpdateDisabled()
	Return 0;
EndFunction

// Returns the number of the update option from the service.
// 
// Returns:
//  Number - An update option value.
//
Function ModeUpdateFromService()
	Return 1;
EndFunction

// Returns the number of the update option from the file.
// 
// Returns:
//  Number - An update option value.
//
Function ModeUpdateFromFile()
	Return 2;
EndFunction

// Checks the add-in service for available updates.
//
// Parameters:
//  AddInsDetails - ValueTable - The IDs of add-ins in the service whose updates
//                   should be downloaded.
//  AuthenticationData - Structure, Undefined - Credentials for log in to the add-in service.
//
// Returns:
//  Structure - Information on available updates.:
//    * ErrorCode - String - String code of the occurred error that
//                  can be processed by the calling functionality:
//                    - <Пустая строка> - Updated successfully.
//                    - "НеверныйЛогинИлиПароль" - Invalid username or password.
//                    - "ПревышеноКоличествоПопыток" - The number of login attempts is exceeded.
//                      
//                    - "ОшибкаПодключения" - Service connection error.
//                    - "ОшибкаСервиса" - Internal service error.
//                    - "НеизвестнаяОшибка" - Unknown (unprocessable) error occurred when
//                      obtaining data.
//                    - "СервисВременноНеДоступен" - Server is unavailable due to maintenance.
//                    - "НеизвестнаяВнешняяКомпонентаИлиПрограмма" - No add-in or app is found in the service
//                      by the passed ID.
//                    - "НетДоступаКПрограмме" - App is unavailable on 1C:ITS Portal.
//                    - "ОбновлениеНеТребуется" - The latest versions of add-ins is uploaded.
//    *ErrorMessage  - String, FormattedString - an error message for the user.
//    *ErrorInfo - String, FormattedString - an error message for the administrator.
//    *AvailableVersions - Array - contains information on available updates
//      **ID      - String - An add-in ID in the service.
//      **Version             - String - Relevant version number.
//      **Checksum   - Number - File checksum.
//      **VersionDescription     - String - details of version changes.
//      **FileId - String - File ID that will be used for import.
//      **Size             - String - File size.
//      **Name       - String - An add-in description.
//
Function InternalAddInsAvailableUpdates(
		AddInsDetails,
		AuthenticationData = Undefined) Export
		
	// 1. Check update availability.
	CheckImportAvailability();
	
	CheckResult = New Structure;
	CheckResult.Insert("ErrorCode",          "");
	CheckResult.Insert("ErrorMessage",  "");
	CheckResult.Insert("ErrorInfo", "");
	CheckResult.Insert("AvailableVersions ",   New Array);
	If AuthenticationData = Undefined Then
		Result = AuthenticationData();
		If Result.Error Then
			CheckResult.ErrorCode = InvalidUsernameOrPasswordErrorCode();
			FillPropertyValues(CheckResult, Result, "ErrorInfo");
			CheckResult.ErrorMessage = Result.ErrorInfo;
			Return CheckResult;
		EndIf;
		DataForAuthentication = Result.AuthenticationData;
	Else
		DataForAuthentication = AuthenticationData;
	EndIf;
	
	// 2. Import from the service information on the up-to-date add-in versions and their download links.
	// 
	OperationResult = RelevantAddInsVersionsInformation(
		AddInsDetails,
		DataForAuthentication);
		
	If ValueIsFilled(OperationResult.ErrorCode) Then
		FillPropertyValues(
			CheckResult,
			OperationResult,
			"ErrorCode, ErrorMessage, ErrorInfo");
		Return CheckResult;
	EndIf;
	
	// 3. Determine relevant versions.
	ProcessLatestVersions(AddInsDetails, OperationResult.AddInsData);
	
	For Each VersionSpecifier In OperationResult.AddInsData Do
		
		If ValueIsFilled(VersionSpecifier.ErrorCode)
			And VersionSpecifier.ErrorCode <> "LatestVersion" Then
			Continue;
		EndIf;
		
		FileID = New Structure;
		FileID.Insert("FileID", VersionSpecifier.FileID);
		FileID.Insert("Checksum",   VersionSpecifier.Checksum);
		FileID.Insert("Size",             VersionSpecifier.Size);
		FileID.Insert("VersionDetails",     "");
		
		VersionData = New Structure;
		VersionData.Insert("Id",      VersionSpecifier.Id);
		VersionData.Insert("Description",       VersionSpecifier.Description);
		VersionData.Insert("Version",             VersionSpecifier.Version);
		VersionData.Insert("VersionDetails",     "");
		VersionData.Insert("Size",             VersionSpecifier.Size);
		VersionData.Insert("FileID", FileID);
		VersionData.Insert("VersionDate",         VersionSpecifier.VersionDate);
		CheckResult.AvailableVersions.Add(VersionData);
		
	EndDo;
	
	Return CheckResult;
	
EndFunction

// Imports add-in updates from the service.
Procedure UpdateAddIns()
	
	// 1. Check the possibility to get add-ins from the service.
	CheckImportAvailability();
	
	// 2. Generate a request to import add-ins.
	ModuleAddInsServer = Common.CommonModule("AddInsServer");
	AddInsDetails = ModuleAddInsServer.ComponentsToUse("ForUpdate");
	OperationResult        = CurrentVersionsOfExternalComponents(AddInsDetails);
	
	// 3. Process imported add-ins.
	If Not ValueIsFilled(OperationResult.ErrorCode) Then
		ModuleAddInsServer.UpdateAddIns(OperationResult.AddInsData);
		UpdateAddInsCache(OperationResult.AddInsData);
	EndIf;
	
EndProcedure

// Updates the add-in data cache.
//
// Parameters:
//  AddInsData - ValueTable - See ImportResultDetails.
//
Procedure UpdateAddInsCache(AddInsData)
	
	For Each AddInDetails In AddInsData Do
		
		If ValueIsFilled(AddInDetails.ErrorCode) Then
			Continue;
		EndIf;
		InformationRegisters.AddInsDataCache.UpdateCacheData(AddInDetails);
		
	EndDo;
	
EndProcedure

// Updates the cache with the data obtained from the service using the passed add-in details.
//
// Parameters:
//  AddInsDetails - Structure - See AddInsDetails.
// 
// Returns:
//  Structure - see the ImportResultDetails function.
//
Function UpdateAddInsCacheData(AddInsDetails)
	
	OperationResult = ImportResultDetails();
	
	// 1. Check whether the cache must be updated.
	AddInsDescriptionForUpdate = AddInsDetails();
	For Each AddInDetails In AddInsDetails Do
		Id = AddInDetails.Id;
		CacheDataVersions = InformationRegisters.AddInsDataCache.DataOfCache(Id);
		If CacheDataVersions = Undefined Then
			AddInDescriptionForUpdate = AddInsDescriptionForUpdate.Add();
			FillPropertyValues(
				AddInDescriptionForUpdate,
				AddInDetails)
		EndIf;
	EndDo;
	
	If AddInsDescriptionForUpdate.Count() > 0 Then
		
		// 2. Check data for an add-in request.
		OperationResult = CheckTheDataFillingOfExternalComponents(
			AddInsDescriptionForUpdate);
		If ValueIsFilled(OperationResult.ErrorCode) Then
			Return OperationResult;
		EndIf;
		
		// 3. Get information about the most up-to-date add-in versions in the service.
		// 
		ActivationData = AuthenticationData();
		If ActivationData.Error Then
			OperationResult.ErrorCode = InvalidUsernameOrPasswordErrorCode();
			FillPropertyValues(OperationResult, ActivationData, "ErrorInfo");
			OperationResult.ErrorMessage = ActivationData.ErrorInfo;
			Return OperationResult;
		EndIf;
		OperationResult = RelevantAddInsVersionsInformation(
			AddInsDescriptionForUpdate,
			ActivationData.AuthenticationData);
		
		If ValueIsFilled(OperationResult.ErrorCode) Then
			Return OperationResult;
		EndIf;
		
		// 4. Update the add-in data cache.
		UpdateAddInsCache(
			OperationResult.AddInsData);
		
	EndIf;
	
	Return OperationResult;
	
EndFunction

Function CanModifyScheduledJobSettings()
	Return AccessRight("Update", Metadata.Constants.AddInsUpdateOption);
EndFunction

#EndRegion

#EndRegion
