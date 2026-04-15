
Function ProductsRequiredMinimum() Export

	Query = New Query;
	Query.Text = 
	"SELECT
	|	Warehouses.Ref AS Warehouse,
	|	Products.Ref AS Product,
	|	0 AS RequiredBalance
	|FROM
	|	Catalog.Warehouses AS Warehouses,
	|	Catalog.Products AS Products
	|WHERE
	|	Products.ProductType = &Product";
	
	Query.SetParameter("Product", Enums.ProductsTypes.InventoryItem);
	
	GoodsRequiredBalance = Query.Execute().Unload();
	
	Randomizer = New RandomNumberGenerator;
	For Each BalanceRow In GoodsRequiredBalance Do
	
		BalanceRow.RequiredBalance = Randomizer.RandomNumber(1, 20);
	
	EndDo;
	
	Return GoodsRequiredBalance;
	
EndFunction
