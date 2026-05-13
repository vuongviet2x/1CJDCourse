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

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DataLock = New DataLock;
	For Each ChartOfCalculationTypes In Metadata.ChartsOfCalculationTypes Do 
		DataLock.Add(ChartOfCalculationTypes.FullName());
	EndDo;
	DataLock.Lock();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	_DemoBaseEarnings.Ref
	|FROM
	|	ChartOfCalculationTypes._DemoBaseEarnings AS _DemoBaseEarnings
	|WHERE
	|	_DemoBaseEarnings.BaseCalculationTypes.CalculationType = &Ref";
	Query.SetParameter("Ref", Ref);
	
	SubordinateTypesOfCalculation = Query.Execute().Unload().UnloadColumn("Ref");
	For Each SubordinateLink In SubordinateTypesOfCalculation Do
		SubordinateObject = SubordinateLink.GetObject();
		FoundItems = SubordinateObject.BaseCalculationTypes.FindRows(New Structure("CalculationType", Ref));
		For Each TableRow In FoundItems Do
			SubordinateObject.BaseCalculationTypes.Delete(TableRow);
		EndDo;
		SubordinateObject.Write();
	EndDo;
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	
	// StandardSubsystems.NationalLanguageSupport
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	// End StandardSubsystems.NationalLanguageSupport
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf