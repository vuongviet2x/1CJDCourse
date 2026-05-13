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

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.AdditionalReportsAndDataProcessors

// Returns info about an external data processor.
//
// Returns:
//   See AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo
//
Function ExternalDataProcessorInfo() Export
	RegistrationParameters = AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo("2.2.2.1");
	RegistrationParameters.Information = NStr("ru = 'Обработка для загрузки номенклатуры из прайс-листа фирмы ""1C"" с использованием профилей безопасности. На сервере должен быть установлен Microsoft Office или Data Connectivity Components.';
											|en = 'Processing to import products from the 1C price list using security profiles. The server must have Microsoft Office or Data Connectivity Components installed.';");
	RegistrationParameters.Kind = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalDataProcessor();
	RegistrationParameters.Version = "3.1.10.138";
	RegistrationParameters.SafeMode = True;
	
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Параметры загрузки номенклатуры из прайс-листа (профили безопасности)';
								|en = 'Import parameters of product from price list (security profiles)';");
	Command.Id = "FormSettings";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm();
	Command.ShouldShowUserNotification = True;
	
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Загрузить номенклатуру из прайс-листа фирмы ""1C"" (профили безопасности)';
								|en = 'Import products from the 1C price list (security profiles)';");
	Command.Id = "ImportProductsFromPriceList";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeServerMethodCall();
	Command.ShouldShowUserNotification = False;
	
	Resolution = SafeModeManager.PermissionToCreateCOMClass("Excel.Application", "00024500-0000-0000-C000-000000000046");
	RegistrationParameters.Permissions.Add(Resolution);
	
	Resolution = SafeModeManager.PermissionToCreateCOMClass("ADODB.Connection", "00000514-0000-0010-8000-00AA006D2EA4");
	RegistrationParameters.Permissions.Add(Resolution);
	
	Return RegistrationParameters;
EndFunction

// Server commands handler.
//
// Parameters:
//   CommandID - String    - Command name given in function ExternalDataProcessorInfo().
//   ExecutionParameters  - Structure - Command execution context:
//       * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - Data processor reference.
//           Can be used to read data processor parameters.
//           As an example, see the comments to function AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm().
//
Procedure ExecuteCommand(CommandID, ExecutionParameters) Export
	FileAddress = CommonClientServer.StructureProperty(ExecutionParameters, "FileAddress");
	If Not ValueIsFilled(FileAddress) Then
		Ref = ExecutionParameters.AdditionalDataProcessorRef;
		SettingsStorage = Common.ObjectAttributeValue(Ref, "SettingsStorage");
		Settings = SettingsStorage.Get();
		If TypeOf(Settings) = Type("Structure") Then
			FileAddress = CommonClientServer.StructureProperty(Settings, "FileAddress");
		Else
			FileAddress = "https://www.1c.ru/ftp/pub/pricelst/price_1c.zip";
		EndIf;
	EndIf;
	
	ImportProductsFromPriceList(FileAddress);
EndProcedure

// End StandardSubsystems.AdditionalReportsAndDataProcessors

#EndRegion

#EndRegion

#Region Private

Procedure ImportProductsFromPriceList(FileAddress)
	VerifyAccessRights("Insert", Metadata.Catalogs._DemoProducts);
	If Not ValueIsFilled(FileAddress) Then
		Raise NStr("ru = 'Перед выполнением команды укажите адрес файла в настройках.';
								|en = 'Before executing the command, specify the file address in the settings.';");
	EndIf;
	
	// Import a file.
	TempFilesDir = CommonClientServer.AddLastPathSeparator(GetTempFileName("Demo"));
	CreateDirectory(TempFilesDir);
	
	AddressLength = StrLen(FileAddress);
	LastSlashPosition = AddressLength;
	Char = Mid(FileAddress, LastSlashPosition, 1);
	While Char <> "\" And Char <> "/" Do
		LastSlashPosition = LastSlashPosition - 1;
		Char = Mid(FileAddress, LastSlashPosition, 1);
	EndDo;
	
	FileName = Mid(FileAddress, LastSlashPosition + 1);
	FullFileName = TempFilesDir + FileName;
	
	FileGettingParameters = GetFilesFromInternetClientServer.FileGettingParameters();
	FileGettingParameters.PathForSaving = FullFileName;
	GetFilesFromInternet.DownloadFileAtServer(FileAddress, FileGettingParameters);
	
	// Extract from a ZIP archive.
	If Upper(Right(FileName, 3)) = "ZIP" Then
		ZIPReader = New ZipFileReader(FullFileName);
		Item = ZIPReader.Items[0];
		ZIPReader.Extract(Item, TempFilesDir);
		FullFileName = TempFilesDir + Item.Name;
	EndIf;
	
	// Import a price list.
	ImportedProducts = New ValueTable;
	ImportedProducts.Columns.Add("Description", New TypeDescription("String",,New StringQualifiers(100, AllowedLength.Variable)));
	ImportedProducts.Columns.Add("Price", New TypeDescription("Number"));
	
	Try
		ReadProductsExcel(FullFileName, ImportedProducts);
	Except
		ErrorInformationExcel = ErrorInfo();
		Try
			ReadProductsADODB(FullFileName, ImportedProducts);
		Except
			ErrorInformationADODB = ErrorInfo();
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось прочитать номенклатуру из файла Excel.
					|Сообщение об ошибке от COM-объекта Excel.Application:
					|	%1
					|Сообщение об ошибке от COM-объекта ADODB.Connection:
					|	%2
					|Обратитесь к системному администратору.';
					|en = 'Failed to read product from the Excel file.
					| An error message from COM object Excel.Application:
					|	%1
					|An error message from COM object ADODB.Connection:
					|	%2
					|Contact system administrator.';"),
				StrReplace(ErrorProcessing.DetailErrorDescription(ErrorInformationExcel), Chars.LF, Chars.LF + Chars.Tab),
				StrReplace(ErrorProcessing.DetailErrorDescription(ErrorInformationADODB), Chars.LF, Chars.LF + Chars.Tab));
		EndTry;
	EndTry;
	ImportPriceList(ImportedProducts);
	
	// Delete temporary files.
	DeleteFiles(TempFilesDir);
EndProcedure

// ACC:1353-off COM object operations.
Procedure ReadProductsADODB(FullFileName, ImportedProducts)
	// Import data from Excel to a value table.
	Try
		Connection = New COMObject("ADODB.Connection");
	Except
		Raise NStr("ru = 'Не удалось подключить объект ADODB.
			|Вероятные причины:
			| - У пользователя недостаточно прав на создание COM-объектов;
			| - Включен контроль учетных записей Windows;
			| - Операционная система сервера не из семейства Windows.
			|
			|Техническая информация:';
			|en = 'Failed to attach ADODB object.
			|Possible causes:
			| - User has insufficient rights to create COM objects,
			| - Windows account control enabled,
			| - Server operating system is not from the Windows family.
			|
			|Technical information:';") + Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	
	ConnectionString = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=""" + TrimAll(FullFileName) + """;Extended Properties=""Excel 12.0;HDR=YES;IMEX=1;""";
	Try
		Connection.Open(ConnectionString);
	Except
		Raise NStr("ru = 'Не удалось прочитать прайс-лист объектом ADODB.
			|Вероятные причины:
			| - На сервере не установлен пакет ""Microsoft Access Database Engine 2010 Redistributable"";
			| - У пользователя недостаточно прав на создание COM-объектов;
			| - Включен контроль учетных записей Windows;
			|
			|Техническая информация:';
			|en = 'Failed to read price list using ADODB object.
			|Possible causes:
			| - The server does not have the ""Microsoft Access Database Engine 2010 Redistributable"" package,
			| - User has insufficient rights to create COM objects,
			| - Windows account control enabled,
			|
			|Technical information:';") + Chars.LF  + ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;

	Connection.CursorLocation = 3;
	
	QueryText = "SELECT * FROM &Table";
	QueryText = StrReplace(QueryText, "&Table", "[A:CZ]");
	
	RecordSet = Connection.Execute(QueryText);
	While Not RecordSet.EOF() Do
		Description = RecordSet.Fields(1).Value;
		Price         = RecordSet.Fields(5).Value;
		If ValueIsFilled(Description) And ValueIsFilled(Price) Then
			NewRow = ImportedProducts.Add();
			NewRow.Description = Description;
			NewRow.Price         = Price;
		EndIf;
		RecordSet.MoveNext();
	EndDo;
	
	RecordSet.Close();
	RecordSet = Undefined;
	Connection.Close();
	Connection = Undefined;

EndProcedure

Procedure ReadProductsExcel(FullFileName, ImportedProducts)
	// Read a Microsoft Excel sheet.
	Try
		Excel = New COMObject("Excel.Application");
	Except
		Raise NStr("ru = 'Не удалось подключить COM-объект Excel.
			|Вероятные причины:
			| - На сервере не установлен Microsoft Office;
			| - У пользователя недостаточно прав на создание COM-объектов;
			| - Включен контроль учетных записей Windows;
			| - Операционная система сервера не из семейства Windows.
			|
			|Техническая информация:';
			|en = 'Failed to attach Excel COM object.
			|Possible causes:
			| - Server does not have Microsoft Office,
			| - User has insufficient rights to create COM objects,
			| - Windows account control enabled,
			| - Server operating system is not from the Windows family.
			|
			|Technical information:';") + Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	Excel.AutomationSecurity = 3; // msoAutomationSecurityForceDisable = 3
	Excel.Application.Workbooks.Open(FullFileName);
	Excel.DisplayAlerts = 0;
	ExcelSheet = Excel.Sheets(1);
	TotalRows = ExcelSheet.Cells.SpecialCells(11).Row;
	
	ExcelSheetRange = ExcelSheet.Range(ExcelSheet.Cells(1,2), ExcelSheet.Cells(TotalRows,4));
	Data = ExcelSheetRange.Value.Unload();
	
	DescriptionColumnValues = Data[0];
	ColumnValuesPrice = Data[2];
	
	For IndexOf = 0 To TotalRows - 1 Do
		Description = DescriptionColumnValues[IndexOf];
		Price         = ColumnValuesPrice[IndexOf];
		If Not ValueIsFilled(Price) Or Not ValueIsFilled(Description) Then
			Continue;
		EndIf;
		
		NewRow = ImportedProducts.Add();
		NewRow.Description = Description;
		NewRow.Price         = Price;
	EndDo;
	
	Data = Undefined;
	ExcelSheetRange = Undefined;
	TotalRows = Undefined;
	ExcelSheet = Undefined;
	
	Excel.Application.Workbooks(1).Close();
	Excel.Quit();
	
	Excel = Undefined;
	
EndProcedure
// ACC:1353-on

Procedure ImportPriceList(ImportedProducts)
	
	ProductsToImportToBorder = ImportedProducts.Count() - 1;
	
	// Read existing products.
	Query = New Query;
	Query.Text =
	"SELECT
	|	Table.Ref,
	|	Table.Description
	|FROM
	|	Catalog._DemoProducts AS Table";
	
	ExistingProducts = Query.Execute().Unload();
	ExistingProducts.Indexes.Add("Description");
	
	// Import.
	RandomNumberGenerator = New RandomNumberGenerator;
	ItemsCreated = 0;
	ItemsRefreshed = 0;
	For Number = 1 To WeekDay(CurrentSessionDate()) Do
		BeginTransaction();
		Try
			RandomIndex = RandomNumberGenerator.RandomNumber(0, ProductsToImportToBorder);
			RowToImport = ImportedProducts[RandomIndex];
			ExistingRow = ExistingProducts.Find(RowToImport.Description, "Description");
			If ExistingRow = Undefined Then
				CatalogObject = Catalogs._DemoProducts.CreateItem();
				CatalogObject.SetNewCode();
				CatalogObject.Description = RowToImport.Description;
				ItemsCreated = ItemsCreated + 1;
			Else
				Block = New DataLock;
				LockItem = Block.Add("Catalog._DemoProducts");
				LockItem.SetValue("Ref", ExistingRow.Ref);
				Block.Lock();
				
				CatalogObject = ExistingRow.Ref.GetObject();
				ItemsRefreshed = ItemsRefreshed + 1;
			EndIf;
			CatalogObject.Price = RowToImport.Price;
			CatalogObject.Write();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
	// Output the result.
	Message = New UserMessage;
	Message.Text = NStr("ru = 'Из прайс-листа загружены новые позиции.';
							|en = 'New items were imported from the price list.';");
	Message.Message();
	Message = New UserMessage;
	Message.Text = StrReplace(NStr("ru = 'Загружено позиций: %1';
										|en = 'Items imported: %1';"), "%1", ItemsCreated + ItemsRefreshed);
	Message.Message();
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf