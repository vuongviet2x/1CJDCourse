
&AtClient
Procedure ProductsQuantityOnChange(Item)
	
	CalculateAmountAtRow(Items.Products.CurrentData, Object.Discount);
	
EndProcedure

&AtClient
Procedure ServicesQuantityOnChange(Item)

	CalculateAmountAtRow(Items.Services.CurrentData, Object.Discount);

EndProcedure

&AtClient
Procedure ProductsOnChange(Item)

	RecalculateDocumentTotalAtServer();
	
EndProcedure

&AtClient
Procedure ServicesOnChange(Item)

	RecalculateDocumentTotalAtServer();
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateAmountAtRow(ProductsRow, Discount)
	
	ProductsRow.Amount = ProductsRow.Quantity * ProductsRow.Price * (1 - Discount / 100);
	
EndProcedure

&AtServer
Procedure RecalculateDocumentTotalAtServer()

	DocumentTotal = 0;
	For Each ProductsRow In Object.Products Do
	
		CalculateAmountAtRow(ProductsRow, Object.Discount);	
		DocumentTotal = DocumentTotal + ProductsRow.Amount;
	
	EndDo;
	For Each ServicesRow In Object.Services Do
	
		CalculateAmountAtRow(ServicesRow, Object.Discount);	
		DocumentTotal = DocumentTotal + ServicesRow.Amount;
	
	EndDo;
	
	Object.DocumentTotal = DocumentTotal;
	
EndProcedure

