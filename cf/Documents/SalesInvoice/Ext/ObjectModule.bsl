
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
		|	SalesTurnovers.AmountTurnover >= &RequierdAmount";
		
		PreviousMonth = AddMonth(Date, -1);
		
		Query.SetParameter("BeginOfPeriod", BegOfMonth(PreviousMonth));
		Query.SetParameter("EndOfPeriod", EndOfMonth(PreviousMonth));
		Query.SetParameter("Customer", Customer);
		Query.SetParameter("RequierdAmount", RequiredSalesAmount);
		
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

Procedure Posting(Cancel, Mode)

	RegisterRecords.GoodsInWarehouses.Write = True;
	RegisterRecords.Sales.Write = True;
	For Each CurRowProducts In Products Do
		Record = RegisterRecords.GoodsInWarehouses.Add();
		Record.RecordType = AccumulationRecordType.Expense;
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
		Record.Quantity = CurRowProducts.Quantity;
		Record.Amount = CurRowProducts.Amount;
	EndDo;

	For Each CurRowServices In Services Do
		Record = RegisterRecords.Sales.Add();
		Record.Period = Date;
		Record.Product = CurRowServices.Product;
		Record.Customer = Customer;
		Record.Contract = Contract;
		Record.Quantity = CurRowServices.Quantity;
		Record.Amount = CurRowServices.Amount;
	EndDo;

EndProcedure
