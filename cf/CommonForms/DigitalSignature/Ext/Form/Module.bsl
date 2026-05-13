///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SignatureProperties = DigitalSignatureClientServer.ResultOfSignatureValidationOnForm();
	FillPropertyValues(SignatureProperties, Parameters.SignatureProperties);
	
	FillPropertyValues(ThisObject, SignatureProperties);
	FillPropertyValues(ThisObject, SignatureProperties.CheckResult);
	
	If Parameters.SignatureProperties.Property("Object") Then
		SignedObject = Parameters.SignatureProperties.Object;
	EndIf;
	
	Items.GroupMachineReadableLOA.Visible = False;
	
	
	Items.AdditionalAttributesManualCheckJustification.Visible = ValueIsFilled(AdditionalAttributesManualCheckJustification)
		And StrLen(AdditionalAttributesManualCheckJustification) > 100;
	
	If ValueIsFilled(ErrorDescription) Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "ErrorDescription");
		Items.Instruction.Visible     = 
			DigitalSignatureInternal.VisibilityOfRefToAppsTroubleshootingGuide();
	ElsIf ValueIsFilled(AdditionalAttributesManualCheckJustification) Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "ManualVerification");
		Items.Instruction.Visible     = False;
	Else
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "");
		Items.Instruction.Visible     = False;
	EndIf;
	
	If Not IsTempStorageURL(SignatureAddress) Then
		Return;
	EndIf;
	
	SignAlgorithmDoesNotComplyWithGOST = "";
	SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(
		SignatureAddress, True, False, SignAlgorithmDoesNotComplyWithGOST);
		
	If ValueIsFilled(SignAlgorithmDoesNotComplyWithGOST) Then
		SignAlgorithm = SignAlgorithmDoesNotComplyWithGOST;
		Items.SignAlgorithm.Visible = False;
		Items.SignAlgorithmWarning.Visible = True;
	Else
		Items.SignAlgorithm.Visible = True;
		Items.SignAlgorithmWarning.Visible = False;
	EndIf;
	
	HashAlgorithm = DigitalSignatureInternalClientServer.HashAlgorithm(
		SignatureAddress, True);
	
	If ValueIsFilled(Status) Then
		Items.DecorationStatus.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Статус на %1: %2';
					|en = 'Status as of %1: %2';"), SignatureValidationDate, Status);
	Else
		Items.DecorationStatus.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Статус на %1: %2';
					|en = 'Status as of %1: %2';"), SignatureValidationDate, BriefCheckResult);
	EndIf;
	
	Items.ErrorDescription.Visible = Not IsBlankString(ErrorDescription);
	Items.Comment.Visible = Not IsBlankString(Comment);
	
	Items.GroupMathValidationError.Visible   = Not IsBlankString(SignatureMathValidationError);
	Items.GroupErrorOnAdditionalAttributesManualCheck.Visible = Not IsBlankString(AdditionalAttributesCheckError);
	
	UpdateFormData();
		
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InstructionClick(Item)
	
	DigitalSignatureClient.OpenInstructionOnTypicalProblemsOnWorkWithApplications();
	
EndProcedure


#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveToFile(Command)
	
	DigitalSignatureClient.SaveSignature(SignatureAddress);
	
EndProcedure

&AtClient
Procedure OpenCertificate(Command)
	
	If ValueIsFilled(CertificateAddress) Then
		DigitalSignatureClient.OpenCertificate(CertificateAddress);
		
	ElsIf ValueIsFilled(Thumbprint) Then
		DigitalSignatureClient.OpenCertificate(Thumbprint);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenCertificateToVerifySignature(Command)
	
	If Not ArePropertiesRead Or ValueIsFilled(SignatureReadError) Then
		DigitalSignatureClient.ReadSignatureProperties(
			New NotifyDescription("AfterSignaturePropertiesRead", ThisObject), SignatureAddress);
		Return;
	Else
		OpenCertificateRead();
	EndIf;
	
EndProcedure

&AtClient
Procedure ExtendActionSignature(Command)
	
	FollowUpHandler = New NotifyDescription("AfterImprovementSignature", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("SignatureType", SignatureType);
	FormParameters.Insert("DataPresentation", 
		StrTemplate("%1, %2, %3", CertificateOwner, SignatureDate, SignatureType));
		
	If ValueIsFilled(SignedObject) Then
		Structure = New Structure;
		Structure.Insert("Signature", SignatureAddress);
		Structure.Insert("SignedObject", SignedObject);
		Structure.Insert("SequenceNumber", SequenceNumber); 
		FormParameters.Insert("Signature", Structure);
	Else
		FormParameters.Insert("Signature", SignatureAddress);
	EndIf;
	
	DigitalSignatureClient.OpenRenewalFormActionsSignatures(ThisObject, FormParameters, FollowUpHandler);
	
EndProcedure

&AtClient
Procedure OpenMathValidationErrorDetails(Command)
	
	OpenErrorDescription(SignatureMathValidationError);
	
EndProcedure

&AtClient
Procedure OpenAdditionalAttributesErrorDetails(Command)
	
	OpenErrorDescription(AdditionalAttributesCheckError);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OpenErrorDescription(ErrorText)
	
	FormParameters = New Structure;
	FormParameters.Insert("WarningTitle", NStr("ru = 'Проверка подписи';
															|en = 'Signature verification';"));
	FormParameters.Insert("ErrorTextClient", ErrorText);
	FormParameters.Insert("ShowNeedHelp", True);
	FormParameters.Insert("ShowInstruction", True);
	
	AdditionalParameters = New Structure;
	
	If ValueIsFilled(CertificateAddress) Then
		AdditionalParameters.Insert("CertificateData",
			CertificateAddress);
	EndIf;
	
	If ValueIsFilled(SignatureAddress) Then
		AdditionalParameters.Insert("SignatureData",
			SignatureAddress);
	EndIf;
		
	FormParameters.Insert("AdditionalData", AdditionalParameters);
	
	DigitalSignatureInternalClient.OpenExtendedErrorPresentationForm(FormParameters, ThisObject);

EndProcedure

&AtServer
Procedure UpdateFormData()
	
	If DigitalSignature.AvailableAdvancedSignature() And DigitalSignature.AddEditDigitalSignatures() Then
		If (ValueIsFilled(DateActionLastTimestamp) And DateActionLastTimestamp <= CurrentSessionDate())
			Or SignatureType = Enums.CryptographySignatureTypes.NormalCMS Or Not SignatureCorrect Then
			Items.FormExtendActionSignature.Visible = False;
		Else
			Items.FormExtendActionSignature.Visible = True;
		EndIf;
	Else
		Items.FormExtendActionSignature.Visible = False;
	EndIf;
		
	If SignatureType = Enums.CryptographySignatureTypes.BasicCAdESBES
		Or SignatureType = Enums.CryptographySignatureTypes.NormalCMS Then
		If ValueIsFilled(DateActionLastTimestamp) Then
			Items.DateActionLastTimestamp.Title = NStr("ru = 'Срок действия сертификата подписи истек';
																		|en = 'Certificate expired';"); 
		Else
			Items.DateActionLastTimestamp.Visible = False;
		EndIf;
	Else
		Items.DateActionLastTimestamp.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterImprovementSignature(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Success Then
		
		For Each KeyAndValue In Result.PropertiesSignatures[0].SignatureProperties Do
			If KeyAndValue.Key = "Signature" Then
				SignatureAddress = PutToTempStorage(KeyAndValue.Value);
				Continue;
			EndIf;
			If KeyAndValue.Value = Undefined Then
				Continue;
			EndIf;
			If Items.Find(KeyAndValue.Key) = Undefined Then
				Continue;
			EndIf;
			
			ThisObject[KeyAndValue.Key] = KeyAndValue.Value;
		EndDo;
		
		UpdateFormData();
	EndIf;
	
EndProcedure

&AtClient
Async Procedure AfterSignaturePropertiesRead(Result, AdditionalParameters) Export
	
	ArePropertiesRead = True;
	
	If Result.Success = True Then
		SignatureReadError = "";
		HasSignatureCertificate = False;
		For Each CertificateData In Result.Certificates Do
			
			NewRow = CertificatesToVerifySignature.Add();
			
			CryptoCertificate = New CryptoCertificate;
			Await CryptoCertificate.InitializeAsync(CertificateData);
			CertificateProperties = Await DigitalSignatureInternalClient.CertificateProperties(CryptoCertificate);
			NewRow.IssuedTo = CertificateProperties.Presentation;
			NewRow.CertificateData = PutToTempStorage(CertificateData, UUID);
			If CertificateData = Result.Certificate Then
				NewRow.IsSignatureCertificate = True;
				HasSignatureCertificate = True;
			EndIf;
			
		EndDo;
		
		If Not HasSignatureCertificate And ValueIsFilled(Result.Certificate) Then
			
			NewRow = CertificatesToVerifySignature.Add();
			
			CryptoCertificate = New CryptoCertificate;
			Await CryptoCertificate.InitializeAsync(Result.Certificate);
			CertificateProperties = Await DigitalSignatureInternalClient.CertificateProperties(CryptoCertificate);
			NewRow.IssuedTo = CertificateProperties.Presentation;
			NewRow.CertificateData = PutToTempStorage(Result.Certificate, UUID);
			NewRow.IsSignatureCertificate = True;
			
		EndIf;
	ElsIf Result.Success = Undefined Then
		SignatureReadError = NStr("ru = 'Не удалось получить сертификаты из подписи, проверьте настройки приложений электронной подписи.';
									|en = 'Couldn''t get certificates from the signature. Check the settings of the digital signing apps.';");
	Else
		SignatureReadError = Result.ErrorText;
	EndIf;
		
	CertificatesToVerifySignature.Sort("IsSignatureCertificate Desc");
	OpenCertificateRead();
	
EndProcedure

&AtClient
Async Procedure OpenCertificateRead()
	
	If ValueIsFilled(SignatureReadError) Then
		ShowMessageBox(, SignatureReadError);
		Return;
	EndIf;
	
	Count = CertificatesToVerifySignature.Count();
	
	If Count > 1 Then
		
		ValueList = New ValueList();
		For Each Certificate In CertificatesToVerifySignature Do
			
			If Certificate.IsSignatureCertificate Then
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Сертификат подписанта: %1';
						|en = 'Signer''s certificate: %1';"), Certificate.IssuedTo);
			Else
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Сертификат для проверки подписи: %1';
						|en = 'Certificate for signature verification: %1';"), Certificate.IssuedTo);
			EndIf;
			
			ValueList.Add(Certificate.CertificateData, Presentation);
				
		EndDo;
		
		SelectedItemsCount = Await ValueList.ChooseItemAsync(NStr("ru = 'Выберите сертификат';
																|en = 'Select a certificate';"));

		If SelectedItemsCount <> Undefined Then
			DigitalSignatureClient.OpenCertificate(SelectedItemsCount.Value);
		EndIf;
		
	ElsIf Count = 1 Then
		DigitalSignatureClient.OpenCertificate(CertificatesToVerifySignature[0].CertificateData);
	EndIf;
	
EndProcedure

#EndRegion
