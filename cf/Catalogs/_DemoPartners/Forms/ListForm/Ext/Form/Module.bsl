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

	CanBeEdited = AccessRight("Edit", Metadata.Catalogs._DemoPartners);
	FullUser = Users.IsFullUser();
	
	// StandardSubsystems.BatchEditObjects
	Items.ListContextMenuReplaceAndDelete.Visible = FullUser;
	Items.FormChangeSelectedItems.Visible = CanBeEdited;
	Items.FormReplaceAndDelete.Visible = CanBeEdited;
	Items.FormMergeSelectedItems.Visible = CanBeEdited;
	Items.ListContextMenuMergeSelectedItems.Visible = CanBeEdited;
	Items.ListContextMenuChangeSelectedItems.Visible = CanBeEdited;
	// End StandardSubsystems.BatchEditObjects
	
	// StandardSubsystems.Users
	ExternalUsers.ShowExternalUsersListView(ThisObject);
	// End StandardSubsystems.Users
	
	// StandardSubsystems.Properties
	LabelsDisplayParameters = PropertyManager.LabelsDisplayParameters();
	LabelsDisplayParameters.LabelsDestinationElementName = "GroupLabels";
	LabelsDisplayParameters.LabelsDisplayOption = Enums.LabelsDisplayOptions.Label;

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("LabelsDisplayParameters", LabelsDisplayParameters);
	AdditionalParameters.Insert("ArbitraryObject", True);
	AdditionalParameters.Insert("CommandBarItemName", "CommandBar");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.MarkedObjectsDeletion
	Items.GoToMarkedForDeletionItems.Visible = FullUser;
	MarkedObjectsViewSettings = MarkedObjectsDeletion.MarkedObjectsDisplaySettings();
	Setting = MarkedObjectsViewSettings.Add();
	Setting.FormItemName = Items.List.Name;
	MarkedObjectsDeletion.OnCreateAtServer(ThisObject, MarkedObjectsViewSettings);
	MarkedObjectsDeletion.SetShowMarkedObjectsCommandMark(ThisObject, Items.List,
		Items.ShowObjectsMarkedForDeletion);
	// End StandardSubsystems.MarkedObjectsDeletion

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		AttachIdleHandler("ListAfterActivateRow", 0.1, True);
	EndIf;

	If EventName = "Write__DemoPartners" And Items.List.CurrentRow = Source Then

		AttachIdleHandler("ListAfterActivateRow", 0.1, True);
	EndIf;
	// End StandardSubsystems.Properties

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)

	If ObjectReference <> Items.List.CurrentRow Then
		ObjectReference = Items.List.CurrentRow;

		AttachIdleHandler("ListAfterActivateRow", 0.1, True);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	// StandardSubsystems.Users
	ExternalUsers.ExternalUserListOnRetrievingDataAtServer(TagName, Settings, Rows);
	// End StandardSubsystems.Users

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.MarkedObjectsDeletion

&AtClient
Procedure GoToMarkedForDeletionItems(Command)
	MarkedObjectsDeletionClient.GoToMarkedForDeletionItems(ThisObject, Items.List);
EndProcedure

&AtClient
Procedure ShowObjectsMarkedForDeletion(Command)
	FormButton = Items.ShowObjectsMarkedForDeletion;
	MarkedObjectsDeletionClient.ShowObjectsMarkedForDeletion(ThisObject, Items.List, FormButton);
EndProcedure

// End StandardSubsystems.MarkedObjectsDeletion

// StandardSubsystems.BatchEditObjects

&AtClient
Procedure ChangeSelectedItems(Command)

	BatchEditObjectsClient.ChangeSelectedItems(Items.List);

EndProcedure

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined,
	StandardProcessing = Undefined)

	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);

EndProcedure

// End StandardSubsystems.Properties

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

// StandardSubsystems.DuplicateObjectsDetection

&AtClient
Procedure MergeSelectedItems(Command)

	DuplicateObjectsDetectionClient.MergeSelectedItems(Items.List);

EndProcedure

&AtClient
Procedure ShowUsageInstances(Command)

	DuplicateObjectsDetectionClient.ShowUsageInstances(Items.List);

EndProcedure

&AtClient
Procedure ReplaceAndDelete(Command)
    
    
    // StandardSubsystems.PerformanceMonitor
	MonitoringCenterClient.WriteBusinessStatisticsOperation(
		"_DemoClientInformation._DemoProducts.ReplaceAndDelete.Click", 1);
    // End StandardSubsystems.PerformanceMonitor

	DuplicateObjectsDetectionClient.ReplaceSelected(Items.List);

EndProcedure

// End StandardSubsystems.DuplicateObjectsDetection
#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtClient
Procedure ListAfterActivateRow()

	FillAdditionalAttributesInForm();
	PopulateLabelsOnForm();

EndProcedure

&AtServer
Procedure FillAdditionalAttributesInForm()

	If ValueIsFilled(ObjectReference) Then
		PropertyManager.FillAdditionalAttributesInForm(
			ThisObject, ObjectReference.GetObject(), True);
	Else
		PropertyManager.DeleteOldAttributesAndItems(ThisObject);
	EndIf;

EndProcedure

&AtServer
Procedure PopulateLabelsOnForm()

	If ValueIsFilled(ObjectReference) Then
		PropertyManager.FillObjectLabels(
			ThisObject, ObjectReference.GetObject(), True);
	EndIf;

EndProcedure

// End StandardSubsystems.Properties

#EndRegion