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

	MainProject = Catalogs._DemoProjects.MainProject();
	SetConditionalAppearance();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	If EventName = "Write__DemoProject" Then
		UpdateList();
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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

#Region Private

&AtServer
Procedure UpdateList()

	MainProject = Catalogs._DemoProjects.MainProject();
	SetConditionalAppearance();

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	ConditionalAppearanceOfList = List.SettingsComposer.Settings.ConditionalAppearance;
	ConditionalAppearanceOfList.Items.Clear();
	
	// Set appearance for the main project.
	ConditionalAppearanceItem = ConditionalAppearanceOfList.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;

	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Ref");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = MainProject;
	DataFilterItem.Use = True;

	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("Font");
	AppearanceColorItem.Value = Metadata.StyleItems.MainListItem.Value;
	AppearanceColorItem.Use = True;
EndProcedure

#EndRegion