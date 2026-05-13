
Procedure CalculateAmountAtRow(ProductsRow, Discount = 0) Export
	
	ProductsRow.Amount = ProductsRow.Quantity * ProductsRow.Price * (1 - Discount / 100);
	
EndProcedure