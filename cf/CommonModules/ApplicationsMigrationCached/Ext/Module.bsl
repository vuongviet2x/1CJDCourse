
#Region Internal

// Returns types of shared data references mapped by search fields.
//
// Returns:
//   Map of KeyAndValue - Collection of the following reference types:
//    * Key - Type
//    * Value - Boolean
//
Function TypesOfSharedDataToBeMatchedBySearchFields() Export
	
	Types = New Map;
	For Each MetadataObject In ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading() Do
		Types.Insert(TypeOfMetadataReferenceObject(MetadataObject), True);
	EndDo;
	
	Return Types;
	
EndFunction

// Returns types of shared data references mapped by a predefined name.
// 
// Returns: 
//	Map of KeyAndValue - Collection of the following reference types:
//	 * Key - Type
//	 * Value - Boolean
Function TypesOfMappedSharedDataByPredefinedName() Export
	
	Types = New Map;
	
	SeparatedMetadataObjects = ApplicationsMigrationCached.AreaDataModel();
	PermittedSharedData = ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading();
	
	For Each MetadataKind In TypesOfMetadataWithPredefined() Do
		For Each MetadataObject In MetadataKind Do
			If SeparatedMetadataObjects[MetadataObject] <> Undefined Then
				Continue;
			EndIf;
			If PermittedSharedData.Find(MetadataObject) <> Undefined Then
				Continue;
			EndIf;
			If MetadataObject.GetPredefinedNames().Count() <> 0 Then
				Types.Insert(TypeOfMetadataReferenceObject(MetadataObject), True);
			EndIf;
		EndDo;
	EndDo;
	
	Return Types;
	
EndFunction

// Returns a collection of separated metadata that is data.
//
// Returns:
//   Map of KeyAndValue - Collection of the following objects:
//   * Key - MetadataObject
//   * Value - Boolean
//
Function AreaDataModel() Export
	
	AreaDataModel = New Map;
	
	DontUse  = Metadata.ObjectProperties.CommonAttributeUse.DontUse;
	For Each Content In Metadata.CommonAttributes.DataAreaMainData.Content Do
		MetadataObject = Content.Metadata;
		
		// If an extension adds an object, the object belongs to the data area model regardless of the settings.
		// The code is required to export data from a shared infobase properly.
		//
		// The procedure for adding objects using extensions:
		// For shared infobases:
		//	a) Set the "DontUse" flag for extension objects.
		//	b) Unless the object's "Autousage" property is set to "DontUse".
		//	c) In this case, set the property to "Auto".
		// For separated infobases with the extension installed to an area:
		//	a) Set the property to the same value as the "Split" property in the common attribute.
		//	
		If Content.Use = DontUse 
			And MetadataObject.ConfigurationExtension() = Undefined Then
			Continue;
		EndIf;
		
		If Metadata.ScheduledJobs.Contains(MetadataObject)
			Or Metadata.ExternalDataSources.Contains(MetadataObject)
			Or Metadata.ExchangePlans.Contains(MetadataObject) Then
			Continue;
		EndIf;
		
		AreaDataModel.Insert(MetadataObject, True);
		
		If Metadata.CalculationRegisters.Contains(MetadataObject) Then
			For Each Recalculation In MetadataObject.Recalculations Do
				AreaDataModel.Insert(Recalculation, True);
			EndDo; 
		EndIf;
		
	EndDo;
	
	Use  = Metadata.ObjectProperties.CommonAttributeUse.Use;
	For Each Content In Metadata.CommonAttributes.DataAreaAuxiliaryData.Content Do
		MetadataObject = Content.Metadata;
		If Content.Use = Use 
			And Not Metadata.ScheduledJobs.Contains(MetadataObject)
			And Not Metadata.ExternalDataSources.Contains(MetadataObject)
			And Not Metadata.ExchangePlans.Contains(MetadataObject) Then
			AreaDataModel.Insert(MetadataObject, True);
			If Metadata.CalculationRegisters.Contains(MetadataObject) Then
				For Each Recalculation In MetadataObject.Recalculations Do
					AreaDataModel.Insert(Recalculation, True);
				EndDo; 
			EndIf;
		EndIf;
	EndDo;
	
	For Each Sequence In Metadata.Sequences Do
		For Each MetadataObject In Sequence.Documents Do
			If AreaDataModel.Get(MetadataObject) <> Undefined Then
				AreaDataModel.Insert(Sequence, True);
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	Return AreaDataModel;
	
EndFunction

// Returns metadata objects that participate in export.
//
// Returns:
//   Map of KeyAndValue - Collection of the following objects:
//   * Key - MetadataObject
//   * Value - Boolean
//
Function UnloadedObjects() Export
	
	UnloadedObjects = ApplicationsMigrationCached.AreaDataModel();
	
	For Each MetadataObject In ExportImportDataInternalEvents.GetTypesExcludedFromUploadUpload() Do
		UnloadedObjects.Delete(MetadataObject);
	EndDo;
	
	Return UnloadedObjects;
	
EndFunction

// Returns a collection of forbidden reference types.
//
// Returns:
//  Map of KeyAndValue - Collection of the following reference types:
//   * Key - Type
//   * Value - Boolean
//
Function ProhibitedTypesOfSharedData() Export
	
	Types = New Map;
	
	SeparatedMetadataObjects = ApplicationsMigrationCached.AreaDataModel();
	PermittedSharedData = ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading();
	TypesOfMetadataWithPredefined = TypesOfMetadataWithPredefined();
	
	MetadataKinds = New Array;
	MetadataKinds.Add(Metadata.Catalogs);
	MetadataKinds.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataKinds.Add(Metadata.ChartsOfAccounts);
	MetadataKinds.Add(Metadata.ChartsOfCalculationTypes);
	MetadataKinds.Add(Metadata.Documents);
	MetadataKinds.Add(Metadata.BusinessProcesses);
	MetadataKinds.Add(Metadata.Tasks);
	
	For Each MetadataKind In MetadataKinds Do
		HavePredefined = TypesOfMetadataWithPredefined.Find(MetadataKind) <> Undefined;
		For Each MetadataObject In MetadataKind Do
			If SeparatedMetadataObjects[MetadataObject] <> Undefined Then
				Continue;
			EndIf;
			If PermittedSharedData.Find(MetadataObject) <> Undefined Then
				Continue;
			EndIf;
			If Not HavePredefined Or MetadataObject.GetPredefinedNames().Count() = 0 Then
				Types.Insert(TypeOfMetadataReferenceObject(MetadataObject), True);
			EndIf;
		EndDo;
	EndDo;
	
	Return Types;
	
EndFunction

// Returns a collection of object reference types that are separated independently and together.
//
// Returns:
//	Map of KeyAndValue - Collection of the following reference types:
//	 * Key - Type
//	 * Value - Boolean	
Function TypesOfLinksToBeRecreated() Export
	
	Types = New Map;
	
	For Each CompositionItem In Metadata.CommonAttributes.DataAreaAuxiliaryData.Content Do
		If CompositionItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Use Then
			
			If Metadata.Catalogs.Contains(CompositionItem.Metadata)
				Or Metadata.ChartsOfCharacteristicTypes.Contains(CompositionItem.Metadata)
				Or Metadata.ExchangePlans.Contains(CompositionItem.Metadata)
				Or Metadata.Documents.Contains(CompositionItem.Metadata)
				Or Metadata.ChartsOfAccounts.Contains(CompositionItem.Metadata)
				Or Metadata.ChartsOfCalculationTypes.Contains(CompositionItem.Metadata)
				Or Metadata.BusinessProcesses.Contains(CompositionItem.Metadata)
				Or Metadata.Tasks.Contains(CompositionItem.Metadata) Then
				
				Types.Insert(TypeOfMetadataReferenceObject(CompositionItem.Metadata), True);
				
			EndIf;
		EndIf;
	EndDo;
	
	Return Types;
	
EndFunction

// Returns a collection of metadata objects separated together.
//
// Returns:
//   Map of KeyAndValue - Collection of the following metadata objects:
//   * Key - MetadataObject
//   * Value - Boolean
//
Function SharedMetadataObjects() Export
	
	Objects = New Map;
	
	For Each CompositionItem In Metadata.CommonAttributes.DataAreaAuxiliaryData.Content Do
		If CompositionItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Use Then
			Objects.Insert(CompositionItem.Metadata, True);
		EndIf;
	EndDo;
	
	Return Objects;
	
EndFunction

// Returns types of metadata that can have predefined items.
//
// Returns:
//   Array of MetadataObject - an array of object kinds.
//
Function TypesOfMetadataWithPredefined() Export
	
	MetadataKinds = New Array;
	MetadataKinds.Add(Metadata.Catalogs);
	MetadataKinds.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataKinds.Add(Metadata.ChartsOfAccounts);
	MetadataKinds.Add(Metadata.ChartsOfCalculationTypes);
	
	Return MetadataKinds;
	
EndFunction

#EndRegion

#Region Private

// Returns type of a reference metadata object.
// 
// Parameters:
// 	MetadataObject - MetadataObjectCatalog, MetadataObjectDocument, MetadataObjectChartOfCharacteristicTypes -
// 					 - MetadataObjectChartOfAccounts, MetadataObjectChartOfCalculationTypes, MetadataObjectExchangePlan - 
// 					 - MetadataObjectBusinessProcess, MetadataObjectTask - a metadata object.
// Returns:
// 	TypeDescription - reference type details.
Function TypeOfMetadataReferenceObject(MetadataObject) 
	
	Return MetadataObject.StandardAttributes.Ref.Type.Types()[0];
	
EndFunction

#EndRegion
