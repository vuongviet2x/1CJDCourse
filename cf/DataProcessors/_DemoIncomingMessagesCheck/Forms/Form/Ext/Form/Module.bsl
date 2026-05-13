///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillAccountsChoiceList();
	BeginOfPeriod = CurrentSessionDate();
	EndOfPeriod = CurrentSessionDate();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTable

&AtClient
Procedure TableOnActivateRow(Item)
	EmailText = "";
	If Items.Table.CurrentData = Undefined Then
		Return;
	EndIf;
	EmailText = Items.Table.CurrentData.Text; 
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CheckIncomingExecute()
	
	If Not ValueIsFilled(AccountIncoming) Then
		CommonClient.MessageToUser(NStr("ru = 'Почта для получения входящих писем не указана.';
														|en = 'Specify the email account for incoming messages.';"));
		Return;
	EndIf;
	
	CheckIncomingExecuteCompletion();
	
EndProcedure

&AtClient
Procedure CheckIncomingExecuteCompletion()
	
	Status(NStr("ru = 'Загрузка входящих сообщений.';
					|en = 'Importing incoming messages.';"),,NStr("ru = 'Пожалуйста, подождите...';
																|en = 'Please wait…';"));
	Try
		ImportIncomingMessages();
		NewMessages = IncomingMessages1.Count();
		If NewMessages > 0 Then
			ShowMessageBox(, NStr("ru = 'Получено новых писем:';
											|en = 'You''ve got new mails:';") + " " + NewMessages);
		Else
			ShowMessageBox(, NStr("ru = 'Нет новых писем.';
											|en = 'No new mails.';"));
		EndIf;
	Except
		EmailOperationsClient.ReportConnectionError(AccountIncoming, 
			NStr("ru = 'Загрузка входящих сообщений';
				|en = 'Importing incoming messages';"), ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

&AtServer
Procedure ImportIncomingMessages()
	
	InternetMailMessageFields = EmailOperations.InternetMailMessageFields();
	
	ColumnsArray1 = New Array;
	ColumnsArray1.Add(InternetMailMessageFields.SenderName);
	ColumnsArray1.Add(InternetMailMessageFields.Attachments);
	ColumnsArray1.Add(InternetMailMessageFields.Subject);
	ColumnsArray1.Add(InternetMailMessageFields.PostingDate);
	ColumnsArray1.Add(InternetMailMessageFields.ReplyTo);
	ColumnsArray1.Add(InternetMailMessageFields.From);
	ColumnsArray1.Add(InternetMailMessageFields.Texts);
	
	ImportParameters = New Structure;
	ImportParameters.Insert("Columns", ColumnsArray1);

	Filter = New Structure;
	If ValueIsFilled(BeginOfPeriod) Then
		Filter.Insert("AfterDateOfPosting", BeginOfPeriod);
	EndIf;
	
	If ValueIsFilled(EndOfPeriod) Then
		Filter.Insert("BeforeDateOfPosting", EndOfDay(EndOfPeriod) + 1);
	EndIf;
	
	If ValueIsFilled(Filter) Then
		ImportParameters.Insert("Filter", Filter);
	EndIf;
	
	Try
		IncomingMessagesTable = EmailOperations.DownloadEmailMessages(AccountIncoming, ImportParameters);
	Except
		WriteLogEvent(NStr("ru = 'Проверка входящих сообщений';
										|en = 'Check incoming messages';", Common.DefaultLanguageCode()), EventLogLevel.Error, , AccountIncoming,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
	IncomingMessages1.Clear();
	
	For Each IncomingMessageItem In IncomingMessagesTable Do
		NewRow = IncomingMessages1.Add();
		NewRow.Sender     = IncomingMessageItem.SenderName;
		If IsBlankString(IncomingMessageItem.SenderName) Then
			NewRow.Sender     = IncomingMessageItem.Sender;
		EndIf;
		NewRow.ReplyTo   = IncomingMessageItem.ReplyTo;
		NewRow.Subject            = IncomingMessageItem.Subject;
		NewRow.PostingDate = IncomingMessageItem.PostingDate;
		If IncomingMessageItem.Attachments.Count() > 0 Then
			NewRow.Attachment = True;
		Else
			NewRow.Attachment = False;
		EndIf;
		
		For Each Text In IncomingMessageItem.Texts Do
			If Text["TextType"] = "PlainText" Then
				NewRow.Text = Text["Text"];
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillAccountsChoiceList()
	
	Items.AccountIncoming.ChoiceList.Clear();
	
	AvailableEmailAccounts = EmailOperations.AvailableEmailAccounts(, True, True);
	
	HasFullAccounts = False;
	
	For Each StrAccount In AvailableEmailAccounts Do
		HasFullAccounts = True;
		Items.AccountIncoming.ChoiceList.Add(StrAccount.Ref, StrAccount.Description);
	EndDo;
	
	If HasFullAccounts Then
		AccountIncoming = Items.AccountIncoming.ChoiceList[0].Value;
	EndIf;
	
EndProcedure

#EndRegion


