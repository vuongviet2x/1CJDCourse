///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2018, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	Var Characteristic;
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	LongDesc = DataKind;
	For Each Characteristic In DataCharacteristics Do
		LongDesc = LongDesc 
			+ ", " + Characteristic.Characteristic + ": " + Characteristic.Value;
	EndDo;
		
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf