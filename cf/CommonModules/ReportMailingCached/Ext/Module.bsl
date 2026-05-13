///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Private

// Recipients types table broken down by storage and user presentation of these types.
//
// Returns: 
//   ValueTable - Table of recipient types.:
//       * MetadataObjectID - CatalogRef.MetadataObjectIDs - a reference that is stored
//                                                                                              in the database.
//       * RecipientsType  - TypeDescription - a type by which the recipient and exclusion list values are limited.
//       * Presentation   - String - a type presentation for users.
//       * MainCIKind   - CatalogRef.ContactInformationKinds - contact information kind: email, by
//                                                                       default.
//       * CIGroup        - CatalogRef.ContactInformationKinds - contact information kind group.
//       * ChoiceFormPath - String - a path to the choice form.
//
Function RecipientsTypesTable() Export
	
	TypesTable = New ValueTable;
	TypesTable.Columns.Add("MetadataObjectID", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	TypesTable.Columns.Add("RecipientsType", New TypeDescription("TypeDescription"));
	TypesTable.Columns.Add("Presentation", New TypeDescription("String"));
	TypesTable.Columns.Add("MainCIKind", New TypeDescription("CatalogRef.ContactInformationKinds"));
	TypesTable.Columns.Add("CIGroup", New TypeDescription("CatalogRef.ContactInformationKinds"));
	TypesTable.Columns.Add("ChoiceFormPath", New TypeDescription("String"));
	TypesTable.Columns.Add("MainType", New TypeDescription("TypeDescription"));
	
	TypesTable.Indexes.Add("MetadataObjectID");
	TypesTable.Indexes.Add("RecipientsType");
	
	AvailableTypes = Metadata.Catalogs.ReportMailings.TabularSections.Recipients.Attributes.Recipient.Type.Types();
	
	// The Users catalog parameters + User groups.
	TypesSettings = New Structure;
	TypesSettings.Insert("MainType",       Type("CatalogRef.Users"));
	TypesSettings.Insert("AdditionalType", Type("CatalogRef.UserGroups"));
	ReportMailing.AddItemToRecipientsTypesTable(TypesTable, AvailableTypes, TypesSettings);
	
	// Extension mechanism.
	ReportMailingOverridable.OverrideRecipientsTypesTable(TypesTable, AvailableTypes);
	
	// Other catalogs parameters.
	BlankArray = New Array;
	For Each UnusedType In AvailableTypes Do
		ReportMailing.AddItemToRecipientsTypesTable(TypesTable, BlankArray, New Structure("MainType", UnusedType));
	EndDo;
	
	Return TypesTable;
EndFunction

// Reports to be excluded are used as a filter when selecting reports.
Function ReportsToExclude() Export
	
	MetadataArray = New Array;
	
	SSLSubsystemsIntegration.WhenDefiningExcludedReports(MetadataArray);
	ReportMailingOverridable.DetermineReportsToExclude(MetadataArray);
	
	Result = New Array;
	For Each ReportMetadata In MetadataArray Do
		Result.Add(Common.MetadataObjectID(ReportMetadata));
	EndDo;
	
	ReportsToExclude = New FixedArray(Result);
	
	Return ReportsToExclude;
	
EndFunction

Function FilesAndEmailTextParameters() Export

	ReportDistributionParameters = New Structure;
	
	ReportDistributionParameters.Insert("Recipient", NStr("ru = 'Получатель';
													|en = 'Recipient';"));
	ReportDistributionParameters.Insert("ExecutionDate", NStr("ru = 'Дата выполнения';
														|en = 'Fulfillment date';"));
	ReportDistributionParameters.Insert("Author", NStr("ru = 'Автор';
											|en = 'Author';"));
	ReportDistributionParameters.Insert("MailingDescription", NStr("ru = 'Наименование рассылки';
															|en = 'Distribution description';"));
	ReportDistributionParameters.Insert("GeneratedReports", NStr("ru = 'Сформированные отчеты';
															|en = 'Generated reports';"));
	ReportDistributionParameters.Insert("SystemTitle", NStr("ru = 'Заголовок системы';
														|en = 'Application title';"));
	ReportDistributionParameters.Insert("DeliveryMethod", NStr("ru = 'Способ доставки';
														|en = 'Delivery method';"));
	ReportDistributionParameters.Insert("ReportFormat", NStr("ru = 'Формат отчета';
													|en = 'Report format';"));
	ReportDistributionParameters.Insert("Period", NStr("ru = 'Период';
												|en = 'Period';"));
	ReportDistributionParameters.Insert("MailingDate", NStr("ru = 'Дата рассылки';
													|en = 'Send date';"));
	ReportDistributionParameters.Insert("ReportDescription1", NStr("ru = 'Наименование отчета';
															|en = 'Report name';"));
	
	Return ReportDistributionParameters;

EndFunction

#EndRegion
