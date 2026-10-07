&AtClient
Procedure crm_Goodscrm_DiscountOnChangeAfter(Item)
	
	CalculateAmountWithDiscount(Items.Goods.CurrentData);
	
EndProcedure

&AtClient
Procedure CalculateAmountWithDiscount(GoodsRow)
	
    GoodsRow.crm_AmountAfterDiscount = GoodsRow.Amount - GoodsRow.Amount * GoodsRow.Discount / 100;
	
EndProcedure
