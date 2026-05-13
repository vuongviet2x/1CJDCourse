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

	ByPerformer = Users.AuthorizedUser();
	SetFilter();
	BusinessProcessesAndTasksServer.SetBusinessProcessesAppearance(List.ConditionalAppearance);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	If Users.IsExternalUserSession() Then
		Items.ByPerformer.Visible = False;
	EndIf;

	CanBeEdited = AccessRight("Edit", Metadata.BusinessProcesses._DemoJobWithRoleAddressing);
	Items.FormBatchObjectModification.Visible = CanBeEdited;
	Items.ListContextMenuBatchObjectModification.Visible = CanBeEdited;
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	SetListFilter(Settings);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ByPerformerOnChange(Item)
	SetFilter();
EndProcedure

&AtClient
Procedure ByPerformerRoleOnChange(Item)
	SetFilter();
EndProcedure

&AtClient
Procedure ShowExecutedJobsOnChange(Item)
	SetFilter();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeSelectedItems(Command)

	BatchEditObjectsClient.ChangeSelectedItems(Items.List);

EndProcedure

&AtClient
Procedure Stop(Command)

	BusinessProcessesAndTasksClient.Stop(
		Items.List.SelectedRows);

	For Each SelectedRow In Items.List.SelectedRows Do
		NotifyChanged(SelectedRow);
	EndDo;

EndProcedure

&AtClient
Procedure ContinueBusinessProcess(Command)

	BusinessProcessesAndTasksClient.Activate(
		Items.List.SelectedRows);

	For Each SelectedRow In Items.List.SelectedRows Do
		NotifyChanged(SelectedRow);
	EndDo;

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetFilter()
	FilterParameters = New Map;
	FilterParameters.Insert("ShowExecutedJobs", ShowExecutedJobs);
	FilterParameters.Insert("ByPerformer", ByPerformer);
	FilterParameters.Insert("ByPerformerRole", ByPerformerRole);
	SetListFilter(FilterParameters);
EndProcedure

&AtServer
Procedure SetListFilter(FilterParameters)

	CommonClientServer.DeleteDynamicListFilterGroupItems(List, "Completed");

	If Not FilterParameters["ShowExecutedJobs"] Then
		CommonClientServer.SetDynamicListFilterItem(
			List, "Completed", False);
	EndIf;

	If FilterParameters["ByPerformer"].IsEmpty() Then
		List.Parameters.SetParameterValue("Performer", Null);
	Else
		List.Parameters.SetParameterValue("Performer", FilterParameters["ByPerformer"]);
	EndIf;

	If FilterParameters["ByPerformerRole"].IsEmpty() Then
		CommonClientServer.DeleteDynamicListFilterGroupItems(List, "PerformerRole");
	Else
		CommonClientServer.SetDynamicListFilterItem(
			List, "PerformerRole", FilterParameters["ByPerformerRole"]);
	EndIf;

EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion