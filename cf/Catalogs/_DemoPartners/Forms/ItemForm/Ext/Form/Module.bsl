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
	
	// StandardSubsystems.Properties
	LabelsDisplayParameters = PropertyManager.LabelsDisplayParameters();
	LabelsDisplayParameters.LabelsDestinationElementName = "GroupLabels";

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("LabelsDisplayParameters", LabelsDisplayParameters);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.ContactInformation
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("URLProcessing", True);
	AdditionalParameters.Insert("ItemForPlacementName", "ContactInformationGroup");
	ContactsManager.OnCreateAtServer(ThisObject, Object, AdditionalParameters);
	// End StandardSubsystems.ContactInformation
	
	// Take into account the possibility of creating from an interaction.
	Interactions.PrepareNotifications(ThisObject, Parameters, False);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnCreateAccessValueForm(ThisObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.StoredFiles
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.StoredFiles

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.StoredFiles

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)

	FilesOperationsClient.ShowConfirmationForClosingFormWithFiles(ThisObject, Cancel, Exit, Object.Ref);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.StoredFiles
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.StoredFiles

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.ContactInformation
	ContactsManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.ContactInformation
	ContactsManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.ContactInformation

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	InteractionsClient.ContactAfterWrite(ThisObject, Object, WriteParameters, "_DemoPartners");
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);

	Notify("Write__DemoPartners", New Structure, Object.Ref);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.ContactInformation
	ContactsManager.FillCheckProcessingAtServer(ThisObject, Object, Cancel);
	// End StandardSubsystems.ContactInformation

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
Procedure ClientOnChange(Item)
	
	// StandardSubsystems.Properties
	UpdateAdditionalAttributesItems();
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure VendorOnChange(Item)
	
	// StandardSubsystems.Properties
	UpdateAdditionalAttributesItems();
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure CompetitorOnChange(Item)
	
	// StandardSubsystems.Properties
	UpdateAdditionalAttributesItems();
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure OtherRelationsOnChange(Item)
	
	// StandardSubsystems.Properties
	UpdateAdditionalAttributesItems();
	// End StandardSubsystems.Properties

EndProcedure

// StandardSubsystems.StoredFiles
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters,
		StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters,
		StandardProcessing);

EndProcedure
// End StandardSubsystems.StoredFiles

#EndRegion

#Region FormCommandsEventHandlers

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

// StandardSubsystems.StoredFiles
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.StoredFiles

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);

EndProcedure

// End StandardSubsystems.Properties

// StandardSubsystems.ContactInformation

&AtClient
Procedure Attachable_ContactInformationOnChange(Item)
	ContactsManagerClient.StartChanging(ThisObject, Item);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationStartChoice(Item, ChoiceData, StandardProcessing)
	ContactsManagerClient.StartSelection(ThisObject, Item,, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationOnClick(Item, StandardProcessing)
	ContactsManagerClient.StartSelection(ThisObject, Item,, StandardProcessing);
EndProcedure

// Parameters:
//  Item - FormField
//  StandardProcessing - Boolean
//
&AtClient
Procedure Attachable_ContactInformationClearing(Item, StandardProcessing)
	ContactsManagerClient.StartClearing(ThisObject, Item.Name);
EndProcedure

// Parameters:
//  Command - FormCommand
//
&AtClient
Procedure Attachable_ContactInformationExecuteCommand(Command)
	ContactsManagerClient.StartCommandExecution(ThisObject, Command.Name);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
	StandardProcessing)

	ContactsManagerClient.AutoCompleteAddress(Item, Text, ChoiceData, DataGetParameters,
		Waiting, StandardProcessing);

EndProcedure

// Parameters:
//  Item - FormField
//  ValueSelected - Arbitrary
//  StandardProcessing -Boolean
//
&AtClient
Procedure Attachable_ContactInformationChoiceProcessing(Item, ValueSelected, StandardProcessing)

	ContactsManagerClient.ChoiceProcessing(ThisObject, ValueSelected, Item.Name,
		StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_ContactInformationURLProcessing(Item,
	FormattedStringURL, StandardProcessing)
	ContactsManagerClient.StartURLProcessing(ThisObject, Item,
		FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContinueContactInformationUpdate(Result, AdditionalParameters) Export
	UpdateContactInformation(Result);
EndProcedure

&AtServer
Procedure UpdateContactInformation(Result)
	ContactsManager.UpdateContactInformation(ThisObject, Object, Result);
EndProcedure

// End StandardSubsystems.ContactInformation

#EndRegion