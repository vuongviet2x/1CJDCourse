
Procedure Posting(Cancel, Mode)
	
	RegisterRecords.ProductPrices.Write = True;
	For Each CurRowProducts In Products Do
		Record = RegisterRecords.ProductPrices.Add();
		Record.Period 	= Date;
		Record.Product 	= CurRowProducts.Product;
		Record.Price 	= CurRowProducts.Price;
	EndDo;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("Products") Then
			
			FillProductAndServices(FillingData.Products);
			
		EndIf;
	
	EndIf;
	
EndProcedure

Procedure FillProductAndServices(ProductsToAdd)
	
	For Each Product In ProductsToAdd Do
	
		Products.Add().Product = Product;
	
	EndDo;
	
EndProcedure


