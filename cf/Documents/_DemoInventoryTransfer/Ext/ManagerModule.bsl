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

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.Print

// Overrides object's print settings.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// Populates a list of print commands.
// 
// Parameters:
//  PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "TransferNote";
	PrintCommand.Presentation = NStr("ru = 'Накладная на перемещение';
										|en = 'Transfer note';");
	PrintCommand.CheckPostingBeforePrint = True;
	
EndProcedure

// Generates print forms.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export

	// Print a transfer note.
	TemplatePrintRequired = PrintManagement.TemplatePrintRequired(PrintFormsCollection, "TransferNote");
	If TemplatePrintRequired Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"TransferNote",
			NStr("ru = 'Накладная на перемещение';
				|en = 'Transfer note';"),
			GoodsTransferPrintForm(ObjectsArray, PrintObjects),
			,
			"Document._DemoInventoryTransfer.PF_MXL_TransferNote");
	EndIf;
		
EndProcedure

// End StandardSubsystems.Print

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowRead
	|WHERE
	|	ValueAllowed(Organization)
	|	AND (     ValueAllowed(StorageSource)
	|	    OR ValueAllowed(StorageLocationDestination))
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(StorageSource)
	|	AND ValueAllowed(StorageLocationDestination)
	|	AND ValueAllowed(EmployeeResponsible)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

Function GoodsTransferPrintForm(ObjectsArray, PrintObjects)
	
	QueryText = 
	"SELECT
	|	_DemoInventoryTransfer.Ref,
	|	_DemoInventoryTransfer.Number,
	|	_DemoInventoryTransfer.Date,
	|	_DemoInventoryTransfer.StorageSource,
	|	_DemoInventoryTransfer.StorageLocationDestination,
	|	_DemoInventoryTransfer.Organization,
	|	_DemoInventoryTransfer.EmployeeResponsible,
	|	_DemoInventoryTransfer.Goods.(
	|		LineNumber,
	|		Products,
	|		Count
	|	)
	|FROM
	|	Document._DemoInventoryTransfer AS _DemoInventoryTransfer
	|WHERE
	|	_DemoInventoryTransfer.Ref IN (&DocumentsList)";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentsList", ObjectsArray);
	
	Header = Query.Execute().Select();
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "TransferNote";
	
	Template = PrintManagement.PrintFormTemplate("Document._DemoInventoryTransfer.PF_MXL_TransferNote");
	
	While Header.Next() Do
		If SpreadsheetDocument.TableHeight > 0 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		PrintData = New Structure;
		
		TitleText = GenerateDocumentTitle(Header, NStr("ru = 'Демо: Перемещение товаров';
																	|en = 'Demo: Goods transfer';"));
		PrintData.Insert("TitleText", TitleText);
		PrintData.Insert("OrganizationPresentation", Header.Organization);
		PrintData.Insert("SenderPresentation", Header.StorageSource);
		PrintData.Insert("RecipientPresentation", Header.StorageLocationDestination);
		
		GoodsTable = Header.Goods.Unload();
		
		ArrayOfLayoutAreas = New Array;
		ArrayOfLayoutAreas.Add("Title");
		ArrayOfLayoutAreas.Add("TableHeader");
		ArrayOfLayoutAreas.Add("String");
		ArrayOfLayoutAreas.Add("Footer");
		ArrayOfLayoutAreas.Add("Signatures");
		
		For Each AreaName In ArrayOfLayoutAreas Do
			TemplateArea = Template.GetArea(AreaName);
			If AreaName <> "String" Then
				FillPropertyValues(TemplateArea.Parameters, PrintData);
				SpreadsheetDocument.Put(TemplateArea);
			Else
				For Each TableRow In GoodsTable Do
					TemplateArea.Parameters.Fill(TableRow);
					SpreadsheetDocument.Put(TemplateArea);
				EndDo;
			EndIf;
		EndDo;

		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, Header.Ref);
	
	EndDo;
	
	Return SpreadsheetDocument;
	
	
EndFunction

// Returns the document title for a print form.
//
// Parameters:
//  Header - A structure with the following fields:
//           Number - String, Number - Document number.
//           Date - Date - Document date.
//           Presentation - String - Optional. Platform presentation of the document reference.
//                                    If DocumentName is not specified, the name will be parsed from this parameter.
//                                    
//  DocumentName_1 - String - Document name (for example, "Proforma invoice").
//
// Returns:
//  String - Document title.
//
Function GenerateDocumentTitle(Header, Val DocumentName_1 = "")
	
	DocumentData = New Structure("Number,Date,Presentation");
	FillPropertyValues(DocumentData, Header);
	
	// If the document name is not passed explicitly, get it from the document presentation.
	If IsBlankString(DocumentName_1) And ValueIsFilled(DocumentData.Presentation) Then
		NumberPosition = StrFind(DocumentData.Presentation, DocumentData.Number);
		If NumberPosition > 0 Then
			DocumentName_1 = TrimAll(Left(DocumentData.Presentation, NumberPosition - 1));
		EndIf;
	EndIf;

	NumberForPrinting = ObjectsPrefixesClientServer.NumberForPrinting(DocumentData.Number);
	
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 № %2 от %3';
																		|en = '%1 #%2, %3';"),
		DocumentName_1, NumberForPrinting, Format(DocumentData.Date, "DLF=DD"));
	
EndFunction

#EndRegion

#EndIf
