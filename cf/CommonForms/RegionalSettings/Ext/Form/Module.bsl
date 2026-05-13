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
Var PreviousLanguage;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Source = Parameters.Source;
	If Source = "SSLAdministrationPanel" Then
		Items.OK.Title = NStr("ru = 'Изменить';
									|en = 'OK';");
		Items.OK.ToolTipRepresentation = ToolTipRepresentation.None;
		Items.ApplicationTimeZoneGroup.Visible = False;
		Title = NStr("ru = 'Языки ведения учета';
						|en = 'Accounting languages';");
		AutoTitle = False;
	EndIf;
	 
	FillInTimeZones();
	
	If Common.SeparatedDataUsageAvailable() Then
	
		FileInfobase = Common.FileInfobase();
		
		AppTimeZone = GetInfoBaseTimeZone();
		If IsBlankString(AppTimeZone) Then
			AppTimeZone = TimeZone();
		EndIf;
		
		If Common.DataSeparationEnabled() Then
			Items.MainLanguageGroup.Visible = False;
			Items.AdditionalLanguagesGroup.Visible = False;
		EndIf;
		
	Else
		
		AppTimeZone = SessionTimeZone();
		
	EndIf;
	
	SetMainLanguage();
	
	Settings = New Structure;
	Settings.Insert("AdditionalLanguageCode1", "");
	Settings.Insert("AdditionalLanguageCode2", "");
	Settings.Insert("MultilanguageData",      True);
	
	NationalLanguageSupportOverridable.OnDefineSettings(Settings);
	
	LanguagesCount = Metadata.Languages.Count();
	If Not Settings.MultilanguageData Or LanguagesCount = 1 Then
		Items.AdditionalLanguagesGroup.Visible = False;
		Items.MainLanguageGroup.Visible        = False;
	Else
		If LanguagesCount = 2 Then
			Items.AdditionalLanguage2Group.Visible = False;
		EndIf;
		DisplayAdditionalLanguagesSettings(Settings, LanguagesCount);
	EndIf;
	
	DataToChangeMultilanguageAttributes = NationalLanguageSupportServer.DataToChangeMultilanguageAttributes();
	If DataToChangeMultilanguageAttributes <> Undefined Then
		If Not DataToChangeMultilanguageAttributes.MainLanguageChanged And Common.IsMainLanguage() Then
			WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		EndIf;
		ContinueChangingMultilingualDetails = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ContinueChangingMultilingualDetails Then
		RefillData();
		Return;
	EndIf;
	
	If FileInfobase
		And StrFind(LaunchParameter, "UpdateAndExit") > 0 Then
			AttachIdleHandler("WriteConstantsValuesAndClose", 0.1, True);
	EndIf;
	 
	TimeZoneOffset = CommonClient.SessionDate() - CurrentTimeOnTheClient();
	SetTime();
	
	If StrCompare(Source, "InitialFilling") = 0 Then
		FormClosingTime = CurrentTimeOnTheClient() + 180;
		AttachIdleHandler("AutoCloseInactiveForm", 1, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetMainLanguage()
	
	DefaultLanguage = Constants.DefaultLanguage.Get();
	For Each Language In Metadata.Languages Do
		Items.DefaultLanguage.ChoiceList.Add(Language.LanguageCode, Language.Presentation());
	EndDo;
	
	If IsBlankString(DefaultLanguage) Then
		DefaultLanguage = CurrentLanguage().LanguageCode;
	EndIf;
	
	If IsBlankString(DefaultLanguage) Or Items.DefaultLanguage.ChoiceList.FindByValue(DefaultLanguage) = Undefined Then
		DefaultLanguage = Common.DefaultLanguageCode();
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayAdditionalLanguagesSettings(Settings, LanguagesCount)
	
	AvailableLanguages = New Map;
	For Each ConfigurationLanguage In Metadata.Languages Do
		If StrCompare(DefaultLanguage, ConfigurationLanguage.LanguageCode) = 0  Then
			Continue;
		EndIf;
		AvailableLanguages.Insert(ConfigurationLanguage.LanguageCode, True);
	EndDo;
	
	DefaultLanguage1 = "";
	If ValueIsFilled(Settings.AdditionalLanguageCode1) Then
		If AvailableLanguages.Get(Settings.AdditionalLanguageCode1) = True Then
			DefaultLanguage1 = Settings.AdditionalLanguageCode1;
		EndIf;
	EndIf;
	
	DefaultLanguage2 = "";
	If LanguagesCount > 2 And ValueIsFilled(Settings.AdditionalLanguageCode2) Then
		If AvailableLanguages.Get(Settings.AdditionalLanguageCode2) = True Then
			DefaultLanguage2 = Settings.AdditionalLanguageCode2;
		EndIf;
	EndIf;
	
	For Each Language In Metadata.Languages Do
		If StrCompare(Language.LanguageCode, DefaultLanguage) <> 0 Then
			If IsBlankString(DefaultLanguage1) Then
				DefaultLanguage1 = Language.LanguageCode;
			ElsIf IsBlankString(DefaultLanguage2) And Language.LanguageCode <> DefaultLanguage1 Then
				DefaultLanguage2 = Language.LanguageCode;
			EndIf;
		EndIf;
		Items.AdditionalLanguage1.ChoiceList.Add(Language.LanguageCode, Language.Presentation());
		Items.AdditionalLanguage2.ChoiceList.Add(Language.LanguageCode, Language.Presentation());
	EndDo;
	
	UseAdditionalLanguage1 = NationalLanguageSupportServer.FirstAdditionalLanguageUsed();
	UseAdditionalLanguage2 = NationalLanguageSupportServer.SecondAdditionalLanguageUsed();
	
	AdditionalLanguage1 = NationalLanguageSupportServer.FirstAdditionalInfobaseLanguageCode();
	AdditionalLanguage2 = NationalLanguageSupportServer.SecondAdditionalInfobaseLanguageCode();
	
	Items.AdditionalLanguage1.Enabled = UseAdditionalLanguage1;
	Items.AdditionalLanguage2.Enabled = UseAdditionalLanguage2;
	
	If IsBlankString(AdditionalLanguage1) Then
		AdditionalLanguage1 = DefaultLanguage1;
	EndIf;
	
	If LanguagesCount > 2 And IsBlankString(AdditionalLanguage2) Then
		AdditionalLanguage2 = DefaultLanguage2;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseAdditionalLanguage1OnChange(Item)
	Items.AdditionalLanguage1.Enabled = UseAdditionalLanguage1;
	DataChanged = True;
EndProcedure

&AtClient
Procedure UseAdditionalLanguage2OnChange(Item)
	Items.AdditionalLanguage2.Enabled = UseAdditionalLanguage2;
	DataChanged = True;
EndProcedure

&AtClient
Procedure DefaultLanguageOnChange(Item)
	
	If StrCompare(PreviousLanguage, DefaultLanguage) <> 0 Then
		If StrCompare(AdditionalLanguage1, DefaultLanguage) = 0 Then
			AdditionalLanguage1 = PreviousLanguage;
		ElsIf StrCompare(AdditionalLanguage2, DefaultLanguage) = 0 Then
			AdditionalLanguage2 = PreviousLanguage;
		EndIf;
	EndIf;
	
	DataChanged = True;
	
EndProcedure

&AtClient
Procedure DefaultLanguageStartChoice(Item, ChoiceData, StandardProcessing)
	PreviousLanguage = DefaultLanguage;
EndProcedure

&AtClient
Procedure AdditionalLanguage1OnChange(Item)
	
	If StrCompare(PreviousLanguage, AdditionalLanguage1) <> 0 Then
		If StrCompare(AdditionalLanguage1, DefaultLanguage) = 0 Then
			DefaultLanguage = PreviousLanguage;
		ElsIf StrCompare(AdditionalLanguage1, AdditionalLanguage2) = 0 Then
			AdditionalLanguage2 = PreviousLanguage;
		EndIf;
	EndIf;
	
	DataChanged = True;
	
EndProcedure

&AtClient
Procedure AdditionalLanguage2OnChange(Item)
	
	If StrCompare(PreviousLanguage, AdditionalLanguage2) <> 0 Then
		If StrCompare(AdditionalLanguage2, AdditionalLanguage1) = 0 Then
			AdditionalLanguage1 = PreviousLanguage;
		ElsIf StrCompare(AdditionalLanguage2, DefaultLanguage) = 0 Then
			DefaultLanguage = PreviousLanguage;
		EndIf;
	EndIf;
	
	DataChanged = True;
	
EndProcedure

&AtClient
Procedure AdditionalLanguage2StartChoice(Item, ChoiceData, StandardProcessing)
	PreviousLanguage = AdditionalLanguage2;
EndProcedure

&AtClient
Procedure AdditionalLanguage1StartChoice(Item, ChoiceData, StandardProcessing)
	PreviousLanguage = AdditionalLanguage1;
EndProcedure

&AtClient
Procedure AppTimeZoneOnChange(Item)
	TimeZoneOffset = TimeZoneOffset(AppTimeZone, CurrentTimeOnTheClient());
	DataChanged = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If DataCorrect() Then
		
		If Source = "SSLAdministrationPanel" And ConstantsValuesChanged() Then
			RefillData();
		Else
			WriteConstantsValuesAndClose();
		EndIf;
		
	Else
		ShowMessageBox(Undefined, NStr("ru = 'Указаны некорректные значения региональных настроек';
													|en = 'Invalid regional settings.';"));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AutoCloseInactiveForm()
	
	If DataChanged Then
		Items.OK.Title = NStr("ru = 'ОК';
									|en = 'OK';");
		Return;
	EndIf;
	
	If FormClosingTime < CurrentTimeOnTheClient() Then
		
		WriteConstantsValuesAndClose();
		Items.OK.Title = NStr("ru = 'ОК';
									|en = 'OK';");
		Return;
		
	EndIf;
	
	SecondsBeforeCloseForm = FormClosingTime - CurrentTimeOnTheClient();
	Seconds = SecondsBeforeCloseForm % 60;
	Minutes1 = (SecondsBeforeCloseForm - Seconds) / 60;
	MinutesAndSeconds = ?(Minutes1 > 1, String(Minutes1) + ":" + String(Seconds), String(Seconds));

	Items.OK.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'ОК (%1)';
			|en = 'OK (%1)';"), MinutesAndSeconds);
		
	AttachIdleHandler("AutoCloseInactiveForm", 1, True);
	
EndProcedure

&AtClient
Procedure WriteConstantsValuesAndClose()
	
	WriteConstantsValues();
	Close(New Structure("Cancel", False));
	
EndProcedure

&AtClient
Procedure RefillData()
	
	ClearMessages();
	
	Items.Pages.CurrentPage = Items.Waiting;
	Items.OK.Enabled = False;
	
	ExecutionProgressNotification = New NotifyDescription("ExecutionProgress", ThisObject);
	
	TimeConsumingOperation = StartBackgroundRefillingAtServer(UUID);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow           = False;
	WaitSettings.ExecutionProgressNotification = ExecutionProgressNotification;
	
	Handler = New NotifyDescription("AfterRefillInBackground", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, Handler, WaitSettings);
	
EndProcedure

&AtServer
Function StartBackgroundRefillingAtServer(Val Var_UUID)
	
	If Not ContinueChangingMultilingualDetails Then
		MetadataListToProcess = PrepareListMetadataForProcessing(OldAndNewValuesOfConstants());
		WriteConstantsValues(MetadataListToProcess);
	EndIf;

	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(Var_UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("ru = 'Перезаполнение строк предопределенных элементов и классификаторов.';
			|en = 'Refill predefined items and classifiers.';");
	ExecutionParameters.RefinementErrors =
		NStr("ru = 'Не удалось перезаполнить строки предопределенных элементов и классификаторов по причине:';
			|en = 'Cannot refill predefined items and classifiers due to:';");
	
	Return TimeConsumingOperations.ExecuteInBackground("NationalLanguageSupportServer.ChangeLanguageinMultilingualDetailsConfig",
		New Structure, ExecutionParameters);
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.LongRunningOperationNewState
//  AdditionalParameters - Undefined
//
&AtClient
Procedure ExecutionProgress(Result, AdditionalParameters) Export
	
	If Result.Status = "Running"
	   And Result.Progress <> Undefined Then
	
		Progress = Result.Progress.Percent;
		Items.Progress.ToolTip = Result.Progress.Text;
		
	EndIf;
	
EndProcedure

&AtServer
Function PrepareListMetadataForProcessing(OldAndNewValuesOfConstants)
	
	ObjectsWithMultilingualAttributes = NationalLanguageSupportServer.ObjectNamesWithMultilingualAttributes();
	
	CurrentReferencesToObjects = New Map;
	
	For Each ObjectWithMultilingualAttributes In ObjectsWithMultilingualAttributes Do
		
		Settings = New Structure;
		Settings.Insert("ReferenceToLastProcessedObjects", Undefined);
		Settings.Insert("LanguageFields", ObjectWithMultilingualAttributes.Value);
		
		CurrentReferencesToObjects.Insert(ObjectWithMultilingualAttributes.Key, Settings);
	EndDo;
	
	ProcessingSettings = New Structure;
	ProcessingSettings.Insert("SettingsChangesLanguages", OldAndNewValuesOfConstants);
	ProcessingSettings.Insert("Objects", CurrentReferencesToObjects);
	
	Value = New ValueStorage(ProcessingSettings);
	
	Return Value;
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure AfterRefillInBackground(Result, AdditionalParameters) Export
	
	Items.Pages.CurrentPage = Items.RegionalSettings;
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;

	RefreshReusableValues();

	Items.Close.DefaultButton = True;
	Items.OK.Visible              = False;
	Items.Close.Visible         = True;
	CurrentItem                     = Items.Close;
	Items.Pages.CurrentPage = Items.CompletedSuccessfullyText;
	
EndProcedure

&AtClient
Function DataCorrect()
	
	If IsBlankString(DefaultLanguage) Then
		Return False;
	EndIf;
	
	If IsBlankString(AppTimeZone) Then
		Return False;
	EndIf;
	
	LanguagesThatWereSet = New Map;
	LanguagesThatWereSet.Insert(DefaultLanguage, True);
	
	If UseAdditionalLanguage1 Then
		If DefaultLanguage = AdditionalLanguage1 Or AdditionalLanguage1 = AdditionalLanguage2 Then
			Return False;
		EndIf;
	EndIf;
	
	If UseAdditionalLanguage2 Then
		If DefaultLanguage = AdditionalLanguage2 Or AdditionalLanguage1 = AdditionalLanguage2 Then
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Procedure WriteConstantsValues(MetadataListToProcess = Undefined)
	
	If Common.SeparatedDataUsageAvailable() Then
		
		If AppTimeZone <> GetInfoBaseTimeZone() Then
			SetPrivilegedMode(True);
			Try
				SetExclusiveMode(True);
				SetInfoBaseTimeZone(AppTimeZone);
				SetExclusiveMode(False);
			Except
				SetExclusiveMode(False);
				Raise;
			EndTry;
			SetPrivilegedMode(False);
			SetSessionTimeZone(AppTimeZone);
		EndIf;
		
	Else
		
		SetSessionTimeZone(AppTimeZone);
		
	EndIf;
	
	If Not Common.SeparatedDataUsageAvailable() Or Not Common.DataSeparationEnabled() Then
		
		LanguageCode1 = ?(UseAdditionalLanguage1, AdditionalLanguage1, "");
		LanguageCode2 = ?(UseAdditionalLanguage2, AdditionalLanguage2, "");
		
		LanguagesCodes = New Array;
		LanguagesCodes.Add(DefaultLanguage);
		If UseAdditionalLanguage1 Then
			LanguagesCodes.Add(AdditionalLanguage1);
		EndIf;
		If UseAdditionalLanguage2 Then
			LanguagesCodes.Add(AdditionalLanguage2);
		EndIf;
		
		BeginTransaction();
		Try
			
			SessionParameters.DefaultLanguage = DefaultLanguage;
			
			Constants.DefaultLanguage.Set(DefaultLanguage);
			
			Constants.AdditionalLanguage1.Set(LanguageCode1);
			Constants.UseAdditionalLanguage1.Set(UseAdditionalLanguage1);
			
			Constants.AdditionalLanguage2.Set(LanguageCode2);
			Constants.UseAdditionalLanguage2.Set(UseAdditionalLanguage2);
			
			Constants.DataToChangeMultilanguageAttributes.Set(MetadataListToProcess);
			
			If Common.SeparatedDataUsageAvailable() Then
				If Common.SubsystemExists("StandardSubsystems.Print") Then
					ModulePrintManager = Common.CommonModule("PrintManagement");
					ModulePrintManager.AddPrintFormsLanguages(LanguagesCodes);
				EndIf;
			EndIf;
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	
	EndIf;
	
	RefreshReusableValues();
	
EndProcedure

&AtServer
Function ConstantsValuesChanged()
	
	If Metadata.Languages.Count() = 1 Then
		Return False;
	EndIf;
	
	If StrCompare(Constants.DefaultLanguage.Get(), DefaultLanguage) <> 0 Then
		Return True;
	EndIf;
	
	If (Constants.UseAdditionalLanguage1.Get() = False And UseAdditionalLanguage1 = True)
		Or (Constants.UseAdditionalLanguage2.Get() = False And UseAdditionalLanguage2 = True) Then
			Return True;
	EndIf;
	
	If UseAdditionalLanguage1
		And StrCompare(Constants.AdditionalLanguage1.Get(), AdditionalLanguage1) <> 0 Then
			Return True;
	EndIf;
	
	If UseAdditionalLanguage2
		And StrCompare(Constants.AdditionalLanguage2.Get(), AdditionalLanguage2) <> 0 Then
			Return True;
	EndIf;
	
	Return False;
	
EndFunction


// Returns:
//   See NationalLanguageSupportServer.DescriptionOfOldAndNewLanguageSettings
//
&AtServer
Function OldAndNewValuesOfConstants()
	
	Result = NationalLanguageSupportServer.DescriptionOfOldAndNewLanguageSettings();
	
	Result.MainLanguageOldValue= Constants.DefaultLanguage.Get();
	Result.MainLanguageNewMeaning = DefaultLanguage;
	
	Result.AdditionalLanguage1OldValue = Constants.AdditionalLanguage1.Get();
	Result.AdditionalLanguage1NewValue = AdditionalLanguage1;
	
	Result.AdditionalLanguage2OldValue = Constants.AdditionalLanguage2.Get();
	Result.AdditionalLanguage2NewValue = AdditionalLanguage2;
	
	Return Result;
	
EndFunction

// Time zone.

&AtServer
Procedure FillInTimeZones()

	For Each DescriptionOfTheTimeZone In GetAvailableTimeZones() Do
	
			OffsetByDate = Date(1, 1, 1) + StandardTimeOffset(DescriptionOfTheTimeZone); 
			OffsetPresentation = StringFunctionsClientServer.SubstituteParametersToString("(UTC+%1)",
				Format(OffsetByDate, "DF=HH:mm; DE=00:00;"));
	
			TimeZonePresentation = OffsetPresentation + " " + DescriptionOfTheTimeZone;
			Items.AppTimeZone.ChoiceList.Add(DescriptionOfTheTimeZone, TimeZonePresentation);
			
	EndDo;
	
EndProcedure

&AtServerNoContext
Function TimeZoneOffset(AppTimeZone, TimeOnTheClient)
	
	UniversalSessionDate = ToUniversalTime(CurrentSessionDate(), SessionTimeZone());
	SessionDateNewTimeZone = UniversalSessionDate + StandardTimeOffset(AppTimeZone);

	Return SessionDateNewTimeZone - TimeOnTheClient + DaylightTimeOffset(AppTimeZone);
	
EndFunction

&AtClient
Procedure SetTime()
	
	SelectedTimeZoneTime = CurrentTimeOnTheClient() + TimeZoneOffset;
	AttachIdleHandler("SetTime", 1, True);
	
EndProcedure

&AtClient
Function CurrentTimeOnTheClient()

	// ACC:143-off To calculate the time offset for the form, CurrentDate is required.
	Return CurrentDate();
	// ACC:143-on 
	
EndFunction

#EndRegion