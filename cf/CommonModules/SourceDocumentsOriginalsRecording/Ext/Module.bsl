///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

#Region FormsEventsHandlers

// Handler of the "OnCreateAtServer" document form event.
//
// Parameters:
//  Form - ClientApplicationForm:
//   * Object - FormDataStructure, DocumentObject - Form's main attribute.
//  Placement - FormGroup - a group where a label with the current original state will be located.
//		           If Undefined, the label will be located in the lower right corner of the form. Optional. 
//
Procedure OnCreateAtServerDocumentForm(Form, Placement = Undefined) Export

	If GetFunctionalOption("UseSourceDocumentsOriginalsRecording") = False
	Or Not AccessRight("Read",Metadata.InformationRegisters.SourceDocumentsOriginalsStates) Then
		DecorationToDisable = Form.Items.Find("OriginalStateDecoration");
		If Not DecorationToDisable = Undefined Then
			DecorationToDisable.Visible = False;
		EndIf;
		Return;
	EndIf;
	
	Attributes = New Array;
	Attributes.Add(New FormAttribute("OriginalStatesChoiceList", New TypeDescription("ValueList")));
	
	Form.ChangeAttributes(Attributes);

	OriginalsStates = UsedStates();
	
	FillOriginalStatesChoiceList(Form, OriginalsStates);
	
	If Placement = Undefined Then
		Parent = Form;
	Else
		Parent = Placement;
	EndIf;
	
	OriginalStateDecoration = Form.Items.Add("OriginalStateDecoration", Type("FormDecoration"), Parent);
	OriginalStateDecoration.Type = FormDecorationType.Label;
	OriginalStateDecoration.Hyperlink = True;
	If Placement = Undefined Then
		OriginalStateDecoration.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
	EndIf;
	OriginalStateDecoration.SetAction("Click", "Attachable_OriginalStateDecorationClick");

	If ValueIsFilled(Form.Object.Ref) Then
		CurrentOriginalState = OriginalStateInfoByRef(Form.Object.Ref);
		If CurrentOriginalState.Count() = 0 Then
			CurrentOriginalState=NStr("ru = '<Состояние оригинала неизвестно>';
											|en = '<Original state is unknown>';");
			OriginalStateDecoration.TextColor = StyleColors.InaccessibleCellTextColor;
		Else
			CurrentOriginalState = CurrentOriginalState.SourceDocumentOriginalState;
		EndIf;
	Else
		CurrentOriginalState=NStr("ru = '<Состояние оригинала неизвестно>';
										|en = '<Original state is unknown>';");
		OriginalStateDecoration.TextColor = StyleColors.InaccessibleCellTextColor;
	EndIf;

	OriginalStateDecoration.Title = CurrentOriginalState;

EndProcedure

// Handler of the "OnCreateAtServer" list form event.
//
// Parameters:
//  Form - ClientApplicationForm - a document list form.
//  List - FormTable - the main form list.
//  Placement - FormField - a list column next to which new columns of states will be located.
//		                       If Undefined, the columns will be located at the end of the list. Optional.
//
Procedure OnCreateAtServerListForm(Form, List, Placement = Undefined) Export

	If GetFunctionalOption("UseSourceDocumentsOriginalsRecording") = False 
	Or Not AccessRight("Read",Metadata.InformationRegisters.SourceDocumentsOriginalsStates) Then
		ColumnToDisable = Form.Items.Find("StateOriginalReceived");
		If Not ColumnToDisable = Undefined Then
			ColumnToDisable.Visible = False;
		EndIf;
		Return;
	EndIf;
	
	// Create columns in the dynamic list.
	PropsListStatusReceived = Form.Items.Insert("StateOriginalReceived",Type("FormField"),List,Placement);
	PropsListStatusReceived.Type = FormFieldType.PictureField;
	PropsListStatusReceived.TitleLocation = FormItemTitleLocation.None; 
	PropsListStatusReceived.ValuesPicture = PictureLib.IconsCollectionSourceDocumentOriginalAvailable;
	PropsListStatusReceived.HeaderPicture = PictureLib.SourceDocumentOriginalStateOriginalReceived;
	PropsListStatusReceived.Title = NStr("ru = 'Состояние оригинал получен';
													|en = 'Status ""Hard copy received""';");
	PropsListStatusReceived.DataPath = List.Name + ".StateOriginalReceived";
	
	AttributeListState = Form.Items.Insert("SourceDocumentOriginalState",Type("FormField"),List,Placement);
	AttributeListState.Type = FormFieldType.LabelField;
	AttributeListState.CellHyperlink = True; 
	AttributeListState.Title = NStr("ru = 'Состояние оригинала';
											|en = 'Original state';");
	AttributeListState.DataPath = List.Name + ".SourceDocumentOriginalState";
	
	If Not RightsToChangeState() Then
		PropsListStatusReceived.Enabled = False;
		AttributeListState.Enabled = False;
		Return;
	EndIf;
	
	// Create a list.
	Attributes = New Array;
	Attributes.Add(New FormAttribute("OriginalStatesChoiceList", New TypeDescription("ValueList")));	
	Form.ChangeAttributes(Attributes);
	
	OriginalsStates = UsedStates();
	
	If Not Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		OutputOriginalStateCommandsToForm(Form, List, OriginalsStates);
	EndIf;

	FillOriginalStatesChoiceList(Form, OriginalsStates);

EndProcedure

// Handler of the "OnGetDataAtServer" list form event.
//
// Parameters:
//  ListRows - DynamicListRows - Document list rows.
//
Procedure OnGetDataAtServer(ListRows) Export
	
	If GetFunctionalOption("UseSourceDocumentsOriginalsRecording") = False 
	Or Not AccessRight("Read",Metadata.InformationRegisters.SourceDocumentsOriginalsStates) Then
		Return;
	EndIf;
	
	References = New Array;
	KeyFieldName = "Ref";
	 
	For Each ListLine In ListRows Do
		ListLine = ListRows[ListLine.Key]; 
		If Not ListLine.Data.Property("Ref")
			Or (ListLine.Appearance.Get("SourceDocumentOriginalState") = Undefined 
			And ListLine.Appearance.Get("StateOriginalReceived") = Undefined) Then
			Return;
		EndIf;
		References.Add(ListLine.Data[KeyFieldName]);
	EndDo;
	
	Query = New Query;
	Query.Text = "SELECT
	               |	SourceDocumentsOriginalsStates.State AS SourceDocumentOriginalState,
	               |	SourceDocumentsOriginalsStates.OverallState AS OverallState,
	               |	CASE
	               |		WHEN SourceDocumentsOriginalsStates.State = VALUE(Catalog.SourceDocumentsOriginalsStates.OriginalReceived)
	               |			THEN 1
	               |		ELSE 0
	               |	END AS StateOriginalReceived,
	               |	SourceDocumentsOriginalsStates.Owner AS Ref
	               |FROM
	               |	InformationRegister.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
	               |WHERE
	               |	SourceDocumentsOriginalsStates.OverallState
	               |	AND SourceDocumentsOriginalsStates.Owner IN(&Ref)"; 

	Query.SetParameter("Ref", References);
	
	ColorOfHyperlink = StyleColors.HyperlinkColor;
	InactiveHyperlinkColor = StyleColors.InaccessibleCellTextColor;
	
	Selection = Query.Execute().Select();
	If Not ListLine.Appearance.Get("SourceDocumentOriginalState") = Undefined Then
		For Each String In ListRows Do
			String = ListRows[String.Key];
			Selection.Reset();
			If Selection.FindNext(String.Data["Ref"], "Ref") Then 
				
				String.Data["SourceDocumentOriginalState"] = Selection.SourceDocumentOriginalState;
				String.Appearance["SourceDocumentOriginalState"].SetParameterValue("TextColor", ColorOfHyperlink);
			Else
				String.Data["SourceDocumentOriginalState"] = NStr("ru = '<Неизвестно>';
																				|en = '<Unknown>';");
				String.Appearance["SourceDocumentOriginalState"].SetParameterValue("TextColor", InactiveHyperlinkColor);
			EndIf;
		EndDo;
	EndIf;
	
	If Not ListLine.Appearance.Get("StateOriginalReceived") = Undefined Then
		For Each String In ListRows Do
			String = ListRows[String.Key];
			Selection.Reset();
			If Selection.FindNext(String.Data["Ref"], "Ref") Then 
				String.Data["StateOriginalReceived"] = Selection.StateOriginalReceived;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

// Updates commands that set the original state on the list form.
//
// Parameters:
//  Form - ClientApplicationForm - a document list form.
//  List - FormTable - the main form list.
//
Procedure UpdateOriginalStateCommands(Form, List) Export

	OriginalsStates = UsedStates();

	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		SetConfigureOriginalStateSubmenu = Form.Items.Find("SetConfigureOriginalStateSubmenuNormal");		
		If Not SetConfigureOriginalStateSubmenu = Undefined Then
			Form.Items.Delete(SetConfigureOriginalStateSubmenu);
		EndIf;
		
		SetConfigureOriginalStateSubmenu = Form.Items.Find("SetConfigureOriginalStateSubmenuSeeAlso");		
		If Not SetConfigureOriginalStateSubmenu = Undefined Then
			Form.Items.Delete(SetConfigureOriginalStateSubmenu);
		EndIf;
	EndIf;
	
	OutputOriginalStateCommandsToForm(Form, List, OriginalsStates);

	FillOriginalStatesChoiceList(Form, OriginalsStates);

EndProcedure

// Sets conditional formatting for attachable items in the list.
//
// Parameters:
//  Form - ClientApplicationForm - a document list form.
//  List - FormTable - the main form list.
//
Procedure SetConditionalAppearanceInListForm(Form, List) Export

	AppearanceItem = Form.ConditionalAppearance.Items.Add();

	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField(List.Name+".SourceDocumentOriginalState"); 
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	FilterElement.Use = True;

	AppearanceItem.Appearance.SetParameterValue("Text", NStr("ru = '<Неизвестно>';
																			|en = '<Unknown>';"));
	AppearanceItem.Appearance.SetParameterValue("TextColor",  StyleColors.InaccessibleCellTextColor);
	AppearanceItem.Use = True;
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("SourceDocumentOriginalState");
	AppearanceField.Use = True;
	
	AppearanceItem = Form.ConditionalAppearance.Items.Add();

	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField(List.Name+".SourceDocumentOriginalState"); 
	FilterElement.ComparisonType = DataCompositionComparisonType.Filled;
	FilterElement.Use = True;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	AppearanceItem.Use = True;

	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("SourceDocumentOriginalState");
	AppearanceField.Use = True;

EndProcedure

// Adds a role that changes the original state to the profile details of 1C-supplied access groups. 
//
// Parameters:
//  ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription
//
Procedure SupplementProfileWithRoleForDocumentsOriginalsStatesChange(ProfileDetails) Export

	ProfileDetails.Roles.Add("SourceDocumentsOriginalsStatesChange");

EndProcedure

// Adds a role that configures the list of original states to the profile details of 1C-supplied access groups.
//
// Parameters:
//  ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription.
//  
Procedure SupplementProfileWithRoleForDocumentsOriginalsStatesSetup(ProfileDetails) Export

	ProfileDetails.Roles.Add("AddEditSourceDocumentsOriginalsStates");

EndProcedure

// Adds a role that reads the original state to the profile details of 1C-supplied access groups.
//
// Parameters:
//  ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription.
//
Procedure SupplementProfileWithRoleForDocumentsOriginalsStatesReading(ProfileDetails) Export

	ProfileDetails.Roles.Add("ReadSourceDocumentsOriginalsStates");

EndProcedure

// Returns an array of source document states.
//
//	Returns:
//  Array of CatalogRef.SourceDocumentsOriginalsStates - all possible original states, including
//    the hidden "Not all originals" state.
//
Function AllStates() Export
	
	Query = New Query;
	Query.Text ="SELECT ALLOWED
	              |	SourceDocumentsOriginalsStates.Ref AS State
	              |FROM
	              |	Catalog.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
	              |WHERE
	              |	NOT SourceDocumentsOriginalsStates.DeletionMark
	              |
	              |ORDER BY
	              |	SourceDocumentsOriginalsStates.AddlOrderingAttribute" ;

	Selection = Query.Execute();

	Return Selection.Unload().UnloadColumn("State");

EndFunction

// Displays attachable commands in the form. Called without implementing the "Attachable commands" subsystem.
//
// Parameters:
//  Form - ClientApplicationForm - a document list form.
//  List - FormTable - the main form list.
//  OriginalsStates - ValueTable - original states available to users and used when changing
//                                          the original state:
//              * Description 	- String - The name of the source document state.
//              * Ref		- CatalogRef.SourceDocumentsOriginalsStates
//
Procedure OutputOriginalStateCommandsToForm(Form, List, OriginalsStates) Export

	// Check and create a submenu and button list on the list command panel.
	Items = Form.Items;

	If Items.Find("SetConfigureOriginalStateSubmenu") = Undefined Then
		SetConfigureOriginalStateSubmenu = Items.Add("SetConfigureOriginalStateSubmenu", 
			Type("FormGroup"), List.CommandBar);
		SetConfigureOriginalStateSubmenu.Type = FormGroupType.Popup;
		SetConfigureOriginalStateSubmenu.Representation = ButtonRepresentation.Picture; 
		SetConfigureOriginalStateSubmenu.Picture = PictureLib.SetSourceDocumentOriginalState;
		SetConfigureOriginalStateSubmenu.Title = NStr("ru = 'Установить состояние оригинала';
																		|en = 'Set original state';");
		SetConfigureOriginalStateSubmenu.ToolTip = NStr("ru = 'Подменю команд для установки и изменения состояния оригиналов первичных документов.';
																		|en = 'Use these commands to set and change states of source document originals.';");
	EndIf;
	SetConfigureOriginalStateSubmenu = Items.Find("SetConfigureOriginalStateSubmenu");
	
	If Items.Find("SetOriginalStateGroup") = Undefined Then
		SetOriginalStateGroup = Items.Add("SetOriginalStateGroup", Type("FormGroup"),
			SetConfigureOriginalStateSubmenu);
		SetOriginalStateGroup.Type = FormGroupType.ButtonGroup;
	EndIf;
	SetOriginalStateGroup = Items.Find("SetOriginalStateGroup");

	If Items.Find("ConfigureOriginalStatesGroup") = Undefined Then
		ConfigureOriginalStatesGroup = Items.Add("ConfigureOriginalStatesGroup", Type("FormGroup"),
			SetConfigureOriginalStateSubmenu);
		ConfigureOriginalStatesGroup.Type = FormGroupType.ButtonGroup;
	EndIf;
	ConfigureOriginalStatesGroup = Items.Find("ConfigureOriginalStatesGroup");

	If Items.Find("SetOriginalReceivedGroup") = Undefined Then
		SetOriginalReceivedGroup =  Items.Add("SetOriginalReceivedGroup", Type("FormGroup"), 
			List.CommandBar); 
		SetOriginalReceivedGroup.Type = FormGroupType.ButtonGroup;
		SetOriginalReceivedGroup.ToolTip = NStr("ru = 'Установить конечное состояние оригинала первичного документа ""Оригинал получен"".';
														|en = 'Set the final ""Original received"" state of the source document original.';");
	EndIf;
	SetOriginalReceivedGroup = Items.Find("SetOriginalReceivedGroup");
	
	For Each State In SetOriginalStateGroup.ChildItems Do
		FoundCommand = Form.Commands.Find(State.CommandName);
		FoundButton = Form.Items.Find(State.CommandName);

		If Not FoundCommand = Undefined Then
			Form.Commands.Delete(FoundCommand);
			Form.Items.Delete(FoundButton);
		EndIf;			
	EndDo;
	
	// Remove the latest button.
	If SetOriginalStateGroup.ChildItems.Count() > 0 Then 
		State = SetOriginalStateGroup.ChildItems[0];
		FoundCommand = Form.Commands.Find(State.CommandName);
		FoundButton = Form.Items.Find(State.CommandName);
	EndIf;
	
	If Not FoundCommand = Undefined Then
		Form.Commands.Delete(FoundCommand);
		Form.Items.Delete(FoundButton);
	EndIf;
	
	For Each State In OriginalsStates Do
		CommandName = "Command" + StrReplace(State.Ref.UUID(),"-","_");
		ButtonName = State.Description;

		If Form.Commands.Find(CommandName) = Undefined Then
			Command = Form.Commands.Add(CommandName);
			Command.Action = "Attachable_SetOriginalState";

			// Command panel buttons.
			SetStateButton = Form.Items.Add(CommandName, Type("FormButton"), SetOriginalStateGroup);
			SetStateButton.Title = ButtonName;
			SetStateButton.CommandName = CommandName;

			// Set pictures.
			If State.Ref = Catalogs.SourceDocumentsOriginalsStates.OriginalReceived Then
				SetStateButton.Picture = PictureLib.SourceDocumentOriginalStateOriginalReceived;
			ElsIf State.Ref = Catalogs.SourceDocumentsOriginalsStates.FormPrinted Then
				SetStateButton.Picture = PictureLib.SourceDocumentOriginalStateOriginalNotReceived;
			EndIf;
			
		EndIf;

	EndDo;

	// Adds a state settings navigation button to the command bar submenu of the "Set state" list.
	If AccessRight("Insert",Metadata.Catalogs.SourceDocumentsOriginalsStates) 
		And AccessRight("Update",Metadata.Catalogs.SourceDocumentsOriginalsStates) Then
		CommandName = "StatesSetup";
		ButtonName = NStr("ru = 'Настроить...';
						|en = 'Configure…';");

		If Form.Commands.Find(CommandName) = Undefined Then
			FormCommand  = Form.Commands.Add(CommandName);
			FormCommand.Action = "Attachable_SetOriginalState";
			FormCommand.Title = ButtonName;
			
			ConfigureStatesButton = Form.Items.Add(CommandName, Type("FormButton"),ConfigureOriginalStatesGroup);
			ConfigureStatesButton.Title = ButtonName;
			ConfigureStatesButton.CommandName = CommandName;
			ConfigureStatesButton.Picture = PictureLib.ConfigureSourceDocumentOriginalStates;
		EndIf; 
		
	EndIf;

	// Adds button "Set original received" on the list command panel. 
	CommandName = "SetOriginalReceived";
	If Form.Commands.Find(CommandName) = Undefined Then
		FormCommand  = Form.Commands.Add(CommandName);
		FormCommand.Action = "Attachable_SetOriginalState";
		FormCommand.Title = NStr("ru = 'Установить ""Оригинал получен""';
										|en = 'Set ""Original received""';");
		FormCommand.ToolTip = NStr("ru = 'Установить ""Оригинал получен""';
										|en = 'Set ""Original received""';");
		
		NewButton = Form.Items.Add("Button" + CommandName , Type("FormButton"), SetOriginalReceivedGroup);
		NewButton.Picture = PictureLib.SourceDocumentOriginalStateOriginalReceived;
		NewButton.CommandName = CommandName;
	EndIf;

EndProcedure

#EndRegion

#Region Internal

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.3.142";
	Handler.InitialFilling = True;
	Handler.Procedure = "SourceDocumentsOriginalsRecording.WriteSourceDocumentOriginalState";
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.4.137"; 
	Handler.Id = New UUID("35320bc5-3ec6-4036-9253-ee5c507531e3");
	Handler.Procedure = "Catalogs.SourceDocumentsOriginalsStates.ProcessDataForMigrationToNewVersion";
	Handler.Comment = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Перезаполнение служебного реквизита %1 для устранения вероятного сбоя порядка.';
			|en = 'Repopulate internal attribute %1 to prevent misordering.';"),
		"AddlOrderingAttribute");
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs.SourceDocumentsOriginalsStates.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToRead      = "Catalog.SourceDocumentsOriginalsStates";
	Handler.ObjectsToChange    = "Catalog.SourceDocumentsOriginalsStates";
	Handler.ObjectsToLock   = "Catalog.SourceDocumentsOriginalsStates";
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
		Priority = Handler.ExecutionPriorities.Add();
		Priority.Procedure = "NationalLanguageSupportServer.ProcessDataForMigrationToNewVersion";
		Priority.Order = "Before";
	EndIf;
	
EndProcedure

// See also "InfobaseUpdateOverridable.OnDefineSettings".
//
// Parameters:
//  Objects - Array of MetadataObject
//
Procedure OnDefineObjectsWithInitialFilling(Objects) Export

	Objects.Add(Metadata.Catalogs.SourceDocumentsOriginalsStates);

EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport.
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export

	TableRow = CatalogsToImport.Find(Metadata.Catalogs.SourceDocumentsOriginalsStates.FullName(), 
		"FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;

EndProcedure

// See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds.
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	
	If Not GetFunctionalOption("UseSourceDocumentsOriginalsRecording")Then
		Return;
	EndIf;

	Kind = AttachableCommandsKinds.Add();
	Kind.Name         = "SettingOriginalState";
	Kind.SubmenuName  = "SetConfigureOriginalStateSubmenu";
	Kind.Title   = NStr("ru = 'Установить состояние оригинала';
							|en = 'Set original state';");
	Kind.Picture    = PictureLib.SetSourceDocumentOriginalState;
	Kind.Representation = ButtonRepresentation.Picture;
	
	Kind = AttachableCommandsKinds.Add();
	Kind.Name         = "SettingStateOriginalReceived";
	Kind.SubmenuName  = "SetStateOriginalReceived";
	Kind.Title   = NStr("ru = 'Установить состояние ""Оригинал получен""';
							|en = 'Set ""Original received"" state';");
	Kind.Picture    = PictureLib.SourceDocumentOriginalStateOriginalReceived;	
	Kind.Representation = ButtonRepresentation.Picture;

EndProcedure

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject.
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	If Not RightsToChangeState() Then
		Return;
	EndIf;

	ObjectsWithSourceDocumentsOriginalsAccounting = New Array;
	SourceDocumentsOriginalsRecordingOverridable.OnDefineObjectsWithOriginalsAccountingCommands(ObjectsWithSourceDocumentsOriginalsAccounting);
	NeedOutputCommands = False;
	
	For Each Object In ObjectsWithSourceDocumentsOriginalsAccounting Do		
		If StrFind(FormSettings.FormName, Object) Then
			NeedOutputCommands = True;
			Break;
		EndIf;
	EndDo;
	If Not NeedOutputCommands Then
		Return;
	EndIf;
	
	ObjectsWithSourceDocumentsOriginalsAccounting.Clear();
	
	For Each Type In Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type.Types() Do
		If Type = Type("CatalogRef.MetadataObjectIDs") Then
			Continue;
		EndIf;
		MetadataObject = Metadata.FindByType(Type);
		ObjectsWithSourceDocumentsOriginalsAccounting.Add(MetadataObject.FullName());
	EndDo;
	
	For Each Source In Sources.Rows Do
		If ObjectsWithSourceDocumentsOriginalsAccounting.Find(Source.FullName) <> Undefined Then
			NeedOutputCommands = True;
			Break;
		EndIf;
	EndDo;
	If Not NeedOutputCommands Then
		Return;
	EndIf;

	OriginalsStates = UsedStates();
	
	Order = 0;
	
	// Original state commands.
	For Each State In OriginalsStates Do		
		Command = Commands.Add();
		Command.Kind = "SettingOriginalState";
		Command.Presentation = State.Description;
		Command.Order = Order + 1; 
		// Set pictures.
		If State.Ref = Catalogs.SourceDocumentsOriginalsStates.OriginalReceived Then
			Command.Picture = PictureLib.SourceDocumentOriginalStateOriginalReceived;
		ElsIf State.Ref = Catalogs.SourceDocumentsOriginalsStates.FormPrinted Then
			Command.Picture = PictureLib.SourceDocumentOriginalStateOriginalNotReceived;
		EndIf;		
		Command.ParameterType = Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type;
		Command.Purpose = "ForList";
		Command.WriteMode = "Post";
		Command.FunctionalOptions = "UseSourceDocumentsOriginalsRecording";
		Command.Handler = "SourceDocumentsOriginalsRecordingClient.Attachable_SetOriginalState";
		
		Order = Order + 1;
	EndDo;
	
	// A command for navigating to the state settings in the command bar submenu of the "Set state" list.
	// Applicable if the user is assigned the required role.
	If AccessRight("Insert",Metadata.Catalogs.SourceDocumentsOriginalsStates) 
		And AccessRight("Update",Metadata.Catalogs.SourceDocumentsOriginalsStates) Then
		Command = Commands.Add();
		Command.Kind = "SettingOriginalState";
		Command.Id = "StatesSetup";
		Command.Presentation = NStr("ru = 'Настроить...';
									|en = 'Configure…';");
		Command.Importance = "SeeAlso";
		Command.Picture = PictureLib.ConfigureSourceDocumentOriginalStates;
		Command.ParameterType = Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type;
		Command.Purpose = "ForList";
		Command.WriteMode = "NotWrite";
		Command.FunctionalOptions = "UseSourceDocumentsOriginalsRecording";
		Command.Handler = "SourceDocumentsOriginalsRecordingClient.Attachable_SetOriginalState";	
	EndIf;
	
	Description = String(Catalogs.SourceDocumentsOriginalsStates.OriginalReceived);

	// Command "Set original received" on the list command panel. 
	Command = Commands.Add();
	Command.Kind = "SettingStateOriginalReceived";
	Command.Presentation = StringFunctionsClientServer.InsertParametersIntoString(
		NStr("ru = 'Установить состояние ""[Description]""';
			|en = 'Set the ""[Description]"" state';"),
		New Structure("Description", Description));
	Command.ButtonRepresentation = ButtonRepresentation.Picture;
	Command.Picture = PictureLib.SourceDocumentOriginalStateOriginalReceived;
	Command.ParameterType = Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type;
	Command.Purpose = "ForList";
	Command.WriteMode = "Post";
	Command.FunctionalOptions = "UseSourceDocumentsOriginalsRecording";
	Command.Handler = "SourceDocumentsOriginalsRecordingClient.Attachable_SetOriginalState";	

EndProcedure

Procedure BeforeItemMoved(ItemToMove, AdjacentElement, Direction, ErrorText, 
	StandardProcessing) Export
	
	If TypeOf(ItemToMove) <> Type("CatalogRef.SourceDocumentsOriginalsStates") Then
		Return;
	EndIf;
	
	ItemFormPrinted = PredefinedValue("Catalog.SourceDocumentsOriginalsStates.FormPrinted");
	ItemOriginalReceived = PredefinedValue("Catalog.SourceDocumentsOriginalsStates.OriginalReceived");
	
	MovingDown = Direction = ItemOrderSetup.ItemMovementDirectionDown();
	MovingUp = Direction = ItemOrderSetup.ItemMovementDirectionUp();
	
	If AdjacentElement = ItemFormPrinted And MovingUp
		Or (ItemToMove = ItemFormPrinted And MovingDown) Then
		StandardProcessing = False;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Состояние ""%1"" является начальным, размещение перед ним других состояний не предусмотрено.';
				|en = 'The ""%1"" state is the initial state. No other states can be set before it.';"),
			ItemFormPrinted);
	EndIf;
	
	If AdjacentElement = ItemOriginalReceived And MovingDown 
		Or (ItemToMove = ItemOriginalReceived And MovingUp) Then
		StandardProcessing = False;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Состояние ""%1"" является конечным, размещение после него других состояний не предусмотрено.';
				|en = 'The ""%1"" state is the final state. No other states can be set after it.';"),
			ItemOriginalReceived);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function RightsToChangeState()
	
	Return AccessRight("Edit", Metadata.InformationRegisters.SourceDocumentsOriginalsStates);

EndFunction

//	Parameters:
//  RecordData - Array of See SetTheNewStateOfTheOriginalArray.RecordData
//               - DocumentRef - The document whose source document's state should be changed.  
//  StateName - String - a state to be set.
//
// Returns:
//  String - "IsChanged" is the source document state is not repeated and was saved.
//           "NotIsChanged" 
//           "NotCarriedOut" 
//
Function SetNewOriginalState(Val RecordData, Val StateName) Export

	If Not GetFunctionalOption("UseSourceDocumentsOriginalsRecording") Then
		Return "NotIsChanged";
	EndIf;
		
	VerifyAccessRights("Edit", Metadata.InformationRegisters.SourceDocumentsOriginalsStates);

	WritingObjects = New Array;
	DocsToCheck = New Array;
	If TypeOf(RecordData) = Type("Array") Then
		For Each ListLine In RecordData Do
			Ref = CommonClientServer.StructureProperty(ListLine, "Ref"); 
			If IsAccountingObject(Ref) Then
				DocsToCheck.Add(Ref);
				WritingObjects.Add(ListLine);
			EndIf;
		EndDo;
	Else
		DocsToCheck.Add(RecordData);
		WritingObjects.Add(RecordData);
	EndIf;

	UnpostedDocuments = CommonServerCall.CheckDocumentsPosting(DocsToCheck);
	If UnpostedDocuments.Count() > 0 Then
		Return "NotPosted";
	EndIf;
	
	SetPrivilegedMode(True);
	If TypeOf(RecordData) = Type("Array") Then
		 Result = SetTheNewStateOfTheOriginalArray(RecordData, StateName);
	Else
		 Result = SetNewStatusForOriginalDoc(RecordData, StateName);
	EndIf;
	Return ?(Result, "IsChanged", "NotIsChanged");
	
EndFunction

//	Parameters:
//  RecordData - Array of Structure - Information on the current document state:
//                 * OverallState    - Boolean - "True" if the current state is aggregated.
//                 * Ref 		   - DocumentRef - The document whose source document's state should be changed.
//                 * SourceDocumentOriginalState - CatalogRef.SourceDocumentsOriginalsStates -
//                                                           The current state of a source document.
//                 * SourceDocument - String - A source document ID. Required if the state is not aggregated. 
//                                                
//                 * FromOutside 			   - Boolean - "True" if the source document was added manually. 
//                                                It's required if the current state is not overall. 
//  StateName - String - a state to be set.
//
// Returns:  
//  Boolean - If True, the source document's state is not repeated and was saved.
//
Function SetTheNewStateOfTheOriginalArray(Val RecordData, Val StateName)

	IsChanged = False;
	
	Block = New DataLock();

	BeginTransaction();
	Try
		
		For Each Record In RecordData Do
			LockItem = Block.Add("InformationRegister.SourceDocumentsOriginalsStates");
			LockItem.SetValue("Owner", Record.Ref); 
		EndDo;
		Block.Lock();

		For Each Record In RecordData Do
	
			If TrimAll(Record.SourceDocumentOriginalState) = TrimAll(StateName) Then
				Continue;
			EndIf;
			
			If Record.OverallState Then
				RecordSet = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordSet();
				RecordSet.Filter.Owner.Set(Record.Ref);
				RecordSet.Filter.OverallState.Set(False);
				RecordSet.Read();
	
				If RecordSet.Count() = 0 Then
					IsChanged = True;
					InformationRegisters.SourceDocumentsOriginalsStates.WriteCommonDocumentOriginalState(Record.Ref, 
						StateName);
					Continue;
				EndIf;
					
				For Each PreviousRecord1 In RecordSet Do
					If TrimAll(PreviousRecord1.State) = StateName Then
						Continue;
					EndIf; 
					IsChanged = True;
					TabularSection = TableOfEmployees(Record.Ref);
					PreviousRecordEmployee = ?(TabularSection <> "", PreviousRecord1.Employee, Undefined);
					InformationRegisters.SourceDocumentsOriginalsStates.WriteDocumentOriginalStateByPrintForms(Record.Ref,
						PreviousRecord1.SourceDocument, PreviousRecord1.SourceDocumentPresentation, StateName,
						PreviousRecord1.ExternalForm, PreviousRecordEmployee);
				EndDo;
	
				IsChanged = True;
				InformationRegisters.SourceDocumentsOriginalsStates.WriteCommonDocumentOriginalState(Record.Ref, 
					StateName);
				Continue;
			EndIf;
			
			RecordSet = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordSet();
			RecordSet.Filter.Owner.Set(Record.Ref);
			RecordSet.Read();
			If RecordSet.Count() = 0 Then
				IsChanged = True;
				InformationRegisters.SourceDocumentsOriginalsStates.WriteCommonDocumentOriginalState(Record.Ref,
					StateName);
				Continue;
			EndIf;
			
			RecordSet.Filter.SourceDocument.Set(Record.SourceDocument);
			RecordSet.Read();
			TabularSection = TableOfEmployees(Record.Ref); 
			If TabularSection <> "" Then
				IsStatesChanged = WriteOriginalDocumentStateByEmployees(RecordSet, Record.Ref, 
					TabularSection, StateName);
			Else
				IsStatesChanged = WriteDocumentOriginalStateByPrintForms(RecordSet, Record.Ref, 
					StateName);
			EndIf;
			IsChanged = IsChanged Or IsStatesChanged; 
			If IsChanged Then
				InformationRegisters.SourceDocumentsOriginalsStates.WriteCommonDocumentOriginalState(Record.Ref, 
					StateName);
			EndIf;
	
		EndDo;
		
		CommitTransaction();
		
	Except	
		RollbackTransaction();
		Raise;
	EndTry;
		
	Return IsChanged;

EndFunction

// Parameters:
//   Document - DocumentRef - The document whose source document's state should be changed.
//   StateName - String - The state to be applied.
//
// Returns:
//   Boolean - If True, the source document's state is not repeated and was saved.
//
Function SetNewStatusForOriginalDoc(Val Document, Val StateName)
	
	Block = New DataLock();
	LockItem = Block.Add("InformationRegister.SourceDocumentsOriginalsStates");
	LockItem.SetValue("Owner", Document); 

	BeginTransaction();
	Try
		 
		Block.Lock();
		RecordSet = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordSet();
		RecordSet.Filter.Owner.Set(Document);
		RecordSet.Filter.OverallState.Set(True);  
		RecordSet.Read();
	
		If RecordSet.Count() And TrimAll(RecordSet[0].State) = StateName Then
			CommitTransaction();
			Return False;
		EndIf;
				
		RecordSet.Filter.OverallState.Set(False);
		RecordSet.Read();
	
		If RecordSet.Count() > 0 Then
			TabularSection = TableOfEmployees(Document); 
			If TabularSection <> "" Then
				WriteOriginalDocumentStateByEmployees(RecordSet, Document, TabularSection, StateName);
			Else
				WriteDocumentOriginalStateByPrintForms(RecordSet, Document, StateName);
			EndIf;
		EndIf; 
		
		InformationRegisters.SourceDocumentsOriginalsStates.WriteCommonDocumentOriginalState(Document, 
			StateName);
		
		CommitTransaction();
		
	Except
		RollbackTransaction(); 
		Raise;
	EndTry;
	
	Return True;

EndFunction

Function WriteDocumentOriginalStateByPrintForms(RecordSet, Document, StateName)
	
	IsChanged = False;
	For Each PreviousRecord1 In RecordSet Do
		If TrimAll(PreviousRecord1.State) = StateName Then
			Continue;
		EndIf;
		IsChanged = True;
		InformationRegisters.SourceDocumentsOriginalsStates.WriteDocumentOriginalStateByPrintForms(Document,
			PreviousRecord1.SourceDocument, PreviousRecord1.SourceDocumentPresentation, 
			StateName, PreviousRecord1.ExternalForm);
	EndDo;
	Return IsChanged;
	
EndFunction

Function WriteOriginalDocumentStateByEmployees(RecordSet, Document, TabularSection, StateName)
	
	IsChanged = False;
	For Each Employee In Document[TabularSection] Do
		RecordSet.Filter.Employee.Set(Employee.Employee);
		RecordSet.Read(); 
		If RecordSet.Count() = 0 Then
			Continue;
		EndIf;

		For Each PreviousRecord1 In RecordSet Do
			If TrimAll(PreviousRecord1.State) = StateName Then
				Continue;
			EndIf;
			IsChanged = True;
			InformationRegisters.SourceDocumentsOriginalsStates.WriteDocumentOriginalStateByPrintForms(Document,
				PreviousRecord1.SourceDocument, PreviousRecord1.SourceDocumentPresentation, 
				StateName, PreviousRecord1.ExternalForm, Employee.Employee);
		EndDo; 
	EndDo;
	Return IsChanged;
	
EndFunction

// Fills in the drop-down choice list of states on the form.
//
//	Parameters:
//  Form - ClientApplicationForm - a form of the document list.
//
Procedure FillOriginalStatesChoiceList(Form, OriginalsStates)

	OriginalStatesChoiceList = Form.OriginalStatesChoiceList;
	OriginalStatesChoiceList.Clear(); 
	
	For Each State In OriginalsStates Do

		If State.Ref = Catalogs.SourceDocumentsOriginalsStates.OriginalReceived Then 
			OriginalStatesChoiceList.Add(State.Description, State.Description,,
				PictureLib.SourceDocumentOriginalStateOriginalReceived);
		ElsIf State.Ref = Catalogs.SourceDocumentsOriginalsStates.FormPrinted Then
			OriginalStatesChoiceList.Add(State.Description, State.Description,,
				PictureLib.SourceDocumentOriginalStateOriginalNotReceived);
		Else
			OriginalStatesChoiceList.Add(State.Description, State.Description);
		EndIf;

	EndDo;

EndProcedure

// Returns an array of states available to a user.
//
//	Returns:
//  ValueTable:
//    * Description - String - a description of the original state;
//    * Ref		 - CatalogRef.SourceDocumentsOriginalsStates
//
Function UsedStates()Export 

	SetPrivilegedMode(True);

	Query = New Query;
	Query.Text = "SELECT ALLOWED
	               |	SourceDocumentsOriginalsStates.Description AS Description,
	               |	SourceDocumentsOriginalsStates.Ref AS Ref
	               |FROM
	               |	Catalog.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
	               |WHERE
	               |	NOT SourceDocumentsOriginalsStates.Ref = VALUE(Catalog.SourceDocumentsOriginalsStates.OriginalsNotAll)
	               |	AND NOT SourceDocumentsOriginalsStates.DeletionMark
	               |
	               |ORDER BY
	               |	SourceDocumentsOriginalsStates.AddlOrderingAttribute";

	Selection = Query.Execute();
	
	SetPrivilegedMode(False);

	Return Selection.Unload();

EndFunction

// Returns a record key of the register of overall document original state by reference.
//
//	Parameters:
//  DocumentRef - DocumentRef - A reference to the document whose general state record key is to be received.
//
//	Returns:
//  InformationRegisterRecordKey.SourceDocumentsOriginalsStates
//
Function OverallStateRecordKey(DocumentRef) Export

	Query = New Query;
	Query.Text ="SELECT ALLOWED
	|	SourceDocumentsOriginalsStates.Owner AS Owner,
	|	SourceDocumentsOriginalsStates.SourceDocument AS SourceDocument,
	|	SourceDocumentsOriginalsStates.OverallState AS OverallState,
	|	SourceDocumentsOriginalsStates.ExternalForm AS ExternalForm,
	|	SourceDocumentsOriginalsStates.Employee AS Employee
	|FROM
	|	InformationRegister.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
	|WHERE
	|	SourceDocumentsOriginalsStates.Owner = &Ref
	|	AND SourceDocumentsOriginalsStates.OverallState" ;
	
	Query.SetParameter("Ref",DocumentRef);

	Selection = Query.Execute().Unload();

	For Each Var_Key In Selection Do
		TransmittedParameters = New Structure("Owner, SourceDocument, OverallState, ExternalForm, Employee");
		FillPropertyValues(TransmittedParameters,Var_Key);

		ParametersArray1 = New Array;
		ParametersArray1.Add(TransmittedParameters);

		RegisterRecordKey = New("InformationRegisterRecordKey.SourceDocumentsOriginalsStates", ParametersArray1);
	EndDo;

	Return RegisterRecordKey;

EndFunction

// Checks and returns a flag indicating whether the document by reference is a document with originals recording.
//
// Parameters:
//  DocumentRef - DocumentRef - a reference to the document to be checked.
//
// Returns:
//   Boolean
//
Function IsAccountingObject(DocumentRef) Export

	If DocumentRef = Undefined Then
		Return False;
	EndIf;
	
	Return Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type.ContainsType(TypeOf(DocumentRef));

EndFunction

// Looks up for employees information in a document and returns the name of the table that contains it.
//
//	Parameters:
//  DocumentRef - DocumentRef - a reference to the document to be checked.
//
//	Returns:
//  String - The name of the table containing employees.
//           It is empty if the document does not contain multiple employees.
//
Function TableOfEmployees(DocumentRef) Export
	
	ListOfObjects = New Map();
	Result = "";
	SourceDocumentsOriginalsRecordingOverridable.WhenDeterminingMultiEmployeeDocuments(ListOfObjects);
	DocumentType = Common.TableNameByRef(DocumentRef);
	If ListOfObjects[DocumentType] <> Undefined Then
		Result = ListOfObjects[DocumentType];
	EndIf;
	
	Return Result;
	
EndFunction

// Returns an array with type details of objects attached to the subsystem.
//
//	Returns:
//  Array of Type
//
Function InformationAboutConnectedObjects() Export

	AvailableTypes = Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type.Types();
	Return AvailableTypes;

EndFunction

// Returns a reference to the document by the spreadsheet document barcode.
//
// Parameters:
//  Barcode - String
//  Managers - Array of CatalogRef
//            - DocumentRef
//            - TaskRef
//
// Returns:
//  Array of DocumentRef
//
Function RefBySpreadsheetDocumentBarcode(Barcode, Managers = Undefined) 

	If Not StringFunctionsClientServer.OnlyNumbersInString(Barcode, False, False)
		Or TrimAll(Barcode) = "" Then
		Return New Array;
	EndIf;

	BarcodeInHexadecimal = ConvertDecimalToHexadecimalNotation(Number(Barcode));
	While StrLen(BarcodeInHexadecimal) < 32 Do
		BarcodeInHexadecimal = "0" + BarcodeInHexadecimal;
	EndDo;

	Id = Mid(BarcodeInHexadecimal, 1,  8)
		+ "-" + Mid(BarcodeInHexadecimal, 9,  4)
		+ "-" + Mid(BarcodeInHexadecimal, 13, 4)
		+ "-" + Mid(BarcodeInHexadecimal, 17, 4)
		+ "-" + Mid(BarcodeInHexadecimal, 21, 12);

	If StrLen(Id) <> 36 Then
		Return New Array;
	EndIf;

	If Managers = Undefined Then
		ObjectsManagers = New Array();
		For Each MetadataItem In Metadata.Documents Do
			ObjectsManagers.Add(Documents[MetadataItem.Name]);
		EndDo;
	Else
		ObjectsManagers = New Array();
		For Each EmptyRef In Managers Do
			RefType = TypeOf(EmptyRef);
			
			If Documents.AllRefsType().ContainsType(RefType) Then
				ObjectsManagers.Add(Documents[EmptyRef.Metadata().Name]);
				
			ElsIf Catalogs.AllRefsType().ContainsType(RefType) Then
				ObjectsManagers.Add(Catalogs[EmptyRef.Metadata().Name]);
				
			ElsIf Tasks.AllRefsType(RefType).ContainsType(RefType) Then	
				ObjectsManagers.Add(Tasks[EmptyRef.Metadata().Name]);
				
			ElsIf BusinessProcesses.AllRefsType(RefType).ContainsType(RefType) Then	
				ObjectsManagers.Add(BusinessProcesses[EmptyRef.Metadata().Name]);
				
			ElsIf ChartsOfCharacteristicTypes.AllRefsType(RefType).ContainsType(RefType) Then
				ObjectsManagers.Add(ChartsOfCharacteristicTypes[EmptyRef.Metadata().Name]);
				
			Else
				ExceptionText = NStr("ru = 'Ошибка распознавания штрихкода: тип ""%Type%"" не поддерживается.';
										|en = 'Barcode recognition error: type ""%Type%"" is not supported.';");
				ExceptionText = StrReplace(ExceptionText, "%Type%", RefType);				
				Raise ExceptionText;
			EndIf;

		EndDo;
	EndIf;

	Query = New Query;

	ReferencesArrray = New Array;
	FirstQuery = True;
	For Each Manager In ObjectsManagers Do

		Try
			Ref = Manager.GetRef(New UUID(Id));
		Except
			Continue;
		EndTry;
		
		RefMetadata = Ref.Metadata();
		If Not AccessRight("Read", RefMetadata) Then
			Continue;
		EndIf;
		
		ReferencesArrray.Add(Ref);
		
		If FirstQuery Then
			Query.Text = Query.Text +
			"SELECT ALLOWED Table.Ref AS Ref
			|FROM &TheMetadataLinksToTheFullName AS Table
			|WHERE Ref IN (&ReferencesArrray)
			|";
		Else	
			Query.Text = Query.Text + 
			"UNION ALL
			|
			|SELECT Table.Ref AS Ref
			|FROM &TheMetadataLinksToTheFullName AS Table
			|WHERE Ref IN (&ReferencesArrray)
			|";
		EndIf;
		
		Query.Text = StrReplace(Query.Text, "&TheMetadataLinksToTheFullName", RefMetadata.FullName());
		FirstQuery = False;

	EndDo;

	If Not FirstQuery Then
		Query.Parameters.Insert("ReferencesArrray", ReferencesArrray);
		Return Query.Execute().Unload().UnloadColumn("Ref");
	Else
		Return New Array;
	EndIf;

EndFunction

// The procedure processes actions of originals recording after scanning the document barcode.
//
// Parameters:
//   Barcode - String - the scanned document barcode.
//
Procedure ProcessBarcode(Barcode) Export

	RefByBarcode = RefBySpreadsheetDocumentBarcode(Barcode);
	SetNewOriginalState(RefByBarcode[0], 
		Catalogs.SourceDocumentsOriginalsStates.OriginalReceived);

EndProcedure

// After recording states of document print forms to the register, checks whether the print forms have the same states.
//
// Parameters:
//  DocumentRef - DocumentRef - a reference to the document whose print form states must be checked.
//  StateName - String - a state name that was set.
//
// Returns:
//   Boolean - True if all the document print forms have the same state.
//
Function PrintFormsStateSame(DocumentRef,StateName) Export

	FormsStateSame = False;

	Query = New Query;
	Query.Text = "SELECT ALLOWED
	               |	SourceDocumentsOriginalsStates.State.Description AS OriginalState
	               |FROM
	               |	InformationRegister.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
	               |WHERE
	               |	SourceDocumentsOriginalsStates.Owner = &Ref
	               |	AND NOT SourceDocumentsOriginalsStates.OverallState";
	Query.SetParameter("Ref", DocumentRef);

	Selection = Query.Execute().Select();
	While Selection.Next() Do

		FormsStateSame = (Selection.OriginalState = TrimAll(StateName));
		If Not FormsStateSame Then
			Break;
		EndIf;

	EndDo;

	Return FormsStateSame;

EndFunction

// Returns data on the current state of the source document by Ref.
//
//	Parameters:
//  DocumentRef - DocumentRef - a reference to the document whose overall state details must be received. 
//
//  Returns:
//    Structure:
//    * Ref - DocumentRef - Document reference.
//    * SourceDocumentOriginalState - CatalogRef.SourceDocumentsOriginalsStates - Current source document state.
//        
//
Function OriginalStateInfoByRef(DocumentRef) Export

	Query = New Query;
	Query.Text = "SELECT ALLOWED
		|	SourceDocumentsOriginalsStates.State AS State,
		|	SourceDocumentsOriginalsStates.OverallState AS OverallState
		|FROM
		|	InformationRegister.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
		|WHERE
		|	SourceDocumentsOriginalsStates.Owner = &Ref
		|	AND SourceDocumentsOriginalsStates.OverallState = TRUE";
	
	Query.SetParameter("Ref",DocumentRef);
	
	StateInfo3 = New Structure;

	If Not Query.Execute().IsEmpty() Then
		Selection = Query.Execute().Select();
		Selection.Next();
		
		StateInfo3.Insert("Ref",DocumentRef);
		StateInfo3.Insert("SourceDocumentOriginalState",Selection.State);	
	EndIf;

	Return StateInfo3;

EndFunction

// Update handler procedure that populates initial items of the "States of source document originals" catalog.
Procedure WriteSourceDocumentOriginalState() Export

	OriginalState = Catalogs.SourceDocumentsOriginalsStates.FormPrinted.GetObject();
	LockDataForEdit(OriginalState.Ref);
	OriginalState.Description = NStr("ru = 'Форма напечатана';
											|en = 'Form printed';", Common.DefaultLanguageCode());
	OriginalState.LongDesc = NStr("ru = 'Состояние, означающее, что  печатная форма только печаталась.';
										|en = 'State that means that the print form was printed only.';", 
		Common.DefaultLanguageCode());
	OriginalState.AddlOrderingAttribute = 1;
	InfobaseUpdate.WriteObject(OriginalState);

	OriginalState = Catalogs.SourceDocumentsOriginalsStates.OriginalsNotAll.GetObject();
	LockDataForEdit(OriginalState.Ref);
	OriginalState.Description = NStr("ru = 'Оригиналы не все';
											|en = 'Not all originals';", Common.DefaultLanguageCode());
	OriginalState.LongDesc = NStr("ru = 'Общее состояние для документа, у которого оригиналы печатных форм находятся в разных состояниях.';
										|en = 'The aggregated state of a document whose print forms have different states.';", 
		Common.DefaultLanguageCode());
	OriginalState.AddlOrderingAttribute = 99998;
	InfobaseUpdate.WriteObject(OriginalState);

	OriginalState = Catalogs.SourceDocumentsOriginalsStates.OriginalReceived.GetObject();
	LockDataForEdit(OriginalState.Ref);
	OriginalState.Description = NStr("ru = 'Оригинал получен';
											|en = 'Original received';", Common.DefaultLanguageCode());
	OriginalState.LongDesc = NStr("ru = 'Состояние, означающее, что подписанный оригинал печатной формы есть в наличии.';
										|en = 'State that means that the signed print form original is available.';", 
		Common.DefaultLanguageCode());
	OriginalState.AddlOrderingAttribute = 99999;
	InfobaseUpdate.WriteObject(OriginalState);

EndProcedure

Function ConvertDecimalToHexadecimalNotation(Val Decimal)

	Result = "";

	While Decimal > 0 Do
		Remainder = Decimal % 16;
		Decimal = (Decimal - Remainder) / 16;
		Result = Mid("0123456789abcdef", Remainder + 1, 1) + Result;
	EndDo;

	Return Result;
	
EndFunction

// Overrides value lists of print objects and their templates.
//
// Parameters:
//  PrintObjects - ValueList - Print object references.
//  PrintList - ValueList - Template names and print form presentations.
//
Procedure WhenDeterminingTheListOfPrintedForms(PrintObjects, PrintList) Export
	
	AccountingTableForOriginals = AccountingTableForOriginals();
	If AccountingTableForOriginals.Count() = 0 Then
		Return;
	EndIf;
	
	TemplatesNames = New Array;
	For Each Template In PrintList Do
		TemplatesNames.Add(Template.Value);
	EndDo;
	
	MetadataCompliance = New Map();
	For Each PrintObject In PrintObjects Do
		MetadataCompliance.Insert(PrintObject.Value.Metadata());
	EndDo;
	MetadataObjects = Common.UnloadColumn(MetadataCompliance, "Key");
	
	DeleteLayouts = New Array;
	For Each MetadataObject In MetadataObjects Do
		FoundRows = AccountingTableForOriginals.FindRows(New Structure("MetadataObject", MetadataObject));
		If FoundRows.Count() = 0 Then
			Continue;
		EndIf;
		LeaveLayouts = Common.UnloadColumn(FoundRows, "Id");
		For Each Template In TemplatesNames Do
			If LeaveLayouts.Find(Template) = Undefined Then
				DeleteLayouts.Add(Template);
			EndIf;
		EndDo;
	EndDo;
	
	For Each Template In DeleteLayouts Do
		FoundTemplate = PrintList.FindByValue(Template);
		If FoundTemplate <> Undefined Then
			PrintList.Delete(FoundTemplate);
		EndIf;
	EndDo;

EndProcedure

Function AccountingTableForOriginals()
	
	Table = New ValueTable;
	Table.Columns.Add("MetadataObject", New TypeDescription("MetadataObject"));
	Table.Columns.Add("Id", New TypeDescription("String"));
	
	SourceDocumentsOriginalsRecordingOverridable.FillInTheOriginalAccountingTable(Table);
	Return Table;
	
EndFunction

#EndRegion
