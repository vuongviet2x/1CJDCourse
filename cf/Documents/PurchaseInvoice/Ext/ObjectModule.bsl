
Procedure Posting(Cancel, Mode)
	//{{__REGISTER_REGISTERRECORDS_WIZARD
	// This fragment was built by the wizard.
	// Warning! All manually made changes will be lost next time you use the wizard.

	// register GoodsInWarehouses Receipt
	RegisterRecords.GoodsInWarehouses.Write = True;
	For Each CurRowProducts In Products Do
		Record = RegisterRecords.GoodsInWarehouses.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Product = CurRowProducts.Product;
		Record.Warehouse = Warehouse;
		Record.Batch = Ref;
		Record.Quantity = CurRowProducts.Quantity;
		Record.Amount = CurRowProducts.Amount;
	EndDo;

	//}}__REGISTER_REGISTERRECORDS_WIZARD
EndProcedure
