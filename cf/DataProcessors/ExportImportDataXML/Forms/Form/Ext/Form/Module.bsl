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
	
	CheckPlatformVersionAndCompatibilityMode();
	
	OperatingModeAtClient = (OperatingModeAtClientOrAtServer = 0);
	
	Items.UploadFileName.Enabled = Not OperatingModeAtClient;
	Items.ImportFileName.Enabled = Not OperatingModeAtClient;
	
	ObjectAtServer = FormAttributeToValue("Object");
	ObjectAtServer.Initialize();
	ValueToFormAttribute(ObjectAtServer.MetadataTree, "Object.MetadataTree");
	
	File = New File(UploadFileName);
	Object.UseFastInfoSetFormat = (File.Extension = ".fi");
	
	ExportMode = (Items.GroupMode.CurrentPage = Items.GroupMode.ChildItems.XMLExportGroup);
	QueryConsoleUsageOption = "Built_In";
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	OperatingModeAtClient = (OperatingModeAtClientOrAtServer = 0);
	
	Items.UploadFileName.Enabled = Not OperatingModeAtClient;
	Items.ImportFileName.Enabled = Not OperatingModeAtClient;
	
	File = New File(UploadFileName);
	Object.UseFastInfoSetFormat = (File.Extension = ".fi");
	
	ExportMode = (Items.GroupMode.CurrentPage = Items.GroupMode.ChildItems.XMLExportGroup);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	ProcessingSelectionOnServer(ValueSelected);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UploadFileNameOnChange(Item)
	
	File = New File(UploadFileName);
	Object.UseFastInfoSetFormat = (File.Extension = ".fi");
	
EndProcedure

&AtClient
Procedure UploadFileNameOpening(Item, StandardProcessing)
	
	OpenInApplication(Item, "UploadFileName", StandardProcessing);
	
EndProcedure

&AtClient
Procedure UploadFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	ProcessFileChoiceStart(StandardProcessing);
	
EndProcedure

&AtClient
Procedure UseFastInfoSetFormatOnChange(Item)
	
	If Object.UseFastInfoSetFormat Then
		UploadFileName = StrReplace(UploadFileName, ".xml", ".fi");
	Else
		UploadFileName = StrReplace(UploadFileName, ".fi", ".xml");
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupModeOnCurrentPageChange(Item, CurrentPage)
	
	ExportMode = (Items.GroupMode.CurrentPage = Items.GroupMode.ChildItems.XMLExportGroup);
	
EndProcedure

&AtClient
Procedure AdditionalObjectsToExportOnChange(Item)
	
	If Item.CurrentData <> Undefined And ValueIsFilled(Item.CurrentData.Object) Then
		
		Item.CurrentData.ObjectForQueryName = ObjectNameByTypeForQuery(Item.CurrentData.Object);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportFileNameOpening(Item, StandardProcessing)
	
	OpenInApplication(Item, "ImportFileName", StandardProcessing);
	
EndProcedure

&AtClient
Procedure ImportFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	ProcessFileChoiceStart(StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMetadataTree

&AtClient
Procedure MetadataTreeExportOnChange(Item)
	
	CurrentData = Items.MetadataTree.CurrentData;
	
	If CurrentData.Export = 2 Then
		CurrentData.Export = 0;
	EndIf;
	
	SetSubordinateMarks(CurrentData, "Export");
	SetParentMarks(CurrentData, "Export");
	
EndProcedure

&AtClient
Procedure MetadataTreeExportIfNecessaryOnChange(Item)
	
	CurrentData = Items.MetadataTree.CurrentData;
	
	If CurrentData.ExportIfNecessary = 2 Then
		CurrentData.ExportIfNecessary = 0;
	EndIf;
	
	SetSubordinateMarks(CurrentData, "ExportIfNecessary");
	SetParentMarks(CurrentData, "ExportIfNecessary");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAdditionalObjectsToExport

&AtClient
Procedure AdditionalObjectsToExportBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Item.CurrentItem.TypeRestriction = ObjectsTypeToExport;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddFromQuery(Command)
	
	OpenForm(QueriesConsoleFormName(),QueriesConsoleParameters(),ThisObject);
	
EndProcedure

&AtClient
Procedure ClearAdditionalObjectsToExport(Command)
	
	Object.AdditionalObjectsToExport.Clear();
	
EndProcedure

&AtClient
Procedure ExportData(Command)
	
	Object.StartDate = ExportPeriod.StartDate;
	Object.EndDate = ExportPeriod.EndDate;
	
	ClearMessages();
	
	If Not OperatingModeAtClient Then
		
		If IsBlankString(UploadFileName) Then
			
			MessageText = NStr("ru = 'Поле ""Имя файла"" не заполнено';
									|en = 'The ""File name"" field not filled in';");
			MessageToUser(MessageText, "UploadFileName");
			Return;
			
		EndIf;
		
	EndIf;
	
	FileAddressInTempStorage = "";
	ExportDataAtServer(FileAddressInTempStorage);
	
	If OperatingModeAtClient And Not IsBlankString(FileAddressInTempStorage) Then
		
		FileName = ?(Object.UseFastInfoSetFormat, NStr("ru = 'Файл выгрузки.fi';
																|en = 'Export file.fi';"), NStr("ru = 'Файл выгрузки.xml';
																								|en = 'Export file.xml';"));
		GetFile(FileAddressInTempStorage, FileName);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportData(Command)
	
	ClearMessages();
	FileAddressInTempStorage = "";
	
	If OperatingModeAtClient Then
		
		NotifyDescription = New NotifyDescription("ImportDataCompletion", ThisObject);
		BeginPutFile(NotifyDescription, FileAddressInTempStorage, , , UUID);
		
	Else
		
		If IsBlankString(ImportFileName) Then
			
			MessageText = NStr("ru = 'Поле ""Имя файла"" не заполнено';
									|en = 'The ""File name"" field not filled in';");
			MessageToUser(MessageText, "ImportFileName");
			Return;
			
		EndIf;
		
		File = New File(ImportFileName);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("FileAddressInTempStorage", FileAddressInTempStorage);
		AdditionalParameters.Insert("FileExtention" ,               File.Extension);
		
		Notification = New NotifyDescription("CheckIfEndFileExistsCompletion", ThisObject, AdditionalParameters);
		File.BeginCheckingExistence(Notification);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QueryConsoleSettings(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("QueryConsoleUsageOption", QueryConsoleUsageOption);
	FormParameters.Insert("PathToExternalQueryConsole", PathToExternalQueryConsole);
	
	NotificationAboutSettingsClosing = New NotifyDescription("QueryConsoleSettingsFormClosed", ThisObject);
	OpenForm(QueriesConsoleSettingsFormName(), FormParameters, ThisObject,,,,
		NotificationAboutSettingsClosing,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure RecalculateDataToExportByRef(Command)
	
	SaveTreeView(Object.MetadataTree.GetItems());
	RecalculateDataToExportByRefAtServer();
	RestoreTreeDisplay(Object.MetadataTree.GetItems());
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CheckIfEndFileExistsCompletion(Exists, AdditionalParameters) Export
	
	If Not Exists Then
		MessageToUser(NStr("ru = 'Файл не существует';
									|en = 'File does not exist';"), "ImportFileName");
		Return;
	EndIf;
	
	ImportDataAtServer(AdditionalParameters.FileAddressInTempStorage,
		AdditionalParameters.FileExtention);
	
EndProcedure

&AtServer
Function QueriesConsoleFormName()
	
	If QueryConsoleUsageOption = "Built_In" Then
		
		DataProcessor = FormAttributeToValue("Object");
		FormIdentifier = ".Form.SelectFromQuery";
		
	Else //QueriesConsoleUsageOption = External
		
		DataProcessor = ExternalDataProcessors.Create(PathToExternalQueryConsole);
		FormIdentifier = ".ObjectForm";
		
	EndIf;
	
	Return DataProcessor.Metadata().FullName() + FormIdentifier;
	
EndFunction

&AtServer
Function QueriesConsoleSettingsFormName()
	
	DataProcessor = FormAttributeToValue("Object");
	SettingsFormName = DataProcessor.Metadata().FullName() + ".Form.QueryConsoleSettings";
	
	Return SettingsFormName;
	
EndFunction

&AtClient
Function QueriesConsoleParameters()
	
	FormParameters = New Structure;
	
	If QueryConsoleUsageOption = "Outer" Then
		
		FormParameters.Insert("QueryConsoleUsageOption", QueryConsoleUsageOption);
		FormParameters.Insert("PathToExternalQueryConsole", PathToExternalQueryConsole);
		
	Else
		
		FormParameters.Insert("Title", NStr("ru = 'Выбор данных для выгрузки';
													|en = 'Select data for export';"));
		FormParameters.Insert("ChoiceMode", True);
		FormParameters.Insert("CloseOnChoice", False);
		
	EndIf;
	
	Return FormParameters;
	
EndFunction

&AtClient
Procedure QueryConsoleSettingsFormClosed(ClosingResult, AdditionalParameters) Export
	If TypeOf(ClosingResult) <> Type("Structure") Then
		Return;
	EndIf;
	FillPropertyValues(ThisObject, ClosingResult);
EndProcedure

&AtClient
Procedure OpenInApplication(Item, DataPath, StandardProcessing)
	
	StandardProcessing = False;
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("FileName", Item.EditText);
	AdditionalParameters.Insert("NotifyDescription", New NotifyDescription);
	AdditionalParameters.Insert("DataPath", DataPath);
	
	File = New File(Item.EditText);
	
	NotifyDescription = New NotifyDescription("AfterDetermineFileExistence", ThisObject, AdditionalParameters);
	File.BeginCheckingExistence(NotifyDescription);
	
EndProcedure

// Continuation of the procedure (see above).
&AtClient
Procedure AfterDetermineFileExistence(Exists, AdditionalParameters) Export
	
	If Exists Then
		BeginRunningApplication(AdditionalParameters.NotifyDescription, AdditionalParameters.FileName);
	Else
		WarningText = NStr("ru = 'Файл ""%1"" не существует или к нему нет доступа.';
									|en = 'The %1 file is inaccessible or does not exist.';");
		WarningText = StrReplace(WarningText, "%1", AdditionalParameters.DataPath);
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangeRunMode()
	
	OperatingModeAtClient = (OperatingModeAtClientOrAtServer = 0);
	
	Items.UploadFileName.Enabled = Not OperatingModeAtClient;
	Items.ImportFileName.Enabled = Not OperatingModeAtClient;
	
EndProcedure

&AtClientAtServerNoContext
Procedure MessageToUser(Text, DataPath = "")
	
	Message = New UserMessage;
	Message.Text = Text;
	Message.DataPath = DataPath;
	Message.Message();
	
EndProcedure

&AtClient
Procedure ProcessFileChoiceStart(StandardProcessing)
	
	StandardProcessing = False;
	DialogMode = ?(ExportMode, FileDialogMode.Save, FileDialogMode.Open);
	FileDialog = New FileDialog(DialogMode);
	FileDialog.CheckFileExist = Not ExportMode;
	FileDialog.Multiselect = False;
	FileDialog.Title = NStr("ru = 'Задайте имя файла выгрузки';
										|en = 'Specify export file name';");
	FileDialog.FullFileName = ?(ExportMode, UploadFileName, ImportFileName);
	
	FileDialog.Filter = "Format exports(*.xml)|*.xml|FastInfoSet (*.fi)|*.fi|All files (*.*)|*.*";
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("PropertyName", ?(ExportMode, "UploadFileName", "ImportFileName"));
	
	Notification = New NotifyDescription("FileChoiceStartChoiceProcessing", ThisObject, AdditionalParameters);
	FileDialog.Show(Notification);
	
EndProcedure

&AtClient
Procedure FileChoiceStartChoiceProcessing(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	ThisObject[AdditionalParameters.PropertyName] = SelectedFiles[0];
	
EndProcedure

&AtClient
Procedure SetSubordinateMarks(CurRow, CheckBoxName)
	
	SubordinateItems = CurRow.GetItems();
	
	If SubordinateItems.Count() = 0 Then
		Return;
	EndIf;
	
	For Each String In SubordinateItems Do
		
		String[CheckBoxName] = CurRow[CheckBoxName];
		
		SetSubordinateMarks(String, CheckBoxName);
		
	EndDo;
		
EndProcedure

&AtClient
Procedure SetParentMarks(CurRow, CheckBoxName)
	
	Parent = CurRow.GetParent();
	If Parent = Undefined Then
		Return;
	EndIf; 
	
	CurState = Parent[CheckBoxName];
	
	EnabledItemsFound  = False;
	DisabledItemsFound = False;
	
	For Each String In Parent.GetItems() Do
		If String[CheckBoxName] = 0 Then
			DisabledItemsFound = True;
		ElsIf String[CheckBoxName] = 1
			Or String[CheckBoxName] = 2 Then
			EnabledItemsFound  = True;
		EndIf; 
		If EnabledItemsFound And DisabledItemsFound Then
			Break;
		EndIf; 
	EndDo;
	
	If EnabledItemsFound And DisabledItemsFound Then
		Enable = 2;
	ElsIf EnabledItemsFound And (Not DisabledItemsFound) Then
		Enable = 1;
	ElsIf (Not EnabledItemsFound) And DisabledItemsFound Then
		Enable = 0;
	ElsIf (Not EnabledItemsFound) And (Not DisabledItemsFound) Then
		Enable = 2;
	EndIf;
	
	If Enable = CurState Then
		Return;
	Else
		Parent[CheckBoxName] = Enable;
		SetParentMarks(Parent, CheckBoxName);
	EndIf; 
	
EndProcedure

&AtServer
Procedure ExportDataAtServer(FileAddressInTempStorage)
	
	If OperatingModeAtClient Then
		
		Extension = ?(Object.UseFastInfoSetFormat, ".fi", ".xml");
		TempFileName = GetTempFileName(Extension);
		
	Else
		
		TempFileName = UploadFileName;
		
	EndIf;
	
	ObjectAtServer = FormAttributeToValue("Object");
	FillMetadataTreeAtServer(ObjectAtServer);
	
	ObjectAtServer.ExecuteExport(TempFileName);
	
	If OperatingModeAtClient Then
		
		File = New File(TempFileName);
		
		If File.Exists() Then
			
			BinaryData = New BinaryData(TempFileName);
			FileAddressInTempStorage = PutToTempStorage(BinaryData, UUID);
			DeleteFiles(TempFileName);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetMarksOfDataToExport(SourceTreeRows, TreeToReplaceRows)
	
	ColumnExport = TreeToReplaceRows.UnloadColumn("Export");
	SourceTreeRows.LoadColumn(ColumnExport, "Export");
	
	ColumnExportIfNecessary = TreeToReplaceRows.UnloadColumn("ExportIfNecessary");
	SourceTreeRows.LoadColumn(ColumnExportIfNecessary, "ExportIfNecessary");
	
	ColumnExpanded = TreeToReplaceRows.UnloadColumn("Expanded");
	SourceTreeRows.LoadColumn(ColumnExpanded, "Expanded");
	
	For Each SourceTreeRow1 In SourceTreeRows Do
		
		RowIndex = SourceTreeRows.IndexOf(SourceTreeRow1);
		TreeToChangeRow = TreeToReplaceRows.Get(RowIndex);
		
		SetMarksOfDataToExport(SourceTreeRow1.Rows, TreeToChangeRow.Rows);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ImportDataCompletion(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If Result Then
		
		File = New File(SelectedFileName);
		ImportDataAtServer(Address, File.Extension);
	
	EndIf;
	
EndProcedure

&AtServer
Procedure ImportDataAtServer(FileAddressInTempStorage, Extension)
	
	If OperatingModeAtClient Then
		
		BinaryData = GetFromTempStorage(FileAddressInTempStorage); // BinaryData
		TempFileName = GetTempFileName(Extension);
		BinaryData.Write(TempFileName);
		
	Else
		
		TempFileName = ImportFileName;
		
	EndIf;
	
	FormAttributeToValue("Object").ExecuteImport(TempFileName);
	
	If OperatingModeAtClient Then
		
		File = New File(TempFileName);
		
		If File.Exists() Then
			
			DeleteFiles(TempFileName);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RecalculateDataToExportByRefAtServer()
	
	ObjectAtServer = FormAttributeToValue("Object");
	FillMetadataTreeAtServer(ObjectAtServer);
	ObjectAtServer.ExportComposition(True);
	ValueToFormAttribute(ObjectAtServer.MetadataTree, "Object.MetadataTree");
	
EndProcedure

&AtServer
Procedure FillMetadataTreeAtServer(ObjectAtServer)
	
	MetadataTree = FormAttributeToValue("Object.MetadataTree");
	
	ObjectAtServer.Initialize();
	
	SetMarksOfDataToExport(ObjectAtServer.MetadataTree.Rows, MetadataTree.Rows);
	
EndProcedure

&AtClient
Procedure SaveTreeView(TreeRows)
	
	For Each String In TreeRows Do
		
		RowID=String.GetID();
		String.Expanded = Items.MetadataTree.Expanded(RowID);
		
		SaveTreeView(String.GetItems());
		
	EndDo;
	
EndProcedure

&AtClient
Procedure RestoreTreeDisplay(TreeRows)
	
	For Each String In TreeRows Do
		
		RowID=String.GetID();
		If String.Expanded Then
			Items.MetadataTree.Expand(RowID);
		EndIf;
		
		RestoreTreeDisplay(String.GetItems());
		
	EndDo;
	
EndProcedure

// Parameters:
//   Ref - AnyRef - Reference to object.
//
&AtServerNoContext
Function ObjectNameByTypeForQuery(Ref)
	
	ObjectMetadata = Ref.Metadata();
	NameOfMetadataObjects = ObjectMetadata.Name;
	
	NameForQuery = "";
	
	If Metadata.Catalogs.Contains(ObjectMetadata) Then
		NameForQuery = "Catalog";
	ElsIf Metadata.Documents.Contains(ObjectMetadata) Then
		NameForQuery = "Document";
	ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(ObjectMetadata) Then
		NameForQuery = "ChartOfCharacteristicTypes";
	ElsIf Metadata.ChartsOfAccounts.Contains(ObjectMetadata) Then
		NameForQuery = "ChartOfAccounts";
	ElsIf Metadata.ChartsOfCalculationTypes.Contains(ObjectMetadata) Then
		NameForQuery = "ChartOfCalculationTypes";
	ElsIf Metadata.ExchangePlans.Contains(ObjectMetadata) Then
		NameForQuery = "ExchangePlan";
	ElsIf Metadata.BusinessProcesses.Contains(ObjectMetadata) Then
		NameForQuery = "BusinessProcess";
	ElsIf Metadata.Tasks.Contains(ObjectMetadata) Then
		NameForQuery = "Task";
	EndIf;
	
	If IsBlankString(NameForQuery) Then
		Return "";
	Else
		Return NameForQuery + "." + NameOfMetadataObjects;
	EndIf;
	
EndFunction

// Parameters:
//   SelectedValues - ValueTable:
//     * Ref - AnyRef - Reference to object.
//
&AtServer
Procedure ProcessingSelectionOnServer(SelectedValues)
	
	If TypeOf(SelectedValues) = Type("Structure") Then
		
		QueryResult = GetFromTempStorage(SelectedValues.ChoiceData);
		
		If TypeOf(QueryResult)=Type("Array") Then
			
			QueryResult = QueryResult[QueryResult.UBound()];
			
			If QueryResult.Columns.Find("Ref") <> Undefined Then
				SelectedRefs = QueryResult.Unload();
			EndIf;
			
		EndIf;
		
	Else
		
		SelectedRefs = SelectedValues;
		
	EndIf;
	
	For Each Value In SelectedRefs Do
		
		NewRow = Object.AdditionalObjectsToExport.Add();
		NewRow.Object = Value.Ref;
		NewRow.ObjectForQueryName = ObjectNameByTypeForQuery(Value.Ref);
		
	EndDo
	
EndProcedure

&AtClient
Procedure ExportAtClientOrAtServerOnChange(Item)
	
	OnChangeRunMode();
	
EndProcedure

&AtClient
Procedure ImportAtClientOrAtServerOnChange(Item)
	
	OnChangeRunMode();
	
EndProcedure

&AtServer
Procedure CheckPlatformVersionAndCompatibilityMode()
	
	Information = New SystemInfo;
	If Not (Left(Information.AppVersion, 3) = "8.3"
		And (Metadata.CompatibilityMode = Metadata.ObjectProperties.CompatibilityMode.DontUse
		Or (Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_1
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_2_13
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_2_16"]
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_1"]
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_2"]))) Then
		
		Raise NStr("ru = 'Обработка предназначена для запуска на версии платформы
			|1С:Предприятие 8.3 с отключенным режимом совместимости или выше';
			|en = 'The data processor supports 1C:Enterprise 8.3 or later,
			|with disabled compatibility mode.';");
		
	EndIf;
	
EndProcedure

#EndRegion