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
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", Items.AdditionalAttributesPage.Name);
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	Items.Basis.Visible = ValueIsFilled(Object.Basis);
	
	If Users.IsExternalUserSession() Then
		Items.Department.Visible = False;
		Items.Contract.Visible = False;
		Items.EmployeeResponsible.Visible = False;
	EndIf;
	
	// StandardSubsystems.StoredFiles
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "Files";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.StoredFiles
	
	// StandardSubsystems.UserReminders
	PlacementParameters = UserReminders.PlacementParameters();
	PlacementParameters.Group = Items.GroupPaymentDateWithNotification;
	PlacementParameters.NameOfAttributeWithEventDate = "PayDate";
	UserReminders.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.UserReminders
	
	If Common.IsMobileClient() Then
		Items.GoodsLineNumber.Visible = False;
		Items.HeaderGroup.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.CommendAndEmployeeResponsible.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	UpdateTableRowsCounters();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.StoredFiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.StoredFiles

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.UserReminders
	UserReminders.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.UserReminders

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	If Object.DocumentCurrency.IsEmpty() And Not Object.Contract.IsEmpty() Then
		Object.DocumentCurrency = ContractCurrency(Object.Contract);
	EndIf;
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	Notify("Write__DemoCustomerProformaInvoice", New Structure, Object.Ref);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
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
	
	// StandardSubsystems.UserReminders
	UserRemindersClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	// End StandardSubsystems.UserReminders
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.UserReminders
	ReminderText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Проверить оплату по счету %1';
			|en = 'Check the payment on invoice %1';"), CurrentObject.Number);	
	UserReminders.OnWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters, ReminderText);
	// End StandardSubsystems.UserReminders
	
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
Procedure ContractOnChange(Item)
	If Object.DocumentCurrency.IsEmpty() And Not Object.Contract.IsEmpty() Then
		Object.DocumentCurrency = ContractCurrency(Object.Contract);
	EndIf;
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	// StandardSubsystems.Properties
	If PropertiesParameters.Property(CurrentPage.Name)
		And Not PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
EndProcedure

// StandardSubsystems.StoredFiles
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.StoredFiles

// StandardSubsystems.UserReminders
&AtClient
Procedure Attachable_OnChangeReminderSettings(Item)
	
	UserRemindersClient.OnChangeReminderSettings(Item, ThisObject);
	
EndProcedure
// End StandardSubsystems.UserReminders

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnChange(Item)
	UpdateTableRowsCounters();
EndProcedure

// StandardSubsystems.ImportDataFromFile

&AtClient
Procedure ImportGoodsFromFile(Command)
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "_DemoCustomerProformaInvoice.Goods";
	ImportParameters.Title               = NStr("ru = 'Загрузка списка товаров из файла';
													|en = 'Import goods list from file';");
	ImportParameters.AdditionalParameters.Insert("Counterparty", Object.Counterparty);
	ImportParameters.AdditionalParameters.Insert("Organization", Object.Organization);
	
	Notification = New NotifyDescription("ImportGoodsFromFileCompletion", ThisObject);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

// End StandardSubsystems.ImportDataFromFile

#EndRegion

#Region FormCommandsEventHandlers

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

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties

// StandardSubsystems.StoredFiles
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.StoredFiles

#EndRegion

#Region Private

// StandardSubsystems.ImportDataFromFile

&AtClient
Procedure ImportGoodsFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then 
		Return;
	EndIf;
	
	UploadProductsFromFileOnServer(ImportedDataAddress);
	RecalculateTabularSection();
		
EndProcedure

&AtServer
Procedure UploadProductsFromFileOnServer(ImportedDataAddress)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	ProductsAdded_ = False;
	FunctionalOptionCharacteristic = ?(ImportedData.Columns.Find("Characteristic") <> Undefined, True, False);
	For Each TableRow In ImportedData Do 
		
		If Not ValueIsFilled(TableRow.Products) Then 
			Continue;
		EndIf;
		
		NewLineProducts = Object.Goods.Add();
		NewLineProducts.Products = TableRow.Products;
		NewLineProducts.Price = TableRow.Price;
		NewLineProducts.Count = TableRow.Count;
		If FunctionalOptionCharacteristic Then
			NewLineProducts.Characteristic = TableRow.Characteristic;
		EndIf;
		ProductsAdded_ = True;
	EndDo;
	
	If ProductsAdded_ Then
		Modified = True;
	EndIf;
	
EndProcedure

// End StandardSubsystems.ImportDataFromFile

// StandardSubsystems.Properties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

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

&AtClient
Procedure RecalculateTabularSection()
	For Each TableRow In Object.Goods Do
		TableRow.Sum = TableRow.Count * TableRow.Price;
		TableRow.Total = TableRow.Count * TableRow.Price;
	EndDo;
EndProcedure

&AtClient
Procedure UpdateTableRowsCounters()
	SetPageTitle(Items.GoodsPage, Object.Goods, NStr("ru = 'Товары';
																			|en = 'Goods';"));
EndProcedure

&AtClient
Procedure SetPageTitle(PageItem, AttributeTabularSection, DefaultTitle)
	PageHeader = DefaultTitle;
	If AttributeTabularSection.Count() > 0 Then
		PageHeader = DefaultTitle + " (" + AttributeTabularSection.Count() + ")";
	EndIf;
	PageItem.Title = PageHeader;
EndProcedure

&AtServerNoContext
Function ContractCurrency(Contract)
	Return Common.ObjectAttributeValue(Contract, "SettlementsCurrency");
EndFunction

#EndRegion