
Procedure Posting(Cancel, Mode)

	For Each CurRowProducts In Products Do
		Record = RegisterRecords.GoodsInWarehouses.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Record.Product = CurRowProducts.Product;
		Record.Warehouse = WarehouseSender;
		Record.Quantity = CurRowProducts.Quantity;
		Record.Amount = CurRowProducts.Amount;
		
		Record = RegisterRecords.GoodsInWarehouses.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Product = CurRowProducts.Product;
		Record.Warehouse = WarehouseRecipient;
		Record.Quantity = CurRowProducts.Quantity;		
		Record.Amount = CurRowProducts.Amount;
	EndDo;
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

