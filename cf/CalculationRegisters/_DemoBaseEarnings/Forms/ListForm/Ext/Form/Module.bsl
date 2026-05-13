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

	SetConditionalAppearance();

	Parameters.Filter.Property("Organization", FilterOrganization);
	SetDynamicListFilterItem(List, "Organization", FilterOrganization);

	Parameters.Filter.Property("Recorder", FilterRecorder);
	SetDynamicListFilterItem(List, "Recorder", FilterRecorder);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)

	SetDynamicListFilterItem(List, "Organization", FilterOrganization);

EndProcedure

&AtClient
Procedure FilterRecorderOnChange(Item)

	SetDynamicListFilterItem(List, "Recorder", FilterRecorder);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SwitchRecordsActivity(Command)
	CurrentData = Items.List.CurrentData;

	If CurrentData = Undefined Or Not ValueIsFilled(CurrentData.Recorder) Then
		ShowMessageBox(, NStr("ru = 'Не выбран документ';
										|en = 'No document is selected';"));
		Return;
	EndIf;

	SwitchRecordsActivityServer(CurrentData.Recorder);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	List.ConditionalAppearance.Items.Clear();

	Item = List.ConditionalAppearance.Items.Add();

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReversingEntry");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);

EndProcedure

&AtServer
Procedure SwitchRecordsActivityServer(Document)

	BeginTransaction();
	Try
		DataLock = New DataLock;
		DataLockItem = DataLock.Add("CalculationRegister._DemoBaseEarnings.RecordSet");
		DataLockItem.SetValue("Recorder", Document);
		DataLockItem = DataLock.Add(Document.Metadata().FullName());
		DataLockItem.SetValue("Ref", Document);
		DataLockItem.Mode = DataLockMode.Shared;
		DataLock.Lock();

		DeletionMark = Common.ObjectAttributeValue(Document, "DeletionMark");

		If DeletionMark <> Undefined And Not DeletionMark Then

			RegisterRecords = CalculationRegisters._DemoBaseEarnings.CreateRecordSet();
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
Procedure SetDynamicListFilterItem(Val DynamicList, Val FieldName, Val RightValue,
	Val Var_ComparisonType = Undefined)

	If Var_ComparisonType = Undefined Then
		Var_ComparisonType = DataCompositionComparisonType.Equal;
	EndIf;

	CommonClientServer.SetFilterItem(DynamicList.Filter, FieldName, RightValue,
		Var_ComparisonType,, ValueIsFilled(RightValue), DataCompositionSettingsItemViewMode.Inaccessible);

EndProcedure

#EndRegion