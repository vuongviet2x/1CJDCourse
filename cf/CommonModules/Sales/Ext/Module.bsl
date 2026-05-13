
Procedure CheckAmountOfProducts(Products, Cancel) Export
	
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

