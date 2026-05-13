
&AtClient
Procedure ListOnActivateRow(Item)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined Then
		Products.Parameters.SetParameterValue("Ref", CurrentData.Ref);
	Else	
		Products.Parameters.SetParameterValue("Ref", Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	CurrentData = Items.Products.CurrentData;
	If ValueIsFilled(CurrentData.Product) Then
		ShowValue(, CurrentData.Product);
	EndIf;
	
EndProcedure
