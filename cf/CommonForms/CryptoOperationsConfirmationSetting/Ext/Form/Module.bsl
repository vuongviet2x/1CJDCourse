#Region Variables

&AtClient
Var CloseProgrammatically;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skipping initialization to ensure getting the form when passing the Autotest parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	CryptoOperationCycle	= True;
	Certificate 			= Parameters.Certificate;
	CertificateStructure	= DigitalSignatureSaaS.CertificateSigningDecryptionProperties(Certificate);
	
	If Parameters.Property("CryptoOperationsConfirmationMethod") Then
		CryptoOperationsConfirmationMethod = Parameters.CryptoOperationsConfirmationMethod;
	Else
		CryptoOperationsConfirmationMethod = CertificateStructure.CryptoOperationsConfirmationMethod;
	EndIf;
	
	If Parameters.Property("CryptoOperationCycle") Then
		CryptoOperationCycle = Parameters.CryptoOperationCycle;
	EndIf;
	
	CertificateThumbprint = DigitalSignatureSaaS.FindCertificateById(Certificate);
	
	If Not ValueIsFilled(CryptoOperationsConfirmationMethod) Then
		CryptoOperationsConfirmationMethod = Enums.CryptoOperationsConfirmationMethods.SessionToken;
	EndIf;	
	
	InitialValueOfCryptoOperationConfirmationMethod = CryptoOperationsConfirmationMethod;
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CloseProgrammatically	= False;
	Items.CryptoOperationsConfirmationMethod.ToolTip = 
			DigitalSignatureSaaSClientServer.GetDescriptionOfWaysToConfirmCryptoOperations();
	UpdateCertificateDisplay();
	
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
Procedure CryptoOperationsConfirmationMethodOnChange(Item)
	
	AuthorizationStep = 4;
	FormControl(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CloseOpen(FormParameters)
	
	CloseProgrammatically = True;
	
	If FormParameters = Undefined Then
		FormParameters = New Structure();
		FormParameters.Insert("CryptoOperationsConfirmationMethod", InitialValueOfCryptoOperationConfirmationMethod);
		FormParameters.Insert("Completed2", False);
		FormParameters.Insert("State", "ContinueReceivingSecurityToken");
	EndIf;
	
	If IsOpen() Then 
		Close(FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure Confirm(Command)
	
	If CryptoOperationsConfirmationMethod = PredefinedValue("Enum.CryptoOperationsConfirmationMethods.LongLivedToken") 
		And CryptoOperationsConfirmationMethod <> InitialValueOfCryptoOperationConfirmationMethod Then
		NewNtoification = OnCloseNotifyDescription;
		OnCloseNotifyDescription = Undefined;
		CloseOpen(Undefined);
		
		DigitalSignatureSaaSClient.DisableConfirmationOfCryptoOperations(Certificate, NewNtoification);
	Else	
		ReflectChangesServer();
		
		FormParameters = New Structure;
		FormParameters.Insert("CryptoOperationsConfirmationMethod", CryptoOperationsConfirmationMethod);
		FormParameters.Insert("Completed2", True);
		FormParameters.Insert("State", "ContinueReceivingSecurityToken");
		
		CloseOpen(FormParameters);
	EndIf;	
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function FullPresentationOfCertificate(CertificateThumbprint)
	
	Result					= "CertificateThumbprint";
	SearchingCertificate				= New Structure("Thumbprint", CertificateThumbprint);
	CertificateData		    = CertificatesStorage.FindCertificate(SearchingCertificate);
	CertificateProperties			= New Structure("StartDate, EndDate, Description");
	
	Try
		FillPropertyValues(CertificateProperties, CertificateData);
	
		CertificateIsValidWith 	= CertificateProperties.StartDate;
		CertificateIsValidFor 	= CertificateProperties.EndDate;
		
		If TypeOf(CertificateIsValidWith) = Type("String") Then 
			CertificateIsValidWith = StrReplace(CertificateIsValidWith, Char(10), "");
		EndIf;
			
		If TypeOf(CertificateIsValidFor) = Type("String") Then 
			CertificateIsValidFor = StrReplace(CertificateIsValidFor, Char(10), "");
		EndIf;
		
		Result = TrimAll(CertificateData.Description) + " (" + CertificateIsValidWith + " - " + CertificateIsValidFor + ")";
	Except
		
	EndTry;	
	
	Return Result;
	
EndFunction

&AtClient
Procedure UpdateCertificateDisplay()
	
	CertificatePresentation = FullPresentationOfCertificate(CertificateThumbprint);

EndProcedure

&AtClient
Procedure ShowMessage(MessageText, Wait = False, IsError = False)
	
	Items.Explanation.Title = MessageText;
	If IsError Then 
		Items.Explanation.TextColor = WebColors.Red;
	Else
		Items.Explanation.TextColor = New Color;
	EndIf;	
	
	If Items.TimeConsumingOperationIndicator.Visible <> Wait Then
		Items.TimeConsumingOperationIndicator.Visible = Wait;
	EndIf;	
	
EndProcedure

&AtClient
Procedure GetSettingsForGettingTemporaryPasswordsAfterExecution(Result, IncomingContext) Export
	
	Result = CryptographyServiceInternalClient.GetBackgroundExecutionResult(Result);
	
	If Result.Completed2 Then
		PhoneSettings   = Result.ExecutionResult;
		Recipient 			= PhoneSettings.Phone;
		ShowMessage("", False);
		FormControl(ThisObject);
		
	Else	
		ShowMessage(NStr("ru = 'Сервис отправки SMS-сообщений временно недоступен. Повторите попытку позже.';
								|en = 'SMS service is temporarily unavailable. Try again later.';"), , True);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Items = Form.Items;
	
	// Show current phone number.
	Items.ChangeRecipient.Title = NStr("ru = 'Изменить номер';
												|en = 'Change number';");
	Items.Confirm.Enabled = Form.AuthorizationStep = 4;
	
EndProcedure

&AtClient
Procedure ChangeRecipient(Command)
	
	If CryptoOperationCycle Then
		FormParameters = New Structure;
		FormParameters.Insert("State", "ChangingSettingsForGettingTemporaryPasswords");
		FormParameters.Insert("Certificate", Certificate);
		
		CloseOpen(FormParameters);
		
	Else
		CloseOpen(Undefined);
		DigitalSignatureSaaSClient.ChangeSettingsForGettingTemporaryPasswords(Certificate);
		
	EndIf;	
	
EndProcedure

&AtServer
Procedure ReflectChangesServer()
	
	DigitalSignatureSaaS.ConfigureUseOfLongTermToken(CryptoOperationsConfirmationMethod, Certificate);
	
EndProcedure	

#EndRegion