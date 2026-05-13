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

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.AttachableCommands

// Determines API content for integration with the configuration.
//
// Parameters:
//   Settings - Structure - Integration settings for this object:
//     * AddSendInvitationCommands - Boolean
//     * Location - Array of String
//
Procedure OnDefineSettings(Settings) Export
	
	Settings.AddSendInvitationCommands = True;
	Settings.Location.Add(Metadata.Documents.PollPurpose);
	
EndProcedure

// Defines a list of attachable commands to be output to the "SubmenuSendPollInvitation" submenu of configuration objects.
// Submenu parameters are See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds.
//
// Parameters:
//   Commands - ValueTable - Table describing the commands to add internal attachable commands to.
//                               See the column list in the description of the Commands parameter
//                               (procedure AttachableCommandsOverridable.OnDefineCommandsAttachedToObject).
//   Parameters - Structure - Auxiliary input parameters required for generating commands.
//       See details of the FormSettings parameter of the AttachableCommandsOverridable.OnDefineCommandsAttachedToObject procedure.
//
Procedure AddSendInvitationCommands(Commands, Parameters) Export
	
	If GetFunctionalOption("UseMessageTemplates") 
		And AccessRight("View", Metadata.DataProcessors._DemoSendSurveyInvitation) Then
		Command                  = Commands.Add();
		Command.Presentation    = NStr("ru = 'Пригласить';
										|en = 'Invite';");
		Command.Id    = "SendSurveyInvitation";
		Command.Handler       = "SendSurveyInvitation";
		Command.FormName         =  "DataProcessor._DemoSendSurveyInvitation.Form";
		Command.Kind              = "SendPollInvitation";
	EndIf;
	
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#Region Private

// Parameters:
//  ServerCallParameters - AnyRef
//                         - Array of AnyRef
//  StorageAddress - String
//
Procedure CreateAndSendEmail(ServerCallParameters, StorageAddress) Export
	
	Accounts_ = EmailOperations.AvailableEmailAccounts(True);
	If Accounts_.Count() = 0 Then
		Try
			Raise NStr("ru = 'Почта не указана или содержит некорректные сведения.';
									|en = 'Email account is not specified or contains incorrect information.';");
		Except
			FillInResult(StorageAddress, ErrorInfo());
		EndTry;
		Return;
	Else
		Account = Accounts_[0].Ref;
	EndIf;
	
	TemplateOwner = ?(TypeOf(ServerCallParameters.Ref) = Type("Array"), ServerCallParameters.Ref[0], ServerCallParameters.Ref);
	
	Template = MessageTemplates.TemplateParameters(TemplateOwner);
	UUID = Undefined;
	Message = MessageTemplates.GenerateMessage(Template.Ref, TemplateOwner, UUID);
	Recipients = InvitationRecipients(TemplateOwner);
	
	EmailParameters = New Structure();
	EmailParameters.Insert("BCCs", Recipients);
	EmailParameters.Insert("Subject", Message.Subject);
	EmailParameters.Insert("Body", Message.Text);
	
	TextType = ?(Message.AdditionalParameters.EmailFormat1 = Enums.EmailEditingMethods.HTML, "HTML", "PlainText");
	EmailParameters.Insert("TextType", TextType);
	EmailParameters.Insert("Attachments", Common.ValueTableToArray(Message.Attachments));
	
	MailMessage = EmailOperations.PrepareEmail(Account, EmailParameters);
	Try
		EmailOperations.SendMail(Account, MailMessage);
	Except
		FillInResult(StorageAddress, ErrorInfo());
		Return;
	EndTry;
	
	FillInResult(StorageAddress);
	
EndProcedure

Procedure FillInResult(StorageAddress, ErrorInfo = Undefined)
	
	Result = New Structure("Success, ErrorInfo", True);
	If ErrorInfo <> Undefined Then
		Result.Success = False;
		Result.ErrorInfo = ErrorInfo;
	EndIf;
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Function InvitationRecipients(Val TemplateOwner)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PurposeOfSurveysRespondents.Respondent AS Respondent
	|FROM
	|	Document.PollPurpose.Respondents AS PurposeOfSurveysRespondents
	|WHERE
	|	PurposeOfSurveysRespondents.Ref = &Ref";
	
	Query.SetParameter("Ref", TemplateOwner);
	Respondents = Query.Execute().Unload().UnloadColumn("Respondent");
	
	ContactInformationTypes = CommonClientServer.ValueInArray(Enums.ContactInformationTypes.Email);
	RespondentsEmail = ContactsManager.ObjectsContactInformation(Respondents, ContactInformationTypes);
	Recipients = New Array;
	For Each Recipient In RespondentsEmail Do
		Recipients.Add(New Structure("Address, Presentation", Recipient.Presentation, String(Recipient.Object)));
	EndDo;
	
	Return Recipients;

EndFunction

#EndRegion

#EndIf