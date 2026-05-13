
Procedure Filling(FillingData, StandardProcessing)
	//{{__CREATE_BASED_ON_WIZARD
	// This fragment was built by the wizard.
	// Warning! All manually made changes will be lost next time you use the wizard.
	If TypeOf(FillingData) = Type("DocumentRef.SalesInvoice") Then
		// Filling the headline
		Contract = FillingData.Contract;
		Customer = FillingData.Customer;
		DocumentTotal = FillingData.DocumentTotal;
		SalesDocument = FillingData.Ref;
		Warehouse = FillingData.Warehouse;
		Discount = FillingData.Discount;
		For Each CurRowProducts In FillingData.Products Do
			NewRow = Products.Add();
			NewRow.Amount = CurRowProducts.Amount;
			NewRow.Price = CurRowProducts.Price;
			NewRow.Product = CurRowProducts.Product;
			NewRow.Quantity = CurRowProducts.Quantity;
		EndDo;
		For Each CurRowServices In FillingData.Services Do
			NewRow = Services.Add();
			NewRow.Amount = CurRowServices.Amount;
			NewRow.Price = CurRowServices.Price;
			NewRow.Product = CurRowServices.Product;
			NewRow.Quantity = CurRowServices.Quantity;
		EndDo;
	EndIf;
	//}}__CREATE_BASED_ON_WIZARD
EndProcedure

Procedure Posting(Cancel, Mode)

	RegisterRecords.GoodsInWarehouses.Write = True;
	RegisterRecords.Sales.Write = True;
	For Each CurRowProducts In Products Do
		Record = RegisterRecords.GoodsInWarehouses.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Product = CurRowProducts.Product;
		Record.Warehouse = Warehouse;
		Record.Quantity = CurRowProducts.Quantity;
		Record.Amount = CurRowProducts.Amount;
		
		Record = RegisterRecords.Sales.Add();
		Record.Period = Date;
		Record.Product = CurRowProducts.Product;
		Record.Customer = Customer;
		Record.Contract = Contract;
		Record.Quantity = -CurRowProducts.Quantity;
		Record.Amount = -CurRowProducts.Amount;
	EndDo;

	For Each CurRowServices In Services Do
		Record = RegisterRecords.Sales.Add();
		Record.Period = Date;
		Record.Product = CurRowServices.Product;
		Record.Customer = Customer;
		Record.Contract = Contract;
		Record.Quantity = -CurRowServices.Quantity;
		Record.Amount = -CurRowServices.Amount;
	EndDo;

EndProcedure
