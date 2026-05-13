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
	RegistrationParameters = AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo("2.2.2.1");
	RegistrationParameters.Information = NStr("ru = 'Обработка формирования печатной формы документа ""Демо: Списание товаров"". Печатные формы создаются в формате Open Office XML. Используется для демонстрации возможностей подсистемы ""Дополнительные отчеты и обработки"".';
											|en = 'The data processor generates print forms for documents ""Demo: Goods write-off"" in the Open Office XML format. It demonstrates the features and capabilities of the ""Additional reports and data processors"" subsystem.';");
	RegistrationParameters.Kind = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindPrintForm();
	RegistrationParameters.Version = "3.1.4.1";
	RegistrationParameters.Purpose.Add("Document._DemoGoodsWriteOff");
	
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Списание товаров в Open Office XML (внешняя печатная форма)';
								|en = 'Goods write-off in Open Office XML (external print form)';");
	Command.Id = "GoodsWriteOffOpenOfficeXML";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeClientMethodCall();
	Command.ShouldShowUserNotification = True;
	
	Return RegistrationParameters;
EndFunction

// End StandardSubsystems.AdditionalReportsAndDataProcessors

#EndRegion

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf