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
	
	IsGoods = Not Common.EmptyClipboard("Goods");
	Items.GoodsInsertRows.Enabled = IsGoods;
	Items.GoodsInsertMenuRows.Enabled = IsGoods;
	
	Items.VAT.Visible = Object.ConsiderVAT Or GetFunctionalOption("_DemoIncludeVAT");
	Items.VATRate.Enabled = Object.ConsiderVAT;
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	If Common.IsMobileClient() Then
		Items.StandardAttributesGroup.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.MainAttributesGroup.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.GoodsLineNumber.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DefineProductsThatRequireCCDInput();
	
	// StandardSubsystems.AccountingAudit
	AccountingAudit.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccountingAudit
	
	If ValueIsFilled(Object.TaxInvoice) Then
		Items.DisplayTaxInvoiceGroup.CurrentPage = Items.TaxInvoiceGroup;
	Else
		Items.DisplayTaxInvoiceGroup.CurrentPage = Items.PostTaxInvoiceGroup;
	EndIf;
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateTableRowsCounters();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	DefineProductsThatRequireCCDInput();
	// StandardSubsystems.AccountingAudit
	AccountingAudit.AfterWriteAtServer(CurrentObject);
	// End StandardSubsystems.AccountingAudit
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	Notify("Write__DemoGoodsReceipt", , Object.Ref);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "DataCopiedToClipboard" Then
		IsGoods = (Parameter.CopySource = "Goods");
		Items.GoodsInsertRows.Enabled = IsGoods;
		Items.GoodsInsertMenuRows.Enabled = IsGoods;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ConsiderVATOnChange(Item)
	Items.VATRate.Enabled = Object.ConsiderVAT;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnChange(Item)
	UpdateTableRowsCounters();
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	If Items.Goods.CurrentData <> Undefined Then
		Items.Goods.CurrentData.CCDRequired = DefineCCDNecessity(Items.Goods.CurrentData.Products);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAgentServices

&AtClient
Procedure AgentServicesOnChange(Item)
	UpdateTableRowsCounters();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PostTaxInvoice(Command)
	PostTaxInvoiceServer();
	Read();
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If Items.Goods.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CopyLinesOnServer();
	ShowUserNotification(NStr("ru = 'Копирование в буфер обмена';
										|en = 'Copy to clipboard';"), Window.GetURL(), 
		StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Скопировано товаров: %1';
																	|en = 'Copied goods: %1';"), Items.Goods.SelectedRows.Count()));
	Notify("DataCopiedToClipboard", New Structure("CopySource", "Goods"), Object.Ref);
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	Count = InsertRowsOnServer();
	If Count > 0 Then
		ShowUserNotification(NStr("ru = 'Вставка из буфера обмена';
											|en = 'Paste';"), Window.GetURL(), 
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Вставлено товаров: %1';
																		|en = 'Inserted goods: %1';"), Count));
	EndIf;
		
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateTableRowsCounters()
	SetPageTitle(Items.GoodsPage, Object.Goods, NStr("ru = 'Товары';
																			|en = 'Goods';"));
	SetPageTitle(Items.AgentServicesPage, Object.AgentServices, NStr("ru = 'Агентские услуги';
																								|en = 'Agency services';"));
EndProcedure

&AtClient
Procedure SetPageTitle(PageItem, AttributeTabularSection, DefaultTitle)
	PageHeader = DefaultTitle;
	If AttributeTabularSection.Count() > 0 Then
		PageHeader = DefaultTitle + " (" + AttributeTabularSection.Count() + ")";
	EndIf;
	PageItem.Title = PageHeader;
EndProcedure

&AtServer
Procedure PostTaxInvoiceServer()
	If CheckFilling() Then
		ReceiptObject = FormAttributeToValue("Object");
		If Modified Then
			ReceiptObject.Write(DocumentWriteMode.Posting);
		EndIf;
		
		InvoiceObject = Documents._DemoTaxInvoiceReceived.CreateDocument();
		InvoiceObject.Consignor = Object.Counterparty;
		InvoiceObject.Counterparty = Object.Counterparty;
		InvoiceObject.Seller = Object.Counterparty;
		InvoiceObject.Date = Object.Date;
		InvoiceObject.Write();
		
		ReceiptObject.TaxInvoice = InvoiceObject.Ref;
		ReceiptObject.Write(DocumentWriteMode.Posting);
		
		ValueToFormAttribute(ReceiptObject, "Object");
	EndIf;
EndProcedure

&AtServer
Procedure CopyLinesOnServer()
	
	Common.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows, "Goods");

EndProcedure

&AtServer
Function InsertRowsOnServer()
	
	DataFromClipboard = Common.RowsFromClipboard();
	If DataFromClipboard.Source <> "Goods" Then
		Return 0;
	EndIf;
		
	Table = DataFromClipboard.Data;
	For Each TableRow In Table Do
		FillPropertyValues(Object.Goods.Add(), TableRow);
	EndDo;
	
	DefineProductsThatRequireCCDInput();
	
	Return Table.Count();
	
EndFunction

&AtServer
Procedure DefineProductsThatRequireCCDInput()
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	OwnGoods.Products AS Products
	|INTO OwnGoods
	|FROM
	|	&OwnGoods AS OwnGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OwnGoods.Products AS Products
	|FROM
	|	OwnGoods AS OwnGoods
	|		LEFT JOIN Catalog._DemoProducts AS _DemoProducts
	|		ON (OwnGoods.Products = _DemoProducts.Ref)
	|WHERE 
	|	NOT ISNULL(_DemoProducts.OriginCountry.EEUMember, TRUE) = TRUE";
	
	Query.SetParameter("OwnGoods", Object.Goods.Unload(, "Products"));
	QueryResult = Query.Execute().Select();
	
	While QueryResult.Next() Do
		Filter = New Structure("Products", QueryResult.Products);
		FoundRows = Object.Goods.FindRows(Filter);
		For Each RowThatRequiresCCD  In FoundRows Do
			RowThatRequiresCCD.CCDRequired = True;
		EndDo;
	EndDo;
	
EndProcedure

&AtServerNoContext
Function DefineCCDNecessity(Products)
	
	If ValueIsFilled(Products) Then
		OriginCountry = Common.ObjectAttributeValue(Products, "OriginCountry");
		Return Not ContactsManager.IsEEUMemberCountry(OriginCountry);
	EndIf;
	
	Return False;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	DataFilterItemsGroup               = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	DataFilterItemsGroup.GroupType     = DataCompositionFilterItemsGroupType.AndGroup;
	DataFilterItemsGroup.Use = True;
	
	DataFilterItem                = DataFilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Object.Goods.CCDRequired");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use  = True;
	
	DataFilterItem                = DataFilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Object.Goods.CCDNumber");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.NotFilled;
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem               = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field          = New DataCompositionField(Items.GoodsCCDNumber.Name);
	AppearanceFieldItem.Use = True;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

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

// StandardSubsystems.AccountingAudit
&AtClient
Procedure Attachable_OpenIssuesReport(ItemOrCommand, Var_URL, StandardProcessing)
	AccountingAuditClient.OpenObjectIssuesReport(ThisObject, Object.Ref, StandardProcessing);
EndProcedure
// End StandardSubsystems.AccountingAudit

#EndRegion