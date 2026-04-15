
Function ListOfGoodsMovement(PrintingObjects) Export

	Spreadsheet = New SpreadsheetDocument;
	
	Template = Documents.InventoryTransfer.GetTemplate("ListOfGoodsMovement");
	Query = New Query;
	Query.Text =
	"SELECT
	|	InventoryTransfer.Date,
	|	InventoryTransfer.Number,
	|	InventoryTransfer.WarehouseRecipient,
	|	InventoryTransfer.WarehouseSender,
	|	InventoryTransfer.Products.(
	|		LineNumber,
	|		Product,
	|		Quantity,
	|		Amount
	|	)
	|FROM
	|	Document.InventoryTransfer AS InventoryTransfer
	|WHERE
	|	InventoryTransfer.Ref IN (&PrintingObjects)";
	
	Query.Parameters.Insert("PrintingObjects", PrintingObjects);
	
	Selection = Query.Execute().Select();

	AreaTitle 			= Template.GetArea("Title");
	AreaHeader 			= Template.GetArea("Header");
	AreaProductsHeader 	= Template.GetArea("ProductsHeader");
	AreaProducts 		= Template.GetArea("Products");
	AreaFooter 			= Template.GetArea("Footer");
	Spreadsheet.Clear();

	InsertPageBreak = False;
	While Selection.Next() Do
		If InsertPageBreak Then
			Spreadsheet.PutHorizontalPageBreak();
		EndIf;

		AreaTitle.Parameters.Number = Selection.Number;
		AreaTitle.Parameters.Date = Format(Selection.Date, "DLF=D");
		
		Spreadsheet.Put(AreaTitle);

		AreaHeader.Parameters.Fill(Selection);
		Spreadsheet.Put(AreaHeader);

		Spreadsheet.Put(AreaProductsHeader);
		SelectionProducts = Selection.Products.Select();
		While SelectionProducts.Next() Do
			AreaProducts.Parameters.Fill(SelectionProducts);
			Spreadsheet.Put(AreaProducts);
		EndDo;

		Spreadsheet.Put(AreaFooter);

		InsertPageBreak = True;
	EndDo;
	
	Spreadsheet.ShowGrid = False;
	Spreadsheet.ReadOnly = True;
	
	Return Spreadsheet;
	
EndFunction
