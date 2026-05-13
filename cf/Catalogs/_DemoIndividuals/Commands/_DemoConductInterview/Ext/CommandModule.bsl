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
	
	If Not UsageAllowed() Then
		WarningText = NStr("ru = 'Форма недоступна, не включена подсистема ""Анкетирование"".';
									|en = 'Form is unavailable. The Surveys subsystem is disabled.';");
		ShowMessageBox(, WarningText);
		Return;
	EndIf; 
	
	SurveysClient.StartInterview(CommandParameter);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function UsageAllowed()
	
	Return GetFunctionalOption("UseSurvey");
	
EndFunction

#EndRegion
