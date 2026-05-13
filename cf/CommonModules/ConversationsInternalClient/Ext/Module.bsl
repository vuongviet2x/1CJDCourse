///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Internal

Function Connected2() Export
	
	Return ConversationsInternalServerCall.Connected2();
	
EndFunction

Procedure ShowConnection(CompletionDetails = Undefined) Export
	
	OpenForm("DataProcessor.EnableDiscussions.Form",,,,,, CompletionDetails);
	
EndProcedure

Procedure ShowDisconnection() Export
	
	If Not ConversationsInternalServerCall.Connected2() Then 
		ShowMessageBox(, NStr("ru = 'Обсуждения уже отключены ранее.';
										|en = 'Conversations are already disabled.';"));
		Return;
	EndIf;
	
	Buttons = New ValueList;
	Buttons.Add("Disconnect", NStr("ru = 'Отключить';
										|en = 'Disable';"));
	Buttons.Add(DialogReturnCode.No);
	
	Notification = New NotifyDescription("AfterResponseToDisablePrompt", ThisObject);
	
	ShowQueryBox(Notification, NStr("ru = 'Отключить обсуждения?';
									|en = 'Do you want to disable conversations?';"),
		Buttons,, DialogReturnCode.No);
	
EndProcedure

Procedure AfterWriteUser(Form, CompletionDetails) Export
	
	If Not Form.SuggestDiscussions Then
		ExecuteNotifyProcessing(CompletionDetails);
		Return;
	EndIf;
	
	Form.SuggestDiscussions = False;
		
	CallbackOnCompletion = New NotifyDescription("SuggestDiscussionsCompletion", ThisObject, CompletionDetails);
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.PromptDontAskAgain = True;
	QuestionParameters.Title = NStr("ru = 'Обсуждения (система взаимодействий)';
										|en = 'Conversations (collaboration system)';");
	StandardSubsystemsClient.ShowQuestionToUser(CallbackOnCompletion, Form.SuggestConversationsText,
		QuestionDialogMode.YesNo, QuestionParameters);
	
EndProcedure

Procedure OnGetCollaborationSystemUsersChoiceForm(ChoicePurpose, Form, ConversationID, Parameters, SelectedForm, StandardProcessing) Export

	Parameters.Insert("SelectConversationParticipants", True);
	Parameters.Insert("ChoiceMode", True);
	Parameters.Insert("CloseOnChoice", False);
	Parameters.Insert("MultipleChoice", True);
	Parameters.Insert("AdvancedPick", True);
	Parameters.Insert("SelectedUsers", New Array);
	Parameters.Insert("PickFormHeader", NStr("ru = 'Участники обсуждения';
													|en = 'Conversation members';"));
	
	StandardProcessing = False;
	
	SelectedForm = "Catalog.Users.ChoiceForm";

EndProcedure

Procedure ShowSettingOfIntegrationWithExternalSystems() Export
	OpenForm("DataProcessor.EnableDiscussions.Form.SettingsOfMessagesFromOtherApplications",,ThisObject);
EndProcedure

Procedure OnStart(Parameters) Export
	
	CommandsGenerationHandler = New NotifyDescription("AddConversationsCommands", ThisObject);
	CollaborationSystem.AttachGenerateCommandsHandler(CommandsGenerationHandler);
	
EndProcedure

#EndRegion

#Region Private

Procedure StartPickingConversationParticipants(Item) Export
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CloseOnChoice", False);
	FormParameters.Insert("MultipleChoice", True);
	FormParameters.Insert("AdvancedPick", True);
	FormParameters.Insert("SelectedUsers", New Array);
	FormParameters.Insert("PickFormHeader", NStr("ru = 'Участники обсуждения';
															|en = 'Conversation members';"));
	
	OpenForm("Catalog.Users.ChoiceForm", FormParameters,Item,,,,,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

Procedure ShowIntegrationInformation(Form, IntegrationDetails, IntegrationChangeNotification) Export

	Notification = New NotifyDescription("IntegrationCreationCompletion", ThisObject,
		New Structure("Notification", IntegrationChangeNotification));
		
	IntegrationTypes = ConversationsInternalClientServer.ExternalSystemsTypes();
	FormName = "DataProcessor.EnableDiscussions.Form";
	If IntegrationDetails.Type = IntegrationTypes.Telegram Then
		FormName = FormName + ".BotCreationTelegram";
	ElsIf IntegrationDetails.Type = IntegrationTypes.VKontakte Then	
		FormName = FormName + ".BotCreationVKontakte";
	EndIf;
		
	OpenForm(FormName, IntegrationDetails, Form,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

Procedure IntegrationCreationCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(AdditionalParameters.Notification, True);

EndProcedure

Procedure AfterResponseToDisablePrompt(ReturnCode, Context) Export
	
	If ReturnCode = "Disconnect" Then 
		OnDisconnect();
	EndIf;
	
EndProcedure

Procedure OnDisconnect()
	
	Notification = New NotifyDescription("AfterDisconnectSuccessfully", ThisObject,,
		"OnProcessDisableDiscussionError", ThisObject);
	
	Try
		CollaborationSystem.BeginInfoBaseUnregistration(Notification);
	Except
		OnProcessDisableDiscussionError(ErrorInfo(), False, Undefined);
	EndTry;
	
EndProcedure

Procedure AfterDisconnectSuccessfully(Context) Export
	
	Notify("ConversationsEnabled", False);
	
EndProcedure

Procedure OnProcessDisableDiscussionError(ErrorInfo, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	
	EventLogClient.AddMessageForEventLog(
		NStr("ru = 'Обсуждения.Ошибка отмены регистрации информационной базы';
			|en = 'Conversations.An error occurred when unregistering infobase';",
			CommonClient.DefaultLanguageCode()),
		"Error",
		ErrorProcessing.DetailErrorDescription(ErrorInfo),, True);
	
	StandardSubsystemsClient.OutputErrorInfo(ErrorInfo);
	
EndProcedure

Procedure SuggestDiscussionsCompletion(Result, CompletionDetails) Export
	
	If Result = Undefined Then
		ExecuteNotifyProcessing(CompletionDetails);
		Return;
	EndIf;
	
	If Result.NeverAskAgain Then
		CommonServerCall.CommonSettingsStorageSave("ApplicationSettings", "SuggestDiscussions", False);
	EndIf;
	
	If Result.Value = DialogReturnCode.Yes Then
		ShowConnection();
		Return;
	EndIf;
	ExecuteNotifyProcessing(CompletionDetails);
	
EndProcedure

Procedure AddConversationsCommands(CommandParameters_, Commands, DefaultCommand, AdditionalParameters) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.UserReminders") Then
		ModuleUserReminderInternalClient = CommonClient.CommonModule("UserRemindersInternalClient");
		ModuleUserReminderInternalClient.AddConversationsCommands(CommandParameters_, Commands, DefaultCommand);
	EndIf;
		
EndProcedure

#EndRegion