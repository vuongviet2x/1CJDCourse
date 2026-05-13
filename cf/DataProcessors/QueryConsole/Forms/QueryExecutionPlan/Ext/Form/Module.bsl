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
	
	If Not Parameters.Property("QueryPlanStorageAddress", QueryPlanStorageAddress) Then
		Return;
	EndIf;
	
	QueryMark = Parameters.QueryMark;
	
	If Not ValueIsFilled(QueryMark) Then
		If Not Parameters.QueryAnalysisPerformed Then
			Cancel = True;
			Return;
		EndIf;
	EndIf;
	
	Title = NStr("ru = 'План выполнения запроса (';
					|en = 'Query plan (';") + Parameters.QueryName1 + ")";
	
	FullLogFileName = TechnologicalLogFile(Parameters.OSProcessID, Parameters.LogFilesDirectory);
	If Not DataFromTechnologicalLogRead(FullLogFileName) Then
		Items.QueryExecutionPlanGroup.CurrentPage = Items.GetQueryExecutionPlanGroup;
		NeedToReadLogName = FullLogFileName;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure QueryShowTypeOnChange(Item)
	
	If DataDisplayType = 0 Then
		If DBMSType = "DBMSSQL" Then
			Items.OperatorTreeMetadata.Visible=True;
			Items.OperatorTree.Visible=False;
		Else
			QueryExecutionPlanText = QueryExecutionPlanInMetadata;
		EndIf;	
		GeneratedSQLQueryText = QueryTextAsMetadata;
	Else 
		If DBMSType = "DBMSSQL" Then 
			Items.OperatorTreeMetadata.Visible=False;
			Items.OperatorTree.Visible=True;
		Else
			QueryExecutionPlanText = QueryExecutionPlanFromTechLog;
		EndIf;
		
		GeneratedSQLQueryText = QueryTextInSQL;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region SQLServerQueryExecutionPlanFormTableItemsEventHandlers

&AtClient
Procedure TreeOnActivateRow(Item)
	
	If DBMSType = "DBMSSQL" Then
		If DataDisplayType = 0 Then
			OperatorDetails = Item.CurrentData.OperatorMetadata;
		Else
			OperatorDetails = Item.CurrentData.Operator;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function DataProcessorObject2()
	
	Return FormAttributeToValue("Object");
	
EndFunction

&AtServer
Function TechnologicalLogFile(OSProcessID, LogFilesDirectory)
	
	CurrentDate = CurrentDate(); // ACC:143 - Technological log filenames are generated using the server date.
	ExpectedFileName = NameTechnologicalLogFile(CurrentDate);
	
	FullLogFileName = FindTechnologicalLogFile(ExpectedFileName, OSProcessID, LogFilesDirectory); 
	If ValueIsFilled(FullLogFileName) Then
		Return FullLogFileName;
	Else
		ExpectedFileName = NameTechnologicalLogFile(CurrentDate - 3600);
		FullLogFileName =  FindTechnologicalLogFile(ExpectedFileName, OSProcessID, LogFilesDirectory);
		If ValueIsFilled(FullLogFileName) Then
			Return FullLogFileName;
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtServer
Function NameTechnologicalLogFile(FileDate)
	
	ExpectedFileName = Format(FileDate, "DF=yyMMddHH")+ ".log";
	Return ExpectedFileName;
	
EndFunction

&AtServer
Function FindTechnologicalLogFile(FileName, OSProcessID, LogFilesDirectory)

	ListOfFiles = FindFiles(LogFilesDirectory, "*.log", True);
	For Each File In ListOfFiles Do
		If StrFind(File.Path, "_" + OSProcessID) > 0 Then
			If File.Name = FileName Then
				Return File.FullName;
			EndIf;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtServer
Function DataFromTechnologicalLogRead(FullLogFileName)
	
	If ValueIsFilled(QueryPlanStorageAddress) Then
		
		QueryPlanStructure = GetFromTempStorage(QueryPlanStorageAddress);
		
		If QueryPlanStructure <> Undefined Then
			DBMSType = QueryPlanStructure.DBMSType;
			QueryTextInSQL = QueryPlanStructure.SQLQuery;
			QueryExecutionPlanFromTechLog = QueryPlanStructure.QueryExecutionPlan;
		Else
			ReadData1 = New Structure("DBMSType, SQLQuery, QueryExecutionPlan");
			DataProcessorObject2().ReadTechnologicalLog(FullLogFileName, QueryMark, ReadData1);
			
			DBMSType = ReadData1.DBMSType;
			QueryTextInSQL = ReadData1.SQLQuery;
			QueryExecutionPlanFromTechLog = ReadData1.QueryExecutionPlan;
			
			QueryPlanStructure = New Structure;
			QueryPlanStructure.Insert("DBMSType", DBMSType);
			QueryPlanStructure.Insert("SQLQuery", QueryTextInSQL);
			QueryPlanStructure.Insert("QueryExecutionPlan", QueryExecutionPlanFromTechLog);
			QueryPlanStructure.Insert("QueryPlanUpToDate", True);
			
			QueryPlanStorageAddress = PutToTempStorage(QueryPlanStructure,QueryPlanStorageAddress);
		EndIf;
	Else
		ReadData1 = New Structure("DBMSType, SQLQuery, QueryExecutionPlan");
		DataProcessorObject2().ReadTechnologicalLog(FullLogFileName, QueryMark, ReadData1);
		
		DBMSType = ReadData1.DBMSType;
		QueryTextInSQL = ReadData1.SQLQuery;
		QueryExecutionPlanFromTechLog = ReadData1.QueryExecutionPlan;
	EndIf;
	
	If Not ValueIsFilled(DBMSType) Then
		Return False;
	EndIf;
	
	AsMetadata = DataProcessorObject2().TransformToMetadata(QueryTextInSQL, QueryExecutionPlanFromTechLog, DBMSType);
	
	QueryTextAsMetadata = AsMetadata.QueryTextAsMetadata;
	QueryExecutionPlanInMetadata = AsMetadata.QueryExecutionPlanInMetadata;
	
	GeneratedSQLQueryText = AsMetadata.QueryTextAsMetadata;
	QueryExecutionPlanText = AsMetadata.QueryExecutionPlanInMetadata;
	
	If DBMSType = "DBMSSQL" Then
		TotalCostTotal = 0;
		Items.QueryExecutionPlanGroup.CurrentPage = Items.QueryExecutionPlanGroupSQLServer;
		QueryPlanTree = FormAttributeToValue("QueryExecutionPlanTree"); // ValueTree
		DataProcessorObject2().QueryExecutionPlanTree(QueryExecutionPlanFromTechLog, QueryExecutionPlanInMetadata, QueryPlanTree, TotalCostTotal);
		ValueToFormAttribute(QueryPlanTree, "QueryExecutionPlanTree");
		TotalQueryCost = TotalCostTotal;
		Items.QueryCostInformationGroup.Visible = True;
		Items.ShowQueryExecutionPlanAs.Visible = True;
		Maximum = FindMaxCostIndicator(QueryPlanTree.Rows);
		SetDataAppearanceInCostColumn(Maximum);
	Else
		Items.QueryCostInformationGroup.Visible = False;
		Items.QueryExecutionPlanGroup.CurrentPage = Items.QueryExecutionPlanTextPresentationGroup;
		Items.ShowQueryExecutionPlanAs.Visible = False;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Procedure SetDataAppearanceInCostColumn(Maximum)
	
	ConditionalAppearance.Items.Clear();
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	AppearanceField = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("CostTree");
	AppearanceField.Use = True;
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("QueryExecutionPlanTree.Cost"); 
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal; 
	FilterElement.RightValue = Maximum; 
	FilterElement.Use = True;
	ConditionalAppearanceItem.Appearance.SetParameterValue("Font", New Font(, , True));
	
EndProcedure

&AtServer
Function FindMaxCostIndicator(TreeRows, Maximum = 0)
	
	For Each TreeRow In TreeRows Do
		If TreeRow.Rows.Count() > 0 Then
			Maximum = FindMaxCostIndicator(TreeRow.Rows, Maximum);
		EndIf;
		If TreeRow.Cost > Maximum Then
			Maximum = TreeRow.Cost;
		EndIf;
	EndDo;
	
	Return Maximum;
	
EndFunction

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(NeedToReadLogName) Then
		AttachIdleHandler("ReadDataFromTechnologicalLogHandler", 2);
		Items.GetQueryExecutionPlanGroup.Visible = True;
		AttemptsNumber = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReadDataFromTechnologicalLogHandler()
	
	If DataFromTechnologicalLogRead(NeedToReadLogName) Then
		DetachIdleHandler("ReadDataFromTechnologicalLogHandler");
		NeedToReadLogName = Undefined;
		Items.GetQueryExecutionPlanGroup.Visible = False;
	Else
		If AttemptsNumber < 5 Then
			AttemptsNumber = AttemptsNumber + 1;
		Else
			DetachIdleHandler("ReadDataFromTechnologicalLogHandler");
			NeedToReadLogName = Undefined;
			Items.GetQueryExecutionPlanGroup.Visible = False;
			NotificationParameters = New Structure;
			NotificationParameters.Insert("QueryMark", QueryMark);
			Notify("GetQueryExecutionPlanError", NotificationParameters, ThisObject);
			ShowMessageBox(, NStr("ru = 'План выполнения запроса не был получен.';
											|en = 'A query plan is not received.';"));
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowQueryExecutionPlanAsOnChange(Item)
	
	If ShowQueryExecutionPlanAs = 0 Then
		Items.QueryExecutionPlanGroup.CurrentPage = Items.QueryExecutionPlanGroupSQLServer;
	Else
		Items.QueryExecutionPlanGroup.CurrentPage = Items.QueryExecutionPlanTextPresentationGroup;
	EndIf;

EndProcedure

#EndRegion


