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
Var TechnologicalLogFoldersToDelete;

&AtClient
Var FormIsBeingClosed;

&AtClient
Var ClearingTechnologicalLogFiles;

&AtClient
Var TechnologicalLogFilesDeletionStartDate;

#EndRegion

#Region FormEventHandlers

// Server-side create handler.
// 1. Initializes valid configuration data types for parameter presentation.
// 2. Generates the form name path.
// 3. Automatically creates a query within the table.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DefaultQueryName = NStr("ru = 'Новый запрос';
								|en = 'New query';");
	
	DataProcessorObject                            = DataProcessorObject2();
	Object.AvailableDataTypes                 = DataProcessorObject.Metadata().Attributes.AvailableDataTypes.Type;
	Object.PathToForms                         = DataProcessorObject.Metadata().FullName() + ".Form";
	Object.AlternatingColorsByQuery = True;
	
	Item                      = Object.Queries.Add();
	CurrentQueryID = New UUID;
	Item.Id        = CurrentQueryID;
	Item.Name                  = DefaultQueryName;
	
	TypesList                  = DataProcessorObject2().GenerateListOfTypes();
	DataProcessorObject2().TypesListFiltering(TypesList, "");
	
	FormCaption = NStr("ru = 'Консоль запросов (%DefaultQueryName%)';
							|en = 'Query console (%DefaultQueryName%)';");
	FormCaption = StrReplace(FormCaption, "%DefaultQueryName%", DefaultQueryName);
	Title = FormCaption;
	
	Object.TabOrderType = "Auto";
	
	EnableChoiceMode();
	
	OutputQueryResults = 1000;
	
	EnableResult = New Structure("Result, Cause", False, "");
	TechnologicalLogParameters = New Structure("LogFilesDirectory, OSProcessID");
	
	DataProcessorObject2().GetFlagIfTechnologicalLogEnabledForCurrentSession(TechnologicalLogParameters, EnableResult);
	If EnableResult.Result Or QueryAnalysisPerformed Then
		OSProcessID = TechnologicalLogParameters.OSProcessID;
		LogFilesDirectory = TechnologicalLogParameters.LogFilesDirectory;
		
		ShouldShowQueryExecutionPlan = True;
		Items.ShowQueryExecutionPlan.Enabled = False;
		Items.QueryPlanActivationDecoration.Visible = True;
		Items.ShowQueryExecutionPlanSkip.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
#If MobileClient Then
		ShowMessageBox(, NStr("ru = 'Работа консоли запросов в мобильном клиенте не поддерживается.';
										|en = 'Query console operation is not supported in mobile client.';"));
		Cancel = True;
		Return;
#EndIf
	
	FormIsBeingClosed = False;
	ClearingTechnologicalLogFiles = False;
	
	If ShouldShowQueryExecutionPlan Then
		AttachIdleHandler("CheckIfCanOpenTechnologicalLog", 3);
	EndIf;
	
	If ShouldShowQueryExecutionPlan Then
		SetShowQueryExecutionPlanLabelAppearance();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ClearingTechnologicalLogFiles Then
		FormIsBeingClosed = True;
		MessageText = NStr("ru = 'Очистка файлов может продолжаться до 2 минут';
								|en = 'File clearing can take up to 2 minutes';");
		MessageToUser(MessageText, "Object");
		Cancel = True;
		Return;
	EndIf;
	
	If Modified Then
		Cancel = True;
		If Not Exit Then
			Text = NStr("ru = 'Данные изменены. Сохранить изменения?';
						|en = 'The data has been changed. Save the changes?';");
			NotifyDescription = New NotifyDescription("BeforeCloseCompletion", ThisObject);
			ShowQueryBox(NotifyDescription, Text, QuestionDialogMode.YesNoCancel);
		EndIf;
	ElsIf Not Exit Then
		Notify("DisableGetQueryPlanInOtherFormsFlag",, ThisObject);
		If ShouldShowQueryExecutionPlan > 0 Then
			Cancel = True;
			FormIsBeingClosed = True;
			ShouldShowQueryExecutionPlan = False;
			DisableQueryExecutionPlanClient();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Cancel Then
		Return;
	ElsIf Response = DialogReturnCode.Yes Then
		SaveQueryFile(Object.FileName);
	Else
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "PassSettingsParameters" Then
		ExportSettings(Parameter);
	ElsIf EventName = "PassAutoSavingSettingsParameters" Then
		AutoSaveSettings();
	ElsIf EventName = "ExportQueriesToAttributes" Then
		ExportQueriesToAttributes(Parameter);
	ElsIf EventName = "UpdateFormClient" Then
		UpdateFormClient();
	ElsIf EventName = "ClearQueryLabel" Then
		QueryMark = "";
	ElsIf EventName = "GettingBorder" Then
		ExportQueriesToAttributes(Parameter); 
	ElsIf EventName = "DisableGetQueryPlanInOtherFormsFlag"
		 And Source <> ThisObject Then
		ShouldShowQueryExecutionPlan = False;
		SetShowQueryExecutionPlanLabelAppearance();
	ElsIf EventName = "Enable_QueryExecutionPlan"
		 And Source <> ThisObject
		 And Not ShouldShowQueryExecutionPlan Then
		ShouldShowQueryExecutionPlan = True;
		Enable_QueryExecutionPlanClient();
	ElsIf EventName = "GetQueryExecutionPlanError"
		 And Parameter.Property("QueryMark") And Parameter.QueryMark = QueryMark Then
		QueryAnalysisPerformed = False;
		SetShowQueryExecutionPlanLabelAppearance();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShowQueryExecutionPlanClick(Item)
	
	QueryPlanStorageAddress = "";
	
	If ValueIsFilled(CurrentQueryID) Then
		
		FilterStructure1 = New Structure;
		FilterStructure1.Insert("Id",CurrentQueryID);
		QueryString = Object.Queries.FindRows(FilterStructure1);
		
		If QueryString.Count() > 0 Then
			If ValueIsFilled(QueryString[0].QueryPlanStorageAddress) Then
				
				QueryPlanStorageAddress = QueryString[0].QueryPlanStorageAddress;
				QueryPlanStructure = GetFromTempStorage(QueryPlanStorageAddress);
				
				If QueryPlanStructure <> Undefined Then
					QueryPlanUpToDate = QueryPlanStructure.QueryPlanUpToDate;
					OpenQueryExecutionPlanForm();
					Return;
				EndIf;
				
			EndIf;
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(QueryMark) Then 
		ShowMessageBox(Undefined, NStr("ru = 'Для получения плана выполнения запроса сначала выполните запрос.';
													|en = 'To get a query plan, execute the query first.';"));
		Return;
	EndIf;
	
	If TechnologicalLogAvailable() Then
		OpenQueryExecutionPlanForm();
	Else
		AttachIdleHandler("CheckIfCanOpenTechnologicalLog", 5);
		Items.ShowQueryExecutionPlan.Title = NStr("ru = 'Подготовка...';
																|en = 'Preparation…';");
	EndIf;
	
EndProcedure

&AtClient
Procedure TypeInFormStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ItemTitle = NStr("ru = 'Выбрать тип';
							|en = 'Choose type';");
	NotifyDescription = New NotifyDescription("TypeInFormSelectionCompletion", ThisObject);
	TypesList.ShowChooseItem(NotifyDescription, ItemTitle);

EndProcedure

&AtClient
Procedure TypeInFormSelectionCompletion(SelectedElement, AdditionalParameters) Export
	
	If SelectedElement <> Undefined Then
		
		CurrentParameter = Items.Parameters.CurrentData;
		Current_Type = SelectedElement;
		
		If Current_Type.Value = "ValueTable"
			Or Current_Type.Value = "PointInTime"
			Or Current_Type.Value = "Boundary" Then
		
			CurrentParameter.Type            = Current_Type.Value;
			CurrentParameter.TypeInForm      = Current_Type.Presentation;
			CurrentParameter.Value       = "";
			CurrentParameter.ValueInForm = Current_Type.Presentation;
		Else
			ParameterTypeAndValueInitialization(CurrentParameter, Current_Type);
		EndIf;
		
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ParametersBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	If Not Copy Then 
		CurrentQueryIndex = CurrentQuestionIndex();
		If CurrentQueryIndex = Undefined Then
			MessageText = NStr("ru = 'Выберите запрос.';
									|en = 'Select query.';");
			MessageToUser(MessageText, "Object");
			Return;
		EndIf;
		
		ParameterItem = Object.Parameters.Add();
		ParameterItem.QueryID = CurrentQueryID;
		ParameterItem.Name = GETParameterName();
		ParameterItem.Id = New UUID;
		
		UpdateFormClient();
		
		ItemsParameters = Items.Parameters;
		ItemsParameters.CurrentRow = ParameterItem.GetID();
		TypeInFormStartChoice(ItemsParameters, Undefined, False);
	Else
		CopyingItem = Item.CurrentData;
		
		ParameterItem = Object.Parameters.Add();
		ParameterItem.Id = New UUID;
		ParameterItem.QueryID = CurrentQueryID;
		ParameterItem.Name = CopyingItem.Name;
		ParameterItem.Type = CopyingItem.Type;
		ParameterItem.Value = CopyingItem.Value;
		ParameterItem.TypeInForm = CopyingItem.TypeInForm;
		ParameterItem.ValueInForm = CopyingItem.ValueInForm;
	EndIf;
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure QueryTextOnChange(Item)
	
	CurrentQueryIndex = CurrentQuestionIndex();
	If CurrentQueryIndex = Undefined Then
		MessageText = NStr("ru = 'Выберите запрос.';
								|en = 'Select query.';");
		MessageToUser(MessageText, "Object");
		Return;
	EndIf;
	
	QueryStrings = QueryText.GetText();
	CurrentQuery = Object.Queries.Get(CurrentQueryIndex - 1);
	
	// If the query name is default, generate a query name.
	If CurrentQuery.Name = DefaultQueryName Then 
		CurrentQuery.Name = GetQueryName(QueryStrings);
	EndIf;
	
	QueryMark = "";
	If ValueIsFilled(CurrentQuery.QueryPlanStorageAddress) Then
		QueryPlanStructure = GetFromTempStorage(CurrentQuery.QueryPlanStorageAddress);
		If QueryPlanStructure <> Undefined Then
			QueryPlanUpToDate = False;
			QueryPlanStructure.Insert("QueryPlanUpToDate",QueryPlanUpToDate);
			CurrentQuery.QueryPlanStorageAddress = PutToTempStorage(QueryPlanStructure,CurrentQuery.QueryPlanStorageAddress);
		Else
			CurrentQuery.QueryPlanStorageAddress = PutToTempStorage(Undefined,New UUID);
		EndIf;
	Else
		CurrentQuery.QueryPlanStorageAddress = PutToTempStorage(Undefined,New UUID);
	EndIf;
	
	SetShowQueryExecutionPlanLabelAppearance();
	
	CurrentQuery.Text = QueryStrings;
	
EndProcedure

&AtClient
Procedure FillFromXML(Command)
	FoundItems = Object.Queries.FindRows(New Structure("Id", CurrentQueryID));
	If FoundItems.Count() = 0 Then
		MessageToUser(NStr("ru = 'Выберите запрос.';
									|en = 'Select query.';"), "Object");
		Return;
	EndIf;
	CurrentQuery = FoundItems[0];
	Context = New Structure("FromQueryText", False);
	If Left(CurrentQuery.Text, 10) = "<Structure" Then
		Context.FromQueryText = True;
		FillParametersFromXMLServer(CurrentQuery.Text, Context);
	Else
		Handler = New NotifyDescription("FillParametersFromXMLCompletion", ThisObject, Context);
		ToolTip = SubstituteParametersToString(NStr("ru = 'Вставьте XML с информацией о запросе, полученный методом %1';
													|en = 'Insert XML with information on query, got by the %1 method.';"), 
			"Common.ValueToXMLString()");
		ShowInputString(Handler, , ToolTip, , True);
	EndIf;
EndProcedure

&AtClient
Procedure ValueInFormOnChange(Item)
	
	CurrentParameter = Items.Parameters.CurrentData;
	
	Value		= CurrentParameter.ValueInForm;
	Current_Type		= CurrentParameter.Type;
	If Current_Type <> "ValueTable" And Current_Type <> "PointInTime" And Current_Type <> "Boundary" Then
		InternalValue					= ValueToStringServer(Value);
		CurrentParameter.Value	= InternalValue;
		
		Modified 			= True;
		
	EndIf;
EndProcedure

&AtClient
Procedure ParametersOnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure ParametersAfterDeleteRow(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure ValueInFormStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentParameter = Items.Parameters.CurrentData;
	ParameterType	= Items.Parameters.CurrentData.Type;
	
	CurrentParameterID = CurrentParameter.Id;
	
	If ParameterType = "ValueTable" Then
		Path = Object.PathToForms + "." + "ValueTable";
	ElsIf ParameterType = "PointInTime" Then
		Path = Object.PathToForms + "." + "PointInTime";
	ElsIf ParameterType = "Boundary" Then
		Path = Object.PathToForms + "." + "Boundary";
	Else
		Return;
	EndIf;
	
	QueriesToPass = PutQueriesInStructure();
	OpenForm(Path, QueriesToPass, ThisObject);
	
EndProcedure

&AtClient
Procedure QueryResultOnChange(Item)
	
	// WithCaptured current query from the query list.
	CurrentQueryIndex = CurrentQuestionIndex();
	If CurrentQueryIndex = Undefined Then
		MessageText = NStr("ru = 'Выберите запрос.';
								|en = 'Select query.';");
		MessageToUser(MessageText, "Object");
		Return;
	EndIf;
	
	// Select the current query.
	CurrentQuery = Object.Queries.Get(CurrentQueryIndex - 1);
	CurrentQuery.ResultAddress = PutToTempStorage(QueryResult, UUID);
	
EndProcedure

&AtClient
Procedure QueryResultSelection(Item, Area, StandardProcessing)
	
	DetailsCell = Area.Details;
	
	DetailsType = TypeOf(DetailsCell);
	
	If Object.AvailableDataTypes.ContainsType(DetailsType) And DetailsCell <> Undefined Then
		StandardProcessing = False;
		ShowValue(, DetailsCell);
	EndIf;
	
EndProcedure

&AtClient
Procedure QueryResultOnChangeAreaContent(Item, Area)
	
	// WithCaptured current query from the query list.
	CurrentQueryIndex = CurrentQuestionIndex();
	If CurrentQueryIndex = Undefined Then
		MessageText = NStr("ru = 'Выберите запрос.';
								|en = 'Select query.';");
		MessageToUser(MessageText, "Object");
		Return;
	EndIf;
	
	// Select the current query.
	CurrentQuery = Object.Queries.Get(CurrentQueryIndex - 1);
	CurrentQuery.ResultAddress = PutToTempStorage(QueryResult, UUID);
	
EndProcedure

&AtClient
Procedure GetQueryExecutionPlanOnChange(Item)
	
	If ShouldShowQueryExecutionPlan Then
		Enable_QueryExecutionPlanClient()
	Else
		DisableQueryExecutionPlanClient();
	EndIf;
	
EndProcedure


#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetUUID(Command)
	
	LineNumber = Items.Parameters.CurrentRow;
	Notification = New NotifyDescription("AfterEnterUUID", ThisObject, LineNumber);
	UUIDAsString1 = "";
	ShowInputString(Notification, UUIDAsString1, NStr("ru = 'Введите уникальный идентификатор';
																		|en = 'Enter an UUID';"));
	
EndProcedure

&AtClient
Procedure CommentOut(Command)
	
	Var FirstRow, FirstColumn, LastRow, LastColumn;
	
	Item = Items.QueryText;
	Item.GetTextSelectionBounds(FirstRow, FirstColumn, LastRow, LastColumn);
	
	TextBeforeChange = QueryText.GetText();
	RowsCount = StrLineCount(TextBeforeChange);
	SelectedFragment = "";
	LastRowLength = 0;
	
	If LastColumn = 1 Then 
		LastRow = LastRow - 1;
	EndIf;
	If FirstRow >= LastRow And LastColumn = 1 Then 
		LastColumn = StrLen(StrGetLine(TextBeforeChange, FirstRow));
		LastRow = FirstRow;
	EndIf;
	
	For LineNumber = 1 To RowsCount Do
		Particle = StrGetLine(TextBeforeChange, LineNumber);
		If LineNumber >= FirstRow And LineNumber <= LastRow Then
			If LineNumber = FirstRow Then 
				SelectedFragment = SelectedFragment + "//" + Particle;
			Else
				SelectedFragment = SelectedFragment + Chars.LF + "//" +Particle;
			EndIf;
			If LineNumber = LastRow Then 
				LastRowLength = StrLen(Particle) + 3;
			EndIf;
		EndIf;
	EndDo;
	
	If LastColumn = 1 Then 
		LastRow = LastRow + 1;
		LastRowLength = 1;
		SelectedFragment =  SelectedFragment + Chars.LF;
	EndIf;
	
	Item.SetTextSelectionBounds(FirstRow, 1, LastRow, LastRowLength);
	Item.SelectedText = SelectedFragment;
	Item.SetTextSelectionBounds(FirstRow, 1, LastRow, LastRowLength);
	
EndProcedure

&AtClient
Procedure Uncomment(Command)
	
	Var FirstRow, FirstColumn, LastRow, LastColumn;
	Item = Items.QueryText;
	Item.GetTextSelectionBounds(FirstRow, FirstColumn, LastRow, LastColumn);
	
	TextBeforeChange = QueryText.GetText();
	RowsCount = StrLineCount(TextBeforeChange);
	SelectedFragment = "";
	LastRowLength = LastColumn;
	
	If LastColumn = 1 Then
		LastRow = LastRow - 1;
	EndIf;
	If FirstRow >= LastRow And LastColumn = 1 Then 
		LastColumn = StrLen(StrGetLine(TextBeforeChange, FirstRow));
		LastRow = FirstRow;
	EndIf;

	For LineNumber = 1 To RowsCount Do
		Particle = StrGetLine(TextBeforeChange, LineNumber);
		If LineNumber >= FirstRow And LineNumber <= LastRow Then
			If StrStartsWith(TrimL(Particle), "//") Then
				Position = StrFind(Particle, "//");
				Particle = Left(Particle, Position - 1) + Mid(Particle, Position + 2);
			EndIf;
			If LineNumber = FirstRow Then 
				SelectedFragment = SelectedFragment + Particle;
			Else
				SelectedFragment = SelectedFragment + Chars.LF + Particle;
			EndIf;
			If LineNumber = LastRow Then 
				LastRowLength = StrLen(Particle) + 3;
			EndIf;
		EndIf;
	EndDo;
	
	If LastColumn = 1 Then
		LastRow = LastRow + 1;
		LastRowLength = 1;
		SelectedFragment =  SelectedFragment + Chars.LF;
	EndIf;
	
	Item.SetTextSelectionBounds(FirstRow, 1, LastRow, LastRowLength);
	Item.SelectedText = SelectedFragment;
	Item.SetTextSelectionBounds(FirstRow, 1, LastRow, LastRowLength);
	
EndProcedure

&AtClient
Procedure SelectQueryResult(Command)
	
	For Each QueryString In Object.Queries Do
		If QueryString.Id=CurrentQueryID And Not IsBlankString(QueryString.QueryResultsAddress) Then
			NotifyChoice(New Structure("ChoiceAction, ChoiceData",
				Parameters.ChoiceAction, QueryString.QueryResultsAddress));
			Return;
		EndIf;
	EndDo;
	
	WarningText = NStr("ru = 'Введите текст запроса и выполните его.';
								|en = 'Enter a query text and execute it.';");
	ShowMessageBox(, WarningText);
	
EndProcedure

&AtClient
Procedure OpenQuerySelectionForm(Command)
	
	QueriesToPass = PutQueriesInStructure();
	Path = Object.PathToForms + "." + "SelectQuery";
	OpenForm(Path, QueriesToPass, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenQueryBuilder(Command)
	
#If MobileClient Then
		ShowMessageBox(, NStr("ru = 'Работа консоли запросов в мобильном клиенте не поддерживается.';
										|en = 'Query console operation is not supported in mobile client.';"));
		Return;
#Else
		CurrentQueryIndex = CurrentQuestionIndex();
		If CurrentQueryIndex = Undefined Then
			MessageText = NStr("ru = 'Выберите запрос.';
									|en = 'Select query.';");
			MessageToUser(MessageText, "Object");
			Return;
		EndIf;
		
		QueryTextInForm = TrimAll(QueryText.GetText());
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("CurrentQueryIndex", CurrentQueryIndex);
		ParametersStructure.Insert("RequestSourceText", QueryTextInForm);
		
		QueryWizard = New QueryWizard(QueryTextInForm);
		Notification = New NotifyDescription("AfterCloseQueryBuilder", ThisObject, ParametersStructure);
		QueryWizard.Show(Notification);
#EndIf
	
EndProcedure

&AtClient
Procedure ReadParametersFromQueryText(Command)
	
	FillParameters_Client();
	
EndProcedure

&AtClient
Procedure OpenAutoSaveSettingsForm(Command)
	
	SettingsToPass = PutSettingsInStructure();
	Path = Object.PathToForms + "." + "Settings";
	
	OpenForm(Path, SettingsToPass, ThisObject);
	
EndProcedure

&AtClient
Procedure ExecuteQuery(Command)
	
	RunQueryExecution(False);
	
EndProcedure

&AtClient
Procedure ExecuteQueryUsingTempTables(Command)
	
	RunQueryExecution(True);
	
EndProcedure

&AtClient
Procedure SaveQueriesToFile(Command)
	
	SaveQueryFile(Object.FileName);
	
EndProcedure

&AtClient
Procedure SaveQueriesToAnotherFile(Command)
	
	SaveQueryFile();
	
EndProcedure

&AtClient
Procedure SelectQueriesFromFile(Command)
	
	FileReadingProcessing(True);
	
EndProcedure

&AtClient
Procedure CreateQueryTextForDesigner(Command)
	
	TransferParameters = New Structure;
	TransferParameters.Insert("QueryText", QueryText.GetText());
	
	Path = Object.PathToForms + "." + "DesignerQueryText";
	OpenForm(Path, TransferParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenSpreadsheetDocumentInNewWindow(Command)
	
	TransferParameters = New Structure;
	TransferParameters.Insert("QueryResult", QueryResult);
	
	Path = Object.PathToForms + "." + "QueryResult";
	OpenForm(Path, TransferParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure CopyQuery(Command)
	
	CurrentQueryIndex = CurrentQuestionIndex();
	If CurrentQueryIndex = Undefined Then
		MessageToUser(NStr("ru = 'Выберите запрос.';
									|en = 'Select query.';"), "Object");
		Return;
	EndIf;
	
	BaseQuery = Object.Queries.Get(CurrentQueryIndex - 1);
	
	NewQueryID 	= New UUID;
	NewQueryName			= GenerateQueryCopyName(BaseQuery.Name);
	
	NewQuery 				= Object.Queries.Add();
	NewQuery.Id 	= NewQueryID;
	NewQuery.Name				= NewQueryName;
	NewQuery.Text			= BaseQuery.Text;
	NewQuery.QueryPlanStorageAddress = PutToTempStorage(Undefined,New UUID);
	
	QueryAnalysisPerformed = False;
	QueryPlanUpToDate = False;
	
	QueryMark = "";
	SetShowQueryExecutionPlanLabelAppearance();
	
	CopyParametersFromQuery(NewQuery);
	
	// Modify value of CurrentQueryID.
	CurrentQueryID = NewQueryID;
	
	UpdateFormClient();
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure OpenObjectFromResult(Command)
	
	DetailsCell = QueryResult.CurrentArea.Details;
	DetailsType    = TypeOf(DetailsCell);
	If Object.AvailableDataTypes.ContainsType(DetailsType) And DetailsCell <> Undefined Then
		ShowValue(, DetailsCell);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenListFromResult(Command)
	
	DetailsCell = QueryResult.CurrentArea.Details;
	ListFormName    = GenerateListFormNameForRef(DetailsCell);
	If Not IsBlankString(ListFormName) Then
		OpenForm(ListFormName, , ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectCells(Command)
	
	ResultArea = QueryResult.CurrentArea;
	
	FirstRow     = ResultArea.Top;
	FirstColumn    = ResultArea.Left;
	LastRow  = ResultArea.Bottom;
	LastColumn = ResultArea.Right;
	
	ReferenceArea      = QueryResult.Area(FirstRow, FirstColumn, FirstRow, FirstColumn);
	ReferenceAreaFont = ReferenceArea.Font;
	
	If ReferenceAreaFont = Undefined Then
		Return;
	EndIf;
	
	BoldFlag = Not ReferenceAreaFont.Fatty;
	If BoldFlag = Undefined Then
		Return;
	EndIf;
	
	For RowIndex = FirstRow To LastRow Do
		For ColumnIndex = FirstColumn To LastColumn Do
			CurrentResultArea = QueryResult.Area(RowIndex, ColumnIndex, RowIndex, ColumnIndex);
			CurrentFont = CurrentResultArea.Font;
			If CurrentFont <> Undefined Then
				CurrentResultArea.Font = New Font(CurrentFont,,, BoldFlag);
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

&AtClient
Procedure AfterCloseQueryBuilder(QueryTextInForm, ParametersStructure) Export
	
	If QueryTextInForm <> Undefined Then
		
		CurrentQuery = Object.Queries.Get(ParametersStructure.CurrentQueryIndex - 1);
		
		If QueryTextInForm <> ParametersStructure.RequestSourceText Then
			
			QueryMark = "";
			QueryPlanStructure = Undefined;
			
			If ValueIsFilled(CurrentQuery.QueryPlanStorageAddress) Then
				QueryPlanStructure = GetFromTempStorage(CurrentQuery.QueryPlanStorageAddress);
			EndIf;
			
			If QueryPlanStructure <> Undefined Then
				QueryPlanUpToDate = False;
				QueryPlanStructure.Insert("QueryPlanUpToDate",QueryPlanUpToDate);
				CurrentQuery.QueryPlanStorageAddress = PutToTempStorage(QueryPlanStructure,CurrentQuery.QueryPlanStorageAddress);
			Else
				CurrentQuery.QueryPlanStorageAddress = PutToTempStorage(Undefined,New UUID);
			EndIf;
			
			SetShowQueryExecutionPlanLabelAppearance();
			
		EndIf;
		
		If CurrentQuery.Name = DefaultQueryName Then
			CurrentQuery.Name = GetQueryName(QueryTextInForm);
		EndIf;
		CurrentQuery.Text = QueryTextInForm;
		Modified = True;
		UpdateFormClient();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function DataProcessorObject2()
	
	Return FormAttributeToValue("Object");
	
EndFunction

// Pass tables "Queries" and "Parameters" as a structure.
//
&AtServer
Function PutQueriesInStructure()
	
	StorageAddress		= DataProcessorObject2().PutQueriesInTempStorage(Object, CurrentQueryID, CurrentParameterID);
	AddressParameter		= New Structure;
	AddressParameter.Insert("StorageAddress", StorageAddress);
	Return AddressParameter;
	
EndFunction

// Get the "Queries" table as a structure.
// Returns the selected query ID, and updates the "Queries" table.
//
// Parameters:
//   TransferParameters - Structure - Queries from the object being passed and the current query ID:
//     * StorageAddress - String
//
&AtServer
Procedure ExportQueriesToAttributes(TransferParameters)
	
	QueriesDetails = GetFromTempStorage(TransferParameters.StorageAddress); // See DataProcessorObject.QueryConsole.PutQueriesInTempStorage
	ReceivedQueries 				= QueriesDetails.Queries;
	ReceivedParameters 			= QueriesDetails.Parameters;
	Object.FileName  				= QueriesDetails.FileName;
	CurrentQueryID  	= QueriesDetails.CurrentQueryID;
	CurrentParameterID 	= QueriesDetails.CurrentParameterID;
	Object.Queries.Load(ReceivedQueries);
	Object.Parameters.Load(ReceivedParameters);
	
	OutputQueryResult();
	
EndProcedure

&AtServer
Procedure OutputQueryResult()
	
	QueryResult = New SpreadsheetDocument;
	For Each StrQueries In Object.Queries Do
		
		If StrQueries.Id = CurrentQueryID Then
			GetQueryResultFromStorage(QueryResult, StrQueries.ResultAddress);
			
			RowsCount = StrQueries.RowsCount;
			RunTime = StrQueries.RunTime;
			ResultingLine	= NStr("ru = 'Результат запроса (количество строк = %CntOfRws%, время выполнения = %RunTime% с)';
											|en = 'Query result (number of rows = %CntOfRws%, execution time = %RunTime% sec)';");
			ResultingLine 	= StrReplace(ResultingLine, "%CntOfRws%", String(RowsCount));
			ResultingLine 	= StrReplace(ResultingLine, "%RunTime%", String(RunTime));
			Items.QueryResult.Title = ResultingLine;
			
			Items.GroupQueryResult.Title = ResultingLine;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Pass autosave settings.
//
&AtServer
Function PutSettingsInStructure()
	
	StorageAddress		= DataProcessorObject2().PutSettingsInTempStorage(Object);
	AddressParameter		= New Structure;
	AddressParameter.Insert("StorageAddress", StorageAddress);
	
	Return AddressParameter;
	
EndFunction

// Get settings as a structure.
//
// Parameters:
//   TransferParameters - Structure - Settings.
//
&AtServer
Procedure ExportSettings(TransferParameters)
	
	Object.UseAutosave 						= GetFromTempStorage(TransferParameters.StorageAddress).UseAutosave;
	Object.AutoSavePeriod								= GetFromTempStorage(TransferParameters.StorageAddress).AutoSavePeriod;
	Object.OutputRefValuesInQueryResults		= GetFromTempStorage(TransferParameters.StorageAddress).OutputRefValuesInQueryResults;
	Object.TabOrderType										= GetFromTempStorage(TransferParameters.StorageAddress).TabOrderType;
	Object.AlternatingColorsByQuery				= GetFromTempStorage(TransferParameters.StorageAddress).AlternatingColorsByQuery;
	
EndProcedure

// Form update.
// Update presentation of parameters, query text, and the result.
//
&AtClient
Procedure UpdateFormClient()
	
	// Update parameters.
	Filter = New Structure;
	Filter.Insert("QueryID", CurrentQueryID);
	FixedFilter1 = New FixedStructure(Filter);
	Items.Parameters.RowFilter = FixedFilter1;
	
	For Each StrQueries In Object.Queries Do
		
		If StrQueries.Id = CurrentQueryID Then
			
			// Update query text.
			QueryText.SetText(StrQueries.Text);
			QueryAnalysisPerformed = QueryAnalysisPerformed(StrQueries.QueryPlanStorageAddress, QueryPlanUpToDate);
			SetShowQueryExecutionPlanLabelAppearance();
			
			// Display form header.
			FormCaption = NStr("ru = 'Консоль запросов (%QueryName1%)';
									|en = 'Query console (%QueryName1%)';");
			FormCaption = StrReplace(FormCaption, "%QueryName1%", StrQueries.Name);
			Title = FormCaption;
			
		EndIf;
		
	EndDo;
	
	SetShowQueryExecutionPlanLabelAppearance();
	
	// Output the "Queries" button title.
	NumberOfRequests_ = Object.Queries.Count();
	QueryChoiceButtonHeader = NStr("ru = 'Запросы';
										|en = 'Queries';");
	If NumberOfRequests_ > 1 Then
		QueryChoiceButtonHeader = QueryChoiceButtonHeader + " (" + NumberOfRequests_ + ")";
	EndIf;
	Items.FormSelect_Query.Title = QueryChoiceButtonHeader;
	
#If WebClient Then
		RefreshDataRepresentation();
#EndIf
	
EndProcedure

&AtClient
Function CurrentQuestionIndex()
	
	Result = Undefined;
	For Each StrQueries In Object.Queries Do
		If StrQueries.Id = CurrentQueryID Then
			Result = StrQueries.LineNumber;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

// Returns a query name by the first table name.
//
// Parameters:
//   QueryText - String - Text of the query to pass.
//
&AtClient
Function GetQueryName(Val QueryText)
	
	// If the query is empty, returns "Query".
	If IsBlankString(QueryText) Then
		Result = DefaultQueryName;
		Return Result;
	EndIf;
	
	// Search for the reserved word "SELECT".
	Select = "SELECT"; // @query-part-1
	LengthSelect = StrLen(Select);
	PositionSELECT = StrFind(Upper(QueryText), Select);
	If PositionSELECT = 0 Then
		Result = DefaultQueryName;
		Return Result;
	EndIf;
	
	// Slice of a query text line without the SELECT key.
	QueryText = Mid(QueryText, PositionSELECT + LengthSelect);
	
	// Search for the first dot to define a table name.
	Point = ".";
	LengthDot = StrLen(Point);
	PositionDot = StrFind(Upper(QueryText), Point);
	If PositionDot = 0 Then
		Result = DefaultQueryName;
		Return Result;
	EndIf;
	
	// Returns "Query:" and the first table name.
	Result = TrimAll(Left(QueryText, PositionDot - LengthDot));
	If IsBlankString(Result) Then
		Result = DefaultQueryName;
	EndIf;
	
	Return Result;
	
EndFunction

// Reads parameters from the query.
//
// Parameters:
//  QueryText - String - Query text.
//  ShouldDelete - Boolean - Parameter clear up flag for the current query.
//  QueryID - String - Current query ID.
//
&AtServer
Procedure ReadQueryParameters(QueryText, ShouldDelete, QueryID)
	
	// Read parameters from the query text to the structure array.
	ResultStructure = DataProcessorObject2().ReadQueryParameters(QueryText, QueryID);
	If TypeOf(ResultStructure) = Type("String") Then
		MessageToUser(ResultStructure);
		Return;
	EndIf;
	
	// Initialize parameters.
	ParametersInForm = Object.Parameters;
	
	// Delete parameters of the current query.
	If ShouldDelete Then
		RowsCount = ParametersInForm.Count() - 1;
		While RowsCount >= 0 Do
			CurrentParameter = ParametersInForm.Get(RowsCount);
			If CurrentParameter.QueryID = QueryID Then
				ParametersInForm.Delete(RowsCount);
				Modified = True;
			EndIf;
			RowsCount = RowsCount - 1;
		EndDo;
	EndIf;
	
	// Add parameters.
	Filter = New Structure;
	Filter.Insert("QueryID", QueryID);
	ParametersArray = ParametersInForm.FindRows(Filter);
	
	For Each StrParameter In ResultStructure Do
		HasParameter = False;
		For Each Page1 In ParametersArray Do
			If StrParameter.Name = Page1.Name Then
				HasParameter = True;
			EndIf;
		EndDo;
		If Not HasParameter Or Not ShouldDelete Then 
			AddParameterToForm(ParametersInForm, StrParameter);
			Modified = True;
		EndIf;
	EndDo;
	
EndProcedure

// Adds a parameter from the structure to the form parameter.
//
// Parameters:
//  ParametersInForm - ValueTable - "Parameters" value table in the form.
//  StructureParameter - KeyAndValue - Current string of the array structure parameter.
//
&AtServer
Procedure AddParameterToForm(ParametersInForm, StructureParameter)
	
	Value 	= StructureParameter.Value;
	Type			= DataProcessorObject2().TypeNameFromValue(ValueFromStringInternal(Value));
	
	// Main attributes.
	Item							= ParametersInForm.Add();
	Item.Id			= New UUID;
	Item.QueryID 	= StructureParameter.QueryID;
	Item.Name						= StructureParameter.Name;
	Item.Type						= Type;
	Item.Value				= Value;
	
	Value = ValueFromStringInternal(Value);
	
	// Form attributes.
	Item.TypeInForm 				= String(TypeOf(Value));
	Item.ValueInForm 			= Value;
	
EndProcedure	

// Call a procedure to save queries to the file.
//
&AtClient
Procedure AutoSaveSettings()
	
	If Object.UseAutosave Then
		// Call a procedure to save queries to the file.
		AutoSavePeriod = Object.AutoSavePeriod * 60;
		If AutoSavePeriod > 0 Then
			AttachIdleHandler("SaveQueries", AutoSavePeriod);
		EndIf;
	Else
		DetachIdleHandler("SaveQueries");
	EndIf;
	
EndProcedure

// The procedure that save queries for autosaving.
//
&AtClient
Procedure SaveQueries()
	
	FileName = Object.FileName;
	If Not IsBlankString(FileName) Then
		BinaryData = SaveQueriesServer();
		BinaryData.Write(FileName);
		ShowUserNotification(NStr("ru = 'Автосохранение прошло успешно.';
											|en = 'Successfully autosaved.';"), FileName);
		Modified = False;
	EndIf;
	
EndProcedure

// The procedure that save queries (server-side).
//
&AtServer
Function SaveQueriesServer()
	
	BinaryData = DataProcessorObject2().WriteQueriesToXMLFile(Object);
	Return BinaryData;
	
EndFunction

// Runs query.
//
&AtClient
Procedure RunQueryExecution(OutputTempTables)
	
	// WithCaptured current query from the query list.
	CurrentQueryIndex = CurrentQuestionIndex();
	If CurrentQueryIndex = Undefined Then
		MessageText = NStr("ru = 'Выберите запрос.';
								|en = 'Select query.';");
		MessageToUser(MessageText, "Object");
		Return;
	EndIf;
	
	UnformattedText = QueryText.GetText();
	Formatted_Text = StrReplace(UnformattedText, "|", "");
	
	If IsBlankString(Formatted_Text) Then
		WarningText = NStr("ru = 'Введите текст запроса.';
									|en = 'Enter query text.';");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	QueryText.SetText(Formatted_Text);
	Object.Queries.Get(CurrentQueryIndex - 1).Text = Formatted_Text;
	Object.Queries.Get(CurrentQueryIndex - 1).QueryPlanStorageAddress = PutToTempStorage(Undefined,New UUID);
	QueryAnalysisPerformed = False;
	QueryPlanUpToDate = True;
	SetShowQueryExecutionPlanLabelAppearance();
	
	// Define a query text.
	SelectedText = Items.QueryText.SelectedText;
	If Not IsBlankString(SelectedText) Then
		Text = SelectedText;
	Else
		Text = Object.Queries.Get(CurrentQueryIndex - 1).Text;
	EndIf;
	
	OutputID = Object.OutputRefValuesInQueryResults;
	
	// Clear the QueryResult spreadsheet document in the form.
	QueryResult = New SpreadsheetDocument;
	MessageText = "";
	
	ClearMessages();
	
	// Server-side query runtime.
	Try
		ExecuteQueryServer(CurrentQueryIndex, QueryResult, OutputTempTables, OutputID, Text, MessageText);
	Except
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ShowErrorToUser(ErrorText);
		Return;
	EndTry;
	
	If Not IsBlankString(MessageText) Then 
		MessageToUser(MessageText, "Object");
	EndIf;
	
	Items.GroupParameters.Hide();
	Items.GroupQueryResult.Show();
	
EndProcedure

&AtClient
Procedure ShowErrorToUser(Val ErrorText)
	
	Position = StrFind(ErrorText, "{(");
	
	If Position > 0 Then
		ErrorLocationInformationText = Mid(ErrorText, Position + 2);
		PositionEnd1 = StrFind(ErrorLocationInformationText, ")}");
		
		MessageText = TrimAll(Mid(ErrorLocationInformationText, PositionEnd1 + 3));
		MessageToUser(MessageText, "Object");
		
		ColumnAndRowNumber = StrSplit(Mid(ErrorLocationInformationText, 1, PositionEnd1 - 1), ",");
		If ColumnAndRowNumber.Count() = 2 Then
			NumberType = New TypeDescription("Number");
			ColumnNumber = NumberType.AdjustValue(TrimAll(ColumnAndRowNumber[0]));
			LineNumber = NumberType.AdjustValue(TrimAll(ColumnAndRowNumber[1]));
			Items.QueryText.SetTextSelectionBounds(ColumnNumber, LineNumber, ColumnNumber, LineNumber);
			CurrentItem = Items.QueryText;
		EndIf;
	Else
		MessageToUser(ErrorText, "Object");
	EndIf;

EndProcedure

// Imports a spreadsheet document returned from the Temporary storage to the query result.
//
// Parameters:
//  QueryResult - Query result.
//  ResultAddress - Temporary storage address.
//  QueryText - String - Query text.
//
&AtServer
Procedure ExecuteQueryServer(CurrentQueryIndex, SpreadsheetDocumentOfResult, OutputTempTables, OutputID, QueryText, MessageText)
	
	// Delete rows with comments.
	RowsCount = StrLineCount(QueryText);
	Text = "";
	For LineNumber = 1 To RowsCount Do
		Particle = StrGetLine(QueryText, LineNumber);
		If Not StrStartsWith(TrimL(Particle), "//") Then
			Text = Text + Particle + Chars.LF;
		EndIf;
	EndDo;
	
	// Populate parameters.
	FillParametersOnQueryExecution(Text);
	
	// Reset parameters.
	RunTime = 0;
	RowsCount = 0;
	
	// Select the current query.
	CurrentQuery = Object.Queries.Get(CurrentQueryIndex - 1);
	// Select parameters of the current query.
	Filter = New Structure;
	Filter.Insert("QueryID", CurrentQuery.Id);
	ParametersArray = Object.Parameters.FindRows(Filter);
	
	MaxCellsWidthArray = New Array;
	MaxCellsWidthArray.Clear();
	
	TabIndex = Object.TabOrderType;
	UseAlteration = Object.AlternatingColorsByQuery;
	
	If ShouldShowQueryExecutionPlan And TechnologicalLogAvailable() Then
		QueryMark = String(New UUID);
	Else
		QueryMark = "";
	EndIf;
	
	// Run the query.
	
	// Save the query result together with the spreadsheet document (result presentation).
	QueryOutputParameters = New Structure;
	QueryOutputParameters.Insert("OutputTempTables", OutputTempTables);
	QueryOutputParameters.Insert("OutputID", OutputID);
	QueryOutputParameters.Insert("TabIndex", TabIndex);
	QueryOutputParameters.Insert("UseAlteration", UseAlteration);
	QueryOutputParameters.Insert("OutputQueryResults", OutputQueryResults);
	
	QueryExecutionReport = New Structure;
	QueryExecutionReport.Insert("RowsCount", RowsCount);
	QueryExecutionReport.Insert("RunTime", RunTime);
	QueryExecutionReport.Insert("MessageText", MessageText);
	
	Result = DataProcessorObject2().ExecuteQuery(Text, ParametersArray, SpreadsheetDocumentOfResult, QueryOutputParameters, QueryExecutionReport, QueryMark);
	
	If ValueIsFilled(QueryExecutionReport.MessageText) Then
		MessageToUser(QueryExecutionReport.MessageText);
	EndIf;
	
	// Only if the selection mode is enabled.
	If Not Parameters.ChoiceMode Then
		Result = Undefined;
	EndIf; 
	
	// Populate a temporary storage address for the result.
	CurrentQuery.ResultAddress = PutToTempStorage(SpreadsheetDocumentOfResult, UUID);
	CurrentQuery.RunTime = QueryExecutionReport.RunTime;
	CurrentQuery.RowsCount = QueryExecutionReport.RowsCount;
	
	If Not IsBlankString(CurrentQuery.QueryResultsAddress) Then
		DeleteFromTempStorage(CurrentQuery.QueryResultsAddress)
	EndIf;
	If Result = Undefined Then
		CurrentQuery.QueryResultsAddress = "";
	Else
		CurrentQuery.QueryResultsAddress = PutToTempStorage(Result, UUID);
	EndIf;
	
	// Update the query result title.
	ResultingLine = NStr("ru = 'Результат запроса (количество строк = %RowsCount%, время выполнения = %RunTime% с)';
								|en = 'Query result (number of rows = %RowsCount%, execution time = %RunTime% sec)';");
	ResultingLine = StrReplace(ResultingLine, "%RowsCount%", String(QueryExecutionReport.RowsCount));
	ResultingLine = StrReplace(ResultingLine, "%RunTime%", String(QueryExecutionReport.RunTime));
	
	Items.QueryResult.Title = ResultingLine;
	Items.GroupQueryResult.Title = ResultingLine;
	
EndProcedure

&AtServer
Procedure GetQueryResultFromStorage(SpreadsheetDocumentOfResult, ResultAddress)
	
	If Not IsBlankString(ResultAddress) Then
		ResultFromTempStorage 	= GetFromTempStorage(ResultAddress);
		SpreadsheetDocumentOfResult 	= ResultFromTempStorage;
	EndIf;
	
EndProcedure

&AtServer
Function ValueToStringServer(Value)
	
	Result = ValueToStringInternal(Value);
	Return Result;
	
EndFunction

// Returns a string presentation of the type.
// For example, returns the CatalogRef.CatalogName value for the catalog reference.
//
&AtServer
Function StringType(Value)
	
	AddedTypesList = New ValueList;
	DataProcessorObject2().GenerateListOfTypes(AddedTypesList);
	
	StringType = String(Type(Value));
	If Value = "ValueList" Then
		Return "ValueList";
	EndIf;
		
	TypeDetected = False;
	For Each ListItem In AddedTypesList Do
		If ListItem.Presentation = StringType Then
			TypeDetected = True;
			Break;
		EndIf;
	EndDo;
	
	If Not TypeDetected Then
		StringType	= XMLType(Type(Value)).TypeName;
	EndIf;
	
	Return StringType;
	
EndFunction

// Generate a save query file dialog box.
//
&AtClient
Procedure SaveQueryFile(FileName = "")
	
	AdditionalParameters = New Structure("FileName", FileName);
#If Not WebClient Then
		// Extension is always attached for thin, thick, and web clients.
		SaveQueryFileCompletion(True, AdditionalParameters);
		Return;
#EndIf
	
	Notification = New NotifyDescription("BeginAttachingFileSystemExtensionCompletion", ThisObject,
		New NotifyDescription("SaveQueryFileCompletion", ThisObject, AdditionalParameters));
	BeginAttachingFileSystemExtension(Notification);
	
EndProcedure

&AtClient
Procedure SaveQueryFileCompletion(Result, AdditionalParameters) Export
	
	FileName = AdditionalParameters.FileName;
	If Result Then
		
		FilesToReceive = New Array;
		FilesToReceive.Add(New TransferableFileDescription(FileName, SaveQueriesToTempStorage()));
		
		GetFilesNotificationDescription = New NotifyDescription("GettingFilesCompletion", ThisObject);
		If ValueIsFilled(FileName) Then
			BeginGettingFiles(GetFilesNotificationDescription, FilesToReceive, FileName, False);
		Else
			Dialog = New FileDialog(FileDialogMode.Save);
			Dialog.Title = NStr("ru = 'Выберите файл запросов';
									|en = 'Select query file';");
			Dialog.Preview = False;
			Dialog.Filter = NStr("ru = 'Файл запросов (*.q1c)|*.q1c';
								|en = 'Query file (*.q1c)|*.q1c';");
			Dialog.DefaultExt = "q1c";
			Dialog.CheckFileExist = True;
			Dialog.Multiselect = False;
			
			BeginGettingFiles(GetFilesNotificationDescription, FilesToReceive, Dialog, True);
		EndIf;
	Else
		MessageToUser(NStr("ru = 'Без расширения для работы с 1С:Предприятием невозможно работать с файлами.';
									|en = 'To manage files, install 1C:Enterprise Extension.';"), "Object");
	EndIf;
	
EndProcedure

// Parameters:
//   Result - Array of File
//   AdditionalParameters - Structure
//
&AtClient
Procedure GettingFilesCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined And TypeOf(Result) = Type("Array") Then
		Modified = False;
		Object.FileName = Result[0].FullName;
	EndIf;
	
EndProcedure

&AtClient
Procedure FileReadingProcessing(ShouldDelete)
	
	AdditionalParameters = New Structure("ShouldDelete", ShouldDelete);
	
#If Not WebClient Then
		// Extension is always attached for thin, thick, and web clients.
		ReadFileEnd(True, AdditionalParameters);
		Return;
#EndIf
	
	Notification = New NotifyDescription("BeginAttachingFileSystemExtensionCompletion", ThisObject,
		New NotifyDescription("ReadFileEnd", ThisObject, AdditionalParameters));
	BeginAttachingFileSystemExtension(Notification);
	
EndProcedure

&AtClient
Procedure ReadFileEnd(Result, AdditionalParameters) Export
	
	If Result Then
		// Select a file to import.
		Dialog = New FileDialog(FileDialogMode.Open);
		Dialog.Title = NStr("ru = 'Выберите файл запросов';
								|en = 'Select query file';");
		Dialog.Preview = False;
		Dialog.Filter = NStr("ru = 'Файл запросов (*.q1c)|*.q1c';
							|en = 'Query file (*.q1c)|*.q1c';");
		Dialog.DefaultExt = "q1c";
		Dialog.CheckFileExist  = True;
		Dialog.Multiselect = False;
		
		AdditionalParameters = New Structure("ShouldDelete", AdditionalParameters.ShouldDelete);
		Notification = New NotifyDescription("PlacingFilesCompletion", ThisObject, AdditionalParameters);
		// ACC:1348-off - No need to call the "FileSystemClient" common module procedure.
		//                 The data processor can be used outside 1C:SSL.
		BeginPuttingFiles(Notification,, Dialog, True, UUID);
		// ACC:1348-on
	Else
		MessageToUser(NStr("ru = 'Без расширения для работы с 1С:Предприятием невозможно сохранять и загружать запросы в файл.';
									|en = 'To save and import queries to files, install 1C:Enterprise Extension.';"), "Object");
	EndIf;
	
EndProcedure

&AtClient
Procedure PlacingFilesCompletion(Result, AdditionalParameters) Export

	If TypeOf(Result) = Type("Array") Then
		If Result.Count() > 0 Then
			
			If AdditionalParameters.ShouldDelete Then
				Object.Queries.Clear();
				Object.Parameters.Clear();
			EndIf;
			
			FileName = Result[0].Name;
			ImportQueriesFromFile(Result[0].Location);
			Object.FileName = FileName;
		EndIf;
	EndIf;
	
	NumberOfRequests_ = Object.Queries.Count();
	If NumberOfRequests_ > 0 Then
		CurrentQueryID = Object.Queries.Get(0).Id;
		Modified = False;
		QueryPlanStorageAddress = Object.Queries.Get(0).QueryPlanStorageAddress;
		QueryAnalysisPerformed = QueryAnalysisPerformed(QueryPlanStorageAddress, QueryPlanUpToDate);
		SetShowQueryExecutionPlanLabelAppearance();
	Else
		Item = Object.Queries.Add();
		CurrentQueryID = New UUID;
		Item.Id = CurrentQueryID;
		Item.Name = DefaultQueryName;
		Result = New SpreadsheetDocument;
	EndIf;
	
	UpdateFormClient();
	
EndProcedure

&AtServer
Procedure ImportQueriesFromFile(AddressInTempStorage)
	
	BinaryData = GetFromTempStorage(AddressInTempStorage);
	ExternalDataProcessorObject = DataProcessorObject2().ReadQueriesFromXMLFile(BinaryData);
	FillQueriesAndParametersFromExternalDataProcessorObject(ExternalDataProcessorObject);
	OutputQueryResult();
	
EndProcedure

// Common save and import procedures

&AtClient
Procedure BeginAttachingFileSystemExtensionCompletion(ExtensionAttached, AdditionalParameters) Export
	
	If ExtensionAttached Then
		ExecuteNotifyProcessing(AdditionalParameters, True);
		Return;
	EndIf;
	
	If Not ExtensionInstallationPrompted Then
		ExtensionInstallationPrompted = True;
		NotifyDescriptionQuestion = New NotifyDescription("QueryAboutExtensionInstallation", ThisObject, AdditionalParameters);
		BeginInstallFileSystemExtension(NotifyDescriptionQuestion );
	Else
		ExecuteNotifyProcessing(AdditionalParameters, ExtensionAttached);
	EndIf;
	
EndProcedure

&AtClient
Procedure QueryAboutExtensionInstallation(Notification) Export
	
	ExecuteNotifyProcessing(Notification, True);
	
EndProcedure

&AtServer
Function SaveQueriesToTempStorage()
	
	BinaryData = SaveQueriesServer();
	Return PutToTempStorage(BinaryData);
	
EndFunction

// Populates queries and parameters from the external data processor object.
//
// Parameters:
//  DataProcessorObject2 - DataProcessorObject.QueryConsole - Data processor object.
//
&AtServer
Procedure FillQueriesAndParametersFromExternalDataProcessorObject(DataProcessorObject2)
	
	QueriesDP = DataProcessorObject2.Queries;
	ParametersDP = DataProcessorObject2.Parameters;
	
	Object.Queries.Clear();
	Object.Parameters.Clear();
	
	// Populate form queries and parameters.
	For Each CurrQuery In QueriesDP Do
		QueryItem                  = Object.Queries.Add();
		QueryItem.Id    = CurrQuery.Id;
		QueryItem.Name              = CurrQuery.Name;
		QueryItem.Text            = CurrQuery.Text;
		QueryItem.QueryPlanStorageAddress = CurrQuery.QueryPlanStorageAddress;
	EndDo;
	
	For Each CurParameter In ParametersDP Do
		StringType 	= CurParameter.Type;
		
		Value	= CurParameter.Value;
		Value    = ValueFromStringInternal(Value);
	
		If StringType = "ValueTable" Or StringType = "PointInTime" Or StringType = "Boundary" Then
			ParameterItem								= Object.Parameters.Add();
			ParameterItem.QueryID		= CurParameter.QueryID;
			ParameterItem.Id				= CurParameter.Id;
			ParameterItem.Name							= CurParameter.Name;
			ParameterItem.Type		 					= TypesList.FindByValue(StringType).Value;
			ParameterItem.Value 					= CurParameter.Value;
			ParameterItem.TypeInForm					= TypesList.FindByValue(StringType).Presentation;
			ParameterItem.ValueInForm				= DataProcessorObject2().GenerateValuePresentation(Value);
		Else
			Array 		= New Array;
			Array.Add(Type(StringType));
			LongDesc	= New TypeDescription(Array);
			
			ParameterItem								= Object.Parameters.Add();
			ParameterItem.QueryID		= CurParameter.QueryID;
			ParameterItem.Id				= CurParameter.Id;
			ParameterItem.Name							= CurParameter.Name;
			ParameterItem.Type 						= StringType;
			ParameterItem.TypeInForm					= LongDesc;
			ParameterItem.Value					= ValueToStringInternal(Value);
			ParameterItem.ValueInForm				= Value;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ParameterTypeAndValueInitialization(CurrentParameter, Current_Type)
	
	// Table type.
	StringType					= StringType(Current_Type.Value);
	CurrentParameter.Type 		= StringType;
	
	// Type in the form.
	Array = New Array;
	Array.Add(Type(CurrentParameter.Type));
	LongDesc = New TypeDescription(Array);
	
	CurrentParameter.TypeInForm 		= Current_Type.Presentation;
	
	// Value.
	Value						= LongDesc.AdjustValue(Type(Current_Type.Value));
	CurrentParameter.ValueInForm	= Value;   
	
	InterValue					= ValueToStringServer(Value);
	CurrentParameter.Value		= InterValue;
	
EndProcedure

&AtServer
Function GETParameterName()
	
	ParametersInForm = Object.Parameters;
	Flag = True;
	IndexOf = 0;
	
	While Flag Do
		Name = "Parameter" + String(Format(IndexOf, "NZ=-"));
		Name = StrReplace(Name, "-", "");
		Filter = New Structure("Name", Name);
		
		FilteredRows = ParametersInForm.FindRows(Filter);
		If FilteredRows.Count() = 0 Then
			Result = Name;
			Flag = False;
		EndIf;
		IndexOf = IndexOf+1;
	EndDo;
	
	Return Result;
	
EndFunction

// Displays a user message or warning.
//
// Parameters:
//  MessageText - String - Message text to pass.
//  DataPath - String - Path to the message data.
//
&AtClientAtServerNoContext
Procedure MessageToUser(MessageText, DataPath = "")
	
	Message = New UserMessage;
	Message.Text = MessageText;
	Message.DataPath = DataPath;
	Message.Message();
	
EndProcedure

&AtClient
Procedure FillParameters_Client()
	
	// WithCaptured current query from the query list.
	CurrentQueryIndex = CurrentQuestionIndex();
	If CurrentQueryIndex = Undefined Then
		MessageToUser(NStr("ru = 'Выберите запрос.';
									|en = 'Select query.';"), "Object");
		Return;
	EndIf;
	
	CurrentQuery = Object.Queries.Get(CurrentQueryIndex - 1);
	
	If Not IsBlankString(CurrentQuery.Text) Then
		Filter = New Structure;
		Filter.Insert("QueryID", CurrentQueryID);
		ParametersArray = Object.Parameters.FindRows(Filter);
		
		If ParametersArray.Count() > 0 Then
			Text = NStr("ru = 'Таблица параметров не пуста. Очистить таблицу?';
						|en = 'Parameter table is not blank. Clear table?';");
			NotifyDescription = New NotifyDescription("FillParameters_ClientCompletion", ThisObject, CurrentQuery);
			ShowQueryBox(NotifyDescription, Text, QuestionDialogMode.YesNo);
		Else
			FillParameters_ClientCompletion(DialogReturnCode.Yes, CurrentQuery);
		EndIf;
		
	Else
		ShowMessageBox(, NStr("ru = 'Текст запроса пустой.';
										|en = 'Query text is blank.';"));
	EndIf;
	
	Items.GroupParameters.Show();
	Items.GroupQueryResult.Hide();
	
EndProcedure

&AtClient
Procedure FillParameters_ClientCompletion(Response, CurrentQuery) Export
	
	ShouldDelete = (Response = DialogReturnCode.Yes);
	
	ReadQueryParameters(CurrentQuery.Text, ShouldDelete, CurrentQueryID);
	
	UpdateFormClient();
	
EndProcedure

&AtServer
Function GenerateListFormNameForRef(Ref)
	
	ListFormName = "";
	
	If Ref = Undefined Then
		Return ListFormName;
	EndIf;
	
	If IsReference(TypeOf(Ref)) Then
		ListFormName = Ref.Metadata().DefaultListForm.FullName();
	EndIf;
	
	Return ListFormName;
	
EndFunction

&AtServer
Procedure FillParametersOnQueryExecution(QueryText)
	
	// Read parameters from the query text to the structure array.
	ResultStructure = DataProcessorObject2().ReadQueryParameters(QueryText, CurrentQueryID);
	
	MessageOutputFlag = False;
	ParametersInForm = Object.Parameters;
	
	For Each ReadParameter In ResultStructure Do
		Filter = New Structure;
		Filter.Insert("QueryID", CurrentQueryID);
		ParametersArray = Object.Parameters.FindRows(Filter);
		
		ParameterFound = False;
		For IndexOf = 0 To ParametersArray.Count() - 1 Do
			If Lower(ParametersArray.Get(IndexOf).Name) = Lower(ReadParameter.Name) Then 
				ParameterFound = True;
			EndIf;
		EndDo;
		
		If Not ParameterFound Then
			If Not MessageOutputFlag Then
				MessageToUser(NStr("ru = 'Найденные параметры были добавлены автоматически.';
											|en = 'Found parameters were added automatically.';"), "Object");
				MessageOutputFlag = True;
			EndIf;
			AddParameterToForm(ParametersInForm, ReadParameter);
		EndIf;
	EndDo;
	
EndProcedure

// Copies parameters from the query with the current query ID.
//
// Parameters:
//  QueryUser - Structure - Query parameters are linked to.
//
&AtClient
Procedure CopyParametersFromQuery(QueryUser)
	
	QueryOptions = Object.Parameters;
	
	ParametersArray = New Array;
	
	For Each CurrentParameter In QueryOptions Do
		If CurrentParameter.QueryID <> CurrentQueryID Then
			Continue;
		EndIf;
		ParametersArray.Add(CurrentParameter);
	EndDo;
	
	ParametersCount1 = ParametersArray.Count();
	For IndexOf = 0 To ParametersCount1 - 1 Do
		ParameterItem 						= Object.Parameters.Add();
		ParameterItem.Id 			= New UUID;
		ParameterItem.QueryID 	= QueryUser.Id;
		ParameterDetails = ParametersArray.Get(IndexOf);
		ParameterItem.Name						= ParameterDetails.Name;
		ParameterItem.Type						= ParameterDetails.Type;
		ParameterItem.Value 				= ParameterDetails.Value;
		ParameterItem.TypeInForm 				= ParameterDetails.TypeInForm;
		ParameterItem.ValueInForm 			= ParameterDetails.ValueInForm;
	EndDo;
	
EndProcedure

// Generates a name of the query copy.
//
// Parameters:
//  Name - String - Query name to pass.
//
&AtClient
Function GenerateQueryCopyName(Name)
	
	Flag 	= True;
	IndexOf 	= 1;
	
	While Flag Do
		QueryNameToGenerate = NStr("ru = '%QueryName1% - Копия %CopyNumber%';
									|en = '%QueryName1% - Copy %CopyNumber%';");
		QueryNameToGenerate = StrReplace(QueryNameToGenerate, "%QueryName1%", Name);
		QueryNameToGenerate = StrReplace(QueryNameToGenerate, "%CopyNumber%", IndexOf);
		
		Filter = New Structure;
		Filter.Insert("Name", QueryNameToGenerate);
		
		QueriesByFilterArray = Object.Queries.FindRows(Filter);
		
		If QueriesByFilterArray.Count() = 0 Then 
			Flag = False;
		EndIf;
		
		IndexOf 	= IndexOf + 1;
	EndDo;
	
	Return QueryNameToGenerate;
	
EndFunction

//  Analyzes the form startup parameters. If necessary, configures the selection mode.
&AtServer
Procedure EnableChoiceMode()
	
	NewButton = Items.FormSelectQueryResult;
	NewButton.Visible   = Parameters.ChoiceMode;
	NewButton.Enabled = NewButton.Visible;
	
	If Not NewButton.Visible Then
		Return;
	EndIf;
	
	NewButton.DefaultButton = True;
	
	CloseOnChoice = Parameters.CloseOnChoice;
	If Not IsBlankString(Parameters.Title) Then
		Title = Parameters.Title;
	EndIf;
	
EndProcedure	

&AtServer
Function EnableQueryExecutionPlan()
	
	EnableResult = New Structure("Result, Cause", True, "");
	
	If ShowQueryExecutionPlanAvailable() Then
		TechnologicalLogParameters = New Structure("LogFilesDirectory, OSProcessID");
		DataProcessorObject2().EnableTechnologicalLog(TechnologicalLogParameters, EnableResult);
		If EnableResult.Result Then
			OSProcessID = TechnologicalLogParameters.OSProcessID;
			LogFilesDirectory = TechnologicalLogParameters.LogFilesDirectory;
		EndIf;
	Else
		EnableResult.Result = False;
		EnableResult.Cause = NStr("ru = 'Отображение плана выполнения запроса доступно только при работе на ОС Windows.';
											|en = 'Query plan can be displayed only when working on OS Windows.';");
	EndIf;
	
	Return EnableResult;
	
EndFunction

&AtServer
Procedure DisableQueryExecutionPlan(TechnologicalLogDisablingParameters, ChangeConfigurationFile)
	
	DataProcessorObject2().DisableTechnologicalLog(TechnologicalLogDisablingParameters, ChangeConfigurationFile);
	
EndProcedure

&AtServer
Function TechnologicalLogAvailable()
	
	ListOfFiles = FindFiles(LogFilesDirectory, "*.log", True);
	For Each File In ListOfFiles Do
		If StrFind(File.Path, "_" + OSProcessID) > 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Procedure CheckIfCanOpenTechnologicalLog()
	
	TechnologicalLogAvailable = TechnologicalLogAvailable();
	If TechnologicalLogAvailable Or QueryAnalysisPerformed Then
		
		Items.QueryPlanActivationDecoration.Visible = False;
		Items.ShowQueryExecutionPlanSkip.Visible = True;
		SetShowQueryExecutionPlanLabelAppearance();
		
		DetachIdleHandler("CheckIfCanOpenTechnologicalLog");
	Else
		Items.ShowQueryExecutionPlan.Enabled = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenQueryExecutionPlanForm()
	
	If ValueIsFilled(QueryMark) Or QueryAnalysisPerformed Then
		
		Filter = New Structure("Id", CurrentQueryID);
		Rows = Object.Queries.FindRows(Filter);
		If Rows.Count() > 0 Then 
			QueryName1 = Rows[0].Name;
		Else
			QueryName1 = "";
		EndIf;
		
		QueryAnalysisPerformed = True;
		SetShowQueryExecutionPlanLabelAppearance();
		
		QueryOptions = New Structure;
		QueryOptions.Insert("QueryMark", QueryMark);
		QueryOptions.Insert("LogFilesDirectory", LogFilesDirectory);
		QueryOptions.Insert("OSProcessID", OSProcessID);
		QueryOptions.Insert("QueryName1", QueryName1);
		QueryOptions.Insert("CurrentQueryID", CurrentQueryID);
		QueryOptions.Insert("QueryAnalysisPerformed", QueryAnalysisPerformed);
		QueryOptions.Insert("QueryPlanStorageAddress", QueryPlanStorageAddress);
		
		OpenForm(Object.PathToForms  + ".QueryExecutionPlan", QueryOptions, Object, True);
		
	EndIf;
	
EndProcedure

&AtServer
Function ShowQueryExecutionPlanAvailable()
	
	SystemInfo = New SystemInfo();
	If (SystemInfo.PlatformType = PlatformType.Windows_x86) Or (SystemInfo.PlatformType = PlatformType.Windows_x86_64) Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction 

&AtServer
Function IsReference(Type)
	
	Return Type <> Type("Undefined") 
		And (Catalogs.AllRefsType().ContainsType(Type)
		Or Documents.AllRefsType().ContainsType(Type)
		Or Enums.AllRefsType().ContainsType(Type)
		Or ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type)
		Or ChartsOfAccounts.AllRefsType().ContainsType(Type)
		Or ChartsOfCalculationTypes.AllRefsType().ContainsType(Type)
		Or BusinessProcesses.AllRefsType().ContainsType(Type)
		Or BusinessProcesses.RoutePointsAllRefsType().ContainsType(Type)
		Or Tasks.AllRefsType().ContainsType(Type)
		Or ExchangePlans.AllRefsType().ContainsType(Type));
	
EndFunction

&AtClient
Procedure AfterEnterUUID(Result, Parameter) Export
	
	UUIDParamaterValue = New UUID(Result);
	CurrentRow = Object.Parameters.FindByID(Parameter);
	CurrentRow.Value = ValueToStringServer(UUIDParamaterValue);
	CurrentRow.ValueInForm = UUIDParamaterValue;
	
EndProcedure

&AtClient
Procedure FillParametersFromXMLCompletion(XMLLine, Context) Export
	
	If TypeOf(XMLLine) <> Type("String") Or IsBlankString(XMLLine) Then
		Return;
	EndIf;
	Context.Insert("FromQueryText", True);
	FillParametersFromXMLServer(XMLLine, Context);
	
EndProcedure

&AtServer
Procedure FillParametersFromXMLServer(Val XMLLine, Val Context)
	
	XMLReader = New XMLReader;
	XMLReader.SetString(XMLLine);
	Try
		ParametersStructure = XDTOSerializer.ReadXML(XMLReader); // Query
	Except
		ErrorText = NStr("ru = 'Невозможно сформировать запрос из введенного XML, т.к. он, скорее всего некорректный.
		|Техническая информация: %1';
		|en = 'Cannot generate query from entered XML as it is most likely incorrect.
		|Technical information: %1';");
		MessageToUser(SubstituteParametersToString(ErrorText, ErrorProcessing.BriefErrorDescription(ErrorInfo())));
		Return;
	EndTry;
	
	If ParametersStructure.Count() <> 2
		Or Not ParametersStructure.Property("Text")
		Or Not ParametersStructure.Property("Parameters") Then
		Context.FromQueryText = False;
	EndIf;
	
	FoundItems = Object.Queries.FindRows(New Structure("Id", CurrentQueryID));
	CurrentQuery = FoundItems[0];
	
	If Context.FromQueryText Then
		CurrentQuery.Text = ParametersStructure.Text;
		CurrentQuery.Name   = GetQueryNameByForm(ThisObject, CurrentQuery.Text);
		QueryText.SetText(CurrentQuery.Text);
		ParametersStructure = ParametersStructure.Parameters
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("QueryID", CurrentQueryID);
	For Each KeyAndValue In ParametersStructure Do
		Filter.Insert("Name", KeyAndValue.Key);
		FoundItems = Object.Parameters.FindRows(Filter);
		If FoundItems.Count() = 0 Then
			QueryParameter = Object.Parameters.Add();
			QueryParameter.Name = Filter.Name;
			QueryParameter.Id = New UUID;
			QueryParameter.QueryID = CurrentQueryID;
		Else
			QueryParameter = FoundItems[0];
		EndIf;
		If TypeOf(KeyAndValue.Value) = Type("Array") Then
			Value = New ValueList;
			Value.LoadValues(KeyAndValue.Value);
			QueryParameter.Type = "ValueList";
		Else
			Value = KeyAndValue.Value;
			QueryParameter.Type = DataProcessorObject2().TypeNameFromValue(Value);
		EndIf;
		QueryParameter.Value = ValueToStringServer(Value);
		QueryParameter.ValueInForm = Value;
		QueryParameter.TypeInForm = String(TypeOf(Value));
	EndDo;
	
EndProcedure

// Returns a query name by the first table name.
//
// Parameters:
//   QueryText - String - Text of the query to pass.
//
&AtClientAtServerNoContext
Function GetQueryNameByForm(Form, Val QueryText)
	
	// If the query is empty, returns "Query".
	If IsBlankString(QueryText) Then
		Result = Form.DefaultQueryName;
		Return Result;
	EndIf;
	
	// Search for the reserved word "SELECT".
	Select = "SELECT"; // @query-part-1
	LengthSelect = StrLen(Select);
	PositionSELECT = StrFind(Upper(QueryText), Select);
	If PositionSELECT = 0 Then
		Result = Form.DefaultQueryName;
		Return Result;
	EndIf;
	
	// Slice of a query text line without the SELECT key.
	QueryText = Mid(QueryText, PositionSELECT + LengthSelect);
	
	// Search for the first dot to define a table name.
	Point = ".";
	LengthDot = StrLen(Point);
	PositionDot = StrFind(Upper(QueryText), Point);
	If PositionDot = 0 Then
		Result = Form.DefaultQueryName;
		Return Result;
	EndIf;
	
	// Returns "Query:" and the first table name.
	Result = TrimAll(Left(QueryText, PositionDot - LengthDot));
	If IsBlankString(Result) Then
		Result = Form.DefaultQueryName;
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function SubstituteParametersToString(Val SubstitutionString,
	Val Parameter1, Val Parameter2 = Undefined, Val Parameter3 = Undefined)
	
	SubstitutionString = StrReplace(SubstitutionString, "%1", Parameter1);
	SubstitutionString = StrReplace(SubstitutionString, "%2", Parameter2);
	SubstitutionString = StrReplace(SubstitutionString, "%3", Parameter3);
	
	Return SubstitutionString;
	
EndFunction

&AtClient
Procedure DisableGetQueryPlanInOtherFormsFlag()
	
	ShouldShowQueryExecutionPlan = False;
	AttachIdleHandler("CheckIfCanOpenTechnologicalLog", 3);
	
EndProcedure

&AtClientAtServerNoContext
Function QueryAnalysisPerformed(Address, QueryPlanUpToDate)
	
	If ValueIsFilled(Address) Then
		QueryPlanStructure = GetFromTempStorage(Address);
		If TypeOf(QueryPlanStructure) = Type("Structure") Then
			QueryPlanUpToDate = QueryPlanStructure.QueryPlanUpToDate;
			If QueryPlanStructure.DBMSType <> "" And  QueryPlanStructure.SQLQuery <> "" And QueryPlanStructure.QueryExecutionPlan <> "" Then
				Return True;
			EndIf;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Procedure SetShowQueryExecutionPlanLabelAppearance()
	
	If QueryAnalysisPerformed Then
		If QueryPlanUpToDate Then
			Items.ShowQueryExecutionPlan.Title = NStr("ru = 'Открыть';
																	|en = 'Open';");
		Else
			Items.ShowQueryExecutionPlan.Title = NStr("ru = 'Открыть (не актуален)';
																	|en = 'Open (irrelevant)';");
		EndIf;
		Items.ShowQueryExecutionPlan.Enabled = True;
	ElsIf TechnologicalLogAvailable And ShouldShowQueryExecutionPlan Then
		Items.ShowQueryExecutionPlan.Title = NStr("ru = 'Получить';
																|en = 'Get';");
		Items.ShowQueryExecutionPlan.Enabled = True;
	Else
		Items.ShowQueryExecutionPlan.Title = NStr("ru = 'Получить';
																|en = 'Get';");
		Items.ShowQueryExecutionPlan.Enabled = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure Enable_QueryExecutionPlanClient()
	
	EnableResult = EnableQueryExecutionPlan();
	If EnableResult.Result Then
		ShowUserNotification(NStr("ru = 'Показывать план выполнения запроса';
											|en = 'Show query plan';"), , NStr("ru = 'Включение анализа плана выполнения запроса занимает до одной минуты';
																								|en = 'Enabling query plan analysis takes up to one minute';"));
		Items.ShowQueryExecutionPlan.Enabled = False;
		Items.QueryPlanActivationDecoration.Visible = True;
		Items.ShowQueryExecutionPlanSkip.Visible = False;
		Notify("Enable_QueryExecutionPlan",, ThisObject);
		AttachIdleHandler("CheckIfCanOpenTechnologicalLog", 3);
	Else
		ShouldShowQueryExecutionPlan = False;
		ShowMessageBox(, EnableResult.Cause);
		TechnologicalLogAvailable = False;
	EndIf;

EndProcedure

&AtClient
Procedure DisableQueryExecutionPlanClient()
	
	DetachIdleHandler("CheckIfCanOpenTechnologicalLog");
	
	TechnologicalLogDisablingParameters = New Structure;
	TechnologicalLogDisablingParameters.Insert("LogFilesDirectory", LogFilesDirectory);
	TechnologicalLogDisablingParameters.Insert("EnabledDirectoriesRegistry", New Array);
	TechnologicalLogDisablingParameters.Insert("DeletedDirectoriesRegistry", New Array);
	
	DisableQueryExecutionPlan(TechnologicalLogDisablingParameters, True);
	
	Items.QueryPlanActivationDecoration.Visible = False;
	Items.ShowQueryExecutionPlanSkip.Visible = True;
	SetShowQueryExecutionPlanLabelAppearance();
	
	TechnologicalLogAvailable = False;
	Notify("DisableGetQueryPlanInOtherFormsFlag",, ThisObject);
	
	SupplementTechnologicalLogFilesToDelete(TechnologicalLogDisablingParameters.EnabledDirectoriesRegistry, TechnologicalLogDisablingParameters.DeletedDirectoriesRegistry);
	
	If TechnologicalLogDisablingParameters.DeletedDirectoriesRegistry.Count() > 0 Then
		TechnologicalLogFoldersToDelete = TechnologicalLogDisablingParameters.DeletedDirectoriesRegistry;
		TechnologicalLogFilesDeletionStartDate = CurrentSessionDateAtServer();
		ClearingTechnologicalLogFiles = True;
		Items.GetQueryExecutionPlan.Enabled = False;
		Items.QueryPlanActivationDecoration.Visible = True;
		Items.ShowQueryExecutionPlanSkip.Visible = False;
		Items.ShowQueryExecutionPlan.Title = NStr("ru = 'Очистка временных файлов';
																|en = 'Clearing temporary files';");
		Items.ShowQueryExecutionPlan.Enabled = False;
		AttachIdleHandler("CheckTechnologicalLogFilesDeletion", 3, True);
	EndIf
	
EndProcedure

&AtClient
Procedure CheckTechnologicalLogFilesDeletion()

	DeleteFoundTechnologicalLogFiles(TechnologicalLogFoldersToDelete);
	
	If CurrentSessionDateAtServer() - TechnologicalLogFilesDeletionStartDate > 90 Then
		TechnologicalLogFoldersToDelete = New Array;
	EndIf;
	
	If TechnologicalLogFoldersToDelete.Count() = 0 Then
		
		DetachIdleHandler("CheckTechnologicalLogFilesDeletion");
		
		Items.GetQueryExecutionPlan.Enabled = True;
		Items.QueryPlanActivationDecoration.Visible = False;
		Items.ShowQueryExecutionPlanSkip.Visible = True;
		SetShowQueryExecutionPlanLabelAppearance();
		ClearingTechnologicalLogFiles = False;
		
		If FormIsBeingClosed Then
			Close();
		EndIf;
	Else
		AttachIdleHandler("CheckTechnologicalLogFilesDeletion", 3, True);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure SupplementTechnologicalLogFilesToDelete(EnabledDirectoriesRegistry, DeletedDirectoriesRegistry)
	
	FilesFound = FindFiles(TempFilesDir(), "*.1c_logs", True);
	
	For Each FoundFile In FilesFound Do
		FileToDeleteName = Upper(FoundFile.FullName);
		
		If Not EnabledDirectoriesRegistry.Find(FileToDeleteName) = Undefined Then
			Continue;
		EndIf;
		
		If DeletedDirectoriesRegistry.Find(FileToDeleteName) = Undefined Then
			DeletedDirectoriesRegistry.Add(FileToDeleteName);
		EndIf;
	EndDo;

EndProcedure

&AtServerNoContext
Procedure DeleteFoundTechnologicalLogFiles(DirectoriesToDelete)

	SuccessfullyDeletedDirectories = New Array;
	
	For Each Directory In DirectoriesToDelete Do
		If StrFind(Upper(Directory), ".1C_LOGS") = 0
			Or StrFind(Upper(Directory), "\TEMP\") = 0 Then
			SuccessfullyDeletedDirectories.Add(Directory);
			Continue;
		EndIf;
		
		Try
			DeleteFiles(Directory);
		Except
			Continue;
		EndTry;
			
		SuccessfullyDeletedDirectories.Add(Directory);
	EndDo;
	
	For Each Directory In SuccessfullyDeletedDirectories Do
		FoundDirectoryIndex = DirectoriesToDelete.Find(Directory);
		DirectoriesToDelete.Delete(FoundDirectoryIndex);
	EndDo;

EndProcedure

&AtServerNoContext
Function CurrentSessionDateAtServer()

	Return CurrentSessionDate();

EndFunction
 

#EndRegion
