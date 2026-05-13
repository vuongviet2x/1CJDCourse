///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "SaaS.OSL core" subsystem.
// CommonModule.OnlineUserSupportSaaS.
//
// Online Support server procedures and functions:
//  - Get an authentication ticket in the SaaS mode
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns a user authentication ticket on the support portal
// in SaaS mode in a shared session.
// To check a returned ticket, call the "check" operation
// of the https://login.1c.ru or https://login.1c.eu service
//
// For details, See https://login.1c.ru/rest/public/swagger
// -ui.html.
//
// Parameters:
//  TicketOwner - String - an arbitrary name of a service, for which
//      user authentication is performed. The same name must be
//      used when calling the checkTicket() operation.
//      Parameter value is required;
//  DataArea - Number - a number of data area (a subscriber), for which
//      the ticket will be received.
//
// Returns:
//  Structure - The result of receiving a ticket. Structure fields:
//      * Ticket1 - String - Received authentication ticket. If when receiving a ticket,
//        an error occurred, the field value is a blank string.
//      * ErrorCode - String - String code of the occurred error that
//        can be processed by the calling functionality:
//              - <Пустая строка> - a ticket is successfully received.
//              - "ОшибкаПодключения" - an error occurred when connecting to the service.
//              - "ОшибкаСервиса" - an internal service error.
//              - "НеизвестнаяОшибка" - an unknown error occurred
//                 when getting the ticket (an error that cannot be processed),
//      * ErrorMessage - String - brief details of an error, which
//        can be displayed to user,
//      * ErrorInfo - String - details of an error, which
//        can be written to the event log.
//
Function AuthenticationTicketOnSupportPortalInSharedSession(TicketOwner, DataArea) Export
	
	If Common.SeparatedDataUsageAvailable() Then
		Raise NStr("ru = 'Получение тикета недоступно в разделенном сеансе.';
								|en = 'Ticket cannot be received in separated session.';");
	EndIf;
	
	Result = AuthenticationTicketOnSupportPortal(TicketOwner, DataArea);
	
	If Result.ErrorCode = "OperationNotSupported" Then
		// For the external functionality, the error is interpreted as
		// "service connection error."
		Result.ErrorCode = "AttachmentError";
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Internal

// Returns a user authentication ticket on the support portal
// in SaaS mode for a data area.
// To check a returned ticket, call the "check" operation
// of the https://login.1c.ru or https://login.1c.eu service
//
// For details, See https://login.1c.ru/rest/public/swagger
// -ui.html.
//
// Parameters:
//  TicketOwner - String - an arbitrary name of a service, for which
//      user authentication is performed. The same name must be
//      used when calling the checkTicket() operation.
//      Parameter value is required;
//  DataArea - Number - a number of data area (a subscriber), for which
//      the ticket will be received.
//
// Returns:
//  Structure - The result of receiving a ticket. Structure fields:
//      * Ticket1 - String - Received authentication ticket. If when receiving a ticket,
//        an error occurred, the field value is a blank string.
//      * ErrorCode - String - String code of the occurred error that
//        can be processed by the calling functionality:
//              - <Пустая строка> - a ticket is successfully received.
//              - "ОшибкаПодключения" - an error occurred when connecting to the service.
//              - "ОшибкаСервиса" - an internal service error.
//              - "ОперацияНеПоддерживается" - an operation in Service Manager
//                 is not found;
//              - "НеизвестнаяОшибка" - an unknown error occurred
//                 when getting the ticket (an error that cannot be processed),
//      * ErrorMessage - String - brief details of an error, which
//        can be displayed to user,
//      * ErrorInfo - String - details of an error, which
//        can be written to the event log.
//
Function AuthenticationTicketOnSupportPortal(TicketOwner, DataArea = Undefined) Export
	
	If Not Common.DataSeparationEnabled() Then
		Raise NStr("ru = 'Недоступно при работе в локальном режиме.';
								|en = 'Unavailable in local mode.';");
	EndIf;
	
	If Not ValueIsFilled(TicketOwner) Then
		Raise NStr("ru = 'Не заполнено значение параметра ""ВладелецТикета""';
								|en = 'The TicketOwner parameter is blank.';");
	EndIf;
	
	If Common.SeparatedDataUsageAvailable() Then
		SeparatorValue = SaaSOSL.SessionSeparatorValue();
	ElsIf DataArea = Undefined Then
		Raise NStr("ru = 'Не заполнено значение параметра ""ОбластьДанных""';
								|en = 'The DataArea parameter is blank.';");
	Else
		// Shared sessions use the passed value of the
		// "DataArea" parameter.
		SeparatorValue = DataArea;
	EndIf;
	
	Result = New Structure;
	Result.Insert("ErrorCode"         , "");
	Result.Insert("ErrorMessage" , "");
	Result.Insert("ErrorInfo", "");
	Result.Insert("Ticket1"             , "");
	Result.Insert("InternalParameters", "");
	
	If Not Common.SeparatedDataUsageAvailable() Then
		UserIdentificator = Undefined;
	Else
		CurrentUser = Users.AuthorizedUser();
		UserIdentificator =
			Common.ObjectAttributeValue(
				CurrentUser,
				"ServiceUserID");
	EndIf;
	
	BodyWriter = New JSONWriter;
	BodyWriter.SetString();
	BodyWriter.WriteStartObject();

	BodyWriter.WritePropertyName("zone");
	BodyWriter.WriteValue(SeparatorValue);
	
	AreaKey = DataAreaKey(SeparatorValue);
	If ValueIsFilled(AreaKey) Then
		BodyWriter.WritePropertyName("zoneKey");
		BodyWriter.WriteValue(AreaKey);
	EndIf;
	
	If ValueIsFilled(UserIdentificator) Then
		BodyWriter.WritePropertyName("userGUID");
		BodyWriter.WriteValue(String(UserIdentificator));
	EndIf;
	
	BodyWriter.WritePropertyName("openUrl");
	BodyWriter.WriteValue(String(TicketOwner));
	
	BodyWriter.WriteEndObject();
	RequestBody = BodyWriter.Close();
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/json");
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Method"                   , "POST");
	AdditionalParameters.Insert("Headers"               , Headers);
	AdditionalParameters.Insert("DataForProcessing"      , RequestBody);
	AdditionalParameters.Insert("DataFormatToProcess", 1);
	AdditionalParameters.Insert("AnswerFormat"            , 1);
	AdditionalParameters.Insert("Timeout"                 , 30);
	
	ConnectionSettings = ServiceManagerConnectionSettings();
	URLOfService = ConnectionSettings.URL + "/hs/tickets/";
	
	OperationResult = OnlineUserSupport.DownloadContentFromInternet(
		URLOfService,
		ConnectionSettings.InternalUsername,
		ConnectionSettings.InternalUserPassword,
		AdditionalParameters);
	If OperationResult.StatusCode = 404 Then
		
		// No service to receive tickets in the service manager.
		Result.ErrorCode = "OperationNotSupported";
		Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить тикет аутентификации.
				|Аутентификация не поддерживается Менеджером сервиса.
				|В Менеджере сервиса отсутствует сервис тикетов аутентификации.
				|Получен код состояния 404 при обращении к ресурсу %1.';
				|en = 'Cannot receive an authentication ticket.
				|Authentication is not supported in the service manager.
				|Authentication ticket service is missing in the manager service.
				|404 state code is received while accessing the %1 resource.';"),
			URLOfService);
		
		OnlineUserSupport.WriteInformationToEventLog(
			Result.ErrorInfo,
			Undefined,
			False);
		
		If Users.IsFullUser(, True, False) Then
			Result.ErrorMessage = NStr("ru = 'Аутентификация на Портале 1С:ИТС не поддерживается (404).';
												|en = 'Authentication on 1C:ITS Portal is not supported (404).';");
		Else
			Result.ErrorMessage = NStr("ru = 'Ошибка аутентификации.';
												|en = 'Authentication error.';");
		EndIf;
		
	ElsIf OperationResult.StatusCode = 201
		Or OperationResult.StatusCode = 400
		Or OperationResult.StatusCode = 403
		Or OperationResult.StatusCode = 500 Then
		
		// Response body being processed.
		Try
			
			JSONReader = New JSONReader;
			JSONReader.SetString(OperationResult.Content);
			ResponseObject = ReadJSON(JSONReader);
			JSONReader.Close();
			
			If OperationResult.StatusCode = 201 Then
				Result.Ticket1 = ResponseObject.ticket;
			Else
				
				If TypeOf(ResponseObject) = Type("Structure") And ResponseObject.Property("parameters") Then // ACC:1416 - An optional property of the service response.
					Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Не удалось получить тикет аутентификации в Менеджере сервиса (%1).
							|Код состояния: %2;
							|Сообщение: %3
							|Область данных: %4;
							|Владелец тикета: %5;
							|Код абонента: %6;
							|Идентификатор абонента: %7;
							|Логин пользователя: %8;
							|Идентификатор пользователя: %9.';
							|en = 'Cannot get an authentication ticket in the service manager (%1).
							|State code: %2;
							|Message: %3
							|Data area: %4;
							|Ticket owner: %5;
							|Subscriber code: %6;
							|User ID: %7;
							|Username: %8;
							|User ID: %9.';"),
						URLOfService,
						OperationResult.StatusCode,
						ResponseObject.text,
						SeparatorValue,
						String(TicketOwner),
						ResponseObject.parameters.subscriberCode,
						ResponseObject.parameters.subscriberGuid,
						ResponseObject.parameters.userName,
						String(UserIdentificator));
				Else
					Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Не удалось получить тикет аутентификации в Менеджере сервиса (%1).
							|Код состояния: %2;
							|Сообщение: %3
							|Область данных: %4;
							|Владелец тикета: %5;
							|Идентификатор пользователя: %6.';
							|en = 'Cannot get authentication ticket in the service manager (%1).
							|State code: %2;
							|Message: %3
							|Data area: %4;
							|Ticket owner: %5;
							|User ID: %6.';"),
						URLOfService,
						OperationResult.StatusCode,
						ResponseObject.text,
						SeparatorValue,
						String(TicketOwner),
						String(UserIdentificator));
				EndIf;
				
				OnlineUserSupport.WriteInformationToEventLog(
					Result.ErrorInfo);
				
				Result.ErrorCode = ?(
					OperationResult.StatusCode = 500,
					"ServiceError",
					"AttachmentError");
				
				If Users.IsFullUser(, True, False) Then
					Result.ErrorMessage =
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Ошибка аутентификации (%1).';
								|en = 'Authentication error (%1).';"),
							OperationResult.StatusCode);
				Else
					Result.ErrorMessage = NStr("ru = 'Ошибка аутентификации.';
														|en = 'Authentication error.';");
				EndIf;
				
			EndIf;
			
		Except
			
			ErrorInfo = ErrorInfo();
			
			Result.ErrorCode = "ServiceError";
			
			Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить тикет аутентификации в Менеджере сервиса (%1).
					|Некорректный ответ Менеджера сервиса.
					|Ошибка при обработке ответа Менеджера сервиса:
					|%2
					|Код состояния: %3;
					|Тело ответа: %4
					|Область данных: %5;
					|Владелец тикета: %6;
					|Идентификатор пользователя: %7.';
					|en = 'Cannot get authentication ticket in the service manager (%1).
					|Incorrect response of the service manager.
					|An error occurred while processing the service manager response:
					|%2
					|State code: %3;
					|Response body: %4
					|Data area: %5;
					|Ticket owner: %6;
					|User ID: %7.';"),
				URLOfService,
				ErrorProcessing.DetailErrorDescription(ErrorInfo),
				OperationResult.StatusCode,
				Left(OperationResult.Content, 5120),
				SeparatorValue,
				String(TicketOwner),
				String(UserIdentificator));
			OnlineUserSupport.WriteInformationToEventLog(
				Result.ErrorInfo);
			
			If Users.IsFullUser(, True, False) Then
				Result.ErrorMessage =
					NStr("ru = 'Ошибка аутентификации. Некорректный ответ сервиса.';
						|en = 'Authentication error. Incorrect service response.';");
			Else
				Result.ErrorMessage = NStr("ru = 'Ошибка аутентификации.';
													|en = 'Authentication error.';");
			EndIf;
			
		EndTry;
		
	ElsIf OperationResult.StatusCode = 0 Then
		
		// Connection error.
		Result.ErrorCode = "AttachmentError";
		Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить тикет аутентификации в Менеджере сервиса (%1).
				|Не удалось подключиться к Менеджеру сервиса.
				|%2';
				|en = 'Cannot get authentication ticket in the service manager (%1).
				|Cannot connect to the service manager.
				| %2';"),
			URLOfService,
			OperationResult.ErrorInfo);
		OnlineUserSupport.WriteInformationToEventLog(
			Result.ErrorInfo);
		
		If Users.IsFullUser(, True, False) Then
			Result.ErrorMessage =
				NStr("ru = 'Не удалось подключиться к сервису.';
					|en = 'Cannot connect to the service.';")
					+ Chars.LF + OperationResult.ErrorMessage;
		Else
			Result.ErrorMessage = NStr("ru = 'Ошибка аутентификации.';
												|en = 'Authentication error.';");
		EndIf;
		
	Else
		
		// Unknown service error.
		ErrorInfo = ErrorInfo();
		
		Result.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить тикет аутентификации в Менеджере сервиса (%1).
				|Некорректный ответ Менеджера сервиса.
				|Ошибка при обработке ответа Менеджера сервиса:
				|%2
				|Код состояния: %3;
				|Тело ответа: %4
				|Область данных: %5;
				|Владелец тикета: %6;
				|Идентификатор пользователя: %7.';
				|en = 'Cannot get authentication ticket in the service manager (%1).
				|Incorrect response of the service manager.
				|An error occurred while processing the service manager response:
				|%2
				|State code: %3;
				|Response body: %4
				|Data area: %5;
				|Ticket owner: %6;
				|User ID: %7.';"),
			URLOfService,
			ErrorProcessing.DetailErrorDescription(ErrorInfo),
			OperationResult.StatusCode,
			Left(OperationResult.Content, 5120),
			SeparatorValue,
			String(TicketOwner),
			String(UserIdentificator));
		OnlineUserSupport.WriteInformationToEventLog(
			Result.ErrorInfo);
		
		Result.ErrorCode = "UnknownError";
		If Users.IsFullUser(, True, False) Then
			Result.ErrorMessage =
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Неизвестная ошибка сервиса аутентификации (%1).';
						|en = 'An unknown authentication service error (%1).';"),
					OperationResult.StatusCode);
		Else
			Result.ErrorMessage = NStr("ru = 'Ошибка аутентификации.';
												|en = 'Authentication error.';");
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// Defines Service Manager connection settings.
//
// Returns:
//  Structure - Connection settings:
//   *URL - String - connection address;
//   *InternalUsername - String - Username.
//   *InternalUserPassword - String - User password.
//
Function ServiceManagerConnectionSettings()
	
	SetPrivilegedMode(True);
	Result = New Structure;
	Result.Insert("URL", SaaSOSL.InternalServiceManagerURL());
	Result.Insert("InternalUsername",
		SaaSOSL.ServiceManagerInternalUserName());
	Result.Insert("InternalUserPassword",
		SaaSOSL.ServiceManagerInternalUserPassword());
	
	Return Result;
	
EndFunction

// Defines a data area based on the passed separator.
//
// Parameters:
//  SeparatorValue - Number - Separator.
//
// Returns:
//  Number - an area key.
//
Function DataAreaKey(SeparatorValue)
	
	If Common.SeparatedDataUsageAvailable() Then
		
		// No caching in the separated mode
		// (no need to access the data area).
		SetPrivilegedMode(True);
		
		// Get the constant by name to bypass the syntax check
		// in configurations that don't support the SaaS mode.
		Return Constants["DataAreaKey"].Get();
		
	Else
		// The result is cached as you need to enter the data area.
		Return OnlineUserSupportSaaSCached.DataAreaKey(SeparatorValue);
	EndIf;
	
EndFunction

#EndRegion
