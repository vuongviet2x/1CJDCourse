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

	If CommandParameter = Undefined Then
		Return;
	EndIf;

	ClosingNotification1 = New NotifyDescription("MakeDefaultCompletion", ThisObject, CommandParameter);
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Отметить проект %1 как основной?
			|Основной проект подсвечивается жирным шрифтом и выводится в заголовке приложения.';
			|en = 'Mark the %1 project as main?
			| The main project is in bold font in projects list, and displayed in application title.';"),
		String(CommandParameter));
	ShowQueryBox(ClosingNotification1, QueryText, QuestionDialogMode.YesNo);

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure MakeDefaultCompletion(Result, Project) Export

	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;

	SetMainProject(Project);
	Notify("Write__DemoProject", New Structure, Project);
	RefreshReusableValues();
	StandardSubsystemsClient.SetAdvancedApplicationCaption();

EndProcedure

&AtServer
Procedure SetMainProject(Project)

	Catalogs._DemoProjects.SetMainProject(Project);

EndProcedure

#EndRegion