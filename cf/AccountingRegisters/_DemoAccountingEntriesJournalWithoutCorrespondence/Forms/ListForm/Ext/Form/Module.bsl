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

	Items.FilterRecorder.TypeRestriction = Metadata.AccountingRegisters._DemoAccountingTransactionLog.StandardAttributes.Recorder.Type;

	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetFilters();
EndProcedure

&AtClient
Procedure OnReopen()
	SetFilters();
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// FORM ITEM EVENT HANDLERS

&AtClient
Procedure FilterAccountOnChange(Item)

	SetFilterItem(List.SettingsComposer.Settings.Filter, "Account", FilterAccount, DataCompositionComparisonType.InHierarchy);

EndProcedure

&AtClient
Procedure FilterOrganizationOnChange(Item)

	SetFilterItem(List.SettingsComposer.Settings.Filter, "Organization", FilterOrganization);

EndProcedure

&AtClient
Procedure FilterRecorderOnChange(Item)

	SetFilterItem(List.SettingsComposer.Settings.Filter, "Recorder", FilterRecorder);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SwitchPostingActivity(Command)

	CurrentData = Items.List.CurrentData;

	If CurrentData = Undefined Or Not ValueIsFilled(CurrentData.Recorder) Then
		ShowMessageBox(, NStr("ru = 'Не выбран документ';
										|en = 'No document is selected';"));
		Return;
	EndIf;

	SwitchPostingActivityServer(CurrentData.Recorder);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SwitchPostingActivityServer(Document)

	BeginTransaction();
	Try
		DataLock = New DataLock;
		DataLockItem = DataLock.Add(
			"AccountingRegister._DemoAccountingTransactionLog.RecordSet");
		DataLockItem.SetValue("Recorder", Document);
		DataLockItem = DataLock.Add(Document.Metadata().FullName());
		DataLockItem.SetValue("Ref", Document);
		DataLockItem.Mode = DataLockMode.Shared;
		DataLock.Lock();

		DeletionMark = Common.ObjectAttributeValue(Document, "DeletionMark");

		If DeletionMark <> Undefined And Not DeletionMark Then

			RegisterRecords = AccountingRegisters._DemoAccountingTransactionLog.CreateRecordSet();
			RegisterRecords.Filter.Recorder.Set(Document);
			RegisterRecords.Read();

			If RegisterRecords.Count() > 0 Then
				RegisterRecords.SetActive(Not RegisterRecords[0].Active);
				RegisterRecords.Write();
			EndIf;

		EndIf;

		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

	Items.List.Refresh();

EndProcedure

&AtClientAtServerNoContext
Procedure SetFilterItem(Val Filter, Val FieldName, Val RightValue,
	Val Var_ComparisonType = Undefined)

	If Var_ComparisonType = Undefined Then
		Var_ComparisonType = DataCompositionComparisonType.Equal;
	EndIf;

	CommonClientServer.SetFilterItem(Filter, FieldName, RightValue,
		Var_ComparisonType,, ValueIsFilled(RightValue), DataCompositionSettingsItemViewMode.Inaccessible);

EndProcedure

&AtClient
Function FilterValue(FilterItems1, FieldName)

	For Each FilterElement In FilterItems1 Do
		If FilterElement.LeftValue = New DataCompositionField(FieldName) Then
			Return FilterElement.RightValue;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure SetFilters()
	
	FilterAccount = FilterValue(List.SettingsComposer.Settings.Filter.Items, "Account");
	FilterOrganization = FilterValue(List.SettingsComposer.Settings.Filter.Items, "Organization");
	FilterRecorder = FilterValue(List.SettingsComposer.Settings.Filter.Items, "Recorder");
	
EndProcedure

#EndRegion