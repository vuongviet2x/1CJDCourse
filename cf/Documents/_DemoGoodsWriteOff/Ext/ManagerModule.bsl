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
	PrintCommand.Id = "ActOfDebitingGoods";
	PrintCommand.Presentation = NStr("ru = 'Акт о списании товаров';
										|en = 'Retirement certificate';");
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

	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActOfDebitingGoods") Then

		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection, 
			"ActOfDebitingGoods",
			NStr("ru = 'Акт о списании товаров';
				|en = 'Retirement certificate';"),
			GeneratePrintedFormForDebitingGoods(ObjectsArray, PrintObjects));
				
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
	|	AND ValueAllowed(StorageLocation)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(EmployeeResponsible)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.AttachableCommands

// Defines the list of generation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
EndProcedure

// Intended for use by the AddGenerationCommands procedure in other object manager modules.
// Adds this object to the list of generation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - Details of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents._DemoGoodsWriteOff);
	
EndFunction

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#Region Private

Function GeneratePrintedFormForDebitingGoods(ObjectsArray, PrintObjects)

	Query = New Query;
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.Text =
	"SELECT
	|	Document_DemoGoodsWriteOff.Ref AS Ref,
	|	Document_DemoGoodsWriteOff.Number AS Number,
	|	Document_DemoGoodsWriteOff.Date AS Date,
	|	Document_DemoGoodsWriteOff.StorageLocation AS Warehouse,
	|	Document_DemoGoodsWriteOff.Organization AS Organization,
	|	PRESENTATION(Document_DemoGoodsWriteOff.StorageLocation) AS WarehousePresentation,
	|	Document_DemoGoodsWriteOff.Organization.Description AS OrganizationPresentation,
	|	Document_DemoGoodsWriteOff.Organization.Prefix AS Prefix,
	|	Document_DemoGoodsWriteOff.StorageLocation.FinanciallyLiablePerson AS Warehouseman,
	|	Document_DemoGoodsWriteOff.EmployeeResponsible AS EmployeeResponsible
	|FROM
	|	Document._DemoGoodsWriteOff AS Document_DemoGoodsWriteOff
	|WHERE
	|	Document_DemoGoodsWriteOff.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsConsumption.Ref AS Ref,
	|	GoodsConsumption.LineNumber AS LineNumber,
	|	GoodsConsumption.Products AS Products,
	|	GoodsConsumption.Count AS Count,
	|	GoodsConsumption.Products.Description AS ProductsPresentation
	|FROM
	|	Document._DemoGoodsWriteOff.Goods AS GoodsConsumption
	|WHERE
	|	GoodsConsumption.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|TOTALS BY
	|	Ref";
	
	SetPrivilegedMode(True);
	Results = Query.ExecuteBatch(); // Array of QueryResult
	SelectionByDocuments = Results.Get(0).Select();
	ProductSelection_1 	= Results.Get(1).Select(QueryResultIteration.ByGroups);
	
	DocumentAttributes 	= New Structure("Number, Date, Prefix");
	DocumentSynonym 	= NStr("ru = 'Акт о списании товаров';
								|en = 'Retirement certificate';");
	
	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PRINTPARAMETERSGoodsWriteOffGoodsWriteOffNote";
	
	Template = PrintManagement.PrintFormTemplate("Document._DemoGoodsWriteOff.PF_MXL_GoodsWriteOffNote");
	HeaderArea_ = Template.GetArea("Title");
	
	AreaOfHeaderNumber = Template.GetArea("TableHeader|LineNumber");
	ProductAreaHeader  = Template.GetArea("TableHeader|OwnGoods");
	AreaDataHeader = Template.GetArea("TableHeader|Data");
	Template.Area("OwnGoods").ColumnWidth = Template.Area("OwnGoods").ColumnWidth
		+ Template.Area("ColumnOfCodes").ColumnWidth;
	NumberAreaLine = Template.GetArea("String|LineNumber");
	ProductLineArea_  = Template.GetArea("String|OwnGoods");
	DataAreaRow = Template.GetArea("String|Data");
	
	RoomAreaBasementTable = Template.GetArea("TableFooter|LineNumber");
	ProductAreaTableBasement  = Template.GetArea("TableFooter|OwnGoods");
	DataAreaTableBasement = Template.GetArea("TableFooter|Data");
	
	LabelArea       	= Template.GetArea("Signatures");
	AreaTotalQuantity 	= Template.GetArea("TotalCount1");
	
	FirstDocument = True;
	While SelectionByDocuments.Next() Do
		
		If Not FirstDocument Then
			TabDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		
		RowNumberStart = TabDocument.TableHeight + 1;
		
		FillPropertyValues(DocumentAttributes, SelectionByDocuments);
		
		AddlHeaderParameters = New Structure;
		AddlHeaderParameters.Insert("TitleText", GenerateDocumentTitle(DocumentAttributes, DocumentSynonym));
		
		HeaderArea_.Parameters.Fill(SelectionByDocuments);
		HeaderArea_.Parameters.Fill(AddlHeaderParameters);
		
		TabDocument.Put(HeaderArea_);
		
		// Display lines.
		If Not ProductSelection_1.FindNext(New Structure("Ref",SelectionByDocuments.Ref)) Then
			Continue;
		EndIf;
		
		// Display header.
		TabDocument.Put(AreaOfHeaderNumber);
		
		TabDocument.Join(ProductAreaHeader);
		TabDocument.Join(AreaDataHeader);
		
		TotalItems_1 = 0;
		
		SelectionByLines = ProductSelection_1.Select(QueryResultIteration.ByGroups);
		While SelectionByLines.Next() Do
			NumberAreaLine.Parameters.Fill(SelectionByLines);
			TabDocument.Put(NumberAreaLine);
			
			// Products.
			ProductLineArea_.Parameters.Products = SelectionByLines.Products;
			ProductLineArea_.Parameters.ProductsPresentation = SelectionByLines.Products;
			TabDocument.Join(ProductLineArea_);
			// Quantity data.
			DataAreaRow.Parameters.Fill(SelectionByLines);
			TabDocument.Join(DataAreaRow);
			TotalItems_1 = TotalItems_1 + 1;
		EndDo;
		
		// Display totals.
		TabDocument.Put(RoomAreaBasementTable);
		TabDocument.Join(ProductAreaTableBasement);
		TabDocument.Join(DataAreaTableBasement);
		TextOfResultingLine = NStr("ru = 'Всего наименований %TotalItems_1%';
									|en = 'Total items %TotalItems_1%';");
		TextOfResultingLine = StrReplace(TextOfResultingLine,"%TotalItems_1%", TotalItems_1);
		AreaTotalQuantity.Parameters.TotalString = TextOfResultingLine;
		TabDocument.Put(AreaTotalQuantity);
		
		// Display signatures.
		LabelArea.Parameters.EmployeeResponsible = SelectionByDocuments.EmployeeResponsible;
		LabelArea.Parameters.Warehouseman = SelectionByDocuments.Warehouseman;
		TabDocument.Put(LabelArea);
		
		PrintManagement.SetDocumentPrintArea(TabDocument, RowNumberStart, PrintObjects, SelectionByDocuments.Ref);
		
	EndDo;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return TabDocument;
	
EndFunction

// Returns a document title in the form it is generated by the platform to present a document reference.
//
// Parameters:
//  Header - Structure:
//          Number - String, Number - Document number.
//          Date - Date - Document date.
//  DocumentName_1 - String - Document name (for example, metadata object synonym).
//
// Returns: 
//  String - Document title.
//
Function GenerateDocumentTitle(Header, Val DocumentName_1 = "", RemoveOnlyLeadingZerosFromObjectNumber = False)
	
	DocumentData = New Structure("Number,Date,Presentation");
	FillPropertyValues(DocumentData, Header);
	
	// If the document name is not passed explicitly, get it from the document presentation.
	If IsBlankString(DocumentName_1) And ValueIsFilled(DocumentData.Presentation) Then
		NumberPosition = StrFind(DocumentData.Presentation, DocumentData.Number);
		If NumberPosition > 0 Then
			DocumentName_1 = TrimAll(Left(DocumentData.Presentation, NumberPosition - 1));
		EndIf;
	EndIf;

	If RemoveOnlyLeadingZerosFromObjectNumber Then
		NumberForPrinting = ObjectsPrefixesClientServer.DeleteLeadingZerosFromObjectNumber(DocumentData.Number);
	Else 
		// Delete leading zeroes, company prefix, and an infobase prefix.
		NumberForPrinting = ObjectsPrefixesClientServer.NumberForPrinting(DocumentData.Number);
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 № %2 от %3';
																		|en = '%1 #%2, %3';"),
		DocumentName_1, NumberForPrinting, Format(DocumentData.Date, "DLF=DD"));
	
EndFunction

#EndRegion

#EndIf
