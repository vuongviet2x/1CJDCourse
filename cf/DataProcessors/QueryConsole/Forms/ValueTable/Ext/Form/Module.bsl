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
Var DefaultColumnName;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Read transfer parameters.
	TransferParameters 	= GetFromTempStorage(Parameters.StorageAddress); // See DataProcessorObject.QueryConsole.PutQueriesInTempStorage
	Object.Queries.Load(TransferParameters.Queries);
	Object.Parameters.Load(TransferParameters.Parameters);
	Object.FileName 	= TransferParameters.FileName;
	CurrentQueryID 	= TransferParameters.CurrentQueryID;
	CurrentParameterID	= TransferParameters.CurrentParameterID;
	
	Object.AvailableDataTypes	= DataProcessorObject2().Metadata().Attributes.AvailableDataTypes.Type;
	DataProcessorObject2().GenerateListOfTypes(TypesList);
	
	FillTablesOnOpen();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ValuesTableSettingsColumnTypeOnChange(Item)
	// Define column name.
	FirstType = "";
	                                                                              
	CurrentColumn 	= Items.ValuesTableSettings.CurrentData;
	ColumnType      = CurrentColumn.ColumnType;
	OldColumnName= CurrentColumn.ColumnDescription;
	
	AvailableTypes 	= CurrentColumn.ColumnType.Types();
	Count 		= AvailableTypes.Count();
	If Count > 0 Then 
		Flag = False;
		For Each ListItem In TypesList Do 
			If ListItem.Presentation = String(AvailableTypes.Get(0)) Then 
				Flag = True;
				Break;
			EndIf;
		EndDo;
		If Flag Then 
			FirstType = String(AvailableTypes.Get(0)); // For primitive types.
		Else
			FirstType = New(AvailableTypes.Get(0));
			FirstType = TypeNameByValue(FirstType);
		EndIf;
	EndIf;
	
	RowID 	= CurrentColumn.GetID();
	If StrFind(Upper(OldColumnName), Upper(DefaultColumnName)) <> 0 Then
		NewColumnName	= GenerateColumnName(FirstType, RowID);
	Else	
		NewColumnName	= OldColumnName;
	EndIf;
	CurrentColumn.ColumnDescription = NewColumnName;
	
	InitializeColumnInValueTableClient(OldColumnName, NewColumnName, ColumnType);
EndProcedure

&AtClient
Procedure ValuesTableSettingsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	Cancel = True;
	
	RowID 					= New UUID;
	ColumnName 								= GenerateColumnName(DefaultColumnName, RowID);
	
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	ColumnType								= New TypeDescription(TypesArray);
	
    SettingItem 						= ValuesTableSettings.Add();
	SettingItem.ColumnDescription    = ColumnName;
	SettingItem.ColumnType    			= ColumnType;
	
	InitializeColumnInValueTableClient("", ColumnName, ColumnType)
EndProcedure

&AtClient
Procedure ValuesTableSettingsColumnDescriptionTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	CurrentColumnValueTable 	= Items.ValuesTableSettings.CurrentData;
	OldName 			= CurrentColumnValueTable.ColumnDescription;
	ColumnType          = CurrentColumnValueTable.ColumnType;
	RowID	= CurrentColumnValueTable.GetID();
	
	Text = RemoveCharsFromText(Text);
	
	If Not IsBlankString(Text) Then 	
		NewName	= GenerateColumnName(Text, RowID);
	Else
		NewName 	= GenerateColumnName(DefaultColumnName, RowID);
		
		ShowMessageToUser(NStr("ru = 'Наименование колонки не может быть пустым.';
											|en = 'Column title cannot be blank.';"), "Object");
	EndIf;
	
	CurrentColumnValueTable.ColumnDescription = NewName;
	
	If ColumnType.Types().Count() <> 0 Then 
		ChangeAttributeAndColumnNameServer(OldName, NewName, ColumnType);
	EndIf;	
EndProcedure

&AtClient
Procedure ValuesTableSettingsBeforeDeleteRow(Item, Cancel)
	CurrentRow 		= Items.ValuesTableSettings.CurrentRow;
	CurrentColumnValueTable 	= Items.ValuesTableSettings.CurrentData;
	ColumnName 			= CurrentColumnValueTable.ColumnDescription;
	ColumnType          = CurrentColumnValueTable.ColumnType;
	
	If ColumnType.Types().Count() <> 0 Then 
		DeleteColumnServer(ColumnName);
	EndIf;	
	
	CollectionItem = ValuesTableSettings.FindByID(CurrentRow);
	CollectionItemIndex = ValuesTableSettings.IndexOf(CollectionItem);
	ValuesTableSettings.Delete(CollectionItemIndex);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExportValuesTable(Command)
	ExportValuesTableServer();	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function DataProcessorObject2()
	Return FormAttributeToValue("Object");
EndFunction

// Generates columns for the Value table from the Value table settings.
//
// Changes the current parameter attributes.
//
&AtClient
Procedure ExportValuesTableServer()
	TransferParameters = PutQueriesInStructure(CurrentQueryID, CurrentParameterID);
	
	Close(); 
	Owner					= FormOwner;
	Owner.Modified = True;
	
	Notify("ExportQueriesToAttributes", TransferParameters);
EndProcedure	

&AtServer
Function InternalValueOfValueTableObject()
	VT = FormAttributeToValue("ValueTableParameter");
	Return ValueToStringInternal(VT);
EndFunction

&AtServer
Function PutQueriesInStructure(QueryID,ParameterId)
	FormParameters = Object.Parameters;
	
	ValueTablePresentation1 = GenerateValueTablePresentation();
	
	For Each Page1 In FormParameters Do
		If Page1.Id = CurrentParameterID Then
			Page1.Type		 		= "ValueTable";
			Page1.Value 		= InternalValueOfValueTableObject();
			Page1.TypeInForm		= NStr("ru = 'Таблица значений';
										|en = 'Value table';");
			Page1.ValueInForm	= ValueTablePresentation1;
		EndIf;
	EndDo;
	
	TransferParameters = New Structure;
	TransferParameters.Insert("StorageAddress", DataProcessorObject2().PutQueriesInTempStorage(Object, QueryID, ParameterId));
	
	Return TransferParameters;
EndFunction	

// Populates value tables in the form by the value table being imported.
//
&AtServer
Procedure FillTablesOnOpen()
	FormParameters = Object.Parameters;
	For Each CurrentParameter In FormParameters Do 
		If CurrentParameter.Id = CurrentParameterID Then 
			Value = CurrentParameter.Value;
			If IsBlankString(Value) Then 
				Return;
			Else
				Break;
			EndIf;
		EndIf;	
	EndDo;	
	
	// Generate the "Settings" table.
	VT = ValueFromStringInternal(Value); // ValueTable
	ThisIsTable = TypeOf(VT) = Type("ValueTable");
	If Not ThisIsTable Then
		Return;
	EndIf;
	
	Columns = VT.Columns;
	For IndexOf = 0 To Columns.Count() - 1 Do
		CurrentColumn = Columns.Get(IndexOf);
		
		ColumnName = CurrentColumn.Name;
		ColumnType = CurrentColumn.ValueType;
		
		Setting 						= ValuesTableSettings.Add();
		Setting.ColumnDescription 	= ColumnName;
		Setting.ColumnType 			= ColumnType;
		
		InitializeColumnInValueTableServer("", ColumnName, ColumnType, "");
	EndDo;	
	
	// Populate value table.
	For Each TableRow In VT Do
		VTItem1 = ValueTableParameter.Add();
		For Each Column In VT.Columns Do
			VTItem1[Column.Name]  = TableRow[Column.Name];
		EndDo;
	EndDo;	
EndProcedure	

&AtServer
Function GenerateValueTablePresentation()
	VT = FormAttributeToValue("ValueTableParameter");
	Presentation = DataProcessorObject2().GenerateValuePresentation(VT);
	
	Return Presentation;
EndFunction

// Generates the name of a column to add.
// It must differ from the form attribute name and column name. 
// 
//
// Parameters:
//  Name - Name to pass.
//
&AtClient
Function GenerateColumnName(Val ColumnName, CurRowID)
	ValueTableSettings = ValuesTableSettings;
	Flag = True;
	IndexOf = 0;
	
	ColumnName = TrimAll(ColumnName);
	
	While Flag Do
		Name = ColumnName + String(Format(IndexOf, "NZ=-"));
		Name = StrReplace(Name, "-", "");
		
		// If a row with this name doesn't exist.
		Filter = New Structure("ColumnDescription", Name);
		FilteredRows = ValueTableSettings.FindRows(Filter);
		If FilteredRows.Count() = 0 Then
			Flag = False;
		Else
			If FilteredRows.Get(0).GetID() <> CurRowID Then
				Flag = True;
			Else
				Flag = False;
			EndIf;
		EndIf;
		
		// If a column with this name doesn't exist.
		Columns = Items.ValueTableParameter.ChildItems;
		NumberOfColumns = Columns.Count();
		For IndexOf = 0 To NumberOfColumns - 1 Do
			If Columns.Get(IndexOf).Name = Name Then
				Flag = True;
				Break;
			EndIf;
		EndDo;
		
		Result = ?(Flag, "", Name);
		
		IndexOf = IndexOf + 1;
	EndDo; 
	
	Return Result;
EndFunction

&AtClient
Procedure InitializeColumnInValueTableClient(OldColumnName, NewColumnName, ColumnType)
	SystemMessage = "";
	InitializeColumnInValueTableServer(OldColumnName, NewColumnName, ColumnType, SystemMessage);
	If Not IsBlankString(SystemMessage) Then
		ShowMessageToUser(SystemMessage, "Object");
	EndIf;
EndProcedure

&AtServer
Procedure InitializeColumnInValueTableServer(OldColumnName, NewColumnName, ColumnType, Message = "");
	
	BeginTransaction();
	Try
		NameOfAttributeToDelete = ParentName + "." + OldColumnName;
		
		// Populate an array with attributes to delete.
		AttributesToDeleteArray = New Array;
		ParentAttr = GetAttributes(ParentName);
		For Each CurAttr In ParentAttr Do
			If CurAttr.Name = OldColumnName Then 
				AttributesToDeleteArray.Add(NameOfAttributeToDelete);
			EndIf;
		EndDo;
		
		// Export values to the value table.
		If Not IsBlankString(OldColumnName) Then
			ValuesVT = ValueTableParameter.Unload(, OldColumnName);
		Else
			ValuesVT = Undefined;
		EndIf;
		
		// Add a new attribute to the object.
		AttributesToBeAdded = New Array;
		
		NewAttribute = New FormAttribute(NewColumnName, ColumnType, ParentName, NewColumnName, False);
		AttributesToBeAdded.Add(NewAttribute);
		ChangeAttributes(AttributesToBeAdded, AttributesToDeleteArray);
		
		// Search for a column in ValueTableParameter with criterion DataPath = NewAttributePath.
		NameOfPropsToAdd = ParentName + "." + NewColumnName;
		ColumnNumber = SearchForColumnsInValueTableWithSpecifiedDataPath(NameOfPropsToAdd);
		If ValuesVT <> Undefined Then 
			If ColumnNumber <> Undefined Then 
				FirstColumnName = ValuesVT.Columns.Get(0).Name;
				IndexOf = 0;
				For Each Page1 In ValuesVT Do 
					ValueTableParameter.Get(IndexOf)[NewColumnName] = Page1[FirstColumnName];
					IndexOf = IndexOf + 1;
				EndDo;
			EndIf;
		Else
			NewTableColumn = Items.Add(NewColumnName, Type("FormField"), Items.ValueTableParameter);
			NewTableColumn.DataPath = NameOfPropsToAdd;
			NewTableColumn.Type = FormFieldType.InputField;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Changes an attribute and column name by the row ID.
//
// Parameters:
//  RowID - Setting value table row ID.
//  Name - New name to be passed for the attribute and column.
//
&AtServer
Procedure ChangeAttributeAndColumnNameServer(OldName, NewName, ColumnType)
	
	BeginTransaction();
	Try
		NameOfAttributeToDelete = ParentName + "." + OldName;
		
		// Populate an array with attributes to delete.
		AttributesToDeleteArray = New Array;
		ParentAttr = GetAttributes(ParentName);
		For Each CurAttr In ParentAttr Do
			If CurAttr.Name = OldName Then 
				AttributesToDeleteArray.Add(NameOfAttributeToDelete);
			EndIf;
		EndDo;
		
		// Export values to the value table.
		ValuesVT = ValueTableParameter.Unload(, OldName);
		
		// Add a new attribute to the object.
		AttributesToBeAdded = New Array;
		NewAttribute = New FormAttribute(NewName, ColumnType, ParentName, NewName, False);
		AttributesToBeAdded.Add(NewAttribute);
		ChangeAttributes(AttributesToBeAdded, AttributesToDeleteArray);
		
		// Search for a column in ValueTableParameter with criterion DataPath = NewAttributePath.
		NameOfPropsToAdd = ParentName + "." + NewName;
		ColumnNumber = SearchForColumnsInValueTableWithSpecifiedDataPath(NameOfPropsToAdd);
		If ColumnNumber <> Undefined Then 
			FirstColumnName = ValuesVT.Columns.Get(0).Name;
			IndexOf = 0;
			For Each OldRow In ValuesVT Do
				ValueTableParameter.Get(IndexOf)[NewName] = OldRow[FirstColumnName];
				IndexOf = IndexOf + 1;
			EndDo;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
	EndTry;
EndProcedure

// Returns a column number with the given path.
//
// Parameters:
//  DataPath - Given path.
//
//	Returns:
//	  Column number or Undefined.
//
&AtServer
Function SearchForColumnsInValueTableWithSpecifiedDataPath(DataPath)
	
	Columns 			= Items.ValueTableParameter.ChildItems;
	ColumnsCount 	= Columns.Count();
	For IndexOf = 0 To ColumnsCount - 1 Do
		CurColumn = Columns.Get(IndexOf);
		If CurColumn.DataPath = DataPath Then
			Return IndexOf;
		EndIf;
	EndDo;
	Return Undefined;
	
EndFunction

// Deletes a column by its name.
//
// Parameters:
//  ColumnName - a column name.
//
&AtServer
Procedure DeleteColumnServer(ColumnName)
	NameOfAttributeToDelete = ParentName + "." + ColumnName;
	
	// Populate an array with attributes to delete.
	AttributesToDeleteArray = New Array;
	ParentAttr		= GetAttributes(ParentName);
	For Each CurAttr In ParentAttr Do
		If CurAttr.Name = ColumnName Then 
			AttributesToDeleteArray.Add(NameOfAttributeToDelete);
		EndIf;	
	EndDo;	
	
	ChangeAttributes(, AttributesToDeleteArray);
EndProcedure	

&AtClient
Procedure ShowMessageToUser(MessageText, DataPath)
	ClearMessages();
	Message = New UserMessage(); 
    Message.Text = MessageText;
	Message.DataPath = DataPath;
	Message.SetData(Object); 
    Message.Message(); 	
EndProcedure	

&AtClient
Function RemoveCharsFromText(Val Text)
	Result = "";
	
	TextLength = StrLen(Text);
	
	If TextLength = 0 Then
		Return Result;
	EndIf;
	
	For IndexOf = 0 To TextLength - 1 Do
		TextChar = Left(Text, 1);
		If Not IsChar(TextChar) Then
			Result = Result + TextChar;
		EndIf;
		Text = Mid(Text, 2);
	EndDo;
	
	Return Result;
EndFunction

&AtClient
Function IsChar(Char)
	// 1040–1103 are Cyrillic letters.
	// 48–57 are digits.
	// 65–122 are Latin letters.
	
	Code = CharCode(Char); 
	If (Code >= 1040 And Code <= 1103) Or (Code >= 48 And Code <= 57) Or (Code >= 65 And Code <= 122) Then
		Return False;
	Else
		Return True;
	EndIf;
EndFunction

&AtServer
Function TypeNameByValue(Value)
	
	MetadataObject = Value.Metadata(); // MetadataObject
	Return MetadataObject.Name;
	
EndFunction

#EndRegion

#Region Initialize

ParentName           = "ValueTableParameter";
DefaultColumnName = "Column";

#EndRegion
