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

#Region UpdateHandlers

// Registers data for update in the InfobaseUpdate exchange plan.
//
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export

	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	DemoSaleOfGoodsGoods.Ref AS Ref
		|FROM
		|	Document._DemoGoodsSales.Goods AS DemoSaleOfGoodsGoods
		|WHERE
		|	DemoSaleOfGoodsGoods.DimensionKey = VALUE(Catalog._DemoProductDimensionKeys.EmptyRef)";
	
	QueryResult = Query.Execute();
	
	ObjectsToBeProcessed = QueryResult.Unload().UnloadColumn("Ref");

	If ObjectsToBeProcessed.Count() > 0 Then
		InfobaseUpdate.MarkForProcessing(Parameters, ObjectsToBeProcessed);
	EndIf;
	
EndProcedure

// Processes data registered in the InfobaseUpdate exchange plan.
//
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	Parameters.ProcessingCompleted  = False;
	GoodsSales = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, Metadata.Documents._DemoGoodsSales.FullName());
	
	While GoodsSales.Next() Do
		RepresentationOfTheReference = String(GoodsSales.Ref);
		Try
			
			FillInAnalyticsKeys(GoodsSales);
			ObjectsProcessed = ObjectsProcessed + 1;
			
		Except
			// If an order is failed to process, try again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			InfobaseUpdate.WriteErrorToEventLog(
				GoodsSales.Ref,
				RepresentationOfTheReference,
				ErrorInfo());
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Document._DemoGoodsSales");
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось обработать некоторые заказы покупателей (пропущены): %1';
				|en = 'Couldn''t process (skipped) some sales orders: %1';"), 
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Documents._DemoSalesOrder,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Обработана очередная порция заказов покупателей: %1';
					|en = 'Yet another batch of sales orders is processed: %1';"),
				ObjectsProcessed));
	EndIf;
	

EndProcedure

#EndRegion


#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ReportsOptions

// Defines the list of report commands.
//
// Parameters:
//  ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//  Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

// End StandardSubsystems.ReportsOptions

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(ParentCompany)
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(StorageLocation)";
	
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
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents._DemoGoodsSales);
	
EndFunction

// End StandardSubsystems.AttachableCommands

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
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection.
//
Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ExpenseToPrint";
	PrintCommand.Presentation = NStr("ru = 'Расходная накладная';
										|en = 'Sales invoice';");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.Order = 10;

	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "Invoice";
	PrintCommand.Presentation = NStr("ru = 'Реализация товаров (на принтер)';
										|en = 'Goods sales (to print)';");
	PrintCommand.Picture = PictureLib.PrintImmediately;
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.Order = 1;
	PrintCommand.SkipPreview = True;
	
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
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "Invoice") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"Invoice",
			NStr("ru = 'Реализация товаров';
				|en = 'Goods sales';"),
			GenerateGoodsSalesPrintForm(ObjectsArray, PrintObjects),
			,
			"Document._DemoGoodsSales.PF_MXL_GoodsSales");
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ExpenseToPrint") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ExpenseToPrint",
			NStr("ru = 'Расходная накладная';
				|en = 'Sales invoice';"),
			CreatePrintedFormInvoice(ObjectsArray, PrintObjects),
			,
			"Document._DemoGoodsSales.PF_MXL_ExpenseToPrint");
	EndIf;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#Region Private

Function GenerateGoodsSalesPrintForm(ObjectsArray, PrintObjects)

	QueryText = 
	"SELECT
	|	_DemoGoodsSales.Ref AS Ref,
	|	_DemoGoodsSales.Number AS Number,
	|	_DemoGoodsSales.Date AS Date,
	|	_DemoGoodsSales.ParentCompany AS Organization,
	|	_DemoGoodsSales.Counterparty AS Counterparty,
	|	_DemoGoodsSales.VATRate AS VATRate,
	|	_DemoGoodsSales.Currency AS Currency,
	|	_DemoGoodsSales.Goods.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		Products AS OwnGoods,
	|		Count AS Count,
	|		Price AS Price,
	|		CASE
	|			WHEN _DemoDocumentsRegistry.Sum - _DemoGoodsSales.Goods.Price * _DemoGoodsSales.Goods.Count = 0
	|				THEN _DemoGoodsSales.Goods.Price * _DemoGoodsSales.Goods.Count
	|			ELSE _DemoDocumentsRegistry.Sum - _DemoGoodsSales.Goods.Price * _DemoGoodsSales.Goods.Count
	|		END AS Sum,
	|		CASE
	|			WHEN _DemoGoodsSales.Goods.Count > 0
	|				THEN ""PCs""
	|		END AS PresentationOfBasicUnitOfMeasure
	|	) AS Goods,
	|	_DemoDocumentsRegistry.Sum AS AmountTotal
	|FROM
	|	InformationRegister._DemoDocumentsRegistry AS _DemoDocumentsRegistry
	|		LEFT JOIN Document._DemoGoodsSales AS _DemoGoodsSales
	|		ON _DemoDocumentsRegistry.Ref = _DemoGoodsSales.Ref
	|WHERE
	|	_DemoGoodsSales.Ref IN(&DocumentsList)";

	Query = New Query(QueryText);
	Query.SetParameter("DocumentsList", ObjectsArray);

	Header = Query.Execute().Select();

	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "GoodsSales";

	Template = PrintManagement.PrintFormTemplate("Document._DemoGoodsSales.PF_MXL_GoodsSales");

	While Header.Next() Do
		If SpreadsheetDocument.TableHeight > 0 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;

		RowNumberStart = SpreadsheetDocument.TableHeight + 1;

		PrintData = New Structure;
		
		Values = New Structure("Number, Date",ObjectsPrefixesClientServer.NumberForPrinting(Header.Number, True, True),Format(Header.Date,"DLF=DD"));
		TitleText = NStr("ru = 'Демо: Реализация товаров № [Number] от [Date]';
								|en = 'Demo: Goods sales #[Number], [Date]';");
		
		PrintData.Insert("TitleText", StringFunctionsClientServer.InsertParametersIntoString(TitleText,Values));
		PrintData.Insert("SupplierPresentation", Header.Organization);
		PrintData.Insert("RecipientPresentation1", Header.Counterparty);
		PrintData.Insert("RecipientPresentation1", Header.Counterparty);
		PrintData.Insert("Total", Header.AmountTotal);
		PrintData.Insert("AmountInWords", CurrencyRateOperations.GenerateAmountInWords(Header.AmountTotal, Header.Currency));
		PrintData.Insert("VAT", ?(ValueIsFilled(Header.VATRate),Header.VATRate,NStr("ru = 'Без налога (НДС)';
																								|en = 'Without tax (VAT)';")));

		GoodsTable = Header.Goods.Unload();

		ArrayOfLayoutAreas = New Array;
		ArrayOfLayoutAreas.Add("Title");
		ArrayOfLayoutAreas.Add("Vendor");
		ArrayOfLayoutAreas.Add("Customer");
		ArrayOfLayoutAreas.Add("TableHeader");
		ArrayOfLayoutAreas.Add("TableRow");
		ArrayOfLayoutAreas.Add("TableFooter");
		ArrayOfLayoutAreas.Add("VATBasement");
		ArrayOfLayoutAreas.Add("AmountInWords");
		ArrayOfLayoutAreas.Add("Signatures");

		For Each AreaName In ArrayOfLayoutAreas Do
			TemplateArea = Template.GetArea(AreaName);
			If AreaName <> "TableRow" Then
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

Function CreatePrintedFormInvoice(ObjectsArray, PrintObjects)

	QueryText = 
	"SELECT
	|	_DemoGoodsSales.Ref AS Ref,
	|	_DemoGoodsSales.Number AS Number,
	|	_DemoGoodsSales.Date AS Date,
	|	_DemoGoodsSales.ParentCompany AS Organization,
	|	_DemoGoodsSales.Counterparty AS Counterparty,
	|	_DemoGoodsSales.Goods.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		Products AS OwnGoods,
	|		Count AS Count,
	|		Price AS Price,
	|		CASE
	|			WHEN _DemoGoodsSales.Goods.Count > 0
	|				THEN ""PCs""
	|		END AS PresentationOfBasicUnitOfMeasure
	|	) AS Goods,
	|	_DemoGoodsSales.StorageLocation AS StorageLocation
	|FROM
	|	InformationRegister._DemoDocumentsRegistry AS _DemoDocumentsRegistry
	|		LEFT JOIN Document._DemoGoodsSales AS _DemoGoodsSales
	|		ON _DemoDocumentsRegistry.Ref = _DemoGoodsSales.Ref
	|WHERE
	|	_DemoGoodsSales.Ref IN(&DocumentsList)";

	Query = New Query(QueryText);
	Query.SetParameter("DocumentsList", ObjectsArray);

	Header = Query.Execute().Select();

	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "ExpenseToPrint";

	Template = PrintManagement.PrintFormTemplate("Document._DemoGoodsSales.PF_MXL_ExpenseToPrint");

	LineCount = 1;

	While Header.Next() Do
		If SpreadsheetDocument.TableHeight > 0 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;

		RowNumberStart = SpreadsheetDocument.TableHeight + 1;

		PrintData = New Structure;
		
		TitleText = NStr("ru = 'Демо: Расходная накладная';
								|en = 'Demo: Sales invoice';");
		PrintData.Insert("TitleText", TitleText);
		
		Values = New Structure("Number, Date",ObjectsPrefixesClientServer.NumberForPrinting(Header.Number, True, True),Format(Header.Date,"DLF=DD"));
		Text = NStr("ru = 'Демо: Расходная накладная № [Number] от [Date]';
					|en = 'Demo: Sales invoice #[Number], [Date]';");

		PrintData.Insert("PresentationOfOrder", StringFunctionsClientServer.InsertParametersIntoString(Text,Values));
		PrintData.Insert("WarehousePresentation_", Header.StorageLocation);
		PrintData.Insert("RepresentationOfTheOrganization", Header.Organization);
		PrintData.Insert("PartnerPresentation_", Header.Counterparty);

		GoodsTable = Header.Goods.Unload();

		ArrayOfLayoutAreas = New Array;
		ArrayOfLayoutAreas.Add("Title");
		ArrayOfLayoutAreas.Add("Header");
		ArrayOfLayoutAreas.Add("Vendor");
		ArrayOfLayoutAreas.Add("Customer");
		ArrayOfLayoutAreas.Add("TableHeader");
		ArrayOfLayoutAreas.Add("TableRow");
		ArrayOfLayoutAreas.Add("TableFooter");

		For Each AreaName In ArrayOfLayoutAreas Do
			TemplateArea = Template.GetArea(AreaName);
			If AreaName <> "TableRow" Then
				FillPropertyValues(TemplateArea.Parameters, PrintData);
				SpreadsheetDocument.Put(TemplateArea);
			Else
				For Each TableRow In GoodsTable Do
					TemplateArea.Parameters.Fill(TableRow);
					SpreadsheetDocument.Put(TemplateArea);
					LineCount = LineCount+1;
				EndDo;
			EndIf;

		EndDo;
		
	Area = Template.GetArea("Signatures");
	TextOfResultingLine = NStr("ru = 'Всего наименований %TotalItems_1%';
								|en = 'Total items %TotalItems_1%';");
	TextOfResultingLine = StrReplace(TextOfResultingLine,"%TotalItems_1%", LineCount-1);
	DataStructureSummaryRow = New Structure;
	DataStructureSummaryRow.Insert("TotalString", TextOfResultingLine);
	Area.Parameters.Fill(DataStructureSummaryRow);
	SpreadsheetDocument.Put(Area);
	
	PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, Header.Ref);
	
	EndDo;
	
	Return SpreadsheetDocument;

EndFunction

Procedure FillInAnalyticsKeys(Document)
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("Document._DemoGoodsSales");
		LockItem.SetValue("Ref", Document.Ref);
		Block.Lock();
		
		DocumentObject = Document.Ref.GetObject();
		For Each LineProducts_ In DocumentObject.Goods Do
		
			If Not ValueIsFilled(LineProducts_.DimensionKey) Then
				
				ParametersOfKey = New Structure();
				ParametersOfKey.Insert("Products", LineProducts_.Products);
				ParametersOfKey.Insert("StorageLocation", DocumentObject.StorageLocation);
				LineProducts_.DimensionKey = Catalogs._DemoProductDimensionKeys.CreateKey(ParametersOfKey);	
			
			EndIf;
		
		EndDo;
		InfobaseUpdate.WriteData(DocumentObject);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

#EndRegion

#EndIf