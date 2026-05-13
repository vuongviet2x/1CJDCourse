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
	
	If Common.DataSeparationEnabled() Then
		Raise NStr("ru = 'Использование Интернет-поддержки недоступно при работе в модели сервиса.';
								|en = 'Online support cannot be used in SaaS.';");
	EndIf;
	
	LicensingClientSettingsInputMode = Parameters.LicensingClientSettingsInputMode;
	If LicensingClientSettingsInputMode Then
		ServersConnectionSettings =
			OnlineUserSupportInternalCached.OUSServersConnectionSettings();
	EndIf;
	
	SetPrivilegedMode(True);
	AuthenticationData = OnlineUserSupport.OnlineSupportUserAuthenticationData();
	If AuthenticationData <> Undefined Then
		Login = AuthenticationData.Login;
	EndIf;
	
	Items.DecorationLabelTechSupport.Visible = Common.SubsystemExists("OnlineUserSupport.MessagesToTechSupportService");
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "OnlineUserSupportEnableOnlineUserSupportRegistrationForm" Then
		If Parameter.IsActivated <> True Then
			If FormOwner = Undefined
				Or WindowOpeningMode <> FormWindowOpeningMode.LockOwnerWindow Then
				Parameter.IsActivated = True;
				AttachIdleHandler("ActivateThisForm", 0.1, True);
			ElsIf ThisObject.FormOwner <> Undefined Then
				Parameter.IsActivated = True;
				AttachIdleHandler("ActivateOwner", 0.1, True);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationLabelConnectionURLProcessing(
		Item,
		FormattedStringURL,
		StandardProcessing)
	
	If FormattedStringURL = "action:openPortal" Then
		StandardProcessing = False;
		OnlineUserSupportClient.OpenPortalMainPage();
	EndIf;
	
EndProcedure

&AtClient
Procedure PasswordOnChange(Item)
	
	OnlineUserSupportClient.OnChangeSecretData(Item);
	
EndProcedure

&AtClient
Procedure PasswordStartChoice(Item, ChoiceData, StandardProcessing)
	
	OnlineUserSupportClient.ShowSecretData(
		ThisObject,
		Item,
		"Password");
	
EndProcedure

&AtClient
Procedure PasswordRecoveryLabelAuthorizationClick(Item)
	
	OnlineUserSupportClient.OpenPasswordRecoveryPage();
	
EndProcedure

&AtClient
Procedure NoUsernameAndPasswordAuthorizationLabelClick(Item)
	
	OnlineUserSupportClient.OpenNewUserRegistrationPage();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Connect(Command)
	
	If Not FillUsernameAndPasswordCorrectly() Then
		Return;
	EndIf;
	
	If ServersConnectionSettings = Undefined Then
		ServersConnectionSettings = OnlineUserSupportClient.ServersConnectionSettings();
	EndIf;
	
	Status(, , NStr("ru = 'Подключение Интернет-поддержки...';
						|en = 'Enabling online support…';"));
	AuthenticationResult =
		AuthenticateUser(
			TrimAll(Login),
			Password,
			True,
			SaveWithoutCheck);
	Status();
	
	If IsBlankString(AuthenticationResult.ErrorCode) Then
		NotificationParameters = New Structure("Login, Password", Login, "");
		Close(NotificationParameters);
		Notify("OnlineSupportEnabled", NotificationParameters);
	ElsIf AuthenticationResult.ErrorCode = "InvalidUsernameOrPassword" Then
		ShowMessageBox(, AuthenticationResult.ErrorMessage);
	Else
		
		// A network error or another error. In this case:
		// - The user is shown a warning about invalid credentials.
		//  - The username and password are saved in the app (see the "AuthenticateUser" method).
		//  
		
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Логин и пароль сохранены в программе, но проверка корректности
				|логина и пароля не выполнена из-за ошибки:
				|%1';
				|en = 'The username and the password are saved to the application
				|but not validated due to an error:
				|%1';"),
			AuthenticationResult.ErrorMessage);
		
		ShowMessageBox(
			New NotifyDescription("OnUsernameAndPasswordValidityCheckErrorMessage", ThisObject),
			WarningText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationLabelTechSupportURLProcessing(
		Item,
		FormattedStringURL,
		StandardProcessing)
	
	If FormattedStringURL = "action:openSupport" Then
		
		StandardProcessing = False;
		
		Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не получается подключить Интернет-поддержку пользователей.
				|Для подключения указывается логин %1.';
				|en = 'Cannot enable online support.
				|Enter the %1 username.';"),
			Items.Login.EditText);
		
		If CommonClient.SubsystemExists("OnlineUserSupport.MessagesToTechSupportService") Then
			
			TheModuleOfTheMessageToTheTechnicalSupportServiceClientServer =
				CommonClient.CommonModule("MessagesToTechSupportServiceClientServer");
			MessageData = TheModuleOfTheMessageToTheTechnicalSupportServiceClientServer.MessageData();
			MessageData.Recipient = "webIts";
			MessageData.Subject = NStr("ru = 'Интернет-поддержка. Подключение Интернет-поддержки';
										|en = 'Online support. Enable online support';");
			MessageData.Message = Message;
			MessageData.CannedResponseSearchSettings.Text = NStr("ru = 'Превышено количество попыток аутентификации';
																		|en = 'Exceeded maximum number of authentication attempts';");
			
			TheModuleOfTheMessageToTheTechnicalSupportServiceClient =
				CommonClient.CommonModule("MessagesToTechSupportServiceClient");
			TheModuleOfTheMessageToTheTechnicalSupportServiceClient.SendMessage(
				MessageData);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Common.

&AtClient
Function FillUsernameAndPasswordCorrectly()
	
	Result = OnlineUserSupportClientServer.VerifyAuthenticationData(
		New Structure("Login, Password",
		Login, Password));
	
	If Result.Cancel Then
		CommonClient.MessageToUser(
			Result.ErrorMessage,
			,
			Result.Field);
	EndIf;
	
	Return Not Result.Cancel;
	
EndFunction

&AtServerNoContext
Procedure SaveAuthenticationData(Val AuthenticationData)
	
	// Checking the right to write data
	If Not OnlineUserSupport.RightToWriteOUSParameters() Then
		Raise NStr("ru = 'Недостаточно прав для записи данных аутентификации Интернет-поддержки.';
								|en = 'Insufficient rights to save authentication credentials for online support.';");
	EndIf;
	
	// Write data.
	SetPrivilegedMode(True);
	OnlineUserSupport.ServiceSaveAuthenticationData(AuthenticationData);
	
EndProcedure

&AtServerNoContext
Function AuthenticateUser(
		Val Login,
		Val Password,
		Val RememberPassword,
		Val SaveWithoutCheck)
	
	If Not SaveWithoutCheck Then
		AuthenticationResult =
			OnlineUserSupport.CheckUsernameAndPassword(
				Login,
				Password);
	Else
		AuthenticationResult = New Structure(
			"ErrorCode, ErrorMessage, Result",
			"",
			"",
			True);
	EndIf;
	
	If AuthenticationResult.ErrorCode <> "InvalidUsernameOrPassword" Then
		SaveAuthenticationData(
			?(RememberPassword, New Structure("Login, Password", Login, Password), Undefined));
	EndIf;
	
	Return AuthenticationResult;
	
EndFunction

&AtClient
Procedure OnUsernameAndPasswordValidityCheckErrorMessage(AdditionalParameters) Export
	
	NotificationParameters = New Structure("Login, Password", Login, "");
	Close(NotificationParameters);
	Notify("OnlineSupportEnabled", NotificationParameters);
	
EndProcedure

&AtClient
Procedure ActivateThisForm()
	
	ThisObject.Activate();
	
EndProcedure

&AtClient
Procedure ActivateOwner()
	
	ThisObject.FormOwner.Activate();
	
EndProcedure

#EndRegion
