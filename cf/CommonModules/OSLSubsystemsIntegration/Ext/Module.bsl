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
// Server procedures and functions for integration with SSL, CTL, and OSL:
//  - Subscription to SSL events
//  - Subscription to CTL events
//  - Handle SSL and CTL events in OSL subsystems
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
//  Subscriptions - Structure - See SSLSubsystemsIntegration.SSLEvents.
//
Procedure OnDefineEventSubscriptionsSSL(Subscriptions) Export
	
	// Core
	Subscriptions.OnAddSubsystems = True;
	Subscriptions.OnAddClientParametersOnStart = True;
	Subscriptions.OnAddClientParameters = True;
	Subscriptions.OnAddMetadataObjectsRenaming = True;
	Subscriptions.OnAddSessionParameterSettingHandlers = True;
	Subscriptions.BeforeStartApplication = True;
	
	// AttachableCommands
	Subscriptions.OnDefineAttachableCommandsKinds = True;
	Subscriptions.OnDefineAttachableObjectsSettingsComposition = True;
	Subscriptions.OnDefineCommandsAttachedToObject = True;
	
	// Security profiles.
	Subscriptions.OnFillPermissionsToAccessExternalResources = True;
	
	// Users.
	Subscriptions.OnDefineRoleAssignment = True;
	
	// ScheduledJobs
	Subscriptions.OnDefineScheduledJobSettings = True;
	Subscriptions.WhenYouAreForbiddenToWorkWithExternalResources = True;
	Subscriptions.WhenAllowingWorkWithExternalResources = True;
	
	// To-do list.
	Subscriptions.OnDetermineToDoListHandlers = True;
	Subscriptions.OnDetermineCommandInterfaceSectionsOrder = True;
	
	// Access management
	Subscriptions.OnFillMetadataObjectsAccessRestrictionKinds = True;
	Subscriptions.OnFillListsWithAccessRestriction = True;
	
	// Report options.
	Subscriptions.OnSetUpReportsOptions = True;
	
	// Monitoring center.
	Subscriptions.OnCollectConfigurationStatisticsParameters = True;
	
EndProcedure

#Region Core

// See ConfigurationSubsystemsOverridable.OnAddSubsystems.
//
Procedure OnAddSubsystems(SubsystemsModules) Export
	
	SubsystemsModules.Add("InfobaseUpdateISL");
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
//
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	OUSParameters = New Structure;
	
	If Common.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		ModuleGetApplicationUpdates = Common.CommonModule("GetApplicationUpdates");
		ModuleGetApplicationUpdates.ClientParametersOnStart(OUSParameters);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.PortalMonitor1CITS") Then
		ModuleOneCITSPortalDashboard = Common.CommonModule("PortalMonitor1CITS");
		ModuleOneCITSPortalDashboard.ClientParametersOnStart(OUSParameters);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.News_") Then
		ModuleNewsProcessingInternal = Common.CommonModule("ОбработкаНовостейСлужебный");
		ModuleNewsProcessingInternal.OnAddClientParametersOnStart(OUSParameters);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.CloudArchive20") Then
		ModuleCloudArchive20 = Common.CommonModule("CloudArchive20");
		ModuleCloudArchive20.ClientParametersOnStart(OUSParameters);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		ModuleClassifiersOperations.ClientParametersOnStart(OUSParameters);
	EndIf;
	
	Parameters.Insert("OnlineUserSupport", OUSParameters);
	
EndProcedure

// See CommonOverridable.OnAddClientParameters.
//
Procedure OnAddClientParameters(Parameters) Export
	
	OUSParameters = New Structure;
	OUSParameters.Insert("ConfigurationName"          , Metadata.Name);
	OUSParameters.Insert("ApplicationName"             , OnlineUserSupport.InternalApplicationName());
	OUSParameters.Insert("ConfigurationVersion"       , Metadata.Version);
	OUSParameters.Insert("LocalizationCode"           , CurrentLocaleCode());
	OUSParameters.Insert("UpdateProsessingVersion", StandardSubsystemsServer.LibraryVersion());
	
	ConnectionSetup = OnlineUserSupportInternalCached.OUSServersConnectionSettings();
	
	OUSParameters.Insert(
		"OUSServersDomain",
		ConnectionSetup.OUSServersDomain);
	OUSParameters.Insert(
		"CanConnectOnlineUserSupport",
		OnlineUserSupport.CanConnectOnlineUserSupport());
	
	// Add subsystem parameters.
	If Common.SubsystemExists("OnlineUserSupport.WorkingWithCounterparties") Then
		ModuleCounterpartiesFunctions = Common.CommonModule("WorkingWithCounterparties");
		ModuleCounterpartiesFunctions.OnAddClientParameters(OUSParameters);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.News_") Then
		ModuleNewsProcessingInternal = Common.CommonModule("ОбработкаНовостейСлужебный");
		ModuleNewsProcessingInternal.OnAddClientParameters(OUSParameters);
	EndIf;
	
	Parameters.Insert("OnlineUserSupport", OUSParameters);
	
EndProcedure

// See CommonOverridable.BeforeStartApplication
Procedure BeforeStartApplication() Export
	
	LicensingClient.BeforeStartApplication();
	
	If Common.SubsystemExists("OnlineUserSupport.News_") Then
		ModuleNewsProcessingInternal = Common.CommonModule("ОбработкаНовостейСлужебный");
		ModuleNewsProcessingInternal.BeforeStartApplication();
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddMetadataObjectsRenaming.
//
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	Common.AddRenaming(
		Total,
		"2.2.5.1",
		"Role.ПодключениеКСервисуИнтернетПоддержки",
		"Role.CanEnableOnlineSupport",
		"OnlineUserSupport");
	
	Common.AddRenaming(
		Total,
		"2.1.2.1",
		"Role.ИспользованиеИПП",
		"Role.ПодключениеКСервисуИнтернетПоддержки",
		"OnlineUserSupport");
	
	If Common.SubsystemExists("OnlineUserSupport.PortalMonitor1CITS") Then
		ModuleOneCITSPortalDashboard = Common.CommonModule("PortalMonitor1CITS");
		ModuleOneCITSPortalDashboard.OnAddMetadataObjectsRenaming(Total);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		ModuleClassifiersOperations.OnAddMetadataObjectsRenaming(Total);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.IntegrationWithConnect") Then
		ModuleIntegrationWithConnect = Common.CommonModule("IntegrationWithConnect");
		ModuleIntegrationWithConnect.OnAddMetadataObjectsRenaming(Total);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		ModuleOnlinePaymentInternal = Common.CommonModule("OnlinePaymentInternal");
		ModuleOnlinePaymentInternal.OnAddMetadataObjectsRenaming(Total);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.InstantPayments.FPSc2bTransfers") Then
		ModuleFPSc2bTransfersInternal = Common.CommonModule("FPSc2bTransfersInternal");
		ModuleFPSc2bTransfersInternal.OnAddMetadataObjectsRenaming(Total);
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddSessionParameterSettingHandlers.
//
Procedure OnAddSessionParameterSettingHandlers(Handlers) Export
	
	If Common.SubsystemExists("OnlineUserSupport.News_") Then
		ModuleNewsProcessingInternal = Common.CommonModule("ОбработкаНовостейСлужебный");
		ModuleNewsProcessingInternal.OnAddSessionParameterSettingHandlers(Handlers);
	EndIf;
	
EndProcedure

#EndRegion

#Region SecurityProfiles

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources.
//
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export

	If Not Common.DataSeparationEnabled() Then
		
		NewPermissions = New Array;
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		
		Resolution = ModuleSafeModeManager.PermissionToUseInternetResource(
			"HTTPS",
			"login.1c.ru",
			443,
			NStr("ru = 'Сервисы аутентификации (зона ru)';
				|en = 'Authentication services (ru zone)';"));
		NewPermissions.Add(Resolution);
		
		Resolution = ModuleSafeModeManager.PermissionToUseInternetResource(
			"HTTPS",
			"login.1c.eu",
			443,
			NStr("ru = 'Сервисы аутентификации (зона eu)';
				|en = 'Authentication services (eu zone)';"));
		NewPermissions.Add(Resolution);
		
		PermissionsRequests.Add(ModuleSafeModeManager.RequestToUseExternalResources(NewPermissions));
		
		If Common.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
			ModuleGetApplicationUpdates = Common.CommonModule("GetApplicationUpdates");
			ModuleGetApplicationUpdates.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
		EndIf;
		
		If Common.SubsystemExists("OnlineUserSupport.PortalMonitor1CITS") Then
			ModuleOneCITSPortalDashboard = Common.CommonModule("PortalMonitor1CITS");
			ModuleOneCITSPortalDashboard.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
		EndIf;
		
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.EnableMaintenanceServices") Then
		ModuleMaintenanceServicesActivation = Common.CommonModule("EnableMaintenanceServices");
		ModuleMaintenanceServicesActivation.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.Connecting1CTaxi") Then
		ModuleOneCTaxcomConnection = Common.CommonModule("Connecting1CTaxi");
		ModuleOneCTaxcomConnection.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.WorkingWithCounterparties") Then
		ModuleCounterpartiesFunctions = Common.CommonModule("WorkingWithCounterparties");
		ModuleCounterpartiesFunctions.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		ModuleSPARKRisks = Common.CommonModule("SparkRisks");
		ModuleSPARKRisks.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.News_") Then
		ModuleNewsProcessingInternal = Common.CommonModule("ОбработкаНовостейСлужебный");
		ModuleNewsProcessingInternal.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		ModuleClassifiersOperations.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		ModuleGetAddIns = Common.CommonModule("GetAddIns");
		ModuleGetAddIns.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.InstantPayments.BasicFPSFeatures") Then
		ModuleFasterPaymentSystemInternal = Common.CommonModule("InstantPaymentsInternal");
		ModuleFasterPaymentSystemInternal.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		ModuleOnlinePaymentInternal = Common.CommonModule("OnlinePaymentInternal");
		ModuleOnlinePaymentInternal.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.FDO") Then
		ModuleFDOInternal = Common.CommonModule("FDOInternal");
		ModuleFDOInternal.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.ИнтеграцияСЦРПТ") Then
		ModuleIntegrationOfTheSRPT = Common.CommonModule("ИнтеграцияСЦРПТ");
		ModuleIntegrationOfTheSRPT.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.GettingStatutoryReports") Then
		StatutoryReportsGetterModule = Common.CommonModule("GettingStatutoryReports");
		StatutoryReportsGetterModule.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.MessagesToTechSupportService") Then
		TheModuleOfTheMessageToTheTechnicalSupportService = Common.CommonModule("MessagesToTechSupportService");
		TheModuleOfTheMessageToTheTechnicalSupportService.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	EndIf;
	
EndProcedure

#EndRegion

#Region Users

// See UsersOverridable.OnDefineRoleAssignment
// (
//
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	If Common.SubsystemExists("OnlineUserSupport.News_") Then
		ModuleNewsProcessingInternal = Common.CommonModule("ОбработкаНовостейСлужебный");
		ModuleNewsProcessingInternal.OnDefineRoleAssignment(RolesAssignment);
	EndIf;
	
EndProcedure

#EndRegion

#Region AttachableCommands

// See "AttachableCommandsOverridable.OnDefineCommandsAttachedToObject"
//
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	If Common.SubsystemExists("OnlineUserSupport.InstantPayments.FPSc2bTransfers") Then
		ModuleFPSc2bTransfersInternal =
			Common.CommonModule("FPSc2bTransfersInternal");
		ModuleFPSc2bTransfersInternal.OnDefineCommandsAttachedToObject(
			FormSettings,
			Sources,
			AttachedReportsAndDataProcessors,
			Commands);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		ModuleOnlinePayment = Common.CommonModule("OnlinePayment");
		ModuleOnlinePayment.OnDefineCommandsAttachedToObject(
			FormSettings,
			Sources,
			AttachedReportsAndDataProcessors,
			Commands);
	EndIf;
		
	If Common.SubsystemExists("OnlineUserSupport.FDO") Then
		ModuleFDOInternal = Common.CommonModule("FDOInternal");
		ModuleFDOInternal.OnDefineCommandsAttachedToObject(
			FormSettings,
			Sources,
			AttachedReportsAndDataProcessors,
			Commands);
	EndIf;
	
EndProcedure

// See "AttachableCommandsOverridable.OnDefineAttachableObjectsSettingsComposition"
//
Procedure OnDefineAttachableObjectsSettingsComposition(InterfaceSettings4) Export
	
	If Common.SubsystemExists("OnlineUserSupport.InstantPayments.FPSc2bTransfers") Then
		ModuleFPSc2bTransfersInternal = 
			Common.CommonModule("FPSc2bTransfersInternal");
		ModuleFPSc2bTransfersInternal.OnDefineAttachableObjectsSettingsComposition(
			InterfaceSettings4);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		ModuleOnlinePayment = Common.CommonModule("OnlinePayment");
		ModuleOnlinePayment.OnDefineAttachableObjectsSettingsComposition(InterfaceSettings4);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.FDO") Then
		ModuleFDOInternal = Common.CommonModule("FDOInternal");
		ModuleFDOInternal.OnDefineAttachableObjectsSettingsComposition(InterfaceSettings4);
	EndIf;
	
EndProcedure

// See "AttachableCommandsOverridable.OnDefineAttachableCommandsKinds"
//
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	
	If Common.SubsystemExists("OnlineUserSupport.InstantPayments.FPSc2bTransfers") Then
		ModuleFPSc2bTransfersInternal = 
			Common.CommonModule("FPSc2bTransfersInternal");
		ModuleFPSc2bTransfersInternal.OnDefineAttachableCommandsKinds(AttachableCommandsKinds);
	EndIf;

	If Common.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		ModuleOnlinePayment = Common.CommonModule("OnlinePayment");
		ModuleOnlinePayment.OnDefineAttachableCommandsKinds(AttachableCommandsKinds);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.FDO") Then
		ModuleFDOInternal = Common.CommonModule("FDOInternal");
		ModuleFDOInternal.OnDefineAttachableCommandsKinds(AttachableCommandsKinds);
	EndIf;
	
EndProcedure

#EndRegion

#Region ScheduledJobs

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
//
Procedure OnDefineScheduledJobSettings(Settings) Export
	
	If Common.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		ModuleOnlinePayment = Common.CommonModule("OnlinePayment");
		ModuleOnlinePayment.OnDefineScheduledJobSettings(Settings);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.News_") Then
		ModuleNewsProcessingInternal = Common.CommonModule("ОбработкаНовостейСлужебный");
		ModuleNewsProcessingInternal.OnDefineScheduledJobSettings(Settings);
	EndIf;
	
EndProcedure

// See ExternalResourcesOperationsLockOverridable.WhenYouAreForbiddenToWorkWithExternalResources.
//
Procedure WhenYouAreForbiddenToWorkWithExternalResources() Export
	
	OnlineUserSupport.WhenYouAreForbiddenToWorkWithExternalResources();
	
	If Common.SubsystemExists("OnlineUserSupport.CloudArchive20") Then
		ModuleCloudArchive20 = Common.CommonModule("CloudArchive20");
		ModuleCloudArchive20.ЗаблокироватьОблачныйАрхив();
	EndIf;
	
EndProcedure

// See ExternalResourcesOperationsLockOverridable.WhenAllowingWorkWithExternalResources.
//
Procedure WhenAllowingWorkWithExternalResources() Export
	
	OnlineUserSupport.WhenAllowingWorkWithExternalResources();
	
	If Common.SubsystemExists("OnlineUserSupport.CloudArchive20") Then
		ModuleCloudArchive20 = Common.CommonModule("CloudArchive20");
		ModuleCloudArchive20.РазблокироватьОблачныйАрхив();
	EndIf;
	
EndProcedure

#EndRegion

#Region AccessManagement

// See AccessManagementOverridable.OnFillMetadataObjectsAccessRestrictionKinds
//
Procedure OnFillMetadataObjectsAccessRestrictionKinds(LongDesc) Export
	
	If Common.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		ModuleOnlinePayment = Common.CommonModule("OnlinePayment");
		ModuleOnlinePayment.OnFillMetadataObjectsAccessRestrictionKinds(LongDesc);
	EndIf;
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction
//
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	If Common.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		ModuleOnlinePayment = Common.CommonModule("OnlinePayment");
		ModuleOnlinePayment.OnFillListsWithAccessRestriction(Lists);
	EndIf;
	
EndProcedure

#EndRegion

#Region ToDoList

// See ToDoListOverridable.OnDetermineToDoListHandlers.
//
Procedure OnDetermineToDoListHandlers(ToDoList) Export
	
	If Common.SubsystemExists("OnlineUserSupport.EnableMaintenanceServices") Then
		ModuleMaintenanceServicesActivation = Common.CommonModule("EnableMaintenanceServices");
		ToDoList.Add(ModuleMaintenanceServicesActivation);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		ModuleGetApplicationUpdates = Common.CommonModule("GetApplicationUpdates");
		ToDoList.Add(ModuleGetApplicationUpdates);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		ToDoList.Add(ModuleClassifiersOperations);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		ModuleSPARKRisks = Common.CommonModule("SparkRisks");
		ToDoList.Add(ModuleSPARKRisks);
	EndIf;
	
EndProcedure

// See ToDoListOverridable.OnDetermineCommandInterfaceSectionsOrder.
//
Procedure OnDetermineCommandInterfaceSectionsOrder(Sections) Export
	
	Sections.Add(Metadata.Subsystems.OnlineUserSupport);
	
EndProcedure

#EndRegion

#Region ReportsOptions

// See ReportsOptionsOverridable.CustomizeReportsOptions.
//
Procedure OnSetUpReportsOptions(Settings) Export
	
	If Common.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		ModuleSPARKRisks = Common.CommonModule("SparkRisks");
		ModuleSPARKRisks.CustomizeReportsOptions(Settings);
	EndIf;
	
EndProcedure

#EndRegion

#Region MonitoringCenter

// See MonitoringCenterOverridable.OnCollectConfigurationStatisticsParameters.
//
Procedure OnCollectConfigurationStatisticsParameters() Export
	
	If Common.SubsystemExists("OnlineUserSupport.WorkingWithCounterparties") Then
		ModuleCounterpartiesFunctions = Common.CommonModule("WorkingWithCounterparties");
		ModuleCounterpartiesFunctions.OnCollectConfigurationStatisticsParameters();
	EndIf;
	
EndProcedure

#EndRegion

// End StandardSubsystems.Core

// SaaSTechnology.Core

// Handle software events that occur in CTL subsystems.
// Intended only for calls from CTL to OSL.

// Defines events, to which this library is subscribed.
//
// Parameters:
//  Subscriptions - Structure - See CTLSubsystemsIntegration.EventsCTL.
//
Procedure OnDefineEventsSubscriptionsCTL(Subscriptions) Export
	
	// Data export and import
	Subscriptions.OnFillCommonDataTypesSupportingRefMappingOnExport = True;
	Subscriptions.OnFillTypesExcludedFromExportImport = True;
	Subscriptions.AfterImportData = True;
	
	// Job queue.
	Subscriptions.OnGetTemplateList = True;
	Subscriptions.OnDefineHandlerAliases = True;
	
	// Default master data.
	Subscriptions.OnDefineSuppliedDataHandlers = True;
	
	// Tariffication.
	Subscriptions.OnCreateServicesList = True;
	
EndProcedure

#Region ExportImportData

// See ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefMappingOnExport.
//
Procedure OnFillCommonDataTypesSupportingRefMappingOnExport(Types) Export
	
	If Common.SubsystemExists("OnlineUserSupport.News_") Then
		ModuleNewsProcessingInternal = Common.CommonModule("ОбработкаНовостейСлужебный");
		ModuleNewsProcessingInternal.OnFillCommonDataTypesSupportingRefMappingOnExport(Types);
	EndIf;
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
//
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	If Common.SubsystemExists("OnlineUserSupport.EnableMaintenanceServices") Then
		ModuleMaintenanceServicesActivation = Common.CommonModule("EnableMaintenanceServices");
		ModuleMaintenanceServicesActivation.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		ModuleSPARKRisks = Common.CommonModule("SparkRisks");
		ModuleSPARKRisks.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.News_") Then
		ModuleNewsProcessingInternal = Common.CommonModule("ОбработкаНовостейСлужебный");
		ModuleNewsProcessingInternal.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.РасписанияРегламентныхЗаданий") Then
		TheModuleOfTheScheduleOfRoutineTasks = Common.CommonModule("РасписанияРегламентныхЗаданий");
		TheModuleOfTheScheduleOfRoutineTasks.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
EndProcedure

// See ExportImportDataOverridable.AfterImportData.
//
Procedure AfterImportData(Container) Export
	
	If Common.SubsystemExists("OnlineUserSupport.EnableMaintenanceServices") Then
		ModuleMaintenanceServicesActivation = Common.CommonModule("EnableMaintenanceServices");
		ModuleMaintenanceServicesActivation.AfterImportData(Container);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.WorkingWithCounterparties") Then
		ModuleCounterpartiesFunctions = Common.CommonModule("WorkingWithCounterparties");
		ModuleCounterpartiesFunctions.AfterImportData(Container);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		ModuleSPARKRisks = Common.CommonModule("SparkRisks");
		ModuleSPARKRisks.AfterImportData(Container);
	EndIf;
	
EndProcedure

#EndRegion

#Region JobsQueue

// See JobsQueueOverridable.OnGetTemplateList.
//
Procedure OnGetTemplateList(Templates) Export
	
	If Common.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		ModuleSPARKRisks = Common.CommonModule("SparkRisks");
		ModuleSPARKRisks.OnGetTemplateList(Templates);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.News_") Then
		ModuleNewsProcessingInternal = Common.CommonModule("ОбработкаНовостейСлужебный");
		ModuleNewsProcessingInternal.OnGetTemplateList(Templates);
	EndIf;
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases.
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	If Common.SubsystemExists("OnlineUserSupport.EnableMaintenanceServices") Then
		ModuleMaintenanceServicesActivation = Common.CommonModule("EnableMaintenanceServices");
		ModuleMaintenanceServicesActivation.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.WorkingWithCounterparties") Then
		ModuleCounterpartiesFunctions = Common.CommonModule("WorkingWithCounterparties");
		ModuleCounterpartiesFunctions.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		ModuleSPARKRisks = Common.CommonModule("SparkRisks");
		ModuleSPARKRisks.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		ModuleClassifiersOperations.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.InstantPayments.ARAPReconciliationWithEnterpriseAccountingc2b") Then
		ModuleARAPReconciliationWithEnterpriseAccountingc2b = Common.CommonModule("ARAPReconciliationWithEnterpriseAccountingc2b");
		ModuleARAPReconciliationWithEnterpriseAccountingc2b.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.InstantPayments.FPSc2bTransfers") Then
		ModuleFPSc2bTransfersInternal = Common.CommonModule("FPSc2bTransfersInternal");
		ModuleFPSc2bTransfersInternal.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;
		
	If Common.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		ModuleOnlinePayment = Common.CommonModule("OnlinePayment");
		ModuleOnlinePayment.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.News_") Then
		ModuleNewsProcessingInternal = Common.CommonModule("ОбработкаНовостейСлужебный");
		ModuleNewsProcessingInternal.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.PortalMonitor1CITS") Then
		ModuleOneCITSPortalDashboard = Common.CommonModule("PortalMonitor1CITS");
		ModuleOneCITSPortalDashboard.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;
	
EndProcedure

#EndRegion

#Region SuppliedData

// See SuppliedDataOverridable.GetHandlersForSuppliedData.
//
Procedure OnDefineSuppliedDataHandlers(Handlers) Export
	
	If Common.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		Handler = Handlers.Add();
		Handler.DataKind      = "SPARK1CRisksMonitoringEventTypes";
		Handler.HandlerCode = "SPARK1CRisksMonitoringEventTypes";
		Handler.Handler     = Common.CommonModule("SparkRisks");
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		ModuleClassifiersOperations.OnDefineSuppliedDataHandlers(Handlers);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		ModuleGetAddIns = Common.CommonModule("GetAddIns");
		ModuleGetAddIns.OnDefineSuppliedDataHandlers(Handlers);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		ModuleGetApplicationUpdates = Common.CommonModule("GetApplicationUpdates");
		ModuleGetApplicationUpdates.OnDefineSuppliedDataHandlers(Handlers);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.InstantPayments.BasicFPSFeatures") Then
		ModuleFasterPaymentSystemInternal = Common.CommonModule("InstantPaymentsInternal");
		ModuleFasterPaymentSystemInternal.OnDefineSuppliedDataHandlers(Handlers);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.GettingStatutoryReports") Then
		StatutoryReportsGetterModule = Common.CommonModule("GettingStatutoryReports");
		StatutoryReportsGetterModule.OnDefineSuppliedDataHandlers(Handlers);
	EndIf;
	
EndProcedure

#EndRegion

#Region Tariffication

// See TarifficationOverridable.OnCreateServicesList.
//
Procedure OnCreateServicesList(ServiceProviders) Export
	
	Services = New Array;
	
	If Common.SubsystemExists("OnlineUserSupport.WorkingWithCounterparties") Then
		ModuleCounterpartiesFunctions = Common.CommonModule("WorkingWithCounterparties");
		ModuleCounterpartiesFunctions.OnCreateServicesList(Services);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		ModuleSPARKRisks = Common.CommonModule("SparkRisks");
		ModuleSPARKRisks.OnCreateServicesList(Services);
	EndIf;
	
	If Services.Count() > 0 Then
		// Supplier adds it only if there are services.
		Supplier1CITSPortal = ServiceSupplier1CITSPortalOnGenerateServicesList(
			ServiceProviders);
		CommonClientServer.SupplementArray(Supplier1CITSPortal.Services, Services);
	EndIf;
	
EndProcedure

#EndRegion

// End SaaSTechnology.Core

#EndRegion

#EndRegion

#Region Internal

#Region Core

// See OnlineUserSupportOverridable.OnDefineConfigurationInterfaceLanguageCode.
//
Procedure OnDefineConfigurationInterfaceLanguageCode(LanguageCode, LanguageCodeInISO6391Format) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineConfigurationInterfaceLanguageCode Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineConfigurationInterfaceLanguageCode(LanguageCode, LanguageCodeInISO6391Format);
	EndIf;
	
EndProcedure

// See OnlineUserSupportOverridable.OnChangeOnlineSupportAuthenticationData.
//
Procedure OnChangeOnlineSupportAuthenticationData(UserData) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnChangeOnlineSupportAuthenticationData Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnChangeOnlineSupportAuthenticationData(UserData);
	EndIf;
	
EndProcedure

// See OnlineUserSupportOverridable.WhenDeterminingTheVersionNumberOfTheProgram.
//
Procedure WhenDeterminingTheVersionNumberOfTheProgram(ApplicationVersion) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().WhenDeterminingTheVersionNumberOfTheProgram Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.WhenDeterminingTheVersionNumberOfTheProgram(ApplicationVersion);
	EndIf;
	
EndProcedure

#EndRegion

#Region BasicFPSFeatures

// See "InstantPaymentsOverridable.OnDefineConnectionSettings".
//
Procedure OnDefineConnectionSettings(Settings) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineConnectionSettings Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineConnectionSettings(
			Settings);
	EndIf;
	
EndProcedure

// See "InstantPaymentsOverridable.OnWriteConnectionSettings".
//
Procedure OnWriteConnectionSettings(PaymentParameters, Cancel, ErrorMessage) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnWriteConnectionSettings Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnWriteConnectionSettings(
			PaymentParameters,
			Cancel,
			ErrorMessage);
	EndIf;
	
EndProcedure

// See "InstantPaymentsOverridable.OnSetupConnectionFormItems".
//
Procedure OnSetupConnectionFormItems(
		FormSettings,
		AdditionalParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnSetupConnectionFormItems Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnSetupConnectionFormItems(
			FormSettings,
			AdditionalParameters);
	EndIf;
	
EndProcedure

// See "InstantPaymentsOverridable.OnFillConnectionSettingsForm".
//
Procedure OnFillConnectionSettingsForm(Settings, AdditionalParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnFillConnectionSettingsForm Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnFillConnectionSettingsForm(
			Settings,
			AdditionalParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region FPSc2bTransfers

// See "FPSc2bTransfersOverridable.OnGenerateFPSPaymentOrder".
//
Procedure WhenFormingAnOrderForPaymentOfSBP(
		DocumentPayments,
		OrderForPayment,
		ConnectionSetup,
		AdditionalParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().WhenFormingAnOrderForPaymentOfSBP Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.WhenFormingAnOrderForPaymentOfSBP(
			DocumentPayments,
			OrderForPayment,
			ConnectionSetup,
			AdditionalParameters);
	EndIf;
	
EndProcedure

// See "FPSc2bTransfersOverridable.OnGeneratePartialPaymentOrderFPS".
//
Procedure OnGeneratePartialPaymentOrderFPS(
		DocumentPayments,
		OrderForPayment,
		ConnectionSetup,
		AdditionalParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnGeneratePartialPaymentOrderFPS Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnGeneratePartialPaymentOrderFPS(
			DocumentPayments,
			OrderForPayment,
			ConnectionSetup,
			AdditionalParameters);
	EndIf;
	
EndProcedure

// See "FPSc2bTransfersOverridable.OnGenerateFPSReturnOrder".
//
Procedure WhenFormingAnOrderForTheReturnOfTheSBP(
		DocumentReturnPolicy,
		RefundOrder,
		ConnectionSetup,
		AdditionalParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().WhenFormingAnOrderForTheReturnOfTheSBP Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.WhenFormingAnOrderForTheReturnOfTheSBP(
			DocumentReturnPolicy,
			RefundOrder,
			ConnectionSetup,
			AdditionalParameters);
	EndIf;
	
EndProcedure

// See "FPSc2bTransfersOverridable.OnImportingOperationStatus".
//
Procedure OnImportingOperationStatus(
		DocumentOperations,
		ConnectionSetup,
		ProcessingResult,
		Processed) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnImportingOperationStatus Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnImportingOperationStatus(
			DocumentOperations,
			ConnectionSetup,
			ProcessingResult,
			Processed);
	EndIf;
	
EndProcedure

// See "FPSc2bTransfersOverridable.OnDefiningOverriddenTemplatesOfFPSMessagesByTypes".
//
Procedure OnDefiningOverriddenTemplatesOfFPSMessagesByTypes(
		Templates) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefiningOverriddenTemplatesOfFPSMessagesByTypes Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefiningOverriddenTemplatesOfFPSMessagesByTypes(Templates);
	EndIf;
	
EndProcedure

// See "FPSc2bTransfersOverridable.OnCheckUsageOfFPSMessageTemplates".
//
Procedure OnCheckUsageOfFPSMessageTemplates(
		Used) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnCheckUsageOfFPSMessageTemplates Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnCheckUsageOfFPSMessageTemplates(Used);
	EndIf;
	
EndProcedure

// See "FPSc2bTransfersOverridable.OnDefineAvailableConnectionByOperationDocument".
//
Procedure OnDefineAvailableConnectionByOperationDocument(
		DocumentOperations,
		Result) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineAvailableConnectionByOperationDocument Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineAvailableConnectionByOperationDocument(
			DocumentOperations,
			Result);
	EndIf;
	
EndProcedure

// See "FPSc2bTransfersOverridable.OnDefiningObjectsWithFPSCommands".
//
Procedure OnDefiningObjectsWithFPSCommands(
		NamesOfOperationDocs) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefiningObjectsWithFPSCommands Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefiningObjectsWithFPSCommands(NamesOfOperationDocs);
	EndIf;
	
EndProcedure

// See "FPSc2bTransfersOverridable.OnDefineConnectionParametersForOperationDocument".
//
Procedure OnDefineConnectionParametersForOperationDocument(
		DocumentOperations,
		ConnectionSettings,
		AdditionalSettings,
		QuestionParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineConnectionParametersForOperationDocument Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineConnectionParametersForOperationDocument(
			DocumentOperations,
			ConnectionSettings,
			AdditionalSettings,
			QuestionParameters);
	EndIf;
	
EndProcedure

// See "FPSc2bTransfersOverridable.OnGenerateListOfFPSMessageRecipients".
//
Procedure OnGenerateListOfFPSMessageRecipients(
		PaymentPurpose,
		SendingOption,
		Recipients) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnGenerateListOfFPSMessageRecipients Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnGenerateListOfFPSMessageRecipients(
			PaymentPurpose,
			SendingOption,
			Recipients);
	EndIf;
		
EndProcedure

// See "FPSc2bTransfersOverridable.OnDefineFPSMessageSendParameters".
//
Procedure OnDefineFPSMessageSendingParameters(MessagesSendingParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineFPSMessageSendingParameters Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineFPSMessageSendingParameters(MessagesSendingParameters);
	EndIf;
	
EndProcedure

// See "FPSc2bTransfersOverridable.OnCreateQRCodeFormAtServer".
//
Procedure OnCreateQRCodeFormAtServer(
		Var_ThisObject,
		FormSettings,
		PaymentLinkData) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnCreateQRCodeFormAtServer Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnCreateQRCodeFormAtServer(
			Var_ThisObject,
			FormSettings,
			PaymentLinkData);
	EndIf;
	
EndProcedure

// See "IntegrationWithPaymentSystemsOverridable.OnCreateLinkAttachmentFormAtServer".
//
Procedure OnCreateLinkAttachmentFormAtServer(Var_ThisObject, Cancel) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnCreateLinkAttachmentFormAtServer Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnCreateLinkAttachmentFormAtServer(Var_ThisObject, Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region PortalMonitor1CITS

// See 1CITSPortalDashboardOverridable.OnDetermineCommonMonitorParameters.
//
Procedure WhenDeterminingTheGeneralParametersOfTheMonitor(MonitorParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().WhenDeterminingTheGeneralParametersOfTheMonitor Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.WhenDeterminingTheGeneralParametersOfTheMonitor(
			MonitorParameters);
	EndIf;
	
EndProcedure

// See 1CITSPortalDashboardOverridable.OnCreateMonitorForm.
//
Procedure WhenCreatingAMonitorForm(Form, CreationParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().WhenCreatingAMonitorForm Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.WhenCreatingAMonitorForm(
			Form,
			CreationParameters);
	EndIf;
	
EndProcedure

// See 1CITSPortalDashboardOverridable.BeforeGetMonitorData.
//
Procedure BeforeReceivingMonitorData(Form, ParametersForObtainingAdditionalData) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().BeforeReceivingMonitorData Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.BeforeReceivingMonitorData(
			Form,
			ParametersForObtainingAdditionalData);
	EndIf;
	
EndProcedure

// See 1CITSPortalDashboardOverridable.OnGetAdditionalMonitorData.
//
Procedure WhenReceivingAdditionalMonitorData(AdditionalData, ParametersForObtainingAdditionalData) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().WhenReceivingAdditionalMonitorData Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.WhenReceivingAdditionalMonitorData(
			AdditionalData,
			ParametersForObtainingAdditionalData);
	EndIf;
	
EndProcedure

// See OneCITSPortalDashboardOverridable.DisplayMonitorAdditionalData.
//
Procedure DisplayAdditionalMonitorData(Form, AdditionalData) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().DisplayAdditionalMonitorData Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.DisplayAdditionalMonitorData(
			Form,
			AdditionalData);
	EndIf;
	
EndProcedure

// See "OneCITSPortalDashboardOverridable.OnGenerateWarningTexts".
//
Procedure OnGenerateWarningTexts(ServiceData_, WarningsTexts) Export
	
	If Common.SubsystemExists("OnlineUserSupport.WorkingWithCounterparties") Then
		ModuleCounterpartiesFunctions = Common.CommonModule("WorkingWithCounterparties");
		ModuleCounterpartiesFunctions.OnGenerateWarningTexts(
			ServiceData_,
			WarningsTexts);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		ModuleSPARKRisks = Common.CommonModule("SparkRisks");
		ModuleSPARKRisks.OnGenerateWarningTexts(
			ServiceData_,
			WarningsTexts);
	EndIf;
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnGenerateWarningTexts Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnGenerateWarningTexts(
			ServiceData_,
			WarningsTexts);
	EndIf;
	
EndProcedure

// See "OneCITSPortalDashboardOverridable.OnFillServicesParameters".
//
Procedure OnFillServicesParameters(ServicesParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnFillServicesParameters Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnFillServicesParameters(
			ServicesParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region ApplicationSettings

// See AppSettingsOSLClientOverridable.OnCreateFormOnlineSupportAndServices.
//
Procedure OnCreateFormOnlineSupportAndServices(Form) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnCreateFormOnlineSupportAndServices Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnCreateFormOnlineSupportAndServices(Form);
	EndIf;
	
EndProcedure

#EndRegion

#Region OnlinePayment

// See "OnlinePaymentOverridable.OnDefineOnlinePaymentAdditionalSettings"
//
Procedure OnDefineOnlinePaymentAdditionalSettings(AdditionalSettings) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineOnlinePaymentAdditionalSettings Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineOnlinePaymentAdditionalSettings(AdditionalSettings);
	EndIf;
	
EndProcedure

// See "OnlinePaymentOverridable.OnCreateOnlinePaymentsForm"
//
Procedure OnCreateOnlinePaymentsForm(Form, Group, Prefix, AdditionalSettings) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnCreateOnlinePaymentsForm Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnCreateOnlinePaymentsForm(Form, Group, Prefix, AdditionalSettings);
	EndIf;
	
EndProcedure

// See "OnlinePaymentOverridable.BeforeStartEditAdditionalSettingsOfOnlinePayment".
//
Procedure BeforeStartEditAdditionalSettingsOfOnlinePayment(Context, Cancel = False) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().BeforeStartEditAdditionalSettingsOfOnlinePayment Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.BeforeStartEditAdditionalSettingsOfOnlinePayment(Context, Cancel);
	EndIf;
	
EndProcedure

// See "OnlinePaymentOverridable.BeforeEndEditingAdditionalSettingsOfOnlinePayments".
//
Procedure BeforeEndEditingAdditionalSettingsOfOnlinePayments(Context, Cancel = False) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().BeforeEndEditingAdditionalSettingsOfOnlinePayments Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.BeforeEndEditingAdditionalSettingsOfOnlinePayments(Context, Cancel);
	EndIf;
	
EndProcedure

// See OnlinePaymentOverridable.MappingOfPaymentReasonAttributes
//
Procedure MappingOfPaymentReasonAttributes(MatchingBankDetails) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().MappingOfPaymentReasonAttributes Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.MappingOfPaymentReasonAttributes(MatchingBankDetails);
	EndIf;
	
EndProcedure

// See "OnlinePaymentOverridable.OnDefinePaymentReasons"
//
Procedure OnDefinePaymentReasons(PaymentBaseObjects) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefinePaymentReasons Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefinePaymentReasons(PaymentBaseObjects);
	EndIf;
	
EndProcedure

// See "OnlinePaymentOverridable.OnCheckingIfPaymentReasonFilled"
//
Procedure OnCheckingIfPaymentReasonFilled(Val PaymentPurpose, Cancel) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnCheckingIfPaymentReasonFilled Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnCheckingIfPaymentReasonFilled(PaymentPurpose, Cancel);
	EndIf;
	
EndProcedure

// See "OnlinePaymentOverridable.FillInTheDetailsOfTheOrganization"
//
Procedure FillInTheDetailsOfTheOrganization(Val Organization, Attributes) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FillInTheDetailsOfTheOrganization Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FillInTheDetailsOfTheOrganization(Organization, Attributes);
	EndIf;
	
EndProcedure

// See "OnlinePaymentOverridable.SingleCompanyUsed"
//
Procedure SingleCompanyUsed(Result) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().SingleCompanyUsed Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.SingleCompanyUsed(Result);
	EndIf;
	
EndProcedure

// See "OnlinePaymentOverridable.NameOfAppliedCompanyCatalog"
//
Procedure NameOfAppliedCompanyCatalog(NameOfApplicationCatalog) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().NameOfAppliedCompanyCatalog Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.NameOfAppliedCompanyCatalog(NameOfApplicationCatalog);
	EndIf;
	
EndProcedure

// See "OnlinePaymentOverridable.PopulatePaymentReasonData"
//
Procedure PopulatePaymentReasonData(Val PaymentPurpose, PaymentReasonData) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().PopulatePaymentReasonData Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.PopulatePaymentReasonData(PaymentPurpose, PaymentReasonData);
	EndIf;
	
EndProcedure

// See "OnlinePaymentOverridable.PopulatePaymentReasonContactInfo"
//
Procedure PopulatePaymentReasonContactInfo(Val PaymentPurpose, ContactInformation) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().PopulatePaymentReasonContactInfo Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.PopulatePaymentReasonContactInfo(PaymentPurpose, ContactInformation);
	EndIf;
	
EndProcedure

// See "OnlinePaymentOverridable.OnGenerateListOfMessageRecipients"
//
Procedure OnGenerateListOfMessageRecipients(Val PaymentPurpose, Val SendingOption, Recipients) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnGenerateListOfMessageRecipients Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnGenerateListOfMessageRecipients(PaymentPurpose, SendingOption, Recipients);
	EndIf;
	
EndProcedure

// See "OnlinePaymentOverridable.OnDefineOnlinePaymentMessageSendParameters"
//
Procedure OnDefineOnlinePaymentMessageSendParameters(MessagesSendingParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineOnlinePaymentMessageSendParameters Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineOnlinePaymentMessageSendParameters(MessagesSendingParameters);
	EndIf;
	
EndProcedure

// See "OnlinePaymentOverridable.OnImportOnlinePaymentTransactions".
//
Procedure OnImportOnlinePaymentTransactions(Val Operations, Result, Cancel) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnImportOnlinePaymentTransactions Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnImportOnlinePaymentTransactions(Operations, Result, Cancel);
	EndIf;
	
EndProcedure

// See "OnlinePaymentOverridable.CheckIfOnlinePaymentMessageTemplatesUsed"
//
Procedure CheckIfOnlinePaymentMessageTemplatesUsed(Used) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().CheckIfOnlinePaymentMessageTemplatesUsed Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.CheckIfOnlinePaymentMessageTemplatesUsed(Used);
	EndIf;
	
EndProcedure

// See "OnlinePaymentOverridable.PredefinedTemplatesOfOnlinePaymentMessages".
//
Procedure PredefinedTemplatesOfOnlinePaymentMessages(Templates) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().PredefinedTemplatesOfOnlinePaymentMessages Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.PredefinedTemplatesOfOnlinePaymentMessages(Templates);
	EndIf;
	
EndProcedure

// See "OnlinePaymentOverridable.PredefinedTemplatesForOnlinePaymentMessagesByTypes".
//
Procedure PredefinedTemplatesForOnlinePaymentMessagesByTypes(Templates) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().PredefinedTemplatesForOnlinePaymentMessagesByTypes Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.PredefinedTemplatesForOnlinePaymentMessagesByTypes(Templates);
	EndIf;
	
EndProcedure

#EndRegion

#Region Connecting1CTaxi

// See Connect1CTaxcomOverridable.Use1CTaxcomService.
//
Procedure UseService1WithATax(Cancel) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().UseService1WithATax Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.UseService1WithATax(
			Cancel);
	EndIf;
	
EndProcedure

// See Connect1CTaxcomOverridable.FillCompanyRegistrationData.
//
Procedure FillInTheRegistrationDataOfTheCompany(Organization, ThisOrganization) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FillInTheRegistrationDataOfTheCompany Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FillInTheRegistrationDataOfTheCompany(
			Organization,
			ThisOrganization);
	EndIf;
	
EndProcedure

#EndRegion

#Region EnableMaintenanceServices

// See "EnableMaintenanceServicesOverridable.OnDefineMaintenanceServices".
//
Procedure WhenDefiningSupportServices(ServiceModules) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().WhenDefiningSupportServices Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.WhenDefiningSupportServices(ServiceModules);
	EndIf;
	
EndProcedure

#EndRegion

#Region GetApplicationUpdates

// See GetApplicationUpdatesOverridable.OnDefineUpdatesGetParameters.
//
Procedure OnDefineUpdatesGetParameters(UpdatesGetParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineUpdatesGetParameters Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineUpdatesGetParameters(UpdatesGetParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region ClassifiersOperations

// See ClassifiersOperationsOverridable.OnAddClassifiers.
//
Procedure OnAddClassifiers(Classifiers) Export
	
	If Common.SubsystemExists("OnlineUserSupport.ДанныеНагрузкиИРентабельности") Then
		ModuleLoadandCostEfficiencyData = Common.CommonModule("ДанныеНагрузкиИРентабельности");
		ModuleLoadandCostEfficiencyData.OnAddClassifiers(Classifiers);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.PickName") Then
		ModuleNameHint = Common.CommonModule("PickName");
		ModuleNameHint.OnAddClassifiers(Classifiers);
	EndIf;
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnAddClassifiers Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnAddClassifiers(Classifiers);
	EndIf;
	
EndProcedure

// See ClassifiersOperationsOverridable.OnDefineInitialClassifierVersionNumber.
//
Procedure OnDefineInitialClassifierVersionNumber(Id, InitialVersionNumber) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineInitialClassifierVersionNumber Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineInitialClassifierVersionNumber(
			Id,
			InitialVersionNumber);
	EndIf;
	
EndProcedure

// See ClassifiersOperationsOverridable.OnImportClassifier.
//
Procedure OnImportClassifier(Id, Version, Address, Processed, AdditionalParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnImportClassifier Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnImportClassifier(
			Id,
			Version,
			Address,
			Processed,
			AdditionalParameters);
	EndIf;
		
	If Common.SubsystemExists("OnlineUserSupport.ДанныеНагрузкиИРентабельности") Then
		ModuleLoadandCostEfficiencyData = Common.CommonModule("ДанныеНагрузкиИРентабельности");
		ModuleLoadandCostEfficiencyData.OnImportClassifier(Id, Version, Address, Processed);
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.PickName") Then
		ModuleNameHint = Common.CommonModule("PickName");
		ModuleNameHint.OnImportClassifier(Id, Version, Address, Processed);
	EndIf;
	
EndProcedure

// See ClassifiersOperationsSaaSOverridable.OnProcessDataArea.
//
Procedure OnProcessDataArea(Id, Version, AdditionalParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnProcessDataArea Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnProcessDataArea(
			Id,
			Version,
			AdditionalParameters);
	EndIf;
	
EndProcedure

// See ClassifiersOperationsSaaSOverridable.OnDefineClassifiersIDs.
//
Procedure OnDefineClassifiersIDs(IDs) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineClassifiersIDs Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineClassifiersIDs(
			IDs);
	EndIf;
	
EndProcedure

#EndRegion

#Region GetAddIns

// See GetAddInsSaaSOverridable.OnDefineAddInsVersionsToUse.
//
Procedure OnDefineAddInsVersionsToUse(IDs) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineAddInsVersionsToUse Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineAddInsVersionsToUse(IDs);
	EndIf;
	
EndProcedure

#EndRegion

#Region ARAPReconciliationWithEnterpriseAccountingc2b

// See "ARAPReconciliationWithEnterpriseAccountingc2b.OnSetUpReconciliationStatement".
//
Procedure OnSetUpReconciliationStatement(Settings) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnSetUpReconciliationStatement Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnSetUpReconciliationStatement(
			Settings);
	EndIf;
	
EndProcedure

// See "ARAPReconciliationWithEnterpriseAccountingc2b.OnDefineTurnovers".
//
Procedure OnDefineTurnovers(PaymentDocuments, Integration, Turnovers) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineTurnovers Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineTurnovers(
			PaymentDocuments,
			Integration,
			Turnovers);
	EndIf;
	
EndProcedure

// See "ARAPReconciliationWithEnterpriseAccountingc2b.OnWriteOff".
//
Procedure OnWriteOff(ExpensesWriteOffParameters, DocumentWriteOffs) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnWriteOff Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnWriteOff(
			ExpensesWriteOffParameters,
			DocumentWriteOffs);
	EndIf;
	
EndProcedure

// See "ARAPReconciliationWithEnterpriseAccountingc2b.OnDefineOperationData".
//
Procedure OnDefineOperationData(
		PaymentDocs,
		Integration,
		OperationData_) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineOperationData Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineOperationData(
			PaymentDocs,
			Integration,
			OperationData_);
	EndIf;
	
EndProcedure

#EndRegion

#Region SparkRisks

// See SPARKRisksOverridable.OnDetermineCounterpartiesCatalogsProperties.
//
Procedure WhenDeterminingThePropertiesOfCounterpartyDirectories(PropertiesOfDirectories) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().WhenDeterminingThePropertiesOfCounterpartyDirectories Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.WhenDeterminingThePropertiesOfCounterpartyDirectories(PropertiesOfDirectories);
	EndIf;
	
EndProcedure

// See SPARKRisksOverridable.CounterpartiesToMonitor.
//
Procedure CounterpartiesForMonitoring(PutOnMonitoring, RemoveFromMonitoring) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().CounterpartiesForMonitoring Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.CounterpartiesForMonitoring(
			PutOnMonitoring,
			RemoveFromMonitoring);
	EndIf;
	
EndProcedure

// See SPARKRisksOverridable.ReportsDisplayParameters.
//
Procedure ReportDisplayOptions(DisplayParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().ReportDisplayOptions Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.ReportDisplayOptions(DisplayParameters);
	EndIf;
	
EndProcedure

// See SPARKRisksOverridable.OnCreateAtServer.
//
Procedure WhenCreatingOnTheSPARKServer(
		Form,
		CounterpartyObject,
		Counterparty,
		CounterpartyKind,
		DisplayParameters,
		UsageIsAllowed,
		StandardLibraryProcessing) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().WhenCreatingOnTheSPARKServer Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.WhenCreatingOnTheSPARKServer(
			Form,
			CounterpartyObject,
			Counterparty,
			CounterpartyKind,
			DisplayParameters,
			UsageIsAllowed,
			StandardLibraryProcessing);
	EndIf;

EndProcedure

// See SPARKRisksOverridable.BackgroundJobTimeout.
//
Procedure WaitingTimeForABackgroundTask(WaitCompletion) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().WaitingTimeForABackgroundTask Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.WaitingTimeForABackgroundTask(WaitCompletion);
	EndIf;
	
EndProcedure

// See SPARKRisksOverridable.OnGenerateReportInputVATReliability.
//
Procedure WhenGeneratingTheIncomingVATReliabilityReport(
		TempTablesManager,
		FilterParameters,
		Use) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().WhenGeneratingTheIncomingVATReliabilityReport Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.WhenGeneratingTheIncomingVATReliabilityReport(
			TempTablesManager,
			FilterParameters,
			Use);
	EndIf;
	
EndProcedure

// See SPARKRisksOverridable.OnGenerateDebtorsReliability.
//
Procedure WhenFormingTheReliabilityOfDebtors(
		TempTablesManager,
		FilterParameters,
		Use) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().WhenFormingTheReliabilityOfDebtors Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.WhenFormingTheReliabilityOfDebtors(
			TempTablesManager,
			FilterParameters,
			Use);
	EndIf;
	
EndProcedure

// See SPARKRisksOverridable.InitialDataFillingParametersLegalEntities1SPARKRisks.
//
Procedure ParametersOfInitialDataFilling1SPARKRisksOfLegalEntities(
		FillParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().ParametersOfInitialDataFilling1SPARKRisksOfLegalEntities Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.ParametersOfInitialDataFilling1SPARKRisksOfLegalEntities(
			FillParameters);
	EndIf;
	
EndProcedure

// See SPARKRisksOverridable.InitialDataFillingParametersIndividualEntrepreneurs1SPARKRisks.
//
Procedure ParametersOfInitialDataFilling1SPARKRisksOfIndividualEntrepreneurs(
		FillParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().ParametersOfInitialDataFilling1SPARKRisksOfIndividualEntrepreneurs Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.ParametersOfInitialDataFilling1SPARKRisksOfIndividualEntrepreneurs(
			FillParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region GettingStatutoryReports

// See "GettingStatutoryReportsOverridable.OnAddStatutoryReportKinds".
//
Procedure OnAddStatutoryReportKinds(ReportsKinds, AdditionalParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnAddStatutoryReportKinds Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnAddStatutoryReportKinds(
			ReportsKinds, 
			AdditionalParameters);
	EndIf;
	
EndProcedure

// See "GettingStatutoryReportsOverridable.OnImportStatutoryReport".
//
Procedure OnImportStatutoryReport(FileDetails, Processed, AdditionalParameters) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OnImportStatutoryReport Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnImportStatutoryReport(
			FileDetails,
			Processed,
			AdditionalParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region News_

// See "NewsProcessingOverridable.FurtherProcessClassifierAfterReceivedAfterWritten"
//
Procedure FurtherProcessClassifierAfterReceivedAfterWritten(ClassifierRef) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FurtherProcessClassifierAfterReceivedAfterWritten Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FurtherProcessClassifierAfterReceivedAfterWritten(ClassifierRef);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.FurtherProcessContextNewsArray"
//
Procedure FurtherProcessContextNewsArray(
			Val MetadataIdentifier,
			Val FormIdentifier,
			Val EventsIDsOnOpen,
			NewsStructuresArray) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FurtherProcessContextNewsArray Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FurtherProcessContextNewsArray(
			MetadataIdentifier,
			FormIdentifier,
			EventsIDsOnOpen,
			NewsStructuresArray);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.FurtherProcessNewsAfterReceived"
//
Procedure FurtherProcessNewsAfterReceived(TableOfNewsImportDatesBeforeReceived) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FurtherProcessNewsAfterReceived Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FurtherProcessNewsAfterReceived(TableOfNewsImportDatesBeforeReceived);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.FurtherProcessNewsItemAfter ReceivedBeforeWrite"
//
Procedure FurtherProcessNewsItemAfterReceivedBeforeWrite(NewsObject, NewsItemXDTO) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FurtherProcessNewsItemAfterReceivedBeforeWrite Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FurtherProcessNewsItemAfterReceivedBeforeWrite(NewsObject, NewsItemXDTO);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.FurtherProcessNewsItemAfterReceivedAfterWritten"
//
Procedure FurtherProcessNewsItemAfterReceivedAfterWritten(NewsItemRef) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FurtherProcessNewsItemAfterReceivedAfterWritten Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FurtherProcessNewsItemAfterReceivedAfterWritten(NewsItemRef);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.FurtherProcessContextNewsTable"
//
Procedure FurtherProcessContextNewsTable(
			Val MetadataIdentifier,
			Val FormIdentifier,
			Val EventsIDsOnOpen,
			ContextNewsTable) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FurtherProcessContextNewsTable Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FurtherProcessContextNewsTable(
			MetadataIdentifier,
			FormIdentifier,
			EventsIDsOnOpen,
			ContextNewsTable);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.FurtherProcessNewsItemTextBeforeShow"
//
Procedure FurtherProcessNewsItemTextBeforeShow(NewsObject, TextHTML) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FurtherProcessNewsItemTextBeforeShow Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FurtherProcessNewsItemTextBeforeShow(NewsObject, TextHTML);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.FurtherProcessNewsListTextBeforeShow"
//
Procedure FurtherProcessNewsListTextBeforeShow(TextHTML) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FurtherProcessNewsListTextBeforeShow Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FurtherProcessNewsListTextBeforeShow(TextHTML);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.FurtherProcessContextNewsFormOnCreateAtServer"
//
Procedure FurtherProcessContextNewsFormOnCreateAtServer(
			Form,
			Cancel,
			StandardProcessing) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FurtherProcessContextNewsFormOnCreateAtServer Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FurtherProcessContextNewsFormOnCreateAtServer(
			Form,
			Cancel,
			StandardProcessing);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.FurtherProcessNewsItemFormOnCreateAtServer"
//
Procedure FurtherProcessNewsItemFormOnCreateAtServer(Form, Cancel, StandardProcessing) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FurtherProcessNewsItemFormOnCreateAtServer Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FurtherProcessNewsItemFormOnCreateAtServer(Form, Cancel, StandardProcessing);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.FurtherProcessCriticalNewsFormOnCreateAtServer"
//
Procedure FurtherProcessCriticalNewsFormOnCreateAtServer(
			Form,
			Cancel,
			StandardProcessing) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FurtherProcessCriticalNewsFormOnCreateAtServer Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FurtherProcessCriticalNewsFormOnCreateAtServer(
			Form,
			Cancel,
			StandardProcessing);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.FurtherProcessFormOnCreateAtServer"
//
Procedure FurtherProcessFormOnCreateAtServer(
			Form,
			SettingsForPopulatingWithNews,
			EventsIDsOnOpen,
			CreatedNewsButtonOrSubmenu,
			NewsStructuresArray) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FurtherProcessFormOnCreateAtServer Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FurtherProcessFormOnCreateAtServer(
			Form,
			SettingsForPopulatingWithNews,
			EventsIDsOnOpen,
			CreatedNewsButtonOrSubmenu,
			NewsStructuresArray);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.FurtherProcessDesktopNewsViewFormOnCreateAtServer"
//
Procedure FurtherProcessDesktopNewsViewFormOnCreateAtServer(
			Form,
			ReturnValues) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FurtherProcessDesktopNewsViewFormOnCreateAtServer Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FurtherProcessDesktopNewsViewFormOnCreateAtServer(
			Form,
			ReturnValues);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.FurtherProcessNewsViewFormOnCreateAtServer"
//
Procedure FurtherProcessNewsViewFormOnCreateAtServer(
			Form,
			Cancel,
			StandardProcessing) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FurtherProcessNewsViewFormOnCreateAtServer Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FurtherProcessNewsViewFormOnCreateAtServer(
			Form,
			Cancel,
			StandardProcessing);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.FurtherPrepareURLParameters"
//
Procedure FurtherPrepareURLParameters(
			Val Object,
			ActionUUID,
			Action,
			ParametersList) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FurtherPrepareURLParameters Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FurtherPrepareURLParameters(
			Object,
			ActionUUID,
			Action,
			ParametersList);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.ApplyFollowUpConditionalFormattingToContextNewsForm"
//
Procedure ApplyFollowUpConditionalFormattingToContextNewsForm(
			ContextNewsForm,
			ConditionalFormDesign) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().ApplyFollowUpConditionalFormattingToContextNewsForm Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.ApplyFollowUpConditionalFormattingToContextNewsForm(
			ContextNewsForm,
			ConditionalFormDesign);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.FillInteractiveActionsAfterNewsReceived"
//
Procedure FillInteractiveActionsAfterNewsReceived(
			NewsTable,
			User,
			Filter,
			InteractiveActions) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FillInteractiveActionsAfterNewsReceived Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FillInteractiveActionsAfterNewsReceived(
			NewsTable,
			User,
			Filter,
			InteractiveActions);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.FillCategoryCodesForAutoFilteringNews"
//
Procedure FillCategoryCodesForAutoFilteringNews(
			NewsCategoryCodes,
			Scope = "Common",
			ContextUsedToPerformCheck = Undefined) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().FillCategoryCodesForAutoFilteringNews Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.FillCategoryCodesForAutoFilteringNews(
			NewsCategoryCodes,
			Scope,
			ContextUsedToPerformCheck);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.PredefinedCategoryValue"
//
Procedure PredefinedCategoryValue(Category, Value) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().PredefinedCategoryValue Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.PredefinedCategoryValue(Category, Value);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.ProcessUserRecord"
//
Procedure ProcessUserRecord(UserObject, IsNewUser, Cancel) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().ProcessUserRecord Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.ProcessUserRecord(UserObject, IsNewUser, Cancel);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.ContextNewsPanel_SelectNews"
//
Procedure ContextNewsPanel_SelectNews(
			Form,
			NewsTableForContextNewsPanel,
			StandardProcessing) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().ContextNewsPanel_SelectNews Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.ContextNewsPanel_SelectNews(
			Form,
			NewsTableForContextNewsPanel,
			StandardProcessing);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.OverrideActionsWhenInactiveNewsFeedFound"
//
Procedure OverrideActionsWhenInactiveNewsFeedFound(
			NewsFeed,
			NewsItemObject,
			Cancel) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OverrideActionsWhenInactiveNewsFeedFound Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OverrideActionsWhenInactiveNewsFeedFound(
			NewsFeed,
			NewsItemObject,
			Cancel);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.OverrideNewsItemStateResetOnWrite"
//
Procedure OverrideNewsItemStateResetOnWrite(Val ObjectNewsItem, ResetNewsItemState) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OverrideNewsItemStateResetOnWrite Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OverrideNewsItemStateResetOnWrite(ObjectNewsItem, ResetNewsItemState);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.OverrideNewsFeedListForContextNews"
//
Procedure OverrideNewsFeedListForContextNews(NewsFeedsList = Undefined) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().OverrideNewsFeedListForContextNews Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OverrideNewsFeedListForContextNews(NewsFeedsList);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.GetAdditionalStandardValuesForClassifiers"
//
Procedure GetAdditionalStandardValuesForClassifiers(
			MetadataObjectName,
			StandardValues) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().GetAdditionalStandardValuesForClassifiers Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.GetAdditionalStandardValuesForClassifiers(
			MetadataObjectName,
			StandardValues);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.GetAdditionalStandardValuesForNews"
//
Procedure GetAdditionalStandardValuesForNews(NewsFeed, StandardValues) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().GetAdditionalStandardValuesForNews Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.GetAdditionalStandardValuesForNews(NewsFeed, StandardValues);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.GetNewsWithReminders"
//
Procedure GetNewsWithReminders(
			NewsCritical,
			ImportantNews,
			AdditionalParameters,
			StandardProcessing) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().GetNewsWithReminders Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.GetNewsWithReminders(
			NewsCritical,
			ImportantNews,
			AdditionalParameters,
			StandardProcessing);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.AllowAutoCalculateCategoryValues"
//
Procedure AllowAutoCalculateCategoryValues(AutoCalculate) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().AllowAutoCalculateCategoryValues Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.AllowAutoCalculateCategoryValues(AutoCalculate);
	EndIf;

EndProcedure

// See "NewsProcessingOverridable.CalculateFilterByCategory"
//
Procedure CalculateFilterByCategory(
			NewsCategory,
			NewsCategoryCode,
			NewsCategoryValue,
			CalculationResult2,
			DataArea = Undefined,
			ContextUsedToPerformCheck = Undefined,
			StandardProcessing = True) Export

	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().CalculateFilterByCategory Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.CalculateFilterByCategory(
			NewsCategory,
			NewsCategoryCode,
			NewsCategoryValue,
			CalculationResult2,
			DataArea,
			ContextUsedToPerformCheck,
			StandardProcessing);
	EndIf;

EndProcedure

#EndRegion

#Region FDO

// See "FiscalDataOperatorOverridable.OnDetermineIntegrationSettings".
//
Procedure WhenDefiningIntegrationSettings(Settings) Export
	
	If OSLSubsystemsIntegrationCached.SubscriptionsSSL().WhenDefiningIntegrationSettings Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.WhenDefiningIntegrationSettings(Settings);
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
	Events.Insert("OnDefineConfigurationInterfaceLanguageCode", False);
	Events.Insert("OnChangeOnlineSupportAuthenticationData", False);
	Events.Insert("WhenDeterminingTheVersionNumberOfTheProgram", False);
	
	// 1C:ITS Portal Dashboard
	Events.Insert("WhenDeterminingTheGeneralParametersOfTheMonitor", False);
	Events.Insert("WhenCreatingAMonitorForm", False);
	Events.Insert("BeforeReceivingMonitorData", False);
	Events.Insert("WhenReceivingAdditionalMonitorData", False);
	Events.Insert("DisplayAdditionalMonitorData", False);
	Events.Insert("OnGenerateWarningTexts", False);
	Events.Insert("OnFillServicesParameters", False);
	
	// Application settings
	Events.Insert("OnCreateFormOnlineSupportAndServices", False);
	
	// Online payments
	Events.Insert("OnDefineOnlinePaymentAdditionalSettings", False);
	Events.Insert("OnCreateOnlinePaymentsForm", False);
	Events.Insert("BeforeStartEditAdditionalSettingsOfOnlinePayment", False);
	Events.Insert("BeforeEndEditingAdditionalSettingsOfOnlinePayments", False);
	Events.Insert("MappingOfPaymentReasonAttributes", False);
	Events.Insert("OnDefinePaymentReasons", False);
	Events.Insert("OnCheckingIfPaymentReasonFilled", False);
	Events.Insert("FillInTheDetailsOfTheOrganization", False);
	Events.Insert("SingleCompanyUsed", False);
	Events.Insert("NameOfAppliedCompanyCatalog", False);
	Events.Insert("PopulatePaymentReasonData", False);
	Events.Insert("PopulatePaymentReasonContactInfo", False);
	Events.Insert("OnGenerateListOfMessageRecipients", False);
	Events.Insert("OnDefineOnlinePaymentMessageSendParameters", False);
	Events.Insert("OnImportOnlinePaymentTransactions", False);
	Events.Insert("CheckIfOnlinePaymentMessageTemplatesUsed", False);
	Events.Insert("PredefinedTemplatesOfOnlinePaymentMessages", False);
	Events.Insert("PredefinedTemplatesForOnlinePaymentMessagesByTypes", False);
	
	// Fiscal data operator
	Events.Insert("WhenDefiningIntegrationSettings", False);
	
	// Add productivity tools
	Events.Insert("WhenDefiningSupportServices", False);
	
	// Get application updates
	Events.Insert("OnDefineUpdatesGetParameters", False);
	
	// Classifiers
	Events.Insert("OnAddClassifiers", False);
	Events.Insert("OnDefineInitialClassifierVersionNumber", False);
	Events.Insert("OnImportClassifier", False);
	Events.Insert("OnProcessDataArea", False);
	Events.Insert("OnDefineClassifiersIDs", False);
	
	// Attach 1C-Taxcom.
	Events.Insert("UseService1WithATax", False);
	Events.Insert("FillInTheRegistrationDataOfTheCompany", False);
	
	// Get add-ins
	Events.Insert("OnDefineAddInsVersionsToUse", False);
	
	// Faster Payments System basic functionality
	Events.Insert("OnDefineConnectionSettings", False);
	Events.Insert("OnWriteConnectionSettings", False);
	Events.Insert("OnSetupConnectionFormItems", False);
	Events.Insert("OnFillConnectionSettingsForm", False);
	
	// FPS transfers (c2b)
	Events.Insert("WhenFormingAnOrderForPaymentOfSBP", False);
	Events.Insert("OnGeneratePartialPaymentOrderFPS", False);
	Events.Insert("WhenFormingAnOrderForTheReturnOfTheSBP", False);
	Events.Insert("OnImportingOperationStatus", False);
	Events.Insert("OnDefineAvailableConnectionByOperationDocument", False);
	Events.Insert("OnDefiningObjectsWithFPSCommands", False);
	Events.Insert("OnDefineConnectionParametersForOperationDocument", False);
	Events.Insert("OnGenerateListOfFPSMessageRecipients", False);
	Events.Insert("OnDefiningOverriddenTemplatesOfFPSMessagesByTypes", False);
	Events.Insert("OnCheckUsageOfFPSMessageTemplates", False);
	Events.Insert("OnCreateQRCodeFormAtServer", False);
	Events.Insert("OnDefineFPSMessageSendingParameters", False);
	Events.Insert("OnCreateLinkAttachmentFormAtServer", False);
	
	// FPS payments reconciliation (c2b)
	Events.Insert("OnSetUpReconciliationStatement", False);
	Events.Insert("OnDefineTurnovers", False);
	Events.Insert("OnWriteOff", False);
	Events.Insert("OnDefineOperationData", False);

	// SPARK Risks.
	Events.Insert("WhenDeterminingThePropertiesOfCounterpartyDirectories", False);
	Events.Insert("CounterpartiesForMonitoring", False);
	Events.Insert("ReportDisplayOptions", False);
	Events.Insert("WhenCreatingOnTheSPARKServer", False);
	Events.Insert("WaitingTimeForABackgroundTask", False);
	Events.Insert("WhenGeneratingTheIncomingVATReliabilityReport", False);
	Events.Insert("OnDefineAddInsVersionsToUse", False);
	Events.Insert("WhenFormingTheReliabilityOfDebtors", False);
	Events.Insert("ParametersOfInitialDataFilling1SPARKRisksOfLegalEntities", False);
	Events.Insert("ParametersOfInitialDataFilling1SPARKRisksOfIndividualEntrepreneurs", False);
	
	// Statutory report acquisition
	Events.Insert("OnAddStatutoryReportKinds", False);
	Events.Insert("OnImportStatutoryReport", False);
	
	// News (server)
	Events.Insert("FurtherProcessClassifierAfterReceivedAfterWritten", False);
	Events.Insert("FurtherProcessContextNewsArray", False);
	Events.Insert("FurtherProcessNewsAfterReceived", False);
	Events.Insert("FurtherProcessNewsItemAfterReceivedBeforeWrite", False);
	Events.Insert("FurtherProcessNewsItemAfterReceivedAfterWritten", False);
	Events.Insert("FurtherProcessContextNewsTable", False);
	Events.Insert("FurtherProcessNewsItemTextBeforeShow", False);
	Events.Insert("FurtherProcessNewsListTextBeforeShow", False);
	Events.Insert("FurtherProcessContextNewsFormOnCreateAtServer", False);
	Events.Insert("FurtherProcessNewsItemFormOnCreateAtServer", False);
	Events.Insert("FurtherProcessCriticalNewsFormOnCreateAtServer", False);
	Events.Insert("FurtherProcessFormOnCreateAtServer", False);
	Events.Insert("FurtherProcessDesktopNewsViewFormOnCreateAtServer", False);
	Events.Insert("FurtherProcessNewsViewFormOnCreateAtServer", False);
	Events.Insert("FurtherPrepareURLParameters", False);
	Events.Insert("ApplyFollowUpConditionalFormattingToContextNewsForm", False);
	Events.Insert("FillInteractiveActionsAfterNewsReceived", False);
	Events.Insert("FillCategoryCodesForAutoFilteringNews", False);
	Events.Insert("FillCategoriesProgramValues_ForDataAreas", False);
	Events.Insert("FillCategoriesProgramValues_Common", False);
	Events.Insert("PredefinedCategoryValue", False);
	Events.Insert("InfobaseUpdate_DataArea_InitialStartup", False);
	Events.Insert("InfobaseUpdate_DataArea_MigrateToVersion", False);
	Events.Insert("InfobaseUpdate_SharedData_InitialStartup", False);
	Events.Insert("InfobaseUpdate_SharedData_MigrateToVersion", False);
	Events.Insert("ProcessUserRecord", False);
	Events.Insert("ContextNewsPanel_SelectNews", False);
	Events.Insert("OverrideActionsWhenInactiveNewsFeedFound", False);
	Events.Insert("OverrideNewsItemStateResetOnWrite", False);
	Events.Insert("OverrideNewsFeedListForContextNews", False);
	Events.Insert("GetAdditionalStandardValuesForClassifiers", False);
	Events.Insert("GetAdditionalStandardValuesForNews", False);
	Events.Insert("GetNewsWithReminders", False);
	Events.Insert("OnStart", False);
	Events.Insert("OnMigrateFromAnotherApp", False);
	Events.Insert("AllowAutoCalculateCategoryValues", False);
	Events.Insert("CalculateFilterByCategory", False);
	
	Return Events;
	
EndFunction

// Returns 1C:ITS portal supplier details to fill in services
// in the TarifficationOverridable.OnGenerateServicesList method.
// The supplier is added to the supplier list.
//
// Parameters:
//	ServiceProviders - Array - an array of elements of the Structure type - supplier details.
//		See the parameter details in the OnGenerateServicesList procedure.
//
// Returns:
//	Structure - see the OnGenerateServicesList procedure
//		and the ServicesSuppliers parameter details.
//
// Example:
//	Used in the TarifficationOverridable.OnGenerateServicesList method.
//	Supplier1CITSPortal =
//		ServiceSupplier1CITSPortalOnGenerateServicesList(ServicesSuppliers);
//	NewService = New Structure;
//	NewService.Insert("ID", <Service ID>);
//	NewService.Insert("Description" , <Service description>);
//	NewService.Insert("ServiceType" , <Service type>);
//	Supplier1CITS.Services.Add(NewService);
//
Function ServiceSupplier1CITSPortalOnGenerateServicesList(ServiceProviders)
	
	ServiceProviderID1sitsPortal =
		OnlineUserSupportClientServer.ServiceProviderID1sitsPortal();
	For Each CurrentSupplier In ServiceProviders Do
		If CurrentSupplier.Id = ServiceProviderID1sitsPortal Then
			Return CurrentSupplier;
		EndIf;
	EndDo;
	
	// If a supplier is not in the list, adding a new supplier.
	Supplier1CITSPortal = New Structure;
	Supplier1CITSPortal.Insert("Id", ServiceProviderID1sitsPortal);
	Supplier1CITSPortal.Insert("Description" , NStr("ru = 'Портал 1С:ИТС';
														|en = '1C:ITS Portal';"));
	Supplier1CITSPortal.Insert("Services"       , New Array);
	ServiceProviders.Add(Supplier1CITSPortal);
	
	Return Supplier1CITSPortal;
	
EndFunction

#EndRegion