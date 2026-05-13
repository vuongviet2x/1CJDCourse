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
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	If Common.IsMobileClient() Then
		Items.Comment.Visible = False;
		Items.GroupOfFilters.ShowTitle = True;
		Items.Organization.TitleLocation = FormItemTitleLocation.Left;
	EndIf;
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerListForm(ThisObject, Items.List);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
		SourceDocumentsOriginalsRecordingClient.NotificationHandlerListForm(EventName, ThisObject, Items.List);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization,,, ValueIsFilled(Organization));
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "StorageLocation", Warehouse,,, ValueIsFilled(Warehouse));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
		SourceDocumentsOriginalsRecordingClient.ListSelection(Field.Name,ThisObject,Items.List, StandardProcessing);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnGetDataAtServer(Rows);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
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

// StandardSubsystems.SourceDocumentsOriginalsRecording
&AtClient
Procedure Attachable_UpdateOriginalStateCommands()
	
	UpdateOriginalStateCommands()
   
EndProcedure

&AtServer
Procedure UpdateOriginalStateCommands()
	
	AttachableCommands.OnCreateAtServer(ThisObject);
	
EndProcedure

//End StandardSubsystems.SourceDocumentsOriginalsRecording

#EndRegion

