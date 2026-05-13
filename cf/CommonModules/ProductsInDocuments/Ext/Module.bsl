
Procedure CheckGoodsInWarehouseBalance(Products, Warehouse, Date, Cancel, Company = Undefined) Export

	If Company <> Undefined Then
		CheckBalanceOfGoods = GetFunctionalOption("ContolBalanceOfGoods", New Structure("Company", Company));
	Else
		CheckBalanceOfGoods = Constants.ContolBalanceOfGoods.Get();
	EndIf;
	
	If Not CheckBalanceOfGoods Then
		Return;
	EndIf;
	
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

	Query.SetParameter("Period", 	New Boundary(Date, BoundaryType.Including));
	Query.SetParameter("Products", 	Products);
	Query.SetParameter("Warehouse", Warehouse);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		MessageText = StrTemplate(
			"Not enough %1 units of product %2 in the warehouse %3",
			- Selection.Quantity,
			Selection.Product,
			Warehouse
		);
		Message(MessageText);
		Cancel = True;
	EndDo;
	
EndProcedure
