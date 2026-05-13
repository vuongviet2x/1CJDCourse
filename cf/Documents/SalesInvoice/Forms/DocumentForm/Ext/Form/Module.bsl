
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

EndProcedure

&AtClient
Procedure CustomerOnChange(Item)
	
	FillMainContractAtServer();

EndProcedure

&AtServer
Procedure FillMainContractAtServer()

	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.FillMainContract();
	
	ValueToFormAttribute(DocumentObject, "Object");

EndProcedure

&AtClient
Procedure ProductsQuantityOnChange(Item)
	
	FillAmountInProductsRow();

	OnProductOrQuantityChangeAtServer();
	
EndProcedure

&AtClient
Procedure ProductsPriceOnChange(Item)
	FillAmountInProductsRow();
EndProcedure

&AtClient
Procedure FillAmountInProductsRow()

	CurrentData = Items.Products.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData.Amount = CurrentData.Price * CurrentData.Quantity;
	
EndProcedure

&AtClient
Procedure ProductsProductOnChange(Item)
		
	OnProductOrQuantityChangeAtServer();
	
EndProcedure

&AtServer
Procedure OnProductOrQuantityChangeAtServer()

	CalculateWeightAtServer();
		
EndProcedure

&AtServer
Procedure CalculateWeightAtServer()

	TotalWeight = 0;
	For Each ProductsRow In Object.Products Do
	
		TotalWeight = TotalWeight + WeightOfProduct(ProductsRow.Product) * ProductsRow.Quantity;
	
	EndDo;

EndProcedure

&AtServerNoContext
Function WeightOfProduct(Product)

	Return Product.Weight;

EndFunction

&AtClient
Procedure PickProducts(Command)
	PickProductsToTable(Items.Products, PredefinedValue("Enum.ProductTypes.Product"));
EndProcedure

&AtClient
Procedure PickServices(Command)
	PickProductsToTable(Items.Services, PredefinedValue("Enum.ProductTypes.Service"));
EndProcedure

&AtClient
Procedure PickProductsToTable(TableItem, ProductType)

	OpenForm(
		"Catalog.Products.ChoiceForm",
		New Structure("MultipleChoice, CloseOnChoise, Filter", False, False, New Structure("Type", ProductType)),
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
