///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns version cache data by the passed id.
//
// Parameters:
//   Id - String - cache record ID.
//
// Returns:
//   FixedStructure, Undefined
//
Function DataOfCache(Val Id) Export
	
	Result = Undefined;
		
	Query = New Query;
	Query.Text =
		"SELECT
		|	CacheTable.UpdateDate AS UpdateDate,
		|	CacheTable.Version AS Version,
		|	CacheTable.VersionDate AS VersionDate,
		|	CacheTable.VersionDetails AS VersionDetails,
		|	CacheTable.Id AS Id,
		|	CacheTable.Description AS Description
		|FROM
		|	InformationRegister.AddInsDataCache AS CacheTable
		|WHERE
		|	CacheTable.Id = &Id";
	
	Query.SetParameter("Id", Id);
	
	BeginTransaction();
	Try
		// Managed lock is not set, so other sessions can change the value while this transaction is active.
		SetPrivilegedMode(True);
		QueryResult = Query.Execute();
		SetPrivilegedMode(False);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If QueryResult.IsEmpty() Then
		Return Result;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	If IsCacheUpToDate(Selection.UpdateDate) Then
		Result = New Structure(
			"Id,
			|Description,
			|UpdateDate,
			|Version,
			|VersionDate,
			|VersionDetails");
		FillPropertyValues(Result, Selection);
		Result = New FixedStructure(Result);
	EndIf;
	
	Return Result;
	
EndFunction

// Updates data in the add-in cache.
//
// Parameters:
//  ID - ValueTableRow - Data to be written to the cache.
//
Procedure UpdateCacheData(AddInDetails) Export
	
	SetPrivilegedMode(True);
	
	Id = AddInDetails.Id;
	Var_Key = CreateRecordKey(New Structure("Id", Id));
	
	Try
		LockDataForEdit(Var_Key);
	Except
		// The data is being updated from another session.
		Return;
	EndTry;
	
	Try
		
		Set = CreateRecordSet();
		Set.Filter.Id.Set(Id);
		
		Record = Set.Add();
		FillPropertyValues(
			Record,
			AddInDetails);
		Record.UpdateDate = CurrentUniversalDate();
		
		Set.Write();
		
		UnlockDataForEdit(Var_Key);
		
	Except
		
		UnlockDataForEdit(Var_Key);
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion

#Region Private

Function IsCacheUpToDate(UpdateDate)
	
	If ValueIsFilled(UpdateDate) Then
		Return UpdateDate + 24 * 60 * 60 > CurrentUniversalDate(); // Cache for no more than 24 hours
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#EndIf