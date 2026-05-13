///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormCommandsEventHandlers

&AtClient
Procedure ResetSettings(Command)
	ResetSettingsServer();
	ShowUserNotification(NStr("ru = 'Резервное копирование';
										|en = 'Backup';"),,
		NStr("ru = 'Настройки резервного копирования сброшены';
			|en = 'Backup settings are reset';"));
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ResetSettingsServer()
	IBBackupServer.SetBackupSettings(Undefined);	
EndProcedure

#EndRegion
