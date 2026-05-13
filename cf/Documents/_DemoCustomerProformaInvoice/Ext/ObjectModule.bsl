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

Procedure Filling(FillingData, FillingText, StandardProcessing)
	If FillingData = Undefined Then // Create a new item.
		_DemoStandardSubsystems.OnEnterNewItemFillCompany(ThisObject);
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
EndProcedure

Procedure Posting(Cancel, Mode)
	For Each CurProductRow In Goods Do
		Movement = RegisterRecords._DemoProformaInvoicesTurnovers.Add();
		Movement.Period = Date;
		Movement.Products = CurProductRow.Products;
		Movement.Sum = CurProductRow.Sum;
	EndDo;
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf