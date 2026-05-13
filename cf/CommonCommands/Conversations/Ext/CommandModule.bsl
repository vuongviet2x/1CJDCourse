///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	NewConversation = NewConversation(CommandParameter);
	
	If NewConversation = "Unavailable" Or NewConversation = "DisabledNoEnableRight" Then
		ShowMessageBox(, NStr("ru = 'Использование обсуждений недоступно. Обратитесь к администратору.';
										|en = 'Conversations are not available. Contact the Administrator.';"));
		Return;
	ElsIf NewConversation = "DisabledCanEnable" Then
		SuggestConversationsText = 
			NStr("ru = 'Включить обсуждения?
				|
				|С их помощью пользователи смогут отправлять друг другу текстовые сообщения 
				|и совершать видеозвонки, создавать тематические обсуждения и вести переписку по документам.';
				|en = 'Do you want to enable conversations?
				|
				|With them, users will be able to exchange text messages, make video calls,
				|create themed conversations, and correspond on documents.';");
		CallbackOnCompletion = New NotifyDescription("SuggestDiscussionsCompletion", ThisObject);
		
		ShowQueryBox(CallbackOnCompletion, SuggestConversationsText, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	FileSystemClient.OpenURL(NewConversation);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SuggestDiscussionsCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ConversationsInternalClient.ShowConnection();
	
EndProcedure

&AtServer
Function NewConversation(UserRef)
	
	If Not ConversationsInternalServerCall.Connected2() Then
		If AccessRight("CollaborationSystemInfoBaseRegistration", Metadata) Then 
			Return "DisabledCanEnable";
		Else 
			Return "DisabledNoEnableRight";
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	InfoBaseUserID = Common.ObjectAttributeValue(
		UserRef, "IBUserID");
	SetPrivilegedMode(False);
	
	If Not ValueIsFilled(InfoBaseUserID) Then
		Return "Unavailable";
	EndIf;
	
	Try
		UserIDCollaborationSystem = CollaborationSystem.GetUserID(
			InfoBaseUserID);
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для начала обсуждения необходимо, чтобы пользователь %1
			           |хотя бы один раз запустил приложение.';
						|en = 'To start a conversation, user ""%1""
						|must run the application at least once.';"),
			UserRef);
	EndTry;
	
	If UserIDCollaborationSystem = CollaborationSystem.CurrentUserID() Then 
		Raise NStr("ru = 'Для начала обсуждения выберите другого пользователя.';
								|en = 'Select another user to start the conversation.';");
	EndIf;
	
	Conversation = CollaborationSystem.CreateConversation();
	Conversation.Group = False;
	Conversation.Members.Add(CollaborationSystem.CurrentUserID());
	Conversation.Members.Add(UserIDCollaborationSystem);
	Conversation.Write();
	
	Return GetURL(Conversation.ID);
	
EndFunction

#EndRegion
