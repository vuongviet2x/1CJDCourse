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
	
	Query = New Query;
	
	Query.Text = "
	|SELECT
	|	ISNULL(MIN(RecordDate), DATETIME(3000,1,1)) AS RecordDate
	|FROM
	|	InformationRegister.DeleteTimeMeasurements3
	|";
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		StartDate3 = Selection.RecordDate;
	EndIf;
	
	Query.Text = "
	|SELECT
	|	ISNULL(MAX(RecordDate), DATETIME(1,1,1)) AS RecordDate
	|FROM
	|	InformationRegister.DeleteTimeMeasurements3
	|";
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		EndDate3 = Selection.RecordDate;
	EndIf;
	
	Query.Text = "
	|SELECT
	|	COUNT(*) AS MeasurementsCount
	|FROM
	|	InformationRegister.DeleteTimeMeasurements3
	|";
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		Object.CountFound = Object.CountFound + Selection.MeasurementsCount;
	EndIf;
	
	Object.StartDateFound = StartDate3;
	Object.StartDateTransfer = StartDate3;
	
	Object.EndDateFound = EndDate3;
	Object.EndDateTransfer = EndDate3;
	
	Object.LeftToTransferCount = Object.CountFound;
	
	If Object.CountFound = 0 Then
		Object.StartDateFound = Date(1,1,1);
		Object.StartDateTransfer = Date(1,1,1);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveTo_(Command)
	
	If Object.CountFound <> 0 Then
		AttachIdleHandler("TransferAttachable", 0.1, True);
	Else
		Message = New UserMessage;
		Message.Text = NStr("ru = 'Нет данных для переноса.';
								|en = 'No data to transfer.';");
	
		Message.Message();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure TransferAttachable()
	
	Written1 = TransferAtServer(Object.StartDateTransfer, Object.EndDateTransfer);
	
	If Written1 > 0 Then
		Object.LeftToTransferCount = Object.LeftToTransferCount - Written1;
		AttachIdleHandler("TransferAttachable", 0.1, True);
	Else
		Message = New UserMessage;
		Message.Text = NStr("ru = 'Перенос данных завершен.';
								|en = 'Data transfer is completed.';");
	
		Message.Message();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function TransferAtServer(StartDate, EndDate)
	
	Written1 = 0;
	
	BeginTransaction();
	
	Try
		Block = New DataLock;
		Block.Add("InformationRegister.DeleteTimeMeasurements3");
		Block.Lock();
		
		Result = SelectRecordsToTransfer(StartDate, EndDate);
		Written1 = Written1 + TransferRecords(Result);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Written1;
	
EndFunction

&AtServerNoContext
Function SelectRecordsToTransfer(StartDate, EndDate)
	
	Query = New Query;
	
	Query.Text = "
	|SELECT TOP 1000
	|	KeyOperation,
	|	MeasurementStartDate,
	|	SessionNumber,
	|	RecordDateBegOfHour,
	|	RunTime,
	|	MeasurementWeight,
	|	Comment,
	|	RecordDate,
	|	EndDate,
	|	User,
	|	RecordDateLocal
	|FROM
	|	InformationRegister.DeleteTimeMeasurements3
	|WHERE
	|	RecordDate <= &EndDate
	|ORDER BY
	|	RecordDate DESC
	|";
	
	Query.SetParameter("StartDate", StartDate);
	Query.SetParameter("EndDate", EndDate);
	Result = Query.Execute();
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function TransferRecords(Result)
	
	Written1 = 0;
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		RecordManager = InformationRegisters.TimeMeasurements.CreateRecordManager();
		RecordManager.KeyOperation = Selection.KeyOperation;
		RecordManager.SessionNumber = Selection.SessionNumber;
		RecordManager.RunTime = Selection.RunTime;
		RecordManager.RecordDate = Selection.RecordDate;
		RecordManager.User = Selection.User;
		RecordManager.RecordDateLocal = Selection.RecordDateLocal;
		RecordManager.MeasurementStartDate = Selection.MeasurementStartDate;
		RecordManager.EndDate = Selection.EndDate;
		RecordManager.RecordDateBegOfHour = Selection.RecordDateBegOfHour;
		RecordManager.MeasurementWeight = Selection.MeasurementWeight;
		RecordManager.Comment = Selection.Comment;
		RecordManager.Write(True);
		
		RecordSetDelete = InformationRegisters.DeleteTimeMeasurements3.CreateRecordSet();
		RecordSetDelete.Filter.KeyOperation.Set(Selection.KeyOperation);
		RecordSetDelete.Filter.MeasurementStartDate.Set(Selection.MeasurementStartDate);
		RecordSetDelete.Filter.SessionNumber.Set(Selection.SessionNumber);
		RecordSetDelete.Filter.RecordDateBegOfHour.Set(Selection.RecordDateBegOfHour);
		RecordSetDelete.Write(True);

		Written1 = Written1 + 1;
		
	EndDo;
	
	Return Written1;
	
EndFunction

#EndRegion