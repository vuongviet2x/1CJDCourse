
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

	CheckGoodsInWarehouseBalance(Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If WarehouseRecipient = WarehouseSender Then
	
		Cancel = True;
		Message("The warehouse-sender can't have the same value that the warehouse-recipient has");
	
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
	Query.SetParameter("Warehouse", WarehouseSender);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Message(
			StrTemplate("Not enough %1 units of product %2 in the warehouse %3", - Selection.Quantity, Selection.Product, WarehouseSender)
		);
		Cancel = True;
	EndDo;
	
EndProcedure
