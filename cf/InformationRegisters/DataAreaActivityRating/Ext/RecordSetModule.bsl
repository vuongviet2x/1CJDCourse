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

// @skip-check data-exchange-load
Procedure OnWrite(Cancel, Replacing)
	
	// The value validator of the "DataExchange.Import" property is not implemented since the restrictions
	// imposed by this code block are not supposed to be overridden by setting the property to "True"
	// (by the piece of code that is trying to record an entry into the register).
	//
	// The register must be excluded from the scope of any data exchange if data area separation is enabled.
	// 
	
	If Not SaaSOperations.SessionWithoutSeparators() Then
		
		Raise NStr("ru = 'Нарушение прав доступа.';
								|en = 'Access violation.';");
		
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf