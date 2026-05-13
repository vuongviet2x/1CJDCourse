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
	
	FillMetadataObjectsChoiceList();
	
	CommonLanguageParameters = FillCommonLanguageParameters();
	
	WithoutDeletedItems = True;
	KeyAttributeName = DefaultKeyAttributeName();
	
	SetConditionalAppearance();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FormMode = "TablePage";
	ChangeSectionPage();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MetadataObjectAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	StandardProcessing = False;
	GetAutoCompleteValue(Text, ChoiceData);
	
EndProcedure

&AtClient
Procedure MetadataObjectTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	StandardProcessing = False;
	GetAutoCompleteValue(Text, ChoiceData);
	
EndProcedure

&AtClient
Procedure MetadataObjectOnChange(Item)
	
	Attributes.GetItems().Clear();
	ClearDynamicallyCreatedFormItems();
	OneCCode.Clear();
	
	If Not ValueIsFilled(Object.MetadataObject) Then
		Return;
	EndIf;
	
	MetadataObjectOnChangeAtServer();
	
	CurrentItem = Items.SpreadsheetDocument;
	Area = SpreadsheetDocument.Area(1,1,1,1);
	Items.SpreadsheetDocument.SetSelectedAreas(Area);
	SpreadsheetDocument.CurrentArea = Items.SpreadsheetDocument.CurrentArea;
	
	CurrentPredefinedDataName = "";
	HeaderAreaName = "";
	
	CheckTabularSectionsDisplay();
	OutputCurrentItemTabularSections();
	ChangeSectionPage();
	
	WriteSpreadsheetDocumentCopy(False);
	
	SetConditionalAppearance();
	
	If FormMode = "CodePage" Then
		UpdateTableAndCode();
	EndIf;
	
EndProcedure

&AtClient
Procedure MetadataObjectOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(Object.MetadataObject) Then
		Return;
	EndIf;
	
	OpeningParameters = New Structure;
	OpenForm(Object.MetadataObject + ".ListForm", OpeningParameters, ThisObject,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FormModeOnChange(Item)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	CurrentPage = Items.SectionsGroup.CurrentPage;
	If CurrentPage.Name = FormMode Then
		Return;
	ElsIf CurrentPage = Items.CodePage Then
		
		ConversionResult = ConvertToTableAtServer();
		If Not ConversionResult.Success Then
			CommonClient.MessageToUser(ConversionResult.ErrorText);
			FormMode = "CodePage";
			Return;
		EndIf;
		
		CurrentItem = Items.SpreadsheetDocument;
		Area = SpreadsheetDocument.Area(1,1,1,1);
		Items.SpreadsheetDocument.SetSelectedAreas(Area);
		SpreadsheetDocument.CurrentArea = Items.SpreadsheetDocument.CurrentArea;
		
		CurrentPredefinedDataName = "";
		HeaderAreaName = "";
		
		CheckTabularSectionsDisplay();
		OutputCurrentItemTabularSections();
		
		FormMode = "TablePage";
	Else
		ConvertToCodeAtServer();
		CurrentPredefinedDataName = "";
		HeaderAreaName = "";
	EndIf;
	
	WriteSpreadsheetDocumentCopy(False);
	
	ChangeSectionPage();
	
EndProcedure

&AtClient
Procedure AttributesCheckOnChange(Item)
	
	CurrentData = Items.Attributes.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	AttributesSetMarkInList(CurrentData, CurrentData.Check, True);
	
EndProcedure

&AtClient
Procedure RollbackToLastStableVersion(Command)
	
	RestoreSpreadsheetDocumentFromCopy();
	
	If FormMode = "CodePage" Then
		ConvertToCodeAtServer();
		CurrentPredefinedDataName = "";
		HeaderAreaName = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure OneCCodeOnChange(Item)
	
	Items.RollbackToLastStableVersion.Enabled = True;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSpreadsheetDocument

&AtClient
Procedure Attachable_SpreadsheetDocumentOnActivateArea(Item)
	
	If Not ValueIsFilled(Object.MetadataObject) Then
		Return;
	EndIf;
	
	SpreadsheetDocumentName = ?(Item.Name <> Items.SpreadsheetDocumentWithoutTS.Name,
		Item.Name, Items.SpreadsheetDocument.Name);
	
	TableHeight = ThisObject[SpreadsheetDocumentName].TableHeight;
	TableWidth = ThisObject[SpreadsheetDocumentName].TableWidth;
	
	ActiveAreaStructure = New Structure;
	SourceArea = Item.CurrentArea;
	TopOfArea  = ?(SourceArea.Top  = 0, 1, SourceArea.Top);
	BottomOfArea   = ?(SourceArea.Bottom   = 0, TableHeight, SourceArea.Bottom);
	LeftField  = ?(SourceArea.Left  = 0, 1, SourceArea.Left);
	AreaRight = ?(SourceArea.Right = 0, TableWidth, SourceArea.Right);
	
	AreaName = ThisObject[SpreadsheetDocumentName].Area(1, LeftField, 1, AreaRight).Name;
	
	Item.Protection = (TopOfArea = 1) Or (AreaRight > TableWidth);
	
	For LineNumber = TopOfArea To BottomOfArea Do
		For ColumnNumber = LeftField To AreaRight Do
			CoordinatesOfArea = New Structure;
			CoordinatesOfArea.Insert("Top", LineNumber);
			CoordinatesOfArea.Insert("Left", ColumnNumber);
			AreaName = AreaName(CoordinatesOfArea);
			Cell = ThisObject[SpreadsheetDocumentName].Area(AreaName);
			CellStructure_ = New Structure("Name, ContainsValue, Value, Text, ValueType");
			FillPropertyValues(CellStructure_, Cell);
			ActiveAreaStructure.Insert(AreaName, CellStructure_);
		EndDo;
	EndDo;
	
	CoordinatesOfArea = New Structure;
	CoordinatesOfArea.Insert("Top", TopOfArea);
	CoordinatesOfArea.Insert("Left", 0);
	If (SpreadsheetDocumentName = "SpreadsheetDocument") And DisplayTabularSections
		 And StrFind(HeaderAreaName, AreaName(CoordinatesOfArea) + "C") = 0 Then
		CoordinatesOfArea.Insert("Top",  TopOfArea);
		CoordinatesOfArea.Insert("Left",  LeftField);
		CoordinatesOfArea.Insert("Bottom",   BottomOfArea);
		CoordinatesOfArea.Insert("Right", AreaRight);
		HeaderAreaName = AreaName(CoordinatesOfArea);
		AttachIdleHandler("OutputCurrentItemTabularSections", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_SpreadsheetDocumentValueInputStart(Item, Area, StandardProcessing)
	
	WriteSpreadsheetDocumentCopy();
	
	SpreadsheetDocumentName = StrReplace(Item.Name, "NoTS", "");
	TabularSectionName = StrReplace(SpreadsheetDocumentName, "SpreadsheetDocument", "");
	
	ColumnHeaderArea = ThisObject[SpreadsheetDocumentName].Area(1, Area.Left, 1, Area.Left);
	
	If Area.ContainsValue Or Area.Top = 1 Then
		Return;
	EndIf;
	
	AttributeName = ColumnHeaderArea.Name;
	CoordinatesOfArea = New Structure;
	CoordinatesOfArea.Insert("Top", 1);
	CoordinatesOfArea.Insert("Left", Area.Left);
	If AttributeName = AreaName(CoordinatesOfArea) Then
		AttributeName = ColumnHeaderArea.Text;
	EndIf;
	AttributeName = StrReplace(AttributeName, " ", "");
	
	If IsBlankString(AttributeName) Then
		Return;
	EndIf;
	
	AttributesStructure1 = FullObjectStructure;
	If SpreadsheetDocumentName <> "SpreadsheetDocument" Then
		If Not FullObjectStructure.Property(TabularSectionName, AttributesStructure1) Then
			Return;
		EndIf;
		AttributesStructure1 = AttributesStructure1.Attributes;
	EndIf;
	
	StructureAttributeValue = Undefined;
	If AttributesStructure1.Property(AttributeName, StructureAttributeValue) Then
		
		StructureAttributeType = StructureAttributeValue.ValueType;
		
		If ContainsSimpleTypesOnly(StructureAttributeType) Then
			
			// Untypified area of a simple type.
			Area.ContainsValue = True;
			Area.ValueType = StructureAttributeType;
			
			If ThisIsBoolean(StructureAttributeType) Then
				// For cases where "No" is specified in the non-synced area.
				// Therefore, "OnChange" event is not triggered, and the data table is not synced.
				SpreadsheetDocumentBordersChangesSynchronization(TabularSectionName, Area.Top - 2);
				SpreadsheetDocumentDataChangesSynchronization(False, AttributeName, TabularSectionName, Area.Top - 2);
			EndIf;
			
			Return;
			
		EndIf;
		
	Else
		Return;
	EndIf;
	
	// Manage untypified areas for attributes of reference type.
	StandardProcessing = False;
	
	AdditionalParameters = SpreadsheetDocumentParameters(Area, SpreadsheetDocumentName, StructureAttributeType, AttributeName);
	
	If IsAccountKind(StructureAttributeType) Then
		If IsBlankString(Area.Text) Then
			OnCloseNotifyDescription = New NotifyDescription("SpreadsheetDocumentSelectionAccountKindAttributeSelectionCompletion",
				ThisObject, AdditionalParameters);
			AccountTypes = New ValueList;
			AccountTypes.Add(AccountType.ActivePassive);
			AccountTypes.Add(AccountType.Active);
			AccountTypes.Add(AccountType.Passive);
			
			AccountTypes.ShowChooseItem(OnCloseNotifyDescription, NStr("ru = 'Выбор вида счета';
																				|en = 'Select account type';"));
		EndIf;
		
	ElsIf IsTypesDetails(StructureAttributeType) Then
		OnCloseNotifyDescription = New NotifyDescription("SpreadsheetDocumentSelectionTypesDetailsAttributeSelectionCompletion",
			ThisObject, AdditionalParameters);
		TypeDescription = TableDataRead(CurrentPredefinedDataName, AttributeName, TabularSectionName,
			AdditionalParameters.LineNumber);
		OpeningParameters = New Structure("TypeDescription, MetadataObject", TypeDescription, Object.MetadataObject);
		
		OpenForm("ExternalDataProcessor.DataPopulation.Form.TypesDetailsEditForm",
			OpeningParameters, ThisObject,,,, OnCloseNotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
	Else
		FullNameAttributeMetadata = FullTypeMetadataName(StructureAttributeType);
		
		OnCloseNotifyDescription = New NotifyDescription("SpreadsheetDocumentSelectionReferenceTypeAttributeSelectionCompletion",
			ThisObject, AdditionalParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("ChoiceMode",           True);
		OpeningParameters.Insert("ChoiceFoldersAndItems",  FoldersAndItemsUse.FoldersAndItems);
		OpeningParameters.Insert("StructureAttributeType", StructureAttributeType);
		
		FormNameString = ?((AttributeName = "Parent") And (Not IsChartOfAccounts(StructureAttributeType)), ".GroupChoiceForm", ".ChoiceForm");
		
		OpenForm(FullNameAttributeMetadata + FormNameString, OpeningParameters, ThisObject,,,,
			OnCloseNotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

// Parameters:
//  Area - SpreadsheetDocumentRange
//  SpreadsheetDocumentName - String
//  StructureAttributeType - TypeDescription
// 
// Returns:
//  Structure:
//   * SpreadsheetDocumentName - String
//   * AttributeName - String
//   * Area - SpreadsheetDocumentRange
//   * ValueType - TypeDescription
//   * LineNumber - Number
//
&AtClient
Function SpreadsheetDocumentParameters(Area, Val SpreadsheetDocumentName, Val StructureAttributeType, Val Var_AttributeName)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SpreadsheetDocumentName", SpreadsheetDocumentName);
	AdditionalParameters.Insert("Area",                Area);
	AdditionalParameters.Insert("LineNumber",            Area.Top - 2);
	AdditionalParameters.Insert("AttributeName",           Var_AttributeName);
	AdditionalParameters.Insert("ValueType",            StructureAttributeType);
	
	Return AdditionalParameters;
	
EndFunction

&AtClient
Procedure Attachable_SpreadsheetDocumentOnChange(Item)
	
	// Check if modified.
	If Not SpreadsheetDocumentOnChangeModified(Item) Then
		Return;
	EndIf;
	
	SpreadsheetDocumentName = StrReplace(Item.Name, "NoTS", "");
	TabularSectionName = StrReplace(SpreadsheetDocumentName, "SpreadsheetDocument", "");
	CurrentArea = Item.CurrentArea;
	
	IsRowsChange     = (CurrentArea.Left + CurrentArea.Right = 0);
	IsColumnsChange   = (CurrentArea.Top + CurrentArea.Bottom = 0);
	IsCellChange    = (Not IsRowsChange) And (Not IsColumnsChange) And (CurrentArea.Top = CurrentArea.Bottom)
		And (CurrentArea.Left = CurrentArea.Right);
	IsHeaderChange = IsCellChange And (CurrentArea.Top = 1);
	
	If IsCellChange And (SpreadsheetDocumentName <> "SpreadsheetDocument") And (CurrentPredefinedDataName = "") Then
		CurrentArea.ContainsValue = False;
		CurrentArea.Text = ?(IsHeaderChange, CurrentArea.Name, "");
		Return;
	EndIf;
	
	If CurrentArea.Top <= 1 Then
		LeftArea  = ?(CurrentArea.Left = 0, 1, CurrentArea.Left);
		RightArea = ?(CurrentArea.Right = 0, ThisObject[SpreadsheetDocumentName].TableWidth, CurrentArea.Right);
		For ColumnNumber = LeftArea To RightArea Do
			TitleArea = ThisObject[SpreadsheetDocumentName].Area(1, ColumnNumber);
			If TitleArea.Text = "" Then
				TitleArea.Name = "";
			EndIf;
		EndDo;
	EndIf;
		
	AttributeName   = "";
	TSAttributeName = "";
	
	If IsCellChange Or IsHeaderChange Then
		
		TitleArea = ThisObject[SpreadsheetDocumentName].Area(1, CurrentArea.Left);
		AttributeName = TitleArea.Name;
		
		CoordinatesOfArea = New Structure;
		CoordinatesOfArea.Insert("Top", 1);
		CoordinatesOfArea.Insert("Left", TitleArea.Left);
		If AttributeName = AreaName(CoordinatesOfArea) Then
			AttributeName = TitleArea.Text;
		EndIf;
		AttributeName = StrReplace(AttributeName, " ", "");
		
		If IsBlankString(AttributeName) And Not IsColumnsChange Then
			Return;
		EndIf;
		
		If SpreadsheetDocumentName = "SpreadsheetDocument" Then
			SourceOfBankingDetails = FullObjectStructure;
		Else
			TSAttributeName = StrReplace(SpreadsheetDocumentName, "SpreadsheetDocument", "");
			SourceOfBankingDetails = FullObjectStructure[TSAttributeName].Attributes;
		EndIf;
		
		StructureAttributeValue = Undefined;
		SourceOfBankingDetails.Property(AttributeName, StructureAttributeValue);
		
		CheckResult = CellDataValidationResult(CurrentArea, StructureAttributeValue.ValueType, AttributeName);
		If CheckResult.Success Then
			If IsReference(TypeOf(CheckResult.Value)) And (Not ValueIsFilled(CheckResult.Value)) Then
				CurrentArea.ContainsValue = False;
			EndIf;
			
			CurrentArea.Comment.Text = "";
			CurrentArea.BackColor = WebColors.White;
			If ValueIsFilled(CheckResult.Value) Then
				If CheckResult.ThisIsValue Then
					CurrentArea.Value = CheckResult.Value;
				Else
					CurrentArea.Text = CheckResult.Value;
				EndIf;
			EndIf;
			
		Else
			If ValueIsFilled(CheckResult.Value) Then
				If CheckResult.ThisIsValue Then
					CurrentArea.Value = CheckResult.Value;
				Else
					CurrentArea.Text = CheckResult.Value;
				EndIf;
			EndIf;
			
			CurrentArea.Comment.Text = CheckResult.ErrorText;
			CurrentArea.BackColor = WebColors.Pink;
		EndIf;
		
	EndIf;
	
	If IsColumnsChange Then
		
		If SpreadsheetDocumentName = "SpreadsheetDocument" Then
			CurrentPredefinedDataNameColumn = SpreadsheetDocumentColumnByName("SpreadsheetDocument", KeyAttributeName);
			If CurrentPredefinedDataNameColumn = 0 Then
				// Deleted column PredefinedDataName. Return.
				CommonClient.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Нельзя удалять обязательный реквизит с именем ключевого реквизита ""%1"".';
						|en = 'Cannot delete a mandatory attribute that contains the name of a key attribute ""%1"".';"), KeyAttributeName));
				FillSpreadsheetDocuments();
				CurrentPredefinedDataNameColumn = SpreadsheetDocumentColumnByName("SpreadsheetDocument", KeyAttributeName);
			EndIf;
		EndIf;
		
		AttributesSynchronizeWithTable(SpreadsheetDocumentName);
		
		Return;
		
	EndIf;
	
	If IsHeaderChange Then
		
		If CurrentArea.Text = "" Then
			CurrentArea.Text = AttributeName;
		EndIf;
		
		ErrorText = "";
		If StructureAttributeValue = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'У объекта метаданных нет реквизита ""%1"" %2';
																						|en = 'Metadata object does not have the ""%1"" attribute%2';"), AttributeName,
				?(IsBlankString(TSAttributeName), "", StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'табличной части ""%1""';
																												|en = 'table ""%1""';"), TSAttributeName)));
		ElsIf StructureAttributeValue.IsExcludable Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Реквизит ""%1"" %2 исключаемого типа %3';
																						|en = 'Attribute ""%1"" of %2 is of excludable type %3';"), AttributeName,
				?(IsBlankString(TSAttributeName), "", StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'табличной части ""%1""';
																												|en = 'table ""%1""';"), TSAttributeName)), StructureAttributeValue.ValueType);
		ElsIf HasDuplicateColumns(ThisObject[SpreadsheetDocumentName], AttributeName, CurrentArea.Left) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Реквизит ""%1"" %2 уже есть в таблице.';
																						|en = 'Attribute ""%1"" %2 is already in the table.';"), AttributeName,
				?(IsBlankString(TSAttributeName), "", StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'табличной части ""%1""';
																												|en = 'table ""%1""';"), TSAttributeName)));
		EndIf;
		
		If ErrorText <> "" Then
			CoordinatesOfArea = New Structure;
			CoordinatesOfArea.Insert("Top", 1);
			CoordinatesOfArea.Insert("Left", CurrentArea.Left);
			CurrentArea.Name = AreaName(CoordinatesOfArea);
			CurrentArea.ContainsValue = False;
			CurrentArea.Text = "";
			
			ShowUserNotification(ErrorText);
		Else
			AttributesSynchronizeWithTable(SpreadsheetDocumentName);
			FillSpreadsheetDocuments();
		EndIf;
		
		Return;
		
	EndIf;
	
	If IsRowsChange Then
		
		If SpreadsheetDocumentName = "SpreadsheetDocument" Then
			SourceTable1 = DataTable;
		Else
			FoundRows = DataTable.FindRows(New Structure(KeyAttributeName, CurrentPredefinedDataName));
			If FoundRows.Count() = 0 Then
				// Algorithm is aborted.
				Return;
			EndIf;
			SourceTable1 = FoundRows[0][TabularSectionName];
		EndIf;
		
		If ThisObject[SpreadsheetDocumentName].TableHeight-1 < SourceTable1.Count() Then
			
			// Rows were removed.
			IndexOf = CurrentArea.Bottom - 2;
			While IndexOf >= CurrentArea.Top - 2 Do
				SourceTable1.Delete(SourceTable1[IndexOf]);
				IndexOf = IndexOf - 1;
			EndDo;
			
			AttachIdleHandler("OutputCurrentItemTabularSections", 0.1, True);
			
			Return;
			
		EndIf;
		
	EndIf;
	
	SpreadsheetDocumentOnAreaChange(SpreadsheetDocumentName, CurrentArea);
	
	Items.RollbackToLastStableVersion.Enabled = True;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttributes

&AtClient
Procedure AttributesOnChange(Item)
	
	Items.AttributesReread.Enabled = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CheckAll(Command)
	
	HeaderAttributes = Attributes.GetItems();
	
	For Each Attribute In HeaderAttributes Do
		
		If Attribute.IsExcludable Then
			Continue;
		EndIf;
		
		Attribute.Check = True;
		
		If Attribute.IsTabularSection Then
			
			TSAttributes = Attribute.GetItems();
			
			For Each TSProps In TSAttributes Do
				If TSProps.IsExcludable Then
					Continue;
				EndIf;
				TSProps.Check = True;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	FillDataTable();
	FillSpreadsheetDocuments();
	CheckTabularSectionsDisplay();
	ChangeSectionPage();
	
	ConvertToCodeAtServer();
	CurrentPredefinedDataName = "";
	HeaderAreaName = "";
	
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	HeaderAttributes = Attributes.GetItems();
	
	For Each Attribute In HeaderAttributes Do
		
		If Attribute.IsExcludable Then
			Continue;
		EndIf;
		
		If StrCompare(Attribute.Name, DefaultKeyAttributeName()) = 0 Then
			Continue;
		EndIf;
		
		If Attribute.Name = KeyAttributeName Then
			Continue;
		EndIf;
		
		Attribute.Check = False;
		
		If Not Attribute.IsTabularSection Then
			Continue;
		EndIf;
		
		TSAttributes = Attribute.GetItems();
		For Each TSProps In TSAttributes Do
			TSProps.Check = False;
		EndDo;
		
	EndDo;
	
	FillSpreadsheetDocuments();
	CheckTabularSectionsDisplay();
	ChangeSectionPage();
	
EndProcedure

&AtClient
Procedure Reread(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	UpdateTableAndCode();
	
EndProcedure

&AtClient
Procedure HideShowAttributeTree(Command)
	
	HideShowAttributeTreeAtServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ThisIsMultilingualConfiguration()
	
	Return (Metadata.Languages.Count() > 1);
	
EndFunction

&AtServerNoContext
Function InputByStringOptionsForType(AttributeType);
	
	InputByString = New Structure;
	
	DefaultAttributeValue = AttributeType.AdjustValue();
	AttributeMetadata = DefaultAttributeValue.Metadata(); // MetadataObjectCatalog, MetadataObjectDocument 
	
	If Common.IsEnum(AttributeMetadata) Then
		Return InputByString;
	EndIf;
	
	For Each InputByStringAttribute In AttributeMetadata.InputByString Do
		SearchAttributeType = "String";
		StandardAttributes = AttributeMetadata.StandardAttributes;
		If InputByStringAttribute.Name = "Code" And StandardAttributes.Code.Type.ContainsType(Type("Number")) Then
			SearchAttributeType = "Number";
		EndIf;
		InputByString.Insert(InputByStringAttribute.Name, SearchAttributeType);
	EndDo;
	
	Return InputByString;
	
EndFunction

&AtServerNoContext
Function FullTypeMetadataName(AttributeType)
	
	DefaultAttributeValue = AttributeType.AdjustValue();
	
	AttributeMetadata = DefaultAttributeValue.Metadata();
	
	Return AttributeMetadata.FullName();
	
EndFunction

&AtServerNoContext
Function ObjectAttributeValue(Object, PropertyName)
	
	Return Common.ObjectAttributeValue(Object, PropertyName);
	
EndFunction

&AtServerNoContext
Function ContainsSimpleTypesOnly(AttributeType)
	
	If AttributeType = Undefined Then
		Return False;
	EndIf;
	
	TypesDetailsString = New TypeDescription("String");
	TypesDetailsBoolean = New TypeDescription("Boolean");
	TypesDetailsDate = New TypeDescription("Date");
	TypesDetailsNumber = New TypeDescription("Number");
	
	Basic = True;
	For Each Type In AttributeType.Types() Do
		Basic = Basic And (TypesDetailsString.ContainsType(Type)
								Or TypesDetailsBoolean.ContainsType(Type)
								Or TypesDetailsDate.ContainsType(Type)
								Or TypesDetailsNumber.ContainsType(Type));
	EndDo;
	
	Return Basic;
	
EndFunction

&AtServerNoContext
Function IsEnum(AttributeType)
	
	If AttributeType = Undefined Then
		Return False;
	EndIf;
	
	DefaultAttributeValue = AttributeType.AdjustValue();
	
	If BusinessProcesses.RoutePointsAllRefsType().ContainsType(TypeOf(DefaultAttributeValue)) Then
		Return False;
	EndIf;
	
	If AttributeType = Type("TypeDescription") Or AttributeType = New TypeDescription("TypeDescription") Then
		Return False;
	EndIf;
	
	Try
		AttributeMetadata = DefaultAttributeValue.Metadata();
	Except
		Return False;
	EndTry;
	
	Return Common.IsEnum(AttributeMetadata);
	
EndFunction

&AtServerNoContext
Function IsReferenceType(AttributeType)
	
	If AttributeType = Undefined Then
		Return False;
	EndIf;
	
	If AttributeType = Type("TypeDescription") Or AttributeType = New TypeDescription("TypeDescription") Then
		Return False;
	EndIf;
	
	DefaultAttributeValue = AttributeType.AdjustValue();
	
	If BusinessProcesses.RoutePointsAllRefsType().ContainsType(TypeOf(DefaultAttributeValue)) Then
		Return False;
	EndIf;
	
	Try
		Return Common.IsRefTypeObject(DefaultAttributeValue.Metadata());
	Except
		// ACC:280
	EndTry;
	
	Return False;
	
EndFunction

&AtServerNoContext
Function IsAccountKind(AttributeType)
	
	If AttributeType = Undefined Then
		Return False;
	EndIf;
	
	AccountKindTypesDetails = New TypeDescription("AccountType");
	If (AttributeType = Type("AccountType")) Or (AttributeType = AccountKindTypesDetails) Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtServerNoContext
Function IsChartOfAccounts(AttributeType)
	
	If AttributeType = Undefined Then
		Return False;
	EndIf;
	
	If AttributeType = Type("TypeDescription") Or AttributeType = New TypeDescription("TypeDescription") Then
		Return False;
	EndIf;
	
	DefaultAttributeValue = AttributeType.AdjustValue();
	
	Return Common.IsChartOfAccounts(DefaultAttributeValue.Metadata());
	
EndFunction

&AtServerNoContext
Function IsTypesDetails(AttributeType)
	
	If AttributeType = Undefined Then
		Return False;
	EndIf;
	
	Return AttributeType = Type("TypeDescription") Or AttributeType = New TypeDescription("TypeDescription");
	
EndFunction

&AtServerNoContext
Function IsString(AttributeType)
	
	If AttributeType = Undefined Then
		Return False;
	EndIf;
	
	TypesDetailsBoolean = New TypeDescription("String");
	For Each Type In AttributeType.Types() Do
		If Not TypesDetailsBoolean.ContainsType(Type) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

&AtServerNoContext
Function ThisIsBoolean(AttributeType)
	
	If AttributeType = Undefined Then
		Return False;
	EndIf;
	
	TypesDetailsBoolean = New TypeDescription("Boolean");
	For Each Type In AttributeType.Types() Do
		If Not TypesDetailsBoolean.ContainsType(Type) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

&AtServerNoContext
Function IsNumber(AttributeType, Digits = 0)
	
	If AttributeType = Undefined Then
		Return False;
	EndIf;
	
	TypesDetailsNumber = New TypeDescription("Number");
	For Each Type In AttributeType.Types() Do
		If Not TypesDetailsNumber.ContainsType(Type) Then
			Return False;
		EndIf;
	EndDo;
	
	Digits = AttributeType.NumberQualifiers.Digits;
	Return True;
	
EndFunction

&AtServerNoContext
Function IsDate(AttributeType, Var_DateFractions = Undefined)
	
	If AttributeType = Undefined Then
		Return False;
	EndIf;
	
	TypesDetailsDate = New TypeDescription("Date");
	For Each Type In AttributeType.Types() Do
		If Not TypesDetailsDate.ContainsType(Type) Then
			Return False;
		EndIf;
	EndDo;
	
	Var_DateFractions = AttributeType.DateQualifiers.DateFractions;
	
	Return True;
	
EndFunction

&AtServerNoContext
Function IsReference(ValueType)
	
	Return Common.IsReference(ValueType);
	
EndFunction

&AtServerNoContext
Function GetTypesDetailsPresentation(TypeDescription)
	
	If Not ValueIsFilled(TypeDescription) Then
		Return "";
	EndIf;
	
	TypesDetailsPresentation = "";
	Separator = "";
	For Each Type In TypeDescription.Types() Do
		MetadataObjectByType = Metadata.FindByType(Type);
		If MetadataObjectByType = Undefined Then
			TypesDetailsPresentation = TypesDetailsPresentation + Separator + String(Type);
			Separator = "; ";
		Else
			TypesDetailsPresentation = TypesDetailsPresentation + Separator + MetadataObjectByType.FullName();
			Separator = "; ";
		EndIf;
	EndDo;
	
	Return TypesDetailsPresentation;
	
EndFunction

&AtServerNoContext
Function TypeCanContainPredefinedValues(AttributeType)
	
	DefaultAttributeValue = AttributeType.AdjustValue();
	AttributeMetadata = DefaultAttributeValue.Metadata();
	
	Return Common.IsCatalog(AttributeMetadata)
			Or Common.IsChartOfAccounts(AttributeMetadata)
			Or Common.IsChartOfCharacteristicTypes(AttributeMetadata)
			Or Common.IsChartOfCalculationTypes(AttributeMetadata);
	
EndFunction

&AtServer
Function RefValueByDescription(Description, Var_AttributeName)
	
	QueryText = "SELECT TOP 1
		|	&MetadataObject AS Ref
		|FROM
		|	&Table AS MetadataObject
		|WHERE
		|	&Filter = &Description";
	
	QueryText = StrReplace(QueryText, "&Table", Object.MetadataObject);
	QueryText = StrReplace(QueryText, "&MetadataObject", 
		StringFunctionsClientServer.SubstituteParametersToString("MetadataObject.%1", Var_AttributeName));
	QueryText = StrReplace(QueryText, "&Filter", 
		StringFunctionsClientServer.SubstituteParametersToString("MetadataObject.%1.Description", Var_AttributeName));

	Query = New Query(QueryText);
	Query.SetParameter("Description", Description);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		ValueFound = Selection.Ref;
	Else
		ValueFound = PredefinedValue(Object.MetadataObject + ".EmptyRef");
		
		MetadataObject = Metadata.FindByFullName(Object.MetadataObject);
		If MetadataObject <> Undefined Then
			MetadataObjectAttribute1 =  MetadataObject.Attributes.Find(Var_AttributeName);
			If MetadataObjectAttribute1 <> Undefined Then
				For Each AttributeTypes In MetadataObjectAttribute1.Type.Types() Do
					If IsReference(AttributeTypes) Then
						FullName = Metadata.FindByType(AttributeTypes).FullName();
						ValueFound = PredefinedValue(FullName + ".EmptyRef");
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
	EndIf;
	
	Return ValueFound;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Metadata object attributes available for selection.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("AttributesCheck");
	
	AvailabilityFilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AvailabilityFilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	KeyAttributeNames = New ValueList;
	KeyAttributeNames.Add(DefaultKeyAttributeName());
	KeyAttributeNames.Add(KeyAttributeName);
	
	ItemFilter = AvailabilityFilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Attributes.Name");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = KeyAttributeNames;
	
	ItemFilter = AvailabilityFilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Attributes.IsExcludable");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// NStr parameter available only for non-localized string attributes.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("AttributesUseNStr");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Attributes.AttributeString");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

&AtClient
Function AreaName(CoordinatesOfArea, SpreadsheetDocumentName = "")
	
	Var Top, Left, Bottom, Right;
	
	If Not CoordinatesOfArea.Property("Top", Top)Then
		Top = 0;
	EndIf;
	
	If Not CoordinatesOfArea.Property("Left", Left) Then
		Left = 0;
	EndIf;
	
	If Not CoordinatesOfArea.Property("Bottom", Bottom) Then
		Bottom = 0;
	EndIf;
	
	If Not CoordinatesOfArea.Property("Right", Right) Then
		Right = 0;
	EndIf;
	
	If SpreadsheetDocumentName = "" Then
		AdrTop  = ?(Top  = 0, "", "R" + Format(Top, "NG="));
		AdrLeft  = ?(Left  = 0, "", "C" + Format(Left, "NG="));
		AdrBottom   = ?(Bottom   = 0, "", "R" + Format(Bottom, "NG="));
		AdrRight = ?(Right = 0, "", "C" + Format(Right, "NG="));
	Else
		AdrTop  = ?(Top  = 0, "R1", "R" + Format(Top, "NG="));
		AdrLeft  = ?(Left  = 0, "C1", "C" + Format(Left, "NG="));
		AdrBottom   = ?(Bottom   = 0, "R" + ThisObject[SpreadsheetDocumentName].TableHeight, "R" + Format(Bottom, "NG="));
		AdrRight = ?(Right = 0, "C" + ThisObject[SpreadsheetDocumentName].TableWidth, "C" + Format(Right, "NG="));
	EndIf;
	
	Return AdrTop + AdrLeft + AdrBottom + AdrRight;
	
EndFunction

&AtClient
Procedure AttributesSetMarkInList(Data, Check, CheckParent)
	
	// Mark as a subordinate item.
	RowItems = Data.GetItems();
	
	For Each Item In RowItems Do
		If Item.IsExcludable Then
			Continue;
		EndIf;
		Item.Check = Check;
		AttributesSetMarkInList(Item, Check, False);
	EndDo;
	
	// Check the parent item.
	Parent = Data.GetParent();
	
	If CheckParent And Parent <> Undefined Then
		AttributesCheckParent(Parent);
	EndIf;
	
EndProcedure

&AtClient
Procedure AttributesCheckParent(Parent)
	
	ParentMark = False;
	RowItems = Parent.GetItems();
	
	For Each Item In RowItems Do
		If Item.Check Then
			ParentMark = True;
			Break;
		EndIf;
	EndDo;
	
	Parent.Check = ParentMark;
	
EndProcedure

&AtClient
Procedure AttributesSynchronizeWithTable(SpreadsheetDocumentName = "SpreadsheetDocument", InitializationData = Undefined)
	
	IsTabularSection = False;
	
	If InitializationData = Undefined And SpreadsheetDocumentName = "SpreadsheetDocument" Then
		InitializationData = Attributes;
	ElsIf InitializationData = Undefined Then
		HeaderAttributes = Attributes.GetItems();
		For Each Attribute In HeaderAttributes Do
			If Attribute.IsTabularSection And Attribute.Name = StrReplace(SpreadsheetDocumentName, "SpreadsheetDocument", "") Then
				InitializationData = Attribute;
				IsTabularSection = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	AttributesByTable = "";
	For ColumnNumber = 1 To ThisObject[SpreadsheetDocumentName].TableWidth Do
		ColumnHeaderArea1 = ThisObject[SpreadsheetDocumentName].Area(1, ColumnNumber);
		AttributeName = ColumnHeaderArea1.Name;
		CoordinatesOfArea = New Structure;
		CoordinatesOfArea.Insert("Top", 1);
		CoordinatesOfArea.Insert("Left", ColumnNumber);
		If AttributeName = AreaName(CoordinatesOfArea) Then
			AttributeName = TrimAll(ColumnHeaderArea1.Text)
		EndIf;
		AttributesByTable = AttributesByTable + AttributeName + ",";
	EndDo;
	
	ColumnsToDeleteArray = New Array;
	
	AttributesByTable = Upper(AttributesByTable);
	InitializationAttributes = InitializationData.GetItems();
	
	For Each Attribute In InitializationAttributes Do
		
		If Not Attribute.IsTabularSection Then
			
			Check = StrFind(AttributesByTable, Upper(Attribute.Name) + ",") > 0;
			Attribute.Check = Check;
			
			If Attribute.ToLocalize Then
				
				LColumnsArray = New Array;
				For Each LocalizationLanguage In Object.Languages Do
					If LocalizationLanguage.DefaultLanguage Then
						Continue;
					EndIf;
					LColumnName = Attribute.Name + "_" + LocalizationLanguage.LanguageCode;
					If StrFind(AttributesByTable, Upper(LColumnName) + ",") > 0 Then
						LColumnsArray.Add(LColumnName);
					EndIf;
				EndDo;
				
				If Check Then
					If LColumnsArray.Count() = Object.Languages.Count() - 1 Then
						Continue;
					EndIf;
					
					// A column is missing. Delete the whole localization group.
					Attribute.Check = False;
					ColumnNumber = SpreadsheetDocumentColumnByName(SpreadsheetDocumentName, Attribute.Name);
					ColumnsToDeleteArray.Add(ColumnNumber);
					For Each LColumnName In LColumnsArray Do
						ColumnNumber = SpreadsheetDocumentColumnByName(SpreadsheetDocumentName, LColumnName);
						ColumnsToDeleteArray.Add(ColumnNumber);
					EndDo;
					
				Else
					For Each LColumnName In LColumnsArray Do
						ColumnNumber = SpreadsheetDocumentColumnByName(SpreadsheetDocumentName, LColumnName);
						ColumnsToDeleteArray.Add(ColumnNumber);
					EndDo;
				EndIf;
			EndIf;
			
		ElsIf DisplayTabularSections Then
			FormField = Items.Find("SpreadsheetDocument" + Attribute.Name);
			If FormField <> Undefined Then
				AttributesSynchronizeWithTable("SpreadsheetDocument" + Attribute.Name, Attribute);
				AttributesCheckParent(Attribute);
			EndIf;
		EndIf;
		
	EndDo;
	
	If ColumnsToDeleteArray.Count() > 0 Then
		SpreadsheetDocumentDeleteColumns(SpreadsheetDocumentName, ColumnsToDeleteArray);
	EndIf;
	
	If IsTabularSection Then
		
		AttributesCheckParent(InitializationData);
		
		If Not InitializationData.Check Then
			FirstTSName = CheckTabularSectionsDisplay();
			
			If DisplayTabularSections Then
				If FirstTSName <> "" Then
					CurrentItem = Items["SpreadsheetDocument" + FirstTSName];
					Items["SpreadsheetDocument"+FirstTSName].CurrentArea = ThisObject["SpreadsheetDocument"+FirstTSName].Area(1, 1);
				EndIf;
				Items["Page" + StrReplace(SpreadsheetDocumentName, "SpreadsheetDocument", "")].Visible = False;
				
				CurrentItem = Items.SpreadsheetDocument;
				SpreadsheetDocument.CurrentArea = Items.SpreadsheetDocument.CurrentArea;
			EndIf;
			
		EndIf;
		
		ChangeSectionPage();
		
	EndIf;
	
EndProcedure

&AtClient
Function PredefinedDataNameByRow(LineNumber);
	
	If LineNumber < 2 Then
		Return "";
	EndIf;
	
	If CurrentPredefinedDataNameColumn <> 0 Then
		mArea = SpreadsheetDocument.Area(1, CurrentPredefinedDataNameColumn);
		CoordinatesOfArea = New Structure;
		CoordinatesOfArea.Insert("Top", 1);
		CoordinatesOfArea.Insert("Left", CurrentPredefinedDataNameColumn);
		If Not (mArea.Name = KeyAttributeName 
				Or (mArea.Name = AreaName(CoordinatesOfArea) And mArea.Text = KeyAttributeName)) Then
			CurrentPredefinedDataNameColumn = 0;
		EndIf;
	EndIf;
	
	If CurrentPredefinedDataNameColumn = 0 Then
		CurrentPredefinedDataNameColumn = SpreadsheetDocumentColumnByName("SpreadsheetDocument", KeyAttributeName);
	EndIf;
	
	If CurrentPredefinedDataNameColumn = 0 Then
		Return "";
	EndIf;
	
	PredefinedDataNameArea = SpreadsheetDocument.Area(LineNumber, CurrentPredefinedDataNameColumn);
	If PredefinedDataNameArea.ContainsValue Then
		Return PredefinedDataNameArea.Value;
	Else
		Return TrimAll(PredefinedDataNameArea.Text);
	EndIf;
	
EndFunction

&AtClient
Function SpreadsheetDocumentColumnByName(SpreadsheetDocumentName, ColumnName = "")
	
	If IsBlankString(ColumnName) Then
		ColumnName = KeyAttributeName;
	EndIf;
	
	For ColumnNumber = 1 To SpreadsheetDocument.TableWidth Do
		
		Result = ThisObject[SpreadsheetDocumentName].Area(1, ColumnNumber);
		
		CoordinatesOfArea = New Structure;
		CoordinatesOfArea.Insert("Top", 1);
		CoordinatesOfArea.Insert("Left", CurrentPredefinedDataNameColumn);
		If Result.Name = ColumnName Or (Result.Name = AreaName(CoordinatesOfArea) And Result.Text = ColumnName) Then
			Return ColumnNumber;
		EndIf;
		
	EndDo;
	
	Return 0;
	
EndFunction

&AtClient
Procedure GetAutoCompleteValue(SearchString, ChoiceData)
	
	If IsBlankString(SearchString) Then
		
		ChoiceData = Undefined;
		Return;
	EndIf;
	
	ChoiceData = New ValueList;
	
	For Each String In Items.MetadataObject.ChoiceList Do
		
		If StrFind(Lower(String.Value), Lower(SearchString)) = 0 Then
			Continue;
		EndIf;
		
		PresentationRow = String.Value;
		FormattedString = SelectFragmentInString(PresentationRow, SearchString);
		ChoiceData.Add(String.Value, New FormattedString(FormattedString));
		
	EndDo;
	
EndProcedure

&AtClient
Function SelectFragmentInString(Val String, Val Particle)
	
	RowsArray = New Array;
	BoldFont = New Font(,, True); // ACC:1345
	
	Position = 1;
	FragmentLength = StrLen(Particle);
	
	SubstringsString = StrReplace(Upper(String),Upper(Particle), Chars.LF);
	For IndexOf = 1 To StrLineCount(SubstringsString) Do
		
		Substring = StrGetLine(SubstringsString, IndexOf);
		StringLength = StrLen(Substring);
		RowsArray.Add(Mid(String,Position, StringLength));
		Position = Position + StringLength;
		
		FormattedFragment = New FormattedString(Mid(String,Position, FragmentLength), BoldFont, WebColors.Green);
		RowsArray.Add(FormattedFragment);
		Position = Position + FragmentLength;
		
	EndDo;
	
	Return RowsArray;
	
EndFunction

&AtClient
Procedure ChangeSectionPage()
	
	If FormMode = "TablePage" Then
		Items.SectionsGroup.CurrentPage = Items.TableWithTSPage;
	ElsIf FormMode = "CodePage" Then
		Items.SectionsGroup.CurrentPage = Items.CodePage;
	Else
		Items.SectionsGroup.CurrentPage = Items.TablePage;
	EndIf;
	
EndProcedure

// Parameters:
//   Result - Arbitrary
//   AdditionalParameters - See SpreadsheetDocumentParameters
// 
&AtClient
Procedure SpreadsheetDocumentSelectionReferenceTypeAttributeSelectionCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	// Sync DataTable.
	TabularSectionName = StrReplace(AdditionalParameters.SpreadsheetDocumentName, "SpreadsheetDocument", "");
	CurrentPredefinedDataNameColumn = SpreadsheetDocumentColumnByName("SpreadsheetDocument", KeyAttributeName);
	SpreadsheetDocumentBordersChangesSynchronization(TabularSectionName, AdditionalParameters.Area.Top-2);
	SpreadsheetDocumentDataChangesSynchronization(Result, AdditionalParameters.AttributeName, TabularSectionName, AdditionalParameters.LineNumber);
	
	AdditionalParameters.Area.Text = String(Result);
	If Not IsEnum(AdditionalParameters.ValueType)
		And TypeCanContainPredefinedValues(AdditionalParameters.ValueType)
		And ValueIsFilled(Result)
		And ObjectAttributeValue(Result, "Predefined")
		And AdditionalParameters.AttributeName <> "Parent" Then
		
		AdditionalParameters.Area.Text = ObjectAttributeValue(Result, KeyAttributeName);
	EndIf;
	
	TablePresentationsOnBordersChange(AdditionalParameters.SpreadsheetDocumentName, AdditionalParameters.Area);
	
EndProcedure

// Parameters:
//   Result - Arbitrary
//   AdditionalParameters - See SpreadsheetDocumentParameters
// 
&AtClient
Procedure SpreadsheetDocumentSelectionTypesDetailsAttributeSelectionCompletion(Result, AdditionalParameters) Export
	
	// Sync DataTable.
	TabularSectionName = StrReplace(AdditionalParameters.SpreadsheetDocumentName, "SpreadsheetDocument", "");
	SpreadsheetDocumentBordersChangesSynchronization(TabularSectionName, AdditionalParameters.Area.Top - 2);
	SpreadsheetDocumentDataChangesSynchronization(Result, AdditionalParameters.AttributeName, TabularSectionName, AdditionalParameters.LineNumber);
	
	AdditionalParameters.Area.Text = GetTypesDetailsPresentation(Result);
	
	TablePresentationsOnBordersChange(AdditionalParameters.SpreadsheetDocumentName, AdditionalParameters.Area);
	
EndProcedure

// Parameters:
//   Result - Arbitrary
//   AdditionalParameters - See SpreadsheetDocumentParameters
// 
&AtClient
Procedure SpreadsheetDocumentSelectionAccountKindAttributeSelectionCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	// Sync DataTable
	TabularSectionName = StrReplace(AdditionalParameters.SpreadsheetDocumentName, "SpreadsheetDocument", "");
	SpreadsheetDocumentBordersChangesSynchronization(TabularSectionName, AdditionalParameters.Area.Top - 2);
	SpreadsheetDocumentDataChangesSynchronization(Result, AdditionalParameters.AttributeName, TabularSectionName, AdditionalParameters.LineNumber);
	
	AdditionalParameters.Area.Text = AccountKindPresentation(Result.Value);
	
	DataString1 = DataTable.Get(AdditionalParameters.LineNumber);
	DataString1.Kind = Result.Value;
	
	TablePresentationsOnBordersChange(AdditionalParameters.SpreadsheetDocumentName, AdditionalParameters.Area);
	
EndProcedure

&AtClient
Function SpreadsheetDocumentOnChangeModified(Item)
	
	Var CellStructure_;
	
	If ActiveAreaStructure = Undefined Then
		Return True;
	EndIf;
	
	SpreadsheetDocumentName = StrReplace(Item.Name, "NoTS", "");
	
	ItemModified = False;
	SourceArea = Item.CurrentArea;
	TopOfArea  = ?(SourceArea.Top  = 0, 1, SourceArea.Top);
	BottomOfArea   = ?(SourceArea.Bottom   = 0, ThisObject[SpreadsheetDocumentName].TableHeight, SourceArea.Bottom);
	LeftField  = ?(SourceArea.Left  = 0, 1, SourceArea.Left);
	AreaRight = ?(SourceArea.Right = 0, ThisObject[SpreadsheetDocumentName].TableWidth, SourceArea.Right);
	
	For LineNumber = TopOfArea To BottomOfArea Do
		
		For ColumnNumber = LeftField To AreaRight Do
			CoordinatesOfArea = New Structure;
			CoordinatesOfArea.Insert("Top", LineNumber);
			CoordinatesOfArea.Insert("Left", ColumnNumber);
			AreaName = AreaName(CoordinatesOfArea);
			If Not ActiveAreaStructure.Property(AreaName, CellStructure_) Then
				Continue;
			EndIf;
			Cell = ThisObject[SpreadsheetDocumentName].Area(AreaName);
			ItemModified = ItemModified Or Cell.Name <> CellStructure_.Name;
			ItemModified = ItemModified Or Cell.ContainsValue <> CellStructure_.ContainsValue;
			If Cell.ContainsValue Then
				ItemModified = ItemModified Or Cell.Value <> CellStructure_.Value;
				ItemModified = ItemModified Or Cell.ValueType <> CellStructure_.ValueType;
			EndIf;
			ItemModified = ItemModified Or (Cell.Text <> CellStructure_.Text);
			If ItemModified Then
				Return True;
			EndIf;
		EndDo;
	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Procedure SpreadsheetDocumentOnAreaChange(SpreadsheetDocumentName, CellArea)
	
	TabularSectionName = StrReplace(SpreadsheetDocumentName, "SpreadsheetDocument", "");
	
	ChangeAreaTop  = ?(CellArea.Top = 0, 1, CellArea.Top);
	ChangeAreaBottom   = ?(CellArea.Bottom = 0, ThisObject[SpreadsheetDocumentName].TableHeight, CellArea.Bottom);
	ChangeAreaLeft  = ?(CellArea.Left = 0, 1, CellArea.Left);
	ChangeAreaRight = ?(CellArea.Right = 0, ThisObject[SpreadsheetDocumentName].TableWidth, CellArea.Right);
	
	AttributesNamesByColumns = New Structure;
	For ColumnNumber = ChangeAreaLeft To ChangeAreaRight Do
		ColumnHeaderArea = ThisObject[SpreadsheetDocumentName].Area(1, ColumnNumber, 1, ColumnNumber);
		
		AttributeName = ColumnHeaderArea.Name;
		CoordinatesOfArea = New Structure;
		CoordinatesOfArea.Insert("Top", 1);
		CoordinatesOfArea.Insert("Left", ColumnNumber);
		If AttributeName = AreaName(CoordinatesOfArea) Then
			AttributeName = ColumnHeaderArea.Text;
		EndIf;
		AttributeName = StrReplace(AttributeName, " ", "");
		
		AttributesNamesByColumns.Insert("Column"+ColumnNumber, AttributeName);
		
	EndDo;
	
	TypingRequired = False;
	AreaDataTable.Clear();
	For ColumnNumber = ChangeAreaLeft To ChangeAreaRight Do
		
		AttributeName = AttributesNamesByColumns["Column" + ColumnNumber];
		
		If IsBlankString(AttributeName) Then
			Continue;
		EndIf;
		
		StructureAttribute = Undefined;
		MainLAttributeName = "";
		ToLocalize = Left(Right(AttributeName, 3),1) = "_" And Object.Languages.FindRows(New Structure("LanguageCode", Right(AttributeName, 2))).Count() > 0;
		If ToLocalize Then
			MainLAttributeName = Left(AttributeName, StrLen(AttributeName) - 3);
		EndIf;
		
		If TabularSectionName = "" Then
			If (Not ToLocalize And Not FullObjectStructure.Property(AttributeName, StructureAttribute))
				Or (ToLocalize And Not FullObjectStructure.Property(MainLAttributeName, StructureAttribute)) Then
				Continue;
			EndIf;
		ElsIf FullObjectStructure.Property(TabularSectionName, StructureAttribute) Then
			TSStructureAttribute = Undefined;
			If (Not ToLocalize And Not StructureAttribute.Attributes.Property(AttributeName, TSStructureAttribute))
				Or (ToLocalize And Not StructureAttribute.Attributes.Property(MainLAttributeName, TSStructureAttribute)) Then
				Continue;
			EndIf;
			StructureAttribute = TSStructureAttribute;
		Else
			Continue;
		EndIf;
		
		For LineNumber = ChangeAreaTop To ChangeAreaBottom Do
			
			CoordinatesOfArea = New Structure;
			CoordinatesOfArea.Insert("Top", LineNumber);
			CoordinatesOfArea.Insert("Left", ColumnNumber);
			AreaNameCells = AreaName(CoordinatesOfArea);
			TableCellArea = ThisObject[SpreadsheetDocumentName].Area(AreaNameCells);
			If TableCellArea.ContainsValue And TableCellArea.ValueType = StructureAttribute.ValueType Then
				// This is a simple type.
				NewRow = AreaDataTable.Add();
				NewRow.AttributeName = AttributeName;
				NewRow.LineNumber = TableCellArea.Top - 2;
				NewRow.AreaType = TableCellArea.ValueType;
				NewRow.Result = TableCellArea.Value;
				NewRow.ShouldBeTypified = False;
				NewRow.AreaNameCells = AreaNameCells;
			Else // Refine the result type.
				NewRow = AreaDataTable.Add();
				NewRow.AttributeName = AttributeName;
				NewRow.LineNumber = TableCellArea.Top - 2;
				NewRow.AreaType = StructureAttribute.ValueType;
				NewRow.Result = Undefined;
				NewRow.Text = TableCellArea.Text;
				NewRow.ShouldBeTypified = True;
				NewRow.AreaNameCells = AreaNameCells;
				TypingRequired = True;
			EndIf;
		EndDo;
		
	EndDo;
	
	If TypingRequired Then
		SpreadsheetDocumentOnChangeValuesTyping(TabularSectionName);
	EndIf;
	CurrentPredefinedDataNameColumn = SpreadsheetDocumentColumnByName("SpreadsheetDocument", KeyAttributeName);
	
	SpreadsheetDocumentBordersChangesSynchronization(TabularSectionName, ChangeAreaBottom - 2);
	
	For Each TableRow In AreaDataTable Do
		
		If TableRow.ShouldBeTypified And TableRow.BasicType Then
			TableCellArea = ThisObject[SpreadsheetDocumentName].Area(TableRow.AreaNameCells);
			TableCellArea.ContainsValue = True;
			TableCellArea.ValueType = TableRow.AreaType;
			TableCellArea.Value = TableRow.Result;
		EndIf;
		
		SpreadsheetDocumentDataChangesSynchronization(TableRow.Result, TableRow.AttributeName, TabularSectionName, TableRow.LineNumber);
		
	EndDo;
	
	TablePresentationsOnBordersChange(SpreadsheetDocumentName, CellArea);
	AreaDataTable.Clear();
	
EndProcedure

&AtClient
Procedure TablePresentationsOnBordersChange(SpreadsheetDocumentName, CurrentArea)
	
	LineNumber = CurrentArea.Bottom;
	TableWidth = ThisObject[SpreadsheetDocumentName].TableWidth;
	
	ColumnHeaderArea = ThisObject[SpreadsheetDocumentName].Area(1, 1, 1, );
	BeginningRowIndex = 0;
	For IndexOf = 2 To LineNumber Do
		LeftArea = ThisObject[SpreadsheetDocumentName].Area(IndexOf, 1, IndexOf, 1);
		RightArea = ThisObject[SpreadsheetDocumentName].Area(IndexOf, TableWidth, IndexOf, TableWidth);
		If LeftArea.RightBorder = ColumnHeaderArea.RightBorder And RightArea.RightBorder = ColumnHeaderArea.RightBorder Then
			Continue;
		EndIf;
		BeginningRowIndex = IndexOf;
		Break;
	EndDo;
	
	If BeginningRowIndex = 0 Then
		Return;
	EndIf;
	
	If SpreadsheetDocumentName = "SpreadsheetDocument" Then
		// Start table repopulation.
		HeaderAreaName = "";
	EndIf;
	
	AreaProperties = New Structure("BackColor, TopBorder, LeftBorder, BottomBorder, RightBorder");
	For ColumnIndex = 1 To TableWidth Do
		ColumnHeaderArea = ThisObject[SpreadsheetDocumentName].Area(1, ColumnIndex, 1, ColumnIndex);
		FillPropertyValues(AreaProperties, ColumnHeaderArea);
		For RowIndex = BeginningRowIndex To LineNumber Do
			Area = ThisObject[SpreadsheetDocumentName].Area(RowIndex, ColumnIndex, RowIndex, ColumnIndex);
			FillPropertyValues(Area, AreaProperties);
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure OutputCurrentItemTabularSections()
	
	If Not DisplayTabularSections Then
		Return;
	EndIf;
	
	mHeaderString = SpreadsheetDocument.CurrentArea.Top;
	
	PredefinedDataName = PredefinedDataNameByRow(mHeaderString);
	If CurrentPredefinedDataName <> PredefinedDataName Then
		CurrentPredefinedDataName = PredefinedDataName;
		OutputTabularSectionsOfCurrentItemAtServer(mHeaderString, CurrentPredefinedDataName);
	EndIf;
	
EndProcedure

&AtClient
Function HasDuplicateColumns(Source, ColumnName, ColumnToCheckNumber = 0)
	
	ColumnsCount = 0;
	For ColumnNumber = 1 To Source.TableWidth Do
		If ColumnNumber = ColumnToCheckNumber Then
			Continue;
		EndIf;
		TitleArea = Source.Area(1, ColumnNumber);
		AttributeName = TitleArea.Name;
		CoordinatesOfArea = New Structure;
		CoordinatesOfArea.Insert("Top", 1);
		CoordinatesOfArea.Insert("Left", ColumnNumber);
		If AttributeName = AreaName(CoordinatesOfArea) Then
			AttributeName = TitleArea.Text;
		EndIf;
		AttributeName = StrReplace(AttributeName, " ", "");
		
		If AttributeName = ColumnName Then
			ColumnsCount = ColumnsCount + 1;
		EndIf;
		
	EndDo;
	
	Return ColumnsCount > ?(ColumnToCheckNumber = 0, 1, 0);

EndFunction

&AtClient
Procedure SpreadsheetDocumentBordersChangesSynchronization(TabularSectionName, LineNumber)
	
	If IsBlankString(TabularSectionName) Then
		NewPresentation = "";
		While DataTable.Count() < LineNumber+1 Do
			NewRow = DataTable.Add();
			NewPresentation = GetNewPredefinedDataNameByDefault();
			NewRow.PredefinedDataName = NewPresentation;
			AreaKey1 = SpreadsheetDocument.Area(DataTable.Count()+1, CurrentPredefinedDataNameColumn);
			If AreaKey1.Text = "" Or (AreaKey1.ContainsValue And AreaKey1.Value = "")Then
				AreaKey1.ContainsValue = True;
				AreaKey1.ValueType = New TypeDescription("String");
				AreaKey1.Value = NewPresentation;
			EndIf; 
		EndDo;
	Else
		FoundRows = DataTable.FindRows(New Structure(KeyAttributeName, CurrentPredefinedDataName));
		If FoundRows.Count() = 0 Then
			Return;
		EndIf;
		
		DataString1 = FoundRows[0];
		TSDataTable = DataString1[TabularSectionName];
		While TSDataTable.Count() < LineNumber+1 Do
			NewRow = TSDataTable.Add();
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure SpreadsheetDocumentDataChangesSynchronization(Result, Var_AttributeName, TabularSectionName, LineNumber)
	
	If IsBlankString(TabularSectionName) Then
		If (Var_AttributeName = KeyAttributeName) And (KeyAttributeName = DefaultKeyAttributeName()) Then
			FillWithGUID = False;
			ResultRow = String(Result);
			If (Not IsBlankString(ResultRow)) And (StrFind(PredefinedValuesNames, ResultRow + ",") = 0) Then
				// Predefined value doesn't exist.
				If Not StringFunctionsClientServer.IsUUID(ResultRow) Then
					FillWithGUID = True;
				EndIf;
			EndIf;
			
			If Not FillWithGUID Then
				// Look for duplicates.
				RowIndex = 0;
				For Each DataString1 In DataTable Do
					If (DataString1.PredefinedDataName = Result) And (RowIndex <> LineNumber) Then
						FillWithGUID = True;
						Break;
					EndIf;
					RowIndex = RowIndex + 1;
				EndDo;
			EndIf;
			
			If FillWithGUID Then
				Result = GetNewPredefinedDataNameByDefault();
				Area = SpreadsheetDocument.Area(LineNumber+2, CurrentPredefinedDataNameColumn);
				Area.ContainsValue = True;
				Area.ValueType = New TypeDescription("String");
				Area.Value = Result;
			EndIf;
		EndIf;
		DataString1 = DataTable[LineNumber];
		
	Else
		FoundRows = DataTable.FindRows(New Structure(KeyAttributeName, CurrentPredefinedDataName));
		If FoundRows.Count() = 0 Then
			Return;
		EndIf;
		
		DataString1 = FoundRows[0];
		TSDataTable = DataString1[TabularSectionName];
		DataString1 = TSDataTable[LineNumber];
	EndIf;
	
	DataString1[Var_AttributeName] = Result;
	
EndProcedure

&AtClient
Function GetNewPredefinedDataNameByDefault()
	
	Return String(New UUID);
	
EndFunction

&AtServer
Procedure SpreadsheetDocumentDeleteColumns(SpreadsheetDocumentName, ColumnsArray1)
	
	ColumnsTable1 = New ValueTable;
	ColumnsTable1.Columns.Add("ColumnNumber", New TypeDescription("Number"));
	For Each ColumnNumber In ColumnsArray1 Do
		NewRow = ColumnsTable1.Add();
		NewRow.ColumnNumber = ColumnNumber;
	EndDo;
	ColumnsTable1.Sort("ColumnNumber Desc");
	
	For Each ColumnRow In ColumnsTable1 Do
		If ColumnRow.ColumnNumber > 0 Then
			Area = ThisObject[SpreadsheetDocumentName].Area("C" + Format(ColumnRow.ColumnNumber, "NG="));
			ThisObject[SpreadsheetDocumentName].DeleteArea(Area,SpreadsheetDocumentShiftType.Horizontal);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SpreadsheetDocumentOnChangeValuesTyping(TabularSectionName)
	
	TypesDetailsString = New TypeDescription("String");
	TypesDetailsBoolean = New TypeDescription("Boolean");
	TypesDetailsDate = New TypeDescription("Date");
	TypesDetailsNumber = New TypeDescription("Number");
	
	StructureAttributeType = TypesDetailsString;
	
	For Each TableRow In AreaDataTable Do
		
		If Not TableRow.ShouldBeTypified Then
			Continue;
		EndIf;
		
		AttributeName = TableRow.AttributeName;
		AreaText = TrimAll(TableRow.Text);
		
		StructureAttribute = Undefined;
		If IsBlankString(TabularSectionName) And AttributeName = KeyAttributeName Then
			If StrFind(PredefinedValuesNames, AreaText + ",") = 0 Then
				If Not StringFunctionsClientServer.IsUUID(AreaText) Then
					AreaText = String(New UUID);
				EndIf;
			EndIf;
			
		ElsIf IsBlankString(TabularSectionName) And FullObjectStructure.Property(AttributeName, StructureAttribute) Then
			StructureAttributeType = StructureAttribute.ValueType;
		ElsIf Not IsBlankString(TabularSectionName) And FullObjectStructure.Property(TabularSectionName, StructureAttribute) Then
			
			TSStructureAttribute = Undefined;
			If StructureAttribute.Attributes.Property(AttributeName, TSStructureAttribute) Then
				StructureAttributeType = TSStructureAttribute.ValueType;
			EndIf;
			
		EndIf;
		
		If ContainsSimpleTypesOnly(StructureAttributeType) Then
			TableRow.BasicType = True;
			
			For Each Type In StructureAttributeType.Types() Do
				If TypesDetailsBoolean.ContainsType(Type) Then
					AttributeValue = Upper(AreaText);
					TableRow.AreaType = StructureAttributeType;
					TableRow.Result = AttributeValue = "YES" Or AttributeValue = "TRUE";
					
				ElsIf TypesDetailsNumber.ContainsType(Type) Then
					If IsBlankString(AreaText) Then
						TableRow.AreaType = StructureAttributeType;
						TableRow.Result = 0;
					Else
						AttributeValue = StrReplace(AreaText, " ", "");
						AttributeValue = StrReplace(AttributeValue, Chars.NBSp, "");
						AttributeValue = StrReplace(AttributeValue, Chars.Tab, "");
						AttributeValue = StrReplace(AttributeValue, ", ", ".");
						PointCount = StrLen(AttributeValue) - StrLen(StrReplace(AttributeValue, ".", ""));
						If StringFunctionsClientServer.OnlyNumbersInString(StrReplace(AttributeValue, ".", "")) And PointCount <= 1 Then
							TableRow.AreaType = StructureAttributeType;
							TableRow.Result = Number(AttributeValue);
						EndIf;
					EndIf;
					
				ElsIf TypesDetailsDate.ContainsType(Type) Then
					If IsBlankString(AreaText) Then
						TableRow.AreaType = StructureAttributeType;
						TableRow.Result = Date(1,1,1);
					Else
						AreaText = StrReplace(AttributeValue, " ", ", ");
						AttributeValue = StrReplace(Upper(AttributeValue), "T", ", ");
						AttributeValue = StrReplace(Upper(AttributeValue), ".", ", ");
						AttributeValue = StrReplace(Upper(AttributeValue), ":", ", ");
						
						Array = StrSplit(AttributeValue, ", ");
						
						If Array.Count() >= 3 Then
							
							If StrLen(Array[0]) > 2 Then
								AttributeValue = Array[0] + Array[1] + Array[2];
							Else
								AttributeValue = Array[2] + Array[1] + Array[0];
							EndIf;
							
							For IndexOf = 3 To Array.Count() - 1 Do
								AttributeValue = AttributeValue + Array[IndexOf];
							EndDo;
							
							TableRow.AreaType = StructureAttributeType;
							TableRow.Result = Date(AttributeValue);
							
						EndIf;
					EndIf;
					
				ElsIf TypesDetailsString.ContainsType(Type) Then
					TableRow.AreaType = StructureAttributeType;
					TableRow.Result = AreaText;
				EndIf;
			EndDo;
			
		ElsIf IsAccountKind(StructureAttributeType) Then
			TableRow.AreaType = StructureAttributeType;
			TableRow.Result = AreaText;
			
		ElsIf IsTypesDetails(StructureAttributeType) Then
			// The rest AreaType = Undefined. Don't typify the area.
			If IsBlankString(AreaText) Then
				TableRow.Result = "";
			EndIf;
			
			TypesArray = New Array;
			RowsArray = StrSplit(AreaText, ";", False);
			For Each TypeAsString In RowsArray Do
				TypeAsString = TrimAll(TypeAsString);
				MetadataByType = Common.MetadataObjectByFullName(TypeAsString);
				If MetadataByType = Undefined Then
					If StrFind(TypeAsString, ".") = 0 Then
						Try
							TypesArray.Add(Type(TypeAsString));
						Except
							Continue;
						EndTry;
					EndIf;
				Else
					TypesArray.Add(Type(StrReplace(TypeAsString, ".", "Ref.")));
				EndIf;
			EndDo;
			
			TableRow.Result = New TypeDescription(TypesArray);
			
		ElsIf IsEnum(StructureAttributeType) Then
			// The rest AreaType = Undefined. Don't typify the area.
			DefaultAttributeValue = StructureAttributeType.AdjustValue();
			If IsBlankString(AreaText) Then
				TableRow.Result = DefaultAttributeValue;
			EndIf;
			
			AttributeMetadata = DefaultAttributeValue.Metadata();
			For EnumIndex = 0 To Enums[AttributeMetadata.Name].Count() - 1 Do
				EnumByIndex = AttributeMetadata.EnumValues[EnumIndex];
				If EnumByIndex.Name = AreaText Or EnumByIndex.Synonym = AreaText Then
					TableRow.Result = PredefinedValue("Enum." + AttributeMetadata.Name + "." + EnumByIndex.Name);
					Break;
				Else
					TableRow.Result = DefaultAttributeValue;
				EndIf;
			EndDo;
			
		ElsIf IsReferenceType(StructureAttributeType) Then
			// The rest AreaType = Undefined. Don't typify the area.
			DefaultAttributeValue = StructureAttributeType.AdjustValue();
			TableRow.Result = DefaultAttributeValue;
			If IsBlankString(AreaText) Then
				Continue;
			EndIf;
			
			FilterText1 = "";
			MetadataObject = DefaultAttributeValue.Metadata(); // MetadataObjectCatalog, MetadataObjectDocument 
			For Each StandardAttribute In MetadataObject.StandardAttributes Do
				If StrFind("Code,Description", StandardAttribute.Name) > 0 Then
					FilterText1 = FilterText1 + " OR " + "SourceTable1." + StandardAttribute.Name + " = &AreaText";
					FilterText1 = FilterText1 + " OR " + "SourceTable1." + StandardAttribute.Name + " = &AreaTextWithoutSpaces";
				EndIf;
			EndDo;
			
			QueryText =
				"SELECT
				|	SourceTable1.Ref AS Ref
				|FROM
				|	&SourceTable1 AS SourceTable1
				|WHERE
				|	FALSE";
			QueryText = StrReplace(QueryText, "&SourceTable1", DefaultAttributeValue.Metadata().FullName());
			Query = New Query(QueryText + FilterText1);
			Query.SetParameter("AreaText", AreaText);
			Query.SetParameter("AreaTextWithoutSpaces", StrReplace(AreaText, " ", ""));
			
			//@skip-check query-in-loop - One-time calls during cell clean-up. Can be arbitrary for this data type.
			Selection = Query.Execute().Select();
			
			If Selection.Next() Then
				TableRow.Result = Selection.Ref;
			ElsIf TypeCanContainPredefinedValues(StructureAttributeType) Then
				
				QueryText =
				"SELECT
				|	SourceTable1.Ref AS Ref,
				|	SourceTable1.PredefinedDataName AS PredefinedDataName
				|FROM
				|	&SourceTable1 AS SourceTable1
				|WHERE
				|	SourceTable1.Predefined
				|	AND SourceTable1.PredefinedDataName IN (&AreaText, &AreaTextWithoutSpaces)";
				
				QueryText = StrReplace(QueryText, "SourceTable1.PredefinedDataName", "SourceTable1." + KeyAttributeName );
				QueryText = StrReplace(QueryText, "&SourceTable1", DefaultAttributeValue.Metadata().FullName());
				Query.Text = QueryText;
				//@skip-check query-in-loop - One-time calls during cell clean-up. Can be arbitrary for this data type.
				Try
					Selection = Query.Execute().Select();
					While Selection.Next() Do
						TableRow.Result = Selection.Ref;
					EndDo;
				Except
					// ACC:280
				EndTry;
				
			EndIf;
			
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function TableDataRead(PredefinedDataName, Var_AttributeName, TabularSectionName, LineNumber)
	
	If IsBlankString(TabularSectionName) Then
		If DataTable.Count()-1 < LineNumber Then
			Return Undefined;
		EndIf;
		DataString1 = DataTable[LineNumber];
		
	Else
		FoundRows = DataTable.FindRows(New Structure(KeyAttributeName, PredefinedDataName));
		If FoundRows.Count() = 0 Then
			Return Undefined;
		EndIf;
		
		DataString1 = FoundRows[0];
		TSDataTable = DataString1[TabularSectionName];
		If TSDataTable.Count()-1 < LineNumber Then
			Return Undefined;
		EndIf;
		DataString1 = TSDataTable[LineNumber];
		
	EndIf;
	
	Return DataString1[Var_AttributeName];
	
EndFunction

&AtServer
Procedure FillMetadataObjectsChoiceList()
	
	TypesArray = New Array;
	TypesArray.Add("Catalogs");
	TypesArray.Add("ChartsOfCharacteristicTypes");
	TypesArray.Add("ChartsOfAccounts");
	TypesArray.Add("ChartsOfCalculationTypes");
	
	For Each MetadataType In TypesArray Do
		For Each MetadataObject In Metadata[MetadataType] Do
			
			ConfigurationExtension = MetadataObject.ConfigurationExtension();
			If (ConfigurationExtension <> Undefined)
				And (Not ConfigurationExtension.UsedInDistributedInfoBase) Then
				
				Continue;
			EndIf;
			
			Items.MetadataObject.ChoiceList.Add(MetadataObject.FullName());
			
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Procedure MetadataObjectOnChangeAtServer()
	
	ObjectMetadata = Common.MetadataObjectByFullName(Object.MetadataObject);
	
	PredefinedNamesArray    = ObjectMetadata.GetPredefinedNames();
	PredefinedValuesNames = StrConcat(PredefinedNamesArray, ",") + ",";
	SetKeyAttributeName(ObjectMetadata);
	
	FillFullObjectStructure();
	
	FIllAttributeTree();
	
	FillDataTable();
	
	FillSpreadsheetDocuments();
	
EndProcedure

&AtServer
Procedure SetKeyAttributeName(ObjectMetadata)
	
	Try
		
		ObjectManager = Common.ObjectManagerByFullName(ObjectMetadata.FullName());
		
		CustomSettingsFillItems = CustomSettingsFillItems();
		ObjectManager.OnSetUpInitialItemsFilling(CustomSettingsFillItems);
		KeyAttributeName = CustomSettingsFillItems.KeyAttributeName;
		
		If IsBlankString(KeyAttributeName) Then
			KeyAttributeName = DefaultKeyAttributeName();
		EndIf;
		
	Except
		KeyAttributeName = DefaultKeyAttributeName();
	EndTry;
	
EndProcedure

// Item population overridable settings.
// 
// Returns:
//  Structure:
//    * OnInitialItemFilling - Boolean
//    * KeyAttributeName - String
//    * AdditionalParameters - Structure
//
&AtServer
Function CustomSettingsFillItems()
	
	ItemsFillingSettings = New Structure;
	ItemsFillingSettings.Insert("OnInitialItemFilling", False);
	ItemsFillingSettings.Insert("KeyAttributeName",          DefaultKeyAttributeName());
	ItemsFillingSettings.Insert("AdditionalParameters",        New Structure);
	
	Return ItemsFillingSettings;
	
EndFunction

&AtServer
Procedure FIllAttributeTree()
	
	HeaderAttributes = Attributes.GetItems();
	HeaderAttributes.Clear();
	
	PictureGeographicalDiagram = PictureLib.GeographicalSchema;
	PictureProps = PictureLib.Attribute;
	ImageCatalog = PictureLib.Catalog;
	
	For Each Attribute In FullObjectStructure Do
		
		If Attribute.Value.IsExcludable Then
			Continue;
		EndIf;
		
		NewRow = HeaderAttributes.Add();
		NewRow.IsExcludable       = Attribute.Value.IsExcludable;
		NewRow.Check           = Not NewRow.IsExcludable;
		NewRow.Name               = Attribute.Key;
		NewRow.ToLocalize      = Attribute.Value.ToLocalize;
		NewRow.ValueType       = Attribute.Value.ValueType;
		NewRow.AttributeString         = Attribute.Value.AttributeString;
		NewRow.UseNStr  = Attribute.Value.AttributeString;
		NewRow.TabularSectionName = "";
		NewRow.Picture          = ?(NewRow.ToLocalize, PictureGeographicalDiagram, PictureProps);
		
		If Not ValueIsFilled(Attribute.Value.Attributes) Then
			NewRow.IsTabularSection = False;
			Continue;
		EndIf;
		
		NewRow.IsTabularSection = True;
		TSAttributes = NewRow.GetItems();
		HasAttributesNotToExclude = False;
		
		For Each TSProps In Attribute.Value.Attributes Do
			If TSProps.Value.IsExcludable Then
				Continue;
			EndIf;
			
			NewLineTS = TSAttributes.Add();
			NewLineTS.IsExcludable       = TSProps.Value.IsExcludable;
			NewLineTS.Check           = Not NewLineTS.IsExcludable;
			NewLineTS.Name               = TSProps.Key;
			NewLineTS.ToLocalize      = TSProps.Value.ToLocalize;
			NewLineTS.ValueType       = TSProps.Value.ValueType;
			NewLineTS.AttributeString         = TSProps.Value.AttributeString;
			NewLineTS.UseNStr  = TSProps.Value.AttributeString;
			NewLineTS.Picture          = ?(NewLineTS.ToLocalize, PictureGeographicalDiagram, PictureProps);
			NewLineTS.IsTabularSection = False;
			NewLineTS.TabularSectionName = NewRow.Name;
			
			HasAttributesNotToExclude = (HasAttributesNotToExclude Or NewLineTS.Check);
		EndDo;
		
		NewRow.IsExcludable = Not HasAttributesNotToExclude;
		NewRow.Check     = Not NewRow.IsExcludable;
		NewRow.Picture    = ImageCatalog;
		
	EndDo;
	
EndProcedure

// Generates a structure of main language parameters and modifies the language table.
// The resulting table contains only present or selected languages.
//	Parameters:
//		LanguagesCodes 
//			- Array of languages from selected attributes.
//			- "Undefined" if the table is populated programmatically.
//	Returns: A parameter structure
//		MainLanguage - Main language code.
//		AdditionalLanguage1 - First additional language code.
//		AdditionalLanguage2 - Second additional language code.
//		MainLanguagePresentation - Code presentation in the format [(LanguageName)] to use in column presentations.
//
&AtServer
Function FillCommonLanguageParameters()
	
	If Metadata.Constants.Find("DefaultLanguage") = Undefined Then
		DefaultLanguage = Common.DefaultLanguageCode();
		AdditionalLanguage1 = DefaultLanguage;
		AdditionalLanguage2 = DefaultLanguage;
	Else
		DefaultLanguage = Constants.DefaultLanguage.Get();
		AdditionalLanguage1 = Constants.AdditionalLanguage1.Get();
		AdditionalLanguage2 = Constants.AdditionalLanguage2.Get();
	EndIf;
	
	CommonLanguageParameters = New Structure;
	
	Object.Languages.Clear();
	
	For Each Language In Metadata.Languages Do
		
		StringLanguage = Object.Languages.Add();
		StringLanguage.Name = Language.Name;
		StringLanguage.LanguageCode = Language.LanguageCode;
		StringLanguage.Presentation = " (" + ?(IsBlankString(Language.Synonym), StringLanguage.Name, Language.Synonym) + ")";
		
		If DefaultLanguage = StringLanguage.LanguageCode Then
			CommonLanguageParameters.Insert("DefaultLanguage", StringLanguage.LanguageCode);
			CommonLanguageParameters.Insert("DefaultLanguagePresentation", StringLanguage.Presentation);
			StringLanguage.DefaultLanguage = True;
		EndIf;
		
	EndDo;
	
	CommonLanguageParameters.Insert("AdditionalLanguage1", AdditionalLanguage1);
	CommonLanguageParameters.Insert("AdditionalLanguage2", AdditionalLanguage2);
	
	Return CommonLanguageParameters;
	
EndFunction

&AtServer
Function FillDataTable(ByCode = False)
	
	FillDataTableColumns();
	
	FillingResult = ExecutionResult();
	
	If ByCode Then
		FillingResult = FillDataTableByCode();
	Else
		FillDataTableOnRequest();
	EndIf;
	
	Return FillingResult;
	
EndFunction

&AtServer
Function FillDataTableByCode()
	
	PredefinedDataName = Undefined;
	
	FillingResult = GetFillingResultByCode();
	If Not FillingResult.Success Then
		Return FillingResult;
	EndIf;
	
	For Each DataElement In FillingResult.Data Do
		
		NewRow = DataTable.Add();
		
		HeaderAttributes = Attributes.GetItems();
		
		For Each Attribute In HeaderAttributes Do
			
			If Attribute.IsExcludable Then
				Continue;
			EndIf;
			
			If Attribute.IsTabularSection Then
				NewRow[Attribute.Name].Load(DataElement[Attribute.Name].Unload());
			Else
				AttributeValue = DataElement[Attribute.Name];
				
				If Attribute.Name = KeyAttributeName Then
					If FillingResult.NamesStructure.Property("Number" + DataTable.Count(), PredefinedDataName) Then
						If (KeyAttributeName = DefaultKeyAttributeName()) And IsBlankString(PredefinedDataName) Then
							AttributeValue = String(New UUID);
						Else
							AttributeValue = PredefinedDataName;
						EndIf;
					ElsIf KeyAttributeName = DefaultKeyAttributeName() Then
						AttributeValue = String(New UUID);
					EndIf;
				EndIf;
				
				NewRow[Attribute.Name] = AttributeValue;
				
				If Attribute.ToLocalize And DataElement.AdditionalProperties.Property("AttributesToLocalize") Then
					For Each LocalizationLanguage In Object.Languages Do
						LAttributeName1 = NameOfAttributeToLocalize(Attribute.Name, LocalizationLanguage.LanguageCode);
						LAttributeName2 = Attribute.Name + "_" + LocalizationLanguage.LanguageCode;
						If Not IsBlankString(LAttributeName1) Then
							NewRow[LAttributeName2] = DataElement[LAttributeName1];
						ElsIf DataElement.AdditionalProperties.AttributesToLocalize.Property(Attribute.Name) Then
							NewRow[LAttributeName2] = DataElement.AdditionalProperties.AttributesToLocalize[Attribute.Name][LAttributeName2];
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return FillingResult;
	
EndFunction

&AtServer
Procedure FillDataTableOnRequest()
	
	QueryText = GetDataSelectionQueryText();
	Query = New Query(QueryText);
	SourceTable1 = Query.Execute().Unload();
	
	If WithoutDeletedItems And SourceTable1.Columns.Find(KeyAttributeName) <> Undefined Then
		
		LinesToDelete = New Array;
		
		For Each TableRow In SourceTable1 Do
			
			If Not TableRow.Predefined Then
				If StrFind(TableRow.Ref.Metadata().InputByString, "Description") > 0
					And IsObsoleteItem(TableRow.Description) Then
					LinesToDelete.Add(TableRow);
				EndIf;
				If KeyAttributeName = DefaultKeyAttributeName() Then
					TableRow.PredefinedDataName = TableRow.Ref.UUID();
				EndIf;
			EndIf;
			
			If IsObsoleteItem(TableRow.PredefinedDataName) Then
				LinesToDelete.Add(TableRow);
			EndIf;
			
		EndDo;
		
		For Each TableRow In LinesToDelete Do
			SourceTable1.Delete(TableRow);
		EndDo;
	EndIf;
	
	DataTable.Load(SourceTable1);
	
	HeaderAttributes = Attributes.GetItems();
	For Each Attribute In HeaderAttributes Do
		
		If Attribute.IsExcludable Then
			Continue;
		EndIf;
		
		If Not Attribute.IsTabularSection Then
			Continue;
		EndIf;
		
		For IndexOf = 0 To SourceTable1.Count() - 1 Do
			DataTable[IndexOf][Attribute.Name].Load(SourceTable1[IndexOf][Attribute.Name]);
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Function IsObsoleteItem(TagName)
	
	Return StrStartsWith(Upper(TagName), "DELETE");
	
EndFunction

&AtServer
Procedure FillSpreadsheetDocuments(FromCode = False)
	
	FillDynamicFormItems();
	SpreadsheetDocumentsStructure = InitializeSpreadsheetDocuments();
	
	FillSpreadsheetDocument(SpreadsheetDocumentsStructure, DataTable);
	
	For Each String In SpreadsheetDocumentsStructure Do
		
		TabularSectionName = ?(String.Key = "Header", "", String.Key);
		
		ThisObject["SpreadsheetDocument" + TabularSectionName].Put(String.Value);
		Items["SpreadsheetDocument" + TabularSectionName].ShowGrid = True;
		Items["SpreadsheetDocument" + TabularSectionName].ShowHeaders = True;
		Items["SpreadsheetDocument" + TabularSectionName].Edit = True;
		
		ThisObject["SpreadsheetDocument" + TabularSectionName].FixedTop = 1;
	EndDo;
	
	SpreadsheetDocument.FixedLeft = 1;
	
	Items.SpreadsheetDocumentWithoutTS.ShowGrid = True;
	Items.SpreadsheetDocumentWithoutTS.ShowHeaders = True;
	Items.SpreadsheetDocumentWithoutTS.Edit = True;
	
EndProcedure

&AtServer
Function GetDataSelectionQueryText()
	
	QueryText = 
		"SELECT ALLOWED
		|	MDObjects.*
		|FROM
		|	&TableName AS MDObjects
		|WHERE
		|	TRUE";
	QueryText = StrReplace(QueryText, "&TableName", Object.MetadataObject);
	If HasGroups Then
		QueryText = QueryText + " AND NOT MDObjects.IsFolder";
	EndIf;
	
	If WithoutDeletedItems Then
		QueryText = QueryText + " AND NOT MDObjects.DeletionMark";
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtServer
Function InitializeSpreadsheetDocuments(InitializationData = Undefined)
	
	TitleFont = New Font(,, True); // ACC:1345
	
	DestinationSpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocuments = New Structure;
	SpreadsheetDocuments.Insert("Header", DestinationSpreadsheetDocument);
	
	If InitializationData = Undefined Then
		InitializationData = Attributes;
	EndIf;
	
	InitializationAttributes = InitializationData.GetItems();
	
	// Header.
	ColumnNum = 0;
	
	For Each Attribute In InitializationAttributes Do
		
		If Not Attribute.Check Then
			Continue;
		EndIf;
		
		If Attribute.IsTabularSection Then
			SpreadsheetDocumentTS = InitializeSpreadsheetDocuments(Attribute);
			SpreadsheetDocuments.Insert(Attribute.Name, SpreadsheetDocumentTS.Header);
			Continue;
		EndIf;
		
		ToLocalize = Attribute.ToLocalize;
		
		ColumnNum = ColumnNum + 1;
		Area = DestinationSpreadsheetDocument.Area(1, ColumnNum);
		Area.ContainsValue = False;
		If ToLocalize Then
			Area.BackColor = StyleColors.AddedAttributeBackground;
			Area.Text = Attribute.Name + CommonLanguageParameters.DefaultLanguagePresentation;
		ElsIf Attribute.Name = KeyAttributeName Then
			Area.Text = KeyAttributeName;
		Else
			Area.Text = Attribute.Name;
		EndIf;
		Area.Name = Attribute.Name;
		
		ValueType = Attribute.ValueType;
		Digits = 0;
		If ThisIsBoolean(ValueType) Then
			ColumnWidth = 7;
		ElsIf IsNumber(ValueType, Digits) Then
			ColumnWidth = Digits+2;
		ElsIf IsDate(ValueType, Digits) Then
			If Digits = DateFractions.DateTime Then
				ColumnWidth = 19;
			Else
				ColumnWidth = 10;
			EndIf;
		ElsIf Attribute.Name = KeyAttributeName Then
			ColumnWidth = 27;
		Else
			ColumnWidth = StrLen(Area.Text) + 2;
		EndIf;
		Area.ColumnWidth = ColumnWidth;
		
		If ToLocalize Then
			
			For Each LocalizationLanguage In Object.Languages Do
				
				If LocalizationLanguage.DefaultLanguage Then
					Continue;
				EndIf;
				
				ColumnNum = ColumnNum + 1;
				Area = DestinationSpreadsheetDocument.Area(1, ColumnNum);
				Area.ContainsValue = False;
				Area.BackColor = StyleColors.AddedAttributeBackground;
				Area.Text = Attribute.Name + LocalizationLanguage.Presentation;
				Area.Name = Attribute.Name + "_" + LocalizationLanguage.LanguageCode;
				Area.ColumnWidth = StrLen(Area.Text) + 2;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	If DestinationSpreadsheetDocument.TableHeight > 0 And  DestinationSpreadsheetDocument.TableWidth > 0 Then
		Area = DestinationSpreadsheetDocument.Area("R1");
		Area.Font = TitleFont;
		Area.HorizontalAlign = HorizontalAlign.Left;
		Area.TextPlacement = SpreadsheetDocumentTextPlacementType.Cut;
	EndIf;
	
	Return SpreadsheetDocuments;
	
EndFunction

&AtServer
Procedure FillSpreadsheetDocument(SpreadsheetDocuments, DataSource, InitializationData = Undefined, TabularSectionName = "", PredefinedDataName = "")
	
	If InitializationData = Undefined Then
		InitializationData = Attributes;
	EndIf;
	
	SolidLine = New Line(SpreadsheetDocumentCellLineType.Solid);
	
	If IsBlankString(TabularSectionName) Then
		DestinationSpreadsheetDocument = SpreadsheetDocuments.Header;
	Else
		DestinationSpreadsheetDocument = SpreadsheetDocuments[TabularSectionName];
	EndIf;
	LineNumber = DestinationSpreadsheetDocument.TableHeight;
	
	For Each DataString1 In DataSource Do
		
		LineNumber = LineNumber + 1;
		ColumnNumber = 0;
		
		InitializationAttributes = InitializationData.GetItems();
		
		For Each Attribute In InitializationAttributes Do
			
			If Not Attribute.Check Then
				Continue;
			EndIf;
			
			If Attribute.IsTabularSection Then
				Continue;
			EndIf;
			
			ToLocalize = Attribute.ToLocalize;
			
			ColumnNumber = ColumnNumber + 1;
			Area = DestinationSpreadsheetDocument.Area(LineNumber, ColumnNumber);
			
			If ToLocalize Then
				Area.BackColor = StyleColors.AddedAttributeBackground;
			EndIf;
			
			ValueType = Attribute.ValueType;
			
			If ContainsSimpleTypesOnly(ValueType) Then
				Area.ContainsValue = True;
				Area.ValueType = ValueType;
				Area.Value = ?(Attribute.Name = KeyAttributeName And Not IsBlankString(TabularSectionName), PredefinedDataName, DataString1[Attribute.Name]);
				If (Attribute.Name = KeyAttributeName) And (KeyAttributeName <> DefaultKeyAttributeName())
					 And IsBlankString(DataString1[KeyAttributeName]) And IsBlankString(DataString1[DefaultKeyAttributeName()]) Then
					Area.Note.Text = NStr("ru = 'Не заполнено значение ключевого реквизита.';
													|en = 'A key attribute is required.';");
					Area.BackColor = WebColors.Pink;
				EndIf;
			ElsIf IsAccountKind(ValueType) Then
				Area.Text = AccountKindPresentation(DataString1[Attribute.Name]);
				Area.Protection = True;
			ElsIf IsEnum(ValueType) Then
				Area.Text = String(DataString1[Attribute.Name]);
			ElsIf (IsReferenceType(ValueType) And ValueIsFilled(DataString1[Attribute.Name]))
				  Or Common.IsReference(TypeOf(DataString1[Attribute.Name])) Then
				Area.ContainsValue = False;
				Area.Text = String(DataString1[Attribute.Name]);
			ElsIf IsTypesDetails(ValueType) Then
				Area.ContainsValue = False;
				Area.Text = GetTypesDetailsPresentation(DataString1[Attribute.Name]);
			EndIf;
			
			Area.Protection = (Area.Protection Or (Attribute.Name = KeyAttributeName));
			
			If ToLocalize Then
				
				For Each LocalizationLanguage In Object.Languages Do
					
					If LocalizationLanguage.DefaultLanguage Then
						Continue;
					EndIf;
					
					ColumnNumber = ColumnNumber + 1;
					Area = DestinationSpreadsheetDocument.Area(LineNumber, ColumnNumber);
					Area.BackColor = StyleColors.AddedAttributeBackground;
					
					NameOfAttributeToLocalize = Attribute.Name + "_" + LocalizationLanguage.LanguageCode;
					
					Area.ContainsValue = True;
					Area.ValueType = New TypeDescription("String");
					Area.Value = DataString1[NameOfAttributeToLocalize];
					
				EndDo;
				
			EndIf;
			
		EndDo;
	EndDo;
	
	If DestinationSpreadsheetDocument.TableHeight > 0 And DestinationSpreadsheetDocument.TableWidth > 0 Then
		Area = DestinationSpreadsheetDocument.Area(1, 1, DestinationSpreadsheetDocument.TableHeight, DestinationSpreadsheetDocument.TableWidth);
		Area.TopBorder = SolidLine;
		Area.BottomBorder = SolidLine;
		Area.LeftBorder = SolidLine;
		Area.RightBorder = SolidLine;
	EndIf;
	
EndProcedure

&AtServer
Procedure OutputTabularSectionsOfCurrentItemAtServer(HeaderString, CurrentPredefinedDataName)
	
	If HeaderString > 1 And HeaderString <= DataTable.Count()+1 Then
		DataSource = DataTable[HeaderString - 2];
	Else
		DataSource = Undefined;
	EndIf;
	
	HeaderAttributes = Attributes.GetItems();
	
	For Each Attribute In HeaderAttributes Do
		
		If Not Attribute.Check Then
			Continue;
		EndIf;
		
		If Not Attribute.IsTabularSection Then
			Continue;
		EndIf;
		
		SpreadsheetDocumentTS = InitializeSpreadsheetDocuments(Attribute);
		SpreadsheetDocumentsStructure.Insert(Attribute.Name, SpreadsheetDocumentTS.Header);
		If DataSource <> Undefined Then
			FillSpreadsheetDocument(SpreadsheetDocumentsStructure, DataSource[Attribute.Name], Attribute, Attribute.Name, CurrentPredefinedDataName);
		EndIf;
		
	EndDo;
	
	For Each String In SpreadsheetDocumentsStructure Do
		
		If String.Key = "Header" Then
			Continue;
		EndIf;
		
		TabularSectionName = String.Key;
		
		If Items.Find("SpreadsheetDocument" + TabularSectionName) <> Undefined Then
			ThisObject["SpreadsheetDocument" + TabularSectionName].Clear();
			ThisObject["SpreadsheetDocument" + TabularSectionName].Put(String.Value);
			Items["SpreadsheetDocument" + TabularSectionName].ShowGrid = True;
			Items["SpreadsheetDocument" + TabularSectionName].ShowHeaders = True;
			Items["SpreadsheetDocument" + TabularSectionName].Edit = True;
			ThisObject["SpreadsheetDocument" + TabularSectionName].FixedTop = 1;
		EndIf;
		
	EndDo;
	
	SpreadsheetDocument.FixedLeft = 1;
	
EndProcedure

&AtServer
Procedure FillDynamicFormItems()
	
	ClearDynamicallyCreatedFormItems();
	
	For Each Attribute In FullObjectStructure Do
		
		If Attribute.Value.IsExcludable Then
			Continue;
		EndIf;
		
		If Not ValueIsFilled(Attribute.Value.Attributes) Then
			Continue;
		EndIf;
		
		TabularSectionName = Attribute.Key;
		
		AttributesToBeAdded = New Array;
		FormAttribute = New FormAttribute("SpreadsheetDocument" + TabularSectionName, New TypeDescription("SpreadsheetDocument"));
		AttributesToBeAdded.Add(FormAttribute);
		
		ChangeAttributes(AttributesToBeAdded);
		
		Page = Items.Add("Page" + TabularSectionName, Type("FormGroup"), Items.TabularSectionsGroup);
		Page.Title = TabularSectionName;
		Item = Items.Add("SpreadsheetDocument" + TabularSectionName, Type("FormField"), Page);
		Item.DataPath = "SpreadsheetDocument" + TabularSectionName;
		Item.TitleLocation = FormItemTitleLocation.None;
		Item.SetAction("OnChange", "Attachable_SpreadsheetDocumentOnChange");
		Item.SetAction("Selection", "Attachable_SpreadsheetDocumentValueInputStart");
		Item.SetAction("OnActivate", "Attachable_SpreadsheetDocumentOnActivateArea");
		
		If (StrCompare(TabularSectionName, "Presentations") = 0)
			Or (StrCompare(TabularSectionName, "ContactInformation") = 0)
			Or (StrCompare(TabularSectionName, "AdditionalAttributes") = 0) Then
			
			Page.Visible = False;
		EndIf;
		
	EndDo
	
EndProcedure

&AtServer
Procedure FillDataTableColumns()
	
	TypesDetailsTable = New TypeDescription("ValueTable");
	TypesDetailsString  = New TypeDescription("String");
	
	DataTable.Clear();
	ClearDataTableColumns();
	
	AttributesToBeAdded = New Array;
	For Each Attribute In FullObjectStructure Do
		
		If Attribute.Value.IsExcludable Then
			Continue;
		EndIf;
		
		If ValueIsFilled(Attribute.Value.Attributes) Then
			AttributesToBeAdded.Add(New FormAttribute(Attribute.Key, TypesDetailsTable, "DataTable", Attribute.Key));
		Else
			AttributesToBeAdded.Add(New FormAttribute(Attribute.Key, Attribute.Value.ValueType, "DataTable", Attribute.Key));
			
			If Attribute.Value.ToLocalize Then
				For Each LocalizationLanguage In Object.Languages Do
					LAttributeName = Attribute.Key + "_" + LocalizationLanguage.LanguageCode;
					AttributesToBeAdded.Add(New FormAttribute(LAttributeName, TypesDetailsString, "DataTable", LAttributeName));
				EndDo;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ChangeAttributes(AttributesToBeAdded);
	
	AttributesToBeAdded = New Array;
	For Each Attribute In FullObjectStructure Do
		
		If Attribute.Value.IsExcludable Then
			Continue;
		EndIf;
		
		If Not ValueIsFilled(Attribute.Value.Attributes) Then
			Continue;
		EndIf;
		
		Path = "DataTable." + Attribute.Key;
		For Each TSProps In Attribute.Value.Attributes Do
			
			If TSProps.Value.IsExcludable Then
				Continue;
			EndIf;
			
			AttributesToBeAdded.Add(New FormAttribute(TSProps.Key, TSProps.Value.ValueType, Path, TSProps.Key));
			
			If TSProps.Value.ToLocalize Then
				For Each LocalizationLanguage In Object.Languages Do
					LAttributeName = TSProps.Key + "_" + LocalizationLanguage.LanguageCode;
					AttributesToBeAdded.Add(New FormAttribute(LAttributeName, TypesDetailsString, "DataTable", LAttributeName));
				EndDo;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	ChangeAttributes(AttributesToBeAdded);
	
EndProcedure

&AtServer
Procedure ClearDataTableColumns()
	
	AttributesToBeDeleted = New Array;
	
	ArrayOfCurrentResultingTableColumns = GetAttributes("DataTable");
	For Each ArrayElement In ArrayOfCurrentResultingTableColumns Do
		AttributesToBeDeleted.Add(ArrayElement.Path + "." + ArrayElement.Name);
	EndDo;

	For Each ArrayElement In AttributesToBeDeleted Do
		FoundFormItem = Items.Find(ArrayElement);
		If FoundFormItem <> Undefined  Then
			Items.Delete(FoundFormItem);
		EndIf;
	EndDo;
	
	ChangeAttributes(, AttributesToBeDeleted);
	
EndProcedure

&AtServer
Procedure ClearDynamicallyCreatedFormItems()
	
	PagesToDelete = New Array;
	AttributesToBeDeleted = New Array;
	
	For Each Page In Items.TabularSectionsGroup.ChildItems Do
		For Each PageElement In Page.ChildItems Do
			DataPath = PageElement.DataPath;
			If DataPath <> "" Then
				AttributesToBeDeleted.Add(DataPath);
			EndIf;
		EndDo;
		PagesToDelete.Add(Page);
	EndDo;
	
	For Each Page In PagesToDelete Do
		Items.Delete(Page);
	EndDo;
	
	ChangeAttributes(, AttributesToBeDeleted);
	SpreadsheetDocument.Clear();
	
EndProcedure

&AtServer
Procedure FillFullObjectStructure()
	
	ObjectMetadata = Common.MetadataObjectByFullName(Object.MetadataObject);
	DataProcessorObject = FormAttributeToValue("Object");
	
	FullObjectStructure = DataProcessorObject.GetMetadataObjectAttributes(ObjectMetadata, KeyAttributeName, , HasGroups);
	
EndProcedure

&AtClient
Procedure UpdateTableAndCode()
	
	CurrentPage = Items.SectionsGroup.CurrentPage;
	If CurrentPage = Items.CodePage Then
		
		ConvertToTableAtServer(False);
		ConvertToCodeAtServer();
		CurrentPredefinedDataName = "";
		HeaderAreaName = "";
		
	Else
		
		ConvertToCodeAtServer();
		
		ConvertToTableAtServer(False);
		CurrentItem = Items.SpreadsheetDocument;
		Area = SpreadsheetDocument.Area(1,1,1,1);
		Items.SpreadsheetDocument.SetSelectedAreas(Area);
		SpreadsheetDocument.CurrentArea = Items.SpreadsheetDocument.CurrentArea;
		
		CurrentPredefinedDataName = "";
		HeaderAreaName = "";
		
		CheckTabularSectionsDisplay();
		OutputCurrentItemTabularSections();
		
		FormMode = "TablePage";
		CurrentPredefinedDataName = "";
		HeaderAreaName = "";
		
	EndIf;
	
	Items.AttributesReread.Enabled = False;
	
EndProcedure

&AtClient
Function CheckTabularSectionsDisplay()
	
	DisplayTabularSections = False;
	
	HeaderAttributes = Attributes.GetItems();
	For Each Attribute In HeaderAttributes Do
		If Attribute.IsTabularSection And Attribute.Check Then
			DisplayTabularSections = True;
			Return Attribute.Name;
		EndIf;
	EndDo;
	
	Return "";
	
EndFunction

&AtServer
Procedure ConvertToCodeAtServer()
	
	OneCCode.Clear();
	
	If SpreadsheetDocument.TableHeight < 2 Then
		Return;
	EndIf;
	
	OneCCode.AddLine("Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export");
	OneCCode.AddLine("");
	
	ConvertTableDataToCode(DataTable);
	
	OneCCode.AddLine("EndProcedure");
	
EndProcedure

&AtServer
Procedure ConvertTableDataToCode(DataSource, InitializationData = Undefined, TabularSectionName = "")
	
	If DataSource.Count() = 0 Then
		Return;
	EndIf;
	
	If InitializationData = Undefined Then
		InitializationData = Attributes;
	EndIf;
	
	RefsManagers = New Structure;
	RefsManagers.Insert("Catalog", "Catalogs.");
	RefsManagers.Insert("ChartOfCharacteristicTypes", "ChartsOfCharacteristicTypes.");
	RefsManagers.Insert("ChartOfAccounts", "ChartsOfAccounts.");
	RefsManagers.Insert("ChartOfCalculationTypes", "ChartsOfCalculationTypes.");
	RefsManagers.Insert("ExchangePlan", "ExchangePlans.");
	
	TypesDetailsString = New TypeDescription("String");
	TypesDetailsBoolean = New TypeDescription("Boolean");
	TypesDetailsDate   = New TypeDescription("Date");
	TypesDetailsNumber  = New TypeDescription("Number");
	
	If IsBlankString(TabularSectionName) Then
		Item = "Item";
		AddItemText = Chars.Tab + "Item = Items.Add();";
	Else
		Item = "TSItem";
		AddItemText = Chars.Tab + "TSItem = Item." + TabularSectionName + "." + "Add();";
		
		TSInitialization = StringFunctionsClientServer.SubstituteParametersToString("Item.%1 = TabularSections.%1.Copy();", TabularSectionName);
		OneCCode.AddLine(Chars.LF + Chars.Tab + TSInitialization);
	EndIf;
	
	UniqueRowsNames = New Map;
	StructureAttribute    = Undefined;
	OutputPredefinedDataNames = FullObjectStructure.Property(KeyAttributeName, StructureAttribute);
	
	InitializationAttributes = InitializationData.GetItems();
	
	For Each DataString1 In DataSource Do
		
		IsKeyColumn = DataString1.Property(KeyAttributeName);
		
		IsKeyAttributeValueFilled = True;
		
		If IsKeyColumn And IsBlankString(TabularSectionName) And OutputPredefinedDataNames Then
			ValueOfKeyProps = DataString1[KeyAttributeName];
			PredefinedDataNameValue = DataString1.PredefinedDataName;
			
			If IsBlankString(ValueOfKeyProps) And IsBlankString(PredefinedDataNameValue) Then
				IsKeyAttributeValueFilled = False;
			EndIf;
			
			If IsBlankString(ValueOfKeyProps) Then
				ValueOfKeyProps = PredefinedDataNameValue;
			EndIf;
			
			If IsKeyAttributeValueFilled And (Not ValueIsFilled(ValueOfKeyProps))
				Or (UniqueRowsNames.Get(ValueOfKeyProps) = True) Then
				// A row with the same PredefinedDataName value has already been found.
				Continue;
			EndIf;
			UniqueRowsNames.Insert(ValueOfKeyProps, True);
			
		EndIf;
		
		OneCCode.AddLine(AddItemText);
		
		For Each Attribute In InitializationAttributes Do
			
			If Not Attribute.Check Then
				Continue;
			EndIf;
			
			AttributeName = Attribute.Name;
			AttributeValue = DataString1[AttributeName];
			
			If Attribute.IsTabularSection Then
				ConvertTableDataToCode(AttributeValue, Attribute, AttributeName);
				Continue;
			EndIf;
			
			StructureAttributeType = Attribute.ValueType;
			ToLocalize          = Attribute.ToLocalize;
			UseNStr      = Attribute.UseNStr;
			AttributeType          = TypeOf(AttributeValue);
			
			IsSimpleType = ContainsSimpleTypesOnly(StructureAttributeType);
			IsAccountKind   = IsAccountKind(AttributeType);
			
			If AttributeValue = Undefined Or AttributeType = Undefined Then
				Continue;
				
			ElsIf IsTypesDetails(AttributeType) Then
				
				OneCCode.AddLine(Chars.Tab + "TypesArray = New Array;");
				
				For Each Type In AttributeValue.Types() Do
					MetadataObjectByType = Metadata.FindByType(Type);
					If MetadataObjectByType <> Undefined Then
						Type_Text = """" + StrReplace(MetadataObjectByType.FullName(), ".", "Ref.") + """";
					EndIf;
					OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("TypesArray.Add(Type(%1));", Type_Text));
				EndDo;
				
				OneCCode.AddLine(Chars.Tab + "TypeDetails = New TypeDescription(TypesArray);");
				OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("%1.%2 = TypeDetails;", Item, AttributeName));
				
			ElsIf IsSimpleType And TypesDetailsString.ContainsType(AttributeType) And (Not ToLocalize) Then
				
				If Not ValueIsFilled(AttributeValue) And IsKeyAttributeValueFilled Then
					Continue;
				EndIf;
				
				If AttributeName <> KeyAttributeName Then
					AttributeValueString = StringAttributeValueForCode(AttributeValue, True);
					If UseNStr Then
						AttributeValueString = StringFunctionsClientServer.SubstituteParametersToString("NStr(""%1 = '%2'"", Common.DefaultLanguageCode())", "ru", AttributeValueString);
					Else
						AttributeValueString = StringFunctionsClientServer.SubstituteParametersToString("""%1""", AttributeValueString);
					EndIf;
				ElsIf (StrFind(PredefinedValuesNames, AttributeValue + ",") > 0)
					 Or (KeyAttributeName <> DefaultKeyAttributeName()) Then
					AttributeValueString = StringAttributeValueForCode(AttributeValue, False, True);
				Else // UUID.
					Continue;
				EndIf;
				
				CodeComment = "";
				If (AttributeName = KeyAttributeName) And IsBlankString(AttributeValue) Then
					// Exclude from checking for invalid comments. 
					CodeComment = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '// %1 Заполнить уникальным значением';
																										|en = '// %1 Replace with a unique value';"), "TO" + "DO");
				EndIf;
				
				OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("%1.%2 = %3;%4",
					Item, AttributeName, AttributeValueString, CodeComment));
				
			ElsIf IsSimpleType And TypesDetailsString.ContainsType(AttributeType) Then
				
				TextNStr = "";
				Separator = "";
				LineBreak = Chars.LF + Chars.Tab + Chars.Tab;
				If ValueIsFilled(AttributeValue) Then
					AttributeValueString = StringAttributeValueForCode(AttributeValue, True);
					TextNStr = StringFunctionsClientServer.SubstituteParametersToString(LineBreak + "|%1 = '%2'", CommonLanguageParameters.DefaultLanguage, AttributeValueString);
					Separator = ";";
				EndIf;
				
				For Each LocalizationLanguage In Object.Languages Do
					
					If LocalizationLanguage.DefaultLanguage Then
						Continue;
					EndIf;
					
					LAttributeValue = DataString1[AttributeName + "_" + LocalizationLanguage.LanguageCode];
					AttributeValueString = StringAttributeValueForCode(LAttributeValue, True);
					
					If ValueIsFilled(LAttributeValue) Then
						TextNStr = TextNStr + StringFunctionsClientServer.SubstituteParametersToString("%1" + LineBreak + "|%2 = '%3'", Separator, LocalizationLanguage.LanguageCode, AttributeValueString);
						Separator = ";";
					EndIf;
					
				EndDo;
				
				If ValueIsFilled(TextNStr) Then
					TextNStr = StringFunctionsClientServer.SubstituteParametersToString("""%1""", TextNStr);
				Else
					TextNStr = """""";
				EndIf;
				
				OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("NationalLanguageSupportServer.FillMultilanguageAttribute(Item, ""%1"", %2, LanguagesCodes); // @ NStr", AttributeName, TextNStr));
				
			ElsIf IsSimpleType And TypesDetailsBoolean.ContainsType(AttributeType) Then
				OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("%1.%2 = %3;", Item, AttributeName, ?(AttributeValue, "True", "False")));
			ElsIf IsSimpleType And TypesDetailsDate.ContainsType(AttributeType) And ValueIsFilled(AttributeValue) Then
				OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("%1.%2 = %3;", Item, AttributeName, "Date(""" + Format(AttributeValue, "DF=yyyyMMddHHmmss") + """)"));
			ElsIf IsSimpleType And TypesDetailsNumber.ContainsType(AttributeType) Then
				OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("%1.%2 = %3;", Item, AttributeName, Format(AttributeValue, "NDS=.; NZ=0; NG=")));
			ElsIf IsSimpleType And BusinessProcesses.RoutePointsAllRefsType().ContainsType(AttributeType) Then
				AttributeValueString = StringAttributeValueForCode(AttributeValue, False);
				OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("%1.%2 = %3; // Presentation references BusinessProcessRoutePoint", Item, AttributeName, AttributeValueString));
			ElsIf IsAccountKind Then
				AccountKindName = AccountKindNameByValue(AttributeValue);
				OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("%1.%2 = %3;", Item, AttributeName, "AccountType." + AccountKindName));
			Else // If IsRefAttribute then...
				
				If Not ValueIsFilled(AttributeValue) Then
					Continue;
				EndIf;
				
				AttributeMetadata = AttributeValue.Metadata();
				
				If Metadata.ExchangePlans.Find(AttributeMetadata.Name) <> Undefined Then
					InputByStringOptions = InputByStringOptionsForType(StructureAttributeType);
					CodeType = "";
					If InputByStringOptions.Property("Code", CodeType) Then
						SearchText = "FindByCode(" + ?(CodeType = "String", StringAttributeValueForCode(AttributeValue.Code, False, True), AttributeValue.Code) + ")";
					ElsIf InputByStringOptions.Property("Description", CodeType) Then
						SearchText = "FindByDescription(" +  StringAttributeValueForCode(AttributeValue.Description, False, True) + ")";
					Else
						Continue;
					EndIf;
					OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("%1.%2 = ExchangePlans[""%3""].%4;", Item, AttributeName, AttributeMetadata.Name, SearchText));
					
				ElsIf Common.IsEnum(AttributeMetadata) And Not IsBlankString(AttributeValue) Then
					EnumIndex = Enums[AttributeMetadata.Name].IndexOf(AttributeValue);
					EnumValueDetails = AttributeMetadata.EnumValues[EnumIndex]; // MetadataObjectEnumValue
					EnumerationName = EnumValueDetails.Name; 
					AttributeValueString = "Enums." + AttributeMetadata.Name + "." + EnumerationName;
					OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("%1.%2 = %3;", Item, AttributeName, AttributeValueString));
				ElsIf Common.IsEnum(AttributeMetadata) And IsBlankString(AttributeValue) Then
					Continue;
					
				ElsIf Metadata.Catalogs.Find(AttributeMetadata.Name) <> Undefined
					Or Metadata.ChartsOfCharacteristicTypes.Find(AttributeMetadata.Name) <> Undefined
					Or Metadata.ChartsOfAccounts.Find(AttributeMetadata.Name) <> Undefined
					Or Metadata.ChartsOfCalculationTypes.Find(AttributeMetadata.Name) <> Undefined Then
					
					FullNameAttributeMetadata = AttributeMetadata.FullName();
					InputByStringOptions = InputByStringOptionsForType(StructureAttributeType);
					
					CodeType = "";
					
					Predefined = (StrCompare(KeyAttributeName, DefaultKeyAttributeName()) = 0 And AttributeValue.Predefined)
						Or (IsKeyColumn And ValueIsFilled(DataString1[KeyAttributeName]));
					
					If Predefined And ValueIsFilled(AttributeValue.PredefinedDataName) Then
						ObjectManager = "";
						Var_Key = StrReplace(FullNameAttributeMetadata, "." + AttributeMetadata.Name, "");
						If RefsManagers.Property(Var_Key, ObjectManager) Then
							AttributeValueString = StrReplace(FullNameAttributeMetadata, Var_Key + ".", ObjectManager) + "." + AttributeValue.PredefinedDataName;
							OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("%1.%2 = %3;", Item, AttributeName, AttributeValueString));
						EndIf;
							
					ElsIf InputByStringOptions.Property("Code", CodeType) Then
						ObjectManager = "";
						If RefsManagers.Property(StrReplace(FullNameAttributeMetadata, "." + AttributeMetadata.Name, ""), ObjectManager) Then
							CodeValue = ?(CodeType = "String", StringAttributeValueForCode(AttributeValue.Code, False, True), Format(AttributeValue.Code, "NFD=0; NG="));
							OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("FoundRef = %1.FindByCode(%2);", (ObjectManager + AttributeMetadata.Name), CodeValue));
							OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("%1.%2 = %3;", Item, AttributeName, "FoundRef"));
						EndIf;
						
					ElsIf InputByStringOptions.Property("Description") Then
						ObjectManager = "";
						If RefsManagers.Property(StrReplace(FullNameAttributeMetadata, "." + AttributeMetadata.Name, ""), ObjectManager) Then
							AttributeValueString = StringAttributeValueForCode(AttributeValue.Description, False, True);
							OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("FoundRef = %1.FindByDescription(%2);", (ObjectManager + AttributeMetadata.Name), AttributeValueString));
							OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("%1.%2 = %3;", Item, AttributeName, "FoundRef"));
						EndIf;
						
					Else// Search by attribute.
						AttributeValueString = StringAttributeValueForCode(AttributeValue, False);
						OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("%1.%2 = %3; // Presentation %4", Item, AttributeName, AttributeValueString, FullNameAttributeMetadata));
						
					EndIf;
					
				Else
					AttributeValueString = StringAttributeValueForCode(AttributeValue, False);
					OneCCode.AddLine(Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString("%1.%2 = %3; // Presentation references", Item, AttributeName, AttributeValueString));
					
				EndIf;
				
			EndIf;
		EndDo;
		
		If IsBlankString(TabularSectionName) Then
			OneCCode.AddLine("");
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function StringAttributeValueForCode(InitialString, FormatWithLocalization = True, AsOneString = False)
	
	If Not AsOneString Then
		StringForCode = "";
		Separator = "";
		For IndexOf = 1 To StrLineCount(InitialString) Do
			CurrentRow = StrGetLine(InitialString, IndexOf);
			CurrentRow = StrReplace(CurrentRow,"""", """""");
			
			If StrLen(CurrentRow) > 120 Then
				SubstringsArray = StrSplit(CurrentRow, " ", True);
				
				LongSeparator = "";
				CurrentRow = "";
				CurrentRowPart = "";
				For Index1 = 0 To SubstringsArray.Count()-1 Do
					CurrentRowPart = CurrentRowPart + " " + SubstringsArray[Index1];
					If StrLen(CurrentRowPart) > 120 And (SubstringsArray.Count() -1 - Index1) > 1 Then
						// More than one word is left. Wrap the line.
						CurrentRow = CurrentRow + LongSeparator + CurrentRowPart;
						CurrentRowPart = "";
						LongSeparator = """" + Chars.LF + Chars.Tab + Chars.Tab + Chars.Tab + "+ """;
					EndIf;
				EndDo;
				
				CurrentRow = CurrentRow + LongSeparator + CurrentRowPart;
			EndIf;
			
			StringForCode = StringForCode + Separator + CurrentRow;
			Separator = Chars.LF + Chars.Tab + Chars.Tab + "|";
		EndDo
	Else
		StringForCode = InitialString;
		StringForCode = StrReplace(StringForCode,"""", """""");
		StringForCode = StrReplace(StringForCode, Chars.LF, """" + Chars.LF + """");
	EndIf;
	
	If FormatWithLocalization Then
		Return StringForCode;
	Else
		Return """" + StringForCode + """";
	EndIf;

EndFunction

&AtServer
Function ConvertToTableAtServer(ByCode = True)
	
	ConversionResult = ExecutionResult();
	
	FillingResult = FillDataTable(ByCode);
	If Not FillingResult.Success Then
		FillPropertyValues(ConversionResult, FillingResult);
		Return ConversionResult;
	EndIf;
	
	FillSpreadsheetDocuments(ByCode);
	
	Return ConversionResult;
	
EndFunction

&AtServer
Function GetFillingResultByCode()
	
	FillingResult = CodeExecutionResultWithData();
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ObjectsArray", New Array);
	ExecutionParameters.Insert("NamesStructure", New Structure);
	ExecutionParameters.Insert("LanguagesCodes",    Object.Languages.Unload(, "LanguageCode").UnloadColumn("LanguageCode"));
	
	CommonLanguageParameters = FillCommonLanguageParameters();
	
	If StrStartsWith(Object.MetadataObject, "Catalog") Then
		ManagerToInsert = StrReplace(Object.MetadataObject, "Catalog", "Catalogs")+ ".CreateElement()";
	ElsIf StrStartsWith(Object.MetadataObject, "ChartOfCharacteristicTypes") Then
		ManagerToInsert = StrReplace(Object.MetadataObject, "ChartOfCharacteristicTypes", "ChartsOfCharacteristicTypes")+ ".CreateElement()";
	ElsIf StrStartsWith(Object.MetadataObject, "ChartOfAccounts") Then
		ManagerToInsert = StrReplace(Object.MetadataObject, "ChartOfAccounts", "ChartsOfAccounts") + ".CreateAccount()";
	ElsIf StrStartsWith(Object.MetadataObject, "ChartOfCalculationTypes") Then
		ManagerToInsert = StrReplace(Object.MetadataObject, "ChartOfCalculationTypes", "ChartsOfCalculationTypes") + ".CreateCalculationType()";
	EndIf;

	ReplacementText_2 = "Parameters.NamesStructure.Insert(""Number"" + Parameters.ObjectsArray.Count(), """"); Parameters.NamesStructure[""Number"" + Parameters.ObjectsArray.Count()] = ";

	OneCCodeText = CodeToExecute();

	OneCCodeText = StrReplace(OneCCodeText, "Items.Add();", ManagerToInsert + "; Parameters.ObjectsArray.Add(Item);");
	OneCCodeText = StrReplace(OneCCodeText, StringFunctionsClientServer.SubstituteParametersToString("Item.%1 = ", KeyAttributeName) , ReplacementText_2);
	OneCCodeText = StrReplace(OneCCodeText, "NationalLanguageSupportServer.FillMultilanguageAttribute", "Attachable_FillMultilanguageAttribute");
	OneCCodeText = StrReplace(OneCCodeText, "LanguagesCodes", "Parameters.LanguagesCodes");
	
	For Each Attribute In FullObjectStructure Do
		If Attribute.Value.ValueType = Undefined Then
			TSInitialization = StringFunctionsClientServer.SubstituteParametersToString("Item.%1 = TabularSections.%1.Copy();", Attribute.Key);
			OneCCodeText = StrReplace(OneCCodeText, TSInitialization, "//" + TSInitialization);
		EndIf;
	EndDo;
	
	Try
		If ThisIsMultilingualConfiguration() Then
			// Intended for "Attachable_FillMultilanguageAttribute".
			ExecuteInSafeMode(OneCCodeText, ExecutionParameters);
		Else
			Common.ExecuteInSafeMode(OneCCodeText, ExecutionParameters);
		EndIf;
	Except
		
		ErrorInfo = ErrorInfo();
		Cause = ?(TypeOf(ErrorInfo.Cause) = Type("ErrorInfo"), ErrorInfo.Cause, ErrorInfo);
		ErrorDescriptionString = ErrorProcessing.DetailErrorDescription(Cause);
		
		FillingResult.ErrorText = ErrorDescriptionString;
		FillingResult.Success     = False;
		
		SearchRow = "{(";
		ErrorLinePosition = StrFind(ErrorDescriptionString, SearchRow);
		
		If ErrorLinePosition = 0 Then
			Return FillingResult;
		EndIf;
		
		OpeningBracketPosition = ErrorLinePosition + StrLen(SearchRow);
		PositionOfClosingBracket = StrFind(ErrorDescriptionString, ")",, ErrorLinePosition);
		StringNumberCharCount = PositionOfClosingBracket - OpeningBracketPosition;
		
		FragmentWithErrorLineNumber = Mid(ErrorDescriptionString, OpeningBracketPosition, StringNumberCharCount);
		FragmentWithErrorLineNumber = StrReplace(FragmentWithErrorLineNumber, " ", "");
		
		Try
			ErrorStringNumber = Number(FragmentWithErrorLineNumber);
		Except
			Return FillingResult;
		EndTry;
		
		OneCCodeText = OneCCode.GetText();
		
		RowWithError = StrGetLine(OneCCodeText, ErrorStringNumber);
		StartPosition = StrFind(OneCCodeText, RowWithError);
		If StartPosition = 0 Then
			Return FillingResult;
		EndIf;
		
		EndPosition = StartPosition + StrLen(RowWithError);
		Items.OneCCode.SetTextSelectionBounds(StartPosition, EndPosition);
		
		CurrentItem = Items.OneCCode;
		FormMode = "CodePage";
		
		Return FillingResult;
		
	EndTry;
	
	FillingResult.Data        = ExecutionParameters.ObjectsArray;
	FillingResult.NamesStructure = ExecutionParameters.NamesStructure;
	
	Return FillingResult;
	
EndFunction

&AtServer
Procedure ExecuteInSafeMode(Val Algorithm, Val Var_Parameters = Undefined)
	
	SetSafeMode(True);
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		SeparatorArray = ModuleSaaSOperations.ConfigurationSeparators();
	Else
		SeparatorArray = New Array;
	EndIf;
	
	For Each SeparatorName In SeparatorArray Do
		
		SetDataSeparationSafeMode(SeparatorName, True);
		
	EndDo;
	
	// ACC:478-off - Required for proper functioning in multi-language configurations. The executable code is safe.
	Execute Algorithm;
	// ACC:487-on
	
EndProcedure

&AtServer
Function CodeToExecute()
	
	ProcedureKeyword      = "Procedure";
	EndProcedureKeyword = "EndProcedure";
	
	OneCCodeText = TrimAll(OneCCode.GetText());
	OneCCodeText = StrReplace(OneCCodeText,  ProcedureKeyword, "//" + ProcedureKeyword);
	OneCCodeText = StrReplace(OneCCodeText, EndProcedureKeyword, "//" + EndProcedureKeyword);
	
	Return OneCCodeText;
	
EndFunction

&AtServer
Procedure Attachable_FillMultilanguageAttribute(Item, Var_AttributeName, StringToLocalize, LanguagesCodes)
	
	AttributesToLocalizeStructure = New Structure;
	AttributesToLocalize = Undefined;
	If Not Item.AdditionalProperties.Property("AttributesToLocalize", AttributesToLocalize) Then
		AttributesToLocalize = New Structure;
		Item.AdditionalProperties.Insert("AttributesToLocalize", AttributesToLocalize);
	EndIf;
	AttributesToLocalize.Insert(Var_AttributeName, AttributesToLocalizeStructure);
	
	For Each LanguageCode In LanguagesCodes Do
		
		NameOfAttributeToLocalize = NameOfAttributeToLocalize(Var_AttributeName, LanguageCode);
		LanguageStringToLocalize   = NStr(StringToLocalize, LanguageCode);
		If Not IsBlankString(NameOfAttributeToLocalize) Then
			Item[NameOfAttributeToLocalize] = LanguageStringToLocalize;
		Else
			NameOfAttributeToLocalize = Var_AttributeName + "_" + LanguageCode;
			AttributesToLocalizeStructure.Insert(NameOfAttributeToLocalize, LanguageStringToLocalize);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function NameOfAttributeToLocalize(Var_AttributeName, LanguageCode)
	
	NameOfAttributeToLocalize = Var_AttributeName;
	
	If LanguageCode = CommonLanguageParameters.DefaultLanguage Then
		Return NameOfAttributeToLocalize;
		
	ElsIf LanguageCode = CommonLanguageParameters.AdditionalLanguage1 Then
		Return NameOfAttributeToLocalize + "Language1";
		
	ElsIf LanguageCode = CommonLanguageParameters.AdditionalLanguage2 Then
		Return NameOfAttributeToLocalize + "Language2";
	EndIf;
	
	Return "";
	
EndFunction

&AtServerNoContext
Function DefaultKeyAttributeName()
	
	Return "PredefinedDataName";
	
EndFunction

&AtServer
Procedure WriteSpreadsheetDocumentCopy(Var_Enabled = True)
	
	SpreadsheetDocumentCopy.Clear();
	SpreadsheetDocumentCopy.Put(SpreadsheetDocument);
	
	DataTableOnServer = FormAttributeToValue("DataTable", Type("ValueTable"));
	AddressOfDataTableStorage = PutToTempStorage(DataTableOnServer, New UUID);
	
	Items.RollbackToLastStableVersion.Enabled = Var_Enabled;
	
EndProcedure

&AtServer
Procedure RestoreSpreadsheetDocumentFromCopy()
	
	SpreadsheetDocument.Clear();
	SpreadsheetDocument.Put(SpreadsheetDocumentCopy);
	
	DataTableOnServer = GetFromTempStorage(AddressOfDataTableStorage);
	ValueToFormAttribute(DataTableOnServer, "DataTable");
	
	Items.RollbackToLastStableVersion.Enabled = False;
	
EndProcedure

&AtClient
Function CellDataValidationResult(CurrentArea, AttributeType, Var_AttributeName)
	
	ResultingStructure = CheckResult();
	
	Try
		CellValue = CurrentArea.Value;
		ResultingStructure.ThisIsValue = True;
	Except
		CellValue = CurrentArea.Text;
	EndTry;
	
	If IsAccountKind(AttributeType) And (TypeOf(CellValue) <> Type("AccountType")) Then
		ResultingStructure.Success = False;
		ResultingStructure.ErrorText = NStr("ru = 'Некорректное значение вида счета.';
												|en = 'Invalid account type.';");
		ResultingStructure.Value = ActiveAreaStructure[CurrentArea.Name].Value;
		Return ResultingStructure;
	EndIf;
	
	If IsReferenceType(AttributeType) Then
		ValueByDescription = RefValueByDescription(CellValue, Var_AttributeName);
		If (Not ValueByDescription.IsEmpty()) Or IsBlankString(CellValue) Then
			ResultingStructure.Value = ValueByDescription;
			Return ResultingStructure;
		EndIf;
		
		ResultingStructure.Success = False;
		ResultingStructure.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Некорректные данные для типа ""%1"".';
																										|en = 'Invalid value for the %1 data type.';"),
			AttributeType);
		Return ResultingStructure;
	EndIf;
	
	If (Var_AttributeName = DefaultKeyAttributeName()) Or (Var_AttributeName = KeyAttributeName) Then
		IndexOf = CurrentArea.Bottom - 2;
		Try
			DataString1 = DataTable.Get(IndexOf);
		Except
			Return ResultingStructure;
		EndTry;
		
		If IsBlankString(CellValue) And ((CurrentArea.Left = 1) Or (Var_AttributeName = KeyAttributeName)) Then
			ResultingStructure.Success = False;
			ResultingStructure.ErrorText = NStr("ru = 'Значение ключевого реквизита не может быть пустым.';
													|en = 'Key attributes require a non-empty value.';");
			ResultingStructure.Value = ActiveAreaStructure[CurrentArea.Name].Value;
			Return ResultingStructure;
		EndIf;
		
		FoundRows = DataTable.FindRows(New Structure(Var_AttributeName, CellValue));
		If FoundRows.Count() > 0 Then
			ResultingStructure.Success = False;
			ResultingStructure.ErrorText = NStr("ru = 'Значение ключевого реквизита не уникально.';
													|en = 'Key attribute values must be unique.';");
			ResultingStructure.Value = ActiveAreaStructure[CurrentArea.Name].Value;
			Return ResultingStructure;
		EndIf;
		
		If KeyAttributeName <> DefaultKeyAttributeName() Then
			If IsPredefinedItemExists(CellValue) Then
				CurrentArea.Value = "";
				Return ResultingStructure;
			EndIf;
			
			FoundRows = DataTable.FindRows(New Structure(Var_AttributeName, CellValue));
			If FoundRows.Count() > 0 Then
				CurrentArea.Value = "";
				Return ResultingStructure;
			EndIf;
			
			NameOfPropsToCheck = ?(Var_AttributeName = KeyAttributeName, DefaultKeyAttributeName(), KeyAttributeName);
			If Not IsBlankString(DataString1[NameOfPropsToCheck]) Then
				CurrentArea.Value = "";
				Return ResultingStructure;
			EndIf;
		EndIf;
	EndIf;
	
	If IsString(AttributeType) Then
		Return ResultingStructure;
	EndIf;
	
	If IsNumber(AttributeType) Then
		If TypeOf(CellValue) = Type("String") Then
			StringWithoutSpaces = StrReplace(CellValue, " ", "");
			Try
				Number = Number(StringWithoutSpaces);
			Except
				ResultingStructure.Success = False;
				ResultingStructure.ErrorText = NStr("ru = 'Некорректные данные для типа ""Число"".';
														|en = 'Invalid value for the Number data type.';");
			EndTry;
			Return ResultingStructure;
		EndIf;
		
		Return ResultingStructure;
	EndIf;
	
	If ThisIsBoolean(AttributeType) Then
		If TypeOf(CellValue) = Type("String") Then
			StringWithoutSpaces = StrReplace(CellValue, " ", "");
			Try
				Boolean = Boolean(StringWithoutSpaces);
			Except
				ResultingStructure.Success = False;
				ResultingStructure.ErrorText = NStr("ru = 'Некорректные данные для типа ""Булево"".';
														|en = 'Invalid value for the Boolean data type.';");
			EndTry;
			Return ResultingStructure;
		EndIf;
		
		Return ResultingStructure;
	EndIf;
	
	If IsEnum(AttributeType) Then
		IsValueExists = IsEnumerationValueExists(CellValue, AttributeType);
		If Not IsValueExists Then
			ResultingStructure.Success = False;
			ResultingStructure.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Некорректные данные для типа ""%1"".';
																											|en = 'Invalid value for the %1 data type.';"),
				AttributeType);
		EndIf;
		Return ResultingStructure;
	EndIf;
	
	Return ResultingStructure;
	
EndFunction

&AtServer
Function IsPredefinedItemExists(PredefinedDataName)
	
	QueryText = GetDataSelectionQueryText();
	Query = New Query(QueryText);
	SourceTable1 = Query.Execute().Unload();
	
	FoundRows = SourceTable1.FindRows(New Structure("PredefinedDataName", PredefinedDataName));
	
	Return (FoundRows.Count() > 0);
	
EndFunction

&AtServer
Function IsEnumerationValueExists(Value, AttributeType)
	
	For Each Type In AttributeType.Types() Do
		MetadataObjectByType = Metadata.FindByType(Type);
		If MetadataObjectByType = Undefined Then
			Continue;
		EndIf;
		
		Return (MetadataObjectByType.EnumValues.Find(Value) <> Undefined);
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Procedure HideShowAttributeTreeAtServer()
	
	TreeVisibility = Not Items.PropertiesGroup.Visible;
	
	Items.HideAttributeTree.Check = TreeVisibility;
	Items.PropertiesGroup.Visible       = TreeVisibility;
	
	FormCommand = Commands.Find("HideShowAttributeTree");
	FormCommand.ToolTip = ?(TreeVisibility,
		NStr("ru = 'Скрыть дерево реквизитов';
			|en = 'Hide attribute tree';"),
		NStr("ru = 'Показать дерево реквизитов';
			|en = 'Show attribute tree';"));
	
EndProcedure

&AtServerNoContext
Function AccountKindNameByValue(Value)
	
	If Value = AccountType.ActivePassive Then
		Return "ActivePassive";
	EndIf;
	
	Return String(Value);
	
EndFunction

&AtServerNoContext
Function AccountKindPresentation(Value)
	
	AccountKindString = "";
	
	If Value = AccountType.ActivePassive Then
		AccountKindString = "AP";
	ElsIf Value = AccountType.Active Then
		AccountKindString = "A";
	ElsIf Value = AccountType.Passive Then
		AccountKindString = "P";
	EndIf;
	
	Return AccountKindString;
	
EndFunction

// Constructor functions 

&AtServer
Function ExecutionResult()
	
	Result = New Structure;
	Result.Insert("Success",     True);
	Result.Insert("ErrorText", "");
	
	Return Result;
	
EndFunction

&AtServer
Function CodeExecutionResultWithData()
	
	Result = ExecutionResult();
	Result.Insert("Data",        New Array);
	Result.Insert("NamesStructure", New Structure);
	Return Result;
	
EndFunction

&AtServer
Function CheckResult()
	
	Result = ExecutionResult();
	Result.Insert("Value", "");
	Result.Insert("ThisIsValue", False);
	Return Result;
	
EndFunction

#EndRegion
