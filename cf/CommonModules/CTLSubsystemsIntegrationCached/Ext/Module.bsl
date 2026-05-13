///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2019, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//strict-types

#Region Internal

// SSL subscriptions.
// 
// Returns: 
//  Structure:
// * BeforeExportData - Boolean
// * BeforeImportData - Boolean
// * AfterExportData - Boolean
// * AfterImportData - Boolean
// * AfterImportInfobaseUsers - Boolean
// * AfterImportInfobaseUser - Boolean
// * OnAddCTLUpdateHandlers - Boolean
// * OnImportInfobaseUser - Boolean
// * OnFillIIBParametersTable - Boolean
// * OnFillTypesExcludedFromExportImport - Boolean
// * OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport - Boolean
// * OnFillCommonDataTypesSupportingRefMappingOnExport - Boolean
// * OnFillTypesThatRequireRefAnnotationOnImport - Boolean
// * OnDefineCorrespondentInterfaceVersion - Boolean
// * OnDefineSharedDataExceptions - Boolean
// * OnDefineScheduledJobsUsage - Boolean
// * OnDefineMessagesChannelsHandlers - Boolean
// * OnDefineErrorHandlers - Boolean
// * OnDefineSuppliedDataHandlers - Boolean
// * OnDefineUserAlias - Boolean
// * OnDefineHandlerAliases - Boolean
// * OnGetTemplateList - Boolean
// * OnRegisterDataExportHandlers - Boolean
// * OnRegisterDataImportHandlers - Boolean
// * OnSetIBParametersValues - Boolean
// * OnCreateServicesList - Boolean
// * RecordingOutgoingMessageInterfaces - Boolean
// * RecordingIncomingMessageInterfaces - Boolean
// (See CTLSubsystemsIntegration.EventsCTL)
Function SubscriptionsSSL() Export
	
	Subscriptions = CTLSubsystemsIntegration.EventsCTL();
	SSLSubsystemsIntegration.OnDefineEventsSubscriptionsCTL(Subscriptions);
	
	Return Subscriptions;
	
EndFunction

// OSL subscriptions.
// 
// Returns:
//  Structure:
// * BeforeExportData - Boolean
// * BeforeImportData - Boolean
// * AfterExportData - Boolean
// * AfterImportData - Boolean
// * AfterImportInfobaseUsers - Boolean
// * AfterImportInfobaseUser - Boolean
// * OnAddCTLUpdateHandlers - Boolean
// * OnImportInfobaseUser - Boolean
// * OnFillIIBParametersTable - Boolean
// * OnFillTypesExcludedFromExportImport - Boolean
// * OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport - Boolean
// * OnFillCommonDataTypesSupportingRefMappingOnExport - Boolean
// * OnFillTypesThatRequireRefAnnotationOnImport - Boolean
// * OnDefineCorrespondentInterfaceVersion - Boolean
// * OnDefineSharedDataExceptions - Boolean
// * OnDefineScheduledJobsUsage - Boolean
// * OnDefineMessagesChannelsHandlers - Boolean
// * OnDefineErrorHandlers - Boolean
// * OnDefineSuppliedDataHandlers - Boolean
// * OnDefineUserAlias - Boolean
// * OnDefineHandlerAliases - Boolean
// * OnGetTemplateList - Boolean
// * OnRegisterDataExportHandlers - Boolean
// * OnRegisterDataImportHandlers - Boolean
// * OnSetIBParametersValues - Boolean
// * OnCreateServicesList - Boolean
// * RecordingOutgoingMessageInterfaces - Boolean
// * RecordingIncomingMessageInterfaces - Boolean
// (See CTLSubsystemsIntegration.EventsCTL)
Function SubscriptionsOSL() Export
	
	Subscriptions = CTLSubsystemsIntegration.EventsCTL();
	If Common.SubsystemExists("OnlineUserSupport") Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule("OSLSubsystemsIntegration");
		ModuleOSLSubsystemsIntegration.OnDefineEventsSubscriptionsCTL(Subscriptions);
	EndIf;
	
	Return Subscriptions;
	
EndFunction

#EndRegion