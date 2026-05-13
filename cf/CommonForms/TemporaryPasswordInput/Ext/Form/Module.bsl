#Region Variables

&AtClient
Var SessionID;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Certificate = Parameters.Certificate; // FormDataStructure - See CryptographyServiceInternalClient.GetSecurityToken 
	
	If Not ValueIsFilled(Certificate) Then
		Cancel = True;
		Return;
	EndIf;
	
	PasswordsDeliveryMethod = "phone";
	
	ProcedureParameters = New Structure("CertificateID", CryptographyServiceInternal.Id(Certificate));
	
	TimeConsumingOperation = CryptographyServiceInternal.ExecuteInBackground(
		"CryptographyServiceInternal.GetSettingsForGettingTemporaryPasswords", ProcedureParameters);
	
	UseToken = DigitalSignatureSaaS.LongTermTokenUsageIsPossible();
	PasswordBeingSent = True;
	Items.GetTempPasswordUsingAnotherMethod.Visible = False;	
	Phone = "...";
	
	Items.ConfigureConfirmation.Title = GetSettingsHeader(UseToken, NStr("ru = 'Изменить получателя';
																									|en = 'Change recipient';"));
	Items.ConfigureConfirmation.ExtendedTooltip.Title = ?(UseToken, 
				NStr("ru = 'Изменить настройки подтверждения операций с ключом';
					|en = 'Change settings of confirming operations with the key';"), "");
	Items.TimeConsumingOperationIndicator.Picture = GetLibraryImage("TimeConsumingOperation16");
	Items.TimeConsumingOperationIndicator2.Picture = GetLibraryImage("TimeConsumingOperation16");

	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SessionID = Undefined;
	Notification = New NotifyDescription("GetSettingsForGettingTemporaryPasswordsAfterExecution", ThisObject);
	CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, TimeConsumingOperation);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PasswordOnChange(Item)
	
	If Items.PasswordGroup.Enabled Then 
		PasswordEditTextChange(Item, Item.EditText, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure PasswordEditTextChange(Item, Text, StandardProcessing)
	
	Password = TrimAll(Text);
	If ValueIsFilled(Password) And StrLen(Password) = 6 Then
		DetachIdleHandler("Attachable_VerifyPassword");
		AttachIdleHandler("Attachable_VerifyPassword", 0.5, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CloseOpen(FormParameters)
	
	DetachIdleHandler("Attachable_VerifyPassword");
	If IsOpen() Then 
		Close(FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ResendPassword(Command)

	Password = Undefined;
	Notification = New NotifyDescription("GetTemporaryPasswordAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, GetPasswordOnServer(True, SessionID));
		
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure Confirm(Command)
	
	DetachIdleHandler("Attachable_VerifyPassword");
	ClearMessages();
	ErrorText = "";
	Password = TrimAll(Password);
	If ValueIsFilled(Password) And StrLen(Password) = 6 Then
		Notification = New NotifyDescription("ConfirmPasswordAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, ConfirmOnServer(SessionID));
		FormControl(ThisObject);
	ElsIf ValueIsFilled(Password) And StrLen(Password) <> 6 Then
		ErrorText = NStr("ru = 'Пароль должен состоять из 6 цифр';
							|en = 'The password must contain 6 digits';");
	Else
		ErrorText = NStr("ru = 'Пароль не указан';
							|en = 'Password is not specified';");
	EndIf;

EndProcedure

&AtClient
Procedure GetTempPasswordUsingAnotherMethod(Command)
	
	If PasswordsDeliveryMethod = "phone" Then
		PasswordsDeliveryMethod = "email";
	Else
		PasswordsDeliveryMethod = "phone";
	EndIf;
	
	ResendPassword(Undefined);
	
	FormControl(ThisObject);

EndProcedure

&AtClient
Procedure ConfigureConfirmation(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Certificate", Certificate);
	If UseToken Then
		FormParameters.Insert("State", "ChangingMethodOfConfirmingCryptoOperation");
	Else
		FormParameters.Insert("State", "ChangingSettingsForGettingTemporaryPasswords");
	EndIf;	
	
	CloseOpen(FormParameters);

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ConfirmPasswordAfterExecution(Result, IncomingContext) Export

	Result = CryptographyServiceInternalClient.GetBackgroundExecutionResult(Result);
	
	If Result.Completed2 Then
		SaveSecurityTokens(Result.ExecutionResult);
		CloseOpen(New Structure("State", "PasswordAccepted"));
	Else
		PasswordBeingChecked = False;
		FormControl(ThisObject);
		
		ExceptionText = ErrorProcessing.DetailErrorDescription(Result.ErrorInfo);
		If StrFind(ExceptionText, "PasswordIsIncorrect") Then
			ErrorText = NStr("ru = 'Указан неверный пароль';
								|en = 'Password is incorrect';");
		ElsIf StrFind(ExceptionText, "ExceededNumberOfAttemptsToEnterPassword") Then
			CloseOpen(New Structure("State, ErrorDescription", "PasswordNotAccepted", NStr("ru = 'Превышен лимит попыток ввода пароля';
																								|en = 'Exceeded number of attempts to enter password';"))); 
		ElsIf StrFind(ExceptionText, "PasswordExpired") Then
			CloseOpen(New Structure("State, ErrorDescription", "PasswordNotAccepted", NStr("ru = 'Срок действия пароля истек';
																								|en = 'Password expired';")));
		Else 
			CloseOpen(New Structure("State, ErrorDescription", "PasswordNotAccepted", NStr("ru = 'Выполнение операции временно невозможно';
																								|en = 'Operation temporarily cannot be executed';")));
		EndIf;		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure SaveSecurityTokens(Val SecurityTokens)
	
	SetPrivilegedMode(True);
	CryptographyServiceInternal.SaveSecurityTokens(SecurityTokens);
	SetPrivilegedMode(False);
	
EndProcedure

&AtClient
Procedure GetSettingsForGettingTemporaryPasswordsAfterExecution(Result, IncomingContext) Export
	
	Result = CryptographyServiceInternalClient.GetBackgroundExecutionResult(Result);
	
	If Result.Completed2 Then
		Phone          = Result.ExecutionResult.Phone;
		Email = Result.ExecutionResult.Email;
		
		Recipient = Phone;
		
		Notification = New NotifyDescription("GetTemporaryPasswordAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, GetPasswordOnServer());
	Else
		ErrorData = GetErrorDetails(Result.ErrorInfo);
		Notification = New NotifyDescription("AfterDisplayingWarning", ThisObject, ErrorData);
		ShowMessageBox(Notification, ErrorData.Information);		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterDisplayingWarning(IncomingContext) Export
	
	CloseOpen(IncomingContext);
	
EndProcedure

&AtClient
Procedure GetTemporaryPasswordAfterExecution(Result, IncomingContext) Export
	
	Result = CryptographyServiceInternalClient.GetBackgroundExecutionResult(Result);
	
	If Result.Completed2 Then
		Timer = Result.ExecutionResult.DelayBeforeResending;
		PasswordSent = True;
		PasswordBeingSent = False;
		If Result.ExecutionResult.Property("SessionID") Then 
			SessionID = Result.ExecutionResult.SessionID;
		EndIf;
		StartCountdown();
		FormControl(ThisObject);
		AttachIdleHandler("Attachable_ActivatePasswordField", 0.1, True);
	Else
		Notification = New NotifyDescription("AfterDisplayingWarning", ThisObject);
		ShowMessageBox(Notification, NStr("ru = 'Сервис отправки SMS-сообщений временно недоступен. Повторите попытку позже.';
												|en = 'SMS service is temporarily unavailable. Try again later.';"));
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_VerifyPassword()
	
	Confirm(Undefined);
	
EndProcedure

&AtClient
Procedure Attachable_ActivatePasswordField()
	
	Password = Undefined;
	Items.Password.UpdateEditText();
	CurrentItem = Items.Password;
	
EndProcedure

&AtServer
Function GetPasswordOnServer(Repeatedly = False, SessionID = Undefined)
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("CertificateID", CryptographyServiceInternal.Id(Certificate));
	ProcedureParameters.Insert("Resending", Repeatedly);
	ProcedureParameters.Insert("Type", PasswordsDeliveryMethod);
	ProcedureParameters.Insert("SessionID", SessionID);
	
	Return CryptographyServiceInternal.ExecuteInBackground(
		"CryptographyServiceInternal.GetTemporaryPassword", ProcedureParameters);
	
EndFunction

&AtClient
Procedure StartCountdown()
	
	AttachIdleHandler("Attachable_HandlerCountdown", 1, True);
	
EndProcedure

&AtClient
Procedure Attachable_HandlerCountdown()
	
	Timer = Timer - 1;
	If Timer >= 0 Then
		CountdownLabel = StrTemplate(NStr("ru = 'Запросить пароль повторно можно будет через %1 сек.';
												|en = 'You can request the password again in %1 sec.';"), Timer);
		AttachIdleHandler("Attachable_HandlerCountdown", 1, True);		
	Else
		CountdownLabel = "";
		PasswordSent = False;		
		NewTitle	= NStr("ru = 'Изменить адрес';
								|en = 'Change address';");
		Items.GetTempPasswordUsingAnotherMethod.Visible = ValueIsFilled(Email);
		Items.ConfigureConfirmation.Title = GetSettingsHeader(UseToken, NewTitle);
		
		FormControl(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Function GetErrorDetails(ErrorData)
	
	ExceptionText = ErrorProcessing.DetailErrorDescription(ErrorData);
	
	Result = New Structure();
	Result.Insert("State", "PasswordNotAccepted");
	Result.Insert("Information", NStr("ru = 'Сервис отправки SMS-сообщений временно недоступен. Повторите попытку позже.';
											|en = 'Text message service is temporarily unavailable. Try again later.';"));
	Result.Insert("ErrorDescription", ExceptionText);
	
	If StrFind(ExceptionText, "InvalidCertificateIdError") Then
		Position = StrFind(ExceptionText, "Invalid certificate id");
		If Position > 0 Then
			Result.Insert("ErrorDescription", NStr("ru = 'Не обнаружен сертификат в приложении';
														|en = 'The certificate is not found in the app';") + ": " + Mid(ExceptionText, Position + 23, 40) + ".");
		Else	
			Result.Insert("ErrorDescription", NStr("ru = 'Не обнаружен сертификат в приложении.';
														|en = 'The certificate is not found in the app.';"));
		EndIf;	
		Result.Insert("Information", NStr("ru = 'Указанный сертификат не обнаружен в приложении.';
												|en = 'The certificate is not found in the app.';"));
	EndIf;

	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function GetSettingsHeader(CurrentMode, NewTitle)
	
	Result = "Settings";
	If Not CurrentMode Then
		Result = NewTitle;
	EndIf;
	
	Return Result;
	
EndFunction	

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Items = Form.Items;
	
	Items.CountdownLabel.Visible = Form.PasswordSent;	
	Items.ResendPassword.Visible = Not Form.PasswordSent And Not Form.PasswordBeingSent;
	Items.IndentDecoration.Visible = Items.GetTempPasswordUsingAnotherMethod.Visible;
	
	CommandText = NStr("ru = 'Отправить пароль на %1';
						|en = 'Send password to %1';");
	If Form.PasswordsDeliveryMethod = "phone" Then
		If Form.PasswordBeingSent Then
			Items.Explanation.Title = NStr("ru = 'Выполняется отправка пароля в SMS-сообщении на номер';
												|en = 'Sending SMS message with password to the number';");
		Else
			Items.Explanation.Title = NStr("ru = 'Пароль отправлен в SMS-сообщении на номер';
												|en = 'SMS message with password is sent to the number';");
		EndIf;
		NewTitle = NStr("ru = 'Изменить номер';
								|en = 'Change number';");
		Items.ConfigureConfirmation.Title = GetSettingsHeader(Form.UseToken, NewTitle);
		Items.GetTempPasswordUsingAnotherMethod.Title = StrTemplate(CommandText, Form.Email);
		Form.Recipient = Form.Phone;
		Items.Password.InputHint = NStr("ru = 'Введите пароль из SMS';
												|en = 'Enter password from the text message';");
	ElsIf Form.PasswordsDeliveryMethod = "email" Then
		If Form.PasswordBeingSent Then
			Items.Explanation.Title = NStr("ru = 'Выполняется отправка пароля в письме на адрес';
												|en = 'Sending password to email:';");
		Else
			Items.Explanation.Title = NStr("ru = 'Пароль отправлен в письме на адрес';
												|en = 'Password is sent to email:';");
		EndIf;	
		NewTitle = NStr("ru = 'Изменить адрес';
								|en = 'Change address';");
		Items.ConfigureConfirmation.Title = GetSettingsHeader(Form.UseToken, NewTitle);
		Items.GetTempPasswordUsingAnotherMethod.Title = StrTemplate(CommandText, Form.Phone);
		Form.Recipient = Form.Email;
		Items.Password.InputHint = NStr("ru = 'Введите пароль из письма';
												|en = 'Enter password from the mail';");
	EndIf;

	Items.TimeConsumingOperationIndicator.Visible = Form.PasswordBeingSent
			And Items.TimeConsumingOperationIndicator.Picture.Type <> PictureType.Empty;
	Items.TimeConsumingOperationIndicator2.Visible = Form.PasswordBeingChecked 
			And Items.TimeConsumingOperationIndicator2.Picture.Type <> PictureType.Empty;
	
	Items.PasswordGroup.Enabled = Not Form.PasswordBeingSent And Not Form.PasswordBeingChecked;		
	Items.AdvancedGroup.Enabled = Not Form.PasswordBeingSent And Not Form.PasswordBeingChecked;
		
	Items.PasswordCheckLabel.Visible = Form.PasswordBeingChecked;
	Items.ErrorText.Visible = Not Form.PasswordBeingChecked;
	
EndProcedure

&AtServer
Function ConfirmOnServer(SessionID = Undefined)
	
	PasswordBeingChecked = True;

	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("CertificateID", CryptographyServiceInternal.Id(Certificate));
	ProcedureParameters.Insert("TemporaryPassword", Password);
	ProcedureParameters.Insert("SessionID", SessionID);
	
	Return CryptographyServiceInternal.ExecuteInBackground(
		"CryptographyServiceInternal.GetSessionKey", ProcedureParameters);
	
EndFunction

&AtServerNoContext
Function GetLibraryImage(IconName)
	
	If Metadata.CommonPictures.Find(IconName) <> Undefined Then
		Result = PictureLib[IconName];
	Else
		Result = New Picture;
	EndIf;	

	Return Result;
	
EndFunction

#EndRegion