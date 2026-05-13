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
	
	If Common.IsWebClient() Then
		Raise NStr("ru = 'Резервное копирование недоступно в веб-клиенте.';
								|en = 'Web client does not support data backup.';");
	EndIf;
	
	If Not Common.IsWindowsClient() Then
		Raise NStr("ru = 'Резервное копирование и восстановление данных необходимо настроить средствами операционной системы или другими сторонними средствами.';
								|en = 'Set up data backup and restore using operating system tools or other third-party tools.';");
	EndIf;
	
	Settings = IBBackupServer.BackupParameters();
	DisableNotifications = Settings.BackupConfigured;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	Settings = ApplicationParameters["StandardSubsystems.IBBackupParameters"];
	Settings.NotificationParameter1 = ?(DisableNotifications, "DontNotify", "NotConfiguredYet");
	
	If DisableNotifications Then
		IBBackupClient.DisableBackupIdleHandler();
	Else
		IBBackupClient.AttachIdleBackupHandler();
	EndIf;
	
	SetBackupSettings();
	Notify("BackupSettingsFormClosed");
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetBackupSettings()
	
	Settings = IBBackupServer.BackupParameters();
	Settings.BackupConfigured = DisableNotifications;
	Settings.CreateBackupAutomatically = False;
	IBBackupServer.SetBackupSettings(Settings);
	
EndProcedure

#EndRegion
