///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// For calling from the OnInitialItemsFilling handler.
// Fills in columns called AttributeName_<LanguageCode> with text values for the specified language codes.
//
// Parameters:
//  Item        - ValueTableRow - A row that takes the value.
//  AttributeName   - String - an attribute name. For example, Description.
//  InitialString - String - a string in the NStr format. For example, "ru" = 'Russian message'; en = 'English message'".
//  LanguagesCodes     - Array - codes of languages ​​in which you need to fill in the rows.
// 
// Example:
//
//  NationalLanguageSupportServer.FillMultilingualAttribute(Item, "Description", "ru = 'Russian message'; en =
//  'English message'", LanguageCodes);
//
Procedure FillMultilanguageAttribute(Item, AttributeName, InitialString, LanguagesCodes = Undefined) Export
	
	For Each LanguageCode In LanguagesCodes Do
		
		TheValueOfTheLanguageCode = NStr(InitialString, LanguageCode);
		ValueToFillIn = ?(ValueIsFilled(TheValueOfTheLanguageCode), TheValueOfTheLanguageCode, NStr(InitialString, Common.DefaultLanguageCode()));
		Item[NameOfAttributeToLocalize(AttributeName, LanguageCode)] = ValueToFillIn;
		If StrCompare(LanguageCode, Common.DefaultLanguageCode()) = 0 Then
			Item[AttributeName] = ValueToFillIn;
		EndIf;
	EndDo;
	
EndProcedure

// Called from the OnCreateAtServer handler of the object form. Adds the open button to the fields for entering
// multilanguage attributes on this form. Clicking the button opens a window for entering the attribute value in all
// configuration languages.
//
// Parameters:
//   Form  - ClientApplicationForm - object form.
//   Object - FormDataStructure:
//     * Ref - AnyRef
//  ObjectName - String - for list forms, the dynamic list name on the form. The default value is "List".
//                        For other forms, the main attribute name on the form. Use it
//                        if the name differs from the default ones: "Object", "Record", or "List".
//
Procedure OnCreateAtServer(Form, Object = Undefined, ObjectName = Undefined) Export
	
	If Object = Undefined Then
		FormType = NationalLanguageSupportCached.DefineFormType(Form.FormName);
		If FormType = "DefaultListForm" Or FormType = "MainChoiceForm" Then
			If TypeOf(ObjectName) <> Type("String") Then
				ObjectName = "List";
			EndIf;
			
			ChangeListQueryTextForCurrentLanguage(Form, ObjectName);
		EndIf;
		Return;
	EndIf;
	
	AddtlLanguagesAreUsed = False;
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
		PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
		AddtlLanguagesAreUsed = PrintManagementModuleNationalLanguageSupport.AdditionalLanguagesOfPrintedFormsAreUsed();
	EndIf;
	
	If Object <> Undefined
		And NationalLanguageSupportCached.ConfigurationUsesOnlyOneLanguage(Object.Property("Presentations"))
		And Not AddtlLanguagesAreUsed Then
		Return;
	EndIf;
	
	FormAttributeList = Form.GetAttributes();
	CreateMultilanguageAttributesParameters = True;
	For Each Attribute In FormAttributeList Do
		If Attribute.Name = "MultilanguageAttributesParameters" Then
			CreateMultilanguageAttributesParameters = False;
		EndIf;
	EndDo;
	
	If CreateMultilanguageAttributesParameters Then
		AttributesToBeAdded = New Array;
		AttributesToBeAdded.Add(New FormAttribute("MultilanguageAttributesParameters", New TypeDescription(),,, True));
		Form.ChangeAttributes(AttributesToBeAdded);
	EndIf;
	
	Form.MultilanguageAttributesParameters = New Structure;
	
	ObjectMetadata1 = MetadataObject(Object);

	If TypeOf(ObjectName) <> Type("String") Then
		ObjectName = ?(Common.IsRegister(ObjectMetadata1), "Record", "Object");
	EndIf;
	
	AttributesDescriptions = DescriptionsOfObjectAttributesToLocalize(ObjectMetadata1, ObjectName + ".");
	
	For Each Item In Form.Items Do
		
		If TypeOf(Item) = Type("FormField") And AttributesDescriptions[Item.DataPath] <> Undefined Then
			Item.OpenButton = True;
			Item.SetAction("Opening", "Attachable_Opening");
			Form.MultilanguageAttributesParameters.Insert(Item.Name, Item.DataPath);
		EndIf;
		
	EndDo;
	
	If Form.Parameters.Property("CopyingValue")
		 And ValueIsFilled(Form.Parameters.CopyingValue) Then
			
			ClearMultilingualBankingDetails(Object, ObjectMetadata1);
			OnReadPresentationsAtServer(Object);
			
	EndIf;
	
EndProcedure

// It is called from the OnReadAtServer handler of the object form to fill in values of the multilanguage
// form attributes in the current user language.
//
// Parameters:
//  Form         - ClientApplicationForm - object form.
//  CurrentObject - Arbitrary - an object received in the OnReadAtServer form handler.
//  ObjectName - String - the main attribute name on the form. It is used
//                        if the name differs from the default: "Object", "Record", "List".
//
Procedure OnReadAtServer(Form, CurrentObject, ObjectName = Undefined) Export
	
	MetadataObject = MetadataObject(CurrentObject);
	If IsMainLanguage() And MultilanguageStringsInAttributes(MetadataObject) Then
		Return;
	EndIf;
	
		If TypeOf(ObjectName) <> Type("String") Then
		ObjectName = ?(Common.IsRegister(MetadataObject), "Record", "Object");
		EndIf;

	PropertyCheck = New Structure(ObjectName, Undefined);
	FillPropertyValues(PropertyCheck, Form, ObjectName);
	If PropertyCheck[ObjectName] <> Undefined Then
		OnReadPresentationsAtServer(Form[ObjectName]);
	EndIf;
	
EndProcedure

// It is called from the BeforeWriteAtServer handler of the object form or when programmatically recording an object
// to record multilingual attribute values in accordance with the current user language.
//
// Parameters:
//  CurrentObject - BusinessProcessObject
//                - DocumentObject
//                - TaskObject
//                - ChartOfCalculationTypesObject
//                - ChartOfCharacteristicTypesObject
//                - ExchangePlanObject
//                - ChartOfAccountsObject
//                - CatalogObject - Object being written.
//
Procedure BeforeWriteAtServer(CurrentObject) Export
	
	MetadataObject = MetadataObject(CurrentObject);
	CurrentLanguageSuffix = CurrentLanguageSuffix();
	
	NamesOfMultilingualAttributes       = DescriptionsOfObjectAttributesToLocalize(MetadataObject);
	NamesOfMultiLangAttributesInHeader = TheNamesOfTheLocalizedDetailsOfTheObjectInTheHeader(MetadataObject);

	If MultilanguageStringsInAttributes(MetadataObject) Then
		
		If Not Common.IsRegister(MetadataObject) And CurrentObject.IsNew()  Then
			
			For Each Attribute In NamesOfMultiLangAttributesInHeader Do
				
				AttributeValue = CurrentObject[Attribute.Key];
				If IsBlankString(AttributeValue) Then
					Continue;
				EndIf;
				
				If IsBlankString(CurrentObject[Attribute.Key + "Language1"]) Then
					CurrentObject[Attribute.Key + "Language1"] = AttributeValue;
				EndIf;
				
				If IsBlankString(CurrentObject[Attribute.Key + "Language2"]) Then
					CurrentObject[Attribute.Key + "Language2"] = AttributeValue;
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If CurrentLanguage().LanguageCode <> Common.DefaultLanguageCode() Then
			
			For Each Attribute In NamesOfMultiLangAttributesInHeader Do
				
				Value = CurrentObject[Attribute.Key];
				CurrentObject[Attribute.Key] = CurrentObject[Attribute.Key + CurrentLanguageSuffix];
				CurrentObject[Attribute.Key + CurrentLanguageSuffix] = Value;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	FullName = MetadataObject.FullName();
	
	If Not ObjectContainsPMRepresentations(FullName) Then
		Return;
	EndIf;
	
	Attributes = NationalLanguageSupportCached.TabularSectionMultilingualAttributes(FullName);
	
	Presentations = CurrentObject.Presentations; // TabularSection
	Filter = New Structure();
	If CurrentLanguage().LanguageCode <> Common.DefaultLanguageCode() Then
		Filter.Insert("LanguageCode", CurrentLanguage().LanguageCode);
		FoundRows = Presentations.FindRows(Filter);
		
		If FoundRows.Count() > 0 Then
			Presentation = FoundRows[0];
		Else
			Presentation = Presentations.Add();
			Presentation.LanguageCode = CurrentLanguage().LanguageCode;
		EndIf;
		
		For Each AttributeName In Attributes Do
			
			If NamesOfMultiLangAttributesInHeader[AttributeName] <> Undefined Then
				
				ValueInCurrentLanguage = CurrentObject[AttributeName + CurrentLanguageSuffix];
				If IsBlankString(ValueInCurrentLanguage) Then
					Presentation[AttributeName] = CurrentObject[AttributeName];
				Else
					Presentation[AttributeName] = ValueInCurrentLanguage;
				EndIf;
				
			Else
				
				Presentation[AttributeName] = CurrentObject[AttributeName];
				
			EndIf;
			
		EndDo;
	EndIf;
	
	PopulateMultilingualAttributesOfPresentationsTabularSection(CurrentObject, Attributes, NamesOfMultiLangAttributesInHeader);
	
	Filter.Insert("LanguageCode", Common.DefaultLanguageCode());
	FoundRows = Presentations.FindRows(Filter);
	If FoundRows.Count() > 0 Then
		For Each AttributeName In Attributes Do  
			If NamesOfMultiLangAttributesInHeader[AttributeName] = Undefined
			   Or (CurrentLanguage().LanguageCode <> Common.DefaultLanguageCode()
			   And IsBlankString(CurrentLanguageSuffix)) 
			   And CurrentObject[AttributeName] <> Null Then
					CurrentObject[AttributeName] = FoundRows[0][AttributeName];
			EndIf;
		EndDo;
		Presentations.Delete(FoundRows[0]);
	EndIf;
	
	Presentations.GroupBy("LanguageCode", StrConcat(Attributes, ","));
	
EndProcedure

// It is called from the object module to fill in the multilingual
// attribute values of the object in the current user language.
//
// Parameters:
//  Object - BusinessProcessObject
//         - DocumentObject
//         - TaskObject
//         - ChartOfCalculationTypesObject
//         - ChartOfCharacteristicTypesObject
//         - ExchangePlanObject
//         - ChartOfAccountsObject
//         - CatalogObject - a data object.
//
Procedure OnReadPresentationsAtServer(Object) Export
	
	MetadataObject = MetadataObject(Object);
	
	If IsMainLanguage() Then
		Return;
	EndIf;
	
	CurrentLanguageSuffix = CurrentLanguageSuffix();

	NamesOfAttributesToLocalize = TheNamesOfTheLocalizedDetailsOfTheObjectInTheHeader(MetadataObject);
	
	If MultilanguageStringsInAttributes(MetadataObject) And ValueIsFilled(CurrentLanguageSuffix) Then
		
		For Each Attribute In NamesOfAttributesToLocalize Do
			
			Value = Object[Attribute.Key];
			Object[Attribute.Key] = Object[Attribute.Key + CurrentLanguageSuffix];
			Object[Attribute.Key + CurrentLanguageSuffix] = Value;
			
			If IsBlankString(Object[Attribute.Key]) Then
				Object[Attribute.Key] = Value;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	FullName = MetadataObject.FullName();
	
	If Not ObjectContainsPMRepresentations(FullName) Then
		Return;
	EndIf;
	
	Attributes = NationalLanguageSupportCached.TabularSectionMultilingualAttributes(FullName);
	
	For Each AttributeName In Attributes Do
		
		Filter = New Structure();
		Filter.Insert("LanguageCode", Common.DefaultLanguageCode());
		FoundRows = Object.Presentations.FindRows(Filter);
	
		If FoundRows.Count() > 0 Then
			
			Presentation = FoundRows[0];
			
		Else
			
			If IsBlankString(Object[AttributeName]) Then
				Continue;
			EndIf;
			
			Presentation = Object.Presentations.Add();
			Presentation.LanguageCode = Common.DefaultLanguageCode();
			
		EndIf;
		Presentation[AttributeName] = Object[AttributeName];
		
		Filter = New Structure();
		Filter.Insert("LanguageCode", CurrentLanguage().LanguageCode);
		FoundRows = Object.Presentations.FindRows(Filter);
		
		If FoundRows.Count() > 0 And ValueIsFilled(FoundRows[0][AttributeName]) Then
			Object[AttributeName] = FoundRows[0][AttributeName];
		EndIf;
		
	EndDo;
	
EndProcedure

// It is called from the ProcessGettingChoiceData handler to form a list during line input,
// automatic text selection and quick selection, as well as when the GetChoiceData method is executed.
// The list contains options in all languages, considering the attributes specified in the LineInput property.
//
// Parameters:
//  ChoiceData         - ValueList - data for the choice.
//  Parameters            - Structure - contains choice parameters.
//  StandardProcessing - Boolean  - this parameter stores the flag of whether the standard (system) event processing is executed.
//  MetadataObject     - MetadataObjectBusinessProcess
//                       - MetadataObjectDocument
//                       - MetadataObjectTask
//                       - MetadataObjectChartOfCalculationTypes
//                       - MetadataObjectChartOfCharacteristicTypes
//                       - MetadataObjectExchangePlan
//                       - MetadataObjectChartOfAccounts
//                       - MetadataObjectCatalog
//                       - MetadataObjectTable - a metadata object, for which the choice list is generated.
//
Procedure ChoiceDataGetProcessing(ChoiceData, Val Parameters, StandardProcessing, MetadataObject) Export
	
	If NationalLanguageSupportCached.ConfigurationUsesOnlyOneLanguage(MetadataObject.TabularSections.Find("Presentations") = Undefined) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	InputByStringFields = MetadataObject.InputByString;
	Fields              = New Array;
	
	DescriptionsOfAttributesToLocalize = DescriptionsOfObjectAttributesToLocalize(MetadataObject);
	For Each Field In InputByStringFields Do
		If DescriptionsOfAttributesToLocalize.Get(Field.Name) <> Undefined Then
			
			Fields.Add("Table." + Field.Name + " LIKE &SearchString ESCAPE ""~""");
			
			If FirstAdditionalLanguageUsed() Then
				Fields.Add("Table." + Field.Name + "Language1 LIKE &SearchString ESCAPE ""~""");
			EndIf;
			
			If SecondAdditionalLanguageUsed() Then
				Fields.Add("Table." + Field.Name + "Language2 LIKE &SearchString ESCAPE ""~""");
			EndIf;

		Else
			Fields.Add("Table." + Field.Name + " LIKE &SearchString ESCAPE ""~""");
		EndIf;
	EndDo;
	
	QueryTemplate = "SELECT ALLOWED TOP 20
	|	Table.Ref AS Ref
	|FROM
	|	&ObjectName AS Table
	|WHERE
	|	&FilterConditions";
	
	QueryText = StrReplace(QueryTemplate, "&ObjectName", MetadataObject.FullName());
	QueryText = StrReplace(QueryText, "&FilterConditions", StrConcat(Fields, " OR "));
	
	Query = New Query(QueryText);	
	Query.SetParameter("SearchString", "%" + Common.GenerateSearchQueryString(Parameters.SearchString) +"%");
	QueryResult = Query.Execute().Select();
	
	ChoiceData = New ValueList;
	While QueryResult.Next() Do
		ChoiceData.Add(QueryResult.Ref, QueryResult.Ref);
	EndDo;
	
EndProcedure

// Adds the current language code to a field in the query text.
// Field conversion examples:
//   - If FieldName value is "Properties.Title", the field is converted into "Properties.TitleLanguage1".
//   - If FieldName value is "Properties.Title AS Title", the field is converted into "Properties.TitleLanguage1 AS Title". 
//   
// 
// Parameters:
//  QueryText - String - Text of the query whose field is renamed.
//  FieldName - String - Name of the field to replace.
//
Procedure ChangeRequestFieldUnderCurrentLanguage(QueryText, FieldName) Export
	
	LanguageSuffix = CurrentLanguageSuffix();
	If IsBlankString(LanguageSuffix) Then
		Return;
	EndIf;
	
	SpacePosition = StrFind(FieldName, " ");
	NewFieldName =? (SpacePosition > 1,
		Left(FieldName, SpacePosition - 1) + LanguageSuffix + Mid(FieldName, SpacePosition), FieldName + LanguageSuffix);
	
	QueryText = StrReplace(QueryText, FieldName, NewFieldName);
	
EndProcedure

// Returns the additional language postfix for the current UI language.
// 
// Returns:
//  String - Postfix added to the name of the attribute that stores the attribute value in the given language.
//           For example, "Lang1" for the attribute "DescriptionLang2".
//
Function CurrentLanguageSuffix() Export

	Return LanguageSuffix(CurrentLanguage().LanguageCode);

EndFunction


// Returns the additional language postfix by the passed language code.
// 
// Parameters:
//  LanguageCode - String - Short language presentation. For example, "en" for English.
// 
// Returns:
//  String - Postfix added to the name of the attribute that stores the attribute value in the given language.
//           For example, "Lang1" for the attribute "DescriptionLang2".
//
Function LanguageSuffix(LanguageCode) Export
	
	If IsBlankString(LanguageCode) Then
		Return CurrentLanguageSuffix();
	EndIf;
	
	Return NationalLanguageSupportCached.LanguageSuffix(LanguageCode);

EndFunction

// Determines whether the passed language is used in the app.
// 
// Parameters:
//  LanguageSuffix - String - Additional language postfix. For example, "Lang1".
// 
// Returns:
//  Boolean - If "True", the additional language is used in the app. 
//
Function IsAdditionalLangUsed(LanguageSuffix) Export

	Return NationalLanguageSupportCached.IsAdditionalLangUsed(LanguageSuffix);

EndFunction

// Returns attribute names considering the passed language code.
// 
// Parameters:
//  AttributesNames - String - A comma-delimited list of attributes. For example, "Description,Comment".
//  LanguageCode - String - Language code. If unspecified, the current app language is passed.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String - An attribute name. For example, "Description". 
//   * Value - String - Attribute name followed by the language code. For example, "DescriptionsLang2"
//
Function AttributesNamesConsideringLangCode(AttributesNames, LanguageCode = "") Export
	
	Result    = New Map;
	Attributes    = StrSplit(AttributesNames, ",", False);
	LanguageSuffix = LanguageSuffix(LanguageCode);
	
	For Each Attribute In Attributes Do
		Result.Insert(TrimL(Attribute), TrimAll(Attribute) + LanguageSuffix);
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Internal

Function RegionalInfobaseSettingsRequired() Export
	
	If (Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable())
		Or Common.IsStandaloneWorkplace()  Then
		Return False;
	EndIf;
	
	SetPrivilegedMode(True);
	
	MultilingualAttributesChangeData = DataToChangeMultilanguageAttributes();
	If MultilingualAttributesChangeData <> Undefined Then
		If MultilingualAttributesChangeData.MainLanguageChanged 
		 Or Users.IsFullUser(,, False) Then
			Return True;
		EndIf;
		
		If (MultilingualAttributesChangeData.FirstAdditionalLanguageChanged
		   And CurrentLanguage().LanguageCode = FirstAdditionalInfobaseLanguageCode())
		 Or (MultilingualAttributesChangeData.SecondAdditionalLanguageChanged
		   And CurrentLanguage().LanguageCode = SecondAdditionalInfobaseLanguageCode()) Then
				Return True;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(Constants.DefaultLanguage.Get()) Then
		Return False;
	EndIf;
	
	If InfobaseUpdateInternal.DataUpdateMode() = "InitialFilling" 
		And Metadata.Languages.Count() > 1 Then
		Return True;
	EndIf;
	
	Constants.DefaultLanguage.Set(Common.DefaultLanguageCode());
	
	Return False;
	
EndFunction

Function DefaultLanguageCode() Export
	
	SetPrivilegedMode(True);
	Return SessionParameters.DefaultLanguage;
	
EndFunction

Function LanguagePresentation(LanguageCode) Export
	
	If GetAvailableLocaleCodes().Find(LanguageCode) = Undefined Then
		For Each Language In Metadata.Languages Do
			If Language.LanguageCode = LanguageCode Then
				Return Language.Presentation();
			EndIf;
		EndDo;
		Return LanguageCode;
	EndIf;
	
	Presentation = LocaleCodePresentation(LanguageCode);
	StringParts1 = StrSplit(Presentation, " ", True);
	StringParts1[0] = Title(StringParts1[0]);
	Presentation = StrConcat(StringParts1, " ");
	
	Return Presentation;
	
EndFunction

Function LanguagesInformationRecords() Export
	Return NationalLanguageSupportCached.LanguagesInformationRecords();
EndFunction

Function ObjectContainsPMRepresentations(ReferenceOrFullMetadataName, AttributeName = "") Export
	Return NationalLanguageSupportCached.ObjectContainsPMRepresentations(ReferenceOrFullMetadataName, AttributeName);
EndFunction

Function AttributeNameWithoutSuffixLanguage(Val AttributeName) Export
	
	If IsAttributeToLocalize(AttributeName) Then
		Return Left(AttributeName, StrLen(AttributeName) - LanguageSuffixLength());
	EndIf;
	
	Return AttributeName;
	
EndFunction

Function AttributeToLocalizeFlag() Export
	Return "ToLocalize";
EndFunction

Function MultilanguageStringsInAttributes(MetadataObject) Export
	
	Return NationalLanguageSupportCached.ThereareMultilingualDetailsintheHeaderoftheObject(MetadataObject.FullName());
	
EndFunction

Function MultilingualObjectAttributes(ObjectOrRef) Export
	
	ObjectType = TypeOf(ObjectOrRef);
	
	If ObjectType = Type("String") Or Common.IsReference(ObjectType) Then
		Object = ObjectOrRef;
	Else
		Object = ObjectOrRef.FullName();
	EndIf;
	
	Return NationalLanguageSupportCached.MultilingualObjectAttributes(Object);
	
EndFunction

Function UpdateMultilanguageStringsOfPredefinedItems(ObjectsRefs, MetadataObject) Export
	
	Result = New Structure();
	Result.Insert("ObjectsWithIssuesCount", 0);
	Result.Insert("ObjectsProcessed", 0);
	
	UpdateSettings = SettingsPredefinedDataUpdate(MetadataObject);
	
	While ObjectsRefs.Next() Do
		
		Try
			
			UpdateMultilanguageStringsOfPredefinedItem(ObjectsRefs.Ref, UpdateSettings);
			Result.ObjectsProcessed = Result.ObjectsProcessed + 1;
			
		Except
			// If an item cannot be processed, try again.
			Result.ObjectsWithIssuesCount = Result.ObjectsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать элемент %1 по причине: 
					|%2';
					|en = 'Couldn''t process item: %1. Reason:
					|%2';"),
				ObjectsRefs.Ref, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
			MetadataObject, ObjectsRefs.Ref, MessageText);
			
		EndTry;
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure DetermineModifiedMultilingualItems(NewValue, TableRow, NameOfAttributeToLocalize, EditedAttributes, DatasetToFill) Export

	ObjectAttributesToLocalize = DatasetToFill.ObjectAttributesToLocalize;

	If ObjectAttributesToLocalize.Count() = 0 Then
		Return;
	EndIf;

	Languages                  = StandardSubsystemsServer.ConfigurationLanguages();
	LanguagesInformationRecords       = LanguagesInformationRecords();
	HierarchySupported = DatasetToFill.HierarchySupported;

	If DatasetToFill.MultilanguageStringsInAttributes Then
		
		For LanguageNumber = 0 To LanguagesInformationRecords.AdditionalLanguagesCount Do

			LanguageCode = LanguagesInformationRecords["Language" + String(LanguageNumber)];

			LocalizableAttributeNameInHeader = ?(LanguageNumber = 0, NameOfAttributeToLocalize, NameOfAttributeToLocalize
				+ "Language" + String(LanguageNumber));
			If ValueIsFilled(LanguageCode) Then
				If NewValue[LocalizableAttributeNameInHeader] <> TableRow[NameOfAttributeToLocalize + "_"
					+ LanguageCode] Then
					EditedAttributes.Add(LocalizableAttributeNameInHeader);
				EndIf;
			EndIf;
		EndDo;
	ElsIf Not (HierarchySupported And NewValue.IsFolder) Then
		
		For Each LanguageCode In Languages Do
			ViewTable = NewValue.Presentations; // ValueTable
			NewPresentation = ViewTable.Add();
			NewPresentation.LanguageCode = LanguageCode;
			For Each NameOfAttributeToLocalize In ObjectAttributesToLocalize Do
				Value = TableRow[NameOfAttributeToLocalize.Key + "_" + LanguageCode];
				NewPresentation[NameOfAttributeToLocalize.Key] = ?(ValueIsFilled(Value), Value,
					TableRow[NameOfAttributeToLocalize.Key]);
			EndDo;
		EndDo;

	EndIf;

EndProcedure

Procedure DeleteMultilingualAttributes(EditedAttributes) Export
	
	LanguagesInformationRecords = LanguagesInformationRecords();
	
	Position = EditedAttributes.Count() - 1;
	
	While Position >= 0 Do
	
		For LanguageNumber = 1 To LanguagesInformationRecords.AdditionalLanguagesCount Do
			If StrEndsWith(EditedAttributes[Position], "Language" + LanguageNumber) Then
				EditedAttributes.Delete(Position);
				Break;
			EndIf;
		EndDo;
		
		Position = Position - 1;
	
	EndDo;
	
EndProcedure

Procedure ChangeListQueryTextForCurrentLanguage(Form, ListName = "List") Export
	
	LanguageSuffix = CurrentLanguageSuffix();
	
	If IsBlankString(LanguageSuffix) Then
		Return;
	EndIf;
	
	List = Form[ListName];
	If IsBlankString(List.QueryText) Then
		Return;
	EndIf;
	
	MetadataObject = Undefined;
	If ValueIsFilled(List.MainTable) Then
		MetadataObject = Common.MetadataObjectByFullName(List.MainTable);
	EndIf;
	
	If MetadataObject = Undefined Then
		MetadataObjectPathPartsSet = StrSplit(Form.FormName, ".");
		MetadataObjectName = MetadataObjectPathPartsSet[0] + "." + MetadataObjectPathPartsSet[1];
		MetadataObject = Common.MetadataObjectByFullName(MetadataObjectName);
	EndIf;
	
	If MetadataObject = Undefined Then
		Return;
	EndIf;
	
	AttributesToLocalize = ObjectAttributesToLocalizeForCurrentLanguage(MetadataObject);
	
	QueryModel = New QuerySchema;
	QueryModel.SetQueryText(List.QueryText);
	
	For Each QueryPackage In QueryModel.QueryBatch Do
		For Each QueryOperator In QueryPackage.Operators Do
			For Each QuerySource In QueryOperator.Sources Do
				If TypeOf(QuerySource.Source) <> Type("QuerySchemaNestedQuery")
					 And StrStartsWith(MetadataObject.FullName(), QuerySource.Source.TableName) Then
					
					For Each AttributeDetails In AttributesToLocalize Do
						
						MainAttributeName = Left(AttributeDetails.Key, StrLen(AttributeDetails.Key) - LanguageSuffixLength());
						FullName = QuerySource.Source.Alias + "."+ MainAttributeName;
						
						For IndexOf = 0 To QueryOperator.SelectedFields.Count() - 1 Do
							
							SelectTheQueryField = QueryOperator.SelectedFields.Get(IndexOf);
							If TypeOf(SelectTheQueryField) <> Type("QuerySchemaExpression") Then
								Continue;
							EndIf;
							
							FieldToSelect = String(SelectTheQueryField);
							Position = StrFind(FieldToSelect, FullName);
							
							If Position = 0 Then
								Continue;
							EndIf;
							
							FieldChoiceText = QuerySource.Source.Alias + "." + AttributeDetails.Key;
							
							If StrCompare(FieldToSelect, FullName) = 0 Then
								
								FieldToSelect = StrReplace(FieldToSelect, FullName, FieldChoiceText);
								
							Else
								
								FieldToSelect = StrReplace(FieldToSelect, FullName + Chars.LF,
									FieldChoiceText + Chars.LF);
								FieldToSelect = StrReplace(FieldToSelect, FullName + " ",
									FieldChoiceText + " " );
								FieldToSelect = StrReplace(FieldToSelect, FullName + ")",
									FieldChoiceText + ")" );
								
							EndIf;
							
							QueryOperator.SelectedFields.Set(IndexOf, New QuerySchemaExpression(FieldToSelect));
							
							If QueryPackage.Columns.Find(MainAttributeName) = Undefined Then
								QueryPackage.Columns.Get(IndexOf).Alias = MainAttributeName;
							EndIf;
							
						EndDo;
						
					EndDo;
					
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	List.QueryText = QueryModel.GetQueryText();
	
EndProcedure

Function FirstAdditionalLanguageUsed() Export
	
	Return IsAdditionalLangUsed("Language1");
	
EndFunction

Function SecondAdditionalLanguageUsed() Export
	
	Return IsAdditionalLangUsed("Language2");
	
EndFunction

// Update data.

Procedure ProcessGeneralDataToUpgradeToNewVersion() Export
	
	If Metadata.Languages.Count() = 1 Then
		Return;
	EndIf;
	
	ObjectsToBeProcessed = ListOfObjectsToBeProcessedToUpgradeToNewVersion("Overall");
	
	If ObjectsToBeProcessed.Count() = 0 Then
		Return;
	EndIf;
	
	ObjectsProcessed = 0; 
	ObjectsWithIssuesCount = 0;
	
	MetadataObject    = Undefined;
	FillParameters = Undefined;
	For Each ObjectToProcess1 In ObjectsToBeProcessed Do
		
		If MetadataObject = Undefined Or TypeOf(MetadataObject) <> TypeOf(ObjectToProcess1) Then
			MetadataObject = Metadata.FindByType(TypeOf(ObjectToProcess1));
			FillParameters = InfobaseUpdateInternal.ParameterSetForFillingObject(MetadataObject);
		EndIf;
		
		If FillParameters <> Undefined Then
			FillAndMoveLinesFromPchViewToRequisites(ObjectToProcess1, FillParameters, ObjectsProcessed, ObjectsWithIssuesCount);
		EndIf;
		
	EndDo;
	
	If ObjectsWithIssuesCount > 0 Then
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Error,,,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Процедуре %1 не удалось обновить некоторые объекты (пропущены): %2 из %3';
						|en = 'Procedure %1 couldn''t update (skipped) some objects: %2 of %3.';"),
					"NationalLanguageSupportServer.ProcessGeneralDataToUpgradeToNewVersion",
					ObjectsWithIssuesCount, ObjectsProcessed));
	EndIf;	
	
EndProcedure

// Registers objects to process in the update handler
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	If Metadata.Languages.Count() = 1 Then
		Return;
	EndIf;
	
	ObjectsToBeProcessed = ListOfObjectsToBeProcessedToUpgradeToNewVersion(VariantOfDataForProcessingTakingIntoAccountSeparation());

	If ObjectsToBeProcessed.Count() > 0 Then
		InfobaseUpdate.MarkForProcessing(Parameters, ObjectsToBeProcessed);
	EndIf;
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	TotalProcessed    = 0;
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	Batch             = 10000;
	
	ObjectsToProcess = ObjectsSCHRepresentations(VariantOfDataForProcessingTakingIntoAccountSeparation());
	For Each NameObjectSTCHView In ObjectsToProcess Do
		
		Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, NameObjectSTCHView);
		
		FillParameters = Undefined;
		If Selection.Count() > 0 Then
			FillParameters = InfobaseUpdateInternal.ParameterSetForFillingObject(
				Common.MetadataObjectByFullName(NameObjectSTCHView));
		EndIf;
		
		While Selection.Next() Do
			FillAndMoveLinesFromPchViewToRequisites(Selection.Ref, FillParameters, ObjectsProcessed, ObjectsWithIssuesCount);
		EndDo;
		
		TotalProcessed = TotalProcessed + ObjectsProcessed;
		 
		If TotalProcessed >= Batch Then
			Break;
		EndIf;
	
	EndDo;
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедуре %1 не удалось обработать некоторые объекты (пропущены): %2';
				|en = 'Procedure %1 couldn''t process (skipped) some objects: %2';"), 
			"NationalLanguageSupportServer.ProcessDataForMigrationToNewVersion",
			ObjectsWithIssuesCount);
		Raise MessageText;
	ElsIf ObjectsProcessed > 0 Then
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Процедура %1 обработала очередную порцию объектов: %2';
					|en = 'Procedure %1 processed yet another batch of objects: %2.';"),
				"NationalLanguageSupportServer.ProcessDataForMigrationToNewVersion",
				ObjectsProcessed));
	EndIf;
	
	
	ObjectsWithPredefinedItems = InfobaseUpdateInternal.ObjectsWithInitialFilling();
	For Each ObjectWithPredefinedElements In ObjectsWithPredefinedItems Do

		If ObjectsToProcess.Find(ObjectWithPredefinedElements.Value) = Undefined Then
			ObjectsToProcess.Add(ObjectWithPredefinedElements.Value);
		EndIf;
		
	EndDo;
	
	For Each ObjectWithPredefinedElements In ObjectsWithPredefinedItems Do
		
		If TotalProcessed >= Batch Then
			Break;
		EndIf;
		
		Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue,
			ObjectWithPredefinedElements.Value);
		If Selection.Count() > 0 Then
		
			// @skip-check query-in-loop - Batch-wise data processing in an update handler
			FillInEmptyMultilingualDetailsWithTheValueOfTheMainLanguage(Selection, ObjectWithPredefinedElements.Key,
				TotalProcessed);
			
		EndIf;
	EndDo;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, ObjectsToProcess);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Initial data population.

// Parameters:
//  ObjectReference - CatalogRef
//                 - ChartOfCharacteristicTypesRef
//  SettingsOfUpdate - Structure:
//   * PredefinedData - ValueTable
//   * DefaultLanguage - String
//   * LanguageCode2 - String
//   * LanguageCode1 - String
//   * ObjectAttributesToLocalize - See SettingsPredefinedDataUpdate
// 
Procedure UpdateMultilanguageStringsOfPredefinedItem(ObjectReference, SettingsOfUpdate) Export
	
	PredefinedDataName = Common.ObjectAttributeValue(ObjectReference, "PredefinedDataName");
	If Not ValueIsFilled(PredefinedDataName) Then
		InfobaseUpdate.MarkProcessingCompletion(ObjectReference);
		Return;
	EndIf;
	
	Item = SettingsOfUpdate.PredefinedData.Find(PredefinedDataName, "PredefinedDataName");
	
	If Item = Undefined Then
		InfobaseUpdate.MarkProcessingCompletion(ObjectReference);
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add(SettingsOfUpdate.NameMetadataObject);
		LockItem.SetValue("Ref", ObjectReference);
		Block.Lock();
		
		Object = ObjectReference.GetObject();
		If Object = Undefined Then // the object may have been deleted in other sessions
			RollbackTransaction();
			Return;
		EndIf;
		LockDataForEdit(ObjectReference);
		
		For Each ObjectAttributeToLocalize In SettingsOfUpdate.ObjectAttributesToLocalize Do
			Name = ObjectAttributeToLocalize.Key;
			Object[Name] = Item[NameOfAttributeToLocalize(Name, SettingsOfUpdate.DefaultLanguage)];
			
			If FirstAdditionalLanguageUsed() And ValueIsFilled(SettingsOfUpdate.LanguageCode1) Then
				Object[Name + "Language1"] = Item[NameOfAttributeToLocalize(Name, SettingsOfUpdate.LanguageCode1)];
			EndIf;
			If SecondAdditionalLanguageUsed()  And ValueIsFilled(SettingsOfUpdate.LanguageCode2) Then
				Object[Name + "Language2"] = Item[NameOfAttributeToLocalize(Name, SettingsOfUpdate.LanguageCode2)];
			EndIf;
			
		EndDo;
		InfobaseUpdate.WriteObject(Object);
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
		
	
EndProcedure

// Parameters:
//  MetadataObject - MetadataObject
// 
// Returns:
//  Structure:
//   * ObjectAttributesToLocalize - Map of KeyAndValue:
//   ** Key - String
//   ** Value - Boolean 
//   * LanguageCode1 - String
//   * LanguageCode2 - String
//   * DefaultLanguage - String
//   * NameMetadataObject - String
//   * PredefinedData - ValueTable
//
Function SettingsPredefinedDataUpdate(MetadataObject) Export
	
	Result = New Structure;
	Result.Insert("ObjectAttributesToLocalize", New Map);
	Result.Insert("LanguageCode1", FirstAdditionalInfobaseLanguageCode());
	Result.Insert("LanguageCode2", SecondAdditionalInfobaseLanguageCode());
	Result.Insert("DefaultLanguage", Common.DefaultLanguageCode());
	Result.Insert("NameMetadataObject", MetadataObject.FullName());
	Result.Insert("PredefinedData", Undefined);
	
	ObjectManager = Common.ObjectManagerByFullName(Result.NameMetadataObject);
	
	Result.ObjectAttributesToLocalize = DescriptionsOfObjectAttributesToLocalize(MetadataObject);
	Result.PredefinedData = InfobaseUpdateInternal.PredefinedObjectData(MetadataObject, ObjectManager, Result.ObjectAttributesToLocalize);
	
	InfobaseUpdateInternal.PredefinedItemsSettings(ObjectManager, Result.PredefinedData);
	
	Return Result;
	
EndFunction

Function MultilingualAttributesStringsChanged(SuppliedInformationRecords, QueryData, ObjectAttributesToLocalize, RegistrationParameters) Export
	
	For Each AttributeDetails In ObjectAttributesToLocalize Do
		
		If MultilingualAttributeStringsChanged(SuppliedInformationRecords, QueryData,
				AttributeDetails.Key, RegistrationParameters) Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

Function MultilingualAttributeStringsChanged(SuppliedInformationRecords, QueryData, AttributeName, RegistrationParameters) Export
	
	LanguagesInformationRecords = NationalLanguageSupportCached.LanguagesInformationRecords();
	
	MainLanguageValue = SuppliedInformationRecords[NameOfAttributeToLocalize(AttributeName, LanguagesInformationRecords.DefaultLanguage)];
	If IsBlankString(MainLanguageValue) And ValueIsFilled(SuppliedInformationRecords[AttributeName]) Then
		MainLanguageValue = SuppliedInformationRecords[AttributeName];
	EndIf;
	
	If StrCompare(MainLanguageValue, QueryData[AttributeName]) <> 0 Then
		
		If IsBlankString(MainLanguageValue) Then
			If Not RegistrationParameters.SkipEmpty Then
				Return True;
			EndIf;
		Else
			Return True;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(LanguagesInformationRecords.Language1)
		And StrCompare(SuppliedInformationRecords[NameOfAttributeToLocalize(AttributeName, LanguagesInformationRecords.Language1)], QueryData[AttributeName + "Language1"]) <> 0  Then
		
		If IsBlankString(SuppliedInformationRecords[NameOfAttributeToLocalize(AttributeName, LanguagesInformationRecords.Language1)]) Then
			If Not RegistrationParameters.SkipEmpty Then
				Return True;
			EndIf;
		Else
			Return True;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(LanguagesInformationRecords.Language2)
		And StrCompare(SuppliedInformationRecords[NameOfAttributeToLocalize(AttributeName, LanguagesInformationRecords.Language2)], QueryData[AttributeName + "Language2"]) <> 0  Then
		
		If IsBlankString(SuppliedInformationRecords[NameOfAttributeToLocalize(AttributeName, LanguagesInformationRecords.Language2)]) Then
			If Not RegistrationParameters.SkipEmpty Then
				Return True;
			EndIf;
		Else
			Return True;
		EndIf;
		
	EndIf;
	
	Return False;
	
EndFunction

// Parameters:
//  ObjectAttributesNames - Array of String
//  ObjectAttributesToLocalize - Map of KeyAndValue:
//   * Key - String
//   * Value - Boolean
//
Procedure GenerateNamesOfMultilingualAttributes(Val ObjectAttributesNames, Val ObjectAttributesToLocalize) Export
	
	LanguagesInformationRecords = NationalLanguageSupportCached.LanguagesInformationRecords();
	
	For Each ObjectAttribute In ObjectAttributesToLocalize Do
		
		ObjectAttributesNames.Add(ObjectAttribute.Key);
		
		If ValueIsFilled(LanguagesInformationRecords.Language1) Then
			ObjectAttributesNames.Add(ObjectAttribute.Key + "Language1");
		EndIf;
		If ValueIsFilled(LanguagesInformationRecords.Language2) Then
			ObjectAttributesNames.Add(ObjectAttribute.Key + "Language2");
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure WhenGettingParametersForFillingInPredefinedData(FillParameters) Export
	
	FillParameters.Insert("Languages", StandardSubsystemsServer.ConfigurationLanguages());
	FillParameters.Insert("LanguagesInformationRecords", LanguagesInformationRecords());
	
EndProcedure

Procedure InitialFillingInOfPredefinedDataLocalizedBankingDetails(ItemToFill, TableRow, 
	ExceptionFields, Context) Export
	
	LanguagesInformationRecords = LanguagesInformationRecords();
	
	HierarchySupported = Context.HierarchySupported;
	
	ObjectAttributesToLocalize = Context.ObjectAttributesToLocalize;
	MultilanguageStringsInAttributes = Context.MultilanguageStringsInAttributes;
	
	If ObjectAttributesToLocalize.Count() > 0 Then
		If MultilanguageStringsInAttributes Then
			
			For Each NameOfAttributeToLocalize In ObjectAttributesToLocalize Do
				
				ValueMainLanguage = TableRow[NameOfAttributeToLocalize.Key + "_"
				+ LanguagesInformationRecords.DefaultLanguage];
				
				If IsBlankString(ValueMainLanguage) Then
					ValueMainLanguage = TableRow[NameOfAttributeToLocalize.Key];
				EndIf;
				
				If ExceptionFields[NameOfAttributeToLocalize.Key] = Undefined Then
					ItemToFill[NameOfAttributeToLocalize.Key] = ValueMainLanguage;
				EndIf;
				
				For Position = 1 To LanguagesInformationRecords.AdditionalLanguagesCount Do
					
					LanguageSuffix = "Language" + String(Position);
					AttributeName = NameOfAttributeToLocalize.Key + LanguageSuffix;
					
					If ExceptionFields[AttributeName] <> Undefined
						Or (Not IsAdditionalLangUsed(LanguageSuffix) 
						And ValueIsFilled(ItemToFill[AttributeName])) Then
						Continue;
					EndIf;
					
					If ValueIsFilled(LanguagesInformationRecords[LanguageSuffix]) Then
						ValueLanguage = TableRow[NameOfAttributeToLocalize.Key + "_" + LanguagesInformationRecords[LanguageSuffix]];
					EndIf;
					
					ItemToFill[AttributeName] = ?(IsBlankString(ValueLanguage), ValueMainLanguage, ValueLanguage);
					
				EndDo;
				
			EndDo;
		EndIf;
		
		If Context.ObjectContainsPMRepresentations And Not (HierarchySupported
			And ItemToFill.IsFolder) Then
			InfobaseUpdateInternal.InitialFillingPMViews(ItemToFill, TableRow,
			Context);
		EndIf;
	EndIf;
	
EndProcedure


Procedure FillItemsWithMultilingualInitialData(ItemToFill, TableRow, Context, ExceptionFields) Export
	
	HierarchySupported = Context.HierarchySupported;
	ObjectAttributesToLocalize = Context.ObjectAttributesToLocalize;
	MultilanguageStringsInAttributes = Context.MultilanguageStringsInAttributes;
	
	If ObjectAttributesToLocalize.Count() = 0 Then
		Return;
	EndIf;
	
	Languages = StandardSubsystemsServer.ConfigurationLanguages();
	LanguagesInformationRecords = LanguagesInformationRecords();
	
	If MultilanguageStringsInAttributes Then 
		
		InitialFillingInOfPredefinedDataLocalizedBankingDetails(ItemToFill, TableRow, ArrayIntoMap(ExceptionFields), Context);
		
	ElsIf Not (HierarchySupported And ItemToFill.IsFolder) Then
		
		For Each LanguageCode In Languages Do
			ViewTable = ItemToFill.Presentations; // ValueTable
			NewPresentation = ViewTable.Add();
			NewPresentation.LanguageCode = LanguageCode;
			For Each NameOfAttributeToLocalize In ObjectAttributesToLocalize Do
				Value = TableRow[NameOfAttributeToLocalize.Key + "_" + LanguageCode];
				NewPresentation[NameOfAttributeToLocalize.Key] = ?(ValueIsFilled(Value), Value, TableRow[NameOfAttributeToLocalize.Key]);
			EndDo;
		EndDo;
		
	EndIf;

EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	If Metadata.Languages.Count() > 1 Then
	
		Handler = Handlers.Add();
		Handler.Version = "3.1.6.16";
		Handler.Comment = NStr("ru = 'Заполнение значений мультиязычных реквизитов значением основного языка.';
										|en = 'Fill in values of multilanguage attributes with the main language value.';");
	
		If Common.DataSeparationEnabled() 
			 And Not Common.SeparatedDataUsageAvailable() Then
			
			Handler.ExecutionMode = "Seamless";
			Handler.SharedData     = True;
			Handler.Procedure       = "NationalLanguageSupportServer.ProcessGeneralDataToUpgradeToNewVersion";
		
		Else
		
			Handler.ExecutionMode = "Deferred";
			Handler.Procedure = "NationalLanguageSupportServer.ProcessDataForMigrationToNewVersion";
			
			Handler.Id = New UUID("68d400bb-e5bb-49da-a567-ebf7458b29f8");
			Handler.UpdateDataFillingProcedure = "NationalLanguageSupportServer.RegisterDataToProcessForMigrationToNewVersion";
			Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
			
			ObjectsSCHRepresentations = ObjectsSCHRepresentations(VariantOfDataForProcessingTakingIntoAccountSeparation());
			
			ObjectsForProcessing = ObjectsWithInitialStringFilling(ObjectsSCHRepresentations);
			
			Handler.ObjectsToRead    = ObjectsForProcessing;
			Handler.ObjectsToChange  = ObjectsForProcessing;
			Handler.ObjectsToLock = ObjectsForProcessing;
			
		EndIf;

	EndIf;

	
EndProcedure

// Adds or changes the attribute values in the object.
//
// Parameters:
//  Object - CatalogObject
//         - DocumentObject
//         - ChartOfCharacteristicTypesObject
//         - InformationRegisterRecord - Object to populate.
//  Values - Structure - where the key is the attribute name, and the value contains the string to be placed in the attribute.
//  LanguageCode - String - attribute language code. For example, "en".
//
Procedure SetAttributesValues(Object, Values, Val LanguageCode = Undefined) Export
	
	If Not ValueIsFilled(LanguageCode) Then
		LanguageCode = DefaultLanguageCode();
	EndIf;
	
	LanguagesCodes = New Array;
	LanguagesCodes.Add(LanguageCode);
	
	AvailableLanguages = StandardSubsystemsServer.ConfigurationLanguages();
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
		PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
		AdditionalLanguages = PrintManagementModuleNationalLanguageSupport.AdditionalLanguagesOfPrintedForms();
		CommonClientServer.SupplementArray(AvailableLanguages, AdditionalLanguages);
	EndIf;
	
	MetadataObject = Object.Metadata();
	AllMultilingualRequisites = MultilingualObjectAttributes(MetadataObject);
	NamesofLocalizableDetails = TheNamesOfTheLocalizedDetailsOfTheObjectInTheHeader(MetadataObject);
	
	TSPresentations = Undefined;
	If ObjectContainsPMRepresentations(MetadataObject.FullName()) Then
		TSPresentations = Metadata.FindByType(TypeOf(Object.Presentations));
	EndIf;
	
	For Each AttributeValue In Values Do
		AttributeName = AttributeValue.Key;
		AttributeValues = New Map();
		
		StringWithoutSpaces = StrReplace(AttributeValue.Value, " ", "");
		If Common.StringAsNstr(StringWithoutSpaces) Then
			For Each Language In AvailableLanguages Do
				If StrFind(StringWithoutSpaces, Language +"=") > 0 Then
					AttributeValues[Language] = NStr(AttributeValue.Value, Language);
				EndIf;
			EndDo;
		Else
			AttributeValues[LanguageCode] = AttributeValue.Value;
		EndIf;
		
		For Each Item In AttributeValues Do
			Language = Item.Key;
			Value = Item.Value;
			
			If AllMultilingualRequisites[AttributeName] <> Undefined Then
				
				If Language = Common.DefaultLanguageCode() Then
					Object[AttributeName] = Value;
					Continue;
				EndIf;
				
				If NamesofLocalizableDetails[AttributeName] <> Undefined Then
					LanguageSuffix = LanguageSuffix(Language);
					If ValueIsFilled(LanguageSuffix) Then
						Object[AttributeName + LanguageSuffix] = Value;
					EndIf;
				EndIf;
				
				If TSPresentations <> Undefined 
					 And TSPresentations.Attributes.Find(AttributeName) <> Undefined Then
						
						FoundRow = Undefined;
						For Each TableRow In Object.Presentations Do
							If TableRow.LanguageCode = Language Then
								FoundRow = TableRow;
								Break;
							EndIf;
						EndDo;
						
						If FoundRow =  Undefined Then
							FoundRow = Object.Presentations.Add();
							FoundRow.LanguageCode = Language;
						EndIf;
						
						FoundRow[AttributeName] = Value;
				EndIf;
				
			Else // If an attribute is not multilingual, set its value only in the default language.
				If LanguageCode = Common.DefaultLanguageCode() Then
					Object[AttributeName] = AttributeValues[LanguageCode];
				EndIf;
			EndIf;
			
		EndDo;
	EndDo;
	
EndProcedure

// Parameters:
//  ParameterName - String
//  SpecifiedParameters - Array of String
//
Procedure SessionParametersSetting(Val SessionParametersNames, SpecifiedParameters) Export
	
	If SessionParametersNames = Undefined
	 Or SessionParametersNames.Find("DefaultLanguage") <> Undefined Then
		
		SessionParameters.DefaultLanguage = InfobaseLanguageCode();
		SpecifiedParameters.Add("DefaultLanguage");
	EndIf;
	
EndProcedure

Function FirstAdditionalInfobaseLanguageCode() Export
	
	If Not FirstAdditionalLanguageUsed() Then
		Return "";
	EndIf;
	
	LanguageCode = Constants.AdditionalLanguage1.Get();
	For Each LanguagesFromMetadata In Metadata.Languages Do
		If StrCompare(LanguagesFromMetadata.LanguageCode, LanguageCode) = 0 Then
			Return LanguageCode;
		EndIf;
	EndDo;
	
	Return "";
	
EndFunction

Function SecondAdditionalInfobaseLanguageCode() Export
	
	If Not SecondAdditionalLanguageUsed() Then
		Return "";
	EndIf;
	
	LanguageCode = Constants.AdditionalLanguage2.Get();
	For Each LanguagesFromMetadata In Metadata.Languages Do
		If StrCompare(LanguagesFromMetadata.LanguageCode, LanguageCode) = 0 Then
			Return LanguageCode;
		EndIf;
	EndDo;
	
	Return "";
	
EndFunction

#EndRegion

#Region Private

// Parameters:
//  Object - CatalogObject
//         - DocumentObject
//         - FormDataStructure:
//            * Ref - CatalogRef
//                     - DocumentRef
//                     - ChartOfCharacteristicTypesRef
//            * SourceRecordKey - InformationRegisterRecord
// 
// Returns:
//  MetadataObjectCatalog
//  MetadataObjectDocument
//  MetadataObject
//
Function MetadataObject(Object) Export
	
	If TypeOf(Object) = Type("FormDataStructure") Then
		If Not Object.Property("SourceRecordKey") Then
			ObjectType = TypeOf(Object.Ref);
		Else
			ObjectType = TypeOf(Object.SourceRecordKey);
		EndIf;
	Else
		ObjectType = TypeOf(Object);
	EndIf;
	
	ObjectMetadata1 = Metadata.FindByType(ObjectType);
	
	Return ObjectMetadata1;
	
EndFunction

Function NameOfAttributeToLocalize(AttributeName, LanguageCode)
	
	Return AttributeName + "_" + LanguageCode;
	
EndFunction

// Code of the main infobase language
// 
// Returns:
//  String - a language code. For example, "en".
//
Function InfobaseLanguageCode()
	
	DefaultLanguageCode = Constants.DefaultLanguage.Get();
	If ValueIsFilled(DefaultLanguageCode) Then
		For Each ConfigurationLanguages In Metadata.Languages Do
			If StrCompare(ConfigurationLanguages.LanguageCode, DefaultLanguageCode) = 0 Then
				Return DefaultLanguageCode;
			EndIf;
		EndDo;
	EndIf;
	
	Return Metadata.DefaultLanguage.LanguageCode;
	
EndFunction

// Returns:
//  Structure:
//   * MainLanguageOldValue - String
//   * AdditionalLanguage1OldValue - String
//   * AdditionalLanguage2OldValue - String
//   * MainLanguageNewMeaning - String
//   * AdditionalLanguage1NewValue - String
//   * AdditionalLanguage2NewValue - String
//
Function DescriptionOfOldAndNewLanguageSettings() Export
	
	DescriptionOfConstants = New Structure;
	DescriptionOfConstants.Insert("MainLanguageOldValue", "");
	DescriptionOfConstants.Insert("AdditionalLanguage1OldValue", "");
	DescriptionOfConstants.Insert("AdditionalLanguage2OldValue", "");
	DescriptionOfConstants.Insert("MainLanguageNewMeaning", "");
	DescriptionOfConstants.Insert("AdditionalLanguage1NewValue", "");
	DescriptionOfConstants.Insert("AdditionalLanguage2NewValue", "");
	
	Return DescriptionOfConstants;
	
EndFunction

Function DefineFormType(FormName) Export
	
	Result = "";
	
	FormNameParts1 = StrSplit(Upper(FormName), ".");
	DefaultListForm = DefaultListForm(FormNameParts1);
	MainChoiceForm = DefaultChoiceForm(FormNameParts1);
	
	FoundForm = Metadata.FindByFullName(FormName);
	
	If DefaultListForm = FoundForm  Then
		Result = "DefaultListForm";
	ElsIf MainChoiceForm  = FoundForm Then
		Result = "MainChoiceForm";
	EndIf;
	
	Return Result;
	
EndFunction

Function ObjectAttributesToLocalizeForCurrentLanguage(MetadataObject, Language = Undefined)
	
	AttributesList = New Map;
	
	If ValueIsFilled(Language) Then
		LanguagePrefix = Language;
	Else
		LanguagePrefix = CurrentLanguageSuffix();
	EndIf;
	
	ObjectAttributesList = New Map;
	MetadataObjectAttributes = MetadataObject.Attributes; //  MetadataObjectCollection of MetadataObjectAttribute -
	For Each Attribute In MetadataObjectAttributes Do
		ObjectAttributesList.Insert(Attribute.Name, Attribute);
	EndDo;
	
	MetadataObjectStandardAttributes = MetadataObject.StandardAttributes; // MetadataObjectCollection of StandardAttributeDescription -
	For Each Attribute In MetadataObjectStandardAttributes Do
		ObjectAttributesList.Insert(Attribute.Name, Attribute);
	EndDo;
	
	QueryText = "SELECT TOP 0
		|	*
		|FROM
		|	&MetadataObjectFullName AS SourceData";
	
	QueryText = StrReplace(QueryText, "&MetadataObjectFullName", MetadataObject.FullName());
	Query = New Query(QueryText);
	
	QueryResult = Query.Execute();
	
	AttributesList = New Map;
	For Each Column In QueryResult.Columns Do
		If StrEndsWith(Column.Name, LanguagePrefix) Then
			Attribute = ObjectAttributesList.Get(Column.Name);
			If Attribute = Undefined Then
				Attribute = Metadata.CommonAttributes.Find(Column.Name);
			EndIf;
			AttributesList.Insert(Column.Name, Attribute);
			
		EndIf;
	EndDo;
	
	Return AttributesList;
	
EndFunction

// Returns:
//  Map of KeyAndValue:
//   * Key - String 
//   * Value - Boolean 
//
Function DescriptionsOfObjectAttributesToLocalize(MetadataObject, Prefix = "") Export
	
	ObjectAttributesList = New Map;
	If MultilanguageStringsInAttributes(MetadataObject) Then
		
		LanguageSuffixLength = LanguageSuffixLength();
		
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED TOP 0
			|	*
			|FROM
			|	&TableName AS SourceData";
		Query.Text = StrReplace(Query.Text, "&TableName", MetadataObject.FullName());
		
		QueryResult = Query.Execute();
		
		For Each Column In QueryResult.Columns Do
			If (StrEndsWith(Column.Name, "Language1")
			 Or  StrEndsWith(Column.Name, "Language2"))
			   And Not StrStartsWith(Column.Name, "Delete") Then
				ObjectAttributesList.Insert(Prefix + Left(Column.Name, StrLen(Column.Name) - LanguageSuffixLength), False);
			EndIf;
		EndDo;
		
	EndIf;
	
	FullName = MetadataObject.FullName();
	
	If ObjectContainsPMRepresentations(FullName) Then
		
		PresentationTabularSectionAttributes = NationalLanguageSupportCached.TabularSectionMultilingualAttributes(FullName);
		For Each AttributeName In PresentationTabularSectionAttributes Do
			ObjectAttributesList.Insert(Prefix + AttributeName, True);
		EndDo;
		
	EndIf;
	
	Return ObjectAttributesList;
	
EndFunction

Function TheNamesOfTheLocalizedDetailsOfTheObjectInTheHeader(MetadataObject, Prefix = "") Export
	
	ObjectAttributesList = New Map;
	If MultilanguageStringsInAttributes(MetadataObject) Then
	
		LanguageSuffixLength = LanguageSuffixLength();
		
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED TOP 0
			|	*
			|FROM
			|	&TableName AS SourceData";
		Query.Text = StrReplace(Query.Text, "&TableName", MetadataObject.FullName());
		
		QueryResult = Query.Execute();
		
		For Each Column In QueryResult.Columns Do
			If (StrEndsWith(Column.Name, "Language1")
			 Or  StrEndsWith(Column.Name, "Language2"))
			   And Not StrStartsWith(Column.Name, "Delete") Then
				ObjectAttributesList.Insert(Prefix + Left(Column.Name, StrLen(Column.Name) - LanguageSuffixLength), False);
			EndIf;
		EndDo;
	EndIf;
	
	Return ObjectAttributesList;
	
EndFunction

Function LanguageSuffixLength()
	
	Return StrLen("Language1");
	
EndFunction

Function ArrayIntoMap(Array)
	Map = New Map();
	For Each Item In Array Do
		Map.Insert(Item, True);
	EndDo; 
	Return Map;
EndFunction

Function DefaultListForm(FormNameParts1)
	
	If FormNameParts1[0]= "CATALOG"
		Or FormNameParts1[0] = "DOCUMENT"
		Or FormNameParts1[0] = "ENUM"
		Or FormNameParts1[0] = "CHARTOFCHARACTERISTICTYPES"
		Or FormNameParts1[0] = "CHARTOFACCOUNTS"
		Or FormNameParts1[0] = "CHARTOFCALCULATIONTYPES"
		Or FormNameParts1[0] = "BUSINESSPROCESS"
		Or FormNameParts1[0] = "TASK"
		Or FormNameParts1[0] = "TASK"
		Or FormNameParts1[0] = "ACCOUNTINGREGISTER"
		Or FormNameParts1[0] = "ACCUMULATIONREGISTER"
		Or FormNameParts1[0] = "CALCULATIONREGISTER"
		Or FormNameParts1[0] = "INFORMATIONREGISTER"
		Or FormNameParts1[0] = "EXCHANGEPLAN" Then
			Return Common.MetadataObjectByFullName(FormNameParts1[0] + "." + FormNameParts1[1]).DefaultListForm;
	EndIf;
	
	Return Undefined;
	
EndFunction

Function DefaultChoiceForm(FormNameParts1)
	
	If FormNameParts1[0]= "CATALOG"
		Or FormNameParts1[0] = "DOCUMENT"
		Or FormNameParts1[0] = "ENUM"
		Or FormNameParts1[0] = "CHARTOFCHARACTERISTICTYPES"
		Or FormNameParts1[0] = "CHARTOFACCOUNTS"
		Or FormNameParts1[0] = "BUSINESSPROCESS"
		Or FormNameParts1[0] = "TASK"
		Or FormNameParts1[0] = "TASK"
		Or FormNameParts1[0] = "EXCHANGEPLAN" Then
			Return Common.MetadataObjectByFullName(FormNameParts1[0] + "." + FormNameParts1[1]).DefaultChoiceForm;
	EndIf;
	
	Return Undefined;
	
EndFunction

Function ObjectNamesWithMultilingualAttributes() Export
	
	MultilingualObjects = New Map;
	
	For Each Item In Metadata.FunctionalOptions["UseAdditionalLanguage1"].Content Do
		
		Attribute = Item.Object;
		AttributeName = Left(Attribute.Name, StrLen(Attribute.Name) - StrLen(FirstLanguageSuffix()));
		
		If Metadata.CommonAttributes.Contains(Attribute) Then
			AutoUse = (Attribute.AutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse.Use);
			For Each CompositionItem In Attribute.Content Do
				
				If CompositionItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Use
					Or (AutoUse And CompositionItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Auto) Then
					
					If MultilingualObjects[CompositionItem.Metadata.FullName()] = Undefined Then
						AttributesList = New Array;
						AttributesList.Add(AttributeName);
						MultilingualObjects.Insert(CompositionItem.Metadata.FullName(), AttributesList);
					Else
						AttributesList = MultilingualObjects[CompositionItem.Metadata.FullName()]; // Array
						AttributesList.Add(AttributeName);
					EndIf;
					
				EndIf;
				
			EndDo;
		Else
			MetadataObject = Attribute.Parent();
			If MetadataObject <> Undefined Then
				
				If MultilingualObjects[MetadataObject.FullName()] = Undefined Then
					AttributesList = New Array;
					AttributesList.Add(AttributeName);
					MultilingualObjects.Insert(MetadataObject.FullName(), AttributesList);
				Else
					AttributesList = MultilingualObjects[MetadataObject.FullName()]; // Array
					AttributesList.Add(AttributeName);
				EndIf;
				
			EndIf;
		EndIf;
	EndDo;
	
	Return MultilingualObjects;
	
EndFunction

Procedure ClearMultilingualBankingDetails(Object, ObjectMetadata1)
	
	If MultilanguageStringsInAttributes(ObjectMetadata1) Then
		
		ListOfMultilingualDetails = TheNamesOfTheLocalizedDetailsOfTheObjectInTheHeader(ObjectMetadata1);
		For Each Attribute In ListOfMultilingualDetails Do
			Object[Attribute.Key + "Language1"] = "";
			Object[Attribute.Key + "Language2"] = "";
		EndDo;
		
	ElsIf Object.Property("Presentations") Then
		
		Object.Presentations.Clear();
		
	EndIf;
	
EndProcedure

Function IsMainLanguage() Export
	
	Return StrCompare(Common.DefaultLanguageCode(), CurrentLanguage().LanguageCode) = 0;
	
EndFunction

Procedure FillInEmptyMultilingualDetailsWithTheValueOfTheMainLanguage(Selection, MetadataObject, TotalProcessed)
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	
	While Selection.Next() Do
		
		TotalProcessed = TotalProcessed + 1;
		
		Block = New DataLock;
		LockItem = Block.Add(MetadataObject.FullName());
		LockItem.SetValue("Ref", Selection.Ref);
		
		BeginTransaction();
		Try
			
			Block.Lock();
			
			CurrentObject = Selection.Ref.GetObject();
			If CurrentObject <> Undefined Then
				
				LockDataForEdit(Selection.Ref);
				
				// @skip-check query-in-loop - Batch processing of a large amount of data.
				NamesOfAttributesToLocalize = TheNamesOfTheLocalizedDetailsOfTheObjectInTheHeader(MetadataObject);
				
				For Each Attribute In NamesOfAttributesToLocalize Do
					
					AttributeValue = CurrentObject[Attribute.Key];
					If IsBlankString(AttributeValue) Then
						Continue;
					EndIf;
					
					If IsBlankString(CurrentObject[Attribute.Key + "Language1"]) Then
						CurrentObject[Attribute.Key + "Language1"] = AttributeValue;
					EndIf;
					
					If IsBlankString(CurrentObject[Attribute.Key + "Language2"]) Then
						CurrentObject[Attribute.Key + "Language2"] = AttributeValue;
					EndIf;
				EndDo;
				
				InfobaseUpdate.WriteObject(CurrentObject);
				
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
		Except
			
			RollbackTransaction();
			// If an object cannot be processed, try again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось заполнить мультиязычные реквизиты объекта %1 по причине:
				|%2';
				|en = 'Cannot fill in multi-language attributes of the %1 object due to:
				|%2';"), Selection.Ref, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				MetadataObject, Selection.Ref, MessageText);
			
		EndTry;
		
	EndDo;
		
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось заполнить мультиязычные реквизиты в некоторых объектах (пропущены): %1';
				|en = 'Couldn''t fill in (skipped) multilanguage attributes in some objects: %1';"), 
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			MetadataObject,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Заполнены мультиязычные реквизиты в очередной порции объектов: %1';
					|en = 'Multilingual attributes are populated in yet another batch of objects: %1';"),
				ObjectsProcessed));
	EndIf;
	
EndProcedure

Procedure PopulateMultilingualAttributesOfPresentationsTabularSection(CurrentObject, Val Attributes, NamesOfMultiLangAttributesInHeader)
	
	Presentations = CurrentObject.Presentations; // TabularSection
	CurrentLanguageSuffix = CurrentLanguageSuffix();
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
		PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
		AvailableLanguages = PrintManagementModuleNationalLanguageSupport.AvailableLanguages();
	Else
		AvailableLanguages = New Array;
		For Each Language In Metadata.Languages Do
			AvailableLanguages.Add(Language.LanguageCode);
		EndDo;
	EndIf;

	For Each PrintFormLanguage In AvailableLanguages Do
		
		If CurrentLanguage().LanguageCode = PrintFormLanguage Then
			Continue;
		EndIf;
		
		Filter = New Structure();
		Filter.Insert("LanguageCode", PrintFormLanguage);
		FoundRows = Presentations.FindRows(Filter);
		
		If FoundRows.Count() > 0 Then
			Presentation = FoundRows[0];
		Else
			Presentation = Presentations.Add();
			Presentation.LanguageCode = PrintFormLanguage;
		EndIf;
		
		For Each AttributeName In Attributes Do
			If IsBlankString(Presentation[AttributeName]) Then
				ValueInCurrentLanguage = ?(NamesOfMultiLangAttributesInHeader[AttributeName] <> Undefined,
					CurrentObject[AttributeName + CurrentLanguageSuffix], CurrentObject[AttributeName]) ;
				Presentation[AttributeName] = ValueInCurrentLanguage;
			EndIf;
			
		EndDo;
		
	EndDo;

EndProcedure


// Parameters:
//  Attribute - MetadataObjectAttribute
//           - StandardAttributeDescription
//
Function IsAttributeToLocalize(AttributeName)
	Return StrEndsWith(AttributeName, "Language1") Or StrEndsWith(AttributeName, "Language2");
EndFunction

// Parameters:
//  DataVariant - String - Valid values are: "Overall", "Separated_Data", "All" 
// 
// Returns:
//  Array - ObjectsSCHRepresentations objects
//
Function ObjectsSCHRepresentations(DataVariant)
	
	ObjectsSCHRepresentations = New Array;

	If DataVariant = "Separated_Data" Or DataVariant = "All" Then
			
		If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
			ModuleContactsManagerInternal = Common.CommonModule("ContactsManagerInternal");
			ModuleContactsManagerInternal.OnDefineObjectsWithTablePresentation(ObjectsSCHRepresentations);
		EndIf;
		
		If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
			ModuleReportsOptionsInternal = Common.CommonModule("ReportsOptionsInternal");
			ModuleReportsOptionsInternal.OnDefineObjectsWithTablePresentation(ObjectsSCHRepresentations);
		EndIf;
		
		If Common.SubsystemExists("StandardSubsystems.Properties") Then
			ModulePropertyManagerInternal = Common.CommonModule("PropertyManagerInternal");
			ModulePropertyManagerInternal.OnDefineObjectsWithTablePresentation(ObjectsSCHRepresentations);
		EndIf;
	EndIf;
	
	If DataVariant = "Overall" Or DataVariant = "All" Then
		If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
			ModuleReportsOptionsInternal = Common.CommonModule("ReportsOptionsInternal");
			ModuleReportsOptionsInternal.OnDefineObjectsWithTablePresentationCommonData(ObjectsSCHRepresentations);
		EndIf;
	EndIf;
	
	Return ObjectsSCHRepresentations;
	
EndFunction

Function VariantOfDataForProcessingTakingIntoAccountSeparation()
	Return ?(Common.SeparatedDataUsageAvailable(), "Separated_Data", "All");
EndFunction

Procedure FillAndMoveLinesFromPchViewToRequisites(Ref, FillParameters, ObjectsProcessed, ObjectsWithIssuesCount)
	
	MetadataObject = Ref.Metadata(); // MetadataObject
	
	ObjectTabularSection = MetadataObject.TabularSections.Find("Presentations"); // MetadataObjectTabularSection
	If ObjectTabularSection = Undefined Then
		Return;
	EndIf;
	
	Hierarchical = (Common.IsCatalog(MetadataObject)
		Or Common.IsChartOfCharacteristicTypes(MetadataObject))
		And MetadataObject.Hierarchical;
		
	If Hierarchical And MetadataObject.HierarchyType
		= Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
		
		ObjectTabularSection = MetadataObject.TabularSections.Find("Presentations"); // MetadataObjectTabularSection
		IsFolder = Common.ObjectAttributeValue(Ref, "IsFolder");

		If ObjectTabularSection.Use = Metadata.ObjectProperties.AttributeUse.ForItem
			 And IsFolder Then
				Return;
		ElsIf ObjectTabularSection.Use = Metadata.ObjectProperties.AttributeUse.ForFolder
			 And Not IsFolder Then
				Return;
		EndIf;
	EndIf;
	
	FullName = MetadataObject.FullName();
	
	Block = New DataLock;
	LockItem = Block.Add(FullName);
	LockItem.SetValue("Ref", Ref);
	
	Languages = StandardSubsystemsServer.ConfigurationLanguages();
	
	BeginTransaction();
	Try
		
		Block.Lock();
		RepresentationOfTheReference = String(Ref);
		LockDataForEdit(Ref);
		
		Object = Ref.GetObject();
		
		For Each LanguageCode In Languages Do
			
			If StrCompare(Common.DefaultLanguageCode(), LanguageCode) = 0 Then
				Continue;
			EndIf;
			
			Filter = New Structure("LanguageCode", LanguageCode);
			FoundRows = Object.Presentations.FindRows(Filter);
			
			If FoundRows.Count() > 0 Then
				TableRow = FoundRows[0];
			Else
				TableRow = Object.Presentations.Add();
				TableRow.LanguageCode = LanguageCode;
			EndIf;
			
			MultilingualAttributes = NationalLanguageSupportCached.TabularSectionMultilingualAttributes(FullName);
			For Each AttributeName In MultilingualAttributes Do
				
				ValueInMainLanguage = Object[AttributeName];
				
				If IsBlankString(TableRow[AttributeName]) Then
					
					FillingData = PrimaryAttributeValue(FillParameters, AttributeName, Object, LanguageCode);
					If IsBlankString(FillingData) Then
						FillingData = ValueInMainLanguage;
					EndIf;
				
					If ValueIsFilled(FillingData) Then
						
						If StrCompare(Common.DefaultLanguageCode(), LanguageCode) = 0 Then
							Object[AttributeName] = FillingData;
						ElsIf StrCompare(FirstAdditionalInfobaseLanguageCode(), LanguageCode) = 0 Then
							Object[AttributeName + FirstLanguageSuffix()] = FillingData;
						ElsIf StrCompare(SecondAdditionalInfobaseLanguageCode(), LanguageCode) = 0 Then
							Object[AttributeName + SecondLanguageSuffix()] = FillingData;
						EndIf;
						
					EndIf;
				Else
					
					If StrCompare(FirstAdditionalInfobaseLanguageCode(), LanguageCode) = 0 
						And IsBlankString(Object[AttributeName + FirstLanguageSuffix()]) Then
							Object[AttributeName + FirstLanguageSuffix()] = TableRow[AttributeName];
					ElsIf StrCompare(SecondAdditionalInfobaseLanguageCode(), LanguageCode) = 0
							And IsBlankString(Object[AttributeName + SecondLanguageSuffix()])Then
						Object[AttributeName + SecondLanguageSuffix()] = TableRow[AttributeName];
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		InfobaseUpdate.WriteObject(Object);
		ObjectsProcessed = ObjectsProcessed + 1;
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
		
		InfobaseUpdate.WriteErrorToEventLog(
			Ref,
			RepresentationOfTheReference,
			ErrorInfo());
	EndTry;
	
EndProcedure

// Parameters:
//  ListOfObjects - Array
// 
// Returns:
//  String - A comma-delimited list of object names
//
Function ObjectsWithInitialStringFilling(ListOfObjects)
	
	ObjectsWithInitialFilling = ObjectsWithInitialFilling(VariantOfDataForProcessingTakingIntoAccountSeparation());

	For Each ObjectWithPredefinedElements In ObjectsWithInitialFilling Do
		FullName = ObjectWithPredefinedElements.Value;
		If ListOfObjects.Find(FullName) = Undefined Then
			ListOfObjects.Add(FullName);
		EndIf;
	EndDo;
	
	Return StrConcat(ListOfObjects, ",");
	
EndFunction

Function ListOfObjectsToBeProcessedToUpgradeToNewVersion(DataVariant)
	
	ObjectsToBeProcessed = New Array();
	TheSeparatorQueries = Chars.LF + " UNION ALL " + Chars.LF;
	
	LanguagesInformationRecords = NationalLanguageSupportCached.LanguagesInformationRecords();
	If ValueIsFilled(LanguagesInformationRecords.Language1) Or ValueIsFilled(LanguagesInformationRecords.Language2) Then
	
		ObjectsWithPredefinedItems = ObjectsWithInitialFilling(DataVariant);
		
		QueryTemplate = "SELECT
			|	ObjectData.Ref
			|FROM
			|	&Table AS ObjectData
			|WHERE
			|	&FilterCriterion";
		
		QueriesSet = New Array;
		
		For Each ObjectWithPredefinedElements In ObjectsWithPredefinedItems Do
			
			MetadataObjectWithItems = ObjectWithPredefinedElements.Key;
			FullMetadataObjectName  = ObjectWithPredefinedElements.Value;
			
			// @skip-check query-in-loop - Batch processing of a large amount of data.
			ObjectAttributesToLocalize = TheNamesOfTheLocalizedDetailsOfTheObjectInTheHeader(MetadataObjectWithItems);
			Filters = New Array;
			
			For Each ObjectAttribute In ObjectAttributesToLocalize Do
				
				If Not ObjectAttribute.Value Then
					Continue;
				EndIf;
				
				If ValueIsFilled(LanguagesInformationRecords.Language1) And ValueIsFilled(LanguagesInformationRecords.Language2) Then
					FilterTemplate = "CAST(&Attribute AS STRING(1)) <> """"
					| AND (CAST(&Language1 AS STRING(1)) = """" OR CAST(&Language2 AS STRING(1)) = """")";
					
					FilterTemplate = StrReplace(FilterTemplate, "&Language1", ObjectAttribute.Key + "Language1");
					FilterTemplate = StrReplace(FilterTemplate, "&Language2", ObjectAttribute.Key + "Language2");
					
				Else
					FilterTemplate = "CAST(&Attribute AS STRING(1)) <> """"
					| AND CAST(&Language1Or2 AS STRING(1)) = """"";
					
					If ValueIsFilled(LanguagesInformationRecords.Language2) Then
						FilterTemplate = StrReplace(FilterTemplate, "&Language1Or2", ObjectAttribute.Key + "Language2");
					Else
						FilterTemplate = StrReplace(FilterTemplate, "&Language1Or2", ObjectAttribute.Key + "Language1");
					EndIf;
					
				EndIf;
				
				FilterText1 = StrReplace(FilterTemplate, "&Attribute", ObjectAttribute.Key);
				Filters.Add(FilterText1);
				
			EndDo;
			
			If Filters.Count() = 0 Then
				Continue;
			EndIf;
				
			TheTextOfTheRequest = StrReplace(QueryTemplate, "&Table", FullMetadataObjectName);
			TheTextOfTheRequest = StrReplace(TheTextOfTheRequest, "&FilterCriterion", StrConcat(
				Filters, " OR "));
			QueriesSet.Add(TheTextOfTheRequest);
			
		EndDo;
		
		If QueriesSet.Count() > 0 Then
			
			Query = New Query;
			Query.Text = StrConcat(QueriesSet, TheSeparatorQueries);
			QueryResults = Query.Execute().Unload();
			ObjectsToBeProcessed = QueryResults.UnloadColumn("Ref");
			
		EndIf;
		
	EndIf;
	
	// A special batch of objects that should be registered with the "Presentations" table.
	ObjectsSCHRepresentations = ObjectsSCHRepresentations(DataVariant);
	
	If ObjectsSCHRepresentations.Count() > 0 Then
		
		QueryTemplate = "SELECT
		|DirectoryofSTCHRepresentations.Ref
		|FROM
		|	#PresentationTable AS DirectoryofSTCHRepresentations
		|	LEFT JOIN #Table AS CatalogPTS
		|		ON DirectoryofSTCHRepresentations.Ref = CatalogPTS.Ref
		|WHERE DirectoryofSTCHRepresentations.LanguageCode = ""&LanguageCode"" AND &Condition";
		
		TemplateWhere = "(CAST(DirectoryofSTCHRepresentations.%1 AS STRING(10)) <> """" 
		|AND CAST(CatalogPTS.%1#LanguageSuffix AS STRING(10)) = """")";
		
		QueriesSet = New Array;
		
		For Each MetadataObjectName In ObjectsSCHRepresentations Do
			
			MetadataObject = Metadata.FindByFullName(MetadataObjectName);
			ObjectTabularSection = MetadataObject.TabularSections.Find("Presentations"); // MetadataObjectTabularSection
			
			MultilingualAttributes = NationalLanguageSupportCached.TabularSectionMultilingualAttributes(MetadataObjectName);
			FilterConditions = New Array;
			
			For Each MultilingualProps In MultilingualAttributes Do
				
				FilterConditions.Add(StringFunctionsClientServer.SubstituteParametersToString(
					TemplateWhere, MultilingualProps));
			EndDo;
			
			QueryTextWhere = "(" + StrConcat(FilterConditions, " OR ") + ")";
			
			If MetadataObject.Hierarchical 
				And MetadataObject.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
				
				If ObjectTabularSection.Use = Metadata.ObjectProperties.AttributeUse.ForItem Then
					QueryTextWhere = QueryTextWhere + "
					|AND CatalogPTS.IsFolder <> TRUE";
				ElsIf ObjectTabularSection.Use = Metadata.ObjectProperties.AttributeUse.ForFolder Then
					QueryTextWhere = QueryTextWhere + "
					|AND CatalogPTS.IsFolder = TRUE";
				EndIf;
			EndIf;
			
			QueryText = StrReplace(QueryTemplate, "#PresentationTable", 
				MetadataObject.FullName() + "." + "Presentations");
			QueryText = StrReplace(QueryText, "#Table", MetadataObject.FullName());
			
			QueryText = StrReplace(QueryText, "&Condition", QueryTextWhere);
			QueriesSet.Add(QueryText);
			
		EndDo;
		
		QueryText = StrConcat(QueriesSet, TheSeparatorQueries);
		Query = New Query;
		
		If FirstAdditionalLanguageUsed() Then
			Query.Text = StrReplace(QueryText, "#LanguageSuffix", FirstLanguageSuffix());
			Query.Text = StrReplace(Query.Text, "&LanguageCode", FirstAdditionalInfobaseLanguageCode());
		EndIf;
		
		If SecondAdditionalLanguageUsed() Then 
			
			If ValueIsFilled(Query.Text) Then
				Query.Text = Query.Text + Common.QueryBatchSeparator();
			EndIf;
			
			RequestText = StrReplace(QueryText, "#LanguageSuffix", SecondLanguageSuffix());
			Query.Text = Query.Text + StrReplace(RequestText, "&LanguageCode", 
				SecondAdditionalInfobaseLanguageCode());
			
		EndIf;
		
		If ValueIsFilled(Query.Text) Then
			QueryResults = Query.ExecuteBatch();
			For Each QueryResult In QueryResults Do
				
				ObjectsTablePartViewToProcess = QueryResult.Unload().UnloadColumn("Ref");
				CommonClientServer.SupplementArray(ObjectsToBeProcessed, 
					ObjectsTablePartViewToProcess, True);
			EndDo;
		EndIf;
		
	EndIf;
	
	Return ObjectsToBeProcessed;
	
EndFunction

#Region ChangeLanguage

// Data for modifying multilanguage attributes.
// 
// Returns:
//  Structure:
//   * SettingsChangesLanguages - See NationalLanguageSupportServer.DescriptionOfOldAndNewLanguageSettings
//   * MainLanguageChanged - Boolean
//   * FirstAdditionalLanguageChanged - Boolean
//   * SecondAdditionalLanguageChanged - Boolean
//   * Objects - Map of KeyAndValue:
//   ** Key - String
//   ** Value - Structure:
//     *** ReferenceToLastProcessedObjects - Arbitrary
//    *** LanguageFields - Array
//	
Function DataToChangeMultilanguageAttributes() Export

	If Metadata.Languages.Count() = 1 
		Or (Common.DataSeparationEnabled() 
		   And Common.SeparatedDataUsageAvailable()) Then
		Return Undefined;
	EndIf;

	DataToChangeMultilanguageAttributes = Constants.DataToChangeMultilanguageAttributes.Get().Get();
	If DataToChangeMultilanguageAttributes = Undefined Then
		Return Undefined;
	EndIf;
	
	SettingsChangesLanguages = DataToChangeMultilanguageAttributes.SettingsChangesLanguages;
	DataToChangeMultilanguageAttributes.Insert("MainLanguageChanged", 
		StrCompare(SettingsChangesLanguages.MainLanguageNewMeaning, SettingsChangesLanguages.MainLanguageOldValue) <> 0);
	DataToChangeMultilanguageAttributes.Insert("FirstAdditionalLanguageChanged", 
		StrCompare(SettingsChangesLanguages.AdditionalLanguage1NewValue, SettingsChangesLanguages.AdditionalLanguage1OldValue) <> 0);
	DataToChangeMultilanguageAttributes.Insert("SecondAdditionalLanguageChanged",
		StrCompare(SettingsChangesLanguages.AdditionalLanguage2NewValue, SettingsChangesLanguages.AdditionalLanguage2OldValue) <> 0);
		
	Return DataToChangeMultilanguageAttributes;

EndFunction

Procedure ChangeLanguageinMultilingualDetailsConfig(Parameters, Address) Export
	
	DataToChangeMultilanguageAttributes = DataToChangeMultilanguageAttributes();
	If DataToChangeMultilanguageAttributes = Undefined Then
		Return;
	EndIf;
	
	ObjectsWithInitialFilling = InfobaseUpdateInternal.ObjectsWithInitialFilling();
	
	ProcessedObjectsCount1 = 0;
	DeletableObjects = New Array;
	
	For Each ObjectData In DataToChangeMultilanguageAttributes.Objects Do
		FullName = ObjectData.Key;
		ObjectMetadata = Common.MetadataObjectByFullName(FullName);
		Context = New Structure;

		If ObjectsWithInitialFilling.Get(ObjectMetadata) <> Undefined Then

			Context = InfobaseUpdateInternal.ParameterSetForFillingObject(
				ObjectMetadata);
			
		EndIf;
		
		Percent = Round(ProcessedObjectsCount1 * 100 / ObjectsWithInitialFilling.Count()) + 1;
		TimeConsumingOperations.ReportProgress(?(Percent >99, 98, Percent), ObjectMetadata.Presentation());
		
		If StrStartsWith(FullName, "Catalog")
		 Or StrStartsWith(FullName, "ChartOfCharacteristicTypes")
		 Or StrStartsWith(FullName, "ChartOfAccounts")
		 Or StrStartsWith(FullName, "ChartOfCalculationTypes") Then
			
			// @skip-check query-in-loop - Batch processing of a large amount of data.
			HandleReferenceObjects(FullName, ObjectData.Value, DataToChangeMultilanguageAttributes,
				Context);
				
		ElsIf StrStartsWith(FullName, "InformationRegister") Then
			MetadataObject = Common.MetadataObjectByFullName(FullName);
			
			If MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate Then
				// @skip-check query-in-loop - Batch processing of a large amount of data.
				ChangeLanguageInSubRegistersDetails(MetadataObject, ObjectData.Value,
					DataToChangeMultilanguageAttributes, Context);
			Else
				Periodic3 = MetadataObject.InformationRegisterPeriodicity
					<> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical;
				// @skip-check query-in-loop - Batch processing of a large amount of data.
				ChangeLanguageIncaseIndependentDetails(MetadataObject, ObjectData.Value,
					DataToChangeMultilanguageAttributes, Context, Periodic3);
			EndIf;
		Else
			DeletableObjects.Add(FullName);
		EndIf;
		
		ProcessedObjectsCount1 = ProcessedObjectsCount1 + 1;
	EndDo;
	
	If DeletableObjects.Count() > 0 Then
		For Each FullNameOfObjectToDelete In DeletableObjects Do
			DataToChangeMultilanguageAttributes.Objects.Delete(FullNameOfObjectToDelete);
		EndDo;
		WriteDataToChangeMultilingualAttributes(DataToChangeMultilanguageAttributes);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		
		TimeConsumingOperations.ReportProgress(99 , NStr("ru = 'Варианты отчетов';
														|en = 'Report options';"));
		
		ModuleReportsOptions = Common.CommonModule("ReportsOptions");
		Settings = ModuleReportsOptions.SettingsUpdateParameters();
		Settings.Deferred2 = True;
		ModuleReportsOptions.Refresh(Settings);
		ModuleReportsOptions.ResetInfillViews("ConfigurationCommonData");
	EndIf;
	
	TimeConsumingOperations.ReportProgress(100, "");
	
EndProcedure

Procedure HandleReferenceObjects(FullName, ObjectData, DataToChangeMultilanguageAttributes, FillParameters)
	
	LastRef = ?(ObjectData.ReferenceToLastProcessedObjects <> Undefined,
	ObjectData.ReferenceToLastProcessedObjects,
	Common.ObjectManagerByFullName(FullName).EmptyRef());
	
	RequestFieldLayout = "ObjectData.%1%2 AS %1%2";
	
	ValuesLanguageConstants = DataToChangeMultilanguageAttributes.SettingsChangesLanguages;
	MultilingualAttributes = ObjectData.LanguageFields;
	
	HaveDataPortion = True;
	
	ObjectContainsPMRepresentations = False;
	If FillParameters.Count() > 0 Then
		ObjectContainsPMRepresentations =  FillParameters.ObjectContainsPMRepresentations;
	EndIf;
	
	While HaveDataPortion Do

		QueryFields = New Array;

		For Each MultilingualProps In MultilingualAttributes Do

			QueryFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
				RequestFieldLayout, MultilingualProps, ""));
			QueryFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
				RequestFieldLayout, MultilingualProps, FirstLanguageSuffix()));
			QueryFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
				RequestFieldLayout, MultilingualProps, SecondLanguageSuffix()));

		EndDo;

		Query = New Query;
		QueryText =
		"SELECT TOP 1000
		|	ObjectData.Ref AS Ref,
		|	&ObjectField
		|FROM
		|	#ObjectData AS ObjectData
		|WHERE
		|	ObjectData.Ref > &Ref
		|
		|ORDER BY
		|	Ref";

		QueryText = StrReplace(QueryText, "&ObjectField", StrConcat(QueryFields, "," + Chars.LF));
		QueryText = StrReplace(QueryText, "#ObjectData", FullName);

		Query.Text = QueryText;
		Query.SetParameter("Ref", LastRef);
		
		// @skip-check query-in-loop - Batch processing of data
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then

			SelectionDetailRecords = QueryResult.Select();

			IsIncludesEditedPredefinedAttributes = 
				InfobaseUpdateInternal.IsIncludesEditedPredefinedAttributes(FullName);
			
			While SelectionDetailRecords.Next() Do
				
				PresentationOfObjectToChange = String(SelectionDetailRecords.Ref);
				
				BeginTransaction();
				Try

					Block = New DataLock;
					LockItem = Block.Add(FullName);
					LockItem.SetValue("Ref", SelectionDetailRecords.Ref);
					Block.Lock();

					ObjectToChange = SelectionDetailRecords.Ref.GetObject();
					If ObjectToChange = Undefined Then // the object may have been deleted in other sessions
						RollbackTransaction();
						Continue;
					EndIf;
					
					LockDataForEdit(SelectionDetailRecords.Ref);
					
					NewStringPchRepresentation = Undefined;
					
					EditedAttributes = Undefined;
					If IsIncludesEditedPredefinedAttributes And ValueIsFilled(ObjectToChange.EditedPredefinedAttributes) Then
						EditedAttributes = StrSplit(ObjectToChange.EditedPredefinedAttributes, ",", False);
					EndIf;
					
					For Each MultilingualProps In MultilingualAttributes Do
						
						// Save old values.
						AttributeValues = New Map;
						AttributeValues[ValuesLanguageConstants.MainLanguageOldValue] =  ObjectToChange[MultilingualProps];
						AttributeValues[ValuesLanguageConstants.AdditionalLanguage1OldValue] = ObjectToChange[MultilingualProps
							+ FirstLanguageSuffix()];
						AttributeValues[ValuesLanguageConstants.AdditionalLanguage2OldValue] = ObjectToChange[MultilingualProps
							+ SecondLanguageSuffix()];

						If EditedAttributes <> Undefined Then
							
							Substitutions_3 = New Map;
							If EditedAttributes.Find(MultilingualProps) <> Undefined Then
								Position = EditedAttributes.Find(MultilingualProps);
								Substitutions_3.Insert(Position, MultilingualProps + LanguageSuffix(ValuesLanguageConstants.MainLanguageOldValue));
							EndIf;
							If EditedAttributes.Find(MultilingualProps + FirstLanguageSuffix()) <> Undefined Then
								Position = EditedAttributes.Find(MultilingualProps + FirstLanguageSuffix());
								Substitutions_3.Insert(Position, MultilingualProps + LanguageSuffix(ValuesLanguageConstants.AdditionalLanguage1OldValue));
							EndIf;
							If EditedAttributes.Find(MultilingualProps + SecondLanguageSuffix()) <> Undefined Then 
								Position = EditedAttributes.Find(MultilingualProps + SecondLanguageSuffix());
								Substitutions_3.Insert(Position, MultilingualProps + LanguageSuffix(ValuesLanguageConstants.AdditionalLanguage2OldValue));
							EndIf;
							
							For Each Replacement In Substitutions_3 Do 
								EditedAttributes[Replacement.Key] = Replacement.Value;
							EndDo;

						EndIf;
							
						DefaultValue = ObjectToChange[MultilingualProps];
						If DataToChangeMultilanguageAttributes.MainLanguageChanged Then
							NewValue = AttributeValues[ValuesLanguageConstants.MainLanguageNewMeaning];
							FillPropsITCHSubmissions(FillParameters, MultilingualProps,
								ObjectToChange, NewValue, DefaultValue,
								ValuesLanguageConstants.MainLanguageNewMeaning);
								
							If ObjectContainsPMRepresentations Then
								Filter = New Structure("LanguageCode", ValuesLanguageConstants.MainLanguageNewMeaning);
								FoundRows = ObjectToChange.Presentations.FindRows(Filter);
								For Each FoundRow In FoundRows Do
									ObjectToChange.Presentations.Delete(FoundRow);
								EndDo;
								
								IsAttributePresentInTabularSection = FillParameters.ObjectAttributesToLocalize[MultilingualProps];
								
								If ValueIsFilled(ValuesLanguageConstants.MainLanguageOldValue) 
								   And IsAttributePresentInTabularSection Then
									
									If FillParameters.HierarchySupported 
										And ObjectToChange.IsFolder
										And Not FillParameters.PMViewUsedForGroups Then
										Continue;
									EndIf;
									
									Filter = New Structure("LanguageCode", ValuesLanguageConstants.MainLanguageOldValue);
									FoundRows = ObjectToChange.Presentations.FindRows(Filter);
									If FoundRows.Count() > 0 Then
										DataString1 = FoundRows[0];
									Else
										DataString1= ObjectToChange.Presentations.Add();
										DataString1.LanguageCode= ValuesLanguageConstants.MainLanguageOldValue;
									EndIf;
									DataString1[MultilingualProps] = AttributeValues[ValuesLanguageConstants.MainLanguageOldValue];
								EndIf;
								
							EndIf;
							
						EndIf;
						
						If DataToChangeMultilanguageAttributes.FirstAdditionalLanguageChanged Then
							NewValue = AttributeValues[ValuesLanguageConstants.AdditionalLanguage1NewValue];
							FillPropsITCHSubmissions(FillParameters, MultilingualProps, ObjectToChange, NewValue, DefaultValue,
								ValuesLanguageConstants.AdditionalLanguage1NewValue);
								
						EndIf;
						
						If DataToChangeMultilanguageAttributes.SecondAdditionalLanguageChanged Then
							NewValue = AttributeValues[ValuesLanguageConstants.AdditionalLanguage2NewValue];
							FillPropsITCHSubmissions(FillParameters, MultilingualProps, ObjectToChange, NewValue, DefaultValue,
								ValuesLanguageConstants.AdditionalLanguage2NewValue);
						EndIf;
						
						If NewStringPchRepresentation <> Undefined Then
							NewStringPchRepresentation[MultilingualProps] = AttributeValues[ValuesLanguageConstants.MainLanguageOldValue];
						EndIf;
						
					EndDo;
					
					If EditedAttributes <> Undefined Then
						ObjectToChange.EditedPredefinedAttributes = StrConcat(EditedAttributes, ",");
					EndIf;
					
					InfobaseUpdate.WriteObject(ObjectToChange);
					
					LastRef = SelectionDetailRecords.Ref;
					ObjectData.ReferenceToLastProcessedObjects = LastRef;
					
					WriteDataToChangeMultilingualAttributes(DataToChangeMultilanguageAttributes);
					
					CommitTransaction();
					
				Except
					RollbackTransaction();
					
					LastRef = SelectionDetailRecords.Ref;
					ObjectData.ReferenceToLastProcessedObjects = LastRef; 
					
					ErrorDescription     = ErrorInfo();
					ObjectMetadata = Metadata.FindByFullName(FullName);
					WriteLogEvent(EventLogEvent(), EventLogLevel.Error, 
						ObjectMetadata, PresentationOfObjectToChange,
						ErrorProcessing.DetailErrorDescription(ErrorDescription));
					
				EndTry;
			
			EndDo;
			
		Else
			HaveDataPortion = False;
			
			DataToChangeMultilanguageAttributes.Objects.Delete(FullName);
			WriteDataToChangeMultilingualAttributes(DataToChangeMultilanguageAttributes);
			
			Return;
		EndIf;

	EndDo;
		
EndProcedure

Procedure FillPropsITCHSubmissions(FillParameters, MultilingualProps, ObjectToChange,
	NewValue, DefaultValue, LanguageCode = "")
	
	FillValue = "";
	ThereFillingParameters  = FillParameters.Count() <> 0;
	ObjectContainsPMRepresentations = ?(ThereFillingParameters, FillParameters.ObjectContainsPMRepresentations,False);
	
	If NewValue <> Undefined Then
		FillValue = NewValue;
	ElsIf ObjectContainsPMRepresentations Then
		
		Filter = New Structure("LanguageCode", LanguageCode);
		FindRows = ObjectToChange.Presentations.FindRows(Filter);
		If FindRows.Count() > 0 Then
			FillValue = FindRows[0][MultilingualProps];
		EndIf;
		
	EndIf;
	
	If IsBlankString(FillValue) And ThereFillingParameters Then
		FillValue = PrimaryAttributeValue(FillParameters, MultilingualProps, ObjectToChange, LanguageCode);
	EndIf;
	
	FillValue = ?(ValueIsFilled(FillValue),
		FillValue, DefaultValue);
	
	If IsBlankString(FillValue)  Then
		Return;
	EndIf;
	
	LanguageSuffix = LanguageSuffix(LanguageCode);
	If ValueIsFilled(LanguageSuffix) Then
		ObjectToChange[MultilingualProps + LanguageSuffix] = FillValue;
	ElsIf StrCompare(Common.DefaultLanguageCode(), LanguageCode) = 0 Then
		ObjectToChange[MultilingualProps] = FillValue;
	EndIf;
	
	IsAttributePresentInTabularSection = ?(ThereFillingParameters, 
		FillParameters.ObjectAttributesToLocalize[MultilingualProps], Undefined);
	
	If IsBlankString(LanguageCode) 
		Or Not ObjectContainsPMRepresentations
		Or (FillParameters.HierarchySupported And ObjectToChange.IsFolder)
		Or IsAttributePresentInTabularSection <> True Then
			Return;
	EndIf;
	
	Filter = New Structure("LanguageCode", LanguageCode);
	FindRows = ObjectToChange.Presentations.FindRows(Filter);
	If FindRows.Count() > 0 Then
		
		StringCurrentLanguage = FindRows[0];
		
	Else
		
		StringCurrentLanguage = ObjectToChange.Presentations.Add();
		StringCurrentLanguage.LanguageCode = LanguageCode;
		
	EndIf;
	
	StringCurrentLanguage[MultilingualProps] = FillValue;
	
EndProcedure

Function PrimaryAttributeValue(FillParameters, MultilingualProps, ObjectToChange, LanguageCode)
	
	FillValue = "";
	
	If FillParameters.PredefinedData.Count() > 0 Then
	
		FillingData = Undefined;
		
		Settings = FillParameters.PredefinedItemsSettings;
		
		KeyAttributeName = Settings.OverriddenSettings.KeyAttributeName;
		ValueOfKeyProps = ObjectToChange[KeyAttributeName];
		If ValueIsFilled(ValueOfKeyProps) Then
			FillingData = FillParameters.PredefinedData.Find(ValueOfKeyProps, KeyAttributeName);
			
		ElsIf Settings.IsColumnNamePredefinedData Then
			ValueOfKeyProps  = ObjectToChange["PredefinedDataName"];
			FillingData = FillParameters.PredefinedData.Find(ValueOfKeyProps, "PredefinedDataName");
		EndIf;
		
		If TypeOf(FillingData) = Type("ValueTableRow") Then
			
			FillValue = ?(ValueIsFilled(LanguageCode), FillingData[MultilingualProps + "_" + LanguageCode],
				FillingData[MultilingualProps]);
			
		EndIf;
		
	EndIf;
	
	Return FillValue;
	
EndFunction

Procedure WriteDataToChangeMultilingualAttributes(DataToChangeMultilanguageAttributes)
	
	SetPrivilegedMode(True);
	If DataToChangeMultilanguageAttributes.Objects.Count() = 0 Then
		PackedValue = Undefined;
	Else
		PackedValue = New ValueStorage(DataToChangeMultilanguageAttributes);
	EndIf;
	
	Constants.DataToChangeMultilanguageAttributes.Set(PackedValue);

EndProcedure

Procedure ChangeLanguageInSubRegistersDetails(MetadataObject, ObjectData, DataToChangeMultilanguageAttributes, FillParameters, Periodic3 = False)
	
	FullName = MetadataObject.FullName(); 
	RegisterManager = Common.ObjectManagerByFullName(FullName);
	
	MultilingualAttributes = ObjectData.LanguageFields;
	ValuesLanguageConstants = DataToChangeMultilanguageAttributes.SettingsChangesLanguages;
	
	TableName = StrReplace(FullName, ".", "");
	
	QueryText = "SELECT DISTINCT TOP 1000
	|	TableName.Recorder AS RecorderAttributeRef
	|FROM
	|	&MetadataObject AS TableName
	|WHERE
	|	TableName.Recorder > &Recorder
	|ORDER BY
	|	TableName.Recorder";

	QueryText = StrReplace(QueryText, "&MetadataObject", FullName);
	QueryText = StrReplace(QueryText, "TableName", TableName);
	
	Query = New Query(QueryText);
	If ObjectData.ReferenceToLastProcessedObjects = Undefined Then
		Query.SetParameter("Recorder", Undefined);
	Else
		Filter = ObjectData.ReferenceToLastProcessedObjects;
		Query.SetParameter("Recorder", Filter["Recorder"]);
	EndIf;
	
	Result = Query.Execute().Unload();
	
	While Result.Count() > 0 Do
		
		For Each ResultString1 In Result Do
			
			Block = New DataLock;
			LockItem = Block.Add(FullName + "." + "RecordSet");
			
			CurrentRecordSet = RegisterManager.CreateRecordSet();
			CurrentRecordSet.Filter.Recorder.Set(ResultString1.RecorderAttributeRef);
			
			LockItem.SetValue("Recorder", ResultString1.RecorderAttributeRef);
			
			BeginTransaction();
				Try
					
					Block.Lock();
					CurrentRecordSet.Read();
					
					If CurrentRecordSet.Count() = 0 Then
						RollbackTransaction();
						Continue;
					EndIf;
					
					For Each ModifiableRecord In CurrentRecordSet Do
						
						For Each MultilingualProps In MultilingualAttributes Do
							
							// Save old values.
							AttributeValues = New Map;
							AttributeValues[ValuesLanguageConstants.MainLanguageOldValue] =  ModifiableRecord[MultilingualProps];
							AttributeValues[ValuesLanguageConstants.AdditionalLanguage1OldValue] = ModifiableRecord[MultilingualProps + FirstLanguageSuffix()];
							AttributeValues[ValuesLanguageConstants.AdditionalLanguage2OldValue] = ModifiableRecord[MultilingualProps + SecondLanguageSuffix()];
							
							DefaultValue = String(ModifiableRecord[MultilingualProps]);
							If DataToChangeMultilanguageAttributes.MainLanguageChanged Then
								NewValue = AttributeValues[ValuesLanguageConstants.MainLanguageNewMeaning];
								FillPropsITCHSubmissions(FillParameters, MultilingualProps, ModifiableRecord, NewValue, DefaultValue,
									ValuesLanguageConstants.MainLanguageNewMeaning);
							EndIf;
							
							If DataToChangeMultilanguageAttributes.FirstAdditionalLanguageChanged Then
								NewValue = AttributeValues[ValuesLanguageConstants.AdditionalLanguage1NewValue];
								FillPropsITCHSubmissions(FillParameters, MultilingualProps, ModifiableRecord, NewValue, DefaultValue,
									ValuesLanguageConstants.AdditionalLanguage1NewValue);
							EndIf;
							
							If DataToChangeMultilanguageAttributes.SecondAdditionalLanguageChanged Then
								NewValue = AttributeValues[ValuesLanguageConstants.AdditionalLanguage2NewValue];
								FillPropsITCHSubmissions(FillParameters, MultilingualProps, ModifiableRecord, NewValue, DefaultValue,
									ValuesLanguageConstants.AdditionalLanguage2NewValue);
							EndIf;
							
						EndDo;
						
					EndDo;
					
					InfobaseUpdate.WriteData(CurrentRecordSet);
					
					Filter = New Structure();
					Filter.Insert("Recorder", ResultString1.RecorderAttributeRef);
					
					ObjectData.ReferenceToLastProcessedObjects = Filter;
					
					WriteDataToChangeMultilingualAttributes(DataToChangeMultilanguageAttributes);
					
					CommitTransaction();
					
				Except
					RollbackTransaction();
					
					Filter = New Structure();
					Filter.Insert("Recorder", ResultString1.RecorderAttributeRef);
					
					ObjectData.ReferenceToLastProcessedObjects = Filter;
					
					ErrorDescription     = ErrorInfo();
					ObjectMetadata = Metadata.FindByFullName(FullName);
					WriteLogEvent(EventLogEvent(), EventLogLevel.Error,
						ObjectMetadata,, ErrorProcessing.DetailErrorDescription(ErrorDescription));
					
				EndTry;
			
		EndDo;
		
		Query.SetParameter("Recorder", ResultString1.RecorderAttributeRef);
		
		// @skip-check query-in-loop - Batch processing of data
		Result = Query.Execute().Unload();
		
	EndDo;
	
	DataToChangeMultilanguageAttributes.Objects.Delete(FullName);
	WriteDataToChangeMultilingualAttributes(DataToChangeMultilanguageAttributes);
	
EndProcedure

Procedure ChangeLanguageIncaseIndependentDetails(MetadataObject, ObjectData, DataToChangeMultilanguageAttributes, FillParameters, Periodic3 = False)
	
	FullName = MetadataObject.FullName(); 
	RegisterManager = Common.ObjectManagerByFullName(FullName);
	
	MultilingualAttributes = ObjectData.LanguageFields;
	ValuesLanguageConstants = DataToChangeMultilanguageAttributes.SettingsChangesLanguages;
	
	TableName = StrReplace(FullName, ".", "");
	SelectionFieldTemplate = "TableName.[FieldName] AS [FieldName]DimensionRef";
	
	Dimensions          = MetadataObject.Dimensions;// Array of MetadataObjectDimension
	
	SelectionFieldSet        = New Array;
	ConditionSet             = New Array;
	OrderFieldSet = New Array;
	
	If Periodic3 Then
		OrderFieldSet.Add(TableName + "." + "Period");
		ConditionSet.Add("TableName.Period > &Period");
		SelectionFieldSet.Add("TableName.Period AS Period");
	EndIf;
	
	For Each Dimension In Dimensions Do
		SetAdditionalConditions = New Array;
		
		If ConditionSet.Count() > 0 Then
			SetAdditionalConditions.Add(StrReplace(ConditionSet.Get(ConditionSet.UBound()), ">", "="));
		EndIf;
		SetAdditionalConditions.Add(TableName + "." + Dimension.Name + " > &" + Dimension.Name);
		
		ConditionSet.Add(StrConcat(SetAdditionalConditions, " And "));
		
		OrderFieldSet.Add(TableName + "." + Dimension.Name);
		SelectionFieldSet.Add(StrReplace(SelectionFieldTemplate, "[FieldName]", Dimension.Name));
		
	EndDo;
	
	ConditionByDimensions = StrConcat(ConditionSet, " OR ");
	OrderFields  = StrConcat(OrderFieldSet, ", " + Chars.LF);
	SelectionFields1         = StrConcat(SelectionFieldSet, ", " + Chars.LF);
	
	QueryText =
	"SELECT TOP 1000
	|	&SelectionFields1 AS SelectionFields1
	|FROM
	|	&MetadataObject AS TableName
	|WHERE
	|	&Condition
	|
	|ORDER BY
	|	&OrderFields";
	
	QueryText = StrReplace(QueryText, "&Condition", ConditionByDimensions);

	QueryText = StrReplace(QueryText, "&OrderFields", OrderFields);
	QueryText = StrReplace(QueryText, "&SelectionFields1 AS SelectionFields1", SelectionFields1);
	QueryText = StrReplace(QueryText, "&MetadataObject", FullName);
	QueryText = StrReplace(QueryText, "TableName", TableName);
		
	Query = New Query(QueryText);
	If ObjectData.ReferenceToLastProcessedObjects = Undefined Then
		
		If Periodic3 Then
			Query.SetParameter("Period", Date("00010101"));
			
		EndIf;
		For Each Dimension In Dimensions Do
			Query.SetParameter(Dimension.Name, Undefined);
		EndDo;
		
	Else
		Filter = ObjectData.ReferenceToLastProcessedObjects;
		
		For Each Dimension In Dimensions Do
			Query.SetParameter(Dimension.Name, Filter[Dimension.Name]);
		EndDo;
		
		If Periodic3 Then
			Query.SetParameter("Period", Filter["Period"]);
		EndIf;
	
	EndIf;
	
	Result = Query.Execute().Unload();
	
	While Result.Count() > 0 Do
		
		For Each ResultString1 In Result Do
			
			Block = New DataLock;
			LockItem = Block.Add(FullName);
		
			
			CurrentRecordSet = RegisterManager.CreateRecordSet();
			CurrentSetFilter = CurrentRecordSet.Filter;
			
			If Periodic3 Then
				LockItem.SetValue("Period", ResultString1["Period"]);
				CurrentSetFilter.Period.Set(ResultString1["Period"]);
			EndIf;
			
			For Each Dimension In Dimensions Do
				
				DimensionName      = Dimension.Name;
				DimensionValue = ResultString1[DimensionName + "DimensionRef"];
				If Not ValueIsFilled(DimensionValue) Then
					Continue;
				EndIf;
				
				FilterByDimension = CurrentSetFilter[DimensionName];// FilterItem
				FilterByDimension.Set(DimensionValue);
				
				LockItem.SetValue(DimensionName, DimensionValue);
				
			EndDo;
			
			RecordKeyDetails = Common.ValueTableRowToStructure(ResultString1);
			RecordKey = RegisterManager.CreateRecordKey(RecordKeyDetails);
			
			BeginTransaction();
				Try
					
					Block.Lock();
					CurrentRecordSet.Read();
					LockDataForEdit(RecordKey);
					
					If CurrentRecordSet.Count() = 0 Then
						RollbackTransaction();
						Continue;
					EndIf;
					
					ModifiableRecord = CurrentRecordSet.Get(0);
					
					For Each MultilingualProps In MultilingualAttributes Do
						
						// Save old values.
						AttributeValues = New Map;
						AttributeValues[ValuesLanguageConstants.MainLanguageOldValue] =  ModifiableRecord[MultilingualProps];
						AttributeValues[ValuesLanguageConstants.AdditionalLanguage1OldValue] = ModifiableRecord[MultilingualProps + FirstLanguageSuffix()];
						AttributeValues[ValuesLanguageConstants.AdditionalLanguage2OldValue] = ModifiableRecord[MultilingualProps + SecondLanguageSuffix()];
							
						DefaultValue = ModifiableRecord[MultilingualProps];
						If DataToChangeMultilanguageAttributes.MainLanguageChanged Then
							NewValue = AttributeValues[ValuesLanguageConstants.MainLanguageNewMeaning];
							FillPropsITCHSubmissions(FillParameters, MultilingualProps, ModifiableRecord, NewValue, DefaultValue,
								ValuesLanguageConstants.MainLanguageNewMeaning);
						EndIf;
						
						If DataToChangeMultilanguageAttributes.FirstAdditionalLanguageChanged Then
							NewValue = AttributeValues[ValuesLanguageConstants.AdditionalLanguage1NewValue];
							FillPropsITCHSubmissions(FillParameters, MultilingualProps, ModifiableRecord, NewValue, DefaultValue,
								ValuesLanguageConstants.AdditionalLanguage1NewValue);
						EndIf;
						
						If DataToChangeMultilanguageAttributes.SecondAdditionalLanguageChanged Then
							NewValue = AttributeValues[ValuesLanguageConstants.AdditionalLanguage2NewValue];
							FillPropsITCHSubmissions(FillParameters, MultilingualProps, ModifiableRecord, NewValue, DefaultValue,
								ValuesLanguageConstants.AdditionalLanguage2NewValue);
						EndIf;
						
					EndDo;
						
					InfobaseUpdate.WriteData(CurrentRecordSet);
					
					Filter = New Structure();
					For Each Dimension In Dimensions Do
						Filter.Insert(Dimension.Name, ResultString1[Dimension.Name + "DimensionRef"]);
					EndDo;
					
					If Periodic3 Then
						Filter.Insert("Period", ResultString1["Period"]);
					EndIf;
					
					ObjectData.ReferenceToLastProcessedObjects = Filter;

					WriteDataToChangeMultilingualAttributes(DataToChangeMultilanguageAttributes);
					
					CommitTransaction();
					
				Except
					RollbackTransaction();
					
					Filter = New Structure();
					For Each Dimension In Dimensions Do
						Filter.Insert(Dimension.Name, ResultString1[Dimension.Name + "DimensionRef"]);
					EndDo;
					
					If Periodic3 Then
						Filter.Insert("Period", ResultString1["Period"]);
					EndIf;
					
					ObjectData.ReferenceToLastProcessedObjects = Filter;
					
					ErrorDescription     = ErrorInfo();
					ObjectMetadata = Metadata.FindByFullName(FullName);
					WriteLogEvent(EventLogEvent(), EventLogLevel.Error, 
						ObjectMetadata,, ErrorProcessing.DetailErrorDescription(ErrorDescription));
					
				EndTry;
			
		EndDo;
		
		If Periodic3 Then
			Query.SetParameter("Period", ResultString1["Period"]);
		EndIf;
		
		For Each Dimension In Dimensions Do
			Query.SetParameter(Dimension.Name, ResultString1[Dimension.Name + "DimensionRef"]);
		EndDo;
		
		// @skip-check query-in-loop - Batch processing of data
		Result = Query.Execute().Unload();
		
	EndDo;
	
	DataToChangeMultilanguageAttributes.Objects.Delete(FullName);
	WriteDataToChangeMultilingualAttributes(DataToChangeMultilanguageAttributes);
	
EndProcedure

Function FirstLanguageSuffix() Export
	Return "Language1";
EndFunction

Function SecondLanguageSuffix() Export
	Return "Language2";
EndFunction

Function ObjectsWithInitialFilling(DataVariant)
	
	ObjectsWithPredefinedItems = InfobaseUpdateInternal.ObjectsWithInitialFilling();
	
	If Not Common.DataSeparationEnabled()
		Or Not Common.SubsystemExists("CloudTechnology.Core") Then
		Return ObjectsWithPredefinedItems;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	ObjectsWithPredefinedItemsForDataVariant = New Map(ObjectsWithPredefinedItems);
	
	For Each ObjectWithPredefinedItem In ObjectsWithPredefinedItems Do
		
		IsSeparatedMetadataObject = ModuleSaaSOperations.IsSeparatedMetadataObject(
			ObjectWithPredefinedItem.Key);
		If DataVariant = "Overall" And IsSeparatedMetadataObject Then
			ObjectsWithPredefinedItemsForDataVariant.Delete(ObjectWithPredefinedItem.Key);
		ElsIf Not IsSeparatedMetadataObject Then
			ObjectsWithPredefinedItemsForDataVariant.Delete(ObjectWithPredefinedItem.Key);
		EndIf;
		
	EndDo;
	
	Return ObjectsWithPredefinedItemsForDataVariant;
	
EndFunction

// Name of the event as it appears in the event log.
// 
// Returns:
//  String - Log event.
//
Function EventLogEvent()

	Return NStr("ru = 'Мультиязычность';
				|en = 'National language support';", Common.DefaultLanguageCode());

EndFunction

#EndRegion

#EndRegion