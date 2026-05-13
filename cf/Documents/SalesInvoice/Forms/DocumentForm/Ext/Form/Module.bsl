
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BatchesVisibility = Constants.WriteOffOrder.Get() = Enums.WriteOffMethods.Manually;
	
	Items.ProductsBatch.Visible 	= BatchesVisibility;
	Items.ProductsPickBatch.Visible = BatchesVisibility;
	
EndProcedure

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

&AtClient
Procedure ProductsProductOnChange(Item)
	
	OnChangeProduct(Items.Products.CurrentData);

EndProcedure

&AtClient
Procedure ServicesProductOnChange(Item)
	
	OnChangeProduct(Items.Services.CurrentData);

EndProcedure

&AtClient
Procedure ControlMinimumSalesPrice(CurrentData)

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

		OnChangeProduct(NewRow);
	EndIf;	
	
EndProcedure

&AtClient
Procedure ServicesChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	FoundRows = Object.Services.FindRows(New Structure("Product", SelectedValue));
	If FoundRows.Count() = 0 Then
		NewRow = Object.Services.Add();
		NewRow.Product = SelectedValue;
		NewRow.Quantity = 1;

		OnChangeProduct(NewRow);
	EndIf;	
	
EndProcedure

&AtClient
Procedure OnChangeProduct(CurrentData)

	CurrentData.Price = ProductsInDocumentsServerCall.ProductPrice(CurrentData.Product, Object.Date);
	ControlMinimumSalesPrice(CurrentData);
	ProductsInDocumentsClientServer.CalculateAmountAtRow(CurrentData, Object.Discount);

EndProcedure

&AtClient
Procedure ProductsBatchStartChoice(Item, ChoiceData, StandardProcessing)
	
	//StandardProcessing = False;

	//CurrentData = Items.Products.CurrentData;
	//If CurrentData = Undefined Or Not ValueIsFilled(CurrentData.Product) Then
	//
	//	Message("You should select a product to start batch choice");
	//	Return;
	//	
	//EndIf;	
	//
	//OpenFormParameters = New Structure;
	//OpenFormParameters.Insert("Date", Object.Date);
	//OpenFormParameters.Insert("Product", CurrentData.Product);
	//OpenFormParameters.Insert("Warehouse", Object.Warehouse);
	//
	//OpenForm(
	//	"Document.PurchaseInvoice.Form.BatchChoiceForm",
	//	OpenFormParameters,
	//	Items.ProductsBatch,,,,,
	//	FormWindowOpeningMode.LockOwnerWindow
	//);
	
EndProcedure

&AtClient
Procedure PickBatch(Command)

	CurrentData = Items.Products.CurrentData;
	If CurrentData = Undefined Or Not ValueIsFilled(CurrentData.Product) Then
	
		Message("You should select a product to start batch choice");
		Return;
		
	EndIf;	
	
	OpenFormParameters = New Structure;
	OpenFormParameters.Insert("Date", Object.Date);
	OpenFormParameters.Insert("Product", CurrentData.Product);
	OpenFormParameters.Insert("Warehouse", Object.Warehouse);
	OpenFormParameters.Insert("ChoiceMode", True);
	
	OpenForm(
		"Document.PurchaseInvoice.Form.BatchChoiceForm",
		OpenFormParameters,
		Items.ProductsBatch,,,,
		New CallbackDescription("PickBatchOnSelection", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow
	);
	
EndProcedure

&AtClient
Procedure PickBatchOnSelection(Result, AdditionalParameters) Export

	CurrentData = Items.Products.CurrentData;
	If CurrentData = Undefined Or Result = Undefined Then
		Return;
	EndIf;
	
	CurrentData.Batch = Result;
	
EndProcedure

