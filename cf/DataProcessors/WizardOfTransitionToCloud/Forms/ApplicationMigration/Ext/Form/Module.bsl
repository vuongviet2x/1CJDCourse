
#Region Variables

&AtClient
Var CloseOfCourse;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ScheduledJobsServer.OperationsWithExternalResourcesLocked() Then
		Raise NStr("ru = 'Работа со всеми внешними ресурсами (синхронизация данных, отправка почты и т.п.) заблокирована.';
								|en = 'Scheduled online activities such as data synchronization and emailing are disabled.';");
	EndIf;
	
	ServiceAddress = ?(Service = "Other", "", Service);
	
	FillPropertyValues(ThisObject, TransitionState());
	
	If State <> Enums.ApplicationMigrationStates.Running Then
		
		Description = StrTemplate(NStr("ru = '%1 (Миграция приложения)';
										|en = '%1 (Application migration)';"), Metadata.Synonym);
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Users.Ref AS Ref,
		|	Users.IBUserID
		|FROM
		|	Catalog.Users AS Users";
	Result = Query.Execute().Unload();
	If Result.Count() = 0 Then
		StepsCount = 3;
	ElsIf Result.Count() = 1 And Not ValueIsFilled(Result[0].IBUserID) Then
		StepsCount = 3;
	Else
		StepsCount = 4;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	OnOpenForm();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Or CloseOfCourse = True Then
		Return;
	EndIf;
	
	If ValueIsFilled(Job) Then
		Cancel = True;
		ShowWarningMonopolyModeIsSet();
		Return;
	EndIf;
	
	If ValueIsFilled(StartDate) Then
		Return;
	EndIf;
	
	Cancel = True;
	StandardProcessing = False;
	NotifyDescription = New NotifyDescription("BeforeClosingAlert", ThisObject);
	QueryText = NStr("ru = 'Закрыть помощник?';
						|en = 'Do you want to close the assistant?';");
	ShowQueryBox(NotifyDescription, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	If Items.Pages.CurrentPage = Items.CreateApplicationPage Then
		NewPage = PageCreateApplicationNext();
	ElsIf Items.Pages.CurrentPage = Items.PageWait Then
		NewPage = WaitingPageNext();
	ElsIf Items.Pages.CurrentPage = Items.ResultPage Then
		NewPage = PageResultNext();
	ElsIf Items.Pages.CurrentPage = Items.ErrorPage Then
		NewPage = ErrorPageNext();
	EndIf;
	
	If NewPage <> Undefined Then
		OpeningPage(NewPage);
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	If Items.Pages.CurrentPage = Items.PageWait Then
	
		CancelTransition();
		DisableServiceStatusUpdateHandler();
		ApplicationParameters.Delete(ApplicationsMigrationClient.NameOfTransitionForm());
		
		OpeningPage(Items.ResultPage);
		
	EndIf;

EndProcedure

&AtClient
Procedure Back(Command)
	
	Page = Items[PagesStack[PagesStack.Count() - 2].Value];
	If Page = Items.PageRegistrationConfirmation Then
		Page = Items[PagesStack[PagesStack.Count() - 3].Value];
	EndIf;
	
	OpeningPage(Page);
	
EndProcedure

#EndRegion

#Region Private

#Region PageHandlers

&AtClient
Procedure OpeningPage(Page)
	
	Items.Next.Visible = True;
	Items.Next.Enabled = True;
	Items.Next.Title = NStr("ru = 'Далее';
									|en = 'Next';");
	
	Items.Cancel.Visible = False;
	Items.Cancel.Title = NStr("ru = 'Отмена';
									|en = 'Cancel';");
	
	Items.Back.Visible = True;
	
	FoundItem = PagesStack.FindByValue(Page.Name);
	If FoundItem = Undefined Then
		PagesStack.Add(Page.Name);
	Else
		RepeatCount = PagesStack.Count() - PagesStack.IndexOf(FoundItem) - 1;
		For RepeatNumber = 1 To RepeatCount Do
			PagesStack.Delete(PagesStack.Count() - 1);
		EndDo;
	EndIf;
	ItSBackwardsTransition = FoundItem <> Undefined;
	
	If Page = Items.CreateApplicationPage Then
		PageCreateAppOpen(ItSBackwardsTransition);
	ElsIf Page = Items.PageWait Then
		WaitingPageOpening(ItSBackwardsTransition);
	ElsIf Page = Items.ErrorPage Then
		PageErrorOpening(ItSBackwardsTransition);
	ElsIf Page = Items.ResultPage Then
		OpeningResultPage(ItSBackwardsTransition);
	EndIf;
	
	Items.Pages.CurrentPage = Page;
	
EndProcedure

&AtClient
Function PageCreateApplicationNext()
	
	Cancel = False;
	If Not ValueIsFilled(Description) Then
		CommonClient.MessageToUser(
			NStr("ru = 'Не заполнено поле ""Наименование""';
				|en = 'The Description field is required.';"), , "Description", , Cancel);
	EndIf;
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	BeginSeek();
	
	Return Items.PageWait;
	
EndFunction

&AtClient
Procedure PageCreateAppOpen(ItSBackwardsTransition)
	
	Title = StrTemplate(NStr("ru = 'Шаг %1 из %1: Параметры создания приложения';
								|en = 'Step %1 out of %1: Application creation parameters';"), StepsCount);
	Items.Next.Title = NStr("ru = 'Начать миграцию';
									|en = 'Start migration';");
	Items.Back.Visible = False;
	
	If Not ValueIsFilled(Description) Then
		Description = "";
	EndIf;
	
EndProcedure

&AtClient
Function WaitingPageNext()
	
	Job = RunMonopolyCompletion();
	
	If ValueIsFilled(Job) Then
		BlockEntireInterface();
		ShowWarningMonopolyModeIsSet();
	Else
		Text = NStr("ru = 'Не удалось установить монопольный режим, необходимо завершение сеансов всех пользователей.';
					|en = 'Cannot set the exclusive mode, close the sessions of all users.';");
		ShowMessageBox(, Text);
	EndIf;

	Return Undefined;
	
EndFunction

&AtClient
Procedure WaitingPageOpening(ItSBackwardsTransition)
	
	ApplicationParameters[ApplicationsMigrationClient.NameOfTransitionForm()] = ThisObject;
	
	Items.Next.Visible = ExclusiveModeRequired;
	Items.Next.Title = NStr("ru = 'Завершить миграцию';
									|en = 'Complete migration';");
	Items.Next.Enabled = Not ValueIsFilled(Job);
	Title = ?(ValueIsFilled(Job), 
		NStr("ru = 'Завершение миграции...';
			|en = 'Completing migration…';"), 
		NStr("ru = 'Выполняется миграция...';
			|en = 'Migrating…';"));
	Items.Cancel.Visible = True;
	Items.Back.Visible = False;
	
	LF = Chars.LF;
	Tab = Chars.Tab;
	
	Rows = New Array;
	Rows.Add(NStr("ru = 'Адрес сервиса';
						|en = 'Service address';") + ": ");
	Rows.Add(New FormattedString(ServiceAddress, , , , ServiceAddress));
	Rows.Add(LF);
	Rows.Add(StrTemplate(NStr("ru = 'Код абонента: %1';
									|en = 'Subscriber code: %1';"), SubscriberCode) + LF);
	Rows.Add(StrTemplate(NStr("ru = 'Код приложения: %1';
									|en = 'Application code: %1';"), ApplicationCode) + LF);
	Rows.Add(NStr("ru = 'Контакты обслуживающей организации';
						|en = 'Service company contacts';") + ":" + LF);
	Rows.Add(Tab);
	Rows.Add(Tab + StrTemplate(NStr("ru = 'e-mail: %1';
										|en = 'e-mail: %1';"), ServiceCompanyEmail) + LF);
	Rows.Add(Tab);
	Rows.Add(Tab + StrTemplate(NStr("ru = 'тел.: %1';
										|en = 'phone: %1';"), ServiceCompanyPhoneNumber) + LF);
	
	Items.InformationDecoration.Title = New FormattedString(Rows);
	
	EnableServiceStatusUpdateHandler();
	
EndProcedure

&AtClient
Function PageResultNext()
	
	ClearUploadState();
	Close();
	Return Undefined;
	
EndFunction

&AtClient
Procedure OpeningResultPage(ItSBackwardsTransition)
	
	Title = NStr("ru = 'Результат миграции';
					|en = 'Migration result';");
	
	Items.Next.Title = NStr("ru = 'Готово';
									|en = 'Done';");
	Items.Cancel.Visible = False;
	Items.Back.Visible = False;
	
	Items.DecorationRef.Visible = ValueIsFilled(ApplicationURL);
	If ValueIsFilled(ApplicationURL) Then
		Items.DecorationRef.Title = New FormattedString(ApplicationURL, , , , ApplicationURL);
	EndIf;
	
EndProcedure

&AtClient
Function ErrorPageNext()
	
	ClearUploadState();
	ApplicationParameters.Delete(ApplicationsMigrationClient.NameOfTransitionForm());
	Close();
	Return Undefined;
	
EndFunction

&AtClient
Procedure PageErrorOpening(ItSBackwardsTransition)
	
	Title = NStr("ru = 'Ошибка миграции';
					|en = 'Migration error';");
	
	Items.Next.Title = NStr("ru = 'Готово';
									|en = 'Done';");
	Items.Cancel.Visible = False;
	Items.Back.Visible = False;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure BeginSeek()
	
	ApplicationsMigration.ValidateExchangePlanContent();
	
	ApplicationData = ApplicationsMigration.CreateMigrationApplication(
		ThisObject, Description, SessionTimeZone(), UsersRights, RecoveryExtensions);
	ApplicationCode = ApplicationData.Code;
	
	ExportUserSettings = New Map;
	For Each UserRights_ In UsersRights Do
		If ValueIsFilled(UserRights_.User) Then
			ExportUserSettings.Insert(UserRights_.User, UserRights_.Login);
		EndIf;
	EndDo;
	
	CompleteMigrationAutomatically = MigrationCompletionOption = 0;
	
	ServiceOrganizationData = ApplicationsMigration.ServiceOrganizationData(ThisObject);
	
	ServiceCompanyEmail = ServiceOrganizationData.Email;
	ServiceCompanyPhoneNumber = ServiceOrganizationData.Phone;
	
	AdditionalProperties = New Structure;
	AdditionalProperties.Insert("ServiceAddress", ServiceAddress);
	AdditionalProperties.Insert("ServiceCompanyEmail", ServiceCompanyEmail);
	AdditionalProperties.Insert("ServiceCompanyPhoneNumber", ServiceCompanyPhoneNumber);
	AdditionalProperties.Insert("SubscriberCode", SubscriberCode);
	AdditionalProperties.Insert("ApplicationCode", ApplicationCode);
	
	ApplicationsMigration.BeginUnload(
		ApplicationData.ApplicationURL, 
		ApplicationData.Login, 
		ApplicationData.Password, 
		ExportUserSettings, 
		CompleteMigrationAutomatically, 
		AdditionalProperties);
	
	FillPropertyValues(ThisObject, TransitionState());
	
EndProcedure

&AtServer
Procedure CancelTransition()
	
	ApplicationsMigration.CancelUpload();
	DisableExclusiveMode_();
	Job = Undefined;
	ApplicationURL = "";
	CompletedOn = CurrentSessionDate();
	Comment = NStr("ru = 'Переход в сервис отменен';
						|en = 'Cloud migration canceled';");
	
EndProcedure

&AtServerNoContext
Function TransitionState()
	
	TransitionState = ApplicationsMigration.ExportState();
	TransitionState.Insert("TimeLeft", NStr("ru = 'Рассчитывается...';
														|en = 'Calculating…';"));
	
	If (TransitionState.State = Enums.ApplicationMigrationStates.Running 
			Or TransitionState.State = Enums.ApplicationMigrationStates.PendingImport)
		And TransitionState.SentMessageNumber >= 3 
		And TransitionState.ObjectsImported <> 0 Then
		
		RemainingTime = (CurrentUniversalDate() - TransitionState.StartDate) / 
			TransitionState.ObjectsImported * TransitionState.ImportObjects;
		
		If RemainingTime <= 180 Then
			TransitionState.TimeLeft = NStr("ru = 'Несколько минут';
													|en = 'Several minutes';");
		ElsIf RemainingTime <= 3600 Then
			TransitionState.TimeLeft = StrTemplate(NStr("ru = '~ %1 мин.';
																|en = '~ %1 min.';"), Round(RemainingTime / 60));
		Else
			TransitionState.TimeLeft = StrTemplate(NStr("ru = '~ %1 ч.';
																|en = '~ %1 h.';"), Round(RemainingTime / 3600, 1));
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(TransitionState.StartDate) Then
		TransitionState.StartDate = ToLocalTime(TransitionState.StartDate, SessionTimeZone());
	EndIf;
	
	If ValueIsFilled(TransitionState.CompletedOn) Then
		TransitionState.CompletedOn = ToLocalTime(TransitionState.CompletedOn, SessionTimeZone());
	EndIf;
	
	TransitionState.Insert("Progress", 0);
	If TransitionState.ObjectsImported <> 0 Then
		TransitionState.Insert("Progress", TransitionState.ObjectsImported * 100 / 
			(TransitionState.ImportObjects + TransitionState.ObjectsImported));
	EndIf;
	
	TransitionState.Insert("MessagesSentProcessedText", StrTemplate(NStr("ru = '%1 / %2';
																					|en = '%1 / %2';"), 
		TransitionState.SentMessageNumber, TransitionState.ReceivedMessageNumber));
	TransitionState.Insert("ObjectsExportedImportedText", StrTemplate(NStr("ru = '%1 / %2';
																				|en = '%1 / %2';"), 
		TransitionState.ObjectsExported, TransitionState.ObjectsImported));
	TransitionState.Insert("LeftToExportImportText", StrTemplate(NStr("ru = '%1 / %2';
																				|en = '%1 / %2';"), 
		TransitionState.ObjectsChanged, TransitionState.ImportObjects));
	
	Return TransitionState;
	
EndFunction

&AtClient
Procedure UpdatingTransitionStatus() Export
	
	PastRequiresMonopolyRegime = ExclusiveModeRequired;
	
	FillPropertyValues(ThisObject, TransitionState());
	
	If ValueIsFilled(CompletedOn) Then
		
		If ValueIsFilled(Job) Then
			If DisableExclusiveMode_() Then
				Job = Undefined;
				DisableServiceStatusUpdateHandler();
				ApplicationParameters.Delete(ApplicationsMigrationClient.NameOfTransitionForm());
			EndIf;
		EndIf;
		
		If State = PredefinedValue("Enum.ApplicationMigrationStates.OperationFailed") Then
			NewPage = Items.ErrorPage;
		Else
			NewPage = Items.ResultPage;
		EndIf;
		
		OpeningPage(NewPage);
		
		If Not IsOpen() Then
			Open();
		EndIf;
		
	Else
		
		Items.Next.Visible = ExclusiveModeRequired;
		If ValueIsFilled(Job) Then
			// Check the running task.
			Job = RunMonopolyCompletion();
		ElsIf ExclusiveModeRequired And CompleteMigrationAutomatically Then
			// Try to set exclusive mode. If succeeded, lock the UI to prevent the user from editing data. 
			// 
			Job = RunMonopolyCompletion();
			If ValueIsFilled(Job) Then
				BlockEntireInterface();
			EndIf;
		ElsIf ExclusiveModeRequired And Not PastRequiresMonopolyRegime And Not CompleteMigrationAutomatically And Not IsOpen() Then
			// Export is almost finished. Set exclusive mode.
			// Show the form to let the user click the button.
			Open();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearUploadState()
	
	InformationRegisters.ApplicationsMigrationExportState.CreateRecordSet().Write();
	
EndProcedure

&AtClient
Procedure BeforeClosingAlert(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		CloseOfCourse = True;
		Close();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function RunMonopolyCompletion()
	
	Try
		SetExclusiveMode(True);
	Except
		Return Undefined;
	EndTry;
	
	Filter = New Structure("Key, State", "ApplicationsMigrationExport", BackgroundJobState.Active);
	RunningJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	If RunningJobs.Count() = 0 Then
		JobParameters = New Array;
		JobParameters.Add(True);
		BackgroundJob = BackgroundJobs.Execute("ApplicationsMigration.ExportJob", JobParameters, "ApplicationsMigrationExport");
		Return BackgroundJob.UUID;
	Else
		Return RunningJobs[0].UUID;
	EndIf;
	
EndFunction

&AtServerNoContext
Function DisableExclusiveMode_()
	
	Try
		SetExclusiveMode(False);
	Except
		Return False;
	EndTry;

	Return True;
	
EndFunction

&AtClient
Procedure OnOpenForm(OnStart = False) Export
	
	If State = PredefinedValue("Enum.ApplicationMigrationStates.OperationSuccessful") Then
		NewPage = Items.ResultPage;
	ElsIf State = PredefinedValue("Enum.ApplicationMigrationStates.OperationFailed") Then
		NewPage = Items.ErrorPage;
	ElsIf State = PredefinedValue("Enum.ApplicationMigrationStates.Running")
		Or State = PredefinedValue("Enum.ApplicationMigrationStates.PendingImport") Then
		NewPage = Items.PageWait;
	Else
		NewPage = Items.CreateApplicationPage;
	EndIf;
	
	OpeningPage(NewPage);
	
	If OnStart 
		And (ValueIsFilled(CompletedOn) Or ExclusiveModeRequired) 
		And Not IsOpen() Then
		Open();
	EndIf;
	
EndProcedure

&AtClient
Procedure BlockEntireInterface()
	
	If IsOpen() Then
		OpeningPage(Items.Pages.CurrentPage);
	Else
		Open();
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowWarningMonopolyModeIsSet()
	
	Text = NStr("ru = 'Установлен монопольный режим, не закрывайте приложение до окончания миграции.';
				|en = 'Exclusive mode is selected, do not close the application until migration is complete.';");
	ShowMessageBox(, Text);
	
EndProcedure

#EndRegion

#EndRegion
