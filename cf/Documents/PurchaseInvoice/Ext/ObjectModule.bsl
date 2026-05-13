
#Region Public

Procedure FillMainContract() Export

	If ValueIsFilled(Vendor) Then
		Contract = Vendor.MainContract;
	Else	
		Contract = Undefined;
	EndIf;
	
EndProcedure
	
#EndRegion

#Region EventHandlers
	
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	AdditionalProperties.Insert("IsNew", IsNew());
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	If AdditionalProperties.IsNew Then
	
		// Some code execution	
	
	EndIf;
	
	GoodsInWarehouses = RegisterRecords.GoodsInWarehouses;
	GoodsInWarehouses.Write = True;
	
	GeneralJournal = RegisterRecords.GeneralJournal;
	GeneralJournal.Write = True;
	
	ExtraDimensionTypes = ChartsOfCharacteristicTypes.ExtraDimensionTypes;
	
	For Each ProductsRow In Products Do
	
		NewRecord = GoodsInWarehouses.AddReceipt();
		NewRecord.Period 	= Date;
		NewRecord.Warehouse = Warehouse;
		NewRecord.Product 	= ProductsRow.Product;
		NewRecord.Quantity 	= ProductsRow.Quantity;
		NewRecord.Amount 	= ProductsRow.Amount;
		
		NewRecord = GeneralJournal.Add();
		NewRecord.Period 	 = Date;
		NewRecord.AccountDr  = ChartsOfAccounts.ChartOfAccounts.Products;
		NewRecord.AccountCr  = ChartsOfAccounts.ChartOfAccounts.TradePayables;
		NewRecord.Amount 	 = ProductsRow.Amount;
		NewRecord.QuantityDr = ProductsRow.Quantity;
		NewRecord.ExtDimensionsDr[ExtraDimensionTypes.Product]   	= ProductsRow.Product;
		NewRecord.ExtDimensionsDr[ExtraDimensionTypes.Warehouse] 	= Warehouse;
		NewRecord.ExtDimensionsCr[ExtraDimensionTypes.Counterparty] = Vendor;
		
	EndDo;
	
EndProcedure

#EndRegion
