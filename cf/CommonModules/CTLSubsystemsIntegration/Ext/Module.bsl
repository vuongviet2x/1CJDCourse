#Region Public

#Region EventHandlersSSL
// Handle software events that occur in SSL subsystems.
// Intended only for calls from SSL to CTL.

// Defines events, to which this library is subscribed.
//
// Parameters:
//  Subscriptions - Structure - Structure's property keys are names of events,
//           to which this library is subscribed.
//
Procedure OnDefineEventSubscriptionsSSL(Subscriptions) Export

    // Core
	Subscriptions.OnAddSessionParameterSettingHandlers = True;
	Subscriptions.OnAddReferenceSearchExceptions = True;
	Subscriptions.OnSendDataToMaster = True;
	Subscriptions.OnSendDataToSlave = True;
	Subscriptions.OnReceiveDataFromMaster = True;
	Subscriptions.OnReceiveDataFromSlave = True;
	Subscriptions.OnEnableSeparationByDataAreas = True;
	Subscriptions.OnDefineSupportedInterfaceVersions = True;
	Subscriptions.OnAddClientParametersOnStart = True;
	Subscriptions.OnAddClientParameters = True;
	Subscriptions.OnAddSubsystems = True;

	// BatchObjectsModification
	Subscriptions.OnDefineObjectsWithEditableAttributes = True;

	// AdditionalReportsAndDataProcessors
	Subscriptions.OnSetAdditionalReportOrDataProcessorAttachmentModeInDataArea = True;

	// ImportDataFromFile
	Subscriptions.OnDefineCatalogsForDataImport = True;

	// ODataInterface
	Subscriptions.OnFillTypesExcludedFromExportImportOData = True;

	// Users
	Subscriptions.OnEndIBUserProcessing = True;

	// SecurityProfiles
	Subscriptions.OnCheckCanSetupSecurityProfiles = True;
	Subscriptions.OnRequestPermissionsToUseExternalResources = True;
	Subscriptions.OnRequestToCreateSecurityProfile = True;
	Subscriptions.OnRequestToDeleteSecurityProfile = True;
	Subscriptions.OnAttachExternalModule = True;

	// ScheduledJobs
	Subscriptions.OnDefineScheduledJobSettings = True;
	
	// AccessManagement
	Subscriptions.OnFillSuppliedAccessGroupProfiles = True;
	
	Subscriptions.OnGetUpdatePriority = True;
	
	Subscriptions.BeforeStartApplication = True;
	
EndProcedure

#Region Core

// See CommonOverridable.BeforeStartApplication
Procedure BeforeStartApplication() Export
	
	CheckCanRunProgram();

	If Common.SubsystemExists("CloudTechnology.DataAreasBackup") Then
		ModuleDataAreaBackup = Common.CommonModule("DataAreasBackup");
		ModuleDataAreaBackup.SetUserActivityFlagInArea();
	EndIf;
	
	SaaSOperations.SetUserActivityFlagInArea();

EndProcedure

// See ConfigurationSubsystemsOverridable.OnAddSubsystems
// 
// Parameters:
// 	SubsystemsModules - Array of String - Module names.
Procedure OnAddSubsystems(SubsystemsModules) Export

	SubsystemsModules.Add("InfobaseUpdateCTL");

EndProcedure

// See CommonOverridable.OnAddSessionParameterSettingHandlers.
Procedure OnAddSessionParameterSettingHandlers(Handlers) Export
	
	Handlers.Insert("SecurityTokens", "DigitalSignatureSaaS.SessionParametersSetting");
	
EndProcedure

// See CommonOverridable.OnAddReferenceSearchExceptions
Procedure OnAddReferenceSearchExceptions(RefSearchExclusions) Export

	AdditionalReportsAndDataProcessorsSaaS.OnAddReferenceSearchExceptions(RefSearchExclusions);
	ExtensionsSaaS.OnAddReferenceSearchExceptions(RefSearchExclusions);

EndProcedure

// See OnSendDataToMaster
// in Syntax Assistant
Procedure OnSendDataToMaster(DataElement, ItemSend,
		Recipient) Export

	AdditionalReportsAndDataProcessorsStandaloneMode.OnSendDataToMaster(DataElement, ItemSend, Recipient);

EndProcedure

// See OnSendDataToSlave
// in Syntax Assistant
Procedure OnSendDataToSlave(DataElement, ItemSend,
		InitialImageCreating, Recipient) Export

	AdditionalReportsAndDataProcessorsStandaloneMode.OnSendDataToSlave(DataElement, ItemSend, InitialImageCreating, Recipient);

EndProcedure

// See OnReceiveDataFromMaster
// in Syntax Assistant
Procedure OnReceiveDataFromMaster(DataElement, ItemReceive,
		SendBack, Sender) Export

	AdditionalReportsAndDataProcessorsStandaloneMode.OnReceiveDataFromMaster(DataElement, ItemReceive, SendBack, Sender);

EndProcedure

// See OnReceiveDataFromSlave
// in Syntax Assistant
Procedure OnReceiveDataFromSlave(DataElement, ItemReceive,
		SendBack, Sender) Export

	AdditionalReportsAndDataProcessorsStandaloneMode.OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Sender);

EndProcedure

// See SaaSOperationsOverridable.OnEnableSeparationByDataAreas
Procedure OnEnableSeparationByDataAreas() Export

	JobsQueueInternal.OnEnableSeparationByDataAreas();
	JobsQueueInternalDataSeparation.OnEnableSeparationByDataAreas();
	SaaSOperations.OnEnableSeparationByDataAreas();
	CloudTechnology.OnEnableSeparationByDataAreas();
	SaaSOperationsCTL.OnEnableSeparationByDataAreas();

EndProcedure

// See CommonOverridable.OnDefineSupportedInterfaceVersions
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export

	If Common.SubsystemExists("CloudTechnology.InformationCenter") Then
		ModuleInformationCenterInternal = Common.CommonModule("InformationCenterInternal");
		ModuleInformationCenterInternal.OnDefineSupportedInterfaceVersions(SupportedVersionsStructure);
	EndIf;

	SafeModeManagerInternalSaaS.OnDefineSupportedInterfaceVersions(SupportedVersionsStructure);
	RemoteAdministrationCTLInternal.OnDefineSupportedInterfaceVersions(SupportedVersionsStructure);
	DigitalSignatureSaaS.OnDefineSupportedInterfaceVersions(SupportedVersionsStructure);

	If Common.SubsystemExists("CloudTechnology.DataTransfer") Then
		ModuleDataTransferInternal = Common.CommonModule("DataTransferInternal");
		ModuleDataTransferInternal.OnDefineSupportedInterfaceVersions(SupportedVersionsStructure);
	EndIf;

	MessageInterfacesSaaS.OnDefineSupportedInterfaceVersions(SupportedVersionsStructure);
	MessagesExchangeInner.OnDefineSupportedInterfaceVersions(SupportedVersionsStructure);
	DataAreasBackup.OnDefineSupportedInterfaceVersions(SupportedVersionsStructure);

	VersionsArray = CommonClientServer.ValueInArray("1.0.0.1");
	SupportedVersionsStructure.Insert("ImportDataIntoExistingArea", VersionsArray);
	
	If Common.SubsystemExists("CloudTechnology.SummaryApplications") Then
		ModuleSummaryApplications = Common.CommonModule("SummaryApplications");
		ModuleSummaryApplications.OnDefineSupportedInterfaceVersions(SupportedVersionsStructure);
	EndIf;
	
EndProcedure

// 
Procedure OnAddClientParametersOnStart(Parameters) Export

	SaaSOperations.OnAddClientParametersOnStart(Parameters);
	
	If Common.SubsystemExists("CloudTechnology.ServicePayment") Then
		ServicePaymentModule = Common.CommonModule("ServicePayment");
		ServicePaymentModule.OnAddClientParametersOnStart(Parameters);
	EndIf;
	
	ApplicationsMigration.OnAddClientParametersOnStart(Parameters);
	
	ExportImportDataInternal.OnAddClientParametersOnStart(Parameters);
	
EndProcedure

// 
Procedure OnAddClientParameters(Parameters) Export

	DigitalSignatureSaaS.OnAddClientParameters(Parameters);
	SaaSOperations.OnAddClientParameters(Parameters);
	DataAreasBackup.OnAddClientParameters(Parameters);

EndProcedure

#EndRegion

#Region BatchEditObjects

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export

	MessagesExchangeInner.OnDefineObjectsWithEditableAttributes(Objects);

EndProcedure

#EndRegion

#Region AdditionalReportsAndDataProcessors

// Deprecated.
Procedure OnSetAdditionalReportOrDataProcessorAttachmentModeInDataArea(SuppliedDataProcessor,
		WorkMode) Export

	Return;

EndProcedure

#EndRegion

#Region ImportDataFromFile

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export

	JobsQueueInternal.OnDefineCatalogsForDataImport(CatalogsToImport);
	SaaSOperations.OnDefineCatalogsForDataImport(CatalogsToImport);
	
	If Common.SubsystemExists("CloudTechnology.UsersNotificationCTL") Then
		ModuleUsersNotificationCTL = Common.CommonModule("UsersNotificationCTL");
		ModuleUsersNotificationCTL.OnDefineCatalogsForDataImport(CatalogsToImport);
	EndIf;

EndProcedure

#EndRegion

#Region ODataInterface

// See SSLSubsystemsIntegration.OnFillTypesExcludedFromExportImportOData
Procedure OnFillTypesExcludedFromExportImportOData(Types) Export
	
	TypeDescriptions = New Array();
	
	If Common.SubsystemExists("CloudTechnology.Core") Then

		WorkInSafeModeServiceModuleInServiceModel = Common.CommonModule("SafeModeManagerInternalSaaS");
		WorkInSafeModeServiceModuleInServiceModel.OnFillTypesExcludedFromExportImport(TypeDescriptions);

		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		ModuleSaaSOperations.OnFillTypesExcludedFromExportImport(TypeDescriptions);

	EndIf;

	If Common.SubsystemExists("CloudTechnology.InformationCenter") Then
		ModuleInformationCenterInternal = Common.CommonModule("InformationCenterInternal");
		ModuleInformationCenterInternal.OnFillTypesExcludedFromExportImport(TypeDescriptions);
	EndIf;

	If Common.SubsystemExists("CloudTechnology.QualityControlCenter") Then
		ModuleQCCIncidentsServer = Common.CommonModule("QCCIncidentsServer");
		ModuleQCCIncidentsServer.OnFillTypesExcludedFromExportImport(TypeDescriptions);
	EndIf;

	If Common.SubsystemExists("CloudTechnology.TariffsManagement") Then
		ModuleTariffication = Common.CommonModule("Tariffication");
		ModuleTariffication.OnFillTypesExcludedFromExportImport(TypeDescriptions);
	EndIf;

	If Common.SubsystemExists("CloudTechnology.CheckingAndCorrectingData") Then
		ModuleCheckingAndCorrectingData = Common.CommonModule("CheckingAndCorrectingData");
		ModuleCheckingAndCorrectingData.OnFillTypesExcludedFromExportImport(TypeDescriptions);
	EndIf;

	If Common.SubsystemExists("CloudTechnology.ApplicationsMigration") Then
		ApplicationMigrationModule = Common.CommonModule("ApplicationsMigration");
		ApplicationMigrationModule.OnFillTypesExcludedFromExportImport(TypeDescriptions);
	EndIf;

	If Common.SubsystemExists("CloudTechnology.JobsQueueExternalInterface") Then
		TaskQueueModuleExternalInterface = Common.CommonModule("JobsQueueExternalInterface");
		TaskQueueModuleExternalInterface.OnFillTypesExcludedFromExportImport(TypeDescriptions);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.DataAreasObjectsIntegration") Then
		ModuleIntegrationOfDataDomainObjects = Common.CommonModule("DataAreasObjectsIntegration");
		ModuleIntegrationOfDataDomainObjects.OnFillTypesExcludedFromExportImport(TypeDescriptions);
	EndIf;

	If Common.SubsystemExists("CloudTechnology.MessagesExchange") Then
		ModuleMessagesExchangeInternal = Common.CommonModule("MessagesExchangeInner");
		ModuleMessagesExchangeInternal.OnFillTypesExcludedFromExportImport(TypeDescriptions);
	EndIf;

	If Common.SubsystemExists("CloudTechnology.JobsQueue") Then
		ModuleJobQueueInternalDataSeparation = Common.CommonModule("JobsQueueInternalDataSeparation");
		ModuleJobQueueInternalDataSeparation.OnFillTypesExcludedFromExportImport(TypeDescriptions);
	EndIf;

	If Common.SubsystemExists("CloudTechnology.DataAreasBackup") Then
		ModuleDataAreaBackup = Common.CommonModule("DataAreasBackup");
		ModuleDataAreaBackup.OnFillTypesExcludedFromExportImport(TypeDescriptions);
	EndIf;

	If Common.SubsystemExists("CloudTechnology.ExportImportData") Then
		ModuleExportImportDataOverridable = Common.CommonModule("ExportImportDataOverridable");
		ModuleExportImportDataOverridable.OnFillTypesExcludedFromExportImport(TypeDescriptions);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.SuppliedData") Then
		ModuleSuppliedData = Common.CommonModule("SuppliedData");
		ModuleSuppliedData.OnFillTypesExcludedFromExportImport(TypeDescriptions);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.ExtensionsSaaS") Then
		ModuleExtensionsSaaS = Common.CommonModule("ExtensionsSaaS");
		ModuleExtensionsSaaS.OnFillTypesExcludedFromExportImport(TypeDescriptions);
	EndIf;

	If Common.SubsystemExists("CloudTechnology.DataAreasFiles") Then
		ModuleDataAreaFiles = Common.CommonModule("DataAreasFiles");
		ModuleDataAreaFiles.OnFillTypesExcludedFromExportImport(TypeDescriptions);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.UsersNotificationCTL") Then
		ModuleUsersNotificationCTL = Common.CommonModule("UsersNotificationCTL");
		ModuleUsersNotificationCTL.OnFillTypesExcludedFromExportImport(TypeDescriptions);
	EndIf;

	CommonClientServer.SupplementArray(
		Types,
		ExportImportDataInternalEvents.TypesFromTypeDescriptions(TypeDescriptions));
	
EndProcedure

#EndRegion

#Region Users

// See UsersInternalSaaS.OnEndIBUserProcessing
Procedure OnEndIBUserProcessing(User) Export

	SaaSOperationsOverridable.SetDefaultRights(User);

EndProcedure

#EndRegion

#Region SecurityProfiles

// See SafeModeManagerOverridable.OnCheckCanSetupSecurityProfiles
Procedure OnCheckCanSetupSecurityProfiles(Cancel) Export

	SafeModeManagerInternalSaaS.OnCheckCanSetupSecurityProfiles(Cancel);

EndProcedure

// See SafeModeManagerOverridable.OnRequestPermissionsToUseExternalResources
Procedure OnRequestPermissionsToUseExternalResources(Val ProgramModule,
		Val Owner, Val ReplacementMode, Val PermissionsToAdd,
		Val PermissionsToDelete, StandardProcessing, Result) Export

	SafeModeManagerInternalSaaS.OnRequestPermissionsToUseExternalResources(ProgramModule, Owner, ReplacementMode, PermissionsToAdd, PermissionsToDelete, StandardProcessing, Result);

EndProcedure

// See SafeModeManagerOverridable.OnRequestToCreateSecurityProfile
Procedure OnRequestToCreateSecurityProfile(Val ProgramModule,
		StandardProcessing, Result) Export

	SafeModeManagerInternalSaaS.OnRequestToCreateSecurityProfile(ProgramModule, StandardProcessing, Result);

EndProcedure

// See SafeModeManagerOverridable.OnRequestToDeleteSecurityProfile
Procedure OnRequestToDeleteSecurityProfile(Val ProgramModule,
		StandardProcessing, Result) Export

	SafeModeManagerInternalSaaS.OnRequestToDeleteSecurityProfile(ProgramModule, StandardProcessing, Result);

EndProcedure

// See SafeModeManagerOverridable.OnAttachExternalModule
Procedure OnAttachExternalModule(Val ExternalModule,
		SafeMode) Export

	SafeModeManagerInternalSaaS.OnAttachExternalModule(ExternalModule, SafeMode);

EndProcedure

#EndRegion

#Region ScheduledJobs

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
Procedure OnDefineScheduledJobSettings(Settings) Export

	If Common.SubsystemExists("CloudTechnology.ApplicationsMigration") Then
		ApplicationMigrationModule = Common.CommonModule("ApplicationsMigration");
		ApplicationMigrationModule.OnDefineScheduledJobSettings(Settings);
	EndIf;
	If Common.SubsystemExists("CloudTechnology.TariffsManagement") Then
		ModuleTariffication = Common.CommonModule("Tariffication");
		ModuleTariffication.OnDefineScheduledJobSettings(Settings);
	EndIf;
	If Common.SubsystemExists("CloudTechnology.QualityControlCenter") Then
		ModuleQCCIncidentsServer = Common.CommonModule("QCCIncidentsServer");
		ModuleQCCIncidentsServer.OnDefineScheduledJobSettings(Settings);
	EndIf;
	If Common.SubsystemExists("CloudTechnology.InformationCenter") Then
		ModuleInformationCenterInternal = Common.CommonModule("InformationCenterInternal");
		ModuleInformationCenterInternal.OnDefineScheduledJobSettings(Settings);
	EndIf;
	If Common.SubsystemExists("CloudTechnology.UsersNotificationCTL") Then
		ModuleUsersNotificationCTL = Common.CommonModule("UsersNotificationCTL");
		ModuleUsersNotificationCTL.OnDefineScheduledJobSettings(Settings);
	EndIf;

EndProcedure

#EndRegion

#Region AccessManagement

// See AccessManagementOverridable.OnFillSuppliedAccessGroupProfiles
Procedure OnFillSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate) Export
EndProcedure

#EndRegion

#Region IBVersionUpdate

// See SSLSubsystemsIntegration.OnGetUpdatePriority.
Procedure OnGetUpdatePriority(Priority) Export
	
	DataProcessPriority = "DataProcessing";
	
	If Priority = DataProcessPriority Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Not Constants.SetPriorityOfDataProcessingInSpecifiedTimeInterval.Get() Then
		Return;
	EndIf;
	
	TimeTypesDescription = Common.DateTypeDetails(DateFractions.Time);
	CurrentUniversalTime = TimeTypesDescription.AdjustValue(CurrentUniversalDate());
	
	BeginningOfDataProcessingPriorityTimeInterval = Constants.BeginningOfDataProcessingPriorityTimeInterval.Get();
	EndOfDataProcessingPriorityTimeInterval = Constants.EndOfDataProcessingPriorityTimeInterval.Get();
	
	If EndOfDataProcessingPriorityTimeInterval > BeginningOfDataProcessingPriorityTimeInterval Then
		If CurrentUniversalTime >= BeginningOfDataProcessingPriorityTimeInterval 
			And CurrentUniversalTime <= EndOfDataProcessingPriorityTimeInterval Then
			Priority = DataProcessPriority;
		EndIf;
	Else
		If CurrentUniversalTime <= EndOfDataProcessingPriorityTimeInterval 
			Or CurrentUniversalTime >= BeginningOfDataProcessingPriorityTimeInterval Then
			Priority = DataProcessPriority;
		EndIf;	 
	EndIf;
		
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Internal

#Region Core

// See InfobaseUpdateCTL.OnAddUpdateHandlers
Procedure OnAddCTLUpdateHandlers(Handlers) Export

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnAddCTLUpdateHandlers Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnAddCTLUpdateHandlers(Handlers);
	EndIf;

EndProcedure

#EndRegion

#Region ExportImportData

// Parameters:
//	Types - See ExportImportDataOverridable.OnFillTypesThatRequireRefAnnotationOnImport.Types
Procedure OnFillTypesThatRequireRefAnnotationOnImport(Types) Export

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnFillTypesThatRequireRefAnnotationOnImport Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnFillTypesThatRequireRefAnnotationOnImport(Types);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnFillTypesThatRequireRefAnnotationOnImport Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnFillTypesThatRequireRefAnnotationOnImport(Types);
	EndIf;

EndProcedure

// Parameters:
//	Types - See ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefMappingOnExport.Types
Procedure OnFillCommonDataTypesSupportingRefMappingOnExport(Types) Export

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnFillCommonDataTypesSupportingRefMappingOnExport Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnFillCommonDataTypesSupportingRefMappingOnExport(Types);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnFillCommonDataTypesSupportingRefMappingOnExport Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnFillCommonDataTypesSupportingRefMappingOnExport(Types);
	EndIf;

EndProcedure

// Parameters:
//	Types - See ExportImportDataOverridable.OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport.Types
Procedure OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport(Types) Export

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport(Types);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport(Types);
	EndIf;

EndProcedure

// Parameters:
//	Types - Array of MetadataObject - types to exclude.
Procedure OnFillTypesExcludedFromExportImport(Types) Export

	SaaSOperations.OnFillTypesExcludedFromExportImport(Types);
	MessagesExchangeInner.OnFillTypesExcludedFromExportImport(Types);
	JobsQueueInternalDataSeparation.OnFillTypesExcludedFromExportImport(Types);
	DataAreasBackup.OnFillTypesExcludedFromExportImport(Types);
	ApplicationsSize.OnFillTypesExcludedFromExportImport(Types);

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnFillTypesExcludedFromExportImport Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnFillTypesExcludedFromExportImport(Types);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnFillTypesExcludedFromExportImport Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnFillTypesExcludedFromExportImport(Types);
	EndIf;

EndProcedure

// Parameters:
//	HandlersTable - See ExportImportDataOverridable.OnRegisterDataExportHandlers.HandlersTable
Procedure OnRegisterDataExportHandlers(HandlersTable) Export

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnRegisterDataExportHandlers Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnRegisterDataExportHandlers(HandlersTable);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnRegisterDataExportHandlers Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnRegisterDataExportHandlers(HandlersTable);
	EndIf;

EndProcedure

// Parameters:
//	HandlersTable - See ExportImportDataOverridable.OnRegisterDataImportHandlers.HandlersTable
Procedure OnRegisterDataImportHandlers(HandlersTable) Export

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnRegisterDataImportHandlers Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnRegisterDataImportHandlers(HandlersTable);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnRegisterDataImportHandlers Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnRegisterDataImportHandlers(HandlersTable);
	EndIf;

EndProcedure

// Parameters:
//	Container - See ExportImportDataOverridable.BeforeExportData.Container
Procedure BeforeExportData(Container) Export

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().BeforeExportData Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.BeforeExportData(Container);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().BeforeExportData Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.BeforeExportData(Container);
	EndIf;

EndProcedure

// Parameters:
//	Container - See ExportImportDataOverridable.AfterExportData.Container
Procedure AfterExportData(Container) Export

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().AfterExportData Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		// @skip-warning 
		ModuleSSLSubsystemsIntegration.AfterExportData(Container);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().AfterExportData Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.AfterExportData(Container);
	EndIf;

EndProcedure

// Parameters:
//	Container - See ExportImportDataOverridable.BeforeImportData.Container
Procedure BeforeImportData(Container) Export

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().BeforeExportData Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.BeforeImportData(Container);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().BeforeImportData Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.BeforeImportData(Container);
	EndIf;

EndProcedure

// Parameters:
//	Container - See ExportImportDataOverridable.AfterImportData.Container
Procedure AfterImportData(Container) Export

	SaaSOperations.AfterImportData(Container);

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().AfterImportData Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.AfterImportData(Container);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().AfterImportData Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.AfterImportData(Container);
	EndIf;

EndProcedure

// Parameters:
//	Container - See ExportImportDataOverridable.OnImportInfobaseUser.Container
//	Serialization - See ExportImportDataOverridable.OnImportInfobaseUser.Serialization
//	IBUser - See ExportImportDataOverridable.OnImportInfobaseUser.IBUser
//	Cancel - See ExportImportDataOverridable.OnImportInfobaseUser.Cancel
Procedure OnImportInfobaseUser(Container, Serialization,
		IBUser, Cancel) Export

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnImportInfobaseUser Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnImportInfobaseUser(Container, Serialization, IBUser, Cancel);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnImportInfobaseUser Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnImportInfobaseUser(Container, Serialization, IBUser, Cancel);
	EndIf;

EndProcedure

// Parameters:
//	Container - See ExportImportDataOverridable.AfterImportInfobaseUser.Container
//	Serialization - See ExportImportDataOverridable.AfterImportInfobaseUser.Serialization
//	IBUser - See ExportImportDataOverridable.AfterImportInfobaseUser.IBUser
Procedure AfterImportInfobaseUser(Container, Serialization,
		IBUser) Export

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().AfterImportInfobaseUser Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.AfterImportInfobaseUser(Container, Serialization, IBUser);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().AfterImportInfobaseUser Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.AfterImportInfobaseUser(Container, Serialization, IBUser);
	EndIf;

EndProcedure

// Parameters:
//	Container - See ExportImportDataOverridable.AfterImportInfobaseUsers.Container
Procedure AfterImportInfobaseUsers(Container) Export

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().AfterImportInfobaseUsers Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.AfterImportInfobaseUsers(Container);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().AfterImportInfobaseUsers Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.AfterImportInfobaseUsers(Container);
	EndIf;

EndProcedure

#EndRegion

#Region SaaSOperations_CoreSaaS

// Parameters:
//	ParametersTable - See SaaSOperations.IBParameters
Procedure OnFillIIBParametersTable(Val ParametersTable) Export

	AdditionalReportsAndDataProcessorsSaaS.OnFillIIBParametersTable(ParametersTable);
	SafeModeManagerInternalSaaS.OnFillIIBParametersTable(ParametersTable);
	SaaSOperationsCTL.OnFillIIBParametersTable(ParametersTable);
	ExtensionsSaaS.OnFillIIBParametersTable(ParametersTable);
	DigitalSignatureSaaS.OnFillIIBParametersTable(ParametersTable);
	DataAreasBackup.OnFillIIBParametersTable(ParametersTable);

	If Common.SubsystemExists("CloudTechnology.InformationCenter") Then
		ModuleInformationCenterInternal = Common.CommonModule("InformationCenterInternal");
		ModuleInformationCenterInternal.OnFillIIBParametersTable(ParametersTable);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnFillIIBParametersTable Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnFillIIBParametersTable(ParametersTable)
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnFillIIBParametersTable Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnFillIIBParametersTable(ParametersTable);
	EndIf;

EndProcedure

// Parameters:
//	UserIdentificator - See SaaSOperations.AliasOfUserOfInformationBase.UserIdentificator
//	Alias - String - alias to assign (return parameter).
Procedure OnDefineUserAlias(UserIdentificator, Alias) Export

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineUserAlias Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineUserAlias(UserIdentificator, Alias)
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnDefineUserAlias Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnDefineUserAlias(UserIdentificator, Alias);
	EndIf;

EndProcedure

// See SaaSOperations.OnDefineSharedDataExceptions
// 
// Parameters:
//	Exceptions - Array of MetadataObject - Exceptions.
//
Procedure OnDefineSharedDataExceptions(Exceptions) Export

	If Common.SubsystemExists("CloudTechnology.QualityControlCenter") Then
		ModuleQCCIncidentsServer = Common.CommonModule("QCCIncidentsServer");
		ModuleQCCIncidentsServer.OnDefineSharedDataExceptions(Exceptions);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineSharedDataExceptions Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		// @skip-warning 
		ModuleSSLSubsystemsIntegration.OnDefineSharedDataExceptions(Exceptions);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnDefineSharedDataExceptions Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnDefineSharedDataExceptions(Exceptions);
	EndIf;
	
	SaaSOperations.OnDefineSharedDataExceptions(Exceptions);

EndProcedure

// See SaaSOperationsOverridable.OnSetIBParametersValues
Procedure OnSetIBParametersValues(Val ParameterValues) Export

	AdditionalReportsAndDataProcessorsSaaS.OnSetIBParametersValues(ParameterValues);
	ExtensionsSaaS.OnSetIBParametersValues(ParameterValues);
	RemoteAdministrationInternal.OnSetIBParametersValues(ParameterValues);
	DigitalSignatureSaaS.OnSetIBParametersValues(ParameterValues);

	If Common.SubsystemExists("CloudTechnology.InformationCenter") Then
		ModuleInformationCenterInternal = Common.CommonModule("InformationCenterInternal");
		ModuleInformationCenterInternal.OnSetIBParametersValues(ParameterValues);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnSetIBParametersValues Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		// @skip-warning 
		ModuleSSLSubsystemsIntegration.OnSetIBParametersValues(ParameterValues);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnSetIBParametersValues Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnSetIBParametersValues(ParameterValues);
	EndIf;

EndProcedure

#EndRegion

#Region SaaSOperations_MessagesExchange

// @skip-warning EmptyMethod - Implementation feature.
// 
//  Parameters:
//	Handlers - See MessagesExchangeOverridable.GetMessagesChannelsHandlers.Handlers
//
Procedure OnDefineMessagesChannelsHandlers(Handlers) Export
EndProcedure

// See MessageInterfacesSaaSOverridable.FillInReceivedMessageHandlers
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export

	AdditionalReportsAndDataProcessorsSaaS.RecordingIncomingMessageInterfaces(HandlersArray);
	If Common.SubsystemExists("CloudTechnology.InformationCenter") Then
		ModuleInformationCenterInternal = Common.CommonModule("InformationCenterInternal");
		ModuleInformationCenterInternal.RecordingIncomingMessageInterfaces(HandlersArray);
	EndIf;
	SafeModeManagerInternalSaaS.RecordingIncomingMessageInterfaces(HandlersArray);
	ExtensionsSaaS.RecordingIncomingMessageInterfaces(HandlersArray);
	RemoteAdministrationInternal.RecordingIncomingMessageInterfaces(HandlersArray);

	If Common.SubsystemExists("CloudTechnology.TariffsManagement") Then
		ModuleTariffication = Common.CommonModule("Tariffication");
		ModuleTariffication.RecordingIncomingMessageInterfaces(HandlersArray);
	EndIf;
	DataAreasBackup.RecordingIncomingMessageInterfaces(HandlersArray);

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().RecordingIncomingMessageInterfaces Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.RecordingIncomingMessageInterfaces(HandlersArray);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().RecordingIncomingMessageInterfaces Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.RecordingIncomingMessageInterfaces(HandlersArray);
	EndIf;

	If Common.SubsystemExists("CloudTechnology.SummaryApplications") Then
		ModuleSummaryApplications = Common.CommonModule("SummaryApplications");
		ModuleSummaryApplications.RecordingIncomingMessageInterfaces(HandlersArray);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.UsersNotificationCTL") Then
		ModuleUsersNotificationCTL = Common.CommonModule("UsersNotificationCTL");
		ModuleUsersNotificationCTL.RecordingIncomingMessageInterfaces(HandlersArray);
	EndIf

EndProcedure

// See MessageInterfacesSaaSOverridable.FillInHandlersForSendingMessages
Procedure RecordingOutgoingMessageInterfaces(HandlersArray) Export

	AdditionalReportsAndDataProcessorsSaaS.RecordingOutgoingMessageInterfaces(HandlersArray);
	ExtensionsSaaS.RecordingOutgoingMessageInterfaces(HandlersArray);
	RemoteAdministrationInternal.RecordingOutgoingMessageInterfaces(HandlersArray);

	If Common.SubsystemExists("CloudTechnology.TariffsManagement") Then
		ModuleTariffication = Common.CommonModule("Tariffication");
		ModuleTariffication.RecordingOutgoingMessageInterfaces(HandlersArray);
	EndIf;
	DataAreasBackup.RecordingOutgoingMessageInterfaces(HandlersArray);

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().RecordingOutgoingMessageInterfaces Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.RecordingOutgoingMessageInterfaces(HandlersArray);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().RecordingOutgoingMessageInterfaces Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.RecordingOutgoingMessageInterfaces(HandlersArray);
	EndIf;

	If Common.SubsystemExists("CloudTechnology.SummaryApplications") Then
		ModuleSummaryApplications = Common.CommonModule("SummaryApplications");
		ModuleSummaryApplications.RecordingOutgoingMessageInterfaces(HandlersArray);
	EndIf;
	
EndProcedure

// See MessageInterfacesSaaSOverridable.OnDefineCorrespondentInterfaceVersion
Procedure OnDefineCorrespondentInterfaceVersion(Val MessageInterface,
		Val ConnectionParameters, Val RecipientPresentation1, Result) Export

	AdditionalReportsAndDataProcessorsSaaS.OnDefineCorrespondentInterfaceVersion(MessageInterface, ConnectionParameters, RecipientPresentation1, Result);

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineCorrespondentInterfaceVersion Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		// @skip-warning 
		ModuleSSLSubsystemsIntegration.OnDefineCorrespondentInterfaceVersion(
			MessageInterface, ConnectionParameters, RecipientPresentation1, Result);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnDefineCorrespondentInterfaceVersion Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnDefineCorrespondentInterfaceVersion(
			MessageInterface,	ConnectionParameters, RecipientPresentation1, Result);
	EndIf;

EndProcedure

#EndRegion

#Region SaaSOperations_JobsQueue

// See JobsQueueOverridable.OnGetTemplateList
Procedure OnGetTemplateList(JobTemplates) Export

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnGetTemplateList Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnGetTemplateList(JobTemplates);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnGetTemplateList Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnGetTemplateList(JobTemplates);
	EndIf;

EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export

	AdditionalReportsAndDataProcessorsSaaS.OnDefineHandlerAliases(NamesAndAliasesMap);
	ExtensionsSaaS.OnDefineHandlerAliases(NamesAndAliasesMap);
	SaaSOperationsCTL.OnDefineHandlerAliases(NamesAndAliasesMap);
	If Common.SubsystemExists("CloudTechnology.ApplicationsMigration") Then
		ApplicationMigrationModule = Common.CommonModule("ApplicationsMigration");
		ApplicationMigrationModule.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;
	If Common.SubsystemExists("CloudTechnology.SuppliedSubscribersData") Then
		ModuleSuppliedSubscriberData = Common.CommonModule("SuppliedSubscribersData");
		ModuleSuppliedSubscriberData.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;
	If Common.SubsystemExists("CloudTechnology.DataAreasObjectsIntegration") Then
		ModuleIntegrationOfDataDomainObjects = Common.CommonModule("DataAreasObjectsIntegration");
		ModuleIntegrationOfDataDomainObjects.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;
	If Common.SubsystemExists("CloudTechnology.AsyncDataReceipt") Then
		AsynchronousDataAcquisitionModule = Common.CommonModule("AsyncDataReceipt");
		AsynchronousDataAcquisitionModule.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;

	If Common.SubsystemExists("CloudTechnology.ProcessAutomation.DistributedCommandExecution") Then
		DistributedCommandExecutionModule = Common.CommonModule("DistributedCommandExecution");
		DistributedCommandExecutionModule.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;

	SuppliedData.OnDefineHandlerAliases(NamesAndAliasesMap);
	SaaSOperations.OnDefineHandlerAliases(NamesAndAliasesMap);
	DataAreasBackup.OnDefineHandlerAliases(NamesAndAliasesMap);

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineHandlerAliases Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnDefineHandlerAliases Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;

	If Common.SubsystemExists("CloudTechnology.SummaryApplications") Then
		ModuleSummaryApplications = Common.CommonModule("SummaryApplications");
		ModuleSummaryApplications.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;

EndProcedure

// See JobsQueueOverridable.OnDefineErrorHandlers
Procedure OnDefineErrorHandlers(ErrorHandlers) Export

	SaaSOperationsCTL.OnDefineErrorHandlers(ErrorHandlers);
	DataAreasBackup.OnDefineErrorHandlers(ErrorHandlers);

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineErrorHandlers Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineHandlerAliases(ErrorHandlers);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnDefineErrorHandlers Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnDefineErrorHandlers(ErrorHandlers);
	EndIf;

EndProcedure

// See JobsQueueOverridable.OnDefineScheduledJobsUsage
// Parameters:
// 	UsageTable - ValueTable - Details:
//		* ScheduledJob - String - a name of scheduled job.
//  	* Use - Boolean - Usage flag.
//
Procedure OnDefineScheduledJobsUsage(UsageTable) Export

	SaaSOperations.OnDefineScheduledJobsUsage(UsageTable);

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineScheduledJobsUsage Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineScheduledJobsUsage(UsageTable);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnDefineScheduledJobsUsage Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnDefineScheduledJobsUsage(UsageTable);
	EndIf;

EndProcedure

#EndRegion

#Region SaaSOperations_SuppliedData

// See SuppliedDataOverridable.GetHandlersForSuppliedData
Procedure OnDefineSuppliedDataHandlers(Handlers) Export

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnDefineSuppliedDataHandlers Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnDefineSuppliedDataHandlers(Handlers);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnDefineSuppliedDataHandlers Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		ModuleSSLSubsystemsIntegration.OnDefineSuppliedDataHandlers(Handlers);
	EndIf;

	If Common.SubsystemExists("CloudTechnology.InformationCenter") Then
		ModuleInformationCenterInternal = Common.CommonModule("InformationCenterInternal");
		ModuleInformationCenterInternal.OnDefineSuppliedDataHandlers(Handlers);
	EndIf;

	ExtensionsSaaS.OnDefineSuppliedDataHandlers(Handlers);
	SaaSOperations.OnDefineSuppliedDataHandlers(Handlers);

EndProcedure

#EndRegion

#Region ServiceTechnology_TariffManagement

Procedure OnCreateServicesList(ServiceProviders) Export

	If CTLSubsystemsIntegrationCached.SubscriptionsSSL().OnCreateServicesList Then
		ModuleSSLSubsystemsIntegration = Common.CommonModule("SSLSubsystemsIntegration");
		// @skip-warning 
		ModuleSSLSubsystemsIntegration.OnCreateServicesList(ServiceProviders);
	EndIf;

	If CTLSubsystemsIntegrationCached.SubscriptionsOSL().OnCreateServicesList Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule(NameOfBIPIntegrationModule());
		ModuleOSLSubsystemsIntegration.OnCreateServicesList(ServiceProviders);
	EndIf;

EndProcedure

#EndRegion

#Region OverridingCalls

#Region Core

// See Common.SessionSeparatorUsage
// ()
// 
// Returns:
//	Boolean - Usage flag.
Function SessionSeparatorUsage() Export
	
	Return Common.DataSeparationEnabled() 
			And Common.SeparatedDataUsageAvailable();
	
EndFunction

// 
//
Procedure LockIB(Val CheckNoOtherSessions = True) Export

	SetExclusiveMode(True);

EndProcedure

// 
//
Procedure UnlockIB() Export

	SetExclusiveMode(False);

EndProcedure

#EndRegion

#Region CoreSaaS

// See SaaSOperations.LockCurDataArea
// ()
//
Procedure LockCurDataArea(Val CheckNoOtherSessions = False,
		Val SharedLocking = False) Export

	SetExclusiveMode(True);

EndProcedure

// See SaaSOperations.UnlockCurDataArea
// ()
//
Procedure UnlockCurDataArea() Export

	SetExclusiveMode(False);

EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Private

Function NameOfBIPIntegrationModule()
	
	Return "OSLSubsystemsIntegration";
	
EndFunction

// Defines events, to which other libraries can subscribe.
//
// Returns:
// 	Structure - Structure property keys are names of events, to which libraries can be subscribed. Details:
// * BeforeExportData - Boolean -
// * BeforeImportData - Boolean -
// * AfterExportData - Boolean -
// * AfterImportData - Boolean -
// * AfterImportInfobaseUsers - Boolean -
// * AfterImportInfobaseUser - Boolean -
// * OnAddCTLUpdateHandlers - Boolean -
// * OnImportInfobaseUser - Boolean -
// * OnFillIIBParametersTable - Boolean -
// * OnFillTypesExcludedFromExportImport - Boolean -
// * OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport - Boolean -
// * OnFillCommonDataTypesSupportingRefMappingOnExport - Boolean -
// * OnFillTypesThatRequireRefAnnotationOnImport - Boolean -
// * OnDefineCorrespondentInterfaceVersion - Boolean -
// * OnDefineSharedDataExceptions - Boolean -
// * OnDefineScheduledJobsUsage - Boolean -
// * OnDefineMessagesChannelsHandlers - Boolean -
// * OnDefineErrorHandlers - Boolean -
// * OnDefineSuppliedDataHandlers - Boolean -
// * OnDefineUserAlias - Boolean -
// * OnDefineHandlerAliases - Boolean -
// * OnGetTemplateList - Boolean -
// * OnRegisterDataExportHandlers - Boolean -
// * OnRegisterDataImportHandlers - Boolean -
// * OnSetIBParametersValues - Boolean -
// * OnCreateServicesList - Boolean -
// * RecordingOutgoingMessageInterfaces - Boolean -
// * RecordingIncomingMessageInterfaces - Boolean -
Function EventsCTL() Export

	Events = New Structure;

	// Core
	Events.Insert("OnAddCTLUpdateHandlers", False);

	// ExportImportData
	Events.Insert("OnFillTypesThatRequireRefAnnotationOnImport", False);
	Events.Insert("OnFillCommonDataTypesSupportingRefMappingOnExport", False);
	Events.Insert("OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport", False);
	Events.Insert("OnFillTypesExcludedFromExportImport", False);
	Events.Insert("OnRegisterDataExportHandlers", False);
	Events.Insert("OnRegisterDataImportHandlers", False);
	Events.Insert("BeforeExportData", False);
	Events.Insert("AfterExportData", False);
	Events.Insert("BeforeImportData", False);
	Events.Insert("AfterImportData", False);
	Events.Insert("OnImportInfobaseUser", False);
	Events.Insert("AfterImportInfobaseUser", False);
	Events.Insert("AfterImportInfobaseUsers", False);

	// SaaSTechnology_Core
	Events.Insert("OnFillIIBParametersTable", False);
	Events.Insert("OnDefineUserAlias", False);
	Events.Insert("OnDefineSharedDataExceptions", False);
	Events.Insert("OnSetIBParametersValues", False);

	// SaaSTechnology_MessageExchange
	Events.Insert("OnDefineMessagesChannelsHandlers", False);
	Events.Insert("RecordingIncomingMessageInterfaces", False);
	Events.Insert("RecordingOutgoingMessageInterfaces", False);
	Events.Insert("OnDefineCorrespondentInterfaceVersion", False);

	// SaaSTechnology_JobsQueue
	Events.Insert("OnGetTemplateList", False);
	Events.Insert("OnDefineHandlerAliases", False);
	Events.Insert("OnDefineErrorHandlers", False);
	Events.Insert("OnDefineScheduledJobsUsage", False);

	// SaaSTechnology_SuppliedData
	Events.Insert("OnDefineSuppliedDataHandlers", False);

	// SaaSTechnology_SupportPlansManagement
	Events.Insert("OnCreateServicesList", False);

	Return Events;

EndFunction

Procedure CheckCanRunProgram()
	
	If Not SaaSOperations.DataSeparationEnabled()
		And GetFunctionalOption("ExclusiveLockSet") Then
		
		Job = GetCurrentInfoBaseSession().GetBackgroundJob();
		CanStartProgram = Job <> Undefined
			And SaaSOperations.MethodsAllowedToRunNames().Find(Job.MethodName) <> Undefined;
		
		If Not CanStartProgram And GetInfoBaseSessions().Count() = 1 Then
			SaaSOperations.RemoveExclusiveLock(True);
			CanStartProgram = True;
		EndIf;
		
		If Not CanStartProgram Then
			Raise NStr("ru = 'База данных заблокирована';
									|en = 'The database is locked';");
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
