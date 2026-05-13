
&AtClient
Procedure ProductsQuantityOnChange(Item)
	
	ProductsInDocumentsClientServer.CalculateAmountAtRow(Items.Products.CurrentData, Object.Discount);
	
EndProcedure

&AtClient
Procedure ServicesQuantityOnChange(Item)

	ProductsInDocumentsClientServer.CalculateAmountAtRow(Items.Services.CurrentData, Object.Discount);

EndProcedure

&AtClient
Procedure ProductsOnChange(Item)

	RecalculateDocumentTotalAtServer();
	
EndProcedure

&AtClient
Procedure ServicesOnChange(Item)

	RecalculateDocumentTotalAtServer();
	
EndProcedure


&AtServer
Procedure RecalculateDocumentTotalAtServer()

	DocumentTotal = 0;
	For Each ProductsRow In Object.Products Do
	
		ProductsInDocumentsClientServer.CalculateAmountAtRow(ProductsRow, Object.Discount);	
		DocumentTotal = DocumentTotal + ProductsRow.Amount;
	
	EndDo;
	For Each ServicesRow In Object.Services Do
	
		ProductsInDocumentsClientServer.CalculateAmountAtRow(ServicesRow, Object.Discount);	
		DocumentTotal = DocumentTotal + ServicesRow.Amount;
	
	EndDo;
	
	Object.DocumentTotal = DocumentTotal;
	
EndProcedure

