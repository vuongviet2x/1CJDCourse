///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Internal

Function SettingFlagShouldMutePromptToMigrateToWebService(SettingObject1, Value = Undefined) Export
	
	If TypeOf(SettingObject1) = Type("String") Then
		Var_Key = "ShouldMutePromptToMigrateToWebService" + SettingObject1;
	Else
		Var_Key = "ShouldMutePromptToMigrateToWebService" + SettingObject1.UUID();
	EndIf;
	
	If Value = Undefined Then
		// Read
		Return Common.CommonSettingsStorageLoad("ApplicationSettings", Var_Key, False,, UserName());
	EndIf;
	
	SettingsDescription = NStr("ru = 'Не предлагать перейти на веб-сервис';
							|en = 'Do not offer to switch to a web service';");
	
	// Write
	Common.CommonSettingsStorageSave("ApplicationSettings", Var_Key, Value, SettingsDescription, UserName());
	
EndFunction

#EndRegion