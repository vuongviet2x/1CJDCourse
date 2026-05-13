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

	// StandardSubsystems.StoredFiles
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesHyperlink = FilesOperations.FilesHyperlink();
	SettingsOfFileManagementInForm = FilesOperations.SettingsOfFileManagementInForm();
	SettingsOfFileManagementInForm.DuplicateAttachedFiles = True;
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink, SettingsOfFileManagementInForm);
	// End StandardSubsystems.StoredFiles

EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.StoredFiles
	FilesOperations.OnWriteAtServer(Cancel, CurrentObject, WriteParameters, ThisObject);
	// End StandardSubsystems.StoredFiles

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

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
Procedure ProjectRegulationsStartChoice(Item, ChoiceData, StandardProcessing)

	FilesOperationsClient.OpenFileChoiceForm(Object.Ref, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure ProjectRegulationsOpening(Item, StandardProcessing)

	FilesOperationsClient.OpenFileForm(Object.ProjectRegulations, StandardProcessing);

EndProcedure

// StandardSubsystems.StoredFiles
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters,
		StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters,
		StandardProcessing);

EndProcedure
// End StandardSubsystems.StoredFiles

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteEmail1(Command)

	MessageParameters = New Structure;
	If ValueIsFilled(Object.ProjectRegulations) Then
		MessageParameters.Insert("ProjectRegulations", Object.ProjectRegulations);
	EndIf;
	MessageParameters.Insert("UUID", UUID);
	MessageParameters.Insert("Project", Object.Ref);

	Notification = New NotifyDescription("AfterSendMessage", ThisObject);
	MessageTemplatesClient.GenerateMessage(Object.Organization, "MailMessage", Notification, Object.Department,
		MessageParameters);

EndProcedure

// StandardSubsystems.StoredFiles
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.StoredFiles

#EndRegion

#Region Private

&AtClient
Procedure AfterSendMessage(Result, AdditionalParameters) Export

	If Result <> True Then
		ShowMessageBox(, NStr("ru = 'Не удалось отправить сформированное письмо. Подробнее см. в журнале регистрации.';
										|en = 'Failed to send a generated mail. See the event log for details.';"));
	EndIf;

EndProcedure

#EndRegion