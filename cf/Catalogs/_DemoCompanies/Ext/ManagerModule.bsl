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

////////////////////////////////////////////////////////////////////////////////
// Use multiple companies.

// Returns the default company.
// If the infobase contains only one company that is not marked for deletion and not predefined, returns the reference to the company.
// Otherwise, returns an empty reference.
//
// Returns:
//   DefinedType.Organization
//
Function DefaultCompany() Export

	Organization = EmptyRef();

	Query = New Query;
	Query.Text =
	"SELECT ALLOWED TOP 2
	|	Companies.Ref AS Organization
	|FROM
	|	Catalog._DemoCompanies AS Companies
	|WHERE
	|	NOT Companies.DeletionMark
	|	AND NOT Companies.Predefined";

	Selection = Query.Execute().Select();
	If Selection.Next() And Selection.Count() = 1 Then
		Organization = Selection.Organization;
	EndIf;

	Return Organization;

EndFunction

// Returns a number of Companies catalog items.
// Does not return items that are predefined and marked for deletion.
//
// Returns:
//   Number
//
Function NumberOfOrganizations() Export

	SetPrivilegedMode(True);

	Count = 0;

	Query = New Query;
	Query.Text =
	"SELECT
	|	COUNT(*) AS Count
	|FROM
	|	Catalog._DemoCompanies AS Companies
	|WHERE
	|	NOT Companies.Predefined
	|	AND NOT Companies.DeletionMark";

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Count = Selection.Count;
	EndIf;

	SetPrivilegedMode(False);

	Return Count;

EndFunction

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

	Result.Add("Prefix");
	Result.Add("ContactInformation.*");

	Return Result
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

// Prepares printable data.
// 
// Parameters:
//  DataSources - See PrintManagementOverridable.WhenPreparingPrintData.DataSources
//  ExternalDataSets - See PrintManagementOverridable.WhenPreparingPrintData.ExternalDataSets
//  LanguageCode - See PrintManagementOverridable.WhenPreparingPrintData.LanguageCode
//  AdditionalParameters - See PrintManagementOverridable.WhenPreparingPrintData.AdditionalParameters
// 
Procedure WhenPreparingPrintData(DataSources, ExternalDataSets, LanguageCode, AdditionalParameters) Export

	PrintData = PrintData(DataSources, LanguageCode, AdditionalParameters);
	ExternalDataSets.Insert("PrintData", PrintData);

EndProcedure

// End StandardSubsystems.Print

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

// StandardSubsystems.MessagesTemplates

// Called when preparing message templates. Overrides the list of attributes and attachments.
//
// Parameters:
//  Attributes - See MessageTemplatesOverridable.OnPrepareMessageTemplate.Attributes
//  Attachments  - See MessageTemplatesOverridable.OnPrepareMessageTemplate.Attachments
//  AdditionalParameters - Structure - Additional information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export

	If TypeOf(AdditionalParameters.TemplateOwner) = Type("CatalogRef._DemoDepartments") Then
		TypesArray = New Array;
		TypesArray.Add(Type("CatalogRef._DemoProjects"));
		AllowedTypes = New TypeDescription(TypesArray);
		LongDesc = New Structure("TypeDetails, Presentation", AllowedTypes, NStr("ru = 'Демо: Проект';
																						|en = 'Demo: Project';"));
		AdditionalParameters.Parameters.Insert("_DemoProjects", LongDesc);
	EndIf;

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

	If TypeOf(AdditionalParameters.TemplateOwner) = Type("CatalogRef._DemoDepartments") Then
		Project = Message.AdditionalParameters.ArbitraryParameters["_DemoProjects"];
		If Project <> Undefined Then
			AttributesValues = Common.ObjectAttributesValues(
				Message.AdditionalParameters.MessageParameters.Project, 
				Common.CopyRecursive(Project), True);
			For Each Attribute In AttributesValues Do
				Project[Attribute.Key] = Attribute.Value;
			EndDo;
		EndIf;

		If AdditionalParameters.MessageParameters.Property("ProjectRegulations") Then
			DataFiles = FilesOperations.FileData(AdditionalParameters.MessageParameters.ProjectRegulations,
				AdditionalParameters.MessageParameters.UUID);
			Message.Attachments.Insert(DataFiles.FileName, DataFiles.RefToBinaryFileData);
		EndIf;
	EndIf;

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

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Ref)";

	Restriction.TextForExternalUsers1 = Restriction.Text;

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

Function CompanySignaturesAndSeals(Organization) Export

	Result = New Structure;

	ReadCompanyAllowed = ValueIsFilled(Common.ObjectAttributeValue(Organization, "Ref",
		True));
	If Not ReadCompanyAllowed Then
		Return Result;
	EndIf;

	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);

	Attributes = New Array;
	Attributes.Add("CompanySeal");
	Attributes.Add("CEOSignature");
	Attributes.Add("ChiefAccountantSignature");

	SignaturesAndSeals = Common.ObjectAttributesValues(Organization, Attributes);
	PicturesFiles = New Array;
	For Each SignatureSeal In SignaturesAndSeals Do
		PicturesFile = SignatureSeal.Value;
		PicturesFiles.Add(PicturesFile);
	EndDo;
	PicturesBinaryData = FilesOperations.BinaryFilesData(PicturesFiles, False);
	For Each SignatureSeal In SignaturesAndSeals Do
		Id = SignatureSeal.Key;
		PicturesFile = SignatureSeal.Value;
		Picture = PictureFromFile(PicturesBinaryData, PicturesFile);
		Result.Insert(Id, Picture);
	EndDo;

	Return Result;

EndFunction

Function PictureFromFile(PicturesBinaryData, File)

	BinaryData = Undefined;

	If ValueIsFilled(File) Then
		BinaryData = PicturesBinaryData[File];
	EndIf;

	If BinaryData = Undefined Then
		Return New Picture;
	EndIf;

	Return New Picture(BinaryData, True);

EndFunction

Function PrintData(DataSources, LanguageCode, AdditionalParameters)

	PrintData = New ValueTable;
	PrintData.Columns.Add("Ref", New TypeDescription);
	PrintData.Columns.Add("AbbreviatedDescription", New TypeDescription("String"));
	PrintData.Columns.Add("DescriptionFull", New TypeDescription("String"));
	PrintData.Columns.Add("TIN", New TypeDescription("String"));
	PrintData.Columns.Add("CRTR", New TypeDescription("String"));
	PrintData.Columns.Add("CEO", New TypeDescription("CatalogRef._DemoIndividuals"));
	PrintData.Columns.Add("ChiefAccountant", New TypeDescription("CatalogRef._DemoIndividuals"));
	PrintData.Columns.Add("CompanySeal",
		New TypeDescription("CatalogRef._DemoCompaniesAttachedFiles"));
	PrintData.Columns.Add("CEOSignature",
		New TypeDescription("CatalogRef._DemoCompaniesAttachedFiles"));
	PrintData.Columns.Add("ChiefAccountantSignature",
		New TypeDescription("CatalogRef._DemoCompaniesAttachedFiles"));
	PrintData.Columns.Add("DSStamp", New TypeDescription);

	SourcesByTypes = New Map;
	SourcesByTypes[Type("CatalogRef._DemoCompanies")] = New Array;

	For Each Source In DataSources Do
		Type = TypeOf(Source);
		If SourcesByTypes[Type] = Undefined Then
			SourcesByTypes[Type] = New Array;
		EndIf;
		ItemByType = SourcesByTypes[Type]; // Array
		ItemByType.Add(Source);
	EndDo;

	AttributesValues = Common.ObjectsAttributesValues(SourcesByTypes[Type("CatalogRef._DemoCompanies")], 
		"CompanySeal, CEOSignature, ChiefAccountantSignature");

	Owners = New Array;
	Companies = New Array;
	For Each DataSourceDescription In AdditionalParameters.DataSourceDescriptions Do
		Owner = DataSourceDescription.Owner;
		If ValueIsFilled(Owner) And Common.IsReference(TypeOf(Owner)) And Common.IsDocument(
			Owner.Metadata()) Then
			Owners.Add(Owner);
		EndIf;
		
		If TypeOf(DataSourceDescription.Value) = Type("CatalogRef._DemoCompanies") Then
			Companies.Add(DataSourceDescription.Value);
		EndIf;
	EndDo;

	If ValueIsFilled(Owners) Then
		AdditionalParameters.SourceDataGroupedByDataSourceOwner = True;
		DataSources = Owners;
	EndIf;
	
	DatesDetails = Common.ObjectsAttributeValue(Owners, "Date");
	
	If Not Common.SubsystemExists("StandardSubsystems.Companies") Then
		Query = New Query;
		Query.SetParameter("Companies", Companies);
		Query.Text =
		"SELECT
		|	*
		|FROM
		|	Catalog._DemoCompanies
		|WHERE
		|	Catalog._DemoCompanies.Ref IN (&Companies)";
		CompanyTable = Query.Execute().Unload();
	EndIf;

	For Each DataSourceDescription In AdditionalParameters.DataSourceDescriptions Do
		DateOfLastEdit = DatesDetails[DataSourceDescription.Owner];
		If Not ValueIsFilled(DateOfLastEdit) Then
			DateOfLastEdit = CurrentSessionDate();
		EndIf;

		Object = DataSourceDescription.Value;
		If TypeOf(Object) <> Type("CatalogRef._DemoCompanies") Then
			Continue;
		EndIf;

		CompanyInformation = New Structure;
		If Common.SubsystemExists("StandardSubsystems.Companies") Then
			ModuleOrganizationServer = Common.CommonModule("CompaniesServer");
			CompanyInformation = ModuleOrganizationServer.CompanyInformation(Object,, DateOfLastEdit, LanguageCode);
		Else
			String = CompanyTable.Find(Object, "Ref");
			CompanyInformation = Common.ValueTableRowToStructure(String);
			CompanyInformation.Insert("NameForPrinting", String.DescriptionFull);
		EndIf;

		ThisOrganization = PrintData.Add();
		FillPropertyValues(ThisOrganization, CompanyInformation);
		FillPropertyValues(ThisOrganization, AttributesValues[Object]);
		ThisOrganization.DescriptionFull = CompanyInformation.NameForPrinting;

		If AdditionalParameters.SourceDataGroupedByDataSourceOwner Then
			ThisOrganization.Ref = DataSourceDescription.Owner;
		EndIf;
	EndDo;

	Return PrintData;

EndFunction

#EndRegion

#EndIf