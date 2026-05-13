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
	
	// StandardSubsystems.ContactInformation
	ContactsManager.OnCreateAtServer(ThisObject, Object.Ref,,
		FormItemTitleLocation.Left);

	HiddenKinds = New Array;
	HiddenKinds.Add(ContactsManager.ContactInformationKindByName("_DemoIndividualEmail"));

	AdditionalParameters = ContactsManager.ContactInformationParameters();
	AdditionalParameters.HiddenKinds = HiddenKinds;
	AdditionalParameters.ItemForPlacementName = "IndividualContactInformationGroup";
	AdditionalParameters.CITitleLocation = FormItemTitleLocation.Top;
	ContactsManager.OnCreateAtServer(ThisObject, Individual, AdditionalParameters);
	// End StandardSubsystems.ContactInformation
	
	// Cover the case when the item is created from an interaction.
	Interactions.PrepareNotifications(ThisObject, Parameters, False);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.ContactInformation
	If ValueIsFilled(CurrentObject.Individual) Then
		ValueToFormAttribute(CurrentObject.Individual.GetObject(), "Individual");
	EndIf;

	ContactsManager.OnReadAtServer(ThisObject, Individual,
		"IndividualContactInformationGroup");
	ContactsManager.OnReadAtServer(ThisObject, Object);
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.ContactInformation
	IndividualObject = FormAttributeToValue("Individual");
	ContactsManager.FillCheckProcessingAtServer(ThisObject, IndividualObject, Cancel);
	If Not Cancel Then
		ContactsManager.FillCheckProcessingAtServer(ThisObject, Object, Cancel);
	EndIf;
	// End StandardSubsystems.ContactInformation

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.ContactInformation
	ContactsManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	ContactsManager.BeforeWriteAtServer(ThisObject, Individual);
	// End StandardSubsystems.ContactInformation

EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)

	IndividualObject = FormAttributeToValue("Individual");

	If Not IndividualObject.Ref.IsEmpty() Then
		IndividualObject.Write();
		ValueToFormAttribute(IndividualObject, "Individual");
	EndIf;

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	InteractionsClient.ContactAfterWrite(ThisObject, Object, WriteParameters, "_DemoPartnersContactPersons");
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	AttachIdleHandler("CheckIfIndividualLockRequired", 1, False);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write__DemoIndividuals" And Source = Object.Individual Then
		ReadIndividualContactInformation();
	EndIf;
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure IndividualOnChange(Item)
	If IsBlankString(Object.Description) Then
		Object.Description = Individual.Description;
	EndIf;
	ChangeIndividualData();

EndProcedure

// StandardSubsystems.ContactInformation

&AtClient
Procedure Attachable_ContactInformationOnChange(Item)
	ContactsManagerClient.StartChanging(ThisObject, Item);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationStartChoice(Item, ChoiceData, StandardProcessing)
	ContactsManagerClient.StartSelection(ThisObject, Item,, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationOnClick(Item, StandardProcessing)
	ContactsManagerClient.StartSelection(ThisObject, Item,, StandardProcessing);
EndProcedure

// Parameters:
//  Item - FormField
//  StandardProcessing - Boolean
//
&AtClient
Procedure Attachable_ContactInformationClearing(Item, StandardProcessing)
	ContactsManagerClient.StartClearing(ThisObject, Item.Name);
EndProcedure

// Parameters:
//  Command - FormCommand
//
&AtClient
Procedure Attachable_ContactInformationExecuteCommand(Command)
	ContactsManagerClient.StartCommandExecution(ThisObject, Command.Name);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
	StandardProcessing)

	ContactsManagerClient.AutoCompleteAddress(Item, Text, ChoiceData, DataGetParameters,
		Waiting, StandardProcessing);

EndProcedure

// Parameters:
//  Item - FormField
//  ValueSelected - Arbitrary
//  StandardProcessing -Boolean
//
&AtClient
Procedure Attachable_ContactInformationChoiceProcessing(Item, ValueSelected, StandardProcessing)

	ContactsManagerClient.ChoiceProcessing(ThisObject, ValueSelected, Item.Name,
		StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_ContactInformationURLProcessing(Item,
	FormattedStringURL, StandardProcessing)
	ContactsManagerClient.StartURLProcessing(ThisObject, Item,
		FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContinueContactInformationUpdate(Result, AdditionalParameters) Export
	UpdateContactInformation(Result);
EndProcedure

&AtServer
Procedure UpdateContactInformation(Result)
	ContactsManager.UpdateContactInformation(ThisObject, Object, Result);
EndProcedure

// End StandardSubsystems.ContactInformation

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtClient
Procedure CheckIfIndividualLockRequired()
	If Modified And Not Individual.Ref.IsEmpty() Then
		If LockIndividualOnEditAtServer(Individual.Ref,
			UUID) Then
			DetachIdleHandler("CheckIfIndividualLockRequired");
		Else
			Read();
			Raise NStr("ru = 'Данные контактного лица не могут быть записаны, т.к. личные данные физического лица не доступны для изменения.
								   |Возможно, эти данные физического лица редактируются другим пользователем.';
									|en = 'Contact person details cannot be saved as personal details of an individual cannot be changed.
									|Perhaps, these contact person details are being edited by another user.';");
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure ChangeIndividualData()

	If Individual.Ref.IsEmpty() Then
		ReadIndividualContactInformation();
		Return;
	EndIf;

	If LockIndividualOnEditAtServer(Object.Individual,
		UUID) Then
		UnlockIndividualOnEditAtServer(Individual.Ref,
			UUID);
		ReadIndividualContactInformation();
	Else
		Object.Individual = Individual.Ref;
		Raise NStr("ru = 'Данные контактного лица не могут быть записаны, т.к. личные данные физического лица не доступны для изменения.
							   |Возможно, эти данные физического лица редактируются другим пользователем.';
								|en = 'Contact person details cannot be saved as personal details of an individual cannot be changed.
								|Perhaps, these contact person details are being edited by another user.';");
	EndIf;

EndProcedure

&AtServerNoContext
Function LockIndividualOnEditAtServer(Individual, FormUUID)

	Try
		DataVersion = Common.ObjectAttributeValue(Individual, "DataVersion");
		LockDataForEdit(Individual, DataVersion, FormUUID);
	Except
		Return False;
	EndTry;

	Return True;

EndFunction

&AtServerNoContext
Function UnlockIndividualOnEditAtServer(IndividualRef, FormUUID)
	Try
		UnlockDataForEdit(IndividualRef, FormUUID);
	Except
		Return False;
	EndTry;

	Return True;

EndFunction

&AtServer
Procedure ReadIndividualContactInformation()

	ValueToFormAttribute(Object.Individual.GetObject(), "Individual");
	// StandardSubsystems.ContactInformation
	ContactsManager.OnReadAtServer(ThisObject, Individual.Ref,
		"IndividualContactInformationGroup");
	// End StandardSubsystems.ContactInformation

EndProcedure

#EndRegion