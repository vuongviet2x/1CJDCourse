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

// See ServerNotifications.SessionUndeliveredServerNotifications
Function SessionUndeliveredServerNotifications(Val Parameters) Export
	
	Return ServerNotifications.SessionUndeliveredServerNotifications(Parameters);
	
EndFunction

// Parameters:
//  LongDesc - Structure:
//   * Date - Date
//   * Id - String
//   * Conversation - String
//   * Text - String
//   * DetailErrorDescription - String
//
Procedure LogErrorGettingDataFromMessage(Val LongDesc) Export
	
	If StrLineCount(LongDesc.Text) = 3 Then
		NameOfAlert = TrimAll(StrGetLine(LongDesc.Text, 1));
		NotificationID = Lower(TrimAll(StrGetLine(LongDesc.Text, 2)));
		LongRunningOperationProcedureName = TrimAll(StrGetLine(LongDesc.Text, 3));
		If StringFunctionsClientServer.IsUUID(NotificationID) Then
			Query = New Query;
			Query.SetParameter("NotificationID", NotificationID);
			Query.Text =
			"SELECT
			|	SentServerNotifications.NotificationContent AS NotificationContent
			|FROM
			|	InformationRegister.SentServerNotifications AS SentServerNotifications
			|WHERE
			|	SentServerNotifications.NotificationID <> &NotificationID";
			SetPrivilegedMode(True);
			Selection = Query.Execute().Select();
			SetPrivilegedMode(False);
			If Selection.Next() Then
				NotificationContent = Selection.NotificationContent;
				If TypeOf(NotificationContent) = Type("ValueStorage") Then
					XMLNotificationContent = XMLString(NotificationContent);
				EndIf;
			Else
				XMLNotificationContent = "<" + NStr("ru = 'Содержимое оповещения не найдено в базе данных';
													|en = 'The notification content is not found in the database';") + ">"; 
			EndIf;
		Else
			XMLNotificationContent = "<" + NStr("ru = 'Идентификатор оповещения не является уникальным идентификатором';
												|en = 'The notification ID is not a UUID';") + ">"; 
		EndIf;
	EndIf;
	If Not ValueIsFilled(NameOfAlert) Then
		NameOfAlert = "<" + NStr("ru = 'Нет данных';
									|en = 'No data';") + ">";
	EndIf;
	If Not ValueIsFilled(NotificationID) Then
		NotificationID = "<" + NStr("ru = 'Нет данных';
											|en = 'No data';") + ">";
	EndIf;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'При обращении к свойству ""%1"" сообщения системы взаимодействия со свойствами:
		           |- Дата: %2
		           |- Идентификатор: %3
		           |- Обсуждение: %4
		           |- Текст
		           |	Имя оповещения: %5
		           |	Идентификатор оповещения: %6';
					|en = 'When accessing the ""%1"" property of the collaboration system message with properties:
					|- Date: %2
					|- ID: %3
					|- Conversation: %4
					|- Text
					|	Notification name: %5
					|	Notification ID: %6';"),
		"Data",
		LongDesc.Date,
		LongDesc.Id,
		LongDesc.Conversation,
		NameOfAlert,
		NotificationID);
	
	If ValueIsFilled(LongRunningOperationProcedureName)
	   And LongRunningOperationProcedureName <> "-" Then
		
		ErrorText = ErrorText + "
		|	" + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Имя процедуры длительной операции: %1';
				|en = 'Long-running operation procedure name: %1';"),
			LongRunningOperationProcedureName);
	EndIf;
	
	ErrorText = ErrorText + Chars.LF;
	ErrorText = ErrorText + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Возникла ошибка:
		           |
		           |%1';
					|en = 'An error occurred:
					|
					|%1';"),
		LongDesc.DetailErrorDescription);
	
	If ValueIsFilled(XMLNotificationContent)
	   And NotificationID <> "-" Then
		
		ErrorText = ErrorText + Chars.LF + Chars.LF;
		ErrorText = ErrorText + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Содержимое оповещения в формате хранилища значения в XML (из базы данных):
			           |%1';
						|en = 'Notification content in a value storage format in XML (from the database):
						|%1';"),
			XMLNotificationContent);
	EndIf;
	
	WriteLogEvent(
		NStr("ru = 'Серверные оповещения.Ошибка получения данных оповещения из сообщения';
			|en = 'Server notifications.An error occurred when receiving the notification data from the message';",
			Common.DefaultLanguageCode()),
		EventLogLevel.Error,, NameOfAlert, ErrorText);
	
EndProcedure

// Parameters:
//  Comment - String - Comment for the Event log
//
Procedure WritePerformanceIndicators(Val Comment) Export
	
	WriteLogEvent(
		NStr("ru = 'Серверные оповещения.Показатели производительности';
			|en = 'Server notifications.Performance indicators';",
			Common.DefaultLanguageCode()),
		EventLogLevel.Information,,, Comment);
	
EndProcedure

#EndRegion
