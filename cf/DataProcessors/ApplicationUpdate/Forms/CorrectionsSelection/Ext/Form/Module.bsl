///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	ReadOnly = Parameters.ReadOnly;
	If ReadOnly Then
		Items.FormCancel.Visible             = False;
		Items.CorrectionsMark.ReadOnly = True;
	EndIf;
	
	Items.GroupNoteRecalled.Visible = False;
	PatchesDetails = GetFromTempStorage(Parameters.AddressPatchesDetails);

	For Each CurrentPatch In PatchesDetails Do
		
		If Parameters.ListOfCorrections.FindByValue(CurrentPatch.Id) = Undefined Then
			Continue;
		EndIf;
		
		If CurrentPatch.Revoked1 Then
			Items.GroupNoteRecalled.Visible = True;
		EndIf;
		
		LineCorrection = Corrections.Add();
		FillPropertyValues(LineCorrection, CurrentPatch, "LongDesc, Revoked1, Id");
		
		LineCorrection.Description = ?(
			LineCorrection.Revoked1,
			CurrentPatch.Description + " " + NStr("ru = '(Исправление заменено)';
														|en = '(Patch replaced)';"),
			CurrentPatch.Description);
		
		LineCorrection.Mark = (LineCorrection.Revoked1
			Or Parameters.SelectedPatches.FindByValue(LineCorrection.Id) <> Undefined);
		
		LineCorrection.DescriptionDisplayed = CollapsedDetailsText(
			LineCorrection.LongDesc,
			LineCorrection.CanExpand);
		
		If LineCorrection.CanExpand Then
			// Initially, details are collapsed.
			LineCorrection.HeaderReferencesActions = NStr("ru = 'Подробнее';
															|en = 'Details';");
		EndIf;
		
	EndDo;
	
	RefreshLabelTotalPatchesSelected(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCorrections

&AtClient
Procedure CorrectionsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "CorrectionsHeaderReferencesActions" Then
		CurrentData = Items.Corrections.CurrentData;
		If CurrentData.IsExpanded Then
			CurrentData.DescriptionDisplayed = CollapsedDetailsText(CurrentData.LongDesc);
			CurrentData.IsExpanded = False;
			CurrentData.HeaderReferencesActions = NStr("ru = 'Подробнее';
														|en = 'Details';");
		Else
			CurrentData.DescriptionDisplayed = CurrentData.LongDesc;
			CurrentData.IsExpanded = True;
			CurrentData.HeaderReferencesActions = NStr("ru = 'Свернуть';
														|en = 'Collapse';");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CorrectionsMarkOnChange(Item)
	
	RefreshLabelTotalPatchesSelected(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectAllCommand(Command)
	
	For Each PatchString In Corrections Do
		PatchString.Mark = True;
	EndDo;
	
	RefreshLabelTotalPatchesSelected(ThisObject);
	
EndProcedure

&AtClient
Procedure ClearAll3(Command)
	
	ClearMark1();
	RefreshLabelTotalPatchesSelected(ThisObject);
	
EndProcedure

&AtClient
Procedure OkCommand(Command)
	
	If ReadOnly Then
		
		Close();
		
	Else
		
		Result = New ValueList;
		For Each PatchString In Corrections Do
			If PatchString.Mark Then
				Result.Add(PatchString.Id);
			EndIf;
		EndDo;
		
		If Result.Count() = 0 Then
			ShowMessageBox(, NStr("ru = 'Выберите исправления для установки.';
											|en = 'Select patches to install.';"));
			Return;
		EndIf;
		
		Close(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Pick(Command)
	
	NotifyDescription = New NotifyDescription(
		"PickCompletion",
		ThisObject);
	
	ShowInputString(
		NotifyDescription,
		"",
		NStr("ru = 'Введите список наименований исправлений (патчей).';
			|en = 'Enter a list of patch descriptions.';"),
		,
		True);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Function CollapsedDetailsText(LongDesc, CanExpand = False)
	
	CanExpand = True;
	CPCharPosition = StrFind(LongDesc, Chars.LF);
	If CPCharPosition = 0 Then
		If StrLen(LongDesc) > 100 Then
			Return Left(LongDesc, 100) + "...";
		Else
			CanExpand = False;
			Return LongDesc;
		EndIf;
	ElsIf CPCharPosition > 100 Then
		Return Left(LongDesc, 100) + "...";
	Else
		Return Left(LongDesc, CPCharPosition - 1) + "...";
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Procedure RefreshLabelTotalPatchesSelected(Form)
	
	CountSelected = 0;
	For Each LineCorrection In Form.Corrections Do
		If LineCorrection.Mark Then
			CountSelected = CountSelected + 1;
		EndIf;
	EndDo;
	
	Form.TextSelectedCorrections = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Всего выбрано исправлений %1 из %2';
			|en = 'Total %1 patches selected out of %2';"),
		CountSelected,
		Form.Corrections.Count());
	
EndProcedure

&AtClient
Procedure ClearMark1()
	
	For Each PatchString In Corrections Do
		If Not PatchString.Revoked1 Then
			PatchString.Mark = False;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorrectionsMark.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorrectionsDescription.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Corrections.Revoked1");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor",     StyleColors.InactiveLineColor);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorrectionsHeaderReferencesActions.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Corrections.CanExpand");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", True);
	
EndProcedure

&AtClient
Procedure PickCompletion(Result, AdditionalParameters) Export
	
	ClearMark1();
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	StringComposition = StringFunctionsClientServer.SplitStringIntoWordArray(Result);
	
	For Each Value In StringComposition Do
		For Each PatchString In Corrections Do
			If PatchString.Description = Value Then
				PatchString.Mark = True;
			EndIf;
		EndDo;
	EndDo;
	
	RefreshLabelTotalPatchesSelected(ThisObject);
	
EndProcedure

#EndRegion
