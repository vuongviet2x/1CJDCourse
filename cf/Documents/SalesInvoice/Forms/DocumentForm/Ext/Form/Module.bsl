
&AtClient
Procedure CalculateAmountAtRow(ProductsRow)
	
	ProductsRow.Amount = ProductsRow.Quantity * ProductsRow.Price;
	
EndProcedure

&AtClient
Procedure ProductsQuantityOnChange(Item)
	
	CalculateAmountAtRow(Items.Products.CurrentData);
	
EndProcedure

&AtClient
Procedure ProductsPriceOnChange(Item)
	
	ControlMinimumSalesPrice();
	CalculateAmountAtRow(Items.Products.CurrentData);
	
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)

	DocumentTotal = 0;

	For Each ProductsRow In Object.Products Do
		DocumentTotal = DocumentTotal + ProductsRow.Amount;
	EndDo;
	
	Object.DocumentTotal = DocumentTotal;

EndProcedure

&AtClient
Procedure ProductsProductOnChange(Item)
	ControlMinimumSalesPrice();
EndProcedure

&AtClient
Procedure ControlMinimumSalesPrice()

	CurrentData = Items.Products.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	MinimumPrice = MinimumSalePriceOfProduct(CurrentData.Product);
	If CurrentData.Price < MinimumPrice Then
		CurrentData.Price = MinimumPrice;
		
		Message("Minimum sale price for " + CurrentData.Product + " is " + MinimumPrice);
		
	EndIf;

EndProcedure

&AtServerNoContext
Function MinimumSalePriceOfProduct(Product)
	
	Return Product.MinimumSalePrice;
	
EndFunction
