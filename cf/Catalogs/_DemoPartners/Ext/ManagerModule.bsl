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

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	IsFolder
	|	OR ValueAllowed(Ref)";

	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS _DemoPartners
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = _DemoPartners.Ref
	|
	|LEFT JOIN Catalog._DemoPartnersContactPersons AS _DemoPartnersContactPersons
	|	ON _DemoPartnersContactPersons.Owner = _DemoPartners.Ref
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