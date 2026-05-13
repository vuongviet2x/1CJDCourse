///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Id <> Undefined Then
		IntegrationDetails = CollaborationSystem.GetIntegration(Parameters.Id);
		If IntegrationDetails <> Undefined Then
			Description = IntegrationDetails.Presentation;
			Token = IntegrationDetails.ExternalSystemParameters.Get("token");
			GroupIdentifier = IntegrationDetails.ExternalSystemParameters.Get("groupId");
			
			Attendees.Clear();
			For Each IBUser In Conversations.InfoBaseUsers(IntegrationDetails.Members) Do
				Attendees.Add().User = IBUser.Value;
			EndDo;
		EndIf;
		
		If IntegrationDetails.Use Then
			Items.Close.Title = NStr("ru = 'Записать и закрыть';
												|en = 'Save and close';");
			Items.Disconnect.Visible = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If Not StringFunctionsClientServer.OnlyNumbersInString(GroupIdentifier) Then
		Common.MessageToUser(NStr("ru = 'Ключ группы должен содержать только цифры.';
													|en = 'The group key must contain only numbers.';")
			,,"GroupIdentifier",,Cancel);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	ConversationsInternalClient.StartPickingConversationParticipants(Items.Attendees);
EndProcedure

&AtClient
Procedure ActivateBot(Command)
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Try
		ActivateServer();
		Close(True);
	Except
		ShowMessageBox(, NStr("ru = 'Не удалось активировать чат-бот по причине:';
										|en = 'Cannot enable the chat bot due to:';")
			+ Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndTry;
EndProcedure

&AtServer
Procedure ActivateServer()
	
	IntegrationParameters = ConversationsInternal.IntegrationParameters();
	IntegrationParameters.Id = Parameters.Id;
	IntegrationParameters.Key = Description; 
	IntegrationParameters.Type = ConversationsInternalClientServer.ExternalSystemsTypes().VKontakte;
	IntegrationParameters.Attendees = Attendees.Unload(,"User").UnloadColumn("User");
	IntegrationParameters.token = Token;
	IntegrationParameters.groupId = GroupIdentifier;
	
	Try
		ConversationsInternal.CreateChangeIntegration(IntegrationParameters);
	Except
		WriteLogEvent(ConversationsInternal.EventLogEvent(),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;

EndProcedure

&AtClient
Procedure AttendeesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	For Each PickedUser In ValueSelected Do
		If Attendees.FindRows(New Structure("User", PickedUser)).Count() = 0 Then
			Attendees.Add().User = PickedUser;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure Disconnect(Command)
	Try
		DisconnectServer();
	    Close(True);
	Except
		ShowMessageBox(, NStr("ru = 'Не удалось отключить чат-бот по причине:';
										|en = 'Cannot disable the chat bot due to:';")
			+ Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndTry;
EndProcedure

&AtServer
Procedure DisconnectServer()
	ConversationsInternal.DisableIntegration(Parameters.Id);
EndProcedure

#EndRegion

