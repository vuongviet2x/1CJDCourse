///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Private

// Checks for active infobase connections.
//
// Returns:
//  Boolean       - True if there are connections.
//                 False if there are no connections.
//
Function HasActiveConnections(MessagesForEventLog = Undefined) Export
	
	VerifyAccessRights("Administration", Metadata);
	EventLog.WriteEventsToEventLog(MessagesForEventLog);
	Return IBConnections.InfobaseSessionsCount(False, False) > 1;
EndFunction

Procedure WriteUpdateStatus(ParametersOfUpdate, MessagesForEventLog = Undefined) Export
	
	VerifyAccessRights("Administration", Metadata);
	
	ScriptDirectory = "";
	If Not IsBlankString(ParametersOfUpdate.MainScriptFileName) Then 
		ScriptDirectory = Left(ParametersOfUpdate.MainScriptFileName, StrLen(ParametersOfUpdate.MainScriptFileName) - 10);
	EndIf;
	ParametersOfUpdate.ScriptDirectory = ScriptDirectory;
	
	ConfigurationUpdate.WriteUpdateStatus(
		ParametersOfUpdate,
		MessagesForEventLog);
	
EndProcedure

Function TemplatesTexts(MessagesForEventLog, InteractiveMode, ExecuteDeferredHandlers, IsDeferredUpdate) Export
	
	VerifyAccessRights("Administration", Metadata);
	
	TemplatesTexts = New Structure;
	TemplatesTexts.Insert("AdditionalConfigurationUpdateFile");
	TemplatesTexts.Insert(?(InteractiveMode, "ConfigurationUpdateSplash", "NonInteractiveConfigurationUpdate"));
	
	If IsDeferredUpdate Then
		TemplatesTexts.Insert("TaskSchedulerTaskCreationScript");
	EndIf;
	
	TemplatesTexts.Insert("PatchesDeletionScript");
	
	For Each TemplateProperties In TemplatesTexts Do
		TemplatesTexts[TemplateProperties.Key] = DataProcessors.InstallUpdates.GetTemplate(TemplateProperties.Key).GetText();
	EndDo;
	
	If InteractiveMode Then
		TemplatesTexts.ConfigurationUpdateSplash = GenerateSplashText(TemplatesTexts.ConfigurationUpdateSplash); 
	EndIf;
	
	// Configuration update file: main.js.
	ScriptTemplate = DataProcessors.InstallUpdates.GetTemplate("ConfigurationUpdateFileTemplate");
	
	ParametersArea = ScriptTemplate.GetArea("ParametersArea");
	ParametersArea.DeleteLine(1);
	ParametersArea.DeleteLine(ParametersArea.LineCount());
	If StrStartsWith(ParametersArea.GetLine(ParametersArea.LineCount()), "#") Then
		ParametersArea.DeleteLine(ParametersArea.LineCount());
	EndIf;
	TemplatesTexts.Insert("ParametersArea", ParametersArea.GetText());
	
	ConfigurationUpdateArea = ScriptTemplate.GetArea("ConfigurationUpdateArea");
	ConfigurationUpdateArea.DeleteLine(1);
	ConfigurationUpdateArea.DeleteLine(ConfigurationUpdateArea.LineCount());
	TemplatesTexts.Insert("ConfigurationUpdateFileTemplate", ConfigurationUpdateArea.GetText());
	
	// Writing accumulated events to the event log.
	EventLog.WriteEventsToEventLog(MessagesForEventLog);
	ExecuteDeferredHandlers = ConfigurationUpdate.ExecuteDeferredHandlers();
	
	ScriptMessages = ScriptMessages();
	For Each TemplateProperties In TemplatesTexts Do
		TemplatesTexts[TemplateProperties.Key] = SubstituteParametersToText(TemplatesTexts[TemplateProperties.Key], ScriptMessages);
	EndDo;
	
	Return TemplatesTexts;
	
EndFunction

Function GenerateSplashText(Val TextTemplate1)
	
	TextParameters = New Map;
	TextParameters["[SplashTitle]"] = NStr("ru = 'Обновление конфигурации ""1С:Предприятие""...';
													|en = 'Updating 1C:Enterprise configuration…';");
	TextParameters["[SplashText]"] = NStr("ru = 'Пожалуйста, подождите.
		|<br/> Выполняется обновление конфигурации.';
		|en = 'Please wait.
		|<br/> Application update is in progress.';");
	
	TextParameters["[Step1Initialization]"] = NStr("ru = 'Инициализация';
													|en = 'Initializing';");
	TextParameters["[Step2ClosingUserSessions]"] = NStr("ru = 'Завершение работы пользователей';
													|en = 'Closing user sessions';");
	TextParameters["[Step3BackupCreation]"] = NStr("ru = 'Создание резервной копии информационной базы';
															|en = 'Creating infobase backup';");
	TextParameters["[Step4ConfigurationUpdate]"] = NStr("ru = 'Обновление конфигурации информационной базы';
															|en = 'Updating infobase configuration';");
	TextParameters["[Step4DownloadExtensions]"] = NStr("ru = 'Обновление расширений информационной базы';
														|en = 'Updating infobase extensions';");
	TextParameters["[Step5IBUpdate]"] = NStr("ru = 'Выполнение обработчиков обновления';
												|en = 'Running update handlers';");
	TextParameters["[Step6DeferredUpdate]"] = NStr("ru = 'Выполнение отложенных обработчиков обновления';
														|en = 'Running deferred update handlers';");
	TextParameters["[Step7CompressTables]"] = NStr("ru = 'Сжатие таблиц информационной базы';
												|en = 'Compressing infobase tables';");
	TextParameters["[Step8AllowConnections]"] = NStr("ru = 'Разрешение подключения новых соединений';
															|en = 'Granting permission for new connections';");
	TextParameters["[Step9Completion]"] = NStr("ru = 'Завершение';
												|en = 'Completing';");
	TextParameters["[Step10Recovery]"] = NStr("ru = 'Восстановление информационной базы';
													|en = 'Restoring infobase';");
	TextParameters["[Step11PatchesDeletion]"] = NStr("ru = 'Удаление исправлений (патчей)';
													|en = 'Deleting patches';");
	
	TextParameters["[Step41Load]"] = NStr("ru = 'Загрузка файла обновления в основную базу';
												|en = 'Loading update file to the main infobase';");
	TextParameters["[Step42ConfigurationUpdate]"] = NStr("ru = 'Обновление конфигурации информационной базы';
															|en = 'Updating infobase configuration';");
	TextParameters["[Step43IBUpdate]"] = NStr("ru = 'Выполнение обработчиков обновления';
													|en = 'Running update handlers';");
	
	TextParameters["[ProcessIsAborted]"] = NStr("ru = 'Внимание: процесс обновления был прерван, и информационная база осталась заблокированной.';
												|en = 'Warning! The update was terminated and the infobase remains locked.';");
	TextParameters["[AbortedTooltip]"] = NStr("ru = 'Для разблокирования информационной базы воспользуйтесь консолью кластера серверов или запустите ""1С:Предприятие"".';
														|en = 'To unlock the infobase, use the server cluster console or run 1C:Enterprise.';");
	
	TextParameters["[ProductName]"] = NStr("ru = '1С:ПРЕДПРИЯТИЕ 8.3';
													|en = '1C:ENTERPRISE 8.3';");
	TextParameters["[Copyright]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = '© ООО ""1С-Софт"", 1996-%1';
			|en = '© 1C Company, 1996-%1';"), Format(Year(CurrentSessionDate()), "NG=0"));
	
	Return SubstituteParametersToText(TextTemplate1, TextParameters);
	
EndFunction

Function SubstituteParametersToText(Val Text, Val TextParameters)
	
	Result = Text;
	For Each TextParameter In TextParameters Do
		Result = StrReplace(Result, TextParameter.Key, TextParameter.Value);
	EndDo;
	Return Result; 
	
EndFunction

Procedure SaveConfigurationUpdateSettings(Settings) Export
	VerifyAccessRights("Administration", Metadata);
	ConfigurationUpdate.SaveConfigurationUpdateSettings(Settings);
EndProcedure

Procedure UpdatePatchesFromScript(NewPatches, PatchesToDelete) Export // ACC:557 To call from a script.
	ConfigurationUpdate.UpdatePatchesFromScript(NewPatches, PatchesToDelete);
EndProcedure

Function ScriptDirectory() Export
	
	Return ConfigurationUpdate.ScriptDirectory();
	
EndFunction

// ACC:299–off for using from the update script.
// ACC:557–off for using from the update script.
//
Procedure DeletePatchesFromScript() Export
	
	MessageText = NStr("ru = 'Начато удаление исправлений до запуска обновления приложения.';
							|en = 'Starting patch clean up followed by application update.';");
	WriteLogEvent(ConfigurationUpdate.EventLogEvent(), EventLogLevel.Information,,, MessageText);
	
	AllExtensions = ConfigurationExtensions.Get();
	For Each Extension In AllExtensions Do
		If Not ConfigurationUpdate.IsPatch(Extension) Then
			Continue;
		EndIf;
		Try
			Extension.Delete();
		Except
			ErrorInfo = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось удалить исправление ""%1"" по причине:
				           |
				           |%2';
							|en = 'Cannot delete patch ""%1."" Reason:
							|
							|%2';"), Extension.Name, ErrorProcessing.BriefErrorDescription(ErrorInfo));
			WriteLogEvent(NStr("ru = 'Исправления.Удаление';
											|en = 'Patch.Delete';", Common.DefaultLanguageCode())
				, EventLogLevel.Error,,, ErrorText);
		EndTry;
	EndDo;
	
	MessageText = NStr("ru = 'Удаление исправлений завершено.';
							|en = 'Patch deletion completed.';");
	WriteLogEvent(ConfigurationUpdate.EventLogEvent(), EventLogLevel.Information,,, MessageText);
	
EndProcedure
// ACC:299-on
// ACC:557-on

Function ScriptMessages()
	
	Messages = New Map;
		
	// Messages in templates ConfigurationUpdateFileTemplate, NonInteractiveConfigurationUpdate, and ConfigurationUpdateSplash.
	Messages["[TheStartOfStartupMessage]"] = NStr("ru = 'Запускается: {0}; параметры: {1}; окно: {2}; ожидание: {3}';
												|en = 'Starting: {0}; parameters: {1}; window: {2}; waiting: {3}';");
	Messages["[ExceptionDetailsMessage]"] = NStr("ru = 'Исключение при запуске приложения: {0}, {1}';
													|en = 'Exception at the application start: {0}, {1}';");
	Messages["[MessageLaunchResult]"] = NStr("ru = 'Код возврата: {0}';
													|en = 'Return code: {0}';");
	Messages["[TheMessageIsThePathToTheScriptFile]"] = NStr("ru = 'Файл скрипта: {0}';
													|en = 'Script file: {0}';");
	Messages["[UpdateFileCounterMessage]"] = NStr("ru = 'Количество файлов обновления: {0}';
															|en = 'Number of update files: {0}';");
	Messages["[TheMessageRestoringTheDatabase]"] = NStr("ru = 'Восстановление ИБ из временного архива';
														|en = 'Restore infobase from a temporary archive';");
	Messages["[TheMessageTheBeginningOfTheConnectionSessionWithTheDatabase]"] = NStr("ru = 'Начат сеанс внешнего соединения с ИБ';
																|en = 'External infobase connection session started';");
	Messages["[MessageDeletingASchedulerTask]"] = NStr("ru = 'Удаление задачи планировщика задач: {0}';
																|en = 'Deleting a scheduler task: {0}';");
	Messages["[TheSchedulerTaskDeletionFailureMessage]"] = NStr("ru = 'Задача из планировщика задач не была удалена по причине: {0}';
																	|en = 'Cannot delete the task from the task scheduler due to: {0}';");
	Messages["[TheMessageConnectionFailureWithTheDatabase]"] = NStr("ru = 'Исключение при создании COM-соединения: {0}, {1}';
														|en = 'Exception when creating COM connection: {0}, {1}';");
	Messages["[TheMessageIsACallToCompleteTheUpdate]"] = "ConfigurationUpdate.CompleteUpdate" + "({0}, {1}, {2})";
	Messages["[FailureMessageWhenCallingToCompleteTheUpdate]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Исключение при вызове %1: {0}, {1}';
			|en = 'Exception when calling %1: {0}, {1}';"), "ConfigurationUpdate.CompleteUpdate");
	Messages["[TheMessageDatabaseUpdateResult]"] = NStr("ru = 'Обновление информационной базы завершилось успешно';
															|en = 'The infobase is updated.';");
	Messages["[DatabaseUpdateFailureMessage]"] = NStr("ru = 'Непредвиденная ситуация при обновлении информационной базы';
														|en = 'An unexpected error occurred while updating the infobase';");
	Messages["[TheMessageDatabaseParameters]"] = NStr("ru = 'Параметры информационной базы: {0}.';
												|en = 'Infobase parameters: {0}.';");
	Messages["[LoggingFailureMessage]"] = NStr("ru = 'Исключение при записи журнала: {0}, {1}';
													|en = 'Exception when writing Event log: {0}, {1}';");
	Messages["[MessageUpdateLogging1S]"] = NStr("ru = 'Протокол обновления сохранен в журнал регистрации.';
															|en = 'The update protocol is saved to the event log.';");
	Messages["[TheMessageCopyingTheDatabase]"] = NStr("ru = '\r\n\Выполняется копирование из:\r\n\{0}\r\n\в:\r\n\{1}';
													|en = '\r\n\Copying from:\r\n\{0}\r\n\ to:\r\n\{1}';");
	Messages["[TheMessageDatabaseFileDoesNotExist]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Файл базы данных %1 не существует по пути: {0}';
			|en = '%1 database file does not exist by path: {0}';"), "1Cv8.1CD");
	Messages["[TheMessageDatabaseBackupDirectoryDoesNotExist]"] = NStr("ru = 'Папки для сохранения резервной копии не существует: {0}';
																		|en = 'There is no folder to save the backup: {0}';");
	Messages["[MessageBackupFileParameters]"] = NStr("ru = '\r\n\Файл резервной копии уже существует: {0}\r\n\Создан: {1}\r\n\Последнее обращение: {2}\r\n\Последнее изменение: {3}\r\n\Размер: {4}\r\n\Тип: {5}\r\n\Атрибуты:\r\n\{6}';
																|en = '\r\n\The backup file already exists: {0}\r\n\Created: {1}\r\n\Last accessed: {2}\r\n\Last modified: {3}\r\n\Size: {4}\r\n\Type: {5}\r\n\Attributes:\r\n\{6}';");
	Messages["[TheMessageDiskDoesNotExist]"] = NStr("ru = '\r\n\Диск не найден по пути {0}\r\n\Исключение: {1}, {2}';
													|en = '\r\n\Hard drive is not found at {0}\r\n\Exception: {1}, {2}';");
	Messages["[TheMessageDiskIsUnavailable]"] = NStr("ru = 'Диск недоступен по пути {0}';
													|en = 'Hard drive is unavailable at {0}';");
	Messages["[MessageEnoughDiskSpace]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Доступно на диске {0}: {1} Mb\r\n\Размер файла %1: {2} Mb\r\n\Тип диска: {3}';
			|en = 'Space available on drive {0}: {1} Mb\r\n\%1 file size: {2} Mb\r\n\Drive type: {3}';"), "1Cv8.1CD");
	Messages["[MessageDiskSpaceIsInsufficient]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = '\r\n\Недостаточно свободного места для создания резервной копии.\r\n\Освободите место или укажите папку на другом диске.\r\n\Требуется: {0} Mb\r\n\Доступно на диске {1}: {2} Mb\r\n\Размер файла %1: {3} Mb\r\n\Тип диска: {4}';
			|en = '\r\n\There is not enough free space to create a backup.\r\n\Free up some space or specify a folder on a different hard drive.\r\n\Required: {0} Mb\r\n\Space available on drive {1}: {2} Mb\r\n\%1 File size: {3} Mb\r\n\Drive type: {4}';"), "1Cv8.1CD");
	Messages["[TheMessageIsTheResultOfCreatingABackupCopyOfTheDatabase]"] = NStr("ru = 'Резервная копия базы создана';
																		|en = 'Infobase is backed up';");
	Messages["[TheMessageFailureToCreateABackupCopyOfTheDatabaseInDetail]"] = NStr("ru = 'Исключение при создании резервной копии базы: {0}, {1}';
																			|en = 'Exception when backing up the infobase: {0}, {1}';");
	Messages["[TheMessageDatabaseRecoveryResult]"] = NStr("ru = 'База данных восстановлена из резервной копии';
																|en = 'Database is restored from the backup';");
	Messages["[TheMessageDatabaseRecoveryFailureInDetail]"] = NStr("ru = 'Исключение при восстановлении базы из резервной копии: {0}, {1}.';
																	|en = 'Exception when restoring an infobase from a backup: {0}, {1}.';");
	Messages["[TheMessageChallengeAllowUsersToWork]"] = "IBConnections.AllowUserAuthorization";
	Messages["[MessageCallRefusalToAllowUsersToWork]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Исключение при вызове %1: {0}, {1}';
			|en = 'Exception when calling %1: {0}, {1}';"), "IBConnections.AllowUserAuthorization");
	Messages["[TheErrorMessageUpdatesFixes]"] = NStr("ru = 'Не удалось обновить исправления конфигурации. Подробности см. в предыдущей записи.';
																|en = 'Cannot update the configuration patches. For more information, see the previous record.';");
	Messages["[CallFailureMessageUpdateFixesFromScript]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Исключение при вызове %1: {0}, {1}';
			|en = 'Exception when calling %1: {0}, {1}';"), "ConfigurationUpdateServerCall.UpdatePatchesFromScript");
	Messages["[MessageCallToUpdateTheInformationBase]"] = "InfobaseUpdateServerCall.UpdateInfobase" + "({0})";
	Messages["[MessageCallFailureToUpdateTheInformationBase]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Исключение при вызове %1: {0}, {1}.';
			|en = 'Exception when calling %1: {0}, {1}.';"), "InfobaseUpdateServerCall.UpdateInfobase");
	Messages["[TheMessageDatabaseUpdateFailureIsGeneral]"] = NStr("ru = 'Не удалось обновить информационную базу по причине:';
															|en = 'Cannot update the infobase due to:';");
	Messages["[TheMessageBlockingTheDatabase]"] = NStr("ru = 'в связи с необходимостью обновления конфигурации';
													|en = 'because configuration update is pending';");
	Messages["[UserShutdownFailureMessage]"] = NStr("ru = 'Попытка завершения работы пользователей завершилась безуспешно: отменена блокировка ИБ.';
																		|en = 'An attempt to close user sessions is unsuccessful. Infobase lock is canceled.';");
	Messages["[TheMessageCancelingTheBlockingOfUsersWork]"] = NStr("ru = 'Исключение при завершении работы пользователей: {0}, {1}';
																		|en = 'Exception when closing user sessions: {0}, {1}';");
	Messages["[MessageEndOfDatabaseConnectionSession]"] = NStr("ru = 'Завершен сеанс внешнего соединения с ИБ';
																|en = 'External infobase connection session completed';");
	Messages["[TheMessageBlockingTheWorkOfUsersLogging]"] = NStr("ru = 'Установка блокировки сеансов в связи с необходимостью обновления конфигурации';
																			|en = 'Lock sessions because configuration update is pending';");
	Messages["[TheMessageBlockingTheWorkOfUsers]"] = NStr("ru = 'в связи с необходимостью обновления конфигурации';
																|en = 'because configuration update is pending';");
	Messages["[MessageDatabaseSessionCounter]"] = NStr("ru = 'Количество сеансов информационной базы: {0}';
														|en = 'Number of infobase sessions: {0}';");
	Messages["[TheMessageIsTheResultOfBlockingSessions]"] = NStr("ru = 'Блокировка начала сеансов установлена: {0}';
																|en = 'Session start lock is set: {0}';");
	Messages["[TheMessageTheCounterOfTheHungSessionsOfTheDatabase]"] = NStr("ru = 'Количество зависших сеансов информационной базы: {0}, попытка № {1}';
																|en = 'Number of hung infobase sessions: {0}, attempt #{1}';");
	Messages["[TheMessageIsACallToPerformADeferredUpdateNow]"] = "InfobaseUpdateInternal.ExecuteDeferredUpdateNow" + "()";
	Messages["[MessageCallFailureToPerformADelayedUpdateNow]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Исключение при вызове %1: {0}, {1}.';
			|en = 'Exception when calling %1: {0}, {1}.';"), "InfobaseUpdateInternal.ExecuteDeferredUpdateNow");
	Messages["[CallFailureMessageRemoveFixesFromScript]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Исключение при вызове %1: {0}, {1}.';
			|en = 'Exception when calling %1: {0}, {1}.';"), "ConfigurationUpdateServerCall.DeletePatchesFromScript");
	Messages["[TheMessageFailureToDeleteFixes]"] = NStr("ru = 'Не удалось удалить исправления конфигурации. Подробности см. в предыдущей записи.';
															|en = 'Cannot delete the configuration patches. For more information, see the previous record.';");
	Messages["[MessageCOMConnectorParameters]"] = NStr("ru = 'Используется COM-соединение: {0}';
															|en = 'COM connection is used: {0}';");
	Messages["[TheMessageDatabaseUpdateFailureFromTheFile]"] = NStr("ru = 'Не удалось обновить по файлу, возможно конфигурация не находится на поддержке, попытка загрузки конфигурации.';
																|en = 'Cannot update by file. The configuration may not be supported. Attempting to load configuration.';");
	Messages["[SplashScreenMessageStepError]"] = NStr("ru = 'Завершение с ошибкой. Код ошибки: {0}. Подробности см. в предыдущей записи.';
														|en = 'An error occurred. Error code: {0}. For more information, see the previous record.';");
	Messages["[MessageInitialization]"] = NStr("ru = 'Инициализация';
												|en = 'Initializing';");
	Messages["[TheUserShutdownMessage]"] = NStr("ru = 'Завершение работы пользователей';
																|en = 'Closing user sessions';");
	Messages["[TheMessageCreatingABackupCopyOfTheDatabase]"] = NStr("ru = 'Создание резервной копии информационной базы';
																|en = 'Creating infobase backup';");
	Messages["[MessageExecutingDeferredUpdateHandlers]"] = NStr("ru = 'Выполнение отложенных обработчиков обновления';
																				|en = 'Running deferred update handlers';");
	Messages["[ConfigurationUpdateMessage]"] = NStr("ru = 'Обновление конфигурации информационной базы';
															|en = 'Updating infobase configuration';");
	Messages["[MessageLoadingExtensions]"] = NStr("ru = 'Обновление расширений информационной базы';
														|en = 'Infobase extension update';");
	Messages["[UpdateFileDownloadMessage]"] = NStr("ru = 'Загрузка файла обновления в основную базу ({0}/{1})';
															|en = 'Loading update file to the main infobase ({0}/{1})';");
	Messages["[MessageConfigurationUpdateParameters]"] = NStr("ru = 'Обновление конфигурации информационной базы ({0}/{1})';
																	|en = 'Updating infobase configuration ({0}/{1})';");
	Messages["[MessageExecutingUpdateHandlers]"] = NStr("ru = 'Выполнение обработчиков обновления ({0}/{1})';
																	|en = 'Running update handlers ({0}/{1})';");
	Messages["[TheConnectionPermissionMessage]"] = NStr("ru = 'Разрешение подключений новых соединений';
														|en = 'Allowing new connections';");
	Messages["[UpdateCompletionMessage]"] = NStr("ru = 'Завершение';
														|en = 'Completing';");
	
	// Messages in template PatchesDeletionScript.
	Messages["[InitializationFailureMessage]"] = NStr("ru = 'Переменные не инициализированы';
														|en = 'Variables are not initialized';");
	Messages["[MessageCreatingACOMConnectorObject]"] = NStr("ru = 'Создание объекта COM-соединителя...';
																|en = 'Creating a COM connector object…';");
	Messages["[MessageFailureToCreateACOMConnectorObject]"] = NStr("ru = 'Не удалось создать объект COM-соединителя:';
																		|en = 'Cannot create a COM connector object:';");
	Messages["[TheMessageEstablishingAConnectionToTheDatabase]"] = NStr("ru = 'Установка соединения с';
															|en = 'Connecting with';");
	Messages["[TheMessageConnectionFailureWithTheDatabaseIsGeneral]"] = NStr("ru = 'Не удалось установить соединение с';
																|en = 'Cannot connect to';");
	Messages["[MessageMainEvent]"] = NStr("ru = 'Удаление исправлений (патчей)';
													|en = 'Deleting patches';");
	Messages["[TheMessageIsACallToRemoveFixesFromTheScript]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Вызов %1...';
			|en = 'Calling %1…';"), "ConfigurationUpdateServerCall.DeletePatchesFromScript");
	Messages["[TheMessageIsACallToUpdateTheFixesFromTheScript]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Вызов %1...';
			|en = 'Calling %1…';"), "ConfigurationUpdateServerCall.UpdatePatchesFromScript");
	Messages["[ErrorMessage_]"] = NStr("ru = ': Ошибка в конфигурации:';
											|en = ': Configuration error:';") + Chars.NBSp;
	Messages["[MessageImportance]"] = NStr("ru = 'Обязательная';
											|en = 'Required';");
	
	Return Messages;
	
EndFunction

Function VersionsRequiringSuccessfulUpdate(FilesOfUpdate) Export
	
	Table = New ValueTable;
	Table.Columns.Add("Version");
	Table.Columns.Add("VersionWeight");
	Table.Columns.Add("Required");
	
	If FilesOfUpdate.Count() < 2 Then
		Return New Array;
	EndIf;
	
	For Each InformationRecords In FilesOfUpdate Do
		UpdateDetails1 = New ConfigurationUpdateDescription(InformationRecords.BinaryData);
		
		String = Table.Add();
		String.Version       = UpdateDetails1.TargetConfiguration.Version;
		String.VersionWeight    = VersionWeight(String.Version);
		String.Required = InformationRecords.Required;
	EndDo;
	
	Versions = New Array;
	Table.Sort("VersionWeight Asc");
	LastRow = Table[Table.Count() - 1];
	For Each TableRow In Table Do
		If Not TableRow.Required Then
			Continue;
		EndIf;
		
		If TableRow = LastRow Then
			Continue; // Ignore the latest version.
		EndIf;
		
		Versions.Add(TableRow.Version);
	EndDo;
	
	Return Versions;
	
EndFunction

Function VersionWeight(Version)
	
	VersionByParts = StrSplit(Version, ".");
	
	Return 0
		+ Number(VersionByParts[0]) * 1000000000000
		+ Number(VersionByParts[1]) * 100000000
		+ Number(VersionByParts[2]) * 10000
		+ Number(VersionByParts[3]);
	
EndFunction

Function ParametersOfUpdate() Export
	
	ParametersOfUpdate = New Structure;
	ParametersOfUpdate.Insert("UpdateAdministratorName", Undefined);
	ParametersOfUpdate.Insert("UpdateScheduled", False);
	ParametersOfUpdate.Insert("UpdateComplete", False);
	ParametersOfUpdate.Insert("ConfigurationUpdateResult", Undefined);
	ParametersOfUpdate.Insert("ScriptDirectory", "");
	ParametersOfUpdate.Insert("MainScriptFileName", "");
	ParametersOfUpdate.Insert("PatchInstallationResult", Undefined);
	ParametersOfUpdate.Insert("VersionsRequiringSuccessfulUpdate", Undefined);
	
	Return ParametersOfUpdate;
	
EndFunction

#EndRegion
