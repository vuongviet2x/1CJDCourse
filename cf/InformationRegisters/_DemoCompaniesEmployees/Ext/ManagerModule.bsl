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

// Called from "CommonOverridable.AfterReplaceRefs", See Common.ReplaceReferences.
//
// Parameters:
//  Result - Structure:
//    * HasErrors - Boolean
//    * QueueForDirectDeletion - Array of AnyRef
//    * Errors - ValueTable:
//      ** Ref - AnyRef
//      ** ErrorObject - Arbitrary
//      ** ErrorObjectPresentation - String
//      ** ErrorType - String
//      ** ErrorText - String
//  ExecutionParameters	 - See Common.RefsReplacementParameters
//  SearchTable		 - ValueTable
//
Procedure ReplaceReferences(Result, Val ExecutionParameters, Val SearchTable) Export
	
	ColumnsType = New TypeDescription("CatalogRef._DemoIndividuals");
	IndividualsReplacementTable = New ValueTable;
	IndividualsReplacementTable.Columns.Add("Original", ColumnsType);
	IndividualsReplacementTable.Columns.Add("Duplicate1", ColumnsType);
	
	ColumnsType = New TypeDescription("CatalogRef._DemoCompanies");
	CompaniesReplacementTable = New ValueTable;
	CompaniesReplacementTable.Columns.Add("Original", ColumnsType);
	CompaniesReplacementTable.Columns.Add("Duplicate1", ColumnsType);
	
	For Each DuplicateOriginal In ExecutionParameters.SuccessfulReplacements Do
		
		If TypeOf(DuplicateOriginal.Value) = Type("CatalogRef._DemoCompanies") Then
			
			ReplacementPair = CompaniesReplacementTable.Add();	
			ReplacementPair.Original = DuplicateOriginal.Value;		
			ReplacementPair.Duplicate1 = DuplicateOriginal.Key;		
			
		ElsIf TypeOf(DuplicateOriginal.Value) = Type("CatalogRef._DemoIndividuals") Then	
			
			ReplacementPair = IndividualsReplacementTable.Add();	
			ReplacementPair.Original = DuplicateOriginal.Value;		
			ReplacementPair.Duplicate1 = DuplicateOriginal.Key;		

		EndIf;
		
	EndDo;
	
	Query = New Query;
	Query.SetParameter("ReplacementTableIndividuals", IndividualsReplacementTable); 
	Query.SetParameter("CompaniesReplacementTable", CompaniesReplacementTable); 
	SetPrivilegedMode(True);
	Query.Text = DuplicateRecordsSearchQueryText();
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		
		BeginTransaction();
		Try
			DeletionRequired1 = SelectionDetailRecords.SameRecordsCountAfterReplacement = 2;
			If DeletionRequired1 Then
				
				Set = InformationRegisters._DemoCompaniesEmployees.CreateRecordSet();
				Set.Filter.Period.Set(SelectionDetailRecords.Period);
				Set.Filter.Organization.Set(ValueIncludingReplacement(SelectionDetailRecords.Organization, CompaniesReplacementTable));
				Set.Filter.Individual.Set(ValueIncludingReplacement(SelectionDetailRecords.Individual, IndividualsReplacementTable));
				Set.Read();
				Set.Clear();
				Set.Write();
				
			Else	
				
				Block = New DataLock;
				LockItem = Block.Add("InformationRegister._DemoCompaniesEmployees");
				LockItem.SetValue("Period", SelectionDetailRecords.Period);
				LockItem.SetValue("Organization", SelectionDetailRecords.Organization);
				LockItem.SetValue("Individual", SelectionDetailRecords.Individual);
				Block.Lock();
				
				SetBeforeReplacement = InformationRegisters._DemoCompaniesEmployees.CreateRecordSet();
				SetBeforeReplacement.Filter.Period.Set(SelectionDetailRecords.Period);
				SetBeforeReplacement.Filter.Organization.Set(SelectionDetailRecords.Organization);
				SetBeforeReplacement.Filter.Individual.Set(SelectionDetailRecords.Individual);
				SetBeforeReplacement.Read();
				
				SetAfterReplacement = InformationRegisters._DemoCompaniesEmployees.CreateRecordSet();
				SetAfterReplacement.Filter.Period.Set(SelectionDetailRecords.Period);
				SetAfterReplacement.Filter.Organization.Set(ValueIncludingReplacement(SelectionDetailRecords.Organization, CompaniesReplacementTable));
				SetAfterReplacement.Filter.Individual.Set(ValueIncludingReplacement(SelectionDetailRecords.Individual, IndividualsReplacementTable));
				
				For Each RecordBeforeReplacement In SetBeforeReplacement Do
					
					RecordAfterReplacement = SetAfterReplacement.Add();
					FillPropertyValues(RecordAfterReplacement, RecordBeforeReplacement);
					RecordAfterReplacement.Individual = ValueIncludingReplacement(SelectionDetailRecords.Individual, IndividualsReplacementTable);
					RecordAfterReplacement.Organization = ValueIncludingReplacement(SelectionDetailRecords.Organization, CompaniesReplacementTable);
					
				EndDo;
				
				SetBeforeReplacement.Clear();
				SetBeforeReplacement.Write();
				SetAfterReplacement.Write();
				
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
		EndTry;
		
	EndDo;

EndProcedure

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Individual)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

Function ValueIncludingReplacement(Value, SuccessfulReplacements)

	Var Result;
	 
	ReplacementPair = SuccessfulReplacements.Find(Value, "Duplicate1");
	If ReplacementPair = Undefined Then
		Result = Value;
	Else
		Result = ReplacementPair.Original;
	EndIf;
	
	Return Result;

EndFunction

Function DuplicateRecordsSearchQueryText()
	
	Return "SELECT
	        |	ReplacementTable.Original AS Original,
	        |	ReplacementTable.Duplicate1 AS Duplicate1
	        |INTO ReplacementTableIndividuals
	        |FROM
	        |	&ReplacementTableIndividuals AS ReplacementTable
	        |;
	        |
	        |////////////////////////////////////////////////////////////////////////////////
	        |SELECT
	        |	ReplacementTable.Duplicate1 AS Duplicate1,
	        |	ReplacementTable.Original AS Original
	        |INTO CompaniesReplacementTable
	        |FROM
	        |	&CompaniesReplacementTable AS ReplacementTable
	        |;
	        |
	        |////////////////////////////////////////////////////////////////////////////////
	        |SELECT
	        |	Tab.Period AS Period,
	        |	Tab.Organization AS Organization,
	        |	Tab.Individual AS Individual,
	        |	COUNT(DISTINCT Tab.EntryType) AS SameRecordsCountAfterReplacement
	        |FROM
	        |	(SELECT
	        |		_DemoCompaniesEmployees.Period AS Period,
	        |		_DemoCompaniesEmployees.Organization AS Organization,
	        |		_DemoCompaniesEmployees.Individual AS Individual,
	        |		_DemoCompaniesEmployees.Department_Company AS Department_Company,
	        |		_DemoCompaniesEmployees.OccupiedRates AS OccupiedRates,
	        |		_DemoCompaniesEmployees.EmployeeCode AS EmployeeCode,
	        |		""Original"" AS EntryType
	        |	FROM
	        |		InformationRegister._DemoCompaniesEmployees AS _DemoCompaniesEmployees
	        |	WHERE
	        |		(_DemoCompaniesEmployees.Individual IN
	        |					(SELECT
	        |						ReplacementTable.Original AS Original
	        |					FROM
	        |						ReplacementTableIndividuals AS ReplacementTable)
	        |				OR _DemoCompaniesEmployees.Organization IN
	        |					(SELECT
	        |						ReplacementTable.Original AS Original
	        |					FROM
	        |						CompaniesReplacementTable AS ReplacementTable))
	        |	
	        |	UNION ALL
	        |	
	        |	SELECT
	        |		_DemoCompaniesEmployees.Period,
	        |		CASE
	        |			WHEN CompaniesReplacementTable.Original IS NULL
	        |				THEN _DemoCompaniesEmployees.Organization
	        |			ELSE CompaniesReplacementTable.Duplicate1
	        |		END,
	        |		CASE
	        |			WHEN IndividualsReplacementTable.Original IS NULL
	        |				THEN _DemoCompaniesEmployees.Individual
	        |			ELSE IndividualsReplacementTable.Duplicate1
	        |		END,
	        |		_DemoCompaniesEmployees.Department_Company,
	        |		_DemoCompaniesEmployees.OccupiedRates,
	        |		_DemoCompaniesEmployees.EmployeeCode,
	        |		""Duplicate1""
	        |	FROM
	        |		InformationRegister._DemoCompaniesEmployees AS _DemoCompaniesEmployees
	        |			LEFT JOIN ReplacementTableIndividuals AS IndividualsReplacementTable
	        |			ON _DemoCompaniesEmployees.Individual = IndividualsReplacementTable.Duplicate1
	        |			LEFT JOIN CompaniesReplacementTable AS CompaniesReplacementTable
	        |			ON _DemoCompaniesEmployees.Organization = CompaniesReplacementTable.Duplicate1
	        |	WHERE
	        |		(NOT IndividualsReplacementTable.Original IS NULL
	        |				OR NOT CompaniesReplacementTable.Original IS NULL)) AS Tab
	        |
	        |GROUP BY
	        |	Tab.Period,
	        |	Tab.Organization,
	        |	Tab.Individual";

EndFunction

#EndRegion

#EndIf
