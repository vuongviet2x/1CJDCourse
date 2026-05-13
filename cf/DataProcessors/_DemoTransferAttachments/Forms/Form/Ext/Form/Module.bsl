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
	
	FilesOwners = New Array;
	
	// ACC:278-off - Call the internal API for debugging purposes.
	CatalogSuffix = FilesOperationsInternal.CatalogSuffixAttachedFiles();
	// ACC:278-on
	PrefixLength      = StrLen(CatalogSuffix);
	
	For Each CatalogWithFiles In Metadata.Catalogs Do
		If StrEndsWith(CatalogWithFiles.Name, CatalogSuffix) Then
			ShortNameOfFilesOwner = Left(CatalogWithFiles.Name, StrLen(CatalogWithFiles.Name) - PrefixLength);
			If Metadata.Catalogs.Find(ShortNameOfFilesOwner) = Undefined Then
				Continue;
			EndIf;
			TypeName = "CatalogRef." + ShortNameOfFilesOwner;
			If Metadata.Catalogs.Files.Attributes.FileOwner.Type.ContainsType(Type(TypeName)) Then
				FilesOwners.Add("Catalog." + Left(CatalogWithFiles.Name, StrLen(CatalogWithFiles.Name) - PrefixLength));
			EndIf;
		EndIf;
	EndDo;
	
	For Each MetadataObjectName1 In FilesOwners Do
		FilesOwner = Common.MetadataObjectByFullName(MetadataObjectName1);
		Items.DocumentOrCatalog.ChoiceList.Add(FilesOwner.FullName(), FilesOwner.Presentation());
	EndDo;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DocumentOrCatalogOnChange(Item)
	
	Items.Source.ChoiceList.Clear();
	Items.Receiver.ChoiceList.Clear();
	
	FileStorageCatalogNames = FileStorageCatalogNames(DocumentOrCatalog);
	For Each StorageCatalogName In FileStorageCatalogNames Do
		Items.Source.ChoiceList.Add(StorageCatalogName.Value, StorageCatalogName.Presentation);
		Items.Receiver.ChoiceList.Add(StorageCatalogName.Value, StorageCatalogName.Presentation);
	EndDo;
	
EndProcedure     

&AtClient
Procedure SourceOnChange(Item)    
	
	FillAttachmentsTable();
	SetPrimaryTableInSource();
	
EndProcedure

&AtClient
Procedure AttachedFilesOwnersOnActivateCell(Item)
	SetFilter();
EndProcedure

&AtClient
Procedure ReceiverOnChange(Item)
	SetPrimaryTableInDestination();
EndProcedure


#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveFiles(Command)
	
	If IsBlankString(DocumentOrCatalog) Then
		CommonClient.MessageToUser(NStr("ru = 'Укажите документ или справочник с присоединенными файлами.';
														|en = 'Specify a document or catalog with attachments.';"),, "DocumentOrCatalog");
		Return;
	EndIf;
	
	If IsBlankString(Source) Then
		CommonClient.MessageToUser(NStr("ru = 'Укажите таблицу-источник с файлами.';
														|en = 'Specify a source table with files.';"),, "Source");
		Return;
	EndIf;
	
	If IsBlankString(Receiver) Then
		CommonClient.MessageToUser(NStr("ru = 'Укажите таблицу-приемник файлов.';
														|en = 'Specify a file destination table.';"),, "Receiver");
		Return;
	EndIf;
	
	CurrentData = Items.AttachedFilesOwners.CurrentData;
	If CurrentData = Undefined Then
		CommonClient.MessageToUser(NStr("ru = 'Выберите владельца присоединенных файлов.';
														|en = 'Select the owner of attachments.';"),, "AttachedFilesOwners");
		Return;
	EndIf;
	
	Result = MoveFilesServer(CurrentData.Ref);
	If Result > 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Файлы успешно перенесены (%1).';
				|en = 'Files are transferred successfully (%1).';"), Result);
	Else
		MessageText = NStr("ru = 'Файлы не были перенесены. Нажмите ""Создать файлы для переноса"" и повторите перенос.';
								|en = 'Files were not transferred. Click ""Create files to transfer"" and try again.';");
	EndIf;
	ShowMessageBox(, MessageText);
	Items.SourceFiles1.Refresh();
	Items.FilesOfDestination.Refresh();
EndProcedure

&AtClient
Procedure CreateFilesToTransfer(Command)
	
	If IsBlankString(DocumentOrCatalog) Then
		CommonClient.MessageToUser(NStr("ru = 'Укажите объект метаданных с файлами.';
														|en = 'Specify a metadata object with files.';"),, "DocumentOrCatalog");
		Return;
	EndIf;
	
	If IsBlankString(Source) Then
		CommonClient.MessageToUser(NStr("ru = 'Укажите таблицу-источник с файлами.';
														|en = 'Specify a source table with files.';"),, "Source");
		Return;
	EndIf;
	
	Result = CreateFilesToTransferAtServer();
	FillAttachmentsTable();
	
	If Result > 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Файлы успешно созданы (%1).';
				|en = 'Files are created successfully (%1).';"), Result);
	Else
		MessageText = NStr("ru = 'Файлы для переноса не были созданы.';
								|en = 'Files to transfer were not created.';");
	EndIf;
	ShowMessageBox(, MessageText);
	
	Items.SourceFiles1.Refresh();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillAttachmentsTable()
	
	AttachedFilesOwners.Clear();
	AttachmentOwnersValue = FormAttributeToValue("AttachedFilesOwners");
	// ACC:278-off - Call the internal API for debugging purposes.
	FilesOwners = FilesOperationsInternal.ReferencesToObjectsWithFiles(DocumentOrCatalog, Source);
	// ACC:278-on
	For Each FilesOwner In FilesOwners Do
		NewRow = AttachmentOwnersValue.Add();
		NewRow.Ref = FilesOwner;
	EndDo;
	ValueToFormAttribute(AttachmentOwnersValue, "AttachedFilesOwners");
	
EndProcedure

&AtServer
Function MoveFilesServer(FilesOwner)
	
	TransferredFiles = FilesOperations.MoveFilesBetweenStorageCatalogs(FilesOwner, Source, Receiver);
	
	Return TransferredFiles.Count();
	
EndFunction

&AtServer
Function CreateFilesToTransferAtServer()
	
	QueryText = 
		"SELECT ALLOWED TOP 1
		|	AttachedFiles.Author AS Author,
		|	AttachedFiles.FileOwner AS FilesOwner,
		|	AttachedFiles.Extension AS ExtensionWithoutPoint,
		|	AttachedFiles.Description AS BaseName,
		|	AttachedFiles.UniversalModificationDate AS ModificationTimeUniversal,
		|	AttachedFiles.Ref AS Ref
		|FROM
		|	&TableName AS AttachedFiles";
	// ACC:278-off - Call the internal API for debugging purposes.
	QueryText = StrReplace(QueryText, "&TableName", 
		DocumentOrCatalog + FilesOperationsInternal.CatalogSuffixAttachedFiles());
	// ACC:278-on
	Query = New Query(QueryText);
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	If Selection.Count() = 0 Then
		Return 0;
	EndIf;
	
	Result = 0;
	While Selection.Next() Do
		
		SourceFile1 = Selection.Ref; // CatalogRef
		
		BeginTransaction();
		Try
			
			FileData = FilesOperations.FileData(SourceFile1);
			
			FileParameters = FilesOperations.FileAddingOptions();
			FileParameters.Author = FileData.Author;
			FileParameters.FilesOwner = Selection.FilesOwner;
			FileParameters.BaseName = FileData.Description;
			FileParameters.ExtensionWithoutPoint = FileData.Extension;
			SourceName = Metadata.FindByFullName(Source).Name;
			NewRefToFile = FilesOperations.NewRefToFile(Selection.FilesOwner, SourceName);
			FilesOperations.AppendFile(FileParameters, FileData.RefToBinaryFileData,,,NewRefToFile);
	
			Result = Result + 1;
			CommitTransaction();
			
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	Return Result;
	
EndFunction

&AtServerNoContext
Function FileStorageCatalogNames(DocumentOrCatalog)
	ObjectManager = Common.ObjectManagerByFullName(DocumentOrCatalog);
	EmptyRef = ObjectManager.EmptyRef();
	// ACC:278-off - Call the internal API for debugging purposes.
	FileStorageCatalogNames = FilesOperationsInternal.FileStorageCatalogNames(EmptyRef, True);
	// ACC:278-on
	Result = New ValueList;
	For Each FileStoringCatalogName In FileStorageCatalogNames Do
		StoringCatalog = Metadata.Catalogs[FileStoringCatalogName.Key];
		Result.Add(StoringCatalog.FullName(), StoringCatalog.Presentation());
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Procedure SetFilter()
	CurrentData = Items.AttachedFilesOwners.CurrentData;
	If CurrentData = Undefined Then
		FilesOwner = Undefined;
	Else
		FilesOwner = CurrentData.Ref;
	EndIf;
	
	CommonClientServer.SetFilterItem(SourceFiles1.Filter, "FileOwner", FilesOwner, DataCompositionComparisonType.Equal);
	CommonClientServer.SetFilterItem(FilesOfDestination.Filter, "FileOwner", FilesOwner, DataCompositionComparisonType.Equal);
EndProcedure

&AtServer
Procedure SetPrimaryTableInSource()
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable              = Source;
	ListProperties.DynamicDataRead = True;
	Common.SetDynamicListProperties(Items.SourceFiles1, ListProperties);
EndProcedure

&AtServer
Procedure SetPrimaryTableInDestination()
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable              = Receiver;
	ListProperties.DynamicDataRead = True;
	Common.SetDynamicListProperties(Items.FilesOfDestination, ListProperties);
EndProcedure

#EndRegion
