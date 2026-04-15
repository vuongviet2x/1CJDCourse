
&AtClient
Procedure SortArray(Command)
	
	UnsortedNumbers = New Array;
	
	UnsortedNumbers.Add(4);
	UnsortedNumbers.Add(2);
	UnsortedNumbers.Add(15);
	UnsortedNumbers.Add(7);
	UnsortedNumbers.Add(10);
	
	SortedNumbers = SortedArray(UnsortedNumbers);
	
	For Each Element In SortedNumbers Do
	
		Message(Element);
	
	EndDo;
	
EndProcedure

&AtClient
Function SortedArray(UnsortedArray)

	ValueListForSorting = New ValueList;
	
	ValueListForSorting.LoadValues(UnsortedArray);
	
	ValueListForSorting.SortByValue();
	
	Return ValueListForSorting.UnloadValues();

EndFunction


&AtClient
Procedure ShowSelectionFromValueList(Command)
	
	ActionsToPerform = New ValueList;
	
	ActionsToPerform.Add(1, "First action");
	ActionsToPerform.Add(2, "Second action");
	ActionsToPerform.Add(3, "Third action");
	
	CallbackDescription = New CallbackDescription("ShowSelectionFromValueListEnding", ThisObject);
	
	ActionsToPerform.ShowChooseItem(CallbackDescription, "Choose the action to perform");
	
EndProcedure

&AtClient
Procedure ShowSelectionFromValueListEnding(SelectedElement, AdditionalParameters) Export

	If SelectedElement <> Undefined Then
		Message("Selected item: Value = " + SelectedElement.Value + ", Presentation = " + SelectedElement.Presentation);
	EndIf;

EndProcedure

&AtServer
Procedure CopyAndGetTotalValueTableAtServer()
	
	ValueTable = New ValueTable;
	
	ValueTable.Columns.Add("Product");
	ValueTable.Columns.Add("Price");
	ValueTable.Columns.Add("Quantity");
	
	NewRow = ValueTable.Add();
	NewRow.Product 	= "Cable, 10m";
	NewRow.Price 	= 100;
	NewRow.Quantity = 24;
	
	NewRow = ValueTable.Add();
	NewRow.Product 	= "Cable, 10m";
	NewRow.Price 	= 103;
	NewRow.Quantity = 52;
	
	NewRow = ValueTable.Add();
	NewRow.Product 	= "Cable, 15m";
	NewRow.Price 	= 150;
	NewRow.Quantity = 10;
	
	NewRow = ValueTable.Add();
	NewRow.Product 	= "Cable, 20m";
	NewRow.Price 	= 190;
	NewRow.Quantity = 200;
	
	RowsFilter  = New Structure("Product", "Cable, 10m");
	CopiedTable = ValueTable.Copy(RowsFilter);
	
	Message("Quantity of cable, 10m is " + CopiedTable.Total("Quantity"));
	
EndProcedure

&AtClient
Procedure CopyAndGetTotalValueTable(Command)
	CopyAndGetTotalValueTableAtServer();
EndProcedure

&AtServer
Procedure CalculateTotalAtValueTreeAtServer()
	
	SalesTree = New ValueTree;
	
	SalesTree.Columns.Add("Period");
	SalesTree.Columns.Add("Customer");
	SalesTree.Columns.Add("Product");
	SalesTree.Columns.Add("Amount");

	NewPeriodRow = SalesTree.Rows.Add();
	NewPeriodRow.Period = "January 2023";
	
	NewCustomerRow = NewPeriodRow.Rows.Add();
	NewCustomerRow.Period 	= "January 2023";
	NewCustomerRow.Customer	= "John";
	
	NewRow = NewCustomerRow.Rows.Add();	
	NewRow.Product 	= "Water";
	NewRow.Amount 	= 1250;
	
	NewCustomerRow = NewPeriodRow.Rows.Add();
	NewCustomerRow.Period 	= "January 2023";
	NewCustomerRow.Customer	= "Albert";

	NewRow = NewCustomerRow.Rows.Add();	
	NewRow.Product 	= "Water";
	NewRow.Amount 	= 480;
		
	NewRow = NewCustomerRow.Rows.Add();
	NewRow.Product 	= "Flour";
	NewRow.Amount 	= 1000;
		
	NewPeriodRow = SalesTree.Rows.Add();
	NewPeriodRow.Period = "February 2023";
	
	NewCustomerRow = NewPeriodRow.Rows.Add();
	NewCustomerRow.Period 	= "February 2023";
	NewCustomerRow.Customer	= "John";

	NewRow = NewCustomerRow.Rows.Add();
	NewRow.Product 	= "Water";
	NewRow.Amount 	= 2500;
		
	NewCustomerRow = NewPeriodRow.Rows.Add();
	NewCustomerRow.Period 	= "February 2023";
	NewCustomerRow.Customer	= "Bob";

	NewRow = NewCustomerRow.Rows.Add();
	NewRow.Product 	= "Water";
	NewRow.Amount 	= 800;

	NewRow = NewCustomerRow.Rows.Add();
	NewRow.Product 	= "Beans";
	NewRow.Amount 	= 130;
	
	AmountOfWater = AmountOfProductAtTree(SalesTree, "Water");
	Message("Amount of Water is " + AmountOfWater);
	
EndProcedure

&AtServer
Function AmountOfProductAtTree(Tree, Product)

	Result = 0;
	
	For Each TreeRow In Tree.Rows Do
	
		If TreeRow.Product = Product Then
			Result = Result + TreeRow.Amount;
		Else
			Result = Result + AmountOfProductAtTree(TreeRow, Product);
		EndIf;
		
	EndDo;

	Return Result;
	
EndFunction

&AtClient
Procedure CalculateTotalAtValueTree(Command)
	CalculateTotalAtValueTreeAtServer();
EndProcedure


