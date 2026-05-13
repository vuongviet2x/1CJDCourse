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
	RegistrationParameters.Information = NStr("ru = 'Ввод документов на основании ""Демо: Оприходование товаров"". Используется для демонстрации возможностей подсистемы ""Дополнительные отчеты и обработки"".';
											|en = 'Entering documents on the basis of Demo: Goods recording as received. It is used to demonstrate features of the ""Additional reports and data processors"" subsystem.';");
	RegistrationParameters.Kind = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindRelatedObjectCreation();
	RegistrationParameters.Version = "3.0.2.1";
	RegistrationParameters.SafeMode = False;
	RegistrationParameters.Purpose.Add(Metadata.Documents._DemoReceivedGoodsRecording.FullName());
	
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Скопировать документы ""Демо: Оприходование товаров"" (вызов серверного метода).';
								|en = 'Copy the ""Demo: Goods recording as received"" documents (calling a server method).';");
	Command.Id = "Copy";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeServerMethodCall();
	Command.ShouldShowUserNotification = True;
	
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Создать документы ""Демо: Перемещение товаров"" (открытие формы)...';
								|en = 'Create the ""Demo: Goods transfer"" documents (opening form)…';");
	Command.Id = "CreateMoves";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm();
	Command.ShouldShowUserNotification = False;
	
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Создать документы ""Демо: Списание товаров"" (вызов клиентского метода).';
								|en = 'Create documents ""Demo: Goods write-off"" (client method).';");
	Command.Id = "CreateCharge";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeClientMethodCall();
	Command.ShouldShowUserNotification = True;
	
	Return RegistrationParameters;
EndFunction

// Server commands handler.
//
// Parameters:
//   CommandID - String - Command name given in function ExternalDataProcessorInfo().
//   RelatedObjects    - Array - References to the objects the command runs for.
//   CreatedObjects     - Array - References to the objects created during the command runtime.
//   ExecutionParameters  - Structure - Command execution context:
//       * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - Data processor reference.
//           Can be used to read data processor parameters.
//           As an example, see the comments to function AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm().
//
Procedure ExecuteCommand(CommandID, RelatedObjects, CreatedObjects, ExecutionParameters) Export
	StartDateInMilliseconds = CurrentUniversalDateInMilliseconds();
	StorageLocationDestination = CommonClientServer.StructureProperty(ExecutionParameters, "StorageLocationDestination");
	
	CreatedObjects = New Array;
	For Each Basis In RelatedObjects Do
		BasisObject = Basis.GetObject();
		If CommandID = "Copy" Then
			NewObject = Copy(Basis, BasisObject);
		ElsIf CommandID = "CreateMoves" Then
			NewObject = CreateMoves(Basis, BasisObject, StorageLocationDestination);
		ElsIf CommandID = "CreateCharge" Then
			NewObject = CreateCharge(Basis, BasisObject);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Команда ""%1"" не поддерживается обработкой ""%2""';
					|en = 'The ""%2"" data processor does not support the ""%1"" command';"),
				CommandID,
				Metadata().Presentation());
		EndIf;
		NewObject.Write();
		CreatedObjects.Add(NewObject.Ref);
	EndDo;
	
	// Simulate a long-running operation.
	RNG = New RandomNumberGenerator;
	EndDateInMilliseconds = StartDateInMilliseconds + 1000*RNG.RandomNumber(2, 4);
	While CurrentUniversalDateInMilliseconds() < EndDateInMilliseconds Do
	EndDo;
EndProcedure

// End StandardSubsystems.AdditionalReportsAndDataProcessors

#EndRegion

#EndRegion

#Region Private

// Run the command.
Function Copy(Basis, BasisObject)
	NewObject = Documents._DemoReceivedGoodsRecording.CreateDocument();
	FillDocumentBasedOnOtherDocument(NewObject, Basis, BasisObject);
	NewObject.Goods.Load(BasisObject.Goods.Unload());
	Return NewObject;
EndFunction

// Run the command.
Function CreateMoves(Basis, BasisObject, StorageLocationDestination)
	NewObject = Documents._DemoInventoryTransfer.CreateDocument();
	FillDocumentBasedOnOtherDocument(NewObject, Basis, BasisObject);
	NewObject.Goods.Load(BasisObject.Goods.Unload());
	NewObject.StorageSource = BasisObject.StorageLocation;
	NewObject.StorageLocationDestination = StorageLocationDestination;
	Return NewObject;
EndFunction

// Run the command.
Function CreateCharge(Basis, BasisObject)
	NewObject = Documents._DemoGoodsWriteOff.CreateDocument();
	FillDocumentBasedOnOtherDocument(NewObject, Basis, BasisObject);
	NewObject.Goods.Load(BasisObject.Goods.Unload());
	Return NewObject;
EndFunction

// Common mechanism.
Procedure FillDocumentBasedOnOtherDocument(NewObject, Basis, BasisObject)
	FillPropertyValues(NewObject, BasisObject, , "Number, EmployeeResponsible");
	NewObject.Date = CurrentSessionDate();
	NewObject.Comment = StrReplace(NStr("ru = 'Введен на основании ""%1"".';
												|en = 'It is entered on the basis of ""%1"".';"), "%1", String(Basis))
		+ ?(ValueIsFilled(NewObject.Comment), " " + TrimAll(NewObject.Comment), "");
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf