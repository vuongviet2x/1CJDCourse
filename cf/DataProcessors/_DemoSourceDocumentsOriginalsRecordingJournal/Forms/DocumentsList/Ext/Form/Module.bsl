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

	FillInResponsibleSelectionList();
	
	FillOriginalStateSelectionList();
	FilterState = (NStr("ru = '<Состояние известно>';
							|en = '<Known state>';"));

	ListDisplay = "ByDocuments";

	URL = "e1cib/app/DataProcessor._DemoSourceDocumentsOriginalsRecordingJournal";

	RestoreSettings();

	SetListSelections();
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.DocumentsListCommandBar;
	PlacementParameters.Sources = Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type;
    AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
    // End StandardSubsystems.AttachableCommands

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerListForm(ThisObject, Items.DocumentsList, Items.DocumentsListSum);
	SourceDocumentsOriginalsRecording.SetConditionalAppearanceInListForm(ThisObject, Items.DocumentsList);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	UsePeripherals = True;
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OnConnectBarcodeScanner(ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording

	SetSelectionByOriginalState();

EndProcedure

&AtClient
Procedure OnClose(Exit)

	If Not Exit Then
		ShouldSaveSettings();
	EndIf;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	If EventName = "AddDeleteSourceDocumentOriginalState" Then
		 FillOriginalStateSelectionList();
	 EndIf;	
	 
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.ProcessBarcode(Parameter,EventName);
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerListForm(EventName, ThisObject, Items.DocumentsList);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)

	SetListSelections()

EndProcedure

&AtClient
Procedure FilterChangeAuthorOnChange(Item)

	SetListSelections()

EndProcedure

&AtClient
Procedure ListDisplayOnChange(Item)

	DisplayingListWhenChangingOnServer();

EndProcedure

&AtClient
Procedure FilterStateStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;

	OpenForm("Catalog.SourceDocumentsOriginalsStates.Form.StateChoiceForm",New Structure("StatesList", FilterOriginalStates),Item);

EndProcedure

&AtClient
Procedure FilterStateChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	SetSelectionByOriginalState(ValueSelected);
	
EndProcedure

&AtClient
Procedure FilterStateClearing(Item, StandardProcessing)

	FilterOriginalStates.Clear();
	CommonClientServer.DeleteDynamicListFilterGroupItems(DocumentsList,"SourceDocumentOriginalState");
 
EndProcedure

&AtClient
Procedure HelpTextFilterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New NotifyDescription("SetSelectionByDocumentTypeCompletion", ThisObject);
	OpenForm("DataProcessor._DemoSourceDocumentsOriginalsRecordingJournal.Form.DocumentsKindsFilterSettingForm",New Structure("FilterDocumentsKinds",FilterDocumentsKinds),
		ThisObject,,,,Notification);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure DocumentsListSelection(Item, RowSelected, Field, StandardProcessing)

	StandardProcessing = False; 
	If Field.Name = "SourceDocumentOriginalState" Or Field.Name = "StateOriginalReceived" Then
		SourceDocumentsOriginalsRecordingClient.ListSelection(Field.Name, ThisObject, Items.DocumentsList,
			StandardProcessing);
	Else
		// Open document.
		OpenDocument();
	EndIf;

EndProcedure

&AtClient
Procedure DocumentsListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
    AttachableCommandsClient.StartCommandUpdate(ThisObject);
    // End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion


#Region FormCommandsEventHandlers

&AtClient
Procedure OpenDocumentCommand(Command)

	OpenDocument();

EndProcedure

&AtClient
Procedure SetDateInterval(Command)

	Dialog = New StandardPeriodEditDialog();
	Dialog.Period = Period;
	Dialog.Show(New NotifyDescription("SetDateIntervalCompletion", ThisObject, New Structure("Dialog", Dialog)));

EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export

	If Not ValueSelected = Undefined Then 	
		SetHeader(ValueSelected);
		Period = ValueSelected;
		SetSelectionByPeriod();
	EndIf;

EndProcedure

// StandardSubsystems.SourceDocumentsOriginalsRecording

// Parameters:
//  Command - FormCommand
//
&AtClient
Procedure Attachable_SetOriginalState(Command)
	
	SourceDocumentsOriginalsRecordingClient.SetOriginalState(Command.Name,ThisObject,Items.DocumentsList);

EndProcedure

&AtClient
Procedure Attachable_UpdateOriginalStateCommands()
	
	UpdateOriginalStateCommands()
   
EndProcedure

&AtServer
Procedure UpdateOriginalStateCommands()
	
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.DocumentsListCommandBar;
	PlacementParameters.Sources = Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type;
    AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
   
EndProcedure

//End StandardSubsystems.SourceDocumentsOriginalsRecording


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.DocumentsList);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.DocumentsList);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.DocumentsList);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject,
		"DocumentsList.IBDocumentDate",
		"DocumentsListIBDocumentDate");
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject,
		"DocumentsList.SourceDocumentDate",
		"DocumentsListSourceDocumentDate");

	Item = DocumentsList.ConditionalAppearance.Items.Add();

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use  = True;
	FilterGroup.GroupType  = DataCompositionFilterItemsGroupType.OrGroup;

	FilterElement = FilterGroup.Items.Add(Type("DataCompositionFilterItem")); 
	FilterElement.Use = True;
	FilterElement.LeftValue = New DataCompositionField("OverallState"); 
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;

	FilterElement = FilterGroup.Items.Add(Type("DataCompositionFilterItem")); 
	FilterElement.Use = True;
	FilterElement.LeftValue = New DataCompositionField("OverallState");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = True;

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("IndentField1");

	Item.Appearance.SetParameterValue("Visible", False);
	
	Item = DocumentsList.ConditionalAppearance.Items.Add();

	FilterElement = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("OverallState");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue =True;
	FilterElement.Use = True;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.AuxiliaryNavigationColor);

EndProcedure

&AtServer
Procedure SetHeader(ValueSelected)

	TitleText = Common.ListPresentation(Metadata.DataProcessors._DemoSourceDocumentsOriginalsRecordingJournal)+ " ";
	Values = New Structure("StartDate, EndDate",Format(ValueSelected.StartDate,NStr("ru = 'ДФ=dd.MM.yy';
																									|en = 'DF=MM/dd/yy';")), Format(ValueSelected.EndDate,NStr("ru = 'ДФ=dd.MM.yy';
																																										|en = 'DF=MM/dd/yy';")));
	If Not ValueIsFilled(ValueSelected) Then
		Title = TitleText;
	ElsIf Not ValueIsFilled(ValueSelected.StartDate) Then
		Title = TitleText +StringFunctionsClientServer.InsertParametersIntoString(NStr("ru = '(по [EndDate])';
																								|en = '(to [EndDate])';"), Values);
	ElsIf Not ValueIsFilled(ValueSelected.EndDate)Then
		Title = TitleText +StringFunctionsClientServer.InsertParametersIntoString(NStr("ru = '(с [StartDate])';
																								|en = '(from [StartDate])';"), Values);
	ElsIf ValueSelected.Variant = StandardPeriodVariant.Today Or ValueSelected.Variant = StandardPeriodVariant.Yesterday 
		Or  ValueSelected.Variant = StandardPeriodVariant.Tomorrow Then
		Title = TitleText +StringFunctionsClientServer.InsertParametersIntoString(NStr("ru = '([StartDate])';
																								|en = '([StartDate])';"), Values);
	Else
		Title = TitleText +StringFunctionsClientServer.InsertParametersIntoString(NStr("ru = '(с [StartDate] по [EndDate])';
																								|en = '(from [StartDate] to [EndDate])';"), Values);
	EndIf;

EndProcedure

&AtServer
Procedure RestoreSettings()

	Settings = Common.CommonSettingsStorageLoad("DataProcessor._DemoSourceDocumentsOriginalsRecordingJournal.Form.Form", "SourceDocumentOriginals");

	If TypeOf(Settings) = Type("Structure") Then
		FilterDocumentsKinds = Settings.FilterDocumentsKinds;
		FilterOrganization = Settings.FilterOrganization;
		FilterChangeAuthor = Settings.FilterChangeAuthor;
		FilterState = Settings.FilterState;
		DocumentsCount = Settings.DocumentsCount;
		PastSelectionOfOriginalState = Settings.FilterOriginalStates; 
		ListDisplay = Settings.ListDisplay;

		// Restore filter list by state.
		If ValueIsFilled(PastSelectionOfOriginalState) Then
			For Each State In PastSelectionOfOriginalState Do
				FilterOriginalStates.Add(State.Value);
			EndDo;
		EndIf;
	
	Else// If no saved settings are present, then populate the filter list by document type.
		FillInitialSelectionListOfDocumentTypes();
		FilterState = NStr("ru = '<Состояние известно>';
								|en = '<Known state>';");		
	EndIf;

EndProcedure

&AtServer
Procedure ShouldSaveSettings()

	AttributesToSaveNames =
		"FilterDocumentsKinds,
		|FilterOrganization,
		|FilterChangeAuthor,
		|FilterState,
		|DocumentsCount,
		|FilterOriginalStates,
		|ListDisplay";

	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisForm);

	Common.CommonSettingsStorageSave("DataProcessor._DemoSourceDocumentsOriginalsRecordingJournal.Form.Form", "SourceDocumentOriginals",Settings);

EndProcedure

&AtClient
Procedure OpenDocument()

	If Items.DocumentsList.SelectedRows = Undefined Then
		ShowMessageBox(, NStr("ru = 'Не выделено ни одного документа.';
										|en = 'No document is selected.';"));
		Return;
	EndIf;
		
	For Each ListLine In Items.DocumentsList.SelectedRows Do
		Document = Items.DocumentsList.RowData(ListLine);
		ShowValue(,Document.Ref);
	EndDo;

EndProcedure

#Region Filters

&AtServer
Procedure FillInResponsibleSelectionList()

	SetPrivilegedMode(True);

	UsersArray = InfoBaseUsers.GetUsers();

	Items.FilterChangeAuthor.ChoiceList.Clear();
	Items.FilterChangeAuthor.ChoiceList.Add(Users.CurrentUser(),NStr("ru = '<Мои записи>';
																								|en = '<My records>';"));

	For Each User In UsersArray Do

		If User.Roles.Contains(Metadata.Roles.SourceDocumentsOriginalsStatesChange) 
			And Not Users.CurrentUser() = Users.FindByName(User.Name) Then
			FoundUser =Users.FindByName(User.Name);
			Items.FilterChangeAuthor.ChoiceList.Add(FoundUser);
		EndIf;

	EndDo;

	SetPrivilegedMode(False);

EndProcedure

&AtServer
Procedure FillOriginalStateSelectionList()

	OriginalStates = SourceDocumentsOriginalsRecording.AllStates();
	
	Items.FilterState.ChoiceList.Clear();
	For Each State In OriginalStates Do
		Items.FilterState.ChoiceList.Add(State);
	EndDo;
	Items.FilterState.ChoiceList.Add("Statesknown",NStr("ru = '<Состояние известно>';
																			|en = '<Known state>';"));
	Items.FilterState.ChoiceList.Add("Statesnotable",NStr("ru = '<Состояние неизвестно>';
																			|en = '<Unknown state>';"));
	
EndProcedure

&AtServer
Procedure FillInitialSelectionListOfDocumentTypes() 

	DocumentsKindsTable.Clear();

	AvailableTypes = Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type.Types();
	DocumentNames = New Array;
	For Each Type In AvailableTypes Do
		If Type = Type("CatalogRef.MetadataObjectIDs") Then
			Continue;
		EndIf;
		DocumentType = Metadata.FindByType(Type);
		DocumentNames.Add(DocumentType.FullName());
	EndDo;
	
	Query = New Query;
	Query.Text = "SELECT
	               |	MetadataObjectIDs.FullName AS FullName,
	               |	MetadataObjectIDs.Synonym AS Synonym,
	               |	MetadataObjectIDs.Ref AS Ref
	               |FROM
	               |	Catalog.MetadataObjectIDs AS MetadataObjectIDs
	               |WHERE
	               |	MetadataObjectIDs.FullName IN(&DocumentNames)";
	Query.SetParameter("DocumentNames",DocumentNames);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Filter = New Structure("Presentation", Selection.Synonym);
		FoundRows = DocumentsKindsTable.FindRows(Filter);
		If FoundRows.Count()= 0 Then
			NewRow = DocumentsKindsTable.Add();
			NewRow.DocumentKind = Selection.Ref;
			NewRow.Presentation = Selection.Synonym;
			NewRow.Filter = True;
		EndIf;
	EndDo;

	DocumentsCount = DocumentsKindsTable.Count();

EndProcedure

&AtServer
Procedure SetListSelections()

	CommonClientServer.SetDynamicListFilterItem(DocumentsList,"Organization",FilterOrganization,
		DataCompositionComparisonType.Equal,,ValueIsFilled(FilterOrganization));

	CommonClientServer.SetDynamicListFilterItem(DocumentsList,"ChangeAuthor",FilterChangeAuthor,
		DataCompositionComparisonType.Equal,,ValueIsFilled(FilterChangeAuthor));

	SetSelectionByDocumentType(FilterDocumentsKinds);
	
	DisplayingListWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure SetSelectionByDocumentTypeCompletion(Result, AdditionalParameters = Undefined) Export
	
	SetSelectionByDocumentType(Result);
	
EndProcedure	
	
&AtServer
Procedure SetSelectionByDocumentType(Result)

	CommonClientServer.DeleteDynamicListFilterGroupItems(DocumentsList,"RefType");
	
	If ValueIsFilled(Result) Then
		If TypeOf(Result) = Type("Structure") Then 
			Array = New Array;
			DocumentsCount = Result.DocumentsCount;
			For Each Filter In Result.FilterDocumentsKinds Do
				Array.Add(Filter.Value);
			EndDo;
		Else			
			Array = New Array;
			For Each Filter In Result Do
				Array.Add(Filter.Value);
			EndDo;
		EndIf;
		
		FilterDocumentsKinds.LoadValues(Array);
				
		CommonClientServer.SetDynamicListFilterItem(DocumentsList,"RefType",FilterDocumentsKinds,
			DataCompositionComparisonType.InList,,True);

		If FilterDocumentsKinds.Count() = DocumentsCount Or FilterDocumentsKinds.Count()= 0 Then
			Items.HelpTextFilter.Title = StringFunctions.FormattedString(NStr("ru = 'Показаны все документы журнала <a href=""%1"">Настроить</a>';
																										|en = 'All log documents are shown <a href=""%1"">Configure</a>';"),"ConfigureFilter");
		Else	
			LabelText = StringFunctionsClientServer.StringWithNumberForAnyLanguage(NStr("ru = ';Показан %1 документ журнала;;
			|Показано %1 документа журнала;Показано %1 документов журнала;';
			|en = ';%1 log document is shown;;;;
			|%1 log documents are shown';"),FilterDocumentsKinds.Count());
			Items.HelpTextFilter.Title = StringFunctions.FormattedString(LabelText + " " +NStr("ru = '<a href=""%1"">Настроить</a>';
																															|en = '<a href=""%1"">Configure</a>';"),"ConfigureFilter");	
		EndIf;

	Else
		If Not DocumentsKindsTable.Count() = 0 Then
			Array = New Array;
			For Each Filter In DocumentsKindsTable Do
				Array.Add(Filter.DocumentKind);
			EndDo;
		FilterDocumentsKinds.LoadValues(Array);		
		
		Items.HelpTextFilter.Title = StringFunctions.FormattedString(NStr("ru = 'Показаны все документы журнала <a href=""%1"">Настроить</a>';
																									|en = 'All log documents are shown <a href=""%1"">Configure</a>';"),"ConfigureFilter");

		CommonClientServer.SetDynamicListFilterItem(DocumentsList,"RefType",FilterDocumentsKinds,
			DataCompositionComparisonType.InList,,True);

		EndIf;
	EndIf;

	
EndProcedure

&AtClient
Procedure SetSelectionByOriginalState(ValueSelected = Undefined) 	

	FilterState = "";

	If ValueSelected=Undefined And FilterOriginalStates.Count()>1 Then 
		For Each State In FilterOriginalStates Do
			If State.Value = "Statesnotable" Then
				Unknowns = True;
			EndIf;
			FilterState = FilterState + ?(ValueIsFilled(FilterState), ", ", "")+ State.Value;
		EndDo;
			
	ElsIf ValueSelected=Undefined And FilterOriginalStates.Count()=1 Then
		FilterState = FilterOriginalStates[0].Value;
		If FilterOriginalStates[0].Value = "Statesnotable" Then
			CommonClientServer.SetDynamicListFilterItem(DocumentsList,"SourceDocumentOriginalState",,
				DataCompositionComparisonType.NotFilled,,ValueIsFilled(FilterState));
			Return;
		EndIf;
		
	ElsIf TypeOf(ValueSelected) = Type("ValueList") Then
		FilterOriginalStates.Clear();
		CheckingForAllEmptyMarks = 0;
		For Each State In ValueSelected Do
			If State.Check Then
				If State.Value = "Statesnotable" Then
					Unknowns = True;
					FilterOriginalStates.Add(State.Value);
					FilterState = FilterState + ?(ValueIsFilled(FilterState), ", ", "")+ State.Presentation;
				Else
					FilterOriginalStates.Add(State.Value);
					FilterState = FilterState + ?(ValueIsFilled(FilterState), ", ", "")+ State.Value;
				EndIf;
			Else
				CheckingForAllEmptyMarks = CheckingForAllEmptyMarks + 1; 
			EndIf;
			
		EndDo;
		If CheckingForAllEmptyMarks = ValueSelected.Count() Then
			Unknowns = True;
			For Each State In ValueSelected Do
				FilterOriginalStates.Add(State.Value);
			EndDo;
		EndIf;
	Else 
		FilterOriginalStates.Clear();
		If Not ValueSelected=Undefined Then
			If ValueSelected = "Statesnotable" Then
				FilterState = NStr("ru = '<Состояние неизвестно>';
										|en = '<Unknown state>';");
			ElsIf ValueSelected = "Statesknown" Then
				FilterState = NStr("ru = '<Состояние известно>';
										|en = '<Known state>';");
			Else
				FilterState = ValueSelected;
			EndIf;
		EndIf;
		
		FilterOriginalStates.Add(ValueSelected);
		If ValueSelected = "Statesnotable" Or FilterState = "Statesnotable" Then
			CommonClientServer.SetDynamicListFilterItem(DocumentsList,"SourceDocumentOriginalState",,
				DataCompositionComparisonType.NotFilled,,ValueIsFilled(FilterState));
			Return;
		ElsIf ValueSelected = "Statesknown" Or FilterState = "Statesknown" Then
				CommonClientServer.SetDynamicListFilterItem(DocumentsList,"SourceDocumentOriginalState",,
			DataCompositionComparisonType.Filled,,ValueIsFilled(FilterState));
			Return;
		EndIf;
	EndIf;

	If Unknowns = True Then
		
		CommonClientServer.DeleteDynamicListFilterGroupItems(DocumentsList,"SourceDocumentOriginalState");
		
		FilterGroup = DocumentsList.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.Use  = True;
		FilterGroup.GroupType  = DataCompositionFilterItemsGroupType.OrGroup;
		
		FilterElement = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.Use = True;
		FilterElement.LeftValue = New DataCompositionField("SourceDocumentOriginalState"); 
		FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;

		FilterElement = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.Use = True;
		FilterElement.LeftValue = New DataCompositionField("SourceDocumentOriginalState");
		FilterElement.ComparisonType = DataCompositionComparisonType.InList;
		FilterElement.RightValue = FilterOriginalStates;
		
	ElsIf ValueIsFilled(FilterState) Then
		CommonClientServer.SetDynamicListFilterItem(DocumentsList,"SourceDocumentOriginalState",FilterOriginalStates,
			DataCompositionComparisonType.InList,,ValueIsFilled(FilterState));	
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayingListWhenChangingOnServer()

	// Reset the filter by common state.
	CommonClientServer.DeleteDynamicListFilterGroupItems(DocumentsList,"OverallState");

	If ListDisplay = "ByDocuments" Then
		
		FilterGroup = DocumentsList.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.Use  = True;
		FilterGroup.GroupType  = DataCompositionFilterItemsGroupType.OrGroup;
		
		// Set a filter to display the list by document.
		FilterElement = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.Use = True;
		FilterElement.LeftValue = New DataCompositionField("OverallState"); 
		FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;

		FilterElement = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.Use = True;
		FilterElement.LeftValue = New DataCompositionField("OverallState");
		FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
		FilterElement.RightValue = True;

		Items.IndentField1.Visible = False;
		Items.SourceDocumentPresentation.Visible = False;

	ElsIf ListDisplay = "OnPrintedForms" Then
		Items.IndentField1.Visible = True;
		Items.SourceDocumentPresentation.Visible = True;
	EndIf;

EndProcedure

&AtServer
Procedure SetSelectionByPeriod()

	DocumentsList.Parameters.SetParameterValue("BeginOfPeriod",Period.StartDate);

	DocumentsList.Parameters.SetParameterValue("EndOfPeriod",Period.EndDate);

EndProcedure

#EndRegion

#EndRegion
