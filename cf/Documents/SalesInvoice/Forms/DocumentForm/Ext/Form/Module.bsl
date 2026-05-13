
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
	
	CalculateAmountAtRow(Items.Products.CurrentData);
	
EndProcedure
