///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormCommandsEventHandlers

&AtClient
Procedure ReplaceAllInstances(Command)
	ReferencesArrray = Items.List.SelectedRows;
	If ReferencesArrray.Count() = 0 Then
		ShowMessageBox(, NStr("ru = 'Выберите договор';
										|en = 'Select a contract';"));
		Return;
	EndIf;
	DuplicateObjectsDetectionClient.ReplaceSelected(ReferencesArrray);
EndProcedure

#EndRegion