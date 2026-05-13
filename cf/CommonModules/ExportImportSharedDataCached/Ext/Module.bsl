////////////////////////////////////////////////////////////////////////////////
// "Data import and export" subsystem.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns dependencies of shared metadata objects.
// If a metadata object contains a field whose value type is a reference to another metadata object,
// it is considered that it depends on this field.
//
// Returns:
//  FixedMap of KeyAndValue:
//    * Key - String - a full name of the dependent metadata object,
//    * Value - Array of String - full names of metadata objects, on which this metadata object depends.
//
Function DependenciesOfUnsharedMetadataObjects() Export
	
	Cache = New Map();
	
	TypesOfCommonClassifiers = ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading();
	
	For Each TypeOfGeneralClassifier In TypesOfCommonClassifiers Do
		
		Manager = Common.ObjectManagerByFullName(TypeOfGeneralClassifier.FullName());
		
		NaturalKeyFields = Manager.NaturalKeyFields();
		For Each NaturalKeyField In NaturalKeyFields Do
			
			FieldTypes = Undefined;
			
			For Iterator_SSLy = 0 To TypeOfGeneralClassifier.StandardAttributes.Count() - 1 Do
				
				// Searching standard attributes
				StandardAttribute = TypeOfGeneralClassifier.StandardAttributes[Iterator_SSLy];
				If StandardAttribute.Name = NaturalKeyField Then
					FieldTypes = StandardAttribute.Type;
				EndIf;
				
			EndDo;
			
			// Search in attributes.
			Attribute = TypeOfGeneralClassifier.Attributes.Find(NaturalKeyField);
			If Attribute <> Undefined Then
				FieldTypes = Attribute.Type;
			EndIf;
			
			// Searching common attributes
			CommonAttribute = Metadata.CommonAttributes.Find(NaturalKeyField);
			If CommonAttribute <> Undefined Then
				For Each CommonAttribute In Metadata.CommonAttributes Do
					If CommonAttribute.Content.Find(TypeOfGeneralClassifier) <> Undefined Then
						FieldTypes = CommonAttribute.Type;
					EndIf;
				EndDo;
			EndIf;
			
			If FieldTypes = Undefined Then
				
				Raise StrTemplate(NStr("ru = 'Поле %1 не может использоваться в качестве поля естественного ключа объекта %2:
                          |поле объекта не обнаружено';
							|en = 'Cannot use the %1 field as a natural key field of %2 object:
							|the object field is not found';", Metadata.DefaultLanguage.LanguageCode),
					NaturalKeyField,
					TypeOfGeneralClassifier.FullName());
				
			EndIf;
			
			For Each FieldType In FieldTypes.Types() Do
				
				If Not CommonCTL.IsPrimitiveType(FieldType) And Not CommonCTL.IsEnum(ExportImportDataInternal.MetadataObjectByRefType(FieldType)) Then
					
					If FieldType = Type("ValueStorage") Then
						
						Raise StrTemplate(
							NStr("ru = 'Поле %1 не может использоваться в качестве поля естественного ключа объекта %2: использование
                                  |значений типа %3 в качестве полей естественного ключа не поддерживается';
									|en = 'Cannot use the %1 field as a natural key field of the %2 object:
									|using the %3 type values as natural keys is not supported';", Metadata.DefaultLanguage.LanguageCode),
							NaturalKeyField,
							TypeOfGeneralClassifier.FullName(),
							"ValueStorage");
						
					EndIf;
					
					Ref = New(FieldType);
					ObjectMetadata = Ref.Metadata(); // MetadataObject
					If TypesOfCommonClassifiers.Find(ObjectMetadata) <> Undefined Then
						GeneralClassifier = Cache.Get(TypeOfGeneralClassifier.FullName()); // Array
						If GeneralClassifier <> Undefined Then
							GeneralClassifier.Add(ObjectMetadata.FullName());
						Else
							NewArray = New Array();
							NewArray.Add(ObjectMetadata.FullName());
							Cache.Insert(TypeOfGeneralClassifier.FullName(), NewArray);
						EndIf;
						
					Else
						
						Raise StrTemplate(
							NStr("ru = 'Поле %1 не может использоваться в качестве поля естественного ключа объекта %2:
                                  |в качестве типа поля может использоваться объект %3, который не включен в набор
                                  |общих данных через переопределяемую процедуру
                                  |%4';
									|en = 'Cannot use the %1 field as a natural key field of the %2 object:
									|the field type might be based on the %3 object, which is not included
									|in the common data set through overridable procedure
									|%4';", Metadata.DefaultLanguage.LanguageCode),
							NaturalKeyField,
							TypeOfGeneralClassifier.FullName(),
							ObjectMetadata.FullName(),
							"ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefMappingOnExport");
						
					EndIf;
					
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	Return New FixedMap(Cache);
	
EndFunction

// Returns rules for controlling references to shared data in separated ones upon export.
//
// Returns:
//  FixedMap of KeyAndValue:
//    * Key - String - full name of a metadata object, for which it is required
//       to control references to shared data in the separated data upon export.
//    * Value - Array of String - an array of object field names, in which you need to control
//       the presence of references to shared data in separated data during export.
//
Function ControlReferencesToUnsharedDataInPartitionedDataWhenUnloading() Export
	
	Cache = New Map();
	
	TypesOfSharedData = ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading();
	ObjectsExcludedFromUnloadingLoading = ExportImportDataInternalEvents.GetTypesExcludedFromUploadUpload();
	ObjectsThatDoNotRequireReferenceMapping = ExportImportDataInternalEvents.GetSharedDataTypesThatDoNotRequireLinkMappingWhenLoading();
	
	LocalCacheOfDelimiterCompositions = New Map();
	
	For Each MetadataObject In ExportImportDataInternal.AllConstants() Do
		FillReferenceControlCacheForUnsharedDataWhenUnloadingForConstants(
			Cache, MetadataObject, TypesOfSharedData, ObjectsExcludedFromUnloadingLoading, ObjectsThatDoNotRequireReferenceMapping,
				LocalCacheOfDelimiterCompositions);
	EndDo;
	
	For Each MetadataObject In ExportImportDataInternal.AllReferenceData() Do
		FillReferenceControlCacheForUnsharedDataWhenUnloadingForObjects(
			Cache, MetadataObject, TypesOfSharedData, ObjectsExcludedFromUnloadingLoading, ObjectsThatDoNotRequireReferenceMapping,
				LocalCacheOfDelimiterCompositions);
	EndDo;
	
	For Each MetadataObject In ExportImportDataInternal.AllRecordSets() Do
		FillReferenceControlCacheForUnsharedDataWhenUnloadingForRecordsets(
			Cache, MetadataObject, TypesOfSharedData, ObjectsExcludedFromUnloadingLoading, ObjectsThatDoNotRequireReferenceMapping,
				LocalCacheOfDelimiterCompositions);
	EndDo;
	
	Return New FixedMap(Cache);
	
EndFunction

#EndRegion

#Region Private

Procedure FillReferenceControlCacheForUnsharedDataWhenUnloadingForConstants(Cache, Val MetadataObject, Val TypesOfSharedData, Val ObjectsExcludedFromUnloadingLoading, Val ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition)
	
	If ObjectsExcludedFromUnloadingLoading.Find(MetadataObject) = Undefined 
	   And ExportImportSharedData.MetadataObjectIsSeparatedByAtLeastOneSeparator(MetadataObject, LocalCacheOfDelimiterComposition) Then
		
		FillCacheOfReferenceControlForUnsharedDataWhenUnloadingByFieldOfSplitObject(
			Cache, MetadataObject, MetadataObject, TypesOfSharedData, ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition);
		
	EndIf;
	
EndProcedure

Procedure FillReferenceControlCacheForUnsharedDataWhenUnloadingForObjects(Cache, Val MetadataObject, Val TypesOfSharedData, Val ObjectsExcludedFromUnloadingLoading, Val ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition)
	
	If ObjectsExcludedFromUnloadingLoading.Find(MetadataObject) = Undefined 
	   And ExportImportSharedData.MetadataObjectIsSeparatedByAtLeastOneSeparator(MetadataObject, LocalCacheOfDelimiterComposition) Then
		
		For Each Attribute In MetadataObject.Attributes Do
			
			FillCacheOfReferenceControlForUnsharedDataWhenUnloadingByFieldOfSplitObject(
				Cache, MetadataObject, Attribute, TypesOfSharedData, ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition);
			
		EndDo;
		
		For Each TabularSection In MetadataObject.TabularSections Do
			
			For Each Attribute In TabularSection.Attributes Do
				
				FillCacheOfReferenceControlForUnsharedDataWhenUnloadingByFieldOfSplitObject(
					Cache, MetadataObject, Attribute, TypesOfSharedData, ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition);
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure FillReferenceControlCacheForUnsharedDataWhenUnloadingForRecordsets(Cache, Val MetadataObject, Val TypesOfSharedData, Val ObjectsExcludedFromUnloadingLoading, Val ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition)
	
	If ObjectsExcludedFromUnloadingLoading.Find(MetadataObject) = Undefined 
	   And ExportImportSharedData.MetadataObjectIsSeparatedByAtLeastOneSeparator(MetadataObject, LocalCacheOfDelimiterComposition) Then
		
		For Each Dimension In MetadataObject.Dimensions Do
			
			FillCacheOfReferenceControlForUnsharedDataWhenUnloadingByFieldOfSplitObject(
				Cache, MetadataObject, Dimension, TypesOfSharedData, ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition);
			
		EndDo;
		
		For Each Resource In MetadataObject.Resources Do
			
			FillCacheOfReferenceControlForUnsharedDataWhenUnloadingByFieldOfSplitObject(
				Cache, MetadataObject, Resource, TypesOfSharedData, ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition);
			
		EndDo;
		
		For Each Attribute In MetadataObject.Attributes Do
			
			FillCacheOfReferenceControlForUnsharedDataWhenUnloadingByFieldOfSplitObject(
				Cache, MetadataObject, Attribute, TypesOfSharedData, ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterComposition);
			
		EndDo;
		
	EndIf;
	
EndProcedure


// Parameters:
// 	Cache - Map - Key and value:
//	 * Key - String - full metadata name.
//	 * Value - Array of String - metadata names.
Procedure FillCacheOfReferenceControlForUnsharedDataWhenUnloadingByFieldOfSplitObject(Cache, Val MetadataObject, Val Field, Val TypesOfSharedData, Val ObjectsThatDoNotRequireReferenceMapping, LocalCacheOfDelimiterCompositions)
	
	FieldTypes = Field.Type;
	ObjectName = MetadataObject.FullName();
	
	If CommonCTL.IsRefsTypesSet(FieldTypes) Then
		
		// The attribute type is either "AnyRef" or a flexible type like "CatalogRef.*", "DocumentRef.*", etc.
		// In this stage, validation is skipped as the developer can imply any reference to a separated object.
		// The information on the object and attribute is cached and later used to validate data that will actually be imported.
		//
		// 
		// 
		//
		
		TypesNames = Cache.Get(ObjectName);
		If TypesNames = Undefined Then
			TypesNames = New Array;
			Cache.Insert(ObjectName, TypesNames);
		EndIf;
		
		TypesNames.Add(Field.FullName());
		
	Else
		
		For Each FieldType In FieldTypes.Types() Do
			
			If Not CommonCTL.IsPrimitiveType(FieldType) And Not (FieldType = Type("ValueStorage")) Then
				
				RefMetadata = ExportImportDataInternal.MetadataObjectByRefType(FieldType);
				
				If TypesOfSharedData.Find(RefMetadata) = Undefined
						And Not CommonCTL.IsEnum(RefMetadata)
						And Not ExportImportSharedData.MetadataObjectIsSeparatedByAtLeastOneSeparator(RefMetadata, LocalCacheOfDelimiterCompositions) 
						And RefMetadata.ConfigurationExtension() = Undefined Then
					
					If ObjectsThatDoNotRequireReferenceMapping.Find(RefMetadata) = Undefined Then
						
						RaiseExceptionIfSplitDataContainsReferencesToUnsharedDataWithoutReferenceMatchingSupport(
							MetadataObject,
							Field.FullName(),
							RefMetadata,
							False);
						
					Else
						
						TypesNames = Cache.Get(ObjectName);
						If TypesNames = Undefined Then
							TypesNames = New Array;
							Cache.Insert(ObjectName, TypesNames);
						EndIf;
						
						TypesNames.Add(Field.FullName());
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure RaiseExceptionIfSplitDataContainsReferencesToUnsharedDataWithoutReferenceMatchingSupport(Val MetadataObject, Val FieldName, Val RefMetadata, Val OnExport)
	
	If CommonCTL.IsConstant(MetadataObject) Then
		
		ErrorText = StrTemplate(
			NStr("ru = 'В качестве значения разделенной константы %1 используются ссылки на
                  |неразделенный объект %2';
					|en = 'References to undivided object %2
					|are used as a value of divided constant %1';", Metadata.DefaultLanguage.LanguageCode),
			MetadataObject.FullName(),
			RefMetadata.FullName());
		
	ElsIf CommonCTL.IsRefData(MetadataObject) Then
		
		ErrorText = StrTemplate(
			NStr("ru = 'В качестве значения реквизита %1 разделенного объекта %2 используются ссылки на
                  |неразделенный объект %3';
					|en = 'References to undivided object %3
					|are used as a value of attribute %1 of divided object %2';", Metadata.DefaultLanguage.LanguageCode),
			FieldName,
			MetadataObject.FullName(),
			RefMetadata.FullName());
		
	ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
		
		ErrorText = StrTemplate(
			NStr("ru = 'В качестве значения измерения, ресурса или реквизита %1 разделенного набора записей %2 используются ссылки на
                  |неразделенный объект %3';
					|en = 'References to
					|undivided object %3are used as a value of dimension, resource or attribute %1 of divided record set %2';", Metadata.DefaultLanguage.LanguageCode),
			FieldName,
			MetadataObject.FullName(),
			RefMetadata.FullName());
		
	Else
		
		Raise StrTemplate(NStr("ru = 'Неожиданный объект метаданных: %1';
										|en = 'Unexpected metadata object: %1';", Metadata.DefaultLanguage.LanguageCode),
			MetadataObject.FullName());
		
	EndIf;
	
	If OnExport Then
		
		ErrorText = ErrorText + " "
			+ NStr("ru = '(в качестве типа значения для объекта установлен составной тип данных,
                  |который может содержать ссылки как на разделенные данные, так и на неразделенные,
                  |но при выгрузке была диагностирована попытка выгрузки ссылки на неразделенный объект).';
					|en = '(composite data type is set as a value type for the object
					|which can contain references to both separated and shared data,
					|but an attempt of export of the reference to undivided object was detected when exporting).';", Metadata.DefaultLanguage.LanguageCode);
		
	Else
		
		ErrorText = ErrorText + ".";
		
	EndIf;
	
	ErrorAddition = StrTemplate(
		NStr("ru = 'При этом неразделенный объект %1 не включен в состав типов общих данных,
              |для которых возможно выполнение сопоставления ссылок при выгрузке и загрузке.
              |Данная ситуация является недопустимой, т.к. при загрузке выгруженных данных в другую ИБ
              |будут загружены ""битые"" ссылки на объект %1.
              |
              |Для исправления ситуации требуется реализовать для объекта %1 механизм определения
              |полей, однозначно определяющих естественный ключ объекта и включить объект %1 в состав
              |типов общих данных, для которых возможно выполнение сопоставления ссылок при
              |выгрузке и загрузке, указав объект метаданных %1 в процедуре
              |%2.';
				|en = 'The shared %1 object does not belong to shared data types,
				|for which references can be mapped upon export and import.
				|This situation is not allowed as ""damaged"" references to the %1 object will be imported
				|when you import exported data to another infobase.
				|
				|To fix this situation, implement a tool determining
				|fields that uniquely identify the object natural key for the %1 object. Include the %1 object in
				|shared data types, for which references can be mapped upon export and import.
				|To do it, specify the %1 metadata object in the procedure
				|%2.';", Metadata.DefaultLanguage.LanguageCode),
		RefMetadata.FullName(),
		"ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefMappingOnExport");
	
	If Not OnExport Then
		
		ErrorAddition = ErrorAddition + Chars.LF + StrTemplate(
			NStr("ru = 'Если корректное сопоставление ссылок на неразделенные данные в ИБ, из которой выгружены
                  |данные и ИБ, в которую они загружаются, гарантируется с помощью других механизмов, необходимо
                  |указать объект метаданных %1 в процедуре
                  |%2.';
					|en = 'If other tools ensure the correct mapping of references to shared data in the infobase, from which data and the infobase, to which they are imported, are exported,
					|specify the %1 metadata object in the procedure
					|%2.';", Metadata.DefaultLanguage.LanguageCode),
			RefMetadata.FullName(),
			"ExportImportDataOverridable.OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport");
		
	EndIf;
	
	Raise ErrorText + Chars.LF + Chars.CR + ErrorAddition;
	
EndProcedure

#EndRegion