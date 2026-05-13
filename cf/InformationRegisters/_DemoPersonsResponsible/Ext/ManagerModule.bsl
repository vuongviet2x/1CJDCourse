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

#Region Private

Function PersonsResponsibleAndCompanies(Filter = Undefined) Export
	
	QueryText =
	"SELECT
	|	_DemoPersonsResponsible.Organization AS Organization,
	|	_DemoPersonsResponsible.Individual AS EmployeeResponsible
	|FROM
	|	InformationRegister._DemoPersonsResponsible AS _DemoPersonsResponsible";
	
	Query = New Query;
	Query.Text = QueryText;
	ResponsiblePersons = Query.Execute().Unload();
	
	If TypeOf(Filter) = Type("Array") Then
		
		QueryText =
		"SELECT
		|	Companies.Ref AS Organization
		|FROM
		|	Catalog._DemoCompanies AS Companies
		|WHERE
		|	Companies.Ref IN (&Filter)
		|
		|ORDER BY
		|	Companies.Description";
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("Filter", Filter);
		
	Else
		
		QueryText =
		"SELECT
		|	Companies.Ref AS Organization
		|FROM
		|	Catalog._DemoCompanies AS Companies
		|WHERE
		|	NOT Companies.DeletionMark
		|
		|ORDER BY
		|	Companies.Description";
		
		Query = New Query;
		Query.Text = QueryText;
		
	EndIf;
	
	Result = Query.Execute().Unload();
	Result.Columns.Add("EmployeeResponsible");
	
	For Each TableRow In Result Do
		
		EmployeesResponsible = ResponsiblePersons.Find(TableRow.Organization, "Organization");
		
		If EmployeesResponsible <> Undefined Then
			
			FillPropertyValues(TableRow, EmployeesResponsible, "EmployeeResponsible");
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

#EndRegion

#EndIf