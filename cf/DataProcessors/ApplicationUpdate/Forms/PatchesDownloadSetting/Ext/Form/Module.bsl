///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IsSystemAdministrator = GetApplicationUpdates.IsSystemAdministrator();
	
	Items.LabelContactYourAdministrator.Visible = Not IsSystemAdministrator;
	Items.FormRemindLater.DefaultButton      = Not IsSystemAdministrator;
	Items.FormEnable.Visible                    = IsSystemAdministrator;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Enable(Command)
	
	GetApplicationUpdatesServerCall.EnableDisableAutomaticPatchesInstallation(True);
	
	Close();
	
EndProcedure

&AtClient
Procedure RemindLater(Command)
	
	DateOfInforming = BegOfDay(CommonClient.SessionDate() + 2592000);	// CurrentDate + 30 days
	
	CommonServerCall.CommonSettingsStorageSave(
		GetApplicationUpdatesClientServer.CommonSettingsID(),
		GetApplicationUpdatesClientServer.SettingKeyPatchDownloadEnablementNotificationDate(),
		DateOfInforming);
	
	Close();
	
EndProcedure

&AtClient
Procedure DontShowAgain(Command)
	
	CommonServerCall.CommonSettingsStorageSave(
		GetApplicationUpdatesClientServer.CommonSettingsID(),
		GetApplicationUpdatesClientServer.SettingKeyPatchDownloadEnablementNotificationDate(),
		'39991231');
	
	Close();
	
EndProcedure

#EndRegion