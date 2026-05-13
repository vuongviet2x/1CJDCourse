///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	QueryConsoleUsageOption = Parameters.QueryConsoleUsageOption;
	PathToExternalQueryConsole = Parameters.PathToExternalQueryConsole;
	
	Items.PathToExternalQueryConsole.Enabled = (QueryConsoleUsageOption = "Outer");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure QueryConsoleUsageOptionOnChange(Item)
	
	Items.PathToExternalQueryConsole.Enabled = (QueryConsoleUsageOption = "Outer");
	
EndProcedure

&AtClient
Procedure PathToExternalQueryConsoleStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	Dialog = New FileDialog(FileDialogMode.Open);
	Dialog.CheckFileExist = True;
	Dialog.Multiselect = False;
	Dialog.Filter = NStr("ru = 'Внешние обработки (*.epf)|*.epf';
						|en = 'External data processors (*.epf)|*.epf';");
	
	ChoiceNotification1 = New NotifyDescription("PathToExternalQueryConsoleSelectionCompletion", ThisObject);
	Dialog.Show(ChoiceNotification1);
	
EndProcedure

&AtClient
Procedure Confirm(Command)
	
	QueryConsoleSettings = New Structure;
	QueryConsoleSettings.Insert("QueryConsoleUsageOption", QueryConsoleUsageOption);
	QueryConsoleSettings.Insert("PathToExternalQueryConsole", PathToExternalQueryConsole);
	
	Close(QueryConsoleSettings);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure PathToExternalQueryConsoleSelectionCompletion(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	PathToExternalQueryConsole = SelectedFiles[0];
	
EndProcedure

#EndRegion
