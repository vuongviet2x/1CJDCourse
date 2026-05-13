
Procedure Posting(Cancel, Mode)
	
	RegisterRecords.ProductPrices.Write = True;
	For Each CurRowProducts In Products Do
		Record = RegisterRecords.ProductPrices.Add();
		Record.Period 	= Date;
		Record.Product 	= CurRowProducts.Product;
		Record.Price 	= CurRowProducts.Price;
	EndDo;
	
EndProcedure
