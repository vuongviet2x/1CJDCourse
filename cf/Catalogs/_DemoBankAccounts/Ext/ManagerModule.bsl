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

// Runs at subordinate object duplicate replacement. See Common.ReplaceReferences.
// Showcase of the search procedure overriding upon replacing references to catalog owners.
//
// Parameters:
//  ReplacementPairs - Map of KeyAndValue - Contains the original—duplicate value pairs:
//    * Key - AnyRef - Reference to the replaceable value.
//    * Value - AnyRef - Reference to the replacement value.
//  UnprocessedDuplicates - Array of Structure:
//    * ValueToReplace - AnyRef - The original value of a replaceable object.
//    * UsedLinks - ValueTable - Details of replacement pairs:
//    ** Key - String - Full name of the parent metadata object.
//    ** Metadata - MetadataObject - Parent metadata object.
//    ** AttributeType - Type - Replacing attribute type.
//    ** AttributeName - String - The replacing attribute, which originates a pair.
//    ** Used - Boolean - Flag indicating whether objects are added to replacement pairs.
//    * KeyAttributesValue - Structure - Key is the attribute name. Value is the attribute value. 
//
Procedure OnSearchForReferenceReplacement(ReplacementPairs, UnprocessedDuplicates) Export

	AccountsNumbers = New ValueTable;
	AccountsNumbers.Columns.Add("AccountNumber", Metadata.Catalogs._DemoBankAccounts.Attributes.AccountNumber.Type);
	AccountsNumbers.Columns.Add("Owner", Metadata.Catalogs._DemoBankAccounts.StandardAttributes.Owner.Type);

	For Each UnprocessedDuplicate In UnprocessedDuplicates Do

		KeyAttributesValue = UnprocessedDuplicate.KeyAttributesValue;
		If Not ValueIsFilled(KeyAttributesValue.AccountNumber) Then
			Continue;
		EndIf;

		If UnprocessedDuplicate.UsedLinks.Find("Owner", "AttributeName") = Undefined Then
			Continue;
		EndIf;

		MainObjectValueToReplace = ReplacementPairs[KeyAttributesValue.Owner];
		If Not ValueIsFilled(MainObjectValueToReplace) Then
			Continue;
		EndIf;
		
		AccountNumber = AccountsNumbers.Add();
		AccountNumber.Owner = MainObjectValueToReplace;
		AccountNumber.AccountNumber = KeyAttributesValue.AccountNumber;

	EndDo;

	Query = New Query(
		"SELECT
		|	TableAccountNumbers.AccountNumber AS AccountNumber,
		|	TableAccountNumbers.Owner AS Owner
		|INTO TableAccountNumbers
		|FROM
		|	&TableAccountNumbers AS TableAccountNumbers
		|INDEX BY
		|	Owner
		|;
		|
		|SELECT
		|	_DemoBankAccounts.Ref AS Ref
		|FROM
		|	Catalog._DemoBankAccounts AS _DemoBankAccounts
		|INNER JOIN TableAccountNumbers AS TableAccountNumbers
		|	ON _DemoBankAccounts.AccountNumber = TableAccountNumbers.AccountNumber
		|	AND _DemoBankAccounts.Owner = TableAccountNumbers.Owner");

	Query.SetParameter("TableAccountNumbers", AccountsNumbers);

	SelectionDetailRecords = Query.Execute().Select();
	If SelectionDetailRecords.Next() Then
		ReplacementPairs.Insert(UnprocessedDuplicate.ValueToReplace, SelectionDetailRecords.Ref);
	EndIf;

EndProcedure

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE
	|	ValueAllowed(CAST(Owner AS Catalog._DemoCompanies))
	|	AND ListReadingAllowed(CAST(Owner AS Catalog._DemoCompanies))
	|	OR
	|	ValueAllowed(CAST(Owner AS Catalog._DemoCounterparties).Partner)
	|	AND ListReadingAllowed(CAST(Owner AS Catalog._DemoCounterparties).Partner)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(CAST(Owner AS Catalog._DemoCompanies))
	|	AND ListUpdateAllowed(CAST(Owner AS Catalog._DemoCompanies))
	|	OR
	|	ValueAllowed(CAST(Owner AS Catalog._DemoCounterparties).Partner)
	|	AND ListUpdateAllowed(CAST(Owner AS Catalog._DemoCounterparties).Partner)";

	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS _DemoBankAccounts
	|
	|LEFT JOIN Catalog._DemoCounterparties AS _DemoCounterparties
	|	ON _DemoCounterparties.Ref = _DemoBankAccounts.Owner
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
	|AllowRead
	|WHERE
	|	ValueAllowed(Owner ONLY Catalog._DemoCompanies)
	|	AND ListReadingAllowed(Owner ONLY Catalog._DemoCompanies)
	|	OR
	|	ValueAllowed(ExternalUsersPartners.Ref)
	|	AND ListReadingAllowed(ExternalUsersPartners.AuthorizationObject)
	|	OR
	|	ValueAllowed(ExternalUsersContactPersons.Ref)
	|	AND ListReadingAllowed(ExternalUsersContactPersons.AuthorizationObject)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(Owner ONLY Catalog._DemoCompanies)
	|	AND ListUpdateAllowed(Owner ONLY Catalog._DemoCompanies)
	|	OR
	|	ValueAllowed(ExternalUsersPartners.Ref)
	|	AND ListUpdateAllowed(ExternalUsersPartners.AuthorizationObject)
	|	OR
	|	ValueAllowed(ExternalUsersContactPersons.Ref)
	|	AND ListUpdateAllowed(ExternalUsersContactPersons.AuthorizationObject)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf