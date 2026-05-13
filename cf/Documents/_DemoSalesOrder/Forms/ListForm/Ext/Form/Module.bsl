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
	
	QuickFilter = Common.CopyRecursive(Parameters.Filter);
	If ValueIsFilled(QuickFilter) Then
		SetFilterOnCreateAtServer(QuickFilter);
		Parameters.Filter.Clear();
	EndIf;
	
	// StandardSubsystems.AccessManagement
	FiltersDetails = New Map;
	FiltersDetails.Insert("Organization", Type("CatalogRef._DemoCompanies"));
	FiltersDetails.Insert("Partner",     Type("CatalogRef._DemoPartners"));
	AccessManagement.SetDynamicListFilters(List, FiltersDetails);
	// End StandardSubsystems.AccessManagement
	
	If Not Common.SubsystemExists("StandardSubsystems.BatchEditObjects")
	 Or Not AccessRight("Edit", Metadata.Documents._DemoSalesOrder) Then
		
		Items.FormChangeSelectedItems.Visible = False;
	EndIf;
	
	// StandardSubsystems.AccountingAudit
	AccountingAudit.OnCreateListFormAtServer(ThisObject, "List");
	// End StandardSubsystems.AccountingAudit
	
	If Common.IsMobileClient() Then
		Items.Comment.Visible = False;
		Items.HeaderGroup.ShowTitle = True;
		Items.FilterByCompany.TitleLocation = FormItemTitleLocation.Left;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If ValueIsFilled(QuickFilter) Then
		For Each FilterElement In QuickFilter Do
			Settings.Delete(FilterElement.Key);
		EndDo;
	Else
		For Each ListSettings In Settings Do
			CommonClientServer.SetDynamicListFilterItem(
				List, ListSettings.Key, ListSettings.Value, DataCompositionComparisonType.Equal,, ValueIsFilled(ListSettings.Value));
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterByOrderStatusOnChange(Item)
	SetFilterByStatusAtServer();
EndProcedure

&AtClient
Procedure FilterByOrderStatusClearing(Item, StandardProcessing)
	If OrderStatus = Undefined Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure FilterByCompanyOnChange(Item)
	SetFilterByCompanyAtServer();
EndProcedure

&AtClient
Procedure FilterByCompanyClearing(Item, StandardProcessing)
	If Organization = Undefined Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure ListDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	// StandardSubsystems.Interactions
	InteractionsClient.ListSubjectDrag(Item, DragParameters, StandardProcessing, String, Field);
	// End StandardSubsystems.Interactions

EndProcedure

&AtClient
Procedure ListDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	// StandardSubsystems.Interactions
	InteractionsClient.ListSubjectDragCheck(Item, DragParameters, StandardProcessing, String, Field);
	// End StandardSubsystems.Interactions

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	// StandardSubsystems.AccountingAudit
	AccountingAudit.OnGetDataAtServer(Settings, Rows);
	// End StandardSubsystems.AccountingAudit
	
EndProcedure

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

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Date.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Number.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Currency.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Contract.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Comment.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Counterparty.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Organization.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Partner.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.OrderStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("EmptyRef");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

EndProcedure

&AtServer
Procedure SetFilterOnCreateAtServer(QuickFilter)
	
	For Each FilterElement In QuickFilter Do
		
		If TypeOf(FilterElement.Value) = Type("ValueList") Then
			ListComparisonView = DataCompositionComparisonType.InList;
		Else
			ListComparisonView = DataCompositionComparisonType.Equal;
		EndIf;
		
		CommonClientServer.SetDynamicListFilterItem(
			List, FilterElement.Key, FilterElement.Value, ListComparisonView,, True);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetFilterByStatusAtServer()
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "OrderStatus", OrderStatus, DataCompositionComparisonType.Equal,, ValueIsFilled(OrderStatus));
	
EndProcedure

&AtServer
Procedure SetFilterByCompanyAtServer()
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	
EndProcedure

#EndRegion
