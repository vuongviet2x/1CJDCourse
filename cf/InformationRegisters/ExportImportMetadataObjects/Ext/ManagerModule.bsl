// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Get the object to process.
// 
// Parameters:
//  ByProcessingPriority - Boolean - By processing priority.
// 
// Returns:
//  Structure - Get the object to process.:
// * HasObjectsToProcessing - Boolean - There are objects to process.
// * Object - See InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection
Function GetObjectToProcessing(ByProcessingPriority = False) Export
	
	Result = New Structure();
	Result.Insert("HasObjectsToProcessing", False);
	Result.Insert("Object", Undefined);
	
	Block = New DataLock();
	LockItem = Block.Add("InformationRegister.ExportImportMetadataObjects");
	LockItem.SetValue("ProcessingProcedure_", 0);
	
	BeginTransaction();
	
	Try
		
		Block.Lock();
		
		ObjectSelection = ObjectsForProcessingSelection(False, 1);
		
		If ObjectSelection.Next() Then
			
			Result.HasObjectsToProcessing = True;
			Result.Object = ObjectSelection;
			
			If ByProcessingPriority Then
				
				ImportPriority = ImportingMetadataObjectPriority();
				ObjectPriority = PriorityFromProcessingOrder(ObjectSelection.ProcessingProcedure_);
				
				If ImportPriority <> ObjectPriority Then
					Result.Object = Undefined;
				EndIf;
				
			EndIf;
			
			If Result.Object <> Undefined Then
				CommitObjectProcessingStart(Result.Object);
			EndIf;
		
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
	Return Result;
	
EndFunction

// Selection of objects to import.
// 
// Parameters:
//  InProcessing - Boolean - Indicates that previously processed \ unprocessed objects are selected.
//  ObjectCount - Number - Number of objects in the selection.
// 
// Returns:
//  QueryResultSelection - Selection of objects to import.:
//  * ProcessingProcedure_ - Number - Number of the object in the processing order.
//  * MetadataObject - String - Full name of the metadata object.
Function ObjectsForProcessingSelection(InProcessing = False, ObjectCount = 0) Export
	
	Query = New Query();
	Query.SetParameter("InProcessing", InProcessing);
	
	Query.Text = 
	"SELECT TOP 1000
	|	ExportImportMetadataObjects.ProcessingProcedure_ AS ProcessingProcedure_,
	|	ExportImportMetadataObjects.MetadataObject AS MetadataObject
	|FROM
	|	InformationRegister.ExportImportMetadataObjects AS ExportImportMetadataObjects
	|WHERE
	|	ExportImportMetadataObjects.InProcessing = &InProcessing
	|
	|ORDER BY
	|	ExportImportMetadataObjects.ProcessingProcedure_";
	
	TextFirst = ?(ValueIsFilled(ObjectCount), "FIRST " + Format(ObjectCount, "NG=0;"), "");
	Query.Text = StrReplace(Query.Text, "TOP 1000", TextFirst);
	
	Return Query.Execute().Select();
	
EndFunction

// There are metadata objects being processed.
// 
// Returns:
//  Boolean - There are metadata objects being processed.
Function HasProcessedMetadataObjects() Export
	
	Query = New Query();
	Query.Text = 
	"SELECT TOP 1
	|	TRUE AS Result
	|FROM
	|	InformationRegister.ExportImportMetadataObjects AS ExportImportMetadataObjects
	|WHERE
	|	ExportImportMetadataObjects.InProcessing";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Commit the start of the object processing.
// 
// Parameters:
//  ObjectSelection - See InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection
Procedure CommitObjectProcessingStart(ObjectSelection) Export
	
	RegisterRecord = GetRecordManager(ObjectSelection);
	RegisterRecord.InProcessing = True;
	RegisterRecord.Write();
	
EndProcedure

// Commit the end of the object processing.
// 
// Parameters:
//  ObjectSelection - See InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection
Procedure RecordObjectProcessingEnd(ObjectSelection) Export
	
	RegisterRecord = GetRecordManager(ObjectSelection);
	RegisterRecord.InProcessing = False;
	RegisterRecord.Write();
	
EndProcedure

// Delete the record.
// 
// Parameters:
//  ObjectSelection - See InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection
Procedure DeleteRecord(ObjectSelection) Export
	
	RegisterRecord = CreateRecordManager();
	RegisterRecord.ProcessingProcedure_ = ObjectSelection.ProcessingProcedure_;
	RegisterRecord.Delete();
	
EndProcedure

// Priority of the metadata object to import.
// 
// Returns:
//  Undefined, Number - Priority of the metadata object to import.
Function ImportingMetadataObjectPriority() Export
	
	Query = New Query();
	Query.Text = 
	"SELECT TOP 1
	|	ExportImportMetadataObjects.ProcessingProcedure_ AS ProcessingProcedure_
	|FROM
	|	InformationRegister.ExportImportMetadataObjects AS ExportImportMetadataObjects
	|WHERE
	|	ExportImportMetadataObjects.InProcessing
	|
	|ORDER BY
	|	ExportImportMetadataObjects.ProcessingProcedure_";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return PriorityFromProcessingOrder(Selection.ProcessingProcedure_);
	EndIf;
	
	Query.Text = 
	"SELECT TOP 1
	|	ExportImportMetadataObjects.ProcessingProcedure_ AS ProcessingProcedure_
	|FROM
	|	InformationRegister.ExportImportMetadataObjects AS ExportImportMetadataObjects
	|WHERE
	|	NOT ExportImportMetadataObjects.InProcessing
	|
	|ORDER BY
	|	ExportImportMetadataObjects.ProcessingProcedure_";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return PriorityFromProcessingOrder(Selection.ProcessingProcedure_);
	EndIf;
	
	Return Undefined;
	
EndFunction

// Priority from the processing order.
// 
// Parameters:
//  ProcessingProcedure_ - Number - Processing order.
// 
// Returns:
//  Number - Priority from the processing order.
Function PriorityFromProcessingOrder(ProcessingProcedure_) Export
	
	Return Int(ProcessingProcedure_ / 10000);
	
EndFunction

#EndRegion

#Region Private

// Get the record manager.
// 
// Parameters:
//  ObjectSelection - See InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection
// 
// Returns:
//  InformationRegisterRecordManager.ExportImportMetadataObjects - Register record manager.
Function GetRecordManager(ObjectSelection)
	
	RegisterRecord = CreateRecordManager();
	RegisterRecord.ProcessingProcedure_ = ObjectSelection.ProcessingProcedure_;
	RegisterRecord.Read();
	
	If Not RegisterRecord.Selected() Or RegisterRecord.MetadataObject <> ObjectSelection.MetadataObject Then
		
		ErrorText = StrTemplate(
			NStr("ru = 'Объект метаданных выборки ''%1'' не соответствует значению записи ''%2''';
				|en = 'The metadata object of the ''%1'' dataset does not correspond to the ''%2'' record value.';"),
			ObjectSelection.MetadataObject,
			?(RegisterRecord.Selected(), RegisterRecord.MetadataObject, NStr("ru = 'Запись не найдена';
																			|en = 'Record is not found';")));
		
		Raise ErrorText;
		
	EndIf;
	
	Return RegisterRecord;
	
EndFunction

#EndRegion

#EndIf
