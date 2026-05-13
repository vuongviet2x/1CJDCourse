///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Variables

&AtClient
Var AdministrationParameters, CurrentLockValue;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		SessionWithoutSeparators = ModuleSaaSOperations.SessionWithoutSeparators();
	Else
		SessionWithoutSeparators = True;
	EndIf;
	
	IsFileInfobase = Common.FileInfobase();
	IsSystemAdministrator = Users.IsFullUser(, True);
	
	If IsFileInfobase Or Not IsSystemAdministrator Then
		Items.DisableScheduledJobsGroup.Visible = False;
	EndIf;
	
	If Common.DataSeparationEnabled() Or Not IsSystemAdministrator Then
		Items.UnlockCode.Visible = False;
	EndIf;
	
	SetInitialUserAuthorizationRestrictionStatus();
	RefreshSettingsPage();
	
	If Not IBConnections.IsSubsystemUsed() Then
		Enabled = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ClientConnectedOverWebServer = CommonClient.ClientConnectedOverWebServer();
	If IBConnectionsClient.SessionTerminationInProgress() Then
		Items.GroupMode.CurrentPage = Items.LockStatePage;
		RefreshStatePage(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	BlockingSessionsInformation = IBConnections.BlockingSessionsInformation(NStr("ru = 'Блокировка не установлена.';
																					|en = 'The lock is not set.';"));
	
	If BlockingSessionsInformation.HasBlockingSessions Then
		Raise BlockingSessionsInformation.MessageText;
	EndIf;
	
	SessionCount = BlockingSessionsInformation.SessionCount;
	
	// Checking if a lock can be set.
	If Object.LockEffectiveFrom > Object.LockEffectiveTo 
		And ValueIsFilled(Object.LockEffectiveTo) Then
		Common.MessageToUser(
			NStr("ru = 'Дата окончания блокировки не может быть меньше даты начала блокировки. Блокировка не установлена.';
				|en = 'Cannot set a lock. The end date cannot be earlier than the start date.';"),,
			"Object.LockEffectiveTo",,Cancel);
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.LockEffectiveFrom) Then
		Common.MessageToUser(
			NStr("ru = 'Не указана дата начала блокировки.';
				|en = 'Please select the start date.';"),, "Object.LockEffectiveFrom",,Cancel);
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UsersSessions" Then
		SessionCount = Parameter.SessionCount;
		UpdateLockState(ThisObject);
		If Parameter.Status = "Done" Then
			Close();
		ElsIf Parameter.Status = "Error" Then
			ShowMessageBox(,NStr("ru = 'Не удалось завершить работу всех активных пользователей.
				|Подробности см. в Журнале регистрации.';
				|en = 'Cannot close all active user sessions.
				|See the Event log for details.';"), 30);
			Close();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ActiveUsers(Command)
	
	OpenForm("DataProcessor.ActiveUsers.Form",, ThisObject);
	
EndProcedure

&AtClient
Procedure Apply(Command)
	
	ClearMessages();
	
	Object.DisableUserAuthorisation = Not InitialUserAuthorizationRestrictionStatusValue;
	If Object.DisableUserAuthorisation Then
		
		SessionCount = 1;
		Try
			If Not CheckLockPreconditions() Then
				Return;
			EndIf;
		Except
			CommonClient.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			Return;
		EndTry;
		
		CurrentSessionDate = CommonClient.SessionDate();
		
		QuestionTitle = NStr("ru = 'Блокировка работы пользователей';
								|en = 'Deny user access';");
		If SessionCount > 1 And Object.LockEffectiveFrom < CurrentSessionDate + 10 * 60 Then
			QueryText = NStr("ru = 'Указано слишком близкое время начала действия блокировки, к которому пользователи могут не успеть сохранить все свои данные и завершить работу.
				|Рекомендуется установить время начала на 10 минут относительно текущего времени.';
				|en = 'The period before applying the lock is too short. Users might not have enough time to save their data.
				|It is recommended that you give them at least 10 minutes.';");
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.Yes, NStr("ru = 'Заблокировать через 10 минут';
														|en = 'Lock in 10 minutes';"));
			Buttons.Add(DialogReturnCode.No, NStr("ru = 'Заблокировать сейчас';
														|en = 'Lock now';"));
			Buttons.Add(DialogReturnCode.Cancel, NStr("ru = 'Отмена';
															|en = 'Cancel';"));
			Notification = New NotifyDescription("ApplyCompletion", ThisObject, "LockTimeTooSoon");
			ShowQueryBox(Notification, QueryText, Buttons,,, QuestionTitle);
		ElsIf Object.LockEffectiveFrom > CurrentSessionDate + 60 * 60 Then
			QueryText = NStr("ru = 'Указано слишком большое время начала действия блокировки (более, чем через час).
				|Запланировать блокировку на указанное время?';
				|en = 'The user lock is deferred for more than one hour.
				|Do you want to schedule the user lock for the specified time?';");
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.No, NStr("ru = 'Запланировать';
														|en = 'Schedule';"));
			Buttons.Add(DialogReturnCode.Yes, NStr("ru = 'Заблокировать сейчас';
														|en = 'Lock now';"));
			Buttons.Add(DialogReturnCode.Cancel, NStr("ru = 'Отмена';
															|en = 'Cancel';"));
			Notification = New NotifyDescription("ApplyCompletion", ThisObject, "LockTimeTooLate");
			ShowQueryBox(Notification, QueryText, Buttons,,, QuestionTitle);
		Else
			If Object.LockEffectiveFrom - CurrentSessionDate > 15*60 Then
				QueryText = NStr("ru = 'Завершение работы всех активных пользователей будет произведено в период с %1 по %2.
					|Продолжить?';
					|en = 'All active user sessions will be closed from %1 to %2.
					|Do you want to continue?';");
			Else
				QueryText = NStr("ru = 'Сеансы всех активных пользователей будут завершены к %2.
					|Продолжить?';
					|en = 'All active user sessions will be closed by %2.
					|Do you want to continue?';");
			EndIf;
			Notification = New NotifyDescription("ApplyCompletion", ThisObject, "Confirmation");
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(QueryText, Object.LockEffectiveFrom - 900, Object.LockEffectiveFrom);
			ShowQueryBox(Notification, QueryText, QuestionDialogMode.OKCancel,,, QuestionTitle);
		EndIf;
		
	Else
		
		Notification = New NotifyDescription("ApplyCompletion", ThisObject, "Confirmation");
		ExecuteNotifyProcessing(Notification, DialogReturnCode.OK);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplyCompletion(Response, Variant) Export
	
	CurrentSessionDate = CommonClient.SessionDate();
	
	If Variant = "LockTimeTooSoon" Or Variant = "LockTimeTooLate" Then
		If Response = DialogReturnCode.Yes Then
			Object.LockEffectiveFrom = CurrentSessionDate + 10 * 60;
		ElsIf Response <> DialogReturnCode.No Then
			Return;
		EndIf;
	ElsIf Variant = "Confirmation" Then
		If Response <> DialogReturnCode.OK Then
			Return;
		EndIf;
	EndIf;
	
	If CorrectAdministrationParametersEntered And IsSystemAdministrator And Not IsFileInfobase
		And CurrentLockValue <> Object.DisableScheduledJobs Then
		
		Try
			SetScheduledJobLockAtServer(AdministrationParameters);
		Except
			EventLogClient.AddMessageForEventLog(IBConnectionsClient.EventLogEvent(), "Error",
				ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
			Items.ErrorGroup.Visible = True;
			Items.ErrorText.Title = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			Return;
		EndTry;
		
	EndIf;
	
	If Not IsFileInfobase And Not CorrectAdministrationParametersEntered And SessionWithoutSeparators Then
		
		NotifyDescription = New NotifyDescription("AfterGetAdministrationParametersOnLock", ThisObject);
		FormCaption = NStr("ru = 'Управление блокировкой сеансов';
								|en = 'User sessions';");
		NoteLabel = NStr("ru = 'Для управления блокировкой сеансов введите
			|параметры администрирования кластера серверов и информационной базы';
			|en = 'To manage user sessions, enter
			|the infobase and server cluster administration parameters';");
		IBConnectionsClient.ShowAdministrationParameters(NotifyDescription, True,
			True, AdministrationParameters, FormCaption, NoteLabel);
		
	Else
		
		AfterGetAdministrationParametersOnLock(True, Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Stop(Command)
	
	If Not IsFileInfobase And Not CorrectAdministrationParametersEntered And SessionWithoutSeparators Then
		
		NotifyDescription = New NotifyDescription("AfterGetAdministrationParametersOnUnlock", ThisObject);
		FormCaption = NStr("ru = 'Управление блокировкой сеансов';
								|en = 'User sessions';");
		NoteLabel = NStr("ru = 'Для управления блокировкой сеансов введите
			|параметры администрирования кластера серверов и информационной базы';
			|en = 'To manage user sessions, enter
			|the infobase and server cluster administration parameters';");
		IBConnectionsClient.ShowAdministrationParameters(NotifyDescription, True,
			True, AdministrationParameters, FormCaption, NoteLabel);
		
	Else
		
		AfterGetAdministrationParametersOnUnlock(True, Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AdministrationParameters(Command)
	
	NotifyDescription = New NotifyDescription("AfterGetAdministrationParameters", ThisObject);
	FormCaption = NStr("ru = 'Управление блокировкой регламентных заданий';
							|en = 'Scheduled job locks';");
	NoteLabel = NStr("ru = 'Для управления блокировкой регламентных заданий введите
		|параметры администрирования кластера серверов и информационной базы';
		|en = 'To manage scheduled job locks, enter
		|the infobase and server cluster administration parameters';");
	IBConnectionsClient.ShowAdministrationParameters(NotifyDescription, True,
		True, AdministrationParameters, FormCaption, NoteLabel);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InitialUserAuthorizationRestrictionStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersAuthorizationRestrictionStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("ru = 'Запрещено';
										|en = 'Denied';");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InitialUserAuthorizationRestrictionStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersAuthorizationRestrictionStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("ru = 'Запланировано';
										|en = 'Scheduled';");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InitialUserAuthorizationRestrictionStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersAuthorizationRestrictionStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("ru = 'Истекло';
										|en = 'Expired';");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.LockedAttributeColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InitialUserAuthorizationRestrictionStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersAuthorizationRestrictionStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("ru = 'Разрешено';
										|en = 'Allowed';");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.FormTextColor);

EndProcedure

&AtServer
Function CheckLockPreconditions()
	
	Return CheckFilling();

EndFunction

&AtServer
Function LockUnlock()
	
	Try
		FormAttributeToValue("Object").PerformInstallation();
		Items.ErrorGroup.Visible = False;
	Except
		WriteLogEvent(IBConnections.EventLogEvent(),
			EventLogLevel.Error,,, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		If IsSystemAdministrator Then
			Items.ErrorGroup.Visible = True;
			Items.ErrorText.Title = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndIf;
		Return False;
	EndTry;
	
	SetInitialUserAuthorizationRestrictionStatus();
	SessionCount = IBConnections.InfobaseSessionsCount();
	Return True;
	
EndFunction

&AtServer
Function CancelLock()
	
	Try
		FormAttributeToValue("Object").CancelLock();
	Except
		WriteLogEvent(IBConnections.EventLogEvent(),
			EventLogLevel.Error,,, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		If IsSystemAdministrator Then
			Items.ErrorGroup.Visible = True;
			Items.ErrorText.Title = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndIf;
		Return False;
	EndTry;
	
	SetInitialUserAuthorizationRestrictionStatus();
	Items.GroupMode.CurrentPage = Items.SettingsPage;
	RefreshSettingsPage();
	Return True;
	
EndFunction

&AtServer
Procedure RefreshSettingsPage()
	
	Items.DisableScheduledJobsGroup.Enabled = True;
	Items.ApplyCommand.Visible = True;
	Items.ApplyCommand.DefaultButton = True;
	Items.StopCommand.Visible = False;
	Items.ApplyCommand.Title = ?(Object.DisableUserAuthorisation,
		NStr("ru = 'Снять блокировку';
			|en = 'Remove lock';"), NStr("ru = 'Установить блокировку';
												|en = 'Set lock';"));
	Items.DisableScheduledJobs.Title = ?(Object.DisableScheduledJobs,
		NStr("ru = 'Оставить блокировку работы регламентных заданий';
			|en = 'Keep scheduled job locks';"), NStr("ru = 'Также запретить работу регламентных заданий';
																			|en = 'Lock scheduled jobs';"));
	
EndProcedure

&AtClientAtServerNoContext
Procedure RefreshStatePage(Form)
	
	Form.Items.DisableScheduledJobsGroup.Enabled = False;
	Form.Items.StopCommand.Visible = True;
	Form.Items.ApplyCommand.Visible = False;
	Form.Items.CloseCommand.DefaultButton = True;
	UpdateLockState(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateLockState(Form)
	
	If Form.SessionCount = 0 Then
		
		StateText = NStr("ru = 'Ожидается установка блокировки...
			|Работа пользователей в приложении будет запрещена в указанное время';
			|en = 'Lock pending…
			|Users will be unable to use the app while the lock is set.';");
		
	Else
		
		StateText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Пожалуйста, подождите...
			|Работа пользователей завершается. Осталось активных сеансов: %1';
			|en = 'Please wait…
			|Closing user sessions. Active sessions remaining: %1.';"),
			Form.SessionCount);
			
	EndIf;
	
	Form.Items.State.Title = StateText;
	
EndProcedure

&AtServer
Procedure GetLockParameters()
	DataProcessor = FormAttributeToValue("Object");
	Try
		DataProcessor.GetLockParameters();
		Items.ErrorGroup.Visible = False;
	Except
		WriteLogEvent(IBConnections.EventLogEvent(),
			EventLogLevel.Error,,, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		If IsSystemAdministrator Then
			Items.ErrorGroup.Visible = True;
			Items.ErrorText.Title = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndIf;
	EndTry;
	
	ValueToFormAttribute(DataProcessor, "Object");
	
EndProcedure

&AtServer
Procedure SetInitialUserAuthorizationRestrictionStatus()
	
	GetLockParameters();
	
	InitialUserAuthorizationRestrictionStatusValue = Object.DisableUserAuthorisation;
	If Object.DisableUserAuthorisation Then
		If CurrentSessionDate() < Object.LockEffectiveFrom Then
			InitialUserAuthorizationRestrictionStatus = NStr("ru = 'Работа пользователей в приложении будет запрещена в указанное время';
															|en = 'Users will be denied access to the application at the specified time';");
			UsersAuthorizationRestrictionStatus = "Scheduled";
		ElsIf CurrentSessionDate() > Object.LockEffectiveTo And Object.LockEffectiveTo <> '00010101' Then
			InitialUserAuthorizationRestrictionStatus = NStr("ru = 'Работа пользователей в приложении разрешена (истек срок запрета)';
															|en = 'Users are allowed to log in to the application (the lock has expired)';");
			UsersAuthorizationRestrictionStatus = "Expired";
		Else
			InitialUserAuthorizationRestrictionStatus = NStr("ru = 'Работа пользователей в приложении запрещена';
															|en = 'Users are denied access to the application';");
			UsersAuthorizationRestrictionStatus = "Prohibited";
		EndIf;
	Else
		InitialUserAuthorizationRestrictionStatus = NStr("ru = 'Работа пользователей в приложении разрешена';
														|en = 'Users can access the application';");
		UsersAuthorizationRestrictionStatus = "Allowed1";
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterGetAdministrationParameters(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		AdministrationParameters = Result;
		CorrectAdministrationParametersEntered = True;
		
		Try
			Object.DisableScheduledJobs = InfobaseScheduledJobLockAtServer(AdministrationParameters);
			CurrentLockValue = Object.DisableScheduledJobs;
		Except;
			CorrectAdministrationParametersEntered = False;
			Raise;
		EndTry;
		
		Items.DisableScheduledJobsGroup.CurrentPage = Items.ScheduledJobManagementGroup;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterGetAdministrationParametersOnLock(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf TypeOf(Result) = Type("Structure") Then
		AdministrationParameters = Result;
		CorrectAdministrationParametersEntered = True;
		EnableScheduledJobLockManagement();
		IBConnectionsClient.SaveAdministrationParameters(AdministrationParameters);
	ElsIf TypeOf(Result) = Type("Boolean") And CorrectAdministrationParametersEntered Then
		IBConnectionsClient.SaveAdministrationParameters(AdministrationParameters);
	EndIf;
	
	If Not LockUnlock() Then
		Return;
	EndIf;
	
	IBConnectionsClient.SetTheUserShutdownMode(Object.DisableUserAuthorisation);
	
	If Object.DisableUserAuthorisation Then
		Items.GroupMode.CurrentPage = Items.LockStatePage;
		RefreshStatePage(ThisObject);
	Else
		Items.GroupMode.CurrentPage = Items.SettingsPage;
		RefreshSettingsPage();
	EndIf;
	
	ShowUserNotification(NStr("ru = 'Блокировка работы пользователей';
										|en = 'User access';"),
		New NotifyDescription("OpeningHandlerOfAppWorkBlockForm", IBConnectionsClient),
		?(Object.DisableUserAuthorisation, NStr("ru = 'Блокировка установлена.';
													|en = 'User access is denied.';"), NStr("ru = 'Блокировка снята.';
																							|en = 'User access is allowed.';")),
		PictureLib.DialogInformation);
	
EndProcedure

&AtClient
Procedure AfterGetAdministrationParametersOnUnlock(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf TypeOf(Result) = Type("Structure") Then
		AdministrationParameters = Result;
		CorrectAdministrationParametersEntered = True;
		EnableScheduledJobLockManagement();
		IBConnectionsClient.SaveAdministrationParameters(AdministrationParameters);
	ElsIf TypeOf(Result) = Type("Boolean") And CorrectAdministrationParametersEntered Then
		IBConnectionsClient.SaveAdministrationParameters(AdministrationParameters);
	EndIf;
	
	If Not CancelLock() Then
		Return;
	EndIf;
	
	IBConnectionsClient.SetTheUserShutdownMode(False);
	ShowMessageBox(,NStr("ru = 'Завершение работы активных пользователей отменено.';
								|en = 'Closing active user sessions is canceled.';"));
	
EndProcedure

&AtClient
Procedure EnableScheduledJobLockManagement()
	
	Object.DisableScheduledJobs = InfobaseScheduledJobLockAtServer(AdministrationParameters);
	CurrentLockValue = Object.DisableScheduledJobs;
	Items.DisableScheduledJobsGroup.CurrentPage = Items.ScheduledJobManagementGroup;
	
EndProcedure

&AtServer
Procedure SetScheduledJobLockAtServer(AdministrationParameters)
	
	ClusterAdministration.SetInfobaseScheduledJobLock(
		AdministrationParameters, Undefined, Object.DisableScheduledJobs);
	
EndProcedure

&AtServer
Function InfobaseScheduledJobLockAtServer(AdministrationParameters)
	
	Return ClusterAdministration.InfobaseScheduledJobLock(AdministrationParameters);
	
EndFunction

#EndRegion