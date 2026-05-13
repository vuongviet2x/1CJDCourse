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
	
	PopulateTitlesAndTooltips();
	
	EditCheckboxes(ThisObject, True, True);
	EditCheckboxes(ThisObject, True, False);
	
	If Common.DataSeparationEnabled() Then
		
		If Common.SubsystemExists("CloudTechnology.Core") Then
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
			SessionWithoutSeparators = ModuleSaaSOperations.SessionWithoutSeparators();
		Else
			SessionWithoutSeparators = True;
		EndIf;
		
		If SessionWithoutSeparators Then
			UpdateSharedData = True;
		Else
			UpdateSeparatedData = True;
		EndIf;
		
	Else
		UpdateSharedData = True;
		UpdateSeparatedData   = True;
	EndIf;
	
	If Not Common.DataSeparationEnabled()
	 Or Not UpdateSharedData Then
		
		Items.DataArea.Visible                = False;
		Items.SignInToSpecifiedDataArea.Visible = False;
		Items.CurrentDataArea.Visible         = False;
		Items.SignOutOfCurrentDataArea.Visible  = False;
	EndIf;
	
	UpdateCurrentDataArea1();
	
	If Not Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Items.AccessManagementSubsystem.Visible = False;
		Items.AccessManagementSubsystemData.Visible = False;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		Items.ReportOptionsSubsystemData.Visible = False;
		Items.ReportOptionsSubsystem.Visible = False;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.InformationOnStart") Then
		Items.InformationOnStartSubsystemData.Visible = False;
		Items.InformationOnStartSubsystem.Visible = False;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.AccountingAudit") Then
		Items.AccountingAuditSubsystemData.Visible = False;
		Items.AccountingAuditSubsystem.Visible = False;
	EndIf;
	
	UpdateVisibilityBySetupMode();
	
	UpdateItemAvailability(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If StrFind(LaunchParameter, "-BatchMode") > 0 Then
#If Not WebClient Then
		BatchRun = True;
		PerformABatchLaunch();
#Else
		ErrorText =
			NStr("ru = 'В веб-клиенте недоступен пакетный режим инструмента разработчика
			           |""Обновление вспомогательных данных"", используйте тонкий клиент.';
						|en = 'The parameterized launch mode of
						|the ""Service data update"" development tool is unavailable in web client. Use thin client.';");
			Raise ErrorText;
#EndIf
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	UpdateVisibilityBySetupMode();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SetupModeOnChange(Item)
	
	UpdateVisibilityBySetupMode();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SignInToSpecifiedDataArea(Command)
	
	UpdateCurrentDataArea1();
	
	If DataArea = CurrentDataArea Then
		ShowAWarningToTheUser(Undefined,
			NStr("ru = 'Вход в указанную область данных уже выполнен.';
				|en = 'You are already logged on to the specified data area.';"));
		Return;
	EndIf;
	
	If CurrentDataArea <> Undefined Then
		SignOutOfDataAreaClient();		
	EndIf;
	
	SignInToDataAreaClient();
	UpdateCurrentDataArea1();
	
EndProcedure

&AtClient
Procedure SignOutOfCurrentDataArea(Command)
	
	UpdateCurrentDataArea1();
	
	If CurrentDataArea = Undefined Then
		ShowAWarningToTheUser(Undefined,
			NStr("ru = 'Вход в область данных еще не выполнен.';
				|en = 'You are not logged on to a data area.';"));
		Return;
	EndIf;
	
	SignOutOfDataAreaClient();
	
	If Not UpdateCurrentDataArea1() Then
		ShowAWarningToTheUser(Undefined,
			NStr("ru = 'Область данных не изменилась.';
				|en = 'The data area is not changed.';"));
	EndIf;
	
EndProcedure

&AtClient
Procedure RunUpdate(Command)
	
	DataMarked = False;
	
	If Not ValueIsFilled(SetupMode) Then
		DataMarked = True;
	EndIf;
	
	// StandardSubsystems Core
	If SetupMode = "SimpleSetup" And CoreSubsystemData
	 Or SetupMode = "AdvancedSetup"
	     And (    MetadataObjectIDs And Items.MetadataObjectIDs.Enabled
	        Or ExtensionObjectIDs And Items.ExtensionObjectIDs.Enabled
	        Or ProgramInterfaceCache        And Items.ProgramInterfaceCache.Enabled) Then
		
		DataMarked = True;
	EndIf;
	
	// StandardSubsystems Users
	If SetupMode = "SimpleSetup" And UsersSubsystemData
	 Or SetupMode = "AdvancedSetup"
	     And (    CheckRoleAssignment And Items.CheckRoleAssignment.Enabled
	        Or UserGroupsHierarchy   And Items.UserGroupsHierarchy.Enabled
	        Or UserGroupCompositions    And Items.UserGroupCompositions.Enabled
	        Or UsersInfo       And Items.UsersInfo.Enabled) Then
		
		DataMarked = True;
	EndIf;
	
	// StandardSubsystems AccessManagement
	If Not DataMarked And CommonClient.SubsystemExists("StandardSubsystems.AccessManagement") Then
		If SetupMode = "SimpleSetup" And AccessManagementSubsystemData
		 Or SetupMode = "AdvancedSetup"
		   And (    RolesRights                                    And Items.RolesRights.Enabled
		      Or RightsDependencies                               And Items.RightsDependencies.Enabled
		      Or AccessKindsProperties                          And Items.AccessKindsProperties.Enabled
		      Or SuppliedAccessGroupProfilesDescription      And Items.SuppliedAccessGroupProfilesDescription.Enabled
		      Or AvailableRightsForObjectsRightSettingsDetails And Items.AvailableRightsForObjectsRightSettingsDetails.Enabled
		      
		      Or SuppliedAccessGroupProfiles     And Items.SuppliedAccessGroupProfiles.Enabled
		      Or UnsuppliedAccessGroupProfiles   And Items.UnsuppliedAccessGroupProfiles.Enabled
		      Or InfobaseUsersRoles And Items.InfobaseUsersRoles.Enabled
		      Or AccessRestrictionParameters         And Items.AccessRestrictionParameters.Enabled
		      Or AccessGroupsTables                 And Items.AccessGroupsTables.Enabled
		      Or AccessGroupsValues                And Items.AccessGroupsValues.Enabled
		      Or ObjectRightsSettingsInheritance    And Items.ObjectRightsSettingsInheritance.Enabled
		      Or ObjectsRightsSettings               And Items.ObjectsRightsSettings.Enabled
		      Or AccessValuesGroups               And Items.AccessValuesGroups.Enabled
		      Or AccessValuesSets               And Items.AccessValuesSets.Enabled) Then
			
			DataMarked = True;
		EndIf;
	EndIf;
	
	// StandardSubsystems ReportsOptions
	If Not DataMarked And CommonClient.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		If SetupMode = "SimpleSetup" And ReportOptionsSubsystemData
		 Or SetupMode = "AdvancedSetup"
		   And (    ConfigurationReports  And Items.ConfigurationReports.Enabled
		      Or ExtensionReports    And Items.ExtensionReports.Enabled
		      Or ReportSearchIndex And Items.ReportSearchIndex.Enabled) Then
		
			DataMarked = True;
		EndIf;
	EndIf;
	
	// StandardSubsystems InformationOnStart
	If SetupMode = "SimpleSetup" And InformationOnStartSubsystemData
	 Or SetupMode = "AdvancedSetup"
	   And InformationPackagesOnStart And Items.InformationPackagesOnStart.Enabled Then
		
		DataMarked = True;
	EndIf;
	
	// StandardSubsystems AccountingAudit
	If SetupMode = "SimpleSetup" And AccountingAuditSubsystemData
	 Or SetupMode = "AdvancedSetup"
	   And AccountingCheckRules And Items.AccountingCheckRules.Enabled Then
		
		DataMarked = True;
	EndIf;
	
	If Not DataMarked Then
		ShowAWarningToTheUser(Undefined,
			NStr("ru = 'Отметьте данные, которые нужно обновить.';
				|en = 'Mark the data that you want to update.';"));
		Return;
	EndIf;
	
	// Set the standard color for all items.
	ParametersOfUpdate = ParametersOfUpdate();
	HighlightChanges(
		UpdateParametersToTheLine(ParametersOfUpdate), False);
	
	HasChanges = False;
	ExecuteUpdateAtServer(HasChanges);
	
	If HasChanges = Undefined Then
		ShowAWarningToTheUser(Undefined,
			NStr("ru = 'После открытия обработки изменилась текущая область данных.
			           |Если нужно проверьте настройки и повторите команду.';
						|en = 'Current data area has changed after opening a data processor.
						|Check settings and retry the command if you need to.';"));
		Return;
	EndIf;
	
	If UpdateSharedData And UpdateSeparatedData Then
		
		If HasChanges Then
			Text = NStr("ru = 'Обновление выполнено успешно.';
						|en = 'Updated successfully.';");
		Else
			Text = NStr("ru = 'Обновление не требуется.';
						|en = 'No update required.';");
		EndIf;
		
	ElsIf UpdateSharedData Then
		
		If HasChanges Then
			Text = NStr("ru = 'Обновление неразделенных данных выполнено успешно.';
						|en = 'Shared data updated successfully.';");
		Else
			Text = NStr("ru = 'Обновление неразделенных данных не требуется.';
						|en = 'No update of shared data required.';");
		EndIf;
	Else
		If HasChanges Then
			Text = NStr("ru = 'Обновление разделенных данных выполнено успешно.';
						|en = 'Separated data updated successfully.';");
		Else
			Text = NStr("ru = 'Обновление разделенных данных не требуется.';
						|en = 'No update of separated data required.';");
		EndIf;
	EndIf;
	
	ShowAWarningToTheUser(Undefined, Text);
	
	
EndProcedure

&AtClient
Procedure CheckAll(Command)
	EditCheckboxes(ThisObject, True);
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	EditCheckboxes(ThisObject, False);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure PopulateTitlesAndTooltips()
	
	Items.Explanation2.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.Explanation2.Title, "AccessManagementOverridable", "ReportsOptionsOverridable");
	
	Items.RightsDependencies.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Данные из процедуры %1, используемые в шаблонах RLS (см. процедуру в общем модуле %2).';
			|en = 'The %1 procedure data used in RLS templates. See the procedure in the %2 common module.';"),
		"OnFillAccessRightsDependencies",
		"AccessManagementOverridable");
	
	Items.AccessKindsProperties.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Данные из процедуры %1';
			|en = '%1 procedure data';"), "OnFillAccessKinds");
	
	Items.AccessKindsProperties.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Кэш свойств видов доступа (см. процедуру в общем модуле %1).
		           |Используется для ускорения первого обращения в разных случаях использования приложения.';
					|en = 'Cached access type properties. See the common module %1.
					|After the first call the data will be retrieved from the cache.';"),
		"AccessManagementOverridable");
	
	Items.SuppliedAccessGroupProfilesDescription.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Данные из процедуры %1';
			|en = '%1 procedure data';"), "OnFillSuppliedAccessGroupProfiles");
	
	Items.SuppliedAccessGroupProfilesDescription.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Кэш описаний поставляемых профилей групп доступа (см. процедуру в общем модуле %1).';
			|en = 'Cached description of the 1C-supplied access group profiles. See the common module %1.';"),
		"AccessManagementOverridable");
	
	Items.AvailableRightsForObjectsRightSettingsDetails.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Данные из процедуры %1';
			|en = '%1 procedure data';"), "OnFillAvailableRightsForObjectsRightsSettings");
	
	Items.AvailableRightsForObjectsRightSettingsDetails.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Кэш описания возможных прав для настройки прав объектов (см. процедуру в общем модуле %1).
		           |Используется для ускорения работы приложения при первом обращении.';
					|en = 'Cached description of the custom access rights. See the common module %1.
					|After the first call the data will be retrieved from the cache.';"),
		"AccessManagementOverridable");
	
EndProcedure

&AtClient
Procedure ShowAWarningToTheUser(NotifyDescriptionOnCompletion, Text)
	If BatchRun Then
		Return;
	EndIf;
	
	ShowMessageBox(NotifyDescriptionOnCompletion, Text);
EndProcedure

&AtClient
Procedure PerformABatchLaunch()
#If Not WebClient Then
	BatchLaunchUpdateOptions = StrSplit(LaunchParameter, ";");
	
	ErrorLogFile = "";
	ChangedUpdateParameters = New Structure;
	For Each UpdateParameter In BatchLaunchUpdateOptions Do
		
		KeyValue = StrSplit(UpdateParameter, "=");
		If KeyValue.Count() <> 2 Then
			Continue;
		EndIf;
		
		Var_Key = TrimAll(KeyValue[0]);
		Value = TrimAll(KeyValue[1]);
		
		If Var_Key = "ErrorLogFile" Then
			ErrorLogFile = Value;
			Continue;
		EndIf;
		
		ParametersOfUpdate = ParametersOfUpdate();
		If Not ParametersOfUpdate.Property(Var_Key) Then
			Continue;
		EndIf;
		
		ChangedUpdateParameters.Insert(Var_Key, Boolean(Value));
		
	EndDo;
	
	For Each UpdateParameter In ParametersOfUpdate() Do
		ThisObject[UpdateParameter.Key] = True;
	EndDo;
	
	FillPropertyValues(ThisObject, ChangedUpdateParameters);
	SetupMode = "AdvancedSetup";
	
	Try
		RunUpdate(Undefined);
		AssignCurrentUserWithRoleOpenAdditionalReportsAndDataProcessorsInteractively();
	Except
		ErrorInfo = ErrorInfo();
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		
		WriteUpdateErrorToFile(ErrorLogFile, ErrorPresentation);
	EndTry;
	
	Exit(False, False);
#EndIf
EndProcedure

&AtClientAtServerNoContext
Function ParametersOfUpdate()
	ParametersOfUpdate = New Structure;
	
	ParametersOfUpdate.Insert("CoreSubsystemData");
	ParametersOfUpdate.Insert("MetadataObjectIDs");
	ParametersOfUpdate.Insert("ExtensionObjectIDs");
	ParametersOfUpdate.Insert("ProgramInterfaceCache");
	
	ParametersOfUpdate.Insert("UsersSubsystemData");
	ParametersOfUpdate.Insert("CheckRoleAssignment");
	ParametersOfUpdate.Insert("UserGroupsHierarchy");
	ParametersOfUpdate.Insert("UserGroupCompositions");
	ParametersOfUpdate.Insert("UsersInfo");
	
	ParametersOfUpdate.Insert("ReportOptionsSubsystemData");
	ParametersOfUpdate.Insert("ConfigurationReports");
	ParametersOfUpdate.Insert("ExtensionReports");
	ParametersOfUpdate.Insert("ReportSearchIndex");
	
	ParametersOfUpdate.Insert("InformationOnStartSubsystemData");
	ParametersOfUpdate.Insert("InformationPackagesOnStart");
	
	ParametersOfUpdate.Insert("AccountingAuditSubsystemData");
	ParametersOfUpdate.Insert("AccountingCheckRules");
	
	ParametersOfUpdate.Insert("AccessManagementSubsystemData");
	ParametersOfUpdate.Insert("RolesRights");
	ParametersOfUpdate.Insert("RightsDependencies");
	ParametersOfUpdate.Insert("AccessKindsProperties");
	ParametersOfUpdate.Insert("SuppliedAccessGroupProfilesDescription");
	ParametersOfUpdate.Insert("AvailableRightsForObjectsRightSettingsDetails");
	ParametersOfUpdate.Insert("SuppliedAccessGroupProfiles");
	ParametersOfUpdate.Insert("UnsuppliedAccessGroupProfiles");
	ParametersOfUpdate.Insert("InfobaseUsersRoles");
	ParametersOfUpdate.Insert("AccessRestrictionParameters");
	ParametersOfUpdate.Insert("AccessGroupsTables");
	ParametersOfUpdate.Insert("AccessGroupsValues");
	ParametersOfUpdate.Insert("ObjectRightsSettingsInheritance");
	ParametersOfUpdate.Insert("ObjectRightsSettingsInheritance");
	ParametersOfUpdate.Insert("ObjectsRightsSettings");
	ParametersOfUpdate.Insert("AccessValuesGroups");
	ParametersOfUpdate.Insert("AccessValuesSets");
	
	Return ParametersOfUpdate;
EndFunction

&AtClientAtServerNoContext
Function UpdateParametersToTheLine(ParametersOfUpdate)
	Keys = New Array;
	
	For Each KeyValue In ParametersOfUpdate Do
		Keys.Add(KeyValue.Key);
	EndDo;
	
	Return StrConcat(Keys, "," + Chars.LF);
EndFunction

&AtServer
Procedure ExecuteUpdateAtServer(HasChanges)
	
	If UpdateCurrentDataArea1() Then
		HasChanges = Undefined;
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Not Common.DataSeparationEnabled() Then
		ExecuteSharedDataUpdate(HasChanges);
		ExecuteSeparatedDataUpdate(HasChanges);
	Else
		If UpdateSharedData Then
			BackToCurrentDataArea = False;
			
			If Common.SeparatedDataUsageAvailable() Then
				// Temporarily leave the data area.
				BackToCurrentDataArea = True;
				SignOutOfDataArea();
				RefreshReusableValues();
			EndIf;
			
			Try
				// Update shared data.
				ExecuteSharedDataUpdate(HasChanges);
			Except
				If BackToCurrentDataArea Then
					SignInToDataArea(CurrentDataArea);
				EndIf;
				RefreshReusableValues();
				Raise;
			EndTry;
			
			If BackToCurrentDataArea Then
				SignInToDataArea(CurrentDataArea);
				RefreshReusableValues();
			EndIf;
		EndIf;
		
		If UpdateSeparatedData Then
			// Update data of the data area.
			ExecuteSeparatedDataUpdate(HasChanges);
		EndIf;
	EndIf;
	
	UpdateCurrentDataArea1();
	
EndProcedure

&AtServer
Procedure ExecuteSharedDataUpdate(HasOverallChanges)
	
	SetPrivilegedMode(True);
	
	ShouldUpdate = False;
	// ACC:1443-off - No.644.3.5. It's acceptable to access the metadata object as
	// the call is intended specifically for this developer tool.
	ParametersOfUpdate = InformationRegisters.ApplicationRuntimeParameters.ParametersOfUpdate(ShouldUpdate);
	// ACC:1443-on
	
	// StandardSubsystems Core
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And CoreSubsystemData
	 Or SetupMode = "AdvancedSetup" And MetadataObjectIDs Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.Core.MetadataObjectIDs.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And CoreSubsystemData
	 Or SetupMode = "AdvancedSetup" And ProgramInterfaceCache Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.Core.ClearAPIsCache.ShouldUpdate = True;
		ParametersOfUpdate.AttachableCommands.PluginCommandsConfig.ShouldUpdate = True;
	EndIf;
	
	// StandardSubsystems Users
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And UsersSubsystemData
	 Or SetupMode = "AdvancedSetup" And CheckRoleAssignment Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.Users.CheckRoleAssignment.ShouldUpdate = True;
	EndIf;
	
	// StandardSubsystems AccessManagement
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And AccessManagementSubsystemData
	 Or SetupMode = "AdvancedSetup" And RolesRights Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AccessManagement.RolesRights.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And AccessManagementSubsystemData
	 Or SetupMode = "AdvancedSetup" And RightsDependencies Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AccessManagement.RightsDependencies.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And AccessManagementSubsystemData
	 Or SetupMode = "AdvancedSetup" And AccessKindsProperties Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AccessManagement.AccessKindsProperties.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And AccessManagementSubsystemData
	 Or SetupMode = "AdvancedSetup" And SuppliedAccessGroupProfilesDescription Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AccessManagement.SuppliedAccessGroupProfilesDescription.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And AccessManagementSubsystemData
	 Or SetupMode = "AdvancedSetup" And AvailableRightsForObjectsRightSettingsDetails Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AccessManagement.AvailableRightsForObjectsRightSettingsDetails.ShouldUpdate = True;
	EndIf;
	
	// StandardSubsystems ReportsOptions
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And ReportOptionsSubsystemData
	 Or SetupMode = "AdvancedSetup" And ConfigurationReports Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.ReportsOptions.ParametersReportsConfiguration.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And ReportOptionsSubsystemData
	 Or SetupMode = "AdvancedSetup" And ReportSearchIndex Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.ReportsOptions.ParametersIndexSearchReportsConfiguration.ShouldUpdate = True;
	EndIf;
	
	// StandardSubsystems InformationOnStart
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And InformationOnStartSubsystemData
	 Or SetupMode = "AdvancedSetup" And InformationPackagesOnStart Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.InformationOnStart.InformationPackagesOnStart.ShouldUpdate = True;
	EndIf;
	
	// StandardSubsystems AccountingAudit
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And AccountingAuditSubsystemData
	 Or SetupMode = "AdvancedSetup" And AccountingCheckRules Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AccountingAudit.SystemChecksAccounting.ShouldUpdate = True;
	EndIf;
	
	If Not ShouldUpdate Then
		Return;
	EndIf;
	
	// ACC:1443-off - No.644.3.5. It's acceptable to access the metadata object as
	// the call is intended specifically for this developer tool.
	InformationRegisters.ApplicationRuntimeParameters.ExecuteUpdateUnsharedDataInBackground(
		ParametersOfUpdate, UUID);
	// ACC:1443-on
	
	// StandardSubsystems Core
	If ParametersOfUpdate.Core.MetadataObjectIDs.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("CoreSubsystemData, MetadataObjectIDs");
	EndIf;
	
	If ParametersOfUpdate.Core.ClearAPIsCache.HasChanges
	 Or ParametersOfUpdate.AttachableCommands.PluginCommandsConfig.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("CoreSubsystemData, ProgramInterfaceCache");
	EndIf;
	
	// StandardSubsystems Users
	If ParametersOfUpdate.Users.CheckRoleAssignment.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("UsersSubsystemData, CheckRoleAssignment");
	EndIf;
	
	// StandardSubsystems AccessManagement
	If ParametersOfUpdate.AccessManagement.RolesRights.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("AccessManagementSubsystemData, RolesRights");
	EndIf;
	
	If ParametersOfUpdate.AccessManagement.RightsDependencies.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("AccessManagementSubsystemData, RightsDependencies");
	EndIf;
	
	If ParametersOfUpdate.AccessManagement.AccessKindsProperties.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("AccessManagementSubsystemData, AccessKindsProperties");
	EndIf;
	
	If ParametersOfUpdate.AccessManagement.SuppliedAccessGroupProfilesDescription.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("AccessManagementSubsystemData, SuppliedAccessGroupProfilesDescription");
	EndIf;
	
	If ParametersOfUpdate.AccessManagement.AvailableRightsForObjectsRightSettingsDetails.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("AccessManagementSubsystemData, AvailableRightsForObjectsRightSettingsDetails");
	EndIf;
	
	// StandardSubsystems ReportsOptions
	If ParametersOfUpdate.ReportsOptions.ParametersReportsConfiguration.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("ReportOptionsSubsystemData, ConfigurationReports");
	EndIf;
	
	If ParametersOfUpdate.ReportsOptions.ParametersIndexSearchReportsConfiguration.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("ReportOptionsSubsystemData, ReportSearchIndex");
	EndIf;
	
	// StandardSubsystems InformationOnStart
	If ParametersOfUpdate.InformationOnStart.InformationPackagesOnStart.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("InformationOnStartSubsystemData, InformationPackagesOnStart");
	EndIf;
	
	// StandardSubsystems AccountingAudit
	If ParametersOfUpdate.AccountingAudit.SystemChecksAccounting.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("AccountingAuditSubsystemData, AccountingCheckRules");
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteSeparatedDataUpdate(HasOverallChanges)
	
	SetPrivilegedMode(True);
	
	ShouldUpdate = False;
	// ACC:1443-off - No.644.3.5. It's acceptable to access the metadata object as
	// the call is intended specifically for this developer tool.
	ParametersOfUpdate = InformationRegisters.ExtensionVersionParameters.ParametersOfUpdate(ShouldUpdate);
	// ACC:1443-on
	
	// StandardSubsystems Core
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And CoreSubsystemData
	 Or SetupMode = "AdvancedSetup" And ExtensionObjectIDs Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.Core.ExtensionObjectIDs.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And CoreSubsystemData
	 Or SetupMode = "AdvancedSetup" And ProgramInterfaceCache Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AttachableCommands.ConnectableExtensionCommands.ShouldUpdate = True;
	EndIf;
	
	// StandardSubsystems Users
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And UsersSubsystemData
	 Or SetupMode = "AdvancedSetup" And UserGroupsHierarchy Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.Users.UserGroupsHierarchy.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And UsersSubsystemData
	 Or SetupMode = "AdvancedSetup" And UserGroupCompositions Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.Users.UserGroupCompositions.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And UsersSubsystemData
	 Or SetupMode = "AdvancedSetup" And UsersInfo Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.Users.UsersInfo.ShouldUpdate = True;
	EndIf;
	
	// StandardSubsystems AccessManagement
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And AccessManagementSubsystemData
	 Or SetupMode = "AdvancedSetup" And SuppliedAccessGroupProfiles Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AccessManagement.SuppliedAccessGroupProfiles.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And AccessManagementSubsystemData
	 Or SetupMode = "AdvancedSetup" And UnsuppliedAccessGroupProfiles Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AccessManagement.UnsuppliedAccessGroupProfiles.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And AccessManagementSubsystemData
	 Or SetupMode = "AdvancedSetup" And InfobaseUsersRoles Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AccessManagement.InfobaseUsersRoles.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And AccessManagementSubsystemData
	 Or SetupMode = "AdvancedSetup" And AccessRestrictionParameters Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AccessManagement.AccessRestrictionParameters.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And AccessManagementSubsystemData
	 Or SetupMode = "AdvancedSetup" And AccessGroupsTables Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AccessManagement.AccessGroupsTables.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And AccessManagementSubsystemData
	 Or SetupMode = "AdvancedSetup" And AccessGroupsValues Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AccessManagement.AccessGroupsValues.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And AccessManagementSubsystemData
	 Or SetupMode = "AdvancedSetup" And ObjectRightsSettingsInheritance Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AccessManagement.ObjectRightsSettingsInheritance.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And AccessManagementSubsystemData
	 Or SetupMode = "AdvancedSetup" And ObjectsRightsSettings Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AccessManagement.ObjectsRightsSettings.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And AccessManagementSubsystemData
	 Or SetupMode = "AdvancedSetup" And AccessValuesGroups Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AccessManagement.AccessValuesGroups.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And AccessManagementSubsystemData
	 Or SetupMode = "AdvancedSetup" And AccessValuesSets Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AccessManagement.AccessValuesSets.ShouldUpdate = True;
	EndIf;
	
	// StandardSubsystems ReportsOptions
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And ReportOptionsSubsystemData
	 Or SetupMode = "AdvancedSetup" And ConfigurationReports Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.ReportsOptions.ConfigurationReports.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And ReportOptionsSubsystemData
	 Or SetupMode = "AdvancedSetup" And ReportSearchIndex Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.ReportsOptions.IndexSearchReportsConfiguration.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And ReportOptionsSubsystemData
	 Or SetupMode = "AdvancedSetup" And ExtensionReports Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.ReportsOptions.ExtensionReports.ShouldUpdate = True;
	EndIf;
	
	If SetupMode = ""
	 Or SetupMode = "SimpleSetup" And ReportOptionsSubsystemData
	 Or SetupMode = "AdvancedSetup" And ReportSearchIndex Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.ReportsOptions.IndexSearchReportsExtensions.ShouldUpdate = True;
	EndIf;
	
	// StandardSubsystems AccountingAudit
	If SetupMode = ""
		Or SetupMode = "SimpleSetup" And AccountingAuditSubsystemData
		Or SetupMode = "AdvancedSetup" And AccountingCheckRules Then
		
		ShouldUpdate = True;
		ParametersOfUpdate.AccountingAudit.AccountingCheckRules.ShouldUpdate = True;
	EndIf;
	
	If Not ShouldUpdate Then
		Return;
	EndIf;
	
	// ACC:1443-off - No.644.3.5. It's acceptable to access the metadata object as
	// the call is intended specifically for this developer tool.
	InformationRegisters.ExtensionVersionParameters.ExecuteUpdateSplitDataInBackground(
		ParametersOfUpdate, UUID);
	// ACC:1443-on
	
	// StandardSubsystems Core
	If ParametersOfUpdate.Core.ExtensionObjectIDs.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("CoreSubsystemData, ExtensionObjectIDs");
	EndIf;
	
	If ParametersOfUpdate.AttachableCommands.ConnectableExtensionCommands.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("CoreSubsystemData, ProgramInterfaceCache");
	EndIf;
	
	// StandardSubsystems Users
	If ParametersOfUpdate.Users.UserGroupsHierarchy.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("UsersSubsystemData, UserGroupsHierarchy");
	EndIf;
	
	If ParametersOfUpdate.Users.UserGroupCompositions.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("UsersSubsystemData, UserGroupCompositions");
	EndIf;
	
	If ParametersOfUpdate.Users.UsersInfo.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("UsersSubsystemData, UsersInfo");
	EndIf;
	
	// StandardSubsystems AccessManagement
	If ParametersOfUpdate.AccessManagement.SuppliedAccessGroupProfiles.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("AccessManagementSubsystemData, SuppliedAccessGroupProfiles");
	EndIf;
	
	If ParametersOfUpdate.AccessManagement.UnsuppliedAccessGroupProfiles.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("AccessManagementSubsystemData, UnsuppliedAccessGroupProfiles");
	EndIf;
	
	If ParametersOfUpdate.AccessManagement.InfobaseUsersRoles.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("AccessManagementSubsystemData, InfobaseUsersRoles");
	EndIf;
	
	If ParametersOfUpdate.AccessManagement.AccessRestrictionParameters.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("AccessManagementSubsystemData, AccessRestrictionParameters");
	EndIf;
	
	If ParametersOfUpdate.AccessManagement.AccessGroupsTables.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("AccessManagementSubsystemData, AccessGroupsTables");
	EndIf;
	
	If ParametersOfUpdate.AccessManagement.AccessGroupsValues.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("AccessManagementSubsystemData, AccessGroupsValues");
	EndIf;
	
	If ParametersOfUpdate.AccessManagement.ObjectRightsSettingsInheritance.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("AccessManagementSubsystemData, ObjectRightsSettingsInheritance");
	EndIf;
	
	If ParametersOfUpdate.AccessManagement.ObjectsRightsSettings.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("AccessManagementSubsystemData, ObjectsRightsSettings");
	EndIf;
	
	If ParametersOfUpdate.AccessManagement.AccessValuesGroups.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("AccessManagementSubsystemData, AccessValuesGroups");
	EndIf;
	
	If ParametersOfUpdate.AccessManagement.AccessValuesSets.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("AccessManagementSubsystemData, AccessValuesSets");
	EndIf;
	
	// StandardSubsystems ReportsOptions
	If ParametersOfUpdate.ReportsOptions.ConfigurationReports.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("ReportOptionsSubsystemData, ConfigurationReports");
	EndIf;
	
	If ParametersOfUpdate.ReportsOptions.IndexSearchReportsConfiguration.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("ReportOptionsSubsystemData, ReportSearchIndex");
	EndIf;
	
	If ParametersOfUpdate.ReportsOptions.ExtensionReports.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("ReportOptionsSubsystemData, ExtensionReports");
	EndIf;
	
	If ParametersOfUpdate.ReportsOptions.IndexSearchReportsExtensions.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("ReportOptionsSubsystemData, ReportSearchIndex");
	EndIf;
	
	// StandardSubsystems AccountingAudit
	If ParametersOfUpdate.AccountingAudit.AccountingCheckRules.HasChanges Then
		HasOverallChanges = True;
		HighlightChanges("AccountingAuditSubsystemData, AccountingCheckRules");
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateItemAvailability(Form)
	
	Items = Form.Items;
	
	// StandardSubsystems Core
	Items.MetadataObjectIDs.Enabled              = Form.UpdateSharedData;
	Items.ExtensionObjectIDs.Enabled              = Form.UpdateSeparatedData;
	Items.ProgramInterfaceCache.Enabled                     = Form.UpdateSharedData;
	
	// StandardSubsystems Users
	Items.CheckRoleAssignment.Enabled                      = Form.UpdateSharedData;
	Items.UserGroupsHierarchy.Enabled                    = Form.UpdateSeparatedData;
	Items.UserGroupCompositions.Enabled                     = Form.UpdateSeparatedData;
	Items.UsersInfo.Enabled                        = Form.UpdateSeparatedData;
	
	// StandardSubsystems AccessManagement
	Items.RolesRights.Enabled                                    = Form.UpdateSharedData;
	Items.RightsDependencies.Enabled                               = Form.UpdateSharedData;
	Items.AccessKindsProperties.Enabled                          = Form.UpdateSharedData;
	Items.SuppliedAccessGroupProfilesDescription.Enabled      = Form.UpdateSharedData;
	Items.AvailableRightsForObjectsRightSettingsDetails.Enabled = Form.UpdateSharedData;
	Items.SuppliedAccessGroupProfiles.Enabled               = Form.UpdateSeparatedData;
	Items.UnsuppliedAccessGroupProfiles.Enabled             = Form.UpdateSeparatedData;
	Items.InfobaseUsersRoles.Enabled           = Form.UpdateSeparatedData;
	Items.AccessGroupsTables.Enabled                           = Form.UpdateSeparatedData;
	Items.AccessGroupsValues.Enabled                          = Form.UpdateSeparatedData;
	Items.ObjectRightsSettingsInheritance.Enabled              = Form.UpdateSeparatedData;
	Items.ObjectsRightsSettings.Enabled                         = Form.UpdateSeparatedData;
	Items.AccessValuesGroups.Enabled                         = Form.UpdateSeparatedData;
	Items.AccessValuesSets.Enabled                         = Form.UpdateSeparatedData;
	Items.AccessRestrictionParameters.Enabled                   = Form.UpdateSeparatedData;
	
	// StandardSubsystems ReportsOptions
	Items.ConfigurationReports.Enabled  = Form.UpdateSharedData Or Form.UpdateSeparatedData;
	Items.ExtensionReports.Enabled    = Form.UpdateSharedData Or Form.UpdateSeparatedData;
	Items.ReportSearchIndex.Enabled = Form.UpdateSeparatedData;
	
	// StandardSubsystems InformationOnStart
	Items.InformationPackagesOnStart.Enabled = Form.UpdateSharedData;
	
	// StandardSubsystems AccountingAudit
	Items.AccountingCheckRules.Enabled = True;
	
EndProcedure

&AtServer
Procedure UpdateVisibilityBySetupMode()
	
	UpdateCurrentDataArea1();
	
	If SetupMode = "SimpleSetup" Then
		Items.SimpleSetup.Visible = True;
		Items.AdvancedSetup.Visible = False;
		Items.CheckAll.Visible = True;
		Items.UncheckAll.Visible = True;
		
	ElsIf SetupMode = "AdvancedSetup" Then
		Items.SimpleSetup.Visible = False;
		Items.AdvancedSetup.Visible = True;
		Items.CheckAll.Visible = True;
		Items.UncheckAll.Visible = True;
		
	Else // No setting.
		Items.SimpleSetup.Visible = False;
		Items.AdvancedSetup.Visible = False;
		Items.CheckAll.Visible = False;
		Items.UncheckAll.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure HighlightChanges(ItemsNames, HasChanges = True)
	
	ChangeColor = Metadata.StyleItems.HyperlinkColor.Value;
	NormalColor   = Items.DataArea.TitleTextColor; // Auto.
	
	DescriptionOfElements = New Structure(ItemsNames);
	For Each ItemDetails In DescriptionOfElements Do
		Items[ItemDetails.Key].TitleTextColor = ?(HasChanges, ChangeColor, NormalColor);
	EndDo;
	
EndProcedure

&AtServer
Function UpdateCurrentDataArea1()
	
	If Not Common.DataSeparationEnabled()
	 Or Not UpdateSharedData Then
		
		Return False;
	EndIf;
	
	SessionSeparatorValue = Undefined;
	
	If Common.SeparatedDataUsageAvailable() Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		SessionSeparatorValue = ModuleSaaSOperations.SessionSeparatorValue();
	EndIf;
	
	CurrentDataAreaChanged = CurrentDataArea <> SessionSeparatorValue;
	
	If CurrentDataAreaChanged Then
		CurrentDataArea = SessionSeparatorValue;
	EndIf;
	
	If CurrentDataArea = Undefined Then
		UpdateSeparatedData = False;
	Else
		UpdateSeparatedData = True;
	EndIf;
	
	UpdateItemAvailability(ThisObject);
	
	Return CurrentDataAreaChanged;
	
EndFunction

&AtServerNoContext
Procedure SignInToDataArea(Val DataArea)
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		ModuleSaaSOperations.SignInToDataArea(DataArea);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure SignOutOfDataArea()
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		ModuleSaaSOperations.SignOutOfDataArea();
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Copied from CommonForm.SignInToDataArea.

&AtClient
Procedure SignInToDataAreaClient()
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		Return;
	EndIf;
	
	If Not SpecifiedDataAreaIsFilled(DataArea) Then
		ShowQueryBox(
			New NotifyDescription("SignInToDataAreaCompletion", ThisObject),
			NStr("ru = 'Выбранная область данных не заполнена, продолжить вход?';
				|en = 'The selected data area is empty. Do you want to log in to the data area?';"),
			QuestionDialogMode.YesNo,
			,
			DialogReturnCode.No);
	Else
		SignInToDataAreaCompletion(Undefined, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure SignInToDataAreaCompletion(Response, Context) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	EnterDataAreaOnServer(DataArea);
	RefreshInterface();
	
	CompletionProcessing = New NotifyDescription(
		"ContinuingToEnterDataAreaAfterActionsBeforeStartingSystem", ThisObject);
	StandardSubsystemsClient.BeforeStart(CompletionProcessing);
	
EndProcedure

&AtClient
Procedure ContinuingToEnterDataAreaAfterActionsBeforeStartingSystem(Result, Context) Export
	
	If Result.Cancel Then
		ExitDataAreaOnServer();
		RefreshInterface();
		Return;
	EndIf;
	
	CompletionProcessing = New NotifyDescription(
		"ContinuingToEnterDataAreaAfterActionsAtStartOfSystem", ThisObject);
	
	StandardSubsystemsClient.OnStart(CompletionProcessing);
	
EndProcedure

&AtClient
Procedure ContinuingToEnterDataAreaAfterActionsAtStartOfSystem(Result, Context) Export
	
	If Result.Cancel Then
		ExitDataAreaOnServer();
		RefreshInterface();
	EndIf;
	
	Activate();
	
EndProcedure

&AtClient
Procedure SignOutOfDataAreaClient()
	
	ExitDataAreaOnServer();
	RefreshInterface();
	StandardSubsystemsClient.SetAdvancedApplicationCaption(True);
	
EndProcedure

&AtServerNoContext
Function SpecifiedDataAreaIsFilled(Val DataArea)
	
	DataAreaRegister = StrReplace("InformationRegister.%1", "%1", "DataAreas");
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DataAreas.Status AS Status
	|FROM
	|	#DataArea AS DataAreas
	|WHERE
	|	DataAreas.DataAreaAuxiliaryData = &DataArea";
	Query.Text = StrReplace(Query.Text, "#DataArea", DataAreaRegister);
	Query.SetParameter("DataArea", DataArea);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Selection.Status = Enums["DataAreaStatuses"].Used;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtServerNoContext
Procedure EnterDataAreaOnServer(Val DataArea)
	
	SetPrivilegedMode(True);
	SignInToDataArea(DataArea);
	
	BeginTransaction();
	
	Try
		AreaKey = InformationRegisters["DataAreas"].CreateRecordKey(
			New Structure("DataAreaAuxiliaryData", DataArea));
		
		LockDataForEdit(AreaKey);
		
		DataAreaRegister = StrReplace("InformationRegister.%1", "%1", "DataAreas");
		Block = New DataLock;
		Item = Block.Add(DataAreaRegister);
		Item.SetValue("DataAreaAuxiliaryData", DataArea);
		Block.Lock();
		
		RecordManager = InformationRegisters["DataAreas"].CreateRecordManager();
		RecordManager.DataAreaAuxiliaryData = DataArea;
		RecordManager.Read();
		If Not RecordManager.Selected() Then
			EnumerationName = "DataAreaStatuses";
			RecordManager.DataAreaAuxiliaryData = DataArea;
			RecordManager.Status = Enums[EnumerationName].Used;
			RecordManager.Write();
		EndIf;
		UnlockDataForEdit(AreaKey);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtServerNoContext
Procedure ExitDataAreaOnServer()
	
	SetPrivilegedMode(True);
	SignOutOfDataArea();
	
EndProcedure

&AtClientAtServerNoContext
Procedure EditCheckboxes(Form, NewValue = False, SimpleSetup = Undefined)
	
	If SimpleSetup = Undefined Then
		If Not ValueIsFilled(Form.SetupMode) Then
			Return;
		EndIf;
		SimpleSetup = Form.SetupMode = "SimpleSetup";
	EndIf;
	
	If SimpleSetup Then
		Form.CoreSubsystemData = NewValue;
		Form.UsersSubsystemData = NewValue;
		Form.AccessManagementSubsystemData = NewValue;
		Form.ReportOptionsSubsystemData = NewValue;
		Form.InformationOnStartSubsystemData = NewValue;
		Form.AccountingAuditSubsystemData = NewValue;
	Else
		// StandardSubsystems Core
		Form.MetadataObjectIDs = NewValue;
		Form.ExtensionObjectIDs = NewValue;
		Form.ProgramInterfaceCache = NewValue;
		
		// StandardSubsystems Users
		Form.CheckRoleAssignment = NewValue;
		Form.UserGroupsHierarchy = NewValue;
		Form.UserGroupCompositions = NewValue;
		Form.UsersInfo = NewValue;
		
		// StandardSubsystems AccessManagement
		Form.RolesRights = NewValue;
		Form.RightsDependencies = NewValue;
		Form.AccessKindsProperties = NewValue;
		Form.SuppliedAccessGroupProfilesDescription = NewValue;
		Form.AvailableRightsForObjectsRightSettingsDetails = NewValue;
		Form.SuppliedAccessGroupProfiles = NewValue;
		Form.UnsuppliedAccessGroupProfiles = NewValue;
		Form.InfobaseUsersRoles = NewValue;
		Form.AccessRestrictionParameters = NewValue;
		Form.AccessGroupsTables = NewValue;
		Form.AccessGroupsValues = NewValue;
		Form.ObjectRightsSettingsInheritance = NewValue;
		Form.ObjectsRightsSettings = NewValue;
		Form.AccessValuesGroups = NewValue;
		Form.AccessValuesSets = NewValue;
		
		// StandardSubsystems ReportsOptions
		Form.ConfigurationReports  = NewValue;
		Form.ExtensionReports    = NewValue;
		Form.ReportSearchIndex = NewValue;
		
		// StandardSubsystems InformationOnStart
		Form.InformationPackagesOnStart = NewValue;
		
		// StandardSubsystems AccountingAudit
		Form.AccountingCheckRules = NewValue;
	EndIf;
	
EndProcedure

&AtServer
Procedure AssignCurrentUserWithRoleOpenAdditionalReportsAndDataProcessorsInteractively()
	
	CurrentUserUniqueIdentifier = InfoBaseUsers.CurrentUser().UUID;
	CurrentUser = InfoBaseUsers.FindByUUID(CurrentUserUniqueIdentifier);
	If CurrentUser = Undefined Then
		Return;
	EndIf;
	
	RoleOpenExternalReportsAndDataProcessorsInteractively = Metadata.Roles.InteractiveOpenExtReportsAndDataProcessors;
	If CurrentUser.Roles.Contains(RoleOpenExternalReportsAndDataProcessorsInteractively) Then
		Return;
	EndIf;
	
	CurrentUser.Roles.Add(RoleOpenExternalReportsAndDataProcessorsInteractively);
	CurrentUser.Write();
	
EndProcedure

&AtClient
Procedure WriteUpdateErrorToFile(FullFileName, ErrorText)
#If Not WebClient Then
	
	If IsBlankString(FullFileName) Then
		Return;
	EndIf;
	// ACC:566-off - A development tool
	TextWriter = New TextWriter(FullFileName);
	TextWriter.WriteLine(ErrorText);
	TextWriter.Close();
	// ACC:566-on
	
#EndIf
EndProcedure

#EndRegion