///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2018, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns a namespace of the message interface version.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//  String - a package description.
//
Function Package() Export
EndFunction

// Returns a message interface version supported by the handler.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//  String -Package version.
//
Function Version() Export
EndFunction

// Returns a base type for version messages.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//  XDTOObjectType - base body type for messages SaaS.
//
Function BaseType() Export
EndFunction

// Processes incoming SaaS messages.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  Message - XDTODataObject - Incoming message.
//  Sender - ExchangePlanRef.MessagesExchange - exchange plan node that matches the message sender.
//  MessageProcessed - Boolean - indicates whether the message is successfully processed. The parameter value must be
//    set to If True, the message was successfully read in this handler.
//
Procedure ProcessSaaSMessage(Val Message, Val Sender, MessageProcessed) Export
EndProcedure

#EndRegion
