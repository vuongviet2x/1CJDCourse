///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Users.CommonAuthorizationSettingsUsed() Then
		Items.UsersAuthorizationSettingsGroup.Visible = False;
		Items.GroupExternalUsers.Group
			= ChildFormItemsGroup.AlwaysHorizontal;
	EndIf;
	
	If Common.DataSeparationEnabled()
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion()
	 Or Common.IsStandaloneWorkplace()
	 Or Not UsersInternal.ExternalUsersEmbedded() Then
	
		Items.GroupExternalUsers.Visible = False;
		Items.SectionDetails.Title =
			NStr("ru = 'Администрирование пользователей, настройка групп доступа, управление пользовательскими настройками.';
				|en = 'Manage users, configure access groups, grant access to external users, and manage user settings.';");
	EndIf;
	
	If StandardSubsystemsServer.IsBaseConfigurationVersion()
	 Or Common.IsSubordinateDIBNode() Then
		
		Items.UseUserGroups.Enabled = False;
		Items.UseExternalUsers.Enabled = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		SimplifiedInterface = ModuleAccessManagementInternal.SimplifiedAccessRightsSetupInterface();
		Items.OpenAccessGroups.Visible            = Not SimplifiedInterface;
		Items.UseUserGroups.Visible = Not SimplifiedInterface;
		Items.LimitAccessAtRecordLevelUniversally.Visible
			= ModuleAccessManagementInternal.ScriptVariantRussian()
				And Users.IsFullUser();
		Items.AccessUpdateOnRecordsLevel.Visible =
			ModuleAccessManagementInternal.LimitAccessAtRecordLevelUniversally(True);
		
		If Common.IsSubordinateDIBNode() Then
			Items.LimitAccessAtRecordLevel.Enabled = False;
			Items.LimitAccessAtRecordLevelUniversally.Enabled = False;
		EndIf;
		IsAccessRightsChangeLoggingSupported =
			ModuleAccessManagementInternal.IsAccessRightsChangeLoggingSupported();
	Else
		Items.AccessGroupsGroup.Visible = False;
		IsAccessRightsChangeLoggingSupported = False;
	EndIf;
	
	If Not IsAccessRightsChangeLoggingSupported
	   And Items.Find("ShouldRegisterChangesInAccessRights") <> Undefined Then
		
		Items.ShouldRegisterChangesInAccessRights.Title =
			NStr("ru = 'Регистрировать изменения участников групп пользователей';
				|en = 'Log changes in user group membership';");
		Items.ShouldRegisterChangesInAccessRights.ExtendedTooltip.Title =
			NStr("ru = 'Запись дополнительных событий в журнал регистрации при изменении участников групп пользователей.';
				|en = 'Logging events of changes in user group membership.';");
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		Items.PeriodClosingDatesGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PersonalDataProtection") Then
		Items.GroupPersonalDataAccessEventRegistrationSettings.Visible =
			  Not Common.DataSeparationEnabled()
			And Users.IsFullUser(, True);
	Else
		Items.PersonalDataProtectionGroup.Visible = False;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions")
	 Or Metadata.Subsystems.Find("Administration") = Undefined Then
		Items.UserMonitoring.Visible = False;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.UserMonitoring") Then
		Items.GroupDataAccessAudit.Visible = False;
		If Items.Find("ShouldRegisterChangesInAccessRights") <> Undefined Then
			Items.ShouldRegisterChangesInAccessRights.Visible = False;
		EndIf;
		Items.GroupUserMonitoringLeftColumnVerticalIndent.Visible = True;
		
	ElsIf Common.DataSeparationEnabled()
	      Or Not Users.IsFullUser(, True) Then
		
		Items.GroupDataAccessManagementSettings.Visible = False;
	Else
		ModuleUserMonitoring = Common.CommonModule("UserMonitoring");
		ShouldRegisterDataAccess = ModuleUserMonitoring.ShouldRegisterDataAccess();
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Items.PasswordsRecovery.Visible = False;
	EndIf;
	
	// Update items states.
	SetAvailability();
	
	ApplicationSettingsOverridable.UsersAndRightsSettingsOnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	RefreshApplicationInterface();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName <> "Write_ConstantsSet" Then
		Return;
	EndIf;
	
	If Source = "UseSurvey" 
		And CommonClient.SubsystemExists("StandardSubsystems.Surveys") Then
		
		Read();
		SetAvailability();
		
	ElsIf Source = "UseHidePersonalDataOfSubjects" Then
		Read();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseUserGroupsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ShouldRegisterChangesInAccessRightsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseExternalUsersOnChange(Item)
	
	If ConstantsSet.UseExternalUsers Then
		
		QueryText =
			NStr("ru = 'Разрешить доступ внешним пользователям?
			           |
			           |При входе в приложение список выбора пользователей станет пустым
			           |(реквизит ""Показывать в списке выбора"" в карточках всех
			           | пользователей будет очищен и скрыт).';
						|en = 'Do you want to allow external user access?
						|
						|The user list in the startup dialog will be cleared
						|(attribute ""Show in choice list"" will be cleared and hidden from all user profiles).
						|';");
		
		ShowQueryBox(
			New NotifyDescription(
				"UseExternalUsersOnChangeCompletion",
				ThisObject,
				Item),
			QueryText,
			QuestionDialogMode.YesNo);
	Else
		QueryText =
			NStr("ru = 'Запретить доступ внешним пользователям?
			           |
			           |Реквизит ""Вход в приложение разрешен"" будет
			           |очищен в карточках всех внешних пользователей.';
						|en = 'Do you want to deny external user access?
						|
						|Attribute ""Login allowed"" will be cleared
						|in all external user cards.';");
		
		ShowQueryBox(
			New NotifyDescription(
				"UseExternalUsersOnChangeCompletion",
				ThisObject,
				Item),
			QueryText,
			QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure LimitAccessAtRecordLevelUniversallyOnChange(Item)
	
	If ConstantsSet.LimitAccessAtRecordLevelUniversally Then
		QueryText =
			NStr("ru = 'Включить производительный вариант ограничения доступа?
			           |
			           |Включение займет некоторое время для перезаполнения настроек прав в приложении,
			           |см. ход выполнения по ссылке ""Обновление доступа на уровне записей"".';
						|en = 'Do you want to enable the high-performance access restriction mode?
						|
						|The update of the right settings will take some time.
						|To monitor the progress, click ""RLS access update progress"".';");
	Else
		QueryText =
			NStr("ru = 'Выключить производительный вариант ограничения доступа?
			           |
			           |Включение займет некоторое время для перезаполнения настроек прав в приложении,
			           |см. ход выполнения регламентного задания ""Заполнение данных для ограничения доступа"" в журнале регистрации.';
						|en = 'Do you want to disable the high-performance access restriction mode?
						|
						|The update of the right settings will take some time.
						|To monitor the progress, click ""RLS access update progress"".';");
	EndIf;
	
	If ValueIsFilled(QueryText) Then
		ShowQueryBox(
			New NotifyDescription(
				"LimitAccessAtRecordLevelUniversallyOnChangeCompletion",
				ThisObject, Item),
			QueryText, QuestionDialogMode.YesNo);
	Else
		LimitAccessAtRecordLevelUniversallyOnChangeCompletion(DialogReturnCode.Yes, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure LimitAccessAtRecordLevelOnChange(Item)
	
	If ConstantsSet.LimitAccessAtRecordLevelUniversally Then
		QueryText =
			NStr("ru = 'Настройки групп доступа вступят в силу через некоторое время,
			           |см. ход выполнения по ссылке ""Обновление доступа на уровне записей"".
			           |
			           |Заполнение настроек прав доступа может временно замедлить работу приложения 
			           |и занять от нескольких секунд до часов (в зависимости от объема данных).';
						|en = 'Access group settings will take effect in a while.
						|To monitor the progress, click ""RLS access update progress"".
						|
						|This might slow down the app and take
						|from seconds to a few hours, depending on the data volume.';");
		If ConstantsSet.LimitAccessAtRecordLevel Then
			QueryText = NStr("ru = 'Включить ограничение доступа на уровне записей?';
								|en = 'Do you want to enable record-level access restrictions?';")
				+ Chars.LF + Chars.LF + QueryText;
		Else
			QueryText = NStr("ru = 'Выключить ограничение доступа на уровне записей?';
								|en = 'Do you want to disable record-level access restrictions?';")
				+ Chars.LF + Chars.LF + QueryText;
		EndIf;
		
	ElsIf ConstantsSet.LimitAccessAtRecordLevel Then
		QueryText =
			NStr("ru = 'Включить ограничение доступа на уровне записей?
			           |
			           |Заполнение настроек прав доступа может временно замедлить работу приложения 
			           |и занять от нескольких секунд до часов (в зависимости от объема данных).
			           |См. ход выполнения регламентного задания ""Заполнение данных для ограничения доступа"" в журнале регистрации.';
						|en = 'Do you want to enable RLS restriction?
						|
						|This might slow down the app and take
						|from seconds to a few hours, depending on the data volume.
						|To monitor the progress, see ""Populate data for access restriction"" in the event log.';");
	Else
		QueryText = "";
	EndIf;
	
	If ValueIsFilled(QueryText) Then
		ShowQueryBox(
			New NotifyDescription(
				"LimitAccessAtRecordLevelOnChangeCompletion",
				ThisObject, Item),
			QueryText, QuestionDialogMode.YesNo);
	Else
		LimitAccessAtRecordLevelOnChangeCompletion(DialogReturnCode.Yes, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure ShouldRegisterDataAccessOnChange(Item)
	RegisterDataAccessOnChangeAtServer(ShouldRegisterDataAccess);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CatalogExternalUsers(Command)
	OpenForm("Catalog.ExternalUsers.ListForm", , ThisObject);
EndProcedure

&AtClient
Procedure UserMonitoring(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsOptionsClient = CommonClient.CommonModule("ReportsOptionsClient");
		ModuleReportsOptionsClient.ShowReportBar("Administration", Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure AccessUpdateOnRecordsLevel(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternalClient = CommonClient.CommonModule("AccessManagementInternalClient");
		ModuleAccessManagementInternalClient.OpenAccessUpdateOnRecordsLevelForm(True, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigurePeriodClosingDates(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		ModulePeriodClosingDatesInternalClient = CommonClient.CommonModule("PeriodClosingDatesInternalClient");
		ModulePeriodClosingDatesInternalClient.OpenPeriodEndClosingDates(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Client.

&AtClient
Procedure Attachable_OnChangeAttribute(Item, ShouldRefreshInterface = True)
	
	ConstantsNames = OnChangeAttributeServer(Item.Name);
	RefreshReusableValues();
	
	If ShouldRefreshInterface Then
		RefreshInterface = True;
		AttachIdleHandler("RefreshApplicationInterface", 2, True);
	EndIf;
	
	For Each ConstantName In ConstantsNames Do
		If ConstantName <> "" Then
			Notify("Write_ConstantsSet", New Structure, ConstantName);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_PDDestructionSettingsOnChange(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.PersonalDataProtection") Then
		ModulePersonalDataProtectionClient = CommonClient.CommonModule("PersonalDataProtectionClient");
		ModulePersonalDataProtectionClient.SettingsForDestructionOfPersonalDataWhenChanging(ThisObject);
	EndIf;

	RefreshInterface = True;
	AttachIdleHandler("RefreshApplicationInterface", 2, True);

EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtClient
Procedure LimitAccessAtRecordLevelUniversallyOnChangeCompletion(Response, Item) Export
	
	If Response = DialogReturnCode.No Then
		ConstantsSet.LimitAccessAtRecordLevelUniversally
			= Not ConstantsSet.LimitAccessAtRecordLevelUniversally;
		Return;
	EndIf;
	
	Attachable_OnChangeAttribute(Item);
	
	Items.AccessUpdateOnRecordsLevel.Visible =
		ConstantsSet.LimitAccessAtRecordLevelUniversally;
	
EndProcedure

&AtClient
Procedure LimitAccessAtRecordLevelOnChangeCompletion(Response, Item) Export
	
	If Response = DialogReturnCode.No Then
		ConstantsSet.LimitAccessAtRecordLevel = Not ConstantsSet.LimitAccessAtRecordLevel;
		Return;
	EndIf;
	
	Attachable_OnChangeAttribute(Item);
	
	If Not ConstantsSet.LimitAccessAtRecordLevel Then
		// _Demo Example Start
		If ConstantsSet._DemoRestrictAccessByPartners Then
			ConstantsSet._DemoRestrictAccessByPartners = False;
			Attachable_OnChangeAttribute(Items._DemoRestrictAccessByPartners);
		EndIf;
		If ConstantsSet._DemoRestrictAccessByProducts Then
			ConstantsSet._DemoRestrictAccessByProducts = False;
			Attachable_OnChangeAttribute(Items._DemoRestrictAccessByProducts);
		EndIf;
		If ConstantsSet._DemoRestrictAccessByIndividuals Then
			ConstantsSet._DemoRestrictAccessByIndividuals = False;
			Attachable_OnChangeAttribute(Items._DemoRestrictAccessByIndividuals);
		EndIf;
		// _Demo Example End
	EndIf;
	
EndProcedure

&AtClient
Procedure UseExternalUsersOnChangeCompletion(Response, Item) Export
	
	If Response = DialogReturnCode.No Then
		ConstantsSet.UseExternalUsers = Not ConstantsSet.UseExternalUsers;
	Else
		Attachable_OnChangeAttribute(Item);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server call.

&AtServer
Function OnChangeAttributeServer(TagName)
	
	ConstantsNames = New Array;
	DataPathAttribute = Items[TagName].DataPath;
	
	BeginTransaction();
	Try
		// _Demo Example Start
		If ConstantsSet.LimitAccessAtRecordLevel
			And ConstantsSet.UseExternalUsers
			And Not ConstantsSet._DemoRestrictAccessByPartners
			And Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
			// Installing a dependent setting.
			ConstantsSet._DemoRestrictAccessByPartners = True;
			ConstantName = SaveAttributeValue(Items._DemoRestrictAccessByPartners.DataPath);
			ConstantsNames.Add(ConstantName);
		EndIf;
		// _Demo Example End
		ConstantName = SaveAttributeValue(DataPathAttribute);
		ConstantsNames.Add(ConstantName);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	SetAvailability(DataPathAttribute);
	RefreshReusableValues();
	Return ConstantsNames;
	
EndFunction

&AtServerNoContext
Procedure RegisterDataAccessOnChangeAtServer(Val ShouldRegisterDataAccess)
	
	If Not Common.SubsystemExists("StandardSubsystems.UserMonitoring") Then
		Return;
	EndIf;
	
	ModuleUserMonitoring = Common.CommonModule("UserMonitoring");
	ModuleUserMonitoring.SetDataAccessRegistration(ShouldRegisterDataAccess);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server.

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		Return "";
	EndIf;
	
	ConstantName = NameParts[1];
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	CurrentValue  = ConstantManager.Get();
	If CurrentValue <> ConstantValue Then
		Try
			ConstantManager.Set(ConstantValue);
		Except
			ConstantsSet[ConstantName] = CurrentValue;
			Raise;
		EndTry;
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If DataPathAttribute = "ConstantsSet.UseExternalUsers"
	 Or DataPathAttribute = "" Then
		
		Items.OpenExternalUsers.Enabled = ConstantsSet.UseExternalUsers;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PeriodClosingDates")
		And (DataPathAttribute = "ConstantsSet.UsePeriodClosingDates"
		Or DataPathAttribute = "") Then
		
		Items.ConfigurePeriodClosingDates.Enabled = ConstantsSet.UsePeriodClosingDates;
	EndIf;
	
	// _Demo Example Start
	If DataPathAttribute = "ConstantsSet.LimitAccessAtRecordLevel" Or DataPathAttribute = "" Then
		HasAvailability = ConstantsSet.LimitAccessAtRecordLevel
			And Not Common.IsStandaloneWorkplace();
		Items._DemoRestrictAccessByProducts.Enabled    = HasAvailability;
		Items._DemoRestrictAccessByIndividuals.Enabled = HasAvailability;
	EndIf;
	If DataPathAttribute = "ConstantsSet._DemoRestrictAccessByPartners" Or DataPathAttribute = "" Then
		Items._DemoOpenPartnersAccessGroups.Enabled = ConstantsSet._DemoRestrictAccessByPartners;
	EndIf;
	If DataPathAttribute = "ConstantsSet._DemoRestrictAccessByProducts" Or DataPathAttribute = "" Then
		Items._DemoOpenProductsAccessGroups.Enabled = ConstantsSet._DemoRestrictAccessByProducts;
	EndIf;
	If DataPathAttribute = "ConstantsSet.LimitAccessAtRecordLevel"
	 Or DataPathAttribute = "ConstantsSet._DemoRestrictAccessByPartners"
	 Or DataPathAttribute = "ConstantsSet.UseExternalUsers"
	 Or DataPathAttribute = "" Then
		Items._DemoRestrictAccessByPartners.Enabled =
			  ConstantsSet.LimitAccessAtRecordLevel
			And Not ConstantsSet.UseExternalUsers
			And Not Common.IsStandaloneWorkplace();
		Items._DemoRestrictAccessByPartnersWarning.Visible =
			ConstantsSet.LimitAccessAtRecordLevel
			And ConstantsSet.UseExternalUsers;
	EndIf;
	// _Demo Example End
	
EndProcedure

#EndRegion
