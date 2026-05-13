
Function ProductPrice(Product, Val Date = Undefined) Export

	If Date = Undefined Then
		Date = CurrentSessionDate();
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ProductPricesSliceLast.Price AS Price
	|FROM
	|	InformationRegister.ProductPrices.SliceLast(&Period, Product = &Product) AS ProductPricesSliceLast";

	Query.SetParameter("Period", Date);
	Query.SetParameter("Product", Product);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Price;
	Else
		Return 0;
	EndIf;
	
EndFunction

