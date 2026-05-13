
Procedure FillMainContract() Export

	If ValueIsFilled(Vendor) Then
		Contract = Vendor.MainContract;
	Else	
		Contract = Undefined;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	AdditionalProperties.Insert("IsNew", IsNew());
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	If AdditionalProperties.IsNew Then
	
		// Some code execution	
	
	EndIf;
	
	GoodsInWarehouses = RegisterRecords.GoodsInWarehouses;
	GoodsInWarehouses.Write = True;
	
	For Each ProductsRow In Products Do
	
		NewRecord = GoodsInWarehouses.AddReceipt();
		NewRecord.Period 	= Date;
		NewRecord.Warehouse = Warehouse;
		NewRecord.Product 	= ProductsRow.Product;
		NewRecord.Quantity 	= ProductsRow.Quantity;
		NewRecord.Amount 	= ProductsRow.Amount;
	
	EndDo;
	
EndProcedure
