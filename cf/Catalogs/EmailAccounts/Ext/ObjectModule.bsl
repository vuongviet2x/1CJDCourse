///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillObjectWithDefaultValues();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Not UseForSending And Not UseForReceiving Then
		CheckedAttributes.Clear();
		CheckedAttributes.Add("Description");
		Return;
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	If Not UseForSending Then
		NotCheckedAttributeArray.Add("OutgoingMailServer");
	EndIf;
	
	If Not UseForReceiving And ProtocolForIncomingMail = "POP" Then
		NotCheckedAttributeArray.Add("IncomingMailServer");
	EndIf;
		
	If Not IsBlankString(Email) And Not CommonClientServer.EmailAddressMeetsRequirements(Email, True) Then
		Common.MessageToUser(
			NStr("ru = 'Почтовый адрес заполнен неверно.';
				|en = 'Invalid email address.';"), ThisObject, "Email");
		NotCheckedAttributeArray.Add("Email");
		Cancel = True;
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	Common.DeleteDataFromSecureStorage(Ref);
	SetPrivilegedMode(False);
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If User <> TrimAll(User) Then
		User = TrimAll(User);
	EndIf;
	
	If SMTPUser <> TrimAll(SMTPUser) Then
		SMTPUser = TrimAll(SMTPUser);
	EndIf;
	
	If Not AdditionalProperties.Property("DoNotCheckSettingsForChanges") And Not Ref.IsEmpty() Then
		PasswordCheckIsRequired = Catalogs.EmailAccounts.PasswordCheckIsRequired(Ref, ThisObject);
		If PasswordCheckIsRequired Then
			PasswordCheck = Undefined;
			If Not AdditionalProperties.Property("Password", PasswordCheck) Or Not PasswordCorrect(PasswordCheck) Then
				ErrorMessageText = NStr("ru = 'Не подтвержден пароль для изменения настроек почты.';
												|en = 'The password required to change the account settings is not confirmed.';");
				Raise ErrorMessageText;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	PasswordRecoveryAccount = EmailOperationsInternal.AccountSettingsForPasswordRecovery();
	
	If PasswordRecoveryAccount.Used
		 And PasswordRecoveryAccount.AccountEmail = Ref Then
		
		If Users.IsFullUser() Then
			
			SetPrivilegedMode(True);
			SMTPPassword = Common.ReadDataFromSecureStorage(Ref, "SMTPPassword");
			SetPrivilegedMode(False);
			
			Settings = AdditionalAuthenticationSettings.GetPasswordRecoverySettings();
			Settings.SMTPServerAddress = OutgoingMailServer;
			Settings.SenderName   = UserName;
			Settings.UseSSL  = UseSecureConnectionForOutgoingMail;
			Settings.SMTPPassword       = SMTPPassword;
			Settings.SMTPUser = SMTPUser;
			Settings.SMTPPort         = OutgoingMailServerPort;
			
			AdditionalAuthenticationSettings.SetPasswordRecoverySettings(Settings);
		Else
			Raise NStr("ru = 'Настройки почты используются для восстановления пароля и
			|могут быть изменены только администратором.';
			|en = 'Email settings are used for password recovery and
			|can only be changed by the administrator.';");
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure FillObjectWithDefaultValues()
	
	UserName = NStr("ru = '1С:Предприятие';
							|en = '1C:Enterprise';");
	UseForReceiving = False;
	UseForSending = False;
	KeepMessageCopiesAtServer = False;
	KeepMailAtServerPeriod = 0;
	Timeout = 30;
	IncomingMailServerPort = 110;
	OutgoingMailServerPort = 25;
	ProtocolForIncomingMail = "POP";
	
	If Predefined Then
		Description = NStr("ru = 'Системная учетная запись';
							|en = 'System account';");
	EndIf;
	
EndProcedure

Function PasswordCorrect(PasswordCheck)
	SetPrivilegedMode(True);
	Passwords = Common.ReadDataFromSecureStorage(Ref, "Password,SMTPPassword");
	SetPrivilegedMode(False);
	
	PasswordsToCheck1 = New Array;
	If ValueIsFilled(Passwords.Password) Then
		PasswordsToCheck1.Add(Passwords.Password);
	EndIf;
	If ValueIsFilled(Passwords.SMTPPassword) Then
		PasswordsToCheck1.Add(Passwords.SMTPPassword);
	EndIf;
	
	For Each PasswordToCheck In PasswordsToCheck1 Do
		If PasswordCheck <> PasswordToCheck Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf