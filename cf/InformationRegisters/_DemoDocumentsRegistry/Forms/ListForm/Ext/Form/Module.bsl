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
	
	If ValueIsFilled(Parameters.RowChoiceMode) Then
		RowChoiceMode = Parameters.RowChoiceMode;
	Else
		RowChoiceMode = "OpenEntryForm";
	EndIf;
	
	If RowChoiceMode = "OpenObjectForm" Then
		Items.RecordSeparator.Visible = False;
		Items.Ref.Visible = False;
		Items.DeletionMark.Visible = False;
		Items.Posted.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	If RowChoiceMode = "OpenEntryForm" Then
		ShowValue(, RowSelected);
	ElsIf RowChoiceMode = "OpenObjectForm" Then
		ShowValue(, Item.CurrentData.Ref);
	EndIf;
EndProcedure

#EndRegion