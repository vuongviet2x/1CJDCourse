///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2018, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
// @strict-types

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Message exchange.

// Returns a state of using data area backup.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//   Boolean - True if backup is used.
//
Function BackupIsUsed() Export
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Active users in data area.

// Sets a flag of user activity in the current area.
// A flag is a value of jointly separated LastClientSessionStartDate constant.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure SetUserActivityFlagInArea() Export
EndProcedure

// Returns a mapping of Russian names of application system settings fields
// to English names from XDTO package ZoneBackupControl of Service manager.
// (a type:{http://www.1c.ru/SaaS/1.0/XMLSchema/ZoneBackupControl}Settings).
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//   FixedMap of KeyAndValue - Mapping between Russian and English names of setting fields.:
//   * Key - String
//   * Value - String
//
Function MatchingRussianNamesOfSettingsFieldsToEnglish() Export
EndFunction

// Defines whether the application supports backup creation.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//  Boolean - True if the application supports backup creation.
//
Function ServiceManagerSupportsBackup() Export
EndFunction

// Returns the proxy of the backup management service.
// The calling code must set the privileged mode.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns: 
//   WSProxy - service manager proxy.
// 
Function BackupControlProxy() Export
EndFunction

// Returns a subsystem name that must be used in event names of the event log.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//   String - Subsystem name.
//
Function SubsystemNameForLogEvents() Export
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Background jobs.

// Returns a description of a background job that exports an area to a file.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//   String - the description of the background job.
//
Function NameOfBackgroundBackup() Export
EndFunction

// See JobsQueueOverridable.OnDefineHandlerAliases.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
// 	NamesAndAliasesMap - See JobsQueueOverridable.OnDefineHandlerAliases.NamesAndAliasesMap
// 
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.Constants.BackUpDataArea);
	Types.Add(Metadata.Constants.LastClientSessionStartDate);
	
EndProcedure

// See CommonOverridable.OnDefineSupportedInterfaceVersions.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
// 	SupportedVersionsStructure - See CommonOverridable.OnDefineSupportedInterfaceVersions.SupportedVersions
// 
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export
EndProcedure

// See SaaSOperationsOverridable.OnFillIIBParametersTable.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//	ParametersTable - See SaaSOperations.IBParameters
//
Procedure OnFillIIBParametersTable(ParametersTable) Export
EndProcedure

// See JobsQueueOverridable.OnDefineErrorHandlers.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
// 	ErrorHandlers - See JobsQueueOverridable.OnDefineErrorHandlers.ErrorHandlers
// 
Procedure OnDefineErrorHandlers(ErrorHandlers) Export
EndProcedure

// See MessageInterfacesSaaSOverridable.FillInReceivedMessageHandlers.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
// 	HandlersArray - See MessageInterfacesSaaSOverridable.FillInReceivedMessageHandlers.HandlersArray
// 
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
EndProcedure

// See MessageInterfacesSaaSOverridable.FillInHandlersForSendingMessages.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
// 	HandlersArray - See MessageInterfacesSaaSOverridable.FillInHandlersForSendingMessages.HandlersArray
// 
Procedure RecordingOutgoingMessageInterfaces(HandlersArray) Export
EndProcedure

// See CommonOverridable.OnAddClientParameters.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
// 	Parameters - See CommonOverridable.OnAddClientParameters.Parameters
// 
Procedure OnAddClientParameters(Parameters) Export
EndProcedure

#EndRegion
