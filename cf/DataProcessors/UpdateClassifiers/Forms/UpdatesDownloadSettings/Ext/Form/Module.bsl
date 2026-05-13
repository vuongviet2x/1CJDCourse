///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormCommandsEventHandlers

&AtClient
Procedure Enable(Command)
	
	ClassifiersOperationsServerCall.EnableClassifierAutoUpdateFromService();
	Close();
	
EndProcedure

&AtClient
Procedure RemindLater(Command)
	
	// Remind in 7 days.
	DateOfInforming = BegOfDay(CommonClient.SessionDate() + 604800);
	
	CommonServerCall.CommonSettingsStorageSave(
		ClassifiersOperationsClientServer.CommonSettingsID(),
		ClassifiersOperationsClientServer.DateOfNotificationOnGetUpdatesEnabledSettingKey(),
		DateOfInforming);
	
	Close();
	
EndProcedure

&AtClient
Procedure DontShowAgain(Command)
	
	CommonServerCall.CommonSettingsStorageSave(
		ClassifiersOperationsClientServer.CommonSettingsID(),
		ClassifiersOperationsClientServer.DateOfNotificationOnGetUpdatesEnabledSettingKey(),
		'39991231');
	
	Close();
	
EndProcedure

#EndRegion