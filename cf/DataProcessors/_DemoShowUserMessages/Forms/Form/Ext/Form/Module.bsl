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
	
	Object.ObjectAttribute = NStr("ru = 'Тестовое значение реквизита';
									|en = 'Test attribute value';");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShowMessageForFormFieldLinkedToObjectAttributeAtClient(Command)
	
	CommonClient.MessageToUser(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Пример сообщения, связанного с реквизитом объекта (%1).';
				|en = 'Sample of a message connected to an object attribute (%1).';"), "Object.ObjectAttribute"), ,
		"ObjectAttribute", "Object");
	
EndProcedure

&AtClient
Procedure ShowMessageForFormFieldLinkedToObjectAttributeAtServer(Command)
	
	ShowMessageForFormFieldLinkedToObjectAttributeServer();
	
EndProcedure

&AtClient
Procedure ViewCodeOptionOne(Command)
	
	OpenForm("DataProcessor._DemoShowUserMessages.Form.CodeExample",
		New Structure("CodeExample", "Common.MessageToUser(
		|	NStr(""ru = 'Sample messages related From1 attribute5 object_.'""),
		|	,
		|	""ObjectAttribute"",
		|	""Object"");"));
	
EndProcedure

&AtClient
Procedure ShowMessageForFormFieldLinkedToFormAttributeAtClient(Command)
	
	CommonClient.MessageToUser(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Пример сообщения, связанного с реквизитом формы (%1).';
				|en = 'Sample of a message connected to a form attribute (%1).';"), "FormAttribute"), ,
			"FormAttribute");
	
EndProcedure

&AtClient
Procedure ShowMessageForFormFieldLinkedToFormAttributeAtServer(Command)
	
	ShowMessageForFormFieldLinkedToFormAttributeServer();
	
EndProcedure

&AtClient
Procedure ViewCodeOptionTwo(Command)
	
	OpenForm("DataProcessor._DemoShowUserMessages.Form.CodeExample",
		New Structure("CodeExample", "Common.MessageToUser(
		|	NStr(""ru = 'Sample messages, related From1 attribute5 forms (FormAttribute).'""),
		|	,
		|	""FormAttribute"");"));
		
EndProcedure

&AtClient
Procedure ShowMessageAssociatedWithInfobaseObjectAttribute(Command)
	
	If Not ShowInfobaseObjectAttributeMessageServer() Then
		NotifyDescription = New NotifyDescription("ShowMessageAssociatedWithInfobaseObjectAttributeCompletion", ThisObject);
		ShowMessageBox(NotifyDescription, NStr("ru = 'Для выполнения теста предварительно создайте хотя бы один документ ""Демо: Счет на оплату покупателю"".';
														|en = 'To run a test, create at least one ""Demo: Sales proforma invoice document"" in advance.';"));
	EndIf;
	
EndProcedure

&AtClient
Procedure ViewCodeOptionThree(Command)
	
	OpenForm("DataProcessor._DemoShowUserMessages.Form.CodeExample",
		New Structure("CodeExample", "Common.MessageToUser(
		|	NStr(""ru = 'Sample messages, related From1 attribute5 ""EmployeeResponsible"" document_ ""Demo: Account to1 payment_0 tobuyer"" 
				|(object information bases).'""),
		|	Ref.GetObject(),
		|	""EmployeeResponsible"");"));
	
EndProcedure

&AtClient
Procedure ShowMessageAssociatedWithInfobaseObjectAttributeByRefAtClient(Command)
	
	Var ResultIsEmpty;
	
	Ref = GetRef(ResultIsEmpty);
	
	If ResultIsEmpty Then
		ShowMessageBox(, NStr("ru = 'Не найдено доступных объектов.';
										|en = 'Available objects are not found.';"));
		Return;
	EndIf;
	
	CommonClient.MessageToUser(
		NStr("ru = 'Пример сообщения, связанного с реквизитом ""Ответственный"" документа ""Демо: Счет на оплату покупателю""
			| (объект информационной базы).';
			|en = 'Sample of a message connected to the ""Person responsible"" attribute of the ""Demo: Sales proforma invoice"" document
			|(an infobase object).';"),
		Ref,
		"EmployeeResponsible");
	
	Return;
	
EndProcedure

&AtClient
Procedure ShowMessageAssociatedWithInfobaseObjectAttributeByRefAtServer(Command)
	
	If Not ShowMessageLinkedToInfobaseObjectAttributeByRefServer() Then
		NotifyDescription = New NotifyDescription("ShowMessageAssociatedWithInfobaseObjectAttributeByRefAtServerCompletion", ThisObject);
		ShowMessageBox(NotifyDescription, NStr("ru = 'Для выполнения теста предварительно создайте хотя бы один документ ""Демо: Счет на оплату покупателю"".';
														|en = 'To run a test, create at least one ""Demo: Sales proforma invoice document"" in advance.';"));
	EndIf;
	
EndProcedure

&AtClient
Procedure ViewCodeOptionFour(Command)
	
	OpenForm("DataProcessor._DemoShowUserMessages.Form.CodeExample",
		New Structure("CodeExample", "Common.MessageToUser(
		|	NStr(""ru = 'Test1 message turn oferror, related1 From1 attribute5 ""EmployeeResponsible"" document_ ""Demo: Account to1 payment_0 tobuyer""
				|(ref to1 object).'""),
		|	Ref,
		|	""EmployeeResponsible"")"));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ShowMessageForFormFieldLinkedToObjectAttributeServer()
	
	Common.MessageToUser(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Пример сообщения, связанного с реквизитом объекта (%1).';
				|en = 'Sample of a message connected to an object attribute (%1).';"), "Object.ObjectAttribute"), ,
		"ObjectAttribute",
		"Object");
	
EndProcedure

&AtServer
Procedure ShowMessageForFormFieldLinkedToFormAttributeServer()
	
	Common.MessageToUser(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Пример сообщения, связанного с реквизитом формы (%1).';
				|en = 'Sample of a message connected to a form attribute (%1).';"), "FormAttribute"), ,
		"FormAttribute");
	
EndProcedure

&AtClient
Procedure ShowMessageAssociatedWithInfobaseObjectAttributeCompletion(AdditionalParameters) Export
	
	OpenForm("Document._DemoCustomerProformaInvoice.ListForm");
	
EndProcedure

&AtServer
Function ShowInfobaseObjectAttributeMessageServer()
	
	Var ResultIsEmpty;
	Ref = GetRef(ResultIsEmpty);
	If ResultIsEmpty Then
		Return False;
	EndIf;
	
	Common.MessageToUser(
		NStr("ru = 'Пример сообщения, связанного с реквизитом ""Ответственный"" документа ""Демо: Счет на оплату покупателю"" 
			| (объект информационной базы).';
			|en = 'Sample of a message connected to the ""Person responsible"" attribute of the ""Demo: Sales proforma invoice"" document
			|(an infobase object).';"),
		Ref.GetObject(), "EmployeeResponsible");
	Return True;
	
EndFunction

&AtClient
Procedure ShowMessageAssociatedWithInfobaseObjectAttributeByRefAtServerCompletion(AdditionalParameters) Export
	
	OpenForm("Document._DemoCustomerProformaInvoice.ListForm");
	
EndProcedure

&AtServer
Function ShowMessageLinkedToInfobaseObjectAttributeByRefServer()
	
	Var ResultIsEmpty;
	
	Ref = GetRef(ResultIsEmpty);
	
	If ResultIsEmpty Then
		Return False;
	EndIf;
	
	Common.MessageToUser(
		NStr("ru = 'Пример сообщения, связанного с реквизитом ""Ответственный"" документа ""Демо: Счет на оплату покупателю""
			| (ссылка на объект).';
			|en = 'Sample of a message connected to the ""Person responsible"" attribute of the ""Demo: Sales proforma invoice"" document
			|(object reference).';"),
		Ref,
		"EmployeeResponsible");
	
	Return True;
	
EndFunction

&AtServerNoContext
Function GetRef(ResultIsEmpty)
	
	QueryText = 
		"SELECT ALLOWED TOP 1
		|	_DemoCustomerProformaInvoice.Ref AS Ref
		|FROM
		|	Document._DemoCustomerProformaInvoice AS _DemoCustomerProformaInvoice";
	
	Query = New Query;
	Query.Text = QueryText;
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		ResultIsEmpty = True;
		Return Documents._DemoCustomerProformaInvoice.EmptyRef();
	EndIf;
	
	ResultIsEmpty = False;
	Return Result.Unload()[0].Ref
	
EndFunction

#EndRegion



