
Procedure Posting(Cancel, Mode)
WriteOffOrder = Constants.WriteOffOrder.Get();
	
	Query = New Query;
	Query.SetParameter("Ref", 			Ref);	
	Query.SetParameter("PointInTime", 	PointInTime());
	Query.SetParameter("Products", 		Products.UnloadColumn("Product"));
	Query.SetParameter("Warehouse", 	WarehouseSender);
	
	If WriteOffOrder <> Enums.WriteOffMethods.Manually Then

		If WriteOffOrder = Enums.WriteOffMethods.FIFO Then
			BatchOrder = " ASC";
		Else
			BatchOrder = " DESC";
		EndIf;

		Query.Text = 
		"SELECT
		|	InventoryTransferProducts.Product AS Product,
		|	SUM(InventoryTransferProducts.Quantity) AS Quantity,
		|	SUM(InventoryTransferProducts.Amount) AS Amount
		|INTO ProductsOfDocument
		|FROM
		|	Document.InventoryTransfer.Products AS InventoryTransferProducts
		|WHERE
		|	InventoryTransferProducts.Ref = &Ref
		|
		|GROUP BY
		|	InventoryTransferProducts.Product
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
					ErrorMessage = StrTemplate(
						"Not enough %1 units of product %2 in the warehouse %3",
						QuantityLeft,
						CurrentProduct,
						WarehouseSender
					);
					Message(ErrorMessage);
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
			Record.Warehouse 	= WarehouseSender;
			Record.Quantity 	= Quantity;
			Record.Amount 		= Quantity * Price;
			Record.Batch 		= SelectionProducts.Batch;

			Record = RegisterRecords.GoodsInWarehouses.Add();
			Record.RecordType 	= AccumulationRecordType.Receipt;
			Record.Period 		= Date;
			Record.Product 		= SelectionProducts.Product;
			Record.Warehouse 	= WarehouseRecipient;
			Record.Quantity 	= Quantity;
			Record.Amount 		= Quantity * Price;
			Record.Batch 		= SelectionProducts.Batch;
			
			QuantityLeft = QuantityLeft - Quantity;
		EndDo;
		
		If QuantityLeft > 0 Then
			Cancel = True;
			ErrorMessage = StrTemplate(
				"Not enough %1 units of product %2 in the warehouse %3",
				QuantityLeft,
				CurrentProduct,
				WarehouseSender
			);
			Message(ErrorMessage);
		EndIf;
		
	Else
		Query.Text =
		"SELECT
		|	InventoryTransferProducts.Product AS Product,
		|	InventoryTransferProducts.Batch AS Batch,
		|	SUM(InventoryTransferProducts.Quantity) AS Quantity
		|FROM
		|	Document.InventoryTransfer.Products AS InventoryTransferProducts
		|WHERE
		|	InventoryTransferProducts.Ref = &Ref
		|
		|GROUP BY
		|	InventoryTransferProducts.Product,
		|	InventoryTransferProducts.Batch
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
			Record.Warehouse 	= WarehouseSender;
			Record.Quantity 	= SelectionProducts.Quantity;
			Record.Amount 		= SelectionProducts.Quantity * Price;
			Record.Batch 		= SelectionProducts.Batch;

			Record = RegisterRecords.GoodsInWarehouses.Add();
			Record.RecordType 	= AccumulationRecordType.Receipt;
			Record.Period 		= Date;
			Record.Product 		= SelectionProducts.Product;
			Record.Warehouse 	= WarehouseRecipient;
			Record.Quantity 	= SelectionProducts.Quantity;
			Record.Amount 		= SelectionProducts.Quantity * Price;
			Record.Batch 		= SelectionProducts.Batch;

			SelectionBalance.Reset();
		EndDo;
		
	EndIf;
	
	RegisterRecords.GoodsInWarehouses.Write();

	ProductsInDocuments.CheckGoodsInWarehouseBalance(
		Products.UnloadColumn("Product"),
		WarehouseSender,
		PointInTime(),
		Cancel
	);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If WarehouseRecipient = WarehouseSender Then
	
		Cancel = True;
		Message("The warehouse-sender can't have the same value that the warehouse-recipient has");
	
	EndIf;
	
EndProcedure

