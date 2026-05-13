///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Variables

// 
&AtClient
Var PostingMeasurementID;
// End StandardSubsystems.PerformanceMonitor

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	PreviousOrderStatus = Object.OrderStatus;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	// StandardSubsystems.Interactions
	Interactions.PrepareNotifications(ThisObject,Parameters);
	// End StandardSubsystems.Interactions
	
	// StandardSubsystems.ContactInformation
	AdditionalContactInformationParameters = ContactsManager.ContactInformationParameters();
	AdditionalContactInformationParameters.ItemForPlacementName = "ContactInformationGroup";
	AdditionalContactInformationParameters.CITitleLocation = FormItemTitleLocation.Left;
	AdditionalContactInformationParameters.AllowAddingFields = False;
	ContactsManager.OnCreateAtServer(ThisObject, Object, AdditionalContactInformationParameters);
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.ContactInformation
	InitializeContactInformationFields();
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	SetItemsVisibility();
	
	// StandardSubsystems.StoredFiles
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	SettingsOfFileManagementInForm = FilesOperations.SettingsOfFileManagementInForm();
	SettingsOfFileManagementInForm.DuplicateAttachedFiles = True;
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink, SettingsOfFileManagementInForm);
	// End StandardSubsystems.StoredFiles
	
	If Common.IsMobileClient() Then
		
		Items.Contract.TitleLocation = FormItemTitleLocation.Top;
		Items.Comment.TitleLocation = FormItemTitleLocation.Top;
		Items.MessageTemplate.Title = NStr("ru = 'Шаблон';
													|en = 'Template';");
		Items.MessageTemplate.TitleLocation = FormItemTitleLocation.Auto;
		Items.ProformaInvoicesRowNumber.Visible = False;
		Items.PartnersAndContactPersonsRowNumber.Visible = False;
		Items.HeaderRight.ItemsAndTitlesAlign =
			ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.MainGroup3.ItemsAndTitlesAlign =
			ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateTableRowsCounters();
	
	// StandardSubsystems.StoredFiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.StoredFiles
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.ContactInformation
	ContactsManager.FillCheckProcessingAtServer(ThisObject, Object, Cancel);
	// End StandardSubsystems.ContactInformation

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
	// StandardSubsystems.ContactInformation
	ContactsManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.ContactInformation
	
	SetItemsVisibility();
	
	// StandardSubsystems.AccountingAudit
	AccountingAudit.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccountingAudit
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	// StandardSubsystems.PerformanceMonitor
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
	
		PostingMeasurementID = PerformanceMonitorClient.TimeMeasurement();
		
	EndIf;
	// End StandardSubsystems.PerformanceMonitor
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.ContactInformation
	ContactsManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.ContactInformation

EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.StoredFiles
	FilesOperations.OnWriteAtServer(Cancel, CurrentObject, WriteParameters, ThisObject);
	// End StandardSubsystems.StoredFiles
	
	// StandardSubsystems.Interactions
	If ValueIsFilled(InteractionBasis) Then
		Interactions.OnWriteSubjectFromForm(
			CurrentObject.Ref, InteractionBasis, Cancel);
	EndIf;
	// End StandardSubsystems.Interactions
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	// StandardSubsystems.ContactInformation
	ContactsManager.AfterWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.MessagesTemplates
	If CurrentObject.OrderStatus <> PreviousOrderStatus
		And CurrentObject.NotifyOnOrderStatusChange Then
		
			Accounts_ = EmailOperations.AvailableEmailAccounts(True, False);

			AdditionalParameters = MessageTemplates.ParametersForSendingAMessageUsingATemplate();
			AdditionalParameters.SendImmediately = True;
			If Accounts_.Count() > 0 Then
				AdditionalParameters.Account = Accounts_[0].Ref;
			EndIf;
			
			AdditionalParameters.DCSParametersValues.Insert("DeliveryDate", Format(CurrentSessionDate() + 24*60*60, "DLF=DD;" ));
			
			Result = MessageTemplates.GenerateMessageAndSend(CurrentObject.MessageTemplate, CurrentObject.Ref, UUID, AdditionalParameters);
			
			If Not Result.Sent Then
				WriteLogEvent(EventLogEvent(), EventLogLevel.Warning, Metadata.Documents._DemoSalesOrder,
					Object.Ref, Result.ErrorDescription);
			EndIf;
			PreviousOrderStatus = CurrentObject.OrderStatus;
	EndIf;
	// End StandardSubsystems.MessagesTemplates
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.PerformanceMonitor
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
        
        PerformanceMonitorClient.SetMeasurementKeyOperation(PostingMeasurementID, "_DemoSalesOrderPosting");
		
	EndIf;
	// End StandardSubsystems.PerformanceMonitor
	
	// StandardSubsystems.Interactions
	InteractionsClient.InteractionSubjectAfterWrite(ThisObject,Object,WriteParameters,"_DemoSalesOrder");
	// End StandardSubsystems.Interactions
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	Notify("Write__DemoSalesOrder", New Structure, Object.Ref);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	// StandardSubsystems.StoredFiles
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.StoredFiles

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CounterpartyOnChange(Item)
	
	SetItemsVisibility();
	
EndProcedure

// StandardSubsystems.ContactInformation

// Demo of API that adds contact information fields to a form.

&AtClient
Procedure DeliveryAddressPresentationOnChange(Item)
	
	Text = Item.EditText;
	If IsBlankString(Text) Then
		// Reset both presentations and internal field values.
		DeliveryAddressPresentation = "";
		DeliveryAddressComment   = "";
		Object.DeliveryAddress        = "";
		Return;
	EndIf;
		
	// Generate internal field values using the generating parameters and text from
	// the "DeliveryAddressContactInformationKind" attribute.
	DeliveryAddressPresentation = Text;
	Object.DeliveryAddress = ValuesOfContactInformationFieldsServer(Text, DeliveryAddressContactInformationKind, DeliveryAddressComment);
EndProcedure

&AtClient
Procedure DeliveryAddressPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	// If the user edits the presentation in the field and clicks the choice button right away, 
	// update the data and reset the internal fields for re-parsing.
	If Item.EditText <> DeliveryAddressPresentation Then
		DeliveryAddressPresentation = Item.EditText;
		Object.DeliveryAddress        = "";
	EndIf;
	
	// Editable data.
	OpeningParameters = ContactsManagerClient.ContactInformationFormParameters(DeliveryAddressContactInformationKind, 
		Object.DeliveryAddress, DeliveryAddressPresentation, DeliveryAddressComment);
		
	If IsBlankString(Object.DeliveryAddress) Then
		OpeningParameters.AddressType = "AdministrativeAndTerritorial";
	EndIf;
	
	ContactsManagerClient.OpenContactInformationForm(OpeningParameters, Item);
	
EndProcedure

&AtClient
Procedure DeliveryAddressPresentationClearing(Item, StandardProcessing)
	// Reset both presentations and internal field values.
	DeliveryAddressPresentation = "";
	DeliveryAddressComment   = "";
	Object.DeliveryAddress        = "";
EndProcedure

&AtClient
Procedure DeliveryAddressPresentationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	If TypeOf(ValueSelected)<>Type("Structure") Then
		// Cancel choice, data is not modified.
		Return;
	EndIf;
	
	DeliveryAddressPresentation = ValueSelected.Presentation;
	DeliveryAddressComment   = ValueSelected.Comment;
	Object.DeliveryAddress        = ValueSelected.Value;
	Modified          = True;
	
EndProcedure

&AtClient
Procedure DeliveryAddressCommentOnChange(Item)
	FillDeliveryAddressCommentServer();
EndProcedure

&AtClient
Procedure EmailRepresentationOnChange(Item)
	Text = Item.EditText;
	If IsBlankString(Text) Then
		// Reset both presentations and internal field values.
		EmailRepresentation = "";
		Object.Email       = "";
		Return;
	EndIf;
		
	// Generate internal field values using the generating parameters and text from
	// the "EmailContactInformationKind" attribute.
	EmailRepresentation = Text;
	Object.Email = ValuesOfContactInformationFieldsServer(Text, EmailContactInformationKind);
EndProcedure

// End StandardSubsystems.ContactInformation

// StandardSubsystems.MessagesTemplates

&AtClient
Procedure MessageTemplateStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	Notification = New NotifyDescription("AfterTemplateChoice", ThisObject);
	MessageTemplatesClient.SelectTemplate(Notification, "MailMessage", "CustomerNotificationChangeOrder");
	
EndProcedure

// End StandardSubsystems.MessagesTemplates

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

#EndRegion

#Region FormTableItemsEventHandlersProformaInvoices

&AtClient
Procedure ProformaInvoicesOnChange(Item)
	UpdateTableRowsCounters();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPartnersAndContactPersons

&AtClient
Procedure PartnersAndContactPersonsOnChange(Item)
	UpdateTableRowsCounters();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteEmail2(Command)
	
	EmailParameters = ContactsManagerClient.SMSAndEmailParameters();
	EmailParameters.Presentation = EmailRepresentation;
	EmailParameters.ExpectedKind = EmailContactInformationKind;
	EmailParameters.ContactInformationSource = Object.Partner;
	EmailParameters.AttributeName = "EmailRepresentation";
	ContactsManagerClient.CreateEmailMessage(Object.Email, EmailParameters);
		
EndProcedure

// StandardSubsystems.StoredFiles
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.StoredFiles

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

#EndRegion

#Region Private

// Returns a string constant for generating event log messages.
//
// Returns:
//   String
//
&AtServerNoContext
Function EventLogEvent()
	
	Return NStr("ru = 'Неудачная отправка оповещения';
				|en = 'Failed to send notification';", Common.DefaultLanguageCode());
	
EndFunction

// StandardSubsystems.ObjectAttributesLock

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	LockedAttributes = ObjectAttributesLockClient.Attributes(ThisObject);
	
	If LockedAttributes.Count() > 0 Then
		FormParameters = New Structure;
		FormParameters.Insert("Ref", Object.Ref);
		FormParameters.Insert("LockedAttributes", LockedAttributes);
		
		OpenForm("Document._DemoSalesOrder.Form.AttributeUnlocking", FormParameters,
			ThisObject,,,, New NotifyDescription("AfterAttributesToUnlockChoice", ThisObject));
	Else
		ObjectAttributesLockClient.ShowAllVisibleAttributesUnlockedWarning();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterAttributesToUnlockChoice(AttributesToUnlock, Context) Export
	
	If TypeOf(AttributesToUnlock) <> Type("Array") Then
		Return;
	EndIf;
	
	ObjectAttributesLockClient.SetFormItemEnabled(ThisObject,
		AttributesToUnlock);
	
EndProcedure

// End StandardSubsystems.ObjectAttributesLock

&AtServer
Procedure SetItemsVisibility()
	
	If ValueIsFilled(Object.Counterparty) Then
		CounterpartyKind = Common.ObjectAttributeValue(Object.Counterparty, "CounterpartyKind");
	Else
		CounterpartyKind = Undefined;
	EndIf;
	
	Items.Contract.Visible = CounterpartyKind <> Enums._DemoBusinessEntityIndividual.Individual;
	
EndProcedure

&AtClient
Procedure UpdateTableRowsCounters()
	
	Items.ProformaInvoicesPage.Title = 
		?(Object.ProformaInvoices.Count() > 0, 
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Счета на оплату (%1)';
																		|en = 'Proforma invoices (%1)';"), Object.ProformaInvoices.Count()),
			NStr("ru = 'Счета на оплату';
				|en = 'Proforma invoices';"));
	Items.PartnersAndContactPersonsPage.Title = 
		?(Object.PartnersAndContactPersons.Count() > 0, 
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Контактные лица (%1)';
																		|en = 'Contact persons (%1)';"), Object.PartnersAndContactPersons.Count()),
			NStr("ru = 'Контактные лица';
				|en = 'Contact persons';"));
	
EndProcedure

// StandardSubsystems.ContactInformation

&AtClient
Procedure Attachable_ContactInformationOnChange(Item)
	ContactsManagerClient.StartChanging(ThisObject, Item);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationStartChoice(Item, ChoiceData, StandardProcessing)
	ContactsManagerClient.StartSelection(ThisObject, Item, , StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationOnClick(Item, StandardProcessing)
	ContactsManagerClient.StartSelection(ThisObject, Item, , StandardProcessing);
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
Procedure Attachable_ContactInformationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	ContactsManagerClient.AutoCompleteAddress(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing);
	
EndProcedure

// Parameters:
//  Item - FormField
//  ValueSelected - Arbitrary
//  StandardProcessing -Boolean
//
&AtClient
Procedure Attachable_ContactInformationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ContactsManagerClient.ChoiceProcessing(ThisObject, ValueSelected, Item.Name, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_ContactInformationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	ContactsManagerClient.StartURLProcessing(ThisObject, Item, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContinueContactInformationUpdate(Result, AdditionalParameters) Export
	UpdateContactInformation(Result);
EndProcedure

&AtServer
Procedure UpdateContactInformation(Result)
	ContactsManager.UpdateContactInformation(ThisObject, Object, Result);
EndProcedure

// Demo of API that adds contact information fields to a form.

&AtServer
Procedure InitializeContactInformationFields()
	
	// Form attribute that manages a delivery address.
	DescriptionKindContactInformation = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	DescriptionKindContactInformation.ValidationSettings.CheckValidity = True;
	DescriptionKindContactInformation.ValidationSettings.IncludeCountryInPresentation = True;
	DescriptionKindContactInformation.Description = NStr("ru = 'Адрес доставки';
														|en = 'Delivery address';");
	DeliveryAddressContactInformationKind = DescriptionKindContactInformation;
	
	// Email attributes are the same.
	EmailContactInformationKind = New Structure;
	EmailContactInformationKind.Insert("Type", Enums.ContactInformationTypes.Email);
	
	// Read data from address fields to attributes for editing.
	DeliveryAddressPresentation = ContactsManager.ContactInformationPresentation(Object.DeliveryAddress);
	DeliveryAddressComment   = ContactsManager.ContactInformationComment(Object.DeliveryAddress);
	
	EmailRepresentation = ContactsManager.ContactInformationPresentation(Object.Email);
EndProcedure

// Set a new comment for a delivery address.
// 
&AtServer
Procedure FillDeliveryAddressCommentServer()
	
	If IsBlankString(Object.DeliveryAddress) Then
		// Data initialization is required.
		Object.DeliveryAddress = ValuesOfContactInformationFieldsServer(DeliveryAddressPresentation, DeliveryAddressContactInformationKind, DeliveryAddressComment);
		Return;
	EndIf;
	
	ContactsManager.SetContactInformationComment(Object.DeliveryAddress, DeliveryAddressComment);
	
EndProcedure

&AtServerNoContext
Function ValuesOfContactInformationFieldsServer(Val Presentation, Val ContactInformationKind, Val Comment = Undefined)
	
	// Create a new instance by presentation.
	Result = ContactsManager.ContactsByPresentation(Presentation, ContactInformationKind);
	
	Return Result;
EndFunction

// End StandardSubsystems.ContactInformation

// StandardSubsystems.AccountingAudit

&AtClient
Procedure Attachable_OpenIssuesReport(ItemOrCommand, Var_URL, StandardProcessing)
	AccountingAuditClient.OpenObjectIssuesReport(ThisObject, Object.Ref, StandardProcessing);
EndProcedure

// End StandardSubsystems.AccountingAudit

// StandardSubsystems.MessagesTemplates

&AtClient
Procedure AfterTemplateChoice(Template, AdditionalParameters) Export
	If Template <> Undefined Then
		Object.MessageTemplate = Template;
		Modified = True;
	EndIf;
EndProcedure

// End StandardSubsystems.MessagesTemplates


#EndRegion
