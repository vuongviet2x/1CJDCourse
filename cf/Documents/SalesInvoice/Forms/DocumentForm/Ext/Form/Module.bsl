
&AtClient
Procedure ProductsQuantityOnChange(Item)
	
	CalculateAmountAtRow(Items.Products.CurrentData, Object.Discount);
	
EndProcedure

&AtClient
Procedure ProductsPriceOnChange(Item)
	
	ControlMinimumSalesPrice();
	CalculateAmountAtRow(Items.Products.CurrentData, Object.Discount);
	
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)

	RecalculateAmountOfProductsAtServer();
	
EndProcedure

&AtClient
Procedure ProductsProductOnChange(Item)
	ControlMinimumSalesPrice();
EndProcedure

&AtClient
Procedure ControlMinimumSalesPrice()

	CurrentData = Items.Products.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	MinimumPrice = MinimumSalePriceOfProduct(CurrentData.Product);
	If CurrentData.Price < MinimumPrice Then
		
		CurrentData.Price = MinimumPrice;
		Message("Minimum sale price for " + CurrentData.Product + " is " + MinimumPrice);
		
	EndIf;

EndProcedure

&AtServerNoContext
Function MinimumSalePriceOfProduct(Product)
	
	Return Product.MinimumSalePrice;
	
EndFunction

&AtClient
Procedure DateOnChange(Item)
	
	CheckContractValidity();

EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	OnChangeContractAtServer();

	CheckContractValidity();
	
EndProcedure

&AtClient
Procedure CheckContractValidity()

	ContractValidUntil = ContractValidUntil(Object.Contract);
	
	If ValueIsFilled(ContractValidUntil) And ContractValidUntil < BegOfDay(Object.Date) Then
		Message("This contract is invalid on " + Format(Object.Date, "DLF=D"));
	EndIf;

EndProcedure

&AtServerNoContext
Function ContractValidUntil(Contract)

	Return Contract.ValidUntil;

EndFunction

&AtServer
Procedure OnChangeContractAtServer()

	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.FillDiscount();
	
	ValueToFormAttribute(DocumentObject, "Object");
	
	RecalculateAmountOfProductsAtServer();

EndProcedure

&AtClientAtServerNoContext
Procedure CalculateAmountAtRow(ProductsRow, Discount)
	
	ProductsRow.Amount = ProductsRow.Quantity * ProductsRow.Price * (1 - Discount / 100);
	
EndProcedure

&AtServer
Procedure RecalculateAmountOfProductsAtServer()

	DocumentTotal = 0;
	For Each ProductsRow In Object.Products Do
	
		CalculateAmountAtRow(ProductsRow, Object.Discount);	
		DocumentTotal = DocumentTotal + ProductsRow.Amount;
	
	EndDo;

	Object.DocumentTotal = DocumentTotal;
	
EndProcedure
