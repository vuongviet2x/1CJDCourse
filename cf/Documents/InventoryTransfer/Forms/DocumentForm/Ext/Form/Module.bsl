
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
Procedure Pick(Command)
	
	ProductType = PredefinedValue("Enum.ProductsTypes.InventoryItem");
	
	OpenForm(
		"Catalog.Products.ChoiceForm",
		New Structure("MultipleChoice, CloseOnChoice, Filter", False, False, New Structure("ProductType", ProductType)),
		Items.Products, 
	);

EndProcedure

&AtClient
Procedure FillInByTheRemainingGoods(Command)
	
	If Not ValueIsFilled(Object.WarehouseSender) Then
		Message("Fill in the Warehouse-sender field");
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("FillInByTheRemainingGoodsAnswer", ThisObject);
	If Object.Products.Count() > 0 Then	
		ShowQueryBox(CallbackDescription, "The tabular section will be cleared. Do you want to continue?", QuestionDialogMode.YesNo);
	Else
		RunCallback(CallbackDescription, DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInByTheRemainingGoodsAnswer(Result, AdditionalParameters) Export

	If Result = DialogReturnCode.Yes Then
		FillInByTheRemainingGoodsAtServer();
	EndIf;

EndProcedure

&AtServer
Procedure FillInByTheRemainingGoodsAtServer()

	Query = New Query;
	Query.Text =
	"SELECT
	|	PurchaseInvoiceProducts.Product AS Product,
	|	SUM(PurchaseInvoiceProducts.Quantity) AS Quantity
	|INTO Purchases
	|FROM
	|	Document.PurchaseInvoice.Products AS PurchaseInvoiceProducts
	|WHERE
	|	PurchaseInvoiceProducts.Ref.Posted
	|	AND PurchaseInvoiceProducts.Ref.Date < &Date
	|
	|GROUP BY
	|	PurchaseInvoiceProducts.Product
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesInvoiceProducts.Product AS Product,
	|	SUM(SalesInvoiceProducts.Quantity) AS Quantity
	|INTO Sales
	|FROM
	|	Document.SalesInvoice.Products AS SalesInvoiceProducts
	|WHERE
	|	SalesInvoiceProducts.Ref.Posted
	|	AND SalesInvoiceProducts.Ref.Date < &Date
	|
	|GROUP BY
	|	SalesInvoiceProducts.Product
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Purchases.Product AS Product,
	|	Purchases.Quantity - ISNULL(Sales.Quantity, 0) AS Quantity
	|FROM
	|	Purchases AS Purchases
	|		LEFT JOIN Sales AS Sales
	|		ON Purchases.Product = Sales.Product";

	Query.SetParameter("Date", Object.Date);

	Object.Products.Load(Query.Execute().Unload());
	
EndProcedure
