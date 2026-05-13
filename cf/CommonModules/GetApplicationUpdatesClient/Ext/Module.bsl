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
// CommonModule.GetApplicationUpdatesClient.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Opens the application update wizard in a working update mode:
// configuration or 1C:Enterprise platform update.
//
Procedure UpdateProgram() Export
	
	OpenForm("DataProcessor.ApplicationUpdate.Form.Form",
		New Structure("Scenario", "ApplicationUpdate1"));
	
EndProcedure

// Opens an application update wizard in the mode of migration to a new configuration
// edition.
//
// Parameters:
//	EditionNumber - String - Configuration edition to migrate to.
//		It is filled in the format of <Edition number>.<Subedition number>,
//		for example, 3.0, 3.1 and so on.
//	AdditionalParameters - Structure - additional parameters of opening
//		an update wizard. The structure includes the following fields:
//		* WindowTitle - String - an update wizard window title.
//		* UpdateAvailableHeader - String - a header of information about
//			 an available update. If it is not passed or filled in,
//			the header is not shown.
//		* NoUpdateHeader - String - a header of information about
//			an available update that is displayed if the update is unavailable.
//			If it is not passed or filled in,
//			the header is not shown.
//
Procedure MigrateToNewEdition(EditionNumber, AdditionalParameters = Undefined) Export
	
	If Not ValueIsFilled(EditionNumber) Then
		Raise NStr("ru = 'Не передан номер редакции.';
								|en = 'The version number is not specified.';");
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Scenario"          , "MigrationToAnotherApplicationOrRevision");
	FormParameters.Insert("NewEditionNumber", EditionNumber);
	
	If AdditionalParameters <> Undefined Then
		For Each KeyValue In AdditionalParameters Do
			FormParameters.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	OpenForm("DataProcessor.ApplicationUpdate.Form.Form", FormParameters);
	
EndProcedure

// Opens an application update wizard in the mode of migration to
// other application.
//
// Parameters:
//	NewApplicationName - String - The name of the new app.
//		See the OnlineSupportID property of the OnAddSubsystem method.
//	EditionNumber - String - an edition number of another application. It is filled
//		in the format of <Edition number>.<Subedition number>, for example, 3.0, 3.1 and so on.
//		If it is not passed, migration to the highest version is performed.
//	AdditionalParameters - Structure - additional parameters of opening
//		an update wizard. The structure includes the following fields:
//		* WindowTitle - String - an update wizard window title.
//		* UpdateAvailableHeader - String - a header of information about
//			 an available update. If it is not passed or filled in,
//			the header is not shown.
//		* NoUpdateHeader - String - a header of information about
//			an available update that is displayed if the update is unavailable.
//			If it is not passed or filled in,
//			the header is not shown.
//
Procedure MigrateToAnotherApplication(
	NewApplicationName,
	EditionNumber = Undefined,
	AdditionalParameters = Undefined) Export
	
	If Not ValueIsFilled(NewApplicationName) Then
		Raise NStr("ru = 'Не передано имя новой программы.';
								|en = 'New application name is not sent.';");
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Scenario"          , "MigrationToAnotherApplicationOrRevision");
	FormParameters.Insert("NewApplicationName" , NewApplicationName);
	FormParameters.Insert("NewEditionNumber", EditionNumber);
	
	If AdditionalParameters <> Undefined Then
		For Each KeyValue In AdditionalParameters Do
			FormParameters.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	OpenForm("DataProcessor.ApplicationUpdate.Form.Form", FormParameters);
	
EndProcedure

// Returns information about available application
// update in a working update scenario.
//
// Returns:
//	Structure - information about available update.
//		The fields:
//		* Error - Boolean - indicates that an error occurred when receiving
//			information on an available update. True - an error occurred,
//			otherwise, False.
//		* Message - String - a message about an error that can be
//			displayed to a user.
//		* ErrorInfo - String - details of an error, which
//			can be written to the event log.
//		* UpdateAvailable - Boolean - indicates whether there are available updates.
//			True - at least one update is available,
//			otherwise, False.
//		* Configuration - Structure - information on available configuration update.
//			If update is unavailable, the value is Undefined.
//			Fields:
//			** Version - String - Configuration version number.
//			** MinPlatformVersion - String - a minimum platform version
//				required to migrate to this configuration version.
//			** UpdateSize - Number - an update size in bytes.
//			** URLNewInVersion - String - "What's new in version" description file URL.
//			** URLOrderOfUpdate - String - URL of the "Update procedure" file.
//		* PatchesForCurrentVersion - Number - a number of available patches for
//			the current configuration version.
//		* PatchesForNewVersion - Number - a number of available patches for
//			a new configuration version.
//		* Platform - Structure - information on available 1C:Enterprise platform update.
//			If update is unavailable, the value is Undefined.
//			Fields:
//			** Version - String - Platform version number.
//			** UpdateSize - Number - an update size in bytes.
//			** URLTransitionFeatures - String - URL of description file "Features of migration to
//				a new 1C:Enterprise platform version".
//			** PlatformPageURL - String - Web page URL to
//				receive a distribution package manually.
//			** InstallationRequired - Number - indicates whether it is required to update the platform:
//				0 - required
//				1 - recommended
//				2 - not required.
//
Function AvailableUpdateInformation() Export
	
	Return GetApplicationUpdatesServerCall.AvailableUpdateInformation();
	
EndFunction

#Region IntegrationWithStandardSubsystemsLibrary

#Region BSPConfigurationUpdate

// Upon the application startup, it displays a form of the "Migration to a new
// 1C:Enterprise platform version" wizard in "Non-recommended
// 1C:Enterprise platform version is used" mode.
// The first wizard step informs that the platform version is
// lower than the recommended one. Available buttons: "Migrate to new platform version",
// "End session", "Continue with the current version" (depending on
// the passed parameters).
// Wizard form is displayed in the "Lock whole interface" mode.
// It is intended for integration with Standard Subsystems Library (SSL).
//
// Parameters:
//  ClosingNotification1 - NotifyDescription - A wizard exit notification handler.
//    If a user clicks "Continue with the current version", the handler takes "Continue".:
//      Otherwise, the handler takes "Undefined".
//      
//  StandardProcessing - Boolean - The parameter returns "False" if the standard 1C:Enterprise version data processor should be run
//    (in cases where the current runtime mode does not support the wizard).
//
Procedure WhenCheckingPlatformVersionAtStartup(ClosingNotification1, StandardProcessing) Export
	
	StandardProcessing = False;
	Try
		InternalOnCheckPlatformVersionOnStart(ClosingNotification1, StandardProcessing);
	Except
		StandardProcessing = True;
		GetApplicationUpdatesServerCall.WriteErrorToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка проверки версии платформы при запуске. %1';
					|en = 'An error occurred while checking the platform on start. %1';"),
				ErrorProcessing.DetailErrorDescription(ErrorInfo())));
	EndTry;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Internal

// Called upon the application start from
// OnlineUserSupportClient.OnStart().
//
Procedure OnStart() Export
	
	ClientParametersOnStart = StandardSubsystemsClient.ClientParametersOnStart();
	If Not ClientParametersOnStart.SeparatedDataUsageAvailable Then
		Return;
	EndIf;
	
	OUSParameters = ClientParametersOnStart.OnlineUserSupport;
	
	If OUSParameters.NotifyThatAutoImportOfPatchesEnabled Then
		AttachIdleHandler(
			"GetAppUpdates_ShowPatchDownloadSetupTask",
			1,
			True);
	EndIf;
	
	If OUSParameters.GetApplicationUpdates = Undefined Then
		// Platform update cannot be used in the current operation mode.
		Return;
	EndIf;
	
	SettingsOfUpdate = OnlineUserSupportClient.ValueFromFixedType(
		OUSParameters.GetApplicationUpdates);
	OnlineUserSupportClient.SetApplicationParameterValue(
		"GetApplicationUpdates\SettingsOfUpdate",
		SettingsOfUpdate);
	
	If SettingsOfUpdate.AutomaticCheckForProgramUpdates = 0 Then
		// If updates are not checked automatically
		OnlineUserSupportClient.SetApplicationParameterValue(
			"GetApplicationUpdates\CheckOnStartCompleted", True);
		Return;
	ElsIf SettingsOfUpdate.AutomaticCheckForProgramUpdates <> 1 Then
		OnlineUserSupportClient.SetApplicationParameterValue(
			"GetApplicationUpdates\CheckOnStartCompleted", True);
	EndIf;
	
	If OUSParameters.CheckForUpdate <> Undefined Then
		
		// Save the active check flag on startup.
		OnlineUserSupportClient.SetApplicationParameterValue(
			"GetApplicationUpdates\CheckOnStartCompleted",
			OUSParameters.CheckForUpdate.WasCheckStarted);
		
		If OUSParameters.CheckForUpdate.JobDetails <> Undefined Then
			AttachCheckResultProcessing(
				New Structure(OUSParameters.CheckForUpdate.JobDetails));
		ElsIf SettingsOfUpdate.AutomaticCheckForProgramUpdates = 2 Then
			// Call the schedule check in 5 minutes after the app startup.
			AttachScheduledCheck();
		Else
			// Calling automatic update check 1 second after the application start.
			AttachIdleHandler("GetApplicationUpdatesCheckForUpdates", 1, True);
		EndIf;
		
	EndIf;
	
EndProcedure

#Region Common

// Returns the common settings of the "Application update" subsystem.
//
// Returns:
//  See GetApplicationUpdatesServerCall.SettingsOfUpdate
//
Function GlobalUpdateSettings() Export
	
	SettingsOfUpdate = OnlineUserSupportClient.ApplicationParameterValue(
		"GetApplicationUpdates\SettingsOfUpdate");
	If SettingsOfUpdate = Undefined Then
		SettingsOfUpdate = GetApplicationUpdatesServerCall.SettingsOfUpdate();
		OnlineUserSupportClient.SetApplicationParameterValue(
			"GetApplicationUpdates\SettingsOfUpdate", SettingsOfUpdate);
	EndIf;
	
	Return SettingsOfUpdate;
	
EndFunction

#EndRegion

#Region ApplicationSettings

// The handler of the OnChange event associated with the AutomaticUpdatesCheck item
// in the "Online support and services" OSL administration panel.
//
// Parameters:
//  Form - See DataProcessor.OSLAdministrationPanel.Form.InternetSupportAndServices
//  Item - FormField - An administration panel event item.
//
Procedure AutomaticUpdatesCheckOnChange(Form, Item) Export
	
	Items = Form.Items;
	
	Items.UpdatesCheckScheduleDecoration.Enabled = (Form.AutomaticUpdatesCheck = 2);
	
	SettingsOfUpdate = GlobalUpdateSettings();
	SettingsOfUpdate.AutomaticCheckForProgramUpdates =
		Form.AutomaticUpdatesCheck;
	GetApplicationUpdatesServerCall.AutomaticUpdatesCheckOnChange(
		SettingsOfUpdate);
	WasCheckStarted = OnlineUserSupportClient.ApplicationParameterValue(
		"GetApplicationUpdates\WasCheckStarted",
		False);
	
	If Not WasCheckStarted Then
		// If a check job is running, the settings will apply automatically when the next check is completed.
		// 
		If Form.AutomaticUpdatesCheck <> 2 Then
			DisableScheduledCheck();
		Else
			AttachScheduledCheck();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Common

Function UpdatesReceiptProcessingFormOpen()
	
	NotificationParameter1 = New Structure("Form", Undefined);
	Notify("GetApplicationUpdatesCheckFormOpening", NotificationParameter1, ThisObject);
	Return (NotificationParameter1.Form <> Undefined);
	
EndFunction

Procedure WriteErrorToEventLog(Message) Export
	
	EventLogClient.AddMessageForEventLog(
		GetApplicationUpdatesClientServer.EventLogEventName(
			CommonClient.DefaultLanguageCode()),
		"Error",
		Message);
	
EndProcedure

Procedure WriteInformationToEventLog(Message) Export
	
	EventLogClient.AddMessageForEventLog(
		GetApplicationUpdatesClientServer.EventLogEventName(
			CommonClient.DefaultLanguageCode()),
		,
		Message);
	
EndProcedure

Procedure InternalOnCheckPlatformVersionOnStart(ClosingNotification1, StandardProcessing)
	
	CheckParameters = GetApplicationUpdatesServerCall.PlatformVersionCheckParametersOnStart();
	If CheckParameters.Continue Then
		ExecuteNotifyProcessing(ClosingNotification1, "Continue");
		Return;
	EndIf;
	
	If CheckParameters.IsSystemAdministrator Then
		
		// Displaying a message in the application update wizard.
		OpenForm("DataProcessor.ApplicationUpdate.Form",
			New Structure("Scenario, MustExit, MessageText",
				"NotRecommendedPlatformVersionMessage",
				CheckParameters.MustExit,
				CheckParameters.MessageText),
			,
			,
			,
			,
			ClosingNotification1,
			FormWindowOpeningMode.LockWholeInterface);
		
	Else
		
		// Showing message to a regular user in a new form.
		OpenForm("CommonForm.MessagePlatformVersionUpdateRequired",
			New Structure("MessageText", CheckParameters.MessageText),
			,
			,
			,
			,
			ClosingNotification1,
			FormWindowOpeningMode.LockWholeInterface);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region CheckForUpdates1

Procedure CheckUpdates() Export
	
	SettingsOfUpdate = GlobalUpdateSettings();
	CheckDate        = CommonClient.SessionDate();
	
	// Processing automatic update check settings.
	ExecuteCheck = False;
	If SettingsOfUpdate.AutomaticCheckForProgramUpdates = 1 Then
		
		If Not OnlineUserSupportClient.ApplicationParameterValue(
			"GetApplicationUpdates\CheckOnStartCompleted", False) Then
			OnlineUserSupportClient.SetApplicationParameterValue(
				"GetApplicationUpdates\CheckOnStartCompleted", True);
			ExecuteCheck = True;
		EndIf;
		
	ElsIf SettingsOfUpdate.AutomaticCheckForProgramUpdates = 2 Then
		// Determining whether it is necessary to execute a scheduled check
		
		Schedule            = CommonClientServer.StructureToSchedule(SettingsOfUpdate.Schedule);
		LastCheckDate = SettingsOfUpdate.LastCheckDate;
		
		If Schedule.ExecutionRequired(CheckDate, LastCheckDate) Then
			ExecuteCheck = True;
		EndIf;
		
	EndIf;
	
	If Not ExecuteCheck Then
		If SettingsOfUpdate.AutomaticCheckForProgramUpdates = 2 Then
			// If the check is on schedule, repeat the call in 5 minutes.
			AttachScheduledCheck();
		EndIf;
		Return;
	EndIf;
	
	UpdateSettingToSave = Undefined;
	If SettingsOfUpdate.AutomaticCheckForProgramUpdates = 2 Then
		// Writing the last check date.
		SettingsOfUpdate.Insert("LastCheckDate", CheckDate);
		// The settings will be saved when an update check starts.
		UpdateSettingToSave = SettingsOfUpdate;
	EndIf;
	
	CheckResult =
		GetApplicationUpdatesServerCall.SaveUpdateSettingsAndCheckForUpdates(
			UpdateSettingToSave);
	If CheckResult.JobDetails <> Undefined Then
		If CheckResult.JobDetails.Status = "Completed2" Then
			ProcessUpdateCheckCompletion(
				SettingsOfUpdate,
				CheckResult.NotificationParameters);
		Else
			AttachCheckResultProcessing(CheckResult.JobDetails);
		EndIf;
	ElsIf SettingsOfUpdate.AutomaticCheckForProgramUpdates = 2 Then
		AttachScheduledCheck();
	EndIf;
	
EndProcedure

Procedure OnCompletingCheckForUpdatesInBackground(Result, AdditionalParameters) Export
	
	If Result.Status = "Completed2" Then
		
		SettingsOfUpdate = GlobalUpdateSettings();
		NotificationParameters =
			GetApplicationUpdatesServerCall.DetermineAvailableUpdateNotificationParameters(
				Result.ResultAddress);
		
		ProcessUpdateCheckCompletion(
			SettingsOfUpdate,
			NotificationParameters);
		
	ElsIf Result.Status = "Error" Then
		GetApplicationUpdatesServerCall.WriteErrorToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось определить результат фоновой проверки наличия обновлений. %1';
					|en = 'Cannot determine the result of the background check for updates. %1';"),
				Result.DetailErrorDescription));
	EndIf;
	
EndProcedure

Procedure ProcessUpdateCheckCompletion(SettingsOfUpdate, NotificationParameters)
	
	// Job completed.
	OnlineUserSupportClient.SetApplicationParameterValue(
		"GetApplicationUpdates\WasCheckStarted",
		False);
	
	// Processing the job execution result
	If TypeOf(NotificationParameters) = Type("Structure") Then
		ProcessNotificationOnAvailableUpdate(NotificationParameters);
	EndIf;
	
	If SettingsOfUpdate.AutomaticCheckForProgramUpdates = 2 Then
		AttachScheduledCheck();
	EndIf;
	
EndProcedure

Procedure OnClickNotificationInformationOnAvailableUpdate(InformationOnUpdate1) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("Scenario", "ApplicationUpdate1");
	
	OpenForm("DataProcessor.ApplicationUpdate.Form.Form", FormParameters);
	
EndProcedure

Procedure ProcessNotificationOnAvailableUpdate(NotificationParameters)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ToDoList") Then
		ShowNotification = False;
		OSLSubsystemsIntegrationClient.OnDefineIsNecessaryToShowAvailableUpdatesNotifications(
			ShowNotification);
		GetApplicationUpdatesClientOverridable.OnDefineIsNecessaryToShowAvailableUpdatesNotifications(
			ShowNotification);
		If Not ShowNotification Then
			Return;
		EndIf;
	EndIf;
	
	If UpdatesReceiptProcessingFormOpen() Then
		Return;
	EndIf;
	
	ShowUserNotification(
		NStr("ru = 'Обновление программы';
			|en = 'Update application';"),
		New NotifyDescription(
			"OnClickNotificationInformationOnAvailableUpdate",
			ThisObject),
		NotificationParameters.Text,
		?(NotificationParameters.Error,
			PictureLib.Error32,
			?(NotificationParameters.Important,
				PictureLib.Warning32,
				PictureLib.DialogInformation)),
		?(NotificationParameters.Important Or NotificationParameters.Error,
			UserNotificationStatus.Important,
			UserNotificationStatus.Information),
		"GetApplicationUpdates");
	
EndProcedure

Procedure AttachScheduledCheck()
	
	AttachIdleHandler("GetApplicationUpdatesCheckForUpdates", 300, True);
	
EndProcedure

Procedure AttachCheckResultProcessing(JobDetails)
	
	// Save the active check flag.
	OnlineUserSupportClient.SetApplicationParameterValue(
		"GetApplicationUpdates\WasCheckStarted",
		True);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Undefined);
	IdleParameters.OutputIdleWindow = False;
	IdleParameters.Interval             = 10;
	
	TimeConsumingOperationsClient.WaitCompletion(
		JobDetails,
		New NotifyDescription(
			"OnCompletingCheckForUpdatesInBackground",
			ThisObject),
		IdleParameters);
	
EndProcedure

Procedure DisableScheduledCheck()
	
	DetachIdleHandler("GetApplicationUpdatesCheckForUpdates");
	
EndProcedure

#EndRegion

#EndRegion
