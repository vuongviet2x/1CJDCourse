///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Read transfer parameters.
	TransferParameters = GetFromTempStorage(Parameters.StorageAddress); // See DataProcessorObject.QueryConsole.PutQueriesInTempStorage
	Object.Queries.Load(TransferParameters.Queries);
	Object.Parameters.Load(TransferParameters.Parameters);
	Object.FileName = TransferParameters.FileName;
	CurrentQueryID = TransferParameters.CurrentQueryID;
	CurrentParameterID = TransferParameters.CurrentParameterID;
	
	DataProcessorObject = DataProcessorObject2();
	Object.AvailableDataTypes = DataProcessorObject.Metadata().Attributes.AvailableDataTypes.Type;
	
	TypesList = DataProcessorObject2().GenerateListOfTypes();
	DataProcessorObject.TypesListFiltering(TypesList, "");
	
	Filter = New Structure;
	Filter.Insert("Id", CurrentQueryID);
	QueriesStringsWithID = Object.Queries.FindRows(Filter);
	If QueriesStringsWithID.Count() > 0 Then
		Items.Queries.CurrentRow = QueriesStringsWithID.Get(0).GetID();
	EndIf;
	Title = NStr("ru = 'Выбрать запрос';
					|en = 'Select query';");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure QueriesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	Cancel = True;
	
	CopyingItem = Item.CurrentData;
	
	DefaultQueryName = FormOwner.DefaultQueryName;
	QueryID = New UUID;
	
	Query = Object.Queries.Add();
	Query.Name = DefaultQueryName;
	Query.Id = QueryID;
	Query.QueryPlanStorageAddress = PutToTempStorage(Undefined,New UUID);
	
	If Copy Then
		NewQueryName = GenerateQueryCopyName(CopyingItem.Name);
		Query.Name = NewQueryName;
		Query.Text = CopyingItem.Text;
		CurrentQueryID = CopyingItem.Id;
		
		// Copy parameters.
		Filter = New Structure;
		Filter.Insert("QueryID", CurrentQueryID);
		ParametersArray = Object.Parameters.FindRows(Filter);
		For Each Page1 In ParametersArray Do
			ParameterItem = Object.Parameters.Add();
			ParameterItem.Id = New UUID;
			ParameterItem.QueryID = QueryID;
			ParameterItem.Name = Page1.Name;
			ParameterItem.Type = Page1.Type;
			ParameterItem.Value = Page1.Value;
			ParameterItem.TypeInForm = Page1.TypeInForm;
			ParameterItem.ValueInForm = Page1.ValueInForm;
		EndDo;
	EndIf;
	
	FormOwner.Modified = True;
	
EndProcedure

// Handler before query delete.
// Deletes query parameters.
//
&AtClient
Procedure QueriesBeforeDeleteRow(Item, Cancel)
	
	ParametersInForm = Object.Parameters;
	QueryToDeleteID = Items.Queries.CurrentData.Id;
	
	RowsCount = ParametersInForm.Count() - 1;
	While RowsCount >= 0 Do
		CurrentParameter = ParametersInForm.Get(RowsCount);
		If CurrentParameter.QueryID = QueryToDeleteID Then
			ParametersInForm.Delete(RowsCount);
			Modified = True;
		EndIf;
		RowsCount = RowsCount - 1;
	EndDo;
	
	FormOwner.Modified = True;
	
EndProcedure

&AtClient
Procedure QueriesSelection(Item, RowSelected, Field, StandardProcessing)
	
	QueryChoiceProcessing();
	
EndProcedure

&AtClient
Procedure QueriesNameOnChange(Item)
	
	FormOwner.Modified = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompareQueriesResults(Command)
	
#If Not ThickClientManagedApplication And Not ThickClientOrdinaryApplication Then
	ShowMessageBox(, NStr("ru = 'Сравнивать результаты можно только в режиме толстого клиента.';
									|en = 'You can compare results only in the thick client mode.';"));
	Return;
#Else
	SelectedQueries = Items.Queries.SelectedRows;
	If SelectedQueries.Count() <> 2 Then
		ShowMessageBox(, NStr("ru = 'Для сравнения выберите только 2 запроса';
										|en = 'Select only 2 queries to compare';"));
		Return;
	Else
		FirstQueryStringID = SelectedQueries.Get(0);
		SecondQueryStringID = SelectedQueries.Get(1);
	EndIf;
	
	FirstQueryID = Object.Queries.FindByID(FirstQueryStringID).Id;
	SecondQueryID1 = Object.Queries.FindByID(SecondQueryStringID).Id;
	
	FirstQueryFile = Undefined;
	SecondQueryFile = Undefined;
	
	GetSpreadsheetDocumentsOfQueriesToCompare(FirstQueryID, SecondQueryID1, FirstQueryFile, SecondQueryFile);
	
	If TypeOf(FirstQueryFile) <> Undefined
		And TypeOf(SecondQueryFile) <> Undefined Then
		// Compare two files.
		Comparison = New FileCompare;
		Comparison.CompareMethod = FileCompareMethod.SpreadsheetDocument;
		Comparison.FirstFile = FirstQueryFile;
		Comparison.SecondFile = SecondQueryFile;
		Comparison.ShowDifferencesModally();
		
		DeleteFiles(FirstQueryFile);
		DeleteFiles(SecondQueryFile);
	EndIf;
#EndIf

EndProcedure

&AtClient
Procedure SaveQueriesToAnotherFile(Command)
	
	SaveQueryFile();
	
EndProcedure

&AtClient
Procedure SaveQueriesToFile(Command)
	
	SaveQueryFile(Object.FileName);
	
EndProcedure

&AtClient
Procedure RecoverQueriesFromFile(Command)
	
	FileReadingProcessing(True);
	FormOwner.Modified = False;
	
EndProcedure

&AtClient
Procedure Select_Query(Command)
	
	QueryChoiceProcessing();
	
EndProcedure

&AtClient
Procedure AddQueriesFromFile(Command)
	
	FileReadingProcessing(False);
	FormOwner.Modified = True;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function DataProcessorObject2()
	
	Return FormAttributeToValue("Object");
	
EndFunction

&AtServer
Function PutQueriesInStructure(QueryID, ParameterId)
	
	TransferParameters = New Structure;
	TransferParameters.Insert("StorageAddress", DataProcessorObject2().PutQueriesInTempStorage(Object, QueryID, ParameterId));
	Return TransferParameters;
	
EndFunction

&AtClient
Procedure QueryChoiceProcessing()
	
	CurrentRow = Items.Queries.CurrentRow;
	If CurrentRow <> Undefined Then
		CurrentQuery = Items.Queries.CurrentData;
		CurrentQueryID = CurrentQuery.Id;
		
		TransferParameters = PutQueriesInStructure(CurrentQueryID, CurrentParameterID);
		
		// Pass parameters to opening form.
		Close();
		Notify("ExportQueriesToAttributes", TransferParameters);
		Notify("ClearQueryLabel");
		Notify("UpdateFormClient");
	Else
		ShowMessageToUser(NStr("ru = 'Выберите запрос.';
											|en = 'Select query.';"), "Object");
	EndIf;
	
EndProcedure

// Save.
&AtClient
Procedure SaveQueryFile(FileName = "")
	
	AdditionalParameters = New Structure("FileName", FileName);
#If Not WebClient Then
		// Extension is always attached for thin, thick, and web clients.
		SaveQueryFileCompletion(True, AdditionalParameters);
		Return;
#EndIf
	
	Notification = New NotifyDescription("BeginAttachingFileSystemExtensionCompletion", ThisObject,
		New NotifyDescription("SaveQueryFileCompletion", ThisObject, AdditionalParameters));
	BeginAttachingFileSystemExtension(Notification);
	
EndProcedure

&AtClient
Procedure SaveQueryFileCompletion(Result, AdditionalParameters) Export
	
	FileName = AdditionalParameters.FileName;
	If Result Then
		
		FilesToReceive = New Array;
		FilesToReceive.Add(New TransferableFileDescription(FileName, SaveQueriesToTempStorage(Object)));
		
		GetFilesNotificationDescription = New NotifyDescription("GettingFilesCompletion", ThisObject);
		If ValueIsFilled(FileName) Then
			BeginGettingFiles(GetFilesNotificationDescription, FilesToReceive, FileName, False);
		Else
			Dialog = New FileDialog(FileDialogMode.Save);
			Dialog.Title = NStr("ru = 'Выберите файл запросов';
									|en = 'Select query file';");
			Dialog.Preview = False;
			Dialog.Filter = NStr("ru = 'Файл запросов (*.q1c)|*.q1c';
								|en = 'Query file (*.q1c)|*.q1c';");
			Dialog.DefaultExt = "q1c";
			Dialog.CheckFileExist = True;
			Dialog.Multiselect = False;
			
			BeginGettingFiles(GetFilesNotificationDescription, FilesToReceive, Dialog, True);
		EndIf;
	Else
		ShowMessageToUser(NStr("ru = 'Без расширения для работы с 1С:Предприятием невозможно работать с файлами.';
											|en = 'To manage files, install 1C:Enterprise Extension.';"), "Object");
	EndIf;
	
EndProcedure

// Parameters:
//   Result - Array of File
//   AdditionalParameters - Structure
//
&AtClient
Procedure GettingFilesCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined And TypeOf(Result) = Type("Array") Then
		FormOwner.Modified = False;
		Object.FileName = Result[0].Name;
		FormOwner.Object.FileName = Result[0].Name;
	EndIf;
	
EndProcedure

// Import.

&AtClient
Procedure FileReadingProcessing(ShouldDelete)
	
	AdditionalParameters = New Structure("ShouldDelete", ShouldDelete);
	
#If Not WebClient Then
		// Extension is always attached for thin, thick, and web clients.
		ReadFileEnd(True, AdditionalParameters);
		Return;
#EndIf
	
	Notification = New NotifyDescription("BeginAttachingFileSystemExtensionCompletion", ThisObject,
		New NotifyDescription("ReadFileEnd", ThisObject, AdditionalParameters));
	BeginAttachingFileSystemExtension(Notification);
	
EndProcedure

&AtClient
Procedure ReadFileEnd(Result, AdditionalParameters) Export
	
	If Result Then
		// Select a file to import.
		Dialog = New FileDialog(FileDialogMode.Open);
		Dialog.Title = NStr("ru = 'Выберите файл запросов';
								|en = 'Select query file';");
		Dialog.Preview = False;
		Dialog.Filter = NStr("ru = 'Файл запросов (*.q1c)|*.q1c';
							|en = 'Query file (*.q1c)|*.q1c';");
		Dialog.DefaultExt = "q1c";
		Dialog.CheckFileExist  = True;
		Dialog.Multiselect = False;

		AdditionalParameters = New Structure("ShouldDelete", AdditionalParameters.ShouldDelete);
		Notification = New NotifyDescription("PlacingFilesCompletion", ThisObject, AdditionalParameters);
		BeginPuttingFiles(Notification,, Dialog, True, UUID);
	Else
		ShowMessageToUser(NStr("ru = 'Без расширения для работы с 1С:Предприятием невозможно работать с файлами.';
											|en = 'To manage files, install 1C:Enterprise Extension.';"), "Object");
	EndIf;

EndProcedure

&AtClient
Procedure PlacingFilesCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Array") Then
		If Result.Count() > 0 Then
			
			If AdditionalParameters.ShouldDelete Then
				Object.Queries.Clear();
				Object.Parameters.Clear();
			EndIf;
			
			FileName = Result[0].Name;
			ImportQueriesFromFile(Result[0].Location);
			Object.FileName = FileName;
			
		EndIf;
	EndIf;
	
	NumberOfRequests_ = Object.Queries.Count();
	If NumberOfRequests_ > 0 Then
		
		CurrentQueryID = Object.Queries.Get(0).Id;
		TransferParameters = PutQueriesInStructure(CurrentQueryID, CurrentParameterID);
		
		Notify("ExportQueriesToAttributes", TransferParameters);
		Notify("UpdateFormClient");
		
	EndIf;
	
EndProcedure

// Common save and import procedures.

&AtClient
Procedure BeginAttachingFileSystemExtensionCompletion(ExtensionAttached, AdditionalParameters) Export
	
	If ExtensionAttached Then
		ExecuteNotifyProcessing(AdditionalParameters, True);
	Else
		If Not ExtensionInstallationPrompted Then
			ExtensionInstallationPrompted = True;
			NotifyDescription = New NotifyDescription("QueryAboutExtensionInstallation", ThisObject, AdditionalParameters);
			BeginInstallFileSystemExtension(NotifyDescription);
		Else
			ExecuteNotifyProcessing(AdditionalParameters, ExtensionAttached);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure QueryAboutExtensionInstallation(Notification) Export
	
	ExecuteNotifyProcessing(Notification, True);
	
EndProcedure

// Save queries.
//
// Parameters:
//  FileName - XML file name.
//  Object - Data processor object.
//
&AtServer
Function SaveQueries(Val Object)
	
	BinaryData = DataProcessorObject2().WriteQueriesToXMLFile(Object);
	Return BinaryData;
	
EndFunction

&AtServer
Function SaveQueriesToTempStorage(Val Object)
	
	BinaryData = SaveQueries(Object);
	Return PutToTempStorage(BinaryData);
	
EndFunction

&AtServer
Procedure ImportQueriesFromFile(AddressInTempStorage)
	
	BinaryData = GetFromTempStorage(AddressInTempStorage);
	ExternalDataProcessorObject = DataProcessorObject2().ReadQueriesFromXMLFile(BinaryData);
	FillQueriesAndParametersFromExternalDataProcessorObject(ExternalDataProcessorObject);
	
EndProcedure

// Populates queries and parameters from the external data processor object.
//
// Parameters:
//  DataProcessorObject2 - External data processor object.
//
&AtServer
Procedure FillQueriesAndParametersFromExternalDataProcessorObject(DataProcessorObject2)
	
	QueriesDataProcessor = DataProcessorObject2.Queries;
	ParametersDataProcessor = DataProcessorObject2.Parameters;
	
	Object.Queries.Clear();
	Object.Parameters.Clear();
	
	// Populate form queries and parameters.
	For Each QueryText1 In QueriesDataProcessor Do
		QueryItem = Object.Queries.Add();
		QueryItem.Id = QueryText1.Id;
		QueryItem.Name = QueryText1.Name;
		QueryItem.Text = QueryText1.Text;
		QueryItem.QueryPlanStorageAddress = QueryText1.QueryPlanStorageAddress;
	EndDo;
	
	For Each CurParameter In ParametersDataProcessor Do
		StringType = CurParameter.Type;
		
		Value = CurParameter.Value;
		Value = ValueFromStringInternal(Value);
		
		If StringType = "ValueTable" Or StringType = "PointInTime" Or StringType = "Boundary" Then
			ParameterItem = Object.Parameters.Add();
			ParameterItem.QueryID = CurParameter.QueryID;
			ParameterItem.Id = CurParameter.Id;
			ParameterItem.Name = CurParameter.Name;
			ParameterItem.Type = TypesList.FindByValue(StringType).Value;
			ParameterItem.Value = CurParameter.Value;
			ParameterItem.TypeInForm = TypesList.FindByValue(StringType).Presentation;
			ParameterItem.ValueInForm = DataProcessorObject2().GenerateValuePresentation(Value);
		Else
			Array = New Array;
			Array.Add(Type(StringType));
			LongDesc = New TypeDescription(Array);
			
			ParameterItem = Object.Parameters.Add();
			ParameterItem.QueryID = CurParameter.QueryID;
			ParameterItem.Id = CurParameter.Id;
			ParameterItem.Name = CurParameter.Name;
			ParameterItem.Type = StringType;
			ParameterItem.TypeInForm = LongDesc;
			ParameterItem.Value = ValueToStringInternal(Value);
			ParameterItem.ValueInForm = Value;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ShowMessageToUser(MessageText, DataPath)
	
	ClearMessages();
	Message = New UserMessage();
	Message.Text = MessageText;
	Message.DataPath = DataPath;
	Message.SetData(Object);
	Message.Message();
	
EndProcedure

&AtServer
Procedure GetSpreadsheetDocumentsOfQueriesToCompare(FirstQueryID1, SecondQueryID, FirstQueryFile, SecondQueryFile)
	
	FirstQueryFilter = New Structure;
	FirstQueryFilter.Insert("Id",FirstQueryID1);
	FirstDocumentAddress = Object.Queries.FindRows(FirstQueryFilter).Get(0).ResultAddress;
	
	FirstQueryFilter.Insert("Id",SecondQueryID);
	SecondDocumentAddress = Object.Queries.FindRows(FirstQueryFilter).Get(0).ResultAddress;
	
	If IsBlankString(FirstDocumentAddress) Or IsBlankString(SecondDocumentAddress) Then
		Return;
	EndIf;
	
	FirstQuerySD = GetFromTempStorage(FirstDocumentAddress); // BinaryData
	SecondQuerySD = GetFromTempStorage(SecondDocumentAddress); // BinaryData
	
	FirstQueryFile = GetTempFileName("mxl");
	FirstQuerySD.Write(FirstQueryFile);
	
	SecondQueryFile = GetTempFileName("mxl");
	SecondQuerySD.Write(SecondQueryFile);
	
EndProcedure

// Generates the name of the query copy.
//
// Parameters:
//  Name - Query name to pass.
//
&AtClient
Function GenerateQueryCopyName(Name)
	
	Flag 	= True;
	IndexOf 	= 1;
	
	While Flag Do
		QueryNameToGenerate = NStr("ru = '%QueryName1% - Копия %CopyNumber%';
									|en = '%QueryName1% - Copy %CopyNumber%';");
		QueryNameToGenerate = StrReplace(QueryNameToGenerate, "%QueryName1%", Name);
		QueryNameToGenerate = StrReplace(QueryNameToGenerate, "%CopyNumber%", IndexOf);
		
		Filter = New Structure;
		Filter.Insert("Name", QueryNameToGenerate);
		
		QueriesByFilterArray = Object.Queries.FindRows(Filter);
		
		If QueriesByFilterArray.Count() = 0 Then
			Flag = False;
		EndIf;
		
		IndexOf = IndexOf + 1;
	EndDo;
	
	Return QueryNameToGenerate;
	
EndFunction

#EndRegion