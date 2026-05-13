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
	
	ValueObject = FormAttributeToValue("Object");
	Subsystems.Load(ValueObject.SubsystemsDependencies());
	
	FillSubsystemsHierarchy();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SubsystemsHierarchyCheckOnChange(Item)
	
	CurrentData = Items.SubsystemsHierarchy.CurrentData;
	SubsystemName = CurrentData.Name;
	
	If CurrentData.Check Then
		
		CurrentData.SelectedByUser = True;
		
		SubsystemsProcessed = New Array;
		SubsystemsProcessed.Add(SubsystemName);
		ChangeMarkRecursively(CurrentData, CurrentData.Check, SubsystemsProcessed);
		
		DependenciesArray = New Array;
		For Each SubsystemName In SubsystemsProcessed Do
			AddDependenciesRecursively(DependenciesArray, SubsystemName);
		EndDo;
		
		For Each Subsystem In SubsystemsHierarchy.GetItems() Do
			
			If DependenciesArray.Find(Subsystem.Name) <> Undefined Then
				Subsystem.Check = True;
			EndIf;
			
			For Each SubordinateSubsystem In Subsystem.GetItems() Do
				
				If DependenciesArray.Find(SubordinateSubsystem.Name) <> Undefined Then
					SubordinateSubsystem.Check = True;
				EndIf;
				
			EndDo;
			
		EndDo;
		Return;
		
	EndIf;
		
	ArrayOfDependentSubsystems = New Array;
	PopulateDependantSubsystemsRecursively(SubsystemsHierarchy, SubsystemName, ArrayOfDependentSubsystems);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SubsystemName", SubsystemName);
	AdditionalParameters.Insert("DependentSubsystems", ArrayOfDependentSubsystems);
	
	If ArrayOfDependentSubsystems.Count() = 0 Then
		UncheckDependentSubsystemsCompletion(DialogReturnCode.Yes, AdditionalParameters);
		Return;
	EndIf;
	
	NotifyDescription = New NotifyDescription("UncheckDependentSubsystemsCompletion", ThisObject, 
		AdditionalParameters);
	SynonymsOfSubsystems = SynonymsOfSubsystems(ArrayOfDependentSubsystems);
	QueryText = StrReplace(
		NStr("ru = 'Пометка будет также снята у зависимых подсистем:
			|%1
			|
			|Продолжить?';
			|en = 'The dependent subsystems will also be unmarked:
			|%1
			|
			|Continue?';"),
		"%1",
		StrConcat(SynonymsOfSubsystems, Chars.LF));
	
	ShowQueryBox(NotifyDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SubsystemsHierarchyOnActivateRow(Item)
	
	If Items.SubsystemsHierarchy.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	SubsystemName = Items.SubsystemsHierarchy.CurrentData.Name;
	If IsBlankString(SubsystemName) Then
		Return;
	EndIf;
	
	SubsystemsByName = Subsystems.FindRows(New Structure("Name", SubsystemName));
	If SubsystemsByName.Count() = 0 Then
		Return;
	EndIf;
	
	Subsystem = SubsystemsByName[0];
	SubsystemDetails = Subsystem.LongDesc;
	
	SynonymsOfSubsystems = New Array;
	For Each Dependence In Subsystem.DependsOnSubsystems Do
		SynonymsOfSubsystems.Add(Subsystems.FindRows(New Structure("Name", TrimAll(Dependence)))[0].Synonym);
	EndDo;
	DependsOnSubsystems = StrConcat(SynonymsOfSubsystems, Chars.LF);
	
	SynonymsOfSubsystems.Clear();
	For Each Dependence In Subsystem.ConditionallyDependsOnSubsystems Do
		SynonymsOfSubsystems.Add(Subsystems.FindRows(New Structure("Name", TrimAll(Dependence)))[0].Synonym);
	EndDo;
	ConditionallyDependsOnSubsystems = StrConcat(SynonymsOfSubsystems, Chars.LF);
	
	ArrayOfDependentSubsystems = New Array;
	PopulateDependantSubsystemsRecursively(SubsystemsHierarchy, SubsystemName, ArrayOfDependentSubsystems, False);
	SynonymsOfSubsystems = SynonymsOfSubsystems(ArrayOfDependentSubsystems);
	DependentSubsystems = StrConcat(SynonymsOfSubsystems, Chars.LF);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure DeleteUnusedSubsystemsCode(Command)
	
	Messages = New Array;

	IsFileInfobase = (StrFind(Upper(InfoBaseConnectionString()), "FILE=") = 1);
	If Not IsFileInfobase Then
		Messages.Add(NStr("ru = 'Удаление кода неиспользуемых подсистем возможно только в файловой базе.';
								|en = 'You can delete the code of unused subsystems only in the file database.';"));
	EndIf;
	
	If DesignerIsOpen() Then
		Messages.Add(NStr("ru = 'Для удаления фрагментов кода неиспользуемых подсистем закройте конфигуратор.';
								|en = 'To delete code snippets of unused subsystems, close Designer.';"));
	EndIf;

	If Messages.Count() > 0 Then
		ShowMessageBox(, StrConcat(Messages, Chars.LF));
		Return;
	EndIf;

	NotifyDescription = New NotifyDescription("AfterConfirmDeletieCodeFragments", ThisObject);
	ShowQueryBox(NotifyDescription, NStr("ru = 'Будет выполнено удаление фрагментов кода неиспользуемых подсистем. Продолжить?';
											|en = 'Code snippets of unused subsystems will be deleted. Continue?';"), 
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SubsystemsClearAll(Command)
	
	ChangeMarkRecursively(SubsystemsHierarchy, False)
	
EndProcedure

&AtClient
Procedure SubsystemsSelectAll(Command)
	
	ChangeMarkRecursively(SubsystemsHierarchy, True)
	
EndProcedure

&AtClient
Procedure OutputSubsystemsList(Command)
	
	TextDocument = New TextDocument;
	AddSubsystemsRecursively(TextDocument, SubsystemsHierarchy);
	TextDocument.Show(NStr("ru = 'Выбранные подсистемы';
									|en = 'Selected subsystems';"));
	
EndProcedure

&AtClient
Procedure SaveSettingsToFile(Command)
	
	NotifyDescription = New NotifyDescription("SaveSettingsToFileFollowUp", ThisObject);
	BeginAttachingFileSystemExtension(NotifyDescription);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SaveSettingsToFileFollowUp(Attached, AdditionalParameters) Export
	
	If Attached Then
		NotifyDescription = New NotifyDescription("AfterFileChoiceInSaveDialog", ThisObject);
		
		SavingDialog = New FileDialog(FileDialogMode.Save);
		SavingDialog.Multiselect = False;
		SavingDialog.Filter = NStr("ru = 'Файл настроек сравнения';
										|en = 'Comparison settings file';") + "(*.xml)|*.xml";
		SavingDialog.FullFileName = "ComparisonSettingsFile";
		SavingDialog.Show(NotifyDescription);
		
	Else
		GetFile(GenerateSettingsFile(), "ComparisonSettingsFile.xml", True);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterFileChoiceInSaveDialog(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ComparisonSettings = GenerateSettingsFile();
	
	FullFileName = Result[0];
	FilesToObtain = New Array;
	FilesToObtain.Add(New TransferableFileDescription(FullFileName, ComparisonSettings));
	
	BeginGettingFiles(New NotifyDescription, FilesToObtain, FullFileName, False);
	
EndProcedure

&AtClient
Procedure AfterConfirmDeletieCodeFragments(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ClearMessages();
		Status(NStr("ru = 'Выполняется удаление фрагментов кода из модулей конфигурации';
						|en = 'Deleting code snippets from the configuration modules';"));
		Result = CutSubsystemFragments();
		BeginDeletingFiles(New NotifyDescription("AfterDeleteCodeSnippets", ThisObject, 
			New Structure("Result", Result)), ModulesExportDirectory);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterDeleteCodeSnippets(AdditionalParameters) Export
	
	Result = AdditionalParameters.Result;
	
	If Not IsBlankString(Result.Errors) Then
		Document = New TextDocument();
		Document.SetText(Result.Errors);
		Document.Show(NStr("ru = 'Пропущенные модули';
								|en = 'Skipped modules';"));
	EndIf;
	ShowMessageBox(, StrReplace(NStr("ru = 'Было проведено замен: %1';
												|en = 'Items replaced:%1';"), "%1", Result.ReplacementsCount1));

EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubsystemsHierarchy.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SubsystemsHierarchy.Required");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Font", New Font(,, True)); //@skip-check new-font - The handler is intended for empty configurations that have no styles.
	
EndProcedure

&AtServer
Function CutSubsystemFragments()
	
	IBAdministratorName = InfoBaseUsers.CurrentUser().Name;
	
	ConnectionString = InfoBaseConnectionString();
	FileInforbaseFind = StrFind(ConnectionString, "File=");
	FirstPathChar = FileInforbaseFind + 6;
	ConnectionString = Mid(ConnectionString, FirstPathChar);
	LastPathChar = StrFind(ConnectionString, ";");
	ConnectionString = Left(ConnectionString, LastPathChar - 2);
	IBDirectory = ConnectionString;
	
	ModulesExportDirectory = GetTempFileName("ModulesExport");
	CreateDirectory(ModulesExportDirectory);
	
	DeleteFiles(ModulesExportDirectory, "*");
	ExportConfigurationModules();
	
	ReplacementsCount1 = 0;
	Errors = "";
	SubsystemsToDelete = SubsystemsToDeleteList();
	If SubsystemsToDelete.Count() > 0 Then
		
		FilesArray = FindFiles(ModulesExportDirectory, "*.txt");
		FileText = New TextDocument;
		
		For Each File In FilesArray Do
			
			MessageText = NStr("ru = 'Выполняется удаление фрагментов кода в модуле [ModuleFileName]';
									|en = 'Deleting code snippets in module [ModuleFileName]';");
			MessageText = StrReplace(MessageText, "[ModuleFileName]", File.Name);
			WriteLogEvent(EventLogEvent(), EventLogLevel.Information,,, MessageText);
			
			FileText.Read(File.FullName);
			TextString = FileText.GetText();
			For Each SubsystemName In SubsystemsToDelete Do
				CutSubsystemFragmentsFromText(File.Name, SubsystemName, TextString, ReplacementsCount1, Errors);
			EndDo;
			FileText.SetText(TextString);
			FileText.Write(File.FullName);
		EndDo;
		
	EndIf;
	
	If ReplacementsCount1 > 0 Then
		ImportModulesIntoConfiguration();
	EndIf;
	
	Return New Structure("ReplacementsCount1,Errors", ReplacementsCount1, Errors);
	
EndFunction

&AtServer
Procedure CutSubsystemFragmentsFromText(ModuleFileName, SubsystemName, TextString, ReplacementsCount1, Errors)
	
	FragmentBeginning = FindFragmentBeginning(TextString, SubsystemName);
	While FragmentBeginning > 0 Do
		
		FragmentEndPosition = FindFragmentEnd(TextString, SubsystemName);
		If FragmentEndPosition = 0 Then
			MessageText = NStr("ru = '%1: для открывающей скобки %2 не обнаружена закрывающая скобка.';
									|en = '%1: close parenthesis is not found for open parenthesis %2.';");
			MessageText = StrReplace(MessageText, "%2", "// " + SubsystemName);
			MessageText = StrReplace(MessageText, "%1", ModuleFileName);
			WriteLogEvent(EventLogEvent(), EventLogLevel.Warning,,, MessageText);
			Errors = Errors + Chars.LF + MessageText;
			Return;
		EndIf; 				
		
		If FragmentEndPosition < FragmentBeginning Then
			MessageText = NStr("ru = '%1: для открывающей скобки %2 закрывающая скобка расположена выше по тексту.';
									|en = '%1: close parenthesis is above in the text for open parenthesis %2.';");
			MessageText = StrReplace(MessageText, "%2", "// " + SubsystemName);
			MessageText = StrReplace(MessageText, "%1", ModuleFileName);
			WriteLogEvent(EventLogEvent(), EventLogLevel.Warning,,, MessageText);
			Errors = Errors + Chars.LF + MessageText;
			Return;
		EndIf; 	

		FragmentBeginningLength = StrLen("// " + SubsystemName);
		IntermediateString = Mid(TextString, FragmentBeginning + FragmentBeginningLength + 1, FragmentEndPosition - (FragmentBeginning + FragmentBeginningLength) + 1);
		If FindFragmentBeginning(IntermediateString, SubsystemName) > 0 Then 
			MessageText = NStr("ru = '%1: внутри открывающейся скобки %2 есть еще одна открывающаяся скобка, до закрывающейся.';
									|en = '%1: there is an open parenthesis inside open parenthesis %2 before the close parenthesis.';");
			MessageText = StrReplace(MessageText, "%2", "// " + SubsystemName);
			MessageText = StrReplace(MessageText, "%1", ModuleFileName);
			WriteLogEvent(EventLogEvent(), EventLogLevel.Warning,,, MessageText);
			Errors = Errors + Chars.LF + MessageText;
			Return;
		EndIf;	
		
		LastCharPosition = FragmentEndPosition + StrLen("// End " + SubsystemName);
		CutFragment(TextString, FragmentBeginning - 1, LastCharPosition);
		ReplacementsCount1 = ReplacementsCount1 + 1;
		
		FragmentBeginning = FindFragmentBeginning(TextString, SubsystemName);
		
	EndDo;
	
EndProcedure	

&AtServer
Function FindFragmentBeginning(Val TextString, Val SubsystemName)
	
	TextString 	= Lower(TextString);
	SubsystemName 	= Lower(SubsystemName);
	
	FirstOption = "// " + SubsystemName;
	SecondOption = "//" + SubsystemName;
	
	If StrFind(TextString, FirstOption) = 0 And StrFind(TextString, SecondOption) = 0 Then
		Return 0;
	EndIf;
	
	For Iteration = 1 To StrLen(TextString) Do
		If Mid(TextString, Iteration, StrLen(FirstOption)) = (FirstOption) Then 
			If Not IsBlankString(Mid(TextString, Iteration + StrLen(FirstOption), 1)) Then 
				Continue;
			EndIf;
			Return Iteration;
		EndIf;
		
		If Mid(TextString, Iteration, StrLen(SecondOption)) = (SecondOption) Then 
			If Not IsBlankString(Mid(TextString, Iteration + StrLen(SecondOption), 1)) Then 
				Continue;
			EndIf;	
			Return Iteration;
		EndIf;
	EndDo;	
	
	Return 0;
	
EndFunction

&AtServer
Function FindFragmentEnd(Val TextString, Val SubsystemName)
	
	TextString 	= Lower(TextString);
	SubsystemName 	= Lower(SubsystemName);
	
	FirstOption = "// end " + SubsystemName;
	SecondOption = "//end " + SubsystemName;
	
	If StrFind(TextString, FirstOption) = 0 And StrFind(TextString, SecondOption) = 0 Then
		Return 0;
	EndIf;
	
	For Iteration = 1 To StrLen(TextString) Do
		
		If Mid(TextString, Iteration, StrLen(FirstOption)) = (FirstOption) Then 
			If Not IsBlankString(Mid(TextString, Iteration + StrLen(FirstOption), 1)) Then 
				Continue;
			EndIf;
			Return Iteration;
		EndIf;
		
		If Mid(TextString, Iteration, StrLen(SecondOption)) = (SecondOption) Then 
			If Not IsBlankString(Mid(TextString, Iteration + StrLen(SecondOption), 1)) Then 
				Continue;
			EndIf;
			Return Iteration;
		EndIf;
	EndDo;
	
	Return 0;
	
EndFunction

&AtServer
Procedure CutFragment(TextString, Begin, End)
	TextString = TrimR(Left(TextString, Begin)) + Mid(TextString, End);
EndProcedure	

&AtServer
Procedure ImportModulesIntoConfiguration()
		
	PlatformCommandLine = BinDir() + "1cv8.exe";
	
	ConfigurationDirectory = IBDirectory;
	User = IBAdministratorName;
	Password = "";
	CommandLine = PlatformCommandLine + " DESIGNER /F"""
		+ ConfigurationDirectory + """ /N"""
		+ User + """ /P""" + Password
		+ """ /LoadConfigFiles """ + ModulesExportDirectory
		+ """ -Module";
				  
	RunApp(CommandLine,,True);
	
EndProcedure

&AtServer
Procedure ExportConfigurationModules()

	PlatformCommandLine = BinDir() + "1cv8.exe";
	ConfigurationDirectory = IBDirectory;
	User = IBAdministratorName;
	Password = "";
	CommandLine = PlatformCommandLine + " DESIGNER /F"""
		+ ConfigurationDirectory + """ /N"""
		+ User + """ /P""" + Password
		+ """ /DumpConfigFiles """ + ModulesExportDirectory
		+ """ -Module";
				  
	RunApp(CommandLine,,True);

EndProcedure

&AtServer
Function SubsystemsToDeleteList()
	
	SubsystemsList = Subsystems.Unload(, "Name").UnloadColumn("Name");
	UsedSubsystemsList = UsedSubsystemsList();
	
	SubsystemsToDelete = New Array;
	For Each SubsystemName In SubsystemsList Do
		If UsedSubsystemsList.Find(SubsystemName) = Undefined Then 
			SubsystemsToDelete.Add("StandardSubsystems." + SubsystemName);
		EndIf;
	EndDo;
		
	Return SubsystemsToDelete;
	
EndFunction

&AtServer
Function UsedSubsystemsList()
	
	Result = New Array;
	StandardSubsystems = Metadata.Subsystems.Find("StandardSubsystems");
	If StandardSubsystems = Undefined Then
		ExceptionText = NStr("ru = 'Ошибка внедрения БСП. Группа подсистем ""[SubsystemName]"" не найдена в метаданных конфигурации базы данных.';
								|en = 'SSL integration error. Subsystem group ""[SubsystemName]"" is not found in the database configuration metadata.';");
		ExceptionText = StrReplace(ExceptionText, "[SubsystemName]", "StandardSubsystems");
		Raise ExceptionText;
	Else
		SubsystemsList = StandardSubsystems.Subsystems;
		GetSubsystems(Result, SubsystemsList, "")
	EndIf;
	Return Result;
	
EndFunction

&AtServer
Procedure GetSubsystems(SubsystemsList, NestedSubsystems, SubsystemPath)
	
	If NestedSubsystems.Count() > 0 Then
		For Each Subsystem In NestedSubsystems Do
			BackupPath = SubsystemPath;
			SubsystemPath = SubsystemPath + "." + String(Subsystem.Name);
			GetSubsystems(SubsystemsList, Subsystem.Subsystems, SubsystemPath);
			SubsystemsList.Add(Mid(SubsystemPath, 2));
			SubsystemPath = BackupPath;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Function EventLogEvent()
	
	Return NStr("ru = 'Помощник внедрения БСП';
				|en = 'SSL integration wizard';", DefaultLanguageCode());
	
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
Function GenerateSettingsFile()
	
	TemplateFile1 = GetTempFileName("xml");
	TextWriter = New TextWriter(TemplateFile1);
	TextWriter.Write(FormAttributeToValue("Object").GetTemplate("SettingsTemplate").GetText());
	TextWriter.Close();
	
	DOMDocument = DOMDocument(TemplateFile1);
	DeleteFiles(TemplateFile1);
	
	// Objects section.
	NodeObjects = DOMDocument.GetElementByTagName("Objects")[0];
	
	SelectSubsystemsCheckBoxesRecursively(SubsystemsHierarchy, DOMDocument, NodeObjects, "");
	
	SettingsFileName = GetTempFileName("xml");
	WriteDOMDocumentToFile(DOMDocument, SettingsFileName);
	
	BinaryData = New BinaryData(SettingsFileName);
	Address = PutToTempStorage(BinaryData, UUID);
	
	DeleteFiles(SettingsFileName);
	Return Address;
	
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
Procedure AddSubsystemDetails(SubsystemName, DOMDocument, NodeObjects, InterfaceSubsystem = False)
	
	ObjectNode = DOMDocument.CreateElement("Object");
	ObjectNode.SetAttribute("fullNameInSecondConfiguration", SubsystemName);
	
	NodeRule = DOMDocument.CreateElement("MergeRule");
	NodeRule.TextContent = "GetFromSecondConfiguration";
	ObjectNode.AppendChild(NodeRule);
	
	If Not InterfaceSubsystem Then
		NodeSubsystem = DOMDocument.CreateElement("Subsystem");
		NodeSubsystem.SetAttribute("configuration", "Second");
		NodeSubsystem.SetAttribute("includeObjectsFromSubordinateSubsystems", "true");
		
		NodeRule = DOMDocument.CreateElement("MergeRule");
		NodeRule.TextContent = "GetFromSecondConfiguration";
		NodeSubsystem.AppendChild(NodeRule);
		ObjectNode.AppendChild(NodeSubsystem);
	EndIf;
	
	NodeObjects.AppendChild(ObjectNode);
	
EndProcedure

&AtServer
Procedure WriteDOMDocumentToFile(DOMDocument, PathToFile)
	
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(PathToFile);
	
	DOMWriter = New DOMWriter;
	DOMWriter.Write(DOMDocument, XMLWriter);
	
EndProcedure

&AtClient
Procedure ChangeMarkRecursively(HierarchyLevel, CheckMarkValue, SubsystemsProcessed = Undefined)
	
	For Each HierarchyLine In HierarchyLevel.GetItems() Do
		
		If HierarchyLine.Required Then
			Continue;
		EndIf;
		
		HierarchyLine.Check = CheckMarkValue;
		HierarchyLine.SelectedByUser = CheckMarkValue;
		
		If SubsystemsProcessed <> Undefined Then
			SubsystemsProcessed.Add(HierarchyLine.Name);
		EndIf;
		
		ChangeMarkRecursively(HierarchyLine, CheckMarkValue, SubsystemsProcessed);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure AddSubsystemsRecursively(TextDocument, HierarchyLevel)
	
	For Each Subsystem In HierarchyLevel.GetItems() Do
		
		If Not Subsystem.Check Then
			Continue;
		EndIf;
		
		TextDocument.AddLine(Subsystem.Name);
		AddSubsystemsRecursively(TextDocument, Subsystem);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure AddDependenciesRecursively(Dependencies, SubsystemName)
	
	If IsBlankString(SubsystemName) Then
		Return;
	EndIf;
	
	SubsystemsInformation = Subsystems.FindRows(New Structure("Name", SubsystemName));
	If SubsystemsInformation.Count() = 0 Then
		Return;
	EndIf;
	
	Subsystem = SubsystemsInformation[0];
	For Each DependencyOnSubsystem In Subsystem.DependsOnSubsystems Do
		
		If Dependencies.Find(DependencyOnSubsystem) <> Undefined Then
			Continue;
		EndIf;
		
		Dependencies.Add(DependencyOnSubsystem);
		AddDependenciesRecursively(Dependencies, DependencyOnSubsystem);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SelectSubsystemsCheckBoxesRecursively(HierarchyLevel, DOMDocument, NodeObjects, CaptureFileName)
	
	For Each Subsystem In HierarchyLevel.GetItems() Do
		
		If Subsystem.Check Then
			
			SubsystemName = Subsystem.Name;
			If StrFind(SubsystemName, ".") > 0 Then
				SubsystemName = StrReplace(SubsystemName, ".", ".Subsystem.");
			EndIf;
			
			NameTemplate = "Subsystem.StandardSubsystems.Subsystem.%1";
			FullName = StrReplace(NameTemplate, "%1", SubsystemName);
			
			AddSubsystemDetails(FullName, DOMDocument, NodeObjects);
			If SubsystemName = "ApplicationSettings" Then
				FullName = "Subsystem.Administration";
				AddSubsystemDetails(FullName, DOMDocument, NodeObjects, True);
			ElsIf SubsystemName = "AttachableCommands" Then
				FullName = "Subsystem.AttachableReportsAndDataProcessors";
				AddSubsystemDetails(FullName, DOMDocument, NodeObjects, True);
			EndIf;
			
		EndIf;
		
		SelectSubsystemsCheckBoxesRecursively(Subsystem, DOMDocument, NodeObjects, CaptureFileName);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillSubsystemsHierarchy()
	
	ValueTree = FormAttributeToValue("SubsystemsHierarchy", Type("ValueTree"));
	ValueTree.Rows.Clear();
	CreatedRowsOfTree = New Map;

	For Each TableRow In Subsystems Do
		If CreatedRowsOfTree[TableRow.Name] <> Undefined Then
			Continue;
		EndIf; 
		If Not IsBlankString(TableRow.Parent) Then
			DimensionString = ValueTree.Rows.Find(TableRow.Parent, "Name", True);
			If DimensionString = Undefined Then
				ParentLevelRow = Subsystems.FindRows(New Structure("Name", TableRow.Parent))[0];
				DimensionString = ValueTree.Rows.Add(); // Only the second hierarchy level is acceptable.
				FillPropertyValues(DimensionString, ParentLevelRow);
				CreatedRowsOfTree[ParentLevelRow.Name] = True; 
			EndIf;
			TreeRow = DimensionString.Rows.Add(); 
		Else
			TreeRow = ValueTree.Rows.Add(); 
		EndIf;
		FillPropertyValues(TreeRow, TableRow);
		CreatedRowsOfTree[TableRow.Name] = True; 
	EndDo;

	ValueTree.Rows.Sort("Synonym", True);
	ValueToFormAttribute(ValueTree, "SubsystemsHierarchy");

EndProcedure

&AtServer
Function DefaultLanguageCode()
	
	If Metadata.Constants.Find("DefaultLanguage") <> Undefined
		And ValueIsFilled(Constants["DefaultLanguage"].Get()) Then
		Return Constants["DefaultLanguage"].Get();
	EndIf;
	
	Return Metadata.DefaultLanguage.LanguageCode;
	
EndFunction

&AtClient
Function SynonymsOfSubsystems(Subsystems)
	
	SynonymsOfSubsystems = New Array;
	
	For Each DependentSubsystem In Subsystems Do
		SynonymsOfSubsystems.Add(DependentSubsystem.Synonym);
	EndDo;
	
	Return SynonymsOfSubsystems;
	
EndFunction

&AtClient
Function SubsystemsNames(Subsystems)
	
	SubsystemsNames = New Array;
	
	For Each DependentSubsystem In Subsystems Do
		SubsystemsNames.Add(DependentSubsystem.Name);
	EndDo;
	
	Return SubsystemsNames;
	
EndFunction

&AtClient
Procedure PopulateDependantSubsystemsRecursively(HierarchyLevel, SubsystemName, DependentSubsystems, MarkedOnly = True)
	
	For Each Subsystem In HierarchyLevel.GetItems() Do
		
		If (Not MarkedOnly) Or Subsystem.Check Then
			
			Dependencies = Subsystems.FindRows(New Structure("Name", Subsystem.Name))[0].DependsOnSubsystems;
			If (Dependencies.Find(SubsystemName) <> Undefined) And (DependentSubsystems.Find(Subsystem) = Undefined) Then
				DependentSubsystems.Add(Subsystem);
				PopulateDependantSubsystemsRecursively(SubsystemsHierarchy, Subsystem.Name, DependentSubsystems, MarkedOnly);
			EndIf;
			
		EndIf;
		
		PopulateDependantSubsystemsRecursively(Subsystem, SubsystemName, DependentSubsystems, MarkedOnly);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure PopulateDependsOnSubsystemsRecursively(SubsystemsCollection, Dependencies, DependsOnSubsystems)
	
	For Each Subsystem In SubsystemsCollection Do
		
		If Subsystem.SelectedByUser Then
			Continue;
		EndIf;
		
		If (Dependencies.Find(Subsystem.Name) = Undefined) Or (Not Subsystem.Check) Then
			PopulateDependsOnSubsystemsRecursively(Subsystem.GetItems(), Dependencies, DependsOnSubsystems);
			Continue;
		EndIf;
		
		SubsystemDependencies = Subsystems.FindRows(New Structure("Name", Subsystem.Name))[0].DependsOnSubsystems;
		HasZeroLinkedSubsystemsSelected = True;
		If (SubsystemDependencies.Count() > 0) Then
			HasZeroLinkedSubsystemsSelected = Not HasLinkedSubsystemsMarked(SubsystemsHierarchy.GetItems(),
				SubsystemDependencies, Dependencies, True);
		EndIf;
		
		ArrayOfDependentSubsystems = New Array;
		PopulateDependantSubsystemsRecursively(SubsystemsHierarchy, Subsystem.Name, ArrayOfDependentSubsystems, False);
		DependentSubsystemsNames = SubsystemsNames(ArrayOfDependentSubsystems);
		
		HasZeroDependentSubsystemsMarked = True;
		If DependentSubsystemsNames.Count() > 0 Then
			HasZeroDependentSubsystemsMarked = Not HasLinkedSubsystemsMarked(SubsystemsHierarchy.GetItems(),
				DependentSubsystemsNames, Dependencies);
		EndIf;
		
		If HasZeroLinkedSubsystemsSelected
			And HasZeroDependentSubsystemsMarked
			And (Not Subsystem.Required)
			And (DependsOnSubsystems.Find(Subsystem) = Undefined) Then
			DependsOnSubsystems.Add(Subsystem);
		EndIf;
		
		PopulateDependsOnSubsystemsRecursively(Subsystem.GetItems(), SubsystemDependencies, DependsOnSubsystems);
		
	EndDo;
	
EndProcedure

&AtClient
Function HasLinkedSubsystemsMarked(SubsystemsCollection, LinkedSubsystems, Dependencies, SelectedByUser = False)
	
	For Each SubordinateSubsystem In SubsystemsCollection Do
		
		If LinkedSubsystems.Find(SubordinateSubsystem.Name) = Undefined Then
			Continue;
		EndIf;
		
		If Dependencies.Find(SubordinateSubsystem.Name) <> Undefined Then
			Continue;
		EndIf;
		
		IsSubsystemMarked = ?(SelectedByUser, SubordinateSubsystem.Check And SubordinateSubsystem.SelectedByUser,
			SubordinateSubsystem.Check);
		
		If IsSubsystemMarked Then
			Return True;
		EndIf;
		
		If HasLinkedSubsystemsMarked(SubordinateSubsystem.GetItems(),
				LinkedSubsystems, Dependencies, SelectedByUser) Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Procedure UncheckDependentSubsystemsCompletion(Response, AdditionalParameters) Export
	
	CurrentData = Items.SubsystemsHierarchy.CurrentData;
	If Response <> DialogReturnCode.Yes Then
		CurrentData.Check = True;
		Return;
	EndIf;
	
	ProcessedSubsystems = New Array;
	ProcessedSubsystems.Add(CurrentData.Name);
	
	CurrentData.SelectedByUser = False;
	
	ChangeMarkRecursively(CurrentData, CurrentData.Check, ProcessedSubsystems);
	
	SubsystemName = AdditionalParameters.SubsystemName;
	For Each ArrayElement In AdditionalParameters.DependentSubsystems Do
		ProcessedSubsystems.Add(ArrayElement.Name);
		ArrayElement.Check = False;
		ArrayElement.SelectedByUser = False;
	EndDo;
	
	SubsystemsDependencies = New Array;
	For Each SubsystemName In ProcessedSubsystems Do
		AddDependenciesRecursively(SubsystemsDependencies, SubsystemName);
	EndDo;
	
	ArrayDependsOnSubsystems = New Array;
	PopulateDependsOnSubsystemsRecursively(SubsystemsHierarchy.GetItems(), SubsystemsDependencies, ArrayDependsOnSubsystems);
	If ArrayDependsOnSubsystems.Count() > 0 Then
		
		SynonymsOfSubsystems = SynonymsOfSubsystems(ArrayDependsOnSubsystems);
		
		NotificationParameters = New Structure;
		NotificationParameters.Insert("DependsOnSubsystems", ArrayDependsOnSubsystems);
		NotificationParameters.Insert("SynonymsOfSubsystems", SynonymsOfSubsystems);
		
		SavedResponse = SavedAnswerOfUser();
		If SavedResponse = Undefined Then
			
			QueryText = StrReplace(
				NStr("ru = 'При выборе данной подсистемы были автоматически отмечены для внедрения:
					|%1
					|
					|Снять пометку?';
					|en = 'When selecting this subsystem, the following subsystems were marked for deployment:
					|%1
					|
					|Unmark?';"),
				"%1",
				StrConcat(SynonymsOfSubsystems, Chars.LF));
			
			NotifyDescription = New NotifyDescription("UncheckDependsOnSubsystemsCompletion", ThisObject, NotificationParameters);
			
			OpeningParameters = New Structure;
			OpeningParameters.Insert("Title", ClientApplication.GetCaption());
			OpeningParameters.Insert("MessageText", QueryText);
			
			FormNameArray1 = StrSplit(FormName, ".");
			FormNameArray1.Delete(FormNameArray1.UBound());
			QuestionFormName = StrConcat(FormNameArray1, ".") + ".DoQueryBox";
			OpenForm(QuestionFormName, OpeningParameters,,,,, NotifyDescription);
			
			Return;
		EndIf;
			
		AnswerParameters = New Structure;
		AnswerParameters.Insert("Value", ?(SavedResponse = True, DialogReturnCode.Yes, DialogReturnCode.No));
		AnswerParameters.Insert("NeverAskAgain", False);
		
		UncheckDependsOnSubsystemsCompletion(AnswerParameters, NotificationParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UncheckDependsOnSubsystemsCompletion(Response, AdditionalParameters) Export
	
	If Response = Undefined Then
		Return;
	EndIf;
	
	If Response.NeverAskAgain Then
		TheUserResponse = (Response.Value = DialogReturnCode.Yes);
		SaveUserSResponseToServer(TheUserResponse);
	EndIf;
	
	If Response.Value <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	For Each ArrayElement In AdditionalParameters.DependsOnSubsystems Do
		ArrayElement.Check = False;
	EndDo;
	
	StateText = StrReplace(
		NStr("ru = 'Снята пометка с подсистем:
			|%1';
			|en = 'The following subsystems are unmarked:
			|%1';"),
		"%1",
		StrConcat(AdditionalParameters.SynonymsOfSubsystems, Chars.LF));
	
	Status(StateText);
	
EndProcedure

&AtServer
Procedure SaveUserSResponseToServer(TheUserResponse)
	
	CommonSettingsStorage.Save("UserCommonSettings",
		"QuestionOfUncheckingAutomaticallyMarkedSubsystems",
		TheUserResponse);
	
EndProcedure

&AtServer
Function SavedAnswerOfUser()
	
	SavedResponse = CommonSettingsStorage.Load("UserCommonSettings",
		"QuestionOfUncheckingAutomaticallyMarkedSubsystems");
	
	Return SavedResponse;
	
EndFunction

#EndRegion
