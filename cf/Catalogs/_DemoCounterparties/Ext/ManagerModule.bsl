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

// StandardSubsystems.MessagesTemplates

// Called when preparing message templates. Overrides the list of attributes and attachments.
//
// Parameters:
//  Attributes               - ValueTable - List of template attributes.:
//         * Name            - String - Unique name of a common attribute.
//         * Presentation  - String - Common attribute presentation.
//         * Type            - Type    - Attribute type. By default, String.
//         * Format         - String - Output format of numbers, dates, strings, and boolean values.
//  Attachments                - ValueTable - Print forms and attachments:
//         * Name            - String - Unique attachment name.
//         * Presentation  - String - Variant presentation.
//         * FileType       - String - Attachment type, which matches the file extension: pdf, png, jpg, mxl, and so on.
//                                      
//  AdditionalParameters - Structure - Additional information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
	// Determine the counterparty state attribute.
	NewAttribute = Attributes.Add();
	NewAttribute.Name = "CounterpartyState";
	NewAttribute.Presentation = NStr("ru = 'Состояние контрагента';
										|en = 'Counterparty state';");
	NewAttribute.Type = New TypeDescription("String");

	MessageTemplates.ExpandAttribute("Partner", Attributes, "", "AccessGroup");

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

// StandardSubsystems.BatchEditObjects

// Returns the object attributes that are not recommended to be edited
// using a bulk attribute modification data processor.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export

	Result = New Array;

	Result.Add("TIN");
	Result.Add("NCBOCode");
	Result.Add("CRTR");

	Result.Add("ContactInformation.*");

	Return Result;

EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.ReportsOptions

// Defines the list of report commands.
//
// Parameters:
//  ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//  Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export

EndProcedure

// End StandardSubsystems.ReportsOptions

// StandardSubsystems.Print

// Override object's print settings.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export

EndProcedure

// End StandardSubsystems.Print

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the ObjectsVersioning subsystem.
//
// Parameters:
//  Settings - Structure - Subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export
	Settings.OnGetInternalAttributes = True;
EndProcedure

// Restricts object attribute visibility in the version report.
//
// Parameters:
//  Attributes - Array of String
//
Procedure OnGetInternalAttributes(Attributes) Export
	Attributes.Add("IsForeignCounterparty");
EndProcedure

// End StandardSubsystems.ObjectsVersioning

// StandardSubsystems.AttachableCommands

// Defines the list of population commands.
//
// Parameters:
//   FillingCommands - See ObjectsFillingOverridable.BeforeAddFillCommands.FillingCommands.
//   Parameters - See ObjectsFillingOverridable.BeforeAddFillCommands.Parameters
//
Procedure AddFillCommands(FillingCommands, Parameters) Export

EndProcedure

// End StandardSubsystems.AttachableCommands

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	IsFolder
	|	OR ValueAllowed(Partner)";

	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS _DemoCounterparties
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = _DemoCounterparties.Partner
	|
	|LEFT JOIN Catalog._DemoPartnersContactPersons AS _DemoPartnersContactPersons
	|	ON _DemoPartnersContactPersons.Owner = _DemoCounterparties.Partner
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersContactPersons
	|	ON ExternalUsersContactPersons.AuthorizationObject = _DemoPartnersContactPersons.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	IsFolder
	|	OR ValueAllowed(ExternalUsersPartners.Ref)
	|	OR ValueAllowed(ExternalUsersContactPersons.Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf