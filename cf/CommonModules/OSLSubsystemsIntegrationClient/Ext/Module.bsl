///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The Online Support subsystem.
// CommonModule.OSLSubsystemsIntegration.
//
// Client procedures and functions for integration with SSL and OSL:
//  - Subscription to SSL events
//  - Handle SSL events in OSL subsystems
//  - Determine a list of possible subscriptions in OSL
//  - Call the subscribed-to SSL methods
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.Core

// Handle software events that occur in SSL subsystems.
// Intended only for calls from OSL to SSL.

// Defines events, to which this library is subscribed.
//
// Parameters:
//  Subscriptions - Structure - See SSLSubsystemsIntegrationClient.SSLEvents.
//
Procedure OnDefineEventSubscriptionsSSL(Subscriptions) Export
	
	// Report options.
	Subscriptions.OnProcessSpreadsheetDocumentSelection = True;
	Subscriptions.OnProcessDetails = True;

	Subscriptions.AfterStart = True;

EndProcedure

#Region ReportsOptions

// See ReportsClientOverridable.SpreadsheetDocumentSelectionHandler.
//
Procedure OnProcessSpreadsheetDocumentSelection(ReportForm, Item, Area, StandardProcessing) Export
	
	If CommonClient.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		ModuleSPARKRisksClient = CommonClient.CommonModule("SparkRisksClient");
		ModuleSPARKRisksClient.OnProcessSpreadsheetDocumentSelection(
			ReportForm,
			Item,
			Area,
			StandardProcessing);
	EndIf;
	
	If CommonClient.SubsystemExists("OnlineUserSupport.InstantPayments.ARAPReconciliationWithEnterpriseAccountingc2b") Then
		ModuleARAPReconciliationWithEnterpriseAccountingc2bClient = CommonClient.CommonModule("ARAPReconciliationWithEnterpriseAccountingc2bClient");
		ModuleARAPReconciliationWithEnterpriseAccountingc2bClient.OnProcessSpreadsheetDocumentSelection(
			ReportForm,
			Item,
			Area,
			StandardProcessing);
	EndIf;
	
	If CommonClient.SubsystemExists("OnlineUserSupport.InstantPayments.FPSc2bTransfers") Then
		ModuleFPSc2bTransfersClient = CommonClient.CommonModule("FPSc2bTransfersClient");
		ModuleFPSc2bTransfersClient.OnProcessSpreadsheetDocumentSelection(
			ReportForm,
			Item,
			Area,
			StandardProcessing);
	EndIf;
	
EndProcedure

// See ReportsClientOverridable.DetailProcessing.
//
Procedure OnProcessDetails(ReportForm, Item, Details, StandardProcessing) Export
	
	If CommonClient.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		ModuleSPARKRisksClient = CommonClient.CommonModule("SparkRisksClient");
		ModuleSPARKRisksClient.OnProcessDetails(
			ReportForm,
			Item,
			Details,
			StandardProcessing);
	EndIf;
	
EndProcedure

// End StandardSubsystems.Core

#EndRegion

#EndRegion

#EndRegion

#Region Internal

#Region Core

// See OnlineUserSupportClientOverridable.OpenInternetPage.
//
Procedure OpenInternetPage(PageAddress, WindowTitle, StandardProcessing) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().OpenInternetPage Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OpenInternetPage(
			PageAddress,
			WindowTitle,
			StandardProcessing);
	EndIf;
	
EndProcedure

#EndRegion

#Region BasicFPSFeatures

// See "InstantPaymentsClientOverridable.OnProcessAdditionalInfoURL".
//
Procedure OnProcessAdditionalInfoURL(
		Item,
		FormattedStringURL,
		StandardProcessing,
		FormData1) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().OnProcessAdditionalInfoURL Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OnProcessAdditionalInfoURL(
			Item,
			FormattedStringURL,
			StandardProcessing,
			FormData1);
	EndIf;
	
EndProcedure

#EndRegion

#Region FPSc2bTransfers

// See "FPSc2bTransfersClientOverridable.OnPopulateMessageParametersNoTemplateFPS".
//
Procedure OnPopulateMessageParametersNoTemplateFPS(MessageParameters, OperationParametersList) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().OnPopulateMessageParametersNoTemplateFPS Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OnPopulateMessageParametersNoTemplateFPS(MessageParameters, OperationParametersList);
	EndIf;
	
EndProcedure

// See "FPSc2bTransfersClientOverridable.OnOpenQRCodeForm".
//
Procedure OnOpenQRCodeForm(
		Form,
		PaymentLinkData,
		NotificationAfterFormSetupCompleted) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().OnOpenQRCodeForm Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OnOpenQRCodeForm(
			Form,
			PaymentLinkData,
			NotificationAfterFormSetupCompleted);
	EndIf;
	
EndProcedure

// See "FPSc2bTransfersClientOverridable.OnCloseQRCodeForm".
//
Procedure OnCloseQRCodeForm(Form) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().OnCloseQRCodeForm Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OnCloseQRCodeForm(Form);
	EndIf;
	
EndProcedure

// See "FPSc2bTransfersClientOverridable.OnDisplayQRCode".
//
Procedure OnDisplayQRCode(PaymentLinkData, Parameters) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().OnDisplayQRCode Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OnDisplayQRCode(PaymentLinkData, Parameters);
	EndIf;
	
EndProcedure

// See "FPSc2bTransfersClientOverridable.OnHandlingCommandClick".
//
Procedure OnHandlingCommandClick(Form, Command, PaymentLinkData) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().OnHandlingCommandClick Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OnHandlingCommandClick(
			Form,
			Command,
			PaymentLinkData);
	EndIf;
	
EndProcedure

// See "FPSc2bTransfersClientOverridable.OnCloseLinkAttachmentForm".
//
Procedure OnCloseLinkAttachmentForm(Form, Exit) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().OnCloseLinkAttachmentForm Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OnCloseLinkAttachmentForm(
			Form,
			Exit);
	EndIf;
	
EndProcedure

// See "FPSc2bTransfersClientOverridable.OnOpenLinkAttachmentForm".
//
Procedure OnOpenLinkAttachmentForm(Form, Cancel) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().OnOpenLinkAttachmentForm Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OnOpenLinkAttachmentForm(
			Form,
			Cancel);
	EndIf;
	
EndProcedure

// See "FPSc2bTransfersClientOverridable.HandleNotificationsForLinkAttachmentForm".
//
Procedure HandleNotificationsForLinkAttachmentForm(
		Form,
		EventName,
		Parameter,
		Source,
		Connect) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().HandleNotificationsForLinkAttachmentForm Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.HandleNotificationsForLinkAttachmentForm(
			Form,
			EventName,
			Parameter,
			Source,
			Connect);
	EndIf;
	
EndProcedure

#EndRegion

#Region PortalMonitor1CITS

// See 1CITSPortalDashboardClientOverridable.BeforeGetMonitorData.
//
Procedure BeforeReceivingMonitorData(Form) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().BeforeReceivingMonitorData Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.BeforeReceivingMonitorData(
			Form);
	EndIf;
	
EndProcedure

// See 1CITSPortalDashboardClientOverridable.ProcessCommandInMonitorForm.
//
Procedure ProcessACommandInTheFormOfAMonitor(Form, Command) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().ProcessACommandInTheFormOfAMonitor Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.ProcessACommandInTheFormOfAMonitor(
			Form,
			Command);
	EndIf;
	
EndProcedure

// See 1CITSPortalDashboardClientOverridable.OnClickDecorationInMonitorForm.
//
Procedure WhenYouClickTheSceneryInTheFormOfAMonitor(Form, Item) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().WhenYouClickTheSceneryInTheFormOfAMonitor Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.WhenYouClickTheSceneryInTheFormOfAMonitor(
			Form,
			Item);
	EndIf;
	
EndProcedure

// See 1CITSPortalDashboardClientOverridable.ProcessURLInMonitorForm.
//
Procedure ProcessANavigationLinkInTheFormOfAMonitor(
	Form,
	Item,
	FormattedStringURL,
	StandardProcessing) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().ProcessANavigationLinkInTheFormOfAMonitor Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.ProcessANavigationLinkInTheFormOfAMonitor(
			Form,
			Item,
			FormattedStringURL,
			StandardProcessing);
	EndIf;
	
EndProcedure

// See 1CITSPortalDashboardClientOverridable.OnExecuteIdleHandlerInMonitorForm.
//
Procedure WhenExecutingAWaitHandlerInTheFormOfAMonitor(Form) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().WhenExecutingAWaitHandlerInTheFormOfAMonitor Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.WhenExecutingAWaitHandlerInTheFormOfAMonitor(
			Form);
	EndIf;
	
EndProcedure

// See 1CITSPortalDashboardClientOverridable.OnCloseMonitorForm.
//
Procedure WhenClosingTheMonitorForm(Form, Exit) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().WhenClosingTheMonitorForm Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.WhenClosingTheMonitorForm(
			Form,
			Exit);
	EndIf;
	
EndProcedure

#EndRegion

#Region OnlinePayment

// See "OnlinePaymentsClientOverridable.SettingsFormItemOnChange".
//
Procedure SettingsFormItemOnChange(Context, Item) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().SettingsFormItemOnChange Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.SettingsFormItemOnChange(Context, Item);
	EndIf;
	
EndProcedure

// See "OnlinePaymentsClientOverridable.SettingsFormItemCreate".
//
Procedure SettingsFormItemCreate(Context, Item, StandardProcessing) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().SettingsFormItemCreate Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.SettingsFormItemCreate(Context, Item, StandardProcessing);
	EndIf;
	
EndProcedure

// See "OnlinePaymentsClientOverridable.SettingsFormElementChoiceStart".
//
Procedure SettingsFormElementChoiceStart(Context, Item, ChoiceData, StandardProcessing) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().SettingsFormElementChoiceStart Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.SettingsFormElementChoiceStart(
			Context,
			Item,
			ChoiceData,
			StandardProcessing);
	EndIf;
	
EndProcedure

// See "OnlinePaymentsClientOverridable.SetupFormElementsSelectionProcessing".
//
Procedure SetupFormElementsSelectionProcessing(Context, Item, ValueSelected, StandardProcessing) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().SetupFormElementsSelectionProcessing Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.SetupFormElementsSelectionProcessing(
			Context,
			Item,
			ValueSelected,
			StandardProcessing);
	EndIf;
	
EndProcedure

// See "OnlinePaymentsClientOverridable.SettingsFormElementClick".
//
Procedure SettingsFormElementClick(Context, Item) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().SettingsFormElementClick Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.SettingsFormElementClick(Context, Item);
	EndIf;
	
EndProcedure

// See "OnlinePaymentsClientOverridable.SettingsFormCommandAction".
//
Procedure SettingsFormCommandAction(Context, Command) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().SettingsFormCommandAction Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.SettingsFormCommandAction(Context, Command);
	EndIf;
	
EndProcedure

// See "OnlinePaymentsClientOverridable.PopulateMessageParametersWithoutTemplate".
//
Procedure PopulateMessageParametersWithoutTemplate(MessageParameters) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().PopulateMessageParametersWithoutTemplate Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.PopulateMessageParametersWithoutTemplate(MessageParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region GetApplicationUpdates

// See GetApplicationUpdatesClientOverridable.OnDefineIsNecessaryToShowAvailableUpdatesNotifications.
//
Procedure OnDefineIsNecessaryToShowAvailableUpdatesNotifications(Use) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().OnDefineIsNecessaryToShowAvailableUpdatesNotifications Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OnDefineIsNecessaryToShowAvailableUpdatesNotifications(Use);
	EndIf;
	
EndProcedure

#EndRegion

#Region SparkRisks

// See SPARKRisksClientOverridable.URLProcessing.
//
Procedure ProcessingOfTheSPARKNavigationLinkRisks(
		Form,
		FormItem,
		URL,
		StandardFormProcessing,
		StandardLibraryProcessing) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().ProcessingOfTheSPARKNavigationLinkRisks Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.ProcessingOfTheSPARKNavigationLinkRisks(
			Form,
			FormItem,
			URL,
			StandardFormProcessing,
			StandardLibraryProcessing);
	EndIf;
	
EndProcedure

// See SPARKRisksClientOverridable.NotificationProcessing.
//
Procedure HandlingSPARKAlertRisks(
		Form,
		CounterpartyObject,
		EventName,
		Parameter,
		Source,
		StandardLibraryProcessing) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().HandlingSPARKAlertRisks Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.HandlingSPARKAlertRisks(
			Form,
			CounterpartyObject,
			EventName,
			Parameter,
			Source,
			StandardLibraryProcessing);
	EndIf;
	
EndProcedure

// See SPARKRisksClientOverridable.OverrideBackgroundJobsCheckParameters.
//
Procedure RedefineTheParametersForCheckingBackgroundTasksSPARKRisks(
		NumberOfChecks,
		CheckInterval) Export
	
	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().RedefineTheParametersForCheckingBackgroundTasksSPARKRisks Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.RedefineTheParametersForCheckingBackgroundTasksSPARKRisks(
			NumberOfChecks,
			CheckInterval);
	EndIf;
	
EndProcedure

#EndRegion

#Region BasicSSLFeatures

// See CommonClientOverridable.AfterStart.
//
Procedure AfterStart() Export

	If CommonClient.SubsystemExists("OnlineUserSupport.News_") Then
		ModuleNewsProcessingClient = CommonClient.CommonModule("ОбработкаНовостейКлиент");
		ModuleNewsProcessingClient.AfterStart();
	EndIf;

EndProcedure

#EndRegion

#Region News_

// See "NewsProcessingClientOverridable.PerformInteractiveAction"
//
Procedure PerformInteractiveAction(Action) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().PerformInteractiveAction Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.PerformInteractiveAction(Action);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.ContextNews_NewsCommandHandling"
//
Procedure ContextNews_NewsCommandHandling(Form, Command) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().ContextNews_NewsCommandHandling Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.ContextNews_NewsCommandHandling(Form, Command);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.ContextNews_HandleNotification"
//
Procedure ContextNews_HandleNotification(Form, EventName, Parameter, Source) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().ContextNews_HandleNotification Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.ContextNews_HandleNotification(Form, EventName, Parameter, Source);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.ContextNews_ShowMustReadNewsOnOpen_BeforeStandardProcessing"
//
Procedure ContextNews_ShowMustReadNewsOnOpen_BeforeStandardProcessing(
			Form,
			EventsIDsOnOpen,
			StandardProcessing = True) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().ContextNews_ShowMustReadNewsOnOpen_BeforeStandardProcessing Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.ContextNews_ShowMustReadNewsOnOpen_BeforeStandardProcessing(
			Form,
			EventsIDsOnOpen,
			StandardProcessing);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.ContextNews_ShowMustReadNewsOnOpen_AfterStandardProcessing"
//
Procedure ContextNews_ShowMustReadNewsOnOpen_AfterStandardProcessing(
			Form,
			EventsIDsOnOpen) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().ContextNews_ShowMustReadNewsOnOpen_AfterStandardProcessing Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.ContextNews_ShowMustReadNewsOnOpen_AfterStandardProcessing(
			Form,
			EventsIDsOnOpen);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.ContextNews_OnOpen_BeforeStandardProcessing"
//
Procedure ContextNews_OnOpen_BeforeStandardProcessing(Form, StandardProcessing = True) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().ContextNews_OnOpen_BeforeStandardProcessing Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.ContextNews_OnOpen_BeforeStandardProcessing(Form, StandardProcessing);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.ContextNews_OnOpen_AfterStandardProcessing"
//
Procedure ContextNews_OnOpen_AfterStandardProcessing(Form) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().ContextNews_OnOpen_AfterStandardProcessing Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.ContextNews_OnOpen_AfterStandardProcessing(Form);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.HandleClickInNewsText"
//
Procedure HandleClickInNewsText(
			News_,
			EventData,
			Form,
			FormItem,
			StandardProcessingBy1CEnterprise,
			StandardProcessingBySubsystem) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().HandleClickInNewsText Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.HandleClickInNewsText(
			News_,
			EventData,
			Form,
			FormItem,
			StandardProcessingBy1CEnterprise,
			StandardProcessingBySubsystem);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.HandleEvent"
//
Procedure HandleEvent(NewsItemRef, Form, ParametersList) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().HandleEvent Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.HandleEvent(NewsItemRef, Form, ParametersList);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.ContextNewsPanel_HandlersParameters"
//
Procedure ContextNewsPanel_HandlersParameters(Result) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().ContextNewsPanel_HandlersParameters Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.ContextNewsPanel_HandlersParameters(Result);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.ContextNewsPanel_NewsPanelItemClick"
//
Procedure ContextNewsPanel_NewsPanelItemClick(Form, Item, StandardProcessing) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().ContextNewsPanel_NewsPanelItemClick Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.ContextNewsPanel_NewsPanelItemClick(Form, Item, StandardProcessing);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.ContextNewsPanel_NewsPanelItemHandleURL"
//
Procedure ContextNewsPanel_NewsPanelItemHandleURL(
			Form,
			Item,
			ItemURL,
			StandardProcessingBy1CEnterprise,
			StandardProcessingBySubsystem) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().ContextNewsPanel_NewsPanelItemHandleURL Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.ContextNewsPanel_NewsPanelItemHandleURL(
			Form,
			Item,
			ItemURL,
			StandardProcessingBy1CEnterprise,
			StandardProcessingBySubsystem);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.OverrideInitialDisplayOfImportantAndCriticalNewsOnStartup"
//
Procedure OverrideInitialDisplayOfImportantAndCriticalNewsOnStartup(IntervalInSec) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().OverrideInitialDisplayOfImportantAndCriticalNewsOnStartup Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OverrideInitialDisplayOfImportantAndCriticalNewsOnStartup(IntervalInSec);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.OverrideMessageLabelsWithoutContextNews"
//
Procedure OverrideMessageLabelsWithoutContextNews(
			Form,
			MessageText,
			ExplanationOfMessage,
			Cancel) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().OverrideMessageLabelsWithoutContextNews Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OverrideMessageLabelsWithoutContextNews(
			Form,
			MessageText,
			ExplanationOfMessage,
			Cancel);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.OverrideOpenParametersForContextNewsForm"
//
Procedure OverrideOpenParametersForContextNewsForm(OpeningParameters) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().OverrideOpenParametersForContextNewsForm Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OverrideOpenParametersForContextNewsForm(OpeningParameters);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.OverrideOpenParametersForNewsItemForm"
//
Procedure OverrideOpenParametersForNewsItemForm(FormName, OpeningParameters) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().OverrideOpenParametersForNewsItemForm Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OverrideOpenParametersForNewsItemForm(FormName, OpeningParameters);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.OverrideOpenParametersForContextNewsListForm"
//
Procedure OverrideOpenParametersForContextNewsListForm(FormName, OpeningParameters) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().OverrideOpenParametersForContextNewsListForm Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OverrideOpenParametersForContextNewsListForm(FormName, OpeningParameters);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.OverrideOpenParametersForNewsListForm"
//
Procedure OverrideOpenParametersForNewsListForm(
			FormName,
			OpeningParameters,
			CommandParameter = Undefined,
			CommandExecuteParameters = Undefined) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().OverrideOpenParametersForNewsListForm Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OverrideOpenParametersForNewsListForm(
			FormName,
			OpeningParameters,
			CommandParameter,
			CommandExecuteParameters);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.OverrideOpenParametersForCriticalContextNewsForm"
//
Procedure OverrideOpenParametersForCriticalContextNewsForm(
			FormName,
			OpeningParameters) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().OverrideOpenParametersForCriticalContextNewsForm Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OverrideOpenParametersForCriticalContextNewsForm(
			FormName,
			OpeningParameters);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.ShowImportantNewsWithEnabledNotifications"
//
Procedure ShowImportantNewsWithEnabledNotifications(
			NewsCritical,
			ImportantNews,
			AdditionalParameters,
			StandardProcessing) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().ShowImportantNewsWithEnabledNotifications Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.ShowImportantNewsWithEnabledNotifications(
			NewsCritical,
			ImportantNews,
			AdditionalParameters,
			StandardProcessing);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.AfterUserSettingsWritten"
//
Procedure AfterUserSettingsWritten(SavedSettings, Cancel) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().AfterUserSettingsWritten Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.AfterUserSettingsWritten(SavedSettings, Cancel);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.ViewNewsItem_HandleNotification"
//
Procedure ViewNewsItem_HandleNotification(
			EventName,
			Parameter,
			Source,
			Form,
			HTMLDocuments,
			StandardProcessing) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().ViewNewsItem_HandleNotification Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.ViewNewsItem_HandleNotification(
			EventName,
			Parameter,
			Source,
			Form,
			HTMLDocuments,
			StandardProcessing);
	EndIf;

EndProcedure

// See "NewsProcessingClientOverridable.CurrentUserCanManageNews"
//
Procedure CurrentUserCanManageNews(Result) Export

	If OSLSubsystemsIntegrationClientCached.SubscriptionsSSL().CurrentUserCanManageNews Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.CurrentUserCanManageNews(Result);
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#Region Private

// Defines events, to which other libraries can subscribe.
//
// Returns:
//   События - Structure - structure property keys are names of events, to which
//             libraries can be subscribed.
//
Function OSLEvents() Export
	
	Events = New Structure;
	
	// OSL core
	Events.Insert("OpenInternetPage", False);
	
	// 1C:ITS Portal Dashboard
	Events.Insert("BeforeReceivingMonitorData", False);
	Events.Insert("ProcessACommandInTheFormOfAMonitor", False);
	Events.Insert("WhenOpeningTheIntegrationSettingsForm", False);
	Events.Insert("ProcessANavigationLinkInTheFormOfAMonitor", False);
	Events.Insert("WhenExecutingAWaitHandlerInTheFormOfAMonitor", False);
	Events.Insert("WhenClosingTheMonitorForm", False);
	
	// Online payments
	Events.Insert("SettingsFormItemOnChange", False);
	Events.Insert("SettingsFormItemCreate", False);
	Events.Insert("SettingsFormElementChoiceStart", False);
	Events.Insert("SetupFormElementsSelectionProcessing", False);
	Events.Insert("SettingsFormElementClick", False);
	Events.Insert("SettingsFormCommandAction", False);
	Events.Insert("PopulateMessageParametersWithoutTemplate", False);
	
	// Get application updates.
	Events.Insert("OnDefineIsNecessaryToShowAvailableUpdatesNotifications", False);
	
	// Faster Payments System basic functionality
	Events.Insert("OnProcessAdditionalInfoURL", False);
	
	// FPS transfers (c2b)
	Events.Insert("OnPopulateMessageParametersNoTemplateFPS", False);
	Events.Insert("OnOpenQRCodeForm", False);
	Events.Insert("OnDisplayQRCode", False);
	Events.Insert("OnCloseQRCodeForm", False);
	Events.Insert("OnHandlingCommandClick", False);
	Events.Insert("OnOpenLinkAttachmentForm", False);
	Events.Insert("OnCloseLinkAttachmentForm", False);
	Events.Insert("HandleNotificationsForLinkAttachmentForm", False);
	
	// SPARK Risks.
	Events.Insert("ProcessingOfTheSPARKNavigationLinkRisks", False);
	Events.Insert("HandlingSPARKAlertRisks", False);
	Events.Insert("RedefineTheParametersForCheckingBackgroundTasksSPARKRisks", False);
	
	// News (client)
	Events.Insert("PerformInteractiveAction", False);
	Events.Insert("ContextNews_NewsCommandHandling", False);
	Events.Insert("ContextNews_HandleNotification", False);
	Events.Insert("ContextNews_ShowMustReadNewsOnOpen_BeforeStandardProcessing", False);
	Events.Insert("ContextNews_ShowMustReadNewsOnOpen_AfterStandardProcessing", False);
	Events.Insert("ContextNews_OnOpen_BeforeStandardProcessing", False);
	Events.Insert("ContextNews_OnOpen_AfterStandardProcessing", False);
	Events.Insert("HandleClickInNewsText", False);
	Events.Insert("HandleEvent", False);
	Events.Insert("ContextNewsPanel_HandlersParameters", False);
	Events.Insert("ContextNewsPanel_NewsPanelItemClick", False);
	Events.Insert("ContextNewsPanel_NewsPanelItemHandleURL", False);
	Events.Insert("OverrideInitialDisplayOfImportantAndCriticalNewsOnStartup", False);
	Events.Insert("OverrideMessageLabelsWithoutContextNews", False);
	Events.Insert("OverrideOpenParametersForContextNewsForm", False);
	Events.Insert("OverrideOpenParametersForNewsItemForm", False);
	Events.Insert("OverrideOpenParametersForContextNewsListForm", False);
	Events.Insert("OverrideOpenParametersForNewsListForm", False);
	Events.Insert("OverrideOpenParametersForCriticalContextNewsForm", False);
	Events.Insert("ShowImportantNewsWithEnabledNotifications", False);
	Events.Insert("AfterUserSettingsWritten", False);
	Events.Insert("ViewNewsItem_HandleNotification", False);
	Events.Insert("CurrentUserCanManageNews", False);
	
	Return Events;
	
EndFunction

#EndRegion
