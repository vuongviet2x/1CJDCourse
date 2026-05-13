///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The Online Support subsystem.
// CommonModule.LicensingClientGlobal.
//
// Global server procedures and functions for setting up the licensing client.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Opens the OSL form for entering licensing client settings.
// The handler is connected in all modes except for the SaaS mode.
// Attached in the method
// LicensingClientClient.AttachLicensingClientSettingsRequest.
//
// The settings are checked upon the first call
// (before displaying a system legal agreement consent).
//
Procedure OnRequestLicensingClientSettings() Export
	
	If Not OnlineUserSupportClient.ApplicationParameterValue(
		"CoreISL\FirstLicensingClientSettingsRequestProcessed", False) Then
		
		// Processing the first call of licensing client settings request
		OnlineUserSupportClient.SetApplicationParameterValue(
			"CoreISL\FirstLicensingClientSettingsRequestProcessed",
			True);
		
		CheckResult = LicensingClientServerCall.CheckLicensingClientSettings();
		
		OnlineUserSupportClient.SetApplicationParameterValue(
			"CoreISL\EnableOUSRight",
			CheckResult.EnableOUSRight);
		
		If CheckResult.SettingsSynchronized Or Not CheckResult.EnableOUSRight Then
			// Licensing client settings are written from OSL.
			// If the settings are invalid, 1C:Enterprise will re-call the handler
			// to display the licensing client settings prompt dialog.
			// 
			Return;
		EndIf;
		
	EndIf;
	
	If Not OnlineUserSupportClient.ApplicationParameterValue("CoreISL\EnableOUSRight", False) Then
		// Executed only upon the second and subsequent calls of the handler.
		ShowMessageBox(, NStr("ru = 'Недостаточно прав для подключения Интернет-поддержки пользователей.
			|Обратитесь к администратору.';
			|en = 'Insufficient rights to enable online support.
			|Contact the administrator.';"));
		Return;
	EndIf;
	
	NotificationParameter1 = New Structure("IsActivated", False);
	Notify("OnlineUserSupportEnableOnlineUserSupportRegistrationForm", NotificationParameter1);
	
	NotificationParameterCheck = New Structure("IsActivated", False);
	FillPropertyValues(
		NotificationParameterCheck,
		NotificationParameter1);
	
	If NotificationParameterCheck.IsActivated = True Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("LicensingClientSettingsInputMode", True);
	
	OpenForm(
		"CommonForm.CanEnableOnlineSupport",
		FormParameters,
		,
		,
		,
		,
		,
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

#EndRegion