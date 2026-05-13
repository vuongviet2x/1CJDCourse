///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "ContactTechnicalSuppor" subsystem.
// CommonModule.ContactTechnicalSupportServerCall.
//
// Server procedures and functions for contacting support: 
// - Send messages to 1C:ITS
//  - Prepare message attachments
//  - Generate a URL for navigating to the request page
//  
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Generates a message for sending a support ticket.
// The parameters include autofill data, attachments, and
// Event log import parameters.
//
// Parameters:
//  MessageData - Structure - Data for generating a message. 
//                    See MessagesToTechSupportServiceClientServer.MessageData
//                                .
//  Attachments - Array of Structure, Undefined - Attachment files. NOTE: Only text files (TXT, JSON, XML) are supported.
//              Attachment structure fields are:
//   *Presentation - String - The attachment presentation. For example, "Attachment_1.txt".
//   *DataKind - String - Determines the passed data conversion.
//                Valid values are:
//                  - ИмяФайла - String - The full name of an attached file.
//                  - Адрес - String - The address of the BinaryData-type value in the temporary storage.
//                  - Текст - String - The attachment text.
//   *Data - String - Data for attachment generation.
//  EventLog - Structure, Undefined - Event log export settings:
//    *StartDate    - Date - Event period start date.
//    *EndDate - Date - Event period end date.
//    *Events       - Array - An event list.
//    *Metadata    - Array, Undefined - A metadata array for filtering.
//    *Level       - String - A logging level. Valid values are:
//       - "Ошибка" - Filter events with EventLogLevel.Error.
//       - "Предупреждение" - Filter events with EventLogLevel.Warning.
//       - "Информация" - Filter events with EventLogLevel.Information.
//       - "Примечание" - Filter events with EventLogLevel.Note.
//
// Returns:
//  Structure - The message send result:
//   *ErrorCode - String - A send error id.:
//                          - <Пустая строка> - Sent successfully.
//                          - "НеверныйФорматЗапроса" - Invalid support ticket parameters.
//                             
//                          - "НеизвестнаяОшибка" - Error sending the ticket.
//                          - "НеизвестнаяОшибкаСервиса" - Service issues when sending the ticket.
//                          - "ОтсутствуетОбязательныйПараметрЗапроса" - The support ticket is missing a mandatory parameter.
//                             
//                          - "ОшибкаФайловойСистемы" - File system error.
//                          - "ПревышенМаксимальныйРазмерВложения" - The maximum attachment size is exceeded.
//                          - "ПревышенМаксимальныйРазмерЖурналаРегистрации" - The maximum log size is exceeded.
//                             
//                          - "ПустойПараметрЗапроса" - A mandatory parameter is empty.
//                             
//   *ErrorMessage - String, FormattedString - An error message to be displayed to the user.
//   *URLPages - String - The URL of the send page.
//
Function PrepareMessage(
		MessageData,
		Attachments = Undefined,
		EventLog = Undefined) Export
	
	Result = MessagesToTechSupportServiceClientServer.ResultOfSendParametersCheck(
		MessageData,
		Attachments,
		EventLog);
	
	If ValueIsFilled(Result.ErrorCode) Then
		Return Result;
	EndIf;
	
	If MessageData.Use_StandardTemplate Then
		MessageData.Message = MessageTextTemplate(MessageData.Message);
	EndIf;
	
	AttachmentsData = New Array;
	
	// Prepare the passed attachments.
	Result = PrepareAttachments(
		Attachments,
		AttachmentsData);
	
	If ValueIsFilled(Result.ErrorCode) Then
		Return Result;
	EndIf;
	
	// If required, attach the Event log.
	Result = PrepareEventLogText(
		EventLog,
		AttachmentsData);
	
	If ValueIsFilled(Result.ErrorCode) Then
		Return Result;
	EndIf;
	
	// Add technical information.
	PrepareTechnicalInfo(
		MessageData,
		AttachmentsData);
	
	// Send the data to the 1C:ITS Portal
	Result = DataTransferOperation(
		MessageData,
		AttachmentsData);
	
	ClearTechnicalInfo(MessageData);
	
	// Prepare a URL for navigating to the support request page.
	// 
	If IsBlankString(Result.ErrorCode) Then
		FillPageParameters(Result);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Internal

#Region SSLCore

// Integration with the StandardSubsystems.Core subsystem.
//
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	NewPermissions = New Array;
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Resolution = ModuleSafeModeManager.PermissionToUseInternetResource(
		"HTTPS",
		TechnicalSupportServicesHost(0),
		443,
		NStr("ru = 'Служба технической поддержки (ru)';
			|en = 'Technical support (RU)';"));
	NewPermissions.Add(Resolution);
	
	Resolution = ModuleSafeModeManager.PermissionToUseInternetResource(
		"HTTPS",
		TechnicalSupportServicesHost(1),
		443,
		NStr("ru = 'Служба технической поддержки (eu)';
			|en = 'Technical support (EU)';"));
	NewPermissions.Add(Resolution);
	
	PermissionsRequests.Add(ModuleSafeModeManager.RequestToUseExternalResources(NewPermissions));
	
EndProcedure

#EndRegion

#Region OnlineUserSupportSubsystemsIntegration

// Populates the details of the hosts used in Online Support services.
//
// Parameters:
//  OnlineSupportServicesHosts - Map - The name and host of a service.
//
Procedure OnFillOnlineSupportServicesHosts(OnlineSupportServicesHosts) Export
	
	OnlineSupportServicesHosts.Insert(
		TechnicalSupportServicesHost(0),
		NStr("ru = 'Служба технической поддержки';
			|en = 'Technical support';"));
	OnlineSupportServicesHosts.Insert(
		TechnicalSupportServicesHost(1),
		NStr("ru = 'Служба технической поддержки';
			|en = 'Technical support';"));
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region MessageGeneration

// Gets the filtered Event log entries, checks the send progress,
// and passes the result as text.
//
// Parameters:
//  FilterParameters - Structure - A structure with the following keys:
//   * StartDate    - Date - Event period start date.
//   * EndDate - Date - Event period end date.
//   * Event       - Array - An event array.
//   * Metadata    - Array, Undefined - A metadata array for filtering.
//   *Level       - EventLogLevel - A logging level.
//  AttachmentsData - Array of Structure - Prepared attachment data:
//   *Presentation - String - The attachment presentation.
//   *Text - String - The attachment text.
//   *Size - Number - Attachment size in bytes.
//
// Returns:
//  Structure - Preparation result:
//    *ErrorCode - String - A send error id.:
//    *ErrorMessage - String, FormattedString - An error message to be displayed to the user.
//
Function PrepareEventLogText(FilterParameters, AttachmentsData)
	
	Result = MessagesToTechSupportServiceClientServer.OperationNewResult();
	If FilterParameters = Undefined Then
		Return Result;
	EndIf;
	
	Filter = New Structure("StartDate, EndDate, Event, Metadata, Level");
	
	FillPropertyValues(
		Filter,
		FilterParameters,
		"StartDate, EndDate, Metadata");
	
	Filter.Event = FilterParameters.Events;
	
	If Not ValueIsFilled(Filter.StartDate) Then
		Filter.StartDate = CurrentSessionDate() - 60;
	EndIf;
	
	If Not ValueIsFilled(Filter.EndDate) Then
		Filter.EndDate = CurrentSessionDate();
	EndIf;
	
	If Not ValueIsFilled(FilterParameters.Level) Then
		Filter.Delete("Level");
	Else
		Filter.Level = EventLogLevel[FilterParameters.Level];
	EndIf;
	
	If (TypeOf(Filter.Metadata) <> Type("Array"))
		Or (TypeOf(Filter.Metadata) = Type("Array")
			And Filter.Metadata.Count() = 0) Then
		Filter.Delete("Metadata");
	EndIf;
	
	If (TypeOf(Filter.Event) <> Type("Array"))
		Or (TypeOf(Filter.Event) = Type("Array")
			And Filter.Event.Count() = 0) Then
		Filter.Delete("Event");
	EndIf;
	
	TempFileName = GetTempFileName("xml");
	
	Try
		
		SetPrivilegedMode(True);
		
		UnloadEventLog(
			TempFileName,
			Filter);
			
		SetPrivilegedMode(False);
		
		TempFile = New File(TempFileName);
		If Not TempFile.Exists() Then
			Result.ErrorCode = ErrorCodeFileSystemError();
			Result.ErrorMessage =
				NStr("ru = 'Файл выгрузки журнала регистрации не обнаружен. Обратитесь к администратору.';
					|en = 'The event log export file is not found. Contact the administrator.';");
			Return Result;
		EndIf;
		
		If TempFile.Size() > MaxFileSize() Then
			Result.ErrorCode = ErrorCodeEventLogMaxSizeExceeded();
			Result.ErrorMessage =
				NStr("ru = 'Превышен максимально допустимый размер файла журнала регистрации. Измените параметры выгрузки данных.';
					|en = 'The size limit of the event log file is exceeded. Change the data export parameters.';");
			Return Result;
		EndIf;
		
		TextReader = New TextReader(TempFileName);
		
		AttachmentParameters = New Structure;
		AttachmentParameters.Insert("Presentation", NStr("ru = 'Журнал регистрации.xml';
														|en = 'Event log.xml';"));
		AttachmentParameters.Insert("Text",         TextReader.Read());
		AttachmentParameters.Insert("Size",        TempFile.Size());
		AttachmentParameters.Insert("Extension",    ".xml");
		AttachmentsData.Add(AttachmentParameters);
		
		TextReader.Close();
		
	Except
		
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось выгрузить события журнала регистрации в файл по причине:
					|%1';
					|en = 'Cannot export event log records. Reason:
					|%1';"),
				ErrorProcessing.DetailErrorDescription(ErrorInfo())));
		
		Result.ErrorCode = ErrorCodeUnknownError();
		Result.ErrorMessage =
			NStr("ru = 'Не удалось выгрузить события журнала регистрации. Обратитесь к администратору.';
				|en = 'Cannot export event log records. Contact the administrator.';");
		
	EndTry;
	
	Try
		DeleteFiles(TempFileName);
	Except
		WriteInformationToEventLog(
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return Result;
	
EndFunction

// Gets a text for generating attachments from the passed data.
//
// Parameters:
//  Attachments - Array of Structure, Undefined - Attachment files. NOTE: Only text files (TXT) are supported.
//             Attachment structure fields are:
//   *Presentation - String - The attachment presentation. For example, "Attachment_1.txt".
//   *DataKind - String - Determines the passed data conversion.
//                         Valid values are:
//                           - ИмяФайла - String - The full name of an attached file.
//                           - Адрес - String - The address of the BinaryData-type value in the temporary storage.
//                           - Текст - String - The attachment text.
//   *Data - String - Data for attachment generation.
//  AttachmentsData - Array of Structure - Prepared attachment data:
//   *Presentation - String - The attachment presentation.
//   *Text - String - The attachment text.
//   *Size - Number - Attachment size in bytes.
//
// Returns:
//  Structure - Preparation result:
//    *ErrorCode - String - A send error id.:
//    *ErrorMessage - String, FormattedString - An error message to be displayed to the user.
//
Function PrepareAttachments(Attachments, AttachmentsData)
	
	Result = MessagesToTechSupportServiceClientServer.OperationNewResult();
	
	If Attachments = Undefined Then
		Return Result;
	EndIf;
		
	For Each Attachment In Attachments Do
		
		If Attachment.DataKind = "Address" Then
			
			FileData = GetFromTempStorage(Attachment.Data);
			If FileData.Size() > MaxFileSize() Then
				Result.ErrorCode = ErrorCodeAttachmentMaxSizeExceeded();
				Result.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Превышен максимально допустимый размер файла %1.';
						|en = 'The size limit of file %1 is exceeded.';"),
					Attachment.Presentation);
				Return Result;
			EndIf;
			
			AttachmentText = GetStringFromBinaryData(FileData);
			Size = FileData.Size();
			
		ElsIf Attachment.DataKind = "FileName" Then
			
			FileOnHardDrive = New File(Attachment.Data);
			If Not FileOnHardDrive.Exists() Then
				Result.ErrorCode = MessagesToTechSupportServiceClientServer.ErrorCodeInvalidRequestFormat();
				Result.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Файл %1 не найден .';
						|en = 'File %1 is not found.';"),
					Attachment.Presentation);
				Return Result;
			ElsIf FileOnHardDrive.Size() > MaxFileSize() Then
				Result.ErrorCode = ErrorCodeAttachmentMaxSizeExceeded();
				Result.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Превышен максимально допустимый размер файла %1.';
						|en = 'The size limit of file %1 is exceeded.';"),
					Attachment.Presentation);
				Return Result;
			EndIf;
			
			TextReader = New TextReader(Attachment.Data);
			AttachmentText = TextReader.Read();
			TextReader.Close();
			
			Size = FileOnHardDrive.Size();
			
		Else
			AttachmentText = Attachment.Data;
			Size = GetBinaryDataFromString(Attachment.Data, "UTF-8").Size();
		EndIf;
		
		AttachmentParameters = New Structure;
		AttachmentParameters.Insert("Presentation", Attachment.Presentation);
		AttachmentParameters.Insert("Text",         AttachmentText);
		AttachmentParameters.Insert("Size",        Size);
		AttachmentParameters.Insert(
			"Extension",
			CommonClientServer.GetFileNameExtension(Attachment.Presentation));
		AttachmentsData.Add(AttachmentParameters);
		
	EndDo;
	
	Return Result;
	
EndFunction

// Generates a support ticket text.
//
// Parameters:
//  Message - String - A user message
//
// Returns:
//  String - A message created from a template.
//
Function MessageTextTemplate(Message)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Здравствуйте!
			|
			|%1
			|
			|<Укажите ФИО>.';
			|en = 'Hello.
			|
			|%1
			|
			|<Your full name>.';"),
		Message);
	
EndFunction

// Generates a text describing the app technical parameters.
//
// Parameters:
//  TechnicalInfoData - Structure - Technical information data.
//    See MessagesToTechSupportServiceClientServer.TechnicalInfoDetails
//                                            .
// 
// Returns:
//  String - Data for generating the attachment "Technical information.txt".
//
Function AttachmentTextTechnicalInformation(TechnicalInfoData)
	
	TextTemplate1 = NStr("ru = 'Техническая информация о программе:
		|Идентификатор конфигурации:
		|%1';
		|en = 'Application details:
		|Configuration ID:
		|%1';");
	
	Result = StringFunctionsClientServer.SubstituteParametersToString(
		TextTemplate1,
		TechnicalInfoData.OnlineSupportSettings.ConfigurationID);
	
	Return Result;
	
EndFunction

// Populates technical information and attaches the file to the ticket.
//
// Parameters:
//  MessageData - Structure - Data for generating a message.
//                    See MessagesToTechSupportServiceClientServer.MessageData
//                                .
//  AttachmentsData - Array of Structure - Prepared attachment data:
//   *Presentation - String - The attachment presentation.
//   *Text - String - The attachment text.
//   *Size - Number - Attachment size in bytes.
//   *Extension - String - The file extension.
//
Procedure PrepareTechnicalInfo(MessageData, AttachmentsData)
	
	TechnicalInfoData = MessageData.TechnicalInfoData;
	
	// Any user can send a support ticket (not only administrators).
	SetPrivilegedMode(True);
	
	TechnicalInfoData.ApplicationDetails          = ApplicationDetails();
	TechnicalInfoData.OngoingSession              = CurrentSessionDetails();
	TechnicalInfoData.ExtensionData_           = ConfigurationExtensions.Get();
	TechnicalInfoData.SubsystemsData            = Common.SubsystemsDetails();
	TechnicalInfoData.OnlineSupportSettings = OnlineSupportSettings();
	TechnicalInfoData.InternetSettings          = InternetSettings();
	MessagesToTechSupportServiceClientServer.FillSystemInfo(
		TechnicalInfoData.ServerSystemInfo);
	FillPropertyValues(
		TechnicalInfoData.ClientSystemInfo,
		Common.ClientSystemInfo());
		
	// Add a technical details file.
	AttachmentParameters = New Structure;
	AttachmentParameters.Insert("Presentation", NStr("ru = 'Техническая информация.txt';
													|en = 'Technical information.txt';"));
	AttachmentParameters.Insert("Text",         AttachmentTextTechnicalInformation(TechnicalInfoData));
	AttachmentParameters.Insert("Size",        StrLen(AttachmentParameters.Text));
	AttachmentParameters.Insert(
		"Extension",
		CommonClientServer.GetFileNameExtension(AttachmentParameters.Presentation));
	AttachmentsData.Add(AttachmentParameters);
	
	
EndProcedure

// Determines the app details.
//
// Returns:
//  Structure - Add details.
//
Function ApplicationDetails()
	
	ApplicationName = String(OnlineUserSupport.InternalApplicationName());
	If ApplicationName = "Unknown" Then
		ApplicationName = NStr("ru = '<Не заполнено>';
							|en = '<Empty>';");
	EndIf;
	
	Result = New Structure;
	Result.Insert("ConfigurationDescription", Metadata.Synonym);
	Result.Insert("Version", OnlineUserSupport.ConfigurationVersion());
	Result.Insert("Vendor", Metadata.Vendor);
	Result.Insert("OnlineSupportID", ApplicationName);
	Result.Insert("ConfigurationName", OnlineUserSupport.ConfigurationName());
	
	Return Result;
	
EndFunction

// Determines the details of the current user session.
//
// Returns:
//  Structure - The session information.
//
Function CurrentSessionDetails()
	
	IsFileIB = Common.FileInfobase();
	
	Result = New Structure;
	Result.Insert("UserName", UserName());
	Result.Insert("ClientUsed", Common.ClientUsed());
	Result.Insert(
		"WorkMode",
		?(IsFileIB, "FILE", "SRVR"));
	Result.Insert(
		"ThereIsRightOfAdministration",
		Users.IsFullUser(, True, False));
	Result.Insert(
		"HasFullRights",
		Users.IsFullUser(, False, False));
	
	
	Return Result;
	
EndFunction

// Determines the details of Online Support settings.
//
// Returns:
//  Structure - Information on Online Support settings.
//
Function OnlineSupportSettings()
	
	AuthenticationData = OnlineUserSupport.OnlineSupportUserAuthenticationData();
	
	Result = New Structure(
		"Login, PasswordFilled",
		"",
		False);
	
	If AuthenticationData <> Undefined Then
		Result.Insert("Login", AuthenticationData.Login);
		Result.Insert(
			"PasswordFilled",
			Not IsBlankString(AuthenticationData.Password));
	EndIf;
	
	MonitoringCenterID1 = "";
	If Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
		ModuleMonitoringCenter = Common.CommonModule("MonitoringCenter");
		MonitoringCenterID1 = ModuleMonitoringCenter.InfoBaseID();
	EndIf;
	Result.Insert("MonitoringCenterID1", MonitoringCenterID1);
	
	LicensingClientName = "";
	ConfigurationID = "";
	If OnlineUserSupport.OperationWithLicensingClientSettingsAvailable() Then
		ConfigurationID = OnlineUserSupportInternalCached.ConfigurationID();
		If Not IsBlankString(ConfigurationID) Then
			LicensingClientName = LicensingClient.LicensingClientName();
		EndIf;
	EndIf;
	Result.Insert("LicensingClientName", LicensingClientName);
	Result.Insert("ConfigurationID", ConfigurationID);
	
	Return Result;
	
EndFunction

// Determines the details of internet connection settings.
//
// Returns:
//  Structure - Information on the applied internet connection settings.
//
Function InternetSettings()
	
	ConnectionSetup = OnlineUserSupport.ServersConnectionSettings();
	
	Result = New Structure;
	Result.Insert(
		"DomainZone",
		?(ConnectionSetup.OUSServersDomain = 1, "1c.eu", "1c.ru"));
	
	ProxySettings = GetFilesFromInternet.ProxySettingsAtServer();
	If ProxySettings = Undefined Then
		ProxySettingValue = "DONT_USE";
	Else
		If ProxySettings.Get("UseProxy") Then
			ProxySettingValue = ?(ProxySettings.Get("UseSystemSettings"),
				"AUTO",
				"USE");
		Else
			ProxySettingValue = "DONT_USE";
		EndIf;
	EndIf;
	Result.Insert("ProxySettings", ProxySettingValue);
	
	Return Result;
	
EndFunction

// Clears up the collected technical information.
//
// Parameters:
//  MessageData - Structure - Data for generating a message.
//                    See MessagesToTechSupportServiceClientServer.MessageData.
//
Procedure ClearTechnicalInfo(MessageData)
	
	MessageData.Insert(
		"TechnicalInfoData",
		MessagesToTechSupportServiceClientServer.TechnicalInfoDetails());
	
EndProcedure

#EndRegion

#Region ServiceOperationsCall

// Calls an operation for sending a support ticket.
// 
//
// Parameters:
//  MessageData - Structure - Data for generating a message.
//                    See MessagesToTechSupportServiceClientServer.MessageData
//                                .
//  AttachmentsData - Array of Structure - Prepared attachment data:
//   *Presentation - String - The attachment presentation.
//   *Text - String - The attachment text.
//
// Returns:
//  Structure - The result of the operation call:
//   *ErrorCode - String - An error ID.
//   *ErrorMessage - String - An error message to be displayed to the user.
//   *URL - String - A URL for navigating to 1C:ITS Portal.
//
Function DataTransferOperation(
		MessageData,
		AttachmentsData)
	
	// Read the server connection settings as the call can be made before the startup.
	// 
	ConnectionSetup = OnlineUserSupportInternalCached.OUSServersConnectionSettings();
	
	Result = New Structure;
	Result.Insert("ErrorCode"        , "");
	Result.Insert("ErrorMessage", "");
	Result.Insert("URL"              , "");
	
	JSONData = V2RequestJSONParameters(
		MessageData,
		AttachmentsData);
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/json");
	
	AdditionalRequestParameters = New Structure;
	AdditionalRequestParameters.Insert("Method"                   , "POST");
	AdditionalRequestParameters.Insert("AnswerFormat"            , 1);
	AdditionalRequestParameters.Insert("Headers"               , Headers);
	AdditionalRequestParameters.Insert("DataForProcessing"      , JSONData);
	AdditionalRequestParameters.Insert("DataFormatToProcess", 1);
	AdditionalRequestParameters.Insert("Timeout"                 , 300);
	
	SendDataOperationURL = SendDataOperationURL(ConnectionSetup.OUSServersDomain);
	SendingResult = OnlineUserSupport.DownloadContentFromInternet(
		SendDataOperationURL,
		,
		,
		AdditionalRequestParameters);
	
	If Not IsBlankString(SendingResult.ErrorCode) Then
		
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось отправить данные сообщения в службу технической поддержки.
					|%1';
					|en = 'Cannot send message data to technical support.
					|%1';"),
				SendingResult.ErrorInfo));
		
		If SendingResult.StatusCode = 400 Then
			Result.ErrorCode = MessagesToTechSupportServiceClientServer.ErrorCodeInvalidRequestFormat();
			Result.ErrorMessage =
				NStr("ru = 'Неверный набор параметров или формат запроса. Обратитесь к администратору.';
					|en = 'Invalid set of parameters or request format. Contact the administrator.';");
		ElsIf SendingResult.StatusCode = 429 Then
			Result.ErrorCode = ErrorCodeRequestResendLimitReached();
			Result.ErrorMessage =
				NStr("ru = 'Превышено количество попыток ввода отправки обращений. Повторите попытку позже.';
					|en = 'Exceeded maximum number of attempts to send a message. Try again later.';");
		ElsIf SendingResult.StatusCode = 500
			Or SendingResult.StatusCode = 503 Then
			Result.ErrorCode = ErrorCodeUnknownServiceError();
			Result.ErrorMessage =
				NStr("ru = 'Не удалось подключиться к сервису. Сервис временно недоступен. Повторите попытку подключения позже.';
					|en = 'Cannot connect to the service. The service is temporarily unavailable. Try again later.';");
		Else
			Result.ErrorCode = ErrorCodeUnknownError();
			Result.ErrorMessage =
				NStr("ru = 'Неизвестная ошибка при подключении к сервису.';
					|en = 'An unknown error occurred while connecting to the service.';");
		EndIf;
		
		Return Result;
		
	EndIf;
	
	Try
		CallResult = ResultV2RequestFromJSON(SendingResult.Content);
	Except
		
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось отправить данные сообщения в службу технической поддержки.
					|Ошибка при обработке ответа сервиса.
					|Некорректный ответ сервиса отправки сообщений.
					|%1
					|Тело ответа: %2';
					|en = 'Cannot send message data to technical support.
					|An error occurred while processing the service response.
					|The messaging service returned an invalid response.
					|%1
					|Response body: %2';"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()),
			SendingResult.Content));
		
		Result.ErrorCode = ErrorCodeUnknownError();
		Result.ErrorMessage =
			NStr("ru = 'Не удалось отправить данные сообщения в службу технической поддержки.';
				|en = 'Cannot send message data to technical support.';");
		
		Return Result;
		
	EndTry;
	
	If TypeOf(CallResult) <> Type("Structure")
		Or Not CallResult.Property("URL") Then // ACC:1416 - Data from external sources.
		
		WriteInformationToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось отправить данные сообщения в службу технической поддержки.
				|Ошибка при передаче сообщения в службу технической поддержки.
				|Сервис сообщил об ошибке.
				|Ответ сервиса: %1';
				|en = 'Cannot send message data to technical support.
				|An error occurred while sending the message.
				|The service reported an error.
				|Service response: %1%1';"),
			SendingResult.Content));
		
		Result.ErrorCode = ErrorCodeUnknownError();
		Result.ErrorMessage =
			NStr("ru = 'Не удалось отправить данные сообщения в службу технической поддержки.
				|Ошибка при передаче сообщения в службу технической поддержки.';
				|en = 'Cannot send message data to technical support.
				|An error occurred while sending the message.';");
		
		Return Result;
		
	EndIf;
	
	// Send attachments
	For Each ExportFile In CallResult.files Do
		
		FileDispatchURL = ExportFile.uploadURL;
		AttachmentData = AttachmentsData[ExportFile.number];
		JSONData = JSONFilesTransferParameters(
			AttachmentData);
		
		Headers = New Map;
		Headers.Insert("Content-Type", "application/json");
		
		AdditionalRequestParameters = New Structure;
		AdditionalRequestParameters.Insert("Method"                   , "POST");
		AdditionalRequestParameters.Insert("AnswerFormat"            , 1);
		AdditionalRequestParameters.Insert("Headers"               , Headers);
		AdditionalRequestParameters.Insert("DataForProcessing"      , JSONData);
		AdditionalRequestParameters.Insert("DataFormatToProcess", 1);
		AdditionalRequestParameters.Insert("Timeout"                 , 300);
		
		SendingResult = OnlineUserSupport.DownloadContentFromInternet(
			FileDispatchURL,
			,
			,
			AdditionalRequestParameters);
		
		If Not IsBlankString(SendingResult.ErrorCode) Then
		
			WriteInformationToEventLog(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось отправить данные сообщения в службу технической поддержки.
						|%1';
						|en = 'Cannot send message data to technical support.
						|%1';"),
					SendingResult.ErrorInfo));
			
			If SendingResult.StatusCode = 400 Then
				Result.ErrorCode = MessagesToTechSupportServiceClientServer.ErrorCodeInvalidRequestFormat();
				Result.ErrorMessage =
					NStr("ru = 'Неверный набор параметров или формат запроса. Обратитесь к администратору.';
						|en = 'Invalid set of parameters or request format. Contact the administrator.';");
			ElsIf SendingResult.StatusCode = 413 Then
				Result.ErrorCode = ErrorCodeAttachmentMaxSizeExceeded();
				Result.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Превышен максимально допустимый размер файла %1.';
						|en = 'The size limit of file %1 is exceeded.';"),
					SendingResult.ErrorInfo);
			ElsIf SendingResult.StatusCode = 500
				Or SendingResult.StatusCode = 503 Then
				Result.ErrorCode = ErrorCodeUnknownServiceError();
				Result.ErrorMessage =
					NStr("ru = 'Не удалось подключиться к сервису. Сервис временно недоступен. Повторите попытку подключения позже.';
						|en = 'Cannot connect to the service. The service is temporarily unavailable. Try again later.';");
			Else
				Result.ErrorCode = ErrorCodeUnknownError();
				Result.ErrorMessage =
					NStr("ru = 'Неизвестная ошибка при подключении к сервису.';
						|en = 'An unknown error occurred while connecting to the service.';");
			EndIf;
			
			Return Result;
			
		EndIf;
		
	EndDo;
	
	Result.URL = CallResult.URL;
	
	Return Result;

EndFunction

// Generates an URL for navigating to the support request page.
//
// Parameters:
//  MessageParameters - Structure - Message data
//   *ErrorCode - String - The error id.
//   Message data
//   *ErrorCode - String - The error id.
//
Procedure FillPageParameters(MessageParameters)
	
	// Read the server connection settings as the call can be made before the startup.
	// 
	ConnectionSetup = OnlineUserSupportInternalCached.OUSServersConnectionSettings();
	
	MessageParameters.Insert("URLPages", "");
	MessageParameters.URLPages = MessageParameters.URL;
	
	If Users.IsFullUser(, True, False) Then
		
		SetPrivilegedMode(True);
		TicketResult =
			OnlineUserSupport.AuthenticationTicketOnSupportPortal(MessageParameters.URLPages);
		SetPrivilegedMode(False);
		
		If ValueIsFilled(TicketResult.Ticket1) Then
			MessageParameters.URLPages = OnlineUserSupportClientServer.LoginServicePageURL(
				"/ticket/auth?token=" + TicketResult.Ticket1,
				ConnectionSetup);
		EndIf;
	EndIf;
	
EndProcedure

// Determines the host for sending a support ticket.
// 
//
// Parameters:
//  Domain - Number  - A domain id.
//
// Returns:
//  String - A connection host.
//
Function TechnicalSupportServicesHost(Domain)
	
	
	If Domain = 0 Then
		Host = "its.1c.ru";
	Else
		Host = "its.1c.eu";
	EndIf;
	
	MessagesToTechSupportServiceOverridable.OnDefineTechnicalSupportServicesHost(
		Host);
	
	Return Host;
	
EndFunction

// Determines a URL for sending a support ticket.
// 
//
// Parameters:
//  Domain - Number  - A domain ID.
//
// Returns:
//  String - An operation URL.
//
Function SendDataOperationURL(Domain)
	
	
	Return "https://"
		+ TechnicalSupportServicesHost(Domain)
		+ "/sd/v2/request";
	
EndFunction

// Generates request parameters for the
// /v2/request operation.
//
Function V2RequestJSONParameters(
		MessageData,
		AttachmentsData)
	
	QueryData = New Structure;
	
	// Support ticket data
	TicketData = New Structure;
	TicketData.Insert("theme", MessageData.Subject);
	TicketData.Insert("text", MessageData.Message);
	TicketData.Insert("techSupportNick", MessageData.Recipient);
	QueryData.Insert("requestInfo", TicketData);
	
	// Canned response settings
	CannedResponseSearchSettings = New Structure;
	CannedResponseSearchSettings.Insert("text", MessageData.CannedResponseSearchSettings.Text);
	CannedResponseSearchSettings.Insert("programNick", MessageData.CannedResponseSearchSettings.TheProgramID);
	QueryData.Insert("searchParams", CannedResponseSearchSettings);
	
	// Technical details
	TechnicalInformation = New Structure;
	TechnicalInfoData = MessageData.TechnicalInfoData;
	
	// 1. App details
	ApplicationDetails = New Structure;
	ApplicationDetails.Insert("description", TechnicalInfoData.ApplicationDetails.ConfigurationDescription);
	ApplicationDetails.Insert("version", TechnicalInfoData.ApplicationDetails.Version);
	ApplicationDetails.Insert("vendor", TechnicalInfoData.ApplicationDetails.Vendor);
	ApplicationDetails.Insert("name", TechnicalInfoData.ApplicationDetails.ConfigurationName);
	ApplicationDetails.Insert(
		"InternetSupportID",
		TechnicalInfoData.ApplicationDetails.OnlineSupportID);
	TechnicalInformation.Insert("programInfo", ApplicationDetails);
	
	// 2. Client system information
	ClientSystemInfo = New Structure;
	ClientSystemInfo.Insert(
		"platformType",
		TechnicalInfoData.ClientSystemInfo.PlatformType);
	ClientSystemInfo.Insert(
		"platformVersion",
		TechnicalInfoData.ClientSystemInfo.AppVersion);
	ClientSystemInfo.Insert("osVersion", TechnicalInfoData.ClientSystemInfo.OSVersion);
	TechnicalInformation.Insert("clientInfo", ClientSystemInfo);
	
	// 3. Server system information
	ServerSystemInfo = New Structure;
	ServerSystemInfo.Insert(
		"platformType",
		TechnicalInfoData.ServerSystemInfo.PlatformType);
	ServerSystemInfo.Insert(
		"platformVersion",
		TechnicalInfoData.ServerSystemInfo.AppVersion);
	ServerSystemInfo.Insert("osVersion", TechnicalInfoData.ServerSystemInfo.OSVersion);
	TechnicalInformation.Insert("serverInfo", ServerSystemInfo);
	
	// 4. User session data
	SessData = New Structure;
	SessData.Insert("userName", TechnicalInfoData.OngoingSession.UserName);
	SessData.Insert("clientApplicationType", TechnicalInfoData.OngoingSession.ClientUsed);
	SessData.Insert("mode", TechnicalInfoData.OngoingSession.WorkMode);
	SessData.Insert("isFullAccess", TechnicalInfoData.OngoingSession.HasFullRights);
	SessData.Insert("isAdministrator", TechnicalInfoData.OngoingSession.ThereIsRightOfAdministration);
	TechnicalInformation.Insert("sessionInfo", SessData);
	
	// 5. Patches and extensions data
	ExtensionsDetails = New Array;
	ExtensionData_ = TechnicalInfoData.ExtensionData_;
	ConfigurationExtensionPurposes = Metadata.ObjectProperties.ConfigurationExtensionPurpose;
	For Each ExtensionData In ExtensionData_ Do
		
		ExtensionDetails = New Structure;
		ExtensionDetails.Insert("name", ExtensionData.Name);
		ExtensionDetails.Insert("uuid", String(ExtensionData.UUID));
		ExtensionDetails.Insert("active", ExtensionData.Active);
		ExtensionDetails.Insert("safeMode", ExtensionData.SafeMode);
		ExtensionDetails.Insert(
			"usedInDistributedInfoBase",
			ExtensionData.UsedInDistributedInfoBase);
		ExtensionDetails.Insert(
			"unsafeActionProtection",
			ExtensionData.UnsafeActionProtection.UnsafeOperationWarnings);
		Purpose = ExtensionData.Purpose;
		If Purpose = ConfigurationExtensionPurposes.Customization Then
			ValuePurpose = "Customization";
		ElsIf Purpose = ConfigurationExtensionPurposes.AddOn Then
			ValuePurpose = "AddOn";
		ElsIf Purpose = ConfigurationExtensionPurposes.Patch Then
			ValuePurpose = "Patch";
		Else
			Raise NStr("ru = 'Неизвестный вариант назначения расширения';
									|en = 'Unknown extension purpose';");
		EndIf;
		ExtensionDetails.Insert("purpose", ValuePurpose);
		IsFixPatch = ExtensionData.Purpose = ConfigurationExtensionPurposes.Patch
			And StrStartsWith(ExtensionData.Name, "EF");
		ExtensionDetails.Insert("isPatch", IsFixPatch);
		ExtensionsDetails.Add(ExtensionDetails);
		
	EndDo;
	
	TechnicalInformation.Insert("extensionsInfo", ExtensionsDetails);
	
	// 6. Subsystem details
	SubsystemsDetails1 = New Array;
	SubsystemsData = TechnicalInfoData.SubsystemsData;
	For Each SubsystemData In SubsystemsData Do
		
		SubsystemDetails = New Structure;
		SubsystemDetails.Insert("name", SubsystemData.Name);
		SubsystemDetails.Insert("version", SubsystemData.Version);
		SubsystemDetails.Insert("InternetSupportID", SubsystemData.OnlineSupportID);
		SubsystemDetails.Insert("isConfigration", SubsystemData.IsConfiguration);
		SubsystemsDetails1.Add(SubsystemDetails);
		
	EndDo;
	
	TechnicalInformation.Insert("subsystemsInfo", SubsystemsDetails1);
	
	// 7. Online Support settings
	OnlineSupportSettings = TechnicalInfoData.OnlineSupportSettings;
	OnlineSupportDetails = New Structure;
	OnlineSupportDetails.Insert("login", OnlineSupportSettings.Login);
	OnlineSupportDetails.Insert("passwordIsFilled", OnlineSupportSettings.PasswordFilled);
	OnlineSupportDetails.Insert("monitoringCenterID", OnlineSupportSettings.MonitoringCenterID1);
	OnlineSupportDetails.Insert("licensingClientName", OnlineSupportSettings.LicensingClientName);
	If ValueIsFilled(MessageData.TIN) Then
		OnlineSupportDetails.Insert("inn", MessageData.TIN);
	EndIf;
	If ValueIsFilled(MessageData.RegistrationNumber) Then
		OnlineSupportDetails.Insert("registrationNumber", MessageData.RegistrationNumber);
	EndIf;
	TechnicalInformation.Insert("supportInfo", OnlineSupportDetails);
	
	// 8. Online connection settings
	InternetSettings = TechnicalInfoData.InternetSettings;
	InternetConnectionDetails = New Structure;
	InternetConnectionDetails.Insert("domainZone", InternetSettings.DomainZone);
	InternetConnectionDetails.Insert("proxy", InternetSettings.ProxySettings);
	TechnicalInformation.Insert("InternetSettings", InternetConnectionDetails);
	
	QueryData.Insert("technicalInfo", TechnicalInformation);
	
	// Attachment details
	FilesDetails = New Array;
	
	For Counter = 0 To AttachmentsData.UBound() Do
		
		AttachmentData = AttachmentsData[Counter];
		
		FileDetails = New Structure;
		FileDetails.Insert("number", Counter);
		FileDetails.Insert("name", AttachmentData.Presentation);
		FileDetails.Insert("size", AttachmentData.Size);
		FileDetails.Insert("extension", AttachmentData.Extension);
		FilesDetails.Add(FileDetails);
		
	EndDo;
	QueryData.Insert("files", FilesDetails);
	
	Return DataIntoJSON(QueryData);

EndFunction

// Read the respond of /v2/request.
//
Function ResultV2RequestFromJSON(JSONBody)
	
	ReadResponse = New JSONReader;
	ReadResponse.SetString(JSONBody);
	Result = ReadJSON(ReadResponse);
	ReadResponse.Close();
	
	Return Result;

EndFunction

// Generates request parameters for sending files.
//
Function JSONFilesTransferParameters(AttachmentData)
	
	QueryData = New Structure;
	QueryData.Insert("name", AttachmentData.Presentation);
	QueryData.Insert("value", AttachmentData.Text);
	
	Return DataIntoJSON(QueryData);
	
EndFunction

// Returns a data presentation as a JSON string.
//
// Parameters:
//  Data - Structure - JSON data to be serialized.
// 
// Returns:
//  String - Serialized data.
//
Function DataIntoJSON(Data)
	
	MessageDataWriter = New JSONWriter;
	MessageDataWriter.SetString();
	WriteJSON(MessageDataWriter, Data);
	
	Return MessageDataWriter.Close();
	
EndFunction

#EndRegion

#Region OtherServiceProceduresFunctions

// Determines the maximum attachment size.
//
// Returns:
//  Number - The maximum file size in bytes.
//
Function MaxFileSize()
	
	Return 10485760; // 10 MB.
	
EndFunction

// Returns the "UnknownError" error code.
//
// Returns:
//  String - The error code.
//
Function ErrorCodeUnknownError()
	
	Return "UnknownError";
	
EndFunction

// Returns the "AttachmentMaxSizeExceeded" error code.
//
// Returns:
//  String - The error code.
//
Function ErrorCodeAttachmentMaxSizeExceeded()
	
	Return "AttachmentMaxSizeExceeded";
	
EndFunction

// Returns the "EventLogMaxSizeExceeded" error code.
//
// Returns:
//  String - The error code.
//
Function ErrorCodeEventLogMaxSizeExceeded()
	
	Return "EventLogMaxSizeExceeded";
	
EndFunction

// Returns the "RequestResendLimitReached" error code.
//
// Returns:
//  String - The error code.
//
Function ErrorCodeRequestResendLimitReached()
	
	Return "RequestResendLimitReached";
	
EndFunction

// Returns the " UnknownServiceError" error code.
//
// Returns:
//  String - The error code.
//
Function ErrorCodeUnknownServiceError()
	
	Return "UnknownServiceError";
	
EndFunction

// Returns the "FileSystemError" error code.
//
// Returns:
//  String - The error code.
//
Function ErrorCodeFileSystemError()
	
	Return "FileSystemError";
	
EndFunction

// Adds an entry to the Event log.
//
// Parameters:
//  ErrorMessage - String - A comment to the Event log entry.
//  Error - Boolean - If True, the entry level is set to "Error".
//  MetadataObject - MetadataObject - The metadata object for which an error is registered.
//
Procedure WriteInformationToEventLog(
		ErrorMessage,
		Error = True,
		MetadataObject = Undefined) Export
	
	ELLevel = ?(Error, EventLogLevel.Error, EventLogLevel.Information);
	
	WriteLogEvent(
		EventLogEventName(),
		ELLevel,
		MetadataObject,
		,
		Left(ErrorMessage, 5120));
	
EndProcedure

// Returns an event name for the Event log
//
// Returns:
//  String - The event name.
//
Function EventLogEventName()
	
	Return NStr("ru = 'Сообщения в службу технической поддержки';
				|en = 'Messages to technical support';",
		Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#EndRegion
