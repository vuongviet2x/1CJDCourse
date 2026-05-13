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

// StandardSubsystems.BatchEditObjects

// Returns the object attributes that are not recommended to be edited
// using a bulk attribute modification data processor.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export

	Result = New Array;
	Result.Add("ContactInformation.*");
	Return Result;

EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.Print

// Override object's print settings.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export

EndProcedure

// End StandardSubsystems.Print

// StandardSubsystems.MessagesTemplates

// Called when preparing message templates. Overrides the list of attributes and attachments.
//
// Parameters:
//  Attributes - See MessageTemplatesOverridable.OnPrepareMessageTemplate.Attributes
//  Attachments  - See MessageTemplatesOverridable.OnPrepareMessageTemplate.Attachments
//  AdditionalParameters - Structure - Additional information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export

EndProcedure

// Called when creating a message from a template. Populates values in attributes and attachments.
//
// Parameters:
//  Message - Structure:
//    * AttributesValues - Map of KeyAndValue - List of template's attributes:
//      ** Key     - String - Template's attribute name.
//      ** Value - String - Template's filling value.
//    * CommonAttributesValues - Map of KeyAndValue - List of template's common attributes:
//      ** Key     - String - Template's attribute name.
//      ** Value - String - Template's filling value.
//    * Attachments - Map of KeyAndValue:
//      ** Key     - String - Template's attachment name.
//      ** Value - BinaryData
//                  - String - binary data or an address in a temporary storage of the attachment.
//  MessageSubject - AnyRef - The reference to a data source object.
//  AdditionalParameters - Structure -  Additional information about a message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export

EndProcedure

// Populates a list of recipients (in case the message is generated from a template).
//
// Parameters:
//   SMSMessageRecipients - ValueTable:
//     * PhoneNumber - String - Recipient's phone number.
//     * Presentation - String - Recipient presentation.
//     * Contact       - Arbitrary - The contact this phone number belongs to.
//  MessageSubject - AnyRef - The reference to a data source object.
//                   - Structure  - Structure that describes template parameters:
//    * SubjectOf               - AnyRef - The reference to a data source object.
//    * MessageKind - String - Message type: Email or SMSMessage.
//    * ArbitraryParameters - Map - List of arbitrary parameters.
//    * SendImmediately - Boolean - Flag indicating whether the message must be sent immediately.
//    * MessageParameters - Structure - Additional message parameters.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export

EndProcedure

// Populates a list of recipients (in case the message is generated from a template).
//
// Parameters:
//   EmailRecipients - ValueTable - List of message recipients:
//     * SendingOption - String - Messaging options: "Whom" (To), "Copy" (CC), "HiddenCopy" (BCC), and "ReplyTo".
//     * Address           - String - Recipient's email address.
//     * Presentation   - String - Recipient presentation.
//     * Contact         - Arbitrary - The contact this email address belongs to.
//  MessageSubject - AnyRef - The reference to a data source object.
//                   - Structure  - Structure that describes template parameters:
//    * SubjectOf               - AnyRef - The reference to a data source object.
//    * MessageKind - String - Message type: Email or SMSMessage.
//    * ArbitraryParameters - Map - List of arbitrary parameters.
//    * SendImmediately - Boolean - Flag indicating whether the message must be sent immediately.
//    * MessageParameters - Structure - Additional message parameters.
//    * ConvertHTMLForFormattedDocument - Boolean - Flag indicating whether the HTML text must be converted.
//             Applicable to messages containing images.
//             Required due to the specifics of image output in formatted documents. 
//    * Account - CatalogRef.EmailAccounts - Sender's email account.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export

	Individual = Common.ObjectAttributeValue(MessageSubject.SubjectOf, "Individual");
	MessageTemplates.FillRecipients(EmailRecipients, Individual, "Ref",
		Enums.ContactInformationTypes.Email, "Copy");

	UserEmailAddress = ContactsManager.ObjectContactInformationPresentation(
		Users.AuthorizedUser(), ContactsManager.ContactInformationKindByName("UserEmail"));
	NewRecipient =  EmailRecipients.Add();
	NewRecipient.SendingOption = "ReplyTo";
	NewRecipient.Address           = UserEmailAddress;
	NewRecipient.Presentation   = UserEmailAddress;

EndProcedure

// End StandardSubsystems.MessagesTemplates

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Owner)";

	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS _DemoPartnersContactPersons
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = _DemoPartnersContactPersons.Owner
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersContactPersons
	|	ON ExternalUsersContactPersons.AuthorizationObject = _DemoPartnersContactPersons.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)
	|	OR ValueAllowed(ExternalUsersContactPersons.Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region InfobaseUpdate

// Registers items for processing.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export

	DataProcessorRefs = ContactsManager.ObjectsThatRequireContactInformationUpdate(
		Metadata.Catalogs._DemoPartnersContactPersons);

	InfobaseUpdate.MarkForProcessing(Parameters, DataProcessorRefs);

EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export

	PartnerContactPerson = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue,
		"Catalog._DemoPartnersContactPersons");

	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;

	While PartnerContactPerson.Next() Do

		Block = New DataLock;
		LockItem = Block.Add("Catalog._DemoPartnersContactPersons");
		LockItem.SetValue("Ref", PartnerContactPerson.Ref);
		
		RepresentationOfTheReference = String(PartnerContactPerson.Ref);
		
		BeginTransaction();
		Try

			Block.Lock();
			CatalogObject = PartnerContactPerson.Ref.GetObject();

			If CatalogObject = Undefined Then
				InfobaseUpdate.MarkProcessingCompletion(PartnerContactPerson.Ref);
				ObjectsProcessed = ObjectsProcessed + 1;
				CommitTransaction();
				Continue;
			EndIf;

			Transformed = ContactsManager.UpdateObjectContactInformation(CatalogObject);
			If Not Transformed Then
				InfobaseUpdate.MarkProcessingCompletion(PartnerContactPerson.Ref);
				ObjectsProcessed = ObjectsProcessed + 1;
				CommitTransaction();
				Continue;
			EndIf;

			InfobaseUpdate.WriteData(CatalogObject);
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
		Except
			RollbackTransaction();
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			InfobaseUpdate.WriteErrorToEventLog(
				PartnerContactPerson.Ref,
				RepresentationOfTheReference,
				ErrorInfo());
		EndTry;
	
	EndDo;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
		"Catalog._DemoPartnersContactPersons");

	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось обработать некоторые элементы справочника Контактные лица партнеров (пропущены): %1';
				|en = 'Couldn''t process (skipped) some items of the ""Partner contacts"" catalog: %1';"),
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Information, Metadata.Catalogs._DemoPartnersContactPersons,,
			StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Обработана очередная порция контактных лиц партнеров: %1';
						|en = 'Yet another batch of partner contacts is processed: %1';"), 
					ObjectsProcessed));
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#EndIf