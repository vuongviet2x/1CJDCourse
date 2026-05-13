///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// Generates a print form of the configuration profile and opens it in the PrintDocuments form.
//
// Parameters:
//  PrintParameters - See PrintManagementClient.DescriptionOfPrintParameters
//
// Returns:
//  Undefined - it is not required to return a result.
//
&AtClient
Function PrintCompanyProfile(PrintParameters) Export
	
	ObjectsAreas = New ValueList;
	SpreadsheetDocument = GenerateCompanyProfile(PrintParameters.PrintObjects, ObjectsAreas);
	
	PrintFormID = "CompanyProfile";
	
	PrintFormsCollection = PrintManagementClient.NewPrintFormsCollection(PrintFormID);
	PrintForm = PrintManagementClient.PrintFormDetails(PrintFormsCollection, PrintFormID);
	PrintForm.TemplateSynonym = NStr("ru = 'Карточка организации';
										|en = 'Company card';");
	PrintForm.SpreadsheetDocument = SpreadsheetDocument;
	PrintForm.PrintFormFileName = NStr("ru = 'Карточка организации';
												|en = 'Company card';");
	
	AdditionalParameters = PrintManagementClient.PrintParameters();
	AdditionalParameters.FormCaption = NStr("ru = 'Карточка организации';
													|en = 'Company card';");
	AdditionalParameters.FormOwner = PrintParameters.Form;
	
	PrintManagementClient.PrintDocuments(PrintFormsCollection, ObjectsAreas, AdditionalParameters);
	
	Return Undefined;
EndFunction

#EndRegion

#Region Private

&AtServerNoContext
Function GenerateCompanyProfile(CompaniesList, ObjectsAreas)
	Return DataProcessors._DemoPrintCompanyProfile.GenerateCompanyProfile(CompaniesList, ObjectsAreas);
EndFunction

#EndRegion
