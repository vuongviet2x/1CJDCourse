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

// StandardSubsystems.Print

// Override object's print settings.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export

	Settings.OnAddPrintCommands = True;

EndProcedure

// Populates a list of print commands.
// 
// Parameters:
//  PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	

EndProcedure

// End StandardSubsystems.Print

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the ObjectsVersioning subsystem.
//
// Parameters:
//  Settings - Structure - Subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

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

EndProcedure

// End StandardSubsystems.MessagesTemplates

#EndRegion

#EndRegion


#EndIf