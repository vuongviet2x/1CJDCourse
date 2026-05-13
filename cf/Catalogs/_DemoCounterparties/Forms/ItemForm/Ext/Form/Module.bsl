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

	InfobaseUpdate.CheckObjectProcessed("Catalog._DemoCounterparties", ThisObject);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.Properties
	GroupsForPlacement = New ValueList;
	GroupsForPlacement.Add(PropertyManager.PropertiesSetByName("Catalog_DemoCounterpartiesMain"),
		Items.MainGroup3.Name);
	GroupsForPlacement.Add("AllOther", Items.OthersGroup.Name);

	LabelsDisplayParameters = PropertyManager.LabelsDisplayParameters();
	LabelsDisplayParameters.LabelsDestinationElementName = Items.GroupLabels.Name;
	LabelsDisplayParameters.LabelsDisplayOption = Enums.LabelsDisplayOptions.Label;

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", GroupsForPlacement);
	AdditionalParameters.Insert("LabelsDisplayParameters", LabelsDisplayParameters);
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.ContactInformation
	ItemsPlacedOnForm = New Map;
	ItemsPlacedOnForm.Insert("_DemoCounterpartyAddress", True);
	ItemsPlacedOnForm.Insert("_DemoCounterpartyEmail", True);
	ItemsPlacedOnForm.Insert("_DemoSkypeCounterparties", True);
	ItemsPlacedOnForm.Insert("_DemoCounterpartyPhone", True);
	ItemsPlacedOnForm.Insert("_DemoCounterpartyMessengers", True);
	ItemsPlacedOnForm.Insert("_DemoCounterpartyLegalAddress", True);


	AdditionalContactInformationParameters = ContactsManager.ContactInformationParameters();
	AdditionalContactInformationParameters.DeferredInitialization = True;
	AdditionalContactInformationParameters.ItemsPlacedOnForm = ItemsPlacedOnForm;

	ContactsManager.OnCreateAtServer(ThisObject, Object,
		AdditionalContactInformationParameters);
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Interactions
	Interactions.PrepareNotifications(ThisObject, Parameters, False);
	// End StandardSubsystems.Interactions

	If Common.IsMobileClient() Then
		ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.PageBasic.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
	EndIf;

	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.ContactInformation
	ContactsManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.AccountingAudit
	AccountingAudit.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccountingAudit
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.ContactInformation
	ContactsManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.ContactInformation

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.Interactions
	InteractionsClient.ContactAfterWrite(ThisObject, Object, WriteParameters, "_DemoCounterparties");
	// End StandardSubsystems.Interactions

	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	Notify("Write__DemoCounterparties", New Structure, Object.Ref);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.ContactInformation
	ContactsManager.FillCheckProcessingAtServer(ThisObject, Object, Cancel);
	// End StandardSubsystems.ContactInformation

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
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
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If PropertiesParameters.Property(CurrentPage.Name)
		And Not PropertiesParameters.DeferredInitializationExecuted Then

		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.ContactInformation
	If ContactInformationParameters.Property(CurrentPage.Name)
		And Not ContactInformationParameters[CurrentPage.Name].DeferredInitializationExecuted Then

		ContactInformationWhenChangingPages();

	EndIf;
	// End StandardSubsystems.ContactInformation

EndProcedure

&AtClient
Procedure CounterpartyKindOnChange(Item)

	IsLegalEntity = Object.CounterpartyKind = PredefinedValue("Enum._DemoBusinessEntityIndividual.BusinessEntity");
	If Not IsLegalEntity Then
		Object.CRTR = "";
	EndIf;

EndProcedure

// StandardSubsystems.ContactInformation

&AtClient
Procedure RegistrationCountryChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ContactsManagerClient.WorldCountryChoiceProcessing(Item, ValueSelected, StandardProcessing);
EndProcedure

// End StandardSubsystems.ContactInformation

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined,
	StandardProcessing = Undefined)

	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);

EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);

EndProcedure

// End StandardSubsystems.Properties

// StandardSubsystems.ContactInformation
// An obsolete method for integrating "Contact information" subsystem is demonstrated.
// ACC:78-off - The export server procedure is used for demonstrating an obsolete method.

&AtClient
Procedure Attachable_ContactInformationOnChange(Item)
	ContactsManagerClient.OnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationStartChoice(Item, ChoiceData, StandardProcessing)
	OpeningParameters = New Structure("Country", Object.RegistrationCountry);
	ContactsManagerClient.StartChoice(ThisObject, Item,, StandardProcessing, OpeningParameters);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationOnClick(Item, StandardProcessing)
	ContactsManagerClient.StartChoice(ThisObject, Item,, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationClearing(Item, StandardProcessing)
	ContactsManagerClient.Clearing(ThisObject, Item.Name);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationExecuteCommand(Command)
	ContactsManagerClient.ExecuteCommand(ThisObject, Command.Name);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
	StandardProcessing)

	ContactsManagerClient.AutoCompleteAddress(Item, Text, ChoiceData, DataGetParameters,
		Waiting, StandardProcessing);

EndProcedure

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

&AtServer
Procedure Attachable_UpdateContactInformation(Result) Export
	ContactsManager.UpdateContactInformation(ThisObject, Object, Result);
EndProcedure

&AtServer
Procedure ContactInformationWhenChangingPages()
	ContactsManager.ExecuteDeferredInitialization(ThisObject, Object);
EndProcedure

// ACC:78-on
// End StandardSubsystems.ContactInformation

// StandardSubsystems.AttachableCommands
// An obsolete method for integrating "Attachable commands" subsystem is demonstrated.
// ACC:78-off - The export server procedure is used for demonstrating an obsolete method.

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

// ACC:78-on
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.AccountingAudit
&AtClient
Procedure Attachable_OpenIssuesReport(ItemOrCommand, Var_URL, StandardProcessing)
	AccountingAuditClient.OpenObjectIssuesReport(ThisObject, Object.Ref, StandardProcessing);
EndProcedure
// End StandardSubsystems.AccountingAudit

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
EndProcedure

#EndRegion