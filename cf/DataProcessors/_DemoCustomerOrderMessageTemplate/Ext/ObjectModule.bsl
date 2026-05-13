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

// Returns info about an external data processor.
//
// Returns:
//   See AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo
//
Function ExternalDataProcessorInfo() Export
	
	RegistrationParameters = New Structure;
	
	RegistrationParameters.Insert("Kind", "MessageTemplate");
	RegistrationParameters.Insert("Version", "2.3.3.50");
	RegistrationParameters.Insert("Purpose", New Array);
	RegistrationParameters.Insert("Description", NStr("ru = 'Демо: Шаблон сообщения по изменившемуся статусу документа ""Демо: Заказ покупателя""';
														|en = 'Demo: Message template by changed status of the Demo: Sales order document';"));
	RegistrationParameters.Insert("SafeMode", True);
	RegistrationParameters.Insert("Information", NStr("ru = 'Данная обработка загружает шаблон сообщения по изменившемуся статусу документа ""Демо: Заказ покупателя"". Для доступа к шаблонам сообщений откройте раздел ""Интегрируемые подсистемы (часть 2)"" и перейдите к списку ""Шаблоны сообщений"".';
													|en = 'This data processor imports message template by changed status of the ""Demo: Sales order"" document. To get access to message templates, open the ""Integrated subsystems (part 2)"" section and go to the ""Message templates"" list.';"));
	RegistrationParameters.Insert("SSLVersion", "2.1.2.1");
	
	RegistrationParameters.Insert("Commands", New ValueTable);
	
	Return RegistrationParameters;
	
EndFunction

// Returns template parameters.
// 
// Returns:
//   See MessageTemplates.ParametersTable
//
Function TemplateParameters() Export
	
	TemplateParameters = MessageTemplates.ParametersTable();
	
	MessageTemplatesClientServer.AddTemplateParameter(
	                        TemplateParameters,
	                        "StringTypeParameter",
	                        New TypeDescription("String",, New StringQualifiers(50, AllowedLength.Variable)),
	                        False,
	                        NStr("ru = 'Дополнительная информация';
								|en = 'Additional details';"));
	
	MessageTemplatesClientServer.AddTemplateParameter(
	                        TemplateParameters, 
	                        NStr("ru = 'Демо: Заказ покупателя';
								|en = 'Demo: Sales order';"),
	                        New TypeDescription("DocumentRef._DemoSalesOrder"),
	                        False,
	                        NStr("ru = 'Укажите заказ клиента';
								|en = 'Select a sales order';"));
	
	Return TemplateParameters;
	
EndFunction

// Returns a data structure to display in the message template.
//
// Returns:
//  Structure:
//   * Description - String
//   * TemplateParameters - See TemplateParameters
//   * InputOnBasisParameterTypeFullName - String
//   * ForInputOnBasis - Boolean
//   * EmailTextType - EnumRef.EmailEditingMethods
//   * HTMLEmailTemplateText - String
//   * EmailSubject - String
//   * CommonTemplate - Boolean
//   * ForSMSMessages - Boolean
//   * SMSTemplateText - String
//   * ForEmails - Boolean
//
Function DataStructureToDisplayInTemplate() Export
	
	StructureOfData = New Structure;
	
	StructureOfData.Insert("Description",                           NStr("ru = 'Оповещение при изменившемся статусе заказа';
																			|en = 'A notification on changed order status';"));
	StructureOfData.Insert("TemplateParameters",                       TemplateParameters());
	StructureOfData.Insert("ForEmails",        True);
	StructureOfData.Insert("SMSTemplateText",                        "");
	StructureOfData.Insert("ForSMSMessages",                     False);
	StructureOfData.Insert("CommonTemplate",                            False);
	StructureOfData.Insert("EmailSubject",                             EmailTextForTemplate());
	StructureOfData.Insert("HTMLEmailTemplateText",                 HTMLEmailTextForTemplate());
	StructureOfData.Insert("EmailTextType",                        Enums.EmailEditingMethods.HTML);
	StructureOfData.Insert("ForInputOnBasis",        True);
	StructureOfData.Insert("InputOnBasisParameterTypeFullName", "Document._DemoSalesOrder");
	
	Return StructureOfData;
	
EndFunction

// Returns a data structure for initializing the "Template-based message" data processor.
//
// Parameters:
//  ForEmail - Boolean - If True, the template is used for email creation.
//
// Returns:
//  Structure:
//   * TemplateParameters - See TemplateParameters
//   * EmailTextType - EnumRef.EmailEditingMethods
//   * ForSMSMessages - Boolean
//   * ForEmails - Boolean
//
Function DataStructureForMessageByTemplate(ForEmail) Export
	
	StructureOfData = New Structure;
	
	StructureOfData.Insert("TemplateParameters",                TemplateParameters());
	StructureOfData.Insert("EmailTextType",                 Enums.EmailEditingMethods.HTML);
	StructureOfData.Insert("ForEmails", ForEmail);
	StructureOfData.Insert("ForSMSMessages",              Not ForEmail);
	
	Return StructureOfData;
	
EndFunction

// Generates a message from template.
//
// Parameters:
//  TemplateParametersStructure - Structure - Template parameters.
// 
// Returns:
//  Structure:
//    * SMSMessageText - String
//    * EmailSubject - String
//    * EmailText - String
//    * AttachmentsStructure - Structure
//   * HTMLEmailText - String
//
Function GenerateMessageUsingTemplate(TemplateParametersStructure) Export
	
	MessageStructure = MessageTemplatesClientServer.InitializeMessageStructure();
	
	Message = TextAndSubjectOfHTMLEmailForSending(TemplateParametersStructure);
	MessageStructure.HTMLEmailText   = Message.HTMLEmailText;
	MessageStructure.EmailSubject        = Message.EmailSubject;
	MessageStructure.AttachmentsStructure = Message.AttachmentsStructure;
	
	Return MessageStructure;
	
EndFunction

// Creates a list of email recipients.
// 
// Parameters:
//  TemplateParametersStructure - Structure - Template parameters.
//  StandardProcessing - Boolean - Flag indicating whether the standard data processor is used. Cleared in the function.
// 
// Returns:
//  Array
//
Function DataStructureRecipients(TemplateParametersStructure, StandardProcessing) Export
	
	Result = New Array;
	StandardProcessing = False;
	If TemplateParametersStructure.Property("_DemoSalesOrder") And Not TemplateParametersStructure._DemoSalesOrder.IsEmpty() Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	DemoOrderOfTheBuyerPartnersAndContactPersons.ContactPerson
		|FROM
		|	Document._DemoSalesOrder.PartnersAndContactPersons AS DemoOrderOfTheBuyerPartnersAndContactPersons
		|WHERE
		|	DemoOrderOfTheBuyerPartnersAndContactPersons.Ref = &BuyerSOrder";
		
		Query.SetParameter("BuyerSOrder", TemplateParametersStructure._DemoSalesOrder);
		QueryResult = Query.Execute().Unload().UnloadColumn("ContactPerson");
		
		If QueryResult.Count() > 0 Then
			Recipients = ContactsManager.ObjectsContactInformation(QueryResult,
				Enums.ContactInformationTypes.Email,, CurrentSessionDate());
			
			For Each Recipient In Recipients Do
				NewRecipient = RecipientStructure();
				NewRecipient.Address = Recipient.Presentation;
				NewRecipient.Presentation = String(Recipient.Object) + " <" + Recipient.Presentation + ">";
				NewRecipient.ContactInformationSource = Recipient.Object;
				Result.Add(NewRecipient);
			EndDo;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Function TextAndSubjectOfHTMLEmailForSending(TemplateParametersStructure)
	
	HTMLEmailText = GetTemplate("EmailTemplateHTML").GetText();
	EmailSubject      = "";

	If TemplateParametersStructure.Property("_DemoSalesOrder") And Not TemplateParametersStructure._DemoSalesOrder.IsEmpty() Then
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	DemoSalesOrder.Number,
		|	DemoSalesOrder.Date,
		|	DemoSalesOrder.OrderStatus,
		|	DemoSalesOrder.Counterparty AS PartnerPresentation_
		|FROM
		|	Document._DemoSalesOrder AS DemoSalesOrder
		|WHERE
		|	DemoSalesOrder.Ref = &BuyerSOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	_DemoInvoiceForPaymentToTheBuyerOfGoods.Products AS Products,
		|	_DemoInvoiceForPaymentToTheBuyerOfGoods.Characteristic AS Characteristic,
		|	_DemoInvoiceForPaymentToTheBuyerOfGoods.Count AS Count,
		|	_DemoInvoiceForPaymentToTheBuyerOfGoods.Price AS Price,
		|	_DemoInvoiceForPaymentToTheBuyerOfGoods.Sum AS Sum,
		|	_DemoInvoiceForPaymentToTheBuyerOfGoods.Total AS Total,
		|	_DemoInvoiceForPaymentToTheBuyerOfGoods.VATAmount AS VATAmount
		|FROM
		|	Document._DemoSalesOrder.ProformaInvoices AS _DemoOrderOfTheBuyerOfTheInvoiceForPayment
		|		LEFT JOIN Document._DemoCustomerProformaInvoice.Goods AS _DemoInvoiceForPaymentToTheBuyerOfGoods
		|		ON (_DemoOrderOfTheBuyerOfTheInvoiceForPayment.Account = _DemoInvoiceForPaymentToTheBuyerOfGoods.Ref)
		|WHERE
		|	_DemoOrderOfTheBuyerOfTheInvoiceForPayment.Ref = &BuyerSOrder";
		
		Query.SetParameter("BuyerSOrder", TemplateParametersStructure._DemoSalesOrder);
		
		QueryResult = Query.ExecuteBatch();
		
		If Not QueryResult[0].IsEmpty() Then
			
			Selection = QueryResult[0].Select();
			Selection.Next();
			
			HTMLEmailText = StrReplace(HTMLEmailText, "[%1]", Selection.PartnerPresentation_);
			
			OrderPresentation =  StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '№ %1 от %2';
					|en = '#%1, %2';"), Selection.Number, Format(Selection.Number , "DLF=DD"));
			HTMLEmailText     = StrReplace(HTMLEmailText, "[%2]", OrderPresentation);
			EmailSubject          = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Изменение статуса по заказу %1';
																								|en = 'Status change by the %1 order';"), OrderPresentation);
			
			HTMLEmailText = StrReplace(HTMLEmailText, "[%3]", Selection.OrderStatus);
			HTMLEmailText = StrReplace(HTMLEmailText, "[%4]", GenerateOrderGoodsTable(QueryResult[1]));
			
			AttachmentsStructure = New Structure;
			AttachmentsStructure.Insert("Logo", New Picture(GetTemplate("Logo")));
			HTMLEmailText = StrReplace(HTMLEmailText, "[%6]", "<img src=""Logo""></img>");
			
		EndIf;
		
	EndIf;
	
	If TemplateParametersStructure.Property("StringTypeParameter") And Not IsBlankString(TemplateParametersStructure.StringTypeParameter) Then
		HTMLEmailText = StrReplace(HTMLEmailText, "[%5]", TemplateParametersStructure.StringTypeParameter);
	EndIf;
	
	Return New Structure("EmailSubject, HTMLEmailText, AttachmentsStructure", EmailSubject, HTMLEmailText, AttachmentsStructure);
	
EndFunction

Function TemplateParametersPresentation()
	
	Parameters = New Map;
	Parameters.Insert("%1", NStr("ru = 'Представление партнера';
									|en = 'Partner presentation';"));
	Parameters.Insert("%2", NStr("ru = 'Представление заказа';
									|en = 'Order presentation';"));
	Parameters.Insert("%3", NStr("ru = 'Статус заказа';
									|en = 'Order status';"));
	Parameters.Insert("%4", NStr("ru = 'Таблица номенклатуры';
									|en = 'Product table';"));
	Parameters.Insert("%5", NStr("ru = 'Дополнительная информация';
									|en = 'Additional information';"));
	Parameters.Insert("%6", NStr("ru = 'Логотип';
									|en = 'Logo';"));
	
	Return Parameters;
	
EndFunction

Function GenerateOrderGoodsTable(QueryResult)

	TableText = "";
	Template = "<FONT face=Terminal>|%1|%2|%3|%4|</FONT><BR>";
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		TableText = TableText + StringFunctionsClientServer.SubstituteParametersToString(Template,
			StringFunctionsClientServer.SupplementString(Selection.Products, 46, " ", "Right"),
			StringFunctionsClientServer.SupplementString(Selection.Count,   12, " ", "Left"),
			StringFunctionsClientServer.SupplementString(Selection.Price,          9, " ", "Left"),
			StringFunctionsClientServer.SupplementString(Selection.VATAmount,     13, " ", "Left"));
		
	EndDo;
	
	TableText = StrReplace(TableText, " ", "&nbsp;");
	
	Return TableText;

EndFunction

Function EmailTextForTemplate()
	
	Text = NStr("ru = 'Изменение статуса по заказу [%2]';
				|en = 'Order status changed [%2]';");
	Return FillTemplateWithParametersPresentation(Text);
	
EndFunction

Function HTMLEmailTextForTemplate()
	
	HTMLEmailText = GetTemplate("EmailTemplateHTML").GetText();
	HTMLEmailText = FillTemplateWithParametersPresentation(HTMLEmailText);
	TableText = "<FONT face=Terminal>"
		+ StrReplace(StringFunctionsClientServer.SupplementString("&ProductsTable", 50, " ", "Left")," ","&nbsp;")
		+ "</FONT><BR>";
	
	Return StrReplace(HTMLEmailText, "&ProductsTable", TableText);
	
EndFunction

Function FillTemplateWithParametersPresentation(TemplateText)
	
	TemplateParameters= TemplateParametersPresentation();
	For Each TemplateParameter In TemplateParameters Do
		TemplateText = StrReplace(TemplateText, TemplateParameter.Key, TemplateParameter.Value);
	EndDo;
	
	Return TemplateText;
	
EndFunction

Function RecipientStructure()
		
	RecipientStructure = New Structure;
	RecipientStructure.Insert("Address",                        "");
	RecipientStructure.Insert("Presentation",                "");
	RecipientStructure.Insert("ContactInformationSource", "");
	RecipientStructure.Insert("EmailAddressKind",           "");
	RecipientStructure.Insert("Explanation",                    "");
	RecipientStructure.Insert("SourceObject",               "");
	Return RecipientStructure;
	
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf