///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Interface to call from an additional print form.

// Generates a print form of the "Proforma invoice" document using a template in Office Open XML document format.
// 
//
// Parameters:
//  DocumentRef      - AnyRef - Object to generate a print form for.
//  ObjectTemplateAndData - Map - Collection of references to objects and their data.
//  TemplateName           - String - Description of the print template.
//
// Returns:
//  String - a storage address, to which the generated file is placed.
//
Function PrintCustomerProformaInvoice(DocumentRef, ObjectTemplateAndData, TemplateName) Export
	
	TemplateType				= ObjectTemplateAndData.Templates.TemplateTypes[TemplateName];
	TemplatesBinaryData	= ObjectTemplateAndData.Templates.TemplatesBinaryData;
	Areas					= ObjectTemplateAndData.Templates.AreasDetails;
	ObjectData = ObjectTemplateAndData.Data[DocumentRef][TemplateName];
	
	Template = PrintManagement.InitializeOfficeDocumentTemplate(TemplatesBinaryData[TemplateName], TemplateType, TemplateName);
	If Template = Undefined Then
		Return "";
	EndIf;
	
	ClosePrintFormWindow = False;
	Try
		PrintForm = PrintManagement.InitializePrintForm(TemplateType, Template.TemplatePagesSettings, Template);
		PrintFormStorageAddress = "";
		If PrintForm = Undefined Then
			PrintManagement.ClearRefs(Template);
			Return "";
		EndIf;
		
		// Output document's headers and footers.
		Area = PrintManagement.TemplateArea(Template, Areas[TemplateName]["Header"]);
		PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData);
		
		Area = PrintManagement.TemplateArea(Template, Areas[TemplateName]["Footer"]);
		PrintManagement.AttachArea(PrintForm, Area);
		
		// Display the document header: Common area with parameters.
		Area = PrintManagement.TemplateArea(Template, Areas[TemplateName]["Title"]);
		PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData);
		
		// Outputting a data collection from the infobase as a table.
		Area = PrintManagement.TemplateArea(Template, Areas[TemplateName]["TableHeaderProductsText"]);
		PrintManagement.AttachArea(PrintForm, Area, False);
		Area = PrintManagement.TemplateArea(Template, Areas[TemplateName]["ProductsTableHeader"]);
		PrintManagement.AttachArea(PrintForm, Area, False);
		Area = PrintManagement.TemplateArea(Template, Areas[TemplateName]["RowTableProducts"]);
		PrintManagement.JoinAndFillCollection(PrintForm, Area, ObjectData.Goods);
		
		// Output a data collection from the infobase as a numbered list.
		Area = PrintManagement.TemplateArea(Template, Areas[TemplateName]["TheProductsNomenclatureHeader"]);
		PrintManagement.AttachArea(PrintForm, Area, False);
		Area = PrintManagement.TemplateArea(Template, Areas[TemplateName]["GoodsProducts"]);
		PrintManagement.JoinAndFillCollection(PrintForm, Area, ObjectData.Goods);
		
		// Output a data collection from the infobase as a list.
		Area = PrintManagement.TemplateArea(Template, Areas[TemplateName]["TheProductsTotalHeader"]);
		PrintManagement.AttachArea(PrintForm, Area, False);
		Area = PrintManagement.TemplateArea(Template, Areas[TemplateName]["GoodsTotal"]);
		PrintManagement.JoinAndFillCollection(PrintForm, Area, ObjectData.Goods);
		
		// Display the document footer: Common area with parameters.
		Area = PrintManagement.TemplateArea(Template, Areas[TemplateName]["BottomPart"]);
		PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData);
		
		PrintFormStorageAddress = PrintManagement.GenerateDocument(PrintForm);
	Except
		Common.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		ClosePrintFormWindow = True;
		Return "";
	EndTry;
	
	PrintManagement.ClearRefs(PrintForm, ClosePrintFormWindow);
	PrintManagement.ClearRefs(Template);
	
	Return PrintFormStorageAddress;
	
EndFunction

// Document print procedure.
//
// Parameters:
//  ObjectsArray - Array - Objects to generate a print form for.
//  PrintObjects  - ValueList - Layout of spreadsheet documents by the objects being printed:
//   * Value      - AnyRef - Printable object.
//   * Presentation - String - Name of the area the object belongs to.
//  TemplateName      - String - "Proforma invoice" or "Order".
//  OutputPaymentDetails - Boolean - If True, payment details are displayed in the proforma invoice header.
//  LanguageCode - String - Language to generate the print form in.
//                      Includes the ISO 639-1 language code and (optionally) the ISO 3166-1 country code separated by an underscore.
//                      Examples: "en", "en_US", "en_GB", "ru", "ru_RU".
//                      By default, the configuration language.
//
// Returns:
//  SpreadsheetDocument - print form.
//
Function PrintingAnOrderInvoice(ObjectsArray, PrintObjects, TemplateName = "Account", OutputPaymentDetails = True, LanguageCode = Undefined) Export
	
	QueryText = 
	"SELECT ALLOWED
	|	CustomerProformaInvoice.Ref AS Ref,
	|	CustomerProformaInvoice.Number AS Number,
	|	CustomerProformaInvoice.Date AS Date,
	|	CustomerProformaInvoice.AmountIncludesVAT AS AmountIncludesVAT,
	|	CustomerProformaInvoice.DocumentCurrency AS DocumentCurrency,
	|	CustomerProformaInvoice.Date AS DocumentDate,
	|	CustomerProformaInvoice.BankAccount AS BankAccount,
	|	CustomerProformaInvoice.Counterparty AS Counterparty,
	|	CustomerProformaInvoice.Organization AS Organization,
	|	CustomerProformaInvoice.Goods.(
	|		Products.Description AS OwnGoods,
	|		Price AS Price,
	|		Sum AS Sum,
	|		VATAmount AS VATAmount,
	|		Count AS Count,
	|		LineNumber AS LineNumber,
	|		Products AS Products) AS Goods,
	|	CASE
	|		WHEN CounterpartyBankAccount.ManualBankDetailsChange
	|			THEN CounterpartyBankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BICBank,
	|	CASE
	|		WHEN CounterpartyBankAccount.ManualBankDetailsChange
	|			THEN CounterpartyBankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN CounterpartyBankAccount.ManualBankDetailsChange
	|			THEN CounterpartyBankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END AS BankCorrAccount,
	|	CASE
	|		WHEN CounterpartyBankAccount.ManualBankDetailsChange
	|			THEN CounterpartyBankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	CASE
	|		WHEN CounterpartyBankAccount.TransferBankDetailsManualEdit
	|			THEN CounterpartyBankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END AS TransferBankBIC,
	|	CASE
	|		WHEN CounterpartyBankAccount.TransferBankDetailsManualEdit
	|			THEN CounterpartyBankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END AS TransferBankDescription,
	|	CASE
	|		WHEN CounterpartyBankAccount.TransferBankDetailsManualEdit
	|			THEN CounterpartyBankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END AS TransferBankCorrAccount,
	|	CASE
	|		WHEN CounterpartyBankAccount.TransferBankDetailsManualEdit
	|			THEN CounterpartyBankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END AS TransferBankCity,
	|	CustomerProformaInvoice.Counterparty.DescriptionFull AS RecipientFullName,
	|	CounterpartyBankAccount.AccountNumber AS RecipientAccountNumber,
	|	_DemoCompanies.CEO AS CEO,
	|	_DemoCompanies.ChiefAccountant AS ChiefAccountant,
	|	_DemoCompanies.AbbreviatedDescription AS SupplierName
	|FROM
	|	Document._DemoCustomerProformaInvoice AS CustomerProformaInvoice
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON CustomerProformaInvoice.BankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON CustomerProformaInvoice.BankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Catalog._DemoBankAccounts AS CounterpartyBankAccount
	|		ON CustomerProformaInvoice.BankAccount = CounterpartyBankAccount.Ref
	|		LEFT JOIN Catalog.Currencies AS Currencies
	|		ON CustomerProformaInvoice.DocumentCurrency = Currencies.Ref
	|		LEFT JOIN Catalog._DemoCompanies AS _DemoCompanies
	|		ON CustomerProformaInvoice.Organization = _DemoCompanies.Ref
	|WHERE
	|	CustomerProformaInvoice.Ref IN (&ObjectsArray)
	|
	|ORDER BY
	|	CustomerProformaInvoice.PointInTime";
	
	Query = New Query(QueryText);
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	Header = Query.Execute().Select();
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "InvoiceForPaymentInvoiceOrder";
	
	Template = PrintManagement.PrintFormTemplate("Document._DemoCustomerProformaInvoice.PF_MXL_OrderInvoice", LanguageCode);
	
	While Header.Next() Do
		ContactInformation = ContactInformationForProformaInvoice(Header.Organization, Header.Date, LanguageCode);
		
		If SpreadsheetDocument.TableHeight > 0 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		PrintData = New Structure;
		PrintData.Insert("TIN", "0000000000");
		PrintData.Insert("CRTR", "000000000");
		
		PrintData.Insert("Date", Format(Header.Date, "L=" + LanguageCode + "; DLF=DD"));
		PrintData.Insert("Number", ObjectsPrefixesClientServer.NumberForPrinting(Header.Number));
		
		If IsBlankString(Header.TransferBankBIC) Then
			PrintData.Insert("PayeeBankPresentation", TrimAll(Header.BankDescription) + " " + TrimAll(Header.BankCity));
			PrintData.Insert("SupplierPresentation", TrimAll(Header.RecipientFullName));
			PrintData.Insert("RecipientBankBIC", TrimAll(Header.BICBank));
			PrintData.Insert("RecipientBankAccountPresentation", TrimAll(Header.BankCorrAccount));
			PrintData.Insert("RecipientAccountPresentation", TrimAll(Header.RecipientAccountNumber));
		Else
			PrintData.Insert("PayeeBankPresentation", TrimAll(Header.TransferBankDescription) + " " 
				+ TrimAll(Header.TransferBankCity));
				PrintData.Insert("SupplierPresentation", 
				StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1 р/с %2 в %3';
					|en = '%1 account %2 in %3';"),
				TrimAll(Header.RecipientFullName),
				TrimAll(Header.RecipientAccountNumber),
				TrimAll(Header.BankCity)));
			PrintData.Insert("RecipientBankBIC", TrimAll(Header.TransferBankBIC));
			PrintData.Insert("RecipientBankAccountPresentation", TrimAll(Header.TransferBankCorrAccount));
			PrintData.Insert("RecipientAccountPresentation", TrimAll(Header.BankCorrAccount));
		EndIf;	
		
		TitleText = GenerateDocumentTitle(
			Header, ?(TemplateName = "Account", 
			NStr("ru = 'Демо: Счет на оплату';
				|en = 'Demo: Proforma invoice';"),
			NStr("ru = 'Демо: Заказ покупателя';
				|en = 'Demo: Sales order';")));
		PrintData.Insert("TitleText", TitleText);
		
		PrintData.Insert("Vendor", Header.Organization);
		PrintData.Insert("SupplierPresentation", Header.SupplierName + " " + ContactInformation.LegalAddress);
		
		
		PrintData.Insert("Recipient", Header.Counterparty);
		
		RecipientPresentation1 = Common.ObjectAttributeValue(Header.Counterparty, "DescriptionFull", , LanguageCode);
		PrintData.Insert("RecipientPresentation1", ?(ValueIsFilled(RecipientPresentation1), RecipientPresentation1, Header.Counterparty));
		
		GoodsTable = Header.Goods.Unload();
		Products = GoodsTable.UnloadColumn("Products");
		AttributesValues = Common.ObjectsAttributeValue(Products, "NameForPrinting", , LanguageCode);
		For Each TableRow In GoodsTable Do
			NameForPrinting = AttributesValues[TableRow.Products];
			If ValueIsFilled(NameForPrinting) Then
				TableRow.OwnGoods = NameForPrinting;
			EndIf;
		EndDo;
		
		PrintData.Insert("Total", GoodsTable.Total("Sum"));
		PrintData.Insert("TotalVAT", GoodsTable.Total("VATAmount"));
		
		PrintData.Insert("TotalAmount_", PrintData.Total + ?(Header.AmountIncludesVAT, 0, PrintData.TotalVAT));
		PrintData.Insert("AmountInWords", 
			CurrencyRateOperations.GenerateAmountInWords(PrintData.TotalAmount_, Header.DocumentCurrency, , LanguageCode));
			
		PrintData.Insert("TotalString", 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Всего наименований %1, на сумму %2';
					|en = 'Total items %1 to the amount of %2';"),
				Format(GoodsTable.Count(), "NZ=0; NG=0"),
				PrintData.AmountInWords));
			
		PrintData.Insert("TotalItems_1", GoodsTable.Count());
		PrintData.Insert("VAT", ?(Header.AmountIncludesVAT, NStr("ru = 'В том числе НДС:';
																	|en = 'VAT inclusive:';"), NStr("ru = 'Сумма НДС:';
																									|en = 'VAT amount:';")));
		
		PrintData.Insert("ManagerSFullName_", Header.CEO);
		PrintData.Insert("AccountantSFullName", Header.ChiefAccountant);
		
		
		ArrayOfLayoutAreas = New Array;
		
		If OutputPaymentDetails Then
			ArrayOfLayoutAreas.Add("AttributesForPayment");
		EndIf;
		
		If TemplateName = "Account" And OutputPaymentDetails Then
			ArrayOfLayoutAreas.Add("InvoiceHeader_");
		Else
			ArrayOfLayoutAreas.Add("OrderHeader");
		EndIf;
		
		ArrayOfLayoutAreas.Add("Vendor");
		ArrayOfLayoutAreas.Add("Customer");
		ArrayOfLayoutAreas.Add("TableHeader");
		ArrayOfLayoutAreas.Add("String");
		ArrayOfLayoutAreas.Add("InTotal");
		If Header.AmountIncludesVAT Then
			ArrayOfLayoutAreas.Add("TotalNDSVAmount");
		Else
			ArrayOfLayoutAreas.Add("TotalVATOnTop");
		EndIf;
		ArrayOfLayoutAreas.Add("AmountInWords");
		ArrayOfLayoutAreas.Add(?(TemplateName = "Account", "BasementAccounts", "BasementOfOrder"));
		
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

// To demonstrate access to an external print form.
//
// Parameters:
//  ObjectsArray - Array - Objects to generate a print form for.
//  PrintObjects  - ValueList - Layout of spreadsheet documents by the objects being printed:
//   * Value      - AnyRef - Printable object.
//   * Presentation - String - Name of the area the object belongs to.
//  LanguageCode - String - Language to generate the print form in.
//                      Includes the ISO 639-1 language code and (optionally) the ISO 3166-1 country code separated by an underscore.
//                      Examples: "en", "en_US", "en_GB", "ru", "ru_RU".
//                      By default, the configuration language.
// 
// Returns:
//  SpreadsheetDocument - print form.
//
Function PrintingALetterOfGuarantee(ObjectsArray, PrintObjects, LanguageCode = Undefined) Export
	
	QueryText = 
	"SELECT
	|	_DemoCustomerProformaInvoice.Ref AS Ref,
	|	_DemoCustomerProformaInvoice.Number AS Number,
	|	_DemoCustomerProformaInvoice.Date AS Date,
	|	_DemoCustomerProformaInvoice.Organization AS Organization,
	|	_DemoCustomerProformaInvoice.Counterparty AS Counterparty,
	|	_DemoCustomerProformaInvoice.PayAmount AS PayAmount,
	|	DATEADD(_DemoCustomerProformaInvoice.Date, DAY, 5) AS PaymentDueDate
	|FROM
	|	Document._DemoCustomerProformaInvoice AS _DemoCustomerProformaInvoice
	|WHERE
	|	_DemoCustomerProformaInvoice.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	_DemoCustomerProformaInvoice.PointInTime";
	
	Query = New Query(QueryText);
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	PrintData = Query.Execute().Unload();
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PaymentInvoiceLetterOfGuarantee";
	
	Template = PrintManagement.PrintFormTemplate("Document._DemoCustomerProformaInvoice.PF_MXL_LetterOfGuarantee", LanguageCode);
	
	RepresentationsOfPropertyValues = PropertyManager.RepresentationsOfPropertyValues(ObjectsArray, LanguageCode);
	
	For Each Document In PrintData Do
		If SpreadsheetDocument.TableHeight > 0 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		ParameterValues = New Structure;
		ParameterValues.Insert("Date", Format(Document.Date, ?(ValueIsFilled(LanguageCode), "L=" + LanguageCode + ";", "") + "DLF=DD"));
		ParameterValues.Insert("Number", ObjectsPrefixesClientServer.NumberForPrinting(Document.Number));
		
		TemplateArea = Template.GetArea("EmailText");
		TemplateArea.Parameters.Fill(Document);
		TemplateArea.Parameters.Fill(ParameterValues);
		TemplateArea.Parameters.Fill(RepresentationsOfPropertyValues[Document.Ref]);
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, Document.Ref);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction


//  See PrintManagementOverridable.OnDefinePrintDataSources
Procedure OnDefinePrintDataSources(Object, PrintDataSources) Export
	
	FieldList = PrintManagement.PrintDataFieldTree();
	
	Field = FieldList.Rows.Add();
	Field.Id = "Ref";
	Field.Presentation = NStr("ru = 'Ссылка';
								|en = 'Reference';");
	Field.ValueType = New TypeDescription();	
	
	Field = FieldList.Rows.Add();
	Field.Id = "QRCode";
	Field.Presentation = NStr("ru = 'QR-код';
								|en = 'QR code';");
	Field.Picture = PictureLib.TypePicture;
	Field.Order = 1;
	
	SchemaOfBarcodesData = PrintManagement.SchemaCompositionDataPrint(FieldList);
	PrintDataSources.Add(SchemaOfBarcodesData, "ProformaInvoiceQRCode");
	
EndProcedure

// Prepares printable data.
// 
// Parameters:
//  DataSources - See PrintManagementOverridable.WhenPreparingPrintData.DataSources
//  ExternalDataSets - See PrintManagementOverridable.WhenPreparingPrintData.ExternalDataSets
//  DataCompositionSchemaId - See PrintManagementOverridable.WhenPreparingPrintData.DataCompositionSchemaId
//  LanguageCode - See PrintManagementOverridable.WhenPreparingPrintData.LanguageCode
//  AdditionalParameters - See PrintManagementOverridable.WhenPreparingPrintData.AdditionalParameters
//
Procedure WhenPreparingPrintData(DataSources, ExternalDataSets, DataCompositionSchemaId, LanguageCode,
	AdditionalParameters) Export
	
	If DataCompositionSchemaId = "ProformaInvoiceQRCode" Then
	
		DataSet = New ValueTable();
		DataSet.Columns.Add("Ref");
		DataSet.Columns.Add("QRCode");
		
		
		DocumentsData = DocumentsData(DataSources);
		
		QRCodes = New Map;
		For Each PaymentDetails In DocumentsData Do
			GetUserMessages();
			QRString = Undefined;

			If IsBlankString(QRString) Then
				QRCodes.Insert(PaymentDetails.Ref, New Picture());
				Continue;
			EndIf;

			QRCodeData = BarcodeGeneration.QRCodeData(QRString, 1, 120);
			
			If Not TypeOf(QRCodeData) = Type("BinaryData") Then
				Template = NStr("ru = 'Не удалось сформировать QR-код для документа %1.
						 |Технические подробности см. в журнале регистрации.';
						|en = 'Cannot generate QR code for document %1.
						|See the Event log for details.';");
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(Template, PaymentDetails.Ref);
				Common.MessageToUser(MessageText);
				Continue;
			EndIf;
			
			QRCode = New Picture(QRCodeData);	
			QRCodes.Insert(PaymentDetails.Ref, QRCode); 
		EndDo;
		
		For Each DataSource In DataSources Do
			DataFieldsVal = DataSet.Add();  
			DataFieldsVal.Ref = DataSource;
			DataFieldsVal.QRCode = QRCodes[DataSource];
		EndDo;
		
		ExternalDataSets.Insert("Data", DataSet);
		
	EndIf;
	
EndProcedure

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ImportDataFromFile

// Overrides parameters of data import from a file.
//
// Parameters:
//  Parameters - Structure:
//   * DataStructureTemplateName - String - Template description. For example, "ImportingFromFile".
//   * TabularSectionName - String - Table full name. For example, "Document._DemoCustomerProformaInvoice.TabularSection.Goods".
//   * RequiredColumns2 - Array of String - Descriptions of required columns.
//   * ColumnDataType - Map of KeyAndValue:
//      * Key - String - Column name.
//      * Value - TypeDescription - Column type.
//   * AdditionalParameters - Structure
//
Procedure SetDownloadParametersFromVHFFile(Parameters) Export
	
EndProcedure

// Maps data being imported to the FullTabularSectionName table
// with infobase data and populates the AddressOfMappingTable and ConflictsList parameters.
// ConflictsList contains a list of infobase objects suggested for an ambiguous cell value.
// 
//
// Parameters:
//   AddressOfUploadedData    - String - The address of temporary storage containing a table of data imported from the file.
//                                        Column list:
//     * Id - Number - Row number.
//       Other columns repeat ImportingFromFile template columns.
//   AddressOfMappingTable - String - Temporary storage address containing an emptytable,
//                                        that is a copy of a spreadsheet document. 
//                                        The table must be populated with values from the AddressOfDataToImport table.
//   ConflictsList - ValueTable - List of ambiguous values:
//     * Column       - String - Name of the column where an ambiguous value was found.
//     * Id - Number - ID of the row where an ambiguous value was found.
//   FullTabularSectionName   - String - The full name of the recipient table.
//   AdditionalParameters   - Arbitrary - Any additional information.
//
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	
	
	Goods = GetFromTempStorage(AddressOfMappingTable); // ValueTable
	DataToImport = GetFromTempStorage(AddressOfUploadedData); // ValueTable
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
		"SELECT
		|	CAST(DataForComparison.Barcode AS STRING(13)) AS Barcode,
		|	DataForComparison.Products AS Products,
		|	DataForComparison.Id AS Id
		|INTO DataForComparison
		|FROM
		|	&DataForComparison AS DataForComparison
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	_DemoProducts.Ref AS Ref,
		|	_DemoProducts.Barcode AS Barcode,
		|	DataForComparison.Id AS Id
		|INTO MappedProductByBarcode
		|FROM
		|	DataForComparison AS DataForComparison
		|		INNER JOIN Catalog._DemoProducts AS _DemoProducts
		|		ON (_DemoProducts.Barcode = DataForComparison.Barcode)
		|			AND (DataForComparison.Barcode <> """")
		|
		|INDEX BY
		|	Id
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataForComparison.Products AS Products,
		|	DataForComparison.Id AS Id
		|INTO DataForMatchingByName
		|FROM
		|	DataForComparison AS DataForComparison
		|		LEFT JOIN MappedProductByBarcode AS MappedProductByBarcode
		|		ON DataForComparison.Id = MappedProductByBarcode.Id
		|WHERE MappedProductByBarcode.Id IS NULL
		|
		|INDEX BY
		|	Id
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(_DemoProducts.Ref) AS Ref,
		|	DataForMatchingByName.Id AS Id,
		|	COUNT(DataForMatchingByName.Id) AS Count
		|FROM
		|	DataForMatchingByName AS DataForMatchingByName
		|		INNER JOIN Catalog._DemoProducts AS _DemoProducts
		|		ON (_DemoProducts.Description = (CAST(DataForMatchingByName.Products AS STRING(500))))
		|
		|GROUP BY
		|	DataForMatchingByName.Id
		|
		|UNION ALL
		|
		|SELECT
		|	MAX(MappedProductByBarcode.Ref),
		|	MappedProductByBarcode.Id,
		|	COUNT(MappedProductByBarcode.Id)
		|FROM
		|	MappedProductByBarcode AS MappedProductByBarcode
		|
		|GROUP BY
		|	MappedProductByBarcode.Id";

	Query.SetParameter("DataForComparison", DataToImport);
	QueriesResults = Query.ExecuteBatch(); // Array of QueryResult
	
	TableOfProducts = QueriesResults[3].Unload(); // ValueTable
	FunctionalOptionCharacteristic = ?(DataToImport.Columns.Find("Characteristic") <> Undefined, True, False);
	For Each TableRow In DataToImport Do
		
		OwnGoods = Goods.Add();
		OwnGoods.Id = TableRow.Id;
		OwnGoods.Count = TableRow.Count;
		OwnGoods.Price = TableRow.Price;
		
		StringProducts_ = TableOfProducts.Find(TableRow.Id, "Id");
		If StringProducts_ <> Undefined Then 
			If StringProducts_.Count = 1 Then 
				OwnGoods.Products = StringProducts_.Ref; 
				If FunctionalOptionCharacteristic Then
					OwnGoods.Characteristic = Catalogs._DemoCharacteristics.FindByDescription(TableRow.Characteristic, 
						True,, OwnGoods.Products);
				EndIf;
			ElsIf StringProducts_.Count > 1 Then
				WritingAboutAmbiguity = ConflictsList.Add();
				WritingAboutAmbiguity.Id = TableRow.Id;
				WritingAboutAmbiguity.Column = "Products";
			EndIf;
		EndIf;
	EndDo;
	
	PutToTempStorage(Goods, AddressOfMappingTable);
	
EndProcedure

// Returns a list of infobase objects suggested for an ambiguous cell value.
// 
// Parameters:
//   FullTabularSectionName   - String - The full name of the recipient table.
//   ConflictsList    - Array of CatalogRef._DemoProducts - Array with ambiguous data.
//   ColumnName                - String - The name of the column, where the ambiguity is detected.
//   LoadedValuesString - String - Import data that caused the ambiguity.
//   AdditionalParameters   - Arbitrary - Any additional information.
//
Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export
	
	If ColumnName = "Products" Then
		Query = New Query;
		
		WhereText = "";
		If ValueIsFilled(LoadedValuesString.Products) Then
			WhereText = "WHERE _DemoProducts.Description = &Description";
			Query.SetParameter("Description", LoadedValuesString.Products);
		EndIf;
			
		If ValueIsFilled(LoadedValuesString.Barcode) Then
			If ValueIsFilled(WhereText) Then
				WhereText = WhereText + " OR _DemoProducts.Barcode = &Barcode";
			Else
				WhereText = "WHERE _DemoProducts.Barcode = &Barcode";
			EndIf;
			Query.SetParameter("Barcode", LoadedValuesString.Barcode);
		EndIf;
		
		Query.Text = "SELECT
			|	_DemoProducts.Ref
			|FROM
			|	Catalog._DemoProducts AS _DemoProducts " + WhereText;
		
		QueryResult = Query.Execute();
		SelectionDetailRecords = QueryResult.Select();
		While SelectionDetailRecords.Next() Do
			ConflictsList.Add(SelectionDetailRecords.Ref);
		EndDo;
	EndIf;
	
EndProcedure

// End StandardSubsystems.ImportDataFromFile

// StandardSubsystems.ToDoList


// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Not AccessRight("Read", Metadata.Documents._DemoCustomerProformaInvoice) Then
		Return;
	EndIf;
	
	If Users.IsExternalUserSession() Then
		AuthorizationObject = ExternalUsers.GetExternalUserAuthorizationObject();
		If TypeOf(AuthorizationObject) = TypeOf(Catalogs._DemoPartnersContactPersons.EmptyRef()) Then
			AuthorizationObject = AuthorizationObject.Owner;
		EndIf;
		Result = UnpaidCustomerInvoicesCount(AuthorizationObject);
		UnpaidCustomerInvoicesCount = Result.Count();
		
		Objects = Result.UnloadColumn("Ref");
		FilterByObjects = New Structure;
		FilterByObjects.Insert("Ref", Objects);
		
		SalesOrdersID = "CustomerProformaInvoicesNotPaid";
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = SalesOrdersID;
		ToDoItem.HasToDoItems       = UnpaidCustomerInvoicesCount > 0;
		ToDoItem.Presentation  = NStr("ru = 'Неоплаченные счета';
									|en = 'Unpaid proforma invoices';");
		ToDoItem.Count     = UnpaidCustomerInvoicesCount;
		ToDoItem.Form          = "Document._DemoCustomerProformaInvoice.ListForm";
		ToDoItem.FormParameters = New Structure("Filter", FilterByObjects);
		ToDoItem.Owner       = Metadata.Subsystems._DemoOrganizer;
		
	EndIf;
EndProcedure

// End StandardSubsystems.ToDoList

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the ObjectsVersioning subsystem.
//
// Parameters:
//  Settings - Structure - Subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// StandardSubsystems.Print

// Overrides object's print settings.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	Settings.OnSpecifyingRecipients = True;
	
EndProcedure

// Populates a list of print commands.
// 
// Parameters:
//  PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// Proforma invoice (DCS).
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "PrintManagement";
	PrintCommand.Id = "Document._DemoCustomerProformaInvoice.PF_MXL_ProformaInvoice";
	PrintCommand.Presentation = NStr("ru = 'Счет на оплату (на основе СКД)';
										|en = 'Proforma invoice (based on DCS)';");
	
	// Proforma invoice.
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "Account";
	PrintCommand.Presentation = NStr("ru = 'Счет на оплату';
										|en = 'Proforma invoice';");
	PrintCommand.CheckPostingBeforePrint = Not Users.RolesAvailable("_DemoPrintUnpostedDocuments");
	
	// Proforma invoice without payment details.
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "Account";
	PrintCommand.Presentation = NStr("ru = 'Счет на оплату без платежных реквизитов';
										|en = 'Proforma invoice without payment details';");
	PrintCommand.CheckPostingBeforePrint = Not Users.RolesAvailable("_DemoPrintUnpostedDocuments");
	PrintCommand.AdditionalParameters.Insert("OutputPaymentDetails", False);
	
	// Demo of print command availability restriction.
	If Users.RolesAvailable("_DemoPrintProformaInvoice") Then
		// Proforma invoice (to print out).
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "Account";
		PrintCommand.Presentation = NStr("ru = 'Счет на оплату (на принтер)';
											|en = 'Proforma invoice (to print)';");
		PrintCommand.Picture = PictureLib.PrintImmediately;
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.SkipPreview = True;
	EndIf;
	
	If Not Users.IsExternalUserSession() Then
		// Document set.
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "Account,OrderDocument,OrderDocument,DataProcessor._DemoPrintForm.LetterOfGuarantee,Account,Account,OrderDocument";
		PrintCommand.Presentation = NStr("ru = 'Комплект документов';
											|en = 'Document set';");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.FixedSet = True;
		PrintCommand.OverrideCopiesUserSetting = True;
		PrintCommand.Order = 75;
		
		// Document set (to print out).
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "Account,OrderDocument,OrderDocument,DataProcessor._DemoPrintForm.LetterOfGuarantee,Account,Account,OrderDocument";
		PrintCommand.Presentation = NStr("ru = 'Комплект документов (на принтер)';
											|en = 'Document set for printing';");
		PrintCommand.Picture = PictureLib.PrintImmediately;
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.FixedSet = True;
		PrintCommand.OverrideCopiesUserSetting = True;
		PrintCommand.SkipPreview = True;
		PrintCommand.Order = 75;
		
		// Document set to compile.
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "Account,OrderDocument,OrderDocument,DataProcessor._DemoPrintForm.LetterOfGuarantee,Account,Account,OrderDocument";
		PrintCommand.Presentation = NStr("ru = 'Настраиваемый комплект документов';
											|en = 'Customized document set';");
		PrintCommand.FormsList = "DocumentForm,ListForm";
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.FormCaption = NStr("ru = 'Настраиваемый комплект';
											|en = 'Customized set';");
		PrintCommand.AddExternalPrintFormsToSet = True;
		PrintCommand.Order = 75;
	EndIf;
	
	// Proforma invoice as Adobe PDF document.
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "Account";
	PrintCommand.Presentation = NStr("ru = 'Счет на оплату в документ Adobe PDF';
										|en = 'Proforma invoice in Adobe PDF';");
	PrintCommand.Picture = PictureLib.PDFFormat;
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.SaveFormat = SpreadsheetDocumentFileType.PDF;
	
	// Proforma invoice in Office Open XML format.
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ProformaInvoice(OfficeOpenXML)";
	PrintCommand.Presentation = NStr("ru = 'Счет на оплату в Office Open XML';
										|en = 'Proforma invoice in Office Open XML';");
	PrintCommand.Picture = PictureLib.WordFormat;
	PrintCommand.CheckPostingBeforePrint = True;
	
	
	// Proforma invoice in the Office Open XML format (based on DCS)
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "PrintManagement";
	PrintCommand.Id = "Document._DemoCustomerProformaInvoice.PrintForm_DOC_ProformaInvoiceDCS_ru";
	PrintCommand.Presentation = NStr("ru = 'Счет на оплату в Office Open XML (на основе СКД)';
										|en = 'Proforma invoice in Office Open XML (based on DCS)';");
	PrintCommand.Picture = PictureLib.WordFormat;
	PrintCommand.CheckPostingBeforePrint = True;
	
	// Proforma invoice as Microsoft Word document.
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ProformaInvoice(MSWord)";
	PrintCommand.Presentation = NStr("ru = 'Счет на оплату в Microsoft Word (для обратной совместимости)';
										|en = 'Proforma invoice in Microsoft Word (for backward compatibility)';");
	PrintCommand.Picture = PictureLib.WordFormat2007;
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.Handler = "_DemoStandardSubsystemsClient.PrintCustomerProformaInvoices";
	
	// Proforma invoice as OpenOffice.org Writer document.
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ProformaInvoice(ODT)";
	PrintCommand.Presentation = NStr("ru = 'Счет на оплату в OpenOffice.org Writer (для обратной совместимости)';
										|en = 'Proforma invoice in OpenOffice.org Writer (provided for backward compatibility)';");
	PrintCommand.Picture = PictureLib.OpenOfficeWriterFormat;
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.Handler = "_DemoStandardSubsystemsClient.PrintCustomerProformaInvoices";
	

	// Print form with generation error.
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PrintedFormWithAnError";
	PrintCommand.Presentation = NStr("ru = 'Печатная форма с ошибкой формирования';
										|en = 'Print form with generation error';");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.Order = 100;
	
EndProcedure

// Generates print forms.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	// Print a proforma invoice.
	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "ProformaInvoice(OfficeOpenXML)");
	If PrintForm <> Undefined Then
		
		TemplateName = "ProformaInvoice(OfficeOpenXML)";
		ObjectTemplateAndData = PrintManagementServerCall.TemplatesAndObjectsDataToPrint("Document._DemoCustomerProformaInvoice", TemplateName, ObjectsArray);
		
		OfficeDocuments = New Map;
		
		Template = NStr("ru = '[Organization]-[Counterparty] Счет №[Number] от [Date]';
						|en = '[Organization]–[Counterparty] Proforma invoice #[Number], [Date]';");
		DocumentsAttributesValues = Common.ObjectsAttributesValues(ObjectsArray, "Organization,Counterparty,Number,Date,Ref");
		For Each Ref In ObjectsArray Do
			
			DocumentAttributesValues = DocumentsAttributesValues[Ref];
			DocumentAttributesValues.Date = Format(DocumentAttributesValues.Date, "DLF=D");
			DocumentAttributesValues.Number = ObjectsPrefixesClientServer.NumberForPrinting(DocumentAttributesValues.Number);
			DocumentName = StringFunctionsClientServer.InsertParametersIntoString(Template, DocumentsAttributesValues[Ref]);
			
			OfficeDocumentStorageAddress = PrintCustomerProformaInvoice(Ref, ObjectTemplateAndData, TemplateName);
			
			OfficeDocuments.Insert(OfficeDocumentStorageAddress, DocumentName);
			
		EndDo;
		
		PrintForm.TemplateSynonym    = NStr("ru = 'Счет на оплату';
												|en = 'Proforma invoice';");
		PrintForm.OfficeDocuments = OfficeDocuments;
		
	EndIf;
	
	// Print a proforma invoice.
	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "Account");
	If PrintForm <> Undefined Then
		// File names.
		FilesNames = New Map;
		Template = NStr("ru = '[Organization]-[Counterparty] Счет №[Number] от [Date]';
						|en = '[Organization]–[Counterparty] Proforma invoice #[Number], [Date]';");
		DocumentsAttributesValues = Common.ObjectsAttributesValues(ObjectsArray, "Organization,Counterparty,Number,Date,Ref");
		For Each Ref In ObjectsArray Do
			DocumentAttributesValues = DocumentsAttributesValues[Ref];
			DocumentAttributesValues.Date = Format(DocumentAttributesValues.Date, "DLF=D");
			DocumentAttributesValues.Number = ObjectsPrefixesClientServer.NumberForPrinting(DocumentAttributesValues.Number);
			FileName = StringFunctionsClientServer.InsertParametersIntoString(Template, DocumentsAttributesValues[Ref]);
			FilesNames.Insert(Ref, FileName);
		EndDo;
		
		// Print form details.
		OutputPaymentDetails = True;
		If PrintParameters.Property("OutputPaymentDetails") Then
			OutputPaymentDetails = PrintParameters.OutputPaymentDetails;
		EndIf;
		PrintForm.SpreadsheetDocument = PrintingAnOrderInvoice(ObjectsArray, PrintObjects, "Account", OutputPaymentDetails, OutputParameters.LanguageCode);
		PrintForm.TemplateSynonym = NStr("ru = 'Счет на оплату';
											|en = 'Proforma invoice';");
		PrintForm.FullTemplatePath = "Document._DemoCustomerProformaInvoice.PF_MXL_OrderInvoice";
		PrintForm.PrintFormFileName = FilesNames;
		PrintForm.OutputInOtherLanguagesAvailable = True;
	EndIf;
	
	// Print a sales order.
	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "OrderDocument");
	If PrintForm <> Undefined Then
		PrintForm.SpreadsheetDocument = PrintingAnOrderInvoice(ObjectsArray, PrintObjects, "OrderDocument");
		PrintForm.TemplateSynonym = NStr("ru = 'Заказ покупателя';
											|en = 'Sales order';");
		PrintForm.FullTemplatePath = "Document._DemoCustomerProformaInvoice.PF_MXL_OrderInvoice";
	EndIf;
	
	
	// Print form mailing parameters.
	OnSpecifyingRecipients(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
EndProcedure

// Prepares object data for printout.
// 
// Parameters:
//  DocumentsArray - Array - References to objects, for which printing data is requested.
//  TemplatesNamesArray - Array - Names of the templates the print data to insert to.
//
// Returns:
//  Map of KeyAndValue - a collection of references to objects and their data:
//   * Key - AnyRef - Reference to an infobase object.
//   * Value - Structure:
//    ** Key - String - Template name.
//    ** Value - Structure - Object data.
//
Function GetPrintInfo(Val DocumentsArray, Val TemplatesNamesArray) Export
	
	DataByAllObjects = New Map;
	
	For Each ObjectRef In DocumentsArray Do
		ObjectDataByTemplates = New Map;
		For Each TemplateName In TemplatesNamesArray Do
			ObjectDataByTemplates.Insert(TemplateName, GetObjectData(ObjectRef));
		EndDo;
		DataByAllObjects.Insert(ObjectRef, ObjectDataByTemplates);
	EndDo;
	
	AreasDetails = New Map;
	TemplatesBinaryData = New Map;
	TemplateTypes = New Map; // For backward compatibility purposes.
	
	For Each TemplateName In TemplatesNamesArray Do
		If TemplateName = "ProformaInvoice(OfficeOpenXML)" Then
			TemplatesBinaryData.Insert(TemplateName, 
				PrintManagement.PrintFormTemplate("Document._DemoCustomerProformaInvoice.PF_DOC_ProformaInvoice"));
		ElsIf TemplateName = "ProformaInvoice(MSWord)" Then
			TemplatesBinaryData.Insert(TemplateName, 
				PrintManagement.PrintFormTemplate("Document._DemoCustomerProformaInvoice.PF_DOC_ProformaInvoiceBackwardCompatibility"));
			TemplateTypes.Insert(TemplateName, "DOC"); // For backward compatibility purposes.
		ElsIf TemplateName = "ProformaInvoice(ODT)" Then
			TemplatesBinaryData.Insert(TemplateName, PrintManagement.PrintFormTemplate("CommonTemplate._DemoPF_ODT_ProformaInvoice"));
			TemplateTypes.Insert(TemplateName, "ODT"); // For backward compatibility purposes.
		EndIf;
		AreasDetails.Insert(TemplateName, GetADescriptionOfTheAreasOfTheOfficeDocumentLayout());
	EndDo;
	
	Templates = New Structure;
	Templates.Insert("AreasDetails", AreasDetails);
	Templates.Insert("TemplateTypes", TemplateTypes); // For backward compatibility purposes.
	Templates.Insert("TemplatesBinaryData", TemplatesBinaryData);
	
	Result = New Structure;
	Result.Insert("Data", DataByAllObjects);
	Result.Insert("Templates", Templates);
	
	Return Result;
	
EndFunction

// Adds information to be sent by email.
//
// Parameters:
//  SendOptions - 
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//
Procedure OnSpecifyingRecipients(SendOptions, ObjectsArray, PrintFormsCollection) Export
	
	QueryText =
	"SELECT ALLOWED
	|	_DemoCustomerProformaInvoice.Counterparty AS Counterparty,
	|	_DemoCustomerProformaInvoice.Partner AS Partner
	|FROM
	|	Document._DemoCustomerProformaInvoice AS _DemoCustomerProformaInvoice
	|WHERE
	|	_DemoCustomerProformaInvoice.Ref IN(&ObjectsArray)
	|
	|GROUP BY
	|	_DemoCustomerProformaInvoice.Counterparty,
	|	_DemoCustomerProformaInvoice.Partner";
	
	Query = New Query(QueryText);
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	QueryResult = Query.Execute().Unload();
	BuyerInformation = Undefined;
	If QueryResult.Count() = 1 Then
		BuyerInformation = QueryResult[0];
	EndIf;
	
	QueryText =
	"SELECT ALLOWED
	|	_DemoCustomerProformaInvoice.Number,
	|	_DemoCustomerProformaInvoice.Date,
	|	_DemoCustomerProformaInvoice.Ref
	|FROM
	|	Document._DemoCustomerProformaInvoice AS _DemoCustomerProformaInvoice
	|WHERE
	|	_DemoCustomerProformaInvoice.Ref IN(&ObjectsArray)";
	
	Query = New Query(QueryText);
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	ObjectSelection = Query.Execute().Select();
	
	If PrintFormsCollection.Count() = 1 Then
		SendOptions.Subject = PrintFormsCollection[0].TemplateSynonym;
		SendOptions.Text = NStr("ru = 'Файл во вложении.';
										|en = 'The file is attached.';");
	Else 
		SendOptions.Subject = NStr("ru = 'Документы';
										|en = 'Documents';");
		SendOptions.Text = NStr("ru = 'Файлы во вложении.';
										|en = 'The files are attached.';");
	EndIf;
	
	SendOptions.Text = SendOptions.Text + Chars.LF;
	For Each PrintForm In PrintFormsCollection Do
		While ObjectSelection.Next() Do
			SendOptions.Text = SendOptions.Text + Chars.LF + GenerateDocumentTitle(ObjectSelection, DocumentName_1(PrintForm.TemplateName));
		EndDo;
	EndDo;
	
	// Populate recipient only if there is one recipient for all documents.
	If BuyerInformation <> Undefined Then
		ObjectsOfContactInformation = New Array;
		ObjectsOfContactInformation.Add(BuyerInformation.Partner);
		ObjectsOfContactInformation.Add(BuyerInformation.Counterparty);
		
		ContactInformationTypes = CommonClientServer.ValueInArray(Enums.ContactInformationTypes.Email);
		PartnerAddresses = ContactsManager.ObjectsContactInformation(ObjectsOfContactInformation, 
			ContactInformationTypes,, CurrentSessionDate());
		
		Recipients = New Array;
		For Each Address In PartnerAddresses Do
			AddressPresentation = Address.Presentation;
			If Not IsBlankString(AddressPresentation) Then
				RecipientPresentation1 = String(Address.Object);
				Explanation = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Контактное лицо %1';
																						|en = 'Contact person %1';"), Address.Object);
				
				RecipientDetails = CreateRecipientDetails();
				RecipientDetails.Address = AddressPresentation;
				RecipientDetails.Presentation = RecipientPresentation1;
				RecipientDetails.ContactInformationSource = Address.Object;
				RecipientDetails.EmailAddressKind = String(Address.Kind);
				RecipientDetails.Explanation = Explanation;
				
				Recipients.Add(RecipientDetails);
			EndIf;
			
		EndDo;
		
		If Recipients.Count() = 0 Then
			RecipientDetails = CreateRecipientDetails();
			RecipientDetails.ContactInformationSource = BuyerInformation.Partner;
			Recipients.Add(RecipientDetails);
		EndIf;
		
		SendOptions.Recipient = Recipients;
	EndIf;
		
EndProcedure

// End StandardSubsystems.Print

// StandardSubsystems.AttachableCommands

// Defines the list of population commands.
//
// Parameters:
//   FillingCommands - See ObjectsFillingOverridable.BeforeAddFillCommands.FillingCommands.
//   Parameters - See ObjectsFillingOverridable.BeforeAddFillCommands.Parameters
//
Procedure AddFillCommands(FillingCommands, Parameters) Export
	
EndProcedure

// Defines the list of generation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses._DemoJobWithRoleAddressing.AddGenerateCommand(GenerationCommands);
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Intended for use by the AddGenerationCommands procedure in other object manager modules.
// Adds this object to the list of generation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - Details of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents._DemoCustomerProformaInvoice);
	
EndFunction

// End StandardSubsystems.AttachableCommands

// StandardSubsystems.MessagesTemplates

// Called when preparing message templates. Overrides the list of attributes and attachments.
//
// Parameters:
//  Attributes - See MessageTemplatesOverridable.OnPrepareMessageTemplate.Attributes
//  Attachments  - See MessageTemplatesOverridable.OnPrepareMessageTemplate.Attachments
//  AdditionalParameters - Structure - Additional information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
	MultiplierAttribute = Attributes.Find("_DemoCustomerProformaInvoice.Repetition");
	If MultiplierAttribute <> Undefined Then
		Attributes.Delete(MultiplierAttribute);
	EndIf;
	
	MessageTemplates.ExpandAttribute("Partner", Attributes, "", "ChiefAccountant,InformationSupport");
	
EndProcedure

// Called when creating a message from a template. Populates values in attributes and attachments.
//
// Parameters:
//  Message - Structure:
//    * AttributesValues - Map of KeyAndValue - List of template's attributes:
//      ** Key     - String - Template's attribute name.
//      ** Value - String - Template's filling value.
//    * CommonAttributesValues - Map of KeyAndValue - List of template's common attributes:
//      ** Key     - String - Template's attribute name.
//      ** Value - String - Template's filling value.
//    * Attachments - Map of KeyAndValue:
//      ** Key     - String - Template's attachment name.
//      ** Value - BinaryData
//                  - String - binary data or an address in a temporary storage of the attachment.
//  MessageSubject - AnyRef - The reference to a data source object.
//  AdditionalParameters - Structure -  Additional information about a message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Populates a list of recipients (in case the message is generated from a template).
//
// Parameters:
//   SMSMessageRecipients - ValueTable:
//     * PhoneNumber - String - Recipient's phone number.
//     * Presentation - String - Recipient presentation.
//     * Contact       - Arbitrary - The contact this phone number belongs to.
//  MessageSubject - AnyRef - The reference to a data source object.
//                   - Structure  - Structure that describes template parameters:
//    * SubjectOf               - AnyRef - The reference to a data source object.
//    * MessageKind - String - Message type: Email or SMSMessage.
//    * ArbitraryParameters - Map - List of arbitrary parameters.
//    * SendImmediately - Boolean - Flag indicating whether the message must be sent immediately.
//    * MessageParameters - Structure - Additional message parameters.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
	MessageTemplates.FillRecipients(SMSMessageRecipients, MessageSubject, "Counterparty", Enums.ContactInformationTypes.Phone);
	
EndProcedure

// Populates a list of recipients (in case the message is generated from a template).
//
// Parameters:
//   EmailRecipients - ValueTable - List of message recipients:
//     * SendingOption - String - Messaging options: "Whom" (To), "Copy" (CC), "HiddenCopy" (BCC), and "ReplyTo".
//     * Address           - String - Recipient's email address.
//     * Presentation   - String - Recipient presentation.
//     * Contact         - Arbitrary - The contact this email address belongs to.
//  MessageSubject - AnyRef - The reference to a data source object.
//                   - Structure  - Structure that describes template parameters:
//    * SubjectOf               - AnyRef - The reference to a data source object.
//    * MessageKind - String - Message type: Email or SMSMessage.
//    * ArbitraryParameters - Map - List of arbitrary parameters.
//    * SendImmediately - Boolean - Flag indicating whether the message must be sent immediately.
//    * MessageParameters - Structure - Additional message parameters.
//    * ConvertHTMLForFormattedDocument - Boolean - Flag indicating whether the HTML text must be converted.
//             Applicable to messages containing images.
//             Required due to the specifics of image output in formatted documents. 
//    * Account - CatalogRef.EmailAccounts - Sender's email account.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
	MessageTemplates.FillRecipients(EmailRecipients, MessageSubject, "Counterparty");
	
EndProcedure

// End StandardSubsystems.MessagesTemplates

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Partner)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS _DemoCustomerProformaInvoice
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = _DemoCustomerProformaInvoice.Partner
	|
	|LEFT JOIN Catalog._DemoPartnersContactPersons AS _DemoPartnersContactPersons
	|	ON _DemoPartnersContactPersons.Owner = _DemoCustomerProformaInvoice.Partner
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersContactPersons
	|	ON ExternalUsersContactPersons.AuthorizationObject = _DemoPartnersContactPersons.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)
	|	OR ValueAllowed(ExternalUsersContactPersons.Ref)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Update handlers.

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	PrintManagement.RegisterNewTemplateName(
		"Document._DemoCustomerProformaInvoice.PF_DOC_ProformaInvoiceBackwardCompatibility_ru", 
		Parameters);
	
EndProcedure

// Records of renaming the
// Document._DemoCustomerProformaInvoice.PF_DOC_ProformaInvoice_ru 
// print form template to Document._DemoCustomerProformaInvoice.PF_DOC_ProformaInvoiceBackwardCompatibility_ru in the UserPrintTemplates information register.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Templates = New Map;
	Templates["Document._DemoCustomerProformaInvoice.PF_DOC_ProformaInvoiceBackwardCompatibility_ru"] = "Document._DemoCustomerProformaInvoice.PF_DOC_ProformaInvoice_ru";
	PrintManagement.TransferUserTemplates(Templates, Parameters);
	
EndProcedure

#EndRegion

#Region Private

Function UnpaidCustomerInvoicesCount(Partner)
	
	Query = New Query;
	Query.Text =
	"SELECT
	| _DemoInvoiceForPaymentToTheBuyerOfGoods.Ref AS Ref
	|FROM
	| Document._DemoCustomerProformaInvoice.Goods AS _DemoInvoiceForPaymentToTheBuyerOfGoods
	|WHERE
	| _DemoInvoiceForPaymentToTheBuyerOfGoods.Ref.Partner = &Partner
	|
	|GROUP BY
	| _DemoInvoiceForPaymentToTheBuyerOfGoods.Ref
	|
	|HAVING
	| SUM(_DemoInvoiceForPaymentToTheBuyerOfGoods.Sum) > _DemoInvoiceForPaymentToTheBuyerOfGoods.Ref.PayAmount";
	
	Query.SetParameter("Partner", Partner);
	QueryResult = Query.Execute().Unload();
	
	Return QueryResult;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Prepare printable spreadsheet documents.

// Returns the document title for a print form.
//
// Parameters:
//  Header - A structure with the following fields:
//           Number - String, Number - Document number.
//           Date - Date - Document date.
//           Presentation - String - Optional. Platform presentation of the document reference.
//                                    If DocumentName is not specified, the name will be parsed from this parameter.
//                                    
//  DocumentName_1 - String - The document name (for example, "Proforma invoice").
//
// Returns:
//  String - Document title.
//
Function GenerateDocumentTitle(Header, Val DocumentName_1 = "")
	
	DocumentData = New Structure("Number,Date,Presentation");
	FillPropertyValues(DocumentData, Header);
	
	// If the document name is not passed explicitly, get it from the document presentation.
	If IsBlankString(DocumentName_1) And ValueIsFilled(DocumentData.Presentation) Then
		NumberPosition = StrFind(DocumentData.Presentation, DocumentData.Number);
		If NumberPosition > 0 Then
			DocumentName_1 = TrimAll(Left(DocumentData.Presentation, NumberPosition - 1));
		EndIf;
	EndIf;

	NumberForPrinting = ObjectsPrefixesClientServer.NumberForPrinting(DocumentData.Number);
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 № %2 от %3';
																		|en = '%1 #%2, %3';"),
		DocumentName_1, NumberForPrinting, Format(DocumentData.Date, "DLF=DD"));
	
EndFunction

// Returns:
//   Array of See PaymentDocumentStructure - Collection of payment document details.
//
Function DocumentsData(ObjectsArray)
	
	ReturnArray = New Array;
	
	Query = New Query();
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("Kind", ContactsManager.ContactInformationKindByName("_DemoCounterpartyAddress"));
	Query.Text =
	"SELECT
	|	_DemoContractorsContactInformation.Presentation AS PayerAddress,
	|	_DemoContractorsContactInformation.Ref AS Counterparty
	|INTO ttAddress
	|FROM
	|	Document._DemoCustomerProformaInvoice AS CustomerProformaInvoice
	|		LEFT JOIN Catalog._DemoCounterparties.ContactInformation AS _DemoContractorsContactInformation
	|		ON CustomerProformaInvoice.Counterparty = _DemoContractorsContactInformation.Ref
	|WHERE
	|	CustomerProformaInvoice.Ref IN(&ObjectsArray)
	|	AND ISNULL(_DemoContractorsContactInformation.Kind, """") = &Kind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerProformaInvoice.PayAmount AS AmountAsNumber,
	|	CustomerProformaInvoice.Organization.Description AS RecipientText,
	|	CustomerProformaInvoice.Counterparty.DescriptionFull AS FullPayerName,
	|	CustomerProformaInvoice.BankAccount AS BankAccount,
	|	CASE
	|		WHEN CustomerProformaInvoice.BankAccount.ManualBankDetailsChange
	|			THEN CustomerProformaInvoice.BankAccount.BankDescription
	|		ELSE CustomerProformaInvoice.BankAccount.Bank.Description
	|	END AS RecipientBankDescription,
	|	CASE
	|		WHEN CustomerProformaInvoice.BankAccount.ManualBankDetailsChange
	|			THEN CustomerProformaInvoice.BankAccount.BankBIC
	|		ELSE CustomerProformaInvoice.BankAccount.Bank.Code
	|	END AS RecipientBankBIC,
	|	CASE
	|		WHEN CustomerProformaInvoice.BankAccount.ManualBankDetailsChange
	|			THEN CustomerProformaInvoice.BankAccount.BankCorrAccount
	|		ELSE CustomerProformaInvoice.BankAccount.Bank.CorrAccount
	|	END AS RecipientBankAccount,
	|	CustomerProformaInvoice.BankAccount.AccountNumber AS RecipientAccountNumber,
	|	CustomerProformaInvoice.Counterparty.TIN AS RecipientTIN,
	|	CustomerProformaInvoice.Number AS Number,
	|	CustomerProformaInvoice.Ref AS Ref,
	|	CustomerProformaInvoice.Date AS Date,
	|	ISNULL(ttAddress.PayerAddress, """") AS PayerAddress
	|FROM
	|	Document._DemoCustomerProformaInvoice AS CustomerProformaInvoice
	|		LEFT JOIN ttAddress AS ttAddress
	|		ON CustomerProformaInvoice.Counterparty = ttAddress.Counterparty
	|WHERE
	|	CustomerProformaInvoice.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	CustomerProformaInvoice.PointInTime
	|TOTALS BY
	|	Ref";

	Result = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	MessageText = "";
	
	While Result.Next() Do
		
		FillError = False;
		If Not ValueIsFilled(Result.BankAccount) Then
			MessageText = NStr("ru = 'Не заполнен обязательный реквизит: ""Банковский счет""';
									|en = 'Required attribute ""Bank account"" is blank';");
			Common.MessageToUser(MessageText,Result.Ref);
			FillError = True;
		EndIf;
		
		If Not ValueIsFilled(Result.RecipientBankDescription) Then
			MessageText = NStr("ru = 'В банковском счете не заполнен реквизит: ""Наименование банка""';
									|en = 'Bank name is not filled in the bank account';");
			Common.MessageToUser(MessageText,Result.Ref);
			FillError = True;
		EndIf;
		
		If Not ValueIsFilled(Result.RecipientBankBIC) Then
			MessageText = NStr("ru = 'В банковском счете не заполнен реквизит: ""БИК банка""';
									|en = 'Bank code is not filled in the bank account';");
			Common.MessageToUser(MessageText,Result.Ref);
			FillError = True;
		EndIf;
		
		If Not ValueIsFilled(Result.RecipientAccountNumber) Then
			MessageText = NStr("ru = 'В банковском счете не заполнен реквизит: ""Номер счета""';
									|en = 'Account number is not filled in the bank account';");
			Common.MessageToUser(MessageText,Result.Ref);
			FillError = True;
		EndIf;
		
		If FillError Then
			Continue;
		EndIf;
		
		StructureOfData = PaymentDocumentStructure();
		PaymentDetails = Result.Select();
		PaymentDetails.Next();
		FillPropertyValues(StructureOfData, PaymentDetails);
		StructureOfData.PaymentPurposes = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Оплата по счету №%1 от %2';
																										|en = 'Payment against proforma invoice #%1, %2';"),
			ObjectsPrefixesClientServer.NumberForPrinting(PaymentDetails.Number), Format(PaymentDetails.Date, "DLF=D"));
		
		ReturnArray.Add(StructureOfData);
	EndDo;
	
	Return ReturnArray;
	
EndFunction

// Returns:
//  Structure:
//   * PayerAddress - String 
//   * PayerMiddleName - String 
//   * PayerName - String
//   * LastPayerName - String 
//   * PaymentPurposes - String
//   * AmountAsNumber - Number
//   * RecipientBankAccount 
//   * RecipientBankBIC 
//   * RecipientBankDescription 
//   * RecipientAccountNumber 
//   * RecipientText 
//   * Ref - DocumentRef._DemoCustomerProformaInvoice
// 
Function PaymentDocumentStructure()
	
	ReturnStructure = New Structure;
	
	ReturnStructure.Insert("Ref");
	ReturnStructure.Insert("RecipientText");
	ReturnStructure.Insert("RecipientAccountNumber");
	ReturnStructure.Insert("RecipientBankDescription");
	ReturnStructure.Insert("RecipientBankBIC");
	ReturnStructure.Insert("RecipientBankAccount");
	
	ReturnStructure.Insert("AmountAsNumber");
	ReturnStructure.Insert("PaymentPurposes", "");
	
	ReturnStructure.Insert("LastPayerName", "");
	ReturnStructure.Insert("PayerName", "");
	ReturnStructure.Insert("PayerMiddleName", "");
	ReturnStructure.Insert("PayerAddress");
	
	Return ReturnStructure;
	
EndFunction

Function ContactInformationForProformaInvoice(Organization, Date, LanguageCode)
	
	InformationRecords = ContactInformationInfo();
	
	Filter = ContactsManager.FilterContactInformation3();
	Filter.ContactInformationKinds.Add(ContactsManager.ContactInformationKindByName("_DemoCompanyLegalAddress"));
	Filter.Date = Date;
	Filter.LanguageCode = LanguageCode;
	
	CITable = ContactsManager.ContactInformation(Organization, Filter);
	
	For Each CITableRow In CITable Do
		
		// Define a lower level of a locality in the address.
		CityLocality = "";
		
		If CITableRow.Kind =  ContactsManager.ContactInformationKindByName("_DemoCompanyLegalAddress") Then
			InformationRecords.LegalAddress = CITableRow.Presentation;
			InformationRecords.CityFromLegalAddress = CityLocality;
			InformationRecords.LegalAddress = CITableRow.Presentation;
			InformationRecords.FieldsValuesLegalAddress = CITableRow.Value;
			InformationRecords.CityFromLegalAddress = CityLocality;
		EndIf;
		
	EndDo;
	
	Return InformationRecords;
EndFunction

Function ContactInformationInfo()
	InformationRecords = New Structure;
	InformationRecords.Insert("LegalAddress", "");
	InformationRecords.Insert("CityFromLegalAddress", "");
	InformationRecords.Insert("LegalAddress", "");
	InformationRecords.Insert("FieldsValuesLegalAddress", "");
	InformationRecords.Insert("CityFromLegalAddress", "");
	
	Return InformationRecords;
EndFunction

Function CreateRecipientDetails()
	RecipientDetails = New Structure;
	RecipientDetails.Insert("Address", "");
	RecipientDetails.Insert("Presentation", "");
	RecipientDetails.Insert("ContactInformationSource");
	RecipientDetails.Insert("EmailAddressKind", "");
	RecipientDetails.Insert("Explanation", "");
	
	Return RecipientDetails;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Office document template management.

Function GetObjectData(ObjectReference)
	
	SetPrivilegedMode(True);
	
	Object = ObjectReference.GetObject();
	
	ObjectData = New Structure;
	
	ObjectData.Insert("Comment", Object.Comment);
	ObjectData.Insert("Counterparty",  Common.ObjectAttributeValue(Object.Counterparty, "Description"));
	ObjectData.Insert("PayAmount", Object.PayAmount);
	ObjectData.Insert("Organization", Common.ObjectAttributeValue(Object.Organization, "Description"));
	ObjectData.Insert("Date",        String(CurrentSessionDate()));
	
	ObjectData.Insert("Goods", New Array);
	
	For Each LineOfATabularSection In Object.Goods Do
		RowOfProductsTable = New Structure;
		RowOfProductsTable.Insert("Products",LineOfATabularSection.Products);
		RowOfProductsTable.Insert("Count",	LineOfATabularSection.Count);
		RowOfProductsTable.Insert("Price",		LineOfATabularSection.Price);
		RowOfProductsTable.Insert("Sum",		LineOfATabularSection.Sum);
		RowOfProductsTable.Insert("Total",		LineOfATabularSection.Total);
		
		If Not LineOfATabularSection.Products.PicturesFile.IsEmpty() Then
			Drawing = FilesOperations.FileData(LineOfATabularSection.Products.PicturesFile).RefToBinaryFileData;
		Else
			Drawing = Undefined;
		EndIf;
		RowOfProductsTable.Insert("Drawing", Drawing);
		
		ObjectData.Goods.Add(RowOfProductsTable);
	EndDo;
	
	Return ObjectData;
	
EndFunction

Function GetADescriptionOfTheAreasOfTheOfficeDocumentLayout()
	
	AreasDetails = New Structure;
	
	PrintManagement.AddAreaDetails(AreasDetails, "Header",	"Header");
	PrintManagement.AddAreaDetails(AreasDetails, "Footer",		"Footer");
	PrintManagement.AddAreaDetails(AreasDetails, "Title",			"Shared3");
	PrintManagement.AddAreaDetails(AreasDetails, "BottomPart",			"Shared3");
	PrintManagement.AddAreaDetails(AreasDetails, "ProductsTableHeader",	"TableRow");
	PrintManagement.AddAreaDetails(AreasDetails, "RowTableProducts",	"TableRow");
	PrintManagement.AddAreaDetails(AreasDetails, "TableHeaderProductsText",	"Shared3");
	PrintManagement.AddAreaDetails(AreasDetails, "TheProductsNomenclatureHeader",	"Shared3");
	PrintManagement.AddAreaDetails(AreasDetails, "GoodsProducts",		"List");
	PrintManagement.AddAreaDetails(AreasDetails, "TheProductsTotalHeader",		"Shared3");
	PrintManagement.AddAreaDetails(AreasDetails, "GoodsTotal",			"List");
	PrintManagement.AddAreaDetails(AreasDetails, "Paragraph",				"Shared3");
	
	Return AreasDetails;
	
EndFunction

Function DocumentName_1(Id)
	Result = "";
	If Id = "Account" Then
		Result = NStr("ru = 'Демо: Счет на оплату';
						|en = 'Demo: Proforma invoice';")
	ElsIf Id = "OrderDocument" Then
		Result = NStr("ru = 'Демо: Заказ покупателя';
						|en = 'Demo: Sales order';")
	EndIf;
	Return Result;
EndFunction

#EndRegion

#EndIf