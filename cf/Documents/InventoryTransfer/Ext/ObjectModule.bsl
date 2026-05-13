
Procedure Posting(Cancel, Mode)

	RegisterRecords.GoodsInWarehouses.Write = True;
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

EndProcedure
