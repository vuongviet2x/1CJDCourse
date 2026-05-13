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
//   CreatedObjects - Array - Objects created during the command runtime.
//
&AtClient
Procedure ExecuteCommand(CommandID, RelatedObjects, CreatedObjects) Export
	Parameters.CommandID = CommandID;
	
	AccompanyingText1 = NStr("ru = 'Создание списаний товаров';
								|en = 'Creating goods write-offs';");
	
	CommandParameters = AdditionalReportsAndDataProcessorsClient.CommandExecuteParametersInBackground(Parameters.AdditionalDataProcessorRef);
	CommandParameters.RelatedObjects   = RelatedObjects;
	CommandParameters.CreatedObjects    = CreatedObjects;
	CommandParameters.AccompanyingText1 = AccompanyingText1 + "...";
	
	Operation = ExecuteCommandDirectly(CommandParameters);
	AfterFinishTimeConsumingOperation(Operation, AccompanyingText1);
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
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateMoves(Command)
	ExecuteCommandInBackground(NStr("ru = 'Создание документов';
								|en = 'Create documents';"));
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ExecuteCommandInBackground(AccompanyingText1)
	CommandParameters = AdditionalReportsAndDataProcessorsClient.CommandExecuteParametersInBackground(Parameters.AdditionalDataProcessorRef);
	CommandParameters.RelatedObjects = RelatedObjects.UnloadValues();
	CommandParameters.CreatedObjects = New Array;
	CommandParameters.AccompanyingText1 = AccompanyingText1 + "...";
	CommandParameters.Insert("StorageLocationDestination", StorageLocationDestination);
	
	Handler = New NotifyDescription("AfterFinishTimeConsumingOperation", ThisObject, AccompanyingText1);
	If ValueIsFilled(Parameters.AdditionalDataProcessorRef) Then // The data processor is attached.
		AdditionalReportsAndDataProcessorsClient.ExecuteCommandInBackground(Parameters.CommandID, CommandParameters, Handler);
	Else
		Operation = ExecuteCommandDirectly(CommandParameters);
		ExecuteNotifyProcessing(Handler, Operation);
	EndIf;
EndProcedure

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

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AccompanyingText1 - String
//
&AtClient
Procedure AfterFinishTimeConsumingOperation(Result, AccompanyingText1) Export
	
	ReadAndClose();
	
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
Procedure ReadAndClose()
	If TypeOf(FormOwner) = Type("ClientApplicationForm") And Not FormOwner.Modified Then
		Try
			FormOwner.Read();
		Except
			// ACC:280 - The list form is missing the "Read" method.
		EndTry;
	EndIf;
	If IsOpen() Then
		Close();
	EndIf;
EndProcedure

#EndRegion
