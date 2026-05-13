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
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName,ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
			
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
			
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
		
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FillInShortCompositionOfDocument()
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
    
    AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
    
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// StandardSubsystems.SourceDocumentsOriginalsRecording
&AtClient
Procedure Attachable_OriginalStateDecorationClick()
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject);
EndProcedure
// End StandardSubsystems.SourceDocumentsOriginalsRecording

#EndRegion

#Region FormTableItemsEventHandlersEmployees_

&AtClient
Procedure Employees_EmployeeOnChange(Item)
	
	EmployeesEmployeeWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure EmployeesStartDateOnChange(Item)
	
	EmployeesStartEndDateWhenModified()
	
EndProcedure

&AtClient
Procedure EmployeesEndDateOnChange(Item)
	
	EmployeesStartEndDateWhenModified()
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure EmployeesEmployeeWhenChangingOnServer()
	
	CurrentData = Object.Employees_.FindByID(Items.Employees_.CurrentRow);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData.StartDate = '00010101';
	CurrentData.EndDate = '00010101';
	CurrentData.DaysCount = 0;
		
EndProcedure

&AtClient
Procedure EmployeesStartEndDateWhenModified()
	
	CurrentData = Items.Employees_.CurrentData;
		
	If ValueIsFilled(CurrentData.StartDate) Then
		If ValueIsFilled(CurrentData.EndDate) Then
			If CurrentData.StartDate > CurrentData.EndDate Then	
				CommonClient.MessageToUser(NStr("ru = 'Дата начала отпуска больше чем дата окончания.';
																|en = 'The leave start date is greater than the end date.';"));
				CurrentData.StartDate = Undefined;
				Return;
			EndIf;

			CurrentData.DaysCount = (BegOfDay(CurrentData.EndDate) - BegOfDay(CurrentData.StartDate)) / (60 * 60 * 24);
		 EndIf;
	Else
		CurrentData.DaysCount = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInShortCompositionOfDocument()
	
		// First N people and M characters.
	MaximumNumberOfIndividuals = 10;
	MaxStringLength = 100;
	
	Counter = 0;
	FirstIndividuals = New Array;
	UniqueIndividuals = New Map;
	
	For Each Person In Object.Employees_ Do
		
		If Counter = MaximumNumberOfIndividuals Then
			Break;
		EndIf;
		
		If Not ValueIsFilled(Person.Employee) 
			Or UniqueIndividuals[Person.Employee] <> Undefined Then
			
			Continue;
			
		EndIf;
		
		UniqueIndividuals.Insert(Person.Employee, True);
		
		Counter = Counter + 1;
		
	EndDo;
	
	ShortComposition = StrConcat(FirstIndividuals, ", ");
            
	If StrLen(ShortComposition) > MaxStringLength Then
		ShortComposition = Left(ShortComposition, MaxStringLength - 3) + "...";
	EndIf;	

	Object.BriefDocumentComposition = ShortComposition;
	
EndProcedure

#EndRegion
