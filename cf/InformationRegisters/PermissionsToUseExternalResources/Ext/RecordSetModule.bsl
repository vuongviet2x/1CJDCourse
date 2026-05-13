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

Procedure BeforeWrite(Cancel, Replacing)
	
	// No need to run "DataExchange.Load".
	// Safe mode restricts writing internal data.
	SafeModeManagerInternal.OnSaveInternalData(ThisObject);
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	For Each Record In ThisObject Do
		
		ProgramModule = SafeModeManagerInternal.ReferenceFormPermissionRegister(
			Record.ProgramModuleType, Record.ModuleID);
		Record.SoftwareModulePresentation = String(ProgramModule);
		
		Owner = SafeModeManagerInternal.ReferenceFormPermissionRegister(
			Record.OwnerType, Record.OwnerID);
		Record.OwnerPresentation = String(Owner);
		
	EndDo;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf