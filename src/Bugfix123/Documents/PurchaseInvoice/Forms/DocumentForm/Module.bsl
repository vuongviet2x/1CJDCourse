&AtClient
&Around("CalculatePriceAtRow")
Procedure bf123_CalculatePriceAtRow(GoodsRow)
	
	If GoodsRow.Count <> 0 Then 
		GoodsRow.Price = GoodsRow.Amount / GoodsRow.Quantity;
	Else
		 GoodsRow.Price = 0; 	
	EndIf;
	
EndProcedure
