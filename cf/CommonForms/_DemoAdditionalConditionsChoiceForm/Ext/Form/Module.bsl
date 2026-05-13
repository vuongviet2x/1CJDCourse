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

	Title = Parameters.SelectionFormHeader;
	StructureOfFilledValues = New Structure("NameOfTableToFillIn, NameOfColumnToFillIn", 
													Parameters.NameOfFormElementToFillIn, 
													Parameters.NameOfFormElementDetailsToFillIn);
	
	If Parameters.ExternalConnectionParameters = Undefined Then
		
		If ValueIsFilled(Parameters.ArrayOfSelectedValues_) Then
			ArrayOfPassedValues = Parameters.ArrayOfSelectedValues_;
		Else
			ArrayOfPassedValues = New Array();
		EndIf;
		
		FillInListOfAvailableValues( ArrayOfPassedValues, 
										  Parameters.NameOfSelectionTable,
										  Parameters.FilterCollection);
	
	Else
		
		If Parameters.ExternalConnectionParameters.JoinType = "ExternalConnection" Then
			
			ErrorMessageString = "";
			
			Result = DataExchangeServer.ExternalConnectionToInfobase(Parameters.ExternalConnectionParameters);
				
			ExternalConnection = Result.Join;
			
			If ExternalConnection = Undefined Then
				Common.MessageToUser(Result.DetailedErrorDetails,,,, Cancel);
				Return;
			EndIf;
			
			MetadataObjectProperties = 
				ExternalConnection.DataExchangeExternalConnection.MetadataObjectProperties(Parameters.NameOfSelectionTable);
			
			If ValueIsFilled(Parameters.ArrayOfSelectedValues_) Then
				ArrayOfPassedValues = Parameters.ArrayOfSelectedValues_;
			Else
				ArrayOfPassedValues = New Array();
			EndIf;
			
			If Parameters.ExternalConnectionParameters.CorrespondentVersion_2_1_1_7
				Or Parameters.ExternalConnectionParameters.CorrespondentVersion_2_0_1_6 Then
				
				ResultingCollectionOfObjects = 
				ExternalConnection.DataExchangeExternalConnection.GetTableObjects_2_0_1_6(Parameters.NameOfSelectionTable);
				
				CorrespondentInfobaseTable = Common.ValueFromXMLString(ResultingCollectionOfObjects);
				
			Else
				
				ResultingCollectionOfObjects = 
				ExternalConnection.DataExchangeExternalConnection.GetTableObjects(Parameters.NameOfSelectionTable);
				
				CorrespondentInfobaseTable = ValueFromStringInternal( ResultingCollectionOfObjects);
				
			EndIf;
			
			FillInListOfAvailableValuesExternalConnection( ListOfSelectedValues, 
			ArrayOfPassedValues, 
			CorrespondentInfobaseTable);
			
			If ValueIsFilled(Parameters.FilterCollection) Then
				
				CheckFilterPassageExternalConnection(Parameters.FilterCollection);
				
			EndIf;
			
		ElsIf Parameters.ExternalConnectionParameters.JoinType = "WebService" Then
			
			ErrorMessageString = "";
			
			If Parameters.ExternalConnectionParameters.CorrespondentVersion_2_1_1_7 Then
				
				WSProxy = DataExchangeServer.GetWSProxy_2_1_1_7(Parameters.ExternalConnectionParameters, ErrorMessageString);
				
			ElsIf Parameters.ExternalConnectionParameters.CorrespondentVersion_2_0_1_6 Then
				
				WSProxy = DataExchangeServer.GetWSProxy_2_0_1_6(Parameters.ExternalConnectionParameters, ErrorMessageString);
				
			Else
				
				WSProxy = DataExchangeServer.GetWSProxy(Parameters.ExternalConnectionParameters, ErrorMessageString);
				
			EndIf;
			
			If WSProxy = Undefined Then
				Common.MessageToUser(ErrorMessageString,,,, Cancel);
				Return;
			EndIf;
			
			If Parameters.ExternalConnectionParameters.CorrespondentVersion_2_1_1_7
				Or Parameters.ExternalConnectionParameters.CorrespondentVersion_2_0_1_6 Then
				
				CorrespondentInfobaseData = XDTOSerializer.ReadXDTO(WSProxy.GetIBData(Parameters.NameOfSelectionTable));
				
				MetadataObjectProperties = CorrespondentInfobaseData.MetadataObjectProperties;
				CorrespondentInfobaseTable = Common.ValueFromXMLString(CorrespondentInfobaseData.CorrespondentInfobaseTable);
				
			Else
				
				CorrespondentInfobaseData = ValueFromStringInternal(WSProxy.GetIBData(Parameters.CorrespondentInfobaseTableFullName));
				
				MetadataObjectProperties = ValueFromStringInternal(CorrespondentInfobaseData.MetadataObjectProperties);
				CorrespondentInfobaseTable = ValueFromStringInternal(CorrespondentInfobaseData.CorrespondentInfobaseTable);
				
			EndIf;
			
			If ValueIsFilled(Parameters.ArrayOfSelectedValues_) Then
				ArrayOfPassedValues = Parameters.ArrayOfSelectedValues_;
			Else
				ArrayOfPassedValues = New Array();
			EndIf;
			
			InitializeRefID(CorrespondentInfobaseTable);
			
			FillInListOfAvailableValuesExternalConnection( ListOfSelectedValues, 
			ArrayOfPassedValues, 
			CorrespondentInfobaseTable);
			
			If ValueIsFilled(Parameters.FilterCollection) Then
				
				CheckFilterPassageExternalConnection(Parameters.FilterCollection);
				
			EndIf;
			
			
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteClose(Command)
	
	FormClosingParameters = New Structure();
	FormClosingParameters.Insert("AddressOfTableInTemporaryStorage", CreateTableOfSelectedValues());
	FormClosingParameters.Insert("NameOfTableToFillIn",          StructureOfFilledValues.NameOfTableToFillIn);
	FormClosingParameters.Insert("NameOfColumnToFillIn",          StructureOfFilledValues.NameOfColumnToFillIn);
	
	NotifyChoice(FormClosingParameters);
	
EndProcedure

&AtClient
Procedure ClearMark1(Command)
	
	FillInMarks(False);
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	
	FillInMarks(True);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure FillInListOfAvailableValues( ArrayOfPassedValues, 
											CatalogView,
											AdditionalConditions = Undefined)
	
	Query = New Query("SELECT ALLOWED
	                      |	CatalogForSelectingSelections.Ref AS Presentation,
	                      |	CASE
	                      |		WHEN CatalogForSelectingSelections.Ref IN (&ArrayOfPassedValues)
	                      |			THEN TRUE
	                      |		ELSE FALSE
	                      |	END AS Check
	                      |FROM
	                      |	&MetadataTableName AS CatalogForSelectingSelections
	                      |WHERE
	                      |	CatalogForSelectingSelections.DeletionMark = FALSE");
	
	If ValueIsFilled(AdditionalConditions) Then
		
		For Each Filter In AdditionalConditions Do
			
			Query.Text = AddConditionText(Query.Text, " CatalogForSelectingSelections.", "And", Filter);
			Query.SetParameter(Filter.ParameterName, Filter.ParameterValue);
			
		EndDo; 
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&MetadataTableName", CatalogView);
	Query.SetParameter("ArrayOfPassedValues", ArrayOfPassedValues);
	
	ListOfSelectedValues.Load(Query.Execute().Unload());
	
	For Each ListItem In ListOfSelectedValues Do
		
		If TypeOf(ListItem.Presentation) <> Type("String") Then
			ListItem.Id = String(ListItem.Presentation.UUID());
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInListOfAvailableValuesExternalConnection(TableOfCorrespondentDatabaseValues, 
		ArrayOfPassedValues, ValueTree)
	
	For Each TreeRow In ValueTree.Rows Do
		If TreeRow.Rows.Count() > 0 Then
			FillInListOfAvailableValuesExternalConnection(TableOfCorrespondentDatabaseValues, 
				ArrayOfPassedValues, TreeRow);
		Else
			NewRow = TableOfCorrespondentDatabaseValues.Add();
			FillPropertyValues(NewRow, TreeRow);
			If ArrayOfPassedValues.Find(NewRow.Id) <> Undefined Then
				NewRow.Check = True;
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function CreateTableOfSelectedValues()
	
	TableOfSelectedValues = 
		ListOfSelectedValues.Unload(New Structure("Check", True), "Presentation, Id");
	
	Return PutToTempStorage( TableOfSelectedValues, UUID);
		
EndFunction

&AtServer
Procedure FillInMarks(MarkValue)
	
	TableOfFillableValues = ListOfSelectedValues.Unload();
	TableOfFillableValues.FillValues(MarkValue, "Check");
	ListOfSelectedValues.Load(TableOfFillableValues);
	
EndProcedure

&AtServer
Procedure CheckFilterPassageExternalConnection(FilterCollection)
	
	Query = New Query("SELECT
	                      |	ValueTable.Presentation,
	                      |	ValueTable.Check,
	                      |	ValueTable.Key,
	                      |	ValueTable.Id
	                      |INTO ListOfFilteredItems
	                      |FROM
	                      |	&ListOfSelectedValues_ AS ValueTable
	                      |WHERE TRUE // Autocorrect");
	
	Query.Text = StrReplace(Query.Text, " True // Autocorrect", "");
	Query.SetParameter("ListOfSelectedValues_", ListOfSelectedValues.Unload());
	
	For Each Filter In FilterCollection Do
		
		If StrEndsWith(Query.Text, "WHERE") Then
			
			ConditionConnector = "";
			
		Else
			
			ConditionConnector = "And";
			
		EndIf;
		
		Query.Text = AddConditionText(Query.Text, " ValueTable.", ConditionConnector, Filter);
		Query.SetParameter(Filter.ParameterName, Filter.ParameterValue);
		
	EndDo; 
	
	Query.Text = Query.Text + "
	                      |;
	                      |SELECT
	                      |	ListOfFilteredItems.Presentation,
	                      |	ListOfFilteredItems.Check,
	                      |	ListOfFilteredItems.Key,
	                      |	ListOfFilteredItems.Id
	                      |FROM
	                      |	ListOfFilteredItems AS ListOfFilteredItems";
	
	ListOfSelectedValues.Load(Query.Execute().Unload());
	
EndProcedure

// Parameters:
//   QueryText - String - Query text.
//   TableName - String - Data table name.
//   ConditionConnector - String - Filter criteria merge operator.
//   Filter - Structure:
//     * AttributeOfFilter - String - Object attribute name.
//     * Condition - String - Criteria kind.
//
&AtServer
Function AddConditionText(QueryText, TableName, ConditionConnector, Filter)
	
	QueryText = QueryText + Chars.LF + " " + ConditionConnector 
		+ TableName
		+ Filter.AttributeOfFilter
		+ " " + Filter.Condition
		+ ?(Filter.Condition = "In", " (","")
		+ " &"
		+ Filter.ParameterName
		+ ?(Filter.Condition = "In", ") ","");

	Return QueryText;
	
EndFunction

&AtServer
Procedure InitializeRefID(CorrespondentInfobaseTable)
	
	For Each TreeRow In CorrespondentInfobaseTable.Rows Do
		If TreeRow.Rows.Count() > 0 Then
			InitializeRefID(TreeRow);
		Else
			TreeRow.Id = LinkID(TreeRow.Id);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function LinkID(Val LineEXT)
	
	UIDString = Mid(LineEXT, 1 + StrFind(LineEXT, ":"), 32);
	
	Id =
		Mid(UIDString, 25, 8) 
		+ "-" + Mid(UIDString, 21, 4) 
		+ "-" + Mid(UIDString, 17, 4) 
		+ "-" + Mid(UIDString, 1, 4)
		+ "-" + Mid(UIDString, 5, 12);
	
	Return Id;
	
EndFunction

#EndRegion

#EndRegion