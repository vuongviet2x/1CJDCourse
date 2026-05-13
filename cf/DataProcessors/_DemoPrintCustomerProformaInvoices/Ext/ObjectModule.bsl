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

// StandardSubsystems.AdditionalReportsAndDataProcessors

// Returns info about an external data processor.
//
// Returns:
//   See AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo
//
Function ExternalDataProcessorInfo() Export
	RegistrationParameters = AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo("2.3.1.73");
	RegistrationParameters.Information = NStr("ru = 'Обработка формирования печатной формы документа ""Демо: Счет на оплату покупателю"". Используется для демонстрации возможностей подсистемы ""Дополнительные отчеты и обработки"".';
											|en = 'The data processor of document print form generation ""Demo: Sales proforma invoice"". It is used for showing features of the Additional reports and data processors subsystem.';");
	RegistrationParameters.Kind = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindPrintForm();
	RegistrationParameters.Version = "3.1.8.48";
	RegistrationParameters.Purpose.Add("Document._DemoCustomerProformaInvoice");
	
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Счет на оплату (внешняя печатная форма)';
								|en = 'Proforma invoice (external print form)';");
	Command.Id = "Account";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeServerMethodCall();
	Command.ShouldShowUserNotification = True;
	Command.Modifier = "PrintMXL1";
	Command.CommandsToReplace = "Account,Receipt";
	
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Комплект документов (внешняя печатная форма)';
								|en = 'Document set (external print form)';");
	Command.Id = "Account,Account,OrderDocument";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeServerMethodCall();
	Command.ShouldShowUserNotification = True;
	Command.Modifier = "PrintMXL1";
	
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Гарантийное письмо (внешняя печатная форма)';
								|en = 'Warranty letter (external print form)';");
	Command.Id = "LetterOfGuarantee";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeServerMethodCall();
	Command.ShouldShowUserNotification = True;
	Command.Modifier = "PrintMXL1";
	
	Return RegistrationParameters;
EndFunction

// End StandardSubsystems.AdditionalReportsAndDataProcessors

// StandardSubsystems.Print

// Generates print forms.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "Account");
	If PrintForm <> Undefined Then
		PrintForm.SpreadsheetDocument = Documents._DemoCustomerProformaInvoice.PrintingAnOrderInvoice(ObjectsArray, PrintObjects, "Account");
		PrintForm.TemplateSynonym = NStr("ru = 'Счет на оплату (внешняя печатная форма)';
											|en = 'Proforma invoice (external print form)';");
		PrintForm.FullTemplatePath = "Document._DemoCustomerProformaInvoice.PF_MXL_OrderInvoice";
	EndIf;
	
	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "OrderDocument");
	If PrintForm <> Undefined Then
		PrintForm.SpreadsheetDocument = Documents._DemoCustomerProformaInvoice.PrintingAnOrderInvoice(ObjectsArray, PrintObjects, "OrderDocument");
		PrintForm.TemplateSynonym = NStr("ru = 'Заказ покупателя (внешняя печатная форма)';
											|en = 'Sales order (external print form)';");
		PrintForm.FullTemplatePath = "Document._DemoCustomerProformaInvoice.PF_MXL_OrderInvoice";
	EndIf;
	
	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "LetterOfGuarantee");
	If PrintForm <> Undefined Then
		PrintForm.SpreadsheetDocument = Documents._DemoCustomerProformaInvoice.PrintingALetterOfGuarantee(ObjectsArray, PrintObjects, OutputParameters.LanguageCode);
		PrintForm.TemplateSynonym = NStr("ru = 'Гарантийное письмо (внешняя печатная форма)';
											|en = 'Warranty letter (external print form)';");
		PrintForm.FullTemplatePath = "Document._DemoCustomerProformaInvoice.PF_MXL_LetterOfGuarantee";
		PrintForm.OutputInOtherLanguagesAvailable = True;
	EndIf;
	
	Documents._DemoCustomerProformaInvoice.OnSpecifyingRecipients(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf