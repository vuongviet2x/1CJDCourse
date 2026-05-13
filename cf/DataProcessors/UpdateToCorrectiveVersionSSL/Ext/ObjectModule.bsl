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

Var SSLObjects;
Var DOMDocument; // DOMDocument
Var NodeObjects;

#EndRegion

#Region Public

// Generates a compare/merge settings file to update to a hotfix version.
//
// Parameters:
//    SettingsFileName - String - Name of an XML file containing compare/merge settings.
//                                If a blank string is passed, it returns the name of the temporary file containing the settings.
//                                
//    CaptureFileName  - String - Name of an XML file containing a list of objects to be captured in the storage.
//                                If a blank string is passed, it returns the name of the temporary file containing the object list.
//                                
//
Procedure GenerateCompareMergeSettingsFile(SettingsFileName = "", CaptureFileName = "") Export
	
	If IsBlankString(SettingsFileName) Then
		// The calling code must delete the temporary file.
		SettingsFileName = GetTempFileName("xml");
	EndIf;
	
	If IsBlankString(CaptureFileName) Then
		// The calling code must delete the temporary file.
		CaptureFileName = GetTempFileName("xml");
	EndIf;
	
	TemplateFile1 = GetTempFileName("xml");
	TextWriter = New TextWriter(TemplateFile1);
	TextWriter.Write(GetTemplate("SettingsTemplate").GetText());
	TextWriter.Close();
	
	// Get a DOM document for the compare/join template file.
	DOMDocument = DOMDocument(TemplateFile1);
	DeleteFiles(TemplateFile1);
	
	// Settings section.
	Settings = DOMDocument.GetElementByTagName("Settings")[0];
	// 1C:Enterprise version depends on the SSL version and is specified in the template file.
	
	// MainConfiguration section.
	MainConfiguration = Settings.GetElementByTagName("MainConfiguration")[0];
	Name = MainConfiguration.GetElementByTagName("Name")[0];
	Name.TextContent = Metadata.Name;
	Version = MainConfiguration.GetElementByTagName("Version")[0];
	Version.TextContent = Metadata.Version;
	Vendor = MainConfiguration.GetElementByTagName("Vendor")[0];
	Vendor.TextContent = Metadata.Vendor;
	
	// Skip population of sections SupportRules, Parameters, Conformities, and Conformities. Instead, set the default values.
	
	// Objects section.
	NodeObjects = DOMDocument.GetElementByTagName("Objects")[0];
	
	SelectSubsystemsCheckBoxes(CaptureFileName);
	SelectOverridableModulesCheckBoxes();
	SelectRolesCheckBoxes();
	SelectSeparatorsCheckBoxes();
	SelectFilterCriteriaCheckBoxes();
	SelectCheckBoxesOfTypesToDefine();
	SelectCommonCommandsCheckBoxes();
	SelectLanguagesCheckBoxes();
	SelectCatalogsCheckBoxes();
	SelectExchangePlansCheckBoxes();
	SelectEnumerationsCheckBoxes();
	SelectChartOfCharacteristicTypesCheckBoxes();
	SelectBusinessProcessesCheckBoxes();
	SelectFunctionalOptionsCheckBoxes();
	
	WriteDOMDocumentToFile(SettingsFileName);
	
EndProcedure

// Compares or merges a configuration with a new supplier configuration.
//
// Parameters:
//    PathToUpdateFile - String - Path to a new configuration CF file.
//    SkipWarningsOnUpdate - Boolean - If set to "True", add the "-force" parameter.
//
// Returns:
//  String - If empty, the update completed successfully.
//           Otherwise, contains the warning texts.
//
Function UpdateToCorrectiveVersion(PathToUpdateFile, SkipWarningsOnUpdate = True) Export
	
	If InfoBaseUsers.CurrentUser().PasswordIsSet Then
		Raise NStr("ru = 'Обновление возможно только для пользователя без пароля.';
								|en = 'Update is available only for users without password.';");
	EndIf;
	
	If DesignerIsOpen() Then
		Raise NStr("ru = 'Для обновления закройте конфигуратор.';
								|en = 'To update, close Designer.';");
	EndIf;
	
	BinDir = StandardSubsystemsServer.ClientParametersAtServer().Get("BinDir");
	SettingsFilePath = "";
	GenerateCompareMergeSettingsFile(SettingsFilePath);
	
	MessagesFileName = GetTempFileName("txt");
	
	StartupCommand = New Array;
	StartupCommand.Add(BinDir + "1cv8.exe");
	StartupCommand.Add("DESIGNER");
	StartupCommand.Add("/IBConnectionString");
	StartupCommand.Add(InfoBaseConnectionString());
	StartupCommand.Add("/N");
	StartupCommand.Add(UserName());
	StartupCommand.Add("/P");
	StartupCommand.Add();
	StartupCommand.Add("/UpdateCfg");
	StartupCommand.Add(PathToUpdateFile);
	StartupCommand.Add("-Settings");
	StartupCommand.Add(SettingsFilePath);
	If SkipWarningsOnUpdate Then
		StartupCommand.Add("-force");
	EndIf;
	StartupCommand.Add("-ClearUnresolvedRefs");
	StartupCommand.Add("/Out");
	StartupCommand.Add(MessagesFileName);
	StartupCommand.Add("/DisableStartupMessages");
	StartupCommand.Add("/DisableStartupDialogs");
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	
	Result = FileSystem.StartApplication(StartupCommand, ApplicationStartupParameters);
	Messages = "";
	
	If Result.ReturnCode <> 0 Then
		Try
			Text = New TextDocument;
			Text.Read(MessagesFileName);
			Messages = Text.GetText();
			DeleteFiles(MessagesFileName);
		Except
			Messages = "";
		EndTry;
		If IsBlankString(Messages) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось выполнить сравнение/объединение с конфигурацией из файла по причине:
				           |Код возврата: %1';
							|en = 'Cannot compare or merge with the configuration from the file due to:
							|Return code: %1';"), Result.ReturnCode);
		EndIf;
	EndIf;
	DeleteFiles(MessagesFileName);
	
	ImportantMessages = ImportantMessages(Messages);
	If SkipWarningsOnUpdate
	 Or ValueIsFilled(ImportantMessages)
	 Or Not ValueIsFilled(Messages) Then
		Return ImportantMessages;
	EndIf;
	
	Return UpdateToCorrectiveVersion(PathToUpdateFile);
	
EndFunction

#EndRegion

#Region Private

Function ImportantMessages(Messages)
	
	Rows = New Array;
	CommonTitle = NStr("ru = 'Невозможно выполнение обновления конфигурации в командном режиме';
							|en = 'Cannot update the configuration in command mode';");
	UnimportantWarningsTitle = NStr("ru = 'Неизмененные свойства:';
											|en = 'Unchanged properties:';");
	
	IsUnimportantWarningsTitleFound = False;
	
	RowsCount = StrLineCount(Messages);
	For LineNumber = 1 To RowsCount Do
		String = StrGetLine(Messages, LineNumber);
		If String = UnimportantWarningsTitle Then
			IsUnimportantWarningsTitleFound = True;
			Continue;
		EndIf;
		If IsUnimportantWarningsTitleFound Then
			If Not ValueIsFilled(String) Then
				IsUnimportantWarningsTitleFound = False;
			EndIf;
			Continue;
		EndIf;
		Rows.Add(String);
	EndDo;
	If Rows.Count() = 1
	   And Rows[0] = CommonTitle Then
		Rows = New Array;
	EndIf;
	
	Return StrConcat(Rows, Chars.LF);
	
EndFunction

// Settings file population procedure.

Procedure SelectSubsystemsCheckBoxes(CaptureFileName)
	
	For Each SubsystemProperties In EmbeddedSubsystems(CaptureFileName) Do
		SelectSubsystemCheckBoxes(SubsystemProperties, False);
		SelectSubsystemCheckBoxes(SubsystemProperties, True);
	EndDo;
	
EndProcedure

Procedure SelectSubsystemCheckBoxes(SubsystemProperties, SecondConfiguration)
	
	ObjectNode = DOMDocument.CreateElement("Object");
	If SecondConfiguration Then
		ObjectNode.SetAttribute("fullNameInSecondConfiguration", SubsystemProperties.Key);
	Else
		ObjectNode.SetAttribute("fullName", SubsystemProperties.Key);
	EndIf;
	
	NodeRule = DOMDocument.CreateElement("MergeRule");
	NodeRule.TextContent = "GetFromSecondConfiguration";
	ObjectNode.AppendChild(NodeRule);
	
	NodeSubsystem = DOMDocument.CreateElement("Subsystem");
	If SecondConfiguration Then
		NodeSubsystem.SetAttribute("configuration", "Second");
	Else
		NodeSubsystem.SetAttribute("configuration", "Main");
	EndIf;
	NodeSubsystem.SetAttribute("includeObjectsFromSubordinateSubsystems", "false");
	
	If SubsystemProperties.Value Then
		NodeRule = DOMDocument.CreateElement("MergeRule");
		NodeRule.TextContent = "GetFromSecondConfiguration";
		NodeSubsystem.AppendChild(NodeRule);
		ObjectNode.AppendChild(NodeSubsystem);
	Else
		ObjectNode.AppendChild(NodeSubsystem);
		If SecondConfiguration Then
			PropertyNode1 = DOMDocument.CreateElement("Properties");
			SetRuleForProperty(PropertyNode1, "CommandInterface", "MergePrioritizingSecondConfiguration");
			SetRuleForProperty(PropertyNode1, "Content", "MergePrioritizingSecondConfiguration");
			ObjectNode.AppendChild(PropertyNode1);
		EndIf;
	EndIf;
	
	NodeObjects.AppendChild(ObjectNode);
	
EndProcedure

Procedure SelectOverridableModulesCheckBoxes()
	
	For Each OverridableModule In OverridableModules() Do
		SetRuleForObjectAndProperties(OverridableModule,
			New Structure("Module", "DoNotMerge"));
	EndDo;
	
EndProcedure

Procedure SelectRolesCheckBoxes()
	
	Roles = New Array;
	Roles.Add("Role.SystemAdministrator");
	Roles.Add("Role.FullAccess");
	
	For Each Role In Roles Do
		SetRuleForObjectAndProperties(Role,
			New Structure("Rights", "MergePrioritizingSecondConfiguration"));
	EndDo;
	
EndProcedure

Procedure SelectSeparatorsCheckBoxes()
	
	If Not Common.SubsystemExists("StandardSubsystems.SaaSOperations.CoreSaaS") Then
		Return;
	EndIf;
	
	Separators = New Array;
	Separators.Add("CommonAttribute.DataAreaAuxiliaryData");
	Separators.Add("CommonAttribute.DataAreaMainData");
	
	For Each Separator In Separators Do
		SetRuleForObjectAndProperties(Separator,
			New Structure("Content", "MergePrioritizingSecondConfiguration"));
	EndDo;
EndProcedure

Procedure SelectFilterCriteriaCheckBoxes()
	
	Criteria = New Map;
	Criteria.Insert("FilterCriterion.RelatedDocuments", "StandardSubsystems.SubordinationStructure");
	
	For Each FilterCriterion In Criteria Do
		
		If Not Common.SubsystemExists(FilterCriterion.Value) Then
			Continue;
		EndIf;
		
		RuleProperties = New Structure;
		RuleProperties.Insert("Type", "DoNotMerge");
		RuleProperties.Insert("Content", "DoNotMerge");
		SetRuleForObjectAndProperties(FilterCriterion.Key, RuleProperties);
		
	EndDo;
	
EndProcedure

Procedure SelectCheckBoxesOfTypesToDefine()
	
	For Each TypeProperties In DefinedTypes() Do
		ObjectNode = DOMDocument.CreateElement("Object");
		ObjectNode.SetAttribute("fullNameInSecondConfiguration", TypeProperties.Key);
		
		PropertyNode1 = DOMDocument.CreateElement("Properties");
		Rule = ?(TypeProperties.Value, "MergePrioritizingSecondConfiguration", "DoNotMerge");
		SetRuleForProperty(PropertyNode1, "Type", Rule);
		
		ObjectNode.AppendChild(PropertyNode1);
		NodeObjects.AppendChild(ObjectNode);
	EndDo;
	
EndProcedure

Procedure SelectCommonCommandsCheckBoxes()
	
	Commands = New Map;
	
	Subsystem = "StandardSubsystems.DataExchange";
	Commands.Insert("CommonCommand.Synchronize", Subsystem);
	Commands.Insert("CommonCommand.SynchronizeWithAdditionalParameters", Subsystem);
	Commands.Insert("CommonCommand.ConnectionSettings", Subsystem);
	Commands.Insert("CommonCommand.ImportRulesSet", Subsystem);
	Commands.Insert("CommonCommand.ImportObjectConvertionRules", Subsystem);
	Commands.Insert("CommonCommand.ImportObjectRegistrationRules", Subsystem);
	Commands.Insert("CommonCommand.GetSynchronizationSettingsForOtherApplication", Subsystem);
	Commands.Insert("CommonCommand.SynchronizationScenarios", Subsystem);
	Commands.Insert("CommonCommand.SendingEvents", Subsystem);
	Commands.Insert("CommonCommand.ReceivingEvents", Subsystem);
	Commands.Insert("CommonCommand.DataToSendComposition", Subsystem);
	Commands.Insert("CommonCommand.DeleteSynchronizationSetting", Subsystem);
	
	Subsystem = "StandardSubsystems.SubordinationStructure";
	Commands.Insert("CommonCommand.RelatedDocuments", Subsystem);
	
	Subsystem = "StandardSubsystems.AccessManagement";
	Commands.Insert("CommonCommand.SetRights", Subsystem);
	
	For Each Command In Commands Do
		
		If Not Common.SubsystemExists(Command.Value) Then
			Continue;
		EndIf;
		
		SetRuleForObjectAndProperties(Command.Key,
			New Structure("CommandParameterType", "DoNotMerge"));
		
	EndDo;
	
EndProcedure

Procedure SelectLanguagesCheckBoxes()
	SetRuleForObject("Language.Russian", "GetFromSecondConfiguration");
EndProcedure

Procedure SelectCatalogsCheckBoxes()
	CatalogTable_ = New ValueTable;
	CatalogTable_.Columns.Add("Name");
	CatalogTable_.Columns.Add("Subsystem");
	CatalogTable_.Columns.Add("Property");
	CatalogTable_.Columns.Add("Rule");
	
	NewRow = CatalogTable_.Add();
	NewRow.Name = "Catalog.PerformerRoles";
	NewRow.Subsystem = "StandardSubsystems.BusinessProcessesAndTasks";
	NewRow.Property = "Predefined";
	NewRow.Rule = "DoNotMerge";
	
	NewRow = CatalogTable_.Add();
	NewRow.Name = "Catalog.ContactInformationKinds";
	NewRow.Subsystem = "StandardSubsystems.ContactInformation";
	NewRow.Property = "Predefined";
	NewRow.Rule = "DoNotMerge";
	
	NewRow = CatalogTable_.Add();
	NewRow.Name = "Catalog.ExternalUsers.Command.ExternalAccess";
	NewRow.Subsystem = "StandardSubsystems.Users";
	NewRow.Property = "CommandParameterType";
	NewRow.Rule = "DoNotMerge";
	
	NewRow = CatalogTable_.Add();
	NewRow.Name = "Catalog.AdditionalAttributesAndInfoSets";
	NewRow.Subsystem = "StandardSubsystems.Properties";
	NewRow.Property = "Predefined";
	NewRow.Rule = "DoNotMerge";
	
	NewRow = CatalogTable_.Add();
	NewRow.Name = "Catalog.AccessGroupProfiles";
	NewRow.Subsystem = "StandardSubsystems.AccessManagement";
	NewRow.Property = "Predefined";
	NewRow.Rule = "DoNotMerge";
	
	NewRow = CatalogTable_.Add();
	NewRow.Name = "Catalog.MetadataObjectIDs";
	NewRow.Subsystem = "StandardSubsystems.Core";
	NewRow.Property = "Predefined";
	NewRow.Rule = "MergePrioritizingSecondConfiguration";
	
	NewRow = CatalogTable_.Add();
	NewRow.Name = "Catalog.SourceDocumentsOriginalsStates";
	NewRow.Subsystem = "StandardSubsystems.SourceDocumentsOriginalsRecording";
	NewRow.Property = "Predefined";
	NewRow.Rule = "DoNotMerge";

	For Each Catalog In CatalogTable_ Do
		
		If Common.SubsystemExists(Catalog.Subsystem) Then
			SetRuleForObjectAndProperties(Catalog.Name,
				New Structure(Catalog.Property, Catalog.Rule));
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SelectExchangePlansCheckBoxes()
	ExchangePlansTable = New ValueTable;
	ExchangePlansTable.Columns.Add("Name");
	ExchangePlansTable.Columns.Add("Subsystem");
	ExchangePlansTable.Columns.Add("Property");
	ExchangePlansTable.Columns.Add("Rule");
	
	NewRow = ExchangePlansTable.Add();
	NewRow.Name = "ExchangePlan.InfobaseUpdate";
	NewRow.Subsystem = "StandardSubsystems.IBVersionUpdate";
	NewRow.Property = "Content";
	NewRow.Rule = "MergePrioritizingSecondConfiguration";
	
	For Each ExchangePlan In ExchangePlansTable Do
		
		If Common.SubsystemExists(ExchangePlan.Subsystem) Then
			SetRuleForObjectAndProperties(ExchangePlan.Name,
				New Structure(ExchangePlan.Property, ExchangePlan.Rule));
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SelectEnumerationsCheckBoxes()
	If Common.SubsystemExists("StandardSubsystems.SendSMSMessage") Then
		SetRuleForObject("Enum.SMSProviders", "DoNotMerge");
	EndIf;
EndProcedure

Procedure SelectChartOfCharacteristicTypesCheckBoxes()
	ChartOfCharacteristicTypesTable = New ValueTable;
	ChartOfCharacteristicTypesTable.Columns.Add("Name");
	ChartOfCharacteristicTypesTable.Columns.Add("Subsystem");
	ChartOfCharacteristicTypesTable.Columns.Add("RuleProperties");
	
	RuleProperties = New Structure;
	RuleProperties.Insert("Type", "MergePrioritizingSecondConfiguration");
	RuleProperties.Insert("Predefined", "MergePrioritizingSecondConfiguration");
	
	NewRow = ChartOfCharacteristicTypesTable.Add();
	NewRow.Name = "ChartOfCharacteristicTypes.QuestionsForSurvey";
	NewRow.Subsystem = "StandardSubsystems.Surveys";
	NewRow.RuleProperties = New Structure("Type", "MergePrioritizingSecondConfiguration");
	
	NewRow = ChartOfCharacteristicTypesTable.Add();
	NewRow.Name = "ChartOfCharacteristicTypes.TaskAddressingObjects";
	NewRow.Subsystem = "StandardSubsystems.BusinessProcessesAndTasks";
	NewRow.RuleProperties = RuleProperties;
	
	NewRow = ChartOfCharacteristicTypesTable.Add();
	NewRow.Name = "ChartOfCharacteristicTypes.PeriodClosingDatesSections";
	NewRow.Subsystem = "StandardSubsystems.PeriodClosingDates";
	NewRow.RuleProperties = RuleProperties;
	
	NewRow = ChartOfCharacteristicTypesTable.Add();
	NewRow.Name = "ChartOfCharacteristicTypes.AdditionalAttributesAndInfo";
	NewRow.Subsystem = "StandardSubsystems.Properties";
	NewRow.RuleProperties = RuleProperties;
	
	For Each ChartOfCharacteristicTypes In ChartOfCharacteristicTypesTable Do
		
		If Common.SubsystemExists(ChartOfCharacteristicTypes.Subsystem) Then
			SetRuleForObjectAndProperties(ChartOfCharacteristicTypes.Name, ChartOfCharacteristicTypes.RuleProperties);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SelectBusinessProcessesCheckBoxes()
	If Common.SubsystemExists("StandardSubsystems.BusinessProcessesAndTasks") Then
		SetRuleForObjectAndProperties("BusinessProcess.Job", New Structure("BasedOn", "DoNotMerge"));
	EndIf;
EndProcedure

Procedure SelectFunctionalOptionsCheckBoxes()
	
	FunctionalOptions = New Array;
	FunctionalOptions.Add("FunctionalOption.StandaloneWorkplace");
	FunctionalOptions.Add("FunctionalOption.LocalMode");
	FunctionalOptions.Add("FunctionalOption.SaaSOperations");
	
	For Each FunctionalOption In FunctionalOptions Do
		SetRuleForObjectAndProperties(FunctionalOption,
			New Structure("Content", "DoNotMerge"));
	EndDo;
	
EndProcedure

// Secondary procedures.

// Generates a file to capture objects to the storage.
//
Function EmbeddedSubsystems(CaptureFileName)
	
	// StandardSubsystems subsystem is required.
	If Metadata.Subsystems.Find("StandardSubsystems") = Undefined Then
		Raise NStr("ru = 'Не внедрена БСП';
								|en = 'SSL is not integrated';");
	EndIf;
	
	Subsystems = New Map;
	SSLObjects = New Map;
	
	Record = New XMLWriter;
	Record.OpenFile(CaptureFileName);
	Record.WriteXMLDeclaration();
	Record.WriteStartElement(NStr("ru = 'Objects';
										|en = 'Objects';"));
	Record.WriteAttribute("xmlns", "http://v8.1c.ru/8.3/config/objects");
	Record.WriteAttribute("version", "1.0");
	
	AdministrationSubsystem = Metadata.Subsystems.Find("Administration");
	If AdministrationSubsystem <> Undefined Then
		FullName = AdministrationSubsystem.FullName();
		Subsystems.Insert(FullName, False);
		Record.WriteStartElement("Object");
		Record.WriteAttribute("fullName", FullName);
		Record.WriteAttribute("includeChildObjects", "false");
		Record.WriteEndElement();
	EndIf;
	
	AttachableReportsSubsystem = Metadata.Subsystems.Find("AttachableReportsAndDataProcessors");
	If AttachableReportsSubsystem <> Undefined Then
		FullName = AttachableReportsSubsystem.FullName();
		Subsystems.Insert(FullName, False);
		Record.WriteStartElement("Object");
		Record.WriteAttribute("fullName", FullName);
		Record.WriteAttribute("includeChildObjects", "false");
		Record.WriteEndElement();
	EndIf;
	
	AddSubsystems(Subsystems, Metadata.Subsystems.StandardSubsystems, Record);
	
	Record.WriteEndElement();
	Record.Close();
	
	Return Subsystems;
	
EndFunction

Function OverridableModules()
	
	OverridableModules = New Array;
	
	For Each CommonModule In Metadata.CommonModules Do
		If IsSSLObject(CommonModule) And StrEndsWith(CommonModule.Name, "Overridable") Then
			OverridableModules.Add(CommonModule.FullName());
		EndIf;
	EndDo;
	
	Return OverridableModules;
	
EndFunction

Function DefinedTypes()
	
	// SSL doesn't populate these type collections. Clear the flags for the collections.
	BlankTypesToDefine = New Array;
	BlankTypesToDefine.Add("Organization");
	BlankTypesToDefine.Add("Department");
	BlankTypesToDefine.Add("Individual");
	
	DefinedTypes = New Map;
	
	For Each DefinedType In Metadata.DefinedTypes Do
		If IsSSLObject(DefinedType) Then
			SetCheck = BlankTypesToDefine.Find(DefinedType.Name) = Undefined;
			DefinedTypes.Insert(DefinedType.FullName(), SetCheck);
		EndIf;
	EndDo;
	
	Return DefinedTypes;
	
EndFunction

Procedure AddSubsystems(Subsystems, MetadataSubsystems, Record)
	
	For Each Subsystem In MetadataSubsystems.Subsystems Do
		If Subsystem.Subsystems.Count() = 0 Or Subsystem.Name = "DataExchange" Then
			FullName = Subsystem.FullName();
			Subsystems.Insert(FullName, True);
			Record.WriteStartElement("Object");
			Record.WriteAttribute("fullName", FullName);
			Record.WriteAttribute("includeChildObjects", "false");
			Record.WriteStartElement("Subsystem");
			Record.WriteAttribute("includeObjectsFromSubordinateSubsystems", "true");
			Record.WriteEndElement();
			Record.WriteEndElement();
			For Each MetadataObject In Subsystem.Content Do
				SSLObjects.Insert(MetadataObject, True);
			EndDo;
		Else
			AddSubsystems(Subsystems, Subsystem, Record);
		EndIf;
	EndDo;
	
EndProcedure

// DOM document management.

Procedure WriteDOMDocumentToFile(PathToFile)
	
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(PathToFile);
	
	DOMWriter = New DOMWriter;
	DOMWriter.Write(DOMDocument, XMLWriter);
	
EndProcedure

Function DOMDocument(PathToFile)
	
	XMLReader = New XMLReader;
	DOMBuilder = New DOMBuilder;
	XMLReader.OpenFile(PathToFile);
	DOMDocument = DOMBuilder.Read(XMLReader);
	XMLReader.Close();
	
	Return DOMDocument;
	
EndFunction

Procedure SetRuleForObjectAndProperties(FullName, RuleProperties)
	
	ObjectNode = DOMDocument.CreateElement("Object");
	ObjectNode.SetAttribute("fullNameInSecondConfiguration", FullName);
	PropertyNode1 = DOMDocument.CreateElement("Properties");
	For Each RuleProperty In RuleProperties Do
		SetRuleForProperty(PropertyNode1, RuleProperty.Key, RuleProperty.Value);
	EndDo;
	ObjectNode.AppendChild(PropertyNode1);
	NodeObjects.AppendChild(ObjectNode);
EndProcedure

Procedure SetRuleForProperty(PropertyNode1, PropertyName, Rule)
	
	NodeProperty = DOMDocument.CreateElement("Property");
	NodeProperty.SetAttribute("name", PropertyName);
	NodeRule = DOMDocument.CreateElement("MergeRule");
	NodeRule.TextContent = Rule;
	NodeProperty.AppendChild(NodeRule);
	PropertyNode1.AppendChild(NodeProperty);
	
EndProcedure

Procedure SetRuleForObject(FullName, Rule)
	ObjectNode = DOMDocument.CreateElement("Object");
	ObjectNode.SetAttribute("fullNameInSecondConfiguration", FullName);
	
	NodeRule = DOMDocument.CreateElement("MergeRule");
	NodeRule.TextContent = Rule;
	ObjectNode.AppendChild(NodeRule);
	NodeObjects.AppendChild(ObjectNode);
EndProcedure

// Common procedures.

Function IsSSLObject(MetadataObject)
	Return SSLObjects.Get(MetadataObject) = True;
EndFunction

Function DesignerIsOpen()
	
	For Each Session In GetInfoBaseSessions() Do
		If Upper(Session.ApplicationName) = Upper("Designer") Then // Designer.
			Return True;
		EndIf;
	EndDo;
	Return False;
	
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf