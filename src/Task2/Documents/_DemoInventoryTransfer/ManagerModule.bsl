&Around("GoodsTransferPrintForm")
Function Ext1_GoodsTransferPrintForm(ObjectsArray, PrintObjects)
		
	QueryText = 
	"SELECT
	|	_DemoInventoryTransfer.Ref AS Ref,
	|	_DemoInventoryTransfer.Number AS Number,
	|	_DemoInventoryTransfer.Date AS Date,
	|	_DemoInventoryTransfer.StorageSource AS StorageSource,
	|	_DemoInventoryTransfer.StorageLocationDestination AS StorageLocationDestination,
	|	_DemoInventoryTransfer.Organization AS Organization,
	|	_DemoInventoryTransfer.EmployeeResponsible AS EmployeeResponsible,
	|	_DemoInventoryTransfer.Goods.(
	|		LineNumber AS LineNumber,
	|		Products AS Products,
	|		Count AS Count
	|	) AS Goods,
	|	_DemoInventoryTransfer.ReleasedBy AS ReleasedBy,
	|	_DemoInventoryTransfer.ReceivedBy AS ReceivedBy
	|FROM
	|	Document._DemoInventoryTransfer AS _DemoInventoryTransfer
	|WHERE
	|	_DemoInventoryTransfer.Ref IN(&DocumentsList)";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentsList", ObjectsArray);
	
	Header = Query.Execute().Select();
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "TransferNote";
	
	Template = PrintManagement.PrintFormTemplate("Document._DemoInventoryTransfer.PF_MXL_TransferNote");
	
	While Header.Next() Do
		If SpreadsheetDocument.TableHeight > 0 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		PrintData = New Structure;
		
		TitleText = GenerateDocumentTitle(Header, NStr("ru = 'Демо: Перемещение товаров';
																	|en = 'Demo: Goods transfer';"));
		PrintData.Insert("TitleText", TitleText);
		PrintData.Insert("OrganizationPresentation", Header.Organization);
		PrintData.Insert("SenderPresentation", Header.StorageSource);
		PrintData.Insert("RecipientPresentation", Header.StorageLocationDestination);
		PrintData.Insert("ReleasedBy", Header.ReleasedBy);
		PrintData.Insert("ReceivedBy", Header.ReceivedBy);	
		
		GoodsTable = Header.Goods.Unload();
		
		ArrayOfLayoutAreas = New Array;
		ArrayOfLayoutAreas.Add("Title");
		ArrayOfLayoutAreas.Add("TableHeader");
		ArrayOfLayoutAreas.Add("String");
		ArrayOfLayoutAreas.Add("Footer");
		ArrayOfLayoutAreas.Add("Signatures");
		
		For Each AreaName In ArrayOfLayoutAreas Do
			TemplateArea = Template.GetArea(AreaName);
			If AreaName <> "String" Then
				FillPropertyValues(TemplateArea.Parameters, PrintData);
				SpreadsheetDocument.Put(TemplateArea);
			Else
				For Each TableRow In GoodsTable Do
					TemplateArea.Parameters.Fill(TableRow);
					SpreadsheetDocument.Put(TemplateArea);
				EndDo;
			EndIf;
		EndDo;

		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, Header.Ref);
	
	EndDo;
	
	Return SpreadsheetDocument;

EndFunction
