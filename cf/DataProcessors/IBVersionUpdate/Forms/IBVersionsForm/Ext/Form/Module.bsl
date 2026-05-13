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
	
	VersionRecordSet = InformationRegisters.SubsystemsVersions.CreateRecordSet();
	VersionRecordSet.Read();
	ValueToFormAttribute(VersionRecordSet, "Versions");
	
	If Common.DataSeparationEnabled()
		And Common.SubsystemExists("CloudTechnology.Core") Then
		Items.ListCommands.Visible = False;
		
		DataAreasSubsystemsVersionRegister = "DataAreasSubsystemsVersions";
		AreasVersionRecordSet = InformationRegisters[DataAreasSubsystemsVersionRegister].CreateRecordSet();
		AreasVersionRecordSet.Read();
		ValueToFormAttribute(AreasVersionRecordSet, "AreasVersions");
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		SessionWithoutSeparators = ModuleSaaSOperations.SessionWithoutSeparators();
		
		If Not SessionWithoutSeparators Then
			Items.Versions.ReadOnly = True;
		EndIf;
	Else
		Items.SubsystemsVersions.PagesRepresentation = FormPagesRepresentation.None;
		Items.Versions.CommandBarLocation = FormItemCommandBarLabelLocation.None;
	EndIf;
	
	ToolTipText = NStr("ru = 'Важно. Ошибка будет воспроизводиться до перезапуска обновления.
		|Имитация ошибки заполнения свойства %1.
		|См. процедуру %2 документа %3.';
		|en = 'Important. An error will be simulated before restarting the update.
		|Simulation of the %1 property filling error.
		|See procedure %2 of document %3.';");
	ToolTipText = StringFunctionsClientServer.SubstituteParametersToString(ToolTipText, "SelectionParameters",
		"RegisterDataToProcessForMigrationToNewVersion", "_DemoSalesOrder");
	Items.SimulateInvalidSelectionParameters.ToolTip = ToolTipText;
	
	SimuateErrorOnUpdate = Common.CommonSettingsStorageLoad(
		"IBUpdate", "SimuateErrorOnUpdate", False);
	ExclusiveUpdate = Common.CommonSettingsStorageLoad(
		"IBUpdate", "ExecuteExclusiveUpdate", False);
	SimuateErrorOnDeferredUpdate = Common.CommonSettingsStorageLoad(
		"IBUpdate", "SimuateErrorOnDeferredUpdate", False);
	SimuateErrorOnDeferredParallelUpdate = Common.CommonSettingsStorageLoad(
		"IBUpdate", "SimuateErrorOnDeferredParallelUpdate", False);
	SimulateProblemWithHandlerIDData = Common.CommonSettingsStorageLoad(
		"IBUpdate", "SimulateProblemsWithDataAndHandler", False);
	PauseWhenExecutingHandler = Common.CommonSettingsStorageLoad(
		"IBUpdate", "PauseWhenExecutingHandler", 0);
	SimulateInvalidSelectionParameters = Common.CommonSettingsStorageLoad(
		"IBUpdate", "SimulateErrorInSelectionParameters", False);
	
	PathToForms = FormAttributeToValue("Object").Metadata().FullName() + ".Form";
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If StrFind(LaunchParameter, "StartInfobaseUpdate") > 0 Then
		StartInfobaseUpdate = True;
		Items.StartInfobaseUpdate.ReadOnly = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New NotifyDescription("SelectAndClose", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersVersions

&AtClient
Procedure VersionsOnChange(Item)
	
	CommonDataVersionsChanged = True;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAreasVersions

&AtClient
Procedure AreasVersionsOnChange(Item)
	
	DataAreasVersionsChanged = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAll(Command)
	
	WriteAllAtServer();
	
EndProcedure

&AtClient
Procedure RestartApplication(Command)
	
	Notification = New NotifyDescription("RestartApplicationCompletion", ThisObject);
	ShowQueryBox(Notification, NStr("ru = 'Перезапустить приложение?';
									|en = 'Restart the app?';"), QuestionDialogMode.OKCancel);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	
	WriteAllAtServer();
	Close();
	
EndProcedure

&AtServer
Procedure WriteAllAtServer()
	
	If Not Modified Then
		Common.CommonSettingsStorageSave("IBUpdate",
			"ExecuteExclusiveUpdate", ExclusiveUpdate);
		Common.CommonSettingsStorageSave("IBUpdate",
			"SimuateErrorOnUpdate", SimuateErrorOnUpdate);
		Common.CommonSettingsStorageSave("IBUpdate",
			"SimuateErrorOnDeferredUpdate", SimuateErrorOnDeferredUpdate);
		Common.CommonSettingsStorageSave("IBUpdate",
			"SimuateErrorOnDeferredParallelUpdate", SimuateErrorOnDeferredParallelUpdate);
		Common.CommonSettingsStorageSave("IBUpdate",
			"SimulateProblemsWithDataAndHandler", SimulateProblemWithHandlerIDData);
		Common.CommonSettingsStorageSave("IBUpdate",
			"PauseWhenExecutingHandler", PauseWhenExecutingHandler);
		Common.CommonSettingsStorageSave("IBUpdate",
			"SimulateErrorInSelectionParameters", SimulateInvalidSelectionParameters);
		Return;
	EndIf;
	
	Filter = New Structure("SubsystemName", Metadata.Name);
	
	ConfigurationVersion = Undefined;
	If Common.DataSeparationEnabled() Then
		
		If Common.SubsystemExists("CloudTechnology.Core") Then
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
			SessionWithoutSeparators = ModuleSaaSOperations.SessionWithoutSeparators();
		Else
			SessionWithoutSeparators = True;
		EndIf;
		
		If SessionWithoutSeparators
		   And CommonDataVersionsChanged Then
			
			ConfigurationVersion = Versions.FindRows(Filter);
			FormAttributeToValue("Versions").Write();
		EndIf;
		
		If DataAreasVersionsChanged Then
			ConfigurationVersion = AreasVersions.FindRows(Filter);
			FormAttributeToValue("AreasVersions").Write();
		EndIf;
	Else
		If CommonDataVersionsChanged Then
			ConfigurationVersion = Versions.FindRows(Filter);
			FormAttributeToValue("Versions").Write();
		EndIf;
	EndIf;
	
	If ConfigurationVersion <> Undefined
		And ConfigurationVersion.Count() <> 0 Then
		Version = ConfigurationVersion[0].Version;
		Filter = New Structure;
		Filter.Insert("ObjectKey", "IBUpdate");
		Filter.Insert("SettingsKey", "SystemChangesDisplayLastVersion");
		
		Selection = CommonSettingsStorage.Select(Filter);
		
		While Selection.Next() Do
			Common.CommonSettingsStorageSave("IBUpdate",
				"SystemChangesDisplayLastVersion", Version, , Selection.User);
		EndDo;
		
	EndIf;
	
	Common.CommonSettingsStorageSave("IBUpdate",
		"ExecuteExclusiveUpdate", ExclusiveUpdate);
	Common.CommonSettingsStorageSave("IBUpdate",
		"SimuateErrorOnUpdate", SimuateErrorOnUpdate);
	Common.CommonSettingsStorageSave("IBUpdate",
		"SimuateErrorOnDeferredUpdate", SimuateErrorOnDeferredUpdate);
	Common.CommonSettingsStorageSave("IBUpdate",
		"SimuateErrorOnDeferredParallelUpdate", SimuateErrorOnDeferredParallelUpdate);
	Common.CommonSettingsStorageSave("IBUpdate",
		"SimulateProblemsWithDataAndHandler", SimulateProblemWithHandlerIDData);
	Common.CommonSettingsStorageSave("IBUpdate",
		"PauseWhenExecutingHandler", PauseWhenExecutingHandler);
	Common.CommonSettingsStorageSave("IBUpdate",
		"SimulateErrorInSelectionParameters", SimulateInvalidSelectionParameters);
	
	If CommonDataVersionsChanged Then
		UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
		UpdateInfo.LegitimateVersion = "";
		InfobaseUpdateInternal.WriteInfobaseUpdateInfo(UpdateInfo);
	EndIf;
	
	Modified           = False;
	CommonDataVersionsChanged    = False;
	DataAreasVersionsChanged = False;
	
EndProcedure

&AtClient
Procedure RestartApplicationCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.OK Then
		Return;
	EndIf;
	
	NewStartupParameter = StrReplace(LaunchParameter, """", """""");
	
	If Not StartInfobaseUpdate
	 Or StrFind(LaunchParameter, "StartInfobaseUpdate") > 0 Then
		
		AdditionalParametersOfCommandLine = "/C """ + NewStartupParameter + """";
	Else
		AdditionalParametersOfCommandLine = "/C """ + NewStartupParameter
			+ ?(Right(LaunchParameter, 1) = ";", "", ";") + "StartInfobaseUpdate""";
	EndIf;
	
	Exit(True, True, AdditionalParametersOfCommandLine);
	
EndProcedure

#EndRegion
