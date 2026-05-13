///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Internal

// Deletes unused common add-ins.
//
Procedure RemoveUnusedAddIns() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.RemoveUnusedAddIns);
	If Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
			"SELECT
			|	CommonAddIns.Ref AS Ref
			|FROM
			|	Catalog.CommonAddIns AS CommonAddIns
			|WHERE
			|	NOT CommonAddIns.DeletionMark
			|	AND NOT CommonAddIns.Id IN (&IDs)";
		
	Query.SetParameter("IDs", AddInsInternal.SuppliedAddIns());
		
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add("Catalog.CommonAddIns");
			LockItem.SetValue("Ref", Selection.Ref);
			Block.Lock();

			Object = Selection.Ref.GetObject();
			Object.DeletionMark = True;
			Object.Write();
			CommitTransaction();
		Except
			RollbackTransaction();
			WriteLogEvent(NStr("ru = 'Поставляемые внешние компоненты.Удаление неиспользуемой компоненты';
											|en = 'Built-in add-ins.Delete unused add-in';",
				Common.DefaultLanguageCode()),
				EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(
				ErrorInfo()));
			Raise;
		EndTry;
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Parameters:
//  ComponentDetails - See AddInsServer.SuppliedSharedAddInDetails.
//
Procedure UpdateSharedAddIn(ComponentDetails) Export
	
	If Not Common.DataSeparationEnabled() Or Common.SeparatedDataUsageAvailable() Then 
		Raise
			NStr("ru = 'Загрузка общих внешних компонент возможна только в неразделенном режиме модели сервиса.';
				|en = 'Common add-ins can be imported only in shared SaaS mode.';");
	EndIf;
	
	SetPrivilegedMode(True);
	
	WriteLogEvent(NStr("ru = 'Поставляемые внешние компоненты.Загрузка поставляемой компоненты';
									|en = 'Built-in add-ins.Import built-in add-in';", 
		Common.DefaultLanguageCode()),
		EventLogLevel.Information,,,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Инициирована загрузка поставляемой обработки
			           |%1';
						|en = 'Built-in data processor import is initiated
						|%1';"),
		AddInsInternal.AddInPresentation(
			ComponentDetails.Id, 
			ComponentDetails.Version)));
	
	BeginTransaction();
	Try
		Ref = Catalogs.CommonAddIns.FindByID(
			ComponentDetails.Id, 
			ComponentDetails.Version);
		
		If Ref.IsEmpty() Then
			SharedAddIn = Catalogs.CommonAddIns.CreateItem();
		Else
			Block = New DataLock;
			LockItem = Block.Add("Catalog.CommonAddIns");
			LockItem.SetValue("Ref", Ref);
			Block.Lock();
			
			SharedAddIn = Ref.GetObject();
			SharedAddIn.Lock();
		EndIf;
		
		SharedAddIn.Fill(Undefined); // Default constructor
		
		ComponentBinaryData = New BinaryData(ComponentDetails.PathToFile);
		Information = AddInsInternal.InformationOnAddInFromFile(ComponentBinaryData, False);
		
		If Not Information.Disassembled Then 
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Поставляемую компоненту не удалось разобрать
				           |по причине:
				           |%1 %2';
							|en = 'Cannot parse the built-in add-in
							|due to:
							|%1 %2';"),
				Information.ErrorDescription, 
				?(Information.ErrorInfo = Undefined, "", 
					": " + ErrorProcessing.BriefErrorDescription(Information.ErrorInfo)));
		EndIf;
		
		FillPropertyValues(SharedAddIn, Information.Attributes); // By manifest data.
		FillPropertyValues(SharedAddIn, ComponentDetails);   // By data from the website.
		
		SharedAddIn.TargetPlatforms = New ValueStorage(Information.Attributes.TargetPlatforms);
		SharedAddIn.AddInStorage = New ValueStorage(ComponentBinaryData);
		
		SharedAddIn.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(
			NStr("ru = 'Поставляемые внешние компоненты.Загрузка поставляемой компоненты';
				|en = 'Built-in add-ins.Import built-in add-in';",
				Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure

Function IsComponentFromStorage(Location) Export
	
	Return StrStartsWith(Location, "e1cib/data/Catalog.CommonAddIns.AddInStorage");
	
EndFunction

// Parameters:
//   Result     - See AddInsInternal.SavedAddInInformation
//   Id - String               - an add-in object ID.
//   Version – String
//                 - Undefined - an add-in version.
// 
Procedure FillAddInInformation(Result, Version, Id) Export
	
	ReferenceFromSharedStorage = Catalogs.CommonAddIns.FindByID(Id, Version);
	ReferenceFromStorage = Catalogs.AddIns.FindByID(Id, Version);
		
	If ReferenceFromStorage.IsEmpty() Then
		If ReferenceFromSharedStorage.IsEmpty() Then
			Result.State = "NotFound1";
		Else
			Result.State = "FoundInSharedStorage";
			Result.Ref = ReferenceFromSharedStorage;
		EndIf;
	Else
		If ReferenceFromSharedStorage.IsEmpty() Then
			Result.State = "FoundInStorage";
			Result.Ref = ReferenceFromStorage;
		Else
			If ValueIsFilled(Version) Then
				// The same add-in version is present in both the common storage and area storage.
				// The add-in in the area has a higher priority.
				Result.State = "FoundInStorage";
				Result.Ref = ReferenceFromStorage;
			Else
				StorageVersion = Common.ObjectAttributeValue(ReferenceFromStorage, "VersionDate");
				SharedStorageVersion = Common.ObjectAttributeValue(ReferenceFromSharedStorage, "VersionDate");
				
				If SharedStorageVersion > StorageVersion Then
					Result.State = "FoundInSharedStorage";
					Result.Ref = ReferenceFromSharedStorage;
				Else
					// The add-in is present in both the common storage and area storage.
					// The add-in in the area has a higher priority.
					Result.State = "FoundInStorage";
					Result.Ref = ReferenceFromStorage;
				EndIf;
			EndIf;
		EndIf;
	EndIf;

EndProcedure

Function SharedAddInVersions() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CommonAddIns.Ref AS Ref,
	|	CommonAddIns.DataVersion AS DataVersion
	|FROM
	|	Catalog.CommonAddIns AS CommonAddIns";
	
	Return Query.Execute().Select();

EndFunction


#Region ConfigurationSubsystemsEventHandlers

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	
	Objects.Insert(Metadata.Catalogs.CommonAddIns.FullName(), "AttributesToEditInBatchProcessing");
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	ModuleExportImportData = Common.CommonModule("ExportImportData");
	ModuleExportImportData.AddTypeExcludedFromUploadingUploads(Types,
		Metadata.Catalogs.CommonAddIns,
		ModuleExportImportData.ActionWithClearLinks());
	
EndProcedure

// 
Procedure OnSendDataToMaster(DataElement, ItemSend, Recipient) Export
	
	If TypeOf(DataElement) = Type("CatalogObject.CommonAddIns") Then
		ItemSend = DataItemSend.Ignore;
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.OnSendDataToSlave.
Procedure OnSendDataToSlave(DataElement, ItemSend, InitialImageCreating, Recipient) Export
	
	If TypeOf(DataElement) = Type("CatalogObject.CommonAddIns") Then
		ItemSend = DataItemSend.Ignore;
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromMaster.
Procedure OnReceiveDataFromMaster(DataElement, ItemReceive, SendBack, Sender) Export
	
	If TypeOf(DataElement) = Type("CatalogObject.CommonAddIns") Then
		ItemReceive = DataItemReceive.Ignore;
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromSlave.
Procedure OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Sender) Export
	
	If TypeOf(DataElement) = Type("CatalogObject.CommonAddIns") Then
		ItemReceive = DataItemReceive.Ignore;
	EndIf;
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.9.221";
	Handler.SharedData = True;
	Handler.Id = New UUID("a76bc949-68aa-4ba3-b9f3-a03b530da817");
	Handler.Procedure = "Catalogs.CommonAddIns.HandleCommonAddIns";
	Handler.Comment = NStr("ru = 'Заполнение реквизитов совместимости общих компонент.';
									|en = 'Fill in compatibility attributes of common add-ins.';");
	Handler.ExecutionMode = "Seamless";
	
EndProcedure

#EndRegion

#EndRegion


