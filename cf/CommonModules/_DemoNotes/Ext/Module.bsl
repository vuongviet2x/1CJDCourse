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

// Writes to the internal information register a record about the note presence.
//
// On catalog item write, the parameters match the handler parameters.
//
Procedure CheckIfThereAreNotesOnSubject(Source, Cancel) Export
	
	If Source.DataExchange.Load Then 
		Return; 
	EndIf;

	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(Source.SubjectOf) Then
		Return;
	EndIf;
	
	Query = New Query;
	
	QueryText = 
	"SELECT TOP 1
	|	Notes.Ref
	|FROM
	|	Catalog.Notes AS Notes
	|WHERE
	|	Notes.SubjectOf = &SubjectOf
	|	AND Notes.Author = &User
	|	AND Notes.DeletionMark = FALSE";
	Query.Text = QueryText;
	Query.SetParameter("SubjectOf", Source.SubjectOf);
	Query.SetParameter("User", Source.Author);
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.Notes");
	LockItem.SetValue("SubjectOf", Source.SubjectOf);
	LockItem.SetValue("Author", Source.Author);
	LockItem.Mode = DataLockMode.Shared;
	
	LockItem = Block.Add("InformationRegister._DemoNotesOnSubjectAvailable");
	LockItem.SetValue("SubjectOf", Source.SubjectOf);
	LockItem.SetValue("Author", Source.Author);
	
	RecordSet = InformationRegisters._DemoNotesOnSubjectAvailable.CreateRecordSet();
	RecordSet.Filter.Author.Set(Source.Author);
	RecordSet.Filter.SubjectOf.Set(Source.SubjectOf);
	
	BeginTransaction();
	Try
		Block.Lock();
		Selection = Query.Execute().Select();
		RecordSet.Read();
		
		HasNotes = Selection.Count() > 0;
		If HasNotes Then 
			If RecordSet.Count() = 0 Then
				NewRecord = RecordSet.Add();
				FillPropertyValues(NewRecord, Source);
				NewRecord.HasNotes = True;
			Else
				For Each Record In RecordSet Do
					Record.HasNotes = True;
				EndDo;
			EndIf;
		Else
			RecordSet.Clear();
		EndIf;
		
		RecordSet.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion
