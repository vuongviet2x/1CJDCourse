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

Var FileInfobase Export;

Var PlatformVersion Export;

#EndRegion

#Region Private

///////////////////////////////////////////////////////////////////////////
// FUNCTIONS TO MANAGE TEMPORARY STORAGE

// Parameters:
//   Object - Arbitrary - Data processor object to pass:
//     * Parameters - ValueTable
//     * Queries - ValueTable
//   CurrentQueryID - Current query GUID.
//   CurrentParameterID - Current parameter GUID.
//
// Returns:
//   String - Storage address, where: 
//     * Parameters - ValueTable
//     * Queries - ValueTable
//     * FileName - String
//     * CurrentQueryID - String
//     * CurrentParameterID - String
//
Function PutQueriesInTempStorage(Object, CurrentQueryID, CurrentParameterID) Export
	
	TransferParameters = New Structure;
	TransferParameters.Insert("Queries", Object.Queries.Unload());
	TransferParameters.Insert("Parameters", Object.Parameters.Unload());
	TransferParameters.Insert("FileName", Object.FileName);
	TransferParameters.Insert("CurrentQueryID", CurrentQueryID);
	TransferParameters.Insert("CurrentParameterID", CurrentParameterID);
	
	StorageAddress = PutToTempStorage(TransferParameters);
	Return StorageAddress;
	
EndFunction

// Puts data processor settings into an internal storage.
// 
// Parameters:
//   Object - Data processor object to pass.
//
Function PutSettingsInTempStorage(Object) Export
	
	TransferParameters = New Structure;
	TransferParameters.Insert("UseAutosave", Object.UseAutosave);
	TransferParameters.Insert("AutoSavePeriod", Object.AutoSavePeriod);
	TransferParameters.Insert("OutputRefValuesInQueryResults", Object.OutputRefValuesInQueryResults);
	TransferParameters.Insert("AlternatingColorsByQuery", Object.AlternatingColorsByQuery);
	TransferParameters.Insert("TabOrderType", Object.TabOrderType);
	
	StorageAddress = PutToTempStorage(TransferParameters);
	Return StorageAddress;
	
EndFunction

///////////////////////////////////////////////////////////////////////////
// FUNCTIONS TO MANAGE XML FILES

// Writes queries (text and parameters) to an XML file.
//
// Parameters:
//  FileName - String - an XML file name.
//  Object - Arbitrary - Data processor object to be passed, where:
//   * Parameters - ValueTable
//   * Queries - ValueTable:
//     ** Name - String
//     ** Id - Number
//
Function WriteQueriesToXMLFile(Val Object) Export
	
	
	XMLFile1 = New XMLWriter;
	FileName = GetTempFileName("q1c");
	XMLFile1.OpenFile(FileName);
	XMLFile1.WriteXMLDeclaration();
	XMLFile1.WriteStartElement("querylist");
	// Loop of queries.
	For Each CurrQuery In Object.Queries Do
		XMLFile1.WriteStartElement("query");
		XMLFile1.WriteAttribute("name", CurrQuery.Name);
			XMLFile1.WriteStartElement("text");
			QueryText = CurrQuery.Text;
			
			For Counter = 1 To StrLineCount(QueryText) Do
				TransferStr	= Chars.CR + Chars.LF;
				CurRow 	= StrGetLine(QueryText, Counter);
				XMLFile1.WriteText(CurRow);
				XMLFile1.WriteRaw(TransferStr);
			EndDo;
			XMLFile1.WriteEndElement();
			QueryID = CurrQuery.Id;
			
			If ValueIsFilled(CurrQuery.QueryPlanStorageAddress) Then
				QueryPlanStructure = GetFromTempStorage(CurrQuery.QueryPlanStorageAddress);
				If QueryPlanStructure <> Undefined Then
					If QueryPlanStructure.QueryPlanUpToDate Then
						SQLQuery = QueryPlanStructure.SQLQuery;
						QueryExecutionPlan = QueryPlanStructure.QueryExecutionPlan;
						DBMSType = QueryPlanStructure.DBMSType;
					Else
						SQLQuery = "";
						QueryExecutionPlan = "";
						DBMSType = "";
					EndIf;
				Else
					SQLQuery = "";
					QueryExecutionPlan = "";
					DBMSType = "";
				EndIf;
			Else
				SQLQuery = "";
				QueryExecutionPlan = "";
				DBMSType = "";
			EndIf;
			
			XMLFile1.WriteStartElement("textSQL");
			For Counter = 1 To StrLineCount(SQLQuery) Do
				TransferStr	= Chars.CR + Chars.LF;
				CurRow 	= StrGetLine(SQLQuery, Counter);
				XMLFile1.WriteText(CurRow);
				XMLFile1.WriteRaw(TransferStr);
			EndDo;
			XMLFile1.WriteEndElement();
			
			XMLFile1.WriteStartElement("planSQL");
			For Counter = 1 To StrLineCount(QueryExecutionPlan) Do
				TransferStr	= Chars.CR + Chars.LF;
				CurRow 	= StrGetLine(QueryExecutionPlan, Counter);
				XMLFile1.WriteText(CurRow);
				XMLFile1.WriteRaw(TransferStr);
			EndDo;
			XMLFile1.WriteEndElement();
			
			XMLFile1.WriteStartElement("typeSQL");
			For Counter = 1 To StrLineCount(DBMSType) Do
				TransferStr	= Chars.CR + Chars.LF;
				CurRow 	= StrGetLine(DBMSType, Counter);
				XMLFile1.WriteText(CurRow);
				XMLFile1.WriteRaw(TransferStr);
			EndDo;
			XMLFile1.WriteEndElement();
			
			// Write parameters to an XML file.
			If Object.Parameters.Count() > 0 Then
				XMLFile1.WriteStartElement("parameters");
				For Each CurParameter In Object.Parameters Do
					If CurParameter.QueryID = QueryID Then
						ParameterName		= CurParameter.Name;
						ParameterType		= CurParameter.Type;
						Value			= CurParameter.Value;
						If IsBlankString(Value) Then
							ParameterValue = "";
						Else
							ParameterValue = ValueFromStringInternal(CurParameter.Value);
						EndIf;
						
						XMLFile1.WriteStartElement("parameter");
						XMLFile1.WriteAttribute("name", ParameterName);
						If ParameterType = "ValueList" Then 
							XMLFile1.WriteAttribute("type", ParameterType);
							WriteValueListToXML(XMLFile1, ParameterValue);
						ElsIf ParameterType = "ValueTable" Then
							XMLFile1.WriteAttribute("type", ParameterType);
							
							Columns = ParameterValue.Columns.Count();
							Rows = ParameterValue.Count();
							
							XMLFile1.WriteAttribute("colcount", XMLString(Columns));
							XMLFile1.WriteAttribute("rowcount", XMLString(Rows));
							
							WriteValueTableToXML(XMLFile1, ParameterValue);
						ElsIf ParameterType = "PointInTime" Then
							XMLFile1.WriteAttribute("type", ParameterType);
							WritePointInTimeToXML(XMLFile1, ParameterValue);
						ElsIf ParameterType = "Boundary" Then
							XMLFile1.WriteAttribute("type", ParameterType);
							WriteBorderToXML(XMLFile1, ParameterValue);
						Else
							TypeName = TypeNameFromValue(ParameterValue);
							XMLFile1.WriteAttribute("type", TypeName);
							XMLFile1.WriteAttribute("value", XMLString(ParameterValue));
						EndIf;
						XMLFile1.WriteEndElement();
					EndIf;
				EndDo;
				XMLFile1.WriteEndElement();
			EndIf;
			
		XMLFile1.WriteEndElement();
	EndDo;
	XMLFile1.WriteEndElement();
	XMLFile1.Close();
	
	ReturnValue = New BinaryData(FileName);
	
	DeleteFiles(FileName);
	
	Return ReturnValue;
	
EndFunction

// Writes value list lines to an XML file.
//
// Parameters:
//  XMLFile1 - XMLWriter
//  Value - ValueList
//
Procedure WriteValueListToXML(XMLFile1, Value)
	
	If TypeOf(Value) <> Type("ValueList") Then
		Return;
	EndIf;
	
	For Each ListStr In Value Do
		ValueOfListItem	= ListStr.Value;
		// Determine the type name.
		TypeName = TypeNameFromValue(ValueOfListItem); 
		
		XMLFile1.WriteStartElement("item");
			XMLFile1.WriteAttribute("type", TypeName);
			XMLFile1.WriteAttribute("value", XMLString(ValueOfListItem));
		XMLFile1.WriteEndElement();
	EndDo;
	
EndProcedure

// Parameters:
//   XMLFile1 - XMLWriter
//   Value - ValueTable
//
Procedure WriteValueTableToXML(XMLFile1, Value)
	
	If TypeOf(Value) <> Type("ValueTable") Then
		Return;
	EndIf;
	
	NumberOfColumns 	= Value.Columns.Count();
	CntOfRws	= Value.Count();
	
	For RowIndex2 = 0 To CntOfRws - 1 Do
		For Column_Index = 0 To NumberOfColumns - 1 Do
			ValueOfListItem	= Value.Get(RowIndex2).Get(Column_Index);
			ColumnName = Value.Columns.Get(Column_Index).Name;
			// Determine the type name.
			TypeName = TypeNameFromValue(ValueOfListItem);
			If TypeName = "String" Then 
				Length = Value.Columns.Get(Column_Index).ValueType.StringQualifiers.Length;
			Else 
				Length = 0;
			EndIf;
			
			XMLFile1.WriteStartElement("item");
			XMLFile1.WriteAttribute("nameCol", ColumnName);
			XMLFile1.WriteAttribute("row", XMLString(RowIndex2));
			XMLFile1.WriteAttribute("col", XMLString(Column_Index));
			XMLFile1.WriteAttribute("type", TypeName);
			XMLFile1.WriteAttribute("length", XMLString(Length));
			XMLFile1.WriteAttribute("value", XMLString(ValueOfListItem));
			XMLFile1.WriteEndElement();
		EndDo;
	EndDo;
	
EndProcedure

// Writes a timestamp to an XML file.
//
// Parameters:
//  XMLFile1 - XMLWriter
//  Value - Timestamp.
//
Procedure WritePointInTimeToXML(XMLFile1, Value)
	
	If TypeOf(Value) <> Type("PointInTime") Then
		Return;
	EndIf;
	
	// Determine the type name.
	TypeName = TypeNameFromValue(Value.Ref);
	
	XMLFile1.WriteStartElement("item");
		If Value.Ref <> Undefined Then 
			XMLFile1.WriteAttribute("type", TypeName);
			XMLFile1.WriteAttribute("valueRef", XMLString(Value.Ref));
		EndIf;
		XMLFile1.WriteAttribute("valueDate", XMLString(Value.Date));
	XMLFile1.WriteEndElement();
	
EndProcedure

// Writes a border.
//
Procedure WriteBorderToXML(XMLFile1, Boundary)
	
	If TypeOf(Boundary) <> Type("Boundary") Then
		Return;
	EndIf;
	
	XMLFile1.WriteStartElement("divide");
		// Determine the type name.
		TypeName 			= TypeNameFromValue(Boundary.Value); 
		BorderValueType 	= TypeOf(Boundary.Value);
		
		// Write a border kind to a string.
		BorderKindName = String(Boundary.BoundaryType);
		
		XMLFile1.WriteAttribute("type", TypeName);
		XMLFile1.WriteAttribute("valueDiv", BorderKindName);
		
		If BorderValueType <> Type("PointInTime") Then
			XMLFile1.WriteAttribute("value", XMLString(Boundary.Value));
		Else
			WritePointInTimeToXML(XMLFile1, Boundary.Value);
		EndIf;
	XMLFile1.WriteEndElement();
	
EndProcedure

// Parameters:
//   BinaryData - BinaryData
// Returns:
//   DataProcessorObject.QueryConsole
//
Function ReadQueriesFromXMLFile(BinaryData) Export
	
	FileName = GetTempFileName("q1c");
	BinaryData.Write(FileName);
	XMLFile1 = New XMLReader;
	XMLFile1.OpenFile(FileName);
	XMLFile1.Read();
	// Read all queries.
	If XMLFile1.NodeType = XMLNodeType.StartElement And XMLFile1.Name = "querylist" Then
		While XMLFile1.Read() Do 
			// Read a query.
			If XMLFile1.NodeType = XMLNodeType.StartElement And XMLFile1.Name = "query" Then
				While XMLFile1.ReadAttribute() Do 
					If XMLFile1.Name = "name" Then
						// Add a query to the table.
						curQueryItem 				= Queries.Add();
						curQueryItem.Id	= New UUID;
						curQueryItem.Name 			= XMLFile1.Value;
					EndIf;
				EndDo;
				
				QueryPlanStructure = New Structure;
				QueryPlanStructure.Insert("SQLQuery","");
				QueryPlanStructure.Insert("QueryExecutionPlan","");
				QueryPlanStructure.Insert("DBMSType","");
				QueryPlanStructure.Insert("QueryPlanUpToDate",True);
				
				While XMLFile1.Read() Do 
					If XMLFile1.NodeType = XMLNodeType.StartElement And XMLFile1.Name = "text" Then
						XMLFile1.Read();
						curQueryItem.Text = XMLFile1.Value;
					// Read parameters.
					EndIf;
					If XMLFile1.NodeType = XMLNodeType.StartElement And XMLFile1.Name = "parameters" Then
						While XMLFile1.Read() Do
							// Read an individual parameter.
							If XMLFile1.NodeType = XMLNodeType.StartElement And XMLFile1.Name = "parameter" Then
								While XMLFile1.ReadAttribute() Do 
									// Read the attribute name.									
									If XMLFile1.Name = "name" Then
										curQueryParameter 						= Parameters.Add();
										curQueryParameter.Id  		= New UUID;
										curQueryParameter.Name					= XMLFile1.Value;
										curQueryParameter.QueryID	= curQueryItem.Id;
									EndIf;
									
									// Read the parameter type.
									If XMLFile1.Name = "type" Then
										ElementType 			= Type(XMLFile1.Value);
										curQueryParameter.Type	= String(XMLFile1.Value);
									EndIf;
									
									// Read the parameter value.
									If XMLFile1.Name = "value" Then
										Value					= XMLValue(ElementType, XMLFile1.Value);
										curQueryParameter.Value = ValueToStringInternal(Value);
									EndIf;
									
									// Read the number of value table's columns.
									If XMLFile1.Name = "colcount" Then
										ColumnsCount 	= Number(XMLFile1.Value);
									EndIf;
									
									// Read the number of value table's rows.
									If XMLFile1.Name = "rowcount" Then
										RowsCount 	= Number(XMLFile1.Value);
									EndIf;
								EndDo;
								
								// Read individual types.
								// Individual types imply individual reading of parameters.
								// Individual types are: 
								// Value list, Value table, Timestamp, Boundary.
								//
								// (The list might expand.)
								If curQueryParameter.Type = "ValueList" Then
									ReadValueListFromXML(XMLFile1, curQueryParameter);
								EndIf; 
								If curQueryParameter.Type = "ValueTable" Then
									ReadValueTableFromXML(XMLFile1, curQueryParameter, RowsCount, ColumnsCount);
								EndIf;
								If curQueryParameter.Type = "PointInTime" Then
									ReadPointInTimeFromXML(XMLFile1, curQueryParameter);
								EndIf;
								If curQueryParameter.Type = "Boundary" Then
									ReadBorderFromXML(XMLFile1, curQueryParameter);
								EndIf;
							EndIf;
							If TagsEndCheck(XMLFile1) Then
								Break;
							EndIf;
						EndDo;
					EndIf;
					
					If XMLFile1.NodeType = XMLNodeType.StartElement And XMLFile1.Name = "textSQL" Then
						XMLFile1.Read();
						QueryPlanStructure.SQLQuery = TrimAll(XMLFile1.Value);
					EndIf;
					
					If XMLFile1.NodeType = XMLNodeType.StartElement And XMLFile1.Name = "planSQL" Then
						XMLFile1.Read();
						QueryPlanStructure.QueryExecutionPlan = TrimAll(XMLFile1.Value);
					EndIf;
					
					If XMLFile1.NodeType = XMLNodeType.StartElement And XMLFile1.Name = "typeSQL" Then
						XMLFile1.Read();
						QueryPlanStructure.DBMSType = TrimAll(XMLFile1.Value);
					EndIf;
					
					If TagsEndCheck(XMLFile1) Then
						Break;
					EndIf;
				EndDo; // Looping query tags.
			EndIf; // If the tag is "query".
			If XMLFile1.NodeType = XMLNodeType.EndElement And XMLFile1.Name = "query" Then
				If QueryPlanStructure.SQLQuery <> "" And QueryPlanStructure.QueryExecutionPlan <> "" And QueryPlanStructure.DBMSType <> "" Then
					curQueryItem.QueryPlanStorageAddress = PutToTempStorage(QueryPlanStructure, New UUID());
				Else
					curQueryItem.QueryPlanStorageAddress = PutToTempStorage(Undefined, New UUID());
				EndIf;
			EndIf;
		EndDo;// Looping queries.
	EndIf;// If the tag is "querylist".
	XMLFile1.Close();
	DeleteFiles(FileName);
	Return ThisObject;
	
EndFunction

// Read value list.
//
// Parameters:
//  XMLFile1 - XML to read.
//  QueryParameter - Current parameter.
//
Procedure ReadValueListFromXML(XMLFile1, QueryParameter)
	
	ValuesList1 = New ValueList;
	While XMLFile1.Read() Do
		If XMLFile1.Name = "item" And XMLFile1.NodeType = XMLNodeType.StartElement Then
			While XMLFile1.ReadAttribute() Do
				If XMLFile1.Name = "type" Then
					ElementType = Type(XMLFile1.Value);
				EndIf;
				If XMLFile1.Name = "value" Then
					// Read the value.
					Value				= XMLValue(ElementType, XMLFile1.Value);
					ValueOfListItem 	= Value;
				EndIf;	
			EndDo;	
			ValuesList1.Add(ValueOfListItem);
		ElsIf XMLFile1.Name <> "item" Then
			Break;
		EndIf;
	EndDo;
	
	QueryParameter.Value = ValueToStringInternal(ValuesList1);
	
EndProcedure

// Parameters:
//   XMLFile1 - XMLReader
//   QueryParameter - ValueTable
//   RowsCount - Number
//   ColumnsCount - Number
//
Procedure ReadValueTableFromXML(XMLFile1, QueryParameter, RowsCount, ColumnsCount)
	
	ValueTable = New ValueTable;
	ColumnsArray1 = New Array;
	
	While XMLFile1.Read() Do 
		If XMLFile1.Name = "item" And XMLFile1.NodeType = XMLNodeType.StartElement Then
			While XMLFile1.ReadAttribute() Do
				If XMLFile1.Name = "col" Then
					ColumnIndex 	= Number(XMLFile1.Value);
				EndIf;
				If XMLFile1.Name = "row" Then
					RowIndex 	= Number(XMLFile1.Value);
				EndIf;
				If XMLFile1.Name = "type" Then
					ElementType = Type(XMLFile1.Value);
					TypesArray = New Array;
					TypesArray.Add(ElementType);
				EndIf;
				If XMLFile1.Name = "nameCol" Then
					ColumnName	 = XMLFile1.Value;
				EndIf;
				If XMLFile1.Name = "length" Then
					Length		 = XMLFile1.Value;
				EndIf;
				If XMLFile1.Name = "value" Then
					Value		= XMLValue(ElementType, XMLFile1.Value);
					CellValue 	= Value;
				EndIf;
			EndDo;
			
			RowParameters = New StringQualifiers(Length);
			If ColumnsArray1.Count() - 1 < ColumnIndex Then
				TypeDescription = New TypeDescription();
				TypeDescription = New TypeDescription(TypeDescription, TypesArray,,, RowParameters);
				
				CellsValueListColumns  = New ValueList;
				CellsValueListColumns.Insert(RowIndex,CellValue);
				
				Column_Structure = ColumnsInXMLFile(ColumnName, TypeDescription, CellsValueListColumns);
				ColumnsArray1.Insert(ColumnIndex, Column_Structure);
				
			Else
				TypeDescription = ColumnsArray1.Get(ColumnIndex).TypeDescription;
				TypeDescription = New TypeDescription(TypeDescription, TypesArray,,, RowParameters);
				CellsValueListColumns  = ColumnsArray1.Get(ColumnIndex).CellsValueListColumns;
				CellsValueListColumns.Insert(RowIndex,CellValue);
				
				ColumnsArray1.Delete(ColumnIndex);
				Column_Structure = ColumnsInXMLFile(ColumnName, TypeDescription, CellsValueListColumns);
				
				ColumnsArray1.Insert(ColumnIndex, Column_Structure);
			EndIf;	
		ElsIf XMLFile1.Name <> "item" Then
			Break;
		EndIf;
	EndDo;
	
	NumberOfColumns = ColumnsArray1.Count();
	For ColumnsIndex = 0 To NumberOfColumns - 1 Do
		DescriptionOfColumns =  ColumnsArray1.Get(ColumnsIndex); // See ColumnsInXMLFile
		ColumnName 		= DescriptionOfColumns.Name;
		ColumnType 		= ColumnsArray1.Get(ColumnsIndex).TypeDescription;
		ValueTable.Columns.Insert(ColumnsIndex, ColumnName, ColumnType, ColumnName);
		
		ValueList 	= ColumnsArray1.Get(ColumnsIndex).CellsValueListColumns;
		CntOfRws = ValueList.Count();
		For RowsIndex = 0 To CntOfRws - 1 Do
			CellValue = ValueList.Get(RowsIndex).Value;
			If RowsIndex <= ValueTable.Count() - 1 Then 
				ValueTable.Get(RowsIndex).Set(ColumnsIndex, CellValue);
			Else
				ValueTable.Insert(RowsIndex).Set(ColumnsIndex, CellValue);
			EndIf;
		EndDo;
	EndDo;
	
	QueryParameter.Value = ValueToStringInternal(ValueTable);
	
EndProcedure

// Parameters:
//  ColumnName - String
//  TypeDescription - Structure:
//    * CellsValueListColumns - ValueList
//    * TypeDescription - TypeDescription
//  CellsValueListColumns - TypeDescription
// Returns:
//  Structure:
//   * Name - String
//   * TypeDescription - TypeDescription
//   * CellsValueListColumns - ValueList
// 
Function ColumnsInXMLFile(Val ColumnName, Val TypeDescription, Val CellsValueListColumns)
	
	Column_Structure = New Structure;
	Column_Structure.Insert("Name", ColumnName);
	Column_Structure.Insert("TypeDescription", TypeDescription);
	Column_Structure.Insert("CellsValueListColumns", CellsValueListColumns);
	
	Return Column_Structure;
	
EndFunction


// Reads point in time.
//
// Parameters:
//   XMLFile1 - XML to read.
//   QueryParameter - Current parameter.
//
Procedure ReadPointInTimeFromXML(XMLFile1, QueryParameter)
	
	While XMLFile1.Read() Do 
		If XMLFile1.Name = "item" And XMLFile1.NodeType = XMLNodeType.StartElement Then 
			While XMLFile1.ReadAttribute() Do
				If XMLFile1.Name = "type" Then
					ElementType = Type(XMLFile1.Value);
				EndIf;
				If XMLFile1.Name = "valueRef" Then
					RefValue	= XMLValue(ElementType, XMLFile1.Value);
				EndIf;
				If XMLFile1.Name = "valueDate" Then
					DateValue1	= XMLValue(Type("Date"), XMLFile1.Value);
				EndIf;
			EndDo;
			MV = New PointInTime(DateValue1, RefValue);
		ElsIf XMLFile1.Name <> "item" Then
			Break;
		EndIf;
	EndDo;
	
	QueryParameter.Value	= ValueToStringInternal(MV);
	
EndProcedure

// Reads border.
//
// Parameters:
//  XMLFile1 - XML to read.
//  QueryParameter - Current parameter.
//
Procedure ReadBorderFromXML(XMLFile1, QueryParameter)
	
	While XMLFile1.Read() Do
		If XMLFile1.Name = "divide" And XMLFile1.NodeType = XMLNodeType.StartElement Then
			While XMLFile1.ReadAttribute() Do
				If XMLFile1.Name = "type" Then
					ElementType = Type(XMLFile1.Value);
				EndIf;
				If XMLFile1.Name = "value" Then
					Value	= XMLValue(ElementType, XMLFile1.Value);
				EndIf;
				If XMLFile1.Name = "valueDiv" Then
					Kind	= XMLValue(Type("String"), XMLFile1.Value);
					Kind	= BorderKindDefinition(Kind);
				EndIf;
			EndDo;	
			If ElementType = Type("PointInTime") Then
				ReadPointInTimeFromXML(XMLFile1, QueryParameter);
				Value = ValueFromStringInternal(QueryParameter.Value);
			EndIf;
			
			Boundary = New Boundary(Value, Kind);
		ElsIf XMLFile1.Name <> "divide" Then 
			Break;
		EndIf;
	EndDo;
	
	QueryParameter.Value = ValueToStringInternal(Boundary);
	
EndProcedure

// Defines the criteria of the tag end: "query" or "parameters".
//
// Parameters:
//  XMLFile1 - XMLReader
//
Function TagsEndCheck(XMLFile1)
	
	If (XMLFile1.NodeType = XMLNodeType.EndElement And XMLFile1.Name = "query")
		Or (XMLFile1.NodeType = XMLNodeType.EndElement And XMLFile1.Name = "parameters") Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

///////////////////////////////////////////////////////////////////////////
// FUNCTIONS TO MANAGE QUERIES

// Reads parameters from the query text.
//
// Parameters:
//  QueryText - String
//  QueryID - String - Query UUID.
//
// Returns:
//  Array of See AddingNewParameter
//
Function ReadQueryParameters(QueryText, QueryID) Export
	
	StructureArray = New Array;
	
	Query = New Query;
	Query.Text = QueryText;
	
	// Populate the parameter table with parameters.
	QueryParam = Query.FindParameters();
	
	For Each StrParameters In QueryParam Do
		ResultStructure = AddingNewParameter(StrParameters, QueryID);
		StructureArray.Add(ResultStructure);
	EndDo;
	
	Return StructureArray;
	
EndFunction

// Adds a new parameter to the parameter structure.
//
// Parameters:
//  CurrentReadParameter - QueryParameterDescription - The current parameter read from the query text.
//  QueryID - String - Query GUID.
//
// Returns:
//  Structure:
//   * QueryID - String
//   * Name - String
//   * Type - String
//   * Value - String
//
Function AddingNewParameter(CurrentReadParameter, QueryID)
	
	ParameterItem = New Structure("QueryID, Name, Type, Value",
		QueryID, CurrentReadParameter.Name);
	
	// Check the first type in the list, if any.
	AvailableTypes = CurrentReadParameter.ValueType.Types();
	If AvailableTypes.Count()=0 Then
		// Consider this a string.
		ParameterItem.Type = "String";
		ParameterItem.Value = ValueToStringInternal("");
		Return ParameterItem;
	EndIf;
	
	// Describe the first available type.
	Array = New Array;
	Array.Add( AvailableTypes.Get(0) );
	NewTypesDetails = New TypeDescription(Array);
	
	Value = NewTypesDetails.AdjustValue(Undefined);
	
	AddedTypesList = New ValueList;
	GenerateListOfTypes(AddedTypesList);
	
	Flag = False;
	TypePresentationString = String(TypeOf(Value));
	For Each ListItem In AddedTypesList Do
		If ListItem.Presentation = TypePresentationString Then
			Flag = True;
			Break;
		EndIf;
	EndDo;
	
	ParameterItem.Type = ?(Flag, TypePresentationString, XMLType(TypeOf(Value)).TypeName);
	ParameterItem.Value = ValueToStringInternal(Value);
	
	Return ParameterItem;
	
EndFunction

// Imports parameters to the query.
// If a value is a blank string, the parameter is set to Undefined.
//
// Parameters:
//  Query - Query to passed.
//  QueryOptions - Query parameters to be passed.
//
Procedure ImportParametersToQuery(Query, QueryOptions)
	
	For Each ParameterItem In QueryOptions Do
		StringValue2 = ParameterItem.Value;
		If IsBlankString(StringValue2) Then
			Value = Undefined;
		Else
			Value = ValueFromStringInternal(StringValue2);
		EndIf;
		Query.SetParameter(ParameterItem.Name, Value);
	EndDo;
	
EndProcedure

// Runs a query.
//
// Parameters:
//  QueryText - String
//  QueryOptions - Array - Query parameters.
//  SpreadsheetDocumentOfQueryResult - SpreadsheetDocument - Query result.
//  QueryOutputParameters - Structure:
//    * OutputTempTables - Boolean
//    * OutputID - Boolean - Flag indicating whether to output reference GUIDs.
//    * TabIndex - String - Query result iteration order.
//    * UseAlteration - Boolean - Flag indicating whether to use alteration in the resulting spreadsheet document.
//  QueryExecutionReport - Structure:
//    * RunTime - Number - Query runtime duration.
//    * RowsCount - Number - Number of rows in the query result.
//    * MessageText - String - Error message text.
//  QueryMark - String - Tag that helps to find the query in the technological log.
//
Function ExecuteQuery(QueryText, QueryOptions, SpreadsheetDocumentOfQueryResult, QueryOutputParameters, QueryExecutionReport, QueryMark) Export
	
	If ValueIsFilled(QueryMark) Then
		WriteQueryMark(QueryText, QueryMark, "begin");
	EndIf;
		
	If ValueIsFilled(QueryMark) Then
		WriteQueryMark(QueryText, QueryMark, "end");
	EndIf;
	
	// Array of query texts.
	ArrayOfTexts = BuildQueriesTextsArray(QueryText);
	
	QueryText = StrReplace(QueryText ,"\;", ";"); // Escape semicolons.
	Query = New Query(QueryText);
	
	// Import parameters.
	ImportParametersToQuery(Query, QueryOptions);
	
	// Validate queries.
	Begin = CurrentUniversalDateInMilliseconds();
	If QueryOutputParameters.OutputTempTables Then
		QueriesArray = Query.ExecuteBatchWithIntermediateData();
	Else
		QueriesArray = Query.ExecuteBatch();
	EndIf;
	End  = CurrentUniversalDateInMilliseconds() ;
	QueryExecutionReport.RunTime = (End - Begin) / 1000;
	
	DataArrayByQuery = New Structure;
	DataArrayByQuery.Insert("Query", Query);
	DataArrayByQuery.Insert("ArrayOfTexts", ArrayOfTexts);
	DataArrayByQuery.Insert("QueriesArray", QueriesArray);
	DataArrayByQuery.Insert("QueryMark", QueryMark);
	
	Success = OutputQueriesResult(SpreadsheetDocumentOfQueryResult, DataArrayByQuery, QueryOptions, QueryOutputParameters, QueryExecutionReport);
	If Not Success Then
		If PossibleErrorBecauseOfSemicolon(QueryText) Then 
			QueryExecutionReport.MessageText = NStr("ru = 'Результат запроса не был выведен. Возможно не экранирована точка с запятой. Для экранирования точки с запятой используется обратный слеш -""\;""(см. справку)';
															|en = 'Query result was not output. Maybe a semicolon was not escaped. To escape semicolon, use reverse slash -""\;""(see Help)';");
		Else
			QueryExecutionReport.MessageText = NStr("ru = 'Запрос не был выполнен, т.к. текст запроса некорректный';
															|en = 'Query was not executed as query text is incorrect';");
		EndIf;
	EndIf;
	
	Return QueriesArray;
	
EndFunction

Procedure WriteQueryMark(QueryText, Label, Status)
	
	If Status = "begin" Then
		PlacemarkText = StrReplace("SELECT ""[Marker]"" AS Label INTO Marker_begin", "[Marker]", 
			"Marker_" + Label+ "_"+ Status);
		QueryText = PlacemarkText + Chars.LF + ";" + Chars.LF + QueryText + Chars.LF + ";" + Chars.LF;
	Else
		PlacemarkText = StrReplace("SELECT ""[Marker]"" AS Label INTO Marker_end", "[Marker]", 
			"Marker_" + Label+ "_"+ Status);
		QueryText =  Chars.LF + QueryText + PlacemarkText + Chars.LF + ";" + Chars.LF;
	EndIf;
	
EndProcedure

// Returns an array of query texts.
//
// Parameters:
//  QueryText - String
//
Function BuildQueriesTextsArray(Val QueryText)
	
	ArrayOfTexts = New Array;
	While Not IsBlankString(QueryText) Do
		Semicolon = ";";
		SemicolonPosition = StrFind(QueryText, Semicolon);
		If Mid(QueryText, SemicolonPosition - 1, 1) = "\" Then
			SemicolonPosition = 0;
		EndIf;
		If SemicolonPosition = 0 Then
			NextQueryText 	= QueryText;
			SemicolonPosition	= StrLen(QueryText);
		Else
			NextQueryText = Left(QueryText, SemicolonPosition - 1);
		EndIf;
		If Not IsBlankString(NextQueryText) Then 
			ArrayOfTexts.Add(TrimAll(NextQueryText));
		EndIf;
		QueryText = Mid(QueryText, SemicolonPosition + 1);
	EndDo;
	
	Return ArrayOfTexts;
	
EndFunction

// Returns a value indicating whether the query is hierarchical.
//
// Parameters:
//  QueryText - String
//
Function HasHierarchyInQuery(QueryText)
	
	Totals	= "TOTALS";
	Position	= StrFind(Upper(QueryText), Totals);
	
	Return ?(Position = 0, False, True);
	
EndFunction

// Returns a temporary table name.
//
// Parameters:
//  QueryText - String
//  Buffer - String - Row storage variable of the format 'PUT <TempTableName>'.
//  Position - Number - Cursor position after the word 'INTO' in the query text.
//
Function GetTempTableName(QueryText, Buffer, Position)
	
	TableName		= "";
	TextLength 	= StrLen(QueryText);
	
	// Add blank characters to clipboard.
	For IndexOf = Position To TextLength Do
		Char = Mid(QueryText, IndexOf, 1);
		If IsBlankString(Char) Then
			Buffer = Buffer + Char;
		Else
			Break;
		EndIf;
	EndDo;
	
	// Add a temporary table name.
	For TempTableIndex = IndexOf To TextLength Do
		Char = Mid(QueryText, TempTableIndex, 1);
		If Not IsBlankString(Char) Then
			Buffer 		= Buffer + Char;
			TableName  = TableName + Char; 
		Else
			Break;
		EndIf;
	EndDo;
	
	Return NStr("ru = 'Временная таблица';
				|en = 'Temporary table';") + ": " + TableName;
	
EndFunction

// Returns a query name from the query text.
//
// Parameters:
//  QueryText - String
//
Function GetQueryName(Val QueryText)
	
	Result_Value = NStr("ru = 'Запрос';
							|en = 'Query';") + ": ";
	TextLength = StrLen(QueryText);
	PrepositionFlagFROM = True;
	
	While PrepositionFlagFROM Do 
		WordFROM = "FROM_";
		LengthFROM = StrLen(WordFROM);
		PositionFrom_ = StrFind(Upper(QueryText), WordFROM);
		If PositionFrom_ = 0 Then
			Return Result_Value;
		EndIf;
		
		CharBeforeFROM = Mid(QueryText, PositionFrom_ - 1, 1);
		CharAfterFROM = Mid(QueryText, PositionFrom_ + LengthFROM, 1);
		If IsBlankString(CharBeforeFROM) And IsBlankString(CharAfterFROM) Then
			PrepositionFlagFROM = False;
		Else
			QueryText = Mid(QueryText, PositionFrom_ + LengthFROM);
		EndIf;
	EndDo;
	
	StartPosition = PositionFrom_ + LengthFROM;
	
	For IndexOf = StartPosition To TextLength Do
		Char = Mid(QueryText, IndexOf, 1);
		If Not IsBlankString(Char) Then
			Break;
		EndIf;
	EndDo;
	
	// Generate a table name.
	For QueryIndex = IndexOf To TextLength Do
		Char = Mid(QueryText, QueryIndex, 1);
		If Not IsBlankString(Char) Then
			Result_Value = Result_Value + Char;
		Else
			Break;
		EndIf;
	EndDo;
	
	Return Result_Value;
	
EndFunction

///////////////////////////////////////////////////////////////////////////
// FUNCTIONS TO MANAGE QUERY RESULT

Function PossibleErrorBecauseOfSemicolon(QueryText)
	
	Position = 1;
	While Position >0 Do
		Position = StrFind(QueryText, ";");
		If Position > 0 Then 
			SearchText = Left(QueryText, Position);
			If StrFind(SearchText, """") >0 Then
				Return True;
			EndIf;
		EndIf;
		QueryText = Mid(QueryText, Position + 1);
	EndDo;
	
	Return False;
	
EndFunction

// Output the result of all queries with temporary tables.
// 
// If it is a temporary table, the query runs from the text array and the result generates.
// If it is not a temporary table, the result is taken from the ResultsArray.
//
// Parameters:
//  SpreadsheetDocumentOfQueryResult - SpreadsheetDocument - Query result.
//  DataArrayByQuery - Structure - Contains query data:
//    * Query - Query - Query to passed.
//    * ArrayOfTexts - Array - Array of query texts.
//    * QueriesArray - Array - Array of query results.
//  QueryOptions - Array -  Query parameters.
//  QueryOutputParameters - Structure:
//    * OutputTempTables - Boolean - Flag indicating whether to output temporary tables.
//    * OutputID - Boolean - Flag indicating whether to output reference GUIDs.
//    * TabIndex - String- Query result iteration order.
//    * UseAlteration - Boolean - Flag indicating whether to use alteration in the resulting spreadsheet document.
//  QueryExecutionReport - Structure:
//    * RunTime - Number - Query runtime duration.
//    * RowsCount - Number - Number of rows in the query result.
//    * MessageText - String - Error message text.
//
Function OutputQueriesResult(SpreadsheetDocumentOfQueryResult, DataArrayByQuery, QueryOptions, QueryOutputParameters, QueryExecutionReport)
	
	ArrayOfTexts = DataArrayByQuery.ArrayOfTexts;
	QueriesArray = DataArrayByQuery.QueriesArray;
	QueryMark = DataArrayByQuery.QueryMark;
	
	QueriesTextsCount 		= ArrayOfTexts.Count();
	QueriesResultsCount   = QueriesArray.Count();
		
	If QueriesResultsCount <> QueriesTextsCount Then
		Return False;
	EndIf;
	
	// Append query to output temporary tables (including tables being deleted).
	QueryToAccumulate = New Query;
	ImportParametersToQuery(QueryToAccumulate, QueryOptions);
	
	Into        = "INTO"; // @Query-part
	LengthPut   = StrLen(Into);
		
	For IndexOf = 0 To QueriesTextsCount - 1 Do
		ArrayQueryText = ArrayOfTexts.Get(IndexOf);
		
		If ValueIsFilled(QueryMark) And StrFind(ArrayQueryText, QueryMark) > 0 Then
			QueriesResultsCount = QueriesResultsCount - 1;
			Continue;
		EndIf;
		
		OneQueryRowsCount = 0;
		ColumnsWidthArray          = New Array;
		Collapse                      = DetermineCollapsing(IndexOf, QueriesResultsCount);
		
		PositionPut = StrFind(Upper(ArrayQueryText), Into);
		
		If PositionPut <> 0 And Not QueryOutputParameters.OutputTempTables Then
			Continue;
		EndIf;
		
		Result  = QueriesArray.Get(IndexOf);
		
		If PositionPut <> 0 Then
			
			BufferPut = Mid(ArrayQueryText, PositionPut, LengthPut);
			PositionAfterPut = PositionPut + LengthPut;
			QueryName1 = GetTempTableName(ArrayQueryText, BufferPut, PositionAfterPut);
			
		Else
			QueryName1 = GetQueryName(ArrayQueryText);
		EndIf;
		
		Hierarchy = HasHierarchyInQuery(ArrayQueryText);
		
		SD = OutputSingleQueryResult(QueryName1, Result, Collapse, QueryOutputParameters, Hierarchy, OneQueryRowsCount, ColumnsWidthArray);
		SpreadsheetDocumentOfQueryResult.Put(SD);

		QueryExecutionReport.RowsCount = QueryExecutionReport.RowsCount + OneQueryRowsCount;
	EndDo;
	
	Return True;
	
EndFunction

// Output the query result to a spreadsheet document.
//
// Parameters:
//   QueryName1 - String - Query name.
//   QueryResult - QueryResult
//   IsOpen - Boolean - Flag indicating whether to collapse the result of a query in the spreadsheet document.
//  QueryOutputParameters - Structure:
//    * OutputTempTables - Boolean - Flag indicating whether to output temporary tables.
//    * OutputID - Boolean - Flag indicating whether to output reference GUIDs.
//    * TabIndex - String - Query result iteration order.
//    * UseAlteration - Boolean - Flag indicating whether to use alteration in the resulting spreadsheet document.
//   Hierarchy - Boolean - Flag indicating whether the query contains totals.
//   RowsCount - Number - Number of rows in the query result.
//   ColumnsWidthArray - Array - Column max width.
//
Function OutputSingleQueryResult(QueryName1, QueryResult, IsOpen, QueryOutputParameters, Hierarchy, RowsCount, ColumnsWidthArray)
	
	QueryResult = ResultExport(QueryResult, QueryOutputParameters.TabIndex, Hierarchy);
	
	OutputTemplate = New SpreadsheetDocument;
	OneQueryTemplate = New SpreadsheetDocument;
	
	If QueryResult = Undefined Then
		Return OutputTemplate;
	EndIf;
	
	OneQueryTemplate.Clear();
	OutputTemplate.Clear();
	
	LevelTop = 1;
	HeaderAndDetailsLevel = 2;
	
	If TypeOf(QueryResult) = Type("ValueTree") Then
		RowsCount = QueryResult.Rows.Count();
	Else
		RowsCount = QueryResult.Count();
	EndIf;
	
	// Output to a spreadsheet document.
	ColumnHeaders = OutputColumnsHeaders(QueryResult, ColumnsWidthArray);
	QueryOutputParameters.Insert("ColumnsWidthArray", ColumnsWidthArray);
	QueryOutputParameters.Insert("RowsCount", RowsCount);
	QueryOutputParameters.Insert("OutputStringsCount", 0);
	Details_3 = OutputDetails(QueryResult, QueryOutputParameters);
	
	If QueryOutputParameters.OutputQueryResults >= 0
		 And (QueryOutputParameters.OutputStringsCount < QueryOutputParameters.RowsCount) Then
		StringsCountToTitle = Format(QueryOutputParameters.OutputStringsCount, "NG=0; NZ=0") + " from_ "
			+ QueryOutputParameters.RowsCount;
	Else
		StringsCountToTitle = Format(QueryOutputParameters.RowsCount, "NG=0; NZ=0");
	EndIf;
	
	Title = OutputQueryHeader(QueryName1, StringsCountToTitle);
	
	OneQueryTemplate.StartRowAutoGrouping();
	
	OneQueryTemplate.Put(Title, LevelTop);
	OneQueryTemplate.Put(ColumnHeaders, HeaderAndDetailsLevel,, IsOpen);
	OneQueryTemplate.Put(Details_3, HeaderAndDetailsLevel,, IsOpen);
	
	OneQueryTemplate.EndRowAutoGrouping();
	
	SetAutoWidth(OutputTemplate, ColumnsWidthArray);
	OutputTemplate.Put(OneQueryTemplate).CreateFormatOfRows();
	
	Return OutputTemplate;
	
EndFunction

// Returns resulting ValueTable or ValueTree.
//
// Parameters:
//  QueryResult - QueryResult
//  TabIndex - String
//  Hierarchy - Boolean - Flag indicating whether the query has a hierarchy. 
//
// Returns:
//  ValueTable
//  ValueTree
//
Function ResultExport(QueryResult, TabIndex, Hierarchy)
	
	If QueryResult = Undefined Then
		Return Undefined;
	EndIf;
	
	If Upper(TabIndex) = "AUTO" Then
		If Hierarchy Then
			ExportedValue = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);
		Else
			ExportedValue = QueryResult.Unload(QueryResultIteration.Linear);
		EndIf;
	Else
		ExportedValue = QueryResult.Unload(QueryResultIteration.Linear);
	EndIf;
	
	Return ExportedValue;
	
EndFunction

Function OutputQueryHeader(QueryName1,RowsCount)
	
	Title 	= New SpreadsheetDocument;
	
	OutputLayout = GetTemplate("QueryExecutionResult");
	
	HeaderArea_ 	= OutputLayout.GetArea("QueryName");
	HeaderArea_.Parameters.QueryName1  		= QueryName1;
	HeaderArea_.Parameters.RowsCount	= RowsCount;
	Title.Put(HeaderArea_);
	
	Return Title;
	
EndFunction

Function OutputColumnsHeaders(Result, ColumnsWidthArray)
	
	OutputLayout 				= GetTemplate("QueryExecutionResult");
	
	UpperColumnsHeader		= New SpreadsheetDocument;
	
	ColumnsHeader				= New SpreadsheetDocument;
	ColumnsHeadersArea 		= OutputLayout.GetArea("TableCellArea");
	
	Area 	  					= ColumnsHeadersArea.Area();
	Area.Font 					= New Font(,, False);
	Area.HorizontalAlign = HorizontalAlign.Center;
	Area.BackColor				= StyleColors.TableHeaderBackColor;
	
	IndexOf = 0;
	// Output a table header.
	For Each Page1 In Result.Columns Do
		SettingMaxWidthToArray(IndexOf, Page1.Name, ColumnsWidthArray);
		ColumnsHeadersArea.Parameters.Value	= Page1.Name;
		turn = ColumnsHeader.Join(ColumnsHeadersArea);
		turn.ColumnWidth = ColumnsWidthArray.Get(IndexOf);
		IndexOf	= IndexOf + 1;
	EndDo;
	UpperColumnsHeader.Put(ColumnsHeader);
	
	Return UpperColumnsHeader;
	
EndFunction

Function OutputDetails(Result, QueryOutputParameters)
	
	Details_3 = New SpreadsheetDocument;
	Level = 1;
	Details_3.StartRowAutoGrouping();
	
	If TypeOf(Result) = Type("ValueTree") Then
		RowIndex = 1;
		ColumnsCount = Result.Columns.Count();
		OutputDetailsWithHierarchy(Details_3, Result, QueryOutputParameters, Level, ColumnsCount, RowIndex);
	EndIf;
	
	If TypeOf(Result) = Type("ValueTable") Then
		ColumnsCount = Result.Columns.Count();
		OutputDetailsWithoutHierarchy(Details_3, Result, QueryOutputParameters, Level, ColumnsCount);
	EndIf;
	
	Details_3.EndRowAutoGrouping();
	Return Details_3;
	
EndFunction

Procedure OutputDetailsWithoutHierarchy(CommonDetails, Result, QueryOutputParameters, Level, ColumnsCount)
	
	OutputLayout = GetTemplate("QueryExecutionResult");
	QueryOutputParameters.RowsCount = Result.Count();
	RowIndex = 1;
	
	QueryResultRowsCount = ?(QueryOutputParameters.OutputQueryResults = -1,QueryOutputParameters.RowsCount, QueryOutputParameters.OutputQueryResults);
	
	For Each String In Result Do
		
		If RowIndex > QueryResultRowsCount Then
			Break;
		EndIf;
		
		Details_3 = New SpreadsheetDocument;
		DetailArea = OutputLayout.GetArea("TableCellArea");
		
		Area = DetailArea.CurrentArea;
		Area.Font = New Font(,, False);
		Area.BackColor = DetermineBackgroundColorByIndex(RowIndex, QueryOutputParameters.UseAlteration);
		
		For IndexOf = 0 To ColumnsCount - 1 Do
			Value = String.Get(IndexOf);
			
			If TypeOf(Value) = Type("ValueTable") Then
				Value = ConvertValueTableInRow(Value);
			EndIf;
			
			ValueForParameter = Value;
			If IsReference(TypeOf(Value)) And QueryOutputParameters.OutputID Then
				Try
					ValueForParameter = Value.UUID();
				Except
					ValueForParameter = Value;
				EndTry;
			EndIf;
			DetailArea.Parameters.Value = ValueForParameter;
			DetailArea.Parameters.Details = Value;
			SettingMaxWidthToArray(IndexOf, ValueForParameter, QueryOutputParameters.ColumnsWidthArray);
			Details_3.Join(DetailArea);
		EndDo;
		RowIndex = RowIndex + 1;
		QueryOutputParameters.OutputStringsCount = QueryOutputParameters.OutputStringsCount + 1;
		CommonDetails.Put(Details_3, Level);
	EndDo;
	
EndProcedure

Procedure OutputDetailsWithHierarchy(CommonDetails, Result, QueryOutputParameters , Level, ColumnsCount, RowIndex, CountingRowsCountOnly = False)
	
	
	OutputLayout = GetTemplate("QueryExecutionResult");
	IsOpen = True;
	SubordinateItems = Result.Rows;
	QueryOutputParameters.RowsCount = QueryOutputParameters.RowsCount + SubordinateItems.Count();
	
	If CountingRowsCountOnly Then
		For Each Subordinated In SubordinateItems Do
			OutputDetailsWithHierarchy(CommonDetails, Subordinated, QueryOutputParameters, Level + 1, ColumnsCount, RowIndex, True);
		EndDo;
		Return;
	EndIf;
	
	RowIndexByLevel = 1;
	QueryResultRowsCount = ?(QueryOutputParameters.OutputQueryResults = -1, SubordinateItems.Count(), QueryOutputParameters.OutputQueryResults);
	
	For Each Subordinated In SubordinateItems Do
		
		If RowIndexByLevel > QueryResultRowsCount Then
			OutputDetailsWithHierarchy(CommonDetails, Subordinated, QueryOutputParameters, Level + 1, ColumnsCount, RowIndex, True);
			Continue;
		EndIf;
		
		Details_3 = New SpreadsheetDocument;
		DetailArea = OutputLayout.GetArea("TableCellArea");
		
		Area = DetailArea.CurrentArea;
		Area.Font = New Font(,, False);
		Area.BackColor = DetermineBackgroundColorByIndex(RowIndex, QueryOutputParameters.UseAlteration);
		
		For IndexOf = 0 To ColumnsCount - 1 Do
			Value = Subordinated.Get(IndexOf);
			
			If TypeOf(Value) = Type("ValueTable") Then
				Value = ConvertValueTableInRow(Value);
			EndIf;
			
			ValueForParameter = Value;
			// Computing the indent according to an item level.
			Whitespace = DefineIndentByLevel(Level, IndexOf, IsOpen);
			
			If IsReference(TypeOf(Value)) And QueryOutputParameters.OutputID Then
				Try
					ValueForParameter = Value.UUID();
				Except
					ValueForParameter = Value;
				EndTry;
			EndIf;
			ValueForParameter = "" + Whitespace + ValueForParameter;
			DetailArea.Parameters.Value = ValueForParameter;
			DetailArea.Parameters.Details = Value;
			
			SettingMaxWidthToArray(IndexOf, ValueForParameter, QueryOutputParameters.ColumnsWidthArray);
			
			Details_3.Join(DetailArea);
			
		EndDo;
		
		CommonDetails.Put(Details_3, Level,, IsOpen);
		RowIndex = RowIndex + 1;
		RowIndexByLevel = RowIndexByLevel + 1;
		QueryOutputParameters.OutputStringsCount = QueryOutputParameters.OutputStringsCount + 1;
		
		OutputDetailsWithHierarchy(CommonDetails, Subordinated, QueryOutputParameters, Level + 1, ColumnsCount, RowIndex);
		
	EndDo;
	
EndProcedure

// Determines whether to collapse the result of a query.
//
// Parameters:
//  CurrentQueryPosition - Number - Sequence number of a query in the package.
//  CountOfAllQueries - Number - Total count of queries in the package.
//
Function DetermineCollapsing(Val CurrentQueryPosition, CountOfAllQueries)
	
	CurrentQueryPosition = CurrentQueryPosition + 1;
	
	If CountOfAllQueries = 1 Then
		Result_Value = True;
	Else
		If CurrentQueryPosition = CountOfAllQueries Then
			Result_Value = True;
		Else
			Result_Value = False;
		EndIf;
	EndIf;
	
	Return Result_Value;
	
EndFunction

// Outputs a row with auto width of columns.
//
// Parameters: 
//  QueryResult - SpreadsheetDocument
//  ArrayOfMaxWidth - Array of Number - Column width for an individual query.
//
Procedure SetAutoWidth(QueryResult, ArrayOfMaxWidth)
	
	UpperBound = ArrayOfMaxWidth.UBound();
	If UpperBound = -1 Then
		Return;
	EndIf;
	
	For IndexOf = 0 To UpperBound Do 
		TempSpreadsheetDocument = New SpreadsheetDocument;
		Page1 = TempSpreadsheetDocument.GetArea(1, IndexOf + 1, 1, IndexOf + 1);
		QueryResult.Join(Page1).ColumnWidth = ArrayOfMaxWidth.Get(IndexOf);
	EndDo;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////
// OTHER PROCEDURES AND FUNCTIONS

// Generates a list of valid configuration types.
//
// Parameters:
//  AddedTypesList - ValueList - List of manually added types.
//
// Returns:
//  ValueList
//
Function GenerateListOfTypes(AddedTypesList = Undefined) Export
	
	TypesArray = AvailableDataTypes.Types();
	
	NotPrimitiveTypes = New ValueList;
	NotPrimitiveTypes.LoadValues(TypesArray);
	NotPrimitiveTypes.SortByValue(SortDirection.Asc);
	
	TypesList = New ValueList;
	TypesList.Add("String", NStr("ru = 'Строка';
										|en = 'Row';"));
	TypesList.Add("Number", NStr("ru = 'Число';
										|en = 'Number';"));
	TypesList.Add("Date", NStr("ru = 'Дата';
										|en = 'Date';"));
	TypesList.Add("Boolean", NStr("ru = 'Булево';
										|en = 'Boolean';"));
	TypesList.Add("Boundary", NStr("ru = 'Граница';
										|en = 'Border';"));
	TypesList.Add("PointInTime", NStr("ru = 'Момент времени';
												|en = 'Point in time';"));
	TypesList.Add("ValueList", NStr("ru = 'Список значений';
												|en = 'Value list';"));
	TypesList.Add("ValueTable", NStr("ru = 'Таблица значений';
												|en = 'Value table';"));
	
	AddedTypesList = New ValueList;
	AddedTypesList = TypesList.Copy();
	
	For Each Page1 In NotPrimitiveTypes Do
		TypeValue 		= XMLType(Page1.Value).TypeName;
		TypePresentation 	= String(Page1.Value);
		TypesList.Add(TypeValue, TypePresentation);
	EndDo;
	
	Return TypesList;
	
EndFunction

// Define an indent by level.
//
// Parameters:
//  Level - Number - Passed level within the tree.
//  ColumnNumber - Number - Column number. Indent applies to the first column only.
//  IsOpen - Boolean - Flag indicating whether the group is open or not.
//
Function DefineIndentByLevel(Level, ColumnNumber, IsOpen)
	
	Whitespace = "";
	If ColumnNumber = 0 Then
		If Level > 1 Then
			For IndexOf = 1 To Level Do
				Whitespace = Whitespace + Chars.Tab;
			EndDo;
			IsOpen = False;
		Else
			IsOpen = True;
		EndIf;
	EndIf;
	Return Whitespace;
	
EndFunction

// Returns the string presentation of the type by value.
//
// Parameters:
//  Value - Arbitrary - Value to pass.
//
// Returns:
//  String
//
Function TypeNameFromValue(Value) Export
	
	ValueType = TypeOf(Value);
	If ValueType = Type("String") Or ValueType = Type("Undefined") Then
		TypeName = "String";
	ElsIf ValueType = Type("Number") Then
		TypeName = "Number";
	ElsIf ValueType = Type("Boolean") Then
		TypeName = "Boolean";
	ElsIf ValueType = Type("Date") Then
		TypeName = "Date";
	ElsIf ValueType = Type("PointInTime") Then
		TypeName = "PointInTime";
	ElsIf ValueType = Type("FixedArray") Then
		TypeName = "FixedArray";
	ElsIf ValueType = Type("ValueTable") Then
		TypeName = "ValueTable";
	Else
		TypeName = XMLType(TypeOf(Value)).TypeName;
	EndIf;
	
	Return TypeName;
	
EndFunction

// Returns the border kind from its string presentation.
//
// Parameters:
//  Kind - String - String presentation of a border kind.
//
// Returns:
//  BoundaryType 
//
Function BorderKindDefinition(Kind) Export
	
	If Upper(Kind) = "EXCLUDING" Then
		Result = BoundaryType.Excluding;
	Else
		Result = BoundaryType.Including;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a value presentation.
//
// Parameters:
//  Value - Arbitrary - Value to pass.
//
// Returns:
//  String
//
Function GenerateValuePresentation(Value) Export
	
	Result = "";
	
	If TypeOf(Value) = Type("ValueTable") Then
		TotalString = NStr("ru = 'Таблица: строк = %RowsCount%, колонок = %ColumnsCount%';
								|en = 'Table: rows = %RowsCount%, columns = %ColumnsCount%';");
		TotalString = StrReplace(TotalString, "%RowsCount%", String(Value.Count()));
		TotalString = StrReplace(TotalString, "%ColumnsCount%", String(Value.Columns.Count()));
		Result = TotalString;
	ElsIf TypeOf(Value) = Type("PointInTime") Then
		Result = String(Value.Date) + "; " + String(Value.Ref);
	ElsIf TypeOf(Value) = Type("Boundary") Then 
		Result = String(Value.Value) + "; " + String(Value.BoundaryType);
	EndIf;
	
	Return Result;
	
EndFunction

// Filters the list of types for this context.
//
// Parameters:
//  TypesList - ValueList - Types to pass.
//  Context - String
//
Procedure TypesListFiltering(TypesList, Context) Export
	
	If Lower(Context) = "boundary" Then
		Item = TypesList.FindByValue("ValueList");
		TypesList.Delete(Item);
		Item = TypesList.FindByValue("ValueTable");
		TypesList.Delete(Item);
		Item = TypesList.FindByValue("Boundary");
		TypesList.Delete(Item);
	EndIf;
	
	Item = TypesList.FindByValue("TypeDescription"); // Always delete "Type details" type.
	TypesList.Delete(Item);
	
EndProcedure

// Sets a maximum cell width for each column.
//
Procedure SettingMaxWidthToArray(IndexOf, Val Itm, ColumnsWidthArray)
	
	MaxCellWidth = 100;
	
	Itm = TrimR(Itm);
	Itm = StrLen(Itm);
	If IndexOf > ColumnsWidthArray.UBound() Then
		If Itm < MaxCellWidth Then 
			ColumnsWidthArray.Insert(IndexOf, Itm + 1);
		Else
			ColumnsWidthArray.Insert(IndexOf, MaxCellWidth);
		EndIf;
	Else
		Max = ColumnsWidthArray.Get(IndexOf);
		If Itm > Max Then
			If Itm < MaxCellWidth Then
				ColumnsWidthArray.Set(IndexOf, Itm + 1);
			Else
				ColumnsWidthArray.Set(IndexOf, MaxCellWidth);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Checks if the type is a reference type.
//
// Parameters:
//  Type - Type - Types to pass.
//
// Returns:
//  Boolean
//
Function IsReference(Type) Export
	
	Return Catalogs.AllRefsType().ContainsType(Type)
		Or Documents.AllRefsType().ContainsType(Type)
		Or Enums.AllRefsType().ContainsType(Type)
		Or ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type)
		Or ChartsOfAccounts.AllRefsType().ContainsType(Type)
		Or ChartsOfCalculationTypes.AllRefsType().ContainsType(Type)
		Or BusinessProcesses.AllRefsType().ContainsType(Type)
		Or BusinessProcesses.RoutePointsAllRefsType().ContainsType(Type)
		Or Tasks.AllRefsType().ContainsType(Type)
		Or ExchangePlans.AllRefsType().ContainsType(Type);
	
EndFunction

// Returns the background color of the spreadsheet document by a row index and usage.
//
// Parameters:
//  IndexOf - Number - Row index.
//  Use - Boolean - Flag indicating whether alteration is used.
//
// Returns:
//   Color
//
Function DetermineBackgroundColorByIndex(IndexOf, Use)
	
	AlterationColor = StyleColors.ReportHeaderBackColor;
	
	If Not Use Then
		Return WebColors.White;
	EndIf;
	
	Balance = IndexOf % 2;
	If Balance = 0 Then
		Color = AlterationColor;
	Else
		Color = WebColors.White;
	EndIf;
	
	Return Color;
	
EndFunction

Function ConvertValueTableInRow(ValueTable)
	
	ValueTablePresentation = "";
	For Each ValueTableRow In ValueTable Do
		Separator = "";
		For Each ValueTableCell In ValueTableRow Do
			ValueTablePresentation = ValueTablePresentation + Separator + String(ValueTableCell);
			Separator = ";";
		EndDo;
		ValueTablePresentation = ValueTablePresentation + Chars.LF;
	EndDo;
	
	Return ValueTablePresentation;
	
EndFunction

// Determines infobase type: File (True) or Client/server (False).
// The function uses the InfobaseConnectionString parameter. You can specify this parameter explicitly.
//
// Parameters:
//  InfoBaseConnectionString - String - Parameter is indented to check connection strings
//                 for other infobases.
//
// Returns:
//  Boolean - True if it is a file infobase.
//
Function FileInfobase(Val InfoBaseConnectionString = "")
	
	If IsBlankString(InfoBaseConnectionString) Then
		InfoBaseConnectionString = InfoBaseConnectionString();
	EndIf;
	Return StrFind(Upper(InfoBaseConnectionString), "FILE=") = 1;
	
EndFunction

Function PlatformVersion()

	SystemInfo = New SystemInfo;
	PlatformVersion = SystemInfo.AppVersion;
	Return PlatformVersion;

EndFunction

Function FileIBDirectory()
	
	Path = Upper(InfoBaseConnectionString());
	SearchPosition = StrFind(Path, "FILE");
	If SearchPosition = 0 Then
		Return "";
	EndIf;
	Path = StrReplace(Path, """", "");
	Path = StrReplace(Path, ";", "");
	Path = Mid(Path, SearchPosition + 5);
	SearchPosition = StrFind(Path, "\",SearchDirection.FromEnd);
	Path = Mid(Path, SearchPosition + 1);
	Return Path;
	
EndFunction

// Returns:
//   Structure:
//     * LogFilesDirectory - Undefined
//     * CurrentTechnologicalLogState - Structure:
//        * Enabled - Boolean
//        * LogFilesDirectory - String
//     * TechnologicalLogEventFilters - Undefined
//     * ReplaceFilters - Boolean
//
Function ConfigurationFileProcessingParameters()
	
	CurrentTechnologicalLogState = New Structure;
	CurrentTechnologicalLogState.Insert("Enabled", False);
	CurrentTechnologicalLogState.Insert("LogFilesDirectory", "");

	ProcessingParameters = New Structure;
	ProcessingParameters.Insert("ReplaceFilters", False);
	ProcessingParameters.Insert("TechnologicalLogEventFilters", Undefined);
	ProcessingParameters.Insert("CurrentTechnologicalLogState", CurrentTechnologicalLogState);
	ProcessingParameters.Insert("LogFilesDirectory", Undefined);
	Return ProcessingParameters;

EndFunction

#Region TechnologicalLogOperations

// Enable technological log.
//
Procedure EnableTechnologicalLog(TechnologicalLogParameters, EnableResult) Export
	
	FileInfobase = FileInfobase();
	PlatformVersion = PlatformVersion();
	ApplicationConfigurationDirectory = ConfigFilePath();
	
	If ApplicationConfigurationDirectory <> Undefined Then
	
		ConfigurationFileParameters = New Structure;
		ConfigurationFileParameters.Insert("ApplicationConfigurationDirectory", ApplicationConfigurationDirectory);
		ConfigurationFileParameters.Insert("LogFilesDirectory", Undefined);
		ConfigurationFileParameters.Insert("ConfigurationFile", Undefined);
		ConfigurationFileParameters.Insert("Stream", Undefined);
		
		ConfigurationFileStructure = New Structure;
		
		ReadConfigurationFromFile(ConfigurationFileStructure, ConfigurationFileParameters);
		ChangeConfigurationEnableTechnologicalLog(ConfigurationFileStructure, ConfigurationFileParameters);
		WriteConfigurationToFile(ConfigurationFileStructure, ConfigurationFileParameters, EnableResult, True);
		
		FillPropertyValues(TechnologicalLogParameters, ConfigurationFileParameters, "LogFilesDirectory");
		TechnologicalLogParameters.OSProcessID = Format(OSProcessID(), "NDS=; NGS=; NG=0");
	
	EndIf;
	
EndProcedure

Function ConfigFilePath()
	
	SystemInfo = New SystemInfo();
	If Not ((SystemInfo.PlatformType = PlatformType.Windows_x86) Or (SystemInfo.PlatformType = PlatformType.Windows_x86_64)) Then
		Return Undefined;
	EndIf;
	
	CommonConfigurationFilesDirectory = BinDir() + "conf";
	FilePointer = New File(CommonConfigurationFilesDirectory + GetServerPathSeparator() + "conf.cfg");
	If FilePointer.Exists() Then
		ConfigurationFile = New TextReader(FilePointer.FullName);
		String = ConfigurationFile.ReadLine();
		While String <> Undefined Do
			Position = StrFind(String, "ConfLocation=");
			If Position > 0 Then 
				ApplicationConfigurationDirectory = TrimAll(Mid(String, Position + 13));
				Break;
			EndIf;
			String = ConfigurationFile.ReadLine();
		EndDo;
	EndIf;
	
	Return ApplicationConfigurationDirectory;
	
EndFunction

// Disable technological log.
//
Procedure DisableTechnologicalLog(TechnologicalLogDisablingParameters, ChangeConfigurationFile = True) Export
	
	FileInfobase = FileInfobase();
	PlatformVersion = PlatformVersion();
	ApplicationConfigurationDirectory = ConfigFilePath();
	
	ConfigurationFileParameters = New Structure;
	ConfigurationFileParameters.Insert("ApplicationConfigurationDirectory", ApplicationConfigurationDirectory);
	ConfigurationFileParameters.Insert("LogFilesDirectory", TechnologicalLogDisablingParameters.LogFilesDirectory);
	ConfigurationFileParameters.Insert("ConfigurationFile", Undefined);
	ConfigurationFileParameters.Insert("Stream", Undefined);
	
	ConfigurationFileStructure = New Structure;
	
	ReadConfigurationFromFile(ConfigurationFileStructure, ConfigurationFileParameters);
	If ChangeConfigurationFile Then
		ChangeConfigurationDisableTechnologicalLog(ConfigurationFileStructure, ConfigurationFileParameters);
	EndIf; 
	DisablingResult = New Structure();
	WriteConfigurationToFile(ConfigurationFileStructure, ConfigurationFileParameters, DisablingResult, ChangeConfigurationFile);
	
	FillPropertyValues(TechnologicalLogDisablingParameters, ConfigurationFileStructure, 
		"EnabledDirectoriesRegistry, DeletedDirectoriesRegistry");
	
EndProcedure

Procedure ReadConfigurationFromFile(ConfigurationFileStructure, ConfigurationFileParameters)
	
	ConfigurationFileStructure.Insert("ConfigurationBlocks", New Array);
	ConfigurationFileStructure.Insert("ConsoleBlocksCount", 0);
	ConfigurationFileStructure.Insert("HasPlanSql", False);
	ConfigurationFileStructure.Insert("ConsoleTagsTemplates", ConsoleTagsTemplates());
	
	If ConfigurationFileParameters.ApplicationConfigurationDirectory <> Undefined Then
		
		ConfigurationFileParameters.ConfigurationFile = New File(ConfigurationFileParameters.ApplicationConfigurationDirectory
			+ GetPathSeparator() + "logcfg.xml");
		
		If ConfigurationFileParameters.ConfigurationFile.Exists() Then
			
			ConfigurationFileParameters.Stream = New TextReader(ConfigurationFileParameters.ConfigurationFile.FullName);
			
			TextParameters = New Structure;
			TextParameters.Insert("ConfigurationFileText", ConfigurationFileParameters.Stream);
			TextParameters.Insert("TagRow", "");
			TextParameters.Insert("InitialBlovkRow", "");
			TextParameters.Insert("BlockText", "");
			TextParameters.Insert("CurrentRow", "");
			
			While True Do
				If ReadTextUpToTag(TextParameters, ConfigurationFileStructure.ConsoleTagsTemplates.StartTagStart) Then
					AddBlockToConfigurationStructure(ConfigurationFileStructure, TextParameters, False);
					TextParameters.TagRow = TextParameters.CurrentRow;
					
					If ReadTextUpToTag(TextParameters, ConfigurationFileStructure.ConsoleTagsTemplates.Closing, True) Then
						AddBlockToConfigurationStructure(ConfigurationFileStructure, TextParameters, True);
					Else
						AddBlockToConfigurationStructure(ConfigurationFileStructure, TextParameters, False);
						Break;
					EndIf;
				Else
					// Configuration file has no console blocks.
					AddBlockToConfigurationStructure(ConfigurationFileStructure, TextParameters, False);
					Break;
				EndIf;
			EndDo;
			
			ConfigurationFileParameters.Stream.Close();
			
		EndIf;
		
	EndIf;
	
	For Each ConfigurationBlock In ConfigurationFileStructure.ConfigurationBlocks Do
		
		// Get technological log directory register for each configuration block.
		Try
			
			XMLReader = New XMLReader;
			XMLReader.SetString(ConfigurationBlock.Text);
			XMLReader.Read();
			DOMBuilder = New DOMBuilder;
			LogNode = DOMBuilder.Read(XMLReader);
			XMLReader.Close();
			
		Except
			
			ErrorText = StrReplace(NStr("ru = 'Не удалось прочитать конфигурационный файл logcfg.xml по причине: %1';
											|en = 'Cannot read the configuration file logcfg.xml due to: %1';"),
				"%1", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(EventLogEvent(), EventLogLevel.Error,,, ErrorText);
			Return;
			
		EndTry;
		
		CollectTechnologicalLogDirectoriesByConfigurationNodes(LogNode, LogNode, ConfigurationBlock.TechnologicalLogDirectoriesRegistry);
		
		// Check for the tag that enables a query plan.
		If Not ConfigurationFileStructure.HasPlanSql Then
			If StrFind(ConfigurationBlock.Text, "<plansql/>") > 0 Then
				ConfigurationFileStructure.HasPlanSql = True;
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure AddBlockToConfigurationStructure(ConfigurationFileStructure, TextParameters, IsConsoleBlock)
	
	ConfigurationBlock = New Structure;
	ConfigurationBlock.Insert("IsConsoleBlock", IsConsoleBlock);
	ConfigurationBlock.Insert("Delete", False);
	ConfigurationBlock.Insert("Text", TextParameters.BlockText);
	ConfigurationBlock.Insert("InformationSecurityID");
	ConfigurationBlock.Insert("DateTime");
	ConfigurationBlock.Insert("TechnologicalLogDirectoriesRegistry", New Array);
	
	If IsBlankString(TextParameters.BlockText) Then
		Return;
	EndIf;
	
	If IsConsoleBlock Then
		
		// Parse for tags.
		
		ConsoleTagsTemplates = ConfigurationFileStructure.ConsoleTagsTemplates;
		
		TagRow = TrimAll(TextParameters.TagRow);
		TagRow = TrimAll(Mid(TagRow, StrLen(ConsoleTagsTemplates.StartTagStart) + 1));
		SeparatorPosition = StrFind(TagRow, "SRVR");
		If SeparatorPosition = 0 Then
			SeparatorPosition = StrFind(TagRow, "FILE");
		EndIf;
		If SeparatorPosition > 1 Then
			DateTimeTagRow = TrimAll(Left(TagRow, SeparatorPosition - 1));
			Try
				ConfigurationBlock.Insert("DateTime", Date(DateTimeTagRow));
			Except
				ConfigurationBlock.Insert("DateTime");
			EndTry;
			
			TagRow = TrimAll(Mid(TagRow, SeparatorPosition));
			SeparatorPosition = StrFind(TagRow, ConsoleTagsTemplates.EndTagEnd);
			If SeparatorPosition > 1 Then
				ConfigurationBlock.Insert("InformationSecurityID", TrimAll(Left(TagRow, SeparatorPosition-1)));
			EndIf;
		Else
			DateTimeTagRow = TagRow;
		EndIf;
		
		// Get the technological log directory.
		XMLDirectoryString = New XMLReader;
		XMLDirectoryString.SetString(TextParameters.InitialBlovkRow);
		XMLDirectoryString.Read();
		ConfigurationBlock.Insert("TechnologicalLogDirectory", XMLDirectoryString.GetAttribute("location"));
		
		ConfigurationFileStructure.ConfigurationBlocks.Add(ConfigurationBlock);
		ConfigurationFileStructure.ConsoleBlocksCount = ConfigurationFileStructure.ConsoleBlocksCount + 1;
		
	Else
		
		// Combine into one block all configuration file parts that are not console blocks.
		HasNoConsoleBlock = False;
		For Each ExistingBlock In ConfigurationFileStructure.ConfigurationBlocks Do
			If Not ExistingBlock.IsConsoleBlock Then
				HasNoConsoleBlock = True;
				Break;
			EndIf;
		EndDo;
		
		If HasNoConsoleBlock Then
			ExistingBlock.Text = ExistingBlock.Text + ?(ExistingBlock.Text = "", "", Chars.LF) + TextParameters.BlockText;
		Else
			ConfigurationFileStructure.ConfigurationBlocks.Add(ConfigurationBlock);
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//   TechnologicalLogConfiguration - DOMDocument
//                          - HTMLDocument
//   CurrentNode - HTMLNode
//               - DOMDocument
//               - HTMLDocument
//               - DOMNode
//   TechnologicalLogDirectories - Array
//
Procedure CollectTechnologicalLogDirectoriesByConfigurationNodes(TechnologicalLogConfiguration, CurrentNode, TechnologicalLogDirectories)

	For Each Node In CurrentNode.ChildNodes Do
		
		If Node.NodeName = "#document" Or Node.NodeName = "config" Then
			CollectTechnologicalLogDirectoriesByConfigurationNodes(TechnologicalLogConfiguration, Node, TechnologicalLogDirectories);
		EndIf;
		
		If Node.NodeName = "log" Then
			
			TechnologicalLogDirectory = Node.GetAttribute("location");
			If TechnologicalLogDirectory <> Undefined Then
				TechnologicalLogDirectories.Add(TrimAll(TechnologicalLogDirectory));
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function ReadTextUpToTag(TextParameters, TagTemplate, IncludeTags = False)

	TemplateLength = StrLen(TagTemplate);
	TextParameters.BlockText = "";
	If IncludeTags Then
		TextParameters.BlockText = TextParameters.CurrentRow;
	EndIf; 
	TextParameters.InitialBlovkRow = "";
	IsFirstBlockRow = True;
	TextParameters.CurrentRow = TextParameters.ConfigurationFileText.ReadLine();
	
	While TextParameters.CurrentRow <> Undefined Do
		
		If StrFind(Lower(TextParameters.CurrentRow), "</config>") > 0 Then
			TextParameters.BlockText = TextParameters.BlockText
				+ ?(TextParameters.BlockText = "", "", Chars.LF) + TextParameters.CurrentRow;
			Return False;
		EndIf;
		
		If IsFirstBlockRow Then
			TextParameters.InitialBlovkRow = TextParameters.CurrentRow;
			IsFirstBlockRow = False;
		EndIf;
		
		If Left(TrimAll(TextParameters.CurrentRow), TemplateLength) = TagTemplate Then
			If IncludeTags Then
				TextParameters.BlockText = TextParameters.BlockText
					+ ?(TextParameters.BlockText = "", "", Chars.LF) + TextParameters.CurrentRow;
			EndIf;
			Break;
		EndIf;
		
		TextParameters.BlockText = TextParameters.BlockText
			+ ?(TextParameters.BlockText = "", "", Chars.LF) + TextParameters.CurrentRow;
			
		TextParameters.CurrentRow = TextParameters.ConfigurationFileText.ReadLine();
		
	EndDo;
	
	If TextParameters.CurrentRow = Undefined Then
		Return False;
	EndIf;
	
	Return True;

EndFunction

Procedure WriteConfigurationToFile(ConfigurationFileStructure, ConfigurationFileParameters, EnableResult, Write)
	
	ConfigurationFileStructure.Insert("EnabledDirectoriesRegistry", New Array);
	ConfigurationFileStructure.Insert("DeletedDirectoriesRegistry", New Array);
	
	If Write Then
	
		HasPlanSql = False;
		For Each ConfigurationBlock In ConfigurationFileStructure.ConfigurationBlocks Do
			If ConfigurationBlock.Delete Then
				Continue;
			EndIf;
			If StrFind(ConfigurationBlock.Text, "<plansql/>") > 0 Then
				HasPlanSql = True;
				Break;
			EndIf;
		EndDo;
		
		ConfigurationFileText = "";
		NoConsoleBlockText = "";
		
		ConfigurationFileText = "";
		For Each ConfigurationBlock In ConfigurationFileStructure.ConfigurationBlocks Do
			
			If ConfigurationBlock.IsConsoleBlock
				 And ConfigurationBlock.Delete Then
				For Each TechnologicalLogDirectory In ConfigurationBlock.TechnologicalLogDirectoriesRegistry Do
					ConfigurationFileStructure.DeletedDirectoriesRegistry.Add(Upper(TechnologicalLogDirectory));
				EndDo;
			ElsIf ConfigurationBlock.IsConsoleBlock Then
				ConfigurationFileStructure.EnabledDirectoriesRegistry.Add(Upper(ConfigurationBlock.TechnologicalLogDirectory));
				ConfigurationFileText = ConfigurationFileText + ?(ConfigurationFileText = "", "", Chars.LF)
				 + ConfigurationBlock.Text;
			Else
				For Each TechnologicalLogDirectory In ConfigurationBlock.TechnologicalLogDirectoriesRegistry Do
					ConfigurationFileStructure.EnabledDirectoriesRegistry.Add(Upper(TechnologicalLogDirectory));
				EndDo;
				NoConsoleBlockText = ConfigurationBlock.Text;
			EndIf;
			
			If Not ConfigurationBlock.Delete
				 And Not HasPlanSql
				 And StrFind(ConfigurationBlock.Text, "<plansql/>") > 0 Then
				HasPlanSql = True;
			EndIf;
			
		EndDo;
		
		If Not HasPlanSql
			 And ConfigurationFileStructure.ConsoleBlocksCount > 0 Then
			PlanSqlBlock = ConfigurationFileStructure.ConsoleTagsTemplates.StartTagStart + " -->" + Chars.LF
				+ "<plansql/>" + Chars.LF
				+ ConfigurationFileStructure.ConsoleTagsTemplates.Closing + " -->";
			ConfigurationFileText = ConfigurationFileText + ?(ConfigurationFileText = "", "", Chars.LF) + PlanSqlBlock;
		EndIf;
		
		If Not IsBlankString(ConfigurationFileText) Then
			ConfigurationFileText = StrReplace(NoConsoleBlockText, "</config>", ConfigurationFileText + Chars.LF + "</config>");
		Else
			ConfigurationFileText = NoConsoleBlockText;
		EndIf;
		
		Try
			
			ConfigurationFileParameters.Stream = New TextWriter(ConfigurationFileParameters.ConfigurationFile.FullName);
			ConfigurationFileParameters.Stream.WriteLine(ConfigurationFileText);
			ConfigurationFileParameters.Stream.Close();
			
		Except
			MessageText = NStr("ru = 'Не удалось записать конфигурационный файл в каталоге %1
				|по причине:
				|%2
				|
				|Проверьте права доступа.';
				|en = 'Cannot save the configuration file in the %1 directory
				|due to:
				|%2
				|
				|Check access rights.';");
			MessageText = StrReplace(MessageText, "%1", ConfigurationFileParameters.ApplicationConfigurationDirectory);
			MessageText = StrReplace(MessageText, "%2", ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			EnableResult.Insert("Result", False);
			EnableResult.Insert("Cause", MessageText);
		EndTry;
		
	Else
		
		For Each ConfigurationBlock In ConfigurationFileStructure.ConfigurationBlocks Do
			If ConfigurationBlock.IsConsoleBlock Then
				ConfigurationFileStructure.EnabledDirectoriesRegistry.Add(Upper(ConfigurationBlock.TechnologicalLogDirectory));
			Else
				For Each TechnologicalLogDirectory In ConfigurationBlock.TechnologicalLogDirectoriesRegistry Do
					ConfigurationFileStructure.EnabledDirectoriesRegistry.Add(Upper(TechnologicalLogDirectory));
				EndDo;
			EndIf;
		EndDo;
	
	EndIf;
	
EndProcedure

Function ConsoleTagsTemplates(InformationSecurityID = "")
	
	Result = New Structure;
	Result.Insert("StartTagStart", "<!-- ConsoleQueriesBegin");
	Result.Insert("EndTagEnd", "-->");
	Result.Insert("Closing", "<!-- ConsoleQueriesEnd");
	
	Return Result;
	
EndFunction

Procedure ChangeConfigurationEnableTechnologicalLog(ConfigurationFileStructure, ConfigurationFileParameters)

	CurrentSessionFilter = CurrentSessionFilter();
	
	If ConfigurationFileParameters.ApplicationConfigurationDirectory <> Undefined 
		 And ConfigurationFileParameters.ConfigurationFile.Exists() Then
		// Modify the configuration file.
		
		CurrentSessionConfigurationBlock = Undefined;
		For Each ConfigurationBlock In ConfigurationFileStructure.ConfigurationBlocks Do
		
			If Not ConfigurationBlock.IsConsoleBlock Then
				Continue;
			EndIf;
			
			If ConfigurationBlock.InformationSecurityID = CurrentSessionFilter.InformationSecurityID Then
				CurrentSessionConfigurationBlock = ConfigurationBlock;
			EndIf;
		
		EndDo;
		
		If CurrentSessionConfigurationBlock = Undefined Then
			
			CurrentSessionConfigurationBlock = SessionConfigurationBlock(CurrentSessionFilter, ConfigurationFileStructure.ConsoleTagsTemplates);
			ConfigurationFileStructure.ConfigurationBlocks.Add(CurrentSessionConfigurationBlock);
			ConfigurationFileStructure.ConsoleBlocksCount = ConfigurationFileStructure.ConsoleBlocksCount + 1;
			
		Else
			// Modify the found configuration block.
			ConfigurationBlockText = CurrentSessionConfigurationBlock.Text;
			
			XMLReader = New XMLReader;
			ConfigurationBlockText = StrReplace(ConfigurationBlockText,"<property name=""all""/>","");
			ConfigurationBlockText = StrReplace(ConfigurationBlockText,"<property name=""sql""/>","");
			ConfigurationBlockText = StrReplace(ConfigurationBlockText,"<property name=""plansqltext""/>","");
			ConfigurationBlockText = StrReplace(ConfigurationBlockText,"<plansql/>","");
			XMLReader.SetString(ConfigurationBlockText);
			
			DOMBuilder = New DOMBuilder;
			LogNode = DOMBuilder.Read(XMLReader);
			XMLReader.Close();
			
			ConfigurationProcessingParameters = ConfigurationFileProcessingParameters();
			ConfigurationProcessingParameters.ReplaceFilters = True;
			
			BypassTechnologicalLogConfigurationNodes(LogNode, LogNode, CurrentSessionFilter, ConfigurationProcessingParameters);
			
			DOMWriter = New DOMWriter;
			XMLWriter = New XMLWriter;
			XMLWriter.SetString();
			DOMWriter.Write(LogNode, XMLWriter);
			CurrentSessionConfigurationBlock.Text = XMLWriter.Close();
			Tag = CurrentSessionTag(ConfigurationFileStructure.ConsoleTagsTemplates, CurrentSessionFilter);
			CurrentSessionConfigurationBlock.Text = StrReplace(CurrentSessionConfigurationBlock.Text, "<?xml version=""1.0""?>", Tag);
			
		EndIf;
		
		ConfigurationFileParameters.Insert("LogFilesDirectory", CurrentSessionConfigurationBlock.TechnologicalLogDirectory);
		
	Else
		CreateNewConfiguration(ConfigurationFileStructure, ConfigurationFileParameters, CurrentSessionFilter);
	EndIf;
	
EndProcedure

Function CurrentSessionTag(TagsTemplates, CurrentSessionFilter)
	
	Return TagsTemplates.StartTagStart + " " + Format(CurrentSessionFilter.DateTime, "dd.MM.yyyy hh:mm:ss") + " "
		+ CurrentSessionFilter.InformationSecurityID + " " + TagsTemplates.EndTagEnd;
	
EndFunction

Function SessionConfigurationBlock(CurrentSessionFilter, TagsTemplates)

	TechnologicalLogEvents = QueryConsoleEvents(FileInfobase);
	LogFilesDirectory = GetTempFileName("1c_logs");
	
	SDBLFilterTemplate = "  <eq property=""DBMS"" value=""DBV8DBEng""/>
		|  <eq property=""DataBase"" value=""%1""/>";
	EXCPFilterTemplate = "  <eq property=""DataBase"" value=""%1""/>";
	TemplateOfFilter = "  <eq property=""p:processName"" value=""%1""/>
		|  <eq property=""usr"" value=""%2""/>
		|  <eq property=""sessionid"" value=""%3""/>";

	Text = New Array;
	Text.Add(CurrentSessionTag(TagsTemplates, CurrentSessionFilter));
	Text.Add(StrReplace("<log history=""2"" location=""%1"">", "%1", LogFilesDirectory));
	For Each EventValue In TechnologicalLogEvents Do
		
		If FileInfobase Then
			If EventValue = "SDBL" Then
				FiltersText = StrReplace(SDBLFilterTemplate, "%1", CurrentSessionFilter.DataBase);
			ElsIf EventValue = "DBV8DBEng" Or EventValue = "EXCP" Then
				FiltersText = StrReplace(EXCPFilterTemplate, "%1", CurrentSessionFilter.DataBase);
			EndIf;
		Else
			FiltersText = StrReplace(TemplateOfFilter, "%1", CurrentSessionFilter.processname);
			FiltersText = StrReplace(FiltersText, "%2", CurrentSessionFilter.usr);
			FiltersText = StrReplace(FiltersText, "%3", CurrentSessionFilter.sessionid);
		EndIf;
		
		TextFragment = StrReplace("<event>
			|  <eq property=""name"" value=""%1""/>
			|%2
			|</event>", "%1", EventValue);
		Text.Add(StrReplace(TextFragment, "%2", FiltersText));
	EndDo;
	
	Text.Add("<property name=""all""/>
		|  <property name=""sql""/>
		|  <property name=""plansqltext""/>
		|</log>");
	Text.Add(TagsTemplates.Closing + " " + TagsTemplates.EndTagEnd);
	
	Result = New Structure;
	Result.Insert("IsConsoleBlock", True);
	Result.Insert("Delete", False);
	Result.Insert("InformationSecurityID", CurrentSessionFilter.InformationSecurityID);
	Result.Insert("DateTime", CurrentSessionFilter.DateTime);
	Result.Insert("TechnologicalLogDirectory", LogFilesDirectory);
	Result.Insert("Text", StrConcat(Text, Chars.LF));
	Result.Insert("TechnologicalLogDirectoriesRegistry", New Array);
	
	Return Result;
	
EndFunction

Procedure CreateNewConfiguration(ConfigurationFileStructure, ConfigurationFileParameters, CurrentSessionFilter)
	
	ConfigurationFileStructure.ConfigurationBlocks.Clear();
	ConfigurationFileStructure.ConsoleBlocksCount = 0;
	
	// The configuration's start block
	ConfigurationBlockText = "<?xml version=""1.0"" encoding=""UTF-8""?>" + Chars.LF+ "<config xmlns=""http://v8.1c.ru/v8/tech-log"">"
		+ Chars.LF + "<dump create=""false"" type=""0"" prntscrn=""false""/>" + Chars.LF + "</config>";
	
	ConfigurationBlock = New Structure;
	ConfigurationBlock.Insert("IsConsoleBlock", False);
	ConfigurationBlock.Insert("Delete", False);
	ConfigurationBlock.Insert("InformationSecurityID", Undefined);
	ConfigurationBlock.Insert("DateTime", Undefined);
	ConfigurationBlock.Insert("TechnologicalLogDirectory", Undefined);
	ConfigurationBlock.Insert("Text", ConfigurationBlockText);
	ConfigurationBlock.Insert("TechnologicalLogDirectoriesRegistry", New Array);
	
	ConfigurationFileStructure.ConfigurationBlocks.Add(ConfigurationBlock);
	
	// Current session block.
	ConfigurationBlock = SessionConfigurationBlock(CurrentSessionFilter, ConfigurationFileStructure.ConsoleTagsTemplates);
	ConfigurationFileStructure.ConfigurationBlocks.Add(ConfigurationBlock);
	ConfigurationFileStructure.ConsoleBlocksCount = ConfigurationFileStructure.ConsoleBlocksCount + 1;
	ConfigurationFileParameters.Insert("LogFilesDirectory", ConfigurationBlock.TechnologicalLogDirectory);
	
EndProcedure

Procedure ChangeConfigurationDisableTechnologicalLog(ConfigurationFileStructure, ConfigurationFileParameters)
	
	MaxBlockLifetime = 7200;
	
	CurrentSessionFilter = CurrentSessionFilter();
	
	If ConfigurationFileParameters.ApplicationConfigurationDirectory <> Undefined
		 And ConfigurationFileParameters.ConfigurationFile.Exists() Then
		
		CurrentSessionConfigurationBlock = Undefined;
		For Each ConfigurationBlock In ConfigurationFileStructure.ConfigurationBlocks Do
		
			If Not ConfigurationBlock.IsConsoleBlock Then
				Continue;
			EndIf;
			
			BlockExpired = True;
			If TypeOf(ConfigurationBlock.DateTime) = Type("Date") Then
				BlockExpired = CurrentSessionFilter.DateTime - ConfigurationBlock.DateTime > MaxBlockLifetime;
			EndIf;
			
			If BlockExpired Then
				ConfigurationBlock.Delete = True;
				ConfigurationFileStructure.ConsoleBlocksCount = ConfigurationFileStructure.ConsoleBlocksCount - 1;
				Continue;
			EndIf;
		
			If ConfigurationBlock.InformationSecurityID = CurrentSessionFilter.InformationSecurityID Then
				CurrentSessionConfigurationBlock = ConfigurationBlock;
			EndIf;
			
		EndDo;
		
		If CurrentSessionConfigurationBlock <> Undefined Then
			
			ConfigurationBlockText = CurrentSessionConfigurationBlock.Text;
			
			XMLReader = New XMLReader;
			ConfigurationBlockText = StrReplace(ConfigurationBlockText,"<plansql/>","");
			XMLReader.SetString(ConfigurationBlockText);
			
			DOMBuilder = New DOMBuilder;
			QueryConsoleNode = DOMBuilder.Read(XMLReader);
			XMLReader.Close();
			
			NodesToDelete1 = New Array;
			EventCount = 0;
			FindNodesToDelete(QueryConsoleNode,CurrentSessionFilter, NodesToDelete1, EventCount);
			
			If EventCount = NodesToDelete1.Count() Then
				CurrentSessionConfigurationBlock.Delete = True;
				ConfigurationFileStructure.ConsoleBlocksCount = ConfigurationFileStructure.ConsoleBlocksCount - 1;
			Else
				For Each Event In NodesToDelete1 Do
					Event.ParentNode.RemoveChild(Event);
				EndDo;
				
				DOMWriter = New DOMWriter;
				XMLWriter = New XMLWriter;
				XMLWriter.SetString();
				DOMWriter.Write(QueryConsoleNode, XMLWriter);
				CurrentSessionConfigurationBlock.Text = XMLWriter.Close();
				Tag = CurrentSessionTag(ConfigurationFileStructure.ConsoleTagsTemplates, CurrentSessionFilter);
				CurrentSessionConfigurationBlock.Text = StrReplace(CurrentSessionConfigurationBlock.Text, "<?xml version=""1.0""?>", Tag);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Finds a query and a query plan in the technological log file.
//
Procedure ReadTechnologicalLog(PathToFile, MarkID, ReadData1) Export
	
	RowsArray = New Array;
	AddToArray1 = False;
	
	TempFile = GetTempFileName(".log");
	FileCopy(PathToFile, TempFile);
	
	File = New TextReader();
	File.Open(TempFile);
	String = File.ReadLine();
	TimeLine_ = "";
	While String <> Undefined Do
		If AddToArray1 Then 
			If AddToArray1 And StrFind(String, MarkID + "_end") = 0 Then
				If Mid(String, 3, 1) = ":" And Mid(String, 6, 1) = "." Then
					If ValueIsFilled(TimeLine_) 
						And StrFind(TimeLine_, "Sql=") > 0
						And StrFind(TimeLine_, "planSQLText=") > 0 
						And StrFind(TimeLine_, "Marker_" + MarkID) = 0 Then
						RowsArray.Add(TimeLine_);	
					EndIf;
					TimeLine_ = String;
				Else
					TimeLine_ = TimeLine_ + Chars.LF + String;
				EndIf;
				Else
					Break;
			EndIf;
		EndIf;
		
		If StrFind(String, MarkID + "_begin") > 0 Then
			AddToArray1 = True;
		EndIf;
		String = File.ReadLine();
	EndDo;
	File.Close();
	
	SQLTextFromTechLog = "";
	QueryExecutionPlan = "";
	
	If RowsArray.Count() > 1 Then
		Separator = Chars.LF +  Chars.LF;
	Else
		Separator = "";
	EndIf;
	
	For Each String In RowsArray Do
		PositionStart = StrFind(String, ",");
		RowShift = Mid(String, PositionStart + 1);
		PositionEnd = StrFind(RowShift, ",");
		DBMSType = Upper(Left(RowShift, PositionEnd -1));
		Position = StrFind(RowShift, "Sql=");
		If Mid(RowShift, Position + 4, 1) = """" Or Mid(RowShift, Position + 4, 1) = "'" Then
			RowShift = Mid(RowShift, Position + 5);
		Else
			RowShift = Mid(RowShift, Position + 4);
		EndIf;
		
		If DBMSType = "DBMSSQL" Then 
			Position = StrFind(RowShift, ",Rows");
			SQLTextCurrentQuery = Left(RowShift, Position-2);
			Position = StrFind(RowShift, "planSQLText=");
			RowShift = Mid(RowShift, Position + 13);
			Position = StrFind(RowShift, "'");
			QueryExecutionPlanCurrentQuery = Left(RowShift, Position-1);
		ElsIf DBMSType = "DBPOSTGRS" Then 
			Position = StrFind(RowShift, ",planSQLText=");
			SQLTextCurrentQuery = Left(RowShift, Position-1);
			RowShift = Mid(RowShift, Position + 13);
			Position = StrFind(RowShift, ",Result");
			QueryExecutionPlanCurrentQuery = Left(RowShift, Position-1);
		Else
			Position = StrFind(RowShift, "',");	
			SQLTextCurrentQuery = Left(RowShift, Position-2);
			Position = StrFind(RowShift, "planSQLText=");
			RowShift = Mid(RowShift, Position + 13);
			Position = StrFind(RowShift, "'");
			QueryExecutionPlanCurrentQuery = Left(RowShift, Position-1);
		EndIf;
		
		QueryExecutionPlan = QueryExecutionPlan + QueryExecutionPlanCurrentQuery + Separator;
		SQLTextFromTechLog = SQLTextFromTechLog + SQLTextCurrentQuery +Separator;
		
	EndDo;
	
	ReadData1.DBMSType = DBMSType;
	ReadData1.SQLQuery = TrimAll(SQLTextFromTechLog);
	ReadData1.QueryExecutionPlan = TrimAll(QueryExecutionPlan);
	
	DeleteFiles(TempFile);
	
EndProcedure

Function OSProcessID()
	
	CurrentProcessID = Undefined;
	SystemObject = New COMObject("WScript.Shell");
	If CurrentProcessID = Undefined Then 
		Process_ = SystemObject.Exec("rundll32.exe kernel32,Sleep");
		CurrentProcessID = GetCOMObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\CIMV2:Win32_Process.Handle='" + Format(Process_.ProcessID,"NG=0") + "'").ParentProcessID;
		Process_.Terminate();
	EndIf;
	
	Return CurrentProcessID;
	
EndFunction

Function EventLogEvent() Export
	
	Return NStr("ru = 'Консоль запросов';
				|en = 'Query console';", DefaultLanguageCode());
	
EndFunction

Procedure GetQueryConsoleNode(CurrentNode, ConsoleNode)
	
	For Each Node In CurrentNode.ChildNodes Do
		
		If Node.NodeName = "#document" Or Node.NodeName = "config" Then
			GetQueryConsoleNode(Node, ConsoleNode);
		EndIf;
		
		If Node.NodeName = "log" Then
			If Node.HasAttribute("repname") Then
				 ConsoleNode = Node;
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

Function QueryConsoleEvents(FileInfobase = False)
	
	Result = New Array;
	If Not FileInfobase Then
		Result.Add("db2");
		Result.Add("dbmssql");
		Result.Add("dbpostgrs");
		Result.Add("dboracle");
	EndIf; 
	Result.Add("SDBL");
	Result.Add("DBV8DBEng");
	
	Return Result;
	
EndFunction

Procedure BypassTechnologicalLogConfigurationNodes(TechnologicalLogConfiguration, CurrentNode, CurrentSessionFilter, ProcessingParameters)
	
	For Each Node In CurrentNode.ChildNodes Do
		
		If Node.NodeName = "#document" Or Node.NodeName = "config" Then
			 BypassTechnologicalLogConfigurationNodes(TechnologicalLogConfiguration, Node, CurrentSessionFilter, ProcessingParameters);
		EndIf;
		
		If Node.NodeName = "log" Then
			
			If Not ProcessingParameters.LogFilesDirectory = Undefined Then
				Node.SetAttribute("location", ProcessingParameters.LogFilesDirectory);
			EndIf; 
			
			ProcessingParameters.TechnologicalLogEventFilters = New Structure;
			ProcessingParameters.TechnologicalLogEventFilters.Insert("CurrentEvent",Undefined);
			ProcessingParameters.TechnologicalLogEventFilters.Insert("CurrentInfobase",Undefined);
			ProcessingParameters.TechnologicalLogEventFilters.Insert("CurrentUser",Undefined);
			ProcessingParameters.TechnologicalLogEventFilters.Insert("sessionid",Undefined);
			
			BypassTechnologicalLogConfigurationNodes(TechnologicalLogConfiguration, Node, CurrentSessionFilter, ProcessingParameters);
			TechnologicalLogEventFilters = ProcessingParameters.TechnologicalLogEventFilters;
			
			ShouldEnableTechnologicalLog = (TechnologicalLogEventFilters.CurrentEvent = Undefined
				And TechnologicalLogEventFilters.CurrentInfobase = Undefined
				And TechnologicalLogEventFilters.CurrentUser = Undefined
				And TechnologicalLogEventFilters.sessionid = Undefined
				And ProcessingParameters.ReplaceFilters);
			If ShouldEnableTechnologicalLog Then
				TechnologicalLogEvents = QueryConsoleEvents(FileInfobase);
				For Each ItemEvent In TechnologicalLogEvents Do
					AddQueryConsoleEvent(TechnologicalLogConfiguration,Node, CurrentSessionFilter, ItemEvent);
				EndDo;
			Else
				ShouldEnableTechnologicalLog = (FileInfobase
				 	And TechnologicalLogEventFilters.sessionid = Undefined
				 	And TechnologicalLogEventFilters.CurrentInfobase = CurrentSessionFilter.DataBase
				 	And TechnologicalLogEventFilters.CurrentUser = Undefined)
				  Or (FileInfobase
				 	And TechnologicalLogEventFilters.CurrentEvent <> Undefined
				 	And TechnologicalLogEventFilters.sessionid = Undefined
				 	And TechnologicalLogEventFilters.CurrentInfobase = Undefined
				 	And TechnologicalLogEventFilters.CurrentUser = Undefined)
				  Or (Not FileInfobase
					And TechnologicalLogEventFilters.CurrentEvent <> Undefined
					And TechnologicalLogEventFilters.sessionid = CurrentSessionFilter.sessionid
					And TechnologicalLogEventFilters.CurrentInfobase = CurrentSessionFilter.processname
					And TechnologicalLogEventFilters.CurrentUser = CurrentSessionFilter.usr);
			EndIf;
			If ShouldEnableTechnologicalLog Then
				ProcessingParameters.CurrentTechnologicalLogState = New Structure;
				ProcessingParameters.CurrentTechnologicalLogState.Insert("Enabled", True);
				ProcessingParameters.CurrentTechnologicalLogState.Insert("LogFilesDirectory", Node.GetAttribute("location"));
			EndIf;
			
			If ProcessingParameters.ReplaceFilters Then
				AddQueryConsoleProperty(TechnologicalLogConfiguration,Node, "all");
				AddQueryConsoleProperty(TechnologicalLogConfiguration,Node, "sql");
				AddQueryConsoleProperty(TechnologicalLogConfiguration,Node, "plansqltext");
			EndIf;
			
		EndIf;
		
		If Node.NodeName = "event" Then
			
			BypassTechnologicalLogConfigurationNodes(TechnologicalLogConfiguration, Node, CurrentSessionFilter, ProcessingParameters);
			TechnologicalLogEventFilters = ProcessingParameters.TechnologicalLogEventFilters;

			If (FileInfobase
				 And TechnologicalLogEventFilters.CurrentEvent <> Undefined
				 And TechnologicalLogEventFilters.sessionid = Undefined
				 And TechnologicalLogEventFilters.CurrentInfobase = CurrentSessionFilter.DataBase
				 And TechnologicalLogEventFilters.CurrentUser = Undefined) 
				Or (FileInfobase
				 And TechnologicalLogEventFilters.CurrentEvent <> Undefined
				 And TechnologicalLogEventFilters.sessionid = Undefined
				 And TechnologicalLogEventFilters.CurrentInfobase = Undefined
				 And TechnologicalLogEventFilters.CurrentUser = Undefined)
				Or (Not FileInfobase
				 And TechnologicalLogEventFilters.CurrentEvent <> Undefined
				 And TechnologicalLogEventFilters.sessionid = CurrentSessionFilter.sessionid
				 And TechnologicalLogEventFilters.CurrentInfobase = CurrentSessionFilter.processname
				 And TechnologicalLogEventFilters.CurrentUser = CurrentSessionFilter.usr) Then
				Return;
			EndIf;

			TechnologicalLogEventFilters.CurrentEvent = Undefined;
			TechnologicalLogEventFilters.CurrentInfobase = Undefined;
			TechnologicalLogEventFilters.sessionid = Undefined;
			TechnologicalLogEventFilters.CurrentUser = Undefined;
			
		EndIf;
		
		If Node.NodeName = "eq" Then
			
			If Node.GetAttribute("property") = "name" Then
				ProcessingParameters.TechnologicalLogEventFilters.CurrentEvent = Node.GetAttribute("value");
			EndIf;
			
			If FileInfobase Then
					If Node.GetAttribute("property") = "DataBase" Then
						ProcessingParameters.TechnologicalLogEventFilters.CurrentInfobase = Node.GetAttribute("value");
					EndIf;
			Else
					If Node.GetAttribute("property") = "p:processName" Then
						ProcessingParameters.TechnologicalLogEventFilters.CurrentInfobase = Node.GetAttribute("value");
					EndIf;
			EndIf;
			
			If Node.GetAttribute("property") = "usr" Then
				ProcessingParameters.TechnologicalLogEventFilters.CurrentUser = Node.GetAttribute("value");
			EndIf;
			
			If Node.GetAttribute("property") = "sessionid" Then
				ProcessingParameters.TechnologicalLogEventFilters.sessionid =  Node.GetAttribute("value");
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FindNodesToDelete(CurrentNode,CurrentSessionFilter,NodesToDelete1, EventCount = 0, TechnologicalLogEventFilters = Undefined)
	
	For Each Node In CurrentNode.ChildNodes Do
		
		If Node.NodeName = "log" Then
			FindNodesToDelete(Node,CurrentSessionFilter,NodesToDelete1, EventCount, TechnologicalLogEventFilters);
		EndIf;
		
		If Node.NodeName = "event" Then
			
			TechnologicalLogEventFilters = New Structure;
			TechnologicalLogEventFilters.Insert("CurrentEvent",Undefined);
			TechnologicalLogEventFilters.Insert("CurrentInfobase",Undefined);
			TechnologicalLogEventFilters.Insert("CurrentUser",Undefined);
			TechnologicalLogEventFilters.Insert("sessionid",Undefined);
			
			FindNodesToDelete(Node,CurrentSessionFilter,NodesToDelete1, EventCount, TechnologicalLogEventFilters);
			
			NodeForDeletion = (FileInfobase
				 And TechnologicalLogEventFilters.CurrentEvent <> Undefined
				 And TechnologicalLogEventFilters.sessionid = Undefined
				 And TechnologicalLogEventFilters.CurrentInfobase = CurrentSessionFilter.DataBase
				 And TechnologicalLogEventFilters.CurrentUser = Undefined) 
				Or (FileInfobase
				 And TechnologicalLogEventFilters.CurrentEvent <> Undefined
				 And TechnologicalLogEventFilters.sessionid = Undefined
				 And TechnologicalLogEventFilters.CurrentInfobase = Undefined
				 And TechnologicalLogEventFilters.CurrentUser = Undefined)
				Or (Not FileInfobase
				 And TechnologicalLogEventFilters.CurrentEvent <> Undefined
				 And TechnologicalLogEventFilters.sessionid = CurrentSessionFilter.sessionid
				 And TechnologicalLogEventFilters.CurrentInfobase = CurrentSessionFilter.processname
				 And TechnologicalLogEventFilters.CurrentUser = CurrentSessionFilter.usr)
				Or (Not FileInfobase
				 And CurrentSessionFilter.usr = TechnologicalLogEventFilters.CurrentUser
				 And QueryConsoleSessionInactive(CurrentSessionFilter, TechnologicalLogEventFilters));
			If NodeForDeletion Then
				NodesToDelete1.Add(Node);
			EndIf;
			EventCount = EventCount + 1;
			
		EndIf;
		
		If Node.NodeName = "eq" Then
			If Node.GetAttribute("property") = "name" Then
				TechnologicalLogEventFilters.CurrentEvent = Node.GetAttribute("value");
			EndIf;
			
			If FileInfobase Then
					If Node.GetAttribute("property") = "DataBase" Then
						TechnologicalLogEventFilters.CurrentInfobase = Node.GetAttribute("value");
					EndIf;
			Else
					If Node.GetAttribute("property") = "p:processName" Then
						TechnologicalLogEventFilters.CurrentInfobase = Node.GetAttribute("value");
					EndIf;
			EndIf;
			
			If Node.GetAttribute("property") = "usr" Then
				TechnologicalLogEventFilters.CurrentUser = Node.GetAttribute("value");
			EndIf;
			
			If Node.GetAttribute("property") = "sessionid" Then
				TechnologicalLogEventFilters.sessionid = Node.GetAttribute("value");
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure AddQueryConsoleEvent(TechnologicalLogConfiguration,ParentNode1,CurrentSessionFilter, EventValue)
	
	EventNode = TechnologicalLogConfiguration.CreateElement("event");
	ParentNode1.AppendChild(EventNode);
	
	SetFilter1(TechnologicalLogConfiguration, EventNode, "name", EventValue);
	
	If FileInfobase Then
		If EventValue = "SDBL" Then
			SetFilter1(TechnologicalLogConfiguration, EventNode, "DBMS", "DBV8DBEng");
			SetFilter1(TechnologicalLogConfiguration, EventNode, "DataBase", CurrentSessionFilter.DataBase);
		ElsIf EventValue = "DBV8DBEng" Or EventValue = "EXCP" Then
			SetFilter1(TechnologicalLogConfiguration, EventNode, "DataBase", CurrentSessionFilter.DataBase);
		EndIf;
	Else
		SetFilter1(TechnologicalLogConfiguration, EventNode, "p:processName", CurrentSessionFilter.processname);
		If ValueIsFilled(CurrentSessionFilter.usr) Then
			SetFilter1(TechnologicalLogConfiguration, EventNode, "usr", CurrentSessionFilter.usr);
		EndIf; 
		SetFilter1(TechnologicalLogConfiguration, EventNode, "sessionid", CurrentSessionFilter.sessionid);
	EndIf;
	
EndProcedure

Procedure AddQueryConsoleProperty(TechnologicalLogConfiguration,ParentNode1, PropertyName);
	
	PropertyNode = TechnologicalLogConfiguration.CreateElement("property");
	PropertyNode.SetAttribute("name", PropertyName);
	ParentNode1.AppendChild(PropertyNode);
	
EndProcedure

Procedure SetFilter1(TechnologicalLogConfiguration,ParentNode1, FilterName1, ValueOfFilter)
	
	If ValueOfFilter <> Undefined Then
		FilterNode = TechnologicalLogConfiguration.CreateElement("eq");
		FilterNode.SetAttribute("property", FilterName1);
		FilterNode.SetAttribute("value", ValueOfFilter);
		ParentNode1.AppendChild(FilterNode);
	EndIf;
	
EndProcedure

Function CurrentSessionFilter()
	
	CurrentSessionFilter = New Structure;
	CurrentSessionFilter.Insert("InformationSecurityID", Upper(InfoBaseConnectionString()));
	CurrentSessionFilter.Insert("DateTime", CurrentSessionDate());
	
	If FileInfobase Then
		CurrentSessionFilter.Insert("processname", "");
		CurrentSessionFilter.Insert("usr","");
		CurrentSessionFilter.Insert("sessionid","");
		CurrentSessionFilter.Insert("DataBase", FileIBDirectory());
	Else
		CurrentSessionFilter.Insert("processname", DBMSName());
		CurrentSessionFilter.Insert("usr", UserName());
		CurrentSessionFilter.Insert("sessionid", StrReplace(String(InfoBaseSessionNumber()),Chars.NBSp,""));
	EndIf;
	
	Return CurrentSessionFilter;
	
EndFunction

Function QueryConsoleSessionInactive(CurrentSessionFilter, TechnologicalLogEventFilters)
	
	CurrentInfobaseSessions = GetInfoBaseSessions(); // Array of InfoBaseSession
	 
	If TechnologicalLogEventFilters.CurrentInfobase <> CurrentSessionFilter.processname Then
		Return False;
	EndIf;
	
	For Each CurrentInfobaseSession In CurrentInfobaseSessions Do
		If CurrentInfobaseSession.User.Name = TechnologicalLogEventFilters.CurrentUser
			 And String(CurrentInfobaseSession.SessionNumber) = TechnologicalLogEventFilters.sessionid Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Procedure GetFlagIfTechnologicalLogEnabledForCurrentSession(TechnologicalLogParameters, EnableResult) Export
	
	FileInfobase = FileInfobase();
	PlatformVersion = PlatformVersion();
	ApplicationConfigurationDirectory = ConfigFilePath();
	
	ConfigurationFileParameters = New Structure;
	ConfigurationFileParameters.Insert("ApplicationConfigurationDirectory", ApplicationConfigurationDirectory);
	ConfigurationFileParameters.Insert("ConfigurationFile", Undefined);
	ConfigurationFileParameters.Insert("Stream", Undefined);
	
	ConfigurationFileStructure = New Structure;
	
	ReadConfigurationFromFile(ConfigurationFileStructure, ConfigurationFileParameters);
	
	CurrentSessionFilter = CurrentSessionFilter();
	
	If ConfigurationFileParameters.ApplicationConfigurationDirectory <> Undefined 
		 And ConfigurationFileParameters.ConfigurationFile.Exists() Then
		
		CurrentSessionConfigurationBlock = Undefined;
		For Each ConfigurationBlock In ConfigurationFileStructure.ConfigurationBlocks Do
		
			If Not ConfigurationBlock.IsConsoleBlock Then
				Continue;
			EndIf;
			
			If ConfigurationBlock.InformationSecurityID = CurrentSessionFilter.InformationSecurityID Then
				CurrentSessionConfigurationBlock = ConfigurationBlock;
				Break;
			EndIf;
		
		EndDo;
		
		If CurrentSessionConfigurationBlock <> Undefined Then
			
			ConfigurationBlockText = CurrentSessionConfigurationBlock.Text;
			
			XMLReader = New XMLReader;
			ConfigurationBlockText = StrReplace(ConfigurationBlockText,"<property name=""all""/>","");
			ConfigurationBlockText = StrReplace(ConfigurationBlockText,"<property name=""sql""/>","");
			ConfigurationBlockText = StrReplace(ConfigurationBlockText,"<property name=""plansqltext""/>","");
			ConfigurationBlockText = StrReplace(ConfigurationBlockText,"<plansql/>","");
			XMLReader.SetString(ConfigurationBlockText);
			
			DOMBuilder = New DOMBuilder;
			LogNode = DOMBuilder.Read(XMLReader);
			XMLReader.Close();
			
			ConfigurationProcessingParameters = ConfigurationFileProcessingParameters();
			BypassTechnologicalLogConfigurationNodes(LogNode, LogNode, CurrentSessionFilter, ConfigurationProcessingParameters);
			CurrentTechnologicalLogState = ConfigurationProcessingParameters.CurrentTechnologicalLogState;
			
			If CurrentTechnologicalLogState <> Undefined Then
				OSProcessID = OSProcessID();
				EnableResult.Result = CurrentTechnologicalLogState.Enabled;
				TechnologicalLogParameters.LogFilesDirectory =  CurrentTechnologicalLogState.LogFilesDirectory;
				TechnologicalLogParameters.OSProcessID = Format(OSProcessID, "NDS=; NGS=; NG=0");
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region StandaloneOperation

////////////////////////////////////////////////////////////////////////////////
// Basic procedures and functions that make standalone mode work.

Function SubsystemExists(FullSubsystemName) Export
	
	SubsystemsNames = SubsystemsNames();
	Return SubsystemsNames.Get(FullSubsystemName) <> Undefined;
	
EndFunction

Function SubsystemsNames() Export
	
	Return New FixedMap(SubordinateSubsystemsNames(Metadata));
	
EndFunction

Function SubordinateSubsystemsNames(ParentSubsystem)
	
	Names = New Map;
	
	For Each CurrentSubsystem In ParentSubsystem.Subsystems Do
		
		Names.Insert(CurrentSubsystem.Name, True);
		SubordinatesNames = SubordinateSubsystemsNames(CurrentSubsystem);
		
		For Each SubordinateFormName In SubordinatesNames Do
			Names.Insert(CurrentSubsystem.Name + "." + SubordinateFormName.Key, True);
		EndDo;
	EndDo;
	
	Return Names;
	
EndFunction

Function CommonModule(Name) Export
	
	If Metadata.CommonModules.Find(Name) <> Undefined Then
		Module = Eval(Name);
	Else
		Module = Undefined;
	EndIf;
	
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise StrReplace(NStr("ru = 'Общий модуль ""%1"" не найден.';
											|en = 'Common module %1 is not found.';"), "%1", Name);
	EndIf;
	
	Return Module;
	
EndFunction

Function DefaultLanguageCode()
	If SubsystemExists("StandardSubsystems.Core") Then
		ModuleCommon = CommonModule("Common");
		Return ModuleCommon.DefaultLanguageCode();
	EndIf;
	Return Metadata.DefaultLanguage.LanguageCode;
EndFunction

#EndRegion

#Region QueryAndQueryExecutionPlanProcessing

Function DBMSName()
	
	StringForConnection = InfoBaseConnectionString();
	Position = StrFind(StringForConnection, "Ref=""");
	If Position > 0 Then
		StringForConnection = Mid(StringForConnection, Position + 5);
		Position = StrFind(StringForConnection, """");
		If Position > 0 Then
			Return Left(StringForConnection, Position - 1);
		Else
			Return StringForConnection;
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Converts names of the DBMS query objects into names of the configuration metadata objects.
//
// Returns:
//  Structure:
//    * QueryTextAsMetadata - String
//    * QueryExecutionPlanInMetadata - String 
//
Function TransformToMetadata(QueryText, QueryExecutionPlan, DBMSType)  Export
	
	QueryTextInMetadata = QueryText;
	QueryPlanInMetadata = QueryExecutionPlan;
	
	StringType = New TypeDescription("String", , New StringQualifiers(150));
	StringTypeValue = New TypeDescription("String", , );
	NumberType = New TypeDescription("Number");
	
	Database_Structure = GetDBStorageStructureInfo(, True);
	Database_Structure.Sort("StorageTableName DESC");
	
	DatabaseMapIndex = New ValueTable;
	DatabaseMapIndex.Columns.Add("Key", StringType); 
	DatabaseMapIndex.Columns.Add("Value", StringTypeValue);
	DatabaseMapIndex.Columns.Add("CharsCount", NumberType);
	DatabaseMapIndex.Indexes.Add("Key");
	DatabaseMapIndex.Indexes.Add("CharsCount");
	
	FieldDatabaseMap = New ValueTable;
	FieldDatabaseMap.Columns.Add("Key", StringType); 
	FieldDatabaseMap.Columns.Add("Value", StringTypeValue);
	FieldDatabaseMap.Columns.Add("CharsCount", NumberType);
	FieldDatabaseMap.Indexes.Add("Key");
	FieldDatabaseMap.Indexes.Add("CharsCount");
	
	DatabaseMap = New ValueTable;
	DatabaseMap.Columns.Add("Key", StringType); 
	DatabaseMap.Columns.Add("Value", StringTypeValue);
	DatabaseMap.Columns.Add("CharsCount", NumberType);
	DatabaseMap.Indexes.Add("Key");
	DatabaseMap.Indexes.Add("CharsCount");
	
	For Each String In Database_Structure Do
		NewRow = DatabaseMap.Add();
		NewRow.Key = String.StorageTableName;
		NewRow.Value = String.TableName;
		NewRow.CharsCount = StrLen(String.StorageTableName);
	EndDo;
	
	DatabaseMap.Sort("CharsCount Desc, Key Desc");
	
	For Each String In Database_Structure Do
		For Each IndexOf In String.Indexes Do
			NewRow = DatabaseMapIndex.Add();
			NewRow.Key = IndexOf.StorageIndexName;
			ListField = "";
			Separator = "";
			For Each Field In IndexOf.Fields Do
				If ValueIsFilled(Field.FieldName) Then
					ListField = ListField + Separator + Field.FieldName; 
				EndIf;
				Separator = ", ";
			EndDo;
			NewRow.Value = ListField;
			NewRow.CharsCount = StrLen(IndexOf.StorageIndexName);
		EndDo;
		
		For Each Field In String.Fields Do
			If ValueIsFilled(Field.FieldName) Then
				NewRow = FieldDatabaseMap.Add();
				NewRow.Key = Field.StorageFieldName;
				NewRow.Value = Field.FieldName;
				NewRow.CharsCount = StrLen(Field.StorageFieldName);
			Else
				Position = StrFind(Field.StorageFieldName, "_IDRRef");
				If Position > 1 Then 
					ObjectName = Left(Field.StorageFieldName, Position-1);
					TableName =  DatabaseMap.Find(ObjectName, "Key").Value;
					NewRow = FieldDatabaseMap.Add();
					NewRow.Key = Field.StorageFieldName;
					NewRow.Value = "Ref(" + TableName + ")";
					NewRow.CharsCount = StrLen(Field.StorageFieldName);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	FieldDatabaseMap.Sort("CharsCount Desc, Key DESC");
	DatabaseMapIndex.Sort("CharsCount Desc, Key DESC");
	
	If DBMSType = "DBPOSTGRS" Then
		QueryPlanInMetadata = Lower(QueryPlanInMetadata);
	ElsIf DBMSType = "DBMSSQL" Then
		// Clear the query.
		QueryPlanInMetadata = StrReplace(QueryPlanInMetadata, "[" + DBMSName() + "].[dbo].", "");
		QueryPlanInMetadata = StrReplace(QueryPlanInMetadata, "[tempdb].[dbo].", "");
		QueryPlanInMetadata = StrReplace(QueryPlanInMetadata, "#tt", "TempTable");
		QueryTextInMetadata = StrReplace(QueryTextInMetadata, "dbo.", "");
		QueryTextInMetadata = StrReplace(QueryTextInMetadata, "#tt", "TempTable");
	EndIf;
	
	For Each Field In DatabaseMapIndex Do
		
		If StrFind(QueryPlanInMetadata, Field.Key) Then
			If DBMSType = "DBPOSTGRS" Then
				Var_Key = Lower(Field.Key);
			Else
				Var_Key = Field.Key;
			EndIf;
			QueryPlanInMetadata = StrReplace(QueryPlanInMetadata, Var_Key, NStr("ru = 'Индекс по';
																					|en = 'Index by';") + " " + Field.Value + "");
		EndIf;
		
	EndDo;
	
	For Each Field In FieldDatabaseMap Do
		If StrFind(QueryTextInMetadata, Field.Key) Then
			QueryTextInMetadata = StrReplace(QueryTextInMetadata, Field.Key, Field.Value);
			If DBMSType = "DBPOSTGRS" Then 
				Var_Key = Lower(Field.Key);
			Else
				Var_Key = Field.Key;
			EndIf;
			QueryPlanInMetadata = StrReplace(QueryPlanInMetadata, Var_Key, Field.Value);
		EndIf;
	EndDo;
	
	For Each Field In DatabaseMap Do
		If StrFind(QueryTextInMetadata, Field.Key) Then
			QueryTextInMetadata = StrReplace(QueryTextInMetadata, Field.Key, Field.Value);
			If DBMSType = "DBPOSTGRS" Then 
				QueryPlanInMetadata = StrReplace(QueryPlanInMetadata, Lower(Field.Key), Field.Value);
			ElsIf DBMSType = "DBMSSQL" Then 
				QueryPlanInMetadata = StrReplace(QueryPlanInMetadata, "[" + Field.Key + "]", Field.Value);	
			Else
				QueryPlanInMetadata = StrReplace(QueryPlanInMetadata, Field.Key, Field.Value);
			EndIf;
		EndIf;
	EndDo;
	
	AsMetadata = New Structure();
	AsMetadata.Insert("QueryTextAsMetadata", QueryTextInMetadata);
	AsMetadata.Insert("QueryExecutionPlanInMetadata", QueryPlanInMetadata);
	
	Return AsMetadata;
	
EndFunction

// Parameters:
//   QueryPlanText - String
//   QueryPlanMetadata - String
//   TreeQueryPlan - ValueTree
//   TotalCostTotal - Number
// 
Procedure QueryExecutionPlanTree(Val QueryPlanText, Val QueryPlanMetadata, TreeQueryPlan, TotalCostTotal) Export
	
	TotalCostTotal = 0;
	
	Position = 1;
	PreviousPosition = 0;
	String_Tree = TreeQueryPlan;
	While Position > 0  Do
		ArrayOfCells = New Array;
		For IndexOf = 1 To 8 Do
			Position = StrFind(QueryPlanText, ",");
			ArrayOfCells.Add(TrimAll(Left(QueryPlanText, Position-1)));
			QueryPlanText = Mid(QueryPlanText, Position + 1);
		EndDo;
		Position = StrFind(QueryPlanText, Chars.LF);
		If Position = 0 Then
			Operator = QueryPlanText;
		Else
			Operator = Left(QueryPlanText, Position - 1);
		EndIf;
		QueryPlanText = Mid(QueryPlanText, Position + 1);
	
		For IndexOf = 1 To 8 Do
			PositionMetadata = StrFind(QueryPlanMetadata, ",");
			QueryPlanMetadata = Mid(QueryPlanMetadata, PositionMetadata + 1);
		EndDo;
		PositionMetadata = StrFind(QueryPlanMetadata, Chars.LF);
		If PositionMetadata > 0 Then
			OperatorMetadata = Left(QueryPlanMetadata, PositionMetadata - 1);
			QueryPlanMetadata = Mid(QueryPlanMetadata, PositionMetadata + 1);
		Else
			OperatorMetadata = QueryPlanMetadata;
		EndIf;
		
		PositionMetadata = StrFind(OperatorMetadata, "|--") - 4;
		
		If PositionMetadata = 0 Then 
			String_Tree = TreeQueryPlan.Rows.Add();
		Else
			If PreviousPosition < PositionMetadata Then 
				String_Tree = String_Tree.Rows.Add();
			ElsIf PreviousPosition > PositionMetadata Then 
				String_Tree = FindPositionInBranch(String_Tree, PositionMetadata); // ValueTreeRow
				If String_Tree <> Undefined Then 
					String_Tree = String_Tree.Rows.Add();
				Else
					String_Tree = TreeQueryPlan.Rows.Add();
				EndIf;
			Else 
				RowsUpOneLevel = String_Tree.Parent.Rows; // ValueTreeRowCollection
				String_Tree = RowsUpOneLevel.Add();
				
			EndIf;
		EndIf;
		
		If String_Tree.Parent = Undefined Then
			TotalCostTotal = TotalCostTotal + ConvertToNumber(ArrayOfCells[6]);
		EndIf;

		PositionSQL = StrFind(Operator, "|--");
		String_Tree.Operator = Mid(Operator, PositionSQL + 3);
		String_Tree.OperatorMetadata = Mid(OperatorMetadata, PositionMetadata + 7);
		String_Tree.Indent = PositionMetadata;
		String_Tree.FactRows = ArrayOfCells[0];
		String_Tree.CallsActual = ArrayOfCells[1];
		String_Tree.PlanRows = ArrayOfCells[2];
		String_Tree.InputOutputCosts = ArrayOfCells[3];
		String_Tree.CPUUtilization = ArrayOfCells[4];
		String_Tree.AverageRowSize = ArrayOfCells[5];
		String_Tree.CostTotal = ConvertToNumber(ArrayOfCells[6]);
		String_Tree.CallsPlanned = ArrayOfCells[7];
		PreviousPosition = PositionMetadata;
	EndDo;
	
	CalculateOperatorsCost(TreeQueryPlan.Rows);
	
EndProcedure

Function CalculateOperatorsCost(TreeBranch1)
	
	Sum = 0;
	
	For Each String In TreeBranch1 Do
		
		CostAccumulator = 0;
		
		If String.Rows.Count() > 0 Then
			CostAccumulator = CalculateOperatorsCost(String.Rows);
		EndIf;
		
		OperatorCost = String.CostTotal - CostAccumulator;
		String.Cost = ?(OperatorCost < 0, 0, OperatorCost);
		Sum = Sum + String.CostTotal;
		
	EndDo;
	
	Return Sum;
	
EndFunction

// Parameters:
//   Branch1 - ValueTreeRow:
//    * Indent - Number
//   PositionNumber - Number
//
// Returns:
//   ValueTreeRow
//   Undefined
//
Function FindPositionInBranch(Branch1, PositionNumber)
	
	If Branch1.Indent > PositionNumber Then
		Return FindPositionInBranch(Branch1.Parent, PositionNumber);
	ElsIf Branch1.Indent = PositionNumber Then
		Return Branch1.Parent;
	EndIf;
	
	Return Undefined;
	
EndFunction

Function ConvertToNumber(NumberAsString)
	
	Result = 0;
	NumberAsString = TrimAll(Upper(NumberAsString));
	If StrLen(NumberAsString) > 0 Then
		EPosition  = StrFind(NumberAsString, "E");
		If EPosition = 0 Then 
			Result = Number(NumberAsString);
		Else
			NumberBeforeE = Number(Left(NumberAsString, EPosition - 1));
			NumberAfterE = Number(Mid(NumberAsString, EPosition + 1));
			Result =  NumberBeforeE * Pow(10 ,NumberAfterE);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf
