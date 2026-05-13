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
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.DigitalSignature
	Items.FormCertificateApplication.Visible = DigitalSignature.AvailabilityOfCreatingAnApplication().ForSoleProprietors
		Or DigitalSignature.AvailabilityOfCreatingAnApplication().ForEmployeesLegalEntities
		Or DigitalSignature.AvailabilityOfCreatingAnApplication().ForHeadsLegalEntities;
	// End StandardSubsystems.DigitalSignature

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.DigitalSignature
&AtClient
Procedure CertificateApplication(Command)

	If Not ValueIsFilled(Items.List.CurrentRow) Then
		ShowMessageBox(, NStr("ru = 'Выделите строку с организацией';
										|en = 'Select line with a company';"));
		Return;
	EndIf;

	ResultHandler = New NotifyDescription("CertificateApplicationAfterAdding", ThisObject);

	AddingOptions = DigitalSignatureClient.CertificateAddingOptions();
	AddingOptions.Organization = Items.List.CurrentRow;
	AddingOptions.FromPersonalStorage = False;
	DigitalSignatureClient.ToAddCertificate(ResultHandler, AddingOptions);

EndProcedure
// End StandardSubsystems.DigitalSignature

#EndRegion

#Region Private

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.DigitalSignature

// Parameters:
//  Result - Undefined
//            - Structure:
//          * Ref   - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//          * Added - Boolean
//
//  Context - Undefined
//
&AtClient
Procedure CertificateApplicationAfterAdding(Result, Context) Export

	If Result = Undefined Then
		WarningText = NStr("ru = 'Заявление не добавлено';
									|en = 'Application is not added';");

	ElsIf Not Result.Added Then
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Заявление добавлено, но не исполнено:
				 |%1';
				|en = 'Application is added but not fulfilled:
				|%1';"), Result.Ref);
	Else
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Заявление добавлено, и исполнено:
				 |%1';
				|en = 'Application is added and fulfilled:
				|%1';"), Result.Ref);
	EndIf;

	ShowMessageBox(, WarningText);

EndProcedure
// End StandardSubsystems.DigitalSignature

#EndRegion