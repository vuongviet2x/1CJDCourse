
&AtClient
Procedure SendMessage(Command)
	
	NumberForMessage = 1;
	If NumberForMessage = 2 Then
	
		Message("Number is " + NumberForMessage);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateSalesInvoice(Command)
	CreateSalesInvoiceAtServer();
EndProcedure

&AtServerNoContext
Procedure CreateSalesInvoiceAtServer()
	
	BeginTransaction();
	Try
		Document = Documents.SalesInvoice.CreateDocument();	
		
		Document.Customer = NewCustomer();
		Document.Contract = NewContract(Document.Customer);
		
		FillProducts(Document);
		
		//Document.FillTotal();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		//ErrorText = DetailErrorDescription(ErrorInfo());
		
		Raise "An error occurred while creating the document";
	EndTry;
	
EndProcedure

&AtServerNoContext
Function NewCustomer()

	Customer = Catalogs.Counterparties.CreateItem();
	
	Customer.Write();
	
	Return Customer.Ref;

EndFunction

&AtServerNoContext
Function NewContract(Counterparty)

	Contract = Catalogs.CounterpartyContracts.CreateItem();
	Contract.Owner = Counterparty;
	
	Contract.Write();
	
	Return Contract.Ref;

EndFunction

&AtServerNoContext
Procedure FillProducts(SalesInvoice)

	Query = New Query;
	Query.Text =
	"SELECT TOP 3
	|	Products.Ref AS Product
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	NOT Products.DeletionMark
	|
	|ORDER BY
	|	Ref DESC";

	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	RowNumber = 0;
	While Selection.Next() Do
		RowNumber = RowNumber + 1;
		
		NewRow = SalesInvoice.Products.Add();
		NewRow.Product 	= Selection.Product;
		NewRow.Quantity = RowNumber;
		NewRow.Price 	= 100 * RowNumber;
		NewRow.Amount 	= NewRow.Quantity * NewRow.Price;
	EndDo;
	
EndProcedure
