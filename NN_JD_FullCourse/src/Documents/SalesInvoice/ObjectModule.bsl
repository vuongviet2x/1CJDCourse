
Procedure FillDiscount() Export

	DiscountPercent = Contract.Discount;
	RequiredSalesAmount = Contract.RequiredSalesAmount;
	If RequiredSalesAmount > 0 Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	1 AS Check
		|FROM
		|	AccumulationRegister.Sales.Turnovers(&BeginOfPeriod, &EndOfPeriod, Month, Customer = &Customer) AS SalesTurnovers
		|WHERE
		|	SalesTurnovers.AmountTurnover >= &RequiredAmount";
		
		PreviousMonth = AddMonth(Date, -1);
		
		Query.SetParameter("BeginOfPeriod", BegOfMonth(PreviousMonth));
		Query.SetParameter("EndOfPeriod", EndOfMonth(PreviousMonth));
		Query.SetParameter("Customer", Customer);
		Query.SetParameter("RequiredAmount", RequiredSalesAmount);
		
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then
			Discount = 0;
		Else
			Discount = DiscountPercent;
		EndIf;
	Else
		Discount = DiscountPercent;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	AdditionalProperties.Insert("PreviousState", Ref.State);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	PreviousState = AdditionalProperties.PreviousState;
	If State <> PreviousState Then
		NewRecord = InformationRegisters.SalesInvoiceStates.CreateRecordManager();
		
		NewRecord.Period = CurrentSessionDate();
		NewRecord.SalesInvoice = Ref;
		NewRecord.State = State;
		
		NewRecord.Write(True);
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, Mode)
	
	If State = Enums.SalesInvoiceStates.Planned Then
		Return;
	EndIf;
	
	WriteOffOrder = Constants.WriteOffOrder.Get();
	
	Query = New Query;
	Query.SetParameter("Ref", 			Ref);	
	Query.SetParameter("PointInTime", 	PointInTime());
	Query.SetParameter("Products", 		Products.UnloadColumn("Product"));
	Query.SetParameter("Warehouse", 	Warehouse);
	
	If WriteOffOrder <> Enums.WriteOffMethods.Manually Then

		If WriteOffOrder = Enums.WriteOffMethods.FIFO Then
			BatchOrder = " ASC";
		Else
			BatchOrder = " DESC";
		EndIf;

		Query.Text = 
		"SELECT
		|	SalesInvoiceProducts.Product AS Product,
		|	SUM(SalesInvoiceProducts.Quantity) AS Quantity,
		|	SUM(SalesInvoiceProducts.Amount) AS Amount
		|INTO ProductsOfDocument
		|FROM
		|	Document.SalesInvoice.Products AS SalesInvoiceProducts
		|WHERE
		|	SalesInvoiceProducts.Ref = &Ref
		|
		|GROUP BY
		|	SalesInvoiceProducts.Product
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductsOfDocument.Product AS Product,
		|	ISNULL(GoodsInWarehousesBalance.Batch, VALUE(Document.PurchaseInvoice.EmptyRef)) AS Batch,
		|	ProductsOfDocument.Quantity AS Quantity,
		|	ProductsOfDocument.Amount AS Amount,
		|	ISNULL(GoodsInWarehousesBalance.QuantityBalance, 0) AS QuantityBalance,
		|	CASE
		|		WHEN ISNULL(GoodsInWarehousesBalance.QuantityBalance, 0) = 0
		|			THEN 0
		|		ELSE ISNULL(GoodsInWarehousesBalance.AmountBalance, 0) / ISNULL(GoodsInWarehousesBalance.QuantityBalance, 0)
		|	END AS Price
		|FROM
		|	ProductsOfDocument AS ProductsOfDocument
		|		LEFT JOIN AccumulationRegister.GoodsInWarehouses.Balance(
		|				&PointInTime,
		|				Product IN (&Products)
		|					AND Warehouse = &Warehouse) AS GoodsInWarehousesBalance
		|		ON ProductsOfDocument.Product = GoodsInWarehousesBalance.Product
		|
		|ORDER BY
		|	ProductsOfDocument.Product,
		|	GoodsInWarehousesBalance.Batch.Date";
		
		Query.Text = Query.Text + BatchOrder;
		
		SelectionProducts = Query.Execute().Select();
		
		CurrentProduct = Undefined;
		QuantityLeft = 0;
		While SelectionProducts.Next() Do
			
			If SelectionProducts.Product <> CurrentProduct Then
				If QuantityLeft > 0 Then
					Cancel = True;
					Message(
						StrTemplate("Not enough %1 units of product %2 in the warehouse %3", QuantityLeft, CurrentProduct, Warehouse)
					);
				EndIf;
				CurrentProduct 	= SelectionProducts.Product;
				QuantityLeft 	= SelectionProducts.Quantity;
				
			ElsIf QuantityLeft <= 0 Then
				Continue;
			EndIf;
			
			Price = SelectionProducts.Price;
			
			Quantity = Min(QuantityLeft, SelectionProducts.QuantityBalance);

			Record = RegisterRecords.GoodsInWarehouses.Add();
			Record.RecordType 	= AccumulationRecordType.Expense;
			Record.Period 		= Date;
			Record.Product 		= SelectionProducts.Product;
			Record.Warehouse 	= Warehouse;
			Record.Quantity 	= Quantity;
			Record.Amount 		= Quantity * Price;
			Record.Batch 		= SelectionProducts.Batch;
			
			QuantityLeft = QuantityLeft - Quantity;
		EndDo;
		
		If QuantityLeft > 0 Then
			Cancel = True;
			Message(
				StrTemplate("Not enough %1 units of product %2 in the warehouse %3", QuantityLeft, CurrentProduct, Warehouse)
			);
		EndIf;
		
	Else
		Query.Text =
		"SELECT
		|	SalesInvoiceProducts.Product AS Product,
		|	SalesInvoiceProducts.Batch AS Batch,
		|	SUM(SalesInvoiceProducts.Quantity) AS Quantity,
		|	SUM(SalesInvoiceProducts.Amount) AS Amount
		|FROM
		|	Document.SalesInvoice.Products AS SalesInvoiceProducts
		|WHERE
		|	SalesInvoiceProducts.Ref = &Ref
		|
		|GROUP BY
		|	SalesInvoiceProducts.Product,
		|	SalesInvoiceProducts.Batch
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsInWarehousesBalance.Product AS Product,
		|	GoodsInWarehousesBalance.Batch AS Batch,
		|	CASE
		|		WHEN GoodsInWarehousesBalance.QuantityBalance = 0
		|			THEN 0
		|		ELSE GoodsInWarehousesBalance.AmountBalance / GoodsInWarehousesBalance.QuantityBalance
		|	END AS Price
		|FROM
		|	AccumulationRegister.GoodsInWarehouses.Balance(
		|			&PointInTime,
		|			Product IN (&Products)
		|				AND Warehouse = &Warehouse) AS GoodsInWarehousesBalance";
		
		QueryBatch = Query.ExecuteBatch();
		
		SelectionProducts = QueryBatch[0].Select();
		SelectionBalance  = QueryBatch[1].Select();
		
		Filter = New Structure("Product, Batch");
		While SelectionProducts.Next() Do
			
			FillPropertyValues(Filter, SelectionProducts);
			
			If SelectionBalance.FindNext(Filter) Then
				Price = SelectionBalance.Price;
			Else
				Price = 0;
			EndIf;
			
			Record = RegisterRecords.GoodsInWarehouses.Add();
			Record.RecordType 	= AccumulationRecordType.Expense;
			Record.Period 		= Date;
			Record.Product 		= SelectionProducts.Product;
			Record.Warehouse 	= Warehouse;
			Record.Quantity 	= SelectionProducts.Quantity;
			Record.Amount 		= SelectionProducts.Quantity * Price;
			Record.Batch 		= SelectionProducts.Batch;
			
			SelectionBalance.Reset();
		EndDo;
		
	EndIf;
	RegisterRecords.GoodsInWarehouses.Write();
	
	ProductsInDocuments.CheckGoodsInWarehouseBalance(
		Products.UnloadColumn("Product"),
		Warehouse,
		PointInTime(),
		Cancel,
		Company
	);
	
	RegisterRecords.Sales.Write = True;
	For Each CurRowProducts In Products Do
		Record = RegisterRecords.Sales.Add();
		Record.Period 	= Date;
		Record.Product 	= CurRowProducts.Product;
		Record.Company 	= Company;
		Record.Customer = Customer;
		Record.Contract = Contract;
		Record.Quantity = CurRowProducts.Quantity;
		Record.Amount 	= CurRowProducts.Amount;
	EndDo;
	
	For Each CurRowServices In Services Do
		Record = RegisterRecords.Sales.Add();
		Record.Period 	= Date;
		Record.Product 	= CurRowServices.Product;
		Record.Company 	= Company;
		Record.Customer = Customer;
		Record.Contract = Contract;
		Record.Quantity = CurRowServices.Quantity;
		Record.Amount 	= CurRowServices.Amount;
	EndDo;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Constants.WriteOffOrder.Get() <> Enums.WriteOffMethods.Manually Then
		IndexOfBatch = CheckedAttributes.Find("Products.Batch");
		If IndexOfBatch <> Undefined Then
			CheckedAttributes.Delete(IndexOfBatch);	
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	DocumentFilling.SetNewNumber(StandardProcessing, Prefix, Company);
	
EndProcedure
