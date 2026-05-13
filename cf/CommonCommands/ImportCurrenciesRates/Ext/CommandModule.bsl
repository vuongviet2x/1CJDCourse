///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	NotifyDescription = New NotifyDescription("ImportCurrencyRatesClient", ThisObject);
	ShowQueryBox(NotifyDescription, 
		NStr("ru = 'Будет произведена загрузка файла с полной информацией по курсами всех валют за все время из менеджера сервиса.
              |Курсы валют, помеченных в областях данных для загрузки из сети Интернет, будут заменены в фоновом задании. Продолжить?';
				|en = 'You are about to import a file with full exchange rates data for all the periods from the service manager.
				|The exchange rates that are marked to be imported from the Internet in specific data areas will be replaced in a background job. Do you want to continue?';"), 
		QuestionDialogMode.YesNo);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ImportCurrencyRatesClient(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ImportCurrencyRates();
	
	ShowUserNotification(
		NStr("ru = 'Загрузка запланирована.';
			|en = 'The import is scheduled.';"), ,
		NStr("ru = 'Курсы будут загружены в фоновом режиме через непродолжительное время.';
			|en = 'The exchange rates will soon be imported in background mode.';"),
		PictureLib.DialogInformation);
	
EndProcedure

&AtServer
Procedure ImportCurrencyRates()
	
	CurrencyRateOperationsInternal.ImportCurrencyRates();
	
EndProcedure

#EndRegion
