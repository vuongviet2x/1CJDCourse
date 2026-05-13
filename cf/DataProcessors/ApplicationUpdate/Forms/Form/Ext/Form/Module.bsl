///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
// 
Var AdministrationParameters;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Scenario = Parameters.Scenario;
	IsSubordinateDIBNode = Common.IsSubordinateDIBNode();
	
	Items.WarningsPanel.Visible = False;
	
	// After installing patches, restart the app.
	RestartApplication = True;
	
	// Hide inactive wizard pages.
	// Intended to eliminate "flashing" when toggling controls.
	// 
	BlankPage = Items.BlankPage;
	For Each CurPage In Items.Pages.ChildItems Do
		If CurPage <> BlankPage Then
			CurPage.Visible = False;
		EndIf;
	EndDo;
	
	If IsSubordinateDIBNode
		And Not IsScenarioOfMigrationToNewPlatformVersion(ThisObject)
		And Not IsNotRecommendedPlatformVersionMessageScenario(ThisObject) Then
		
		// In child nodes, the app is updated using the DIB mechanisms.
		// 
		LogMessage =
			NStr("ru = 'Обновление программы невозможно. В подчиненном узле информационной базы обновление получается из главного узла.';
				|en = 'Cannot update the application. The subnode of the infobase receives update from the main node.';");
		GetApplicationUpdates.WriteErrorToEventLog(LogMessage);
		DisplayInternalError(
			NStr("ru = '<b>Обновление программы невозможно</b><br />В подчиненном узле информационной базы обновление получается из главного узла.';
				|en = '<b>Cannot update the application</b><br /> The infobase subordinate node is updated from the main node.';"),
			,
			LogMessage);
		Items.NextButton.Visible  = False;
		Items.CancelButton.Title = NStr("ru = 'Закрыть';
												|en = 'Close';");
		Return;
		
	ElsIf Common.IsWebClient()
		And Not IsNotRecommendedPlatformVersionMessageScenario(ThisObject) Then
		
		LogMessage =
			NStr("ru = 'Обновление программы невозможно. Обновление программы недоступно при работе в режиме веб-клиента.';
				|en = 'Cannot update the application. The update is not available in the web client mode.';");
		GetApplicationUpdates.WriteErrorToEventLog(LogMessage);
		DisplayInternalError(
			NStr("ru = '<b>Обновление программы невозможно</b><br />
				|Обновление программы недоступно при работе в режиме веб-клиента.<br />
				|Откройте программу в тонком или толстом клиенте и повторите попытку.';
				|en = '<b>Cannot update the application</b><br /> Cannot update the application while working in the web client mode.<br />
				|Open the application in thin or thick client and retry.
				|';"),
			,
			LogMessage);
		Items.NextButton.Visible  = False;
		Items.CancelButton.Title = NStr("ru = 'Закрыть';
												|en = 'Close';");
		Return;
		
	ElsIf Common.ClientConnectedOverWebServer()
		And Not IsNotRecommendedPlatformVersionMessageScenario(ThisObject) Then
		
		LogMessage =
			NStr("ru = 'Обновление программы невозможно. Обновление программы недоступно при работе в режиме подключения к веб серверу.';
				|en = 'Cannot update the application. The update is not available in mode of connection to a web server.';");
		GetApplicationUpdates.WriteErrorToEventLog(LogMessage);
		DisplayInternalError(
			NStr("ru = '<b>Обновление программы невозможно</b><br />
				|Обновление программы недоступно при работе в режиме подключения к веб серверу.<br />
				|Откройте программу в тонком или толстом клиенте и повторите попытку.';
				|en = '<b>Cannot update the application</b><br />
				|Cannot update the application while working in the web server connection mode.<br />
				|Open the application in thin or thick client and retry.';"),
			,
			LogMessage);
		Items.NextButton.Visible  = False;
		Items.CancelButton.Title = NStr("ru = 'Закрыть';
												|en = 'Close';");
		Return;
		
	EndIf;
	
	// Checking mechanism usage capability.
	If IsScenarioOfMigrationToNewPlatformVersion(ThisObject)
		And Not GetApplicationUpdates.InternalCanUsePlatformUpdatesReceipt() Then
		ExceptionText =
			NStr("ru = 'Переход на новую версию платформы 1С:Предприятие недоступен в текущем режиме работы.';
				|en = 'You cannot migrate to a new version of 1C:Enterprise platform in the current operation mode.';");
		Raise ExceptionText;
	ElsIf (IsApplicationUpdateScenario(ThisObject)
		And Not GetApplicationUpdates.CanUseApplicationUpdate(False, False))
		Or (IsScenarioOfMigrationToOtherApplicationOrEdition(ThisObject)
		And Not GetApplicationUpdates.CanUseApplicationUpdate()) Then
		ExceptionText =
			NStr("ru = 'Получение обновлений программы недоступно в текущем режиме работы.';
				|en = 'Cannot receive application updates in the current operation mode.';");
		Raise ExceptionText;
	EndIf;
	
	IsSystemAdministrator = GetApplicationUpdates.IsSystemAdministrator();
	IsFileIB           = GetApplicationUpdates.IsFileIB();
	IsWindowsClient        = Common.IsWindowsClient();
	
	If IsScenarioOfMigrationToNewPlatformVersion(ThisObject)
		Or IsNotRecommendedPlatformVersionMessageScenario(ThisObject) Then
		
		If Not IsSystemAdministrator Then
			// Migration to a new version of the platform is executed by the system administrator only.
			Raise NStr("ru = 'Недостаточно прав для перехода на новую версию платформы.';
									|en = 'Insufficient rights to migrate to a new platform version.';");
		EndIf;
		
		AutoTitle = False;
		Title     = NStr("ru = 'Переход на новую версию платформы 1С:Предприятие';
							|en = 'Migrate to a new 1C:Enterprise platform version';");
		
	ElsIf IsScenarioOfMigrationToOtherApplicationOrEdition(ThisObject) Then
		
		If Not IsBlankString(Parameters.WindowTitle) Then
			AutoTitle = False;
			Title     = Parameters.WindowTitle;
		EndIf;
		UpdateAvailableHeader = Parameters.UpdateAvailableHeader;
		NoUpdateHeader      = Parameters.NoUpdateHeader;
		
		NewApplicationName  = Parameters.NewApplicationName;
		NewEditionNumber = Parameters.NewEditionNumber;
		
	ElsIf IsBlankString(Scenario) Then
		
		// Working update scenario is used by default.
		Scenario = "ApplicationUpdate1";
		
	ElsIf Not IsApplicationUpdateScenario(ThisObject) Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неизвестный сценарий работы помощника обновления программы (""%1"").';
				|en = 'Unknown script of the application update wizard (""%1""). ';"),
			Scenario);
		
	EndIf;
	
	UpdatesGetParameters = Undefined;
	
	If IsFileIB Then
		If GetApplicationUpdates.IsBaseConfigurationVersion() Then
			Items.DirectoryToSavePlatformComponentGroup.Visible = False;
		Else
			UpdatesGetParameters = GetApplicationUpdates.InternalUpdatesGetParameters();
			Items.DirectoryToSavePlatformComponentGroup.Visible =
				UpdatesGetParameters.SelectDirectoryToSavePlatformDistributionPackage;
		EndIf;
		Items.DirectoryToSavePlatformGroup.Visible =
			Items.DirectoryToSavePlatformComponentGroup.Visible;
	EndIf;
	
	Items.EmailTechSupportDecoration.Title =
		OnlineUserSupportClientServer.FormattedHeader(
			OnlineUserSupportClientServer.SubstituteDomain(
				NStr("ru = '<body>При возникновении проблем напишите в <a href=""mailto:webits-info@1c.eu"">техподдержку</a>.</body>';
					|en = '<body>If there are any issues, write an email to <a href=""mailto:webits-info@1c.eu""> the technical support</a>.</body>';"),
			OnlineUserSupport.ServersConnectionSettings().OUSServersDomain));
	
	If Not IsScenarioOfMigrationToOtherApplicationOrEdition(ThisObject) Then
		CreateBackup = Common.SubsystemExists("StandardSubsystems.IBBackup");
		Items.CreateBackup.Visible            = CreateBackup;
		Items.CreateBackupSet.Visible = CreateBackup;
	EndIf;
	
	If IsNotRecommendedPlatformVersionMessageScenario(ThisObject) Then
		// Read the server connection settings as it can be displayed before the startup.
		// 
		ServersConnectionSettings =
			OnlineUserSupportInternalCached.OUSServersConnectionSettings();
		MustExit = Parameters.MustExit;
		Items.MessageText.Title = Parameters.MessageText;
		DisplayNotRecommendedPlatformVersion();
	EndIf;
	
	If IsApplicationUpdateScenario(ThisObject)
		Or IsScenarioOfMigrationToOtherApplicationOrEdition(ThisObject) Then
		
		If Not GetApplicationUpdates.CanUseApplicationUpdate(True) Then
			
			Items.InstallUpdateFromFileGroup1.Visible = False;
			Items.InstallUpdateFromFileGroup2.Visible = False;
			
		Else
			
			If UpdatesGetParameters = Undefined Then
				UpdatesGetParameters = GetApplicationUpdates.InternalUpdatesGetParameters();
			EndIf;
			
			If Not UpdatesGetParameters.GetConfigurationUpdates
				And Not UpdatesGetParameters.GetPatches Then
				
				Items.InstallUpdateFromFileGroup1.Visible = False;
				Items.InstallUpdateFromFileGroup2.Visible = False;
				
			Else
				
				Items.InstallUpdateFromFileGroup1.Visible = True;
				Items.InstallUpdateFromFileGroup2.Visible = True;
				If UpdatesGetParameters.GetConfigurationUpdates
					And UpdatesGetParameters.GetPatches Then
					
					InstallUpdateFromFileTitle =
						NStr("ru = 'Установить обновление конфигурации или исправления (патчи) из файла';
							|en = 'Install configuration update or patches from file';");
					InstallUpdateFromFileTooltip =
						NStr("ru = 'Если у вас уже есть файл обновления конфигурации или файлы исправлений (патчи), перейдите по ссылке для установки обновления конфигурации из файла';
							|en = 'If you already have a configuration update file or patch files, follow the link to install the configuration update from the file.';");
					
				ElsIf UpdatesGetParameters.GetConfigurationUpdates
					And Not UpdatesGetParameters.GetPatches Then
					
					InstallUpdateFromFileTitle =
						NStr("ru = 'Установить обновление конфигурации из файла';
							|en = 'Install a configuration update from the file';");
					InstallUpdateFromFileTooltip =
						NStr("ru = 'Если у вас уже есть файл обновления конфигурации, перейдите по ссылке для установки обновления конфигурации из файла';
							|en = 'If you already have a configuration update file, follow the link to install the configuration update from the file.';");
						
				Else
					
					InstallUpdateFromFileTitle =
						NStr("ru = 'Установить исправления (патчи) из файла';
							|en = 'Install patches from file';");
					InstallUpdateFromFileTooltip =
						NStr("ru = 'Если у вас уже есть файлы исправлений (патчи), перейдите по ссылке для установки обновления конфигурации из файла';
							|en = 'If you already have patch files, follow the link to install the configuration update from the file.';");
					
				EndIf;
				
				Items.InstallUpdateFromFileDecoration1.Title = InstallUpdateFromFileTitle;
				Items.InstallUpdateFromFileDecoration2.Title = InstallUpdateFromFileTitle;
				Items.InstallUpdateFromFileDecoration1.ToolTip = InstallUpdateFromFileTooltip;
				Items.InstallUpdateFromFileDecoration2.ToolTip = InstallUpdateFromFileTooltip;
				
			EndIf;
			
		EndIf;
		
		UpdateReleaseNotificationOption      =
			GetApplicationUpdates.AutoupdateSettings().UpdateReleaseNotificationOption;
		
		// Integration with "Monitoring center" subsystem.
		ConfigureTheDisplayOfIntegrationWithTheMonitoringCenter();
		
	EndIf;
	
	SendMessagesToTechnicalSupportAvailable =
		Common.SubsystemExists("OnlineUserSupport.MessagesToTechSupportService");
	Items.EmailTechSupportDecoration.Visible = SendMessagesToTechnicalSupportAvailable;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Items.Pages.CurrentPage = Items.ServiceMessagePage Then
		// When creating on the server, an error message occurred.
		Return;
	EndIf;
	
	If IsNotRecommendedPlatformVersionMessageScenario(ThisObject) Then
		Return;
	EndIf;
	
	// This is an exception from the "Minimize server calls" standard since this is a synchronous method,
	// which can run for a period of time while switching to async will result in more server calls.
	// 
	GetAndDisplayInformationOnAvailableUpdate();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	// StandardSubsystems.ConfigurationUpdate
	If Upper(ChoiceSource.FormName) = Upper("DataProcessor.ActiveUsers.Form.ActiveUsers") Then
		
		DisplayUpdateReceiptComplete();
		
	EndIf;
	// End StandardSubsystems.ConfigurationUpdate
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "GetApplicationUpdatesCheckFormOpening"
		And TypeOf(Parameter) = Type("Structure") Then
		Parameter.Form = ThisObject;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Items.Pages.CurrentPage = Items.AcquisitionAndInstallationPage
		And Items.AcquisitionInstallationPages.CurrentPage = Items.QuietInstallationPage Then
		Cancel = True;
		If Exit Then
			WarningText = NStr("ru = 'Не завершена установка платформы 1С:Предприятие.';
										|en = 'Installation of 1C:Enterprise platform is not completed.';");
		EndIf;
		Return;
	EndIf;
	
	If Exit Then
		If ValueIsFilled(TimeConsumingOperation) Then
			Cancel               = True;
			WarningText = NStr("ru = 'Получение и установка обновлений не завершены.';
										|en = 'Updates are not completely received and installed.';");
		ElsIf Items.Pages.CurrentPage = Items.UpdateModeSelectionFileMode
			Or Items.Pages.CurrentPage = Items.UpdateModeSelectionServerMode Then
			Cancel               = True;
			WarningText = NStr("ru = 'Не установлено обновление программы.';
										|en = 'Application update is not installed.';");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		// The server call is excluded when terminating the session.
		
		If ValueIsFilled(TimeConsumingOperation) Then
			CancelJobExecution(TimeConsumingOperation.JobID);
		EndIf;
		
		DetachIdleHandler("GetUpdateFilesIteration");
		DetachIdleHandler("DownloadConfigurationUpdate");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region UpdateOptionChoicePage

&AtClient
Procedure UpdateReleaseNotificationOption1OnChange(Item)
	
	SaveUpdateReleaseNotificationOptionAtServer(UpdateReleaseNotificationOption);
	
EndProcedure

&AtClient
Procedure UpdateReleaseNotificationOption2OnChange(Item)
	
	SaveUpdateReleaseNotificationOptionAtServer(UpdateReleaseNotificationOption);
	
EndProcedure

#EndRegion

&AtClient
Procedure LabelHasAccountingErrorsURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	StandardProcessing = False;
	If CommonClient.SubsystemExists("StandardSubsystems.AccountingAudit") Then
		ModuleAccountingAuditClient = CommonClient.CommonModule("AccountingAuditClient");
		ModuleAccountingAuditClient.OpenIssuesReport("SystemChecks");
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateConfigurationOnChange(Item)
	
	UpdateContext       = Undefined;
	UpdateFilesDetails = Undefined;
	OnChangeConfigurationComponentFlagAtServer();
	
EndProcedure

&AtClient
Procedure InstallPatchesOnChange(Item)
	
	UpdateContext       = Undefined;
	UpdateFilesDetails = Undefined;
	OnChangePatchAtServer();
	
EndProcedure

&AtClient
Procedure UpdatePlatformOnChange(Item)
	
	UpdateContext       = Undefined;
	UpdateFilesDetails = Undefined;
	OnChangePlatformFlagAtServer();
	
EndProcedure

&AtClient
Procedure LoginOnChange(Item)
	
	UsernamePasswordChanged = True;
	
EndProcedure

&AtClient
Procedure PasswordOnChange(Item)
	
	UsernamePasswordChanged = True;
	OnlineUserSupportClient.OnChangeSecretData(
		Item);

EndProcedure

&AtClient
Procedure PasswordStartChoice(Item, ChoiceData, StandardProcessing)
	
	OnlineUserSupportClient.ShowSecretData(
		ThisObject,
		Item,
		"Password");
	
EndProcedure

&AtClient
Procedure SavePlatformComponentDistributionPackagesToDirectory1OnChange(Item)
	
	Items.DirectoryToSavePlatformDistributionPackage.Enabled = SavePlatformDistributionPackagesToDirectory;
	If SavePlatformDistributionPackagesToDirectory Then
		DirectoryToSavePlatform = GetApplicationUpdatesClientServer.DirectoryToWorkWithPlatformUpdates();
	Else
		DirectoryToSavePlatform = DefaultPlatformDistributionPackageDirectory();
	EndIf;
	
EndProcedure

&AtClient
Procedure SavePlatformComponentDistributionPackagesToDirectoryOnChange(Item)
	
	Items.DirectoryToSavePlatformComponentDistributionPackage.Enabled = SavePlatformDistributionPackagesToDirectory;
	If SavePlatformDistributionPackagesToDirectory Then
		DirectoryToSavePlatform = GetApplicationUpdatesClientServer.DirectoryToWorkWithPlatformUpdates();
	Else
		DirectoryToSavePlatform = DefaultPlatformDistributionPackageDirectory();
	EndIf;
	
EndProcedure

&AtClient
Procedure DirectoryToSavePlatformComponentDistributionPackageStartChoice(Item, ChoiceData, StandardProcessing)
	
	Select1CEnterpriseDestinationDirectory(Item);
	
EndProcedure

&AtClient
Procedure DirectoryToSavePlatformDistributionPackageStartChoice(Item, ChoiceData, StandardProcessing)
	
	Select1CEnterpriseDestinationDirectory(Item);
	
EndProcedure

&AtClient
Procedure RegisterAt1CITSPortalDecorationClick(Item)
	
	OpenWebPage(
		OnlineUserSupportClientServer.LoginServicePageURL(
			"/registration",
			ConnectionSetup()),
		NStr("ru = 'Регистрация';
			|en = 'Registration';"));
	
EndProcedure

&AtClient
Procedure MigrationFeaturesLabelURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	StandardProcessing = False;
	ProcessURL1(FormattedStringURL);
	
EndProcedure

&AtClient
Procedure InstalledAdditionallyLabelURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	StandardProcessing = False;
	ProcessURL1(FormattedStringURL);
	
EndProcedure

&AtClient
Procedure UpdateAcquisitionErrorMessageDecorationURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	StandardProcessing = False;
	ProcessURL1(FormattedStringURL);
	
EndProcedure

&AtClient
Procedure ErrorFixingRecommendationsDecorationURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	StandardProcessing = False;
	ProcessURL1(FormattedStringURL);
	
EndProcedure

&AtClient
Procedure EmailTechSupportDecorationURLProcessing(Item,
	FormattedStringURL,
	StandardProcessing)
	
	StandardProcessing = False;
	ProcessURL1(FormattedStringURL);
	
EndProcedure

&AtClient
Procedure OpenEventLogDecorationURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	StandardProcessing = False;
	ProcessURL1(FormattedStringURL);
	
EndProcedure

&AtClient
Procedure ServiceMessageDecorationURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	StandardProcessing = False;
	ProcessURL1(FormattedStringURL);
	
EndProcedure

&AtClient
Procedure InstallationCompleteInformationDecorationURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	StandardProcessing = False;
	ProcessURL1(FormattedStringURL);
	
EndProcedure

&AtClient
Procedure TheDecorationOfThePageIsSetToCreateARCURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	StandardProcessing = False;
	ProcessURL1(FormattedStringURL);
	
EndProcedure

&AtClient
Procedure TheDecorationOfThePageIsSetNotToCreateRCURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	StandardProcessing = False;
	ProcessURL1(FormattedStringURL);
	
EndProcedure

&AtClient
Procedure DecorationPageCompletedCreateRCURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	StandardProcessing = False;
	ProcessURL1(FormattedStringURL);
	
EndProcedure

&AtClient
Procedure DecorationPageCompletedDoNotCreateRCURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	StandardProcessing = False;
	ProcessURL1(FormattedStringURL);
	
EndProcedure

&AtClient
Procedure CreateBackupSetOnChange(Item)
	
	If CreateBackup Then
		Items.InstructionInstallationInstalledPages.CurrentPage = Items.InstalledCreateBackupPage;
	Else
		Items.InstructionInstallationInstalledPages.CurrentPage = Items.InstalledDoNotCreateBackupPage;
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateBackupOnChange(Item)
	
	If CreateBackup Then
		Items.PagesInstructionInstallationCompleted.CurrentPage = Items.CompletedCreateBackupPage;
	Else
		Items.PagesInstructionInstallationCompleted.CurrentPage = Items.CompletedDoNotCreateBackupPage;
	EndIf;
	
EndProcedure

&AtClient
Procedure BackupFileLabelClick(Item)
	
	// StandardSubsystems.ConfigurationUpdate
	ConfigurationUpdateClient.ShowBackup(
		New Structure("CreateDataBackup, IBBackupDirectoryName, RestoreInfobase",
			CreateDataBackup,
			IBBackupDirectoryName,
			RestoreInfobase),
		New NotifyDescription("OnChangeBackupParameters", ThisObject));
	// End StandardSubsystems.ConfigurationUpdate
	
EndProcedure

&AtClient
Procedure UpdateRadioButtonsFileOnChange(Item)
	
	DisplayUpdateReceiptComplete();
	
EndProcedure

&AtClient
Procedure UpdateRadioButtonsServerOnChange(Item)
	
	DisplayUpdateReceiptComplete();
	
EndProcedure

&AtClient
Procedure DeferredHandlersLabelURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	StandardProcessing = False;
	InfobaseUpdateClient.ShowDeferredHandlers();
	
EndProcedure

&AtClient
Procedure EmailReportOnChange(Item)
	
	DisplayUpdateReceiptComplete();
	
EndProcedure

&AtClient
Procedure ActionsListLabel2Click(Item)
	
	ShowActiveUsers();
	
EndProcedure

&AtClient
Procedure ActionsListLabel4Click(Item)
	
	ShowActiveUsers();
	
EndProcedure

&AtClient
Procedure DecorationPatchesErrorsBeingCorrectedClick(Item)
	
	SelectedUpdateID = ?(UpdateConfiguration,
		UpdateOption,
		CurrentVersionID());
	SelectedUpdate               = UpdatesOptions[SelectedUpdateID];
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressPatchesDetails", PatchAddress);
	FormParameters.Insert("SelectedPatches"    , SelectedUpdate.SelectedPatches);
	FormParameters.Insert("ListOfCorrections"       , SelectedUpdate.ListOfCorrections);
	FormParameters.Insert("ReadOnly"          , Items.InstallPatches.ReadOnly);
	
	OpenForm("DataProcessor.ApplicationUpdate.Form.CorrectionsSelection",
		FormParameters,
		ThisObject,
		,
		,
		,
		New NotifyDescription("OnSelectPatches", ThisObject, SelectedUpdateID));
	
EndProcedure

&AtClient
Procedure ActiveUsersDecorationURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	StandardProcessing = False;
	ShowActiveUsers();
	
EndProcedure

&AtClient
Procedure InstallUpdateFromFileDecoration1Click(Item)
	
	InstallUpdateFromFile();
	
EndProcedure

&AtClient
Procedure InstallUpdateFromFileDecoration2Click(Item)
	
	InstallUpdateFromFile();
	
EndProcedure

&AtClient
Procedure ImportAndInstallCorrectionsAutomaticallyOnChange(Item)
	
	IsFlagSaved = SaveFlagOfPatchAutoDownloadAndInstallationAtServer(
		ImportAndInstallCorrectionsAutomatically);
	If IsFlagSaved Then
		Items.CorrectionsImportDecorationSchedule.Enabled =
			ImportAndInstallCorrectionsAutomatically;
	Else
			
		ImportAndInstallCorrectionsAutomatically = False;
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("ru = 'Подключить';
													|en = 'Enable';"));
		Buttons.Add(DialogReturnCode.Cancel);
		ShowQueryBox(
			New NotifyDescription(
				"OnAnswerPatchQuestionEnableOnlineSupportOnEnablePatchesInstallation",
				ThisObject),
			NStr("ru = 'Для автоматического получения и установки исправлений (патчей)
				|необходимо подключить Интернет-поддержку пользователей.';
				|en = 'Enable online support to get and install patches automatically.
				|';"),
			Buttons);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CorrectionsImportDecorationScheduleClick(Item)
	
	// ACC:574-off Mobile client doesn't use this code.
	Schedule = GetApplicationUpdatesServerCall.PatchesInstallationJobSchedule();
	ScheduleDialog = New ScheduledJobDialog(Schedule);
	NotifyDescription = New NotifyDescription(
		"OnChangePatchInstallationSchedule",
		ThisObject);
	ScheduleDialog.Show(NotifyDescription);
	// ACC:574-on
	
EndProcedure

&AtClient
Procedure LabelHasUnappliedCorrectionsURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	StandardProcessing = False;
	Exit(True, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure BackCommand(Command)
	
	CurPage = Items.Pages.CurrentPage;
	If (CurPage = Items.AvailablePlatformVersionPage
		Or CurPage = Items.PlatformAlreadyInstalledPage)
		And IsNotRecommendedPlatformVersionMessageScenario(ThisObject) Then
		DisplayNotRecommendedPlatformVersion();
	Else
		// The update information is already received.
		DisplayInformationOnAvailableUpdate();
	EndIf;
	
EndProcedure

&AtClient
Procedure NextCommand(Command)
	
	RunNextCommandDataProcessor();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	CloseParameter = Undefined;
	If IsNotRecommendedPlatformVersionMessageScenario(ThisObject)
		And Items.Pages.CurrentPage = Items.NoNewPlatformVersionAvailablePage
		And Not UpdatesOptions[UpdateOption].Platform.UpdateAvailable Then
		
		CloseParameter = "Continue";
		
	EndIf;
	
	Close(CloseParameter);
	
EndProcedure

&AtClient
Procedure ContinueWorkingWithCurrentVersion(Command)
	
	GetApplicationUpdatesServerCall.SaveNotificationSettingsOfNonRecommendedPlatformVersion();
	Close("Continue");
	
EndProcedure

&AtClient
Procedure ActiveUsers(Command)
	
	ShowActiveUsers();
	
EndProcedure

&AtClient
Procedure Download1CEnterpriseDistributionPackage(Command)
	
	SelectedUpdate  = UpdatesOptions[UpdateOption];
	PlatformPageURL = SelectedUpdate.Platform.PlatformPageURL;
	
	If IsBlankString(PlatformPageURL) Then
		ShowMessageBox(, NStr("ru = 'Адрес страницы новой версии платформы не определен.';
										|en = 'Page address of the new platform version is not determined.';"));
		Return;
	EndIf;
	
	If IsSystemAdministrator And StrFind(PlatformPageURL, "needAccessToken") = 0 Then
		PlatformPageURL = PlatformPageURL
			+ ?(StrFind(PlatformPageURL, "?") > 0, "&", "?")
			+ "needAccessToken=true";
	EndIf;
	
	OpenWebPage(PlatformPageURL);
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Common.

// It is used to avoid visibility
// of several pages at the same time.
&AtClientAtServerNoContext
Procedure DisplayPage(Pages, Page)
	
	If Not Page.Visible Then
		Page.Visible = True;
	EndIf;
	
	Pages.CurrentPage = Page;
	
EndProcedure

&AtClient
Procedure ProcessURL1(Ref)
	
	If Ref = "open:RCInstruction" Then
		
		OpenInternalInstructionFile(
			"InfobaseBackupCreation_en",
			NStr("ru = 'Создание резервной копии.htm';
				|en = 'Creating backup.htm';"));
		
	ElsIf Ref = "open:V8Update" Then
		
		SelectedUpdate = UpdatesOptions[UpdateOption];
		OpenWebPage(
			SelectedUpdate.Platform.URLTransitionFeatures,
			NStr("ru = 'Особенности перехода на новую версию платформы 1С:Предприятие';
				|en = 'Features of migrating to a new version of 1C:Enterprise platform';"));
		
	ElsIf Ref = "open:DistribFolder" Then
		
		FileSystemClient.OpenExplorer(UpdateContext.PlatformDistributionPackageDirectory);
		
	ElsIf Ref = "open:ActiveUsers" Then
		
		NameOfFormToOpen_ = "DataProcessor.ActiveUsers.Form.ActiveUsers";
		OpenForm(NameOfFormToOpen_, New Structure("ExclusiveModeSettingError", True));
		
	ElsIf Ref = "open:ProxySettings" Then
		
		OpenForm("CommonForm.ProxyServerParameters",
			New Structure("ProxySettingAtClient", True),
			ThisObject);
		
	ElsIf Lower(Left(Ref, 22)) = "mailto:webits-info@1c." Then
		
		SendMessageToTechSupport("webIts");
		
	ElsIf Lower(Left(Ref, 7)) = "mailto:" Then
		
		FileSystemClient.OpenURL(Ref);
		
	ElsIf Ref = "open:log" Then
		
		OpenForm("DataProcessor.EventLog.Form", New Structure("User", UserName()));
		
	ElsIf Ref = "open:debuglog" Then
		
		FileSystemClient.OpenFile(UpdateContext.ProtocolFilePath);
	ElsIf Ref = "action:retruupdateplatfom" Then
		PlatformInstallationMode = 1;
		RunNextCommandDataProcessor();
	ElsIf Lower(Left(Ref, 7)) = "http://"
		Or Lower(Left(Ref, 8)) = "https://" Then
		
		OpenWebPage(Ref);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenWebPage(PageAddress, WindowTitle = "")
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("WindowTitle"              , WindowTitle);
	OpeningParameters.Insert("Login"                      , Login);
	OpeningParameters.Insert("Password"                     , Password);
	OpeningParameters.Insert("IsFullUser", IsSystemAdministrator);
	OpeningParameters.Insert("ConnectionSetup"        , ServersConnectionSettings);
	
	OnlineUserSupportClient.OpenWebPageWithAdditionalParameters(
		PageAddress,
		OpeningParameters);
	
EndProcedure

&AtClient
Procedure SendMessageToTechSupport(RecipientAddress)
	
	If IsScenarioOfMigrationToNewPlatformVersion(ThisObject)
		Or IsNotRecommendedPlatformVersionMessageScenario(ThisObject) Then
		Subject = NStr("ru = 'Интернет-поддержка. Переход на новую версию Платформы 1С:Предприятие';
					|en = 'Online support. Migration to a new version of 1C:Enterprise Platform';");
	Else
		Subject = NStr("ru = 'Интернет-поддержка. Обновление программы';
					|en = 'Online support. Application update';");
	EndIf;
	Attachments = Undefined;
	
	If Items.Pages.CurrentPage = Items.ConnectionToPortalPage Then
		
		If Items.ConnectionFailurePanel.Visible Then
			ReasonDetails = OnlineUserSupportClient.FormattedHeaderText(
				Items.UpdateAcquisitionErrorMessageDecoration.Title);
		Else
			ReasonDetails = "";
		EndIf;
		
		Message = NStr("ru = 'Не удалось подключиться к Порталу 1С:ИТС.';
						|en = 'Cannot connect to 1C:ITS Portal.';")
			+ ?(IsBlankString(ReasonDetails),
				"",
				Chars.LF + Chars.LF + NStr("ru = 'Описание:';
												|en = 'Details:';") + Chars.LF + ReasonDetails);
		
	ElsIf Items.Pages.CurrentPage = Items.ServerConnectionFailedPage Then
		
		Message = NStr("ru = 'Ошибка при подключении сервиса автоматического обновления программы.';
						|en = 'An error occurred when connecting to the automatic application update service.';")
			+ ?(IsBlankString(DetailedErrorDetails),
				"",
				Chars.LF + Chars.LF + NStr("ru = 'Описание:';
												|en = 'Details:';") + Chars.LF + DetailedErrorDetails);
		
	ElsIf Items.Pages.CurrentPage = Items.ServiceMessagePage Then
		
		If IsBlankString(DetailedErrorDetails) Then
			Message = NStr("ru = 'Сообщение при подключении сервиса автоматического обновления программы:';
							|en = 'Message when connecting to the automatic application update service:';")
				+ Chars.LF
				+ OnlineUserSupportClient.FormattedHeaderText(
					Items.ServiceMessageDecoration.Title);
		Else
			
			If UpdateContext <> Undefined
				And Not IsBlankString(UpdateContext.ProtocolFilePath) Then
				
				Attachments = New Array;
				If GetApplicationUpdatesClientServer.FileExists(UpdateContext.ProtocolFilePath) Then
					Attachments.Add(
						New Structure("Presentation, FileName",
							NStr("ru = 'Протокол установки платформы 1С_Предприятие.txt';
								|en = 'Platform installation protocol 1C:Enterprise.txt';"),
							UpdateContext.ProtocolFilePath));
				EndIf;
				
			EndIf;
			
			If IsScenarioOfMigrationToNewPlatformVersion(ThisObject)
				Or IsNotRecommendedPlatformVersionMessageScenario(ThisObject) Then
				
				Message = NStr("ru = 'Ошибка при получении и установке платформы 1С:Предприятие:';
								|en = 'An error occurred while receiving and installing 1C:Enterprise platform:';")
					+ Chars.LF
					+ DetailedErrorDetails;
				
			Else
				
				Message = NStr("ru = 'Не удалось обновить программу.';
								|en = 'Application update failed.';")
					+ Chars.LF
					+ NStr("ru = 'Причина:';
							|en = 'Reason:';")
					+ Chars.LF
					+ DetailedErrorDetails;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If CommonClient.SubsystemExists("OnlineUserSupport.MessagesToTechSupportService") Then
		
		TheModuleOfTheMessageToTheTechnicalSupportServiceClientServer =
			CommonClient.CommonModule("MessagesToTechSupportServiceClientServer");
		MessageData = TheModuleOfTheMessageToTheTechnicalSupportServiceClientServer.MessageData();
		MessageData.Recipient = "webIts";
		MessageData.Subject       = Subject;
		MessageData.Message  = Message;
		
		TheModuleOfTheMessageToTheTechnicalSupportServiceClient =
			CommonClient.CommonModule("MessagesToTechSupportServiceClient");
		TheModuleOfTheMessageToTheTechnicalSupportServiceClient.SendMessage(
			MessageData,
			AttachmentsToTechSupport);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenIBBackupCreation()
	
	If CommonClient.SubsystemExists("StandardSubsystems.IBBackup") Then
		ModuleIBBackupClient = CommonClient.CommonModule("IBBackupClient");
		FormParameters = New Structure("BinDir", PlatformInstallationDirectory);
		ModuleIBBackupClient.OpenBackupForm(FormParameters);
	Else
		MessageText = NStr("ru = 'Не встроена подсистема ""Резервное копирование ИБ"".';
								|en = 'The ""IB backup"" subsystem is not embedded.';");
		GetApplicationUpdatesServerCall.WriteErrorToEventLog(MessageText);
		ShowMessageBox(, MessageText);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenInternalInstructionFile(TemplateName, FileName)
	
	#If Not WebClient Then
	InstructionFilePath = PrepareInstructionTemplateFile(TemplateName, FileName);
	
	// Opening the instruction in the default browser.
	Try
		FileSystemClient.OpenFile(InstructionFilePath);
	Except
		GetApplicationUpdatesServerCall.WriteErrorToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при открытии внутреннего файла инструкции (%1).
					|%2';
					|en = 'An error occurred while opening an internal instruction file (%1).
					|%2';"),
				FileName,
				ErrorProcessing.DetailErrorDescription(ErrorInfo())));
		ShowMessageBox(, NStr("ru = 'Ошибка при открытии файла.';
										|en = 'An error occurred while opening the file.';"));
		Return;
	EndTry;
	
	#EndIf
	
EndProcedure

&AtClient
Procedure InstallUpdateFromFile()
	
	// StandardSubsystems.ConfigurationUpdate
	// Call the API to install a configuration update from a file.
	Close();
	ConfigurationUpdateClient.ShowUpdateSearchAndInstallation();
	// End StandardSubsystems.ConfigurationUpdate
	
EndProcedure

&AtServerNoContext
Function PrepareInstructionTemplateFile(Val TemplateName, Val FileName)
	
	If Not GetApplicationUpdates.InternalCanUsePlatformUpdatesReceipt() Then
		Raise
			NStr("ru = 'Использование обновления платформы 1С:Предприятие недоступно в текущем режиме работы.';
				|en = '1C:Enterprise platform update cannot be used in the current operation mode.';");
	EndIf;
	
	// Write the file to the user's computer in the server context
	// as this mechanism is used only in file mode.
	
	DirectoryToWorkWithUpdates =
		GetApplicationUpdatesClientServer.DirectoryToWorkWithPlatformUpdates();
	
	If Not GetApplicationUpdatesClientServer.FileExists(DirectoryToWorkWithUpdates) Then
		Try
			CreateDirectory(DirectoryToWorkWithUpdates);
		Except
			GetApplicationUpdatesServerCall.WriteErrorToEventLog(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка при создании каталога для работы с обновлениями платформы 1С:Предприятие (%1).
						|%2';
						|en = 'An error occurred while creating a directory for working with updates of 1C:Enterprise platform (%1). 
						|%2';"),
					DirectoryToWorkWithUpdates,
					ErrorProcessing.DetailErrorDescription(ErrorInfo())));
			Raise NStr("ru = 'Ошибка при создании временного каталога.';
									|en = 'An error occurred when creating a temporary directory.';");
		EndTry;
	EndIf;
	
	InstructionFilePath = DirectoryToWorkWithUpdates + FileName;
	Try
		TextWriter = New TextWriter(InstructionFilePath);
		TextWriter.Write(DataProcessors.ApplicationUpdate.GetTemplate(TemplateName).GetText());
		TextWriter.Close();
	Except
		GetApplicationUpdatesServerCall.WriteErrorToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при записи данных макета инструкции в файл на диске (%1).
					|%2';
					|en = 'An error occurred while saving instruction template data to the file on the disk (%1).
					|%2';"),
				FileName,
				ErrorProcessing.DetailErrorDescription(ErrorInfo())));
		Raise NStr("ru = 'Ошибка при создании временного файла.';
								|en = 'An error occurred while creating a temporary file. ';");
	EndTry;
	
	Return InstructionFilePath;
	
EndFunction

&AtClientAtServerNoContext
Function IsConnectionError(ErrorCode)
	
	Return (ErrorCode = "ConnectError" Or ErrorCode = "ServerError" Or ErrorCode = "ClientError");
	
EndFunction

&AtClientAtServerNoContext
Function IsScenarioOfMigrationToNewPlatformVersion(Form)
	
	Return (Form.Scenario = "MigrationToNewPlatformVersion");
	
EndFunction

&AtClientAtServerNoContext
Function IsNotRecommendedPlatformVersionMessageScenario(Form)
	
	Return (Form.Scenario = "NotRecommendedPlatformVersionMessage");
	
EndFunction

&AtClientAtServerNoContext
Function IsScenarioOfMigrationToOtherApplicationOrEdition(Form)
	
	Return (Form.Scenario = "MigrationToAnotherApplicationOrRevision");
	
EndFunction

&AtClientAtServerNoContext
Function IsApplicationUpdateScenario(Form)
	
	Return (Form.Scenario = "ApplicationUpdate1");
	
EndFunction

&AtClient
Function ConnectionSetup()
	
	If ServersConnectionSettings = Undefined Then
		Return OnlineUserSupportClient.ServersConnectionSettings();
	Else
		Return ServersConnectionSettings;
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function UpdateReceiptComplete(WizardForm)
	
	Return (WizardForm.UpdateContext <> Undefined
		And WizardForm.UpdateContext.Completed);
	
EndFunction

&AtClient
Procedure InstallConfigurationUpdate()
	
	PatchesFilesToPlace = New Array;
	If InstallPatches Then
		For Each CurPatch In UpdateContext.Corrections Do
			If IsBlankString(CurPatch.FileAddress) Then
				PatchesFilesToPlace.Add(
					New TransferableFileDescription(CurPatch.ReceivedFileName));
			EndIf;
		EndDo;
	EndIf;
	
	If PatchesFilesToPlace.Count() = 0 Then
		BeginSettingUpdates();
	Else
		Status(, , NStr("ru = 'Пожалуйста, подождите...';
							|en = 'Please wait…';"));
		
		ImportParameters = FileSystemClient.FileImportParameters();
		ImportParameters.Interactively = False;
		ImportParameters.FormIdentifier = New UUID;
		
		FileSystemClient.ImportFiles(
			New NotifyDescription("BeginSettingUpdates", ThisObject),
			ImportParameters,
			PatchesFilesToPlace);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeginSettingUpdates(
	PlacedPatchesFiles = Undefined,
	AdditionalParameters = Undefined) Export
	
	Status();
	If PlacedPatchesFiles <> Undefined Then
		For Each CurPatchFile In PlacedPatchesFiles Do
			For Each CurPatch In UpdateContext.Corrections Do
				If CurPatch.ReceivedFileName = CurPatchFile.FullName Then
					CurPatch.FileAddress = CurPatchFile.Location;
					Break;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	InstallationParameters = ConfigurationUpdateInstallationParameters();
	
	UpdatesFilesDetailsStr = "";
	For Each CurFile In InstallationParameters.FilesOfUpdate Do
		UpdatesFilesDetailsStr = UpdatesFilesDetailsStr + Chars.LF
			+ "  " + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Имя файла: %1, Выполнить обработчики обновления: %2;';
					|en = 'File name: %1, Run update data processors: %2;';"),
				CurFile.UpdateFileFullName,
				CurFile.RunUpdateHandlers);
	EndDo;
	
	PatchesFilesNames = New Array;
	For Each CurPatch In UpdateContext.Corrections Do
		PatchesFilesNames.Add(CurPatch.ReceivedFileName);
	EndDo;
	
	EventLogMessage = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Вызов интерфейса установки обновления (СтандартныеПодсистемы.ОбновлениеКонфигурации).
			|Файлы обновления конфигурации: %1;
			|Файлы исправлений (патчей): %2;
			|Удалить исправления (патчи): %3;
			|Платформа 1С:Предприятие: %4';
			|en = 'Call the update installation interface (StandardSubsystems.ConfigurationUpdate).
			|Configuration update files: %1;
			|Patch files: %2;
			|Patches to delete: %3;
			| 1C:Enterprise Platform: %4';"),
			UpdatesFilesDetailsStr,
			StrConcat(PatchesFilesNames, ","),
			StrConcat(InstallationParameters.Corrections.Delete),
			InstallationParameters.PlatformDirectory);
	GetApplicationUpdatesClient.WriteInformationToEventLog(EventLogMessage);
	
	// Integration with "Monitoring center" subsystem.
	If InformationTransferToMonitoringCenter
		And CommonClient.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
		EnableTheUseOfTheMonitoringCenter();
	EndIf;
	
	// Calling the API to install the configuration update.
	ConfigurationUpdateClient.InstallUpdate(
		ThisObject,
		InstallationParameters,
		AdministrationParameters);
	
EndProcedure

&AtClient
Function ConfigurationUpdateInstallationParameters()
	
	Result = New Structure;
	Result.Insert("UpdateMode"                  , UpdateMode);
	Result.Insert("ShouldExitApp"          , False);
	Result.Insert("UpdateDateTime"              , UpdateDateTime);
	Result.Insert("EmailReport"              , EmailReport);
	Result.Insert("Email"            , Email);
	Result.Insert("SchedulerTaskCode"            , SchedulerTaskCode);
	Result.Insert("UpdateFileName"               , "");
	Result.Insert("CreateDataBackup"          , CreateDataBackup);
	Result.Insert("IBBackupDirectoryName"      , IBBackupDirectoryName);
	Result.Insert("RestoreInfobase", RestoreInfobase);
	Result.Insert("PlatformDirectory"                 , "");
	
	If UpdatePlatform Then
		SelectedUpdate        = UpdatesOptions[UpdateOption];
		Result.PlatformDirectory = GetApplicationUpdatesClientServer.OneCEnterprisePlatformInstallationDirectory(
			SelectedUpdate.Platform.Version);
	Else
		
	EndIf;
	
	FilesOfUpdate = New Array;
	For Each CurFile In UpdateContext.ConfigurationUpdates Do
		FilesOfUpdate.Add(
			New Structure("UpdateFileFullName, RunUpdateHandlers",
				CurFile.FullNameOfCFUFileInDistributionDirectory,
				CurFile.ApplyUpdateHandlers));
	EndDo;
	Result.Insert("FilesOfUpdate", FilesOfUpdate);
	
	PatchesInstall = New Array;
	For Each CurPatch In UpdateContext.Corrections Do
		PatchesInstall.Add(CurPatch.FileAddress);
	EndDo;
	
	Result.Insert("Corrections",
		New Structure("Set, Delete",
			PatchesInstall,
			UpdateContext.RevokedPatches));
	
	Return Result;
	
EndFunction

&AtClient
Procedure ShowActiveUsers()
	
	// StandardSubsystems.Core
	FormParameters = New Structure;
	FormParameters.Insert("NotifyOnClose", True);
	StandardSubsystemsClient.OpenActiveUserList(FormParameters, ThisObject);
	// End StandardSubsystems.Core
	
EndProcedure

&AtServer
Function IsConfigurationUpdateFlagNonEditable()
	
	Return MultipleVersionsAvailableForUpdate()
		And Not (UpdateOption = CurrentVersionID()
		Or UpdateOption = CurrentVersionNewBuildID());
	
EndFunction

&AtServer
Function MultipleVersionsAvailableForUpdate()
	
	If UpdatesOptions.Count() > 2 Then
		Return True;
	ElsIf ValueIsFilled(AvailableUpdateInformation.EndOfCurrentVersionSupport)
		And AvailableUpdateInformation.EndOfCurrentVersionSupport > CurrentSessionDate() Then
		
		UpToDateVerOption = UpdatesOptions[UpToDateVersionID()];	// See NewUpdateOption
		If UpToDateVerOption.Configuration = Undefined
			Or Not UpToDateVerOption.Configuration.UpdateAvailable Then
			
			Return False;
			
		EndIf;
		
		CurrentVersion    = CommonClientServer.ConfigurationVersionWithoutBuildNumber(
			OnlineUserSupport.ConfigurationVersion());
		LatestVersion = CommonClientServer.ConfigurationVersionWithoutBuildNumber(
			UpToDateVerOption.Configuration.Version);
		
		Return CurrentVersion <> LatestVersion;
		
	EndIf;
	
	Return False;
	
EndFunction

// A new object of the update option.
//
// Parameters:
//  VersionID - String
//  VersionNumberWithoutBuild - String
//  EndOfSupport - Undefined - Long-term support is discontinued for the current version.
//                     - Date - The date when support for the current version will be discontinued.
//
// Returns:
//  Structure:
//    * Configuration - Undefined - Configuration update is unavailable.
//                   - Structure of KeyAndValue - Configuration update information.
//    * Platform - Undefined - 1C:Enterprise update is unavailable.
//                - Structure of KeyAndValue - 1C:Enterprise update information.
//    * SelectedPatches - ValueList of String - A list of ids of patches selected for installation.
//    * ListOfCorrections - ValueList of String - A list of patches available for installation.
//    * UpdateTitle - String - The update option details.
//    * UpdateTooltip - String - An update option tooltip.
//
&AtServerNoContext
Function NewUpdateOption(VersionID, VersionNumberWithoutBuild, EndOfSupport)
	
	Result = New Structure();
	Result.Insert("Configuration"         , Undefined);
	Result.Insert("Platform"            , Undefined);
	Result.Insert("SelectedPatches" , New ValueList());
	Result.Insert("ListOfCorrections"    , New ValueList());
	Result.Insert("UpdateTitle"  , "");
	Result.Insert("UpdateTooltip"  , "");
	
	SupportEndPresentation = ?(ValueIsFilled(EndOfSupport),
		Format(EndOfSupport, "DLF=DD"),
		"");
	
	If VersionID = CurrentVersionID()
		Or VersionID = CurrentVersionNewBuildID() Then
		
		If ValueIsFilled(EndOfSupport) Then
			Result.UpdateTitle = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Обновить текущую версию %1 (поддержка до %2)';
					|en = 'Update the current version: %1 (supported until %2)';"),
				VersionNumberWithoutBuild,
				SupportEndPresentation);
			Result.UpdateTooltip = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'До %1 будут выпускаться версии с исправлением ошибок и поддержкой законодательных изменений.';
					|en = 'Versions with bug fixes and legislative updates will be released up to version %1.';"),
				VersionNumberWithoutBuild);
		Else
			Result.UpdateTitle = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Обновить текущую версию %1';
					|en = 'Update the current version: %1';"),
				VersionNumberWithoutBuild);
		EndIf;
		
	ElsIf VersionID = UpToDateVersionID() Then
		
		Result.UpdateTitle = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Перейти на новую версию %1 (актуальная версия)';
				|en = 'Migrate to the new version: %1 (the latest version)';"),
			VersionNumberWithoutBuild);
		
	Else
		
		Result.UpdateTitle = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Перейти на новую версию %1 (поддержка до %2)';
				|en = 'Migrate to the new version: %1 (supported until %2)';"),
			VersionNumberWithoutBuild,
			SupportEndPresentation);
		Result.UpdateTooltip = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'До %1 будут выпускаться версии с исправлением ошибок и поддержкой законодательных изменений.';
				|en = 'Versions with bug fixes and legislative updates will be released up to version %1.';"),
			SupportEndPresentation);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function CurrentVersionID()
	
	Return "CurrentVersion";
	
EndFunction

&AtClientAtServerNoContext
Function CurrentVersionNewBuildID()
	
	Return "CurrentVersionNewBuild";
	
EndFunction

&AtClientAtServerNoContext
Function UpToDateVersionID()
	
	Return "LatestVersion";
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Integration with "Monitoring center" subsystem.

&AtServer
Procedure ConfigureTheDisplayOfIntegrationWithTheMonitoringCenter()
	
	If Common.SubsystemExists("StandardSubsystems.MonitoringCenter")Then
		ModuleMonitoringCenter = Common.CommonModule("MonitoringCenter");
		If ModuleMonitoringCenter.MonitoringCenterEnabled() Then
			Items.GroupMonitoringCenterServerMode.Visible = False;
			Items.GroupMonitoringCenterFileMode.Visible  = False;
		Else
			InformationTransferToMonitoringCenter = True;
		EndIf;
	Else
		Items.GroupMonitoringCenterServerMode.Visible = False;
		Items.GroupMonitoringCenterFileMode.Visible  = False;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure EnableTheUseOfTheMonitoringCenter()
	
	If Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
		ModuleMonitoringCenter = Common.CommonModule("MonitoringCenter");
		ModuleMonitoringCenter.EnableSubsystem();
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Step of available update information.

&AtClient
Procedure RunNextCommandDataProcessor()
	
	CurPage = Items.Pages.CurrentPage;
	
	If CurPage = Items.NoNewPlatformVersionAvailablePage Then
		Close();
		Return;
	EndIf;
	
	If CurPage = Items.PlatformAlreadyInstalledPage
		Or CurPage = Items.PlatformInstallationCompletedPage Then
		
		If CreateBackup Then
			If IsNotRecommendedPlatformVersionMessageScenario(ThisObject) Then
				// If this 1C:Enterprise version is not recommended,
				// don't close the dialog as this will cause the app to exit.
				OpenIBBackupCreation();
			Else
				Close();
				OpenIBBackupCreation();
			EndIf;
		Else
			Close();
		EndIf;
		
		Return;
		
	EndIf;
	
	If CurPage = Items.PlatformVersionNotRecommendedPage Then
		
		GetAndDisplayInformationOnAvailableUpdate();
		
	ElsIf CurPage = Items.AvailablePlatformVersionPage Then
		
		If Not IsFileIB Then
			// In the client/server mode, the user can see only the download link,
			// and the "Next" button's title reads "Done".
			// 
			Close();
			Return;
		EndIf;
		
		// File mode handler.
		If Items.DirectoryToSavePlatformGroup.Visible
			And SavePlatformDistributionPackagesToDirectory Then
			If IsBlankString(DirectoryToSavePlatform) Then
				CommonClient.MessageToUser(
					NStr("ru = 'Не выбран каталог хранения дистрибутивов платформы.';
						|en = 'Directory for storing platform distributions is not selected.';"),
					,
					"DirectoryToSavePlatformDistributionPackage");
				Return;
			EndIf;
		EndIf;
		
		StartGetUpdates();
		
	ElsIf CurPage = Items.UpdateOptionChoicePage Then
		
		If IsBlankString(UpdateOption) Then
			CommonClient.MessageToUser(
				NStr("ru = 'Не выбран вариант обновления.';
					|en = 'An update option is not selected.';"));
		Else
			DisplayInformationOnComponentsUpdate(True);
		EndIf;
		
	ElsIf CurPage = Items.InformationOnAvailableComponentUpdatePage Then
		
		// Update add-ins.
		If Not UpdateConfiguration
			And Not InstallPatches
			And Not IsFileIB And UpdatePlatform Then
			// If the "Next" button is unavailable and the configuration doesn't update,
			// then 1C:Enterprise is selected and the button title reads "Done".
			Close();
			Return;
		EndIf;
		
		// File mode handler.
		If UpdatePlatform
			And Items.DirectoryToSavePlatformComponentGroup.Visible
			And SavePlatformDistributionPackagesToDirectory Then
			If IsBlankString(DirectoryToSavePlatform) Then
				CommonClient.MessageToUser(
					NStr("ru = 'Не выбран каталог хранения дистрибутивов платформы.';
						|en = 'Directory for storing platform distributions is not selected.';"),
					,
					"DirectoryToSavePlatformComponentDistributionPackage");
				Return;
			EndIf;
		EndIf;
		
		StartGetUpdates();
		
	ElsIf CurPage = Items.ConnectionToPortalPage Then
		
		ClearMessages();
		
		Result = OnlineUserSupportClientServer.VerifyAuthenticationData(
			New Structure("Login, Password",
			Login, Password));
	
		If Result.Cancel Then
			CommonClient.MessageToUser(
				Result.ErrorMessage,
				,
				Result.Field);
		EndIf;
		
		If Result.Cancel Then
			Return;
		EndIf;
		
		StartGetUpdates();
		
	ElsIf CurPage = Items.ServerConnectionFailedPage
		Or CurPage = Items.ServiceMessagePage Then
		
		// The "Next" button's title reads either "Retry" or "Install with manual settings"
		// (in case of a security policy error).
		If Not IsBlankString(AvailableUpdateInformation.ErrorName) Then
			
			// Retrying to get update information.
			GetAndDisplayInformationOnAvailableUpdate();
			
		ElsIf UpdateFilesDetails <> Undefined
			And Not IsBlankString(UpdateFilesDetails.ErrorName)
			Or UpdateContext <> Undefined
			And Not IsBlankString(UpdateContext.ErrorName) Then
			
			// 1. Retry to get the information on the file updates and start the import.
			// 2. If a file acquisition/1C:Enterprise installation error occurred,
			// retry getting the update files/installing 1C:Enterprise.
			// 
			StartGetUpdates();
			
		EndIf;
		
	ElsIf CurPage = Items.PageInstallCorrections Then
		
		If RestartApplication Then
			Exit(True, True);
		Else
			Close();
		EndIf;
		
	ElsIf CurPage = Items.UpdateModeSelectionFileMode
		Or CurPage = Items.UpdateModeSelectionServerMode Then
		
		// Call the "StandardSubsystems.ConfigurationUpdate" API to install updates.
		// 
		InstallConfigurationUpdate();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GetAndDisplayInformationOnAvailableUpdate()
	
	Status(, , NStr("ru = 'Получение информации о доступном обновлении';
						|en = 'Getting available update information';"));
	GetAndDisplayInformationOnAvailableUpdateAtServer();
	Status();
	
EndProcedure

&AtServer
Function NewAvailableUpdateInformation()
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ConnectionSetup",
		OnlineUserSupport.ServersConnectionSettings());
	AdditionalParameters.Insert("OnlyPatches"  , Not IsWindowsClient);
	Return GetApplicationUpdates.AvailableUpdateInformationInternal(
		OnlineUserSupport.ApplicationName(),
		OnlineUserSupport.ConfigurationVersion(),
		NewApplicationName,
		NewEditionNumber,
		Scenario,
		AdditionalParameters);
	
EndFunction

&AtServer
Procedure GetAndDisplayInformationOnAvailableUpdateAtServer()
	
	InformationOnUpdate1 = NewAvailableUpdateInformation();
	FillInformationOnUpdate(InformationOnUpdate1);
	DisplayInformationOnAvailableUpdate(True);
	
EndProcedure

// Initializes the app update wizard.
//
// Parameters:
//  InformationOnUpdate1 - See GetApplicationUpdates.AvailableUpdateInformationInternal
//
&AtServer
Procedure FillInformationOnUpdate(InformationOnUpdate1)
	
	Corrections = InformationOnUpdate1.Corrections;
	If Corrections = Undefined Then
		PatchAddress = "";
	ElsIf IsBlankString(PatchAddress) Then
		PatchAddress = PutToTempStorage(Corrections, UUID);
	Else
		PutToTempStorage(Corrections, PatchAddress);
	EndIf;
	
	InformationOnUpdate1.Delete("Corrections");
	AvailableUpdateInformation = InformationOnUpdate1;
	
	// Populate the available update options
	UpdateOptionsList = New Map();
	VersionsUpdateOptions  = New Map();
	CurrentApplicationName       = OnlineUserSupport.ApplicationName();
	CurrentApplicationVersion    = OnlineUserSupport.ConfigurationVersion();
	CurrentVersionWithoutBuild    = CommonClientServer.ConfigurationVersionWithoutBuildNumber(CurrentApplicationVersion);
	
	// Add the current version information.
	InfoAboutUpdateOption = NewUpdateOption(
		CurrentVersionID(),
		CurrentVersionWithoutBuild,
		InformationOnUpdate1.EndOfCurrentVersionSupport);
	If ValueIsFilled(InformationOnUpdate1.EndOfCurrentVersionSupport)
		And InformationOnUpdate1.EndOfCurrentVersionSupport > CurrentSessionDate() Then
		
		InfoAboutUpdateOption.Configuration = New Structure("UpdateAvailable", False);
		InfoAboutUpdateOption.Platform    = New Structure("UpdateAvailable", False);
		
	EndIf;
	
	UpdateOptionsList.Insert(
		CurrentVersionID(),
		InfoAboutUpdateOption);
	VersionsUpdateOptions.Insert(
		CurrentApplicationName + "|" + CurrentApplicationVersion,
		InfoAboutUpdateOption);
	
	// Add information on migration to newer versions with long-term support
	For Each AdditionalVersion In InformationOnUpdate1.AdditionalVersions Do
		
		VersionNumberWithoutBuild = CommonClientServer.ConfigurationVersionWithoutBuildNumber(
			AdditionalVersion.Configuration.Version);
		If CurrentVersionWithoutBuild = VersionNumberWithoutBuild Then
			If ValueIsFilled(AdditionalVersion.Configuration.EndOfSupport)
				And AdditionalVersion.Configuration.EndOfSupport > CurrentSessionDate() Then
				
				VersionID = CurrentVersionNewBuildID();
				
			// Support for the current version is discontinued
			Else
				Continue;
			EndIf;
		Else
			VersionID = CurrentApplicationName + "|" + AdditionalVersion.Configuration.Version;
		EndIf;
		
		InfoAboutUpdateOption = NewUpdateOption(
			VersionID,
			VersionNumberWithoutBuild,
			AdditionalVersion.Configuration.EndOfSupport);
		FillPropertyValues(InfoAboutUpdateOption, AdditionalVersion, "Configuration,Platform");
		
		UpdateOptionsList.Insert(
			VersionID,
			InfoAboutUpdateOption);
		VersionsUpdateOptions.Insert(
			CurrentApplicationName + "|" + AdditionalVersion.Configuration.Version,
			InfoAboutUpdateOption);
		
	EndDo;
	
	// Add the latest version information.
	AppNewVersionName   = ?(IsBlankString(NewApplicationName), CurrentApplicationName, NewApplicationName);
	AppNewVersionNumber = "";
	EndOfSupport        = Undefined;
	If InformationOnUpdate1.Configuration <> Undefined Then
		AppNewVersionNumber = InformationOnUpdate1.Configuration.Version;
		EndOfSupport        = InformationOnUpdate1.Configuration.EndOfSupport;
	EndIf;
	
	InfoAboutUpdateOption = NewUpdateOption(
		UpToDateVersionID(),
		CommonClientServer.ConfigurationVersionWithoutBuildNumber(AppNewVersionNumber),
		EndOfSupport);
	FillPropertyValues(InfoAboutUpdateOption, InformationOnUpdate1, "Configuration,Platform");
	
	UpdateOptionsList.Insert(
		UpToDateVersionID(),
		InfoAboutUpdateOption);
	VersionsUpdateOptions.Insert(
		AppNewVersionName + "|" + AppNewVersionNumber,
		InfoAboutUpdateOption);
	
	// Populate patch information
	If Corrections <> Undefined Then
		For Each PatchString In Corrections Do
			// All versions of additional subsystem support patching
			If PatchString.ForCurrentVersion And PatchString.ForNewVersion Then
				For Each CurUpdateOption In UpdateOptionsList Do
					CurUpdateOption.Value.SelectedPatches.Add(PatchString.Id);
					CurUpdateOption.Value.ListOfCorrections.Add(PatchString.Id);
				EndDo;
			Else
				For Each ApplicabilityRow In PatchString.Applicability Do
					CurUpdateOption = VersionsUpdateOptions[
						ApplicabilityRow.ApplicationName + "|" + ApplicabilityRow.ApplicationVersion];	// See NewUpdateOption
					If CurUpdateOption <> Undefined Then
						CurUpdateOption.SelectedPatches.Add(PatchString.Id);
						CurUpdateOption.ListOfCorrections.Add(PatchString.Id);
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
	UpdatesOptions = New FixedMap(UpdateOptionsList);
	
EndProcedure

&AtServer
Procedure DisplayInformationOnAvailableUpdate(Val FillInitialSettings = False)
	
	If Not IsBlankString(AvailableUpdateInformation.ErrorName) Then
		If IsConnectionError(AvailableUpdateInformation.ErrorName) Then
			DisplayConnectionError(
				AvailableUpdateInformation.Message,
				AvailableUpdateInformation.ErrorInfo);
		Else
			DisplayServiceMessage(
				AvailableUpdateInformation.Message,
				NStr("ru = 'Повторить попытку подключения >';
					|en = 'Try connecting again >';"),
				AvailableUpdateInformation.ErrorInfo);
		EndIf;
		Return;
	EndIf;
	
	If IsScenarioOfMigrationToNewPlatformVersion(ThisObject)
		Or IsNotRecommendedPlatformVersionMessageScenario(ThisObject) Then
		
		UpdateOption = UpToDateVersionID();
		DisplayInformationOnAvailablePlatformUpdate(FillInitialSettings);
		
	ElsIf MultipleVersionsAvailableForUpdate() Then
		ShowUpdateOptionsInfo(FillInitialSettings);
		UpdateWarningsPanel(True);
	Else
		
		UpdateOption = UpToDateVersionID();
		DisplayInformationOnComponentsUpdate(FillInitialSettings);
		
		// If a configuration update is available, show the warning (if required).
		UpdateOptionCurrentVersion    = UpdatesOptions[CurrentVersionID()];
		VersionOfUpdateOptionUpToDate = UpdatesOptions[UpToDateVersionID()];
		ConfigurationUpdateAvailable    =
			VersionOfUpdateOptionUpToDate.Configuration <> Undefined
			And VersionOfUpdateOptionUpToDate.Configuration.UpdateAvailable
			Or UpdateOptionCurrentVersion <> Undefined
			And UpdateOptionCurrentVersion.ListOfCorrections.Count() > 0
			Or VersionOfUpdateOptionUpToDate <> Undefined
			And VersionOfUpdateOptionUpToDate.ListOfCorrections.Count() > 0;
		
		UpdateWarningsPanel(ConfigurationUpdateAvailable);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayInformationOnAvailablePlatformUpdate(FillInitialSettings = False)
	
	HasUpdate      = True;
	SelectedUpdate = UpdatesOptions[UpdateOption];
	PlatformUpdate = SelectedUpdate.Platform;
	If Not PlatformUpdate.UpdateAvailable Then
		
		// No information on the 1C:Enterprise version is available on 1C:ITS. In the non-recommended message scenario,
		// clear the minimum and recommended version cache and allow operating the app.
		If IsNotRecommendedPlatformVersionMessageScenario(ThisObject) Then
			GetApplicationUpdates.DeletePlatformVersionInformation();
		EndIf;
		
		HasUpdate = False;
		DisplayPage(Items.Pages, Items.NoNewPlatformVersionAvailablePage);
		Items.NoVersionDecoration.Title =
			OnlineUserSupportClientServer.FormattedHeader(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '<body>Используемая сейчас версия: %1</body>';
						|en = '<body>The current version: %1</body>';"),
					OnlineUserSupport.Current1CPlatformVersion()));
		
	ElsIf CommonClientServer.CompareVersions(
		OnlineUserSupport.Current1CPlatformVersion(),
		PlatformUpdate.Version) >= 0 Then
		
		HasUpdate = False;
		DisplayPage(Items.Pages, Items.NoNewPlatformVersionAvailablePage);
		Items.NoVersionDecoration.Title = OnlineUserSupportClientServer.FormattedHeader(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '<body>Рекомендуемая версия платформы 1С:Предприятие: <b>%1</b>
					|<br />Используемая сейчас версия: %2</body>';
					|en = '<body>Recommended version of 1C:Enterprise platform: <b>%1</b>
					|<br />The current version:%2</body>';"),
				PlatformUpdate.Version,
				OnlineUserSupport.Current1CPlatformVersion()));
		
	EndIf;
	
	If Not HasUpdate Then
		
		Items.BackButton.Enabled  = False;
		Items.NextButton.Enabled  = False;
		Items.CancelButton.Enabled = True;
		Items.ContinueWorkingWithCurrentVersion.Visible = False;
		Items.NextButton.Title    = NStr("ru = 'Далее >';
												|en = 'Next >';");
		Items.CancelButton.Title   = NStr("ru = 'Закрыть';
												|en = 'Close';");
		Return;
		
	Else
		
		Use = False;
		If IsFileIB Then
			PlatformInstallationDirectory = GetApplicationUpdatesClientServer.OneCEnterprisePlatformInstallationDirectory(
				PlatformUpdate.Version);
			Use = (PlatformInstallationDirectory <> "");
		EndIf;
		
		If Use Then
			
			// It is a file infobase, and the platform is installed.
			DisplayNewPlatformVersionIsAlreadyInstalledOnComputerPage();
			
		Else
			
			// Page of information about available platform update.
			DisplayPage(Items.Pages, Items.AvailablePlatformVersionPage);
			Items.VersionLabel.Title = NStr("ru = 'Версия';
													|en = 'Version';")
				+ " " + PlatformUpdate.Version;
			Items.TransitionSpecificsLabel.Visible =
				(Not IsBlankString(PlatformUpdate.URLTransitionFeatures));
			
			Items.NewPlatformVersionMessageDecoration.Title = NewPlatformVersionPageTitle();
			
			// File and client/server mode.
			If IsFileIB Then
				
				Items.SizeGroup.Visible                      = True;
				Items.Download1CEnterpriseDistributionPackage2.Visible    = False;
				Items.PlatformInstallationParametersGroup.Visible = True;
				Items.UpdateSizeLabel.Title =
					OnlineUserSupportClientServer.FileSizePresentation(
						PlatformUpdate.UpdateSize);
				Items.NextButton.Enabled  = True;
				Items.NextButton.Title    = NStr("ru = 'Далее >';
														|en = 'Next >';");
				
				// Save platform distribution packages.
				If FillInitialSettings Then
					SettingsOfUpdate = GetApplicationUpdates.AutoupdateSettings();
					PlatformInstallationMode = SettingsOfUpdate.InstallationMode;
					If Items.DirectoryToSavePlatformGroup.Visible Then
						If SettingsOfUpdate.PlatformDistributionPackagesDirectory = Undefined Then
							DirectoryToSavePlatform = DefaultPlatformDistributionPackageDirectory();
							SavePlatformDistributionPackagesToDirectory = False;
							Items.DirectoryToSavePlatformDistributionPackage.Enabled = False;
						Else
							DirectoryToSavePlatform = SettingsOfUpdate.PlatformDistributionPackagesDirectory;
							If IsBlankString(DirectoryToSavePlatform) Then
								DirectoryToSavePlatform = GetApplicationUpdatesClientServer.DirectoryToWorkWithPlatformUpdates();
							EndIf;
							SavePlatformDistributionPackagesToDirectory = True;
							Items.DirectoryToSavePlatformDistributionPackage.Enabled = True;
						EndIf;
					Else
						DirectoryToSavePlatform = DefaultPlatformDistributionPackageDirectory();
					EndIf;
				EndIf;
				
			Else
				
				// Client/server mode.
				Items.SizeGroup.Visible                      = False;
				Items.Download1CEnterpriseDistributionPackage2.Visible    = True;
				Items.PlatformInstallationParametersGroup.Visible = False;
				Items.NextButton.Enabled  = True;
				Items.NextButton.Title    = NStr("ru = 'Готово';
														|en = 'Finish';");
				
			EndIf;
			
			Items.BackButton.Enabled  = IsNotRecommendedPlatformVersionMessageScenario(ThisObject);
			Items.CancelButton.Enabled = True;
			Items.ContinueWorkingWithCurrentVersion.Visible = False;
			Items.CancelButton.Title   = NStr("ru = 'Отмена';
													|en = 'Cancel';");
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayNewPlatformVersionIsAlreadyInstalledOnComputerPage()
	
	DisplayPage(Items.Pages, Items.PlatformAlreadyInstalledPage);
	
	SelectedUpdate = UpdatesOptions[UpdateOption];
	PlatformUpdate = SelectedUpdate.Platform;
	Items.VersionInstalledLabel.Title =
		NStr("ru = 'Версия';
			|en = 'Version';") + " " + PlatformUpdate.Version;
	
	If Not IsBlankString(PlatformUpdate.URLTransitionFeatures) Then
		
		Items.InstalledAdditionallyLabel.Title =
			OnlineUserSupportClientServer.FormattedHeader(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '<body>Версия платформы %1 уже установлена на компьютере.
						|<br />Перед началом работы на новой версии платформы рекомендуется ознакомиться
						|<br />с <a href=""open:V8Update"">особенностями перехода</a> на эту версию платформы.</body>';
						|en = '<body>%1 version platform is already installed on the computer.
						|<br />Before you begin to use a new platform version, read
						|<br />c <a href=""open:V8Update"">features of migration </a> to this platform version.</body>';"),
					PlatformUpdate.Version));
		
	Else
		
		Items.InstalledAdditionallyLabel.Title =
			OnlineUserSupportClientServer.FormattedHeader(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '<body>Версия платформы %1 уже установлена на компьютере.</body>';
						|en = '<body>Version of platform %1 is already installed on the computer.</body>';"),
					PlatformUpdate.Version));
		
	EndIf;
	
	If Items.PlatformAlreadyInstalledMessageDecoration.Visible Then
		Items.PlatformAlreadyInstalledMessageDecoration.Title = NewPlatformVersionPageTitle();
	EndIf;
	
	If IsBlankString(Items.DecorationInstalledCreateBackupPage.Title) Then
		Items.DecorationInstalledCreateBackupPage.Title =
			InstructionTextOnMigrationToNewPlatformVersion(True);
	EndIf;
	
	If IsBlankString(Items.DecorationInstalledDoNotCreateBackupPage.Title) Then
		Items.DecorationInstalledDoNotCreateBackupPage.Title =
			InstructionTextOnMigrationToNewPlatformVersion(False);
	EndIf;
	
	If CreateBackup Then
		Items.InstructionInstallationInstalledPages.CurrentPage = Items.InstalledCreateBackupPage;
	Else
		Items.InstructionInstallationInstalledPages.CurrentPage = Items.InstalledDoNotCreateBackupPage;
	EndIf;
	
	Items.BackButton.Enabled  = Not IsScenarioOfMigrationToNewPlatformVersion(ThisObject);
	Items.NextButton.Enabled  = True;
	Items.CancelButton.Enabled = True;
	Items.ContinueWorkingWithCurrentVersion.Visible = False;
	Items.NextButton.Title    = NStr("ru = 'Готово';
											|en = 'Finish';");
	Items.CancelButton.Title   = NStr("ru = 'Отмена';
											|en = 'Cancel';");
	
EndProcedure

&AtServer
Procedure DisplayInformationOnComponentsUpdate(Val FillInitialSettings)
	
	DisplayPage(Items.Pages, Items.InformationOnAvailableComponentUpdatePage);
	If FillInitialSettings Then
		FillInitialSettingsAndInstallationDisplayOfComponents();
	EndIf;
	
	DisplayConfigurationComponent();
	DisplayPatches();
	DisplayPlatformComponent();
	DisplayBriefInformationOnAvailableUpdate();
	CustomizeCommandBarButtonsForComponents();
	
EndProcedure

&AtServer
Procedure ShowUpdateOptionsInfo(FillInitialSettings)
	
	DisplayPage(Items.Pages, Items.UpdateOptionChoicePage);
	If FillInitialSettings Then
		DisplayUpdateOptions();
	EndIf;
	
	CustomizeCommandBarButtonsForComponents();
	
EndProcedure

&AtServer
Procedure DisplayUpdateOptions()
	
	// Populate the information on the current version
	CurrentVersion = OnlineUserSupport.ConfigurationVersion();
	
	Items.UpdateOptionLabel.Title = StringFunctions.FormattedString(
		NStr("ru = 'Текущая версия <b>%1</b>, выберите вариант обновления:';
			|en = 'The current version is <b>%1</b>. Select an update option:';"),
		CurrentVersion);
	
	// Delete the previously created items
	For Each CurItem In Items.UpdateOptionsGroup.ChildItems Do
		Items.Delete(CurItem);
	EndDo;
	
	// Populate the list with update options
	AdditionalVersions            = AvailableUpdateInformation.AdditionalVersions;
	CurrentVersionNewBuildData = UpdatesOptions.Get(CurrentVersionNewBuildID());
	CurrentVersionNewBuild        = ?(CurrentVersionNewBuildData = Undefined,
		"",
		CurrentVersionNewBuildData.Configuration.Version);
	
	// Add the current version to the list of available update options
	If CurrentVersionNewBuildData = Undefined Then
		
		ConfigurationInformation = New Structure();
		ConfigurationInformation.Insert("VersionID", CurrentVersionID());
		ConfigurationInformation.Insert("Version"             , CurrentVersion);
		ConfigurationInformation.Insert("URLNewInVersion"    , "");
		
		AddUpdateOptionItems(
			ConfigurationInformation,
			CurrentVersionID());
		
	Else
		
		AddUpdateOptionItems(
			CurrentVersionNewBuildData.Configuration,
			CurrentVersionNewBuildID());
		
	EndIf;
	
	// Add the additional versions to the list of available update options
	ApplicationName = OnlineUserSupport.ApplicationName();
	For Each AdditionalVersion In AdditionalVersions Do
		If CurrentVersionNewBuild <> AdditionalVersion.Configuration.Version Then
			VersionID = ApplicationName + "|" + AdditionalVersion.Configuration.Version;
			AddUpdateOptionItems(AdditionalVersion.Configuration, VersionID);
		EndIf;
	EndDo;
	
	// Add the most up-to-date version to the list of available update options
	AddUpdateOptionItems(
		AvailableUpdateInformation.Configuration,
		UpToDateVersionID());
	
EndProcedure

&AtServer
Procedure UpdateWarningsPanel(UpdateAvailable)
	
	// Get a list of patches to display a warning on the form.
	SetPrivilegedMode(True);
	InstalledPatches = ConfigurationUpdate.InstalledPatches();
	SetPrivilegedMode(False);
	
	ThereAreNotAppliedFixes = False;
	
	If InstalledPatches <> Undefined Then
		For Each PatchDetails In InstalledPatches Do
			If Not ValueIsFilled(PatchDetails.Id) Then
				ThereAreNotAppliedFixes = True;
			EndIf;
		EndDo;
	EndIf;
	
	Items.LabelHasAccountingErrors.Visible = (UpdateAvailable And ErrorsPanelVisibility());
	Items.ExtensionsAvailableLabel.Visible = (IsSystemAdministrator
		And UpdateAvailable
		And ConfigurationUpdate.WarnAboutExistingExtensions());
	Items.LabelHasUnappliedCorrections.Visible = ThereAreNotAppliedFixes;
	Items.WarningsPanel.Visible = (Items.LabelHasAccountingErrors.Visible
		Or Items.ExtensionsAvailableLabel.Visible
		Or Items.LabelHasUnappliedCorrections.Visible);
	
EndProcedure

// Adds new items to the update option choice form.
//
// Parameters:
//  ConfigurationInformation - Structure:
//    * VersionID - String
//    * Version - String
//    * URLNewInVersion - String
//  VersionID - String - The update option id.
//
&AtServer
Procedure AddUpdateOptionItems(ConfigurationInformation, VersionID)
	
	Postfix          = StrReplace(String(New UUID()), "-", "");
	VersionNumber       = CommonClientServer.ConfigurationVersionWithoutBuildNumber(ConfigurationInformation.Version);
	CurrentUpdate = UpdatesOptions[VersionID];	// See NewUpdateOption
	
	// The common option group
	VariantGroup = Items.Add(
		"UpdateOptionGroup" + Postfix,
		Type("FormGroup"),
		Items.UpdateOptionsGroup);
	VariantGroup.Type                 = FormGroupType.UsualGroup;
	VariantGroup.Representation         = UsualGroupRepresentation.None;
	VariantGroup.Group         = ChildFormItemsGroup.Vertical;
	VariantGroup.ShowTitle = False;
	
	// Option radio buttons
	OptionItem = Items.Add(
		"UpdateOption" + Postfix,
		Type("FormField"),
		VariantGroup);
	OptionItem.Type                  = FormFieldType.RadioButtonField;
	OptionItem.DataPath          = "UpdateOption";
	OptionItem.TitleLocation   = FormItemTitleLocation.None;
	OptionItem.ToolTipRepresentation = ToolTipRepresentation.Button;
	OptionItem.ToolTip            = CurrentUpdate.UpdateTooltip;

	OptionItem.ChoiceList.Add(
		VersionID,
		CurrentUpdate.UpdateTitle);
	
	// A group containing additional option information
	If VersionID = CurrentVersionID()
		Or VersionID = CurrentVersionNewBuildID() Then
		
		ThereAreFixes       = (UpdatesOptions[CurrentVersionID()].ListOfCorrections.Count() > 0);
		HasNewConfiguration = (CurrentUpdate <> Undefined
			And CurrentUpdate.Configuration <> Undefined
			And CurrentUpdate.Configuration.UpdateAvailable);
		HasNew1CEnterpriseVersion    = (CurrentUpdate <> Undefined
			And CurrentUpdate.Platform <> Undefined
			And CurrentUpdate.Platform.UpdateAvailable);
		
		If HasNewConfiguration Then
			If IsBlankString(ConfigurationInformation.URLNewInVersion) Then
				VersionAdditionalInfo =
					NStr("ru = 'Доступно обновление';
						|en = 'Update available';");
			Else
				VersionAdditionalInfo = StringFunctions.FormattedString(
					"Available refreshenabled. <a href=""%1"">New In versions</a>",
					ConfigurationInformation.URLNewInVersion);
			EndIf;
		ElsIf ThereAreFixes
			And HasNew1CEnterpriseVersion Then
			
			VersionAdditionalInfo =
				NStr("ru = 'Доступна установка исправлений (патчей) и обновление платформы';
					|en = 'Patches and platform update available';");
			
		ElsIf ThereAreFixes
			And Not HasNew1CEnterpriseVersion Then
			
			VersionAdditionalInfo = NStr("ru = 'Доступна установка исправлений (патчей)';
													|en = 'Patches available';");
			
		ElsIf Not ThereAreFixes
			And HasNew1CEnterpriseVersion Then
			
			VersionAdditionalInfo = NStr("ru = 'Доступно обновление платформы';
													|en = 'Platform update available';");
			
		Else
			VersionAdditionalInfo = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Нет доступных обновлений для текущей версии %1';
					|en = 'There are no available updates for current version %1';"),
				VersionNumber);
		EndIf;
		
	ElsIf Not IsBlankString(ConfigurationInformation.URLNewInVersion) Then
		VersionAdditionalInfo = StringFunctions.FormattedString(
			"<a href=""%1"">New In versions</a>",
			ConfigurationInformation.URLNewInVersion);
	Else
		Return;
	EndIf;
	
	InformationGroup_3 = Items.Add(
		"GroupUpdateOptionAdditionalInfo" + Postfix,
		Type("FormGroup"),
		VariantGroup);
	InformationGroup_3.Type                  = FormGroupType.UsualGroup;
	InformationGroup_3.Representation          = UsualGroupRepresentation.None;
	InformationGroup_3.Group          = ChildFormItemsGroup.AlwaysHorizontal;
	InformationGroup_3.ShowTitle  = False;
	InformationGroup_3.VerticalSpacing = FormItemSpacing.Half;
	
	IndentDecoration = Items.Add(
		"IndentDecoration" + Postfix,
		Type("FormDecoration"),
		InformationGroup_3);
	IndentDecoration.Type    = FormDecorationType.Label;
	IndentDecoration.Width = 1;
	
	TextDecoration = Items.Add(
		"VersionInformation" + Postfix,
		Type("FormDecoration"),
		InformationGroup_3);
	TextDecoration.Type                    = FormDecorationType.Label;
	TextDecoration.AutoMaxWidth = False;
	TextDecoration.MaxWidth     = 0;
	TextDecoration.Title              = VersionAdditionalInfo;
	
EndProcedure

&AtServer
Procedure FillInitialSettingsAndInstallationDisplayOfComponents()
	
	SelectedUpdate       = UpdatesOptions[UpdateOption];
	ComConfigurationUpdate = SelectedUpdate.Configuration;
	PlatformUpdate       = SelectedUpdate.Platform;
	UpdateConfiguration      = (ComConfigurationUpdate <> Undefined
		And ComConfigurationUpdate.UpdateAvailable);
	
	InstallPatches = (?(UpdateConfiguration,
		SelectedUpdate,
		UpdatesOptions[CurrentVersionID()]).ListOfCorrections.Count() > 0);
	
	Items.AutoInstallGroup.Visible = IsSystemAdministrator;
	If Items.AutoInstallGroup.Visible Then
		ImportAndInstallCorrectionsAutomatically =
			Constants.ImportAndInstallCorrectionsAutomatically.Get();
		Job = ScheduledJobsServer.GetScheduledJob(
			Metadata.ScheduledJobs.GetAndInstallConfigurationTroubleshooting);
		If Job <> Undefined Then
			Items.CorrectionsImportDecorationSchedule.Title =
				OnlineUserSupportClientServer.SchedulePresentation(Job.Schedule);
		EndIf;
		Items.CorrectionsImportDecorationSchedule.Enabled =
			ImportAndInstallCorrectionsAutomatically;
	EndIf;
	
	UpdatePlatform = PlatformUpdate <> Undefined
		And PlatformUpdate.UpdateAvailable
		And (UpdateConfiguration
		And PlatformUpdate.InstallationRequired < 2
		Or Not UpdateConfiguration)
		And CommonClientServer.CompareVersions(
			OnlineUserSupport.Current1CPlatformVersion(),
			PlatformUpdate.Version) < 0;
	
	If UpdatePlatform
		And IsFileIB
		And IsSystemAdministrator
		And Items.DirectoryToSavePlatformComponentGroup.Visible Then
		SettingsOfUpdate = GetApplicationUpdates.AutoupdateSettings();
		PlatformInstallationMode = SettingsOfUpdate.InstallationMode;
		If Items.DirectoryToSavePlatformComponentGroup.Visible Then
			If SettingsOfUpdate.PlatformDistributionPackagesDirectory = Undefined Then
				DirectoryToSavePlatform = DefaultPlatformDistributionPackageDirectory();
				SavePlatformDistributionPackagesToDirectory = False;
				Items.DirectoryToSavePlatformComponentDistributionPackage.Enabled = False;
			Else
				DirectoryToSavePlatform = SettingsOfUpdate.PlatformDistributionPackagesDirectory;
				If IsBlankString(DirectoryToSavePlatform) Then
					DirectoryToSavePlatform = GetApplicationUpdatesClientServer.DirectoryToWorkWithPlatformUpdates();
				EndIf;
				SavePlatformDistributionPackagesToDirectory = True;
				Items.DirectoryToSavePlatformComponentDistributionPackage.Enabled = True;
			EndIf;
		Else
			DirectoryToSavePlatform = DefaultPlatformDistributionPackageDirectory();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayBriefInformationOnAvailableUpdate()
	
	SelectedUpdate      = UpdatesOptions[UpdateOption];	// See NewUpdateOption
	AdditionalUpdate = UpdatesOptions[CurrentVersionID()];	// See NewUpdateOption
	
	ComConfUpdate = SelectedUpdate.Configuration;
	PlComUpdate   = SelectedUpdate.Platform;
	
	HasNoSelectedVersionUpdates = (ComConfUpdate = Undefined
		Or Not ComConfUpdate.UpdateAvailable)
		And SelectedUpdate.ListOfCorrections.Count() = 0
		And (PlComUpdate = Undefined
		Or Not PlComUpdate.UpdateAvailable);
	HasNoAdditionalVersionUpdates = (AdditionalUpdate = Undefined
		Or ((AdditionalUpdate.Configuration = Undefined
		Or Not AdditionalUpdate.Configuration.UpdateAvailable)
		And AdditionalUpdate.ListOfCorrections.Count() = 0
		And (AdditionalUpdate.Platform = Undefined
		Or Not AdditionalUpdate.Platform.UpdateAvailable)));
	
	MessageText = "<body>";
	
	If MultipleVersionsAvailableForUpdate() Then
		
		MessageText = MessageText
			+ SelectedUpdate.UpdateTitle
			+ "<br/>";
	EndIf;
	
	If HasNoSelectedVersionUpdates
		And HasNoAdditionalVersionUpdates Then
		
		// No update is available.
		If IsApplicationUpdateScenario(ThisObject)
			Or IsBlankString(NoUpdateHeader) Then
			
			MessageText = MessageText
				+ NStr("ru = 'Обновление не требуется. Установлена актуальная версия программы.';
						|en = 'No update is required. Your application version is up-to-date.';");
				
		Else
			MessageText = MessageText + NoUpdateHeader;
		EndIf;
		
	Else
		
		DirectUpdate = IsApplicationUpdateScenario(ThisObject);
		If DirectUpdate Then
			MessageText = MessageText + NStr("ru = 'Доступно обновление программы.';
													|en = 'Application update is available.';");
		Else
			MessageText = MessageText
				+ ?(IsBlankString(UpdateAvailableHeader), "", UpdateAvailableHeader);
		EndIf;
		
		// Update size.
		UpdateSize = ?(UpdateConfiguration, ComConfUpdate.UpdateSize, 0)
			+ ?(InstallPatches, SelectedCorrectionsSize, 0)
			+ ?(UpdatePlatform And IsFileIB, PlComUpdate.UpdateSize, 0);
		If UpdateSize <> 0 Then
			MessageText = MessageText + ?(DirectUpdate, " ", "<br />")
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Размер дистрибутива: <b>%1</b>';
						|en = 'Distribution size: <b>%1</b>';"),
					OnlineUserSupportClientServer.FileSizePresentation(UpdateSize));
		EndIf;
		
		If UpdateConfiguration Then
			If IsSystemAdministrator And Not IsBlankString(ComConfUpdate.URLOrderOfUpdate) Then
				MessageText = MessageText
					+ StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = '<br /><b>Внимание!</b> Для продолжения необходимо ознакомиться с информацией о <a href=""%1"">порядке обновления</a>.';
							|en = '<br /><b>Warning!</b> To continue, read about<a href=""%1"">the update procedure</a>.';"),
						ComConfUpdate.URLOrderOfUpdate);
			EndIf;
		EndIf;
		
		If Not IsSystemAdministrator Then
			MessageText = MessageText
				+ NStr("ru = '<br />Для обновления программы обратитесь к администратору.';
						|en = '<br />To update the application, contact administrator.';");
		EndIf;
		
	EndIf;
	
	MessageText = MessageText + "</body>";
	Items.UpdateAvailableMessageDecoration.Title =
		OnlineUserSupportClientServer.FormattedHeader(MessageText);
	
EndProcedure

&AtServer
Procedure CustomizeCommandBarButtonsForComponents()
	
	Items.BackButton.Enabled  = False;
	Items.CancelButton.Visible   = True;
	Items.CancelButton.Enabled = True;
	Items.ContinueWorkingWithCurrentVersion.Visible = False;
	
	If Not AvailableUpdateInformation.UpdateAvailable Or Not IsSystemAdministrator Then
		
		Items.NextButton.Visible   = False;
		Items.CancelButton.Title  = NStr("ru = 'Закрыть';
												|en = 'Close';");
		
	ElsIf Items.Pages.CurrentPage = Items.UpdateOptionChoicePage Then
		
		Items.NextButton.Enabled = True;
		Items.NextButton.Title   = NStr("ru = 'Далее >';
												|en = 'Next >';");
		Items.CancelButton.Title  = NStr("ru = 'Отмена';
												|en = 'Cancel';");
		
	ElsIf Not UpdateConfiguration And Not InstallPatches And Not UpdatePlatform Then
		
		// Update is not selected.
		Items.BackButton.Enabled = MultipleVersionsAvailableForUpdate();
		Items.NextButton.Enabled = False;
		Items.NextButton.Title   = NStr("ru = 'Далее >';
												|en = 'Next >';");
		Items.CancelButton.Title  = NStr("ru = 'Отмена';
												|en = 'Cancel';");
		
	ElsIf IsFileIB Then
		
		// Update is selected. File infobases have no update restrictions.
		Items.BackButton.Enabled = MultipleVersionsAvailableForUpdate();
		Items.NextButton.Enabled = True;
		Items.NextButton.Title   = NStr("ru = 'Далее >';
												|en = 'Next >';");
		Items.CancelButton.Title  = NStr("ru = 'Отмена';
												|en = 'Cancel';");
		
	ElsIf UpdateConfiguration Or InstallPatches Then
		
		Items.BackButton.Enabled = MultipleVersionsAvailableForUpdate();
		If UpdatePlatform Then
			// The client/server mode doesn't support 1C:Enterprise automatic update.
			Items.NextButton.Enabled = False;
			Items.NextButton.Title   = NStr("ru = 'Далее >';
													|en = 'Next >';");
			Items.CancelButton.Title  = NStr("ru = 'Отмена';
													|en = 'Cancel';");
		Else
			Items.NextButton.Enabled = True;
			Items.NextButton.Title   = NStr("ru = 'Далее >';
													|en = 'Next >';");
			Items.CancelButton.Title  = NStr("ru = 'Отмена';
													|en = 'Cancel';");
		EndIf;
		
	Else
		
		// Updating the platform in a client/server mode.
		Items.BackButton.Enabled = MultipleVersionsAvailableForUpdate();
		Items.NextButton.Enabled = True;
		Items.NextButton.Title   = NStr("ru = 'Готово';
												|en = 'Finish';");
		Items.CancelButton.Title  = NStr("ru = 'Отмена';
												|en = 'Cancel';");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayConfigurationComponent()
	
	SelectedUpdate       = UpdatesOptions[UpdateOption];
	ComConfigurationUpdate = SelectedUpdate.Configuration;
	If ComConfigurationUpdate = Undefined Then
		
		Items.ConfigurationUpdateGroup.Visible = False;
		
	Else
		
		Items.ConfigurationUpdateGroup.Visible = True;
		If Not ComConfigurationUpdate.UpdateAvailable Then
			
			// No updates.
			Items.UpdateConfiguration.ReadOnly = True;
			Items.ConfigurationUpdateHeaderDecoration.Title = NStr("ru = 'Обновление конфигурации';
																				|en = 'Configuration update';");
			Items.ConfigurationVersionNumberDecoration.Title =
				OnlineUserSupportClientServer.FormattedHeader(
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = '<body>Обновление не требуется. Текущая версия конфигурации: <b>%1</b><br />
							|%2</body>';
							|en = '<body>No update is required. Current configuration version: <b>%1</b><br />
							|%2</body>';"),
						OnlineUserSupport.ConfigurationVersion(),
						OnlineUserSupport.ConfigurationSynonym()));
			
		Else
			
			Items.UpdateConfiguration.ReadOnly = (Not IsSystemAdministrator
				Or UpdateReceiptComplete(ThisObject))
				Or IsScenarioOfMigrationToOtherApplicationOrEdition(ThisObject)
				Or IsConfigurationUpdateFlagNonEditable();
			Items.ConfigurationUpdateHeaderDecoration.Title =
				OnlineUserSupportClientServer.FormattedHeader(
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = '<body>Обновление конфигурации, <b>%1</b></body>';
							|en = '<body>Configuration update, <b>%1</b></body>';"),
						OnlineUserSupportClientServer.FileSizePresentation(
							ComConfigurationUpdate.UpdateSize)));
			
			If Not IsBlankString(ComConfigurationUpdate.URLNewInVersion) Then
				
				Items.ConfigurationVersionNumberDecoration.Title =
					OnlineUserSupportClientServer.FormattedHeader(
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = '<body><b>Версия %1</b>   <a href=""%2"">Новое в версии</a><br />
								|Текущая версия конфигурации: %3<br />
								|%4</body>';
								|en = '<body><b>Version %1</b>   <a href=""%2"">New in version</a><br />
								|Current configuration version: %3<br />
								|%4</body>';"),
							ComConfigurationUpdate.Version,
							ComConfigurationUpdate.URLNewInVersion,
							OnlineUserSupport.ConfigurationVersion(),
							OnlineUserSupport.ConfigurationSynonym()));
				
			Else
				
				Items.ConfigurationVersionNumberDecoration.Title =
					OnlineUserSupportClientServer.FormattedHeader(
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = '<body><b>Версия %1</b><br />
								|Текущая версия конфигурации: %2<br />
								|%3</body>';
								|en = '<body><b>Version %1</b><br />
								|Current configuration version: %2<br />
								|%3</body>';"),
							ComConfigurationUpdate.Version,
							OnlineUserSupport.ConfigurationVersion(),
							OnlineUserSupport.ConfigurationSynonym()));
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayPatches()
	
	Corrections                    = Undefined;
	PatchesCountForVersion = 0;
	SelectedUpdate            = ?(UpdateConfiguration,
		UpdatesOptions[UpdateOption],
		UpdatesOptions[CurrentVersionID()]);
	
	If IsBlankString(PatchAddress) Then
		Items.CorrectionsGroup.Visible = False;
		Return;
	Else
		Corrections                    = GetFromTempStorage(PatchAddress);
		PatchesCountForVersion = SelectedUpdate.ListOfCorrections.Count();
	EndIf;
	
	Items.CorrectionsGroup.Visible = True;
	
	SelectedCorrectionsSize = 0;
	If PatchesCountForVersion > 0 Then
		
		Items.InstallPatches.ReadOnly = False;
		If UpdateConfiguration Then
			
			Items.DecorationPatchesConfigurationVersion.Title =
				OnlineUserSupportClientServer.FormattedHeader(
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = '<body><strong>Для новой версии конфигурации %1</strong></body>';
							|en = '<body><strong>For a new configuration version %1</strong></body>';"),
						SelectedUpdate.Configuration.Version));
			
		Else
			
			Items.DecorationPatchesConfigurationVersion.Title =
				OnlineUserSupportClientServer.FormattedHeader(
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = '<body><strong>Для текущей версии конфигурации %1</strong></body>';
							|en = '<body><strong>For the current configuration version %1</strong></body>';"),
						OnlineUserSupport.ConfigurationVersion()));
			
		EndIf;
		
		SelectedPatchesList = SelectedUpdate.SelectedPatches;
		For Each ListItem In SelectedPatchesList Do
			LineCorrection          = Corrections.Find(ListItem.Value, "Id");
			SelectedCorrectionsSize = SelectedCorrectionsSize
				+ ?(LineCorrection.Revoked1, 0, LineCorrection.Size);
		EndDo;
		
		Items.DecorationPatchesErrorsBeingCorrected.Visible = True;
		If SelectedPatchesList.Count() = 0 Then
			InstallPatches = False;
			Items.DecorationPatchesErrorsBeingCorrected.Title = NStr("ru = 'Исправляемые ошибки (не выбраны)';
																		|en = 'Errors to correct (not selected)';");
		Else
			InstallPatches = (UpdateConfiguration Or InstallPatches);
			Items.DecorationPatchesErrorsBeingCorrected.Title =
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Исправляемые ошибки (%1 из %2)';
						|en = 'Errors to correct (%1 of %2)';"),
					SelectedPatchesList.Count(),
					PatchesCountForVersion);
		EndIf;
		
		If SelectedCorrectionsSize = 0 Then
			Items.DecorationHeaderPatches.Title = NStr("ru = 'Исправления (патчи)';
																|en = 'Patches';");
		Else
			Items.DecorationHeaderPatches.Title =
				OnlineUserSupportClientServer.FormattedHeader(
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = '<body>Исправления (патчи), <strong>%1</strong></body>';
							|en = '<body>Patches, <strong>%1</strong></body>';"),
						OnlineUserSupportClientServer.FileSizePresentation(
							SelectedCorrectionsSize)));
		EndIf;
		
		Items.InstallPatches.ReadOnly = (Not IsSystemAdministrator
			Or UpdateReceiptComplete(ThisObject));
		
	Else
		
		InstallPatches = False;
		Items.InstallPatches.ReadOnly = True;
		Items.DecorationHeaderPatches.Title = NStr("ru = 'Исправления (патчи)';
															|en = 'Patches';");
		Items.DecorationPatchesConfigurationVersion.Title =
			OnlineUserSupportClientServer.FormattedHeader(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '<body>Исправление ошибок для версии <strong>%1</strong> не требуется.</body>';
						|en = '<body>Error correction for version <strong>%1</strong> is not required.</body>';"),
					?(UpdateConfiguration,
					SelectedUpdate.Configuration.Version,
					OnlineUserSupport.ConfigurationVersion())));
		Items.DecorationPatchesErrorsBeingCorrected.Visible = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayPlatformComponent()
	
	SelectedUpdate = UpdatesOptions[UpdateOption];
	PlComUpdate     = SelectedUpdate.Platform;
	
	Items.PlatformNoteDecorationClientServer.Visible = False;
	
	If PlComUpdate = Undefined Then
		
		Items.PlatformUpdateGroup.Visible = False;
		
	ElsIf Not PlComUpdate.UpdateAvailable Then
		
		Items.PlatformUpdateGroup.Visible = True;
		
		// No updates.
		Items.UpdatePlatform.ReadOnly = True;
		Items.PlatformUpdateHeaderDecoration.Title =
			NStr("ru = 'Обновление платформы 1С:Предприятие';
				|en = '1C:Enterprise platform update';");
		Items.PlatformVersionNumberDecoration.Title =
			OnlineUserSupportClientServer.FormattedHeader(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '<body>Обновление не требуется. Текущая версия платформы 1С:Предприятие: <b>%1</b></body>';
						|en = '<body>No update is required. Current 1C:Enterprise platform version: <b>%1</b></body>';"),
					OnlineUserSupport.Current1CPlatformVersion()));
		
		Items.PlatformNoteDecoration.Visible                 = False;
		Items.Download1CEnterpriseDistributionPackage1.Visible              = False;
		Items.PlatformComponentInstallationParametersGroup.Visible = False;
		
	Else
		
		Items.PlatformUpdateGroup.Visible = True;
		
		Items.UpdatePlatform.ReadOnly = (Not IsSystemAdministrator
			Or UpdateConfiguration And PlComUpdate.InstallationRequired = 0
			Or UpdateReceiptComplete(ThisObject));
		
		If UpdateConfiguration And PlComUpdate.InstallationRequired = 0 Then
			UpdatePlatform = True;
		EndIf;
		
		If IsFileIB Then
			Items.PlatformUpdateHeaderDecoration.Title =
				OnlineUserSupportClientServer.FormattedHeader(
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = '<body>Обновление платформы 1С:Предприятие, <b>%1</b></body>';
							|en = '<body>1C:Enterprise platform update, <b>%1</b></body>';"),
						OnlineUserSupportClientServer.FileSizePresentation(
							PlComUpdate.UpdateSize)));
		Else
			Items.PlatformUpdateHeaderDecoration.Title =
				OnlineUserSupportClientServer.FormattedHeader(
						NStr("ru = '<body>Обновление платформы 1С:Предприятие</body>';
							|en = '<body>1C:Enterprise platform update</body>';"));
		EndIf;
		
		If Not IsBlankString(PlComUpdate.URLTransitionFeatures) Then
			
			Items.PlatformVersionNumberDecoration.Title =
				OnlineUserSupportClientServer.FormattedHeader(
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = '<body><b>Версия %1</b>   <a href=""%2"">Особенности перехода на новую версию платформы</a><br />
							|Текущая версия платформы 1С:Предприятие: %3</body>';
							|en = '<body><b>Version %1</b>   <a href=""%2"">Migrate to a new platform version</a><br />
							|Current 1C:Enterprise platform version: %3</body>';"),
						PlComUpdate.Version,
						PlComUpdate.URLTransitionFeatures,
						OnlineUserSupport.Current1CPlatformVersion()));
			
		Else
			
			Items.PlatformVersionNumberDecoration.Title =
				OnlineUserSupportClientServer.FormattedHeader(
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = '<body><b>Версия %1</b><br />
							|Текущая версия платформы 1С:Предприятие: %2</body>';
							|en = '<body><b>Version %1</b><br />
							|Current 1C:Enterprise platform version: %2</body>';"),
						PlComUpdate.Version,
						OnlineUserSupport.Current1CPlatformVersion()));
			
		EndIf;
		
		If IsFileIB Then
			
			Items.Download1CEnterpriseDistributionPackage1.Visible = False;
			If UpdateConfiguration Then
				
				Items.PlatformNoteDecoration.Visible = True;
				If PlComUpdate.InstallationRequired = 0 Then
					Items.PlatformNoteDecoration.Title =
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Обновление платформы является обязательным для работы с новой версией конфигурации %1.';
								|en = 'Platform update is required for a new version of %1 configuration.';"),
							SelectedUpdate.Configuration.Version);
				ElsIf PlComUpdate.InstallationRequired = 1 Then
					Items.PlatformNoteDecoration.Title =
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Новая версия %1 платформы 1С:Предприятие рекомендуется для работы с новой версией конфигурации %2.';
								|en = '%1 new version of 1C:Enterprise platform is recommended for new configuration version %2.';"),
							PlComUpdate.Version,
							SelectedUpdate.Configuration.Version);
				Else
					Items.PlatformNoteDecoration.Title =
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Обновление платформы не является обязательным для работы с новой версией конфигурации %1.';
								|en = 'Platform update is optional for a new version of %1 configuration.';"),
							SelectedUpdate.Configuration.Version);
				EndIf;
				
			ElsIf PlComUpdate.InstallationRequired < 2 Then
				
				Items.PlatformNoteDecoration.Visible = True;
				Items.PlatformNoteDecoration.Title =
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Рекомендуется установить новую версию платформы 1С:Предприятие.';
							|en = 'It is recommended that you install new 1C:Enterprise platform version.';"),
						SelectedUpdate.Configuration.Version);
				
			Else
				
				Items.PlatformNoteDecoration.Visible = False;
				
			EndIf;
			
			Items.PlatformComponentInstallationParametersGroup.Visible = IsSystemAdministrator;
			Items.PlatformNoteDecorationClientServer.Visible     = False;
			
		Else
			
			// Display for client/server infobase.
			Items.PlatformNoteDecoration.Visible = True;
			
			If UpdateConfiguration Then
				
				If PlComUpdate.InstallationRequired = 0 Then
					Items.PlatformNoteDecoration.Title =
						OnlineUserSupportClientServer.FormattedHeader(
							StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = '<body>Для работы новой версии конфигурации требуется платформа 1С:Предприятие не ниже версии <b>%1</b>.</body>';
									|en = '<body>For new configuration version operation you need 1C:Enterprise platform not earlier than <b>%1</b>.</body>';"),
								SelectedUpdate.Configuration.MinPlatformVersion));
				ElsIf PlComUpdate.InstallationRequired = 1 Then
					Items.PlatformNoteDecoration.Title =
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Новая версия %1 платформы 1С:Предприятие рекомендуется для работы с новой версией конфигурации %2.';
								|en = '%1 new version of 1C:Enterprise platform is recommended for new configuration version %2.';"),
							PlComUpdate.Version,
							SelectedUpdate.Configuration.Version);
				Else
					Items.PlatformNoteDecoration.Title =
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Обновление платформы не является обязательным для работы с новой версией конфигурации %1.';
								|en = 'Platform update is optional for a new version of %1 configuration.';"),
							SelectedUpdate.Configuration.Version);
				EndIf;
				
			ElsIf PlComUpdate.InstallationRequired < 2 Then
				
				Items.PlatformNoteDecoration.Visible = True;
				Items.PlatformNoteDecoration.Title =
					NStr("ru = 'Рекомендуется установить новую версию платформы 1С:Предприятие.';
						|en = 'It is recommended that you install new 1C:Enterprise platform version.';");
				
			Else
				
				Items.PlatformNoteDecoration.Visible = False;
				
			EndIf;
			
			Items.Download1CEnterpriseDistributionPackage1.Visible              = IsSystemAdministrator;
			Items.PlatformNoteDecorationClientServer.Visible     = IsSystemAdministrator;
			Items.PlatformComponentInstallationParametersGroup.Visible = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnChangeConfigurationComponentFlagAtServer()
	
	DisplayPatches();
	DisplayPlatformComponent();
	DisplayBriefInformationOnAvailableUpdate();
	CustomizeCommandBarButtonsForComponents();
	
EndProcedure

&AtServer
Procedure OnChangePatchAtServer()
	
	DisplayBriefInformationOnAvailableUpdate();
	CustomizeCommandBarButtonsForComponents();
	
EndProcedure

&AtServer
Procedure OnSelectPatchesAtServer()
	
	If Items.InstallPatches.ReadOnly Then
		Return;
	EndIf;
	
	DisplayPatches();
	DisplayBriefInformationOnAvailableUpdate();
	CustomizeCommandBarButtonsForComponents();
	
EndProcedure

&AtServer
Procedure OnChangePlatformFlagAtServer()
	
	DisplayBriefInformationOnAvailableUpdate();
	CustomizeCommandBarButtonsForComponents();
	
EndProcedure

&AtClient
Procedure OnSelectPatches(Result, SelectedUpdateID) Export
	
	If TypeOf(Result) <> Type("ValueList") Then
		Return;
	EndIf;
	
	UpdateOptionsList = New Map(UpdatesOptions);
	
	SelectedUpdate = UpdateOptionsList[SelectedUpdateID];
	SelectedUpdate.SelectedPatches = Result;
	
	UpdatesOptions = New FixedMap(UpdateOptionsList);
	
	OnSelectPatchesAtServer();
	
EndProcedure

&AtClient
Procedure OnAnswerPatchQuestionEnableOnlineSupportOnEnablePatchesInstallation(
	ReturnCode,
	AdditionalParameters) Export
	
	If ReturnCode = DialogReturnCode.Yes Then
		OnlineUserSupportClient.EnableInternetUserSupport(
			New NotifyDescription("EnableOnlineSupportCompletionAutomaticPatchInstallation", ThisObject),
			ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure EnableOnlineSupportCompletionAutomaticPatchInstallation(
	Result,
	AdditionalParameters) Export
	
	If Result <> Undefined Then
		ImportAndInstallCorrectionsAutomatically = True;
		GetApplicationUpdatesServerCall.EnableDisableAutomaticPatchesInstallation(
			ImportAndInstallCorrectionsAutomatically);
		Items.CorrectionsImportDecorationSchedule.Enabled =
			ImportAndInstallCorrectionsAutomatically;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangePatchInstallationSchedule(Schedule, Form) Export
	
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	RepeatPeriodInDay = Schedule.RepeatPeriodInDay;
	If RepeatPeriodInDay > 0
		And RepeatPeriodInDay < 3600 Then
		ShowMessageBox(,
			NStr("ru = 'Интервал автоматической установки не может быть чаще, чем один раз в час.';
				|en = 'The automatic installation interval cannot be shorter than one hour.';"));
		Return;
	EndIf;
	
	OnChangePatchInstallationScheduleAtServer(Schedule);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Step of getting and installing update files.

&AtClient
Procedure StartGetUpdates()
	
	// During the preparation, the app might send a request to the service to obtain information on the downloaded files.
	Status(, , NStr("ru = 'Подготовка к получению и установки обновлений';
						|en = 'Prepare to receive and install updates';"));
	
	PlatformInstalled = False;
	If Not (IsScenarioOfMigrationToNewPlatformVersion(ThisObject)
		Or IsNotRecommendedPlatformVersionMessageScenario(ThisObject))
		And Not UpdateConfiguration
		And Not InstallPatches Then
		// Case processing: only the platform is being installed, or the platform is already installed.
		SelectedUpdate       = UpdatesOptions[UpdateOption];
		PlatformInstallationDirectory = GetApplicationUpdatesClientServer.OneCEnterprisePlatformInstallationDirectory(
			SelectedUpdate.Platform.Version);
		PlatformInstalled = (PlatformInstallationDirectory <> "");
	EndIf;
	
	If PlatformInstalled Then
		DisplayNewPlatformVersionIsAlreadyInstalledOnComputerPage();
		Return;
		
	ElsIf UpdateReceiptComplete(ThisObject) Then
		
		// If clicking "Back" navigates to the "Info on available update" step,
		// return to the "Installation completed" step.
		DisplayUpdateReceiptComplete();
		Return;
		
	EndIf;
	
	InitializationResult = InitializeObtainingUpdatesAtServer();
	
	Status();
	
	If InitializationResult.StartGetAndInstallUpdates Then
		StartGetAndInstallUpdates();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function AuthenticationDataOfOnlineSupportUserFilled()
	
	Return OnlineUserSupport.AuthenticationDataOfOnlineSupportUserFilled();
	
EndFunction

&AtServerNoContext
Function UpdateFilesDetailsAtServer(
	Val ComConfigurationUpdate,
	Val PatchParameters,
	Val PlatformUpdate,
	Val Login,
	Val Password,
	Val SaveAuthenticationData)
	
	If Not GetApplicationUpdates.IsSystemAdministrator() Then
		Raise NStr("ru = 'Недостаточно прав.';
								|en = 'Insufficient rights.';");
	EndIf;
	
	If PatchParameters = Undefined Then
		PatchesToGetIDs = Undefined;
		RevokedPatchesIDs = Undefined;
	Else
		PatchesToGetIDs = PatchParameters.PatchesToGetIDs;
		RevokedPatchesIDs = Undefined;
		If Not IsBlankString(PatchParameters.PatchAddress) Then
			RevokedPatchesIDs = New Array;
			PatchTable = GetFromTempStorage(PatchParameters.PatchAddress);
			Rows = PatchTable.FindRows(
				New Structure(?(ComConfigurationUpdate <> Undefined, "ForNewVersion", "ForCurrentVersion"), True));
			For Each CurrentRow In Rows Do
				If CurrentRow.Revoked1 Then
					RevokedPatchesIDs.Add(String(CurrentRow.Id));
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	If SaveAuthenticationData Then
		
		Result = GetApplicationUpdates.UpdateFilesDetails(
			ComConfigurationUpdate,
			PatchesToGetIDs,
			PlatformUpdate,
			Login,
			Password);
		
		If IsBlankString(Result.ErrorName) Then
			SaveAuthenticationData(New Structure("Login, Password", Login, Password));
		EndIf;
		
	Else
		
		SetPrivilegedMode(True);
		SavedAuthenticationData = OnlineUserSupport.OnlineSupportUserAuthenticationData();
		SetPrivilegedMode(False);
		
		If SavedAuthenticationData = Undefined Then
			Result = New Structure;
			Result.Insert("ErrorName", "AuthenticationDataNotFilled");
			Return Result;
		EndIf;
		
		Result = GetApplicationUpdates.UpdateFilesDetails(
			ComConfigurationUpdate,
			PatchesToGetIDs,
			PlatformUpdate,
			SavedAuthenticationData.Login,
			SavedAuthenticationData.Password);
		
	EndIf;
	
	Result.Insert("RevokedPatches", RevokedPatchesIDs);
	
	Return Result;
	
EndFunction

&AtServerNoContext
Procedure SaveAuthenticationData(Val AuthenticationData)
	
	// Checking the right to write data.
	If Not OnlineUserSupport.RightToWriteOUSParameters() Then
		Raise NStr("ru = 'Недостаточно прав для записи данных аутентификации Интернет-поддержки.';
								|en = 'Insufficient rights to save authentication credentials for online support.';");
	EndIf;
	
	// Write data.
	SetPrivilegedMode(True);
	OnlineUserSupport.SaveAuthenticationData(AuthenticationData);
	
EndProcedure

&AtClient
Procedure StartGetAndInstallUpdates()
	
	If IsFileIB Then
		
		// The background job was started when update download was initialized.
		
		If UpdateContext <> Undefined Then
			
			// Displaying the current status of the job upon restart.
			DisplayUpdateContextState();
			
			// Clear the result of loading and installing updates.
			// Re-obtain it from the background job.
			UpdateContext = Undefined;
			
		EndIf;
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow           = False;
		IdleParameters.Interval                       = 1;
		IdleParameters.OutputProgressBar     = True;
		IdleParameters.ExecutionProgressNotification = New NotifyDescription(
			"OnRefreshProgressOfUpdateDownloadAndInstallation",
			ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			New NotifyDescription(
				"OnCompleteGettingAndInstallingUpdates",
				ThisObject),
			IdleParameters);
		
	Else
		
		// For the client/server mode, load and install configuration updates and patches
		// (skip updates for 1C:Enterprise). Files are obtained synchronously.
		// 
		If UpdateContext = Undefined Then
			
			ContextCreationParameters = New Structure;
			ContextCreationParameters.Insert("UpdateFilesDetails", UpdateFilesDetails);
			ContextCreationParameters.Insert("UpdateContext"      , UpdateContext);
			ContextCreationParameters.Insert("UpdateConfiguration"    , UpdateConfiguration);
			ContextCreationParameters.Insert("InstallPatches"   , InstallPatches);
			ContextCreationParameters.Insert("UpdatePlatform"       , False);
			ContextCreationParameters.Insert("IsWindowsClient"        , CommonClient.IsWindowsClient());
			UpdateContext = GetApplicationUpdatesClientServer.NewContextOfGetAndInstallUpdates(
				ContextCreationParameters);
			
		Else
			
			// Reset the error status.
			UpdateContext.ErrorName          = "";
			UpdateContext.Message          = "";
			UpdateContext.ErrorInfo = "";
			
		EndIf;
		
		// Update download page was initialized when update download was initialized.
		
		DisplayUpdateContextState();
		
		// Execute in an idle handler with a minimal time interval enough to
		// refresh the wizard's interface and display the update step page.
		// 
		AttachIdleHandler("GetUpdateFilesIteration", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GetUpdateFilesIteration()
	
	CurrentUpdateIndex  = UpdateContext.CurrentUpdateIndex;
	CurrentPatchIndex = UpdateContext.CurrentPatchIndex;
	ReceivedFilesVolume = UpdateContext.ReceivedFilesVolume;
	
	For Iterator_SSLy = CurrentUpdateIndex To UpdateContext.ConfigurationUpdates.UBound() Do
		
		CurrUpdate = UpdateContext.ConfigurationUpdates[Iterator_SSLy];
		
		GetApplicationUpdatesClient.WriteInformationToEventLog(
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
		
		If Not GetApplicationUpdatesClientServer.ConfigurationUpdateReceived(CurrUpdate, UpdateContext) Then
			
			UpdateContext.CurrentAction1 =
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Получение файла %1 из %2';
						|en = 'Receive %1 file from %2';"),
					String(Iterator_SSLy + 1),
					UpdateContext.FilesCount);
			UpdateContext.Progress = 100 * (ReceivedFilesVolume / UpdateContext.FilesVolume);
			DisplayUpdateContextState();
			
			UpdateContext.CurrentUpdateIndex = Iterator_SSLy;
			UpdateContext.ReceivedFilesVolume    = ReceivedFilesVolume;
			
			AttachIdleHandler("DownloadConfigurationUpdate", 0.1, True);
			Return;
			
		Else
			
			GetApplicationUpdatesClient.WriteInformationToEventLog(
				NStr("ru = 'Обновление конфигурации уже было получено ранее.';
					|en = 'The configuration update has already been received.';"));
			
		EndIf;
		
	EndDo;
	
	// If "Return" wasn't triggered, all update files are obtained.
	// Proceed to load patch files.
	For Iterator_SSLy = CurrentPatchIndex To UpdateContext.Corrections.UBound() Do
		
		UpdateContext.CurrentAction1 =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Получение файла %1 из %2';
					|en = 'Receive %1 file from %2';"),
				String(UpdateContext.ConfigurationUpdateCount + Iterator_SSLy + 1),
				UpdateContext.FilesCount);
		UpdateContext.Progress = 100 * (ReceivedFilesVolume / UpdateContext.FilesVolume);
		DisplayUpdateContextState();
		
		UpdateContext.CurrentPatchIndex = Iterator_SSLy;
		UpdateContext.ReceivedFilesVolume     = ReceivedFilesVolume;
		
		AttachIdleHandler("DownloadPatch", 0.1, True);
		Return;
		
	EndDo;
	
	// If next iteration is not triggered, all the files are obtained.
	// 
	If UpdateConfiguration Then
		
		DisplayUpdateReceiptComplete(True);
		
	Else
		
		// Install patches in case of patch-only installation.
		// 
		UpdateContext.CurrentAction1 = NStr("ru = 'Установка исправлений';
													|en = 'Installing patches';");
		UpdateContext.Progress = 100;
		DisplayUpdateContextState();
		
		AttachIdleHandler("InstallDeletePatches", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InstallDeletePatches()
	
	PatchesToInstall = New Array;
	For Each CurPatch In UpdateContext.Corrections Do
		PatchDetails = New Structure;
		PatchDetails.Insert("Name",           CurPatch.Name);
		PatchDetails.Insert("FileAddress",    CurPatch.FileAddress);
		PatchDetails.Insert("Id", CurPatch.Id);
		PatchesToInstall.Add(PatchDetails);
	EndDo;
	
	InstallResult = InstallDeletePatchesAtServer(
		PatchesToInstall,
		UpdateContext.RevokedPatches);
	
	Attachments = New Array();
	
	If Not InstallResult.Error Then
		DisplayUpdateReceiptComplete(True);
	Else
		
		FillPropertyValues(UpdateContext, InstallResult);
		UpdateContext.ErrorName = "PatchInstallationError";
		
		If Not IsBlankString(InstallResult.MessageForTechSupport) Then
			Attachments.Add(
				New Structure(
					"Presentation, DataKind, Data",
					NStr("ru = 'Информация об ошибках.txt';
						|en = 'Error information.txt';"),
					"Text",
					InstallResult.MessageForTechSupport));
		EndIf;
		
		DisplayInternalError(
			UpdateContext.Message,
			Undefined,
			UpdateContext.ErrorInfo);
			
	EndIf;
	
	AttachmentsToTechSupport = New FixedArray(Attachments);
	
EndProcedure

&AtServerNoContext
Function InstallDeletePatchesAtServer(Val PatchesToInstall, Val RevokedPatches)
	
	If Not GetApplicationUpdates.IsSystemAdministrator() Then
		Raise NStr("ru = 'Недостаточно прав для установки исправлений (патчей).';
								|en = 'Insufficient rights to install patches.';");
	EndIf;
	
	Return GetApplicationUpdates.InstallAndDeletePatches(
		PatchesToInstall,
		RevokedPatches);
	
EndFunction

&AtClient
Procedure DownloadConfigurationUpdate()
	
	RefreshEnabled = UpdateContext.ConfigurationUpdates[UpdateContext.CurrentUpdateIndex];
	GetApplicationUpdatesClientServer.CreateDirectoriesToGetUpdate(RefreshEnabled, UpdateContext);
	If Not IsBlankString(UpdateContext.ErrorName) Then
		DisplayInternalError(
			UpdateContext.Message,
			Undefined,
			UpdateContext.ErrorInfo);
		Return;
	EndIf;
	
	GetApplicationUpdatesClient.WriteInformationToEventLog(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Загрузка файла обновления конфигурации %1 (выполняется на сервере информационной базы).';
				|en = 'Import an update file for the %1 configuration (performed on the infobase server).';"),
			RefreshEnabled.ReceivedFileName));
	
	GetResult1 = GetUpdateFileAtServer(RefreshEnabled.UpdateFileURL);
	
	If IsBlankString(GetResult1.ErrorCode) Then
		FilesToObtain = New Array;
		FilesToObtain.Add(
			New TransferableFileDescription(RefreshEnabled.ReceivedFileName, GetResult1.FileAddress));
		BeginGetFilesFromServer(
			New NotifyDescription("OnGetConfigurationUpdateFile",
				ThisObject,
				GetResult1),
			FilesToObtain);
	Else
		OnGetConfigurationUpdateFile(Undefined, GetResult1);
	EndIf;
	
EndProcedure

&AtClient
Procedure DownloadPatch()
	
	Patch = UpdateContext.Corrections[UpdateContext.CurrentPatchIndex];
	GetApplicationUpdatesClient.WriteInformationToEventLog(
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
			Patch.FileURL,
			Patch.Id,
			Patch.Size,
			Patch.ReceivedFileName));
	
	If Patch.ReceivedEmails Then

		// Import the patch file to the temporary storage for further installation.
		GetApplicationUpdatesClient.WriteInformationToEventLog(
			NStr("ru = 'Исправление (патч) уже было получено ранее.';
				|en = 'The patch has already been received.';"));
		HandlerOnPlace = New NotifyDescription("OnPlacePatchFile", ThisObject, Patch);
		
		BeginPutFileToServer(
			HandlerOnPlace,
			,
			,
			,
			Patch.ReceivedFileName,
			?(UpdateConfiguration,
				New UUID,
				UUID));
		
		Return;
		
	EndIf;
	
	// When patching the configuration, keep the file in the form's temporary storage
	// (that's why the form ID is passed).
	// When updating the configuration, keep the file in the temporary storage
	// after the form closes as the files will be passed to the updater's API
	// (that's why a new UUID is used).
	// 
	GetResult1 = GetPatchFileAtServer(
		Patch.FileURL,
		Patch.Id,
		?(UpdateConfiguration,
			New UUID,
			UUID));
	
	If IsBlankString(GetResult1.ErrorCode) Then
		
		FilesToObtain = New Array;
		FilesToObtain.Add(
			New TransferableFileDescription(Patch.ReceivedFileName, GetResult1.FileAddress));
		BeginGetFilesFromServer(
			New NotifyDescription("OnGetPatchFile",
				ThisObject,
				GetResult1),
			FilesToObtain);
		
	Else
		
		OnGetPatchFile(Undefined, GetResult1);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnPlacePatchFile(FileDetails, AdditionalParameters) Export
	
	Patch = UpdateContext.Corrections[UpdateContext.CurrentPatchIndex];
	Patch.FileAddress = FileDetails.Address;
	
	// Increment the file counter.
	UpdateContext.CurrentPatchIndex = UpdateContext.CurrentPatchIndex + 1;
	UpdateContext.ReceivedFilesVolume     = UpdateContext.ReceivedFilesVolume + Patch.Size;
	
	// Switching to the next iteration of update receiving.
	AttachIdleHandler("GetUpdateFilesIteration", 0.1, True);
	
EndProcedure

&AtClient
Procedure OnGetConfigurationUpdateFile(ObtainedFiles, GetResult1) Export
	
	RefreshEnabled = UpdateContext.ConfigurationUpdates[UpdateContext.CurrentUpdateIndex];
	If IsBlankString(GetResult1.ErrorCode) Then
		
		GetApplicationUpdatesClient.WriteInformationToEventLog(
			NStr("ru = 'Файл обновления успешно загружен.';
				|en = 'The update file is imported.';"));
		
		GetApplicationUpdatesClientServer.CompleteUpdateReceipt(RefreshEnabled, UpdateContext);
		If Not IsBlankString(UpdateContext.ErrorName) Then
			DisplayInternalError(
				UpdateContext.Message,
				Undefined,
				UpdateContext.ErrorInfo);
			Return;
		EndIf;
		
		// Increasing a file counter.
		UpdateContext.CurrentUpdateIndex = UpdateContext.CurrentUpdateIndex + 1;
		UpdateContext.ReceivedFilesVolume    = UpdateContext.ReceivedFilesVolume + RefreshEnabled.FileSize;
		
		// Switching to the next iteration of update receiving.
		AttachIdleHandler("GetUpdateFilesIteration", 0.1, True);
		Return;
		
	EndIf;
	
	// In case of file receiving error.
	If GetResult1.ErrorCode = "AuthenticationDataNotFilled" Then
		DisplayConnectionToPortal();
		Return;
	EndIf;
	
	// In case of file receiving error.
	
	LogMessage =
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при получении файла дистрибутива конфигурации (%1). %2';
				|en = 'An error occurred while receiving configuration distribution file (%1). %2';"),
			RefreshEnabled.UpdateFileURL,
			GetResult1.ErrorInfo);
	GetApplicationUpdatesServerCall.WriteErrorToEventLog(LogMessage);
	
	UpdateContext.ErrorName = GetResult1.ErrorCode;
	UpdateContext.ErrorInfo = LogMessage;
	UpdateContext.Message = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Ошибка при получении файла дистрибутива конфигурации. %1';
			|en = 'An error occurred while receiving configuration distribution file. %1';"),
		GetResult1.ErrorMessage);
	
	If IsConnectionError(UpdateContext.ErrorName) Then
		DisplayConnectionError(
			UpdateContext.Message,
			LogMessage);
	Else
		DisplayInternalError(
			UpdateContext.Message,
			Undefined,
			LogMessage);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnGetPatchFile(ObtainedFiles, GetResult1) Export
	
	Patch = UpdateContext.Corrections[UpdateContext.CurrentPatchIndex];
	If IsBlankString(GetResult1.ErrorCode) Then
		
		GetApplicationUpdatesClient.WriteInformationToEventLog(
			NStr("ru = 'Файл исправления (патча) успешно загружен.';
				|en = 'The patch file is imported.';"));
		
		Patch.FileAddress = GetResult1.FileAddress;
		
		// Increasing a file counter.
		UpdateContext.CurrentPatchIndex = UpdateContext.CurrentPatchIndex + 1;
		UpdateContext.ReceivedFilesVolume     = UpdateContext.ReceivedFilesVolume + Patch.Size;
		
		// Switching to the next iteration of update receiving.
		AttachIdleHandler("GetUpdateFilesIteration", 0.1, True);
		Return;
		
	EndIf;
	
	// In case of file receiving error.
	If GetResult1.ErrorCode = "AuthenticationDataNotFilled" Then
		DisplayConnectionToPortal();
		Return;
	EndIf;
	
	// In case of file receiving error.
	LogMessage =
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при получении файла исправления (патча) (%1). %2';
				|en = 'An error occurred while getting a patch file (%1). %2';"),
			Patch.FileURL,
			GetResult1.DetailedErrorDetails);
	GetApplicationUpdatesServerCall.WriteErrorToEventLog(LogMessage);
	
	UpdateContext.ErrorName = GetResult1.ErrorCode;
	UpdateContext.ErrorInfo = LogMessage;
	UpdateContext.Message = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Ошибка при получении файла исправления (патча). %1';
			|en = 'An error occurred while getting a patch file. %1';"),
		GetResult1.BriefErrorDetails);
	
	If IsConnectionError(UpdateContext.ErrorName) Then
		DisplayConnectionError(
			UpdateContext.Message,
			LogMessage);
	Else
		DisplayInternalError(
			UpdateContext.Message,
			Undefined,
			LogMessage);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetUpdateFileAtServer(Val FileURL)
	
	OnlineUserSupport.CheckURL(FileURL);
	
	If Not GetApplicationUpdates.IsSystemAdministrator() Then
		Raise NStr("ru = 'Недостаточно прав.';
								|en = 'Insufficient rights.';");
	EndIf;
	
	SetPrivilegedMode(True);
	AuthenticationData = OnlineUserSupport.OnlineSupportUserAuthenticationData();
	SetPrivilegedMode(False);
	
	If AuthenticationData = Undefined Then
		GetResult1 = New Structure;
		GetResult1.Insert("ErrorCode", "AuthenticationDataNotFilled");
		Return GetResult1;
	EndIf;
	
	AddlParameters = New Structure("AnswerFormat, Timeout", 2, 43200);
	GetResult1 = OnlineUserSupport.DownloadContentFromInternet(
		FileURL,
		AuthenticationData.Login,
		AuthenticationData.Password,
		AddlParameters);
	
	If IsBlankString(GetResult1.ErrorCode) Then
		FileAddress = PutToTempStorage(GetResult1.Content);
		GetResult1.Insert("FileAddress", FileAddress);
		GetResult1.Delete("Content");
	EndIf;
	
	Return GetResult1;
	
EndFunction

&AtServerNoContext
Function GetPatchFileAtServer(Val FileURL, Val PatchID, Val FormIdentifier)
	
	OnlineUserSupport.CheckURL(FileURL);
	
	If Not GetApplicationUpdates.IsSystemAdministrator() Then
		Raise NStr("ru = 'Недостаточно прав.';
								|en = 'Insufficient rights.';");
	EndIf;
	
	SetPrivilegedMode(True);
	AuthenticationData = OnlineUserSupport.OnlineSupportUserAuthenticationData();
	SetPrivilegedMode(False);
	
	If AuthenticationData = Undefined Then
		GetResult1 = New Structure;
		GetResult1.Insert("ErrorCode", "AuthenticationDataNotFilled");
		Return GetResult1;
	EndIf;
	
	GetResult1 = GetApplicationUpdates.ImportPatchFile(
		FileURL,
		PatchID,
		AuthenticationData);
	
	If GetResult1.Error Then
		GetResult1.Insert("ErrorCode", "PatchFileDownloadError");
	Else
		GetResult1.Insert("ErrorCode", "");
		FileAddress = PutToTempStorage(GetResult1.Content, FormIdentifier);
		GetResult1.Insert("FileAddress", FileAddress);
		GetResult1.Delete("Content");
	EndIf;
	
	Return GetResult1;
	
EndFunction

&AtServer
Procedure InitializeUpdateReceiptPage()
	
	If IsScenarioOfMigrationToNewPlatformVersion(ThisObject)
		Or IsNotRecommendedPlatformVersionMessageScenario(ThisObject) Then
		// Scenario of migrating to a new platform version.
		Items.GetDistributionPackageDecoration.Title =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Выполняется получение файла дистрибутива платформы 1С:Предприятие (%1).';
					|en = 'Receiving a distribution file of 1C:Enterprise platform (%1).';") + " "
					+ NStr("ru = 'Получение файла может занять от нескольких минут до нескольких часов в зависимости от размера обновления,';
							|en = 'Receiving file can take from several minutes to several hours depending on the size of update,';")
					+ " "
					+ NStr("ru = 'скорости подключения к Интернету и производительности компьютера.';
							|en = 'speed of the Internet connection and computer performance.';"),
				StrUpdateSize(ThisObject));
	Else
		// Other scenarios.
		Items.GetDistributionPackageDecoration.Title =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Выполняется получение файлов обновления (%1). Получение файлов может занять от нескольких минут до';
					|en = 'Receiving update files (%1). The receiving may take from several minutes to';")
					+ " " + NStr("ru = 'нескольких часов в зависимости от размера обновления,';
								|en = 'several hours depending on the update size,';")
					+ " " + NStr("ru = 'скорости подключения к Интернету и производительности компьютера.';
								|en = 'speed of the Internet connection and computer performance.';"),
				StrUpdateSize(ThisObject));
	EndIf;
	
	DisplayPage(Items.Pages, Items.AcquisitionAndInstallationPage);
	Items.AcquisitionInstallationPages.CurrentPage = Items.AcquisitionPage;
	
	Items.BackButton.Enabled  = False;
	Items.NextButton.Enabled  = False;
	Items.CancelButton.Visible   = True;
	Items.CancelButton.Enabled = True;
	Items.ContinueWorkingWithCurrentVersion.Visible = False;
	Items.NextButton.Title  = NStr("ru = 'Далее >';
											|en = 'Next >';");
	Items.CancelButton.Title = NStr("ru = 'Отмена';
											|en = 'Cancel';");
	
EndProcedure

&AtServer
Procedure StartUpdatesReceiptInBackground()
	
	// This scenario branch can be processed in the file mode only.
	If Not IsFileIB Or Not IsSystemAdministrator Then
		Raise
			NStr("ru = 'Использование обновления платформы 1С:Предприятие недоступно в текущем режиме работы.';
				|en = '1C:Enterprise platform update cannot be used in the current operation mode.';");
	EndIf;
	
	// Saving platform installation settings.
	SettingsOfUpdate = GetApplicationUpdates.AutoupdateSettings();
	SettingsOfUpdate.InstallationMode = PlatformInstallationMode;
	If Not SavePlatformDistributionPackagesToDirectory Then
		SettingsOfUpdate.PlatformDistributionPackagesDirectory = Undefined;
	ElsIf DirectoryToSavePlatform = GetApplicationUpdatesClientServer.DirectoryToWorkWithPlatformUpdates() Then
		SettingsOfUpdate.PlatformDistributionPackagesDirectory = "";
	Else
		SettingsOfUpdate.PlatformDistributionPackagesDirectory = DirectoryToSavePlatform;
	EndIf;
	GetApplicationUpdates.WriteAutoupdateSettings(
		SettingsOfUpdate);
	
	// Starting a background job to get and install updates.
	ProcedureParameters = New Structure;
	If Not SavePlatformDistributionPackagesToDirectory Then
		ProcedureParameters.Insert("PlatformDistributionPackagesStorageDirectory", Undefined);
	Else
		ProcedureParameters.Insert("PlatformDistributionPackagesStorageDirectory", DirectoryToSavePlatform);
	EndIf;
	ProcedureParameters.Insert("PlatformInstallationMode", PlatformInstallationMode);
	
	ProcedureParameters.Insert("UpdateFilesDetails", UpdateFilesDetails);
	ProcedureParameters.Insert("UpdateContext"      , UpdateContext);
	
	If IsScenarioOfMigrationToNewPlatformVersion(ThisObject)
		Or IsNotRecommendedPlatformVersionMessageScenario(ThisObject) Then
		ProcedureParameters.Insert("UpdateConfiguration" , False);
		ProcedureParameters.Insert("InstallPatches", False);
		ProcedureParameters.Insert("UpdatePlatform"    , True);
	Else
		ProcedureParameters.Insert("UpdateConfiguration" , UpdateConfiguration);
		ProcedureParameters.Insert("InstallPatches", InstallPatches);
		ProcedureParameters.Insert("UpdatePlatform"    , UpdatePlatform);
	EndIf;
	ProcedureParameters.Insert("IsWindowsClient", Common.IsWindowsClient());
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.RunInBackground      = True;
	ExecutionParameters.WaitCompletion   = 0;
	ExecutionParameters.BackgroundJobKey = "GetAndInstallApplicationUpdates"
		+ String(New UUID);
	
	Try
		
		JobStartResult = TimeConsumingOperations.ExecuteFunction(
			ExecutionParameters,
			"GetApplicationUpdates.DownloadAndInstallUpdatesInBackground",
			ProcedureParameters);
		If JobStartResult.Status = "Canceled" Then
			Raise NStr("ru = 'Задание отменено администратором.';
									|en = 'Job is canceled by the administrator.';");
		ElsIf JobStartResult.Status = "Error" Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось выполнить фоновое задание. %1';
					|en = 'Cannot perform a background job. %1';"),
				JobStartResult.DetailErrorDescription);
		EndIf;
		
	Except
		
		EventLogMessage =
			NStr("ru = 'Ошибка запуска задания.';
				|en = 'Job start error.';") + Chars.LF
				+ ErrorProcessing.DetailErrorDescription(ErrorInfo());
		GetApplicationUpdates.WriteErrorToEventLog(EventLogMessage);
		
		DisplayInternalError(NStr("ru = 'Ошибка начала задания.';
										|en = 'Job beginning error.';") + Chars.LF
			+ ErrorProcessing.BriefErrorDescription(ErrorInfo()),
			Undefined,
			EventLogMessage);
		Return;
		
	EndTry;
	
	TimeConsumingOperation = JobStartResult;
	
	If UpdateContext = Undefined Then
		Progress = 0;
		CurrentAction1 = NStr("ru = 'Подготовка к получению обновления...';
								|en = 'Preparing to receive the update…';");
	EndIf;
	
	// Show Receipt and setup page.
	InitializeUpdateReceiptPage();
	
EndProcedure

&AtClient
Procedure DisplayUpdateContextState()
	
	If UpdateContext = Undefined Then
		Return;
	EndIf;
	
	CurrentAction1 = UpdateContext.CurrentAction1;
	Progress        = UpdateContext.Progress;
	
	If Not UpdateContext.UpdateFilesReceived Then
		
		Items.AcquisitionInstallationPages.CurrentPage = Items.AcquisitionPage;
		
	ElsIf UpdateContext.UpdatePlatform Then
		// If the update files are obtained and 1C:Enterprise should be installed,
		// display the 1C:Enterprise installation progress bar.
		
		If PlatformInstallationMode = 0 Then
			Items.AcquisitionInstallationPages.CurrentPage = Items.QuietInstallationPage;
			Items.CancelButton.Enabled                   = False;
		Else
			Items.AcquisitionInstallationPages.CurrentPage = Items.InteractiveInstallationPage;
			Items.CancelButton.Enabled                   = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnRefreshProgressOfUpdateDownloadAndInstallation(Progress, AdditionalParameters) Export
	
	If Progress = Undefined
		Or Progress.Progress = Undefined Then
		Return;
	EndIf;
	
	ProgressStructure = Progress.Progress;
	
	StateSpecifier = ProgressStructure.AdditionalParameters;
	If StateSpecifier = Undefined Then
		Return;
	EndIf;
	
	UpdateContext = StateSpecifier.AddlParameters;
	If UpdateContext = Undefined Then
		Return;
	EndIf;
	
	DisplayUpdateContextState();
	
EndProcedure

&AtClient
Procedure OnCompleteGettingAndInstallingUpdates(Result, AdditionalParameters) Export
	
	// The long-running operation was canceled
	If Result = Undefined Then
		Return;
	EndIf;
	
	StateSpecifier = JobState(Result);
	If StateSpecifier = Undefined Then
		Return;
	EndIf;
	
	UpdateContext = StateSpecifier.AddlParameters;
	If UpdateContext = Undefined Then
		Return;
	EndIf;
	
	// Error, Installation, InstallationCanceled, Completed.
	If StateSpecifier.StatusCode = "Error" Then
		
		Attachments                    = New Array();
		EventLogMessage = UpdateContext.ErrorInfo;
		
		If IsConnectionError(UpdateContext.ErrorName) Then
			DisplayConnectionError(
				UpdateContext.Message,
				EventLogMessage);
		ElsIf UpdateContext.ErrorName = "AuthenticationDataNotFilled" Then
			DisplayConnectionToPortal();
		ElsIf PlatformInstallationMode = 0
			And GetApplicationUpdatesClientServer.IsReturnCodeOfSystemPoliciesRestriction(
				UpdateContext.InstallerReturnCode) Then
			DisplayInternalError(
				UpdateContext.Message,
				NStr("ru = 'Установить с ручными настройками >';
					|en = 'Install with manual settings >';"),
				EventLogMessage);
		Else
			DisplayInternalError(
				UpdateContext.Message,
				Undefined,
				EventLogMessage);
		EndIf;
		
		If Not IsBlankString(UpdateContext.MessageForTechSupport) Then
			Attachments.Add(
				New Structure(
					"Presentation, DataKind, Data",
					NStr("ru = 'Информация об ошибках.txt';
						|en = 'Error information.txt';"),
					"Text",
					UpdateContext.MessageForTechSupport));
		EndIf;
		
		AttachmentsToTechSupport = New FixedArray(Attachments);
		
	ElsIf StateSpecifier.StatusCode = "PlatformInstallationCanceled" Then
		DisplayInformationOnAvailableUpdate();
	ElsIf StateSpecifier.StatusCode = "Completed" Then
		DisplayUpdateReceiptComplete(True);
	EndIf;
	
	TimeConsumingOperation = Undefined;
	
EndProcedure

&AtServerNoContext
Function JobState(Val ResultLongOperation)
	
	Result = New Structure("StatusCode, AddlParameters", "", Undefined);
	
	If ResultLongOperation.Status = "Completed2" Then
		
		Return GetFromTempStorage(ResultLongOperation.ResultAddress);
		
	ElsIf ResultLongOperation.Status = "Error" Then
		
		LogMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при проверке состояния задания. %1';
				|en = 'An error occurred when checking the condition of the job: %1';"),
			ResultLongOperation.DetailErrorDescription);
		GetApplicationUpdates.WriteErrorToEventLog(LogMessage);
		
		Result.StatusCode = "Error";
		MessageToUserText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при проверке состояния задания. %1';
				|en = 'An error occurred when checking the condition of the job: %1';"),
			ResultLongOperation.BriefErrorDescription);
		
		Result.AddlParameters = New Structure(
			"Message, ErrorInfo, ErrorName",
			MessageToUserText,
			LogMessage,
			"CouldNotCheckJobState");
		
		Return Result;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtServerNoContext
Procedure CancelJobExecution(Val TaskID_)
	
	TimeConsumingOperations.CancelJobExecution(TaskID_);
	
EndProcedure

&AtClientAtServerNoContext
Function StrUpdateSize(WizardForm)
	
	SelectedUpdate = WizardForm.UpdatesOptions[WizardForm.UpdateOption];
	If IsScenarioOfMigrationToNewPlatformVersion(WizardForm)
		Or IsNotRecommendedPlatformVersionMessageScenario(WizardForm) Then
		
		Return OnlineUserSupportClientServer.FileSizePresentation(
			SelectedUpdate.Platform.UpdateSize);
		
	Else
		
		Return OnlineUserSupportClientServer.FileSizePresentation(
			?(WizardForm.UpdateConfiguration,
				SelectedUpdate.Configuration.UpdateSize,
				0)
			+ ?(WizardForm.InstallPatches,
				WizardForm.SelectedCorrectionsSize,
				0)
			+ ?(WizardForm.UpdatePlatform,
				SelectedUpdate.Platform.UpdateSize,
				0));
		
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Other wizard steps.

&AtServer
Procedure DisplayInternalError(
	Val ErrorMessage,
	Val ButtonNextTitle = Undefined,
	Val DetailedDescriptionOfInternalError = "")
	
	DisplayServiceMessage(ErrorMessage, ButtonNextTitle, DetailedDescriptionOfInternalError);
	
EndProcedure

&AtServer
Procedure DisplayConnectionToPortal(Val Message = "")
	
	If Items.Pages.CurrentPage <> Items.ConnectionToPortalPage Then
		FillDataToConnect();
	EndIf;
	
	DisplayPage(Items.Pages, Items.ConnectionToPortalPage);
	If IsBlankString(Message) Then
		Items.ConnectionFailurePanel.Visible = False;
	Else
		Items.ConnectionFailurePanel.Visible = True;
		Items.UpdateAcquisitionErrorMessageDecoration.Title =
			OnlineUserSupportClientServer.FormattedHeader(Message);
	EndIf;
	
	Items.BackButton.Enabled  = True;
	Items.NextButton.Enabled  = True;
	Items.NextButton.Title    = NStr("ru = 'Далее >';
											|en = 'Next >';");
	Items.CancelButton.Visible   = True;
	Items.CancelButton.Enabled = True;
	Items.ContinueWorkingWithCurrentVersion.Visible = False;
	
EndProcedure

&AtServer
Procedure FillDataToConnect()
	
	If Not IsSystemAdministrator Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	AuthenticationData = OnlineUserSupport.OnlineSupportUserAuthenticationData();
	SetPrivilegedMode(False);
	If AuthenticationData = Undefined Then
		Login  = "";
		Password = "";
	Else
		Login  = AuthenticationData.Login;
		Password = String(New UUID);
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayServiceMessage(Message, ButtonNextTitle, DetailedDescriptionOfInternalError = "")
	
	DetailedErrorDetails = DetailedDescriptionOfInternalError;
	DisplayPage(Items.Pages, Items.ServiceMessagePage);
	
	If Upper(Left(Message, 6)) <> "<BODY>" Then
		// Displaying a reference to go to the event log.
		PresentationHTML =
			OnlineUserSupportClientServer.SubstituteDomain(
				"<body>" + StrReplace(Message, Chars.LF, "<br />")
				+ "<br />"
				+ "<br />" + NStr("ru = 'Технические подробности см. в <a href=""open:log"" >журнале регистрации</a>.';
									|en = 'For technical details, see <a href=""open:log"" >Event log</a>.';")
				+ ?(SendMessagesToTechnicalSupportAvailable,
					"<br /><br />"
					+ NStr("ru = 'При возникновении проблем напишите в <a href=""mailto:webits-info@1c.eu"">техподдержку</a>.';
							|en = 'If issues occur, contact <a href=""mailto:webits-info@1c.eu"">technical support</a>.';"),
					"")
				+ "</body>",
				OnlineUserSupport.ServersConnectionSettings().OUSServersDomain);
		Items.ServiceMessageDecoration.Title =
			OnlineUserSupportClientServer.FormattedHeader(PresentationHTML);
	Else
		Items.ServiceMessageDecoration.Title =
			OnlineUserSupportClientServer.FormattedHeader(Message);
	EndIf;
	
	Items.BackButton.Enabled =
		(AvailableUpdateInformation <> Undefined And IsBlankString(AvailableUpdateInformation.ErrorName));
	Items.CancelButton.Visible   = True;
	Items.CancelButton.Enabled = True;
	Items.ContinueWorkingWithCurrentVersion.Visible = False;
	Items.CancelButton.Title = NStr("ru = 'Отмена';
											|en = 'Cancel';");
	
	If ButtonNextTitle = Undefined Then
		Items.NextButton.Enabled  = False;
		Items.NextButton.Title  = NStr("ru = 'Далее >';
												|en = 'Next >';");
	Else
		Items.NextButton.Enabled  = True;
		Items.NextButton.Title  = ButtonNextTitle;
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayConnectionError(Val Message, Val ConnectionErrorDescription)
	
	DisplayPage(Items.Pages, Items.ServerConnectionFailedPage);
	
	DetailedErrorDetails = ConnectionErrorDescription;
	If IsBlankString(Message) Then
		Items.ConnectionFailureDecoration.Visible = False;
	Else
		Items.ConnectionFailureDecoration.Visible = True;
		Items.ConnectionFailureDecoration.Title = Message;
	EndIf;
	
	Items.BackButton.Enabled =
		(IsBlankString(AvailableUpdateInformation.ErrorName)
		Or IsNotRecommendedPlatformVersionMessageScenario(ThisObject));
	Items.NextButton.Title    = NStr("ru = 'Повторить попытку подключения >';
											|en = 'Try connecting again >';");
	Items.NextButton.Enabled  = True;
	Items.CancelButton.Visible   = True;
	Items.CancelButton.Enabled = True;
	Items.ContinueWorkingWithCurrentVersion.Visible = False;
	
EndProcedure

&AtClient
Procedure DisplayUpdateReceiptComplete(Initialize = False)
	
	If Not UpdateConfiguration Then
		
		// Displaying completion of installing patches or a platform.
		DisplayUpdateReceiptCompleteAtServer(Initialize);
		
	Else
		
		Items.AcquisitionInstallationPages.CurrentPage = Items.AcquisitionCompletedPage;
		Progress        = 100;
		CurrentAction1 = "";
		
		If AdministrationParameters = Undefined Then
			
			NotifyDescription = New NotifyDescription(
				"AfterGetAdministrationParameters",
				ThisObject,
				Initialize);
			FormCaption = NStr("ru = 'Установка обновления';
									|en = 'Update setup';");
			If IsFileIB Then
				NoteLabel = NStr("ru = 'Для установки обновления необходимо ввести
					|параметры администрирования информационной базы';
					|en = 'To install the update, enter
					|the infobase administration parameters';");
				PromptForClusterAdministrationParameters = False;
			Else
				NoteLabel = NStr("ru = 'Для установки обновления необходимо ввести параметры
					|администрирования кластера серверов и информационной базы';
					|en = 'To install the update, enter
					|the server cluster and infobase administration parameters';");
				PromptForClusterAdministrationParameters = True;
			EndIf;
			
			IBConnectionsClient.ShowAdministrationParameters(
				NotifyDescription,
				True,
				PromptForClusterAdministrationParameters,
				AdministrationParameters,
				FormCaption,
				NoteLabel);
			
		Else
			
			AfterGetAdministrationParameters(AdministrationParameters, Initialize);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterGetAdministrationParameters(Result, Initialize) Export
	
	If Result <> Undefined Then
		
		AdministrationParameters = Result;
		AfterObtainedAdministrationParametersAtServer(
			AdministrationParameters,
			Initialize);
		
		If Initialize
			And Items.Pages.CurrentPage = Items.UpdateModeSelectionFileMode Then
			
			Items.BackupFileLabel.Title =
				ConfigurationUpdateClient.BackupCreationTitle(ThisObject);
			
		EndIf;
		
	Else
		
		WarningText = NStr("ru = 'Для установки обновления необходимо ввести параметры администрирования.';
									|en = 'To install the update, enter the administration parameters.';");
		ShowMessageBox(, WarningText);
		
		MessageText = NStr("ru = 'Не удалось установить обновление программы, т.к. не были введены
			|корректные параметры администрирования информационной базы.';
			|en = 'Cannot install the application update as the specified
			|infobase administration parameters are invalid.';");
		GetApplicationUpdatesClient.WriteErrorToEventLog(MessageText);
		
		DisplayInternalError(
			NStr("ru = 'Не удалось установить обновление программы, т.к. не были введены
				|корректные параметры администрирования информационной базы.</body>';
				|en = 'Cannot install the application update as correct parameters of the infobase management
				|were not entered.</body>';"),
				,
				MessageText);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayUpdateReceiptCompleteAtServer(Val Initialize)
	
	SelectedUpdate = UpdatesOptions[UpdateOption];
	
	If IsScenarioOfMigrationToNewPlatformVersion(ThisObject)
			Or IsNotRecommendedPlatformVersionMessageScenario(ThisObject)
			Or (Not UpdateConfiguration And UpdatePlatform) Then
		
		// Update completed. "Not UpdateConfiguration" means only 1C:Enterprise and patches were installed.
		// 
		
		DisplayPage(Items.Pages, Items.PlatformInstallationCompletedPage);
		
		TitleTemplate1 = NStr("ru = '<body>Установлена версия: <b>%1</b>
			|<br />Дистрибутив платформы скопирован в каталог <a href=""open:DistribFolder"">%2</a></body>';
			|en = '<body>Version is installed: <b>%1</b>
			|<br />Platform distribution is copied to the directory <a href=""open:DistribFolder"">%2</a></body>';");
		
		InstalledPlatformVersion = SelectedUpdate.Platform.Version;
		PlatformInstallationDirectory =
			GetApplicationUpdatesClientServer.OneCEnterprisePlatformInstallationDirectory(InstalledPlatformVersion);
		
		Items.InstallationCompleteInformationDecoration.Title =
			OnlineUserSupportClientServer.FormattedHeader(
				StringFunctionsClientServer.SubstituteParametersToString(
					TitleTemplate1,
					InstalledPlatformVersion,
					UpdateContext.PlatformDistributionPackageDirectory));
		
		If IsBlankString(Items.DecorationCompletedCreateBackupPage.Title) Then
			Items.DecorationCompletedCreateBackupPage.Title =
				InstructionTextOnMigrationToNewPlatformVersion(True);
		EndIf;
		
		If IsBlankString(Items.DecorationCompletedDoNotCreateBackupPage.Title) Then
			Items.DecorationCompletedDoNotCreateBackupPage.Title =
				InstructionTextOnMigrationToNewPlatformVersion(False);
		EndIf;
		
		If CreateBackup Then
			Items.PagesInstructionInstallationCompleted.CurrentPage = Items.CompletedCreateBackupPage;
		Else
			Items.PagesInstructionInstallationCompleted.CurrentPage = Items.CompletedDoNotCreateBackupPage;
		EndIf;
		
		Items.BackButton.Enabled  = True;
		Items.NextButton.Enabled  = True;
		Items.CancelButton.Visible   = True;
		Items.CancelButton.Enabled = True;
		Items.ContinueWorkingWithCurrentVersion.Visible = False;
		Items.NextButton.Title  = NStr("ru = 'Готово';
												|en = 'Finish';");
		Items.CancelButton.Title = NStr("ru = 'Отмена';
												|en = 'Cancel';");
		
	ElsIf Not UpdateConfiguration Then
		
		// Only patches are installed.
		DisplayPage(Items.Pages, Items.PageInstallCorrections);
		
		// Connections.UsersSessions
		ConnectionsInfo = IBConnections.ConnectionsInformation(False);
		// End Connections.UsersSessions
		
		Items.ActiveUsersDecoration.Visible = ConnectionsInfo.HasActiveConnections;
		
		Items.BackButton.Enabled  = True;
		Items.NextButton.Enabled  = True;
		Items.CancelButton.Visible   = False;
		Items.ContinueWorkingWithCurrentVersion.Visible = False;
		Items.NextButton.Title  = NStr("ru = 'Готово';
												|en = 'Finish';");
		
	Else
		
		Items.CancelButton.Visible = True;
		
		If IsFileIB Then
			
			DisplayPage(Items.Pages, Items.UpdateModeSelectionFileMode);
			
			If Initialize Then
				
				Items.UpdateOrderFile.Visible = Not IsBlankString(
					SelectedUpdate.Configuration.URLOrderOfUpdate);
				
				If Items.UpdateOrderFile.Visible Then
					Items.UpdateOrderFileLabel.Title =
						OnlineUserSupportClientServer.FormattedHeader(
							StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = '<body>Для продолжения необходимо ознакомиться с <a href=""%1"">порядком обновления</a>.</body>';
									|en = '<body>To continue, read <a href=""%1"">the update procedure</a>.</body>';"),
								SelectedUpdate.Configuration.URLOrderOfUpdate));
				EndIf;
				
				FillUpdatesInstallationSettingsFileMode();
				
			EndIf;
			
			// Connections.UsersSessions
			ConnectionsInfo = IBConnections.ConnectionsInformation(False);
			// End Connections.UsersSessions
			
			Items.ConnectionsGroup.Visible = ConnectionsInfo.HasActiveConnections;
			
			If ConnectionsInfo.HasActiveConnections Then
				AllPages = Items.ActiveUsersPanel.ChildItems;
				
				If ConnectionsInfo.HasCOMConnections Then
					Items.ActiveUsersPanel.CurrentPage = AllPages.ActiveConnections;
				ElsIf ConnectionsInfo.HasDesignerConnection Then
					Items.ActiveUsersPanel.CurrentPage = AllPages.DesignerConnection;
				Else
					Items.ActiveUsersPanel.CurrentPage = AllPages.ActiveUsers;
				EndIf;
				
			EndIf;
			
			Items.BackButton.Enabled = True;
			Items.NextButton.Enabled = (Not ConnectionsInfo.HasActiveConnections
				Or UpdateMode = 1);
			Items.CancelButton.Enabled = True;
			Items.ContinueWorkingWithCurrentVersion.Visible = False;
			Items.NextButton.Title = ?(
				UpdateMode = 0,
				NStr("ru = 'Далее >';
					|en = 'Next >';"),
				NStr("ru = 'Готово';
					|en = 'Finish';"));
			
			Items.CancelButton.Title = NStr("ru = 'Отмена';
													|en = 'Cancel';");
			
		Else
			
			DisplayPage(Items.Pages, Items.UpdateModeSelectionServerMode);
			If Initialize Then
				
				Items.OrderOfUpdateServer.Visible = Not IsBlankString(
					SelectedUpdate.Configuration.URLOrderOfUpdate);
				
				If Items.OrderOfUpdateServer.Visible Then
					Items.UpdateOrderServerLabel.Title =
						OnlineUserSupportClientServer.FormattedHeader(
							StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = '<body>Для продолжения необходимо ознакомиться с <a href=""%1"">порядком обновления</a>.</body>';
									|en = '<body>To continue, read <a href=""%1"">the update procedure</a>.</body>';"),
								SelectedUpdate.Configuration.URLOrderOfUpdate));
				EndIf;
				
				FillUpdatesInstallationSettingsClientServerMode();
				
			EndIf;
			
			If SchedulerTaskCode = 0 And Not UpdateDateTimeSet Then
				UpdateDateTime = Return_Date(
					AddDays(BegOfDay(CurrentSessionDate()), 1), UpdateDateTime);
				UpdateDateTimeSet = True;
			EndIf;
			
			DeferredHandlersAvailable = (InfobaseUpdate.DeferredUpdateStatus() = "UncompletedStatus");
			Items.DeferredHandlersLabel.Visible = DeferredHandlersAvailable;
			
			RestartInformationPanelPages1 = Items.RestartInformationPages1.ChildItems;
			Items.RestartInformationPages1.CurrentPage = ?(
				UpdateMode = 0,
				RestartInformationPanelPages1.RestartNowPage1,
				RestartInformationPanelPages1.ScheduledRestartPage);
			
			If UpdateMode <> 0 Then
				
				// Connections.UsersSessions
				ConnectionsInfo = IBConnections.ConnectionsInformation(False);
				// End Connections.UsersSessions
				
				ConnectionsPresent = (ConnectionsInfo.HasActiveConnections And UpdateMode = 0);
				Items.ConnectionsGroup1.Visible = ConnectionsPresent;
				
				If ConnectionsPresent Then
					AllPages = Items.ActiveUsersPanel1.ChildItems;
					Items.ActiveUsersPanel1.CurrentPage = ? (ConnectionsInfo.HasCOMConnections, 
						AllPages.ActiveConnections1, AllPages.ActiveUsers1);
				EndIf;
				
			EndIf;
			
			Items.UpdateDateTimeField.Enabled = (UpdateMode = 2);
			Items.Email.Enabled   = EmailReport;
			
			Items.BackButton.Enabled  = True;
			Items.NextButton.Enabled  = True;
			Items.CancelButton.Enabled = True;
			Items.ContinueWorkingWithCurrentVersion.Visible = False;
			Items.NextButton.Title = ?(
				UpdateMode = 0,
				NStr("ru = 'Далее >';
					|en = 'Next >';"),
				NStr("ru = 'Готово';
					|en = 'Finish';"));
			Items.CancelButton.Title = NStr("ru = 'Отмена';
													|en = 'Cancel';");
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillUpdatesInstallationSettingsFileMode()
	
	// StandardSubsystems.ConfigurationUpdate
	SettingsOfUpdate = ConfigurationUpdate.ConfigurationUpdateSettings();
	UpdateMode                   = SettingsOfUpdate.UpdateMode;
	CreateDataBackup           = SettingsOfUpdate.CreateDataBackup;
	IBBackupDirectoryName       = SettingsOfUpdate.IBBackupDirectoryName;
	RestoreInfobase = SettingsOfUpdate.RestoreInfobase;
	// End StandardSubsystems.ConfigurationUpdate
	
EndProcedure

&AtServer
Procedure FillUpdatesInstallationSettingsClientServerMode()
	
	// StandardSubsystems.ConfigurationUpdate
	SettingsOfUpdate = ConfigurationUpdate.ConfigurationUpdateSettings();
	UpdateMode       = SettingsOfUpdate.UpdateMode;
	UpdateDateTime   = SettingsOfUpdate.UpdateDateTime;
	EmailReport   = SettingsOfUpdate.EmailReport;
	Email = SettingsOfUpdate.Email;
	SchedulerTaskCode = SettingsOfUpdate.SchedulerTaskCode;
	// End StandardSubsystems.ConfigurationUpdate
	
EndProcedure

&AtClientAtServerNoContext
Function Return_Date(Date, Time)
	Return Date(Year(Date), Month(Date), Day(Date), Hour(Time), Minute(Time), Second(Time));
EndFunction

// Adds a set number of days to the date.
//
// Parameters:
//  Date		- Date	- Source date.
//  NumberOfDays	- Number	- a number of days added to the source date.
//
&AtClientAtServerNoContext
Function AddDays(Val Date, Val NumberOfDays)
	
	If NumberOfDays > 0 Then
		Difference = Day(Date) + NumberOfDays - Day(EndOfMonth(Date));
		If Difference > 0 Then
			NewDate = AddMonth(Date, 1);	
			Return Date(Year(NewDate), Month(NewDate), Difference, 
				Hour(NewDate), Minute(NewDate), Second(NewDate));
		EndIf;
	ElsIf NumberOfDays < 0 Then
		Difference = Day(Date) + NumberOfDays - Day(BegOfMonth(Date));
		If Difference < 1 Then
			NewDate = AddMonth(Date, -1);	
			Return Date(Year(NewDate), Month(NewDate), Day(EndOfMonth(NewDate)) - Difference, 
				Hour(NewDate), Minute(NewDate), Second(NewDate));
		EndIf;
	EndIf; 
	Return Date(Year(Date), Month(Date), Day(Date) + NumberOfDays, Hour(Date), Minute(Date), Second(Date));
	
EndFunction

&AtServer
Procedure DisplayNotRecommendedPlatformVersion()
	
	DisplayPage(Items.Pages, Items.PlatformVersionNotRecommendedPage);
	If Not GetApplicationUpdates.InternalCanUsePlatformUpdatesReceipt(False) Then
		// If 1C:Enterprise update is unavailable, show only the user message.
		// 
		Items.BackButton.Visible          = False;
		Items.NextButton.Visible          = False;
		Items.CancelButton.DefaultButton = True;
		Items.Help.Visible              = False;
	Else
		Items.BackButton.Enabled = False;
		Items.NextButton.Title   = NStr("ru = 'Обновить платформу >';
												|en = 'Update platform >';");
		Items.NextButton.Visible   = True;
		Items.NextButton.Enabled = True;
	EndIf;
	
	Items.CancelButton.Enabled = True;
	Items.ContinueWorkingWithCurrentVersion.Visible = Not MustExit;
	Items.CancelButton.Title   = NStr("ru = 'Завершить работу';
											|en = 'End session';");
	
EndProcedure

&AtServer
Function NewPlatformVersionPageTitle()
	
	SelectedUpdate = UpdatesOptions[UpdateOption];
	
	Return ?(SelectedUpdate.Platform.UpdateRecommended,
		NStr("ru = 'Рекомендуется перейти на новую версию платформы';
			|en = 'It is recommended that you migrate to a new platform version ';"),
		NStr("ru = 'Доступна новая версия платформы';
			|en = 'A new platform version is available';"));
	
EndFunction

&AtServer
Function InstructionTextOnMigrationToNewPlatformVersion(CreateBackupParameter)
	
	Rows = New Array;
	
	IsBaseConfigurationVersion = GetApplicationUpdates.IsBaseConfigurationVersion();
	BackupSubsystemImplemented =
		Common.SubsystemExists("StandardSubsystems.IBBackup");
	
	If BackupSubsystemImplemented
		And CreateBackupParameter Then
		
		If Common.SubsystemExists("StandardSubsystems.UsersSessions") Then
			Rows.Add(
				NStr("ru = '<body>Будет автоматически завершена работа <a href=""open:ActiveUsers"">активных пользователей</a> программы, создана резервная копия';
					|en = '<body>Active <a href=""open:ActiveUsers""> users</a> of the application will be automatically closed and backup will be created';"));
		Else
			Rows.Add(
				NStr("ru = '<body>Будет автоматически завершена работа активных пользователей программы, создана резервная копия';
					|en = '<body>Active users will be automatically closed and backup will be created';"));
		EndIf;
		
		If IsBaseConfigurationVersion Then
			Rows.Add(
				NStr("ru = 'информационной базы и запущен сеанс работы с программой на новой версии платформы.<body>';
					|en = 'of infobase and application session is started on a new platform version.<body>';"));
		Else
			Rows.Add(
				NStr("ru = 'информационной базы и запущен сеанс работы с программой на новой версии платформы.
					|<br />На компьютерах других пользователей программы необходимо обновить платформу 1С:Предприятие вручную.</body>';
					|en = 'of infobase and application session is started on a new platform version. 
					|<br /> 1C:Enterprise platform should be updated manually on the computers of other application users.</body>';"));
		EndIf;
		
	Else
		
		Rows.Add(NStr("ru = '<body>Чтобы начать работать на новой версии платформы:';
							|en = '<body>To start using a new platform version:';"));
		If Common.SubsystemExists("StandardSubsystems.UsersSessions") Then
			Rows.Add(
				NStr("ru = '- завершите работу всех <a href=""open:ActiveUsers"">активных пользователей</a> программы;';
					|en = '- close all <a href=""open:ActiveUsers""> active users </a> in the application;';"));
		Else
			Rows.Add(NStr("ru = '- завершите работу всех активных пользователей программы;';
								|en = '- close all active users in the application;';"));
		EndIf;
		
		Rows.Add(NStr("ru = '- завершите текущий сеанс работы с программой;';
							|en = '- end the current application session;';"));
		
		If Not IsBaseConfigurationVersion Then
			Rows.Add(NStr("ru = '- установите новую версию платформы на компьютеры других пользователей программы;';
								|en = '- install a new platform version on the computers of other application users;';"));
		EndIf;
		
		Rows.Add(NStr("ru = '- откройте программу на новой версии платформы;';
							|en = '- open the application on a new platform version;';"));
		
		If BackupSubsystemImplemented Then
			Rows.Add(
				NStr("ru = '<br />Перед началом работы на новой версии платформы рекомендуется создать резервную копию.</body>';
					|en = '<br />Before starting to use a new platform version, it is recommended that you create a backup.</body>';"));
		Else
			Rows.Add(
				NStr("ru = '<br />Перед началом работы на новой версии платформы рекомендуется <a href=""open:RCInstruction"">создать резервную копию</a>.</body>';
					|en = '<br />Before starting to use a new platform version <a href=""open:RCInstruction"">create a backup</a>.</body>';"));
		EndIf;
		
	EndIf;
	
	Return OnlineUserSupportClientServer.FormattedHeader(
		StrConcat(Rows, Chars.LF + "<br />"));
	
EndFunction

&AtClient
Procedure OnChangeBackupParameters(BackupParameters, AddlParameters) Export
	
	If TypeOf(BackupParameters) = Type("Structure") Then
		FillPropertyValues(ThisObject, BackupParameters);
		DisplayUpdateReceiptComplete();
		Items.BackupFileLabel.Title =
			ConfigurationUpdateClient.BackupCreationTitle(ThisObject);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure SetAdministratorPassword(Val AdministrationParameters)
	
	IBAdministrator = InfoBaseUsers.FindByName(
		AdministrationParameters.InfobaseAdministratorName);
	
	If Not IBAdministrator.StandardAuthentication Then
		
		IBAdministrator.StandardAuthentication = True;
		IBAdministrator.Password = AdministrationParameters.InfobaseAdministratorPassword;
		IBAdministrator.Write();
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ErrorsPanelVisibility()
	
	If Common.SubsystemExists("StandardSubsystems.AccountingAudit") Then
		ModuleAccountingAudit       = Common.CommonModule("AccountingAudit");
		SummaryInformationOnChecksKinds = ModuleAccountingAudit.SummaryInformationOnChecksKinds("SystemChecks");
		Return SummaryInformationOnChecksKinds.Count > 0;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtServerNoContext
Function SaveFlagOfPatchAutoDownloadAndInstallationAtServer(
	Val ImportAndInstallCorrectionsAutomatically)
	
	If ImportAndInstallCorrectionsAutomatically
		And Not AuthenticationDataOfOnlineSupportUserFilled() Then
		Return False;
	Else
		GetApplicationUpdatesServerCall.EnableDisableAutomaticPatchesInstallation(
			ImportAndInstallCorrectionsAutomatically);
		Return True;
	EndIf;
	
EndFunction

&AtServerNoContext
Procedure SaveUpdateReleaseNotificationOptionAtServer(Val NewValue)
	
	SettingsOfUpdate = GetApplicationUpdates.AutoupdateSettings();
	SettingsOfUpdate.UpdateReleaseNotificationOption = NewValue;
	
	GetApplicationUpdates.WriteAutoupdateSettings(SettingsOfUpdate);
	
EndProcedure

&AtServer
Procedure OnChangePatchInstallationScheduleAtServer(Val Schedule)
	
	GetApplicationUpdatesServerCall.SetPatchesInstallationJobSchedule(Schedule);
	
	Items.CorrectionsImportDecorationSchedule.Title =
		OnlineUserSupportClientServer.SchedulePresentation(Schedule);
	
EndProcedure

&AtServer
Function InitializeObtainingUpdatesAtServer()
	
	Result = New Structure;
	Result.Insert("StartGetAndInstallUpdates", False);
	
	If Not UsernamePasswordChanged
		And Not AuthenticationDataOfOnlineSupportUserFilled() Then
		
		DisplayConnectionToPortal();
		Return Result;
		
	ElsIf UpdateFilesDetails <> Undefined
		And IsBlankString(UpdateFilesDetails.ErrorName) Then
		
		// File details were successfully obtained. Resume loading and installing the updates.
		// This execution path is triggered when either a file acquisition error occurs
		// or the user cancels the installation interactively.
		// 
		
		If Items.Pages.CurrentPage = Items.ServiceMessagePage
			And UpdateContext <> Undefined
			And GetApplicationUpdatesClientServer.IsReturnCodeOfSystemPoliciesRestriction(
				UpdateContext.InstallerReturnCode)
			And PlatformInstallationMode = 0 Then
			
			// Bypass the security policy errors when installing in silent (default) mode.
			// If a security policy restriction error occurs, run interactive installation.
			// 
			PlatformInstallationMode = 1;
			
		EndIf;
		
		Result.StartGetAndInstallUpdates = True;
		
	Else
		
		// Get the update file details in cases they are not yet obtained
		// or an error occurred when obtaining them.
		// 
		
		SelectedUpdate            = UpdatesOptions[UpdateOption];
		SelectedPatchesUpdate = ?(UpdateConfiguration,
			UpdatesOptions[UpdateOption],
			UpdatesOptions[CurrentVersionID()]);
		
		If IsScenarioOfMigrationToNewPlatformVersion(ThisObject)
			Or IsNotRecommendedPlatformVersionMessageScenario(ThisObject) Then
			
			ConfigurationUpdateInformation = Undefined;
			PlatformUpdateInformation    = SelectedUpdate.Platform;
			
		Else
			
			ConfigurationUpdateInformation = ?(
				UpdateConfiguration,
				SelectedUpdate.Configuration,
				Undefined);
			
			PlatformUpdateInformation = ?(
				UpdatePlatform,
				SelectedUpdate.Platform,
				Undefined);
			
		EndIf;
		
		If InstallPatches Then
			PatchesParameters = New Structure;
			PatchesParameters.Insert("PatchAddress"                   , PatchAddress);
			PatchesParameters.Insert("PatchesToGetIDs",
				SelectedPatchesUpdate.SelectedPatches.UnloadValues());
		Else
			PatchesParameters = Undefined;
		EndIf;
		
		UpdateFilesDetails = UpdateFilesDetailsAtServer(
			ConfigurationUpdateInformation,
			PatchesParameters,
			PlatformUpdateInformation,
			Login,
			Password,
			UsernamePasswordChanged);
		
		If IsBlankString(UpdateFilesDetails.ErrorName) Then
			
			// Authorization is successful.
			UsernamePasswordChanged = False;
			Login  = "";
			Password = "";
			
			Result.StartGetAndInstallUpdates = True;
			
		Else
			
			// Processing an error of getting information about available updates.
			If IsConnectionError(UpdateFilesDetails.ErrorName) Then
				
				DisplayConnectionError(
					UpdateFilesDetails.Message,
					UpdateFilesDetails.ErrorInfo);
				
			ElsIf UpdateFilesDetails.ErrorName = "AuthenticationDataNotFilled" Then
				
				DisplayConnectionToPortal();
				
			ElsIf UpdateFilesDetails.ErrorName = "LoginError" Then
				
				DisplayConnectionToPortal(UpdateFilesDetails.Message);
				
			Else
				
				DisplayServiceMessage(
					UpdateFilesDetails.Message,
					NStr("ru = 'Повторить попытку >';
						|en = 'Retry >';"),
					UpdateFilesDetails.ErrorInfo);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Result.StartGetAndInstallUpdates Then
		If IsFileIB Then
			StartUpdatesReceiptInBackground();
		Else
			InitializeUpdateReceiptPage();
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure AfterObtainedAdministrationParametersAtServer(
	Val AdministrationParameters,
	Val Initialize)
	
	SetAdministratorPassword(AdministrationParameters);
	DisplayUpdateReceiptCompleteAtServer(Initialize);
	
EndProcedure

&AtClient
Procedure Select1CEnterpriseDestinationDirectory(Item)
	
	#If Not WebClient Then
	
	ChoiceDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	ChoiceDialog.Title = NStr("ru = 'Каталог хранения дистрибутивов платформы 1С:Предприятие';
									|en = 'Directory for storing 1C:Enterprise platform distributions ';");
	ChoiceDialog.Directory   = Item.EditText;
	If Not ChoiceDialog.Choose() Then
		Return;
	EndIf;
	
	DirectoryToSavePlatform = ChoiceDialog.Directory;
	
	#EndIf
	
EndProcedure

&AtClientAtServerNoContext
Function DefaultPlatformDistributionPackageDirectory()
	
	Return GetApplicationUpdatesClientServer.DirectoryToWorkWithPlatformUpdates()
		+ ?(GetApplicationUpdatesClientServer.Is64BitApplication(), "setup_64\", "setup\");
	
EndFunction

#EndRegion