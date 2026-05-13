///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure QueryOptionsIsExpressionOnChange(Item)
	
	CurrentData = Items.QueryOptions.CurrentData;
	
	If CurrentData.IsExpression And Not TypeOf(CurrentData.ParameterValue) = Type("String") Then
		CurrentData.ParameterValue = "";
	EndIf;
	
	ChangeTypeSelection();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteQuery(Command)
	
	QueryText = DocumentQueryText.GetText();
	
	If IsBlankString(QueryText) Then
		
		MessageToUser(NStr("ru = 'Не задан текст запроса';
									|en = 'Query text is not specified';"), "QueryText");
		Return;
		
	EndIf;
	
	ExecuteQueryAtServer(QueryText);
	
EndProcedure

&AtClient
Procedure FillParameters_(Command)
	FillParametersAtServer();
EndProcedure

&AtClient
Procedure AddToExportResult(Command)
	
	If Items.Find("QueryResult") = Undefined Then
		
	Else
		
		NotifyChoice(ThisObject.QueryResult);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ExecuteQueryAtServer(QueryText)
	
	Query = New Query;
	
	For Each ParametersString1 In QueryOptions Do
		If ParametersString1.IsExpression Then
			Query.SetParameter(ParametersString1.ParameterName, EvalExpression(ParametersString1.ParameterValue));
		Else
			Query.SetParameter(ParametersString1.ParameterName, ParametersString1.ParameterValue);
		EndIf;
	EndDo;
	
	Query.Text = QueryText;
	Result = Query.Execute();
	ResultTable2 = Result.Unload();
	
	DeleteFormItems();
	AddFormItems(ResultTable2);
	
EndProcedure

&AtServer
Function EvalExpression(Val Expression)
	
	SetSafeMode(True);
	
	For Each CommonAttribute In Metadata.CommonAttributes Do
		If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
			SetDataSeparationSafeMode(CommonAttribute.Name, True);
		EndIf;
	EndDo;
	
	// Don't call CalculateInSafeMode because the safe mode is set without using SSL.
	Return Eval(Expression);
	
EndFunction

&AtServer
Procedure AddFormItems(ResultTable2)
	
	AttributeName = "QueryResult";
	
	AttributesArray = New Array;
	AttributesArray.Add(New FormAttribute(AttributeName, New TypeDescription("ValueTable")));
	
	For Each Column In ResultTable2.Columns Do
		AttributesArray.Add(New FormAttribute(Column.Name, Column.ValueType, AttributeName));
	EndDo;
	
	ChangeAttributes(AttributesArray);
	
	FormTable = Items.Add(AttributeName, Type("FormTable"), Items.GroupQueryResult);
	FormTable.DataPath = AttributeName;
	FormTable.CommandBarLocation = FormItemCommandBarLabelLocation.None;
	FormTable.VerticalStretch = False;
	
	For Each Column In ResultTable2.Columns Do
		NewItem = Items.Add("Column_" + Column.Name, Type("FormField"), FormTable);
		NewItem.Type = FormFieldType.InputField;
		NewItem.DataPath = AttributeName + "." + Column.Name;
	EndDo; 
	
	ValueToFormAttribute(ResultTable2, AttributeName);
	
	Items.QueryResultGroup.CurrentPage = Items.QueryResultGroup.ChildItems.GroupQueryResult;
	
EndProcedure

&AtServer
Procedure DeleteFormItems()
	
	AttributeName = "QueryResult";
	
	If Items.Find(AttributeName) <> Undefined Then
		
		AttributesArray = New Array;
		AttributesArray.Add(AttributeName);
		
		ChangeAttributes(, AttributesArray);
		
		Items.Delete(Items[AttributeName]);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure MessageToUser(Text, DataPath = "")
	
	Message = New UserMessage;
	Message.Text = Text;
	Message.DataPath = DataPath;
	Message.Message();
	
EndProcedure

&AtServer
Procedure FillParametersAtServer()
	
	Query = New Query;
	Query.Text = DocumentQueryText.GetText();
	
	ParametersDetails = Query.FindParameters();
	
	For Each Parameter In ParametersDetails Do
		ParameterName =  Parameter.Name;
		FilterParameters = New Structure;
		FilterParameters.Insert("ParameterName", ParameterName);
		RowsArray = QueryOptions.FindRows(FilterParameters);
		
		If RowsArray.Count() = 1 Then
			
			ParametersString1 = RowsArray[0];
			
		Else
			
			ParametersString1 = QueryOptions.Add();
			ParametersString1.ParameterName = ParameterName;
			
		EndIf;
		
		ParametersString1.ParameterValue = Parameter.ValueType.AdjustValue(ParametersString1.ParameterValue);
		ParametersString1.ParameterType = Parameter.ValueType;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ChangeTypeSelection()
	
	CurrentData = Items.QueryOptions.CurrentData;
	QueryParameter = Items.QueryOptions.ChildItems.QueryOptionsParameterValue;
	
	QueryParameter.TypeRestriction = ?(CurrentData.IsExpression, New TypeDescription, CurrentData.ParameterType);
	QueryParameter.ChooseType = Not CurrentData.IsExpression;
	
EndProcedure

#EndRegion
