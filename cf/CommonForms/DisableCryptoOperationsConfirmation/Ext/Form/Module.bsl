#Region Variables

&AtClient
Var CloseProgrammatically;

&AtClient
Var ArrayOfResources;

&AtClient
Var SessionID;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skipping initialization to ensure getting the form when passing the Autotest parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Certificate 					= Parameters.Certificate;
	ProcedureParameters 			= New Structure("CertificateID", CryptographyServiceInternal.Id(Certificate));
	TimeConsumingOperation 			= CryptographyServiceInternal.ExecuteInBackground(
		"CryptographyServiceInternal.GetSettingsForGettingTemporaryPasswords", ProcedureParameters);
	
	CertificateThumbprint		= DigitalSignatureSaaS.FindCertificateById(Certificate);
	UserData			= GetCurUserData();
	
	StoredPasswordValue 	= UserData.StoredPasswordValue;
	Login 						= UserData.Login;
	PasswordVerified				= Not ValueIsFilled(StoredPasswordValue);
	AuthorizationStep 				= 1;
	Items.TimeConsumingOperationIndicator.Picture = GetLibraryImage("TimeConsumingOperation16");
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ArrayOfResources		= PrepareArrayOfResources();
	CurrentItem		= Items.Confirm;
	CloseProgrammatically	= False;
	
	If TimeConsumingOperation <> Undefined Then
		ShowMessage(NStr("ru = 'Получение настроек';
								|en = 'Getting settings';"), True);
		Notification = New NotifyDescription("GetSettingsForGettingTemporaryPasswordsAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, TimeConsumingOperation);
	EndIf;	
	
	ChangePasswordVisibility(True);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If CloseProgrammatically <> True Then
		CloseProgrammatically = True;
		Cancel = True;
		
		CloseOpen(Undefined);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PasswordStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ChangePasswordVisibility();
	
EndProcedure

&AtClient
Procedure PasswordOnChange(Item)
	
	PasswordVerified = VerifyUserPassword(StoredPasswordValue, UserPassword);
	If AuthorizationStep = 2 Then
		CurrentItem = Items.PhoneCode;
	Else
		CurrentItem = Items.Confirm;
	EndIf;	
	
EndProcedure

&AtClient
Procedure UserPasswordEditTextChange(Item, Text, StandardProcessing)
	
	PasswordStatus 	= "";
	
EndProcedure

&AtClient
Procedure PhoneCodeOnChange(Item)
	
	CheckPhoneCode(PhoneCode);
	
EndProcedure

&AtClient
Procedure PhoneCodeEditTextChange(Item, Text, StandardProcessing)
	
	StandardProcessing = False;
	If StrLen(Text) = 6 Then
		PhoneCode = Text;
		CheckPhoneCode(Text);
	EndIf;	
	
EndProcedure

&AtClient
Procedure RepeatCodeClick(Item, StandardProcessing)
	
	ShowMessage(NStr("ru = 'Выполняется отправка пароля в SMS-сообщении на номер';
							|en = 'Sending SMS message with password to the number';"), True);
	
	StandardProcessing 	= False;
	PhoneCode 			= "";
	CodeStatus				= "";
	DisableCountdown = 99;
	Notification 	= New NotifyDescription("GetTemporaryPasswordAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, GetPasswordOnServer(True, SessionID));
		
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CloseOpen(FormParameters)
	
	CloseProgrammatically = True;
	
	If FormParameters = Undefined Then
		FormParameters = New Structure();
		FormParameters.Insert("CryptoOperationsConfirmationMethod", PredefinedValue("Enum.CryptoOperationsConfirmationMethods.SessionToken"));
		FormParameters.Insert("Completed2", False);
		FormParameters.Insert("State", "ContinueReceivingSecurityToken");
		FormParameters.Insert("Certificate", Certificate);
	EndIf;
	
	If IsOpen() Then 
		Close(FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure Confirm(Command)
	
	If AuthorizationStep > 2 And PasswordVerified Then
		If Not IsCheckOnly Then
			ReflectChangesServer();
		EndIf;
		
		FormParameters = New Structure();
		FormParameters.Insert("CryptoOperationsConfirmationMethod", PredefinedValue("Enum.CryptoOperationsConfirmationMethods.LongLivedToken"));
		FormParameters.Insert("Completed2", True);
		FormParameters.Insert("State", "PasswordAccepted");
		FormParameters.Insert("Certificate", Certificate);
		
		CloseOpen(FormParameters);
		
	ElsIf Not PasswordVerified Then
		ShowMessageBox(, 
			NStr("ru = 'В целях безопасности, для отключения подтверждения операций с ключом, 
			|следует правильно указать пароль пользователя 1С.';
			|en = 'For security purposes, to disable confirmation of operations with the key, 
			|the 1C user password must be correctly specified.';"), 30, 
			NStr("ru = 'Процедура не закончена.';
				|en = 'The procedure is not completed.';"));
		
	Else
		ShowMessageBox(, 
			NStr("ru = 'В целях безопасности, для отключения подтверждения операций с ключом, 
			|следует полностью пройти процедуру идентификации по SMS.';
			|en = 'For security reasons, in order to disable the confirmation of operations with the key, 
			|you must completely go through the identification procedure by SMS.';"), 30, 
			NStr("ru = 'Процедура не закончена.';
				|en = 'The procedure is not completed.';"));
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region IdleHandlers

&AtClient
Procedure CountdownPhoneCode()
	
	Timer		= TimerEnd - CurrentDate();
	GeneralTimer	= PeriodTimer - CurrentDate();
	
	If AuthorizationStep <> 2 Then
		RepeatCode 	= "";
		
	ElsIf DisableCountdown <> 99 Then
		If Timer > 0 Then
			RepeatCode = StrTemplate(NStr("ru = 'Запросить пароль повторно можно будет через %1 сек.';
											|en = 'You can request the password again in %1 sec.';"), Timer);
		ElsIf Items.RepeatCode.Hyperlink = False Then
			RepeatCode = NStr("ru = 'Отправить пароль повторно';
								|en = 'Re-send the password';");
			Items.RepeatCode.Hyperlink = True;
		EndIf;	
		
		If DisableCountdown > 0 Then
			DisableCountdown = DisableCountdown - 1;
		ElsIf GeneralTimer > 0 And Timer > 0 Then
			CodeStatus = "";
		ElsIf GeneralTimer > 0 Then
			CodeStatus = StrTemplate(NStr("ru = 'Истекает через %1:%2';
										|en = 'Expires in %1:%2';"), Int(GeneralTimer / 60), Format(GeneralTimer % 60, "ND=2; NLZ="));
		Else
			CodeStatus = NStr("ru = 'Истек срок действия пароля';
								|en = 'Password has expired';");
			Items.CodeStatus.TextColor = WebColors.Red;
		EndIf;
		
		If GeneralTimer > 0 Or Timer > 0 Then
			AttachIdleHandler("CountdownPhoneCode", 1, True);
		EndIf;
		
	EndIf;	
	
EndProcedure

&AtClient
Procedure StartPhoneCodeCountdown(Timer, ValidityPeriod)
	
	TimerEnd = CurrentDate() + Timer;
	PeriodTimer		= CurrentDate() + ValidityPeriod;
	RepeatCode 	= "";
	CodeStatus		= "";
	
	Items.CodeStatus.TextColor = WebColors.Gray;
	Items.RepeatCode.Hyperlink = False;
	DisableCountdown = 0;
	AttachIdleHandler("CountdownPhoneCode", 1, True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CheckNextStep()
	
	AuthorizationStep = AuthorizationStep + 1;
	
	If AuthorizationStep = 2 Then
		Step_PhoneCode();
		
	ElsIf AuthorizationStep = 3 Then
		If Not ValueIsFilled(StoredPasswordValue) Then
			AuthorizationStep = 4;
		EndIf;
		ShowMessage("", False);
		
	EndIf;	
	
	FormControl(ThisObject);
	
	If AuthorizationStep = 2 Then
		CurrentItem 	= Items.PhoneCode;
	ElsIf AuthorizationStep = 3 And Not PasswordVerified Then
		CurrentItem 	= Items.UserPassword;
	Else
		CurrentItem 	= Items.Confirm;
	EndIf;	
	
EndProcedure

&AtClient
Procedure Step_PhoneCode()
	
	ShowMessage(NStr("ru = 'Выполняется отправка пароля в SMS-сообщении на номер';
							|en = 'Sending SMS message with password to the number';"), True);
	CurrentItem 	= Items.PhoneCode;
	Notification 		= New NotifyDescription("GetTemporaryPasswordAfterExecution", ThisObject);
	CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, GetPasswordOnServer());
	
EndProcedure

&AtClient
Procedure ShowMessage(MessageText, Wait = False, IsError = False)
	
	Items.Explanation.Title = MessageText;
	If IsError Then 
		Items.Explanation.TextColor = WebColors.Red;
	Else
		Items.Explanation.TextColor = Items.RepeatCode.TextColor;
	EndIf;	
	
	If Items.TimeConsumingOperationIndicator.Visible <> Wait Then
		Items.TimeConsumingOperationIndicator.Visible = Wait;
	EndIf;	
	
EndProcedure

&AtClient
Procedure GetTemporaryPasswordAfterExecution(Result, IncomingContext) Export
	
	Result = CryptographyServiceInternalClient.GetBackgroundExecutionResult(Result);
	
	If Result.Completed2 Then
		Timer = Result.ExecutionResult.DelayBeforeResending;
		If Result.ExecutionResult.Property("SessionID") Then 
			SessionID = Result.ExecutionResult.SessionID;
		EndIf;
		
		ShowMessage(NStr("ru = 'Пароль отправлен на номер:';
								|en = 'Password is sent to the number:';") + " " + PhonePresentation(Recipient));

		StartPhoneCodeCountdown(Timer, 600);
		FormControl(ThisObject);
		
	Else
		ShowMessage(NStr("ru = 'Сервис отправки SMS-сообщений временно недоступен.';
								|en = 'SMS message sending service is temporarily unavailable.';"), , True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckPhoneCode(CurrentCode)
	
	If AuthorizationStep <> 2 Then
		DisableCountdown = 99;
		
	ElsIf CheckInProgress Then
		CodeStatus 	= NStr("ru = 'Ожидается ответ';
								|en = 'Waiting for response';");
		DisableCountdown = 10;
		
	ElsIf DisableCountdown = 99 Then
		CodeStatus 	= NStr("ru = 'Необходимо повторить процедуру';
								|en = 'Repeat the procedure';");
		
	ElsIf ValueIsFilled(CurrentCode) And StrLen(CurrentCode) = 6 Then
		CheckInProgress = True;
		ShowMessage(NStr("ru = 'Выполняется проверка пароля';
								|en = 'Checking the password';"), True);
		Notification 			= New NotifyDescription("ConfirmPasswordAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, ConfirmOnServer(SessionID));
		
	ElsIf ValueIsFilled(CurrentCode) And StrLen(CurrentCode) <> 6 Then
		CodeStatus 	= NStr("ru = 'Пароль должен быть из 6 цифр';
								|en = 'The password must contain 6 digits';");
		DisableCountdown = 10;
		
	Else
		CodeStatus 	= NStr("ru = 'Пароль не указан';
								|en = 'Password is not specified';");
		DisableCountdown = 10;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GetSettingsForGettingTemporaryPasswordsAfterExecution(Result, IncomingContext) Export
	
	Result = CryptographyServiceInternalClient.GetBackgroundExecutionResult(Result);
	
	If Result.Completed2 Then
		PhoneSettings   = Result.ExecutionResult;
		Recipient 			= PhoneSettings.Phone;
		ShowMessage("", False);
		CheckNextStep();
		
	Else	
		ShowMessage(NStr("ru = 'Сервис отправки SMS-сообщений временно недоступен. Повторите попытку позже.';
								|en = 'SMS service is temporarily unavailable. Try again later.';"), , True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterDisplayingWarning(IncomingContext) Export
	
	CloseOpen(Undefined);
	
EndProcedure

&AtClient
Procedure ChangePasswordVisibility(ForciblyHide = False)
	
	NewMode 	= Not Items.UserPassword.PasswordMode;
	Items.UserPassword.ChoiceButton = Not ArrayOfResources[0].Kind = PictureType.Empty;
	
	If ForciblyHide Then
		Items.UserPassword.ChoiceButtonPicture = ArrayOfResources[0];
		Items.UserPassword.PasswordMode = True;
		
	ElsIf Not NewMode Then
		Items.UserPassword.ChoiceButtonPicture = ArrayOfResources[1];
		Items.UserPassword.PasswordMode = NewMode;
		
	EndIf;	
	
EndProcedure

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Items 	= Form.Items;
	
	Items.PhoneCode.Enabled = Form.AuthorizationStep = 2;
	
EndProcedure

&AtServer
Function GetPasswordOnServer(Repeatedly = False, SessionID = Undefined)
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("CertificateID", CryptographyServiceInternal.Id(Certificate));
	ProcedureParameters.Insert("Resending", Repeatedly);
	ProcedureParameters.Insert("Type", "phone");
	ProcedureParameters.Insert("SessionID", SessionID);
	
	Return CryptographyServiceInternal.ExecuteInBackground(
		"CryptographyServiceInternal.GetTemporaryPassword", ProcedureParameters);
	
EndFunction

&AtServerNoContext
Function GetCurUserData()
	
	Result = New Structure("Login, StoredPasswordValue");
	
	SetPrivilegedMode(True);
	
	CurrentUser 		= Users.AuthorizedUser();
	UserIdentificator 	= Common.ObjectAttributeValue(CurrentUser, "IBUserID");
	UserProperties 		= Users.IBUserProperies(UserIdentificator);
	
	If UserProperties <> Undefined Then
		Result.Login 					= UserProperties.Name;
		Result.StoredPasswordValue = UserProperties.StoredPasswordValue;
	EndIf;	
	
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function VerifyUserPassword(StoredPasswordValue, CurrentPassword)
	
	Result = False;
	
	If Not ValueIsFilled(StoredPasswordValue) And IsBlankString(CurrentPassword) Then
		Result = True;
	ElsIf ValueIsFilled(StoredPasswordValue) Then
		DataHashing = New DataHashing(HashFunction.SHA1);
		DataHashing.Append(CurrentPassword);
			
		NewValue = Base64String(DataHashing.HashSum);
		
		DataHashing = New DataHashing(HashFunction.SHA1);
		DataHashing.Append(Upper(CurrentPassword));
		
		NewValue = NewValue + ","
			+ Base64String(DataHashing.HashSum);
			
		Result = StoredPasswordValue = NewValue;
	EndIf;	
	
	Return Result;
	
EndFunction

&AtServer
Procedure ReflectChangesServer()
	
	DigitalSignatureSaaS.ConfigureUseOfLongTermToken(Enums.CryptoOperationsConfirmationMethods.LongLivedToken, Certificate);
	
EndProcedure	

&AtServerNoContext
Procedure SaveSecurityTokens(Val SecurityTokens)
	
	SetPrivilegedMode(True);
	CryptographyServiceInternal.SaveSecurityTokens(SecurityTokens);
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Function ConfirmOnServer(SessionID = Undefined)
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("CertificateID", CryptographyServiceInternal.Id(Certificate));
	ProcedureParameters.Insert("TemporaryPassword", PhoneCode);
	ProcedureParameters.Insert("SessionID", SessionID);
	
	Return CryptographyServiceInternal.ExecuteInBackground(
		"CryptographyServiceInternal.GetSessionKey", ProcedureParameters);
	
EndFunction

&AtServerNoContext
Function PhonePresentation(CurrentPhone)
	
	Result   = TrimAll(CurrentPhone);
	Counter 	= StrLen(Result);
	DigitsTotal	= 0;
	
	While Counter > 0 Do
		IsDigit    = StrFind("0123456789", Mid(Result, Counter, 1))  > 0;
		If IsDigit Then
			DigitsTotal = DigitsTotal + 1;
		EndIf;
		
		If DigitsTotal > 2 And IsDigit Then
			Result = Mid(Result, 1, Counter - 1) + "*" + Mid(Result, Counter + 1);
		EndIf;
		
		If DigitsTotal >= 7 Then
			Break;
		EndIf;
		
		Counter 	= Counter - 1;
		
	EndDo;	
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function PrepareArrayOfResources()
	
	Result = New Array;
	Result.Add(GetLibraryImage("VisibilityClosed"));
	Result.Add(GetLibraryImage("VisibilityOpen"));
	Result.Add(PredefinedValue("Enum.CryptoOperationsConfirmationMethods.LongLivedToken"));
	
	Return Result;

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

&AtClient
Procedure ConfirmPasswordAfterExecution(Result, IncomingContext) Export

	Result 			= CryptographyServiceInternalClient.GetBackgroundExecutionResult(Result);
	CheckInProgress = False;
	
	ShowMessage("", False);
	
	If Result.Completed2 Then
		SaveSecurityTokens(Result.ExecutionResult);
		CodeStatus		= NStr("ru = 'Указан верный пароль';
								|en = 'Password is correct';");
		CheckNextStep();
		FormControl(ThisObject);
		
	Else
		ExceptionText = ErrorProcessing.DetailErrorDescription(Result.ErrorInfo);
		If StrFind(ExceptionText, "PasswordIsIncorrect") Then
			CodeStatus = NStr("ru = 'Указан неверный пароль';
								|en = 'Password is incorrect';");
			DisableCountdown = 10;
		ElsIf StrFind(ExceptionText, "ExceededNumberOfAttemptsToEnterPassword") Then
			CodeStatus = NStr("ru = 'Превышен лимит попыток';
								|en = 'Attempt limit exceeded';"); 
			SessionID = "";
			DisableCountdown = 99;
		ElsIf StrFind(ExceptionText, "PasswordExpired") Then
			CodeStatus = NStr("ru = 'Срок действия пароля истек';
								|en = 'Password expired';");
			SessionID = "";
			DisableCountdown = 99;
		Else 
			CodeStatus = NStr("ru = 'Выполнение операции временно невозможно';
								|en = 'Operation temporarily cannot be executed';");
			DisableCountdown = 99;
		EndIf;		
	EndIf;
	
EndProcedure

#EndRegion