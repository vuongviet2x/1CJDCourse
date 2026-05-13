///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

// For details, see section FILLED BY SUBSYSTEM DEVELOPERS in the object module.

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	PopulateTitlesAndTooltips();
	
	RestrictionsSource = "FromSpreadsheetDocument";
	ExportToTemporaryFolder = True;
	
	UserKindsProperties.Add();
	UserKindsProperties.Add();
	
	DataProcessorObject = FormAttributeToValue("Object");
	IsExternalDataProcessor = Not Metadata.DataProcessors.Contains(DataProcessorObject.Metadata());
	If IsExternalDataProcessor Then
		DataProcessorFileName = DataProcessorObject.UsedFileName;
	EndIf;
	
	If Not ValueIsFilled(ComparisonSource) Then
		ComparisonSource = "File";
	EndIf;
	
	Items.RestrictionByOwnerWithOptimizationLabel.ToolTip =
		NStr("ru = 'Для работы ограничения используются ключи доступа, записанные для владельца.
		           |Не требуется запись своих ключей доступа и расчет прав на них, что эффективно.';
					|en = 'For the restriction to work, access keys written for the owner are used.
					|It is not required to write own access keys and calculate the rights to them, which is effective.';");
	
	Items.RestrictionByOwnerWithOptimizationLabelForExternalUsers.ToolTip =
		Items.RestrictionByOwnerWithOptimizationLabel.ToolTip;
	
	Items.RestrictionByOwnerWithoutOptimizationLabel.ToolTip =
		NStr("ru = 'Оптимизация не используется, так как ключи доступа объекта используются другим объектом, либо отключена разработчиком,
		           |либо в ограничении есть условия кроме проверки прав объекта, которые остаются после упрощения (с учетом неиспользуемых видов доступа).
		           |Для работы ограничения записываются свои ключи доступа, зависимые от ключей доступа владельца, что увеличивает время обновления.
		           |Иногда при разработке требуется учесть, что права на зависимые ключи доступа рассчитываются с небольшим отставанием от расчета прав на ведущие ключи доступа.';
					|en = 'Optimization is not used because objects access keys are used by another object, or it is disabled by the developer,
					|or the restriction contains conditions other than checking the object rights that remain after simplification (considering unused access kinds).
					|For the restriction to work, own access keys that depend on owner access keys are written, which increases the update time.
					|During development, it is sometimes required to take into account that the rights to dependent access keys are calculated slightly later than the rights to master access keys.';");
	
	Items.RestrictionByOwnerWithoutOptimizationLabelForExternalUsers.ToolTip =
		Items.RestrictionByOwnerWithoutOptimizationLabel.ToolTip;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
#If WebClient Or MobileClient Then
		ShowMessageBox(, NStr("ru = 'Инструмент ""Управление доступом"" недоступен в веб-клиенте и мобильном клиенте, используйте тонкий клиент.';
										|en = 'The ""Access management"" tool is not available in the web client and mobile client. Use the thin client.';"));
		Cancel = True;
		Return;
#EndIf
	
#If Not WebClient Then
	
	ReadStartupParameters();
	
	If StrFind(LaunchParameter, "NewDescriptionFolder") > 0 Then
		StartRestrictionsTextsExport();
		Terminate();
		Return;
	EndIf;
	
	Items.FolderForRLSTextExportFromThisConfiguration.Enabled = ExportRLSTexts;
	Items.FolderWithDumpedConfigurationFiles.Enabled = ConfigurationFilesExported;
	SetItemsVisibility();
	
	ReadDifferences();
	
#EndIf
	
	Items.List.UpdateEditText();
	UpdateListRestrictionTexts();
	
	If Not ValueIsFilled(ExternalApplicationCommandLine) Then
		ExternalApplicationCommandLine = """C:\Program Files (x86)\SmartSynchronize\bin\smartsynchronize.exe"" %1 %2";
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	UpdateItemAvailability(ThisObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	AttributesToExclude = New Array;
	
	If ComparisonSource = "File" Then
		AttributesToExclude.Add("FolderForPreviousRLSTextExport");
	Else // "Folder".
		AttributesToExclude.Add("PathToPreviousConfigurationVersionFile");
	EndIf;
	
	If Not ExportRLSTexts Then
		AttributesToExclude.Add("FolderForRLSTextExportFromThisConfiguration");
	EndIf;
	
	If Not ConfigurationFilesExported Then
		AttributesToExclude.Add("FolderWithDumpedConfigurationFiles");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesToExclude);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListOnChange(Item)
	
	UpdateListRestrictionTexts();
	
EndProcedure

&AtClient
Procedure ListStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Collections = New ValueList;
	Collections.Add("ExchangePlans");
	Collections.Add("Catalogs");
	Collections.Add("Documents");
	Collections.Add("DocumentJournals");
	Collections.Add("ChartsOfCharacteristicTypes");
	Collections.Add("ChartsOfAccounts");
	Collections.Add("ChartsOfCalculationTypes");
	Collections.Add("InformationRegisters");
	Collections.Add("AccumulationRegisters");
	Collections.Add("AccountingRegisters");
	Collections.Add("CalculationRegisters");
	Collections.Add("BusinessProcesses");
	Collections.Add("Tasks");
	
	FormParameters = StandardSubsystemsClientServer.MetadataObjectsSelectionParameters();
	FormParameters.SelectSingle = True;
	FormParameters.ChoiceInitialValue = List;
	FormParameters.MetadataObjectsToSelectCollection = Collections;
	
	StandardSubsystemsClient.ChooseMetadataObjects(FormParameters, 
		New NotifyDescription("ListStartChoiceCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure ListOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Items.List.OpenButton <> True Then
		Return;
	EndIf;
	
	FileSystemClient.OpenURL("e1cib/list/" + List);
	
EndProcedure

&AtClient
Procedure ListEditTextChange(Item, Text, StandardProcessing)
	
	List = Text;
	UpdateListRestrictionTexts();
	
EndProcedure

&AtClient
Procedure RestrictionTextEditTextChange(Item, Text, StandardProcessing)
	
	OnChangeRestrictionText(False);
	
EndProcedure

&AtClient
Procedure RestrictionTextForExternalUsersEditTextChange(Item, Text, StandardProcessing)
	
	OnChangeRestrictionText(True);
	
EndProcedure

&AtClient
Procedure RestrictionsSourceOnChange(Item)
	
	UpdateItemAvailability(ThisObject);
	
EndProcedure

&AtClient
Procedure ReadyConfigurationFileDumpFolderStartChoice(Item, ChoiceData, StandardProcessing)
	
	Dialog = New FileDialog(FileDialogMode.ChooseDirectory);
	Dialog.Directory = ReadyConfigurationFileDumpFolder;
	Dialog.Title = NStr("ru = 'Выбор папки, содержащей файлы выгрузки конфигурации';
							|en = 'Select the folder containing configuration export files';");
	
	Handler = New NotifyDescription(
		"DirectoryForPreparedConfigurationDumpToFilesStartChoiceAfterChoice", ThisObject);
	FileSystemClient.ShowSelectionDialog(Handler, Dialog);
	
EndProcedure

&AtClient
Procedure FolderChoiceFieldOpen(Item, StandardProcessing)
	StandardProcessing = False;
	FileSystemClient.OpenExplorer(ThisObject[Item.Name]);
EndProcedure

&AtClient
Procedure FolderChoiceFieldStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FileDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	FileDialog.Directory = ThisObject[Item.Name];
	FileDialog.Title = NStr("ru = 'Выбор папки';
										|en = 'Select a folder';");
	
	If ValueIsFilled(Item.ToolTip) Then
		FileDialog.Title = Item.ToolTip;
	EndIf;
	
	NotifyDescription = New NotifyDescription("OnFolderChoice", ThisObject, Item.Name);
	FileSystemClient.ShowSelectionDialog(NotifyDescription, FileDialog);
	
EndProcedure

&AtClient
Procedure FolderChoiceFieldOnChange(Item)
	FileName = ThisObject[Item.Name];
	// ACC:566-off - A development tool
	File = New File(FileName);
	If File.Exists() Then
		ThisObject[Item.Name] = File.FullName + GetPathSeparator();
	EndIf;
	// ACC:566-on
EndProcedure

&AtClient
Procedure PathToPreviousConfigurationVersionFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Directory = "";
	// ACC:566-off - A development tool
	File = New File(ThisObject[Item.Name]);
	If File.Exists() Then
		Directory = File.Path;
	EndIf;
	// ACC:566-on
	
	FileDialog = New FileDialog(FileDialogMode.Open);
	FileDialog.Directory = Directory;
	FileDialog.Filter = "Configuration (*.cf)|*.cf";
	FileDialog.Title = NStr("ru = 'Выберите файл предыдущей версии конфигурации';
										|en = 'Select a file of previous configuration';");
	
	NotifyDescription = New NotifyDescription("OnSelectConfigurationFile", ThisObject);
	FileSystemClient.ShowSelectionDialog(NotifyDescription, FileDialog);
	
EndProcedure

&AtClient
Procedure ComparisonSourceOnChange(Item)
	If ComparisonSource = "File" And Not ValueIsFilled(DataProcessorFileName) Then
		ComparisonSource = "Folder";
		ShowMessageBox(, NStr("ru = 'Для сравнения текстов RLS с текстами в предыдущей версии конфигурации (.cf)
			|в конфигураторе выгрузите эту обработку в файл 
			|и откройте ее в тонком клиенте через меню Файл -> Открыть.';
			|en = 'To compare RLS texts with texts of the previous configuration version (.cf)
			|, export this data processor to file in Designer
			|and open it in thin client by clicking File -> Open.';"));
	EndIf;
	SetItemsVisibility();
EndProcedure

&AtClient
Procedure ExportRLSTextsOnChange(Item)
	Items.FolderForRLSTextExportFromThisConfiguration.Enabled = ExportRLSTexts;
EndProcedure

&AtClient
Procedure ConfigurationFilesExportedOnChange(Item)
	Items.FolderWithDumpedConfigurationFiles.Enabled = ConfigurationFilesExported;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDifferencesFound

&AtClient
Procedure DifferencesFoundOnActivateRow(Item)
	
#If Not WebClient Then
	
	If Items.DifferencesFound.CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.ReferenceDescriptionFolder) Or Not ValueIsFilled(Object.NewDescriptionFolder) Then
		Return;
	EndIf;
	
	Table = Items.DifferencesFound.CurrentData.Value;
	
	FileName = Object.ReferenceDescriptionFolder + Table + ".txt";
	PreviousText = ReadFile(FileName);
	
	FileName = Object.NewDescriptionFolder + Table + ".txt";
	CurrentText = ReadFile(FileName);
#EndIf

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateAccess(Command)
	
	ScheduleAccessUpdateAtServer(ListFullName);
	AccessManagementInternalClient.OpenAccessUpdateOnRecordsLevelForm(True, True);
	AttachIdleHandler("RunAccessUpdateIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure GenerateProfilesDetailsExecute(Command)
	TextDocument = New TextDocument;
	TextDocument.SetText(DetailsOfInitialProfilesFillingInIntegratedLanguage(SpecificProfile));
	TextDocument.Show(NStr("ru = 'Описание начального заполнения имеющихся профилей групп доступа';
									|en = 'Details of initial population of existing access group profiles';"));
EndProcedure

&AtClient
Procedure CheckRestriction(Command)
	
	CheckSpecifiedRestriction(False);
	
EndProcedure

&AtClient
Procedure ShowTextToInsert(Command)
	TextDocument = New TextDocument;
	TextDocument.SetText(TextForInsert());
	TextDocument.Show(NStr("ru = 'Тексты для вставки в модуль и в роли';
									|en = 'Texts to insert to module and roles';"));
EndProcedure

&AtClient
Procedure CalculateRestrictionInRole(Command)
	
	CheckSpecifiedRestriction(True);
	
EndProcedure

&AtClient
Procedure ExportToTemporaryFolderOnChange(Item)
	
	UpdateItemAvailability(ThisObject);
	
EndProcedure

&AtClient
Procedure GenerateFullDetails(Command)
	
	GenerateDescription();
	
EndProcedure

&AtClient
Procedure GenerateDifferencesDetails(Command)
	
	GenerateDescription(False);
	
EndProcedure

&AtClient
Procedure ExportDetails(Command)
	
#If Not WebClient Then
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	If ConfigurationFilesExported Then
		Object.ConfigurationExportFolder = FolderWithDumpedConfigurationFiles;
	Else
		Object.ConfigurationExportFolder = "";
		If DesignerIsOpen() And Not CommonClient.FileInfobase() Then
			ErrorText = NStr("ru = 'Для сравнения текстов RLS закройте конфигуратор.';
								|en = 'To compare RLS texts, close Designer.';");
			Raise ErrorText;
		EndIf;
	EndIf;
	
	If ComparisonSource = "File" Then
		// ACC:441-off - After the call, the data should be analyzed.
		Object.ReferenceDescriptionFolder = GetTempFileName("last") + GetPathSeparator();
		// ACC:441-on
		ExportRestrictionsTextsFromConfigurationFile();
	Else
		Object.ReferenceDescriptionFolder = FolderForPreviousRLSTextExport;
	EndIf;
	
	If ExportRLSTexts Then
		Object.NewDescriptionFolder = FolderForRLSTextExportFromThisConfiguration;
	Else
		// ACC:441-off - After the call, the data should be analyzed.
		Object.NewDescriptionFolder = GetTempFileName("this") + GetPathSeparator();
		// ACC:441-on
	EndIf;
	
	StartRestrictionsTextsExport();
	ReadDifferences();
	
	ShowUserNotification(NStr("ru = 'Контроль изменения текстов RLS';
										|en = 'Control of RLS text change';"), , NStr("ru = 'Сравнение текстов RLS подготовлено.';
																						|en = 'Comparison of RLS texts is prepared.';"));
#EndIf

EndProcedure

&AtClient
Procedure CompareInExternalApplication(Command)
	
	If Not ValueIsFilled(Object.NewDescriptionFolder) Then
		Object.NewDescriptionFolder = FolderForRLSTextExportFromThisConfiguration;
	EndIf;
	
	If Not ValueIsFilled(Object.ReferenceDescriptionFolder) Then
		Object.ReferenceDescriptionFolder = FolderForPreviousRLSTextExport;
	EndIf;
	
	CommandLine1 = StringFunctionsClientServer.SubstituteParametersToString(
		ExternalApplicationCommandLine,
		Quote(Object.ReferenceDescriptionFolder),
		Quote(Object.NewDescriptionFolder));
	
	FileSystemClient.StartApplication(CommandLine1);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure PopulateTitlesAndTooltips()
	
	Items.Explanation3.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.Explanation3.Title,
		"OnFillSuppliedAccessGroupProfiles",
		"AccessManagementOverridable");
	
	Items.Explanation4.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.Explanation4.Title,
		"OnFillMetadataObjectsAccessRestrictionKinds",
		"AccessManagementOverridable");
	
	Items.GenerateDifferencesForAccessKindsDetailsByRights.ExtendedTooltip.Title
		= StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Сформировать описание различий между новым описанием и
			           |существующим описанием в процедуре
			           |%1
			           |общего модуля %2
			           |для частичного исправления существующего описания.';
						|en = 'Generate details of differences between new details and
						|existing details in the procedure
						|%1
						|of the %2 common module
						|to correct existing details partially.';"),
			"OnFillMetadataObjectsAccessRestrictionKinds",
			"AccessManagementOverridable");
	
	Items.GenerateAccessKindsDetailsByRights.ExtendedTooltip.Title
		= StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Сформировать полное описание для вставки в процедуру %1 общего модуля %2.';
				|en = 'Generate full details to insert in the ""%1"" procedure of the %2 common module.';"),
			"OnFillMetadataObjectsAccessRestrictionKinds",
			"AccessManagementOverridable");
	
EndProcedure

&AtClient
Procedure ListStartChoiceCompletion(ValueList, Context) Export
	
	If TypeOf(ValueList) <> Type("ValueList")
	 Or ValueList.Count() = 0 Then
		Return;
	EndIf;
	
	List = ValueList[0].Value;
	
	AttachIdleHandler("ListUpdateEditingTextIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure ListUpdateEditingTextIdleHandler()
	
	Items.List.UpdateEditText();
	UpdateListRestrictionTexts();
	
EndProcedure

&AtServerNoContext
Procedure ScheduleAccessUpdateAtServer(Val FullName)
	
	AccessManagementInternal.ScheduleAccessUpdate(FullName);
	
EndProcedure

&AtClient
Procedure RunAccessUpdateIdleHandler()
	
	Result = RunAccessUpdateAtServer();
	If ValueIsFilled(Result.WarningText) Then
		ShowMessageBox(, Result.WarningText);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function RunAccessUpdateAtServer()
	
	Return AccessManagementInternal.StartAccessUpdateAtRecordLevel(True);
	
EndFunction

&AtClient
Procedure CheckSpecifiedRestriction(ConsiderDependencies)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ConsiderDependencies", ConsiderDependencies);
	AdditionalParameters.Insert("Text", UserKindsProperties[0].RestrictionText);
	AdditionalParameters.Insert("TextForExternalUsers1",
		UserKindsProperties[1].RestrictionText);
	
	UpdateListRestrictionTexts(AdditionalParameters);
	
	If Items.AccessRestriction.CurrentPage = Items.ForUsers Then
		If ValueIsFilled(UserKindsProperties[0].RestrictionErrorsText) Then
			Items.AccessRestriction.CurrentPage = Items.ForUsersErrors;
			CurrentItem = Items.RestrictionErrorsText;
		EndIf;
	Else
		If ValueIsFilled(UserKindsProperties[1].RestrictionErrorsText) Then
			Items.AccessRestriction.CurrentPage = Items.ForExternalUsersErrors;
			CurrentItem = Items.RestrictionErrorsTextForExternalUsers;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateListRestrictionTexts(AdditionalParameters = Undefined)
	
	ListProperties = ListProperties(List, AdditionalParameters);
	FillPropertyValues(ThisObject, ListProperties);
	
	Items.AccessRestriction.Enabled = ListProperties.ListFound;
	Items.List.OpenButton          = ListProperties.ListFound;
	Items.UpdateAccess.Enabled     = ListProperties.ListFound;
	
	UpdateListRestrictionTextsForUsersKind(ListProperties.ForUsers, False, AdditionalParameters);
	UpdateListRestrictionTextsForUsersKind(ListProperties.ForExternalUsers, True, AdditionalParameters);
	
	HasErrors = Not ListProperties.HasResultList
		Or ValueIsFilled(ListProperties.ForUsers.RestrictionErrorsText)
		Or ValueIsFilled(ListProperties.ForExternalUsers.RestrictionErrorsText);
	
	Items.CalculateRestrictionInRole.Enabled = Not HasErrors;
	Items.CalculateRestrictionInRoleForExternalUsers.Enabled = Not HasErrors;
	
	UpdateTextToInsertAvailability(HasErrors);
	
EndProcedure

&AtClient
Procedure UpdateListRestrictionTextsForUsersKind(Properties, ForExternalUsers, AdditionalParameters)
	
	If ForExternalUsers Then
		PagesRestrictionInRoleTitles            = Items.RestrictionInRoleHeadersForExternalUsers;
		PageRestrictionInRoleTitleWithCalculation   = Items.RestrictionInRoleHeaderWithCalculationForExternalUsers;
		PageRestrictionInRoleTitleWithoutCalculation  = Items.RestrictionInRoleHeaderWithoutCalculationForExternalUsers;
		ErrorItem                                = Items.ForExternalUsersErrors;
		ItemRestrictionText                      = Items.RestrictionTextForExternalUsers;
		ItemCheckRestrictionText             = Items.CheckRestrictionTextForExternalUsers;
		ItemCalculateRestrictionInRole            = Items.CalculateRestrictionInRoleForExternalUsers;
		OwnerRestrictionElement                = Items.RestrictionByOwnerForExternalUsers;
		PageOwnerRestrictionNotCalculated   = Items.RestrictionByOwnerNotCalculatedForExternalUsers;
		PageOwnerRestrictionWithOptimization  = Items.RestrictionByOwnerWithOptimizationForExternalUsers;
		PageOwnerRestrictionWithoutOptimization = Items.RestrictionByOwnerWithoutOptimizationForExternalUsers;
		CaptionRestrictionOnOwnerWithoutOptimization  = Items.RestrictionByOwnerWithoutOptimizationLabelForExternalUsers;
	Else
		PagesRestrictionInRoleTitles            = Items.RestrictionInRoleHeaders;
		PageRestrictionInRoleTitleWithCalculation   = Items.RestrictionInRoleHeaderWithCalculation;
		PageRestrictionInRoleTitleWithoutCalculation  = Items.RestrictionInRoleHeaderWithoutCalculation;
		ErrorItem                                = Items.ForUsersErrors;
		ItemRestrictionText                      = Items.RestrictionText;
		ItemCheckRestrictionText             = Items.CheckRestrictionText;
		ItemCalculateRestrictionInRole            = Items.CalculateRestrictionInRole;
		OwnerRestrictionElement                = Items.RestrictionByOwner;
		PageOwnerRestrictionNotCalculated   = Items.RestrictionByOwnerNotCalculated;
		PageOwnerRestrictionWithOptimization  = Items.RestrictionByOwnerWithOptimization;
		PageOwnerRestrictionWithoutOptimization = Items.RestrictionByOwnerWithoutOptimization;
		CaptionRestrictionOnOwnerWithoutOptimization  = Items.RestrictionByOwnerWithoutOptimizationLabel;
	EndIf;
	
	PagesRestrictionInRoleTitles.CurrentPage =
		?(Properties.RestrictionByOwnerPossible = True,
			PageRestrictionInRoleTitleWithCalculation, PageRestrictionInRoleTitleWithoutCalculation);
	
	StoredProperties = UserKindsProperties[?(ForExternalUsers, 1, 0)];
	FillPropertyValues(StoredProperties, Properties);
	
	ErrorItem.Visible = ValueIsFilled(StoredProperties.RestrictionErrorsText);
	ItemRestrictionText.UpdateEditText();
	ItemCheckRestrictionText.Title = NStr("ru = 'Проверить';
														|en = 'Check';");
	
	If ValueIsFilled(Properties.RestrictionErrorsText)
		Or Properties.RestrictionByOwnerPossible = True
		And (AdditionalParameters = Undefined
			Or Not AdditionalParameters.ConsiderDependencies) Then
		
		StoredProperties.RestrictionTextInRole = ?(ValueIsFilled(Properties.RestrictionErrorsText),
			NStr("ru = '<Ограничение для роли не рассчитано - исправьте ошибки и нажмите Проверить>';
				|en = '<;Restriction is not calculated for the role. Fix the errors and click Check>';"),
			NStr("ru = '<Ограничение для роли не рассчитано - нажмите Рассчитать>';
				|en = '<Restriction is not calculated for the role - click Calculate>';"));
		
		OwnerRestrictionElement.CurrentPage = PageOwnerRestrictionNotCalculated;
		ItemCalculateRestrictionInRole.Title = NStr("ru = 'Рассчитать *';
															|en = 'Calculate *';");
		
	ElsIf Properties.RestrictionByOwnerPossible = True Then
		
		ItemCalculateRestrictionInRole.Title = NStr("ru = 'Рассчитать';
															|en = 'Calculate';");
		OwnerRestrictionElement.CurrentPage = ?(Properties.TheOwnerRestrictionIsUsed,
			PageOwnerRestrictionWithOptimization, PageOwnerRestrictionWithoutOptimization);
		CaptionRestrictionOnOwnerWithoutOptimization.Title =
			?(Properties.ByOwnerWithoutSavingAccessKeys = False,
				NStr("ru = 'Без оптимизации (отключена)';
					|en = 'No optimization (disabled)';"), NStr("ru = 'Без оптимизации';
																|en = 'No optimization';"));
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangeRestrictionText(ForExternalUsers)
	
	If ForExternalUsers Then
		ItemCheckRestrictionText  = Items.CheckRestrictionTextForExternalUsers;
		ItemCalculateRestrictionInRole = Items.CalculateRestrictionInRoleForExternalUsers;
	Else
		ItemCheckRestrictionText  = Items.CheckRestrictionText;
		ItemCalculateRestrictionInRole = Items.CalculateRestrictionInRole;
	EndIf;
	
	ItemCheckRestrictionText.Title  = NStr("ru = 'Проверить *';
														|en = 'Check *';");
	ItemCalculateRestrictionInRole.Title = NStr("ru = 'Рассчитать';
														|en = 'Calculate';");
	
	Items.CalculateRestrictionInRole.Enabled = False;
	Items.RestrictionByOwner.CurrentPage = Items.RestrictionByOwnerNotCalculated;
	
	Items.CalculateRestrictionInRoleForExternalUsers.Enabled = False;
	Items.RestrictionByOwnerForExternalUsers.CurrentPage =
		Items.RestrictionByOwnerNotCalculatedForExternalUsers;
	
	StoredProperties = UserKindsProperties[?(ForExternalUsers, 1, 0)];
	StoredProperties.RestrictionTextInRole = NStr("ru = '<Ограничение для роли не рассчитано - нажмите Проверить>';
													|en = '<Restriction is not calculated for the role - click Check>';");
	
	UpdateTextToInsertAvailability(True);
	
EndProcedure

&AtClient
Procedure UpdateTextToInsertAvailability(HasErrors)
	
	TextToInsertAvailable = Not HasErrors
		And (    ValueIsFilled(UserKindsProperties[0].RestrictionText)
		   Or ValueIsFilled(UserKindsProperties[1].RestrictionText) );
	
	Items.ShowTextToInsert.Enabled = TextToInsertAvailable;
	Items.ShowTextToInsertForExternalUsers.Enabled = TextToInsertAvailable;
	
EndProcedure

&AtServerNoContext
Function ListProperties(List, AdditionalParameters = Undefined)
	
	Properties = New Structure;
	Properties.Insert("ListFound", False);
	Properties.Insert("NoteList", "");
	Properties.Insert("HasResultList", False);
	Properties.Insert("TextInManagerModule", Undefined);
	Properties.Insert("ListFullName", "");
	Properties.Insert("FullCollectionNameList", "");
	Properties.Insert("ImplementationSettings",      New Structure);
	Properties.Insert("ForUsers",        PropertiesForUsersKind());
	Properties.Insert("ForExternalUsers", PropertiesForUsersKind());
	
	MetadataObject = Common.MetadataObjectByFullName(List);
	
	If MetadataObject = Undefined Then
		If ValueIsFilled(List) Then
			Properties.NoteList = NStr("ru = 'Список не найден';
											|en = 'List is not found';");
		Else
			Properties.NoteList = NStr("ru = 'Список не выбран';
											|en = 'List is not selected';");
		EndIf;
		Return Properties;
	EndIf;
	
	FullName = MetadataObject.FullName();
	Properties.ListFullName = FullName;
	Properties.ListFound = True;
	
	Properties.FullCollectionNameList =
		Common.BaseTypeNameByMetadataObject(MetadataObject) + "." + MetadataObject.Name;
	
	Try
		Result = AccessManagementInternal.AccessRestrictionCheckResult(FullName, AdditionalParameters);
	Except
		ErrorInfo = ErrorInfo();
		RestrictionDetailsError = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		Result = Undefined;
	EndTry;
	
	If Result <> Undefined
	   And ValueIsFilled(Result.RestrictionDetailsError) Then
		
		RestrictionDetailsError = Result.RestrictionDetailsError;
		Result = Undefined;
	EndIf;
	
	If Result = Undefined Then
		Properties.NoteList = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Список найден. Не удалось определить наличие ограничения по причине:
			           |%1';
						|en = 'The list is found. Cannot identify if there is a restriction due to:
						|%1';"),
			RestrictionDetailsError);
		Return Properties;
	EndIf;
	
	Properties.HasResultList = True;
	
	Properties.TextInManagerModule = Result.TextInManagerModule;
	
	If Result.TextInManagerModule = Undefined Then
		Properties.NoteList = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Список найден. Не указан в процедуре %1 общего модуля %2.';
				|en = 'The list is found. It is not specified in procedure ""%1"" of common module ""%2"".';"),
			"OnFillListsWithAccessRestriction",
			"AccessManagementOverridable");
	Else
		If Result.TextInManagerModule Then
			Properties.NoteList = NStr("ru = 'Список найден. Ограничение в модуле менеджера.';
											|en = 'The list is found. Restriction in manager module.';");
		Else
			Properties.NoteList = NStr("ru = 'Список найден. Ограничение в переопределяемом модуле.';
											|en = 'The list is found. Restriction in overridable module.';");
		EndIf;
	EndIf;
	
	Properties.ImplementationSettings = Result.ImplementationSettings;
	
	FillListPropertiesForUsersKind(Properties.ForUsers,
		Result.ForUsers, AdditionalParameters);
	
	FillListPropertiesForUsersKind(Properties.ForExternalUsers,
		Result.ForExternalUsers, AdditionalParameters);
	
	Return Properties;
	
EndFunction

&AtServerNoContext
Function PropertiesForUsersKind()
	
	Properties = New Structure;
	
	Properties.Insert("RestrictionByOwnerPossible");
	Properties.Insert("TheOwnerRestrictionIsUsed");
	Properties.Insert("ByOwnerWithoutSavingAccessKeys");
	Properties.Insert("RestrictionErrorsText");
	Properties.Insert("RestrictionTextInRole");
	
	Return Properties;
	
EndFunction

&AtServerNoContext
Procedure FillListPropertiesForUsersKind(Properties, Result, AdditionalParameters)
	
	Properties.RestrictionByOwnerPossible     = Result.RestrictionByOwnerPossible;
	Properties.TheOwnerRestrictionIsUsed = Result.TheOwnerRestrictionIsUsed;
	Properties.ByOwnerWithoutSavingAccessKeys  = Result.ByOwnerWithoutSavingAccessKeys;
	
	If AdditionalParameters = Undefined Then
		Properties.Insert("RestrictionText", Result.RestrictionToCheck);
	EndIf;
	
	ErrorsText = "";
	ErrorsDescription = Result.ErrorsDescription; // Structure
	
	If ValueIsFilled(ErrorsDescription) Then
		ErrorsText = ErrorsDescription.ErrorsText;
		ErrorsText = ErrorsText + Chars.LF + Chars.LF + ErrorsDescription.Restriction;
		If ValueIsFilled(ErrorsDescription.AddOn) Then
			ErrorsText = ErrorsText + Chars.LF + Chars.LF + ErrorsDescription.AddOn;
		EndIf;
	EndIf;
	
	If ValueIsFilled(Result.RestrictionParametersGenerationError) Then
		ErrorsText = ErrorsText + Chars.LF + Chars.LF
			+ Result.RestrictionParametersGenerationError;
	EndIf;
	
	If ValueIsFilled(Result.QueriesTextsGenerationError) Then
		ErrorsText = ErrorsText + Chars.LF + Chars.LF
			+ Result.QueriesTextsGenerationError;
	EndIf;
	
	Properties.RestrictionErrorsText = TrimAll(ErrorsText);
	RestrictionInRoles = Result.RestrictionInRoles; // Structure
	
	If ValueIsFilled(Properties.RestrictionErrorsText)
	 Or Not ValueIsFilled(Result.RestrictionToCheck)
	 Or RestrictionInRoles = Undefined Then
		Return;
	EndIf;
	
	If RestrictionInRoles.TemplateForObject Then
		RestrictionTextInRole = "#ForObject(";
		ParametersCount = 1;
	Else
		RestrictionTextInRole = "#ForRegister(";
		ParametersCount = 6;
	EndIf;
	RestrictionTextInRole = ?(RestrictionInRoles.TemplateForObject, "#ForObject(", "#ForRegister(");
	
	FirstParameter = True;
	For Each Parameter In RestrictionInRoles.Parameters Do
		RestrictionTextInRole = RestrictionTextInRole + ?(FirstParameter, "", ", ") + """" + Parameter + """";
		FirstParameter = False;
	EndDo;
	
	For ParameterNumber = RestrictionInRoles.Parameters.Count() + 1 To ParametersCount Do
		RestrictionTextInRole = RestrictionTextInRole + ?(FirstParameter, "", ", ") + """""";
		FirstParameter = False;
	EndDo;
	
	Properties.RestrictionTextInRole = RestrictionTextInRole + ")";
	
EndProcedure

&AtClient
Function TextForInsert()
	
	PointNumber = 1;
	Text = "";
	
	If TextInManagerModule = Undefined Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '1. В процедуру %1
			           |   общего модуля %2 добавить строку:';
						|en = '1. Add the following line to procedure ""%1""
						|   of common module ""%2"":';"),
			"OnFillListsWithAccessRestriction",
			"AccessManagementOverridable");
		Text = Text + StringFunctionsClientServer.SubstituteParametersToString("
			           |
			           |	Lists.Insert(Metadata.%1, True);", FullCollectionNameList);
		Text = Text + Chars.LF + Chars.LF;
		PointNumber = 2;
	EndIf;
	
	If TextInManagerModule <> False Then
		Text = Text + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1. В модуле менеджера объекта метаданных %2 вставить или обновить процедуру:';
				|en = '%1. Insert or update the procedure in manager module of metadata object %2:';"),
			PointNumber,
			FullCollectionNameList);
			
		Text = Text + Chars.LF + Chars.LF +
		"#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		|#Area Public
		|#Area ForCallsFromOtherSubsystems
		|// StandardSubsystems.AccessManagement
		|
		|// Parameters:
		|//   Restriction - see. AccessManagementOverridable.OnFillAccessRestriction.Restriction.
		|//
		|Procedure OnFillAccessRestriction(Restriction) Export
		|	" + ?(ValueIsFilled(UserKindsProperties[0].RestrictionText), "
		|	Restriction.Text =
		|	""" + TextWithIndent(UserKindsProperties[0].RestrictionText, "	|") + """;
		|	", "") + ?(ValueIsFilled(UserKindsProperties[1].RestrictionText), "
		|	Restriction.TextForExternalUsers1 =
		|	""" + TextWithIndent(UserKindsProperties[1].RestrictionText, "	|") + """;
		|	", "") + "
		|EndProcedure
		|
		|// End StandardSubsystems.AccessManagement
		|#EndRegion
		|#EndRegion
		|#EndIf";
	Else
		Text = Text + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1. В процедуре %2
			           |   общего модуля %3 вставить или обновить строки:';
						|en = '%1. Insert or update rows in the %2 procedure
						|of the %3 common module:';"),
			PointNumber,
			"OnFillAccessRestriction",
			"AccessManagementOverridable");
			
		Text = Text + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
		"	If List = Metadata.%1 Then
		|		
		|		Restriction.Text =
		|		""%2"";" + ?(ValueIsFilled(UserKindsProperties[1].RestrictionText), "
		|		
		|		Restriction.TextForExternalUsers1 =
		|		""%3"";", "") + "
		|	
		|	EndIf;",
		FullCollectionNameList,
		TextWithIndent(UserKindsProperties[0].RestrictionText, "		|"),
		TextWithIndent(UserKindsProperties[1].RestrictionText, "		|"));
	EndIf;
	Text = Text + Chars.LF + Chars.LF;
	PointNumber = PointNumber + 1;
	
	If ValueIsFilled(UserKindsProperties[0].RestrictionText)
	   And Not StrStartsWith(UserKindsProperties[0].RestrictionText, "<")
	 Or ValueIsFilled(UserKindsProperties[1].RestrictionText)
	   And Not StrStartsWith(UserKindsProperties[1].RestrictionText, "<") Then
	
		Text = Text + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1. В процедуре %2 формы элемента данных (если есть)
			           |   следует сделать вставку кода (для библиотек проверка подсистемы обязательна):';
						|en = '%1. Insert the code in the %2 procedure of the data item form (if any)
						| (for libraries, subsystem check is required):';"),
			PointNumber, "OnReadAtServer");
		
		Text = Text + Chars.LF + Chars.LF +
		"	// StandardSubsystems.AccessManagement
		|	If Common.SubsystemExists(""StandardSubsystems.AccessManagement"") Then
		|		ModuleAccessManagement = Common.CommonModule(""AccessManagement"");
		|		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
		|	EndIf;
		|	// End StandardSubsystems.AccessManagement";
		
		PointNumber = PointNumber + 1;
		Text = Text + Chars.LF + Chars.LF;
	EndIf;
	
	Text = Text + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = '%1. Запустить отчет %2 в режиме исправления с отбором по подсистеме
		           |   Управление доступом, чтобы проверить и обновить внедрение после изменения текста ограничения.';
					|en = '%1. Run the %2 report in troubleshooting mode with the Access management subsystem filter to verify and update integration after the restriction text is changed.
					|';"),
		PointNumber, "SSLImplementationCheck.epf");
	Text = Text + Chars.LF + Chars.LF;
	Text = Text + "	" + NStr("ru = 'Либо обновить внедрение вручную:';
									|en = 'Or update the integration manually:';");
	
	AddRoleTemplateDetails(Text, FullCollectionNameList, UserKindsProperties[0],
		NStr("ru = 'в роли с назначением для пользователей на права %1
		           |объекта метаданных %2 установить ограничение
		           |(и добавить соответствующий шаблон ограничения, если его еще нет в роли):';
					|en = 'Set restriction
					|on rights %1
					|of the %2 metadata object in role with assignment for users (and add the matching restriction template if it is not in the role):';"));
	
	AddRoleTemplateDetails(Text, FullCollectionNameList, UserKindsProperties[1],
		NStr("ru = 'в роли с назначением для внешних пользователей на права %1
		           |объекта метаданных %2 установить ограничение
		           |(и добавить соответствующий шаблон ограничения, если его еще нет в роли):';
					|en = 'Set restriction
					|on rights %1
					|of the %2 metadata object in role with assignment for external users (and add the matching restriction template if it is not in the role):';"));
	
	AddRequiredTypesDetails(Text, ImplementationSettings, "AccessKeysValuesOwner");
	AddRequiredTypesDetails(Text, ImplementationSettings, "AccessKeysValuesOwnerObject");
	AddRequiredTypesDetails(Text, ImplementationSettings, "AccessKeysValuesOwnerDocument");
	AddRequiredTypesDetails(Text, ImplementationSettings, "AccessKeysValuesOwnerRecordSet");
	AddRequiredTypesDetails(Text, ImplementationSettings, "AccessKeysValuesOwnerCalculationRegisterRecordSet");
	AddRequiredTypesDetails(Text, ImplementationSettings, "RegisterAccessKeysRegisterField");
	
	If ValueIsFilled(ImplementationSettings.DimensionTypesForSeparateKeyRegister) Then
		AddRequiredItemsDetails(Text,
			ImplementationSettings.DimensionTypesForSeparateKeyRegister.InformationRegisterName,
			ImplementationSettings.DimensionTypesForSeparateKeyRegister.DimensionsTypes,
			NStr("ru = 'в регистр сведений %1 добавить типы:';
				|en = 'add types to information register %1:';"));
	EndIf;
	
	If ValueIsFilled(ImplementationSettings.PredefinedID) Then
		AddRequiredItemsDetails(Text,
			ImplementationSettings.PredefinedID.CatalogName,
			ImplementationSettings.PredefinedID.PredefinedItemName,
			NStr("ru = 'в справочник %1 добавить предопределенный элемент:';
				|en = 'add a predefined item to catalog %1:';"));
	EndIf;
	
	Return Text;
	
EndFunction

&AtClient
Procedure AddRoleTemplateDetails(Text, FullName, RoleTemplateDetails, LongDesc)
	
	If ValueIsFilled(RoleTemplateDetails.RestrictionTextInRole) Then
		If StrStartsWith(RoleTemplateDetails.RestrictionTextInRole, "<") Then
			RoleTemplate = RoleTemplateDetails.RestrictionTextInRole;
		Else
			RoleTemplate =
			"#If &RecordLevelAccessRestrictionIsUniversal #Then
			|" + RoleTemplateDetails.RestrictionTextInRole + "
			|#Else
			|<" + NStr("ru = 'старое ограничение доступа';
						|en = 'previous access restriction';") + ">
			|#EndIf"
		EndIf;
	Else
		RoleTemplate = "<" + NStr("ru = 'Очистить ограничение, если указано и удалить шаблон, если не используется в роли';
								|en = 'Clear the restriction if specified and delete a template if it is not used in the role';") + ">";
	EndIf;
	
	DetailsToAdd = StringFunctionsClientServer.SubstituteParametersToString(LongDesc,
		"Read" + ", " + "Create" + ", " + "Update", FullName);
	DetailsToAdd = "- " + TextWithIndent(DetailsToAdd, "  ") + Chars.LF + Chars.LF;
	DetailsToAdd = DetailsToAdd + "  " + TextWithIndent(RoleTemplate, "  ");
	
	Text = Text + Chars.LF + "	" + TextWithIndent(DetailsToAdd, "	") + Chars.LF;
	
EndProcedure

&AtClient
Procedure AddRequiredTypesDetails(Text, ImplementationSettings, TypeToDefineName)
	
	If Not ValueIsFilled(ImplementationSettings[TypeToDefineName]) Then
		Return;
	EndIf;
	
	AddRequiredItemsDetails(Text, TypeToDefineName, ImplementationSettings[TypeToDefineName],
		NStr("ru = 'в определяемый тип %1 добавить типы:';
			|en = 'add types to the %1 type collection:';"));
	
EndProcedure

&AtClient
Procedure AddRequiredItemsDetails(Text, HeaderParameter, DescriptionOfElements, DescriptionHeader)
	
	DetailsToAdd = StringFunctionsClientServer.SubstituteParametersToString(DescriptionHeader, HeaderParameter);
	DetailsToAdd = "- " + TextWithIndent(DetailsToAdd, "	") + Chars.LF;
	DetailsToAdd = DetailsToAdd + "	" + TextWithIndent(DescriptionOfElements, "	");
	
	Text = Text + Chars.LF + "	" + TextWithIndent(DetailsToAdd, "	") + Chars.LF;
	
EndProcedure

&AtClientAtServerNoContext
Function TextWithIndent(Text, Indent)
	
	Return StrReplace(Text, Chars.LF, Chars.LF + Indent);
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateItemAvailability(Context)
	
	Items = Context.Items;
	Items.ReadyConfigurationFileDumpFolder.Enabled = Not Context.ExportToTemporaryFolder;
	
	If Context.RestrictionsSource = "FromConfigurationDumpToFiles" Then
		Items.GetRestrictions.CurrentPage = Items.RestrictionsFromExport;
	Else
		Items.GetRestrictions.CurrentPage = Items.RestrictionsFromList;
	EndIf;
	
EndProcedure

&AtClient
Procedure DirectoryForPreparedConfigurationDumpToFilesStartChoiceAfterChoice(SelectedFiles, Context) Export
	
	If TypeOf(SelectedFiles) = Type("Array") Then
		ReadyConfigurationFileDumpFolder = SelectedFiles[0];
	EndIf;
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

&AtClient
Procedure GenerateDescription(FullDetails = True)
	
	ExistingDescription = "";
	FillMetadataObjectsAccessRestrictionKinds(ExistingDescription);
	
	If RestrictionsSource <> "FromConfigurationDumpToFiles"
	   And AllAccessRestrictions.TableHeight = 0 Then
		
		ShowMessageBox(,
			NStr("ru = 'Требуется заполнение табличного
			           |документа ""Все ограничения доступа"".
			           |Инструкции см. выше.';
						|en = 'It is required that you fill in spreadsheet
						|document ""All access restrictions"".
						|See the instructions above.';"));
		Return;
	EndIf;
	
	NewDetails = NewRightsRestrictionsTypesDescription();
	If NewDetails = Undefined Then
		Return;
	EndIf;
	
	If FullDetails Then
		Text = New TextDocument;
		Text.AddLine(
		"	LongDesc =
		|	""");
		
		Text.AddLine(NewDetails);
		Text.AddLine(
		"	|"";");
		
		Text.Show(NStr("ru = 'Описание видов ограничений прав объектов метаданных';
							|en = 'Details of restriction kinds of metadata object rights';"));
		Return;
	EndIf;
	
	MissingRows = "";
	CountOfRows = StrLineCount(NewDetails);
	For LineNumber = 1 To CountOfRows Do
		String = StrGetLine(NewDetails, LineNumber);
		If StrFind(ExistingDescription, Mid(String, 3)) = 0 Then
			MissingRows = MissingRows + String + Chars.LF;
		EndIf;
	EndDo;
	
	UnnecessaryRows = "";
	CountOfRows = StrLineCount(ExistingDescription);
	For LineNumber = 1 To CountOfRows Do
		String = "	|" + StrGetLine(ExistingDescription, LineNumber);
		If StrFind(NewDetails, TrimR(String)) = 0 Then
			UnnecessaryRows = UnnecessaryRows + String + Chars.LF;
		EndIf;
	EndDo;
	
	Text = New TextDocument;
	
	Text.AddLine(NStr("ru = 'Недостающие виды ограничений прав объектов метаданных:';
								|en = 'Missing right restriction kinds of metadata objects:';"));
	Text.AddLine(TrimR(MissingRows));
	Text.AddLine("");
	
	Text.AddLine(NStr("ru = 'Лишние виды ограничений прав объектов метаданных:';
								|en = 'Excess right restriction kinds of metadata objects:';"));
	Text.AddLine(TrimR(UnnecessaryRows));
	Text.AddLine("");
	
	Text.Show(NStr("ru = 'Недостающие и лишние виды ограничений прав объектов метаданных';
						|en = 'Missing and excess right restriction kinds of metadata objects';"));

EndProcedure


&AtServerNoContext
Procedure FillMetadataObjectsAccessRestrictionKinds(ExistingDescription)
	
	List = AccessManagementInternalCached.PermanentMetadataObjectsRightsRestrictionsKinds(True);
	If TypeOf(List) = Type("String") Then
		ExistingDescription = List;
		Return;
	EndIf;
	
	For Each String In List Do
		ExistingDescription = ExistingDescription
			+ String.FullTableName + "." + String.Right + "." + String.AccessKindName
			+ ?(ValueIsFilled(String.FullObjectTableName), "." + String.FullObjectTableName, "")
			+ Chars.LF;
	EndDo;
	
EndProcedure

&AtClient
Function NewRightsRestrictionsTypesDescription()
	
	AccessRestrictionKinds.Clear();
	
	ErrorsInDataExported = "";
	DefineAccessRestrictionsKindsAtServer(ErrorsInDataExported);
	If ValueIsFilled(ErrorsInDataExported) Then
		TextDocument = New TextDocument;
		TextDocument.AddLine(ErrorsInDataExported);
		If RestrictionsSource = "FromConfigurationDumpToFiles" Then
			DocumentTitle = NStr("ru = 'Ошибки при загрузке ограничений из файлов выгрузки конфигурации';
										|en = 'Errors occurred when importing restrictions from configuration export files';");
		Else
			DocumentTitle = NStr("ru = 'Ошибки при разборе ограничений, вставленных в табличный документ';
										|en = 'Errors occurred when parsing restrictions inserted into the spreadsheet document.';");
		EndIf;
		TextDocument.Show(DocumentTitle);
		Return Undefined;
	EndIf;
	
	For Each String In AccessRestrictionKinds Do
		If Upper(Left(String.Table, StrLen("Catalog."))) = Upper("Catalog.") Then
			String.CollectionOrder = 1;
			
		ElsIf Upper(Left(String.Table, StrLen("Document."))) = Upper("Document.") Then
			String.CollectionOrder = 2;
			
		ElsIf Upper(Left(String.Table, StrLen("DocumentJournal."))) = Upper("DocumentJournal.") Then
			String.CollectionOrder = 3;
			
		ElsIf Upper(Left(String.Table, StrLen("ChartOfCharacteristicTypes."))) = Upper("ChartOfCharacteristicTypes.") Then
			String.CollectionOrder = 4;
			
		ElsIf Upper(Left(String.Table, StrLen("ChartOfAccounts."))) = Upper("ChartOfAccounts.") Then
			String.CollectionOrder = 5;
			
		ElsIf Upper(Left(String.Table, StrLen("ChartOfCalculationTypes."))) = Upper("ChartOfCalculationTypes.") Then
			String.CollectionOrder = 6;
			
		ElsIf Upper(Left(String.Table, StrLen("InformationRegister."))) = Upper("InformationRegister.") Then
			String.CollectionOrder = 7;
			
		ElsIf Upper(Left(String.Table, StrLen("AccumulationRegister."))) = Upper("AccumulationRegister.") Then
			String.CollectionOrder = 8;
			
		ElsIf Upper(Left(String.Table, StrLen("AccountingRegister."))) = Upper("AccountingRegister.") Then
			String.CollectionOrder = 9;
			
		ElsIf Upper(Left(String.Table, StrLen("CalculationRegister."))) = Upper("CalculationRegister.") Then
			String.CollectionOrder = 10;
			
		ElsIf Upper(Left(String.Table, StrLen("BusinessProcess."))) = Upper("BusinessProcess.") Then
			String.CollectionOrder = 11;
			
		ElsIf Upper(Left(String.Table, StrLen("Task."))) = Upper("Task.") Then
			String.CollectionOrder = 12;
			
		EndIf;
		
		If String.Right = "Read" Then
			String.RightsOrder = 1;
		Else
			String.RightsOrder = 2;
		EndIf;
	EndDo;
	
	AccessRestrictionKinds.Sort("CollectionOrder Asc, Table Asc, RightsOrder Asc, AccessKind Asc, ObjectTable Asc");
	
	NewDetails = "";
	
	For Each String In AccessRestrictionKinds Do
		
		NewDetails = NewDetails
			+ "	|"
			+ String.Table
			+ "." + String.Right
			+ "." + String.AccessKind
			+ ?(ValueIsFilled(String.ObjectTable), "." + String.ObjectTable, "")
			+ Chars.LF;
		
	EndDo;
	
	Return TrimR(NewDetails);
	
EndFunction

#EndRegion

&AtServerNoContext
Function DetailsOfInitialProfilesFillingInIntegratedLanguage(SpecificProfile)
	
	Query = New Query;
	Query.SetParameter("ProfileAdministrator", AccessManagement.ProfileAdministrator());
	Query.Text =
	"SELECT
	|	Profiles.Ref AS Ref
	|FROM
	|	Catalog.AccessGroupProfiles AS Profiles
	|WHERE
	|	Profiles.Ref <> &ProfileAdministrator
	|	AND NOT Profiles.DeletionMark
	|	AND NOT Profiles.IsFolder
	|	AND Profiles.Ref IN(&SpecificProfile)";
	
	Table = NewProfileTable();
	
	If ValueIsFilled(SpecificProfile) Then
		Query.SetParameter("SpecificProfile", SpecificProfile);
	Else
		Query.Text = StrReplace(Query.Text, "Profiles.Ref IN(&SpecificProfile)", "TRUE");
	EndIf;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		AddDescriptionOfInitialFillingOfProfileInBuiltInLanguage(Table, Selection.Ref);
	EndDo;
	
	Table.Sort("IsFolder Desc, OrderingKey Asc");
	
	Return Chars.LF
		+ StrConcat(Table.UnloadColumn("LongDesc"), Chars.LF + Chars.LF)
		+ Chars.LF;
	
EndFunction

// Returns:
//  ValueTable:
//   * Ref           - CatalogRef.AccessGroupProfiles
//   * IsFolder        - Boolean
//   * OrderingKey - String
//   * Name              - String
//   * LongDesc         - String
//
&AtServerNoContext
Function NewProfileTable()
	
	Table = New ValueTable;
	Table.Columns.Add("Ref",           New TypeDescription("CatalogRef.AccessGroupProfiles"));
	Table.Columns.Add("IsFolder",        New TypeDescription("Boolean"));
	Table.Columns.Add("OrderingKey", New TypeDescription("String"));
	Table.Columns.Add("Name",              New TypeDescription("String"));
	Table.Columns.Add("LongDesc",         New TypeDescription("String"));
	
	Return Table;
	
EndFunction

&AtServerNoContext
Procedure AddDescriptionOfInitialFillingOfProfileInBuiltInLanguage(Table, ProfileReference, OrderingKey = "")
	
	If Table.Find(ProfileReference, "Ref") <> Undefined Then
		Return;
	EndIf;
	
	Profile = ProfileReference.GetObject(); // CatalogObject.AccessGroupProfiles
	
	If ValueIsFilled(Profile.Parent) Then
		AddDescriptionOfInitialFillingOfProfileInBuiltInLanguage(Table, Profile.Parent, OrderingKey);
	EndIf;
	OrderingKey = OrderingKey + " \ " + Profile.Description;
	
	SuppliedDataID = String(Profile.SuppliedDataID);
	
	ProfilesDetails = AccessManagementInternal.SuppliedProfiles().ProfilesDetails;
	ProfileProperties = ProfilesDetails.Get(SuppliedDataID); // See Catalogs.AccessGroupProfiles.SuppliedProfileProperties
	
	Name = Profile.PredefinedDataName;
	
	If Not ValueIsFilled(Name)
	   And ProfileProperties <> Undefined
	   And ValueIsFilled(ProfileProperties.Name) Then
		
		Name = ProfileProperties.Name;
	EndIf;
	
	If Profile.SuppliedDataID
		= CommonClientServer.BlankUUID() Then
		
		Id = String(Profile.Ref.UUID());
	Else
		Id = String(Profile.SuppliedDataID);
	EndIf;
	
	If Profile.IsFolder And Not ValueIsFilled(Name) Then
		Name = NameFromSynonym(Profile.Description);
		Number = 2;
		While Table.Find(Name, "Name") <> Undefined Do
			Name = Name + Format(Number, "NG=");
			Number = Number + 1;
		EndDo;
	EndIf;
	
	Rows = New Array;
	If Profile.IsFolder Then
		Rows.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"	// Folder profiles ""%1"".", Profile.Description));
		Rows.Add(
			"	FolderDescription_ = AccessManagement.NewDescriptionOfTheAccessGroupProfilesFolder();");
	Else
		Rows.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"	// Profile ""%1"".", Profile.Description));
		Rows.Add(
			"	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();");
	EndIf;
	
	If ValueIsFilled(Name) Then
		Rows.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"	%ProfileDetails%.Name           = ""%1"";", Name));
	EndIf;
	
	If ValueIsFilled(Profile.Parent) Then
		ParentName = Table.Find(Profile.Parent, "Ref").Name;
		Rows.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"	%ProfileDetails%.Parent      = ""%1"";", ParentName));
	EndIf;
	
	Rows.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"	%ProfileDetails%.Id = ""%1"";", Id));
	
	Rows.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"	%ProfileDetails%.Description  =
			|		NStr(""ru = '%1'"",
			|			Common.DefaultLanguageCode());", Profile.Description));
	
	If Not Profile.IsFolder Then
		AddDescriptionOfDestination(Rows, Profile);
		AddDescriptionOfSuppliedProfile(Rows, ProfileProperties);
		AddDescriptionOfRolesAndAccessTypes(Rows, Profile);
	EndIf;
	
	Rows.Add(
		"	ProfilesDetails.Add(%ProfileDetails%);");
	
	Text = StrConcat(Rows, Chars.LF);
	
	Text = StrReplace(Text, "%ProfileDetails%",
		?(Profile.IsFolder, "FolderDescription_", "ProfileDetails"));
	
	NewRow = Table.Add();
	NewRow.Ref = ProfileReference;
	NewRow.Name = Name;
	NewRow.LongDesc = Text;
	NewRow.IsFolder = Profile.IsFolder;
	NewRow.OrderingKey = OrderingKey;
	
EndProcedure

&AtServerNoContext
Function NameFromSynonym(Synonym)
	
	Separators = " " + Chars.NBSp + Chars.Tab;
	Words = StrSplit(Synonym, Separators, False);
	For IndexOf = 0 To Words.UBound() Do
		Word = TrimAll(Words[IndexOf]);
		Words[IndexOf] = Upper(Left(Word, 1)) + Lower(Mid(Word, 2));
	EndDo;
	
	Return StrConcat(Words);
	
EndFunction

&AtServerNoContext
Procedure AddDescriptionOfDestination(Rows, Profile)
	
	Purpose = New Array;
	For Each String In Profile.Purpose Do
		Type = TypeOf(String.UsersType);
		If Not Common.IsReference(Type) Then
			Continue;
		EndIf;
		ObjectManager = Common.ObjectManagerByRef(String.UsersType);
		EmptyObjectRef = ObjectManager.EmptyRef();
		If Purpose.Find(EmptyObjectRef) = Undefined Then
			Purpose.Add(EmptyObjectRef);
		EndIf;
	EndDo;
	
	If Purpose.Count() = 1
	   And Purpose.Find(Catalogs.Users.EmptyRef()) <> Undefined Then
		
		Return;
	EndIf;
	
	Rows.Add("	// Redefine assignments.");
	
	For Each CurAssignment In Purpose Do
		RefTypeName1 = Common.TypePresentationString(TypeOf(CurAssignment));
		Rows.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"	ProfileDetails.Purpose.Add(Type(""%1""));", RefTypeName1));
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure AddDescriptionOfSuppliedProfile(Rows, ProfileProperties)
	
	SuppliedProfileDetails = "";
	If ProfileProperties <> Undefined Then
		SuppliedProfilesNote = AccessManagementInternalCached.SuppliedProfilesNote();
		SuppliedProfileDetails = SuppliedProfilesNote.Get(ProfileProperties.Id);
	EndIf;
	
	LongDesc = "";
	For LineNumber = 1 To StrLineCount(SuppliedProfileDetails) Do
		If ValueIsFilled(LongDesc) Then
			LongDesc = LongDesc
			+ "
			  		           |";
		EndIf;
		LongDesc = LongDesc + StrGetLine(SuppliedProfileDetails, LineNumber);
	EndDo;
	
	Rows.Add(StringFunctionsClientServer.SubstituteParametersToString(
		"	ProfileDetails.LongDesc =
		|		NStr(""ru = '%1'"");", LongDesc));
	
EndProcedure

&AtServerNoContext
Procedure AddDescriptionOfRolesAndAccessTypes(Rows, Profile)
	
	RolesDetails = New ValueList;
	RoleIDs = Profile.Roles.Unload().UnloadColumn("Role");
	RolesNames = Common.ObjectsAttributeValue(RoleIDs, "Name");
	For Each RoleDetails In Profile.Roles Do
		RolesDetails.Add(RolesNames.Get(RoleDetails.Role));
	EndDo;
	RolesDetails.SortByValue();
	
	For Each RoleDetails In RolesDetails Do
		Rows.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"	ProfileDetails.Roles.Add(""%1"");", RoleDetails.Value));
	EndDo;
	
	For Each AccessKindDetails In Profile.AccessKinds Do
		
		AccessKindName = AccessManagementInternal.AccessKindProperties(AccessKindDetails.AccessKind).Name;
		
		Rows.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"	ProfileDetails.AccessKinds.Add(""%1"");", AccessKindName
					+ ?(AccessKindDetails.Predefined, """, ""Predefined",
							?(AccessKindDetails.AllAllowed, """, ""AllAllowedByDefault", ""))));
		
		Filter = New Structure("AccessKind", AccessKindDetails.AccessKind);
		AccessValuesDetails = Profile.AccessValues.FindRows(Filter);
		
		For Each AccessValueDetails In AccessValuesDetails Do
			If Not ValueIsFilled(AccessValueDetails.AccessValue) Then
				Continue;
			EndIf;
			ValueMetadata = AccessValueDetails.AccessValue.Metadata();
			If Metadata.Enums.Find(ValueMetadata.Name) = ValueMetadata Then
				AccessValueName = Common.EnumerationValueName(AccessValueDetails.AccessValue);
			Else
				AccessValueName = Common.ObjectAttributeValue(
					AccessValueDetails.AccessValue, "PredefinedDataName");
			EndIf;
			If Not ValueIsFilled(AccessValueName) Then
				Continue;
			EndIf;
			ValueTableName1 = Common.TableNameByRef(AccessValueDetails.AccessValue);
			FullAccessValueName = ValueTableName1 + "." + AccessValueName;
			Rows.Add(StringFunctionsClientServer.SubstituteParametersToString(
				"	ProfileDetails.AccessValues.Add(""%1"",
				|		""%2"");", AccessKindName, FullAccessValueName));
		EndDo;
	EndDo;
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

&AtServer
Procedure DefineAccessRestrictionsKindsAtServer(ErrorsInDataExported)
	
	AccessRestrictions = AccessRestrictions(ErrorsInDataExported);
	If ValueIsFilled(ErrorsInDataExported) Then
		Return;
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("AccessRestrictions",  AccessRestrictions);
	ProcedureParameters.Insert("AccessRestrictionKinds", AccessRestrictionKinds);
	
	DataProcessor = FormAttributeToValue("Object");
	DataProcessor.DefineTypesOfRightsRestrictions(ProcedureParameters);
	
EndProcedure

#EndRegion

// Returns a table with the fields Table, Role, Right, Fields, and Restriction.
// Same as the output of Designer list "All access restrictions" to a spreadsheet document.
//
// Parameters:
//  ExportFolder - String - Directory containing configuration data exported to files.
//                    If it is not a blank string, the export will be made to a temporary directory.
//
&AtServer
Function AccessRestrictions(ErrorsInDataExported)
	
	If RestrictionsSource = "FromConfigurationDumpToFiles" Then
		UploadFolder = ?(ExportToTemporaryFolder, "", ReadyConfigurationFileDumpFolder);
		Return FormAttributeToValue("Object").AccessRestrictionsFromUploadingConfigurationToFiles(UploadFolder, ErrorsInDataExported);
	Else
		Return AccessRestrictionsFromSpreadsheetDocument(ErrorsInDataExported);
	EndIf;
	
EndFunction

&AtServer
Function AccessRestrictionsFromSpreadsheetDocument(ErrorsInDataExported)
	
	Table = New ValueTable;
	Table.Columns.Add("Table",     New TypeDescription("String"));
	Table.Columns.Add("Role",        New TypeDescription("String"));
	Table.Columns.Add("Right",       New TypeDescription("String"));
	Table.Columns.Add("Fields",        New TypeDescription("String"));
	Table.Columns.Add("Restriction", New TypeDescription("String"));
	
	Rights = New Map;
	Rights.Insert(Upper("Read"),     True);
	Rights.Insert(Upper("Update"),  True);
	Rights.Insert(Upper("Create"), True);
	Rights.Insert(Upper("Delete"),   True);
	
	For LineNumber = 2 To AllAccessRestrictions.TableHeight Do
		
		Properties = New Structure("Table, Role, Right, Fields, Restriction");
		Properties.Table     = AllAccessRestrictions.Area("R" + Format(LineNumber,"NG=") + "C1").Text;
		Properties.Role        = AllAccessRestrictions.Area("R" + Format(LineNumber,"NG=") + "C2").Text;
		Properties.Right       = AllAccessRestrictions.Area("R" + Format(LineNumber,"NG=") + "C3").Text;
		Properties.Fields        = AllAccessRestrictions.Area("R" + Format(LineNumber,"NG=") + "C4").Text;
		Properties.Restriction = AllAccessRestrictions.Area("R" + Format(LineNumber,"NG=") + "C5").Text;
		
		If Not ValueIsFilled(Properties.Table)
		   And Not ValueIsFilled(Properties.Role)
		   And Not ValueIsFilled(Properties.Right)
		   And Not ValueIsFilled(Properties.Fields)
		   And Not ValueIsFilled(Properties.Restriction) Then
			
			Continue;
		EndIf;
		
		HasError = False;
		
		MetadataTables = Common.MetadataObjectByFullName(Properties.Table);
		RoleMetadata    = Metadata.Roles.Find(Properties.Role);
		
		If MetadataTables = Undefined Then
			AddError(ErrorsInDataExported, LineNumber, HasError, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось найти объект метаданных ""%1"".';
					|en = 'Cannot find the ""%1"" metadata object.';"), Properties.Table));
		EndIf;
		
		If RoleMetadata = Undefined Then
			AddError(ErrorsInDataExported, LineNumber, HasError, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось найти роль ""%1"".';
					|en = 'Cannot find role %1.';"), Properties.Role));
		EndIf;
		
		If Rights.Get(Upper(Properties.Right)) = Undefined Then
			AddError(ErrorsInDataExported, LineNumber, HasError, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Некорректное имя права ""%1"".';
					|en = 'Incorrect %1 right name.';"), Properties.Right));
		EndIf;
		
		If HasError Then
			Continue;
		EndIf;
		
		If Not AccessRight(Properties.Right, MetadataTables, RoleMetadata) Then
			Continue;
		EndIf;
		
		FillPropertyValues(Table.Add(), Properties);
	EndDo;
	
	Return Table;
	
EndFunction

&AtServer
Procedure AddError(ErrorsInDataExported, LineNumber, HasError, ErrorDescription)
	
	HasError = True;
	
	ErrorsInDataExported = ErrorsInDataExported  + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'В строке %1 табличного документа обнаружена ошибка:
		           |%2';
					|en = 'Error is detected in row %1 of the spreadsheet document:
					|%2';"), Format(LineNumber, "NG="), ErrorDescription) + Chars.LF;
	
EndProcedure

&AtClient
Procedure SetItemsVisibility()
	Items.PathToPreviousConfigurationVersionFile.Visible = ComparisonSource = "File";
	Items.FolderForPreviousRLSTextExport.Visible = ComparisonSource = "Folder";
EndProcedure

&AtClient
Function Quote(String)
	Return """" + StrReplace(String, """", """""") + """";
EndFunction

#If Not WebClient Then

&AtClient
Procedure ReadStartupParameters()
	
	If StrFind(LaunchParameter, "ReferenceDescriptionFolder") = 0
		And StrFind(LaunchParameter, "NewDescriptionFolder") = 0 Then
		Return;
	EndIf;
	
	ParametersDetails = StrSplit(LaunchParameter, ";", False);
	ParametersCollection = New Structure;
	
	For Each LongDesc In ParametersDetails Do
		StringParts1 = StrSplit(LongDesc, "=", True);
		ParameterName = StringParts1[0];
		ParameterValue = True;
		If StringParts1.Count() > 1 Then
			ParameterValue = StringParts1[1];
		EndIf;
		ParametersCollection.Insert(ParameterName, ParameterValue);
	EndDo;
	
	FillPropertyValues(ThisObject, ParametersCollection);
	FillPropertyValues(Object, ParametersCollection);
	
EndProcedure

&AtClient
Procedure OnFolderChoice(SelectedFiles, Var_AttributeName) Export
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	ThisObject[Var_AttributeName] = SelectedFiles[0] + GetPathSeparator();
EndProcedure

&AtClient
Procedure OnSelectConfigurationFile(SelectedFiles, Var_AttributeName) Export
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	PathToPreviousConfigurationVersionFile = SelectedFiles[0];
EndProcedure

&AtClient
Procedure StartRestrictionsTextsExport()
	DeleteExportFolder = False;
	If Not ValueIsFilled(Object.ConfigurationExportFolder) Then
		DeleteExportFolder = True;
		Object.ConfigurationExportFolder = GetTempFileName("cf") + GetPathSeparator();
		CreateDirectory(Object.ConfigurationExportFolder);
		
		ConnectionString = InfoBaseConnectionString();
		If DesignerIsOpen() Then
			If CommonClient.FileInfobase() Then
				InfobaseDirectory = StringFunctionsClientServer.ParametersFromString(ConnectionString).file;
				FileCopy(InfobaseDirectory + "\1Cv8.1CD", Object.ConfigurationExportFolder + "\1Cv8.1CD");
				ConnectionString = StringFunctionsClientServer.SubstituteParametersToString("File=""%1"";", Object.ConfigurationExportFolder);
			Else
				ErrorText = NStr("ru = 'Для сравнения текстов RLS закройте конфигуратор.';
									|en = 'To compare RLS texts, close Designer.';");
				Raise ErrorText;
			EndIf;
		EndIf;
		
		AddConnection("ThisConfiguration", ConnectionString, UserName());
		DumpConfigurationToFiles("ThisConfiguration", Object.ConfigurationExportFolder, , AllRoles());
	EndIf;
	
	ExportRestrictionsTexts();
	
	If DeleteExportFolder Then
		DeleteFiles(Object.ConfigurationExportFolder);
	EndIf;
EndProcedure

&AtServer
Procedure ExportRestrictionsTexts()
	DataProcessorObject = FormAttributeToValue("Object");
	DataProcessorObject.ExportRestrictionsTexts();
EndProcedure

&AtClient
Function ReadFile(FileName)
	// ACC:566-off - A development tool
	File = New File(FileName);
	If Not File.Exists() Then
		Return "";
	EndIf;
	
	TextReader = New TextReader(FileName);
	Result = TextReader.Read();
	TextReader.Close();
	// ACC:566-on
	Return Result;
EndFunction

&AtClient
Procedure ReadDifferences()
	DifferencesFound.Clear();
	PreviousText = "";
	CurrentText = "";
	
	If Not ValueIsFilled(Object.NewDescriptionFolder) Then
		Return;
	EndIf;
	
	FileName = Object.NewDescriptionFolder + "Otherness.txt";
	FileContent = ReadFile(FileName);
	TablesList = StrSplit(FileContent, Chars.LF);
	For Each Table In TablesList Do
		DifferencesFound.Add(Table);
	EndDo;
	
	If DifferencesFound.Count() > 0 Then
		Items.DifferencesFound.CurrentRow = DifferencesFound[0].GetID();
	EndIf;
EndProcedure

&AtClient
Procedure ExportRestrictionsTextsFromConfigurationFile()
	
	IBDirectory1 = GetTempFileName("db");
	
	AddConnection("PreviousConfiguration", "File=""" + IBDirectory1 + """");
	CreateNewIB("PreviousConfiguration", PathToPreviousConfigurationVersionFile);
	
	StartupKeys = New Structure;
	StartupKeys.Insert("DisableSystemStartupLogic");
	StartupKeys.Insert("ConfigurationExportFolder", "");
	StartupKeys.Insert("ReferenceDescriptionFolder", "");
	StartupKeys.Insert("NewDescriptionFolder", Object.ReferenceDescriptionFolder);
	
	StartupKey = StartupParametersAsString(StartupKeys);
	
	ClientStartupParameters = ClientStartupParameters("PreviousConfiguration", StartupKey, DataProcessorFileName, True, False);
	StartEnterprise(ClientStartupParameters);
	
	DeleteFiles(IBDirectory1);
	
EndProcedure

&AtClient
Function StartupParametersAsString(StartupParameters)
	Rows = New Array;
	For Each Parameter In StartupParameters Do
		Rows.Add(Parameter.Key + ?(Parameter.Value = Undefined, "", "=" + Parameter.Value));
	EndDo;
	Return StrConcat(Rows, ";");
EndFunction

&AtServerNoContext
Function AllRoles()
	Result = New Array;
	For Each Role In Metadata.Roles Do
		If Role.ConfigurationExtension() = Undefined Then
			Result.Add(Role.FullName());
		EndIf;
	EndDo;
	Return Result;
EndFunction

&AtServerNoContext
Function DesignerIsOpen()
	For Each Session In GetInfoBaseSessions() Do
		If Upper(Session.ApplicationName) = Upper("Designer") Then
			Return True;
		EndIf;
	EndDo;
	Return False;
EndFunction

#Region BatchMode

#Region OneCEnterpriseCommandLine

&AtClient
Procedure CreateNewIB(ConnectionName, TemplateFileName1 = "")
	
	Connection = ConnectionSettings(ConnectionName);
	
	Cancel = True;
	If StrStartsWith(Lower(Connection.ConnectionString), Lower("File=")) Then
		Position = StrFind(Connection.ConnectionString, """");
		If Position > 0 Then
			FileBasePath = Mid(Connection.ConnectionString, Position + 1);
			Position = StrFind(FileBasePath, """");
			If Position > 0 Then
				FileBasePath = Left(FileBasePath, Position - 1);
				CreateBaseDirectory(FileBasePath);
				Cancel = False;
			EndIf;
		EndIf;
	EndIf;
	
	If Cancel Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Строка соединения ИБ ""%1"" указана неверно:';
				|en = 'Infobase connection string ""%1"" is specified incorrectly:';"), ConnectionName) + Chars.LF
			+ Connection.ConnectionString;
		Raise ErrorText;
	EndIf;
	
	StartupParameters = New Array;
	StartupParameters.Add(Quote(BinDir() + "1cv8.exe"));
	StartupParameters.Add("CREATEINFOBASE");
	StartupParameters.Add(Quote(Connection.ConnectionString));
	
	If ValueIsFilled(TemplateFileName1) Then
		StartupParameters.Add("/UseTemplate " + Quote(TemplateFileName1));
	EndIf;
	
	StartEnterprise(StartupParameters);
	
EndProcedure

&AtClient
Function ClientStartupParameters(ConnectionName, StartupKey, DataProcessorName = "", ProhibitScheduledJobsStart = False,
	UseAuthorization = True)
	
	Connection = ConnectionSettings(ConnectionName);
	
	StartupParameters = New Array;
	StartupParameters.Add(Quote(PathToExecutablePlatformFile("ThinClient")));
	StartupParameters.Add("ENTERPRISE");
	StartupParameters.Add("/IBConnectionString " + Quote(Connection.ConnectionString));
	
	If ValueIsFilled(Connection.AreaNumber) Then 
		StartupParameters.Add("/Z-,+" + Connection.AreaNumber);
	EndIf;
	
	If UseAuthorization And ValueIsFilled(Connection.Login) Then 
		StartupParameters.Add("/N "+ Quote(Connection.Login));
		If ValueIsFilled(Connection.Password) Then 
			StartupParameters.Add("/P "+ Quote(Connection.Password));
		EndIf;
	EndIf;
	
	If ValueIsFilled(StartupKey) Then
		StartupParameters.Add("/C "+ Quote(StartupKey));
	EndIf;
	
	If ValueIsFilled(DataProcessorName) Then
		StartupParameters.Add("/Execute "+ Quote(DataProcessorName));
	EndIf;
	
	If ProhibitScheduledJobsStart Then
		StartupParameters.Add("/AllowExecuteScheduledJobs -Off"); // "-Off" case-sensitive.
	EndIf;
	
	StartupParameters.Add("/DisableStartupMessages");
	StartupParameters.Add("/DisableStartupDialogs");
	
	Return StartupParameters;
	
EndFunction

&AtClient
Function DesignerStartupParameters(ConnectionName, InteractiveLaunch = False)
	
	Connection = ConnectionSettings(ConnectionName);
	
	StartupParameters = New Array;
	StartupParameters.Add(Quote(PathToExecutablePlatformFile()));
	StartupParameters.Add("DESIGNER");
	StartupParameters.Add("/IBConnectionString " + Quote(Connection.ConnectionString));
	
	If ValueIsFilled(Connection.Login) Then 
		StartupParameters.Add("/N "+ Quote(Connection.Login));
		If ValueIsFilled(Connection.Password) Then 
			StartupParameters.Add("/P "+ Quote(Connection.Password));
		EndIf;
	EndIf;
	
	If Not InteractiveLaunch Then
		StartupParameters.Add("/DisableStartupMessages");
		StartupParameters.Add("/DisableStartupDialogs");
	EndIf;
	
	Return StartupParameters;
EndFunction

&AtClient
Procedure DumpConfigurationToFiles(ConnectionName, UploadFolder, ExportAsFlatList = False, ListOfObjects = Undefined)
	
	ParameterString = "/DumpConfigToFiles " + Quote(UploadFolder);
	
	ListFileName = "";
	If ValueIsFilled(ListOfObjects) Then
		ListFileName = GetTempFileName();
		TextWriter = New TextWriter(ListFileName);
		TextWriter.WriteLine(StrConcat(ListOfObjects, Chars.LF));
		TextWriter.Close();
		ParameterString = ParameterString + " -listFile " + Quote(ListFileName);
	EndIf;
	
	StartupParameters = DesignerStartupParameters(ConnectionName);
	StartupParameters.Add(ParameterString);
	If ExportAsFlatList Then
		StartupParameters.Add("-Format ""Plain""");
	EndIf;
	StartEnterprise(StartupParameters);
	
	If ValueIsFilled(ListFileName) Then
		DeleteFiles(ListFileName);
	EndIf;
	
EndProcedure

&AtClient
Procedure StartEnterprise(StartupParameters)
	
#If MobileClient Then
	ShowMessageBox(, NStr("ru = 'Инструмент ""Управление доступом""  в веб-клиенте и мобильном клиенте, используйте тонкий клиент.';
									|en = 'The ""Access management"" tool is not available in the web client and mobile client. Use the thin client.';"));
	Return;
#Else
	LogFileName1 = GetTempFileName("txt");
	StartupParameters.Add("/Out " + Quote(LogFileName1));
	
	CommandLine1 = StrConcat(StartupParameters, " ");
	ReturnCode = 0;
	Try
		// ACC:534-off - The startup string is safe.
		RunApp(CommandLine1,, True, ReturnCode);
		// ACC:534-on
	Except
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не удалось запустить:
			|%1
			|по причине: 
			|%2';
			|en = 'Cannot start:
			|%1
			|due to: 
			|%2';"), 
			CommandLine1, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If ReturnCode <> 0 Then
		StartLog = ReadFile(LogFileName1);
		ErrorText = NStr("ru = 'Операция не выполнена.';
							|en = 'Operation failed.';") + Chars.LF 
			+ NStr("ru = 'Строка запуска:';
					|en = 'Launch string:';") + Chars.LF 
			+ CommandLine1 + Chars.LF 
			+ NStr("ru = 'Код возврата:';
					|en = 'Return code:';")+ " " + ReturnCode + Chars.LF
			+ NStr("ru = 'Содержимое лога';
					|en = 'Log entries';") + " " + LogFileName1 + ":" + Chars.LF
			+ StartLog;
		Raise ErrorText;
	EndIf;
	
	DeleteFiles(LogFileName1);
#EndIf

EndProcedure

&AtClient
Procedure CreateBaseDirectory(Path)
	// ACC:566-off - A development tool
	File = New File(Path);
	If File.Exists() Then
		DeleteFiles(Path);
	EndIf;
	LogFolder = Path + "\1Cv8Log";
	CreateDirectory(LogFolder);
	LogFileName = LogFolder + "\1Cv8.lgf";
	File = New File(LogFileName);
	If Not File.Exists() Then
		TextWriter = New TextWriter(Path + "\1Cv8Log\1Cv8.lgf", "windows-1251");
		TextWriter.Close();
	EndIf;
	// ACC:566-on
EndProcedure

#EndRegion

#Region OSCommandLine

&AtClient
Function PathToExecutablePlatformFile(Package = "")
	
	FileName = "1cv8.exe";
	If Package = "ThinClient" Then
		FileName = "1cv8c.exe";
	EndIf;
	
	PathToExecutableFile = BinDir() + FileName;
	
	Return PathToExecutableFile;

EndFunction

#EndRegion

#Region ConnectionsList

&AtClient
Function ConnectionsSettings()
	
	ParameterName = "Testing.ConnectionsSettings";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New Map);
	EndIf;
	
	Return ApplicationParameters[ParameterName];
	
EndFunction

&AtClient
Function ConnectionSettings(ConnectionName)
	
	ConnectionSettings = ConnectionsSettings()[ConnectionName];
	If ConnectionSettings = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Настройки подключения %1 не найдены.';
				|en = 'Connection settings %1 are not found.';"), ConnectionName);
		Raise ErrorText;
	EndIf;
	
	Return ConnectionSettings;
	
EndFunction

&AtClient
Procedure AddConnection(ConnectionName, ConnectionString, Login = "", Password = "")
	
	ConnectionSettings = ConnectionsSettings()[ConnectionName];
	If ConnectionSettings = Undefined Then
		ConnectionSettings = New Structure;
	EndIf;
	ConnectionSettings.Insert("ConnectionString", ConnectionString);
	ConnectionSettings.Insert("Login", Login);
	ConnectionSettings.Insert("Password", Password);
	ConnectionSettings.Insert("AreaNumber");
	ConnectionSettings.Insert("Platform");
	
	ConnectionsSettings().Insert(ConnectionName, ConnectionSettings);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

#EndRegion
