
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	List.Parameters.SetParameterValue("Date", Parameters.Date);
	List.Parameters.SetParameterValue("Product", Parameters.Product);
	List.Parameters.SetParameterValue("Warehouse", Parameters.Warehouse);
	
EndProcedure

