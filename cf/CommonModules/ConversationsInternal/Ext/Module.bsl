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
	
	// A server call makes sure the correct state is obtained if the infobase registration data
	// was modified by the method "CollaborationSystem.SetInfoBaseRegistrationData". 
	// It runs faster and doesn't make calls to the Collaboration server.
	//
	// 
	CanUse = CollaborationSystem.CanUse();
	
	Return CanUse And Not Locked2();
	
EndFunction

Function Locked2() Export
	
	SetPrivilegedMode(True);
	RegistrationDetails = Common.ReadDataFromSecureStorage(
		"CollaborationSystemInfoBaseRegistrationData");
	Locked2 = RegistrationDetails <> Undefined;
	Return Locked2;
	
EndFunction

Procedure Lock() Export 
	
	If Not AccessRight("DataAdministration", Metadata) Then 
		Raise 
			NStr("ru = 'Обсуждения не заблокированы. Для выполнения операции требуется право администрирования данных.';
				|en = 'Conversations are not locked. To perform the operation, you need to have data administration rights.';");
	EndIf;
	
	If Locked2() Then 
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	RegistrationDetails = CollaborationSystem.GetInfoBaseRegistrationData();
	If TypeOf(RegistrationDetails) = Type("CollaborationSystemInfoBaseRegistrationData") Then
		Common.WriteDataToSecureStorage(
			"CollaborationSystemInfoBaseRegistrationData", 
			RegistrationDetails);
	EndIf;
	CollaborationSystem.SetInfoBaseRegistrationData(Undefined);
	
EndProcedure

Procedure Unlock() Export 
	
	If Not AccessRight("DataAdministration", Metadata) Then 
		Raise 
			NStr("ru = 'Обсуждения не заблокированы. Для выполнения операции требуется право администрирования данных.';
				|en = 'Conversations are not locked. To perform the operation, you need to have data administration rights.';");
	EndIf;
	
	SetPrivilegedMode(True);
	RegistrationDetails = Common.ReadDataFromSecureStorage(
		"CollaborationSystemInfoBaseRegistrationData");
	Common.DeleteDataFromSecureStorage("CollaborationSystemInfoBaseRegistrationData");
	If TypeOf(RegistrationDetails) = Type("CollaborationSystemInfoBaseRegistrationData") Then 
		CollaborationSystem.SetInfoBaseRegistrationData(RegistrationDetails);
	EndIf;
	RegistrationDetails = Undefined;
	
EndProcedure

// Parameters:
//  Cancel - Boolean
//  Form - ClientApplicationForm
//        - ManagedFormExtensionForObjects
//  Object - FormDataStructure
//         - CatalogObject.Users
//
Procedure OnCreateAtUserServer(Cancel, Form, Object) Export
	
	If Not AccessRight("DataAdministration", Metadata) Then
		Form.SuggestDiscussions = False;
		Return;
	EndIf;
	
	SuggestDiscussions = Common.CommonSettingsStorageLoad("ApplicationSettings", "SuggestDiscussions", True);
	Form.SuggestDiscussions = Not Cancel And Not ValueIsFilled(Object.Ref) And SuggestDiscussions 
		And Not ConversationsInternalServerCall.Connected2();
	If Not Form.SuggestDiscussions Then
		Return;
	EndIf;
	
	AdministrationSubsystem = Metadata.Subsystems.Find("Administration");
	If AdministrationSubsystem <> Undefined Then 
		EnableLater = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Включить обсуждения также можно позднее из раздела %1.';
				|en = 'You can also enable conversations later from the %1 section.';"),
			AdministrationSubsystem.Synonym);
	Else
		EnableLater = NStr("ru = 'Включить обсуждения также можно позднее из настроек приложения.';
								|en = 'You can also enable conversations later from the app settings.';");
	EndIf;
	
	Form.SuggestConversationsText = 
		NStr("ru = 'Включить обсуждения?
			       |
			       |С их помощью пользователи смогут отправлять друг другу текстовые сообщения и совершать видеозвонки, создавать тематические обсуждения и вести переписку по документам.';
					|en = 'Do you want to enable conversations?
					|
					|With them, users will be able to exchange text messages, make video calls, create themed conversations, and correspond on documents.';")
			+ Chars.LF + Chars.LF + EnableLater;
	
EndProcedure

#Region ForCallsFromOtherSubsystems

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources.
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	Permissions = New Array;
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	Resolution = ModuleSafeModeManager.PermissionToUseInternetResource("WSS", "1cdialog.com", 443, 
		NStr("ru = 'Сервис 1С:Диалог для системы взаимодействия (тематические обсуждения, переписка и видеозвонки между пользователями приложения).';
			|en = '1C:Dialog service for Collaboration System (provides chat rooms, messaging, and video calls).';"));
	Permissions.Add(Resolution);
	Resolution = ModuleSafeModeManager.PermissionToUseInternetResource("HTTPS", "*.s3storage.ru", 443, 
		NStr("ru = 'Сервис 1С:Диалог для системы взаимодействия (Хранилище файлов сервиса).';
			|en = '1C:Dialog service for Collaboration System (Service file storage).';"));
	Permissions.Add(Resolution);
	Resolution = ModuleSafeModeManager.PermissionToUseInternetResource("HTTP", "clr.globalsign.com", 80, 
		NStr("ru = 'Сервис 1С:Диалог для системы взаимодействия (Сервер проверки отзыва сертификатов).';
			|en = '1C:Dialog service for Collaboration System (Certificate revocation check server).';"));
	Permissions.Add(Resolution);
	PermissionsRequests.Add(ModuleSafeModeManager.RequestToUseExternalResources(Permissions));
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Version = "3.1.3.282";
	Handler.Id = New UUID("b3be68c5-708d-42c9-a019-818036d09d06");
	Handler.Procedure = "ConversationsInternal.LockInvalidUsersInCollaborationSystem";
	Handler.ExecutionMode = "Deferred";
	Handler.Comment = NStr("ru = 'Блокировка недействительных пользователей в системе взаимодействия.';
									|en = 'Disable inactive users in the Collaboration System.';");
	Handler.UpdateDataFillingProcedure = "ConversationsInternal.UsersToBlockInteractionsInTheSystem";
	Handler.ObjectsToRead = "Catalog.Users";
	Handler.ObjectsToChange = "CollaborationSystemUser";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
EndProcedure

// Locks a collaboration system user. 
// If errors occur when locking, ErrorInfo is returned.
// If the user is locked, Undefined is returned.
//
// Parameters:
//    User - CatalogRef.Users
//
// Returns:
//  ErrorInfo, Undefined
//
Function BlockAnInteractionSystemUser(User) Export

	Result = Undefined;
	IBUserID = Common.ObjectAttributeValue(User, "IBUserID");
	If Not ValueIsFilled(IBUserID) Then
		Return Result;
	EndIf;
	
	UserIDCollaborationSystem = Undefined;
	Try
		UserIDCollaborationSystem = CollaborationSystem.GetUserID(
			IBUserID);
	Except
		// ACC:280 - A thrown exception means the Collaboration System user was not found.
	EndTry;
	
	If UserIDCollaborationSystem = Undefined Then
		Return Result;
	EndIf;	
	
	ThePatternOfLogRecording = NStr("ru = 'Пользователь %1 недействителен. Пользователь системы взаимодействий заблокирован';
											|en = 'The %1 user is invalid. The collaboration system user is locked';");
	Try
		CollaborationSystemUser = CollaborationSystem.GetUser(UserIDCollaborationSystem);
		CollaborationSystemUser.IsLocked = True;
		CollaborationSystemUser.Write();
		WriteLogEvent(
			EventLogEvent(NStr("ru = 'Блокировка недействительных пользователей';
											|en = 'Disable inactive users';", Common.DefaultLanguageCode())),
			EventLogLevel.Information,, User,
			StringFunctionsClientServer.SubstituteParametersToString(ThePatternOfLogRecording, User));
	Except
		Result = ErrorInfo();
	EndTry;
	
	Return Result;
EndFunction

// Returns an array of users who must be locked in the collaboration system.
//
// Returns:
//    Array of CatalogRef.Users
//
Function InvalidUsers() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Users.Ref AS Ref
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Invalid
	|	 OR Users.DeletionMark";
	Result = Query.Execute().Unload();
	ReferencesArrray = Result.UnloadColumn("Ref");
	Return ReferencesArrray;

EndFunction

Procedure UsersToBlockInteractionsInTheSystem(Parameters) Export

	If Not Connected2() Then
		Return;
	EndIf;
	
	ReferencesArrray = InvalidUsers();
    InfobaseUpdate.MarkForProcessing(Parameters, ReferencesArrray);

EndProcedure

Procedure LockInvalidUsersInCollaborationSystem(ParametersOfUpdate) Export

	FullMetadataObjectName = "Catalog.Users";
	Users_Selection = InfobaseUpdate.SelectRefsToProcess(ParametersOfUpdate.Queue, FullMetadataObjectName);
			
	ObjectsWithErrors = 0;
	TextOfTheLastError = "";
	While Users_Selection.Next() Do
		User = Users_Selection.Ref;
		InfobaseUpdate.MarkProcessingCompletion(User); // If the processing fails, manual adjustment is available.
 		Error = BlockAnInteractionSystemUser(User);
		If Error <> Undefined Then
			ObjectsWithErrors = ObjectsWithErrors + 1;
			TextOfTheLastError = ErrorProcessing.DetailErrorDescription(Error);
		EndIf;
	EndDo;
	
	If ObjectsWithErrors > 0 Then
		
		LogError = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось заблокировать пользователей в системе взаимодействия: %1.
					|Возможно, система взаимодействия временно недоступна.
					|Для блокировки нажмите ""Заблокировать недействительных в системе взаимодействия"" в подменю Еще списка пользователей.';
					|en = 'Cannot disable users in the Collaboration System: %1.
					|The Collaboration System might be temporarily unavailable.
					|To disable users, click ""Disable inactive users in Collaboration System"" in the ""More actions"" menu of the user list.';") + Chars.LF,
			ObjectsWithErrors);

		WriteLogEvent(
			EventLogEvent(NStr("ru = 'Блокировка недействительных пользователей';
											|en = 'Disable inactive users';", Common.DefaultLanguageCode())),
			EventLogLevel.Warning,,,
			StringFunctionsClientServer.SubstituteParametersToString(LogError, ObjectsWithErrors)
			+ Chars.LF + TextOfTheLastError);
	
	EndIf;
	
	ParametersOfUpdate.ProcessingCompleted = True;

EndProcedure

#EndRegion

#EndRegion

#Region Private

// Returns:
//  Structure:
//   * Id - Undefined
// 				   - CollaborationSystemIntegrationID
//   * Key - String
//   * Type - String
//   * Attendees - Array
//   * token - String
//   * groupId - String
//
Function IntegrationParameters() Export
	IntegrationParameters = New Structure;
	
	IntegrationParameters.Insert("Id");
	IntegrationParameters.Insert("Key", ""); 
	IntegrationParameters.Insert("Type", "");
	IntegrationParameters.Insert("Attendees", New Array);
	IntegrationParameters.Insert("token", "");
	IntegrationParameters.Insert("groupId", "");
	
	Return IntegrationParameters;
EndFunction

Function EventLogEvent(EventDetails = "") Export
	Return NStr("ru = 'Обсуждения';
				|en = 'Conversations';", Common.DefaultLanguageCode())
		+ ?(IsBlankString(EventDetails), "", "."+EventDetails);
EndFunction

Procedure CreateChangeIntegration(Parameters) Export

	Id = CommonClientServer.StructureProperty(Parameters, "Id");
	If Id <> Undefined Then
		NewIntegration = CollaborationSystem.GetIntegration(Id);
	Else
		NewIntegration = CollaborationSystem.CreateIntegration();
	EndIf;
	
	NewIntegration.ExternalSystemType = Parameters.Type;
	NewIntegration.Presentation = Parameters.Key;
	NewIntegration.Key = Parameters.Key;
	NewIntegration.Use = True;
	ExternalSystemDetails = CollaborationSystem.GetExternalSystemDescription(Parameters.Type);
	
	NotGivenParameters = New Array;
	For Each IntegrationParameter In ExternalSystemDetails.ParametersDescriptions Do
		If Not Parameters.Property(IntegrationParameter.Name) Then
			If IntegrationParameter.Required Then
				NotGivenParameters.Add(IntegrationParameter.Name);
			EndIf;
		Else
			NewIntegration.ExternalSystemParameters.Insert(IntegrationParameter.Name, Parameters[IntegrationParameter.Name]);
		EndIf;
	EndDo;
	
	If NotGivenParameters.Count() > 0 Then
		Raise NStr("ru = 'Не заполнены параметры интеграции: 
			|%1';
			|en = 'Integration parameters are not specified:
			|%1';", StrConcat(NotGivenParameters, Chars.LF + "- "));
	EndIf;
	
	NewIntegration.Members.Clear();
	For Each Member In Conversations.CollaborationSystemUsers(Parameters.Attendees) Do
	    If Member.Value <> Undefined Then
			NewIntegration.Members.Add(Member.Value.ID);
		EndIf;
	EndDo;
	
	NewIntegration.Write();
EndProcedure

Procedure DisableIntegration(Id) Export

	Integration = CollaborationSystem.GetIntegration(Id);
	Integration.Use = False;
	Integration.Write();

EndProcedure

#EndRegion