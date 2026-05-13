///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2021, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The form supports only the API method.
// Internal methods and internal API methods are not acceptable.
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not AccessRight("Update", Metadata.InformationRegisters.UserPrintTemplates) Then
		Items.SetActionOnChoosePrintFormTemplate.Visible = False;
	EndIf;
	
	IsWebClient = Common.IsWebClient();
	
	VerifyAccessRights("SaveUserData", Metadata);
	
	SuggestOpenWebSiteOnStart = Common.CommonSettingsStorageLoad(
		"UserCommonSettings", 
		"SuggestOpenWebSiteOnStart",
		False);

	// StandardSubsystems.Core
	If Not IsWebClient Then
		Items.WebClientOperations.Visible = False;
	EndIf;
	AskConfirmationOnExit = StandardSubsystemsServer.AskConfirmationOnExit();
	ShowInstalledApplicationUpdatesWarning = StandardSubsystemsServer.ShowInstalledApplicationUpdatesWarning();
	
	Items.SuggestOpenWebSiteOnStart.ExtendedTooltip.Title = 
		StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Демонстрирует открытие диалогов, блокирующих запуск приложения, из общего модуля %1.';
																	|en = 'Demonstrates the dialog boxes that lock the startup (from the common module %1).';"),
		"CommonClientOverridable");
	
	// Determine the operating date settings.
	WorkingDateValue = Common.UserWorkingDate();
	If ValueIsFilled(WorkingDateValue) Then
		UseCurrentDeviceDate = 0;
	Else
		UseCurrentDeviceDate = 1;
		Items.WorkingDateValue.Enabled = False;
	EndIf;
	
	// End StandardSubsystems.Core
	
	// StandardSubsystems.Users
	AuthorizedUser = Users.AuthorizedUser();
	If AccessRight("View", Metadata.FindByType(TypeOf(AuthorizedUser))) Then
		Items.UserInfo.Title = AuthorizedUser;
	Else
		Items.AccountGroup.Visible = False;
	EndIf;
	// End StandardSubsystems.Users
	
	// StandardSubsystems.StoredFiles
	FilesOperationSettings = FilesOperations.FilesOperationSettings();
	PromptForEditModeOnOpenFile = FilesOperationSettings.PromptForEditModeOnOpenFile;
	
	If FilesOperationSettings.ActionOnDoubleClick = "OpenFile" Then
		ActionOnDoubleClick = Enums.DoubleClickFileActions.OpenFile;
		Items.PromptForEditModeOnOpenFile.Enabled = True;
	Else
		ActionOnDoubleClick = Enums.DoubleClickFileActions.OpenCard;
		Items.PromptForEditModeOnOpenFile.Enabled = False;
	EndIf;
	
	If FilesOperationSettings.FileVersionsComparisonMethod = "MicrosoftOfficeWord" Then
		FileVersionsComparisonMethod = Enums.FileVersionsComparisonMethods.MicrosoftOfficeWord;
	Else
		FileVersionsComparisonMethod = Enums.FileVersionsComparisonMethods.OpenOfficeOrgWriter;
	EndIf;
	
	ShowTooltipsOnEditFiles = FilesOperationSettings.ShowTooltipsOnEditFiles;
	
	ShowFileNotModifiedFlag = FilesOperationSettings.ShowFileNotModifiedFlag;
	
	ShowLockedFilesOnExit = FilesOperationSettings.ShowLockedFilesOnExit;
	
	ShowSizeColumn = FilesOperationSettings.ShowSizeColumn;
	
	// Populate file open settings.
	SettingString = OpenFileSettings.Add();
	SettingString.FileType = Enums.BuiltInEditorFileTypes.TextFiles;
	
	SettingString.Extension = FilesOperationSettings.TextFilesExtension;
	
	SettingString.OpeningMethod = FilesOperationSettings.TextFilesOpeningMethod;
	
	// End StandardSubsystems.StoredFiles
	
	// StandardSubsystems.DigitalSignature
	Items.DigitalSignatureAndEncryptionSettings.Visible =
		AccessRight("SaveUserData", Metadata);
	// End StandardSubsystems.DigitalSignature
	
	If Common.IsMobileClient() Then
		Items.WriteAndClose.Representation = ButtonRepresentation.Picture;
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Items.ProxyServerCustomSettings.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.UserReminders") Then
		ModuleUserReminder = Common.CommonModule("UserReminders");
		Items.ReminderSettings.Visible = ModuleUserReminder.UsedUserReminders();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
#If WebClient Then
	UpdateWorkingGroupInWebClient();
#EndIf
	// StandardSubsystems.StoredFiles
	Items.ScanningSettings.Visible = FilesOperationsClient.ScanAvailable();
	// End StandardSubsystems.StoredFiles
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New NotifyDescription("WriteAndCloseNotification", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

////////////////////////////////////////////////////////////////////////////////
// Main page

&AtClient
Procedure UserInfo(Command)
	
	ShowValue(, AuthorizedUser);
	
EndProcedure

&AtClient
Procedure ProxyServerCustomSettings(Command)
	
	GetFilesFromInternetClient.OpenProxyServerParametersForm(New Structure("ProxySettingAtClient", True));
	
EndProcedure

&AtClient
Procedure InstallFileSystemExtensionAtClient(Command)
	
	Notification = New NotifyDescription("InstallFileSystemExtensionAtClientCompletion", ThisObject);
	BeginInstallFileSystemExtension(Notification);
	
EndProcedure

&AtClient
Procedure UpdateWorkingGroupInWebClient()
	
	Notification = New NotifyDescription("UpdateWorkingGroupInWebClientCompletion", ThisObject);
	FileSystemClient.AttachFileOperationsExtension(Notification);
	
EndProcedure

&AtClient
Procedure UpdateWorkingGroupInWebClientCompletion(Attached, AdditionalParameters) Export
	Items.GroupPages.CurrentPage = ?(Attached, Items.ExtensionInstalledGroup, 
		Items.ExtensionNotInstalledGroup);
EndProcedure

&AtClient
Procedure UseCurrentDeviceDateOnChange(Item)
	
	If UseCurrentDeviceDate = 1 Then
		WorkingDateValue = '0001-01-01';
	Else
		WorkingDateValue = CurrentDate(); // ACC:143 Current machine date is required.
	EndIf;
	Items.WorkingDateValue.Enabled = UseCurrentDeviceDate = 0;
	Modified = True;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Organizer page

////////////////////////////////////////////////////////////////////////////////
// Print page

&AtClient
Procedure SetActionOnChoosePrintFormTemplate(Command)
	
	PrintManagementClient.SetActionOnChoosePrintFormTemplate();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// StoredFiles page.

&AtClient
Procedure WorkingDirectorySettings(Command)
	
	NotifyDescription = New NotifyDescription("WorkingDirectorySettingFollowUp", ThisObject);
	FileSystemClient.AttachFileOperationsExtension(NotifyDescription,, False);
	
EndProcedure

&AtClient
Procedure ScanningSettings(Command)
	
	FilesOperationsClient.OpenScanSettingForm();
	
EndProcedure

&AtClient
Procedure DigitalSignatureAndEncryptionSettings(Command)
	
	DigitalSignatureClient.OpenDigitalSignatureAndEncryptionSettings();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	SaveSettings_And_CloseForm();
	
EndProcedure

&AtClient
Procedure ActionOnDoubleClickOnChange(Item)
	Items.PromptForEditModeOnOpenFile.Enabled = 
		(ActionOnDoubleClick = PredefinedValue("Enum.DoubleClickFileActions.OpenFile"));
EndProcedure

&AtClient
Procedure ReminderSettings(Command)
	ModuleUserReminderClient = CommonClient.CommonModule("UserRemindersClient");
	ModuleUserReminderClient.OpenSettings();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SaveSettings_And_CloseForm()
	
	Settings = New Structure;
	Settings.Insert("RemindAboutFileSystemExtensionInstallation", RemindAboutFileSystemExtensionInstallation);
	Settings.Insert("AskConfirmationOnExit", AskConfirmationOnExit);
	Settings.Insert("ShowInstalledApplicationUpdatesWarning", ShowInstalledApplicationUpdatesWarning);
	
	PersonalFilesOperationsSettings = SpecifySettingsAtServer(Settings);
	Settings.Insert("PersonalFilesOperationsSettings ", PersonalFilesOperationsSettings);
	
	CommonClient.SavePersonalSettings(Settings);
	
	CommonClient.RefreshApplicationInterface();
	Modified = False;
	Close();
	
EndProcedure

&AtClient
Procedure WriteAndCloseNotification(Result, Context) Export
	SaveSettings_And_CloseForm();
EndProcedure

&AtClient
Procedure InstallFileSystemExtensionAtClientCompletion(AdditionalParameters) Export
	
	UpdateWorkingGroupInWebClient();
	
EndProcedure

&AtServer
Function SpecifySettingsAtServer(Settings)
	
	// StandardSubsystems.Core
	
	// Operating date.
	If UseCurrentDeviceDate = 1 Then
		WorkDateValueForSaving = '0001-01-01';
	Else
		WorkDateValueForSaving = WorkingDateValue;
	EndIf;
	Common.SetUserWorkingDate(WorkDateValueForSaving);
	
	Common.SavePersonalSettings(Settings);
	// End StandardSubsystems.Core
	
	// StandardSubsystems.StoredFiles
	FilesOperationSettings = New Structure;
	FilesOperationSettings.Insert("ActionOnDoubleClick", ActionOnDoubleClick);
	FilesOperationSettings.Insert("PromptForEditModeOnOpenFile", PromptForEditModeOnOpenFile);
	FilesOperationSettings.Insert("ShowTooltipsOnEditFiles", ShowTooltipsOnEditFiles);
	FilesOperationSettings.Insert("ShowLockedFilesOnExit", ShowLockedFilesOnExit);
	FilesOperationSettings.Insert("ShowSizeColumn", ShowSizeColumn);
	FilesOperationSettings.Insert("ShowFileNotModifiedFlag", ShowFileNotModifiedFlag);
	FilesOperationSettings.Insert("FileVersionsComparisonMethod", FileVersionsComparisonMethod);
	
	If OpenFileSettings.Count() >= 1 Then
		FilesOperationSettings.Insert("TextFilesExtension", OpenFileSettings[0].Extension);
		FilesOperationSettings.Insert("TextFilesOpeningMethod", OpenFileSettings[0].OpeningMethod);
	EndIf;
	
	FilesOperations.SaveFilesOperationSettings(FilesOperationSettings);
	// End StandardSubsystems.StoredFiles
	
	SaveCollectionProperties("UserCommonSettings", ThisObject,
		"SuggestOpenWebSiteOnStart");
	
	RefreshReusableValues();
	
	Return FilesOperations.FilesOperationSettings();
	
EndFunction

&AtServer
Procedure SaveCollectionProperties(ObjectKey, Collection, AttributesNames)
	AttributesStructure1 = New Structure(AttributesNames);
	FillPropertyValues(AttributesStructure1, Collection);
	For Each KeyAndValue In AttributesStructure1 Do
		Common.CommonSettingsStorageSave(ObjectKey, KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
EndProcedure

&AtClient
Procedure WorkingDirectorySettingFollowUp(Result, AdditionalParameters) Export
	If Result = True Then
		FilesOperationsClient.OpenWorkingDirectorySettingsForm();
	EndIf;
EndProcedure

#EndRegion
