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

	FillInDocumentViewSelectionList();

	If Parameters.FilterDocumentsKinds.Count() > 0 Then

		For Each DocumentKind In DocumentsKindsTable Do
			DocumentKind.Filter = False;
		EndDo;

		For Each DocumentKind In Parameters.FilterDocumentsKinds Do
			Filter = New Structure("DocumentKind", DocumentKind.Value);
			FoundRows = DocumentsKindsTable.FindRows(Filter);
			If ValueIsFilled(FoundRows) Then
				For Each String In FoundRows Do
					String.Filter = True;
				EndDo;
			EndIf;
		EndDo;
		
	Else
		
		For Each DocumentKind In DocumentsKindsTable Do
			DocumentKind.Filter = True;
		EndDo;
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WillSelectAllCheckBoxes(Command)

	For Each CurrentFilter In DocumentsKindsTable Do
		CurrentFilter.Filter = True;
	EndDo;

EndProcedure

&AtClient
Procedure ClearAllCheckBoxes(Command)

	For Each CurrentFilter In DocumentsKindsTable Do
		CurrentFilter.Filter = False;
	EndDo;

EndProcedure

&AtClient
Procedure AllTypesOfDocumentsOK(Command)

	FillInListOfDocumentsByDocumentType();
	Result = New Structure("FilterDocumentsKinds,DocumentsCount",FilterDocumentsKinds,DocumentsKindsTable.Count());
	Close(Result);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInDocumentViewSelectionList()

	TableOfSpecies = FormAttributeToValue("DocumentsKindsTable");
	TableOfSpecies.Clear();

	AvailableTypes = Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type.Types();
	DocumentNames = New Array;
	For Each Type In AvailableTypes Do
		If Type = Type("CatalogRef.MetadataObjectIDs") Then
			Continue;
		EndIf;
		DocumentType = Metadata.FindByType(Type);
		DocumentNames.Add(DocumentType.FullName());
	EndDo;
	
	Query = New Query;
	Query.Text = "SELECT
	               |	MetadataObjectIDs.FullName AS FullName,
	               |	MetadataObjectIDs.Synonym AS Synonym,
	               |	MetadataObjectIDs.Ref AS Ref
	               |FROM
	               |	Catalog.MetadataObjectIDs AS MetadataObjectIDs
	               |WHERE
	               |	MetadataObjectIDs.FullName IN(&DocumentNames)";
	Query.SetParameter("DocumentNames",DocumentNames);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Filter = New Structure("Presentation", Selection.Synonym);
		FoundRows = TableOfSpecies.FindRows(Filter);
		If FoundRows.Count()= 0 Then
			NewRow = TableOfSpecies.Add();
			NewRow.DocumentKind = Selection.Ref;
			NewRow.Presentation = Selection.Synonym;
			NewRow.Filter = True;
		EndIf;
	EndDo;

	TableOfSpecies.Sort("Presentation");
	ValueToFormAttribute(TableOfSpecies, "DocumentsKindsTable");
	
EndProcedure

&AtServer
Procedure FillInListOfDocumentsByDocumentType()

	FilterDocumentsKinds.Clear();
	
	For Each DocumentKind In DocumentsKindsTable Do
			If DocumentKind.Filter = True Then
				FilterDocumentsKinds.Add(DocumentKind.DocumentKind,DocumentKind.Presentation);
			EndIf;
	EndDo;

	If FilterDocumentsKinds.Count() = 0 Then
		For Each DocumentKind In DocumentsKindsTable Do
			FilterDocumentsKinds.Add(DocumentKind.DocumentKind,DocumentKind.Presentation);
		EndDo;
	EndIf;

EndProcedure

#EndRegion

