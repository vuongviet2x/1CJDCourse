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
	
	ReadOnly = True;
	
	Items.FormCancelBackgroundJob.ExtendedTooltip.Title =
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Отменить фоновое задание потока обновления доступа прямо сейчас.
			           |Зависшие фоновые задания отменяются автоматически (%1 сек).
			           |Недостающее фоновое задание будет запущено автоматически.';
						|en = 'Cancel the background job of the access update thread immediately.
						|Background jobs that do not respond for %1 seconds are canceled automatically.
						|The missing background job will be started automatically.';"),
			AccessManagementInternal.MaxWaitSecondsCountOfWaitingForOneJobInThreadToBeProcessed());
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
EndProcedure

&AtClient
Procedure CancelBackgroundJob(Command)
	
	If Items.List.CurrentData = Undefined Then
		ShowMessageBox(, NStr("ru = 'Запись не выделена.';
										|en = 'Please select a background job.';"));
		Return;
	EndIf;
	
	ResultingText = "";
	CancelBackgroundJobAtServer(Items.List.CurrentData.ThreadID, ResultingText);
	
	ShowMessageBox(, ResultingText);
	
EndProcedure

&AtClient
Procedure AccessUpdateOnRecordsLevel(Command)
	
	AccessManagementInternalClient.OpenAccessUpdateOnRecordsLevelForm(, True);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure CancelBackgroundJobAtServer(JobID, ResultingText)
	
	BackgroundJob = BackgroundJobs.FindByUUID(JobID);
	
	If BackgroundJob = Undefined Then
		ResultingText = NStr("ru = 'Не удалость найти фоновое задание по идентификатору.';
								|en = 'Cannot find a background job by ID.';");
		Return;
	EndIf;
	
	Try
		BackgroundJob.Cancel();
		ResultingText = NStr("ru = 'Фоновое задание отменено.';
								|en = 'The background job is canceled.';");
	Except
		ErrorInfo = ErrorInfo();
		ResultingText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось отменить фоновое задание по причине:
			           |%1';
						|en = 'Cannot cancel the background job. Reason:
						|%1';"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndTry;
	
EndProcedure

#EndRegion


