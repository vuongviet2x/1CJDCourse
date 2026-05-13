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

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowRead
	|WHERE
	|	ValueAllowed(Organization)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(EmployeeResponsible, EmptyRef AS TRUE)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

// Sets "Project" as the main project for the current user
// The main project is formatted as bold in project lists and displayed in the application title.
// 
// Parameters:
//  Project - CatalogRef._DemoProjects - Project to be set as main.
//
Procedure SetMainProject(Project) Export
	
	CommonClientServer.CheckParameter("Catalogs._DemoProjects.SetMainProject", "Project", 
		Project, Type("CatalogRef._DemoProjects"));
	Common.CommonSettingsStorageSave("_DemoProjects", "MainProject", Project);
	SessionParameters._DemoCurrentProject = Project;
	
EndProcedure	

// Returns the main project for the current user.
//
// Returns:
//   CatalogRef._DemoProjects - Main project. If the main project is not specified, returns an empty string.
//
Function MainProject() Export
	
	Return Common.CommonSettingsStorageLoad("_DemoProjects", "MainProject", EmptyRef());
	
EndFunction	

// Parameters:
//  ParameterName - String
//  SpecifiedParameters - Array of String
//
Procedure SessionParametersSetting(ParameterName, SpecifiedParameters) Export
	
	If ParameterName = "_DemoCurrentProject" Then
		SessionParameters._DemoCurrentProject = MainProject();
		SpecifiedParameters.Add("_DemoCurrentProject");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
