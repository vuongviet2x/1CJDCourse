////////////////////////////////////////////////////////////////////////////////
//
// The "Cryptography service" subsystem.
//  
////////////////////////////////////////////////////////////////////////////////
//


#Region Internal

#Region GetSecurityToken

Procedure GetSecurityToken(CallbackOnCompletion, Id, OperationParametersList = Undefined) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("Id", Id);
	Context.Insert("OperationParametersList", OperationParametersList);
	
	Notification = New NotifyDescription("GetSecurityTokenAfterReceiving", ThisObject, Context);
	#If MobileAppClient Or MobileClient Then
		PasswordEntryForm = "CommonForm.TemporaryPasswordInputMobileApplication";
	#Else
		PasswordEntryForm = "CommonForm.TemporaryPasswordInput";
	#EndIf
	
	CertificateData = New Structure("Id", Id);
	OpenForm(
		PasswordEntryForm, 
		New Structure("Certificate, OperationParametersList", CertificateData, OperationParametersList),
		,,,, 
		Notification);
		
EndProcedure

// Parameters:
// 	Result - Undefined, Structure - a result of handler execution.
// 	IncomingContext - Structure - Incoming context:
// 	 * CallbackOnCompletion - NotifyDescription - notification.
// 	 * Id - String - operation ID.
// 	 * OperationParametersList - Structure - parameters.
Procedure GetSecurityTokenAfterReceiving(Result, IncomingContext) Export
	
	ExecutionResult = New Structure("Completed2", False);
	If TypeOf(Result) = Type("Structure") Then
		If Result.State = "ChangingSettingsForGettingTemporaryPasswords" Then
			Notification = New NotifyDescription("GetSecurityTokenAfterChangingSettingsToGetTemporaryPasswords", ThisObject, IncomingContext);
			DigitalSignatureSaaSClient.ChangeSettingsForGettingTemporaryPasswords(Result.Certificate, Notification);
			Return;
		ElsIf Result.State = "ChangingMethodOfConfirmingCryptoOperation" Then
			Notification = New NotifyDescription("GetSecurityTokenAfterReceiving", ThisObject, IncomingContext);
			DigitalSignatureSaaSClient.ChangeWayCryptoOperationsAreConfirmed(Result.Certificate, Notification);
			Return;
		ElsIf Result.State = "ContinueReceivingSecurityToken" Then
			GetSecurityToken(IncomingContext.CallbackOnCompletion, IncomingContext.Id, IncomingContext.OperationParametersList);	
			Return;
		ElsIf Result.State = "PasswordNotAccepted" Then
			ExceptionText = Result.ErrorDescription;
		ElsIf Result.State = "PasswordAccepted" Then
			ExecutionResult.Insert("Completed2", True);	
		EndIf;
	Else
		ExceptionText = NStr("ru = 'Пользователь отказался от ввода пароля';
								|en = 'The user refused to enter the password';");
	EndIf;
	
	
	If Not ExecutionResult.Completed2 Then
		Try
			Raise(ExceptionText);
		Except
			ErrorInfo = ErrorInfo();
		EndTry;
		ExecutionResult.Insert("ErrorInfo", ErrorInfo);
	EndIf;
	
	ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, ExecutionResult);
	
EndProcedure

// Parameters:
// 	Result - See GetSecurityTokenAfterReceiving.Result
// 	IncomingContext - See GetSecurityTokenAfterReceiving.IncomingContext
Procedure GetSecurityTokenAfterChangingSettingsToGetTemporaryPasswords(Result, IncomingContext) Export
	
	If TypeOf(Result) = Type("Structure") Then
		If Result.PhoneNumberChanged Or Result.EmailChanged Then
			GetSecurityToken(IncomingContext.CallbackOnCompletion, IncomingContext.Id, IncomingContext.OperationParametersList);	
		Else
			GetSecurityTokenAfterReceiving(Undefined, IncomingContext);	
		EndIf;
	Else
		GetSecurityTokenAfterReceiving(Undefined, IncomingContext);
	EndIf;
		
EndProcedure

#EndRegion

#Region Encrypt

Procedure Encrypt(CallbackOnCompletion, Data, Recipients, EncryptionType = "CMS", EncryptionParameters = Undefined) Export
	
	Notification = New NotifyDescription(
		"EncryptAfterCompletion", 
		ThisObject, 
		New Structure("CallbackOnCompletion", CallbackOnCompletion));
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.Encrypt(Data, Recipients, EncryptionType, EncryptionParameters));
	
EndProcedure

Procedure EncryptBlock(CallbackOnCompletion, Data, Recipient) Export
	
	Notification = New NotifyDescription(
		"EncryptAfterCompletion", 
		ThisObject, 
		New Structure("CallbackOnCompletion", CallbackOnCompletion));
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.EncryptBlock(Data, Recipient));
	
EndProcedure
	
Procedure EncryptAfterCompletion(TimeConsumingOperation, IncomingContext) Export
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	If Result.Completed2 Then
		Result.Insert("EncryptedData", Result.ExecutionResult);
		Result.Delete("ExecutionResult");
	EndIf;
	
	ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, Result);

EndProcedure

#EndRegion

#Region Decrypt

Procedure Decrypt(CallbackOnCompletion, EncryptedData, EncryptionType = "CMS", EncryptionParameters = Undefined) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("EncryptedData", EncryptedData);
	Context.Insert("EncryptionType", EncryptionType);
	Context.Insert("EncryptionParameters", EncryptionParameters);
	
	Notification = New NotifyDescription("DecryptAfterReceivingPropertiesOfCryptoMessage", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.GetCryptoMessageProperties(EncryptedData, True));	
	
EndProcedure

Procedure DecryptBlock(CallbackOnCompletion, EncryptedData, Recipient, KeyInformation, EncryptionParameters = Undefined) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("EncryptedData", EncryptedData);
	Context.Insert("Recipient", Recipient);
	Context.Insert("KeyInformation", KeyInformation);
	Context.Insert("EncryptionParameters", EncryptionParameters);
	
	Notification = New NotifyDescription("DecryptBlockAfterDecryption", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.DecryptBlock(EncryptedData, Recipient, KeyInformation, EncryptionParameters));	
	
	EndProcedure
	
Procedure DecryptAfterReceivingPropertiesOfCryptoMessage(TimeConsumingOperation, IncomingContext) Export
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	MessageProperties = Undefined;
	
	RecipientsField = "Recipients";
	IdField = "Id";
	
	If Result.Completed2 Then
		MessageProperties = Result.ExecutionResult;

		IDs = New Array;
		If MessageProperties.Type = "envelopedData" Then
			For Each Recipient In MessageProperties[RecipientsField] Do
				If Recipient.Property(IdField) Then
					IDs.Add(Recipient[IdField]);
				EndIf;
			EndDo;			
		Else
			Try
				Raise StrTemplate(NStr("ru = 'Недопустимое значение параметра %1 - файл не является криптосообщением';
												|en = 'Incorrect value of the %1 parameter. The file is not a crypto message';"),
					"EncryptedData");
			Except
				ExecutionResult = PrepareNegativeResult(ErrorInfo());
				ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, ExecutionResult);
				Return;
			EndTry;	
		EndIf;
		
		If Not ValueIsFilled(IDs) Then
			Try
				Raise(NStr("ru = 'В хранилище отсутствуют сертификаты для расшифровки сообщения.';
										|en = 'There are no certificates for message decryption in storage.';"));
			Except
				ExecutionResult = PrepareNegativeResult(ErrorInfo());
				ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, ExecutionResult);
				Return;
			EndTry;
		EndIf;
		
		If IDs.Count() > 1 Then
			IDs = CryptographyServiceInternalServerCall.DetermineOrderOfCertificates(IDs);
		EndIf;

		IncomingContext.Insert("IDs", IDs);
		IncomingContext.Insert("CurrentID", 0);
		IncomingContext.Insert(RecipientsField, MessageProperties[RecipientsField]);
		IncomingContext.Insert("ErrorsDetails", New Array);
		DecryptByIteratingOverCertificates(IncomingContext);
	Else		
		ExecutionResult = PrepareNegativeResult(Result.ErrorInfo);
		If TypeOf(Result) = Type("Structure") And Result.Property("ExecutionResult") Then 
			MessageProperties = Result.ExecutionResult;
		EndIf;
		If ValueIsFilled(MessageProperties) And MessageProperties.Property(RecipientsField) Then
			ExecutionResult.Insert(RecipientsField, MessageProperties[RecipientsField]);
		EndIf;
		ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, ExecutionResult);
	EndIf;

EndProcedure

Procedure DecryptAfterDecryption(TimeConsumingOperation, IncomingContext) Export
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		If TypeOf(Result.ExecutionResult) = Type("Structure") Then
			If Result.ExecutionResult.ReturnCode = "AuthenticationRequired" Then
				Notification = New NotifyDescription("DecryptAfterReceivingSecurityToken", ThisObject, IncomingContext);
				GetSecurityToken(Notification, Result.ExecutionResult.Id, IncomingContext.EncryptionParameters);
			Else
				Raise(NStr("ru = 'Неизвестный код возврата';
										|en = 'Unknown return code';"));
			EndIf;
		Else
			Result.Insert("DecryptedData", Result.ExecutionResult);
			Result.Delete("ExecutionResult");
			ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, Result);
		EndIf;
	Else
		IncomingContext.CurrentID = IncomingContext.CurrentID + 1;
		DecryptByIteratingOverCertificates(IncomingContext, Result.ErrorInfo);
	EndIf;
		
EndProcedure

Procedure DecryptAfterReceivingSecurityToken(Result, IncomingContext) Export
	
	If Result.Completed2 Then
		DecryptByIteratingOverCertificates(IncomingContext);
	Else
		ErrorPresentation = ErrorProcessing.BriefErrorDescription(Result.ErrorInfo);
		If IncomingContext.ErrorsDetails.Find(ErrorPresentation) = Undefined Then
			IncomingContext.ErrorsDetails.Add(ErrorPresentation);
		EndIf;		
		IncomingContext.CurrentID = IncomingContext.CurrentID + 1;
		DecryptByIteratingOverCertificates(IncomingContext);
	EndIf;
	
EndProcedure

Procedure DecryptBlockAfterDecryption(TimeConsumingOperation, IncomingContext) Export
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		If TypeOf(Result.ExecutionResult) = Type("Structure") Then
			If Result.ExecutionResult.ReturnCode = "AuthenticationRequired" Then
				Notification = New NotifyDescription("DecryptBlockAfterReceivingSecurityToken", ThisObject, IncomingContext);
				GetSecurityToken(Notification, Result.ExecutionResult.Id, IncomingContext.EncryptionParameters);
			Else
				Raise(NStr("ru = 'Неизвестный код возврата';
										|en = 'Unknown return code';"));
			EndIf;
		Else
			Result.Insert("DecryptedData", Result.ExecutionResult);
			Result.Delete("ExecutionResult");
			ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, Result);
		EndIf;
	Else
		ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, Result);
	EndIf;
		
EndProcedure

Procedure DecryptBlockAfterReceivingSecurityToken(Result, IncomingContext) Export
	
	If Result.Completed2 Then
		Notification = New NotifyDescription("DecryptBlockAfterDecryption", ThisObject, IncomingContext);
		WaitForExecutionCompletionInBackground(
			Notification, 
			CryptographyServiceInternalServerCall.DecryptBlock(
				IncomingContext.EncryptedData, 
				IncomingContext.Recipient,
				IncomingContext.KeyInformation, 
				IncomingContext.EncryptionParameters));
		Return;
	Else
		ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region Sign

Procedure Sign(CallbackOnCompletion, Data, Signatory, SignatureType = "CMS", SigningParameters = Undefined) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("Data", Data);
	Context.Insert("Signatory", Signatory);
	Context.Insert("SignatureType", SignatureType);
	Context.Insert("SigningParameters", SigningParameters);
	
	Notification = New NotifyDescription("SignAfterReceivingSigningResult", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.Sign(Data, Signatory, SignatureType, SigningParameters));
	
EndProcedure

Procedure SignAfterReceivingSigningResult(TimeConsumingOperation, IncomingContext) Export
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	ExecutionResult = New Structure("Completed2");
	
	If Result.Completed2 Then
		
		If TypeOf(Result.ExecutionResult) = Type("Structure") Then
			If Result.ExecutionResult.ReturnCode = "AuthenticationRequired" Then		
				Context = New Structure;
				Context.Insert("CallbackOnCompletion", IncomingContext.CallbackOnCompletion);
				Context.Insert("Data", IncomingContext.Data);
				Context.Insert("Signatory", IncomingContext.Signatory);
				Context.Insert("SignatureType", IncomingContext.SignatureType);
				Context.Insert("SigningParameters", IncomingContext.SigningParameters);
				
				Notification = New NotifyDescription("SignAfterReceivingSecurityToken", ThisObject, Context);
				GetSecurityToken(Notification, Result.ExecutionResult.Id, IncomingContext.SigningParameters);
			Else
				Raise(NStr("ru = 'Неизвестный код возврата';
										|en = 'Unknown return code';"));
			EndIf;
			Return;
		Else
			ExecutionResult.Completed2 = True;
			ExecutionResult.Insert("Signature", Result.ExecutionResult);
		EndIf;
		ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, ExecutionResult);
	Else
		ExecutionResult = PrepareNegativeResult(Result.ErrorInfo);
		ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, ExecutionResult);
	EndIf;
	
EndProcedure

Procedure SignAfterReceivingSecurityToken(Result, IncomingContext) Export
	
	If Result.Completed2 Then
		Sign(
			IncomingContext.CallbackOnCompletion,
			IncomingContext.Data,
			IncomingContext.Signatory,
			IncomingContext.SignatureType,
			IncomingContext.SigningParameters);
	Else
		ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region VerifySignature

Procedure VerifySignature(CallbackOnCompletion, Signature, Data = Undefined, SignatureType = "CMS", SigningParameters = Undefined) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("Signature", Signature);
	Context.Insert("Data", Data);
	Context.Insert("SignatureType", SignatureType);
	Context.Insert("SigningParameters", SigningParameters);
		
	Notification = New NotifyDescription("VerifySignatureAfterReceivingResult", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.VerifySignature(Signature, Data, SignatureType, SigningParameters));
	
EndProcedure

Procedure VerifySignatureAfterReceivingResult(TimeConsumingOperation, IncomingContext) Export
	
	ExecutionResult = New Structure("Completed2");
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		
		CheckResult = Result.ExecutionResult;
		
		ExecutionResult.Completed2 = True;
		ExecutionResult.Insert("SignatureIsValid", CheckResult);
		
	Else
		ExecutionResult = PrepareNegativeResult(Result.ErrorInfo);		
	EndIf;
	
	ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, ExecutionResult);
	
EndProcedure

#EndRegion

#Region CheckCertificate

Procedure CheckCertificate(CallbackOnCompletion, Certificate) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("Certificate", Certificate);
	
	Notification = New NotifyDescription("VerifyCertificateAfterReceivingResult", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.CheckCertificate(Certificate));
		
EndProcedure

Procedure VerifyCertificateAfterReceivingResult(TimeConsumingOperation, IncomingContext) Export
	
	ExecutionResult = New Structure("Completed2");
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		
		CheckResult = Result.ExecutionResult;
		
		ExecutionResult.Completed2 = True;
		ExecutionResult.Insert("Valid1", CheckResult);
	
	Else
		ExecutionResult = PrepareNegativeResult(Result.ErrorInfo);
	EndIf;
	
	ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, ExecutionResult);

EndProcedure

#EndRegion

#Region VerifyCertificateWithParameters

Procedure VerifyCertificateWithParameters(CallbackOnCompletion, Certificate, CheckParameters) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("Certificate", Certificate);
	Context.Insert("CheckParameters", CheckParameters);
	
	Notification = New NotifyDescription("VerifyCertificateWithParametersAfterReceivingResult", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.VerifyCertificateWithParameters(Certificate, CheckParameters));
		
EndProcedure

Procedure VerifyCertificateWithParametersAfterReceivingResult(TimeConsumingOperation, IncomingContext) Export
	
	ExecutionResult = New Structure("Completed2");
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		
		CheckResult = Result.ExecutionResult;
		
		ExecutionResult.Completed2 = True;
		ExecutionResult.Insert("Valid1", CheckResult);
	
	Else
		ExecutionResult = PrepareNegativeResult(Result.ErrorInfo);
	EndIf;
	
	ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, ExecutionResult);

EndProcedure

#EndRegion

#Region GetCertificateProperties

Procedure GetCertificateProperties(CallbackOnCompletion, Certificate) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("Certificate", Certificate);
	
	Notification = New NotifyDescription("GetCertificatePropertiesAfterReceivingResult", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.GetCertificateProperties(Certificate));
	
EndProcedure

Procedure GetCertificatePropertiesAfterReceivingResult(TimeConsumingOperation, IncomingContext) Export
	
	ExecutionResult = New Structure("Completed2");
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		
		CertificateProperties = Result.ExecutionResult;
		
		ExecutionResult.Completed2 = True;
		ExecutionResult.Insert("Certificate", CertificateProperties);
	
	Else
		ExecutionResult = PrepareNegativeResult(Result.ErrorInfo);
	EndIf;
	
	ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, ExecutionResult);
	
EndProcedure

#EndRegion

#Region GetCertificatesFromSignature

Procedure GetCertificatesFromSignature(CallbackOnCompletion, Signature) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("Signature", Signature);
	
	Notification = New NotifyDescription("GetCertificatesFromSignatureAfterReceivingResult", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.GetCertificatesFromSignature(Signature));
	
EndProcedure

Procedure GetCertificatesFromSignatureAfterReceivingResult(TimeConsumingOperation, IncomingContext) Export
	
	ExecutionResult = New Structure("Completed2");
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		
		Certificates = Result.ExecutionResult;
		
		ExecutionResult.Completed2 = True;
		ExecutionResult.Insert("Certificates", Certificates);
		
	Else
		ExecutionResult = PrepareNegativeResult(Result.ErrorInfo);
	EndIf;
	
	ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, ExecutionResult);
	
EndProcedure
		
#EndRegion

#Region DataHashing

Procedure DataHashing(CallbackOnCompletion, Data, HashAlgorithm, HashingParameters) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("Data", Data);
	Context.Insert("HashAlgorithm", HashAlgorithm);
	Context.Insert("HashingParameters", HashingParameters);
	
	Notification = New NotifyDescription("HashingDataAfterReceivingResult", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.DataHashing(Data, HashAlgorithm, HashingParameters));
	
EndProcedure

Procedure HashingDataAfterReceivingResult(TimeConsumingOperation, IncomingContext) Export
	
	ExecutionResult = New Structure("Completed2");
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		
		Result = Result.ExecutionResult;
	
		ExecutionResult.Completed2 = True;
		ExecutionResult.Insert("Hash", Result);
		
	Else
		ExecutionResult = PrepareNegativeResult(Result.ErrorInfo);
	EndIf;
	
	ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, ExecutionResult);
	
EndProcedure

#EndRegion

Procedure WaitForExecutionCompletionInBackground(CallbackOnCompletion, TimeConsumingOperation) Export
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Undefined);
	IdleParameters.OutputIdleWindow = False;
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);

EndProcedure

#EndRegion

#Region Private

// Parameters:
// 	Certificate - Structure - Required fields.:
// 	 * Id - String - Certificate ID.
// Returns:
// 	 String - Certificate ID.
Function Id(Val Certificate) Export
	
	Return Certificate.Id;

EndFunction

// Returns:
// 	Structure - Details.:
// 	* Completed2 - Boolean - indicates execution
// 	* ExecutionResult - BinaryData, String, Structure - a result or details of an error with the following fields:
// 	   ** ReturnCode - String - error code
// 	   ** Id - String - Certificate ID.
Function GetBackgroundExecutionResult(TimeConsumingOperation) Export
	
	If TimeConsumingOperation = Undefined Then
		Return PrepareNegativeResult(NStr("ru = 'Вызов API сервиса криптографии не был завершен штатно.';
														|en = 'API cryptography service was not called correctly.';"));
	EndIf;
	
	If TimeConsumingOperation.Status = "Completed2" Then
		Return PreparePositiveResult(GetFromTempStorage(TimeConsumingOperation.ResultAddress));
	Else
		Return PrepareNegativeResult(TimeConsumingOperation.BriefErrorDescription);
	EndIf;
	
EndFunction

Function PreparePositiveResult(ExecutionResult)
	
	Result = New Structure;
	Result.Insert("Completed2", True);
	Result.Insert("ExecutionResult", ExecutionResult);
		
	Return Result;
	
EndFunction

// Returns:
// 	Structure - Details.:
// * ErrorInfo - ErrorInfo - error details. 
// * Completed2 - Boolean - always = False
Function PrepareNegativeResult(ErrorInfo)
	
	Result = New Structure;
	Result.Insert("Completed2", False);
	
	If TypeOf(ErrorInfo) = Type("String") Then
		Result.Insert("ErrorInfo", GetErrorInformationByLine(ErrorInfo));
	Else	
		Result.Insert("ErrorInfo", ErrorInfo);
	EndIf;

	Return Result;
	
EndFunction

Function GetErrorInformationByLine(ExceptionText)
	
	Try
		Raise ExceptionText;
	Except
		Return ErrorInfo();
	EndTry;
	
EndFunction

// Parameters:
// 	IncomingContext - Structure - 
// 	ErrorInfo - ErrorInfo, Undefined - error information.
Procedure DecryptByIteratingOverCertificates(IncomingContext, ErrorInfo = Undefined)

	If IncomingContext.CurrentID < IncomingContext.IDs.Count() Then
		Notification = New NotifyDescription("DecryptAfterDecryption", ThisObject, IncomingContext);
		WaitForExecutionCompletionInBackground(
			Notification, 
			CryptographyServiceInternalServerCall.Decrypt(
				IncomingContext.EncryptedData, 
				New Structure("Id", IncomingContext.IDs[IncomingContext.CurrentID]),
				IncomingContext.EncryptionType, 
				IncomingContext.EncryptionParameters));
		Return;
	EndIf;
	
	If ErrorInfo = Undefined Then
		ExceptionText = StrConcat(IncomingContext.ErrorsDetails, Chars.LF);
		If Not ValueIsFilled(ExceptionText) Then
			ExceptionText = NStr("ru = 'Не удалось выполнить расшифровку сообщения';
									|en = 'Cannot decrypt a message';");
		EndIf;
		Try			
			Raise(ExceptionText);
		Except
			ErrorInfo = ErrorInfo();
		EndTry;
	EndIf;
	
	Result = PrepareNegativeResult(ErrorInfo);
	RecipientsField = "Recipients";
	If IncomingContext.Property(RecipientsField) Then
		Result.Insert(RecipientsField, IncomingContext[RecipientsField]);
	EndIf;
	ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, Result);
	
EndProcedure

#EndRegion