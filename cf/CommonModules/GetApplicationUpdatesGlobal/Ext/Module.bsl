///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "Application update" subsystem.
// CommonModule.GetApplicationUpdatesGlobal.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Procedure GetApplicationUpdatesCheckForUpdates() Export
	
	GetApplicationUpdatesClient.CheckUpdates();
	
EndProcedure

// Starts after the system startup and prompts the user to enable the automatic patch download and installation.
// 
//
Procedure GetAppUpdates_ShowPatchDownloadSetupTask() Export
	
	ShowUserNotification(
		NStr("ru = 'Установка исправлений (патчей)';
			|en = 'Install patches';"),
		"e1cib/app/DataProcessor.ApplicationUpdate.Form.PatchesDownloadSetting",
		NStr("ru = 'Рекомендуется включить автоматическую загрузку и установку исправлений (патчей).';
			|en = 'We recommend that you enable automatic patch import and installation.';"),
		PictureLib.DialogExclamation,
		UserNotificationStatus.Important);
	
EndProcedure

#EndRegion
