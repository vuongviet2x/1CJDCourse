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
//  HandlersArray - Array - Array of handlers.
//
Procedure MessagesChannelsHandlers(Val HandlersArray) Export
EndProcedure

// Registers message translation handlers.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  HandlersArray - Array - Array of handlers.
//
Procedure MessagesTranslationHandlers(Val HandlersArray) Export
EndProcedure

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Manage/a.b.c.d}SetCorrSynopticExchange.
// @skip-warning EmptyMethod - implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTOValueType
//
Function ConfigureUploadToSummaryAppMessage(Val PackageToUse = Undefined) Export
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Manage/a.b.c.d}SetSynopticExchange.
// @skip-warning EmptyMethod - implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTOValueType
//
Function MessageConfigureUploadToSummaryApp(Val PackageToUse = Undefined) Export
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Manage/a.b.c.d}PushSynopticExchangeStep1.
// @skip-warning EmptyMethod - implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTOValueType
//
Function MessageInteractiveStartOfUploadToSummaryApplication(Val PackageToUse = Undefined) Export
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Manage/a.b.c.d}PushSynopticExchangeStep2.
// @skip-warning EmptyMethod - implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTOValueType
//
Function MessageInteractiveStartLoadingToSummaryApplication(Val PackageToUse = Undefined) Export
EndFunction

#EndRegion
