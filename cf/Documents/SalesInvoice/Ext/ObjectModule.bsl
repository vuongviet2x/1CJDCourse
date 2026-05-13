
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
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Products.LineNumber AS LineNumber,
	|	Products.Product AS Product,
	|	Products.Amount AS Amount
	|INTO TempTableProducts
	|FROM
	|	&Products AS Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TempTableProducts.LineNumber AS LineNumber,
	|	TempTableProducts.Product AS Product,
	|	TempTableProducts.Amount AS Amount
	|FROM
	|	TempTableProducts AS TempTableProducts
	|		INNER JOIN Catalog.Products AS Products
	|		ON TempTableProducts.Product = Products.Ref
	|WHERE
	|	NOT Products.Promotional
	|	AND TempTableProducts.Amount = 0";
	
	Query.SetParameter("Products", Products);
	
	// Execute query and select data from the query result
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		MessageText = StrTemplate(
			"The ""Amount"" is required on line %1 of the ""Products"" list.",
			Selection.LineNumber
		);
		Message(MessageText);
		Cancel = True;
		
	EndDo;
	
EndProcedure

Procedure DeleteAttributeFromChecking(CheckedAttributes, AttributeToDelete)

	IndexOfAttribute = CheckedAttributes.Find(AttributeToDelete);
	If IndexOfAttribute <> Undefined Then
	
		CheckedAttributes.Delete(IndexOfAttribute);
	
	EndIf;

EndProcedure

