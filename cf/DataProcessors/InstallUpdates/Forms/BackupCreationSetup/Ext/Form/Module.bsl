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
	
	FillPropertyValues(Object, Parameters);
	UpdateControlsStates(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BackupDirectoryFieldStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Dialog = New FileDialog(FileDialogMode.ChooseDirectory);
	Dialog.Directory = Object.IBBackupDirectoryName;
	Dialog.CheckFileExist = True;
	Dialog.Title = NStr("ru = 'Выбор каталога резервной копии ИБ';
							|en = 'Select infobase backup directory';");
	If Dialog.Choose() Then
		Object.IBBackupDirectoryName = Dialog.Directory;
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateDataBackupOnChange(Item)
	UpdateControlsStates(ThisObject);
EndProcedure

&AtClient
Procedure RestoreInfobaseOnChange(Item)
	UpdateManualRollbackLabel(ThisObject);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	Cancel = False;
	If Object.CreateDataBackup = 2 Then
		File = New File(Object.IBBackupDirectoryName);
		Cancel = Not File.Exists() Or Not File.IsDirectory();
		If Cancel Then
			ShowMessageBox(, NStr("ru = 'Укажите существующий каталог для сохранения резервной копии ИБ.';
											|en = 'Please specify an existing directory for storing the infobase backup.';"));
			CurrentItem = Items.BackupDirectoryField;
		EndIf;
	EndIf;
	If Not Cancel Then
		SelectionResult = New Structure;
		SelectionResult.Insert("CreateDataBackup",           Object.CreateDataBackup);
		SelectionResult.Insert("IBBackupDirectoryName",       Object.IBBackupDirectoryName);
		SelectionResult.Insert("RestoreInfobase", Object.RestoreInfobase);
		Close(SelectionResult);
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure UpdateControlsStates(Form)
	
	Form.Items.BackupDirectoryField.AutoMarkIncomplete = (Form.Object.CreateDataBackup = 2);
	Form.Items.BackupDirectoryField.Enabled = (Form.Object.CreateDataBackup = 2);
	InfoPages = Form.Items.InfoPanel.ChildItems;
	CreateDataBackup = Form.Object.CreateDataBackup;
	InfoPanel = Form.Items.InfoPanel;
	If CreateDataBackup = 0 Then // Do not create a backup.
		Form.Object.RestoreInfobase = False;
		InfoPanel.CurrentPage = InfoPages.NoRollback;
	ElsIf CreateDataBackup = 1 Then // Create a temporary backup.
		InfoPanel.CurrentPage = InfoPages.ManualRollback;
		UpdateManualRollbackLabel(Form);
	ElsIf CreateDataBackup = 2 Then // Create a backup in the specified directory.
		Form.Object.RestoreInfobase = True;
		InfoPanel.CurrentPage = InfoPages.AutomaticRollback;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateManualRollbackLabel(Form)
	LabelPages = Form.Items.ManualRollbackLabelsPages.ChildItems;
	Form.Items.ManualRollbackLabelsPages.CurrentPage = ?(Form.Object.RestoreInfobase,
		LabelPages.Restore, LabelPages.DontRestore);
EndProcedure

#EndRegion
