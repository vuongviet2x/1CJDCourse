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
	RegistrationParameters.Information = NStr("ru = 'Обработка сервисных функций полнотекстового поиска. Используется для демонстрации возможностей подсистемы ""Дополнительные отчеты и обработки"".';
											|en = 'The data processor of full-text search service functions. It is used to demonstrate features of the ""Additional reports and data processors"" subsystem.';");
	RegistrationParameters.Kind = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalDataProcessor();
	RegistrationParameters.Version = "3.0.2.1";
	
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Обновить индекс полнотекстового поиска';
								|en = 'Update full-text search index';");
	Command.Id = "UpdateIndex";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeServerMethodCall();
	Command.ShouldShowUserNotification = True;
	
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Вывод ошибки';
								|en = 'Error output';");
	Command.Id = "Exception";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeServerMethodCall();
	
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Управление полнотекстовым поиском';
								|en = 'Full-text search management';");
	Command.Id = "OpeningForm";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm();
	Command.ShouldShowUserNotification = True;
	
	LongDesc = NStr("ru = 'Для управления индексом полнотекстового поиска требуется установка привилегированного режима.';
					|en = 'To manage full-text search index, set privileged mode.';");
	Resolution = SafeModeManager.PermissionToUsePrivilegedMode(LongDesc);
	RegistrationParameters.Permissions.Add(Resolution);
	
	Return RegistrationParameters;
EndFunction

// Server commands handler.
//
// Parameters:
//   CommandName           - String    - Command name given in function ExternalDataProcessorInfo().
//   ExecutionParameters  - Structure - Command execution context:
//       * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - Data processor reference.
//           Can be used to read data processor parameters.
//           As an example, see the comments to function AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm().
//
Procedure ExecuteCommand(Val CommandName, Val ExecutionParameters) Export
	If CommandName = "Exception" Then
		Raise NStr("ru = 'Вызвано исключение';
								|en = 'An exception is raised';");
	EndIf;
	If CommandName = "OpeningForm" Then
		CommandName = CommonClientServer.StructureProperty(ExecutionParameters, "CommandName");
	EndIf;
	
	// General actions before command execution start.
	SetPrivilegedMode(True);
	
	// Dispatch commands handlers.
	If CommandName = "UpdateIndex" Then
		If FullTextSearch.GetFullTextSearchMode() <> FullTextSearchMode.Enable Then 
			Raise NStr("ru = 'Полнотекстовый поиск запрещен. Обратитесь к администратору.';
									|en = 'Full text search is prohibited. Contact the Administrator.';");
		EndIf;	
		Try
			FullTextSearch.UpdateIndex(False, False);
		Except
			WriteLogEvent(NStr("ru = 'Демо: управление полнотекстовым поиском';
											|en = 'Demo: Full-text search management';", Common.DefaultLanguageCode()), 
				EventLogLevel.Warning,,, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;	
	ElsIf CommandName = "ClearIndex" Then
		If FullTextSearch.GetFullTextSearchMode() <> FullTextSearchMode.Enable Then 
			Raise NStr("ru = 'Полнотекстовый поиск запрещен. Обратитесь к администратору.';
									|en = 'Full text search is prohibited. Contact the Administrator.';");
		EndIf;	
		Try
			FullTextSearch.ClearIndex();
		Except
			WriteLogEvent(NStr("ru = 'Демо: управление полнотекстовым поиском';
											|en = 'Demo: Full-text search management';", Common.DefaultLanguageCode()), 
				EventLogLevel.Warning,,, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;	
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Команда ""%1"" не поддерживается обработкой ""%2""';
				|en = 'The ""%2"" data processor does not support the ""%1"" command';"), CommandName, Metadata().Presentation());
	EndIf;
	
	// Simulate a long-running operation to demonstrate a background job start in the client/server mode.
	If Not Common.FileInfobase() Then
		EndDate = CurrentSessionDate() + 4;
		While EndDate > CurrentSessionDate() Do
		EndDo;
	EndIf;
	
EndProcedure

// End StandardSubsystems.AdditionalReportsAndDataProcessors

#EndRegion

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf