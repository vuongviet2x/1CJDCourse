///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// Namespace of message interface version.
//
// Returns:
//   String - a namespace.
//
Function Package() Export
	
	Return "http://www.1c.ru/SaaS/ExchangeAdministration/Control";
	
EndFunction

// Message interface version supported by the handler.
//
// Returns:
//   String - a message interface version.
//
Function Version() Export
	
	Return "2.1.2.1";
	
EndFunction

// Base type for version messages.
//
// Returns:
//   XDTOObjectType - a base type of message body.
//
Function BaseType() Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Raise NStr("ru = 'Отсутствует менеджер сервиса.';
								|en = 'There is no Service manager.';");
	EndIf;
	
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	Return ModuleMessagesSaaS.TypeBody();
	
EndFunction

// Processing incoming SaaS messages
//
// Parameters:
//   Message   - XDTODataObject - an incoming message.
//   Sender - ExchangePlanRef.MessagesExchange - exchange plan node that matches the message sender.
//   MessageProcessed - Boolean - indicates whether the message is successfully processed. The parameter value must be
//                         set to True if the message was successfully read in this handler.
//
Procedure ProcessSaaSMessage(Val Message, Val Sender, MessageProcessed) Export
	
	MessageProcessed = True;
	
	Dictionary = MessagesDataExchangeAdministrationControlInterface;
	MessageType = Message.Body.Type();
	
	If MessageType = Dictionary.DataSynchronizationSettingsReceivedMessage(Package()) Then
		DataExchangeSaaS.SaveSessionData(Message, SettingsGetActionPresentation());
	ElsIf MessageType = Dictionary.DataSynchronizationSettingsReceivingErrorMessage(Package()) Then
		DataExchangeSaaS.CommitUnsuccessfulSession(Message, SettingsGetActionPresentation());
	ElsIf MessageType = Dictionary.SynchronizationEnabledSuccessfullyMessage(Package()) Then
		DataExchangeSaaS.CommitSuccessfulSession(Message, SynchronizationEnablingPresentation());
	ElsIf MessageType = Dictionary.SynchronizationDisabledMessage(Package()) Then
		DataExchangeSaaS.CommitSuccessfulSession(Message, SynchronizationDisablingPresentation());
	ElsIf MessageType = Dictionary.SynchronizationEnablingErrorMessage(Package()) Then
		DataExchangeSaaS.CommitUnsuccessfulSession(Message, SynchronizationEnablingPresentation());
	ElsIf MessageType = Dictionary.SynchronizationDisablingErrorMessage(Package()) Then
		DataExchangeSaaS.CommitUnsuccessfulSession(Message, SynchronizationDisablingPresentation());
	ElsIf MessageType = Dictionary.SynchronizationDoneMessage(Package()) Then
		DataExchangeSaaS.CommitSuccessfulSession(Message, SynchronizationExecutionPresentation());
	Else
		MessageProcessed = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function SettingsGetActionPresentation()
	
	Return NStr("ru = 'Получение настроек синхронизации данных из Менеджера сервиса.';
				|en = 'Getting data synchronization settings from Service manager.';");
	
EndFunction

Function SynchronizationEnablingPresentation()
	
	Return NStr("ru = 'Включение синхронизации данных в Менеджере сервиса.';
				|en = 'Enabling data synchronization in Service manager.';");
	
EndFunction

Function SynchronizationDisablingPresentation()
	
	Return NStr("ru = 'Отключение синхронизации данных в Менеджере сервиса.';
				|en = 'Disabling data synchronization in Service manager.';");
	
EndFunction

Function SynchronizationExecutionPresentation()
	
	Return NStr("ru = 'Выполнение синхронизации данных по запросу пользователя.';
				|en = 'Running data synchronization by user request.';");
	
EndFunction

#EndRegion
