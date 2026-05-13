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
//   Table - See AccessManagement.AccessValuesSetsTable
//
Procedure FillAccessValuesSets(Table) Export
	
	// The restriction logic:
	// "Read": Organization
	// "Update": Organization AND EmployeeResponsible (if specified).
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		// Read, Update.
		String = Table.Add();
		String.AccessValue = Organization;
	Else
		// Read: Set #1.
		String = Table.Add();
		String.SetNumber     = 1;
		String.Read          = True;
		String.AccessValue = Organization;
		
		// Insert, Update: Set #2.
		String = Table.Add();
		String.SetNumber     = 2;
		String.Update       = True;
		String.AccessValue = Organization;
		
		String = Table.Add();
		String.SetNumber     = 2;
		String.AccessValue = EmployeeResponsible;
	EndIf;
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf