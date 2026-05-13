///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Variables

&AtClient
Var OperationNumber; // Number of the long-running operation.

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ExecutionSpeed = 0;
	ExpectedResult = "Success";
	WaitForm = "Show";
	ExecutionProgress = True;
	
	If Common.IsMobileClient() Then
		Items.ExpectedResult.TitleHeight = 2;
		Items.ExecutionSpeed.TitleHeight = 2;
		Items.WaitForm.TitleHeight = 2;
	EndIf;
	
	If Common.DebugMode() Then
		Items.AttentionLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
			Items.AttentionLabel.Title, "DebugMode");
		Items.WarningGroup.Visible = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteAction(Command)
	
	BeforeExecute();
	
	TimeConsumingOperation = StartProcedureExecution(OperationNumber);
	
	CallbackOnCompletion = New NotifyDescription("ProcessResult", ThisObject, OperationNumber);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters());
	
EndProcedure

&AtClient
Procedure CalculateValue(Command)
	
	BeforeExecute();
	
	TimeConsumingOperation = StartFunctionExecution(OperationNumber);
	
	CallbackOnCompletion = New NotifyDescription("ProcessResult", ThisObject, OperationNumber);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters());
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure BeforeExecute()
	
	ClearMessages();
	If OperationNumber = Undefined Then
		OperationNumber = 0;
	EndIf;
	OperationNumber = OperationNumber + 1;
	
	If WaitForm = "Show" Then
		Items.Pages.CurrentPage = Items.NotificationPage;
	Else
		Items.Pages.CurrentPage = Items.TimeConsumingOperationPage;
		NotificationText2 = NStr("ru = 'Пожалуйста, подождите...';
								|en = 'Please wait…';");
		If Not IsBlankString(Notification) Then
			NotificationText2 = Notification + Chars.LF + NotificationText2;
		EndIf;
		Items.TimeConsumingOperation.ExtendedTooltip.Title = NotificationText2;
	EndIf;
	
	Message = New UserMessage;
	Message.TargetID = UUID;
	Message.Text = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = '%1 Начало выполнения %2...';
			|en = '%1 Starting %2...';"),
		CommonClient.SessionDate(),
		OperationNumber);
	Message.Message();
	
EndProcedure 

&AtServer
Function StartFunctionExecution(OperationNumber)
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters,
		"DataProcessors._DemoTimeConsumingOperation.CalculateValue",
		OperationNumber, ExecutionSpeed, ExpectedResult = "Error", ExecutionProgress);
	
EndFunction

&AtServer
Function StartProcedureExecution(OperationNumber)
	
	Return TimeConsumingOperations.ExecuteProcedure(,
		"DataProcessors._DemoTimeConsumingOperation.PerformTheCalculation",
		OperationNumber, ExecutionSpeed, ExpectedResult = "Error", ExecutionProgress);
		
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  Context - Structure:
//   * OperationNumber - Number
//   * IsValueCalculation - Boolean
//
&AtClient
Procedure ProcessResult(Result, ExecutedOperationNumber) Export
	
	Items.Pages.CurrentPage = Items.NotificationPage;
	If Result = Undefined Then // Canceled by user.
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;
	
	OutputResult(Result, ExecutedOperationNumber);
	
EndProcedure 

// Parameters:
//  Result - See TimeConsumingOperationsClient.LongRunningOperationNewState
//  AdditionalParameters - Undefined
//
&AtClient
Procedure ExecuteActionProgressBar(Result, AdditionalParameters) Export
	
	NotificationText2 = NStr("ru = 'Пожалуйста, подождите...';
							|en = 'Please wait…';");
	If Not IsBlankString(Notification) Then
		NotificationText2 = Notification + Chars.LF + NotificationText2;
	EndIf;
	If Result.Progress <> Undefined Then
		NotificationText2 = NotificationText2 + ProgressAsString(Result.Progress);
		Items.TimeConsumingOperation.ExtendedTooltip.Title = NotificationText2;
	EndIf;
	If Result.Messages <> Undefined Then
		For Each UserMessage In Result.Messages Do
			UserMessage.TargetID = UUID;
			UserMessage.Message();
		EndDo;
	EndIf;

EndProcedure 

&AtServer
Procedure OutputResult(Result, ExecutedOperationNumber)
	
	If Result.Property("ResultAddress") And ValueIsFilled(Result.ResultAddress) Then
		MessageText = GetFromTempStorage(Result.ResultAddress);
	Else
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Действие %1 успешно выполнено';
				|en = 'Action %1 is completed';"), ExecutedOperationNumber);
	EndIf;
	
	If Result.Messages <> Undefined Then
		For Each UserMessage In Result.Messages Do
			UserMessage.TargetID = UUID;
			UserMessage.Message();
		EndDo;
	EndIf;
	
	Message = New UserMessage;
	Message.TargetID = UUID;
	Message.Text = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = '%1 %2';
			|en = '%1 %2';"), CurrentSessionDate(), MessageText);
	Message.Message();
	
EndProcedure

&AtClient
Function ProgressAsString(Progress)
	
	Result = "";
	If Progress = Undefined Then
		Return Result;
	EndIf;
	
	Percent = 0;
	If Progress.Property("Percent", Percent) Then
		Result = String(Percent) + "%";
	EndIf;
	Text = 0;
	If Progress.Property("Text", Text) Then
		If Not IsBlankString(Result) Then
			Result = Result + " (" + Text + ")";
		Else
			Result = Text;
		EndIf;
	EndIf;

	Return Result;
	
EndFunction

&AtClient
Function IdleParameters()
	
	Var ExecutionProgressNotification, IdleParameters;
	
	If (ExecutionProgress Or OutputMessages) And (WaitForm <> "Show") Then
		ExecutionProgressNotification = New NotifyDescription("ExecuteActionProgressBar", ThisObject);
	Else
		ExecutionProgressNotification = Undefined;
	EndIf;
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.MessageText = Notification;
	IdleParameters.OutputProgressBar = ExecutionProgress;
	IdleParameters.ExecutionProgressNotification = ExecutionProgressNotification;
	IdleParameters.UserNotification.Show = True;
	IdleParameters.UserNotification.URL = "e1cib/app/DataProcessor._DemoTimeConsumingOperation";
	IdleParameters.OutputIdleWindow = (WaitForm = "Show");
	IdleParameters.OutputMessages = OutputMessages;
	Return IdleParameters;

EndFunction

#EndRegion
