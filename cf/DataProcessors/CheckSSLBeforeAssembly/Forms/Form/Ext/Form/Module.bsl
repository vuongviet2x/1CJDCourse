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
Var Report_Results;
&AtServer
Var ObjectsAndSubsystemsMap;
&AtClient
Var ExceptionObjectsConditionalCallsChecks;
&AtClient
Var SubsystemsConditionalCallsCheckExceptions;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	RunAndEnd               = Parameters.RunAndEnd;
	ModulesExportDirectory            = Parameters.ModulesExportDirectory;
	AutoTesting        = Parameters.AutoTesting;
	FullPathToCheckFile          = Parameters.FullPathToCheckFile;
	
	IBAdministratorName = InfoBaseUsers.CurrentUser().Name;
	
	// List of metadata to skip during right check.
	ExceptionsList = New ValueList;
	ExceptionsList.Add(Metadata.Catalogs.AdditionalReportsAndDataProcessors.Name);
	ExceptionsList.Add(Metadata.InformationRegisters.AdditionalDataProcessorsPurposes.Name);
	ExceptionsList.Add(Metadata.InformationRegisters.DataProcessorAccessUserSettings.Name);
	ExceptionsList.Add(Metadata.Constants.DataAreaKey.Name);
	
	FillDeveloperTools(Metadata.Subsystems._DemoDeveloperTools);
	
	// Block of current check details.
	
	// Here, add the details of any check in the following format:
	// AddCheck(<User-readable representation of the check>, <Checker function's name>);
	AddCheck(NStr("ru = 'Модули обычного и управляемого приложения должны совпадать';
							|en = 'Modules of standard and managed application must match';"), 
		"Attachable_CheckManagedAndOrdinaryApplicationModulesMatch()");
	
	AddCheck(NStr("ru = 'Каждый объект должен принадлежать хотя бы одной подсистеме';
							|en = 'Each object must belong at least to one subsystem';"), 
		"Attachable_CheckObjectsInclusionInSubsystems()");
	
	AddCheck(NStr("ru = 'Демонстрационные объекты не должны включаться в поставляемые подсистемы';
							|en = 'Demo objects cannot be included to 1C-supplied subsystems';"), 
		"Attachable_Check_DemoObjectsInclusion()");
	
	AddCheck(NStr("ru = 'Демонстрационные примеры должны быть правильно закомментированы';
							|en = 'Demo examples must have correct comments';"), 
		"Attachable_Check_DemoExamplesCommentsValidity()");
	
	AddCheck(NStr("ru = 'Демонстрационные объекты должны быть правильно названы';
							|en = 'Demo objects must have correct names';"), 
		"Attachable_Check_DemoObjectsNamesValidity()");
	
	AddCheck(NStr("ru = 'Роль и вид доступа должны быть включены хотя бы в одно описание профиля';
							|en = 'Role and access kind must be included in at least one profile description';"), 
		"Attachable_CheckRolesAndAccessKindsInclusionInProfiles()");
	
	AddCheck(NStr("ru = 'Комментарии блоков кода, относящихся к той или иной подсистемы должны быть корректными';
							|en = 'Code block comments belonging to subsystems must be correct';"), 
		"Attachable_CheckSubsystemsCodeBlocksComments()");
	
	AddCheck(NStr("ru = 'Использование функции проверки существования подсистем';
							|en = 'Use the subsystem existence check function';"), 
		"Attachable_CheckConditionalCallsValidity()");
	
	AddCheck(NStr("ru = 'Недопустимо наличие недокументированных связей между подсистемами';
							|en = 'Undocumented links between subsystems are not allowed';"), 
		"Attachable_IncorrectLinksBetweenSubsystems()");
	
	AddCheck(NStr("ru = 'У поставляемых подсистем должен быть снят флаг ""Включать в содержание справки""';
							|en = 'Clear the ""Include in help contents"" check box for the 1C-supplied subsystems';"), 
		"Attachable_CheckIncludeInHelpContentFlagValue()");
	
	AddCheck(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Подсистемы верхнего уровня (а также подчиненные им подсистемы), отображаемые в главном командном интерфейсе, должны иметь право
		|просмотр в роли %1<%2>';
		|en = 'Upper level subsystems (and subsystems subordinate to them) that are displayed in the main command interface must have the right
		|to view in role %1<%2>';"), "Subsystem", "SubsystemName"),
		"Attachable_RightCheckCommandInterfaceSubsystemsView()");
	
	AddCheck(StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Недопустимо наличие ""%1"" в текстах модулей';
																					|en = '%1 is not allowed in module texts';"), "TO" + "DO"), 
		"Attachable_SearchForProhibitedComments()");
	
	AddCheck(NStr("ru = 'Нерекомендуемые настройки ролей';
							|en = 'Not recommended role settings';"), 
		"Attachable_FindNotRecommendedRolesSettings()",
		False);
	
	AddCheck(NStr("ru = 'Платформенная проверка конфигурации не должна содержать ошибок.';
							|en = 'Platform configuration check must not have errors.';"),
		"Attachable_ConfigurationPlatformCheck()",
		False);
	
	AddCheck(NStr("ru = 'Недопустимо наличие права ""Интерактивное удаление""';
							|en = 'The ""Delete interactively"" right is not allowed';"), 
		"Attachable_CheckHasInteractiveDeleteRight()",
		False);
	
	AddCheck(NStr("ru = 'Дополнительные команды открытия списков должны иметь в ролях те же права, что и объекты метаданных.';
							|en = 'Additional commands of list opening must have in roles the same rights as metadata objects do.';"), 
		"Attachable_CheckRightToViewListsOpeningCommandsInRoles()",
		False);
	
	AddCheck(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'У отложенных обработчиков обновления должны быть заполнены свойства %1, %2';
			|en = 'Properties %1 and %2 of deferred update handlers must be filled in';"),
		"ObjectsToRead", "ObjectsToChange"),
		"Attachable_CheckDeferredUpdateHandlers()",
		False);
	
	AddCheck(NStr("ru = 'Роли должны давать права на объекты только своей подсистемы.';
							|en = 'Roles must grant access to objects only of their own subsystem.';"),
		"Attachable_CheckRolesForUnauthorizedAccess()",
		False);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
#If WebClient Or MobileClient Then
	Raise NStr("ru = 'Для открытия обработки необходимо запустить тонкий или толстый клиент.';
							|en = 'To open the data processor, run the thin client or thick client.';");
#EndIf
	
	If RunAndEnd Then
		StartCheck();
	EndIf;
	
	Items.CompareApplicationFiles.Visible = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CommandExecute(Command)
	
#If Not WebClient Then
	If Not RunAndEnd Then
		ClearDirectoryForExport(ModulesExportDirectory);
	EndIf;
	ExecuteCheck();
#EndIf
	
EndProcedure

&AtClient
Procedure OpenDesigner(Command)
#If Not WebClient Then
	
	StartupCommand = New Array;
	StartupCommand.Add(BinDir() + "1cv8.exe");
	StartupCommand.Add("DESIGNER");
	StartupCommand.Add("/IBConnectionString");
	StartupCommand.Add(IBPath);
	StartupCommand.Add("/N");
	StartupCommand.Add(IBAdministratorName);
	StartupCommand.Add("/P");
	StartupCommand.Add(IBAdministratorPassword);
	
	FileSystemClient.StartApplication(StartupCommand);
	
#EndIf
EndProcedure

&AtClient
Procedure SelectAllChecks(Command)
	For Each Validation In Object.Checks Do
		Validation.ShouldExecuteCheck = True;
	EndDo;
EndProcedure

&AtClient
Procedure ClearAllChecks(Command)
	For Each Validation In Object.Checks Do
		Validation.ShouldExecuteCheck = False;
	EndDo;
EndProcedure

&AtClient
Procedure OpenPreviousCheckResults(Command)
	Report_Results.Show();
EndProcedure

&AtClient
Procedure CompareApplicationFiles(Command)

#If Not ThickClientManagedApplication And Not ThickClientOrdinaryApplication Then
	Raise NStr("ru = 'Для сравнения необходимо запустить толстый клиент.';
							|en = 'To compare files, run the thick client.';");
#Else
	Comparison = New FileCompare;
	
	If ModulesExportDirectory = "" Then
		UploadConfigurationToXML(ModulesExportDirectory);
	EndIf;
	
	FirstFile = FindFiles(ModulesExportDirectory, "ManagedApplicationModule.bsl", True);
	SecondFile = FindFiles(ModulesExportDirectory, "OrdinaryApplicationModule.bsl", True);
	
	If FirstFile.Count() = 0 Or SecondFile.Count() = 0 Then
		CommonClient.MessageToUser(NStr("ru = 'Не найдены файлы приложений';
														|en = 'Application files are not found';"));
		Return;
	EndIf;
	
	Comparison.FirstFile = FirstFile[0].FullName;
	Comparison.SecondFile = SecondFile[0].FullName;
	
	Comparison.IgnoreWhiteSpace = True;
	Comparison.EOLSensitive = False;
	Comparison.CaseSensitive = False;
	Comparison.CompareMethod = FileCompareMethod.TextDocument;
	Comparison.ShowDifferences();
#EndIf
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure StartCheck()
	CommandExecute(Undefined);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions.

&AtClient
Procedure ClearDirectoryForExport(ModulesExportDirectory)
	FilesArray = FindFiles(ModulesExportDirectory, "*", True);
	For Each File In FilesArray Do
		DeleteFiles(File.FullName);
	EndDo;
EndProcedure

// ACC:78-off is used for batch calls.
&AtClient
Procedure ExecuteCheck(Output_List = Undefined) Export
	PopulateCheckExceptions();
	Output_List     = New ValueList;
	ExecutionErrors = "";
	For Each Validation In Object.Checks Do
		If Validation.ShouldExecuteCheck Then
			Try
				Status(NStr("ru = 'Проверка правила:';
								|en = 'Rule check:';") + " " + Validation.CheckDescription);
				ChecksArray = StrSplit(Validation.CheckProcedureDescription, ",", False);
				For Each IntermediateCheck In ChecksArray Do
					ErrorsStructure = Eval(TrimAll(IntermediateCheck));
					ApplyCheckExceptions(ErrorsStructure);
					If ErrorsStructure <> Undefined Then
						If TypeOf(ErrorsStructure) = Type("Array") Then
							For Each ArrayElement In ErrorsStructure Do
								Output_List.Add(ArrayElement);
							EndDo;
						Else
							Output_List.Add(ErrorsStructure);
						EndIf;
					EndIf;
				EndDo;
				
			Except
				ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				EventLogClient.AddMessageForEventLog(NStr("ru = 'Проверка перед сборкой';
																					|en = 'Check before assembly';"), "Error", ErrorPresentation);
				MessageText = NStr("ru = 'Не удалось выполнить проверку ""%1""';
										|en = 'Cannot check %1';");
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, Validation.CheckDescription);
				
				ExecutionErrors = ?(ExecutionErrors = "", MessageText, ExecutionErrors + Chars.LF + MessageText);
			EndTry;
		EndIf;
	EndDo;
	
	HasErrors = False;
	TabDoc = OutputErrors(Output_List, HasErrors);
	TabDoc.ShowGroups = True;
	TabDoc.ShowGrid = False;
	TabDoc.ShowHeaders = False;
	
	If RunAndEnd Then
		If Not AutoTesting Then
			If StrEndsWith(FullPathToCheckFile, ".txt") Then
				OutputErrorsToTextFile(Output_List);
			Else
				TabDoc.Write(FullPathToCheckFile);
			EndIf;
			Terminate(False);
		EndIf;
	Else
		TabDoc.Show();
		RefreshHyperlink();
		Report_Results = TabDoc;
		ClearDirectoryForExport(ModulesExportDirectory);
	EndIf;
	
	If ValueIsFilled(ExecutionErrors) Then
		Raise ExecutionErrors;
	EndIf;
	
EndProcedure
// ACC:78-on.
&AtClient
Procedure RefreshHyperlink()
	TitleTemplate1 = NStr("ru = 'Открыть результаты проверки на: %1';
							|en = 'Open check results on: %1';"); 
	Items.OpenCheckResults.Title = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, String(SessionDate()));
	Items.OpenCheckResults.Enabled = True;
EndProcedure

&AtServer
Function SessionDate()
	
	Return CurrentSessionDate();
	
EndFunction	

&AtServer
Procedure UploadConfigurationToXML(ConfigurationUploadDirectory)
	
	If Not IsBlankString(ConfigurationUploadDirectory) Then
		Directory = New File(ConfigurationUploadDirectory);
		If Not Directory.Exists() Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Указанный каталог выгрузки ""%1"" не существует.';
																							|en = 'Specified ""%1"" export directory does not exist.';"), ConfigurationUploadDirectory);
		EndIf;
		If FindFiles(ConfigurationUploadDirectory, "Configuration.xml", True).Count() = 0 Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Указанный каталог выгрузки ""%1"" не содержит файлов выгрузки конфигурации.';
																							|en = 'Specified ""%1"" export directory does not contain configuration export files.';"), ConfigurationUploadDirectory);
		EndIf;
		DumpDirectory = ConfigurationUploadDirectory;
		Return;
	EndIf;
	
	If InfoBaseUsers.CurrentUser().PasswordIsSet Then
		Raise NStr("ru = 'Проверка возможна только для пользователя без пароля.';
								|en = 'Can check only for users without password.';");
	EndIf;
	
	DumpDirectory = GetTempFileName("");
	BinDir = StandardSubsystemsServer.ClientParametersAtServer().Get("BinDir");
	CreateDirectory(DumpDirectory);
	
	ConnectionString = InfoBaseConnectionString();
	If DesignerIsOpen() Then
		If Common.FileInfobase() Then
			InfobaseDirectory = StringFunctionsClientServer.ParametersFromString(ConnectionString).file;
			FileCopy(InfobaseDirectory + "\1Cv8.1CD", DumpDirectory + "\1Cv8.1CD");
			ConnectionString = StringFunctionsClientServer.SubstituteParametersToString("File=""%1"";", DumpDirectory);
		Else
			Raise NStr("ru = 'Для проверки закройте конфигуратор.';
									|en = 'To check, close Designer.';");
		EndIf;
	EndIf;
	
	MessagesFileName = DumpDirectory + "\UploadConfigurationToFilesMessages.txt";
	
	StartupCommand = New Array;
	StartupCommand.Add(BinDir + "1cv8.exe");
	StartupCommand.Add("DESIGNER");
	StartupCommand.Add("/IBConnectionString");
	StartupCommand.Add(ConnectionString);
	StartupCommand.Add("/N");
	StartupCommand.Add(UserName());
	StartupCommand.Add("/P");
	StartupCommand.Add();
	StartupCommand.Add("/DumpConfigToFiles");
	StartupCommand.Add(DumpDirectory);
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
		Except
			Messages = "";
		EndTry;
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось выполнить выгрузку конфигурации в файлы по причине:
			           |%1';
						|en = 'Failed to import configuration to files due to:
						|%1';"), Messages);
	EndIf;
	
	ConfigurationUploadDirectory = DumpDirectory;
	
EndProcedure

&AtServer
Procedure AddCheck(CheckName, CheckProcedureName, ShouldExecuteCheck = True)
	NewCheckRow = Object.Checks.Add();
	NewCheckRow.ShouldExecuteCheck = ShouldExecuteCheck;
	NewCheckRow.CheckDescription = CheckName;
	NewCheckRow.CheckProcedureDescription = CheckProcedureName;
EndProcedure

&AtServer
Function OutputErrors(ErrorList, HasErrors)
	
	TabDoc = New SpreadsheetDocument;
	TabDoc.StartRowAutoGrouping();
	Template = FormAttributeToValue("Object").GetTemplate("ErrorReportTemplate");
	
	For Each ErrorsStructureItem In ErrorList Do
		ErrorsStructure = ErrorsStructureItem.Value;
		InvalidData = ErrorsStructure.InvalidData;
		
		If InvalidData = Undefined
			Or InvalidData.Count() = 0 Then
			Continue;
		EndIf;
		
		RuleArea = Template.GetArea("RuleName");
		RuleArea.Parameters.RuleName = ErrorsStructure.ErrorPresentation;
		RuleArea.Parameters.ErrorsCount = ?(InvalidData = Undefined, 0, InvalidData.Count());
		TabDoc.Put(RuleArea, 0);
		
		AreaToCorrect = Template.GetArea("PatchDetails");
		AreaToCorrect.Parameters.CorrectionMethod = ErrorsStructure.PatchDetails;
		TabDoc.Put(AreaToCorrect,1);
		
		If TypeOf(InvalidData) = Type("ValueList") Then
			For Each Error In InvalidData Do
				ErrorArea_ = Template.GetArea("Object");
				ErrorArea_.Parameters.ObjectName = Error.Value;
				TabDoc.Put(ErrorArea_,2);
			EndDo;
		EndIf;
		
		HasErrors = True;
	EndDo;
	
	If Not HasErrors Then
		RuleArea = Template.GetArea("RuleName");
		RuleArea.Parameters.RuleName = NStr("ru = 'Ошибок не обнаружено';
													|en = 'No errors detected';");
		RuleArea.Parameters.ErrorsCount = 0;
		TabDoc.Put(RuleArea, 0);
	EndIf;
	
	TabDoc.EndRowAutoGrouping();
	Return TabDoc;
	
EndFunction

&AtServer
Procedure OutputErrorsToTextFile(ErrorList)
	
	HasErrors = False;
	TextDocument = New TextDocument;
	For Each ErrorsStructureItem In ErrorList Do
		ErrorsStructure = ErrorsStructureItem.Value;
		InvalidData = ErrorsStructure.InvalidData;
		
		If InvalidData = Undefined
			Or InvalidData.Count() = 0 Then
			Continue;
		EndIf;
		
		CheckName = ErrorsStructure.ErrorPresentation;
		VerificationDescription = ErrorsStructure.PatchDetails;
		
		TextDocument.AddLine("--------------------------------------------------");
		TextDocument.AddLine(Chars.LF);
		TextDocument.AddLine("- " + NStr("ru = 'Проверка';
													|en = 'Check';")+ ":");
		TextDocument.AddLine(CheckName);
		If ValueIsFilled(VerificationDescription) Then
			TextDocument.AddLine("- " + NStr("ru = 'Описание';
														|en = 'Details';")+ ":");
			TextDocument.AddLine(VerificationDescription);
		EndIf;
		TextDocument.AddLine("- " + NStr("ru = 'Ошибки';
													|en = 'Errors';")+ ":");
		
		If TypeOf(InvalidData) = Type("ValueList") Then
			For Each Error In InvalidData Do
				TextDocument.AddLine(Error.Value);
			EndDo;
		EndIf;
		
		TextDocument.AddLine(Chars.LF);
		
		HasErrors = True;
	EndDo;
	
	If Not HasErrors Then
		TextDocument.AddLine(NStr("ru = 'Ошибок не обнаружено';
												|en = 'No errors detected';"));
	EndIf;
	
	TextDocument.Write(FullPathToCheckFile);
	
EndProcedure

&AtServer
Function MetadataTypeToCheck()
	TypesList = New ValueList;
	TypesList.Add("WebServices");
	TypesList.Add("WSReferences");
	TypesList.Add("BusinessProcesses");
	TypesList.Add("CommandGroups");
	TypesList.Add("Documents");
	TypesList.Add("DocumentJournals");
	TypesList.Add("Tasks");
	TypesList.Add("Interfaces");
	TypesList.Add("Constants");
	TypesList.Add("FilterCriteria");
	TypesList.Add("DocumentNumerators");
	TypesList.Add("DataProcessors");
	TypesList.Add("CommonPictures");
	TypesList.Add("CommonCommands");
	TypesList.Add("CommonTemplates");
	TypesList.Add("CommonModules");
	TypesList.Add("CommonForms");
	TypesList.Add("Reports");
	TypesList.Add("XDTOPackages");
	TypesList.Add("SessionParameters");
	TypesList.Add("FunctionalOptionsParameters");
	TypesList.Add("Enums");
	TypesList.Add("ChartsOfCalculationTypes");
	TypesList.Add("ChartsOfCharacteristicTypes");
	TypesList.Add("ExchangePlans");
	TypesList.Add("ChartsOfAccounts");
	TypesList.Add("EventSubscriptions");
	TypesList.Add("Sequences");
	TypesList.Add("AccountingRegisters");
	TypesList.Add("AccumulationRegisters");
	TypesList.Add("CalculationRegisters");
	TypesList.Add("InformationRegisters");
	TypesList.Add("ScheduledJobs");
	TypesList.Add("Roles");
	TypesList.Add("Catalogs");
	TypesList.Add("Styles");
	TypesList.Add("FunctionalOptions");
	TypesList.Add("SettingsStorages");
	TypesList.Add("StyleItems");
	TypesList.Add("Languages");
	Return TypesList;
	
EndFunction

&AtServer
Function SubsystemsObjects()
	
	ObjectsAndSubsystemsMap1 = New ValueTable;
	ObjectsAndSubsystemsMap1.Columns.Add("Subsystem");
	ObjectsAndSubsystemsMap1.Columns.Add("Object");
	
	// Run a check similar to CAC, across the second level of subsystems nesting.
	
	For Each FirstLevelSubsystem In Metadata.Subsystems Do
		For Each SecondLevelSubsystem In FirstLevelSubsystem.Subsystems Do
			For Each ThirdLevelSubsystem In SecondLevelSubsystem.Subsystems Do
				SupplementMapWithSubsystemObjects(ObjectsAndSubsystemsMap1, ThirdLevelSubsystem);
			EndDo;
			SupplementMapWithSubsystemObjects(ObjectsAndSubsystemsMap1, SecondLevelSubsystem);
		EndDo;
		SupplementMapWithSubsystemObjects(ObjectsAndSubsystemsMap1, FirstLevelSubsystem);
	EndDo;
	
	Return ObjectsAndSubsystemsMap1;
	
EndFunction

&AtServer
Procedure SupplementMapWithSubsystemObjects(ObjectsAndSubsystemsMap1, SubsystemToResearch)
	For Each CompositionObject In SubsystemToResearch.Content Do
		If IsNotDemoExtensionObject(CompositionObject) Then
			// Check only demo extensions.
			Continue;
		EndIf;
		
		NewMap = ObjectsAndSubsystemsMap1.Add();
		NewMap.Subsystem = SubsystemToResearch;
		NewMap.Object = CompositionObject;
	EndDo;
EndProcedure

&AtClient
Function GetTextFileByPath(ExchangeDirectory, FileName)
	SearchFile = FindFiles(ExchangeDirectory, FileName, True);
	If SearchFile.Count() = 0 Then
		Return Undefined;
	EndIf;
	FileText = New TextDocument;
	FileText.Read(SearchFile[0].FullName);
	Return FileText;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Attachable functions
//
// Details of checker functions:
// The functions can be run on both the client and the server.
// Return value: "Undefined" if no errors are found.
//
// Otherwise, a structure: ("ErrorPresentation, PatchDetails, InvalidData",
//  <User-readable error representation - String>, <User-readable fixing instruction - String>.
//  <A list of error representations - ValueList>).
//
// If a string presentation is enough
// (for example, to warn that the modules don't match without specifying the location),
// then pass "Undefined" as the second parameter.

&AtServer
Function Attachable_Check_DemoObjectsNamesValidity()
	
	MetadataTypesList = MetadataTypeToCheck();
	NotSubordinateObjectsList = New ValueList;
	
	For Each MetadataTypeInList In MetadataTypesList Do
		MetadataType = MetadataTypeInList.Value;
		For Each SpecifiedTypeMetadataObject In Metadata[MetadataType] Do
			If MetadataType = "SessionParameters"
				Or MetadataType = "Roles"
				Or StrStartsWith(SpecifiedTypeMetadataObject.Name, "RegistryAccessKeys_Demo")
				Or StrStartsWith(SpecifiedTypeMetadataObject.Name, "Delete_Demo") Then
					
				Continue;
			EndIf;
			
			If IsNotDemoExtensionObject(SpecifiedTypeMetadataObject) Then
				// Check only demo extensions.
				Continue;
			EndIf;
			
			If StrFind(SpecifiedTypeMetadataObject.Name, "_Demo") > 0 And Left (SpecifiedTypeMetadataObject.Name, 5) <> "_Demo" Then
				NotSubordinateObjectsList.Add(NameOfMetadata(SpecifiedTypeMetadataObject), 
					SpecifiedTypeMetadataObject.FullName());
			EndIf;
		EndDo;
	EndDo;
	PatchDetails = NStr("ru = 'Демо-объекты именуются с префиксом ""_Демо"" в начале имени. Исключение - объекты типа ""Параметры сеанса"" и ""Роли"", где данный префикс
			|может находиться в середине имени.';
			|en = 'Demo objects are named with the ""_Demo"" prefix at the beginning of their names. An exception: in objects like ""Session parameters"" and ""Roles"" this prefix
			|can be in the middle of the name.';");
	Return New Structure("ErrorPresentation, PatchDetails, InvalidData",
		NStr("ru = 'Неправильно названы демо-объекты';
			|en = 'Demo object names are incorrect';"), 
		PatchDetails, NotSubordinateObjectsList);
EndFunction

&AtServer
Function Attachable_CheckObjectsInclusionInSubsystems()
	
	Result = New Array();
	InvalidObjects = CheckObjectBelonging();
	
	ErrorPresentation = NStr("ru = 'Объекты не принадлежат ни одной поставляемой подсистеме.';
								|en = 'The objects do not belong to built-in subsystems.';");
	PatchDetails = NStr("ru = 'Все объекты метаданных в конфигурации должны быть подчинены одной поставляемой подсистеме.
		|Исключение составляют только те объекты, которые не могут быть подчинены подсистемам в текущей версии платформы.';
		|en = 'All metadata objects in the configuration must be subordinate to a single built-in subsystem.
		|The exception is objects that cannot be subordinated to the subsystems in the current platform version.';");
	ErrorsStructure =  New Structure("ErrorPresentation, PatchDetails, InvalidData", 
		ErrorPresentation, PatchDetails, InvalidObjects.NotSubordinateObjects);
	Result.Add(ErrorsStructure);
	
	ErrorPresentation = NStr("ru = 'Объекты принадлежат более чем одной поставляемой подсистеме.';
								|en = 'The objects belong to more than one built-in subsystem.';");
	ErrorsStructure =  New Structure("ErrorPresentation, PatchDetails, InvalidData", 
		ErrorPresentation, PatchDetails, InvalidObjects.RedundantSubordinateObjects);
	Result.Add(ErrorsStructure);
	
	Return Result;
EndFunction

&AtServer
Function Attachable_Check_DemoObjectsInclusion()

	InvalidObjectsList = New ValueList;
	SubsystemsObjectsList = SubsystemsObjects();
	
	For Each ObjectSubordinationToSubsystem In SubsystemsObjectsList Do
		
		If IsSuppliedSubsystem(ObjectSubordinationToSubsystem.Subsystem)
			And StrStartsWith(ObjectSubordinationToSubsystem.Object.Name, "_Demo") Then
			InvalidObjectsList.Add(String(ObjectSubordinationToSubsystem.Object), 
				ObjectSubordinationToSubsystem.Object.FullName());
		EndIf;
		
	EndDo;
	
	PatchDetails = NStr("ru = 'Демонстрационные объекты не должны быть включены в поставляемые подсистемы';
								|en = 'Demo objects must not be included in 1C-supplied subsystems';");
	ErrorPresentation = NStr("ru = 'Следующие демонстрационные объекты включены в поставляемые подсистемы';
								|en = 'The following demo objects are included in 1C-supplied subsystems';");
	ErrorsStructure =  New Structure("ErrorPresentation, PatchDetails, InvalidData", 
		ErrorPresentation, PatchDetails, InvalidObjectsList);
	Return ErrorsStructure;
	
EndFunction

&AtClient
Function Attachable_Check_DemoExamplesCommentsValidity()

	FileText = New TextDocument;
	InvalidObjectsList  = New ValueList;
	
	If ModulesExportDirectory = "" Then
		UploadConfigurationToXML(ModulesExportDirectory);
	EndIf;
	
	ModulesArray = FindFiles(ModulesExportDirectory, "*.bsl", True);
	
	For Each ModuleFile In ModulesArray Do
		
		If StrFind(ModuleFile.FullName, "GoToVersion1") > 0
			Or StrFind(ModuleFile.FullName, "SSLImplementationCheck") > 0
			Or StrFind(ModuleFile.FullName, "UploadConfigurationToFilesMessages") > 0 Then
			Continue;
		EndIf;
		
		CurrentRowNumber = 0;
		FileText.Read(ModuleFile.FullName);
		RowsCount = FileText.LineCount();
		
		While CurrentRowNumber < RowsCount Do
			
			CheckString = FileText.GetLine(CurrentRowNumber);
			If StrFind(CheckString, "Demo ") = 0 Then
				CurrentRowNumber = CurrentRowNumber + 1;
				Continue;
			Else
				If (StrFind(CheckString, "_Demo begin example") = 0 And StrFind(CheckString, "_Demo end example") = 0) 
						And StrFind(CheckString, "//")> 0 Then
					ErrorString = "%1 : %2";
					FullName_Structure = FullNameByModuleName(ModuleFile.FullName, ModuleFile.Name);
					ErrorString = StringFunctionsClientServer.SubstituteParametersToString(ErrorString, FullName_Structure.FullModuleName, "String " + CurrentRowNumber);
					InvalidObjectsList.Add(ErrorString, FullName_Structure.FullObjectName);
				EndIf;
			EndIf;
			CurrentRowNumber = CurrentRowNumber + 1;
		EndDo;
	EndDo;
	
	ErrorPresentation = NStr("ru = 'Возможно неправильное комментирование демонстрационных примеров';
								|en = 'Demo examples may be commented incorrectly';");
	PatchDetails = NStr("ru = 'Демонстрационные примеры выделяются в коде с помощью комментариев вида 
		|//_Демо начало примера
		|<Код примера>
		|//_Демо конец примера
		|Другие представления демонстрационных примеров в коде запрещены.';
		|en = 'Demo examples are enclosed in the following comments:
		|//_Demo Example Start
		|<Example code>
		|//_Demo Example End
		|Other formats of demo examples in code are forbidden.';");
	ErrorsStructure =  New Structure("ErrorPresentation, PatchDetails, InvalidData",
		ErrorPresentation, PatchDetails, InvalidObjectsList);
	Return ErrorsStructure;
	
EndFunction

&AtServer
Function Attachable_CheckRightToViewListsOpeningCommandsInRoles()
	
	MetadataObjectsCollections1 = New Array;
	MetadataObjectsCollections1.Add(Metadata.Catalogs);
	MetadataObjectsCollections1.Add(Metadata.Documents);
	MetadataObjectsCollections1.Add(Metadata.DocumentJournals);
	MetadataObjectsCollections1.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataObjectsCollections1.Add(Metadata.ChartsOfAccounts);
	MetadataObjectsCollections1.Add(Metadata.ChartsOfCalculationTypes);
	MetadataObjectsCollections1.Add(Metadata.InformationRegisters);
	MetadataObjectsCollections1.Add(Metadata.AccumulationRegisters);
	MetadataObjectsCollections1.Add(Metadata.AccountingRegisters);
	MetadataObjectsCollections1.Add(Metadata.CalculationRegisters);
	MetadataObjectsCollections1.Add(Metadata.BusinessProcesses);
	MetadataObjectsCollections1.Add(Metadata.Tasks);
	
	InvalidObjectsList = New ValueList;
	
	For Each MetadataObjectCollection In MetadataObjectsCollections1 Do
		For Each MetadataObject In MetadataObjectCollection Do
			Command = MetadataObject.Commands.Find(MetadataObject.Name);
			If Command = Undefined Then
				Continue;
			EndIf;
			For Each Role In Metadata.Roles Do
				ObjectRight = AccessRight("View", MetadataObject, Role);
				CommandRight = AccessRight("View", Command, Role);
				If ObjectRight And Not CommandRight Then
					
					// Skip commands that open object editors or object list editors.
					// Such commands must not be included in "read-only" roles intended.
					ObjectEditCommand = NStr("ru = 'Открывает форму для редактирования';
															|en = 'Opens form for editing';");
					If StrStartsWith(Command.Comment, ObjectEditCommand)
						And Not AccessRight("Edit", MetadataObject, Role) Then
						Continue;
					EndIf;
					
					InvalidObjectsList.Add(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Не хватает права Просмотр для дополнительной команды ""%1"" объекта метаданных ""%2"" в роли ""%3"".';
							|en = 'The View right is missing for the %1 additional command of the %2 metadata object in the %3 role.';"),
						Command.Name,
						MetadataObject.FullName(),
						Role.Name), NameOfMetadata(MetadataObject));
						
				ElsIf Not ObjectRight And CommandRight Then
					InvalidObjectsList.Add(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Лишнее право Просмотр для дополнительной команды ""%1"" объекта метаданных ""%2"" в роли ""%3"".';
							|en = 'The View right is excess for the %1 additional command of the %2 metadata object in the %3 role.';"),
						Command.Name,
						MetadataObject.FullName(),
						Role.Name), NameOfMetadata(MetadataObject));
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	ErrorPresentation = NStr("ru = 'Объекты имеют различный доступ со своими дополнительными командами открытия списков';
								|en = 'The objects have different access with their own additional commands for opening lists';");
	PatchDetails = NStr("ru = 'Все объекты метаданных должны иметь одинаковые права на просмотр со своими дополнительными командами открытия списков.';
								|en = 'All metadata objects must have the same view rights with their own additional commands for opening lists.';");
	
	ErrorsStructure =  New Structure(
		"ErrorPresentation, PatchDetails, InvalidData",
		ErrorPresentation, PatchDetails, InvalidObjectsList);
	Return ErrorsStructure;
	
EndFunction

&AtServer
Function Attachable_CheckRolesAndAccessKindsInclusionInProfiles()
	
	ExclusionRoles = New Map;
	ExclusionRoles.Insert("Administration", True);
	ExclusionRoles.Insert("StartAutomation", True);
	ExclusionRoles.Insert("StartExternalConnection", True);
	ExclusionRoles.Insert("StartThickClient", True);
	ExclusionRoles.Insert("InteractiveOpenExtReportsAndDataProcessors", True);
	ExclusionRoles.Insert("UpdateDataBaseConfiguration", True);
	ExclusionRoles.Insert("TechnicianMode", True);
	ExclusionRoles.Insert("UpdateDataBaseConfiguration", True);
	ExclusionRoles.Insert("Subsystem_DemoDeveloperTools", True);
	ExclusionRoles.Insert("RemoteAccessMessageExchange", True);
	ExclusionRoles.Insert("RemoteODataAccess", True);
	ExclusionRoles.Insert("RemoteAccessDataExchangeSaaS", True);
	ExclusionRoles.Insert("RemoteControl", True);
	
	AccessKindsExceptions = New Map;
	
	InvalidObjectsList = New ValueList;
	AccessManagementInternal.UpdateAccessKindsPropertiesDetails();
	Catalogs.AccessGroupProfiles.UpdateSuppliedProfilesDescription();
	RefreshReusableValues();
	AccessKindsProperties = AccessManagementInternal.AccessKindsProperties();
	ProfilesDetails     = AccessManagementInternal.SuppliedProfiles().ProfilesDetails;
	AccessKindsArray    = AccessKindsProperties.Array;
	
	ProfilesRoles = New Map;
	ProfilesAccessKinds = New Map;
	For Each ProfileDetails In ProfilesDetails Do
		If ProfileDetails.Value.IsFolder Then
			Continue;
		EndIf;
		For Each Role In ProfileDetails.Value.Roles Do
			ProfilesRoles.Insert(Role, True);
		EndDo;
		For Each String In ProfileDetails.Value.AccessKinds Do
			ProfilesAccessKinds.Insert(String.Key, True);
		EndDo;
	EndDo;
	
	For Each AccessKindProperties In AccessKindsArray Do
		AccessKindName = AccessKindProperties.Name;
		
		If AccessKindsExceptions.Get(AccessKindName) <> Undefined
		 Or ProfilesAccessKinds.Get(AccessKindName) <> Undefined Then
			
			Continue;
		EndIf;
		
		InvalidObjectsList.Add(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Вид доступа ""%1"".';
				|en = 'Access kind %1.';"), AccessKindName));
	EndDo;
	
	For Each Role In Metadata.Roles Do
		If Role.ConfigurationExtension() <> Undefined Then
			Continue;
		EndIf;
		
		NameOfRole = Role.Name;
		
		If StrFind(NameOfRole, "_Demo") = 0 And Not SSLRole(Role) Then
			Continue;
		EndIf;
		
		If ExclusionRoles.Get(NameOfRole) <> Undefined
		 Or ProfilesRoles.Get(NameOfRole) <> Undefined
		 Or StrFind(NameOfRole, "Profile_") > 0 Then
			
			Continue;
		EndIf;
		
		InvalidObjectsList.Add(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Роль ""%1"".';
				|en = 'Role %1.';"), NameOfRole), Role.FullName());
	EndDo;
	
	ErrorPresentation = NStr("ru = 'Роль или вид доступа не задействована ни в одном из профилей';
								|en = 'The role or access kind is not used in any of the profiles';");
	PatchDetails = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Это означает, что работа приложения с этой ролью (видом доступа) не тестируется и не демонстрируется в демо-базе.
			|Для исправления: 
			|- Включите роль (или вид доступа) в одно из описаний поставляемых или демонстрационный профилей групп доступа, см. %1;
			|- Опишите нововведение в UpdateSSL и в документации для разработчиков (в разделе ""Настройка прав доступа пользователей"");
			|- Затем направьте техническому писателю для включения в пользовательскую документацию (глава 5 https://its.1c.ru/db/bspdoc).';
			|en = 'It means that the application operation with this role or access kind is not tested and not demonstrated in the demo infobase.
			|To fix it: 
			|- Include the role or access kind in one of the descriptions of the built-in or demo profiles of access groups. See %1.
			|- Describe the update in UpdateSSL and in the documentation for developers (the ""User access setup"" section).
			|- Send the description to the technical writer so that they include it in the user documentation.';"),
		"_DemoStandardSubsystems.OnFillSuppliedAccessGroupProfiles");
	
	ErrorsStructure =  New Structure;
	ErrorsStructure.Insert("ErrorPresentation", ErrorPresentation);
	ErrorsStructure.Insert("PatchDetails", PatchDetails);
	ErrorsStructure.Insert("InvalidData",     InvalidObjectsList);
	
	Return ErrorsStructure;
	
EndFunction

&AtClient
Function Attachable_CheckSubsystemsCodeBlocksComments()
	
	InvalidObjectsList = New ValueList;
	
	If ModulesExportDirectory = "" Then
		UploadConfigurationToXML(ModulesExportDirectory);
	EndIf;
	
	SubsystemsArray = UsedSubsystemsList(False);
	ModulesArray = FindFiles(ModulesExportDirectory, "*.bsl", True);	
	FileText = New TextDocument;
	
	Status(NStr("ru = 'Проверка комментариев для блоков кода';
					|en = 'Check comments for code blocks';"));
	
	For Each File In ModulesArray Do
		
		FileText.Read(File.FullName);
		TextString = FileText.GetText();
		
		For Each Subsystem In SubsystemsArray Do
			DetermineCommentsErrors(File, Subsystem, TextString, InvalidObjectsList);
		EndDo;
	EndDo;
	
	ErrorPresentation = NStr("ru = 'Указаны неверные комментарии для блоков кода подсистем';
								|en = 'Incorrect comments for subsystem code blocks';");
	PatchDetails = NStr("ru = 'Для всех блоков кода, относящихся к той или иной подсистеме, используются начальные и конечные комментарии вида:
		|<%1>
		|...
		|Конец <%1>';
		|en = 'All code blocks that belong to a particular subsystem use initial and final comments of the following kind:
		|<%1>
		|…
		|End <%1>';");
	PatchDetails = StringFunctionsClientServer.SubstituteParametersToString(PatchDetails, "SubsystemPath");
	
	ErrorsStructure =  New Structure(
		"ErrorPresentation, PatchDetails, InvalidData",
		ErrorPresentation, PatchDetails, InvalidObjectsList);
	Return ErrorsStructure;
	
EndFunction

&AtClient
Function IsException(FullObjectName)
	
	If DeveloperTools.FindByValue(FullObjectName) <> Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Function Attachable_CheckConditionalCallsValidity()
	
	InvalidObjectsList = New ValueList;
	
	If ModulesExportDirectory = "" Then
		UploadConfigurationToXML(ModulesExportDirectory);
	EndIf;
	
	ModulesArray = FindFiles(ModulesExportDirectory, "*.bsl", True);
	
	UsedSubsystemsList = UsedSubsystemsList();
	UsedSubsystemsList.Add("StandardSubsystems");
	FileText = New TextDocument;
	
	Status(NStr("ru = 'Проверка условных вызовов';
					|en = 'Check conditional calls';"));
	
	For Each File In ModulesArray Do
		
		FileText.Read(File.FullName);
		TextString = FileText.GetText();
		
		ConditionalCallString = "Common.SubsystemExists(""";
		ConditionalCallString2 = "CommonClient.SubsystemExists(""";
		DefineConditionalCallsErrors(File, TextString, InvalidObjectsList, UsedSubsystemsList, ConditionalCallString);
		DefineConditionalCallsErrors(File, TextString, InvalidObjectsList, UsedSubsystemsList, ConditionalCallString2);
	EndDo;
	
	ErrorPresentation = NStr("ru = 'Несуществующая подсистема при вызове функции %1';
								|en = 'Non-existent subsystem when calling function %1';");
	ErrorPresentation = StringFunctionsClientServer.SubstituteParametersToString(ErrorPresentation, "SubsystemExists");
	PatchDetails = NStr("ru = 'Название подсистемы должно задаваться с учетом иерархии в виде - ""%1""
		|или ""%2"" :';
		|en = 'The subsystem name must be specified considering hierarchy in kind of ""%1""
		|or ""%2"":';");
	PatchDetails = StringFunctionsClientServer.SubstituteParametersToString(PatchDetails,
		"StandardSubsystems.SubsystemName", "StandardSubsystems.SubsystemName1.SubsystemName2");
	
	ErrorsStructure =  New Structure(
		"ErrorPresentation, PatchDetails, InvalidData",
		ErrorPresentation, PatchDetails, InvalidObjectsList);
	Return ErrorsStructure;
	
EndFunction

&AtClient
Function Attachable_CheckHasInteractiveDeleteRight()
	
	InvalidObjectsList = CheckRolesRights("InteractiveDelete", "AllRoles");
	
	ErrorPresentation = NStr("ru = 'Недопустимо наличие права ""Интерактивное удаление""';
								|en = 'The ""Delete interactively"" right is not allowed';");
	PatchDetails = Undefined;
	ErrorsStructure =  New Structure(
		"ErrorPresentation, PatchDetails, InvalidData",
		ErrorPresentation, PatchDetails, InvalidObjectsList);
	Return ErrorsStructure;
	
EndFunction

&AtClient
Function Attachable_IncorrectLinksBetweenSubsystems()
	
	If ModulesExportDirectory = "" Then
		UploadConfigurationToXML(ModulesExportDirectory);
	EndIf;
	
	InvalidObjectsList = IncorrectLinksBetweenSubsystems();
	
	ErrorPresentation = NStr("ru = 'Недопустимо наличие недокументированных связей между подсистемами';
								|en = 'Undocumented links between subsystems are not allowed';");
	PatchDetails = NStr("ru = 'Связи между подсистемами делают невозможным выборочное встраивание библиотеки в конфигурацию, поэтому их следует избегать. 
		|Варианты исправления:
		|- Сделайте связь необязательной (рекомендуется). Замените явный вызов на условный с помощью функций %7 и %8. В документации укажите, какие ключевые возможности будут доступны при совместном использовании с другими подсистемами.
		|- Обязательные зависимости укажите в функции %1 модуля объекта обработки %2, а также в документации.
		|
		|Исключения из этого правила согласуются с ответственным за БСП и вносятся в макет %3 в формате:
		|%4-%5-%6';
		|en = 'Links between subsystems disable selective library embedding into the configuration. That is why, try to avoid such links. 
		|How to fix the issue:
		|- Make the link optional (recommended). Replace the explicit call with a conditional call using the %7 and %8 functions. In the documentation, specify key features that will be available when used with other subsystems.
		|- Specify required dependencies in the %1 function of the %2 data processor object module and in the documentation.
		|
		|Make sure you approve the exceptions to this rule with the person responsible for SSL and enter them into the %3 template in the following format:
		|%4-%5-%6';");
	
	PatchDetails = StringFunctionsClientServer.SubstituteParametersToString(PatchDetails,
		"SubsystemsDependencies",
		"FirstSSLDeployment",
		"Report.SubsystemsDependencies.ExceptionObjects",
		"CallingSubsystem", "SubsystemToCall", "CallingObject", 
		"Common.SubsystemExists", "Common.CommonModule");
	
	ErrorsStructure =  New Structure(
		"ErrorPresentation, PatchDetails, InvalidData",
		ErrorPresentation, PatchDetails, InvalidObjectsList);
	Return ErrorsStructure;
	
EndFunction

&AtClient
Function Attachable_SearchForProhibitedComments()
	
	If ModulesExportDirectory = "" Then
		UploadConfigurationToXML(ModulesExportDirectory);
	EndIf;
	
	SearchString = "TO"+"DO";
	InvalidObjectsList = SearchForProhibitedCommentsInModulesCode(SearchString);
	
	ErrorPresentation = NStr("ru = 'Недопустимо наличие комментария ""%1"" в текстах модулей.';
								|en = 'Comment ""%1"" is not allowed in module texts.';");
	ErrorPresentation = StringFunctionsClientServer.SubstituteParametersToString(ErrorPresentation, SearchString);
	PatchDetails = Undefined;
	ErrorsStructure =  New Structure(
		"ErrorPresentation, PatchDetails, InvalidData",
		ErrorPresentation, PatchDetails, InvalidObjectsList);
	Return ErrorsStructure;
	
EndFunction

&AtClient
Function Attachable_PropertyUsageCheckHorizontalIfPossible()
	
	If ModulesExportDirectory = "" Then
		UploadConfigurationToXML(ModulesExportDirectory);
	EndIf;
	
	InvalidObjectsList = HorizontalIfPossibleGroups();
	
	ErrorPresentation = NStr("ru = 'Недопустимо устанавливать свойство группы ""Группировка"" в значение ""Горизонтальная если возможно""';
								|en = 'Set the property of the Grouping group to the ""Horizontal, if possible"" value is not allowed';");
	PatchDetails = NStr("ru = 'Установите свойство группы ""Группировка"" в значение ""Горизонтальная"" или ""Вертикальная""';
								|en = 'Set the Grouping group property to Horizontal or Vertical';");
	ErrorsStructure = New Structure(
		"ErrorPresentation, PatchDetails, InvalidData",
		ErrorPresentation, PatchDetails, InvalidObjectsList);
	Return ErrorsStructure;
	
EndFunction

&AtClient
Function Attachable_CheckIncludeInHelpContentFlagValue()
	
	InvalidObjectsList = IncludeProceduresWithFlagToHelpContent();
	
	ErrorPresentation = NStr("ru = 'Поставляемые подсистемы не должны содержать флаг ""Включать в содержание справки""';
								|en = '""Include in help contents"" check box is not allowed for 1C-supplied subsystems';");
	PatchDetails = Undefined;
	ErrorsStructure =  New Structure(
		"ErrorPresentation, PatchDetails, InvalidData",
		ErrorPresentation, PatchDetails, InvalidObjectsList);
	Return ErrorsStructure;
	
EndFunction

&AtClient
Function Attachable_CheckManagedAndOrdinaryApplicationModulesMatch()
	
	OrdinaryApplicationFileText     = New TextDocument;
	ManagedApplicationFileText = New TextDocument;
	
	If ModulesExportDirectory = "" Then
		UploadConfigurationToXML(ModulesExportDirectory);
	EndIf;
	
	OrdinaryApplicationFileText = GetTextFileByPath(ModulesExportDirectory, "OrdinaryApplicationModule.bsl");
	ManagedApplicationFileText = GetTextFileByPath(ModulesExportDirectory, "ManagedApplicationModule.bsl");
	
	List = New ValueList;
	
	// If one of the files is not found, throw an error.
	If OrdinaryApplicationFileText = Undefined Or ManagedApplicationFileText = Undefined Then
		List.Add("Not managedto find files modules applications.");
		Return New Structure("ErrorPresentation, PatchDetails, InvalidData",NStr("ru = 'Не удалось найти файлы модулей приложения.';
																								|en = 'Cannot find the application module files.';"),"", List) ;
	EndIf;
	
	ErrorPresentation = NStr("ru = 'Модули обычного и управляемого приложений различны.';
								|en = 'Modules of standard and managed applications differ.';");
	PatchDetails = NStr("ru = 'БСП поддерживает работу как в управляемом, так и в обычном приложении.
		|Соответственно, модули обычного и управляемого приложений должны совпадать за исключением специально предусмотренных случаев';
		|en = 'SSL supports work both in managed and ordinary application.
		|Accordingly, the modules of ordinary and managed applications must be the same, except for specially provided cases.';");
	
	// If the number of rows differ, throw an error.
	If OrdinaryApplicationFileText.LineCount() <> ManagedApplicationFileText.LineCount() Then
		List.Add(ErrorPresentation);
		Return New Structure("ErrorPresentation, PatchDetails, InvalidData", 
			ErrorPresentation, PatchDetails, List);
	EndIf;
	
	RowToCheckNumber = 0;
	
	While RowToCheckNumber < OrdinaryApplicationFileText.LineCount() Do
		
		If TrimAll(OrdinaryApplicationFileText.GetLine(RowToCheckNumber)) <> 
			TrimAll(ManagedApplicationFileText.GetLine(RowToCheckNumber)) Then
			List.Add(ErrorPresentation);
			Return New Structure("ErrorPresentation, PatchDetails, InvalidData", 
				ErrorPresentation, PatchDetails, List);
		EndIf;
		RowToCheckNumber = RowToCheckNumber + 1;
	EndDo;
	
	Return New Structure("ErrorPresentation, PatchDetails, InvalidData", 
		ErrorPresentation, PatchDetails, List);
	
EndFunction

&AtClient
Function Attachable_CheckDeferredUpdateHandlers()
	
	InvalidObjectsList = DeferredHandlersCheck();
	
	ErrorPresentation = NStr("ru = 'У отложенных обработчиков обновления не заполнены все необходимые свойства';
								|en = 'Not all required properties are filled in for deferred update handlers';");
	PatchDetails = NStr("ru = 'Заполните свойства %1, %2';
								|en = 'Fill in properties %1 and %2';");
	PatchDetails = StringFunctionsClientServer.SubstituteParametersToString(PatchDetails, "ReadableObject", "ObjectsToChange");
	ErrorsStructure =  New Structure(
		"ErrorPresentation, PatchDetails, InvalidData",
		ErrorPresentation, PatchDetails, InvalidObjectsList);
	Return ErrorsStructure;
	
EndFunction

&AtClient
Function Attachable_RightCheckCommandInterfaceSubsystemsView()
	
	InvalidObjectsList = RightCheckCommandInterfaceSubsystemsView();
	
	ErrorPresentation = NStr("ru = 'Подсистемы верхнего уровня (а также подчиненные им подсистемы), отображаемые в главном командном интерфейсе,
		|должны иметь право просмотр в роли %1<%2>';
		|en = 'Upper level subsystems (and subsystems subordinate to them) that are displayed in the main command interface
		|must have the right to view in role %1<%2>';");
	ErrorPresentation = StringFunctionsClientServer.SubstituteParametersToString(ErrorPresentation, "Subsystem", "TopLevelSubsystemName");
	
	PatchDetails = Undefined;
	ErrorsStructure =  New Structure(
		"ErrorPresentation, PatchDetails, InvalidData",
		ErrorPresentation, PatchDetails, InvalidObjectsList);
	Return ErrorsStructure;
	
EndFunction

&AtClient
Function Attachable_ConfigurationPlatformCheck()
	
	If ModulesExportDirectory = "" Then
		UploadConfigurationToXML(ModulesExportDirectory);
	EndIf;
	
	InvalidObjectsList = ConfigurationPlatformCheck();
	
	ErrorPresentation = NStr("ru = 'Платформенная проверка конфигурации не должна выдавать ошибок.';
								|en = 'Platform configuration check must not return errors.';");
	PatchDetails = NStr("ru = 'Если какая-то из ошибок является особенностью поведения платформы и не должна
		|или не может быть исправлена, то такую ошибку необходимо добавить в список исключений.
		|Для этого нужно скопировать всю строку ошибки и добавить ее с новой строки в макете
		|%1 обработки %2.';
		|en = 'If an error is a feature of the platform behavior and must not
		|or cannot be fixed, add such error to the list of exceptions.
		|To do this, copy the entire error line and add it on a new line of template
		|%1of data processor %2.';");
	PatchDetails = StringFunctionsClientServer.SubstituteParametersToString(PatchDetails,
		"PlarformCheckExceptions", "CheckSSLBeforeAssembly");
	ErrorsStructure =  New Structure(
		"ErrorPresentation, PatchDetails, InvalidData",
		ErrorPresentation, PatchDetails, InvalidObjectsList);
	Return ErrorsStructure;
	
EndFunction

&AtClient
Function Attachable_CheckRolesForUnauthorizedAccess()
	
	If ModulesExportDirectory = "" Then
		UploadConfigurationToXML(ModulesExportDirectory);
	EndIf;
	
	Errors = ValidateSSLRoles();
	
	Result = New Array;
	ErrorPresentation = NStr("ru = 'Найдены роли, дающие права на объекты других подсистем';
								|en = 'Roles that give rights to objects of other subsystems are found';");
	PatchDetails = NStr("ru = 'Если роль должна предоставлять доступ к объектам других подсистем,
		|то необходимо добавить в список исключений, в функции ""%1""
		|модуля формы обработки ""%2"".';
		|en = 'If a role must grant access to objects of other subsystems,
		|add it to the list of exceptions in function ""%1""
		|of data processor form module ""%2"".';");
	PatchDetails = StringFunctionsClientServer.SubstituteParametersToString(PatchDetails,
		"ExclusionRoles", "CheckSSLBeforeAssembly");
	
	
	ErrorsStructure = ErrorsStructure();
	ErrorsStructure.ErrorPresentation = ErrorPresentation;
	ErrorsStructure.PatchDetails = PatchDetails;
	ErrorsStructure.InvalidData     = Errors.OtherSSLSubsystems;
	ErrorsStructure.Urgency           = "HighPriority";
	Result.Add(ErrorsStructure);
	
	ErrorPresentation = NStr("ru = 'Роли БСП должны давать права только на объекты БСП';
								|en = 'SSL roles must grant rights only to SSL objects';");
	PatchDetails = Undefined;
	
	ErrorsStructure = ErrorsStructure();
	ErrorsStructure.ErrorPresentation = ErrorPresentation;
	ErrorsStructure.PatchDetails = PatchDetails;
	ErrorsStructure.InvalidData     = Errors.ThirdPartySubsystems;
	ErrorsStructure.Urgency           = "OnSchedule";
	Result.Add(ErrorsStructure);
	
	Return Result;
	
EndFunction

// The following checks do not support address registration of errors.

&AtServer
Function Attachable_FindNotRecommendedRolesSettings()
	
	If ModulesExportDirectory = "" Then
		UploadConfigurationToXML(ModulesExportDirectory);
	EndIf;
	
	Result = NotRecommendedRightsSettings(ModulesExportDirectory);
	
	ErrorsArray = New Array;
	
	InvalidObjectsList = New ValueList;
	If ValueIsFilled(Result.InvalidRightsSettings) Then
		Explanation = NStr("ru = '1.1. См. пункт 1 стандарта ""Проверка прав доступа"" https://its.1c.eu/db/v8std#content:737:hdoc
			|1.2. Для уменьшения размера выгрузки конфигурации в файлы права на поля должны быть установлены по умолчанию.';
			|en = '1.1. See clause 1 of the <link https://kb.1ci.com/1C_Enterprise_Platform/Guides/Developer_Guides/1C_Enterprise_Development_Standards/Setting_data_access_rights/Verifying_access_rights/>Verifying access rights</> standard.
			|1.2. To reduce the size of the exported configuration, use default field rights.';");
		InvalidObjectsList.Add(Explanation + Chars.LF + Result.InvalidRightsSettings);
	EndIf;
	ErrorPresentation =
		NStr("ru = 'Право на поле отличается от права на поле по умолчанию для роли (есть права на объект)';
			|en = 'Field right does not match the default field right for the role (has rights to object)';");
	
	ErrorsStructure = ErrorsStructure();
	ErrorsStructure.ErrorPresentation = ErrorPresentation;
	ErrorsStructure.PatchDetails = Undefined;
	ErrorsStructure.InvalidData     = InvalidObjectsList;
	ErrorsStructure.Urgency           = "OnSchedule";
	ErrorsArray.Add(ErrorsStructure);
	
	InvalidObjectsList = New ValueList;
	If ValueIsFilled(Result.NonDefaultRights) Then
		InvalidObjectsList.Add(Result.NonDefaultRights);
	EndIf;
	
	ErrorPresentation =
		NStr("ru = 'Право на поле отличается от права на поле по умолчанию для роли (нет прав на объект)';
			|en = 'Field right does not match the default field right for the role (no rights to object)';");
	
	ErrorsStructure = ErrorsStructure();
	ErrorsStructure.ErrorPresentation = ErrorPresentation;
	ErrorsStructure.PatchDetails = Undefined;
	ErrorsStructure.InvalidData     = InvalidObjectsList;
	ErrorsStructure.Urgency           = "OnSchedule";
	ErrorsArray.Add(ErrorsStructure);
	
	Return ErrorsArray;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and check functions.

&AtServer
Function ValidateSSLRoles()
	
	Errors = New Structure("OtherSSLSubsystems, ThirdPartySubsystems");
	FillObjectsInclusionInSubsystems();
	
	Separator = GetPathSeparator();
	
	RolesExportDirectory = StringFunctionsClientServer.SubstituteParametersToString("%1%2Roles", ModulesExportDirectory,
		Separator);
	RolesDirectory         = New File(RolesExportDirectory);
	If Not RolesDirectory.Exists() Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Каталог выгрузки ролей ""%1"" не существует.';
																						|en = 'Role import directory %1 does not exist.';"),
			RolesExportDirectory);
	EndIf;
	
	AllSubsystems       = AllSubsystems();
	SSLSubsystems       = AllSubsystems.SSLSubsystems;
	ThirdPartySubsystems = AllSubsystems.ThirdPartySubsystems;
	
	ExclusionRoles                     = ExclusionRoles();
	DenyAccessToThirdPartySubsystems = ExclusionRoles.DenyAccessToThirdPartySubsystems;
	DenyAccessToOtherSSLSubsystems = ExclusionRoles.DenyAccessToOtherSSLSubsystems;
	
	Errors.ThirdPartySubsystems = CheckRolesForAccess(DenyAccessToThirdPartySubsystems, SSLSubsystems, ThirdPartySubsystems);
	Errors.OtherSSLSubsystems = CheckRolesForAccess(DenyAccessToOtherSSLSubsystems, SSLSubsystems, SSLSubsystems, "BSP");
	
	Return Errors;
	
EndFunction

&AtServer
Function ExclusionRoles()
	
	ExceptionStructure = New Structure;
	ExceptionStructure.Insert("DenyAccessToThirdPartySubsystems", New Array);
	ExceptionStructure.Insert("DenyAccessToOtherSSLSubsystems", New Array);
	
	ExceptionStructure.DenyAccessToThirdPartySubsystems.Add("FullAccess");
	ExceptionStructure.DenyAccessToThirdPartySubsystems.Add("SystemAdministrator");
	ExceptionStructure.DenyAccessToThirdPartySubsystems.Add("RemoteODataAccess");
	
	ExceptionStructure.DenyAccessToOtherSSLSubsystems.Add("FullAccess");
	ExceptionStructure.DenyAccessToOtherSSLSubsystems.Add("SystemAdministrator");
	ExceptionStructure.DenyAccessToOtherSSLSubsystems.Add("RemoteODataAccess");
	ExceptionStructure.DenyAccessToOtherSSLSubsystems.Add("BasicAccessSSL");
	ExceptionStructure.DenyAccessToOtherSSLSubsystems.Add("BasicAccessExternalUserSSL");
	
	Return ExceptionStructure;
	
EndFunction

&AtServer
Function AllSubsystems()
	
	SubsystemsStructure = New Structure;
	SubsystemsStructure.Insert("ThirdPartySubsystems", New Array);
	SubsystemsStructure.Insert("SSLSubsystems"      , New Array);
	
	Subsystems            = Metadata.Subsystems;
	StandardSubsystems = Subsystems.StandardSubsystems;
	SubsystemsArray       = New Array;
	
	For Each Subsystem In Subsystems Do
		
		FillSubordinateSubsystemsArray(Subsystem, SubsystemsArray);
		
	EndDo;
	
	For Each Subsystem In SubsystemsArray Do
		
		SubsystemParent1 = SubsystemParent1(Subsystem);
		
		If SubsystemParent1 = StandardSubsystems Then
			SubsystemsStructure.SSLSubsystems.Add(Subsystem);
		Else
			SubsystemsStructure.ThirdPartySubsystems.Add(Subsystem);
		EndIf;
		
	EndDo;
	
	Return SubsystemsStructure;
	
EndFunction

&AtServer
Procedure FillSubordinateSubsystemsArray(Subsystem, SubsystemsArray)
	
	If SubsystemsArray.Find(Subsystem) = Undefined Then
		SubsystemsArray.Add(Subsystem);
	EndIf;
	
	Subsystems = Subsystem.Subsystems;
	
	For Each InternalSubsystem In Subsystems Do
		FillSubordinateSubsystemsArray(InternalSubsystem, SubsystemsArray);
	EndDo;
	
EndProcedure

&AtServer
Function SubsystemParent1(Subsystem)
	
	Parent = Subsystem.Parent();
	If Parent.Parent() = Undefined Then
		Return Subsystem;
	Else
		Return SubsystemParent1(Parent);
	EndIf;
	
EndFunction

&AtServer
Function SubsystemRoles(Subsystem)
	
	SubsystemRoleArray = New Array;
	SubsystemComposition     = Subsystem.Content;
	
	For Each CompositionItem In SubsystemComposition Do
		If IsRole(CompositionItem) Then
			SubsystemRoleArray.Add(CompositionItem);
		EndIf;
	EndDo;
	
	Return SubsystemRoleArray;
	
EndFunction

&AtServer
Function CheckRolesForAccess(ExclusionRoles, SSLSubsystems, ThirdPartySubsystems, AccessSectionAsString = "")
	
	InvalidObjectsList = New ValueList;
	For Each SSLSubsystem In SSLSubsystems Do
		
		SubsystemRoles = SubsystemRoles(SSLSubsystem);
		
		For Each SubsystemRole In SubsystemRoles Do
			
			If ExclusionRoles.Find(SubsystemRole.Name) = Undefined Then
				
				ErrorString = UnauthorizedRoleAccess(SubsystemRole.Name, SSLSubsystem, SSLSubsystems, ThirdPartySubsystems,
					AccessSectionAsString);
					
				If ValueIsFilled(ErrorString) Then
					InvalidObjectsList.Add(ErrorString, SubsystemRole.FullName());
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return InvalidObjectsList;
	
EndFunction

&AtServer
Function ObjectIncludedInSubsystemComposition(Subsystem, FullName)
	ObjectSubsystems = ObjectsAndSubsystemsMap[FullName];
	If ObjectSubsystems = Undefined Then
		If Subsystem.FullName() = FullName Then
			Return True;
		Else
			Return False;
		EndIf;
	EndIf;
	Return ObjectSubsystems.Find(Subsystem) <> Undefined;
EndFunction

&AtServer
Function ObjectIncludedInStandardSubsystemsComposition(SSLSubsystems, RoleObject)
	
	ObjectIncludedInComposition = False;
	
	For Each SSLSubsystem In SSLSubsystems Do
		If ObjectIncludedInSubsystemComposition(SSLSubsystem, RoleObject) Then
			ObjectIncludedInComposition = True;
			Break;
		EndIf;
	EndDo;
	
	Return ObjectIncludedInComposition;
	
EndFunction

&AtServer
Function UnauthorizedRoleAccess(Role, CheckedSubsystem, SSLSubsystems, ThirdPartySubsystems, AccessSectionAsString = "")
	
	ErrorString   = "";
	ListOfObjects = "";
	
	RoleObjects  = RoleObjects(Role);
	
	For Each CurrentSubsystem In ThirdPartySubsystems Do
		
		For Each RoleObjectKeyAndValue In RoleObjects Do
			RoleObject = RoleObjectKeyAndValue.Key;
			
			If AccessSectionAsString = "BSP" Then
				
				If ObjectIncludedInSubsystemComposition(CurrentSubsystem, RoleObject)
					And Not ObjectIncludedInSubsystemComposition(CheckedSubsystem, RoleObject)
					And CurrentSubsystem.FullName() <> CheckedSubsystem.FullName() Then
					
					ListOfObjects = ListOfObjects + ?(ValueIsFilled(ListOfObjects), Chars.LF + "- ", "- ")
						+ FullObjectNameTranslationToNationalLanguage(RoleObject)
						+ " (" + StrReplace(CurrentSubsystem.FullName(), "Subsystem.", "") + ")";
						
				EndIf;
				
			Else
				
				If ObjectIncludedInSubsystemComposition(CurrentSubsystem, RoleObject)
					And Not ObjectIncludedInStandardSubsystemsComposition(SSLSubsystems, RoleObject) Then
					
					ListOfObjects = ListOfObjects + ?(ValueIsFilled(ListOfObjects), Chars.LF + "- ", "- ")
						+ FullObjectNameTranslationToNationalLanguage(RoleObject)
						+ " (" + StrReplace(CurrentSubsystem.FullName(), "Subsystem.", "") + ")";
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	If ValueIsFilled(ListOfObjects) Then
		ErrorTemplate = NStr("ru = 'Роль:
			|- %1 (%2)
			|Дает права на объекты:
			|%3';
			|en = 'Role:
			|- %1 (%2)
			|Grants rights to objects:
			|%3';");
		ErrorString = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
			Role, StrReplace(CheckedSubsystem.FullName(), "Subsystem.", ""), ListOfObjects);
	EndIf;
	
	Return ErrorString;
	
EndFunction

&AtServer
Function IsRole(MetadataObject)
	
	Return Metadata.Roles.Contains(MetadataObject);
	
EndFunction

&AtServer
Function RoleObjects(NameOfRole)
	
	Separator = GetPathSeparator();
	RoleObjects = New Map;
	
	PathToRole = StringFunctionsClientServer.SubstituteParametersToString("%1%2Roles%2%3%2Ext%2Rights.xml",
		ModulesExportDirectory, Separator, NameOfRole);
	
	DOMDocument = DOMDocument(PathToRole);
	Nodes        = DOMDocument.GetElementByTagName("Object");
	EnglishAndNationalNamesMap = EnglishAndNationalNamesMap();
	For Each Node In Nodes Do
		ObjectParts = StrSplit(Node.FirstChild.TextContent, ".");
		If StrFind(Node.FirstChild.TextContent, "Subsystem") Then
			NewObjectInParts = New Array;
			For Each ObjectPart In ObjectParts Do
				ObjectPartInNationalLanguage = EnglishAndNationalNamesMap[ObjectPart];
				If ObjectPartInNationalLanguage <> Undefined Then
					NewObjectInParts.Add(ObjectPartInNationalLanguage);
				Else
					NewObjectInParts.Add(ObjectPart);
				EndIf;
			EndDo;
			FullObjectName = StrConcat(NewObjectInParts, ".");
		Else
			If ObjectParts.Count() > 2 Then
				// Check rights to objects only.
				Continue;
			EndIf;
			FullObjectName = EnglishAndNationalNamesMap[ObjectParts[0]] + "." + ObjectParts[1];
		EndIf;
		
		RoleObjects.Insert(FullObjectName);
	EndDo;
	
	Return RoleObjects;
	
EndFunction

&AtServer
Function FullObjectNameTranslationToNationalLanguage(Val TranslationObject)
	
	TranslatedObject                 = "";
	EnglishAndNationalNamesMap = EnglishAndNationalNamesMap();
	TranslationObject                     = StrSplit(TranslationObject, ".");
	
	For Each TransformedPathPart In TranslationObject Do
		TranslatePart       = EnglishAndNationalNamesMap[TransformedPathPart];
		TranslatedObject = TranslatedObject + ?(ValueIsFilled(TranslatedObject), ".", "")
			+ ?(TranslatePart = Undefined, TransformedPathPart, TranslatePart);
	EndDo;
	
	Return TranslatedObject;
	
EndFunction

&AtServer
Procedure FillObjectsInclusionInSubsystems(FirstLevelSubsystem = Undefined, SubsystemParent = Undefined)
	
	Subsystems = ?(SubsystemParent = Undefined,
		?(FirstLevelSubsystem = Undefined,
			Metadata,
			FirstLevelSubsystem),
		SubsystemParent);
	
	If ObjectsAndSubsystemsMap = Undefined Then
		ObjectsAndSubsystemsMap = New Map;
	EndIf;
	
	For Each Subsystem In Subsystems.Subsystems Do
		For Each SubsystemObject In Subsystem.Content Do
			ObjectSubsystems = ObjectsAndSubsystemsMap[SubsystemObject.FullName()];
			If ObjectSubsystems = Undefined Then
				ObjectSubsystems = New Array;
			ElsIf ObjectSubsystems.Find(Subsystem) <> Undefined Then
				Continue;
			EndIf;
			ObjectSubsystems.Add(Subsystem);
			ObjectsAndSubsystemsMap.Insert(SubsystemObject.FullName(), ObjectSubsystems);
		EndDo;
		
		FillObjectsInclusionInSubsystems(FirstLevelSubsystem, Subsystem);
	EndDo;
	
EndProcedure

&AtServer
Function RightCheckCommandInterfaceSubsystemsView()
	
	InvalidObjects = New ValueList;
	For Each Subsystem In Metadata.Subsystems Do
		If Not Subsystem.IncludeInCommandInterface Or StrFind(Subsystem.Name, "_Demo") = 0 Then
			Continue;
		EndIf;
		
		NameOfRole = "Subsystem" + Subsystem.Name;
		CheckTheirChildSubsystems(Subsystem, NameOfRole, InvalidObjects)
	EndDo;
	
	Return InvalidObjects;
	
EndFunction

&AtServer
Procedure CheckTheirChildSubsystems(Subsystem, NameOfRole, InvalidObjects)
	
	If Not AccessRight("View", Subsystem, Metadata.Roles[NameOfRole]) Then
		LongDesc = NStr("ru = 'У подсистемы ""%1"" нет права ""Просмотр"" в роли ""%2""';
						|en = 'The View right is not available in the %1 subsystem in the %2 role';");
		LongDesc = StringFunctionsClientServer.SubstituteParametersToString(LongDesc, Subsystem.Name, NameOfRole);
		InvalidObjects.Add(LongDesc, Subsystem.FullName());
	EndIf;
	
	For Each ChildSubsystem In Subsystem.Subsystems Do
		CheckTheirChildSubsystems(ChildSubsystem, NameOfRole, InvalidObjects);
	EndDo;
	
EndProcedure

&AtClient
Procedure DefineConditionalCallsErrors(ModuleFile, Val TextString, Errors, UsedSubsystemsList, ConditionalCallString)
	
	FullName_Structure = FullNameByModuleName(ModuleFile.FullName, ModuleFile.Name);
	
	If ExceptionObjectsConditionalCallsChecks = Undefined Then
		ExceptionObjectsConditionalCallsChecks = New Map;
		ExceptionObjectsConditionalCallsChecks["CommonClientServer"] = True;
		ExceptionObjectsConditionalCallsChecks["CheckSSLBeforeAssembly"] = True;
		ExceptionObjectsConditionalCallsChecks["SubsystemsDependencies"] = True;
	EndIf;
	If ExceptionObjectsConditionalCallsChecks[FullName_Structure.ObjectName] <> Undefined Then
		Return;
	EndIf;
	
	If SubsystemsConditionalCallsCheckExceptions = Undefined Then
		SubsystemsConditionalCallsCheckExceptions = New Array;
		SubsystemsConditionalCallsCheckExceptions.Add("OnlineUserSupport");
		SubsystemsConditionalCallsCheckExceptions.Add("CloudTechnology");
		SubsystemsConditionalCallsCheckExceptions.Add("IntegrationWith1CDocumentManagementSubsystem");
	EndIf;

	MessageText = "";
	
	While True Do
		
		ConditionalCallStartPosition = StrFind(TextString, ConditionalCallString);
		If ConditionalCallStartPosition = 0 Then
			Break;
		EndIf;
		
		CurrentTextString = Right(TextString, StrLen(TextString) - ConditionalCallStartPosition + 1);
		ConditionalCallEndPosition = StrFind(CurrentTextString, """)");
		If ConditionalCallEndPosition = 0 Then
			Break;
		EndIf;
		
		ConditionalCall = Mid(CurrentTextString, 0, ConditionalCallEndPosition + 2);
		ConditionalCall = TrimAll(ConditionalCall);
		
		IsSubsystemException = False;
		For Each SubsystemName In SubsystemsConditionalCallsCheckExceptions Do
			If StrFind(ConditionalCall, SubsystemName) > 0 Then
				IsSubsystemException = True;
				Continue;
			EndIf;
		EndDo;
		If IsSubsystemException Then
			TextString = Right(CurrentTextString, StrLen(CurrentTextString) - ConditionalCallEndPosition + 1);
			Continue;
		EndIf;
		
		If Not SubsystemNameSpecifiedCorrectly(ConditionalCall, UsedSubsystemsList) Then
			MessageText = ?(IsBlankString(MessageText),
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1: %2';
																								|en = '%1: %2';"), 
					FullName_Structure.FullModuleName, ConditionalCall),
				ConditionalCall);
			Errors.Add(MessageText, FullName_Structure.FullObjectName);
		EndIf;
		
		TextString = Right(CurrentTextString, StrLen(CurrentTextString) - ConditionalCallEndPosition + 1);
		
	EndDo;
	
EndProcedure

&AtClient
Function SubsystemNameSpecifiedCorrectly(ConditionalCall, UsedSubsystemsList)
	
	NameIsCorrect = False;
	
	If StrFind(ConditionalCall, "ElectronicInteraction") > 0
		Or StrFind(ConditionalCall, "RegulatedReporting") > 0
		Or StrFind(ConditionalCall, "EquipmentSupport") > 0 Then
		Return True;
	EndIf;
	
	For Each UsedSubsystem In UsedSubsystemsList Do
		
		If StrFind(ConditionalCall, """" +  UsedSubsystem + """") > 0 Then
			NameIsCorrect = True;
			Break;
		EndIf;
		
	EndDo;
	
	Return NameIsCorrect;
	
EndFunction

&AtServer
Function CheckObjectBelonging()
	SubsystemsObjectsList = SubsystemsObjects();
	
	// Use only a list of metadata objects that belong to the subsystems.
	MetadataTypesList = MetadataTypeToCheck();
	
	// Do not check he following:
	DeleteFromList(MetadataTypesList,"FunctionalOptions");
	DeleteFromList(MetadataTypesList,"FunctionalOptionsParameters");
	DeleteFromList(MetadataTypesList,"Languages");
	
	NotSubordinateObjects = New ValueList;
	RedundantSubordinateObjects = New ValueList;
	
	For Each MetadataTypeInList In MetadataTypesList Do
		MetadataType = MetadataTypeInList.Value;
		For Each SpecifiedTypeMetadataObject In Metadata[MetadataType] Do
			// Skip demo objects.
			If Not IsSuppliedObject(SpecifiedTypeMetadataObject, MetadataType) Then
				Continue;
			EndIf;
			
			If IsNotDemoExtensionObject(SpecifiedTypeMetadataObject) Then
				// Check only demo extensions.
				Continue;
			EndIf;
			
			// Search for objects that don't belong to any subsystem.
			FilterParameters = New Structure("Object",SpecifiedTypeMetadataObject);
			SubsystemsSubordinations = SubsystemsObjectsList.FindRows(FilterParameters);
			If SubsystemsSubordinations.Count() = 0 And SpecifiedTypeMetadataObject.ConfigurationExtension() = Undefined Then
				NameString_ = StringFunctionsClientServer.SubstituteParametersToString("%1 : %2", String(MetadataType), SpecifiedTypeMetadataObject.Name);
				NotSubordinateObjects.Add(NameString_, SpecifiedTypeMetadataObject.FullName());
			EndIf;
			
			// Search for objects that belong to more than one subsystem.
			If SubsystemsSubordinations.Count() > 0 Then
				SuppliedSubsystemsCount = 0;
				For Each ParentSubsystem In SubsystemsSubordinations Do
					If IsSuppliedSubsystem(ParentSubsystem.Subsystem) Then
						SuppliedSubsystemsCount = SuppliedSubsystemsCount + 1;
					EndIf;
				EndDo;
				If SuppliedSubsystemsCount > 1 Then
					NameString_ = StringFunctionsClientServer.SubstituteParametersToString("%1 : %2", String(MetadataType), SpecifiedTypeMetadataObject.Name);
					RedundantSubordinateObjects.Add(NameString_, SpecifiedTypeMetadataObject.FullName());
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	Return New Structure("NotSubordinateObjects,RedundantSubordinateObjects", 
		NotSubordinateObjects, RedundantSubordinateObjects);
	
EndFunction

// Parameters:
//   MetadataObject - MetadataObject
//   MetadataType - Arbitrary
// Returns:
//   Boolean
//
&AtServer
Function IsSuppliedObject(MetadataObject, MetadataType)
	
	If MetadataType = "SessionParameters" Then
		CheckException = (StrFind(MetadataObject.Name, "_Demo") > 0);
	Else
		CheckException = StrStartsWith(MetadataObject.Name, "_Demo");
	EndIf;
	
	Return Not CheckException;
EndFunction

&AtServer
Procedure DeleteFromList(List, ObjectName)
	ValueToDelete = List.FindByValue(ObjectName);
	If ValueToDelete = Undefined Then 
		Return;
	EndIf;
	List.Delete(ValueToDelete);
EndProcedure

&AtServer 
Function IsSuppliedSubsystem(CheckSubsystem)
	SuppliedSubsystem = Metadata.Subsystems.StandardSubsystems;
	Return CheckSubsystem = SuppliedSubsystem
		Or CheckSubsystem.Parent() = SuppliedSubsystem
		Or CheckSubsystem.Parent().Parent() = SuppliedSubsystem;
EndFunction

&AtServer
Function UsedSubsystemsList(OnlyStandardSubsystems = True)
	
	Result = New Array;
	StandardSubsystems = Metadata.Subsystems.Find("StandardSubsystems");
	If StandardSubsystems <> Undefined Then
		SubsystemsList = StandardSubsystems.Subsystems;
		AddSubsystems(Result, SubsystemsList, "", "StandardSubsystems.");
	EndIf;
	
	If Not OnlyStandardSubsystems Then
		MetadataSaaSTechnology = Metadata.Subsystems.Find("CloudTechnology");
		If MetadataSaaSTechnology <> Undefined Then
			SubsystemsList = MetadataSaaSTechnology.Subsystems;
			AddSubsystems(Result, SubsystemsList, "", "CloudTechnology.");
		EndIf;
		
		MetadataOnlineUserSupport = Metadata.Subsystems.Find("OnlineUserSupport");
		If MetadataOnlineUserSupport <> Undefined Then
			SubsystemsList = MetadataOnlineUserSupport.Subsystems;
			AddSubsystems(Result, SubsystemsList, "", "OnlineUserSupport.");
		EndIf;
	EndIf;
	
	For Each SubsystemException In SubsystemsToIntegrate() Do
		Result.Add(SubsystemException);
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure AddSubsystems(SubsystemsList, NestedSubsystems, SubsystemPath, Prefix)
	
	If NestedSubsystems.Count() > 0 Then 
		For Each Subsystem In NestedSubsystems Do
			BackupPath = SubsystemPath;
			SubsystemPath = SubsystemPath + "." + String(Subsystem.Name);
			AddSubsystems(SubsystemsList, Subsystem.Subsystems, SubsystemPath, Prefix);
			SubsystemsList.Add(Prefix + Mid(SubsystemPath, 2));
			SubsystemPath = BackupPath;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Function SubsystemsToIntegrate()
	
	Exceptions = New Array;
	Exceptions.Add("StandardSubsystems.ExternalBusinessProcessesAndTasks");
	Exceptions.Add("StandardSubsystems.SMDataAreasBackup");
	
	Return Exceptions;
	
EndFunction

&AtClient
Procedure DetermineCommentsErrors(ModuleFile, SubsystemName, Val TextString, Errors)
	
	FragmentBeginning = FindFragmentBeginning(TextString, SubsystemName);
	While FragmentBeginning > 0 Do
		
		FragmentEndPosition = FindFragmentEnd(TextString, SubsystemName);
		If FragmentEndPosition = 0 Then
			FullName_Structure = FullNameByModuleName(ModuleFile.FullName, ModuleFile.Name);
			If IsException(FullName_Structure.FullObjectName) Then
				Return;
			EndIf;
			
			MessageText = NStr("ru = '[ModuleFileName]: для открывающей скобки [FragmentBeginning] не обнаружена закрывающая скобка.';
									|en = '[ModuleFileName]: close parenthesis is not found for open parenthesis [FragmentBeginning].';");
			MessageText = StrReplace(MessageText, "[FragmentBeginning]", "// " + SubsystemName);
			MessageText = StrReplace(MessageText, "[ModuleFileName]", FullName_Structure.FullModuleName);
			Errors.Add(MessageText, FullName_Structure.FullObjectName);
			Return;
		EndIf;
		
		If FragmentEndPosition < FragmentBeginning Then
			FullName_Structure = FullNameByModuleName(ModuleFile.FullName, ModuleFile.Name);
			If IsException(FullName_Structure.FullObjectName) Then
				Return;
			EndIf;
			
			MessageText = NStr("ru = '[ModuleFileName]: для открывающей скобки [FragmentBeginning] закрывающая скобка расположена выше по тексту.';
									|en = '[ModuleFileName]: close parenthesis is above in the text for open parenthesis [FragmentBeginning].';");
			MessageText = StrReplace(MessageText, "[FragmentBeginning]", "// " + SubsystemName);
			MessageText = StrReplace(MessageText, "[ModuleFileName]", FullName_Structure.FullModuleName);
			Errors.Add(MessageText, FullName_Structure.FullObjectName);
			Return;
		EndIf;
		
		FragmentBeginningLength = StrLen("// " + SubsystemName);
		IntermediateString = Mid(TextString, FragmentBeginning + FragmentBeginningLength + 1, FragmentEndPosition - (FragmentBeginning + FragmentBeginningLength) + 1);
		If FindFragmentBeginning(IntermediateString, SubsystemName) > 0 Then 
			FullName_Structure = FullNameByModuleName(ModuleFile.FullName, ModuleFile.Name);
			If IsException(FullName_Structure.FullObjectName) Then
				Return;
			EndIf;
			
			MessageText = NStr("ru = '[ModuleFileName]: внутри открывающейся скобки [FragmentBeginning] есть еще одна открывающаяся скобка, до закрывающейся. Фрагмент кода: [CodeSnippet]';
									|en = '[ModuleFileName]: there is an open parenthesis inside open parenthesis [FragmentBeginning] before the close parenthesis. Code snippet: [CodeSnippet]';");
			MessageText = StrReplace(MessageText, "[FragmentBeginning]", "// " + SubsystemName);
			MessageText = StrReplace(MessageText, "[ModuleFileName]", FullName_Structure.FullModuleName);
			MessageText = StrReplace(MessageText, "[CodeSnippet]", Left(IntermediateString, 200));
			Errors.Add(MessageText, FullName_Structure.FullObjectName);
			Return;
		EndIf;
		
		LastCharPosition = FragmentEndPosition + StrLen("// End " + SubsystemName);
		TextString = Mid(TextString, LastCharPosition);
		
		FragmentBeginning = FindFragmentBeginning(TextString, SubsystemName);
		
	EndDo;
	
EndProcedure

&AtClient
Function FindFragmentBeginning(Val TextString, Val SubsystemName)
	
	TextString  = Lower(TextString);
	SubsystemName = Lower(SubsystemName);
	
	FirstOption = "// " + SubsystemName;
	SecondOption = "//" + SubsystemName;
	
	If StrFind(TextString, FirstOption) = 0 And StrFind(TextString, SecondOption) = 0 Then
		Return 0;
	EndIf;
	
	For Iteration = 1 To StrLen(TextString) Do
		
		If Mid(TextString, Iteration, StrLen(FirstOption)) = (FirstOption) Then
			Return Iteration;
		EndIf;
		
		If Mid(TextString, Iteration, StrLen(SecondOption)) = (SecondOption) Then 
			Return Iteration;
		EndIf;
	EndDo;
	
	Return 0;
	
EndFunction

&AtClient
Function FindFragmentEnd(Val TextString, Val SubsystemName)
	
	TextString  = Lower(TextString);
	SubsystemName = Lower(SubsystemName);
	
	FirstOption = "// end " + SubsystemName;
	SecondOption = "//end " + SubsystemName;
	
	If StrFind(TextString, FirstOption) = 0 And StrFind(TextString, SecondOption) = 0 Then
		Return 0;
	EndIf;
	
	For Iteration = 1 To StrLen(TextString) Do
		
		If Mid(TextString, Iteration, StrLen(FirstOption)) = (FirstOption) Then 
			Return Iteration;
		EndIf;
		
		If Mid(TextString, Iteration, StrLen(SecondOption)) = (SecondOption) Then 
			Return Iteration;
		EndIf;
	EndDo;
	
	Return 0;
	
EndFunction

&AtServer
Function CheckRolesRights(TypeOfVerification, RoleName1)
	
	RightsStructure = MetadataObjectsRights();
	
	IncorrectlyFilledRoles = New ValueList;
	
	// Check rights to exchange plans.
	For Each Item In Metadata.ExchangePlans Do
		
		MetadataObjectName = "ExchangePlans";
		IncorrectlyFilledRoles = RoleCheck(
			Item, RightsStructure.ExchangePlans, IncorrectlyFilledRoles, TypeOfVerification, RoleName1, MetadataObjectName);
		
	EndDo;
	
	// Check rights to constants.
	For Each Item In Metadata.Constants Do
		
		MetadataObjectName = "Constants";
		IncorrectlyFilledRoles = RoleCheck(
			Item, RightsStructure.Constants, IncorrectlyFilledRoles, TypeOfVerification, RoleName1, MetadataObjectName);
		
	EndDo;
	
	// Check rights to catalogs.
	For Each Item In Metadata.Catalogs Do
		
		MetadataObjectName = "Catalogs";
		IncorrectlyFilledRoles = RoleCheck(
			Item, RightsStructure.Catalogs, IncorrectlyFilledRoles, TypeOfVerification, RoleName1, MetadataObjectName);
		
	EndDo;
	
	// Check rights to documents.
	For Each Item In Metadata.Documents Do
		
		MetadataObjectName = "Documents";
		IncorrectlyFilledRoles = RoleCheck(
			Item, RightsStructure.Documents, IncorrectlyFilledRoles, TypeOfVerification, RoleName1, MetadataObjectName);
		
	EndDo;
	
	// Check rights to charts of characteristic types.
	For Each Item In Metadata.ChartsOfCharacteristicTypes Do
		
		MetadataObjectName = "ChartsOfCharacteristicTypes";
		IncorrectlyFilledRoles = RoleCheck(
			Item, RightsStructure.ChartsOfCharacteristicTypes, IncorrectlyFilledRoles, TypeOfVerification, RoleName1, MetadataObjectName);
		
	EndDo;
	
	// Check rights to information registers.
	For Each Item In Metadata.InformationRegisters Do
		
		MetadataObjectName = "InformationRegisters";
		IncorrectlyFilledRoles = RoleCheck(
			Item, RightsStructure.InformationRegisters, IncorrectlyFilledRoles, TypeOfVerification, RoleName1, MetadataObjectName);
		
	EndDo;
	
	// Check rights to accumulation registers.
	For Each Item In Metadata.AccumulationRegisters Do
		
		MetadataObjectName = "AccumulationRegisters";
		IncorrectlyFilledRoles = RoleCheck(
			Item, RightsStructure.AccumulationRegisters, IncorrectlyFilledRoles, TypeOfVerification, RoleName1, MetadataObjectName);
		
	EndDo;
	
	// Check rights to business processes.
	For Each Item In Metadata.BusinessProcesses Do
		
		MetadataObjectName = "BusinessProcesses";
		IncorrectlyFilledRoles = RoleCheck(
			Item, RightsStructure.BusinessProcesses, IncorrectlyFilledRoles, TypeOfVerification, RoleName1, MetadataObjectName);
		
	EndDo;
	
	// Check rights to tasks.
	For Each Item In Metadata.Tasks Do
		
		MetadataObjectName = "Tasks";
		IncorrectlyFilledRoles = RoleCheck(
			Item, RightsStructure.Tasks, IncorrectlyFilledRoles, TypeOfVerification, RoleName1, MetadataObjectName);
		
	EndDo;
	
	Return IncorrectlyFilledRoles;
	
EndFunction

&AtServer
Function RoleCheck(MetadataObjectsList, RightsList, IncorrectlyFilledRoles, TypeOfVerification, RoleName1, MetadataObjectName)
	
	CommonAttributeContentItem = Metadata.CommonAttributes.DataAreaMainData.Content.Find(MetadataObjectsList);
	CommonAuxiliaryAttributeItem = Metadata.CommonAttributes.DataAreaAuxiliaryData.Content.Find(MetadataObjectsList);
	
	FullObjectName = CommonAttributeContentItem.Metadata.FullName();
	
	If ExceptionsList.FindByValue(CommonAttributeContentItem.Metadata.Name) <> Undefined Then
		Return IncorrectlyFilledRoles;
	EndIf;
	
	If TypeOfVerification = "InteractiveDelete" Then
		
		If RightsList.FindByValue("InteractiveDelete") = Undefined Then
			Return IncorrectlyFilledRoles;
		EndIf;
		
		For Each ItemRole In Metadata.Roles Do
			AccessToObjectIsSet = AccessRight(
				"InteractiveDelete", CommonAttributeContentItem.Metadata, ItemRole);
				
			If AccessToObjectIsSet Then
				ErrorString = NStr("ru = 'Роль %1, объект %2.%3';
									|en = 'Role %1, object %2.%3';");
				ErrorString = StringFunctionsClientServer.SubstituteParametersToString(ErrorString,
					                     ItemRole.Name,
					                     MetadataObjectName,
					                     CommonAttributeContentItem.Metadata.Name);
				IncorrectlyFilledRoles.Add(ErrorString, FullObjectName);
			EndIf;
			
		EndDo;
		
	Else
		
		For Each Item In RightsList Do
			
			If Item.Value = "InteractiveDelete" Then
				Continue;
			EndIf;
			
			If RoleName1 = "SystemAdministrator" Then
				AccessToObjectIsSet = AccessRight(
					Item.Value, CommonAttributeContentItem.Metadata, Metadata.Roles.SystemAdministrator);
			ElsIf RoleName1 = "FullAccess" Then
				AccessToObjectIsSet = AccessRight(
					Item.Value, CommonAttributeContentItem.Metadata, Metadata.Roles.FullAccess);
			EndIf;
			
			If TypeOfVerification = "SeparatedMORights" Then
				
				If RoleName1 = "SystemAdministrator" Then
					
					If CommonAttributeContentItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Auto Then
						
						If AccessToObjectIsSet Then
							IncorrectlyFilledRoles.Add(MetadataObjectName + "." + CommonAttributeContentItem.Metadata.Name, FullObjectName);
							Break;
						EndIf;
						
					EndIf;
					
				ElsIf RoleName1 = "FullAccess" Then
					
					If CommonAttributeContentItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Auto
						And Not AccessToObjectIsSet Then
						IncorrectlyFilledRoles.Add(MetadataObjectName + "." + CommonAttributeContentItem.Metadata.Name, FullObjectName);
						Break;
					EndIf;
					
				EndIf;
				
			ElsIf TypeOfVerification = "SharedMORights" Then
				
				If RoleName1 = "SystemAdministrator" Then
					
					If CommonAttributeContentItem.Use = Metadata.ObjectProperties.CommonAttributeUse.DontUse Then
						AuxiliaryData = (CommonAuxiliaryAttributeItem.Use =
							                     Metadata.ObjectProperties.CommonAttributeUse.Use);
						
						If Not AccessToObjectIsSet And Not AuxiliaryData Then
							
							IncorrectlyFilledRoles.Add(MetadataObjectName + "." + CommonAttributeContentItem.Metadata.Name, FullObjectName);
							Break;
						EndIf;
						
					EndIf;
					
				ElsIf RoleName1 = "FullAccess" Then
					
					If CommonAttributeContentItem.Use = 
							Metadata.ObjectProperties.CommonAttributeUse.DontUse Then
							
						If Item.Value = "Read"
							Or Item.Value = "View"
							Or Item.Value = "InputByString" Then
							Continue;
						ElsIf AccessToObjectIsSet Then
							IncorrectlyFilledRoles.Add(MetadataObjectName + "." + CommonAttributeContentItem.Metadata.Name, FullObjectName);
							Break;
						EndIf;
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return IncorrectlyFilledRoles;
	
EndFunction

&AtServer
Function MetadataObjectsRights()
	
	RightsStructure = New Structure;
	
	// Exchange plans.
	RightsList = New ValueList;
	RightsList.Add("Read");
	RightsList.Add("Create");
	RightsList.Add("Update");
	RightsList.Add("Delete");
	RightsList.Add("View");
	RightsList.Add("InteractiveInsert");
	RightsList.Add("Edit");
	RightsList.Add("InteractiveDelete");
	RightsList.Add("InteractiveDeletionMark");
	RightsList.Add("InteractiveClearDeletionMark");
	RightsList.Add("InteractiveDeleteMarked");
	RightsList.Add("InputByString");
	RightsStructure.Insert("ExchangePlans", RightsList);
	
	// Constants.
	RightsList = New ValueList;
	RightsList.Add("Read");
	RightsList.Add("Update");
	RightsList.Add("View");
	RightsList.Add("Edit");
	RightsStructure.Insert("Constants", RightsList);
	
	// Catalogs.
	RightsList = New ValueList;
	RightsList.Add("Read");
	RightsList.Add("Create");
	RightsList.Add("Update");
	RightsList.Add("Delete");
	RightsList.Add("View");
	RightsList.Add("InteractiveInsert");
	RightsList.Add("Edit");
	RightsList.Add("InteractiveDelete");
	RightsList.Add("InteractiveDeletionMark");
	RightsList.Add("InteractiveClearDeletionMark");
	RightsList.Add("InteractiveDeleteMarked");
	RightsList.Add("InputByString");
	RightsStructure.Insert("Catalogs", RightsList);
	
	// Documents.
	RightsList = New ValueList;
	RightsList.Add("Read");
	RightsList.Add("Create");
	RightsList.Add("Update");
	RightsList.Add("Delete");
	RightsList.Add("Posting");
	RightsList.Add("UndoPosting");
	RightsList.Add("View");
	RightsList.Add("InteractiveInsert");
	RightsList.Add("Edit");
	RightsList.Add("InteractiveDelete");
	RightsList.Add("InteractiveDeletionMark");
	RightsList.Add("InteractiveClearDeletionMark");
	RightsList.Add("InteractiveDeleteMarked");
	RightsList.Add("InteractivePosting");
	RightsList.Add("InteractivePostingRegular");
	RightsList.Add("InteractiveUndoPosting");
	RightsList.Add("InteractiveChangeOfPosted");
	RightsList.Add("InputByString");
	RightsStructure.Insert("Documents", RightsList);
	
	// Charts of characteristic types.
	RightsList = New ValueList;
	RightsList.Add("Read");
	RightsList.Add("Create");
	RightsList.Add("Update");
	RightsList.Add("Delete");
	RightsList.Add("View");
	RightsList.Add("InteractiveInsert");
	RightsList.Add("Edit");
	RightsList.Add("InteractiveDelete");
	RightsList.Add("InteractiveDeletionMark");
	RightsList.Add("InteractiveClearDeletionMark");
	RightsList.Add("InteractiveDeleteMarked");
	RightsList.Add("InputByString");
	RightsStructure.Insert("ChartsOfCharacteristicTypes", RightsList);
	
	// Information registers.
	RightsList = New ValueList;
	RightsList.Add("Read");
	RightsList.Add("Update");
	RightsList.Add("View");
	RightsList.Add("Edit");
	RightsStructure.Insert("InformationRegisters", RightsList);
	
	// Accumulation registers.
	RightsList = New ValueList;
	RightsList.Add("Read");
	RightsList.Add("Update");
	RightsList.Add("View");
	RightsList.Add("Edit");
	RightsList.Add("TotalsControl");
	RightsStructure.Insert("AccumulationRegisters", RightsList);
	
	// Business processes.
	RightsList = New ValueList;
	RightsList.Add("Read");
	RightsList.Add("Create");
	RightsList.Add("Update");
	RightsList.Add("Delete");
	RightsList.Add("View");
	RightsList.Add("InteractiveInsert");
	RightsList.Add("Edit");
	RightsList.Add("InteractiveDelete");
	RightsList.Add("InteractiveDeletionMark");
	RightsList.Add("InteractiveClearDeletionMark");
	RightsList.Add("InteractiveDeleteMarked");
	RightsList.Add("InputByString");
	RightsList.Add("InteractiveActivate");
	RightsList.Add("Start");
	RightsList.Add("InteractiveStart");
	RightsStructure.Insert("BusinessProcesses", RightsList);
	
	// Tasks.
	RightsList = New ValueList;
	RightsList.Add("Read");
	RightsList.Add("Create");
	RightsList.Add("Update");
	RightsList.Add("Delete");
	RightsList.Add("View");
	RightsList.Add("InteractiveInsert");
	RightsList.Add("Edit");
	RightsList.Add("InteractiveDelete");
	RightsList.Add("InteractiveDeletionMark");
	RightsList.Add("InteractiveClearDeletionMark");
	RightsList.Add("InteractiveDeleteMarked");
	RightsList.Add("InputByString");
	RightsList.Add("InteractiveActivate");
	RightsList.Add("Perform");
	RightsList.Add("InteractiveExecute");
	RightsStructure.Insert("Tasks", RightsList);
	
	Return RightsStructure;
EndFunction

&AtServer
Function IncorrectLinksBetweenSubsystems()
	
	InvalidObjectsList = New ValueList;
	FullSubsystemsNames    = FullSubsystemsNames();
	
	IncorrectLinks = 
		Reports.SubsystemsDependencies.InvalidSSLSubsystemsDependencies(ModulesExportDirectory);
		
	TableCopy = IncorrectLinks.Copy();
	TableCopy.GroupBy("CallingObject");
	For Each RowCallingObject In TableCopy Do
		
		CallingObjectBrokenDown = StrSplit(RowCallingObject.CallingObject, ".");
		CallingObjectBrokenDownNew = New Array;
		If CallingObjectBrokenDown.Count() > 2 Then
			CallingObjectBrokenDownNew.Add(CallingObjectBrokenDown[0]);
			CallingObjectBrokenDownNew.Add(CallingObjectBrokenDown[1]);
			FullObjectName = StrConcat(CallingObjectBrokenDownNew, ".");
		Else
			FullObjectName = RowCallingObject.CallingObject;
		EndIf;
		FullObjectName = StrReplace(RowCallingObject.CallingObject, ".Module", "");
		
		FilterParameters = New Structure("CallingObject", RowCallingObject.CallingObject);
		FoundRows = IncorrectLinks.FindRows(FilterParameters);
		GeneratedRow = "";
		CurrentSubsystemToCall = "";
		LineNumber = 0;
		For Each FoundRow In FoundRows Do
			If GeneratedRow = ""
				Or CurrentSubsystemToCall <> FoundRow.SubsystemToCall Then
				
				If ValueIsFilled(GeneratedRow) Then
					InvalidObjectsList.Add(GeneratedRow, FullObjectName);
					GeneratedRow = "";
				EndIf;
				
				If CurrentSubsystemToCall <> ""
					And GeneratedRow <> "" Then
					GeneratedRow = GeneratedRow + Chars.LF;
				EndIf;
				
				CurrentSubsystemToCall = FoundRow.SubsystemToCall;
				LineNumber = 0;
				GeneratedRow = GeneratedRow
				                       + FoundRow.CallingSubsystem + " -> "
				                       + FoundRow.SubsystemToCall + Chars.LF;
			EndIf;
			LineNumber = LineNumber + 1;
			GeneratedRow = GeneratedRow + Chars.Tab + LineNumber + ". "
			                       + FoundRow.CallingObject + " ("
			                       + FoundRow.Call_Position + ")";
			GeneratedRow = GeneratedRow
			                       + ?(FoundRow.ObjectToCall <> "", " -> " + FoundRow.ObjectToCall, "") + Chars.LF;
		EndDo;
		
		GeneratedRow = GeneratedRow + Chars.LF;
		InvalidObjectsList.Add(GeneratedRow, FullObjectName);
		
	EndDo;
	
	Return InvalidObjectsList;
	
EndFunction

&AtServer
Function FullSubsystemsNames()
	
	Map = New Map;
	
	For Each StandardSubsystem In Metadata.Subsystems.StandardSubsystems.Subsystems Do
		Map.Insert(StandardSubsystem.Name, StandardSubsystem.FullName());
		If StandardSubsystem.Name = "SaaSOperations" Then
			// Loop through all SaaS subsystems.
			For Each SaaSSubsystem In StandardSubsystem.Subsystems Do
				Map.Insert(SaaSSubsystem.Name, SaaSSubsystem.FullName());
			EndDo;
		EndIf;
	EndDo;
	
	Return Map;
	
EndFunction

&AtServer
Function SearchForProhibitedCommentsInModulesCode(SearchString)
	
	InvalidObjectsList = New ValueList;
	ModulesArray = FindFiles(ModulesExportDirectory, "*.bsl", True);
	FileText = New TextDocument;
	LineNumber = 0;
	
	For Each File In ModulesArray Do
		
		If StrFind(File.FullName, "GoToVersion1301") > 0 Then
			Continue; //Exception.
		EndIf;
		
		FileText.Read(File.FullName);
		TextString = FileText.GetText();
		TextString = Upper(TextString);
		
		CharacterNumber = StrFind(TextString, SearchString);
		CommentFound = (CharacterNumber > 0);
		While CommentFound Do
			
			LineNumber = LineNumber(TextString, CharacterNumber, LineNumber);
			FullName_Structure = FullNameByModuleName(File.FullName, File.Name);
			InvalidObjectsList.Add(FullName_Structure.FullModuleName + " - string " + LineNumber,
				                             FullName_Structure.FullObjectName);
			TextString = Mid(TextString, CharacterNumber + 4);
			
			CharacterNumber = StrFind(TextString, SearchString);
			CommentFound = (CharacterNumber > 0);
			
		EndDo;
		LineNumber = 0;
		
	EndDo;
	
	Return InvalidObjectsList;
	
EndFunction

&AtServer
Function HorizontalIfPossibleGroups()
	
	NamespaceMap = New Map;
	NamespaceMap.Insert("ns", "http://v8.1c.ru/8.3/xcf/logform");
	Dereferencer = New DOMNamespaceResolver(NamespaceMap);
	
	InvalidObjectsList = New ValueList;
	ListOfFiles = FindFiles(ModulesExportDirectory, "Form.xml", True);
	
	For Each FormFile In ListOfFiles Do
		
		DOMDocument = DOMDocument(FormFile.FullName);
		
		Expression = "//ns:UsualGroup";
		XPathResult = DOMDocument.EvaluateXPathExpression(Expression, DOMDocument, Dereferencer);
		
		UsualGroup = XPathResult.IterateNext();
		While UsualGroup <> Undefined Do
			
			GroupingSpecified = False;
			For Each Property In UsualGroup.ChildNodes Do
				If Property.NodeName = "Group" Then
					GroupingSpecified = True;
				EndIf;
			EndDo;
			
			If Not GroupingSpecified Then
				TagName = UsualGroup.Attributes.GetNamedItem("name").TextContent;
				FullName_Structure = FullNameByModuleName(FormFile.FullName, FormFile.Name);
				
				If IsSSLObject(FullName_Structure.FullObjectName)
					Or StrStartsWith(FullName_Structure.ObjectName, "_Demo") Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 группа %2';
																								|en = '%1 group %2';"),
						FullName_Structure.FullModuleName, TagName);
					InvalidObjectsList.Add(ErrorText, FullName_Structure.FullObjectName);
				EndIf;
			EndIf;
			
			UsualGroup = XPathResult.IterateNext();
			
		EndDo;
		
	EndDo;
	
	Return InvalidObjectsList;
	
EndFunction

&AtServer
Function IsSSLObject(FullName)
	
	MetadataObject = Common.MetadataObjectByFullName(FullName);
	
	StandardSubsystems = Metadata.Subsystems.StandardSubsystems;
	
	Return ObjectBelongsToSubsystem(StandardSubsystems, MetadataObject);
	
EndFunction

&AtServer
Function ObjectBelongsToSubsystem(Subsystem, MetadataObject)
	
	If Subsystem.Content.Contains(MetadataObject) Then
		Return True;
	EndIf;
	
	For Each SubordinateSubsystem In Subsystem.Subsystems Do
		If ObjectBelongsToSubsystem(SubordinateSubsystem, MetadataObject) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Function DOMDocument(PathToFile)
	
	XMLReader = New XMLReader;
	DOMBuilder = New DOMBuilder;
	XMLReader.OpenFile(PathToFile);
	DOMDocument = DOMBuilder.Read(XMLReader);
	XMLReader.Close();
	
	Return DOMDocument;
	
EndFunction

&AtServer
Function IncludeProceduresWithFlagToHelpContent()
	
	InvalidObjectsList = New ValueList;
	For Each Subsystem In Metadata.Subsystems.StandardSubsystems.Subsystems Do
		If Subsystem.IncludeHelpInContents Then
			InvalidObjectsList.Add(Subsystem.FullName(), Subsystem.FullName());
		EndIf;
		For Each ChildSubsystem In Subsystem.Subsystems Do
			If Subsystem.IncludeHelpInContents Then
				InvalidObjectsList.Add(ChildSubsystem.FullName(), ChildSubsystem.FullName());
			EndIf;
		EndDo;
	EndDo;
	
	Return InvalidObjectsList;
	
EndFunction

&AtServer
Function LineNumber(TextString, CharacterNumber, LineNumber)
	
	LineNumber = LineNumber + StrOccurrenceCount(Left(TextString, CharacterNumber), Chars.LF) + ?(LineNumber = 0, 1, 0);
	
	Return LineNumber;
	
EndFunction

&AtServer
Function DesignerIsOpen()
	
	For Each Session In GetInfoBaseSessions() Do
		If Upper(Session.ApplicationName) = Upper("Designer") Then // Designer.
			Return True;
		EndIf;
	EndDo;
	Return False;
	
EndFunction

&AtServer
Function SSLRole(Role, Subsystem = Undefined)
	
	If Subsystem = Undefined Then
		Subsystem = Metadata.Subsystems.StandardSubsystems;
	EndIf;
	
	If Subsystem.Content.Contains(Role) Then
		Return True;
	EndIf;
	
	For Each CurrentSubsystem In Subsystem.Subsystems Do
		If CurrentSubsystem.Content.Contains(Role) Then
			Return True;
		EndIf;
		If SSLRole(Role, CurrentSubsystem) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Function FullNameByModuleName(FullPathWithName, FileNameWithExtension)
	FormPath = StrReplace(FullPathWithName, ModulesExportDirectory + GetPathSeparator(), "");
	ModuleNameByParts = StrSplit(FormPath, GetPathSeparator());
	
	FullObjectName = "";
	FullModuleName  = "";
	ObjectName       = "";
	Step = 0;
	For Each PathPart In ModuleNameByParts Do
		Step = Step + 1;
		If Upper(PathPart) = "EXT" Then
			Continue;
		EndIf;
		
		If PathPart = FileNameWithExtension Then
			PathPart = StrSplit(PathPart, ".")[0];
		EndIf;
		
		TransformedPathPart = EnglishAndNationalNamesMap()[PathPart];
		If TransformedPathPart = Undefined Then
			TransformedPathPart = PathPart;
		EndIf;
		
		If Step < 3 Then
			FullObjectName = ?(FullObjectName = "",
				                 TransformedPathPart,
				                 FullObjectName + "." + TransformedPathPart);
		EndIf;
		
		If Step = 2 Then
			ObjectName = PathPart;
		EndIf;
		
		FullModuleName = ?(FullModuleName = "",
			                 TransformedPathPart,
			                 FullModuleName + "." + TransformedPathPart);
	EndDo;
	
	Result = New Structure;
	Result.Insert("FullObjectName", FullObjectName);
	Result.Insert("FullModuleName", FullModuleName);
	Result.Insert("ObjectName", ObjectName);
	
	Return Result;
EndFunction

&AtServer
Function EnglishAndNationalNamesMap()
	Result = New Map;
	
	// Metadata object kinds.
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
	Result.Insert("Configurations", "Configuration"); // Obsolete.
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
	
	Return Result;
EndFunction

&AtServer
Function DeferredHandlersCheck()
	
	InvalidObjectsList = New ValueList;
	
	SubsystemsDetails  = StandardSubsystemsCached.SubsystemsDetails();
	SubsystemsDetailsByNames = SubsystemsDetails.ByNames;
	For Each SubsystemName In SubsystemsDetails.Order Do
		DeferredHandlersExecutionMode = SubsystemsDetailsByNames[SubsystemName].DeferredHandlersExecutionMode;
		If DeferredHandlersExecutionMode = "Sequentially" Then
			Continue;
		EndIf;
		
		SubsystemDetails = SubsystemsDetails.ByNames.Get(SubsystemName);
		If Not ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		
		ParallelSinceVersion = SubsystemsDetailsByNames[SubsystemName].ParallelDeferredUpdateFromVersion;
		
		Module = Common.CommonModule(SubsystemDetails.MainServerModule);
		Handlers = InfobaseUpdate.NewUpdateHandlerTable();
		Module.OnAddUpdateHandlers(Handlers);
		
		FilterParameters = New Structure;
		FilterParameters.Insert("ExecutionMode", "Deferred");
		
		FoundRows = Handlers.FindRows(FilterParameters);
		For Each DetailsString In FoundRows Do
			If DetailsString.Version = "*"
				Or (ValueIsFilled(ParallelSinceVersion)
					And CommonClientServer.CompareVersions(DetailsString.Version, ParallelSinceVersion) < 0) Then
				Continue;
			EndIf;
			
			If ValueIsFilled(DetailsString.ObjectsToRead)
				And ValueIsFilled(DetailsString.ObjectsToChange) Then
				Continue;
			EndIf;
			
			ProcedureInPartsName = StringFunctionsClientServer.SplitStringIntoSubstringsArray(DetailsString.Procedure, ".");
			If ProcedureInPartsName.Count() = 2 Then
				FullObjectName = "CommonModule" + "." + ProcedureInPartsName[0];
			Else
				FullObjectName = MetadataTypesMap(ProcedureInPartsName[0]) + "." + ProcedureInPartsName[1];
			EndIf;
			
			InvalidObjectsList.Add(DetailsString.Procedure, FullObjectName);
		EndDo;
		
	EndDo;
	
	Return InvalidObjectsList;
	
EndFunction

&AtServer
Function MetadataTypesMap(ManagerName)
	
	Map = New Map;
	Map.Insert("Catalogs", "Catalog");
	Map.Insert("Documents", "Document");
	Map.Insert("DocumentJournals", "DocumentJournal");
	Map.Insert("InformationRegisters", "InformationRegister");
	
	Return Map[ManagerName];
	
EndFunction

&AtServer
Function ConfigurationPlatformCheck()
	
	InvalidObjectsList = New ValueList;
	
	MessagesFileName = ModulesExportDirectory + "\ConfigurationCheckResult.txt";
	
	If IsBlankString(ConnectionString) Then
		ConnectionString = InfoBaseConnectionString();
	EndIf;
	
	BinDir = StandardSubsystemsServer.ClientParametersAtServer().Get("BinDir");
	
	StartupCommand = New Array;
	StartupCommand.Add(BinDir + "1cv8.exe");
	StartupCommand.Add("DESIGNER");
	StartupCommand.Add("/IBConnectionString");
	StartupCommand.Add(ConnectionString);
	StartupCommand.Add("/N");
	StartupCommand.Add(UserName());
	StartupCommand.Add("/P");
	StartupCommand.Add();
	StartupCommand.Add("/CheckConfig");
	StartupCommand.Add("-ConfigLogIntegrity");
	StartupCommand.Add("-IncorrectReferences");
	StartupCommand.Add("-ThinClient");
	StartupCommand.Add("-WebClient");
	StartupCommand.Add("-Server");
	StartupCommand.Add("-ExternalConnection");
	StartupCommand.Add("-ExternalConnectionServer");
	StartupCommand.Add("-ThickClientManagedApplication");
	StartupCommand.Add("-ThickClientServerManagedApplication");
	StartupCommand.Add("-ThickClientOrdinaryApplication");
	StartupCommand.Add("-ThickClientServerOrdinaryApplication");
	StartupCommand.Add("-DistributiveModules");
	StartupCommand.Add("-UnreferenceProcedures");
	StartupCommand.Add("-HandlersExistence");
	StartupCommand.Add("-EmptyHandlers");
	StartupCommand.Add("-ExtendedModulesCheck");
	StartupCommand.Add("/Out");
	StartupCommand.Add(MessagesFileName);
	StartupCommand.Add("/DisableStartupMessages");
	StartupCommand.Add("/DisableStartupDialogs");
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	
	FileSystem.StartApplication(StartupCommand, ApplicationStartupParameters);
	
	ExceptionsTemplate = DataProcessors.CheckSSLBeforeAssembly.GetTemplate("PlarformCheckExceptions");
	Exceptions = ExceptionsTemplate.GetText();
	Try
		Text = New TextDocument;
		HasErrors = False;
		ReadErrorsFileWithWait(Text, MessagesFileName, HasErrors);
		If HasErrors Then
			Text.Read(MessagesFileName);
		EndIf;
	Except
		ErrorInfo = ErrorInfo();
		InvalidObjectsList.Add(ErrorProcessing.DetailErrorDescription(ErrorInfo), "DataProcessor.CheckSSLBeforeAssembly");
		Return InvalidObjectsList;
	EndTry;
	
	LongError = False;
	For LineNumber = 1 To Text.LineCount() Do
		String = Text.GetLine(LineNumber);
		If String = "Join From1 ofstorage configurations not isset"
			Or StrFind(String, "Attachable_") > 0
			Or StrFind(Exceptions, String) > 0 Then
			Continue;
		EndIf;
		
		If StrFind(String, "{") > 0 Then
			LongError = True;
		EndIf;
		
		ProcessedString1 = StrReplace(String, "{", "");
		
		StringParts = StrSplit(ProcessedString1, " ");
		FullObjectName = StringParts[0];
		FullObjectNameInParts = StrSplit(FullObjectName, ".");
		If FullObjectNameInParts.Count() < 2 Then
			Continue;
		EndIf;
		FullName = FullObjectNameInParts[0] + "." + FullObjectNameInParts[1];
		
		If LongError Then
			LineNumber = LineNumber + 1;
			NextRow = Text.GetLine(LineNumber);
			If TrimL(NextRow) <> NextRow Then
				String = String + Chars.LF + NextRow;
				LongError = False;
			EndIf;
		EndIf;
		
		InvalidObjectsList.Add(String, FullName);
	EndDo;
	
	DeleteFiles(MessagesFileName);
	
	Return InvalidObjectsList;
	
EndFunction

&AtServer
Procedure ReadErrorsFileWithWait(Text, FileName, ReadingError)
	
	Try
		Text.Read(FileName);
	Except
		ReadingError = True;
		ReadEnd = CurrentSessionDate() + 10;
		While CurrentSessionDate() < ReadEnd Do
			// Wait to make sure that there is no shared access error.
		EndDo;
	EndTry;
	
EndProcedure

&AtServer
Procedure FillDeveloperTools(Subsystem)
	
	For Each MetadataObject In Subsystem.Content Do
		FullObjectName = MetadataObject.FullName();
		If DeveloperTools.FindByValue(FullObjectName) = Undefined Then
			DeveloperTools.Add(FullObjectName);
		EndIf;
	EndDo;
	
	For Each SubordinateSubsystem In Subsystem.Subsystems Do
		FillDeveloperTools(SubordinateSubsystem);
	EndDo;
	
EndProcedure

&AtServer
Function ErrorsStructure()
	
	ErrorsStructure = New Structure;
	ErrorsStructure.Insert("ErrorPresentation");
	ErrorsStructure.Insert("PatchDetails");
	ErrorsStructure.Insert("InvalidData");
	ErrorsStructure.Insert("Urgency");
	
	Return ErrorsStructure;
	
EndFunction

// Procedures that search for non-recommended right settings.

// Returns descriptions of the settings not recommended for role development:
// a. In client application forms:
// - for attributes "View by roles" and "Editing by roles"
//    - for commands "Usage by roles"
//    - for fields "User visibility by roles"
//    - b. In the "Visibility by roles" command interface
// c. Redundant settings of rights to attributes in roles (differences from default rights if there are no rights to the object).
// d. In roles of rights to attributes.
// Check clause "a" transferred to CAC (the "Check access rights" standard).
//
// Check clause "b" planned to be transferred to CAC (a new version of the "Check access rights" standard).
// Check clause "c" planned to be transferred to the integration check (with the autocorrection mode).
// Such settings are difficult to detect, analyze, combine upon update, and document for users.
//
// Moreover, there might be a dependence on a specific role,
// which is recommended to be avoided as such role is impossible to be replaced upon an update.
// It is recommended that you use default management of visibility and accessibility (view only)
//
// in a general form instead of such settings, for example, as a function that checks for the role. In this case, it is easy to detect settings components
// by the function usage locations and analyze the influence on the whole configuration and a specific location.
// Upon update, it is easy to replace the role being checked with another role or another feature.
// 
//
// Parameters:
//  UploadFolder - String - Directory containing configuration data exported to files.
//
&AtServer
Function NotRecommendedRightsSettings(UploadFolder)
	
	Errors = New Structure("InvalidRightsSettings, NonDefaultRights", "", "");
	
	// Command interface analysis.
	Files = FindFiles(UploadFolder, "CommandInterface.xml", True);
	
	For Each File In Files Do
		XMLReader = New XMLReader;
		XMLReader.OpenFile(File.FullName);
		Factory = XDTOFactory.ReadXML(XMLReader);
		XMLReader.Close();
		
		ObjectName = ObjectName(UploadFolder, File.FullName, "Ext.CommandInterface.xml") + "CommandInterface";
		CheckObjectProperties(Errors.InvalidRightsSettings, Factory, ObjectName, "CommandsVisibility",   "Command",   "Visibility");
		CheckObjectProperties(Errors.InvalidRightsSettings, Factory, ObjectName, "SubsystemsVisibility", "Subsystem", "Visibility");
	EndDo;
	
	// Role analysis: rights to attributes, standard attributes, dimensions, resources,
	//  tables of attributes, standard tables of standard attributes.
	Files = FindFiles(UploadFolder, "Rights.xml", True);
	
	For Each File In Files Do
		
		LongDesc = FullNameByModuleName(File.FullName, File.Name);
		If Not IsSSLObject(LongDesc.FullObjectName) Then
			Continue;
		EndIf;
		
		XMLReader = New XMLReader;
		XMLReader.OpenFile(File.FullName);
		Factory = XDTOFactory.ReadXML(XMLReader);
		XMLReader.Close();
		
		ObjectName = StrReplace(ObjectName(UploadFolder, File.FullName, ".Ext.Rights.xml"), "Roles.", "Role.");
		CheckRightsToAttributes(Errors, Factory, ObjectName);
	EndDo;
	
	Return Errors;
	
EndFunction

// For function NotRecommendedSettings.
&AtServer
Function ObjectName(UploadFolder, FullFileName, EndToDelete)
	
	ObjectName = StrReplace(FullFileName, UploadFolder + GetPathSeparator(), "");
	ObjectName = StrReplace(ObjectName, GetPathSeparator(), ".");
	ObjectName = StrReplace(ObjectName, EndToDelete, "");
	
	Return ObjectName;
	
EndFunction

// For procedure NotRecommendedSettings.
&AtServer
Procedure CheckUserVisibility(Text, DescriptionOfElements, Var_FormName)
	
	If TypeOf(DescriptionOfElements) = Type("XDTOList") Then
		For Each XDTODataObject In DescriptionOfElements Do
			CheckUserVisibility(Text, XDTODataObject, Var_FormName);
		EndDo;
		Return;
	EndIf;
	
	If TypeOf(DescriptionOfElements) <> Type("XDTODataObject") Then
		Return;
	EndIf;
	
	For Each Property In DescriptionOfElements.Properties() Do
		If Property.OwnerObject = Undefined Then
			Continue;
		EndIf;
		PropertyValue = Property.OwnerObject[Property.Name];
		
		If Property.Name = "UserVisible" Then
			CheckLinksWithObjectPropertyRoles(Text, DescriptionOfElements, Var_FormName, PropertyValue, "Item", "UserVisible");
		Else
			CheckUserVisibility(Text, PropertyValue, Var_FormName);
		EndIf;
	EndDo;
	
EndProcedure

// For procedure NotRecommendedSettings.
&AtServer
Procedure CheckObjectProperties(Text, XDTODataObject, Var_FormName, PropertiesName, PropertyName, LinkName)
	
	PropertiesObject = ObjectProperty1(XDTODataObject, PropertiesName);
	If PropertiesObject = Undefined Then
		Return;
	EndIf;
	
	PropertyObject = ObjectProperty1(PropertiesObject, PropertyName, False);
	If PropertyObject = Undefined Then
		Return;
	EndIf;
	
	ListOfObjects = ListOfObjects(PropertyObject);
	
	For Each PropertyObject In ListOfObjects Do
		Links = ObjectProperty1(PropertyObject, LinkName);
		If Links = Undefined Then
			Continue;
		EndIf;
		
		CheckLinksWithObjectPropertyRoles(Text, PropertyObject, Var_FormName, Links, PropertyName, LinkName);
	EndDo;
	
EndProcedure

// For procedure NotRecommendedSettings.
&AtServer
Procedure CheckRightsToAttributes(Errors, XDTODataObject, NameOfRole)
	
	ErrorsText = New Structure("InvalidRightsSettings, NonDefaultRights", "", "");
	
	SetNewObjectsRights = RoleProperty(ErrorsText.InvalidRightsSettings,
		XDTODataObject, "setForNewObjects");
	
	SetDetailsAndTablePartsRightsByDefault = RoleProperty(ErrorsText.InvalidRightsSettings,
		XDTODataObject, "setForAttributesByDefault", True);
	
	ErrorTitle = Chars.LF + NameOfRole + ":" + Chars.LF;
	
	If ValueIsFilled(ErrorsText.InvalidRightsSettings) Then
		Errors.InvalidRightsSettings = Errors.InvalidRightsSettings
			+ ErrorTitle
			+ ErrorsText.InvalidRightsSettings
			+ Chars.LF;
		Return;
	EndIf;
	
	ListOfObjects = ObjectProperty1(XDTODataObject, "object", False);
	If ListOfObjects = Undefined Then
		Return;
	EndIf;
	ListOfObjects = ListOfObjects(ListOfObjects);
	
	SubordinateObjectsNames = New Map;
	SubordinateObjectsNames.Insert("Attribute",              True);
	SubordinateObjectsNames.Insert("StandardAttribute",      True);
	SubordinateObjectsNames.Insert("TabularSection",         True);
	SubordinateObjectsNames.Insert("StandardTabularSection", True);
	SubordinateObjectsNames.Insert("Dimension",              True);
	SubordinateObjectsNames.Insert("Resource",               True);
	SubordinateObjectsNames.Insert("AddressingAttribute",    True);
	SubordinateObjectsNames.Insert("AccountingFlag",         True);
	SubordinateObjectsNames.Insert("ExtDimensionAccountingFlag", True);
	SubordinateObjectsNames.Insert("Command",                False);
	
	SkippedMetadataObjects = SkippedMetadataObjects(ListOfObjects,
		SetNewObjectsRights);
	
	For Each PropertyObject In ListOfObjects Do
		FullObjectName = ObjectProperty1(PropertyObject, "name");
		If FullObjectName = Undefined Then
			Continue;
		EndIf;
		NameParts = StrSplit(FullObjectName, ".");
		If NameParts.Count() < 3 Then
			Continue;
		EndIf;
		IsField = SubordinateObjectsNames.Get(NameParts[2]);
		If IsField = Undefined Then
			Continue;
		EndIf;
		SkippedObject = SkippedMetadataObjects[NameParts[0] + "." + NameParts[1]];
		
		RightsToField = New Structure;
		RightsToField.Insert("View", "Unspecified");
		RightsToField.Insert("Edit", "Unspecified");
		
		RightsList = ObjectProperty1(PropertyObject, "right", False);
		If RightsList <> Undefined Then
			RightsList = ListOfObjects(RightsList);
			For Each RightsObjectProperties In RightsList Do
				NameOfRight = ObjectProperty1(RightsObjectProperties, "name");
				If NameOfRight = Undefined Then
					Continue;
				EndIf;
				If Not RightsToField.Property(NameOfRight) Then
					Continue;
				EndIf;
				RightsToField[NameOfRight] = ObjectProperty1(RightsObjectProperties, "value");
			EndDo;
		EndIf;
		
		If Not IsField Then // This is a command.
			If (SkippedObject = Undefined Or Not SkippedObject.View)
			   And RightsToField.View = True Then
			
				ErrorsText.InvalidRightsSettings = ErrorsText.InvalidRightsSettings
					+ ?(ValueIsFilled(ErrorsText.InvalidRightsSettings), Chars.LF, "")
					+ FullObjectName + " " + NStr("ru = 'лишнее право Просмотр.';
													|en = 'the View right is excess.';");
			EndIf;
			Continue;
		EndIf;
		
		If RightsToField.View = "Unspecified" Then
			RightsToField.View = SetDetailsAndTablePartsRightsByDefault;
		EndIf;
		If RightsToField.Edit = "Unspecified" Then
			RightsToField.Edit = SetDetailsAndTablePartsRightsByDefault;
		EndIf;
		
		If SkippedObject = Undefined
			And (RightsToField.View <> True
			   Or RightsToField.Edit <> True) Then
			ErrorType = "NonDefaultRights";
		Else
			ErrorType = "InvalidRightsSettings";
		EndIf;
		
		If RightsToField.View <> True Then
			ErrorsText[ErrorType] = ErrorsText[ErrorType]
				+ ?(ValueIsFilled(ErrorsText[ErrorType]), Chars.LF, "")
				+ FullObjectName + " " + NStr("ru = 'без права Просмотр.';
												|en = 'without the View right.';");
		EndIf;
		If RightsToField.Edit <> True Then
			ErrorsText[ErrorType] = ErrorsText[ErrorType]
				+ ?(ValueIsFilled(ErrorsText[ErrorType]), Chars.LF, "")
				+ FullObjectName + " " + NStr("ru = 'без права Редактирование.';
												|en = 'without the Edit right.';");
		EndIf;
	EndDo;
	
	If ValueIsFilled(ErrorsText.InvalidRightsSettings) Then
		Errors.InvalidRightsSettings = Errors.InvalidRightsSettings
			+ ErrorTitle
			+ ErrorsText.InvalidRightsSettings
			+ Chars.LF;
	EndIf;
	If ValueIsFilled(ErrorsText.NonDefaultRights) Then
		Errors.NonDefaultRights = Errors.NonDefaultRights
			+ ErrorTitle
			+ ErrorsText.NonDefaultRights
			+ Chars.LF;
	EndIf;
	
	Return;
	
EndProcedure

// For procedure CheckRightsToAttributes.
&AtServer
Function RoleProperty(Text, XDTODataObject, PropertyName, RequiredValue = Undefined)
	
	If PropertyName = "setForNewObjects" Then
		PropertyPresentation = NStr("ru = 'Устанавливать права для новых объектов';
									|en = 'Set rights for new objects';");
	
	ElsIf PropertyName = "setForAttributesByDefault" Then
		PropertyPresentation = NStr("ru = 'Устанавливать права для реквизитов и табличных частей по умолчанию';
									|en = 'Set rights for attributes and tables by default';");
	
	ElsIf PropertyName = "independentRightsOfChildObjects" Then
		PropertyPresentation = NStr("ru = 'Независимые права подчиненных объектов';
									|en = 'Independent rights of subordinate objects';");
	Else
		Raise NStr("ru = 'Неизвестное свойство роли:';
								|en = 'Unknown role property:';") + " " + PropertyName;
	EndIf;
	
	Value = ObjectProperty1(XDTODataObject, PropertyName);
	If Value = Undefined Then
		Text = Text + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Свойство ""%1"" не найдено.';
				|en = 'The %1 property is not found.';"), PropertyPresentation) + Chars.LF;
		Return Undefined;
	EndIf;
	
	If TypeOf(Value) <> Type("Boolean") Then
		Text = Text + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Свойство ""%1"" не типа Булево.';
				|en = 'The %1 property is not Boolean.';"), PropertyPresentation) + Chars.LF;
		Return Undefined;
	EndIf;
	
	If TypeOf(RequiredValue) = Type("Boolean")
	   And Value <> RequiredValue Then
		
		If RequiredValue Then
			Text = Text + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Свойство ""%1"" должно быть установлено.';
					|en = 'The %1 property must be set.';"), PropertyPresentation) + Chars.LF;
		Else
			Text = Text + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Свойство ""%1"" должно быть снято.';
					|en = 'The %1 property must be cleared.';"), PropertyPresentation) + Chars.LF;
		EndIf;
	EndIf;
	
	Return Value;
	
EndFunction

// For procedure CheckRightsToAttributes.
&AtServer
Function SkippedMetadataObjects(ListOfObjects, SetNewObjectsRights)
	
	// Get a list of metadata objects, for which the View or Modify rights are set.
	SkippedMetadataObjects = New Map;
	
	For Each PropertyObject In ListOfObjects Do
		FullObjectName = ObjectProperty1(PropertyObject, "name");
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
		
		RightsList = ObjectProperty1(PropertyObject, "right", False);
		If RightsList <> Undefined Then
			RightsList = ListOfObjects(RightsList);
			For Each RightsObjectProperties In RightsList Do
				NameOfRight = ObjectProperty1(RightsObjectProperties, "name");
				If NameOfRight = Undefined Then
					Continue;
				EndIf;
				If Not RightsToField.Property(NameOfRight) Then
					Continue;
				EndIf;
				RightsToField[NameOfRight] = ObjectProperty1(RightsObjectProperties, "value");
			EndDo;
		EndIf;
		
		If StrStartsWith(FullObjectName, "DataProcessor")
		 Or StrStartsWith(FullObjectName, "Report") Then
			
			RightsToField.Edit = True;
			
		ElsIf RightsToField.Edit = "Unspecified" Then
			RightsToField.Edit = SetNewObjectsRights;
		EndIf;
		
		If RightsToField.View = "Unspecified" Then
			RightsToField.View = SetNewObjectsRights;
		EndIf;
		
		If RightsToField.Edit <> False Or RightsToField.View <> False Then
			InstalledRights = New Structure;
			InstalledRights.Insert("View", RightsToField.View <> False);
			InstalledRights.Insert("Edit", RightsToField.Edit <> False);
			SkippedMetadataObjects.Insert(FullObjectName, InstalledRights);
		EndIf;
	EndDo;
	
	Return SkippedMetadataObjects;
	
EndFunction

// For procedures CheckObjectProperties, CheckUserVisibility.
&AtServer
Procedure CheckLinksWithObjectPropertyRoles(Text, XDTODataObject, Var_FormName, Links, PropertyName, LinkName)
	
	LinksToRoles = ObjectProperty1(Links, "Value", False);
	If LinksToRoles = Undefined Then
		Return;
	EndIf;
	
	RolesDetails = ListOfObjects(LinksToRoles);
	RoleFound = False;
	
	For Each RoleDetails In RolesDetails Do
		If Not ValueIsFilled(RoleDetails.name) Then
			Continue;
		EndIf;
		If Not RoleFound Then
			RoleFound = True;
			Text = Text + Var_FormName  + "." + PropertyName
				+ "." + XDTODataObject.name + " " + LinkName  +":" + Chars.LF;
		EndIf;
		Text = Text + " - " + RoleDetails.name + Chars.LF;
	EndDo;
	
	If RoleFound Then
		Text = Text + Chars.LF;
	EndIf;
	
EndProcedure

// For procedure CheckObjectProperties, CheckLinksToObjectPropertyRoles.
&AtServer
Function ObjectProperty1(XDTODataObject, ObjectName, Get = True)
	
	If XDTODataObject.Properties().Get(ObjectName) = Undefined Then
		Return Undefined;
	EndIf;
	
	If Get Then
		Return XDTODataObject.Get(ObjectName);
	Else
		Return XDTODataObject[ObjectName];
	EndIf;
	
EndFunction

// For procedure CheckObjectProperties, CheckLinksToObjectPropertyRoles.
&AtServer
Function ListOfObjects(Data)
	
	If TypeOf(Data) = Type("XDTOList") Then
		Return Data;
	Else
		Array = New Array;
		Array.Add(Data);
		Return Array;
	EndIf;
	
EndFunction

&AtServer
Function NameOfMetadata(Val MetadataObject)
	ConfigurationExtension = MetadataObject.ConfigurationExtension(); // ConfigurationExtension
		ConfigurationName = ?(ConfigurationExtension <> Undefined, 
			NStr("ru = 'расширение';
				|en = 'extension';") + " " + ConfigurationExtension.Name, 
			NStr("ru = 'конфигурация';
				|en = 'configuration';") + " " + Metadata.Name);
	Return StringFunctionsClientServer.SubstituteParametersToString("%1 (%2)", 
		MetadataObject.FullName(), ConfigurationName);			
EndFunction	

&AtServer
Function IsNotDemoExtensionObject(MetadataObject)
	
	ConfigurationExtension = MetadataObject.ConfigurationExtension();
	If ConfigurationExtension <> Undefined
		And Not StrStartsWith(ConfigurationExtension.Name, "_Demo") Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtServer
Procedure ApplyCheckExceptions(ErrorsStructure)
	
	If TypeOf(ErrorsStructure) <> Type("Structure") Then
		Return;
	EndIf;
	
	If TypeOf(ErrorsStructure.InvalidData) <> Type("ValueList") Then
		Return;
	EndIf;
	
	NewErroneousData = New ValueList;
	For Each Item In ErrorsStructure.InvalidData Do
		If ObjectsToExclude.FindByValue(Item.Presentation) <> Undefined Then
			Continue;
		EndIf;
		
		NewErroneousData.Add(Item.Value, Item.Presentation);
		
	EndDo;
	
	ErrorsStructure.InvalidData = NewErroneousData;
	
EndProcedure

&AtServer
Procedure PopulateCheckExceptions()
	
	ExceptionsTemplate = FormAttributeToValue("Object").GetTemplate("SubsystemsExcludedFromCheckScope");
	Subsystems = New Array;
	For LineNumber = 1 To ExceptionsTemplate.LineCount() Do
		String = ExceptionsTemplate.GetLine(LineNumber);
		Subsystem = Common.MetadataObjectByFullName(String);
		If Subsystem = Undefined Then
			Continue;
		EndIf;
		
		Subsystems.Add(Subsystem);
	EndDo;
	
	PopulateExcludedObjects(Subsystems);
	
EndProcedure

&AtServer
Procedure PopulateExcludedObjects(Subsystems)
	
	If ObjectsToExclude = Undefined Then
		ObjectsToExclude = New ValueList;
	EndIf;
	
	For Each Subsystem In Subsystems Do
		For Each SubsystemObject In Subsystem.Content Do
			ObjectsToExclude.Add(SubsystemObject.FullName());
		EndDo;
		
		PopulateExcludedObjects(Subsystem.Subsystems);
	EndDo;
	
EndProcedure

#EndRegion
