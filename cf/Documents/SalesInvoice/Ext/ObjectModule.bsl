
Procedure FillMainContract() Export

	If ValueIsFilled(Customer) Then
		Contract = Customer.MainContract;
	Else	
		Contract = Undefined;
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)

	RegisterRecords.GoodsInWarehouses.Write = True;
	RegisterRecords.Sales.Write = True;
	
	For Each CurRowProducts In Products Do
		Record = RegisterRecords.GoodsInWarehouses.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
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
	
	Company 	= Constants.DefaultCompany.Get();
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
