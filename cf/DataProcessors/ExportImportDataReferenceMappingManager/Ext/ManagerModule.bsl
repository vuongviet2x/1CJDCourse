#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Procedure PerformStandardLinkMatching(LinkReplacementFlow, Val MetadataObject, Val SourceRefsTable, Val RefsMapManager) Export
	
	XMLTypeName1 = ExportImportDataInternal.XMLRefType(MetadataObject);
	
	SourceLinkColumnName = RefsMapManager.SourceLinkColumnName_();
	
	Selection = FetchingLinkMatching(MetadataObject, SourceRefsTable, SourceLinkColumnName);
	
	While Selection.Next() Do
		
		LinkReplacementFlow.ReplaceRef(XMLTypeName1, String(Selection[SourceLinkColumnName].UUID()),
			String(Selection.Ref.UUID()));
		
	EndDo;
	
EndProcedure

// Parameters:
// 	MetadataObject - MetadataObject - Metadata object.
// 	SourceRefsTable - ValueTable - source references.
// 	SourceLinkColumnName - String - a column name.
// Returns:
// 	QueryResultSelection - Mapping to object fields:
//	 * Ref - AnyRef - reference to object.
Function FetchingLinkMatching(Val MetadataObject, Val SourceRefsTable, Val SourceLinkColumnName) Export
	
	KeyFields = New Array();
	For Each KeyColumn In SourceRefsTable.Columns Do
		If KeyColumn.Name <> SourceLinkColumnName Then
			KeyFields.Add(KeyColumn.Name);
		EndIf;
	EndDo;
	
	TextOfMatchingRequest = GenerateTextOfLinkMatchingRequestUsingNaturalKeys(
		MetadataObject, SourceRefsTable.Columns, SourceLinkColumnName);
	
	Query = New Query(TextOfMatchingRequest);
	Query.SetParameter("SourceRefsTable", SourceRefsTable);
	
	Return Query.Execute().Select();
	
EndFunction

#EndRegion

#Region Private

// Generating a query to get shared data references in the infobase
//
// Returns:
//  String - Query text. 
//
Function GenerateTextOfLinkMatchingRequestUsingNaturalKeys(Val MetadataObject, Val Columns, Val SourceLinkColumnName)
	
	QueryText = StrReplace(
		"SELECT
		|	SourceRefsTable.*
		|INTO SourceLinks
		|FROM
		|	&SourceRefsTable AS SourceRefsTable;
		|SELECT
		|	&FieldName,
		|	_XMLLoading_Table.Ref AS Ref
		|FROM
		|	SourceLinks AS SourceLinks" + "
		|	INNER JOIN &ObjectTable AS _XMLLoading_Table 
		|	ON NOT _XMLLoading_Table.DeletionMark ", 
			"&ObjectTable", MetadataObject.FullName());
	
	For Each Column In Columns Do 
		
		If Column.Name = SourceLinkColumnName Then 
			Continue;
		EndIf;
		
		QueryText = QueryText + "AND (SourceLinks.%KeyName = _XMLLoading_Table.%KeyName) ";
		QueryText = StrReplace(QueryText, "%KeyName",          Column.Name);
		
	EndDo;
	
	QueryText = StrReplace(QueryText, "&FieldName",
		StrTemplate("SourceLinks.%1 AS %1", SourceLinkColumnName));
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf