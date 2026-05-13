///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Raise NStr("ru = 'Настройка варианта обновления внешних компонент недоступна при работе в модели сервиса.
			|Загрузка обновлений выполняется подсистемой ""Поставляемые данные"".';
			|en = 'Cannot set up add-in update in SaaS.
			|Add-ins are updated automatically by the Default master data subsystem.';");
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Regardless of the user rights, the constant value must match the scheduled job runtime mode.
	// 
	SetPrivilegedMode(True);
	GetAddIns.SetScheduledJobsUsage(Value <> 0);
	
EndProcedure

#EndRegion

#EndIf