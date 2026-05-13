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
	
	RelativeSize = Parameters.RelativeSize;
	MinimumEffect = Parameters.MinimumEffect;
	Items.MinimumEffect.Visible = Parameters.RebuildMode;
	Title = ?(Parameters.RebuildMode,
	              NStr("ru = 'Параметры перестроения';
						|en = 'Rebuild parameters';"),
	              NStr("ru = 'Параметр расчета оптимальных агрегатов';
						|en = 'Parameter of optimal aggregate calculation';"));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	SelectionResult = New Structure("RelativeSize, MinimumEffect");
	FillPropertyValues(SelectionResult, ThisObject);
	
	NotifyChoice(SelectionResult);
	
EndProcedure

#EndRegion
