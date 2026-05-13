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
//   String - a namespace.
//
Function Package() Export
EndFunction

// Returns the current (used by the calling code) version of the message interface.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//   String - an interface version.
//
Function Version() Export
EndFunction

// Returns a name of the application message interface.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//   String - an interface name.
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

// Returns the message type {http://www.1c.ru/1cFresh/ControlSynopticExchange/a.b.c.d}SynopticExchangePrepared.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which the message type is being received.
//
// Returns:
//  XDTOValueType
//
Function MessageUploadToSummaryApplicationSetupCompleted(Val PackageToUse = Undefined) Export
EndFunction

// Returns the message type {{http://www.1c.ru/1cFresh/ControlSynopticExchange/a.b.c.d}SynopticExchangeFailed.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
// XDTOValueType
//
Function ErrorMessageConfiguringUploadingToSummaryApp(Val PackageToUse = Undefined) Export
EndFunction

// Returns the message type {http://www.1c.ru/1cFresh/ControlSynopticExchange/a.b.c.d}SynopticExchangeDeleted.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTOValueType
//
Function MessageUploadToSummaryApplicationSettingsRemoved(Val PackageToUse = Undefined) Export
EndFunction

// Returns the message type {http://www.1c.ru/1cFresh/ControlSynopticExchange/a.b.c.d}SynopticExchangePushed.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTOValueType
//
Function MessageInteractiveStartOfUploadToSummaryApplicationCompleted(Val PackageToUse = Undefined) Export
EndFunction

#EndRegion
