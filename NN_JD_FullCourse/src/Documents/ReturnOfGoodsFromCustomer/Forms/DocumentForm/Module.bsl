
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.ProductsBatch.Visible = Constants.WriteOffOrder.Get() = Enums.WriteOffMethods.Manually;

EndProcedure

&AtClient
Procedure ProductsQuantityOnChange(Item)
	
	ProductsInDocumentsClientServer.CalculateAmountAtRow(Items.Products.CurrentData, Object.Discount);
	
EndProcedure

&AtClient
Procedure ServicesQuantityOnChange(Item)

	ProductsInDocumentsClientServer.CalculateAmountAtRow(Items.Services.CurrentData, Object.Discount);

EndProcedure

&AtClient
Procedure ProductsOnChange(Item)

	RecalculateDocumentTotalAtServer();
	
EndProcedure

&AtClient
Procedure ServicesOnChange(Item)

	RecalculateDocumentTotalAtServer();
	
EndProcedure

&AtServer
Procedure RecalculateDocumentTotalAtServer()

	DocumentTotal = 0;
	For Each ProductsRow In Object.Products Do
	
		ProductsInDocumentsClientServer.CalculateAmountAtRow(ProductsRow, Object.Discount);	
		DocumentTotal = DocumentTotal + ProductsRow.Amount;
	
	EndDo;
	For Each ServicesRow In Object.Services Do
	
		ProductsInDocumentsClientServer.CalculateAmountAtRow(ServicesRow, Object.Discount);	
		DocumentTotal = DocumentTotal + ServicesRow.Amount;
	
	EndDo;
	
	Object.DocumentTotal = DocumentTotal;
	
EndProcedure

&AtClient
Procedure ProductsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
EndProcedure

&AtServer
Procedure FillBySalesDocumentAtServer()
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Fill(Object.SalesDocument);
	ValueToFormAttribute(DocumentObject, "Object");
	
EndProcedure

&AtClient
Procedure FillBySalesDocument(Command)
	If ValueIsFilled(Object.SalesDocument) Then
		CallbackDescription = New CallbackDescription("FillBySalesDocumentFinish", ThisObject);
		ShowQueryBox(CallbackDescription, "Document will be filled with losing all changes. Continue?", QuestionDialogMode.YesNo);
	Else
		Message("Sales document attribute is not filled");
	EndIf;
EndProcedure

&AtClient
Procedure FillBySalesDocumentFinish(Result, AdditionalParameters) Export

	If Result = DialogReturnCode.Yes Then
		FillBySalesDocumentAtServer();
	EndIf;
	
EndProcedure
