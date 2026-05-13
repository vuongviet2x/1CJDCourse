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
	Object.DeleteCreatedObjects = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteAction(Command)
	BackgroundJob = StartExecutionAtServer();
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	Handler = New NotifyDescription("AfterExecuteAction", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function StartExecutionAtServer()
	
	Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 Начало выполнения...';
																										|en = '%1 Starting...';"), CurrentSessionDate()));
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("CounterpartiesCount", Object.CounterpartiesCount);
	ProcedureParameters.Insert("CounterpartyBankAccountCount", Object.CounterpartyBankAccountCount);
	ProcedureParameters.Insert("DeleteCreatedObjects", Object.DeleteCreatedObjects);
		
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Демо: замер длительной операции';
															|en = 'Demo: Measure long-running operation';");
	ExecutionParameters.RefinementErrors = NStr("ru = 'Не удалось выполнить действие по причине:';
												|en = 'Cannot perform the operation. Reason:';");
	
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessors._DemoTimeConsumingOperationMeasurement1.ExecuteAction", 
		ProcedureParameters, ExecutionParameters);
	
EndFunction
	
// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure AfterExecuteAction(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;
	
	CommonClient.MessageToUser(NStr("ru = 'Действие выполнено.';
													|en = 'Operation completed.';"));	
	
EndProcedure
	
#EndRegion
