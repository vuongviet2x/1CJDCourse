#Region Internal

// Cursor queries for independent record sets

// Get a data chunk from an independent record set.
// 
// Parameters: 
//  ObjectMetadata - MetadataObject
//  Filter - Array of Structure:
//  * ComparisonType - ComparisonType
//  * Field - String
//  * Value - Arbitrary
//  PortionSize - Number
//  YouCanContinue - Boolean
//  State - See InitializeStateForFetchingPortionsOfIndependentRecordset
//  AdditionToTableName - String
// 
// Returns: 
//  Array of ValueTable:
//   * Column - Arbitrary - Arbitrary list of columns (object fields).
//
Function GetChunkOfDataFromIndependentRecordset(Val ObjectMetadata, Val Filter,
		Val PortionSize, YouCanContinue, State, Val AdditionToTableName = "") Export
	
	If State = Undefined Then
		State = InitializeStateForFetchingPortionsOfIndependentRecordset(ObjectMetadata, Filter, 
			AdditionToTableName);
		YouCanContinue = True;
	EndIf;
	
	Result = New Array;
	
	ItRemainsToGet = PortionSize; // Remains to receive in this chunk.
	
	FirstSelection = False;
	
	CurrentQuery = 0; // Current query index.
	
	While True Do // Get chunk fragments.
		PortionFragment = Undefined; // Last chunk fragment received.
		
		If Not State.ThereWasSelection Then // First query.
			State.ThereWasSelection = True;
			FirstSelection = True;
			
			Query = New Query;
			Query.Text = StrReplace(State.Queries.First, "999", Format(ItRemainsToGet, "NG="));
		Else
			Query = New Query;
			If State.Queries.Subsequent.Count() <> 0 Then 
				QueryDetails = State.Queries.Subsequent[CurrentQuery];
				CurrentQuery = CurrentQuery + 1;
				Query.Text = StrReplace(QueryDetails.Text, "999", Format(ItRemainsToGet, "NG="));
				If QueryDetails.ConditionFields <> Undefined Then 
					For Each ConditionField In QueryDetails.ConditionFields Do
						Query.SetParameter(ConditionField, State.Key[ConditionField]);
					EndDo;
				EndIf;
			EndIf;
		EndIf;
		
		For Each FilterParameter In State.Queries.Parameters Do
			Query.SetParameter(FilterParameter.Key, FilterParameter.Value);
		EndDo;
		
		If Not IsBlankString(Query.Text) Then 
			PortionFragment = Query.Execute().Unload();
			
			FragmentSize = PortionFragment.Count();
		Else
			FragmentSize = 0;
		EndIf;
		
		If FragmentSize > 0 Then
			Result.Add(PortionFragment);
			
			FillPropertyValues(State.Key, PortionFragment[FragmentSize - 1]);
		EndIf;
		
		If FragmentSize < ItRemainsToGet Then
			
			If Not FirstSelection // If it is the first query, there is no need to continue
				And CurrentQuery < State.Queries.Subsequent.Count() Then
				
				ItRemainsToGet = ItRemainsToGet - FragmentSize;
				
				Continue; // Navigating to the next query
			Else
				YouCanContinue = False;
			EndIf;
		EndIf;
		
		Break;
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// Cursor queries for independent record sets

// Parameters:
// 	ObjectMetadata - MetadataObjectInformationRegister, MetadataObjectSequence - Dataset object.
// 	Filter - Array - filter criteria.
// 	AdditionToTableName - String - addition.
// Returns:
// 	Structure:
// * ThereWasSelection - Boolean
// * Key - Structure - structure used to store the latest key value.
// * Queries - FixedStructure - Query details:
//		** First - String - Query that gets the first chunk.
//		** Subsequent - FixedArray - Queries that get follow-up chunks.
//		** Parameters - Structure - filter parameters.
Function InitializeStateForFetchingPortionsOfIndependentRecordset(Val ObjectMetadata, Val Filter, 
	Val AdditionToTableName = "")
	
	IsInformationRegister    = Metadata.InformationRegisters.Contains(ObjectMetadata);
	
	IsSequence = Metadata.Sequences.Contains(ObjectMetadata);
	
	KeyFields = New Array; // Fields that form the record key.
	
	If IsInformationRegister And ObjectMetadata.InformationRegisterPeriodicity 
		<> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
		
		KeyFields.Add("Period");
	EndIf;
	
	If IsSequence Then 
		
		KeyFields.Add("Recorder");
		KeyFields.Add("Period");
		
	EndIf;
	
	AddDelimitersToKey(ObjectMetadata, KeyFields);
	
	For Each MetadataDimensions In ObjectMetadata.Dimensions Do
		KeyFields.Add(MetadataObjectName(MetadataDimensions));
	EndDo;
	
	SelectionFields1 = New Array; // All fields.
	
	If IsInformationRegister Then 
		
		For Each ResourceMetadata In ObjectMetadata.Resources Do
			SelectionFields1.Add(MetadataObjectName(ResourceMetadata));
		EndDo;
		
		For Each AttributeMetadata In ObjectMetadata.Attributes Do
			SelectionFields1.Add(MetadataObjectName(AttributeMetadata));
		EndDo;
		
	EndIf;
	
	For Each KeyField In KeyFields Do
		SelectionFields1.Add(KeyField);
	EndDo;
	
	TableAlias = "_RecordsetTable"; // Table alias in the query text.
	
	SelectionFieldString_ = ""; // Part of the query text with dataset fields.
	For Each SelectionField In SelectionFields1 Do
		If Not IsBlankString(SelectionFieldString_) Then
			SelectionFieldString_ = SelectionFieldString_ + "," + Chars.LF;
		EndIf;
		
		SelectionFieldString_ = SelectionFieldString_ + Chars.Tab + TableAlias + "." + SelectionField + " AS " + SelectionField;
	EndDo;
	
	StringOfOrderingFields = ""; //Part of the query text with ordering fields.
	For Each KeyField In KeyFields Do
		If Not IsBlankString(StringOfOrderingFields) Then
			StringOfOrderingFields = StringOfOrderingFields + ", ";
		EndIf;
		StringOfOrderingFields = StringOfOrderingFields + KeyField;
	EndDo;
	
	If TypeOf(Filter) = Type("Array") Then
		Filter = CreateSelectionCondition(TableAlias, Filter);
	EndIf;
	
	// Prepare queries to get data chunks.
	If KeyFields.Count() = 0 Then 
		QueryTemplate = // 
		"SELECT
		|&SelectionFieldString_
		|FROM
		|	&Table
		|WHERE &Condition";
	Else
		// Chunk size is set in the GetDataBatchFromIndependentRecordSet method.
		QueryTemplate = // 
		"SELECT TOP 999
		|&SelectionFieldString_
		|FROM
		|	&Table
		|WHERE &Condition
		|ORDER BY
		|	&StringOfOrderingFields";
	EndIf;
	QueryTemplate = StrReplace(QueryTemplate, "&SelectionFieldString_", SelectionFieldString_);
	QueryTemplate = StrReplace(QueryTemplate, "&Table", 
		ObjectMetadata.FullName() + AdditionToTableName + " AS " + TableAlias);
	QueryTemplate = StrReplace(QueryTemplate, "&StringOfOrderingFields", StringOfOrderingFields);
	
	// Query to get the first data chunk.
	If Not IsBlankString(Filter.FilterCriterion) Then
		RequestTextForFirstPortion = StrReplace(QueryTemplate, "&Condition", Filter.FilterCriterion);
	Else
		RequestTextForFirstPortion = StrReplace(QueryTemplate, "WHERE &Condition", "");
	EndIf;
	
	Queries = New Array; // Queries for subsequent chunks.
	For RequestCounter_ = 0 To KeyFields.UBound() Do
		
		ConditionFieldString = ""; // Part of the query text with condition fields.
		ConditionFields = New Array; // Part of the query text with condition fields.
		
		NumberOfConditionFields = KeyFields.Count() - RequestCounter_;
		For FieldIndex = 0 To NumberOfConditionFields - 1 Do
			If Not IsBlankString(ConditionFieldString) Then
				ConditionFieldString = ConditionFieldString + " And ";
			EndIf;
			
			KeyField = KeyFields[FieldIndex];
			
			If FieldIndex = NumberOfConditionFields - 1 Then
				LogicalOperator = ">";
			Else
				LogicalOperator = "=";
			EndIf;
			
			ConditionFieldString = ConditionFieldString + TableAlias + "." + KeyField + " " 
				+ LogicalOperator + " &" + KeyField;
				
			ConditionFields.Add(KeyField);
		EndDo;
		
		If Not IsBlankString(Filter.FilterCriterion) Then
			ConditionFieldString = Filter.FilterCriterion + " And " + ConditionFieldString;
		EndIf;
		
		QueryDetails = New Structure("Text, ConditionFields");
		QueryDetails.Text = StrReplace(QueryTemplate, "&Condition", ConditionFieldString);
		QueryDetails.ConditionFields = New FixedArray(ConditionFields);
		
		Queries.Add(New FixedStructure(QueryDetails));
		
	EndDo;
	
	QueryDescriptions = New Structure;
	QueryDescriptions.Insert("First", RequestTextForFirstPortion);
	QueryDescriptions.Insert("Subsequent", New FixedArray(Queries));
	QueryDescriptions.Insert("Parameters", Filter.FilterParameters);
	
	KeyStructure1 = New Structure; // Structure used to store the latest key value.
	For Each KeyField In KeyFields Do
		KeyStructure1.Insert(KeyField);
	EndDo;
	
	State = New Structure;
	State.Insert("Queries", New FixedStructure(QueryDescriptions));
	State.Insert("Key", KeyStructure1);
	State.Insert("ThereWasSelection", False);
	
	Return State;
	
EndFunction

Procedure AddDelimitersToKey(Val ObjectMetadata, KeyFields)
	
	For Each CommonAttribute In Metadata.CommonAttributes Do 

		If Not CommonAttribute.SeparatedDataUse = 
			Metadata.ObjectProperties.CommonAttributeSeparatedDataUse.IndependentlyAndSimultaneously Then 
			Continue;
		EndIf;
		
		CommonPropsElement = CommonAttribute.Content.Find(ObjectMetadata);
		If CommonPropsElement <> Undefined Then
			
			If ElementIsUsedInSeparator(CommonAttribute, CommonPropsElement) Then  
				KeyFields.Add(CommonAttribute.Name);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function ElementIsUsedInSeparator(CommonAttribute, CommonPropsElement)
	
	CommonAttributeAutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse;
	CommonAttributeUse     = Metadata.ObjectProperties.CommonAttributeUse;
	
	If CommonAttribute.AutoUse = CommonAttributeAutoUse.Use Then 
		If CommonPropsElement.Use = CommonAttributeUse.Auto
			Or CommonPropsElement.Use = CommonAttributeUse.Use Then 
				Return True;
		Else
				Return False;
		EndIf;
	Else
		If CommonPropsElement.Use = CommonAttributeUse.Auto
			Or CommonPropsElement.Use = CommonAttributeUse.DontUse Then 
				Return False;
		Else
				Return True;
		EndIf;
	EndIf;
	
EndFunction

Function CreateSelectionCondition(Val TableAlias, Val Filter)
	
	FIlterRow = ""; // Part of the query text with the condition formed by the filter.
	FilterParameters = New Structure;
	If Filter.Count() > 0 Then
		For Each FilterDetails In Filter Do
			If Not IsBlankString(FIlterRow) Then
				FIlterRow = FIlterRow + " And ";
			EndIf;
			
			ParameterName = "P" + Format(FilterParameters.Count(), "NZ=0; NG=");
			FilterParameters.Insert(ParameterName, FilterDetails.Value);
			
			Operand = "&" + ParameterName;
			
			If FilterDetails.ComparisonType = ComparisonType.Equal Then
				LogicalOperator = "=";
			ElsIf FilterDetails.ComparisonType = ComparisonType.NotEqual Then
				LogicalOperator = "<>";
			ElsIf FilterDetails.ComparisonType = ComparisonType.InList Then
				LogicalOperator = "In";
				Operand = "(" + Operand + ")";
			ElsIf FilterDetails.ComparisonType = ComparisonType.NotInList Then
				LogicalOperator = "NOT IN";
				Operand = "(" + Operand + ")";
			ElsIf FilterDetails.ComparisonType = ComparisonType.Greater Then
				LogicalOperator = ">";
			ElsIf FilterDetails.ComparisonType = ComparisonType.GreaterOrEqual Then
				LogicalOperator = ">=";
			ElsIf FilterDetails.ComparisonType = ComparisonType.Less Then
				LogicalOperator = "<";
			ElsIf FilterDetails.ComparisonType = ComparisonType.LessOrEqual Then
				LogicalOperator = "<=";
			Else
				MessageTemplate = NStr("ru = 'Вид сравнения %1 не поддерживается.';
										|en = 'Comparison type %1 is not supported.';");
				MessageText = StrTemplate(MessageTemplate, FilterDetails.ComparisonType);
				Raise MessageText;
			EndIf;
			
			FIlterRow = FIlterRow + TableAlias + "." + FilterDetails.Field + " " + LogicalOperator + " " + Operand;
		EndDo;
	EndIf;
	
	Return New Structure("FilterCriterion, FilterParameters", FIlterRow, FilterParameters);
	
EndFunction

// Returns the name of the given metadata object.
// 
// Parameters:
// 	MetadataObject - MetadataObject - Metadata object.
// Returns:
// 	String - metadata object name.
Function MetadataObjectName(MetadataObject)
	
	Return MetadataObject.Name;
	
EndFunction

#EndRegion

