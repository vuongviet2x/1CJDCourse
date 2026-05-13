///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "OnlineUserSupport.PickName" subsystem.
// CommonModule.PickName.
//
// Server procedures for name classifier management:
//  - Return classifier entries by the passed search parameters
//  - Return classifier IDs
//  - Procedures for importing, adding, and updating classifier entries
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the search result. Or an empty array if nothing is found.
//
// Parameters:
//  SearchMode_ - String - Valid search mode values are::
//    "LastName", "Name" (meaning, first name), "MiddleName", "LastFirstName".
//  FullNameData - Structure, Undefined - Describes the full name passed for searching.
//    The structure is used to determine the gender if "Gender" is not specified:
//    * LastName - String, Undefined - Person's last name (if "SearchMode_" is set to "LastName"). Optional.
//      
//    * Name - String, Undefined - Person's first name (if "SearchMode_" is set to "Name"). Optional.
//      
//    * MiddleName - String, Undefined - Person's middle name (if "SearchMode_" is set to "MiddleName"). Optional.
//      
//    * Presentation - String - Person's full name (if "SearchMode_" is set to "LastFirstName"). Optional.
//      
//  Gender - Number - The person's gender that will be used in the search. Valid values are::
//    0 - None (will be auto-determined from "FullNameData"; 1 - Male; 2 - Female; 3 - Either one is possible.
//  SelectionSize - Number - Determines the dataset size.
// Returns:
//   Array of String - Search data sorted by frequency.
//
Function Pick(SearchMode_, FullNameData = Undefined, Gender = 0, SelectionSize = 10) Export
	
	DataKind           = SearchMode_;
	NameDataForSearch  = NewNameDataForSearch(FullNameData);
	PresentationData = New Array;
	
	If DataKind = "LASTFIRSTNAME" Then
		PrepareSearchStringFromPresentation(NameDataForSearch, PresentationData, DataKind);
	EndIf;
	
	If Gender = 0 Then
		Gender = DetermineGenderFromEnteredData(DataKind, NameDataForSearch);
	EndIf;
	
	If FullNameData = Undefined Then
		TextForAutoSelection = "";
	Else
		TextForAutoSelection = NameDataForSearch[DataKind];
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	NamesClassifier.Value AS Value
	|FROM
	|	InformationRegister.NamesClassifier AS NamesClassifier
	|WHERE
	|	NamesClassifier.DataKind = &DataKind
	|	AND NamesClassifier.Value LIKE &StartOfText
	|	AND &GenderCondition
	|
	|ORDER BY
	|	NamesClassifier.DisplayPriority DESC";

	Query.Text = StrReplace(
		Query.Text,
		"SELECT",
		StringFunctionsClientServer.SubstituteParametersToString("SELECT TOP %1", SelectionSize));
		
	If Gender = 3 Then
		Query.Text = StrReplace(Query.Text, "&GenderCondition", "TRUE");
	Else
		Query.Text = StrReplace(
			Query.Text,
			"&GenderCondition",
			"(NamesClassifier.Gender = &Gender OR NamesClassifier.Gender = 3)");
		Query.SetParameter("Gender", Gender);
	EndIf;
	
	Query.SetParameter("StartOfText", TextForAutoSelection + "%");
	Query.SetParameter("DataKind",    Enums.NameDataKind[DataKind]);
	
	Selection = Query.Execute().Select();
	
	SearchData_ = New Array;
	
	While Selection.Next() Do
		
		If SearchMode_ = "LASTFIRSTNAME" Then
			PresentationData[PresentationData.Count()-1] = Selection.Value;
			SearchData_.Add(StrConcat(PresentationData, " "));
		Else
			SearchData_.Add(Selection.Value);
		EndIf;
		
	EndDo;
	
	Return SearchData_;
	
EndFunction

// Returns the auto-determined person's gender.
//
// Parameters:
//  FullNameData - Structure, Undefined - Optional.
//  * Name - String - Person's first name (if "SearchMode_" is set to "Name"). Optional.
//    * MiddleName - String - Person's middle name (if "SearchMode_" is "MiddleName"). Optional.
//                                        * Presentation - String - Person's full name (if "SearchMode_" is "LastFirstName"). Optional.
//      Optional.
//    * Name - String - Person's first name (if "SearchMode_" is set to "Name"). Optional.
//      * MiddleName - String - Person's middle name (if "SearchMode_" is "MiddleName"). Optional.
//    * Presentation - String - Person's full name (if "SearchMode_" is "LastFirstName"). Optional.
//      
//    
//      
//  Returns:
//    Number - Valid values are::
//      1 - Male; 2 - Female; 3 - Either one is possible.
//
Function DetermineGender(FullNameData) Export
	
	NameDataForSearch = NewNameDataForSearch(FullNameData);
	
	If ValueIsFilled(NameDataForSearch.Presentation) Then
		PrepareSearchStringFromPresentation(NameDataForSearch);
	EndIf;
	
	Query = New Query;
	
	Query.Text = 
	"SELECT
	|	GenderFromLastName.Gender AS Gender
	|INTO GenderData
	|FROM
	|	InformationRegister.NamesClassifier AS GenderFromLastName
	|WHERE
	|	GenderFromLastName.DataKind = VALUE(Enum.NameDataKind.LastName)
	|	AND GenderFromLastName.Value = &LastName
	|	AND (GenderFromLastName.Gender = 1
	|			OR GenderFromLastName.Gender = 2)
	|
	|UNION ALL
	|
	|SELECT
	|	GenderFromFirstName.Gender
	|FROM
	|	InformationRegister.NamesClassifier AS GenderFromFirstName
	|WHERE
	|	GenderFromFirstName.DataKind = VALUE(Enum.NameDataKind.NAME)
	|	AND GenderFromFirstName.Value = &Name
	|	AND (GenderFromFirstName.Gender = 1
	|			OR GenderFromFirstName.Gender = 2)
	|
	|UNION ALL
	|
	|SELECT
	|	GenderFromMiddleName.Gender
	|FROM
	|	InformationRegister.NamesClassifier AS GenderFromMiddleName
	|WHERE
	|	GenderFromMiddleName.DataKind = VALUE(Enum.NameDataKind.MiddleName)
	|	AND GenderFromMiddleName.Value = &MiddleName
	|	AND (GenderFromMiddleName.Gender = 1
	|			OR GenderFromMiddleName.Gender = 2)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GenderData.Gender AS Gender
	|FROM
	|	GenderData AS GenderData";
	
	Query.SetParameter("LastName",  NameDataForSearch.LastName);
	Query.SetParameter("Name",      NameDataForSearch.Name);
	Query.SetParameter("MiddleName", NameDataForSearch.MiddleName);

	Selection = Query.Execute().Select();
	
	If Selection.Count() = 1 Then
		Selection.Next();
		Return Selection.Gender;
	Else
		Return 3;
	EndIf;
	
EndFunction

// Searches for classifier entries by the passed name components.
//
// Parameters:
//  NameComponents - Array of String - Data to be searched.
//  CompleteCoincidence - Boolean - If set to "True", the "Equal" operator is used.
//   If set to "False", the "Like" operator is used.
//   The function supports a wildcard character to search by substrings. For example, "Tom%".
//   
//
//  Returns:
//    Structure - Search result:
//    * LastNames - Array of Structure - Found last names:
//      ** Value - String - Found value.
//      ** DisplayPriority - Number - Value priority. Optional.
//      
//    * Names - Array of Structure - Found first names:
//      ** Value - String - Found value.
//      ** DisplayPriority - Number - Value priority.
//    * MiddleNames - Array of Structure - Found middle names:
//      ** Value - String - Found value.
//
// Example:
//	NameComponents = New Array;
//	NameComponents.Add("Tom%");
//	Result = PickName.FindName(NameComponents, False);
//
Function FindName(NameComponents, CompleteCoincidence = True) Export
	
	Result = New Structure;
	Result.Insert("LastNames", New Array);
	Result.Insert("Names", New Array);
	Result.Insert("MiddleNames", New Array);
	
	If NameComponents.Count() = 0 Then
		Return Result;
	EndIf;
	
	NameComponentsQuery = New ValueTable;
	NameComponentsQuery.Columns.Add("Value", Common.StringTypeDetails(100));
	For Each NameComponent In NameComponents Do
		TableRow = NameComponentsQuery.Add();
		TableRow.Value = NameComponent;
	EndDo;
	
	Query = New Query;
	Query.Text =
		"SELECT DISTINCT
		|	NameComponentsQuery.Value AS Value
		|INTO TT_NameComponents
		|FROM
		|	&NameComponentsQuery AS NameComponentsQuery
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NamesClassifier.DataKind AS DataKind,
		|	NamesClassifier.Value AS Value,
		|	NamesClassifier.DisplayPriority AS DisplayPriority
		|FROM
		|	InformationRegister.NamesClassifier AS NamesClassifier
		|		INNER JOIN TT_NameComponents AS TT_NameComponents
		|		ON NamesClassifier.Value %Template%";
	
	Query.Text = StrReplace(
		Query.Text,
		"%Template%",
		?(CompleteCoincidence,
			"= TT_NameComponents.Value",
			"LIKE TT_NameComponents.Value"));
	
	Query.SetParameter("NameComponentsQuery", NameComponentsQuery);
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		If SelectionDetailRecords.DataKind = Enums.NameDataKind.LastName Then
			AddToSearchResult(
					Result.LastNames,
					SelectionDetailRecords.Value,
					SelectionDetailRecords.DisplayPriority);
		ElsIf SelectionDetailRecords.DataKind = Enums.NameDataKind.Name Then
			AddToSearchResult(
					Result.Names,
					SelectionDetailRecords.Value,
					SelectionDetailRecords.DisplayPriority);
		ElsIf SelectionDetailRecords.DataKind = Enums.NameDataKind.MiddleName Then
			AddToSearchResult(
				Result.MiddleNames,
				SelectionDetailRecords.Value,
				SelectionDetailRecords.DisplayPriority);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Internal

// See ClassifiersOperationsOverridable.OnAddClassifiers.
//
Procedure OnAddClassifiers(Classifiers) Export
	
	Specifier = ClassifiersOperations.ClassifierDetails();
	Specifier.Description           = NStr("ru = 'Классификатор ФИО';
											|en = '""Name"" classifier';");
	Specifier.Id          = IDInClassifiersService();
	Specifier.AutoUpdate = True;
	Specifier.SharedData            = True;
	
	Classifiers.Add(Specifier);
	
EndProcedure

// See ClassifiersOperationsOverridable.OnImportClassifier.
//
Procedure OnImportClassifier(Id, Version, Address, Processed) Export
	
	If Id <> IDInClassifiersService() Then
		Return;
	EndIf;
	
	PathToFile = GetTempFileName();
	BinaryData = GetFromTempStorage(Address);
	BinaryData.Write(PathToFile);
	
	Try
		
		JSONReader = New JSONReader;
		JSONReader.OpenFile(PathToFile);
		ClassifierData = ReadJSON(JSONReader);
		JSONReader.Close();
		DeleteFiles(PathToFile);
		
	Except
		
		DeleteFiles(PathToFile);
		WriteInformationToEventLog(
			NStr("ru = 'Некорректный формат файла классификатора, обработка прервана';
				|en = 'Invalid classifier file format. Processing aborted';"),
			True,
			Metadata.InformationRegisters.RNCEA2CapValues);
			
		Return;
		
	EndTry;
	
	IsValidDataFormat = IsClassifierStructureValid(ClassifierData);
	
	If IsValidDataFormat Then
		ProcessClassifierData(ClassifierData, Processed);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Returns the auto-determined person's gender.
//
// Parameters:
//  SearchMode_ - String - Valid search mode values are::
//    "LastName", "Name" (meaning, first name), "MiddleName".
//  EnteredData - Structure - Data of the last name used in the search.
//    * LastName - String, Undefined - Person's last name (if the SearchMode is set to "LastName").
//    Data of the last name used in the search.
//    * LastName - String, Undefined - Person's last name (if the SearchMode is set to "LastName").
//
//  Returns:
//    Number - Valid values are::
//      1 - Male; 2 - Female; 3 - Either one is possible.
//
Function DetermineGenderFromEnteredData(SearchMode_, EnteredData)
	
	If (SearchMode_ = "LastName" Or IsBlankString(EnteredData.LastName))
		And (SearchMode_ = "Name" Or IsBlankString(EnteredData.Name))
		And (SearchMode_ = "MiddleName" Or IsBlankString(EnteredData.MiddleName)) Then
		Return 3;
	EndIf;
	
	FullNameData = New Structure;
	FullNameData.Insert("LastName",  ?(SearchMode_ = "LastName", "", EnteredData.LastName));
	FullNameData.Insert("Name",      ?(SearchMode_ = "Name", "", EnteredData.Name));
	FullNameData.Insert("MiddleName", ?(SearchMode_ = "MiddleName", "", EnteredData.MiddleName));
	
	Return DetermineGender(FullNameData);
	
EndFunction

// Validates the passed classifier data structure.
//
// Parameters:
//  ClassifierData - Structure - Classifier data structure.
//
// Returns:
//  Boolean - "True" is the structure is valid.
//
Function IsClassifierStructureValid(ClassifierData)
	
	If Not ValueIsFilled(ClassifierData)
		Or TypeOf(ClassifierData) <> Type("Structure") Then
		
		WriteInformationToEventLog(
			NStr("ru = 'Отсутствуют данные или данные не являются структурой';
				|en = 'Data is either not a structure or missing';"),
			True,
			Metadata.InformationRegisters.NamesClassifier);
			
		Return False;
	
	// ACC:1415-off
	// Exception: Classifier files are provided from external sources.
	
	ElsIf Not ClassifierData.Property("version")
		Or TypeOf(ClassifierData.version) <> Type("Number") Then
		
		WriteInformationToEventLog(
			NStr("ru = 'Отсутствует или неправильно заполнено свойство ""version""';
				|en = 'Property ""version"" is missing or invalid';"),
			True,
			Metadata.InformationRegisters.NamesClassifier);
			
		Return False;
		
	ElsIf Not ClassifierData.Property("classifierData")
		Or TypeOf(ClassifierData.classifierData) <> Type("Structure") Then
		
		WriteInformationToEventLog(
			NStr("ru = 'Отсутствует или неправильно заполнено свойство ""classifierData""';
				|en = 'Property ""classifierData"" is missing or invalid';"),
			True,
			Metadata.InformationRegisters.NamesClassifier);
			
		Return False;
		
	ElsIf Not ClassifierData.classifierData.Property("names")
		Or TypeOf(ClassifierData.classifierData.names) <> Type("Array") Then
		
		WriteInformationToEventLog(
			NStr("ru = 'Отсутствует или неправильно заполнено свойство ""names""';
				|en = 'Property ""names"" is missing or invalid';"),
			True,
			Metadata.InformationRegisters.NamesClassifier);
			
		Return False;
		
	ElsIf Not ClassifierData.classifierData.Property("surnames")
		Or TypeOf(ClassifierData.classifierData.surnames) <> Type("Array") Then
		
		WriteInformationToEventLog(
			NStr("ru = 'Отсутствует или неправильно заполнено свойство ""surnames""';
				|en = 'Property ""surnames"" is missing or invalid';"),
			True,
			Metadata.InformationRegisters.NamesClassifier);
			
		Return False;
		
	ElsIf Not ClassifierData.classifierData.Property("secondNames")
		Or TypeOf(ClassifierData.classifierData.secondNames) <> Type("Array") Then
		
		WriteInformationToEventLog(
			NStr("ru = 'Отсутствует или неправильно заполнено свойство ""secondNames""';
				|en = 'Property ""secondNames"" is missing or invalid';"),
			True,
			Metadata.InformationRegisters.NamesClassifier);
			
		Return False;
		
	// ACC:1415-on
	
	Else
		Return True;
	EndIf;
	
EndFunction

// Parses the passed structure and writes classifier data.
// If succeeded, "Processed" is set to "True"
//
// Parameters:
//  ClassifierData - Structure - Classifier data structure.
//  Processed - Boolean - Flag indicating if data is successfully processed.
//
Procedure ProcessClassifierData(ClassifierData, Processed)
	
	DataTable = New ValueTable;
	DataTable.Columns.Add("DataKind",            New TypeDescription("EnumRef.NameDataKind"));
	DataTable.Columns.Add("Value",             New TypeDescription("String", , New StringQualifiers(200)));
	DataTable.Columns.Add("Gender",                  New TypeDescription("Number"));
	DataTable.Columns.Add("DisplayPriority", New TypeDescription("Number"));
	
	ProcessClassifierDataKind(
		Enums.NameDataKind.Name,
		ClassifierData.classifierData.names,
		DataTable);
	
	ProcessClassifierDataKind(
		Enums.NameDataKind.MiddleName,
		ClassifierData.classifierData.surnames,
		DataTable);
	
	ProcessClassifierDataKind(
		Enums.NameDataKind.LastName,
		ClassifierData.classifierData.secondNames,
		DataTable);
	
	SetPrivilegedMode(True);
	
	Set = InformationRegisters.NamesClassifier.CreateRecordSet();
	Set.Load(DataTable);
	Set.Write();
	
	Processed = True;
	
EndProcedure

// Populates a table of data kinds with classifier data.
//
// Parameters:
//  DataKind - EnumRef.NameDataKind - Data kind  being processed.
//  ClassifierDataByKind - Structure - Classifier data by the data kind being processed.
//  DataTable - ValueTable - Contains data prepared for adding to the register.
//
Procedure ProcessClassifierDataKind(DataKind, ClassifierDataByKind, DataTable)
	
	For Each Item In ClassifierDataByKind Do
		
		NwRw = DataTable.Add();
		NwRw.DataKind            = DataKind;
		NwRw.Value             = Item["value"];
		NwRw.Gender                  = Item["sex"];
		NwRw.DisplayPriority = Item["priority"];
		
	EndDo;
	
EndProcedure

// Adds an entry to the event log.
//
// Parameters:
//  ErrorMessage - String - Log entry comment.
//  Error - Boolean - If set to "True", the entry level is set to "Error".
//  MetadataObject - MetadataObject - Metadata object, for which an error is registered.
//
Procedure WriteInformationToEventLog(
		ErrorMessage,
		Error = True,
		MetadataObject = Undefined) Export
	
	ELLevel = ?(Error, EventLogLevel.Error, EventLogLevel.Information);
	
	WriteLogEvent(
		EventLogEventName(),
		ELLevel,
		MetadataObject,
		,
		Left(ErrorMessage, 5120));
	
EndProcedure

// Returns an event name for the event log.
//
// Returns:
//  String - Event name.
//
Function EventLogEventName()
	
	Return NStr("ru = 'Подбор ФИО';
				|en = 'Pick name';",
		Common.DefaultLanguageCode());
	
EndFunction

// Generates an id for the name picking classifier.
//
// Returns:
//  String - Classifier id.
//
Function IDInClassifiersService()

	Return "FullNameData";

EndFunction

// Generates a string that starts with a capital letter.
//
// Parameters:
//  StringForConversion - String - Source string.
//
// Returns:
//  String - Modified string.
//
Function CapitalLetter(StringForConversion)
	
	Return Upper(Left(StringForConversion, 1)) + Mid(Lower(StringForConversion), 2);
	
EndFunction

// Prepares search data by the passed presentation.
//
// Parameters:
//  NameDataForSearch - Structure, Undefined - * Name - String - Person's first name (if "SearchMode_" is set to "Name").
//    * MiddleName - String - Person's middle name (if "SearchMode_" is "MiddleName").
//                                                 * Presentation - String - Person's full name (if "SearchMode_" is "LastFirstName").
//    * Name - String - Person's first name (if "SearchMode_" is set to "Name").
//    * MiddleName - String - Person's middle name (if "SearchMode_" is "MiddleName").
//    * Presentation - String - Person's full name (if "SearchMode_" is "LastFirstName").
//  PresentationData - Array of String - Presentation of the split name.
//  DataKind - String - ID of the searched data type.
//
Procedure PrepareSearchStringFromPresentation(
		NameDataForSearch,
		PresentationData = Undefined,
		DataKind = Undefined)
	
	PresentationData = StrSplit(NameDataForSearch.Presentation, " ", False);
	
	For IndexOf = 0 To PresentationData.UBound() Do
		PresentationData[IndexOf] = CapitalLetter(PresentationData[IndexOf]);
	EndDo;
	
	If PresentationData.Count() > 2 Then
		NameDataForSearch.LastName  = PresentationData[0];
		NameDataForSearch.Name      = PresentationData[1];
		NameDataForSearch.MiddleName = PresentationData[2];
		DataKind        = "MiddleName";
	ElsIf PresentationData.Count() = 2 And Right(NameDataForSearch.Presentation, 1) = " " Then
		NameDataForSearch.LastName  = PresentationData[0];
		NameDataForSearch.Name      = PresentationData[1];
		PresentationData.Add("");
		DataKind        = "MiddleName";
	ElsIf PresentationData.Count() = 2 Then
		NameDataForSearch.LastName  = PresentationData[0];
		NameDataForSearch.Name      = PresentationData[1];
		DataKind        = "Name";
	ElsIf PresentationData.Count() = 1 And Right(NameDataForSearch.Presentation, 1) = " " Then
		NameDataForSearch.LastName  = PresentationData[0];
		PresentationData.Add("");
		DataKind        = "Name";
	Else
		DataKind        = "LastName";
		NameDataForSearch.LastName  = CapitalLetter(TrimAll(NameDataForSearch.Presentation));
	EndIf;
	
EndProcedure

// Generates a structure for performing a search.
//
// Parameters:
//  FullNameData - Structure, Undefined - Describes the full name passed for searching.
//    The structure is used to determine the gender if "Gender" is not specified:
//    * LastName - String, Undefined - Person's last name (if "SearchMode_" is set to "LastName"). Optional.
//      
//    * Name - String, Undefined - Person's first name (if "SearchMode_" is set to "Name"). Optional.
//      
//    * MiddleName - String, Undefined - Person's middle name (if "SearchMode_" is set to "MiddleName"). Optional.
//      
//    * Presentation - String - Person's full name (if "SearchMode_" is set to "LastFirstName"). Optional.
//      
//
// Returns:
//  Structure - Data used in the search
//    * LastName - String, Undefined - Person's last name (if the SearchMode is set to "LastName").
//    Data used in the search
//    * LastName - String, Undefined - Person's last name (if the SearchMode is set to "LastName").
//    
//
Function NewNameDataForSearch(FullNameData)
	
	NameDataForSearch  = New Structure;
	
	NameDataForSearch.Insert("LastName",       "");
	NameDataForSearch.Insert("Name",           "");
	NameDataForSearch.Insert("MiddleName",      "");
	NameDataForSearch.Insert("Presentation", "");
	
	For Each NameElement In FullNameData Do
		NameDataForSearch[NameElement.Key] = NameElement.Value;
	EndDo;
	
	Return NameDataForSearch;
	
EndFunction

// Adds the found values to the search result.
//
// Parameters:
//  Result - Array of Structure - Search result.
//  Value - String - Found value.
//  DisplayPriority - Number - Value priority.
//
Procedure AddToSearchResult(
		Result,
		Value,
		DisplayPriority)
	
	Result.Add(
		New Structure(
			"Value, DisplayPriority",
			Value,
			DisplayPriority));
	
EndProcedure

#EndRegion
