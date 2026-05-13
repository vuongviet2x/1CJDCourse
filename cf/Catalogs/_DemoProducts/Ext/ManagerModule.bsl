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

// StandardSubsystems.ImportDataFromFile

// Sets parameters of data import from file.
//
// Parameters:
//  Parameters - See ImportDataFromFile.ImportFromFileParameters
// 
Procedure DefineParametersForLoadingDataFromFile(Parameters) Export

	Parameters.Title = NStr("ru = 'Демо: Номенклатура';
								|en = 'Demo: Products';");
	Parameters.ObjectPresentation = NStr("ru = 'Номенклатура';
											|en = 'Product';");

	BarcodeTypeDetails = New TypeDescription("String", , New StringQualifiers(13));
	DescriptionTypeDetails = New TypeDescription("String", , New StringQualifiers(100));
	Parameters.ColumnDataType.Insert("Barcode", BarcodeTypeDetails);
	Parameters.ColumnDataType.Insert("Description", DescriptionTypeDetails);

EndProcedure

// Maps data being imported and infobase data.
// Composition and type of table columns match the catalog attributes or the "ImportingFromFile" template.
//
// Parameters:
//   DataToImport - See ImportDataFromFile.MappingTable
//
Procedure MatchUploadedDataFromFile(DataToImport) Export

	Query = New Query;
	Query.Text =
	"SELECT
	|	DataForComparison.Barcode AS Barcode,
	|	DataForComparison.Description AS Description,
	|	DataForComparison.Id AS Id
	|INTO DataForComparison
	|FROM
	|	&DataForComparison AS DataForComparison
	|
	|INDEX BY
	|	DataForComparison.Barcode,
	|	DataForComparison.Description,
	|	DataForComparison.Id
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
	|			AND (_DemoProducts.Barcode <> """")
	|			AND (_DemoProducts.DeletionMark = FALSE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataForComparison.Description AS Description,
	|	DataForComparison.Id AS Id
	|INTO DataForMatchingByName
	|FROM
	|	DataForComparison AS DataForComparison
	|		INNER JOIN MappedProductByBarcode AS MappedProductByBarcode
	|		ON DataForComparison.Barcode = MappedProductByBarcode.Barcode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	_DemoProducts.Ref AS Products,
	|	DataForMatchingByName.Id AS Id
	|FROM
	|	DataForMatchingByName AS DataForMatchingByName
	|		INNER JOIN Catalog._DemoProducts AS _DemoProducts
	|		ON (_DemoProducts.Description = DataForMatchingByName.Description)
	|			AND (_DemoProducts.DeletionMark = FALSE)
	|
	|UNION ALL
	|
	|SELECT
	|	MappedProductByBarcode.Ref,
	|	MappedProductByBarcode.Id
	|FROM
	|	MappedProductByBarcode AS MappedProductByBarcode";

	Query.SetParameter("DataForComparison", DataToImport);

	QueryResult = Query.Execute().Select();

	While QueryResult.Next() Do
		Filter = New Structure("Id", QueryResult.Id);
		For Each TableRow In DataToImport.FindRows(Filter) Do
			TableRow.MappingObject = QueryResult.Products;
		EndDo;
	EndDo;

EndProcedure

// Import data from a file.
//
// Parameters:
//  DataToImport - See ImportDataFromFile.DescriptionOfTheUploadedDataForReferenceBooks
//  ImportParameters - See ImportDataFromFile.DataLoadingSettings
//  Cancel - Boolean    - Abort import. For example, if some data is invalid.
//
Procedure LoadFromFile(DataToImport, ImportParameters, Cancel) Export

	For Each TableRow In DataToImport Do
		MappingObjectIsFull = ValueIsFilled(TableRow.MappingObject);

		If (MappingObjectIsFull And ImportParameters.UpdateExistingItems = 0)
			Or (Not MappingObjectIsFull And ImportParameters.CreateNewItems = 0) Then
			TableRow.RowMappingResult = "Skipped";
			Continue;
		EndIf;

		AccessManagement.DisableAccessKeysUpdate(True);
		BeginTransaction();
		Try

			If MappingObjectIsFull Then

				Block        = New DataLock;
				LockItem = Block.Add("Catalog._DemoProducts");
				LockItem.SetValue("Ref", TableRow.MappingObject);
				Block.Lock();

				CatalogItem = TableRow.MappingObject.GetObject();

				If CatalogItem = Undefined Then
					Raise StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Номенклатура с артикулом %1 не существует.';
							|en = 'Product with product ID %1 does not exist.';"), TableRow.SKU);
				EndIf;
				TableRow.RowMappingResult = "Updated";

			Else

				CatalogItem                         = CreateItem();
				TableRow.RowMappingResult = "Created";

			EndIf;

			CatalogItem.Description = TableRow.Description;
			CatalogItem.Barcode = TableRow.Barcode;
			If ValueIsFilled(TableRow.Country) Then
				CatalogItem.OriginCountry = Catalogs.WorldCountries.FindByDescription(TableRow.Country);
			EndIf;

			If ValueIsFilled(TableRow.Parent) Then
				Parent = FindByDescription(TableRow.Parent, True);
				If Parent = Undefined Or Not Parent.IsFolder Or Parent.IsEmpty() Then
					Parent = CreateFolder();
					Parent.Description = TableRow.Parent;
					Parent.Write();
				EndIf;
				CatalogItem.Parent = Parent.Ref;
			EndIf;

			ProductKind = Catalogs._DemoProductsKinds.FindByDescription(TableRow.ProductKind, True);
			If ProductKind = Undefined Or ProductKind.IsEmpty() Then
				ProductKind = Catalogs._DemoProductsKinds.CreateItem();
				ProductKind.Description = TableRow.ProductKind;
				ProductKind.Write();
			EndIf;

			CatalogItem.ProductKind = ProductKind.Ref;
			If Not CatalogItem.CheckFilling() Then
				TableRow.RowMappingResult = "Skipped";
				UserMessages = GetUserMessages(True);
				If UserMessages.Count() > 0 Then
					MessagesText = "";
					For Each UserMessage In UserMessages Do
						MessagesText  = MessagesText + UserMessage.Text + Chars.LF;
					EndDo;
					TableRow.ErrorDescription = MessagesText;
				EndIf;
				RollbackTransaction();
			Else
				CatalogItem.Write();
				TableRow.MappingObject = CatalogItem.Ref;

				ImportDataFromFile.WritePropertiesOfObject(CatalogItem.Ref, TableRow);

				AccessManagement.DisableAccessKeysUpdate(False);
				CommitTransaction();
			EndIf;
		Except
			RollbackTransaction();
			AccessManagement.DisableAccessKeysUpdate(False, False);
			Cause = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			TableRow.RowMappingResult = "Skipped";
			TableRow.ErrorDescription = NStr("ru = 'Невозможна запись данных по причине:';
												|en = 'Couldn''t save the data due to:';") + Chars.LF + Cause;
		EndTry;
	EndDo;

EndProcedure

// Maps data being imported to the Substitutes table
// with infobase data and populates the AddressOfMappingTable and ConflictsList parameters.
//
// Parameters:
//   AddressOfUploadedData    - String - Temporary storage address with a value table
//                                        that contains data imported from the file. Columns match
//                                        the object attributes or the ImportingFromFile template columns.
//                                        The table must include the column:
//     * Id - Number - Row number.
//   AddressOfMappingTable - String - Temporary storage address containing an emptytable,
//                                        that is a copy of a spreadsheet document. 
//                                        The table must be populated with values from the AddressOfDataToImport table.
//   ConflictsList  - See ImportDataFromFile.ANewListOfAmbiguities
//   FullTabularSectionName - String - The full name of the recipient table.
//   AdditionalParameters - Arbitrary - Any additional information.
//
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList,
	FullTabularSectionName, AdditionalParameters) Export

	Substitutes =  GetFromTempStorage(AddressOfMappingTable); //  See ImportDataFromFile.DescriptionOfTheUploadedDataForReferenceBooks
	DataToImport = GetFromTempStorage(AddressOfUploadedData);
	
	// Product item compatibility.
	ProductCompatibility = New Map;
	For Each Value In Metadata.Enums._DemoProductsCompatibility.EnumValues Do
		Name = Upper(Value.Presentation());
		ProductCompatibility.Insert(Name, Enums._DemoProductsCompatibility[Value.Name]);
	EndDo;

	For Each TableRow In DataToImport Do
		Substitute = Substitutes.Add();
		Substitute.Id = TableRow.Id;
		Substitute.Substitute = FindByDescription(TableRow.Description);
		Substitute.Compatibility = ProductCompatibility.Get(Upper(TableRow.Compatibility));
	EndDo;

	PutToTempStorage(Substitutes, AddressOfMappingTable);

EndProcedure

// End StandardSubsystems.ImportDataFromFile

// StandardSubsystems.BatchEditObjects

// Returns the object attributes that are not recommended to be edited
// using a bulk attribute modification data processor.
//
// Returns:
//  Array - a list of object attribute names.
//
Function AttributesToSkipInBatchProcessing() Export

	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("HiddenAttribute");
	Return NotAttributesToEdit;

EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.ObjectAttributesLock

// Returns:
//   See ObjectAttributesLockOverridable.OnDefineLockedAttributes.LockedAttributes
//
Function GetObjectAttributesToLock() Export

	AttributesToLock = New Array;

	Attribute = ObjectAttributesLock.NewAttributeToLock();
	Attribute.Group = "";
	Attribute.GroupPresentation = NStr("ru = 'Заблокированные реквизиты';
										|en = 'Locked attributes';");
	Attribute.Warning = NStr("ru = 'Не рекомендуется изменять, если номенклатура уже используются';
									|en = 'We do not recommend you to change it if the product is already used';");
	AttributesToLock.Add(Attribute);

	AttributesToLock.Add("Code");
	AttributesToLock.Add("ProductKind");

	Return AttributesToLock;

EndFunction

// End StandardSubsystems.ObjectAttributesLock

// StandardSubsystems.DuplicateObjectsDetection

// Parameters: 
//   ReplacementPairs - See DuplicateObjectsDetectionOverridable.OnDefineItemsReplacementAvailability.ReplacementPairs
//   ReplacementParameters - See DuplicateObjectsDetectionOverridable.OnDefineItemsReplacementAvailability.ReplacementParameters
// 
// Returns:
//   See DuplicateObjectsDetectionOverridable.OnDefineItemsReplacementAvailability.ProhibitedReplacements
//
Function CanReplaceItems(Val ReplacementPairs, Val ReplacementParameters = Undefined) Export

	DeletionMethod = "";
	If ReplacementParameters <> Undefined Then
		ReplacementParameters.Property("DeletionMethod", DeletionMethod);
	EndIf;
	
	// Example: Product with code 000000001 cannot be replaced.
	ForbiddenRef = FindByCode("000000001");

	Result = New Map;
	For Each KeyValue In ReplacementPairs Do
		CurrentRef = KeyValue.Key;
		DestinationRef = KeyValue.Value;

		If CurrentRef = DestinationRef Then
			Continue;

		ElsIf CurrentRef = ForbiddenRef Then
			Error = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Номенклатуру ""%1"" с кодом 000000001 заменять запрещено.';
					|en = 'The ""%1"" product with code 000000001 cannot be replaced.';"), 
				CurrentRef);
			Result.Insert(CurrentRef, Error);
			Continue;
		EndIf;
		
		// Allow to replace a product reference if the products are of the same type or the type is empty. 
		// 
		CurrentKind = CurrentRef.ProductKind;
		TargetKind = DestinationRef.ProductKind;
		ReplacementAllowed = CurrentKind.IsEmpty() Or TargetKind.IsEmpty() Or CurrentKind = TargetKind;

		If ReplacementAllowed Then
			// Check flags, in case the object is important and cannot be deleted.
			If DeletionMethod = "Directly" And CurrentRef = ForbiddenRef Then
				Error = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Номенклатуру ""%1"" с кодом 000000001 запрещено удалять безвозвратно.';
						|en = 'The ""%1"" product with code 000000001 cannot be permanently deleted.';"), 
					CurrentRef);
				Result.Insert(CurrentRef, Error);
			EndIf;
		Else
			Error = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'У элемента ""%1"" вид номенклатуры ""%2"", а у ""%3"" - ""%4""';
					|en = 'Item ""%1"" has product kind ""%2""  and item ""%3"" has product kind ""%4""';"), 
				CurrentRef, CurrentKind, DestinationRef, TargetKind);
			Result.Insert(CurrentRef, Error);
		EndIf;

	EndDo;

	Return Result;
EndFunction

// Parameters: 
//   SearchParameters - See DuplicateObjectsDetectionOverridable.OnDefineDuplicatesSearchParameters.SearchParameters
//   AdditionalParameters - See DuplicateObjectsDetectionOverridable.OnDefineDuplicatesSearchParameters.AdditionalParameters 
//
Procedure DuplicatesSearchParameters(SearchParameters, AdditionalParameters = Undefined) Export

	ComparisonRestrictions = SearchParameters.ComparisonRestrictions;
	SearchRules        = SearchParameters.SearchRules;
	FilterComposer    = SearchParameters.FilterComposer;
	
	// General restrictions in all cases.
	
	// General restrictions.
	Restriction = New Structure;
	Restriction.Insert("Presentation", NStr("ru = 'Вид номенклатуры у сравниваемых элементов одинаков.';
												|en = 'Items being compared have identical product kinds.';"));
	Restriction.Insert("AdditionalFields", "ProductKind");
	ComparisonRestrictions.Add(Restriction);
	
	// Table size to be passed to the handler.
	SearchParameters.ItemsCountToCompare = 100;
	
	// Analysis of runtime mode/call option.
	If AdditionalParameters = Undefined Then
		// External call from the data processor. Nothing else is required. However, you can edit user parameters.
		Return;
	EndIf;
	
	// Call from API.
	FilterItems1 = FilterComposer.Settings.Filter.Items;
	FilterItems1.Clear();
	SearchRules.Clear();

	If AdditionalParameters.Mode = "ControlByDescription" Then
		// Search not deleted items by the same Description and ProductKind.
		
		// Commit filter criteria.
		Filter = FilterItems1.Add(Type("DataCompositionFilterItem"));
		Filter.Use  = True;
		Filter.LeftValue  = New DataCompositionField("DeletionMark");
		Filter.ComparisonType   = DataCompositionComparisonType.Equal;
		Filter.RightValue = False;

		RuleRow = SearchRules.Add();
		RuleRow.Attribute = "Description";
		RuleRow.Rule  = "Equal";

		RuleRow = SearchRules.Add();
		RuleRow.Attribute = "ProductKind";
		RuleRow.Rule  = "Equal";

	ElsIf AdditionalParameters.Mode = "SearchForSimilarItemsByDescription" Then
		// Search for all items with a similar name.

		RuleRow = SearchRules.Add();
		RuleRow.Attribute = "Description";
		RuleRow.Rule  = "Like";
	EndIf;

EndProcedure

// Parameters:
//   ItemsDuplicates - See DuplicateObjectsDetectionOverridable.OnSearchForDuplicates.ItemsDuplicates
//   AdditionalParameters - Structure:
//                              * Mode - String - "ControlByDescription", "SearchForSimilarItemsByDescription"
//                              * Ref - CatalogRef._DemoProducts
//
Procedure OnSearchForDuplicates(ItemsDuplicates, AdditionalParameters = Undefined) Export

	If AdditionalParameters = Undefined Or AdditionalParameters.Mode = "SearchForSimilarItemsByDescription" Then
		
		// General checks.
		For Each Duplicate1 In ItemsDuplicates Do
			If Duplicate1.Fields1.ProductKind = Duplicate1.Fields2.ProductKind Then
				Duplicate1.IsDuplicates = True;
			EndIf;
		EndDo;

	ElsIf AdditionalParameters.Mode = "ControlByDescription" Then
		
		// Exclude the current user.
		For Each Duplicate1 In ItemsDuplicates Do
			If Duplicate1.Ref1 <> AdditionalParameters.Ref Or Duplicate1.Ref2 <> AdditionalParameters.Ref Then
				Duplicate1.IsDuplicates = True;
			EndIf;
		EndDo;

	EndIf;

EndProcedure

// End StandardSubsystems.DuplicateObjectsDetection

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE
	|	TRUE
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	IsFolder
	|	OR ValueAllowed(Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Override object's print settings.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export

EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	
	QueryText = "SELECT TOP 20
	|	Products.Ref AS Ref,
	|	Products.Barcode AS Barcode,
	|	Products.SKU AS SKU,
	|	Products.Description AS Description
	|FROM
	|	Catalog._DemoProducts AS Products
	|WHERE
	|	Products.Description LIKE &SearchString ESCAPE ""~""
	|	OR &FilterConditions
	|	OR Products.Barcode LIKE &SearchStringEndingOnly ESCAPE ""~""
	|	OR Products.SKU LIKE &SearchString ESCAPE ""~""
	|	OR Products.Code LIKE &SearchStringEndingOnly ESCAPE ""~""";
	
	FilterConditions = "TRUE";

	If NationalLanguageSupportServer.IsAdditionalLangUsed("Language1")
	 Or NationalLanguageSupportServer.IsAdditionalLangUsed("Language2") Then
		AttributesNames = NationalLanguageSupportServer.AttributesNamesConsideringLangCode("Description");
		ReplacementTemplate = StrReplace("Products.%1 AS Description", "%1", AttributesNames["Description"]);
		QueryText = StrReplace(QueryText, "Products.Description AS Description",
			ReplacementTemplate);
		FilterConditions = StringFunctionsClientServer.SubstituteParametersToString("Products.%1 LIKE &SearchString ESCAPE ""~""",
			AttributesNames["Description"]);
	EndIf;
	
	QueryText = StrReplace(QueryText, "&FilterConditions", FilterConditions);
	
	Query = New Query(QueryText);
	Query.SetParameter("SearchString", "%" +Common.GenerateSearchQueryString(Parameters.SearchString) + "%");
	Query.SetParameter("SearchStringEndingOnly", Common.GenerateSearchQueryString(Parameters.SearchString) + "%");
	QueryResult = Query.Execute().Select();

	ChoiceData = New ValueList;
	While QueryResult.Next() Do
		
		Presentation = QueryResult.Description;
		If StrFind(QueryResult.Barcode, Parameters.SearchString) > 0 Then
			Presentation = Presentation + " (" + QueryResult.Barcode +")";
		ElsIf StrFind(Upper(QueryResult.SKU), Upper(Parameters.SearchString)) > 0 Then
			Presentation = Presentation + " (" + QueryResult.SKU +")";
		EndIf;
		
		HighlightedPresentation = StrFindAndHighlightByAppearance(Presentation, Parameters.SearchString);
		If HighlightedPresentation <> Undefined Then
			Presentation = HighlightedPresentation;
		EndIf;
		
		ChoiceData.Add(QueryResult.Ref, Presentation);
	EndDo;
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)

	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);

EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)

	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);

EndProcedure

#EndRegion

#EndIf