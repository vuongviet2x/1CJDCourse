///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var Subsystems; // See InitializeTable
Var RequiredSubsystems;

#EndRegion

#Region Internal

Function SubsystemsDependencies() Export
	
	Subsystems = InitializeTable();
	
	RequiredSubsystems = New Map;
	RequiredSubsystems["Core"] = True;
	RequiredSubsystems["IBVersionUpdate"] = True;
	RequiredSubsystems["Users"] = True;

#Region AddressClassifier
	Subsystem = AddSubsystem("AddressClassifier");
	Subsystem.Synonym = NStr("ru = 'Адресный классификатор';
								|en = 'Address classifier';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("GetFilesFromInternet,ContactInformation");
	Subsystem.LongDesc = NStr("ru = '• Хранение и предоставление адресного классификатора для использования в других прикладных подсистемах.
		|• Ввод и проверка корректности адресов через Интернет с помощью веб-сервиса фирмы ""1С"".
		|• Загрузка адресного классификатора в приложение с пользовательского раздела сайта фирмы ""1С"" или из указанного каталога (при автономной работе без постоянного подключения к Интернету).';
		|en = '• Storage and provision of the address classifier to use in other applications.
		|• Entering addresses and verifying them via the Internet using web service of 1C Company.
		|• Importing the address classifier to the application from the user section of 1C Company website or from the specified directory (in standalone mode without stable Internet connection).';");
#EndRegion
	
#Region Surveys
	Subsystem = AddSubsystem("Surveys");
	Subsystem.Synonym = NStr("ru = 'Анкетирование';
								|en = 'Surveys';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("ItemOrderSetup,AttachableCommands");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("ReportsOptions,AttachableCommands");
	Subsystem.LongDesc = NStr("ru = '• Проведение анкетирования для внешних пользователей программы.
		|• Разработка шаблонов анкет и проведение опросов по списку респондентов.
		|• Средства анализа результатов анкетирования.';
		|en = '• Conduct a survey for external application users.
		|• Develop survey templates and send it to the list of respondents.
		|• Analyze the survey results.';");
#EndRegion
	
#Region Core
	Subsystem = AddSubsystem("Core");
	Subsystem.Synonym = NStr("ru = 'Базовая функциональность';
								|en = 'Core';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Процедуры и функции общего назначения, по работе со строками, с другими типами данных, с журналом регистрации и т. п.
		|• Стандартные роли (%1, %2, %3 и др.).
		|• Автоматическое отслеживание переименований объектов метаданных.
		|• Базовые сервисные возможности администратора программы (журнал регистрации, настройка заголовка окна программы и другое).';
		|en = '• Common procedures and functions for operations with strings, other data types, event log, and so on.
		|• Standard roles (%1, %2, %3, and so on).
		|• Automatic tracking of renamed metadata objects.
		|• Basic service features of the application administrator (event log, application window header setup, and so on).';");
	Subsystem.LongDesc = StrTemplate(Subsystem.LongDesc,
		"Administration", "FullAccess", "StartThinClient");
#EndRegion
	
#Region Banks
	Subsystem = AddSubsystem("Banks");
	Subsystem.Synonym = NStr("ru = 'Банки';
								|en = 'Banks';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("GetFilesFromInternet");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Хранение и предоставление классификатора банков РФ (БИК) для использования в других прикладных подсистемах.
		|• Загрузка классификатора банков РФ (БИК) с ИТС или с веб-сайта 1С, автоматически или по требованию.';
		|en = '• Store and provide access to the RF bank classifier (list of bank codes) to be used in other application subsystems.
		|• Import the RF bank classifier (list of bank codes) from ITS or the 1C website, automatically or on demand.';");
#EndRegion
	
#Region BusinessProcessesAndTasks
	Subsystem = AddSubsystem("BusinessProcessesAndTasks");
	Subsystem.Synonym = NStr("ru = 'Бизнес-процессы и задачи';
								|en = 'Business processes and tasks';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("EmailOperations,AccessManagement");
	Subsystem.LongDesc = NStr("ru = '• Интерактивный ввод задач для пользователей программы.
		|• Информирование пользователей об их текущих задачах.
		|• Мониторинг и контроль исполнения задач со стороны заинтересованных лиц - авторов и координаторов выполнения задач.
		|• Базовая функциональность для разработки произвольных бизнес-процессов в конфигурации.';
		|en = '• Interactive task entry for application users.
		|• Informing users of their current tasks.
		|• Monitoring and controlling task execution by interested party - task authors and control managers.
		|• The basis for developing arbitrary business processes in the configuration.';");
#EndRegion
	
#Region Currencies
	Subsystem = AddSubsystem("Currencies");
	Subsystem.Synonym = NStr("ru = 'Валюты';
								|en = 'Currencies';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("GetFilesFromInternet");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("FormulasConstructor");
	Subsystem.LongDesc = NStr("ru = '• Хранение и предоставление доступа к списку и курсам валют.
		|• Загрузка курсов валют с веб-сайта 1С.
		|• Выбор валют из общероссийского классификатора (ОКВ).';
		|en = '• Storage and provision of access to the currency list and exchange rates.
		|• Downloading exchange rates from the 1C website.
		|• Choosing currencies from the all-Russian classifier (RCC).';");
#EndRegion
	
#Region ReportsOptions
	Subsystem = AddSubsystem("ReportsOptions");
	Subsystem.Synonym = NStr("ru = 'Варианты отчетов';
								|en = 'Report options';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("FormulasConstructor");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("EmailOperations,AdditionalReportsAndDataProcessors,AttachableCommands,ReportMailing");
	Subsystem.LongDesc = NStr("ru = '• Совместная работа с вариантами отчетов, предусмотренных в приложении и настроенных пользователями.
		|• Панель быстрого доступа к вариантам отчетов.
		|• Универсальная форма отчета с быстрыми настройками, отправкой отчетов по почте, настройкой рассылок отчетов, автосуммой и другими сервисными возможностями.
		|• Программный интерфейс по тонкой настройке внешнего вида отчетов.';
		|en = '• Joint operation with report options, provided by the application and set up by users.
		|• Quick access toolbar to report options.
		|• Universal report option with quick settings, sending reports via email, report mailing setup, autosum, and other service features.
		|• Application interface for thin setting of report appearance.';");
#EndRegion
	
#Region ObjectsVersioning
	Subsystem = AddSubsystem("ObjectsVersioning");
	Subsystem.Synonym = NStr("ru = 'Версионирование объектов';
								|en = 'Object versioning';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Хранение и просмотр истории изменений справочников и документов (пользователь, внесший изменения, время изменения и характер изменения с точностью до реквизитов объекта и реквизитов его табличных частей).
		|• Сравнение произвольных версий объектов.
		|• Просмотр и откат к ранее сохраненной версии объекта.';
		|en = '• Storing and viewing the history of changes in directories and documents (user who made the changes, change time and the nature of change up to object attributes and attributes of its tables).
		|• Comparing arbitrary object versions.
		|• View and rollback to the previously saved object version.';");
#EndRegion
	
#Region Interactions
	Subsystem = AddSubsystem("Interactions");
	Subsystem.Synonym = NStr("ru = 'Взаимодействия';
								|en = 'Business interactions';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("ContactInformation,ItemOrderSetup,AttachableCommands,FullTextSearch,EmailOperations,FilesOperations,Properties,SendSMSMessage");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("AdditionalReportsAndDataProcessors,AttachableCommands");
	Subsystem.LongDesc = NStr("ru = '• Планирование, регистрация и упорядочивание взаимодействий: переписка по электронной почте, звонки, встречи и сообщения SMS.
		|• Хранение всех взаимодействий и их контактов в информационной базе.
		|• Работа с результатами взаимодействий.';
		|en = '• Planning, registering, and organizing interactions: email, calls, meetings, and SMS messages.
		|• Storing all interactions and their contacts in the infobase.
		|• Operations with interaction results.';");
#EndRegion
	
#Region AddIns
	Subsystem = AddSubsystem("AddIns");
	Subsystem.Synonym = NStr("ru = 'Внешние компоненты';
								|en = 'Add-ins';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Загрузка внешних компонент сторонних разработчиков в приложение без необходимости обновления конфигурации.
		|• Программный интерфейс для установки и подключения внешних компонент.
		|• Автоматическое получение и обновление компонент с сайта ""1С"" (при совместном использовании с библиотекой ""Библиотека интернет-поддержки (БИП)"").';
		|en = '• Import third-party add-ins into the application without the need to update it.
		|• Install and attach add-ins using the API.
		|• Automatically receive and update add-ins from the 1C website (when used together with the Online Support Library).';");
#EndRegion
	
#Region BarcodeGeneration
	Subsystem = AddSubsystem("BarcodeGeneration");
	Subsystem.Synonym = NStr("ru = 'Генерация штрихкода';
								|en = 'Barcode generation';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("AddIns");
	Subsystem.LongDesc = NStr("ru = '• Программный интерфейс для генерирования изображений штрихкодов %1.';
								|en = '• Application interface to generate barcode images %1.';");
	Codes = "EAN8, EAN13, EAN128, Code39, Code93, Code128, Code16k, PDF417, ITF14, RSS14, EAN13AddOn2, EAN13AddOn5, QR, GS1DataBarExpandedStacked, Datamatrix";
	Subsystem.LongDesc = StrReplace(Subsystem.LongDesc, "%1",Codes);
#EndRegion
	
#Region WorkSchedules
	Subsystem = AddSubsystem("WorkSchedules");
	Subsystem.Synonym = NStr("ru = 'Графики работы';
								|en = 'Work schedules';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("CalendarSchedules");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Хранение сведений о производственных календарях, используемых на предприятии.
		|• Получение даты, которая наступит через указанное количество дней по указанному календарю и другой программный интерфейс.';
		|en = '• Storing info on business calendars that are used in the enterprise.
		|• Getting a date that comes after the specified number of days on the specified calendar and another application interface.';");
#EndRegion
	
#Region BatchEditObjects
	Subsystem = AddSubsystem("BatchEditObjects");
	Subsystem.Synonym = NStr("ru = 'Групповое изменение объектов';
								|en = 'Bulk edit';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Групповое изменение произвольных реквизитов и табличных частей объектов приложения (справочников, документов и пр.).
		|• Возможность изменения значений дополнительных реквизитов и сведений.
		|• С учетом предустановленных в приложении правил запрета редактирования реквизитов объектов.';
		|en = '• Bulk edit of attributes and tables of the application objects (catalogs, documents and so on).
		|• The ability to change values of additional attributes and information records.
		|• Considering the preset application rules that prohibit editing applied object attributes.';");
#EndRegion
	
#Region PeriodClosingDates
	Subsystem = AddSubsystem("PeriodClosingDates");
	Subsystem.Synonym = NStr("ru = 'Даты запрета изменения';
								|en = 'Period-end closing dates';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Блокировка изменений любых данных (документов, записей регистров, элементов справочников и др.), введенных ранее определенной даты.
		|• Гибкая настройка одной общей даты запрета изменения для всех объектов приложения в целом, либо нескольких дат по разделам и/или отдельным объектам разделов учета.';
		|en = '• Locking changes to any data (documents, register records, catalog items, and so on) that was entered before the specified date.
		|• Flexible setting of one common date of prohibition to change for all applied objects in general or several dates by sections and/or separate objects of accounting sections.';");
#EndRegion
	
#Region AdditionalReportsAndDataProcessors
	Subsystem = AddSubsystem("AdditionalReportsAndDataProcessors");
	Subsystem.Synonym = NStr("ru = 'Дополнительные отчеты и обработки';
								|en = 'Additional reports and data processors';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("AttachableCommands");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("Print,ReportsOptions,BatchEditObjects");
	Subsystem.LongDesc = NStr("ru = '• Подключение к программе дополнительных (внешних) отчетов и обработок без внесения изменений в конфигурацию.
		|• Привязка дополнительных отчетов и обработок к конкретным типам объектов или разделам командного интерфейса.
		|• Регламентное выполнение обработок по расписанию.
		|• Средства администрирования списка дополнительных отчетов и обработок.';
		|en = '• Attaching additional (external) reports and data processors to the application without changing the configuration.
		|• Linking additional reports and data processors to specific types of objects or sections of the command interface.
		|• Routine execution of data processors on schedule.
		|• Tools for administrating the list of additional reports and data processors.';");
#EndRegion
	
#Region UsersSessions
	Subsystem = AddSubsystem("UsersSessions");
	Subsystem.Synonym = NStr("ru = 'Завершение работы пользователей';
								|en = 'Closing user sessions';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Просмотр и завершение активных сеансов работы в приложении.
		|• Временная блокировка работы пользователей с приложением, запрет регламентных заданий.';
		|en = '• Viewing and completing active application sessions.
		|• Temporarily locking user work in the application, prohibiting scheduled jobs.';");
#EndRegion
	
#Region ImportDataFromFile
	Subsystem = AddSubsystem("ImportDataFromFile");
	Subsystem.Synonym = NStr("ru = 'Загрузка данных из файла';
								|en = 'Import data from spreadsheets';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("AdditionalReportsAndDataProcessors,BatchEditObjects");
	Subsystem.LongDesc = NStr("ru = '• Загрузка табличных данных в произвольные справочники и табличные части документов.';
								|en = '• Importing tabular data to catalogs and document tables.';");
#EndRegion
	
#Region UserNotes
	Subsystem = AddSubsystem("UserNotes");
	Subsystem.Synonym = NStr("ru = 'Заметки пользователя';
								|en = 'Notes';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Электронная замена стикеров по краям монитора, которой можно воспользоваться, не покидая окна своей программы.
		|• Быстрый список заметок на рабочем столе, список заметок по предмету, общий список.
		|• Различные цвета и оформление текста заметок, вставка картинок в заметки.';
		|en = '• Electronic replacement of stickers on the edges of the monitor that can be used without closing your application window.
		|• Quick list of notes on your desktop, list of notes on the subject, common list.
		|• Various colors and design of note text, inserting pictures into notes.';");
#EndRegion
	
#Region ObjectAttributesLock
	Subsystem = AddSubsystem("ObjectAttributesLock");
	Subsystem.Synonym = NStr("ru = 'Запрет редактирования реквизитов объектов';
								|en = 'Object attribute lock';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Программный интерфейс для проверки обязательного заполнения некоторых реквизитов объектов, которые определяют характер данного объекта (условно называются ""ключевыми"" реквизитами).
		|• Запрет редактирования ""ключевых"" реквизитов записанных объектов.
		|• Проверка возможности изменения ""ключевых"" реквизитов пользователем, имеющим на это права.';
		|en = '• Application interface to check the required filling of some object attributes that define character of this object (they are conditionally called ""key"" attributes).
		|• The prohibition to edit ""key"" attributes of the saved objects.
		|• Check if it is possible to change ""key"" attributes by the user who has rights to do it.';");
#EndRegion
	
#Region PersonalDataProtection
	Subsystem = AddSubsystem("PersonalDataProtection");
	Subsystem.Synonym = NStr("ru = 'Защита персональных данных';
								|en = 'Personal data protection';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("Print,AttachableCommands");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Поддержка требований 152-ФЗ (""О персональных данных"").
		|• Управление событиями доступа к персональным данным (установка использования события, получение актуального состояния использования событий, подготовка формы настройки системы).
		|• Классификация персональных данных по областям.
		|• Учет согласий на обработку персональных данных.
		|• Скрытие персональных данных субъектов.';
		|en = '• Supporting the requirements of the Federal Law No. 152-FZ (""On personal data"").
		|• Managing events of access to personal data (setting event usage, getting relevant status of using events, preparing system setting form).
		|• Classifying personal data by areas.
		|• Considering consents to process personal data.
		|• Hiding subject personal data.';");
#EndRegion
	
#Region InformationOnStart
	Subsystem = AddSubsystem("InformationOnStart");
	Subsystem.Synonym = NStr("ru = 'Информация при запуске';
								|en = 'Startup notifications';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Отображение различной информации (например, рекламы) при запуске программы.';
								|en = '• Displaying various information (for example, advertisements) on the application startup.';");
#EndRegion
	
#Region ODataInterface
	Subsystem = AddSubsystem("ODataInterface");
	Subsystem.Synonym = NStr("ru = 'Стандартный интерфейс OData';
								|en = 'OData standard interface';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Настройка автоматического REST-сервиса для запроса и обновления данных.';
								|en = '• Setting automatic REST service for request and data update.';");
#EndRegion
	
#Region CalendarSchedules
	Subsystem = AddSubsystem("CalendarSchedules");
	Subsystem.Synonym = NStr("ru = 'Календарные графики';
								|en = 'Calendar schedules';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Хранение сведений о календарных графиках, используемых на предприятии.';
								|en = '• Storing info on calendar schedules that are used in the enterprise.';");
#EndRegion

#Region FormulasConstructor
	Subsystem = AddSubsystem("FormulasConstructor");
	Subsystem.Synonym = NStr("ru = 'Конструктор формул';
								|en = 'Formula editor';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("NationalLanguageSupport");
	Subsystem.LongDesc = NStr("ru = '• Предоставляет удобную форму редактирования формул, в которой выводятся доступные операнды и операторы.';
								|en = '• Provides a convenient form for editing formulas.';");
#EndRegion
	
#Region ContactInformation
	Subsystem = AddSubsystem("ContactInformation");
	Subsystem.Synonym = NStr("ru = 'Контактная информация';
								|en = 'Contact information';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("ItemOrderSetup,AttachableCommands");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("AddressClassifier");
	Subsystem.LongDesc = NStr("ru = '• Добавление к произвольным справочникам и документам реквизитов для ввода контактной информации: почтовых адресов, адресов электронной почты, телефонов и т. д.
		|• Автоматическая или ручная проверка корректности адресов (при совместном использовании с подсистемой ""Адресный классификатор"").
		|• Предоставление классификатора стран мира (ОКСМ).';
		|en = '• Add attributes to arbitrary catalogs and attribute documents to enter contact information: postal addresses, email addresses, phone numbers, and so on.
		|• Check automatically or manually if addresses are correct (when used together with the ""Address classifier"" subsystem).
		|• Provide the classifier of countries of the world (ARCC).';");
#EndRegion
	
#Region AccountingAudit
	Subsystem = AddSubsystem("AccountingAudit");
	Subsystem.Synonym = NStr("ru = 'Контроль ведения учета';
								|en = 'Data integrity';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("ReportsOptions,Users,AttachableCommands");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("ToDoList,AttachableCommands");
	Subsystem.LongDesc = NStr("ru = '• Контроль корректности данных информационной базы по произвольным прикладным правилам.
		|• Вывод выявленных проблем и способов их устранения для различных категорий пользователей.
		|• Заменить существующие системы-аналоги в ERP, СППР, БП 3.0 и БГУ.';
		|en = '• Validate infobase data using arbitrary applied rules.
		|• Identify issues and display ways to fix them for various user categories.
		|• Replace similar systems in ERP, ASDS, Enterprise Accounting 3.0, and Governmental Accounting.';");
#EndRegion
	
#Region UserMonitoring
	Subsystem = AddSubsystem("UserMonitoring");
	Subsystem.Synonym = NStr("ru = 'Контроль работы пользователей';
								|en = 'User monitoring';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("ReportsOptions,ReportMailing");
	Subsystem.LongDesc = NStr("ru = '• Отчеты по активности и работе пользователей, по продолжительности работы регламентных заданий и о критичных записях в журнале регистрации.';
								|en = '• Generate reports on user activity and operations, on the duration of scheduled jobs, and on critical records in the event log.';");
#EndRegion
	
#Region MachineReadableLettersOfAuthority
	Subsystem = AddSubsystem("MachineReadableLettersOfAuthority");
	Subsystem.Synonym = NStr("ru = 'Машиночитаемые доверенности (единый формат)';
								|en = 'Machine-readable letters of authority (unified format)';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems(
		"ContactInformation,
		|Print,
		|AttachableCommands,
		|GetFilesFromInternet,
		|FilesOperations,
		|ObjectPresentationDeclension,
		|DigitalSignature");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Программный и пользовательский интерфейс для работы с машиночитаемыми доверенностями в формате, соответствующему приказу Минцифры России от 18.08.2021 № 857 «Об утверждении единых требований к формам доверенностей, необходимых для использования квалифицированной электронной подписи».
		|• Регистрация доверенностей в распределенном реестре ФНС.';
		|en = '• Application and user interface for operations with machine-readable letters of authority in the format that corresponds to Order of the Ministry for Digital Development, Communications and Mass Media of the Russian Federation No. 857 dated 08/18/2021 ""On approving standardized format for letters of authority required to use a qualified digital signature"".
		|• Registration of letters of authority in the distributed ledger of the Federal Tax Service.';");
#EndRegion
	
#Region NationalLanguageSupport
	Subsystem = AddSubsystem("NationalLanguageSupport");
	Subsystem.Synonym = NStr("ru = 'Мультиязычность';
								|en = 'National Language Support';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Группа подсистем ""Мультиязычность"" содержит базовую функциональность, необходимую для работы с данными на нескольких языках.
		|Включает в себя ряд подсистем, которые расширяют возможности работы других подсистем с мультиязычными данными.
		|Их необходимо включать в конфигурацию только совместно с соответствующей основной подсистемой.
		|Например, если к внедрению отмечена подсистема ""Печать"", следует также отметить и подсистему ""Печать"" в группе ""Мультиязычность"".';
		|en = '• With National Language Support, your applications can support multiple languages.
		|It enhances the functionality of other subsystems that have multilingual data.
		|Each subsystem in National Language Support just complements its main subsystem.
		|Which means that the ""Print"" subsystem in National Language Support provides no printing features. To print a document, you need the main ""Print"" subsystem.';");
	
	Subsystem = AddSubsystem("NationalLanguageSupport.Core");
	Subsystem.Parent = "NationalLanguageSupport";
	Subsystem.Synonym = NStr("ru = 'Базовая функциональность (мультиязычность)';
								|en = 'Core: National Language Support';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = 'Включает в себя набор вспомогательных механизмов, которые используются другими подсистемами из группы ""Мультиязычность"".';
								|en = 'The core mechanisms that support other National Language Support subsystems.';");
	
	Subsystem = AddSubsystem("NationalLanguageSupport.Print");
	Subsystem.Parent = "NationalLanguageSupport";
	Subsystem.Synonym = NStr("ru = 'Печать (мультиязычность)';
								|en = 'Print: National Language Support';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("Print,"
		+ "NationalLanguageSupport.Core");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Вывод печатных форм на разных языках.';
								|en = '• Print out documents in multiple languages.';");
	
	Subsystem = AddSubsystem("NationalLanguageSupport.TextTranslation");
	Subsystem.Parent = "NationalLanguageSupport";
	Subsystem.Synonym = NStr("ru = 'Перевод текста (мультиязычность)';
								|en = 'Translator: National Language Support';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("NationalLanguageSupport.Core,GetFilesFromInternet");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Перевод текста с помощью онлайн-переводчиков.';
								|en = '• Translate texts with online services.';");
#EndRegion
	
#Region UserReminders
	Subsystem = AddSubsystem("UserReminders");
	Subsystem.Synonym = NStr("ru = 'Напоминания пользователя';
								|en = 'User reminders';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("AttachableCommands");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Ввод персональных напоминаний на нужное время.
		|• Привязка напоминаний к произвольным справочникам, документам и обсуждениям.';
		|en = '• Entering personal reminders in the application for the required time.
		|• Connecting reminders to catalogs, documents, and chats.';");
#EndRegion
	
#Region ItemOrderSetup
	Subsystem = AddSubsystem("ItemOrderSetup");
	Subsystem.Synonym = NStr("ru = 'Настройка порядка элементов';
								|en = 'Item order';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Настройка порядка элементов произвольных списков с помощью кнопок Вверх и Вниз.';
								|en = '• Setting order of arbitrary list items using the Up and Down buttons.';");
#EndRegion
	
#Region ApplicationSettings
	Subsystem = AddSubsystem("ApplicationSettings");
	Subsystem.Synonym = NStr("ru = 'Настройки программы';
								|en = 'Application settings';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Готовые рабочие места (панели) для раздела ""Администрирование"".
		|• Подстройка состава панелей администрирования под текущий режим работы программы.';
		|en = '• Ready workstations (panels) for the Administration section.
		|• Adjusting administration panel content to the current application mode.';");
#EndRegion
	
#Region DataExchange
	Subsystem = AddSubsystem("DataExchange");
	Subsystem.Synonym = NStr("ru = 'Обмен данными';
								|en = 'Data exchange';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("ConfigurationUpdate,ScheduledJobs,GetFilesFromInternet,ObjectsPrefixes");
	Subsystem.LongDesc = NStr("ru = '• Программный интерфейс и готовые рабочие места для организации совместной работы в распределенной информационной базе и для синхронизации данных с другими программами.
		|• Синхронизация данных по требованию и в автоматическом режиме по расписанию.
		|• Подключение через различные каналы связи: локальный или сетевой каталог, электронная почта, FTP-ресурс или через Интернет (в том числе синхронизация данных с приложениями в ""облаке"").
		|• Гибкая настройка правил синхронизации данных между программами, помощник сопоставления одинаковых данных.
		|• Средства мониторинга и диагностики синхронизации данных.
		|• Возможность разработки планов обмена с использованием правил конвертации данных или без них, удобная отладка обработчиков событий правил конвертации в конфигураторе.
		|• Автоматическое обновление конфигурации подчиненного узла РИБ (при совместном использовании с подсистемой ""Обновление конфигурации"").';
		|en = '• Application interface and ready workstations to organize collaboration in distributed infobase and to synchronize data with other applications.
		|• Data synchronization upon request and in auto mode on schedule.
		|• Connect via different communication links: local or network directory, email, FTP resource or via the Internet (including data synchronization with cloud applications).
		|• Flexible setup of data synchronization rules between applications, assistant to map similar data.
		|• Tools for monitoring and diagnosing data synchronization.
		|• The ability to develop exchange plans with or without data conversion rules, convenient debugging of event handlers for conversion rules in Designer.
		|• Automatic update of subordinate DIB node configuration (when used together with the ""Configuration update"" subsystem).';");
#EndRegion
	
#Region IBVersionUpdate
	Subsystem = AddSubsystem("IBVersionUpdate");
	Subsystem.Synonym = NStr("ru = 'Обновление версии ИБ';
								|en = 'Infobase version update';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Выполнение первоначального заполнения и обновления данных информационной базы при изменении версии конфигурации.
		|• Отображение информации об изменениях в новой версии конфигурации.
		|• Программный интерфейс для выполнения монопольных, оперативных и отложенных обработчиков обновления.';
		|en = '• Perform initial population and update of the infobase data when a configuration version changes.
		|• Display details of the new version updates.
		|• Provide API to run exclusive, real-time and deferred update handlers.';");
#EndRegion
	
#Region ConfigurationUpdate
	Subsystem = AddSubsystem("ConfigurationUpdate");
	Subsystem.Synonym = NStr("ru = 'Обновление конфигурации';
								|en = 'Configuration update';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("UsersSessions");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("EmailOperations,SoftwareLicenseCheck,AccountingAudit");
	Subsystem.LongDesc = NStr("ru = '• Автоматическое обновление конфигурации (без открытия конфигуратора) по требованию, в указанное время в будущем или при завершении работы программы.
		|• Проверка и получение обновлений конфигурации через Интернет (по требованию или по расписанию).
		|• Обновление из указанного файла в локальном или сетевом каталоге.
		|• Применение изменений основной конфигурации к конфигурации базы данных.';
		|en = '• Automatically update the configuration (without opening Designer) on demand, at scheduled time, or upon exiting the application.
		|• Check for configuration updates and download them via the Internet (manually or on schedule).
		|• Update the application from files in local or network directories.
		|• Apply main configuration changes to the database configuration.';");
#EndRegion
	
#Region Companies
	Subsystem = AddSubsystem("Companies");
	Subsystem.Synonym = NStr("ru = 'Организации';
								|en = 'Companies';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Программный интерфейс для получения данных по организации.';
								|en = '• Application interface to get company data.';");
#EndRegion
	
#Region Conversations
	Subsystem = AddSubsystem("Conversations");
	Subsystem.Synonym = NStr("ru = 'Обсуждения';
								|en = 'Conversations';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Подключение к интернет-сервису системы взаимодействия, с помощью которого пользователи программы могут общаться друг с другом в режиме реального времени, создавать тематические обсуждения и вести переписку по конкретным документам (например, заказам, реализациям или контрагентам).
		|• Подключение чатов в мессенджерах и социальных сетях для общения с клиентами.';
		|en = '• Enable the Internet service of the collaboration system so that application users can communicate with each other online, create topic conversations, and correspond on specific documents, for example, orders, sales, or counterparties.
		|• Enable chats in messengers and social networks to communicate with customers.';");
#EndRegion
	
#Region SendSMSMessage
	Subsystem = AddSubsystem("SendSMSMessage");
	Subsystem.Synonym = NStr("ru = 'Отправка SMS';
								|en = 'Text messaging';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("GetFilesFromInternet");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Программный интерфейс по рассылке и проверка статусов доставки сообщений SMS.';
								|en = '• Bulk email and text messaging. SMS delivery status.';");
#EndRegion
	
#Region DocumentRecordsReport
	Subsystem = AddSubsystem("DocumentRecordsReport");
	Subsystem.Synonym = NStr("ru = 'Отчет о движениях документа';
								|en = 'Document record history';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("AttachableCommands,ReportsOptions");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Позволяет просматривать движения произвольных документов, которые при проведении, отражают зафиксированные ими события в регистрах.';
								|en = '• Allows to view register records of documents that, when posted, reflect changes in registers.';");
#EndRegion
	
#Region PerformanceMonitor
	Subsystem = AddSubsystem("PerformanceMonitor");
	Subsystem.Synonym = NStr("ru = 'Оценка производительности';
								|en = 'Performance monitor';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Оценка интегральной производительности системы по методике APDEX.
		|• Упрощает и автоматизирует сбор информации о времени выполнения каждой ключевой операции.
		|• Средства анализа результатов замера.
		|• Автоматический экспорт показателей производительности.';
		|en = '• Evaluating integral system productivity by APDEX method.
		|• It simplifies and automates collection of information on the execution time of each key operation.
		|• Tools to analyze measurement results.
		|• Automatic export of performance indicators.';");
#EndRegion
	
#Region Print
	Subsystem = AddSubsystem("Print");
	Subsystem.Synonym = NStr("ru = 'Печать';
								|en = 'Print';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("AttachableCommands,FormulasConstructor");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("FilesOperations,AdditionalReportsAndDataProcessors,EmailOperations,SourceDocumentsOriginalsRecording");
	Subsystem.LongDesc = NStr("ru = '• Программный интерфейс и готовое рабочее место для формирования печатных форм произвольных объектов приложения.
		|• Вывод печатных форм в виде табличных документов и офисных документов Office Open XML (docx).
		|• Отправка печатных форм по электронной почте, сохранение на компьютер или в присоединенных файлах (при совместном использовании с подсистемой ""Присоединенные файлы"").
		|• Подключение внешних печатных форм, а также печать внешних печатных форм в комплекте с основными печатными формами (при совместном использовании с подсистемой ""Дополнительные отчеты и обработки"").
		|• Вывод в печатную форму изображения QR-кода по заданной текстовой строке.';
		|en = '• Application interface and ready workstation to generate print forms of arbitrary applied objects.
		|• Output of print forms as spreadsheet documents and office documents Office Open XML (docx).
		|• Send print forms via email, saving them to the computer or in attachments (when using together with the ""Attachments"" subsystem).
		|• Attach external print forms and printing them together with main print forms (when using together with the ""Additional reports and data processors"" subsystem).
		|• Output the QR code picture to the print form by a given text string.';");
#EndRegion
	
#Region AttachableCommands
	Subsystem = AddSubsystem("AttachableCommands");
	Subsystem.Synonym = NStr("ru = 'Подключаемые команды';
								|en = 'Attachable commands';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("ReportsOptions,AdditionalReportsAndDataProcessors,Print");
	Subsystem.LongDesc = NStr("ru = '• Программный интерфейс для вывода динамически подключаемых команд и интеграции с расширениями.
	|• Подстройка состава команд под типы выбранных объектов в журналах документов и под значения реквизитов объектов.';
	|en = '• Application interface to output dynamically attachable commands and integrations with extensions.
	|• Adapting command components to types of selected documents in document journals and to object attribute values.';");
#EndRegion
	
#Region DuplicateObjectsDetection
	Subsystem = AddSubsystem("DuplicateObjectsDetection");
	Subsystem.Synonym = NStr("ru = 'Поиск и удаление дублей';
								|en = 'Duplicate cleaner';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Поиск и удаление дублирующихся элементов справочников.';
								|en = '• Search and clean up duplicate catalog items.';");
#EndRegion
	
#Region FullTextSearch
	Subsystem = AddSubsystem("FullTextSearch");
	Subsystem.Synonym = NStr("ru = 'Полнотекстовый поиск';
								|en = 'Full-text search';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Настройка и выполнение полнотекстового поиска по всем данным в приложении.';
								|en = '• Setting and full text search by all application data.';");
#EndRegion
	
#Region GetFilesFromInternet
	Subsystem = AddSubsystem("GetFilesFromInternet");
	Subsystem.Synonym = NStr("ru = 'Получение файлов из Интернета';
								|en = 'Network download';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Программный интерфейс для получения файлов из Интернета.
		|• Получение файла из сети на клиенте.
		|• Сохранение файлов на клиентском компьютере, в информационной базе.
		|• Запрос и хранение параметров прокси-сервера.';
		|en = '• Application interface to get files from the Internet.
		|• Getting a file from the network on the client.
		|• Saving files to client computer and to the infobase.
		|• Requesting and storing proxy server parameters.';");
#EndRegion
	
#Region Users
	Subsystem = AddSubsystem("Users");
	Subsystem.Synonym = NStr("ru = 'Пользователи';
								|en = 'Users';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("AccessManagement,ContactInformation");
	Subsystem.LongDesc = NStr("ru = '• Ведение списка пользователей, работающих в приложении.
		|• Ведение списка внешних пользователей, имеющих ограниченный доступ к специализированным рабочим местам (например, ""Мои заказы"", ""Анкеты респондента"", ""Оформление заявок"" и т. п.).
		|• Настройка прав доступа пользователей и внешних пользователей (при внедрении совместно с подсистемой ""Управление доступом"" осуществляется средствами подсистемы ""Управление доступом"").
		|• Группировка списка пользователей (и внешних пользователей).
		|• Очистка и копирование настроек отчетов, форм, рабочего стола, разделов командного интерфейса, избранного, печати табличных документов и других персональных настроек пользователей (и внешних пользователей).';
		|en = '• Keep the list of users that work in the application.
		|• Keep the list of users that have restricted access to specialized workstations (for example, ""My orders"", ""Respondent questionnaires"", ""Create requests"", and so on).
		|• Set up access rights of users and external users (when implementing together with the ""Access management"" subsystem it is done using the ""Access management"" subsystem tools).
		|• Grouping the list of users (and external users).
		|• Clear and copy settings of reports, forms, desktop, command interface sections, favorites, spreadsheet document printing and other personal settings of users and external users.';");
#EndRegion
	
#Region ObjectsPrefixes
	Subsystem = AddSubsystem("ObjectsPrefixes");
	Subsystem.Synonym = NStr("ru = 'Префиксация объектов';
								|en = 'Object prefixes';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Автоматическое назначение префиксов объектам с учетом настроек программы.
		|• Префиксация объектов в разрезах информационных баз и элементов справочника Организации.
		|• Программный интерфейс для перепрефиксации справочников и документов при изменении префикса информационной базы.';
		|en = '• Automatic assignment of prefixes to objects considering application settings.
		|• Object prefixation broken down by infobases and the Companies catalog items.
		|• Application interface to reprefix catalogs and documents when changing infobase prefix.';");
#EndRegion
	
#Region SoftwareLicenseCheck
	Subsystem = AddSubsystem("SoftwareLicenseCheck");
	Subsystem.Synonym = NStr("ru = 'Проверка легальности получения обновления';
								|en = 'Licensed update verification';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Программный и пользовательский интерфейсы для подтверждения легальности получения обновления конфигурации.';
								|en = '• Application and user interface to confirm that configuration update was obtained legally.';");
#EndRegion
	
#Region SecurityProfiles
	Subsystem = AddSubsystem("SecurityProfiles");
	Subsystem.Synonym = NStr("ru = 'Профили безопасности';
								|en = 'Security profiles';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Работа с профилями безопасности информационной базы.
		|Настройка разрешений на использование внешних ресурсов.';
		|en = '• Operations with infobase security profiles
		|• Setting permissions to use external resources.';");
#EndRegion
	
#Region SaaSOperations
	Subsystem = AddSubsystem("SaaSOperations");
	Subsystem.Synonym = NStr("ru = 'Работа в модели сервиса';
								|en = 'SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("DataExchange,ScheduledJobs,UsersSessions");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = 'Подсистема ""Работа в модели сервиса"" содержит базовую функциональность, обязательную для всех прикладных решений, рассчитанных на работу в модели сервиса.
		|Также включает в себя ряд подсистем, не предназначенных для самостоятельного использования.
		|Их необходимо включать в конфигурацию только совместно с соответствующей основной подсистемой.
		|Например, если к внедрению отмечена подсистема ""Пользователи"", следует также отметить и подсистему ""Пользователи в модели сервиса"".';
		|en = 'The ""SaaS"" subsystem contains core required for all applications designed to work in SaaS.
		|It also includes a number of subsystems not intended for independent use.
		|They must be included in the configuration only together with the matching main subsystem.
		|For example if the ""Users"" subsystem is marked for integration, the ""Users SaaS"" subsystem must be marked too.';");
	
	Subsystem = AddSubsystem("SaaSOperations.CoreSaaS");
	Subsystem.Parent = "SaaSOperations";
	Subsystem.Synonym = NStr("ru = 'Базовая функциональность в модели сервиса';
								|en = 'Core SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("SaaSOperations.IBVersionUpdateSaaS,SaaSOperations.UsersSaaS");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = 'Включает в себя набор вспомогательных механизмов, которые используются другими подсистемами из ветки ""Работа в модели сервиса"".';
								|en = 'Includes a set of auxiliary functionalities used by other subsystems from SaaS.';");
	
	Subsystem = AddSubsystem("SaaSOperations.AddInsSaaS");
	Subsystem.Parent = "SaaSOperations";
	Subsystem.Synonym = NStr("ru = 'Внешние компоненты в модели сервиса';
								|en = 'Add-ins SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("AddIns,"
		+ "SaaSOperations.CoreSaaS,"
		+ "SaaSOperations.IBVersionUpdateSaaS,"
		+ "SaaSOperations.UsersSaaS");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = 'Обеспечивает возможность подключения и использования внешних компонент в приложении, выполняющемся в модели сервиса.';
								|en = 'Provides the ability to connect and use add-ins in an application running in SaaS.';");
	
	Subsystem = AddSubsystem("SaaSOperations.AdditionalReportsAndDataProcessorsSaaS");
	Subsystem.Parent = "SaaSOperations";
	Subsystem.Synonym = NStr("ru = 'Дополнительные отчеты и обработки в модели сервиса';
								|en = 'Additional reports and data processors SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("AdditionalReportsAndDataProcessors,SecurityProfiles,"
		+ "SaaSOperations.CoreSaaS,"
		+ "SaaSOperations.IBVersionUpdateSaaS,"
		+ "SaaSOperations.UsersSaaS");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = 'Обеспечивает возможность подключения и использования дополнительных отчетов и обработок в приложении, выполняющемся в модели сервиса.';
								|en = 'Provides the ability to connect and use additional reports and data processors in an application running in SaaS.';");
	
	Subsystem = AddSubsystem("SaaSOperations.DataExchangeSaaS");
	Subsystem.Parent = "SaaSOperations";
	Subsystem.Synonym = NStr("ru = 'Обмен данными в модели сервиса';
								|en = 'Data exchange SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems(
		"DataExchange,"
		+ "SaaSOperations.CoreSaaS,"
		+ "SaaSOperations.IBVersionUpdateSaaS,"
		+ "SaaSOperations.UsersSaaS,"
		+ "SaaSOperations.FilesOperationsSaaS");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = 'Обеспечивает функциональность, связанную с обменом информацией между различными приложениями при выполнении в модели сервиса.';
								|en = 'Provides functionality related to the exchange of information between different applications when executed in SaaS.';");
	
	Subsystem = AddSubsystem("SaaSOperations.IBVersionUpdateSaaS");
	Subsystem.Parent = "SaaSOperations";
	Subsystem.Synonym = NStr("ru = 'Обновление версии в модели сервиса';
								|en = 'Infobase version update SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("IBVersionUpdate,UsersSessions,"
		+ "SaaSOperations.CoreSaaS,SaaSOperations.UsersSaaS");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = 'Обеспечивает функциональность, связанную с обновлением версий информационных баз при работе в модели сервиса.';
								|en = 'Provides functionality connected with updating infobase versions when working in SaaS.';");
	
	Subsystem = AddSubsystem("SaaSOperations.UsersSaaS");
	Subsystem.Parent = "SaaSOperations";
	Subsystem.Synonym = NStr("ru = 'Пользователи в модели сервиса';
								|en = 'Users SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("Users,"
		+ "SaaSOperations.CoreSaaS,SaaSOperations.IBVersionUpdateSaaS");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = 'Обеспечивает работу с пользователями для прикладного решения, выполняющегося в модели сервиса.';
								|en = 'Provides user experience for an application that runs in SaaS.';");
	
	Subsystem = AddSubsystem("SaaSOperations.FilesOperationsSaaS");
	Subsystem.Parent = "SaaSOperations";
	Subsystem.Synonym = NStr("ru = 'Работа с файлами в модели сервиса';
								|en = 'File management SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("FilesOperations,FullTextSearch,"
		+ "SaaSOperations.CoreSaaS,"
		+ "SaaSOperations.IBVersionUpdateSaaS,"
		+ "SaaSOperations.UsersSaaS");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = 'Обеспечивает возможность выгрузки в файл и загрузки из файла данных приложения, выполняющегося в модели сервиса.';
								|en = 'Provides the ability to export to a file and import from an application data file running in SaaS.';");
	
	Subsystem = AddSubsystem("SaaSOperations.AccessManagementSaaS");
	Subsystem.Parent = "SaaSOperations";
	Subsystem.Synonym = NStr("ru = 'Управление доступом в модели сервиса';
								|en = 'Access management SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("AccessManagement,"
		+ "SaaSOperations.CoreSaaS,"
		+ "SaaSOperations.IBVersionUpdateSaaS,"
		+ "SaaSOperations.UsersSaaS");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = 'Позволяет настраивать права пользователей для произвольных элементов данных приложения (элементов справочников,
		|документов, записей регистров, бизнес-процессов, задач и т. д.) приложения, выполняющегося в модели сервиса.';
		|en = 'Allows you to configure user rights for arbitrary items of the application data (items of catalogs,
		|documents, register records, business processes, tasks, and so on) of the application running in SaaS.';");
	
#EndRegion
	
#Region EmailOperations
	Subsystem = AddSubsystem("EmailOperations");
	Subsystem.Synonym = NStr("ru = 'Работа с почтовыми сообщениями';
								|en = 'Email management';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Программный интерфейс для отправки и получения сообщений электронной почты.
		|• Ведение списка учетных записей для работы с электронной почтой.
		|• Базовый пользовательский интерфейс для отправки сообщений.';
		|en = '• Application interface to send and receive emails.
		|• Keeping a list of accounts to work with email.
		|• Basic user interface to send messages.';");
#EndRegion
	
#Region FilesOperations
	Subsystem = AddSubsystem("FilesOperations");
	Subsystem.Synonym = NStr("ru = 'Работа с файлами';
								|en = 'File management';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("ReportsOptions,Properties,AccessManagement");
	Subsystem.LongDesc = NStr("ru = '• Коллективное редактирование файлов в иерархической структуре папок.
		|• Хранение и предоставление доступа к версиям файлов.
		|• Присоединение файлов из файловой системы, создание файлов по шаблону или получение со сканера.
		|• Электронная подпись, шифрование.
		|• Программный и пользовательский интерфейсы для присоединения файлов (вложений) к произвольным объектам программы.
		|• Поддержка произвольного количества разных типов владельцев файлов без потери в скорости работы в условиях ограничения доступа пользователей на уровне записей.
		|• Коллективное редактирование файлов, сканирование, электронная подпись и шифрование.
		|• Общие функции и базовые пользовательские интерфейсы по работе с файлами, хранение файлов в томах, функции для поддержки РИБ и создания первоначального образа информационной базы.';
		|en = '• Collaboratively manage files in a hierarchical folder structure.
		|• Store and grant access to file versions.
		|• Attach files from the file system, create files from templates, or get them from scanner.
		|• Digitally sign and encrypt files.
		|• Use the API and user interface to attach files to the application objects.
		|• Use multiple file owners without compromising performance under access restrictions at the record level.
		|• Collaboratively edit, scan, digitally sign, and encrypt files.
		|• Use common functions and basic user interface to manage files and store them in volumes, as well as functions to support DIB and create initial image of an infobase.';");
#EndRegion
	
#Region ReportMailing
	Subsystem = AddSubsystem("ReportMailing");
	Subsystem.Synonym = NStr("ru = 'Рассылка отчетов';
								|en = 'Report distribution';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("ReportsOptions,ContactInformation,EmailOperations");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("AdditionalReportsAndDataProcessors,GetFilesFromInternet,FilesOperations,AccessManagement,BatchEditObjects");
	Subsystem.LongDesc = NStr("ru = '• Рассылка отчетов и дополнительных отчетов по электронной почте.
		|• Публикация отчетов на FTP, в сетевых каталогах и в папках подсистемы ""Работа с файлами"".
		|• Запуск по расписанию или интерактивно.';
		|en = '• Email reports to a user list.
		|• Publish reports on FTP, in network directories, or in folders of the ""File management"" subsystem.
		|• Send emails manually or set up a schedule.';");
#EndRegion
	
#Region ScheduledJobs
	Subsystem = AddSubsystem("ScheduledJobs");
	Subsystem.Synonym = NStr("ru = 'Регламентные задания';
								|en = 'Scheduled jobs';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Вывод списка и настройка параметров регламентных заданий (расписание, запуск, остановка).';
								|en = '• Outputting list and setting scheduled job parameters (schedule, startup, stop).';");
#EndRegion
	
#Region IBBackup
	Subsystem = AddSubsystem("IBBackup");
	Subsystem.Synonym = NStr("ru = 'Резервное копирование ИБ';
								|en = 'Infobase backup';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("UsersSessions");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Сохранение резервных копий файловой информационной базы по требованию или по заданному расписанию.
		|• Восстановление файловой информационной базы из копии.
		|• Уведомление о необходимости настройки резервного копирования (также в клиент-серверном режиме).';
		|en = '• Saving reserve file infobase copies upon request or on the specified schedule.
		|• Restoring file infobase from the copy.
		|• Notifying that it is required to set up backups (also in client/server mode).';");
#EndRegion
	
#Region Properties
	Subsystem = AddSubsystem("Properties");
	Subsystem.Synonym = NStr("ru = 'Свойства';
								|en = 'Properties';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("ObjectAttributesLock");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Добавление дополнительных свойств к произвольным документам и справочникам.
		|• Вывод значений свойств в любых отчетах и динамических списках.
		|• Раздельное хранение свойств как в самом объекте (дополнительные реквизиты), так и вне объекта-владельца в отдельном регистре сведений (дополнительные сведения).
		|• Возможность задавать одинаковые свойства для различных объектов, свойства, обязательные к заполнению, и другие сервисные возможности.';
		|en = '• Adding additional properties to arbitrary documents and catalogs.
		|• Outputting property values in any reports and dynamic lists.
		|• Storing properties separately both in the object itself (additional attributes) and outside of owner object in a separate information register (additional info).
		|• The ability to set similar properties for different objects, required properties and other server features.';");
#EndRegion
	
#Region ObjectPresentationDeclension
	Subsystem = AddSubsystem("ObjectPresentationDeclension");
	Subsystem.Synonym = NStr("ru = 'Склонение представлений объектов';
								|en = 'Declension tool';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("GetFilesFromInternet");
	Subsystem.LongDesc = NStr("ru = '• Автоматическое склонение представлений объектов с возможностью ручной корректировки пользователем.';
								|en = '• Automatic declension of object presentations with available manual user correction.';");
#EndRegion
	
#Region SubordinationStructure
	Subsystem = AddSubsystem("SubordinationStructure");
	Subsystem.Synonym = NStr("ru = 'Структура подчиненности';
								|en = 'Hierarchy';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Отображение информации о родительских и дочерних документах для выбранного документа, а также всей структуры их взаимосвязей.';
								|en = '• Display of information on parent and child documents for the selected document and their interaction structure.';");
#EndRegion
	
#Region ToDoList
	Subsystem = AddSubsystem("ToDoList");
	Subsystem.Synonym = NStr("ru = 'Текущие дела';
								|en = 'To-do list';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Вывод списка текущих дел пользователя на рабочем столе (новые письма, задачи, заявки, несогласованные заказы и т. п.).';
								|en = '• Display of user to-dos on the desktop (new emails, tasks, requests, unapproved orders, and so on).';");
#EndRegion
	
#Region MarkedObjectsDeletion
	Subsystem = AddSubsystem("MarkedObjectsDeletion");
	Subsystem.Synonym = NStr("ru = 'Удаление помеченных объектов';
								|en = 'Marked object deletion';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Удаление объектов, помеченных на удаление. С контролем целостности (проверка ссылок на удаляемые объекты из других объектов).
		|• Фоновое удаление по расписанию.';
		|en = '• Deletion of objects marked for deletion. With integrity control (check of references to the objects being deleted from other objects).
		|• Scheduled background deletion.';");
#EndRegion
	
#Region AccessManagement
	Subsystem = AddSubsystem("AccessManagement");
	Subsystem.Synonym = NStr("ru = 'Управление доступом';
								|en = 'Access management';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Индивидуальная и групповая настройка прав доступа пользователей с помощью профилей и групп доступа.
		|• Настройка ограничений прав доступа на уровне записей - для отдельных элементов данных информационной базы (элементов справочников, документов, записей регистров и т. д.).
		|• Отчет по правам интересующего пользователя или группы пользователей.
		|• Предусмотрены два варианта внедрения в прикладное решение - обычный и упрощенный.
		|Обычный режим настройки прав доступа рассчитан на многопользовательские прикладные решения, в которых, как правило, выполняется групповая настройка прав, на базе групп доступа.
		|В упрощенном режиме настройка прав выполняется индивидуально для каждого пользователя.
		|Второй режим предназначен для конфигураций с небольшим числом пользователей, каждый из которых обладает своим собственным уникальным набором прав.';
		|en = '• Individual and group setting of user access rights using profiles and access groups.
		|• Setting access right restrictions on the record level: for separate infobase data items (items of catalogs, documents, register records, and so on.)
		|• Report on the rights of a user or a user group of interest.
		|• There are two options for integration into application: usual and simplified.
		|The usual mode of setting access rights is designed for multi-user applications, where, as a rule, group right setting is performed on the access group basis.
		|In the simplified mode, rights are set individually for each user.
		|The second mode is designed for configuration with a small number of users, each of them having his own set of rights.';");
#EndRegion
	
#Region TotalsAndAggregatesManagement
	Subsystem = AddSubsystem("TotalsAndAggregatesManagement");
	Subsystem.Synonym = NStr("ru = 'Управление итогами и агрегатами';
								|en = 'Totals and aggregates';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Администрирование итогов и агрегатов оборотных регистров накопления.
		|• Регламентное выполнение операций переноса границы итогов, пересчета и обновления агрегатов (по расписанию, при завершении работы программы).';
		|en = '• Administration of totals and turnover accumulation registers
		|• Scheduled operation execution on shifting the limit of totals, recalculation and update of aggregates (on schedule and when closing the application).';");
#EndRegion
	
#Region SourceDocumentsOriginalsRecording
	Subsystem = AddSubsystem("SourceDocumentsOriginalsRecording");
	Subsystem.Synonym = NStr("ru = 'Учет оригиналов первичных документов';
								|en = 'Source document tracking';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("ItemOrderSetup,AttachableCommands,Print,ObjectsPrefixes,AdditionalReportsAndDataProcessors");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("ru = '• Фиксация наличия подписанных оригиналов исходящих/входящих  первичных документов.
	|• Хранение и предоставление текущих состояний оригиналов первичных документов.';
	|en = '• Record whether signed originals of outgoing or incoming documents are available.
	|• Store and provide current states of source document originals.';");
#EndRegion
	
#Region MonitoringCenter
	Subsystem = AddSubsystem("MonitoringCenter");
	Subsystem.Synonym = NStr("ru = 'Центр мониторинга';
								|en = 'Monitoring center';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("PerformanceMonitor");
	Subsystem.LongDesc = NStr("ru = '• Собирает обезличенную статистику по использованию конфигурации
		|• Передает обезличенную статистику в единый центр контроля качества.';
		|en = '• Collects impersonal configuration usage statistics
		|• Transfers the impersonal statistics to the unified quality control center.';");
#EndRegion
	
#Region MessageTemplates
	Subsystem = AddSubsystem("MessageTemplates");
	Subsystem.Synonym = NStr("ru = 'Шаблоны сообщений';
								|en = 'Message templates';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("Interactions,AdditionalReportsAndDataProcessors,Print,SendSMSMessage,EmailOperations,FilesOperations");
	Subsystem.LongDesc = NStr("ru = '• Отправка писем и сообщений SMS сформированных на основании справочников или документов и по заранее подготовленным шаблонам сообщений.
		|• Разработка шаблонов сообщений для почты и сообщений SMS.
		|• Программный интерфейс для возможности отправки типовых уведомлений созданных по шаблону в виде писем и сообщений SMS.';
		|en = '• Sending emails and SMS messages generated on the basis of catalogs or documents and according to prearranged message templates.
		|• Developing message templates for mail and SMS messages.
		|• Application interface to send standard notifications created according to template as emails and SMS messages.';");
#EndRegion
	
#Region DigitalSignature
	Subsystem = AddSubsystem("DigitalSignature");
	Subsystem.Synonym = NStr("ru = 'Электронная подпись';
								|en = 'Digital signature';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("ContactInformation,AddressClassifier,Print,UserReminders,ReportsOptions,GetFilesFromInternet");
	Subsystem.LongDesc = NStr("ru = '• Программный и пользовательский интерфейс для работы со средствами криптографии: электронная подпись и проверка подписи.
		|• Отправка заявлений на выпуск сертификата КЭП в УЦ ""1С"" и установка их на компьютере.';
		|en = '• Application and user interface to work with cryptography tools: digital signature and signature check.
		|• Send applications to 1C Certificate authority to issue a certificate of encrypted and certified digital signature and install them on the computer.';");
#EndRegion
	
#Region DSSElectronicSignatureService
	Subsystem = AddSubsystem("DSSElectronicSignatureService");
	Subsystem.Synonym = NStr("ru = 'Электронная подпись сервиса DSS';
								|en = 'DSS service digital signature';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("DigitalSignature,GetFilesFromInternet,AttachableCommands");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("ReportsOptions,AttachableCommands");
	Subsystem.LongDesc = NStr("ru = '• Программный и пользовательский интерфейс для работы с электронной подписью и выполнения операций криптографии с криптографическими ключами хранящиеся на серверах КриптоПро DSS.
		|• Дополняет возможности подсистемы ""Электронная подпись"" для работы с ключами и сертификатами хранящиеся на сервере DSS';
		|en = '• Programming and user interface for managing digital signatures and completing cryptography operations with cryptographic keys stored on the CryptoPro DSS servers.
		|• It adds new features to the ""Digital signature"" subsystem and enables you to use keys and certificates stored in the DSS server';");
#EndRegion
	
	Return Subsystems;
	
EndFunction

#EndRegion

#Region Private

// Returns:
//  ValueTable:
//    * Name - String
//    * Synonym  - String
//    * Required - Boolean
//    * DependsOnSubsystems - Array of String
//    * ConditionallyDependsOnSubsystems - Array of String
//    * LongDesc - String
//    * Check - Boolean
//    * Parent - String
// 
Function InitializeTable()
	
	Subsystems = New ValueTable;
	Subsystems.Columns.Add("Name");
	Subsystems.Columns.Add("Synonym");
	Subsystems.Columns.Add("Required");
	Subsystems.Columns.Add("DependsOnSubsystems");
	Subsystems.Columns.Add("ConditionallyDependsOnSubsystems");
	Subsystems.Columns.Add("LongDesc");
	Subsystems.Columns.Add("Check");
	Subsystems.Columns.Add("Parent");
	Return Subsystems;
	
EndFunction

Function DependenceOnSubsystems(SubsystemsNames)
	
	If IsBlankString(SubsystemsNames) Then
		DependsOnSubsystems = New Array;
	Else
		DependsOnSubsystems = StrSplit(SubsystemsNames, ", " + Chars.LF, False);
	EndIf;
	Return DependsOnSubsystems;
	
EndFunction

// Parameters:
//  SubsystemName - String
//
// Returns:
//  ValueTableRow of See InitializeTable 
// 
Function AddSubsystem(SubsystemName)
	
	NewRow = Subsystems.Add();
	NewRow.Name = SubsystemName;
	NewRow.Required = RequiredSubsystems[SubsystemName] <> Undefined;
	NewRow.Check = NewRow.Required;
	
	Return NewRow;
	
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf