
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Not Parameters.Property("Filter") Then
		Raise "Parameters should contain Filter property";
	EndIf;
	
	List.Parameters.SetParameterValue("Date", 		Parameters.Filter.Date);
	List.Parameters.SetParameterValue("Company", 	Parameters.Filter.Company);
		
EndProcedure

