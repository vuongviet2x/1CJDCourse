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

	List.Parameters.SetParameterValue("User", Users.AuthorizedUser());
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.CommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.BatchEditObjects
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs._DemoProducts);
	Items.FormChangeSelectedItems.Visible = CanBeEdited;
	Items.ListContextMenuChangeSelectedItems.Visible = CanBeEdited;
	// End StandardSubsystems.BatchEditObjects
	
	// StandardSubsystems.AccountingAudit
	AccountingAudit.OnCreateListFormAtServer(ThisObject, "List");
	// End StandardSubsystems.AccountingAudit
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.Properties
	LabelsDisplayParameters = PropertyManager.LabelsDisplayParameters();
	LabelsDisplayParameters.LabelsDestinationElementName = "GroupLabels";
	LabelsDisplayParameters.LabelsLegendDestinationElementName = "GroupLegendLabels";
	LabelsDisplayParameters.ObjectsKind = Metadata.Catalogs._DemoCounterparties.FullName();

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("LabelsDisplayParameters", LabelsDisplayParameters);
	AdditionalParameters.Insert("ArbitraryObject", True);
	AdditionalParameters.Insert("CommandBarItemName", "CommandBar");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	// StandardSubsystems.AccountingAudit
	AccountingAudit.OnGetDataAtServer(Settings, Rows);
	// End StandardSubsystems.AccountingAudit 
	
	// StandardSubsystems.Properties
	PropertyManager.OnGetDataAtServer(Settings, Rows);
	// End StandardSubsystems.Properties

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.BatchEditObjects

&AtClient
Procedure ChangeSelectedItems(Command)

	BatchEditObjectsClient.ChangeSelectedItems(Items.List);

EndProcedure

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.AccountingAudit

&AtClient
Procedure Attachable_Selection(Item, RowSelected, Field, StandardProcessing)

	AccountingAuditClient.OpenListedIssuesReport(ThisObject, "List", Field, StandardProcessing);

EndProcedure

// End StandardSubsystems.AccountingAudit

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

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_SetLabelsLegendVisibility(Command)

	SetLabelsLegendVisibility();

EndProcedure

&AtServer
Procedure SetLabelsLegendVisibility()

	PropertyManager.SetLabelsLegendVisibility(ThisObject);

EndProcedure

// End StandardSubsystems.Properties

#EndRegion