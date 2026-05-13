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
// CommonModule.GetApplicationUpdatesServerCall.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Automatic update setup.

// Saves update settings to the common settings storage.
//
// Parameters:
//  Settings - See SettingsOfUpdate
//
Procedure WriteUpdateSettings(Val Settings) Export
	
	GetApplicationUpdates.WriteAutoupdateSettings(Settings);
	
EndProcedure

// Returns the schedule of the GetAndInstallConfigurationTroubleshooting job.
//
// Returns:
//  Undefined - The scheduled job is not found.
//  JobSchedule
//
Function PatchesInstallationJobSchedule() Export
	
	Job = ScheduledJobsServer.GetScheduledJob(
		Metadata.ScheduledJobs.GetAndInstallConfigurationTroubleshooting);
	If Job <> Undefined Then
		Return Job.Schedule;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Saves the schedule of the GetAndInstallConfigurationTroubleshooting job.
//
// Parameters:
//  Schedule - JobSchedule
//
Procedure SetPatchesInstallationJobSchedule(Val Schedule) Export
	
	RepeatPeriodInDay = Schedule.RepeatPeriodInDay;
	If RepeatPeriodInDay > 0 And RepeatPeriodInDay < 3600 Then
		Raise NStr("ru = 'Интервал автоматической установки не может быть чаще, чем один раз в час.';
								|en = 'The automatic installation interval cannot be shorter than one hour.';");
	EndIf;
	
	ScheduledJobsServer.SetJobSchedule(
		Metadata.ScheduledJobs.GetAndInstallConfigurationTroubleshooting,
		Schedule);
	
EndProcedure

// Assigns a new value to the ImportAndInstallCorrectionsAutomatically constant.
//
// Parameters:
//  SettingValue - Boolean
//
Procedure EnableDisableAutomaticPatchesInstallation(Val SettingValue) Export
	
	GetApplicationUpdates.EnableDisableAutomaticPatchesInstallation(
		SettingValue);
	
EndProcedure

#EndRegion

#Region Private

Function AvailableUpdateInformation() Export
	
	InformationOnUpdate1 = GetApplicationUpdates.AvailableUpdateInformation();
	
	Result = New Structure;
	Result.Insert("Error"            , Not IsBlankString(InformationOnUpdate1.ErrorName));
	Result.Insert("Message"         , InformationOnUpdate1.Message);
	Result.Insert("ErrorInfo", InformationOnUpdate1.ErrorInfo);
	Result.Insert("UpdateAvailable", InformationOnUpdate1.UpdateAvailable);
	
	Configuration = New Structure;
	Configuration.Insert("Version"                    , "");
	Configuration.Insert("MinPlatformVersion", "");
	Configuration.Insert("UpdateSize"          , 0);
	Configuration.Insert("URLNewInVersion"           , "");
	Configuration.Insert("URLOrderOfUpdate"      , "");
	If InformationOnUpdate1.Configuration <> Undefined Then
		FillPropertyValues(Configuration, InformationOnUpdate1.Configuration);
	EndIf;
	Result.Insert("Configuration", Configuration);
	
	Platform = New Structure;
	Platform.Insert("Version"                 , "");
	Platform.Insert("UpdateSize"       , 0);
	Platform.Insert("URLTransitionFeatures" , "");
	Platform.Insert("PlatformPageURL"   , "");
	Platform.Insert("InstallationRequired", 0);
	FillPropertyValues(Platform, InformationOnUpdate1.Platform);
	Result.Insert("Platform", Platform);
	
	PatchesForCurrentVersion = 0;
	PatchesForNewVersion   = 0;
	If InformationOnUpdate1.Corrections <> Undefined Then
		PatchesForNewVersion = InformationOnUpdate1.Corrections.FindRows(
			New Structure(
				"ForNewVersion",
				True)).Count();
		PatchesForCurrentVersion = InformationOnUpdate1.Corrections.FindRows(
			New Structure(
				"ForCurrentVersion",
				True)).Count();
	EndIf;
	
	Result.Insert("PatchesForCurrentVersion", PatchesForCurrentVersion);
	Result.Insert("PatchesForNewVersion"  , PatchesForNewVersion);
	
	Return Result;
	
EndFunction

Procedure WriteErrorToEventLog(Val ErrorMessage) Export
	
	GetApplicationUpdates.WriteErrorToEventLog(
		ErrorMessage);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Automatic update setup.

// See GetApplicationUpdates.AutoupdateSettings
//
Function SettingsOfUpdate() Export
	
	Return GetApplicationUpdates.AutoupdateSettings();
	
EndFunction

Procedure AutomaticUpdatesCheckOnChange(Val SettingsOfUpdate) Export
	
	WriteUpdateSettings(SettingsOfUpdate);
	
	// Assume that a user who can configure the Administration panel can perform any action.
	// 
	SetPrivilegedMode(True);
	
	// Clear user settings.
	If SettingsOfUpdate.AutomaticCheckForProgramUpdates = 0 Then
		UsersList = InfoBaseUsers.GetUsers();
		For Each CurUser In UsersList Do
			Common.CommonSettingsStorageDelete(
				GetApplicationUpdatesClientServer.CommonSettingsID(),
				GetApplicationUpdates.SettingKeyAvailableUpdateInfo(),
				CurUser.Name);
		EndDo;
	EndIf;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Checking 1C:Enterprise platform version upon the application start.

Function PlatformVersionCheckParametersOnStart() Export
	
	Result = New Structure;
	Result.Insert("Continue"             , False);
	Result.Insert("IsSystemAdministrator", Users.IsFullUser(, True, False));
	
	BaseFunctionalityParameters = Common.CommonCoreParameters();
	
	CurrentPlatformVersion       = OnlineUserSupport.Current1CPlatformVersion();
	MinPlatformVersion   = BaseFunctionalityParameters.MinPlatformVersion;
	RecommendedPlatformVersion = BaseFunctionalityParameters.RecommendedPlatformVersion;
	
	MustExit = (CommonClientServer.CompareVersions(
		CurrentPlatformVersion,
		MinPlatformVersion) < 0);
	
	// Determining whether it is necessary to display a message.
	If Not MustExit Then
		
		If Not Result.IsSystemAdministrator Then
			
			// If the user can sign in to the app, don't show the message.
			// 
			Result.Continue = True;
			Return Result;
			
		Else
			
			// Checking if it is necessary to show a notification to the administrator.
			NotificationSettings = Common.CommonSettingsStorageLoad(
				"OnlineSupportDisabledGetApplicationUpdates",
				GetApplicationUpdates.SettingKeyMessageAboutNonRecommended1CEnterpriseVersion());
			
			If TypeOf(NotificationSettings) = Type("Structure") Then
				
				CheckProperties = New Structure("MetadataName,Metadata_Version,RecommendedPlatformVersion");
				FillPropertyValues(CheckProperties, NotificationSettings);
				
				If OnlineUserSupport.ConfigurationName() = CheckProperties.MetadataName
					And OnlineUserSupport.ConfigurationVersion() = CheckProperties.Metadata_Version
					And RecommendedPlatformVersion = CheckProperties.RecommendedPlatformVersion Then
					
					// If the message was shown for the given metadata property set,
					// don't show the message.
					Result.Continue = True;
					Return Result;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	// Determining notification parameters.
	Result.Insert("MustExit",
		BaseFunctionalityParameters.MustExit);
	
	MessageText = "<body>" + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Для работы с программой %1 использовать версию платформы &quot;1С:Предприятие 8&quot; не ниже: <b>%2</b>
			|<br />Используемая сейчас версия: %3';
			|en = 'The following version of 1C:Enterprise is %1: <b>%2</b>
			|<br />The current version is %3.';"),
		?(BaseFunctionalityParameters.MustExit,
			NStr("ru = 'необходимо';
				|en = 'required';"),
			NStr("ru = 'рекомендуется';
				|en = 'recommended';")),
		?(MustExit, MinPlatformVersion, RecommendedPlatformVersion),
		CurrentPlatformVersion);
	
	If Not Result.IsSystemAdministrator Then
		
		// In this branch, operations in the application are prohibited.
		MessageText = MessageText + "<br /><br />"
			+ NStr("ru = 'Вход в приложение невозможен.<br />
				|Необходимо обратиться к администратору для обновления версии платформы 1С:Предприятие.';
				|en = 'Cannot start the application.<br />
				|Contact the administrator to update 1C:Enterprise.';");
		
	ElsIf BaseFunctionalityParameters.MustExit Then
		
		MessageText = MessageText + "<br /><br />"
			+ NStr("ru = 'Вход в приложение невозможен.<br />
				|Необходимо предварительно обновить версию платформы 1С:Предприятие.';
				|en = 'Cannot start the application.<br />
				|Update 1C:Enterprise first.';");
		
	Else
		
		MessageText = MessageText + StringFunctionsClientServer.SubstituteParametersToString(
			"<br /><br />"
			+ NStr("ru = 'Рекомендуется обновить версию платформы 1С:Предприятия. Новая версия платформы содержит исправления ошибок,
				|которые позволят программе работать более стабильно.
				|<br />
				|<br />
				|Вы также можете продолжить работу на текущей версии платформы %1
				|<br />
				|<br />
				|<i>Версия платформы, необходимая для работы в программе: %2, рекомендуемая: %3 или выше, текущая: %4.</i>';
				|en = 'We recommend that you update the 1C:Enterprise platform version. The new platform version contains patches
				|that will allow the application to function more stable.
				|<br />
				|<br />
				|You can also continue using the current platform version  %1
				|<br />
				|<br />
				|<i>Platform version required for the application: %2. Recommended version: %3 or later. Current version: %4.</i>';"),
			CurrentPlatformVersion,
			MinPlatformVersion,
			RecommendedPlatformVersion,
			CurrentPlatformVersion);
		
	EndIf;
	
	MessageText = MessageText + "</body>";
	Result.Insert("MessageText",
		OnlineUserSupportClientServer.FormattedHeader(MessageText));
	
	Return Result;
	
EndFunction

// Saves the information on disabling the warning about using a non-recommended 1C:Enterprise version.
// The parameters include the name and version of the used configuration and the recommended 1C:Enterprise version obtained from the service.
// If either of the parameters is modified, the warning about using a non-recommended version will be displayed.
// 
//
Procedure SaveNotificationSettingsOfNonRecommendedPlatformVersion() Export
	
	BaseFunctionalityParameters = Common.CommonCoreParameters();
	RecommendedPlatformVersion     = BaseFunctionalityParameters.RecommendedPlatformVersion;
	
	DataToBeSaved = New Structure();
	DataToBeSaved.Insert("MetadataName"               , OnlineUserSupport.ConfigurationName());
	DataToBeSaved.Insert("Metadata_Version"            , OnlineUserSupport.ConfigurationVersion());
	DataToBeSaved.Insert("RecommendedPlatformVersion", RecommendedPlatformVersion);
	
	Common.CommonSettingsStorageSave(
		"OnlineSupportDisabledGetApplicationUpdates",
		GetApplicationUpdates.SettingKeyMessageAboutNonRecommended1CEnterpriseVersion(),
		DataToBeSaved);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Checking for updates in the background.

// Saves the passed setting and runs a long-running operation that checks for updates.
// If the operation runs synchronously, the return value will include notification parameters.
// 
//
// Parameters:
//  SettingsOfUpdate - Undefined - Do not save update settings.
//                      - Structure - Saves the passed settings to the common settings storage
//    The format: See GetApplicationUpdatesClient.GlobalUpdateSettings.
//
// Returns:
//  Structure:
//    * JobDetails - See GetApplicationUpdates.StartUpdateExistenceCheck
//    * NotificationParameters - See GetApplicationUpdates.DetermineAvailableUpdateNotificationParameters
//
Function SaveUpdateSettingsAndCheckForUpdates(Val SettingsOfUpdate = Undefined) Export
	Var NotificationParameters;
	
	If SettingsOfUpdate <> Undefined Then
		GetApplicationUpdates.WriteAutoupdateSettings(SettingsOfUpdate);
	EndIf;
	
	JobDetails = GetApplicationUpdates.StartUpdateExistenceCheck();
	If JobDetails.Status = "Completed2" Then
		NotificationParameters = GetApplicationUpdates.DetermineAvailableUpdateNotificationParameters(
			JobDetails.ResultAddress);
	EndIf;
	
	Result = New Structure;
	Result.Insert("JobDetails"    , JobDetails);
	Result.Insert("NotificationParameters", NotificationParameters);
	
	Return Result;
	
EndFunction

Function DetermineAvailableUpdateNotificationParameters(Val ResultAddress) Export
	
	Return GetApplicationUpdates.DetermineAvailableUpdateNotificationParameters(ResultAddress);
	
EndFunction

#EndRegion
