
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	BatchesVisibility = Constants.WriteOffOrder.Get() = Enums.WriteOffMethods.Manually;
	
	Items.ProductsBatch.Visible 	= BatchesVisibility;
	Items.ProductsPickBatch.Visible = BatchesVisibility;

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
	|	GoodsInWarehousesBalance.Product AS Product,
	|	GoodsInWarehousesBalance.QuantityBalance AS Quantity,
	|	GoodsInWarehousesBalance.AmountBalance AS Amount
	|FROM
	|	AccumulationRegister.GoodsInWarehouses.Balance(&Date, Warehouse = &Warehouse) AS GoodsInWarehousesBalance";

	Query.SetParameter("Date", 		Object.Date);
	Query.SetParameter("Warehouse", Object.WarehouseSender);

	Object.Products.Load(Query.Execute().Unload());
	
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
	OpenFormParameters.Insert("Warehouse", Object.WarehouseSender);
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

