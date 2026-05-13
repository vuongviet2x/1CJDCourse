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
	// A report option whose structure change is forbidden.
	Settings.EditStructureAllowed = False;
EndProcedure

// End StandardSubsystems.ReportsOptions

// StandardSubsystems.AdditionalReportsAndDataProcessors

// Returns info about an external report.
//
// Returns:
//   See AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo
//
Function ExternalDataProcessorInfo() Export
	RegistrationParameters = AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo("2.2.4.1");
	RegistrationParameters.Information = NStr("ru = 'Отчет по документам ""Демо: Счет на оплату покупателю"". Используется для демонстрации возможностей подсистемы ""Дополнительные отчеты и обработки"".';
											|en = 'Report on documents ""Demo: Sales proforma invoice"". Used for showing features of the Additional reports and data processors subsystem.';");
	RegistrationParameters.Kind = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalReport();
	RegistrationParameters.Version = "2.4.1.1";
	RegistrationParameters.DefineFormSettings = True;
	
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Получить простой отчет...';
								|en = 'Get simple report…';");
	Command.Id = "AdditionalReportGetSimpleReport";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm();
	Command.ShouldShowUserNotification = False;
	
	Return RegistrationParameters;
EndFunction

// End StandardSubsystems.AdditionalReportsAndDataProcessors

#EndRegion

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	VariantKey = CommonClientServer.StructureProperty(SettingsComposer.UserSettings.AdditionalProperties, "VariantKey");
	If VariantKey = "Exception" Then
		StandardProcessing = False;
		SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", True);
		Raise NStr("ru = 'Прикладной текст исключения';
								|en = 'Applied exception text';");
	EndIf;
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf