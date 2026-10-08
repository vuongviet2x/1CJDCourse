
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
		ColumnNameArea = SpreadsheetDocument.Area(1, i, 1, i);
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
	
	// Cells are addressed by numbers: "R" + i breaks from row 1000 ("R1 000C2" / "R1,000C2" depending on locale)
	Descriptions = New Array;
	For i = 2 To RowsCount Do
		Descriptions.Add(TrimAll(SpreadsheetDocument.Area(i, ColumnNumbers.Product, i, ColumnNumbers.Product).Text));
	EndDo;
	// One query for all products instead of FindByDescription on every row
	ProductsByDescription = ProductsByDescriptions(Descriptions);
	
	UnsuccessfulDates = New Array;
	UniqueDates = New Array;
	For i = 2 To RowsCount Do
		Date 				= SpreadsheetDocument.Area(i, ColumnNumbers.Date, i, ColumnNumbers.Date).Value;
		ProductDescription 	= Descriptions[i - 2];
		ProductPrice 		= SpreadsheetDocument.Area(i, ColumnNumbers.Price, i, ColumnNumbers.Price).Value;
		
		If TypeOf(Date) <> Type("Date") Or Not ValueIsFilled(Date) Then
			Message(StrTemplate("There is an empty or invalid date at %1 row, it is skipped", i));
			Continue;
		EndIf;
		// Documents are matched by day (see ExistingDocumentsByDates)
		Date = BegOfDay(Date);
		
		If TypeOf(ProductPrice) <> Type("Number") Then
			Message(StrTemplate("The price at %1 row is not a number, the row is skipped", i));
			Continue;
		EndIf;
		
		Product = ProductsByDescription.Get(Upper(ProductDescription));
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
					// Tell the user too, not only the event log
					Message(StrTemplate("Prices for %1 were not saved: %2",
						Format(Date, "DLF=D"), BriefErrorDescription(ErrorInfo())));
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
	|	BEGINOFPERIOD(PriceSetup.Date, DAY) AS Date
	|FROM
	|	Document.PriceSetup AS PriceSetup
	|WHERE
	|	PriceSetup.LoadedFromFile
	|	AND BEGINOFPERIOD(PriceSetup.Date, DAY) IN (&Dates)";

	Query.SetParameter("Dates", Dates);
	
	Return Query.Execute().Unload();
	
EndFunction

// Map: upper-case description -> product reference (one query for the whole file)
&AtServerNoContext
Function ProductsByDescriptions(Descriptions)

	Query = New Query;
	Query.Text =
	"SELECT
	|	Products.Ref AS Ref,
	|	Products.Description AS Description
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	Products.Description IN (&Descriptions)
	|	AND NOT Products.DeletionMark";
	Query.SetParameter("Descriptions", Descriptions);
	
	Result = New Map;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result.Insert(Upper(TrimAll(Selection.Description)), Selection.Ref);
	EndDo;
	
	Return Result;

EndFunction
