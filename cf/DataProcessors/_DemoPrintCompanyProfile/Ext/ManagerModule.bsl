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

// Populates a list of print commands.
//
// Parameters:
//  PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PrintCompanyProfile";
	PrintCommand.Presentation = NStr("ru = 'Карточка организации';
										|en = 'Company card';");
	PrintCommand.Handler = "PrintCompanyProfile";
EndProcedure

// End StandardSubsystems.Print

// StandardSubsystems.AttachableCommands

// Parameters:
//  InterfaceSettings4 - Structure:
//   * AddPrintCommands - Boolean
//   * Location - Array
//
Procedure OnDefineSettings(InterfaceSettings4) Export
	InterfaceSettings4.AddPrintCommands = True;
	InterfaceSettings4.Location.Add(Metadata.Catalogs._DemoCompanies);
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#Region Private

// Generates a print form of a company profile.
Function GenerateCompanyProfile(CompaniesList, ObjectsAreas) Export
	
	CompaniesInfo = CompaniesInfo(CompaniesList);
	SpreadsheetDocument = New SpreadsheetDocument;
	Template = PrintManagement.PrintFormTemplate("DataProcessor._DemoPrintCompanyProfile.PF_MXL_CompanyProfile");
	For Each Organization In CompaniesInfo Do
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		ArrayOfLayoutAreas = New Array;
		ArrayOfLayoutAreas.Add("BasicInformation");
		If Organization.ContactInformation.Count() > 0 Then
			ArrayOfLayoutAreas.Add("ContactInformationTitle");
			ArrayOfLayoutAreas.Add("ContactInformationString");
		EndIf;
		If Organization.ResponsiblePersons.Count() > 0 Then
			ArrayOfLayoutAreas.Add("PersonsResponsibleHeader");
			ArrayOfLayoutAreas.Add("PersonsResponsibleRow");
		EndIf;
		
		For Each AreaName In ArrayOfLayoutAreas Do
			TemplateArea = Template.GetArea(AreaName);
			If StrEndsWith(AreaName, "String") Then
				InfoSource = New Array;
				If StrFind(AreaName, "ResponsiblePersons") = 1 Then
					InfoSource = Organization.ResponsiblePersons;
				ElsIf StrFind(AreaName, "ContactInformation") = 1 Then
					InfoSource = Organization.ContactInformation;
				EndIf;
				
				For Each InformationRecords In InfoSource Do
					TemplateArea.Parameters.Fill(InformationRecords);
					SpreadsheetDocument.Put(TemplateArea);
				EndDo;
			Else
				FillPropertyValues(TemplateArea.Parameters, Organization.BasicInformation);
				SpreadsheetDocument.Put(TemplateArea);
			EndIf;
		EndDo;
	
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, ObjectsAreas, Organization.Ref);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

// Gets company info.
//
// Parameters:
//  CompaniesList - Array
// Returns:
//  Array of Structure: 
//   * Ref - CatalogRef._DemoCompanies
//   * BasicInformation - See CompaniesServer.CompanyInfo.
//   * ContactInformation - ValueTable
//   * ResponsiblePersons - ValueTable
//
Function CompaniesInfo(CompaniesList)
	
	Result = New Array;
	CompanyProperties = "Description,Code,OfficerFullNameInfo";
	
	ContactInformation = ContactsManager.ObjectsContactInformation(CompaniesList, , , CurrentSessionDate());
	ContactInformation.Sort("Type, Kind, Presentation");
	
	ContactInformation.Columns.Kind.Name           = "ContactInformationKind";
	ContactInformation.Columns.Presentation.Name = "ContactInformationPresentation";
	
	For Each Organization In CompaniesList Do
		
		Date = CurrentSessionDate();
		BasicInformation = New Structure;
		BasicInformation.Insert("CreationDate2", Date);
		
		OrganizationDescription = Common.ObjectAttributesValues(Organization, "Code, Presentation");
		
		CompanyContactInformation1 = ContactInformation.FindRows(New Structure("Object", Organization));
		
		ResponsiblePersons = New ValueTable;
		ResponsiblePersons.Columns.Add("LASTFIRSTNAME");
		If BasicInformation.Property("OfficerFullNameInfo") Then
			NS = ResponsiblePersons.Add();
			NS.LASTFIRSTNAME = BasicInformation.OfficerFullNameInfo;
		EndIf;
		
		OrganizationDescription = New Structure;
		OrganizationDescription.Insert("Ref",               Organization);
		OrganizationDescription.Insert("BasicInformation",     BasicInformation);
		OrganizationDescription.Insert("ContactInformation", ContactInformation.Copy(CompanyContactInformation1));
		OrganizationDescription.Insert("ResponsiblePersons",    ResponsiblePersons);
		
		Result.Add(OrganizationDescription);
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf