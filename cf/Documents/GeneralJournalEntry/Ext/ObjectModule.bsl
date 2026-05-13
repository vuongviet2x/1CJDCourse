
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	For Each Record In RegisterRecords.GeneralJournal Do
		Record.Period = Date;
	EndDo;
	
	ChangeRecordsActivity();
	
EndProcedure

Procedure ChangeRecordsActivity()

	If IsNew() Or DeletionMark = Ref.DeletionMark Then
		Return;
	EndIf;
	
	GeneralJournalRecords = AccountingRegisters.GeneralJournal.CreateRecordSet();
	
	GeneralJournalRecords.Filter.Recorder.Set(Ref);
	GeneralJournalRecords.Read();
	
	For Each Record In GeneralJournalRecords Do
		Record.Active = Not DeletionMark;
	EndDo;
	
	GeneralJournalRecords.Write(True);
	
EndProcedure
