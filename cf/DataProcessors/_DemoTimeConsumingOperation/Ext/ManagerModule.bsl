///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

// An example of a function called in the background.
Function CalculateValue(OperationNumber, CalculationDuration = 10, CompleteWithError = False, OutputProgressBar = False) Export
	
	SimulateTimeConsumingOperation(OperationNumber, CalculationDuration, OutputProgressBar);
	
	If CompleteWithError Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка: расчет %1 не выполнен';
				|en = 'Error: calculation %1 is not completed';"), OperationNumber);
		Raise ErrorText;
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Расчет %1 выполнен за %2 сек.';
			|en = 'Calculation %1 is completed in %2 seconds';"), OperationNumber, CalculationDuration);
	
EndFunction

// An example of a procedure called in the background.
Procedure PerformTheCalculation(OperationNumber, CalculationDuration = 10, CompleteWithError = False, OutputProgressBar = False) Export
	
	SimulateTimeConsumingOperation(OperationNumber, CalculationDuration, OutputProgressBar);
	
	If CompleteWithError Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка: действие %1 не выполнено';
				|en = 'Error: action %1 is not completed';"), OperationNumber);
		Raise ErrorText;
	EndIf;
	
EndProcedure

Procedure SimulateTimeConsumingOperation(OperationNumber, CalculationDuration, OutputProgressBar)
	
	BackgroundJob = GetCurrentInfoBaseSession().GetBackgroundJob();
	
	For Counter = 1 To CalculationDuration Do
		Pause(BackgroundJob, 1);
		Percent = Int(Counter / CalculationDuration * 100);
		Stage = Min(Int(Counter / (CalculationDuration / 3)) + 1, 3); // Emulation of a 3-stage operation.
		
		Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1 операция %2 выполнена на %3 % (этап %4)';
				|en = '%1 operation %2 completed by %3 % (stage %4)';"),
			CurrentSessionDate(), OperationNumber, Percent, Stage));
		
		If OutputProgressBar Then
			Message = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Этап %1';
					|en = 'Stage %1';"), Stage);
			TimeConsumingOperations.ReportProgress(Percent, Message);
		EndIf;
	EndDo;
	
EndProcedure

Procedure Pause(BackgroundJob, IdleInterval)
	
	If BackgroundJob <> Undefined Then
		BackgroundJob.WaitForExecutionCompletion(IdleInterval);
	Else
		End = CurrentUniversalDateInMilliseconds() + IdleInterval * 1000;
		While CurrentUniversalDateInMilliseconds() < End Do
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
