
Procedure FillMainContract() Export

	If ValueIsFilled(Vendor) Then
		Contract = Vendor.MainContract;
	Else	
		Contract = Undefined;
	EndIf;
	
EndProcedure
