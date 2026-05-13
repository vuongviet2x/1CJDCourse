///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "Application update" subsystem.
// CommonModule.GetApplicationUpdates.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ApplicationUpdate

// Returns parameters of getting updates determined for the current configuration.
//
// Returns:
//	Structure - Infobase update settings.:
//		* GetConfigurationUpdates - Boolean - True if
//			configuration updates are received for it.
//		* GetPatches - Boolean - True if
//			patches are received for the configuration.
//
Function UpdatesGetParameters() Export
	
	Result = New Structure;
	Result.Insert("GetConfigurationUpdates"              , True);
	Result.Insert("GetPatches"                         , True);
	
	UpdatesGetParameters = InternalUpdatesGetParameters();
	FillPropertyValues(Result, UpdatesGetParameters);
	
	Return Result;
	
EndFunction

// Determines whether it is possible to use automatic application update in the
// current operation mode.
//
// Parameters:
//	CheckUpdatesApplicability - Boolean - check if the current
//		user can apply an update.
//		If True, check whether it can be used in the update
//		application mode. Otherwise, check whether it is possible to view information on
//		available updates.
//	CheckOS - Boolean - check if it is possible to apply the update
//		on the current operating system.
//
// Returns:
//	Boolean - indicates whether update can be used. True if it
//		can be used, otherwise, False.
//
Function CanUseApplicationUpdate(
	CheckUpdatesApplicability = False,
	CheckOS = True) Export
	
	AccessParameters = ParametersOfAccessToAppUpdate();
	Result        = AccessParameters.IsSubsystemAvailable
		And Not AccessParameters.IsWebConnection;
	If CheckUpdatesApplicability Then
		Result = Result And AccessParameters.InstallationIsAvailable;
	EndIf;
	If CheckOS Then
		Result = Result And AccessParameters.IsWindowsClient;
	EndIf;
	
	Return Result;
	
EndFunction

// In a file mode, it returns a directory, to which the last
// received 1C:Enterprise distribution package was saved. Returns Undefined
// in other operation modes.
//
// Returns:
//	String - a directory with 1C:Enterprise platform distribution package in
//		a file operation mode.
//	Undefined - in other operation modes.
//
Function DirectoryToSaveLastReceivedDistributionPackage() Export
	
	If Common.FileInfobase() Then
		
		Return Common.CommonSettingsStorageLoad(
			GetApplicationUpdatesClientServer.CommonSettingsID(),
			SettingKeyDistributionPackageDirectory());
		
	Else
		
		Return Undefined;
		
	EndIf;
	
EndFunction

#EndRegion

#Region Corrections

// Returns a list of available patches for the configuration and integrated libraries.
// The method can be called only by administrators and with the privileged mode set.
// Otherwise, the method returns an error.
// 
//
// Returns:
//  Structure - Information on available patches:
//    * Corrections - Structure - Patch details:
//        ** Set - Array of Structure - Details of available patches:
//             *** Id - String - The patch ID.
//             *** Description - String - The patch name.
//             *** ApplicationName - String - The name of the parent configuration with available updates.
//             *** ApplicationVersion - String - The version of the parent configuration with available updates.
//             *** LongDesc - String - The patch details.
//             *** ChangedMetadataDetails - String - A list of metadata objects that were modified.
//             *** Size - Number - The patch size.
//        ** Delete - Array of String - IDs of revoked patches to be uninstalled.
//             
//    * Error - Boolean - True if an error occurred when getting information on patches.
//    * BriefErrorDetails - String - Brief error details to be shown to the user.
//    * DetailedErrorDetails - String - Elaborate error details to be logged.
//
Function ParentConfigurationsPatches() Export
	
	Result = New Structure;
	Result.Insert("Error"                 , False);
	Result.Insert("BriefErrorDetails"  , "");
	Result.Insert("DetailedErrorDetails", "");
	
	Corrections = New Structure;
	Corrections.Insert("Set", New Array);
	Corrections.Insert("Delete"   , New Array);
	Result.Insert("Corrections", Corrections);
	
	If Not Users.IsFullUser(, True, True) Then
		Result.Error = True;
		Result.BriefErrorDetails   = NStr("ru = 'Недостаточно прав.';
												|en = 'Insufficient rights.';");
		Result.DetailedErrorDetails = NStr("ru = 'Недостаточно прав для получения информации об исправлениях.';
												|en = 'Insufficient rights to receive the patch information.';");
		WriteErrorToEventLog(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить информацию о доступных исправлениях (патчах) родительских конфигураций.
				|%1';
				|en = 'Cannot get information on available patches of the parent configurations.
				|%1';"),
			Result.DetailedErrorDetails));
		Return Result;
	EndIf;
	
	SubsystemsVersions = Common.SubsystemsDetails();
	SubsystemsVersionsParameter = New Array;
	IndexForSearch = New Map;
	For Each Cur_Version In SubsystemsVersions Do
		If ValueIsFilled(Cur_Version.OnlineSupportID) Then
			VersionDetails = New Structure;
			VersionDetails.Insert("ApplicationName", Cur_Version.OnlineSupportID);
			VersionDetails.Insert("Version",       Cur_Version.Version);
			SubsystemsVersionsParameter.Add(VersionDetails);
			IndexForSearch.Insert(Cur_Version.OnlineSupportID + ":" + Cur_Version.Version, True);
		EndIf;
	EndDo;
	
	AdditionalSubsystems = PatchesDownloadSettings().Subsystems;
	For Each CurrAddlSubsystem In AdditionalSubsystems Do
		
		VersionDetails = New Structure();
		VersionDetails.Insert("ApplicationName", CurrAddlSubsystem.OnlineSupportID);
		VersionDetails.Insert("Version"      , CurrAddlSubsystem.Version);
		
		SubsystemsVersionsParameter.Add(VersionDetails);
		IndexForSearch.Insert(CurrAddlSubsystem.OnlineSupportID + ":" + CurrAddlSubsystem.Version,
			True);
		
	EndDo;
	
	If SubsystemsVersionsParameter.Count() > 0 Then
		PatchesInformation = InformationOnAvailableConfigurationsPatches(
			SubsystemsVersionsParameter,
			InstalledPatchesIDs());
	Else
		Return Result;
	EndIf;
	
	If PatchesInformation.Error Then
		FillPropertyValues(
			Result,
			PatchesInformation,
			"Error, BriefErrorDetails, DetailedErrorDetails");
		Return Result;
	EndIf;
	
	For Each CurPatch In PatchesInformation.Corrections Do
		If CurPatch.Revoked1 Then
			Result.Corrections.Delete.Add(String(CurPatch.Id));
		Else
			For Each ApplicabilityString In CurPatch.Applicability Do
				SearchKey = ApplicabilityString.ApplicationName + ":" + ApplicabilityString.ApplicationVersion;
				If IndexForSearch.Get(SearchKey) <> Undefined Then
					NewPatch = NewPatchInformationForApplicationInterface();
					FillPropertyValues(NewPatch, CurPatch);
					NewPatch.ApplicationName    = ApplicabilityString.ApplicationName;
					NewPatch.ApplicationVersion = ApplicabilityString.ApplicationVersion;
					Result.Corrections.Set.Add(NewPatch);
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Imports the selected patches into a temporary storage.
// If an error occurs when importing a file of one of the patches, file import
// is aborted and the imported files are returned
// together with the error details. It is required to repeat the call on the calling side for not imported
// patches.
// The method can be called only under a user with administrative
// rights or if a privileged mode is set, otherwise,
// an error is returned as the execution result.
// This method does not support the SaaS mode.
//
// Parameters:
//	PatchesIDs - Array of String - and IDs of patches being imported.
//	FormIdentifier - UUID - UUID of the
//		form, to whose storage you need to place the imported files.
//
// Returns:
//  Structure - Information on the imported patch files.:
//    * Corrections - Array of Structure - details of patch files that were imported.:
//      ** Id - UUID - Patch UUID.
//      ** FileAddress - String - Received file address in a temporary storage.
//    * Error - Boolean - True if an error occurred
//      when getting information on patches.
//    * BriefErrorDetails - String - brief details of an error, which
//      can be displayed to user,
//    * DetailedErrorDetails - String - details of an error, which
//      can be written to the event log.
//
Function ImportPatches(PatchesIDs, FormIdentifier = Undefined) Export
	
	Return InternalImportPatches(PatchesIDs, FormIdentifier, True);
	
EndFunction

// Defines whether automatic import and patch installation are possible using a scheduled job.
//
// Returns:
//	Boolean - indicates whether update can be used. True if it
//		can be used, otherwise, False.
//
Function AutomaticDownloadOfFixesIsAvailable() Export
	
	ParametersOfUpdate = InternalUpdatesGetParameters();
	Return ParametersOfUpdate.GetPatches;
	
EndFunction

// Defines the setting value of automatic patch import and installation.
// In Saas mode, patches are imported by processing default master data.
// The function will return "True" if patch operations are allowed in the application.
//
// Returns:
//	Boolean - indicates whether automatic import is enabled: True if it
//		is enabled. Otherwise, False.
//
Function AutomaticPatchesImportEnabled() Export
	
	If Not InternalUpdatesGetParameters().GetPatches Then
		Return False;
	EndIf;
	
	// In the SaaS mode, patches are imported using the 1C-supplied data processor.
	// 
	If Common.DataSeparationEnabled() Then
		Return True;
	EndIf;
	
	SetPrivilegedMode(True);
	Return Constants.ImportAndInstallCorrectionsAutomatically.Get();
	
EndFunction

// Changes the setting value of automatic patch import and installation.
// Before calling the method, check whether patch import is available
// See AutomaticDownloadOfFixesIsAvailable.
// If automatic patch import
//
// is not available, an exception will be thrown.
// In SaaS mode, patches are imported by processing default master data.
// Calling the method in SaaS mode is pointless.
//
// Parameters:
//	SettingValue - Boolean - if True, automatic import will be enabled.
//
// Example:
//	If GetApplicationUpdates.AutomaticPatchesImportAvailable() Then
//		GetApplicationUpdates.EnableDisableAutomaticPatchesInstallation(True);
//	EndIf;
//
Procedure EnableDisableAutomaticPatchesInstallation(Val SettingValue) Export
	
	If Not AutomaticDownloadOfFixesIsAvailable() Then
		Raise NStr("ru = 'Автоматическое получение исправлений недоступно в текущем режиме работы.';
								|en = 'Cannot receive patches automatically in the current mode.';");
	EndIf;
	
	// In the SaaS mode, patches are imported using the 1C-supplied data processor.
	// 
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	SettingValue = (SettingValue = True);
	Constants.ImportAndInstallCorrectionsAutomatically.Set(SettingValue);
	ScheduledJobsServer.SetScheduledJobUsage(
		Metadata.ScheduledJobs.GetAndInstallConfigurationTroubleshooting,
		(SettingValue And OnlineUserSupport.AuthenticationDataOfOnlineSupportUserFilled()));
	
EndProcedure

// Returns a list of available patches for the configuration and integrated libraries.
// The method can be called only by administrators and with the privileged mode set.
// Otherwise, the method returns an error.
// This method does not support the SaaS mode.
// 
//
// Returns:
//  Structure:
//    * Corrections - Undefined - Cannot get information on available configuration patches.
//                  - ValueTable - A list of available patches with the columns:
//                      ** Id - String - The patch ID.
//                      ** Description - String - The patch name.
//                      ** LongDesc - String - The patch details.
//                      ** ChangedMetadataDetails - String - A list of metadata objects that were modified.
//                      ** Size - Number - The patch size.
//    * Error - Boolean - True if an error occurred when getting information on patches.
//    * BriefErrorDetails - String - Brief error details to be shown to the user.
//    * DetailedErrorDetails - String - Elaborate error details to be logged.
//
Function InfoAboutAvailablePatches() Export
	
	Result = New Structure;
	Result.Insert("Error"                 , False);
	Result.Insert("BriefErrorDetails"  , "");
	Result.Insert("DetailedErrorDetails", "");
	Result.Insert("Corrections"            , Undefined);
	
	WriteInformationToEventLog(
		NStr("ru = 'Получение информации о доступных исправлениях (патчей) для текущей версии конфигурации.';
			|en = 'Receive information on available patches for the current configuration version.';"));
	
	// In the SaaS mode, patches are imported using the default master data tool.
	If Common.DataSeparationEnabled() Then
		Result.Error                  = True;
		Result.BriefErrorDetails   = NStr("ru = 'Работа с исправлениями в модели сервиса запрещена.';
												|en = 'Patch management in SaaS mode is restricted.';");
		Result.DetailedErrorDetails =
			NStr("ru = 'Работа с исправлениями в модели сервиса выполняется через инструмент поставляемых данных.';
				|en = 'Manage patches in SaaS mode using the default master data tool.';");
		
	// Check 1C:Enterprise
	ElsIf Not AutomaticDownloadOfFixesIsAvailable() Then
		Result.Error                  = True;
		Result.BriefErrorDetails   = NStr("ru = 'Автоматическое получение исправлений недоступно.';
												|en = 'Cannot receive patches automatically.';");
		Result.DetailedErrorDetails =
			NStr("ru = 'Автоматическое получение исправлений недоступно в текущем режиме работы.';
				|en = 'Cannot receive patches automatically in the current mode.';");
		
	// Check for the administrator rights
	ElsIf Not IsSystemAdministrator(True) Then
		Result.Error                  = True;
		Result.BriefErrorDetails   = NStr("ru = 'Недостаточно прав.';
												|en = 'Insufficient rights.';");
		Result.DetailedErrorDetails =
			NStr("ru = 'Недостаточно прав для получения информации об исправлениях.';
				|en = 'Insufficient rights to receive the patch information.';");
	EndIf;
	
	If Result.Error Then
		WriteErrorToEventLog(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить информацию о доступных исправлениях (патчах) для текущей версии конфигурации.
				|%1';
				|en = 'Cannot get information on available patches for the current configuration version.
				|%1';"),
			Result.DetailedErrorDetails));
		Return Result;
	EndIf;
	
	// Get a list of patches available for installation
	PatchesInformation = InformationOnAvailableConfigurationsPatches(
		VersionsOfPatchApps(),
		InstalledPatchesIDs());
	If PatchesInformation.Error Then
		FillPropertyValues(Result, PatchesInformation, , "Corrections");
		WriteErrorToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить информацию о доступных исправлениях (патчах) для текущей версии конфигурации.
					|%1';
					|en = 'Cannot get information on available patches for the current configuration version.
					|%1';"),
				PatchesInformation.DetailedErrorDetails));
		Return Result;
	EndIf;
	
	Corrections = PatchesInformation.Corrections;
	Corrections.Columns.Delete("ApplicationName");
	Corrections.Columns.Delete("ApplicationVersion");
	Corrections.Columns.Delete("ForNewVersion");
	Corrections.Columns.Delete("ForCurrentVersion");
	Corrections.Columns.Delete("Applicability");
	
	Result.Corrections = Corrections;
	
	Return Result;
	
EndFunction

// Imports and installs available patches and uninstalls revoked patches for the configuration and integrated libraries.
// The method can be called only by administrators and with the privileged mode set.
// Otherwise, the method returns an error.
// This method does not support the SaaS mode.
// 
//
// Returns:
//  Structure:
//    * Unspecified - Number - the number of patches that are not installed.
//    * NotDeleted - Number - the number of patches that are not deleted.
//    * Error - Boolean - True if none of the available patches is applied.
//    * BriefErrorDetails - String - Brief error details to be shown to the user.
//        It can be filled in even if "Error" is set to False.
//    * DetailedErrorDetails - String - Elaborate error details to be logged.
//        It can be filled in even if "Error" is set to False.
//
Function DownloadAndInstallFixes() Export
	
	Result = New Structure;
	Result.Insert("Error"                 , False);
	Result.Insert("BriefErrorDetails"  , "");
	Result.Insert("DetailedErrorDetails", "");
	Result.Insert("Unspecified"          , 0);
	Result.Insert("NotDeleted"              , 0);
	
	PatchesInformation = InfoAboutAvailablePatches();
	If PatchesInformation.Error Then
		FillPropertyValues(Result, PatchesInformation);
		Return Result;
	EndIf;
	
	WriteInformationToEventLog(
		NStr("ru = 'Автоматическое получение и установка исправлений (патчей) для текущей версии конфигурации.';
			|en = 'Automatic patch receipt and installation for the current configuration version.';"));
	
	// Check if Online Support is connected
	SetPrivilegedMode(True);
	AuthenticationData = OnlineUserSupport.OnlineSupportUserAuthenticationData();
	SetPrivilegedMode(False);
	If AuthenticationData = Undefined Then
		Result.Error                  = True;
		Result.BriefErrorDetails   = NStr("ru = 'Интернет-поддержка не подключена.';
												|en = 'Online support is disabled.';");
		Result.DetailedErrorDetails = NStr("ru = 'Интернет-поддержка не подключена.';
												|en = 'Online support is disabled.';");
	EndIf;
	
	If Result.Error Then
		WriteErrorToEventLog(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось завершить подготовку автоматического получения и установки исправлений (патчей) для текущей версии конфигурации.
				|%1';
				|en = 'Cannot prepare automatic patch receipt and installation for the current configuration version.
				|%1';"),
			Result.DetailedErrorDetails));
		Return Result;
	EndIf;
	
	Corrections = PatchesInformation.Corrections;
	If Corrections = Undefined Or Corrections.Count() = 0 Then
		WriteInformationToEventLog(NStr("ru = 'Нет доступных исправлений (патчей) для установки';
													|en = 'No available patches to install';"));
		Return Result;
	EndIf;
	
	// Import patches
	PatchesIDs = New Array;
	RevokedPatches     = New Array;
	For Each CurPatch In Corrections Do
		If CurPatch.Revoked1 Then
			RevokedPatches.Add(String(CurPatch.Id));
		Else
			PatchesIDs.Add(String(CurPatch.Id));
		EndIf;
	EndDo;
	
	FilesDetails = InternalImportPatches(PatchesIDs, , False);
	If FilesDetails.Error Then
		FillPropertyValues(Result, FilesDetails);
		WriteErrorToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось автоматически получить и установить исправления (патчи) для текущей версии конфигурации.
					|Не удалось получить информацию о доступных исправлениях.
					|%1';
					|en = 'Cannot download and install patches automatically for the current configuration version.
					|Cannot get information on available patches.
					|%1';"),
				FilesDetails.DetailedErrorDetails));
		Return Result;
	EndIf;
	
	// Installing patches
	
	// Checking which patches are already installed.
	InstalledPatches = ConfigurationUpdate.InstalledPatches();
	InstalledPatchesForCheckIDs = New Map;
	For Each CurPatch In InstalledPatches Do
		InstalledPatchesForCheckIDs.Insert(CurPatch.Id, True);
	EndDo;
	
	PatchesToInstallStrDetails     = New Array;
	InstalledPatchesIDsStrDetails = New Array;
	PatchesFilesParameter = New Array;
	For Each CurPatch In FilesDetails.Corrections Do
		StrID = String(CurPatch.Id);
		If InstalledPatchesForCheckIDs[StrID] = Undefined Then
			PatchesToInstallStrDetails.Add(StrID);
			If Not IsBlankString(CurPatch.FileAddress) Then
				PatchesFilesParameter.Add(CurPatch.FileAddress);
			Else
				PatchesFilesParameter.Add(
					PutToTempStorage(
						New BinaryData(CurPatch.ReceivedFileName)));
			EndIf;
		Else
			InstalledPatchesIDsStrDetails.Add(StrID);
		EndIf;
	EndDo;
	
	// Call the patch installation.
	PatchesDetails = New Structure;
	PatchesDetails.Insert("Set", PatchesFilesParameter);
	PatchesDetails.Insert("Delete"   , RevokedPatches);
	
	If PatchesDetails.Set.Count() = 0
		And PatchesDetails.Delete.Count() = 0 Then
		WriteInformationToEventLog(
			NStr("ru = 'Установка и удаление исправлений не требуются (все исправления были установлены ранее).';
				|en = 'There no patches to install or delete. All patches have been installed earlier.';"));
		Return Result;
	EndIf;
	
	WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Вызов установки и удаления исправлений (БСП).
				|Исправления для установки:
				|%1
				|
				|Исправления для удаления (отозванные):
				|%2
				|
				|Уже установлены (исключены из установки):
				|%3.';
				|en = 'Call patch installation and deletion (SSL).
				|Patches to install:
				|%1
				|
				|Patches to delete (withdrawn):
				|%2
				|
				|Installed patches (excluded from installation):
				|%3.';"),
			StrConcat(PatchesToInstallStrDetails, Chars.LF),
			StrConcat(RevokedPatches, Chars.LF),
			StrConcat(InstalledPatchesIDsStrDetails, Chars.LF)));
	PatchesInstallationParameters = ConfigurationUpdate.PatchesInstallationParameters();
	PatchesInstallationParameters.InBackground = False;
	InstallResult = ConfigurationUpdate.InstallAndDeletePatches(PatchesDetails, PatchesInstallationParameters);
	
	// Process the installation result
	BriefErrorDetails   = New Array;
	DetailedErrorDetails = New Array;
	
	// Gather information on the installation error
	If InstallResult.Unspecified > 0 Then
		
		ErrorsMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось установить исправления (%1 шт.).';
				|en = 'Cannot install patches (%1 pcs.).';"),
			InstallResult.Unspecified);
		
		BriefErrorDetails.Add(ErrorsMessage);
		DetailedErrorDetails.Add(ErrorsMessage);
		
		For Each CurError In InstallResult.Errors Do
			
			If CurError.Event <> "Set" Then
				Continue;
			EndIf;
			
			DetailedErrorDetails.Add(
				"--------------------------------------------------------------------------------");
			DetailedErrorDetails.Add(CurError.PatchNumber);
			DetailedErrorDetails.Add(TrimAll(CurError.Cause));
			
		EndDo;
		DetailedErrorDetails.Add(
			"--------------------------------------------------------------------------------");
		
	EndIf;
	
	// Gather information on the uninstallation error
	If InstallResult.NotDeleted > 0 Then
		
		ErrorsMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось удалить исправления (%1 шт.).';
				|en = 'Cannot delete patches (%1 pcs.).';"),
			InstallResult.NotDeleted);
		
		BriefErrorDetails.Add(ErrorsMessage);
		DetailedErrorDetails.Add(ErrorsMessage);
		
		For Each CurError In InstallResult.Errors Do
			
			If CurError.Event <> "Delete" Then
				Continue;
			EndIf;
			
			DetailedErrorDetails.Add(
				"--------------------------------------------------------------------------------");
			DetailedErrorDetails.Add(CurError.PatchNumber);
			DetailedErrorDetails.Add(TrimAll(CurError.Cause));
			
		EndDo;
		DetailedErrorDetails.Add(
			"--------------------------------------------------------------------------------");
		
	EndIf;
	
	// When no patches were installed or uninstalled, it is considered an error
	Result.Error                  =
		(InstallResult.Unspecified = PatchesDetails.Set.Count()
		And InstallResult.NotDeleted = PatchesDetails.Delete.Count());
	Result.BriefErrorDetails   = StrConcat(BriefErrorDetails, Chars.LF);
	Result.DetailedErrorDetails = StrConcat(DetailedErrorDetails, Chars.LF);
	Result.Unspecified           = InstallResult.Unspecified;
	Result.NotDeleted               = InstallResult.NotDeleted;
	
	WriteInformationToEventLog(
		NStr("ru = 'Завершено автоматическое получение и установка исправлений (патчей) для текущей версии конфигурации.';
			|en = 'Automatic patch receipt and installation for the current configuration version is completed.';"));
	
	Return Result;
	
EndFunction

#EndRegion

#Region IntegrationWithStandardSubsystemsLibrary

// Returns the saved response of the service that gets the information on 1C:Enterprise versions for the current configuration.
//
// Returns:
//  Structure:
//    * MinPlatformVersion - String - A semicolon-delimited list of the minimum supported 1C:Enterprise versions.
//    * RecommendedPlatformVersion - String - A semicolon-delimited list of the recommended supported 1C:Enterprise versions.
//
Function InfoAbout1CEnterpriseVersions() Export
	
	Result = New Structure();
	Result.Insert("MinPlatformVersion"  , "");
	Result.Insert("RecommendedPlatformVersion", "");
	
	// Cannot update secure 1C:Enterprise versions
	If IsSecureSoftwareSystem() Then
		Return Result;
	EndIf;
	
	SetPrivilegedMode(True);
	
	SavedData = Common.CommonSettingsStorageLoad(
		GetApplicationUpdatesClientServer.CommonSettingsID(),
		SettingKey1CEnterpriseVersionsInfo(),
		,
		,
		"");
	
	If TypeOf(SavedData) = Type("Structure") Then
		
		ExtendedSavedData = New Structure();
		ExtendedSavedData.Insert("ApplicationName"                , "");
		ExtendedSavedData.Insert("ApplicationVersion"             , "");
		ExtendedSavedData.Insert("MinPlatformVersion"  , "");
		ExtendedSavedData.Insert("RecommendedPlatformVersion", "");
		
		FillPropertyValues(ExtendedSavedData, SavedData);
		
		// Check data relevancy
		ApplicationName    = OnlineUserSupport.ApplicationName();
		ApplicationVersion = OnlineUserSupport.ConfigurationVersion();
		
		If ExtendedSavedData.ApplicationName = ApplicationName
			And ExtendedSavedData.ApplicationVersion = ApplicationVersion Then
			
			FillPropertyValues(Result, ExtendedSavedData);
			
		Else
			DeletePlatformVersionInformation();
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Deletes the saved response of the service that gets the information on 1C:Enterprise versions for the current configuration.
//
Procedure DeletePlatformVersionInformation() Export
	
	SetPrivilegedMode(True);
	
	Common.CommonSettingsStorageDelete(
		GetApplicationUpdatesClientServer.CommonSettingsID(),
		SettingKey1CEnterpriseVersionsInfo(),
		"");
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// It is called when saving a username and a password of an OUS user to the
// infobase from all library usage contexts.
//
// Parameters:
//  Login - String - Username of an online support user.
//
Procedure OnChangeAuthenticationData(Login) Export
	
	SetPrivilegedMode(True);
	ScheduledJobsServer.SetScheduledJobUsage(
		Metadata.ScheduledJobs.GetAndInstallConfigurationTroubleshooting,
		(ValueIsFilled(Login) And AutomaticPatchesImportEnabled()));
	
EndProcedure

// Adds the required client parameters upon startup.
// Added parameters are available in
// StandardSubsystemsClient.ClientRunParametersOnStart().OnlineUserSupport.<ParameterName>;
// It is used if the subsystem implements the scenario executed
// upon the system startup.
// See OSLSubsystemsIntegration.OnAddClientParametersOnStart
//
// Parameters:
//	Parameters - Structure - parameters being filled in.
//
Procedure ClientParametersOnStart(Parameters) Export
	
	SettingsOfUpdate = Undefined;	// See AutoupdateSettings
	
	Parameters.Insert("GetApplicationUpdates"                                 , SettingsOfUpdate);
	Parameters.Insert("NotifyThatAutoImportOfPatchesEnabled", False);
	Parameters.Insert("CheckForUpdate"                                    , Undefined);
	
	If Not CanUseApplicationUpdate() Then
		Return;
	EndIf;
	
	Parameters.GetApplicationUpdates = AutoupdateSettings();
	
	CheckForUpdatesOnStartup(Parameters);
	
	PatchesDownloadSettings = PatchesDownloadSettings();
	If Not PatchesDownloadSettings.DisableNotifications
		And Not Common.SubsystemExists("StandardSubsystems.ToDoList")
		And AutomaticDownloadOfFixesIsAvailable()
		And Not AutomaticPatchesImportEnabled() Then
		
		DateOfInforming = Common.CommonSettingsStorageLoad(
			GetApplicationUpdatesClientServer.CommonSettingsID(),
			GetApplicationUpdatesClientServer.SettingKeyPatchDownloadEnablementNotificationDate(),
			'00010101');
		If DateOfInforming <= CurrentSessionDate() Then
			Parameters.NotifyThatAutoImportOfPatchesEnabled = True;
		EndIf;
		
	EndIf;
	
EndProcedure

// Integration with the StandardSubsystems.Core subsystem.
//
// Parameters:
//  PermissionsRequests - See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources.PermissionsRequests
//
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	If Not Common.DataSeparationEnabled() Then
		
		NewPermissions = New Array;
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		
		Resolution = ModuleSafeModeManager.PermissionToUseInternetResource(
			"HTTP",
			"downloads.v8.1c.ru",
			80,
			NStr("ru = 'Получение файлов обновлений программы (зона ru)';
				|en = 'Receive application update files (ru zone)';"));
		NewPermissions.Add(Resolution);
		
		Resolution = ModuleSafeModeManager.PermissionToUseInternetResource(
			"HTTP",
			"downloads.v8.1c.eu",
			80,
			NStr("ru = 'Получение файлов обновлений программы (зона eu)';
				|en = 'Receive application update files (eu zone)';"));
		NewPermissions.Add(Resolution);
		
		Resolution = ModuleSafeModeManager.PermissionToUseInternetResource(
			"HTTPS",
			"update-api.1c.ru",
			443,
			NStr("ru = 'Сервис получения обновлений программы (зона ru)';
				|en = 'Service to receive application update files (ru zone)';"));
		NewPermissions.Add(Resolution);
		
		Resolution = ModuleSafeModeManager.PermissionToUseInternetResource(
			"HTTPS",
			"update-api.1c.eu",
			443,
			NStr("ru = 'Сервис получения обновлений программы (зона eu)';
				|en = 'Service to receive application update files (eu zone)';"));
		NewPermissions.Add(Resolution);
		
		PermissionsRequests.Add(ModuleSafeModeManager.RequestToUseExternalResources(NewPermissions));
		
	EndIf;
	
EndProcedure

// Fills in a list of infobase update handlers.
//
// Parameters:
//  Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	Handler = Handlers.Add();
	Handler.Version    = "2.1.8.1";
	Handler.Procedure =
		"GetApplicationUpdates.InfobaseUpdateUpdateUpdateDownloadSettings2181";
	Handler.SharedData         = False;
	Handler.InitialFilling = False;
	Handler.ExecutionMode     = "Seamless";
	
	If Not DataSeparationEnabled Then
		
		Handler = Handlers.Add();
		Handler.Version              = "2.4.2.59";
		Handler.Procedure           = "GetApplicationUpdates.UpdateThePatchDownloadSchedule";
		Handler.SharedData         = False;
		Handler.InitialFilling = False;
		Handler.ExecutionMode     = "Deferred";
		Handler.Id       = New UUID("d7d83d59-29bb-43ce-838c-339151202fde");
		Handler.Comment         = NStr("ru = 'Обновление расписания загрузки исправлений (патчей).';
												|en = 'Update the patch import schedule.';");
		
		Handler = Handlers.Add();
		Handler.Version              = "";
		Handler.Procedure           = "GetApplicationUpdates.UpdateThePatchDownloadSchedule";
		Handler.SharedData         = False;
		Handler.InitialFilling = True;
		Handler.ExecutionMode     = "Deferred";
		Handler.Id       = New UUID("a7503eb2-d55f-4f03-883b-1ffafdd7cba5");
		Handler.Comment         =
			NStr("ru = 'Начальное заполнение. Обновление расписания загрузки исправлений (патчей).';
				|en = 'Initial population. Update the patch import schedule.';");
		
		Handler = Handlers.Add();
		Handler.Version              = "2.7.1.36";
		Handler.Procedure           =
			"GetApplicationUpdates.UpdateScheduleOn1CEnterpriseVersionsInfoUpdate";
		Handler.SharedData         = False;
		Handler.InitialFilling = False;
		Handler.ExecutionMode     = "Deferred";
		Handler.Id       = New UUID("aa92254f-635d-446d-a779-8637e2700474");
		Handler.Comment         =
			NStr("ru = 'Обновление расписания регламентной операции по обновлению информации о версиях платформы.';
				|en = 'Update the schedule of the scheduled job to update the platform version information.';");
		
		Handler = Handlers.Add();
		Handler.Version              = "";
		Handler.Procedure           =
			"GetApplicationUpdates.UpdateScheduleOn1CEnterpriseVersionsInfoUpdate";
		Handler.SharedData         = False;
		Handler.InitialFilling = True;
		Handler.ExecutionMode     = "Deferred";
		Handler.Id       = New UUID("f06d3442-9f10-4a6d-979d-0324b1ce5949");
		Handler.Comment         =
			NStr("ru = 'Начальное заполнение. Обновление расписания регламентной операции по обновлению информации о версиях платформы.';
				|en = 'Initial population. Update the schedule of the scheduled job to update the platform version information.';");
		
	EndIf;
	
	If Not DataSeparationEnabled
		And StandardSubsystemsServer.IsBaseConfigurationVersion()
		And AutomaticDownloadOfFixesIsAvailable()
		And Not AutomaticPatchesImportEnabled() Then
		
		Handler = Handlers.Add();
		Handler.Version              = "2.5.1.51";
		Handler.Procedure           = "GetApplicationUpdates.EnableAutomaticDownloadOfFixes";
		Handler.SharedData         = False;
		Handler.InitialFilling = False;
		Handler.ExecutionMode     = "Deferred";
		Handler.Id       = New UUID("15411940-c2c6-4299-a80e-f7deaec31f36");
		Handler.Comment         = NStr("ru = 'Установка настройки автоматической загрузки исправлений (патчей).';
												|en = 'Set up automatic patch import.';");
		
		Handler = Handlers.Add();
		Handler.Version              = "";
		Handler.Procedure           = "GetApplicationUpdates.EnableAutomaticDownloadOfFixes";
		Handler.SharedData         = False;
		Handler.InitialFilling = True;
		Handler.ExecutionMode     = "Deferred";
		Handler.Id       = New UUID("da082492-99e3-4dbd-870e-bc12fb62f1ad");
		Handler.Comment         =
			NStr("ru = 'Начальное заполнение. Установка настройки автоматической загрузки исправлений (патчей).';
				|en = 'Initial population. Set up automatic patch import.';");
		
	EndIf;
	
EndProcedure

// Returns the IDs of the installed configuration patches.
//
// Returns:
//  Array of String
//
Function InstalledPatchesIDs() Export
	
	// The list of the patch IDs in the configuration is not private.
	// Any of the infobase users can access it.
	// 
	SetPrivilegedMode(True);
	
	Result = New Array;
	InstalledPatches = ConfigurationUpdate.InstalledPatches();
	For Each CurPatch In InstalledPatches Do
		If ValueIsFilled(CurPatch.Id) Then
			Result.Add(String(CurPatch.Id));
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns information about available update in a working update scenario.
//
// Returns:
//  See AvailableUpdateInformationInternal
//
Function AvailableUpdateInformation() Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ConnectionSetup",
		OnlineUserSupport.ServersConnectionSettings());
	Return AvailableUpdateInformationInternal(
		OnlineUserSupport.InternalApplicationName(),
		OnlineUserSupport.ConfigurationVersion(),
		"",
		"",
		"ApplicationUpdate1",
		AdditionalParameters);
	
EndFunction

// Returns the download and installation settings for the overridable method.
//
// Returns:
//  Structure - Additional settings for patch download:
//    * DisableNotifications - Boolean - If True, the task on enabling auto-download of patches will be disabled in the ToDoList subsystem
//        and the user will not be notified if the ToDoList subsystem is not integrated in the configuration on startup.
//        By default, False.
//        
//    * Subsystems - Array of Structure - A list of apps whose patches should be downloaded and installed:
//        ** SubsystemName - String - The subsystem name. For example, "StandardSubsystems".
//        ** OnlineSupportID - String - The app name in Online Support services.
//        ** Version - String - A 4-digit version number. For example, "2.1.3.1".
//
Function PatchesDownloadSettings() Export
	
	Settings = New Structure();
	Settings.Insert("DisableNotifications", False);
	Settings.Insert("Subsystems"          , New Array());
	
	GetApplicationUpdatesOverridable.OnDefinePatchesDownloadSettings(Settings);
	
	Return Settings;
	
EndFunction

// Returns the permissions of the "Application update" subsystem add-ins.
//
// Returns:
//  Structure:
//    * GetConfigurationUpdates - Boolean - If True, downloading and installing updates is allowed.
//    * GetPatches - Boolean - If True, downloading and installing patches is allowed.
//    * SelectDirectoryToSavePlatformDistributionPackage - Boolean - If True, the user can select the target directory
//        to download the distribution package to.
//    * ShouldNotifyAboutLongTermSupportVersionRelease - Boolean - If True, the app notifies about new builds (when support is active)
//        and new versions (when support is discontinued) for the current app version.
//        
//
Function InternalUpdatesGetParameters() Export
	
	Result = New Structure;
	Result.Insert("GetConfigurationUpdates"                , True);
	Result.Insert("GetPatches"                           , True);
	Result.Insert("SelectDirectoryToSavePlatformDistributionPackage", True);
	
	OSLSubsystemsIntegration.OnDefineUpdatesGetParameters(
		Result);
	GetApplicationUpdatesOverridable.OnDefineUpdatesGetParameters(
		Result);
	
	SettingsOfUpdate = AutoupdateSettings();
	Result.Insert("ShouldNotifyAboutLongTermSupportVersionRelease",
		SettingsOfUpdate.UpdateReleaseNotificationOption = 1);
	
	Return Result;
	
EndFunction

#Region OnlineUserSupportSubsystemsIntegration

// Populates the details of the hosts used in Online Support services.
//
// Parameters:
//  OnlineSupportServicesHosts - Map of KeyAndValue - The name and host of a service.:
//    * Key - String - The service host.
//    * Value - String - Service details.
//
Procedure OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts) Export
	
	If Not Common.DataSeparationEnabled() Then
		
		OnlineSupportServicesHosts.Insert(
			"downloads.v8.1c.ru",
			NStr("ru = 'Получение файлов обновлений программы';
				|en = 'Receive application update files';"));
		OnlineSupportServicesHosts.Insert(
			"downloads.v8.1c.eu",
			NStr("ru = 'Получение файлов обновлений программы';
				|en = 'Receive application update files';"));
		OnlineSupportServicesHosts.Insert(
			UpdatesServiceHost(0),
			NStr("ru = 'Получение обновлений программы';
				|en = 'Receive application updates';"));
		OnlineSupportServicesHosts.Insert(
			UpdatesServiceHost(1),
			NStr("ru = 'Получение обновлений программы';
				|en = 'Receive application updates';"));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ApplicationSettings

// Called from the OnCreateAtServer() handler of the OSL administrator panel.
// Sets up the visibility of the subsystem management controls.
//
// Parameters:
//  Form - See DataProcessor.OSLAdministrationPanel.Form.InternetSupportAndServices
//
Procedure InternetSupportAndServicesOnCreateAtServer(Form) Export
	
	Items = Form.Items;
	
	Items.GroupAppUpdate.Visible = True;
	
	UpdatesGetParameters = InternalUpdatesGetParameters();
	
	AccessParameters = ParametersOfAccessToAppUpdate();
	InformationOnUpdatesAvailable = AccessParameters.IsSubsystemAvailable
		And Not AccessParameters.IsWebConnection;
	CanUseUpdates = AccessParameters.IsSubsystemAvailable
		And AccessParameters.InstallationIsAvailable
		And AccessParameters.IsWindowsClient
		And Not AccessParameters.IsWebConnection;
	
	Items.ApplicationUpdate.Visible                  = InformationOnUpdatesAvailable;
	Items.ApplicationUpdateGroup_Settings.Visible  = AccessParameters.IsSubsystemAvailable;
	Items.ApplicationUpdatePatchesGroup.Visible =
		UpdatesGetParameters.GetPatches
		And AccessParameters.IsSubsystemAvailable
		And AccessParameters.InstallationIsAvailable;
	Items.GroupAppUpdate_AutoCheckUpdates2.Visible =
		AccessParameters.IsSubsystemAvailable;
	Items.GroupAppUpdate_UpdateReleaseNotificationOption.Visible =
		UpdatesGetParameters.GetConfigurationUpdates;
	
	SettingsOfUpdate = AutoupdateSettings();
	
	If AccessParameters.IsSubsystemAvailable Then
		Form.AutomaticUpdatesCheck =
			SettingsOfUpdate.AutomaticCheckForProgramUpdates;
		Items.UpdatesCheckScheduleDecoration.Enabled =
			(Form.AutomaticUpdatesCheck = 2);
		Items.UpdatesCheckScheduleDecoration.Title =
			OnlineUserSupportClientServer.SchedulePresentation(SettingsOfUpdate.Schedule);
	EndIf;
	
	Form.UpdateReleaseNotificationOption = SettingsOfUpdate.UpdateReleaseNotificationOption;
	
	If Items.ApplicationUpdatePatchesGroup.Visible Then
		Form.ImportAndInstallCorrectionsAutomatically =
			Constants.ImportAndInstallCorrectionsAutomatically.Get();
		Job = ScheduledJobsServer.GetScheduledJob(
			Metadata.ScheduledJobs.GetAndInstallConfigurationTroubleshooting);
		If Job <> Undefined Then
			Items.PatchesInstallationScheduleDecoration.Title =
				OnlineUserSupportClientServer.SchedulePresentation(Job.Schedule);
		EndIf;
		Items.PatchesInstallationScheduleDecoration.Enabled =
			Form.ImportAndInstallCorrectionsAutomatically;
	EndIf;
	
	If Not IsFileIB() Or Not CanUseUpdates Then
		Items.PlatformDistributionPackageDirectory.Visible = False;
	Else
		Form.PlatformDistributionPackageDirectory = DirectoryToSaveLastReceivedDistributionPackage();
		Items.PlatformDistributionPackageDirectory.Visible =
			GetApplicationUpdatesClientServer.FileExists(Form.PlatformDistributionPackageDirectory, True);
	EndIf;
	
	Items.ItemizeIBUpdateInEventLogGroup.Visible =
		Form.IsSystemAdministrator
		And (Not Form.DataSeparationEnabled
		Or Not Form.SeparatedDataUsageAvailable);
	
EndProcedure

#EndRegion

#Region PersonalUserSettings

// Returns custom auto-update settings.
//
// Returns:
//  See NewAutoupdateSettings
//
Function AutoupdateSettings() Export
	
	Result           = NewAutoupdateSettings();
	OutdatedParameters = New Structure("AutoCheckMethod");
	Settings           = Common.CommonSettingsStorageLoad(
		GetApplicationUpdatesClientServer.CommonSettingsID(),
		AutoUpdateSettingKey());
	If TypeOf(Settings) = Type("Structure") Then
		FillPropertyValues(Result, Settings);
		FillPropertyValues(OutdatedParameters, Settings);
		If OutdatedParameters.AutoCheckMethod <> Undefined Then
			Result.AutomaticCheckForProgramUpdates =
				OutdatedParameters.AutoCheckMethod;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Writes custom auto-update settings.
//
// Parameters:
//  Settings - See NewAutoupdateSettings
//
Procedure WriteAutoupdateSettings(Settings) Export
	
	Common.CommonSettingsStorageSave(
		GetApplicationUpdatesClientServer.CommonSettingsID(),
		AutoUpdateSettingKey(),
		Settings);
	
EndProcedure

#EndRegion

#Region SSLToDoList

// Integration with the StandardSubsystems.ToDoList subsystem.
// Fills a user's to-do list.
//
// Parameters:
//  ToDoList - ValueTable - a value table with the following columns:
//    * Id - String - an internal to-do ID used by the To-do list algorithm.
//    * HasToDoItems      - Boolean - if True, the to-do item is displayed in the user's to-do list.
//    * Important        - Boolean - if True, the to-do item is highlighted in red.
//    * Presentation - String - To-do item presentation displayed to a user.
//    * Count    - Number  - a number related to a to-do item; it is displayed in a to-do item's title.
//    * Form         - String - Full path to the form that is displayed by clicking on the
//                               to-do item hyperlink in the "To-do list" panel.
//    * FormParameters - Structure - parameters for opening the indicator form.
//    * Owner      - String, MetadataObject - String ID of the to-do item that is the owner of the current to-do item,
//                      or a subsystem metadata object.
//    * ToolTip     - String - Tooltip text.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ToDoList") Then
		Return;
	EndIf;
	
	PopulateToDoListAppUpdate(ToDoList);
	PopulateToDoListForPatchAutoDownload(ToDoList);
	
EndProcedure

#EndRegion

#Region SaaSSSL

// See SuppliedDataOverridable.GetHandlersForSuppliedData
//
Procedure OnDefineSuppliedDataHandlers(Handlers) Export
	
	StrHandler = Handlers.Add();
	StrHandler.DataKind      = SuppliedPatchDataKind();
	StrHandler.HandlerCode = SuppliedPatchDataKind();
	StrHandler.Handler     = Common.CommonModule("GetApplicationUpdates");
	
EndProcedure

// The procedure is called when a new data notification is received.
// In the procedure body, check whether the application requires this data.
//  If it requires, select the Import check box.
// 
// Parameters:
//   Descriptor - XDTODataObject
//   ToImport - Boolean - Indicates whether to import new data. A return value.
//
Procedure NewDataAvailable(Val Descriptor, ToImport) Export
	
	If Descriptor.DataType <> SuppliedPatchDataKind() Then
		Return;
	EndIf;
	
	SettingsOfUpdate = InternalUpdatesGetParameters();
	If Not SettingsOfUpdate.GetPatches Then
		WriteInformationToEventLog(
			NStr("ru = 'Установка исправлений (патчей) запрещена в настройках конфигурации.';
				|en = 'Patch installation is prohibited in configuration settings.';"));
		ToImport = False;
		Return;
	EndIf;
	
	DeletePatch       = False;
	Id            = "";
	AdditionalSubsystems = PatchesDownloadSettings().Subsystems;
	
	For Each Characteristic In Descriptor.Properties.Property Do
		If Characteristic.Code = "ApplicationVersionsData" Then
			AvailableVersions = Common.ValueFromXMLString(
				Characteristic.Value);
			For Each VersionDetails In AvailableVersions Do
				If VersionDetails.ConfigurationName = OnlineUserSupport.ConfigurationName()
					And VersionDetails.ConfigurationVersion = OnlineUserSupport.ConfigurationVersion() Then
					ToImport = True;
					Break;
				Else
					For Each CurrSubsystem In AdditionalSubsystems Do
						If VersionDetails.ConfigurationName = CurrSubsystem.SubsystemName
							And VersionDetails.ConfigurationVersion = CurrSubsystem.Version Then
							ToImport = True;
							Break;
						EndIf;
					EndDo;
					If ToImport Then
						Break
					EndIf;
				EndIf;
			EndDo;
		ElsIf Characteristic.Code = "ExitStatus" Then
			If Characteristic.Value = "revocation" Then
				DeletePatch = True;
			EndIf;
		ElsIf Characteristic.Code = "Id" Then
			Id = Characteristic.Value;
		EndIf;
	EndDo;
	
	If DeletePatch Then
		
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Отзыв исправления: %1';
					|en = 'Withdrawal of patch: %1';"),
				Id));
			
		// Delete withdrawn patches.
		PatchesToDelete = New Array;
		PatchesToDelete.Add(Id);
		
		Corrections = New Structure;
		Corrections.Insert("Set", New Array);
		Corrections.Insert("Delete",    PatchesToDelete);
		
		ConfigurationUpdate.InstallAndDeletePatches(Corrections);
		ToImport = False;
		
	Else
		
		// Checking patches installed earlier.
		InstalledPatches = ConfigurationUpdate.InstalledPatches();
		For Each PatchSpecifier In InstalledPatches Do
			If String(PatchSpecifier.Id) = Id Then
				ToImport = False;
				Return;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

// The procedure is called after calling NewDataAvailable, it parses the data.
//
// Parameters:
//   Descriptor - XDTODataObject
//   PathToFile - String - The full name of the extracted file. The file is deleted when the procedure completes.
//
Procedure ProcessNewData(Val Descriptor, Val PathToFile) Export
	
	If Descriptor.DataType <> SuppliedPatchDataKind() Then
		Return;
	EndIf;
	
	SettingsOfUpdate = InternalUpdatesGetParameters();
	If Not SettingsOfUpdate.GetPatches Then
		WriteInformationToEventLog(
			NStr("ru = 'Установка исправлений (патчей) запрещена в настройках конфигурации.';
				|en = 'Patch installation is prohibited in configuration settings.';"));
		Return;
	EndIf;
	
	AdditionalSubsystems = PatchesDownloadSettings().Subsystems;
	
	// Re-check is required as the configuration version number might
	// change after importing 1C-supplied data.
	Set = False;
	For Each Characteristic In Descriptor.Properties.Property Do
		If Characteristic.Code = "ApplicationVersionsData" Then
			AvailableVersions = Common.ValueFromXMLString(
				Characteristic.Value);
			For Each VersionDetails In AvailableVersions Do
				If VersionDetails.ConfigurationName = OnlineUserSupport.ConfigurationName()
					And VersionDetails.ConfigurationVersion = OnlineUserSupport.ConfigurationVersion() Then
					Set = True;
					Break;
				Else
					For Each CurrSubsystem In AdditionalSubsystems Do
						If VersionDetails.ConfigurationName = CurrSubsystem.SubsystemName
							And VersionDetails.ConfigurationVersion = CurrSubsystem.Version Then
							Set = True;
							Break;
						EndIf;
					EndDo;
					If Set Then
						Break
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	ModuleSuppliedData = Common.CommonModule("SuppliedData");
	
	If Not Set Then
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Установка нового исправления не возможна, т.к.
						|в дескрипторе поставляемых данных отсутствует номер
						|версии конфигурации:
						|%1';
						|en = 'Cannot install the new patch because
						|the configuration
						|%1number
						|is missing in the default master data descriptor';"),
				ModuleSuppliedData.GetDataDescription(Descriptor)));
		Return;
	EndIf;
	
	WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Установка нового исправления:
				|%1';
				|en = 'Installation of the new patch:
				|%1';"),
			ModuleSuppliedData.GetDataDescription(Descriptor)));
	
	PatchData = New BinaryData(PathToFile);
	PatchesToInstall1 = New Array;
	PatchesToInstall1.Add(PutToTempStorage(PatchData));
	
	Corrections = New Structure;
	Corrections.Insert("Set", PatchesToInstall1);
	Corrections.Insert("Delete",    New Array);
	
	ConfigurationUpdate.InstallAndDeletePatches(Corrections);
	
EndProcedure

// Runs if data processing is failed due to an error.
//
// Parameters:
//  Descriptor - XDTODataObject
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

#EndRegion

#Region Private

// Returns the subsystem update availability, user installation rights, client operating system,
// and the client/infobase connection method.
//
// Returns:
//  Structure:
//    * IsSubsystemAvailable - Boolean - True if the subsystem can be operated regardless of the operating system
//          and the connection method.
//    * InstallationIsAvailable - Boolean - True if the user is administrator.
//    * IsWindowsClient - Boolean - True if the operating system is Windows.
//    * IsWebConnection - Boolean - True if the client is "web" of "thin" connected via a web server.
//
Function ParametersOfAccessToAppUpdate()
	
	IsSubsystemAvailable = Not (Common.DataSeparationEnabled()
		Or Not Users.RolesAvailable("ViewAvailableApplucationUpdatesInformation", , False)
		Or Users.IsExternalUserSession()
		Or Common.IsSubordinateDIBNode()
		Or Common.IsStandaloneWorkplace());
	IsWebConnection = Common.IsWebClient()
		Or Common.ClientConnectedOverWebServer();
	
	Result = New Structure();
	Result.Insert("IsSubsystemAvailable", IsSubsystemAvailable);
	Result.Insert("InstallationIsAvailable" , IsSystemAdministrator());
	Result.Insert("IsWindowsClient"  , Common.IsWindowsClient());
	Result.Insert("IsWebConnection" , IsWebConnection);
	
	Return Result;
	
EndFunction

Function IsFileIB() Export
	
	Return Common.FileInfobase();
	
EndFunction

Function IsSystemAdministrator(ForPrivilegedMode = False) Export
	
	Return Users.IsFullUser(, True, ForPrivilegedMode);
	
EndFunction

Function IsBaseConfigurationVersion() Export
	
	Return StandardSubsystemsServer.IsBaseConfigurationVersion();
	
EndFunction

// Checks the used app variant and returns True if this is a secure 1C:Enterprise version.
// 
//
// Returns:
//  Boolean
//
Function IsSecureSoftwareSystem()
	
	SystemProperties = New Structure();
	SystemProperties.Insert("AppVariant", "");
	
	// The "AppVariant" property of the "SystemInformation" object is implemented in 1C:Enterprise v.8.3.22 or later.
	SystemInfo = New SystemInfo();
	FillPropertyValues(SystemProperties, SystemInfo);
	
	Return Not IsBlankString(SystemProperties.AppVariant);
	
EndFunction

Function InternalCanUsePlatformUpdatesReceipt(
	CheckAutomaticInstallationAvailability = False) Export
	
	If Common.IsWebClient()
		Or Common.DataSeparationEnabled()
		Or Not Users.IsFullUser(, True)
		Or CheckAutomaticInstallationAvailability And Not IsFileIB()
		Or Users.IsExternalUserSession() Then
		Return False;
	EndIf;
	
	SystInfo = New SystemInfo;
	If SystInfo.PlatformType <> PlatformType.Windows_x86
		And SystInfo.PlatformType <> PlatformType.Windows_x86_64 Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function AvailableUpdateInformationInSettings()
	
	Try
		
		Result           = NewDetailsOfAvailableUpdateInfoToSave();
		SavedValue = Common.CommonSettingsStorageLoad(
			GetApplicationUpdatesClientServer.CommonSettingsID(),
			SettingKeyAvailableUpdateInfo());
		
		If TypeOf(SavedValue) = Type("Structure") Then
			FillPropertyValues(Result, SavedValue);
		Else
			Return Undefined;
		EndIf;
		
		If Result.ApplicationName <> OnlineUserSupport.InternalApplicationName()
			Or Result.MetadataName <> OnlineUserSupport.ConfigurationName()
			Or Result.Metadata_Version <> OnlineUserSupport.ConfigurationVersion()
			Or Result.PlatformVersion <> OnlineUserSupport.Current1CPlatformVersion()
			Or TypeOf(Result.AvailableUpdateInformation) <> Type("Structure") Then
			
			Return Undefined;
			
		Else
			Return Result.AvailableUpdateInformation;
		EndIf;
		
	Except
		
		WriteErrorToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить информацию о доступном обновлении из настроек пользователя.
					|%1';
					|en = 'Cannot get available update information from user settings.
					|%1';"),
				ErrorProcessing.DetailErrorDescription(ErrorInfo())));
		
		Return Undefined;
		
	EndTry;
	
EndFunction

// Prepares an object containing information on the available update.
//
// Parameters:
//  AvailableUpdateInformation - Undefined - No information on available updates.
//                                 - See AvailableUpdateInformationInternal
//  ForToDoList - Boolean - True if StandardSubsystems.ToDoList requires information on available updates.
//    
//
// Returns:
//  Undefined - No available updates.
//  Structure:
//    * Text - String - Information on the update.
//    * RecommendedToInstall - Boolean
//    * Important - Boolean
//    * Error - Boolean
//
Function AvailableUpdateNotificationParameters(AvailableUpdateInformation, ForToDoList = False)
	
	If TypeOf(AvailableUpdateInformation) <> Type("Structure") Then
		Return Undefined;
	EndIf;
	
	Result = New Structure();
	Result.Insert("Text"                  , "");
	Result.Insert("RecommendedToInstall", False);
	Result.Insert("Important"                 , False);
	Result.Insert("Error"                 , False);
	
	If Not IsBlankString(AvailableUpdateInformation.ErrorName) Then
		
		If AvailableUpdateInformation.ErrorName = "ConnectError"
			Or AvailableUpdateInformation.ErrorName = "ServerError"
			Or AvailableUpdateInformation.ErrorName = "ClientError" Then
			
			// Process the connection error.
			Result.Text  = NStr("ru = 'Не удалось проверить наличие обновлений программы.';
									|en = 'Cannot check for application updates.';");
			Result.Important = True;
			Result.Error = True;
			
			Return Result;
			
		EndIf;
		
	Else
		
		ComConfUpdate  = AvailableUpdateInformation.Configuration;
		PlComUpdate    = AvailableUpdateInformation.Platform;
		UpdateAvailable =
			(ComConfUpdate <> Undefined
			And ComConfUpdate.UpdateAvailable
			Or AvailableUpdateInformation.Corrections <> Undefined
			And AvailableUpdateInformation.Corrections.Count() > 0
			And Not AutomaticPatchesImportEnabled()
			Or PlComUpdate <> Undefined
			And PlComUpdate.UpdateAvailable);
		
		If UpdateAvailable Then
			
			// Long-term support is enabled for the current version
			If AvailableUpdateInformation.EndOfCurrentVersionSupport <> Undefined
				And AvailableUpdateInformation.EndOfCurrentVersionSupport > CurrentSessionDate()
				And AutoupdateSettings().UpdateReleaseNotificationOption = 1 Then
				
				// Search for an update for the current version without a build number
				HasUpdateForCurrentVersion = False;
				CurrentVersionWithoutBuild          = CommonClientServer.ConfigurationVersionWithoutBuildNumber(
					OnlineUserSupport.ConfigurationVersion());
				
				If ComConfUpdate <> Undefined
					And CurrentVersionWithoutBuild = CommonClientServer.ConfigurationVersionWithoutBuildNumber(ComConfUpdate.Version) Then
					
					HasUpdateForCurrentVersion = True;
					
				Else
					For Each AdditionalVersion In AvailableUpdateInformation.AdditionalVersions Do
						VersionWithoutBuildNumber = CommonClientServer.ConfigurationVersionWithoutBuildNumber(
							AdditionalVersion.Configuration.Version);
						If CurrentVersionWithoutBuild = VersionWithoutBuildNumber Then
							HasUpdateForCurrentVersion = AdditionalVersion.Configuration.UpdateAvailable;
							Break;
						EndIf;
					EndDo;
				EndIf;
				
				If Not HasUpdateForCurrentVersion Then
					Return Undefined;
				EndIf;
				
			EndIf;
			
			Result.Text = NStr("ru = 'Доступно обновление программы.';
									|en = 'Application update is available.';");
			
			ComConfUpdate = AvailableUpdateInformation.Configuration;
			PlComUpdate   = AvailableUpdateInformation.Platform;
			
			Result.RecommendedToInstall = ((ComConfUpdate = Undefined
				Or Not ComConfUpdate.UpdateAvailable)
				And (PlComUpdate <> Undefined
				And PlComUpdate.UpdateAvailable
				And PlComUpdate.InstallationRequired < 2));
			
			If Result.RecommendedToInstall Then
				If Not ForToDoList Then
					Result.Text = Result.Text + Chars.LF
						+ NStr("ru = 'Рекомендуется установить это обновление.';
								|en = 'We recommend that you install this update.';");
				EndIf;
				Result.Important = True;
			EndIf;
			
			Return Result;
			
		EndIf;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Generates a new object for setting up auto-updates.
//
// Returns:
//  Structure:
//    * AutomaticCheckForProgramUpdates - Number - An automatic update check mode.
//        Valid values are::
//          "0" - Do not check for updates.
//          "1" - Check on startup.
//          "2" - Check on schedule.
//    * Schedule - Undefined - The schedule is not configured.
//                 - Structure of See CommonClientServer.StructureToSchedule
//    * LastCheckDate - Date - The date and time of the last update schedule check.
//        Required if "ApplicationUpdateAutoCheckMode" is set to "1".
//    * PlatformDistributionPackagesDirectory - Undefined - The default directory.
//                                    - String - The user-selected directory.
//    * InstallationMode - Number - 1C:Enterprise installation mode. Valid values are::
//        "0" - Silent installation. The default value.
//        "1" - Interactive installation.
//    * UpdateReleaseNotificationOption - Number - The option of notifying users of a version release.
//        Valid values are:
//          "0" - Notify of all releases.
//          "1" - Notify of build releases for the current version if its long-term support is valid.
//            Otherwise, notify of all releases.
//
Function NewAutoupdateSettings()
	
	Result = New Structure();
	Result.Insert("AutomaticCheckForProgramUpdates", 1);
	Result.Insert("Schedule"                                           , Undefined);
	Result.Insert("LastCheckDate"                                , '00010101');
	Result.Insert("PlatformDistributionPackagesDirectory"                        , Undefined);
	Result.Insert("InstallationMode"                                       , 0);
	Result.Insert("UpdateReleaseNotificationOption"               , 0);
	
	Return Result;
	
EndFunction

Function FileDirectoryFromFullName(FullFileName)
	
	StringLength = StrLen(FullFileName);
	For Iterator_SSLy = 0 To StringLength - 1 Do
		CurCharIndex = StringLength - Iterator_SSLy;
		CurChar = Mid(FullFileName, CurCharIndex, 1);
		If CurChar = "\" Or CurChar = "/" Then
			Return Left(FullFileName, CurCharIndex);
		EndIf;
	EndDo;
	
	Return "";
	
EndFunction

Function DirectoryContains1CEnterprisePlatformDistributionPackage(Val Directory, Version)
	
	If Right(Directory, 1) <> "\" Then
		Directory = Directory + "\";
	EndIf;
	
	If Not GetApplicationUpdatesClientServer.FileExists(Directory)
		Or Not GetApplicationUpdatesClientServer.FileExists(Directory + "setup.exe")
		Or Not GetApplicationUpdatesClientServer.FileExists(Directory + "Setup.ini") Then
		Return False;
	EndIf;
	
	// Read the INI file strings
	TextReader = New TextReader(Directory + "Setup.ini");
	HasProductName = False;
	HasVersionNumber = False;
	If GetApplicationUpdatesClientServer.Is64BitApplication() Then
		ProductStringToSearch = "PRODUCT=1C:ENTERPRISE 8 (X86-64)";
	Else
		ProductStringToSearch = "PRODUCT=1C:ENTERPRISE 8";
	EndIf;
	VersionStringToSearch = "PRODUCTVERSION=" + Version;
	
	Try
		
		ReadString = TextReader.ReadLine();
		While ReadString <> Undefined Do
			ReadStringInReg = Upper(TrimAll(ReadString));
			If ReadStringInReg = ProductStringToSearch Then
				HasProductName = True;
			ElsIf ReadStringInReg = VersionStringToSearch Then
				HasVersionNumber = True;
			EndIf;
			
			If HasProductName And HasVersionNumber Then
				TextReader.Close();
				Return True;
			EndIf;
			
			ReadString = TextReader.ReadLine();
		EndDo;
		
		TextReader.Close();
		
	Except
		
		GetApplicationUpdatesServerCall.WriteErrorToEventLog(
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	Return False;
	
EndFunction

// Checks if the app can be updated and runs a long-running operation that checks for updates.
//
// Returns:
//  Undefined - Returns if the app cannot be updated, the long-running operation is canceled, or an error occurred.
//  See TimeConsumingOperations.ExecuteFunction
//    - Returns if the job's status is "Running" or "Completed2".
//
Function StartUpdateExistenceCheck() Export
	
	If Not CanUseApplicationUpdate() Then
		Return Undefined;
	EndIf;
	
	Try
		
		ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(New UUID);
		ExecutionParameters.RunInBackground              = True;
		ExecutionParameters.WaitCompletion           = 0;
		ExecutionParameters.BackgroundJobKey         = "CheckForApplicationUpdates"
			+ String(New UUID);
		ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Проверка наличия обновлений программы';
																|en = 'Check for application updates';");
		
		Result = TimeConsumingOperations.ExecuteFunction(
			ExecutionParameters,
			"GetApplicationUpdates.CheckBackgroundUpdateAvailability");
		
		If Result.Status = "Canceled" Then
			
			WriteInformationToEventLog(
				NStr("ru = 'Не удалось выполнить фоновую проверку наличия обновлений. Задание отменено администратором.';
					|en = 'Cannot check the update availability in the background. The job is canceled by the administrator.';"));
			Return Undefined;
			
		ElsIf Result.Status = "Error" Then
			
			WriteErrorToEventLog(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка фоновой проверки наличия обновлений. Не удалось выполнить фоновое задание. %1';
						|en = 'An error occurred when checking the update availability in the background. Cannot execute the background job. %1';"),
					Result.DetailErrorDescription));
			Return Undefined;
			
		Else
			Return Result;
		EndIf;
		
	Except
		
		WriteErrorToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка фоновой проверки наличия обновлений. Не удалось выполнить фоновое задание. %1';
					|en = 'An error occurred when checking the update availability in the background. Cannot execute the background job. %1';"),
				ErrorProcessing.DetailErrorDescription(ErrorInfo())));
		Return Undefined;
		
	EndTry;
	
EndFunction

#Region Corrections

Function InstallAndDeletePatches(
	Corrections,
	RevokedPatches,
	DeletePatchesFiles = False,
	InBackground = False) Export
	
	Result = New Structure;
	Result.Insert("Error"               , False);
	Result.Insert("Message"            , "");
	Result.Insert("ErrorInfo"   , "");
	Result.Insert("MessageForTechSupport", "");
	
	// Checking which patches are already installed.
	InstalledPatches = ConfigurationUpdate.InstalledPatches();
	InstalledPatchesForCheckIDs = New Map;
	For Each CurPatch In InstalledPatches Do
		InstalledPatchesForCheckIDs.Insert(CurPatch.Id, True);
	EndDo;
	
	PatchesToInstallStrDetails     = New Array;
	InstalledPatchesIDsStrDetails = New Array;
	PatchesFilesParameter = New Array;
	For Each CurPatch In Corrections Do
		StrID = String(CurPatch.Id);
		If InstalledPatchesForCheckIDs[StrID] = Undefined Then
			PatchesToInstallStrDetails.Add("" + StrID);
			If Not IsBlankString(CurPatch.FileAddress) Then
				PatchesFilesParameter.Add(CurPatch.FileAddress);
			Else
				PatchesFilesParameter.Add(
					PutToTempStorage(
						New BinaryData(CurPatch.ReceivedFileName)));
				If DeletePatchesFiles Then
					Try
						DeleteFiles(CurPatch.ReceivedFileName);
					Except
						WriteErrorToEventLog(
							StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = 'Не удалось удалить файл исправления %1.
									|%2';
									|en = 'Cannot delete patch file %1.
									|%2';"),
								CurPatch.ReceivedFileName,
							ErrorProcessing.DetailErrorDescription(ErrorInfo())));
					EndTry;
				EndIf;
			EndIf;
		Else
			InstalledPatchesIDsStrDetails.Add(StrID);
		EndIf;
	EndDo;
	
	// Call the patch installation.
	PatchesDetails = New Structure;
	PatchesDetails.Insert("Set", PatchesFilesParameter);
	PatchesDetails.Insert("Delete"   , RevokedPatches);
	
	If PatchesDetails.Set.Count() = 0
		And PatchesDetails.Delete.Count() = 0 Then
		WriteInformationToEventLog(
			NStr("ru = 'Установка и удаление исправлений не требуются (все исправления были установлены ранее).';
				|en = 'There no patches to install or delete. All patches have been installed earlier.';"));
		Return Result;
	EndIf;
	
	WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Вызов установки и удаления исправлений (БСП).
				|Исправления для установки:
				|%1
				|
				|Исправления для удаления (отозванные):
				|%2
				|
				|Уже установлены (исключены из установки):
				|%3.';
				|en = 'Call patch installation and deletion (SSL).
				|Patches to install:
				|%1
				|
				|Patches to delete (withdrawn):
				|%2
				|
				|Installed patches (excluded from installation):
				|%3.';"),
			StrConcat(PatchesToInstallStrDetails, Chars.LF),
			StrConcat(RevokedPatches, Chars.LF),
			StrConcat(InstalledPatchesIDsStrDetails, Chars.LF)));
	PatchesInstallationParameters = ConfigurationUpdate.PatchesInstallationParameters();
	PatchesInstallationParameters.InBackground = InBackground;
	InstallResult = ConfigurationUpdate.InstallAndDeletePatches(PatchesDetails, PatchesInstallationParameters);
	
	If InstallResult.Unspecified > 0 Or InstallResult.NotDeleted > 0 Then
		
		// If some patches failed to be installed/uninstalled, this is considered an issue,
		// as the update was partially applied and should be handled as an error.
		// 
		ErrorMessage     = "";
		MessageInLog     = "";
		MessageForTechSupport = New Array();
		
		If InstallResult.Unspecified > 0 Then
			
			Message = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось установить исправления (%1 шт.).';
					|en = 'Cannot install patches (%1 pcs.).';"),
				InstallResult.Unspecified);
			
			ErrorMessage = Message;
			MessageInLog = Message;
			
			MessageForTechSupport.Add(Message);
			For Each CurError In InstallResult.Errors Do
				
				If CurError.Event <> "Set" Then
					Continue
				EndIf;
				
				MessageForTechSupport.Add(
					"--------------------------------------------------------------------------------");
				MessageForTechSupport.Add(CurError.PatchNumber);
				MessageForTechSupport.Add(TrimAll(CurError.Cause));
				
			EndDo;
			MessageForTechSupport.Add(
				"--------------------------------------------------------------------------------");
			
		EndIf;
		
		If InstallResult.NotDeleted > 0 Then
			
			Message = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось удалить исправления (%1 шт.).';
						|en = 'Cannot delete patches (%1 pcs.).';"),
					InstallResult.NotDeleted);
			
			ErrorMessage = ErrorMessage + ?(IsBlankString(ErrorMessage), "", Chars.LF) + Message;
			MessageInLog = MessageInLog + ?(IsBlankString(MessageInLog), "", Chars.LF) + Message;
			
			MessageForTechSupport.Add();
			MessageForTechSupport.Add(Message);
			For Each CurError In InstallResult.Errors Do
				
				If CurError.Event <> "Delete" Then
					Continue
				EndIf;
				
				MessageForTechSupport.Add(
					"--------------------------------------------------------------------------------");
				MessageForTechSupport.Add(CurError.PatchNumber);
				MessageForTechSupport.Add(TrimAll(CurError.Cause));
				
			EndDo;
			MessageForTechSupport.Add(
				"--------------------------------------------------------------------------------");
			
		EndIf;
		
		WriteErrorToEventLog(MessageInLog);
		
		Result.Error                = True;
		Result.Message             = ErrorMessage;
		Result.ErrorInfo    = MessageInLog;
		Result.MessageForTechSupport = TrimL(StrConcat(MessageForTechSupport, Chars.LF));
		
	Else
		
		WriteInformationToEventLog(NStr("ru = 'Установка и удаление исправлений успешно завершены.';
													|en = 'Patches are successfully installed and deleted.';"));
		
	EndIf;
	
	Return Result;
	
EndFunction

// Based on the update import settings, runs an asynchronous process
// that checks for app updates (if required).
//
// Parameters:
//  Parameters - Structure - A structure of startup client parameters.
//
Procedure CheckForUpdatesOnStartup(Parameters)
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	SettingsOfUpdate = Parameters.GetApplicationUpdates;
	CheckDate        = CurrentSessionDate();
	
	CheckForUpdate = New Structure;
	CheckForUpdate.Insert("WasCheckStarted", False);
	CheckForUpdate.Insert("JobDetails" , Undefined);
	
	// Processing automatic update check settings.
	If SettingsOfUpdate.AutomaticCheckForProgramUpdates = 1 Then
		CheckForUpdate.WasCheckStarted = True;
	ElsIf SettingsOfUpdate.AutomaticCheckForProgramUpdates = 2 Then
		
		// Determining whether it is necessary to execute a scheduled check
		Schedule = CommonClientServer.StructureToSchedule(SettingsOfUpdate.Schedule);
		LastCheckDate = SettingsOfUpdate.LastCheckDate;
		
		If Schedule.ExecutionRequired(CheckDate, LastCheckDate) Then
			CheckForUpdate.WasCheckStarted = True;
		EndIf;
		
	EndIf;
	
	If Not CheckForUpdate.WasCheckStarted Then
		Parameters.CheckForUpdate = CheckForUpdate;
		Return;
	EndIf;
	
	If SettingsOfUpdate.AutomaticCheckForProgramUpdates = 2 Then
		// Writing the last check date.
		Parameters.GetApplicationUpdates.LastCheckDate = CheckDate;
		WriteAutoupdateSettings(Parameters.GetApplicationUpdates);
	EndIf;
	
	CheckForUpdate.JobDetails = StartUpdateExistenceCheck();
	
	Parameters.CheckForUpdate = CheckForUpdate;
	
EndProcedure

// Returns a list of app names and versions for patch installation.
// The list contains the main app version and the additional subsystems described in the overridable module.
// See GetApplicationUpdatesOverridable.OnDefinePatchesDownloadSettings.
// 
// Returns:
//  Array of Structure:
//    * ApplicationName - String - The app name in Online Support services.
//    * Version - String
//
Function VersionsOfPatchApps()
	
	// Gather info on the main configuration.
	ConfigurationsVersions = New Array;
	ConfigurationsVersions.Add(
		New Structure("ApplicationName, Version",
			OnlineUserSupport.ApplicationName(),
			OnlineUserSupport.ConfigurationVersion()));
	
	// Gather info on the additional subsystems.
	AdditionalSubsystems = PatchesDownloadSettings().Subsystems;
	For Each CurrAddlSubsystem In AdditionalSubsystems Do
		
		ConfigurationVersion = New Structure();
		ConfigurationVersion.Insert("ApplicationName", CurrAddlSubsystem.OnlineSupportID);
		ConfigurationVersion.Insert("Version"      , CurrAddlSubsystem.Version);
		
		ConfigurationsVersions.Add(ConfigurationVersion);
		
	EndDo;
	
	Return ConfigurationsVersions;
	
EndFunction

#EndRegion

#Region PersonalUserSettings

Procedure SaveLastReceivedPlatformDistributionPackageDirectory(Directory)
	
	Common.CommonSettingsStorageSave(
		GetApplicationUpdatesClientServer.CommonSettingsID(),
		SettingKeyDistributionPackageDirectory(),
		Directory);
	
EndProcedure

#EndRegion

#Region BackgroundProcessesOrganization

Function CheckBackgroundUpdateAvailability() Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ConnectionSetup",
		OnlineUserSupport.ServersConnectionSettings());
	AvailableUpdateInformation = AvailableUpdateInformationInternal(
		OnlineUserSupport.InternalApplicationName(),
		OnlineUserSupport.ConfigurationVersion(),
		Undefined,
		Undefined,
		"ApplicationUpdate1",
		AdditionalParameters);
	
	Return AvailableUpdateInformation;
	
EndFunction

Function DetermineAvailableUpdateNotificationParameters(ResultAddress) Export
	
	Result = GetFromTempStorage(ResultAddress);
	SaveAvailableUpdateInformationInSettings(Result);
	NotificationParameters = AvailableUpdateNotificationParameters(Result);
	If NotificationParameters = Undefined Then
		Return -1;
	Else
		Return NotificationParameters;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Get and install patches in the file mode (in the background).
// 

Function DownloadAndInstallUpdatesInBackground(Parameters) Export
	
	If Not CanUseApplicationUpdate(True, False) Then
		Raise NStr("ru = 'Использование обновления программы недоступно в текущем режиме работы.';
								|en = 'Application update cannot be used in the current operation mode.';");
	EndIf;
	
	AddlParameters = Undefined;	// See GetApplicationUpdatesClientServer.NewContextOfGetAndInstallUpdates
	
	Result = New Structure();
	Result.Insert("StatusCode", "");
	Result.Insert("AddlParameters", AddlParameters);
	
	Context = Parameters.UpdateContext;	// See GetApplicationUpdatesClientServer.NewContextOfGetAndInstallUpdates
	If Context = Undefined Then
		Context = GetApplicationUpdatesClientServer.NewContextOfGetAndInstallUpdates(Parameters);
	Else
		// Reset the error status.
		Context.ErrorName          = "";
		Context.Message          = "";
		Context.ErrorInfo = "";
	EndIf;
	
	SetPrivilegedMode(True);
	AuthenticationData = OnlineUserSupport.OnlineSupportUserAuthenticationData();
	SetPrivilegedMode(False);
	
	If AuthenticationData = Undefined Then
		Context.ErrorName     = "AuthenticationDataNotFilled";
		Context.Message     = NStr("ru = 'Не заполнены данные аутентификации.';
										|en = 'Authentication data is required.';");
		Result.StatusCode = "Error";
		Result.AddlParameters = Context;
		Return Result;
	EndIf;
	
	FilesReceived        = 0;
	ReceivedFilesVolume = 0;
	
	// 1. Getting a platform update file.
	If Context.UpdatePlatform Then
		
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Получение обновления платформы 1С:Предприятие: версия %1; URL: %2';
					|en = 'Receive 1C:Enterprise platform update: %1; URL: %2';"),
				Context.PlatformVersion,
				Context.PlatformUpdateFileURL));
		
		If Not IsBlankString(Context.PlatformDistributionPackageDirectory) Then
			
			FilesReceived        = 1;
			ReceivedFilesVolume = ReceivedFilesVolume + Context.PlatformUpdateSize;
			
			WriteInformationToEventLog(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Обновление платформы 1С:Предприятие уже было загружено ранее в %1';
						|en = 'Update of 1C:Enterprise platform has already been downloaded to %1';"),
					Context.PlatformDistributionPackageDirectory));
			
		Else
			
			PlatformInstallationDirectory = GetApplicationUpdatesClientServer.OneCEnterprisePlatformInstallationDirectory(
				Context.PlatformVersion);
			If PlatformInstallationDirectory <> Undefined Then
				
				// Platform is already installed.
				FilesReceived        = 1;
				ReceivedFilesVolume = ReceivedFilesVolume + Context.PlatformUpdateSize;
				Context.PlatformUpdateInstalled = True;
				
				WriteInformationToEventLog(
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Версия %1 платформы 1С:Предприятие уже установлена на компьютере.';
							|en = '1C:Enterprise platform version %1 is already installed on the computer.';"),
						Context.PlatformVersion));
				
			Else
				
				// Importing a platform file.
				Context.CurrentAction1 =
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Получение файла %1 из %2';
							|en = 'Receive %1 file from %2';"),
						String(FilesReceived + 1),
						Context.FilesCount);
				Report_State("GettingFiles", , Context);
				
				ImportPlatformUpdate(Context, Parameters, AuthenticationData);
				If Not IsBlankString(Context.ErrorName) Then
					// An error occurred when importing the platform.
					Result.StatusCode = "Error";
					Result.AddlParameters = Context;
					Return Result;
				Else
					FilesReceived        = 1;
					ReceivedFilesVolume = ReceivedFilesVolume + Context.PlatformUpdateSize;
					Context.Progress = 75 * (ReceivedFilesVolume / Context.FilesVolume);
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	// 2. Getting configuration update files.
	For Each CurrUpdate In Context.ConfigurationUpdates Do
		
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Получение обновления конфигурации.
					|URL: %1;
					|Размер: %2;
					|Формат файла обновления: %3;
					|Контрольная сумма файла обновления: %4;
					|Каталог дистрибутива: %5;
					|Выполнить обработчики обновления: %6;
					|Имя файла обновления (cfu): %7.';
					|en = 'Receive configuration update.
					|URL: %1;
					|Size: %2;
					|Update file format: %3;
					|Checksum update file: %4;
					|Distribution directory: %5;
					|Run update data processors: %6;
					|Update file name (cfu): %7.';"),
				CurrUpdate.UpdateFileURL,
				CurrUpdate.FileSize,
				CurrUpdate.UpdateFileFormat,
				CurrUpdate.Checksum,
				CurrUpdate.DistributionPackageDirectory,
				CurrUpdate.ApplyUpdateHandlers,
				CurrUpdate.RelativeCFUFilePath));
		
		Context.CurrentAction1 =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Получение файла %1 из %2';
					|en = 'Receive %1 file from %2';"),
				String(FilesReceived + 1),
				Context.FilesCount);
		Context.Progress = 75 * (ReceivedFilesVolume / Context.FilesVolume);
		Report_State("GettingFiles", , Context);
		
		If Not GetApplicationUpdatesClientServer.ConfigurationUpdateReceived(CurrUpdate, Context) Then
			
			DownloadConfigurationUpdate(CurrUpdate, Context, Parameters, AuthenticationData);
			If Not IsBlankString(Context.ErrorName) Then
				Result.StatusCode = "Error";
				Result.AddlParameters = Context;
				Return Result;
			EndIf;
			
		Else
			
			WriteInformationToEventLog(
				NStr("ru = 'Обновление конфигурации уже было получено ранее.';
					|en = 'The configuration update has already been received.';"));
			
		EndIf;
		
		FilesReceived        = FilesReceived + 1;
		ReceivedFilesVolume = ReceivedFilesVolume + CurrUpdate.FileSize;
		
	EndDo;
	
	// 3) Getting patch files.
	For Each CurPatch In Context.Corrections Do
		
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Получение файла исправления (патча).
					|URL: %1;
					|Идентификатор: %2;
					|Размер: %3;
					|Локальный файл: %4.';
					|en = 'Get a patch file.
					|URL: %1;
					|ID: %2;
					|Size: %3;
					|Local file: %4.';"),
				CurPatch.FileURL,
				CurPatch.Id,
				CurPatch.Size,
				CurPatch.ReceivedFileName));
			
		Context.CurrentAction1 =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Получение файла %1 из %2';
					|en = 'Receive %1 file from %2';"),
				String(FilesReceived + 1),
				Context.FilesCount);
		Context.Progress = 75 * (ReceivedFilesVolume / Context.FilesVolume);
		Report_State("GettingFiles", , Context);
			
		If Not CurPatch.ReceivedEmails Then
			
			GetResult1 = ImportPatchFile(
				CurPatch.FileURL,
				CurPatch.Id,
				AuthenticationData);
			
			If GetResult1.Error Then
				
				LogMessage =
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Ошибка при получении файла исправления (патча) (%1). %2';
							|en = 'An error occurred while getting a patch file (%1). %2';"),
						CurPatch.FileURL,
						GetResult1.DetailedErrorDetails);
				WriteErrorToEventLog(LogMessage);
				
				Context.ErrorName = "PatchFileDownloadError";
				Context.ErrorInfo = LogMessage;
				Context.Message = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка при получении файла исправления (патча). %1';
						|en = 'An error occurred while getting a patch file. %1';"),
					GetResult1.BriefErrorDetails);
				Result.StatusCode = "Error";
				Result.AddlParameters = Context;
				Return Result;
				
			Else
				
				Try
					GetResult1.Content.Write(CurPatch.ReceivedFileName);
				Except
					
					ErrorInfo = ErrorInfo();
					LogMessage =
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Ошибка при получении файла исправления (патча) (%1).
								|Не удалось сохранить файл в локальном каталоге.
								|%2';
								|en = 'An error occurred while getting a patch file (%1).
								|Couldn''t save the file to the local directory.
								|%2';"),
							CurPatch.FileURL,
							ErrorProcessing.DetailErrorDescription(ErrorInfo));
					WriteErrorToEventLog(LogMessage);
					
					Context.ErrorName = "FileSystemError";
					Context.ErrorInfo = LogMessage;
					Context.Message = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Ошибка при получении файла исправления (патча). %1';
							|en = 'An error occurred while getting a patch file. %1';"),
						ErrorProcessing.BriefErrorDescription(ErrorInfo));
					Result.StatusCode = "Error";
					Result.AddlParameters = Context;
					Return Result;
					
				EndTry;
				
				CurPatch.ReceivedEmails = True;
				WriteInformationToEventLog(NStr("ru = 'Файл исправления (патча) успешно получен.';
															|en = 'The patch file is received.';"));
				
			EndIf;
			
		Else
			
			WriteInformationToEventLog(
				NStr("ru = 'Исправление (патч) уже было получено ранее.';
					|en = 'The patch has already been received.';"));
			
		EndIf;
		
		FilesReceived        = FilesReceived + 1;
		ReceivedFilesVolume = ReceivedFilesVolume + CurPatch.Size;
		
	EndDo;
	
	Context.UpdateFilesReceived = True;
	
	// 4) Install platform.
	If Context.UpdatePlatform And Not Context.PlatformUpdateInstalled Then
		
		Context.Progress        = 80;
		Context.CurrentAction1 = NStr("ru = 'Установка платформы 1С:Предприятие';
										|en = 'Install 1C:Enterprise platform';");
		Report_State("InstallPlatform", , Context);
		
		InstallationCanceled = False;
		InstallPlatformUpdate(Context, Parameters, InstallationCanceled);
		If InstallationCanceled Then
			
			Result.StatusCode = "PlatformInstallationCanceled";
			Result.AddlParameters = Context;
			Return Result;
			
		ElsIf Not IsBlankString(Context.ErrorName) Then
			
			// Platform installation error.
			Result.StatusCode = "Error";
			Result.AddlParameters = Context;
			Return Result;
			
		Else
			
			Context.PlatformUpdateInstalled = True;
			
		EndIf;
		
	EndIf;
	
	// 5) Installing or deleting patches.
	If Context.ConfigurationUpdates.Count() = 0
		And (Context.Corrections.Count() > 0
		Or Context.RevokedPatches.Count() > 0) Then
		// Install/uninstall patches right away if they were issued
		// for the current configuration version.
		
		Context.Progress = 85;
		Context.CurrentAction1 = NStr("ru = 'Установка исправлений (патчей)';
										|en = 'Install patches';");
		Report_State("InstallingPatches", , Context);
		
		InstallResult = InstallAndDeletePatches(Context.Corrections, Context.RevokedPatches, , True);
		If InstallResult.Error Then

			Context.ErrorName             = "PatchInstallationError";
			Context.Message             = InstallResult.Message;
			Context.ErrorInfo    = InstallResult.ErrorInfo;
			Context.MessageForTechSupport = InstallResult.MessageForTechSupport;
			
			Result.StatusCode = "Error";
			Result.AddlParameters = Context;
			Return Result;
			
		EndIf;
		
	EndIf;
	
	Context.Progress  = 100;
	Context.Completed = True;
	
	Result.StatusCode = "Completed";
	Result.AddlParameters = Context;
	Return Result;
	
EndFunction

Procedure ImportPlatformUpdate(Context, Parameters, AuthenticationData)
	
	DirectoryForImport = GetApplicationUpdatesClientServer.DirectoryToWorkWithPlatformUpdates();
	DistributionPackagesStorageDirectory = Parameters.PlatformDistributionPackagesStorageDirectory;
	
	If DistributionPackagesStorageDirectory = Undefined Then
		DistributionPackageDirectory = DirectoryForImport
			+ ?(GetApplicationUpdatesClientServer.Is64BitApplication(),
				"setup_64\",
				"setup\");
	Else
		If Right(DistributionPackagesStorageDirectory, 1) <> "\" Then
			DistributionPackagesStorageDirectory = DistributionPackagesStorageDirectory + "\";
		EndIf;
		DistributionPackageDirectory = DistributionPackagesStorageDirectory + Context.PlatformVersion
			+ ?(GetApplicationUpdatesClientServer.Is64BitApplication(), "_64", "")
			+ "\";
	EndIf;
	
	// Checking for the imported distribution package.
	DistributionPackageImported = DirectoryContains1CEnterprisePlatformDistributionPackage(
		DistributionPackageDirectory,
		Context.PlatformVersion);
	
	// Import a distribution package.
	If DistributionPackageImported Then
		Context.PlatformDistributionPackageDirectory = DistributionPackageDirectory;
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Обновление платформы 1С:Предприятие уже было загружено ранее в %1';
					|en = 'Update of 1C:Enterprise platform has already been downloaded to %1';"),
				Context.PlatformDistributionPackageDirectory));
		Return;
	EndIf;
	
	Try
		CreateDirectory(DistributionPackageDirectory);
	Except
		
		ErrorInfo = ErrorInfo();
		LogMessage =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при создании каталога для сохранения дистрибутива (%1).';
					|en = 'An error occurred while creating a directory for saving the distribution (%1).';"),
				DistributionPackageDirectory)
			+ Chars.LF
			+ ErrorProcessing.DetailErrorDescription(ErrorInfo);
		WriteErrorToEventLog(LogMessage);
		
		Context.ErrorName = "FileSystemOperationError";
		Context.ErrorInfo = LogMessage;
		Context.Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось создать каталог %1 для сохранения дистрибутива. %2';
				|en = 'Cannot create directory %1 to save the distribution. %2';"),
			DistributionPackageDirectory,
			ErrorProcessing.BriefErrorDescription(ErrorInfo));
		Return;
		
	EndTry;
	
	Try
		CreateDirectory(DirectoryForImport);
	Except
		
		ErrorInfo = ErrorInfo();
		LogMessage =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при создании каталога для загрузки дистрибутива (%1).';
					|en = 'An error occurred while creating a directory for importing the distribution (%1).';"),
				DirectoryForImport)
			+ Chars.LF
			+ ErrorProcessing.DetailErrorDescription(ErrorInfo);
		WriteErrorToEventLog(LogMessage);
		
		Context.ErrorName = "FileSystemOperationError";
		Context.ErrorInfo = LogMessage;
		Context.Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось создать каталог %1 для сохранения дистрибутива. %2';
				|en = 'Cannot create directory %1 to save the distribution. %2';"),
			DirectoryForImport,
			ErrorProcessing.BriefErrorDescription(ErrorInfo));
		Return;
		
	EndTry;
	
	// Import a file.
	ReceivedFilePath = DirectoryForImport + "setup.zip";
	
	WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Получение файла обновления платформы 1С:Предприятие: %1';
				|en = 'Receive file of 1C:Enterprise platform update: %1';"),
			ReceivedFilePath));
	
	OnlineUserSupport.CheckURL(Context.PlatformUpdateFileURL);
	AddlParameters = New Structure("RespondFileName, Timeout", ReceivedFilePath, 43200);
	GetResult1 = OnlineUserSupport.DownloadContentFromInternet(
		Context.PlatformUpdateFileURL,
		AuthenticationData.Login,
		AuthenticationData.Password,
		AddlParameters);
	
	If Not IsBlankString(GetResult1.ErrorCode) Then
		
		LogMessage =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при получении файла дистрибутива платформы 1С:Предприятие (%1). %2';
					|en = 'An error occurred while receiving a distribution file of 1C:Enterprise platform (%1). %2';"),
				Context.PlatformUpdateFileURL,
				GetResult1.ErrorInfo);
		WriteErrorToEventLog(LogMessage);
		
		Context.ErrorName = GetResult1.ErrorCode;
		Context.ErrorInfo = LogMessage;
		Context.Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при получении файла дистрибутива. %1';
				|en = 'An error occurred while receiving the distribution file. %1';"),
			GetResult1.ErrorMessage);
		If GetApplicationUpdatesClientServer.FileExists(ReceivedFilePath, False) Then
			Try
				DeleteFiles(ReceivedFilePath);
			Except
				WriteErrorToEventLog(
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EndTry;
		EndIf;
		Return;
		
	EndIf;
	
	WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Файл обновления платформы 1С:Предприятие успешно получен: %1';
				|en = 'File of 1C:Enterprise platform update is successfully received: %1';"),
			ReceivedFilePath));
	
	// Extract files.
	Try
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Извлечение дистрибутива платформы 1С:Предприятие в %1';
					|en = 'Extract 1C:Enterprise platform distribution to %1';"),
				DistributionPackageDirectory));
		ZIPReader = New ZipFileReader(ReceivedFilePath);
		ZIPReader.ExtractAll(DistributionPackageDirectory, ZIPRestoreFilePathsMode.Restore);
	Except
		
		LogMessage =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при извлечении файлов архива (%1) в каталог %2.';
					|en = 'An error occurred while extracting archive files (%1) to directory %2.';"),
				ReceivedFilePath,
				DistributionPackageDirectory)
			+ Chars.LF
			+ ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteErrorToEventLog(LogMessage);
		
		Context.ErrorName          = "FileDataExtractionError";
		Context.ErrorInfo = LogMessage;
		Context.Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось извлечь файлы дистрибутива. %1';
				|en = 'Cannot extract distribution files. %1';"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return;
		
	EndTry;
	
	ZIPReader.Close();
	
	WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Дистрибутив платформы 1С:Предприятие успешно сохранен в %1';
				|en = 'The distribution of 1C:Enterprise platform was successfully saved to %1';"),
			DistributionPackageDirectory));
	
	SaveLastReceivedPlatformDistributionPackageDirectory(DistributionPackageDirectory);
	Context.PlatformDistributionPackageDirectory = DistributionPackageDirectory;
	
	If GetApplicationUpdatesClientServer.FileExists(ReceivedFilePath, False) Then
		Try
			DeleteFiles(ReceivedFilePath);
		Except
			WriteErrorToEventLog(
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
EndProcedure

Procedure InstallPlatformUpdate(Context, Parameters, InstallationCanceled)
	
	// Prepare an installation protocol.
	DirectoryForImport  = GetApplicationUpdatesClientServer.DirectoryToWorkWithPlatformUpdates();
	DistributionPackageDirectory = Context.PlatformDistributionPackageDirectory;
	
	ProtocolFilePath = DirectoryForImport + "installlog.txt";
	Context.ProtocolFilePath = ProtocolFilePath;
	
	If GetApplicationUpdatesClientServer.FileExists(ProtocolFilePath) Then
		Try
			DeleteFiles(ProtocolFilePath);
		Except
			WriteErrorToEventLog(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка при удалении файла протокола (%1). %2';
						|en = 'An error occurred while removing protocol file (%1). %2';"),
					ProtocolFilePath,
					ErrorProcessing.DetailErrorDescription(ErrorInfo())));
		EndTry;
	EndIf;
	
	// Start installation.
	ReturnCode = 0;
	InstallationApplicationFilePath = DistributionPackageDirectory + "setup.exe";
	If Not GetApplicationUpdatesClientServer.FileExists(InstallationApplicationFilePath) Then
		
		LogMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Загружен некорректный дистрибутив платформы 1С:Предприятие. Отсутствует файл setup.exe (%1).';
				|en = 'Incorrect 1C:Enterprise platform distribution package is imported. Setup.exe file (%1) is missing.';"),
			InstallationApplicationFilePath);
		WriteErrorToEventLog(LogMessage);
		
		Context.ErrorName = "InvalidPlatformDistributionPackage";
		Context.ErrorInfo = LogMessage;
		Context.Message =
			NStr("ru = 'Загружен некорректный дистрибутив платформы 1С:Предприятие. Отсутствует файл setup.exe.';
				|en = 'Incorrect 1C:Enterprise platform distribution package is imported. Setup.exe file is missing.';");
		Return;
		
	EndIf;
	
	Try
		
		InstallationApplicationFilePath = """" + DistributionPackageDirectory + "setup.exe""";
		StartupCommand = InstallationApplicationFilePath + " "
			+ ?(Parameters.PlatformInstallationMode = 0, " /S ", "") // Quiet or full mode
			+ "/debuglog installlog.txt"; // Installation protocol.
		
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Установка новой версии платформы 1С:Предприятие (%1). %2';
					|en = 'Installing new version of the 1C:Enterprise platform (%1). %2';"),
				Context.PlatformVersion,
				StartupCommand));
		
		StartupParameters = FileSystem.ApplicationStartupParameters();
		StartupParameters.CurrentDirectory      = DirectoryForImport;
		StartupParameters.WaitForCompletion = True;
		
		RunResult = FileSystem.StartApplication(StartupCommand, StartupParameters);
		ReturnCode      = RunResult.ReturnCode;
		
	Except
		
		LogMessage =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при запуске программы установки платформы 1С:Предприятие (%1). %2';
					|en = 'An error occurred while starting the application to install 1C:Enterprise platform (%1). %2';"),
				StartupCommand,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteErrorToEventLog(LogMessage);
		
		Context.ErrorName = "PlatformInstallationError";
		Context.ErrorInfo = LogMessage;
		Context.Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при запуске программы установки платформы 1С:Предприятие. %1';
				|en = 'An error occurred while starting the application to install 1C:Enterprise platform. %1';"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return;
		
	EndTry;
	
	Context.InstallerReturnCode = ReturnCode;
	
	If ReturnCode = 0 Then
		
		WriteInformationToEventLog(NStr("ru = 'Новая версия платформы 1С:Предприятие успешно установлена.';
													|en = 'New 1C:Enterprise platform version is installed.';"));
		
	Else
		
		If ReturnCode = 1602 Or ReturnCode = 1 Then
			
			// Canceled by user.
			InstallationCanceled = True;
			
		Else
			
			// Processing other return codes.
			LogMessage =
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Установка платформы 1С:Предприятие завершена с ошибкой.
						|Версия %1;
						|Код возврата: %2;
						|Команда: %3';
						|en = 'Installation of the 1C:Enterprise platform completed with error.
						|Version %1;
						|Return code: %2;
						|Command: %3';"),
					Context.PlatformVersion,
					String(ReturnCode),
					StartupCommand);
			WriteErrorToEventLog(LogMessage);
			
			UserMessageTemplate =
				NStr("ru = '<body>При установке новой версии платформы 1С:Предприятие произошла ошибка.
					|<br />Код возврата: %1.';
					|en = '<body>An error occurred when installing a new platform version of 1C:Enterprise.
					|<br />Return code: %1.';");
			
			If GetApplicationUpdatesClientServer.FileExists(ProtocolFilePath) Then
				UserMessageTemplate = UserMessageTemplate + Chars.LF
					+ NStr("ru = '<br />Техническая информация содержится в <a href=""open:debuglog"">протоколе установки</a>.';
							|en = '<br />Technical information is in <a href=""open:debuglog""> the installation protocol</a>.';");
			EndIf;
			
			If Parameters.PlatformInstallationMode = 0
				And GetApplicationUpdatesClientServer.IsReturnCodeOfSystemPoliciesRestriction(ReturnCode) Then
				// If a policy restriction error occurs in silent mode,
				// prompt the user to restart installation in interactive mode.
				UserMessageTemplate = UserMessageTemplate + Chars.LF
					+ NStr("ru = '<br /><br /><p>Данная ошибка связана с ограничениями системных политик безопасности.
						|<br />Рекомендуется <a href=""action:retruupdateplatfom"">установить платформу с ручными настройками</a>, либо запустить
						|<br />программу от имени администратора.</p>';
						|en = '<br /><br /><p>This error is related to the restrictions of system security policies.
						|<br />It is recommended <a href=""action:retruupdateplatfom"">that you install a platform with manual settings</a>, or run the
						|<br />application as administrator.</p>';");
			EndIf;
			
			UserMessageTemplate = UserMessageTemplate
				+ Chars.LF
				+ NStr("ru = '<br /><br />При возникновении проблем напишите в <a href=""mailto:webits-info@1c.eu"">техподдержку</a>.</body>';
						|en = '<br /><br />If any issues occur, write an email to <a href=""mailto:webits-info@1c.eu"">the technical support</a>.</body>';");
			
			Context.ErrorName = "PlatformInstallationError";
			Context.ErrorInfo = LogMessage;
			Context.Message = OnlineUserSupportClientServer.SubstituteDomain(
				StringFunctionsClientServer.SubstituteParametersToString(
					UserMessageTemplate,
					String(ReturnCode)),
				OnlineUserSupport.ServersConnectionSettings().OUSServersDomain);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure DownloadConfigurationUpdate(RefreshEnabled, Context, Parameters, AuthenticationData)
	
	// Create directories.
	GetApplicationUpdatesClientServer.CreateDirectoriesToGetUpdate(RefreshEnabled, Context);
	
	If Not IsBlankString(Context.ErrorName) Then
		Return;
	EndIf;
	
	// Import a file.
	AddlParameters = New Structure("RespondFileName, Timeout", RefreshEnabled.ReceivedFileName, 43200);
	
	WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Загрузка файла обновления конфигурации %1';
				|en = 'Import an update file for the %1 configuration ';"),
			RefreshEnabled.ReceivedFileName));
	
	OnlineUserSupport.CheckURL(RefreshEnabled.UpdateFileURL);
	GetResult1 = OnlineUserSupport.DownloadContentFromInternet(
		RefreshEnabled.UpdateFileURL,
		AuthenticationData.Login,
		AuthenticationData.Password,
		AddlParameters);
	
	If Not IsBlankString(GetResult1.ErrorCode) Then
		
		LogMessage =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при получении файла дистрибутива конфигурации (%1). %2';
					|en = 'An error occurred while receiving configuration distribution file (%1). %2';"),
				RefreshEnabled.UpdateFileURL,
				GetResult1.ErrorInfo);
		WriteErrorToEventLog(LogMessage);
		
		Context.ErrorName = GetResult1.ErrorCode;
		Context.ErrorInfo = LogMessage;
		Context.Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при получении файла дистрибутива конфигурации. %1';
				|en = 'An error occurred while receiving configuration distribution file. %1';"),
			GetResult1.ErrorMessage);
		If GetApplicationUpdatesClientServer.FileExists(RefreshEnabled.ReceivedFileName, False) Then
			Try
				DeleteFiles(RefreshEnabled.ReceivedFileName);
			Except
				WriteErrorToEventLog(
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EndTry;
		EndIf;
		Return;
		
	EndIf;
	
	WriteInformationToEventLog(NStr("ru = 'Файл обновления успешно загружен.';
												|en = 'The update file is imported.';"));
	GetApplicationUpdatesClientServer.CompleteUpdateReceipt(RefreshEnabled, Context);
	RefreshEnabled.ReceivedEmails = True;
	
EndProcedure

Procedure Report_State(
	StatusCode,
	Message = "",
	AddlParameters = Undefined,
	EventLogMessage = Undefined)
	
	StateSpecifier = New Structure("StatusCode, AddlParameters", StatusCode, AddlParameters);
	If EventLogMessage <> Undefined Then
		StateSpecifier.Insert("EventLogMessage", EventLogMessage);
	EndIf;
	
	TimeConsumingOperations.ReportProgress(
		,
		Message,
		StateSpecifier);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Automatic receiving and installation of patches.

Procedure ScheduledJobGetAndInstallConfigurationPatches() Export
	
	Common.OnStartExecuteScheduledJob(
		Metadata.ScheduledJobs.GetAndInstallConfigurationTroubleshooting);
	
	If Not Users.IsFullUser(, True, False) Then
		Raise NStr("ru = 'Недостаточно прав.';
								|en = 'Insufficient rights.';");
	EndIf;
	
	ParametersOfUpdate = InternalUpdatesGetParameters();
	If Not ParametersOfUpdate.GetPatches Then
		WriteInformationToEventLog(
			NStr("ru = 'Использование получения исправлений недоступно в текущем режиме работы.
				|Регламентное задание ПолучениеИУстановкаИсправленийКонфигурации отключено.';
				|en = 'Cannot get patches in the current mode.
				|The GetAndInstallConfigurationTroubleshooting scheduled job is disabled.';"));
		ScheduledJobsServer.SetScheduledJobUsage(
			Metadata.ScheduledJobs.GetAndInstallConfigurationTroubleshooting,
			False);
		Return;
	EndIf;
	
	Job = ScheduledJobsServer.GetScheduledJob(
		Metadata.ScheduledJobs.GetAndInstallConfigurationTroubleshooting);
	If Job <> Undefined Then
		Schedule = Job.Schedule;
		RepeatPeriodInDay = Schedule.RepeatPeriodInDay;
		If RepeatPeriodInDay > 0 And RepeatPeriodInDay < 3600 Then
			Raise NStr("ru = 'Интервал автоматической установки не может быть чаще, чем один раз в час.';
									|en = 'The automatic installation interval cannot be shorter than one hour.';");
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	AuthenticationData = OnlineUserSupport.OnlineSupportUserAuthenticationData();
	SetPrivilegedMode(False);
	If AuthenticationData = Undefined Then
		WriteInformationToEventLog(NStr("ru = 'Интернет-поддержка не подключена.
			|Выполнение задания автоматического получения и установки прервано.';
			|en = 'Online support is not enabled.
			|Job for automatic receipt and installation is aborted.';"));
		Return;
	EndIf;
	
	ImportAndInstallPatchesForCurrentVersion(AuthenticationData, True);
	
EndProcedure

Procedure ImportAndInstallPatchesForCurrentVersion(AuthenticationData, InBackground)
	
	WriteInformationToEventLog(
		NStr("ru = 'Автоматическое получение и установка исправлений (патчей) для текущей версии конфигурации';
			|en = 'Automatic patch receipt and installation for the current configuration version';"));
	
	// 1) Information on available patches.
	ConfigurationsVersions = New Array;
	ConfigurationsVersions.Add(
		New Structure("ApplicationName, Version",
			OnlineUserSupport.ApplicationName(),
			OnlineUserSupport.ConfigurationVersion()));
	
	AdditionalSubsystems = PatchesDownloadSettings().Subsystems;
	For Each CurrAddlSubsystem In AdditionalSubsystems Do
		
		ConfigurationVersion = New Structure();
		ConfigurationVersion.Insert("ApplicationName", CurrAddlSubsystem.OnlineSupportID);
		ConfigurationVersion.Insert("Version"      , CurrAddlSubsystem.Version);
		
		ConfigurationsVersions.Add(ConfigurationVersion);
		
	EndDo;
	
	PatchesInformation = InformationOnAvailableConfigurationsPatches(
		ConfigurationsVersions,
		InstalledPatchesIDs());
	If PatchesInformation.Error Then
		WriteErrorToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось автоматически получить и установить исправления (патчи) для текущей версии конфигурации.
					|Не удалось получить информацию о доступных исправлениях.
					|%1';
					|en = 'Cannot download and install patches automatically for the current configuration version.
					|Cannot get information on available patches.
					|%1';"),
				PatchesInformation.DetailedErrorDetails));
		Return;
	EndIf;
	
	Corrections = PatchesInformation.Corrections;
	If Corrections = Undefined Or Corrections.Count() = 0 Then
		WriteInformationToEventLog(NStr("ru = 'Нет доступных исправлений (патчей) для установки';
													|en = 'No available patches to install';"));
		Return;
	EndIf;
	
	// 2) Import patch.
	PatchesIDs = New Array;
	RevokedPatches     = New Array;
	For Each CurPatch In Corrections Do
		If CurPatch.Revoked1 Then
			RevokedPatches.Add(String(CurPatch.Id));
		Else
			PatchesIDs.Add(String(CurPatch.Id));
		EndIf;
	EndDo;
	
	FilesDetails = InternalImportPatches(PatchesIDs, , False);
	If FilesDetails.Error Then
		WriteErrorToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось автоматически получить и установить исправления (патчи) для текущей версии конфигурации.
					|Не удалось получить информацию о доступных исправлениях.
					|%1';
					|en = 'Cannot download and install patches automatically for the current configuration version.
					|Cannot get information on available patches.
					|%1';"),
				FilesDetails.DetailedErrorDetails));
		Return;
	EndIf;
	
	// 3) Install patch.
	InstallAndDeletePatches(FilesDetails.Corrections, RevokedPatches, , InBackground);
	
	WriteInformationToEventLog(
		NStr("ru = 'Завершено автоматическое получение и установка исправлений (патчей)';
			|en = 'Automatic patch receipt and installation is completed';"));
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Update the platform version information for the current configuration version

// An event handler for the "Update1CEnterpriseVersionsInfo" scheduled job.
//
Procedure Update1CEnterpriseVersionsInfo() Export
	
	Common.OnStartExecuteScheduledJob(
		Metadata.ScheduledJobs.Update1CEnterpriseVersionsInfo);
	
	// It does not supported the SaaS mode and secure 1C:Enterprise versions.
	If Common.DataSeparationEnabled()
		Or IsSecureSoftwareSystem() Then
		
		Return;
		
	EndIf;
	
	// Check the job schedule.
	Job = ScheduledJobsServer.GetScheduledJob(
		Metadata.ScheduledJobs.Update1CEnterpriseVersionsInfo);
	If Job <> Undefined
		And (Job.Schedule.RepeatPeriodInDay > 0
		And Job.Schedule.RepeatPeriodInDay <= 3600
		Or Job.Schedule.RepeatPause > 0
		And Job.Schedule.RepeatPause <= 3600) Then
		
		Raise NStr(
			"ru = 'Интервал обновления информации о версиях платформы не может быть чаще, чем один раз в час.';
			|en = 'Information about platform versions can only be updated once an hour.';");
		
	EndIf;
	
	UpdateInfoOn1CEnterpriseVersionsForCurrentConfigurationVersion();
	
EndProcedure

// Updates the information about the minimum supported and recommended 1C:Enterprise versions
// for the current configuration and saves it to the database.
// The operation runs in the privileged mode.
//
Procedure UpdateInfoOn1CEnterpriseVersionsForCurrentConfigurationVersion()
	
	SetPrivilegedMode(True);
	
	WriteInformationToEventLog(
		NStr("ru = 'Обновление информации о версиях платформы для текущей версии конфигурации';
			|en = 'Update the platform version information for the current configuration version';"));
	
	// 1. Get information on 1C:Enterprise versions from the service.
	ApplicationName    = OnlineUserSupport.ApplicationName();
	ApplicationVersion = OnlineUserSupport.ConfigurationVersion();
	
	InfoAbout1CEnterpriseVersions = Configuration1CEnterpriseVersionsInfo(ApplicationName, ApplicationVersion);
	If InfoAbout1CEnterpriseVersions.Error Then
		WriteErrorToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обновить информацию о версиях платформы для текущей версии конфигурации по причине:
					|%1';
					|en = 'Cannot update the platform version information for the current configuration version due to:
					|%1';",
					Common.DefaultLanguageCode()),
				InfoAbout1CEnterpriseVersions.BriefErrorDetails));
		Return;
	
	// 2. Save the information on 1C:Enterprise versions.
	ElsIf Not IsBlankString(InfoAbout1CEnterpriseVersions.MinPlatformVersion)
		Or Not IsBlankString(InfoAbout1CEnterpriseVersions.RecommendedPlatformVersion) Then
		
		// Compare with the saved values
		StoredValues = InfoAbout1CEnterpriseVersions();
		If StoredValues.MinPlatformVersion <> InfoAbout1CEnterpriseVersions.MinPlatformVersion
			Or StoredValues.RecommendedPlatformVersion <> InfoAbout1CEnterpriseVersions.RecommendedPlatformVersion Then
			
			DataToBeSaved = New Structure("MinPlatformVersion,RecommendedPlatformVersion");
			FillPropertyValues(DataToBeSaved, InfoAbout1CEnterpriseVersions);
			
			Save1CEnterpriseVersionsInfo(DataToBeSaved);
			
		EndIf;
		
	EndIf;
	
	WriteInformationToEventLog(
		NStr("ru = 'Завершено обновление информации о версиях платформы для текущей версии конфигурации';
			|en = 'The platform version information for the current configuration version is updated';"));
	
EndProcedure

// Saves the passed information on 1C:Enterprise versions for the current configuration to the common settings.
//
// Parameters:
//  DataToBeSaved - Structure:
//    * MinPlatformVersion - String - A semicolon-delimited list of the minimum supported 1C:Enterprise versions.
//    * RecommendedPlatformVersion - String - A semicolon-delimited list of the recommended supported 1C:Enterprise versions.
//
Procedure Save1CEnterpriseVersionsInfo(DataToBeSaved)
	
	// Add the app name and version to the dataset to save
	// in order to re-validate the 1C:Enterprise versions upon reading. See InfoAbout1CEnterpriseVersions.
	ExtendedDataToSave = Common.CopyRecursive(DataToBeSaved);
	
	ApplicationName    = OnlineUserSupport.ApplicationName();
	ApplicationVersion = OnlineUserSupport.ConfigurationVersion();
	
	ExtendedDataToSave.Insert("ApplicationName"   , ApplicationName);
	ExtendedDataToSave.Insert("ApplicationVersion", ApplicationVersion);
	
	SetPrivilegedMode(True);
	
	Common.CommonSettingsStorageSave(
		GetApplicationUpdatesClientServer.CommonSettingsID(),
		SettingKey1CEnterpriseVersionsInfo(),
		ExtendedDataToSave,
		,
		"");
	
EndProcedure

#EndRegion

#Region UpdatesServiceOperationsCall

Function UpdatesServiceHost(Domain)
	
	
	If Domain = 0 Then
		Return "update-api.1c.ru";
	Else
		Return "update-api.1c.eu";
	EndIf;
	
EndFunction

Function UpdatesServiceOperationURL(Operation, Domain)
	
	Return "https://"
		+ UpdatesServiceHost(Domain)
		+ "/update-platform"
		+ Operation;
	
EndFunction

Function PingOperationURL(Domain)
	
	Return UpdatesServiceOperationURL("/programs/update/ping", Domain);
	
EndFunction

Function InfoOperationURL(Domain)
	
	Return UpdatesServiceOperationURL("/programs/update/info", Domain);
	
EndFunction

Function UpdatesFilesOperationsURL(Domain)
	
	Return UpdatesServiceOperationURL("/programs/update/", Domain);
	
EndFunction

Function AvailablePatchesOperationsURL(Domain)
	
	Return UpdatesServiceOperationURL("/patches/getInfo", Domain);
	
EndFunction

Function PatchesFilesOperationsURL(Domain)
	
	Return UpdatesServiceOperationURL("/patches/getFiles", Domain);
	
EndFunction

Function OperationURL1CEnterpriseVersionsInfo(Domain)
	
	Return UpdatesServiceOperationURL("/platform/getInfo", Domain);
	
EndFunction

Function JSONPropertyValue(ReadResponse, CurrentLevel, DefaultValue = Undefined)
	
	ReadingJSONRead(ReadResponse, CurrentLevel);
	If ReadResponse.CurrentValueType = JSONValueType.String
		Or ReadResponse.CurrentValueType = JSONValueType.Number
		Or ReadResponse.CurrentValueType = JSONValueType.Boolean Then
		Return ReadResponse.CurrentValue;
	EndIf;
	
	Return DefaultValue;
	
EndFunction

Function ReadingJSONRead(Read, CurrentLevel)
	
	Result = Read.Read();
	If Read.CurrentValueType = JSONValueType.ObjectStart Then
		CurrentLevel = CurrentLevel + 1;
	ElsIf Read.CurrentValueType = JSONValueType.ОbjectEnd Then
		CurrentLevel = CurrentLevel - 1;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure WriteAdditionalQueryParameters(AdditionalRequestParameters, MessageDataWriter)
	
	MessageDataWriter.WritePropertyName("additionalParameters");
	MessageDataWriter.WriteStartArray();
	For Each KeyValue In AdditionalRequestParameters Do
		MessageDataWriter.WriteStartObject();
		MessageDataWriter.WritePropertyName("key");
		MessageDataWriter.WriteValue(KeyValue.Key);
		MessageDataWriter.WritePropertyName("value");
		MessageDataWriter.WriteValue(String(KeyValue.Value));
		MessageDataWriter.WriteEndObject();
	EndDo;
	MessageDataWriter.WriteEndArray();
	
EndProcedure

Function AdditionalQueryParametersPresentation(AdditionalRequestParameters)
	
	Result = New Array;
	For Each KeyValue In AdditionalRequestParameters Do
		Result.Add(Chars.Tab + KeyValue.Key + ": " + String(KeyValue.Value));
	EndDo;
	
	Return StrConcat(Result, Chars.LF);
	
EndFunction

Procedure FillInformationOnPatchesFilesFromJSON(Result, ReadResponse, CurrentLevel)
	
	ReadingJSONRead(ReadResponse, CurrentLevel);
	If ReadResponse.CurrentValueType <> JSONValueType.ArrayStart Then
		Return;
	EndIf;
	
	CurrentPatch = Undefined;
	While ReadingJSONRead(ReadResponse, CurrentLevel) Do
		
		If ReadResponse.CurrentValueType = JSONValueType.ArrayEnd Then
			
			Return;
			
		ElsIf ReadResponse.CurrentValueType = JSONValueType.ObjectStart And CurrentLevel = 2 Then
			
			CurrentPatch = New Structure;
			CurrentPatch.Insert("Id"      , Undefined);
			CurrentPatch.Insert("Name"                , "");
			CurrentPatch.Insert("FileURL"           , "");
			CurrentPatch.Insert("FileName"           , "");
			CurrentPatch.Insert("FileFormat"        , "");
			CurrentPatch.Insert("Size"             , 0);
			CurrentPatch.Insert("Checksum"   , "");
			CurrentPatch.Insert("FileAddress"         , "");
			CurrentPatch.Insert("ReceivedFileName", "");
			CurrentPatch.Insert("ReceivedEmails"           , False);
			
		ElsIf ReadResponse.CurrentValueType = JSONValueType.ОbjectEnd And CurrentLevel = 1 Then
			
			Result.Corrections.Add(CurrentPatch);
			
		ElsIf ReadResponse.CurrentValueType = JSONValueType.PropertyName And CurrentLevel = 2 Then
			
			PropertyName = ReadResponse.CurrentValue;
			
			If PropertyName = "patchUeid" Then
				
				Try
					PropertyValue = JSONPropertyValue(ReadResponse, CurrentLevel, "");
					CurrentPatch.Id = New UUID(PropertyValue);
				Except
					ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Некорректный идентификатор исправления (патча) в patchUpdateList[].uin (%1)';
							|en = 'Incorrect patch ID in patchUpdateList[].uin (%1)';"),
						PropertyValue);
					Raise ExceptionText;
				EndTry;
				
			ElsIf PropertyName = "patchFileUrl" Then
				
				CurrentPatch.FileURL = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				
			ElsIf PropertyName = "patchFileName" Then
				
				CurrentPatch.FileName = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				
			ElsIf PropertyName = "patchFileFormat" Then
				
				CurrentPatch.FileFormat = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				
			ElsIf PropertyName = "size" Then
				
				CurrentPatch.Size = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				
			ElsIf PropertyName = "hashSum" Then
				
				CurrentPatch.Checksum = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Information about available update.

// Returns information about available update of the configuration and the platform.
//
// Parameters:
//  CurrentApplicationName - String - The app name in Online Support services.
//    See Common.ConfigurationOnlineSupportID.
//  CurrentApplicationVersion - String - The current app version.
//  NewApplicationName - String - The name of the new app for the MigrationToAnotherApplicationOrRevision scenario.
//    For other scenarios, an empty string.
//  NewApplicationEditionNumber - String - The version of the new app for the MigrationToAnotherApplicationOrRevision scenario.
//    For other scenarios, an empty string.
//  UpdateScenario - String - The ID of the update scenario. Available options:
//    GeneralUpdate - Search for updates for the current configuration.
//    MigrationToNewPlatformVersion - Search for updates for 1C:Enterprise.
//    MigrationToAnotherApplicationOrRevision - Search for updates to migrate to another configuration or new edition.
//    PlatformUpdateRecommendedMessage - Display information about using a non-recommended 1C:Enterprise version.
//      
//  AdditionalParameters - Structure - Additional update search parameters. A list of available keys:
//    * ConnectionSetup - See OnlineUserSupport.ServersConnectionSettings
//    * ProxyServerSettings - Structure
//    * OnlyPatches - Boolean - True if search only for new patches for the current app version.
//
// Returns:
//  Structure:
//    * ErrorName - String - An error ID.
//    * Message - String - Brief error details.
//    * ErrorInfo - String - detailed error description.
//    * UpdateAvailable - Boolean - True if the update can be installed.
//    * Scenario - String - The ID of the update scenario.
//    * Configuration - Undefined - The update scenario does not intend to search for configuration updates, or
//        the only patches are being requested.
//                   - See NewInformationOnAvailableConfigurationUpdate
//    * Platform - Undefined - Only patches are being requested.
//                - See NewInformationOnAvailablePlatformUpdate
//    * Corrections - Undefined - Notifications about new patches are disabled.
//                  - See NewPatchesInformation
//    * AdditionalVersions - Array of Structure - A list of additional versions available for installation.:
//        ** Configuration - See NewInformationOnAvailableConfigurationUpdate
//        ** Platform - See NewInformationOnAvailablePlatformUpdate
//    * EndOfCurrentVersionSupport - Undefined - Long-term support is discontinued for the current version.
//                                      - Date - The date when support for the current version will be discontinued.
//
Function AvailableUpdateInformationInternal(
	CurrentApplicationName,
	CurrentApplicationVersion,
	NewApplicationName,
	NewApplicationEditionNumber,
	UpdateScenario,
	AdditionalParameters = Undefined) Export
	
	AddlParameters = New Structure();
	AddlParameters.Insert("ConnectionSetup"   , Undefined);
	AddlParameters.Insert("ProxyServerSettings", Undefined);
	AddlParameters.Insert("OnlyPatches"     , False);
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FillPropertyValues(AddlParameters, AdditionalParameters);
	EndIf;
	
	If AddlParameters.ProxyServerSettings <> Undefined Then
		ProxySettings = AddlParameters.ProxyServerSettings.ProxySettings;
	Else
		ProxySettings = Undefined;
	EndIf;
	
	Result = New Structure;
	Result.Insert("ErrorName"                      , "");
	Result.Insert("Message"                      , "");
	Result.Insert("ErrorInfo"             , "");
	Result.Insert("UpdateAvailable"             , False);
	Result.Insert("Scenario"                       , UpdateScenario);
	Result.Insert("Configuration"                   , Undefined);
	Result.Insert("Platform"                      , Undefined);
	Result.Insert("Corrections"                    , Undefined);
	Result.Insert("AdditionalVersions"           , New Array());
	Result.Insert("EndOfCurrentVersionSupport", Undefined);
	
	CommonUpdatesGetParameters = InternalUpdatesGetParameters();
	
	If Not AddlParameters.OnlyPatches Then
		
		AdditionalParametersOperationCall = New Structure;
		AdditionalParametersOperationCall.Insert("ConnectionSetup"   , AddlParameters.ConnectionSetup);
		AdditionalParametersOperationCall.Insert("ProxyServerSettings", ProxySettings);
		
		ParametersOfUpdate = New Structure;
		ParametersOfUpdate.Insert("CurrentApplicationName", CurrentApplicationName);
		ParametersOfUpdate.Insert("CurrentApplicationVersion", CurrentApplicationVersion);
		ParametersOfUpdate.Insert("NewApplicationName", NewApplicationName);
		ParametersOfUpdate.Insert("NewApplicationEditionNumber", NewApplicationEditionNumber);
		ParametersOfUpdate.Insert("UpdateScenario",
			?(UpdateScenario = "ApplicationUpdate1" And Not CommonUpdatesGetParameters.GetConfigurationUpdates,
				"MigrationToNewPlatformVersion", // If the configuration is not updated in a working update scenario, it equals to the platform update.
				UpdateScenario));
		
		AvailableUpdateInformationOperationCall(
			Result,
			ParametersOfUpdate,
			CommonUpdatesGetParameters,
			AdditionalParametersOperationCall);
		
	EndIf;
	
	If IsBlankString(Result.ErrorName) And CommonUpdatesGetParameters.GetPatches Then
		
		Result.Corrections = NewPatchesInformation();
		
		ConfigurationsVersions = New Array;
		If UpdateScenario = "ApplicationUpdate1" Then
			
			ConfigurationsVersions.Add(
				New Structure("ApplicationName, Version", CurrentApplicationName, CurrentApplicationVersion));
			
			// The GeneralUpdate scenario has long-term support versions.
			For Each AdditionalVersion In Result.AdditionalVersions Do
				
				ConfigurationVersion = New Structure();
				ConfigurationVersion.Insert("ApplicationName", CurrentApplicationName);
				ConfigurationVersion.Insert("Version"      , AdditionalVersion.Configuration.Version);
				
				ConfigurationsVersions.Add(ConfigurationVersion);
				
			EndDo;
			
		EndIf;
		
		NewConfigurationVersionName   = Undefined;
		NewConfigurationVersionNumber = Undefined;
		If Result.Configuration <> Undefined
			And Result.Configuration.UpdateAvailable Then
			
			NewConfigurationVersionName = ?(IsBlankString(NewApplicationName), CurrentApplicationName, NewApplicationName);
			NewConfigurationVersionNumber = Result.Configuration.Version;
			ConfigurationsVersions.Add(
				New Structure(
					"ApplicationName, Version",
					NewConfigurationVersionName,
					NewConfigurationVersionNumber));
			
		EndIf;
		
		AdditionalSubsystems = PatchesDownloadSettings().Subsystems;
		For Each CurrAddlSubsystem In AdditionalSubsystems Do
			
			ConfigurationVersion = New Structure();
			ConfigurationVersion.Insert("ApplicationName", CurrAddlSubsystem.OnlineSupportID);
			ConfigurationVersion.Insert("Version"      , CurrAddlSubsystem.Version);
			
			ConfigurationsVersions.Add(ConfigurationVersion);
			
		EndDo;
		
		If ConfigurationsVersions.Count() > 0 Then
			
			ResultPatchesInformation = InformationOnAvailableConfigurationsPatches(
				ConfigurationsVersions,
				InstalledPatchesIDs(),
				False);
			
			If ResultPatchesInformation.Error Then
				Result.ErrorName = ResultPatchesInformation.BriefErrorDetails;
				Result.Message = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось получить информацию об исправлениях (патчах). %1';
						|en = 'Cannot get the information about patches. %1';"),
					ResultPatchesInformation.BriefErrorDetails);
				Result.ErrorInfo = ResultPatchesInformation.DetailedErrorDetails;
				Return Result;
			EndIf;
			
			Result.Corrections = ResultPatchesInformation.Corrections;
			For Each CurrentPatch In ResultPatchesInformation.Corrections Do
				CurrentPatch.ForCurrentVersion =
					CurrentPatch.Applicability.FindRows(
						New Structure("ApplicationName, ApplicationVersion", CurrentApplicationName, CurrentApplicationVersion)).Count() > 0;
				CurrentPatch.ForNewVersion = (NewConfigurationVersionNumber <> Undefined
					And CurrentPatch.Applicability.FindRows(
						New Structure(
							"ApplicationName, ApplicationVersion",
							NewConfigurationVersionName,
							NewConfigurationVersionNumber)).Count() > 0);
				
				For Each CurrAddlSubsystem In AdditionalSubsystems Do
					PatchApplicable = CurrentPatch.Applicability.FindRows(
						New Structure(
							"ApplicationName, ApplicationVersion",
							CurrAddlSubsystem.OnlineSupportID,
							CurrAddlSubsystem.Version)).Count() > 0;
					If PatchApplicable Then
						CurrentPatch.ForCurrentVersion = True;
						CurrentPatch.ForNewVersion   = True;
					EndIf;
				EndDo;
				
				// Force-revoke the patch in case the information on its applicability is missing from the service.
				// Issue details:
				//
				// a) A user uses an app v.1.
				//  - b) A patch for v.1 is released.
				//  - c) The user patches the app.
				//  - d) The service revokes the patch.
				//  - e) The user is unaware of that (for example, no internet connection).
				//  - f) The user updates the app to v.2.
				//  - g) The service has no information that the patch is revoked for v.2.
				//  - h) For proper functioning, the patch should be revoked regardless of its applicability.
				//  
				If Not CurrentPatch.ForCurrentVersion
					And Not CurrentPatch.ForNewVersion
					And CurrentPatch.Revoked1 Then
					CurrentPatch.ForCurrentVersion = True;
				EndIf;
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Result.UpdateAvailable =
		(Result.Configuration <> Undefined And Result.Configuration.UpdateAvailable
		Or (Result.Platform <> Undefined And Result.Platform.UpdateAvailable)
		Or Result.Corrections <> Undefined And Result.Corrections.Count() > 0);
	
	If UpdateScenario = "ApplicationUpdate1" Then
		SaveAvailableUpdateInformationInSettings(Result);
	EndIf;
	
	Return Result;
	
EndFunction

Procedure AvailableUpdateInformationOperationCall(
	Result,
	ParametersOfUpdate,
	UpdatesGetParameters,
	AdditionalParameters)
	
	CurrentApplicationName         = ParametersOfUpdate.CurrentApplicationName;
	CurrentApplicationVersion      = ParametersOfUpdate.CurrentApplicationVersion;
	NewApplicationName           = ParametersOfUpdate.NewApplicationName;
	NewApplicationEditionNumber = ParametersOfUpdate.NewApplicationEditionNumber;
	UpdateScenario          = ParametersOfUpdate.UpdateScenario;
	
	ConnectionSetup    = AdditionalParameters.ConnectionSetup;
	ProxyServerSettings = AdditionalParameters.ProxyServerSettings;
	
	GetConfigurationUpdates = (UpdateScenario <> "ApplicationUpdate1"
		And UpdateScenario <> "MigrationToNewPlatformVersion"
		Or UpdatesGetParameters.GetConfigurationUpdates);
	
	If ConnectionSetup = Undefined Then
		ConnectionSetup = OnlineUserSupport.ServersConnectionSettings();
	EndIf;
	
	ConfigurationUpdateComponent = ?(
		GetConfigurationUpdates,
		NewInformationOnAvailableConfigurationUpdate(),
		Undefined);
	Result.Insert("Configuration", ConfigurationUpdateComponent);
	
	PlatformUpdate = ?(
		IsSecureSoftwareSystem(),
		Undefined,
		NewInformationOnAvailablePlatformUpdate());
	Result.Insert("Platform", PlatformUpdate);
	
	If CurrentApplicationName = "Unknown" Then
		Result.ErrorName = "ConnectError";
		Result.Message = NStr("ru = 'Неверные параметры подключения к сервису.';
									|en = 'Incorrect service connection parameters.';");
		Result.ErrorInfo =
			NStr("ru = 'Не удалось получить информацию о доступном обновлении.
				|Не определено имя программы в методе ПриДобавленииПодсистемы() общего модуля ОбновлениеИнформационнойБазы[Имя программы].';
				|en = 'Cannot get information on available updates.
				|The OnAddSubsystem() method of the InfobaseUpdate[Application name] common module has not determined the application name.';");
		WriteErrorToEventLog(Result.ErrorInfo);
		Return;
	EndIf;
	
	// Check service availability.
	PingOperationURL = PingOperationURL(ConnectionSetup.OUSServersDomain);
	CheckResult = OnlineUserSupport.CheckURLAvailable(PingOperationURL, ProxyServerSettings);
	
	If Not IsBlankString(CheckResult.ErrorName) Then
		Result.ErrorName = CheckResult.ErrorName;
		Result.Message = CheckResult.ErrorMessage;
		Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить информацию о доступном обновлении.
				|Не удалось проверить доступность сервиса автоматического обновления программы: %1.
				|Причина:
				|%2';
				|en = 'Cannot get available update information.
				|Cannot check availability of automatic application update service: %1.
				|Reason:
				|%2';"),
			PingOperationURL,
			CheckResult.ErrorInfo);
		WriteErrorToEventLog(Result.ErrorInfo);
		Return;
	EndIf;
	
	// Call a service operation.
	URLOperations = InfoOperationURL(ConnectionSetup.OUSServersDomain);
	
	OperationParametersList = New Structure;
	OperationParametersList.Insert("CurrentApplicationName", CurrentApplicationName);
	OperationParametersList.Insert("CurrentApplicationVersion", CurrentApplicationVersion);
	OperationParametersList.Insert("NewApplicationName", NewApplicationName);
	OperationParametersList.Insert("NewApplicationEditionNumber", NewApplicationEditionNumber);
	OperationParametersList.Insert("UpdateScenario", UpdateScenario);
	
	AdditionalRequestParameters_ = AdditionalParametersOfQueryToUpdatesService();
	
	// Log the query.
	WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Получение информации о доступном обновлении (%1).';
				|en = 'Get available update information (%1).';"),
			URLOperations)
		+ Chars.LF
		+ StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Имя текущей программы: %1;
				|Версия текущей программы: %2;
				|Имя новой программы: %3;
				|Номер редакции новой программы: %4;
				|Сценарий обновления: %5;
				|Дополнительные параметры:
				|%7';
				|en = 'Current application name: %1;
				|Current application version:%2;
				|New application name: %3;
				|New application version: %4;
				|Update scenario: %5;
				|Additional parameters:
				|%7';"),
			OperationParametersList.CurrentApplicationName,
			OperationParametersList.CurrentApplicationVersion,
			OperationParametersList.NewApplicationName,
			OperationParametersList.NewApplicationEditionNumber,
			OperationParametersList.UpdateScenario,
			AdditionalQueryParametersPresentation(AdditionalRequestParameters_)));
	
	JSONQueryParameters = InfoRequestJSON(OperationParametersList, AdditionalRequestParameters_);
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/json");
	SendOptions = New Structure;
	SendOptions.Insert("Method"                   , "POST");
	SendOptions.Insert("AnswerFormat"            , 1);
	SendOptions.Insert("Headers"               , Headers);
	SendOptions.Insert("DataForProcessing"      , JSONQueryParameters);
	SendOptions.Insert("DataFormatToProcess", 1);
	SendOptions.Insert("ProxySettings"         , ProxyServerSettings);
	SendOptions.Insert("Timeout"                 , 30);
	
	SendingResult = OnlineUserSupport.DownloadContentFromInternet(
		URLOperations,
		,
		,
		SendOptions);
	
	If Not IsBlankString(SendingResult.ErrorCode) Then
		
		Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при получении информации о доступном обновлении.
				|%1';
				|en = 'An error occurred while getting available update information.
				|%1';"),
			SendingResult.ErrorInfo);
		WriteErrorToEventLog(Result.ErrorInfo);
		
		Result.ErrorName = SendingResult.ErrorCode;
		Result.Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить информацию о доступном обновлении.
				|%1';
				|en = 'Cannot get available update information.
				|%1';"),
			SendingResult.ErrorMessage);
		
		Return;
		
	EndIf;
	
	// Process the response.
	Try
		FillInformationOnUpdateFromInfoResonseFromJSON(Result, SendingResult.Content);
	Except
		
		ErrorInfo = ErrorInfo();
		
		Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось проверить наличие обновлений программы.
				|Ошибка при обработке ответа сервиса.
				|Некорректный ответ сервиса.
				|%1
				|Тело ответа: %2';
				|en = 'Cannot check the application updates.
				|An error occurred while processing the service response.
				|Incorrect service response.
				|%1
				|Response body: %2';"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo),
			Left(SendingResult.Content, 1024));
		WriteErrorToEventLog(Result.ErrorInfo);
		
		Result.ErrorName = "InvalidServiceResponse";
		Result.Message =
			NStr("ru = 'Не удалось проверить наличие обновлений программы.
				|Некорректный ответ сервиса.';
				|en = 'Cannot check the application updates.
				|Incorrect service response.';");
		
		Return;
		
	EndTry;
	
	If Not IsBlankString(Result.ErrorName) Then
		
		WriteErrorToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось проверить наличие обновлений программы.
				|
				|Сервис сообщил об ошибке.
				|
				|Ответ сервиса: %1';
				|en = 'Cannot check the application updates.
				|
				|The service reported an error.
				|
				|Service response: %1';"),
			Left(SendingResult.Content, 1024)));
		
		Return;
		
	EndIf;
	
	WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Получена информация о доступном обновлении.
				|%1';
				|en = 'Information about the available update is received.
				|%1';"),
			SendingResult.Content));
	
	If ConfigurationUpdateComponent <> Undefined Then
		ConfigurationUpdateComponent.UpdateAvailable =
			Not IsBlankString(ConfigurationUpdateComponent.Version);
	EndIf;
	
	// 1C:Enterprise installation recommendation level:
	// 0 - Mandatory
	// 1 - Recommended
	// 2 - Available
	CurPlatformVersion = OnlineUserSupport.Current1CPlatformVersion();
	If PlatformUpdate <> Undefined
		And Not IsBlankString(PlatformUpdate.Version) Then
		
		PlatformUpdate.UpdateAvailable =
			(CommonClientServer.CompareVersions(
				CurPlatformVersion,
				PlatformUpdate.Version) < 0);
		
		If ConfigurationUpdateComponent <> Undefined
			And Not IsBlankString(ConfigurationUpdateComponent.Version)
			And Not IsBlankString(ConfigurationUpdateComponent.MinPlatformVersion) Then
			
			If CommonClientServer.CompareVersions(
				CurPlatformVersion,
				ConfigurationUpdateComponent.MinPlatformVersion) < 0 Then
				PlatformUpdate.InstallationRequired = 0;
			EndIf;
			
		EndIf;
		
		If PlatformUpdate.InstallationRequired > 0 Then
			// If "0 - required" is not set above.
			
			If PlatformUpdate.UpdateRecommended Then
				PlatformUpdate.InstallationRequired = 1;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	// Populate the availability of add-in updates for the additional versions
	For Each AdditionalVersion In Result.AdditionalVersions Do
		
		If AdditionalVersion.Configuration <> Undefined Then
			AdditionalVersion.Configuration.UpdateAvailable =
				Not IsBlankString(AdditionalVersion.Configuration.Version);
		EndIf;
		
		If AdditionalVersion.Platform <> Undefined
			And Not IsBlankString(AdditionalVersion.Platform.Version) Then
			
			AdditionalVersion.Platform.UpdateAvailable =
				(CommonClientServer.CompareVersions(
					CurPlatformVersion,
					AdditionalVersion.Platform.Version) < 0);
			
			If AdditionalVersion.Configuration <> Undefined
				And Not IsBlankString(AdditionalVersion.Configuration.Version)
				And Not IsBlankString(AdditionalVersion.Configuration.MinPlatformVersion) Then
				
				If CommonClientServer.CompareVersions(
					CurPlatformVersion,
					AdditionalVersion.Configuration.MinPlatformVersion) < 0 Then
					AdditionalVersion.Platform.InstallationRequired = 0;
				EndIf;
				
			EndIf;
			
			If AdditionalVersion.Platform.InstallationRequired > 0 Then
				// If "0 - required" is not set above.
				
				If AdditionalVersion.Platform.UpdateRecommended Then
					AdditionalVersion.Platform.InstallationRequired = 1;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// The details of the object containing configuration update information.
//
// Returns:
//  Structure:
//    * Version - String
//    * MinPlatformVersion - String
//    * FilesToDownload - Array of String - A list of IDs of patch files to be downloaded.
//    * UpdateSize - Number - The size of all the files, in bytes.
//    * URLNewInVersion - String
//    * URLOrderOfUpdate - String
//    * VersionID - String - The GUID of the current configuration version.
//        Intended for identifying the initial version in an update chain in the Update Service.
//    * UpdateAvailable - Boolean - If True, a new configuration version is available for download and installation.
//    * EndOfSupport - Undefined - Long-term support is discontinued for the current version.
//                         - Date - The date when support for the current version will be discontinued.
//
Function NewInformationOnAvailableConfigurationUpdate()
	
	Result = New Structure;
	Result.Insert("Version"                    , "");
	Result.Insert("MinPlatformVersion", "");
	Result.Insert("FilesToDownload"          , New Array);
	Result.Insert("UpdateSize"          , 0);
	Result.Insert("URLNewInVersion"           , "");
	Result.Insert("URLOrderOfUpdate"      , "");
	Result.Insert("VersionID"       , "");
	Result.Insert("UpdateAvailable"        , False);
	Result.Insert("EndOfSupport"        , Undefined);
	
	Return Result;
	
EndFunction

Function NewPatchesInformation()
	
	Result = New ValueTable;
	
	StringType = New TypeDescription("String");
	BooleanType = New TypeDescription("Boolean");
	
	Result.Columns.Add("Id"               , New TypeDescription("UUID"));
	Result.Columns.Add("Description"                , StringType);
	Result.Columns.Add("ApplicationName"                , StringType);
	Result.Columns.Add("ApplicationVersion"             , StringType);
	Result.Columns.Add("LongDesc"                    , StringType);
	Result.Columns.Add("ChangedMetadataDetails", StringType);
	Result.Columns.Add("Revoked1"                    , BooleanType);
	Result.Columns.Add("ForNewVersion"              , BooleanType);
	Result.Columns.Add("ForCurrentVersion"            , BooleanType);
	Result.Columns.Add("Size"                      , New TypeDescription("Number"));
	Result.Columns.Add("Applicability");
	
	Return Result;
	
EndFunction

Function NewPatchInformationForApplicationInterface()
	
	Result = New Structure;
	
	Result.Insert("Id", Undefined);
	Result.Insert("Description"                , "");
	Result.Insert("ApplicationName"                , "");
	Result.Insert("ApplicationVersion"             , "");
	Result.Insert("LongDesc"                    , "");
	Result.Insert("ChangedMetadataDetails", "");
	Result.Insert("Size"                      , 0);
	
	Return Result;
	
EndFunction

Function NewValueTablePatchApplicability()
	
	Result = New ValueTable;
	
	StringType = New TypeDescription("String");
	Result.Columns.Add("ApplicationName", StringType);
	Result.Columns.Add("ApplicationVersion", StringType);
	
	Return Result;
	
EndFunction

// The details of the object containing 1C:Enterprise update information.
//
// Returns:
//  Structure:
//    * Version - String
//    * FileID - String
//    * UpdateSize - Number - The size of the file to download, in bytes.
//    * URLTransitionFeatures - String
//    * PlatformPageURL - String
//    * UpdateRecommended - Boolean - If True, the 1C:Enterprise update is recommended.
//    * UpdateAvailable - Boolean
//    * InstallationRequired - Number - The 1C:Enterprise update importance. Valid values are::
//        "0" - The update is mandatory to run the new configuration version.
//        "1" - The update is recommended to run the new configuration version.
//        "2" - The update is not required to run the new configuration version.
//
Function NewInformationOnAvailablePlatformUpdate()
	
	Result = New Structure;
	Result.Insert("Version"                 , "");
	Result.Insert("FileID"     , "");
	Result.Insert("UpdateSize"       , 0);
	Result.Insert("URLTransitionFeatures" , "");
	Result.Insert("PlatformPageURL"   , "");
	Result.Insert("UpdateRecommended"   , False);
	Result.Insert("UpdateAvailable"     , False);
	Result.Insert("InstallationRequired", 2);
	
	Return Result;
	
EndFunction

Function InfoRequestJSON(OperationParametersList, AdditionalRequestParameters)
	
	// {
	//  programName: String,
	//  versionNumber: String,
	//  platformVersion: String,
	//  programNewName: String,
	//  redactionNumber: String,
	//  updateType: NewConfigurationAndOrPlatform / NewProgramOrRedaction / NewPlatform,
	//  additionalParameters: [
	//    {
	//      key: String,
	//      value: String
	//    }
	//  ]
	// }
	
	MessageDataWriter = New JSONWriter;
	MessageDataWriter.SetString();
	MessageDataWriter.WriteStartObject();
	
	MessageDataWriter.WritePropertyName("programName");
	MessageDataWriter.WriteValue(String(OperationParametersList.CurrentApplicationName));
	MessageDataWriter.WritePropertyName("versionNumber");
	MessageDataWriter.WriteValue(OperationParametersList.CurrentApplicationVersion);
	MessageDataWriter.WritePropertyName("platformVersion");
	MessageDataWriter.WriteValue(OnlineUserSupport.Current1CPlatformVersion());
	MessageDataWriter.WritePropertyName("programNewName");
	MessageDataWriter.WriteValue(OperationParametersList.NewApplicationName);
	MessageDataWriter.WritePropertyName("redactionNumber");
	MessageDataWriter.WriteValue(OperationParametersList.NewApplicationEditionNumber);
	
	If OperationParametersList.UpdateScenario = "ApplicationUpdate1" Then
		ScenarioNameInService = "NewConfigurationAndOrPlatform";
	ElsIf OperationParametersList.UpdateScenario = "MigrationToAnotherApplicationOrRevision" Then
		ScenarioNameInService = "NewProgramOrRedaction";
	Else
		ScenarioNameInService = "NewPlatform";
	EndIf;
	
	MessageDataWriter.WritePropertyName("updateType");
	MessageDataWriter.WriteValue(ScenarioNameInService);
	
	WriteAdditionalQueryParameters(AdditionalRequestParameters, MessageDataWriter);
	
	MessageDataWriter.WriteEndObject();
	
	Return MessageDataWriter.Close();
	
EndFunction

Procedure FillInformationOnUpdateFromInfoResonseFromJSON(Result, JSONBody)
	
	ReadResponse = New JSONReader;
	ReadResponse.SetString(JSONBody);
	
	CurrentLevel = 0;
	While ReadingJSONRead(ReadResponse, CurrentLevel) Do
		
		If ReadResponse.CurrentValueType = JSONValueType.PropertyName And CurrentLevel = 1 Then
			
			PropertyName = ReadResponse.CurrentValue;
			If PropertyName = "errorName" Then
				
				Result.ErrorName = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				
			ElsIf PropertyName = "errorMessage" Then
				
				Result.ErrorInfo = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				Result.Message          = Result.ErrorInfo;
				
			ElsIf PropertyName = "configurationUpdateResponse" Then
				
				FillInformationOnConfigurationUpdateFromJSON(Result, ReadResponse, CurrentLevel, 2);
				
			ElsIf PropertyName = "platformUpdateResponse" Then
				
				FillInformationOnPlatformUpdateFromJSON(Result, ReadResponse, CurrentLevel, 2);
				
			ElsIf PropertyName = "additionalReleaseUpdate" Then
				
				PopulateInfoAboutUpdatesAdditionalVersionsFromJSON(Result, ReadResponse, CurrentLevel);
				
			ElsIf PropertyName = "currentReleaseSupportEndDate" Then
				
				DateAsString = JSONPropertyValue(ReadResponse, CurrentLevel);
				If DateAsString <> Undefined Then
					Result.EndOfCurrentVersionSupport = ReadJSONDate(DateAsString, JSONDateFormat.ISO);
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ReadResponse.Close();
	
EndProcedure

Procedure FillInformationOnConfigurationUpdateFromJSON(Result, ReadResponse, CurrentLevel, ObjectLevel)
	
	ReadingJSONRead(ReadResponse, CurrentLevel);
	
	If ReadResponse.CurrentValueType <> JSONValueType.ObjectStart Then
		Return;
	EndIf;
	
	ComConfUpdate = Result.Configuration;
	If ComConfUpdate = Undefined Then
		// Skip if the configuration update isn't required.
		// It is managed by the service and intended for an additional check.
		While ReadingJSONRead(ReadResponse, CurrentLevel) Do
			If ReadResponse.CurrentValueType = JSONValueType.ОbjectEnd Then
				Return;
			EndIf;
		EndDo;
	EndIf;
	
	While ReadingJSONRead(ReadResponse, CurrentLevel) Do
		
		If ReadResponse.CurrentValueType = JSONValueType.ОbjectEnd Then
			
			Return;
			
		ElsIf ReadResponse.CurrentValueType = JSONValueType.PropertyName
			And CurrentLevel = ObjectLevel Then
			
			PropertyName = ReadResponse.CurrentValue;
			If PropertyName = "configurationVersion" Then
				ComConfUpdate.Version = JSONPropertyValue(ReadResponse, CurrentLevel, "");
			ElsIf PropertyName = "size" Then
				ComConfUpdate.UpdateSize = JSONPropertyValue(ReadResponse, CurrentLevel, 0);
			ElsIf PropertyName = "platformVersion" Then
				ComConfUpdate.MinPlatformVersion = JSONPropertyValue(ReadResponse, CurrentLevel, "");
			ElsIf PropertyName = "updateInfoUrl" Then
				ComConfUpdate.URLNewInVersion = JSONPropertyValue(ReadResponse, CurrentLevel, "");
			ElsIf PropertyName = "howToUpdateInfoUrl" Then
				ComConfUpdate.URLOrderOfUpdate = JSONPropertyValue(ReadResponse, CurrentLevel, "");
			ElsIf PropertyName = "programVersionUin" Then
				ComConfUpdate.VersionID = JSONPropertyValue(ReadResponse, CurrentLevel, "");
			ElsIf PropertyName = "supportEndDate" Then
				
				DateAsString = JSONPropertyValue(ReadResponse, CurrentLevel);
				If DateAsString <> Undefined Then
					ComConfUpdate.EndOfSupport = ReadJSONDate(DateAsString, JSONDateFormat.ISO);
				EndIf;
				
			ElsIf PropertyName = "upgradeSequence" Then
				
				ReadingJSONRead(ReadResponse, CurrentLevel);
				If ReadResponse.CurrentValueType = JSONValueType.ArrayStart Then
					While ReadingJSONRead(ReadResponse, CurrentLevel) Do
						If ReadResponse.CurrentValueType = JSONValueType.ArrayEnd Then
							Break;
						ElsIf ReadResponse.CurrentValueType = JSONValueType.String Then
							ComConfUpdate.FilesToDownload.Add(ReadResponse.CurrentValue);
						EndIf;
					EndDo;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillInformationOnPlatformUpdateFromJSON(Result, ReadResponse, CurrentLevel, ObjectLevel)
	
	PlComUpdate = Result.Platform;
	If PlComUpdate = Undefined Then
		// Skip if 1C:Enterprise does not require an update.
		While ReadingJSONRead(ReadResponse, CurrentLevel) Do
			If ReadResponse.CurrentValueType = JSONValueType.ОbjectEnd Then
				Return;
			EndIf;
		EndDo;
	EndIf;
	
	ReadingJSONRead(ReadResponse, CurrentLevel);
	If ReadResponse.CurrentValueType <> JSONValueType.ObjectStart Then
		Return;
	EndIf;
	
	While ReadingJSONRead(ReadResponse, CurrentLevel) Do
		
		If ReadResponse.CurrentValueType = JSONValueType.ОbjectEnd Then
			
			Return;
			
		ElsIf ReadResponse.CurrentValueType = JSONValueType.PropertyName
			And CurrentLevel = ObjectLevel Then
			
			PropertyName = ReadResponse.CurrentValue;
			If PropertyName = "platformVersion" Then
				PlComUpdate.Version = JSONPropertyValue(ReadResponse, CurrentLevel, "");
			ElsIf PropertyName = "transitionInfoUrl" Then
				PlComUpdate.URLTransitionFeatures = JSONPropertyValue(ReadResponse, CurrentLevel, "");
			ElsIf PropertyName = "releaseUrl" Then
				PlComUpdate.PlatformPageURL = JSONPropertyValue(ReadResponse, CurrentLevel, "");
			ElsIf PropertyName = "distributionUin" Then
				PlComUpdate.FileID = JSONPropertyValue(ReadResponse, CurrentLevel, "");
			ElsIf PropertyName = "size" Then
				PlComUpdate.UpdateSize = JSONPropertyValue(ReadResponse, CurrentLevel, 0);
			ElsIf PropertyName = "recommended" Then
				PlComUpdate.UpdateRecommended = JSONPropertyValue(ReadResponse, CurrentLevel, False);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure PopulateInfoAboutUpdatesAdditionalVersionsFromJSON(Result, ReadResponse, CurrentLevel)
	
	ReadingJSONRead(ReadResponse, CurrentLevel);
	If ReadResponse.CurrentValueType <> JSONValueType.ArrayStart Then
		Return;
	EndIf;
	
	AdditionalVersions = Result.AdditionalVersions;
	While ReadingJSONRead(ReadResponse, CurrentLevel) Do
		If ReadResponse.CurrentValueType = JSONValueType.ArrayEnd Then
			Break;
		ElsIf ReadResponse.CurrentValueType = JSONValueType.ObjectStart Then
			
			ConfigurationAdditionalVersion = ?(
				Result.Configuration = Undefined,
				Undefined,
				NewInformationOnAvailableConfigurationUpdate());
			Additional1CEnterpriseVersion = ?(
				Result.Platform = Undefined,
				Undefined,
				NewInformationOnAvailablePlatformUpdate());
			
			AdditionalVersion = New Structure();
			AdditionalVersion.Insert("Configuration", ConfigurationAdditionalVersion);
			AdditionalVersion.Insert("Platform"   , Additional1CEnterpriseVersion);
			
			AdditionalVersions.Add(AdditionalVersion);
			
		ElsIf ReadResponse.CurrentValueType = JSONValueType.PropertyName Then
			
			If ReadResponse.CurrentValue = "configurationUpdate" Then
				FillInformationOnConfigurationUpdateFromJSON(
					AdditionalVersion,
					ReadResponse,
					CurrentLevel,
					3);
			ElsIf ReadResponse.CurrentValue = "platformUpdate" Then
				FillInformationOnPlatformUpdateFromJSON(AdditionalVersion, ReadResponse, CurrentLevel, 3);
			EndIf;
			
		EndIf;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Get update files.

// Returns information about update files for getting files in scenarios of the "Application update" wizard.
//
// Parameters:
//  ConfigurationUpdate - See NewInformationOnAvailableConfigurationUpdate
//  PatchesIDs - Array of String
//  PlatformUpdate - See NewInformationOnAvailablePlatformUpdate
//  Login - String - Username of an online support user.
//  Password - String - Password of an online support user.
//
// Returns:
//  Structure:
//    * ErrorName - String - An error ID.
//    * Message - String - Brief error details.
//    * ErrorInfo - String - detailed error description.
//    * ConfigurationUpdates - Array of Structure - Information on new configurations.
//    * Corrections - Array of Structure - Information on new patches.
//    * PlatformVersion - String - The new 1C:Enterprise version.
//    * PlatformUpdateFileURL - String - The address of the 1C:Enterprise distribution package.
//    * PlatformUpdateSize - Number - The size of all the patch files, in bytes.
//
Function UpdateFilesDetails(
	ConfigurationUpdate,
	PatchesIDs,
	PlatformUpdate,
	Login,
	Password) Export
	
	Result = New Structure;
	Result.Insert("ErrorName"             , "");
	Result.Insert("Message"             , "");
	Result.Insert("ErrorInfo"    , "");
	Result.Insert("ConfigurationUpdates", New Array);
	Result.Insert("Corrections"           , New Array);
	Result.Insert("PlatformUpdateFileURL", "");
	Result.Insert("PlatformUpdateSize"  , 0);
	
	If PlatformUpdate <> Undefined Then
		Result.Insert("PlatformVersion"          , PlatformUpdate.Version);
		Result.Insert("PlatformUpdateSize", PlatformUpdate.UpdateSize);
	Else
		Result.Insert("PlatformVersion"          , "");
		Result.Insert("PlatformUpdateSize", 0);
	EndIf;
	
	ConnectionSetup = OnlineUserSupport.ServersConnectionSettings();
	
	// Check service availability.
	PingOperationURL = PingOperationURL(ConnectionSetup.OUSServersDomain);
	CheckResult = OnlineUserSupport.CheckURLAvailable(PingOperationURL);
	
	If Not IsBlankString(CheckResult.ErrorName) Then
		Result.ErrorName = CheckResult.ErrorName;
		Result.Message = CheckResult.ErrorMessage;
		Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить информацию о файлах обновления.
				|Не удалось проверить доступность сервиса автоматического обновления программы: %1.
				|Причина:
				|%2';
				|en = 'Cannot get update file information.
				|Cannot check availability of automatic application update service: %1.
				|Reason:
				|%2';"),
			PingOperationURL,
			CheckResult.ErrorInfo);
		WriteErrorToEventLog(Result.ErrorInfo);
		Return Result;
	EndIf;
	
	If ConfigurationUpdate <> Undefined Or PlatformUpdate <> Undefined Then
		GetConfigurationAndPlatformUpdateFilesDetails(
			Result,
			ConfigurationUpdate,
			PlatformUpdate,
			Login,
			Password,
			ConnectionSetup);
		If Not IsBlankString(Result.ErrorName) Then
			Return Result;
		EndIf;
	EndIf;
	
	If PatchesIDs <> Undefined And PatchesIDs.Count() > 0 Then
		PatchesFilesResult = PatchesFilesDetails(
			PatchesIDs,
			New Structure("Login, Password", Login, Password),
			False);
		If Not IsBlankString(PatchesFilesResult.ErrorName) Then
			FillPropertyValues(Result, PatchesFilesResult, "ErrorName, Message, ErrorInfo");
			Return Result;
		EndIf;
		
		Result.Corrections = PatchesFilesResult.Corrections;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure GetConfigurationAndPlatformUpdateFilesDetails(
	Result,
	ConfigurationUpdate,
	PlatformUpdate,
	Login,
	Password,
	ConnectionSetup)
	
	URLOperations = UpdatesFilesOperationsURL(ConnectionSetup.OUSServersDomain);
	AdditionalRequestParameters_ = AdditionalParametersOfQueryToUpdatesService();
	
	// Log the query.
	WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Получение информации о файлах обновления конфигурации и Платформы (%1).';
				|en = 'Getting the information on configuration and Platform update files (%1).';"),
			URLOperations)
		+ Chars.LF
		+ StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Логин: %1
				|Обновление конфигурации:
				|%2;
				|Обновление платформы: %3;
				|Дополнительные параметры:
				|%5';
				|en = 'Username: %1
				|Configuration update:
				|%2;
				|Platform update:%3;
				|Additional parameters:
				|%5';"),
			Login,
			?(ConfigurationUpdate = Undefined,
				"-",
				StrConcat(ConfigurationUpdate.FilesToDownload, Chars.LF)),
			?(PlatformUpdate = Undefined,
				"-",
				PlatformUpdate.FileID),
			AdditionalQueryParametersPresentation(AdditionalRequestParameters_)));
	
	JSONQueryParameters = UpdateRequestJSON(
		ConfigurationUpdate,
		PlatformUpdate,
		Login,
		Password,
		AdditionalRequestParameters_);
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/json");
	
	SendOptions = New Structure;
	SendOptions.Insert("Method"                   , "POST");
	SendOptions.Insert("AnswerFormat"            , 1);
	SendOptions.Insert("Headers"               , Headers);
	SendOptions.Insert("DataForProcessing"      , JSONQueryParameters);
	SendOptions.Insert("DataFormatToProcess", 1);
	SendOptions.Insert("Timeout"                 , 30);
	
	SendingResult = OnlineUserSupport.DownloadContentFromInternet(
		URLOperations,
		,
		,
		SendOptions);
	
	If Not IsBlankString(SendingResult.ErrorCode) Then
		
		Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при получении информации о файлах обновления.
				|%1';
				|en = 'An error occurred while receiving information on update files.
				|%1';"),
			SendingResult.ErrorInfo);
		WriteErrorToEventLog(Result.ErrorInfo);
		
		Result.ErrorName = SendingResult.ErrorCode;
		Result.Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить информацию о файлах обновления.
				|%1';
				|en = 'Cannot get update file information.
				|%1';"),
			SendingResult.ErrorMessage);
		
		Return;
		
	EndIf;
	
	// Process the response.
	Try
		FillInformationOnUpdateFilesFromUpdateResonseJSON(Result, SendingResult.Content);
	Except
		
		ErrorInfo = ErrorInfo();
		
		Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить информацию об обновлении программы.
				|Ошибка при обработке ответа сервиса.
				|Некорректный ответ сервиса.
				|%1
				|Тело ответа: %2';
				|en = 'Cannot get the application update information.
				|An error occurred while processing the service response.
				|Incorrect service response.
				|%1
				|Response body: %2';"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo),
			Left(SendingResult.Content, 1024));
		WriteErrorToEventLog(Result.ErrorInfo);
		
		Result.ErrorName = "InvalidServiceResponse";
		Result.Message =
			NStr("ru = 'Не удалось получить информацию об обновлении программы.
				|Некорректный ответ сервиса.';
				|en = 'Cannot get the application update information.
				|Incorrect service response.';");
		
		Return;
		
	EndTry;
	
	If Not IsBlankString(Result.ErrorName) Then
		
		WriteErrorToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить информацию об обновлении программы.
				|
				|Сервис сообщил об ошибке.
				|
				|Ответ сервиса: %1';
				|en = 'Cannot get the application update information.
				|
				|The service reported an error.
				|
				|Service response: %1';"),
			Left(SendingResult.Content, 1024)));
		
		Return;
		
	EndIf;
	
	WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Получена информация о файлах обновления конфигурации и Платформы.
				|%1';
				|en = 'Information about configuration and platform update files is received.
				|%1';"),
			SendingResult.Content));
	
	// Check returned data.
	If ConfigurationUpdate <> Undefined Then
		If ConfigurationUpdate.FilesToDownload.Count() <> Result.ConfigurationUpdates.Count() Then
			Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Возвращена неполная информация об обновлении конфигурации.
					|Не совпадает количество запрошенных и возвращенных файлов (%1 и %2).';
					|en = 'Incomplete information about the configuration update is returned.
					|The number of requested files and returned files does not match (%1 and %2).';"),
				ConfigurationUpdate.FilesToDownload.Count(),
				Result.ConfigurationUpdates.Count());
			WriteErrorToEventLog(Result.ErrorInfo);
			
			Result.ErrorName = "InvalidServiceResponse";
			Result.Message =
				NStr("ru = 'Не удалось получить информацию об обновлении программы.
					|Некорректный ответ сервиса.';
					|en = 'Cannot get the application update information.
					|Incorrect service response.';");
		EndIf;
	EndIf;
	
EndProcedure

Function UpdateRequestJSON(
	ConfUpdate,
	PlUpdate,
	Login,
	Password,
	AdditionalRequestParameters)
	
	MessageDataWriter = New JSONWriter;
	MessageDataWriter.SetString();
	MessageDataWriter.WriteStartObject();
	
	MessageDataWriter.WritePropertyName("upgradeSequence");
	If ConfUpdate = Undefined Then
		MessageDataWriter.WriteValue(Undefined);
	Else
		MessageDataWriter.WriteStartArray();
		For Each CurID In ConfUpdate.FilesToDownload Do
			MessageDataWriter.WriteValue(CurID);
		EndDo;
		MessageDataWriter.WriteEndArray();
	EndIf;
	
	MessageDataWriter.WritePropertyName("programVersionUin");
	If ConfUpdate = Undefined Then
		MessageDataWriter.WriteValue(Undefined);
	Else
		MessageDataWriter.WriteValue(ConfUpdate.VersionID);
	EndIf;
	
	MessageDataWriter.WritePropertyName("platformDistributionUin");
	If PlUpdate = Undefined Then
		MessageDataWriter.WriteValue(Undefined);
	Else
		MessageDataWriter.WriteValue(PlUpdate.FileID);
	EndIf;
	
	MessageDataWriter.WritePropertyName("login");
	MessageDataWriter.WriteValue(Login);
	
	MessageDataWriter.WritePropertyName("password");
	MessageDataWriter.WriteValue(Password);
	
	WriteAdditionalQueryParameters(AdditionalRequestParameters, MessageDataWriter);
	
	MessageDataWriter.WriteEndObject();
	
	Return MessageDataWriter.Close();
	
EndFunction

Procedure FillInformationOnUpdateFilesFromUpdateResonseJSON(Result, JSONBody)
	
	ReadResponse = New JSONReader;
	ReadResponse.SetString(JSONBody);
	
	CurrentLevel = 0;
	While ReadingJSONRead(ReadResponse, CurrentLevel) Do
		
		If ReadResponse.CurrentValueType = JSONValueType.PropertyName And CurrentLevel = 1 Then
			
			PropertyName = ReadResponse.CurrentValue;
			If PropertyName = "errorName" Then
				
				Result.ErrorName = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				
			ElsIf PropertyName = "errorMessage" Then
				
				Result.ErrorInfo = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				Result.Message          = Result.ErrorInfo;
				
			ElsIf PropertyName = "platformDistributionUrl" And CurrentLevel = 1 Then
				
				Result.PlatformUpdateFileURL = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				
			ElsIf PropertyName = "configurationUpdateDataList" Then
				
				FillInformationOnConfigurationUpdateFilesFromJSON(Result, ReadResponse, CurrentLevel);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ReadResponse.Close();
	
EndProcedure

Procedure FillInformationOnConfigurationUpdateFilesFromJSON(Result, ReadResponse, CurrentLevel)
	
	ReadingJSONRead(ReadResponse, CurrentLevel);
	If ReadResponse.CurrentValueType <> JSONValueType.ArrayStart Then
		Return;
	EndIf;
	
	While ReadingJSONRead(ReadResponse, CurrentLevel) Do
		
		If ReadResponse.CurrentValueType = JSONValueType.ArrayEnd Then
			Return;
			
		ElsIf ReadResponse.CurrentValueType = JSONValueType.ObjectStart And CurrentLevel = 2 Then
			
			templatePath = "";
			executeUpdateProcess = False;
			updateFileUrl = "";
			updateFileName = "";
			updateFileFormat = "";
			size = 0;
			hashSum = "";
			
		ElsIf ReadResponse.CurrentValueType = JSONValueType.ОbjectEnd And CurrentLevel = 1 Then
			
			Result.ConfigurationUpdates.Add(
				NewConfigurationUpdate(
					updateFileUrl,
					templatePath,
					updateFileName,
					executeUpdateProcess,
					updateFileFormat,
					size,
					hashSum));
			
		ElsIf ReadResponse.CurrentValueType = JSONValueType.PropertyName And CurrentLevel = 2 Then
			
			PropertyName = ReadResponse.CurrentValue;
			
			If PropertyName = "templatePath" Then
				templatePath = JSONPropertyValue(ReadResponse, CurrentLevel, "");
			ElsIf PropertyName = "executeUpdateProcess" Then
				executeUpdateProcess = JSONPropertyValue(ReadResponse, CurrentLevel, False);
			ElsIf PropertyName = "updateFileUrl" Then
				updateFileUrl = JSONPropertyValue(ReadResponse, CurrentLevel, "");
			ElsIf PropertyName = "updateFileName" Then
				updateFileName = JSONPropertyValue(ReadResponse, CurrentLevel, "");
			ElsIf PropertyName = "updateFileFormat" Then
				updateFileFormat = JSONPropertyValue(ReadResponse, CurrentLevel, "");
			ElsIf PropertyName = "size" Then
				size = JSONPropertyValue(ReadResponse, CurrentLevel, 0);
			ElsIf PropertyName = "hashSum" Then
				hashSum = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function NewConfigurationUpdate(
	UpdateFileURL,
	TemplatesSubdirectory,
	RelativeCFUFilePath,
	ApplyUpdateHandlers,
	UpdateFileFormat,
	FileSize,
	Checksum)
	
	Result = New Structure;
	Result.Insert("UpdateFileURL"            , UpdateFileURL);
	Result.Insert("TemplatesSubdirectory"            , TemplatesSubdirectory);
	Result.Insert("RelativeCFUFilePath"     , RelativeCFUFilePath);
	Result.Insert("ApplyUpdateHandlers", ApplyUpdateHandlers);
	Result.Insert("UpdateFileFormat"         , Lower(UpdateFileFormat));
	Result.Insert("FileSize"                   , FileSize);
	Result.Insert("Checksum"              , Checksum);
	Result.Insert("CfuSubdirectory"                 , FileDirectoryFromFullName(RelativeCFUFilePath));
	
	If Right(Upper(Result.RelativeCFUFilePath), 4) <> ".CFU" Then
		Result.RelativeCFUFilePath = Result.RelativeCFUFilePath + ".cfu";
	EndIf;
	
	If Right(Result.TemplatesSubdirectory, 1) <> "\" Then
		Result.TemplatesSubdirectory = Result.TemplatesSubdirectory + "\";
	EndIf;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Information about available patches for subsystems.

Function PatchInfoRequestJSON(OperationParametersList, AdditionalRequestParameters)
	
	MessageDataWriter = New JSONWriter;
	MessageDataWriter.SetString();
	MessageDataWriter.WriteStartObject();
	
	MessageDataWriter.WritePropertyName("programVersionList");
	MessageDataWriter.WriteStartArray();
	For Each SubsystemVersion In OperationParametersList.ConfigurationsVersions Do
		MessageDataWriter.WriteStartObject();
		MessageDataWriter.WritePropertyName("programName");
		MessageDataWriter.WriteValue(SubsystemVersion.ApplicationName);
		MessageDataWriter.WritePropertyName("versionNumber");
		MessageDataWriter.WriteValue(SubsystemVersion.Version);
		MessageDataWriter.WriteEndObject();
	EndDo;
	MessageDataWriter.WriteEndArray();
	
	MessageDataWriter.WritePropertyName("installedPatchesList");
	MessageDataWriter.WriteStartArray();
	For Each PatchID In OperationParametersList.InstalledPatchesIDs Do
		MessageDataWriter.WriteValue(String(PatchID));
	EndDo;
	MessageDataWriter.WriteEndArray();
	
	WriteAdditionalQueryParameters(AdditionalRequestParameters, MessageDataWriter);
	
	MessageDataWriter.WriteEndObject();
	
	Return MessageDataWriter.Close();
	
EndFunction

Function InformationOnAvailableConfigurationsPatches(
	ConfigurationsVersions,
	InstalledPatchesIDs,
	CheckServiceAvailability = True)
	
	Result = New Structure;
	Result.Insert("Error"                 , False);
	Result.Insert("BriefErrorDetails"  , "");
	Result.Insert("DetailedErrorDetails", "");
	Result.Insert("Corrections"            , NewPatchesInformation());
	
	ConnectionSetup = OnlineUserSupport.ServersConnectionSettings();
	
	// Check service availability.
	If CheckServiceAvailability Then
		PingOperationURL = PingOperationURL(ConnectionSetup.OUSServersDomain);
		CheckResult = OnlineUserSupport.CheckURLAvailable(PingOperationURL);
		If Not IsBlankString(CheckResult.ErrorName) Then
			Result.Error                  = True;
			Result.BriefErrorDetails   = CheckResult.ErrorMessage;
			Result.DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить информацию о доступных исправлениях (патчах) конфигураций.
					|Не удалось проверить доступность сервиса автоматического обновления программы: %1.
					|Причина:
					|%2';
					|en = 'Cannot get information on available configuration patches.
					|Cannot check availability of automatic application update service: %1.
					|Reason:
					|%2';"),
				PingOperationURL,
				CheckResult.ErrorInfo);
			WriteErrorToEventLog(Result.DetailedErrorDetails);
			Return Result;
		EndIf;
	EndIf;
	
	// Call a service operation.
	URLOperations = AvailablePatchesOperationsURL(ConnectionSetup.OUSServersDomain);
	
	OperationParametersList = New Structure;
	OperationParametersList.Insert("ConfigurationsVersions"                    , ConfigurationsVersions);
	OperationParametersList.Insert("InstalledPatchesIDs", InstalledPatchesIDs);
	
	AdditionalRequestParameters_ = AdditionalParametersOfQueryToUpdatesService();
	
	// Log the query.
	WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Получение информации об исправлениях (патчах) конфигураций (%1).';
				|en = 'Getting information on configuration patches (%1).';"),
			URLOperations)
		+ Chars.LF
		+ StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Версии подсистем:
				|%1;
				|ИдентификаторыУстановленныхИсправлений:
				|%2;
				|Дополнительные параметры:
				|%3';
				|en = 'Subsystem versions:
				|%1;
				|InstalledPatchesIDs:
				|%2;
				|Additional parameters:
				|%3';"),
			ConfigurationsListPresentation(ConfigurationsVersions),
			StrConcat(InstalledPatchesIDs, Chars.LF),
			AdditionalQueryParametersPresentation(AdditionalRequestParameters_)));
	
	JSONQueryParameters = PatchInfoRequestJSON(OperationParametersList, AdditionalRequestParameters_);
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/json");
	SendOptions = New Structure;
	SendOptions.Insert("Method"                   , "POST");
	SendOptions.Insert("AnswerFormat"            , 1);
	SendOptions.Insert("Headers"               , Headers);
	SendOptions.Insert("DataForProcessing"      , JSONQueryParameters);
	SendOptions.Insert("DataFormatToProcess", 1);
	SendOptions.Insert("Timeout"                 , 30);
	SendingResult = OnlineUserSupport.DownloadContentFromInternet(
		URLOperations,
		,
		,
		SendOptions);
	
	If Not IsBlankString(SendingResult.ErrorCode) Then
		
		Result.Error = True;
		Result.DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при получении информации о доступных исправлениях (патчах) конфигураций.
				|%1';
				|en = 'An error occurred while receiving information about available configuration patches.
				|%1';"),
			SendingResult.ErrorInfo);
		WriteErrorToEventLog(Result.DetailedErrorDetails);
		
		Result.BriefErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить информацию о доступных исправлениях (патчах) конфигураций.
				|%1';
				|en = 'Cannot get information on available configuration patches.
				|%1';"),
			SendingResult.ErrorMessage);
		
		Return Result;
		
	EndIf;
	
	// Process the response.
	Try
		FillInformationOnUpdateFromPatchInfoResonseFromJSON(Result, SendingResult.Content);
	Except
		
		Result.Error = True;
		
		ErrorInfo = ErrorInfo();
		
		Result.DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось проверить наличие исправлений (патчей) конфигураций.
				|Ошибка при обработке ответа сервиса.
				|Некорректный ответ сервиса.
				|%1
				|Тело ответа: %2';
				|en = 'Cannot check the existence of configuration patches.
				|An error occurred while processing the service response.
				|Incorrect service response.
				|%1
				|Response body: %2';"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo),
			Left(SendingResult.Content, 1024));
		WriteErrorToEventLog(Result.DetailedErrorDetails);
		Result.BriefErrorDetails =
			NStr("ru = 'Не удалось проверить наличие исправлений (патчей) конфигураций.
				|Некорректный ответ сервиса.';
				|en = 'Cannot check the existence of configuration patches.
				|Incorrect service response.';");
		
		Return Result;
		
	EndTry;
	
	If Result.Error Then
		
		WriteErrorToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось проверить наличие исправлений (патчей) конфигураций.
				|
				|Сервис сообщил об ошибке.
				|
				|Ответ сервиса: %1';
				|en = 'Cannot check the existence of configuration patches.
				|
				|The service reported an error.
				|
				|Service response: %1';"),
			Left(SendingResult.Content, 1024)));
		
		Return Result;
		
	EndIf;
	
	WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Получена информация о доступных исправлениях (патчах) конфигураций.
				|%1';
				|en = 'Information on available configuration patches is received.
				|%1';"),
			SendingResult.Content));
	
	Return Result;
	
EndFunction

Function ConfigurationsListPresentation(SubsystemsList)
	
	Result = New Array;
	
	For Each CurSubsystemDetails In SubsystemsList Do
		Result.Add(
			Chars.Tab
			+ StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1: %2';
					|en = '%1: %2';"),
				CurSubsystemDetails.ApplicationName,
				CurSubsystemDetails.Version));
	EndDo;
	
	Return StrConcat(Result, Chars.LF);
	
EndFunction

Procedure FillInformationOnUpdateFromPatchInfoResonseFromJSON(Result, JSONBody)
	
	ReadResponse = New JSONReader;
	ReadResponse.SetString(JSONBody);
	
	CurrentLevel = 0;
	While ReadingJSONRead(ReadResponse, CurrentLevel) Do
		
		If ReadResponse.CurrentValueType = JSONValueType.PropertyName And CurrentLevel = 1 Then
			
			PropertyName = ReadResponse.CurrentValue;
			If PropertyName = "errorName" Then
				
				ErrorName = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				If Not IsBlankString(ErrorName) Then
					Result.Error = True;
				EndIf;
				
			ElsIf PropertyName = "errorMessage" Then
				
				Result.BriefErrorDetails   = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				Result.DetailedErrorDetails = Result.BriefErrorDetails;
				
			ElsIf PropertyName = "patchUpdateList" Then
				
				FillInformationOnParentConfigurationsPatchesFromJSON(Result, ReadResponse, CurrentLevel);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ReadResponse.Close();
	
EndProcedure

Procedure FillInformationOnParentConfigurationsPatchesFromJSON(Result, ReadResponse, CurrentLevel)
	
	ReadingJSONRead(ReadResponse, CurrentLevel);
	If ReadResponse.CurrentValueType <> JSONValueType.ArrayStart Then
		Return;
	EndIf;
	
	Corrections = Result.Corrections;
	If Corrections = Undefined Then
		// Skip if no patches should be uploaded.
		// It is managed by the service and intended for an additional check.
		While ReadingJSONRead(ReadResponse, CurrentLevel) Do
			If ReadResponse.CurrentValueType = JSONValueType.ArrayEnd Then
				Return;
			EndIf;
		EndDo;
	EndIf;
	
	PatchData = Undefined;
	While ReadingJSONRead(ReadResponse, CurrentLevel) Do
		
		If ReadResponse.CurrentValueType = JSONValueType.ArrayEnd Then
			
			Return;
			
		ElsIf ReadResponse.CurrentValueType = JSONValueType.ObjectStart Then
			
			PatchData = Result.Corrections.Add();
			PatchData.Applicability = NewValueTablePatchApplicability();
			
		ElsIf ReadResponse.CurrentValueType = JSONValueType.PropertyName And CurrentLevel = 2 Then
			
			PropertyName = ReadResponse.CurrentValue;
			If PropertyName = "ueid" Then
				
				PropertyValue = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				Try
					PatchData.Id = New UUID(PropertyValue);
				Except
					ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Некорректный идентификатор исправления в patchUpdateList[].ueid (%1)';
							|en = 'Incorrect patch ID in patchUpdateList[].uin (%1)';"),
						PropertyValue);
					Raise ExceptionText;
				EndTry;
				
			ElsIf PropertyName = "name" Then
				PatchData.Description = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				
			ElsIf PropertyName = "description" Then
				PatchData.LongDesc = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				
			ElsIf PropertyName = "modificatedMetadata" Then
				PatchData.ChangedMetadataDetails  = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				
			ElsIf PropertyName = "status" Then
				PatchData.Revoked1 = (JSONPropertyValue(ReadResponse, CurrentLevel, "") = "revocation");
				
			ElsIf PropertyName = "size" Then
				PatchData.Size = JSONPropertyValue(ReadResponse, CurrentLevel, 0);
				
			ElsIf PropertyName = "applyToVersion" Then
				
				ReadingJSONRead(ReadResponse, CurrentLevel);
				If ReadResponse.CurrentValueType = JSONValueType.ArrayStart Then
					While ReadingJSONRead(ReadResponse, CurrentLevel) Do
						If ReadResponse.CurrentValueType = JSONValueType.ObjectStart And CurrentLevel = 3 Then
							ApplicabilityString = PatchData.Applicability.Add();
						ElsIf ReadResponse.CurrentValueType = JSONValueType.PropertyName And CurrentLevel = 3 Then
							If ReadResponse.CurrentValue = "programName" Then
								ApplicabilityString.ApplicationName = JSONPropertyValue(ReadResponse, CurrentLevel, "");
							ElsIf ReadResponse.CurrentValue = "versionNumber" Then
								ApplicabilityString.ApplicationVersion = JSONPropertyValue(ReadResponse, CurrentLevel, "");
							EndIf;
						ElsIf ReadResponse.CurrentValueType = JSONValueType.ArrayEnd Then
							Break;
						EndIf;
					EndDo;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Getting patch files in scenarios of call from the API.

Function PatchesFilesDetails(
	PatchesIDs,
	AuthenticationData,
	CheckServiceAvailability)
	
	ConnectionSetup = OnlineUserSupport.ServersConnectionSettings();
	
	Result = New Structure;
	Result.Insert("ErrorName"         , "");
	Result.Insert("Message"         , "");
	Result.Insert("ErrorInfo", "");
	Result.Insert("Corrections"       , New Array);
	
	// Check service availability.
	If CheckServiceAvailability Then
		PingOperationURL = PingOperationURL(ConnectionSetup.OUSServersDomain);
		CheckResult = OnlineUserSupport.CheckURLAvailable(PingOperationURL);
		If Not IsBlankString(CheckResult.ErrorName) Then
			Result.ErrorName = CheckResult.ErrorName;
			Result.Message = CheckResult.ErrorMessage;
			Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить информацию о файлах исправлений (патчах).
					|Не удалось проверить доступность сервиса автоматического обновления программы: %1.
					|Причина:
					|%2';
					|en = 'Cannot get patch file information.
					|Cannot check availability of automatic application update service: %1.
					|Reason:
					|%2';"),
				PingOperationURL,
				CheckResult.ErrorInfo);
			WriteErrorToEventLog(Result.ErrorInfo);
			Return Result;
		EndIf;
	EndIf;
	
	// Call a service operation.
	URLOperations = PatchesFilesOperationsURL(ConnectionSetup.OUSServersDomain);
	AdditionalRequestParameters_ = AdditionalParametersOfQueryToUpdatesService();
	
	// Log the query.
	WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Получение информации о файлах исправлений (патчей) (%1).';
				|en = 'Getting the information about patch files (%1).';"),
			URLOperations)
		+ Chars.LF
		+ StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Логин:
				|%1;
				|Идентификаторы исправлений:
				|%2;
				|Дополнительные параметры:
				|%3';
				|en = 'Username:
				|%1;
				|Patch IDs:
				|%2;
				|Additional parameters:
				|%3';"),
			AuthenticationData.Login,
			StrConcat(PatchesIDs, Chars.LF),
			AdditionalQueryParametersPresentation(AdditionalRequestParameters_)));
	
	JSONQueryParameters = GetPatchFilesRequestJSON(
		PatchesIDs,
		AuthenticationData,
		AdditionalRequestParameters_);
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/json");
	
	SendOptions = New Structure;
	SendOptions.Insert("Method"                   , "POST");
	SendOptions.Insert("AnswerFormat"            , 1);
	SendOptions.Insert("Headers"               , Headers);
	SendOptions.Insert("DataForProcessing"      , JSONQueryParameters);
	SendOptions.Insert("DataFormatToProcess", 1);
	SendOptions.Insert("Timeout"                 , 30);
	
	SendingResult = OnlineUserSupport.DownloadContentFromInternet(
		URLOperations,
		,
		,
		SendOptions);
	
	If Not IsBlankString(SendingResult.ErrorCode) Then
		
		Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при получении информации о файлах исправлений (патчах).
				|%1';
				|en = 'An error occurred while receiving information about patch files.
				|%1';"),
			SendingResult.ErrorInfo);
		WriteErrorToEventLog(Result.ErrorInfo);
		
		Result.ErrorName = SendingResult.ErrorCode;
		Result.Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить информацию о файлах исправлений (патчах).
				|%1';
				|en = 'Cannot get patch file information.
				|%1';"),
			SendingResult.ErrorMessage);
		
		Return Result;
		
	EndIf;
	
	// Process the response.
	Try
		FillInformationOnPatchesFilesFromGetPacthFilesResonseJSON(Result, SendingResult.Content);
	Except
		
		ErrorInfo = ErrorInfo();
		
		Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить информацию о файлах исправлений (патчах).
				|Ошибка при обработке ответа сервиса.
				|Некорректный ответ сервиса.
				|%1
				|Тело ответа: %2';
				|en = 'Cannot get patch file information.
				|An error occurred while processing the service response.
				|Incorrect service response.
				|%1
				|Response body: %2';"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo),
			Left(SendingResult.Content, 1024));
		WriteErrorToEventLog(Result.ErrorInfo);
		
		Result.ErrorName = "InvalidServiceResponse";
		Result.Message =
			NStr("ru = 'Не удалось получить информацию о файлах исправлений (патчах).
				|Некорректный ответ сервиса.';
				|en = 'Cannot get patch file information.
				|Incorrect service response.';");
		
		Return Result;
		
	EndTry;
	
	If Not IsBlankString(Result.ErrorName) Then
		
		WriteErrorToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить информацию о файлах исправлений (патчах).
				|
				|Сервис сообщил об ошибке.
				|
				|Ответ сервиса: %1';
				|en = 'Cannot get patch file information.
				|
				|The service reported an error.
				|
				|Service response: %1';"),
			Left(SendingResult.Content, 1024)));
		
		Return Result;
		
	EndIf;
	
	WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Получена информация о файлах исправлений (патчах).
				|%1';
				|en = 'The information about patch files is received.
				|%1';"),
			SendingResult.Content));
	
	Return Result;
	
EndFunction

Function GetPatchFilesRequestJSON(
	PatchesIDs,
	AuthenticationData,
	AdditionalRequestParameters)
	
	MessageDataWriter = New JSONWriter;
	MessageDataWriter.SetString();
	MessageDataWriter.WriteStartObject();
	
	MessageDataWriter.WritePropertyName("patchUinList");
	MessageDataWriter.WriteStartArray();
	For Each Id In PatchesIDs Do
		MessageDataWriter.WriteValue(String(Id));
	EndDo;
	MessageDataWriter.WriteEndArray();
	
	MessageDataWriter.WritePropertyName("login");
	MessageDataWriter.WriteValue(AuthenticationData.Login);
	
	MessageDataWriter.WritePropertyName("password");
	MessageDataWriter.WriteValue(AuthenticationData.Password);
	
	WriteAdditionalQueryParameters(AdditionalRequestParameters, MessageDataWriter);
	
	MessageDataWriter.WriteEndObject();
	
	Return MessageDataWriter.Close();
	
EndFunction

Procedure FillInformationOnPatchesFilesFromGetPacthFilesResonseJSON(Result, JSONBody)
	
	ReadResponse = New JSONReader;
	ReadResponse.SetString(JSONBody);
	
	CurrentLevel = 0;
	While ReadingJSONRead(ReadResponse, CurrentLevel) Do
		
		If ReadResponse.CurrentValueType = JSONValueType.PropertyName And CurrentLevel = 1 Then
			
			PropertyName = ReadResponse.CurrentValue;
			If PropertyName = "errorName" Then
				
				Result.ErrorName = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				
			ElsIf PropertyName = "errorMessage" Then
				
				Result.ErrorInfo = JSONPropertyValue(ReadResponse, CurrentLevel, "");
				Result.Message          = Result.ErrorInfo;
				
			ElsIf PropertyName = "patchDistributionDataList" Then
				
				FillInformationOnPatchesFilesFromJSON(Result, ReadResponse, CurrentLevel);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ReadResponse.Close();
	
EndProcedure

Function InternalImportPatches(
	PatchesIDs,
	FormIdentifier = Undefined,
	CheckServiceAvailability = True)
	
	Result = New Structure;
	Result.Insert("Error"                 , False);
	Result.Insert("BriefErrorDetails"  , "");
	Result.Insert("DetailedErrorDetails", "");
	Result.Insert("Corrections"            , New Array);
	
	If Not Users.IsFullUser(, True, True) Then
		Result.Error = True;
		Result.BriefErrorDetails   = NStr("ru = 'Недостаточно прав.';
												|en = 'Insufficient rights.';");
		Result.DetailedErrorDetails = NStr("ru = 'Недостаточно прав для получения файлов исправлений (патчей).';
												|en = 'Insufficient rights to get patch files.';");
		WriteErrorToEventLog(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить файлы исправлений (патчей).
				|%1';
				|en = 'Cannot get patch files.
				|%1';"),
			Result.DetailedErrorDetails));
		Return Result;
	EndIf;
	
	SetPrivilegedMode(True);
	AuthenticationData =
		OnlineUserSupport.OnlineSupportUserAuthenticationData();
	SetPrivilegedMode(False);
	If AuthenticationData = Undefined Then
		Result.Error = True;
		Result.BriefErrorDetails   = NStr("ru = 'Интернет-поддержка пользователей не подключена.';
												|en = 'Online support is disabled.';");
		Result.DetailedErrorDetails = NStr("ru = 'Интернет-поддержка пользователей не подключена.';
												|en = 'Online support is disabled.';");
		WriteErrorToEventLog(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить файлы исправлений (патчей).
				|%1';
				|en = 'Cannot get patch files.
				|%1';"),
			Result.DetailedErrorDetails));
		Return Result;
	EndIf;
	
	FilesDetailsGetResult = PatchesFilesDetails(
		PatchesIDs,
		AuthenticationData,
		CheckServiceAvailability);
	If Not IsBlankString(FilesDetailsGetResult.ErrorName) Then
		Result.Error = True;
		Result.BriefErrorDetails   = FilesDetailsGetResult.Message;
		Result.DetailedErrorDetails = FilesDetailsGetResult.ErrorInfo;
		WriteErrorToEventLog(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить файлы исправлений (патчей).
				|%1';
				|en = 'Cannot get patch files.
				|%1';"),
			Result.DetailedErrorDetails));
		Return Result;
	EndIf;
	
	// Import patch files.
	For Each CurPatch In FilesDetailsGetResult.Corrections Do
		
		GetResult1 = ImportPatchFile(
			CurPatch.FileURL,
			CurPatch.Id,
			AuthenticationData);
		
		If GetResult1.Error Then
			
			Result.Error = True;
			Result.BriefErrorDetails =
				NStr("ru = 'Не удалось получить файл исправления (патча).';
					|en = 'Cannot get a patch file.';")
				+ Chars.LF
				+ GetResult1.BriefErrorDetails;
			Result.DetailedErrorDetails =
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось загрузить файл исправления (патча) с идентификатором %1.
						|%2';
						|en = 'Cannot import a patch file with ID %1.
						|%2';"),
					CurPatch.Id,
					GetResult1.DetailedErrorDetails);
			Return Result;
			
		Else
			
			PatchToDownload = NewPatchToDownload();
			PatchToDownload.Id = CurPatch.Id;
			PatchToDownload.FileAddress    = PutToTempStorage(
				GetResult1.Content,
				FormIdentifier);
			
			Result.Corrections.Add(PatchToDownload);
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Details of the patch object.
//
// Returns:
//  Structure:
//    * Id - UUID - The patch ID.
//    * FileAddress - String - The file address in the temporary storage.
//    * ReceivedFileName - String - The patch file path.
//
Function NewPatchToDownload()
	
	Result = New Structure();
	Result.Insert("Id"      , CommonClientServer.BlankUUID());
	Result.Insert("FileAddress"         , "");
	Result.Insert("ReceivedFileName", "");
	
	Return Result;
	
EndFunction

Function ImportPatchFile(FileURL, Id, AuthenticationData) Export
	
	OnlineUserSupport.CheckURL(FileURL);
	
	Result = New Structure;
	Result.Insert("Error"                 , False);
	Result.Insert("BriefErrorDetails"  , "");
	Result.Insert("DetailedErrorDetails", "");
	Result.Insert("Content"             , Undefined);
	
	WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Получение файла исправления (патча).
				|URL: %1;
				|Идентификатор: %2.';
				|en = 'Get a patch file.
				|URL:%1;
				|ID: %2.';"),
			FileURL,
			Id));
	
	RequestBody = GetPatchFileRequestJSON(AuthenticationData.Login, AuthenticationData.Password);
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/json");
	AddlParameters = New Structure;
	AddlParameters.Insert("Method"                   , "POST");
	AddlParameters.Insert("DataFormatToProcess", 1);
	AddlParameters.Insert("DataForProcessing"      , RequestBody);
	AddlParameters.Insert("AnswerFormat"            , 2);
	AddlParameters.Insert("Timeout"                 , 600);
	AddlParameters.Insert("Headers"               , Headers);
	
	GetResult1 = OnlineUserSupport.DownloadContentFromInternet(FileURL, , , AddlParameters);
	If Not IsBlankString(GetResult1.ErrorCode) Then
		Result.Error = True;
		Result.BriefErrorDetails =
			NStr("ru = 'Не удалось получить файл исправления (патча).';
				|en = 'Cannot get a patch file.';") + Chars.LF + GetResult1.ErrorMessage;
		Result.DetailedErrorDetails =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось загрузить файл исправления (патча) с идентификатором %1.
					|%2';
					|en = 'Cannot import a patch file with ID %1.
					|%2';"),
				Id,
				GetResult1.ErrorInfo);
		WriteErrorToEventLog(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить файл исправления (патча).
				|Идентификатор: %1;
				|URL: %2;
				|%3';
				|en = 'Cannot get a patch file
				|ID:%1;
				|URL: %2;
				|%3';"),
			Id,
			FileURL,
			Result.DetailedErrorDetails));
		Return Result;
	EndIf;
	
	Result.Content = GetResult1.Content;
	
	WriteInformationToEventLog(NStr("ru = 'Файл исправления (патча) успешно получен';
												|en = 'The patch file is received';"));
	
	Return Result;
	
EndFunction

Function GetPatchFileRequestJSON(Login, Password)
	
	MessageDataWriter = New JSONWriter;
	MessageDataWriter.SetString();
	MessageDataWriter.WriteStartObject();
	
	MessageDataWriter.WritePropertyName("login");
	MessageDataWriter.WriteValue(Login);
	
	MessageDataWriter.WritePropertyName("password");
	MessageDataWriter.WriteValue(Password);
	
	MessageDataWriter.WriteEndObject();
	
	Return MessageDataWriter.Close();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Automatic update setup.

Procedure SaveAvailableUpdateInformationInSettings(Val AvailableUpdateInformation)
	
	If TypeOf(AvailableUpdateInformation) = Type("Structure") Then
		
		AvailableUpdateInformationDetails = NewDetailsOfAvailableUpdateInfoToSave();
		AvailableUpdateInformationDetails.ApplicationName =
			OnlineUserSupport.InternalApplicationName();
		AvailableUpdateInformationDetails.MetadataName =
			OnlineUserSupport.ConfigurationName();
		AvailableUpdateInformationDetails.Metadata_Version =
			OnlineUserSupport.ConfigurationVersion();
		AvailableUpdateInformationDetails.PlatformVersion =
			OnlineUserSupport.Current1CPlatformVersion();
		AvailableUpdateInformationDetails.AvailableUpdateInformation = AvailableUpdateInformation;
		
		Common.CommonSettingsStorageSave(
			GetApplicationUpdatesClientServer.CommonSettingsID(),
			SettingKeyAvailableUpdateInfo(),
			AvailableUpdateInformationDetails);
		
	EndIf;
	
EndProcedure

// Returns a new object containing the saved information on the update.
//
// Returns:
//  Structure:
//    * ApplicationName - String
//    * MetadataName - String
//    * Metadata_Version - String
//    * PlatformVersion - String
//    * AvailableUpdateInformation - Undefined - The object is not initialized.
//                                     - See AvailableUpdateInformationInternal
//
Function NewDetailsOfAvailableUpdateInfoToSave()
	
	AvailableUpdateInformation = Undefined;	// See AvailableUpdateInformationInternal
	
	Result = New Structure();
	Result.Insert("ApplicationName"                  , "");
	Result.Insert("MetadataName"                 , "");
	Result.Insert("Metadata_Version"              , "");
	Result.Insert("PlatformVersion"               , "");
	Result.Insert("AvailableUpdateInformation", AvailableUpdateInformation);
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Information on the platform version for the current configuration version

Function Configuration1CEnterpriseVersionsInfo(ApplicationName, ApplicationVersion)
	
	Result = New Structure();
	Result.Insert("Error"                      , False);
	Result.Insert("BriefErrorDetails"       , "");
	Result.Insert("DetailedErrorDetails"     , "");
	Result.Insert("MinPlatformVersion"  , "");
	Result.Insert("RecommendedPlatformVersion", "");
	
	ConnectionSetup = OnlineUserSupport.ServersConnectionSettings();
	
	// Check service availability.
	PingOperationURL   = PingOperationURL(ConnectionSetup.OUSServersDomain);
	CheckResult = OnlineUserSupport.CheckURLAvailable(PingOperationURL);
	If Not IsBlankString(CheckResult.ErrorName) Then
		Result.Error                  = True;
		Result.BriefErrorDetails   = CheckResult.ErrorMessage;
		Result.DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось проверить доступность сервиса автоматического обновления программы: %1.
				|Причина:
				|%2';
				|en = 'Cannot check whether the automatic application update service is available: %1.
				|Reason:
				|%2';",
				Common.DefaultLanguageCode()),
			PingOperationURL,
			CheckResult.ErrorInfo);
		WriteErrorToEventLog(Result.DetailedErrorDetails);
		Return Result;
	EndIf;
	
	// Call a service operation.
	URLOperations = OperationURL1CEnterpriseVersionsInfo(ConnectionSetup.OUSServersDomain);
	
	QueryData = New Structure();
	QueryData.Insert("programName"  , ApplicationName);
	QueryData.Insert("versionNumber", ApplicationVersion);
	
	// Log the query.
	WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Получение информации о версиях платформы для текущей версии программы.
				|URL: %3
				|Имя программы: %1
				|Версия программы: %2';
				|en = 'Get the platform version information the current application version.
				|URL: %3
				|Application name: %1
				|Application version: %2';"),
			ApplicationName,
			ApplicationVersion,
			URLOperations));
	
	JSONWriter = New JSONWriter();
	JSONWriter.SetString();
	
	WriteJSON(JSONWriter, QueryData);
	
	ParametersJSONRequests = JSONWriter.Close();
	
	Headers = New Map();
	Headers.Insert("Content-Type", "application/json");
	
	QueryOptions = New Structure();
	QueryOptions.Insert("Method"                   , "POST");
	QueryOptions.Insert("AnswerFormat"            , 1);
	QueryOptions.Insert("Headers"               , Headers);
	QueryOptions.Insert("DataForProcessing"      , ParametersJSONRequests);
	QueryOptions.Insert("DataFormatToProcess", 1);
	QueryOptions.Insert("Timeout"                 , ConnectionSetup.ConnectionTimeout);
	
	ServiceResponse = OnlineUserSupport.DownloadContentFromInternet(
		URLOperations,
		,
		,
		QueryOptions);
	
	// Data is successfully obtained from the service.
	If ServiceResponse.StatusCode = 200 Then
		
		// Response body:
		// [
		//   {
		//     "platformVersionMin": "string",
		//     "platformVersionRecommended": "string"
		//   }
		// ]
		
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Получена информация о версиях платформы для текущей версии конфигурации.
					|%1';
					|en = 'The platform version information for the current configuration version is received.
					|%1';"),
				ServiceResponse.Content));
		
		Try
			
			ResponseData = JSONStringIntoValue(ServiceResponse.Content);	// Array of Structure
			
			MinPlatformVersion   = New Array();
			RecommendedPlatformVersion = New Array();
			
			For Each ResponseString In ResponseData Do
				MinPlatformVersion.Add(ResponseString.platformVersionMin);
				RecommendedPlatformVersion.Add(ResponseString.platformVersionRecommended);
			EndDo;
			
			Result.MinPlatformVersion   = StrConcat(MinPlatformVersion, ";");
			Result.RecommendedPlatformVersion = StrConcat(RecommendedPlatformVersion, ";");
			
		Except
			
			ErrorInfo = ErrorInfo();
			
			Result.Error                  = True;
			Result.BriefErrorDetails   =
				NStr("ru = 'Не удалось получить информацию о версиях платформы для текущей версии конфигурации.
					|Некорректный ответ сервиса.';
					|en = 'Cannot get the platform version information for the current configuration version.
					|Incorrect service response.';");
			Result.DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при получении информации о версиях платформы для текущей версии конфигурации.
					|Некорректный ответ сервиса.
					|%1
					|Ответ сервиса: %2';
					|en = 'An error occurred when getting the platform version information for the current configuration version.
					|Incorrect service response.
					|%1
					|Service response: %2';",
					Common.DefaultLanguageCode()),
				ErrorProcessing.DetailErrorDescription(ErrorInfo),
				ServiceResponse.Content);
			
		EndTry;
		
	ElsIf ServiceResponse.StatusCode = 404 Then
		
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить информацию о версиях платформы для текущей версии конфигурации по причине:
					|Не найдена имя и версия программы.
					|Имя программы: %1
					|Версия программы: %2';
					|en = 'Cannot get the platform version information for the current configuration version due to:
					|The application name and version were not found.
					|Application name: %1
					|Application version: %2';"),
				QueryData.programName,
				QueryData.versionNumber));
		
	ElsIf Not IsBlankString(ServiceResponse.ErrorCode) Then
		
		Result.Error                  = True;
		Result.BriefErrorDetails   = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить информацию о версиях платформы для текущей версии конфигурации.
				|%1';
				|en = 'Cannot get the platform version information for the current configuration version.
				|%1';"),
			ServiceResponse.ErrorMessage);
		Result.DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при получении информации о версиях платформы для текущей версии конфигурации.
				|%1
				|Ответ сервиса: %2';
				|en = 'An error occurred when getting the platform version information for the current configuration version.
				|%1
				|Service response: %2';",
				Common.DefaultLanguageCode()),
			ServiceResponse.ErrorInfo,
			ServiceResponse.Content);
		
	EndIf;
	
	If Result.Error Then
		WriteErrorToEventLog(Result.DetailedErrorDetails);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region OtherProceduresAndFunctions_

Procedure WriteErrorToEventLog(ErrorMessage) Export
	
	WriteLogEvent(
		GetApplicationUpdatesClientServer.EventLogEventName(Common.DefaultLanguageCode()),
		EventLogLevel.Error,
		,
		,
		Left(ErrorMessage, 5120));
	
EndProcedure

Procedure WriteInformationToEventLog(Message) Export
	
	WriteLogEvent(
		GetApplicationUpdatesClientServer.EventLogEventName(Common.DefaultLanguageCode()),
		EventLogLevel.Information,
		,
		,
		Left(Message, 5120));
	
EndProcedure

Function AdditionalParametersOfQueryToUpdatesService()
	
	Result = OnlineUserSupport.AdditionalParametersOfServiceOperationsCall();
	If GetApplicationUpdatesClientServer.Is64BitApplication() Then
		// Notify about supporting x64 platforms only if the configuration
		// can identify whether this is a 64-bit app.
		Result.Insert("platform64Supported", "true");
	EndIf;
	
	Return Result;
	
EndFunction

Procedure AddDisabledToDoItem(ToDoList, ToDoItemID, Sections)
	
	For Each Section In Sections Do
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = ToDoItemID;
		ToDoItem.HasToDoItems       = False;
		ToDoItem.Important         = False;
		ToDoItem.Presentation  = NStr("ru = 'Доступно обновление программы';
									|en = 'Application update is available';");
		ToDoItem.Form          = "DataProcessor.ApplicationUpdate.Form.Form";
		ToDoItem.Owner       = Section;
	EndDo;
	
EndProcedure

Function SuppliedPatchDataKind()
	
	Return "Patches";
	
EndFunction 

Procedure SetAScheduleForTheRoutineTaskOfDownloadingFixes()
	
	Job = ScheduledJobsServer.Job(
		Metadata.ScheduledJobs.GetAndInstallConfigurationTroubleshooting);
	
	// To mitigate the service load, the update time is picked randomly
	// from the following time periods:
	// - 0:00–6:00 a.m
	// -  11:00 a.m.—2:00 p.m.
	// - 4:00 p.m.–10 p.m.
	// - The job runs 3 times every day.
	// 
	
	Generator = New RandomNumberGenerator;
	ScheduleNight = New JobSchedule;
	ScheduleNight.BeginTime       = Date("00010101") + Generator.RandomNumber(0, 21600);
	ScheduleNight.DaysRepeatPeriod = 1;
	
	ScheduleDay = New JobSchedule;
	ScheduleDay.BeginTime       = Date("00010101") + 11 * 60 * 60 + Generator.RandomNumber(0, 1800);
	ScheduleDay.DaysRepeatPeriod = 1;
	
	EveningSchedule = New JobSchedule;
	EveningSchedule.BeginTime       = Date("00010101") + 16 * 60 * 60 + Generator.RandomNumber(0, 21600);
	EveningSchedule.DaysRepeatPeriod = 1;
	
	DetailedDailySchedules = New Array;
	DetailedDailySchedules.Add(ScheduleNight);
	DetailedDailySchedules.Add(ScheduleDay);
	DetailedDailySchedules.Add(EveningSchedule);
	Job.Schedule.DetailedDailySchedules = DetailedDailySchedules;
	Job.Schedule.DaysRepeatPeriod      = 1;
	
	Job.Write();
	
EndProcedure

// Returns the object resulting from the JSON string.
//
// Parameters:
//  JSONString - String
//
// Returns:
//  Arbitrary
//
Function JSONStringIntoValue(JSONString)
	
	JSONReader = New JSONReader();
	JSONReader.SetString(JSONString);
	
	Result = ReadJSON(JSONReader);
	
	JSONReader.Close();
	
	Return Result;
	
EndFunction

// Returns the ID of the setting key of the common storage containing the auto-update settings information.
// 
//
// Returns:
//  String
//
Function AutoUpdateSettingKey()
	
	Return "GetApplicationUpdates";
	
EndFunction

// Returns the ID of the setting key of the common storage containing the 1C:Enterprise versions information
// on the current configuration versions obtained from the service.
//
// Returns:
//  String
//
Function SettingKey1CEnterpriseVersionsInfo()
	
	Return "GetApplicationUpdates/InfoAbout1CEnterpriseVersions";
	
EndFunction

// Returns the ID of the setting key of the common storage containing the information
// on the current configuration version update.
//
// Returns:
//  String
//
Function SettingKeyAvailableUpdateInfo() Export
	
	Return "GetApplicationUpdates/AvailableUpdateInformation"
		+ ?(GetApplicationUpdatesClientServer.Is64BitApplication(),
			"64",
			"");
	
EndFunction

// Returns the ID of the setting key of the common storage containing the information
// on the directory where 1C:Enterprise distribution package is located.
//
// Returns:
//  String
//
Function SettingKeyDistributionPackageDirectory()
	
	Return "DistributionPackageDirectory";
	
EndFunction

// Returns the ID of the setting key of the common storage containing the information
// on the 1C:Enterprise version that should not trigger the non-recommended version warning.
//
// Returns:
//  String
//
Function SettingKeyMessageAboutNonRecommended1CEnterpriseVersion() Export
	
	Return "NotRecommendedPlatformVersionMessage";
	
EndFunction

#EndRegion

#Region UpdateHandlers

// Converts user settings of the
// "Get application updates" subsystem.
//
Procedure InfobaseUpdateUpdateUpdateDownloadSettings2181() Export
	
	If Common.DataSeparationEnabled() Then
		// Not used in SaaS mode.
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	// Move update check settings from
	// "StandardSubsystems.ConfigurationUpdate"
	// and convert the OSL settings.
	
	StructureType = Type("Structure");
	UsersList = InfoBaseUsers.GetUsers();
	For Each CurUser In UsersList Do
		
		UserName = CurUser.Name;
		
		OSLSettings = Common.CommonSettingsStorageLoad(
			GetApplicationUpdatesClientServer.CommonSettingsID(),
			AutoUpdateSettingKey(),
			,
			,
			UserName);
		
		// Search for and replace obsolete properties
		If TypeOf(OSLSettings) = StructureType Then
			OutdatedParameters = New Structure("AutoCheckMethod");
			FillPropertyValues(OutdatedParameters, OSLSettings);
			If OutdatedParameters.AutoCheckMethod <> Undefined Then
				OSLSettings.Insert("AutomaticCheckForProgramUpdates",
					OutdatedParameters.AutoCheckMethod);
				OSLSettings.Delete("AutoCheckMethod");
			EndIf;
		EndIf;
		
		SSLSettings = Common.CommonSettingsStorageLoad(
			"ConfigurationUpdate",
			"ConfigurationUpdateSettings",
			,
			,
			UserName);
		
		If TypeOf(SSLSettings) = StructureType Then
			
			OutdatedParameters = New Structure(
				"CheckForUpdatesOnStart,ScheduleForCheckingForUpdates");
			FillPropertyValues(OutdatedParameters, SSLSettings);
			
			If ValueIsFilled(OutdatedParameters.CheckForUpdatesOnStart) Then
				
				If TypeOf(OSLSettings) <> StructureType Then
					OSLSettings = NewAutoupdateSettings();
				EndIf;
				
				OSLSettings.AutomaticCheckForProgramUpdates =
					OutdatedParameters.CheckForUpdatesOnStart;
				OSLSettings.Schedule = OutdatedParameters.ScheduleForCheckingForUpdates;
				
			EndIf;
			
		EndIf;
		
		If TypeOf(OSLSettings) = StructureType Then
			// If the settings were changed, save the settings.
			Common.CommonSettingsStorageSave(
				GetApplicationUpdatesClientServer.CommonSettingsID(),
				AutoUpdateSettingKey(),
				OSLSettings,
				,
				UserName);
		EndIf;
		
	EndDo;
	
EndProcedure

// Updates the correction import schedule to the infobase.
//
// Parameters:
//  Parameters - Structure
//
Procedure UpdateThePatchDownloadSchedule(Parameters) Export
	
	WriteInformationToEventLog(
		NStr("ru = 'Обновление расписания загрузки исправлений (патчей).';
			|en = 'Update the patch import schedule.';"));
	
	SetAScheduleForTheRoutineTaskOfDownloadingFixes();
	
	WriteInformationToEventLog(
		NStr("ru = 'Обновление расписания загрузки исправлений (патчей).  Успешно завершено.';
			|en = 'Update the patch import schedule. Completed successfully.';"));
	
EndProcedure

// Enables automatic import of patches.
//
// Parameters:
//  Parameters - Structure
//
Procedure EnableAutomaticDownloadOfFixes(Parameters) Export
	
	WriteInformationToEventLog(
		NStr("ru = 'Установка настройки автоматической загрузки исправлений (патчей).';
			|en = 'Set up automatic patch import.';"));
	
	If AutomaticDownloadOfFixesIsAvailable() Then
		EnableDisableAutomaticPatchesInstallation(True);
	EndIf;
	
	WriteInformationToEventLog(
		NStr("ru = 'Установка настройки автоматической загрузки исправлений (патчей). Успешно завершено.';
			|en = 'Set up automatic patch import. Completed successfully.';"));
	
EndProcedure

// Update the schedule of the scheduled job to update the platform version information.
//
// Parameters:
//  Parameters - Structure
//
Procedure UpdateScheduleOn1CEnterpriseVersionsInfoUpdate(Parameters) Export
	
	WriteInformationToEventLog(
		NStr("ru = 'Обновление расписания регламентной операции по обновлению информации о версиях платформы.';
			|en = 'Update the schedule of the scheduled job to update the platform version information.';"));
	
	Job = ScheduledJobsServer.Job(
		Metadata.ScheduledJobs.Update1CEnterpriseVersionsInfo);
	
	// To mitigate the service load, the 1C:Enterprise version update time is picked randomly.
	// 
	
	Generator = New RandomNumberGenerator();
	
	Job.Schedule.BeginTime       = Date("00010101") + Generator.RandomNumber(0, 86399);
	Job.Schedule.DaysRepeatPeriod = 1;
	
	Job.Write();
	
	WriteInformationToEventLog(
		NStr("ru = 'Успешно обновлено расписание регламентной операции по обновлению информации о версиях платформы.';
			|en = 'The schedule of the scheduled job to update the platform version information is updated.';"));
	
EndProcedure

#EndRegion

#Region SSLToDoList

// Adds an app update item to the to-do list if the subsystem is available,
// the user has the view right, and an app update is available.
//
// Parameters:
//  ToDoList - See OnFillToDoList.ToDoList.
//
Procedure PopulateToDoListAppUpdate(ToDoList)
	
	If Not CanUseApplicationUpdate() Then
		Return;
	EndIf;
	
	// If autoupdate is disabled, the settings might store outdated information on the available update.
	// 
	SettingsOfUpdate = AutoupdateSettings();
	If SettingsOfUpdate.AutomaticCheckForProgramUpdates = 0 Then
		Return;
	EndIf;
	
	ToDoItemID = "ApplicationUpdate";
	
	// The procedure call requires the StandardSubsystems.ToDoList subsystem.
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If ModuleToDoListServer.UserTaskDisabled(ToDoItemID) Then
		Return;
	EndIf;
	
	Subsystem = Metadata.Subsystems.Find("Administration");
	If Subsystem = Undefined
		Or Not AccessRight("View", Subsystem)
		Or Not Common.MetadataObjectAvailableByFunctionalOptions(Subsystem) Then
		Sections = ModuleToDoListServer.SectionsForObject(Metadata.DataProcessors.ApplicationUpdate.FullName());
	Else
		Sections = CommonClientServer.ValueInArray(Subsystem);
	EndIf;
	
	If Sections.Count() > 0 Then
		
		AvailableUpdateInformation = AvailableUpdateInformationInSettings();
		NotificationParameters = AvailableUpdateNotificationParameters(AvailableUpdateInformation, True);
		
		If NotificationParameters = Undefined Then
			AddDisabledToDoItem(ToDoList, ToDoItemID, Sections);
			Return;
		EndIf;
		
		For Each Section In Sections Do
			
			ToDoItem = ToDoList.Add();
			ToDoItem.Id = ToDoItemID;
			ToDoItem.HasToDoItems      = True;
			ToDoItem.Important        = NotificationParameters.Important;
			ToDoItem.Presentation = NotificationParameters.Text;
			ToDoItem.Form         = "DataProcessor.ApplicationUpdate.Form.Form";
			ToDoItem.Owner      = Section;
			
			If NotificationParameters.RecommendedToInstall Then
				ToDoItemRecommendedToInstall = ToDoList.Add();
				ToDoItemRecommendedToInstall.Id  = "RecommendationInstallApplicationUpdates";
				ToDoItemRecommendedToInstall.HasToDoItems       = True;
				ToDoItemRecommendedToInstall.Presentation  = NStr("ru = 'Рекомендуется установить это обновление.';
																	|en = 'We recommend that you install this update.';");
				ToDoItemRecommendedToInstall.Owner       = ToDoItemID;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Adds an auto-import activation and patch installation item to the to-do list
// if auto-import is available and the flag is disabled.
//
// Parameters:
//  ToDoList - See OnFillToDoList.ToDoList.
//
Procedure PopulateToDoListForPatchAutoDownload(ToDoList)
	
	ImportSettings = PatchesDownloadSettings();
	If ImportSettings.DisableNotifications Then
		Return;
	EndIf;
	
	AccessParameters = ParametersOfAccessToAppUpdate();
	If Not AccessParameters.IsSubsystemAvailable
		Or Not AutomaticDownloadOfFixesIsAvailable() Then
		Return;
	EndIf;
	
	ToDoItemID = "EnablePatchAutoDownload";
	
	// The procedure call requires the StandardSubsystems.ToDoList subsystem.
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If ModuleToDoListServer.UserTaskDisabled(ToDoItemID) Then
		Return;
	EndIf;
	
	Subsystem = Metadata.Subsystems.Find("Administration");
	If Subsystem = Undefined
		Or Not AccessRight("View", Subsystem)
		Or Not Common.MetadataObjectAvailableByFunctionalOptions(Subsystem) Then
		Sections = ModuleToDoListServer.SectionsForObject(Metadata.DataProcessors.ApplicationUpdate.FullName());
	Else
		Sections = CommonClientServer.ValueInArray(Subsystem);
	EndIf;
	
	If Sections.Count() > 0 Then
		
		DateOfInforming = Common.CommonSettingsStorageLoad(
			GetApplicationUpdatesClientServer.CommonSettingsID(),
			GetApplicationUpdatesClientServer.SettingKeyPatchDownloadEnablementNotificationDate(),
			'00010101');
		HasToDoItems           = Not AutomaticPatchesImportEnabled()
			And DateOfInforming <= CurrentSessionDate();
		
		For Each Section In Sections Do
			
			ToDoItem = ToDoList.Add();
			ToDoItem.Id  = ToDoItemID;
			ToDoItem.HasToDoItems       = HasToDoItems;
			ToDoItem.Important         = True;
			ToDoItem.Owner       = Section;
			ToDoItem.Presentation  = NStr("ru = 'Автоматическая установка исправлений';
										|en = 'Install patches automatically';");
			ToDoItem.Form          = "DataProcessor.ApplicationUpdate.Form.PatchesDownloadSetting";
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
