
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
Procedure Pick(Command)
	
	FormOpenParameters = New Structure("ChoiceMode, CloseOnChoice", True, False);
	OpenForm("Catalog.Products.ChoiceForm", FormOpenParameters, Items.Products);
	
EndProcedure

&AtClient
Procedure ProductsChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If ValueIsFilled(SelectedValue) Then
		
		FindRows = Object.Products.FindRows(New Structure("Product", SelectedValue));
		If FindRows.Count() = 0 Then
		
			NewRow = Object.Products.Add();
			NewRow.Product = SelectedValue;
			NewRow.Quantity = 1;
		
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	Message("On change");
EndProcedure
