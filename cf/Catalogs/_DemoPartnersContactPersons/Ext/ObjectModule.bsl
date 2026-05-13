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
//

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	// If a value for filling the partner (owner) is not passed, try to set it. 
	// 
	FindPartner = FillingData = Undefined;
	If Not FindPartner And FillingData.Property("Owner") Then
		DataAnalysis = New Structure("Owner");
		FillPropertyValues(DataAnalysis, FillingData, "Owner");
		FindPartner = Not ValueIsFilled(DataAnalysis.Owner);
	EndIf;

	If FindPartner Then
		Query = New Query("
							  |SELECT ALLOWED TOP 2
							  |	Partners.Ref AS Ref
							  |FROM
							  |	Catalog._DemoPartners AS Partners
							  |WHERE
							  |	NOT Partners.DeletionMark
							  |");
		Partners = Query.Execute().Unload();
		// Proceed only if single partner is available.
		If Partners.Count() = 1 Then
			Partner = Partners[0]; // CatalogRef._DemoPartners
			Owner = Partner.Ref;
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Else
	Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
							|en = 'Invalid object call on the client.';");
#EndIf