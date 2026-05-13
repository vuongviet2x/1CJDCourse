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
//  
//
////////////////////////////////////////////////////////////////////////////////

#Region Private

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
//                          - <Пустая строка> - Sent successfully
//                          - "НеверныйФорматЗапроса" - Invalid support ticket parameters.
//                             
//                          - "ПревышенМаксимальныйРазмер" - The maximum attachment size is exceeded.
//                          - "НеизвестнаяОшибка" - Error sending the ticket.
//   *ErrorMessage - String, FormattedString - An error message to be displayed to the user.
//   *URLPages - String - The URL of the send page.
//
Function PrepareMessage(
		Val MessageData,
		Val Attachments = Undefined,
		Val EventLog = Undefined) Export
	
	Return MessagesToTechSupportService.PrepareMessage(
		MessageData,
		Attachments,
		EventLog);
	
EndFunction

#EndRegion
