
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Batches.Parameters.SetParameterValue("Date", Parameters.Date);
	Batches.Parameters.SetParameterValue("Product", Parameters.Product);
	Batches.Parameters.SetParameterValue("Warehouse", Parameters.Warehouse);
	
EndProcedure

