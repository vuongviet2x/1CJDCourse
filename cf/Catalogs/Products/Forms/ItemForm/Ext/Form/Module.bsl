
&AtClient
Procedure OnOpen(Cancel)
	ChangeVisibilityOfWeightPromotional();
EndProcedure

&AtClient
Procedure TypeOnChange(Item)
	ChangeVisibilityOfWeightPromotional();
EndProcedure

&AtClient
Procedure ChangeVisibilityOfWeightPromotional()

	If Object.Type = PredefinedValue("Enum.ProductTypes.Service") Then
		Items.GroupWeightPromotional.Visible = False;
	Else
		Items.GroupWeightPromotional.Visible = True;
	EndIf;	

EndProcedure



