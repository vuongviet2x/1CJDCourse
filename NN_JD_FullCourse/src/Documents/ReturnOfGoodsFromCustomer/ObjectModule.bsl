
Procedure Filling(FillingData, StandardProcessing)

	If TypeOf(FillingData) = Type("DocumentRef.SalesInvoice") Then
		// Filling the headline
		Company = FillingData.Company;
		Contract = FillingData.Contract;
		Customer = FillingData.Customer;
		DocumentTotal = FillingData.DocumentTotal;
		SalesDocument = FillingData.Ref;
		Warehouse = FillingData.Warehouse;
		BankAccount = FillingData.BankAccount;
		Discount = FillingData.Discount;
		
		Products.Clear();
		Services.Clear();
		
		For Each CurRowProducts In FillingData.Products Do
			NewRow = Products.Add();
			NewRow.Amount = CurRowProducts.Amount;
			NewRow.Price = CurRowProducts.Price;
			NewRow.Product = CurRowProducts.Product;
			NewRow.Quantity = CurRowProducts.Quantity;
			NewRow.Batch = CurRowProducts.Batch;
		EndDo;
		For Each CurRowServices In FillingData.Services Do
			NewRow = Services.Add();
			NewRow.Amount = CurRowServices.Amount;
			NewRow.Price = CurRowServices.Price;
			NewRow.Product = CurRowServices.Product;
			NewRow.Quantity = CurRowServices.Quantity;
		EndDo;
	EndIf;

EndProcedure

Procedure Posting(Cancel, Mode)

	WriteOffOrder = Constants.WriteOffOrder.Get();
				
	Query = New Query;
	Query.SetParameter("Ref", 			Ref);	
	Query.SetParameter("SalesInvoice", 	SalesDocument);	
	Query.SetParameter("StartDate", 	BegOfDay(SalesDocument.Date));
	Query.SetParameter("EndDate", 		EndOfDay(SalesDocument.Date));
	Query.SetParameter("Products", 		Products.UnloadColumn("Product"));
	Query.SetParameter("Warehouse", 	Warehouse);
	If WriteOffOrder <> Enums.WriteOffMethods.Manually Then

		If WriteOffOrder = Enums.WriteOffMethods.FIFO Then
			BatchOrder = " DESC";
		Else
			BatchOrder = " ASC";
		EndIf;

		Query.Text = 
		"SELECT
		|	ReturnOfGoodsFromCustomerProducts.Product AS Product,
		|	SUM(ReturnOfGoodsFromCustomerProducts.Quantity) AS Quantity,
		|	SUM(ReturnOfGoodsFromCustomerProducts.Amount) AS Amount
		|INTO ProductsOfDocument
		|FROM
		|	Document.ReturnOfGoodsFromCustomer.Products AS ReturnOfGoodsFromCustomerProducts
		|WHERE
		|	ReturnOfGoodsFromCustomerProducts.Ref = &Ref
		|
		|GROUP BY
		|	ReturnOfGoodsFromCustomerProducts.Product
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductsOfDocument.Product AS Product,
		|	ISNULL(GoodsInWarehousesTurnovers.Batch, VALUE(Document.PurchaseInvoice.EmptyRef)) AS Batch,
		|	ProductsOfDocument.Quantity AS Quantity,
		|	ProductsOfDocument.Amount AS Amount,
		|	ISNULL(GoodsInWarehousesTurnovers.QuantityExpense, 0) AS QuantityExpense,
		|	CASE
		|		WHEN ISNULL(GoodsInWarehousesTurnovers.QuantityExpense, 0) = 0
		|			THEN 0
		|		ELSE ISNULL(GoodsInWarehousesTurnovers.AmountExpense, 0) / ISNULL(GoodsInWarehousesTurnovers.QuantityExpense, 0)
		|	END AS Price
		|FROM
		|	ProductsOfDocument AS ProductsOfDocument
		|		LEFT JOIN AccumulationRegister.GoodsInWarehouses.Turnovers(
		|				&StartDate,
		|				&EndDate,
		|				Recorder,
		|				Product IN (&Products)
		|					AND Warehouse = &Warehouse) AS GoodsInWarehousesTurnovers
		|		ON ProductsOfDocument.Product = GoodsInWarehousesTurnovers.Product
		|			AND (GoodsInWarehousesTurnovers.Recorder = &SalesInvoice)
		|
		|ORDER BY
		|	ProductsOfDocument.Product,
		|	GoodsInWarehousesTurnovers.Batch.Date";
		
		Query.Text = Query.Text + BatchOrder;
		
		SelectionProducts = Query.Execute().Select();
		
		CurrentProduct = Undefined;
		QuantityLeft = 0;
		While SelectionProducts.Next() Do
			
			If SelectionProducts.Product <> CurrentProduct Then
				CurrentProduct 	= SelectionProducts.Product;
				QuantityLeft 	= SelectionProducts.Quantity;
			ElsIf QuantityLeft <= 0 Then
				Continue;
			EndIf;
			
			Price = SelectionProducts.Price;
			
			Quantity = Min(QuantityLeft, SelectionProducts.QuantityExpense);

			Record = RegisterRecords.GoodsInWarehouses.Add();
			Record.RecordType 	= AccumulationRecordType.Expense;
			Record.Period 		= Date;
			Record.Product 		= SelectionProducts.Product;
			Record.Warehouse 	= Warehouse;
			Record.Warehouse 	= Warehouse;
			Record.Quantity 	= - Quantity;
			Record.Amount 		= - Quantity * Price;
			Record.Batch 		= SelectionProducts.Batch;
			
			QuantityLeft = QuantityLeft - Quantity;
		EndDo;
		
	Else
		Query.Text =
		"SELECT
		|	ReturnOfGoodsFromCustomerProducts.Product AS Product,
		|	ReturnOfGoodsFromCustomerProducts.Batch AS Batch,
		|	SUM(ReturnOfGoodsFromCustomerProducts.Quantity) AS Quantity,
		|	SUM(ReturnOfGoodsFromCustomerProducts.Amount) AS Amount
		|FROM
		|	Document.ReturnOfGoodsFromCustomer.Products AS ReturnOfGoodsFromCustomerProducts
		|WHERE
		|	ReturnOfGoodsFromCustomerProducts.Ref = &Ref
		|
		|GROUP BY
		|	ReturnOfGoodsFromCustomerProducts.Product,
		|	ReturnOfGoodsFromCustomerProducts.Batch
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsInWarehousesTurnovers.Product AS Product,
		|	GoodsInWarehousesTurnovers.Batch AS Batch,
		|	CASE
		|		WHEN GoodsInWarehousesTurnovers.QuantityTurnover = 0
		|			THEN 0
		|		ELSE GoodsInWarehousesTurnovers.AmountTurnover / GoodsInWarehousesTurnovers.QuantityTurnover
		|	END AS Price
		|FROM
		|	AccumulationRegister.GoodsInWarehouses.Turnovers(
		|			&StartDate,
		|			&EndDate,
		|			Recorder,
		|			Product IN (&Products)
		|				AND Warehouse = &Warehouse) AS GoodsInWarehousesTurnovers
		|WHERE
		|	GoodsInWarehousesTurnovers.Recorder = &SalesInvoice";
		
		QueryBatch = Query.ExecuteBatch();
		
		SelectionProducts = QueryBatch[0].Select();
		SelectionTurnovers = QueryBatch[1].Select();
		
		Filter = New Structure("Product, Batch");
		While SelectionProducts.Next() Do
			
			FillPropertyValues(Filter, SelectionProducts);
			
			If SelectionTurnovers.FindNext(Filter) Then
				Price = SelectionTurnovers.Price;
			Else
				Price = 0;
			EndIf;
			
			Record = RegisterRecords.GoodsInWarehouses.Add();
			Record.RecordType 	= AccumulationRecordType.Expense;
			Record.Period 		= Date;
			Record.Product 		= SelectionProducts.Product;
			Record.Warehouse 	= Warehouse;
			Record.Quantity 	= - SelectionProducts.Quantity;
			Record.Amount 		= - SelectionProducts.Quantity * Price;
			Record.Batch 		= SelectionProducts.Batch;
			
			SelectionTurnovers.Reset();
		EndDo;
		
	EndIf;
	
	RegisterRecords.GoodsInWarehouses.Write = True;
	RegisterRecords.Sales.Write = True;
	For Each CurRowProducts In Products Do
		Record = RegisterRecords.Sales.Add();
		Record.Period = Date;
		Record.Product = CurRowProducts.Product;
		Record.Company = Company;
		Record.Customer = Customer;
		Record.Contract = Contract;
		Record.Quantity = -CurRowProducts.Quantity;
		Record.Amount = -CurRowProducts.Amount;
	EndDo;

	For Each CurRowServices In Services Do
		Record = RegisterRecords.Sales.Add();
		Record.Period = Date;
		Record.Product = CurRowServices.Product;
		Record.Company = Company;
		Record.Customer = Customer;
		Record.Contract = Contract;
		Record.Quantity = -CurRowServices.Quantity;
		Record.Amount = -CurRowServices.Amount;
	EndDo;

EndProcedure
