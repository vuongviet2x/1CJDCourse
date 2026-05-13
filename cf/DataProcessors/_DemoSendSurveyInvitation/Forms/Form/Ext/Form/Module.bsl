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

&AtClient
Procedure SendSurveyInvitation(Ref, ExecutionParameters) Export
	
	TimeConsumingOperation = CreateAndSendEmail(Ref);
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = True;
	Handler = New NotifyDescription("AfterSendInvitation", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, Handler, WaitSettings);
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure AfterSendInvitation(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		SendingResult = GetFromTempStorage(Result.ResultAddress);
		If SendingResult.Success Then
			ShowUserNotification(NStr("ru = 'Приглашение успешно отправлено.';
												|en = 'The invitation is successfully sent.';"));
			Return;
		Else
			ErrorInfo = SendingResult.ErrorInfo;
		EndIf;
	Else
		ErrorInfo = Result.ErrorInfo;
	EndIf;
	
	StandardSubsystemsClient.OutputErrorInfo(ErrorInfo);
	
EndProcedure

&AtServer
Function CreateAndSendEmail(Ref)
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Ref", Ref);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("ru = 'Создание и отправка приглашения для проведения опроса.';
			|en = 'Create and send the survey invitation.';");
	ExecutionParameters.RefinementErrors =
		NStr("ru = 'Не удалось отправить приглашение по причине:';
			|en = 'Cannot send the invitation. Reason:';");
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors._DemoSendSurveyInvitation.CreateAndSendEmail",
		ProcedureParameters,
		ExecutionParameters);
	
EndFunction

#EndRegion
