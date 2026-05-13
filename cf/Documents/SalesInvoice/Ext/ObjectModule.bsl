
Procedure FillMainContract() Export

	If ValueIsFilled(Customer) Then
		Contract = Customer.MainContract;
	Else	
		Contract = Undefined;
	EndIf;

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	TotalAmount = Products.Total("Amount") + Services.Total("Amount");
	
	PreviousState = Ref.State;
	
	AdditionalProperties.Insert("StateWasChanged", State <> PreviousState);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If AdditionalProperties.Property("StateWasChanged")
		And AdditionalProperties.StateWasChanged Then
	
		RecordManager = InformationRegisters.DocumentStates.CreateRecordManager();
		
		RecordManager.Document 	= Ref;
		RecordManager.State 	= State;
		RecordManager.Period 	= CurrentSessionDate();
		RecordManager.Author 	= Responsible;
		
		RecordManager.Write(True);
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)

	RegisterRecords.GoodsInWarehouses.Write = True;
	RegisterRecords.Sales.Write = True;
	RegisterRecords.GeneralJournal.Write = True;

	ExtraDimensionTypes = ChartsOfCharacteristicTypes.ExtraDimensionTypes;
	
	For Each CurRowProducts In Products Do
		Record = RegisterRecords.GoodsInWarehouses.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Record.Product = CurRowProducts.Product;
		Record.Warehouse = Warehouse;
		Record.Quantity = CurRowProducts.Quantity;
		Record.Amount = CurRowProducts.Amount;

		Record = RegisterRecords.Sales.Add();
		Record.Period = Date;
		Record.Product = CurRowProducts.Product;
		Record.Customer = Customer;
		Record.Amount = CurRowProducts.Amount;
		
		NewRecord = RegisterRecords.GeneralJournal.Add();
		NewRecord.Period 	 = Date;
		NewRecord.AccountDr  = ChartsOfAccounts.ChartOfAccounts.TradeReceivables;
		NewRecord.AccountCr  = ChartsOfAccounts.ChartOfAccounts.Products;
		NewRecord.Amount 	 = CurRowProducts.Amount;
		NewRecord.QuantityCr = CurRowProducts.Quantity;
		NewRecord.ExtDimensionsDr[ExtraDimensionTypes.Counterparty] = Customer;
		NewRecord.ExtDimensionsCr[ExtraDimensionTypes.Product]   	= CurRowProducts.Product;
		NewRecord.ExtDimensionsCr[ExtraDimensionTypes.Warehouse] 	= Warehouse;
	EndDo;

	For Each CurRowServices In Services Do
		Record = RegisterRecords.Sales.Add();
		Record.Period = Date;
		Record.Product = CurRowServices.Service;
		Record.Customer = Customer;
		Record.Amount = CurRowServices.Amount;
	EndDo;

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	If Products.Count() > 0 Then
		DeleteAttributeFromChecking(CheckedAttributes, "Services");
	ElsIf Services.Count() > 0 Then	
		DeleteAttributeFromChecking(CheckedAttributes, "Products");
	EndIf;
	
	FunctionalOptionParatemets = New Structure("Company", Company);
	
	If Not GetFunctionalOption("UseContracts", FunctionalOptionParatemets) Then
		DeleteAttributeFromChecking(CheckedAttributes, "Contract");
	EndIf;
	
	// Turn off checking by the platform
	DeleteAttributeFromChecking(CheckedAttributes, "Products.Amount");
	
	Sales.CheckAmountOfProducts(Products, Cancel);
	
EndProcedure

Procedure DeleteAttributeFromChecking(CheckedAttributes, AttributeToDelete)

	IndexOfAttribute = CheckedAttributes.Find(AttributeToDelete);
	If IndexOfAttribute <> Undefined Then
	
		CheckedAttributes.Delete(IndexOfAttribute);
	
	EndIf;

EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	BankAccount = Constants.DefaultBankAccount.Get();
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("Products") Then
			
			FillProductAndServices(FillingData.Products);
			
		EndIf;
	
	EndIf;
	
EndProcedure

Procedure FillProductAndServices(ProductsAndServices)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Products.Ref AS Product,
	|	1 AS Quantity
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	Products.Ref IN(&ProductsAndServices)
	|	AND Products.Type = &Product
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Products.Ref AS Service,
	|	1 AS Quantity
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	Products.Ref IN(&ProductsAndServices)
	|	AND Products.Type = &Service";
	
	Query.SetParameter("ProductsAndServices", 	ProductsAndServices);
	Query.SetParameter("Product", 				Enums.ProductTypes.Product);
	Query.SetParameter("Service", 				Enums.ProductTypes.Service);
	
	Results = Query.ExecuteBatch();
	Products.Load(Results[0].Unload());
	Services.Load(Results[1].Unload());
	
EndProcedure

Procedure CheckGoodsInWarehouseBalance(Cancel)

	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsInWarehousesBalance.Product AS Product,
	|	GoodsInWarehousesBalance.QuantityBalance AS Quantity
	|FROM
	|	AccumulationRegister.GoodsInWarehouses.Balance(
	|			&Period,
	|			Product IN (&Products)
	|				AND Warehouse = &Warehouse) AS GoodsInWarehousesBalance
	|WHERE
	|	GoodsInWarehousesBalance.QuantityBalance < 0";

	Query.SetParameter("Period", New Boundary(PointInTime(), BoundaryType.Including));
	Query.SetParameter("Products", Products.UnloadColumn("Product"));
	Query.SetParameter("Warehouse", Warehouse);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Message(
			StrTemplate("Not enough %1 units of product %2 in the warehouse %3", - Selection.Quantity, Selection.Product, Warehouse)
		);
		Cancel = True;
	EndDo;
	
EndProcedure

