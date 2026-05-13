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

	If Object.Ref.IsEmpty() Or ReadOnly Then
		Items.FormAllowDenyEditing.Visible = False;
	EndIf;

	If Not Users.IsExternalUserSession() Then
		// StandardSubsystems.AttachableCommands
		AttachableCommands.OnCreateAtServer(ThisObject);
		// End StandardSubsystems.AttachableCommands

		If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
			ModuleContactsManager = Common.CommonModule("ContactsManager");
			AdditionalContactInformationParameters = ModuleContactsManager.ContactInformationParameters();
			AdditionalContactInformationParameters.PremiseType = "Office";
			ModuleContactsManager.OnCreateAtServer(ThisObject, Object,
				AdditionalContactInformationParameters);
		EndIf;
	Else
		Items.Pages.Visible = False;
	EndIf;

	CompanyType = ?(ValueIsFilled(Object.IndividualEntrepreneur), 1, 0);
	
	// StandardSubsystems.StoredFiles
	ItemsToAdd1 = New Array;

	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	ItemsToAdd1.Add(HyperlinkParameters);

	CommonFieldParameters = FilesOperations.FileField();
	CommonFieldParameters.SelectionDialogFilter = NStr("ru = 'Изображения';
													|en = 'Pictures';") + "|*.bmp;*.png;*.jpg";
	CommonFieldParameters.MaximumSize = 2;
	CommonFieldParameters.ShowCommandBar = False;

	FieldParameters = FilesOperations.FileField();
	FillPropertyValues(FieldParameters, CommonFieldParameters);
	FieldParameters.Location  = "CompanySeal";
	FieldParameters.DataPath = "Object.CompanySeal";
	ItemsToAdd1.Add(FieldParameters);

	FieldParameters = FilesOperations.FileField();
	FillPropertyValues(FieldParameters, CommonFieldParameters);
	FieldParameters.Location  = "CEOSignature";
	FieldParameters.DataPath = "Object.CEOSignature";
	ItemsToAdd1.Add(FieldParameters);

	FieldParameters = FilesOperations.FileField();
	FillPropertyValues(FieldParameters, CommonFieldParameters);
	FieldParameters.Location  = "ChiefAccountantSignature";
	FieldParameters.DataPath = "Object.ChiefAccountantSignature";
	ItemsToAdd1.Add(FieldParameters);

	FieldParameters = FilesOperations.FileField();
	FillPropertyValues(FieldParameters, CommonFieldParameters);
	FieldParameters.Location  = "OrganizationSLogoForAnElectronicSignatureStamp";
	FieldParameters.DataPath = "Object.OrganizationSLogoForAnElectronicSignatureStamp";
	ItemsToAdd1.Add(FieldParameters);

	FilesOperations.OnCreateAtServer(ThisObject, ItemsToAdd1);
	// End StandardSubsystems.StoredFiles

	If Common.IsMobileClient() Then
		Items.DescriptionFull.TitleLocation = FormItemTitleLocation.Top;

		Items.MainGrouping.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;

		Items.Main_Page.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
	EndIf;

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManager = Common.CommonModule("ContactsManager");
		ModuleContactsManager.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	
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
	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManager = Common.CommonModule("ContactsManager");
		ModuleContactsManager.FillCheckProcessingAtServer(ThisObject, Object, Cancel);
	EndIf;
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManager = Common.CommonModule("ContactsManager");
		ModuleContactsManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	EndIf;

	RefreshInterface = CurrentObject.IsNew() And Not GetFunctionalOption("_DemoUseMultipleCompanies");
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	If RefreshInterface Then
		RefreshInterface();
	EndIf;

	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	Notify("Write_Organization", New Structure, Object.Ref);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

	DetermineIndividualEntrepreneurFieldAvailability(False);
	
	// StandardSubsystems.StoredFiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.StoredFiles

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.StoredFiles
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.StoredFiles

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
Procedure PrefixOnChange(Item)
	If StrFind(Object.Prefix, "-") > 0 Then
		ShowMessageBox(Undefined, NStr("ru = 'Нельзя в префиксе организации использовать символ ""-"".';
													|en = 'Cannot Be in the prefix organization use character ""-"".';"));
		Object.Prefix = StrReplace(Object.Prefix, "-", "");
	EndIf;
EndProcedure

&AtClient
Procedure BusinessEntityCompanyKindOnChange(Item)
	DetermineIndividualEntrepreneurFieldAvailability();
EndProcedure

&AtClient
Procedure CRTROnChange(Item)
	CRTROnChangeAtServer();
EndProcedure

&AtClient
Procedure RegistrationCountryChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ContactsManagerClient.WorldCountryChoiceProcessing(Item, ValueSelected, StandardProcessing);
EndProcedure

// StandardSubsystems.StoredFiles

&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters,
		StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters,
		StandardProcessing);

EndProcedure

// End StandardSubsystems.StoredFiles

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.StoredFiles
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.StoredFiles

&AtClient
Procedure ShowInstructionOnHowToCreateFacsimileSignatureAndSeal(Command)
	PrintManagementClient.ShowInstructionOnHowToCreateFacsimileSignatureAndSeal();
EndProcedure

&AtClient
Procedure AllowDenyEditing(Command)

	ReadOnly = Not ReadOnly;

	If ReadOnly Then
		Items.FormAllowDenyEditing.Title = NStr("ru = 'Разрешить редактирование';
																		|en = 'Allow editing';");
	Else
		Items.FormAllowDenyEditing.Title = NStr("ru = 'Запретить редактирование';
																		|en = 'Deny editing';");
	EndIf;

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure DetermineIndividualEntrepreneurFieldAvailability(SetValue = True)
	Items.IndividualEntrepreneur.Enabled = (CompanyType = 1);

	If SetValue Then
		If CompanyType = 0 Then
			Object.IndividualEntrepreneur = Undefined;
		EndIf;
	EndIf;
EndProcedure

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

// StandardSubsystems.ContactInformation

&AtClient
Procedure Attachable_ContactInformationOnChange(Item)
	If CommonClient.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManagerClient = CommonClient.CommonModule(
			"ContactsManagerClient");
		ModuleContactsManagerClient.StartChanging(ThisObject, Item);
	EndIf;
EndProcedure

// Parameters:
//   Item - FormField
//
&AtClient
Procedure Attachable_ContactInformationStartChoice(Item, ChoiceData, StandardProcessing)

	If CommonClient.SubsystemExists("StandardSubsystems.ContactInformation") Then

		OpeningParameters = New Structure;

		Filter = New Structure("AttributeName", Item.Name);
		Rows = ContactInformationAdditionalAttributesDetails.FindRows(Filter);  // See ContactsManagerClientServer.DescriptionOfTheContactInformationOnTheForm
		RowData = ?(Rows.Count() = 0, Undefined, Rows[0]);
		If RowData <> Undefined Then
			AddCountryToOpenParameters(OpeningParameters, RowData.Kind, Object.RegistrationCountry);
		EndIf;

		ModuleContactsManagerClient = CommonClient.CommonModule(
			"ContactsManagerClient");
		ModuleContactsManagerClient.StartSelection(ThisObject, Item,, StandardProcessing,
			OpeningParameters);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_ContactInformationOnClick(Item, StandardProcessing)
	If CommonClient.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManagerClient = CommonClient.CommonModule(
			"ContactsManagerClient");
		ModuleContactsManagerClient.StartSelection(ThisObject, Item,, StandardProcessing);
	EndIf;
EndProcedure

// Parameters:
//   Item - FormField
//   StandardProcessing - Boolean
//
&AtClient
Procedure Attachable_ContactInformationClearing(Item, StandardProcessing)
	If CommonClient.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManagerClient = CommonClient.CommonModule(
			"ContactsManagerClient");
		ModuleContactsManagerClient.StartClearing(ThisObject, Item.Name);
	EndIf;
EndProcedure


// Parameters:
//   Command - FormCommand
//
&AtClient
Procedure Attachable_ContactInformationExecuteCommand(Command)
	If CommonClient.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManagerClient = CommonClient.CommonModule(
			"ContactsManagerClient");
		ModuleContactsManagerClient.StartCommandExecution(ThisObject, Command.Name);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_ContactInformationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
	StandardProcessing)

	If CommonClient.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManagerClient = CommonClient.CommonModule(
			"ContactsManagerClient");
		ModuleContactsManagerClient.AutoCompleteAddress(Item, Text, ChoiceData,
			DataGetParameters, Waiting, StandardProcessing);
	EndIf;

EndProcedure

// Parameters:
//   Item - FormField
// 	
&AtClient
Procedure Attachable_ContactInformationChoiceProcessing(Item, ValueSelected, StandardProcessing)

	If CommonClient.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManagerClient = CommonClient.CommonModule(
			"ContactsManagerClient");
		ModuleContactsManagerClient.ChoiceProcessing(ThisObject, ValueSelected, Item.Name,
			StandardProcessing);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_ContactInformationURLProcessing(Item,
	FormattedStringURL, StandardProcessing)

	If CommonClient.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManagerClient = CommonClient.CommonModule(
			"ContactsManagerClient");
		ModuleContactsManagerClient.StartURLProcessing(ThisObject, Item,
			FormattedStringURL, StandardProcessing);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_ContinueContactInformationUpdate(Result, AdditionalParameters) Export
	UpdateContactInformation(Result);
EndProcedure

&AtServer
Procedure UpdateContactInformation(Result)

	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManager = Common.CommonModule("ContactsManager");
		ModuleContactsManager.UpdateContactInformation(ThisObject, Object, Result);
	EndIf;
EndProcedure

// End StandardSubsystems.ContactInformation

&AtServer
Procedure CRTROnChangeAtServer()

	If Common.SubsystemExists("StandardSubsystems.CalendarSchedules") Then
		ModuleCalendarSchedules = Common.CommonModule("CalendarSchedules");
		ModuleCalendarSchedules.FillBusinessCalendarInForm(ThisObject,
			"Object.BusinessCalendar", Object.CRTR);
	EndIf;

EndProcedure

&AtServerNoContext
Procedure AddCountryToOpenParameters(OpeningParameters, Kind, RegistrationCountry)

	If Kind = ContactsManager.ContactInformationKindByName("_DemoInternationalCompanyAddress")
		Or Kind = ContactsManager.ContactInformationKindByName("_DemoCompanyPostalAddress") Then
		OpeningParameters.Insert("Country", RegistrationCountry);
	EndIf;

EndProcedure

#EndRegion