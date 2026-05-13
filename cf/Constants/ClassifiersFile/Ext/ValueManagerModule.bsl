///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2019, OOO 1C-Soft
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
		Raise NStr("ru = 'Настройка загрузки классификаторов из файла не доступна при работе в модели сервиса.
			|Загрузка обновлений выполняется подсистемой ""Поставляемые данные"".';
			|en = 'Cannot import classifiers from files in SaaS.
			|Classifiers are updated automatically by the Default master data subsystem.';");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf