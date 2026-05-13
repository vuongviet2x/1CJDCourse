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
	
	AdditionalData = Parameters.AdditionalData;
	
	If ValueIsFilled(AdditionalData) Then
		SignatureVerificationError = CommonClientServer.StructureProperty(AdditionalData, "SignatureData", False) = True;
	EndIf;
	
	If ValueIsFilled(Parameters.SupportInformation) Then
		Items.SupportInformation.Title = Parameters.SupportInformation;
	Else
		Items.SupportInformation.Title = DigitalSignatureInternal.InfoHeadingForSupport();
	EndIf;
	
	DigitalSignatureInternal.ToSetTheTitleOfTheBug(ThisObject,
		Parameters.WarningTitle);
	
	ErrorTextClient = Parameters.ErrorTextClient;
	ErrorTextServer = Parameters.ErrorTextServer;
	ErrorText = Parameters.ErrorText;
	
	TwoMistakes = Not IsBlankString(ErrorTextClient)
		And Not IsBlankString(ErrorTextServer);
	
	SetItems(ErrorTextClient, TwoMistakes, "Client");
	SetItems(ErrorTextServer, TwoMistakes, "Server");
	SetItems(ErrorText, TwoMistakes, "");
	
	Items.SeparatorDecoration.Visible = TwoMistakes;
	
	Items.FooterGroup.Visible = Parameters.ShowNeedHelp;
	Items.SeparatorDecoration2.Visible = Parameters.ShowNeedHelp;
	
	URL = "";
	DigitalSignatureClientServerLocalization.OnDefineRefToSearchByErrorsWhenManagingDigitalSignature(
		URL);
	
	GuideRefVisibility = URL <> "";
	
	If Parameters.ShowNeedHelp Then
		Items.Help.Visible                     = Parameters.ShowInstruction;
		Items.FormOpenApplicationsSettings.Visible = Parameters.ShowOpenApplicationsSettings;
		Items.FormInstallExtension.Visible      = Parameters.ShowExtensionInstallation;
		ErrorDescription = Parameters.ErrorDescription;
	EndIf;
	
	Items.InstructionClient.Visible = GuideRefVisibility And Not IsBlankString(ErrorTextClient);
	Items.InstructionServer.Visible = GuideRefVisibility And Not IsBlankString(ErrorTextServer);
	
	StandardSubsystemsServer.ResetWindowLocationAndSize(ThisObject);
	
	If ValueIsFilled(Parameters.TextOfAdditionalLink) Then
		Items.AdditionalLink.Visible = True;
		Items.AdditionalLink.Title = StringFunctions.FormattedString(Parameters.TextOfAdditionalLink);
	Else
		Items.AdditionalLink.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
#If Not MobileAppClient And Not MobileClient Then
	If ClassifierErrorSolutionTextSupplementOptions <> Undefined Then
		AttachIdleHandler("SupplementErrorClassifierSolutionWithDetails", 0.1, True);
	EndIf;
#EndIf
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InstructionClick(Item)
	
	ErrorAnchor = ""; SearchText = "";
	If Item.Name = "InstructionClient" Then
		SearchText = ErrorTextClient;
		
	ElsIf Item.Name = "InstructionServer" Then
		SearchText = ErrorTextServer;
		
	EndIf;
	
	DigitalSignatureClient.OpenSearchByErrorsWhenManagingDigitalSignature(SearchText);
	
EndProcedure

&AtClient
Procedure SupportInformationURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	
	If Var_URL = "TypicalIssues" Then
		DigitalSignatureClient.OpenInstructionOnTypicalProblemsOnWorkWithApplications();
	Else
		
		UploadTechnicalInformation(False);
		
	EndIf;
	
EndProcedure

&AtClient
Function MessageSubject1(Val Error)
	
	LineBreak = StrFind(Error, Chars.LF);
	If LineBreak = 0 Then
		MessageSubject1 = Left(Error, 100);
	Else
		MessageSubject1 = Left(Error, LineBreak - 1);
	EndIf;
	
	Return MessageSubject1;
	
EndFunction

&AtClient
Procedure ReasonsClientTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DigitalSignatureInternalClient.HandleNaviLinkClassifier(
		Item, FormattedStringURL, StandardProcessing, AdditionalData());
EndProcedure

&AtClient
Procedure DecisionsClientTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DigitalSignatureInternalClient.HandleNaviLinkClassifier(
		Item, FormattedStringURL, StandardProcessing, AdditionalData());
EndProcedure

&AtClient
Procedure ReasonsServerTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DigitalSignatureInternalClient.HandleNaviLinkClassifier(
		Item, FormattedStringURL, StandardProcessing, AdditionalData());
EndProcedure

&AtClient
Procedure DecisionsServerTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DigitalSignatureInternalClient.HandleNaviLinkClassifier(
		Item, FormattedStringURL, StandardProcessing, AdditionalData());
EndProcedure

&AtClient
Procedure AdditionalLinkURLProcessing(Item, FormattedStringURL, StandardProcessing)

	If ValueIsFilled(Parameters.AdditionalLinkHandler) Then
		
		StandardProcessing = False;
		FullProcedureName = Parameters.AdditionalLinkHandler;
		PartsOfProcedureName = StrSplit(FullProcedureName, ".");
		ModuleName = PartsOfProcedureName[0];
		ProcedureName = PartsOfProcedureName[1];
		Notification = New NotifyDescription(ProcedureName, CommonClient.CommonModule(ModuleName));
		
		NotificationParameter1 = New Structure("ParameterOfAdditionalLinkHandler, URL",
			Parameters.ParameterOfAdditionalLinkHandler, FormattedStringURL);
		
		ExecuteNotifyProcessing(Notification, NotificationParameter1);
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenApplicationsSettings(Command)
	
	Close();
	DigitalSignatureClient.OpenDigitalSignatureAndEncryptionSettings("Programs");
	
EndProcedure

&AtClient
Procedure InstallExtension(Command)
	
	DigitalSignatureClient.InstallExtension(True);
	Close();
	
EndProcedure

&AtClient
Procedure DownloadTechnicalInformation(Command)
	
	UploadTechnicalInformation(True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UploadTechnicalInformation(ExportArchive)

	If ExportArchive Then
		Items.DownloadTechnicalInformation.Enabled = False;
		Items.GroupGeneratesTechnicalInformation.Visible = True;
	EndIf;
	
	FilesDetails = New Array;
	ErrorsText = "";
	If ValueIsFilled(AdditionalData) Then
		DigitalSignatureInternalServerCall.AddADescriptionOfAdditionalData(
			AdditionalData, FilesDetails, ErrorsText);
	EndIf;
	
	If ValueIsFilled(ErrorDescription) Then
		MessageSubject1 = MessageSubject1(ErrorDescription);
	ElsIf ValueIsFilled(ErrorText) Then
		MessageSubject1 = MessageSubject1(ErrorText);
	ElsIf ValueIsFilled(ErrorTextClient) Then
		MessageSubject1 = MessageSubject1(ErrorTextClient);
	ElsIf ValueIsFilled(ErrorTextServer) Then
		MessageSubject1 = MessageSubject1(ErrorTextServer);
	Else
		MessageSubject1 = NStr("ru = 'Техническая информация о возникшей проблеме';
							|en = 'Technical details about the issue';");
	EndIf;
	
	Array = New Array;
	If ValueIsFilled(ErrorsText) Then
		Array.Add(ErrorsText);
	EndIf;
	If ValueIsFilled(ErrorDescription) Then
		Array.Add(ErrorDescription);
	EndIf;
	If ValueIsFilled(ErrorText) Then
		Array.Add(ErrorText);
	EndIf;
	If ValueIsFilled(ErrorTextClient) Then
		Array.Add(NStr("ru = 'На клиенте:';
							|en = 'On client:';"));
		Array.Add(ErrorTextClient);
	EndIf;
	If ValueIsFilled(ErrorTextServer) Then
		Array.Add(NStr("ru = 'На сервере:';
							|en = 'On server:';"));
		Array.Add(ErrorTextServer);
	EndIf;
	
	ErrorsText = StrConcat(Array, Chars.LF);
	
	If ExportArchive Then
		DigitalSignatureInternalClient.GenerateTechnicalInformation(
			ErrorsText, Undefined, New NotifyDescription("AfterUploadingTechnicalInformation", ThisObject), FilesDetails);
	Else
		DigitalSignatureInternalClient.GenerateTechnicalInformation(
			ErrorsText, New Structure("Subject, Message", MessageSubject1), , FilesDetails);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterUploadingTechnicalInformation(Result, Context) Export
	
	Items.DownloadTechnicalInformation.Enabled = True;
	Items.GroupGeneratesTechnicalInformation.Visible = False;

EndProcedure

&AtClient
Procedure SupplementErrorClassifierSolutionWithDetails()
	
	ClassifierError = New Structure;
	ClassifierError.Insert("ErrorText", Items.ErrorTextClient.Title);
	ClassifierError.Insert("Cause", Items.ReasonsClientText.Title);
	ClassifierError.Insert("Decision", Items.DecisionsClientText.Title);
	
	DataToSupplement = DigitalSignatureInternalClientServer.DataToSupplementErrorFromClassifier(AdditionalData);
	DigitalSignatureInternalClient.SupplementErrorClassifierSolutionWithDetails(
		New NotifyDescription("AfterErrorClassifierSolutionSupplemented", ThisObject),
		ClassifierError, ClassifierErrorSolutionTextSupplementOptions, DataToSupplement);
		
EndProcedure

&AtClient
Procedure AfterErrorClassifierSolutionSupplemented(ClassifierError, Context) Export
	
	If Items.DecisionsClientText.Title <> ClassifierError.Decision Then
		Items.DecisionsClientText.Title = ClassifierError.Decision;
	EndIf;
	If Items.ReasonsClientText.Title <> ClassifierError.Cause Then
		Items.ReasonsClientText.Title = ClassifierError.Cause;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetItems(ErrorText, TwoMistakes, ErrorLocation)
	
	If ErrorLocation = "Server" Then
		ItemError = Items.ErrorServer;
		ErrorTextElement = Items.ErrorTextServer;
		InstructionItem = Items.InstructionServer;
		ReasonItemText = Items.ReasonsServerText;
		ItemDecisionText = Items.DecisionsServerText;
		ReasonsAndDecisionsGroup = Items.PossibleReasonsAndSolutionsServer;
	ElsIf ErrorLocation = "Client" Then
		ItemError = Items.ErrorClient;
		ErrorTextElement = Items.ErrorTextClient;
		InstructionItem = Items.InstructionClient;
		ReasonItemText = Items.ReasonsClientText;
		ItemDecisionText = Items.DecisionsClientText;
		ReasonsAndDecisionsGroup = Items.PossibleReasonsAndSolutionsClient;
		Items.TitleClient.Visible = TwoMistakes;
	Else
		ItemError = Items.Error;
		ErrorTextElement = Items.ErrorText;
		InstructionItem = Items.Instruction;
		ReasonItemText = Items.ReasonsText;
		ItemDecisionText = Items.SolutionsText;
		ReasonsAndDecisionsGroup = Items.PossibleReasonsAndSolutions;
	EndIf;
	
	ItemError.Visible = Not IsBlankString(ErrorText);
	If Not IsBlankString(ErrorText) Then
		
		HaveReasonAndSolution = Undefined;
		If TypeOf(AdditionalData) = Type("Structure") Then
			If ErrorLocation = "Server" Then
				ChecksSuffix = "AtServer";
			ElsIf ErrorLocation = "Client" Then
				ChecksSuffix = "AtClient";
			Else
				ChecksSuffix = "";
			EndIf;
				
			HaveReasonAndSolution = CommonClientServer.StructureProperty(AdditionalData, 
				"Additional_DataChecks" + ChecksSuffix, Undefined); // See DigitalSignatureInternalClientServer.WarningWhileVerifyingCertificateAuthorityCertificate
		EndIf;
		
		If ValueIsFilled(HaveReasonAndSolution) Then
			ClassifierError = DigitalSignatureInternal.ErrorPresentation();
			Cause = HaveReasonAndSolution.Cause; // String
			ClassifierError.Cause = FormattedString(Cause);
			ClassifierError.Decision = FormattedString(HaveReasonAndSolution.Decision);
		Else
			ClassifierError = DigitalSignatureInternal.ClassifierError(ErrorText, ErrorLocation = "Server", SignatureVerificationError);
		EndIf;
		
		IsKnownError = ClassifierError <> Undefined;
		
		ReasonsAndDecisionsGroup.Visible = IsKnownError;
			
		If IsKnownError Then
			
			ErrorTextElement.TitleLocation = FormItemTitleLocation.Top;
			
			If ValueIsFilled(ClassifierError.RemedyActions) Then
				If ClassifierErrorSolutionTextSupplementOptions = Undefined Then
					ClassifierErrorSolutionTextSupplementOptions = DigitalSignatureInternalClientServer.ClassifierErrorSolutionTextSupplementOptions();
				EndIf;
				DataToSupplement = DigitalSignatureInternalClientServer.DataToSupplementErrorFromClassifier(AdditionalData);
				AddOn = DigitalSignatureInternal.SupplementErrorClassifierSolutionWithDetails(
					ClassifierError, DataToSupplement, 
					ClassifierErrorSolutionTextSupplementOptions, ErrorLocation);
				ClassifierError = AddOn.ClassifierError;
				ClassifierErrorSolutionTextSupplementOptions = AddOn.ClassifierErrorSolutionTextSupplementOptionsAtClient;
			EndIf;
			
			If ValueIsFilled(ClassifierError.Cause) Then
				If TypeOf(ReasonItemText) = Type("FormDecoration") Then
					CommonClientServer.SetFormItemProperty(Items,
					ReasonItemText.Name, "Title", ClassifierError.Cause);
				Else
					ThisObject[ReasonItemText.DataPath] = ClassifierError.Cause;
				EndIf;
			Else
				CommonClientServer.SetFormItemProperty(Items,
				ReasonItemText.Name, "Visible", False);
			EndIf;
			
			If ValueIsFilled(ClassifierError.Decision) Then
				CommonClientServer.SetFormItemProperty(Items,
					ItemDecisionText.Name, "Title", ClassifierError.Decision);
			Else
				CommonClientServer.SetFormItemProperty(Items,
					ItemDecisionText.Name, "Visible", False);
			EndIf;
			
			If ErrorLocation = "Server" Then
				ErrorAnchorServer = ClassifierError.Ref;
			ElsIf ErrorLocation = "Client" Then
				ErrorAnchorClient = ClassifierError.Ref;
			Else
				ErrorAnchor = ClassifierError.Ref;
			EndIf;
		Else
			ErrorTextElement.TitleLocation = FormItemTitleLocation.None;
		EndIf;
		
		CommonClientServer.SetFormItemProperty(Items,
				InstructionItem.Name, "Title", NStr("ru = 'Поиск решения...';
														|en = 'Finding solution…';"));
		
		RequiredNumberOfRows = 0;
		MarginWidth = Int(?(Width < 20, 20, Width) * 1.4);
		For LineNumber = 1 To StrLineCount(ErrorText) Do
			RequiredNumberOfRows = RequiredNumberOfRows + 1
				+ Int(StrLen(StrGetLine(ErrorText, LineNumber)) / MarginWidth);
		EndDo;
		If RequiredNumberOfRows > 5 And Not TwoMistakes Then
			ErrorTextElement.Height = 5;
		ElsIf RequiredNumberOfRows > 3 Then
			ErrorTextElement.Height = 4;
		ElsIf RequiredNumberOfRows > 1 Then
			ErrorTextElement.Height = 2;
		Else
			ErrorTextElement.Height = 1;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Function AdditionalData()
	
	If Not ValueIsFilled(AdditionalData) Then
		Return Undefined;
	EndIf;
	
	AdditionalDataForErrorClassifier = DigitalSignatureInternalClient.AdditionalDataForErrorClassifier();
	Certificate = CommonClientServer.StructureProperty(AdditionalData, "Certificate", Undefined);
	If ValueIsFilled(Certificate) Then
		If TypeOf(Certificate) = Type("Array") Then
			If Certificate.Count() > 0 Then
				If TypeOf(Certificate[0]) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates") Then
					If ValueIsFilled(Certificate[0]) Then
						AdditionalDataForErrorClassifier.Certificate = Certificate[0];
						AdditionalDataForErrorClassifier.CertificateData = CertificateData(Certificate[0], UUID);
					EndIf;
				ElsIf IsTempStorageURL(Certificate[0]) Then
					AdditionalDataForErrorClassifier.CertificateData = Certificate[0];
				EndIf;
			EndIf;
		ElsIf TypeOf(Certificate) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates") Then
			If ValueIsFilled(Certificate) Then
				AdditionalDataForErrorClassifier.Certificate = Certificate;
				AdditionalDataForErrorClassifier.CertificateData = CertificateData(Certificate, UUID);
			EndIf;
		ElsIf TypeOf(Certificate) = Type("BinaryData") Then
			AdditionalDataForErrorClassifier.CertificateData = PutToTempStorage(Certificate, UUID);
		ElsIf IsTempStorageURL(Certificate) Then
			AdditionalDataForErrorClassifier.CertificateData = Certificate;
		EndIf;
	EndIf;
	
	CertificateData = CommonClientServer.StructureProperty(AdditionalData, "CertificateData", Undefined);
	If ValueIsFilled(CertificateData) Then
		AdditionalDataForErrorClassifier.CertificateData = CertificateData;
	EndIf;
	
	SignatureData = CommonClientServer.StructureProperty(AdditionalData, "SignatureData", Undefined);
	If ValueIsFilled(SignatureData) Then
		AdditionalDataForErrorClassifier.SignatureData = SignatureData;
	EndIf;
	
	Return AdditionalDataForErrorClassifier;

EndFunction

&AtServer
Function FormattedString(Val String)
	
	If TypeOf(String) = Type("String") Then
		String = StringFunctions.FormattedString(String);
	EndIf;
	
	Return String;
	
EndFunction

&AtServerNoContext
Function CertificateData(Certificate, UUID)
	
	CertificateData = Common.ObjectAttributeValue(Certificate, "CertificateData").Get();
	If ValueIsFilled(CertificateData) Then
		If ValueIsFilled(UUID) Then
			Return PutToTempStorage(CertificateData, UUID);
		Else
			Return CertificateData;
		EndIf;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#EndRegion
