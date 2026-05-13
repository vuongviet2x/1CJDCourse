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
	
	Filter = Undefined;
	If Parameters.Filter <> Undefined
		And Parameters.Filter.Property("Organization") Then
		Filter = CommonClientServer.ValueInArray(Parameters.Filter.Organization);
	EndIf;
	
	PersonsResponsibleAndCompanies.Load(InformationRegisters._DemoPersonsResponsible.PersonsResponsibleAndCompanies(Filter));
	
	If Common.IsMobileClient() Then 
		Items.PersonsResponsibleAndCompanies.CommandBarLocation = FormItemCommandBarLabelLocation.None;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New NotifyDescription("SelectAndClose", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	WriteEmployeesResponsibleList();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure WriteEmployeesResponsibleList()
	
	For Each Item In PersonsResponsibleAndCompanies Do
		
		BeginTransaction();
		Try
			Block = New DataLock;
		    LockItem = Block.Add("InformationRegister._DemoPersonsResponsible");
		    LockItem.SetValue("Organization", Item.Organization);
		    Block.Lock();
			
			RecordSet = InformationRegisters._DemoPersonsResponsible.CreateRecordSet();
			RecordSet.Filter.Organization.Set(Item.Organization);
			RecordSet.Read();
			
			If RecordSet.Count() <> 0 Then
				
				For Each Record In RecordSet Do
					
					Record.Individual = Item.EmployeeResponsible;
					
				EndDo;
				
			Else
				
				Record = RecordSet.Add();
				Record.Organization    = Item.Organization;
				Record.Individual = Item.EmployeeResponsible;
				
			EndIf;
			
			RecordSet.Write();
			
			CommitTransaction();
		Except
			RollbackTransaction();
    		Raise;
		EndTry;
		
	EndDo;
	
	Modified = False;
	
EndProcedure

&AtClient
Procedure SelectAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	
	WriteEmployeesResponsibleList();
	Modified = False;
	Close();
	
EndProcedure

#EndRegion
