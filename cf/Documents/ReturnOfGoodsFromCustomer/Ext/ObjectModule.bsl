
Procedure Filling(FillingData, StandardProcessing)
	//{{__CREATE_BASED_ON_WIZARD
	// This fragment was built by the wizard.
	// Warning! All manually made changes will be lost next time you use the wizard.
	If TypeOf(FillingData) = Type("DocumentRef.SalesInvoice") Then
		// Filling the headline
		SalesDocument 	= FillingData;
		Company 		= FillingData.Company;
		Contract 		= FillingData.Contract;
		Customer 		= FillingData.Customer;
		Warehouse 		= FillingData.Warehouse;
		For Each CurRowProducts In FillingData.Products Do
			NewRow = Products.Add();
			NewRow.Amount = CurRowProducts.Amount;
			NewRow.Price = CurRowProducts.Price;
			NewRow.Product = CurRowProducts.Product;
			NewRow.Quantity = CurRowProducts.Quantity;
		EndDo;
		For Each CurRowServices In FillingData.Services Do
			NewRow = Services.Add();
			NewRow.Amount = CurRowServices.Amount;
			NewRow.Price = CurRowServices.Price;
			NewRow.Quantity = CurRowServices.Quantity;
			NewRow.Service = CurRowServices.Service;
		EndDo;
	EndIf;
	//}}__CREATE_BASED_ON_WIZARD
EndProcedure



