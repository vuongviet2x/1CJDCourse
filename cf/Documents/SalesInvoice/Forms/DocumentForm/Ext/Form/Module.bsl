
&AtClient
Procedure CustomerOnChange(Item)
	
	FillMainContractAtServer();
	
EndProcedure

&AtServer
Procedure FillMainContractAtServer()

	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.FillMainContract();
	
	ValueToFormAttribute(DocumentObject, "Object");

EndProcedure
