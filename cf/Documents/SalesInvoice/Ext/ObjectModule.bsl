
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
	
	If State <> Enums.SalesInvoiceStates.Planned Then
	
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
		RegisterRecords.GoodsInWarehouses.Write();
		CheckGoodsInWarehouseBalance(Cancel);

		For Each CurRowServices In Services Do
			Record = RegisterRecords.Sales.Add();
			Record.Period = Date;
			Record.Product = CurRowServices.Product;
			Record.Company = Company;
			Record.Customer = Customer;
			Record.Contract = Contract;
			Record.Quantity = CurRowServices.Quantity;
			Record.Amount = CurRowServices.Amount;
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CheckGoodsInWarehouseBalance(Cancel)

	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsInWarehousesBalance.Product AS Product,
	|	GoodsInWarehousesBalance.QuantityBalance AS Quantity
	|FROM
	|	AccumulationRegister.GoodsInWarehouses.Balance(
	|			&Period,
	|			Product IN (&Products)
	|				AND Warehouse = &Warehouse) AS GoodsInWarehousesBalance
	|WHERE
	|	GoodsInWarehousesBalance.QuantityBalance < 0";

	Query.SetParameter("Period", New Boundary(PointInTime(), BoundaryType.Including));
	Query.SetParameter("Products", Products.UnloadColumn("Product"));
	Query.SetParameter("Warehouse", Warehouse);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Message(
			StrTemplate("Not enough %1 units of product %2 in the warehouse %3", - Selection.Quantity, Selection.Product, Warehouse)
		);
		Cancel = True;
	EndDo;
	
EndProcedure

