
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Period = CurrentSessionDate();
EndProcedure

&AtClient
Procedure ReadFile(Command)
	
	Dialog = New FileDialog(FileDialogMode.Open);
	Dialog.Title = "Choose a file with prices for import";
	Dialog.Filter = 
		"Tables (*.xls,*.xlsx,*.xlsm)|*.xls;*.xlsx;*.xlsm;
		||Microsoft Excel 1997-2003 (*.xls)|*.xls
		||Microsoft Excel (*.xlsx,*.xlsm)|*.xlsx;*.xlsm";

	Dialog.Show(New CallbackDescription("FileFinishChoice", ThisObject));

EndProcedure

&AtClient
Procedure FileFinishChoice(SelectedFiles, AdditionalParameters) Export

	If SelectedFiles <> Undefined Then
		PathToFile = SelectedFiles[0];
				
		BeginPutFileToServer(
			New CallbackDescription("ReadFinishPuttingFile", ThisObject),,,,
			PathToFile,
			UUID
		);	
	EndIf;	

EndProcedure

&AtClient
Procedure ReadFinishPuttingFile(PlacedFileDescription, AdditionalParameters) Export

	If PlacedFileDescription = Undefined Then
		Return;
	EndIf;
	
	ReadOnServer(PlacedFileDescription.Address, PlacedFileDescription.FileRef.Extension);	

EndProcedure

&AtServer
Procedure ReadOnServer(AddressAtTempStorage, FileExtension)
	
	BinaryData = GetFromTempStorage(AddressAtTempStorage);
	
	// Temp file
	TempFileName = GetTempFileName(FileExtension);
	BinaryData.Write(TempFileName);
	
	SpreadsheetDocument.Read(TempFileName, SpreadsheetDocumentValuesReadingMode.Value);
	
	Try
		DeleteFiles(TempFileName);
	Except
		WriteLogEvent(
			"Files.Deletion",
			EventLogLevel.Error,
			Metadata.DataProcessors.ImportPricesFromExcel,,
			DetailErrorDescription(ErrorInfo())
		);
	EndTry;
	
EndProcedure

&AtClient
Procedure LoadPrices(Command)
	LoadPricesAtServer();
EndProcedure

&AtServer
Procedure LoadPricesAtServer()
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	// TableWidth contains number of table columns.
	ColumnsCount = SpreadsheetDocument.TableWidth; 
	// TableHeight contains number of table rows.
	RowsCount 	 = SpreadsheetDocument.TableHeight;
	
	If ColumnsCount < 2 Or RowsCount < 2 Then
		Message("Table should contain at least 2 rows (1 is for column titles) and 2 columns");
		Return;
	EndIf;
	
	ColumnNumbers = New Structure;
	ColumnNumbers.Insert("Product");
	ColumnNumbers.Insert("Price");
	
	// Rx - row #x, Cx - column #x
	For i = 1 To ColumnsCount Do
		ColumnNameArea = SpreadsheetDocument.Area("R1C" + i);
		ColumnName = TrimAll(ColumnNameArea.Text);
		// Searching name of excel file column at structure with column numbers
		If ColumnNumbers.Property(ColumnName) Then
			ColumnNumbers[ColumnName] = i;
		Else
			Message(StrTemplate("Column %1 with number %2 will be skipped", ColumnName, i));
		EndIf;
	EndDo;
	
	ColumnsError = False;
	For Each KeyAndValue In ColumnNumbers Do
		If Not ValueIsFilled(KeyAndValue.Value) Then
			Message(StrTemplate("Can't find column %1 in Excel file", KeyAndValue.Key));
			ColumnsError = True;
		EndIf;
	EndDo;
	
	If ColumnsError Then
		Return;
	EndIf;
	
	For i = 2 To RowsCount Do
		ProductDescription 	= TrimAll(SpreadsheetDocument.Area("R" + i + "C" + ColumnNumbers.Product).Text);
		ProductPrice 		= TrimAll(SpreadsheetDocument.Area("R" + i + "C" + ColumnNumbers.Price).Text);
		
		Product = Catalogs.Products.FindByDescription(ProductDescription, True);
		If ValueIsFilled(Product) Then
			NewRecord = InformationRegisters.ProductPrices.CreateRecordManager();
			
			NewRecord.Period 	= Period;
			NewRecord.Product 	= Product;
			NewRecord.PriceType = PriceType;
			NewRecord.Price 	= ProductPrice;
			
			NewRecord.Write(True);
		Else
			Message(StrTemplate("Unable to find a product by description %1", ProductDescription));
		EndIf;
		
	EndDo;
	
EndProcedure


