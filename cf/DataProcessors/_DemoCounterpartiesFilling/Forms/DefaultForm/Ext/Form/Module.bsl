///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.AdditionalReportsAndDataProcessors

// ACC:78-off additional data processor.

// Assignable client command handler.
//
// Parameters:
//   CommandID - String - Command name as it is given in function ExternalDataProcessorInfo of the object module.
//   RelatedObjects - Array - References the command runs for.
//
&AtClient
Procedure ExecuteCommand(CommandID, RelatedObjects) Export
	
	If CommandID = "FillInAll_" Then
		ListOfCounterparties(RelatedObjects, True, True);
		RefreshCounterpartiesAndClose();
	EndIf;
	
EndProcedure
// ACC:78-on.

// End StandardSubsystems.AdditionalReportsAndDataProcessors

#EndRegion

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	For Each RelatedObjectsItem In Parameters.RelatedObjects Do
		RelatedObjects.Add(RelatedObjectsItem);
	EndDo;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddPrefixToDescription(Command)
	AccompanyingText1 = NStr("ru = 'Добавление префикса к реквизиту ""Наименование""';
								|en = 'Add prefix to the ""Description"" attribute';");
	
	CommandParameters = AdditionalReportsAndDataProcessorsClient.CommandExecuteParametersInBackground(Parameters.AdditionalDataProcessorRef);
	CommandParameters.RelatedObjects = RelatedObjects.UnloadValues();
	CommandParameters.AccompanyingText1 = AccompanyingText1 + "...";
	
	ShowUserNotification(CommandParameters.AccompanyingText1);
	
	Handler = New NotifyDescription("AfterFinishTimeConsumingOperation", ThisObject, AccompanyingText1);
	
	If ValueIsFilled(Parameters.AdditionalDataProcessorRef) Then
		AdditionalReportsAndDataProcessorsClient.ExecuteCommandInBackground(Parameters.CommandID, CommandParameters, Handler);
	Else
		Operation = ExecuteCommandDirectly(CommandParameters);
		ExecuteNotifyProcessing(Handler, Operation);
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ExecuteCommandDirectly(CommandParameters)
	Operation = New Structure("Status, ErrorInfo");
	Try
		AdditionalReportsAndDataProcessors.ExecuteCommandFromExternalObjectForm(
			Parameters.CommandID,
			CommandParameters,
			ThisObject);
		Operation.Status = "Completed2";
	Except
		Operation.ErrorInfo = ErrorInfo();
	EndTry;
	Return Operation;
EndFunction

&AtServer
Procedure ListOfCounterparties(RelatedObjects, FillDescription1, AddPrefix)
	
	FormAttributeToValue("Object").ListOfCounterparties(RelatedObjects, FillDescription1, AddPrefix);
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AccompanyingText1 - String
//
&AtClient
Procedure AfterFinishTimeConsumingOperation(Result, AccompanyingText1) Export
	
	RefreshCounterpartiesAndClose();
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		ShowUserNotification(NStr("ru = 'Успешное завершение';
											|en = 'Successful completion';"),,
			AccompanyingText1, PictureLib.Success32);
	Else
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshCounterpartiesAndClose()
	If TypeOf(FormOwner) = Type("ClientApplicationForm") And Not FormOwner.Modified Then
		Try
			FormOwner.Read();
		Except
			// ACC:280 - The list form is missing the "Read" method.
		EndTry;
	EndIf;
	NotifyChanged(Type("CatalogRef._DemoCounterparties"));
	If IsOpen() Then
		Close();
	EndIf;
EndProcedure

#EndRegion
