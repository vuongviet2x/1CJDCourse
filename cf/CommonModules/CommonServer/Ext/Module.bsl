
Function ContractSumsByCounterparties() Export
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = 
		"SELECT
		|	SalesInvoiceProducts.Product AS Product,
		|	SalesInvoiceProducts.Ref AS SalesInvoice,
		|	SalesInvoiceProducts.Quantity AS Quantity,
		|	SalesInvoiceProducts.Amount AS Amount
		|INTO TempTableProducts
		|FROM
		|	Document.SalesInvoice.Products AS SalesInvoiceProducts";

	QueryResult = Query.Execute();
	
	SecondQuery = New Query;
	SecondQuery.TempTablesManager = TempTablesManager;
	
	SecondQuery.Text = 
		"SELECT
		|	Products.Ref AS Product,
		|	SalesInvoiceProducts.SalesInvoice AS SalesInvoice,
		|	SalesInvoiceProducts.Quantity AS Quantity,
		|	SalesInvoiceProducts.Amount AS Amount
		|FROM
		|	Catalog.Products AS Products
		|		LEFT JOIN TempTableProducts AS SalesInvoiceProducts
		|		ON Products.Ref = SalesInvoiceProducts.Product";
	
	QueryResult = SecondQuery.Execute();
	// Get data from temp table and then unload the query result to a ValueTable
	ProductsFromSalesInvoices = TempTablesManager.Tables[0].GetData().Unload();
	
	SelectionProducts = QueryResult.Select();
	// First level selection
	While SelectionProducts.Next() Do
		SelectionDetailRecords = SelectionProducts.Select();
		
		Message("Total amount of product " + SelectionProducts.Product 
				+ " is " + SelectionProducts.Amount);
		
		// Second level selection
		While SelectionDetailRecords.Next() Do
			
			Message("Amount of product " + SelectionDetailRecords.Product 
					+ " at document " + SelectionDetailRecords.SalesInvoice 
					+ " is " + SelectionDetailRecords.Amount);
					
			// Current level of selection can be retrieved using the Level() method
			CurrentLevel = SelectionDetailRecords.Level();
		EndDo;
	
	EndDo;
	
	ValueTable = QueryResult.Unload();
	
EndFunction
