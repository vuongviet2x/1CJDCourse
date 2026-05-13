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
	RegistrationParameters.Information = NStr("ru = 'Обработка заполнения справочника ""Демо: Контрагенты"". Используется для демонстрации возможностей подсистемы ""Дополнительные отчеты и обработки.""';
											|en = 'Processing the ""Demo: Counterparties"" catalog population. It is used to demonstrate features of the ""Additional reports and data processors"" subsystem.';");
	RegistrationParameters.Kind = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindObjectFilling();
	RegistrationParameters.Version = "3.0.2.1";
	RegistrationParameters.SafeMode = False;
	RegistrationParameters.Purpose.Add("Catalog._DemoCounterparties");
	
	// See command implementation in the ExecuteCommand procedure of the data processor module.
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Заполнить реквизит ""Полное наименование"" (вызов серверной процедуры)';
								|en = 'Fill the ""Full description"" attribute (server procedure call)';");
	Command.Id = "FillFullDescription";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeServerMethodCall();
	Command.ShouldShowUserNotification = True;
	
	// See command implementation in the AddPrefixToDescription procedure of the data processor form module.
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Добавить префикс к реквизиту ""Наименование"" (открытие формы)...';
								|en = 'Add a prefix to the ""Description"" attribute (opening form)…';");
	Command.Id = "AddPrefixToDescription";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm();
	Command.ShouldShowUserNotification = False;
	
	// See command implementation in the ExecuteCommand procedure of the data processor module.
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Комплексная очистка (вызов серверной процедуры)';
								|en = 'Complex clearing (server procedure call)';");
	Command.Id = "ClearAll";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeServerMethodCall();
	Command.ShouldShowUserNotification = False;
	
	// See command implementation in the ExecuteCommand procedure of the data processor form module.
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Комплексное заполнение (вызов клиентской процедуры)';
								|en = 'Complex population (client procedure call)';");
	Command.Id = "FillInAll_";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeClientMethodCall();
	Command.ShouldShowUserNotification = True;
	
	// See command implementation in the ExecuteCommand procedure of the data processor module.
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Заполнить реквизит ""ИНН"" не записывая объект (заполнение формы)';
								|en = 'Fill the ""TIN"" attribute not saving the object (filling form)';");
	Command.Id = "FillTIN";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeFormFilling();
	Command.ShouldShowUserNotification = False;
	
	Return RegistrationParameters;
	
EndFunction

// Server commands handler.
//
// Parameters:
//   CommandID - String - Command name given in function ExternalDataProcessorInfo().
//   RelatedObjects    - Array - References to the objects the command runs for.
//                        - Undefined - for the FormFilling commands.
//   ExecutionParameters  - Structure - Command execution context:
//       * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - Data processor reference.
//           Can be used to read data processor parameters.
//           As an example, see the comments to function AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm().
//
Procedure ExecuteCommand(CommandID, RelatedObjects, ExecutionParameters) Export
	EndDateInMilliseconds = CurrentUniversalDateInMilliseconds() + 4;
	
	If CommandID = "FillTIN" Then
		FillTIN(ExecutionParameters.ThisForm);
	ElsIf CommandID = "FillFullDescription" Then
		ListOfCounterparties(RelatedObjects, True, False);
	ElsIf CommandID = "FillInAll_" Then
		ListOfCounterparties(RelatedObjects, True, True);
	ElsIf CommandID = "AddPrefixToDescription" Then
		ListOfCounterparties(RelatedObjects, False, True);
	ElsIf CommandID = "ClearAll" Then
		ClearCounterpartiesAttributes(RelatedObjects);
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Команда ""%1"" не поддерживается обработкой ""%2""';
				|en = 'The ""%2"" data processor does not support the ""%1"" command';"),
			CommandID,
			Metadata().Presentation());
	EndIf;
	
	// Simulate a long-running operation.
	While CurrentUniversalDateInMilliseconds() < EndDateInMilliseconds Do
	EndDo;
EndProcedure

// End StandardSubsystems.AdditionalReportsAndDataProcessors

#EndRegion

#EndRegion

#Region Private

// Command handler.
Procedure FillTIN(Form)
	
	Generator = New RandomNumberGenerator;
	
	Form.Object.TIN = Format(Generator.RandomNumber(1, 999999999), "ND=12; NFD=0; NLZ=; NG=");
	Form.Modified = True;
	
	Message = New UserMessage;
	Message.Text = NStr("ru = 'Поле ""ИНН"" заполнено.';
							|en = 'TIN field is filled in.';");
	Message.Field = "TIN";
	Message.Message();
	
EndProcedure

// Handler of the FillFullDescription, AddPrefixToDescription, FillAll, and ClearAll commands.
Procedure ListOfCounterparties(RelatedObjects, FillDescription1, AddPrefix) Export
	
	If RelatedObjects.Count() = 0 Then
		Raise NStr("ru = 'Не выбраны контрагенты для заполнения';
								|en = 'Counterparties to populate are not selected';");
	EndIf;
	
	Errors = New Array;
	
	// Populate objects.
	For Each RelatedObjectItem In RelatedObjects Do
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add("Catalog._DemoCounterparties");
			LockItem.SetValue("Ref", RelatedObjectItem);
			Block.Lock();
			
			RelatedObject = RelatedObjectItem.GetObject();
			If FillDescription1 Then
				If Not IsBlankString(RelatedObject.DescriptionFull) Then
					Errors.Add(
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Объект ""%1"" не обработан: реквизит ""%2"" не пустой.';
								|en = 'Object ""%1"" is not processed: attribute ""%2"" is not blank.';"),
							String(RelatedObject), "DescriptionFull"));
				Else
					RelatedObject.DescriptionFull = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Полное наименование заполнено %1';
							|en = 'The full description is populated %1';"),
						String(CurrentSessionDate()));
				EndIf;
			EndIf;
			
			If AddPrefix Then
				RelatedObject.Description = Prefix() + RelatedObject.Description;
			EndIf;
			
			RelatedObject.Write();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
	If FillDescription1 And AddPrefix Then
		NotificationTitle = NStr("ru = 'Наименование и префикс заполнены';
									|en = 'Description and prefix are populated';");
	ElsIf FillDescription1 Then
		NotificationTitle = NStr("ru = 'Полное наименование заполнено';
									|en = 'The full description is populated';");
	ElsIf AddPrefix Then
		NotificationTitle = NStr("ru = 'Добавлен префикс к краткому наименованию';
									|en = 'Prefix to short description is added';");
	EndIf;
	OutputNotification(RelatedObjects, NotificationTitle, Errors);
	
EndProcedure

// Handler of the ClearAll command.
Procedure ClearCounterpartiesAttributes(RelatedObjects) 
	
	If RelatedObjects.Count() = 0 Then
		Raise NStr("ru = 'Не выбраны контрагенты для очистки реквизитов';
								|en = 'Counterparties to clear attributes are not selected';");
	EndIf;
	
	// Populate objects.
	For Each RelatedObjectItem In RelatedObjects Do
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add("Catalog._DemoCounterparties");
			LockItem.SetValue("Ref", RelatedObjectItem);
			Block.Lock();
			
			RelatedObject = RelatedObjectItem.GetObject();
			RelatedObject.Description = StrReplace(RelatedObject.Description, Prefix(), "");
			RelatedObject.DescriptionFull = "";
			RelatedObject.TIN = "";
			RelatedObject.Write();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
	OutputNotification(RelatedObjects, NStr("ru = 'Наименование и префикс очищены';
												|en = 'Description and prefix are cleared';"));
	
EndProcedure

Function Prefix()
	
	Return NStr("ru = 'ПР';
				|en = 'Prefix';") + " ";
	
EndFunction

Procedure OutputNotification(RelatedObjects, NotificationTitle, Errors = Undefined)
	Total = RelatedObjects.Count();
	Errors1 = ?(Errors <> Undefined, Errors.Count(), 0);
	Filled = Total - Errors1;
	
	If Total = 1 Then
		If Errors1 > 0 Then
			Message = New UserMessage;
			Message.Text = Errors[0];
			Message.Field = "Object.DescriptionFull";
			Message.Message();
		Else
			Message = New UserMessage;
			Message.Text = NotificationTitle;
			Message.Message();
		EndIf;
		Return;
	EndIf;
	
	If Errors1 = 0 Then
		NotificationText1 = StringFunctionsClientServer.StringWithNumberForAnyLanguage(
			NStr("ru = ';Обработан %1 объект;; Обработано %1 объекта; Обработано %1 объектов; Обработано %1 объекта';
				|en = ';%1 object is processed;;;;%1 objects are processed';"),
			Total);
		Message = New UserMessage;
		Message.Text = NotificationText1;
		Message.Message();
		Return;
	EndIf;
	
	Brief1 = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Всего объектов: %1
			|Успешно заполнено: %2
			|Ошибок: %3';
			|en = 'Objects total: %1
			|Successfully populated: %2
			|Errors: %3';"),
		Format(Total,     "NZ=0; NG=0"),
		Format(Filled, "NZ=0; NG=0"), 
		Format(Errors1,    "NZ=0; NG=0"));
	
	Message = New UserMessage;
	Message.Text = Brief1;
	Message.Message();
	
	More = "";
	For Each ErrorText In Errors Do
		More = More + "---" + Chars.LF + Chars.LF + ErrorText + Chars.LF + Chars.LF;
	EndDo;
	
	WriteLogEvent(
		NStr("ru = 'Обработка заполнения справочника Демо: Контрагенты';
			|en = 'Processing the Demo: Counterparties catalog population';", Common.DefaultLanguageCode()), 
		EventLogLevel.Information,
		Metadata.Catalogs._DemoCounterparties,
		,
		More);
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf