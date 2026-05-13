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
// CommonModule.ContactTechnicalSupportClientServer.
//
// Client/server procedures and functions for contacting support: 
// - Validate message parameters
//  - Subsystem's common procedures and functions
//  
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Data for sending out the message to the technical support.
// 
// Returns:
//  Structure - Data for generating a message:
//    *Subject - String - Message subject.
//    *Message  - String - Message body.
//    *Use_StandardTemplate - Boolean - Flag indicating whether the standard support message template should be used.
//    *Recipient - String - Placeholder name of the message recipient.
//    *TIN - String - Company TIN.
//    *RegistrationNumber - String - Registration number.
//    *CannedResponseSearchSettings - Structure - Settings for searching a canned response. See CannedResponseSearchSettings
//                                                 .
//    *TechnicalInfoData - Structure - Technical information data. See TechnicalInfoDetails.
//
Function MessageData() Export
	
	Result = New Structure;
	Result.Insert("Subject", "");
	Result.Insert("Message", "");
	Result.Insert("Use_StandardTemplate", True);
	Result.Insert("Recipient", "");
	Result.Insert("TIN", "");
	Result.Insert("RegistrationNumber", "");
	Result.Insert("CannedResponseSearchSettings", CannedResponseSearchSettings());
	Result.Insert("TechnicalInfoData", TechnicalInfoDetails());
	
	Return Result;
	
EndFunction

#EndRegion

#Region Internal

// Fills settings for searching a canned response based on the error text.
//
// Parameters:
//  MessageText - String - Error text.
//  SearchSettings1 - Structure - See CannedResponseSearchSettings
//
Procedure FillCannedResponseSearchSettings(
		MessageText,
		SearchSettings1) Export
	
	If ValueIsFilled(SearchSettings1.Text) Then
		Return;
	EndIf;
	
	If StrFind(MessageText, "Couldn't resolve host name") <> 0 Then
		SearchSettings1.Text = "Couldn't resolve host name";
	ElsIf StrFind(MessageText, "SSL-joins") <> 0 Then
		SearchSettings1.Text = "Error initializations SSL-joins";
	ElsIf StrFind(MessageText, "Deleted node") <> 0 Then
		SearchSettings1.Text = "Node not passed checking";
	ElsIf StrFind(MessageText, "Failure when receiving data from the peer") <> 0 Then
		SearchSettings1.Text = "Failure when receiving data from the peer";
	ElsIf StrFind(MessageText, "404 Not Found") <> 0 And StrFind(MessageText, ".eu") <> 0 Then
		SearchSettings1.Text = "not loading files";
	EndIf;
	
	If ValueIsFilled(SearchSettings1.Text) Then
		SearchSettings1.TheProgramID = "ISL";
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Creates a new result of sending a message
// to Online Support.
//
// Returns:
//
//  Structure - Send result:
//   *ErrorCode - String - The id of an error occurred during the send-out:
//   *ErrorMessage - String, FormattedString - Error message to be displayed to the user.
//
Function OperationNewResult() Export
	
	Result = New Structure;
	Result.Insert("ErrorCode",         "");
	Result.Insert("ErrorMessage", "");
	
	Return Result;
	
EndFunction

// Returns the "InvalidQueryFormat" error code.
//
// Returns:
//  String - Error code.
//
Function ErrorCodeInvalidRequestFormat() Export
	
	Return "InvalidQueryFormat";
	
EndFunction

// Returns the "MandatoryRequestParameterMissing" error code.
//
// Returns:
//  String - Error code.
//
Function ErrorCodeMandatoryRequestParameterMissing() Export
	
	Return "MandatoryRequestParameterMissing";
	
EndFunction

// Returns the "EmptyRequestParameter" error code.
//
// Returns:
//  String - Error code.
//
Function ErrorCodeEmptyRequestParameter() Export
	
	Return "EmptyRequestParameter";
	
EndFunction

// Verifies the parameters of an Online Support request.
// 
//
// Parameters:
//  MessageData - Structure - Data for generating a message.
//                    See MessageData
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
//
// Returns:
//  Structure - See OperationNewResult.
//
Function ResultOfSendParametersCheck(
		MessageData,
		Attachments,
		EventLog) Export
	
	Result = OperationNewResult();
	
	If Not ValueIsFilled(MessageData.Recipient) Then
		Result.ErrorCode         = ErrorCodeEmptyRequestParameter();
		Result.ErrorMessage = NStr("ru = 'Не заполнен получатель сообщения.';
											|en = 'Message recipient is required.';");
		Return Result;
	EndIf;
	
	If Not ValueIsFilled(MessageData.Subject) Then
		Result.ErrorCode         = ErrorCodeEmptyRequestParameter();
		Result.ErrorMessage = NStr("ru = 'Не заполнена тема сообщения.';
											|en = 'Message subject is required.';");
		Return Result;
	EndIf;
	
	If Not ValueIsFilled(MessageData.Message) Then
		Result.ErrorCode         = ErrorCodeEmptyRequestParameter();
		Result.ErrorMessage = NStr("ru = 'Не заполнен текст сообщения.';
											|en = 'Message text is required.';");
		Return Result;
	EndIf;
	
	If Not MessageData.Property("Use_StandardTemplate") Then
		Result.ErrorCode         = ErrorCodeMandatoryRequestParameterMissing();
		Result.ErrorMessage = NStr("ru = 'Не заполнено использование стандартного шаблона.';
											|en = 'Select whether to use the default template.';");
		Return Result;
	EndIf;
	
	If Not MessageData.Property("CannedResponseSearchSettings") Then
		Result.ErrorCode         = ErrorCodeMandatoryRequestParameterMissing();
		Result.ErrorMessage = NStr("ru = 'Не заполнены настройки поиска готового ответа.';
											|en = 'Canned response settings are required.';");
		Return Result;
	EndIf;
	
	If Not MessageData.Property("TechnicalInfoData") Then
		Result.ErrorCode         = ErrorCodeMandatoryRequestParameterMissing();
		Result.ErrorMessage = NStr("ru = 'Не заполнены данные технической информации.';
											|en = 'Technical information data is required.';");
		Return Result;
	EndIf;
	
	If Attachments <> Undefined Then
		
		For Each FileDetails In Attachments Do
			
			If Not ValueIsFilled(FileDetails.Presentation) Then
				Result.ErrorCode         = ErrorCodeMandatoryRequestParameterMissing();
				Result.ErrorMessage = NStr("ru = 'Не заполнено представление вложения.';
													|en = 'Attachment presentation is required.';");
				Return Result;
			EndIf;
			
			If Not ValueIsFilled(FileDetails.DataKind) Then
				Result.ErrorCode         = ErrorCodeMandatoryRequestParameterMissing();
				Result.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не заполнен вид данных вложения %1.';
						|en = 'Data type of attachment %1 is required.';"),
					FileDetails.Presentation);
				Return Result;
			EndIf;
			
			If Not ValueIsFilled(FileDetails.Data) Then
				Result.ErrorCode         = ErrorCodeMandatoryRequestParameterMissing();
				Result.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не заполнены данные вложения %1.';
						|en = 'Data of attachment %1 is required.';"),
					FileDetails.Presentation);
				Return Result;
			EndIf;
			
			If FileDetails.DataKind <> "Address"
				And FileDetails.DataKind <> "FileName"
				And FileDetails.DataKind <> "Text" Then
				Result.ErrorCode         = ErrorCodeInvalidRequestFormat();
				Result.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Передан неверный вид данных вложения %1.';
						|en = 'Incorrect data type of attachment %1.';"),
					FileDetails.DataKind);
				Return Result;
			EndIf;
			
			InvalidChars = CommonClientServer.FindProhibitedCharsInFileName(
				FileDetails.Presentation);
			If StrFind(FileDetails.Presentation, "@") <> 0 Then
				InvalidChars.Add("@");
			EndIf;
			
			If InvalidChars.Count() > 0 Then
				Result.ErrorCode         = ErrorCodeInvalidRequestFormat();
				Result.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В представлении обнаружены недопустимые символы: %1.';
						|en = 'The presentation contains invalid characters: %1.';"),
					StrConcat(InvalidChars, ","));
				Return Result;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If EventLog <> Undefined Then
		If EventLog.StartDate > EventLog.EndDate Then
			Result.ErrorCode         = ErrorCodeInvalidRequestFormat();
			Result.ErrorMessage =
				NStr("ru = 'Некорректный отбор данных журнала регистрации. Дата начала отбора меньше даты окончания.';
					|en = 'Incorrect event log filter settings. The start date is later than the end date.';");
			Return Result;
		EndIf;
		If ValueIsFilled(EventLog.Level)
			And EventLog.Level <> "Error"
			And EventLog.Level <> "Warning"
			And EventLog.Level <> "Information"
			And EventLog.Level <> "Note" Then
			Result.ErrorCode         = ErrorCodeInvalidRequestFormat();
			Result.ErrorMessage =
				NStr("ru = 'Недопустимый отбор данных журнала регистрации. Некорректный уровень событий журнала регистрации.';
					|en = 'Invalid event log filter settings. Incorrect event severity level.';");
			Return Result;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns settings for searching a canned response.
// 
// Returns:
//  Structure - Search settings:
//    *Text - String - Search text.
//    *TheProgramID - String - App ID.
//
Function CannedResponseSearchSettings()
	
	Result = New Structure;
	Result.Insert("Text", "");
	Result.Insert("TheProgramID", "");
	
	Return Result;
	
EndFunction

// Technical information details.
//
// Returns:
//  Structure:
//    *ApplicationDetails - Structure, Undefined - 
//    *OngoingSession - Structure, Undefined - 
//    *ExtensionData_ - Array of ConfigurationExtension, Undefined - An array of configuration add-ins.
//    *SubsystemsData - Array, Undefined - Details of all the libraries integrated in the configuration. See Common.SubsystemsDetails
//                                              .
//    *OnlineSupportSettings - Structure, Undefined - 
//    *InternetSettings - Structure, Undefined - MessagesToTechSupportService.InternetSettings
//    *ClientSystemInfo - Structure - See SystemInfoDetails
//                                              ;
//    *ClientSystemInfo - Structure - See SystemInfoDetails.
//
Function TechnicalInfoDetails() Export
	
	Result = New Structure(
		"ApplicationDetails,
		|OngoingSession,
		|ExtensionData_,
		|SubsystemsData,
		|OnlineSupportSettings,
		|InternetSettings");
	
	Result.Insert("ClientSystemInfo", SystemInfoDetails());
	Result.Insert("ServerSystemInfo", SystemInfoDetails());
	
	Return Result;
	
EndFunction

// System information details.
//
// Returns:
//  Structure:
//    *PlatformType - String, Undefined - The type of the user's platform.
//    *AppVersion - String, Undefined - 1C:Enterprise version.
//    *OSVersion - String, Undefined - Operating system version.
//
Function SystemInfoDetails()
	
	Result = New Structure(
		"PlatformType,
		|AppVersion,
		|OSVersion");
	
	Return Result;
	
EndFunction

// Fill system information.
//
// Parameters:
//  SystemInfoDetails - Structure - See SystemInfoDetails.
//
Procedure FillSystemInfo(SystemInfoDetails) Export
	
	FillPropertyValues(
		SystemInfoDetails,
		New SystemInfo);
	SystemInfoDetails.PlatformType =
		CommonClientServer.NameOfThePlatformType(SystemInfoDetails.PlatformType);
	
EndProcedure

#EndRegion
