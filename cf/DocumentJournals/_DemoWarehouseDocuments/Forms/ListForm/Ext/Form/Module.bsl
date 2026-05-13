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
	
	SetConditionalAppearance();
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.CommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	CanBeEdited = False;
	For Each MetadataObject In Metadata.DocumentJournals._DemoWarehouseDocuments.RegisteredDocuments Do
		CanBeEdited = CanBeEdited Or AccessRight("Edit", MetadataObject);
	EndDo;
	
	// StandardSubsystems.BatchEditObjects
	Items.FormChangeSelectedItems.Visible = CanBeEdited;
	Items.ListContextMenuChangeSelectedItems.Visible = CanBeEdited;
	// End StandardSubsystems.BatchEditObjects
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
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

#Region FormCommandsEventHandlers


&AtClient
Procedure ChangeSelectedItems(Command)
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
EndProcedure

#EndRegion

