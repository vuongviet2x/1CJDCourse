///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Variables

// 
&AtClient
Var PostingMeasurementID;
// End StandardSubsystems.PerformanceMonitor

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InitializeRegistrationPeriodEntry();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	If Common.IsMobileClient() Then
		Items.Date.TitleLocation = FormItemTitleLocation.Top;
		Items.Number.TitleLocation = FormItemTitleLocation.Top;
		Items.SalaryRowNumber.Visible = False;
		Items.Comment.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.AccountingAudit
	AccountingAudit.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccountingAudit
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
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
    
    // StandardSubsystems.PerformanceMonitor
	// Use case: Measure the performance with automatic error logging.
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
        
        PostingMeasurementID = PerformanceMonitorClient.TimeMeasurement("_DemoPayrollAccrualPosting", True);
						
	EndIf;
	// End StandardSubsystems.PerformanceMonitor

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.PerformanceMonitor
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		PerformanceMonitorClient.SetMeasurementErrorFlag(PostingMeasurementID, False);
	EndIf;
	// End StandardSubsystems.PerformanceMonitor
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RegistrationPeriodMonthOnChange(Item)
	
	UpdateRegistrationPeriod();
	
EndProcedure

&AtClient
Procedure RegistrationPeriodMonthClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure RegistrationPeriodYearOnChange(Item)
	
	UpdateRegistrationPeriod();
	
EndProcedure

&AtClient
Procedure RegistrationPeriodYearClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateRegistrationPeriod()
	
	Object.RegistrationPeriod = Date(RegistrationPeriodYear, RegistrationPeriodMonth, 1);
	
EndProcedure

&AtServer
Procedure InitializeRegistrationPeriodEntry()
	
	RegistrationPeriodMonth = Month(Object.RegistrationPeriod);
	RegistrationPeriodYear   = Year(Object.RegistrationPeriod);
	
	ChoiceList = Items.RegistrationPeriodMonth.ChoiceList;
	For Month = 1 To 12 Do
		ChoiceList.Add(Month, Format(Date(1917, Month, 1), "DF=MMMM"));
	EndDo;
	
	// Since period fields are not connected to data directly, force-manage their availability.
	Items.RegistrationPeriodMonth.ReadOnly = ReadOnly;
	Items.RegistrationPeriodYear.ReadOnly   = ReadOnly;
		
EndProcedure

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

// StandardSubsystems.AccountingAudit

&AtClient
Procedure Attachable_OpenIssuesReport(ItemOrCommand, Var_URL, StandardProcessing)
	AccountingAuditClient.OpenObjectIssuesReport(ThisObject, Object.Ref, StandardProcessing);
EndProcedure

// End StandardSubsystems.AccountingAudit

#EndRegion
