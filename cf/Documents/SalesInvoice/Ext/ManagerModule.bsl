
Function PrintFormSalesInvoice(PrintingObjects) Export
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.ShowGrid = False;
	
	SpreadsheetDocument.PrintParametersKey = "SalesInvoice_SalesInvoice";
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SalesInvoice.Number AS DocumentNumber,
	|	SalesInvoice.Date AS DocumentDate,
	|	SalesInvoice.Company AS Company,
	|	SalesInvoice.Customer AS Customer,
	|	SalesInvoice.Contract AS Contract,
	|	SalesInvoice.TotalAmount AS TotalAmount,
	|	SalesInvoice.Responsible AS Responsible,
	|	SalesInvoice.Warehouse AS Warehouse,
	|	SalesInvoice.Products.(
	|		LineNumber AS LineNumber,
	|		Product AS Product,
	|		Quantity AS Quantity,
	|		Price AS Price,
	|		Amount AS Amount
	|	) AS Products,
	|	SalesInvoice.Services.(
	|		LineNumber AS LineNumber,
	|		Service AS Service,
	|		Quantity AS Quantity,
	|		Price AS Price,
	|		Amount AS Amount
	|	) AS Services
	|FROM
	|	Document.SalesInvoice AS SalesInvoice
	|WHERE
	|	SalesInvoice.Ref IN(&PrintingObjects)";
	
	Query.SetParameter("PrintingObjects", PrintingObjects);
	
	Selection = Query.Execute().Select();
	
	Template = Documents.SalesInvoice.GetTemplate("PF_SalesInvoice");
	
	AreaTitle 				= Template.GetArea("Title");
	AreaHeader 				= Template.GetArea("Header");
	AreaHeaderProducts 		= Template.GetArea("HeaderProducts");
	AreaTableRowProducts 	= Template.GetArea("TableRowProducts");
	AreaHeaderServices 		= Template.GetArea("HeaderServices");
	AreaTableRowServices 	= Template.GetArea("TableRowServices");
	AreaTotals 				= Template.GetArea("Totals");
	AreaFooter 				= Template.GetArea("Footer");
	
	InsertPageBreak = False;
	While Selection.Next() Do
		If InsertPageBreak Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		AreaTitle.Parameters.Fill(Selection);
		AreaTitle.Parameters.DocumentDate = Format(Selection.DocumentDate, "DLF=DD");
		
		CompanyLogo = Catalogs.Companies.CompanyLogo(Selection.Company);
		If TypeOf(CompanyLogo) = Type("BinaryData") Then
			Picture = New Picture(CompanyLogo);
			AreaTitle.Drawings.Logo.Picture = Picture;
		EndIf;
		
		SpreadsheetDocument.Put(AreaTitle);
		
		AreaHeader.Parameters.Fill(Selection);
		SpreadsheetDocument.Put(AreaHeader);
				
		SelectionProducts = Selection.Products.Select();
		If SelectionProducts.Count() > 0 Then
			SpreadsheetDocument.Put(AreaHeaderProducts);
			
			While SelectionProducts.Next() Do
				AreaTableRowProducts.Parameters.Fill(SelectionProducts);
				SpreadsheetDocument.Put(AreaTableRowProducts);				
			EndDo;

		EndIf;
		
		SelectionServices = Selection.Services.Select();
		If SelectionServices.Count() > 0 Then
			SpreadsheetDocument.Put(AreaHeaderServices);
			
			While SelectionServices.Next() Do
				AreaTableRowServices.Parameters.Fill(SelectionServices);
				SpreadsheetDocument.Put(AreaTableRowServices);			
			EndDo;

		EndIf;	
		
		AreaTotals.Parameters.TotalAmount = Format(Selection.TotalAmount, "NG=3");
		SpreadsheetDocument.Put(AreaTotals);
		
		AreaFooter.Parameters.Fill(Selection);
		SpreadsheetDocument.Put(AreaFooter);
		
		InsertPageBreak = True;
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction

