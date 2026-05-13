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
	// Can access the object if can access EmployeeResponsible and ALL individuals.
	
	TabRow = Table.Add();
	TabRow.AccessValue = EmployeeResponsible;
	
	For Each TableRow In Salary Do
		
		If Not ValueIsFilled(TableRow.Individual) Then
			Continue;
		EndIf;
		
		TabRow = Table.Add();
		TabRow.AccessValue = TableRow.Individual;
	EndDo;
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	If FillingData = Undefined Then // Create a new item.
		_DemoStandardSubsystems.OnEnterNewItemFillCompany(ThisObject);
		RegistrationPeriod = BegOfMonth(CurrentSessionDate());
	EndIf;
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	GenerateAccrualRegisteredRecords();
	
EndProcedure

#EndRegion

#Region Private

Procedure GenerateAccrualRegisteredRecords()
	
	RegisterRecords._DemoBaseEarnings.Write = True;
	
	For Each String In Salary Do
		Movement = RegisterRecords._DemoBaseEarnings.Add();
		
		Movement.RegistrationPeriod = RegistrationPeriod;
		
		Movement.BegOfActionPeriod = BegOfMonth(RegistrationPeriod);
		Movement.EndOfActionPeriod  = EndOfMonth(RegistrationPeriod);
		
		Movement.Individual = String.Individual;
		Movement.Organization    = Organization;
		
		Movement.CalculationType = ChartsOfCalculationTypes._DemoBaseEarnings.BaseSalaryByDays;
		Movement.Result  = String.Sum;
	EndDo;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf