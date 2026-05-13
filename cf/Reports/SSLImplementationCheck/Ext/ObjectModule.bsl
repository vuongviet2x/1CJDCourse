///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

// 
// 
// 
// 
Var ExceptionsTable; // ValueTable
Var CheckedSubsystem; // MetadataObjectSubsystem
Var DumpDirectory; // String
Var TermsMap; // See MetadataObjectNamesMap
Var SubsystemsTree; // ValueTree
Var FilterBySubsystems; // Array of String
Var MatchingObjects; // See MatchingObjects
Var MetadataTypesMap; // Map
Var ValidMetadata; // Array of MetadataObject
Var CorrectErrors; // Boolean
Var FilesToUpload; // Array of String
Var SSLSubsystemObjects; // Array of MetadataObject
Var FixedErrors; // Array of String
Var NonVerifiableConfigurationSubsystems; // Array of String
Var InteractiveLaunch; // Boolean
Var MetadataObjectInConfigurationLanguageKindName; // See MetadataObjectInConfigurationLanguageKindName
Var ObjectInFileUploadKindName; // See ObjectInFileUploadKindName
Var HasSeparatorsCompositionErrors; // Boolean
Var EDTConfiguration; // Boolean
Var CanUseRegEx; // Boolean

#EndRegion

#Region Public

// Checks library integration into the consumer configuration.
//
// Parameters:
//   ConfigurationUploadDirectory - String - Configuration dump directory.
//   IncomingParameters - See IntegrationCheckParameters
//
// Returns:
//   String - if the CheckParameters.ResultAsString = False, a file name is returned with the check result.
//            Otherwise, a text of all found errors is returned.
//
Function CheckIntegration(ConfigurationUploadDirectory = "", IncomingParameters = Undefined) Export
	
	If Common.DataSeparationEnabled() Then
		Raise NStr("ru = 'Проверка внедрения в разделенном режиме не поддерживается.';
								|en = 'Cannot check integration in separated mode.';");
	EndIf;
	
	CheckParameters = IntegrationCheckParameters();
	If IncomingParameters <> Undefined Then
		FillPropertyValues(CheckParameters, IncomingParameters);
	EndIf;
	
	UploadConfigurationToXML(ConfigurationUploadDirectory);
	ExecuteCheck(CheckParameters);
	
	ImportChanges = Not EDTConfiguration And Not CheckParameters.NotImportChanges;
	If ImportChanges Then
		LoadConfigurationFromXML();
	EndIf;
	
	If IsBlankString(ConfigurationUploadDirectory) Then
		DeleteFiles(DumpDirectory);
	EndIf;
	
	If ValueIsFilled(CheckParameters.ListOfFilesToDownload) Then
		WriteListOfFilesToDownload(CheckParameters.ListOfFilesToDownload);
	EndIf;
	
	Return CheckResult(CheckParameters);
	
EndFunction


// A constructor of parameters to be passed to the "CheckImplementation" function.
// 
// Returns:
//   Structure:
//      * VerificationFileExtension  - String - Valid values are "xml" and "txt".
//                                            If specified, the check result is logged to a file with this extension.
//      * FullPathToCheckFile - String - Full name of the check file with the extension.
//                                            Ignored if the "CheckFileExtension" property is specified.
//      * ResultAsString         - Boolean - Return errors as a string. String type depends on the extension.
//      * CorrectErrors         - Boolean - True if 1C:Enterprise should try to autofix errors.
//      * FixedErrors       - Array of String - If "FixErrors" is set to "True", then error IDs. 
//                                            If the array is blank, 
//                                            fix all errors that can be fixed automatically.
//                                            See a checklist with fixed errors in the "ErrorsToFix" function.
//      * CheckedSubsystems    - Array of String - Names of subsystems whose integration to check.
//                                            If the array is empty, check all subsystems.
//      * NonVerifiableConfigurationSubsystems - Array of String - Names of the upper-level configuration subsystems 
//                                            that should ignore integration errors.
//      * NotImportChanges     - Boolean - "True" if 1C:Enterprise must skip import of changes.
//      * ExceptionsTable        - ValueTable:
//            * Subsystem              - String - Subsystem name. For example, "Properties".
//            * ConfigurationObject      - String - Full name of the object where an error occurred.
//            * BriefErrorDetails   - String - Brief error description. For example, "The required code is not inserted".
//            * DetailedErrorDetails - String - Detailed description.
//      * ListOfFilesToDownload  - String - Path to the file to write modified file list to.
//
Function IntegrationCheckParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("VerificationFileExtension", "");
	Parameters.Insert("FullPathToCheckFile", "");
	Parameters.Insert("ResultAsString", False);
	Parameters.Insert("CorrectErrors", False);
	Parameters.Insert("FixedErrors", New Array);
	Parameters.Insert("CheckedSubsystems", New Array);
	Parameters.Insert("NonVerifiableConfigurationSubsystems", New Array);
	Parameters.Insert("NotImportChanges", False);
	Parameters.Insert("ExceptionsTable", Undefined);
	Parameters.Insert("ListOfFilesToDownload", "");
	Parameters.Insert("OnlyInternalExtensionsAttached", False);
	
	Return Parameters;
	
EndFunction

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ReportsOptions

// Specify the report form settings.
//
// Parameters:
//   Form - ClientApplicationForm
//         - Undefined
//   VariantKey - String
//                - Undefined
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnDefineSelectionParameters     = True;
	Settings.Events.OnLoadVariantAtServer       = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
EndProcedure

// Runs before importing new settings. Intended to change the composition schema.
//   For example, when a report's schema depends on the option key or report parameters.
//   To apply schema changes, call the ReportsServer.EnableSchema() method.
//
// Parameters:
//   Context - Arbitrary - 
//       The context parameters where the report is used.
//       Intended to pass method ReportsServer.EnableSchema() into parameters.
//   SchemaKey - String -
//       ID of the current setting composer schema.
//       By default, empty (that means, the composer is initialized according to the main schema).
//       Intended to optimize and reinitialize the composer as infrequently as possible.
//       Not necessary if the initialization runs unconditionally.
//   VariantKey - String
//                - Undefined -
//       Either the name of a predefined report option or UUID of a custom report.
//       "Undefined" when calling for a drill-down option or without context.
//   NewDCSettings - DataCompositionSettings
//                    - Undefined -
//       The report option settings that should be imported into the settings composer after it is initialized.
//       "Undefined" if the option settings shouldn't be imported (have already been imported).
//   NewDCUserSettings - DataCompositionUserSettings
//                                    - Undefined -
//       The custom settings that should be imported into the settings composer after it is initialized.
//       "Undefined" if the custom settings shouldn't be imported (have already been imported).
//
// Example:
//  // The report composer is initialized based on the common template schema:
//	If SchemaKey <> "1" Then
//		SchemaKey = "1";
//		DCSchema = GetCommonTemplate("MyCommonCompositionSchema");
//		ReportsServer.EnableSchema(ThisObject, Context, DCSchema, SchemaKey);
//	EndIf;
//
//  // The schema depends on the parameter value that is displayed in the report user settings:
//	If TypeOf(NewDCSettings) = Type("DataCompositionUserSettings") Then
//		FullMetadataObjectName = "";
//		For Each DCItem From NewDCUserSettings.Items Do
//			If TypeOf(DCItem) = Type("DataCompositionSettingsParameterValue") Then
//				ParameterName = String(DCItem.Parameter);
//				If ParameterName = "MetadataObject" Then
//					FullMetadataObjectName = DCItem.Value;
//				EndIf;
//			EndIf;
//		EndDo;
//		If SchemaKey <> FullMetadataObjectName Then
//			SchemaKey = FullMetadataObjectName;
//			DCSchema = New DataCompositionSchema;
//			// Populate the schema…
//			ReportsServer.EnableSchema(ThisObject, Context, DCSchema, SchemaKey);
//		EndIf;
//	EndIf;
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If SchemaKey = VariantKey Then
		Return;
	EndIf;
	
	SchemaKey = VariantKey;
	SettingsItems = NewDCSettings.DataParameters.Items;
	
	IncludedSettingsIds = StrSplit("CheckedSubsystems, CorrectErrors", ", ", False);
	For Each Id In IncludedSettingsIds Do 
		
		SettingItem = SettingsItems.Find(Id);
		If SettingItem <> Undefined Then 
			
			UserSettingItem = UserSettingItem(
				NewDCUserSettings, Id);
			
			If UserSettingItem = Undefined Then 
				
				SettingItem.UserSettingID = New UUID;
				SettingItem.Use = False;
			Else
				SettingItem.UserSettingID =
					UserSettingItem.UserSettingID;
			EndIf;
			
			SettingItem.ViewMode = DataCompositionSettingsItemViewMode.QuickAccess;
		EndIf;
		
	EndDo;
	
	SettingItem = SettingsItems.Find("CorrectBooleanErrors");
	If SettingItem <> Undefined Then 
		SettingItem.UserSettingID = "";
	EndIf;
	
EndProcedure

// Called in the event handler of the report form after executing the form code.
// See "Client application form extension for reports.OnLoadVariantAtServer" in Syntax Assistant.
//
// Parameters:
//   Form - ClientApplicationForm - Report form.
//   NewDCSettings - DataCompositionSettings - Settings composer import settings.
//
Procedure OnLoadVariantAtServer(Form, NewDCSettings) Export
	
	If Common.FileInfobase() Then
		// Run background job without extensions. The report is generated in the foreground.
		Form.ReportSettings.Safe = True;
	EndIf;
	
EndProcedure

// See ReportsOverridable.OnDefineSelectionParameters.
Procedure OnDefineSelectionParameters(Form, SettingProperties) Export
	FieldName = String(SettingProperties.DCField);
	If FieldName = "DataParameters.CheckedSubsystems" Then
		SettingProperties.RestrictSelectionBySpecifiedValues = True;
		SettingProperties.ValuesForSelection.Clear();
		SubsystemsNames = New Array;
		AtDeterminingSubsystemsToBeChecked(SubsystemsNames);
		For Each Name In SubsystemsNames Do
			Subsystem = Metadata.Subsystems.StandardSubsystems.Subsystems.Find(Name);
			If Subsystem = Undefined Then
				Continue;
			EndIf;
			SettingProperties.ValuesForSelection.Add(Name, Subsystem.Presentation());
		EndDo;
	ElsIf FieldName = "DataParameters.CorrectErrors" Then
		SettingProperties.RestrictSelectionBySpecifiedValues = True;
		SettingProperties.ValuesForSelection.Clear();
		List = FixedErrors();
		For Each FixedError In List Do
			SettingProperties.ValuesForSelection.Add(FixedError.Value, FixedError.Presentation);
		EndDo;
	EndIf;
EndProcedure

// End StandardSubsystems.ReportsOptions

// StandardSubsystems.AdditionalReportsAndDataProcessors

// Returns info about an external report.
//
// Returns:
//   See AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo.
//
Function ExternalDataProcessorInfo() Export
	ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
	ModuleAdditionalReportsAndDataProcessorsClientServer = Common.CommonModule("AdditionalReportsAndDataProcessorsClientServer");
	RegistrationParameters = ModuleAdditionalReportsAndDataProcessors.ExternalDataProcessorInfo("3.0.1.1");
	
	RegistrationParameters.Kind = ModuleAdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalReport();
	RegistrationParameters.Version = "1.0";
	RegistrationParameters.DefineFormSettings = True;
	RegistrationParameters.SafeMode = False;
	
	Return RegistrationParameters;
EndFunction
// End StandardSubsystems.AdditionalReportsAndDataProcessors

#EndRegion

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	If ReportVersionDiffersFromLibraryVersion() Then
		Template = NStr("ru = 'Рекомендуется использовать версию отчета, совпадающую с используемой версией БСП.
			|Автоматическое исправление некоторых ошибок может быть недоступно.
			|
			|Версия отчета: %1
			|Версия библиотеки: %2';
			|en = 'It is recommended that you use the report version that matches the used SSL version.
			|Automatic fixing of some errors might be not available.
			|
			|Report version: %1
			|Library version: %2';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			ReportVersion(),
			StandardSubsystemsServer.LibraryVersion());
		Common.MessageToUser(MessageText);
	EndIf;
	
	StandardProcessing = False;
	DCSettings = SettingsComposer.GetSettings();
	
	CorrectErrorsField = DCSettings.DataParameters.Items.Find("CorrectErrors");
	CorrectErrorsFieldIsAlternative = DCSettings.DataParameters.Items.Find("CorrectBooleanErrors");
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		CorrectErrors = CorrectErrorsField.Use;
	Else
		CorrectErrors = CorrectErrorsFieldIsAlternative.Value;
	EndIf;
	
	If CorrectErrors Then
		FilterValue = CorrectErrorsField.Value;
		If ValueIsFilled(FilterValue) Then
			If TypeOf(FilterValue) = Type("String") Then
				FixedErrors = New Array;
				FixedErrors.Add(FilterValue);
			Else
				FixedErrors = FilterValue.UnloadValues();
			EndIf;
		Else
			FixedErrors = FixedErrors().UnloadValues();
		EndIf;
	EndIf;
	
	SelectionBySubsystemsField = DCSettings.DataParameters.Items.Find("CheckedSubsystems");
	CheckSubsystemsImplementation = SelectionBySubsystemsField.Use;
	If CheckSubsystemsImplementation Then
		FilterValue = SelectionBySubsystemsField.Value;
		If FilterValue <> Undefined Then
			If TypeOf(FilterValue) = Type("String") Then
				FilterBySubsystems = New Array;
				FilterBySubsystems.Add(FilterValue);
			Else
				FilterBySubsystems = FilterValue.UnloadValues();
			EndIf;
		Else
			FilterBySubsystems = New Array;
		EndIf;
	EndIf;
	
	SettingsComposer.LoadSettings(DCSettings);
	
	InteractiveLaunch = True;
	CheckIntegration();
	
	DCTemplateComposer = New DataCompositionTemplateComposer;
	DCTemplate = DCTemplateComposer.Execute(DataCompositionSchema, DCSettings); // Without details.
	
	DCProcessor = New DataCompositionProcessor;
	DCProcessor.Initialize(DCTemplate, New Structure("CheckTable", CheckTable)); // Without details.
	
	DCResultOutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	DCResultOutputProcessor.SetDocument(ResultDocument);
	DCResultOutputProcessor.Output(DCProcessor);
	
EndProcedure

#EndRegion

#Region Private

Function ReportVersion()
	
	Return Metadata.Version;
	
EndFunction

Function ReportVersionDiffersFromLibraryVersion()
	
	LibraryVersion = StandardSubsystemsServer.LibraryVersion();
	ComparisonResult = CommonClientServer.CompareVersions(ReportVersion(), LibraryVersion);
	
	Return ComparisonResult <> 0;
	
EndFunction

Function MinVersionSupportingRegEx()
	
	Return "8.3.23.1437";
	
EndFunction

#Region SubsystemVerificationProcedures

Procedure AtDeterminingSubsystemsToBeChecked(CheckedSubsystems)
	
	CheckedSubsystems.Add("Core");
	CheckedSubsystems.Add("BusinessProcessesAndTasks");
	CheckedSubsystems.Add("ReportsOptions");
	CheckedSubsystems.Add("ObjectsVersioning");
	CheckedSubsystems.Add("PeriodClosingDates");
	CheckedSubsystems.Add("AdditionalReportsAndDataProcessors");
	CheckedSubsystems.Add("UserNotes");
	CheckedSubsystems.Add("ObjectAttributesLock");
	CheckedSubsystems.Add("ODataInterface");
	CheckedSubsystems.Add("ContactInformation");
	CheckedSubsystems.Add("NationalLanguageSupport");
	CheckedSubsystems.Add("UserReminders");
	CheckedSubsystems.Add("ItemOrderSetup");
	If IsDemoSSL() Then
		CheckedSubsystems.Add("DataExchange");
	EndIf;
	CheckedSubsystems.Add("IBVersionUpdate");
	CheckedSubsystems.Add("PerformanceMonitor");
	CheckedSubsystems.Add("AttachableCommands");
	CheckedSubsystems.Add("Users");
	CheckedSubsystems.Add("ObjectsPrefixes");
	CheckedSubsystems.Add("FilesOperations");
	CheckedSubsystems.Add("SaaSOperations");
	CheckedSubsystems.Add("ReportMailing");
	CheckedSubsystems.Add("Properties");
	CheckedSubsystems.Add("SubordinationStructure");
	CheckedSubsystems.Add("AccessManagement");
	CheckedSubsystems.Add("SourceDocumentsOriginalsRecording");
	CheckedSubsystems.Add("MessageTemplates");
	CheckedSubsystems.Add("DigitalSignature");
	
EndProcedure

Function FixedErrors()
	
	List = New ValueList;
	List.Add("MainRolesComposition",
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Базовая функциональность. В роли %1 или %2 права отличаются от эталонных';
				|en = 'Core. Rights in role ""%1"" or ""%2"" differ from the prototype rights';"),
			"SystemAdministrator", "FullAccess"));
	List.Add("NotRecommendedRolesComposition",
		NStr("ru = 'Базовая функциональность. Нерекомендуемый состав ролей';
			|en = 'Core. Deprecated access rights';"));
	List.Add("ODataRoleComposition",
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Интерфейс %1. В роли %2 ошибочный состав прав';
				|en = '%1 interface. The %2 role has invalid rights.';"),
			"OData",
			"RemoteODataAccess"));
	List.Add("DividersTemplateNotUpdated",
		NStr("ru = 'Работа в модели сервиса. Не обновлен эталонный макет для проверки состава разделителей';
			|en = 'SaaS. Reference template for checking separator content is not updated';"));
	List.Add("IncorrectSeparatorsComposition",
		NStr("ru = 'Работа в модели сервиса. Некорректное значение состава разделителя';
			|en = 'SaaS. Invalid separator content value';"));
	List.Add("RedundantSeparatorSetting",
		NStr("ru = 'Работа в модели сервиса. Избыточное использование явного значения разделителя';
			|en = 'SaaS. Redundant use of explicit separator value';"));
	List.Add("NoRightsToSAAttributes",
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Работа в модели сервиса. В роли %1 должны быть всегда установлены права на реквизиты';
				|en = 'SaaS. The %1 role must always have rights to attributes';"),
			"SystemAdministrator"));
	List.Add("NoRightsToSPAttributes",
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Работа в модели сервиса. В роли %1 должны быть всегда установлены права на реквизиты';
				|en = 'SaaS. The %1 role must always have rights to attributes';"),
			"FullAccess"));
	List.Add("RedundantRightsToASharedObject",
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Работа в модели сервиса. В роли %1 избыточно установлены права на разделенный объект';
				|en = 'SaaS. Redundant access rights are set for a separated object in the %1 role.';"),
			"SystemAdministrator"));
	List.Add("ProhibitedRightsInstalled",
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Работа в модели сервиса. В роли %1 или %2 установлены запрещенные права на объект';
				|en = 'SaaS. Restricted access rights are set for an object in the %1 or %2 role.';"),
			"SystemAdministrator", "FullAccess"));
	List.Add("NecessaryRightsNotSet",
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Работа в модели сервиса. В роли %1 или %2 не установлены необходимые права на объект';
				|en = 'SaaS. Required access rights are not set for an object in the %1 or %2 role.';"),
			"SystemAdministrator", "FullAccess"));
	List.Add("WorkingWithFilesValueType",
		NStr("ru = 'Работа с файлами. Некорректный тип значения реквизита справочника файлов';
			|en = 'File management. Invalid type of the file catalog attribute value';"));
	List.Add("WorkingWithFilesPropertyValue",
		NStr("ru = 'Работа с файлами. Некорректное значение свойства реквизита справочника файлов';
			|en = 'File management. Invalid value of the file catalog attribute property';"));
	List.Add("TypeNotIncludedInDefinedType",
		NStr("ru = 'Управление доступом. Тип отсутствует в составе определяемого типа';
			|en = 'Access management. Type is missing in the type collection';"));
	List.Add("IncorrectPredefinedElementsCompositionInMetadataObjectIdentifiersDirectory",
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Управление доступом. Некорректный состав предопределенных элементов в справочнике %1';
				|en = 'Access management. Incorrect composition of predefined items in the %1 catalog.';"),
			"MetadataObjectIDs"));
	List.Add("InvalidConstraintTextForTableInRole",
		NStr("ru = 'Управление доступом. Неверный текст ограничения для таблицы в роли';
			|en = 'Access management. Incorrect restriction text for the table in role';"));
	List.Add("TemplateUsedInRoleIsMissingOrDifferent",
		NStr("ru = 'Управление доступом. Используемый шаблон в роли отсутствует или отличается от поставляемого';
			|en = 'Access management. Template is missing in the role or does not match the built-in template';"));
	List.Add("NotUsedInRoleTemplate",
		NStr("ru = 'Управление доступом. Шаблон не используется в роли';
			|en = 'Access management. Template is not used in the role';"));
	List.Add("InvalidRegisterFieldTypesComposition",
		NStr("ru = 'Управление доступом. Неверный состав типов поля регистра';
			|en = 'Access management. Incorrect composition of register field types';"));
		
	Return List;
	
EndFunction

Function FixError(Validation)
	Return CorrectErrors And FixedErrors.Find(Validation) <> Undefined;
EndFunction

Procedure Attachable_Core_CheckIntegration()
	
	SubsystemSettings = InfobaseUpdateInternal.SubsystemSettings();
	ObjectsWithInitialFilling = SubsystemSettings.ObjectsWithInitialFilling;
	
	// Check manager modules for code insertions.
	CheckedCalls = New Array;
	CheckedCalls.Add("Procedure OnSetUpInitialItemsFilling(");
	CheckedCalls.Add("Procedure OnInitialItemsFilling(");
	
	CheckParameters = CheckingCodeInsertionParameters();
	CheckParameters.DataToCheck1 = ObjectsWithInitialFilling;
	CheckParameters.ModuleType         = "ManagerModule";
	CheckParameters.CodeString        = CheckedCalls;
	CheckForCodeInsertion(CheckParameters);
	
	CheckMainRolesComposition();
	CheckNonRecommendedRolesComposition();
	CheckTheIntegrityOfSubsystems();
	CheckConfigurationRootModules();
	CheckProxyUsage();
	
EndProcedure

Procedure Attachable_BusinessProcessesAndTasks_CheckIntegration()
	
	// Check business process manager modules for code insertions.
	CheckedCalls = New Array;
	CheckedCalls.Add("Function TaskExecutionForm(");
	CheckedCalls.Add("Procedure OnForwardTask(");
	CheckedCalls.Add("Procedure DefaultCompletionHandler(");
	
	CheckParameters = CheckingCodeInsertionParameters();
	CheckParameters.DataToCheck1 = "DefinedTypes.BusinessProcess.Type";
	CheckParameters.ModuleType         = "ManagerModule";
	CheckParameters.CodeString        = CheckedCalls;
	CheckForCodeInsertion(CheckParameters);
	
	VerifiableBusinessProcesses = New Array;
	VerifiableBusinessProcesses.Add(TypeComposition("DefinedTypes.BusinessProcess.Type"));
	VerifiableBusinessProcesses.Add(TypeComposition("DefinedTypes.BusinessProcessObject.Type"));
	CompareTypes(VerifiableBusinessProcesses, NStr("ru = 'Бизнес-процесс';
												|en = 'Business process';"));
	
	// Duty subject check.
	TestableTaskItems = New Array;
	TestableTaskItems.Add(TypeComposition("BusinessProcesses.Job.BasedOn"));
	TestableTaskItems.Add(TypeComposition("DefinedTypes.TaskSubject.Type"));
	CompareTypes(TestableTaskItems, NStr("ru = 'Предмет заданий';
													|en = 'Duty subject';"));

	// Check if the PerformerRoles catalog has the EmployeeResponsibleForTasksManagement predefined item.
	CheckForPredefinedElement("Catalogs.PerformerRoles", "EmployeeResponsibleForTasksManagement");
	
	// Check if the TaskAddressingObjects chart of characteristic types has the AllAddressingObjects predefined item.
	CheckForPredefinedElement("ChartsOfCharacteristicTypes.TaskAddressingObjects", "AllAddressingObjects");
	
	// Check if the AllAddressingObjects predefined object type matches the types of other business objects.
	CheckedTaskAddressingObjects = New Array;
	CheckedTaskAddressingObjects.Add(TypeComposition("ChartsOfCharacteristicTypes.TaskAddressingObjects.Type"));
	
	TaskAddressingObjectsMetadata = New Array;
	AllAddressingObjects = ChartsOfCharacteristicTypes["TaskAddressingObjects"].AllAddressingObjects;
	For Each Type In Common.ObjectAttributeValue(AllAddressingObjects, "ValueType").Types() Do
		TaskAddressingObjectsMetadata.Add(Metadata.FindByType(Type));
	EndDo;
	CheckedTaskAddressingObjects.Add(TypeComposition("ChartsOfCharacteristicTypes.TaskAddressingObjects.AllAddressingObjects",
		TaskAddressingObjectsMetadata));
	
	AddressingObjectsMetadata = Metadata.ChartsOfCharacteristicTypes["TaskAddressingObjects"];
	PredefinedAddressingObjects = AddressingObjectsMetadata.GetPredefinedNames();
	AddressingObjectsTypes = New Array;
	For Each PredefinedItemName1 In PredefinedAddressingObjects Do
		If PredefinedItemName1 = "AllAddressingObjects" Then
			Continue;
		EndIf;
		PredefinedItem = ChartsOfCharacteristicTypes["TaskAddressingObjects"][PredefinedItemName1];
		For Each Type In Common.ObjectAttributeValue(PredefinedItem, "ValueType").Types() Do
			AddressingObjectsTypes.Add(Metadata.FindByType(Type));
		EndDo;
	EndDo;
	
	If TaskAddressingObjectsMetadata.Count() <> 1 And AddressingObjectsTypes.Count() <> 0 Then
		// If more than one authorization object is used.
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Типы предопределенных элементов ПВХ %1';
				|en = 'Predefined item types of CCT %1';"), "TaskAddressingObjects");
		CheckedTaskAddressingObjects.Add(TypeComposition(MessageText, AddressingObjectsTypes));
	EndIf;
	
	CompareTypes(CheckedTaskAddressingObjects, NStr("ru = 'Объект адресации задач';
														|en = 'Task addressing object';"));
	
	// If the configuration has predefined roles (other than "EmployeeResponsibleForTasksManagement")
	// that use business objects, then check if they are used.
	Query = New Query;
	Query.Text = 
		"SELECT
		|	PerformerRoles.UsedByAddressingObjects AS UsedByAddressingObjects,
		|	PerformerRoles.Ref AS Ref
		|FROM
		|	Catalog.PerformerRoles AS PerformerRoles
		|WHERE
		|	PerformerRoles.UsedByAddressingObjects = TRUE
		|	AND PerformerRoles.Ref <> &Ref";
	
	EmployeeResponsibleForTasksManagement = Common.PredefinedItem("Catalog.PerformerRoles.EmployeeResponsibleForTasksManagement");
	Query.SetParameter("Ref", EmployeeResponsibleForTasksManagement);
	QueryResult = Query.Execute();
	
	// If there is at least one business object, there must be a role that uses business objects.
	If Not QueryResult.IsEmpty() And TaskAddressingObjectsMetadata.Count() > 0 Then
		Query = New Query;
		Query.Text = 
		"SELECT
		|	PerformerRoles.Description
		|FROM
		|	Catalog.PerformerRoles AS PerformerRoles
		|WHERE
		|	PerformerRoles.Predefined = TRUE
		|	AND PerformerRoles.UsedByAddressingObjects = TRUE
		|	AND PerformerRoles.MainAddressingObjectTypes <> VALUE(ChartOfCharacteristicTypes.TaskAddressingObjects.AllAddressingObjects)";
		
		SelectionRoles = Query.Execute();
		If SelectionRoles.IsEmpty() Then
			
			MessageTemplate = NStr("ru = 'В конфигурации имеются объекты адресации задач (предопределенные элементы плана видов характеристик %1), 
				|но нет ни одной роли, которая бы их использовала (реквизит %2 = %3).';
				|en = 'Configuration has task addressing objects (predefined items of chart of characteristic types %1), 
				|but has no role that would use them (attribute %2 = %3).';");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, "TaskAddressingObjects", "UsedByAddressingObjects", "True");
			AddError(Metadata.Catalogs["PerformerRoles"], NStr("ru = 'Отсутствуют роли исполнителей, назначаемые с объектами адресации задач';
																			|en = 'Business roles that are assigned with task addressing objects are missing';"),
				MessageText);
				
		EndIf;
	EndIf;
	
EndProcedure

Procedure Attachable_ReportsOptions_CheckIntegration()
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	
	CheckParameters = New Structure;
	CheckParameters.Insert("MainFormFlag");
	CheckParameters.Insert("SettingsFormCheckbox");
	CheckParameters.Insert("OptionStorageCheckbox");
	CheckParameters.Insert("ReportsExcludedFromCheckStorageVariant", ReportsExcludedFromConnectionCheckToStorage());
	
	PredefinedReportsOptions = ModuleReportsOptions.PredefinedReportsOptions("BuiltIn", False);
	
	For Each RowReport In PredefinedReportsOptions Do
		
		If Not RowReport.IsOption Then
			ReportManager = Reports[RowReport.Metadata.Name];
			Try
				ReportObject = ReportManager.Create();
			Except
				AddError(
					RowReport.Metadata,
					NStr("ru = 'Не удалось создать отчет';
						|en = 'Cannot create the report';"),
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				Continue;
			EndTry;
			
			ReportOptions_CheckConnectionToReportForms(CheckParameters, RowReport);
			ReportOptions_CheckConnectionToOptionsStore(CheckParameters, RowReport);
			ReportOptions_CheckOutdatedPropertiesUse(RowReport, ReportObject);
		Else
			ReportOptions_CheckSettingsForSearch(PredefinedReportsOptions, RowReport);
		EndIf;
		
	EndDo;
	
	For Each SharedCommandMetadata In Metadata.CommonCommands Do
		ReportOptions_CheckCommonCommand(SharedCommandMetadata);
	EndDo;
EndProcedure

Procedure Attachable_ObjectsVersioning_CheckIntegration()
	
	// Compare type lists.
	VersionedDataComposition = TypeComposition("DefinedTypes.VersionedData.Type",,, "Catalog.MetadataObjectIDs");
	ArrayOfSources = New Array;
	ArrayOfSources.Add(VersionedDataComposition);
	
	SubscriptionsComposition = New Array;
	SubscriptionsComposition.Add(TypeComposition("DefinedTypes.VersionedDataObject.Type",, "EverythingExceptDocuments", "Catalog.MetadataObjectIDs"));
	SubscriptionsComposition.Add(SubscriptionsByHandlerComposition("ObjectsVersioningEvents.WriteDocumentVersion", "Documents"));
	ArrayOfSources.Add(MergeTypes(SubscriptionsComposition));
	CompareTypes(ArrayOfSources);
	
	// Check if code insertions are present.
	CheckParameters = CheckingCodeInsertionParameters();
	CheckParameters.DataToCheck1 = VersionedDataComposition;
	CheckParameters.ModuleType         = "DefaultObjectForm";
	CheckParameters.CodeString        = "ObjectsVersioning.OnCreateAtServer(";
	CheckForCodeInsertion(CheckParameters);
	
EndProcedure

Procedure Attachable_PeriodClosingDates_CheckIntegration()
	
	MetadataArray = New Array;
	ObjectManager = Common.ObjectManagerByFullName("ChartOfCharacteristicTypes.PeriodClosingDatesSections");
	Try
		ClosingDatesSectionsProperties = ObjectManager.ClosingDatesSectionsProperties();
	Except
		ClosingDatesSectionsProperties = Undefined;
		ErrorInfo = ErrorInfo();
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Некорректно заполнена процедура %1';
				|en = 'Procedure %1 is filled in incorrectly';"), "OnFillPeriodClosingDatesSections");
		AddError(Metadata.CommonModules["PeriodClosingDatesOverridable"],
			MessageText, ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndTry;
	
	PredefinedItemsNames =
		Metadata.ChartsOfCharacteristicTypes["PeriodClosingDatesSections"].GetPredefinedNames();
	
	ObjectNamePrefix = "Delete";
	BriefErrorDescription =
		NStr("ru = 'Некорректно настроен предопределенный элемент';
			|en = 'Predefined item is set up incorrectly';");
	
	For Each PredefinedItemName In PredefinedItemsNames Do
		If Not StrStartsWith(PredefinedItemName, ObjectNamePrefix) Then
			AddError(Metadata.ChartsOfCharacteristicTypes["PeriodClosingDatesSections"],
				BriefErrorDescription,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Имя предопределенного элемента ""%1"" должно иметь приставку ""%2"".';
						|en = 'The name of the predefined item %1 must have the prefix %2.';"),
					PredefinedItemName, ObjectNamePrefix));
		Else
			SoughtName = Mid(PredefinedItemName, StrLen(ObjectNamePrefix) + 1);
			SectionProperties = ClosingDatesSectionsProperties.Sections.Get(SoughtName);
			If SectionProperties = Undefined Then
				AddError(Metadata.ChartsOfCharacteristicTypes["PeriodClosingDatesSections"],
					BriefErrorDescription,
					StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Имя раздела дат запрета ""%1"", полученное из имени предопределенного элемента ""%2"",
					           |не найдено в описании, указанном в процедуре %3
					           |общего модуля %4.
					           |
					           |Если раздел был переименован/удален в описании, следует переименовать/удалить
					           |соответствующий предопределенный элемент.';
								|en = 'Name of closing date section ""%1"" received from the name of predefined item ""%2""
								|is not found in details specified in procedure %3
								|of common module%4.
								|
								|If the section was renamed or deleted in details, rename or delete
								|the respective predefined item.';"),
					SoughtName, PredefinedItemName, "OnFillPeriodClosingDatesSections", "PeriodClosingDatesOverridable"));
			EndIf;
		EndIf;
	EndDo;
	
	DataSources = New ValueTable;
	DataSources.Columns.Add("Table",     New TypeDescription("String"));
	DataSources.Columns.Add("DateField",    New TypeDescription("String"));
	DataSources.Columns.Add("Section",      New TypeDescription("String"));
	DataSources.Columns.Add("ObjectField", New TypeDescription("String"));
	
	SSLSubsystemsIntegration.OnFillDataSourcesForPeriodClosingCheck(DataSources);
	Common.CommonModule("PeriodClosingDatesOverridable").FillDataSourcesForPeriodClosingCheck(DataSources);
	
	BriefErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Некорректно заполнена процедура %1';
			|en = 'Procedure %1 is filled in incorrectly';"), "FillDataSourcesForPeriodClosingCheck");
	
	For Each DataSource In DataSources Do
		MetadataObject = Common.MetadataObjectByFullName(DataSource.Table);
		MetadataObjectExists = True;
		If MetadataObject = Undefined Then
			MetadataObjectExists = False;
				AddError(Metadata.CommonModules.PeriodClosingDatesOverridable,
					BriefErrorDescription,
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'В процедуре %1
						           |общего модуля %2 указан объект метаданных
						           |""%3"", отсутствующий в конфигурации.';
									|en = 'Procedure %1
									|of common module %2 contains metadata object
									|""%3"" that is missing in the configuration.';"),
						"FillDataSourcesForPeriodClosingCheck", "PeriodClosingDatesOverridable", DataSource.Table));
		EndIf;
		
		If MetadataObjectExists Then
			MetadataArray.Add(MetadataObject);
		EndIf;
		
		// DateField check. The field is required.
		If IsBlankString(DataSource.DateField) Then
			
			AddError(Metadata.CommonModules.PeriodClosingDatesOverridable,
				BriefErrorDescription,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В процедуре %1
					           |общего модуля %2
					           |для объекта ""%3"" не заполнено поле ""%4"".';
								|en = 'In procedure %1
								|of common module %2
								|, object ""%3"" has field ""%4"" blank.';"),
					"FillDataSourcesForPeriodClosingCheck", "PeriodClosingDatesOverridable", DataSource.Table, "DateField"));
		
		ElsIf MetadataObjectExists Then
			CheckChangeBanField(DataSource, MetadataObject, "DateField");
		EndIf;
		
		// ObjectField check. The field is not required.
		If Not IsBlankString(DataSource.ObjectField) And MetadataObjectExists Then
			CheckChangeBanField(DataSource, MetadataObject, "ObjectField");
		EndIf;
		
		// Section check. The field is required unless the ObjectField is empty.
		If IsBlankString(DataSource.Section) And Not IsBlankString(DataSource.ObjectField) Then
			
			AddError(Metadata.CommonModules.PeriodClosingDatesOverridable,
				BriefErrorDescription,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В процедуре %1
					           |общего модуля %2
					           |для объекта ""%3"" не заполнено поле ""%4"" и заполнено поле ""%5"".
					           |Поле ""%4"" может быть пустым только при незаполненном поле ""%5"".';
								|en = 'In procedure %1
								|of common module %2
								|, object ""%3"" has field ""%4"" blank and field ""%5"" filled in.
								|Field ""%4"" can be blank only if field ""%5"" is blank as well.';"),
					"FillDataSourcesForPeriodClosingCheck", "PeriodClosingDatesOverridable", DataSource.Table,
					"Section", "ObjectField"));
		
		ElsIf Not IsBlankString(DataSource.Section)
		        And ClosingDatesSectionsProperties <> Undefined
		        And ClosingDatesSectionsProperties.Sections.Get(DataSource.Section) = Undefined Then
			
			AddError(Metadata.CommonModules.PeriodClosingDatesOverridable,
				BriefErrorDescription,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В процедуре %1
					           |общего модуля %2 указан раздел ""%3"",
					           |который отсутствует в процедуре %4
					           |общего модуля %5.';
								|en = 'Procedure %1
								|of common module %2 contains section ""%3""
								|that is missing in procedure%4
								|of common module %5.';"),
					"FillDataSourcesForPeriodClosingCheck", "PeriodClosingDatesOverridable", DataSource.Section, 
					"OnFillPeriodClosingDatesSections", "PeriodClosingDatesOverridable"));
		EndIf;
		
	EndDo;
	
	// Check compliance of type list.
	DataSources = TypeComposition(
		"PeriodClosingDatesOverridable.FillDataSourcesForPeriodClosingCheck",
			MetadataArray);
	
	SubscriptionsForReferenceBooksComposition = SubscriptionsByHandlerComposition(
		"PeriodClosingDates.CheckPeriodEndClosingDateBeforeWrite", "Catalogs");
	
	SubscriptionsForDocumentsComposition = SubscriptionsByHandlerComposition(CallOptions(
		"PeriodClosingDates.CheckPeriodEndClosingDateBeforeWriteDocument",
		"PersonalDataProtection.CheckPeriodEndClosingDateBeforeWriteDocument"), "Documents");
	
	ArrayOfSubscriptions = New Array;
	ArrayOfSubscriptions.Add(SubscriptionsForReferenceBooksComposition);
	ArrayOfSubscriptions.Add(SubscriptionsForDocumentsComposition);
	
	ArrayOfSubscriptions.Add(SubscriptionsByHandlerComposition(
		"PeriodClosingDates.CheckPeriodEndClosingDateBeforeWriteRecordSet",
		"InformationRegisters,AccumulationRegisters"));
	
	ArrayOfSubscriptions.Add(SubscriptionsByHandlerComposition(
		"PeriodClosingDates.CheckPeriodEndClosingDateBeforeWriteAccountingRegisterRecordSet",
		"AccountingRegisters"));
	
	ArrayOfSubscriptions.Add(SubscriptionsByHandlerComposition(
		"PeriodClosingDates.CheckPeriodEndClosingDateBeforeWriteCalculationRegisterRecordSet",
		"CalculationRegisters"));
	
	SubscriptionsComposition = MergeTypes(ArrayOfSubscriptions);
	
	ArrayOfSources = New Array;
	ArrayOfSources.Add(SubscriptionsComposition);
	ArrayOfSources.Add(DataSources);
	CompareTypes(ArrayOfSources);
	
	// Check type list of the CheckPeriodEndClosingDateBeforeDelete subscription.
	
	ArrayOfSubscriptions = New Array;
	ArrayOfSubscriptions.Add(SubscriptionsForReferenceBooksComposition);
	ArrayOfSubscriptions.Add(SubscriptionsForDocumentsComposition);
	ReferenceSubscriptionsComposition = MergeTypes(ArrayOfSubscriptions);
	
	SubscriptionsBeforeDeletionComposition = SubscriptionsByHandlerComposition(CallOptions(
		"PeriodClosingDates.CheckPeriodEndClosingDateBeforeDelete",
		"PersonalDataProtection.CheckPeriodEndClosingDateBeforeDelete"));
	
	ArrayOfSources = New Array;
	ArrayOfSources.Add(ReferenceSubscriptionsComposition);
	ArrayOfSources.Add(SubscriptionsBeforeDeletionComposition);
	CompareTypes(ArrayOfSources);
	
	// Check if code insertions are present.
	CheckParameters = CheckingCodeInsertionParameters();
	CheckParameters.DataToCheck1 = MetadataArray;
	CheckParameters.ModuleType         = "DefaultObjectForm";
	CheckParameters.CodeString        = "PeriodClosingDates.ObjectOnReadAtServer(";
	CheckParameters.AbsenceOfModuleIsError = False;
	CheckForCodeInsertion(CheckParameters);
	
EndProcedure

Procedure Attachable_AdditionalReportsAndDataProcessors_CheckIntegration()
	
	// Check if the commands have a call string.
	CheckGlobalProcessingReportsEmbedding(True); // Reports.
	CheckGlobalProcessingReportsEmbedding(False); // Data processors.
	
EndProcedure

Procedure Attachable_UserNotes_CheckIntegration()
	
	// Compare type lists.
	ArrayOfSources = New Array;
	ArrayOfSources.Add(TypeComposition("DefinedTypes.NotesSubject.Type",,, "Catalog.MetadataObjectIDs,Catalog.Users"));
	ArrayOfSources.Add(TypeComposition("DefinedTypes.NotesSubjectObject.Type",,, "Catalog.Users"));
	
	SubscriptionsComposition = New Array;
	SubscriptionsComposition.Add(SubscriptionsByHandlerComposition("UserNotes.SetObjectDeletionMarkChangeStatus", "EverythingExceptDocuments", "Catalog.Users"));
	SubscriptionsComposition.Add(SubscriptionsByHandlerComposition("UserNotes.SetDocumentDeletionMarkChangeStatus", "Documents"));
	ArrayOfSources.Add(MergeTypes(SubscriptionsComposition));
	
	CompareTypes(ArrayOfSources, NStr("ru = 'Предмет заметок';
										|en = 'Notes subject';"));
	
EndProcedure

Procedure Attachable_ObjectAttributesLock_CheckIntegration()
	
	Objects = New Map;
	Common.CommonModule("ObjectAttributesLockOverridable").OnDefineObjectsWithLockedAttributes(Objects);
	
	MetadataArray = New Array;
	For Each Item In Objects Do
		MetadataArray.Add(Common.MetadataObjectByFullName(Item.Key));
	EndDo;
	
	// Check if modules contain calls.
	CheckParameters = CheckingCodeInsertionParameters();
	CheckParameters.DataToCheck1 = MetadataArray;
	
	CheckParameters.ModuleType  = "ManagerModule";
	CheckParameters.CodeString = "Function GetObjectAttributesToLock";
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.ModuleType  = "DefaultObjectForm";
	CheckParameters.CodeString = "ObjectAttributesLock.LockAttributes(";
	
	CheckParameters.NameOfAProcedureOrAFunction = "Procedure OnCreateAtServer";
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.NameOfAProcedureOrAFunction = "Procedure AfterWriteAtServer";
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.NameOfAProcedureOrAFunction = "";
	CheckParameters.CodeString = "Attachable_AllowObjectAttributeEdit";
	CheckForCodeInsertion(CheckParameters);
	
EndProcedure

Procedure Attachable_ODataInterface_CheckIntegration()
	
	VerificationProcessingManager = DataProcessors["SetUpStandardODataInterface"];
	
	Role = VerificationProcessingManager.RoleForStandardODataInterface();
	ErrorsByObjects = New Map;
	RoleErrors = VerificationProcessingManager.ODataRoleCompositionErrors(ErrorsByObjects);
	
	If RoleErrors.Count() > 0 Then
		
		ErrorTextBriefly = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Некорректный состав прав роли %1.';
				|en = 'Role ""%1"" has invalid list of rights.';"), Role.Name);
		
		If FixError("ODataRoleComposition") Then
			
			RoleFileName = RoleCompositionFilePath(Role.Name);
			FileToImportName = RoleDescriptionFilePath(Role);
			ReferenceComposition = VerificationProcessingManager.ReferenceRoleCompositionForStandardODataInterface();
			
			FixDataRoleComposition(RoleFileName, ReferenceComposition);
			
			FilesToUpload.Add(FileToImportName);
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Исправлено. Изменен состав прав роли %1.';
					|en = 'Fixed. Role rights composition changed%1.';"), Role.Name);
			
			AddError(Role, ErrorTextBriefly, ErrorText);
		Else
			
			ErrorText = "";
			For Each Error In ErrorsByObjects Do
				AddError(Error.Key, ErrorTextBriefly, Error.Value);
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns:
//  ValueTable:
//   * PredefinedView - String 
//   * OwnerMetadata - MetadataObjectCatalog
//                         - MetadataObjectDocument
//                         - MetadataObject
//   * HasTabularParts  - Boolean
// 
Function ContactInformationKindsTable()
	 
	TableOfSpecies = New ValueTable;
	TableOfSpecies.Columns.Add("PredefinedView");
	TableOfSpecies.Columns.Add("OwnerMetadata");
	TableOfSpecies.Columns.Add("HasTabularParts");
	Return TableOfSpecies;
	
EndFunction

Procedure Attachable_ContactInformation_CheckIntegration()
	
	ModuleContactsManager = Common.CommonModule("ContactsManager");
	
	ContactInformationKindsMetadata = Metadata.Catalogs["ContactInformationKinds"];
	TableOfSpecies = ContactInformationKindsTable();
	DocumentationPath = "https://its.1c.eu/db/bspdoc";
	
	InitialPopulationData = InfobaseUpdateInternal.ParameterSetForFillingObject(ContactInformationKindsMetadata);
	
	CheckForDuplicates = New Map;
	
	Query = New Query;
	Query.Text = "SELECT
	|	ContactInformationKinds.PredefinedKindName AS PredefinedKindName,
	|	ContactInformationKinds.PredefinedDataName AS PredefinedDataName,
	|	ContactInformationKinds.IsFolder AS IsFolder,
	|	ContactInformationKinds.Parent AS Parent,
	|	ParentContactInformationKinds.PredefinedKindName AS ParentPredefinedKindName,
	|	ParentContactInformationKinds.PredefinedDataName AS ParentPredefinedDataName
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|		LEFT JOIN Catalog.ContactInformationKinds AS ParentContactInformationKinds
	|		ON ContactInformationKinds.Parent = ParentContactInformationKinds.Ref
	|WHERE
	|	(ContactInformationKinds.PredefinedDataName <> """"
	|			OR ContactInformationKinds.PredefinedKindName <> """")";
	
	ContactInformationKinds = Query.Execute().Unload();
	
	Position = ContactInformationKinds.Count() -1;
	While Position >=0 Do
		TableRow = ContactInformationKinds[Position];
		If StrStartsWith(TableRow.PredefinedDataName, "Delete")
			Or StrStartsWith(TableRow.PredefinedKindName, "Delete") Then
			ContactInformationKinds.Delete(TableRow);
		EndIf;
		Position = Position -1;
	EndDo;
	
	For Each TableRow In InitialPopulationData.PredefinedData Do
		
		PredefinedItemName = "";
		ShortErrorText   = "";
		DetailedErrorText = "";
		PredefinedView  = Undefined;
		
		If ValueIsFilled(TableRow.PredefinedDataName) Then
			
			If CheckForDuplicates.Get(TableRow.PredefinedDataName) = Undefined Then
				
				PredefinedView = ContactInformationKinds.Find(TableRow.PredefinedDataName, "PredefinedDataName");
				If PredefinedView = Undefined Then
					
					DetailedErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Предопределенный вид контактной информации %1 описан в коде начального заполнения,
						|но отсутствует в информационной базе. Необходимо создать этот вид.
						|Подробнее см. документацию по внедрению подсистемы ""%2"" 1С:Библиотеки стандартных подсистем: %3';
						|en = 'The predefined contact information kind %1 is present in the initial population but missing
						|from the infobase. You should add this kind manually.
						|For details, see the ""%2"" subsystem in 1C:SSL documentation: %3';"), 
						TableRow.PredefinedDataName, CheckedSubsystem.Synonym, DocumentationPath);
					ShortErrorText = NStr("ru = 'Предопределенный вид контактной информации отсутствует в информационной базе.';
												|en = 'The predefined contact information kind is missing from the infobase.';");
					
				Else
					PredefinedItemName = TableRow.PredefinedDataName;
					CheckForDuplicates.Insert(PredefinedItemName, "PredefinedDataName");
				EndIf;
				
			Else
				DetailedErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Предопределенный вид контактной информации %1 уже описан в реквизите %2 кода начального заполнения.
					|Необходимо оставить только одно определение и удалить дублирующий код.';
					|en = 'The predefined contact information kind ""%1"" is already described in the initial population attribute ""%2"".
					|Choose either of them and delete the duplicating code.';"), 
					TableRow.PredefinedDataName, CheckForDuplicates.Get(TableRow.PredefinedDataName));
				ShortErrorText = NStr("ru = 'Код начального заполнения содержит дублирование имен предопределенных видов контактной информации.';
											|en = 'The initial population code duplicates the names of predefined contact information kinds.';");
			EndIf;
			
		ElsIf ValueIsFilled(TableRow.PredefinedKindName) Then
			
			If CheckForDuplicates.Get(TableRow.PredefinedKindName) = Undefined Then

				PredefinedView = ContactInformationKinds.Find(TableRow.PredefinedKindName, "PredefinedKindName");
				If PredefinedView = Undefined Then
					
					DetailedErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Предопределенный вид контактной информации %1 описан в процедуре %2 кода начального заполнения,
						|но отсутствует в информационной базе. Необходимо добавить этот вид контактной информации используя обработчик обновления.
						|Подробнее см. документацию по внедрению подсистемы ""%3"" 1С:Библиотеки стандартных подсистем: %4';
						|en = 'The predefined contact information kind %1 is present in the initial population procedure""%2""
						|but missing from the infobase. You should add this kind using the update handler.
						|For details, see ""%3"" subsystem in 1C:SSL documentation: %4';"),
						TableRow.PredefinedKindName, "OnInitialItemsFilling", CheckedSubsystem.Synonym, DocumentationPath);
					
					ShortErrorText = NStr("ru = 'Предопределенный вид контактной информации отсутствует в информационной базе';
												|en = 'The predefined contact information kind is missing from the infobase';");
					
				Else
					PredefinedItemName = TableRow.PredefinedKindName;
					CheckForDuplicates.Insert(PredefinedItemName, "PredefinedKindName");
				EndIf;
			
			Else
				DetailedErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Предопределенный вид контактной информации %1 уже описан в реквизите %2 кода начального заполнения.
					|Необходимо оставить только одно определение и удалить дублирующий код.';
					|en = 'The predefined contact information kind ""%1"" is already described in the initial population attribute ""%2"".
					|Choose either of them and delete the duplicating code.';"), 
					TableRow.PredefinedDataName, CheckForDuplicates.Get(TableRow.PredefinedKindName));
				ShortErrorText = NStr("ru = 'Код начального заполнения содержит дублирование имен предопределенных видов контактной информации.';
											|en = 'The initial population code duplicates the names of predefined contact information kinds.';");
			EndIf;
			
		Else
			
			DetailedErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В процедуре %1 кода начального заполнения описан предопределенный вид контактной информации %2
				|у которого не заполнен реквизит %3. Необходимо в значение реквизита добавить уникальное имя предопределенного вида
				|и затем создать вид контактной информации в информационной базе используя обработчик обновления.
				|Подробнее см. документацию по внедрению подсистемы ""%4"" 1С:Библиотеки стандартных подсистем: %5';
				|en = 'The initial population procedure ""%1"" has a predefined contact information kind ""%2""
				|with the unfilled attribute ""%3"". You should assign the attribute with a unique name
				|and then create the contact information kind in the infobase using the update handler.
				|For details, see ""%4"" subsystem in 1C:SSL documentation: %5';"),
				"OnInitialItemsFilling", TableRow.Description, "PredefinedKindName",
				CheckedSubsystem.Synonym, DocumentationPath);
			
			ShortErrorText = NStr("ru = 'Код начального заполнения содержит предопределенный вид контактной информации с незаполненным именем.';
										|en = 'The initial population code contains a predefined contact information kind with an unfilled name.';");
			
		EndIf;
		
		If ValueIsFilled(ShortErrorText) Then
			AddError(ContactInformationKindsMetadata, ShortErrorText, DetailedErrorText);
		EndIf;
		
		If PredefinedView = Undefined Then
			Continue;
		EndIf;
		
		If Not PredefinedView.IsFolder Then
			ContactInformationKinds.Delete(PredefinedView);
			Continue;
		EndIf;
		
		Result = AddViewToViewTable(PredefinedView, PredefinedItemName, TableOfSpecies);
		If ValueIsFilled(Result.ErrorText) Then
			AddError(ContactInformationKindsMetadata, Result.ErrorTitle, Result.ErrorText);
		EndIf;
		
		ContactInformationKinds.Delete(PredefinedView);
		
	EndDo;
	
	For Each PredefinedView In ContactInformationKinds Do
		
		If ValueIsFilled(PredefinedView.PredefinedDataName)  Then
			
			If Metadata.Languages.Count() > 1 Then
				
				NameOfTheItemName = ContactInformationKindsMetadata.StandardAttributes.Description.Name;
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В конфигурации с несколькими языками стандартный реквизит %1
					|предопределенного вида контактной информации %2 следует заполнять в процедуре %3 кода начального заполнения
					|с использованием процедуры %4
					|Подробнее см. документацию по внедрению подсистемы ""%5"" 1С:Библиотеки стандартных подсистем: %6''"), NameOfTheItemName,
				PredefinedView.Description, "OnInitialItemsFilling", "FillMultilanguageAttribute",
				CheckedSubsystem.Synonym, DocumentationPath);
				
				ShortErrorText = NStr("ru = 'Отсутствует заполнение наименования в коде начального заполнения.';
											|en = 'The initial population code is missing a description population.';");
				
				AddError(ContactInformationKindsMetadata, ShortErrorText, ErrorText);
			EndIf;
			
			If Not PredefinedView.IsFolder Then
				Continue;
			EndIf;
			
			Result = AddViewToViewTable(PredefinedView, PredefinedView.PredefinedDataName, TableOfSpecies);
			If ValueIsFilled(Result.ErrorText) Then
				AddError(ContactInformationKindsMetadata, Result.ErrorTitle, Result.ErrorText);
			EndIf;
			
		Else
		
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В информационной базе присутствует вид контактной информации %1 
			|описание которого отсутствует в процедуре %2 кода начального заполнения. Необходимо добавить код заполнения.
			|Подробнее см. документацию по внедрению подсистемы ""%3"" 1С:Библиотеки стандартных подсистем: %4';
			|en = 'Contact information kind ""%1"" is present in the infobase but missing from
			|the initial population procedure ""%2"". You should add the population code manually.
			|For details, see ""%3"" subsystem in 1C:SSL documentation: %4';"),
			PredefinedView.PredefinedKindName, "OnInitialItemsFilling", CheckedSubsystem.Synonym, DocumentationPath);
			
			AddError(ContactInformationKindsMetadata, 
				NStr("ru = 'В код начального заполнения отсутствует описание переопределенного вида контактной информации.';
					|en = 'The initial population code is missing the details of a redefined contact information kind.';"), ErrorText);
			
		EndIf
		
	EndDo;
	
	ArrayOfSources = New Array;
	ArrayOfSources.Add(TypeComposition("DefinedTypes.ContactInformationOwner.Type",, "EverythingExceptDocuments"));
	ArrayOfSources.Add(SubscriptionsByHandlerComposition("ContactsManager.DocumentContactInformationFilling", "Documents"));
	ContactInformationTypes = MergeTypes(ArrayOfSources);
	
	ObjectsOwners = TableOfSpecies.UnloadColumn("OwnerMetadata");
	
	TypesArray = New Array;
	TypesArray.Add(ContactInformationTypes);
	TypesArray.Add(TypeComposition(NStr("ru = 'Отсутствует предопределенная группа справочника Виды контактной информации.';
										|en = 'The catalog ""Contact information kinds"" is missing a predefined group.';"), ObjectsOwners));
	CompareTypes(TypesArray, NStr("ru = 'Объект с контактной информацией';
									|en = 'Object with contact information';"));
	
	// Check the ContactInformation table attributes.
	TablePartTypes = New Structure;
	TablePartTypes.Insert("Type",                   New TypeDescription("EnumRef.ContactInformationTypes"));
	TablePartTypes.Insert("Kind",                   New TypeDescription("CatalogRef.ContactInformationKinds"));
	TablePartTypes.Insert("Presentation",         New TypeDescription("String",,New StringQualifiers(500)));
	TablePartTypes.Insert("Value",              New TypeDescription("String"));
	TablePartTypes.Insert("FieldValues",         New TypeDescription("String"));
	TablePartTypes.Insert("Country",                New TypeDescription("String",,New StringQualifiers(100)));
	TablePartTypes.Insert("State",                New TypeDescription("String",,New StringQualifiers(50)));
	TablePartTypes.Insert("City",                 New TypeDescription("String",,New StringQualifiers(50)));
	TablePartTypes.Insert("EMAddress",               New TypeDescription("String",,New StringQualifiers(100)));
	TablePartTypes.Insert("ServerDomainName",    New TypeDescription("String",,New StringQualifiers(100)));
	TablePartTypes.Insert("PhoneNumber",         New TypeDescription("String",,New StringQualifiers(20)));
	TablePartTypes.Insert("PhoneNumberWithoutCodes", New TypeDescription("String",,New StringQualifiers(20)));
	TablePartTypes.Insert("KindForList",          New TypeDescription("CatalogRef.ContactInformationKinds"));
	TablePartTypes.Insert("TabularSectionRowID", New TypeDescription("Number",,New NumberQualifiers(7)));
	
	BankingDetailsWithFullTextSearch = New Map;
	BankingDetailsWithFullTextSearch.Insert("Presentation", True);
	
	For Each ObjectToCheck In TableOfSpecies Do
		OwnerMetadata = ObjectToCheck.OwnerMetadata;
		ContactInformationTabularSection = OwnerMetadata.TabularSections.Find("ContactInformation");
		
		// Check if the ContactInformation table exists.
		If ContactInformationTabularSection = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У объекта ""%1"", подключенного к подсистеме отсутствует
				|обязательная табличная часть ""%2""';
				|en = 'Required table ""%2"" is missing for object ""%1"" attached to the subsystem
				|';"), OwnerMetadata.FullName(), "ContactInformation");
				
			AddError(OwnerMetadata, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Отсутствует табличная часть %1';
					|en = 'The %1 table is missing';"), "ContactInformation"), ErrorText);
			Continue;
		EndIf;
		
		// Check if table attributes are required, match the type, and can use the full-text search.
		For Each TablePartType In TablePartTypes Do
			RequiredAttribute = True;
			If TablePartType.Key = "KindForList" Then
				RequiredAttribute = False;
			ElsIf TablePartType.Key = "TabularSectionRowID" Then
				RequiredAttribute = ObjectToCheck.HasTabularParts;
			EndIf;
			
			FoundAttribute = ContactInformationTabularSection.Attributes.Find(TablePartType.Key);
			
			If FoundAttribute = Undefined Then
				If RequiredAttribute Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У объекта ""%1"" в табличной части ""%2""
					|отсутствует обязательный реквизит ""%3""';
					|en = 'Required attribute ""%3"" is missing for object ""%1""
					|in table ""%2""';"), OwnerMetadata.FullName(), "ContactInformation", TablePartType.Key);
					AddError(OwnerMetadata, StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Проверка наличия обязательных реквизитов табличной части %1';
							|en = 'Check if the %1 table contains the required attributes';"), "ContactInformation"), ErrorText);
				EndIf;
			Else
				
				// Check full-text search settings.
				If BankingDetailsWithFullTextSearch[TablePartType.Key] = True Then
					
					If FoundAttribute.FullTextSearch = Metadata.ObjectProperties.FullTextSearchUsing.DontUse Then
						ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У объекта ""%1"" в табличной части ""%2""
						|у реквизита ""%3"" должен быть включен полнотекстовый поиск.';
						|en = 'Attribute ""%3"" of object ""%1""
						|in table ""%2"" must have full-text search enabled.';"), OwnerMetadata.FullName(), "ContactInformation", TablePartType.Key);
						AddError(OwnerMetadata, StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Проверка настроек полнотекстового поиска у реквизитов табличной части %1';
								|en = 'Checking full-text search settings of attributes of the %1 table';"), "ContactInformation"), ErrorText);
					EndIf;
					
				ElsIf FoundAttribute.FullTextSearch = Metadata.ObjectProperties.FullTextSearchUsing.Use Then
					
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У объекта ""%1"" в табличной части ""%2""
					|у реквизита ""%3"" должен быть отключен полнотекстовый поиск.';
					|en = 'Attribute ""%3"" of object ""%1""
					|in table ""%2"" must have full-text search disabled.';"), OwnerMetadata.FullName(), "ContactInformation", TablePartType.Key);
					AddError(OwnerMetadata, StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Проверка настроек полнотекстового поиска у реквизитов табличной части %1';
							|en = 'Checking full-text search settings of attributes of the %1 table';"), "ContactInformation"), ErrorText);
					
				EndIf;
				
				If FoundAttribute.Type <> TablePartType.Value Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У объекта ""%1"" в табличной части ""%2""
					|тип реквизита ""%3"" не соответствует ожидаемому';
					|en = 'Attribute type ""%3"" of object ""%1""
					|in table ""%2"" does not match the expected type';"), OwnerMetadata.FullName(), "ContactInformation", TablePartType.Key);
					AddError(OwnerMetadata, StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Некорректные типы реквизитов табличной части %1';
							|en = 'Incorrect types of attributes of the %1 table';"), "ContactInformation"), ErrorText);
				EndIf;
			EndIf;
		EndDo;
		
		// Check if characteristics have values.
		If ContactInformationTabularSection.Attributes.Find("KindForList") <> Undefined Then
			CharacteristicsAreSet = False;
			CharacteristicsAreSetCorrectly = False;
			For Each Characteristic In OwnerMetadata.Characteristics Do // CharacteristicsDescription
				If Characteristic.CharacteristicTypes = Metadata.Catalogs["ContactInformationKinds"] Then
					PropertiesOfCIType = Undefined;
					If TypeOf(Characteristic.TypesFilterValue) = Type("CatalogRef.ContactInformationKinds") Then
						PropertiesOfCIType = Common.ObjectAttributesValues(Characteristic.TypesFilterValue, "PredefinedKindName, PredefinedDataName");
					EndIf;
					CharacteristicsAreSet = True;
					If Characteristic.TypesFilterField.Name = "GroupName"
						Or (PropertiesOfCIType <> Undefined And Not StrStartsWith(PropertiesOfCIType.PredefinedDataName, "Delete")) Then
						CharacteristicsAreSetCorrectly = True;
					EndIf;
				EndIf;
			EndDo;
			If Not CharacteristicsAreSet Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У объекта ""%1"" с табличной частью ""%2""
					|создан реквизит ""%3"", но не создана характеристика с видом ""%4""';
					|en = 'For object ""%1"" with table ""%2"",
					|attribute ""%3"" is created but the characteristic with type ""%4"" is not created';"),
					OwnerMetadata.FullName(), "ContactInformation", "KindForList", "ContactInformationKinds");
				AddError(OwnerMetadata, NStr("ru = 'Некорректно заполнены характеристики';
														|en = 'Characteristics are filled in incorrectly';"), ErrorText);
			EndIf;
			If CharacteristicsAreSet And Not CharacteristicsAreSetCorrectly Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У объекта ""%1"" с табличной частью ""%2""
					|в дополнительных характеристиках объекта метаданных для вида характеристики ""%3"" значение колонки ""Поле отбора видов"" не равно ""%4""';
					|en = 'For object ""%1"" with table ""%2"",
					|the ""Type filter field"" column value is not equal to ""%4"" in the additional characteristics of the metadata object for characteristic type ""%3""';"),
					OwnerMetadata.FullName(), "ContactInformation", "Catalog.ContactInformationKinds", "GroupName");
					
				AddError(OwnerMetadata, NStr("ru = 'Некорректно заполнены поля отборов видов характеристики';
														|en = 'Fields of the characteristic type filters are filled in incorrectly';"), ErrorText);
			EndIf;
		EndIf;
	EndDo;
	
	// Check if there are common code insertions.
	CheckedCalls = New Array;
	CheckedCalls.Add("ContactsManager.OnCreateAtServer(");
	CheckedCalls.Add("ContactsManager.OnReadAtServer(");
	CheckedCalls.Add("ContactsManager.FillCheckProcessingAtServer(");
	CheckedCalls.Add("ContactsManager.BeforeWriteAtServer(");
	
	CheckParameters = CheckingCodeInsertionParameters();
	CheckParameters.DataToCheck1 = ObjectsOwners;
	CheckParameters.ModuleType         = "DefaultObjectForm";
	CheckParameters.CodeString        = CheckedCalls;
	CheckForCodeInsertion(CheckParameters);
	
	// Check if there are additional code insertions.
	ObjectsOwners = New Array;
	OwnerObjectsAreOutdatedEmbeddingWay = New Array; 
	For Each ObjectToCheck In TableOfSpecies Do
		
		FormModule = FormModule(ObjectToCheck.OwnerMetadata.DefaultObjectForm);
		FoundProcedure = FindModuleProcedure(FormModule, "Attachable_ContinueContactInformationUpdate");
		If FoundProcedure <> Undefined Then
			ObjectsOwners.Add(ObjectToCheck.OwnerMetadata);
		Else	
			OwnerObjectsAreOutdatedEmbeddingWay.Add(ObjectToCheck.OwnerMetadata);
		EndIf;
		
		If ValueIsFilled(FormModule.Structure) Then
			ClearVariableFormModule(FormModule.Structure.Content);
			FormModule = Undefined;
		EndIf;
	EndDo;
	
	ContactInformation_CheckAdditionalCodeInserts(ObjectsOwners);
	ContactInformation_CheckAdditionalCodeInsertsOutdated(OwnerObjectsAreOutdatedEmbeddingWay);
	
	// If you intend to store contact information for the object table.
	ObjectsOwners = New Array;
	Filter = New Structure("HasTabularParts", True);
	For Each ObjectToCheck In TableOfSpecies.FindRows(Filter) Do
		ObjectsOwners.Add(ObjectToCheck.OwnerMetadata);
	EndDo;
	CheckParameters.DataToCheck1 = ObjectsOwners;
	CheckParameters.ModuleType         = "DefaultObjectForm";
	CheckParameters.CodeString        = "ContactsManager.AfterWriteAtServer(";
	CheckParameters.NameOfAProcedureOrAFunction = "";
	CheckForCodeInsertion(CheckParameters);
	
EndProcedure

Procedure Attachable_NationalLanguageSupport_CheckIntegration()
	
	// Common attributes.
	FormsOfMultilingualObjects = New Array;
	MultilingualObjects = New Array;
	
	UseAdditionalLanguageFunctionalOption = Metadata.FunctionalOptions.Find("UseAdditionalLanguage1");
	If UseAdditionalLanguageFunctionalOption  <> Undefined Then
		For Each Item In Metadata.FunctionalOptions["UseAdditionalLanguage1"].Content Do
			
			Attribute = Item.Object;
			
			If Metadata.CommonAttributes.Contains(Attribute) Then
				AutoUse = (Attribute.AutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse.Use);
				For Each CompositionItem In Attribute.Content Do
					
					If CompositionItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Use
						Or (AutoUse And CompositionItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Auto) Then
						
						If Not Common.IsRegister(CompositionItem.Metadata) Then
							If CompositionItem.Metadata.DefaultObjectForm <> Undefined Then
								FormsOfMultilingualObjects.Add(CompositionItem.Metadata.DefaultObjectForm);
							EndIf;
							MultilingualObjects.Add(CompositionItem.Metadata);
						ElsIf StrStartsWith(CompositionItem.Metadata.FullName(), "InformationRegister.") Then
							If CompositionItem.Metadata.DefaultRecordForm <> Undefined Then
								FormsOfMultilingualObjects.Add(CompositionItem.Metadata.DefaultRecordForm);
							EndIf;
						EndIf;
					EndIf;
					
				EndDo;
			Else
				MetadataObject = Attribute.Parent();
				If MetadataObject <> Undefined And Metadata.Catalogs.Contains(MetadataObject) Or Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject) Then
					MultilingualObjects.Add(Attribute.Parent());
				EndIf;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	FormsOfNonCulturalObjects = New Array;
	
	// Presentation table.
	CheckedMetadataTypes = New Array;
	CheckedMetadataTypes.Add(Metadata.Catalogs);
	CheckedMetadataTypes.Add(Metadata.ChartsOfCharacteristicTypes);
	
	For Each CheckedMetadataType In CheckedMetadataTypes Do
		For Each MetadataObject In CheckedMetadataType Do
			ItIsMultilingualFacility = MultilingualObjects.Find(MetadataObject) <> Undefined;
			If MetadataObject.TabularSections.Find("Presentations") <> Undefined Then
				For Each FormDetails In MetadataObject.Forms Do
					
					FormModule = FormModule(FormDetails);
					If StrFind(FormModule.ModuleText, "NationalLanguageSupportServer.OnCreateAtServer(") > 0 Then
						If ItIsMultilingualFacility Then
							FormsOfMultilingualObjects.Add(FormDetails);
						Else
							FormsOfNonCulturalObjects.Add(FormDetails);
						EndIf;
					EndIf;
					
					If ValueIsFilled(FormModule.Structure) Then
						ClearVariableFormModule(FormModule.Structure.Content);
						FormModule = Undefined;
					EndIf;
					
				EndDo;
			EndIf;
		EndDo;
	EndDo;
	
	MultilingualObjects       = CommonClientServer.CollapseArray(MultilingualObjects);
	
	CheckedCalls = New Array;
	CheckedCalls.Add("NationalLanguageSupportServer.OnCreateAtServer(");
	
	CheckedCalls.Add("Procedure Attachable_Opening(");
	CheckedCalls.Add("NationalLanguageSupportServer.OnReadAtServer(");
	CheckedCalls.Add("NationalLanguageSupportServer.BeforeWriteAtServer(");
	
	CheckParameters = CheckingCodeInsertionParameters();
	CheckParameters.DataToCheck1 = MultilingualObjects;
	CheckParameters.ModuleType         = "DefaultObjectForm";
	CheckParameters.CodeString        = CheckedCalls;
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters = CheckingCodeInsertionParameters();
	CheckParameters.DataToCheck1      = MultilingualObjects;
	CheckParameters.NameOfAProcedureOrAFunction = "Procedure AfterWriteAtServer";
	CheckParameters.ModuleType              = "DefaultObjectForm";
	CheckParameters.CodeString             = "NationalLanguageSupportServer.OnReadAtServer(";
	CheckForCodeInsertion(CheckParameters);
	
	
	
EndProcedure

Procedure Attachable_UserReminders_CheckIntegration()
	
	ArrayOfSources = New Array;
	ArrayOfSources.Add(TypeComposition("DefinedTypes.ReminderSubject.Type",,, "Catalog.MetadataObjectIDs"));
	ArrayOfSources.Add(TypeComposition("DefinedTypes.ReminderSubjectObject.Type",,, "Catalog.MetadataObjectIDs"));
	CompareTypes(ArrayOfSources, NStr("ru = 'Предмет напоминаний';
										|en = 'Reminder subject';"));
	
EndProcedure

Procedure Attachable_ItemOrderSetup_CheckIntegration()
	
	// Compare type content.
	ArrayOfSources = New Array;
	ArrayOfSources.Add(TypeComposition("DefinedTypes.ObjectWithCustomOrder.Type",,, "Catalog.MetadataObjectIDs"));
	ArrayOfSources.Add(ObjectsWithAdditionalOrderingDetailsComposition());
	CompareTypes(ArrayOfSources);
	
	// Check for code insertions.
	TypesArray = TypeComposition("DefinedTypes.ObjectWithCustomOrder.Type",,,
		"Catalog.QuestionnaireAnswersOptions,Catalog.MetadataObjectIDs");
	CheckedCalls = New Array;
	CheckedCalls.Add("AttachableCommands.OnCreateAtServer(");
	
	CheckParameters = CheckingCodeInsertionParameters();
	CheckParameters.DataToCheck1 = TypesArray;
	CheckParameters.ModuleType         = "DefaultListForm";
	CheckParameters.CodeString        = CheckedCalls;
	CheckForCodeInsertion(CheckParameters);
	
EndProcedure

Procedure Attachable_DataExchange_CheckIntegration()
	
	If Not IsDemoSSL() Then
		Return;
	EndIf;
	
	CheckAccessToNonExistentExchangePlanSettings();
	CheckLayoutsAndFormsAvailability();
	CheckCompositionOfCommonCommand();
	CheckExchangePlansComposition();
	CheckExchangePlanManagerModulesCodeInserts();
	CheckDefaultInformationBasePrefix();
	CheckConfigurationReceiverNameIndication();
	CheckDefinedTypeCompositionOfMessagingEndpoint();
	CheckToIncludeConfigurationExtensionForExchangePlansInServiceModel();
	
EndProcedure

Procedure Attachable_IBVersionUpdate_CheckIntegration()
	
	If Metadata.CommonTemplates.Find("SystemReleaseNotes") = Undefined Then
		AddError(Undefined, 
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Отсутствует макет %1';
																		|en = 'Template %1 is missing';"), "SystemReleaseNotes"),
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В конфигурации не создан общий макет %1.';
																		|en = 'Common template %1 is not created in the configuration.';"), "SystemReleaseNotes"));
	EndIf;
	
	CheckIfDeferredHandlersPropertiesValid();
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		CheckIfDeferredHandlersHaveSharedChangeableObjects();
	EndIf;
	
	// Check that the initial population code populates all predefined items of the configuration.
	ObjectsWithInitialFilling = InfobaseUpdateInternal.ObjectsWithInitialFilling();
	
	For Each ObjectWithInitialPopulation In ObjectsWithInitialFilling Do
		
		IsIncludesPredefined =  StrFind(ObjectWithInitialPopulation.Value, "Catalog") > 0 
			Or StrFind(ObjectWithInitialPopulation.Value, "ChartOfCharacteristicTypes") > 0
			Or StrFind(ObjectWithInitialPopulation.Value, "ChartOfAccounts") > 0 
			Or StrFind(ObjectWithInitialPopulation.Value, "ChartOfCalculationTypes") > 0;
		
		If Not IsIncludesPredefined Then
			Continue
		EndIf;
		
		ObjectMetadata = ObjectWithInitialPopulation.Key;
		
		PredefinedItemsNames = ObjectMetadata.GetPredefinedNames();
		If PredefinedItemsNames.Count() = 0 Then
			Continue;
		EndIf;
		
		FillParameters = InfobaseUpdateInternal.ParameterSetForFillingObject(ObjectMetadata);
		
		PredefinedData = FillParameters.PredefinedData;
		PopulationSettings = FillParameters.PredefinedItemsSettings;
		
		If Not PopulationSettings.IsColumnNamePredefinedData Then
			Continue;
		EndIf;
		
		NamesPredefinedWithoutFilling = New Array;
		
		For Each PredefinedItemName In PredefinedItemsNames Do
			If StrStartsWith(PredefinedItemName, "Delete") Then
				Continue;
			EndIf;
			
			If PredefinedData.Find(PredefinedItemName, "PredefinedDataName") = Undefined Then
				NamesPredefinedWithoutFilling.Add(PredefinedItemName);
			EndIf;
			
		EndDo;
		
		If NamesPredefinedWithoutFilling.Count() > 0 Then
			
			Brief1 = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для объекта ""%1"" отсутствует код заполнения предопределенных элементов.';
				|en = 'Object ""%1"" is missing population code for predefined items.';"),  ObjectMetadata.FullName());
			
			More = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Если для объекта %1 существуют обработчики заполнения предопределенных элементов, 
				|то рекомендуется перенести их в процедуру %3 модуля менеджера объекта (или в процедуру %3 общего модуля %4).
				|Если обработчики заполнения отсутствуют, то реализовать их в указанном месте для предопределенных элементов:
				|%2';
				|en = 'If handlers that fill in predefined items exist for object %1,
				|it is recommended that you move them to procedure %3 of the object manager module (or to procedure %3 of common module %4).
				|If such handlers are missing, implement them in the specified area for predefined items:
				|%2';"),
				ObjectMetadata.FullName(), StrConcat(NamesPredefinedWithoutFilling, Chars.LF), "OnInitialItemsFilling", "InfobaseUpdateOverridable");
			
			AddError(ObjectMetadata, Brief1, More);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure Attachable_PerformanceMonitor_CheckIntegration()
	
	MetadataDescriptions = PerformanceEvaluationMetadataDescription();
	
	MethodsArray = New Array;
	MethodsArray.Add("PerformanceMonitor.FixTimeConsumingOperationMeasure");
	MethodsArray.Add("PerformanceMonitor.EndTimeConsumingOperationMeasurement");
	MethodsArray.Add("PerformanceMonitorClient.FixTimeConsumingOperationMeasure");
	MethodsArray.Add("PerformanceMonitorClient.EndTimeConsumingOperationMeasurement");
	
	For Each MetadataDetails In MetadataDescriptions Do 
	
		For Each MetadataObject In Metadata[MetadataDetails.Key] Do
			CheckedModules = MetadataDetails.Value;
			For Each CheckedModule In CheckedModules Do
				If CheckedModule.Key = "Forms" Then
					For Each Form In MetadataObject.Forms Do // MetadataObjectForm
						ModuleText = ModuleText(MetadataObject, Form.Name); 
						ExecuteCheckKeyOperationsNaming(MetadataObject, ModuleText, MethodsArray, Form.Name);
					EndDo;
				ElsIf CheckedModule.Key = "Commands" Then
					For Each Command In MetadataObject.Commands Do // MetadataObjectCommand
						ModuleText = ModuleText(MetadataObject, Command.Name, True); 
						ExecuteCheckKeyOperationsNaming(MetadataObject, ModuleText, MethodsArray, Command.Name);
					EndDo;
				Else
					ModuleText = ModuleText(MetadataObject, CheckedModule.Key); 
					ExecuteCheckKeyOperationsNaming(MetadataObject, ModuleText, MethodsArray, CheckedModule.Key);
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
		
EndProcedure

Procedure Attachable_AttachableCommands_CheckIntegration()
	HasPrint = Common.SubsystemExists("StandardSubsystems.Print");
	HasReportsOptions = Common.SubsystemExists("StandardSubsystems.ReportsOptions");
	HasObjectsFilling = True;
	
	SourcesSettings = PluggableCommands_ConfiguringSources();
	InformationRecords = PlugabbleCommands_ConnectedObjectsInformation();
	If InformationRecords.HadCriticalErrors Then
		Return;
	EndIf;
	AttachedObjects = InformationRecords.AttachedObjects;
	EmptyConnectedObjectSettings = InformationRecords.EmptyConnectedObjectSettings;
	
	EmptySourceSettings = New Structure;
	EmptySourceSettings.Insert("Print",                         False);
	EmptySourceSettings.Insert("PrintSettingsPrint",          False);
	EmptySourceSettings.Insert("ReportsOptions",                False);
	EmptySourceSettings.Insert("ObjectsFilling",             False);
	EmptySourceSettings.Insert("AdditionalReportsAndDataProcessors", False);
	EmptySourceSettings.Insert("UserReminders",        False);
	
	ArrayOfExceptionsPresentationsOfUserReminderObjects = New Array;
	ArrayOfExceptionsPresentationsOfUserReminderObjects.Add("Catalog.MetadataObjectIDs");
	
	MetadataObjectsWithFormsTypes = "BusinessProcesses, Documents, DocumentJournals,
		|Tasks, DataProcessors, Reports, Enums,
		|ChartsOfCalculationTypes, ChartsOfCharacteristicTypes, ExchangePlans, ChartsOfAccounts,
		|AccountingRegisters, AccumulationRegisters, CalculationRegisters, InformationRegisters,
		|Catalogs, SettingsStorages";
	ArrayOfViews = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Upper(MetadataObjectsWithFormsTypes), ",", True, True);
	For Each KindInPlural1 In ArrayOfViews Do
		MetadataObjectCollection = Metadata[KindInPlural1]; //MetadataObjectCollection
		For Each MetadataObject In MetadataObjectCollection Do
			If IsExtensionObject(MetadataObject) Then
				Continue;
			EndIf;
			SourceSettings = SourcesSettings.Find(MetadataObject, "Metadata");
			ThisIsSource = (SourceSettings <> Undefined);
			If SourceSettings = Undefined Then
				SourceSettings = EmptySourceSettings;
			EndIf;
			ConnectedObjectSettings = AttachedObjects.Find(MetadataObject, "Metadata");
			If ConnectedObjectSettings = Undefined Then
				ConnectedObjectSettings = EmptyConnectedObjectSettings;
			EndIf;
			
			// Analyze integration in the manager module.
			ManagerModuleText = ModuleText(MetadataObject, "ManagerModule");
			
			If HasPrint Then
				If SourceSettings.PrintSettingsPrint Then
					IsPlacedWhenDefiningPrintSettings = (FindMethod(ManagerModuleText, "OnDefinePrintSettings") <> Undefined);
					If IsPlacedWhenDefiningPrintSettings And ConnectedObjectSettings.AddPrintCommands Then
						PluggableCommands_ScriptIntersectionError(MetadataObject, "PrintManagementOverridable.OnDefineObjectsWithPrintCommands");
					ElsIf Not IsPlacedWhenDefiningPrintSettings Then
						Brief1 = NStr("ru = 'В модуле менеджера отсутствует обязательная процедура.';
										|en = 'The manager module does not contain the required procedure';");
						More = NStr("ru = 'В модуле менеджера отсутствует обязательная процедура ""%1"".';
										|en = 'The manager module does not contain the required ""%1"" procedure';");
						More = StringFunctionsClientServer.SubstituteParametersToString(More, "OnDefinePrintSettings");
						AddError(MetadataObject, Brief1, More);
						Continue;
					ElsIf Not ConnectedObjectSettings.AddPrintCommands Then
						ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
						ObjectSettings = New Structure("OnSpecifyingRecipients, OnAddPrintCommands", False, False);
						Try
							ObjectManager.OnDefinePrintSettings(ObjectSettings);
						Except
						 	Brief1 = NStr("ru = 'В процедура модуля менеджера вызвала ошибку.';
											|en = 'The manager module procedure caused an error.';");
							More = NStr("ru = 'В модуле менеджера, процедура ""%1"" вызвала ошибку.';
											|en = 'In the manager module, the ""%1"" procedure caused an error.';");
							More = StringFunctionsClientServer.SubstituteParametersToString(More, "OnDefinePrintSettings");
							AddError(MetadataObject, Brief1, More);
							Continue;
						EndTry;
						
						If ObjectSettings.OnSpecifyingRecipients And FindMethod(ManagerModuleText, "OnSpecifyingRecipients") = Undefined Then
							PluggableCommands_MissingProcedureError(MetadataObject, "OnSpecifyingRecipients");
						ElsIf Not ObjectSettings.OnSpecifyingRecipients And FindMethod(ManagerModuleText, "OnSpecifyingRecipients") <> Undefined Then
							Brief1 = NStr("ru = 'В процедуре модуля менеджера отсутствует установка свойства';
											|en = 'The property is not set in the manager module procedure';");
							More = NStr("ru = 'В модуле менеджера, в процедуре ""%1"" отсутствует установка свойства ""%2"".';
											|en = 'In the manager module, the ""%2"" property is not set in the ""%1"" procedure.';");
							More = StringFunctionsClientServer.SubstituteParametersToString(More, "OnDefinePrintSettings", "OnSpecifyingRecipients");
							AddError(MetadataObject, Brief1, More);
						EndIf;
						
						If ObjectSettings.OnAddPrintCommands And FindMethod(ManagerModuleText, "AddPrintCommands") = Undefined Then
							PluggableCommands_MissingProcedureError(MetadataObject, "AddPrintCommands");
						ElsIf Not ObjectSettings.OnAddPrintCommands And FindMethod(ManagerModuleText, "AddPrintCommands") <> Undefined Then
							Brief1 = NStr("ru = 'В процедуре модуля менеджера отсутствует установка свойства';
											|en = 'The property is not set in the manager module procedure';");
							More = NStr("ru = 'В модуле менеджера, в процедуре ""%1"" отсутствует установка свойства ""%2"".';
											|en = 'In the manager module, the ""%2"" property is not set in the ""%1"" procedure.';");
							More = StringFunctionsClientServer.SubstituteParametersToString(More, "OnDefinePrintSettings", "OnAddPrintCommands");
							AddError(MetadataObject, Brief1, More);
						EndIf;
					Else
						PluggableCommands_MissingProcedureError(MetadataObject, "OnDefinePrintSettings");
					EndIf;
									
				Else
							
					ProcedurePostedAddPrintCommands = (FindMethod(ManagerModuleText, "AddPrintCommands") <> Undefined);
					If ProcedurePostedAddPrintCommands Then
						If SourceSettings.Print And ConnectedObjectSettings.AddPrintCommands Then
							PluggableCommands_ScriptIntersectionError(MetadataObject, "PrintManagementOverridable.OnDefineObjectsWithPrintCommands");
						ElsIf Not SourceSettings.Print And Not ConnectedObjectSettings.AddPrintCommands Then
							PluggableCommands_ErrorObjectNotRegisteredInProcedure(MetadataObject, "PrintManagementOverridable.OnDefineObjectsWithPrintCommands");
						EndIf;
					Else
						If SourceSettings.Print Or ConnectedObjectSettings.AddPrintCommands Then
							PluggableCommands_MissingProcedureError(MetadataObject, "AddPrintCommands");
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			
			If HasReportsOptions Then
				ProcedurePostedAddReportCommands = (FindMethod(ManagerModuleText, "AddReportCommands") <> Undefined);
				If ProcedurePostedAddReportCommands Then
					If SourceSettings.ReportsOptions And ConnectedObjectSettings.AddReportCommands Then
						PluggableCommands_ScriptIntersectionError(MetadataObject, "ReportsOptionsOverridable.DefineObjectsWithReportCommands");
					ElsIf Not SourceSettings.ReportsOptions And Not ConnectedObjectSettings.AddReportCommands Then
						PluggableCommands_ErrorObjectNotRegisteredInProcedure(MetadataObject, "ReportsOptionsOverridable.DefineObjectsWithReportCommands");
					EndIf;
				Else
					If SourceSettings.ReportsOptions Or ConnectedObjectSettings.AddReportCommands Then
						PluggableCommands_MissingProcedureError(MetadataObject, "AddReportCommands");
					EndIf;
				EndIf;
			EndIf;
			
			If HasObjectsFilling Then
				ProcedurePostedAddFillCommands = (FindMethod(ManagerModuleText, "AddFillCommands") <> Undefined);
				If ProcedurePostedAddFillCommands Then
					If SourceSettings.ObjectsFilling And ConnectedObjectSettings.AddFillCommands Then
						PluggableCommands_ScriptIntersectionError(MetadataObject, "ObjectsFillingOverridable.OnDefineObjectsWithFIllingCommands");
					ElsIf Not SourceSettings.ObjectsFilling And Not ConnectedObjectSettings.AddFillCommands Then
						PluggableCommands_ErrorObjectNotRegisteredInProcedure(MetadataObject, "ObjectsFillingOverridable.OnDefineObjectsWithFIllingCommands");
					EndIf;
				Else
					If SourceSettings.ObjectsFilling Or ConnectedObjectSettings.AddFillCommands Then
						PluggableCommands_MissingProcedureError(MetadataObject, "AddFillCommands");
					EndIf;
				EndIf;
			EndIf;
			
			// Analyze integration into forms.
			FormsWithOptionalEmbedding = PlugabbleCommands_FormsWithOptionalImplementation(MetadataObject);
			For Each Form In MetadataObject.Forms Do // MetadataObjectForm
				FormModule = FormModule(Form);
				RequireImplementation = False;
				IsObjectForm = False;
				
				If ThisIsSource And FormsWithOptionalEmbedding.Find(Form) = Undefined Then
					MainPropertyType = MainFormPropertyType(Form);
					
					If MainPropertyType <> Undefined And Metadata.FindByType(MainPropertyType) = MetadataObject
						And Not Metadata.DataProcessors.Contains(MetadataObject) Then
						RequireImplementation = True;
						IsObjectForm = True;
					EndIf;
			
					If MainPropertyType = Type("DynamicList") Then
						MainTableOfFormListName = MainTableOfFormListName(Form);
						If MainTableOfFormListName <> Undefined
							And Common.MetadataObjectByFullName(MainTableOfFormListName) = MetadataObject Then
							RequireImplementation = True;
						EndIf;
					EndIf;
				EndIf;
				
				FormModuleText = ModuleText(MetadataObject, Form.Name);
				
				Present = New Array;
				Absent = New Array;
				
				InsertDescription = StringFunctionsClientServer.SubstituteParametersToString("call %1", "AttachableCommands.OnCreateAtServer");
				WhenCreating = FindMethod(FormModuleText, "OnCreateAtServer");
				HasInsertionAtCreatingAtServer = False;
				If WhenCreating <> Undefined
					And FindMethodCall(WhenCreating.Content, "AttachableCommands.OnCreateAtServer(") <> Undefined Then
					Present.Add(InsertDescription);
					HasInsertionAtCreatingAtServer = True;
				Else
					Absent.Add(InsertDescription);
				EndIf;
				
				OutdatedEmbeddingMethod = False;
				
				FoundProcedure = FindModuleProcedure(FormModule, "Attachable_ExecuteCommand");
				If FoundProcedure = Undefined Then
					Absent.Add("Procedure Attachable_ExecuteCommand");
				Else
					Present.Add("Procedure Attachable_ExecuteCommand");
					
					ProcedureText = BlockContentsToString(FoundProcedure);
					If StrFind(ProcedureText, "AttachableCommandsClient.ExecuteCommand(") > 0 Then
						OutdatedEmbeddingMethod = True;
					EndIf;
				EndIf;
				
				SwitchToNotObsoleteIntegrationMethod = False;
				
				FoundProcedure = FindModuleProcedure(FormModule, "Attachable_ContinueCommandExecutionAtServer");
				If Not OutdatedEmbeddingMethod Then
					If FoundProcedure = Undefined Then
						Absent.Add("Procedure Attachable_ContinueCommandExecutionAtServer");
					Else
						Present.Add("Procedure Attachable_ContinueCommandExecutionAtServer");
					EndIf;
				ElsIf FoundProcedure <> Undefined Then
					Absent.Add("AttachableCommandsClient.StartCommandExecution");
					SwitchToNotObsoleteIntegrationMethod = True;
				EndIf;
				
				If OutdatedEmbeddingMethod And (Not SwitchToNotObsoleteIntegrationMethod) Then
					FoundProcedure = FindModuleProcedure(FormModule, "Attachable_ExecuteCommandAtServer");
					If FoundProcedure = Undefined Then
						Absent.Add("Procedure Attachable_ExecuteCommandAtServer");
					Else
						Present.Add("Procedure Attachable_ExecuteCommandAtServer");
					EndIf;
				Else
					FoundProcedure = FindModuleProcedure(FormModule, "ExecuteCommandAtServer");
					If FoundProcedure = Undefined Then
						Absent.Add("Procedure ExecuteCommandAtServer");
					Else
						ProcedureText = BlockContentsToString(FoundProcedure);
						If StrFind(ProcedureText, "AttachableCommandsClient.StartCommandExecution(") > 0 Then
							Present.Add("Procedure ExecuteCommandAtServer");
						EndIf;
					EndIf;
				EndIf;
				
				FoundProcedure = FindModuleProcedure(FormModule, "Attachable_UpdateCommands");
				If FoundProcedure = Undefined Then
					Absent.Add("Procedure Attachable_UpdateCommands");
				Else
					Present.Add("Procedure Attachable_UpdateCommands");
				EndIf;
				
				If IsObjectForm Then
					InsertDescription = StringFunctionsClientServer.SubstituteParametersToString("call %1", "AttachableCommandsClient.AfterWrite");
					AfterWrite = FindMethod(FormModuleText, "AfterWrite");
					If AfterWrite <> Undefined
						And FindMethodCall(AfterWrite.Content, "AttachableCommandsClient.AfterWrite(") <> Undefined Then
						Present.Add(InsertDescription);
					Else
						Absent.Add(InsertDescription);
					EndIf;
				EndIf;
				
				SourceSubsystems = New Array;
				If SourceSettings.ReportsOptions Then
					SourceSubsystems.Add(
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Варианты отчетов (см. %1.%2)';
								|en = 'Report options (see %1.%2)';"), "ReportsOptionsOverridable", "DefineObjectsWithReportCommands"));
				EndIf;
				If SourceSettings.AdditionalReportsAndDataProcessors Then
					SourceSubsystems.Add(
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Дополнительные отчеты и обработки (см. состав определяемого типа %1)';
								|en = 'Additional reports and data processors (see content of the %1 type collection)';"), "ObjectWithAdditionalCommands"));
				EndIf;
				If SourceSettings.ObjectsFilling Then
					SourceSubsystems.Add(
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Заполнение объектов (см. %1.%2)';
								|en = 'Filling in objects (see %1.%2)';"), "ObjectsFillingOverridable", "OnDefineObjectsWithFIllingCommands"));
				EndIf;
				If SourceSettings.Print Then
					SourceSubsystems.Add(
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Печать (см. %1.%2)';
								|en = 'Print (see %1.%2)';"), "PrintManagementOverridable", "OnDefineObjectsWithPrintCommands"));
				EndIf;
				If SourceSettings.UserReminders Then
					SourceSubsystems.Add(
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Напоминания пользователя (см. состав определяемых типов: %1, %2)';
								|en = 'Напоминания пользователя (см. состав определяемых типов: %1, %2)';"), "ReminderSubject", "ReminderSubjectObject"));
				EndIf;
				
				InsertDescription = StrConcat(SourceSubsystems, Chars.LF);
				If SourceSubsystems.Count() = 1 Then
					InsertDescription = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Объект подключен к подсистеме %1.';
							|en = 'Object is attached to the %1 subsystem.';"), InsertDescription);
				ElsIf SourceSubsystems.Count() > 1 Then
					InsertDescription = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Объект подключен к подсистемам:
							|%1.';
							|en = 'Object is attached to subsystems:
							|%1.';"), InsertDescription);
				EndIf;
				
				ObjectPresentation = MetadataObjectTypeView(MetadataObject);
				IsException = (SourceSettings.UserReminders
					And (ArrayOfExceptionsPresentationsOfUserReminderObjects.Find(ObjectPresentation) <> Undefined));
				
				If RequireImplementation Then
					If Absent.Count() > 0 Then
						Brief1 = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'В форме ""%1"" отсутствуют фрагменты кода';
								|en = 'Code snippets are missing in the %1 form';"),
							Form.Name);
						If Present.Count() > 0 Then
							More = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = 'Отсутствуют: %1.';
									|en = 'Missing: %1.';"),
								StrConcat(Absent, "; "));
						Else
							More = NStr("ru = 'Отсутствуют фрагменты кода подсистемы ""Подключаемые команды"".';
											|en = 'The ""Attachable commands"" subsystem code snippets are missing.';");
							If ValueIsFilled(InsertDescription) Then
								More = InsertDescription + Chars.LF + More;
							EndIf;
						EndIf;
						If Not IsException Then
							AddError(MetadataObject, Brief1, More);
						EndIf;
					EndIf;
				ElsIf HasInsertionAtCreatingAtServer Then
					If Present.Count() > 0
						And Absent.Count() > 0 Then
						Brief1 = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'В форме ""%1"" вставлены не все фрагменты кода';
								|en = 'Not all code snippets are inserted in the %1 form';"),
							Form.Name);
						More = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Отсутствуют: %1. Присутствуют: %2.';
								|en = 'Missing: %1. Present: %2.';"),
							StrConcat(Absent, "; "),
							StrConcat(Present, "; "));
						If Not IsException Then
							AddError(MetadataObject, Brief1, More);
						EndIf;
					EndIf;
				EndIf;
				
				If RequireImplementation And OutdatedEmbeddingMethod Then
					FoundProcedure = FindModuleProcedure(FormModule, "Attachable_ExecuteCommandAtServer"); // See NewBlock
					If FoundProcedure <> Undefined Then
						If Not StrEndsWith(Lower(TrimAll(FoundProcedure.Title)), Lower(" Export")) Then
							ErrorTitle = NStr("ru = 'Отсутствует ключевое слово Экспорт';
													|en = 'The Export keyword is missing';");
							ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = 'У процедуры %1 отсутствует ключевое слово %2,
								|подсистема %3 не сможет ее вызывать.';
								|en = 'Procedure %1 does not have keyword %2.
								|Subsystem %3 cannot call it.';"), "Attachable_ExecuteCommandAtServer", 
								"Export", "AttachableCommands");
							If Not IsException Then
								AddError(Form, ErrorTitle, ErrorText);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				
				If ValueIsFilled(FormModule.Structure) Then
					ClearVariableFormModule(FormModule.Structure.Content);
					FormModule = Undefined;
				EndIf;
				
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

Procedure Attachable_Users_CheckIntegration()
	
	TypesUser = Metadata.DefinedTypes.User.Type.Types();
	ExternalUserTypes = Metadata.DefinedTypes.ExternalUser.Type.Types();
	ExternalUserObjectTypes = Metadata.DefinedTypes.ExternalUserObject.Type.Types();
	ExternalAccessCommandTypes = Metadata.Catalogs.ExternalUsers.Commands.ExternalAccess.CommandParameterType.Types();
	
	UsedExternalUsers = True;
	If (ExternalUserTypes.Count() = 1 And ExternalUserTypes[0] = Type("String"))
		And (ExternalUserObjectTypes.Count() = 1 And ExternalUserObjectTypes[0] = Type("CatalogObject.MetadataObjectIDs"))
		And (TypesUser.Count() = 1 And TypesUser[0] = Type("CatalogRef.Users"))
		And ExternalAccessCommandTypes.Count() = 0 Then
		UsedExternalUsers = False;
	EndIf;
	
	// Check type content.
	If UsedExternalUsers Then
		ArrayOfSources = New Array;
		ArrayOfSources.Add(TypeComposition("DefinedTypes.ExternalUser.Type"));
		ArrayOfSources.Add(TypeComposition("DefinedTypes.ExternalUserObject.Type",,, "Catalog.MetadataObjectIDs"));
		ArrayOfSources.Add(TypeComposition("Catalogs.ExternalUsers.Commands.ExternalAccess.CommandParameterType"));
		ArrayOfSources.Add(TypeComposition("DefinedTypes.User.Type",,, "Catalog.Users"));
		
		CompareTypes(ArrayOfSources, NStr("ru = 'Внешний пользователь';
											|en = 'External user';"));
	EndIf;
	
	// Check for a direct call to session parameters.
	CheckDirectAccessToSessionParameters();
	
	// Check for role assignments.
	ErrorList = New ValueList;
	Users.CheckRoleAssignment(True, ErrorList);
	
	BriefErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Ошибка в процедуре %1 общего модуля %2.';
			|en = 'Error in procedure %1 of common module %2.';"), "OnDefineRoleAssignment", "UsersOverridable");
	For Each Error In ErrorList Do
		AddError(Error.Value, BriefErrorDetails, Error.Presentation);
	EndDo;
	
EndProcedure

Procedure Attachable_ObjectsPrefixes_CheckIntegration()
	
	OrganizationPrefixTypes = SubscriptionsByHandlerComposition("ObjectsPrefixesEvents.SetCompanyPrefix");
	IBPrefixTypes = SubscriptionsByHandlerComposition("ObjectsPrefixesEvents.SetInfobasePrefix");
	IBAndOrganizationsPrefixTypes = SubscriptionsByHandlerComposition("ObjectsPrefixesEvents.SetInfobaseAndCompanyPrefix");
	
	If OrganizationPrefixTypes.Count() = 0 And IBAndOrganizationsPrefixTypes.Count() = 0 Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ожидается наличие подписки на событие с обработчиком:
			|%1.%2 
			|или %1.%3';
			|en = 'Subscription to event with handler is expected:
			|%1.%2 
			|or %1.%3';"), "ObjectsPrefixesEvents", "SetCompanyPrefix", "SetInfobaseAndCompanyPrefix");
		AddError(Metadata.CommonModules.ObjectsPrefixesEvents, NStr("ru = 'Отсутствуют подписки установки префикса';
																				|en = 'Prefix setting subscriptions are missing';"), ErrorText);
	EndIf;
	
	If IBPrefixTypes.Count() = 0 And IBAndOrganizationsPrefixTypes.Count() = 0 Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ожидается наличие подписки на событие с обработчиком:
			|%1.%2
			|или %1.%3';
			|en = 'Subscription to event with handler is expected:
			|%1.%2
			|or %1.%3';"), "ObjectsPrefixesEvents", "SetInfobasePrefix", "SetInfobaseAndCompanyPrefix");
		AddError(Metadata.CommonModules.ObjectsPrefixesEvents, NStr("ru = 'Отсутствуют подписки установки префикса';
																				|en = 'Prefix setting subscriptions are missing';"), ErrorText);
	EndIf;
	
	ArrayOfSources = New Array;
	ArrayOfSources.Add(OrganizationPrefixTypes);
	ArrayOfSources.Add(IBPrefixTypes);
	ArrayOfSources.Add(IBAndOrganizationsPrefixTypes);
	TypesIntersection(ArrayOfSources);
	
	CheckExtraSubscriptionPrefixes();
	
EndProcedure

Procedure Attachable_FilesOperations_CheckIntegration()
	
	ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
	ModuleFilesOperationsOverridable = Common.CommonModule("FilesOperationsOverridable");
	
	ObjectsWithFiles = New Array;
	FilesOwners = New Array;
	
	ExcludedDirectories = New Array;
	ExcludedDirectories.Add("Catalog.Files");
	ExcludedDirectories.Add("Catalog.FilesVersions");
	
	FilesOwnersTypes = Metadata.Catalogs["Files"].Attributes.FileOwner.Type.Types();
	AttachedFilesTypes = Metadata.DefinedTypes["AttachedFile"].Type.Types();
	AttachedFilesTypesObject = Metadata.DefinedTypes["AttachedFileObject"].Type.Types();
	AttachedFilesTypesOwners = Metadata.DefinedTypes["AttachedFilesOwner"].Type.Types();
	AttachedFilesObjectTypesOwners = Metadata.DefinedTypes["AttachedFilesOwnerObject"].Type.Types();
	
	For Each CatalogMetadata In Metadata.Catalogs Do
		
		CatalogName = CatalogMetadata.Name;
		
		If Not StrEndsWith(CatalogName, "AttachedFiles") Then
			Continue;
		EndIf;
		
		If StrStartsWith(CatalogName, "Delete") Then
			ExcludedDirectories.Add(CatalogMetadata.FullName());
			Continue;
		EndIf;
		
		// Add all catalogs whose names end with "AttachedFiles" to the array.
		ObjectsWithFiles.Add(CatalogMetadata);
		
		If CatalogMetadata.Attributes.Find("FileOwner") = Undefined Then
			Continue;
		EndIf;
		
		OwnerTypes = CatalogMetadata.Attributes.FileOwner.Type.Types();
		For Each Type In OwnerTypes Do
			
			If Not Common.IsReference(Type) Then
				Continue;
			EndIf;
			
			DirectoriesWithFilesNames = ModuleFilesOperationsInternal.FileStorageCatalogNames(Type);
			For Each CatalogName In DirectoriesWithFilesNames Do
				
				DirectoryByNameMetadata = Metadata.Catalogs.Find(CatalogName);
				If DirectoryByNameMetadata <> Undefined
					And ObjectsWithFiles.Find(DirectoryByNameMetadata) = Undefined Then
					// The array contains catalogs that the developers set as storage catalogs.
					// For example, in the method "FilesOperationsOverridable.OnDefineFileStorageCatalogs"
					ObjectsWithFiles.Add(DirectoryByNameMetadata);
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	// The array includes all the catalogs that are included in the type collection. Exceptions: Catalogs, Files, and FilesVersions.
	For Each Type In AttachedFilesTypes Do
		
		If Type = Type("CatalogRef.Files")
			Or Type = Type("CatalogRef.FilesVersions")
			Or Not Common.IsReference(Type) Then
			Continue;
		EndIf;
		
		TypeAsString = Common.TypePresentationString(Type);
		CatalogMetadata = Metadata.Catalogs.Find(StrReplace(TypeAsString, "CatalogRef.", ""));
		If CatalogMetadata <> Undefined
			And ObjectsWithFiles.Find(CatalogMetadata) = Undefined Then
			ObjectsWithFiles.Add(CatalogMetadata);
		EndIf;
		
	EndDo;
	
	TableOfOwnersOfAttachedFiles = InformationAboutTheOwnersOfAttachedFiles();
	
	ArrayOfFileOwners = New Array();
	For Each FilesOwnerType In FilesOwnersTypes Do
		ArrayOfFileOwners.Add(Metadata.FindByType(FilesOwnerType));
	EndDo;
	
	For Each OwnerTypeOfAttachedFiles In AttachedFilesTypesOwners Do
		MetadataOfTheOwnerOfAttachedFiles = Metadata.FindByType(OwnerTypeOfAttachedFiles);
		If Not ArrayOfFileOwners.Find(MetadataOfTheOwnerOfAttachedFiles) = Undefined Then
			Continue;
		EndIf;
		NewOwner = TableOfOwnersOfAttachedFiles.Add();
		NewOwner.AttachedFilesOwner = MetadataOfTheOwnerOfAttachedFiles;
		NewOwner.OwnerTypeOfAttachedFiles = OwnerTypeOfAttachedFiles;
	EndDo;
	
	For Each OwnerTypeOfAttachedFilesObject In AttachedFilesObjectTypesOwners Do
		MetadataOfTheOwnerOfTheAttachedFilesObject = Metadata.FindByType(OwnerTypeOfAttachedFilesObject);
		If Not ArrayOfFileOwners.Find(MetadataOfTheOwnerOfTheAttachedFilesObject) = Undefined Then
			Continue;
		EndIf;
		NewOwner = TableOfOwnersOfAttachedFiles.Add();
		NewOwner.AttachedFilesOwner = MetadataOfTheOwnerOfTheAttachedFilesObject;
		NameParts = StrSplit(MetadataOfTheOwnerOfTheAttachedFilesObject.FullName(), ".");
		OwnerTypeOfAttachedFilesByString = NameParts[0] + "Ref." + NameParts[1];
		NewOwner.OwnerTypeOfAttachedFiles = Type(OwnerTypeOfAttachedFilesByString);
	EndDo;
	
	TableOfOwnersOfAttachedFiles.GroupBy("AttachedFilesOwner, OwnerTypeOfAttachedFiles");
	
	CatalogNames = New Map;
	For Each TableRow In TableOfOwnersOfAttachedFiles Do
		ModuleFilesOperationsOverridable.OnDefineFileStorageCatalogs(TableRow.OwnerTypeOfAttachedFiles, CatalogNames);
	EndDo;
	
	For Each TableRow In TableOfOwnersOfAttachedFiles Do
		
		// Catalog MetadataObjectIDs is an exception.
		If TableRow.AttachedFilesOwner = Metadata.Catalogs.MetadataObjectIDs Then
			Continue;
		EndIf;
		
		If StrStartsWith(TableRow.AttachedFilesOwner.Name, "Delete") Then
			Continue;
		EndIf;
		
		ThereIsADirectoryOfAttachedFiles = False;
		TheseArePredefinedAttachedFiles = False;
		For Each CatalogMetadata In ObjectsWithFiles Do
			TheseArePredefinedAttachedFiles = TheseArePredefinedAttachedFiles Or TableRow.AttachedFilesOwner = CatalogMetadata;
			If Not CatalogMetadata.Attributes.FileOwner.Type.Types().Find(TableRow.OwnerTypeOfAttachedFiles) = Undefined
				Or (TableRow.AttachedFilesOwner = CatalogMetadata
					And CatalogNames.Get(TableRow.AttachedFilesOwner.Name) <> Undefined) Then
				ThereIsADirectoryOfAttachedFiles = True;
				Break;
			EndIf;
		EndDo;
		
		If Not ThereIsADirectoryOfAttachedFiles And Not TheseArePredefinedAttachedFiles Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Для справочника ""%1"" не создан справочник хранения присоединенных файлов.';
																						|en = 'A catalog for storing attachments for catalog ""%1"" is not created.';"), TableRow.AttachedFilesOwner.Name);
			AddError(TableRow.AttachedFilesOwner.Name, NStr("ru = 'Ошибка создания справочника хранения присоединенных файлов.';
																				|en = 'Cannot create a catalog for storing attachments.';"), ErrorText);
		ElsIf Not ThereIsADirectoryOfAttachedFiles And TheseArePredefinedAttachedFiles Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Для справочника ""%1"" создан справочник хранения присоединенных файлов,
				|но данный справочник является переопределяемым справочником для хранения присоединенных файлов и не описан в процедуре ""%2()"" общего модуля ""%3"".';
				|en = 'A catalog for storing attachments is created for catalog ""%1""
				|but this catalog is an overridable catalog for storing attachments and is not described in procedure ""%2()"" of common module ""%3"".';"),
				TableRow.AttachedFilesOwner.Name, "OnDefineFileStorageCatalogs", "FilesOperationsOverridable");
			AddError(TableRow.AttachedFilesOwner.Name, NStr("ru = 'Ошибка создания справочника хранения присоединенных файлов.';
																				|en = 'Cannot create a catalog for storing attachments.';"), ErrorText);
		EndIf;
		
	EndDo;
	
	For Each CatalogMetadata In ObjectsWithFiles Do
		CatalogName = CatalogMetadata.Name;
		// 1. All catalogs are included in type collections.
		ReferenceValueType = Type("CatalogRef." + CatalogName);
		If AttachedFilesTypes.Find(ReferenceValueType) = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Справочник ""%1"", содержащий присоединенные файлы,
				|не включен в определяемый тип ""%2"".';
				|en = 'Catalog ""%1"" that contains attachments
				|is not included in the %2 type collection.';"), CatalogName, "AttachedFile");
			AddError(CatalogMetadata, NStr("ru = 'Справочник не включен в определяемый тип';
														|en = 'Catalog is not included in the type collection';"), ErrorText);
		EndIf;
		
		ReferenceObjectValueType = Type("CatalogObject." + CatalogName);
		If AttachedFilesTypesObject.Find(ReferenceObjectValueType) = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Справочник ""%1"", содержащий присоединенные файлы,
				|не включен в определяемый тип ""%2"".';
				|en = 'Catalog ""%1"" that contains attachments
				|is not included in the %2 type collection.';"), CatalogName, "AttachedFileObject");
			AddError(CatalogMetadata, NStr("ru = 'Справочник не включен в определяемый тип';
														|en = 'Catalog is not included in the type collection';"), ErrorText);
		EndIf;

		// 2. Check list of attributes.
		CheckCatalogAttributesCompositionPatternMatching(CatalogName, "FilesOperationsAttributesComposition");
		
		If CatalogMetadata.Attributes.Find("FileOwner") = Undefined Then
			Continue;
		EndIf;
		
		OwnersTypes = CatalogMetadata.Attributes.FileOwner.Type.Types();
		For Each OwnerType In OwnersTypes Do
			// 3. Check if there are non-reference owners.
			If Not Common.IsReference(OwnerType) Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В реквизите ""%1"" справочника %2 указано значение не ссылочного типа';
						|en = 'In attribute ""%1"" of catalog %2, a value of non-reference type is specified';"), 
					"FileOwner", CatalogName);
				
				AddError(CatalogMetadata, StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Некорректный тип реквизита ""%1""';
						|en = 'Incorrect type of attribute ""%1""';"), "FileOwner"), ErrorText);
			ElsIf FilesOwners.Find(OwnerType) = Undefined Then
				
				// 4. All reference-type owners are included in type collections.
				FilesOwners.Add(OwnerType);
				
				OwnerMetadataObject = Metadata.FindByType(OwnerType);
				If AttachedFilesTypesOwners.Find(OwnerType) = Undefined Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'В реквизите ""%1"" справочника %2 указано значение ""%3"", не включенное в определяемый тип ""%4"".';
							|en = 'The ""%1"" attribute of the %2 catalog contains the ""%3"" value that is not included in the ""%4"" type collection.';"),
						"FileOwner", CatalogName, OwnerMetadataObject.Name, "AttachedFilesOwner");
					
					AddError(CatalogMetadata, NStr("ru = 'Владелец не включен в определяемый тип';
																|en = 'Owner is not included in the type collection';"), ErrorText);
				EndIf;
				
				ObjectTypeString = StrReplace(Common.TypePresentationString(OwnerType), "Ref", "Object");
				If Not StrStartsWith(ObjectTypeString, "DocumentObject") Then
					
					If AttachedFilesObjectTypesOwners.Find(Type(ObjectTypeString)) = Undefined Then
						ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'В реквизите ""%1"" справочника %2 указано значение ""%3"", не включенное в определяемый тип ""%4"".';
								|en = 'The ""%1"" attribute of the %2 catalog contains the ""%3"" value that is not included in the ""%4"" type collection.';"),
							"FileOwner", CatalogName, OwnerMetadataObject.Name, "AttachedFilesOwnerObject");
						
						AddError(CatalogMetadata, NStr("ru = 'Владелец не включен в определяемый тип';
																	|en = 'Owner is not included in the type collection';"), ErrorText);
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	OwnersMetadata = New Array;
	For Each OwnerType In FilesOwners Do
		OwnersMetadata.Add(Metadata.FindByType(OwnerType));
	EndDo;
	
	// Add the owners of the Files catalog.
	For Each OwnerType In FilesOwnersTypes Do
		OwnersMetadata.Add(Metadata.FindByType(OwnerType));
	EndDo;
	
	CheckModulesSourceCodeAccordingBySample("FilesOperationsImplementationDetails", OwnersMetadata);
	
	AttachedFilesCatalogs = TypeComposition(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Справочники, имена которых заканчиваются на ""%1""';
			|en = 'Catalogs whose names end on ""%1""';"), "AttachedFiles"), ObjectsWithFiles);
	AttachedFilesOwners = TypeComposition(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Предусмотренный справочник присоединенных файлов с реквизитом %1 указанного типа';
			|en = 'The provided attachment catalog with attribute %1 of the specified type';"), "FilesOwner"), OwnersMetadata);
	
	FormDefinitionHandlers = New Array;
	FormDefinitionHandlers.Add("FilesOperationsClientServer.DetermineAttachedFileForm");
	If Common.SubsystemExists("StandardSubsystems.MessageTemplates") Then
		FormDefinitionHandlers.Add("MessageTemplatesClientServer.DetermineAttachedFileForm");
	EndIf;
	
	ArrayOfSources = New Array;
	ArrayOfSources.Add(TypeComposition("DefinedTypes.AttachedFile.Type",,, StrConcat(ExcludedDirectories, ",")));
	ArrayOfSources.Add(TypeComposition("DefinedTypes.AttachedFileObject.Type",,, StrConcat(ExcludedDirectories, ",")));
	ArrayOfSources.Add(SubscriptionsByHandlerComposition(FormDefinitionHandlers));
	ArrayOfSources.Add(AttachedFilesCatalogs);
	CompareTypes(ArrayOfSources, NStr("ru = 'Справочник присоединенных файлов';
										|en = 'Attachment catalog';"));
	
	ArrayOfSources = New Array;
	ArrayOfSources.Add(TypeComposition("DefinedTypes.AttachedFilesOwnerObject.Type",, "EverythingExceptDocuments", "Catalog.MetadataObjectIDs"));
	ArrayOfSources.Add(SubscriptionsByHandlerComposition("FilesOperations.SetAttachedDocumentFilesDeletionMark", "Documents"));
	ObjectTypes = MergeTypes(ArrayOfSources);
	
	ArrayOfSources = New Array;
	ArrayOfSources.Add(TypeComposition("DefinedTypes.AttachedFilesOwner.Type",,, "Catalog.MetadataObjectIDs"));
	ArrayOfSources.Add(AttachedFilesOwners);
	ArrayOfSources.Add(ObjectTypes);
	CompareTypes(ArrayOfSources, NStr("ru = 'Объект-владелец присоединенных файлов';
										|en = 'Owner object of attachments';"));
	
EndProcedure

// Returns a table of attachment owners.
// 
// Returns:
//  ValueTable:
//   * AttachedFilesOwner - MetadataObject
//   * OwnerTypeOfAttachedFiles - Type
//
Function InformationAboutTheOwnersOfAttachedFiles()
	
	AttachedFilesOwners = New ValueTable;
	AttachedFilesOwners.Columns.Add("AttachedFilesOwner");
	AttachedFilesOwners.Columns.Add("OwnerTypeOfAttachedFiles");
	Return AttachedFilesOwners;
	
EndFunction

Procedure Attachable_SaaSOperations_CheckIntegration()
	
	CheckSeparatorsComposition();
	CheckStandardRolesComposition();
	
	// Shared data control.
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	CheckResult = ModuleSaaSOperations.ControlOfUnsharedDataWhenUpdating(False);
	
	ModuleSaaSTechnology = Common.CommonModule("CloudTechnology");
	CTLVersion = ModuleSaaSTechnology.LibraryVersion();
	If CommonClientServer.CompareVersions(CTLVersion, "2.0.10.1") >= 0 Then

		For Each MetadataObject In CheckResult.ThereIsNoUndividedDataInControllingSubscription Do
			AddError(MetadataObject, NStr("ru = 'Контроль неразделенных данных';
													|en = 'Shared data control';"),
				CheckResult.TextForExcludingUnsharedData, Undefined, True);
		EndDo;
		For Each MetadataObject In CheckResult.ObjectsWithMultipleSeparators Do
			AddError(MetadataObject, NStr("ru = 'Контроль неразделенных данных';
													|en = 'Shared data control';"),
				CheckResult.ExceptionTextWithMultipleDelimiters, Undefined, True);
		EndDo;

	Else
	
		If CheckResult <> Undefined Then
			For Each MetadataObject In CheckResult.MetadataObjects Do
				AddError(MetadataObject, NStr("ru = 'Контроль неразделенных данных';
														|en = 'Shared data control';"),
					CheckResult.ExceptionText, Undefined, True);
			EndDo;
		EndIf;

	EndIf;
	
	// Separated data control.
	ModuleSaaSOperationsCTL = Common.CommonModule("SaaSOperationsCTL");
	CheckResult = ModuleSaaSOperationsCTL.ControllingExclusionOfSharedObjectsInControllingSubscriptions(False);
	If CheckResult <> Undefined Then
		For Each MetadataObject In CheckResult.MetadataObjects Do
			AddError(MetadataObject, NStr("ru = 'Контроль разделенных данных';
													|en = 'Separated data control';"),
				CheckResult.ExceptionText, Undefined, True);
		EndDo;
	EndIf;
	
EndProcedure

Procedure Attachable_ReportMailing_CheckIntegration()
	
	If Not Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для выполнения рассылки отчетов выполните внедрение подсистемы ""%1"".';
				|en = 'To enable report distribution, integrate the ""%1"" subsystem.';"), "ContactInformation");
		BriefErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Отсутствует подсистема ""%1"".';
																							|en = '""%1"" subsystem is missing.';"), 
			"ContactInformation");
		AddError(Metadata.Catalogs["ReportMailings"], BriefErrorDetails, ErrorText);
		Return;
	EndIf;
	
	ModuleContactsManager = Common.CommonModule("ContactsManager");
	ContactInformationTypeGroups = New Map;
	
	QueryText =
	"SELECT DISTINCT
	|	ContactInformationKinds.Ref,
	|	CASE WHEN ContactInformationKinds.PredefinedKindName <> """"
	|	THEN ContactInformationKinds.PredefinedKindName
	|	ELSE ContactInformationKinds.PredefinedDataName
	|	END AS PredefinedKindName
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.IsFolder
	|	AND ContactInformationKinds.Parent = VALUE(Catalog.ContactInformationKinds.EmptyRef)";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ContactInformationTypeGroups.Insert(Selection.PredefinedKindName, Selection.Ref);
	EndDo;
	
	RecipientsTypes = TypeComposition("DefinedTypes.BulkEmailRecipient.Type",,, "Catalog.UserGroups");

	ContactInformationGroups = New Array;
	RecipientsTypesWithContactInformationGroups = New Map;
	For Each RecipientsType In RecipientsTypes[0].Content Do
		FullRecipientsTypeName = RecipientsType.FullName();
		ContactInformationGroupLink = ContactInformationTypeGroups.Get(StrReplace(FullRecipientsTypeName, ".", ""));
		If ContactInformationGroupLink = Undefined Then
			// Error: Contact information group is not defined.
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Для объекта не найдена группа контактной информации. Для него:
					|  • Либо выполните внедрение подсистемы ""%1"";
					|  • Либо исключите из определяемого типа ""%2"".';
					|en = 'No contact information group is found for the object. Do one of the following:
					|  • Integrate the %1 subsystem
					|  • Exclude the object from the %2 type collection.';"),
				"ContactInformation", "BulkEmailRecipient");
			AddError(RecipientsType, NStr("ru = 'Отсутствует группа контактной информации';
												|en = 'Contact information group is missing';"), ErrorText);
			Continue;
		EndIf;
		ContactInformationGroups.Add(ContactInformationGroupLink);
		RecipientsTypesWithContactInformationGroups.Insert(RecipientsType, ContactInformationGroupLink);
	EndDo;
	
	Query = New Query;
	Query.Text = "SELECT
	|	Parent AS ContactInformationGroup1
	|FROM
	|	Catalog.ContactInformationKinds
	|WHERE
	|	Parent IN (&ContactInformationGroups)
	|	AND Type = &Type
	|GROUP BY
	|	Parent";
	Query.SetParameter("ContactInformationGroups", ContactInformationGroups);
	ModuleContactsManager = Common.CommonModule("ContactsManager");
	Query.Parameters.Insert("Type", ModuleContactsManager.ContactInformationTypeByDescription("Email"));
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	For Each RecipientsType In RecipientsTypesWithContactInformationGroups Do
		Selection.Reset();
		SearchParameters = New Structure("ContactInformationGroup1", RecipientsType.Value); 
		If Not Selection.FindNext(SearchParameters) Then
			// Error: Main contact information kind (Email) is missing.
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Для получателей рассылки отчетов ""%1"" добавьте вид контактной информации типа ""Адрес электронной почты"", который будет являться источником адресов эл. почты.
					 |Если элемент с типом ""Адрес электронной почты"" присутствует в справочнике видов контактной информации в группе ""%1"", то проверьте заполнение в методе %2 общего модуля %3.';
					|en = 'For report recipients ""%1"", add a contact information kind of the ""Email address"" type. It will be a source of email addresses.
					|If group ""%1"" of the contact information kinds catalog already contains an item with the ""Email address"" type, check whether common module %3 in method %2 is filled in correctly.';"),
				String(RecipientsType.Key), "OverrideRecipientsTypesTable", "ReportMailingOverridable");
			AddError(RecipientsType.Key, NStr("ru = 'Отсутствует вид контактной информации';
													|en = 'Contact information kind is missing';"), ErrorText);
		EndIf;
	EndDo;
	
EndProcedure

Procedure Attachable_Properties_CheckIntegration()
	
	If Not Common.SubsystemExists("StandardSubsystems.Properties") Then
		Return;
	EndIf;
	
	// Check types of the AdditionalAttributes table.
	TablePartTypes = New Structure;
	TablePartTypes.Insert("Property",        New TypeDescription("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo"));
	TablePartTypes.Insert("TextString", New TypeDescription("String"));
	TablePartTypes.Insert("Value",        Metadata.ChartsOfCharacteristicTypes["AdditionalAttributesAndInfo"].Type.Types());

	ValidMetadata = New Array;
	ValidMetadata.Add(Metadata.Catalogs);
	ValidMetadata.Add(Metadata.Documents);
	ValidMetadata.Add(Metadata.BusinessProcesses);
	ValidMetadata.Add(Metadata.Tasks);
	ValidMetadata.Add(Metadata.ChartsOfCharacteristicTypes);
	
	ObjectsWithAdditionalDetails = New Array;
	ModulePropertyManager = Common.CommonModule("PropertyManager");
	
	For Each MetadataKind In ValidMetadata Do // MetadataObjectCollection
		
		For Each MetadataObject In MetadataKind Do
			
			If MetadataObject = Metadata.Catalogs["AdditionalAttributesAndInfoSets"] Then
				Continue; // An exception.
			EndIf;
			
			TablePartAdditionalDetails = MetadataObject.TabularSections.Find("AdditionalAttributes");
			If TablePartAdditionalDetails <> Undefined
				And Not StrStartsWith(MetadataObject.Name, "Delete") Then
				
				ObjectsWithAdditionalDetails.Add(MetadataObject);
				// Check type content.
				For Each TablePartType In TablePartTypes Do
					FoundAttribute = TablePartAdditionalDetails.Attributes.Find(TablePartType.Key);
					If FoundAttribute = Undefined Then
						ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'У объекта ""%1"" в табличной части ""%2"" отсутствует обязательный реквизит ""%3""';
								|en = 'Required attribute ""%3"" is missing for object ""%1"" in table ""%2"".';"), 
							MetadataObject.FullName(), "AdditionalAttributes", TablePartType.Key);
						AddError(MetadataObject,
							StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = 'Отсутствуют обязательные реквизиты табличной части %1';
									|en = 'Required attributes of the %1 table are missing';"),
								"AdditionalAttributes"),
							ErrorText);
					Else
						If FoundAttribute.Name = "Value" Then
							AddError = Not CommonClientServer.ValueListsAreEqual(
								FoundAttribute.Type.Types(), TablePartType.Value);
						Else
							AddError = FoundAttribute.Type <> TablePartType.Value;
						EndIf;
						If AddError Then
							ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = 'У объекта ""%1"" в табличной части ""%2"" тип реквизита ""%3"" не соответствует ожидаемому (%4)';
									|en = 'Attribute type ""%3"" of object ""%1"" in table ""%2"" does not match the expected type (%4).';"), 
								MetadataObject.FullName(), "AdditionalAttributes", TablePartType.Key,
								?(FoundAttribute.Name = "Value", "Metadata.ChartsOfCharacteristicTypes" + "AdditionalAttributesAndInfo.Type",
								TablePartType.Value));
							AddError(MetadataObject,
								StringFunctionsClientServer.SubstituteParametersToString(
									NStr("ru = 'Некорректные типы реквизитов табличной части %1';
										|en = 'Incorrect types of attributes of the %1 table';"),
									"AdditionalAttributes"),
								ErrorText);
						EndIf;
						
					EndIf;
				EndDo;
				
				// Check additional attribute characteristics.
				CharacteristicsAreSet = False;
				CharacteristicsAreSetCorrectly = False;
				SetDescribedInCode = Undefined;
				For Each Characteristic In MetadataObject.Characteristics Do // CharacteristicsDescription
					If Characteristic.CharacteristicTypes = Metadata.Catalogs["AdditionalAttributesAndInfoSets"].TabularSections.AdditionalAttributes Then
						If TypeOf(Characteristic.TypesFilterValue) = Type("String") Then
							SetDescribedInCode = ModulePropertyManager.PropertiesSetByName(Characteristic.TypesFilterValue);
						Else
							SetName = StrReplace(MetadataObject.FullName(), ".", "_");
							SetDescribedInCode = ModulePropertyManager.PropertiesSetByName(SetName);
						EndIf;
						CharacteristicsAreSet = True;
						If Characteristic.TypesFilterField <> Undefined
							And (Characteristic.TypesFilterField.Name = "PredefinedSetName" Or SetDescribedInCode = Undefined) Then
							CharacteristicsAreSetCorrectly = True;
						EndIf;
					EndIf;
				EndDo;
				If Not CharacteristicsAreSet Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У объекта ""%1"" с табличной частью ""%2""
						|отсутствует характеристика с видом ""%3""';
						|en = 'Characteristic with type ""%3""
						|is missing for object ""%1"" with table ""%2""';"),
						MetadataObject.FullName(), "AdditionalAttributes", "Catalog.AdditionalAttributesAndInfoSets.TabularSection.AdditionalAttributes");
					AddError(MetadataObject, NStr("ru = 'Некорректно заполнены характеристики';
															|en = 'Characteristics are filled in incorrectly';"), ErrorText);
				ElsIf Not CharacteristicsAreSetCorrectly And SetDescribedInCode <> Undefined Then
					// Property set is described in code.
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У объекта ""%1"" с табличной частью ""%2""
						|в дополнительных характеристиках объекта метаданных для вида характеристики ""%3"" значение колонки ""Поле отбора видов"" не равно ""%4""';
						|en = 'For object ""%1"" with table ""%2"",
						|the ""Type filter field"" column value is not equal to ""%4"" in the additional characteristics of the metadata object for characteristic type ""%3""';"),
						MetadataObject.FullName(), "AdditionalAttributes", "Catalog.AdditionalAttributesAndInfoSets.TabularSection.AdditionalAttributes", "PredefinedSetName");
					AddError(MetadataObject, NStr("ru = 'Некорректно заполнены поля отборов видов характеристики';
															|en = 'Fields of the characteristic type filters are filled in incorrectly';"), ErrorText);
				ElsIf Not CharacteristicsAreSetCorrectly And SetDescribedInCode = Undefined Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У объекта ""%1"" с табличной частью ""%2""
						|некорректно заполнена характеристика для вида ""%3"".
						|Правильные значения - ""Поле ключа"" = ""Свойство"", ""Поле отбора видов"" = ""Ссылка"", а в ""Значение отбора видов"" должен быть указан предопределенный элемент.';
						|en = 'For object ""%1"" with table ""%2"",
						|the characteristic for kind ""%3"" is filled in incorrectly.
						|The correct values are: ""Key field"" = ""Property"" and ""Type filter field"" = ""Reference"". A predefined item must be specified in ""Type filter value"".';"),
						MetadataObject.FullName(), "AdditionalAttributes", "Catalog.AdditionalAttributesAndInfoSets.TabularSection.AdditionalAttributes");
					AddError(MetadataObject, NStr("ru = 'Некорректно заполнены характеристики';
															|en = 'Characteristics are filled in incorrectly';"), ErrorText);
				EndIf;
			EndIf;
			
		EndDo;
	EndDo;
	
	// Check if code insertions are present.
	CheckedCalls = New Array;
	CheckedCalls.Add("PropertyManagerClient.ExecuteCommand(");
	CheckedCalls.Add("PropertyManager.OnCreateAtServer(");
	CheckedCalls.Add("PropertyManagerClient.ProcessNotifications(");
	CheckedCalls.Add("UpdateAdditionalAttributesItems()");
	CheckedCalls.Add("PropertyManager.UpdateAdditionalAttributesItems(");
	CheckedCalls.Add("PropertyManager.OnReadAtServer(");
	CheckedCalls.Add("PropertyManager.FillCheckProcessing(");
	CheckedCalls.Add("PropertyManager.BeforeWriteAtServer(");
	
	CheckParameters = CheckingCodeInsertionParameters();
	CheckParameters.DataToCheck1 = ObjectsWithAdditionalDetails;
	CheckParameters.ModuleType         = "DefaultObjectForm";
	CheckParameters.CodeString        = CheckedCalls;
	CheckForCodeInsertion(CheckParameters);
	
	// Check predefined items.
	
	ObjectsWithAdditionalProperties = New Array;
	
	AcceptablePrefixes = New Structure;
	AcceptablePrefixes.Insert("Catalog", Metadata.Catalogs);
	AcceptablePrefixes.Insert("Document", Metadata.Documents);
	AcceptablePrefixes.Insert("ChartOfCharacteristicTypes", Metadata.ChartsOfCharacteristicTypes);
	AcceptablePrefixes.Insert("ChartOfAccounts", Metadata.ChartsOfAccounts);
	AcceptablePrefixes.Insert("ChartOfCalculationTypes", Metadata.ChartsOfCalculationTypes);
	AcceptablePrefixes.Insert("BusinessProcess", Metadata.BusinessProcesses);
	AcceptablePrefixes.Insert("Task", Metadata.Tasks);
	AcceptablePrefixes.Insert("ExchangePlan", Metadata.ExchangePlans);
	
	SetsMetadata = Metadata.Catalogs["AdditionalAttributesAndInfoSets"];
	PredefinedItemsNames = SetsMetadata.GetPredefinedNames();
	For Each PredefinedItemName In PredefinedItemsNames Do
		FullPredefinedItemName = "Catalog.AdditionalAttributesAndInfoSets." + PredefinedItemName;
		Set = Common.PredefinedItem(FullPredefinedItemName);
		If ValueIsFilled(Set.Parent) Then
			Continue;
		EndIf;
		FillInPredefined(ObjectsWithAdditionalProperties, PredefinedItemName, AcceptablePrefixes);
	EndDo;
	
	ModuleManagementOfPropertiesOfRepeatIsp = Common.CommonModule("PropertyManagerCached");
	For Each PredefinedSet In ModuleManagementOfPropertiesOfRepeatIsp.PredefinedPropertiesSets() Do
		If TypeOf(PredefinedSet.Key) = Type("String") Then
			If PredefinedItemsNames.Find(PredefinedSet.Key) <> Undefined Then
				ErrorText = NStr("ru = 'Набор свойств ""%1"", описанный в процедуре %2
					|не отмечен префиксом ""Удалить"" в предопределенных элементах справочника %3.';
					|en = 'Property set ""%1"" described in procedure %2
					|is not marked with the Delete prefix in predefined items of catalog %3.';");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
					PredefinedSet.Key, "PropertyManagerOverridable.OnGetPredefinedPropertiesSets",
					"AdditionalAttributesAndInfoSets");
				
				Position = StrFind(PredefinedSet.Key, "_");
				FirstNamePart =  Left(PredefinedSet.Key, Position - 1);
				SecondNamePart = Right(PredefinedSet.Key, StrLen(PredefinedSet.Key) - Position);
				MetadataObject = Common.MetadataObjectByFullName(FirstNamePart + "." + SecondNamePart);
				AddError(MetadataObject, NStr("ru = 'Дублирование предопределенных наборов свойств';
														|en = 'Duplicating predefined property sets';"), ErrorText);
			EndIf;
			Continue;
		EndIf;
		SetProperties = PredefinedSet.Value;
		If ValueIsFilled(SetProperties.Parent) Then
			Continue;
		EndIf;
		PredefinedItemName = SetProperties.Name;
		FillInPredefined(ObjectsWithAdditionalProperties, PredefinedItemName, AcceptablePrefixes);
	EndDo;
	
	ObjectsWithAdditionalInformation = TypeComposition("DefinedTypes.DetailedInfoOwner.Type");
	// Check additional info characteristics.
	For Each MetadataObject In ObjectsWithAdditionalInformation[0].Content Do // MetadataObjectCatalog
		CharacteristicsAreSet = False;
		CharacteristicsAreSetCorrectly = False;
		SetDescribedInCode = Undefined;
		For Each Characteristic In MetadataObject.Characteristics Do // CharacteristicsDetails
			If Characteristic.CharacteristicTypes = Metadata.Catalogs["AdditionalAttributesAndInfoSets"].TabularSections.AdditionalInfo Then
				If TypeOf(Characteristic.TypesFilterValue) = Type("String") Then
					SetDescribedInCode = ModulePropertyManager.PropertiesSetByName(Characteristic.TypesFilterValue);
				Else
					SetName = StrReplace(MetadataObject.FullName(), ".", "_");
					SetDescribedInCode = ModulePropertyManager.PropertiesSetByName(SetName);
				EndIf;
				CharacteristicsAreSet = True;
				If Characteristic.TypesFilterField <> Undefined
					And (Characteristic.TypesFilterField.Name = "PredefinedSetName" Or SetDescribedInCode = Undefined) Then
					CharacteristicsAreSetCorrectly = True;
				EndIf;
			EndIf;
		EndDo;
		If Not CharacteristicsAreSet Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У объекта ""%1"", входящего в состав определяемого типа ""%2""
				|отсутствует характеристика с видом ""%3""';
				|en = 'Characteristic with the %3 kind is missing for the %1 object
				|included in the %2 type collection.';"),
				MetadataObject.FullName(), "DetailedInfoOwner", "Catalog.AdditionalAttributesAndInfoSets.TabularSection.AdditionalInfo");
			AddError(MetadataObject, NStr("ru = 'Некорректно заполнены характеристики';
													|en = 'Characteristics are filled in incorrectly';"), ErrorText);
		ElsIf Not CharacteristicsAreSetCorrectly And SetDescribedInCode <> Undefined Then
			// Property set is described in code.
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У объекта ""%1"", входящего в состав определяемого типа ""%2""
				|поле отбора видов характеристики вида ""%3"" не равно ""%4""';
				|en = 'For the %1 object included in the %2 type collection,
				|the type filter field of the %3characteristic type is not equal to ""%4"".';"),
				MetadataObject.FullName(), "DetailedInfoOwner", "Catalog.AdditionalAttributesAndInfoSets.TabularSection.AdditionalInfo", "PredefinedSetName");
			AddError(MetadataObject, NStr("ru = 'Некорректно заполнены поля отборов видов характеристики';
													|en = 'Fields of the characteristic type filters are filled in incorrectly';"), ErrorText);
		ElsIf Not CharacteristicsAreSetCorrectly And SetDescribedInCode = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У объекта ""%1"", входящего в состав определяемого типа ""%2""
				|некорректно заполнена характеристика для вида ""%3"".
				|Правильные значения - ""Поле ключа"" = ""Свойство"", ""Поле отбора видов"" = ""Ссылка"", а в ""Значение отбора видов"" должен быть указан предопределенный элемент.';
				|en = 'The %1 object included in the %2 type collection contains
				|invalid characteristic values for the %3 type.
				|The correct values are: ""Key field"" = ""Property"" and ""Type filter field"" = ""Reference"". A predefined item must be specified in ""Type filter value"".';"),
				MetadataObject.FullName(), "DetailedInfoOwner", "Catalog.AdditionalAttributesAndInfoSets.TabularSection.AdditionalInfo");
			AddError(MetadataObject, NStr("ru = 'Некорректно заполнены характеристики';
													|en = 'Characteristics are filled in incorrectly';"), ErrorText);
		EndIf;
	EndDo;
	
	ObjectsWithDetailsAndInformation = New Array;
	ObjectsWithDetailsAndInformation.Add(TypeComposition(NStr("ru = 'Объекты с дополнительными реквизитами';
															|en = 'Objects with additional attributes';"), ObjectsWithAdditionalDetails));
	ObjectsWithDetailsAndInformation.Add(ObjectsWithAdditionalInformation);
	ObjectsWithDetailsAndInformation = MergeTypes(ObjectsWithDetailsAndInformation);
	
	ArrayOfSources = New Array;
	ArrayOfSources.Add(ObjectsWithDetailsAndInformation);
	ArrayOfSources.Add(TypeComposition(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Предопределенные элементы справочника %1';
				|en = 'Predefined items of catalog %1';"), "AdditionalAttributesAndInfoSets"),
		ObjectsWithAdditionalProperties));
	CompareTypes(ArrayOfSources,, True);
	
EndProcedure

Procedure Attachable_SubordinationStructure_CheckIntegration()
	
	// If a type is included in the filter criteria, it must be also included in the report command type.
	// If a type is included in a report command type and not included in the filter criteria,
	// do not show warnings (assume that it is one of the listed types).
	If Not Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		CommandComposition = TypeCompositionFromString("CommonCommands.RelatedDocuments.CommandParameterType");
		CriterionComposition = TypeCompositionFromString("FilterCriteria.RelatedDocuments.Type");
		For Each CriterionType In CriterionComposition Do
			If CommandComposition.Find(CriterionType) = Undefined Then
				DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Тип %1 входит в тип критерия отбора %2, но не входит в тип команды %2';
						|en = 'Type %1 is included in filter criteria type %2 but is not included in command type %2';"),
					MetadataObjectTypeView(CriterionType), "RelatedDocuments");
				AddError(CriterionType, NStr("ru = 'Различается состав типов';
												|en = 'Composition of types differs';"), DetailedErrorDetails);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure Attachable_AccessManagement_CheckIntegration()
	
	If VerificationIsRequired() Then
		AccessRestrictions = AccessRestrictionsFromUploadingConfigurationToFiles();
		CheckAccessRestrictionsUse(AccessRestrictions);
	EndIf;
	
	ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
	AccessRestrictionErrors = ModuleAccessManagementInternal.AccessRestrictionErrors();
	For Each Error In AccessRestrictionErrors Do
		AddError(Common.MetadataObjectByFullName(Error.FullName),
			NStr("ru = 'Не выполнена проверка внедрения подсистемы Управление доступом';
				|en = 'Access management subsystem integration is not checked';"),
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось выполнить проверку или обновление внедрения
				           |всех объектов метаданных из-за останавливающей ошибки:
				           |
				           |%1';
							|en = 'Cannot check or update integration
							|of all metadata objects due to stopping error:
							|
							|%1';"),
			Error.ErrorText), , True);
	EndDo;
	
	Parameters = AccessControlImplementationVerificationParameters();
	Parameters.UpdateOnlyConstraintTemplates = AccessRestrictionErrors.Count() > 0;
	AccessControl_AtReadingBasicSettings(Parameters);
	
	If Not Parameters.UpdateOnlyConstraintTemplates And VerificationIsRequired() Then
		CheckNewRLSInRolesUse(AccessRestrictions, Parameters.AccessManagement.RestrictedAccessLists);
	EndIf;
	
	If VerificationIsRequired("InvalidConstraintTextForTableInRole,TemplateUsedInRoleIsMissingOrDifferent,NotUsedInRoleTemplate") Then
		For Each Role In Metadata.Roles Do
			CheckRoleTextInsertion(Parameters, Role);
		EndDo;
	EndIf;
	
	If Parameters.UpdateOnlyConstraintTemplates Then
		Return;
	EndIf;
	
	If VerificationIsRequired("TypeNotIncludedInDefinedType") Then
		UpdateAccessKeyValuesOwnersList(Parameters);
	EndIf;
	
	If VerificationIsRequired("IncorrectPredefinedElementsCompositionInMetadataObjectIdentifiersDirectory") Then
		For Each PredefinedIDs In Parameters.AccessManagement.PredefinedIDs Do
			UpdatePredefinedDirectoryItemsList(PredefinedIDs.Key, PredefinedIDs.Value);
		EndDo;
	EndIf;
	
	If VerificationIsRequired("InvalidRegisterFieldTypesComposition") Then
		CheckRegistersKeysMeasurementsTypes(Parameters);
	EndIf;
	
EndProcedure

Procedure Attachable_SourceDocumentsOriginalsRecording_CheckIntegration()

	If Common.SubsystemExists("StandardSubsystems.SourceDocumentsOriginalsRecording") Then
		ModuleSourceDocumentsOriginalsAccounting = Common.CommonModule("SourceDocumentsOriginalsRecording");
		For Each Type In ModuleSourceDocumentsOriginalsAccounting.InformationAboutConnectedObjects() Do
			If Type = Type("String") Then
			AddError("DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting",NStr("ru = 'Не описан состав определяемого типа подсистемы';
																								|en = 'Composition of the subsystem''s type collection is not described.';"),
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Документы, являющиеся поставщиками оригиналов первичных документов, следует указать в составе определяемого типа %1';
						|en = 'Specify documents that provide source document originals in the %1 type collection.';"),
					"ObjectWithSourceDocumentsOriginalsAccounting"));			
			Return;	
			EndIf;	
		EndDo;
	Else
		Return;
	EndIf;

	// Check if the PerformerRoles catalog has the EmployeeResponsibleForTasksManagement predefined item.
	CheckForPredefinedElement("Catalogs.SourceDocumentsOriginalsStates", "FormPrinted");
	CheckForPredefinedElement("Catalogs.SourceDocumentsOriginalsStates", "OriginalReceived");
	CheckForPredefinedElement("Catalogs.SourceDocumentsOriginalsStates", "OriginalsNotAll");
	
	AccountingObjectsComposition = 
		TypeComposition("DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type",,,"Catalog.MetadataObjectIDs");
	
	// Check if procedures and code block insertions are present in document form modules.
	CheckParameters = CheckingCodeInsertionParameters();
	CheckParameters.DataToCheck1 = AccountingObjectsComposition;
	CheckParameters.ModuleType         = "DefaultObjectForm";
	CheckParameters.CodeString        = "SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm";
	CheckForCodeInsertion(CheckParameters);

	CheckParameters.NameOfAProcedureOrAFunction = "Procedure NotificationProcessing";
	CheckParameters.CodeString             = "SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm";
	CheckForCodeInsertion(CheckParameters);

	CheckParameters.NameOfAProcedureOrAFunction = "Procedure Attachable_OriginalStateDecorationClick";
	CheckParameters.CodeString             = "SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu";
	CheckForCodeInsertion(CheckParameters);

	// Check if procedures for inserting code blocks are present in list form modules.
	CheckParameters = CheckingCodeInsertionParameters();
	CheckParameters.DataToCheck1 = AccountingObjectsComposition;
	CheckParameters.ModuleType              = "DefaultListForm";
	CheckParameters.NameOfAProcedureOrAFunction = "Procedure OnCreateAtServer";
	CheckParameters.CodeString             = "SourceDocumentsOriginalsRecording.OnCreateAtServerListForm";
	CheckForCodeInsertion(CheckParameters);

	CheckParameters.NameOfAProcedureOrAFunction = "Procedure NotificationProcessing";
	CheckParameters.CodeString             = "SourceDocumentsOriginalsRecordingClient.NotificationHandlerListForm";
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.NameOfAProcedureOrAFunction = "Procedure ListSelection";
	CheckParameters.CodeString             = "SourceDocumentsOriginalsRecordingClient.ListSelection";
	CheckForCodeInsertion(CheckParameters);

	CheckParameters = CheckingCodeInsertionParameters();
	CheckParameters.DataToCheck1 = AccountingObjectsComposition;
	CheckParameters.ModuleType              = "DefaultListForm";
	CheckParameters.NameOfAProcedureOrAFunction = "Procedure Attachable_UpdateOriginalStateCommands";
	CheckParameters.CodeString             = "UpdateOriginalStateCommands";
	CheckForCodeInsertion(CheckParameters);

	CheckParameters = CheckingCodeInsertionParameters();
	CheckParameters.DataToCheck1 = AccountingObjectsComposition;
	CheckParameters.ModuleType         = "DefaultListForm";
	CheckParameters.CodeString        = "SourceDocumentsOriginalsRecording.OnCreateAtServerListForm";
	CheckForCodeInsertion(CheckParameters);
	
	If Not Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		CheckParameters = CheckingCodeInsertionParameters();
		CheckParameters.DataToCheck1 = AccountingObjectsComposition;
		CheckParameters.ModuleType         = "DefaultListForm";
		CheckParameters.NameOfAProcedureOrAFunction        = "Procedure Attachable_SetOriginalState";
		CheckParameters.CodeString        = "SourceDocumentsOriginalsRecordingClient.SetOriginalState";
		CheckForCodeInsertion(CheckParameters);
	EndIf;

EndProcedure

Procedure Attachable_MessageTemplates_CheckIntegration()
	
	// Receive content of the objects attached to the Message templates subsystem in the MessageTemplateSubject type collection.
	
	MetadataArray = New Array;
	For Each Item In Metadata.DefinedTypes["MessageTemplateSubject"].Type.Types() Do
		If Item <> Type("CatalogRef.MetadataObjectIDs") Then
			MetadataArray.Add(Metadata.FindByType(Item));
		EndIf;
	EndDo;
	
	// Check if modules contain calls.
	CheckParameters = CheckingCodeInsertionParameters();
	CheckParameters.DataToCheck1 = MetadataArray;
	CheckParameters.ModuleType         = "ManagerModule";
	
	CheckParameters.CodeString = "Procedure OnPrepareMessageTemplate";
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.CodeString = "Procedure OnCreateMessage";
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.CodeString = "Procedure OnFillRecipientsPhonesInMessage";
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.CodeString = "Procedure OnFillRecipientsEmailsInMessage";
	CheckForCodeInsertion(CheckParameters);
	
EndProcedure

Procedure Attachable_DigitalSignature_CheckIntegration()
	
	SignedObjects = New Array;
	CheckedMetadataTypes = New Array;
	CheckedMetadataTypes.Add(Metadata.Catalogs);
	CheckedMetadataTypes.Add(Metadata.Documents);
	CheckedMetadataTypes.Add(Metadata.ChartsOfCharacteristicTypes);
	CheckedMetadataTypes.Add(Metadata.BusinessProcesses);
	CheckedMetadataTypes.Add(Metadata.Tasks);
	
	FilesCatalogs = New Array;
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		FilesCatalogs = TypeComposition("DefinedTypes.AttachedFile.Type")[0].Content;
		FilesCatalogs.Delete(FilesCatalogs.Find(CalculationResult("Metadata.Catalogs.FilesVersions")));
	EndIf;
	
	For Each MetadataKind In CheckedMetadataTypes Do
		For Each ObjectToCheck In MetadataKind Do
			If ObjectToCheck.Attributes.Find("SignedWithDS") = Undefined Then
				Continue;
			EndIf;
			SignedObjects.Add(ObjectToCheck);
		EndDo;
	EndDo;
	
	TypesOfSignedObject = TypeComposition("DefinedTypes.SignedObject.Type");
	SignedObjectsType = TypeComposition(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Объекты метаданных, содержащие реквизит %1';
			|en = 'Metadata objects that contain attribute %1';"), "SignedWithDS"),
		SignedObjects);
	
	// Exclude file catalogs as they cannot be signed, however, they must contain attribute SignedWithDS.
	For Each FilesCatalog In FilesCatalogs Do
	
		For Each TypeRow In TypesOfSignedObject Do
			IndexOf = TypeRow.Content.Find(FilesCatalog);
			If IndexOf <> Undefined Then
				TypeRow.Content.Delete(IndexOf);
			EndIf;
		EndDo;
		
		For Each TypeRow In SignedObjectsType Do
			IndexOf = TypeRow.Content.Find(FilesCatalog);
			If IndexOf <> Undefined Then
				TypeRow.Content.Delete(IndexOf);
			EndIf;
		EndDo;

	EndDo;
	
	ComparedTypes = New Array;
	ComparedTypes.Add(SignedObjectsType);
	ComparedTypes.Add(TypesOfSignedObject);
	CompareTypes(ComparedTypes, NStr("ru = 'Объект с электронной подписью';
										|en = 'Object with digital signature';"));
	
EndProcedure

#EndRegion

#Region ProceduresForUseInInspections

// Logs an error in the check results.
// 
// Parameters:
//    MetadataObject - MetadataObject - Error location.
//    BriefErrorDetails - String - Brief check details.
//    DetailedErrorDetails - String - Detailed error description.
//
Procedure AddError(Val MetadataObject, BriefErrorDetails, DetailedErrorDetails,
	LibrarySubsystem = Undefined, Critical = False)
	
	If LibrarySubsystem = Undefined Then
		LibrarySubsystem = CheckedSubsystem;
	EndIf;
	If MetadataObject = Undefined Then
		MetadataObject = LibrarySubsystem;
	EndIf;
	
	If TypeOf(MetadataObject) = Type("MetadataObject") Then
		If StrFind(MetadataObject.FullName(), ".Form.") > 0 Then
			MetadataObject = MetadataObject.Parent();
		EndIf;
		
		If Not Critical And StrStartsWith(MetadataObject.Name, "Delete") Then
			Return;
		EndIf;
	EndIf;
	
	If IsException(LibrarySubsystem, MetadataObject, BriefErrorDetails, DetailedErrorDetails) Then
		Return;
	EndIf;
	
	ObjectPresentation = MetadataObjectTypeView(MetadataObject);
	ObjectSubsystems = MatchingObjects.Get(ObjectPresentation);
	TopLevelSubsystem = ?(ObjectSubsystems = Undefined, NStr("ru = 'Без подсистемы';
																		|en = 'Without subsystem';"), ObjectSubsystems[0].Presentation);
	TopLevelSubsystemName = ?(ObjectSubsystems = Undefined, "", ObjectSubsystems[0].Name);
	
	NewRow = CheckTable.Add();
	
	NewRow.SSLSubsystem = ?(LibrarySubsystem = Undefined, "", LibrarySubsystem.Presentation());
	NewRow.ConfigurationSubsystem = TopLevelSubsystem;
	NewRow.SubsystemConfigurationName = TopLevelSubsystemName;
	NewRow.MetadataObject = ObjectPresentation;
	If TypeOf(DetailedErrorDetails) = Type("ErrorInfo") Then
		NewRow.BriefErrorDetails = BriefErrorDetails + Chars.LF + ErrorProcessing.BriefErrorDescription(DetailedErrorDetails);
		NewRow.DetailedErrorDetails = ErrorProcessing.DetailErrorDescription(DetailedErrorDetails);
	Else
		NewRow.BriefErrorDetails = BriefErrorDetails;
		NewRow.DetailedErrorDetails = DetailedErrorDetails;
	EndIf;
	
EndProcedure

// Generates list of types included in the collection to later use in comparison procedures.
//
// Parameters:
//    LongDesc        - String - Collection description in terms of metadata objects. For example, "DefinedTypes.VersionedData.Type".
//                               If the "Content" parameter value is set, it is populated with the string type description.
//    Content          - Array of MetadataObject - Populated if a string description is passed as the first parameter. 
//                               Contains an array of metadata objects included in the collection.
//    AllowedTypes  - String - Contains details of lists supported by the collection. 
//                               Valid value is comma-delimited basic type names, such as "Documents,Catalogs". 
//                               Another valid value is "AllExceptDocuments", which makes supported all objects but documents. 
//                               
//    TypesToExclude - String - Full names of metadata objects to exclude from the collection.
//                               For example, to get from a type collection all content except for object IDs, set the value to:
//                               "Catalog.MetadataObjectIDs".
// Returns:
//   See TypesTable.
//
Function TypeComposition(Val LongDesc, Content = Undefined, AllowedTypes = "", TypesToExclude = "")
	
	If Content = Undefined Then
		Content = TypeCompositionFromString(LongDesc);
	EndIf;
	
	ExcludeTypes(TypesToExclude, Content);
	Return NewTypeTableRow(LongDesc, AllowedTypes, Content);
	
EndFunction

// Gets a list of subscription types by handler.
//
// Parameters:
//    Handler - String - Subscription handler being searched at.
//    AllowedTypes - String - See parameter details in the TypeComposition function.
//    TypesToExclude - String - See parameter details in the TypeComposition function.
//
// Returns:
//   See TypesTable.
//
Function SubscriptionsByHandlerComposition(Handler, AllowedTypes = "", TypesToExclude = "")
	
	Content = New Array;
	SubscriptionsNumber = 0;
	MultipleHandlers = TypeOf(Handler) = Type("Array");
	
	For Each Subscription In Metadata.EventSubscriptions Do
		If (Not MultipleHandlers And Subscription.Handler = Handler)
			Or (MultipleHandlers And Handler.Find(Subscription.Handler) <> Undefined) Then
			CurSubscription = Subscription;
			SubscriptionsNumber = SubscriptionsNumber + 1;
			For Each Type In Subscription.Source.Types() Do
				Content.Add(Metadata.FindByType(Type));
			EndDo;
		EndIf;
	EndDo;
	
	If SubscriptionsNumber = 1 Then
		LongDesc = CurSubscription.FullName();
	Else
		HandlerName = ?(MultipleHandlers, StrSplit(Handler[0], ".")[1], Handler);
		LongDesc = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Подписки с обработчиком %1';
																				|en = 'Subscriptions with handler %1';"), HandlerName);
	EndIf;
	
	ExcludeTypes(TypesToExclude, Content);
	
	Return NewTypeTableRow(LongDesc, AllowedTypes, Content);
	
EndFunction

// Merges several type sources.
//
// Parameters:
//    TypesArray - See details in the CompareTypes procedure.
//
// Returns:
//   See TypesTable.
//
Function MergeTypes(ArrayOfSources)
	
	TypesTable = TypesTable();
	
	For Each TypeRow In ArrayOfSources Do
		For Each TypesTableRow In TypeRow Do
			NewRow = TypesTable.Add();
			FillPropertyValues(NewRow, TypesTableRow);
		EndDo;
	EndDo;
	
	Return TypesTable;
	
EndFunction

// Compares the specified type sources—all source types are expected to match.
// If a mismatch is found, logs an error that notifies which sources contain this type and which don't.
// 
//
// Parameters:
//    ArrayOfSources - Array of See TypeComposition
//
Procedure CompareTypes(ArrayOfSources, Val TypeDetails = "", Val SkipDeleted = False)
	
	ProcessedTypes = New Map;
	
	For Each TypesTable In ArrayOfSources Do
		For Each TypeRow In TypesTable Do
			For Each Type In TypeRow.Content Do
				
				If Type = Undefined Then
					TypeName = TypeRow.LongDesc;
					If StrEndsWith(TypeName, ".Type") Then
						TypeName = Left(TypeName, StrLen(TypeName) - 4);
					EndIf;
					Try
						TypeMetadata = CalculationResult("Metadata." + TypeName);
					Except
						TypeMetadata = Undefined;
					EndTry;
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'В состав %1 включено значение Неопределено.';
							|en = 'Undefined value is included in the composition %1.';"), TypeRow.LongDesc);
					AddError(TypeMetadata, NStr("ru = 'Значение Неопределено в составе типа';
														|en = 'Undefined value in the type composition';"), ErrorText);
					Continue;
				EndIf;
				
				If SkipDeleted And StrStartsWith(Type.Name, "Delete") Then
					Continue;
				EndIf;
				
				If ProcessedTypes.Get(Type) = True Then
					Continue;
				EndIf;
				
				Absent = New Array;
				FoundItems = CommonClientServer.ValueInArray(TypeRow.LongDesc);
				For Each TypeTableInternal In ArrayOfSources Do
					If TypeTableInternal = TypesTable Then
						Continue;
					EndIf;
					
					For Each TypeStringInternal In TypeTableInternal Do
						If Not CompareTypesPossible(Type, TypeStringInternal.AllowedTypes) Then
							Continue;
						EndIf;
						
						If TypeStringInternal.Content.Find(Type) = Undefined Then
							Absent.Add(TypeStringInternal.LongDesc)
						Else
							FoundItems.Add(TypeStringInternal.LongDesc);
						EndIf;
					EndDo;
				EndDo;
				
				If Absent.Count() <> 0 Then
					ErrorTemplate = NStr("ru = '%1 указан не во всех предусмотренных местах конфигурации.
						|Следует указать его во всех перечисленных местах или не указывать нигде.
						|%2
						|
						|%1 отсутствует в составе:
						|%3,
						|
						|но присутствует в составе:
						|%4';
						|en = '%1 is specified not in all provided configuration places.
						|Specify it in all listed places or nowhere.
						|%2
						|
						|%1 is missing in
						|%3
						|
						| but is included in
						|%4.';");
					
					If CheckedSubsystem <> Undefined Then
						ImplementationDocumentation = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Подробнее см. документацию по внедрению подсистемы ""%1"" 1С:Библиотеки стандартных подсистем: https://its.1c.eu/db/bspdoc';
								|en = 'For more information, see <link https://kb.1ci.com/1C_Standard_Subsystems_Library/Guides/>documentation</> on integrating the %1 subsystem of 1C:Standard Subsystems Library.';"), 
							CheckedSubsystem.Synonym);
					Else
						ImplementationDocumentation = NStr("ru = 'Подробнее см. документацию по внедрению 1С:Библиотеки стандартных подсистем: https://its.1c.eu/db/bspdoc';
													|en = 'For more information, see <link https://kb.1ci.com/1C_Standard_Subsystems_Library/Guides/>documentation</> on integrating 1C:Standard Subsystems Library.';");
					EndIf;
					
					If Type = Type("String") Then
						FullTypeName = NStr("ru = 'Строка';
											|en = 'String';");
					Else
						FullTypeName = Type.FullName();
					EndIf;
					
					
					If IsBlankString(TypeDetails) Then
						TypeBeingCheckedDescription = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Тип %1';
								|en = 'Type %1';"), FullTypeName);
					Else
						TypeBeingCheckedDescription = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = '%1 %2';
								|en = '%1 %2';"), TypeDetails, FullTypeName);
					EndIf;	
					
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, TypeBeingCheckedDescription,
						ImplementationDocumentation, BulletedList(Absent), BulletedList(FoundItems));
					AddError(Type, NStr("ru = 'Различается состав типов';
											|en = 'Composition of types differs';"), ErrorText);
				EndIf;
				
				ProcessedTypes.Insert(Type, True);
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

// Compares type sources and searches for duplicates.
// If a type duplicate is found, it throws an error with the sources that contain the type.
// 
//
// Parameters:
//    ArrayOfSources - Array of ValueTable - See detains in the TypeComposition function.
//
Procedure TypesIntersection(ArrayOfSources)
	
	ProcessedTypes = New Map;
	
	For Each TypesTable In ArrayOfSources Do
		For Each TypeRow In TypesTable Do
			For Each Type In TypeRow.Content Do
				If ProcessedTypes.Get(Type) = True Then
					Continue;
				EndIf;
				
				HasError = False;
				FoundItems = CommonClientServer.ValueInArray(TypeRow.LongDesc);
				
				For Each TypeTableInternal In ArrayOfSources Do
					If TypeTableInternal = TypesTable Then
						Continue;
					EndIf;
					
					For Each TypeStringInternal In TypeTableInternal Do
						If Not CompareTypesPossible(Type, TypeStringInternal.AllowedTypes) Then
							Continue;
						EndIf;
						
						If TypeStringInternal.Content.Find(Type) <> Undefined Then
							FoundItems.Add(TypeStringInternal.LongDesc);
							HasError = True;
						EndIf;
					EndDo;
				EndDo;
				
				If HasError Then
					ErrorTemplate = NStr("ru = '%1 включите только в один источник. Сейчас он присутствует в
						|%2';
						|en = 'Include %1 only in one source. Now it is present in
						|%2';");
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, Type.FullName(),
						BulletedList(FoundItems));
					AddError(Type, NStr("ru = 'Пересекается состав типов';
											|en = 'Composition of types overlaps';"), ErrorText);
				EndIf;
				ProcessedTypes.Insert(Type, True);
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

// Checks metadata objects for predefined items.
//
// Parameters:
//    FullMetadataObjectName - String - Metadata object full name as a string.
//    PredefinedDataName - String - Name of the predefined item to check.
//
Procedure CheckForPredefinedElement(FullMetadataObjectName, PredefinedDataName)
	
	ObjectMetadata = CalculationResult("Metadata." + FullMetadataObjectName);
	PredefinedArray = ObjectMetadata.GetPredefinedNames();
	
	If PredefinedArray.Find(PredefinedDataName) = Undefined Then
		ErrorTemplate = NStr("ru = 'В ""%1"" отсутствует предопределенный элемент ""%2""';
							|en = 'The ""%2"" predefined item is missing in ""%1""';");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, FullMetadataObjectName, PredefinedDataName);
		AddError(ObjectMetadata, NStr("ru = 'Отсутствует предопределенный элемент';
												|en = 'Predefined item is missing';"), ErrorText);
	EndIf;
	
EndProcedure

// Returns a structure to pass to the CheckCodeInsert procedure.
// 
// Returns:
//   Structure:
//      * DataToCheck1 - MetadataObject - Metadata object to check the code insertion.
//                          - String - Full name of a metadata object.
//                          - Array of MetadataObject - metadata objects.
//                          - See TypesTable.
//      * ModuleType         - String - Type of the module to check. For valid values, see procedure ModuleText.
//      * CodeString        - String - String of code whose call should be checked.
//
//      * NameOfAProcedureOrAFunction              - String - Name of the procedure or function to insert code to.
//                                                       
//      * AbsenceOfModuleIsError     - Boolean - If True, when the module is missing, logs an error.
//                                                       By default, True.
//      * AbsenceOfProcedureIsError  - Boolean - If True, when the procedure or function specified in nProcedureOrFunctionName is missing, logs an error.
//                                                       By default, True.
//                                                       
//      * ProcedurePresenceIsError - Boolean - If True, when the procedure or function specified in nProcedureOrFunctionName is present, logs an error.
//                                                       By default, False.
//                                                       
//      * IsOptionalAlgorithm             - Boolean - Flag indicating whether it is necessary to declare a procedure or a function in the algorithm declaration procedure.
//                                                       By default, False.
//                                                       
//      * IsExportProcedure              - Boolean - If True, export the procedure or function specified in ProcedureOrFunctionName.
//                                                       By default, False.
//                                                       
//
Function CheckingCodeInsertionParameters()
	
	CheckParameters = New Structure;
	CheckParameters.Insert("DataToCheck1");
	CheckParameters.Insert("ModuleType");
	CheckParameters.Insert("CodeString");
	
	CheckParameters.Insert("NameOfAProcedureOrAFunction",              "");
	CheckParameters.Insert("AbsenceOfModuleIsError",     True);
	CheckParameters.Insert("AbsenceOfProcedureIsError",  True);
	CheckParameters.Insert("ProcedurePresenceIsError", False);
	CheckParameters.Insert("IsOptionalAlgorithm",             False);
	CheckParameters.Insert("IsExportProcedure",              False);
	
	Return CheckParameters;
	
EndFunction

// Checks for code insertions. If a required code insertion is missing, logs an error.
//
// Parameters:
//    VerificationParametersIncoming - See CheckingCodeInsertionParameters.
//
Procedure CheckForCodeInsertion(VerificationParametersIncoming)
	
	DataToCheck1 = VerificationParametersIncoming.DataToCheck1;
	ObjectType = TypeOf(DataToCheck1);
	
	VerificationParametersOutgoing = CheckingCodeInsertionParameters();
	FillPropertyValues(VerificationParametersOutgoing, VerificationParametersIncoming);
	
	If ObjectType = Type("MetadataObject") Then
		CheckForCodeInsertionForObject(VerificationParametersOutgoing);
	ElsIf ObjectType = Type("ValueTable") Then
		For Each TypeRow In DataToCheck1 Do
			VerificationParametersOutgoing.DataToCheck1 = TypeRow.Content;
			CheckForCodeInsertionForArray(VerificationParametersOutgoing);
		EndDo;
	ElsIf ObjectType = Type("String") Then
		VerificationParametersOutgoing.DataToCheck1 = TypeCompositionFromString(DataToCheck1);
		CheckForCodeInsertionForArray(VerificationParametersOutgoing);
	ElsIf ObjectType = Type("Array") Then
		CheckForCodeInsertionForArray(VerificationParametersOutgoing);
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неожиданный тип параметра %1 в процедуре ""%2""';
				|en = 'Unexpected type of parameter %1 in procedure ""%2""';"),
			"DataToCheck1", "CheckForCodeInsertion");
	EndIf;
	
EndProcedure

// Returns module text.
//
// Parameters:
//  MetadataObject - MetadataObject - Object that receives a module.
//  ModuleType - String - Valid values:
//     DefaultObjectForm, DefaultListForm, ManagerModule, ObjectModule,
//     CommandModule, RecordSetModule, Module, CommonFormModule, Name of a form or command to receive.
//  IsCommand - Boolean - Pass True if you need to get the text of a command module.
//
// Returns:
//    String
//
Function ModuleText(MetadataObject, Val ModuleType, IsCommand = False)
	
	If StrFind(MetadataObject.FullName(), ".Form.") > 0 Then
		ModuleFileName = FormModuleFilePath(MetadataObject);
	Else
		
		BaseTypeName = StrSplit(MetadataObject.FullName(), ".")[0];
		BaseTypeName = ObjectInFileUploadKindName[BaseTypeName];
		ObjectName = MetadataObject.Name;
		
		Parameters = New Structure;
		Parameters.Insert("DumpDirectory", DumpDirectory);
		Parameters.Insert("BaseTypeName", BaseTypeName);
		Parameters.Insert("ObjectName", ObjectName);
		
		If ModuleType = "DefaultObjectForm" Or ModuleType = "DefaultListForm" Then
			
			If ModuleType = "DefaultObjectForm" Then
				If Metadata.DocumentJournals.Contains(MetadataObject)
					Or Metadata.DataProcessors.Contains(MetadataObject) Then
					Form = MetadataObject.DefaultForm;
				ElsIf Metadata.InformationRegisters.Contains(MetadataObject) Then
					Form = MetadataObject.DefaultRecordForm;
				ElsIf Metadata.AccumulationRegisters.Contains(MetadataObject)
					Or Metadata.AccountingRegisters.Contains(MetadataObject) 
					Or Metadata.CalculationRegisters.Contains(MetadataObject) Then
					Form = Undefined;
				Else
					Form = MetadataObject.DefaultObjectForm;
				EndIf;
			ElsIf ModuleType = "DefaultListForm" Then
				If Metadata.DocumentJournals.Contains(MetadataObject)
					Or Metadata.DataProcessors.Contains(MetadataObject) Then
					Form = MetadataObject.DefaultForm;
				Else
					Form = MetadataObject.DefaultListForm;
				EndIf;
			EndIf;
			If Form = Undefined Then
				Return "";
			Else
				FormName = Form.Name;
			EndIf;
			Parameters.Insert("FormName", FormName);
			NameTemplate = ObjectFormModuleFilePathTemplate();
		ElsIf ModuleType = "ManagerModule" Or ModuleType = "ObjectModule" Or ModuleType = "CommandModule"
			Or ModuleType = "RecordSetModule" Or ModuleType = "Module" Then
			TemplateName = "";
			If TermsMap.Property(ModuleType, TemplateName) Then
				ModuleType = TemplateName;
			EndIf;
			Parameters.Insert("ModuleType", ModuleType);
			NameTemplate = ObjectModuleFilePathTemplate();
		ElsIf ModuleType = "CommonFormModule" Then
			NameTemplate = CommonFormModuleFilePathTemplate();
		ElsIf IsCommand Then
			Parameters.Insert("CommandName", ModuleType);
			NameTemplate = CommandModuleFilePathTemplate();
		Else
			Parameters.Insert("FormName", ModuleType);
			NameTemplate = ObjectFormModuleFilePathTemplate();
		EndIf;
		
		ModuleFileName = StringFunctionsClientServer.InsertParametersIntoString(NameTemplate, Parameters);
	EndIf;
	
	ModuleFile = New File(ModuleFileName);
	If Not ModuleFile.Exists() Then
		Return "";
	EndIf;
	
	ModuleText = New TextReader(ModuleFileName, TextEncoding.UTF8);
	Return ModuleText.Read();
	
EndFunction

// Returns the procedure text by procedure name.
//
// Parameters:
//    ProcedureName - String - Name of the procedure whose text should be received.
//    ModuleText - String - Module's full text.
//
// Returns:
//    String
//
Function ProcedureText(ProcedureName, ModuleText)
	
	Return ProcedureOrFunctionText(ProcedureName, ModuleText, False);
	
EndFunction

// If the code insertion check supports several valid insertion values, (for example, a new and obsolete option),
// pass these options to the function.
// Then, pass the return value to parameter CodeString of procedure CheckCodeInsert.
//
// Parameters:
//    Variant1 - String - First call option.
//    Variant2 - String - Second call option.
//
// Returns:
//    Array - Procedure call options.
//
Function CallOptions(Variant1, Variant2)
	
	CallOptions = New Array;
	CallOptions.Add(Variant1);
	CallOptions.Add(Variant2);
	Return CallOptions;
	
EndFunction

// Parameters:
//   Form - MetadataObject - Object form.
//
Function MainFormPropertyType(Form)
	
	PathToFile = FormElementDescriptionFilePath(Form);
	
	ModuleFile = New File(PathToFile);
	If Not ModuleFile.Exists() Then
		Return Undefined;
	EndIf;
	
	DOMDocument = DOMDocument(PathToFile);
	
	XPathResult = EvaluateXPathExpression(XPathExpressionMainAttributeFormType(), DOMDocument);
	MainPropertyType = XPathResult.IterateNext();
	If MainPropertyType = Undefined Then
		Return Undefined;
	EndIf;
	
	XMLTypeByString = MainPropertyType.TextContent;
	StringParts1 = StrSplit(XMLTypeByString, ":", True);
	If StringParts1.Count() = 2 Then
		XMLTypeByString = StringParts1[1];
	EndIf;
	
	If XMLTypeByString = "SettingsComposer" Then
		Return Type("DataCompositionSettingsComposer");
	EndIf;
	
	Return Type(XMLTypeByString);
	
EndFunction

// Parameters:
//   Form - MetadataObject - Object form.
//
Function MainTableOfFormListName(Form)
	
	PathToFile = FormElementDescriptionFilePath(Form);
	
	ModuleFile = New File(PathToFile);
	If Not ModuleFile.Exists() Then
		Return Undefined;
	EndIf;
	
	DOMDocument = DOMDocument(PathToFile);
	
	XPathResult = EvaluateXPathExpression(XPathExpressionFormList(), DOMDocument);
	MainTable = XPathResult.IterateNext();
	If MainTable = Undefined Then
		Return Undefined;
	EndIf;
	Return MainTable.TextContent;
	
EndFunction

// Parameters:
//   Form - MetadataObject - Object form.
//
Function FormElementDescriptionFilePath(Form)
	
	NameParts = StrSplit(Form.FullName(), ".");
	
	Parameters = New Structure;
	Parameters.Insert("DumpDirectory", DumpDirectory);
	Parameters.Insert("BaseTypeName", ObjectInFileUploadKindName[NameParts[0]]);
	Parameters.Insert("ObjectName", NameParts[1]);
	
	If Not Metadata.CommonForms.Contains(Form) Then
		NameTemplate = FormElementDescriptionFilePathTemplate();
		Parameters.Insert("FormName", Form.Name);
	Else
		NameTemplate = CommonFormElementsDescriptionFilePathTemplate();
	EndIf;
	
	Return StringFunctionsClientServer.InsertParametersIntoString(NameTemplate, Parameters);
	
EndFunction

// Parameters:
//   Form - MetadataObject - Object form.
//
Function FormModuleFilePath(Form)
	
	NameParts = StrSplit(Form.FullName(), ".");
	
	Parameters = New Structure;
	Parameters.Insert("DumpDirectory", DumpDirectory);
	Parameters.Insert("BaseTypeName", ObjectInFileUploadKindName[NameParts[0]]);
	Parameters.Insert("ObjectName", NameParts[1]);
	
	If Not Metadata.CommonForms.Contains(Form) Then
		NameTemplate = ObjectFormModuleFilePathTemplate();
		Parameters.Insert("FormName", Form.Name);
	Else
		NameTemplate = CommonFormModuleFilePathTemplate();
	EndIf;
	
	Return StringFunctionsClientServer.InsertParametersIntoString(NameTemplate, Parameters);
	
EndFunction

Function PathToCommandModuleFile(Command)
	
	NameParts = StrSplit(Command.FullName(), ".");
	
	Parameters = New Structure;
	Parameters.Insert("DumpDirectory", DumpDirectory);
	Parameters.Insert("BaseTypeName", ObjectInFileUploadKindName[NameParts[0]]);
	Parameters.Insert("ObjectName", NameParts[1]);
	
	If Not Metadata.CommonCommands.Contains(Command) Then
		NameTemplate = ObjectCommandModuleFilePathTemplate();
		Parameters.Insert("CommandName", Command.Name);
	Else
		NameTemplate = CommonCommandModuleFilePathTemplate();
	EndIf;
	
	Return StringFunctionsClientServer.InsertParametersIntoString(NameTemplate, Parameters);
	
EndFunction

Function PathToSharedModuleFile(MetadataObject)
	
	NameParts = StrSplit(MetadataObject.FullName(), ".");
	
	Parameters = New Structure;
	Parameters.Insert("DumpDirectory", DumpDirectory);
	Parameters.Insert("BaseTypeName", ObjectInFileUploadKindName[NameParts[0]]);
	Parameters.Insert("ObjectName", NameParts[1]);
	Parameters.Insert("ModuleType", "CommonModule");
	
	NameTemplate = CommonModuleFilePathTemplate();
	
	Return StringFunctionsClientServer.InsertParametersIntoString(NameTemplate, Parameters);
	
EndFunction

Function ObjectManagerModuleFilePath(MetadataObject)
	
	NameParts = StrSplit(MetadataObject.FullName(), ".");
	
	Parameters = New Structure;
	Parameters.Insert("DumpDirectory", DumpDirectory);
	Parameters.Insert("BaseTypeName", ObjectInFileUploadKindName[NameParts[0]]);
	Parameters.Insert("ObjectName", NameParts[1]);
	Parameters.Insert("ModuleType", "ManagerModule");
	
	NameTemplate = ObjectModuleFilePathTemplate();
	
	Return StringFunctionsClientServer.InsertParametersIntoString(NameTemplate, Parameters);
	
EndFunction

Function PathToObjectModuleFile(MetadataObject)
	
	NameParts = StrSplit(MetadataObject.FullName(), ".");
	
	Parameters = New Structure;
	Parameters.Insert("DumpDirectory", DumpDirectory);
	Parameters.Insert("BaseTypeName", ObjectInFileUploadKindName[NameParts[0]]);
	Parameters.Insert("ObjectName", NameParts[1]);
	Parameters.Insert("ModuleType", "ObjectModule");
	
	NameTemplate = ObjectModuleFilePathTemplate();
	
	Return StringFunctionsClientServer.InsertParametersIntoString(NameTemplate, Parameters);
	
EndFunction

// Compares the catalog attributes with a sample stored in the report template.
//
// Parameters:
//  CatalogName - String - Catalog name in configuration metadata.
//  SampleLayoutName - String - Name of the report template the sample belongs to.
//
Procedure CheckCatalogAttributesCompositionPatternMatching(CatalogName, SampleLayoutName)
	
	SampleTable            = TemplateToValuesTable(SampleLayoutName);
	CatalogMetadata     = Metadata.Catalogs[CatalogName];
	CatalogAttributes      = CatalogMetadata.Attributes;
	ColumnsInSampleNumber = SampleTable.Columns.Count();
	
	ThereAreFixes      = False;
	MetadataFilePath = MetadataObjectDescriptionFilePath(CatalogMetadata);
	If FixError("WorkingWithFilesValueType")
		Or FixError("WorkingWithFilesPropertyValue") Then
		DOMDocument = ?(IsBlankString(DumpDirectory), Undefined, DOMDocument(MetadataFilePath));
	EndIf;
	
	For Each SampleString In SampleTable Do
		
		AttributeName = SampleString.Attribute;
		If IsBlankString(AttributeName) Then
			Continue;
		EndIf;
		
		AvailabilityMandatory  = SampleString.AvailabilityMandatory = "True";
		AttributeToCheck = CatalogAttributes.Find(AttributeName);
		If AttributeToCheck = Undefined Then
			
			If AvailabilityMandatory Then
				AttributeAbsenceText = NStr("ru = 'В справочнике присоединенных файлов ""%1"" не найден реквизит ""%2"".';
												|en = 'The %2 attribute is not found in the %1 attachment catalog';");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(AttributeAbsenceText, CatalogName, AttributeName);
				AddError(CatalogMetadata, NStr("ru = 'Отсутствует обязательный реквизит';
															|en = 'The required attribute is missing';"), ErrorText);
			EndIf;
			
			Continue;
			
		EndIf;
		
		AttributeTypeSample = SampleString.Type;
		If Not IsBlankString(AttributeTypeSample)
			And Not AttributeToCheck.Type = TypesDescriptionFromString(AttributeTypeSample) Then
			
			MismatchTypeText = NStr("ru = 'Неверный тип реквизита ""%1"". Требуемый тип реквизита: %2.';
											|en = 'Incorrect attribute type %1. Required attribute type: %2.';");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(MismatchTypeText, 
							AttributeName, StrReplace(AttributeTypeSample, "/", ", "));
			
			If FixError("WorkingWithFilesValueType") Then
				ThereAreFixes = True;
				ErrorText = ChangeAttributeType(DOMDocument, AttributeToCheck.Name, AttributeTypeSample);
			EndIf;
			
			AddError(CatalogMetadata, NStr("ru = 'Несоответствие типов';
														|en = 'Type mismatch';"), ErrorText);
			
		EndIf;
		
		For IndexOf = 3 To ColumnsInSampleNumber - 1 Do
			
			ColumnName = SampleTable.Columns[IndexOf].Name;
			CellValue = SampleString[ColumnName];
			If IsBlankString(CellValue) Then
				Continue;
			EndIf;
			
			PropertyValue = AttributeToCheck[ColumnName];
			If Not ComparePropertyValueWithSample(ColumnName, CellValue, PropertyValue) Then
				
				MismatchPropertyText = NStr("ru = 'Неверное значение свойства ""%1"" реквизита ""%2"". Требуемое значение свойства: ""%3"".';
													|en = 'Incorrect %1 property value of the %2 attribute. Required property value: %3.';");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(MismatchPropertyText,
					ColumnName, AttributeName, CellValue);
				
				If FixError("WorkingWithFilesPropertyValue") Then
					
					ThereAreFixes  = True;
					CorrectionText = ChangePropertyValue(DOMDocument, AttributeToCheck.Name, ColumnName, CellValue);
					If Not IsBlankString(CorrectionText) Then
						ErrorText = CorrectionText;
					EndIf;
					
				EndIf;
				
				AddError(CatalogMetadata, NStr("ru = 'Неверное значение свойства';
															|en = 'Incorrect property value';"), ErrorText);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	If ThereAreFixes Then
		WriteDOMDocument(DOMDocument, MetadataFilePath);
	EndIf;
	
EndProcedure

// Checks if forms contain required code insertions. 
// Takes the code sample in the report template as a reference.
//
// Parameters:
//  SampleLayoutName - String - Name of the report template that contains the code sample.
//  MetadataFilter - Array of MetadataObject - Metadata objects to check.
//
Procedure CheckModulesSourceCodeAccordingBySample(SampleLayoutName, MetadataFilter = Undefined)
	
	SampleTable = TemplateToValuesTable(SampleLayoutName);
	ChecksArray = SampleTable.FindRows(New Structure("Module", "ObjectFormModule"));
	
	CheckedModules = New Array;
	CheckedModules.Add("CommonFormModule");
	For Each CommonForm In Metadata.CommonForms Do
		If MetadataFilter <> Undefined And MetadataFilter.Find(CommonForm) = Undefined Then
			Continue;
		EndIf;
		
		CheckMetadataObjectSourceCodeBySample(CommonForm, ChecksArray, CheckedModules);
	EndDo;
	
	CheckedModules = New Array;
	For Each Catalog In Metadata.Catalogs Do
		If MetadataFilter <> Undefined And MetadataFilter.Find(Catalog) = Undefined Then
			Continue;
		EndIf;
		
		CheckMetadataObjectSourceCodeBySample(Catalog, ChecksArray, CheckedModules);
	EndDo;
	
	For Each Document In Metadata.Documents Do
		If MetadataFilter <> Undefined And MetadataFilter.Find(Document) = Undefined Then
			Continue;
		EndIf;
		
		CheckMetadataObjectFormsPatternMatching(Document, ChecksArray, CheckedModules);
	EndDo;
	
	For Each DataProcessor In Metadata.DataProcessors Do
		If MetadataFilter <> Undefined And MetadataFilter.Find(DataProcessor) = Undefined Then
			Continue;
		EndIf;
		
		CheckMetadataObjectFormsPatternMatching(DataProcessor, ChecksArray, CheckedModules);
	EndDo;
	
	For Each BusinessProcess In Metadata.BusinessProcesses Do
		If MetadataFilter <> Undefined And MetadataFilter.Find(BusinessProcess) = Undefined Then
			Continue;
		EndIf;
		
		CheckMetadataObjectFormsPatternMatching(BusinessProcess, ChecksArray, CheckedModules);
	EndDo;
	
	For Each Task In Metadata.Tasks Do
		If MetadataFilter <> Undefined And MetadataFilter.Find(Task) = Undefined Then
			Continue;
		EndIf;
		
		CheckMetadataObjectFormsPatternMatching(Task, ChecksArray, CheckedModules);
	EndDo;
	
EndProcedure

#EndRegion

#Region SubsystemsInternalProcedures

#Region Core

// Called from CheckUnrecommendedRolesContent.
//
// Parameters:
//   XDTODataObject - Role rights.
//   NameOfRole - String - Full role name.
//   Correct - Boolean - False - Test only. True - Fix.
//
Function CheckRightsToBankingDetailsInRole(DOMDocument, NameOfRole, Correct)
	
	HasChangedRoles = False;
	ErrorText = "";
	BriefErrorDetails = "";
	
	SetNewObjectsRights = RoleProperty(ErrorText, BriefErrorDetails, Correct,
		DOMDocument, SetRightsForNewObjectsProperty());
		
	If Not IsBlankString(ErrorText) Then
		AddRoleDetailsRightsError(Metadata.Roles[NameOfRole],
			BriefErrorDetails,
			ErrorText);
	EndIf;
	
	SetDetailsAndTablePartsRightsByDefault = RoleProperty(ErrorText, BriefErrorDetails, Correct,
		DOMDocument, SetRightsForDetailsAndTablePartsByDefaultProperty(), True);
		
	If Not IsBlankString(ErrorText) Then
		AddRoleDetailsRightsError(Metadata.Roles[NameOfRole],
			BriefErrorDetails,
			ErrorText);
	EndIf;
	
	SubordinateObjectsIndependentRights = RoleProperty(ErrorText, BriefErrorDetails, Correct,
		DOMDocument, IndependentSubordinateObjectsRightsProperty(), False);
		
	If Not IsBlankString(ErrorText) Then
		AddRoleDetailsRightsError(Metadata.Roles[NameOfRole],
			BriefErrorDetails,
			ErrorText);
	EndIf;
	
	RoleComposition = EvaluateXPathExpression(XPathExpressionRoleComposition(), DOMDocument);
	If SetNewObjectsRights = Undefined
		 Or SetDetailsAndTablePartsRightsByDefault = Undefined
		 Or SubordinateObjectsIndependentRights = Undefined
		 Or RoleComposition = Undefined Then
		Return HasChangedRoles;
	EndIf;
	
	SubordinateObjectsNames = New Map;
	SubordinateObjectsNames.Insert("Attribute",              True);
	SubordinateObjectsNames.Insert("StandardAttribute",      True);
	SubordinateObjectsNames.Insert("TabularSection",         True);
	SubordinateObjectsNames.Insert("StandardTabularSection", True);
	SubordinateObjectsNames.Insert("Dimension",              True);
	SubordinateObjectsNames.Insert("Resource",               True);
	SubordinateObjectsNames.Insert("Command",                False);
	
	SkippedMetadataObjects = SkippedMetadataObjectsInRole(RoleComposition,
		SetNewObjectsRights);
		
	InRoleDetailsTable = New ValueTable;
	InRoleDetailsTable.Columns.Add("RoleObject");
	InRoleDetailsTable.Columns.Add("FullObjectName");
	InRoleDetailsTable.Columns.Add("NameParts");
	
	MetadataObjectNamesList = New Array;
	MatchingMetadataObjects = MatchingMetadataObjects();
	AttributesInRoleByMetadataObjects = New Map;
	MetadataObjectsWithAttributes = New ValueList;
	
	While True Do
		
		RoleObject = RoleComposition.IterateNext();
		If RoleObject = Undefined Then
			Break;
		EndIf;
		
		FullObjectName = GetProperty(RoleObject, RoleObjectNameProperty());
		If FullObjectName = Undefined Then
			Continue;
		EndIf;
		
		NameParts = StrSplit(FullObjectName, ".");
		If NameParts.Count() < 3 Then
			
			MetadataObjectNamesList.Add(FullObjectName);
			
		Else
			
			MetadataObject = MatchingMetadataObjects.Get(NameParts[0] + "." + NameParts[1]);
			If MetadataObject = Undefined Then
				Continue;
			EndIf;
			CurrentTable = AttributesInRoleByMetadataObjects.Get(MetadataObject);
			If CurrentTable = Undefined Then
				CurrentTable = InRoleDetailsTable.Copy();
				AttributesInRoleByMetadataObjects.Insert(MetadataObject, CurrentTable);
				MetadataObjectsWithAttributes.Add(MetadataObject, MetadataObject.FullName());
			EndIf;
			NewAttributeInRole = CurrentTable.Add();
			NewAttributeInRole.RoleObject = RoleObject;
			NewAttributeInRole.FullObjectName = FullObjectName;
			NewAttributeInRole.NameParts = NameParts;
		EndIf;
		
	EndDo;
	
	MetadataObjectsWithAttributes.SortByPresentation();
	
	For Each MetadataObjectDetails In MetadataObjectsWithAttributes Do
		MetadataObject = MetadataObjectDetails.Value;
		CurrentTable = AttributesInRoleByMetadataObjects.Get(MetadataObject);
		CurrentErrors = New ValueList;
		
		For Each AttributeInRole In CurrentTable Do
			
			IsField = SubordinateObjectsNames.Get(AttributeInRole.NameParts[2]);
			If IsField = Undefined Then
				Continue;
			EndIf;
			
			If Not IsSSLObject(MetadataObject) And IsField Then
				MetadataObjectInList = MetadataObjectNamesList.Find(AttributeInRole.NameParts[0] + "." + AttributeInRole.NameParts[1]) <> Undefined;
				CheckTheRightToRead = Not (MetadataObjectInConfigurationLanguageKindName.Property(AttributeInRole.NameParts[0])
					And (MetadataObjectInConfigurationLanguageKindName[AttributeInRole.NameParts[0]] = "DataProcessor"
						Or MetadataObjectInConfigurationLanguageKindName[AttributeInRole.NameParts[0]] = "Report"
						Or MetadataObjectInConfigurationLanguageKindName[AttributeInRole.NameParts[0]] = "DocumentJournal"));
				If (SetNewObjectsRights
					And MetadataObjectInList
					And (CheckTheRightToRead And AccessRight("Read", MetadataObject, Metadata.Roles[NameOfRole])))
					Or (SetNewObjectsRights
					And Not MetadataObjectInList) 
					Or (Not SetNewObjectsRights
					And MetadataObjectInList) Then
					Continue;
				EndIf;
			EndIf;
			
			StandardDetailsSynonyms = StandardDetailsSynonyms();
			StandardTablePartPosition = StrFind(AttributeInRole.FullObjectName, "StandardTabularSection");
			StandardAttributesPosition = StrFind(AttributeInRole.FullObjectName, "StandardAttribute");
			
			If StandardTablePartPosition > 0 Then
				AttributePath = Mid(AttributeInRole.FullObjectName, StandardTablePartPosition);
				ConvertPathToStandardAttributes(AttributePath, StandardDetailsSynonyms);
				AttributeName = Mid(AttributePath, 2);
			ElsIf StandardAttributesPosition > 0 Then
				AttributePath = Mid(AttributeInRole.FullObjectName, StandardAttributesPosition);
				ConvertPathToStandardAttributes(AttributePath, StandardDetailsSynonyms);
				AttributeName = Mid(AttributePath, 2);
			Else
				AttributeMetadataObject = Common.MetadataObjectByFullName(AttributeInRole.FullObjectName);
				If AttributeMetadataObject = Undefined Then
					FullObjectName = AttributeInRole.FullObjectName;
				Else
					FullObjectName = AttributeMetadataObject.FullName();
				EndIf;
				CurrentNameComponents = StrSplit(FullObjectName, ".");
				CurrentNameComponents.Delete(0);
				CurrentNameComponents.Delete(0);
				AttributeName = StrConcat(CurrentNameComponents, ".");
			EndIf;
			
			SkippedObject = SkippedMetadataObjects[AttributeInRole.NameParts[0] + "." + AttributeInRole.NameParts[1]];
			
			RightsToField = New Structure;
			RightsToField.Insert("View", "Unspecified");
			RightsToField.Insert("Edit", "Unspecified");
			
			ObjectRightView = Undefined;
			ObjectRightEdit = Undefined;
			For Each ObjectRight In AttributeInRole.RoleObject.ChildNodes Do
				NameOfRight = GetProperty(ObjectRight, RightsNameProperty());
				If NameOfRight = Undefined Then
					Continue;
				EndIf;
				If Not RightsToField.Property(NameOfRight) Then
					Continue;
				EndIf;
				RightsToField[NameOfRight] = GetProperty(ObjectRight, RightValueProperty());
				
				If NameOfRight = "View" Then
					ObjectRightView = ObjectRight;
				EndIf;
				If NameOfRight = "Edit" Then
					ObjectRightEdit = ObjectRight;
				EndIf;
			EndDo;
			
			If Not IsField Then // This is a command.
				If (SkippedObject = Undefined Or Not SkippedObject["View"])
					 And RightsToField["View"] = True Then
					
					If Correct Then
						SetProperty(ObjectRightView, RightValueProperty(), False);
						HasChangedRoles = True;
					EndIf;
					ErrorText = ?(Correct, NStr("ru = 'Исправлено.';
													|en = 'Fixed.';") + " ", "")
						+ StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 (лишнее право Просмотр)';
																						|en = '%1 (View right redundant)';"), AttributeName);
					CurrentErrors.Add(ErrorText);
					
				EndIf;
				Continue;
			EndIf;
			
			If RightsToField["View"] = "Unspecified" Then
				RightsToField["View"] = SetDetailsAndTablePartsRightsByDefault;
			EndIf;
			If RightsToField["Edit"] = "Unspecified" Then
				RightsToField["Edit"] = SetDetailsAndTablePartsRightsByDefault;
			EndIf;
			
			If RightsToField["View"] <> SetDetailsAndTablePartsRightsByDefault Then
				If Correct Then
					SetProperty(ObjectRightView, RightValueProperty(), 
						SetDetailsAndTablePartsRightsByDefault);
					HasChangedRoles = True;
				EndIf;
			EndIf;
				
			If RightsToField["Edit"] <> SetDetailsAndTablePartsRightsByDefault Then
				If Correct Then
					SetProperty(ObjectRightEdit, RightValueProperty(), 
						SetDetailsAndTablePartsRightsByDefault);
					HasChangedRoles = True;
				EndIf;
			EndIf;
	
			If RightsToField["View"] <> SetDetailsAndTablePartsRightsByDefault 
				And RightsToField["Edit"] <> SetDetailsAndTablePartsRightsByDefault Then
					
				Template = ?(SetDetailsAndTablePartsRightsByDefault,
					NStr("ru = '%1 (нет прав %2 и %3)';
						|en = '%1 (rights %2 and %3 missing)';"),
					NStr("ru = '%1 (лишние права %2 и %3)';
						|en = '%1 (rights %2 and %3 redundant)';"));
				ErrorText = ?(Correct, NStr("ru = 'Исправлено.';
												|en = 'Fixed.';") + " ", "")
					+ StringFunctionsClientServer.SubstituteParametersToString(Template,
						AttributeName, "View", "Edit");
				CurrentErrors.Add(ErrorText);
	
			ElsIf RightsToField["View"] <> SetDetailsAndTablePartsRightsByDefault Then
	
				Template = ?(SetDetailsAndTablePartsRightsByDefault,
					NStr("ru = '%1 (нет права %2)';
						|en = '%1 (right %2 missing)';"),
					NStr("ru = '%1 (лишнее право %2)';
						|en = '%1 (right %2 redundant)';"));
				ErrorText = ?(Correct, NStr("ru = 'Исправлено.';
												|en = 'Fixed.';") + " ", "")
					+ StringFunctionsClientServer.SubstituteParametersToString(Template, AttributeName, "View");
				CurrentErrors.Add(ErrorText);
		
			ElsIf RightsToField["Edit"] <> SetDetailsAndTablePartsRightsByDefault Then
	
				Template = ?(SetDetailsAndTablePartsRightsByDefault,
					NStr("ru = '%1 (нет права %2)';
						|en = '%1 (right %2 missing)';"),
					NStr("ru = '%1 (лишнее право %2)';
						|en = '%1 (right %2 redundant)';"));
				ErrorText = ?(Correct, NStr("ru = 'Исправлено.';
												|en = 'Fixed.';") + " ", "") 
					+ StringFunctionsClientServer.SubstituteParametersToString(Template, AttributeName, "Edit");
				CurrentErrors.Add(ErrorText);
				
			EndIf;
			
		EndDo;
		
		If Not ValueIsFilled(CurrentErrors) Then
			Continue;
		EndIf;
		ErrorTitle = NStr("ru = 'Право на реквизит (табличную часть) отличается от значения по умолчанию в роли';
								|en = 'Right to attribute (table) differs from the default value in the role';");
		CurrentErrors.SortByValue();
		ErrorText = MetadataObject.FullName() + ":
		|- " + StrConcat(CurrentErrors.UnloadValues(), Chars.LF + "- ") + Chars.LF;
		AddRoleDetailsRightsError(Metadata.Roles[NameOfRole], ErrorTitle, ErrorText, , ,
			SetDetailsAndTablePartsRightsByDefault);
		
	EndDo;
	
	Return HasChangedRoles;
	
EndFunction

// Called from Attachable_Core_ValidateIntegration.
//
Procedure CheckNonRecommendedRolesComposition()
	
	Files = FindFiles(RoleFilesPath(), RoleFileName(), True);
	
	For Each File In Files Do
		
		DOMDocument = DOMDocument(File.FullName);
		
		Correct = False;
		If FixError("NotRecommendedRolesComposition") Then
			Correct = True;
		EndIf;
		
		NameOfRole = RoleNameByFileName(File.FullName);
		
		HasChangedRoles = CheckRightsToBankingDetailsInRole(DOMDocument, NameOfRole, Correct);
		
		If Correct And HasChangedRoles Then
			WriteDOMDocument(DOMDocument, File.FullName);
			FilesToUpload.Add(File.FullName);
		EndIf;
	
	EndDo;
	
EndProcedure

Procedure CheckMainRolesComposition()
	
	MainRolesTemplates = MainRolesTemplates();
	SkipNewRights = Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.DontUse;
	
	If SkipNewRights Then
		MinimumVersions = Common.MinPlatformVersion();
		MinimumVersions = StrSplit(MinimumVersions, ";");
		MinVersion = TrimAll(MinimumVersions[0]);
		
		SystemInfo = New SystemInfo;
		CurrentVersion = CommonClientServer.ConfigurationVersionWithoutBuildNumber(SystemInfo.AppVersion);
		CurrentMinimumVersion = CommonClientServer.ConfigurationVersionWithoutBuildNumber(MinVersion);
		
		If CurrentMinimumVersion = CurrentVersion Then
			SkipNewRights = False;
		EndIf;
	EndIf;
	
	// Right template relevance check. Applicable to SSL only.
	If Not SkipNewRights And IsDemoSSL() And FixError("MainRolesComposition") Then
		For Each RoleTemplates In MainRolesTemplates Do
			
			RoleRightsTemplate        = RoleTemplates.Value.RightsByRole.Template;
			TemplateForTemplateRightsByRoleReference = RoleTemplates.Value.RightsByRoleReference.Template;
			If EDTConfiguration And CompareEdtxxxRoleTemplates(RoleRightsTemplate, TemplateForTemplateRightsByRoleReference)
				Or RoleRightsTemplate = TemplateForTemplateRightsByRoleReference Then
				Continue;
			EndIf;
			
			TemplateMetadata = Metadata.Reports.SSLImplementationCheck.Templates[RoleTemplates.Key];
			TemplateFileName = ObjectLayoutFilePath(TemplateMetadata);
			TextDocument = New TextDocument;
			TextDocument.SetText(RoleTemplates.Value.RightsByRole.Template);
			TextDocument.Write(TemplateFileName);
			FilesToUpload.Add(TemplateFileName);
			BriefErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не обновлен эталонный макет для проверки роли %1.';
					|en = 'Reference template for checking the %1 role is not updated.';"), RoleTemplates.Key);
			ErrorText = NStr("ru = 'Исправлено. Макет роли ""%1"" обновлен';
								|en = 'Fixed. Template of the %1 role is updated';");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, RoleTemplates.Key);
			AddError(Metadata.Reports["SSLImplementationCheck"], BriefErrorDetails, ErrorText);
		EndDo;
		Return;
	EndIf;
	
	For Each RoleTemplates In MainRolesTemplates Do
		HasErrors = False;
		CompareRoleWithReference(RoleTemplates.Key, RoleTemplates.Value, SkipNewRights, HasErrors);
		If HasErrors And IsDemoSSL() And FixError("MainRolesComposition") Then
			BriefErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не обновлен эталонный макет для проверки роли %1.';
					|en = 'Reference template for checking the %1 role is not updated.';"), RoleTemplates.Key);
			ErrorText = NStr("ru = 'Не исправлено. Макет роли ""%1"" не обновлен.
				|Автоисправление возможно только на версии платформы, совпадающей с режимом совместимости конфигурации.';
				|en = 'Not fixed. The template of the ""%1"" role is not updated.
				|Auto-correction is available only on the platform version that matches configuration compatibility mode.';");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, RoleTemplates.Key);
			AddError(Metadata.Reports["SSLImplementationCheck"], BriefErrorDetails, ErrorText);
		EndIf;
	EndDo;
	
EndProcedure

Procedure CompareRoleWithReference(NameOfRole, RoleTemplates, SkipNewRights, HasErrors)
	
	IsDemoSSL = IsDemoSSL();
	
	If IsDemoSSL Then
		BriefErrorDetails   = NStr("ru = 'Не обновлен эталонный макет для проверки роли %1.';
										|en = 'Reference template for checking the %1 role is not updated.';");
		Refinement = NStr("ru = 'Для автоматического обновления макета запустите отчет %1 на минимальной версии платформы разрешенной для запуска
			|с флажком ""Исправлять ошибки"", выбрав исправляемую ошибку ""Базовая функциональность. В роли %2 или %3 права отличаются от эталонных""
			|(предварительно захватив в хранилище макет ""%4"" отчета %1).
			|
			|Важно: Отчет не проверяет корректность прав, а только обновляет поставляемый шаблон прав БСП, поэтому сначала исправьте ошибки по правам в АПК.';
			|en = 'For automatic template update, start the %1 report on the minimal compatible platform version 
			|with selected ""Correct errors"" check box and select the ""Core. In the %2 or %3 role, access rights are different from the reference ones"" error to correct
			| (after capturing the ""%4"" template of the %1 report in the storage).
			|
			|Important: The report does not check whether rights are correct, it only updates the 1C-supplied template of SSL rights. Therefore, first, you need to fix rights errors in Automatic Configuration Checker.';");
		Refinement = StringFunctionsClientServer.SubstituteParametersToString(Refinement, "SSLImplementationCheck", "SystemAdministrator", "FullAccess", "%1");
		
		ErrorCorrectionTemplate = Chars.LF + Refinement;
		PresentRightErrorTemplate = NStr("ru = 'Значения прав на ""%1"" в роли отличается от значения эталонном макете.';
											|en = 'Values of rights to ""%1"" in the role differ from the reference template value.';");
		MissingRightErrorTemplate  = NStr("ru = 'Значения прав на ""%1"" в роли отличается от значения эталонном макете.';
											|en = 'Values of rights to ""%1"" in the role differ from the reference template value.';");
	Else
		BriefErrorDetails         = NStr("ru = 'Права на объект БСП в роли %1 отличаются от поставляемых.';
											|en = 'Access rights to the SSL object in the %1 role are different from the 1C-supplied rights.';");
		MissingRightErrorTemplate  = NStr("ru = 'В роли ""%2"" отсутствует право ""%3"" на объект ""%1"".';
											|en = 'Right ""%3"" to object ""%1"" is missing from role ""%2"".';");
		PresentRightErrorTemplate = NStr("ru = 'В роли ""%2"" установлено лишнее право ""%3"" на объект ""%1"".';
											|en = 'Role ""%2"" has extra right ""%3"" to object ""%1"".';");
	EndIf;
	BriefErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(BriefErrorDetails, NameOfRole);
	
	RightsTypesSynonyms = RightsTypesSynonyms();
	
	RightsByRole        = RoleTemplates.RightsByRole.Table;
	RightsByRoleReference = RoleTemplates.RightsByRoleReference.Table;
	
	RightsComparisonResult = ResultOfComparingRightsWithReference(RightsByRole, RightsByRoleReference);
	
	ReportVersionIsDifferent = ReportVersionDiffersFromLibraryVersion();
	LibraryVersion       = StandardSubsystemsServer.LibraryVersion();
	
	HasMissedErrors = False;
	For Each ObjectRightsComparison In RightsComparisonResult Do
		
		If Not IsDemoSSL() And Not IsSSLObject(Common.MetadataObjectByFullName(ObjectRightsComparison.Key)) Then
			Continue;
		EndIf;
		
		FlagChanges = False;
		ObjectErrors = New Array;
		
		For Each RightString In ObjectRightsComparison.Value Do
			
			If ReportVersionIsDifferent And RightString.UsedInRole And Not RightString.UsedInReference Then
				HasMissedErrors = True;
				Break;
			EndIf;
			
			If RightString.UsedInReference And Not RightString.UsedInRole And RightString.StandardVal = True Then
				ErrorTemplate = MissingRightErrorTemplate;
			ElsIf RightString.UsedInReference And Not RightString.UsedInRole And RightString.StandardVal = False Then
				ErrorTemplate = PresentRightErrorTemplate;
			ElsIf Not RightString.UsedInReference And RightString.UsedInRole And RightString.Value = True  Then
				ErrorTemplate = PresentRightErrorTemplate;
			ElsIf Not RightString.UsedInReference And RightString.UsedInRole And RightString.Value = False  Then
				ErrorTemplate = MissingRightErrorTemplate;
			ElsIf RightString.StandardVal <> RightString.Value And RightString.StandardVal = True Then
				ErrorTemplate = MissingRightErrorTemplate;
			ElsIf RightString.StandardVal <> RightString.Value And RightString.StandardVal = False Then
				ErrorTemplate = PresentRightErrorTemplate;
			Else
				Continue;
			EndIf;
			
			Right = RightsTypesSynonyms.Get(RightString.Right);
			If SkipNewRights And Right = Undefined Then
				Continue;
			EndIf;
			Right = ?(Right = Undefined, RightString.Right, Right);
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
				RightString.Object, NameOfRole, Right);
			
			If IsDemoSSL Then
				FlagChanges = True;
			EndIf;
			
			If FlagChanges Then
				ObjectErrors.Add(ErrorText);
				Break; // State the error presence without details.
			Else
				HasErrors = True;
				ObjectParts = StrSplit(RightString.Object, ".");
				FullName = ObjectParts[0] + "." + ObjectParts[1];
				
				AddError(Common.MetadataObjectByFullName(FullName),
					BriefErrorDetails,
					ErrorText);
			EndIf;
		EndDo;
		
		If FlagChanges Then
			
			ObjectErrors.Add(StringFunctionsClientServer.SubstituteParametersToString(ErrorCorrectionTemplate, NameOfRole));
			
			HasErrors = True;
			ObjectParts = StrSplit(ObjectRightsComparison.Key, ".");
			FullName = ObjectParts[0] + "." + ObjectParts[1];
			AddError(Common.MetadataObjectByFullName(FullName),
				BriefErrorDetails,
				StrConcat(ObjectErrors, Chars.LF));
			
		EndIf;
		
	EndDo;
	
	If HasMissedErrors Then
		Template = NStr("ru = 'Часть ошибок отличия прав на объекты БСП от поставляемых не была зарегистрирована.
			|Версия проверки внедрения ""%1"" отличается от используемой версии БСП ""%2"".';
			|en = 'Some errors occurred due to difference of rights to SSL objects from the 1C-supplied rights were not registered.
			|Integration check version ""%1"" differs from the used SSL version ""%2"".';");
		AddError(Metadata.Subsystems.StandardSubsystems,
			BriefErrorDetails,
			StringFunctionsClientServer.SubstituteParametersToString(Template,
				ReportVersion(), LibraryVersion));
	EndIf;
	
EndProcedure

Function GetRights(DOMDocument, IsStandard)
	
	RoleDetails = EvaluateXPathExpression(XPathExpressionRoleDescription(), DOMDocument).IterateNext();
	RoleComposition = EvaluateXPathExpression(XPathExpressionRoleComposition(), DOMDocument);
	
	StringQualifier150 = New StringQualifiers(150);
	RightsTable = New ValueTable;
	RightsTable.Columns.Add("Object",   New TypeDescription("String", ,StringQualifier150));
	RightsTable.Columns.Add("Right",    New TypeDescription("String", ,StringQualifier150));
	RightsTable.Columns.Add("Value", New TypeDescription("Boolean"));
	
	StandardDetailsSynonyms = StandardDetailsSynonyms();
	
	While True Do
		
		RoleObject = RoleComposition.IterateNext();
		If RoleObject = Undefined Then
			Break;
		EndIf;
		
		FullObjectName = GetProperty(RoleObject, RoleObjectNameProperty());
		
		StandardTablePartPosition = StrFind(FullObjectName, "StandardTabularSection");
		StandardAttributesPosition = StrFind(FullObjectName, "StandardAttribute");
		
		If StandardTablePartPosition > 0 Then
			MetadataObject = Common.MetadataObjectByFullName(Mid(FullObjectName, 1, StandardTablePartPosition - 2));
			AttributePath = Mid(FullObjectName, StandardTablePartPosition);
			ConvertPathToStandardAttributes(AttributePath, StandardDetailsSynonyms);
			FullName = MetadataObject.FullName() + AttributePath;
		ElsIf StandardAttributesPosition > 0 Then
			MetadataObject = Common.MetadataObjectByFullName(Mid(FullObjectName, 1, StandardAttributesPosition - 2));
			AttributePath = Mid(FullObjectName, StandardAttributesPosition);
			ConvertPathToStandardAttributes(AttributePath, StandardDetailsSynonyms);
			FullName = MetadataObject.FullName() + AttributePath;
		ElsIf Left(FullObjectName, 13) = "Configuration" Then
			MetadataObject = Metadata;
			FullName = "Configuration.StandardSubsystemsLibrary";
			FullObjectName = "Configuration.StandardSubsystemsLibrary";
		Else
			MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
			If MetadataObject = Undefined Then
				// If a metadata object is not found in the configuration,
				// do not include its rights in the check table.
				Continue;
			Else
				FullName = MetadataObject.FullName();
			EndIf;
		EndIf;
		
		If Not MetadataObject = Undefined
			 And Not StrFind(FullName, "Subsystem") > 0
			 And Not TypeOf(MetadataObject) = Type("ConfigurationMetadataObject") Then
			
			MetadataObjectParent = MetadataObject.Parent();
			While Not TypeOf(MetadataObjectParent) = Type("ConfigurationMetadataObject") Do
				MetadataObject = MetadataObjectParent;
				MetadataObjectParent = MetadataObject.Parent();
			EndDo;
		EndIf;
		
		If Not IsStandard
			 And Not TypeOf(MetadataObject) = Type("ConfigurationMetadataObject")
			 And Not IsSSLObject(MetadataObject) Then
			RoleDetails.RemoveChild(RoleObject);
			Continue;
		EndIf;
		
		For Each ObjectRight In RoleObject.ChildNodes Do
			NameOfRight = GetProperty(ObjectRight, RightsNameProperty());
			If NameOfRight = Undefined Then
				Continue;
			EndIf;
			NewRow = RightsTable.Add();
			NewRow.Object   = FullName;
			NewRow.Right    = NameOfRight;
			NewRow.Value = GetProperty(ObjectRight, RightValueProperty());
		EndDo;
		
	EndDo;
	
	Template = WriteDOMDocument(DOMDocument);
	
	ReturnStructure = New Structure("Table, Template", RightsTable, Template);
	
	Return ReturnStructure;
	
EndFunction

Function MainRolesTemplates()
	
	Templates = New Structure;
	Templates.Insert("FullAccess", RoleTemplates("FullAccess"));
	Templates.Insert("SystemAdministrator", RoleTemplates("SystemAdministrator"));
	
	Return Templates;
	
EndFunction

Function RoleTemplates(NameOfRole)
	
	ReturnStructure = New Structure("RightsByRole, RightsByRoleReference");
	FullRightsRoleFile = RoleCompositionFilePath(NameOfRole);
	
	// Start reading configuration role properties.
	DOMDocument = DOMDocument(FullRightsRoleFile);
	
	ReturnStructure.RightsByRole = GetRights(DOMDocument, False);
	
	// Start reading template role properties.
	MemoryStream = New MemoryStream;
	TextDocumentFullRights = GetTemplate(NameOfRole);
	
	TextDocumentFullRightsCorrected = New TextDocument;
	RowsCount = TextDocumentFullRights.LineCount();
	
	For RowIndex = 1 To RowsCount Do
		FullRightsLine = TextDocumentFullRights.GetLine(RowIndex);
		If StrFind(FullRightsLine, "AllFunctionsMode") Then
			FullRightsLine = "			<name>TechnicalSpecialistMode</name>";
		EndIf;
		TextDocumentFullRightsCorrected.AddLine(FullRightsLine);
	EndDo;
	
	TextDocumentFullRightsCorrected.Write(MemoryStream);
	
	MemoryStream.Seek(0, PositionInStream.Begin);
	
	DOMDocument = DOMDocument(MemoryStream);
	MemoryStream.Close();
	
	ReturnStructure.RightsByRoleReference = GetRights(DOMDocument, True);
	
	Return ReturnStructure;
	
EndFunction

Function StandardDetailsSynonyms()
	
	Result = New Map();
	Result.Insert("StandardTabularSections", "StandardTabularSection");
	Result.Insert("StandardAttributes", "StandardAttribute");
	
	Result.Insert("PredefinedDataName", "PredefinedDataName");
	Result.Insert("Predefined", "Predefined");
	Result.Insert("Ref", "Ref");
	Result.Insert("DeletionMark", "DeletionMark");
	Result.Insert("IsFolder", "IsFolder");
	Result.Insert("Owner", "Owner");
	Result.Insert("Parent", "Parent");
	Result.Insert("Description", "Description");
	Result.Insert("Code", "Code");
	
	Result.Insert("Order", "Order");
	Result.Insert("OffBalance", "OffBalance");
	Result.Insert("Kind", "Type");
	
	Result.Insert("Date", "Date");
	Result.Insert("Posted", "Posted");
	Result.Insert("Number", "Number");
	Result.Insert("ValueType", "ValueType");
	
	Result.Insert("Executed", "Executed");
	Result.Insert("RoutePoint", "RoutePoint");
	Result.Insert("BusinessProcess", "BusinessProcess");
	
	Result.Insert("EntryType", "RecordType");
	Result.Insert("Active", "Active");
	Result.Insert("Recorder", "Recorder");
	Result.Insert("Period", "Period");
	
	Result.Insert("CalculationType", "CalculationType");
	
	Result.Insert("Account", "Account");
	Result.Insert("ExtDimension1", "ExtDimension1");
	Result.Insert("ExtDimensionType1", "ExtDimensionType1");
	Result.Insert("ExtDimension2", "ExtDimension2");
	Result.Insert("ExtDimensionType2", "ExtDimensionType2");
	Result.Insert("ExtDimension3", "ExtDimension3");
	Result.Insert("ExtDimensionType3", "ExtDimensionType3");
	
	Result.Insert("RegistrationPeriod", "RegistrationPeriod");
	Result.Insert("ReversingEntry", "ReversingEntry");
	Result.Insert("EndOfBasePeriod", "EndOfBasePeriod");
	Result.Insert("BegOfBasePeriod", "BegOfBasePeriod");
	Result.Insert("EndOfActionPeriod", "EndOfActionPeriod");
	Result.Insert("BegOfActionPeriod", "BegOfActionPeriod");
	Result.Insert("ActionPeriod", "ActionPeriod");
	
	Result.Insert("TurnoversOnly", "TurnoversOnly");
	Result.Insert("ExtDimensionType", "ExtDimensionType");
	Result.Insert("OffBalance", "OffBalance");
	
	Result.Insert("Started", "Started");
	Result.Insert("MainTask", "HeadTask");
	Result.Insert("Completed", "Completed");
	
	Result.Insert("ThisNode", "ThisNode");
	Result.Insert("ReceivedNo", "ReceivedNo");
	Result.Insert("SentNo", "SentNo");
	
	Result.Insert("DisplacingCalculationTypes", "DisplacingCalculationTypes");
	Result.Insert("LeadingCalculationTypes", "LeadingCalculationTypes");
	Result.Insert("BaseCalculationTypes", "BaseCalculationTypes");
	Result.Insert("LineNumber", "LineNumber");
	Result.Insert("CalculationType", "CalculationType");
	
	Result.Insert("ExtDimensionTypes", "ExtDimensionTypes");
	Result.Insert("ExtDimensionType", "ExtDimensionType");
	Result.Insert("TurnoversOnly", "TurnoversOnly");
	
	For Each Item In Result Do
		Result.Insert(Item.Value, Item.Key);
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

Procedure ConvertPathToStandardAttributes(AttributePath, StandardDetailsSynonyms)
	
	AttributesArray = StrSplit(AttributePath, ".");
	AttributePath = "";
	
	For Each Attribute In AttributesArray Do
		AttributeSynonym = StandardDetailsSynonyms.Get(Attribute);
		AttributePath = AttributePath + "." + ?(AttributeSynonym = Undefined, Attribute, AttributeSynonym);
	EndDo;
	
EndProcedure

Procedure CheckTheIntegrityOfSubsystems()
	
	CheckTheIntegrityOfTheSubsystemWorkingWithFiles();
	
EndProcedure

Procedure CheckTheIntegrityOfTheSubsystemWorkingWithFiles()
	
	SubsystemWorkingWithFiles = Metadata.Subsystems.StandardSubsystems.Subsystems.Find("FilesOperations");
	If SubsystemWorkingWithFiles = Undefined Then
		For Each CatalogMetadata In Metadata.Catalogs Do
			
			CatalogName = CatalogMetadata.Name;
			
			If Not StrEndsWith(CatalogName, "AttachedFiles") Then
				Continue;
			EndIf;
			
			If StrStartsWith(CatalogName, "Delete") Then
				Continue;
			EndIf;
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка внедрения подсистемы ""Работа с файлами';
					|en = 'Cannot integrate the File management subsystem';"), CatalogName);
			AddError(CatalogMetadata,
				NStr("ru = 'Существуют справочники, содержащие присоединенные файлы, при отсутствующей подсистеме ""Работа с файлами""';
					|en = 'Some catalogs contain attachments while the ""File management"" subsystem is missing';"), ErrorText);
			
		EndDo;
	EndIf;
	
EndProcedure

Function MatchingMetadataObjects()
	
	MatchingMetadataObjects = New Map;
	
	TypesOfTopLevelObjects = TypesOfTopLevelObjects();
	
	For Each TypeOfTopLevelObjects In TypesOfTopLevelObjects Do
		
		For Each MetadataObject In Metadata[TypeOfTopLevelObjects.Key] Do
			
			NameArray    = StrSplit(MetadataObject.FullName(), ".");
			NameArray[0] = TypeOfTopLevelObjects.Value;
			
			MetadataObjectName = StrConcat(NameArray, ".");
			
			MatchingMetadataObjects.Insert(MetadataObjectName, MetadataObject);
			
		EndDo;
		
	EndDo;
	
	Return MatchingMetadataObjects;
	
EndFunction

Function TypesOfTopLevelObjects()
	
	MatchingObjectTypes = New Map;
	MatchingObjectTypes.Insert("BusinessProcesses",          "BusinessProcess");
	MatchingObjectTypes.Insert("Documents",               "Document");
	MatchingObjectTypes.Insert("DocumentJournals",       "DocumentJournal");
	MatchingObjectTypes.Insert("Tasks",                  "Task");
	MatchingObjectTypes.Insert("Constants",               "Constant");
	MatchingObjectTypes.Insert("DataProcessors",               "DataProcessor");
	MatchingObjectTypes.Insert("Reports",                  "Report");
	MatchingObjectTypes.Insert("ChartsOfCalculationTypes",       "ChartOfCalculationTypes");
	MatchingObjectTypes.Insert("ChartsOfCharacteristicTypes", "ChartOfCharacteristicTypes");
	MatchingObjectTypes.Insert("ExchangePlans",             "ExchangePlan");
	MatchingObjectTypes.Insert("ChartsOfAccounts",             "ChartOfAccounts");
	MatchingObjectTypes.Insert("AccountingRegisters",     "AccountingRegister");
	MatchingObjectTypes.Insert("AccumulationRegisters",      "AccumulationRegister");
	MatchingObjectTypes.Insert("CalculationRegisters",         "CalculationRegister");
	MatchingObjectTypes.Insert("InformationRegisters",        "InformationRegister");
	MatchingObjectTypes.Insert("Catalogs",             "Catalog");
	
	Return MatchingObjectTypes;
	
EndFunction

Function ResultOfComparingRightsWithReference(RightsByRole, RightsByRoleReference)
	
	ResultTable1 = RightsByRole.Copy();
	ResultTable1.Columns.Add("StandardVal");
	ResultTable1.Columns.Add("UsedInRole");
	ResultTable1.Columns.Add("UsedInReference");
	
	// Populate new columns.
	For Each TableRow In ResultTable1 Do
		TableRow.StandardVal      = False;
		TableRow.UsedInRole    = True;
		TableRow.UsedInReference = False;
	EndDo;
	
	RightsByRole.Indexes.Add("Object, Right");
	
	// Add rows and values from the "Reference role rights" to the resulting table.
	For Each RightsTableRowByRoleReference In RightsByRoleReference Do
		TheStructureOfTheSearch = New Structure("Object, Right");
		FillPropertyValues(TheStructureOfTheSearch, RightsTableRowByRoleReference);
		
		RowsOfRoleRightsTable = ResultTable1.FindRows(TheStructureOfTheSearch);
		
		If RowsOfRoleRightsTable.Count() = 0 Then
			NewRow = ResultTable1.Add();
			NewRow.Object               = RightsTableRowByRoleReference.Object;
			NewRow.Right                = RightsTableRowByRoleReference.Right;
			NewRow.StandardVal      = RightsTableRowByRoleReference.Value;
			NewRow.UsedInRole    = False;
			NewRow.UsedInReference = True;
			
			Continue;
		EndIf;
		
		For Each RightsTableRowByRole In RowsOfRoleRightsTable Do
			RightsTableRowByRole.StandardVal      = RightsTableRowByRoleReference.Value;
			RightsTableRowByRole.UsedInReference = True;
		EndDo;
	EndDo;
	
	// Delete rows whose key-value pairs match in both the configuration and the reference element.
	RowsForDeletion = New Array;
	For Each TableRow In ResultTable1 Do
		If TableRow.UsedInRole And TableRow.UsedInReference
				And (TableRow.Value = TableRow.StandardVal) Then
			RowsForDeletion.Add(TableRow);
		EndIf;
	EndDo;
	
	For Each RowForDeletion In RowsForDeletion Do
		ResultTable1.Delete(RowForDeletion);
	EndDo;
	
	ResultingMap = New Map;
	
	// Generate the "Result" map, where a key is an object and a value is a table with the applied filter by object.
	For Each TableRow In ResultTable1 Do
		If ResultingMap[TableRow.Object] <> Undefined Then
			Continue;
		EndIf;
		
		ObjectRightsTable = ResultTable1.Copy(New Structure("Object", TableRow.Object));
		
		ResultingMap.Insert(TableRow.Object, ObjectRightsTable);
	EndDo;
	
	Return ResultingMap;
	
EndFunction

Function InternetActivitiesMethods()
	
	MethodsTable = New ValueTable;
	MethodsTable.Columns.Add("Method");
	MethodsTable.Columns.Add("MethodPresentation");
	MethodsTable.Columns.Add("ProxyParameterNumber");
	
	TableRow = MethodsTable.Add();
	TableRow.Method = Upper("NewHTTPConnection(");
	TableRow.MethodPresentation = "New HTTPConnection";
	TableRow.ProxyParameterNumber = 5;
	
	TableRow = MethodsTable.Add();
	TableRow.Method = Upper("NewFTPConnection(");
	TableRow.MethodPresentation = "New FTPConnection";
	TableRow.ProxyParameterNumber = 5;
	
	TableRow = MethodsTable.Add();
	TableRow.Method = Upper("NewWSProxy(");
	TableRow.MethodPresentation = "New WSProxy";
	TableRow.ProxyParameterNumber = 5;
	
	TableRow = MethodsTable.Add();
	TableRow.Method = Upper("NewWSDefinitions(");
	TableRow.MethodPresentation = "New WSDefinitions";
	TableRow.ProxyParameterNumber = 4;
	
	TableRow = MethodsTable.Add();
	TableRow.Method = Upper("NewHTTPConnection(");
	TableRow.MethodPresentation = "New HTTPConnection";
	TableRow.ProxyParameterNumber = 5;
	
	TableRow = MethodsTable.Add();
	TableRow.Method = Upper("NewFTPConnection(");
	TableRow.MethodPresentation = "New FTPConnection";
	TableRow.ProxyParameterNumber = 5;
	
	TableRow = MethodsTable.Add();
	TableRow.Method = Upper("NewWSProxy(");
	TableRow.MethodPresentation = "New WSProxy";
	TableRow.ProxyParameterNumber = 5;
	
	TableRow = MethodsTable.Add();
	TableRow.Method = Upper("NewWSDefinitions(");
	TableRow.MethodPresentation = "New WSDefinitions";
	TableRow.ProxyParameterNumber = 4;
	
	MethodsTable.Indexes.Add("Method");
	Return MethodsTable;
	
EndFunction

Function ProxyUsageErrorParameters()
	
	Result = New Structure;
	
	Result.Insert("FullFileName");
	Result.Insert("ProxyCheckMetadataObject");
	Result.Insert("TextDocument");
	Result.Insert("CallLineNum");
	Result.Insert("CallLinesCount");
	Result.Insert("MethodPresentation");
	
	Return Result;
	
EndFunction

Procedure CheckProxyUsage()
	
	ProxyUsageErrorParameters = ProxyUsageErrorParameters();
	
	// Exclude the common modules named "GetFilesFromInternet..." and this report from the check scope.
	CheckExceptions = New Array;
	CheckExceptions.Add("GetFilesFromInternet");
	CheckExceptions.Add("GetFilesFromInternet");
	CheckExceptions.Add("SSLImplementationCheck");
	CheckExceptions.Add("SSLImplementationCheck");
	
	ModuleFiles = FindFiles(DumpDirectory, "*.bsl", True);
	For Each ModuleFile In ModuleFiles Do
		
		FullFileName = ModuleFile.FullName;
		
		MetadataObjectProperties = ObjectPropertiesByFileName(FullFileName);
		ProxyCheckMetadataObject = MetadataObjectProperties.MetadataObject;
		If ProxyCheckMetadataObject = Undefined Then
			Continue;
		EndIf;
		
		NameOfMetadataObjectToCheck = ProxyCheckMetadataObject.Name;
		IsCheckException = StrStartsWithByArray(NameOfMetadataObjectToCheck, CheckExceptions);
		If IsCheckException.Success Then
			Continue;
		EndIf;
		
		ProxyUsageErrorParameters.ProxyCheckMetadataObject = ProxyCheckMetadataObject;
		ProxyUsageErrorParameters.FullFileName = FullFileName;
		
		CheckProxyUsageInFile(ProxyUsageErrorParameters);
		
	EndDo;
	
EndProcedure

Procedure CheckProxyUsageInFile(ProxyUsageErrorParameters)
	
	TextDocument = New TextDocument;
	TextDocument.Read(ProxyUsageErrorParameters.FullFileName);
	SourceModuleText = TextDocument.GetText();
	
	If IsBlankString(SourceModuleText) Then
		Return;
	EndIf;
	
	TableOfMethodsWithProxyParameter = InternetActivitiesMethods();
	ArrayOfMethodsWithProxyParameter = TableOfMethodsWithProxyParameter.UnloadColumn("Method");
	
	ArrayWordFile = New Array;
	ArrayWordFile.Add(Upper("file"));
	ArrayWordFile.Add(Upper("file"));
	
	ArrayConstructorWSDefinitions = New Array;
	ArrayConstructorWSDefinitions.Add(Upper("NewWSDefinitions("));
	ArrayConstructorWSDefinitions.Add(Upper("NewWSDefinitions("));
	
	ProxyUsageErrorParameters.TextDocument = TextDocument;
	
	ModuleText = StrReplace(SourceModuleText, " ", "");
	ModuleText = StrReplace(ModuleText, Chars.Tab, "");
	ModuleText = Upper(ModuleText);
	
	MethodPosition = 0;
	While True Do
		
		If CanUseRegEx() Then
			SearchExpression = StrConcat(ArrayOfMethodsWithProxyParameter, "|");
			SearchExpression = StrReplace(SearchExpression, "(", "\(");
			
			SearchResult = EvalStrFindByRegularExpression(ModuleText, SearchExpression, MethodPosition + 1);
			If SearchResult = Undefined Then
				Break;
			EndIf;
			
			MethodPosition = SearchResult.StartIndex;
			If MethodPosition = 0 Then
				Break;
			EndIf;
			
			FoundMethod = SearchResult.Value;
		Else
			MethodSearchResult = StrFindByArray(ModuleText, ArrayOfMethodsWithProxyParameter,, MethodPosition + 1);
			If Not MethodSearchResult.Success Then
				Break;
			EndIf;
			
			FoundMethod = MethodSearchResult.FoundItem;
			MethodPosition = MethodSearchResult.Position;
		EndIf;
		
		MethodsTableRow = TableOfMethodsWithProxyParameter.Find(FoundMethod, "Method");
		If MethodsTableRow = Undefined Then
			Continue;
		EndIf;
		
		MethodParameters = MethodParameters(ModuleText, FoundMethod, MethodPosition);
		If Not MethodParameters.IsMethodFound Then
			Continue;
		EndIf;
		
		ModuleTextBeforeMethod = Left(ModuleText, MethodPosition - 1);
		LastLineModuleTextBeforeMethod = ModuleLastLine(ModuleTextBeforeMethod);
		CommentPosition = StrFind(LastLineModuleTextBeforeMethod, "//");
		
		// If the constructor was found in a comment, skip it.
		If CommentPosition > 0 Then
			Continue;
		EndIf;
		
		ArrayOfMethodParameters = MethodParameters.ParametersArray;
		
		// Check that a filename is assigned to the "WSDLLocation" parameter of the "NewWSDefinitions" constructor.
		If ArrayConstructorWSDefinitions.Find(FoundMethod) <> Undefined Then
			If ArrayOfMethodParameters.Count() > 0 Then
				MethodFirstParameter = ArrayOfMethodParameters[0];
				If StrFindByArray(MethodFirstParameter, ArrayWordFile).Success Then
					Continue;
				EndIf;
			EndIf;
		EndIf;
		
		ProxyUsageErrorParameters.MethodPresentation   = MethodsTableRow.MethodPresentation;
		ProxyUsageErrorParameters.CallLineNum     = MethodParameters.LineNumber;
		ProxyUsageErrorParameters.CallLinesCount = StrLineCount(MethodParameters.CallText);
		
		ProxyParameterNumber = MethodsTableRow.ProxyParameterNumber;
		
		// If the number of parameters is less than the index of the "Proxy" parameter, raise an error.
		If ArrayOfMethodParameters.Count() < ProxyParameterNumber Then
			RegisterProxyUsageError(ProxyUsageErrorParameters);
			Continue;
		EndIf;
		
		ProxyParameter = ArrayOfMethodParameters[ProxyParameterNumber - 1];
		
		// If the "Proxy" parameter is empty, raise an error.
		If IsBlankString(ProxyParameter) Then
			RegisterProxyUsageError(ProxyUsageErrorParameters);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure RegisterProxyUsageError(ProxyUsageErrorParameters)
	
	TextDocument = ProxyUsageErrorParameters.TextDocument;
	
	// Provide error with a 5-line snippet of the erroneous code.
	FirstRowNumber = ProxyUsageErrorParameters.CallLineNum;
	MethodLinesCount = ProxyUsageErrorParameters.CallLinesCount;
	LastRowNumber = Min(FirstRowNumber + MethodLinesCount - 1, FirstRowNumber + 5);
	
	FullMethodLine = "";
	For LineNumber = FirstRowNumber To LastRowNumber Do
		ModuleString = TextDocument.GetLine(LineNumber);
		FullMethodLine = FullMethodLine + ModuleString + Chars.LF;
	EndDo;
	
	TemplateOfFullErrorDetails = NStr(
		"ru = 'Для конструктора ""%1"" не указан параметр ""%2"" - результат функции ""%3"":
		|
		|%4
		|
		|Модуль, стр. %5';
		|en = 'The ""%2"" parameter (result of the ""%3"" function) is not specified for the ""%1"" constructor:
		|
		|%4
		|
		|Module, line %5';");
	
	MethodPresentation = ProxyUsageErrorParameters.MethodPresentation;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(TemplateOfFullErrorDetails,
		MethodPresentation, "Proxy", "GetFilesFromInternet.GetProxy", TrimAll(FullMethodLine),
		Format(FirstRowNumber, "NG="));
	
	AddError(ProxyUsageErrorParameters.ProxyCheckMetadataObject,
		NStr("ru = 'Не указан системный прокси';
			|en = 'System proxy server is not specified.';"),
		ErrorText);
	
EndProcedure

#EndRegion

#Region ReportsOptions

Procedure ReportOptions_CheckConnectionToReportForms(CheckParameters, RowReport)
	If Not RowReport.DCSSettingsFormat Then
		Return;
	EndIf;
	If RowReport.Metadata.Name = "UniversalReport" Then
		Return;
	EndIf;
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	
	ConnectedToMainForm = ModuleReportsOptions.ReportAttachedToMainForm(RowReport.Metadata, CheckParameters.MainFormFlag);
	ConnectedToSettingsForm = ModuleReportsOptions.ReportAttachedToSettingsForm(RowReport.Metadata, CheckParameters.SettingsFormCheckbox);
	If ConnectedToMainForm <> ConnectedToSettingsForm Then
		If ConnectedToMainForm Then
			ErrorText = NStr("ru = 'Отчет подключен к общей форме отчета, но не подключен к общей форме настроек.
				|Рекомендуется использовать общую форму ""Вспомогательная форма настроек отчета""';
				|en = 'The report is attached to the common report form but not attached to the common settings form.
				|We recommend that you use the ""Report settings auxiliary form"" common form';");
		Else
			ErrorText = NStr("ru = 'Отчет не подключен к общей форме отчета, но подключен к общей форме настроек.';
								|en = 'Report is not attached to common report form but attached to common settings form.';");
		EndIf;
		
		ErrorText = ErrorText + Chars.LF
			+ NStr("ru = 'см. свойства объекта отчета ""Основная форма"" и ""Основная форма настроек"",
			|а также свойства конфигурации ""Основная форма отчета"" и ""Основная форма настроек отчета"".
			|Подробнее см. в документации по внедрению подсистемы.';
			|en = 'see report object properties ""Default form"" and ""Default settings form"",
			|and configuration properties ""Default report form"" and ""Default report settings form"".
			|For more information, see the subsystem deployment documentation.';");
		
		AddError(RowReport.Metadata, NStr("ru = 'Отчет не подключен к общим формам';
													|en = 'Report is not attached to common forms.';"), ErrorText);
	EndIf;
EndProcedure

Procedure ReportOptions_CheckConnectionToOptionsStore(CheckParameters, RowReport)
	If Not RowReport.DCSSettingsFormat Then
		Return;
	EndIf;
	If CheckParameters.ReportsExcludedFromCheckStorageVariant.Find(RowReport.Metadata.Name) <> Undefined Then
		Return;
	EndIf;
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	
	ConnectedToStorage = ModuleReportsOptions.ReportAttachedToStorage(RowReport.Metadata, CheckParameters.OptionStorageCheckbox);
	If ConnectedToStorage Then 
		Return;
	EndIf;
	
	ErrorText = NStr("ru = 'Отчет не подключен к хранилищу вариантов.
		|Подробнее см. в документации по внедрению подсистемы.';
		|en = 'Report is not attached to the option storage.
		|For more information, see documentation on subsystem deployment.';");
	AddError(RowReport.Metadata, NStr("ru = 'Отчет не подключен к хранилищу вариантов';
												|en = 'Report is not attached to the option storage';"), ErrorText);
EndProcedure

Procedure ReportOptions_CheckOutdatedPropertiesUse(RowReport, ReportObject)
	If Not RowReport.DefineFormSettings Then
		Return;
	EndIf;
	ReportSettings = Common.CommonModule("ReportsClientServer").DefaultReportSettings();
	Try
		ReportObject.DefineFormSettings(Undefined, Undefined, ReportSettings);
	Except
		ErrorText = NStr("ru = 'Модуль объекта отчета, процедура ""%1"":
			|  Ошибка при вызове события с параметрами (Неопределено, Неопределено, %2):
			|    %3
			|  По возможности следует отказаться от использования параметров ""%4"" и ""%5"",
			|  поскольку в них может быть передано значение Неопределено.
			|  Типы параметров этой процедуры см. в шаблоне этой процедуры,
			|  который описан в комментарии к %6.';
			|en = 'Report object module, procedure ""%1"":
			| An error occurred when calling an event with parameters (Undefined, Undefined, %2):
			|    %3
			| If possible, do not use parameters ""%4"" and ""%5""
			| because they can pass the Undefined value.
			| See parameter types of this procedure in its template
			| that is described in the comment to %6.';");
		More = StrReplace(ErrorProcessing.DetailErrorDescription(ErrorInfo()), Chars.LF, Chars.LF + "    ");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
			"DefineFormSettings", "ReportSettings", More, "Form", "VariantKey", "ReportsOptionsOverridable.CustomizeReportsOptions()");
		AddError(RowReport.Metadata, 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Используются необязательные параметры события %1';
					|en = 'Optional parameters of event %1 are used';"),
				"DefineFormSettings"),
			ErrorText);
		Return;
	EndTry;
	
	ModuleText = ModuleText(RowReport.Metadata, "ObjectModule");
	ProcedureText = ProcedureText("DefineFormSettings", ModuleText);
	
	If Not IsBlankString(ProcedureText) Then
		Names = "";
		If StrFind(ProcedureText, "DefaultPrintOptions") > 0 Then
			Names = ?(Names = "", "", Names + ", ") + "DefaultPrintOptions";
		EndIf;
		If StrFind(ProcedureText, "ParametersFrequencyMap") > 0 Then
			Names = ?(Names = "", "", Names + ", ") + "ParametersFrequencyMap";
		EndIf;
		If Names <> "" Then
			ErrorText = NStr("ru = 'Модуль объекта отчета, процедура ""%1"":
				|  Встречаются обращения к устаревшим параметрам ""%2"".
				|  Актуальный состав параметров см. в %3.';
				|en = 'Report object module, procedure ""%1"":
				| There are appeals to obsolete parameters ""%2"".
				| See relevant parameters in %3.';");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
				"DefineFormSettings", Names, "ReportsClientServer.DefaultReportSettings()");
			AddError(
				RowReport.Metadata,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Используются устаревшие настройки в %1';
						|en = 'Obsolete settings are used in %1';"),
					"DefineFormSettings"),
				ErrorText);
		EndIf;
	EndIf;
	
	If ReportSettings.Events.OnDefineSelectionParameters Then
		ProcedureText = ProcedureText("OnDefineSelectionParameters", ModuleText);
		
		If Not IsBlankString(ProcedureText) Then
			If StrFind(ProcedureText, "Form.") > 0 Then
				ErrorText = NStr("ru = 'Модуль объекта отчета, процедура ""%1"":
					|  Встречаются обращения к параметру ""Форма"".
					|  По возможности следует отказаться от использования этого параметра,
					|  поскольку в нем может быть передано значение Неопределено.
					|  Типы параметров этой процедуры см. в шаблоне этой процедуры,
					|  который описан в комментарии к %2.';
					|en = 'Report object module, procedure ""%1"":
					| There are appeals to the ""Form"" parameter.
					| If possible, do not use this parameter
					| because it can pass the Undefined value.
					| See parameter types of this procedure in its template
					| that is described in the comment to %2.';");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
					"OnDefineSelectionParameters", "ReportsClientServer.DefaultReportSettings()");
				AddError(
					RowReport.Metadata,
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Используются устаревшие настройки в %1';
							|en = 'Obsolete settings are used in %1';"),
						"DefineFormSettings"),
					ErrorText);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

Procedure ReportOptions_CheckSettingsForSearch(PredefinedReportsOptions, ReportVariant)
	If Not ReportVariant.Enabled
		Or ReportVariant.Location.Count() = 0 Then
		Return;
	EndIf;
	
	ReportInfo = PredefinedReportsOptions.FindRows(
		New Structure("Report, IsOption", ReportVariant.Report, False))[0];
	NeedToFillSearchSettings = False;
	If Not ReportInfo.UsesDCS
		And Not ValueIsFilled(ReportVariant.SearchSettings.FieldDescriptions)
		And Not ValueIsFilled(ReportVariant.SearchSettings.FilterParameterDescriptions)
		And Not ValueIsFilled(ReportVariant.SearchSettings.Keywords) Then
		NeedToFillSearchSettings = True;
	EndIf;
	If Not NeedToFillSearchSettings Then
		Return;
	EndIf;
	
	If ValueIsFilled(ReportVariant.VariantKey) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Вариант ""%1"":';
																					|en = 'Option %1:';"), 
			ReportVariant.VariantKey);
	Else
		ErrorText = "";
	EndIf;
	If NeedToFillSearchSettings Then
		ErrorText = ?(ErrorText = "", "", ErrorText + Chars.LF)
			+ "- " + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не заполнены поля ""%1"", ""%2"" и ""%3"".';
					|en = 'Fields ""%1"", ""%2"", and ""%3"" are required.';"),
				"FieldDescriptions", "FilterParameterDescriptions", "Keywords");
	EndIf;
	ErrorText = ?(ErrorText = "", "", ErrorText + Chars.LF)
		+ StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Подробнее - см. %1.';
																		|en = 'For more information, see %1.';"),
			"ReportsOptionsOverridable.CustomizeReportsOptions()");
	AddError(ReportInfo.Metadata, NStr("ru = 'Не заполнены описания вариантов отчетов';
													|en = 'Report option details are blank';"), ErrorText);
EndProcedure

Procedure ReportOptions_CheckCommonCommand(SharedCommandMetadata)
	CommandModuleText = ModuleText(SharedCommandMetadata, "CommandModule");
	If Not ValueIsFilled(CommandModuleText) Then
		Return;
	EndIf;
	Call = FindMethodCall(CommandModuleText, "ReportsOptionsClient.ShowReportBar(");
	If Call <> Undefined Then
		If Call.Parameters.Count() > 2 Then
			Brief1 = NStr("ru = 'Использование удаленного параметра Заголовок';
							|en = 'Using the deleted Title parameter';");
			More = NStr("ru = 'Заголовок панелей отчетов следует описывать в процедуре %1 модуля %2 (переход на БСП 2.2.2).';
							|en = 'Describe report panel title in procedure %1 of module %2 (migration to SSL 2.2.2).';");
			More = StringFunctionsClientServer.SubstituteParametersToString(More, "DefineSectionsWithReportOptions", "ReportsOptionsOverridable");
			AddError(SharedCommandMetadata, Brief1, More);
		EndIf;
	EndIf;
EndProcedure

Function FileExists(FullFileName)
	File = New File(FullFileName);
	Return File.Exists();
EndFunction

Procedure RegisterNestedSubsystems(ParentMetadata, SubsystemsArray)
	For Each MetadataSubsystems In ParentMetadata.Subsystems Do
		If SubsystemsArray.Find(MetadataSubsystems) = Undefined Then
			SubsystemsArray.Add(MetadataSubsystems);
			RegisterNestedSubsystems(MetadataSubsystems, SubsystemsArray);
		EndIf;
	EndDo;
EndProcedure

Function ReportsExcludedFromConnectionCheckToStorage()
	Exceptions = New Array;
	
	Exceptions.Add("UniversalReport");
	Exceptions.Add("ApplicationSizeHistory");
	
	Return Exceptions;
EndFunction

#EndRegion

#Region PeriodClosingDates

Procedure CheckChangeBanField(DataSource, MetadataObject, FieldName)
	
	Simple = DataSource[FieldName];
	NameArray = StrSplit(Simple, ".");
	AttributeName = NameArray[0];
	If MetadataObject.Attributes.Find(AttributeName) <> Undefined Then
		Return;
	EndIf;
	
	For Each StandardAttribute In MetadataObject.StandardAttributes Do // StandardAttributeDescription
		If StandardAttribute.Name = AttributeName Then
			Return;
		EndIf;
	EndDo;
	
	// For registers. Also check Dimensions and Resources.
	If Common.IsRegister(MetadataObject) Then
		If MetadataObject.Dimensions.Find(AttributeName) <> Undefined Then
			Return;
		EndIf;
		If MetadataObject.Resources.Find(AttributeName) <> Undefined Then
			Return;
		EndIf;
	EndIf;
	
	TabularSectionMetadata = TabularSectionMetadata(MetadataObject, AttributeName);
	If TabularSectionMetadata <> Undefined
		And TabularSectionMetadata.Attributes.Find(NameArray[1]) <> Undefined Then
		Return;
	EndIf;
	
	AddError(Metadata.CommonModules.PeriodClosingDatesOverridable,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Некорректно заполнена процедура %1';
				|en = 'Procedure %1 is filled in incorrectly';"), "FillDataSourcesForPeriodClosingCheck"),
		StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В процедуре %1
			|для объекта ""%2"" в качестве значения поля ""%3"" указано значение ""%4"".
			|Указанная таблица не содержит такого реквизита или табличной части.';
			|en = 'In procedure %1
			|, object ""%2"" has ""%4"" as value of field ""%3"".
			|The specified table does not contain such an attribute or tabular section.';"),
			"PeriodClosingDatesOverridable.FillDataSourcesForPeriodClosingCheck",
			DataSource.Table, FieldName, Simple));
	
EndProcedure

Function TabularSectionMetadata(MetadataObject, TabularSectionName)
	
	If Metadata.Catalogs.Contains(MetadataObject)
		Or Metadata.Documents.Contains(MetadataObject)
		Or Metadata.BusinessProcesses.Contains(MetadataObject)
		Or Metadata.Tasks.Contains(MetadataObject)
		Or Metadata.ChartsOfCalculationTypes.Contains(MetadataObject)
		Or Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject)
		Or Metadata.ExchangePlans.Contains(MetadataObject)
		Or Metadata.ChartsOfAccounts.Contains(MetadataObject)
		Or Metadata.DataProcessors.Contains(MetadataObject)
		Or Metadata.Reports.Contains(MetadataObject) Then
		
		Return MetadataObject.TabularSections.Find(TabularSectionName);
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region AdditionalReportsAndDataProcessors

Procedure CheckGlobalProcessingReportsEmbedding(ForReports)
	
	If ForReports Then
		SectionsArray = Common.CommonModule("AdditionalReportsAndDataProcessors").AdditionalReportSections();
		TextTemplate1 = NStr("ru = 'Отсутствует команда вызова дополнительных отчетов из раздела %1';
							|en = 'Missing command to run additional reports from the %1 section';");
		BriefErrorDetails = NStr("ru = 'Отсутствует команда открытия дополнительных отчетов';
									|en = 'Missing command to open additional reports';");
	Else
		SectionsArray = Common.CommonModule("AdditionalReportsAndDataProcessors").AdditionalDataProcessorSections();
		TextTemplate1 = NStr("ru = 'Отсутствует команда вызова дополнительных обработок из раздела %1';
							|en = 'Missing command to run additional data processors from the %1 section';");
		BriefErrorDetails = NStr("ru = 'Отсутствует команда открытия дополнительных обработок';
									|en = 'Missing command to open additional data processors';");
	EndIf;
	
	StartPageName = Common.CommonModule("AdditionalReportsAndDataProcessorsClientServer").StartPageName();
	
	CallString = "AdditionalReportsAndDataProcessorsClient.OpenAdditionalReportAndDataProcessorCommandsForm";
	
	For Each SectionOfMetadata In SectionsArray Do
		// Don't check desktop content.
		If SectionOfMetadata = StartPageName Then
			Continue;
		EndIf;
		// Place the command in one of the "Administration" section panels.
		If SectionOfMetadata.Name = "Administration" Then
			Continue;
		EndIf;
		
		CallFound = False;
		For Each CommonCommand In SectionOfMetadata.Content Do
			If Not Metadata.CommonCommands.Contains(CommonCommand) Then
				Continue;
			EndIf;
			ModuleText = ModuleText(CommonCommand, "CommandModule");
			If StrFind(ModuleText, CallString) > 0 Then
				CallFound = True;
				Break;
			EndIf;
		EndDo;
		
		If Not CallFound Then
			// Continue search in nested sections.
			For Each SubordinateSection In SectionOfMetadata.Subsystems Do
				For Each CommonCommand In SubordinateSection.Content Do
					If Not Metadata.CommonCommands.Contains(CommonCommand) Then
						Continue;
					EndIf;
					ModuleText = ModuleText(CommonCommand, "CommandModule");
					If StrFind(ModuleText, CallString) > 0 Then
						CallFound = True;
						Break;
					EndIf;
				EndDo;
			EndDo;
		EndIf;
		
		If Not CallFound Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, SectionOfMetadata.Name);
			AddError(Metadata.CommonModules.AdditionalReportsAndDataProcessorsOverridable, BriefErrorDetails, ErrorText);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region ContactInformation

Procedure ContactInformation_CheckAdditionalCodeInserts(Val ObjectsOwners)
	
	CheckParameters = CheckingCodeInsertionParameters();
	CheckParameters.DataToCheck1 = ObjectsOwners;
	CheckParameters.ModuleType         = "DefaultObjectForm";
	
	CheckParameters.CodeString             = "ContactsManagerClient.StartChanging";
	CheckParameters.NameOfAProcedureOrAFunction = "Attachable_ContactInformationOnChange";
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.CodeString             = "ContactsManagerClient.StartSelection";
	CheckParameters.NameOfAProcedureOrAFunction = "Attachable_ContactInformationStartChoice";
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.CodeString             = "ContactsManagerClient.StartSelection";
	CheckParameters.NameOfAProcedureOrAFunction = "Attachable_ContactInformationOnClick";
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.CodeString             = "ContactsManagerClient.StartClearing";
	CheckParameters.NameOfAProcedureOrAFunction = "Attachable_ContactInformationClearing";
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.CodeString             = "ContactsManagerClient.StartCommandExecution";
	CheckParameters.NameOfAProcedureOrAFunction = "Attachable_ContactInformationExecuteCommand";
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.CodeString             = "UpdateContactInformation";
	CheckParameters.NameOfAProcedureOrAFunction = "Attachable_ContinueContactInformationUpdate";
	CheckParameters.IsExportProcedure = True;
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.CodeString             = "ContactsManager.UpdateContactInformation";
	CheckParameters.NameOfAProcedureOrAFunction = "UpdateContactInformation";
	CheckParameters.IsExportProcedure = False;
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.CodeString             = "ContactsManagerClient.AutoCompleteAddress";
	CheckParameters.NameOfAProcedureOrAFunction = "Attachable_ContactInformationAutoComplete";
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.CodeString             = "ContactsManagerClient.ChoiceProcessing";
	CheckParameters.NameOfAProcedureOrAFunction = "Attachable_ContactInformationChoiceProcessing";
	CheckForCodeInsertion(CheckParameters);

	CheckParameters.CodeString             = "ContactsManagerClient.StartURLProcessing";
	CheckParameters.NameOfAProcedureOrAFunction = "Attachable_ContactInformationURLProcessing";
	CheckParameters.AbsenceOfProcedureIsError = False;
	CheckForCodeInsertion(CheckParameters);
	
EndProcedure

Procedure ContactInformation_CheckAdditionalCodeInsertsOutdated(Val ObjectsOwners)
	
	CheckParameters = CheckingCodeInsertionParameters();
	CheckParameters.DataToCheck1 = ObjectsOwners;
	CheckParameters.ModuleType         = "DefaultObjectForm";
	
	CheckedCalls = New Array;
	CheckedCalls.Add(CallOptions("ContactsManagerClient.PresentationOnChange", "ContactsManagerClient.OnChange"));
	
	CheckParameters.CodeString             = CheckedCalls;
	CheckParameters.NameOfAProcedureOrAFunction = "Attachable_ContactInformationOnChange";
	CheckForCodeInsertion(CheckParameters);
	
	CheckedCalls = New Array;
	CheckedCalls.Add(CallOptions("ContactsManagerClient.PresentationStartChoice", "ContactsManagerClient.StartChoice"));
	
	CheckParameters.CodeString             = CheckedCalls;
	CheckParameters.NameOfAProcedureOrAFunction = "Attachable_ContactInformationStartChoice";
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.CodeString             = "ContactsManagerClient.StartChoice";
	CheckParameters.NameOfAProcedureOrAFunction = "Attachable_ContactInformationOnClick";
	CheckForCodeInsertion(CheckParameters);
	
	CheckedCalls = New Array;
	CheckedCalls.Add(CallOptions("ContactsManagerClient.ClearingPresentation", "ContactsManagerClient.Clearing"));
	
	CheckParameters.CodeString             = CheckedCalls;
	CheckParameters.NameOfAProcedureOrAFunction = "Attachable_ContactInformationClearing";
	CheckForCodeInsertion(CheckParameters);
	
	CheckedCalls = New Array;
	CheckedCalls.Add(CallOptions("ContactsManagerClient.AttachableCommand", "ContactsManagerClient.ExecuteCommand"));
	
	CheckParameters.CodeString             = CheckedCalls;
	CheckParameters.NameOfAProcedureOrAFunction = "Attachable_ContactInformationExecuteCommand";
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.CodeString             = "ContactsManager.UpdateContactInformation";
	CheckParameters.NameOfAProcedureOrAFunction = "Attachable_UpdateContactInformation";
	CheckParameters.IsExportProcedure = True;
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.CodeString             = "ContactsManagerClient.AutoCompleteAddress";
	CheckParameters.NameOfAProcedureOrAFunction = "Attachable_ContactInformationAutoComplete";
	CheckParameters.IsExportProcedure = False;
	CheckForCodeInsertion(CheckParameters);
	
	CheckParameters.CodeString             = "ContactsManagerClient.ChoiceProcessing";
	CheckParameters.NameOfAProcedureOrAFunction = "Attachable_ContactInformationChoiceProcessing";
	CheckForCodeInsertion(CheckParameters);

EndProcedure

Function AddViewToViewTable(PredefinedView, PredefinedItemName, TableOfSpecies)
	
	Result = New Structure;
	Result.Insert("ErrorText",     "");
	Result.Insert("ErrorTitle", "");
	
	If ValueIsFilled(PredefinedView.Parent) Then
		PredefinedParentName = ?(ValueIsFilled(PredefinedView.ParentPredefinedDataName),
			PredefinedView.ParentPredefinedDataName,PredefinedView.ParentPredefinedKindName);
		
		FoundRow = TableOfSpecies.Find(PredefinedParentName, "PredefinedView");
		If FoundRow = Undefined Then
			NewRow = TableOfSpecies.Add();
			NewRow.PredefinedView = PredefinedParentName;
			NewRow.HasTabularParts  = True;
		Else
			FoundRow.HasTabularParts = True;
		EndIf;
		
		Return Result;
	EndIf;
	
	IsCatalog = StrStartsWith(PredefinedItemName, "Catalog");
	IsDocument   = StrStartsWith(PredefinedItemName, "Document");
	If Not IsCatalog And Not IsDocument Then
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Имя предопределенного вида контактной информации должно начинаться
			|с ""Справочник"" или ""Документ"". Текущее имя ""%1""';
			|en = 'The names of a predefined contact information kind must start
			|with either Catalog or Document. Current name: %1';"), PredefinedItemName);
		Result.ErrorTitle = NStr("ru = 'Некорректное имя предопределенного вида контактной информации';
										|en = 'Invalid name of predefined contact information kind';");
		Return Result;
	EndIf;
	
	If IsCatalog Then
		OwnerName = Mid(PredefinedItemName, StrLen("Catalog") + 1);
		MetadataCollection = Metadata.Catalogs;
	Else
		OwnerName = Mid(PredefinedItemName, StrLen("Document") + 1);
		MetadataCollection = Metadata.Documents;
	EndIf;
	
	OwnerMetadata = MetadataCollection.Find(OwnerName);
	
	If OwnerMetadata = Undefined Then
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для предопределенного вида контактной информации %1 отсутствует объект метаданных %2';
				|en = 'Metadata object ""%2"" is missing for predefined contact information kind ""%1""';"),
			PredefinedItemName, OwnerName);
		Result.ErrorTitle = NStr("ru = 'Отсутствует объект метаданных';
										|en = 'Metadata object is missing';");
		Return Result;
	EndIf;
	
	FoundRow = TableOfSpecies.Find(PredefinedItemName, "PredefinedView");
	If FoundRow = Undefined Then
		NewRow = TableOfSpecies.Add();
		NewRow.PredefinedView = PredefinedItemName;
		NewRow.OwnerMetadata = OwnerMetadata;
		NewRow.HasTabularParts  = False;
	Else
		FoundRow.OwnerMetadata = OwnerMetadata;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region ItemOrderSetup

Function ObjectsWithAdditionalOrderingDetailsComposition()
	
	MetadataArray = New Array;
	For Each MetadataObject In Metadata.Catalogs Do
		If MetadataObject.Attributes.Find("AddlOrderingAttribute") <> Undefined Then
			MetadataArray.Add(MetadataObject);
		EndIf;
	EndDo;
	
	For Each MetadataObject In Metadata.ChartsOfCharacteristicTypes Do
		If MetadataObject.Attributes.Find("AddlOrderingAttribute") <> Undefined Then
			MetadataArray.Add(MetadataObject);
		EndIf;
	EndDo;
	
	For Each MetadataObject In Metadata.ChartsOfCalculationTypes Do
		If MetadataObject.Attributes.Find("AddlOrderingAttribute") <> Undefined Then
			MetadataArray.Add(MetadataObject);
		EndIf;
	EndDo;
	
	Return TypeComposition(
		StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Объекты с реквизитом %1';
																	|en = 'Objects with attribute %1';"), "AddlOrderingAttribute"),
		MetadataArray);
	
EndFunction

#EndRegion

#Region ODataInterface

Procedure FixDataRoleComposition(RoleFileName, ReferenceComposition)
	
	RightsTypesSynonyms       = RightsTypesSynonyms();
	MetadataViews = MetadataObjectsRepresentations();
	
	DOMDocument               = DOMDocument(RoleFileName);
	ResultComposition           = EvaluateXPathExpression(XPathExpressionRoleComposition(), DOMDocument);
	CompositionItem            = ResultComposition.IterateNext();
	CollectionResult        = EvaluateXPathExpression(XPathExpressionRoleDescription(), DOMDocument);
	CollectionCompositionElements = CollectionResult.IterateNext();
	
	While CompositionItem <> Undefined Do
		CollectionCompositionElements.RemoveChild(CompositionItem);
		CompositionItem = ResultComposition.IterateNext();
	EndDo;
	
	For Each MetadataObject In ReferenceComposition Do
		
		ObjectName = ?(TypeOf(MetadataObject.Key) = Type("String"),
			MetadataObject.Key, MetadataObject.Key.FullName());
		
		Separator       = StrFind(ObjectName, ".");
		ObjectTypeString = Left(ObjectName, Separator - 1);
		If Not MetadataViews.Property(ObjectTypeString) Then
			Continue;
		EndIf;
		
		ObjectPresentation = StrReplace(ObjectName, ObjectTypeString + ".", MetadataViews[ObjectTypeString] + ".");
		NodeRoleObject  = CollectionCompositionElements.AppendChild(DOMDocument.CreateElement(RoleObjectProperty()));
		
		AddDOMNodeProperty(DOMDocument, NodeRoleObject, RoleObjectNameProperty(), ObjectPresentation);
		
		For Each RightToObject In MetadataObject.Value Do
			NodeRight = NodeRoleObject.AppendChild(DOMDocument.CreateElement(RoleObjectRightProperty()));
			AddDOMNodeProperty(DOMDocument, NodeRight, RightsNameProperty(), RightsTypesSynonyms.Get(RightToObject));
			AddDOMNodeProperty(DOMDocument, NodeRight, RightValueProperty(), "true");
		EndDo;
	EndDo;
	
	WriteDOMDocument(DOMDocument, RoleFileName);
	
EndProcedure

Function RightsTypesSynonyms()
	
	Result = New Map();
	
	Result.Insert("Read", "Read");
	Result.Insert("Create", "Insert");
	Result.Insert("Update", "Update");
	Result.Insert("Delete", "Delete");
	Result.Insert("Posting", "Posting");
	Result.Insert("UndoPosting", "UndoPosting");
	Result.Insert("View", "View");
	Result.Insert("InteractiveInsert", "InteractiveInsert");
	Result.Insert("Edit", "Edit");
	Result.Insert("InteractiveDeletionMark", "InteractiveSetDeletionMark");
	Result.Insert("InteractiveClearDeletionMark", "InteractiveClearDeletionMark");
	Result.Insert("InteractiveDeleteMarked", "InteractiveDeleteMarked");
	Result.Insert("InteractivePosting", "InteractivePosting");
	Result.Insert("InteractivePostingRegular", "InteractivePostingRegular");
	Result.Insert("InteractiveUndoPosting", "InteractiveUndoPosting");
	Result.Insert("InteractiveChangeOfPosted", "InteractiveChangeOfPosted");
	Result.Insert("InputByString", "InputByString");
	Result.Insert("TotalsControl", "TotalsControl");
	Result.Insert("Use", "Use");
	Result.Insert("InteractiveDelete", "InteractiveDelete");
	Result.Insert("Administration", "Administration");
	Result.Insert("DataAdministration", "DataAdministration");
	Result.Insert("ExclusiveMode", "ExclusiveMode");
	Result.Insert("ActiveUsers", "ActiveUsers");
	Result.Insert("EventLog", "EventLog");
	Result.Insert("ExternalConnection", "ExternalConnection");
	Result.Insert("Automation", "Automation");
	Result.Insert("InteractiveOpenExtDataProcessors", "InteractiveOpenExtDataProcessors");
	Result.Insert("InteractiveOpenExtReports", "InteractiveOpenExtReports");
	Result.Insert("Receive", "Get");
	Result.Insert("Set", "Set");
	Result.Insert("InteractiveActivate", "InteractiveActivate");
	Result.Insert("Start", "Start");
	Result.Insert("InteractiveStart", "InteractiveStart");
	Result.Insert("Perform", "Execute");
	Result.Insert("InteractiveExecute", "InteractiveExecute");
	Result.Insert("Output", "Output");
	Result.Insert("UpdateDataBaseConfiguration", "UpdateDataBaseConfiguration");
	Result.Insert("ThinClient", "ThinClient");
	Result.Insert("WebClient", "WebClient");
	Result.Insert("ThickClient", "ThickClient");
	Result.Insert("AllFunctionsMode", "AllFunctionsMode");
	Result.Insert("SaveUserData", "SaveUserData");
	Result.Insert("StandardAuthenticationChange", "StandardAuthenticationChange");
	Result.Insert("SessionStandardAuthenticationChange", "SessionStandardAuthenticationChange");
	Result.Insert("SessionOSAuthenticationChange", "SessionOSAuthenticationChange");
	Result.Insert("InteractivePredefinedDataDataDeletion", "InteractiveDeletePredefinedData");
	Result.Insert("InteractiveSetDeletionMarkPredefinedData", "InteractiveSetDeletionMarkPredefinedData");
	Result.Insert("InteractiveClearDeletionMarkPredefinedData", "InteractiveClearDeletionMarkPredefinedData");
	Result.Insert("InteractiveDeleteMarkedPredefinedData", "InteractiveDeleteMarkedPredefinedData");
	
	For Each Item In Result Do
		Result.Insert(Item.Value, Item.Key);
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

Function MetadataObjectsRepresentations()
	
	PresentationsStructure = New Structure;
	PresentationsStructure.Insert("ExchangePlan", "ExchangePlan");
	PresentationsStructure.Insert("Constant", "Constant");
	PresentationsStructure.Insert("Catalog", "Catalog");
	PresentationsStructure.Insert("SessionParameter", "SessionParameter");
	PresentationsStructure.Insert("DocumentJournal", "DocumentJournal");
	PresentationsStructure.Insert("Document", "Document");
	PresentationsStructure.Insert("ChartOfCharacteristicTypes", "ChartOfCharacteristicTypes");
	PresentationsStructure.Insert("ChartOfAccounts", "ChartOfAccounts");
	PresentationsStructure.Insert("ChartOfCalculationTypes", "ChartOfCalculationTypes");
	PresentationsStructure.Insert("InformationRegister", "InformationRegister");
	PresentationsStructure.Insert("AccumulationRegister", "AccumulationRegister");
	PresentationsStructure.Insert("AccountingRegister", "AccountingRegister");
	PresentationsStructure.Insert("CalculationRegister", "CalculationRegister");
	PresentationsStructure.Insert("BusinessProcess", "BusinessProcess");
	PresentationsStructure.Insert("Task", "Task");
	
	Return PresentationsStructure;
	
EndFunction

#EndRegion

#Region DataExchange

Procedure CheckAccessToNonExistentExchangePlanSettings()
	
	ModuleDataExchangeCached = Common.CommonModule("DataExchangeCached");
	ModuleDataExchangeServer  = Common.CommonModule("DataExchangeServer");
	
	For Each ExchangePlanName In ModuleDataExchangeCached.SSLExchangePlans() Do
		MetadataOfExchangePlan = Metadata.ExchangePlans[ExchangePlanName];
		
		Try
			SettingVariants = ModuleDataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "ExchangeSettingsOptions");
		Except
			ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			AddError(MetadataOfExchangePlan, NStr("ru = 'Обращение к устаревшим настройкам плана обмена';
														|en = 'Address obsolete exchange plan settings';"),
			    StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В процедуре ""%1"" модуля менеджера плана обмена
						|обнаружено обращение к несуществующей настройке: %2';
						|en = 'In procedure ""%1"" of exchange plan manager module,
						|an attempt to access a non-existent setting is found:%2';"), "OnGetSettings", ErrorPresentation));
			Continue;
		EndTry;
		
		For Each SettingsOption In SettingVariants Do
			Try
				ModuleDataExchangeServer.SettingOptionDetails(ExchangePlanName,
					SettingsOption.SettingID, "", "");
			Except
				AddError(MetadataOfExchangePlan, NStr("ru = 'Обращение к устаревшим свойствам описания варианта настроек';
															|en = 'Address obsolete properties of setting option details';"),
				    StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'В процедуре ""%1"" модуля менеджера плана обмена
							|обнаружено обращение к несуществующему свойству: %2';
							|en = 'In procedure ""%1"" of exchange plan manager module,
							|an attempt to access a non-existent property is found:%2';"), "OnGetSettingOptionDetails", ErrorPresentation));
			EndTry;
		EndDo;
	EndDo;
	
EndProcedure

Procedure CheckLayoutsAndFormsAvailability()
	
	For Each ExchangePlanName In Common.CommonModule("DataExchangeCached").SSLExchangePlans() Do
		
		MetadataOfExchangePlan = Metadata.ExchangePlans[ExchangePlanName];
		HasLayout = MetadataOfExchangePlan.Templates.Find("RecordRules") <> Undefined;
		
		If HasLayout Then
			Continue;
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Отсутствует макет ""%1""';
																						|en = 'Template ""%1"" is missing';"), "RecordRules");
		EndIf;
		
		AddError(MetadataOfExchangePlan, NStr("ru = 'Отсутствуют правила регистрации';
													|en = 'Registration rules are missing';"), ErrorText);
		
	EndDo;
	
EndProcedure

Procedure CheckConfigurationReceiverNameIndication()
	
	ModuleDataExchangeCached = Common.CommonModule("DataExchangeCached");
	ModuleDataExchangeServer  = Common.CommonModule("DataExchangeServer");
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		If Not ExchangePlan.DistributedInfoBase
			And ModuleDataExchangeCached.ExchangePlanUsedInSaaS(ExchangePlan.Name)
			And ModuleDataExchangeServer.IsSeparatedSSLExchangePlan(ExchangePlan.Name) Then
			
			ExchangeSettings = ModuleDataExchangeServer.ExchangePlanSettingValue(ExchangePlan.Name, "IsXDTOExchangePlan, DestinationConfigurationName");
			If ExchangeSettings.IsXDTOExchangePlan Then
				
				Continue;
				
			EndIf;
			
			If Not ValueIsFilled(ExchangeSettings.DestinationConfigurationName)
				Or (TypeOf(ExchangeSettings.DestinationConfigurationName) = Type("Structure")
						And ExchangeSettings.DestinationConfigurationName.Count() = 0) Then
				
				MetadataOfExchangePlan = Metadata.ExchangePlans[ExchangePlan.Name];
				
				ErrorTitle = NStr("ru = 'Отсутствует обязательная настройка плана обмена';
										|en = 'Required exchange plan setting is missing';", Common.DefaultLanguageCode());
				
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В процедуре ""%1"" модуля менеджера плана обмена
					|не задано значение обязательного свойства ""%2""';
					|en = 'In procedure ""%1"" of exchange plan manager module,
					|value of required property ""%2"" is not specified';", Common.DefaultLanguageCode()),
					"OnGetSettings", "DestinationConfigurationName");
				
				AddError(MetadataOfExchangePlan, ErrorTitle, ErrorDescription);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckDefinedTypeCompositionOfMessagingEndpoint()
	
	If Not Common.SubsystemExists(
			"StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		Return;
	EndIf;
	
	If Not Common.SubsystemExists("CloudTechnology.MessagesExchange") Then
		AddError(
			Metadata.DefinedTypes["MessagesQueueEndpoint"],
			NStr("ru = 'Отсутствует обязательная подсистема для обмена данными в модели сервиса';
				|en = 'The required subsystem for data exchange in SaaS is missing';"),
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В конфигурацию не встроена подсистема ""%1"",
				|необходимая для работы подсистемы ""%2""';
				|en = 'Subsystem ""%1"" required for the operation of subsystem ""%2""
				|is not built in the configuration';"),
				"CloudTechnology.MessagesExchange", "StandardSubsystems.SaaSOperations.DataExchangeSaaS"));
		Return;
	EndIf;
	
	ExchangePlanName = "MessagesExchange";
	
	ActualComposition = Metadata.DefinedTypes["MessagesQueueEndpoint"].Type.Types();
	PlannedComposition    = CommonClientServer.ValueInArray(Type("ExchangePlanRef." + ExchangePlanName));
	
	RedundantTypes = New Array;
	For Each CompositionItem In ActualComposition Do
		If PlannedComposition.Find(CompositionItem) = Undefined Then
			RedundantTypes.Add(CompositionItem);
		EndIf;
	EndDo;
	
	If RedundantTypes.Count() > 0 Then
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В состав определяемого типа ""%1"" избыточно включены следующие типы:
			|%2';
			|en = 'The %1 type collection contains the following redundant types:
			|%2';"),
			"MessagesQueueEndpoint", StrConcat(RedundantTypes, Chars.LF));
		
		AddError(
			Metadata.DefinedTypes["MessagesQueueEndpoint"],
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Некорректный состав определяемого типа ""%1""';
																		|en = 'Incorrect composition of the %1 type collection:';"), "MessagesQueueEndpoint"),
			ErrorDescription);
	EndIf;
		
	TypesNotAdded = New Array;
	For Each CompositionItem In PlannedComposition Do
		If ActualComposition.Find(CompositionItem) = Undefined Then
			TypesNotAdded.Add(CompositionItem);
		EndIf;
	EndDo;
	
	If TypesNotAdded.Count() > 0 Then
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В состав определяемого типа ""%1"" не включены обязательные типы:
			|%2';
			|en = 'The following required types are missing from the %1 type collection:
			|%2';"),
			"MessagesQueueEndpoint", StrConcat(TypesNotAdded, Chars.LF));
		
		AddError(
			Metadata.DefinedTypes["MessagesQueueEndpoint"],
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Некорректный состав определяемого типа ""%1""';
																		|en = 'Incorrect composition of the %1 type collection:';"), "MessagesQueueEndpoint"),
			ErrorDescription);
	EndIf;
	
EndProcedure

Procedure CheckToIncludeConfigurationExtensionForExchangePlansInServiceModel()
	
	ModuleDataExchangeCached = Common.CommonModule("DataExchangeCached");
	ModuleDataExchangeServer  = Common.CommonModule("DataExchangeServer");
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		If ExchangePlan.DistributedInfoBase
			And ExchangePlan.IncludeConfigurationExtensions
			And ModuleDataExchangeCached.ExchangePlanUsedInSaaS(ExchangePlan.Name)
			And ModuleDataExchangeServer.IsSeparatedSSLExchangePlan(ExchangePlan.Name) Then
			
			MetadataOfExchangePlan = Metadata.ExchangePlans[ExchangePlan.Name];
			
			ErrorTitle = NStr("ru = '""Включать расширение конфигурации"" в модели сервиса';
									|en = '""Attach configuration extension"" in SaaS mode';", Common.DefaultLanguageCode());
			
			ErrorDescription = NStr("ru = 'Не допустимо использовать параметр ""Включать расширение конфигурации"" для распределенных планов обмена,
				|используемых в модели сервиса';
				|en = 'Cannot use the ""Attach configuration extension"" parameter for distributed exchange plans
				|used in SaaS mode';", Common.DefaultLanguageCode());
			
			AddError(MetadataOfExchangePlan, ErrorTitle, ErrorDescription);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckCompositionOfCommonCommand()
	
	ModuleDataExchangeCached = Common.CommonModule("DataExchangeCached");
	ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
	
	AllSSLExchangePlans = ModuleDataExchangeCached.SSLExchangePlans();
	CommonDataExchangeCommands = CommonDataExchangeCommands();
	
	For Each ExchangePlanName In AllSSLExchangePlans Do
		
		ExchangePlan = Metadata.ExchangePlans.Find(ExchangePlanName);
		If ModuleDataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName) Then
			VerificationProperty = "ForRIBExchange";
		ElsIf ModuleDataExchangeServer.IsXDTOExchangePlan(ExchangePlanName) Then
			VerificationProperty = "ForAUniversalExchangeFormat";
		ElsIf Not ModuleDataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName)
			And ModuleDataExchangeCached.HasExchangePlanTemplate(ExchangePlanName, "ExchangeRules")
			And Not ModuleDataExchangeServer.IsXDTOExchangePlan(ExchangePlanName) Then
			VerificationProperty = "ForExchangeByConversionRules";
		ElsIf Not ModuleDataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName)
			And Not ModuleDataExchangeCached.HasExchangePlanTemplate(ExchangePlanName, "ExchangeRules") Then
			VerificationProperty = "ForUniversalExchangeWithoutRules";
		EndIf;
		
		MissingContext = New Array;
		RedundantComposition = New Array;
		
		For Each TableRow In CommonDataExchangeCommands Do
			
			MustBeEnabled = TableRow[VerificationProperty];
			If MustBeEnabled = Undefined Then
				Continue;
			EndIf;
			ActuallyEnabled = TableRow.CommandComposition.Find(ExchangePlan) <> Undefined;
			
			If MustBeEnabled And Not ActuallyEnabled Then
				MissingContext.Add(TableRow.CommandName);
			ElsIf Not MustBeEnabled And ActuallyEnabled Then
				RedundantComposition.Add(TableRow.CommandName);
			EndIf;
			
		EndDo;
		
		If MissingContext.Count() > 0 Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'План обмена должен быть включен в состав общих команд
					|%1';
					|en = 'Exchange plan must be included in common commands
					|%1';"), BulletedList(MissingContext));
			AddError(ExchangePlan, NStr("ru = 'План обмена не включен в состав команд';
											|en = 'Exchange plan is not included in command composition';"), ErrorText);
		EndIf;
		
		If RedundantComposition.Count() > 0 Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'План обмена должен быть исключен из состава общих команд
					|%1';
					|en = 'Exchange plan must be excluded from common commands
					|%1';"), BulletedList(RedundantComposition));
			AddError(ExchangePlan, NStr("ru = 'План обмена избыточно включен в состав команд';
											|en = 'Exchange plan is redundantly included in command composition';"), ErrorText);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckExchangePlansComposition()
	
	// Get a list of all SSL metadata objects that contain data.
	ValidMetadata = New Array;
	ValidMetadata.Add(Metadata.Constants);
	ValidMetadata.Add(Metadata.Catalogs);
	ValidMetadata.Add(Metadata.Documents);
	ValidMetadata.Add(Metadata.ChartsOfCharacteristicTypes);
	ValidMetadata.Add(Metadata.ChartsOfAccounts);
	ValidMetadata.Add(Metadata.ChartsOfCalculationTypes);
	ValidMetadata.Add(Metadata.InformationRegisters);
	ValidMetadata.Add(Metadata.AccumulationRegisters);
	ValidMetadata.Add(Metadata.AccountingRegisters);
	ValidMetadata.Add(Metadata.CalculationRegisters);
	ValidMetadata.Add(Metadata.BusinessProcesses);
	ValidMetadata.Add(Metadata.Tasks);
	
	AllMetadataObjects = New Array;
	For Each Subsystem In Metadata.Subsystems.StandardSubsystems.Subsystems Do
		If Subsystem.Subsystems.Count() > 0 Then
			For Each SubordinateSubsystem In Subsystem.Subsystems Do
				If SubordinateSubsystem.Name = "DataExchangeSaaS" Then
					Continue;
				EndIf;
				AddSubsystemObjects(SubordinateSubsystem, AllMetadataObjects);
			EndDo;
		EndIf;
		If Subsystem.Name = "DataExchange" Then
			Continue;
		EndIf;
		AddSubsystemObjects(Subsystem, AllMetadataObjects);
	EndDo;
	
	AnyRIBExchangePlanExclusionObjects = AnyRIBExchangePlanExclusionObjects(); // "Full", "WithFilters" (including "SWP")
	
	RIBExchangePlanFullAdditionalExclusionObjects    = RIBExchangePlanFullAdditionalExclusionObjects(); // "Full" only (including "SWP")
	RIBExchangePlanFilterAdditionalExclusionObjects = RIBExchangePlanFilterAdditionalExclusionObjects(); // "Full" only (including "SWP")
	ARMExchangePlanAdditionalExclusionObjects          = ARMExchangePlanAdditionalExclusionObjects(); // "WithFilters" only (including "SWP")
	
	ObjectsOnlyForAnyRIBInitialImage = ObjectsOnlyForAnyRIBInitialImage(); // "Full", "WithFilters" (including "SWP")
	
	AdditionalObjectsOnlyForRIBInitialImageFull    = AdditionalObjectsOnlyForRIBInitialImageFull(); // "Full" only (including "SWP")
	AdditionalObjectsOnlyForRIBInitialImageWithFilter = AdditionalObjectsOnlyForRIBInitialImageWithFilter(); // "Full" only (including "SWP")
	AdditionalObjectsOnlyForARMInitialImage          = AdditionalObjectsOnlyForARMInitialImage(); // "WithFilters" only (including "SWP")
	
	VariablyIncludedInRIBObjects = VariablyIncludedInRIBObjects(); // Exclude from the check scope for the exchange plan and subscriptions.
	
	SubsystemExchangePlans = New Array; // Array of MetadataObjectExchangePlan
	Common.CommonModule("DataExchangeOverridable").GetExchangePlans(SubsystemExchangePlans);
	
	For Each ExchangePlan In SubsystemExchangePlans Do
		
		// Get exchange plan content. Check autoregistration.
		ExchangePlanContent = New Array;
		For Each ObjectOfExchangePlan In ExchangePlan.Content Do
			If IsSSLObject(ObjectOfExchangePlan.Metadata) Then
				ExchangePlanContent.Add(ObjectOfExchangePlan.Metadata);
			EndIf;
			If ObjectOfExchangePlan.AutoRecord = AutoChangeRecord.Allow Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Для объекта %1, входящего в состав плана обмена %2 включена авторегистрация.
					|Все элементы состава плана обмена должны иметь признак авторегистрации Запретить.';
					|en = 'Autoregistration is enabled for object %1 included in exchange plan %2.
					|All components of the exchange plan must have autoregistration disabled.';"),
					ObjectOfExchangePlan.Metadata.FullName(), ExchangePlan.Name);
				AddError(ObjectOfExchangePlan.Metadata, NStr("ru = 'Некорректное использование признака авторегистрации';
																	|en = 'Autoregistration set incorrectly';"), ErrorText);
			EndIf;
		EndDo;
		
		// Get exchange plan subscriptions.
		ExchangePlanName = ExchangePlan.Name;
		SubscriptionsComposition = SubscriptionsComposition(ExchangePlanName);
		SubscriptionsRegistrationCompositionChanges = SubscriptionsComposition.ChangesRegistration;
		
		If ExchangePlan.DistributedInfoBase Then
			// Check exchange plan content.
			ExchangePlanExclusionObjects = Common.CopyRecursive(AnyRIBExchangePlanExclusionObjects);
			
			ExchangePlanPurpose = Common.CommonModule("DataExchangeServer").ExchangePlanPurpose(ExchangePlanName);
			IsRIBFilterExchangePlan = ?(Upper(ExchangePlanPurpose) = "DIBWITHFILTER", True, False);
			
			IsARMExchangePlan = Common.CommonModule("DataExchangeServer").IsSeparatedSSLExchangePlan(ExchangePlanName)
				And Common.CommonModule("DataExchangeCached").ExchangePlanUsedInSaaS(ExchangePlanName);
				
			If IsRIBFilterExchangePlan Then
				CommonClientServer.SupplementArray(ExchangePlanExclusionObjects, RIBExchangePlanFilterAdditionalExclusionObjects, True);
			Else
				CommonClientServer.SupplementArray(ExchangePlanExclusionObjects, RIBExchangePlanFullAdditionalExclusionObjects, True);
			EndIf;
			
			If IsARMExchangePlan Then
				CommonClientServer.SupplementArray(ExchangePlanExclusionObjects, ARMExchangePlanAdditionalExclusionObjects, True);
			EndIf;
			
			PlannedComposition = CommonClientServer.ArraysDifference(AllMetadataObjects, ExchangePlanExclusionObjects);
			PlannedComposition = CommonClientServer.ArraysDifference(PlannedComposition, VariablyIncludedInRIBObjects);
			ActualComposition = CommonClientServer.ArraysDifference(ExchangePlanContent, VariablyIncludedInRIBObjects);
			
			ValidateExchangePlanContent(ExchangePlanName, PlannedComposition, ActualComposition);
			
			// Check subscription content.
			ObjectsUsedOnlyForInitialImage = Common.CopyRecursive(
				ObjectsOnlyForAnyRIBInitialImage);
				
			If IsRIBFilterExchangePlan Then
				CommonClientServer.SupplementArray(ObjectsUsedOnlyForInitialImage, AdditionalObjectsOnlyForRIBInitialImageWithFilter, True);
			Else
				CommonClientServer.SupplementArray(ObjectsUsedOnlyForInitialImage, AdditionalObjectsOnlyForRIBInitialImageFull, True);
			EndIf;
			
			If IsARMExchangePlan Then
				CommonClientServer.SupplementArray(ObjectsUsedOnlyForInitialImage, AdditionalObjectsOnlyForARMInitialImage, True);
			EndIf;
			
			PlannedComposition = CommonClientServer.ArraysDifference(PlannedComposition, ObjectsUsedOnlyForInitialImage);
			ActualComposition = ExcludeVariableObjects(SubscriptionsRegistrationCompositionChanges, VariablyIncludedInRIBObjects);
			CheckInitialImageComposition(ExchangePlanName, PlannedComposition, ActualComposition);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckExchangePlanManagerModulesCodeInserts()
	
	SubsystemExchangePlans = New Array; // Array of MetadataObjectExchangePlan
	Common.CommonModule("DataExchangeOverridable").GetExchangePlans(SubsystemExchangePlans);
	
	For Each ExchangePlan In SubsystemExchangePlans Do
		
		ExchangePlanName = ExchangePlan.Name;
		
		CheckParameters = CheckingCodeInsertionParameters();
		CheckParameters.DataToCheck1 = ExchangePlan;
		CheckParameters.ModuleType         = "ManagerModule";
		
		CheckParameters.CodeString = MandatoryExchangePlanManagerModuleProcedures(ExchangePlanName);
		CheckParameters.AbsenceOfProcedureIsError  = True;
		CheckParameters.ProcedurePresenceIsError = False;
		CheckForCodeInsertion(CheckParameters);
		
		CheckParameters.CodeString = ExchangePlanManagerModuleUnnecessaryProcedures(ExchangePlanName);
		CheckParameters.AbsenceOfProcedureIsError  = False;
		CheckParameters.ProcedurePresenceIsError = True;
		CheckForCodeInsertion(CheckParameters);
		
		// Check for the algorithms declared in exchange plan settings.
		If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
			ModuleDataExchangeCached = Common.CommonModule("DataExchangeCached");
			Try
				ExchangePlanSettings = ModuleDataExchangeCached.ExchangePlanSettings(ExchangePlanName);
			Except
				// Don't display the error. Other means are utilized to check if OnGetSettings is missing.
				ExchangePlanSettings = Undefined;
			EndTry;
		EndIf;
		
		If ExchangePlanSettings <> Undefined Then
			AvailabilityVerificationProcedures = New Array;
			AbsenceVerificationProcedures = New Array;

			For Each Algorithm In ExchangePlanSettings.Algorithms Do
				If Algorithm.Value Then
					AvailabilityVerificationProcedures.Add("" + Algorithm.Key + "(");
				Else
					AbsenceVerificationProcedures.Add("" + Algorithm.Key + "(");
				EndIf;
			EndDo;
			
			CheckParameters.IsOptionalAlgorithm = True;
			
			CheckParameters.CodeString = AbsenceVerificationProcedures;
			CheckParameters.AbsenceOfProcedureIsError  = False;
			CheckParameters.ProcedurePresenceIsError = True;
			CheckForCodeInsertion(CheckParameters);
			
			CheckParameters.CodeString = AvailabilityVerificationProcedures;
			CheckParameters.AbsenceOfProcedureIsError  = True;
			CheckParameters.ProcedurePresenceIsError = False;
			CheckForCodeInsertion(CheckParameters);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function ExcludeVariableObjects(SubscriptionsComposition, VariableObjects)
	
	For Each Object In VariableObjects Do
		For Each TableRow In SubscriptionsComposition Do
			FoundItem = TableRow.Content.Find(Object);
			If FoundItem <> Undefined Then
				TableRow.Content.Delete(FoundItem);
			EndIf;
		EndDo;
	EndDo;
	
	Return SubscriptionsComposition;
	
EndFunction

Procedure CheckDefaultInformationBasePrefix()
	DefaultInfobasePrefix = "";
	Common.CommonModule("DataExchangeOverridable").OnDetermineDefaultInfobasePrefix(DefaultInfobasePrefix);
	If IsBlankString(DefaultInfobasePrefix) Or StrLen(DefaultInfobasePrefix) <> 2 Then
		AddError(Metadata.CommonModules.DataExchangeOverridable,
			NStr("ru = 'Некорректно задан префикс ИБ по умолчанию';
				|en = 'The default infobase prefix is specified incorrectly';"),
			NStr("ru = 'Неправильно задан префикс информационной по умолчанию.';
				|en = 'Infobase prefix is specified incorrectly.';"));
	EndIf;
EndProcedure

Procedure AddCommandTableRow(CommandName, ForRIBExchange, ForAUniversalExchangeFormat,
	ForUniversalExchangeWithoutRules, ForExchangeByConversionRules, CommandsTable)
	
	NewRow = CommandsTable.Add();
	NewRow.CommandName = CommandName;
	NewRow.ForRIBExchange = ForRIBExchange;
	NewRow.ForAUniversalExchangeFormat = ForAUniversalExchangeFormat;
	NewRow.ForUniversalExchangeWithoutRules = ForUniversalExchangeWithoutRules;
	NewRow.ForExchangeByConversionRules = ForExchangeByConversionRules;
	NewRow.CommandComposition = TypeCompositionFromString(StringFunctionsClientServer.SubstituteParametersToString("CommonCommands.%1.CommandParameterType", CommandName));
	
EndProcedure

Procedure AddSubsystemObjects(Subsystem, AllMetadataObjects)
	
	For Each Object In Subsystem.Content Do
		AddObjectToASubsystem(Object, AllMetadataObjects);
	EndDo;
	
EndProcedure

Procedure AddAllSubsystemObjects(SubsystemName, Exceptions)
	
	Subsystem = Metadata.Subsystems.StandardSubsystems.Subsystems.Find(SubsystemName);
	If Subsystem = Undefined Then
		Return;
	EndIf;
	
	For Each Object In Subsystem.Content Do
		AddObjectToASubsystem(Object, Exceptions);
	EndDo;
	
	For Each SubordinateSubsystem In Subsystem.Subsystems Do
		AddAllSubsystemObjects(SubordinateSubsystem.Name, Exceptions);
	EndDo;
	
EndProcedure

Procedure AddObject(ObjectName, Exceptions)
	
	MetadataObject = Common.MetadataObjectByFullName(ObjectName);
	If MetadataObject <> Undefined Then
		Exceptions.Add(MetadataObject);
	ElsIf IsDemoSSL() Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В функции %1 указан несуществующий объект метаданных %2';
																					|en = 'Non-existent metadata object %2 is specified in function %1';"), "ObjectsExchangePlanExchangeRIB", ObjectName);
		AddError(Metadata,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Некорректно заполнены %1';
																		|en = '%1 are filled in incorrectly';"), "ObjectsExchangePlanExchangeRIB"),
			ErrorText);
	EndIf;
	
EndProcedure

Procedure AddObjectToASubsystem(Object, Content)
	
	For Each ValidType_ In ValidMetadata Do
		If ValidType_.Contains(Object) Then
			Content.Add(Object);
		EndIf;
	EndDo;
	
EndProcedure

Procedure SubsystemDoesNotContainObjects(SubsystemName)
	
	Subsystem = Metadata.Subsystems.StandardSubsystems.Subsystems.Find(SubsystemName);
	If Subsystem = Undefined Then
		Return
	EndIf;

	For Each Object In Subsystem.Content Do
		For Each ValidType_ In ValidMetadata Do
			If ValidType_.Contains(Object) Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Согласно документации, подсистема %1 не 
					|содержит объектов для включения в состав плана обмена.';
					|en = 'According to the documentation, the %1 subsystem does not 
					|contain objects to include in the exchange plan.';"), SubsystemName);
				AddError(Object, NStr("ru = 'Подсистема содержит объекты с данными';
											|en = 'The subsystem contains objects with data';"), ErrorText);
			EndIf;
		EndDo;
	EndDo;
	
	For Each SubordinateSubsystem In Subsystem.Subsystems Do
		SubsystemDoesNotContainObjects(SubordinateSubsystem);
	EndDo;
	
EndProcedure

Procedure ValidateExchangePlanContent(ExchangePlanName, PlannedComposition, ActualComposition)
	
	MissingObjects = CommonClientServer.ArraysDifference(PlannedComposition, ActualComposition);
	
	For Each Object In MissingObjects Do
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Объект %1 не включен в состав плана обмена %2.
			|Если объект не должен участвовать в РИБ, то добавьте исключение в функции %3 модуля объекта отчета %4.';
			|en = 'Object %1 is not included in exchange plan %2.
			|If the object cannot take part in DIB, add an exception to functions %3 of report object module %4.';"),
			Object.FullName(), ExchangePlanName, "AnyRIBExchangePlanExclusionObjects", "SSLImplementationCheck");
		AddError(Object, NStr("ru = 'Объект должен быть включен в состав плана обмена';
									|en = 'Object must be included in exchange plan';"), ErrorText);
	EndDo;
	
	RedundantObjects = CommonClientServer.ArraysDifference(ActualComposition, PlannedComposition);
	
	For Each Object In RedundantObjects Do
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Объект %1 избыточно включен включен в состав плана обмена %2';
																					|en = 'Object %1 is excessively included in the exchange plan %2';"),
			Object.FullName(), ExchangePlanName);
		AddError(Object, NStr("ru = 'Объект избыточно включен в состав плана обмена';
									|en = 'Object is excessively included in the exchange plan';"), ErrorText);
	EndDo;
	
EndProcedure

Procedure CheckInitialImageComposition(ExchangePlanName, PlannedComposition, ActualComposition)
	
	// Missing objects.
	For Each Object In PlannedComposition Do
		For Each TableRow In ActualComposition Do
			If Not CompareTypesPossible(Object, TableRow.AllowedTypes) Then
				Continue;
			EndIf;
			If TableRow.Content.Find(Object) = Undefined Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Объект %1 включите в состав %2';
						|en = 'Include the %1 object in %2';"),
					Object.FullName(), TableRow.LongDesc);
				AddError(Object, 
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Объект должен быть включен в подписку вида <%1><%2>';
							|en = 'Object must be included in subscription of the following kind: <%1><%2>';"), "ExchangePlanName", "SubscriptionKind"), ErrorText);
			EndIf;
		EndDo;
	EndDo;
	
	// Redundant objects.
	For Each TableRow In ActualComposition Do
		For Each Object In TableRow.Content Do
			If PlannedComposition.Find(Object) = Undefined Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Объект %1 избыточно включен в состав %2';
						|en = 'The %1 object is excessively included in %2';"),
					Object.FullName(), TableRow.LongDesc);
				AddError(Object, 
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Объект избыточно включен в подписку вида <%1><%2>';
							|en = 'Object is excessively included in subscription of the following kind: <%1><%2>';"), "ExchangePlanName", "SubscriptionKind"), ErrorText);
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Function SubscriptionsComposition(ExchangePlanName)
	
	SubscriptionNameRegistration = ExchangePlanName + "Registration";
	DeletionSubscriptionName = ExchangePlanName + "RegistrationDeletion";
	
	SubscriptionsProperties = New Structure;
	SubscriptionsProperties.Insert(ExchangePlanName + "RegistrationCalculationSet", "CalculationRegisters");
	SubscriptionsProperties.Insert(ExchangePlanName + "RegistrationSet", "InformationRegisters,AccumulationRegisters,AccountingRegisters");
	SubscriptionsProperties.Insert(ExchangePlanName + "RegistrationDocument", "Documents");
	SubscriptionsProperties.Insert(ExchangePlanName + "RegistrationConstant", "Constants");
	SubscriptionsProperties.Insert(DeletionSubscriptionName, "Catalogs,Documents,ChartsOfCharacteristicTypes,ChartsOfAccounts,ChartsOfCalculationTypes,BusinessProcesses,Tasks");
	SubscriptionsProperties.Insert(SubscriptionNameRegistration, "Catalogs,ChartsOfCharacteristicTypes,ChartsOfAccounts,ChartsOfCalculationTypes,BusinessProcesses,Tasks");
	
	SubscriptionsRegistrations = New Array;
	For Each Subscription In Metadata.EventSubscriptions Do
		If StrStartsWith(Subscription.Name, SubscriptionNameRegistration) Then
			SubscriptionsRegistrations.Add(Subscription);
		EndIf;
	EndDo;
	
	TypesTableUpdate = TypesTable();
	TypeTableDeletion = TypesTable();
	
	For Each SubscriptionProperty In SubscriptionsProperties Do
		Content = New Array;
		SubscriptionsNumber = 0;
		For Each Subscription In SubscriptionsRegistrations Do // MetadataObjectEventSubscription
			If Subscription.Name = SubscriptionProperty.Key Then
				SubscriptionsNumber = SubscriptionsNumber + 1;
				CurSubscription = Subscription;
				For Each Type In Subscription.Source.Types() Do
					Object = Metadata.FindByType(Type);
					If IsSSLObject(Object) Then
						AddObjectToASubsystem(Object, Content);
					EndIf;
				EndDo;
				Break;
			EndIf;
		EndDo;
		
		TypesTable = ?(SubscriptionProperty.Key = DeletionSubscriptionName, TypeTableDeletion, TypesTableUpdate);
		LongDesc = ?(SubscriptionsNumber = 1, CurSubscription.FullName(),
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'подписки с именем %1';
																		|en = 'subscriptions with the %1 name';"), SubscriptionProperty.Key));
		
		NewRow = TypesTable.Add();
		NewRow.LongDesc = LongDesc;
		NewRow.AllowedTypes = SubscriptionProperty.Value;
		NewRow.Content = Content;
	EndDo;
	
	SubscriptionsComposition = New Structure;
	SubscriptionsComposition.Insert("ChangesRegistration", TypesTableUpdate);
	SubscriptionsComposition.Insert("RegistrationDeletion", TypeTableDeletion);
	
	Return SubscriptionsComposition;
	
EndFunction

Function CommonDataExchangeCommands()
	
	CommandsTable = New ValueTable;
	
	CommandsTable.Columns.Add("CommandName");
	CommandsTable.Columns.Add("ForRIBExchange");
	CommandsTable.Columns.Add("ForAUniversalExchangeFormat");
	CommandsTable.Columns.Add("ForUniversalExchangeWithoutRules");
	CommandsTable.Columns.Add("ForExchangeByConversionRules");
	CommandsTable.Columns.Add("CommandComposition");
	
	AddCommandTableRow("ImportRulesSet", False, False, False, True, CommandsTable);
	AddCommandTableRow("ImportObjectConvertionRules", False, False, False, True, CommandsTable);
	// DIB exchange plan might contain no object registration rules. No check is required.
	AddCommandTableRow("ImportObjectRegistrationRules", Undefined, True, True, True, CommandsTable);
	AddCommandTableRow("ConnectionSettings", True, True, True, True, CommandsTable);
	AddCommandTableRow("GetSynchronizationSettingsForOtherApplication", False, True, True, True, CommandsTable);
	AddCommandTableRow("Synchronize", True, True, True, True, CommandsTable);
	AddCommandTableRow("SynchronizeWithAdditionalParameters", False, True, False, True, CommandsTable);
	AddCommandTableRow("SendingEvents", True, True, True, True, CommandsTable);
	AddCommandTableRow("ReceivingEvents", True, True, True, True, CommandsTable);
	AddCommandTableRow("DataToSendComposition", True, True, True, True, CommandsTable);
	AddCommandTableRow("SynchronizationScenarios", True, True, True, True, CommandsTable);
	AddCommandTableRow("DeleteSynchronizationSetting", True, True, True, True, CommandsTable);
	
	Return CommandsTable;
	
EndFunction

// Contains a list of objects excluded from a full DIB exchange plan (including a standalone workstation).
//
Function AnyRIBExchangePlanExclusionObjects()
	
	Exceptions = New Array;
	
	AddAllSubsystemObjects("AddressClassifier", Exceptions);
	
	// StandardSubsystems.Core
	AddObject("Constant.MasterNode", Exceptions);
	AddObject("Constant.SystemTitle", Exceptions);
	AddObject("Constant.UseSeparationByDataAreas", Exceptions);
	AddObject("Constant.NotUseSeparationByDataAreas", Exceptions);
	AddObject("Constant.IsStandaloneWorkplace", Exceptions);
	AddObject("Constant.InfoBaseID", Exceptions);
	AddObject("Constant.InfobasePublicationURL", Exceptions);
	AddObject("Constant.LocalInfobasePublishingURL", Exceptions);
	AddObject("Constant.UseAlternativeServerToImportCurrencyRates", Exceptions);
	AddObject("Constant.LoadExtensionsThatChangeDataStructure", Exceptions);
	AddObject("Constant.UseOptimizedStandaloneWorkstationCreationWriting", Exceptions);
	AddObject("Constant.WindowsTemporaryFilesDerectory", Exceptions);
	AddObject("Constant.LinuxTemporaryFilesDerectory", Exceptions);
	AddObject("Constant.LongRunningOperationsThreadCount", Exceptions);
	AddObject("Constant.StandardSubsystemsStandaloneMode", Exceptions);
	AddObject("Constant.ServerNotificationsSendStatus", Exceptions);
	AddObject("Constant.DeliverServerNotificationsWithoutCollaborationSystem", Exceptions);
	AddObject("Constant.RegisterServerNotificationsIndicators", Exceptions);
	AddObject("Catalog.ExtensionsVersions", Exceptions);
	AddObject("Catalog.ExtensionObjectIDs", Exceptions);
	AddObject("InformationRegister.SafeDataStorage", Exceptions);
	AddObject("InformationRegister.SafeDataAreaDataStorage", Exceptions);
	AddObject("InformationRegister.ExtensionVersionObjectIDs", Exceptions);
	AddObject("InformationRegister.ExtensionVersionParameters", Exceptions);
	AddObject("InformationRegister.ProgramInterfaceCache", Exceptions);
	AddObject("InformationRegister.SharedUsers", Exceptions);
	AddObject("InformationRegister.TimeConsumingOperations", Exceptions);
	AddObject("InformationRegister.PeriodicServerNotifications", Exceptions);
	AddObject("InformationRegister.SentServerNotifications", Exceptions);
	AddObject("InformationRegister.ExtensionProperties", Exceptions);
	
	// StandardSubsystems.ReportsOptions
	AddObject("Catalog.PredefinedExtensionsReportsOptions", Exceptions);
	AddObject("InformationRegister.PredefinedExtensionsVersionsReportsOptions", Exceptions);
	AddObject("InformationRegister.ReportsSnapshots", Exceptions);
	
	// StandardSubsystems.Interactions
	AddObject("InformationRegister.AccountsLockedForReceipt", Exceptions);
	AddObject("InformationRegister.EmailFolderStates", Exceptions);
	AddObject("InformationRegister.InteractionsSubjectsStates", Exceptions);
	AddObject("InformationRegister.InteractionsContactStates", Exceptions);
	
	SubsystemDoesNotContainObjects("BatchEditObjects");
	
	// StandardSubsystems.AddIns
	AddObject("Catalog.AddIns", Exceptions);
	
	// StandardSubsystems.PeriodClosingDates
	AddObject("Constant.PeriodClosingDatesVersion", Exceptions);
	AddObject("ChartOfCharacteristicTypes.PeriodClosingDatesSections", Exceptions);
	
	// StandardSubsystems.UsersSessions
	AddObject("Constant.IBAdministrationParameters", Exceptions);
	AddObject("InformationRegister.DataAreaSessionLocks", Exceptions);
	
	SubsystemDoesNotContainObjects("ImportDataFromFile");
	SubsystemDoesNotContainObjects("ObjectAttributesLock");
	
	
	// StandardSubsystems.AccountingAudit
	AddObject("InformationRegister.AccountingCheckResults", Exceptions);
	AddObject("InformationRegister.AccessKeysToRegisterAccountingCheckResults", Exceptions);
	AddObject("InformationRegister.AccountingChecksStates", Exceptions);
	AddObject("Catalog.ChecksKinds", Exceptions);
	AddObject("Catalog.AccountingCheckRules", Exceptions);
	
	// StandardSubsystems.UserMonitoring
	AddObject("Constant.RegistrationSettingsForDataAccessEvents", Exceptions);
	AddObject("Constant.ShouldRegisterChangesInAccessRights", Exceptions);
	
	// StandardSubsystems.NationalLanguageSupport
	AddObject("Constant.UseTextTranslationService", Exceptions);
	AddObject("Constant.TextTranslationService", Exceptions);
	AddObject("InformationRegister.TranslationCache", Exceptions);
	
	SubsystemDoesNotContainObjects("ItemOrderSetup");
	SubsystemDoesNotContainObjects("ApplicationSettings");
	
	// StandardSubsystems.DataExchange
	AddObject("Constant.ORMCachedValuesRefreshDate", Exceptions);
	AddObject("Constant.LoadDataExchangeMessage", Exceptions);
	AddObject("Constant.UseDataSynchronization", Exceptions);
	AddObject("Constant.UseDataSynchronizationInLocalMode", Exceptions);
	AddObject("Constant.UseDataSynchronizationSaaS", Exceptions);
	AddObject("Constant.DataExchangeMessageDirectoryForWindows", Exceptions);
	AddObject("Constant.DataExchangeMessageDirectoryForLinux", Exceptions);
	AddObject("Constant.DataImportTransactionItemCount", Exceptions);
	AddObject("Constant.SubordinateDIBNodeSetupCompleted", Exceptions);
	AddObject("Constant.RetryDataExchangeMessageImportBeforeStart", Exceptions);
	AddObject("Constant.DistributedInfobaseNodePrefix", Exceptions);
	AddObject("Constant.DataExchangeMessageFromMasterNode", Exceptions);
	AddObject("Catalog.DataExchangeScenarios", Exceptions);
	AddObject("InformationRegister.ObjectsDataToRegisterInExchanges", Exceptions);
	AddObject("InformationRegister.CommonNodeDataChanges", Exceptions);
	AddObject("InformationRegister.DeleteExchangeTransportSettings", Exceptions);
	AddObject("InformationRegister.DataExchangeTransportSettings", Exceptions);
	AddObject("InformationRegister.MessageExchangeTransportSettings", Exceptions);
	AddObject("InformationRegister.XDTODataExchangeSettings", Exceptions);
	AddObject("InformationRegister.CommonInfobasesNodesSettings", Exceptions);
	AddObject("InformationRegister.DataSyncEventHandlers", Exceptions);
	AddObject("InformationRegister.DataExchangeRules", Exceptions);
	AddObject("InformationRegister.PredefinedNodesAliases", Exceptions);
	AddObject("InformationRegister.SynchronizedObjectPublicIDs", Exceptions);
	AddObject("InformationRegister.DataExchangeResults", Exceptions);
	AddObject("InformationRegister.DeleteDataExchangeResults", Exceptions);
	AddObject("InformationRegister.DataExchangeMessages", Exceptions);
	AddObject("InformationRegister.InfobaseObjectsMaps", Exceptions);
	AddObject("InformationRegister.DataExchangesStates", Exceptions);
	AddObject("InformationRegister.SuccessfulDataExchangesStates", Exceptions);
	AddObject("InformationRegister.ArchiveOfExchangeMessages", Exceptions);
	AddObject("InformationRegister.DataExchangeTasksInternalPublication", Exceptions);
	AddObject("InformationRegister.SynchronizationCircuit", Exceptions);
	AddObject("InformationRegister.ExchangeMessageArchiveSettings", Exceptions);
	AddObject("InformationRegister.ObjectsUnregisteredDuringLoop", Exceptions);
	
	// StandardSubsystems.IBVersionUpdate
	AddObject("Constant.InfobaseUpdateThreadCount", Exceptions);
	AddObject("InformationRegister.SharedDataUpdateHandlers", Exceptions);
	AddObject("InformationRegister.UpdateThreads", Exceptions);
	AddObject("InformationRegister.UpdateProgress", Exceptions);
	AddObject("InformationRegister.CommitDataProcessedByHandlers", Exceptions);
	
	// StandardSubsystems.ConfigurationUpdate
	AddAllSubsystemObjects("ConfigurationUpdate", Exceptions);
	
	SubsystemDoesNotContainObjects("DuplicateObjectsDetection");
	
	// StandardSubsystems.Print
	AddObject("InformationRegister.CommonSuppliedPrintTemplates", Exceptions);
	AddObject("InformationRegister.SuppliedPrintTemplates", Exceptions);
	
	// StandardSubsystems.GetFilesFromInternet
	AddObject("Constant.ProxyServerSetting", Exceptions);
	
	// StandardSubsystems.Users
	AddObject("Constant.DeleteUserAuthorizationSettings", Exceptions);
	AddObject("Constant.UserAuthorizationSettings", Exceptions);
	AddObject("InformationRegister.UsersInfo", Exceptions);
	
	SubsystemDoesNotContainObjects("ObjectsPrefixes");
	SubsystemDoesNotContainObjects("SoftwareLicenseCheck");
	
	// StandardSubsystems.SecurityProfiles
	AddObject("Constant.AutomaticallyConfigurePermissionsInSecurityProfiles", Exceptions);
	AddObject("Constant.UseSecurityProfiles", Exceptions);
	AddObject("Constant.InfobaseSecurityProfile", Exceptions);
	AddObject("InformationRegister.RequestsForPermissionsToUseExternalResources", Exceptions);
	AddObject("InformationRegister.PermissionsToUseExternalResources", Exceptions);
	AddObject("InformationRegister.ExternalModulesAttachmentModes", Exceptions);
	
	// StandardSubsystems.SaaS
	AddObject("Constant.BackUpDataArea", Exceptions);
	AddObject("Constant.LastClientSessionStartDate", Exceptions);
	AddObject("Constant.AdditionalReportAndDataProcessorFolderUsageSaaS", Exceptions);
	AddObject("Constant.UseSecurityProfilesForARDP", Exceptions);
	AddObject("Constant.FileExchangeDirectorySaaS", Exceptions);
	AddObject("Constant.FileExchangeDirectorySaaSLinux", Exceptions);
	AddObject("Constant.DataAreaKey", Exceptions);
	AddObject("Constant.CopyDataAreasFromPrototype", Exceptions);
	AddObject("Constant.MaxActiveBackgroundJobExecutionTime", Exceptions);
	AddObject("Constant.MaxActiveBackgroundJobCount", Exceptions);
	AddObject("Constant.MinimalARADPScheduledJobIntervalSaaS", Exceptions);
	AddObject("Constant.IndependentUsageOfAdditionalReportsAndDataProcessorsSaaS", Exceptions);
	AddObject("Constant.BackupSupported", Exceptions);
	AddObject("Constant.DataAreaPresentation", Exceptions);
	AddObject("Constant.DataAreaPrefix", Exceptions);
	AddObject("Constant.DataAreasUpdatePriority", Exceptions);
	AddObject("Constant.FileTransferBlockSize", Exceptions);
	AddObject("Constant.AllowScheduledJobsExecutionSaaS", Exceptions);
	AddObject("Constant.InfobaseUsageMode", Exceptions);
	AddObject("Constant.LockMessageOnConfigurationUpdate", Exceptions);
	AddObject("Constant.DataAreaTimeZone", Exceptions);
	AddObject("Catalog.JobsQueue", Exceptions);
	AddObject("Catalog.SuppliedData", Exceptions);
	AddObject("Catalog.SuppliedAdditionalReportsAndDataProcessors", Exceptions);
	AddObject("Catalog.DataAreaMessages", Exceptions);
	AddObject("Catalog.QueueJobTemplates", Exceptions);
	AddObject("InformationRegister.DataAreasSubsystemsVersions", Exceptions);
	AddObject("InformationRegister.UseSuppliedAdditionalReportsAndProcessorsInDataAreas", Exceptions);
	AddObject("InformationRegister.UseAdditionalReportsAndServiceProcessorsAtStandaloneWorkstation", Exceptions);
	AddObject("InformationRegister.DataAreas", Exceptions);
	AddObject("InformationRegister.TextExtractionQueue", Exceptions);
	AddObject("InformationRegister.SuppliedAdditionalReportAndDataProcessorInstallationQueueInDataArea", Exceptions);
	AddObject("InformationRegister.SuppliedDataRequiringProcessing", Exceptions);
	AddObject("InformationRegister.DataAreaActivityRating", Exceptions);
	
	// StandardSubsystems.SaaS.AddInsSaaS
	AddObject("Catalog.CommonAddIns", Exceptions);
	
	// StandardSubsystems.SaaS.DataExchangeSaaS
	AddObject("Constant.DataChangesRecorded", Exceptions);
	AddObject("Constant.UseOfflineModeSaaS", Exceptions);
	AddObject("Constant.UseDataSynchronizationSaaS", Exceptions);
	AddObject("Constant.UseDataSynchronizationSaaSWithLocalApplication", Exceptions);
	AddObject("Constant.UseDataSynchronizationSaaSWithWebApplication", Exceptions);
	AddObject("Constant.LastStandaloneWorkstationPrefix", Exceptions);
	AddObject("Constant.SynchronizeDataWithInternetApplicationsOnExit", Exceptions);
	AddObject("Constant.SynchronizeDataWithInternetApplicationsOnStart", Exceptions);
	AddObject("InformationRegister.DataAreasExchangeTransportSettings", Exceptions);
	AddObject("InformationRegister.DataAreaExchangeTransportSettings", Exceptions);
	AddObject("InformationRegister.SystemMessageExchangeSessions", Exceptions);
	AddObject("InformationRegister.DataAreasDataExchangeMessages", Exceptions);
	AddObject("InformationRegister.DataAreaDataExchangeStates", Exceptions);
	AddObject("InformationRegister.DataAreasSuccessfulDataExchangeStates", Exceptions);
	
	// StandardSubsystems.StoredFiles
	AddObject("InformationRegister.FileWorkingDirectories", Exceptions);
	AddObject("InformationRegister.FilesInWorkingDirectory", Exceptions);
	AddObject("Constant.ExtractTextFilesOnServer", Exceptions);
	AddObject("Constant.StoreFilesInVolumesOnHardDrive", Exceptions);
	AddObject("Constant.SynchronizeFiles", Exceptions);
	AddObject("Constant.FilesStorageMethod", Exceptions);
	AddObject("Constant.VolumePathIgnoreRegionalSettings", Exceptions);
	AddObject("Constant.ParametersOfFilesStorageInIB", Exceptions);
	AddObject("Constant.CreateSubdirectoriesWithOwnersNames", Exceptions);
	AddObject("Constant.FilesCleanupMode", Exceptions);
	AddObject("Catalog.FileStorageVolumes", Exceptions);
	AddObject("Catalog.FileSynchronizationAccounts", Exceptions);
	AddObject("InformationRegister.ScannedFilesNumbers", Exceptions);
	AddObject("InformationRegister.FilesSynchronizationWithCloudServiceStatuses", Exceptions);
	AddObject("InformationRegister.FileSynchronizationSettings", Exceptions);
	
	AddAllSubsystemObjects("ReportMailing", Exceptions);
	
	// StandardSubsystems.ScheduledJobs
	AddObject("Constant.ExternalResourceAccessLockParameters", Exceptions);
	
	// StandardSubsystems.IBBackup
	AddObject("Constant.BackupParameters", Exceptions);
	
	SubsystemDoesNotContainObjects("SubordinationStructure");
	SubsystemDoesNotContainObjects("ToDoList");
	
	// StandardSubsystems.MarkedObjectsDeletion
	AddObject("Constant.CheckIfObjectsToDeleteAreUsed", Exceptions);
	AddObject("InformationRegister.ObjectsToDelete", Exceptions);
	AddObject("InformationRegister.NotDeletedObjects", Exceptions);
	
	// StandardSubsystems.AccessManagement
	AddObject("Constant.LastAccessUpdate", Exceptions);
	AddObject("Constant.AccessUpdateThreadsCount", Exceptions);
	AddObject("InformationRegister.UsersAccessKeysCurrentJobs", Exceptions);
	
	// StandardSubsystems.TotalsAndAggregatesManagement
	AddObject("Constant.TotalsAndAggregatesParameters", Exceptions);
	
	AddAllSubsystemObjects("MonitoringCenter", Exceptions);
	
	// StandardSubsystems.DigitalSignature
	AddObject("Constant.CryptoErrorsClassifier", Exceptions);
	AddObject("Constant.VerifyDigitalSignaturesOnTheServer", Exceptions);
	AddObject("Constant.GenerateDigitalSignaturesAtServer", Exceptions);
	AddObject("Constant.LatestErrorsClassifierUpdateDate", Exceptions);
	AddObject("InformationRegister.PathsToDigitalSignatureAndEncryptionApplicationsOnLinuxServers", Exceptions);
	AddObject("InformationRegister.CertificateRevocationLists", Exceptions);
	
	
	Return Exceptions;
	
EndFunction

// Contains a list of objects excluded from a full DIB exchange plan (including a standalone workstation).
//
Function RIBExchangePlanFullAdditionalExclusionObjects()
	
	Objects = New Array;
	
	// DataExchange
	AddObject("Constant.DataForDeferredUpdate", Objects);
	
	Return Objects;
	
EndFunction

// Contains a list of objects excluded from a full DIB exchange plan (including a standalone workstation).
//
Function RIBExchangePlanFilterAdditionalExclusionObjects()
	
	Objects = New Array;
	
	AddObjectsOnlyForFullRIBAndOnlyForInitialImage(Objects);
	
	Return Objects;
	
EndFunction

// Contains a list of objects excluded from SWP exchange plans.
//
Function ARMExchangePlanAdditionalExclusionObjects()
	
	Exceptions = New Array;
	
	// Subsystems that don't support SaaS.
	AddAllSubsystemObjects("UserMonitoring", Exceptions);
	AddAllSubsystemObjects("ConfigurationUpdate", Exceptions);
	AddAllSubsystemObjects("SoftwareLicenseCheck", Exceptions);
	AddAllSubsystemObjects("ScheduledJobs", Exceptions);
	AddAllSubsystemObjects("IBBackup", Exceptions);
	AddAllSubsystemObjects("TotalsAndAggregatesManagement", Exceptions);
	
	Return Exceptions;
	
EndFunction

// Contains a list of objects whose presence in DIB exchange plans is determined by the subsystem scenario.
// These objects can be included in or excluded from an exchange plan.
// Therefore, their inclusion in the exchange plans is not checked.
//
Function VariablyIncludedInRIBObjects()
	
	Objects = New Array;
	
	// BusinessProcessesAndTasks
	AddObject("Constant.NewTasksNotificationDate", Objects);
	
	AddAllSubsystemObjects("PerformanceMonitor", Objects);
	
	Return Objects;
	
EndFunction

// Contains a list of objects that are included only in the initial image of DIB exchange plans.
// That is, the object is included in the exchange plan and excluded from subscriptions.
//
Function ObjectsOnlyForAnyRIBInitialImage()
	
	Objects = New Array;
	
	// StandardSubsystems.Core
	AddObject("InformationRegister.ApplicationRuntimeParameters", Objects);
	
	// StandardSubsystems.InformationOnStart
	AddObject("InformationRegister.InformationPackagesOnStart", Objects);
	
	// StandardSubsystems.DataExchange
	AddObject("Constant.SubordinateDIBNodeSettings", Objects);
	
	// StandardSubsystems.IBVersionUpdate
	AddObject("Constant.WriteIBUpdateDetailsToEventLog", Objects);
	AddObject("Constant.DeferredUpdateCompletedSuccessfully", Objects);
	AddObject("Constant.OrderOfDataToProcess", Objects);
	AddObject("Constant.LockedObjectsInfo", Objects);
	AddObject("Constant.IBUpdateInfo", Objects);
	AddObject("InformationRegister.SubsystemsVersions", Objects);
	AddObject("InformationRegister.UpdateHandlers", Objects);
	
	// StandardSubsystems.FullTextSearch
	AddObject("Constant.UseFullTextSearch", Objects);
	
	// StandardSubsystems.Users
	AddObject("InformationRegister.UserGroupsHierarchy", Objects);
	AddObject("InformationRegister.UserGroupCompositions", Objects);
	
	// StandardSubsystems.StoredFiles
	AddObject("InformationRegister.DeleteFilesBinaryData", Objects);
	AddObject("InformationRegister.DeleteStoredVersionFiles", Objects);
	AddObject("InformationRegister.FileRepository", Objects);
	AddObject("Catalog.BinaryDataStorage", Objects);
	
	// StandardSubsystems.AccessManagement
	AddObject("Constant.FirstAccessUpdateCompleted", Objects);
	AddObject("InformationRegister.RolesRights", Objects);
	AddObject("InformationRegister.AccessRightsDependencies", Objects);
	AddObject("InformationRegister.AccessValuesGroups", Objects);
	AddObject("InformationRegister.AccessGroupsTables", Objects);
	AddObject("InformationRegister.AccessGroupsValues", Objects);
	AddObject("InformationRegister.DefaultAccessGroupsValues", Objects);
	AddObject("InformationRegister.AccessRestrictionParameters", Objects);
	AddObject("InformationRegister.UsedAccessKindsByTables", Objects);
	
	// StandardSubsystems.SaaS.DataExchangeSaaS
	AddObject("Constant.AccountPasswordRecoveryAddress", Objects);
	
	Return Objects;
	
EndFunction

// Contains a list of objects that are included only in the initial image of DIB (including standalone workstations) exchange plans.
// That is, the object is included in the exchange plan and excluded from subscriptions.
//
Function AdditionalObjectsOnlyForRIBInitialImageFull()
	
	Objects = New Array;
	
	AddObjectsOnlyForFullRIBAndOnlyForInitialImage(Objects);
	
	Return Objects;
	
EndFunction

Procedure AddObjectsOnlyForFullRIBAndOnlyForInitialImage(Objects)
	
	// StandardSubsystems.AccessManagement
	AddObject("Catalog.AccessKeys", Objects);
	AddObject("Catalog.SetsOfAccessGroups", Objects);
	AddObject("InformationRegister.ExternalUsersAccessKeys", Objects);
	AddObject("InformationRegister.AccessGroupsAccessKeys", Objects);
	AddObject("InformationRegister.AccessGroupSetsAccessKeys", Objects);
	AddObject("InformationRegister.AccessKeysForObjects", Objects);
	AddObject("InformationRegister.AccessKeysForRegisters", Objects);
	AddObject("InformationRegister.UsersAccessKeys", Objects);
	AddObject("InformationRegister.DataAccessKeysUpdate", Objects);
	AddObject("InformationRegister.UsersAccessKeysUpdate", Objects);
	For Each InformationRegister In Metadata.InformationRegisters Do
		If StrStartsWith(InformationRegister.Name, "AccessKeysToRegister") Then
			AddObject(InformationRegister.FullName(), Objects);
		EndIf;
	EndDo;
	
EndProcedure

// Contains a list of objects that are included only in the initial image of DIB exchange plans with filters (including standalone workstations).
// That is, the object is included in the exchange plan and excluded from subscriptions.
//
Function AdditionalObjectsOnlyForRIBInitialImageWithFilter()
	
	Objects = New Array;
	
	Return Objects;
	
EndFunction

// Contains a list of objects that are included only in the initial image of standalone workstations exchange plans.
// That is, the object is included in the exchange plan and excluded from subscriptions.
//
Function AdditionalObjectsOnlyForARMInitialImage()
	
	Objects = New Array;
	
	// StandardSubsystems.AdditionalReportsAndDataProcessors
	AddObject("Constant.UseAdditionalReportsAndDataProcessors", Objects);
	
	Return Objects;
	
EndFunction

Function MandatoryExchangePlanManagerModuleProcedures(ExchangePlanName)
	
	MandatoryProcedures = New Array;
	
	MandatoryProcedures.Add("Procedure OnGetSettings(Settings) Export");
	
	Return MandatoryProcedures;
	
EndFunction

Function ExchangePlanManagerModuleUnnecessaryProcedures(ExchangePlanName)
	UnnecessaryProcedures = New Array;
	
	UnnecessaryProcedures.Add("Procedure DefineSettings(");
	UnnecessaryProcedures.Add("Function ExchangePlanUsedInSaaS() Export");
	UnnecessaryProcedures.Add("Function CorrespondentInSaaS() Export");
	UnnecessaryProcedures.Add("Function BriefExchangeInfo(SettingID = "") Export");
	UnnecessaryProcedures.Add("Function DetailedExchangeInformation(SettingID = "") Export");
	UnnecessaryProcedures.Add("Function SettingsFileNameForDestination() Export");
	UnnecessaryProcedures.Add("Function UseDataExchangeCreationWizard() Export");
	UnnecessaryProcedures.Add("Function InitialImageCreationFormName() Export");
	UnnecessaryProcedures.Add("Function UsedExchangeMessagesTransports() Export");
	UnnecessaryProcedures.Add("Function CommonNodeData(CorrespondentVersion, FormName) Export");
	UnnecessaryProcedures.Add("Function SourceConfigurationName() Export");
	UnnecessaryProcedures.Add("Function NodeFiltersSetting(CorrespondentVersion, FormName, SettingID = "") Export");
	UnnecessaryProcedures.Add("Function DefaultNodeValues(CorrespondentVersion, FormName, SettingID = "") Export");
	UnnecessaryProcedures.Add("Function CorrespondentInfobaseNodeFilterSetup(CorrespondentVersion, FormName, SettingID = "") Export");
	UnnecessaryProcedures.Add("Function DefaultValuesForCorrespondentInfobaseNode(CorrespondentVersion, FormName, SettingID = "") Export");
	UnnecessaryProcedures.Add("Function AccountingSettingsSetupNote() Export");
	UnnecessaryProcedures.Add("Function CorrespondentDatabaseAccountingSettingParametersExplanation(CorrespondentVersion) Export");
	UnnecessaryProcedures.Add("Function ExchangePlanNameToMigrateToNewExchange() Export");
	UnnecessaryProcedures.Add("Function ExchangeFormat() Export");
	UnnecessaryProcedures.Add("Function GetExchangeFormatVersions() Export");
	UnnecessaryProcedures.Add("Function InitialImageCreationFormName() Export");
	UnnecessaryProcedures.Add("Function GetAdditionalDataForCorrespondent(");

	Return UnnecessaryProcedures;
EndFunction

#EndRegion

#Region IBVersionUpdate

Procedure CheckIfDeferredHandlersPropertiesValid()
	
	VerificationHandlers = New ValueTable;
	VerificationHandlers.Columns.Add("Handler");
	VerificationHandlers.Columns.Add("Library");
	VerificationHandlers.Columns.Add("ItemsToRead");
	VerificationHandlers.Columns.Add("Editable1");
	VerificationHandlers.Columns.Add("Queue");
	VerificationHandlers.Columns.Add("Priorities");
	
	ExchangePlanContent = New Map;
	For Each ExchangePlanItem In Metadata.ExchangePlans.InfobaseUpdate.Content Do
		ExchangePlanContent.Insert(ExchangePlanItem.Metadata.FullName(), ExchangePlanItem.AutoRecord);
	EndDo;
	
	// Validate deferred handler properties.
	SubsystemsDetails  = StandardSubsystemsCached.SubsystemsDetails();
	For Each SubsystemName In SubsystemsDetails.Order Do
		
		SubsystemDetails = SubsystemsDetails.ByNames[SubsystemName];
		If Not ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		
		DeferredHandlersExecutionMode = SubsystemDetails.DeferredHandlersExecutionMode;
		ParallelSinceVersion = SubsystemDetails.ParallelDeferredUpdateFromVersion;
		
		Module = Common.CommonModule(SubsystemDetails.MainServerModule);
		Handlers = InfobaseUpdate.NewUpdateHandlerTable();
		Module.OnAddUpdateHandlers(Handlers);
		
		FilterParameters = New Structure;
		FilterParameters.Insert("ExecutionMode", "Deferred");
		
		DeferredHandlers = Handlers.FindRows(FilterParameters);
		For Each Handler In DeferredHandlers Do
			
			IdentifiedErrors = New Array;
			If Not ValueIsFilled(Handler.Comment) Then
				ErrorText = NStr("ru = 'У отложенного обработчика ""%1"" не заполнено свойство ""Комментарий""';
									|en = 'The Comment property is not filled in deferred handler %1';");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Handler.Procedure);
				IdentifiedErrors.Add(ErrorText);
			EndIf;
			
			If Not ValueIsFilled(Handler.Id) Then
				ErrorText = NStr("ru = 'Рекомендуется заполнить свойство ""Идентификатор"" отложенного обработчика ""%1""';
									|en = 'Fill in ID of deferred handler %1';");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Handler.Procedure);
				IdentifiedErrors.Add(ErrorText);
			EndIf;
			
			If DeferredHandlersExecutionMode = "Parallel" And Not (Handler.Version = "*"
					Or (ValueIsFilled(ParallelSinceVersion)
						And CommonClientServer.CompareVersions(Handler.Version, ParallelSinceVersion) < 0)) Then
						
				CheckParallelDeferredHandler(Handler, ExchangePlanContent, VerificationHandlers, IdentifiedErrors, SubsystemName);
			EndIf;
			
			// Log found errors.
			If ValueIsFilled(IdentifiedErrors) Then
				FullObjectName = FullNameOfMetadataObjectsFromUpdateHandlerProcedure(Handler.Procedure);
				
				ErrorTextLine = "";
				For Each ErrorText In IdentifiedErrors Do
					If Not ValueIsFilled(ErrorTextLine) Then
						ErrorTextLine = ErrorText;
					Else
						ErrorTextLine = ErrorTextLine + Chars.LF + Chars.LF + ErrorText;
					EndIf;
				EndDo;
				
				AddError(Common.MetadataObjectByFullName(FullObjectName),
					NStr("ru = 'Некорректно заполнены свойства отложенного обработчика';
						|en = 'Deferred handler properties are filled in incorrectly';"),
					ErrorTextLine);
			EndIf;
			
		EndDo;
		
	EndDo;
		
EndProcedure

Procedure CheckParallelDeferredHandler(Val Handler, Val ExchangePlanContent, VerificationHandlers, IdentifiedErrors, SubsystemName)
	
	UpdateHandlerObjectFullName = FullNameOfMetadataObjectsFromUpdateHandlerProcedure(Handler.Procedure);
	ArrayOfHandlerObjectPathItems = StrSplit(UpdateHandlerObjectFullName, ".");
	MetadataObjectsContainingData            = MetadataObjectsContainingData();
	
	HandlerMetadataObjectType = ArrayOfHandlerObjectPathItems[0];
	HandlerInTableBeingUpdated   = MetadataObjectsContainingData.Find(HandlerMetadataObjectType) <> Undefined;
	
	If Common.MetadataObjectByFullName(UpdateHandlerObjectFullName) = Undefined Then
		
		ErrorText = NStr("ru = 'У отложенного обработчика ""%1"" некорректно заполнено свойство ""%2"":';
							|en = 'Property ""%2"" of deferred handler ""%1"" is filled in incorrectly';");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Handler.Procedure, "Procedure")
			+ Chars.LF
			+ NStr("ru = '- не найден объект';
					|en = '- object is not found';") + " " + UpdateHandlerObjectFullName;
		RegisterAHandlerError(IdentifiedErrors, ErrorText, Handler.Procedure);
		
	Else
		
		If HandlerInTableBeingUpdated Then
			
			RegistrationState = ExchangePlanContent[UpdateHandlerObjectFullName];
			If RegistrationState = Undefined Then
				ErrorText = NStr("ru = 'Объект ""%1"", содержащий процедуру отложенного обработчика ""%2"", не входит
					|в состав плана обмена %3.';
					|en = 'The ""%1"" object containing the ""%2"" deferred handler procedure is not included
					|in the ""%3"" exchange plan.';");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, UpdateHandlerObjectFullName,
					Handler.Procedure, "InfobaseUpdate");
				RegisterAHandlerError(IdentifiedErrors, ErrorText, Handler.Procedure);
			ElsIf RegistrationState = AutoChangeRecord.Allow Then
				ErrorText = NStr("ru = 'Для объекта ""%1"", содержащего отложенный обработчик ""%2"", некорректно
					|установлено свойство %3 в плане обмена %4 (должно быть ""Запрещать"").';
					|en = 'For the ""%1"" object containing the ""%2"" deferred handler, the %3 property
					|in the %4 exchange plan is set incorrectly (it must be ""Restrict"").';");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, UpdateHandlerObjectFullName,
					Handler.Procedure, "AutoRecord", "InfobaseUpdate");
				RegisterAHandlerError(IdentifiedErrors, ErrorText, Handler.Procedure);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	NonExistentObjects = "";
	NotIncludedInExchangePlan = "";
	IncorrectlyIncludedInExchangePlan = "";
	ObjectsToRead = New Array;
	
	If Not ValueIsFilled(Handler.ObjectsToRead) And Not HandlerInTableBeingUpdated Then
		ErrorText = NStr("ru = 'У отложенного обработчика ""%1"" не заполнено свойство ""%2""';
							|en = 'Property ""%2"" of deferred handler ""%1"" is not filled in';");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Handler.Procedure, "ObjectsToRead");
		RegisterAHandlerError(IdentifiedErrors, ErrorText, Handler.Procedure);
	Else
		ObjectsToRead = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Handler.ObjectsToRead, ",", , True);
		For Each ObjectToRead In ObjectsToRead Do
			ObjectNotExist = Common.MetadataObjectByFullName(ObjectToRead) <> Undefined;
			If Not ObjectNotExist Then
				NonExistentObjects =  NonExistentObjects + ?(NonExistentObjects = "", "", Chars.LF)
				+ NStr("ru = '- не найден объект';
						|en = '- object is not found';") + " " + ObjectToRead;
			Else
				If StrFind(ObjectToRead, "ScheduledJob.") > 0
					Or StrFind(ObjectToRead, "ExchangePlan.") > 0 Then
					Continue;
				EndIf;
				RegistrationState = ExchangePlanContent[ObjectToRead];
				If RegistrationState = Undefined Then
					NotIncludedInExchangePlan =  NotIncludedInExchangePlan + ?(NotIncludedInExchangePlan = "", "", Chars.LF)
						+ "- " + ObjectToRead;
				ElsIf RegistrationState = AutoChangeRecord.Allow Then
					IncorrectlyIncludedInExchangePlan = IncorrectlyIncludedInExchangePlan + ?(IncorrectlyIncludedInExchangePlan = "", "", Chars.LF)
						+ "- " + ObjectToRead;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	If ValueIsFilled(NonExistentObjects) Then
		ErrorText = NStr("ru = 'У отложенного обработчика ""%1"" некорректно заполнено свойство ""%2"":';
							|en = 'Property ""%2"" of deferred handler ""%1"" is filled in incorrectly';");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Handler.Procedure, "ObjectsToRead")
			+ Chars.LF + NonExistentObjects;
		RegisterAHandlerError(IdentifiedErrors, ErrorText, Handler.Procedure);
	EndIf;
	
	ErrorText = "";
	If ValueIsFilled(NotIncludedInExchangePlan) Then
		ErrorText = NStr("ru = 'Следующие читаемые объекты отложенного обработчика ""%1"" не входят
			|в состав плана обмена %2:';
			|en = 'The following objects to be read of deferred handler ""%1"" do not belong to
			|exchange plan %2:';");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Handler.Procedure, "InfobaseUpdate");
		ErrorText = ErrorText + Chars.LF + NotIncludedInExchangePlan;
	EndIf;
	RegisterAHandlerError(IdentifiedErrors, ErrorText, Handler.Procedure);
	
	If ValueIsFilled(IncorrectlyIncludedInExchangePlan) Then
		ErrorText = NStr("ru = 'Для следующих читаемых объектов отложенного обработчика ""%1"" некорректно
			|установлено свойство %2 в плане обмена %3 (должно быть ""Запрещать""):';
			|en = 'For the following objects to be read of deferred handler ""%1"",
			|property %2 is set incorrectly in exchange plan %3 (""Restrict"" must be set):';");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Handler.Procedure, "AutoRecord", "InfobaseUpdate")
			+ Chars.LF + IncorrectlyIncludedInExchangePlan;
		RegisterAHandlerError(IdentifiedErrors, ErrorText, Handler.Procedure);
	EndIf;
	
	ErrorText        = "";
	NonExistentObjects = "";
	NotIncludedInExchangePlan = "";
	IncorrectlyIncludedInExchangePlan = "";
	ObjectsToChange = New Array;
	If Not ValueIsFilled(Handler.ObjectsToChange) Then
		ErrorText = NStr("ru = 'У отложенного обработчика ""%1"" не заполнено свойство ""%2""';
							|en = 'Property ""%2"" of deferred handler ""%1"" is not filled in';");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Handler.Procedure, "ObjectsToChange");
		RegisterAHandlerError(IdentifiedErrors, ErrorText, Handler.Procedure);
	Else
		ObjectsToChange = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Handler.ObjectsToChange, 
			",", , True);
		For Each ObjectToChange In ObjectsToChange Do
			If StrCompare(ObjectToChange, "CollaborationSystemUser") = 0 Then
				Continue;
			EndIf;
			ObjectNotExist = Common.MetadataObjectByFullName(ObjectToChange) <> Undefined;
			If Not ObjectNotExist Then
				NonExistentObjects = NonExistentObjects + ?(NonExistentObjects = "", "", Chars.LF)
					+ NStr("ru = '- несуществующий объект метаданных';
							|en = '- non-existing metadata object';") + " " + ObjectToChange;
				Continue;
			EndIf;
			If StrFind(ObjectToChange, "ScheduledJob.") > 0
				Or StrFind(ObjectToChange, "ExchangePlan.") > 0 Then
				Continue;
			EndIf;
			RegistrationState = ExchangePlanContent[ObjectToChange];
			If RegistrationState = Undefined Then
				NotIncludedInExchangePlan =  NotIncludedInExchangePlan + ?(NotIncludedInExchangePlan = "", "", Chars.LF)
				+ "- " + ObjectToChange;
			ElsIf RegistrationState = AutoChangeRecord.Allow Then
				IncorrectlyIncludedInExchangePlan =  IncorrectlyIncludedInExchangePlan + ?(IncorrectlyIncludedInExchangePlan = "", "", Chars.LF)
				+ "- " + ObjectToChange;
			EndIf;
		EndDo;
	EndIf;
	
	If ValueIsFilled(NonExistentObjects) Then
		ErrorText = NStr("ru = 'У отложенного обработчика ""%1"" некорректно заполнено свойство ""%2"":';
							|en = 'Property ""%2"" of deferred handler ""%1"" is filled in incorrectly';");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Handler.Procedure, "ObjectsToRead")
			+ Chars.LF + NonExistentObjects;
		RegisterAHandlerError(IdentifiedErrors, ErrorText, Handler.Procedure);
	EndIf;
	
	If ValueIsFilled(NotIncludedInExchangePlan) Then
		ErrorText = NStr("ru = 'Следующие изменяемые объекты отложенного обработчика ""%1"" не входят
			|в состав плана обмена %2:';
			|en = 'The following objects to be changed of deferred handler ""%1"" do not belong to
			|exchange plan %2:';");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Handler.Procedure, "InfobaseUpdate")
			+ Chars.LF + NotIncludedInExchangePlan;
		RegisterAHandlerError(IdentifiedErrors, ErrorText, Handler.Procedure);
	EndIf;
	
	If ValueIsFilled(IncorrectlyIncludedInExchangePlan) Then
		ErrorText = NStr("ru = 'Для следующих изменяемых объектов отложенного обработчика ""%1"" некорректно
			|установлено свойство %2 в плане обмена %3 (должно быть ""Запрещать""):';
			|en = 'For the following objects to be read of deferred handler ""%1"",
			|property %2 is set incorrectly in exchange plan %3(""Restrict"" must be set):';");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Handler.Procedure,
			"AutoRecord", "InfobaseUpdate") + Chars.LF + IncorrectlyIncludedInExchangePlan;
		RegisterAHandlerError(IdentifiedErrors, ErrorText, Handler.Procedure);
	EndIf;
	
	// Handlers for the following conflict check.
	If ObjectsToRead.Count() > 0 Or ObjectsToChange.Count() > 0 Then
		String = VerificationHandlers.Add();
		String.Handler = Handler.Procedure;
		String.Library = SubsystemName;
		String.ItemsToRead   = ObjectsToRead;
		String.Editable1 = ObjectsToChange;
		String.Queue    = Handler.DeferredProcessingQueue;
		String.Priorities = Handler.ExecutionPriorities;
	EndIf;
	
EndProcedure

Procedure RegisterAHandlerError(ErrorsFullText, ErrorText, ProcedureName)
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, ProcedureName);
	If ValueIsFilled(ErrorText) Then
		ErrorsFullText.Add(ErrorText);
	EndIf;
	
EndProcedure

Function MetadataTypesMap(ManagerName)
	
	If MetadataTypesMap = Undefined Then
		MetadataTypesMap = New Map;
		MetadataTypesMap.Insert("Constants", "Constant");
		MetadataTypesMap.Insert("Catalogs", "Catalog");
		MetadataTypesMap.Insert("Documents", "Document");
		MetadataTypesMap.Insert("DocumentJournals", "DocumentJournal");
		MetadataTypesMap.Insert("Enums", "Enum");
		MetadataTypesMap.Insert("Reports", "Report");
		MetadataTypesMap.Insert("DataProcessors", "DataProcessor");
		MetadataTypesMap.Insert("ChartsOfCharacteristicTypes", "ChartOfCharacteristicTypes");
		MetadataTypesMap.Insert("ChartsOfAccounts", "ChartOfAccounts");
		MetadataTypesMap.Insert("ExchangePlans", "ExchangePlan");
		MetadataTypesMap.Insert("ChartsOfCalculationTypes", "ChartOfCalculationTypes");
		MetadataTypesMap.Insert("InformationRegisters", "InformationRegister");
		MetadataTypesMap.Insert("AccumulationRegisters", "AccumulationRegister");
		MetadataTypesMap.Insert("AccountingRegisters", "AccountingRegister");
		MetadataTypesMap.Insert("CalculationRegisters", "CalculationRegister");
		MetadataTypesMap.Insert("BusinessProcesses", "BusinessProcess");
		MetadataTypesMap.Insert("Tasks", "Task");
	EndIf;

	// Search by key.
	Result = MetadataTypesMap[ManagerName];
	If Result <> Undefined Then
		Return Result;
	EndIf;
	
	// Case-insensitive search for a key-value pair.
	For Each Item In MetadataTypesMap Do
		If StrCompare(Item.Key, ManagerName) = 0 Then
			Return Item.Value;
		EndIf;
		If StrCompare(Item.Value, ManagerName) = 0 Then
			Return Item.Key;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

Function MetadataObjectsContainingData()
	
	MetadataObjectsContainingData = New Array;
	MetadataObjectsContainingData.Add("Constant");
	MetadataObjectsContainingData.Add("Catalog");
	MetadataObjectsContainingData.Add("Document");
	MetadataObjectsContainingData.Add("ChartOfCharacteristicTypes");
	MetadataObjectsContainingData.Add("ChartOfAccounts");
	MetadataObjectsContainingData.Add("ChartOfCalculationTypes");
	MetadataObjectsContainingData.Add("InformationRegister");
	MetadataObjectsContainingData.Add("AccumulationRegister");
	MetadataObjectsContainingData.Add("AccountingRegister");
	MetadataObjectsContainingData.Add("CalculationRegister");
	MetadataObjectsContainingData.Add("BusinessProcess");
	MetadataObjectsContainingData.Add("Task");
	
	Return MetadataObjectsContainingData;
	
EndFunction

Function FullNameOfMetadataObjectsFromUpdateHandlerProcedure(ProcedureName)
	
	ProcedureInPartsName = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ProcedureName, ".");
	If ProcedureInPartsName.Count() = 2 Then
		FullObjectName = "CommonModule" + "." + ProcedureInPartsName[0];
	Else
		FullObjectName = MetadataTypesMap(ProcedureInPartsName[0]) + "." + ProcedureInPartsName[1];
	EndIf;
	
	Return FullObjectName;
	
EndFunction

Procedure CheckIfDeferredHandlersHaveSharedChangeableObjects()
	
	// ACC:326-off - The transaction is not committed (for testing purposes).
	BeginTransaction();
	Try
		BriefErrorDetails = NStr("ru = 'Некорректный отложенный обработчик обновления';
									|en = 'Invalid deferred update handler';");
		
		SharedDataComposition = New Map;
		FillSharedDataCompositionByCommonAttributes(SharedDataComposition);
		
		ToggleSeparation(True);
		
		UpdateHandlers = UpdateIterations();
		If UpdateHandlers = Undefined Then
			Return;
		EndIf;
		
		ToggleSeparation(False);
		
		If UpdateHandlers.Count() = 0 Then
			DetailedErrorDetails = NStr("ru = 'Не удалось получить информацию об обработчиках обновления.';
											|en = 'Cannot get information on update handlers.';");
			AddError(Undefined, BriefErrorDetails, DetailedErrorDetails);
			Return;
		EndIf;
		
		MetadataObjectsContainingData = MetadataObjectsContainingData();
		
		UpdateHandlersFieldsToPassToErrors = UpdateHandlersFieldsToPassToErrors();
		
		FilterParameters = New Structure;
		FilterParameters.Insert("ExecutionMode", "Deferred");
		
		UpdateHandlersDeferred = UpdateHandlers.Copy(FilterParameters);
		For Each HandlerUpdates In UpdateHandlersDeferred Do
			
			UpdateHandlerInformation = ValueTableRowToString(HandlerUpdates,,, UpdateHandlersFieldsToPassToErrors);
			
			ArrayOfSharedChangeableObjects = New Array;
			
			ArrayOfChangeableObjects = StrSplit(HandlerUpdates.ObjectsToChange, ",", False);
			For Each ObjectToChange In ArrayOfChangeableObjects Do
				
				ChangeableObjectString = TrimAll(ObjectToChange);
				MetadataObjectToChange = Common.MetadataObjectByFullName(ChangeableObjectString);
				If MetadataObjectToChange = Undefined Then
					// Skip the handler if the metadata object doesn't exist.
					// The existence check is performed in the procedure "CheckParallelDeferredHandler".
					Continue;
				EndIf;
				
				If SharedDataComposition[MetadataObjectToChange] = Undefined Then
					ArrayOfSharedChangeableObjects.Add(ChangeableObjectString);
				EndIf;
				
			EndDo;
			
			UpdateHandlerProcedure = TrimAll(HandlerUpdates.Procedure);
			MetadataObjectFromUpdateProcedure = MetadataObjectFromUpdateHandlerProcedure(UpdateHandlerProcedure);
			
			If ArrayOfSharedChangeableObjects.Count() > 0 Then
				
				DetailedErrorDetails = NStr(
					"ru = 'Отложенный обработчик обновления изменяет неразделенные объекты метаданных:
					|%1.
					|
					|Подробная информация об обработчике:
					|%2';
					|en = 'The deferred update handler changes the shared metadata objects:
					|%1.
					|
					|Detailed handler information:
					|%2';");
				
				DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
					DetailedErrorDetails,
					StrConcat(ArrayOfSharedChangeableObjects, Chars.LF),
					UpdateHandlerInformation);
				
				AddError(MetadataObjectFromUpdateProcedure, BriefErrorDetails, DetailedErrorDetails);
				
			EndIf;
			
			UpdateHandlerProcedureItemsArray = StrSplit(UpdateHandlerProcedure, ".", False);
			
			HandlerMetadataObjectType = UpdateHandlerProcedureItemsArray[0];
			If MetadataObjectsContainingData.Find(HandlerMetadataObjectType) = Undefined Then
				// If the metadata object has no data, it cannot be included in a separator. Skip it.
				Continue;
			EndIf;
			
			ProcedureName = UpdateHandlerProcedureItemsArray[UpdateHandlerProcedureItemsArray.UBound()];
			
			// Check that the update handler procedure is located in the manager module.
			ManagerModule = ManagerModule(MetadataObjectFromUpdateProcedure);
			ModuleProcedure = FindModuleProcedure(ManagerModule, ProcedureName);
			If ModuleProcedure = Undefined Then
				// If the update handler procedure is not located in the module manager, skip it.
				Continue;
			EndIf;
			
			// If the object from the update handler procedure is a shared object, raise an error.
			If SharedDataComposition[MetadataObjectFromUpdateProcedure] = Undefined Then
				
				DetailedErrorDetails = NStr(
					"ru = 'У отложенного обработчика обновления указан неразделенный объект метаданных в процедуре из модуля менеджера:
					|%1
					|
					|Подробная информация об обработчике:
					|%2';
					|en = 'The deferred update handler has a shared metadata object specified in the manager module procedure:
					|%1
					|
					|Detailed handler information:
					|%2';");
				
				DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
					DetailedErrorDetails,
					UpdateHandlerProcedure,
					UpdateHandlerInformation);
				
				AddError(MetadataObjectFromUpdateProcedure, BriefErrorDetails, DetailedErrorDetails);
				
			EndIf;
			
		EndDo;
		RollbackTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	// ACC:326-on
	
EndProcedure

Function MetadataObjectFromUpdateHandlerProcedure(Val FullProcedureName)
	
	If IsBlankString(FullProcedureName) Then
		Return Undefined;
	EndIf;
	
	FullMetadataObjectName = FullNameOfMetadataObjectsFromUpdateHandlerProcedure(FullProcedureName);
	FullMetadataObjectName = TrimAll(FullMetadataObjectName);
	
	MetadataObject = Common.MetadataObjectByFullName(FullMetadataObjectName);
	
	Return MetadataObject;
	
EndFunction

Function UpdateIterations()
	
	UpdateIterations = New ValueTable;
	UpdateIterations.Columns.Add("Subsystem");
	UpdateIterations.Columns.Add("DeferredHandlersExecutionMode");
	UpdateIterations.Columns.Add("ParallelDeferredUpdateFromVersion");
	UpdateIterations.Columns.Add("InitialFilling");
	UpdateIterations.Columns.Add("Version");
	UpdateIterations.Columns.Add("Procedure");
	UpdateIterations.Columns.Add("ExecutionMode");
	UpdateIterations.Columns.Add("ExecuteInMandatoryGroup");
	UpdateIterations.Columns.Add("SharedData");
	UpdateIterations.Columns.Add("HandlerManagement");
	UpdateIterations.Columns.Add("Comment");
	UpdateIterations.Columns.Add("Id");
	UpdateIterations.Columns.Add("CheckProcedure");
	UpdateIterations.Columns.Add("ObjectsToLock");
	UpdateIterations.Columns.Add("UpdateDataFillingProcedure");
	UpdateIterations.Columns.Add("DeferredProcessingQueue");
	UpdateIterations.Columns.Add("ExecuteInMasterNodeOnly");
	UpdateIterations.Columns.Add("RunAlsoInSubordinateDIBNodeWithFilters");
	UpdateIterations.Columns.Add("ObjectsToRead");
	UpdateIterations.Columns.Add("ObjectsToChange");
	UpdateIterations.Columns.Add("Priority");
	UpdateIterations.Columns.Add("ExclusiveMode");
	
	Try
		
		SubsystemsDetails = StandardSubsystemsCached.SubsystemsDetails().ByNames;
		For Each SubsystemDetails In SubsystemsDetails Do
			
			If SubsystemDetails.Key = "CloudTechnologyLibrary" Then
				Continue;
			EndIf;
			
			SubsystemDetailsValue = SubsystemDetails.Value;
			
			Handlers = InfobaseUpdate.NewUpdateHandlerTable();
			MainServerModule = SubsystemDetailsValue.MainServerModule;
			Module = Common.CommonModule(MainServerModule);
			Module.OnAddUpdateHandlers(Handlers);
			
			Subsystem_Name = SubsystemDetailsValue.Name;
			DeferredHandlersExecutionMode = SubsystemDetailsValue.DeferredHandlersExecutionMode;
			ParallelDeferredUpdateFromVersion = SubsystemDetailsValue.ParallelDeferredUpdateFromVersion;
			
			For Each Handler In Handlers Do
				
				NewRow = UpdateIterations.Add();
				FillPropertyValues(NewRow, Handler);
				
				NewRow.Subsystem = Subsystem_Name;
				NewRow.ParallelDeferredUpdateFromVersion = ParallelDeferredUpdateFromVersion;
				NewRow.DeferredHandlersExecutionMode = DeferredHandlersExecutionMode;
				
			EndDo;
			
		EndDo;
		
	Except
		DetailedErrorDetails = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		BriefErrorDetails = NStr("ru = 'Ошибка при проверке отложенных обработчиков обновления';
									|en = 'An error occurred when checking deferred update handlers';");
		ErrorDescriptionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить информацию об обработчиках обновления по причине:
				|%1';
				|en = 'Cannot get information on update handlers. Reason:
				|%1';"), DetailedErrorDetails);
		AddError(Undefined, BriefErrorDetails, ErrorDescriptionText);
		Return Undefined;
	EndTry;
	
	Return UpdateIterations;
	
EndFunction

Procedure FillSharedDataCompositionByCommonAttributes(SharedDataComposition)
	
	CommonAttributeDataSeparationDoSeparate = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate;
	
	For Each MetadataObjectCommonAttribute In Metadata.CommonAttributes Do
		If MetadataObjectCommonAttribute.DataSeparation = CommonAttributeDataSeparationDoSeparate Then
			FillSharedDataCompositionByCommonAttribute(SharedDataComposition, MetadataObjectCommonAttribute);
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillSharedDataCompositionByCommonAttribute(SharedDataComposition, MetadataObjectCommonAttribute)
	
	CommonAttributeAutoUse = MetadataObjectCommonAttribute.AutoUse;
	CommonAttributeAutoUseUse = Metadata.ObjectProperties.CommonAttributeAutoUse.Use;
	CommonAttributeAutoUseEqualToUse = (CommonAttributeAutoUse = CommonAttributeAutoUseUse);
	
	CommonAttributeUsageDoUse = Metadata.ObjectProperties.CommonAttributeUse.Use;
	CommonAttributeUsageAuto = Metadata.ObjectProperties.CommonAttributeUse.Auto;
	
	CommonAttributeContent = MetadataObjectCommonAttribute.Content;
	For Each CommonAttributeContentItem In CommonAttributeContent Do
		
		CommonAttributeUse = CommonAttributeContentItem.Use;
		If (CommonAttributeUse = CommonAttributeUsageDoUse)
		Or ((CommonAttributeUse = CommonAttributeUsageAuto) And CommonAttributeAutoUseEqualToUse) Then
			SharedDataComposition.Insert(CommonAttributeContentItem.Metadata, True);
		EndIf;
		
	EndDo;
	
EndProcedure

Function UpdateHandlersFieldsToPassToErrors()
	
	HandlersFieldsAsString =
		"Subsystem
		|DeferredHandlersExecutionMode
		|Version
		|Procedure
		|Comment
		|ObjectsToRead
		|ObjectsToChange";
	
	Return StrSplit(HandlersFieldsAsString, Chars.LF, False);
	
EndFunction

Function ValueTableRowToString(Val ValueTableRow, Val Separator = "",
	Val ShouldAddEmptyValues = True, Val ColumnsToOutputToString = Undefined)
	
	DataValueType = TypeOf(ValueTableRow);
	If (DataValueType <> Type("ValueTableRow"))
	   And (DataValueType <> Type("ValueTreeRow")) Then
		Return "";
	EndIf;
	
	If Separator = "" Then
		Separator = Chars.LF;
	EndIf;
	
	ValueTable = ValueTableRow.Owner();
	
	ArrayOfValues = New Array;
	For Each Column In ValueTable.Columns Do
		
		ColumnName = Column.Name;
		If ColumnsToOutputToString <> Undefined Then
			If ColumnsToOutputToString.Find(ColumnName) = Undefined Then
				Continue;
			EndIf;
		EndIf;
		
		CellValue = ValueTableRow[ColumnName];
		If (Not ShouldAddEmptyValues) And IsBlankString(CellValue) Then
			Continue;
		EndIf;
		
		ArrayElement = StringFunctionsClientServer.SubstituteParametersToString("%1: %2", ColumnName, CellValue);
		ArrayOfValues.Add(ArrayElement);
		
		If TypeOf(CellValue) = Type("ValueTable") Then
			For Each NestedValueTableRow In CellValue Do
				NestedCellValue = ValueTableRowToString(NestedValueTableRow);
				ArrayOfValues.Add(NestedCellValue);
			EndDo;
		EndIf;
		
	EndDo;
	
	Return StrConcat(ArrayOfValues, Separator);
	
EndFunction

#EndRegion

#Region PerformanceMonitor

Procedure ExecuteCheckKeyOperationsNaming(MetadataObject, ModuleText, MethodsArray, ModuleName)
	
	StepName = NStr("ru = 'Удельный';
					|en = 'Specific';");
	
	For Each MethodName In MethodsArray Do
		
		// Split the module text by method name.
		ModuleOccurrences = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ModuleText, MethodName, True, True);
		FirstOccurrence = True;
		For Each Entry In ModuleOccurrences Do
			
			// The first occurrence is always before the method call, ignore it.
			If FirstOccurrence Then
				FirstOccurrence = False;
				Continue;
			EndIf;
			
			// Consider that methods are always called in one string.
			OccurrenceStrings = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Entry, Chars.LF, True, True);
			
			If OccurrenceStrings.Count() Then
				ArrayOfMethodCallParameters = StringFunctionsClientServer.SplitStringIntoSubstringsArray(OccurrenceStrings[0], ",", True, True);
				// Step name is always the third parameter.
				If ArrayOfMethodCallParameters.Count() >= 3 Then
					CallStepName = Lower(ArrayOfMethodCallParameters[2]);
					If StrFind(CallStepName, Lower(StepName)) > 0 Then
						CommentTemplate = NStr("ru = 'При вызове метода %1 в модуле %2 используется недопустимое имя шага %3. Выберите другое имя шага.';
												|en = 'Upon calling the %1 method, an invalid name of the %3 step is used in the %2 module. Select another step name.';");
						CommentText1 = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, MethodName, ModuleName, StepName);
						AddError(MetadataObject, NStr("ru = 'Для имени шага ключевой операции используется имя ""Удельное""';
																|en = 'Specific name is used for a step name of the key operation';"), CommentText1);
					EndIf;					
				EndIf;				
			EndIf;
			
		EndDo;  
		
	EndDo;
	
EndProcedure

Function PerformanceEvaluationMetadataDescription()
	MetadataDetails = New Map;
	MetadataDetails.Insert("CommonModules", New Structure("Module"));
	MetadataDetails.Insert("ExchangePlans", New Structure("ManagerModule, ObjectModule, Forms, Commands"));
	MetadataDetails.Insert("FilterCriteria", New Structure("Forms, Commands"));
	MetadataDetails.Insert("SettingsStorages", New Structure("Forms"));
	MetadataDetails.Insert("CommonForms", New Structure("CommonFormModule")); 
	MetadataDetails.Insert("CommonCommands", New Structure("CommandModule"));
	MetadataDetails.Insert("WebServices", New Structure("Module"));
	MetadataDetails.Insert("HTTPServices", New Structure("Module"));
	MetadataDetails.Insert("Constants", New Structure("ValueManagerModule"));
	MetadataDetails.Insert("Catalogs", New Structure("ManagerModule, ObjectModule, Forms, Commands"));
	MetadataDetails.Insert("Documents", New Structure("ManagerModule, ObjectModule, Forms, Commands"));
	MetadataDetails.Insert("DocumentJournals", New Structure("ManagerModule, Forms, Commands"));
	MetadataDetails.Insert("Enums", New Structure("ManagerModule, Forms, Commands"));
	MetadataDetails.Insert("Reports", New Structure("ManagerModule, ObjectModule, Forms, Commands,"));
	MetadataDetails.Insert("DataProcessors", New Structure("ManagerModule, ObjectModule, Forms, Commands"));
	MetadataDetails.Insert("ChartsOfCharacteristicTypes", New Structure("ManagerModule, ObjectModule, Forms, Commands"));
	MetadataDetails.Insert("ChartsOfAccounts", New Structure("ManagerModule, ObjectModule, Forms, Commands"));
	MetadataDetails.Insert("ChartsOfCalculationTypes", New Structure("ManagerModule, ObjectModule, Forms, Commands"));
	MetadataDetails.Insert("InformationRegisters", New Structure("ManagerModule, RecordSetModule, Forms, Commands"));
	MetadataDetails.Insert("AccumulationRegisters", New Structure("ManagerModule, RecordSetModule, Forms, Commands"));
	MetadataDetails.Insert("AccountingRegisters", New Structure("ManagerModule, RecordSetModule, Forms, Commands"));
	MetadataDetails.Insert("CalculationRegisters", New Structure("ManagerModule, RecordSetModule, Forms, Commands"));
	MetadataDetails.Insert("BusinessProcesses", New Structure("ManagerModule, ObjectModule, Forms, Commands"));
	MetadataDetails.Insert("Tasks", New Structure("ManagerModule, ObjectModule, Forms, Commands"));
	
	Return MetadataDetails;
EndFunction

#EndRegion

#Region AttachableCommands

Function PluggableCommands_ConfiguringSources()
	SourcesSettings = New ValueTable;
	SourcesSettings.Columns.Add("Metadata");
	SourcesSettings.Columns.Add("Print",                         New TypeDescription("Boolean"));
	SourcesSettings.Columns.Add("PrintSettingsPrint",          New TypeDescription("Boolean"));
	SourcesSettings.Columns.Add("ReportsOptions",                New TypeDescription("Boolean"));
	SourcesSettings.Columns.Add("ObjectsFilling",             New TypeDescription("Boolean"));
	SourcesSettings.Columns.Add("AdditionalReportsAndDataProcessors", New TypeDescription("Boolean"));
	SourcesSettings.Columns.Add("UserReminders",        New TypeDescription("Boolean"));
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		ArrayOfMetadataAllSources = ModulePrintManager.PrintCommandsSources();
		PrintSettings = ModulePrintManager.PrintSettings();
			
		ArrayOfPrintSettingsMetadata = New Array;
		For Each ObjectManager1 In PrintSettings.PrintObjects Do
			ArrayOfPrintSettingsMetadata.Add(Metadata.FindByType(TypeOf(ObjectManager1)));
		EndDo;
		
		MetadataArray = CommonClientServer.ArraysDifference(ArrayOfMetadataAllSources, ArrayOfPrintSettingsMetadata);
		FillValueTable(SourcesSettings, MetadataArray, "Metadata", New Structure("Print", True));
		FillValueTable(SourcesSettings, ArrayOfPrintSettingsMetadata, "Metadata", New Structure("PrintSettingsPrint", True));
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsOptions = Common.CommonModule("ReportsOptions");
		MetadataArray = ModuleReportsOptions.ObjectsWithReportCommands();
		FillValueTable(SourcesSettings, MetadataArray, "Metadata", New Structure("ReportsOptions", True));
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleObjectFilling = Common.CommonModule("ObjectsFilling");
		MetadataArray = ModuleObjectFilling.ObjectsWithFillingCommands();
		FillValueTable(SourcesSettings, MetadataArray, "Metadata", New Structure("ObjectsFilling", True));
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
		Kind = Enums["AdditionalReportsAndDataProcessorsKinds"]["ObjectFilling"];
		AttachedMetadataObjects = ModuleAdditionalReportsAndDataProcessors.AttachedMetadataObjects(Kind);
		MetadataArray = AttachedMetadataObjects.UnloadColumn("Metadata");
		IndexOf = MetadataArray.Find(Metadata.Catalogs.MetadataObjectIDs);
		If IndexOf <> Undefined Then
			MetadataArray.Delete(IndexOf);
		EndIf;
		FillValueTable(SourcesSettings, MetadataArray, "Metadata", New Structure("AdditionalReportsAndDataProcessors", True));
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.UserReminders") Then
		MetadataArray = New Array;
		TypesDefinedByString = "ReminderSubject, ReminderSubjectObject";
		ArrayOfNamesOfDefinedTypes = StrSplit(TypesDefinedByString, ",", False);
		For Each NameOfTypeBeingDefined In ArrayOfNamesOfDefinedTypes Do
			NameOfTypeBeingDefined = TrimAll(NameOfTypeBeingDefined);
			ArrayOfDefinedTypes = Metadata.DefinedTypes[NameOfTypeBeingDefined].Type.Types();
			For Each DefinedType In ArrayOfDefinedTypes Do
				MetadataObject = Metadata.FindByType(DefinedType);
				If MetadataObject = Undefined Then
					Continue;
				EndIf;
				If MetadataArray.Find(MetadataObject) = Undefined Then
					MetadataArray.Add(MetadataObject);
				EndIf;
			EndDo;
		EndDo;
		FillValueTable(SourcesSettings, MetadataArray, "Metadata", New Structure("UserReminders", True));
	EndIf;
	
	Return SourcesSettings;
EndFunction

Function PlugabbleCommands_ConnectedObjectsInformation()
	ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
	InterfaceSettings4 = ModuleAttachableCommands.AttachableObjectsInterfaceSettings();
	
	HadCriticalErrors = False;
	ConnectedObjectsInSourcesContext = New Map;
	EmptyConnectedObjectSettings = New Structure;
	
	AttachedObjects = New ValueTable;
	AttachedObjects.Columns.Add("Metadata");
	For Each Setting In InterfaceSettings4 Do
		Try
			AttachedObjects.Columns.Add(Setting.Key, Setting.TypeDescription);
			EmptyConnectedObjectSettings.Insert(Setting.Key, Setting.TypeDescription.AdjustValue());
		Except
			Brief1 = NStr("ru = 'Не удалось зарегистрировать вид настройки подключаемых объектов.';
							|en = 'Cannot register a setting kind of attachable objects.';");
			More = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'См. в %1:
				|Ключ: ""%2"", описание типов: ""%3"", текст ошибки: ""%4"".';
				|en = 'See %1:
				|Key: ""%2"", type details: ""%3"", error text: ""%4"".';"),
				"AttachableCommandsOverridable.OnDefineAttachableObjectsSettingsComposition()",
				Setting.Key,
				String(Setting.TypeDescription),
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			AddError(Undefined, Brief1, More);
			HadCriticalErrors = True;
		EndTry;
	EndDo;
	
	Content = Metadata.Subsystems.AttachableReportsAndDataProcessors.Content;
	For Each MetadataObject In Content Do
		Try
			Settings = ModuleAttachableCommands.AttachableObjectSettings(MetadataObject.FullName(), InterfaceSettings4);
		Except
			Brief1 = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить настройки объекта, включенного в состав подсистемы ""%1"".';
					|en = 'Cannot receive settings of the object included in subsystem ""%1"".';"),
				"AttachableReportsAndDataProcessors");
			More = TrimAll(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			More = More
				+ ?(StrEndsWith(More, "."), " ", ". ")
				+ NStr("ru = 'См. также раздел ""Подключение отчетов и обработок к механизмам конфигурации"" документации подсистемы ""Подключаемые команды"".';
						|en = 'See also the ""Attach reports and data processors to configuration mechanism"" section of the ""Attachable commands"" subsystem documentation.';");
			AddError(MetadataObject, Brief1, More);
			Continue;
		EndTry;
		If Settings = Undefined Then
			Brief1 = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В состав подсистемы ""%1"" могут входить только отчеты и обработки.';
					|en = 'Subsystem ""%1"" can include only reports and data processors.';"),
				"AttachableReportsAndDataProcessors");
			More = NStr("ru = 'Подробнее см. раздел ""Подключение отчетов и обработок к механизмам конфигурации"" документации подсистемы ""Подключаемые команды"".';
							|en = 'For more information, see the SSL documentation: ""Attachable commands"" subsystem — ""Attaching reports and data processors to configuration mechanisms"" section.';");
			AddError(MetadataObject, Brief1, More);
			Continue;
		EndIf;
		
		ConnectedObjectSettings = AttachedObjects.Add();
		ConnectedObjectSettings.Metadata = MetadataObject;
		FillPropertyValues(ConnectedObjectSettings, Settings);
		
		For Each MetadataObjectSource In Settings.Location Do
			Array = ConnectedObjectsInSourcesContext[MetadataObjectSource];
			If Array = Undefined Then
				Array = New Array;
				ConnectedObjectsInSourcesContext.Insert(MetadataObjectSource, Array);
			EndIf;
			Array.Add(Settings);
		EndDo;
	EndDo;
	
	InformationRecords = New Structure;
	InformationRecords.Insert("ConnectedObjectsInSourcesContext", ConnectedObjectsInSourcesContext);
	InformationRecords.Insert("AttachedObjects", AttachedObjects);
	InformationRecords.Insert("EmptyConnectedObjectSettings", EmptyConnectedObjectSettings);
	InformationRecords.Insert("HadCriticalErrors", HadCriticalErrors);
	Return InformationRecords;
EndFunction

Procedure PluggableCommands_ScriptIntersectionError(MetadataObject, FullProcedureName)
	Brief1 = NStr("ru = 'Объект не может быть одновременно и источником команд и расширением команд других объектов';
					|en = 'An object cannot be both a command source and an extension for other object commands.';");
	More = NStr("ru = 'Объект метаданных определен одновременно и как источник команд (см. %1)
		|и как расширение команд печати других объектов (см. состав подсистемы %2 и содержимое процедуры %3 в модуле менеджера).';
		|en = 'Metadata object is defined both as a command source (see %1)
		|and as an extension to print commands for other objects (see composition of subsystem %2 and content of procedure %3 in the manager module).';");
	More = StringFunctionsClientServer.SubstituteParametersToString(More, FullProcedureName, "AttachableReportsAndDataProcessors", "OnDefineSettings");
	AddError(MetadataObject, Brief1, More);
EndProcedure

Procedure PluggableCommands_ErrorObjectNotRegisteredInProcedure(MetadataObject, FullProcedureName)
	Brief1 = NStr("ru = 'Объект не зарегистрирован в переопределяемом модуле';
					|en = 'Object is not registered in the overridable module';");
	More = NStr("ru = 'Объект метаданных не зарегистрирован в процедуре ""%1"".';
					|en = 'Metadata object is not registered in the ""%1"" procedure.';");
	More = StringFunctionsClientServer.SubstituteParametersToString(More, FullProcedureName);
	AddError(MetadataObject, Brief1, More);
EndProcedure

Procedure PluggableCommands_MissingProcedureError(MetadataObject, FullProcedureName)
	Brief1 = NStr("ru = 'В модуле менеджера отсутствует процедура';
					|en = 'In manager module procedure is missing';");
	More = NStr("ru = 'В модуле менеджера отсутствует процедура ""%1"".';
					|en = 'In manager module the %1 procedure is missing';");
	More = StringFunctionsClientServer.SubstituteParametersToString(More, FullProcedureName);
	AddError(MetadataObject, Brief1, More);
EndProcedure

Procedure FillValueTable(Table, KeysArray, KeyColumnName, FillingStructure)
	For Each Var_Key In KeysArray Do
		TableRow = Table.Find(Var_Key, KeyColumnName);
		If TableRow = Undefined Then
			TableRow = Table.Add();
			TableRow[KeyColumnName] = Var_Key;
		EndIf;
		FillPropertyValues(TableRow, FillingStructure);
	EndDo;
EndProcedure

Function PlugabbleCommands_FormsWithOptionalImplementation(MetadataObject)
	FormsCollection = New Structure;
	FormsCollection.Insert("DefaultFolderForm");
	FormsCollection.Insert("DefaultChoiceForm");
	FormsCollection.Insert("DefaultFolderChoiceForm");
	
	FillPropertyValues(FormsCollection, MetadataObject);
	
	Result = New Array;
	For Each Form In FormsCollection Do
		If Form.Value <> Undefined Then
			Result.Add(Form.Value);
		EndIf;
	EndDo;
	
	For Each Form In MetadataObject.Forms Do
		If StrStartsWith(Form.Name, "ChoiceForm") Or StrStartsWith(Form.Name, "Selection") Then
			If Result.Find(Form) = Undefined Then
				Result.Add(Form);
			EndIf;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

// Module text management.

Function IsExtensionObject(MetadataObject)
	Return MetadataObject.ConfigurationExtension() <> Undefined;
EndFunction

Function FindMethod(ModuleText, MethodName, IncludingComments = True, IncludingDirectives = True, SubsystemBracketsFullNames = "")
	ModuleTextLower = Lower(ModuleText);
	Method = New Structure("Begin, Ending, IsFunction, Parameters, Export, Content, BodyBeginning, BodyEnding, Comments, Directives, SubsystemBrackets");
	Method.Begin = StrFindProcedureOrFunction(ModuleTextLower, Lower(MethodName), Method.IsFunction);
	If Method.Begin = 0 Then
		Return Undefined;
	EndIf;
	EndingRow = ?(Method.IsFunction, "EndFunction", "EndProcedure");
	Method.BodyEnding = StrFindNotCommentAndNotString(ModuleTextLower, Lower(EndingRow), Method.Begin);
	Method.Ending     = Method.BodyEnding + StrLen(EndingRow);
	
	ParametersText = Mid(ModuleText, Method.Begin, Method.BodyEnding - Method.Begin);
	OpeningBracketPosition = StrFindNotCommentAndNotString(ParametersText, "(");
	PositionOfClosingBracket = StrFindNotCommentAndNotString(ParametersText, ")");
	Method.Parameters = Mid(ParametersText, OpeningBracketPosition + 1, PositionOfClosingBracket - OpeningBracketPosition - 1);
	
	Method.BodyBeginning = Method.Begin + PositionOfClosingBracket;
	
	Method.Content = Mid(ParametersText, PositionOfClosingBracket + 1);
	BodyLower = Lower(Method.Content);
	If StrStartsWith(TrimL(BodyLower), Lower("Export")) Then
		Position = StrFind(BodyLower, Lower("Export"));
		Method.BodyBeginning = Method.BodyBeginning + Position + 6;
		Method.Content = Mid(Method.Content, Position + 7);
		Method.Export = True;
	Else
		Method.Export = False;
	EndIf;
	
	// Expand the area using comments and the &-directives.
	Method.Content = TrimAll(Method.Content);
	Method.Comments = "";
	Method.Directives = "";
	Method.SubsystemBrackets = "";
	
	If IncludingDirectives And Method.Begin > 2 Then
		CarriageReturnPosition = StrFind(ModuleText, Chars.LF, SearchDirection.FromEnd, Method.Begin - 2);
		BeforeStartLine = TrimAll(Mid(ModuleText, CarriageReturnPosition, Method.Begin - 2 - CarriageReturnPosition));
		If StrStartsWith(BeforeStartLine, "&") Then
			Method.Begin = CarriageReturnPosition + 1;
			Method.Directives = TrimR(BeforeStartLine + Chars.LF + Method.Directives);
		EndIf;
	EndIf;
	If Not IsBlankString(SubsystemBracketsFullNames) Then
		SubsystemsNames = StrSplit(SubsystemBracketsFullNames, "/");
		For Each FullSubsystemName In SubsystemsNames Do
			If ExpandFragmentDueToSubsystemBrackets(ModuleTextLower, Method, FullSubsystemName) Then
				Method.SubsystemBrackets = FullSubsystemName;
				Break;
			EndIf;
		EndDo;
	EndIf;
	While True And Method.Begin > 2 Do
		CarriageReturnPosition = StrFind(ModuleText, Chars.LF, SearchDirection.FromEnd, Method.Begin - 2);
		BeforeStartLine = TrimAll(Mid(ModuleText, CarriageReturnPosition, Method.Begin - 2 - CarriageReturnPosition));
		If IncludingComments And StrStartsWith(BeforeStartLine, "//") Then
			Method.Begin = CarriageReturnPosition + 1;
			Method.Comments = TrimR(BeforeStartLine + Chars.LF + Method.Comments);
		ElsIf IsBlankString(BeforeStartLine) Then
			Method.Begin = CarriageReturnPosition + 1;
		Else
			Break;
		EndIf;
	EndDo;
	If IncludingComments Then
		Length = StrLen(ModuleText);
		While True And Method.Ending + 2 < Length Do
			CarriageReturnPosition = StrFind(ModuleText, Chars.LF, SearchDirection.FromBegin, Method.Ending + 2);
			AfterEndLine = TrimAll(Mid(ModuleText, CarriageReturnPosition, CarriageReturnPosition - Method.Ending - 2));
			If StrStartsWith(AfterEndLine, "//") Then
				Method.Ending = CarriageReturnPosition - 1;
				Method.Comments = TrimL(Method.Comments + Chars.LF + AfterEndLine);
			Else
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return Method;
EndFunction

Function FindMethodCall(CodeSnippet, StartCallText, StartPosition = 1, SubsystemBracketsFullNames = "")
	Call = New Structure("Parameters, Begin, Ending, Body, SubsystemBrackets");
	
	LowerFragment = Lower(CodeSnippet);
	StartCallTextLower = Lower(StartCallText);
	Call.Begin = StrFindNotCommentAndNotString(LowerFragment, StartCallTextLower, StartPosition);
	If Call.Begin = 0 Then
		Return Undefined;
	EndIf;
	WordsLengthModule = StrLen("Module");
	If WordsLengthModule < Call.Begin
		And Mid(LowerFragment, Call.Begin-WordsLengthModule, WordsLengthModule) = Lower("Module") Then
		Call.Begin = Call.Begin-WordsLengthModule;
		StartCallTextLower = Lower("Module") + StartCallTextLower;
	EndIf;
	If Call.Begin > 1 And Not IsBlankString(Mid(LowerFragment, Call.Begin-1, 1)) Then
		Return Undefined;
	EndIf;
	
	Call.Parameters = New Array;
	AnotherParameter = "";
	OpenSquareBrackets = 0;
	OpenParentheses = 0;
	BeginningLength = StrLen(StartCallTextLower);
	
	AnalyzedCode = Mid(CodeSnippet, Call.Begin + BeginningLength);
	SequentialReading = CreateSequentialRead(AnalyzedCode);
	While True Do
		LastChar = Undefined;
		Block = ReadBlockWithStopBySymbol(SequentialReading, "[](),", LastChar);
		If LastChar = Undefined
			Or (IsBlankString(LastChar) And IsBlankString(Block)) Then
			Return Undefined; // This is the end.
		EndIf;
		
		If LastChar = ")" Then
			OpenParentheses = OpenParentheses - 1;
			If OpenParentheses = -1 Then
				AnotherParameter = AnotherParameter + Block;
				Break; // Call end.
			EndIf;
		ElsIf LastChar = "]" Then
			OpenSquareBrackets = OpenSquareBrackets - 1;
		EndIf;
		
		If OpenSquareBrackets > 0 Or OpenParentheses > 0 Then
			AnotherParameter = AnotherParameter + Block + LastChar;
		Else
			AnotherParameter = AnotherParameter + Block;
			If LastChar = "," Then
				Call.Parameters.Add(TrimAll(AnotherParameter));
				AnotherParameter = "";
			Else
				AnotherParameter = AnotherParameter + LastChar;
			EndIf;
		EndIf;
		
		If LastChar = "(" Then
			OpenParentheses = OpenParentheses + 1;
		ElsIf LastChar = "[" Then
			OpenSquareBrackets = OpenSquareBrackets + 1;
		EndIf;
	EndDo;
	
	If Not IsBlankString(AnotherParameter) Or Call.Parameters.Count() > 0 Then
		Call.Parameters.Add(TrimAll(AnotherParameter));
	EndIf;
	Call.Ending = Call.Begin + BeginningLength + SequentialReading.CharacterNumber + 1;
	
	If Not IsBlankString(SubsystemBracketsFullNames) Then
		SubsystemsNames = StrSplit(SubsystemBracketsFullNames, "/");
		For Each FullSubsystemName In SubsystemsNames Do
			If ExpandFragmentDueToSubsystemBrackets(LowerFragment, Call, FullSubsystemName) Then
				Call.SubsystemBrackets = FullSubsystemName;
				Break;
			EndIf;
		EndDo;
	EndIf;
	Call.Body = Mid(CodeSnippet, Call.Begin, Call.Ending - Call.Begin);
	
	Return Call;
EndFunction

Function StrFindProcedureOrFunction(String, SearchSubstring, IsFunction, Val StartPosition = 1)
	Length = StrLen(SearchSubstring);
	While True Do
		FirstCharacterPosition = StrFind(String, SearchSubstring, , StartPosition);
		If FirstCharacterPosition = 0 Then
			Return 0;
		EndIf;
		ParenthesisPosition = StrFind(String, "(", , FirstCharacterPosition);
		If ParenthesisPosition = 0 Then
			Return 0;
		EndIf;
		LineBetweenParenthesisAndSubstring = Mid(String, FirstCharacterPosition + Length, ParenthesisPosition - FirstCharacterPosition - Length);
		If Not IsBlankString(LineBetweenParenthesisAndSubstring) Then
			StartPosition = FirstCharacterPosition + 1;
			Continue;
		EndIf;
		CarriageReturnPosition = StrFind(String, Chars.LF, SearchDirection.FromEnd, FirstCharacterPosition);
		LineBetweenCarriageReturnAndSubstring = TrimAll(Mid(String, CarriageReturnPosition, FirstCharacterPosition - CarriageReturnPosition));
		MethodType = Lower(TrimAll(LineBetweenCarriageReturnAndSubstring));
		If MethodType = "procedure" Then
			IsFunction = False;
			Break;
		ElsIf MethodType = "function" Then
			IsFunction = True;
			Break;
		EndIf;
		StartPosition = FirstCharacterPosition + 1;
	EndDo;
	Return CarriageReturnPosition + 1;
EndFunction

Function ExpandFragmentDueToSubsystemBrackets(LowerFragment, Call, FullSubsystemBracketsName)
	OpeningLower = Lower("// " + FullSubsystemBracketsName);
	OpeningPosition = StrFind(LowerFragment, OpeningLower, SearchDirection.FromEnd, Call.Begin);
	If OpeningPosition <> 0 Then
		ESPosition = StrFind(LowerFragment, Chars.LF, SearchDirection.FromBegin, OpeningPosition);
		FragmentBetweenOpeningAndBeginning = Mid(LowerFragment, ESPosition, Call.Begin - ESPosition);
		If IsBlankString(FragmentBetweenOpeningAndBeginning) Then
			ClosingLower = Lower("// End " + FullSubsystemBracketsName);
			ClosingPosition = StrFind(LowerFragment, ClosingLower, SearchDirection.FromBegin, Call.Ending);
			If ClosingPosition <> 0 Then
				ESPosition = StrFind(LowerFragment, Chars.LF, SearchDirection.FromEnd, ClosingPosition);
				FragmentBetweenEndingAndClosing = Mid(LowerFragment, Call.Ending, ESPosition - Call.Ending);
				If IsBlankString(FragmentBetweenEndingAndClosing) Then
					Call.Begin    = OpeningPosition;
					Call.Ending = StrFind(LowerFragment, Chars.LF, SearchDirection.FromBegin, ClosingPosition);
					Return True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return False;
EndFunction

// Sequential read.

Function CreateSequentialRead(StringOrReadText)
	SequentialReading = New Structure("IsTextReading, OutputCompleted, String, CharacterNumber, StringLength, LineNumber, CurrentBlock, Comment");
	SequentialReading.IsTextReading = TypeOf(StringOrReadText) = Type("TextReader");
	SequentialReading.OutputCompleted   = False;
	SequentialReading.LineNumber     = 0;
	SequentialReading.CurrentBlock     = "";
	SequentialReading.Comment     = "";
	If SequentialReading.IsTextReading Then
		SequentialReading.Insert("TextReader", StringOrReadText);
	Else
		SequentialReading.String = StringOrReadText;
		SequentialReading.CharacterNumber = 0;
		SequentialReading.StringLength  = StrLen(SequentialReading.String);
		SequentialReading.LineNumber  = SequentialReading.LineNumber + 1;
	EndIf;
	Return SequentialReading;
EndFunction

Function ReadNextObjectCharacter(SequentialReading, Char)
	If SequentialReading.CharacterNumber = SequentialReading.StringLength Then
		If SequentialReading.IsTextReading Then
			SequentialReading.String = SequentialReading.TextReader.ReadLine();
			If SequentialReading.String = Undefined Then
				Char = "";
				SequentialReading.OutputCompleted = True;
				Return False;
			EndIf;
			Char = Chars.LF;
			SequentialReading.CharacterNumber = 0;
			SequentialReading.StringLength  = StrLen(SequentialReading.String);
		Else
			Char = "";
			SequentialReading.OutputCompleted = True;
			Return False;
		EndIf;
	Else
		SequentialReading.CharacterNumber = SequentialReading.CharacterNumber + 1;
		Char = Mid(SequentialReading.String, SequentialReading.CharacterNumber, 1);
	EndIf;
	If Char = Chars.LF Then
		SequentialReading.LineNumber = SequentialReading.LineNumber + 1;
	EndIf;
	SequentialReading.CurrentBlock = SequentialReading.CurrentBlock + Char;
	Return True;
EndFunction

Function ObjectWithoutRegistrationInVariablesNextCharacter(SequentialReading)
	If SequentialReading.CharacterNumber = SequentialReading.StringLength Then
		If SequentialReading.IsTextReading Then
			Char = Chars.LF;
		Else
			Char = Undefined;
		EndIf;
	Else
		Char = Mid(SequentialReading.String, SequentialReading.CharacterNumber + 1, 1);
	EndIf;
	Return Char;
EndFunction

Function ReadObjectToSymbol(SequentialReading, StopReadingSymbol)
	ReadingResult = "";
	Char = Undefined;
	While ReadNextObjectCharacter(SequentialReading, Char) Do
		If Char = StopReadingSymbol Then
			Return ReadingResult;
		Else
			ReadingResult = ReadingResult + Char;
		EndIf;
	EndDo;
	Return ReadingResult;
EndFunction

Function ReadBlockWithStopBySymbol(SequentialReading, CharactersToStopReadingSet, LocalSymbol, EmptyStringIsSeparator = False)
	Block = "";
	QuotationMark = """";
	While ReadNextObjectCharacter(SequentialReading, LocalSymbol) Do
		If StrFind(CharactersToStopReadingSet, LocalSymbol) <> 0 Then
			Break;
		ElsIf EmptyStringIsSeparator And IsBlankString(LocalSymbol) Then
			If Block <> "" Then
				Break;
			EndIf;
		ElsIf LocalSymbol = QuotationMark Then
			While True Do
				Block = Block + QuotationMark + ReadObjectToSymbol(SequentialReading, QuotationMark) + QuotationMark;
				If ObjectWithoutRegistrationInVariablesNextCharacter(SequentialReading) = QuotationMark Then // Double quotation mark.
					ReadNextObjectCharacter(SequentialReading, Undefined);
					Block = Block + QuotationMark; // Resume reading.
				Else
					Break; // Finish reading.
				EndIf;
			EndDo;
		ElsIf LocalSymbol = "/" And ObjectWithoutRegistrationInVariablesNextCharacter(SequentialReading) = "/" Then
			FinishReadingCommentBlock(SequentialReading);
		Else
			Block = Block + LocalSymbol;
		EndIf;
	EndDo;
	Return Block;
EndFunction

Procedure FinishReadingCommentBlock(SequentialReading)
	BeforeAnalysisBeginsCodeBlock = Left(SequentialReading.CurrentBlock, StrLen(SequentialReading.CurrentBlock) - 1);
	Comment = "/" + ReadObjectToSymbol(SequentialReading, Chars.LF);
	If SequentialReading.Comment = "" Then
		SequentialReading.Comment = Comment;
	Else
		SequentialReading.Comment = SequentialReading.Comment + Chars.LF + Comment;
	EndIf;
	SequentialReading.CurrentBlock = BeforeAnalysisBeginsCodeBlock;
EndProcedure

#EndRegion

#Region Users

Procedure CheckDirectAccessToSessionParameters()
	
	ForbiddenParameters = New Array;
	ForbiddenParameters.Add("SessionParameters.CurrentUser");
	ForbiddenParameters.Add("SessionParameters.CurrentExternalUser");
	ForbiddenParameters.Add("SessionParameters.AuthorizedUser");
	
	ModuleFiles = FindFiles(DumpDirectory, "*.bsl", True);
	
	For Each ModuleFile In ModuleFiles Do
		
		TextDocument = New TextDocument;
		TextDocument.Read(ModuleFile.FullName);
		ModuleText = TextDocument.GetText();
		
		For Each ForbiddenParameter In ForbiddenParameters Do
			If StrFindNotCommentAndNotString(ModuleText, ForbiddenParameter) <> 0 Then
				ObjectProperties = ObjectPropertiesByFileName(ModuleFile.FullName);
				If ObjectProperties.MetadataObject = Metadata.CommonModules.UsersInternal Then
					Continue;
					// Direct access to session parameters is allowed only from the UsersInternal module.
				EndIf;
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В %1 обнаружено прямое обращение к %2.';
						|en = 'Direct access to %2 is detected in %1.';"), ObjectProperties.Presentation, ForbiddenParameter);
				AddError(ObjectProperties.MetadataObject,
					NStr("ru = 'Прямое обращение к параметрам сеанса подсистемы Пользователи недопустимо';
						|en = 'Direct access to session parameters of the Users subsystem is unacceptable';"),
					ErrorText);
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

#Region ObjectsPrefixes

Procedure CheckExtraSubscriptionPrefixes()
	
	ModuleObjectsPrefixesInternal = Common.CommonModule("ObjectsPrefixesInternal");
	MetadataUsingPrefixesDetails = ModuleObjectsPrefixesInternal.MetadataUsingPrefixesDetails(True);
	
	FilterStructure1 = New Structure("HasCode, HasNumber", False, False);
	ErrorsDetails = MetadataUsingPrefixesDetails.FindRows(FilterStructure1);
	For Each ErrorDescription In ErrorsDetails Do
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1 включен в подписку %2.';
				|en = '%1 included in subscription %2.';"),
			ErrorDescription.FullName, ErrorDescription.SubscriptionName);
		AddError(Common.MetadataObjectByFullName(ErrorDescription.FullName),
			NStr("ru = 'Включение объектов без кода (номера) в подписки префиксации недопустимо';
				|en = 'Including objects without a code (number) in the prefix subscriptions is not allowed';"),
			ErrorText);
		
	EndDo;
		
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		If ModuleSaaSOperations.IsSeparatedConfiguration() Then
			FilterStructure1 = New Structure("IsSeparatedMetadataObject", False);
			ErrorsDetails = MetadataUsingPrefixesDetails.FindRows(FilterStructure1);
			For Each ErrorDescription In ErrorsDetails Do
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '%1 включен в подписку %2.';
						|en = '%1 included in subscription %2.';"),
					ErrorDescription.FullName, ErrorDescription.SubscriptionName);
				AddError(Common.MetadataObjectByFullName(ErrorDescription.FullName),
					NStr("ru = 'Для разделенных конфигураций включение неразделенных объектов в подписки префиксации недопустимо';
						|en = 'You cannot include shared objects in prefixation subscriptions for separated configurations';"),
					ErrorText);
				
			EndDo;
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region SaaSOperations

Procedure CheckSeparatorsComposition()
	
	// Check basic separator properties.
	Separators = New Structure;
	Separators.Insert("DataAreaMainData");
	Separators.Insert("DataAreaAuxiliaryData");
	
	PlannedProperties = New Structure;
	PlannedProperties.Insert("AutoUse", Metadata.ObjectProperties.CommonAttributeAutoUse.Use);
	PlannedProperties.Insert("DataSeparation", Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate);
	PlannedProperties.Insert("SeparatedDataUse", Metadata.ObjectProperties.CommonAttributeSeparatedDataUse.Independently);
	PlannedProperties.Insert("DataSeparationValue", Metadata.SessionParameters["DataAreaValue"]);
	PlannedProperties.Insert("DataSeparationUse", Metadata.SessionParameters["DataAreaUsage"]);
	PlannedProperties.Insert("ConditionalSeparation", Metadata.Constants.UseSeparationByDataAreas);
	PlannedProperties.Insert("UsersSeparation", Metadata.ObjectProperties.CommonAttributeUsersSeparation.Separate);
	PlannedProperties.Insert("AuthenticationSeparation", Metadata.ObjectProperties.CommonAttributeAuthenticationSeparation.Separate);
	Separators.DataAreaMainData = PlannedProperties;
	
	PlannedProperties = New Structure;
	PlannedProperties.Insert("AutoUse", Metadata.ObjectProperties.CommonAttributeAutoUse.DontUse);
	PlannedProperties.Insert("DataSeparation", Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate);
	PlannedProperties.Insert("SeparatedDataUse", Metadata.ObjectProperties.CommonAttributeSeparatedDataUse.IndependentlyAndSimultaneously);
	PlannedProperties.Insert("DataSeparationValue", Metadata.SessionParameters["DataAreaValue"]);
	PlannedProperties.Insert("DataSeparationUse", Metadata.SessionParameters["DataAreaUsage"]);
	PlannedProperties.Insert("ConditionalSeparation", Metadata.Constants.UseSeparationByDataAreas);
	PlannedProperties.Insert("UsersSeparation", Metadata.ObjectProperties.CommonAttributeUsersSeparation.DontUse);
	PlannedProperties.Insert("AuthenticationSeparation", Metadata.ObjectProperties.CommonAttributeAuthenticationSeparation.DontUse);
	Separators.DataAreaAuxiliaryData = PlannedProperties;
	
	For Each SeparatorProperties In Separators Do
		SeparatorMetadata = Metadata.CommonAttributes[SeparatorProperties.Key];
		For Each AttributeCompositionProperty In SeparatorProperties.Value Do
			If SeparatorMetadata[AttributeCompositionProperty.Key] <> AttributeCompositionProperty.Value Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Значение свойства %1 должно быть %2. Текущее значение %3';
						|en = 'The %1 property value must be %2. Current value is %3';"),
					AttributeCompositionProperty.Key, SeparatorMetadata[AttributeCompositionProperty.Key], AttributeCompositionProperty.Value);
				AddError(SeparatorMetadata, NStr("ru = 'Некорректное значение свойства разделителя';
															|en = 'Incorrect separator property value';"), ErrorText);
				HasSeparatorsCompositionErrors = True;
				Return; // Critical error, beyond autofixing. Abort the check.
			EndIf;
		EndDo;
	EndDo;
	
	CheckSeparators = New Structure;
	CheckSeparators.Insert("DataAreaMainData", True);
	CheckSeparators.Insert("DataAreaAuxiliaryData", True);
	
	// Separator content template relevance check. Applicable to SSL only.
	If IsDemoSSL() And Not EDTConfiguration Then
		CurrentLayouts = SeparatorsCompositionTemplates();
		For Each TemplateProperties In CurrentLayouts Do
			SavedLayout = GetTemplate(TemplateProperties.Key).GetText();
			If TemplateProperties.Value <> SavedLayout Then
				CheckSeparators[TemplateProperties.Key] = False;
				BriefErrorDetails = NStr("ru = 'Не обновлен эталонный макет для проверки состава разделителей';
											|en = 'Reference template for checking separator content is not updated';");
				If FixError("DividersTemplateNotUpdated") Then
					TemplateMetadata = Metadata.Reports.SSLImplementationCheck.Templates[TemplateProperties.Key];
					TemplateFileName = ObjectLayoutFilePath(TemplateMetadata);
					TextDocument = New TextDocument;
					TextDocument.SetText(TemplateProperties.Value);
					TextDocument.Write(TemplateFileName);
					FilesToUpload.Add(TemplateFileName);
					ErrorText = NStr("ru = 'Исправлено. Макет состава разделителей обновлен';
										|en = 'Fixed. Separator content template is updated';");
					AddError(Metadata.Reports["SSLImplementationCheck"], BriefErrorDetails, ErrorText);
				Else
					SavedArray = Common.ValueFromXMLString(SavedLayout);
					CurrentArray = Common.ValueFromXMLString(TemplateProperties.Value);
					
					ErrorTemplate = NStr("ru = 'Объект %1 не указан в эталонном макете состава разделителей %2
						|Убедитесь в правильности установки разделителей на объект и внесите его в макет.
						|Для автообновления макета рекомендуется запустить отчет ""Проверка внедрения БСП"" (Инструменты разработчика - Отчеты разработчика) 
						|с флажком ""Исправлять ошибки"".';
						|en = 'The %1 object is not specified in the %2 reference separator template.
						|Make sure the object''s separators are set correctly and add it to the template.
						|To auto-update the template, run the ""SSL integration check"" report (Development tools – Developer reports)
						|with the ""Fix errors"" checkbox selected.';");
					
					Added1 = CommonClientServer.ArraysDifference(CurrentArray, SavedArray);
					For Each ArrayElement In Added1 Do
						ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, ArrayElement, TemplateProperties.Key);
						AddError(Common.MetadataObjectByFullName(ArrayElement), BriefErrorDetails, ErrorText);
					EndDo;
					
					ErrorTemplate = NStr("ru = 'Объект %1 не должен быть описан в эталонном макете состава разделителей %2
						|Убедитесь в правильности установки разделителей на объект и внести его в макет. 
						|Для автообновления макета рекомендуется запустить отчет ""Проверка внедрения БСП"" (Инструменты разработчика - Отчеты разработчика) 
						|с флажком ""Исправлять ошибки"".';
						|en = 'The %1 object cannot be described in the %2 reference separator template.
						|Make sure the object''s separators are set correctly and add it to the template.
						|To auto-update the template, run the ""SSL integration check"" report (Development tools – Developer reports)
						|with the ""Fix errors"" checkbox selected.';");
					
					Trash = CommonClientServer.ArraysDifference(SavedArray, CurrentArray);
					For Each ArrayElement In Trash Do
						ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, ArrayElement, TemplateProperties.Key, "SSLImplementationCheck");
						AddError(Common.MetadataObjectByFullName(ArrayElement), BriefErrorDetails, ErrorText);
					EndDo;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	PresentationsStructure = New Structure;
	PresentationsStructure.Insert("ExchangePlan", "ExchangePlan");
	PresentationsStructure.Insert("ScheduledJob", "ScheduledJob");
	PresentationsStructure.Insert("Constant", "Constant");
	PresentationsStructure.Insert("Catalog", "Catalog");
	PresentationsStructure.Insert("Document", "Document");
	PresentationsStructure.Insert("ChartOfCharacteristicTypes", "ChartOfCharacteristicTypes");
	PresentationsStructure.Insert("ChartOfAccounts", "ChartOfAccounts");
	PresentationsStructure.Insert("ChartOfCalculationTypes", "ChartOfCalculationTypes");
	PresentationsStructure.Insert("InformationRegister", "InformationRegister");
	PresentationsStructure.Insert("AccumulationRegister", "AccumulationRegister");
	PresentationsStructure.Insert("AccountingRegister", "AccountingRegister");
	PresentationsStructure.Insert("CalculationRegister", "CalculationRegister");
	PresentationsStructure.Insert("BusinessProcess", "BusinessProcess");
	PresentationsStructure.Insert("Task", "Task");
	
	// Check separator content.
	Use = Metadata.ObjectProperties.CommonAttributeUse.Use;
	DontUse = Metadata.ObjectProperties.CommonAttributeUse.DontUse;
	ReportVersionIsDifferent = ReportVersionDiffersFromLibraryVersion();
	LibraryVersion       = StandardSubsystemsServer.LibraryVersion();
	
	Separators.DataAreaMainData = DontUse;
	Separators.DataAreaAuxiliaryData = Use;
	For Each SeparatorProperties In Separators Do
		If Not CheckSeparators[SeparatorProperties.Key] Then
			Continue;
		EndIf;
		
		HasMissedErrors = False;
		PlannedComposition = Common.ValueFromXMLString(GetTemplate(SeparatorProperties.Key).GetText());
		SeparatorMetadata = Metadata.CommonAttributes[SeparatorProperties.Key];
		
		If FixError("IncorrectSeparatorsComposition") Then
			SeparatorFileName = MetadataObjectDescriptionFilePath(SeparatorMetadata);
			DOMDocument = DOMDocument(SeparatorFileName);
			XPathResult = EvaluateXPathExpression(XPathExpressionCommonAttributesComposition() , DOMDocument);
			Content = XPathResult.IterateNext();
			ChangesMade = False;
		EndIf;
		
		For Each CompositionRow In SeparatorMetadata.Content Do
			ObjectMetadata = CompositionRow.Metadata;
			If Not IsSSLObject(CompositionRow.Metadata) Then
				Continue;
			EndIf;
			
			PlannedValueIsDifferentFromAuto = PlannedComposition.Find(ObjectMetadata.FullName()) <> Undefined;
			ActualValue = SeparatorMetadata.Content.Find(ObjectMetadata);
			ActualValueSameAsAuto = (ActualValue.Use <> SeparatorProperties.Value);
			
			SkipError = False;
			If (PlannedValueIsDifferentFromAuto And ActualValueSameAsAuto)
				Or (Not PlannedValueIsDifferentFromAuto And Not ActualValueSameAsAuto) Then
				
				If Not PlannedValueIsDifferentFromAuto And ReportVersionIsDifferent Then
					HasMissedErrors = True;
					SkipError = True;
				EndIf;
				
				If FixError("IncorrectSeparatorsComposition") And Not SkipError Then
					FullName = ObjectMetadata.FullName();
					NameParts = StrSplit(FullName, ".");
					FullName = PresentationsStructure[NameParts[0]] + "." + NameParts[1];
					
					If PlannedValueIsDifferentFromAuto And ActualValueSameAsAuto Then
						// Actual value is "Auto". Expected value is anything but "Auto". Add a node with another (not "Auto") value.
						Var_1169_Use = ?(SeparatorProperties.Value = Use, "Use", "DontUse");
						MetadataNode = DOMDocument.CreateElement(MetadataProperty());
						MetadataNode.TextContent = FullName;
						NodeUsage = DOMDocument.CreateElement(MetadataUsageProperty());
						NodeUsage.TextContent = Var_1169_Use;
						If EDTConfiguration Then
							CompositionNode = DOMDocument.CreateElement(CommonAttributeCompositionProperty());
							
							CompositionNode.AppendChild(MetadataNode);
							CompositionNode.AppendChild(NodeUsage);
							
							Content.AppendChild(CompositionNode);
						Else
							NodeConditionalSeparation = DOMDocument.CreateElement(ConditionalSeparationOfCommonAttributeProperty());
							
							CompositionElementNode = DOMDocument.CreateElement(CommonAttributeCompositionElementProperty());
							CompositionElementNode.AppendChild(MetadataNode);
							CompositionElementNode.AppendChild(NodeUsage);
							CompositionElementNode.AppendChild(NodeConditionalSeparation);
						
							Content.AppendChild(CompositionElementNode);
						EndIf;
					Else
						// Actual value is "Auto". Expected value is anything but "Auto". Delete the record.
						XPathResult = EvaluateXPathExpression(XPathExpressionMetadataByName(FullName), DOMDocument);
						DOMElement = XPathResult.IterateNext();
						If Not DOMElement = Undefined Then
							Content.RemoveChild(DOMElement.ParentNode);
						EndIf;
					EndIf;
					ChangesMade = True;
					
				ElsIf Not SkipError Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Значение использования разделителя %1 должно быть %2';
							|en = 'Usage value of the %1 separator must be %2';"),
						SeparatorMetadata.Name, ?(PlannedValueIsDifferentFromAuto, SeparatorProperties.Value, NStr("ru = 'Авто';
																															|en = 'Auto';")));
					AddError(ObjectMetadata, NStr("ru = 'Некорректное значение разделителя';
															|en = 'Incorrect separator value';"), ErrorText);
					HasSeparatorsCompositionErrors = True;
				EndIf;
			EndIf;
		EndDo;
		
		If HasMissedErrors Then
			Template = NStr("ru = 'Часть ошибок отличия значений разделителя на объекты БСП от поставляемых не была зарегистрирована.
				|Версия проверки внедрения ""%1"" отличается от используемой версии БСП ""%2"".';
				|en = 'Some errors occurred due to difference of separator values for SSL objects from the 1C-supplied separator values were not registered.
				|Integration check version ""%1"" differs from the used SSL version ""%2"".';");
			AddError(SeparatorMetadata,
				NStr("ru = 'Некорректное значение состава разделителя';
					|en = 'Incorrect separator content value';"),
				StringFunctionsClientServer.SubstituteParametersToString(Template,
					ReportVersion(), LibraryVersion));
		EndIf;
		
		If FixError("IncorrectSeparatorsComposition") And ChangesMade And Not HasMissedErrors Then
			WriteDOMDocument(DOMDocument, SeparatorFileName);
			ErrorText = NStr("ru = 'Исправлено. Состав разделителя для объектов БСП актуализирован.';
								|en = 'Fixed. Separator content for SSL objects is updated.';");
			AddError(SeparatorMetadata, NStr("ru = 'Некорректное значение состава разделителя';
														|en = 'Incorrect separator content value';"), ErrorText);
		EndIf;
	EndDo;
	
	// Check redundant separator properties.
	If FixError("RedundantSeparatorSetting") Then
		For Each SeparatorProperties In Separators Do
			SeparatorMetadata = Metadata.CommonAttributes[SeparatorProperties.Key];
			SeparatorFileName = MetadataObjectDescriptionFilePath(SeparatorMetadata);
			DOMDocument = DOMDocument(SeparatorFileName);
			
			XPathResult = EvaluateXPathExpression(XPathExpressionValueAutoUseProperty(), DOMDocument).IterateNext();
			If XPathResult = Undefined Then
				AutoUse = "Use";
			Else
				AutoUse = XPathResult.TextContent;
			EndIf;
			XPathResult = EvaluateXPathExpression(XPathExpressionCommonAttributesComposition(), DOMDocument);
			Content = XPathResult.IterateNext();
			
			DeletedNodes = New Array;
			For Each Object In Content.ChildNodes Do
				For Each ObjectProperties In Object.ChildNodes Do
					If Not TypeOf(ObjectProperties) = Type("DOMElement") Then
						Continue;
					EndIf;
					If ObjectProperties.TagName = MetadataUsageProperty() And ObjectProperties.TextContent = AutoUse Then
						DeletedNodes.Add(Object);
					EndIf;
				EndDo;
			EndDo;
			If DeletedNodes.Count() > 0 Then
				For Each Object In DeletedNodes Do
					Content.RemoveChild(Object);
				EndDo;
				WriteDOMDocument(DOMDocument, SeparatorFileName);
				ErrorText = NStr("ru = 'Исправлено. Для объектов разделителя в явном виде было указано использование разделения,
					|совпадающее со значением Авто разделителя.';
					|en = 'Fixed. Separation
					|matching Auto separation value was explicitly specified for the separator objects.';");
				AddError(SeparatorMetadata, NStr("ru = 'Избыточное использование явного значения разделителя';
															|en = 'Redundant use of explicit separator value';"), ErrorText);
			EndIf;
		EndDo;
	Else
		Separators.DataAreaMainData = Use;
		Separators.DataAreaAuxiliaryData = DontUse;
		For Each SeparatorProperties In Separators Do
			SeparatorMetadata = Metadata.CommonAttributes[SeparatorProperties.Key];
			For Each CompositionItem In SeparatorMetadata.Content Do
				If CompositionItem.Use = SeparatorProperties.Value Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Для разделителя %1 в явном виде указано использование разделения, совпадающее со значением Авто разделителя.';
							|en = 'Separation matching the Auto separator value is explicitly specified for separator %1.';"),
						SeparatorMetadata.Name);
					AddError(CompositionItem.Metadata, NStr("ru = 'Избыточное использование явного значения разделителя';
																	|en = 'Redundant use of explicit separator value';"), ErrorText);
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure

Function SeparatorsCompositionTemplates()
	
	Templates = New Structure;
	Templates.Insert("DataAreaMainData", Metadata.ObjectProperties.CommonAttributeUse.DontUse);
	Templates.Insert("DataAreaAuxiliaryData", Metadata.ObjectProperties.CommonAttributeUse.Use);
	For Each SeparatorProperties In Templates Do
		Templates[SeparatorProperties.Key] = SeparatorValues(SeparatorProperties.Key, SeparatorProperties.Value);
	EndDo;
	
	Return Templates;
	
EndFunction

Function SeparatorValues(SeparatorName, ValueToAdd)
	
	SeparatorValues = New Array;
	
	For Each CompositionItem In Metadata.CommonAttributes[SeparatorName].Content Do
		If IsSSLObject(CompositionItem.Metadata) And CompositionItem.Use = ValueToAdd Then
			SeparatorValues.Add(CompositionItem.Metadata.FullName());
		EndIf;
	EndDo;
	
	Return Common.ValueToXMLString(SeparatorValues);
	
EndFunction

Procedure CheckStandardRolesComposition()
	
	// It is forbidden to set the following rights in the "FullAccess" and "SystemAdministrator" roles:
	// Delete interactively
	// Delete predefined data interactively
	// Mark predefined data for deletion interactively
	// Unmark predefined data for deletion interactively
	// Delete predefined data marked for deletion interactively
	
	// List of separated metadata to skip during right check.
	Exceptions = New Map;
	Exceptions.Insert("Constant.DataAreaKey", True);
	Exceptions.Insert("Constant.DataAreaPrefix", True);
	Exceptions.Insert("Constant.DataAreaTimeZone", True);
	Exceptions.Insert("Constant.DataAreaPresentation", True);
	Exceptions.Insert("Constant.BackUpDataArea", True);
	Exceptions.Insert("Constant.LastClientSessionStartDate", True);
	Exceptions.Insert("InformationRegister.DataAreaExternalModulesAttachmentModes", True);
	Exceptions.Insert("InformationRegister.TextExtractionQueue", True);
	Exceptions.Insert("InformationRegister.DataAreas", True);
	Exceptions.Insert("InformationRegister.DataAreaActivityRating", True);
	
	PresentationsStructure = New Map;
	PresentationsStructure.Insert("Constant", "Constant");
	PresentationsStructure.Insert("CalculationRegister", "CalculationRegister");
	PresentationsStructure.Insert("InformationRegister", "InformationRegister");
	PresentationsStructure.Insert("AccumulationRegister", "AccumulationRegister");
	PresentationsStructure.Insert("AccountingRegister", "AccountingRegister");
	PresentationsStructure.Insert("ExchangePlan", "ExchangePlan");
	PresentationsStructure.Insert("Catalog", "Catalog");
	PresentationsStructure.Insert("ChartOfCharacteristicTypes", "ChartOfCharacteristicTypes");
	PresentationsStructure.Insert("ChartOfAccounts", "ChartOfAccounts");
	PresentationsStructure.Insert("ChartOfCalculationTypes", "ChartOfCalculationTypes");
	PresentationsStructure.Insert("Document", "Document");
	PresentationsStructure.Insert("BusinessProcess", "BusinessProcess");
	PresentationsStructure.Insert("Task", "Task");
	PresentationsStructure.Insert("Sequence", "Sequence");
	PresentationsStructure.Insert("DocumentJournal", "DocumentJournal");
	
	// Get a list of separated and shared metadata objects.
	Use = Metadata.ObjectProperties.CommonAttributeUse.Use;
	
	SeparatedMetadataObjects = New Map;
	UndividedMetadataObjects = New Map;
	
	// Create expression for searching the current separator value.
	SeparatorFileName = CommonAttributeFilePath("DataAreaMainData");
	DOMDocument         = DOMDocument(SeparatorFileName);
	
	For Each CompositionItem In Metadata.CommonAttributes.Find("DataAreaMainData").Content Do
		FullName = CompositionItem.Metadata.FullName();
		NameParts = StrSplit(FullName, ".");
		ObjectType = PresentationsStructure.Get(NameParts[0]);
		If ObjectType = Undefined Then
			Continue;
		EndIf;
		
		FullName = ObjectType + "." + NameParts[1];
		SearchExpression = XPathExpressionUsingCommonAttributesCompositionElement(FullName);
		XPathResult     = EvaluateXPathExpression(SearchExpression, DOMDocument);
		Item = XPathResult.IterateNext();
		
		ObjectIsDivided = (Item = Undefined) Or (Item <> Undefined And Item.TextContent <> "DontUse");
		
		If Not ObjectIsDivided Then
			UndividedMetadataObjects.Insert(FullName, False);
		Else
			If Exceptions.Get(FullName) = Undefined Then
				SeparatedMetadataObjects.Insert(FullName, False);
			EndIf;
		EndIf;
	EndDo;
	
	For Each CompositionItem In Metadata.CommonAttributes.Find("DataAreaAuxiliaryData").Content Do
		If CompositionItem.Use = Use Then
			FullName = CompositionItem.Metadata.FullName();
			NameParts = StrSplit(FullName, ".");
			ObjectType = PresentationsStructure.Get(NameParts[0]);
			If ObjectType = Undefined Then
				Continue;
			EndIf;
			FullName = ObjectType + "." + NameParts[1];
			If UndividedMetadataObjects.Get(FullName) = False Then
				UndividedMetadataObjects.Delete(FullName);
			EndIf;
			If Exceptions.Get(FullName) = Undefined Then
				SeparatedMetadataObjects.Insert(FullName, False);
			EndIf;
		EndIf;
	EndDo;
	
	// Loop through Sequences and check for the first document. If no document is found, the journal is considered separated.
	For Each MetadataSequences In Metadata.Sequences Do
		FullSequenceName = "Sequence." + MetadataSequences.Name;
		If MetadataSequences.Documents.Count() = 0 Then
			SeparatedMetadataObjects.Insert(FullSequenceName, False);
		Else
			For Each MetadataOfDocument In MetadataSequences.Documents Do
				FullDocumentName = "Document." + MetadataOfDocument.Name;
				If SeparatedMetadataObjects.Get(FullDocumentName) = Undefined Then
					UndividedMetadataObjects.Insert(FullSequenceName, False);
				Else
					SeparatedMetadataObjects.Insert(FullSequenceName, False);
				EndIf;
				Break;
			EndDo;
		EndIf;
	EndDo;
	
	// Loop through Journals and check for the first document. If no document is found, the journal is considered separated.
	For Each DocumentLogMetadata In Metadata.DocumentJournals Do
		FullJournalName = "DocumentJournal." + DocumentLogMetadata.Name;
		If DocumentLogMetadata.RegisteredDocuments.Count() = 0 Then
			SeparatedMetadataObjects.Insert(FullJournalName, False);
		Else
			For Each MetadataOfDocument In DocumentLogMetadata.RegisteredDocuments Do
				FullDocumentName = "Document." + MetadataOfDocument.Name;
				If SeparatedMetadataObjects.Get(FullDocumentName) = Undefined Then
					UndividedMetadataObjects.Insert(FullJournalName, False);
				Else
					SeparatedMetadataObjects.Insert(FullJournalName, False);
				EndIf;
				Break;
			EndDo;
		EndIf;
	EndDo;
	
	UndividedMetadataObjectsCopy = Common.CopyRecursive(UndividedMetadataObjects);
	SystemAdministratorRoleComposition(SeparatedMetadataObjects, UndividedMetadataObjectsCopy, Exceptions);
	RoleCompositionFullRights(SeparatedMetadataObjects, UndividedMetadataObjects, Exceptions);
	
EndProcedure

Procedure SystemAdministratorRoleComposition(SeparatedMetadataObjects, UndividedMetadataObjects, Exceptions)
	
	SystemAdministratorRoleFile = RoleCompositionFilePath("SystemAdministrator");
	SystemAdministratorRole1 = Metadata.Roles.SystemAdministrator;
	
	DOMDocument         = DOMDocument(SystemAdministratorRoleFile);
	Dereferencer      = Undefined;
	
	// Check basic role properties.
	If Not RoleBasicPropertiesSetCorrectly(DOMDocument, SystemAdministratorRole1, False, Dereferencer) Then
		Return; // Critical error, beyond autofixing. Abort the check.
	EndIf;
	
	// Check role rights.
	AllowedObjects = AcceptableRights(False);
	ChangesMade = False;
	
	ResultComposition = EvaluateXPathExpression(XPathExpressionRoleComposition(), DOMDocument, Dereferencer);
	While True Do
		
		CompositionItem  = ResultComposition.IterateNext();
		If CompositionItem = Undefined Then
			Break;
		EndIf;
		
		FullObjectName = CompositionItem.FirstChild.TextContent;
		If Not IsDemoSSL() And Not IsSSLObject(Common.MetadataObjectByFullName(FullObjectName)) Then
			Continue;
		EndIf;
		
		If Exceptions.Get(FullObjectName)= True Then
			Continue;
		EndIf;
		
		NameParts = StrSplit(FullObjectName, ".");
		ObjectType = NameParts[0];
		
		If Not AllowedObjects.Property(ObjectType) Then
			// Check only the objects included in the separators.
			Continue;
		EndIf;
		
		NameForError = MetadataObjectInConfigurationLanguageKindName[ObjectType] + "." + NameParts[1];
		
		If NameParts.Count() > 2 Then
			If NameParts[2] = "Command" Then
				Continue; // Keep rights to commands intact.
			EndIf;
			// Rights to attributes are not set.
			If FixError("NoRightsToSAAttributes") And HasSeparatorsCompositionErrors <> True Then
				For Each Right In CompositionItem.ChildNodes Do
					If Right.NodeName = RoleObjectRightProperty() Then
						Right.LastChild.TextContent = "true";
					EndIf;
				EndDo;
				ChangesMade = True;
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В роли %1 для %2 не установлены права на реквизит %3';
						|en = 'Access rights to attribute %3 are not set for %2 in role %1';"),
					"SystemAdministrator", NameForError, NameParts[3]);
				MetadataObject = Common.MetadataObjectByFullName(NameForError);
				AddError(MetadataObject,
					StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В роли %1 должны быть всегда установлены права на реквизиты';
																				|en = 'Access rights to attributes must always be set in role %1';"), "SystemAdministrator"),
					ErrorText);
			EndIf;
			Continue;
		EndIf;
		
		If SeparatedMetadataObjects.Get(FullObjectName) = False Then
			// Rights to separated objects are illegal. Delete the rights.
			If FixError("RedundantRightsToASharedObject") And HasSeparatorsCompositionErrors <> True Then
				For Each Right In CompositionItem.ChildNodes Do
					If Right.NodeName = RightsNameProperty() Then
						Continue;
					Else
						Right.LastChild.TextContent = "false";
					EndIf;
				EndDo;
				ChangesMade = True;
			Else
				If IsDemoSSL() Then
					ErrorTemplate = NStr("ru = 'В роли %1 избыточно установлены права на %2.
						|Возможно некорректно установлены значения разделителей.';
						|en = 'Redundant access rights to %2 are set in role %1.
						|Separator values might be set incorrectly.';");
				Else
					ErrorTemplate = NStr("ru = 'В роли %1 избыточно установлены права на %2';
										|en = 'Redundant access rights to %2 are set in role %1';");
				EndIf;
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, "SystemAdministrator", NameForError);
				MetadataObject = Common.MetadataObjectByFullName(NameForError);
				AddError(MetadataObject,
					StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В роли %1 избыточно установлены права на разделенный объект';
																				|en = 'Redundant access rights to a separated object are set in role %1';"), "SystemAdministrator"),
					ErrorText);
			EndIf;
		ElsIf UndividedMetadataObjects.Get(FullObjectName) = False Then
			AcceptableRights = Common.CopyRecursive(AllowedObjects[ObjectType]);
			// Check for illegal object rights, such as "Delete interactively".
			RightsList = New Array;
			For Each Right In CompositionItem.ChildNodes Do
				If Right.NodeName = RightsNameProperty() Then
					Continue;
				EndIf;
				NameOfRight = Right.FirstChild.TextContent;
				If Not AcceptableRights.Property(NameOfRight) Then
					Continue;
				EndIf;
				If AcceptableRights.Property(NameOfRight) Then
					AcceptableRights[NameOfRight] = True;
				Else
					If FixError("ProhibitedRightsInstalled") And HasSeparatorsCompositionErrors <> True Then
						Right.LastChild.TextContent = "false"; // Illegal right to the object. Delete the right.
						ChangesMade = True;
					Else
						RightsList.Add(NameOfRight);
					EndIf;
				EndIf;
			EndDo;
	
			If ValueIsFilled(RightsList) Then
				If IsDemoSSL() Then
					ErrorTemplate = NStr("ru = 'В роли %1 для %2 установлены запрещенные права:
						| %3.
						|Возможно некорректно установлены значения разделителей.';
						|en = 'These restricted access rights are set for %2 in role %1:
						|%3.
						|Separator values might be set incorrectly.';");
				Else
					ErrorTemplate = NStr("ru = 'В роли %1 для %2 установлены запрещенные права:
						|%3';
						|en = 'These restricted access rights are set for %2 in role %1:
						|%3';");
				EndIf;
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTemplate, "SystemAdministrator", NameForError, StrConcat(RightsList, Chars.LF));
				MetadataObject = Common.MetadataObjectByFullName(NameForError);
				AddError(MetadataObject,
					StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В роли %1 установлены запрещенные права на объект';
																				|en = 'Restricted access rights to an object are set in role %1';"), "SystemAdministrator"),
					ErrorText);
			EndIf;
			
			RightsList = New Array;
			
			For Each Right In AcceptableRights Do
				If TypeOf(Right.Value) = Type("String") Then
					If FixError("NecessaryRightsNotSet") And HasSeparatorsCompositionErrors <> True Then
						// Required rights are missing. Grant the rights.
						NodeRight = CompositionItem.AppendChild(DOMDocument.CreateElement(RoleObjectRightProperty()));
						AddDOMNodeProperty(DOMDocument, NodeRight, RightsNameProperty(), Right.Key);
						AddDOMNodeProperty(DOMDocument, NodeRight, RightValueProperty(), "true");
						ChangesMade = True;
					Else
						RightsList.Add(Right.Value);
					EndIf;
				EndIf;
			EndDo;
				
			If ValueIsFilled(RightsList) Then
				If IsDemoSSL() Then
					ErrorTemplate = NStr("ru = 'В роли %1 для %2 не установлены необходимые права:
						|%3.
						|Возможно, некорректно установлены значения разделителей.';
						|en = 'Role ""%1"" for ""%2"" requires the following access rights:
						|%3.
						|Perhaps, the separator values are misplaced.';");
				Else
					ErrorTemplate = NStr("ru = 'В роли %1 для %2 не установлены необходимые права:
						|%3';
						|en = 'Role ""%1"" for ""%2"" requires the following access rights:
						|%3';");
				EndIf;
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTemplate, "SystemAdministrator", NameForError, StrConcat(RightsList, Chars.LF));
				MetadataObject = Common.MetadataObjectByFullName(NameForError);
				AddError(MetadataObject,
					StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В роли %1 не установлены необходимые права на объект';
																				|en = 'Required access rights to an object are not set in role %1';"), "SystemAdministrator"),
					ErrorText);
			EndIf;
			
			UndividedMetadataObjects.Delete(FullObjectName);
		EndIf;
	EndDo;
	
	// Add missing objects.
	CollectionResult        = EvaluateXPathExpression(XPathExpressionRoleDescription(), DOMDocument, Dereferencer);
	CollectionCompositionElements = CollectionResult.IterateNext();
	For Each Object In UndividedMetadataObjects Do
		
		If Not IsDemoSSL() And Not IsSSLObject(Common.MetadataObjectByFullName(Object.Key)) Then
			Continue;
		EndIf;
		
		NameParts = StrSplit(Object.Key, ".");
		ObjectType = NameParts[0];
		NameForError = MetadataObjectInConfigurationLanguageKindName[ObjectType] + "." + NameParts[1];
		
		If FixError("NecessaryRightsNotSet") And HasSeparatorsCompositionErrors <> True Then
			NodeRoleObject = CollectionCompositionElements.AppendChild(DOMDocument.CreateElement(RoleObjectProperty()));
			AddDOMNodeProperty(DOMDocument, NodeRoleObject, RoleObjectNameProperty(), Object.Key);
			AcceptableRights = AllowedObjects[ObjectType];
			For Each Right In AcceptableRights Do
				NodeRight = NodeRoleObject.AppendChild(DOMDocument.CreateElement(RoleObjectRightProperty()));
				AddDOMNodeProperty(DOMDocument, NodeRight, RightsNameProperty(), Right.Key);
				AddDOMNodeProperty(DOMDocument, NodeRight, RightValueProperty(), "true");
			EndDo;
			ChangesMade = True;
		Else
			If IsDemoSSL() Then
				ErrorTemplate = NStr("ru = 'В роли %1 для %2 должны быть установлены все права, кроме запрещенных.
					|Возможно некорректно установлены значения разделителей.';
					|en = 'All access rights, except for restricted ones, must be set for %2 in role %1.
					|Separator values might be set incorrectly.';");
			Else
				ErrorTemplate = NStr("ru = 'В роли %1 для %2 должны быть установлены все права, кроме запрещенных';
									|en = 'All access rights, except for restricted ones, must be set for %2 in role %1';");
			EndIf;
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, "SystemAdministrator", NameForError);
			MetadataObject = Common.MetadataObjectByFullName(NameForError);
			AddError(MetadataObject, 
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В роли %1 не установлены необходимые права на объект';
																			|en = 'Required access rights to an object are not set in role %1';"), "SystemAdministrator"),
				ErrorText);
		EndIf;
	EndDo;
	
	// If autocorrection is enabled, save changes to the role file.
	If ChangesMade Then
		WriteDOMDocument(DOMDocument, SystemAdministratorRoleFile);
		AddError(SystemAdministratorRole1, 
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Права для роли %1 не соответствуют ожидаемым';
																		|en = 'Access rights for role %1 do not match the expected rights';"), "SystemAdministrator"),
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Исправлено. Права для роли %1 установлены согласно значению разделителей';
																		|en = 'Fixed. Access rights for role %1 are set according to separator values';"), "SystemAdministrator"));
		FilesToUpload.Add(SystemAdministratorRoleFile);
	EndIf;
	
EndProcedure

Procedure RoleCompositionFullRights(SeparatedMetadataObjects, UndividedMetadataObjects, Exceptions)
	
	// Do not check rights for shared objects.
	// Skip objects that are not listed in separators (except for journals and sequences).
	
	FullRightsRoleFile = RoleCompositionFilePath("FullAccess");
	FullAccessRole     = Metadata.Roles.FullAccess;
	DOMDocument         = DOMDocument(FullRightsRoleFile);
	Dereferencer      = Undefined;
	
	// Check basic role properties.
	If Not RoleBasicPropertiesSetCorrectly(DOMDocument, FullAccessRole, True, Dereferencer) Then
		Return; // Critical error, beyond autofixing. Abort the check.
	EndIf;
	
	// Check role rights.
	AllowedObjects = AcceptableRights(True);
	ChangesMade = False;
	
	PermittedRightsToUndivided = New Structure;
	PermittedRightsToUndivided.Insert("Read");
	PermittedRightsToUndivided.Insert("View");
	PermittedRightsToUndivided.Insert("InputByString");
	
	PermittedRightsToShared = New Structure;
	PermittedRightsToShared.Insert("InteractiveDelete", NStr("ru = 'Интерактивное удаление';
																	|en = 'Delete interactively';"));
	PermittedRightsToShared.Insert("InteractiveDeletePredefinedData", NStr("ru = 'Интерактивное удаление предопределенных';
																					|en = 'Delete predefined items interactively';"));
	PermittedRightsToShared.Insert("InteractiveSetDeletionMarkPredefinedData", NStr("ru = 'Интерактивная пометка на удаление предопределенных';
																							|en = 'Mark predefined items for deletion interactively';"));
	PermittedRightsToShared.Insert("InteractiveClearDeletionMarkPredefinedData", NStr("ru = 'Интерактивное снятие пометки удаления предопределенных';
																								|en = 'Unmark predefined items for deletion interactively';"));
	PermittedRightsToShared.Insert("InteractiveDeleteMarkedPredefinedData", NStr("ru = 'Интерактивное удаление помеченных предопределенных';
																						|en = 'Delete predefined items marked for deletion interactively';"));
	
	ResultComposition = EvaluateXPathExpression(XPathExpressionRoleComposition(), DOMDocument, Dereferencer);
	While True Do
		
		CompositionItem  = ResultComposition.IterateNext();
		If CompositionItem = Undefined Then
			Break;
		EndIf;
		
		FullObjectName = CompositionItem.FirstChild.TextContent;
		If Not IsDemoSSL() And Not IsSSLObject(Common.MetadataObjectByFullName(FullObjectName)) Then
			Continue;
		EndIf;
		
		If Exceptions.Get(FullObjectName)= True Then
			Continue;
		EndIf;
		
		NameParts = StrSplit(FullObjectName, ".");
		ObjectType = NameParts[0];
		
		If Not AllowedObjects.Property(ObjectType) Then
			// Check only objects included in the separators.
			Continue;
		EndIf;
		
		NameForError = MetadataObjectInConfigurationLanguageKindName[ObjectType] + "." + NameParts[1];
		
		If NameParts.Count() > 2 Then
			If NameParts[2] = "Command" Then
				Continue; // Keep rights to commands intact.
			EndIf;
			// Rights to attributes are not set.
			If FixError("NoRightsToSPAttributes") And HasSeparatorsCompositionErrors <> True Then
				For Each Right In CompositionItem.ChildNodes Do
					If Right.NodeName = RoleObjectRightProperty() Then
						Right.LastChild.TextContent = "true";
					EndIf;
				EndDo;
				ChangesMade = True;
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В роли %1 для %2 не установлены права на реквизит %3';
						|en = 'Access rights to attribute %3 are not set for %2 in role %1';"),
					"FullAccess", NameForError, NameParts[3]);
				MetadataObject = Common.MetadataObjectByFullName(NameForError);
				AddError(MetadataObject,
					StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В роли %1 должны быть всегда установлены права на реквизиты';
																				|en = 'Access rights to attributes must always be set in role %1';"), "FullAccess"),
					ErrorText);
			EndIf;
			Continue;
		EndIf;
		
		// Shared objects support only "Read," "View," and "Input by string" rights.
		If UndividedMetadataObjects.Get(FullObjectName) = False Then
			// Populate current object rights.
			InstalledRights = Common.CopyRecursive(AllowedObjects[ObjectType]);
			For Each Right In CompositionItem.ChildNodes Do
				If Right.NodeName = RoleObjectRightProperty() Then
					If Not InstalledRights.Property(Right.FirstChild.TextContent) Then
						Continue;
					EndIf;
					InstalledRights[Right.FirstChild.TextContent] = True;
				EndIf;
			EndDo;
			
			RightsList = New Array;

			For Each Right In InstalledRights Do
				If PermittedRightsToUndivided.Property(Right.Key) Then
					Continue; // Don't check allowed rights.
				EndIf;
				If TypeOf(Right.Value) = Type("String") Then
					If FixError("ProhibitedRightsInstalled") And HasSeparatorsCompositionErrors <> True Then
						// Required rights are missing. Grant the rights.
						NodeRight = CompositionItem.AppendChild(DOMDocument.CreateElement(RoleObjectRightProperty()));
						AddDOMNodeProperty(DOMDocument, NodeRight, RightsNameProperty(), Right.Key);
						AddDOMNodeProperty(DOMDocument, NodeRight, RightValueProperty(), "false");
						ChangesMade = True;
					Else
						RightsList.Add(Right.Value);
					EndIf;
				EndIf;
			EndDo;
			
			If ValueIsFilled(RightsList) Then
				If IsDemoSSL() Then
					ErrorTemplate = NStr("ru = 'В роли %1 для %2 установлено запрещенные права:
						|%3.
						|Возможно некорректно установлены значения разделителей.';
						|en = 'The restricted access right is set for %2 in role %1:
						|%3.
						|Separator values might be set incorrectly.';");
				Else
					ErrorTemplate = NStr("ru = 'В роли %1 для %2 установлено запрещенные права:
						|%3';
						|en = 'These restricted access right is set for %2 in role %1:
						|%3';");
				EndIf;
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTemplate, "FullAccess", NameForError, StrConcat(RightsList, Chars.LF));
				MetadataObject = Common.MetadataObjectByFullName(NameForError);
				AddError(MetadataObject,
					StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В роли %1 установлены запрещенные права на объект';
																				|en = 'Restricted access rights to an object are set in role %1';"), "FullAccess"),
					ErrorText);
			EndIf;
			
			UndividedMetadataObjects.Delete(FullObjectName);
		ElsIf SeparatedMetadataObjects.Get(FullObjectName) = False Then
			AcceptableRights = Common.CopyRecursive(AllowedObjects[ObjectType]);
			
			// Check for illegal object rights, such as "Delete interactively".
			RightsList = New Array;
			For Each Right In CompositionItem.ChildNodes Do
				If Right.NodeName = RightsNameProperty() Then
					Continue;
				EndIf;
				NameOfRight = Right.FirstChild.TextContent;
				If Not AcceptableRights.Property(NameOfRight) Then
					Continue;
				EndIf;
				AcceptableRights[NameOfRight] = True;
				If PermittedRightsToShared.Property(NameOfRight) Then
					Continue;
				EndIf;
				
				If FixError("NecessaryRightsNotSet") And HasSeparatorsCompositionErrors <> True Then
					Right.LastChild.TextContent = "true"; // Set all rights except for prohibited ones.
					ChangesMade = True;
				Else
					RightsList.Add(AllowedObjects[ObjectType][NameOfRight]);
				EndIf;
			EndDo;
			
			If ValueIsFilled(RightsList) Then
				If IsDemoSSL() Then
					ErrorTemplate = NStr("ru = 'В роли %1 для %2 не установлены необходимые права:
						|%3.
						|Возможно некорректно установлены значения разделителей.';
						|en = 'Role ""%1"" for ""%2"" requires the following access rights:
						|%3.
						|Perhaps, the separator values are misplaced.';");
				Else
					ErrorTemplate = NStr("ru = 'В роли %1 для %2 не установлены необходимые права:
						|%3';
						|en = 'Role ""%1"" for ""%2"" requires the following access rights:
						|%3';");
				EndIf;
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTemplate, "FullAccess", NameForError, StrConcat(RightsList, Chars.LF));
				MetadataObject = Common.MetadataObjectByFullName(NameForError);
				AddError(MetadataObject,
					StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В роли %1 не установлены необходимые права на объект';
																				|en = 'Required access rights to an object are not set in role %1';"), "FullAccess"),
					ErrorText);
			EndIf;
			
			RightsList = New Array;
			For Each Right In AcceptableRights Do
				If TypeOf(Right.Value) = Type("String") Then
					If PermittedRightsToShared.Property(Right.Key) Then
						If FixError("ProhibitedRightsInstalled") And HasSeparatorsCompositionErrors <> True Then
							// Required rights are missing. Grant the rights.
							NodeRight = CompositionItem.AppendChild(DOMDocument.CreateElement(RoleObjectRightProperty()));
							AddDOMNodeProperty(DOMDocument, NodeRight, RightsNameProperty(), Right.Key);
							AddDOMNodeProperty(DOMDocument, NodeRight, RightValueProperty(), "false");
							ChangesMade = True;
						Else
							RightsList.Add(Right.Value);
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			
			If ValueIsFilled(RightsList) Then
				If IsDemoSSL() Then
					ErrorTemplate = NStr("ru = 'В роли %1 для %2 установлены запрещенные права:
						| %3.
						|Возможно некорректно установлены значения разделителей.';
						|en = 'These restricted access rights are set for %2 in role %1:
						|%3.
						|Separator values might be set incorrectly.';");
				Else
					ErrorTemplate = NStr("ru = 'В роли %1 для %2 установлены запрещенные права:
						|%3';
						|en = 'These restricted access rights are set for %2 in role %1:
						|%3';");
				EndIf;
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTemplate, "FullAccess", NameForError, StrConcat(RightsList, Chars.LF));
				MetadataObject = Common.MetadataObjectByFullName(NameForError);
				AddError(MetadataObject,
					StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В роли %1 установлены запрещенные права на объект';
																				|en = 'Restricted access rights to an object are set in role %1';"), "FullAccess"),
					ErrorText);
			EndIf;
			
			SeparatedMetadataObjects.Delete(FullObjectName);
		EndIf;
	EndDo;
	
	// If a role file is missing data about a shared object, then all rights are set for that object.
	// Revoke all forbidden permissions, and keep only allowed permissions.
	CollectionResult        = EvaluateXPathExpression(XPathExpressionRoleDescription(), DOMDocument, Dereferencer);
	CollectionCompositionElements = CollectionResult.IterateNext();
	For Each Object In UndividedMetadataObjects Do
		
		If Not IsDemoSSL() And Not IsSSLObject(Common.MetadataObjectByFullName(Object.Key)) Then
			Continue;
		EndIf;
		
		NameParts = StrSplit(Object.Key, ".");
		ObjectType = NameParts[0];
		NameForError = MetadataObjectInConfigurationLanguageKindName[ObjectType] + "." + NameParts[1];
		
		If FixError("NecessaryRightsNotSet") And HasSeparatorsCompositionErrors <> True Then
			
			NodeRoleObject = CollectionCompositionElements.AppendChild(DOMDocument.CreateElement(RoleObjectProperty()));
			AddDOMNodeProperty(DOMDocument, NodeRoleObject, RoleObjectNameProperty(), Object.Key);
			
			AcceptableRights = AllowedObjects[ObjectType];
			For Each Right In AcceptableRights Do
				If PermittedRightsToUndivided.Property(Right.Key) Then
					Continue;
				EndIf;
				NodeRight = NodeRoleObject.AppendChild(DOMDocument.CreateElement(RoleObjectRightProperty()));
				AddDOMNodeProperty(DOMDocument, NodeRight, RightsNameProperty(), Right.Key);
				AddDOMNodeProperty(DOMDocument, NodeRight, RightValueProperty(), "false");
			EndDo;
			ChangesMade = True;
		Else
			If IsDemoSSL() Then
				ErrorTemplate = NStr("ru = 'В роли %1 для %2 не должны быть установлены права.
				|Возможно некорректно установлены значения разделителей.';
				|en = 'Access rights cannot be set for %2 in role %1.
				|Separator values might be set incorrectly.';");
			Else
				ErrorTemplate = NStr("ru = 'В роли %1 для %2 не должны быть установлены права';
									|en = 'Access rights cannot be set for %2 in role %1';");
			EndIf;
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, "FullAccess", NameForError);
			MetadataObject = Common.MetadataObjectByFullName(NameForError);
			AddError(MetadataObject,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В роли %1 не установлены необходимые права на объект';
																			|en = 'Required access rights to an object are not set in role %1';"), "FullAccess"),
				ErrorText);
		EndIf;
	EndDo;
	
	// If a role file is missing data about a separated object, then all rights are set for that object.
	// Revoke all forbidden permissions.
	For Each Object In SeparatedMetadataObjects Do
		
		If Not IsDemoSSL() And Not IsSSLObject(Common.MetadataObjectByFullName(Object.Key)) Then
			Continue;
		EndIf;
		
		If Exceptions.Get(Object.Key)= True Then
			Continue;
		EndIf;
		
		NameParts     = StrSplit(Object.Key, ".");
		ObjectType     = NameParts[0];
		NameForError   = MetadataObjectInConfigurationLanguageKindName[ObjectType] + "." + NameParts[1];
		RightsAdded = False;
		
		If FixError("ProhibitedRightsInstalled") And HasSeparatorsCompositionErrors <> True Then
			NodeRoleObject = DOMDocument.CreateElement(RoleObjectProperty());
			AddDOMNodeProperty(DOMDocument, NodeRoleObject, RoleObjectNameProperty(), Object.Key);
		EndIf;
		AcceptableRights = AllowedObjects[ObjectType];
		RightsList = New Array;
		For Each Right In AcceptableRights Do
			If PermittedRightsToShared.Property(Right.Key) Then
				
				If FixError("ProhibitedRightsInstalled") And HasSeparatorsCompositionErrors <> True Then
					NodeRight = NodeRoleObject.AppendChild(DOMDocument.CreateElement(RoleObjectRightProperty()));
					AddDOMNodeProperty(DOMDocument, NodeRight, RightsNameProperty(), Right.Key);
					AddDOMNodeProperty(DOMDocument, NodeRight, RightValueProperty(), "false");
					RightsAdded = True;
				Else
					RightsList.Add(AcceptableRights[Right.Key]);
				EndIf;
			EndIf;
		EndDo;
			
		If ValueIsFilled(RightsList) Then
			If IsDemoSSL() Then
				ErrorTemplate = NStr("ru = 'В роли %1 для %2 не должны быть установлены права:
					| %3.
					|Возможно некорректно установлены значения разделителей.';
					|en = 'Role ""%1"" for ""%2"" is assigned the following unsupported access rights:
					|%3.
					|Perhaps, the separator values are misplaced.';");
			Else
				ErrorTemplate = NStr("ru = 'В роли %1 для %2 не должны быть установлены права:
					|%3';
					|en = 'Role ""%1"" for ""%2"" is assigned the following unsupported access rights:
					|%3';");
			EndIf;
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTemplate, "FullAccess", NameForError, StrConcat(RightsList, Chars.LF));
			MetadataObject = Common.MetadataObjectByFullName(NameForError);
			AddError(MetadataObject,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В роли %1 установлены запрещенные права на объект';
																			|en = 'Restricted access rights to an object are set in role %1';"), "FullAccess"),
				ErrorText);
		EndIf;

		If RightsAdded Then
			CollectionCompositionElements.AppendChild(NodeRoleObject);
			ChangesMade = True;
		EndIf;
	EndDo;
	
	// If autocorrection is enabled, save changes to the role file.
	If ChangesMade Then
		WriteDOMDocument(DOMDocument, FullRightsRoleFile);
		AddError(FullAccessRole,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Права для роли %1 не соответствуют ожидаемым';
																		|en = 'Access rights for role %1 do not match the expected rights';"), "FullAccess"),
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Исправлено. Права для роли %1 установлены согласно значению разделителей';
																		|en = 'Fixed. Access rights for role %1 are set according to separator values';"), "FullAccess"));
		FilesToUpload.Add(FullRightsRoleFile);
	EndIf;
	
EndProcedure

Function RoleBasicPropertiesSetCorrectly(DOMDocument, RoleMetadata, SetNewObjectsRights, Dereferencer = Undefined)
	
	BasicProperties = New ValueList;
	BasicProperties.Add(SetRightsForNewObjectsProperty(), NStr("ru = 'Устанавливать права для новых объектов';
																				|en = 'Set rights for new objects';"), SetNewObjectsRights);
	BasicProperties.Add(SetRightsForDetailsAndTablePartsByDefaultProperty(), NStr("ru = 'Устанавливать права для реквизитов и табличных частей по умолчанию';
																										|en = 'Set rights for attributes and tables by default';"), True);
	BasicProperties.Add(IndependentSubordinateObjectsRightsProperty(), NStr("ru = 'Независимые права подчиненных объектов';
																				|en = 'Independent rights of subordinate objects';"), False);
		
	For Each BasicProperty In BasicProperties Do
		Result            = EvaluateXPathExpression(ExpressionXPathBasicPropertyOfRole(BasicProperty.Value), DOMDocument, Dereferencer);
		BasePropertyNode = Result.IterateNext();
		PropertyValue     = BasePropertyNode.TextContent = "true";
		If PropertyValue <> BasicProperty.Check Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Значение свойства %1 установлено в значение %2. Ожидаемое значение %3';
					|en = 'The %1 property value is set to value %2. The expected value is %3';"),
				BasicProperty.Presentation, Format(PropertyValue, NStr("ru = 'БЛ= False; БИ=Истина';
																			|en = 'BF=False; BT=True';")),
				Format(BasicProperty.Check, NStr("ru = 'БЛ= False; БИ=Истина';
													|en = 'BF=False; BT=True';")));
			AddError(RoleMetadata,
				NStr("ru = 'Значение базового свойства роли отличается от поставляемого';
					|en = 'The role basic property value does not match the built-in property value.';"), ErrorText);
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Function AcceptableRights(IncludingProhibited)
	
	AcceptableRights = New Structure;
	
	RightsStructure = RightsStructure(, IncludingProhibited);
	AcceptableRights.Insert("Constant", RightsStructure);
	AcceptableRights.Insert("CalculationRegister", RightsStructure);
	
	RightsStructure = RightsStructure("TotalsControl", IncludingProhibited);
	AcceptableRights.Insert("InformationRegister", RightsStructure);
	AddHistoryChangesRights(AcceptableRights.InformationRegister);
	AcceptableRights.Insert("AccumulationRegister", RightsStructure);
	AcceptableRights.Insert("AccountingRegister", RightsStructure);
	
	RightsStructure = RightsStructure("AddingRemoving,InputByString", IncludingProhibited);
	AcceptableRights.Insert("ExchangePlan", RightsStructure);
	
	RightsStructure = RightsStructure("AddingRemoving,Predefined,InputByString", IncludingProhibited);
	AcceptableRights.Insert("Catalog", RightsStructure);
	AddHistoryChangesRights(AcceptableRights.Catalog);
	AcceptableRights.Insert("ChartOfCharacteristicTypes", RightsStructure);
	AddHistoryChangesRights(AcceptableRights.ChartOfCharacteristicTypes);
	AcceptableRights.Insert("ChartOfAccounts", RightsStructure);
	AddHistoryChangesRights(AcceptableRights.ChartOfAccounts);
	AcceptableRights.Insert("ChartOfCalculationTypes", RightsStructure);
	AddHistoryChangesRights(AcceptableRights.ChartOfCalculationTypes);
	
	RightsStructure = RightsStructure("AddingRemoving,InputByString,Documents", IncludingProhibited);
	AcceptableRights.Insert("Document", RightsStructure);
	AddHistoryChangesRights(AcceptableRights.Document);
	
	RightsStructure = RightsStructure("AddingRemoving,InputByString,BusinessProcesses", IncludingProhibited);
	AcceptableRights.Insert("BusinessProcess", RightsStructure);
	AddHistoryChangesRights(AcceptableRights.BusinessProcess);
	
	RightsStructure = RightsStructure("AddingRemoving,InputByString,Tasks", IncludingProhibited);
	AcceptableRights.Insert("Task", RightsStructure);
	AddHistoryChangesRights(AcceptableRights.Task);
	
	RightsStructure = RightsStructure("Sequences", IncludingProhibited);
	AcceptableRights.Insert("Sequence", RightsStructure);
	
	RightsStructure = RightsStructure("DocumentJournals", IncludingProhibited);
	AcceptableRights.Insert("DocumentJournal", RightsStructure);
	
	Return AcceptableRights;
	
EndFunction

Procedure AddHistoryChangesRights(RightsStructure)
	RightsStructure.Insert("ReadDataHistory", NStr("ru = 'Чтение истории данных';
													|en = 'Read data history';"));
	RightsStructure.Insert("ReadDataHistoryOfMissingData", NStr("ru = 'Чтение истории данных отсутствующих данных';
																|en = 'Read data history of missing data';"));
	RightsStructure.Insert("UpdateDataHistory", NStr("ru = 'Изменение истории данных';
													|en = 'Update data history';"));
	RightsStructure.Insert("UpdateDataHistoryOfMissingData", NStr("ru = 'Изменение истории данных отсутствующих данных';
																	|en = 'Update data history of missing data';"));
	RightsStructure.Insert("UpdateDataHistorySettings", NStr("ru = 'Изменение настроек истории данных';
															|en = 'Update data history settings';"));
	RightsStructure.Insert("UpdateDataHistoryVersionComment", NStr("ru = 'Изменение комментария версии истории данных';
																	|en = 'Update data history version comment';"));
	RightsStructure.Insert("ViewDataHistory", NStr("ru = 'Просмотр истории данных';
													|en = 'View data history';"));
	RightsStructure.Insert("EditDataHistoryVersionComment", NStr("ru = 'Редактирование комментария версии истории данных';
																|en = 'Edit data history version comment';"));
	RightsStructure.Insert("SwitchToDataHistoryVersion", NStr("ru = 'Переход на версию истории данных';
																|en = 'Switching to data history version';"));
EndProcedure

Function RightsStructure(RequiredRights = "", IncludingProhibited = False)
	
	// The following rights are forbidden for all objects:
	// InteractiveDelete
	// InteractiveDeletePredefinedData
	// InteractiveSetDeletionMarkPredefinedData
	// InteractiveClearDeletionMarkPredefinedData
	// InteractiveDeleteMarkedPredefinedData.
	
	RightsStructure = New Structure;
	
	If StrFind(RequiredRights, "Sequences") <> 0 Then
		RightsStructure.Insert("Read", NStr("ru = 'Чтение';
											|en = 'Read';"));
		RightsStructure.Insert("Update", NStr("ru = 'Изменение';
												|en = 'Update';"));
		Return RightsStructure;
	EndIf;
	
	If StrFind(RequiredRights, "DocumentJournals") <> 0 Then
		RightsStructure.Insert("Read", NStr("ru = 'Чтение';
											|en = 'Read';"));
		RightsStructure.Insert("View", NStr("ru = 'Просмотр';
											|en = 'View';"));
		Return RightsStructure;
	EndIf;
	
	// Basic access for all types, except for journals and sequences.
	RightsStructure.Insert("Read", NStr("ru = 'Чтение';
										|en = 'Read';"));
	RightsStructure.Insert("Update", NStr("ru = 'Изменение';
											|en = 'Update';"));
	RightsStructure.Insert("View", NStr("ru = 'Просмотр';
										|en = 'View';"));
	RightsStructure.Insert("Edit", NStr("ru = 'Редактирование';
										|en = 'Edit';"));
	
	If StrFind(RequiredRights, "TotalsControl") <> 0 Then
		RightsStructure.Insert("TotalsControl", NStr("ru = 'Управление итогами';
													|en = 'Totals management';"));
	EndIf;
	
	If StrFind(RequiredRights, "AddingRemoving") <> 0 Then
		RightsStructure.Insert("Insert", NStr("ru = 'Добавление';
												|en = 'Insert';"));
		RightsStructure.Insert("Delete", NStr("ru = 'Удаление';
												|en = 'Delete';"));
		RightsStructure.Insert("InteractiveInsert", NStr("ru = 'Интерактивное добавление';
														|en = 'Add interactively';"));
		If IncludingProhibited Then
			RightsStructure.Insert("InteractiveDelete", NStr("ru = 'Интерактивное удаление';
															|en = 'Delete interactively';"));
		EndIf;
		RightsStructure.Insert("InteractiveSetDeletionMark", NStr("ru = 'Интерактивная пометка удаления';
																	|en = 'Mark for deletion interactively';"));
		RightsStructure.Insert("InteractiveClearDeletionMark", NStr("ru = 'Интерактивное снятие пометки удаления';
																	|en = 'Unmark for deletion interactively';"));
		RightsStructure.Insert("InteractiveDeleteMarked", NStr("ru = 'Интерактивное удаление помеченных';
																|en = 'Delete items marked for deletion interactively';"));
	EndIf;
	
	If IncludingProhibited And StrFind(RequiredRights, "Predefined") <> 0 Then
		RightsStructure.Insert("InteractiveDeletePredefinedData", NStr("ru = 'Интерактивное удаление предопределенных';
																		|en = 'Delete predefined items interactively';"));
		RightsStructure.Insert("InteractiveSetDeletionMarkPredefinedData", NStr("ru = 'Интерактивная пометка на удаление предопределенных';
																				|en = 'Mark predefined items for deletion interactively';"));
		RightsStructure.Insert("InteractiveClearDeletionMarkPredefinedData", NStr("ru = 'Интерактивное снятие пометки удаления предопределенных';
																					|en = 'Unmark predefined items for deletion interactively';"));
		RightsStructure.Insert("InteractiveDeleteMarkedPredefinedData", NStr("ru = 'Интерактивное удаление помеченных предопределенных';
																			|en = 'Delete predefined items marked for deletion interactively';"));
	EndIf;
	
	If StrFind(RequiredRights, "InputByString") <> 0 Then
		RightsStructure.Insert("InputByString", NStr("ru = 'Ввод по строке';
													|en = 'Input by string';"));
	EndIf;
	
	If StrFind(RequiredRights, "Documents") <> 0 Then
		RightsStructure.Insert("Posting", NStr("ru = 'Проведение';
												|en = 'Post';"));
		RightsStructure.Insert("UndoPosting", NStr("ru = 'Отмена проведения';
													|en = 'Unpost';"));
		RightsStructure.Insert("InteractivePosting", NStr("ru = 'Интерактивное проведение';
															|en = 'Post interactively';"));
		RightsStructure.Insert("InteractivePostingRegular", NStr("ru = 'Интерактивное проведение неоперативное';
																|en = 'Backdate post interactively';"));
		RightsStructure.Insert("InteractiveUndoPosting", NStr("ru = 'Интерактивная отмена проведения';
																|en = 'Unpost interactively';"));
		RightsStructure.Insert("InteractiveChangeOfPosted", NStr("ru = 'Интерактивное изменение проведенных';
																|en = 'Modify posted items interactively';"));
	EndIf;
	
	If StrFind(RequiredRights, "BusinessProcesses") <> 0 Then
		RightsStructure.Insert("InteractiveActivate", NStr("ru = 'Интерактивная активация';
															|en = 'Interactive activation';"));
		RightsStructure.Insert("Start", NStr("ru = 'Старт';
											|en = 'Start';"));
		RightsStructure.Insert("InteractiveStart", NStr("ru = 'Интерактивный старт';
														|en = 'Interactive start';"));
	EndIf;
	
	If StrFind(RequiredRights, "Tasks") <> 0 Then
		RightsStructure.Insert("InteractiveActivate", NStr("ru = 'Интерактивная активация';
															|en = 'Interactive activation';"));
		RightsStructure.Insert("Execute", NStr("ru = 'Выполнение';
												|en = 'Execute';"));
		RightsStructure.Insert("InteractiveExecute", NStr("ru = 'Интерактивное выполнение';
															|en = 'Interactive execution';"));
	EndIf;
	
	Return RightsStructure;
	
EndFunction

#EndRegion

#Region AccessManagement

#Region ObsoleteProceduresAndFunctions

// Checks if restriction texts in different roles within an object/right/etc repeat each other.
// 
//
Procedure CheckAccessRestrictionsUse(AccessRestrictions)
	
	AccessRestrictionKinds = New ValueTable;
	AccessRestrictionKinds.Columns.Add("Table",          New TypeDescription("String"));
	AccessRestrictionKinds.Columns.Add("Right",            New TypeDescription("String"));
	AccessRestrictionKinds.Columns.Add("AccessKind",       New TypeDescription("String"));
	AccessRestrictionKinds.Columns.Add("LongDesc",         New TypeDescription("String"));
	AccessRestrictionKinds.Columns.Add("ObjectTable",   New TypeDescription("String"));
	AccessRestrictionKinds.Columns.Add("CollectionOrder", New TypeDescription("Number"));
	AccessRestrictionKinds.Columns.Add("RightsOrder",      New TypeDescription("Number"));
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("AccessRestrictions",  AccessRestrictions);
	ProcedureParameters.Insert("AccessRestrictionKinds", AccessRestrictionKinds);
	
	DefineTypesOfRightsRestrictions(ProcedureParameters);
	
EndProcedure

// For internal use only.
Procedure DefineTypesOfRightsRestrictions(Parameters)
	
	AccessRestrictionKinds = Parameters.AccessRestrictionKinds;
	AccessRestrictions  = Parameters.AccessRestrictions;
	
	RolesAssignment = Users.RolesAssignment();
	
	RolesForExternalUsersOnly =
		RolesAssignment.ForExternalUsersOnly;
	
	RolesSharedBetweenUsersAndExternalUsers =
		RolesAssignment.BothForUsersAndExternalUsers;
	
	Restrictions = New ValueTable;
	Restrictions.Columns.Add("Table");
	Restrictions.Columns.Add("Role");
	Restrictions.Columns.Add("RoleForUsers");
	Restrictions.Columns.Add("RoleForExternalUsers");
	Restrictions.Columns.Add("Right");
	Restrictions.Columns.Add("Fields");
	Restrictions.Columns.Add("Restriction");
	Restrictions.Columns.Add("RestrictionWithoutComment");
	
	Restrictions.Columns.Add("SpecifiedTable"); // Table specified in the restriction.
	Restrictions.Columns.Add("SpecifiedRight");   // Right specified in the restriction.
	
	For Each String In AccessRestrictions Do
		
		Properties = New Structure("Table, Role, Right, Fields, Restriction, RestrictionWithoutComment");
		FillPropertyValues(Properties, String);
		
		Properties.Restriction = RemoveRestrictingAccessBracketsAtRecordLevelUniversal(Properties.Restriction);
		
		// Delete newline characters at the beginning and end of the text.
		Properties.Restriction = TrimAll(Properties.Restriction);
		
		// Delete comments.
		Result = "";
		For RestrictionLineNumber = 1 To StrLineCount(Properties.Restriction) Do
			String = StrGetLine(Properties.Restriction, RestrictionLineNumber);
			CommentPosition = StrFind(String, "//");
			If CommentPosition > 0 Then
				String = Mid(String, 1, CommentPosition - 1);
			EndIf;
			If Not IsBlankString(Result) Then
				Result = Result + Chars.LF;
			EndIf;
			Result = Result + String;
		EndDo;
		Properties.RestrictionWithoutComment = TrimAll(Result);
		Restriction = Properties.RestrictionWithoutComment;
		
		If StrCompare(Properties.Role, "FullAccess") = 0
			Or StrCompare(Properties.Role, "SystemAdministrator") = 0 Then
			Continue;
		EndIf;
		
		NewRow = Restrictions.Add();
		FillPropertyValues(NewRow, Properties);
		NewRow.RoleForUsers =
			RolesForExternalUsersOnly.Find(Properties.Role) = Undefined;
		NewRow.RoleForExternalUsers =
			RolesForExternalUsersOnly.Find(Properties.Role) <> Undefined
			Or RolesSharedBetweenUsersAndExternalUsers.Find(Properties.Role) <> Undefined;
		
		If StrCompare(Properties.Right, "Create") = 0
		 Or StrCompare(Properties.Right, "Delete") = 0 Then
		
			// These access rights are not used in atomic access restrictions.
			// The "Add" restriction matches the "Update" restriction.
			// The "Delete" restriction is either not used or matches the "Update" restriction.
			SkipToRight = True;
		Else
			SkipToRight = False;
		EndIf;
		
		Restriction = StrReplace(Restriction, Chars.LF, " ");
		Restriction = StrReplace(Restriction, Chars.Tab, " ");
		While StrFind(Restriction, ", ") > 0 Do
			Restriction = StrReplace(Restriction, ", ", ",");
		EndDo;
		While StrFind(Restriction, " ,") > 0 Do
			Restriction = StrReplace(Restriction, " ,", ",");
		EndDo;
		
		If StrCompare(Left(Restriction, StrLen("#ByValues(")), "#ByValues(") = 0 Then
			
			Position = StrFind(Restriction, """");
			String = Mid(Restriction, Position + 1);
			
			NewRow.SpecifiedTable = Left(String, StrFind(String, """,""") - 1);
			CheckTableName(NewRow);
			
			CurrentRow = Mid(String, StrFind(String, """,""") + 3);
			NewRow.SpecifiedRight = Left(CurrentRow, StrFind(CurrentRow, """,""") - 1);
			CheckNameOfRight(NewRow);
			
			If SkipToRight Then
				Continue;
			EndIf;
			
			Position = StrFind(Restriction, """,""");
			String = Mid(Restriction, Position + 3);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			While Position > 0 Do
				
				AccessKind = Left(String, StrFind(String, """,""")-1);
				
				If ValueIsFilled(AccessKind) Then
					
					Position = StrFind(String, """,""");
					String = Mid(String, Position + 3);
					
					FullFieldName1 = Left(String, StrFind(String, """,""")-1);
					// @skip-check query-in-loop - Obsolete code (the standard RLS variant)
					AddAccessType(NewRow, AccessRestrictionKinds, AccessKind, FullFieldName1, "");
					
					Position = StrFind(String, """,""");
					String = Mid(String, Position + 3);
				Else
					Break;
				EndIf;
			EndDo;
			
		ElsIf (StrCompare(Left(Restriction, StrLen("#ByValuesExtended(")), "#ByValuesExtended(") = 0) 
			Or (StrCompare(Left(Restriction, StrLen("#ByValuesAndSetsAdvanced(")), "#ByValuesAndSetsAdvanced(") = 0) Then
			
			Position = StrFind(Restriction, """");
			String = Mid(Restriction, Position + 1);
			
			NewRow.SpecifiedTable = Left(String, StrFind(String, """,""") - 1);
			CheckTableName(NewRow);
			
			CurrentRow = Mid(String, StrFind(String, """,""") + 3);
			NewRow.SpecifiedRight = Left(CurrentRow, StrFind(CurrentRow, """,""") - 1);
			CheckNameOfRight(NewRow);
			
			If SkipToRight Then
				Continue;
			EndIf;
			
			Position = StrFind(Restriction, """,""");
			String = Mid(Restriction, Position + 3);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			AttachedTables = Left(String, StrFind(String, """,""")-1);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			While Position > 0 Do
				
				AccessKind = Left(String, StrFind(String, """,""")-1);
				
				If ValueIsFilled(AccessKind) Then
					
					Position = StrFind(String, """,""");
					String = Mid(String, Position + 3);
					
					FullFieldName1 = Left(String, StrFind(String, """,""")-1);
					// @skip-check query-in-loop - Obsolete code (the standard RLS variant)
					AddAccessType(NewRow, AccessRestrictionKinds, AccessKind, FullFieldName1, AttachedTables);
					
					Position = StrFind(String, """,""");
					String = Mid(String, Position + 3);
					
					Position = StrFind(String, """,""");
					String = Mid(String, Position + 3);
				Else
					Break;
				EndIf;
			EndDo;
			
		ElsIf StrCompare(Left(Restriction, StrLen("#BySetsOfValues(")), "#BySetsOfValues(") = 0 Then
			
			Position = StrFind(Restriction, """");
			String = Mid(Restriction, Position + 1);
			
			NewRow.SpecifiedTable = Left(String, StrFind(String, """,""") - 1);
			CheckTableName(NewRow);
			
			CurrentRow = Mid(String, StrFind(String, """,""") + 3);
			NewRow.SpecifiedRight = Left(CurrentRow, StrFind(CurrentRow, """,""") - 1);
			CheckNameOfRight(NewRow);
			
			If SkipToRight Then
				Continue;
			EndIf;
			
			Position = StrFind(Restriction, """,""");
			String = Mid(Restriction, Position + 3);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			FullFieldName1 = Left(String, StrFind(String, """,""")-1);
								
			AccessKind = "Object";
			
			If Not ValueIsFilled(FullFieldName1) Then
				FullFieldName1 = "Ref";
			EndIf;
			// @skip-check query-in-loop - Obsolete code (the standard RLS variant)
			AddAccessType(NewRow, AccessRestrictionKinds, AccessKind, FullFieldName1, "");
		EndIf;
	EndDo;
	
	// Remove the RightsSettings restriction kinds, for which the field has no types of right setting owners.
	Filter = New Structure("AccessKind, ObjectTable", "RightsSettings", "");
	FoundRows = AccessRestrictionKinds.FindRows(Filter);
	For Each String In FoundRows Do
		AccessRestrictionKinds.Delete(AccessRestrictionKinds.IndexOf(String));
	EndDo;
	
	// Check the restriction use by all fields.
	LineOtherFields = NStr("ru = '<Прочие поля>';
							|en = '<Other fields>';");
	
	MetadataObjectInformationRegisterObjectsVersions = Common.MetadataObjectByFullName("InformationRegister.ObjectsVersions");
	For Each String In Restrictions Do
		If StrCompare(String.Fields, LineOtherFields) <> 0 Then
			If MetadataObjectInformationRegisterObjectsVersions <> Undefined Then
				If String.Role    = "ReadObjectVersionInfo"
					And String.Table = MetadataObjectInformationRegisterObjectsVersions.FullName()
					And String.Right   = "Read"
					And String.Fields    = "ObjectVersion" Then
					Continue; // Exception.
				EndIf;
			EndIf;
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ограничения на уровне записей стандартно применяются сразу ко всем полям таблицы (""%6"").
				           |В роли %1 некорректно задано ограничение полей ""%2"" права ""%3"" таблицы ""%4"":
				           |%5';
							|en = 'Restrictions on the record level are usually applied to all table fields (%6) at once.
							|In the %1 role, the restriction of the ""%2"" fields in the ""%3"" right of the ""%4"" table is set incorrectly:
							|%5.';"),
				String.Role, String.Fields, String.Right, String.Table, String.Restriction, LineOtherFields);
				
			Role = Metadata.Roles.Find(String.Role);
			AddError(Role, NStr("ru = 'Ограничение не по всем полям';
										|en = 'The restriction is not by all fields';"), ErrorText);
		EndIf;
	EndDo;
	
	CompareRightsRestrictionsTypesDescriptions(RightsRestrictionsKindsCurrentDescription(),
		NewRightsRestrictionsTypesDescription(AccessRestrictionKinds));
	
EndProcedure

Function RightsRestrictionsKindsCurrentDescription()
	
	AccessControlModuleServiceRepeatIsp = Common.CommonModule("AccessManagementInternalCached");
	List = AccessControlModuleServiceRepeatIsp.PermanentMetadataObjectsRightsRestrictionsKinds(True);
	If TypeOf(List) = Type("String") Then
		Return List;
	EndIf;
	
	ExistingDescription = "";
	For Each String In List Do
		ExistingDescription = ExistingDescription
			+ String.FullTableName + "." + String.Right + "." + String.AccessKindName
			+ ?(ValueIsFilled(String.FullObjectTableName), "." + String.FullObjectTableName, "")
			+ Chars.LF;
	EndDo;
	
	Return ExistingDescription;
	
EndFunction

Function NewRightsRestrictionsTypesDescription(AccessRestrictionKinds)
	
	For Each String In AccessRestrictionKinds Do
		Text = Upper(String.Table);
		If StrStartsWith(Text, Upper("Catalog.")) Then
			String.CollectionOrder = 1;
			
		ElsIf StrStartsWith(Text, Upper("Document.")) Then
			String.CollectionOrder = 2;
			
		ElsIf StrStartsWith(Text, Upper("DocumentJournal.")) Then
			String.CollectionOrder = 3;
			
		ElsIf StrStartsWith(Text, Upper("ChartOfCharacteristicTypes.")) Then
			String.CollectionOrder = 4;
			
		ElsIf StrStartsWith(Text, Upper("ChartOfAccounts.")) Then
			String.CollectionOrder = 5;
			
		ElsIf StrStartsWith(Text, Upper("ChartOfCalculationTypes.")) Then
			String.CollectionOrder = 6;
			
		ElsIf StrStartsWith(Text, Upper("InformationRegister.")) Then
			String.CollectionOrder = 7;
			
		ElsIf StrStartsWith(Text, Upper("AccumulationRegister.")) Then
			String.CollectionOrder = 8;
			
		ElsIf StrStartsWith(Text, Upper("AccountingRegister.")) Then
			String.CollectionOrder = 9;
			
		ElsIf StrStartsWith(Text, Upper("CalculationRegister.")) Then
			String.CollectionOrder = 10;
			
		ElsIf StrStartsWith(Text, Upper("BusinessProcess.")) Then
			String.CollectionOrder = 11;
			
		ElsIf StrStartsWith(Text, Upper("Task.")) Then
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

Procedure CompareRightsRestrictionsTypesDescriptions(ExistingDescription, NewDetails)
	
	ErrorsDiscrepancies = New ValueTable;
	ErrorsDiscrepancies.Columns.Add("FullMetadataObjectName1",                       New TypeDescription("String"));
	ErrorsDiscrepancies.Columns.Add("MissingConstraintsErrorText", New TypeDescription("String"));
	ErrorsDiscrepancies.Columns.Add("UnnecessaryRestrictionsErrorText",      New TypeDescription("String"));
	
	CountOfRows = StrLineCount(NewDetails);
	For LineNumber = 1 To CountOfRows Do
		String = StrGetLine(NewDetails, LineNumber);
		If StrFind(ExistingDescription, Mid(String, 3)) = 0 Then
			FixRightsRestrictionsTypesDivergenceError(String, ErrorsDiscrepancies, True);
		EndIf;
	EndDo;
	
	CountOfRows = StrLineCount(ExistingDescription);
	For LineNumber = 1 To CountOfRows Do
		String = "	|" + StrGetLine(ExistingDescription, LineNumber);
		If StrFind(NewDetails, TrimR(String)) = 0 Then
			FixRightsRestrictionsTypesDivergenceError(String, ErrorsDiscrepancies, False);
		EndIf;
	EndDo;
	
	ErrorTitle = NStr("ru = 'Некорректно заполнены виды ограничений прав объектов метаданных';
							|en = 'Right restriction kinds of metadata objects are filled in incorrectly';");
	
	For Each CurrentDiscrepancyError In ErrorsDiscrepancies Do
		
		If ValueIsFilled(CurrentDiscrepancyError.MissingConstraintsErrorText)
			And ValueIsFilled(CurrentDiscrepancyError.UnnecessaryRestrictionsErrorText) Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В процедуре %1 общего модуля %2:
				           |%3
				           |%4';
							|en = 'In procedure %1 of common module %2:
							|%3
							|%4';"),
				"OnFillMetadataObjectsAccessRestrictionKinds",
				"AccessManagementOverridable",
				CurrentDiscrepancyError.MissingConstraintsErrorText,
				CurrentDiscrepancyError.UnnecessaryRestrictionsErrorText);
			
			AddError(Common.MetadataObjectByFullName(CurrentDiscrepancyError.FullMetadataObjectName1), ErrorTitle, ErrorText);
			
		ElsIf ValueIsFilled(CurrentDiscrepancyError.MissingConstraintsErrorText) Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В процедуре %1 общего модуля %2:
				           |%3';
							|en = 'In procedure %1 of common module %2:
							|%3';"),
				"OnFillMetadataObjectsAccessRestrictionKinds",
				"AccessManagementOverridable",
				CurrentDiscrepancyError.MissingConstraintsErrorText);
			
			AddError(Common.MetadataObjectByFullName(CurrentDiscrepancyError.FullMetadataObjectName1), ErrorTitle, ErrorText);
			
		ElsIf ValueIsFilled(CurrentDiscrepancyError.UnnecessaryRestrictionsErrorText) Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В процедуре %1 общего модуля %2:
				           |%3';
							|en = 'In procedure %1 of common module %2:
							|%3';"),
				"OnFillMetadataObjectsAccessRestrictionKinds",
				"AccessManagementOverridable",
				CurrentDiscrepancyError.UnnecessaryRestrictionsErrorText);
			
			AddError(Common.MetadataObjectByFullName(CurrentDiscrepancyError.FullMetadataObjectName1), ErrorTitle, ErrorText);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FixRightsRestrictionsTypesDivergenceError(CurrentLineError, ErrorsDiscrepancies, IsMissingConstraints)
	
	OriginalErrorString      = TrimAll(StrReplace(CurrentLineError, "|", ""));
	ArrayConstraintString = StrSplit(OriginalErrorString, ".");
	OriginalErrorString = "	|" + OriginalErrorString;
	
	FullMetadataObjectName1 = ArrayConstraintString.Get(0) + "." + ArrayConstraintString.Get(1);
	ErrorTableRow = ErrorsDiscrepancies.Find(FullMetadataObjectName1, "FullMetadataObjectName1");
	
	If IsMissingConstraints Then
		
		If ErrorTableRow <> Undefined Then
			ErrorTableRow.MissingConstraintsErrorText = ErrorTableRow.MissingConstraintsErrorText
				+ Chars.LF + OriginalErrorString;
		Else
			ErrorTableRow = ErrorsDiscrepancies.Add();
			ErrorTableRow.FullMetadataObjectName1 = FullMetadataObjectName1;
			ErrorTableRow.MissingConstraintsErrorText =
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '- не найдены требуемые виды ограничений прав объектов метаданных:
					           |%1';
								|en = '- the required right restriction kinds of metadata objects are not found:
								|%1';"), OriginalErrorString);
		EndIf;
	Else
		If ErrorTableRow <> Undefined Then
			ErrorTableRow.UnnecessaryRestrictionsErrorText = ErrorTableRow.UnnecessaryRestrictionsErrorText
				+ Chars.LF + OriginalErrorString;
		Else
			ErrorTableRow = ErrorsDiscrepancies.Add();
			ErrorTableRow.FullMetadataObjectName1 = FullMetadataObjectName1;
			ErrorTableRow.UnnecessaryRestrictionsErrorText =
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '- найдены лишние виды ограничений прав объектов метаданных:
					           |%1';
								|en = '- extra right restriction kinds of metadata objects are found:
								|%1';"), OriginalErrorString);
		EndIf;
	EndIf;
	
EndProcedure

// For procedure DefineAccessRestrictionsKinds.
Procedure CheckTableName(Properties)
	
	If Properties.Table <> Properties.SpecifiedTable Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В роли %1 неверно указано имя таблицы в
			           |ограничении полей ""%2"" права ""%3"" таблицы ""%4"":
			           |%5';
						|en = 'Table name in role %1 is specified incorrectly in
						|restriction of %2 fields of the %3 right of the %4 table:
						|%5';"),
			Properties.Role, Properties.Fields, Properties.Right, Properties.Table, Properties.Restriction);
		Role = Metadata.Roles.Find(Properties.Role);
		AddError(Role, NStr("ru = 'Неверное имя таблицы';
									|en = 'Incorrect table name';"), ErrorText);
	EndIf;
	
EndProcedure

// For procedure DefineAccessRestrictionsKinds.
Procedure CheckNameOfRight(Properties)
	
	If ValueIsFilled(Properties.SpecifiedRight)
		And Properties.Right <> Properties.SpecifiedRight Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В роли %1 неверно указано имя права в
			           |ограничении полей ""%2"" права ""%3"" таблицы ""%4"":
			           |%5';
						|en = 'Right name in role %1 is specified incorrectly in
						|restriction of %2 fields of the %3 right of the %4 table:
						|%5';"),
			Properties.Role, Properties.Fields, Properties.Right, Properties.Table, Properties.Restriction);
		Role = Metadata.Roles.Find(Properties.Role);
		AddError(Role, NStr("ru = 'Неверное имя права';
									|en = 'Incorrect right name';"), ErrorText);
	EndIf;
	
EndProcedure

// For procedure DefineAccessRestrictionsKinds.
Procedure AddAccessType(Val Properties, Val AccessRestrictionKinds,
		Val AccessTypesSet, Val FullFieldName1, Val AttachedTables)
	
	AccessKinds = StrSplit(AccessTypesSet, ",", False);
	For Each AccessKind In AccessKinds Do
		
		If AccessKind = "Condition"
		   Or AccessKind = "ReadRight1"
		   Or AccessKind = "ReadRightByID"
		   Or AccessKind = "EditRight" Then
		   Continue;
		EndIf;
			
		Filter = New Structure("Table, Right, AccessKind, ObjectTable");
		
		Filter.Table    = Properties.Table;
		Filter.Right      = Properties.Right;
		Filter.AccessKind = AccessKind;
		
		If AccessKind = "Object" Or AccessKind = "RightsSettings" Then
			
			QueryText =
				"SELECT
				| &FullFieldName1 AS RequiredTypesField
				|FROM
				| #Table AS T
				| ,#AttachedTables
				|WHERE
				|	FALSE";
			
			QueryText = StrReplace(QueryText, "&FullFieldName1", FullFieldName1);
			QueryText = StrReplace(QueryText, ",#AttachedTables", AttachedTables);
			QueryText = StrReplace(QueryText, "#Table", Properties.Table);
			
			Query = New Query(QueryText);
			
			If AccessKind = "RightsSettings" Then
				ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
				AvailableRights = ModuleAccessManagementInternal.RightsForObjectsRightsSettingsAvailable();
				RightsOwners = AvailableRights.ByFullNames;
			EndIf;
			// @skip-check query-in-loop - Obsolete code (the standard RLS variant)
			For Each Type In Query.Execute().Unload().Columns.RequiredTypesField.ValueType.Types() Do
				If Metadata.InformationRegisters["AccessValuesSets"].Dimensions.Object.Type.Types().Find(Type) <> Undefined Then
					TypeMetadata = Metadata.FindByType(Type);
					TypeTable = TypeMetadata.FullName();
					If AccessKind = "RightsSettings" And RightsOwners.Get(TypeTable) = Undefined Then
						Continue;
					EndIf;
					Filter.ObjectTable = TypeTable;
					If AccessRestrictionKinds.FindRows(Filter).Count() = 0 Then
						FillPropertyValues(AccessRestrictionKinds.Add(), Filter);
					EndIf
				EndIf;
			EndDo;
			Continue;
		EndIf;
			
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		If ModuleAccessManagementInternal.AccessKindProperties(AccessKind) = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В роли %1 указано несуществующее имя вида доступа ""%2"" (отсутствует в %7) 
				           |в ограничении полей ""%3"" права ""%4"" таблицы ""%5"":
				           |%6';
							|en = 'Non-existent access kind name ""%2"" is specified in role %1 (it is missing in %7) 
							|in field restriction ""%3"" of right ""%4"" of table ""%5"":
							|%6';"),
				Properties.Role, AccessKind, Properties.Fields, Properties.Right, Properties.Table, Properties.Restriction,
				"AccessManagementOverridable.OnFillAccessKinds");
			Role = Metadata.Roles.Find(Properties.Role);
			AddError(Role, NStr("ru = 'Несуществующий вид доступа';
										|en = 'Non-existent access kind';"), ErrorText);
			Continue;
		EndIf;
		
		Filter.ObjectTable = "";
		If AccessRestrictionKinds.FindRows(Filter).Count() = 0 Then
			FillPropertyValues(AccessRestrictionKinds.Add(), Filter);
		EndIf

	EndDo;
	
EndProcedure

#EndRegion

// For internal use only.
Function AccessRestrictionsFromUploadingConfigurationToFiles()
	
	RightsRestrictions = New ValueTable;
	RightsRestrictions.Columns.Add("Table",     New TypeDescription("String"));
	RightsRestrictions.Columns.Add("Role",        New TypeDescription("String"));
	RightsRestrictions.Columns.Add("Right",       New TypeDescription("String"));
	RightsRestrictions.Columns.Add("Fields",        New TypeDescription("String"));
	RightsRestrictions.Columns.Add("Restriction", New TypeDescription("String"));
	
	For Each Role In Metadata.Roles Do
		AddRoleRightsRestrictions(RightsRestrictions, Role.Name);
	EndDo;
	
	Return RightsRestrictions;
	
EndFunction

// For procedure AccessRestrictionsFromConfigurationExportToFiles.
Procedure AddRoleRightsRestrictions(RightsRestrictions, Role)
	
	Context = New Structure;
	Context.Insert("ObjectsArray",       New Array);
	Context.Insert("MatchingObjects", New Map);
	Context.Insert("TemplatesArray1",       New Array);
	Context.Insert("PatternMatching", New Map);
	
	AddRoleRights(Role, Context);
	
	Rights = New Map;
	Rights.Insert("Read",   "Read");
	Rights.Insert("Insert", "Create");
	Rights.Insert("Update", "Update");
	Rights.Insert("Delete", "Delete");
	
	Objects = Context.MatchingObjects;
	
	For Each ObjectDetails In Objects Do
		If StrOccurrenceCount(ObjectDetails.Key, ".") <> 1 Then
			Continue;
		EndIf;
		MetadataObject = Common.MetadataObjectByFullName(ObjectDetails.Key);
		If MetadataObject = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось найти объект метаданных ""%1"".';
					|en = 'Cannot find the ""%1"" metadata object.';"), ObjectDetails.Key);
			AddError(Undefined, Context.RoleRightsReadingErrorHeader, ErrorText);
		EndIf;
		FullName = MetadataObject.FullName();
		RightsMap = ObjectDetails.Value.RightsMap;
		For Each RightDetails In RightsMap Do
			FieldRestrictions = RightDetails.Value.FieldRestrictions;
			If Not ValueIsFilled(FieldRestrictions) Then
				Continue;
			EndIf;
			Right = Rights[RightDetails.Key];
			For Each RestrictionDetails In FieldRestrictions Do
				If RestrictionDetails.Key = "" And Not ValueIsFilled(RestrictionDetails.Value) Then
					Continue;
				EndIf;
				Fields = ?(RestrictionDetails.Key = "", NStr("ru = '<Прочие поля>';
															|en = '<Other fields>';"), RestrictionDetails.Key);
				NewRow = RightsRestrictions.Add();
				NewRow.Table     = FullName;
				NewRow.Role        = Role;
				NewRow.Right       = Right;
				NewRow.Fields        = Fields;
				NewRow.Restriction = RestrictionDetails.Value;
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

// For procedure AddRoleRightsRestrictions.
Procedure AddRoleRights(Role, Context)
	
	ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'При чтении прав роли %1 произошла ошибка:';
			|en = 'An error occurred when reading the %1 role rights:';"), Role);
	
	Context.Insert("RoleRightsReadingErrorHeader", ErrorTitle);
	RoleFullFileName = RoleCompositionFilePath(Role);
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(RoleFullFileName);
	If Not XMLReader.Read()
		Or Not XMLReader.NodeType = XMLNodeType.StartElement
		Or Not XMLReader.HasName
		Or Not XMLReader.Name = RoleRightProperty()
		Or Not XMLReader.NamespaceURI = "http://v8.1c.ru/8.2/roles"
		Or Not XMLReader.Read()
		Or Not ReadItemAndGoNext(XMLReader, SetRightsForNewObjectsProperty()) <> Undefined
		Or Not ReadItemAndGoNext(XMLReader, SetRightsForDetailsAndTablePartsByDefaultProperty()) <> Undefined
		Or Not ReadItemAndGoNext(XMLReader, IndependentSubordinateObjectsRightsProperty()) <> Undefined
		Or Not XMLReader.HasName Then
		
		Role = Metadata.Roles.Find(Role);
		AddError(Role, ErrorTitle, NStr("ru = 'Некорректный файл прав';
													|en = 'Incorrect rights file';"));
		Return;
	EndIf;
	
	While Not (XMLReader.Name = RoleRightProperty()
		And XMLReader.NodeType = XMLNodeType.EndElement) Do
		
		If XMLReader.Name = RoleObjectProperty() Then
			ReadObject(XMLReader, Context, ErrorTitle);
		ElsIf XMLReader.Name = RoleTemplateProperty() Then
			ReadRestrictionTemplate(XMLReader, Context, ErrorTitle);
		EndIf;
	EndDo;
	
EndProcedure

// For procedure AddRoleRights.
Procedure ReadRestrictionTemplate(XMLReader, Context, ErrorTitle)
	
	XMLReader.Read();
	
	TemplateName = ReadItemAndGoNext(XMLReader, RoleTemplateNameProperty());
	Template = ReadItemAndGoNext(XMLReader, RoleTemplateTextProperty());
	
	TemplateText = Context.PatternMatching.Get(TemplateName);
	If TemplateText = Undefined Then
		Context.TemplatesArray1.Add(TemplateName);
		Context.PatternMatching.Insert(TemplateName, Template);
		
	ElsIf TemplateText <> Template Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Текст шаблона с именем %1, загруженный ранее:
			           |%2
			           |не совпадает с указанным:
			           |%3';
						|en = 'Template text %1 imported earlier:
						|%2
						|does not match the specified one:
						|%3';"), TemplateName, TemplateText, Template);
		AddError(Undefined, Context.RoleRightsReadingErrorHeader, ErrorText);
	EndIf;
	
	XMLReader.Read();
	
EndProcedure

// For procedures AddRoleRights, ReadObject, ReadObjectRight,
// ReadFieldsRestriction, ReadRestrictionTemplate.
//
Function ReadItemAndGoNext(XMLReader, TagName)
	
	If Not XMLReader.NodeType = XMLNodeType.StartElement
	 Or Not XMLReader.HasName
	 Or Not XMLReader.Name = TagName Then
		Return Undefined;
	EndIf;
	
	XMLReader.Read();
	
	If XMLReader.NodeType = XMLNodeType.EndElement
	   And XMLReader.HasName
	   And XMLReader.Name = TagName Then
		
		XMLReader.Read();
		Return "";
	EndIf;
	
	If Not XMLReader.NodeType = XMLNodeType.Text
	 Or Not XMLReader.HasValue Then
		Return Undefined;
	EndIf;
	
	Value = XMLReader.Value;
	
	XMLReader.Skip();
	
	If Not XMLReader.NodeType = XMLNodeType.EndElement
	 Or Not XMLReader.HasName
	 Or Not XMLReader.Name = TagName Then
		Return Undefined;
	EndIf;
	
	XMLReader.Read();
	
	Return Value;
	
EndFunction

// For procedure AddRoleRights.
Procedure ReadObject(XMLReader, Context, ErrorTitle)
	
	XMLReader.Read();
	
	ObjectName = ReadItemAndGoNext(XMLReader, RoleObjectNameProperty());
	
	ObjectProperties = Context.MatchingObjects.Get(ObjectName);
	If ObjectProperties = Undefined Then
		Context.ObjectsArray.Add(ObjectName);
		ObjectProperties = New Structure;
		ObjectProperties.Insert("RightsArray",       New Array);
		ObjectProperties.Insert("RightsMap", New Map);
		Context.MatchingObjects.Insert(ObjectName, ObjectProperties);
	EndIf;
	
	While XMLReader.NodeType = XMLNodeType.StartElement
		And XMLReader.HasName
		And XMLReader.Name = RoleObjectRightProperty() Do
		ReadObjectSRight(XMLReader, Context, ObjectName, ObjectProperties);
	EndDo;
	
	XMLReader.Read();
	
EndProcedure

// For procedure ReadObject.
Procedure ReadObjectSRight(XMLReader, Context, ObjectName, ObjectProperties)
	
	XMLReader.Read();
	
	NameOfRight = ReadItemAndGoNext(XMLReader, RightsNameProperty());
	
	RightsValue = ReadItemAndGoNext(XMLReader, RightValueProperty());
	RightsValue = XMLValue(Type("Boolean"), RightsValue);
	
	RightProperties = ObjectProperties.RightsMap.Get(NameOfRight);
	If RightProperties = Undefined Then
		ObjectProperties.RightsArray.Add(NameOfRight);
		RightProperties = New Structure;
		RightProperties.Insert("Value",         RightsValue);
		RightProperties.Insert("FieldRestrictions", Undefined);
		ObjectProperties.RightsMap.Insert(NameOfRight, RightProperties);
	Else
		If RightsValue = True Then
			RightProperties.Value = True;
		EndIf;
	EndIf;
	
	FieldRestrictions = New Map;
	
	While XMLReader.NodeType = XMLNodeType.StartElement
		And XMLReader.HasName
		And XMLReader.Name = RoleObjectRestrictionProperty() Do
		ReadFieldRestriction(XMLReader, Context, FieldRestrictions, ObjectName, NameOfRight, RightProperties);
	EndDo;
	
	If RightsValue = True Then
		AddFieldRestrictions(Context, FieldRestrictions, ObjectName, NameOfRight, RightProperties);
	EndIf;
	
	XMLReader.Read();
	
EndProcedure

// For procedure ReadObjectRight.
Procedure AddFieldRestrictions(Context, FieldRestrictions, ObjectName, NameOfRight, RightProperties)
	
	If FieldRestrictions.Count() > 0
	   And FieldRestrictions.Get("") = Undefined Then
		
		// The "Other fields" restriction is always present (either empty or filled).
		FieldRestrictions.Insert("", "");
	EndIf;
	
	If RightProperties.FieldRestrictions = Undefined Then
		// Restrictions of the current right fields are processed for the first time.
		RightProperties.FieldRestrictions = FieldRestrictions;
		Return;
		
	ElsIf RightProperties.FieldRestrictions.Count() = 0 Then
		// One of the roles has no right restrictions to any of the fields.
		Return;
	EndIf;
	
	If FieldRestrictions.Count() = 0 Then
		// The current role has no right restrictions to any of the fields.
		RightProperties.FieldRestrictions = New Map;
		Return;
	EndIf;
	
	NewOtherFieldsRestriction = FieldRestrictions.Get("");
	
	// Check or update the current restrictions of some fields with a new restriction for other fields.
	For Each KeyAndValue In RightProperties.FieldRestrictions Do
		FieldName         = KeyAndValue.Key;
		FieldRestriction = KeyAndValue.Value;
		If FieldRestrictions.Get(FieldName) <> Undefined Then
			// This field has a new individual restriction setting.
			Continue;
		EndIf;
		If FieldRestriction = "" Then
			// This field has no restriction, therefore it must not match the new common restriction.
			Continue;
		EndIf;
		If NewOtherFieldsRestriction = "" Then
			RightProperties.FieldRestrictions[FieldName] = "";
		ElsIf FieldRestriction <> NewOtherFieldsRestriction Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В объекте
				           |%1
				           |для права %2 ограничение поля с именем %3, загруженное ранее:
				           |%4
				           |не совпадает с указанным:
				           |%5';
							|en = 'In object
							|%1,
							|for the %2 right, restriction of the %3 field imported earlier
							|%4
							|does not match the specified one:
							|%5.';"), ObjectName, NameOfRight, FieldName, FieldRestriction, NewOtherFieldsRestriction);
			AddError(Undefined, Context.RoleRightsReadingErrorHeader, ErrorText);
		EndIf;
	EndDo;
	
	// Check the current field restrictions using the new restrictions.
	// Apply restrictions to new individual fields.
	OldOtherFieldsRestriction = RightProperties.FieldRestrictions.Get("");
	For Each KeyAndValue In FieldRestrictions Do
		Field        = KeyAndValue.Key;
		Restriction = KeyAndValue.Value;
		
		FieldRestriction = RightProperties.FieldRestrictions.Get(Field);
		If FieldRestriction = Undefined Then
			FieldRestriction = OldOtherFieldsRestriction;
			RightProperties.FieldRestrictions.Insert(Field, FieldRestriction);
		EndIf;
		
		If FieldRestriction = "" Then
			// A field without a restriction cannot become a field with a restriction.
		ElsIf Restriction = "" Then
			RightProperties.FieldRestrictions[Field] = "";
		ElsIf FieldRestriction <> Restriction Then
			FieldName = ?(ValueIsFilled(Field), Field, NStr("ru = '<Прочие поля>';
															|en = '<Other fields>';"));
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В объекте
				           |%1
				           |для права %2 ограничение поля с именем %3, загруженное ранее:
				           |%4
				           |не совпадает с указанным:
				           |%5';
							|en = 'In object
							|%1,
							|for the %2 right, restriction of the %3 field imported earlier
							|%4
							|does not match the specified one:
							|%5.';"), ObjectName, NameOfRight, FieldName, FieldRestriction, Restriction);
			AddError(Undefined, Context.RoleRightsReadingErrorHeader, ErrorText);
		EndIf;
	EndDo;
	
EndProcedure

// For procedure ReadObjectRight.
Procedure ReadFieldRestriction(XMLReader, Context, FieldRestrictions, ObjectName, NameOfRight, RightProperties)
	
	XMLReader.Read();
	
	Fields = New Array;
	
	While XMLReader.NodeType = XMLNodeType.StartElement
	   And XMLReader.HasName
	   And XMLReader.Name = ObjectRestrictionFieldProperty() Do
		
		FieldName = ReadItemAndGoNext(XMLReader, ObjectRestrictionFieldProperty());
		Fields.Add(FieldName);
	EndDo;
	
	If Fields.Count() = 0 Then
		Fields.Add(""); // Other fields.
	EndIf;
	
	Restriction = ReadItemAndGoNext(XMLReader, ObjectRestrictionConditionProperty());
	For Each Field In Fields Do
		FieldRestrictions.Insert(Field, Restriction);
	EndDo;
	
	XMLReader.Read();
	
EndProcedure

Procedure AccessControl_AtReadingBasicSettings(Parameters)
	
	If Parameters.UpdateOnlyConstraintTemplates Then
		Return;
	EndIf;
	
	RestrictedAccessLists = New Map;
	SSLSubsystemsIntegration.OnFillListsWithAccessRestriction(RestrictedAccessLists);
	ModuleAccessManagementOverridable = Common.CommonModule("AccessManagementOverridable");
	ModuleAccessManagementOverridable.OnFillListsWithAccessRestriction(RestrictedAccessLists);
	
	Parameters.AccessManagement.RolesAssignment = Users.RolesAssignment();
	Parameters.AccessManagement.RestrictedAccessLists = RestrictedAccessLists;
	ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
	Parameters.AccessManagement.ImplementationSettings = ModuleAccessManagementInternal.ImplementationSettings();
	
	IdentifiersByTypeDescriptions = New Map;
	PredefinedIDs = Parameters.AccessManagement.ImplementationSettings.PredefinedIDs;
	For Each IDDetails In PredefinedIDs Do
		NameParts = StrSplit(IDDetails.Key, ".", True);
		If IdentifiersByTypeDescriptions[NameParts[0]] = Undefined Then
			IdentifiersByTypeDescriptions.Insert(NameParts[0], New Structure(NameParts[1], IDDetails.Value));
		Else
			IdentifiersByTypeDescriptions[NameParts[0]].Insert(NameParts[1], IDDetails.Value);
		EndIf;
	EndDo;
	Parameters.AccessManagement.PredefinedIDs = IdentifiersByTypeDescriptions;
	
EndProcedure

Procedure AccessControl_CheckTextInsertionInFormModule(Parameters, MetadataObjectForm)
	
	MainFormPropertyType = MainFormPropertyType(MetadataObjectForm);
	If MainFormPropertyType = Undefined Then
		Return;
	EndIf;
	
	MetadataObject = Metadata.FindByType(MainFormPropertyType);
	If MetadataObject = Undefined Or Parameters.AccessManagement.RestrictedAccessLists[MetadataObject] = Undefined Then
		Return;
	EndIf;
	
	Module = FormModule(MetadataObjectForm);
	ErrorTitle = NStr("ru = 'Отсутствует обязательная вставка кода';
							|en = 'The required code insert is missing';");
	
	CallFound = False;
	ModuleProcedure = FindModuleProcedure(Module, "OnReadAtServer");
	If ModuleProcedure <> Undefined Then
		ProcedureByString = BlockToString(ModuleProcedure);
		If StrFind(ProcedureByString, "AccessManagement.OnReadAtServer(") > 0 Then
			CallFound = True;
		EndIf;
	EndIf;
	
	If Not CallFound Then
		AddError(MetadataObjectForm, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В форме ""%1"" отсутствует обязательный вызов ""%2"" в процедуре %3.';
				|en = 'Form ""%1"" does not contain required call ""%2"" in procedure %3.';"),
			MetadataObjectForm.Name, "AccessManagement.OnReadAtServer()", "OnReadAtServer"));
	EndIf;
	
	CallFound = False;
	ModuleProcedure = FindModuleProcedure(Module, "AfterWriteAtServer");
	If ModuleProcedure <> Undefined Then
		ProcedureByString = BlockToString(ModuleProcedure);
		If StrFind(ProcedureByString, "AccessManagement.AfterWriteAtServer(") > 0 Then
			CallFound = True;
		EndIf;
	EndIf;
	
	If Not CallFound Then
		AddError(MetadataObjectForm, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В форме ""%1"" отсутствует обязательный вызов ""%2"" в процедуре %3.';
				|en = 'Form ""%1"" does not contain required call ""%2"" in procedure %3.';"),
			MetadataObjectForm.Name, "AccessManagement.AfterWriteAtServer()", "AfterWriteAtServer"));
	EndIf;
	
	If ValueIsFilled(Module.Structure) Then
		ClearVariableFormModule(Module.Structure.Content);
		Module = Undefined;
	EndIf;
	
EndProcedure

// Parameters:
//  MetadataObjectForm - MetadataObjectForm
//
Procedure AccessControl_CheckUseOfPredefinedInFormModule(MetadataObjectForm)
	
	Module = FormModule(MetadataObjectForm);
	AccessManagement_CheckPredefinedModulesUsage(MetadataObjectForm,
		Module,
		NStr("ru = 'В модуле формы ""%1"" используется обращение к предопределенному элементу ""%2"" вместо использования функции ""%3"", в следующих строках:
		|%4';
		|en = 'The ""%1"" form module uses the ""%2"" predefined item instead of the ""%3"" function in the following lines:
		|%4';"),
		MetadataObjectForm.Name);
	
	If ValueIsFilled(Module.Structure) Then
		ClearVariableFormModule(Module.Structure.Content);
		Module = Undefined;
	EndIf;
	
EndProcedure

// Parameters:
//  MetadataObjectCommand - MetadataObjectCommand
//
Procedure AccessControl_CheckUseOfPredefinedInModuleCommands(MetadataObjectCommand)
	
	Module = CommandModule(MetadataObjectCommand);
	AccessManagement_CheckPredefinedModulesUsage(MetadataObjectCommand,
		Module,
		NStr("ru = 'В модуле команды ""%1"" используется обращение к предопределенному элементу ""%2"" вместо использования функции ""%3"", в следующих строках:
		|%4';
		|en = 'The ""%1"" command module uses the ""%2"" predefined item instead of the ""%3"" function in the following lines:
		|%4';"),
		MetadataObjectCommand.Name);
	
EndProcedure

// Parameters:
//  MetadataObject - MetadataObject
//
Procedure AccessControl_CheckUseOfPredefinedInSharedModule(MetadataObject)
	
	Module = CommonModule(MetadataObject);
	AccessManagement_CheckPredefinedModulesUsage(MetadataObject,
		Module,
		NStr("ru = 'В общем модуле ""%1"" используется обращение к предопределенному элементу ""%2"" вместо использования функции ""%3"", в следующих строках:
		|%4';
		|en = 'The ""%1"" common module uses the ""%2"" predefined item instead of the ""%3"" function in the following lines:
		|%4';"),
		MetadataObject.Name);
	
EndProcedure

// Parameters:
//  MetadataObject - MetadataObject
//
Procedure AccessControl_CheckUsageOfPredefinedInObjectModules(MetadataObject)
	
	FullName = MetadataObject.FullName();
	
	If FullName <> "Catalog.AccessGroupProfiles"
	   And FullName <> "Catalog.AccessGroups" Then
		
		Module = ManagerModule(MetadataObject);
		AccessManagement_CheckPredefinedModulesUsage(MetadataObject,
			Module,
			NStr("ru = 'В модуле менеджера ""%1"" используется обращение к предопределенному элементу ""%2"" вместо использования функции ""%3"", в следующих строках:
			|%4';
			|en = 'The ""%1"" manager module uses the ""%2"" predefined item instead of the ""%3"" function in the following lines:
			|%4';"),
			FullName);
	EndIf;
	
	If FullName <> "Report.SSLImplementationCheck" Then
		Module = ObjectModule(MetadataObject);
		AccessManagement_CheckPredefinedModulesUsage(MetadataObject,
			Module,
			NStr("ru = 'В модуле объекта ""%1"" используется обращение к предопределенному элементу ""%2"" вместо использования функции ""%3"", в следующих строках:
			|%4';
			|en = 'The ""%1"" object module uses the ""%2"" predefined item instead of the ""%3"" function in the following lines:
			|%4';"),
			FullName);
	EndIf;
	
EndProcedure

Function OccurrencesOfString(ModuleText, SearchString, CheckWhatNextCharacterVariableName = False)
	
	Occurrences = New Array;
	If IsBlankString(ModuleText) Then
		Return Occurrences;
	EndIf;
	
	If CanUseRegEx() Then
		
		SearchExpression = SearchString;
		SearchExpression = StrReplace(SearchExpression, "(", "\(");
		SearchExpression = StrReplace(SearchExpression, ")", "\)");
		
		Position = 0;
		
		While True Do
			SearchResult = EvalStrFindByRegularExpression(ModuleText, SearchExpression, Position + 1);
			If SearchResult = Undefined Then
				Break;
			EndIf;
			
			Position = SearchResult.StartIndex;
			If Position = 0 Then
				Break;
			EndIf;
			
			LineNumber = GetModuleLineNum(ModuleText, Position);
			String = StrGetLine(ModuleText, LineNumber);
			
			If CheckWhatNextCharacterVariableName Then
				EndingPosition = StrFind(String, SearchString) + SearchResult.Length;
				If StrLen(String) > EndingPosition And Not ItSymbolNameVariable(Mid(String, EndingPosition, 1)) Then
					Occurrences.Add(Format(LineNumber, "NG=") + " " + String);
				EndIf;
			Else
				Occurrences.Add(Format(LineNumber, "NG=") + " " + String);
			EndIf;
		EndDo;
		
	Else
		
		Rows = StrSplit(ModuleText, Chars.LF + Chars.CR, False);
		LineNumber = 1;
		For Each String In Rows Do
			
			Position = StrFind(String, SearchString);
			
			If Position > 0 Then
				
				If CheckWhatNextCharacterVariableName Then
					EndingPosition = Position + StrLen(SearchString);
					If StrLen(String) > EndingPosition 
						And Not ItSymbolNameVariable(Mid(String, EndingPosition, 1)) Then
						Occurrences.Add(Format(LineNumber, "NG=") + " " + String);
					EndIf;
				Else
					Occurrences.Add(Format(LineNumber, "NG=") + " " + String);
				EndIf;
				
			EndIf;
			LineNumber = LineNumber + 1;
		EndDo;
		
	EndIf;
	
	Return Occurrences;
	
EndFunction

Function ItSymbolNameVariable(Char)
	// ACC:1036-off Orthography check is not required.
	VariableNameCharacters = "АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЫЪЬЭЮЯABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789"; // @Non-NLS
	// 
	Return StrFind(VariableNameCharacters ,Upper(Char)) > 0;
EndFunction

Procedure UpdateAccessKeyValuesOwnersList(Parameters)
	
	ImplementationSettings = Parameters.AccessManagement.ImplementationSettings; // See AccessManagementInternal.ImplementationSettings
	
	ValuesOwners           = ImplementationSettings.AccessKeysValuesOwners;
	CommonRegisterMeasurementsTypes = ImplementationSettings.KeysRegistersDimensionsTypes["AccessKeysForRegisters"];

	DefinedTypesComposition = New Structure;
	DefinedTypesComposition.Insert("AccessKeysValuesOwner",             ValuesOwners.References);
	DefinedTypesComposition.Insert("AccessKeysValuesOwnerObject",       ValuesOwners.Objects);
	DefinedTypesComposition.Insert("AccessKeysValuesOwnerDocument",     ValuesOwners.Documents);
	DefinedTypesComposition.Insert("AccessKeysValuesOwnerRecordSet", ValuesOwners.RecordSets);
	DefinedTypesComposition.Insert("AccessKeysValuesOwnerCalculationRegisterRecordSet", ValuesOwners.CalculationRegisterRecordSets);
	DefinedTypesComposition.Insert("RegisterAccessKeysRegisterField", CommonRegisterMeasurementsTypes.TypesNames);
	DefinedTypesComposition.Insert("AccessValue",                     ImplementationSettings.AccessValues);
	
	ErrorHeaderTemplate      = NStr("ru = 'В определяемом типе %1 указаны не все требуемые типы';
										|en = 'Some of the required types are missing from the %1 type collection';");
	ExplanationCorrectionTemplate = NStr("ru = 'Исправлено. Тип %1 добавлен в состав определяемого типа.';
										|en = 'Fixed. The %1 type is added to the type collection.';");
	
	For Each DefinedType In DefinedTypesComposition Do
		TypeToDefineName = DefinedType.Key;
		TypesComposition = DefinedType.Value;
		TypeMetadata = Metadata.DefinedTypes[DefinedType.Key];
		ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(ErrorHeaderTemplate, TypeToDefineName);
		
		If StrStartsWith(TypeToDefineName, "AccessKeysValuesOwner") Then
			ErrorExplanationTemplate =
				NStr("ru = 'Таблица %1 ограничивается на уровне записей, либо участвует в логике ограничения доступа других таблиц.
				           |Включите ее тип в состав определяемого типа.';
							|en = 'The %1 table is either restricted on the record level or takes part in access restriction logic of other tables.
							|Include its type in the type collection.';");
			
		ElsIf TypeToDefineName = "AccessValue" Then
			ErrorExplanationTemplate =
				NStr("ru = 'Тип %1 сохраняется в ключе доступа.
				           |Включите его в состав определяемого типа.';
							|en = 'The %1 type is saved to the access key.
							|Include it in the type collection.';");
		Else // RegisterAccessKeysRegisterField.
			ErrorExplanationTemplate =
				NStr("ru = 'Тип %1 используется в ограничении доступа к таблицам в составе типов полей:
				           |- %2
				           |Включите его в состав определяемого типа.';
							|en = 'The %1 type is used in table access restriction in field types:
							|- %2.
							|Include it in the type collection.';");
		EndIf;
		
		FileName = MetadataObjectDescriptionFilePath(TypeMetadata);
		
		DOMDocument = DOMDocument(FileName);
		Dereferencer = New DOMNamespaceResolver(DOMDocument);
		
		HasChanges = False;
		For Each TypeName In TypesComposition Do
			ReferenceTypeName = TypeNameWithStringPrefix(TypeName, "cfg");
			TypeInComposition = DOMDocument.EvaluateXPathExpression(XPathExpressionIsDefinedTypeComposition(ReferenceTypeName),
				DOMDocument, Dereferencer).IterateNext() <> Undefined;
				
			If Not TypeInComposition Then
				MetadataObject = Metadata.FindByType(Type(TypeName));
				If StrStartsWith(TypeToDefineName, "AccessKeysValuesOwner") Then
					TableNameOrTypeName = MetadataObject.FullName();
				Else
					TableNameOrTypeName = TypeName;
				EndIf;
				If FixError("TypeNotIncludedInDefinedType") Then
					Types = DOMDocument.EvaluateXPathExpression(XPathExpressionDefinedType(), DOMDocument, Dereferencer).IterateNext();
					NodeType = Types.AppendChild(DOMDocument.CreateElement(PropertyType()));
					NodeType.TextContent = ReferenceTypeName;
					HasChanges = True;
					
					AddError(MetadataObject, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
						ExplanationCorrectionTemplate, TableNameOrTypeName));
				Else
					If TypeToDefineName = "RegisterAccessKeysRegisterField" Then
						Fields = StrConcat(CommonRegisterMeasurementsTypes.RegistersFieldsByTypes[TypeName], Chars.LF + "- ");
					Else
						Fields = "";
					EndIf;
					AddError(MetadataObject, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
						ErrorExplanationTemplate, TableNameOrTypeName, Fields));
				EndIf;
			EndIf;
		EndDo;
		
		If FixError("TypeNotIncludedInDefinedType") And TypesComposition.Count() > 0 Then
			Types = DOMDocument.EvaluateXPathExpression(XPathExpressionDefinedType(), DOMDocument, Dereferencer).IterateNext();
			ReferenceTypeName = TypeNameWithStringPrefix("CatalogObject.MetadataObjectIDs", "cfg");
			MOIDType = DOMDocument.EvaluateXPathExpression(XPathExpressionIsDefinedTypeComposition(ReferenceTypeName),
				DOMDocument, Dereferencer).IterateNext();
			If MOIDType <> Undefined Then
				Types.RemoveChild(MOIDType);
				HasChanges = True;
				ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Тип %1 присутствует в определяемом типе.';
						|en = 'The %1 type is present in the type collection.';"), "CatalogObject.MetadataObjectIDs");
				AddError(MetadataObject, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Исправлено. Тип %1 исключен из состава определяемого типа.';
						|en = 'Fixed. The %1 type is excluded from the type collection.';"), "CatalogObject.MetadataObjectIDs"));
			EndIf;
		EndIf;
		
		If HasChanges Then
			WriteDOMDocument(DOMDocument, FileName);
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckRegistersKeysMeasurementsTypes(Parameters)
	
	KeysRegistersDimensionsTypes = Parameters.AccessManagement.ImplementationSettings.KeysRegistersDimensionsTypes;
	
	For Each RegisterDescription In KeysRegistersDimensionsTypes Do
		RegisterName = "InformationRegister." + RegisterDescription.Key;
		If RegisterName = "InformationRegister.AccessKeysForRegisters" Then
			Continue;
		EndIf;
		FieldsDetails = RegisterDescription.Value;
		
		MetadataObject = Common.MetadataObjectByFullName(RegisterName);
		If MetadataObject = Undefined Then
			Continue;
		EndIf;
		
		FileName = MetadataObjectDescriptionFilePath(MetadataObject);
		DOMDocument = DOMDocument(FileName);
		
		HasChanges = CheckRegisterMeasurementsTypes(DOMDocument, MetadataObject, FieldsDetails);
		If HasChanges Then
			WriteDOMDocument(DOMDocument, FileName);
		EndIf;
	EndDo;
	
EndProcedure

Function CheckRegisterMeasurementsTypes(DOMDocument, Val MetadataObject, Val FieldsDetails)
	
	Dereferencer = New DOMNamespaceResolver(DOMDocument);
	HasChanges = False;
	
	RegisterPresentation = MetadataObject.FullName();
	For Each KeyAndValue In FieldsDetails.RegistersFields Do
		SourceRegisterName = KeyAndValue.Key;
		FieldList = KeyAndValue.Value;
		Break;
	EndDo;
	
	For IndexOf = 1 To FieldList.Count() Do
		FieldName = "Field" + Format(IndexOf, "NG=0");
		FieldDetails = FieldList[IndexOf-1];
		
		SourceFieldName = FieldDetails.Field;
		TypeDescription = FieldDetails.Type;
		
		TypesComposition = DOMDocument.EvaluateXPathExpression(XPathExpressionRegisterDimensionTypes(FieldName), DOMDocument, Dereferencer).IterateNext();
		If TypesComposition = Undefined Then
			ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Отсутствует поле ""%1"" в регистре ""%2""';
				|en = 'The %1 field in the %2 register is missing';"), FieldName, RegisterPresentation);
			Continue;
		EndIf;
		
		For Each Type In TypeDescription.Types() Do
			
			XMLTypeName = TypeNameString(Type, DOMDocument);
			
			TypePresentation = TypePresentation(Type, TypeDescription);
			TypeDetected = MetadataObject.Dimensions[FieldName].Type.ContainsType(Type);
			
			If Not TypeDetected Then
				ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Отсутствует тип ""%1"" в составе типов поля ""%2"" регистра ""%3""';
						|en = 'The %1 type is missing in the %2 field types of the %3 register';"),
					TypePresentation, FieldName, RegisterPresentation);
				If FixError("InvalidRegisterFieldTypesComposition") Then
					NodeType = TypesComposition.AppendChild(DOMDocument.CreateElement(PropertyType()));
					NodeType.TextContent = XMLTypeName;
					If Type = Type("String") Then
						
						StringLengthProperty           = StringLengthString(TypeDescription.StringQualifiers.Length);
						AllowedStringLengthProperty = AllowedStringLengthString(TypeDescription.StringQualifiers.AllowedLength);
						
						QualifierNode = TypesComposition.AppendChild(DOMDocument.CreateElement(StringQualifierProperty()));
						If Not IsBlankString(StringLengthProperty) Then
							AddDOMNodeProperty(DOMDocument, QualifierNode, StringLengthProperty(), StringLengthProperty);
						EndIf;
						If Not IsBlankString(AllowedStringLengthProperty) Then
							AddDOMNodeProperty(DOMDocument, QualifierNode, AllowedStringLengthProperty(), AllowedStringLengthProperty);
						EndIf;
						
					ElsIf Type = Type("Date") Then
						
						DateStringParts = DateStringParts(TypeDescription.DateQualifiers.DateFractions);
						
						QualifierNode = TypesComposition.AppendChild(DOMDocument.CreateElement(DateQualifierProperty()));
						If Not IsBlankString(DateStringParts) Then
							AddDOMNodeProperty(DOMDocument, QualifierNode, DateCompositionProperty(), DateStringParts);
						EndIf;
						
					ElsIf Type = Type("Number") Then
						
						BitnessProperty             = DigitNumberString(TypeDescription.NumberQualifiers.Digits);
						ValidSignProperty          = ValidNumberSignString(TypeDescription.NumberQualifiers.AllowedSign);
						FractionalPartBitnessProperty = FractionalPartBitDepthString(TypeDescription.NumberQualifiers.FractionDigits);
						
						QualifierNode = TypesComposition.AppendChild(DOMDocument.CreateElement(NumberQualifierProperty()));
						AddDOMNodeProperty(DOMDocument, QualifierNode, NumberBitnessProperty(), BitnessProperty);
						If Not IsBlankString(FractionalPartBitnessProperty) Then
							AddDOMNodeProperty(DOMDocument, QualifierNode, NumberFractionalPartBitnessProperty(), FractionalPartBitnessProperty);
						EndIf;
						If Not IsBlankString(ValidSignProperty) Then
							AddDOMNodeProperty(DOMDocument, QualifierNode, ValidNumberSignProperty(), ValidSignProperty);
						EndIf;
						
					EndIf;
					ErrorNote = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Исправлено. В состав типов поля ""%1"" регистра ""%2"" добавлен тип ""%3"".';
							|en = 'Fixed. The %3 type is added to the %1 field types of the %2 register.';"),
						FieldName, RegisterPresentation, TypePresentation);
					HasChanges = True;
				Else
					If Type = Type("EnumRef.AdditionalAccessValues") Then
						ErrorNote = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'В состав типов поля ""%1"" регистра ""%2"" добавьте тип ""%3"".';
								|en = 'Add the %3 type to the %1 field types of the %2 register.';"),
							FieldName, RegisterPresentation, TypePresentation);
					Else
						ErrorNote = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'В состав типов поля ""%1"" регистра ""%2"" добавьте тип ""%3"", соответствующий типу, указанному в поле ""%4"" регистра ""%5"".';
								|en = 'Add the %3 type to the %1 field types of the %2 register. This type must correspond to the type specified in the %4 field of the %5 register.';"),
							FieldName, RegisterPresentation, TypePresentation, SourceFieldName, SourceRegisterName);
					EndIf;
				EndIf;
				AddError(MetadataObject, ErrorTitle, ErrorNote);
				Continue;
			EndIf;
			
			If Type = Type("String") Then
				StringQualifiers = DOMDocument.EvaluateXPathExpression(StringQualifierProperty(), TypesComposition, Dereferencer).IterateNext();
				If StringQualifiers = Undefined Then
					Continue;
				EndIf;
				
				StringLengthElement = DOMDocument.EvaluateXPathExpression(StringLengthProperty(), StringQualifiers, Dereferencer).IterateNext();
				If StringLengthElement = Undefined Then
					StringLength = 0;
				Else
					StringLength = StringLengthValue(StringLengthElement.TextContent);
				EndIf;
				
				AllowedStringLengthElement = DOMDocument.EvaluateXPathExpression(AllowedStringLengthProperty(), StringQualifiers, Dereferencer).IterateNext();
				If AllowedStringLengthElement = Undefined Then
					AllowedStringLength = AllowedLength.Variable;
				Else
					AllowedStringLength = AllowedStringLengthValue(AllowedStringLengthElement.TextContent);
				EndIf;
				
				If TypeDescription.StringQualifiers.Length <> StringLength 
					Or TypeDescription.StringQualifiers.AllowedLength <> AllowedStringLength Then
					FoundTypeRepresentation = StringTypeRepresentation(StringLength, AllowedStringLength);
					ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Неверный тип ""%1"" в составе типов поля ""%2"" регистра ""%3""';
							|en = 'Incorrect type %1 in the composition of the %2 field types of the %3 register';"),
						FoundTypeRepresentation, FieldName, RegisterPresentation);
					If FixError("InvalidRegisterFieldTypesComposition") Then
						
						If Not StringLengthElement = Undefined Then
							StringQualifiers.RemoveChild(StringLengthElement);
						EndIf;
						If Not AllowedStringLengthElement = Undefined Then
							StringQualifiers.RemoveChild(AllowedStringLengthElement);
						EndIf;
						
						StringLengthProperty           = StringLengthString(TypeDescription.StringQualifiers.Length);
						AllowedStringLengthProperty = AllowedStringLengthString(TypeDescription.StringQualifiers.AllowedLength);
						
						If Not IsBlankString(StringLengthProperty) Then
							AddDOMNodeProperty(DOMDocument, StringQualifiers, StringLengthProperty(), StringLengthProperty);
						EndIf;
						If Not IsBlankString(AllowedStringLengthProperty) Then
							AddDOMNodeProperty(DOMDocument, StringQualifiers, AllowedStringLengthProperty(), AllowedStringLengthProperty);
						EndIf;
						
						ErrorNote = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Исправлено. Тип значения ""%1"" в составе типа поля ""%2"" регистра ""%3"" приведен в соответствие с типом, указанным в поле ""%4"" регистра ""%5"": ""%6""';
								|en = 'Fixed. The %1 value type in the %2 field type of the %3 register is brought into accordance with the type specified in the %4 field of the %5 register: %6';"),
							FoundTypeRepresentation, FieldName, RegisterPresentation, SourceFieldName, SourceRegisterName, TypePresentation);
						HasChanges = True;
					Else
						ErrorNote = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Тип ""%1"" в составе типа поля ""%2"" регистра ""%3"" приведите в соответствие с типом, указанным в поле ""%4"" регистра ""%5"": ""%6""';
								|en = 'Match the %1 type included in the %2 field type of the %3 register to the type specified in the %4 field of the %5 register: %6';"),
							FoundTypeRepresentation, FieldName, RegisterPresentation, SourceFieldName, SourceRegisterName, TypePresentation);
					EndIf;
					AddError(MetadataObject, ErrorTitle, ErrorNote);
				EndIf;
			EndIf;
			
			If Type = Type("Date") Then
				
				DateQualifiers = DOMDocument.EvaluateXPathExpression(DateQualifierProperty(), TypesComposition, Dereferencer).IterateNext();
				If DateQualifiers = Undefined Then
					Continue;
				EndIf;
				
				DatePartElement = DOMDocument.EvaluateXPathExpression(DateCompositionProperty(), DateQualifiers, Dereferencer).IterateNext();
				If DatePartElement = Undefined Then
					DatePartsValue = DateFractions.DateTime;
				Else
					DatePartsValue = DatePartsValue(DatePartElement.TextContent);
				EndIf;
				
				If TypeDescription.DateQualifiers.DateFractions <> DatePartsValue Then
					FoundTypeRepresentation = DateTypeRepresentation(DatePartsValue);
					ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Неверный тип ""%1"" в составе типов поля ""%2"" регистра ""%3""';
							|en = 'Incorrect type %1 in the composition of the %2 field types of the %3 register';"),
						FoundTypeRepresentation, FieldName, RegisterPresentation);
					If FixError("InvalidRegisterFieldTypesComposition") Then
						
						If Not DatePartElement = Undefined Then
							DateQualifiers.RemoveChild(DatePartElement);
						EndIf;
						
						DateStringParts = DateStringParts(TypeDescription.DateQualifiers.DateFractions);
						If Not IsBlankString(DateStringParts) Then
							AddDOMNodeProperty(DOMDocument, DateQualifiers, DateCompositionProperty(), DateStringParts);
						EndIf;
						
						ErrorNote = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Исправлено. Тип значения ""%1"" в составе типа поля ""%2"" регистра ""%3"" приведен в соответствие с типом, указанным в поле ""%4"" регистра ""%5"": ""%6""';
								|en = 'Fixed. The %1 value type in the %2 field type of the %3 register is brought into accordance with the type specified in the %4 field of the %5 register: %6';"),
							FoundTypeRepresentation, FieldName, RegisterPresentation, SourceFieldName, SourceRegisterName, TypePresentation);
						HasChanges = True;
					Else
						ErrorNote = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Тип ""%1"" в составе типа поля ""%2"" регистра ""%3"" приведите в соответствие с типом, указанным в поле ""%4"" регистра ""%5"": ""%6""';
								|en = 'Match the %1 type included in the %2 field type of the %3 register to the type specified in the %4 field of the %5 register: %6';"),
							FoundTypeRepresentation, FieldName, RegisterPresentation, SourceFieldName, SourceRegisterName, TypePresentation);
					EndIf;
					AddError(MetadataObject, ErrorTitle, ErrorNote);
				EndIf;
			EndIf;
			
			If Type = Type("Number") Then
				NumberQualifiers = DOMDocument.EvaluateXPathExpression(NumberQualifierProperty(), TypesComposition, Dereferencer).IterateNext();
				If NumberQualifiers = Undefined Then
					Continue;
				EndIf;
				
				BitDepthElement = DOMDocument.EvaluateXPathExpression(NumberBitnessProperty(), NumberQualifiers, Dereferencer).IterateNext();
				Digits = DigitNumberValue(BitDepthElement.TextContent);
				
				FractionalPartBitDepthElement = DOMDocument.EvaluateXPathExpression(NumberFractionalPartBitnessProperty(), NumberQualifiers, Dereferencer).IterateNext();
				If FractionalPartBitDepthElement = Undefined Then
					FractionDigits = 0;
				Else
					FractionDigits = BitDepthOfFractionalPartValue(FractionalPartBitDepthElement.TextContent);
				EndIf;
				
				ValidSignElement = DOMDocument.EvaluateXPathExpression(ValidNumberSignProperty(), NumberQualifiers, Dereferencer).IterateNext();
				If ValidSignElement = Undefined Then
					ValidSignValue = AllowedSign.Any;
				Else
					ValidSignValue = ValidNumberSignValue(ValidSignElement.TextContent);
				EndIf;
				
				If TypeDescription.NumberQualifiers.Digits <> Digits
					Or TypeDescription.NumberQualifiers.FractionDigits <> FractionDigits 
					Or TypeDescription.NumberQualifiers.AllowedSign <> ValidSignValue Then
					
					FoundTypeRepresentation = NumberTypeRepresentation(Digits, FractionDigits, ValidSignValue);
					ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Неверный тип ""%1"" в составе типов поля ""%2"" регистра ""%3""';
							|en = 'Incorrect type %1 in the composition of the %2 field types of the %3 register';"),
						FoundTypeRepresentation, FieldName, RegisterPresentation);
					If FixError("InvalidRegisterFieldTypesComposition") Then
						
						BitDepthElement.TextContent = DigitNumberString(TypeDescription.NumberQualifiers.Digits);
						
						If Not FractionalPartBitDepthElement = Undefined Then
							NumberQualifiers.RemoveChild(FractionalPartBitDepthElement);
						EndIf;
						If Not ValidSignElement = Undefined Then
							NumberQualifiers.RemoveChild(ValidSignElement);
						EndIf;
						
						ValidSignProperty          = ValidNumberSignString(TypeDescription.NumberQualifiers.AllowedSign);
						FractionalPartBitnessProperty = FractionalPartBitDepthString(TypeDescription.NumberQualifiers.FractionDigits);
						
						If Not IsBlankString(FractionalPartBitnessProperty) Then
							AddDOMNodeProperty(DOMDocument, NumberQualifiers, NumberFractionalPartBitnessProperty(), FractionalPartBitnessProperty);
						EndIf;
						If Not IsBlankString(ValidSignProperty) Then
							AddDOMNodeProperty(DOMDocument, NumberQualifiers, ValidNumberSignProperty(), ValidSignProperty);
						EndIf;
						
						ErrorNote = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Исправлено. Тип значения ""%1"" в составе типа поля ""%2"" регистра ""%3"" приведен в соответствие с типом, указанным в поле ""%4"" регистра ""%5"": ""%6""';
								|en = 'Fixed. The %1 value type in the %2 field type of the %3 register is brought into accordance with the type specified in the %4 field of the %5 register: %6';"),
							FoundTypeRepresentation, FieldName, RegisterPresentation, SourceFieldName, SourceRegisterName, TypePresentation);
						HasChanges = True;
					Else
						ErrorNote = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Тип ""%1"" в составе типа поля ""%2"" регистра ""%3"" приведите в соответствие с типом, указанным в поле ""%4"" регистра ""%5"": ""%6""';
								|en = 'Match the %1 type included in the %2 field type of the %3 register to the type specified in the %4 field of the %5 register: %6';"),
							FoundTypeRepresentation, FieldName, RegisterPresentation, SourceFieldName, SourceRegisterName, TypePresentation);
					EndIf;
					AddError(MetadataObject, ErrorTitle, ErrorNote);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	Return HasChanges;
	
EndFunction

Function TypePresentation(Type, TypeDescription)
	XMLType = XMLType(Type);
	Result = XMLType.TypeName;
	
	If Type = Type("String") Then
		Qualifiers = TypeDescription.StringQualifiers;
		Result = StringTypeRepresentation(Qualifiers.Length, Qualifiers.AllowedLength);
	ElsIf Type = Type("Date") Then
		Qualifiers = TypeDescription.DateQualifiers;
		Result = DateTypeRepresentation(Qualifiers.DateFractions);
	ElsIf Type = Type("Number") Then
		Qualifiers = TypeDescription.NumberQualifiers;
		Result = NumberTypeRepresentation(Qualifiers.Digits, Qualifiers.FractionDigits, Qualifiers.AllowedSign);
	EndIf;
	
	Return Result;
EndFunction

Function StringTypeRepresentation(Length, Var_AllowedLength)
	Return "String(" + Length + ", " + Var_AllowedLength + ")";
EndFunction

Function DateTypeRepresentation(DatePartsValue)
	Return "Date(" + DatePartsValue + ")";
EndFunction

Function NumberTypeRepresentation(Digits, FractionDigits, ValidSignValue)
	Return "Number(" + Digits + ", " + FractionDigits + ", " + ValidSignValue + ")";
EndFunction

Procedure UpdatePredefinedDirectoryItemsList(CatalogName, RequiredElements)
	
	PredefinedList = RequiredElements;
	If CatalogName = "MetadataObjectIDs" Then
		PredefinedList = AllRegistersPredefinedIdentifiers();
	EndIf;
	
	CatalogMetadata     = Metadata.Catalogs[CatalogName];
	FileName = PredefinedElementsDescriptionFilePath(CatalogMetadata);
	DOMDocument = DOMDocument(FileName);
	Dereferencer = New DOMNamespaceResolver(DOMDocument);
	
	ErrorHeaderTemplate = NStr("ru = 'Отсутствует предопределенный элемент %1 в справочнике %2';
								|en = 'The %1 predefined item is missing in the %2 catalog';");
	ErrorExplanationTemplate = NStr("ru = 'Регистр %1 ограничивается на уровне записей, поэтому добавьте предопределенный элемент %3 в справочнике %2';
								|en = 'The %1 register is restricted on a record level, so add predefined item %3 in the %2 catalog';");
	ExplanationCorrectionTemplate = NStr("ru = 'Исправлено. Для регистра %1 добавлен предопределенный элемент %3 в справочнике %2.';
										|en = 'Fixed. For the %1 register in the %2 catalog, the %3 predefined item is added.';");
	
	HasChanges = False;
	IDsOfPredefined = New Array;
	For Each PredefinedItemDetails In PredefinedList Do
		PredefinedItemName = PredefinedItemDetails.Key;
		MetadataObject = Common.MetadataObjectByFullName(PredefinedItemDetails.Value);
		IDsOfPredefined.Add(PredefinedItemName);
		
		HasPredefinedOne = DOMDocument.EvaluateXPathExpression(XPathExpressionPredefinedCatalogElement(PredefinedItemName),
			DOMDocument, Dereferencer).IterateNext() <> Undefined;
			
		If Not HasPredefinedOne Then
			ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(ErrorHeaderTemplate, PredefinedItemName, CatalogName);
			If FixError("IncorrectPredefinedElementsCompositionInMetadataObjectIdentifiersDirectory")
				And CatalogName = "MetadataObjectIDs" Then
				Predefined = DOMDocument.EvaluateXPathExpression(XPathExpressionPredefinedData(), DOMDocument, Dereferencer).IterateNext();
				NodeElement = Predefined.AppendChild(DOMDocument.CreateElement(PredefinedDataDetailsProperty()));
				NodeElement.SetAttribute("id", String(New UUID));
				If EDTConfiguration Then
					NodeElement.AppendChild(DOMDocument.CreateElement(NameProperty())).TextContent = String(PredefinedItemName);
					CodeNode = NodeElement.AppendChild(DOMDocument.CreateElement(CodeProperty()));
					AttributeType = DOMDocument.CreateAttribute("http://www.w3.org/2001/XMLSchema-instance", "xsi:type");
					AttributeType.TextContent = "core:StringValue";
					CodeNode.Attributes.SetNamedItem(AttributeType);
					CodeNode.AppendChild(DOMDocument.CreateElement(CodeValueProperty()));
				Else
					NodeElement.AppendChild(DOMDocument.CreateElement(NameProperty())).TextContent = String(PredefinedItemName);
					NodeElement.AppendChild(DOMDocument.CreateElement(CodeProperty()));
					NodeElement.AppendChild(DOMDocument.CreateElement(DescriptionProperty()));
					NodeElement.AppendChild(DOMDocument.CreateElement(IsGroupProperty())).TextContent = "false";
				EndIf;
				HasChanges = True;
				AddError(MetadataObject, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
					ExplanationCorrectionTemplate, MetadataObject.FullName(), CatalogName, PredefinedItemName));
			ElsIf RequiredElements.Property(PredefinedItemName) Then
				AddError(MetadataObject, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
					ErrorExplanationTemplate, MetadataObject.FullName(), CatalogName, PredefinedItemName));
			EndIf;
		EndIf;
	EndDo;
	
	If ValueIsFilled(IDsOfPredefined) Then
		MetadataObject = Metadata.Catalogs.MetadataObjectIDs;
		ErrorHeaderTemplate = NStr("ru = 'Некорректный предопределенный элемент %1';
									|en = 'Incorrect predefined item %1';");
		ErrorExplanationTemplate = NStr("ru = 'Отсутствует объект метаданных, соответствующий предопределенному элементу %1, удалите элемент.';
									|en = 'A metadata object that matches the %1 predefined item is missing. Delete the item.';");
		ExplanationCorrectionTemplate = NStr("ru = 'Исправлено. Удален некорректный предопределенный элемент %1, так как отсутствует соответствующий объект метаданных.';
											|en = 'Fixed. Incorrect predefined item %1 is deleted, because the metadata object matching it is missing.';");
		
		IncorrectPredefined = DOMDocument.EvaluateXPathExpression(XPathExpressionIncorrectPredefined(IDsOfPredefined), DOMDocument, Dereferencer);
		Item = IncorrectPredefined.IterateNext();
		While Item <> Undefined Do
			PredefinedItemName = DOMDocument.EvaluateXPathExpression(XPathExpressionPredefinedName(), Item, Dereferencer).IterateNext().TextContent;
			ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(ErrorHeaderTemplate, PredefinedItemName, CatalogName);
			
			If FixError("IncorrectPredefinedElementsCompositionInMetadataObjectIdentifiersDirectory") Then
				Item.ParentNode.RemoveChild(Item);
				HasChanges = True;
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ExplanationCorrectionTemplate, PredefinedItemName);
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorExplanationTemplate, PredefinedItemName);
			EndIf;
			If FixError("IncorrectPredefinedElementsCompositionInMetadataObjectIdentifiersDirectory") Then
				AddError(MetadataObject, ErrorTitle, ErrorText);
			EndIf;
			Item = IncorrectPredefined.IterateNext();
		EndDo;
	EndIf;
	
	If HasChanges Then
		WriteDOMDocument(DOMDocument, FileName);
	EndIf;
	
EndProcedure

Function AllRegistersPredefinedIdentifiers()
	
	Result = New Structure;
	
	MetadataObjectsCollections = New Array;
	MetadataObjectsCollections.Add(Metadata.AccountingRegisters);
	MetadataObjectsCollections.Add(Metadata.AccumulationRegisters);
	MetadataObjectsCollections.Add(Metadata.CalculationRegisters);
	MetadataObjectsCollections.Add(Metadata.InformationRegisters);
	
	For Each MetadataObjectCollection In MetadataObjectsCollections Do
		For Each MetadataObject In MetadataObjectCollection Do
			If Not StrStartsWith(Lower(MetadataObject.Name), "delete") Then
				Result.Insert(StrReplace(MetadataObject.FullName(), ".", ""), MetadataObject.FullName());
			EndIf;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns:
//  Structure:
//   * UpdateOnlyConstraintTemplates - Boolean
//   * AccessManagement - Structure:
//     ** RestrictionTemplates - See ReferenceConstraintsTemplates 
//     ** RolesAssignment - See Users.RolesAssignment
//     ** RestrictedAccessLists - See AccessManagementOverridable.OnFillListsWithAccessRestriction.Lists 
//     ** ImplementationSettings - See AccessManagementInternal.ImplementationSettings 
//     ** PredefinedIDs - Map 
//
Function AccessControlImplementationVerificationParameters()
	
	Parameters = New Structure;
	Parameters.Insert("UpdateOnlyConstraintTemplates", False);
	Parameters.Insert("AccessManagement", New Structure);
	Parameters.AccessManagement.Insert("RestrictionTemplates", ReferenceConstraintsTemplates());
	Parameters.AccessManagement.Insert("RolesAssignment", Undefined);
	Parameters.AccessManagement.Insert("RestrictedAccessLists", Undefined);
	Parameters.AccessManagement.Insert("ImplementationSettings", Undefined);
	Parameters.AccessManagement.Insert("PredefinedIDs", Undefined);
	
	Return Parameters;
	
EndFunction

// Returns:
//  Map
//
Function ReferenceConstraintsTemplates()
	
	Result = New Map;
	
	FileNameWithTemplate = RoleCompositionFilePath("EditAccessGroupMembers");
	
	DOMDocument = DOMDocument(FileNameWithTemplate);
	Dereferencer = New DOMNamespaceResolver(DOMDocument);
	
	RestrictionTemplates = DOMDocument.EvaluateXPathExpression(XPathExpressionConstraintPatterns(), DOMDocument, Dereferencer);
	Template = RestrictionTemplates.IterateNext();
	While Template <> Undefined Do
		TemplateName = DOMDocument.EvaluateXPathExpression(XPathExpressionValueTemplateName(), Template, Dereferencer).IterateNext().TextContent;
		TemplateText = DOMDocument.EvaluateXPathExpression(XPathExpressionValueTemplateText(), Template, Dereferencer).IterateNext().TextContent;
		DescriptionOfTemplate = New Structure("Name,Text", TemplateName, TemplateText);
		
		Var_Key = TemplateName;
		ParenthesisPosition = StrFind(Var_Key, "(");
		If ParenthesisPosition > 0 Then
			Var_Key = Left(Var_Key, ParenthesisPosition - 1);
		EndIf;
		Result.Insert(Var_Key, DescriptionOfTemplate);
		
		Template = RestrictionTemplates.IterateNext();
	EndDo;
	
	Return Result;
	
EndFunction

Procedure CheckProcedureInsertionAtFillingAccessRestrictionInObjectManagerModule(Parameters, MetadataObject)
	
	RestrictionTextInManagerModule = Parameters.AccessManagement.RestrictedAccessLists[MetadataObject] = True;
	If Not RestrictionTextInManagerModule Then
		Return;
	EndIf;
	
	ManagerModule = ManagerModule(MetadataObject);
	
	ModuleProcedure = FindModuleProcedure(ManagerModule, "OnFillAccessRestriction");
	If ModuleProcedure = Undefined Then
		AddError(MetadataObject, NStr("ru = 'Отсутствует обязательная вставка кода';
												|en = 'The required code insert is missing';"), 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В модуле менеджера должна быть процедура %1.';
					|en = 'Manager module must contain procedure %1.';"), "OnFillAccessRestriction"));
	EndIf;
	
EndProcedure

Procedure CheckRoleTextInsertion(Parameters, Role)
	
	If Role.Name = "EditAccessGroupMembers" Then
		Return;
	EndIf;
	
	RoleRightsFileName = RoleCompositionFilePath(Role.Name);
	
	DOMDocument = DOMDocument(RoleRightsFileName);
	Dereferencer = New DOMNamespaceResolver(DOMDocument);
	
	SetNewObjectsRights = Boolean(DOMDocument.EvaluateXPathExpression(
		ExpressionXPathBasicPropertyOfRole(SetRightsForNewObjectsProperty()), DOMDocument, Dereferencer).IterateNext().TextContent);
	
	If SetNewObjectsRights And Role.Name <> "FullAccess" And Role.Name <> "SystemAdministrator" Then
		Return;
	EndIf;
	
	If Not Parameters.UpdateOnlyConstraintTemplates Then
		CheckIsRestrictionInRole(DOMDocument, Role, Dereferencer, RoleRightsFileName, Parameters);
	EndIf;
	
	HasTemplateChange = False;
	For Each Template In Parameters.AccessManagement.RestrictionTemplates Do
		TemplateName = Template.Key;
		DescriptionOfTemplate = Template.Value;
		CheckForTemplateInRole(DOMDocument, Role, TemplateName, DescriptionOfTemplate, HasTemplateChange);
	EndDo;
	
	If HasTemplateChange Then
		WriteDOMDocument(DOMDocument, RoleRightsFileName);
	EndIf;
	
EndProcedure

Procedure CheckIsRestrictionInRole(DOMDocument, Role, Dereferencer, RoleRightsFileName, Parameters)
	
	HasChanges = False;
	
	ObjectsComposition = DOMDocument.EvaluateXPathExpression(XPathExpressionRoleComposition(), DOMDocument, Dereferencer);
	Object = ObjectsComposition.IterateNext();
	While Object <> Undefined Do
		ObjectName = DOMDocument.EvaluateXPathExpression(XPathExpressionValueRoleObjectName(), Object, Dereferencer).IterateNext().TextContent;
		
		MetadataObject = Common.MetadataObjectByFullName(ObjectName);
		If MetadataObject <> Undefined Then
			DifferentRestrictionsTextForUsersAndExternalUsersInSameRole = False;
			If Parameters.AccessManagement.RolesAssignment.ForExternalUsersOnly.Find(Role.Name) <> Undefined Then
				RestrictionDetails = Parameters.AccessManagement.ImplementationSettings.RestrictionsInRoles.ForExternalUsers[ObjectName];
				
			ElsIf Parameters.AccessManagement.RolesAssignment.BothForUsersAndExternalUsers.Find(Role.Name) = Undefined Then
				RestrictionDetails = Parameters.AccessManagement.ImplementationSettings.RestrictionsInRoles.ForUsers[ObjectName];
			Else // BothForUsersAndExternalUsers.
				RestrictionDetails           = Parameters.AccessManagement.ImplementationSettings.RestrictionsInRoles.ForUsers[ObjectName];
				RestrictionForExternalDescription = Parameters.AccessManagement.ImplementationSettings.RestrictionsInRoles.ForExternalUsers[ObjectName];
				If RestrictionDetails <> Undefined Or RestrictionForExternalDescription <> Undefined Then
					RestrictionDetails           = ?(RestrictionDetails = Undefined,           Null, RestrictionDetails);
					RestrictionForExternalDescription = ?(RestrictionForExternalDescription = Undefined, Null, RestrictionForExternalDescription);
					Text           = RestrictionTextFromDescription(RestrictionDetails);
					TextForExternal = RestrictionTextFromDescription(RestrictionForExternalDescription);
					DifferentRestrictionsTextForUsersAndExternalUsersInSameRole = Text <> TextForExternal;
				EndIf;
			EndIf;
			If RestrictionDetails <> Undefined Then
				NewRestrictionText = RestrictionTextFromDescription(RestrictionDetails);
				Rights = DOMDocument.EvaluateXPathExpression(XPathExpressionObjectRights(), Object, Dereferencer);
				Right = Rights.IterateNext();
				HasCurrentChanges = False;
				UpdateRequired = False;
				
				OldRightsTexts = New Map;
				NewTextsOnRights  = New Map;
				While Right <> Undefined Do
					RightTitle = RightTitle(DOMDocument.EvaluateXPathExpression(XPathExpressionValueRoleObjectName(), Right, Dereferencer).IterateNext().TextContent);
					AccessRestriction = DOMDocument.EvaluateXPathExpression(XPathExpressionAccessRestriction(), Right, Dereferencer).IterateNext();
					
					If AccessRestriction <> Undefined And Not IsBlankString(AccessRestriction.TextContent)
						And StrFind(AccessRestriction.TextContent, "MandatoryAdditionalConditionStart") = 0
						And StrFind(AccessRestriction.TextContent, "MandatoryAdditionalConditionEnd") = 0 Then
						
						RestrictionTextToInsert = RestrictionTextToInsert(NewRestrictionText, AccessRestriction.TextContent);
						HasTextDifferences = RemoveNonPrintableCharacters(AccessRestriction.TextContent) <> RemoveNonPrintableCharacters(RestrictionTextToInsert);
						If HasTextDifferences Or DifferentRestrictionsTextForUsersAndExternalUsersInSameRole Then
							RightsList = OldRightsTexts[AccessRestriction.TextContent];
							If RightsList = Undefined Then
								OldRightsTexts.Insert(AccessRestriction.TextContent, RightTitle);
							Else
								OldRightsTexts[AccessRestriction.TextContent] = RightsList + ", " + RightTitle;
							EndIf;
							RightsList = NewTextsOnRights[RestrictionTextToInsert];
							If RightsList = Undefined Then
								NewTextsOnRights.Insert(RestrictionTextToInsert, RightTitle);
							Else
								NewTextsOnRights[RestrictionTextToInsert] = RightsList + ", " + RightTitle;
							EndIf;
							
							If HasTextDifferences And FixError("InvalidConstraintTextForTableInRole") Then
								AccessRestriction.TextContent = RestrictionTextToInsert;
								HasCurrentChanges = True;
								HasChanges = True;
							Else
								UpdateRequired = True;
							EndIf;
						EndIf;
					EndIf;
					
					Right = Rights.IterateNext();
				EndDo;
				
				BriefErrorDetails = NStr("ru = 'Неверный текст ограничения для таблицы в роли';
											|en = 'Incorrect restriction text for the table in role';");
				TextsExplanation = New Array;
				For Each RightsText In OldRightsTexts Do
					TextsExplanation.Add(RightsText.Value + ":" + Chars.LF + RightsText.Key);
				EndDo;
				OldTextsExplanation = StrConcat(TextsExplanation, Chars.LF + Chars.LF);
				
				TextsExplanation = New Array;
				For Each RightsText In NewTextsOnRights Do
					TextsExplanation.Add(RightsText.Value + ":" + Chars.LF + RightsText.Key);
				EndDo;
				NewTextsExplanation = StrConcat(TextsExplanation, Chars.LF + Chars.LF);
				
				If OldTextsExplanation <> NewTextsExplanation Then
					TextsExplanation = "%2" + Chars.LF
						+ Chars.LF
						+ OldTextsExplanation + Chars.LF
						+ Chars.LF
						+ "%3" + Chars.LF
						+ Chars.LF
						+ NewTextsExplanation;
				Else
					TextsExplanation = "%2" + Chars.LF
						+ Chars.LF
						+ OldTextsExplanation;
				EndIf;
				If HasCurrentChanges Then
					If DifferentRestrictionsTextForUsersAndExternalUsersInSameRole Then
						DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Исправлено частично для таблицы %1.
							           |1. Не обновлены тексты ограничения внешних пользователей,
							           |так как они отличаются от текстов ограничения пользователей:
							           |Для пользователей: %4
							           |Для внешних пользователей: %5
							           |Следует либо сделать ограничения доступа одинаковыми,
							           |либо сделать отдельные роли для пользователей и внешних пользователей.
							           |
							           |2. Обновлены тексты ограничений пользователей для таблицы %1.';
										|en = 'Partly fixed for table %1.
										|1. Texts of external user restrictions are not refreshed
										|because they differ from user restriction texts:
										|For users: %4
										|For external users: %5
										|You need to either make access restrictions equal,
										|or make separate roles for users and external users.
										|
										|2. User restriction texts for table %1 are refreshed.';") + Chars.LF + Chars.LF + TextsExplanation,
							MetadataObject.FullName(), NStr("ru = 'Было:';
																|en = 'Previous value:';"), NStr("ru = 'Стало:';
																					|en = 'Current value:';"), Text, TextForExternal);
					Else
						DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Исправлено. Обновлены тексты ограничений для таблицы %1.';
								|en = 'Fixed. Restriction texts for the %1 table are updated.';") + Chars.LF + Chars.LF + TextsExplanation,
							MetadataObject.FullName(), NStr("ru = 'Было:';
																|en = 'Previous value:';"), NStr("ru = 'Стало:';
																					|en = 'Current value:';"));
					EndIf;
				ElsIf UpdateRequired Then
					If DifferentRestrictionsTextForUsersAndExternalUsersInSameRole Then
						DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = '1. Для таблицы %1 невозможно обновить тексты ограничений
							           |внешних пользователей, так как они отличаются от текстов ограничения пользователей:
							           |Для пользователей: %4
							           |Для внешних пользователей: %5
							           |Следует либо сделать ограничения доступа одинаковыми,
							           |либо сделать отдельные роли для пользователей и внешних пользователей.
							           |
							           |2. Обновите тексты ограничений для таблицы %1.';
										|en = '1. Cannot refresh restriction texts
										|of external users for the %1 table as they differ from user restriction texts:
										|For users: %4
										|For external users: %5
										|Either make access restrictions identical,
										|or make separate roles for users and external users.
										|
										|2. Refresh user restriction texts for the %1 table.';") + Chars.LF + Chars.LF + TextsExplanation,
							MetadataObject.FullName(), NStr("ru = 'Текущее значение:';
																|en = 'Current value:';"), NStr("ru = 'Заменить для пользователей на:';
																								|en = 'Replace for users with:';"), Text, TextForExternal);
					Else
						DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Обновите тексты ограничений для таблицы %1';
								|en = 'Update restriction texts for the %1 table';") + Chars.LF + Chars.LF + TextsExplanation,
							MetadataObject.FullName(), NStr("ru = 'Текущее значение:';
																|en = 'Current value:';"), NStr("ru = 'Заменить на:';
																								|en = 'Replace with:';"));
					EndIf;
				EndIf;
				
				If HasCurrentChanges Or UpdateRequired Then
					AddError(Role, BriefErrorDetails, DetailedErrorDetails);
				EndIf;
			EndIf;
		EndIf;
		
		Object = ObjectsComposition.IterateNext();
	EndDo;
	
	If HasChanges Then
		WriteDOMDocument(DOMDocument, RoleRightsFileName);
		DOMDocument = DOMDocument(RoleRightsFileName);
		Dereferencer = New DOMNamespaceResolver(DOMDocument);
	EndIf;
	
EndProcedure

Procedure CheckNewRLSInRolesUse(AccessRestrictions, RestrictedAccessLists)
	
	RolesWithRestrictionTexts = AccessRestrictions.Copy(, "Role,Table,Restriction");
	RolesWithRestrictionTexts.GroupBy("Role,Table,Restriction");
	RolesWithRestrictionTexts.Sort("Table");
	RolesWithRestrictionTexts.Indexes.Add("Table");
	
	TablesList = RolesWithRestrictionTexts.Copy(, "Table");
	TablesList.GroupBy("Table");
	TablesList = TablesList.UnloadColumn("Table");
	
	TablesWithoutNewRLS = New Array;
	
	For Each Table In TablesList Do
		FoundRows = RolesWithRestrictionTexts.FindRows(New Structure("Table", Table));
		For Each FoundRow In FoundRows Do
			OldRLSFound = False;
			If RestrictionContainsOldRLSTextTemplates(FoundRow.Restriction) Then
				OldRLSFound = True;
			EndIf;
		EndDo;
		
		If Not OldRLSFound Then
			Continue;
		EndIf;
		
		MetadataObject = Common.MetadataObjectByFullName(Table);
		
		If RestrictedAccessLists[MetadataObject] <> Undefined Then
			Continue;
		EndIf;
		
		RolesList = New Array;
		For Each FoundRow In FoundRows Do
			If RolesList.Find(FoundRow.Role) = Undefined Then
				RolesList.Add(FoundRow.Role);
			EndIf;
		EndDo;
		
		TablesWithoutNewRLS.Add(New Structure("MetadataObject,Roles", MetadataObject, RolesList));
	EndDo;
	
	For Each Table In TablesWithoutNewRLS Do
		MetadataObject = Table.MetadataObject;
		RolesList = Table.Roles;
		ExplanationText = "";
		If RolesList.Count() = 1 Then
			ExplanationText = NStr("ru = 'Доступ к объекту на уровне записей ограничен в роли';
									|en = 'Access to object on the record level is restricted in role';") + " " + RolesList[0];
		Else
			ExplanationText = NStr("ru = 'Доступ к объекту на уровне записей ограничен в ролях:';
									|en = 'Access to object on the record level is restricted in roles:';") + Chars.LF 
				+ StrConcat(RolesList, Chars.LF);
		EndIf;
		
		TemplateOfInsert = "	Lists.Insert(%1, True);";
		NameParts = StrSplit(MetadataObject.FullName(), ".", True);
		NameParts[0] = MetadataTypesMap(NameParts[0]);
		MetadataObjectByString = "Metadata." + StrConcat(NameParts, ".");
		
		TextForInsert = StringFunctionsClientServer.SubstituteParametersToString(TemplateOfInsert, MetadataObjectByString);
		
		BriefErrorDetails = NStr("ru = 'Отсутствует обязательная вставка кода';
									|en = 'The required code insert is missing';");
		DetailedErrorDetails = NStr("ru = 'В процедуре %1 отсутствует обязательная вставка кода:';
										|en = 'Procedure %1 does not contain the required code insert:';") + Chars.LF
			+ TextForInsert + Chars.LF
			+ ExplanationText;
		DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(DetailedErrorDetails, "AccessManagementOverridable.OnFillListsWithAccessRestriction");
		
		AddError(MetadataObject, BriefErrorDetails, DetailedErrorDetails);
	EndDo;
	
EndProcedure

Function RestrictionContainsOldRLSTextTemplates(RestrictionText)
	Return StrFind(RestrictionText, "#ByValues") > 0 Or StrFind(RestrictionText, "#BySets") > 0;
EndFunction

Function RemoveNonPrintableCharacters(Val String)
	NonPrintableCharacters = " " + Chars.Tab + Chars.LF + Chars.CR;
	Return StrConcat(StrSplit(String, NonPrintableCharacters, False), "");
EndFunction

Function RightTitle(XMLPermissionName)
	
	If XMLPermissionName = "Read" Then
		Return NStr("ru = 'Чтение';
					|en = 'Read';");
	ElsIf XMLPermissionName = "Insert" Then
		Return NStr("ru = 'Добавление';
					|en = 'Insert';");
	ElsIf XMLPermissionName = "Update" Then
		Return NStr("ru = 'Изменение';
					|en = 'Update';");
	EndIf;
	
	Return XMLPermissionName;
	
EndFunction

Procedure CheckForTemplateInRole(DOMDocument, Role, TemplateName, SuppliedTemplate_, HasChanges)
	
	Dereferencer = New DOMNamespaceResolver(DOMDocument);
	
	TemplateUsed = DOMDocument.EvaluateXPathExpression(XPathExpressionUsingTemplate(TemplateName), 
		DOMDocument, Dereferencer).IterateNext() <> Undefined;
		
	FoundedTemplate = DOMDocument.EvaluateXPathExpression(XPathExpressionTemplateSearch(TemplateName), DOMDocument, Dereferencer).IterateNext();
	
	If Not TemplateUsed Then
		If FoundedTemplate = Undefined Then
			Return;
		EndIf;
		ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Шаблон #%1 не используется в роли.';
				|en = 'Template #%1 is not used in the role.';"), TemplateName);
		If FixError("NotUsedInRoleTemplate") Then
			FoundedTemplate.ParentNode.RemoveChild(FoundedTemplate);
			HasChanges = True;
			AddError(Role, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Исправлено. Неиспользуемый шаблон #%1 удален.';
					|en = 'Fixed. Not used template #%1 has been deleted.';"), TemplateName));
		Else
			AddError(Role, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Шаблон #%1 не используется, удалите его.';
					|en = 'Template #%1 is not used, delete it.';"), TemplateName));
		EndIf;
		Return;
	EndIf;
	
	If Not VerificationIsRequired("TemplateUsedInRoleIsMissingOrDifferent") Then
		Return;
	EndIf;
	
	If FoundedTemplate <> Undefined Then
		AvailableTemplate = DOMDocument.EvaluateXPathExpression(XPathExpressionValueTemplateText(), FoundedTemplate, Dereferencer).IterateNext();
		TextOfExistingTemplate    = AvailableTemplate.TextContent;
		TextOf1CSuppliedTemplate = SuppliedTemplate_.Text;
		If Not FixError("TemplateUsedInRoleIsMissingOrDifferent") Then
			TextOfExistingTemplate    = TextOfTemplateToCompareWith(TextOfExistingTemplate);
			TextOf1CSuppliedTemplate = TextOfTemplateToCompareWith(TextOf1CSuppliedTemplate);
		EndIf;
		If TextOfExistingTemplate <> TextOf1CSuppliedTemplate Then
			ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Шаблон #%1 отличается от поставляемого.';
					|en = 'Template #%1 differs from the built-in template.';"), TemplateName);
			If FixError("TemplateUsedInRoleIsMissingOrDifferent") Then
				AvailableTemplate.TextContent = SuppliedTemplate_.Text;
				HasChanges = True;
				AddError(Role, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Исправлено. Шаблон #%1 обновлен из поставки конфигурации.';
						|en = 'Fixed. Template #%1 is updated from the configuration package.';"), TemplateName));
			Else
				AddError(Role, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Текст шаблона #%1 скопируйте из роли %2.';
						|en = 'Copy the text of template #%1 from role %2.';"), TemplateName, "EditAccessGroupMembers"));
			EndIf;
		EndIf;
	Else
		ErrorTitle = NStr("ru = 'Отсутствует используемый шаблон в роли';
								|en = 'The template being used is missing in role';");
		If FixError("TemplateUsedInRoleIsMissingOrDifferent") Then
			AddTemplateToRole(DOMDocument, SuppliedTemplate_);
			HasChanges = True;
			AddError(Role, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Исправлено. В роль добавлен шаблон #%1';
					|en = 'Fixed. Template #%1 is added to the role';"), TemplateName));
		Else
			AddError(Role, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В роль скопируйте шаблон #%1 из роли %2.';
					|en = 'Copy template #%1 to the role from role %2.';"), TemplateName, "EditAccessGroupMembers"));
		EndIf;
	EndIf;

EndProcedure

Function TextOfTemplateToCompareWith(SourceText)
	
	Text = TrimR(SourceText);
	Rows = StrSplit(Text, Chars.LF + Chars.CR, False);
	Return StrConcat(Rows, Chars.LF);
	
EndFunction

Procedure AddTemplateToRole(DOMDocument, DescriptionOfTemplate)
	Dereferencer = New DOMNamespaceResolver(DOMDocument);
	RoleDetails = DOMDocument.EvaluateXPathExpression(XPathExpressionRoleDescription(), DOMDocument, Dereferencer).IterateNext();
	
	NodeTemplateConstraints = RoleDetails.AppendChild(DOMDocument.CreateElement(RoleTemplateProperty()));
	
	NodeTemplateName = NodeTemplateConstraints.AppendChild(DOMDocument.CreateElement(RoleTemplateNameProperty()));
	NodeTemplateName.TextContent = DescriptionOfTemplate.Name;
	
	NodeTemplateText = NodeTemplateConstraints.AppendChild(DOMDocument.CreateElement(RoleTemplateTextProperty()));
	NodeTemplateText.TextContent = DescriptionOfTemplate.Text;
EndProcedure

Function RestrictionTextToInsert(Val NewRestrictionText, Val RestrictionOldText)
	
	RestrictionText = RemoveRestrictingAccessBracketsAtRecordLevelUniversal(RestrictionOldText);
	RestrictionText = StringFunctionsClientServer.SubstituteParametersToString(
		RoleRestrictionTextTemplate(), NewRestrictionText, TrimAll(RestrictionText));
	
	Return RestrictionText;
	
EndFunction

Function RemoveRestrictingAccessBracketsAtRecordLevelUniversal(Val RestrictionText)
	
	RestrictionText = TrimAll(RestrictionText);
	
	If StrStartsWith(Upper(RestrictionText), Upper("#If &RecordLevelAccessRestrictionIsUniversal")) Then
		SearchText = "#Else";
		Position = StrFind(Upper(RestrictionText), Upper(SearchText));
		If Position > 0 Then
			RestrictionText = Mid(RestrictionText, Position + StrLen(SearchText));
			SearchText = "#EndIf";
			If StrEndsWith(Upper(RestrictionText), Upper(SearchText)) Then
				RestrictionText = Left(RestrictionText, StrLen(RestrictionText) - StrLen(SearchText));
			EndIf;
		EndIf;
	EndIf;
	
	RestrictionText = TrimAll(RestrictionText);
	
	Return RestrictionText;
	
EndFunction

Function RestrictionTextFromDescription(RestrictionDetails)
	
	If RestrictionDetails = Null Then
		Return "";
	EndIf;
	
	If RestrictionDetails.TemplateForObject Then
		TemplateName = "ForObject";
		Parameters = New Array(1);
	Else
		TemplateName = "ForRegister";
		Parameters = New Array(6);
	EndIf;
	
	For IndexOf = 0 To RestrictionDetails.Parameters.UBound() Do
		Parameters[IndexOf] = """" + RestrictionDetails.Parameters[IndexOf] + """";
	EndDo;
	
	For IndexOf = RestrictionDetails.Parameters.UBound() + 1 To Parameters.UBound() Do
		Parameters[IndexOf] = """""";
	EndDo;
	
	Return "#" + TemplateName + "(" + StrConcat(Parameters, ", ")+ ")";
	
EndFunction

Function RoleRestrictionTextTemplate()
	Return 
	"#If &RecordLevelAccessRestrictionIsUniversal #Then
	|%1
	|#Else
	|%2
	|#EndIf"
EndFunction

Function VerificationIsRequired(ErrorIDsByString = "")
	
	ErrorIds = StrSplit(ErrorIDsByString, ", " + Chars.LF, False);
	CorrectionMode = False;
	For Each ErrorID In ErrorIds Do
		CorrectionMode = CorrectionMode Or FixError(ErrorID);
	EndDo;
	
	Return InteractiveLaunch Or Not CorrectErrors Or CorrectionMode;
	
EndFunction

#Region ModuleCheck

Function CanUseRegEx()
	
	If CanUseRegEx <> Undefined Then
		Return CanUseRegEx;
	EndIf;
	
	MinRequired1CEnterpriseVersion = MinVersionSupportingRegEx();
	
	SystemInfo = New SystemInfo;
	PlatformVersion = SystemInfo.AppVersion;
	
	TheResultOfComparingVersions = CommonClientServer.CompareVersions(PlatformVersion,
		MinRequired1CEnterpriseVersion);
	
	CanUseRegEx = (TheResultOfComparingVersions >= 0);
	
	Return CanUseRegEx;
	
EndFunction

// Returns:
//  Structure:
//   * Length            - Number
//   * Value         - String
//   * StartIndex - Number
//
Function EvalStrFindByRegularExpression(Text, SearchExpression, StartPosition = 1)
	
	Expression = "StrFindByRegularExpression(Text, SearchExpression,, StartPosition)";
	
	Try
		CalculationResult = Eval(Expression); // ACC:488 - Executable code is static and safe.
	Except
		Return Undefined;
	EndTry;
	
	Return CalculationResult; // 
	
EndFunction

Function FindModuleProcedure(Module, ProcedureName)
	
	If Not CanUseRegEx() Then
		// Backward compatibility in case the used 1C:Enterprise version does not support regular expressions.
		ReadModuleStructure(Module);
		Return FindBlock(Module.Structure.Content, "Procedure" + " " + ProcedureName + "(");
	EndIf;
	
	ModuleText = Module.ModuleText;
	If ModuleText = Undefined Then
		Return Undefined;
	EndIf;
	
	// Search for the procedure with the given name in the first line.
	SearchExpression  = "(?m)^Procedure " + ProcedureName + "\(";
	
	ProcedureBeginningSearchResult = EvalStrFindByRegularExpression(ModuleText, SearchExpression);
	If ProcedureBeginningSearchResult = Undefined Then
		Return Undefined;
	EndIf;
	
	StartPosition = ProcedureBeginningSearchResult.StartIndex;
	If StartPosition = 0 Then
		Return Undefined;
	EndIf;
	
	SearchResultEndProcedure = Undefined;
	
	// Search a string with the leading "EndProcedure" keyword following the declaration of the found procedure.
	SearchExpression = "(?m)^EndProcedure";
	SearchResultEndProcedure = EvalStrFindByRegularExpression(ModuleText, SearchExpression, StartPosition);
	
	If SearchResultEndProcedure.StartIndex = 0 Then
		Return Undefined;
	EndIf;
	
	Result = New Structure;
	Result.Insert("ProcedureText",          "");
	Result.Insert("Title",               "");
	Result.Insert("Content",              "");
	Result.Insert("LongDesc",                "");
	Result.Insert("PreprocessorInstruction", "");
	Result.Insert("Footer",                  "");
	
	// Get the procedure's text.
	ProcedureStrLen = SearchResultEndProcedure.StartIndex + StrLen("EndProcedure") - StartPosition;
	Result.ProcedureText = Mid(ModuleText, StartPosition, ProcedureStrLen);
	
	RowsArray = StrSplit(Result.ProcedureText, Chars.LF);
	If RowsArray.Count() = 0 Then
		Return Result;
	EndIf;
	
	// The title is the first line of the procedure.
	Result.Title = RowsArray[0];
	
	// Content (the procedure's body).
	RowsArray.Delete(0);
	RowsArray.Delete(RowsArray.UBound());
	Result.Content = RowsArray;
	
	Return Result;
	
EndFunction

Function BlockContentsToString(Block)
	
	RowsCollection = New Array;
	For Each ContentBlock In Block.Content Do
		RowsCollection.Add(BlockToString(ContentBlock));
	EndDo;
	
	Return StrConcat(RowsCollection, Chars.LF);
	
EndFunction

Function LineToBlock(Text)
	BlocksTypes = BlocksTypes();
	
	Result = NewBlock();
	If StrLen(Text) = 0 Then
		Return Result;
	EndIf;
	
	CurrentBlock = Result;
	LongDesc = New Array;
	PreprocessorInstruction = "";
	For Each String In StrSplit(Text, Chars.LF, True) Do
		If IsBlockHeader(String, BlocksTypes) Then
			NewBlock = NewBlock(CurrentBlock, String, StrConcat(LongDesc, Chars.LF));
			CurrentBlock.Content.Add(NewBlock);
			CurrentBlock = NewBlock;
			CurrentBlock.PreprocessorInstruction = PreprocessorInstruction;
			PreprocessorInstruction = "";
			LongDesc.Clear();
		ElsIf IsTitleContinuation(CurrentBlock.Title, String) Then
			CurrentBlock.Title = CurrentBlock.Title + Chars.LF + String;
		ElsIf IsBlockFooter(String, CurrentBlock, BlocksTypes) Then
			PutDescriptionLinesToContent(CurrentBlock.Content, LongDesc);
			CurrentBlock.Footer = String;
			CurrentBlock = CurrentBlock.Parent;
		ElsIf StrStartsWith(String, "//") And IsBlankString(PreprocessorInstruction) Then
			LongDesc.Add(String);
		ElsIf StrStartsWith(String, "&") And IsBlankString(PreprocessorInstruction) Then
			PreprocessorInstruction = String;
		Else
			PutDescriptionLinesToContent(CurrentBlock.Content, LongDesc);
			If Not IsBlankString(PreprocessorInstruction) Then
				CurrentBlock.Content.Add(PreprocessorInstruction);
				PreprocessorInstruction = "";
			EndIf;
			CurrentBlock.Content.Add(String);
		EndIf;
	
		If StrStartsWith(TrimL(CurrentBlock.Title), "Var") And StrFind(CurrentBlock.Title, ";") > 0 Then
			CurrentBlock = CurrentBlock.Parent;
		EndIf;
	EndDo;
	
	PutDescriptionLinesToContent(CurrentBlock.Content, LongDesc);
	If Not IsBlankString(PreprocessorInstruction) Then
		CurrentBlock.Content.Add(PreprocessorInstruction);
	EndIf;
	
	Return Result;
EndFunction

Function BlockToString(Block)
	If TypeOf(Block) = Type("String") Then
		Return Block;
	EndIf;
	
	RowsCollection = BlockToStringsCollection(Block);
	
	Result = StrConcat(RowsCollection, Chars.LF);
	Return Result;
EndFunction

// Parameters:
//  Block - See NewBlock
// 
// Returns:
//  Array of See NewBlock
//
Function BlockToStringsCollection(Val Block)
	
	RowsCollection = New Array;
	
	If StrLen(Block.LongDesc) > 0 Then
		RowsCollection.Add(Block.LongDesc);
	EndIf;
	
	If StrLen(Block.PreprocessorInstruction) > 0 Then
		RowsCollection.Add(Block.PreprocessorInstruction);
	EndIf;
	
	If StrLen(Block.Title) > 0 Then
		RowsCollection.Add(Block.Title);
	EndIf;
	
	For Each ContentBlock In Block.Content Do
		RowsCollection.Add(BlockToString(ContentBlock));
	EndDo;
	
	If StrLen(Block.Footer) > 0 Then
		RowsCollection.Add(Block.Footer);
	EndIf;
	
	Return RowsCollection;

EndFunction

// Returns:
//  Structure:
//   * Parent - Undefined
//              - See NewBlock
//   * Title - String
//   * LongDesc - String
//   * Footer - String
//   * Content - Array
//
Function NewBlock(Parent = Undefined, Title = "", LongDesc = "")
	Result = New Structure;
	Result.Insert("LongDesc", LongDesc);
	Result.Insert("PreprocessorInstruction", "");
	Result.Insert("Title", Title);
	Result.Insert("Content", New Array);
	Result.Insert("Footer", "");
	
	Result.Insert("Parent", Parent);
	Return Result;
EndFunction

Function FindBlock(CollectionBlocks, Title, SearchSubordinateItems = True)
	Result = Undefined;
	
	// Search in the upper level.
	For Each Item In CollectionBlocks Do
		If TypeOf(Item) = Type("String") Then
			Continue;
		EndIf;
		If StrStartsWith(TrimL(Item.Title), Title) Then
			Return Item;
		EndIf;
		If Result <> Undefined Then
			Break;
		EndIf;
	EndDo;
	
	// Search in the lower level.
	If Result = Undefined And SearchSubordinateItems Then
		For Each Item In CollectionBlocks Do
			If TypeOf(Item) = Type("String") Then
				Continue;
			EndIf;
			Result = FindBlock(Item.Content, Title);
			If Result <> Undefined Then
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
EndFunction

Function FindBlocks(CollectionBlocks, Val Headers)
	
	If TypeOf(Headers) = Type("String") Then
		Headers = CommonClientServer.ValueInArray(Headers);
	EndIf;
	
	Result = New Array;
	
	For Each Item In CollectionBlocks Do
		If TypeOf(Item) = Type("String") Then
			Continue;
		EndIf;
		For Each Title In Headers Do
			If StrStartsWith(TrimL(Item.Title), Title) Then
				Result.Add(Item);
				Break;
			EndIf;
		EndDo;
		BlocksFound = FindBlocks(Item.Content, Headers);
		CommonClientServer.SupplementArray(Result, BlocksFound);
	EndDo;
	
	Return Result;
	
EndFunction

Function IsTitleContinuation(Title, String)
	Return (StrStartsWith(Title, "Function") Or StrStartsWith(Title, "Procedure"))
		And StrFind(Title, ")") = 0
		Or StrStartsWith(TrimL(Title), "Var") And StrFind(Title, ";") = 0;
EndFunction

Function IsBlockHeader(Val String, BlocksTypes)
	String = TrimAll(String);
	
	For Each BlockKind In BlocksTypes Do
		If StrStartsWith(String, BlockKind.Key) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
EndFunction

Function IsBlockFooter(Val String, Block, BlocksTypes)
	String = TrimL(String);
	BlockHeader = TrimL(Block.Title);
	
	For Each BlockKind In BlocksTypes Do
		If BlockKind.Value = Undefined Then
			Continue;
		EndIf;
			
		If StrStartsWith(String, BlockKind.Value) Then
			If StrStartsWith(BlockHeader, BlockKind.Key) Then
				Return True;
			Else
				// This footer is from another code block. Check it with the parent blocks.
				CurrentBlock = Block;
				While CurrentBlock <> Undefined And Not StrStartsWith(TrimL(CurrentBlock.Title), BlockKind.Key) Do
					CurrentBlock = CurrentBlock.Parent;
				EndDo;
				If CurrentBlock = Undefined Then
					// This is a footer of a block that has no beginning.
					Return False;
				Else
					// Move error block content to the parent block.
					For Each Item In Block.Content Do
						CurrentBlock.Content.Add(Item);
					EndDo;
					Block.Content = New Array;
					
					// Change the current block to the parent block.
					Block = CurrentBlock; 
					Return True;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	Return False;
EndFunction

Function BlocksTypes()
	Result = New Map;
	Result.Insert("#If", "#EndIf");
	Result.Insert("Function", "EndFunction");
	Result.Insert("Procedure", "EndProcedure");
	Result.Insert(AreaKeyword(), "#EndRegion");
	Result.Insert("// _Demo begin", "// _Demo end");
	Result.Insert("// StandardSubsystems.", "// End StandardSubsystems.");
	Result.Insert("Var ", Undefined);
	Return Result;
EndFunction

Function AreaKeyword()
	Return "#Region";
EndFunction

Procedure PutDescriptionLinesToContent(Content, LongDesc)
	If LongDesc.Count() > 0 Then
		For Each DetailsString In LongDesc Do
			Content.Add(DetailsString);
		EndDo;
		LongDesc.Clear();
	EndIf;
EndProcedure

Function CommonModule(MetadataObject)
	FullModuleName = PathToSharedModuleFile(MetadataObject);
	Return ModuleDetails(FullModuleName);
EndFunction

Function ManagerModule(MetadataObject)
	FullModuleName = ObjectManagerModuleFilePath(MetadataObject);
	Return ModuleDetails(FullModuleName);
EndFunction

Function ObjectModule(MetadataObject)
	FullModuleName = PathToObjectModuleFile(MetadataObject);
	Return ModuleDetails(FullModuleName);
EndFunction

Function FormModule(MetadataObjectForm)
	FullModuleName = FormModuleFilePath(MetadataObjectForm);
	Return ModuleDetails(FullModuleName);
EndFunction

Function CommandModule(MetadataObjectCommand)
	FullModuleName = PathToCommandModuleFile(MetadataObjectCommand);
	Return ModuleDetails(FullModuleName);
EndFunction

Function ModuleDetails(FullModuleName)
	Result = New Structure;
	Result.Insert("FullModuleName", FullModuleName);
	Result.Insert("ModuleText", ReadModuleText(FullModuleName));
	Result.Insert("Structure", Undefined);
	Return Result;
EndFunction

Procedure ReadModuleStructure(Module)
	If Not ValueIsFilled(Module.Structure) Then
		Module.Structure = LineToBlock(Module.ModuleText);
	EndIf;
EndProcedure

Function ReadModuleText(FullModuleName)
	If Not FileExists(FullModuleName) Then
		Return "";
	EndIf;
	TextReader = New TextReader(FullModuleName, TextEncoding.UTF8);
	ModuleText = TextReader.Read();
	TextReader.Close();
	Return ModuleText;
EndFunction

#EndRegion

Procedure AccessManagement_CheckPredefinedModulesUsage(MetadataObject, Module, ErrorTemplate, MetadataObjectName)
	
	ChecksList = New ValueList;
	ChecksList.Add("Catalog.AccessGroupProfiles.Administrator", "AccessManagement.ProfileAdministrator()");
	ChecksList.Add("Catalogs.AccessGroupProfiles.Administrator", "AccessManagement.ProfileAdministrator()");
	ChecksList.Add("Catalog.AccessGroups.Administrators", "AccessManagement.AdministratorsAccessGroup()");
	ChecksList.Add("Catalogs.AccessGroups.Administrators", "AccessManagement.AdministratorsAccessGroup()");
	
	ErrorTitle = NStr("ru = 'Прямое обращение к предопределенному элементу';
							|en = 'Direct access to a predefined item';");
	For Each CurCheck In ChecksList Do
		OccurrencesOfString = OccurrencesOfString(Module.ModuleText, CurCheck.Value, True);
		If Not ValueIsFilled(OccurrencesOfString) Then
			Continue;
		EndIf;
		AddError(MetadataObject, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			MetadataObjectName,
			CurCheck.Value,
			CurCheck.Presentation,
			StrConcat(OccurrencesOfString, Chars.LF)));
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region OtherProceduresAndFunctions_

Function IsException(LibrarySubsystem, MetadataObject, BriefErrorDetails, DetailedErrorDetails)
	
	If ExceptionsTable = Undefined Then
		Return False;
	EndIf;
	
	If TypeOf(MetadataObject) = Type("MetadataObject") Then
		FullName = MetadataObject.FullName();
	Else
		FullName = MetadataObject;
	EndIf;
	
	If TypeOf(LibrarySubsystem) = Type("MetadataObject") Then
		Subsystem = LibrarySubsystem.Name;
	Else
		Subsystem = MetadataObject;
	EndIf;
	
	SearchParameters = New Structure;
	SearchParameters.Insert("Subsystem", Subsystem);
	SearchParameters.Insert("ConfigurationObject", FullName);
	SearchParameters.Insert("BriefErrorDetails", BriefErrorDetails);
	SearchParameters.Insert("DetailedErrorDetails", DetailedErrorDetails);
	
	Return (ExceptionsTable.FindRows(SearchParameters).Count() > 0);
	
EndFunction

Procedure InitializeExceptionTable()
	
	ExceptionsTable = New ValueTable;
	ExceptionsTable.Columns.Add("Subsystem");
	ExceptionsTable.Columns.Add("ConfigurationObject");
	ExceptionsTable.Columns.Add("BriefErrorDetails");
	ExceptionsTable.Columns.Add("DetailedErrorDetails");
	
EndProcedure

Function UserSettingItem(UserSettings, TagName)
	
	If TypeOf(UserSettings) <> Type("DataCompositionUserSettings") Then 
		Return Undefined;
	EndIf;
	
	RequiredElement = New DataCompositionParameter(TagName);
	
	For Each Item In UserSettings.Items Do 
		
		If TypeOf(Item) = Type("DataCompositionSettingsParameterValue")
			And Item.Parameter = RequiredElement Then 
			
			Return Item;
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

Procedure FillInPredefined(ObjectsWithAdditionalProperties, PredefinedItemName, AcceptablePrefixes)
	
	SetsMetadata = Metadata.Catalogs["AdditionalAttributesAndInfoSets"];
	
	SeparatorPosition = StrFind(PredefinedItemName, "_");
	ObjectName         = Mid(PredefinedItemName, SeparatorPosition + 1);
	If StrStartsWith(ObjectName, "Delete") Or StrStartsWith(PredefinedItemName, "Delete") Then
		Return;
	EndIf;
	
	MetadataCollection = Undefined;
	For Each ValidPrefix In AcceptablePrefixes Do
		If StrStartsWith(PredefinedItemName, ValidPrefix.Key) Then
			PrefixLength = StrLen(ValidPrefix.Key) + 2;
			MetadataCollection = ValidPrefix.Value;
			Break;
		EndIf;
	EndDo;
	
	If MetadataCollection = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Имя предопределенного набора свойств должно начинаться
			|с наименования ссылочного типа (""Справочник"", ""Документ"" и т.д). Текущее имя ""%1""';
			|en = 'Name of predefined property set must start
			| with the description of reference type (""Catalog"", ""Document"" and so on). Current name is ""%1""';"), PredefinedItemName);
		AddError(SetsMetadata, NStr("ru = 'Некорректное имя предопределенного набора свойств';
												|en = 'Incorrect name of the predefined property set';"), ErrorText);
		Return;
	EndIf;
	
	OwnerName = Mid(PredefinedItemName, PrefixLength);
	OwnerMetadata = MetadataCollection.Find(OwnerName);
	If OwnerMetadata = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Для предопределенного набора свойств %1 отсутствует объект метаданных %2';
																					|en = 'Metadata object %2 is missing for the predefined set of properties %1';"),
			PredefinedItemName, OwnerName);
		AddError(SetsMetadata, NStr("ru = 'Отсутствует объект метаданных';
												|en = 'Metadata object is missing';"), ErrorText);
	Else
		ObjectsWithAdditionalProperties.Add(OwnerMetadata);
	EndIf;
	
EndProcedure

// Returns:
//  ValueTable:
//     * LongDesc - String
//     * AllowedTypes - String
//     * Content - Array of MetadataObject
//
Function TypesTable()
	
	TypesTable = New ValueTable;
	TypesTable.Columns.Add("LongDesc");
	TypesTable.Columns.Add("AllowedTypes");
	TypesTable.Columns.Add("Content");
	
	Return TypesTable;
	
EndFunction

Function NewTypeTableRow(LongDesc, AllowedTypes, Content)
	
	TypesTable = TypesTable();
	
	NewRow = TypesTable.Add();
	NewRow.LongDesc = LongDesc;
	NewRow.AllowedTypes = AllowedTypes;
	NewRow.Content = Content;
	
	Return TypesTable;
	
EndFunction

Function CompareTypesPossible(MetadataObject, TypesToCompare)
	
	If IsBlankString(TypesToCompare) Then
		Return True;
	ElsIf TypesToCompare = "EverythingExceptDocuments" Then
		Return Not Metadata.Documents.Contains(MetadataObject);
	Else
		BaseTypeName = Common.BaseTypeNameByMetadataObject(MetadataObject);
		Return StrOccurrenceCount(TypesToCompare, BaseTypeName) > 0;
	EndIf;
	
EndFunction

Function MetadataObjectInConfigurationLanguageKindName()
	Result = New Structure;
	
	Result.Insert("AccountingRegister", "AccountingRegister");
	Result.Insert("AccumulationRegister", "AccumulationRegister");
	Result.Insert("BusinessProcess", "BusinessProcess");
	Result.Insert("CalculationRegister", "CalculationRegister");
	Result.Insert("Catalog", "Catalog");
	Result.Insert("ChartOfAccounts", "ChartOfAccounts");
	Result.Insert("ChartOfCalculationTypes", "ChartOfCalculationTypes");
	Result.Insert("ChartOfCharacteristicTypes", "ChartOfCharacteristicTypes");
	Result.Insert("CommandGroup", "CommandGroup");
	Result.Insert("CommonAttribute", "CommonAttribute");
	Result.Insert("CommonCommand", "CommonCommand");
	Result.Insert("CommonForm", "CommonForm");
	Result.Insert("CommonModule", "CommonModule");
	Result.Insert("CommonPicture", "CommonPicture");
	Result.Insert("CommonTemplate", "CommonTemplate");
	Result.Insert("Configuration", "Configuration");
	Result.Insert("Constant", "Constant");
	Result.Insert("DataProcessor", "DataProcessor");
	Result.Insert("DefinedType", "DefinedType");
	Result.Insert("Document", "Document");
	Result.Insert("DocumentJournal", "DocumentJournal");
	Result.Insert("DocumentNumerator", "DocumentNumerator");
	Result.Insert("Enum", "Enum");
	Result.Insert("EventSubscription", "EventSubscription");
	Result.Insert("ExchangePlan", "ExchangePlan");
	Result.Insert("FilterCriterion", "FilterCriterion");
	Result.Insert("FunctionalOption", "FunctionalOption");
	Result.Insert("FunctionalOptionsParameter", "FunctionalOptionsParameter");
	Result.Insert("InformationRegister", "InformationRegister");
	Result.Insert("Language", "Language");
	Result.Insert("Report", "Report");
	Result.Insert("Role", "Role");
	Result.Insert("ScheduledJob", "ScheduledJob");
	Result.Insert("Sequence", "Sequence");
	Result.Insert("SessionParameter", "SessionParameter");
	Result.Insert("SettingsStorage", "SettingsStorage");
	Result.Insert("Style", "Style");
	Result.Insert("StyleItem", "StyleItem");
	Result.Insert("Subsystem", "Subsystem");
	Result.Insert("Task", "Task");
	Result.Insert("WebService", "WebService");
	Result.Insert("WSReference", "WSReference");
	Result.Insert("XDTOPackage", "XDTOPackage");
	
	Return Result;
EndFunction

Function ObjectInFileUploadKindName()
	Result = New Structure;
	
	Result.Insert("AccountingRegister", "AccountingRegisters");
	Result.Insert("AccumulationRegister", "AccumulationRegisters");
	Result.Insert("BusinessProcess", "BusinessProcesses");
	Result.Insert("CalculationRegister", "CalculationRegisters");
	Result.Insert("Catalog", "Catalogs");
	Result.Insert("ChartOfAccounts", "ChartsOfAccounts");
	Result.Insert("ChartOfCalculationTypes", "ChartsOfCalculationTypes");
	Result.Insert("ChartOfCharacteristicTypes", "ChartsOfCharacteristicTypes");
	Result.Insert("CommandGroup", "CommandGroups");
	Result.Insert("CommonAttribute", "CommonAttributes");
	Result.Insert("CommonCommand", "CommonCommands");
	Result.Insert("CommonForm", "CommonForms");
	Result.Insert("CommonModule", "CommonModules");
	Result.Insert("CommonPicture", "CommonPictures");
	Result.Insert("CommonTemplate", "CommonTemplates");
	Result.Insert("Constant", "Constants");
	Result.Insert("DataProcessor", "DataProcessors");
	Result.Insert("DefinedType", "DefinedTypes");
	Result.Insert("Document", "Documents");
	Result.Insert("DocumentJournal", "DocumentJournals");
	Result.Insert("DocumentNumerator", "DocumentNumerator");
	Result.Insert("Enum", "Enums");
	Result.Insert("EventSubscription", "EventSubscriptions");
	Result.Insert("ExchangePlan", "ExchangePlans");
	Result.Insert("FilterCriterion", "FilterCriteria");
	Result.Insert("FunctionalOption", "FunctionalOptions");
	Result.Insert("FunctionalOptionsParameter", "FunctionalOptionsParameters");
	Result.Insert("InformationRegister", "InformationRegisters");
	Result.Insert("Language", "Languages");
	Result.Insert("Report", "Reports");
	Result.Insert("Role", "Roles");
	Result.Insert("ScheduledJob", "ScheduledJobs");
	Result.Insert("Sequence", "Sequences");
	Result.Insert("SessionParameter", "SessionParameters");
	Result.Insert("SettingsStorage", "SettingsStorages");
	Result.Insert("Style", "Style");
	Result.Insert("StyleItem", "StyleItems");
	Result.Insert("Subsystem", "Subsystems");
	Result.Insert("Task", "Tasks");
	Result.Insert("WebService", "WebServices");
	Result.Insert("WSReference", "WSReference");
	Result.Insert("XDTOPackage", "XDTOPackages");
	Result.Insert("HTTPService", "HTTPServices");
	
	Return Result;
EndFunction

Function MetadataObjectNamesMap()
	
	Result = New Structure;
	
	// Metadata object kinds (plural form).
	Result.Insert("AccountingRegisters", "AccountingRegister");
	Result.Insert("AccumulationRegisters", "AccumulationRegister");
	Result.Insert("BusinessProcesses", "BusinessProcess");
	Result.Insert("CalculationRegisters", "CalculationRegister");
	Result.Insert("Catalogs", "Catalog");
	Result.Insert("ChartsOfAccounts", "ChartOfAccounts");
	Result.Insert("ChartsOfCalculationTypes", "ChartOfCalculationTypes");
	Result.Insert("ChartsOfCharacteristicTypes", "ChartOfCharacteristicTypes");
	Result.Insert("CommandGroups", "CommandGroup");
	Result.Insert("CommonAttributes", "CommonAttribute");
	Result.Insert("CommonCommands", "CommonCommand");
	Result.Insert("CommonForms", "CommonForm");
	Result.Insert("CommonModules", "CommonModule");
	Result.Insert("CommonPictures", "CommonPicture");
	Result.Insert("CommonTemplates", "CommonTemplate");
	Result.Insert("Constants", "Constant");
	Result.Insert("DataProcessors", "DataProcessor");
	Result.Insert("DefinedTypes", "DefinedType");
	Result.Insert("Documents", "Document");
	Result.Insert("DocumentJournals", "DocumentJournal");
	Result.Insert("DocumentNumerator", "DocumentNumerator");
	Result.Insert("Enums", "Enum");
	Result.Insert("EventSubscriptions", "EventSubscription");
	Result.Insert("ExchangePlans", "ExchangePlan");
	Result.Insert("FilterCriteria", "FilterCriterion");
	Result.Insert("FunctionalOptions", "FunctionalOption");
	Result.Insert("FunctionalOptionsParameters", "FunctionalOptionsParameter");
	Result.Insert("InformationRegisters", "InformationRegister");
	Result.Insert("Languages", "Language");
	Result.Insert("Reports", "Report");
	Result.Insert("Roles", "Role");
	Result.Insert("ScheduledJobs", "ScheduledJob");
	Result.Insert("Sequences", "Sequence");
	Result.Insert("SessionParameters", "SessionParameter");
	Result.Insert("SettingsStorages", "SettingsStorage");
	Result.Insert("Style", "Style");
	Result.Insert("StyleItems", "StyleItem");
	Result.Insert("Subsystems", "Subsystem");
	Result.Insert("Tasks", "Task");
	Result.Insert("WebServices", "WebService");
	Result.Insert("WSReference", "WSReference");
	Result.Insert("XDTOPackages", "XDTOPackage");
	
	// Types of nested metadata objects.
	Result.Insert("Module", "Module");
	Result.Insert("ManagerModule", "ManagerModule");
	Result.Insert("ObjectModule", "ObjectModule");
	Result.Insert("CommandModule", "CommandModule");
	Result.Insert("RecordSetModule", "RecordSetModule");
	Result.Insert("ValueManagerModule", "ValueManagerModule");
	
	Result.Insert("ExternalConnectionModule", "ExternalConnectionModule");
	Result.Insert("ManagedApplicationModule", "ManagedApplicationModule");
	Result.Insert("OrdinaryApplicationModule", "OrdinaryApplicationModule");
	Result.Insert("SessionModule", "SessionModule");
	
	Result.Insert("Help", "Help");
	Result.Insert("Form", "Form");
	Result.Insert("Flowchart", "Flowchart");
	Result.Insert("Picture", "Picture");
	Result.Insert("CommandInterface", "CommandInterface");
	
	Result.Insert("Template", "Template");
	Result.Insert("Command", "Command");
	Result.Insert("Aggregates", "Aggregates");
	Result.Insert("Recalculation", "Recalculation");
	Result.Insert("Predefined", "Predefined");
	Result.Insert("Content", "Content");
	Result.Insert("Rights", "Rights");
	Result.Insert("Schedule", "Schedule");
	
	// Types of nested metadata objects (plural form).
	Result.Insert("Module", "Module");
	Result.Insert("ManagerModule", "ManagerModule");
	Result.Insert("ObjectModule", "ObjectModule");
	Result.Insert("CommandModule", "CommandModule");
	Result.Insert("RecordSetModule", "RecordSetModule");
	Result.Insert("ValueManagerModule", "ValueManagerModule");
	
	Result.Insert("ExternalConnectionModule", "ExternalConnectionModule");
	Result.Insert("ManagedApplicationModule", "ManagedApplicationModule");
	Result.Insert("OrdinaryApplicationModule", "OrdinaryApplicationModule");
	Result.Insert("SessionModule", "SessionModule");
	
	Result.Insert("Help", "Help");
	Result.Insert("Forms", "Form");
	Result.Insert("Flowchart", "Flowchart");
	Result.Insert("Picture", "Picture");
	Result.Insert("CommandInterface", "CommandInterface");
	
	Result.Insert("Templates", "Template");
	Result.Insert("Commands", "Command");
	Result.Insert("Aggregates", "Aggregates");
	Result.Insert("Recalculations", "Recalculation");
	Result.Insert("Predefined", "Predefined");
	Result.Insert("Content", "Content");
	Result.Insert("Rights", "Rights");
	Result.Insert("Schedule", "Schedule");
	
	// Types of nested metadata objects.
	Result.Insert("Module", "Module");
	Result.Insert("ManagerModule", "ManagerModule");
	Result.Insert("ObjectModule", "ObjectModule");
	Result.Insert("CommandModule", "CommandModule");
	Result.Insert("RecordSetModule", "RecordSetModule");
	Result.Insert("ValueManagerModule", "ValueManagerModule");
	
	Result.Insert("ExternalConnectionModule", "ExternalConnectionModule");
	Result.Insert("ManagedApplicationModule", "ManagedApplicationModule");
	Result.Insert("OrdinaryApplicationModule", "OrdinaryApplicationModule");
	Result.Insert("SessionModule", "SessionModule");
	
	Result.Insert("Help", "Help");
	Result.Insert("Form", "Form");
	Result.Insert("Flowchart", "Flowchart");
	Result.Insert("Picture", "Picture");
	Result.Insert("CommandInterface", "CommandInterface");
	
	Result.Insert("Template", "Template");
	Result.Insert("Command", "Command");
	Result.Insert("Aggregates", "Aggregates");
	Result.Insert("Recalculation", "Recalculation");
	Result.Insert("Predefined", "Predefined");
	Result.Insert("Content", "Content");
	Result.Insert("Rights", "Rights");
	Result.Insert("Schedule", "Schedule");
	
	// Rights.
	Result.Insert("InteractiveDelete", NStr("ru = 'Интерактивное удаление';
												|en = 'Delete interactively';"));
	Result.Insert("InteractiveDeletePredefinedData", NStr("ru = 'Интерактивное удаление предопределенных';
																|en = 'Delete predefined items interactively';"));
	Result.Insert("InteractiveSetDeletionMarkPredefinedData", NStr("ru = 'Интерактивная пометка на удаление предопределенных';
																		|en = 'Mark predefined items for deletion interactively';"));
	Result.Insert("InteractiveClearDeletionMarkPredefinedData", NStr("ru = 'Интерактивное снятие пометки удаления предопределенных';
																			|en = 'Unmark predefined items for deletion interactively';"));
	Result.Insert("InteractiveDeleteMarkedPredefinedData", NStr("ru = 'Интерактивное удаление помеченных предопределенных';
																	|en = 'Delete predefined items marked for deletion interactively';"));
	
	Return Result;
	
EndFunction

// Returns:
//   Map of KeyAndValue:
//     * Key - String
//     * Value - Array of MetadataObjectSubsystem
//
Function MatchingObjects()
	Return New Map;
EndFunction

Function ProcedureOrFunctionText(Val NameOfAProcedureOrAFunction, ModuleText, IsFunction = Undefined)
	
	Return ProcedureOrFunctionDeclarationAndText(NameOfAProcedureOrAFunction, ModuleText, IsFunction).Text;
	
EndFunction

Function ProcedureOrFunctionDeclarationAndText(Val NameOfAProcedureOrAFunction, ModuleText, IsFunction = Undefined)
	
	If IsFunction = Undefined Then
		If StrStartsWith(NameOfAProcedureOrAFunction, "Function") Then
			IsFunction = True;
		ElsIf StrStartsWith(NameOfAProcedureOrAFunction, "Procedure") Then
			IsFunction = False;
		EndIf;
	Else
		NameOfAProcedureOrAFunction = ?(IsFunction, "Function", "Procedure") + " " + NameOfAProcedureOrAFunction;
	EndIf;
	
	If Not StrEndsWith(NameOfAProcedureOrAFunction, "(") Then
		NameOfAProcedureOrAFunction = NameOfAProcedureOrAFunction + "(";
	EndIf;
	
	If IsFunction = Undefined Then
		StartPosition = StrFindNotCommentAndNotString(ModuleText, "Function " + NameOfAProcedureOrAFunction);
		IsFunction = True;
		If StartPosition = 0 Then
			StartPosition = StrFindNotCommentAndNotString(ModuleText, "Procedure " + NameOfAProcedureOrAFunction);
			IsFunction = False;
		EndIf;
	Else
		StartPosition = StrFindNotCommentAndNotString(ModuleText, NameOfAProcedureOrAFunction);
	EndIf;
	
	Result = New Structure;
	Result.Insert("Declare", "");
	Result.Insert("Text", "");
	If StartPosition = 0 Then
		Return Result;
	EndIf;
	
	EndingRow = ?(IsFunction, "EndFunction", "EndProcedure");
	EndingPosition = StrFindNotCommentAndNotString(ModuleText, EndingRow, StartPosition);
	
	DeclarationText = Mid(ModuleText, StartPosition, EndingPosition - StartPosition);
	ClosingParenthesis = StrFindNotCommentAndNotString(DeclarationText, ")");
	Linefeed = StrFind(DeclarationText, Chars.LF,, ClosingParenthesis);
	
	Result.Declare = Mid(DeclarationText, 1, Linefeed);
	Result.Text = Mid(DeclarationText, Linefeed + 1);
	Return Result;
	
EndFunction

Function StrFindNotCommentAndNotString(String, SearchSubstring, Val StartPosition = 1, GoForward = True)
	Direction = ?(GoForward, SearchDirection.FromBegin, SearchDirection.FromEnd);
	While True Do
		FirstCharacterPosition = StrFind(String, SearchSubstring, Direction, StartPosition);
		If FirstCharacterPosition = 0 Then
			Return 0;
		EndIf;
		CarriageReturnPosition = StrFind(String, Chars.LF, SearchDirection.FromEnd, FirstCharacterPosition);
		If CarriageReturnPosition = FirstCharacterPosition - 1 Then
			Return FirstCharacterPosition;
		EndIf;
		LineBetweenCarriageReturnAndSubstring = TrimAll(Mid(String, CarriageReturnPosition, FirstCharacterPosition - CarriageReturnPosition));
		If LineBetweenCarriageReturnAndSubstring = "" Then
			Return FirstCharacterPosition;
		EndIf;
		QuotesEvenNumber = (StrOccurrenceCount(LineBetweenCarriageReturnAndSubstring, """")%2 = 0);
		IsLineContinuation = StrStartsWith(LineBetweenCarriageReturnAndSubstring, "|");
		If QuotesEvenNumber <> IsLineContinuation // All quotation marks are closed.
			And StrFind(LineBetweenCarriageReturnAndSubstring, "//") = 0 Then // No open comment.
			Return FirstCharacterPosition;
		EndIf;
		StartPosition = FirstCharacterPosition + 1;
	EndDo;
	
	Return 0;
EndFunction

Procedure UploadConfigurationToXML(ConfigurationUploadDirectory)
	
	If Not IsBlankString(ConfigurationUploadDirectory) Then
		Directory = New File(ConfigurationUploadDirectory);
		If Not Directory.Exists() Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Указанный каталог выгрузки ""%1"" не существует.';
																							|en = 'Specified ""%1"" export directory does not exist.';"), ConfigurationUploadDirectory);
		EndIf;
		SetConfigurationUploadDirectory(ConfigurationUploadDirectory);
		Return;
	EndIf;
	
	CurrentIBUser = InfoBaseUsers.CurrentUser();
	If Not CurrentIBUser.StandardAuthentication And Not Common.FileInfobase() Then
		Raise NStr("ru = 'В клиент-серверном режиме работы проверка внедрения возможна
			|только для пользователя с аутентификацией средствами 1С.';
			|en = 'In client/server operation mode, integration check is possible
			|only for a user with authentication using 1C.';");
	EndIf;
	
	If InfoBaseUsers.CurrentUser().PasswordIsSet Then
		Raise NStr("ru = 'Проверка внедрения возможна только для пользователя без пароля.';
								|en = 'Integration check is available only for a user without password.';");
	EndIf;
	
	EDTConfiguration  = False;
	DumpDirectory  = GetTempFileName("SSLImplementationCheck");
	DumpDirectory  = CommonClientServer.AddLastPathSeparator(DumpDirectory);
	BinDir = BinDir();
	CreateDirectory(DumpDirectory);
	
	ConnectionString = InfoBaseConnectionString();
	If DesignerIsOpen() Then
		If Common.FileInfobase() Then
			InfobaseDirectory = StringFunctionsClientServer.ParametersFromString(ConnectionString).file;
			InfobaseDirectory = CommonClientServer.AddLastPathSeparator(InfobaseDirectory);
			FileCopy(InfobaseDirectory + "1Cv8.1CD", DumpDirectory + "1Cv8.1CD");
			ConnectionString = StringFunctionsClientServer.SubstituteParametersToString("File=""%1"";", DumpDirectory);
		Else
			Raise NStr("ru = 'Для проверки внедрения закройте конфигуратор.';
									|en = 'To check integration, close Designer.';");
		EndIf;
	EndIf;
	
	MessagesFileName = DumpDirectory + "UploadConfigurationToFilesMessages.txt";
	
	StartupCommand = New Array;
	If Common.IsWindowsServer() Then
		StartupCommand.Add(BinDir + "1cv8.exe");
	Else
		StartupCommand.Add(BinDir + "1cv8");
	EndIf;
	StartupCommand.Add("DESIGNER");
	StartupCommand.Add("/IBConnectionString");
	StartupCommand.Add(ConnectionString);
	If ValueIsFilled(UserName()) And CurrentIBUser.StandardAuthentication Then
		StartupCommand.Add("/N");
		StartupCommand.Add(UserName());
		If Common.IsWindowsServer() Then
			StartupCommand.Add("/P");
			StartupCommand.Add();
		EndIf;
	EndIf;
	StartupCommand.Add("/DumpConfigToFiles");
	StartupCommand.Add(DumpDirectory);
	StartupCommand.Add("/Out");
	StartupCommand.Add(MessagesFileName);
	StartupCommand.Add("/DisableStartupMessages");
	StartupCommand.Add("/DisableStartupDialogs");
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	ApplicationStartupParameters.GetOutputStream = True;
	ApplicationStartupParameters.GetErrorStream = True;
	
	Result = FileSystem.StartApplication(StartupCommand, ApplicationStartupParameters);
	
	If Result.ReturnCode <> 0 Then
		
		Messages = New Array;
		
		If ValueIsFilled(Result.ErrorStream) Then
			Messages.Add(Result.ErrorStream);
		EndIf;
		If ValueIsFilled(Result.OutputStream) Then
			Messages.Add(Result.OutputStream);
		EndIf;
		
		Try
			
			CheckIfFileExists = New File(MessagesFileName);
			If CheckIfFileExists.Exists() Then
				
				TextReader = New TextReader(MessagesFileName, TextEncoding.UTF8);
				Messages.Add(TextReader.Read());
				TextReader.Close();
				
			EndIf; 
			
			If Messages.Count() = 0 Then
				Messages.Add(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Код возврата запуск системы 1С:Предприятие в режиме Конфигуратора: %1';
					|en = 'Return code at 1C:Enterprise startup in Designer mode: %1';"), Result.ReturnCode));
			EndIf;
			
		Except
			Messages.Add(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;
		
		ErrorTextTemplate = NStr("ru = '%1
		|Техническая информация. Код возврата при запуске системы «1С:Предприятие» в режиме Конфигуратора: %2
		|Строка запуска: %3';
		|en = '%1
		|Technical information. Return code at 1C:Enterprise startup in Designer mode: %2
		|Launch string: %3';");
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTextTemplate,
		StrConcat(Messages, Chars.LF), Result.ReturnCode, StrConcat(StartupCommand, " "));
		
		WriteLogEvent(NStr("ru = 'Проверка внедрения БСП';
										|en = 'SSL integration check';", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, ErrorText);
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось выполнить выгрузку конфигурации в файлы по причине:
		|%1';
		|en = 'Failed to import configuration to files due to:
		|%1';"), StrConcat(Messages, Chars.LF));
	EndIf;
	
EndProcedure

Procedure LoadConfigurationFromXML()
	
	If FilesToUpload.Count() = 0 Then
		Return;
	EndIf;
	
	FilesToUpload = CommonClientServer.CollapseArray(FilesToUpload);
	
	If DesignerIsOpen() Then
		MessageText = NStr("ru = 'Невозможно выполнить загрузку исправлений в конфигурацию т.к. открыт конфигуратор.';
								|en = 'Cannot import patches to configuration because Designer is open.';");
		Common.MessageToUser(MessageText);
		Return;
	EndIf;
	
	CurrentIBUser = InfoBaseUsers.CurrentUser();
	
	FileNameToUpload = DumpDirectory + "FilesToDownload.txt";
	FilesNames = StrConcat(FilesToUpload, Chars.LF);
	ListOfFiles = New TextDocument;
	ListOfFiles.SetText(FilesNames);
	ListOfFiles.Write(FileNameToUpload);
	
	MessagesFileName = DumpDirectory + "UploadConfigurationToFilesMessages.txt";
	BinDir = StandardSubsystemsServer.ClientParametersAtServer().Get("BinDir");
	
	StartupCommand = New Array;
	If Common.IsWindowsServer() Then
		StartupCommand.Add(BinDir + "1cv8.exe");
	Else
		StartupCommand.Add(BinDir + "1cv8");
	EndIf;
	StartupCommand.Add("DESIGNER");
	StartupCommand.Add("/IBConnectionString");
	StartupCommand.Add(InfoBaseConnectionString());
	If ValueIsFilled(UserName()) And CurrentIBUser.StandardAuthentication Then
		StartupCommand.Add("/N");
		StartupCommand.Add(UserName());
		If Common.IsWindowsServer() Then
			StartupCommand.Add("/P");
			StartupCommand.Add();
		EndIf;
	EndIf;
	StartupCommand.Add("/LoadConfigFromFiles");
	StartupCommand.Add(DumpDirectory);
	StartupCommand.Add("-listfile");
	StartupCommand.Add(FileNameToUpload);
	StartupCommand.Add("/Out");
	StartupCommand.Add(MessagesFileName);
	StartupCommand.Add("/DisableStartupMessages");
	StartupCommand.Add("/DisableStartupDialogs");
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	
	Result = FileSystem.StartApplication(StartupCommand, ApplicationStartupParameters);
	
	If Result.ReturnCode <> 0 Then
		Try
			Text = New TextDocument;
			Text.Read(MessagesFileName);
			Messages = Text.GetText();
			If IsBlankString(Messages) Then
				Messages = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Код возврата: %1';
						|en = 'Return code: %1';"), Result.ReturnCode);
			EndIf;
		Except
			Messages = "";
		EndTry;
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось выполнить загрузку конфигурации из файлов по причине:
				|%1';
				|en = 'Failed to export configuration from files due to:
				|%1';"), Messages);
	EndIf;
	
EndProcedure

Function CheckResult(CheckParameters)
	
	If CheckParameters = Undefined Then
		Return Undefined;
	EndIf;
	
	NonVerifiableConfigurationSubsystems = CheckParameters.NonVerifiableConfigurationSubsystems;
	
	ResultAsString = CheckParameters.ResultAsString;
	
	If ValueIsFilled(CheckParameters.VerificationFileExtension) Then
		VerificationFileExtension = CheckParameters.VerificationFileExtension;
		// The calling code deletes the temporary file.
		VerificationResultFileName = GetTempFileName(VerificationFileExtension);
	ElsIf ValueIsFilled(CheckParameters.FullPathToCheckFile) Then
		VerificationResultFileName = CheckParameters.FullPathToCheckFile;
		VerificationFileExtension = CommonClientServer.GetFileNameExtension(VerificationResultFileName);
	EndIf;
	
	If Lower(VerificationFileExtension) = "txt" Then
		TextDocument = New TextDocument;
		ErrorTemplate = NStr("ru = 'Объект: %1
		|Проверка: %2
		|Текст ошибки: %3';
		|en = 'Object: %1
		|Check: %2
		|Error text: %3';");
		For Each ImplementationError In CheckTable Do
			If IncludedInUnverifiedSubsystems(ImplementationError.MetadataObject) Then
				Continue;
			EndIf;
			
			TextDocument.AddLine(StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
			ImplementationError.MetadataObject, ImplementationError.BriefErrorDetails,
			ImplementationError.DetailedErrorDetails));
		EndDo;
		If ResultAsString Then
			ErrorText = TextDocument.GetText();
		Else
			TextDocument.Write(VerificationResultFileName);
		EndIf;
	ElsIf Lower(VerificationFileExtension) = "xml" Then
		XMLWriter = New XMLWriter;
		If ResultAsString Then
			XMLWriter.SetString("UTF-8");
		Else
			XMLWriter.OpenFile(VerificationResultFileName);
		EndIf;
		XMLWriter.WriteXMLDeclaration();
		XMLWriter.WriteStartElement("ImplementationCheck");
		For Each ImplementationError In CheckTable Do
			If IncludedInUnverifiedSubsystems(ImplementationError.MetadataObject) Then
				Continue;
			EndIf;
			
			XMLWriter.WriteStartElement("Error");
			XMLWriter.WriteStartElement("SSLSubsystem");
			XMLWriter.WriteText(ImplementationError.SSLSubsystem);
			XMLWriter.WriteEndElement();
			XMLWriter.WriteStartElement("MetadataObject");
			XMLWriter.WriteText(ImplementationError.MetadataObject);
			XMLWriter.WriteEndElement();
			XMLWriter.WriteStartElement("Validation");
			XMLWriter.WriteText(ImplementationError.BriefErrorDetails);
			XMLWriter.WriteEndElement();
			XMLWriter.WriteStartElement("ErrorText");
			XMLWriter.WriteText(ImplementationError.DetailedErrorDetails);
			XMLWriter.WriteEndElement();
			XMLWriter.WriteEndElement();
		EndDo;
		XMLWriter.WriteEndElement();
		ErrorText = XMLWriter.Close();
	EndIf;
	Return ?(ResultAsString, ErrorText, VerificationResultFileName);
	
EndFunction

Procedure FillInVerificationData(CheckParameters)
	
	TermsMap = MetadataObjectNamesMap();
	MetadataObjectInConfigurationLanguageKindName = MetadataObjectInConfigurationLanguageKindName();
	ObjectInFileUploadKindName               = ObjectInFileUploadKindName();
	
	SubsystemsTree = New ValueTree;
	SubsystemsTree.Columns.Add("Subsystem");
	FillInSubsystemTree(Metadata.Subsystems, SubsystemsTree.Rows);
	
	MatchingObjects = MatchingObjects();
	SSLSubsystemObjects = New Array;
	
	For Each Subsystem In Metadata.Subsystems Do
		FillInSubsystemObjects(Subsystem);
	EndDo;
	
	FilesToUpload = New Array;
	
	If CheckParameters <> Undefined And CheckParameters.CorrectErrors Then
		CorrectErrors = CheckParameters.CorrectErrors;
	Else
		CorrectErrors = ?(CorrectErrors = Undefined, False, CorrectErrors);
	EndIf;
	
	If CheckParameters <> Undefined Then
		If CheckParameters.FixedErrors.Count() = 0 Then
			FixedErrors = FixedErrors().UnloadValues();
		Else
			FixedErrors = CheckParameters.FixedErrors;
		EndIf;
	EndIf;
	
	InteractiveLaunch = CheckParameters <> Undefined And CheckParameters.InteractiveLaunch;
	
	If CheckParameters <> Undefined And CheckParameters.ExceptionsTable <> Undefined Then
		InitializeExceptionTable();
		For Each String In CheckParameters.ExceptionsTable Do
			FillPropertyValues(ExceptionsTable.Add(), String);
		EndDo;
	EndIf;
	
	CheckTable.Clear();
	
EndProcedure

Function DesignerIsOpen()
	
	For Each Session In GetInfoBaseSessions() Do
		If Upper(Session.ApplicationName) = Upper("Designer") Then // Designer.
			Return True;
		EndIf;
	EndDo;
	Return False;
	
EndFunction

Function TypeCompositionFromString(TypeRow)
	
	SourceMetadata = CalculationResult("Metadata." + TypeRow);
	MetadataArray = New Array;
	If TypeOf(SourceMetadata) = Type("TypeDescription") Then
		For Each Type In SourceMetadata.Types() Do
			MetadataObject = Metadata.FindByType(Type);
			If MetadataObject = Undefined Then
				MetadataArray.Add(Type);
			Else
				MetadataArray.Add(MetadataObject);
			EndIf;
		EndDo;
	Else
		For Each MetadataObject In SourceMetadata Do
			MetadataArray.Add(MetadataObject);
		EndDo;
	EndIf;
	
	Return MetadataArray;
	
EndFunction

Function MetadataObjectTypeView(Value)

	If TypeOf(Value) = Type("MetadataObject") Then
		Return Value.FullName();
	Else
		Return String(Value);
	EndIf;

EndFunction

Procedure ExcludeTypes(TypesToExclude, MetadataArray)
	
	If Not IsBlankString(TypesToExclude) Then
		
		ArrayOfExcludedTypes = StrSplit(TypesToExclude, ",",);
		
		For Each IsExcludableType In ArrayOfExcludedTypes Do
			
			MetadataObject = Common.MetadataObjectByFullName(IsExcludableType);
			
			ElementIndex = MetadataArray.Find(MetadataObject);
			
			While ElementIndex <> Undefined Do
				
				MetadataArray.Delete(ElementIndex);
				ElementIndex = MetadataArray.Find(MetadataObject);
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure FillInSubsystemTree(Subsystems, SubsystemsTree)
	
	For Each Subsystem In Subsystems Do
		NewRow = SubsystemsTree.Add();
		NewRow.Subsystem = Subsystem;
		If Subsystem.Subsystems.Count() > 0 Then
			FillInSubsystemTree(Subsystem.Subsystems, NewRow.Rows);
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillInSubsystemObjects(Subsystem, IsSSLSubsystem = Undefined)
	
	If IsSSLSubsystem = Undefined Then
		IsSSLSubsystem = (Subsystem = Metadata.Subsystems.StandardSubsystems);
	EndIf;

	For Each Object In Subsystem.Content Do
		TreeRow = SubsystemsTree.Rows.Find(Subsystem, "Subsystem", True);
		ConfigurationSubsystem = TopLevelSubsystem(TreeRow);
		SubsystemData = New Structure("Name, Presentation", ConfigurationSubsystem.Name, ConfigurationSubsystem.Presentation());
		ObjectPresentation = MetadataObjectTypeView(Object);
		ObjectSubsystems = MatchingObjects.Get(ObjectPresentation);
		If ObjectSubsystems = Undefined Then
			ObjectSubsystems = New Array;
		EndIf;
		ObjectSubsystems.Add(SubsystemData);
		MatchingObjects.Insert(ObjectPresentation, ObjectSubsystems);
		If IsSSLSubsystem
			And SSLSubsystemObjects.Find(Object) = Undefined Then
			SSLSubsystemObjects.Add(Object);
		EndIf;
	EndDo;
	
	If IsSSLSubsystem
		And SSLSubsystemObjects.Find(Subsystem) = Undefined Then
		SSLSubsystemObjects.Add(Subsystem);
	EndIf;
	
	For Each SubordinateSubsystem In Subsystem.Subsystems Do
		If SubordinateSubsystem.Name = "DataExchange"
			Or SubordinateSubsystem.Name = "DataExchangeSaaS" Then
			FillInSubsystemObjects(SubordinateSubsystem, False);
		Else
			FillInSubsystemObjects(SubordinateSubsystem, IsSSLSubsystem);
		EndIf;
	EndDo;
	
EndProcedure

Function TopLevelSubsystem(TreeRow)
	
	If TreeRow = Undefined Then
		Return Undefined;
	EndIf;
	
	If ValueIsFilled(TreeRow.Parent) Then
		Return TopLevelSubsystem(TreeRow.Parent);
	Else
		Return TreeRow.Subsystem;
	EndIf;
	
EndFunction

// Parameters:
//  VerificationParametersIncoming - See CheckingCodeInsertionParameters.
//
Procedure CheckForCodeInsertionForArray(VerificationParametersIncoming)
	
	VerificationParametersOutgoing = CheckingCodeInsertionParameters();
	FillPropertyValues(VerificationParametersOutgoing, VerificationParametersIncoming);
	
	CheckObjectForm = VerificationParametersIncoming.ModuleType = "DefaultObjectForm";
	CheckListForm = VerificationParametersIncoming.ModuleType = "DefaultListForm";
	
	If CheckObjectForm Then
		CheckedForms = New Array;
		For Each MetadataObject In VerificationParametersIncoming.DataToCheck1 Do // MetadataObject
			If CheckObjectForm Then
				NotRequireInsertsForms = NotRequireInsertsForObjectFormForms(MetadataObject);
			Else // CheckListForm
				NotRequireInsertsForms = NotRequireInsertsForListFormForms(MetadataObject);
			EndIf;
			
			For Each Form In MetadataObject.Forms Do // MetadataObjectForm
				If NotRequireInsertsForms.Find(Form) <> Undefined Or StrFind(Form.Name, "SelfService") <> 0 Then
					Continue;
				EndIf;
				
				MainPropertyType = MainFormPropertyType(Form);
				IsListForm = MainPropertyType = Type("DynamicList");
				
				If MainPropertyType = Undefined
					Or CheckObjectForm And IsListForm
					Or CheckListForm And Not IsListForm Then
					Continue;
				EndIf;
				
				FormMetadataObject = Metadata.FindByType(MainPropertyType);
				If IsListForm Then
					MainTableOfFormListName = MainTableOfFormListName(Form);
					If MainTableOfFormListName <> Undefined Then
						FormMetadataObject = Common.MetadataObjectByFullName(MainTableOfFormListName);
					EndIf;
				EndIf;
					
				If MetadataObject = FormMetadataObject Then
					CheckedForms.Add(Form);
				EndIf;
			EndDo;
		EndDo;
		
		VerificationParametersOutgoing.ModuleType = "FormModule";
		VerificationParametersIncoming.DataToCheck1 = CheckedForms;
	EndIf;
	
	For Each MetadataObject In VerificationParametersIncoming.DataToCheck1 Do
		VerificationParametersOutgoing.DataToCheck1 = MetadataObject;
		CheckForCodeInsertionForObject(VerificationParametersOutgoing);
	EndDo;
	
EndProcedure

// Parameters:
//  CheckParameters - See CheckingCodeInsertionParameters.
//
Procedure CheckForCodeInsertionForObject(CheckParameters)
	
	MetadataObject       = CheckParameters.DataToCheck1;
	ModuleType              = CheckParameters.ModuleType;
	ModuleText            = ModuleText(MetadataObject, ModuleType);
	CodeString             = CheckParameters.CodeString;
	NameOfAProcedureOrAFunction = CheckParameters.NameOfAProcedureOrAFunction;
	
	VerificationDetails = New Structure;
	VerificationDetails.Insert("AbsenceOfModuleIsError",     CheckParameters.AbsenceOfModuleIsError);
	VerificationDetails.Insert("AbsenceOfProcedureIsError",  CheckParameters.AbsenceOfProcedureIsError);
	VerificationDetails.Insert("ProcedurePresenceIsError", CheckParameters.ProcedurePresenceIsError);
	VerificationDetails.Insert("IsOptionalAlgorithm",             CheckParameters.IsOptionalAlgorithm);
	VerificationDetails.Insert("IsExportProcedure",              CheckParameters.IsExportProcedure);

	If TypeOf(CodeString) = Type("Array") Then
		For Each CallString In CodeString Do
			ModuleTextContainsProcedure(MetadataObject, ModuleText, ModuleType, CallString,
				NameOfAProcedureOrAFunction, VerificationDetails);
		EndDo;
		Return;
	EndIf;
	
	ModuleTextContainsProcedure(MetadataObject, ModuleText, ModuleType, CodeString,
		NameOfAProcedureOrAFunction, VerificationDetails);
	
EndProcedure

Procedure ModuleTextContainsProcedure(MetadataObject, ModuleText, Val ModuleType, CodeString, NameOfAProcedureOrAFunction, VerificationDetails)
	
	If TypeOf(CodeString) = Type("Array") Then
		CallString = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '""%1"" или ""%2""';
																					|en = '%1 or %2';"), CodeString[0], CodeString[1]);
	Else
		CallString = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '""%1""';
																					|en = '""%1""';"), CodeString);
	EndIf;
	
	RefinementErrors = "";
	If ModuleType = "FormModule" Then
		ModuleType = NStr("ru = 'Модуль формы';
						|en = 'Form module';");
		RefinementErrors = NStr("ru = 'Данная вставка должна быть в указанной форме, т.к. основным реквизитом является таблица объекта.';
								|en = 'This insert must be in the specified form as the main attribute is an object table.';");
		RefinementErrors = Chars.LF + Chars.LF + RefinementErrors;
	EndIf;
	
	ModuleIsEmpty = IsBlankString(ModuleText);
	ProcedureNameSet = Not IsBlankString(NameOfAProcedureOrAFunction);
	FullObjectName = MetadataObject.FullName();
	If VerificationDetails.IsOptionalAlgorithm Then
		If VerificationDetails.ProcedurePresenceIsError Then
			BriefErrorDescription = NStr("ru = 'Экспортный метод не объявлен';
												|en = 'Export method is not announced';");
		Else
			BriefErrorDescription = NStr("ru = 'Объявлен отсутствующий экспортный метод';
												|en = 'Missing expert method is announced';");
		EndIf;
	Else
		If VerificationDetails.ProcedurePresenceIsError Then
			BriefErrorDescription = NStr("ru = 'Обнаружена устаревшая вставка кода';
												|en = 'The obsolete code insert is found';");
		Else
			BriefErrorDescription = NStr("ru = 'Отсутствует обязательная вставка кода';
												|en = 'The required code insert is missing';");
		EndIf;
	EndIf;
	
	If ModuleIsEmpty Then
		If VerificationDetails.AbsenceOfModuleIsError Then
			If VerificationDetails.ProcedurePresenceIsError Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Для объекта %1 отсутствует модуль %2. 
					|Обязательно наличие модуля.';
					|en = 'For the %1 object %2 module is missing. 
					|Module is required.';"),
					FullObjectName, ModuleType);
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Для объекта %1 отсутствует модуль %2. 
					|Обязательно наличие модуля и вызова из него %3';
					|en = 'For the %1 object %2 module is missing.
					|Module and a call from it are required %3';"),
					FullObjectName, ModuleType, CallString);
			EndIf;
			ErrorText = ErrorText + RefinementErrors;
			AddError(MetadataObject, BriefErrorDescription, ErrorText);
		EndIf;
		Return;
	EndIf;
	
	If ProcedureNameSet Then
		SearchArea = ProcedureOrFunctionText(NameOfAProcedureOrAFunction, ModuleText);
		If IsBlankString(SearchArea) Then
			If VerificationDetails.AbsenceOfProcedureIsError Then
				If VerificationDetails.IsOptionalAlgorithm Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В модуле %1 объекта %2 отсутствует экспортная процедура %3, 
						|которая объявлена в составе алгоритмов (см. %4).';
						|en = 'Module %1 of object %2 does not contain export procedure %3 
						|that is announced in the algorithm content (see %4).';"),
						ModuleType, FullObjectName, NameOfAProcedureOrAFunction, "OnGetSettings");
				Else
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В модуле %1 объекта %2 отсутствует обязательная процедура %3. 
						|В ней требуется наличие вставки кода %4';
						|en = 'Required procedure %3 is missing in module %1 of object %2. 
						|%4Code insert is required in it';"),
						ModuleType, FullObjectName, NameOfAProcedureOrAFunction, CallString);
				EndIf;
				ErrorText = ErrorText + RefinementErrors;
				AddError(MetadataObject, BriefErrorDescription, ErrorText);
			EndIf;
			Return;
		ElsIf VerificationDetails.ProcedurePresenceIsError Then
			
			If VerificationDetails.IsOptionalAlgorithm Then
				ErrorTemplate = NStr("ru = 'В модуле %1 объекта %2 обнаружена экспортная процедура %3, 
								|которая не объявлена в составе алгоритмов (см. %4).';
								|en = 'In module %1 of object %2, export procedure %3 
								|that is not announced in the algorithm content is found (see %4).';");
			Else
				ErrorTemplate = NStr("ru = 'В модуле %1 объекта %2 обнаружена устаревшая процедура %3.';
									|en = 'In %1 module of the %2 object obsolete procedure %3 is found.';");
			EndIf;
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
					ModuleType, FullObjectName, NameOfAProcedureOrAFunction, "OnGetSettings");
			ErrorText = ErrorText + RefinementErrors;
			AddError(MetadataObject, BriefErrorDescription, ErrorText);
			Return;
		EndIf;
		
		If TypeOf(CodeString) = Type("Array") Then
			ProcedureFunctionFound = StrFind(SearchArea, CodeString[0]) > 0 Or StrFind(SearchArea, CodeString[1]) > 0;
		Else
			ProcedureFunctionFound = (StrFind(SearchArea, CodeString) > 0);
		EndIf;
		If Not ProcedureFunctionFound And VerificationDetails.AbsenceOfProcedureIsError And Not VerificationDetails.IsOptionalAlgorithm Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В модуле %1 объекта %2 в процедуре %3 
				|отсутствует обязательная вставка кода %4';
				|en = 'In the %1 module of the %2 object,
				| the %3 procedure does not contain the required code %4';"),
				ModuleType, FullObjectName, NameOfAProcedureOrAFunction, CallString);
			ErrorText = ErrorText + RefinementErrors;
			AddError(MetadataObject, BriefErrorDescription, ErrorText);
			Return;
		EndIf;
	EndIf;
	
	SearchArea = ModuleText;
	If TypeOf(CodeString) = Type("Array") Then
		If StrFind(SearchArea, CodeString[0]) = 0 And StrFind(SearchArea, CodeString[1]) = 0 Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В модуле %1 объекта %2 отсутствует
				|обязательная вставка кода %3';
				|en = 'In %1 module of the %2 object the required code insert
				|is missing %3';"),
				ModuleType, FullObjectName, CallString);
			ErrorText = ErrorText + RefinementErrors;
			AddError(MetadataObject, BriefErrorDescription, ErrorText);
		EndIf;
		Return;
	EndIf;

	ProcedureFunctionFound = (StrFind(SearchArea, CodeString) > 0);
	If Not ProcedureFunctionFound And VerificationDetails.AbsenceOfProcedureIsError Then
		If VerificationDetails.IsOptionalAlgorithm Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В модуле %1 объекта %2 отсутствует экспортная процедура %3, 
				|которая объявлена в составе алгоритмов (см. %4).';
				|en = 'Module %1 of object %2 does not contain export procedure %3 
				|that is announced in the algorithm content (see %4).';"),
				ModuleType, FullObjectName, ?(ProcedureNameSet, NameOfAProcedureOrAFunction, CallString), "OnGetSettings");
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В модуле %1 объекта %2 отсутствует
				|обязательная вставка кода %3';
				|en = 'In %1 module of the %2 object the required code insert
				|is missing %3';"),
				ModuleType, FullObjectName, CallString);
		EndIf;
		ErrorText = ErrorText + RefinementErrors;
		AddError(MetadataObject, BriefErrorDescription, ErrorText);
		Return;
	EndIf;
	
	If ProcedureFunctionFound And VerificationDetails.ProcedurePresenceIsError Then
		If VerificationDetails.IsOptionalAlgorithm Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В модуле %1 объекта %2 обнаружена экспортная процедура %3, 
					|которая не объявлена в составе алгоритмов (см. %4).';
					|en = 'In module %1 of object %2, export procedure %3 
					|that is not announced in the algorithm content is found (see %4).';"),
					ModuleType, FullObjectName, ?(ProcedureNameSet, NameOfAProcedureOrAFunction, CallString), "OnGetSettings");
		Else
			If ProcedureNameSet Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В модуле %1 объекта %2 в процедуре %3 
				|обнаружена устаревшая вставка кода %4';
				|en = 'Obsolete code insert %4 is detected in module%1 of object %2 in procedure %3 
				|';"),
				ModuleType, FullObjectName, NameOfAProcedureOrAFunction, CallString);
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В модуле %1 объекта %2 обнаружена
				|устаревшая вставка кода %3';
				|en = 'Obsolete code insert %3 is detected
				| in module %1 of object %2';"),
				ModuleType, FullObjectName, CallString);
			EndIf;
		EndIf;
		ErrorText = ErrorText + RefinementErrors;
		AddError(MetadataObject, BriefErrorDescription, ErrorText);
		Return;
	EndIf;
	
	If ProcedureFunctionFound And Not VerificationDetails.IsOptionalAlgorithm And ProcedureNameSet Then
		DeclarationAndText = ProcedureOrFunctionDeclarationAndText(NameOfAProcedureOrAFunction, ModuleText);
		IsExportProcedureFunction = StrEndsWith(Lower(TrimAll(DeclarationAndText.Declare)), " " + Lower("Export")); 
		If VerificationDetails.IsExportProcedure <> IsExportProcedureFunction Then 
			If IsExportProcedureFunction Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В модуле %1 объекта %2 в процедуре %3 
					|избыточно указано ключевое слово Экспорт.';
					|en = 'In module %1 of object %2 in procedure %3, 
					|the Export keyword is redundant.';"),
					ModuleType, FullObjectName, NameOfAProcedureOrAFunction);
			Else	
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В модуле %1 объекта %2 у процедуры %3 
					|отсутствует ключевое слово Экспорт.';
					|en = 'The Export keyword is missing from module %1 of object %2 in procedure %3.
					|';"),
					ModuleType, FullObjectName, NameOfAProcedureOrAFunction);
			EndIf;
			ErrorText = ErrorText + RefinementErrors;
			AddError(MetadataObject, BriefErrorDescription, ErrorText);
		EndIf;
	EndIf;
	
EndProcedure

Function BulletedList(Items)
	
	Marker = "• ";
	String = StrConcat(Items, Chars.LF + Marker);
	String = Marker + String;
	
	Return String;
	
EndFunction

Function IsSSLObject(MetadataObject)
	Return (SSLSubsystemObjects.Find(MetadataObject) <> Undefined);
EndFunction

Function IsDemoSSL()
	Return Metadata.Name = "StandardSubsystemsLibrary_Demo";
EndFunction

Function ObjectPropertiesByFileName(Val FileName)
	
	FileName = StrReplace(FileName, "/", "\");
	ObjectName = StrReplace(FileName, StrReplace(DumpDirectory, "/", "\"), "");
	ObjectName = StrReplace(ObjectName, "Ext\", "");
	ObjectName = Left(ObjectName, StrLen(ObjectName) - 4);
	NameParts = StrSplit(ObjectName, "\", False);
	
	NameArray = New Array;
	For Each NamePart In NameParts Do
		If TermsMap.Property(NamePart) Then
			NameArray.Add(TermsMap[NamePart]);
		Else
			NameArray.Add(NamePart);
		EndIf;
	EndDo;

	FullMetadataObjectName = NameArray[0];
	If NameArray.Count() > 1 Then
		FullMetadataObjectName = FullMetadataObjectName + "." + NameArray[1];
	EndIf;
	
	ObjectProperties = New Structure;
	ObjectProperties.Insert("Presentation", StrConcat(NameArray, "."));
	ObjectProperties.Insert("MetadataObject", Common.MetadataObjectByFullName(FullMetadataObjectName));
	
	Return ObjectProperties;
	
EndFunction

Function DOMDocument(PathToFile)
	
	XMLReader = New XMLReader;
	DOMBuilder = New DOMBuilder;
	
	If TypeOf(PathToFile) = Type("String") Then
		XMLReader.OpenFile(PathToFile);
	Else
		XMLReader.OpenStream(PathToFile);
	EndIf;
	
	DOMDocument = DOMBuilder.Read(XMLReader);
	XMLReader.Close();
	
	Return DOMDocument;
	
EndFunction

Function WriteDOMDocument(DOMDocument, FileName = "")
	
	XMLWriter = New XMLWriter;
	DOMWriter = New DOMWriter;
	
	If Not IsBlankString(FileName) Then
		XMLWriter.OpenFile(FileName);
		DOMWriter.Write(DOMDocument, XMLWriter);
		FilesToUpload.Add(FileName);
	Else
		XMLWriter.SetString("UTF-8");
		DOMWriter.Write(DOMDocument, XMLWriter);
	EndIf;
	
	Return XMLWriter.Close();
	
EndFunction

Function EvaluateXPathExpression(Expression, DOMDocument, Dereferencer = Undefined)
	
	If Dereferencer = Undefined Then
		Dereferencer = DOMDocument.CreateNSResolver();
	EndIf;
	Return DOMDocument.EvaluateXPathExpression(Expression, DOMDocument, Dereferencer);
	
EndFunction

Procedure ExecuteCheck(CheckParameters = Undefined)
	
	If CorrectErrors <> Undefined Then
		CheckParameters.CorrectErrors = CorrectErrors;
	EndIf;
	If FixedErrors <> Undefined Then
		CheckParameters.FixedErrors = FixedErrors;
	EndIf;
	If FilterBySubsystems <> Undefined Then
		CheckParameters.CheckedSubsystems = FilterBySubsystems;
	EndIf;
	
	CheckParameters.Insert("InteractiveLaunch", False);
	If InteractiveLaunch = True Then
		CheckParameters.InteractiveLaunch = True;
	EndIf;
	
	If CheckParameters.ExceptionsTable <> Undefined And ExceptionsTable <> Undefined Then
		InitializeExceptionTable();
		For Each String In CheckParameters.ExceptionsTable Do
			FillPropertyValues(ExceptionsTable.Add(), String);
		EndDo;
		
		CheckParameters.ExceptionsTable = ExceptionsTable.Copy();
	EndIf;
	
	FillInVerificationData(CheckParameters);
	
	If TypeOf(CheckParameters) = Type("Structure")
		And CheckParameters.CheckedSubsystems.Count() > 0 Then
		CheckedSubsystems = CheckParameters.CheckedSubsystems;
	Else
		CheckedSubsystems = New Array;
		AtDeterminingSubsystemsToBeChecked(CheckedSubsystems);
	EndIf;
	
	ProcedureNameTemplate = StringFunctionsClientServer.SubstituteParametersToString(
		"%1_[%2]_%3()", "Attachable", "SubsystemName", "CheckIntegration");
	
	
	RunCheckInMultipleThreads(CheckedSubsystems, ProcedureNameTemplate,
		Not (CheckParameters.Property("OnlyInternalExtensionsAttached")
		    And CheckParameters["OnlyInternalExtensionsAttached"] = True));
	
EndProcedure

Function CalculationResult(Expression)
	
	Return Common.CalculateInSafeMode(Expression);
	
EndFunction

// Parameters:
//  MetadataObject - MetadataObject
// 
// Returns:
//    Array of MetadataObjectForm
//
Function NotRequireInsertsForObjectFormForms(MetadataObject)
	FormsCollection = New Structure;
	FormsCollection.Insert("DefaultFolderForm");
	FormsCollection.Insert("DefaultChoiceForm");
	FormsCollection.Insert("DefaultFolderChoiceForm");
	FormsCollection.Insert("DefaultListForm");
	
	FillPropertyValues(FormsCollection, MetadataObject);
	
	Result = New Array;
	For Each Form In FormsCollection Do
		If Form.Value <> Undefined Then
			Result.Add(Form.Value);
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

// Parameters:
//  MetadataObject - MetadataObject
// 
// Returns:
//    Array of MetadataObjectForm
//
Function NotRequireInsertsForListFormForms(MetadataObject)
	FormsCollection = New Structure;
	FormsCollection.Insert("DefaultFolderForm");
	FormsCollection.Insert("DefaultFolderChoiceForm");
	FormsCollection.Insert("DefaultObjectForm");
	
	FillPropertyValues(FormsCollection, MetadataObject);
	
	Result = New Array;
	For Each Form In FormsCollection Do
		If Form.Value <> Undefined Then
			Result.Add(Form.Value);
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

Procedure CheckMetadataObjectFormsPatternMatching(MetadataObject, ChecksArray, CheckedModules)
	
	For Each Form In MetadataObject.Forms Do
		CheckedModules.Clear();
		CheckedModules.Add(Form.Name);
		CheckMetadataObjectSourceCodeBySample(MetadataObject, ChecksArray, CheckedModules);
	EndDo;
	
EndProcedure

Procedure CheckMetadataObjectSourceCodeBySample(MetadataObject, CheckedInserts, CheckedModules)
	
	ObjectStructure = New Structure("Correctness, Use, ErrorDescription");
	ObjectStructure.Correctness = True;
	ObjectStructure.Use = False;
	ObjectStructure.ErrorDescription = "";
	
	For Each CheckedModule In CheckedModules Do
		
		ModuleText = ModuleText(MetadataObject, CheckedModule);
		If IsBlankString(ModuleText) Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Отсутствует текст модуля: %1.';
					|en = 'Module text is missing: %1.';"), CheckedModule);
			
			ObjectStructure.Correctness = False;
			ObjectStructure.ErrorDescription = ObjectStructure.ErrorDescription + "|" + ErrorText;
			Continue;
			
		EndIf;
		
		ModuleText = SignificantCharacters(ModuleText);
		For Each InsertingCode In CheckedInserts Do
			
			CheckedInsertText = SignificantCharacters(InsertingCode.InsertSettings);
			CheckedProcedureText = SignificantCharacters(InsertingCode.Location);
			
			If Not IsBlankString(CheckedProcedureText) Then
				
				MethodStartPosition = StrFind(ModuleText, CheckedProcedureText);
				If MethodStartPosition > 0 Then
					
					LocationText = Mid(ModuleText, MethodStartPosition);
					If StrStartsWith(CheckedProcedureText, Lower("Procedure")) Then
						MethodTerminationPosition = StrFind(LocationText, Lower("EndProcedure"));
					Else
						MethodTerminationPosition = StrFind(LocationText, Lower("EndFunction"));
					EndIf;
					
					LocationText = Left(LocationText, MethodTerminationPosition);
					
				Else
					
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Отсутствует вызов: %1.';
							|en = 'Call is missing: %1.';"), InsertingCode.Location);
					
					ObjectStructure.Correctness = False;
					ObjectStructure.ErrorDescription = ObjectStructure.ErrorDescription + "|" + ErrorText;
					Continue;
					
				EndIf;
				
			Else
				LocationText = ModuleText;
			EndIf;
			
			If Not IsBlankString(CheckedInsertText) Then
				
				CallParametersPosition = StrFind(CheckedInsertText, "(");
				If CallParametersPosition = 0 Then
					InsertionExists(LocationText, CheckedInsertText, ObjectStructure, InsertingCode);
				Else
					
					While CallParametersPosition > 0 Do
						
						CallPosition = StrFind(LocationText, Left(CheckedInsertText, CallParametersPosition));
						If CallPosition = 0 Then
							
							InsertionExists(LocationText, Left(CheckedInsertText, CallParametersPosition),
								ObjectStructure, InsertingCode);
							Break;
							
						Else
							
							ObjectStructure.Use = True;
							
							LocationText = Mid(LocationText, CallPosition);
							LocationText = StrReplace(LocationText, Left(CheckedInsertText, CallParametersPosition), "");
							CheckedInsertText = Mid(CheckedInsertText, CallParametersPosition + 1);
							
							SampleCallTerminationPosition = StrFind(CheckedInsertText, ")");
							CallTerminationPositionInModule = StrFind(LocationText, ")");
							ModuleCallParameters = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
								Left(LocationText, CallTerminationPositionInModule), ",");
							SampleCallParameters = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
								Left(CheckedInsertText, SampleCallTerminationPosition), ",");
							
							If ModuleCallParameters.Count() < SampleCallParameters.Count() Then
								
								ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("ru = 'Количество параметров вызова не соответствует образцу: %1.';
										|en = 'The number of call parameters does not match the template: %1.';"),
									Chars.LF + InsertingCode.InsertSettings + Chars.LF);
								
								ObjectStructure.Correctness = False;
								ObjectStructure.ErrorDescription = ObjectStructure.ErrorDescription + "|" + ErrorText;
								Break;
								
							EndIf;
							
							LocationText       = Mid(LocationText, CallTerminationPositionInModule + 1);
							CheckedInsertText = Mid(CheckedInsertText, SampleCallTerminationPosition + 1);
							CallParametersPosition = StrFind(CheckedInsertText, "(");
							
						EndIf;
						
					EndDo;
					
					If StrLen(CheckedInsertText) > 0
						And ObjectStructure.Correctness Then
						
						InsertionExists(LocationText, CheckedInsertText, ObjectStructure, InsertingCode);
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		If ObjectStructure.Use Then
			If Not ObjectStructure.Correctness Then
				
				Errors = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ObjectStructure.ErrorDescription, "|", True);
				ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Модуль формы %1';
																								|en = '%1 form module';"), CheckedModule);
				For Each Error In Errors Do
					Error = ErrorTitle + Chars.LF + Error;
					AddError(MetadataObject, NStr("ru = 'Отсутствует обязательная вставка кода';
															|en = 'The required code insert is missing';"),
						Error);
				EndDo;
				
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

Function TemplateToValuesTable(SampleLayoutName, Filters = Undefined)

	Template = GetTemplate(SampleLayoutName);
	
	If Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.English Then
		ObjectEnglishLanguage = Metadata.Languages.Find("English");
		If ObjectEnglishLanguage <> Undefined Then
			Template.LanguageCode = ObjectEnglishLanguage.LanguageCode;
		EndIf;
	EndIf;
	
	ResultTable1 = New ValueTable;
	
	NumberOfDimensions = Template.RowGroupLevelCount();
	For IndexOf = 1 To Template.TableWidth Do
		
		TemplateArea = Template.Area("R1C" + Format(IndexOf, "NZ=0; NG="));
		ColumnName = TrimAll(TemplateArea.Text);
		If IsBlankString(ColumnName) Then
			Break;
		EndIf;
		
		ResultTable1.Columns.Add(ColumnName);
		
	EndDo;
	
	ColumnsCount = ResultTable1.Columns.Count();
	If ColumnsCount = 0 Then
		Return Undefined;
	EndIf;
	
	If NumberOfDimensions > 0 Then
		ResultTable1.Columns.Add("Module");
	EndIf;
	
	FirstColumnName = ResultTable1.Columns[0].Name;
	For LineNumber = 2 To Template.TableHeight Do
		FirstCellText = TrimAll(Template.Area("R" + Format(LineNumber, "NZ=0; NG=") + "C1").Text);
		
		If NumberOfDimensions > 0 Then
			
			If StrStartsWith(FirstCellText, "Module") Then
				FilesFilter = TrimAll(StrReplace(FirstCellText, "Module:", ""));
				Continue;
			EndIf;
			
			NewRow = ResultTable1.Add();
			NewRow.Module = FilesFilter;
			
		Else
			NewRow = ResultTable1.Add();
		EndIf;
		
		NewRow[FirstColumnName] = FirstCellText;
		For IndexOf = 2 To ColumnsCount Do
			ColumnName = ResultTable1.Columns[IndexOf - 1].Name;
			CellValue = TrimAll(Template.Area("R" + Format(LineNumber, "NZ=0; NG=") + "C" + Format(IndexOf, "NZ=0; NG=")).Text);
			NewRow[ColumnName] = CellValue;
		EndDo;
		
	EndDo;
	
	If NumberOfDimensions > 0 Then
		ResultTable1.Sort("Module");
	EndIf;
	
	Return ResultTable1;
	
EndFunction

Function TypesDescriptionFromString(ValueTypeAsString)
	
	If IsBlankString(ValueTypeAsString) Then
		Return Undefined;
	EndIf;
	
	DateQualifiers   = Undefined;
	NumberQualifiers  = Undefined;
	StringQualifiers = Undefined;
	
	ValueTypes = New Array;
	ValueTypesAsString = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ValueTypeAsString, ",", , True);
	For Each TypeAsString In ValueTypesAsString Do
		QualifiersBeginning = StrFind(TypeAsString, "(");
		If QualifiersBeginning > 0 Then
			QualifiersLength = StrLen(TypeAsString) - QualifiersBeginning - 1;
			QualifiersByString = Mid(TypeAsString, QualifiersBeginning + 1, QualifiersLength);
			TypeAsString = Left(TypeAsString, QualifiersBeginning - 1);
			Qualifiers = StringFunctionsClientServer.SplitStringIntoSubstringsArray(QualifiersByString, "/", False, True); 
			
			If TypeAsString = "Date" Then
				DateFormat = Qualifiers[0];
				DateQualifiers = New DateQualifiers(DateFractions[DateFormat]);
			ElsIf TypeAsString = "Number" Then
				NumLength = Number(Qualifiers[0]);
				NumberAccuracy = Number(Qualifiers[1]);
				AllowedNumberChar = AllowedSign[Qualifiers[2]];
				
				NumberQualifiers = New NumberQualifiers(NumLength, NumberAccuracy, AllowedNumberChar);
			ElsIf TypeAsString = "String" Then
				StringLength = Number(Qualifiers[1]);
				AllowedStringLength = ?(Qualifiers[0] = "F", AllowedLength.Fixed, AllowedLength.Variable);
				
				StringQualifiers = New StringQualifiers(StringLength, AllowedStringLength);
			EndIf;
		EndIf;
		
		ValueTypes.Add(Type(TypeAsString));
	EndDo;
	
	If ValueTypes.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	Return New TypeDescription(ValueTypes, , , NumberQualifiers, StringQualifiers, DateQualifiers);
	
EndFunction

Function ComparePropertyValueWithSample(PropertyName, Val ValueInSample, Val PropertyValue)
	
	If Not IsBlankString(ValueInSample) Then
		If PropertyName = "FillChecking" Then
			ValueInSample = FillChecking[ValueInSample];
		Else
			PropertyValue = String(PropertyValue);
		EndIf;
	EndIf;
	
	If PropertyName = "Indexing"
		And PropertyValue = "Index" Then
		
		Return True;
	Else
		Return ValueInSample = PropertyValue;
	EndIf;
	
EndFunction

Function SignificantCharacters(Val Text)
	
	SignificantCharactersString = StrReplace(Text, " ", "");
	SignificantCharactersString = StrReplace(SignificantCharactersString, Chars.CR, "");
	SignificantCharactersString = StrReplace(SignificantCharactersString, Chars.VTab, "");
	SignificantCharactersString = StrReplace(SignificantCharactersString, Chars.NBSp, "");
	SignificantCharactersString = StrReplace(SignificantCharactersString, Chars.LF, "");
	SignificantCharactersString = StrReplace(SignificantCharactersString, Chars.FF, "");
	SignificantCharactersString = StrReplace(SignificantCharactersString, Chars.Tab, "");
	
	Return Lower(SignificantCharactersString);
	
EndFunction

Function InsertionExists(LocationText, CheckedInsertText, ObjectStructure, InsertingCode)
	
	InsertionExists = StrFind(LocationText, CheckedInsertText) > 0;
	If InsertionExists Then
		ObjectStructure.Use = True;
	Else
		
		ParameterText1 = Chars.LF + ?(IsBlankString(InsertingCode.Location), "", 
			InsertingCode.Location + ":" + Chars.LF) + InsertingCode.InsertSettings + Chars.LF;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Вставка отсутствует или не соответствует образцу: %1.';
				|en = 'The insert is missing or does not match the template: %1.';"),
			ParameterText1);
		
		ObjectStructure.Correctness = False;
		ObjectStructure.ErrorDescription = ObjectStructure.ErrorDescription + "|" + ErrorText;
		
	EndIf;
	
	Return InsertionExists;
	
EndFunction

Function ChangeAttributeType(DOMDocument, AttributeName, AttributeTypeByString)
	
	TypeBySample = TypesDescriptionFromString(AttributeTypeByString);
	
	Expression = XPathExpressionCatalogAttributeType(AttributeName);
	Result = EvaluateXPathExpression(Expression, DOMDocument);
	TypesNode = Result.IterateNext();
	
	DeletedNodes = New Array;
	For Each ChildNode In TypesNode.ChildNodes Do
		DeletedNodes.Add(ChildNode);
	EndDo;
	For Each Node_ToDelete In DeletedNodes Do
		TypesNode.RemoveChild(Node_ToDelete);
	EndDo;
	
	For Each Type In TypeBySample.Types() Do
		
		XMLTypeName = TypeNameString(Type, DOMDocument);
		
		AddDOMNodeProperty(DOMDocument, TypesNode, PropertyType(), XMLTypeName);
		
		If Type = Type("String") Then
			
			StringLengthProperty     = StringLengthString(TypeBySample.StringQualifiers.Length);
			AcceptableLengthProperty = AllowedStringLengthString(TypeBySample.StringQualifiers.AllowedLength);
			
			QualifierNode = TypesNode.AppendChild(DOMDocument.CreateElement(StringQualifierProperty()));
			If Not IsBlankString(StringLengthProperty) Then
				AddDOMNodeProperty(DOMDocument, QualifierNode, StringLengthProperty(), StringLengthProperty);
			EndIf;
			If Not IsBlankString(AcceptableLengthProperty) Then
				AddDOMNodeProperty(DOMDocument, QualifierNode, AllowedStringLengthProperty(), AcceptableLengthProperty);
			EndIf;
			
		ElsIf Type = Type("Number") Then
			
			BitnessProperty             = DigitNumberString(TypeBySample.NumberQualifiers.Digits);
			ValidSignProperty          = ValidNumberSignString(TypeBySample.NumberQualifiers.AllowedSign);
			FractionalPartBitnessProperty = FractionalPartBitDepthString(TypeBySample.NumberQualifiers.FractionDigits);
			
			QualifierNode = TypesNode.AppendChild(DOMDocument.CreateElement(NumberQualifierProperty()));
			AddDOMNodeProperty(DOMDocument, QualifierNode, NumberBitnessProperty(), BitnessProperty);
			If Not IsBlankString(FractionalPartBitnessProperty) Then
				AddDOMNodeProperty(DOMDocument, QualifierNode, NumberFractionalPartBitnessProperty(), FractionalPartBitnessProperty);
			EndIf;
			If Not IsBlankString(ValidSignProperty) Then
				AddDOMNodeProperty(DOMDocument, QualifierNode, ValidNumberSignProperty(), ValidSignProperty);
			EndIf;
			
		ElsIf Type = Type("Date") Then
			
			DateStringParts = DateStringParts(TypeBySample.DateQualifiers.DateFractions);
			
			QualifierNode = TypesNode.AppendChild(DOMDocument.CreateElement(DateQualifierProperty()));
			If Not IsBlankString(DateStringParts) Then
				AddDOMNodeProperty(DOMDocument, QualifierNode, DateCompositionProperty(), DateStringParts);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	CorrectionText = NStr("ru = 'Исправлено. Тип реквизита ""%1"" изменен на требуемый: %2.';
							|en = 'Fixed. The ""%1"" attribute type is changed to the required one: %2.';");
	Return StringFunctionsClientServer.SubstituteParametersToString(CorrectionText, 
		AttributeName, StrReplace(AttributeTypeByString, "/", ", "));
	
EndFunction

Function ChangePropertyValue(DOMDocument, AttributeName, PropertyName, PropertyValueByString)
	
	PropertyNameValue = PropertyInEnglishNotation(PropertyName, PropertyValueByString);
	If PropertyNameValue.Name = Undefined Then
		Return "";
	EndIf;
	
	Result    = EvaluateXPathExpression(XPathExpressionCatalogAttributeProperty(AttributeName, PropertyNameValue.Name), DOMDocument);
	PropertyNode1 = Result.IterateNext();
	If Not PropertyNode1 = Undefined Then
		For Each ChildNode In PropertyNode1.ChildNodes Do
			PropertyNode1.RemoveChild(ChildNode);
		EndDo;
		PropertyNode1.AppendChild(DOMDocument.CreateTextNode(PropertyNameValue.Value));
	Else
		Result    = EvaluateXPathExpression(XPathExpressionCatalogAttribute(AttributeName), DOMDocument);
		PropertyNode1 = Result.IterateNext();
		AddDOMNodeProperty(DOMDocument, PropertyNode1, PropertyNameValue.Name, PropertyNameValue.Value);
	EndIf;
	
	CorrectionText = NStr("ru = 'Исправлено. Значение свойства ""%1"" реквизита ""%2"" изменено на требуемое: ""%3"".';
							|en = 'Fixed. The ""%1"" value of the ""%2"" attribute is changed to the required one: ""%3"".';");
	Return StringFunctionsClientServer.SubstituteParametersToString(CorrectionText,
		PropertyName, AttributeName, PropertyValueByString);
	
EndFunction

Procedure AddDOMNodeProperty(DOMDocument, Node, PropertyName, Value)
	
	PropertyNode1 = Node.AppendChild(DOMDocument.CreateElement(PropertyName));
	PropertyNode1.AppendChild(DOMDocument.CreateTextNode(Value));
	
EndProcedure

Function PropertyInEnglishNotation(PropertyName, PropertyValue)
	
	Property = New Structure("Name, Value");
	If PropertyName = "FillChecking" Then
		Property.Name = CheckFillingProperty();
		Property.Value = ?(PropertyValue = "ShowError", "ShowError", "DontCheck");
	ElsIf PropertyName = "Indexing" Then
		Property.Name = IndexingProperty();
		Property.Value = ?(PropertyValue = "Index", "Index", "DontIndex");
	ElsIf PropertyName = "FullTextSearch" Then
		Property.Name = FullTextSearchProperty();
		Property.Value = ?(PropertyValue = "Use", "Use", "DontUse");
	EndIf;
	
	Return Property;
	
EndFunction

Function IncludedInUnverifiedSubsystems(FullObjectName)
	
	ObjectSubsystems = MatchingObjects.Get(FullObjectName);
	
	If ObjectSubsystems = Undefined Then
		Return False;
	EndIf;
	
	For Each Subsystem In ObjectSubsystems Do
		If NonVerifiableConfigurationSubsystems.Find(Subsystem.Name) <> Undefined Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function SkippedMetadataObjectsInRole(RoleComposition, SetNewObjectsRights)
	
	SkippedMetadataObjects = New Map;
	
	While True Do
		
		RoleObject = RoleComposition.IterateNext();
		If RoleObject = Undefined Then
			Break;
		EndIf;
		
		FullObjectName = GetProperty(RoleObject, RoleObjectNameProperty());
		If FullObjectName = Undefined Then
			Continue;
		EndIf;
		
		NameParts = StrSplit(FullObjectName, ".");
		If NameParts.Count() <> 2 Then
			Continue;
		EndIf;
		
		RightsToField = New Structure;
		RightsToField.Insert("View", "Unspecified");
		RightsToField.Insert("Edit", "Unspecified");
		
		For Each ObjectRight In RoleObject.ChildNodes Do
			NameOfRight = GetProperty(ObjectRight, RightsNameProperty());
			If NameOfRight = Undefined Then
				Continue;
			EndIf;
			If Not RightsToField.Property(NameOfRight) Then
				Continue;
			EndIf;
			RightsToField[NameOfRight] = GetProperty(ObjectRight, RightValueProperty());
		EndDo;
		
		If StrStartsWith(FullObjectName, "DataProcessor")
			 Or StrStartsWith(FullObjectName, "Report") Then
			
			RightsToField["Edit"] = True;
			
		ElsIf RightsToField["Edit"] = "Unspecified" Then
			RightsToField["Edit"] = SetNewObjectsRights;
		EndIf;
		
		If RightsToField["View"] = "Unspecified" Then
			RightsToField["View"] = SetNewObjectsRights;
		EndIf;
		
		If RightsToField["Edit"] <> False Or RightsToField["View"] <> False Then
			InstalledRights = New Structure;
			InstalledRights.Insert("View", RightsToField["View"] <> False);
			InstalledRights.Insert("Edit", RightsToField["Edit"] <> False);
			SkippedMetadataObjects.Insert(FullObjectName, InstalledRights);
		EndIf;
		
	EndDo;
	
	Return SkippedMetadataObjects;
	
EndFunction

Function RoleProperty(ErrorText, BriefErrorDetails, Correct, DOMDocument, PropertyName, RequiredValue = Undefined)
	
	ErrorText           = "";
	BriefErrorDetails = "";
	
	If PropertyName = SetRightsForNewObjectsProperty() Then
		PropertyPresentation = NStr("ru = 'Устанавливать права для новых объектов';
									|en = 'Set rights for new objects';");
	
	ElsIf PropertyName = SetRightsForDetailsAndTablePartsByDefaultProperty() Then
		PropertyPresentation = NStr("ru = 'Устанавливать права для реквизитов и табличных частей по умолчанию';
									|en = 'Set rights for attributes and tables by default';");
	
	ElsIf PropertyName = IndependentSubordinateObjectsRightsProperty() Then
		PropertyPresentation = NStr("ru = 'Независимые права подчиненных объектов';
									|en = 'Independent rights of subordinate objects';");
	Else
		ErrorText = NStr("ru = 'Неизвестное свойство роли';
							|en = 'Unknown role property';") + ": " + PropertyName;
		BriefErrorDetails = NStr("ru = 'Неизвестное свойство роли';
									|en = 'Unknown role property';");
		Return Undefined;
	EndIf;
	
	RoleCompositionAndProperties = DOMDocument.FirstChild;
	Value            = GetProperty(RoleCompositionAndProperties, PropertyName);
	If Value = Undefined Then
		ErrorText = ErrorText + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Свойство ""%1"" не найдено.';
				|en = 'The %1 property is not found.';"), PropertyPresentation);
		BriefErrorDetails = NStr("ru = 'Свойство не найдено.';
									|en = 'The property is not found.';");
		Return Undefined;
	EndIf;
	
	If IsDemoSSL() Then
		If TypeOf(Value) <> Type("Boolean") Then
			
			If Correct Then
				SetProperty(RoleCompositionAndProperties, PropertyName, RequiredValue);
				Value = GetProperty(RoleCompositionAndProperties, PropertyName);
			Else
				ErrorText = ErrorText + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Свойство ""%1"" не типа Булево.';
						|en = 'The %1 property is not Boolean.';"), PropertyPresentation);
				BriefErrorDetails = NStr("ru = 'Свойство отличается от свойства по умолчанию для роли (не типа булево)';
											|en = 'The property differs from the default one for the role (not of the Boolean type)';");
			EndIf;
			
		ElsIf TypeOf(RequiredValue) = Type("Boolean")
			 And Value <> RequiredValue Then
			
			If Correct Then
				SetProperty(RoleCompositionAndProperties, PropertyName, RequiredValue);
				Value = GetProperty(RoleCompositionAndProperties, PropertyName);
			ElsIf RequiredValue Then
				ErrorText = ErrorText + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Свойство ""%1"" должно быть установлено.';
						|en = 'The %1 property must be set.';"), PropertyPresentation);
				BriefErrorDetails = NStr("ru = 'Свойство отличается от свойства по умолчанию для роли ( должно быть установлено )';
											|en = 'The property differs from the default one for the role (must be set)';");
			Else
				ErrorText = ErrorText + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Свойство ""%1"" должно быть снято.';
						|en = 'The %1 property must be cleared.';"), PropertyPresentation);
				BriefErrorDetails = NStr("ru = 'Свойство отличается от свойства по умолчанию для роли ( должно быть снято )';
											|en = 'The property differs from the default one for the role (must be removed)';");
			EndIf;
			
		EndIf;
	EndIf;
	
	Return Value;
	
EndFunction

Procedure AddRoleDetailsRightsError(Val MetadataObject, BriefErrorDetails, DetailedErrorDetails, 
	SSLSubsystem = Undefined, Critical = False, PermissionsDefault = Undefined)
	
	If SSLSubsystem = Undefined Then
		SSLSubsystem = CheckedSubsystem;
	EndIf;
	If MetadataObject = Undefined Then
		MetadataObject = SSLSubsystem;
	EndIf;
	ObjectPresentation = MetadataObjectTypeView(MetadataObject);
	
	TableIndex = CheckTable.Count() - 1;
	IsNewLine = True;
	If TableIndex >= 0 Then
		TableRow = CheckTable[TableIndex];
		While TableRow.MetadataObject = ObjectPresentation And TableRow.SSLSubsystem = 
			?(SSLSubsystem = Undefined, "", SSLSubsystem.Presentation()) Do
			If TableRow.BriefErrorDetails = BriefErrorDetails Then
				TableRow.DetailedErrorDetails = TableRow.DetailedErrorDetails + Chars.CR + DetailedErrorDetails;
				IsNewLine = False;
			ElsIf TableIndex > 0 Then
				TableIndex = TableIndex - 1;
				TableRow = CheckTable[TableIndex];
				Continue;
			EndIf;
			Break;
		EndDo;
	EndIf;
	
	If IsNewLine Then
		Indent = Chars.LF + Chars.LF;
		If PermissionsDefault = True Then
			RefinementErrors = NStr("ru = 'Для уменьшения размера конфигурации права на реквизиты (табличные части) должны быть установлены.
				|По умолчанию права для них должны совпадать со значением флажка ""Устанавливать права по умолчанию для реквизитов и табличных частей"" в роли.';
				|en = 'To reduce the configuration size, access rights to attributes (tables) must be set.
				|By default, these rights must match the value of the ""Set rights for attributes and tables by default"" check box in the role.';");
			DetailedErrorDetails = RefinementErrors + Indent + DetailedErrorDetails;
		ElsIf PermissionsDefault = False Then
			RefinementErrors = NStr("ru = 'Для уменьшения размера конфигурации права на реквизиты (табличные части) должны быть сняты.
				|По умолчанию права для них должны совпадать со значением флажка ""Устанавливать права по умолчанию для реквизитов и табличных частей"" в роли.';
				|en = 'To reduce the configuration size, access rights to attributes (tables) must be cleared.
				|By default, these rights must match the value of the ""Set rights for attributes and tables by default"" check box in the role.';");
			DetailedErrorDetails = RefinementErrors + Indent + DetailedErrorDetails;
		EndIf;
		
		AddError(MetadataObject, BriefErrorDetails, DetailedErrorDetails, SSLSubsystem, Critical);
	EndIf;
	
EndProcedure

Function GetProperty(Node, PropertyName)
	
	NodesList = Node.ChildNodes;
	ReturnValue_1 = Undefined;
	For Each ChildNode In NodesList Do
		If ChildNode.NodeName = PropertyName Then
			ReturnValue_1 = ChildNode.TextContent;
			Break;
		EndIf;
	EndDo;
	If ReturnValue_1 = "true" Then
		ReturnValue_1 = True;
	ElsIf ReturnValue_1 = "false" Then
		ReturnValue_1 = False;
	EndIf;
	Return ReturnValue_1;
	
EndFunction

Function SetProperty(Node, PropertyName, Value)
	
	NodesList = Node.ChildNodes;
	If TypeOf(Value) = Type("Boolean") Then
		Value = Format(Value, "BF=false; BT=true");
	EndIf;
		
	Success = False;
	For Each ChildNode In NodesList Do
		If ChildNode.NodeName = PropertyName Then
			ChildNode.TextContent = String(Value);
			Success = True;
			Break;
		EndIf;
	EndDo;
	Return Success;
	
EndFunction

Function RoleNameByFileName(Val FileName)
	
	FileName = StrReplace(FileName, "/", "\");
	NameOfRole = StrReplace(FileName, StrReplace(DumpDirectory, "/", "\"), "");
	NameOfRole = StrReplace(NameOfRole, "Ext\", "");
	NameOfRole = StrReplace(NameOfRole, RoleFileName(), "");
	NameParts = StrSplit(NameOfRole, "\", False);
	
	NameOfRole = NameParts[NameParts.UBound()];
	
	Return NameOfRole;
	
EndFunction

Function CompareEdtxxxRoleTemplates(RoleRightsTemplate, TemplateForTemplateRightsByRoleReference)
	
	StartOfSecondLine = StrFind(RoleRightsTemplate, Chars.LF,,,1);
	EndOfSecondLine  = StrFind(RoleRightsTemplate, Chars.LF,,,2);
	SecondLineText  = Mid(RoleRightsTemplate, StartOfSecondLine, EndOfSecondLine - StartOfSecondLine);
	
	TextOfRoleRightsTemplateWithoutSecondLine = StrReplace(RoleRightsTemplate, SecondLineText, "");
	
	StartOfSecondLine = StrFind(TemplateForTemplateRightsByRoleReference, Chars.LF,,,1);
	EndOfSecondLine  = StrFind(TemplateForTemplateRightsByRoleReference, Chars.LF,,,2);
	SecondLineText  = Mid(TemplateForTemplateRightsByRoleReference, StartOfSecondLine, EndOfSecondLine - StartOfSecondLine);
	
	TextOfTemplateRightsToRoleReferenceWithoutSecondLine = StrReplace(TemplateForTemplateRightsByRoleReference, SecondLineText, "");
	
	Return TextOfRoleRightsTemplateWithoutSecondLine = TextOfTemplateRightsToRoleReferenceWithoutSecondLine;
	
EndFunction

Procedure WriteListOfFilesToDownload(ListOfFilesToDownload)
	
	If Not ValueIsFilled(ListOfFilesToDownload) Then
		Return;
	EndIf;
	
	If FilesToUpload.Count() = 0 Then
		Return;
	EndIf;
	
	FilesToUpload = CommonClientServer.CollapseArray(FilesToUpload);
	
	FilesNames = StrConcat(FilesToUpload, Chars.LF);
	ListOfFiles = New TextDocument;
	ListOfFiles.SetText(FilesNames);
	ListOfFiles.Write(ListOfFilesToDownload);
	
EndProcedure

// Returns a structure of parameters of the sought-for method.
//
// Parameters:
//   ModuleText         - String - The module text to search in.
//   SoughtMethod        - String - Method name.
//   SearchStartPosition - Number  - The position of the character where the search will start off.
//
// Returns:
//   Structure:
//     * IsMethodFound      - Boolean - Search result flag.
//     * ParametersArray - Array - An array of parameters, where: String - Parameter text.
//     * StartPosition    - Number  - The position of the first character of the method calling code.
//     * EndingPosition - Number  - The position of the last character of the method calling code.
//     * CallText      - String - The text of the method calling code (including parameters).
//     * ParameterText_  - String - The text of the method calling parameters.
//     * LineNumber      - Number  - Number of the line where the method begins.
//
Function MethodParameters(Val ModuleText, Val SoughtMethod, Val SearchStartPosition = 1)
	
	ParametersArray = New Array;
	
	Result = New Structure;
	Result.Insert("IsMethodFound", False);
	Result.Insert("ParametersArray", ParametersArray);
	Result.Insert("StartPosition", 0);
	Result.Insert("EndingPosition", 0);
	Result.Insert("CallText", "");
	Result.Insert("ParameterText_", "");
	Result.Insert("LineNumber", 0);
	
	If IsBlankString(ModuleText) Or IsBlankString(SoughtMethod) Then
		Return Result;
	EndIf;
	
	ModuleLength = StrLen(ModuleText);
	If SearchStartPosition >= ModuleLength Then
		Return Result;
	EndIf;
	
	MethodCallPosition = StrFind(ModuleText, SoughtMethod,, SearchStartPosition);
	If MethodCallPosition = 0 Then
		Return Result;
	EndIf;
	
	Result.IsMethodFound = True;
	Result.StartPosition = MethodCallPosition;
	TextBeforeMethod = Left(ModuleText, MethodCallPosition);
	Result.LineNumber = StrLineCount(TextBeforeMethod);
	
	OpeningParenthesisPosition = StrFind(ModuleText, "(",, MethodCallPosition + StrLen(SoughtMethod) - 2);
	If OpeningParenthesisPosition = 0 Then
		Result.EndingPosition = MethodCallPosition + StrLen(SoughtMethod);
		Return Result;
	EndIf;
	
	OpeningParenthesesCount = 1;
	
	IsStringOpen = False;
	
	ParametersStartPosition = OpeningParenthesisPosition + 1;
	ParameterPosition = ParametersStartPosition;
	
	For CharacterNumber = ParametersStartPosition To ModuleLength Do
		
		Char = Mid(ModuleText, CharacterNumber, 1);
		
		// The semicolon means a new line should be started.
		If Char = """" Then
			IsStringOpen = Not IsStringOpen;
		EndIf;
		
		// Characters enclosed in quotation marks are considered non-functional.
		If IsStringOpen Then
			Continue;
		EndIf;
		
		// The opening bracket denotes the start of a callback function.
		If Char = "(" Then
			
			OpeningParenthesesCount = OpeningParenthesesCount + 1;
			
		// The closing bracket denotes the end of either a callback function or the parameters of the sought-for function.
		ElsIf Char = ")" Then
			
			OpeningParenthesesCount = OpeningParenthesesCount - 1;
			
		// The comma denotes the end of a parameter.
		ElsIf Char = "," Then
			
			// Add the parameter to the array if this is a parameter of the sought-for function
			// (not a parameter of the function called as a parameter). Example:
			// Function1(Function2(Parameter1, Parameter2), Parameter3)
			// This expression will result in 2 parameters: "Function2(Parameter1, Parameter2)" and "Parameter3".
			// "Parameter1" and "Parameter2" of "Function2" shouldn't be added. 
			If OpeningParenthesesCount = 1 Then
				Parameter = Mid(ModuleText, ParameterPosition, CharacterNumber - ParameterPosition);
				ParametersArray.Add(TrimAll(Parameter));
				ParameterPosition = CharacterNumber + 1;
			EndIf;
			
		Else
			
			Continue;
			
		EndIf;
		
		// If the opening bracket count matches the closing bracket count,
		// all parameters of the sought-for function are found. Exit the loop.
		If OpeningParenthesesCount = 0 Then
			
			// Add the last parameter.
			Parameter = Mid(ModuleText, ParameterPosition, CharacterNumber - ParameterPosition);
			If (ParametersArray.Count() > 0) Or (Not IsBlankString(Parameter)) Then
				// Function1(): Has no parameters. Don't add an empty parameter.
				// Function2(,): Has two empty parameters. Add the 2d parameter to the array.
				// 
				
				ParametersArray.Add(TrimAll(Parameter));
			EndIf;
			
			Break;
			
		EndIf;
		
	EndDo;
	
	LineBreakPosition = StrFind(TextBeforeMethod, Chars.LF, SearchDirection.FromEnd) + 1;
	CallText = TrimAll(Mid(ModuleText, LineBreakPosition, CharacterNumber - LineBreakPosition + 2));
	ParameterText_ = TrimAll(Mid(ModuleText, ParametersStartPosition, CharacterNumber - ParametersStartPosition));
	
	Result.ParametersArray = ParametersArray;
	Result.EndingPosition = CharacterNumber;
	Result.CallText = CallText;
	Result.ParameterText_ = ParameterText_;
	
	Return Result;
	
EndFunction

// Returns a structure describing the search results.
//
// Parameters:
//   String                        - String             - The source string to search in.
//   SearchArray                  - Array of String   - An array of substrings to search in.
//   DirectionForSearch          - SearchDirection  - Defines the search direction (same as in "StrFind").
//   StartingSearchPosition        - Number              - Defines the search start position.
//   ShouldReturnFirstFoundItem - Boolean             - If set to "True", the function returns the first found item.
//                                                        Otherwise, it returns the nearest array element.
//
// Returns:
//   Structure:
//     * FoundItem - String - The found element of the array.
//     * Position          - Number  - The position of the found element.
//     * Success          - Boolean - "True" if at least one element was found.
//
Function StrFindByArray(String, SearchArray, DirectionForSearch = Undefined,
	StartingSearchPosition = Undefined, ShouldReturnFirstFoundItem = False)
	
	Result = New Structure;
	Result.Insert("FoundItem", "");
	Result.Insert("Position", 0);
	Result.Insert("Success", False);
	
	If DirectionForSearch = Undefined Then
		DirectionForSearch = SearchDirection.FromBegin;
	EndIf;
	
	SearchFromBegin = (DirectionForSearch = SearchDirection.FromBegin);
	
	If StartingSearchPosition = Undefined Then
		StartingSearchPosition = ?(SearchFromBegin, 1, StrLen(String));
	EndIf;
	
	TempSearchPosition = 0;
	For Each SearchText In SearchArray Do
		
		CurrentSearchPosition = StrFind(String, SearchText, DirectionForSearch, StartingSearchPosition);
		If CurrentSearchPosition = 0 Then
			Continue;
		EndIf;
		
		If (TempSearchPosition = 0)
			Or ?(SearchFromBegin, CurrentSearchPosition < TempSearchPosition, CurrentSearchPosition > TempSearchPosition) Then
			
			Result.FoundItem = SearchText;
			Result.Position = CurrentSearchPosition;
			Result.Success = True;
			
			If ShouldReturnFirstFoundItem Then
				Break;
			EndIf;
			
			TempSearchPosition = CurrentSearchPosition;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Returns a structure describing the search results.
//
// Parameters:
//   String       - String           - The source string to search in.
//   SearchArray - Array of String - An array of substrings to search in.
//
// Returns:
//   Structure:
//     * FoundItem - String - The found element of the array.
//     * Success          - Boolean - "True" if at least one element was found.
//
Function StrStartsWithByArray(String, SearchArray)
	
	Result = New Structure;
	Result.Insert("FoundItem", "");
	Result.Insert("Success", False);
	
	For Each SearchText In SearchArray Do
		Success = StrStartsWith(String, SearchText);
		If Success Then
			Result.FoundItem = SearchText;
			Result.Success = True;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Procedure ClearVariableFormModule(Content)
	For Each Item In Content Do
		If TypeOf(Item) = Type("Structure") Then
			ClearVariableFormModule(Item.Content);
		EndIf;
	EndDo;
	
	Content.Clear();
EndProcedure

Procedure ToggleSeparation(Value)
	If Common.FileInfobase() Then
		Constants.UseSeparationByDataAreas.Set(Value);
	EndIf;
EndProcedure

#Region WorkingWithConfigurationFileStructure

#Region MetadataFilePathTemplates

Function RoleCompositionFilePathTemplate()
	
	If EDTConfiguration Then
		PathPattern = "[DumpDirectory]Roles\[NameOfRole]\Rights.rights";
	Else
		PathPattern = "[DumpDirectory]Roles\[NameOfRole]\Ext\Rights.xml";
	EndIf;
	
	PathPattern = StrReplace(PathPattern, "\", GetPathSeparator());
	
	Return PathPattern;
	
EndFunction

Function RoleElementsDescriptionFilePathTemplate()
	
	If EDTConfiguration Then 
		PathPattern = "[DumpDirectory]Roles\[NameOfRole].mdo";
	Else
		PathPattern = "[DumpDirectory]Roles\[NameOfRole].xml";
	EndIf;
	
	PathPattern = StrReplace(PathPattern, "\", GetPathSeparator());
	
	Return PathPattern;
	
EndFunction

Function MetadataObjectDescriptionFilePathTemplate()
	
	If EDTConfiguration Then
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\[ObjectName].mdo";
	Else
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName].xml";
	EndIf;
	
	PathPattern = StrReplace(PathPattern, "\", GetPathSeparator());
	
	Return PathPattern;
	
EndFunction

Function PredefinedElementsDescriptionFilePathTemplate()
	
	If EDTConfiguration Then
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\[ObjectName].mdo";
	Else
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Ext\Predefined.xml";
	EndIf;
	
	PathPattern = StrReplace(PathPattern, "\", GetPathSeparator());
	
	Return PathPattern;
	
EndFunction

Function ObjectLayoutFilePathTemplate()
	
	If EDTConfiguration Then
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Templates\[TemplateName]\Template.txt";
	Else
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Templates\[TemplateName]\Ext\Template.txt";
	EndIf;
	
	PathPattern = StrReplace(PathPattern, "\", GetPathSeparator());
	
	Return PathPattern;
	
EndFunction

Function CommonModuleFilePathTemplate()
	
	If EDTConfiguration Then
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Module.bsl";
	Else
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Ext\Module.bsl";
	EndIf;
	
	PathPattern = StrReplace(PathPattern, "\", GetPathSeparator());
	
	Return PathPattern;
	
EndFunction

Function ObjectModuleFilePathTemplate()
	
	If EDTConfiguration Then
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\[ModuleType].bsl";
	Else
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Ext\[ModuleType].bsl";
	EndIf;
	
	PathPattern = StrReplace(PathPattern, "\", GetPathSeparator());
	
	Return PathPattern;
	
EndFunction

Function ObjectFormModuleFilePathTemplate()
	
	If EDTConfiguration Then
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Forms\[FormName]\Module.bsl";
	Else
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Forms\[FormName]\Ext\Form\Module.bsl";
	EndIf;
	
	PathPattern = StrReplace(PathPattern, "\", GetPathSeparator());
	
	Return PathPattern;
	
EndFunction

Function CommonFormModuleFilePathTemplate()
	
	If EDTConfiguration Then
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Module.bsl";
	Else
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Ext\Form\Module.bsl";
	EndIf;
	
	PathPattern = StrReplace(PathPattern, "\", GetPathSeparator());
	
	Return PathPattern;
	
EndFunction

Function ObjectCommandModuleFilePathTemplate()
	
	If EDTConfiguration Then
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Commands\[CommandName]\CommandModule.bsl";
	Else
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Commands\[CommandName]\Ext\CommandModule.bsl";
	EndIf;
	
	PathPattern = StrReplace(PathPattern, "\", GetPathSeparator());
	
	Return PathPattern;
	
EndFunction

Function CommonCommandModuleFilePathTemplate()
	
	If EDTConfiguration Then
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Module.bsl";
	Else
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Ext\Form\Module.bsl";
	EndIf;
	
	PathPattern = StrReplace(PathPattern, "\", GetPathSeparator());
	
	Return PathPattern;
	
EndFunction

Function CommandModuleFilePathTemplate()
	
	If EDTConfiguration Then 
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Commands\[CommandName]\CommandModule";
	Else
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Commands\[CommandName]\Ext\CommandModule";
	EndIf;
	
	PathPattern = StrReplace(PathPattern, "\", GetPathSeparator());
	
	Return PathPattern;
	
EndFunction

Function FormElementDescriptionFilePathTemplate()
	
	If EDTConfiguration Then 
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Forms\[FormName]\Form.form";
	Else
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Forms\[FormName]\Ext\Form.xml";
	EndIf;
	
	PathPattern = StrReplace(PathPattern, "\", GetPathSeparator());
	
	Return PathPattern;
	
EndFunction

Function CommonFormElementsDescriptionFilePathTemplate()
	
	If EDTConfiguration Then 
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Form.form";
	Else
		PathPattern = "[DumpDirectory][BaseTypeName]\[ObjectName]\Ext\Form.xml";
	EndIf;
	
	PathPattern = StrReplace(PathPattern, "\", GetPathSeparator());
	
	Return PathPattern;
	
EndFunction

Function CommonAttributeFilePathTemplate()
	
	If EDTConfiguration Then
		PathPattern = "[DumpDirectory]CommonAttributes\[ObjectName]\[ObjectName].mdo";
	Else
		PathPattern = "[DumpDirectory]CommonAttributes\[ObjectName].xml";
	EndIf;
	
	PathPattern = StrReplace(PathPattern, "\", GetPathSeparator());
	
	Return PathPattern;
	
EndFunction

#EndRegion

#Region MetadataFilePaths

Function RoleFileName()
	
	If EDTConfiguration Then 
		Return "Rights.rights";
	Else
		Return "Rights.xml"
	EndIf;
	
EndFunction

Function RoleFilesPath()
	
	Parameters = New Structure;
	Parameters.Insert("DumpDirectory", DumpDirectory);
	
	PathPattern = "[DumpDirectory]Roles";
	NameTemplate = StrReplace(PathPattern, "\", GetPathSeparator());
	
	Return StringFunctionsClientServer.InsertParametersIntoString(NameTemplate, Parameters);
	
EndFunction

// Parameters:
//  Role - String
//       - MetadataObjectRole
// 
// Returns:
//  String
//
Function RoleCompositionFilePath(Role)
	
	NameOfRole = ?(TypeOf(Role) = Type("MetadataObject"), Role.Name, Role);
	
	Parameters = New Structure;
	Parameters.Insert("DumpDirectory", DumpDirectory);
	Parameters.Insert("NameOfRole", NameOfRole);
	
	NameTemplate = RoleCompositionFilePathTemplate();
	
	Return StringFunctionsClientServer.InsertParametersIntoString(NameTemplate, Parameters);
	
EndFunction

// Parameters:
//  Role - String
//       - MetadataObjectRole
// 
// Returns:
//  String
//
Function RoleDescriptionFilePath(Role)
	
	NameOfRole = ?(TypeOf(Role) = Type("MetadataObject"), Role.Name, Role);
	
	Parameters = New Structure;
	Parameters.Insert("DumpDirectory", DumpDirectory);
	Parameters.Insert("NameOfRole", NameOfRole);
	
	NameTemplate = RoleElementsDescriptionFilePathTemplate();
	
	Return StringFunctionsClientServer.InsertParametersIntoString(NameTemplate, Parameters);
	
EndFunction

Function MetadataObjectDescriptionFilePath(MetadataObject)
	
	BaseTypeName = StrSplit(MetadataObject.FullName(), ".")[0];
	BaseTypeName = ObjectInFileUploadKindName[BaseTypeName];
	ObjectName = MetadataObject.Name;
	
	Parameters = New Structure;
	Parameters.Insert("DumpDirectory", DumpDirectory);
	Parameters.Insert("BaseTypeName", BaseTypeName);
	Parameters.Insert("ObjectName", ObjectName);
	
	NameTemplate = MetadataObjectDescriptionFilePathTemplate();
	
	Return StringFunctionsClientServer.InsertParametersIntoString(NameTemplate, Parameters);
	
EndFunction

Function PredefinedElementsDescriptionFilePath(MetadataObject)
	
	BaseTypeName = StrSplit(MetadataObject.FullName(), ".")[0];
	BaseTypeName = ObjectInFileUploadKindName[BaseTypeName];
	ObjectName = MetadataObject.Name;
	
	Parameters = New Structure;
	Parameters.Insert("DumpDirectory", DumpDirectory);
	Parameters.Insert("BaseTypeName", BaseTypeName);
	Parameters.Insert("ObjectName", ObjectName);
	
	NameTemplate = PredefinedElementsDescriptionFilePathTemplate();
	
	Return StringFunctionsClientServer.InsertParametersIntoString(NameTemplate, Parameters);
	
EndFunction

Function ObjectLayoutFilePath(Template)
	
	NameParts = StrSplit(Template.FullName(), ".");
	
	Parameters = New Structure;
	Parameters.Insert("DumpDirectory", DumpDirectory);
	Parameters.Insert("BaseTypeName", ObjectInFileUploadKindName[NameParts[0]]);
	Parameters.Insert("ObjectName", NameParts[1]);
	Parameters.Insert("TemplateName", Template.Name);
	
	NameTemplate = ObjectLayoutFilePathTemplate();
	
	Return StringFunctionsClientServer.InsertParametersIntoString(NameTemplate, Parameters);
	
EndFunction

Function CommonAttributeFilePath(CommonAttributeName)
	
	Parameters = New Structure;
	Parameters.Insert("DumpDirectory", DumpDirectory);
	Parameters.Insert("ObjectName", CommonAttributeName);
	
	NameTemplate = CommonAttributeFilePathTemplate();
	
	Return StringFunctionsClientServer.InsertParametersIntoString(NameTemplate, Parameters);
	
EndFunction

#EndRegion

#Region XPathExpressions

Function XPathExpressionTemplateSearch(TemplateName)
	
	XPathExpression = "/xmlns:Rights/xmlns:restrictionTemplate/xmlns:name[starts-with(text(), '" + TemplateName + "(') or text() = '" + TemplateName + "']/parent::*";
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionUsingTemplate(TemplateName)
	
	XPathExpression = "/xmlns:Rights/xmlns:object/xmlns:right/xmlns:restrictionByCondition/xmlns:condition[contains(text(), '#" + TemplateName + "(')]";
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionAccessRestriction()
	
	XPathExpression = "xmlns:restrictionByCondition/xmlns:condition";
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionObjectRights()
	
	XPathExpression = "xmlns:right/xmlns:name[text()='Read' or text()='Insert' or text()='Update']/parent::*";
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionRoleDescription()
	
	XPathExpression = "/xmlns:Rights";
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionRoleComposition()
	
	XPathExpression = "/xmlns:Rights/xmlns:object";
	
	Return XPathExpression;
	
EndFunction

Function ExpressionXPathBasicPropertyOfRole(RoleBasicProperty)
	
	XPathExpression = "/xmlns:Rights/xmlns:" + RoleBasicProperty;
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionConstraintPatterns()
	
	XPathExpression = "/xmlns:Rights/xmlns:restrictionTemplate/xmlns:name/parent::*";
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionFormList()
	
	If EDTConfiguration Then 
		XPathExpression = "/form:Form/attributes/main[text()='true']/parent::*/extInfo/mainTable";
	Else
		XPathExpression = "/xmlns:Form/xmlns:Attributes/xmlns:Attribute/xmlns:MainAttribute[text()='true']/parent::*/xmlns:Settings/xmlns:MainTable";
	EndIf;
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionMainAttributeFormType()
	
	If EDTConfiguration Then 
		XPathExpression = "/form:Form/attributes/main[text()='true']/parent::*/valueType";
	Else
		XPathExpression = "/xmlns:Form/xmlns:Attributes/xmlns:Attribute/xmlns:MainAttribute[text()='true']/parent::*/xmlns:Type/v8:Type";
	EndIf;
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionDefinedType()
	
	If EDTConfiguration Then 
		XPathExpression = "/mdclass:DefinedType/type";
	Else
		XPathExpression = "/xmlns:MetaDataObject/xmlns:DefinedType/xmlns:Properties/xmlns:Type";
	EndIf;
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionIsDefinedTypeComposition(TypeNameString)
	
	If EDTConfiguration Then 
		XPathExpression = "/mdclass:DefinedType/type/types[text()='" + TypeNameString + "']";
	Else
		XPathExpression = "/xmlns:MetaDataObject/xmlns:DefinedType/xmlns:Properties/xmlns:Type/v8:Type[text()='" + TypeNameString + "']";
	EndIf;
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionPredefinedData()
	
	If EDTConfiguration Then
		XPathExpression = "/mdclass:Catalog/predefined";
	Else
		XPathExpression = "/xmlns:PredefinedData";
	EndIf;
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionPredefinedCatalogElement(PredefinedItemName)
	
	If EDTConfiguration Then
		XPathExpression = "/mdclass:Catalog/predefined/items/name[text()='" + PredefinedItemName + "']";
	Else
		XPathExpression = "/xmlns:PredefinedData/xmlns:Item/xmlns:Name[text()='" + PredefinedItemName + "']";
	EndIf;
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionIncorrectPredefined(IDsOfPredefined)
	
	If EDTConfiguration Then
		XPathExpression = "/mdclass:Catalog/predefined/items[contains('" + StrConcat(IDsOfPredefined, ";") + "', name) = false]";
	Else
		XPathExpression = "/xmlns:PredefinedData/xmlns:Item[contains('" + StrConcat(IDsOfPredefined, ";") + "', xmlns:Name) = false]";
	EndIf;
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionPredefinedName()
	
	If EDTConfiguration Then
		Return "name";
	Else
		Return "xmlns:Name";
	EndIf;
	
EndFunction

Function XPathExpressionCatalogAttribute(AttributeName)
	
	If EDTConfiguration Then
		XPathExpression = "/mdclass:Catalog/attributes/name[text()='"
			+ AttributeName + "']/parent::*";
	Else
		XPathExpression = "/xmlns:MetaDataObject/xmlns:Catalog/xmlns:ChildObjects/xmlns:Attribute/xmlns:Properties/xmlns:Name[text()='"
			+ AttributeName + "']/parent::*";
	EndIf;
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionCatalogAttributeProperty(AttributeName, PropertyValueName)
	
	If EDTConfiguration Then
		XPathExpression = "/mdclass:Catalog/attributes/name[text()='"
			+ AttributeName + "']/parent::*/" + PropertyValueName;
	Else
		XPathExpression = "/xmlns:MetaDataObject/xmlns:Catalog/xmlns:ChildObjects/xmlns:Attribute/xmlns:Properties/xmlns:Name[text()='"
			+ AttributeName + "']/parent::*/xmlns:" + PropertyValueName;
	EndIf;
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionCatalogAttributeType(AttributeName)
	
	If EDTConfiguration Then
		XPathExpression = XPathExpressionCatalogAttributeProperty(AttributeName, "type");
	Else
		XPathExpression = XPathExpressionCatalogAttributeProperty(AttributeName, "Type");
	EndIf;
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionRegisterDimensionTypes(DimensionName)
	
	If EDTConfiguration Then
		XPathExpression = "/mdclass:InformationRegister/dimensions/name[text()='" + DimensionName + "']/parent::*/type";
	Else
		XPathExpression = "/xmlns:MetaDataObject/xmlns:InformationRegister/xmlns:ChildObjects/xmlns:Dimension/xmlns:Properties/xmlns:Name[text()='" + DimensionName + "']/parent::*/xmlns:Type";
	EndIf;
	
	Return XPathExpression;
	
EndFunction

Function XPathExpressionMetadataByName(FullName)
	
	If EDTConfiguration Then
		Return "//metadata[text() = '" + FullName + "']";
	Else
		Return "//xr:Metadata[text() = '" + FullName + "']";
	EndIf;
	
EndFunction

Function XPathExpressionValueAutoUseProperty()
	
	If EDTConfiguration Then
		Return "//autoUse";
	Else
		Return "//xmlns:AutoUse";
	EndIf;
	
EndFunction

Function XPathExpressionCommonAttributesComposition()
	
	If EDTConfiguration Then 
		Return "/mdclass:CommonAttribute";
	Else
		Return "//xmlns:Content";
	EndIf;
	
EndFunction

Function XPathExpressionValueRoleObjectName()
	
	Return "xmlns:name";
	
EndFunction

Function XPathExpressionValueTemplateName()
	
	Return "xmlns:name";
	
EndFunction

Function XPathExpressionValueTemplateText()
	
	Return "xmlns:condition";
	
EndFunction

Function XPathExpressionUsingCommonAttributesCompositionElement(CompositionElementFullName)
	
	If EDTConfiguration Then 
		Expression = "/mdclass:CommonAttribute/content/metadata[text() = '%1']/parent::*/use";
	Else
		Expression = "//xmlns:Content/xr:Item/xr:Metadata[text() = '%1']/parent::*/xr:Use";
	EndIf;
	
	Expression = StrReplace(Expression, "%1", CompositionElementFullName);
	
	Return Expression;
	
EndFunction

#EndRegion

#Region ConfigurationNodesProperties

Function StringQualifierProperty()
	
	If EDTConfiguration Then
		Return "stringQualifiers";
	Else
		Return "v8:StringQualifiers";
	EndIf;
	
EndFunction

Function StringLengthProperty()
	
	If EDTConfiguration Then
		Return "length";
	Else
		Return "v8:Length";
	EndIf
	
EndFunction

Function AllowedStringLengthProperty()
	
	If EDTConfiguration Then
		Return "fixed";
	Else
		Return "v8:AllowedLength";
	EndIf;
	
EndFunction

Function DateQualifierProperty()
	
	If EDTConfiguration Then
		Return "dateQualifiers";
	Else
		Return "v8:DateQualifiers";
	EndIf;
	
EndFunction

Function DateCompositionProperty()
	
	If EDTConfiguration Then
		Return "dateFractions";
	Else
		Return "v8:DateFractions";
	EndIf;
	
EndFunction

Function NumberQualifierProperty()
	
	If EDTConfiguration Then
		Return "numberQualifiers";
	Else
		Return "v8:NumberQualifiers";
	EndIf;
	
EndFunction

Function NumberBitnessProperty()
	
	If EDTConfiguration Then
		Return "precision";
	Else
		Return "v8:Digits";
	EndIf;
	
EndFunction

Function NumberFractionalPartBitnessProperty()
	
	If EDTConfiguration Then
		Return "scale";
	Else
		Return "v8:FractionDigits";
	EndIf;
	
EndFunction

Function ValidNumberSignProperty()
	
	If EDTConfiguration Then
		Return "nonNegative";
	Else
		Return "v8:AllowedSign";
	EndIf;
	
EndFunction

Function PropertyType()
	
	If EDTConfiguration Then
		Return "types";
	Else
		Return "v8:Type";
	EndIf;
	
EndFunction

Function MetadataUsageProperty()
	
	If EDTConfiguration Then
		Return "use";
	Else
		Return "xr:Use";
	EndIf;
	
EndFunction

Function MetadataProperty()
	
	If EDTConfiguration Then
		Return "metadata";
	Else
		Return "xr:Metadata";
	EndIf;
	
EndFunction

Function ConditionalSeparationOfCommonAttributeProperty()
	
	If EDTConfiguration Then
		Return "conditionalseparation";
	Else
		Return "xr:ConditionalSeparation";
	EndIf;
	
EndFunction

Function CommonAttributeCompositionElementProperty()
	
	Return "xr:Item";
	
EndFunction

Function CommonAttributeCompositionProperty()
	
	If EDTConfiguration Then
		Return "content";
	Else
		Return "Content";
	EndIf;
	
EndFunction

Function PredefinedDataDetailsProperty()
	
	If EDTConfiguration Then
		Return "items";
	Else
		Return "Item";
	EndIf;
	
EndFunction

Function FullTextSearchProperty()

	If EDTConfiguration Then
		Return "fullTextSearch";
	Else
		Return "FullTextSearch";
	EndIf;
	
EndFunction

Function IndexingProperty()

	If EDTConfiguration Then
		Return "indexing";
	Else
		Return "Indexing";
	EndIf;
	
EndFunction

Function CheckFillingProperty()

	If EDTConfiguration Then
		Return "fillChecking";
	Else
		Return "FillChecking";
	EndIf;
	
EndFunction 

Function NameProperty()
	
	If EDTConfiguration Then
		Return "name";
	Else
		Return "Name";
	EndIf;
	
EndFunction

Function CodeProperty()
	
	If EDTConfiguration Then
		Return "code";
	Else
		Return "Code";
	EndIf;
	
EndFunction

Function CodeValueProperty()
	
	If EDTConfiguration Then
		Return "value";
	Else
		Return "";
	EndIf;
	
EndFunction

Function DescriptionProperty()
	
	Return "Description";
	
EndFunction

Function IsGroupProperty()
	
	Return "IsFolder";
	
EndFunction

Function RoleRightProperty()
	
	Return "Rights";
	
EndFunction

Function RoleObjectProperty()
	
	Return "object";
	
EndFunction

Function RoleObjectNameProperty()
	
	Return "name";
	
EndFunction

Function RoleObjectRightProperty()
	
	Return "right";
	
EndFunction

Function RightsNameProperty()
	
	Return "name";
	
EndFunction

Function RightValueProperty()
	
	Return "value";
	
EndFunction

Function RoleObjectRestrictionProperty()
	
	Return "restrictionByCondition";
	
EndFunction

Function ObjectRestrictionConditionProperty()
	
	Return "condition";
	
EndFunction

Function ObjectRestrictionFieldProperty()
	
	Return "field";
	
EndFunction

Function RoleTemplateProperty()
	
	Return "restrictionTemplate";
	
EndFunction

Function RoleTemplateNameProperty()
	
	Return "name";
	
EndFunction

Function RoleTemplateTextProperty()
	
	Return "condition";
	
EndFunction

Function SetRightsForNewObjectsProperty()
	
	Return "setForNewObjects";
	
EndFunction

Function SetRightsForDetailsAndTablePartsByDefaultProperty()
	
	Return "setForAttributesByDefault";
	
EndFunction

Function IndependentSubordinateObjectsRightsProperty()
	
	Return "independentRightsOfChildObjects";
	
EndFunction

#EndRegion

#Region MeaningOfConfigurationNodes

Function AllowedStringLengthString(AllowedStringLengthValue)
	
	If EDTConfiguration Then
		If AllowedStringLengthValue = AllowedLength.Fixed Then
			AllowedStringLengthString = "true";
		Else
			AllowedStringLengthString = "";
		EndIf;
	Else
		AllowedStringLengthString = XMLString(AllowedStringLengthValue);
	EndIf;
	
	Return AllowedStringLengthString;
	
EndFunction

Function AllowedStringLengthValue(AllowedStringLengthString)
	
	If EDTConfiguration Then
		If IsBlankString(AllowedStringLengthString) Then
			AllowedStringLengthValue = AllowedLength.Variable;
		Else
			AllowedStringLengthValue = AllowedLength.Fixed;
		EndIf;
	Else
		AllowedStringLengthValue = XMLValue(Type("AllowedLength"), AllowedStringLengthString);
	EndIf;
	
	Return AllowedStringLengthValue;
	
EndFunction

Function StringLengthString(StringLengthValue)
	
	StringLengthString = XMLString(StringLengthValue);
	If EDTConfiguration And StringLengthValue = 0 Then
		StringLengthString = "";
	EndIf;
	
	Return StringLengthString;
	
EndFunction

Function StringLengthValue(StringLengthString)
	
	If IsBlankString(StringLengthString) Then
		StringLengthValue = 0;
	Else
		StringLengthValue = XMLValue(Type("Number"), StringLengthString);
	EndIf;
	
	Return StringLengthValue;
	
EndFunction

Function ValidNumberSignString(ValidNumberSignValue)
	
	If EDTConfiguration Then
		If ValidNumberSignValue = AllowedSign.Nonnegative Then
			ValidNumberSignString = "true";
		Else
			ValidNumberSignString = "";
		EndIf;
	Else
		ValidNumberSignString = XMLString(ValidNumberSignValue);
	EndIf;
	
	Return ValidNumberSignString;
	
EndFunction

Function ValidNumberSignValue(ValidNumberSignString)
	
	If EDTConfiguration Then
		If IsBlankString(ValidNumberSignString) Then
			ValidNumberSignValue = AllowedSign.Any;
		Else
			ValidNumberSignValue = AllowedSign.Nonnegative;
		EndIf;
	Else
		ValidNumberSignValue = XMLValue(Type("AllowedSign"), ValidNumberSignString);
	EndIf;
	
	Return ValidNumberSignValue;
	
EndFunction

Function DigitNumberString(DigitNumberValue)
	
	DigitNumberString = XMLString(DigitNumberValue);
	
	Return DigitNumberString;
	
EndFunction

Function DigitNumberValue(DigitNumberString)
	
	DigitNumberValue = XMLValue(Type("Number"), DigitNumberString);
	
	Return DigitNumberValue;
	
EndFunction

Function FractionalPartBitDepthString(BitDepthOfFractionalPartValue)
	
	FractionalPartBitDepthString = XMLString(BitDepthOfFractionalPartValue);
	If EDTConfiguration And BitDepthOfFractionalPartValue = 0 Then
		FractionalPartBitDepthString = "";
	EndIf;
	
	Return FractionalPartBitDepthString;
	
EndFunction

Function BitDepthOfFractionalPartValue(FractionalPartBitDepthString)
	
	If IsBlankString(FractionalPartBitDepthString) Then
		BitDepthOfFractionalPartValue = 0;
	Else
		BitDepthOfFractionalPartValue = XMLValue(Type("Number"), FractionalPartBitDepthString);
	EndIf;
	
	Return BitDepthOfFractionalPartValue;
	
EndFunction

Function DateStringParts(DatePartsValue)
	
	DateStringParts = XMLString(DatePartsValue);
	If EDTConfiguration And DatePartsValue = DateFractions.DateTime Then
		DateStringParts = "";
	EndIf;
	
	Return DateStringParts;
	
EndFunction

Function DatePartsValue(DateStringParts)
	
	If IsBlankString(DateStringParts) Then
		DatePartsValue = DateFractions.DateTime;
	Else
		DatePartsValue = XMLValue(Type("DateFractions"), DateStringParts)
	EndIf;
	
	Return DatePartsValue;
	
EndFunction

Function TypeNameString(Type, DOMDocument)
	
	If EDTConfiguration Then
		TypeNameString = "";
		If Type = Type("String") Then
			TypeNameString = "String";
		ElsIf Type = Type("Number") Then
			TypeNameString = "Number";
		ElsIf Type = Type("Date") Then
			TypeNameString = "Date";
		ElsIf Type = Type("Boolean") Then
			TypeNameString = "Boolean";
		EndIf;
		If Not IsBlankString(TypeNameString) Then
			Return TypeNameString;
		EndIf;
	EndIf;
	
	XMLType = XMLType(Type);
	If ValueIsFilled(XMLType.NamespaceURI) Then
		Prefix = DOMDocument.LookupPrefix(XMLType.NamespaceURI);
	Else
		Prefix = "cfg";
	EndIf;
	
	Return TypeNameWithStringPrefix(XMLType.TypeName, Prefix);
	
EndFunction

Function TypeNameWithStringPrefix(TypeName, Prefix)
	
	If EDTConfiguration Then
		Return TypeName;
	Else
		Return Prefix + ":" + TypeName;
	EndIf;
	
EndFunction

#EndRegion

Procedure SetConfigurationUploadDirectory(ConfigurationUploadDirectory)
	
	If FindFiles(ConfigurationUploadDirectory, "Configuration.xml").Count() = 0 Then
		If FindFiles(ConfigurationUploadDirectory, ".project").Count() = 0 Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Указанный каталог выгрузки ""%1"" не содержит файлов выгрузки конфигурации.';
																							|en = 'Specified ""%1"" export directory does not contain configuration export files.';"), ConfigurationUploadDirectory);
		Else
			EDTConfiguration = True;
			DumpDirectory = CommonClientServer.AddLastPathSeparator(CommonClientServer.AddLastPathSeparator(ConfigurationUploadDirectory) + "src");
		EndIf;
	Else
		EDTConfiguration = False;
		DumpDirectory = CommonClientServer.AddLastPathSeparator(ConfigurationUploadDirectory);
	EndIf;
	
EndProcedure

#EndRegion

#Region CheckingConfigurationRootModules

Function TableOfSupportedSSLCallsInRootModuleEventHandlers()
	
	TableOfSupportedSSLCalls = New ValueTable;
	TableOfSupportedSSLCalls.Columns.Add("RootModuleName");
	TableOfSupportedSSLCalls.Columns.Add("EventHandlerName");
	TableOfSupportedSSLCalls.Columns.Add("ValidSSLProcedureCall");
	
	NewCallString = TableOfSupportedSSLCalls.Add();
	NewCallString.RootModuleName = "ManagedApplicationModule";
	NewCallString.EventHandlerName = "BeforeStart";
	NewCallString.ValidSSLProcedureCall = "#If MobileClient Then
													|Execute(""StandardSubsystemsClient.BeforeStart()"");
													|#Else
													|StandardSubsystemsClient.BeforeStart();
													|#EndIf";
	
	NewCallString = TableOfSupportedSSLCalls.Add();
	NewCallString.RootModuleName = "ManagedApplicationModule";
	NewCallString.EventHandlerName = "BeforeStart";
	NewCallString.ValidSSLProcedureCall = "#If MobileClient Then
													|If MainServerAvailable() = False Then
													|Return;
													|EndIf;
													|#EndIf";
	
	NewCallString = TableOfSupportedSSLCalls.Add();
	NewCallString.RootModuleName = "ManagedApplicationModule";
	NewCallString.EventHandlerName = "OnStart";
	NewCallString.ValidSSLProcedureCall = "#If MobileClient Then
													|Execute(""StandardSubsystemsClient.OnStart()"");
													|#Else
													|StandardSubsystemsClient.OnStart();
													|#EndIf";
	
	NewCallString = TableOfSupportedSSLCalls.Add();
	NewCallString.RootModuleName = "ManagedApplicationModule";
	NewCallString.EventHandlerName = "BeforeExit";
	NewCallString.ValidSSLProcedureCall = "#If MobileClient Then
													|Execute(""StandardSubsystemsClient.BeforeExit(Cancel, WarningText)"");
													|#Else
													|StandardSubsystemsClient.BeforeExit(Cancel, WarningText);
													|#EndIf";
	
	NewCallString = TableOfSupportedSSLCalls.Add();
	NewCallString.RootModuleName = "OrdinaryApplicationModule";
	NewCallString.EventHandlerName = "BeforeStart";
	NewCallString.ValidSSLProcedureCall = "#If MobileClient Then
													|If MainServerAvailable() = False Then
													|Return;
													|EndIf;
													|#EndIf";
	
	NewCallString = TableOfSupportedSSLCalls.Add();
	NewCallString.RootModuleName = "OrdinaryApplicationModule";
	NewCallString.EventHandlerName = "BeforeStart";
	NewCallString.ValidSSLProcedureCall = "#If MobileClient Then
													|Execute(""StandardSubsystemsClient.BeforeStart()"");
													|#Else
													|StandardSubsystemsClient.BeforeStart();
													|#EndIf";
	
	NewCallString = TableOfSupportedSSLCalls.Add();
	NewCallString.RootModuleName = "OrdinaryApplicationModule";
	NewCallString.EventHandlerName = "OnStart";
	NewCallString.ValidSSLProcedureCall = "#If MobileClient Then
													|Execute(""StandardSubsystemsClient.OnStart()"");
													|#Else
													|StandardSubsystemsClient.OnStart();
													|#EndIf";
	
	NewCallString = TableOfSupportedSSLCalls.Add();
	NewCallString.RootModuleName = "OrdinaryApplicationModule";
	NewCallString.EventHandlerName = "BeforeExit";
	NewCallString.ValidSSLProcedureCall = "#If MobileClient Then
													|Execute(""StandardSubsystemsClient.BeforeExit(Cancel, WarningText)"");
													|#Else
													|StandardSubsystemsClient.BeforeExit(Cancel, WarningText);
													|#EndIf";
	
	NewCallString = TableOfSupportedSSLCalls.Add();
	NewCallString.RootModuleName = "SessionModule";
	NewCallString.EventHandlerName = "SessionParametersSetting";
	NewCallString.ValidSSLProcedureCall = "StandardSubsystemsServer.SessionParametersSetting(";
	
	Return TableOfSupportedSSLCalls;
	
EndFunction

Procedure CheckConfigurationRootModules()
	
	ConfigurationRootExportDir = DirAddPathSeparators(DumpDirectory) + "Ext";
	ConfigurationRootExportDir = DirAddPathSeparators(ConfigurationRootExportDir);
	
	ConfigurationRootModules = New Structure;
	ConfigurationRootModules.Insert("ManagedApplicationModule", "ManagedApplicationModule.bsl");
	ConfigurationRootModules.Insert("OrdinaryApplicationModule", "OrdinaryApplicationModule.bsl");
	ConfigurationRootModules.Insert("SessionModule", "SessionModule.bsl");
	
	TableOfSupportedSSLCalls = TableOfSupportedSSLCallsInRootModuleEventHandlers();
	
	For Each KeyAndValue In ConfigurationRootModules Do
		
		FileName = KeyAndValue.Value;
		FullFileName = ConfigurationRootExportDir + FileName;
		
		ModuleText = ReadModuleText(FullFileName);
		If IsBlankString(ModuleText) Then
			Continue;
		EndIf;
		
		ModuleName = KeyAndValue.Key;
		
		StructureOfFilterByRootModule = New Structure;
		StructureOfFilterByRootModule.Insert("RootModuleName", ModuleName);
		TableOfAvailableSSLCallsByModule = TableOfSupportedSSLCalls.Copy(StructureOfFilterByRootModule);
		
		If ModuleName = "ManagedApplicationModule"
		 Or ModuleName = "OrdinaryApplicationModule" Then
			
			CheckAreaOfAppModuleVars(ModuleText, ModuleName);
		EndIf;
		
		CheckRootModuleHandlers(ModuleText, ModuleName, TableOfAvailableSSLCallsByModule);
		
	EndDo;
	
EndProcedure

Procedure CheckAreaOfAppModuleVars(ModuleText, ModuleName)
	
	If ModuleName = "ManagedApplicationModule" Then
		NameOfModuleForOutput = NStr("ru = 'Модуль управляемого приложения';
									|en = 'Managed application module';");
	ElsIf ModuleName = "OrdinaryApplicationModule" Then
		NameOfModuleForOutput = NStr("ru = 'Модуль обычного приложения';
									|en = 'Ordinary application module';");
	Else
		Return;
	EndIf;
	
	TextVariablesDetailsArea = Upper(AreaKeyword() + "Variables");
	
	ModuleTextWithoutSpaces = ModuleText;
	ModuleTextWithoutSpaces = StrReplace(ModuleTextWithoutSpaces, Chars.Tab, "");
	ModuleTextWithoutSpaces = StrReplace(ModuleTextWithoutSpaces, " ", "");
	ModuleTextWithoutSpaces = Upper(ModuleTextWithoutSpaces);
	
	SearchPosition = 0;
	While True Do
		
		VarDetailsSectionLineNum = 0;
		SearchPosition = StrFind(ModuleTextWithoutSpaces, TextVariablesDetailsArea,, SearchPosition + 1);
		If SearchPosition = 0 Then
			Break;
		EndIf;
		
		VarDetailsSectionLineNum = GetModuleLineNum(ModuleTextWithoutSpaces, SearchPosition);
		StringOfVariablesDetailsSection = StrGetLine(ModuleTextWithoutSpaces, VarDetailsSectionLineNum);
		
		If StringOfVariablesDetailsSection = TextVariablesDetailsArea Then
			Break;
		EndIf;
		
	EndDo;
	
	If VarDetailsSectionLineNum = 0 Then
		BriefErrorDetails = NStr("ru = 'Область описания переменных не существует.';
									|en = 'A variable description area does not exist.';");
		DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не существует область описания переменных, в котором должна быть определена переменная %1.';
				|en = 'A variable description area where the %1 variable must be determined does not exist.';"),
			"ApplicationParameters");
		AddError(NameOfModuleForOutput, BriefErrorDetails, DetailedErrorDetails);
		Return;
	EndIf;
	
	TextVar = Upper("Var");
	
	GlobalVariables = New Array;
	GlobalVariables.Add(Upper("ApplicationParameters"));
	
	IsAppSettingsVariableDefined = False;
	
	TextDocModuleText = New TextDocument;
	TextDocModuleText.SetText(ModuleText);
	RowsCount = TextDocModuleText.LineCount();
	
	For LineNumber = VarDetailsSectionLineNum + 1 To RowsCount Do
		
		CurrentRow = TextDocModuleText.GetLine(LineNumber);
		CurrentRow = TrimAll(CurrentRow);
		
		If IsBlankString(CurrentRow) Or StrStartsWith(CurrentRow, "//") Then
			Continue;
		EndIf;
		
		If StrStartsWith(CurrentRow, "#EndRegion") Then
			If Not IsAppSettingsVariableDefined Then
				BriefErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не определена обязательная переменная %1.';
						|en = 'The required %1 variable is not determined.';"), "ApplicationParameters");
				DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В области описания переменных не определена обязательная переменная:
					           |
					           |%1';
								|en = 'A required variable is not defined in the variable description area:
								|
								|%1';"),
					"Var ApplicationParameters Export;");
				AddError(NameOfModuleForOutput, BriefErrorDetails, DetailedErrorDetails);
			EndIf;
			Break;
		EndIf;
		
		For Each VariableSearchedFor In GlobalVariables Do
			For Each ArrayElement In StrSplit(CurrentRow, ",", False) Do
				
				Substring = StrReplace(Upper(ArrayElement), TextVar, "");
				Substring = TrimAll(Substring);
				If StrStartsWith(Substring, VariableSearchedFor) Then
					IsAppSettingsVariableDefined = True;
					Continue;
				EndIf;
				
				BriefErrorDetails = NStr("ru = 'Нерекомендуемые переменные в области описания переменных.';
											|en = 'Not recommended variables in the variable description area.';");
				DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Нерекомендуемые переменные в области описания переменных, стр. %1:
				               |
				               |%2
				               |
				               |В области описания переменных рекомендуется размещать только одну переменную (и не использовать другие переменные):
				               |
				               |%3';
								|en = 'Not recommended variables in the variable description area, page %1:
								|
								|%2
								|
								|It is recommended to place only one variable in the variable description area and not to use other variables:
								|
								|%3';"),
					LineNumber,
					CurrentRow,
					"Var ApplicationParameters Export;");
				AddError(NameOfModuleForOutput, BriefErrorDetails, DetailedErrorDetails);
				
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

Procedure CheckRootModuleHandlers(ModuleText, ModuleName, TableOfSupportedSSLCalls)
	
	If ModuleName = "ManagedApplicationModule" Then
		NameOfModuleForOutput = NStr("ru = 'Модуль управляемого приложения';
									|en = 'Managed application module';");
		TextTemplateDetailedErrorDescription =
			NStr("ru = 'В модуле управляемого приложения не существует обязательный обработчик %1.';
				|en = 'The required %1 handler does not exist in the managed application module.';");
		
	ElsIf ModuleName = "OrdinaryApplicationModule" Then
		NameOfModuleForOutput = NStr("ru = 'Модуль обычного приложения';
									|en = 'Ordinary application module';");
		TextTemplateDetailedErrorDescription =
			NStr("ru = 'В модуле обычного приложения не существует обязательный обработчик %1.';
				|en = 'The required %1 handler does not exist in the ordinary application module.';");
		
	ElsIf ModuleName = "SessionModule" Then
		NameOfModuleForOutput = NStr("ru = 'Модуль сеанса';
									|en = 'Session module';");
		TextTemplateDetailedErrorDescription =
			NStr("ru = 'В модуле сеанса не существует обязательный обработчик %1.';
				|en = 'The required %1 handler does not exist in the session module.';");
	Else
		Return;
	EndIf;
	
	TextProcedure = "Procedure";
	TextProcedureEnd = "EndProcedure";
	
	TableOfCalls = CreateTablesOfCalls();
	
	TextTemplateBriefErrorDetails = NStr("ru = 'Не существует обязательный обработчик %1.';
											|en = 'The required %1 handler does not exist.';");
	
	TableOfHandlersToCheck = TableOfSupportedSSLCalls.Copy();
	TableOfHandlersToCheck.GroupBy("EventHandlerName");
	
	ModuleTextBuffer = Upper(ModuleText);
	ModuleTextBuffer = StrReplace(ModuleTextBuffer, Chars.Tab, "");
	ModuleTextBuffer = StrReplace(ModuleTextBuffer, " ", "");
	For Each TheStringOfTheHandlerBeingChecked In TableOfHandlersToCheck Do
		
		TheHandlerBeingChecked = TheStringOfTheHandlerBeingChecked.EventHandlerName;
		SearchDesign = Upper(TextProcedure + TheHandlerBeingChecked + "(");
		
		HandlerStartPosition = 0;
		While True Do
			
			HandlerStartPosition = StrFind(ModuleTextBuffer, SearchDesign,, HandlerStartPosition + 1);
			If HandlerStartPosition = 0 Then
				Break;
			EndIf;
			
			PreviousChar = Mid(ModuleTextBuffer, HandlerStartPosition - 1, 1);
			If IsBlankString(PreviousChar) Then
				Break;
			EndIf;
			
		EndDo;
		
		If HandlerStartPosition = 0 Then
			DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
				TextTemplateDetailedErrorDescription, TheHandlerBeingChecked);
			BriefErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
				TextTemplateBriefErrorDetails, TheHandlerBeingChecked);
			AddError(NameOfModuleForOutput, BriefErrorDetails, DetailedErrorDetails);
			Continue;
		EndIf;
		
		HandlerEndPosition = 0;
		While True Do
			
			HandlerEndPosition = StrFind(ModuleTextBuffer, Upper(TextProcedureEnd),, HandlerStartPosition);
			If HandlerEndPosition = 0 Then
				Break;
			EndIf;
			
			PreviousChar = Mid(ModuleTextBuffer, HandlerEndPosition - 1, 1);
			If IsBlankString(PreviousChar) Then
				Break;
			EndIf;
			
		EndDo;
		
		If HandlerEndPosition = 0 Then
			DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
				TextTemplateDetailedErrorDescription, TheHandlerBeingChecked);
			BriefErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
				TextTemplateBriefErrorDetails, TheHandlerBeingChecked);
			AddError(NameOfModuleForOutput, BriefErrorDetails, DetailedErrorDetails);
			Continue;
		EndIf;
		
		HandlerStartLineNum = GetModuleLineNum(ModuleTextBuffer, HandlerStartPosition);
		NumberOfHandlerEndLine = GetModuleLineNum(ModuleTextBuffer, HandlerEndPosition);
		
		HandlerText = "";
		For LineNumber = HandlerStartLineNum + 1 To NumberOfHandlerEndLine - 1 Do
			
			HandlerRow = TrimAll(StrGetLine(ModuleText, LineNumber));
			If IsBlankString(HandlerRow)
				Or StrStartsWith(HandlerRow, "//") Then
				Continue;
			EndIf;
			
			HandlerText = HandlerText + HandlerRow + Chars.LF;
			
		EndDo;
		
		HandlerText = TrimAll(HandlerText);
		
		FIlterStructureByHandler = New Structure;
		FIlterStructureByHandler.Insert("EventHandlerName", TheHandlerBeingChecked);
		TableOfValidCallsByHandler = TableOfSupportedSSLCalls.Copy(FIlterStructureByHandler);
		For Each ValidCallRow In TableOfValidCallsByHandler Do
			
			ValidSSLProcedureCall = ValidCallRow.ValidSSLProcedureCall;
			
			CallPosition = StrFind(HandlerText, ValidSSLProcedureCall);
			If CallPosition = 0 Then
				BriefErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
					TextTemplateBriefErrorDetails, TheHandlerBeingChecked);
				DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(
					TextTemplateDetailedErrorDescription, TheHandlerBeingChecked);
				AddError(NameOfModuleForOutput, BriefErrorDetails, DetailedErrorDetails);
				Continue;
			EndIf;
			
			// Delete the lines of the handler.
			CallLineNum = GetModuleLineNum(HandlerText, CallPosition);
			CallLinesCount = StrLineCount(ValidSSLProcedureCall);
			
			// Delete the lines containing the acceptable call.
			DocumentHandlerText = New TextDocument;
			DocumentHandlerText.SetText(HandlerText);
			For ValidCallLineNumber = 1 To CallLinesCount Do
				DocumentHandlerText.ReplaceLine(CallLineNum + ValidCallLineNumber - 1, "");
			EndDo;
			
			HandlerText = DocumentHandlerText.GetText();
			
		EndDo;
		
		If IsBlankString(HandlerText) Then
			Continue;
		EndIf;
		
		HandlerText = TrimAll(HandlerText);
		HandlerLineCount = StrLineCount(HandlerText);
		
		FirstLineOfInvalidCall = "";
		For HandlerLineNumber = 1 To HandlerLineCount Do
			
			FirstLineOfInvalidCall = StrGetLine(HandlerText, HandlerLineNumber);
			FirstLineOfInvalidCall = TrimAll(FirstLineOfInvalidCall);
			
			If IsBlankString(FirstLineOfInvalidCall) Then
				Continue;
			EndIf;
			
			If StrStartsWith(FirstLineOfInvalidCall, "#") Then
				Continue;
			EndIf;
			
			Break;
			
		EndDo;
		
		InvalidCallPosition = StrFind(ModuleText, FirstLineOfInvalidCall,, HandlerStartPosition);
		If InvalidCallPosition > 0 Then
			InvalidCallLineNum = GetModuleLineNum(ModuleText, InvalidCallPosition);
		EndIf;
		
		NewCall = TableOfCalls.Add();
		NewCall.String = FirstLineOfInvalidCall;
		NewCall.LineNumber = InvalidCallLineNum;
		NewCall.AdditionalInformation = TheStringOfTheHandlerBeingChecked.EventHandlerName;
		
	EndDo;
	
	If ModuleName = "ManagedApplicationModule" Then
		TemplateOfFullErrorDetails =
			NStr("ru = 'Недопустимый вызов в обработчике %1 модуля управляемого приложения, стр. %2:';
				|en = 'Incorrect call in the %1 handler of the managed application module, page %2:';");
	ElsIf ModuleName = "OrdinaryApplicationModule" Then
		TemplateOfFullErrorDetails =
			NStr("ru = 'Недопустимый вызов в обработчике %1 модуля обычного приложения, стр. %2:';
				|en = 'Incorrect call in the %1 handler of the ordinary application module, page %2:';");
	ElsIf ModuleName = "SessionModule" Then
		TemplateOfFullErrorDetails =
			NStr("ru = 'Недопустимый вызов в обработчике %1 модуля сеанса, стр. %2:';
				|en = 'Incorrect call in the %1 handler of the session module, page %2:';");
	EndIf;
	
	TemplateOfFullErrorDetails = TemplateOfFullErrorDetails + Chars.LF + Chars.LF
		+ NStr("ru = '%3
		             |
		             |Для корректной последовательности запуска и завершения приложения в обработчиках модулей приложения и сеанса конфигурации должны быть только вызовы стандартных процедур согласно инструкции внедрения БСП.';
					|en = '%3
					|
					|To ensure the correct sequence of starting and closing the application, handlers of application modules and a configuration session must contain only calls to standard procedures, according to the SSL integration instruction.';");
	
	ClarifyAppModule = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'А прикладной код должен быть размещен в одноименном обработчике в общем модуле %1.';
			|en = 'Place the application code in the handler with the same name in the %1 common module.';"),
		"CommonClientOverridable");
	SessionModuleClarification = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'А прикладной код должен быть размещен в своем общем модуле и процедуре, ссылка на которую должна быть добавлена в процедуре %1 общего модуля %2.';
			|en = 'Place the application code in its common module and a procedure, whose reference must be added to the %1 procedure of the %2 common module.';"),
		"OnAddSessionParameterSettingHandlers",
		"CommonOverridable");
	
	For Each Call In TableOfCalls Do
		BriefErrorDetails =
			NStr("ru = 'Некорректное размещение кода обработки события модуля приложения.';
				|en = 'Incorrect code placement of the application module event processing.';");
		DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(TemplateOfFullErrorDetails,
			Call.AdditionalInformation, Call.LineNumber, Call.String);
		If Call.AdditionalInformation = "SessionParametersSetting" Then
			DetailedErrorDetails = DetailedErrorDetails + " " + SessionModuleClarification;
		Else
			DetailedErrorDetails = DetailedErrorDetails + " " + ClarifyAppModule;
		EndIf;
		AddError(NameOfModuleForOutput, BriefErrorDetails, DetailedErrorDetails);
	EndDo;
	
EndProcedure

// Returns the number of the line in the passed module text from the given character position.
//
// Parameters:
//   ModuleText  - String - Module text.
//   CharacterNumber - Number  - Character position in the module text.
//
// Returns:
//   Number - The number of the line the character belongs to.
//
Function GetModuleLineNum(ModuleText, CharacterNumber)
	
	TextBeforeChar = Left(ModuleText, CharacterNumber);
	LineNumber = StrLineCount(TextBeforeChar);
	
	Return LineNumber;
	
EndFunction

Function ModuleLastLine(Val ModuleText)
	
	DocumentText = New TextDocument;
	DocumentText.SetText(ModuleText);
	
	LastRowNumber = DocumentText.LineCount();
	Return DocumentText.GetLine(LastRowNumber);
	
EndFunction

Function DirAddPathSeparators(Val Directory)
	
	PathSeparator = GetPathSeparator();
	If Not StrEndsWith(Directory, PathSeparator) Then
		Directory = Directory + PathSeparator;
	EndIf;
	
	Return Directory;
	
EndFunction

Function CreateTablesOfCalls()
	
	TableOfCalls = New ValueTable;
	TableOfCalls.Columns.Add("LineNumber");
	TableOfCalls.Columns.Add("String");
	TableOfCalls.Columns.Add("AdditionalInformation");
	
	Return TableOfCalls;
	
EndFunction

#EndRegion

#EndRegion

#Region MultiThreadedCheck

// Runs the check in multi-threading mode with result handling.
//
// Parameters:
//   MethodName                       - String            - The name of the check procedure.
//   SSLSubsystem                   - String            - The name of the subsystem to be checked.
//   InitializationStructureStorage - ValueStorage - The storage containing the values of the variables located 
//                                                         in the report object module.
//
// Returns:
//   ValueTable - A table exported from the "CheckTable" report to a value table.
//
// ACC:581-off - An export function as it's called from a background job.
// ACC:299-off - Intended for multi-threaded execution.
// ACC:487-off - A safe call.
//
Function ResultOfSubsystemCheck(MethodName, SSLSubsystem, InitializationStructureStorage, Validation = Undefined) Export
	
	If GetCurrentInfoBaseSession().ApplicationName = "BackgroundJob" Then
		InstalledExtensions = New Structure(SessionParameters.InstalledExtensions);
		InstalledExtensions.Insert("ExtensionsUnavailable");
		SessionParameters.InstalledExtensions = New FixedStructure(InstalledExtensions);
	EndIf;
	
	ReportObjectModuleVariablesInitialization(InitializationStructureStorage, SSLSubsystem);
	
	ObjectsToCheck = AccessManagement_MetadataObjectsToCheck(Validation);
	
	Try
		Execute(MethodName); // ACC:486
	Except
		AddError(CheckedSubsystem, NStr("ru = 'Проверка внедрения подсистемы не выполнена:';
													|en = 'Subsystem integration is not checked:';"), ErrorInfo());
	EndTry;
	
	Result = New Structure;
	Result.Insert("CheckTable",  CheckTable.Unload());
	Result.Insert("FilesToUpload", FilesToUpload);
	
	Return Result;
	
EndFunction
// ACC:299-off, ACC:581-off, ACC-487-off

Procedure RunCheckInMultipleThreads(CheckedSubsystems, ProcedureNameTemplate, NoExtensions)
	
	FormIdentifier = New UUID();
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormIdentifier);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Проверка внедрения БСП';
															|en = 'SSL integration check';");
	ExecutionParameters.NoExtensions = NoExtensions;
	ExecutionParameters.WaitCompletion = Undefined; // Wait for completion or throw an exception.
	
	IsExternalReport = IsExternalReport(ExternalReportBinaryData);
	
	If IsExternalReport Then
		If Not ValueIsFilled(FullNameOfExternalReportFile) Then
			ExecutionParameters.ExternalReportDataProcessor = ExternalReportBinaryData;
		Else
			ExecutionParameters.ExternalReportDataProcessor = New Structure("BinaryData, FullFileName",
				ExternalReportBinaryData, FullNameOfExternalReportFile);
		EndIf;
		If ExternalReportBinaryData = Undefined
		   And Not (Common.FileInfobase()
		         And GetCurrentInfoBaseSession().ApplicationName = "BackgroundJob") Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Требуется заполнить реквизит %1 для запуска внешнего отчета %2,
				           |подключенного без использования полного пути к имени файла,
				           |а например из базы данных или временного хранилища.';
							|en = 'Fill in the %1 attribute to run the %2 external report
							|attached without the full path to the file name,
							|for example, from a database or temporary storage.';"),
				"ExternalReportBinaryData",
				"SSLImplementationCheck.erf");
			Raise ErrorText;
		EndIf;
	EndIf;
	
	MethodParameters = New Map;
	InitializationStructureStorage = New ValueStorage(ReportObjectModuleVariablesValuesStructure());
	
	For Each Subsystem In CheckedSubsystems Do
		SubsystemName = ?(TypeOf(CheckedSubsystems) = Type("Array"), Subsystem, Subsystem.Value);
		
		CheckedSubsystem = Metadata.Subsystems.StandardSubsystems.Subsystems.Find(SubsystemName);
		If CheckedSubsystem <> Undefined Then
			AddMultiThreadedOperationMethodParameter(MethodParameters, ProcedureNameTemplate, SubsystemName,
				InitializationStructureStorage);
		EndIf;
	EndDo;
	
	FunctionNameTemplate = "%1.SSLImplementationCheck.ObjectModule.ResultOfSubsystemCheck";
	FunctionName = StringFunctionsClientServer.SubstituteParametersToString(FunctionNameTemplate,
		?(IsExternalReport, "ExternalReport", "Report"));
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunctionInMultipleThreads(FunctionName,
		ExecutionParameters, MethodParameters);
	
	CheckTable.Clear();
	
	If ExecutionResult.Status <> "Completed2" Then
		If ExecutionResult.Status = "Error" Then
			BriefErrorDescription   = ExecutionResult.BriefErrorDescription;
			DetailErrorDescription = ExecutionResult.DetailErrorDescription;
		ElsIf ExecutionResult.Status = "Canceled" Then
			BriefErrorDescription = NStr("ru = 'Проверка отменена.';
												|en = 'The check is canceled.';");
			DetailErrorDescription = BriefErrorDescription;
		Else
			BriefErrorDescription = NStr("ru = 'Проверка завершилась неуспешно.';
												|en = 'The check failed.';");
			DetailErrorDescription = BriefErrorDescription;
		EndIf;
		AddError(Undefined, BriefErrorDescription,
			DetailErrorDescription,, True);
		Return;
	EndIf;
	
	AddressesOfChecksResults = GetFromTempStorage(ExecutionResult.ResultAddress);
	DeleteFromTempStorage(ExecutionResult.ResultAddress);
	If TypeOf(AddressesOfChecksResults) <> Type("Map") Then
		ErrorText = NStr("ru = 'Нет результатов проверки.';
							|en = 'There are no check results.';");
		Raise ErrorText;
	EndIf;
	
	For Each AddressValidationResult In AddressesOfChecksResults Do
		
		CheckResult = AddressValidationResult.Value;
		If CheckResult.Status <> "Completed2" Then
			If CheckResult.Status = "Error" Then
				ErrorText = CheckResult.DetailErrorDescription;
			ElsIf CheckResult.Status = "Canceled" Then
				ErrorText = NStr("ru = 'Проверка отменена.';
									|en = 'The check is canceled.';");
			Else
				ErrorText = NStr("ru = 'Проверка завершилась неуспешно.';
									|en = 'The check failed.';");
			EndIf;
			AddError(Undefined, AddressValidationResult.Key,
				ErrorText,, True);
			Continue;
		Else
			CheckResultTable = GetFromTempStorage(CheckResult.ResultAddress);
			DeleteFromTempStorage(CheckResult.ResultAddress);
			If TypeOf(CheckResultTable) <> Type("Structure") Then
				AddError(Undefined, AddressValidationResult.Key,
					NStr("ru = 'Нет результата проверки.';
						|en = 'There is no check result.';"),, True);
				Continue;
			EndIf;
		EndIf;
		
		For Each CheckResultTableRow In CheckResultTable.CheckTable Do
			FillPropertyValues(CheckTable.Add(), CheckResultTableRow);
		EndDo;
		
		CommonClientServer.SupplementArray(FilesToUpload, CheckResultTable.FilesToUpload);
		
	EndDo;
	
	CheckTable.Sort("MetadataObject Asc, SSLSubsystem Asc");
	
EndProcedure

Procedure AddMultiThreadedOperationMethodParameter(MethodParameters, ProcedureNameTemplate, SubsystemName,
		InitializationStructureStorage)
	
	ProcedureName = StrReplace(ProcedureNameTemplate, "[SubsystemName]", SubsystemName);
	ParametersArray = New Array;
	ParametersArray.Add(ProcedureName);
	ParametersArray.Add(SubsystemName);
	ParametersArray.Add(InitializationStructureStorage);
	
	MethodParameters.Insert(ProcedureName, ParametersArray);
	
	If StrCompare(SubsystemName, "AccessManagement") <> 0 Then
		Return;
	EndIf;
	
	ChecksForAccessManagementSubsystem = AccessManagement_ChecksArray();
	AccessManagement_ProcedureNameTemplate = "%1(%2)";
	
	For Each CheckInfoRecords In ChecksForAccessManagementSubsystem Do
		ProcedureName = StringFunctionsClientServer.SubstituteParametersToString(AccessManagement_ProcedureNameTemplate, 
			CheckInfoRecords.Value, "ObjectsToCheck");
		
		ParametersArray = New Array;
		ParametersArray.Add(ProcedureName);
		ParametersArray.Add(SubsystemName);
		ParametersArray.Add(InitializationStructureStorage);
		ParametersArray.Add(CheckInfoRecords.Key);
		
		MethodParameters.Insert(ProcedureName, ParametersArray);
	EndDo;
	
EndProcedure

Function ReportObjectModuleVariablesValuesStructure()
	
	ResultingStructure = New Structure;
	ResultingStructure.Insert("ExceptionsTable",                           ExceptionsTable);
	ResultingStructure.Insert("DumpDirectory",                             DumpDirectory);
	ResultingStructure.Insert("FilterBySubsystems",                          FilterBySubsystems);
	ResultingStructure.Insert("ValidMetadata",                        ValidMetadata);
	ResultingStructure.Insert("CorrectErrors",                            CorrectErrors);
	ResultingStructure.Insert("FilesToUpload",                            FilesToUpload);
	ResultingStructure.Insert("FixedErrors",                          FixedErrors);
	ResultingStructure.Insert("NonVerifiableConfigurationSubsystems",         NonVerifiableConfigurationSubsystems);
	ResultingStructure.Insert("InteractiveLaunch",                         InteractiveLaunch);
	ResultingStructure.Insert("MetadataObjectInConfigurationLanguageKindName", MetadataObjectInConfigurationLanguageKindName);
	ResultingStructure.Insert("ObjectInFileUploadKindName",               ObjectInFileUploadKindName);
	ResultingStructure.Insert("HasSeparatorsCompositionErrors",               HasSeparatorsCompositionErrors);
	ResultingStructure.Insert("EDTConfiguration",                             EDTConfiguration);
	
	Return ResultingStructure;
	
EndFunction

Procedure ReportObjectModuleVariablesInitialization(InitializationStructureStorage, SSLSubsystem)
	
	CheckedSubsystem = Metadata.Subsystems.StandardSubsystems.Subsystems.Find(SSLSubsystem);
	If CheckedSubsystem = Undefined Then
		Return;
	EndIf;
	
	If InitializationStructureStorage = Undefined Then
		Return;
	EndIf;
	
	InitializationStructure = InitializationStructureStorage.Get();
	
	ExceptionsTable                           = InitializationStructure.ExceptionsTable;
	DumpDirectory                             = InitializationStructure.DumpDirectory;
	FilterBySubsystems                          = InitializationStructure.FilterBySubsystems;
	ValidMetadata                        = InitializationStructure.ValidMetadata;
	CorrectErrors                            = InitializationStructure.CorrectErrors;
	FilesToUpload                            = InitializationStructure.FilesToUpload;
	FixedErrors                          = InitializationStructure.FixedErrors;
	NonVerifiableConfigurationSubsystems         = InitializationStructure.NonVerifiableConfigurationSubsystems;
	InteractiveLaunch                         = InitializationStructure.InteractiveLaunch;
	MetadataObjectInConfigurationLanguageKindName = InitializationStructure.MetadataObjectInConfigurationLanguageKindName;
	ObjectInFileUploadKindName               = InitializationStructure.ObjectInFileUploadKindName;
	HasSeparatorsCompositionErrors               = InitializationStructure.HasSeparatorsCompositionErrors;
	EDTConfiguration                             = InitializationStructure.EDTConfiguration;
	
	SubsystemsTree = New ValueTree;
	SubsystemsTree.Columns.Add("Subsystem");
	FillInSubsystemTree(Metadata.Subsystems, SubsystemsTree.Rows);
	
	TermsMap = MetadataObjectNamesMap();
	
	MatchingObjects = MatchingObjects();
	SSLSubsystemObjects = New Array;
	
	For Each Subsystem In Metadata.Subsystems Do
		FillInSubsystemObjects(Subsystem);
	EndDo;
	
EndProcedure

Function IsExternalReport(ExternalReportBinaryData)
	
	ObjectStructure = New Structure;
	ObjectStructure.Insert("UsedFileName", Undefined);
	FillPropertyValues(ObjectStructure, ThisObject);
	
	If ObjectStructure.UsedFileName = Undefined Then
		Return False;
	EndIf;
	
	If ExternalReportBinaryData <> Undefined Then
		Return True;
	EndIf;
	
	File = New File(ObjectStructure.UsedFileName);
	If File.Exists() Then
		ExternalReportBinaryData = New BinaryData(ObjectStructure.UsedFileName);
		FullNameOfExternalReportFile = ObjectStructure.UsedFileName;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region AccessManagement_SplitIntoThreads

Procedure Attachable_AccessControl_CheckTextInsertionInFormModule(MetadataObjectCollection)
	
	If Not VerificationIsRequired() Then
		Return;
	EndIf;
	
	Parameters = AccessControlImplementationVerificationParameters();
	AccessControl_AtReadingBasicSettings(Parameters);
	
	For Each MetadataObject In MetadataObjectCollection Do
		AccessControl_CheckTextInsertionInFormModule(Parameters, MetadataObject);
	EndDo;
	
EndProcedure

Procedure Attachable_AccessControl_CheckUseOfPredefinedInFormModule(MetadataObjectCollection)
	
	If Not VerificationIsRequired() Then
		Return;
	EndIf;
	
	For Each MetadataObject In MetadataObjectCollection Do
		AccessControl_CheckUseOfPredefinedInFormModule(MetadataObject);
	EndDo;
	
EndProcedure

Procedure Attachable_AccessControl_CheckUseOfPredefinedInSharedModule(MetadataObjectCollection)
	
	If Not VerificationIsRequired() Then
		Return;
	EndIf;
	
	For Each MetadataObject In MetadataObjectCollection Do
		AccessControl_CheckUseOfPredefinedInSharedModule(MetadataObject);
	EndDo;
	
EndProcedure

Procedure Attachable_AccessControl_CheckUsageOfPredefinedInObjectModules(MetadataObjectCollection)
	
	If Not VerificationIsRequired() Then
		Return;
	EndIf;
	
	For Each MetadataObject In MetadataObjectCollection Do
		AccessControl_CheckUsageOfPredefinedInObjectModules(MetadataObject);
	EndDo;
	
EndProcedure

Procedure Attachable_AccessControl_CheckUseOfPredefinedInModuleCommands(MetadataObjectCollection)
	
	If Not VerificationIsRequired() Then
		Return;
	EndIf;
	
	For Each MetadataObject In MetadataObjectCollection Do
		AccessControl_CheckUseOfPredefinedInModuleCommands(MetadataObject);
	EndDo;
	
EndProcedure

Procedure Attachable_AccessManagement_CheckProcedureInsertionUponFillAccessRestrictionsInObjectManagerModule(MetadataObjectCollection)
	
	If Not VerificationIsRequired() Then
		Return;
	EndIf;
	
	Parameters = AccessControlImplementationVerificationParameters();
	AccessControl_AtReadingBasicSettings(Parameters);
	
	For Each MetadataObject In MetadataObjectCollection Do
		CheckProcedureInsertionAtFillingAccessRestrictionInObjectManagerModule(Parameters, MetadataObject);
	EndDo;
	
EndProcedure

Function AccessManagement_ChecksArray()
	
	Checks = New Structure;
	Checks.Insert("CheckTextInsertInFormModule", "Attachable_AccessControl_CheckTextInsertionInFormModule");
	Checks.Insert("CheckPredefinedsUsageInFormModule", "Attachable_AccessControl_CheckUseOfPredefinedInFormModule");
	Checks.Insert("CheckUsageOfPredefinedsInCommonModule", "Attachable_AccessControl_CheckUseOfPredefinedInSharedModule");
	Checks.Insert("CheckUsageOfPredefinedsInObjectModules", "Attachable_AccessControl_CheckUsageOfPredefinedInObjectModules");
	Checks.Insert("CheckIfPredefinedsUsedInCommandModule", "Attachable_AccessControl_CheckUseOfPredefinedInModuleCommands");
	Checks.Insert("CheckProcedureInsertionAtFillingAccessRestrictionInObjectManagerModule", "Attachable_AccessManagement_CheckProcedureInsertionUponFillAccessRestrictionsInObjectManagerModule");
	
	Return Checks;
	
EndFunction

Function MetadataObjectsCollections()
	
	MetadataObjectsCollections = New Array;
	
	MetadataObjectsCollections.Add(Metadata.CommonModules);
	MetadataObjectsCollections.Add(Metadata.CommonForms);
	MetadataObjectsCollections.Add(Metadata.ExchangePlans);
	MetadataObjectsCollections.Add(Metadata.Catalogs);
	MetadataObjectsCollections.Add(Metadata.Documents);
	MetadataObjectsCollections.Add(Metadata.DocumentJournals);
	MetadataObjectsCollections.Add(Metadata.Reports);
	MetadataObjectsCollections.Add(Metadata.DataProcessors);
	MetadataObjectsCollections.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataObjectsCollections.Add(Metadata.ChartsOfAccounts);
	MetadataObjectsCollections.Add(Metadata.ChartsOfCalculationTypes);
	MetadataObjectsCollections.Add(Metadata.BusinessProcesses);
	MetadataObjectsCollections.Add(Metadata.Tasks);
	MetadataObjectsCollections.Add(Metadata.AccountingRegisters);
	MetadataObjectsCollections.Add(Metadata.AccumulationRegisters);
	MetadataObjectsCollections.Add(Metadata.CalculationRegisters);
	MetadataObjectsCollections.Add(Metadata.InformationRegisters);
	
	Return MetadataObjectsCollections;
	
EndFunction

Function AccessManagement_MetadataObjectsToCheck(Validation)
	
	If Not ValueIsFilled(Validation) Then
		Return Undefined;
	EndIf;
	
	Result = New Array;
	
	MetadataObjectsCollections = MetadataObjectsCollections();
	
	// Generate an individual array of object names for each of the checks.
	For Each MetadataObjectCollection In MetadataObjectsCollections Do
		For Each MetadataObject In MetadataObjectCollection Do
			
			If Metadata.CommonForms.Contains(MetadataObject) Then
				If Validation = "CheckTextInsertInFormModule"
				 Or Validation = "CheckPredefinedsUsageInFormModule" Then
					Result.Add(MetadataObject);
				EndIf;
				
			ElsIf Metadata.CommonCommands.Contains(MetadataObject) Then
				If Validation = "CheckIfPredefinedsUsedInCommandModule" Then
					Result.Add(MetadataObject);
				EndIf;
				
			ElsIf Metadata.CommonModules.Contains(MetadataObject) Then
				If Validation = "CheckUsageOfPredefinedsInCommonModule" Then
					Result.Add(MetadataObject);
				EndIf;
			Else
				If Validation = "CheckProcedureInsertionAtFillingAccessRestrictionInObjectManagerModule"
				 Or Validation = "CheckUsageOfPredefinedsInObjectModules" Then
					Result.Add(MetadataObject);
				EndIf;
				
				For Each Form In MetadataObject.Forms Do
					If Validation = "CheckTextInsertInFormModule"
					 Or Validation = "CheckPredefinedsUsageInFormModule" Then
						Result.Add(Form);
					EndIf;
				EndDo;
				
				For Each Command In MetadataObject.Commands Do
					If Validation = "CheckIfPredefinedsUsedInCommandModule" Then
						Result.Add(Command);
					EndIf;
				EndDo;
			EndIf;
			
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf
