
&AtClientAtServerNoContext
Procedure CalculateAmountAtRow(ProductsRow)
	
	ProductsRow.Amount = ProductsRow.Quantity * ProductsRow.Price;
	
EndProcedure

&AtClient
Procedure ProductsQuantityOnChange(Item)
	
	ProductsInDocumentsClientServer.CalculateAmountAtRow(Items.Products.CurrentData);
	
EndProcedure

&AtClient
Procedure ProductsPriceOnChange(Item)
	
	ProductsInDocumentsClientServer.CalculateAmountAtRow(Items.Products.CurrentData);
	
EndProcedure

&AtClient
Procedure ServicesQuantityOnChange(Item)

	ProductsInDocumentsClientServer.CalculateAmountAtRow(Items.Services.CurrentData);

EndProcedure

&AtClient
Procedure ServicesPriceOnChange(Item)
	
	ProductsInDocumentsClientServer.CalculateAmountAtRow(Items.Services.CurrentData);
	
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
	
		ProductsInDocumentsClientServer.CalculateAmountAtRow(ProductsRow);	
		DocumentTotal = DocumentTotal + ProductsRow.Amount;
	
	EndDo;
	For Each ServicesRow In Object.Services Do
	
		ProductsInDocumentsClientServer.CalculateAmountAtRow(ServicesRow);	
		DocumentTotal = DocumentTotal + ServicesRow.Amount;
	
	EndDo;
	
	Object.DocumentTotal = DocumentTotal;
	
EndProcedure

&AtClient
Procedure PickProducts(Command)
	PickProductsToTable(Items.Products, PredefinedValue("Enum.ProductsTypes.InventoryItem"));
EndProcedure

&AtClient
Procedure PickServices(Command)
	PickProductsToTable(Items.Services, PredefinedValue("Enum.ProductsTypes.Service"));
EndProcedure

&AtClient
Procedure PickProductsToTable(TableItem, ProductType)

	OpenForm(
		"Catalog.Products.ChoiceForm",
		New Structure("MultipleChoice, CloseOnChoice, Filter", False, False, New Structure("ProductType", ProductType)),
		TableItem
	);

EndProcedure

&AtClient
Procedure ProductsChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	FoundRows = Object.Products.FindRows(New Structure("Product", SelectedValue));
	If FoundRows.Count() = 0 Then
		NewRow = Object.Products.Add();
		NewRow.Product = SelectedValue;
		NewRow.Quantity = 1;
	EndIf;
	
EndProcedure

&AtClient
Procedure ServicesChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	FoundRows = Object.Services.FindRows(New Structure("Product", SelectedValue));
	If FoundRows.Count() = 0 Then
		NewRow = Object.Services.Add();
		NewRow.Product = SelectedValue;
		NewRow.Quantity = 1;
	EndIf;
	
EndProcedure

