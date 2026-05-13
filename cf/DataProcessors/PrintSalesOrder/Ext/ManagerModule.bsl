
// StandardSubsystems.Print

// Generates print forms.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "SalesOrder");
	If PrintForm <> Undefined Then
		PrintForm.SpreadsheetDocument = PrintSalesOrder(ObjectsArray, PrintObjects);
		PrintForm.TemplateSynonym = "Sales order";
		PrintForm.FullTemplatePath = "Document._DemoSalesOrder.PF_MXL_SalesOrder";
	EndIf;

EndProcedure


Function PrintSalesOrder(RefsToObjects, PrintObjects) Export
	
	Spreadsheet = New SpreadsheetDocument;
	Spreadsheet.PrintParametersKey = "PrintForm_DocumentSalesOrderSalesOrder";
	
	Template = PrintManagement.PrintFormTemplate("Document._DemoSalesOrder.PF_MXL_SalesOrder");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	_DemoSalesOrder.Ref AS Ref,
	|	_DemoSalesOrder.Date AS Date,
	|	_DemoSalesOrder.Number AS Number,
	|	_DemoSalesOrder.Contract AS Contract,
	|	_DemoSalesOrder.Counterparty AS Counterparty,
	|	_DemoSalesOrder.Organization AS Organization,
	|	_DemoSalesOrder.Partner AS Partner,
	|	_DemoSalesOrder.DocumentAmount AS DocumentAmount,
	|	_DemoSalesOrder.Currency AS Currency
	|FROM
	|	Document._DemoSalesOrder AS _DemoSalesOrder
	|WHERE
	|	_DemoSalesOrder.Ref IN(&Ref)";

	Query.Parameters.Insert("Ref", RefsToObjects);
	
	Selection = Query.Execute().Select();

	AreaCaption = Template.GetArea("Caption");
	Header = Template.GetArea("Header");
	Spreadsheet.Clear();

	InsertPageBreak = False;
	While Selection.Next() Do
		If InsertPageBreak Then
			Spreadsheet.PutHorizontalPageBreak();
		EndIf;
		RowNumberStart = Spreadsheet.TableHeight + 1;

		AreaCaption.Parameters.Fill(Selection);
		Spreadsheet.Put(AreaCaption);

		Header.Parameters.Fill(Selection);
		Spreadsheet.Put(Header, Selection.Level());

		InsertPageBreak = True;
		
		PrintManagement.SetDocumentPrintArea(Spreadsheet, RowNumberStart, PrintObjects, Selection.Ref);
	EndDo;

	Return Spreadsheet;
	
EndFunction


// End StandardSubsystems.Print
