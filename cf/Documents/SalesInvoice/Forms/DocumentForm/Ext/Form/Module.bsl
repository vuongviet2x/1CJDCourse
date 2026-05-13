
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
	OnProductOrQuantityChange();
	
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
	OnProductOrQuantityChange();
EndProcedure

&AtClient
Procedure OnProductOrQuantityChange()

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
