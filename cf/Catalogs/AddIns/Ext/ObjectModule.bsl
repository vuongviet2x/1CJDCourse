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

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Attribute connection with deletion mark.
	If DeletionMark Then
		Use = Enums.AddInUsageOptions.isDisabled;
	EndIf;
	
	// Attribute connection with usage option.
	If Use = Enums.AddInUsageOptions.isDisabled Then
		UpdateFrom1CITSPortal = False;
	EndIf;
	
	// Each add-in must have its own ID with the UpdateFrom1CITSPortal flag set.
	If Not ThisIsTheLatestVersionComponent() Then
		UpdateFrom1CITSPortal = False;
	EndIf;
	
	// Uniqueness control of the add-in ID and version.
	If Not ThisIsTheUniqueComponent() Then 
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Компонента с таким идентификатором ""%1"" и датой ""%2"" уже существует в приложении.';
				|en = 'The add-in with ID ""%1"" and date ""%2"" is already attached to the app.';"),
			Id,
			VersionDate);
	EndIf;
	
	// Storing binary add-in data.
	ComponentBinaryData = Undefined;
	If AdditionalProperties.Property("ComponentBinaryData", ComponentBinaryData) Then
		AddInStorage = New ValueStorage(ComponentBinaryData);
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// If a newer version add-in is being attached, and an old version has the flag "UpdateFrom1CITSPortal" set,
	// clear the add-in flag when overwriting the old versions.
	If ThisIsTheLatestVersionComponent() Then
		RewriteComponentsOfEarlierVersions();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function ThisIsTheLatestVersionComponent() Export
	
	Query = New Query;
	Query.SetParameter("Id", Id);
	Query.SetParameter("Ref", Ref);
	Query.Text = 
		"SELECT
		|	MAX(AddIns.VersionDate) AS VersionDate
		|FROM
		|	Catalog.AddIns AS AddIns
		|WHERE
		|	AddIns.Id = &Id
		|	AND AddIns.Ref <> &Ref
		|	AND NOT AddIns.DeletionMark";
	
	Result = Query.Execute();
	Selection = Result.Select();
	Selection.Next();
	Return (Selection.VersionDate = Null) Or (Selection.VersionDate <= VersionDate)
	
EndFunction

Function ThisIsTheUniqueComponent()
	
	Query = New Query;
	Query.SetParameter("Id", Id);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("VersionDate", VersionDate);
	Query.Text = 
		"SELECT TOP 1
		|	1 AS Field1
		|FROM
		|	Catalog.AddIns AS AddIns
		|WHERE
		|	AddIns.Id = &Id
		|	AND AddIns.Use = VALUE(Enum.AddInUsageOptions.Used)
		|	AND AddIns.Ref <> &Ref
		|	AND AddIns.VersionDate = &VersionDate";
	
	Result = Query.Execute();
	Return Result.IsEmpty();
	
EndFunction

Procedure RewriteComponentsOfEarlierVersions()
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.AddIns");
	LockItem.SetValue("Id", Id);
	Block.Lock();
	
	Query = New Query;
	Query.SetParameter("Id", Id);
	Query.SetParameter("VersionDate", VersionDate);
	Query.Text = 
		"SELECT
		|	AddIns.Ref AS Ref
		|FROM
		|	Catalog.AddIns AS AddIns
		|WHERE
		|	AddIns.Id = &Id
		|	AND AddIns.Use = VALUE(Enum.AddInUsageOptions.Used)
		|	AND AddIns.VersionDate < &VersionDate";
	
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do 
		Object = Selection.Ref.GetObject();
		Object.Lock();
		Object.Write();
	EndDo;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf