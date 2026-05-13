///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	PopulateServicesTable();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New NotifyDescription("WriteAndCloseNotification", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SearchAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If Waiting > 0 Then
		ApplyFilterInResourcesList(Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	ApplyFilterInResourcesList(Text);
	
EndProcedure

&AtClient
Procedure SearchClearing(Item, StandardProcessing)
	
	Items.OnlineSupportServices.RowFilter = Undefined;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOnlineSupportServices

&AtClient
Procedure OnlineSupportServicesSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	
	If Field = Items.OnlineSupportServicesName1 Then
		CurrentData = OnlineSupportServices.FindByID(RowSelected);
		If CurrentData <> Undefined Then
			CurrentData.CanBeManaged = Not CurrentData.CanBeManaged;
		EndIf
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectAllCommand(Command)
	
	SetResourcesListMarks(True);
	
EndProcedure

&AtClient
Procedure ClearAll3(Command)
	
	SetResourcesListMarks(False);
	
EndProcedure

&AtClient
Procedure Save(Command)
	
	SaveAtServer();
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure WriteAndCloseNotification(Result, Context) Export
	
	SaveAtServer();
	Close();
	
EndProcedure

&AtClient
Procedure ApplyFilterInResourcesList(Val Text)
	
	If ValueIsFilled(Text) Then
		Filter = New FixedStructure(New Structure("Name1", Text));
		Items.OnlineSupportServices.RowFilter = Filter;
	Else
		Items.OnlineSupportServices.RowFilter = Undefined;
	EndIf;

EndProcedure

&AtClient
Procedure SetResourcesListMarks(Val Check)
	
	// Select checkboxes for visible rows only.
	RowColumn = Items.OnlineSupportServices;
	For Each ServiceRow In OnlineSupportServices Do
		If RowColumn.RowData(ServiceRow.GetID()) <> Undefined Then
			ServiceRow.CanBeManaged = Check;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SaveAtServer()
	
	Services = New Array;
	For Each ServiceRow In OnlineSupportServices Do
		
		Services.Add(
			New Structure("Name1, CanBeManaged",
				ServiceRow.Name1,
				ServiceRow.CanBeManaged));
		
	EndDo;
	
	OnlineUserSupport.UnlockAccessToOnlineSupportServices(Services);
	
	Modified = False;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	Fields = Item.Fields.Items;
	Fields.Add().Field = New DataCompositionField("OnlineSupportServicesName1");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OnlineSupportServices.CanBeManaged");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", StyleFonts.ImportantOSLTitleFont);
	
EndProcedure

&AtServer
Procedure PopulateServicesTable()
	
	OnlineSupportServices.Clear();
	
	LockParameters = OnlineUserSupport.LockParametersWithOnlineSupportServices();
	
	For Each Resource In LockParameters.OnlineSupportServices Do
		NewString = OnlineSupportServices.Add();
		NewString.Name1  = Resource.Key;
		NewString.CanBeManaged = Resource.Value.CanBeManaged;
	EndDo;
	
	OnlineSupportServices.Sort("Name1");
	
EndProcedure

#EndRegion