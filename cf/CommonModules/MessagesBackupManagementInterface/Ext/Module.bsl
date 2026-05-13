///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2018, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns a namespace of the current (used by the calling code) version of the message interface.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//  String - a package description.
//
Function Package() Export
EndFunction

// Returns the current (used by the calling code) version of the message interface.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//  String - a package version.
//
Function Version() Export
EndFunction

// Returns a name of the application message interface.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//  String - an application interface ID.
//
Function Public() Export
EndFunction

// Registers message handlers as handlers of message exchange channels.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  HandlersArray - Array - an array of handlers.
//
Procedure MessagesChannelsHandlers(Val HandlersArray) Export
EndProcedure

// Registers message translation handlers.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  HandlersArray - Array - an array of handlers.
//
Procedure MessagesTranslationHandlers(Val HandlersArray) Export
EndProcedure

// Returns a message type {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d}PlanZoneBackup.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTODataObject - a message.
//
Function MessagePlanAreaArchiving(Val PackageToUse = Undefined) Export
EndFunction

// Returns a message type {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d}CancelZoneBackup.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTODataObject - a message.
//
Function CancelAreaArchivingMessage(Val PackageToUse = Undefined) Export
EndFunction

// Returns a message type {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d}UpdateScheduledZoneBackupSettings
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTODataObject - a message.
//
Function MessageUpdatePeriodicBackupSettings(Val PackageToUse = Undefined) Export
EndFunction

// Returns a message type {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d}CancelScheduledZoneBackup
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which the message type is being received.
//
// Returns:
//  XDTODataObject - a message.
//
Function CancelPeriodicBackupMessage(Val PackageToUse = Undefined) Export
EndFunction

#EndRegion
