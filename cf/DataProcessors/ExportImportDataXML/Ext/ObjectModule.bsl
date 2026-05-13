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

Var MetadataDescription_SSLy Export;
Var ReferenceTypes Export;
Var MetadataObjectsAndRefTypesMap;
Var ConstantsProcessed Export;
Var RecordSetsProcessed Export;
Var mRegisteredRecordsColumnsMap;

// 
Var FullExportComposition Export;
// 
Var AuxiliaryExportComposition;

// 
Var RegistersUsingTotals;

Var mQueryResultType; 
Var mDeletionDataType;

Var mExportedObjects;
Var mLastSavedDataExportedCount;

Var mSubordinateObjectsExportExists;
Var PredefinedDataTable;
Var MatchingReplacementLinks;
Var Serializer;

Var ConfigurationSeparators; // Array of configuration separators.

#EndRegion

#Region Public

// Runs initial initialization: populates a metadata object class tree, metadata tree, and list of reference types.
// 
//
// Parameters:
//   ExcludedMetadata - Map - Metadata object, which must be excluded from the exported data, is specified as a key. 
//                                        
//
//
Procedure Initialize(ExcludedMetadata = Undefined) Export
	
	AllowResultsUsageEditingRights = False;
	
	// Create an object that describes the processes of creating a tree and an export.
	FillMetadataDetails();
	
	MetadataDescription_SSLy = MetadataDescription_SSLy.Rows[0];
	
	ReferenceTypes = New Map;
	MetadataObjectsAndRefTypesMap = New Map;
	
	MetadataTree.Columns.Clear();
	// Create required columns.
	MetadataTree.Columns.Add("Export", New TypeDescription("Number", New NumberQualifiers(1, 0, AllowedSign.Nonnegative)));
	MetadataTree.Columns.Add("ExportIfNecessary", New TypeDescription("Number", New NumberQualifiers(1, 0, AllowedSign.Nonnegative)));
	MetadataTree.Columns.Add("Metadata");
	MetadataTree.Columns.Add("DescriptionItem");
	MetadataTree.Columns.Add("MetadataObjectsList");
	MetadataTree.Columns.Add("FullMetadataName");
	MetadataTree.Columns.Add("BuilderSettings");
	MetadataTree.Columns.Add("UseFilter1");
	MetadataTree.Columns.Add("PictureIndex");
	MetadataTree.Columns.Add("Expanded");
	
	RegistersUsingTotals = New Array;
	Root = MetadataTree.Rows.Add();
	BuildObjectSubtree(Metadata, Root, MetadataDescription_SSLy);
	CollapsingObjectSubtree(Root);
	
	ProcessTreeRows(MetadataTree.Rows, ExcludedMetadata, 1);
	
	For Each KeyAndValue In ReferenceTypes Do
		MetadataObjectsAndRefTypesMap.Insert(KeyAndValue.Value, KeyAndValue.Key);
	EndDo;
	
EndProcedure	

// Creates an export file with data in an XML format.
//
// Parameters:
//   FileName                           - String - Name of the XML export file.
//   InvalidCharsCheckOnly - Boolean - If True, checks XML only for invalid characters.
//                                                 
//
Procedure ExecuteExport(Val FileName, InvalidCharsCheckOnly = False) Export
	
	ObjectsUnloadedWithErrors = New Map;
	
	ExportComposition();
	
	If FullExportComposition.Count() = 0
		And AdditionalObjectsToExport.Count() = 0 Then
		
		MessageToUser(NStr("ru = 'Не задан состав выгрузки';
									|en = 'Export content is not specified';"));
		Return;
		
	EndIf;
	
	If InvalidCharsCheckOnly Then
		
		XMLWriter = CreateXMLRecordObjectForCheck();
		
		DataExport(XMLWriter, InvalidCharsCheckOnly, ObjectsUnloadedWithErrors);
		
	Else
		
		If UseFastInfoSetFormat Then
			
			XMLWriter = New FastInfosetWriter;
			XMLWriter.OpenFile(FileName);
			
		Else
			
			XMLWriter = New XMLWriter;
			XMLWriter.OpenFile(FileName, "UTF-8");
			
		EndIf;
		
		XMLWriter.WriteXMLDeclaration();
		XMLWriter.WriteStartElement("_1CV8DtUD", "http://www.1c.ru/V8/1CV8DtUD/");
		XMLWriter.WriteNamespaceMapping("V8Exch", "http://www.1c.ru/V8/1CV8DtUD/");
		XMLWriter.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
		XMLWriter.WriteNamespaceMapping("core", "http://v8.1c.ru/data");
		
		XMLWriter.WriteNamespaceMapping("v8", "http://v8.1c.ru/8.1/data/enterprise/current-config");
		XMLWriter.WriteNamespaceMapping("xs", "http://www.w3.org/2001/XMLSchema");
		
		XMLWriter.WriteStartElement("V8Exch:Data");
		
		If InvalidCharsCheckOnly Then
			
			CheckStartTemplate = NStr("ru = 'Начало проверки: %Date%';
										|en = 'Check completed: %Date%.';");
			CheckStartMessage = StrReplace(CheckStartTemplate, "%Date%", CurrentSessionDate());
			MessageToUser(CheckStartMessage);
			
		Else
			
			UploadStartTemplate = NStr("ru = 'Начало выгрузки: %Date%';
										|en = 'Export started: %Date%';");
			ExportStartMessage = StrReplace(UploadStartTemplate, "%Date%", CurrentSessionDate());
			MessageToUser(ExportStartMessage);
			
		EndIf;
		
		InitializeXDTOSerializerWithTypesAnnotation();
		
		DataExport(XMLWriter);
		
		XMLWriter.WriteEndElement(); // V8Exc:Data
		ExportPredefinedItemsTable(XMLWriter);
		XMLWriter.WriteEndElement(); // V8Exc:_1CV8DtUD
		
	EndIf;
	
	If InvalidCharsCheckOnly Then
		
		TemplateChecked = NStr("ru = 'Проверено объектов: %Checked%';
								|en = 'Objects checked: %Checked%';");
		MessageChecked = StrReplace(TemplateChecked, "%Checked%", TotalProcessedRecords());
		MessageToUser(MessageChecked);
		
		TemplateEnd = NStr("ru = 'Окончание проверки: %Date%';
								|en = 'Check completed: %Date%.';");
		MessageEnd = StrReplace(TemplateEnd, "%Date%", CurrentSessionDate());
		MessageToUser(MessageEnd);
		
	Else
		
		TemplateExported = NStr("ru = 'Выгружено объектов: %WasExported%';
								|en = 'Objects exported: %WasExported%';");
		MessageExported = StrReplace(TemplateExported, "%WasExported%", TotalProcessedRecords());
		MessageToUser(MessageExported);
		
		TemplateEnd = NStr("ru = 'Окончание выгрузки: %Date%';
								|en = 'Export completed: %Date%';");
		MessageEnd = StrReplace(TemplateEnd, "%Date%", CurrentSessionDate());
		MessageToUser(MessageEnd);
		
		MessageToUser(NStr("ru = 'Выгрузка данных успешно завершена';
									|en = 'Data export is completed successfully';"));
		
	EndIf;
	
EndProcedure

// Imports XML export files and writes saved objects to the infobase.
//
// Parameters:
//   FileName - String - Name of the XML export file.
//
Procedure ExecuteImport(Val FileName) Export
	
	File = New File(FileName);
	
	TempFileName = "";
	If File.Extension = ".fi" Then
		
		XMLReader = New FastInfosetReader;
		XMLReader.OpenFile(FileName);
		
		XMLWriter = New XMLWriter;
		TempFileName = GetTempFileName("xml");
		XMLWriter.OpenFile(TempFileName, "UTF-8");
		
		While XMLReader.Read() Do
			
			XMLWriter.WriteCurrent(XMLReader);
			
		EndDo;
		
		XMLWriter.Close();
		
		FileName = TempFileName;
		
	EndIf;
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(FileName);
	// Check the exchange file format.
	If Not XMLReader.Read()
		Or XMLReader.NodeType <> XMLNodeType.StartElement
		Or XMLReader.LocalName <> "_1CV8DtUD"
		Or XMLReader.NamespaceURI <> "http://www.1c.ru/V8/1CV8DtUD/" Then
		
		MessageToUser(NStr("ru = 'Неверный формат файла выгрузки';
									|en = 'Incorrect export file format';"));
		If ValueIsFilled(TempFileName) Then
			XMLReader.Close();
			DeleteFiles(TempFileName);
		EndIf;
		Return;
		
	EndIf;
	
	If Not XMLReader.Read()
		Or XMLReader.NodeType <> XMLNodeType.StartElement
		Or XMLReader.LocalName <> "Data" Then
		
		MessageToUser(NStr("ru = 'Неверный формат файла выгрузки';
									|en = 'Incorrect export file format';"));
		If ValueIsFilled(TempFileName) Then
			XMLReader.Close();
			DeleteFiles(TempFileName);
		EndIf;
		Return;
		
	EndIf;
	
	DownloadPredefinedTable(XMLReader);
	
	NameOfTempFileWithReplacedRefs = ReplaceLinksWithPredefinedOnes(FileName);
	
	// Starting this moment, the temporary file is handled. See "NameOfTempFileWithReplacedRefs".
	// The original file (if any) is not needed anymore and should be deleted.
	If ValueIsFilled(TempFileName) Then
		DeleteFiles(TempFileName);
	EndIf;
	
	XMLReader.OpenFile(NameOfTempFileWithReplacedRefs);
	XMLReader.Read();
	XMLReader.Read();
	
	// Read and write objects recorded in infobase export.
	If Not XMLReader.Read() Then 
		
		MessageToUser(NStr("ru = 'Неверный формат файла выгрузки';
									|en = 'Incorrect export file format';"));
		Return;
		
	EndIf;
	
	Imported2 = 0;
	RemoveTotalsUsage();
	
	MessageTemplate = NStr("ru = 'Начало загрузки: %1';
							|en = 'Import started at: %1';");
	MessageText  = SubstituteParametersToString(MessageTemplate, CurrentSessionDate());
	
	MessageToUser(MessageText);
	
	InitializeXDTOSerializerWithTypesAnnotation();
	
	AccessManagementUsed = False;
	If SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement       = CommonModule("AccessManagement");
		AccessManagementUsed = True;
	EndIf;
	
	If AccessManagementUsed Then
		ModuleAccessManagement.DisableAccessKeysUpdate(True, False);
	EndIf;
	
	Try
	
		ExecuteXMLDataImport(Imported2, NameOfTempFileWithReplacedRefs, XMLReader);
		If AccessManagementUsed Then
			ModuleAccessManagement.DisableAccessKeysUpdate(False, False);
		EndIf;
		
	Except
		
		If AccessManagementUsed Then
			ModuleAccessManagement.DisableAccessKeysUpdate(False, False);
		EndIf;
		
		Raise;
	EndTry;
	
	RestoreTotalsUsage();
	
	// Check the exchange file format.
	If XMLReader.NodeType <> XMLNodeType.EndElement
		Or XMLReader.LocalName <> "Data" Then
		
		MessageToUser(NStr("ru = 'Неверный формат файла выгрузки';
									|en = 'Incorrect export file format';"));
		XMLReader.Close();
		DeleteFiles(NameOfTempFileWithReplacedRefs);
		Return;
		
	EndIf;
	
	If Not XMLReader.Read()
		Or XMLReader.NodeType <> XMLNodeType.StartElement
		Or XMLReader.LocalName <> "PredefinedData" Then
		
		MessageToUser(NStr("ru = 'Неверный формат файла выгрузки';
									|en = 'Incorrect export file format';"));
		XMLReader.Close();
		DeleteFiles(NameOfTempFileWithReplacedRefs);
		Return;
		
	EndIf;
	
	XMLReader.Skip();
	
	If Not XMLReader.Read()
		Or XMLReader.NodeType <> XMLNodeType.EndElement
		Or XMLReader.LocalName <> "_1CV8DtUD"
		Or XMLReader.NamespaceURI <> "http://www.1c.ru/V8/1CV8DtUD/" Then
		
		MessageToUser(NStr("ru = 'Неверный формат файла выгрузки';
									|en = 'Incorrect export file format';"));
		XMLReader.Close();
		DeleteFiles(NameOfTempFileWithReplacedRefs);
		Return;
		
	EndIf;
	
	XMLReader.Close();
	DeleteFiles(NameOfTempFileWithReplacedRefs);
	
	TemplateImported1    = NStr("ru = 'Загружено объектов: %1';
								|en = '%1 objects imported';");
	MessageImported = SubstituteParametersToString(TemplateImported1, Imported2);
	
	TemplateEnd    = NStr("ru = 'Окончание загрузки: %1';
								|en = 'Import finished at: %1';");
	MessageEnd = SubstituteParametersToString(TemplateEnd, CurrentSessionDate());
	
	MessageToUser(MessageImported);
	MessageToUser(MessageEnd);
	MessageToUser(NStr("ru = 'Загрузка данных успешно завершена';
								|en = 'Data is imported successfully';"));
	
EndProcedure

// Returns the current version of the data processor.
//
// Returns:
//  String - a data processor version.
//
Function ObjectVersion() Export
	
	Return "2.1.8";
	
EndFunction

#EndRegion

#Region Private

Procedure ExecuteXMLDataImport(Imported2, NameOfTempFileWithReplacedRefs, XMLReader)
	
	Var EventName, ErrorText, MessageText;
	
	While Serializer.CanReadXML(XMLReader) Do
		Recorded_Value = Undefined;
		ValueRead  = True;
		ErrorDescription     = "";
		Try
			Recorded_Value = Serializer.ReadXML(XMLReader); // CatalogObject, DocumentObject, etc.
		Except
			ValueRead = False;
			ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndTry;
		
		If Not ValueRead Then
			RestoreTotalsUsage();
			Try
				XMLReader.Close();
				DeleteFiles(NameOfTempFileWithReplacedRefs);
			Except
				EventName = NStr("ru = 'Обмен данными';
									|en = 'Data exchange';", DefaultLanguageCode());
				
				WriteLogEvent(EventName,
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EndTry;
			ErrorText = NStr("ru = 'Не удалось загрузить данные. 
			|Возможно они были выгружены из другой версии конфигурации.';
			|en = 'Failed to export data.
			|Maybe it was exported from other configuration version.';") +
			Chars.LF + ErrorDescription;
			Raise ErrorText;
		EndIf;
		
		If UseDataExchangeModeOnImport Then
			Recorded_Value.DataExchange.Load = True;
		EndIf;
		
		If Metadata.ExchangePlans.Find(Recorded_Value.Metadata().Name) <> Undefined Then
			If Recorded_Value.ThisNode Then
				Continue;
			EndIf;
		EndIf;
		
		Try
			Recorded_Value.Write();
		Except
			
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			If Not ContinueImportOnError Then
				
				RestoreTotalsUsage();
				XMLReader.Close();
				DeleteFiles(NameOfTempFileWithReplacedRefs);
				Raise;
				
			Else
				
				Try
					MessageText = NStr("ru = 'При загрузке объекта %1(%2) возникла ошибка:
					|%3';
					|en = 'Error occurred while importing object %1(%2):
					|%3';");
					MessageText = SubstituteParametersToString(MessageText,
					Recorded_Value, TypeOf(Recorded_Value), ErrorText);
				Except
					MessageText = NStr("ru = 'При загрузке данных возникла ошибка:
					|%1';
					|en = 'Error occurred while importing data:
					|%1';");
					MessageText = SubstituteParametersToString(MessageText, ErrorText);
				EndTry;
				
				MessageToUser(MessageText);
				
			EndIf;
			
			Imported2 = Imported2 - 1;
			
		EndTry;	
		
		Imported2 = Imported2 + 1;
		
	EndDo;

EndProcedure

Function CreateXMLRecordObjectForCheck()
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString("UTF-16");
	XMLWriter.WriteStartElement("Validation");
	
	Return XMLWriter;
	
EndFunction

// Recursively processes a metadata tree generating lists of full and auxiliary export sets.
//
// Parameters:
//   RecalculateDataToExportByRef - Boolean
//
Procedure ExportComposition(RecalculateDataToExportByRef = False) Export
	
	FullExportComposition = New ValueTable;
	FullExportComposition.Columns.Add("MetadataObjectsList");
	FullExportComposition.Columns.Add("TreeRow");	
	FullExportComposition.Indexes.Add("MetadataObjectsList");
	
	AuxiliaryExportComposition = New ValueTable;
	AuxiliaryExportComposition.Columns.Add("MetadataObjectsList");
	AuxiliaryExportComposition.Columns.Add("TreeRow");	
	AuxiliaryExportComposition.Indexes.Add("MetadataObjectsList");
	
	For Each VTRow In MetadataTree.Rows Do
		AddObjectsToExport(FullExportComposition, AuxiliaryExportComposition, VTRow);
	EndDo;
	
	mSubordinateObjectsExportExists = AuxiliaryExportComposition.Count() > 0;
	
	If RecalculateDataToExportByRef Then
		
		RecalculateDataToExportByRef(FullExportComposition);
		
	EndIf;
	
	AuxiliaryExportComposition.Indexes.Add("MetadataObjectsList");
	FullExportComposition.Indexes.Add("MetadataObjectsList");
	
EndProcedure

// Recursively processes and prepares for export the metadata tree.
//
Procedure ProcessTreeRows(Rows, MetadataExceptionsList, Val ExportNode)
	
	If MetadataExceptionsList = Undefined Then
		Return;
	EndIf;
	If Rows.Count() = 0 Then
		Return;
	EndIf;
	For Each String In Rows Do
		If ExportNode = 0 Then
			String.Export = 0;
			String.ExportIfNecessary = 0;
			ProcessTreeRows(String.Rows, MetadataExceptionsList, 0);
		Else
			Var_Export = ?(MetadataExceptionsList.Get(String.Metadata) = Undefined, 1, 0);
			ProcessTreeRows(String.Rows, MetadataExceptionsList, Var_Export);
			String.Export = Var_Export;
			String.ExportIfNecessary = 0;
		EndIf;
	EndDo;
	
EndProcedure

Procedure ExportRefsArrayMetadata(ReferencesArrray, NameForQueryString, XMLWriter, InvalidCharsCheckOnly = False, ObjectsUnloadedWithErrors = Undefined)
	
	If ReferencesArrray.Count() = 0
		Or Not ValueIsFilled(NameForQueryString) Then
		
		Return;
		
	EndIf;
	
	QueryTextTemplate2 =
	"SELECT ALLOWED
	|	_.*
	|FROM
	|	&MetadataTableName AS _
	|WHERE
	|	_.Ref IN (&ReferencesArrray)";
	
	QueryText = StrReplace(QueryTextTemplate2, "&MetadataTableName", NameForQueryString);
	
	Query = New Query(QueryText);	
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	QueryResult = Query.Execute();
	
	RequestAndRecord(QueryResult, XMLWriter, True, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);
	
EndProcedure

// Returns:
//   ValueTable - Collection of exported objects:
//     * Ref - AnyRef - Reference to the exported object.
// 
Function ExportedObjectsCollection()
	Return mExportedObjects;
EndFunction

// Returns:
//   Array of See RegisterRecord.MetadataTreeRow - Set of registers using totals.
//
Function RegistersWithTotalsCollection()
	Return RegistersUsingTotals;
EndFunction

// The procedure writes register record sets (accumulation registers, accounting registers, and others).
//
// Parameters:
//   XMLWriter - XMLWriter - Intermediary object used to write other infobase objects.
//
Procedure DataExport(XMLWriter, InvalidCharsCheckOnly = False, ObjectsUnloadedWithErrors = Undefined)
	
	mExportedObjects = New ValueTable;
	mExportedObjects.Columns.Add("Ref");
	mExportedObjects.Indexes.Add("Ref");
	
	InitializeTableOfPredefinedItems();
	
	If ObjectsUnloadedWithErrors = Undefined Then
		ObjectsUnloadedWithErrors = New Map;
	EndIf;
	
	For Each ExportTableRow In FullExportComposition Do
		
		MetadataTreeRow = ExportTableRow.TreeRow;
		
		If MetadataTreeRow.DescriptionItem.Manager = Undefined Then
			Raise(NStr("ru = 'Выгрузка данных. Внутренняя ошибка';
									|en = 'Export data. Internal error';"));
		EndIf;
		
		If Metadata.Constants.Contains(MetadataTreeRow.MetadataObjectsList) Then
			
			WritingConstant(XMLWriter, MetadataTreeRow.MetadataObjectsList, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);
			
		ElsIf Metadata.InformationRegisters.Contains(MetadataTreeRow.MetadataObjectsList)
			Or Metadata.AccumulationRegisters.Contains(MetadataTreeRow.MetadataObjectsList)
			Or Metadata.CalculationRegisters.Contains(MetadataTreeRow.MetadataObjectsList) Then
			
			RegisterRecord(XMLWriter, MetadataTreeRow, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);
			
		ElsIf Metadata.AccountingRegisters.Contains(MetadataTreeRow.MetadataObjectsList) Then
			
			RegisterRecord(XMLWriter, MetadataTreeRow, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly, True);
			
		ElsIf TypeOf(MetadataTreeRow.DescriptionItem.Manager) = Type("String") Then
			// Special recalculation case.
			RecalculationRecord(XMLWriter, MetadataTreeRow, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);
			
		ElsIf Metadata.Sequences.Contains(MetadataTreeRow.MetadataObjectsList) Then
			
			SequenceWriter(XMLWriter, MetadataTreeRow, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);
			
		Else
			
			WritingObjectTypeData(MetadataTreeRow, XMLWriter, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);
			
		EndIf;
		
	EndDo;
	
	AdditionalObjectsToExport.Sort("ObjectForQueryName");
	CurrentRefsArray = New Array();
	CurrentQueryName = "";
	
	For Each ExportTableRow In AdditionalObjectsToExport Do
		
		If Not ValueIsFilled(ExportTableRow.Object)
			Or Not ValueIsFilled(ExportTableRow.ObjectForQueryName) Then
			
			Continue;
			
		EndIf;
		
		If CurrentQueryName <> ExportTableRow.ObjectForQueryName Then
			
			ExportRefsArrayMetadata(CurrentRefsArray, CurrentQueryName, XMLWriter, InvalidCharsCheckOnly, ObjectsUnloadedWithErrors);
			
			CurrentRefsArray = New Array();
			CurrentQueryName = ExportTableRow.ObjectForQueryName;
			
		EndIf;
		
		CurrentRefsArray.Add(ExportTableRow.Object);
		
	EndDo;
	
	ExportRefsArrayMetadata(CurrentRefsArray, CurrentQueryName, XMLWriter, InvalidCharsCheckOnly, ObjectsUnloadedWithErrors);
	
EndProcedure

// For internal use.
//
Function GetRestrictionByDateStringForQuery(Properties, TypeName)
	
	ResultingRestrictionByDate = "";
	TableName = "_";
	
	If Not (TypeName = "Document" Or TypeName = "InformationRegister" Or TypeName = "Register") Then
		Return ResultingRestrictionByDate;
	EndIf;
		
	RestrictionFieldName = TableName + "." + ?(TypeName = "Document", "Date", "Period");	
	
	If ValueIsFilled(StartDate) Then
		
		ResultingRestrictionByDate = "
		|	WHERE
		|		" + RestrictionFieldName + " >= &StartDate";
		
	EndIf;
		
	If ValueIsFilled(EndDate) Then
		
		If IsBlankString(ResultingRestrictionByDate) Then
			
			ResultingRestrictionByDate = "
			|	WHERE
			|		" + RestrictionFieldName + " <= &EndDate";
			
		Else
			
			ResultingRestrictionByDate = ResultingRestrictionByDate + "
			|	And
			|		" + RestrictionFieldName + " <= &EndDate";
			
		EndIf;
		
	EndIf;
	
	Return ResultingRestrictionByDate;
	
EndFunction

// For internal use.
//
Function GetQueryTextForInformationRegister(NameOfMetadataObjects, MetadataObject, HasAddlFilters, StringOfFieldsToSelect = "")
	
	QueryTextTemplate2 = 
	"SELECT ALLOWED
	|	_.* // Autocorrect
	|FROM
	|	&MetadataTableName AS _";
	
	QueryText = StrReplace(QueryTextTemplate2, "&MetadataTableName", NameOfMetadataObjects);
	
	If Not IsBlankString(StringOfFieldsToSelect) Then
		
		StringOfFieldsToSelect = SubstituteParametersToString("DISTINCT %1", StringOfFieldsToSelect);
		QueryText = StrReplace(QueryText, "_.* // Autocorrect", StringOfFieldsToSelect);
		
	EndIf;
	
	If MetadataObject.InformationRegisterPeriodicity = Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
		Return QueryText;
	EndIf;
	
	// 0 - Records filtered by the given period.
	// 1 - Last records at the end date.
	// 2 - First records at the start date.
	// 3 - First records at the start date and the records filtered by the given period.
	
	If PeriodicRegistersExportType = 0 Then
		
		If HasAddlFilters
			And Not UseFilterByDateForAllObjects Then
			
			Return QueryText;
			
		EndIf;
		
		AddlRestrictionByDate = GetRestrictionByDateStringForQuery(MetadataObject, "InformationRegister");
		
		QueryText = QueryText + Chars.LF + AddlRestrictionByDate;
		
	ElsIf PeriodicRegistersExportType = 1 Then
		
		MetadataTableName = SubstituteParametersToString("%1.SliceLast(&EndDate)", NameOfMetadataObjects);
		QueryText = StrReplace(QueryTextTemplate2, "&MetadataTableName", MetadataTableName);
		
		If Not IsBlankString(StringOfFieldsToSelect) Then
			
			QueryText = StrReplace(QueryText, "_.* // Autocorrect", StringOfFieldsToSelect);
			
		EndIf;
		
	ElsIf PeriodicRegistersExportType = 2 Then
		
		MetadataTableName = SubstituteParametersToString("%1.SliceFirst(&StartDate)", NameOfMetadataObjects);
		QueryText = StrReplace(QueryTextTemplate2, "&MetadataTableName", MetadataTableName);
		
		If Not IsBlankString(StringOfFieldsToSelect) Then
			
			QueryText = StrReplace(QueryText, "_.* // Autocorrect", StringOfFieldsToSelect);
			
		EndIf;
		
	ElsIf PeriodicRegistersExportType = 3 Then
		
		QueryTextTemplate2 =
		"SELECT ALLOWED 
		|	_.* // Autocorrect
		|FROM &NameOfSliceMetadataTable AS _ 
		|
		|UNION ALL
		|
		|SELECT 
		|	_.* // Autocorrect
		|FROM &MetadataTableName AS _ ";
		
		MetadataTableName = SubstituteParametersToString("%1.SliceLast(&StartDate)", NameOfMetadataObjects);
		QueryText = StrReplace(QueryTextTemplate2, "&NameOfSliceMetadataTable", MetadataTableName);
		QueryText = StrReplace(QueryText, "&MetadataTableName", NameOfMetadataObjects);
		
		If Not IsBlankString(StringOfFieldsToSelect) Then
			
			QueryText = StrReplace(QueryText, "_.* // Autocorrect", StringOfFieldsToSelect);
			
		EndIf;
		
		AddlRestrictionByDate = GetRestrictionByDateStringForQuery(MetadataObject, "InformationRegister");
		QueryText = QueryText + Chars.LF + AddlRestrictionByDate;
		
	EndIf;
	
	Return QueryText;
	
EndFunction

Function GetRequestTextForRegister(NameOfMetadataObjects, MetadataObject, HasAddlFilters, StringOfFieldsToSelect = "")
	
	QueryTextTemplate2 = 
	"SELECT ALLOWED
	|	_.* // Autocorrect
	|FROM
	|	&MetadataTableName AS _";
	
	QueryText = StrReplace(QueryTextTemplate2, "&MetadataTableName", NameOfMetadataObjects); 
	
	If Not IsBlankString(StringOfFieldsToSelect) Then
		
		StringOfFieldsToSelect = SubstituteParametersToString("DISTINCT %1", StringOfFieldsToSelect);
		QueryText = StrReplace(QueryText, "_.* // Autocorrect", StringOfFieldsToSelect);
		
	EndIf;
	
	// Restriction by date might be required.
	HasRestrictionByDates = ValueIsFilled(StartDate) Or ValueIsFilled(EndDate);
	If HasRestrictionByDates Then
		
		If HasAddlFilters
			And Not UseFilterByDateForAllObjects Then
			
			Return QueryText;
			
		EndIf;
		
		AddlRestrictionByDate = GetRestrictionByDateStringForQuery(MetadataObject, "Register");
		
		QueryText = QueryText + Chars.LF + AddlRestrictionByDate;
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// For internal use.
//
Function GetQueryTextByRow(MetadataTreeRow, HasAddlFilters, StringOfFieldsToSelect = "")
	
	MetadataObject  = MetadataTreeRow.Metadata;
	NameOfMetadataObjects     = MetadataObject.FullName();
	
	If Metadata.InformationRegisters.Contains(MetadataObject) Then
		
		QueryText = GetQueryTextForInformationRegister(NameOfMetadataObjects, MetadataObject, HasAddlFilters, StringOfFieldsToSelect);
		Return QueryText;
		
	ElsIf   Metadata.AccumulationRegisters.Contains(MetadataObject)
			Or Metadata.AccountingRegisters.Contains(MetadataObject) Then
		
		QueryText = GetRequestTextForRegister(NameOfMetadataObjects, MetadataObject, HasAddlFilters, StringOfFieldsToSelect);
		Return QueryText;
		
	EndIf;
	
	QueryTextTemplate2 =
	"SELECT ALLOWED
	|	_.* // Autocorrect
	|FROM
	|	&MetadataTableName AS _";
	
	QueryText = StrReplace(QueryTextTemplate2, "&MetadataTableName", NameOfMetadataObjects);
	
	If Not IsBlankString(StringOfFieldsToSelect) Then
		
		QueryText = StrReplace(QueryText, "_.* // Autocorrect", StringOfFieldsToSelect);
		
	EndIf;
	
	// Restriction by date might be required.
	HasRestrictionByDates = ValueIsFilled(StartDate) Or ValueIsFilled(EndDate);
	If HasRestrictionByDates Then
		
		If HasAddlFilters
			And Not UseFilterByDateForAllObjects Then
			
			Return QueryText;
			
		EndIf;
		
		AddlRestrictionByDate = "";
		
		// Check if this metadata object supports restrictions by date.
		If Metadata.Documents.Contains(MetadataObject) Then
			
			AddlRestrictionByDate = GetRestrictionByDateStringForQuery(MetadataObject, "Document");
			
		ElsIf Metadata.AccountingRegisters.Contains(MetadataObject)
			Or Metadata.AccumulationRegisters.Contains(MetadataObject) Then
			
			AddlRestrictionByDate = GetRestrictionByDateStringForQuery(MetadataObject, "Register");
			
		EndIf;
		
		QueryText = QueryText + Chars.LF + AddlRestrictionByDate;
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// For internal use.
//
Function PrepareBuilderBorExport(MetadataTreeRow, StringOfFieldsToSelect = "")
	
	HasAddlFilters = (MetadataTreeRow.BuilderSettings <> Undefined); 
	
	ResultingQueryText = GetQueryTextByRow(MetadataTreeRow, HasAddlFilters, StringOfFieldsToSelect);
	
	ReportBuilder = New ReportBuilder;
	
	ReportBuilder.Text = ResultingQueryText;
	
	ReportBuilder.FillSettings();
	
	ReportBuilder.Filter.Reset();
	If HasAddlFilters Then
		
		ReportBuilder.SetSettings(MetadataTreeRow.BuilderSettings);
		
	EndIf;
	
	ReportBuilder.Parameters.Insert("StartDate", StartDate);
	ReportBuilder.Parameters.Insert("EndDate", EndDate);
	
	Return ReportBuilder;
	
EndFunction

Function GetQueryResultWithRestrictions(MetadataTreeRow)
	
	ReportBuilder = PrepareBuilderBorExport(MetadataTreeRow);

	ReportBuilder.Execute();
	QueryResult = ReportBuilder.Result;
		
	Return QueryResult;
		
EndFunction

Procedure WritingObjectTypeData(MetadataTreeRow, XMLWriter, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly = False)
	
	QueryResult = GetQueryResultWithRestrictions(MetadataTreeRow);
	
	RequestAndRecord(QueryResult, XMLWriter, True, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);
	
EndProcedure

// The procedure runs the passed query and writes the objects received using the query.
//
// Parameters:
//   QueryResult - QueryResult - Query to run. The result contains a set of objects for recording.
//   XMLWriter - XMLWriter - Intermediary object used to write other infobase objects.
//   TopLevelRequest - Boolean - Flag indicating whether process animation is required.
//
Procedure RequestAndRecord(QueryResult, XMLWriter, TopLevelRequest,
	ObjectsUnloadedWithErrors, InvalidCharsCheckOnly)
	
	// Universal procedure of exporting reference objects procedure.
	QueryResultProcessing(QueryResult, XMLWriter, True, TopLevelRequest,
		ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);
	
EndProcedure

Procedure ExecuteAuxiliaryActionsForXMLWriter(ObjectsProcessedTotal, XMLWriter, InvalidCharsCheckOnly)
	
	If Not InvalidCharsCheckOnly Then
		Return;
	EndIf;
	
	If ObjectsProcessedTotal > 1000 Then
		
		XMLWriter.Close();
		XMLWriter = Undefined;
		
		XMLWriter = CreateXMLRecordObjectForCheck();
		
	EndIf;
	
EndProcedure

Function LinkUnloaded(Ref)
	
	Return mExportedObjects.Find(Ref, "Ref") <> Undefined;
	
EndFunction

Procedure AddLinkToUploaded(Ref)
	
	AddLine = ExportedObjectsCollection().Add();
	AddLine.Ref = Ref;
	
EndProcedure

// The procedure writes objects contained in the query result selection and infobase objects required "by reference".
//
// Parameters:
//   QueryResult - QueryResult - Query result.
//   XMLWriter - XMLWriter - Intermediary object used to write other infobase objects.
//   ThisIsRequestForObject - Boolean - If True, selection must contain referenced-to objects.
//             If False, don't export the object, only process references to other objects.
//
Procedure QueryResultProcessing(QueryResult, XMLWriter, ThisIsRequestForObject,
	TopLevelRequest, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly)
	
	SamplingFromQueryResults = QueryResult.Select();
	
	ObjectsProcessedTotal = 0;
	
	While SamplingFromQueryResults.Next() Do
		
		If ThisIsRequestForObject Then
			
			// Reference object export.
			Ref = SamplingFromQueryResults.Ref;
			If LinkUnloaded(Ref) Then
				
				Continue;
				
			EndIf;
			
			AddLinkToUploaded(Ref);
			
			ObjectsProcessedTotal = TotalProcessedRecords();
			
		EndIf;
		
		If mSubordinateObjectsExportExists Then
		
			// Loop over the query columns and search for reference values that might need to be exported.
			For Each QueryColumn In QueryResult.Columns Do
				
				ColumnValue = SamplingFromQueryResults[QueryColumn.Name];
				
				If TypeOf(ColumnValue) = mQueryResultType Then
					
					QueryResultProcessing(ColumnValue, XMLWriter, False, False, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);
					
				Else
				
					WriteValueIfNecessary(ColumnValue, XMLWriter, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If ThisIsRequestForObject Then
			
			Object = Ref.GetObject();
			
			Try
				
				ExecuteAuxiliaryActionsForXMLWriter(ObjectsProcessedTotal, XMLWriter, InvalidCharsCheckOnly);
				
				Serializer.WriteXML(XMLWriter, Object);
				
				ObjectMetadata = Object.Metadata();
				
				If ThisIsMetadataWithPredefinedElements(ObjectMetadata) And Object.Predefined Then
					
					NewRow = CollectionPredefinedData().Add();
					NewRow.TableName = ObjectMetadata.FullName();
					NewRow.Ref = XMLString(Ref);
					NewRow.PredefinedDataName = Object.PredefinedDataName;
					
				EndIf;
				
				If ExportDocumentWithItsRecords And Metadata.Documents.Contains(ObjectMetadata) Then
					
					// Export document register records.
					For Each Movement In Object.RegisterRecords Do
						
						Movement.Read();
						
						If mSubordinateObjectsExportExists
							And Movement.Count() > 0 Then
							
							RegisterType_ = Type(Movement);
							
							ColumnsArray1 = mRegisteredRecordsColumnsMap.Get(RegisterType_);
							
							If ColumnsArray1 = Undefined Then
								
								RegisterRecordTable = Movement.Unload();
								AccountingRegister = Metadata.AccountingRegisters.Contains(Movement.Metadata());
								ColumnsArray1 = RegisterRecordsTableColumns(RegisterRecordTable, AccountingRegister);
								mRegisteredRecordsColumnsMap.Insert(RegisterType_, ColumnsArray1);	
								
							EndIf;
							
							UnloadSubordinateValuesOfSet(XMLWriter, Movement, ColumnsArray1, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);
							
						EndIf;
						
						Serializer.WriteXML(XMLWriter, Movement);
						
					EndDo;
					
				EndIf;
				
			Except
				
				ErrorDescriptionString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				// Failed to save as XML. Perhaps, it contains unsupported characters.
				// 
				If InvalidCharsCheckOnly Then
					
					If ObjectsUnloadedWithErrors.Get(Ref) = Undefined Then
						ObjectsUnloadedWithErrors.Insert(Ref, ErrorDescriptionString);
					EndIf;
					
				Else
					
					ResultMessageString = NStr("ru = 'При выгрузке объекта %1(%2) возникла ошибка:
						|%3';
						|en = 'Error occurred while exporting object %1(%2):
						|%3';");
					ResultMessageString = SubstituteParametersToString(ResultMessageString,
						Object, TypeOf(Object), ErrorDescriptionString);
					
					MessageToUser(ResultMessageString);
					
					Raise ResultMessageString;
					
				EndIf;
				
			EndTry;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure UnloadSubordinateValuesOfSet(XMLWriter, Movement, ColumnsArray1, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly)
		
	For Each RecordingFromSet In Movement Do
								
		For Each Column In ColumnsArray1 Do
			
			If StrFind(Column, "ExtDimension") <> 0 Then
		
				If Column <> "ExtDimensionDr" And Column <> "ExtDimensionCr" Then
				    Column = "ExtDimension";
				EndIf;
				
				Value = RecordingFromSet[Column];
				
				If Value = Undefined Then
					Continue;
				EndIf;
				
				For Each KeyAndValue In Value Do
					
					If ValueIsFilled(KeyAndValue.Value) Then
						WriteValueIfNecessary(KeyAndValue.Value, XMLWriter, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);	
					EndIf;
					
				EndDo;
				
			Else
			
				SavedValue = RecordingFromSet[Column];
				WriteValueIfNecessary(SavedValue, XMLWriter, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Function RegisterRecordsTableColumns(RegisterRecordTable, AccountingRegister = False)
	
	ColumnsArray1 = New Array();
	For Each TableColumn2 In RegisterRecordTable.Columns Do
		
		If TableColumn2.Name = "PointInTime"
			Or StrFind(TableColumn2.Name, "ExtDimensionType") = 1 Then
			
			Continue;
			
		EndIf;
		
		If StrFind(TableColumn2.Name, "ExtDimensionDr") = 1 And AccountingRegister Then
			
			If ColumnsArray1.Find("ExtDimensionDr") = Undefined Then
				ColumnsArray1.Add("ExtDimensionDr");
			EndIf;
			
			Continue;
			
		EndIf;
		
		If StrFind(TableColumn2.Name, "ExtDimensionCr") = 1 And AccountingRegister Then
			
			If ColumnsArray1.Find("ExtDimensionCr") = Undefined Then
				ColumnsArray1.Add("ExtDimensionCr");	
			EndIf;
			
			Continue;
			
		EndIf;
		
		If StrFind(TableColumn2.Name, "ExtDimension") = 1 And AccountingRegister Then
			
			If ColumnsArray1.Find("ExtDimension") = Undefined Then
				ColumnsArray1.Add("ExtDimension");	
			EndIf;
			
			Continue;
			
		EndIf;
		
		ColumnsArray1.Add(TableColumn2.Name);
		
	EndDo;
	
	Return ColumnsArray1;
	
EndFunction

// The procedure analyzes whether it is necessary to write the object "by reference," and writes it.
//
// Parameters:
//   AnalyzedValue - AnyRef - Value to analyze.
//   XMLWriter - XMLWriter - Intermediary object used to write other infobase objects.
//
Procedure WriteValueIfNecessary(AnalyzedValue, XMLWriter, 
	ObjectsUnloadedWithErrors, InvalidCharsCheckOnly )
	
	If Not ValueIsFilled(AnalyzedValue) Then
		Return;
	EndIf;
	
	MetadataObjectsList = ReferenceTypes.Get(TypeOf(AnalyzedValue)); // MetadataObject
	
	If MetadataObjectsList = Undefined Then
		Return; // This is not a reference.
	EndIf;
	
	If LinkUnloaded(AnalyzedValue) Then
		Return; // The object has already been exported.
	EndIf;
	
	// Checks whether this type is included in the list of items exported additionally.
	TableRow = FullExportComposition.Find(MetadataObjectsList, "MetadataObjectsList");
	If TableRow <> Undefined Then
		Return;
	EndIf;
	
	TableRow = AuxiliaryExportComposition.Find(MetadataObjectsList, "MetadataObjectsList");
	If TableRow <> Undefined Then
		
		QueryTextTemplate2 =
		"SELECT
		|	*
		|FROM
		|	&MetadataTableName AS ObjectTable_
		|WHERE
		|	ObjectTable_.Ref = &Ref";
		
		ReplacementString = TableRow.TreeRow.DescriptionItem.ForQuery + MetadataObjectsList.Name;
		QueryText = StrReplace(QueryTextTemplate2, "&MetadataTableName", ReplacementString);
		
		AdditionalRequest = New Query(QueryText);
		AdditionalRequest.SetParameter("Ref", AnalyzedValue);
		QueryResult = AdditionalRequest.Execute();
		RequestAndRecord(QueryResult, XMLWriter, False, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);
		
	EndIf;
		
EndProcedure

// The procedure writes the constant value.
//
// Parameters:
//   XMLWriter - XMLWriter - Intermediary object used to write other infobase objects.
//   MetadataConstant - MetadataObjectConstant - Metadata details of a constant to export.
//
Procedure WritingConstant(XMLWriter, MetadataConstant, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly)
	
	ValueManager = Constants[MetadataConstant.Name].CreateValueManager();
	ValueManager.Read();
	WriteValueIfNecessary(ValueManager.Value, XMLWriter, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);
	// Exported dataset.
	
	ObjectsProcessedTotal = TotalProcessedRecords();
	Try
		
		ExecuteAuxiliaryActionsForXMLWriter(ObjectsProcessedTotal, XMLWriter, InvalidCharsCheckOnly);
		
		Serializer.WriteXML(XMLWriter, ValueManager);
		
	Except
		
		ErrorDescriptionString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		// Failed to save as XML. Perhaps, it contains unsupported characters.
		// 
		If InvalidCharsCheckOnly Then
			
			ObjectsUnloadedWithErrors.Insert(ValueManager, ErrorDescriptionString);
			
		Else
			
			ResultMessageString = NStr("ru = 'При выгрузке константы %1 возникла ошибка:
			|%2';
			|en = 'Error occurred while exporting constant %1:
			|%2';");
			ResultMessageString = SubstituteParametersToString(ResultMessageString,
				MetadataConstant.Name, ErrorDescriptionString);
			
			MessageToUser(ResultMessageString);
			
			Raise ResultMessageString;
			
		EndIf;
		
	EndTry;	
	
	ConstantsProcessed = ConstantsProcessed + 1;
	
EndProcedure

// The procedure writes register record sets (accumulation registers, accounting registers, and others).
//
// Parameters:
//   XMLWriter - XMLWriter - Intermediary object used to write other infobase objects.
//   MetadataTreeRow - ValueTreeRow - Row of the metadata tree matching the register:
//     * MetadataObjectsList - MetadataObjectCalculationRegister - Register metadata.
//     * Parent - See RegisterRecord.MetadataTreeRow
//
Procedure RegisterRecord(XMLWriter, MetadataTreeRow, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly, AccountingRegister = False)
	
	RecordSetManager = MetadataTreeRow.DescriptionItem.Manager[MetadataTreeRow.MetadataObjectsList.Name];
	
	TableNameForQuery = MetadataTreeRow.DescriptionItem.ForQuery;
		
	RecordingViaRecordset(XMLWriter, RecordSetManager, TableNameForQuery,
		MetadataTreeRow, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly, AccountingRegister);
	
EndProcedure

// The procedure writes register record sets (accumulation registers, accounting registers, and others).
//
// Parameters:
//   XMLWriter - XMLWriter - Intermediary object used to write other infobase objects.
//   MetadataTreeRow - ValueTreeRow - Row of the metadata tree matching the register:
//     * MetadataObjectsList - MetadataObjectCalculationRegister - Register metadata.
//     * Parent - See RecalculationRecord.MetadataTreeRow
//
Procedure RecalculationRecord(XMLWriter, MetadataTreeRow, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly)
	
	ObjectString = MetadataTreeRow.Parent.Parent; // See RecalculationRecord.MetadataTreeRow
	
	CalculationRegisterName = ObjectString.MetadataObjectsList.Name;
	ManagerAsString = StrReplace(MetadataTreeRow.DescriptionItem.Manager, "%i", CalculationRegisterName);
	RecalculationManager = EvalExpression(ManagerAsString);
	RecalculationManager = RecalculationManager[MetadataTreeRow.MetadataObjectsList.Name];
	StringForQuery = StrReplace(MetadataTreeRow.DescriptionItem.ForQuery, "%i", CalculationRegisterName);
	
	RecordingViaRecordset(XMLWriter, RecalculationManager, StringForQuery,
		MetadataTreeRow, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);
	
EndProcedure

// The procedure writes document sequences.
//
// Parameters:
//   XMLWriter - XMLWriter - Intermediary object used to write other infobase objects.
//   MetadataTreeRow - ValueTreeRow - Row of the metadata tree matching the register:
//     * MetadataObjectsList - MetadataObjectCalculationRegister - Register metadata.
//     * Parent - See SequenceWriter.MetadataTreeRow
//
Procedure SequenceWriter(XMLWriter, MetadataTreeRow, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly)
	
	RecordSetManager = MetadataTreeRow.DescriptionItem.Manager[MetadataTreeRow.MetadataObjectsList.Name];
	RecordingViaRecordset(XMLWriter, RecordSetManager, MetadataTreeRow.DescriptionItem.ForQuery,
		MetadataTreeRow, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);
	
EndProcedure

// The procedure writes data, which is accessed using the record set.
//
// Parameters:
//   XMLWriter - XMLWriter - Intermediary object used to write other infobase objects.
//   RecordSetManager - InformationRegisterManager
//                         - AccumulationRegisterManager
//                         - CalculationRegisterManager
//                         - AccountingRegisterManager - Register manager.
//   ForQuery - String - Object table name prefix.
//   MetadataTreeRow - ValueTreeRow - Row of the metadata tree matching the register:
//     * MetadataObjectsList - MetadataObjectCalculationRegister - Register metadata.
//     * Parent - See RegisterRecord.MetadataTreeRow
//
Procedure RecordingViaRecordset(XMLWriter, RecordSetManager, ForQuery,
	MetadataTreeRow, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly, AccountingRegister = False)
	
	ObjectName = MetadataTreeRow.MetadataObjectsList.Name;
	
	IsCalculationRegister = (ForQuery = "CalculationRegister.");
	// Get content of the register record columns and check for at least one record.
	If ForQuery = "AccountingRegister." Then
		TableNameForQuery = ForQuery + ObjectName + ".RecordsWithExtDimensions(, , , , 1)";
	Else
		TableNameForQuery = ForQuery + ObjectName;	
	EndIf;
	
	QueryTextTemplate2 =
	"SELECT TOP 1
	|	*
	|FROM
	|	&MetadataTableName AS ObjectTable_";
	
	QueryText = StrReplace(QueryTextTemplate2, "&MetadataTableName", TableNameForQuery);
	
	ReplacementString = "ObjectTable_" + ObjectName;
	QueryText = StrReplace(QueryText, "ObjectTable_", ReplacementString);
	
	Query = New Query(QueryText);
	QueryResultByComposition = Query.Execute();
	If QueryResultByComposition.IsEmpty() Then
		Return;
	EndIf;
	
	RegisterRecordTable = QueryResultByComposition.Unload();
	ColumnsArray1 = RegisterRecordsTableColumns(RegisterRecordTable, AccountingRegister);
	
	// Export registers through its record set.
	RecordSet = RecordSetManager.CreateRecordSet();
	
	Filter = RecordSet.Filter;
	FilterFieldsString = "";
	For Each FilterElement In Filter Do 
		If Not IsBlankString(FilterFieldsString) Then 
			FilterFieldsString = FilterFieldsString + ",";
		EndIf;
		FilterFieldsString = FilterFieldsString + FilterElement.Name;
	EndDo;
	
	ReportBuilder = PrepareBuilderBorExport(MetadataTreeRow, FilterFieldsString); 
	ReportBuilder.Execute();
	QueryResultByFilterValues = ReportBuilder.Result;	
	SamplingFromResult = QueryResultByFilterValues.Select();
	
	NumberOfSelectionFields = RecordSet.Filter.Count();
	
	// Read record sets with different filter content and write them.
	While SamplingFromResult.Next() Do
		
		// Set a filter for registers, which have at least one filter (dimension).
		If NumberOfSelectionFields <> 0 Then
			
			For Each Column In QueryResultByFilterValues.Columns Do 
				If IsCalculationRegister
					And SamplingFromResult[Column.Name] = Undefined Then
					Continue;
				EndIf;
				
				Filter[Column.Name].Value = SamplingFromResult[Column.Name];
				Filter[Column.Name].ComparisonType = ComparisonType.Equal;
				Filter[Column.Name].Use = True;
			EndDo;
			
		EndIf;
		
		RecordSet.Read();
		
		If mSubordinateObjectsExportExists Then
		
			// Check if all values written to the set need to be written by reference.
			UnloadSubordinateValuesOfSet(XMLWriter, RecordSet, ColumnsArray1, ObjectsUnloadedWithErrors, InvalidCharsCheckOnly);
			
		EndIf;
		
		ObjectsProcessedTotal = TotalProcessedRecords();
		Try
			
			ExecuteAuxiliaryActionsForXMLWriter(ObjectsProcessedTotal, XMLWriter, InvalidCharsCheckOnly);
			
			Serializer.WriteXML(XMLWriter, RecordSet);
			
		Except
			
			ErrorDescriptionString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			// Failed to save as XML. Perhaps, it contains unsupported characters.
			// 
			If InvalidCharsCheckOnly Then
				
				NewSet = RecordSetManager.CreateRecordSet();
				
				For Each FIlterRow In RecordSet.Filter Do
					
					FormFilterRow = NewSet.Filter.Find(FIlterRow.Name);
					
					If FormFilterRow = Undefined Then
						Continue;
					EndIf;
					
					FormFilterRow.Use = FIlterRow.Use;
					FormFilterRow.ComparisonType = FIlterRow.ComparisonType;
					FormFilterRow.Value = FIlterRow.Value;
					
				EndDo;
				
				ObjectsUnloadedWithErrors.Insert(NewSet, ErrorDescriptionString);
												
			Else
				
				ResultMessageString = NStr("ru = 'При выгрузке регистра %1%2 возникла ошибка:
					|%3';
					|en = 'Error occurred while exporting register %1%2:
					|%3';");
				ResultMessageString = SubstituteParametersToString(ResultMessageString,
					ForQuery, ObjectName, ErrorDescriptionString);
				
				MessageToUser(ResultMessageString);
				
				Raise ResultMessageString;
				
			EndIf;
			
		EndTry;
		
		RecordSetsProcessed = RecordSetsProcessed + 1;
		
	EndDo;
	
EndProcedure

// The procedure recursively processes the metadata tree row creating lists of full and auxiliary exports.
//
// Parameters:
//   FullExportComposition - Full export list.
//   AuxiliaryExportComposition - Auxiliary export list.
//   VTRow - Metadata tree row to process.
//
Procedure AddObjectsToExport(FullExportComposition, AuxiliaryExportComposition, VTRow)
	
	If (VTRow.DescriptionItem <> Undefined) 
		And VTRow.DescriptionItem.ToExport Then
		
		AddLine = Undefined;
		
		If VTRow.Export Then
			
			AddLine = FullExportComposition.Add();
						
		ElsIf VTRow.ExportIfNecessary Then
			
			AddLine = AuxiliaryExportComposition.Add();
									
		EndIf;
		
		If AddLine <> Undefined Then
			
			AddLine.MetadataObjectsList = VTRow.MetadataObjectsList;	
			AddLine.TreeRow = VTRow;			
			
		EndIf;
		
	EndIf;
	
	For Each SubordinateVTRow In VTRow.Rows Do
		AddObjectsToExport(FullExportComposition, AuxiliaryExportComposition, SubordinateVTRow);
	EndDo;
	
EndProcedure

// The procedure populates the metadata tree row and mapping of reference types to metadata objects.
//
// Parameters:
//   MetadataObjectsList - MetadataObject - Metadata object details.
//   VTItem - ValueTreeRow - Metadata tree row to populate.
//   DescriptionItem - Describes the class the metadata object belongs to (properties, subordinate classes).
//
Procedure BuildObjectSubtree(MetadataObjectsList, VTItem, DescriptionItem)
	
	VTItem.Metadata = MetadataObjectsList;
	VTItem.MetadataObjectsList   = MetadataObjectsList;
	VTItem.FullMetadataName = MetadataObjectsList.Name;
	VTItem.DescriptionItem = DescriptionItem;
	VTItem.Export = False;
	VTItem.ExportIfNecessary = True;
	VTItem.PictureIndex = DescriptionItem.PictureIndex;
	
	If DescriptionItem.Manager <> Undefined Then
		
		// Populate mapping between reference types and metadata objects.
		If ObjectFormsRefType(MetadataObjectsList) Then
			ReferenceTypes[TypeOf(DescriptionItem.Manager[MetadataObjectsList.Name].EmptyRef())] = MetadataObjectsList;
		EndIf;
		
		If Metadata.AccumulationRegisters.Contains(MetadataObjectsList) 
			Or	Metadata.AccountingRegisters.Contains(MetadataObjectsList) Then
			
			RegistersWithTotalsCollection().Add(VTItem);
			
		EndIf;
		
	EndIf;		
		
	// Subordinate branches.
	For Each SubordinateClass In DescriptionItem.Rows Do
		
		If Not SubordinateClass.ToExport Then
			Continue;
		EndIf;
		
		ClassBranch = VTItem.Rows.Add();
		ClassBranch.Metadata = SubordinateClass.Class;
		ClassBranch.Export = False;
		ClassBranch.ExportIfNecessary = True;
		ClassBranch.FullMetadataName = SubordinateClass.Class;
		ClassBranch.PictureIndex = SubordinateClass.PictureIndex;
				
		SubordinateObjectsOfThisClass = MetadataObjectsList[SubordinateClass.Class];
				
		For Each SubordinateMetadataObject In SubordinateObjectsOfThisClass Do 
			SubordinateVTItem = ClassBranch.Rows.Add();
			BuildObjectSubtree(SubordinateMetadataObject, SubordinateVTItem, SubordinateClass);
		EndDo;
		
	EndDo;
		
EndProcedure

// The procedure deletes the rows matching the metadata (which are not included in the data exported) from the metadata tree.
//
// Parameters:
//   VTItem - ValueTreeRow - Metadata tree row whose subordinate items are considered
//        for deletion from the list of potentially exported data.
//
Procedure CollapsingObjectSubtree(VTItem)
	
	ClassesBranchesToDelete = New Array;
	For Each ClassBranch In VTItem.Rows Do
		
		SubordinateMetadataToDelete = New Array;
		
		For Each SubordinateMetadataObject In ClassBranch.Rows Do
			CollapsingObjectSubtree(SubordinateMetadataObject);
			If (SubordinateMetadataObject.Rows.Count()) = 0
				And (Not SubordinateMetadataObject.DescriptionItem.ToExport) Then
				
				SubordinateMetadataToDelete.Add(ClassBranch.Rows.IndexOf(SubordinateMetadataObject));
				
			EndIf;
			
		EndDo;
		
		For Cnt = 1 To SubordinateMetadataToDelete.Count() Do
			ClassBranch.Rows.Delete(SubordinateMetadataToDelete[SubordinateMetadataToDelete.Count() - Cnt]);
		EndDo;
		
		If ClassBranch.Rows.Count() = 0 Then
			ClassesBranchesToDelete.Add(VTItem.Rows.IndexOf(ClassBranch));
		EndIf;
		
	EndDo;
	
	For Cnt = 1 To ClassesBranchesToDelete.Count() Do
		VTItem.Rows.Delete(ClassesBranchesToDelete[ClassesBranchesToDelete.Count() - Cnt]);
	EndDo;
	
EndProcedure

// The procedure sets the Export flag for metadata tree rows subordinate to the current one. 
//      Then calculates and sets the export by reference flag for other objects whose references can or must be inside the object matching this row.
//      
//
// Parameters:
//   VTItem - ValueTreeRow - Metadata tree row.
//
Procedure SetExportToSubordinateRows(VTItem)
	For Each SubordinateRow In VTItem.Rows Do
		SubordinateRow.Export = VTItem.Export;
		SetExportToSubordinateRows(SubordinateRow);
	EndDo;
EndProcedure

// The procedure sets the Export flag for the metadata tree row based on this flag of subordinate rows.
// Then it calls itself for the parent ensuring processing to the tree root.
//
// Parameters:
//   VTItem - ValueTreeRow - Metadata tree row.
//
Procedure UpdateExportState(VTItem)
	If VTItem = Undefined Then
		Return;
	EndIf;
	If (VTItem.DescriptionItem <> Undefined) And VTItem.DescriptionItem.ToExport Then
		Return; // Update upstream to the root or to the first exportable item.
	EndIf;
	State = Undefined;
	For Each SubordinateVTItem In VTItem.Rows Do
		If State = Undefined Then
			State = SubordinateVTItem.Export;
		Else
			If Not State = SubordinateVTItem.Export Then
				State = 2;
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	If State <> Undefined Then
		VTItem.Export = State;
		UpdateExportState(VTItem.Parent);
	EndIf;
EndProcedure

// The procedure sets the Export flag for metadata tree rows subordinate to the current one. 
//      Then calculates and sets the export by reference flag for other objects whose references can or must be inside the object matching this row.
//      
//
// Parameters:
//   VTItem - ValueTreeRow - Metadata tree row.
//
Procedure SetExportIfNecessaryToSubordinateRows(VTItem)
	
	For Each SubordinateRow In VTItem.Rows Do
		SubordinateRow.ExportIfNecessary = VTItem.ExportIfNecessary;
		SetExportIfNecessaryToSubordinateRows(SubordinateRow);
	EndDo;
	
EndProcedure

// The procedure sets the Export flag for the metadata tree row based on this flag of subordinate rows.
// Then it calls itself for the parent ensuring processing to the tree root.
//
// Parameters:
//   VTItem - ValueTreeRow - Metadata tree row.
//
Procedure RefreshStateExportIfNecessary(VTItem)
	
	If VTItem = Undefined Then
		Return;
	EndIf;
	
	If (VTItem.DescriptionItem <> Undefined) And VTItem.DescriptionItem.ToExport Then
		Return; // Update upstream to the root or to the first exportable item.
	EndIf;
	
	State = Undefined;
	For Each SubordinateVTItem In VTItem.Rows Do
		
		If State = Undefined Then
			State = SubordinateVTItem.ExportIfNecessary;
		Else
			If Not State = SubordinateVTItem.ExportIfNecessary Then
				State = 2;
				Break;
			EndIf;
		EndIf;
		
	EndDo;
	
	If State <> Undefined Then
		VTItem.ExportIfNecessary = State;
		RefreshStateExportIfNecessary(VTItem.Parent);
	EndIf;
	
EndProcedure

// The procedure processes the status of the Export flag.
// Sets the Export and ExportIfNecessary flags for linked branches of the tree.
//
// Parameters:
//   VTItem - ValueTreeRow - Metadata tree row.
//
Procedure ProcessingStateChangeExportIfNecessary(VTItem)
	
	If VTItem.ExportIfNecessary = 2 Then
		VTItem.ExportIfNecessary = 0;
	EndIf;
	
	// Change the status "downstream".
	SetExportIfNecessaryToSubordinateRows(VTItem);
	// Change the status "upstream".
	RefreshStateExportIfNecessary(VTItem.Parent);
	
EndProcedure

// The function determines whether objects of this metadata class are typified.
//
// Parameters:
//   LongDesc - Class details. Returns:
// True if objects of this metadata class are typified. Otherwise, False.
//
Function MetadataClassTyped(LongDesc)
	
	For Each Property In LongDesc.Properties Do
		If Property.Value = "Type" Then
			Return True;
		EndIf;
	EndDo;
	Return False;
	
EndFunction

// The function determines whether the type is a reference one.
//
// Parameters:
//   Type - Type - Type to analyze. Returns:
// True if this is a reference type. Otherwise, False.
//
Function ReferentialType(Type)
	
	TypeMetadata = ReferenceTypes.Get(Type);
	Return TypeMetadata <> Undefined;	
		
EndFunction

// The procedure adds a new unique item.
//
// Parameters:
//   Array - Array of Arbitrary - Type to analyze.
//   Item - Arbitrary - Item to add.
//
Procedure AddToArrayIfUnique(Array, Item)
	
	If Array.Find(Item) = Undefined Then
		Array.Add(Item);
	EndIf;
	
EndProcedure

// The function returns an array of types that can have record fields of a metadata object matching the tree row.
//
// Parameters:
//   VTItem - ValueTreeRow - Metadata tree row. Returns:
// Array of types potentially used by the corresponding record.
//
Function GetAllTypes(VTItem)
	
	MetadataObjectsList = VTItem.MetadataObjectsList;
	If TypeOf(MetadataObjectsList) <> Type("MetadataObject") 
		And TypeOf(MetadataObjectsList) <> Type("ConfigurationMetadataObject") Then
		
		Raise(NStr("ru = 'Внутренняя ошибка обработки выгрузки';
								|en = 'Export process internal error';"));
		
	EndIf;
	
	Return GetTypesUsedByMO(MetadataObjectsList, VTItem.DescriptionItem);
	
EndFunction

// The function returns an array of types that can have metadata object record fields.
//
// Parameters:
//   MetadataObjectsList - MetadataObject - Metadata details.
//   DescriptionItem - Describes metadata object class. Returns:
// Array of types potentially used by the matching record.
//
Function GetTypesUsedByMO(MetadataObjectsList, DescriptionItem)
	
	AllTypes = New Array;
	
	For Each Property In DescriptionItem.Properties Do
		
		PropertyValue = MetadataObjectsList[Property.Value];
		If TypeOf(PropertyValue) = Type("MetadataObjectPropertyValueCollection") And PropertyValue.Count() > 0 Then
			
			For Each CollectionRow In PropertyValue Do
				
				RefTypeKeyAndValue = MetadataObjectsAndRefTypesMap[CollectionRow];
				
				If RefTypeKeyAndValue <> Undefined Then
					
					AddToArrayIfUnique(AllTypes, RefTypeKeyAndValue);	
					
				EndIf;
				
			EndDo;			
						
		ElsIf TypeOf(PropertyValue) = Type("MetadataObject") Then
			
			For Each RefTypeKeyAndValue In ReferenceTypes Do
				
				If PropertyValue = RefTypeKeyAndValue.Value Then
					AddToArrayIfUnique(AllTypes, RefTypeKeyAndValue.Key);
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	If MetadataClassTyped(DescriptionItem) Then
		
		TypeDetails = MetadataObjectsList.Type;
		For Each OneType In TypeDetails.Types() Do
			
			If ReferentialType(OneType) Then
				AddToArrayIfUnique(AllTypes, OneType);
			EndIf;
			
		EndDo;
		
	Else
		
		If Metadata.InformationRegisters.Contains(MetadataObjectsList)
			Or Metadata.AccumulationRegisters.Contains(MetadataObjectsList)
			Or Metadata.AccountingRegisters.Contains(MetadataObjectsList)
			Or Metadata.CalculationRegisters.Contains(MetadataObjectsList) Then
			
			// Search for registers in recorders.
			For Each DocumentMD In Metadata.Documents Do
				
				If DocumentMD.RegisterRecords.Contains(MetadataObjectsList) Then
					
					AddToArrayIfUnique(AllTypes, TypeOf(Documents[DocumentMD.Name].EmptyRef()));
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	For Each SubordinateClass In DescriptionItem.Rows Do
		
		For Each SubordinateMetadataObject In MetadataObjectsList[SubordinateClass.Class] Do
			
			TypesOfSubordinateObject = GetTypesUsedByMO(SubordinateMetadataObject, SubordinateClass);
			For Each OneType In TypesOfSubordinateObject Do
				AddToArrayIfUnique(AllTypes, OneType);
			EndDo;
			
		EndDo;
		
	EndDo;
	
	Return AllTypes;
	
EndFunction

// The function returns the metadata tree row matching the passed metadata object.
// Searches in rows subordinate to the passed row.
//
// Parameters:
//   VTRow - ValueTreeRow - Metadata tree row the search starts from.
//   MetadataObjectsList - MetadataObject - Metadata details.
//   
// Returns:
//   ValueTreeRow- Metadata tree row.
//
Function VTItemByMetadataObjectAndRow(VTRow, MetadataObjectsList)
	
	Return VTRow.Rows.Find(MetadataObjectsList, "MetadataObjectsList", True);	
	
EndFunction

// The function returns the metadata tree row matching the passed metadata object.
// Searches the entire metadata tree.
//
// Parameters:
//   MetadataObjectsList - MetadataObject - Metadata details.
// Returns:
//   ValueTreeRow- Metadata tree row.
//
Function VTItemByMetadataObject(MetadataObjectsList)
	For Each VTRow In MetadataTree.Rows Do
		VTItem = VTItemByMetadataObjectAndRow(VTRow, MetadataObjectsList);
		If VTItem <> Undefined Then 
			Return VTItem;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction

// The procedure determines to which objects the record matching the metadata object displayed by
// this metadata tree row can refer, and sets the ExportIfNecessary flag for them.
//
// Parameters:
//   VTItem - ValueTreeRow - Metadata tree row.
//
Procedure SettingStateExportIfNecessary(VTItem)
	
	RefreshStateExportIfNecessary(VTItem.Parent);
	If VTItem.Export <> 1 And VTItem.ExportIfNecessary <> 1 Then
		Return;
	EndIf;
	If VTItem.MetadataObjectsList = Undefined Then
		Return;
	EndIf;
	
	AllTypes = GetAllTypes(VTItem);
	For Each ReferentialType In AllTypes Do
		
		TypeAndObject = ReferenceTypes.Get(ReferentialType);
		If TypeAndObject = Undefined Then
			
			ExceptionText = NStr("ru = 'Внутренняя ошибка. Неполное заполнение структуры ссылочных типов %1';
									|en = 'Internal error. Structure of the %1 reference types is incomplete';");
			ExceptionText = SubstituteParametersToString(ExceptionText, ReferentialType);
			Raise(ExceptionText);
			
		EndIf;
		
		MetadataObjectsList = TypeAndObject;
		VTRow = VTItemByMetadataObject(MetadataObjectsList);
		If VTRow = Undefined Then 
			
			ExceptionText = NStr("ru = 'Внутренняя ошибка. Неполное заполнение дерева метаданных. Отсутствует объект, образующий тип %1';
									|en = 'Internal error. Metadata tree is incomplete. Object of the %1 type is missing.';");
			ExceptionText = SubstituteParametersToString(ExceptionText, ReferentialType);
			Raise(ExceptionText);
			
		EndIf;
		
		If VTRow.Export = 1 
			Or VTRow.ExportIfNecessary = 1 Then
			
			Continue;
			
		EndIf;
		
		VTRow.ExportIfNecessary = 1;
		SettingStateExportIfNecessary(VTRow);
						
	EndDo;
	
EndProcedure

Function TotalProcessedRecords()
	
	Return mExportedObjects.Count() + ConstantsProcessed + RecordSetsProcessed;
	
EndFunction

// Returns:
//   ValueTree - Metadata details tree:
//     * Manager - ConstantsManager
//                - CatalogsManager
//                - DocumentsManager
//                - InformationRegistersManager
//                - SequencesManager
//     * Class - String
//     * ToExport - Boolean
//     * ForQuery - String
//     * Properties - ValueList
//     * PictureIndex - Number
// 
Function MetadataDetailsCollection()
	
	MetadataDescription_SSLy = New ValueTree;
	MetadataDescription_SSLy.Columns.Add("Manager");
	MetadataDescription_SSLy.Columns.Add("Class",       New TypeDescription("String",,New StringQualifiers(100, AllowedLength.Variable)));	
	MetadataDescription_SSLy.Columns.Add("ToExport", New TypeDescription("Boolean"));
	MetadataDescription_SSLy.Columns.Add("ForQuery",  New TypeDescription("String"));	
	MetadataDescription_SSLy.Columns.Add("Properties",    New TypeDescription("ValueList"));
	MetadataDescription_SSLy.Columns.Add("PictureIndex");
	
	Return MetadataDescription_SSLy;
	
EndFunction

Function NewMetadataDetailsString(CurCollectionOfStrings, ThereAreChildElements = False)
	
	Result = CurCollectionOfStrings.Add();
	
	If ThereAreChildElements Then
		CurCollectionOfStrings = Result.Rows;
	EndIf;
	
	Return Result;
	
EndFunction

// The procedure fills in a tree of metadata object classes.
//
// Parameters:
//
Procedure FillMetadataDetails()
	
	MetadataDescription_SSLy = MetadataDetailsCollection();
	
	CurCollectionOfStrings = MetadataDescription_SSLy.Rows;
	
	//////////////////////////////////
	// Configurations.
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "Configurations";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.PictureIndex = 0;
	
	//////////////////////////////////
	// Configurations.Constants
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Constants";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = Constants;
	ClassDetails.ForQuery  = "";
	ClassDetails.PictureIndex = 1;
	ClassDetails.Properties.Add("Type");
	
	//////////////////////////////////
	// Configurations.Catalogs
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "Catalogs";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = Catalogs;
	ClassDetails.ForQuery  = "Catalog.";
	ClassDetails.Properties.Add("Owners");
	ClassDetails.Properties.Add("BasedOn");
	ClassDetails.PictureIndex = 3;
	
	//////////////////////////////////
	// Configurations.Catalogs.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	ClassDetails.Properties.Add("Use");
	
	//////////////////////////////////
	// Configurations.Catalogs.TabularSections
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "TabularSections";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Use");
	
	//////////////////////////////////
	// Configurations.Catalogs.TabularSections.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	CurCollectionOfStrings = ClassDetails.Parent.Parent.Parent.Rows;
	
	//////////////////////////////////
	// Configurations.Documents
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "Documents";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = Documents;
	ClassDetails.ForQuery  = "Document.";
	ClassDetails.Properties.Add("BasedOn");
	ClassDetails.Properties.Add("RegisterRecords");
	ClassDetails.PictureIndex = 7;

	//////////////////////////////////
	// Configurations.Documents.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	
	//////////////////////////////////
	// Configurations.Documents.TabularSections
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "TabularSections";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	
	//////////////////////////////////
	// Configurations.Documents.TabularSections.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	CurCollectionOfStrings = ClassDetails.Parent.Parent.Parent.Rows;
	
	//////////////////////////////////
	// Configurations.Sequences
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "Sequences";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = Sequences;
	ClassDetails.ForQuery  = "Sequence.";
	ClassDetails.Properties.Add("Documents");
	ClassDetails.Properties.Add("RegisterRecords");
	ClassDetails.PictureIndex = 5;
	
	//////////////////////////////////
	// Configurations.Sequences.Dimensions
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Dimensions";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	ClassDetails.Properties.Add("DocumentMap");
	ClassDetails.Properties.Add("RegisterRecordsMap");
	CurCollectionOfStrings = ClassDetails.Parent.Parent.Rows;
	
	//////////////////////////////////
	// Configurations.ChartsOfCharacteristicTypes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "ChartsOfCharacteristicTypes";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = ChartsOfCharacteristicTypes;
	ClassDetails.ForQuery  = "ChartOfCharacteristicTypes.";
	ClassDetails.Properties.Add("CharacteristicExtValues");
	ClassDetails.Properties.Add("Type");
	ClassDetails.Properties.Add("BasedOn");
	ClassDetails.PictureIndex = 9;

	//////////////////////////////////
	// Configurations.ChartsOfCharacteristicTypes.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	ClassDetails.Properties.Add("Use");
	
	//////////////////////////////////
	// Configurations.ChartsOfCharacteristicTypes.TabularSections
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "TabularSections";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Use");

	//////////////////////////////////
	// Configurations.ChartsOfCharacteristicTypes.TabularSections.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	CurCollectionOfStrings = ClassDetails.Parent.Parent.Parent.Rows;
	
	//////////////////////////////////
	// Configurations.ChartsOfAccounts
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "ChartsOfAccounts";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = ChartsOfAccounts;
	ClassDetails.ForQuery  = "ChartOfAccounts.";
	ClassDetails.Properties.Add("BasedOn");
	ClassDetails.Properties.Add("ExtDimensionTypes");
	ClassDetails.PictureIndex = 11;
	
	//////////////////////////////////
	// Configurations.ChartsOfAccounts.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	
	//////////////////////////////////
	// Configurations.ChartsOfAccounts.TabularSections
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "TabularSections";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";

	//////////////////////////////////
	// Configurations.ChartsOfAccounts.TabularSections.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	CurCollectionOfStrings = ClassDetails.Parent.Parent.Parent.Rows;
	
	//////////////////////////////////
	// Configurations.ChartsOfCalculationTypes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "ChartsOfCalculationTypes";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = ChartsOfCalculationTypes;
	ClassDetails.ForQuery  = "ChartOfCalculationTypes.";
	ClassDetails.Properties.Add("BasedOn");
	ClassDetails.Properties.Add("DependenceOnCalculationTypes");
	ClassDetails.Properties.Add("BaseCalculationTypes");
	ClassDetails.Properties.Add("ActionPeriodUse");
	ClassDetails.PictureIndex = 13;

	//////////////////////////////////
	// Configurations.ChartsOfCalculationTypes.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	
	//////////////////////////////////
	// Configurations.ChartsOfCalculationTypes.TabularSections
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "TabularSections";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	
	//////////////////////////////////
	// Configurations.ChartsOfCalculationTypes.TabularSections.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	CurCollectionOfStrings = ClassDetails.Parent.Parent.Parent.Rows;
	
	//////////////////////////////////
	// Configurations.InformationRegisters
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "InformationRegisters";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = InformationRegisters;
	ClassDetails.ForQuery  = "InformationRegister.";
	ClassDetails.PictureIndex = 15;

	//////////////////////////////////
	// Configurations.InformationRegisters.Resources
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Resources";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	
	//////////////////////////////////
	// Configurations.InformationRegisters.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	
	//////////////////////////////////
	// Configurations.InformationRegisters.Dimensions
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Dimensions";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	CurCollectionOfStrings = ClassDetails.Parent.Parent.Rows;
	
	//////////////////////////////////
	// Configurations.AccumulationRegisters
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "AccumulationRegisters";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = AccumulationRegisters;
	ClassDetails.ForQuery  = "AccumulationRegister.";
	ClassDetails.PictureIndex = 17;

	//////////////////////////////////
	// Configurations.AccumulationRegisters.Resources
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Resources";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	
	//////////////////////////////////
	// Configurations.AccumulationRegisters.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	
	//////////////////////////////////
	// Configurations.AccumulationRegisters.Dimensions
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Dimensions";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	CurCollectionOfStrings = ClassDetails.Parent.Parent.Rows;
	
	//////////////////////////////////
	// Configurations.AccountingRegisters
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "AccountingRegisters";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = AccountingRegisters;
	ClassDetails.ForQuery  = "AccountingRegister.";
	ClassDetails.Properties.Add("ChartOfAccounts");
	ClassDetails.Properties.Add("Correspondence");
	ClassDetails.PictureIndex = 19;

	//////////////////////////////////
	// Configurations.AccountingRegisters.Dimensions
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Dimensions";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	
	//////////////////////////////////
	// Configurations.AccountingRegisters.Resources
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Resources";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	
	//////////////////////////////////
	// Configurations.AccountingRegisters.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	CurCollectionOfStrings = ClassDetails.Parent.Parent.Rows;
	
	//////////////////////////////////
	// Configurations.CalculationRegisters
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "CalculationRegisters";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = CalculationRegisters;
	ClassDetails.ForQuery  = "CalculationRegister.";
	ClassDetails.Properties.Add("Periodicity");
	ClassDetails.Properties.Add("ActionPeriod");
	ClassDetails.Properties.Add("BasePeriod");
	ClassDetails.Properties.Add("Schedule");
	ClassDetails.Properties.Add("ScheduleValue");
	ClassDetails.Properties.Add("ScheduleDate");
	ClassDetails.Properties.Add("ChartOfCalculationTypes");
	ClassDetails.PictureIndex = 21;

	//////////////////////////////////
	// Configurations.CalculationRegisters.Resources
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Resources";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	
	//////////////////////////////////
	// Configurations.CalculationRegisters.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	ClassDetails.Properties.Add("ScheduleLink");
	
	//////////////////////////////////
	// Configurations.CalculationRegisters.Dimensions
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Dimensions";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	ClassDetails.Properties.Add("BaseDimension");
	ClassDetails.Properties.Add("ScheduleLink");
	
	//////////////////////////////////
	// Configurations.CalculationRegisters.Recalculations.Dimensions
	CurCollectionOfStrings = ClassDetails.Parent.Parent.Rows;
	
	//////////////////////////////////
	// Configurations.BusinessProcesses
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "BusinessProcesses";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = BusinessProcesses;
	ClassDetails.ForQuery  = "BusinessProcess.";
	ClassDetails.Properties.Add("BasedOn");
	ClassDetails.Properties.Add("Task");
	ClassDetails.PictureIndex = 23;
	
	//////////////////////////////////
	// Configurations.BusinessProcesses.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	
	//////////////////////////////////
	// Configurations.BusinessProcesses.TabularSections
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "TabularSections";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	
	//////////////////////////////////
	// Configurations.BusinessProcesses.TabularSections.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	CurCollectionOfStrings = ClassDetails.Parent.Parent.Parent.Rows;
	
	//////////////////////////////////
	// Configurations.Tasks
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "Tasks";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = Tasks;
	ClassDetails.ForQuery  = "Task.";
	ClassDetails.Properties.Add("Addressing");
	ClassDetails.Properties.Add("MainAddressingAttribute");
	ClassDetails.Properties.Add("CurrentPerformer");
	ClassDetails.Properties.Add("BasedOn");
	ClassDetails.PictureIndex = 25;
	
	//////////////////////////////////
	// Configurations.Tasks.AddressingAttributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "AddressingAttributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	ClassDetails.Properties.Add("AddressingDimension");
	
	//////////////////////////////////
	// Configurations.Tasks.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	
	//////////////////////////////////
	// Configurations.Tasks.TabularSections
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "TabularSections";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";

	//////////////////////////////////
	// Configurations.Tasks.TabularSections.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	CurCollectionOfStrings = ClassDetails.Parent.Parent.Parent.Rows;
	
	//////////////////////////////////
	// Configurations.ExchangePlans
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "ExchangePlans";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = ExchangePlans;
	ClassDetails.ForQuery  = "ExchangePlan.";
	ClassDetails.Properties.Add("BasedOn");
	ClassDetails.PictureIndex = 27;

	//////////////////////////////////
	// Configurations.ExchangePlans.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	
	//////////////////////////////////
	// Configurations.ExchangePlans.TabularSections
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings, True);
	ClassDetails.Class = "TabularSections";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";

	//////////////////////////////////
	// Configurations.ExchangePlans.TabularSections.Attributes
	ClassDetails = NewMetadataDetailsString(CurCollectionOfStrings);
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	
	CurCollectionOfStrings = ClassDetails.Parent.Parent.Parent.Rows;
	
EndProcedure

// The function determines whether the passed metadata object has a reference type. Returns:
//
// True if the passed metadata object has a reference type. Otherwise, False.
//
Function ObjectFormsRefType(MetadataObjectsList)
	
	If MetadataObjectsList = Undefined Then
		Return False;
	EndIf;
	
	If Metadata.Catalogs.Contains(MetadataObjectsList)
		Or Metadata.Documents.Contains(MetadataObjectsList)
		Or Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObjectsList)
		Or Metadata.ChartsOfAccounts.Contains(MetadataObjectsList)
		Or Metadata.ChartsOfCalculationTypes.Contains(MetadataObjectsList)
		Or Metadata.ExchangePlans.Contains(MetadataObjectsList)
		Or Metadata.BusinessProcesses.Contains(MetadataObjectsList)
		Or Metadata.Tasks.Contains(MetadataObjectsList) Then
		Return True;
	EndIf;
	
	Return False;
EndFunction

// The procedure determines which object types are to be exported to maintain reference integrity.
//
// Parameters:
//   Upload0 - ValueTable - Set of objects to export.
//
Procedure RecalculateDataToExportByRef(Upload0)
	
	// Clear all ExportIfNecessary flags.
	ConfigurationRow = MetadataTree.Rows[0];
	ConfigurationRow.ExportIfNecessary = 0;
	ProcessingStateChangeExportIfNecessary(ConfigurationRow);
	
	// Data processor of the passed object set.
	For Each ToExport In Upload0 Do
		
		SettingStateExportIfNecessary(ToExport.TreeRow);
				
	EndDo;
	
EndProcedure

// If necessary, the procedure specifies that using totals is not required.
//
Procedure RemoveTotalsUsage()
	
	If AllowResultsUsageEditingRights Then
		
		For Each RegisterWithVT In RegistersWithTotalsCollection() Do
			
			RegisterWithVT.DescriptionItem.Manager[RegisterWithVT.MetadataObjectsList.Name].SetTotalsUsing(False);
			
		EndDo;
		
	EndIf;
	
EndProcedure

// If necessary, the procedure specifies that using totals is required.
//
// Parameters:
//
Procedure RestoreTotalsUsage()
	
	If AllowResultsUsageEditingRights Then
		
		For Each RegisterWithVT In RegistersWithTotalsCollection() Do
			
			RegisterWithVT.DescriptionItem.Manager[RegisterWithVT.MetadataObjectsList.Name].SetTotalsUsing(True);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure MessageToUser(Text)
	
	Message = New UserMessage;
	Message.Text = Text;
	Message.Message();
	
EndProcedure

// Returns:
//   ValueTable - Collection of predefined items:
//     * TableName - String - Infobase table name.
//     * Ref - String - String presentation of the reference.
//     * PredefinedDataName - String - Value ID.
// 
Function CollectionPredefinedData()
	Return PredefinedDataTable;
EndFunction

Procedure InitializeTableOfPredefinedItems()
	
	PredefinedDataTable = New ValueTable;
	PredefinedDataTable.Columns.Add("TableName");
	PredefinedDataTable.Columns.Add("Ref");
	PredefinedDataTable.Columns.Add("PredefinedDataName");
	
EndProcedure

Procedure ExportPredefinedItemsTable(XMLWriter)
	
	XMLWriter.WriteStartElement("PredefinedData");
	
	If PredefinedDataTable.Count() > 0 Then
		
		PredefinedDataTable.Sort("TableName");
		
		NameOfPreviousTable = "";
		
		For Each Item In PredefinedDataTable Do
			
			If NameOfPreviousTable <> Item.TableName Then
				If Not IsBlankString(NameOfPreviousTable) Then
					XMLWriter.WriteEndElement();
				EndIf;
				XMLWriter.WriteStartElement(Item.TableName);
			EndIf;
			
			XMLWriter.WriteStartElement("item");
			XMLWriter.WriteAttribute("Ref", Item.Ref);
			XMLWriter.WriteAttribute("PredefinedDataName", Item.PredefinedDataName);
			XMLWriter.WriteEndElement();
			
			NameOfPreviousTable = Item.TableName;
			
		EndDo;
		
		XMLWriter.WriteEndElement();
		
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure DownloadPredefinedTable(XMLReader)
	
	XMLReader.Skip(); // Skip the main data block during the first reading.
	XMLReader.Read();
	
	InitializeTableOfPredefinedItems();
	TimeLine_ = CollectionPredefinedData().Add();
	
	MatchingReplacementLinks = New Map;
	
	QueryTextTemplate2 =
	"SELECT
	|	Table.Ref AS Ref
	|FROM
	|	&MetadataTableName AS Table
	|WHERE
	|	Table.PredefinedDataName = &PredefinedDataName";
	
	While XMLReader.Read() Do
		
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			
			If XMLReader.LocalName <> "item" Then
				
				TimeLine_.TableName = XMLReader.LocalName;
				
				QueryText = StrReplace(QueryTextTemplate2, "&MetadataTableName", TimeLine_.TableName);
				Query = New Query(QueryText);
				
			Else
				
				While XMLReader.ReadAttribute() Do
					
					TimeLine_[XMLReader.LocalName] = XMLReader.Value;
					
				EndDo;
				
				Query.SetParameter("PredefinedDataName", TimeLine_.PredefinedDataName);
				
				QueryResult = Query.Execute();
				If Not QueryResult.IsEmpty() Then
					
					Selection = QueryResult.Select();
					
					If Selection.Count() = 1 Then
						
						Selection.Next();
						
						LinkInDatabase = XMLString(Selection.Ref);
						LinkInFile = TimeLine_.Ref;
						
						If LinkInDatabase <> LinkInFile Then
							
							XMLType = XMLRefType(Selection.Ref);
							
							TypeMap = MatchingReplacementLinks.Get(XMLType);
							
							If TypeMap = Undefined Then
								
								TypeMap = New Map;
								TypeMap.Insert(LinkInFile, LinkInDatabase);
								MatchingReplacementLinks.Insert(XMLType, TypeMap);
								
							Else
								
								TypeMap.Insert(LinkInFile, LinkInDatabase);
								
							EndIf;
							
						EndIf;
						
					Else
						
						ExceptionText = NStr("ru = 'Обнаружено дублирование предопределенных элементов %1 в таблице %2.';
												|en = 'Duplicate predefined items %1 are found in table %2.';");
						ExceptionText = StrReplace(ExceptionText, "%1", TimeLine_.PredefinedDataName);
						ExceptionText = StrReplace(ExceptionText, "%2", TimeLine_.TableName);
						
						Raise ExceptionText;
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	XMLReader.Close();
	
EndProcedure

Function ReplaceLinksWithPredefinedOnes(FileName)
	
	ReaderStream = New TextReader(FileName);
	
	TempFile = GetTempFileName("xml");
	
	WriteStream = New TextWriter(TempFile);
	
	// Constants for text parsing.
	BeginningOfType = "xsi:type=""v8:";
	TypeStartLength = StrLen(BeginningOfType);
	EndOfType = """>";
	TypeEndLength = StrLen(EndOfType);
	
	InitialString = ReaderStream.ReadLine();
	While InitialString <> Undefined Do
		
		RowBalance = Undefined;
		
		CurrentPosition = 1;
		TypePosition = StrFind(InitialString, BeginningOfType);
		While TypePosition > 0 Do
			
			WriteStream.Write(Mid(InitialString, CurrentPosition, TypePosition - 1 + TypeStartLength));
			
			RowBalance = Mid(InitialString, CurrentPosition + TypePosition + TypeStartLength - 1);
			CurrentPosition = CurrentPosition + TypePosition + TypeStartLength - 1;
			
			PositionOfEndOfType = StrFind(RowBalance, EndOfType);
			If PositionOfEndOfType = 0 Then
				Break;
			EndIf;
			
			TypeName = Left(RowBalance, PositionOfEndOfType - 1);
			ReplacementCompliance = MatchingReplacementLinks.Get(TypeName);
			If ReplacementCompliance = Undefined Then
				TypePosition = StrFind(RowBalance, BeginningOfType);
				Continue;
			EndIf;
			
			WriteStream.Write(TypeName);
			WriteStream.Write(EndOfType);
			
			OriginalXMLLink = Mid(RowBalance, PositionOfEndOfType + TypeEndLength, 36);
			
			XMLLinkFound = ReplacementCompliance.Get(OriginalXMLLink);
			
			If XMLLinkFound = Undefined Then
				WriteStream.Write(OriginalXMLLink);
			Else
				WriteStream.Write(XMLLinkFound);
			EndIf;
			
			CurrentPosition = CurrentPosition + PositionOfEndOfType - 1 + TypeEndLength + 36;
			RowBalance = Mid(RowBalance, PositionOfEndOfType + TypeEndLength + 36);
			TypePosition = StrFind(RowBalance, BeginningOfType);
			
		EndDo;
		
		If RowBalance <> Undefined Then
			WriteStream.WriteLine(RowBalance);
		Else
			WriteStream.WriteLine(InitialString);
		EndIf;
		
		InitialString = ReaderStream.ReadLine();
		
	EndDo;
	
	ReaderStream.Close();
	WriteStream.Close();
	
	Return TempFile;
	
EndFunction

Function ThisIsMetadataWithPredefinedElements(MetadataObject)
	
	Return Metadata.Catalogs.Contains(MetadataObject)
		Or Metadata.ChartsOfAccounts.Contains(MetadataObject)
		Or Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject)
		Or Metadata.ChartsOfCalculationTypes.Contains(MetadataObject);
	
EndFunction

Procedure InitializeXDTOSerializerWithTypesAnnotation()
	
	TypesWithAnnotatedLinks = PredefinedTypesWhenUnloading();
	
	If TypesWithAnnotatedLinks.Count() > 0 Then
		
		Factory = GetFactoryWithTypesSpecified(TypesWithAnnotatedLinks);
		Serializer = New XDTOSerializer(Factory);
		
	Else
		
		Serializer = XDTOSerializer;
		
	EndIf;
	
EndProcedure

Function PredefinedTypesWhenUnloading()
	
	Types = New Array;
	
	For Each MetadataObject In Metadata.Catalogs Do
		Types.Add(MetadataObject);
	EndDo;
	
	For Each MetadataObject In Metadata.ChartsOfAccounts Do
		Types.Add(MetadataObject);
	EndDo;
	
	For Each MetadataObject In Metadata.ChartsOfCharacteristicTypes Do
		Types.Add(MetadataObject);
	EndDo;
	
	For Each MetadataObject In Metadata.ChartsOfCalculationTypes Do
		Types.Add(MetadataObject);
	EndDo;
	
	Return Types;
	
EndFunction

// Returns an XDTO factory and its types.
//
// Parameters:
//  Types - FixedArray of MetadataObject - Array of types.
//
// Returns:
//  XDTOFactory - XDTO factory.
//
Function GetFactoryWithTypesSpecified(Val Types)
	
	SetOfSchemes = XDTOFactory.ExportXMLSchema("http://v8.1c.ru/8.1/data/enterprise/current-config");
	Schema = SetOfSchemes[0];
	Schema.UpdateDOMElement();
	
	SpecifiedTypes = New Map;
	For Each Type In Types Do
		SpecifiedTypes.Insert(XMLRefType(Type), True);
	EndDo;
	
	Namespace = New Map;
	Namespace.Insert("xs", "http://www.w3.org/2001/XMLSchema");
	DOMNamespaceResolver = New DOMNamespaceResolver(Namespace);
	XPathText = "/xs:schema/xs:complexType/xs:sequence/xs:element[starts-with(@type,'tns:')]";
	
	Query = Schema.DOMDocument.CreateXPathExpression(XPathText, DOMNamespaceResolver);
	Result = Query.Evaluate(Schema.DOMDocument);

	While True Do
		
		FieldNode_ = Result.IterateNext();
		If FieldNode_ = Undefined Then
			Break;
		EndIf;
		AttributeType = FieldNode_.Attributes.GetNamedItem("type");
		TypeWithoutNSPrefix = Mid(AttributeType.TextContent, StrLen("tns:") + 1);
		
		If SpecifiedTypes.Get(TypeWithoutNSPrefix) = Undefined Then
			Continue;
		EndIf;
		
		FieldNode_.SetAttribute("nillable", "true");
		FieldNode_.RemoveAttribute("type");
	EndDo;
	
	XMLWriter = New XMLWriter;
	SchemaFileName = GetTempFileName("xsd");
	XMLWriter.OpenFile(SchemaFileName);
	DOMWriter = New DOMWriter;
	DOMWriter.Write(Schema.DOMDocument, XMLWriter);
	XMLWriter.Close();
	
	Factory = CreateXDTOFactory(SchemaFileName);
	
	DeleteFiles(SchemaFileName);
	
	Return Factory;
	
EndFunction

// Returns the name of the type that will be used in an XML file for the specified metadata object.
// Used to search and replace references upon import, and to edit current-config schema upon writing.
// 
// Parameters:
//  Value - MetadataObject
//           - AnyRef - Metadata object or Ref.
//
// Returns:
//  String - String that describes a metadata object (in a format similar to AccountingRegisterRecordSet.SelfFinancing).
//
Function XMLRefType(Val Value)
	
	If TypeOf(Value) = Type("MetadataObject") Then
		MetadataObject = Value;
		ObjectManager = ObjectManagerByFullName(MetadataObject.FullName());
		Ref = ObjectManager.GetRef();
	Else
		MetadataObject = Value.Metadata();
		Ref = Value;
	EndIf;
	
	If ObjectFormsRefType(MetadataObject) Then
		
		Return XDTOSerializer.XMLTypeOf(Ref).TypeName;
		
	Else
		
		ExceptionText = NStr("ru = 'Ошибка при определении XMLТипа ссылки для объекта %1: объект не является ссылочным.';
								|en = 'Error determining XML Ref type for object %1: this is not a reference object.';");
		ExceptionText = StrReplace(ExceptionText, "%1", MetadataObject.FullName());
		
		Raise ExceptionText;
		
	EndIf;
	
EndFunction

// Returns an object manager by the passed full name of a metadata object.
// Limitation: Does not process business process route points.
//
// Parameters:
//  FullName - String - Full name of metadata object. Example: "Catalog.Company".
//
// Returns:
//  CatalogManager, DocumentManager.
//
Function ObjectManagerByFullName(FullName)
	
	NameParts = SplitStringIntoSubstringsArray(FullName);
	
	If NameParts.Count() >= 2 Then
		MOClass = NameParts[0];
		MetadataObjectName1 = NameParts[1];
	EndIf;
	
	If Upper(MOClass) = "CATALOG" Then
		Manager = Catalogs;
	ElsIf Upper(MOClass) = "CHARTOFCHARACTERISTICTYPES" Then
		Manager = ChartsOfCharacteristicTypes;
	ElsIf Upper(MOClass) = "CHARTOFACCOUNTS" Then
		Manager = ChartsOfAccounts;
	ElsIf Upper(MOClass) = "CHARTOFCALCULATIONTYPES" Then
		Manager = ChartsOfCalculationTypes;
	EndIf;
	
	Return Manager[MetadataObjectName1];
	
EndFunction

Function SubstituteParametersToString(Val SubstitutionString,
	Val Parameter1, Val Parameter2 = Undefined, Val Parameter3 = Undefined)
	
	SubstitutionString = StrReplace(SubstitutionString, "%1", Parameter1);
	SubstitutionString = StrReplace(SubstitutionString, "%2", Parameter2);
	SubstitutionString = StrReplace(SubstitutionString, "%3", Parameter3);
	
	Return SubstitutionString;
EndFunction

Function SplitStringIntoSubstringsArray(Val Page1, Separator = ".")
	
	RowsArray = New Array();
	SeparatorLength = StrLen(Separator);
	While True Do
		Pos = StrFind(Page1, Separator);
		If Pos = 0 Then
			If (TrimAll(Page1) <> "") Then
				RowsArray.Add(Page1);
			EndIf;
			Return RowsArray;
		EndIf;
		RowsArray.Add(Left(Page1,Pos - 1));
		Page1 = Mid(Page1, Pos + SeparatorLength);
	EndDo;
	
EndFunction

Function EvalExpression(Val Expression)
	
	SetSafeMode(True);
	For Each SeparatorName In ConfigurationSeparators Do
		SetDataSeparationSafeMode(SeparatorName, True);
	EndDo;
	
	// Don't call CalculateInSafeMode because the safe mode is set without using SSL.
	Return Eval(Expression);
	
EndFunction

// Initializes data processor attributes and module variables.
//
// Parameters:
//  None.
// 
Procedure InitAttributesAndModuleVariables()
	
	UseDataExchangeModeOnImport    = True;
	ContinueImportOnError = False;
	UseFilterByDateForAllObjects       = True;

	mSubordinateObjectsExportExists     = False;
	mLastSavedDataExportedCount = 50;

	mQueryResultType = Type("QueryResult");
	mDeletionDataType   = Type("ObjectDeletion");

	mRegisteredRecordsColumnsMap = New Map;

	ConstantsProcessed       = 0;
	RecordSetsProcessed = 0;

	ConfigurationSeparators = New Array;
	For Each CommonAttribute In Metadata.CommonAttributes Do
		If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
			ConfigurationSeparators.Add(CommonAttribute.Name);
		EndIf;
	EndDo;
	ConfigurationSeparators = New FixedArray(ConfigurationSeparators);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Base functionality procedures and functions for standalone mode support.

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
		Raise SubstituteParametersToString(NStr("ru = 'Общий модуль ""%1"" не найден.';
															|en = 'Common module %1 is not found.';"), Name);
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

#Region Initialize

InitAttributesAndModuleVariables();

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf