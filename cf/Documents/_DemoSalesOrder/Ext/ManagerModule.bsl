///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ToDoList

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Not AccessRight("Edit", Metadata.Documents._DemoSalesOrder) Then
		Return;
	EndIf;
	
	SalesOrdersCount = SalesOrdersCount();
	
	FilterList = New ValueList;
	FilterList.Add(Enums._DemoCustomerOrderStatuses.NotApproved);
	FilterList.Add(Enums._DemoCustomerOrderStatuses.Approved);
	
	PickingByStatuses = New Structure("OrderStatus", FilterList);
	
	SalesOrdersID = "BuyerSOrders";
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = SalesOrdersID;
	ToDoItem.HasToDoItems       = SalesOrdersCount.Total > 0;
	ToDoItem.Presentation  = NStr("ru = 'Заказы покупателя';
								|en = 'Sales orders';");
	ToDoItem.Count     = SalesOrdersCount.Total;
	ToDoItem.Form          = "Document._DemoSalesOrder.ListForm";
	ToDoItem.FormParameters = New Structure("Filter", PickingByStatuses);
	ToDoItem.Owner       = Metadata.Subsystems._DemoOrganizer;
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "SalesOrdersNotApproved";
	ToDoItem.HasToDoItems       = SalesOrdersCount.NotApproved > 0;
	ToDoItem.Important         = True;
	ToDoItem.Presentation  = NStr("ru = 'Не согласовано';
								|en = 'Not approved';");
	ToDoItem.Count     = SalesOrdersCount.NotApproved;
	ToDoItem.Owner       = SalesOrdersID;
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "SalesOrdersApproved";
	ToDoItem.HasToDoItems       = SalesOrdersCount.Approved > 0;
	ToDoItem.Presentation  = NStr("ru = 'Согласовано';
								|en = 'Consistent';");
	ToDoItem.Count     = SalesOrdersCount.Approved;
	ToDoItem.Owner       = SalesOrdersID;
	
EndProcedure

// End StandardSubsystems.ToDoList

// StandardSubsystems.MessagesTemplates

// Called when preparing message templates. Overrides the list of attributes and attachments.
//
// Parameters:
//  Attributes - See MessageTemplatesOverridable.OnPrepareMessageTemplate.Attributes
//  Attachments  - See MessageTemplatesOverridable.OnPrepareMessageTemplate.Attachments
//  AdditionalParameters - Structure - Additional information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating a message from a template. Populates values in attributes and attachments.
//
// Parameters:
//  Message - Structure:
//    * AttributesValues - Map of KeyAndValue - List of template's attributes:
//      ** Key     - String - Template's attribute name.
//      ** Value - String - Template's filling value.
//    * CommonAttributesValues - Map of KeyAndValue - List of template's common attributes:
//      ** Key     - String - Template's attribute name.
//      ** Value - String - Template's filling value.
//    * Attachments - Map of KeyAndValue:
//      ** Key     - String - Template's attachment name.
//      ** Value - BinaryData
//                  - String - binary data or an address in a temporary storage of the attachment.
//  MessageSubject - AnyRef - The reference to a data source object.
//  AdditionalParameters - Structure -  Additional information about a message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Populates a list of recipients (in case the message is generated from a template).
//
// Parameters:
//   SMSMessageRecipients - ValueTable:
//     * PhoneNumber - String - Recipient's phone number.
//     * Presentation - String - Recipient presentation.
//     * Contact       - Arbitrary - The contact this phone number belongs to.
//  MessageSubject - AnyRef - The reference to a data source object.
//                   - Structure  - Structure that describes template parameters:
//    * SubjectOf               - AnyRef - The reference to a data source object.
//    * MessageKind - String - Message type: Email or SMSMessage.
//    * ArbitraryParameters - Map - List of arbitrary parameters.
//    * SendImmediately - Boolean - Flag indicating whether the message must be sent immediately.
//    * MessageParameters - Structure - Additional message parameters.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	MessageTemplates.FillRecipients(SMSMessageRecipients, MessageSubject, "Counterparty", Enums.ContactInformationTypes.Phone);
EndProcedure

// Populates a list of recipients (in case the message is generated from a template).
//
// Parameters:
//   EmailRecipients - ValueTable - List of message recipients:
//     * SendingOption - String - Messaging options: "Whom" (To), "Copy" (CC), "HiddenCopy" (BCC), and "ReplyTo".
//     * Address           - String - Recipient's email address.
//     * Presentation   - String - Recipient presentation.
//     * Contact         - Arbitrary - The contact this email address belongs to.
//  MessageSubject - AnyRef - The reference to a data source object.
//                   - Structure  - Structure that describes template parameters:
//    * SubjectOf               - AnyRef - The reference to a data source object.
//    * MessageKind - String - Message type: Email or SMSMessage.
//    * ArbitraryParameters - Map - List of arbitrary parameters.
//    * SendImmediately - Boolean - Flag indicating whether the message must be sent immediately.
//    * MessageParameters - Structure - Additional message parameters.
//    * ConvertHTMLForFormattedDocument - Boolean - Flag indicating whether the HTML text must be converted.
//             Applicable to messages containing images.
//             Required due to the specifics of image output in formatted documents. 
//    * Account - CatalogRef.EmailAccounts - Sender's email account.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

// End StandardSubsystems.MessagesTemplates

// StandardSubsystems.BatchEditObjects

// Returns the object attributes that are not recommended to be edited
// using a bulk attribute modification data processor.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	Result = New Array;
	
	Result.Add("DeliveryAddress");
	Result.Add("DeliveryCountry");
	Result.Add("DeliveryState");
	Result.Add("DestinationCity");
	
	Result.Add("Email");
	Result.Add("ServerDomainName");
	
	Result.Add("PartnersAndContactPersons.TabularSectionRowID");
	Result.Add("ContactInformation.*");
	
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.ObjectAttributesLock

// Returns:
//   See ObjectAttributesLockOverridable.OnDefineLockedAttributes.LockedAttributes.
//
Function GetObjectAttributesToLock() Export
	
	AttributesToLock = New Array;
	
	AttributesToLock.Add("Organization");
	AttributesToLock.Add("Partner");
	AttributesToLock.Add("Counterparty");
	AttributesToLock.Add("Contract");
	AttributesToLock.Add("ProformaInvoices");
	
	Return AttributesToLock;
	
EndFunction

// End StandardSubsystems.ObjectAttributesLock

// StandardSubsystems.Interactions

// Get a partner and contact persons of the transaction.
//
// Parameters:
//  Ref  - DocumentRef._DemoSalesOrder - Document whose contacts are to be received.
//
// Returns:
//   Array   - an array that contains document contacts.
// 
Function GetContacts(Ref) Export
	
	If Not ValueIsFilled(Ref) Then
		Return New Array;
	EndIf;
	
	Query = New Query;
	Query.Text = TheTextOfTheRequestForContacts();
	Query.SetParameter("SubjectOf", Ref);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return New Array;
	EndIf;

	Return QueryResult.Unload().UnloadColumn("Contact");
	
EndFunction

// End StandardSubsystems.Interactions

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Partner)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.AttachableCommands

// Defines the list of generation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses._DemoJobWithRoleAddressing.AddGenerateCommand(GenerationCommands);
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Intended for use by the AddGenerationCommands procedure in other object manager modules.
// Adds this object to the list of generation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - Details of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents._DemoSalesOrder);
	
EndFunction

// End StandardSubsystems.AttachableCommands

// StandardSubsystems.Print

// Overrides object's print settings.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// Populates a list of print commands.
// 
// Parameters:
//  PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "SalesOrder";
	PrintCommand.Presentation = NStr("en = 'Sales order';");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.PrintManager = "DataProcessor.PrintSalesOrder";	
	PrintCommand.Order = 1;

	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "DeliveryOrder";
	PrintCommand.Presentation = NStr("en = 'Delivery order';");
	PrintCommand.CheckPostingBeforePrint = True;	
	StartDate = Date(2025, 1, 1);
	
	PrintManagement.AddCommandVisibilityCondition(
		PrintCommand,
		"Date",
		StartDate,
		ComparisonType.GreaterOrEqual
	);
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "DataProcessor.PrintSalesOrder.SalesOrder,DataProcessor.PrintSalesOrder.SalesOrder,DeliveryOrder";
	PrintCommand.Presentation = NStr("en = 'Document set';");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.Order = 90;
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "Document._DemoSalesOrder.PF_MXL_SalesOrderDetails";
	PrintCommand.Presentation = NStr("en = 'Sales order details';");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.PrintManager = "PrintManagement";
		
EndProcedure

// Generates print forms.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	// Print a sales order
	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "DeliveryOrder");
	If PrintForm <> Undefined Then
		PrintForm.SpreadsheetDocument = PrintDeliveryOrder(ObjectsArray, PrintObjects);
		PrintForm.TemplateSynonym = NStr("en = 'Delivery order'");
		PrintForm.FullTemplatePath = "Document._DemoSalesOrder.PF_MXL_DeliveryOrder";
	EndIf;
	
EndProcedure

Function PrintDeliveryOrder(RefsToObjects, PrintObjects) Export

	Spreadsheet = New SpreadsheetDocument;
	Spreadsheet.PrintParametersKey = "PrintForm_DocumentSalesOrderDeliveryOrder";
	
	Template = PrintManagement.PrintFormTemplate("Document._DemoSalesOrder.PF_MXL_DeliveryOrder");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	_DemoSalesOrder.Ref AS Ref,
	|	_DemoSalesOrder.ContactPerson,
	|	_DemoSalesOrder.Date,
	|	_DemoSalesOrder.DeliveryAddress,
	|	_DemoSalesOrder.DeliveryAddressString,
	|	_DemoSalesOrder.DeliveryCountry,
	|	_DemoSalesOrder.DeliveryDate,
	|	_DemoSalesOrder.DeliveryState,
	|	_DemoSalesOrder.DestinationCity,
	|	_DemoSalesOrder.EmployeeResponsible,
	|	_DemoSalesOrder.Number
	|FROM
	|	Document._DemoSalesOrder AS _DemoSalesOrder
	|WHERE
	|	_DemoSalesOrder.Ref IN (&Ref)";
	Query.Parameters.Insert("Ref", RefsToObjects);
	
	Selection = Query.Execute().Select();

	AreaCaption = Template.GetArea("Caption");
	Header = Template.GetArea("Header");
	Footer = Template.GetArea("Footer");

	Spreadsheet.Clear();

	InsertPageBreak = False;
	While Selection.Next() Do
		If InsertPageBreak Then
			Spreadsheet.PutHorizontalPageBreak();
		EndIf;
		RowNumberStart = Spreadsheet.TableHeight + 1;

		AreaCaption.Parameters.Fill(Selection);
		Spreadsheet.Put(AreaCaption);

		Header.Parameters.Fill(Selection);
		Spreadsheet.Put(Header, Selection.Level());

		Footer.Parameters.Fill(Selection);
		Spreadsheet.Put(Footer);

		InsertPageBreak = True;

		PrintManagement.SetDocumentPrintArea(Spreadsheet, RowNumberStart, PrintObjects, Selection.Ref);
	EndDo;

	Return Spreadsheet;
	
EndFunction

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#Region Internal

// Returns a text of the query by interaction contacts contained in the document.
//
// Returns:
//   String
//
Function TheTextOfTheRequestForContacts(IsQueryFragment = False) Export
	
	QueryText = "
		|SELECT DISTINCT
		|	_DemoSalesOrder.Partner AS Contact 
		|FROM
		|	Document._DemoSalesOrder AS _DemoSalesOrder
		|WHERE
		|	_DemoSalesOrder.Ref = &SubjectOf
		|	AND (NOT _DemoSalesOrder.Partner = VALUE(Catalog._DemoPartners.EmptyRef))
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	DemoOrderOfTheBuyerPartnersAndContactPersons.Partner
		|FROM
		|	Document._DemoSalesOrder.PartnersAndContactPersons AS DemoOrderOfTheBuyerPartnersAndContactPersons
		|WHERE
		|	DemoOrderOfTheBuyerPartnersAndContactPersons.Ref = &SubjectOf
		|	AND (NOT DemoOrderOfTheBuyerPartnersAndContactPersons.Partner = VALUE(Catalog._DemoPartners.EmptyRef))
		|	AND DemoOrderOfTheBuyerPartnersAndContactPersons.ContactPerson = VALUE(Catalog._DemoPartnersContactPersons.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT
		|	DemoOrderOfTheBuyerPartnersAndContactPersons.ContactPerson
		|FROM
		|	Document._DemoSalesOrder.PartnersAndContactPersons AS DemoOrderOfTheBuyerPartnersAndContactPersons
		|WHERE
		|	DemoOrderOfTheBuyerPartnersAndContactPersons.Ref = &SubjectOf
		|	AND (NOT DemoOrderOfTheBuyerPartnersAndContactPersons.ContactPerson = VALUE(Catalog._DemoPartnersContactPersons.EmptyRef))";
	
	If IsQueryFragment Then
		QueryText = "
			| UNION ALL
			|" + QueryText;
	EndIf;
		
	Return QueryText;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Update handlers.

// Registers the objects to be updated to the latest version
// in the InfobaseUpdate exchange plan.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	// Parameters of data selection for multithread update.
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document._DemoSalesOrder";
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	// Simulating an error: Verify the correct handling of the scenario when the "SelectionParameters" property is invalid.
	// Start the simulation.
	SimulateError = Common.CommonSettingsStorageLoad("IBUpdate", "SimulateErrorInSelectionParameters", False);
	If SimulateError Then
		SelectionParameters.SelectionMethod = "InvalidSelectionOption";
		Common.CommonSettingsStorageSave("IBUpdate", "SimulateErrorInSelectionParameters", False);
	EndIf;
	// Error simulation end.
	
	UpToDateData = Parameters.UpToDateData;
	UpToDateData.FilterField = "Date";
	UpToDateData.ComparisonType = ComparisonType.Greater;
	UpToDateData.Value = Date("20220712");
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	_DemoSalesOrder.Ref
		|FROM
		|	Document._DemoSalesOrder AS _DemoSalesOrder
		|WHERE
		|	_DemoSalesOrder.OrderStatus = &EmptyRef
		|
		|ORDER BY
		|	_DemoSalesOrder.Date DESC";
	Query.Parameters.Insert("EmptyRef", Enums._DemoCustomerOrderStatuses.EmptyRef());
	
	Result = Query.Execute().Unload();
	ReferencesArrray = Result.UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, ReferencesArrray);
	
EndProcedure

// Populate the new OrderStatus attribute value in the _DemoSalesOrder document.
// 
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	// Simulating an error: Infinite loop in the deferred handler.
	// Start the simulation.
	SimulateError = Common.CommonSettingsStorageLoad("IBUpdate", "SimuateErrorOnDeferredParallelUpdate", False);
	If SimulateError Then
		Parameters.ProcessingCompleted = False;
		
		If Not Parameters.Property("StartsCount") Then
			Parameters.Insert("StartsCount", 1);
		Else
			Parameters.StartsCount = Parameters.StartsCount + 1;
		EndIf;
		
		If Parameters.StartsCount = 16 Then
			Common.CommonSettingsStorageSave("IBUpdate", "SimuateErrorOnDeferredParallelUpdate", False);
		EndIf;
		
		// If there's data for processing, the infinite loop is emulated with a transaction rollback after the data is written.
		If InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Document._DemoSalesOrder") Then
			Return;
		EndIf;
	EndIf;
	
	
	SimulateProblemsWithDataAndHandler = Common.CommonSettingsStorageLoad("IBUpdate", "SimulateProblemsWithDataAndHandler", False);
	PauseWhenExecutingHandler = Common.CommonSettingsStorageLoad("IBUpdate", "PauseWhenExecutingHandler", 0);
	
	If PauseWhenExecutingHandler <> 0 Then
		Common.CommonSettingsStorageSave("IBUpdate", "PauseWhenExecutingHandler", 0);
	EndIf;
	If SimulateProblemsWithDataAndHandler Then
		Common.CommonSettingsStorageSave("IBUpdate", "SimulateProblemsWithDataAndHandler", False);
	EndIf;
	
	// Error simulation end.
	
	// Data selection for a multithread update.
	BuyerSOrders = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	
	For Each BuyerSOrder In BuyerSOrders Do
		RepresentationOfTheReference = String(BuyerSOrder.Ref);
		Try
			
			FillSalesOrderStatus(BuyerSOrder, SimulateError);
			ObjectsProcessed = ObjectsProcessed + 1;
			
			// Error simulation start.
			If SimulateProblemsWithDataAndHandler
				And Not Parameters.Property("TestErrorsAdded") Then
				Comment = NStr("ru = 'Тестовая ошибка для проверки работы отложенного обновления данных.';
									|en = 'Test error to check the deferred data update.';");
				InfobaseUpdate.WriteEventToRegistrationLog(Comment);
				
				
				Refinement = NStr("ru = 'Не удалось обработать документ из-за некорректного значения реквизита %1.';
								|en = 'Couldn''t process the document. Reason: Attribute ""%1"" has invalid value.';");
				Refinement = StringFunctionsClientServer.SubstituteParametersToString(Refinement, "OrderStatus");
				
				InfobaseUpdate.FileIssueWithData(BuyerSOrder.Ref, Refinement);
				Parameters.Insert("TestErrorsAdded");
			EndIf;
			
			If PauseWhenExecutingHandler <> 0 Then
				// ACC:277-off for testing purposes.
				InfobaseUpdateInternal.Pause(PauseWhenExecutingHandler);
				// ACC:277-on
				PauseWhenExecutingHandler = 0;
			EndIf;
			// Error simulation end.
			
		Except
			// If an order is failed to process, try again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			InfobaseUpdate.WriteErrorToEventLog(
				BuyerSOrder.Ref,
				RepresentationOfTheReference,
				ErrorInfo());
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Document._DemoSalesOrder");
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось обработать некоторые заказы покупателей (пропущены): %1';
				|en = 'Couldn''t process (skipped) some sales orders: %1';"), 
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Documents._DemoSalesOrder,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Обработана очередная порция заказов покупателей: %1';
					|en = 'Yet another batch of sales orders is processed: %1';"),
				ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Populates the value of the new OrderStatus attribute in the passed document.
//
Procedure FillSalesOrderStatus(BuyerSOrder, SimulateError)
	
	BeginTransaction();
	Try
	
		// Lock the object (to ensure that it won't be edited in other sessions).
		Block = New DataLock;
		LockItem = Block.Add("Document._DemoSalesOrder");
		LockItem.SetValue("Ref", BuyerSOrder.Ref);
		Block.Lock();
		
		DocumentObject = BuyerSOrder.Ref.GetObject();
		If DocumentObject.OrderStatus <> Enums._DemoCustomerOrderStatuses.EmptyRef() Then
			InfobaseUpdate.MarkProcessingCompletion(BuyerSOrder.Ref);
			CommitTransaction();
			Return;
		EndIf;
		
		// Process object.
		If Not DocumentObject.DeleteOrderClosed And Not DocumentObject.Posted Then
			DocumentObject.OrderStatus = Enums._DemoCustomerOrderStatuses.NotApproved;
		ElsIf Not DocumentObject.DeleteOrderClosed And DocumentObject.Posted Then
			DocumentObject.OrderStatus = Enums._DemoCustomerOrderStatuses.Approved;
		Else
			DocumentObject.OrderStatus = Enums._DemoCustomerOrderStatuses.Closed;
		EndIf;
		
		// Write processed object.
		InfobaseUpdate.WriteData(DocumentObject);
		
		// If an error emulation is enabled, the infinite loop is emulated with a transaction rollback.
		If SimulateError Then
			RollbackTransaction();
		Else
			CommitTransaction();
		EndIf;
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Function SalesOrdersCount()
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	COUNT(_DemoSalesOrder.Ref) AS Count
	|FROM
	|	Document._DemoSalesOrder AS _DemoSalesOrder
	|WHERE
	|	_DemoSalesOrder.OrderStatus <> &OrderClosed
	|
	|UNION ALL
	|
	|SELECT
	|	COUNT(_DemoSalesOrder.Ref)
	|FROM
	|	Document._DemoSalesOrder AS _DemoSalesOrder
	|WHERE
	|	_DemoSalesOrder.OrderStatus = &OrderApproved
	|
	|UNION ALL
	|
	|SELECT
	|	COUNT(_DemoSalesOrder.Ref)
	|FROM
	|	Document._DemoSalesOrder AS _DemoSalesOrder
	|WHERE
	|	_DemoSalesOrder.OrderStatus = &OrderNotApproved";
	
	Query.SetParameter("OrderApproved", Enums._DemoCustomerOrderStatuses.Approved);
	Query.SetParameter("OrderClosed", Enums._DemoCustomerOrderStatuses.Closed);
	Query.SetParameter("OrderNotApproved", Enums._DemoCustomerOrderStatuses.NotApproved);
	
	QueryResult = Query.Execute().Unload();
	
	Result = New Structure("Total, Approved, NotApproved");
	Result.Total = QueryResult[0].Count;
	Result.Approved = QueryResult[1].Count;
	Result.NotApproved = QueryResult[2].Count;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf