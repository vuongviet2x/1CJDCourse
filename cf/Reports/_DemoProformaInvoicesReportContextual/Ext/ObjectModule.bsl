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

// Returns info about an external report.
//
// Returns:
//   See AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo
//
Function ExternalDataProcessorInfo() Export
	RegistrationParameters = AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo("2.2.5.1");
	RegistrationParameters.Information = NStr("ru = 'Отчет по документам ""Демо: Счет на оплату покупателю"". Используется для демонстрации возможностей подсистемы ""Дополнительные отчеты и обработки"".';
											|en = 'Report on documents ""Demo: Sales proforma invoice"". Used for showing features of the Additional reports and data processors subsystem.';");
	RegistrationParameters.Kind = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindReport();
	RegistrationParameters.Version = "3.1.9.233";
	RegistrationParameters.Purpose.Add("Document._DemoCustomerProformaInvoice");
	RegistrationParameters.DefineFormSettings = True;
	
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Список используемой номенклатуры в счетах на оплату';
								|en = 'List of products used in proforma invoices';");
	Command.Id = "Main";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm();
	Command.ShouldShowUserNotification = False;
	
	Return RegistrationParameters;
EndFunction

// End StandardSubsystems.AdditionalReportsAndDataProcessors

// StandardSubsystems.ReportsOptions

// Specify the report form settings.
//
// Parameters:
//   Form - ClientApplicationForm
//         - Undefined
//   VariantKey - String
//                - Undefined
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.GenerateImmediately = True;
	Settings.EditOptionsAllowed = False;
	Settings.Events.OnCreateAtServer = True;
EndProcedure

// Runs in the same-name event handler of a report form after executing the form code.
//  See ClientApplicationForm.OnCreateAtServer in Syntax Assistant.
//
// Parameters:
//   Form - ClientApplicationForm - Report form.
//   Cancel - Boolean - The value is passed "as is" from the handler parameters.
//   StandardProcessing - Boolean - The value is passed "as is" from the handler parameters.
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	RelatedObjects = CommonClientServer.StructureProperty(Form.Parameters, "RelatedObjects");
	If RelatedObjects <> Undefined Then
		Form.ParametersForm.Filter.Insert("Ref", RelatedObjects);
	EndIf;
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf