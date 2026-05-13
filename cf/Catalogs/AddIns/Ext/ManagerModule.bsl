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

// StandardSubsystems.BatchEditObjects

// Returns object attributes that can be edited using the bulk attribute modification data processor.
// 
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

#EndRegion

#EndRegion

#Region Private

// Returns a reference to the add-in catalog by ID and version.
//
// Parameters:
//  Id - String - Add-in object ID.
//  Version        - String - Add-in version.
//
// Returns:
//  CatalogRef.AddIns - a reference to an add-in container in the infobase.
//
Function FindByID(Id, Version = Undefined) Export
	
	Query = New Query;
	Query.SetParameter("Id", Id);
	
	If Not ValueIsFilled(Version) Then 
		Query.Text = 
			"SELECT TOP 1
			|	AddIns.Id AS Id,
			|	AddIns.VersionDate AS VersionDate,
			|	CASE
			|		WHEN AddIns.Use = VALUE(Enum.AddInUsageOptions.Used)
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS Use,
			|	AddIns.Ref AS Ref
			|FROM
			|	Catalog.AddIns AS AddIns
			|WHERE
			|	AddIns.Id = &Id
			|
			|ORDER BY
			|	Use DESC,
			|	VersionDate DESC";
	Else 
		Query.SetParameter("Version", Version);
		Query.Text = 
			"SELECT TOP 1
			|	AddIns.Ref AS Ref,
			|	CASE
			|		WHEN AddIns.Use = VALUE(Enum.AddInUsageOptions.Used)
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS Use
			|FROM
			|	Catalog.AddIns AS AddIns
			|WHERE
			|	AddIns.Id = &Id
			|	AND AddIns.Version = &Version
			|
			|ORDER BY
			|	Use DESC";
		
	EndIf;
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then 
		Return EmptyRef();
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Return Result.Unload()[0].Ref;
	
EndFunction

#Region UpdateHandlers

// Registers the objects to be updated in the InfobaseUpdate exchange plan.
// 
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	If CommonClientServer.CompareVersions(Parameters.SubsystemVersionAtStartUpdates, "3.1.9.221") < 0 Then
	
		QueryText ="SELECT
		|	AddIns.Ref
		|FROM
		|	Catalog.AddIns AS AddIns";
		
		Query = New Query(QueryText);
		
		InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));

	ElsIf ShouldUpdateScanAddInParameters(Parameters.SubsystemVersionAtStartUpdates) Then
	
		QueryText ="SELECT
		|	AddIns.Ref AS Ref
		|FROM
		|	Catalog.AddIns AS AddIns
		|WHERE
		|	AddIns.Id = &Id
		|	OR AddIns.Id = &Id2 AND AddIns.Version LIKE ""3.1.0.%""";
		
		Query = New Query(QueryText);
		Query.SetParameter("Id", "AddInNativeExtension");
		Query.SetParameter("Id2", "ImageScan");
		
		InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
		
	EndIf;
	
EndProcedure

// Update handler of the "Add-ins" catalog:
// - Populates the TargetPlatforms attribute.
// - To ensure auto-update, adds the ExtraCryptoAPI and barcode scan and print add-ins.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	Parameters.ProcessingCompleted = True;
	
	If CommonClientServer.CompareVersions(Parameters.SubsystemVersionAtStartUpdates, "3.1.5.220") < 0
		And Common.SubsystemExists("StandardSubsystems.DigitalSignature")
		And Common.SubsystemExists("OnlineUserSupport.GetAddIns")
		And Not Common.DataSeparationEnabled() Then
		
		ComponentsToUse = AddInsServer.ComponentsToUse("ForImport"); //See GetAddIns.AddInsDetails
		
		If ComponentsToUse.Find("ExtraCryptoAPI", "Id") = Undefined Then 
		
			ModuleDigitalSignatureInternalClientServer = Common.CommonModule("DigitalSignatureInternalClientServer");
			ModuleDigitalSignatureInternal = Common.CommonModule("DigitalSignatureInternal");
			
			ComponentDetails = ModuleDigitalSignatureInternalClientServer.ComponentDetails();
			TheComponentOfTheLatestVersionFromTheLayout = StandardSubsystemsServer.TheComponentOfTheLatestVersion(
				ComponentDetails.ObjectName, ComponentDetails.FullTemplateName);
			
			LayoutLocationSplit = StrSplit(TheComponentOfTheLatestVersionFromTheLayout.Location, ".");
			
			BinaryData = ModuleDigitalSignatureInternal.GetAddInData(
				LayoutLocationSplit.Get(LayoutLocationSplit.UBound()));
				
			AddInParameters = AddInsInternal.ImportParameters();
			AddInParameters.Id = ComponentDetails.ObjectName;
			AddInParameters.Description = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1 для 1С:Предприятие';
					|en = '%1 for 1C:Enterprise';", Common.DefaultLanguageCode()), "ExtraCryptoAPI");
			AddInParameters.Version = TheComponentOfTheLatestVersionFromTheLayout.Version;
			AddInParameters.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Добавлена автоматически %1.';
					|en = 'Added automatically on %1.';", Common.DefaultLanguageCode()), CurrentSessionDate());
			AddInParameters.UpdateFrom1CITSPortal = True;
			AddInParameters.Data = BinaryData;
			
			AddInsInternal.LoadAComponentFromBinaryData(AddInParameters, False);
		EndIf;
	
	EndIf;
	
	If CommonClientServer.CompareVersions(Parameters.SubsystemVersionAtStartUpdates, "3.1.9.163") < 0
		And Common.SubsystemExists("StandardSubsystems.FilesOperations")
		And Common.SubsystemExists("OnlineUserSupport.GetAddIns")
		And Not Common.DataSeparationEnabled() Then
		
		ComponentsToUse = AddInsServer.ComponentsToUse("ForImport"); // See GetAddIns.AddInsDetails
		ModuleFilesOperationsInternalClientServer = Common.CommonModule("FilesOperationsInternalClientServer");
			
		ComponentDetails = ModuleFilesOperationsInternalClientServer.ComponentDetails();
		
		If ComponentsToUse.Find(ComponentDetails.ObjectName, "Id") = Undefined Then 
		
			TheComponentOfTheLatestVersionFromTheLayout = StandardSubsystemsServer.TheComponentOfTheLatestVersion(
				ComponentDetails.ObjectName, ComponentDetails.FullTemplateName);
			
			LayoutLocationSplit = StrSplit(TheComponentOfTheLatestVersionFromTheLayout.Location, ".");
			BinaryData = GetCommonTemplate(LayoutLocationSplit.Get(LayoutLocationSplit.UBound()));
				
			AddInParameters = AddInsInternal.ImportParameters();
			AddInParameters.Id = ComponentDetails.ObjectName;
			AddInParameters.Description = NStr("ru = 'Компонента для сканирования документов и изображений';
													|en = 'Add-in to scan documents and images';");
			AddInParameters.Version = TheComponentOfTheLatestVersionFromTheLayout.Version;
			AddInParameters.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Добавлена автоматически %1.';
					|en = 'Added automatically on %1.';"), CurrentSessionDate());
			AddInParameters.UpdateFrom1CITSPortal = True;
			AddInParameters.Data = BinaryData;
			
			AddInsInternal.LoadAComponentFromBinaryData(AddInParameters, False);
		EndIf;
		
	EndIf;

	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.AddIns");
	If Selection.Count() > 0 Then
		ProcessExternalComponents(Selection, Parameters.SubsystemVersionAtStartUpdates);
	EndIf;

	ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
		"Catalog.AddIns");
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

// Parameters:
//   Selection - QueryResultSelection:
//     * Ref - CatalogRef.AddIns
//
Procedure ProcessExternalComponents(Selection, SubsystemVersionAtStartUpdates)
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	
	ShouldUpdateSupportedPlatforms = CommonClientServer.CompareVersions(SubsystemVersionAtStartUpdates, "3.1.9.221") < 0;
	ShouldUpdateScanAddInParameters = ShouldUpdateScanAddInParameters(SubsystemVersionAtStartUpdates);
		
	If ShouldUpdateScanAddInParameters Then
		ModuleFilesOperationsInternalClientServer = Common.CommonModule("FilesOperationsInternalClientServer");
		ComponentDetails = ModuleFilesOperationsInternalClientServer.ComponentDetails();
		ScanAddInID = ComponentDetails.ObjectName;
	EndIf;

	While Selection.Next() Do
		
		ReceivedDetails = New Array;
		
		If ShouldUpdateSupportedPlatforms Then
			ReceivedDetails.Add("AddInStorage");
			ReceivedDetails.Add("TargetPlatforms");
		EndIf;
		
		If ShouldUpdateScanAddInParameters Then
			ReceivedDetails.Add("Id");
			ReceivedDetails.Add("Version");
		EndIf;
		
		AddInAttributes = Common.ObjectAttributesValues(Selection.Ref, ReceivedDetails);

		If ShouldUpdateSupportedPlatforms Then
			
			ShouldUpdateAddInSupportedPlatforms = True;
			
			ComponentBinaryData = AddInAttributes.AddInStorage.Get();
			
			If TypeOf(ComponentBinaryData) <> Type("BinaryData") Then
				ShouldUpdateAddInSupportedPlatforms = False;
			Else
					
				InformationOnAddInFromFile = AddInsInternal.InformationOnAddInFromFile(
					ComponentBinaryData, False);
				If Not InformationOnAddInFromFile.Disassembled Then
					ShouldUpdateAddInSupportedPlatforms = False;
				Else
					Attributes = InformationOnAddInFromFile.Attributes;
					TargetPlatforms = AddInAttributes.TargetPlatforms.Get();
					If TargetPlatforms <> Undefined And Common.IdenticalCollections(TargetPlatforms,
						Attributes.TargetPlatforms) Then
						ShouldUpdateAddInSupportedPlatforms = False;
					EndIf;
				EndIf;

			EndIf;
			
		Else
			ShouldUpdateAddInSupportedPlatforms = False;
		EndIf;
		
		If Not ShouldUpdateAddInSupportedPlatforms 
			And Not (ShouldUpdateScanAddInParameters And (AddInAttributes.Id = "AddInNativeExtension"
				Or AddInAttributes.Id = ScanAddInID 
				And StrStartsWith(AddInAttributes.Version, "3.1.0."))) Then
			InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			ObjectsProcessed = ObjectsProcessed + 1;
			Continue;
		EndIf;
		
		RepresentationOfTheReference = String(Selection.Ref);
		BeginTransaction();
		Try

			Block = New DataLock;
			LockItem = Block.Add("Catalog.AddIns");
			LockItem.SetValue("Ref", Selection.Ref);
			LockItem.Mode = DataLockMode.Shared;
			Block.Lock();

			ComponentObject_SSLs = Selection.Ref.GetObject(); // CatalogObject.AddIns
			If ShouldUpdateAddInSupportedPlatforms Then
				ComponentObject_SSLs.TargetPlatforms = New ValueStorage(Attributes.TargetPlatforms);
			EndIf;
			
			If ShouldUpdateScanAddInParameters And AddInAttributes.Id = "AddInNativeExtension" Then
				ComponentObject_SSLs.Id = ScanAddInID;
			EndIf;
			
			If ShouldUpdateScanAddInParameters And StrStartsWith(AddInAttributes.Version, "3.1.0.") Then
				ComponentObject_SSLs.Version = StrReplace(AddInAttributes.Version, "3.1.0.", "3.0.1.");
			EndIf;
			
			InfobaseUpdate.WriteObject(ComponentObject_SSLs);

			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();

		Except

			RollbackTransaction();
			// If add-in procession failed, try again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;

			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать компоненту %1 по причине:
					 |%2';
					|en = 'Couldn''t process the %1 add-in due to:
					|%2';"), RepresentationOfTheReference, ErrorProcessing.DetailErrorDescription(ErrorInfo()));

			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning, Selection.Ref.Metadata(), Selection.Ref, MessageText);

		EndTry;

	EndDo;

	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось обработать некоторые компоненты (пропущены): %1';
				|en = 'Couldn''t process some add-ins (skipped): %1';"),
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Information, Metadata.Catalogs.AddIns,,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Обработана очередная порция компонент: %1';
						|en = 'Yet another batch of add-ins is processed: %1';"),
			ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion

Function ShouldUpdateScanAddInParameters(SubsystemVersionAtStartUpdates)
	Return CommonClientServer.CompareVersions(SubsystemVersionAtStartUpdates, "3.1.10.179") < 0
		And Common.SubsystemExists("StandardSubsystems.FilesOperations")
EndFunction

#EndRegion

#EndIf