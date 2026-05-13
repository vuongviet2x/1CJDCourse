
// StandardSubsystems.Print

// Generates print forms.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "GoodsReceipt2");
	If PrintForm <> Undefined Then
		TemplateSynonym = "Goods receipt 2";
		PrintForm.SpreadsheetDocument = PrintGoodsReceipt(
			ObjectsArray,
			PrintObjects,
			"PF_MXL_GoodsReceipt2", 
			TemplateSynonym
		);
		PrintForm.TemplateSynonym = TemplateSynonym;
		PrintForm.FullTemplatePath = "Document._DemoGoodsReceipt.PF_MXL_GoodsReceipt2";
	EndIf;

	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "GoodsReceipt3");
	If PrintForm <> Undefined Then
		TemplateSynonym = "Goods receipt 3";
		PrintForm.SpreadsheetDocument = PrintGoodsReceipt(
			ObjectsArray,
			PrintObjects,
			"PF_MXL_GoodsReceipt3",
			TemplateSynonym
		);
		PrintForm.TemplateSynonym = TemplateSynonym;
		PrintForm.FullTemplatePath = "Document._DemoGoodsReceipt.PF_MXL_GoodsReceipt3";
	EndIf;
	
EndProcedure

Function PrintGoodsReceipt(ObjectsArray, PrintObjects, TemplateName, TemplateSynonym)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_DemoGoodsReceipt" + TemplateName;
	
	Template = PrintManagement.PrintFormTemplate("Document._DemoGoodsReceipt." + TemplateName);
	
	For Each ObjectRef In ObjectsArray Do
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;

		AreaCaption = Template.GetArea("Caption");
		AreaCaption.Parameters.Title = TemplateSynonym;	
		SpreadsheetDocument.Put(AreaCaption);		
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, ObjectRef);
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

// End StandardSubsystems.Print
