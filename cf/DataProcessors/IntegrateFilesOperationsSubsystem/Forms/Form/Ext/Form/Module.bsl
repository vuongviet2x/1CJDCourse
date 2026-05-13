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
	
	Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
	
	ExportFilesToDirectory = 1;
	ChangeVisibilityAvailability();
	SetConditionalAppearance();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ExportFilesToDirectoryOnChange(Item)
	
	ChangeVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure WorkingDirectoryOnChange(Item)
	
	If ValueIsFilled(WorkingDirectory) Then
		WorkingDirectory = AddLastPathSeparator(WorkingDirectory);
	Else
		ExportFilesToDirectory = 1;
	EndIf;
	
	ChangeVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure WorkingDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	ChoiceDialog.Title          = NStr("ru = 'Выберите каталог, в который выгружены файлы конфигурации';
											|en = 'Select a directory, to which the configuration files are exported';");
	ChoiceDialog.Directory            = WorkingDirectory(ThisObject);
	ChoiceDialog.Multiselect = False;
	
	Handler = New NotifyDescription("SelectDirectoryToDumpConfigurationCompletion", ThisObject);
	FileSystemClient.ShowSelectionDialog(Handler, ChoiceDialog);
	
EndProcedure

&AtClient
Procedure WorkingDirectoryOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
#If Not WebClient Then
		
		Directory = WorkingDirectory(ThisObject);
		If Not ValueIsFilled(Directory) Then
			Return;
		EndIf;
		
		FileSystemClient.OpenExplorer(Directory);
		
#EndIf
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersObjectsTree

&AtClient
Procedure ObjectsTreeUseOnChange(Item)
	
	CurrentData = Items.ObjectsTree.CurrentData;
	If CurrentData.Use = 2 Then
		CurrentData.Use = 0;
	EndIf;
	
	ChangeMarkRecursively(CurrentData, CurrentData.Use);
	UpdateLegend();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	CurrentPage = Items.Pages.CurrentPage;
	If CurrentPage = Items.PagesConfigurationExport Then
		
		If IsBlankString(WorkingDirectory) Then
			MessageText = NStr("ru = 'Не заполнено поле ""Каталог выгрузки""';
									|en = 'The Export directory field is blank';");
			CommonClient.MessageToUser(MessageText, , "WorkingDirectory");
			Return;
		EndIf;
		
		ExportConfigurationAndReadMetadata();
		UpdateLegend();
		Items.Pages.CurrentPage = Items.DeploymentSettingsPage;
		
	Else
		PlaceCodeFragments();
	EndIf;
	
	ChangeVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	Items.Pages.CurrentPage = Items.PagesConfigurationExport;
	ChangeVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure ObjectsTreeClearMark(Command)
	
	ChangeMarkRecursively(ObjectsTree, 0);
	UpdateLegend();
	
EndProcedure

&AtClient
Procedure ObjectsTreeSetMark(Command)
	
	ChangeMarkRecursively(ObjectsTree, 1);
	UpdateLegend();
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	ChangeVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure ExpandAll(Command)
	
	For Each TreeItem In ObjectsTree.GetItems() Do
		Items.ObjectsTree.Expand(TreeItem.GetID(), True);
	EndDo;
	
EndProcedure

&AtClient
Procedure CollapseAll(Command)
	
	For Each TreeItem In ObjectsTree.GetItems() Do
		Items.ObjectsTree.Collapse(TreeItem.GetID());
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectDirectoryToDumpConfigurationCompletion(SelectedFiles, ExecutionParameters) Export
	
	If TypeOf(SelectedFiles) <> Type("Array")
		Or SelectedFiles.Count() = 0 Then
		Return;
	EndIf;
	
	WorkingDirectory = AddLastPathSeparator(SelectedFiles[0]);
	ChangeVisibilityAvailability();
	
EndProcedure

&AtServer
Procedure ChangeVisibilityAvailability()
	
	CurrentPage = Items.Pages.CurrentPage;
	If CurrentPage = Items.DeploymentSettingsPage Then
		Items.Back.Visible = True;
		Items.Next.Title = NStr("ru = 'Расставить фрагменты кода';
										|en = 'Arrange code fragments';");
	Else
		
		Items.DesignerOpenedGroup.Visible   = DesignerIsOpen();
		Items.ConfigurationModifiedGroup.Visible = DataBaseConfigurationChangedDynamically()
															Or ConfigurationChanged();
		Items.Back.Visible = False;
		Items.Next.Title = NStr("ru = 'Далее >';
										|en = 'Next >';");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	MetadataKindsAppearance = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceFilter                = MetadataKindsAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ConditionalAppearanceFilter.Use  = True;
	ConditionalAppearanceFilter.LeftValue  = New DataCompositionField("ObjectsTree.MetadataKind");
	ConditionalAppearanceFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ConditionalAppearanceFilter.RightValue = "MetadataObjects_Group";
	
	MetadataKindsAppearance.Appearance.SetParameterValue("Font", StyleFonts.ImportantLabelFont);
	
	AppearanceField               = MetadataKindsAppearance.Fields.Items.Add();
	AppearanceField.Field          = New DataCompositionField("ObjectsTreeObject");
	AppearanceField.Use = True;
	
	MetadataAppearance = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceFilter                = MetadataAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ConditionalAppearanceFilter.Use  = True;
	ConditionalAppearanceFilter.LeftValue  = New DataCompositionField("ObjectsTree.MetadataKind");
	ConditionalAppearanceFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ConditionalAppearanceFilter.RightValue = "MetadataObject";
	
	MetadataAppearance.Appearance.SetParameterValue("Font", StyleFonts.ImportantLabelFont);
	
	AppearanceField               = MetadataAppearance.Fields.Items.Add();
	AppearanceField.Field          = New DataCompositionField("ObjectsTreeObject");
	AppearanceField.Use = True;
	
EndProcedure

&AtClient
Procedure UpdateLegend()
	
	TotalForms     = 0;
	AlreadyBuiltIn   = 0;
	WillBeBuiltIn = 0;
	
	UpdateCounters(ObjectsTree);
	
	Legend = NStr("ru = 'Всего форм: %1.
		|Уже встроено: %2.
		|Будет встроено: %3.';
		|en = 'Forms total: %1.
		|Already built-in: %2.
		|Will be built-in: %3.';");
	Items.DecorationLegend.Title = StringFunctionsClientServer.SubstituteParametersToString(Legend,
			TotalForms, AlreadyBuiltIn, WillBeBuiltIn);
	
EndProcedure

&AtClient
Procedure UpdateCounters(TreeItem)
	
	ItemsCollection = TreeItem.GetItems();
	If ItemsCollection.Count() = 0 Then
		TotalForms     = TotalForms + 1;
		AlreadyBuiltIn   = AlreadyBuiltIn + ?(TreeItem.Use = 2, 1, 0);
		WillBeBuiltIn = WillBeBuiltIn + ?(TreeItem.Use = 1, 1, 0);
	Else
		
		For Each BranchItem In ItemsCollection Do
			UpdateCounters(BranchItem);
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeMarkRecursively(TreeRow, Value)
	
	SubordinateTreeItems = TreeRow.GetItems();
	For Each SubordinateItem In SubordinateTreeItems Do
		SubordinateItem.Use = Value;
		ChangeMarkRecursively(SubordinateItem, Value);
	EndDo;
	
EndProcedure

&AtServer
Procedure ExportConfigurationAndReadMetadata()
	
	DumpDirectory = StrReplace(WorkingDirectory(ThisObject), "\", GetPathSeparator());
	If ExportFilesToDirectory Then
		UploadConfigurationToXML(DumpDirectory, User, Password);
	EndIf;
	
	ItemsRoot = ObjectsTree.GetItems();
	MetadataKind = "MetadataObjects_Group";
	
	ObjectsTree.GetItems().Clear();
	AddMetadata(DumpDirectory, Metadata, MetadataKind, "CommonForms", ItemsRoot);
	AddMetadata(DumpDirectory, Metadata, MetadataKind, "Catalogs", ItemsRoot);
	AddMetadata(DumpDirectory, Metadata, MetadataKind, "Documents", ItemsRoot);
	AddMetadata(DumpDirectory, Metadata, MetadataKind, "DataProcessors", ItemsRoot);
	AddMetadata(DumpDirectory, Metadata, MetadataKind, "BusinessProcesses", ItemsRoot);
	
EndProcedure

&AtServer
Procedure PlaceCodeFragments()
	
	ChangedFiles = New Array;
	PlaceFragmentsInSelectedForms(WorkingDirectory, ObjectsTree, ChangedFiles);
	SetMarkOfCompletedItems(ObjectsTree);
	
	WillBeBuiltIn = 0;
	Legend = NStr("ru = 'Всего форм: %1.
		|Уже встроено: %2.
		|Будет встроено: %3.';
		|en = 'Forms total: %1.
		|Already built-in: %2.
		|Will be built-in: %3.';");
	Items.DecorationLegend.Title = StringFunctionsClientServer.SubstituteParametersToString(Legend,
			TotalForms, AlreadyBuiltIn, WillBeBuiltIn);
	
	If ExportFilesToDirectory Then
		LoadConfigurationFromXML(WorkingDirectory, User, Password, ChangedFiles);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetMarkOfCompletedItems(TreeItem)
	
	For Each SubordinateItem In TreeItem.GetItems() Do
		
		If SubordinateItem.Use = 1 Then
			
			If SubordinateItem.MetadataKind = "Form" Then
				AlreadyBuiltIn = AlreadyBuiltIn + 1;
				SubordinateItem.Use = 2;
			Else
				SubordinateItem.Use = 0;
			EndIf;
			
		EndIf;
		
		SetMarkOfCompletedItems(SubordinateItem);
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure UploadConfigurationToXML(WorkingDirectory, User, Password)
	
	Pstab = Chars.LF + Chars.Tab;
	If FileExists(WorkingDirectory) Then
		DeleteFiles(WorkingDirectory, "*");
	Else
		CreateDirectory(WorkingDirectory);
	EndIf;
	
	ConfigurationPath = InfoBaseConnectionString();
	OneCDCopyDirectory = Undefined;
	
	If DesignerIsOpen() Then
		
		If Common.FileInfobase() Then
			
			InfobaseDirectory = StringFunctionsClientServer.ParametersFromString(ConfigurationPath).file;
			OneCDCopyDirectory = WorkingDirectory + "BaseCopy" + GetPathSeparator();
			CreateDirectory(OneCDCopyDirectory);
			FileCopy(InfobaseDirectory + "\1Cv8.1CD", OneCDCopyDirectory + "1Cv8.1CD");
			ConfigurationPath = StringFunctionsClientServer.SubstituteParametersToString(
				"File=""%1"";", OneCDCopyDirectory);
			
		Else
			Raise NStr("ru = 'Для выгрузки модулей закройте конфигуратор.';
									|en = 'To export modules, close Designer.';");
		EndIf;
		
	EndIf;
	
	MessagesFileName = WorkingDirectory + "Upload0.log";
	
	StartupCommand = New Array;
	StartupCommand.Add(BinDir() + "\1cv8.exe");
	StartupCommand.Add("DESIGNER");
	StartupCommand.Add("/IBConnectionString");
	StartupCommand.Add(ConfigurationPath);
	If Not IsBlankString(User) Then 
		
		StartupCommand.Add("/N");
		StartupCommand.Add(User);
		If Not IsBlankString(Password) Then
			StartupCommand.Add("/P");
			StartupCommand.Add(Password);
		EndIf;
		
	EndIf;
	StartupCommand.Add("/DumpConfigToFiles");
	StartupCommand.Add(WorkingDirectory);
	StartupCommand.Add("/Out");
	StartupCommand.Add(MessagesFileName);
	StartupCommand.Add("/DisableStartupMessages");
	StartupCommand.Add("/DisableStartupDialogs");
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	
	Result = FileSystem.StartApplication(StartupCommand, ApplicationStartupParameters);
	
	//	/DumpConfigFiles <destination dir> [-Module] [-Template] [-Help] [-AllWritable]
	//	- Dump metadata object properties.
	//		<Destination dir> - Directory to dump files to.
	//		Module - Indicates that modules should be dumped.
	//		Template - Indicates that templates should be dumped.
	//		Help - Indicates that help files should be dumped.
	//		AllWritable - Indicates that only write-access objects should be dumped.
	
	If OneCDCopyDirectory <> Undefined Then
		
		Try
			DeleteFiles(OneCDCopyDirectory);
		Except
			// ACC:280 If the directory is being used by another process, it will be automatically deleted later.
		EndTry;
		
	EndIf;
	
	If Result.ReturnCode <> 0 Then
		
		Try
			TextReader = New TextReader(MessagesFileName);
			Messages = TrimAll(TextReader.Read());
			TextReader.Close();
		Except
			Messages = "";
		EndTry;
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось выгрузить конфигурацию в XML (код ошибки ""%1"")';
				|en = 'Cannot export configuration to XML (error code ""%1"")';"),
			Result.ReturnCode);
		
		If Messages <> "" Then
			ErrorText = ErrorText + ":" + StrReplace(Chars.LF + Messages, Chars.LF, Pstab);
		Else
			ErrorText = ErrorText + "."
		EndIf;
		
		Raise ErrorText;
		
	EndIf;
	
	Try
		DeleteFiles(MessagesFileName);
	Except
		// If the file is being used by another process, it will be automatically deleted later.
	EndTry;
	
EndProcedure

&AtServerNoContext
Procedure LoadConfigurationFromXML(WorkingDirectory, User, Password, ChangedFiles)
	
	FileNameChangedFiles = WorkingDirectory + "ChangedFiles.txt";
	TextWriter = New TextWriter(FileNameChangedFiles, TextEncoding.UTF8, , False);
	TextWriter.Write(StrConcat(ChangedFiles, Chars.LF));
	TextWriter.Close();
	TextWriter = Undefined;
	
	ErrorsFileName = WorkingDirectory + "OutUpload.txt";
	
	//	/LoadConfigFromFiles  [-Extension <extension's name>] [-AllExtensions][-files][-listfile][-format]
	//	- Restore the configuration from files. Load of an extension to the main configuration (or the other way around) is not supported.
	//	Valid options are:
	//		 - Directory that contains XML files.
	//		Extension <extension's name> - Extension to be processed.
	//			Returns "0" when the extension is processed.
	//			Returns "1" if the extension is not found or processing failed.
	//		AllExtensions - Indicates that all and only extensions should be restored.
	//			If the extension doesn't exist, it will be created.
	//			The app will try to create the extension in each subdirectory.
	//			When loading the extension to the main configuration (or the other way around), an error is displayed.
	//		files - List of comma-delimited files for restoration.
	//			Not applicable is the "-listfile" option is specified.
	//		listfile - File that lists files for restoration.
	//			Not applicable if the "-files" option is specified. 
	//			The file requirements:
	//			- File encoding is UTF-8.
	//			- Each filename is placed on a separate line.
	//				Supported newline characters:
	//			- \r (new line) and \r (carriage return).
	//		- File must contain empty lines between filenames.
	//			format - The file export format (for partial export).
	//			By default, export runs hierarchically:
	//			Hierarchical - Export considering the file hierarchy.
// Plain - Export files as a plain list.
	
	StartupCommand = New Array;
	StartupCommand.Add(BinDir() + "\1cv8.exe");
	StartupCommand.Add("DESIGNER");
	StartupCommand.Add("/IBConnectionString");
	StartupCommand.Add(InfoBaseConnectionString());
	If Not IsBlankString(User) Then 
		StartupCommand.Add("/N");
		StartupCommand.Add(User);
		StartupCommand.Add("/P");
		StartupCommand.Add(Password);
	EndIf;
	StartupCommand.Add("/LoadConfigFromFiles");
	StartupCommand.Add(WorkingDirectory);
	StartupCommand.Add("-listFile");
	StartupCommand.Add(FileNameChangedFiles);
	StartupCommand.Add("/Out");
	StartupCommand.Add(ErrorsFileName);
	StartupCommand.Add("/DisableStartupMessages");
	StartupCommand.Add("/DisableStartupDialogs");
	
	ManualImportFileAddress = WorkingDirectory + "load.cmd";
	TextWriter = New TextWriter(ManualImportFileAddress, TextEncoding.OEM);
	TextWriter.Write(CommonInternalClientServer.SafeCommandString(StartupCommand));
	TextWriter.Close();
	
	If DesignerIsOpen() Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Конфигурация не загружена, т.к. открыт конфигуратор.
				|Загрузку можно выполнить в конфигураторе из каталога ""%1"" (или запустив файл ""%2"").';
				|en = 'Configuration is not imported as Designer is opened.
				|You can start import in Designer from directory %1 or by running file %2.';"),
			WorkingDirectory,
			ManualImportFileAddress);
		
		Raise MessageText;
		
	EndIf;
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	
	Result = FileSystem.StartApplication(StartupCommand, ApplicationStartupParameters);
	
	If Result.ReturnCode <> 0 Then
		
		If Not FileExists(ErrorsFileName) Then
			ReasonText = "";
		Else
			
			Errors = New TextDocument;
			Errors.Read(ErrorsFileName);
			
			ReasonText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'По причине: %1.';
					|en = 'Reason: %1.';"), Errors.GetText());
			
		EndIf;
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось загрузить XML конфигурации (код ошибки ""%1""). %2';
				|en = 'Cannot import the configuration XML (error code ""%1""). %2';"),
			Result.ReturnCode, ReasonText);
		
		Raise ErrorText;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure AddMetadata(WorkingDirectory, MetadataObject, MetadataKind, LevelToAdd, AdditionLevel)
	
	If MetadataKind = "MetadataObject"
		And MetadataObject.ConfigurationExtension() <> Undefined Then
		Return;
	EndIf;
	
	CurrentLevelString = AdditionLevel.Add();
	CurrentLevelString.Object = ?(MetadataKind = "MetadataObjects_Group", LevelToAdd, MetadataObject.Name);
	CurrentLevelString.MetadataKind = MetadataKind;
	
	LevelElements = CurrentLevelString.GetItems();
	If MetadataKind <> "Form" Then
		
		For Each SubordinateObject In MetadataObject[LevelToAdd] Do
			
			If LevelToAdd = "CommonForms"
				Or LevelToAdd = "Forms" Then
				SubordinateMetadataLevel = Undefined;
				SubordinateMetadataKind = "Form";
			ElsIf LevelToAdd = "MetadataObject" Then
				SubordinateMetadataLevel = "Forms";
				SubordinateMetadataKind = "Form";
			ElsIf LevelToAdd = "Catalogs"
				Or LevelToAdd = "Documents"
				Or LevelToAdd = "DataProcessors"
				Or LevelToAdd = "BusinessProcesses" Then
				SubordinateMetadataLevel = "Forms";
				SubordinateMetadataKind = "MetadataObject";
			EndIf;
			
			AddMetadata(WorkingDirectory, SubordinateObject, SubordinateMetadataKind, SubordinateMetadataLevel, LevelElements);
			
		EndDo;
		
		If LevelElements.Count() = 0 Then
			AdditionLevel.Delete(CurrentLevelString);
		EndIf;
		
	Else
		
		FormDetailsPath = FormDirectory(WorkingDirectory, CurrentLevelString);
		CurrentLevelString.Use = IntegrationRequired(FormDetailsPath);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function DesignerIsOpen()
	
	Sessions = GetInfoBaseSessions();
	For Each Session In Sessions Do
		If Upper(Session.ApplicationName) = "DESIGNER" Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtServerNoContext
Function IntegrationRequired(Path)
	
	DetailsFile = StrReplace(Path + "Form.xml", "\", GetPathSeparator());
	If Not FileExists(DetailsFile) Then
		Raise NStr("ru = 'Выгруженные файлы не соответствуют актуальной конфигурации.';
								|en = 'Exported files do not match the latest configuration.';");
	EndIf;
	
	FormModule = StrReplace(Path + "Form\Module.bsl", "\", GetPathSeparator());
	If Not FileExists(FormModule) Then
		Return 0;
	EndIf;
	
	TextDocument = New TextDocument;
	TextDocument.Read(FormModule);
	
	ModuleText = TextDocument.GetText();
	If StrFind(Lower(ModuleText), Lower("FilesOperations.OnCreateAtServer(")) > 0 Then
		Return 2;
	EndIf;
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(DetailsFile);
	
	DOMBuilder = New DOMBuilder;
	DOMDocument    = DOMBuilder.Read(XMLReader);
	XMLReader.Close();
	
	Dereferencer = New DOMNamespaceResolver(DOMDocument);
	
	Expression             = "/xmlns:Form/xmlns:Attributes/xmlns:Attribute/xmlns:MainAttribute[text()='true']/parent::*/xmlns:Type/v8:Type";
	XPathResult        = DOMDocument.EvaluateXPathExpression(Expression, DOMDocument, Dereferencer);
	MainPropertyType = XPathResult.IterateNext();
	If MainPropertyType = Undefined Then
		Return 0;
	EndIf;
	
	DataType = FromXMLType(New XMLDataType(StrReplace(MainPropertyType.TextContent, "cfg:", ""), ""));
	If DataType = Undefined Then
		Return 0;
	EndIf;
	
	TypeAsString = TypePresentationString(DataType);
	If TypeAsString <> Undefined Then
		
		OwnersTypes = Metadata.DefinedTypes.AttachedFilesOwner.Type.Types();
		If OwnersTypes.Find(Type(TypeAsString)) <> Undefined Then
			Return 1;
		EndIf;
		
	EndIf;
	
	Return 0;
	
EndFunction

&AtServerNoContext
Procedure PlaceFragmentsInSelectedForms(WorkingDirectory, TreeItem, ChangedFilesArray)
	
	For Each BranchItem In TreeItem.GetItems() Do
		
		If BranchItem.MetadataKind = "Form" Then
			If BranchItem.Use = 1 Then
				FormDetailsPath = FormDirectory(WorkingDirectory, BranchItem);
				AddFragmentToForm(FormDetailsPath, ChangedFilesArray, BranchItem.Object);
			EndIf;
		Else
			PlaceFragmentsInSelectedForms(WorkingDirectory, BranchItem, ChangedFilesArray);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Function FormDirectory(WorkingDirectory, TreeRow)
	
	CurrentParent = TreeRow.GetParent();
	If CurrentParent.MetadataKind = "MetadataObjects_Group" Then
		FormDetailsPath = WorkingDirectory + "CommonForms\" + TreeRow.Object + "\Ext\";
	Else
		
		PathPattern = "[ObjectKind]\[ObjectName]\Forms\[FormName]\Ext\";
		
		Parent = CurrentParent.GetParent();
		ParametersStructure = New Structure("ObjectKind");
		If Parent.Object = "Catalogs" Then
			ParametersStructure.ObjectKind = "Catalogs";
		ElsIf Parent.Object = "Documents" Then
			ParametersStructure.ObjectKind = "Documents";
		ElsIf Parent.Object = "DataProcessors" Then
			ParametersStructure.ObjectKind = "DataProcessors";
		ElsIf Parent.Object = "BusinessProcesses" Then
			ParametersStructure.ObjectKind = "BusinessProcesses";
		EndIf;
		
		ParametersStructure.Insert("FormName"  , TreeRow.Object);
		ParametersStructure.Insert("ObjectName", CurrentParent.Object);
		
		FormDetailsPath = WorkingDirectory
				+ StringFunctionsClientServer.InsertParametersIntoString(PathPattern, ParametersStructure);
		
	EndIf;
	
	Return FormDetailsPath;
	
EndFunction

&AtServerNoContext
Procedure AddFragmentToForm(Path, ChangedFilesArray, FormName)
	
	Separator  = GetPathSeparator();
	DetailsFile = StrReplace(Path + "Form.xml", "\", Separator);
	If Not FileExists(DetailsFile) Then
		Return;
	EndIf;
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(DetailsFile);
	
	DOMBuilder = New DOMBuilder;
	DOMDocument    = DOMBuilder.Read(XMLReader);
	XMLReader.Close();
	
	Dereferencer = New DOMNamespaceResolver(DOMDocument);
	
	Expression             = "/xmlns:Form/xmlns:Attributes/xmlns:Attribute/xmlns:MainAttribute[text()='true']/parent::*/xmlns:Type/v8:Type";
	XPathResult        = DOMDocument.EvaluateXPathExpression(Expression, DOMDocument, Dereferencer);
	MainPropertyType = XPathResult.IterateNext();
	If MainPropertyType <> Undefined Then
	
		DataType = FromXMLType(New XMLDataType(StrReplace(MainPropertyType.TextContent, "cfg:", ""), ""));
		If DataType <> Undefined Then
			
			TypeAsString = TypePresentationString(DataType);
			If TypeAsString <> Undefined Then
				
				OwnersTypes = Metadata.DefinedTypes.AttachedFilesOwner.Type.Types();
				If OwnersTypes.Find(Type(TypeAsString)) <> Undefined Then
					ExcludeCommonCommand(DOMDocument);
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	AttachFormEvents(DOMDocument);
	
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(DetailsFile);
	
	DOMWriter = New DOMWriter;
	DOMWriter.Write(DOMDocument, XMLWriter);
	
	ModuleFile = StrReplace(Path + "Form\Module.bsl", "\", Separator);
	TextDocument = New TextDocument;
	If Not FileExists(ModuleFile) Then
		ModuleText = "";
		CreateDirectory(StrReplace(Path + "Form", "\", Separator));
	Else
		TextDocument.Read(ModuleFile);
		ModuleText = TextDocument.GetText();
	EndIf;
	
	StandardProcedureProcessing(ModuleText, "Procedure OnCreateAtServer");
	StandardProcedureProcessing(ModuleText, "Procedure OnOpen");
	StandardProcedureProcessing(ModuleText, "Procedure NotificationProcessing");
	StandardProcedureProcessing(ModuleText, "Procedure Attachable_PreviewFieldClick");
	StandardProcedureProcessing(ModuleText, "Procedure Attachable_PreviewFieldCheckDragging");
	StandardProcedureProcessing(ModuleText, "Procedure Attachable_PreviewFieldDrag");
	StandardProcedureProcessing(ModuleText, "Procedure Attachable_AttachedFilesPanelCommand");
	
	MethodTextClick        = MethodText(ModuleText, "Procedure Attachable_PreviewFieldClick");
	CheckMethodText       = MethodText(ModuleText, "Procedure Attachable_PreviewFieldCheckDragging");
	MethodTextDrag = MethodText(ModuleText, "Procedure Attachable_PreviewFieldDrag");
	
	MethodStartClick        = StrFind(ModuleText, MethodTextClick);
	CheckMethodStart       = StrFind(ModuleText, CheckMethodText);
	MethodStartDrag = StrFind(ModuleText, MethodTextDrag);
	
	If MethodStartClick < CheckMethodStart Then
		If MethodStartDrag < MethodStartClick Then
			MethodText = MethodTextDrag;
		Else
			MethodText = MethodTextClick;
		EndIf;
	Else
		If MethodStartDrag < CheckMethodStart Then
			MethodText = MethodTextDrag;
		Else
			MethodText = CheckMethodText;
		EndIf;
	EndIf;
	
	ArrangeComments(ModuleText, MethodText, True, False);
	
	If MethodStartClick > CheckMethodStart Then
		If MethodStartDrag > MethodStartClick Then
			MethodText = MethodTextDrag;
		Else
			MethodText = MethodTextClick;
		EndIf;
	Else
		If MethodStartDrag > CheckMethodStart Then
			MethodText = MethodTextDrag;
		Else
			MethodText = CheckMethodText;
		EndIf;
	EndIf;
	
	ArrangeComments(ModuleText, MethodText, False, True);
	
	MethodText = MethodText(ModuleText, "Procedure Attachable_AttachedFilesPanelCommand");
	ArrangeComments(ModuleText, MethodText);
	
	TextDocument.SetText(ModuleText);
	TextDocument.Write(ModuleFile);
	
	RootItem = StrReplace(Path, Separator + "Ext" + Separator, ".xml");
	ChangedFilesArray.Add(RootItem);
	
EndProcedure

&AtServerNoContext
Procedure AttachFormEvents(DOMDocument)
	
	Dereferencer = New DOMNamespaceResolver(DOMDocument);
	
	Result = DOMDocument.EvaluateXPathExpression("/xmlns:Form", DOMDocument, Dereferencer);
	FormNode = Result.IterateNext();
	
	Result = DOMDocument.EvaluateXPathExpression("/xmlns:Form/xmlns:Events", DOMDocument, Dereferencer);
	EventsNode = Result.IterateNext();
	If EventsNode = Undefined Then
		EventsNode = FormNode.AppendChild(DOMDocument.CreateElement("Events"));
	EndIf;
	
	AddEvent(DOMDocument, Dereferencer, EventsNode, "OnCreateAtServer", "OnCreateAtServer");
	AddEvent(DOMDocument, Dereferencer, EventsNode, "OnOpen", "OnOpen");
	AddEvent(DOMDocument, Dereferencer, EventsNode, "NotificationProcessing", "NotificationProcessing");
	
EndProcedure

&AtServerNoContext
Procedure AddEvent(DOMDocument, Dereferencer, EventsNode, EventName, ProcedureName)

	Expression = "/xmlns:Form/xmlns:Events/xmlns:Event[@name='" + EventName + "']";
	Result = DOMDocument.EvaluateXPathExpression(Expression, DOMDocument, Dereferencer);
	EventNode1 = Result.IterateNext();
	If EventNode1 = Undefined Then
		EventNode1 = DOMDocument.CreateElement("Event");
		EventNode1.SetAttribute("name", EventName);
		EventNode1.AppendChild(DOMDocument.CreateTextNode(ProcedureName));
		EventsNode.AppendChild(EventNode1);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure ExcludeCommonCommand(DOMDocument)
	
	Dereferencer = New DOMNamespaceResolver(DOMDocument);
	
	Result = DOMDocument.EvaluateXPathExpression("/xmlns:Form", DOMDocument, Dereferencer);
	FormNode = Result.IterateNext();
	
	Result = DOMDocument.EvaluateXPathExpression("/xmlns:Form/xmlns:CommandInterface", DOMDocument, Dereferencer);
	APINode = Result.IterateNext();
	If APINode = Undefined Then
		APINode = FormNode.AppendChild(DOMDocument.CreateElement("CommandInterface"));
	EndIf;
	
	ExpressionNavigationPanel = "/xmlns:Form/xmlns:CommandInterface/xmlns:NavigationPanel";
	Result = DOMDocument.EvaluateXPathExpression(ExpressionNavigationPanel, DOMDocument, Dereferencer);
	NodeNavigationPanel = Result.IterateNext();
	If NodeNavigationPanel = Undefined Then
		NodeNavigationPanel = APINode.AppendChild(DOMDocument.CreateElement("NavigationPanel"));
	EndIf;
	
	CommandExpression = "/xmlns:Form/xmlns:CommandInterface/xmlns:NavigationPanel/xmlns:Item/xmlns:Command[text()='CommonCommand.AttachedFiles']/parent::*";
	Result        = DOMDocument.EvaluateXPathExpression(CommandExpression, DOMDocument, Dereferencer);
	CommandNode      = Result.IterateNext();
	If CommandNode = Undefined Then
		
		CommandNode = NodeNavigationPanel.AppendChild(DOMDocument.CreateElement("Item"));
		AddNodeProperty(DOMDocument, CommandNode, "Command", "CommonCommand.AttachedFiles");
		AddNodeProperty(DOMDocument, CommandNode, "Type", "Auto");
		AddNodeProperty(DOMDocument, CommandNode, "CommandGroup", "FormNavigationPanelGoTo");
		AddNodeProperty(DOMDocument, CommandNode, "DefaultVisible", "false");
		
		PropertyNode1 = CommandNode.AppendChild(DOMDocument.CreateElement("Visible"));
		AddNodeProperty(DOMDocument, PropertyNode1, "xr:Common", "false");
		
	Else
		
		Result = DOMDocument.EvaluateXPathExpression(CommandExpression + "/xmlns:DefaultVisible", DOMDocument, Dereferencer);
		PropertyNode1 = Result.IterateNext();
		If PropertyNode1 <> Undefined Then
			CommandNode.RemoveChild(PropertyNode1);
		EndIf;
		
		AddNodeProperty(DOMDocument, CommandNode, "DefaultVisible", "false");
		
		CommandExpression = CommandExpression + "/xmlns:Visible";
		Result = DOMDocument.EvaluateXPathExpression(CommandExpression, DOMDocument, Dereferencer);
		PropertyNode1 = Result.IterateNext();
		If PropertyNode1 <> Undefined Then
			CommandNode.RemoveChild(PropertyNode1);
		EndIf;
		
		PropertyNode1 = CommandNode.AppendChild(DOMDocument.CreateElement("Visible"));
		AddNodeProperty(DOMDocument, PropertyNode1, "xr:Common", "false");
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure AddNodeProperty(DOMDocument, Node, PropertyName, Value)
	
	PropertyNode1 = Node.AppendChild(DOMDocument.CreateElement(PropertyName));
	PropertyNode1.AppendChild(DOMDocument.CreateTextNode(Value));
	
EndProcedure

&AtServerNoContext
Function TypePresentationString(DataType)
	
	TypeAsString = "";
	MetadataObject = Metadata.FindByType(DataType);
	If Metadata.Catalogs.Contains(MetadataObject) Then
		TypeAsString = "CatalogRef";
	ElsIf Metadata.Documents.Contains(MetadataObject) Then
		TypeAsString = "DocumentRef";
	ElsIf Metadata.BusinessProcesses.Contains(MetadataObject) Then
		TypeAsString = "BusinessProcessRef";
	ElsIf Metadata.Tasks.Contains(MetadataObject) Then
		TypeAsString = "TaskRef";
	Else
		Return Undefined;
	EndIf;
	
	Return TypeAsString + "." + MetadataObject.Name;
	
EndFunction

&AtClientAtServerNoContext
Function FileExists(FullFileName)
	
	// CAC:566-off data processor runs only synchronously.
	File = New File(FullFileName);
	Return File.Exists();
	// ACC:566-on
	
EndFunction

&AtClientAtServerNoContext
Function AddLastPathSeparator(Val DirectoryPath)
	
	If IsBlankString(DirectoryPath) Then
		Return DirectoryPath;
	EndIf;
	
	CharToAdd = GetPathSeparator();
	
	If StrEndsWith(DirectoryPath, CharToAdd) Then
		Return DirectoryPath;
	Else
		Return DirectoryPath + CharToAdd;
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function WorkingDirectory(Form)
	
	If ValueIsFilled(Form.WorkingDirectory) Then
		Return Form.WorkingDirectory;
	ElsIf StrStartsWith(Form.Items.WorkingDirectory.InputHint, "<") Then
		Return "";
	Else
		Return Form.Items.WorkingDirectory.InputHint;
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function AreaText(ModuleText, AreaName)
	
	FullAreaName = "#area " + Lower(AreaName);
	
	AreaStart = StrFind(Lower(ModuleText), FullAreaName);
	If AreaStart > 0 Then
		
		AreaText = Mid(ModuleText, AreaStart);
		SearchText = Mid(AreaText, 3);
		
		AreasStack = New Array;
		AreasStack.Add("AreaStart");
		While AreasStack.Count() > 0 Do
			
			EndRegion = StrFind(Lower(SearchText), Lower("#EndRegion"));
			NextAreaStart = StrFind(Lower(SearchText), Lower("#Area"));
			If NextAreaStart = 0 Then
				NextAreaStart = StrLen(SearchText);
			EndIf;
			
			If NextAreaStart < EndRegion Then
				
				AreasStack.Insert(0, "AreaStart");
				SearchText = Mid(SearchText, NextAreaStart + 3);
				
			Else
				
				AreasStack.Delete(0);
				SearchText = Mid(SearchText, EndRegion + 3);
				
			EndIf;
			
		EndDo;
		
		AreaText = Left(AreaText, StrLen(AreaText) - StrLen(SearchText) 
			+ StrLen("#EndRegion") - 3);
		
	Else
		AreaText = AddArea(ModuleText, AreaName);
	EndIf;
	
	Return AreaText;
	
EndFunction

&AtClientAtServerNoContext
Function AddArea(ModuleText, AreaName)
	
	AreaText = "#Area " + AreaName + "
			|
			|#EndRegion";
	
	If AreaName = "FormEventHandlers" Then
		ModuleText = AreaText + Chars.LF
				+ Chars.LF + ModuleText;
	Else
		ModuleText = ModuleText + Chars.LF
				+ Chars.LF + AreaText;
	EndIf;
	
	Return AreaText;
	
EndFunction

&AtClientAtServerNoContext
Function MethodText(SearchAreaText, Title)
	
	MethodText   = "";
	MethodNameLower = Lower(Title) + "(";
	MethodStart  = StrFind(Lower(SearchAreaText), MethodNameLower);
	If MethodStart > 0 Then
		
		MethodText        = Mid(SearchAreaText, MethodStart);
		ProcedureEnd = StrFind(Lower(MethodText), ?(StrStartsWith(MethodNameLower, "procedure"), Lower("EndProcedure"), Lower("EndFunction")));
		MethodText        = Left(MethodText, ProcedureEnd + ?(StrStartsWith(MethodNameLower, "procedure"), 
			StrLen("EndProcedure") -1, StrLen("EndFunction") - 1));
	
	EndIf;
	
	Return MethodText;
	
EndFunction

&AtClientAtServerNoContext
Function AddMethodToArea(AreaText, AreaName, Title, Parameters, Dir, ToBeginning)
	
	MethodText = Title + Parameters + "
					|
					|" + ?(StrStartsWith(Title, "Procedure"), "EndProcedure", "EndFunction");
	
	AdditionText = Dir + "
					|" + MethodText;
	
	If ToBeginning Then
		
		AreaStart  = Left(AreaText, StrLen(AreaName) + StrLen("#Area") + 1); // Include a whitespace. 
		ReplacementText_1 = AreaStart + Chars.LF + Chars.LF + AdditionText;
		AreaText   = ReplacementText_1 + Right(AreaText, StrLen(AreaText) - StrLen(AreaStart));
		
	Else
		
		EndOfRegion = Right(AreaText, StrLen("#EndRegion"));
		ReplacementText_1   = AdditionText + Chars.LF + Chars.LF + EndOfRegion;
		AreaText     = Left(AreaText, StrLen(AreaText) - StrLen("#EndRegion")) + ReplacementText_1;
		
	EndIf;
	
	Return MethodText;
	
EndFunction

&AtClientAtServerNoContext
Function ApendMethod(MethodText, InsertText1)
	
	If StrEndsWith(MethodText, ";") Then
		MethodText = Left(MethodText, StrLen(MethodText - 1));
	EndIf;
	
	MethodEnd = Right(MethodText, ?(StrEndsWith(Lower(MethodText), Lower("EndProcedure")), 
		StrLen("EndProcedure"), StrLen("EndFunction")));
	Return StrReplace(MethodText, MethodEnd, InsertText1 + Chars.LF + Chars.LF + MethodEnd);
	
EndFunction

&AtClientAtServerNoContext
Procedure StandardProcedureProcessing(ModuleText, MethodTitle)
	
	Dir        = "&AtClient";
	ClearMethod     = False;
	AddToTop = False;
	If MethodTitle = "Procedure OnCreateAtServer" Then
		
		Dir               = "&AtServer";
		AreaName              = "FormEventHandlers";
		AddToTop        = True;
		MethodParameters         = "(Cancel, StandardProcessing)";
		StandardInsertText = "	// StandardSubsystems.FilesOperations
				|	FilesHyperlink = FilesOperations.FilesHyperlink();
				|	FilesHyperlink.Location = ""CommandBar"";
				|	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
				|	// End StandardSubsystems.FilesOperations";
	
	ElsIf MethodTitle = "Procedure OnOpen" Then
		
		AreaName              = "FormEventHandlers";
		MethodParameters         = "(Cancel)";
		StandardInsertText = "	// StandardSubsystems.FilesOperations
				|	FilesOperationsClient.OnOpen(ThisObject, Cancel);
				|	// End StandardSubsystems.FilesOperations";
		
	ElsIf MethodTitle = "Procedure NotificationProcessing" Then
		
		AreaName              = "FormEventHandlers";
		MethodParameters         = "(EventName, Parameter, Source)";
		StandardInsertText = "	// StandardSubsystems.FilesOperations
				|	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
				|	// End StandardSubsystems.FilesOperations";
		
	ElsIf MethodTitle = "Procedure Attachable_PreviewFieldClick" Then
		
		AreaName              = "FormHeaderItemsEventHandlers";
		ClearMethod            = True;
		MethodParameters         = "(Item, StandardProcessing)";
		StandardInsertText = "	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);";
		
	ElsIf MethodTitle = "Procedure Attachable_PreviewFieldCheckDragging" Then
		
		AreaName              = "FormHeaderItemsEventHandlers";
		ClearMethod            = True;
		MethodParameters         = "(Item, DragParameters, StandardProcessing)";
		StandardInsertText = "	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				|				DragParameters, StandardProcessing);";
		
	ElsIf MethodTitle = "Procedure Attachable_PreviewFieldDrag" Then
		
		AreaName              = "FormHeaderItemsEventHandlers";
		ClearMethod            = True;
		MethodParameters         = "(Item, DragParameters, StandardProcessing)";
		StandardInsertText = "	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				|				DragParameters, StandardProcessing);";
		
	ElsIf MethodTitle = "Procedure Attachable_AttachedFilesPanelCommand" Then
		
		AreaName              = "FormCommandsEventHandlers";
		ClearMethod            = True;
		MethodParameters         = "(Command)";
		StandardInsertText = "	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);";
		
	EndIf;
	
	AreaText = "";
	MethodText = MethodText(ModuleText, MethodTitle);
	If IsBlankString(MethodText) Then
		
		AreaText = AreaText(ModuleText, AreaName);
		ReplacementText  = AreaText;
		MethodText  = AddMethodToArea(ReplacementText, AreaName,
				MethodTitle, MethodParameters, Dir, AddToTop);
		ModuleText  = StrReplace(ModuleText, AreaText, ReplacementText);
		AreaText = ReplacementText;
		
	EndIf;
	
	InsertStart = StrFind(Lower(MethodText), Lower("// StandardSubsystems.FilesOperations"));
	If InsertStart = 0 Then
		CurrentInsertText = "";
	Else
		
		If Mid(MethodText, InsertStart - 1, 1) = Chars.Tab Then
			InsertStart = InsertStart - 1;
		EndIf;
		
		InsertText1             = Mid(MethodText, InsertStart);
		InsertEndText    = Lower("// End StandardSubsystems.FilesOperations");
		InsertEnd         = StrFind(Lower(InsertText1), InsertEndText);
		CurrentInsertText = Left(InsertText1, InsertEnd - 1 + StrLen(InsertEndText));
		
	EndIf;
	
	MethodText = MethodText(ModuleText, MethodTitle);
	ReplacementText_1 = MethodText;
	If Not IsBlankString(CurrentInsertText) Then
		ReplacementText_1 = StrReplace(ReplacementText_1, CurrentInsertText, StandardInsertText);
	Else
		
		If ClearMethod Then
			
			ReplacementText_1 = MethodTitle + MethodParameters + "
						|
						|" + ?(StrStartsWith(MethodTitle, "Procedure"), "EndProcedure", "EndFunction");
			
		EndIf;
		
		ReplacementText_1 = ApendMethod(ReplacementText_1, StandardInsertText);
		
	EndIf;
	
	If Not IsBlankString(AreaText) Then
		CurrentAreaText = StrReplace(AreaText, MethodText, ReplacementText_1);
		ModuleText         = StrReplace(ModuleText, AreaText, CurrentAreaText);
	Else
		ModuleText = StrReplace(ModuleText, MethodText, ReplacementText_1);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ArrangeComments(ModuleText, MethodText, BOF = True, EOF = True)
	
	If BOF Then
		
		MethodStart = StrFind(ModuleText, MethodText);
		TextBeforeMethod = Left(ModuleText, MethodStart - 1);
		TextWithComment = MethodText;
		If StrEndsWith(TrimAll(Lower(TextBeforeMethod)), Lower("&AtClient")) Then
			
			TextWithComment = "&AtClient
					|" + TextWithComment;
			
			MethodText = "&AtClient
					|" + MethodText;
			
			TextBeforeMethod = Left(TextBeforeMethod, StrLen(TextBeforeMethod) - 11);
			
		EndIf;
		
		If Not StrEndsWith(TrimAll(Lower(TextBeforeMethod)), Lower(".FilesOperations")) Then
			TextWithComment = "// StandardSubsystems.FilesOperations
					|" + TextWithComment;
		EndIf;
		
		ModuleText = StrReplace(ModuleText, MethodText, TextWithComment);
		
	EndIf;
	
	If EOF Then
		
		MethodStart = StrFind(ModuleText, MethodText);
		TextWithComment = MethodText;
		TextAfterMethod = Right(ModuleText, StrLen(ModuleText) - MethodStart - StrLen(TextWithComment));
		If Not StrStartsWith(TrimAll(Lower(TextAfterMethod)), Lower("// End StandardSubsystems.FilesOperations")) Then
			
			TextWithComment = TextWithComment + "
					|// End StandardSubsystems.FilesOperations";
			
		EndIf;
		
		ModuleText = StrReplace(ModuleText, MethodText, TextWithComment);
		
	EndIf;
	
EndProcedure

#EndRegion