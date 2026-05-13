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
	
	If Common.FileInfobase() Then
		Items.WindowsArchivePath.Title = NStr("ru = 'Для сервера 1С:Предприятия под управлением Microsoft Windows';
													|en = 'For 1C:Enterprise server on Microsoft Windows';"); 
	Else
		Items.WindowsArchivePath.ChoiceButton = False; 
	EndIf;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WindowsArchivePathStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not FilesOperationsInternalClient.FileSystemExtensionAttached1() Then
		FilesOperationsInternalClient.ShowFileSystemExtensionRequiredMessageBox(Undefined);
		Return;
	EndIf;
	
	Dialog = New FileDialog(FileDialogMode.Open);
	
	Dialog.Title                    = NStr("ru = 'Выберите файл';
												|en = 'Select file';");
	Dialog.FullFileName               = ?(WindowsArchivePath = "", "files.zip", WindowsArchivePath);
	Dialog.Multiselect           = False;
	Dialog.Preview      = False;
	Dialog.CheckFileExist  = True;
	Dialog.Filter                       = NStr("ru = 'Архивы zip(*.zip)|*.zip';
												|en = 'ZIP archive (*.zip)|*.zip';");
	
	If Dialog.Choose() Then
		
		WindowsArchivePath = Dialog.FullFileName;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Place(Command)
	
	ClearMessages();
	
	If IsBlankString(WindowsArchivePath) And IsBlankString(PathToArchiveLinux) Then
		Text = NStr("ru = 'Укажите полное имя архива с
		                   |файлами начального образа (файл *.zip)';
							|en = 'Please specify the full name of the archive 
							|with initial image files (a *.zip file).';");
		CommonClient.MessageToUser(Text, , "WindowsArchivePath");
		Return;
	EndIf;
	
	If Not CommonClient.FileInfobase() Then
	
		If Not IsBlankString(WindowsArchivePath) And (Left(WindowsArchivePath, 2) <> "\\" Or StrFind(WindowsArchivePath, ":") <> 0) Then
			ErrorText = NStr("ru = 'Путь к архиву с файлами начального образа
			                         |должен быть в формате UNC (\\servername\resource).';
									|en = 'The path to the archive with initial image files
									|must be in the UNC format (\\servername\resource).';");
			CommonClient.MessageToUser(ErrorText, , "WindowsArchivePath");
			Return;
		EndIf;
	
	EndIf;
	
	AddFilesToVolumes();
	
	NotificationText1 = NStr("ru = 'Размещение файлов из архива с файлами
		|начального образа успешно завершено.';
		|en = 'Files from the initial image archive
		|are stored to volumes.';");
	ShowUserNotification(NStr("ru = 'Размещение файлов';
										|en = 'Store files';"),, NotificationText1);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AddFilesToVolumes()
	
	FilesOperationsInVolumesInternal.AddFilesToVolumes(WindowsArchivePath, PathToArchiveLinux);
	
EndProcedure

#EndRegion
