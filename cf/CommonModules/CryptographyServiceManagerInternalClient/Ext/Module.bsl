////////////////////////////////////////////////////////////////////////////////
// Subsystem "Cryptography Service Manager".
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region GetApplicationForCertificate

Function CreateContainerAndRequestForCertificateResult(Completed2 = False, 
											RequestDataOrError = Undefined, 
											PublicKey = Undefined, 
											ProviderName = Undefined, 
											ProviderType = Undefined)
											
	Result = New Structure();
	Result.Insert("Completed2", Completed2);
	If Completed2 Then
		Result.Insert("CertificateRequest1", RequestDataOrError);
		Result.Insert("PublicKey", PublicKey);
		Result.Insert("ProviderName", ProviderName);
		Result.Insert("ProviderType", ProviderType);
	Else
		RowsArray = StrSplit(RequestDataOrError, "@", False);
		ErrorCode = "";
		If RowsArray.Count() = 2 Then
			ErrorCode = RowsArray[0];
			ErrorText = RowsArray[1];
		Else
			ErrorText = RowsArray[0];
		EndIf;
		Result.Insert("ErrorDescription", ErrorText);
		Result.Insert("ErrorCode", ErrorCode);
	EndIf;
	
	Return Result;
											
EndFunction

Procedure CreateContainerAndRequestCertificate(CallbackOnCompletion, 
										ApplicationID, 
										RequestContent, 
										SubscriberID = Undefined,
										NotaryLawyerHeadOfFarm = False) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("ApplicationID", ApplicationID);
	Context.Insert("RequestContent", RequestContent);
	Context.Insert("SubscriberID", SubscriberID);
	Context.Insert("NotaryLawyerHeadOfFarm", NotaryLawyerHeadOfFarm);
	
	Notification 		= New NotifyDescription("CreateContainerAndRequestCertificateAfterConfirmation", ThisObject, Context);
	FormParameters  = New Structure("CheckMode", "Confirmation");
	
	DigitalSignatureSaaSClient.ChangeSettingsForGettingTemporaryPasswords(Undefined, Notification, FormParameters);
	
EndProcedure

Procedure CreateContainerAndRequestCertificateAfterConfirmation(Result, IncomingContext)	Export
	
	If Result <> Undefined 
		And Result.Property("PhoneNumber") Then
		Notification 			= New NotifyDescription("CreateContainerAndRequestCertificateUponReceipt", ThisObject, IncomingContext);
		
		TimeConsumingOperation = CryptographyServiceManagerInternalServerCall.CreateContainerAndRequestCertificate(IncomingContext.ApplicationID,
								IncomingContext.RequestContent,
								Result.PhoneNumber,
								Result.Email,
								IncomingContext.SubscriberID,
								IncomingContext.NotaryLawyerHeadOfFarm);
		
		WaitForExecutionCompletionInBackground(Notification, TimeConsumingOperation);
		
	Else
		NegativeResult = CreateContainerAndRequestForCertificateResult(False, 
											"UserCanceledAction@" 
											+ NStr("ru = 'Не подтверждены данные для получения временных паролей';
													|en = 'Data for getting temporary passwords is not confirmed';"));
		ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, NegativeResult);
	EndIf;
	
EndProcedure

Procedure CreateContainerAndRequestCertificateUponReceipt(TimeConsumingOperation, IncomingContext) Export
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		QueryResult = Result.ExecutionResult;
		If TypeOf(QueryResult) = Type("Structure") Then
			If QueryResult.Completed2 Then		
				ExecutionResult = CreateContainerAndRequestForCertificateResult(True, 
										QueryResult.CertificateRequest,
										QueryResult.PublicKey,
										QueryResult.ProviderName,
										QueryResult.ProviderType);
			Else
				ExecutionResult = CreateContainerAndRequestForCertificateResult(False,
										NStr("ru = 'Операция завершилась с ошибкой';
											|en = 'Operation failed';") + " " +  
										QueryResult.ErrorDescription);
			EndIf;
		Else
			ExecutionResult = CreateContainerAndRequestForCertificateResult(False, 
									NStr("ru = 'Операция завершилась с ошибкой';
										|en = 'Operation failed';"));
		EndIf;
	Else
		ExecutionResult = CreateContainerAndRequestForCertificateResult(False, 
			ErrorProcessing.DetailErrorDescription(Result.ErrorInfo));
	EndIf;
	
	ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, ExecutionResult);
	
EndProcedure

#EndRegion

#Region InitializeKeyContainer

Function InstallCertificateInContainerAndStoreResult(Completed2 = False, 
											ErrorDescription = "")
											
	Result = New Structure();
	Result.Insert("Completed2", Completed2);
	If Not Completed2 Then
		Result.Insert("ErrorDescription", ErrorDescription);
	EndIf;
	
	Return Result;
											
EndFunction

Procedure BindCertToContainerAndSystemStore(CallbackOnCompletion, ApplicationID, CertificateData) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	
	Notification 			= New NotifyDescription("InstallCertificateInContainerAndStorageAfterExecution", ThisObject, Context);
	ProcedureParameters 	= New Structure;
	ProcedureParameters.Insert("ApplicationID", 	ApplicationID);
	ProcedureParameters.Insert("CertificateData", 		CertificateData);
	
	TimeConsumingOperation = CryptographyServiceManagerInternalServerCall.BindCertToContainerAndSystemStore(ApplicationID,
								CertificateData);
		
	WaitForExecutionCompletionInBackground(Notification, TimeConsumingOperation);
		
EndProcedure

Procedure InstallCertificateInContainerAndStorageAfterExecution(TimeConsumingOperation, IncomingContext) Export
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		
		QueryResult = Result.ExecutionResult;
		If TypeOf(QueryResult) = Type("Structure") Then
			If QueryResult.Completed2 Then		
				ExecutionResult = InstallCertificateInContainerAndStoreResult(True);
			Else
				ExecutionResult = InstallCertificateInContainerAndStoreResult(False, 
										QueryResult.ErrorDescription);
			EndIf;
		Else
			ExecutionResult = InstallCertificateInContainerAndStoreResult(False, 
									NStr("ru = 'Операция завершилась с ошибкой';
										|en = 'Operation failed';"));
		EndIf;
	Else
		ExecutionResult = InstallCertificateInContainerAndStoreResult(
			False, ErrorProcessing.DetailErrorDescription(Result.ErrorInfo));
	EndIf;
	
	ExecuteNotifyProcessing(IncomingContext.CallbackOnCompletion, ExecutionResult);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure WaitForExecutionCompletionInBackground(CallbackOnCompletion, TimeConsumingOperation) Export
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Undefined);
	IdleParameters.OutputIdleWindow = False;
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);

EndProcedure

Function GetBackgroundExecutionResult(TimeConsumingOperation)
	
	ExecutionResult = New Structure("Completed2", False);
	
	If TimeConsumingOperation = Undefined Then
		ExecutionResult.Insert("ErrorInfo", 
					NStr("ru = 'Вызов API сервиса криптографии не был завершен штатно.';
						|en = 'API cryptography service was not called correctly.';"));
	ElsIf TimeConsumingOperation.Status = "Completed2" Then
		ExecutionResult.Completed2 = True;
		ExecutionResult.Insert("ExecutionResult", 
					GetFromTempStorage(TimeConsumingOperation.ResultAddress));
	Else
		ErrorDescription = TimeConsumingOperation.BriefErrorDescription;
		If TypeOf(ErrorDescription) = Type("String") Then
			Try
				Raise ErrorDescription;
			Except	
				ExecutionResult.Insert("ErrorInfo", ErrorInfo());
			EndTry;	
		Else	
			ExecutionResult.Insert("ErrorInfo", ErrorDescription);
		EndIf;
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

#EndRegion