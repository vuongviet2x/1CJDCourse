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

#Region Public

// Records states of print form originals to the register after printing the form.
//
//	Parameters:
//  PrintObjects - ValueList - a document list.
//  PrintForms - ValueList - a description of templates and a presentation of print forms.
//  Written1 - Boolean - indicates that the document state is written to the register.
//
Procedure WriteDocumentOriginalsStatesAfterPrintForm(PrintObjects, PrintForms, Written1 = False) Export
	
	State = PredefinedValue("Catalog.SourceDocumentsOriginalsStates.FormPrinted");
	If Not ValueIsFilled(PrintObjects) Then 
		Return;
	EndIf;
	
	Block = New DataLock();

	BeginTransaction();
	Try
		
		For Each Document In PrintObjects Do
			If SourceDocumentsOriginalsRecording.IsAccountingObject(Document.Value) Then 
				LockItem = Block.Add("InformationRegister.SourceDocumentsOriginalsStates");
				LockItem.SetValue("Owner", Document.Value); 
			EndIf;
		EndDo;
		Block.Lock();
		
		For Each Document In PrintObjects Do
			If SourceDocumentsOriginalsRecording.IsAccountingObject(Document.Value) Then 
				TS = SourceDocumentsOriginalsRecording.TableOfEmployees(Document.Value);
				If TS <> "" Then
					For Each Employee In Document.Value[TS] Do
						For Each Form In PrintForms Do 
							WriteDocumentOriginalStateByPrintForms(Document.Value, 
								Form.Value, Form.Presentation, State, False, Employee.Employee);
						EndDo;
					EndDo;
				Else
					For Each Form In PrintForms Do
						WriteDocumentOriginalStateByPrintForms(Document.Value, Form.Value,
							Form.Presentation, State, False);
					EndDo;
				EndIf;
				WriteCommonDocumentOriginalState(Document.Value, State);
				Written1 = True;
			EndIf;
		EndDo;
		
		CommitTransaction();
		
	Except	
		
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Records the print form original state to the register after printing the form.
//
//	Parameters:
//  Document - DocumentRef - document reference.
//  PrintForm - String - a print form template name.
//  Presentation - String - a print form description.
//  State - String - a description of the print form original state
//            - CatalogRef - a reference to the print form original state.
//  FromOutside - Boolean - indicates whether the form belongs to 1C:Enterprise.
//  Employee - CatalogRef - A reference to an employee if the source document contains employees information.
//
Procedure WriteDocumentOriginalStateByPrintForms(Document, PrintForm, Presentation, State, 
	FromOutside, Employee = Undefined) Export
	
	SetPrivilegedMode(True);
	
	OriginalStateRecord = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordManager();
	OriginalStateRecord.Owner = Document;
	OriginalStateRecord.SourceDocument = PrintForm;
	If ValueIsFilled(Employee) Then
		LastFirstName = Employee.Description;
		Values = New Structure("Presentation, LASTFIRSTNAME", Presentation, LastFirstName);
		EmployeeView = StrFind(Presentation, LastFirstName);
		If EmployeeView = 0 Then
			OriginalStateRecord.SourceDocumentPresentation = StringFunctionsClientServer.InsertParametersIntoString(
				NStr("ru = '[Presentation] [LastFirstName]';
					|en = '[Presentation] [LastFirstName]';"), Values);
		Else
			OriginalStateRecord.SourceDocumentPresentation = Presentation;
		EndIf;
	Else
		OriginalStateRecord.SourceDocumentPresentation = Presentation;
	EndIf;
	OriginalStateRecord.State = Catalogs.SourceDocumentsOriginalsStates.FindByDescription(State);
	OriginalStateRecord.ChangeAuthor = Users.CurrentUser();
	OriginalStateRecord.OverallState = False;
	OriginalStateRecord.ExternalForm = FromOutside;
	OriginalStateRecord.LastChangeDate = CurrentSessionDate();
	OriginalStateRecord.Employee = Employee;
	OriginalStateRecord.Write();

EndProcedure

// Records the overall state of the document original to the register.
//
//	Parameters:
//  Document - DocumentRef - document reference.
//  State - String - a description of the original state.
//
Procedure WriteCommonDocumentOriginalState(Document, State) Export

	SetPrivilegedMode(True);
		
	OriginalStateRecord = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordManager();
	OriginalStateRecord.Owner = Document;
	OriginalStateRecord.SourceDocument = "";
		
	CheckOriginalStateRecord = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordSet();
	CheckOriginalStateRecord.Filter.Owner.Set(Document.Ref);
	CheckOriginalStateRecord.Filter.OverallState.Set(False);
	CheckOriginalStateRecord.Read();
	If CheckOriginalStateRecord.Count() Then
		For Each Record In CheckOriginalStateRecord Do
			If Record.ChangeAuthor <> Users.CurrentUser() Then
				OriginalStateRecord.ChangeAuthor = Undefined;
			Else
				OriginalStateRecord.ChangeAuthor = Users.CurrentUser();
			EndIf;
		EndDo;
		If SourceDocumentsOriginalsRecording.PrintFormsStateSame(Document, State) Then
			OriginalStateRecord.State = Catalogs.SourceDocumentsOriginalsStates.FindByDescription(State);
		Else
				OriginalStateRecord.State = Catalogs.SourceDocumentsOriginalsStates.OriginalsNotAll;
		EndIf;
	Else
		OriginalStateRecord.State = Catalogs.SourceDocumentsOriginalsStates.FindByDescription(State);
		OriginalStateRecord.ChangeAuthor = Users.CurrentUser();
	EndIf;
		
	OriginalStateRecord.OverallState = True;
	OriginalStateRecord.LastChangeDate = CurrentSessionDate();
	OriginalStateRecord.Write();

EndProcedure

#EndRegion

#EndIf

