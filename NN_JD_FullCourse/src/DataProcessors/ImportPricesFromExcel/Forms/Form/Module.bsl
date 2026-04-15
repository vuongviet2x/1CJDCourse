
&AtClient
Procedure SelectFile(Command)
		
	Dialog = New FileDialog(FileDialogMode.Open);
	Dialog.Title = "Choose a file with prices for import";
	Dialog.Filter = 
		"Tables (*.xls,*.xlsx)|*.xls;*.xlsx;
		||Microsoft Excel 1997-2003 (*.xls)|*.xls
		||Microsoft Excel (*.xlsx)|*.xlsx";

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
	
	ReadFileAtServer(PlacedFileDescription.Address, PlacedFileDescription.FileRef.Extension);	

EndProcedure

&AtServer
Procedure ReadFileAtServer(AddressAtTempStorage, FileExtension)
	
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
	
	// TableWidth contains number of table columns.
	ColumnsCount = SpreadsheetDocument.TableWidth; 
	// TableHeight contains number of table rows.
	RowsCount 	 = SpreadsheetDocument.TableHeight;
	
	If ColumnsCount < 3 Or RowsCount < 2 Then
		Message("Table should contain at least 2 rows (1 is for column titles) and 3 columns");
		Return;
	EndIf;
	
	ColumnNumbers = New Structure;
	ColumnNumbers.Insert("Date");
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

	Prices = New ValueTable;
	Prices.Columns.Add("Date", New TypeDescription("Date"));
	Prices.Columns.Add("Product", New TypeDescription("CatalogRef.Products"));
	Prices.Columns.Add("Price", New TypeDescription("Number"));
	
	UnsuccessfulDates = New Array;
	UniqueDates = New Array;
	For i = 2 To RowsCount Do
		Date 				= SpreadsheetDocument.Area("R" + i + "C" + ColumnNumbers.Date).Value;
		ProductDescription 	= TrimAll(SpreadsheetDocument.Area("R" + i + "C" + ColumnNumbers.Product).Text);
		ProductPrice 		= SpreadsheetDocument.Area("R" + i + "C" + ColumnNumbers.Price).Value;
		
		If Not ValueIsFilled(Date) Then
			Message(StrTemplate("There is an empty date at %1 row, it is skipped", i));
			Continue;
		EndIf;
		
		Product = Catalogs.Products.FindByDescription(ProductDescription, True);
		If ValueIsFilled(Product) Then
			NewRow = Prices.Add();
			NewRow.Date 	= Date;
			NewRow.Product 	= Product;
			NewRow.Price 	= ProductPrice;
			
			If UniqueDates.Find(Date) = Undefined Then
				UniqueDates.Add(Date);
			EndIf;
		Else
			Message(StrTemplate("Unable to find a product by description %1", ProductDescription));
			
			UnsuccessfulDates.Add(Date);
		EndIf;
		
	EndDo;
	
	ExistingDocuments = ExistingDocumentsByDates(UniqueDates);
	If ValueIsFilled(Prices) Then
		
		For Each Date In UniqueDates Do
			DocumentWasUpdated = False;
			DocumentShouldBeSaved = False;
			
			FoundRow = ExistingDocuments.Find(Date, "Date");
			If FoundRow = Undefined Then
				DocumentObject = Documents.PriceSetup.CreateDocument();
				DocumentObject.Date = Date;
				DocumentObject.LoadedFromFile = True;
			Else
				DocumentObject = FoundRow.Ref.GetObject();
				
				DocumentWasUpdated = True;
			EndIf;
			
			ProductsOnDate = Prices.FindRows(New Structure("Date", Date));
			For Each ProductsRow In ProductsOnDate Do
			
				FoundRow = DocumentObject.Products.Find(ProductsRow.Product, "Product");
				If FoundRow = Undefined Then
					DocumentProductsRow = DocumentObject.Products.Add();
					DocumentProductsRow.Product = ProductsRow.Product;
				ElsIf FoundRow.Price <> ProductsRow.Price Then
					DocumentProductsRow = FoundRow;
				Else
					Continue;
				EndIf;
				
				DocumentProductsRow.Price = ProductsRow.Price;
				DocumentShouldBeSaved = True;
			EndDo;
			
			If DocumentShouldBeSaved Then
				Try
					DocumentObject.Write(DocumentWriteMode.Posting);
					
					If DocumentWasUpdated Then
						DocumentState = "updated";
					Else
						DocumentState = "created";
					EndIf;
					
					Message(StrTemplate("Document %1 was %2", DocumentObject.Ref, DocumentState));

				Except
					WriteLogEvent(
						"Data.Import prices from Excel",
						EventLogLevel.Error,,,
						DetailErrorDescription(ErrorInfo())
					);
				EndTry;
			Else	
				Message(
					StrTemplate("Prices for %1 were not loaded", Format(Date, "DLF=D"))
				);
			EndIf;
			
		EndDo;
		
	ElsIf ValueIsFilled(UnsuccessfulDates) Then
		ProcessedDates = New Array;
		For Each Date In UnsuccessfulDates Do
			If ProcessedDates.Find(Date) = Undefined Then
				Message(
					StrTemplate("Prices for %1 were not loaded", Format(Date, "DLF=D"))
				);
				ProcessedDates.Add(Date);		
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ExistingDocumentsByDates(Dates)

	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	PriceSetup.Ref AS Ref,
	|	PriceSetup.Date AS Date
	|FROM
	|	Document.PriceSetup AS PriceSetup
	|WHERE
	|	PriceSetup.LoadedFromFile
	|	AND BEGINOFPERIOD(PriceSetup.Date, DAY) IN (&Dates)";

	Query.SetParameter("Dates", Dates);
	
	Return Query.Execute().Unload();
	
EndFunction
