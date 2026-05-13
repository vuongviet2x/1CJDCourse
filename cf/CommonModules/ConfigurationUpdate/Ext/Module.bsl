///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// Uninstalls obsolete patches and sets correct properties to new patches.
// It must be called before starting a batch update of the configuration
// . (See InfobaseUpdate.UpdateInfobase)
// NOTE: The changes will apply after a session restart.
//
// Parameters:
//  IsCheckOnly - Boolean - if True, obsolete patches will not be deleted.
//
// Returns:
//  Structure:
//   * HasChanges     - Boolean - True if patches include changes.
//   * ChangesDetails - String - information on deleted and changed patches.
//
Function PatchesChanged(IsCheckOnly = False) Export
	
	Result = New Structure;
	Result.Insert("HasChanges", False);
	Result.Insert("ChangesDetails", "");
	
	If Common.IsSubordinateDIBNode() Then
		// In a subordinate node, patches are changed when synchronizing.
		Return Result;
	EndIf;
	
	PatchesChanged = False;
	
	// A version check is required for newly attached extensions.
	Corrections = New Array;
	Extensions = ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionApplied);
	For Each Extension In Extensions Do
		If IsPatch(Extension) Then
			Corrections.Add(Extension);
		EndIf;
	EndDo;
	
	Changes = New Structure;
	Changes.Insert("DeletedPatches", New Array);
	Changes.Insert("ProtectionDisabled", New Array);
	Changes.Insert("SafeModeDisabled", New Array);
	Changes.Insert("InactivePatches", New Array);
	
	If Corrections.Count() > 0 Then
		
		MessageText = NStr("ru = 'В составе конфигурации обнаружены установленные исправления (%1).
			|Начало проверки необходимости удаления устаревших патчей.';
			|en = 'Installed patches are found (%1).
			|Clearing up obsolete patches…';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, Corrections.Count());
		WriteLogEvent(EventLogEvent(), EventLogLevel.Information,,, MessageText);
		
		SubsystemsDetails = StandardSubsystemsCached.SubsystemsDetails();
		
		ConfigurationLibraries = New Map;
		For Each Subsystem In SubsystemsDetails.ByNames Do
			ConfigurationLibraries.Insert(Subsystem.Key, Subsystem.Value.Version);
		EndDo;
		
		For Each Patch In Corrections Do
			DeletePatch = True;
			PatchProperties = PatchProperties(Patch.Name);
			
			IsLibraryPatch = False;
			LibraryName     = "";
			ListOfAssemblies = Undefined;
			If PatchProperties = Undefined Then
				// The patch is not applied yet.
				DeletePatch = False;
			ElsIf PatchProperties = "ReadingError" Then
				DeletePatch = True;
			Else
				MessageText = NStr("ru = 'Проверка исправления ""%1"".';
										|en = 'Checking patch ""%1""…';");
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, Patch.Name);
				WriteLogEvent(EventLogEvent(), EventLogLevel.Information,,, MessageText);
				
				For Each ApplicabilityInformation In PatchProperties.AppliedFor Do
					ConfigurationLibraryVersion = ConfigurationLibraries.Get(ApplicabilityInformation.ConfigurationName);
					If ConfigurationLibraryVersion = Undefined Then
						Continue;
					EndIf;
					If ApplicabilityInformation.ConfigurationName <> Metadata.Name Then
						IsLibraryPatch = True;
						LibraryName     = ApplicabilityInformation.ConfigurationName;
						LibraryVersion  = ConfigurationLibraryVersion;
					EndIf;
					
					ArrayOfAssemblies = StrSplit(TrimAll(ApplicabilityInformation.Versions), ",", False);
					ListOfAssemblies = New ValueList;
					For Each Assembly In ArrayOfAssemblies Do
						Assembly = TrimAll(Assembly);
						Try
							VersionWeight = VersionWeightFromStringArray(StrSplit(Assembly, ".", False));
						Except
							// The list contains a build with an invalid number. Skip it.
							VersionWeight = Undefined;
						EndTry;
						If VersionWeight = Undefined Then
							Continue;
						EndIf;
						ListOfAssemblies.Add(VersionWeight, Assembly);
					EndDo;
					ListOfAssemblies.SortByValue();
					NumberOfBuilds = ListOfAssemblies.Count();
					If NumberOfBuilds = 0 Then
						Continue;
					EndIf;
					
					FirstBuild = ListOfAssemblies[0].Presentation;
					LatestBuild = ListOfAssemblies[NumberOfBuilds - 1].Presentation;
					If CommonClientServer.CompareVersions(ConfigurationLibraryVersion, FirstBuild) >= 0
						And CommonClientServer.CompareVersions(LatestBuild, ConfigurationLibraryVersion) >= 0 Then
						DeletePatch = False;
					EndIf;
				EndDo;
			EndIf;
			
			If IsCheckOnly And DeletePatch Then
				Result.HasChanges = True;
				Return Result;
			EndIf;
			
			If DeletePatch Then
				BuildsListAsString = "";
				If ListOfAssemblies <> Undefined Then
					Builds = New Array;
					For Each Item In ListOfAssemblies Do
						Builds.Add(Item.Presentation);
					EndDo;
					BuildsListAsString = StrConcat(Builds, ", ");
					
					If IsLibraryPatch Then
						MessageText = NStr("ru = 'Исправление ""%1"" устарело и будет удалено.
							|Исправление предназначено для сборок ""%2"" библиотеки ""%3"". Текущая версия библиотеки: ""%4"".';
							|en = 'The ""%1"" patch is outdated and will be deleted.
							|You can use the patch for the ""%2"" builds of the ""%3"" library. Current library version: ""%4"".';");
					Else
						LibraryVersion = Metadata.Version;
						MessageText = NStr("ru = 'Исправление ""%1"" устарело и будет удалено.
							|Исправление предназначено для сборок ""%2"". Текущая версия конфигурации: ""%4"".';
							|en = 'The ""%1"" patch is outdated and will be deleted.
							|You can use the patch for the ""%2"" builds. Current configuration version: ""%4"".';");
					EndIf;
				Else
					MessageText = NStr("ru = 'Исправление ""%1"" устарело и будет удалено.';
											|en = 'Patch ""%1"" is obsolete and will be deleted.';");
				EndIf;
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
					Patch.Name,
					BuildsListAsString,
					LibraryName,
					LibraryVersion);
				WriteLogEvent(NStr("ru = 'Исправления.Удаление';
												|en = 'Patch.Delete';", Common.DefaultLanguageCode()),
					EventLogLevel.Information, , , MessageText);
				
				Try
					Patch.Delete();
					Changes.DeletedPatches.Add(Patch.Name);
					PatchesChanged = True;
				Except
					ErrorInfo = ErrorInfo();
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Не удалось удалить исправление ""%1"" по причине:
						           |
						           |%2';
									|en = 'Cannot delete patch ""%1."" Reason:
									|
									|%2';"), Patch.Name, ErrorProcessing.BriefErrorDescription(ErrorInfo));
					WriteLogEvent(NStr("ru = 'Исправления.Удаление';
													|en = 'Patch.Delete';", Common.DefaultLanguageCode()),
						EventLogLevel.Error,,, ErrorText);
					Raise ErrorText;
				EndTry;
			Else
				WritingRequired = False;
				UnsafeActionProtection = Common.ProtectionWithoutWarningsDetails();
				If Patch.UnsafeActionProtection.UnsafeOperationWarnings
						<> UnsafeActionProtection.UnsafeOperationWarnings Then
					Patch.UnsafeActionProtection = UnsafeActionProtection;
					WritingRequired = True;
					Changes.ProtectionDisabled.Add(Patch.Name);
				EndIf;
				If Patch.SafeMode <> False Then
					Patch.SafeMode = False ;
					WritingRequired = True;
					Changes.SafeModeDisabled.Add(Patch.Name);
				EndIf;
				
				If WritingRequired Then
					Try
						Patch.Write();
						PatchesChanged = True;
					Except
						ErrorInfo = ErrorInfo();
						ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Не удалось применить исправление ""%1"" по причине:
							           |
							           |%2';
										|en = 'Cannot apply the ""%1"" patch due to:
										|
										|%2';"), Patch.Name, ErrorProcessing.BriefErrorDescription(ErrorInfo));
						WriteLogEvent(NStr("ru = 'Исправления.Изменение';
														|en = 'Patch.Modify';", Common.DefaultLanguageCode()),
							EventLogLevel.Error,,, ErrorText);
						Raise ErrorText;
					EndTry;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Deleting patches that are not attached without checking their versions.
	Extensions = ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionDisabled);
	For Each Extension In Extensions Do
		If IsPatch(Extension) Then
			Try
				Extension.Delete();
				
				MessageText = NStr("ru = 'Удалено отключенное исправление: ""%1"".';
										|en = 'Disabled patch deleted: ""%1"".';");
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, Extension.Name);
				WriteLogEvent(NStr("ru = 'Исправления.Удаление';
												|en = 'Patch.Delete';", Common.DefaultLanguageCode()),
					EventLogLevel.Information, , , MessageText);
				
				Changes.InactivePatches.Add(Extension.Name);
				PatchesChanged = True;
			Except
				ErrorInfo = ErrorInfo();
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось удалить отключенное исправление ""%1"" по причине:
					           |
					           |%2';
								|en = 'Cannot delete disabled patch ""%1."" Reason:
								|
								|%2';"), Extension.Name, ErrorProcessing.BriefErrorDescription(ErrorInfo));
				WriteLogEvent(NStr("ru = 'Исправления.Удаление';
												|en = 'Patch.Delete';", Common.DefaultLanguageCode()),
					EventLogLevel.Error,,, ErrorText);
				Raise ErrorText;
			EndTry;
		EndIf;
	EndDo;
	
	If Changes.DeletedPatches.Count() > 0 Then
		CorrectionsLeft = Corrections.Count() - Changes.DeletedPatches.Count();
		MessageText = NStr("ru = 'Удаление устаревших патчей завершено.
			|Удалено: %1
			|Осталось действующих патчей: %2';
			|en = 'Patch clean up has completed.
			|Obsolete patches deleted: %1.
			|Patches remained: %2.';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageText,
			Changes.DeletedPatches.Count(),
			CorrectionsLeft);
		WriteLogEvent(EventLogEvent(), EventLogLevel.Information,,, MessageText);
	EndIf;
	
	ChangesDetails = "";
	
	If Changes.DeletedPatches.Count() > 0 Then
		Title = NStr("ru = 'Удалены устаревшие патчи';
						|en = 'Obsolete patches deleted';");
		ChangesDetails = Title + ":" + Chars.LF + StrConcat(Changes.DeletedPatches, Chars.LF);
	EndIf;
	If Changes.InactivePatches.Count() > 0 Then
		Title = NStr("ru = 'Удалены отключенные патчи';
						|en = 'Disabled patches are deleted';");
		If ValueIsFilled(ChangesDetails) Then
			ChangesDetails = ChangesDetails + Chars.LF + Chars.LF;
		EndIf;
		ChangesDetails = ChangesDetails + Title + ":" + Chars.LF + StrConcat(Changes.InactivePatches, Chars.LF);
	EndIf;
	If Changes.ProtectionDisabled.Count() > 0 Then
		Title = NStr("ru = 'Отключены предупреждения об опасных действиях';
						|en = 'Unsafe operation warning disabled';");
		If ValueIsFilled(ChangesDetails) Then
			ChangesDetails = ChangesDetails + Chars.LF + Chars.LF;
		EndIf;
		ChangesDetails = ChangesDetails + Title + ":" + Chars.LF + StrConcat(Changes.ProtectionDisabled, Chars.LF);
	EndIf;
	If Changes.SafeModeDisabled.Count() > 0 Then
		Title = NStr("ru = 'Отключен безопасный режим';
						|en = 'Safe mode disabled';");
		If ValueIsFilled(ChangesDetails) Then
			ChangesDetails = ChangesDetails + Chars.LF + Chars.LF;
		EndIf;
		ChangesDetails = ChangesDetails + Title + ":" + Chars.LF + StrConcat(Changes.SafeModeDisabled, Chars.LF);
	EndIf;
	
	Result.HasChanges = PatchesChanged;
	Result.ChangesDetails = ChangesDetails;
	
	Return Result;
	
EndFunction

#Region ForCallsFromOtherSubsystems

// OnlineUserSupport.GetApplicationUpdates

// Gets configuration update settings.
//
// Returns:
//   Structure:
//     * UpdateMode - Number - 0 for a file infobase, 2 for a client/server infobase.
//     * UpdateDateTime - Date - a scheduled configuration update date.
//     * EmailReport - Boolean - shows whether update reports are sent by email.
//     * Email - String - an email address for sending update reports.
//     * SchedulerTaskCode - Number - a Windows scheduler task code.
//     * UpdateFileName - String - an update file name.
//     * PatchesFiles - Array of String
//     * CreateDataBackup - Number - shows whether a backup is created.
//     * IBBackupDirectoryName - String - a backup directory.
//     * RestoreInfobase - Boolean - shows whether an infobase is restored from a backup
//                                                    in case of update errors.
//
Function ConfigurationUpdateSettings() Export
	
	DefaultSettings = DefaultSettings();
	Settings = Common.CommonSettingsStorageLoad("ConfigurationUpdate", "ConfigurationUpdateSettings");
	
	If Settings <> Undefined Then
		FillPropertyValues(DefaultSettings, Settings);
	EndIf;
	
	Return DefaultSettings;
	
EndFunction

// Saves configuration update settings.
//
// Parameters:
//    Settings - See ConfigurationUpdate.ConfigurationUpdateSettings
//
Procedure SaveConfigurationUpdateSettings(Settings) Export
	
	DefaultSettings = DefaultSettings();
	FillPropertyValues(DefaultSettings, Settings);
	
	Common.CommonSettingsStorageSave(
		"ConfigurationUpdate",
		"ConfigurationUpdateSettings",
		DefaultSettings);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Managing patches.

// Returns details of patches installed in the configuration.
//
// Returns:
//  Array - Structures with the following keys:
//     * Id - String - a patch UUID.
//                     - Undefined - if a patch was installed
//                                in the current session and the application has not been restarted yet.
//     * Description  - String - a patch description.
//
Function InstalledPatches() Export
	
	Result = New Array;
	InstalledExtensions = ConfigurationExtensions.Get(); // Array of ConfigurationExtension
	For Each Extension In InstalledExtensions Do
		If Not IsPatch(Extension) Then
			Continue;
		EndIf;
		PatchInformation = New Structure("Id, Description");
		PatchProperties = PatchProperties(Extension.Name);
		
		If PatchProperties <> Undefined And PatchProperties <> "ReadingError" Then
			PatchInformation.Id = PatchProperties.UUID;
		EndIf;
		PatchInformation.Description  = Extension.Name;
		
		Result.Add(PatchInformation);
	EndDo;
	
	Return Result;
	
EndFunction

// Installs and deletes patches.
//
// Parameters:
//  Corrections - Structure:
//     * Set - Array - patch files in a temporary storage.
//     * Delete    - Array - UUIDs of patches to be deleted (String).
//  PatchesInstallationParameters - See PatchesInstallationParameters
//                                - Boolean - Obsolete.
//  ShouldDeleteUpdateExtensionsOperationParameters - Boolean - The default value is "True".
//                         If the function is called from a configuration update script, set it to "False".
//  DeleteShouldCheckApplicabilityByManifest - Boolean - Set to "True" if the patch is installed manually.
//
// Returns:
//  Structure:
//     * Installed - Array - names of installed patches (String).
//     * Unspecified - Number - the number of patches that are not installed.
//     * NotDeleted     - Number - the number of patches that are not deleted.
//     * Errors        - Array of Structure:
//          * PatchNumber - String - a full patch name.
//          * Event    - String - an event that caused an error. Installation or Deletion.
//          * Cause    - String - detailed error description.
//
Function InstallAndDeletePatches(Corrections, Val PatchesInstallationParameters = Undefined, ShouldDeleteUpdateExtensionsOperationParameters = True, DeleteShouldCheckApplicabilityByManifest = False) Export
	
	If PatchesInstallationParameters = Undefined Then
		PatchesInstallationParameters = PatchesInstallationParameters();
	ElsIf TypeOf(PatchesInstallationParameters) = Type("Boolean") Then
		InBackground = PatchesInstallationParameters;
		PatchesInstallationParameters = PatchesInstallationParameters();
		PatchesInstallationParameters.InBackground = InBackground;
		PatchesInstallationParameters.UpdateExtensionParameters = ShouldDeleteUpdateExtensionsOperationParameters;
		PatchesInstallationParameters.ShouldCheckApplicabilityByManifest = DeleteShouldCheckApplicabilityByManifest;
	EndIf;
	
	ToInstall = Undefined;
	Unspecified   = 0;
	ExecutionResult = New Structure;
	ExecutionResult.Insert("Unspecified", 0);
	ExecutionResult.Insert("NotDeleted", 0);
	ExecutionResult.Insert("Installed", New Array);
	ExecutionResult.Insert("Errors", New Array);
	If Corrections.Property("Set", ToInstall)
		And ToInstall <> Undefined
		And ToInstall.Count() > 0 Then
		
		For Each FixPatch In ToInstall Do
			PatchName = "";
			Data = Undefined;
			Try
				// Reading a patch from an archive.
				If TypeOf(FixPatch) = Type("Structure") Then
					If StrEndsWith(FixPatch.Name, ".zip") Then
						PatchFromArchive = ExtractPatchFromArchive(FixPatch.Location, PatchesInstallationParameters.ShouldCheckApplicabilityByManifest);
						If PatchFromArchive.Property("PatchesArchives") Then
							PatchesFromArchive = New Structure;
							PatchesFromArchive.Insert("Set", PatchFromArchive.PatchesArchives);
							Result = InstallAndDeletePatches(PatchesFromArchive, PatchesInstallationParameters);
							ExecutionResult.Unspecified = ExecutionResult.Unspecified + Result.Unspecified;
							CommonClientServer.SupplementArray(ExecutionResult.Installed, Result.Installed);
							Continue;
						EndIf;
						PatchName = PatchFromArchive.PatchName1;
						If ValueIsFilled(PatchFromArchive.ErrorText) Then
							Raise PatchFromArchive.ErrorText;
						EndIf;
						Data = PatchFromArchive.Data;
					Else
						Data = GetFromTempStorage(FixPatch.Location);
						PatchName = FixPatch.Name;
					EndIf;
				Else
					PatchFromArchive = ExtractPatchFromArchive(FixPatch, PatchesInstallationParameters.ShouldCheckApplicabilityByManifest);
					PatchName = PatchFromArchive.PatchName1;
					If ValueIsFilled(PatchFromArchive.ErrorText) Then
						Raise PatchFromArchive.ErrorText;
					EndIf;
					Data = PatchFromArchive.Data;
				EndIf;
				
				Extension = ConfigurationExtensions.Create();
				Catalogs.ExtensionsVersions.DisableSecurityWarnings(Extension);
				Catalogs.ExtensionsVersions.DisableMainRolesUsageForAllUsers(Extension);
				Extension.SafeMode = False;
				Extension.UsedInDistributedInfoBase = PatchesInstallationParameters.UsedInDistributedInfoBase;
				Extension.Write(Data);
				
				InstalledPatch = ExtensionByID(Extension.UUID);
				If Not IsPatch(InstalledPatch) Then
					Extension.Delete();
					Raise NStr("ru = 'Расширение не является патчем.';
											|en = 'This is not a patch file.';");
				EndIf;
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Установлено исправление: %1';
						|en = 'Patch installed: %1';"),
					InstalledPatch.Name);
				WriteLogEvent(NStr("ru = 'Исправления.Установка';
												|en = 'Patch.Install';", Common.DefaultLanguageCode()),
					EventLogLevel.Information,,, MessageText);
				
				ExecutionResult.Installed.Add(InstalledPatch.Name);
			Except
				ErrorInfo = ErrorInfo();
				
				If Data <> Undefined Then
					PatchDetails = New ConfigurationDescription(Data);
					PatchName = PatchDetails.Name;
				EndIf;
				
				TheFixIsAlreadyInstalled = False;
				If ValueIsFilled(PatchName) Then
					Filter = New Structure;
					Filter.Insert("Name", PatchName);
					FixesFound = ConfigurationExtensions.Get(Filter);
					TheFixIsAlreadyInstalled = FixesFound.Count() > 0;
				EndIf;
				
				If Not TheFixIsAlreadyInstalled Then
					Unspecified = Unspecified + 1;
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось установить исправление %1 по причине:
					           |
					           |%2';
								|en = 'Cannot install the ""%1"" patch due to:
								|
								|%2';"), PatchName, ErrorProcessing.BriefErrorDescription(ErrorInfo));
					WriteLogEvent(NStr("ru = 'Исправления.Установка';
													|en = 'Patch.Install';", Common.DefaultLanguageCode()),
						EventLogLevel.Error,,, ErrorText);
				EndIf;
				
				ErrorDescription = New Structure;
				ErrorDescription.Insert("PatchNumber", PatchName);
				ErrorDescription.Insert("Event", "Set");
				ErrorDescription.Insert("Cause", ErrorProcessing.DetailErrorDescription(ErrorInfo));
				ExecutionResult.Errors.Add(ErrorDescription);
			EndTry;
		EndDo;
	EndIf;
	
	ItemsToDelete = Undefined;
	NotDeleted = 0;
	If Corrections.Property("Delete", ItemsToDelete)
		And ItemsToDelete <> Undefined
		And ItemsToDelete.Count() > 0 Then
		AllExtensions = ConfigurationExtensions.Get();
		For Each Extension In AllExtensions Do
			If Not IsPatch(Extension)
				Or ExecutionResult.Installed.Find(Extension.Name) <> Undefined Then
				Continue;
			EndIf;
			Try
				PatchName = Extension.Name;
				PatchProperties = PatchProperties(Extension.Name);
				If PatchProperties = "ReadingError" Or PatchProperties = Undefined Then
					Continue;
				EndIf;
				Id = PatchProperties.UUID;
				If ItemsToDelete.Find(String(Id)) <> Undefined Then
					Extension.Delete();
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Удалено исправление: %1';
							|en = 'Patch deleted: %1';"),
						Extension.Name);
					WriteLogEvent(NStr("ru = 'Исправления.Удаление';
													|en = 'Patch.Delete';", Common.DefaultLanguageCode()),
						EventLogLevel.Information,,, MessageText);
				EndIf;
			Except
				NotDeleted = NotDeleted + 1;
				ErrorInfo = ErrorInfo();
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось удалить исправление ""%1"" по причине:
					           |
					           |%2';
								|en = 'Cannot delete patch ""%1."" Reason:
								|
								|%2';"), Extension.Name, ErrorProcessing.BriefErrorDescription(ErrorInfo));
				WriteLogEvent(NStr("ru = 'Исправления.Удаление';
												|en = 'Patch.Delete';", Common.DefaultLanguageCode())
					, EventLogLevel.Error,,, ErrorText);
				
				ErrorDescription = New Structure;
				ErrorDescription.Insert("PatchNumber", PatchName);
				ErrorDescription.Insert("Event", "Delete");
				ErrorDescription.Insert("Cause", ErrorProcessing.DetailErrorDescription(ErrorInfo));
				ExecutionResult.Errors.Add(ErrorDescription);
			EndTry;
		EndDo;
	EndIf;
	
	CurrentSession = GetCurrentInfoBaseSession().GetBackgroundJob();
	IsBackgroundJob = (CurrentSession <> Undefined);
	
	AsynchronousCallText = "";
	If Common.FileInfobase() And (PatchesInstallationParameters.InBackground Or IsBackgroundJob) Then
		AsynchronousCallText = NStr("ru = 'Обновление параметров работы расширений после установки или
			|удаления патчей завершилось с ошибкой.';
			|en = 'Failed to update extension parameters
			|after some patches were installed or deleted.';")
	EndIf;
	
	If PatchesInstallationParameters.UpdateExtensionParameters Then
		InformationRegisters.ExtensionVersionParameters.UpdateExtensionParameters(Undefined, "", AsynchronousCallText);
	EndIf;
	
	ExecutionResult.Unspecified = ExecutionResult.Unspecified + Unspecified;
	ExecutionResult.NotDeleted = NotDeleted;
	
	If ExecutionResult.Installed.Count() > 0 Then
		If Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then 
			OperationName = "StandardSubsystems.ConfigurationUpdate.Patches1.AutomaticPatchInstallation";
			ModuleMonitoringCenter = Common.CommonModule("MonitoringCenter");
			ModuleMonitoringCenter.WriteBusinessStatisticsOperation(OperationName, ExecutionResult.Installed.Count());
		EndIf;
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

// A constructor for preparing parameters for "InstallAndDeletePatches"
// 
// Returns:
//   Structure:
//     * InBackground - Boolean - Set to "True" if the function is called in a background job.
//     * UpdateExtensionParameters - Boolean - The default value is "True".
//                                                    If the function is called from a configuration update script, set it to "False".
//     * ShouldCheckApplicabilityByManifest - Boolean - Set to "True" if the patch is installed manually.
//     * UsedInDistributedInfoBase - Boolean - The default value is "True"
//
Function PatchesInstallationParameters() Export
	
	PatchesInstallationParameters = New Structure;
	
	PatchesInstallationParameters.Insert("InBackground", False);
	PatchesInstallationParameters.Insert("UpdateExtensionParameters", True);
	PatchesInstallationParameters.Insert("ShouldCheckApplicabilityByManifest", False);
	PatchesInstallationParameters.Insert("UsedInDistributedInfoBase", True);
	
	Return PatchesInstallationParameters;
	
EndFunction

// Checks whether extensions that require to show 
// the warning about existing extensions are present.
// Checks whether extensions that are not patches are present.
//
// Returns:
//  Boolean - check result.
//
Function WarnAboutExistingExtensions() Export 
	
	AllExtensions = ConfigurationExtensions.Get();
	
	For Each Extension In AllExtensions Do
		If Not IsPatch(Extension) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// End OnlineUserSupport.GetApplicationUpdates

#EndRegion

#EndRegion

#Region Internal

Function IsCurrentVersionRequiresSuccessfulHandlersCompletion() Export
	
	CurrentStatus = ConfigurationUpdateStatus();
	If CurrentStatus = Undefined Then
		Return False;
	EndIf;
	
	If Not CurrentStatus.Property("VersionsRequiringSuccessfulUpdate") Then
		Return False;
	EndIf;
	
	Return CurrentStatus.VersionsRequiringSuccessfulUpdate.Find(Metadata.Version) <> Undefined;
	
EndFunction

Procedure CheckObsoletePatchesExist() Export
	Result = PatchesChanged(True);
	If Result.HasChanges Then
		MessageText = NStr("ru = 'Некорректный вызов функции ""%1"".
			|Перед вызовом не были удалены устаревшие патчи, возможно, обновление выполняется нештатными средствами.';
			|en = 'Incorrect call of function ""%1"".
			|Obsolete patches were not deleted before the call. The update might be performed by non-standard means.';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, "InfobaseUpdate.UpdateInfobase");
		WriteLogEvent(EventLogEvent(), EventLogLevel.Error,,, MessageText);
	EndIf;
EndProcedure

Procedure NewPatchesDetails1(StorageAddress, CurrentPatches, ForUpdate = False) Export
	If ForUpdate Then
		DetailsList1 = New Map;
	Else
		DetailsList1 = New Array;
	EndIf;
	For Each Patch In CurrentPatches Do
		If Metadata.CommonTemplates.Find(Patch) = Undefined Then
			Continue;
		EndIf;
		Template = GetCommonTemplate(Patch);
		For LineNumber = 1 To Template.LineCount() Do
			String = Template.GetLine(LineNumber);
			If Not StrStartsWith(TrimL(String), "<Description>") Then
				Continue;
			EndIf;
			PatchDetails1 = StrReplace(TrimL(String), "<Description>", "");
			While LineNumber < Template.LineCount() Do
				If StrEndsWith(TrimR(PatchDetails1), "</Description>") Then
					PatchDetails1 = StrReplace(TrimR(PatchDetails1), "</Description>", "");
					Break;
				EndIf;
				LineNumber = LineNumber + 1;
				String = Template.GetLine(LineNumber);
				PatchDetails1 = PatchDetails1 + Chars.LF + String;
			EndDo;
			If ForUpdate Then
				DetailsList1.Insert(Patch, PatchDetails1);
			Else
				DetailsList1.Add(Patch + ": " + PatchDetails1);
			EndIf;
			Break;
		EndDo;
	EndDo;
	
	If ForUpdate Then
		PutToTempStorage(DetailsList1, StorageAddress);
	Else
		DetailsAsString = StrConcat(DetailsList1, Chars.LF);
		PutToTempStorage(DetailsAsString, StorageAddress);
	EndIf;
EndProcedure

// This method is called when a configuration update over a COM connection is completed.
//
// Parameters:
//  UpdateResult  - Boolean - update result.
//  Email  - String - an email address the result report will be sent to.
//  UpdateAdministratorName  - String - a name of the user who updated the application.
//  ScriptDirectory  - String - a full path of the folder with an update script log.
//
Procedure CompleteUpdate(Val UpdateResult, Val Email, Val UpdateAdministratorName, Val ScriptDirectory = Undefined) Export

	MessageText = NStr("ru = 'Завершение обновления из внешнего скрипта.';
							|en = 'Completing update from the external script file.';");
	WriteLogEvent(EventLogEvent(), EventLogLevel.Information,,,MessageText);
	
	If Not HasRightsToInstallUpdate() Then
		MessageText = NStr("ru = 'Недостаточно прав для завершения обновления приложения.';
								|en = 'Insufficient rights to complete the application update.';");
		WriteLogEvent(EventLogEvent(), EventLogLevel.Error,,,MessageText);
		Raise(MessageText, ErrorCategory.AccessViolation);
	EndIf;
	
	If ScriptDirectory = Undefined Then 
		ScriptDirectory = ScriptDirectory();
	EndIf;
	
	ParametersOfUpdate = ConfigurationUpdateServerCall.ParametersOfUpdate();
	ParametersOfUpdate.UpdateAdministratorName = UpdateAdministratorName;
	ParametersOfUpdate.UpdateScheduled = False;
	ParametersOfUpdate.UpdateComplete = True;
	ParametersOfUpdate.ConfigurationUpdateResult = UpdateResult;
	ParametersOfUpdate.ScriptDirectory = ScriptDirectory;
	WriteUpdateStatus(ParametersOfUpdate);
	
	If Common.SubsystemExists("StandardSubsystems.EmailOperations")
		And Not IsBlankString(Email) Then
		Try
			SendUpdateNotification(UpdateAdministratorName, Email, UpdateResult);
			MessageText = NStr("ru = 'Уведомление об обновлении успешно отправлено на адрес электронной почты:';
									|en = 'An update notification is sent to:';")
				+ " " + Email;
			WriteLogEvent(EventLogEvent(), EventLogLevel.Information,,,MessageText);
		Except
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось отправить письмо на адрес ""%1"" по причине:
					|%2';
					|en = 'Cannot send an email to %1 due to:
					|%2';"),
				Email, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(EventLogEvent(), EventLogLevel.Error,,,MessageText);
		EndTry;
	EndIf;
	
	If UpdateResult Then
		InfobaseUpdateInternal.AfterUpdateCompletion();
	EndIf;
	
EndProcedure

Function ScriptDirectory() Export
	
	ScriptDirectory = "";
	
	If Not Common.DataSeparationEnabled() Then 
		UpdateStatus = ConfigurationUpdateStatus();
		If UpdateStatus <> Undefined And UpdateStatus.Property("ScriptDirectory") Then
			ScriptDirectory = UpdateStatus.ScriptDirectory;
			
			UpdateStatus.ScriptDirectory = "";
			SetConfigurationUpdateStatus(UpdateStatus); 
		EndIf;
	EndIf;
	
	If Not IsBlankString(ScriptDirectory) Then
		// If the catalog is already deleted, treating this as a regular update from Designer.
		FileInfo3 = New File(ScriptDirectory);
		If Not FileInfo3.Exists() Then 
			ScriptDirectory = "";
		EndIf;
	EndIf;
	
	Return ScriptDirectory;
	
EndFunction

// Returns the full name of the main form of the InstallUpdates data processor.
//
// Returns:
//  String
//
Function InstallUpdatesFormName() Export
	
	Return "DataProcessor.InstallUpdates.Form";
	
EndFunction

// Reads patch properties from a template. The template name must be identical to the patch name.
// XML template format. It matches the Patch XDTO package.
//
// Returns:
//  XDTODataObject
//  Undefined — the patch has not been applied.
//  String      — "ReadingError", invalid template format with patch details.
//
Function PatchProperties(PatchName) Export
	
	If Metadata.CommonTemplates.Find(PatchName) = Undefined Then
		Return Undefined;
	EndIf;
	
	XMLLine = GetCommonTemplate(PatchName).GetText();
	
	XMLReader = New XMLReader;
	XMLReader.SetString(XMLLine);
	
	Try
		Return XDTOFactory.ReadXML(XMLReader, XDTOFactory.Type("http://www.v8.1c.ru/ssl/patch", "Patch"));
	Except
		Return "ReadingError";
	EndTry;
	
EndFunction

Function IsPatch(Extension) Export
	
	Return Extension.Purpose = Metadata.ObjectProperties.ConfigurationExtensionPurpose.Patch
		And StrStartsWith(Extension.Name, "EF");
	
EndFunction

Procedure UpdatePatchesFromScript(NewPatches, PatchesToDelete) Export
	
	MessageText = NStr("ru = 'Обновление исправлений конфигурации из внешнего скрипта.';
							|en = 'Updating patches from an external script file.';");
	WriteLogEvent(EventLogEvent(), EventLogLevel.Information,,, MessageText);
	
	If Not HasRightsToInstallUpdate() Then
		MessageText = NStr("ru = 'Недостаточно прав для обновления исправлений (патчей).';
								|en = 'Insufficient rights to update patches.';");
		WriteLogEvent(EventLogEvent(), EventLogLevel.Error,,, MessageText);
		Raise(MessageText, ErrorCategory.AccessViolation);
	EndIf;
	
	PatchesChanged();
	
	PatchesToInstall1 = New Array;
	If ValueIsFilled(NewPatches) Then
		NewPatchesArray = StrSplit(NewPatches, Chars.LF);
		For Each Patch In NewPatchesArray Do
			Try
				PatchData = New BinaryData(Patch);
				PatchesToInstall1.Add(PutToTempStorage(PatchData));
			Except
				ErrorText = NStr("ru = 'Не удалось получить двоичные данные патча по причине:
					|%1';
					|en = 'Cannot get binary data of the patch due to:
					|%1';");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				WriteLogEvent(EventLogEvent(), EventLogLevel.Error, , , ErrorText);
			EndTry
		EndDo;
	EndIf;
	
	PatchesToDeleteArray = New Array;
	If ValueIsFilled(PatchesToDelete) Then
		PatchesToDeleteArray = StrSplit(PatchesToDelete, Chars.LF);
	EndIf;
	
	Corrections = New Structure("Set, Delete", PatchesToInstall1, PatchesToDeleteArray);
	PatchesInstallationParameters = PatchesInstallationParameters();
	PatchesInstallationParameters.UpdateExtensionParameters = False;
	Result = InstallAndDeletePatches(Corrections, PatchesInstallationParameters);
	Result.Insert("TotalPatchCount", PatchesToInstall1.Count());
	
	Status = ConfigurationUpdateStatus();
	If Status = Undefined Then
		Return;
	EndIf;
	If Not Status.Property("PatchInstallationResult") Then
		Status.Insert("PatchInstallationResult");
	EndIf;
	Status.PatchInstallationResult = Result;
	SetConfigurationUpdateStatus(Status);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See InfobaseUpdateSSL.AfterUpdateInfobase.
Procedure AfterUpdateInfobase() Export
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	Status = ConfigurationUpdateStatus();
	If Status <> Undefined And Status.UpdateComplete And Status.ConfigurationUpdateResult <> Undefined
		And Not Status.ConfigurationUpdateResult Then
		
		Status.ConfigurationUpdateResult = True;
		SetConfigurationUpdateStatus(Status);
		
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	OnAddClientParameters(Parameters);
	
EndProcedure

// See CommonOverridable.OnAddClientParameters.
Procedure OnAddClientParameters(Parameters) Export
	
	If Not Common.SeparatedDataUsageAvailable()
		Or Not Common.IsWindowsClient() Then
		Return;
	EndIf;
	
	Parameters.Insert("SettingsOfUpdate", New FixedStructure(SettingsOfUpdate()));

EndProcedure

Procedure CheckUpdateStatus(UpdateResult, ScriptDirectory, InstalledPatches) Export
	
	// If it is the first start after a configuration update, storing and resetting status.
	UpdateResult = ConfigurationUpdateSuccessful(ScriptDirectory, InstalledPatches);
	If UpdateResult <> Undefined Then
		ResetConfigurationUpdateStatus();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Gets global update settings for a 1C:Enterprise session.
//
Function SettingsOfUpdate()
	
	Settings = New Structure;
	Settings.Insert("ConfigurationChanged",?(HasRightsToInstallUpdate(), ConfigurationChanged(), False));
	Settings.Insert("CheckPreviousInfobaseUpdates", ConfigurationUpdateSuccessful() <> Undefined);
	Settings.Insert("ConfigurationUpdateSettings", ConfigurationUpdateSettings());
	
	Return Settings;
	
EndFunction

// Returns the flag that shows whether configuration update is successful (based on the constant from the settings).
//
// Parameters:
//  ScriptDirectory  - String - a full path of the folder with an update script log.
//  InstalledPatches  - String
//
// Returns:
//  Boolean
//  Undefined
//
Function ConfigurationUpdateSuccessful(ScriptDirectory = "", InstalledPatches = "") Export

	If Not AccessRight("Read", Metadata.Constants.ConfigurationUpdateStatus) Then
		Return Undefined;
	EndIf;
	
	Status = ConfigurationUpdateStatus();
	If Status = Undefined Then
		Return Undefined;
	EndIf;
	
	If Not StandardSubsystemsServer.IsBaseConfigurationVersion()
		And Not Status.UpdateComplete
		Or (Status.UpdateAdministratorName <> UserName()) Then
		
		Return Undefined;
		
	EndIf;
	
	If Status.ConfigurationUpdateResult <> Undefined Then
		Status.Property("ScriptDirectory", ScriptDirectory);
		Status.Property("PatchInstallationResult", InstalledPatches);
	EndIf;
	
	Return Status.ConfigurationUpdateResult;

EndFunction

// Sets a new value to the update settings constant
// based on the success of the last configuration update attempt.
//
Procedure WriteUpdateStatus(UpdateStatus, MessagesForEventLog = Undefined) Export
	
	EventLog.WriteEventsToEventLog(MessagesForEventLog);
	
	UpdateStatus.Insert("PatchInstallationResult", Undefined);
	
	OldStatus = ConfigurationUpdateStatus();
	If OldStatus <> Undefined
		And OldStatus.Property("PatchInstallationResult")
		And OldStatus.PatchInstallationResult <> Undefined Then
		UpdateStatus.PatchInstallationResult = OldStatus.PatchInstallationResult;
	EndIf;
	
	SetConfigurationUpdateStatus(UpdateStatus);
	
EndProcedure

Procedure ResetConfigurationUpdateStatus() Export
	
	SetConfigurationUpdateStatus(Undefined);
	
EndProcedure

Function HasRightsToInstallUpdate() Export
	Return Users.IsFullUser(, True);
EndFunction

Procedure SendUpdateNotification(Val UserName, Val DestinationAddress, Val SuccessfulUpdate)
	
	Subject = ? (SuccessfulUpdate, NStr("ru = 'Успешное обновление конфигурации ""%1"", версия %2';
										|en = 'Application %1 has been updated to version %2';"), 
		NStr("ru = 'Ошибка обновления конфигурации ""%1"", версия %2';
			|en = 'Application %1 failed to update to version %2';"));
	Subject = StringFunctionsClientServer.SubstituteParametersToString(Subject, Metadata.BriefInformation, Metadata.Version);
	
	Details_ = ?(SuccessfulUpdate, NStr("ru = 'Обновление конфигурации завершено успешно.';
											|en = 'Application has been updated.';"), 
		NStr("ru = 'При обновлении конфигурации произошли ошибки. Подробности записаны в журнал регистрации.';
			|en = 'Application has failed to update. See the event log for details.';"));
	Text = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1
		|
		|Конфигурация: %2
		|Версия: %3
		|Строка соединения: %4';
		|en = '%1
		|
		|Application: %2
		|Version: %3
		|Connection string: %4';"),
	Details_, Metadata.BriefInformation, Metadata.Version, InfoBaseConnectionString());
	
	EmailParameters = New Structure;
	EmailParameters.Insert("Subject", Subject);
	EmailParameters.Insert("Body", Text);
	EmailParameters.Insert("Whom", DestinationAddress);
	
	ModuleEmailOperations = Common.CommonModule("EmailOperations");
	Account = ModuleEmailOperations.SystemAccount();
	MailMessage = ModuleEmailOperations.PrepareEmail(Account, EmailParameters);
	ModuleEmailOperations.SendMail(Account, MailMessage);
	
EndProcedure

Function EventLogEvent() Export
	Return NStr("ru = 'Обновление конфигурации';
				|en = 'Configuration update';", Common.DefaultLanguageCode());
EndFunction

Function DefaultSettings()
	
	Result = New Structure;
	Result.Insert("UpdateMode", ?(Common.FileInfobase(), 0, 2));
	Result.Insert("UpdateDateTime", BegOfDay(CurrentSessionDate()) + 24*60*60);
	Result.Insert("EmailReport", False);
	Result.Insert("Email", "");
	Result.Insert("SchedulerTaskCode", 0);
	Result.Insert("UpdateFileName", "");
	Result.Insert("CreateDataBackup", 1);
	Result.Insert("IBBackupDirectoryName", "");
	Result.Insert("RestoreInfobase", True);
	Result.Insert("PatchesFiles", New Array);
	Result.Insert("Corrections", Undefined);
	Return Result;

EndFunction

Function ExecuteDeferredHandlers() Export
	
	Return Not StandardSubsystemsServer.IsBaseConfigurationVersion()
		And InfobaseUpdateInternal.UncompletedHandlersStatus() = "UncompletedStatus";
	
EndFunction

Function ExtractPatchFromArchive(Val FileThatWasPut, ShouldCheckApplicabilityByManifest = False)
	
	ArchiveName = GetTempFileName("zip");
	Data = Undefined;
	ErrorText = "";
	Try
		BinaryData = GetFromTempStorage(FileThatWasPut); // BinaryData
		BinaryData.Write(ArchiveName);
		
		PatchFound = False;
		PatchesArchives = New Array;
		TempDirectory = FileSystem.CreateTemporaryDirectory("Patches1");
		ZIPReader = New ZipFileReader(ArchiveName);
		For Each ArchiveItem In ZIPReader.Items Do
			If ArchiveItem.Extension = "cfe" Then
				PatchFound = True;
				Break;
			ElsIf ArchiveItem.Extension = "zip" Then
				ZIPReader.Extract(ArchiveItem, TempDirectory);
				
				FullPatchName = TempDirectory + ArchiveItem.Name;
				Data = New BinaryData(FullPatchName);
				PatchesArchives.Add(PutToTempStorage(Data));
			EndIf;
		EndDo;
		
		If Not PatchFound And PatchesArchives.Count() > 0 Then
			ZIPReader.Close();
			FileSystem.DeleteTempFile(TempDirectory);
			FileSystem.DeleteTempFile(ArchiveName);
			
			Result = New Structure;
			Result.Insert("PatchesArchives", PatchesArchives);
			Return Result;
		EndIf;
		
		If Not PatchFound Then
			Raise NStr("ru = 'Файл не является исправлением.';
									|en = 'This is not a patch file.';");
		EndIf;
		
		If ShouldCheckApplicabilityByManifest Then
			// Applicability check.
			PatchApplicable = PatchApplicable(ZIPReader, TempDirectory);
			If Not PatchApplicable Then
				Raise NStr("ru = 'Исправление не применимо для данной версии конфигурации.';
										|en = 'Cannot apply the patch to this configuration version.';");
			EndIf;
		EndIf;
		
		ZIPReader.Extract(ArchiveItem, TempDirectory);
		ZIPReader.Close();
		
		FullPatchName = TempDirectory + ArchiveItem.Name;
		Data = New BinaryData(FullPatchName);
		
		FileSystem.DeleteTempFile(ArchiveName);
		FileSystem.DeleteTemporaryDirectory(TempDirectory);
	Except
		FileSystem.DeleteTempFile(ArchiveName);
		If PatchFound Then
			FileSystem.DeleteTemporaryDirectory(TempDirectory);
		EndIf;
		ErrorInfo = ErrorInfo();
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	EndTry;
	
	Result = New Structure;
	If ArchiveItem <> Undefined Then
		Result.Insert("PatchName1", ArchiveItem.Name);
	Else
		Result.Insert("PatchName1", "");
	EndIf;
	Result.Insert("Data", Data);
	Result.Insert("ErrorText", ErrorText);
	
	Return Result;
	
EndFunction

Function PatchApplicable(ZIPReader, TempDirectory)
	ManifestFile = ZIPReader.Items.Find("Manifest.xml");
	If ManifestFile = Undefined Then
		Return True;
	EndIf;
	
	If Common.DebugMode() Then
		Return True;
	EndIf;
	
	Try
		ZIPReader.Extract(ManifestFile, TempDirectory);
		TextDocument = New TextDocument;
		TextDocument.Read(TempDirectory + ManifestFile.Name);
		
		XMLReader = New XMLReader;
		XMLReader.SetString(TextDocument.GetText());
		Properties = XDTOFactory.ReadXML(XMLReader, XDTOFactory.Type("http://www.v8.1c.ru/ssl/patch", "Patch"));
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		Raise NStr("ru = 'Некорректный формат файла манифеста исправления';
								|en = 'Incorrect patch manifest file format';") + ":" + Chars.LF + ErrorText;
	EndTry;
	
	SubsystemsDetails = StandardSubsystemsCached.SubsystemsDetails();
	
	For Each ApplicabilityInformation In Properties.AppliedFor Do
		If ApplicabilityInformation.ConfigurationName = "StandardSubsystemsLibrary" Then
			ApplicabilityInformation.ConfigurationName = "StandardSubsystems";
		EndIf;
		ConfigurationLibraryVersion = SubsystemsDetails.ByNames.Get(ApplicabilityInformation.ConfigurationName);
		
		If ConfigurationLibraryVersion <> Undefined
			And StrFind(ApplicabilityInformation.Versions, ConfigurationLibraryVersion.Version) > 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
EndFunction

// Parameters:
//  Id - UUID
//
// Returns:
//  ConfigurationExtension
//
Function ExtensionByID(Id)
	Filter = New Structure;
	Filter.Insert("UUID", Id);
	Return ConfigurationExtensions.Get(Filter)[0];
EndFunction

Function UpdateInfo(Val UpdateDeliveryFileName) Export
	
	Result = New Structure;
	Result.Insert("ErrorText", "");
	Result.Insert("Compatible", False);
	SourceConfigurations = New ValueTree;
	SourceConfigurations.Columns.Add("Version", New TypeDescription("String"));
	Result.Insert("SourceConfigurations", SourceConfigurations);
	
	Try
		FileData = New BinaryData(UpdateDeliveryFileName);
	Except
		WriteLogEvent(EventLogEvent(), EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Result.ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Return Result;
	EndTry;
	
	Try
		LongDesc = New ConfigurationUpdateDescription(FileData);
	Except
		WriteLogEvent(EventLogEvent(), EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Result.ErrorText = NStr("ru = 'Сведения не доступны';
									|en = 'The information is unavailable';");
		BriefErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		If Not IsBlankString(BriefErrorDescription) Then
			Result.ErrorText = Result.ErrorText + " (" + BriefErrorDescription + ")";
		EndIf;	
		Return Result;
	EndTry;
	
	For Each OriginalConfiguration In LongDesc.SourceConfigurations Do
		
		If Not Result.Compatible
			And (OriginalConfiguration.Name = Metadata.Name And OriginalConfiguration.Vendor = Metadata.Vendor
			And OriginalConfiguration.Version = Metadata.Version) Then
			Result.Compatible = True;
		EndIf;
		
		ConfigurationName = StringFunctionsClientServer.SubstituteParametersToString("%1 (%2)", 
			OriginalConfiguration.Name, OriginalConfiguration.Vendor);
		ConfigurationItem = SourceConfigurations.Rows.Find(ConfigurationName, "Version", False);
		If ConfigurationItem = Undefined Then
			ConfigurationItem = SourceConfigurations.Rows.Add();
			ConfigurationItem.Version = ConfigurationName; 
		EndIf;
		ConfigurationVersion = ConfigurationItem.Rows.Add();
		ConfigurationVersion.Version = OriginalConfiguration.Version;
	EndDo;
	Return Result;
	
EndFunction

Function ConfigurationUpdateStatus()
	
	StorageValue = Constants.ConfigurationUpdateStatus.Get();
	If StorageValue = Undefined Then
		Return Undefined;
	EndIf;	
	Return StorageValue.Get();
	
EndFunction

Procedure SetConfigurationUpdateStatus(Val Status)
	
	Constants.ConfigurationUpdateStatus.Set(New ValueStorage(Status));
	
EndProcedure

Function VersionWeightFromStringArray(VersionDigitsAsStrings)
	
	If VersionDigitsAsStrings.Count() <> 4 Then
		Return Undefined;
	EndIf;
	
	Return 0
		+ Number(VersionDigitsAsStrings[0]) * 1000000000
		+ Number(VersionDigitsAsStrings[1]) * 1000000
		+ Number(VersionDigitsAsStrings[2]) * 1000
		+ Number(VersionDigitsAsStrings[3]);
	
EndFunction

#EndRegion
