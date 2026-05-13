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
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.ContactInformation
	ContactsManager.OnCreateAtServer(ThisObject, Object, Items.ContactInformationGroup.Name,
		FormItemTitleLocation.Left);
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.StoredFiles
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";

	FieldParameters                           = FilesOperations.FileField();
	FieldParameters.Location                = "PhotographGroup";
	FieldParameters.DataPath               = "Object.Photo";
	FieldParameters.ClearFile               = False;
	FieldParameters.NeedSelectFile              = False;
	FieldParameters.AddFiles2            = False;
	FieldParameters.ViewFile         = False;
	FieldParameters.EditFile         = False;
	FieldParameters.ShowCommandBar = False;

	ItemsToAdd1 = New Array;
	ItemsToAdd1.Add(FilesHyperlink);
	ItemsToAdd1.Add(FieldParameters);

	FilesOperations.OnCreateAtServer(ThisObject, ItemsToAdd1);
	// End StandardSubsystems.StoredFiles
	

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.ContactInformation
	ContactsManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.ContactInformation
	ContactsManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.ContactInformation

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	Notify("Write__DemoIndividuals", New Structure, Object.Ref);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.ContactInformation
	ContactsManager.FillCheckProcessingAtServer(ThisObject, Object, Cancel);
	// End StandardSubsystems.ContactInformation

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.StoredFiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.StoredFiles

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	
	// StandardSubsystems.StoredFiles
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.StoredFiles

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

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
//  ValueSelected - Undefined
//  StandardProcessing - Boolean
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