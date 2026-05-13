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
// CommonModule.ContactTechnicalSupportClient.
//
// Client procedures and functions for contacting support: 
// - Send messages to 1C:ITS
//  - Prepare message attachments
//  - Navigate to the request page
//  
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Opens the 1C:ITS Portal page for submitting a support ticket.
// The parameters include autofill data, attachments, and
// Event log import parameters.
//
// Parameters:
//  MessageData - Structure - Data for generating a message.
//                    See MessagesToTechSupportServiceClientServer.MessageData
//                                .
//  Attachments - Array of Structure, Undefined - Attachment files. NOTE: Only text files (TXT, JSON, XML) are supported.
//             Attachment structure fields are:
//    *Presentation - String - The attachment presentation. For example, "Attachment_1.txt".
//    *DataKind - String - Determines the passed data conversion.
//                Valid values are:
//                  - ИмяФайла - String - The full name of an attached file.
//                  - Адрес - String - The address of the BinaryData-type value in the temporary storage.
//                  - Текст - String - The attachment text.
//    *Data - String - Data for attachment generation.
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
//  CallbackOnCompletion - NotifyDescription, Undefined - The method where the ticket send result
//                          should be passed. The method takes the following value
//                          Structure - Send result:
//                            *ErrorCode - String - A send error id.:
//                                                   - <Пустая строка> - Sent successfully
//                                                   - "НеверныйФорматЗапроса" - Invalid support ticket parameters.
//                                                      
//                                                   - "НеизвестнаяОшибка" - Error sending the ticket.
//                                                   - "НеизвестнаяОшибкаСервиса" - Service issues when sending the ticket.
//                                                      
//                                                   - "ОтсутствуетОбязательныйПараметрЗапроса" - The support ticket
//                                                      is missing a mandatory parameter.
//                                                   - "ОшибкаФайловойСистемы" - File system error.
//                                                   - "ПревышенМаксимальныйРазмерВложения" - The maximum attachment
//                                                      size is exceeded.
//                                                   - "ПревышенМаксимальныйРазмерЖурналаРегистрации" - The maximum Event log
//                                                      size is exceeded.
//                                                   - "ПустойПараметрЗапроса" - A mandatory parameter is empty.
//                                                      
//                            *ErrorMessage - String, FormattedString - An error message
//                                                 to be displayed to the user.
//
Procedure SendMessage(
		MessageData,
		Attachments = Undefined,
		EventLog = Undefined,
		CallbackOnCompletion = Undefined) Export
	
	Result = MessagesToTechSupportServiceClientServer.ResultOfSendParametersCheck(
		MessageData,
		Attachments,
		EventLog);
	
	If ValueIsFilled(Result.ErrorCode)
		And CallbackOnCompletion <> Undefined Then
		ExecuteNotifyProcessing(
			CallbackOnCompletion,
			Result);
		Return;
	EndIf;
	
	Status(
		,
		,
		NStr("ru = 'Подготовка сообщения в службу технической поддержки';
			|en = 'Preparing a message to technical support';"));
	
	PrepareTechnicalInfo(MessageData);
	
	MessageParameters = New Structure;
	MessageParameters.Insert("MessageData",       MessageData);
	MessageParameters.Insert("Attachments",              Attachments);
	MessageParameters.Insert("EventLog",     EventLog);
	MessageParameters.Insert("CallbackOnCompletion", CallbackOnCompletion);
	
	PrepareAttachmentsForSending(MessageParameters);
	
EndProcedure

#EndRegion

#Region Private

// Populates technical details on the server side.
//
// Parameters:
//  MessageData - Structure - Data for generating a message.
//                    See MessagesToTechSupportServiceClientServer.MessageData.
//
Procedure PrepareTechnicalInfo(MessageData)
	
	TechnicalInfoData = MessageData.TechnicalInfoData;
	MessagesToTechSupportServiceClientServer.FillSystemInfo(
		TechnicalInfoData.ClientSystemInfo);
	
EndProcedure

// Sends attachments to the server and calls the message preparation method.
//
// Parameters:
//  MessageParameters - Structure - Data for sending out the message.
//
Procedure PrepareAttachmentsForSending(MessageParameters)
	
	Files = New Array;
	If MessageParameters.Attachments <> Undefined Then
		For Each Attachment In MessageParameters.Attachments Do
			If Attachment.DataKind = "FileName" Then
				FileToPass = New TransferableFileDescription(Attachment.Data);
				Files.Add(FileToPass);
			EndIf;
		EndDo;
	EndIf;
	
	If Files.Count() = 0 Then
		PrepareAttachmentsForSendingCompletion(
			Undefined,
			MessageParameters);
	Else
		
		MessageParameters.Insert("Files", Files);
		
		ImportParameters = FileSystemClient.FileImportParameters();
		ImportParameters.Interactively = False;
		
		FileSystemClient.ImportFiles(
			New NotifyDescription(
				"PrepareAttachmentsForSendingCompletion",
				ThisObject,
				MessageParameters),
			ImportParameters,
			Files);
		
	EndIf;
	
EndProcedure

// Puts attachments to a temporary storage and calls the message preparation method.
//
// Parameters:
//  AttachmentsFiles - Array - Files transferred to the server.
//  MessageParameters - Structure - Data for sending out the message.
//
Procedure PrepareAttachmentsForSendingCompletion(
		AttachmentsFiles,
		MessageParameters) Export
	
	If AttachmentsFiles <> Undefined Then
		For Each Attachment In MessageParameters.Attachments Do
			If Attachment.DataKind = "FileName" Then
				For Each File In AttachmentsFiles Do
					If File.FullName = Attachment.Data Then
						// Replace data type with an address in the temporary storage.
						Attachment.DataKind = "Address";
						Attachment.Data = File.Location;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
	SendingResult = ContactTechnicalSupportServerCall.PrepareMessage(
		MessageParameters.MessageData,
		MessageParameters.Attachments,
		MessageParameters.EventLog);
	
	// Clear session data after sending out the message.
	If AttachmentsFiles <> Undefined Then
		Try
			For Each File In AttachmentsFiles Do
				DeleteFromTempStorage(File.Location);
			EndDo;
		Except
			EventLogClient.AddMessageForEventLog(
				EventLogEventName(),
				"Warning",
				DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	If Not ValueIsFilled(SendingResult.ErrorCode) Then
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("WindowTitle", NStr("ru = 'Отправка сообщения в службу технической поддержки';
														|en = 'Send message to technical support';"));
		
		OnlineUserSupportClient.OpenWebPageWithAdditionalParameters(
			SendingResult.URLPages,
			OpeningParameters);
		
		OnCompleteMessageHandling(
			MessageParameters,
			SendingResult);
		
	Else
		
		If MessageParameters.CallbackOnCompletion =  Undefined Then
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("MessageParameters", MessageParameters);
			AdditionalParameters.Insert("SendingResult",  SendingResult);
			
			ShowMessageBox(
				,
				SendingResult.ErrorMessage);
			
		Else
			
			OnCompleteMessageHandling(
				MessageParameters,
				SendingResult);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure OnCompleteMessageHandling(MessageParameters, SendingResult)
	
	If MessageParameters.CallbackOnCompletion <> Undefined Then
		
		Result = New Structure;
		Result.Insert("ErrorCode",         "");
		Result.Insert("ErrorMessage", "");
		
		FillPropertyValues(
			Result,
			SendingResult,
			"ErrorCode, ErrorMessage");
		
		ExecuteNotifyProcessing(
			MessageParameters.CallbackOnCompletion,
			Result);
		
	EndIf;
	
EndProcedure

// Returns an event name for the Event log
//
// Returns:
//  String - The event name.
//
Function EventLogEventName()
	
	Return NStr("ru = 'Сообщения в службу технической поддержки';
				|en = 'Messages to technical support';",
		CommonClient.DefaultLanguageCode());
	
EndFunction

#EndRegion
