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
Var RefreshInterface; // Boolean

&AtClient
Var AutoCheckUpdatesBeforeChange;	// Number

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IsSystemAdministrator                = Users.IsFullUser(, True);
	DataSeparationEnabled                     = Common.DataSeparationEnabled();
	IsStandaloneWorkplace              = Common.IsStandaloneWorkplace();
	SeparatedDataUsageAvailable = Common.SeparatedDataUsageAvailable();
	
	If Common.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		AppSettingsModule = Common.CommonModule("ApplicationSettings");
		AppSettingsModule.OnlineSupportAndServicesOnCreateAtServer(
			ThisObject,
			Cancel,
			StandardProcessing);
	Else
		
		Items.AddressClassifierSettings.Visible       = False;
		Items.ImportCurrenciesRatesDataProcessorGroup.Visible   = False;
		Items.DeclensionsGroup.Visible                      = False;
		Items.MonitoringCenterGroup.Visible               = False;
		Items.AddInsGroup.Visible              = False;
		Items.ConversationsGroup.Visible                     = False;
		
	EndIf;
	
	OnlineSupportServicesSetUpAccessLock();
	
	RefreshOnlineSupportStatus();
	
	OSLSubsystemsIntegration.OnCreateFormOnlineSupportAndServices(
		ThisObject);
	AppSettingsOSLClientOverridable.OnCreateFormOnlineSupportAndServices(
		ThisObject);
		
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
		AppSettingsModuleClient.OnlineSupportAndServicesOnOpen(ThisObject, Cancel);
	EndIf;
	
	AutoCheckUpdatesBeforeChange = AutomaticUpdatesCheck;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
		AppSettingsModuleClient.OnlineSupportAndServicesProcessNotification(
			ThisObject,
			EventName,
			Parameter,
			Source);
	EndIf;
	
	If EventName = "OnlineSupportDisabled" Or EventName = "OnlineSupportEnabled" Then
		RefreshReusableValues();
	EndIf;
	
	If EventName = "HideConfidentialInformation" Then
		RefreshOnlineSupportStatus();
	EndIf;
	
	If EventName = "OnlineSupportEnabled" Then
		// Process Online support connection.
		EnteredAuthenticationData = Parameter;	// Arbitrary
		If EnteredAuthenticationData <> Undefined Then
			AuthenticationData = EnteredAuthenticationData;
			DisplayOUSConnectionState(ThisObject);
		EndIf;
	EndIf;
	
	If EventName = "OperationsWithExternalResourcesAllowed" Then
		Items.GroupOnlineSupportServicesAccessLock.Visible = False;
	EndIf;
	
	// OnlineUserSupport.ClassifiersOperations
	
	If (EventName = "OnlineSupportDisabled"
		Or EventName = "OnlineSupportEnabled")
		And CommonClient.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		
		ModuleClassifiersManagementServerCall = CommonClient.CommonModule(
			"ClassifiersOperationsServerCall");
		Result = ModuleClassifiersManagementServerCall.ClassifiersUpdateSettings();
		
		If EventName = "OnlineSupportDisabled" Then
			If Result.UpdateOption = 1 Then
				Items.DecorationClassifiersUpdateDisabled.Visible = True;
			EndIf;
		ElsIf EventName = "OnlineSupportEnabled" Then
			If Result.Schedule <> Undefined Then
				Items.ClassifiersUpdateScheduleDecoration.Title =
					OnlineUserSupportClientServer.SchedulePresentation(
						Result.Schedule);
			EndIf;
			ClassifiersUpdateOption = Result.UpdateOption;
			Items.DecorationClassifiersUpdateDisabled.Visible = False;
		EndIf;
		
	EndIf;
	
	// End OnlineUserSupport.ClassifiersOperations
	
	// OnlineUserSupport.GetAddIns
	
	If CommonClient.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		ModuleGetAddInsClient =
			CommonClient.CommonModule("GetAddInsClient");
		ModuleGetAddInsClient.OnlineSupportAndServicesProcessNotification(
			ThisObject,
			EventName,
			Parameter,
			Source);
	EndIf;
	
	// End OnlineUserSupport.GetAddIns
	
	// OnlineUserSupport.GettingStatutoryReports
	
	If CommonClient.SubsystemExists("OnlineUserSupport.GettingStatutoryReports") Then
		StatutoryReportsGetterModuleClient =
			CommonClient.CommonModule("GettingStatutoryReportsClient");
		StatutoryReportsGetterModuleClient.OnlineSupportAndServicesProcessNotification(
			ThisObject,
			EventName,
			Parameter,
			Source);
	EndIf;
	
	// End OnlineUserSupport.GettingStatutoryReports
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	RefreshApplicationInterface();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region EventHandlersSSL

&AtClient
Procedure UseAddressesWebServiceOnChange(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		OnChangeWebServiceAddressesUsage(UseAddressesWebService);
	EndIf;
	
EndProcedure

&AtClient
Procedure AllowDataSendingOnChange(Item)
	
	OnChangeModeOfDataExportToMonitoringCenter(Item);
	
EndProcedure

&AtClient
Procedure AllowSendDataTo(Item)
	
	OnChangeModeOfDataExportToMonitoringCenter(Item);
	
EndProcedure

&AtClient
Procedure ForbidSendingDataOnChange(Item)
	
	OnChangeModeOfDataExportToMonitoringCenter(Item);
	
EndProcedure

&AtClient
Procedure MonitoringCenterServiceAddressOnChange(Item)
	
	MonitoringCenterServiceAddressOnChangeAtServer(Item.Name);
	
EndProcedure

&AtClient
Procedure WriteIBUpdateDetailsToEventLogOnChange(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
		AppSettingsModuleClient.OnlineSupportAndServicesOnConstantChange(
			ThisObject,
			Item);
	EndIf;

EndProcedure

&AtClient
Procedure UseMorpherDeclinationServiceOnChange(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		
		OnChangeSSLConstantAtServer("UseMorpherDeclinationService");
		
		AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
		AppSettingsModuleClient.OnlineSupportAndServicesOnConstantChange(
			ThisObject,
			Item);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region CoreISL

&AtClient
Procedure OUSUsernameDecorationURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	If Item.Name = "OUSUsernameDecoration" Then
		StandardProcessing = False;
		OnlineUserSupportClient.OpenUserPersonalAccount();
	EndIf;
	
EndProcedure

&AtClient
Procedure NoteOnlineSupportServicesAccessLockURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	StandardProcessing = False;
	OpenForm("CommonForm.OnlineSupportServicesAccessLock");
	
EndProcedure

#EndRegion

#Region ClassifiersOperations

&AtClient
Procedure ClassifiersFileOnChange(Item)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		OnChangeConstant("ClassifiersFile", ClassifiersFile, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClassifiersFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	FileDialog = New FileDialog(FileDialogMode.Open);
	FileDialog.Title = NStr("ru = 'Выберите файл с классификаторами';
										|en = 'Select a file with classifiers';");
	FileDialog.Filter    = NStr("ru = 'Файл классификаторов (*.zip)|*.zip';
										|en = 'Classifier file (*.zip)|*.zip';");
	
	NotifyDescription = New NotifyDescription(
		"ClassifiersFileAfterChooseFile",
		ThisObject);
	
	FileSystemClient.ShowSelectionDialog(
		NotifyDescription,
		FileDialog);
	
EndProcedure

&AtClient
Procedure ClassifiersUpdateOptionOnChange(Item)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		Return;
	EndIf;
	
	If ClassifiersUpdateOption = 1
		And AuthenticationData = Undefined Then
		
		If Not OnlineUserSupportClient.CanConnectOnlineUserSupport() Then
			ShowMessageBox(,
				NStr("ru = 'Для автоматического обновления классификаторов необходимо
					|подключить Интернет-поддержку пользователей.';
					|en = 'To update classifiers automatically, 
					|enable online support.';"));
			Return;
		EndIf;
		
		NotificationAfterConnected = New NotifyDescription(
			"AfterEnableOnlineSupportClassifiersOperations",
			ThisObject);
		
		AdditionalParameters = New Structure();
		AdditionalParameters.Insert("Item"                   , Item);
		AdditionalParameters.Insert("NotificationAfterConnected", NotificationAfterConnected);
		
		NotifyDescription = New NotifyDescription(
			"OnAnswerToOnlineSupportConnectionQuestion",
			ThisObject,
			AdditionalParameters);
		
		Replies = New ValueList;
		Replies.Add(DialogReturnCode.Yes    , NStr("ru = 'Подключить';
														|en = 'Enable';"));
		Replies.Add(DialogReturnCode.Cancel, NStr("ru = 'Отмена';
														|en = 'Cancel';"));
		
		ShowQueryBox(
			NotifyDescription,
			NStr("ru = 'Для автоматического обновления классификаторов необходимо
				|подключить Интернет-поддержку пользователей.';
				|en = 'To update classifiers automatically, 
				|enable online support.';"),
			Replies);
			
		Return;
	Else
		Items.DecorationClassifiersUpdateDisabled.Visible = False;
	EndIf;
	
	OnChangeConstant("ClassifiersUpdateOption", ClassifiersUpdateOption, False);
	ClassifiersUpdateOptionPrevVal = ClassifiersUpdateOption;
	
EndProcedure

&AtClient
Procedure ClassifiersUpdateScheduleDecorationClick(Item)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		Return;
	EndIf;
	
	ModuleClassifiersManagementServerCall = CommonClient.CommonModule(
		"ClassifiersOperationsServerCall");
	Result = ModuleClassifiersManagementServerCall.ClassifiersUpdateSettings();
	If Result.Schedule <> Undefined Then
		ScheduleDialog = New ScheduledJobDialog(Result.Schedule);
	Else
		ScheduleDialog = New ScheduledJobDialog(New JobSchedule);
	EndIf;
	
	NotifyDescription = New NotifyDescription(
		"OnChangeSchedule",
		ThisObject);
	
	ScheduleDialog.Show(NotifyDescription);
	
EndProcedure

&AtClient
Procedure DecorationClassifiersUpdateDisabledURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If Not OnlineUserSupportClient.CanConnectOnlineUserSupport() Then
		ShowMessageBox(,
			NStr("ru = 'Для автоматического обновления классификаторов необходимо
				|подключить Интернет-поддержку пользователей.';
				|en = 'To update classifiers automatically, 
				|enable online support.';"));
		Return;
	EndIf;
	
	OnlineUserSupportClient.EnableInternetUserSupport(
		Undefined,
		ThisObject);
	
EndProcedure

#EndRegion

#Region News_

&AtClient
Procedure EnableNewsManagementOnChange(Item)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.News_") Then
		Return;
	EndIf;
	
	If Not EnableNewsManagement Then
		
		QueryText = StringFunctionsClient.FormattedString(
			NStr("ru = 'Настоятельно <b>не рекомендуется</b> отключать общую опцию получения новостей.
				|Это позволит оперативно получать важную информацию от службы поддержки фирмы 1С.
				|
				|Отключить опцию получения новостей?';
				|en = 'We strongly recommend that you <b>do not disable</b> the general option for receiving news.
				|This will allow you to get the latest important information from the technical support of 1C Company.
				|
				|Do you want to disable the option for receiving news?';"));
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Disconnect"  , NStr("ru = 'Отключить';
													|en = 'Disable';"));
		ButtonsList.Add("DoNotDisable", NStr("ru = 'Оставить включенной';
													|en = 'Keep enabled';"));
		
		NotifyDescriptionOnCompletion = New NotifyDescription(
			"EnableNewsManagementOnDisabling", // A procedure name.
			ThisObject);
		
		ShowQueryBox(
			NotifyDescriptionOnCompletion,
			QueryText,
			ButtonsList,
			,
			"DoNotDisable", // An id.
			NStr("ru = 'Предупреждение';
				|en = 'Warning';"));
		
	Else
		// "NewsManagementEnabled" functional option change handler
		OnChangeConstant("NewsManagementEnabled", EnableNewsManagement, True, True);
		Items.NewsManagement.Visible = EnableNewsManagement;
		// End "NewsManagementEnabled" functional option change handler
	EndIf;
	
EndProcedure

&AtClient
Procedure NewsList_AutoUpdateIntervalClearing(Item, StandardProcessing)

	// In the separated mode the value "0" means the following:
	//  Remove the setting and take the value from the constant.
	NewsList_AutoUpdateInterval = 0;
	StandardProcessing = False;

EndProcedure

&AtClient
Procedure NewsList_AutoUpdateIntervalOnChange(Item)

	If Not CommonClient.SubsystemExists("OnlineUserSupport.News_") Then
		Return;
	EndIf;

	// Save the value
	NewsList_AutoUpdateIntervalOnChangeAtServer(NewsList_AutoUpdateInterval);

	// Repopulate data and re-attach notification handlers for the current session.
	// The settings are stored in "StandardSubsystemsClient.ClientRunParameters"
	//  and taken from "Cached" (which is filled in the overridable methods).
	// To repopulate the values, clear the cache.
	RefreshReusableValues();
	ModuleNewsProcessingClient = CommonClient.CommonModule("ОбработкаНовостейКлиент");
	ModuleNewsProcessingClient.ПодключитьОбработчикОповещенияОВажныхИОченьВажныхНовостях();

EndProcedure

#EndRegion

#Region GetApplicationUpdates

&AtClient
Procedure AutomaticUpdatesCheck1OnChange(Item)
	
	AutomaticUpdatesCheckOnChangeAsync(Item);
	
EndProcedure

&AtClient
Procedure AutomaticUpdatesCheck2OnChange(Item)
	
	AutomaticUpdatesCheckOnChangeAsync(Item);
	
EndProcedure

&AtClient
Procedure UpdateReleaseNotificationOption1OnChange(Item)
	
	SaveUpdateReleaseNotificationOptionAtServer(UpdateReleaseNotificationOption);
	
EndProcedure

&AtClient
Procedure UpdateReleaseNotificationOption2OnChange(Item)
	
	SaveUpdateReleaseNotificationOptionAtServer(UpdateReleaseNotificationOption);
	
EndProcedure

&AtClient
Procedure UpdatesCheckScheduleDecorationClick(Item)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		Return;
	EndIf;
	
	ModuleGetApplicationUpdatesClient = CommonClient.CommonModule("GetApplicationUpdatesClient");
	SettingsOfUpdate = ModuleGetApplicationUpdatesClient.GlobalUpdateSettings();
	CheckSchedule1 = CommonClientServer.StructureToSchedule(SettingsOfUpdate.Schedule);
	
	ScheduleDialog = New ScheduledJobDialog(CheckSchedule1);
	NotifyDescription = New NotifyDescription(
		"OnChangeUpdateCheckSchedule",
		ThisObject);
	ScheduleDialog.Show(NotifyDescription);
	
EndProcedure

&AtClient
Procedure PlatformDistributionPackageDirectoryClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	#If Not WebClient Then
	FileSystemClient.OpenExplorer(PlatformDistributionPackageDirectory);
	#EndIf
	
EndProcedure

&AtClient
Procedure PatchesInstallationScheduleDecorationClick(Item)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		Return;
	EndIf;
	
	ModuleGetAppUpdatesServerCall = CommonClient.CommonModule(
		"GetApplicationUpdatesServerCall");
	Schedule = ModuleGetAppUpdatesServerCall.PatchesInstallationJobSchedule();
	ScheduleDialog = New ScheduledJobDialog(Schedule);
	NotifyDescription = New NotifyDescription(
		"OnChangePatchInstallationSchedule",
		ThisObject);
	ScheduleDialog.Show(NotifyDescription);
	
EndProcedure

&AtClient
Procedure ImportAndInstallCorrectionsAutomaticallyOnChange(Item)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		Return;
	EndIf;
	
	If ImportAndInstallCorrectionsAutomatically
		And AuthenticationData = Undefined Then
		
		ImportAndInstallCorrectionsAutomatically = False;
		
		If Not OnlineUserSupportClient.CanConnectOnlineUserSupport() Then
			ShowMessageBox(,
				NStr("ru = 'Для автоматического получения и установки исправлений (патчей)
				|необходимо подключить Интернет-поддержку пользователей.';
				|en = 'Enable online support to get and install patches automatically.
				|';"));
			Return;
		EndIf;
		
		NotificationAfterConnected = New NotifyDescription(
			"EnableOnlineSupportCompletionAutomaticPatchInstallation",
			ThisObject);
		
		AdditionalParameters = New Structure();
		AdditionalParameters.Insert("Item"                   , Item);
		AdditionalParameters.Insert("NotificationAfterConnected", NotificationAfterConnected);
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("ru = 'Подключить';
													|en = 'Enable';"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		ShowQueryBox(
			New NotifyDescription(
				"OnAnswerToOnlineSupportConnectionQuestion",
				ThisObject,
				AdditionalParameters),
			NStr("ru = 'Для автоматического получения и установки исправлений (патчей)
				|необходимо подключить Интернет-поддержку пользователей.';
				|en = 'Enable online support to get and install patches automatically.
				|';"),
			Buttons);
		
	Else
		
		ModuleGetAppUpdatesServerCall = CommonClient.CommonModule(
			"GetApplicationUpdatesServerCall");
		ModuleGetAppUpdatesServerCall.EnableDisableAutomaticPatchesInstallation(
			ImportAndInstallCorrectionsAutomatically);
		Items.PatchesInstallationScheduleDecoration.Enabled = ImportAndInstallCorrectionsAutomatically;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region WorkingWithCounterparties

&AtClient
Procedure UseCounterpartyVerificationOnChange(Item)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.WorkingWithCounterparties") Then
		Return;
	EndIf;
	
	EnableCheck = (UseCounterpartyVerification = 1);
	
	ModuleCounterpartyVerification = CommonClient.CommonModule("ПроверкаКонтрагентовВызовСервера");
	ModuleCounterpartyVerification.ПриВключенииВыключенииПроверки(EnableCheck);
	
	RefreshInterface = True;
	AttachIdleHandler("RefreshApplicationInterface", 2, True);
	
EndProcedure

#EndRegion

#Region SparkRisks

&AtClient
Procedure UseSPARKRisksServiceOnChange(Item)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		OnChangeConstant("UseSPARKRisksService", UseSPARKRisksService, True, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region InstantPayments

&AtClient
Procedure PaymentSystemOperationDurationOnChange(Item)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.InstantPayments") Then
		ModuleFasterPaymentSystemServerCall = CommonClient.CommonModule(
			"СистемаБыстрыхПлатежейВызовСервера");
		ModuleFasterPaymentSystemServerCall.УстановитьДлительностьОперации(
			PaymentSystemOperationDuration);
	EndIf;
	
EndProcedure

#EndRegion

#Region IntegrationWithConnect

&AtClient
Procedure Use1CConnectOnChange(Item)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.IntegrationWithConnect") Then
		Return;
	EndIf;
	
	ModuleIntegrationWith1CConnectServerCall = CommonClient.CommonModule("ИнтеграцияСКоннектВызовСервера");
	ModuleIntegrationWith1CConnectServerCall.УстановитьИспользованиеИнтеграции(
		Use1CConnect);
	
	Items.IntegrationWith1CConnectSetup.Enabled = Use1CConnect;
	CommonClient.RefreshApplicationInterface();
	
EndProcedure

#EndRegion

#Region OnlinePayment

&AtClient
Procedure UseOnlinePaymentOnChange(Item)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		Return;
	EndIf;
	
	ModuleOnlinePaymentServerCall = CommonClient.CommonModule("ОнлайнОплатыВызовСервера");
	ModuleOnlinePaymentServerCall.УстановитьИспользованиеИнтеграции(OnlinePayment);
	
	Items.GroupReceivingNotifications.Enabled = OnlinePayment;
	Items.GroupSettingsOnlinePaymentRight.Enabled = OnlinePayment;
	Items.DecorationScheduleReceivingNotificationsFromOnlinePayments.Enabled = 
		UseAutomaticReceivingNotificationFromOnlinePayments;
	
	CommonClient.RefreshApplicationInterface();
	
EndProcedure

&AtClient
Procedure UseAutomaticReceivingNotificationFromOnlinePaymentsOnChange(Item)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		Return;
	EndIf;
	
	If UseAutomaticReceivingNotificationFromOnlinePayments Then
		
		ContinuationHandler = New NotifyDescription(
			"UseAutomaticReceiptOfNotificationsFromOnlinePaymentsFollowUp",
			ThisObject,
			Parameters);
				
		ModuleOnlinePaymentInternalClient = CommonClient.CommonModule("OnlinePaymentInternalClient");
		ModuleOnlinePaymentInternalClient.НачатьПроверкуИПодключениеИПП(ContinuationHandler);
		
	Else
		UseAutomaticReceivingNotificationFromOnlinePaymentsCompletion();
	EndIf;
	
EndProcedure 

&AtClient
Procedure DecorationScheduleReceivingNotificationsFromOnlinePaymentsClick(Item)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		Return;
	EndIf;
	
	ModuleOnlinePaymentServerCall = CommonClient.CommonModule("ОнлайнОплатыВызовСервера");
	Schedule = ModuleOnlinePaymentServerCall.РасписаниеЗаданияПолучениеУведомленияОтОнлайнОплат();
	ScheduleDialog = New ScheduledJobDialog(Schedule);
	NotifyDescription = New NotifyDescription(
		"OnChangeNotificationReceiptSchedule",
		ThisObject);
	ScheduleDialog.Show(NotifyDescription);
	
EndProcedure

#EndRegion

#Region GettingStatutoryReports

&AtClient
Procedure StatutoryReportsFilesOnChange(Item)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.GettingStatutoryReports") Then
		Return;
	EndIf;
	
	OnChangeConstant("StatutoryReportsFiles", StatutoryReportsFiles, False);

EndProcedure

&AtClient
Procedure StatutoryReportsFilesStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.GettingStatutoryReports") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	FileDialog = New FileDialog(FileDialogMode.Open);
	FileDialog.Title = NStr("ru = 'Выберите файл с регламентированными отчетами';
										|en = 'Select a file with statutory reports';");
	FileDialog.Filter    = NStr("ru = 'Файл регламентированных отчетов (*.zip)|*.zip';
										|en = 'Statutory report file (*.zip)|*.zip';");
	
	NotifyDescription = New NotifyDescription(
		"StatutoryReportsFileAfterFileSelected",
		ThisObject);
	
	FileSystemClient.ShowSelectionDialog(
		NotifyDescription,
		FileDialog);
	
EndProcedure

&AtClient
Procedure StatutoryReportsUpdateOptionOnChange(Item)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.GettingStatutoryReports") Then
		Return
	EndIf;
	
	If StatutoryReportsUpdateOption = 1
		And AuthenticationData = Undefined Then
		
		If Not OnlineUserSupportClient.CanConnectOnlineUserSupport() Then
			ShowMessageBox(,
				NStr("ru = 'Для автоматического обновления регламентированных отчетов необходимо
					|подключить Интернет-поддержку пользователей.';
					|en = 'To update statutory reports automatically,
					|enable online support.';"));
			Return;
		EndIf;
		
		NotificationAfterConnected = New NotifyDescription(
			"AfterEnableOnlineSupportGetStatutoryReports",
			ThisObject);
		
		AdditionalParameters = New Structure();
		AdditionalParameters.Insert("Item"                   , Item);
		AdditionalParameters.Insert("NotificationAfterConnected", NotificationAfterConnected);
		
		NotifyDescription = New NotifyDescription(
			"OnAnswerToOnlineSupportConnectionQuestion",
			ThisObject,
			AdditionalParameters);
		
		Replies = New ValueList;
		Replies.Add(DialogReturnCode.Yes    , NStr("ru = 'Подключить';
														|en = 'Enable';"));
		Replies.Add(DialogReturnCode.Cancel, NStr("ru = 'Отмена';
														|en = 'Cancel';"));
		
		ShowQueryBox(
			NotifyDescription,
			NStr("ru = 'Для автоматического обновления регламентированных отчетов необходимо
				|подключить Интернет-поддержку пользователей.';
				|en = 'To update statutory reports automatically,
				|enable online support.';"),
			Replies);
			
		Return;
	Else
		Items.DecorationStatutoryReportsUpdateDisabled.Visible = False;
	EndIf;
	
	OnChangeConstant("StatutoryReportsUpdateOption", StatutoryReportsUpdateOption, False);
	StatutoryReportsUpdateOptionPrevVal = StatutoryReportsUpdateOption;

EndProcedure

&AtClient
Procedure DecorationStatutoryReportsUpdateScheduleClick(Item)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.GettingStatutoryReports") Then
		Return;
	EndIf;
	
	StatutoryReportsGetterModuleServerCall = CommonClient.CommonModule(
		"ПолучениеРегламентированныхОтчетовВызовСервера");
	Result = StatutoryReportsGetterModuleServerCall.НастройкиОбновленияРегламентированныхОтчетов();
	If Result.Schedule <> Undefined Then
		ScheduleDialog = New ScheduledJobDialog(Result.Schedule);
	Else
		ScheduleDialog = New ScheduledJobDialog(New JobSchedule);
	EndIf;
	
	NotifyDescription = New NotifyDescription(
		"OnChangeStatutoryReportsUpdateSchedule",
		ThisObject);
	
	ScheduleDialog.Show(NotifyDescription);

EndProcedure

&AtClient
Procedure DecorationStatutoryReportsUpdateDisabledURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.GettingStatutoryReports") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If Not OnlineUserSupportClient.CanConnectOnlineUserSupport() Then
		ShowMessageBox(,
			NStr("ru = 'Для автоматического обновления регламентированных отчетов необходимо
				|подключить Интернет-поддержку пользователей.';
				|en = 'To update statutory reports automatically,
				|enable online support.';"));
		Return;
	EndIf;
	
	OnlineUserSupportClient.EnableInternetUserSupport(
		Undefined,
		ThisObject);
	
EndProcedure

#EndRegion

#Region GetAddIns

&AtClient
Procedure AddInsFileOnChange(Item)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		Return;
	EndIf;
	
	SettingsOfUpdate = New Structure;
	SettingsOfUpdate.Insert(
		"AddInsFile",
		AddInsFile);
	ModuleGetAddInsClient =
		CommonClient.CommonModule("GetAddInsClient");
	ModuleGetAddInsClient.ChangeAddInsUpdateSettings(
		SettingsOfUpdate);
	
EndProcedure

&AtClient
Procedure AddInsFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	FileDialog = New FileDialog(FileDialogMode.Open);
	FileDialog.Title = NStr("ru = 'Выберите файл с внешними компонентами';
										|en = 'Select a file with add-ins';");
	FileDialog.Filter    = NStr("ru = 'Файл внешних компонент (*.zip)|*.zip';
										|en = 'Add-in file (*.zip)|*.zip';");
	
	NotifyDescription = New NotifyDescription(
		"AddInsFileAfterFileChoice",
		ThisObject);
	
	FileSystemClient.ShowSelectionDialog(
		NotifyDescription,
		FileDialog);
	
EndProcedure

&AtClient
Procedure AddInsUpdateOptionOnChange(Item)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		Return
	EndIf;
	
	If AddInsUpdateOption = 1
		And AuthenticationData = Undefined Then
		
		If Not OnlineUserSupportClient.CanConnectOnlineUserSupport() Then
			ShowMessageBox(,
				NStr("ru = 'Для автоматического обновления внешних компонент необходимо
					|подключить Интернет-поддержку пользователей.';
					|en = 'To update add-ins automatically,
					|enable online support.';"));
			Return;
		EndIf;
		
		NotificationAfterConnected = New NotifyDescription(
			"AfterEnableOnlineSupportGetAddIns",
			ThisObject);
		
		AdditionalParameters = New Structure();
		AdditionalParameters.Insert("Item"                   , Item);
		AdditionalParameters.Insert("NotificationAfterConnected", NotificationAfterConnected);
		
		NotifyDescription = New NotifyDescription(
			"OnAnswerToOnlineSupportConnectionQuestion",
			ThisObject,
			AdditionalParameters);
		
		Replies = New ValueList;
		Replies.Add(DialogReturnCode.Yes    , NStr("ru = 'Подключить';
														|en = 'Enable';"));
		Replies.Add(DialogReturnCode.Cancel, NStr("ru = 'Отмена';
														|en = 'Cancel';"));
		
		ShowQueryBox(
			NotifyDescription,
			NStr("ru = 'Для автоматического обновления внешних компонент необходимо
				|подключить Интернет-поддержку пользователей.';
				|en = 'To update add-ins automatically,
				|enable online support.';"),
			Replies);
			
		Return;
	Else
		Items.DecorationAddInsUpdateNotRunning.Visible = False;
	EndIf;
	
	OnChangeConstant("AddInsUpdateOption", AddInsUpdateOption, False);
	AddInsUpdateOptionPreviousValue = AddInsUpdateOption;

EndProcedure

&AtClient
Procedure DecorationAddInsUpdateScheduleClick(Item)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		Return;
	EndIf;
	
	ModuleGetAddInsClient = CommonClient.CommonModule(
		"GetAddInsClient");
	Result = ModuleGetAddInsClient.AddInsUpdateSettings();
	If Result.Schedule <> Undefined Then
		ScheduleDialog = New ScheduledJobDialog(Result.Schedule);
	Else
		ScheduleDialog = New ScheduledJobDialog(New JobSchedule);
	EndIf;
	
	NotifyDescription = New NotifyDescription(
		"OnChangeAddInsUpdateSchedule",
		ThisObject);
	
	ScheduleDialog.Show(NotifyDescription);

EndProcedure

&AtClient
Procedure DecorationAddInsUpdateNotRunningURLProcessing(
	Item,
	FormattedStringURL,
	StandardProcessing)
	
	If Not CommonClient.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If Not OnlineUserSupportClient.CanConnectOnlineUserSupport() Then
		ShowMessageBox(,
			NStr("ru = 'Для автоматического обновления внешних компонент необходимо
				|подключить Интернет-поддержку пользователей.';
				|en = 'To update add-ins automatically,
				|enable online support.';"));
		Return;
	EndIf;
	
	OnlineUserSupportClient.EnableInternetUserSupport(
		Undefined,
		ThisObject);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

#Region EventHandlersSSL

&AtClient
Procedure AddressClassifierLoading(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
		AppSettingsModuleClient.OnlineSupportAndServicesImportAddressClassifier(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearAddressInfoRecords(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
		AppSettingsModuleClient.OnlineSupportAndServicesClearAddressInfoRecords(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrenciesRatesImport(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
		AppSettingsModuleClient.OnlineSupportAndServicesImportExchangeRates(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure

// StandardSubsystems.IBVersionUpdate
&AtClient
Procedure DeferredDataProcessing(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
		AppSettingsModuleClient.OnlineSupportAndServicesOpenInfobaseUpdateProgress(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure
// End StandardSubsystems.IBVersionUpdate

&AtClient
Procedure EnableDisableConversations(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
		AppSettingsModuleClient.OnlineSupportAndServicesToggleConversations(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConversationsConfigureIntegrationWithExternalSystems(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
		AppSettingsModuleClient.OnlineSupportAndServicesShowSettingForIntegrationWithExternalSystems(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenChangeHistory(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
		AppSettingsModuleClient.OnlineSupportAndServicesSystemChangelog(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure MorpherServiceAccessSetting(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
		AppSettingsModuleClient.OnlineSupportAndServicesConfigureAccessToMorpher(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure MonitoringCenter_Settings(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
		AppSettingsModuleClient.OnlineSupportAndServicesMonitoringCenterSettings(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure MonitoringCenterSendContactInformation(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
		AppSettingsModuleClient.OnlineSupportAndServicesMonitoringCenterSendContactInfo(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenAddIns(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
		AppSettingsModuleClient.OnlineSupportAndServicesOpenAddIns(
			ThisObject,
			Command);
	EndIf;
	
EndProcedure

#EndRegion

#Region CoreISL

&AtClient
Procedure SignInOrSignOutOnlineSupport(Command)
	
	If AuthenticationData = Undefined Then
		OnlineUserSupportClient.EnableInternetUserSupport(, ThisObject);
	Else
		ShowQueryBox(
			New NotifyDescription(
				"OnResponseToQuestionOnExitOnlineSupport",
				ThisObject),
			NStr("ru = 'Логин и пароль для подключения к сервисам Интернет-поддержки пользователей будут удалены из программы.
				|Отключить Интернет-поддержку?';
				|en = 'Your online support username and password will be deleted from the application.
				|Disable online support?';"),
			QuestionDialogMode.YesNo,
			,
			DialogReturnCode.No,
			NStr("ru = 'Выход из Интернет-поддержки пользователей';
				|en = 'Exit online support';"));
	EndIf;
	
EndProcedure

&AtClient
Procedure InformationAndTechnologySupport(Command)
	
	OnlineUserSupportClient.OpenIntegratedWebsitePage(
		"https://its.1c.ru");
	
EndProcedure

#EndRegion

#Region MessagesToTechSupportService

&AtClient
Procedure MessageToTechnicalSupportService(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.MessagesToTechSupportService") Then
		
		TheModuleOfTheMessageToTheTechnicalSupportServiceClientServer =
			CommonClient.CommonModule("MessagesToTechSupportServiceClientServer");
		MessageData = TheModuleOfTheMessageToTheTechnicalSupportServiceClientServer.MessageData();
		MessageData.Recipient = "webIts";
		MessageData.Subject       = NStr("ru = 'Интернет-поддержка пользователей';
											|en = 'Online support';");
		MessageData.Message  = NStr("ru = '<Заполните текст сообщения>';
											|en = '<Fill in message text>';");
		
		TheModuleOfTheMessageToTheTechnicalSupportServiceClient = CommonClient.CommonModule(
			"MessagesToTechSupportServiceClient");
		TheModuleOfTheMessageToTheTechnicalSupportServiceClient.SendMessage(
			MessageData);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region PortalMonitor1CITS

&AtClient
Procedure OnlineSupportDashboard(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.PortalMonitor1CITS") Then
		ModuleOneCITSPortalDashboardClient = CommonClient.CommonModule("PortalMonitor1CITSClient");
		ModuleOneCITSPortalDashboardClient.ОткрытьМонитор();
	EndIf;
	
EndProcedure

#EndRegion

#Region ClassifiersOperations

&AtClient
Procedure UpdateClassifiers(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperationsClient = CommonClient.CommonModule("ClassifiersOperationsClient");
		ModuleClassifiersOperationsClient.RunClassifierUpdate();
	EndIf;
	
EndProcedure

#EndRegion

#Region News_

&AtClient
Procedure NewsManagement(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.News_") Then
		ModuleNewsProcessingClient = CommonClient.CommonModule("ОбработкаНовостейКлиент");
		ModuleNewsProcessingClient.НастройкаНовостей(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region GetApplicationUpdates

&AtClient
Procedure ApplicationUpdate(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		ModuleGetApplicationUpdatesClient = CommonClient.CommonModule(
			"GetApplicationUpdatesClient");
		ModuleGetApplicationUpdatesClient.UpdateProgram();
	EndIf;
	
EndProcedure

#EndRegion

#Region WorkingWithCounterparties

&AtClient
Procedure CheckAccessToCounterpartiesServices(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.WorkingWithCounterparties") Then
		ModuleCounterpartyVerificationClient = CommonClient.CommonModule("ПроверкаКонтрагентовКлиент");
		ModuleCounterpartyVerificationClient.ОткрытьФормуПроверкиПодключенияКСервисам();
	EndIf;
	
EndProcedure

#EndRegion

#Region InstantPayments

&AtClient
Procedure SetUpConnectionToFasterPaymentsSystem(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.InstantPayments.BasicFPSFeatures") Then
		ModuleFasterPaymentsSystemClient = CommonClient.CommonModule(
			"InstantPaymentsClient");
		ModuleFasterPaymentsSystemClient.ConnectionSettings(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenTemplatesOfFPSMessages(Command)
	
	If (CommonClient.SubsystemExists("OnlineUserSupport.InstantPayments.FPSc2bTransfers")
		And CommonClient.SubsystemExists("StandardSubsystems.MessageTemplates")) Then
		ModuleFPSc2bTransfersClient = CommonClient.CommonModule(
			"FPSc2bTransfersClient");
		ModuleFPSc2bTransfersClient.OpenTemplatesOfFPSMessages(UUID);
	EndIf;
	
EndProcedure

#EndRegion

#Region IntegrationWithConnect

&AtClient
Procedure IntegrationWith1CConnectSetup(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.IntegrationWithConnect") Then
		ModuleIntegrationWithConnectClient = CommonClient.CommonModule("IntegrationWithConnectClient");
		ModuleIntegrationWithConnectClient.Integration(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region OnlinePayment

&AtClient
Procedure OpenSettingsOnlinePayments(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		ModuleOnlinePaymentClient = CommonClient.CommonModule("OnlinePaymentClient");
		ModuleOnlinePaymentClient.НастройкаОнлайнОплат(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenOnlinePaymentMessageTemplates(Command)
	
	If (CommonClient.SubsystemExists("OnlineUserSupport.OnlinePayment") 
		And CommonClient.SubsystemExists("StandardSubsystems.MessageTemplates")) Then
		
		ModuleOnlinePaymentClient = CommonClient.CommonModule("OnlinePaymentClient");
		ModuleOnlinePaymentClient.OpenOnlinePaymentMessageTemplates(UUID);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region GettingStatutoryReports

&AtClient
Procedure StatutoryReportsUpdate(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.GettingStatutoryReports") Then
		StatutoryReportsGetterModuleClient =
			CommonClient.CommonModule("GettingStatutoryReportsClient");
		StatutoryReportsGetterModuleClient.ОбновитьРегламентированныеОтчеты();
	EndIf;
	
EndProcedure

#EndRegion

#Region GetAddIns

&AtClient
Procedure AddInsUpdate(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		ModuleGetAddInsClient = CommonClient.CommonModule("GetAddInsClient");
		ModuleGetAddInsClient.UpdateAddIns();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region OnlinePayment

&AtClient
Procedure UseAutomaticReceiptOfNotificationsFromOnlinePaymentsFollowUp(
		Result,
		AdditionalParameters) Export
	
	If Result = Undefined
		Or Not Result Then
		UseAutomaticReceivingNotificationFromOnlinePayments = False;
	Else
		UseAutomaticReceivingNotificationFromOnlinePaymentsCompletion();
	EndIf;
	
EndProcedure

&AtClient
Procedure UseAutomaticReceivingNotificationFromOnlinePaymentsCompletion()
	
	Items.DecorationScheduleReceivingNotificationsFromOnlinePayments.Enabled =
		UseAutomaticReceivingNotificationFromOnlinePayments;
	
	ModuleOnlinePaymentServerCall = CommonClient.CommonModule("ОнлайнОплатыВызовСервера");
	ModuleOnlinePaymentServerCall.UseAutomaticReceivingNotificationFromOnlinePayments(
		UseAutomaticReceivingNotificationFromOnlinePayments);
	
EndProcedure

#EndRegion

#Region News_

&AtServerNoContext
Procedure NewsList_AutoUpdateIntervalOnChangeAtServer(Val NewsList_AutoUpdateIntervalMinutes)

	// Although writing is available for both SaaS and on-prem versions (for shared and separated modes), there's a dedicated form for this.
	//  Therefore, this method can do writing only the separated mode in SaaS. Otherwise, it throws an error.
	// 
	If Common.DataSeparationEnabled()
			And Common.SeparatedDataUsageAvailable() Then
		NewsDisplaySettings = New Structure;
			NewsDisplaySettings.Insert("NewsList_AutoUpdateInterval", NewsList_AutoUpdateIntervalMinutes);
		ModuleNewsProcessing = Common.CommonModule("ОбработкаНовостей");
		ModuleNewsProcessing.УстановитьНастройкиПоказаНовостей(NewsDisplaySettings);
	Else
		MessageText = NStr("ru = 'Сохранение возможно только в разделенном режиме модели сервиса';
								|en = 'Saving is only possible in separated SaaS mode.';");
		Raise MessageText;
	EndIf;

EndProcedure

#EndRegion

&AtServer
Procedure OnChangeSSLConstantAtServer(Val ConstantName)
	
	AppSettingsModule = Common.CommonModule("ApplicationSettings");
	AppSettingsModule.OnlineSupportAndServicesOnConstantChange(
		ThisObject,
		ConstantName,
		ThisObject[ConstantName]);
	
EndProcedure

&AtServerNoContext
Procedure OnChangeWebServiceAddressesUsage(Val UseAddressesWebService)
	
	AppSettingsModule = Common.CommonModule("ApplicationSettings");
	AppSettingsModule.InternetSupportAndServicesWebServiceUsage(UseAddressesWebService);
	
EndProcedure

&AtClient
Procedure OnChangeModeOfDataExportToMonitoringCenter(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		
		MonitoringCenterParameters = AllowDataSendingOnChangeAtServer(Item.Name);
		
		AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
		AppSettingsModuleClient.OnlineSupportAndServicesAllowSendDataOnChange(
			ThisObject,
			Item,
			MonitoringCenterParameters);
			
	EndIf;
	
EndProcedure

&AtServer
Function AllowDataSendingOnChangeAtServer(Val TagName)
	
	OperationParametersList = New Structure();
	
	AppSettingsModule = Common.CommonModule("ApplicationSettings");
	AppSettingsModule.OnlineSupportAndServicesAllowSendDataOnChange(
		ThisObject,
		Items[TagName],
		OperationParametersList);
	
	Return OperationParametersList;
	
EndFunction

&AtServer
Procedure MonitoringCenterServiceAddressOnChangeAtServer(Val TagName)
	
	AppSettingsModule = Common.CommonModule("ApplicationSettings");
	AppSettingsModule.OnlineSupportAndServicesMonitoringCenterOnChange(
		ThisObject,
		Items[TagName]);
	
EndProcedure

&AtClient
Procedure OnChangeUpdateCheckSchedule(Schedule, AdditionalParameters) Export
	
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	RepeatPeriodInDay = Schedule.RepeatPeriodInDay;	// Number
	If AutomaticUpdatesCheck = 2
		And RepeatPeriodInDay > 0
		And RepeatPeriodInDay < 300 Then
		ShowMessageBox(,
			NStr("ru = 'Интервал проверки не может быть задан чаще, чем один раз 5 минут.';
				|en = 'The check interval cannot be shorter than 5 minutes.';"));
		Return;
	EndIf;
	
	Items.UpdatesCheckScheduleDecoration.Title =
		OnlineUserSupportClientServer.SchedulePresentation(Schedule);
	
	ModuleGetApplicationUpdatesClient = 
			CommonClient.CommonModule("GetApplicationUpdatesClient");
	SettingsOfUpdate = ModuleGetApplicationUpdatesClient.GlobalUpdateSettings();
	SettingsOfUpdate.Schedule = CommonClientServer.ScheduleToStructure(Schedule);
	
	ModuleGetAppUpdatesServerCall = 
			CommonClient.CommonModule("GetApplicationUpdatesServerCall");
	ModuleGetAppUpdatesServerCall.WriteUpdateSettings(SettingsOfUpdate);
	
EndProcedure

&AtClient
Procedure OnChangePatchInstallationSchedule(Schedule, AdditionalParameters) Export
	
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
	
	ModuleGetAppUpdatesServerCall = CommonClient.CommonModule(
		"GetApplicationUpdatesServerCall");
	ModuleGetAppUpdatesServerCall.SetPatchesInstallationJobSchedule(Schedule);
	
	Items.PatchesInstallationScheduleDecoration.Title =
		OnlineUserSupportClientServer.SchedulePresentation(Schedule);
	
EndProcedure

&AtClient
Procedure EnableNewsManagementOnDisabling(QuestionResult, AdditionalParameters) Export

	If QuestionResult = "DoNotDisable" Then // An id.
		EnableNewsManagement = Not EnableNewsManagement;
	EndIf;

	// "NewsManagementEnabled" functional option change handler
	OnChangeConstant("NewsManagementEnabled", EnableNewsManagement, True, True);
	Items.NewsManagement.Visible = EnableNewsManagement;
	// End "NewsManagementEnabled" functional option change handler

EndProcedure

&AtClient
Procedure OnChangeConstant(
		ConstantName,
		NewValue,
		ShouldRefreshInterface = True,
		RefreshReusableValues = False)
	
	SaveConstantValue(ConstantName, NewValue, RefreshReusableValues);
	
	If RefreshReusableValues Then
		RefreshReusableValues();
	EndIf;
	
	If ShouldRefreshInterface Then
		RefreshInterface = True;
		AttachIdleHandler("RefreshApplicationInterface", 2, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure EnableOnlineSupportCompletionAutomaticPatchInstallation(
	Result,
	AdditionalParameters) Export
	
	If Result <> Undefined Then
		ImportAndInstallCorrectionsAutomatically = True;
		ModuleGetAppUpdatesServerCall = CommonClient.CommonModule(
			"GetApplicationUpdatesServerCall");
		ModuleGetAppUpdatesServerCall.EnableDisableAutomaticPatchesInstallation(
			ImportAndInstallCorrectionsAutomatically);
		Items.PatchesInstallationScheduleDecoration.Enabled = ImportAndInstallCorrectionsAutomatically;
	EndIf;
	
EndProcedure

&AtClient
Procedure ClassifiersFileAfterChooseFile(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	If SelectedFiles.Count() = 0 Then
		Return;
	EndIf;
	
	ClassifiersFile = SelectedFiles[0];
	OnChangeConstant("ClassifiersFile", ClassifiersFile, False);
	
EndProcedure

&AtClient
Procedure AddInsFileAfterFileChoice(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	If SelectedFiles.Count() = 0 Then
		Return;
	EndIf;
	
	AddInsFile = SelectedFiles[0];
	OnChangeConstant("AddInsFile", AddInsFile, False);
	
EndProcedure

&AtClient
Procedure StatutoryReportsFileAfterFileSelected(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	If SelectedFiles.Count() = 0 Then
		Return;
	EndIf;
	
	StatutoryReportsFiles = SelectedFiles[0];
	OnChangeConstant("StatutoryReportsFiles", StatutoryReportsFiles, False);
	
EndProcedure

&AtClient
Procedure OnAnswerToOnlineSupportConnectionQuestion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		OnlineUserSupportClient.EnableInternetUserSupport(
			AdditionalParameters.NotificationAfterConnected,
			ThisObject);
	ElsIf AdditionalParameters.Item = Items.AddInsUpdateOption Then
		AddInsUpdateOption = AddInsUpdateOptionPreviousValue;
	ElsIf AdditionalParameters.Item = Items.ClassifiersUpdateOption Then
		ClassifiersUpdateOption = ClassifiersUpdateOptionPrevVal;
	ElsIf AdditionalParameters.Item = Items.StatutoryReportsUpdateOption Then
		StatutoryReportsUpdateOption = StatutoryReportsUpdateOptionPrevVal;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterEnableOnlineSupportGetAddIns(
	Result,
	AdditionalParameters) Export
	
	If Result = Undefined Then
		AddInsUpdateOption = AddInsUpdateOptionPreviousValue;
	EndIf;
	
	OnChangeConstant(
		"AddInsUpdateOption",
		AddInsUpdateOption,
		False);
	AddInsUpdateOptionPreviousValue = AddInsUpdateOption;
	
EndProcedure

&AtClient
Procedure AfterEnableOnlineSupportGetStatutoryReports(
	Result,
	AdditionalParameters) Export
	
	If Result = Undefined Then
		StatutoryReportsUpdateOption = StatutoryReportsUpdateOptionPrevVal;
	EndIf;
	
	OnChangeConstant(
		"StatutoryReportsUpdateOption",
		StatutoryReportsUpdateOption,
		False);
	StatutoryReportsUpdateOptionPrevVal = StatutoryReportsUpdateOption;
	
EndProcedure

&AtClient
Procedure AfterEnableOnlineSupportClassifiersOperations(
	Result,
	AdditionalParameters) Export
	
	If Result = Undefined Then
		ClassifiersUpdateOption = ClassifiersUpdateOptionPrevVal;
	EndIf;
	
	OnChangeConstant(
		"ClassifiersUpdateOption",
		ClassifiersUpdateOption,
		False);
	ClassifiersUpdateOptionPrevVal = ClassifiersUpdateOption;
	
EndProcedure

&AtClient
Procedure OnChangeSchedule(Schedule, AdditionalParameters) Export
	
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	RepeatPeriodInDay = Schedule.RepeatPeriodInDay;
	If RepeatPeriodInDay > 0
		And RepeatPeriodInDay < 300 Then
		ShowMessageBox(,
			NStr("ru = 'Интервал обновления не может быть задан чаще, чем один раз 5 минут.';
				|en = 'The update interval cannot be shorter than 5 minutes.';"));
		Return;
	EndIf;
	
	Items.ClassifiersUpdateScheduleDecoration.Title =
		OnlineUserSupportClientServer.SchedulePresentation(Schedule);
	
	ModuleClassifiersManagementServerCall = CommonClient.CommonModule(
		"ClassifiersOperationsServerCall");
	ModuleClassifiersManagementServerCall.WriteUpdateSchedule(Schedule);
	
EndProcedure

&AtClient
Procedure OnChangeAddInsUpdateSchedule(Schedule, AdditionalParameters) Export
	
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	RepeatPeriodInDay = Schedule.RepeatPeriodInDay;
	If RepeatPeriodInDay > 0
		And RepeatPeriodInDay < 300 Then
		ShowMessageBox(,
			NStr("ru = 'Интервал обновления не может быть задан чаще, чем один раз 5 минут.';
				|en = 'The update interval cannot be shorter than 5 minutes.';"));
		Return;
	EndIf;
	
	Items.DecorationAddInsUpdateSchedule.Title =
		OnlineUserSupportClientServer.SchedulePresentation(Schedule);
		
	If Not CommonClient.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		Return;
	EndIf;
	
	SettingsOfUpdate = New Structure;
	SettingsOfUpdate.Insert(
		"Schedule",
		Schedule);
	ModuleGetAddInsClient = CommonClient.CommonModule(
		"GetAddInsClient");
	ModuleGetAddInsClient.ChangeAddInsUpdateSettings(
		SettingsOfUpdate);
	
EndProcedure

&AtClient
Procedure OnChangeStatutoryReportsUpdateSchedule(Schedule, AdditionalParameters) Export
	
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	RepeatPeriodInDay = Schedule.RepeatPeriodInDay;
	If RepeatPeriodInDay > 0
		And RepeatPeriodInDay < 300 Then
		ShowMessageBox(,
			NStr("ru = 'Интервал обновления не может быть задан чаще, чем один раз 5 минут.';
				|en = 'The update interval cannot be shorter than 5 minutes.';"));
		Return;
	EndIf;
	
	Items.DecorationStatutoryReportsUpdateSchedule.Title =
		OnlineUserSupportClientServer.SchedulePresentation(Schedule);
		
	If Not CommonClient.SubsystemExists("OnlineUserSupport.GettingStatutoryReports") Then
		Return;
	EndIf;
		
	StatutoryReportsGetterModuleServerCall = CommonClient.CommonModule(
		"ПолучениеРегламентированныхОтчетовВызовСервера");
	StatutoryReportsGetterModuleServerCall.WriteUpdateSchedule(Schedule);
	
EndProcedure

&AtClient
Procedure OnChangeNotificationReceiptSchedule(Schedule, AdditionalParameters) Export
	
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	ModuleOnlinePaymentServerCall = CommonClient.CommonModule("ОнлайнОплатыВызовСервера");
	ModuleOnlinePaymentServerCall.УстановитьРасписаниеЗаданияПолучениеУведомленияОтОнлайнОплат(Schedule);
	
	Items.DecorationScheduleReceivingNotificationsFromOnlinePayments.Title =
		OnlineUserSupportClientServer.SchedulePresentation(Schedule);
	
EndProcedure

&AtClient
Procedure OnResponseToQuestionOnExitOnlineSupport(ReturnCode, AdditionalParameters) Export
	
	If ReturnCode = DialogReturnCode.Yes Then
		OnlineUserSupportServerCall.ExitOUS();
		AuthenticationData = Undefined;
		DisplayOUSConnectionState(ThisObject);
		Notify("OnlineSupportDisabled");
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure DisplayOUSConnectionState(Form)
	
	Items             = Form.Items;
	AuthenticationData = Form.AuthenticationData;	// See OnlineUserSupport.OnlineSupportUserAuthenticationData
	If AuthenticationData = Undefined Then
		Items.OUSUsernameDecoration.Title           = NStr("ru = 'Подключение к Интернет-поддержке не выполнено.';
																|en = 'Online support is disabled.';");
		Items.SignInOrSignOutOnlineSupport.Title            = NStr("ru = 'Подключить';
																|en = 'Enable';");
		Items.SignInOrSignOutOnlineSupport.ToolTipRepresentation = ToolTipRepresentation.None;
	Else
		Login = AuthenticationData.Login;
		TitleTemplate1 = OnlineUserSupportClientServer.SubstituteDomain(
			NStr("ru = '<body>Подключена Интернет-поддержка для пользователя <a href=""action:openUsersSite"">%1</body>';
				|en = '<body>Online support is enabled for user <a href=""action:openUsersSite"">%1</body>';"));
		Items.OUSUsernameDecoration.Title =
			OnlineUserSupportClientServer.FormattedHeader(
				StringFunctionsClientServer.SubstituteParametersToString(
					TitleTemplate1,
					Login));
		Items.SignInOrSignOutOnlineSupport.Title            = NStr("ru = 'Отключить';
																|en = 'Disable';");
		Items.SignInOrSignOutOnlineSupport.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveConstantValue(Val ConstantName, Val NewValue, Val RefreshReusableValues)
	
	ConstantManager = Constants[ConstantName];
	
	If ConstantManager.Get() <> NewValue Then
		ConstantManager.Set(NewValue);
		If RefreshReusableValues Then
			RefreshReusableValues();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshOnlineSupportStatus()
	
	Items.SettingsGroup1.Visible      = True;
	Items.EnableOnlineSupportGroup.Visible = OnlineUserSupport.CanConnectOnlineUserSupport();
	
	If Items.EnableOnlineSupportGroup.Visible Then
		SetPrivilegedMode(True);
		AuthenticationData = OnlineUserSupport.OnlineSupportUserAuthenticationData();
		SetPrivilegedMode(False);
		If AuthenticationData <> Undefined Then
			AuthenticationData.Password = "";
		EndIf;
		DisplayOUSConnectionState(ThisObject);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.PortalMonitor1CITS") Then
		ModuleOneCITSPortalDashboard = Common.CommonModule("PortalMonitor1CITS");
		Items.OnlineSupportDashboard.Visible = ModuleOneCITSPortalDashboard.ДоступноИспользованиеМонитора();
	Else
		Items.OnlineSupportDashboard.Visible = False;
	EndIf;
	
	// The form opens in both shared and separated modes. The fields are displayed on the form.
	// 
	If Common.SubsystemExists("OnlineUserSupport.News_")
			And IsSystemAdministrator Then
		// In the shared mode, "NewsManagementEnabled" can be toggled.
		// In the separated mode, if "NewsManagementEnabled" is set to "False", the panel is hidden.
		//  Then, the controls are displayed on "GroupNewsSharedSessionOrOnPremisesApp" and "GroupNewsSeparatedSession".
		// 
		ModuleNewsProcessing          = Common.CommonModule("ОбработкаНовостей");
		ModuleNewsProcessingInternal = Common.CommonModule("ОбработкаНовостейСлужебный");
		EnableNewsManagement = ModuleNewsProcessing.NewsManagementEnabled();
		NewsDisplaySettingsByAdmin =
			ModuleNewsProcessingInternal.ПолучитьНастройкиПоказаНовостейНастроенныеАдминистратором(True);
		NewsList_AutoUpdateInterval = NewsDisplaySettingsByAdmin.NewsList_AutoUpdateInterval;
		If Common.DataSeparationEnabled()
				And Common.SeparatedDataUsageAvailable() Then
			Items.GroupNewsSharedSessionOrOnPremisesApp.Visible = False;
			Items.GroupNewsSeparatedSession.Visible             = True;
		Else
			Items.GroupNewsSharedSessionOrOnPremisesApp.Visible = True;
			Items.GroupNewsSeparatedSession.Visible             = False;
		EndIf;
		Items.NewsManagement.Visible = EnableNewsManagement;
	Else
		Items.NewsGroup_.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		ModuleGetAddIns = Common.CommonModule("GetAddIns");
		ModuleGetAddIns.OnlineSupportAndServicesOnCreateAtServer(ThisObject);
	Else
		Items.GroupAddInsUpdate.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		
		ModuleGetApplicationUpdates = Common.CommonModule("GetApplicationUpdates");
		ModuleGetApplicationUpdates.InternetSupportAndServicesOnCreateAtServer(ThisObject);
		
		WriteIBUpdateDetailsToEventLog =
			Constants["WriteIBUpdateDetailsToEventLog"].Get();
		
	Else
		Items.GroupAppUpdate.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		ParametersOfClassifiersSubsystem =
			ModuleClassifiersOperations.OnlineSupportAndServicesFormEnvironmentParameters();
		
		Items.GroupClassifiersUpdate.Visible =
			ParametersOfClassifiersSubsystem.IsInteractiveImportAvailable;
		
		If ParametersOfClassifiersSubsystem.IsInteractiveImportAvailable Then
			
			ClassifiersUpdateOption =
				ParametersOfClassifiersSubsystem.ClassifiersUpdateOption;
			ClassifiersFile = ParametersOfClassifiersSubsystem.ClassifiersFile;
			ClassifiersUpdateOptionPrevVal = ClassifiersUpdateOption;
			
			If Not IsBlankString(ParametersOfClassifiersSubsystem.SchedulePresentation) Then
				Items.ClassifiersUpdateScheduleDecoration.Title =
					ParametersOfClassifiersSubsystem.SchedulePresentation;
			EndIf;
			
			Items.DecorationClassifiersUpdateDisabled.Visible =
				(Not OnlineUserSupport.AuthenticationDataOfOnlineSupportUserFilled()
				And ClassifiersUpdateOption = 1);
			
		EndIf;
		
	Else
		Items.GroupClassifiersUpdate.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.WorkingWithCounterparties") Then
		
		Items.GroupCounterpartyVerification.Visible =
			IsSystemAdministrator
			And (Not IsStandaloneWorkplace
			And Not DataSeparationEnabled
			Or Not SeparatedDataUsageAvailable);
		If Items.GroupCounterpartyVerification.Visible Then
			ModuleCounterpartiesFunctions = Common.CommonModule("WorkingWithCounterparties");
			UseCounterpartyVerification = ModuleCounterpartiesFunctions.UseCounterpartyVerification();
		EndIf;
		
	Else
		Items.GroupCounterpartyVerification.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		Items.GroupSPARKSRisks.Visible =
			IsSystemAdministrator
			And (Not IsStandaloneWorkplace
			And Not DataSeparationEnabled
			Or Not SeparatedDataUsageAvailable);
		If Items.GroupSPARKSRisks.Visible Then
			ModuleSPARKRisks = Common.CommonModule("SparkRisks");
			UseSPARKRisksService = ModuleSPARKRisks.ИспользованиеСПАРКРискиВключено();
		EndIf;
	Else
		Items.GroupSPARKSRisks.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.InstantPayments") Then
		
		ModuleFasterPaymentSystemInternal = Common.CommonModule(
			"InstantPaymentsInternal");
		FasterPaymentSystemSubsystemParameters =
			ModuleFasterPaymentSystemInternal.OnlineSupportAndServicesFormEnvironmentParameters();
		If FasterPaymentSystemSubsystemParameters.НастройкаИнтеграцияДоступна Then
			PaymentSystemOperationDuration =
				FasterPaymentSystemSubsystemParameters.ДлительностьОперацииСистемыБыстрыхПлатежей;
		Else
			Items.GroupFasterPaymentSystem.Visible = False;
		EndIf;
		
		SubsystemFPSc2bTransfers = Common.SubsystemExists("OnlineUserSupport.InstantPayments.FPSc2bTransfers");
		SubsystemMessagesTemplates = Common.SubsystemExists("StandardSubsystems.MessageTemplates");
		SendSMSMessageSubsystem = Common.SubsystemExists("StandardSubsystems.SendSMSMessage");
		SubsystemEmailSending = Common.SubsystemExists("StandardSubsystems.EmailOperations");
		
		CanSetUpTemplates = (SubsystemMessagesTemplates
			And SubsystemFPSc2bTransfers
			And (SendSMSMessageSubsystem Or SubsystemEmailSending));
		
		CommonClientServer.SetFormItemProperty(
			Items,
			"GroupFPSTemplateSetup",
			"Visible",
			CanSetUpTemplates);
		
	Else
		Items.GroupFasterPaymentSystem.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.IntegrationWithConnect") Then
		
		ModuleIntegrationWithConnect = Common.CommonModule("IntegrationWithConnect");
		ParametersOfIntegrationWith1CConnectSubsystem =
			ModuleIntegrationWithConnect.OnlineSupportAndServicesFormEnvironmentParameters();
		
		If ParametersOfIntegrationWith1CConnectSubsystem.ДоступнаИнтеграцияСКоннект Then
			
			Use1CConnect = ParametersOfIntegrationWith1CConnectSubsystem.Use1CConnect;
			If Not Users.IsFullUser() Then
				Items.Use1CConnect.Enabled = False;
			EndIf;
			
			If Not Use1CConnect Then
				Items.IntegrationWith1CConnectSetup.Enabled = False;
			EndIf;
			
		Else
			Items.GroupIntegrationWith1CConnect.Visible = False;
		EndIf;
		
	Else
		Items.GroupIntegrationWith1CConnect.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.GettingStatutoryReports") Then
		StatutoryReportsGetterModule = Common.CommonModule("GettingStatutoryReports");
		StatutoryReportsGetterModule.OnlineSupportAndServicesOnCreateAtServer(ThisObject);
	Else
		Items.GroupStatutoryReportsUpdate.Visible = False;
	EndIf;
	
	Items.MessageToTechnicalSupportService.Visible =
		Common.SubsystemExists("OnlineUserSupport.MessagesToTechSupportService")
		And Not IsStandaloneWorkplace
		And Not DataSeparationEnabled;
	
	RefreshStateOfOnlinePaymentSubsystem();
	
EndProcedure

&AtServer
Procedure RefreshStateOfOnlinePaymentSubsystem()
	
	If Not Common.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		Items.GroupOfOnlinePayment.Visible = False;
		Return;
	EndIf;
	
	ModuleOnlinePayment = Common.CommonModule("OnlinePayment");
	ParametersSubsystems = ModuleOnlinePayment.OnlineSupportAndServicesFormEnvironmentParameters();
	
	If Not ParametersSubsystems.ОнлайнОплатаДоступна Then
		Items.GroupOfOnlinePayment.Visible = False;
		Return;
	EndIf;
	
	OnlinePayment = ParametersSubsystems.UseOnlinePayment;
	If Not ParametersSubsystems.НастройкаИнтеграцииДоступна
			And Not ParametersSubsystems.ЕстьПравоПросмотраСтатусовОнлайнОплат Then
		Items.GroupOfOnlinePayment.Visible = False;
		Return;
	ElsIf Not ParametersSubsystems.НастройкаИнтеграцииДоступна Then
		Items.OnlinePaymentsLeft.Visible = False;
		Items.GroupCustomizeTemplatesOnlinePayments.Visible = False;
		Return;
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"GroupCustomizeTemplatesOnlinePayments",
		"Visible",
		Common.SubsystemExists("StandardSubsystems.MessageTemplates"));
	
	Items.GroupReceivingNotifications.Enabled       = OnlinePayment;
	Items.GroupSettingsOnlinePaymentRight.Enabled = OnlinePayment;
	
	If ParametersSubsystems.UseAutomaticReceivingNotificationFromOnlinePayments <> Undefined Then
		UseAutomaticReceivingNotificationFromOnlinePayments =
			ParametersSubsystems.UseAutomaticReceivingNotificationFromOnlinePayments;
		Items.DecorationScheduleReceivingNotificationsFromOnlinePayments.Title =
			ParametersSubsystems.SchedulePresentation;
	Else
		UseAutomaticReceivingNotificationFromOnlinePayments = False;
	EndIf;
	
	Items.DecorationScheduleReceivingNotificationsFromOnlinePayments.Enabled =
		UseAutomaticReceivingNotificationFromOnlinePayments;
	
	Items.DecorationScheduleReceivingNotificationsFromOnlinePayments.Visible = Not DataSeparationEnabled;
	
	If IsSystemAdministrator Then
		Items.DecorationScheduleReceivingNotificationsFromOnlinePayments.Hyperlink = True;
		Items.DecorationScheduleReceivingNotificationsFromOnlinePayments.TextColor = StyleColors.HyperlinkColor;
	Else
		Items.DecorationScheduleReceivingNotificationsFromOnlinePayments.Hyperlink = False;
		Items.DecorationScheduleReceivingNotificationsFromOnlinePayments.TextColor = StyleColors.NoteText;
	EndIf;
	
EndProcedure

&AtClient
Async Procedure AutomaticUpdatesCheckOnChangeAsync(Item)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		
		If AutomaticUpdatesCheck = 0 Then
			
			QueryText = NStr(
				"ru = 'Оповещения о наличии новых версий программы, исправлениях (патчах) и обновлениях версий платформы будут отключены. Продолжить?';
				|en = 'Notifications about new application versions, patches, and platform updates will be disabled. Continue?';");
			Response        = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo);
			If Response <> DialogReturnCode.Yes Then
				AutomaticUpdatesCheck = AutoCheckUpdatesBeforeChange;
				Return;
			EndIf;
			
		EndIf;
		
		AutoCheckUpdatesBeforeChange = AutomaticUpdatesCheck;
		
		ModuleGetApplicationUpdatesClient =
			CommonClient.CommonModule("GetApplicationUpdatesClient");
		ModuleGetApplicationUpdatesClient.AutomaticUpdatesCheckOnChange(
			ThisObject,
			Item);
			
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure SaveUpdateReleaseNotificationOptionAtServer(Val NewValue)
	
	If Common.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		
		ModuleGetApplicationUpdates = Common.CommonModule("GetApplicationUpdates");
		
		SettingsOfUpdate = ModuleGetApplicationUpdates.AutoupdateSettings();
		SettingsOfUpdate.UpdateReleaseNotificationOption = NewValue;
		
		ModuleGetApplicationUpdates.WriteAutoupdateSettings(SettingsOfUpdate);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnlineSupportServicesSetUpAccessLock()
	
	Items.GroupOnlineSupportServicesAccessLock.Visible =
		ScheduledJobsServer.OperationsWithExternalResourcesLocked();
	If Not Users.IsFullUser() Then
		Items.NoteOnlineSupportServicesAccessLock.Title = 
			NStr("ru = 'Работа с сервисами Интернет-поддержки заблокирована для предотвращения конфликтов с основной информационной базой.
				|Обратитесь к администратору.';
				|en = 'Online support services are disabled to prevent conflicts with the main infobase. 
				|Contact the administrator.';");
	EndIf;
	
EndProcedure

#EndRegion
