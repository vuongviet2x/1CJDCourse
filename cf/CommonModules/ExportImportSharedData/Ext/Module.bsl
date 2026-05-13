////////////////////////////////////////////////////////////////////////////////
// "Data import and export" subsystem.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns type dependencies upon reference substitute.
// 
// Returns: 
//  FixedMap of KeyAndValue - Returns type dependencies upon reference substitute.:
// * Key - String
// * Value - Array of String
Function TypeDependenciesWhenReplacingReferences() Export
	
	Return ExportImportSharedDataCached.DependenciesOfUnsharedMetadataObjects();
	
EndFunction

// Whether a metadata object is separated with one or more delimiters.
// 
// Parameters: 
//	MetadataObject - MetadataObjectExchangePlan, MetadataObjectEnum - Metadata object.
//	Cache - Map of KeyAndValue:
//	 * Key - String
//	 * Value - CommonAttributeContent
// 
// Returns: 
//	Boolean - Whether a metadata object is separated with one or more delimiters.
Function MetadataObjectIsSeparatedByAtLeastOneSeparator(Val MetadataObject, Cache) Export
	
	Result = Cache.Get(MetadataObject);
	If Result <> Undefined Then
		Return Result;
	EndIf;
	
	For Each CommonAttribute In Metadata.CommonAttributes Do
		
		If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
			
			AutoUse = (CommonAttribute.AutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse.Use);
			
			Content = Cache.Get(CommonAttribute.FullName());
			If Content = Undefined Then
				Content = CommonAttribute.Content;
				Cache.Insert(CommonAttribute.FullName(), Content);
			EndIf;
			
			CompositionItem = Content.Find(MetadataObject);
			If CompositionItem <> Undefined Then
				
				If CompositionItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Use
						Or (AutoUse And CompositionItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Auto) Then
					
					Cache.Insert(MetadataObject, True);
					Return True;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Cache.Insert(MetadataObject, False);
	Return False;
	
EndFunction

#Region InternalEventsHandlers

// Fills in an array of types for which the reference annotation
// in files must be used upon export.
//
// Parameters:
//  Types - Array of MetadataObject - metadata objects.
//
Procedure OnFillTypesThatRequireRefAnnotationOnImport(Types) Export
	
	TypesOfSharedData = ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading();
	For Each TypeOfSharedData In TypesOfSharedData Do
		Types.Add(TypeOfSharedData);
	EndDo;
	
EndProcedure

// Called upon registration of arbitrary data export handlers.
//
// Parameters:
//   HandlersTable - ValueTable - This procedure requires
//  that you add information on the arbitrary
//  data import handlers being registered to the value table. Columns::
//    MetadataObject - MetadataObject - Metadata object during whose data export the handler
//      is called.
//    Handler - CommonModule - Common module that contains the implementation of a custom
//      data export handler.
//      The list of export procedures to be implemented in the handler depends on the values in the following
//      value table columns:
//    Version - String - Version of the data import/export handler API supported by the handler.
//      BeforeExportType - Boolean - Indicates whether the handler must be called before exporting
//    all infobase objects associated with this metadata
//      object. If set to True, the common module of the handler must
//      include the BeforeExportType() exportable procedure that supports the following parameters:
//      Container - DataProcessorObject.ExportImportDataContainerManager - Container
//      manager used for data export. For more information, see the comment
//        to the ExportImportDataContainerManager data processor API.
//          Serializer - XDTOSerializer - Initialized with
//          reference annotation support. If an arbitrary export handler requires
//        additional data export, use
//          XDTOSerializer passed to the BeforeExportType() procedure as the
//          Serializer parameter value, not obtained using the XDTOSerializer global
//          context property.
//          MetadataObject - MetadataObject - Handler is called
//          before the object data is exported.
//        Cancel - Boolean - If the parameter value is set to True
//          in the BeforeExportType() procedure, the objects corresponding
//        to the current metadata object are not exported.
//          BeforeExportObject - Boolean - Indicates whether the handler must be called before exporting a specific
//          Infobase object. If set to
//    True, the common module of the handler must include the
//      BeforeExportObject() exportable procedure supporting the following parameters:
//      Container - DataProcessorObject - ExportImportDataContainerManager - Container
//      manager used for data export. For more information, see the comment
//        to the ExportImportDataContainerManager data processor API.
//          ObjectExportManager -
//          Export manager of the current object.
//        For more information, see the comment to the ExportImportDataInfobaseDataExportManager data processor API. Parameter is passed only
//          if procedures of handlers with version not earlier than 1.0.0.1 specified upon registration are called.
//          Serializer - XDTOSerializer - serializer initialized with reference annotation support. In case
//          if the arbitrary export handler requires exporting additional data,
//        use XDTOSerializer passed to the BeforeExportObject() procedure as a value of the
//          Serializer parameter and not obtained using the XDTOSerializer global context property.
//          Object - ManagerOfConstantValue, CatalogObject, DocumentObject,
//          BusinessProcessObject, TaskObject, ChartOfAccountsObject, ExchangePlanObject,
//          ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet,
//          AccumulationRegisterRecordSet, AccountingRegisterRecordSet,
//        CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet -
//          Infobase data object imported after the handler is called.
//          Value passed to the BeforeExportObject() procedure. It can be
//          changed as the Object parameter value in the BeforeExportObject() handler. The changes will be reflected
//          in the object serialization in export files, but not in the infobase.
//          Artifacts - Array of XDTODataObject - Set of additional information logically associated with the object
//          but not contained in it (object artifacts). Artifacts must be generated inside the BeforeExportObject() handler
//          and added to the array passed as the Artifacts parameter value.
//          Each artifact must be an XDTO data object, for whose type an
//          abstract {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact XDTO type is used as the base type. You can use
//        XDTO packages that are not included in the ExportImportData subsystem.
//          The artifacts generated in the BeforeExportObject() procedure will be available in
//          the data import handler procedures (see the comment to the OnRegisterDataImportHandlers() procedure).
//          Cancel - Boolean - If you set this parameter value to True in the BeforeExportObject() procedure,
//          the object that called a handler will not be exported.
//          AfterExportType - Boolean - Flag specifying whether the handler is called after all
//          infobase objects associated with this metadata object are exported. If set to True,
//          the common handler module must include the AfterExportType() exportable procedure, supporting the following parameters:
//          Container - DataProcessorObject.ExportImportDataContainerManager - Container
//        manager used for data export. For more information, see the comment
//           to the ExportImportDataContainerManager data processor API.
//           Serializer - XDTOSerializer - Serializer initialized with reference
//    annotation support. In case if the arbitrary export handler requires
//      exporting additional data, use XDTOSerializer
//      passed to the AfterExportType() procedure as
//      the Serializer parameter value, not obtained using the XDTOSerializer
//        global context property.
//          MetadataObject - MetadataObject - Handler is called after the object
//          data is exported.
//        
//          
//          
//          
//          
//          
//        
//          
//
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	TypesOfSharedData
		= ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading();
	
	For Each TypeOfSharedData In TypesOfSharedData Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = TypeOfSharedData;
		NewHandler.Handler = ExportImportSharedData;
		NewHandler.BeforeUnloadingType = True;
		NewHandler.AfterExportObject = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
		
	EndDo;
	
	ObjectsForMonitoringUnsharedDataWhenUnloading
		= ExportImportSharedDataCached.ControlReferencesToUnsharedDataInPartitionedDataWhenUnloading();
	
	For Each ObjectForMonitoringUnsharedDataDuringUpload In ObjectsForMonitoringUnsharedDataWhenUnloading Do
		
		MetadataObject = Metadata.FindByFullName(ObjectForMonitoringUnsharedDataDuringUpload.Key);
		
		If TypesOfSharedData.Find(MetadataObject) = Undefined Then // Otherwise, a handler is already registered for the object
			
			NewHandler = HandlersTable.Add();
			NewHandler.MetadataObject = MetadataObject;
			NewHandler.Handler = ExportImportSharedData;
			NewHandler.AfterExportObject = True;
			NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Called before data type export.
// See OnRegisterDataExportHandlers.
// Parameters:
//   Container - DataProcessorObject.ExportImportDataContainerManager
//   Serializer - XDTOSerializer
//   MetadataObject - MetadataObject
//   Cancel - Boolean
//
Procedure BeforeUnloadingType(Container, Serializer, MetadataObject, Cancel) Export
	
	If Not CommonCTL.IsRefData(MetadataObject) Then 
		Raise NStr("ru = 'Замена ссылок доступна только в ссылочных данных';
								|en = 'References can be replaced only in the reference data';");
	EndIf;
	
	ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
	NaturalKeyFields = ObjectManager.NaturalKeyFields();
	
	CheckNaturalKeyFields(MetadataObject, NaturalKeyFields);
	CheckForDuplicatesOfNaturalKeys(Container, MetadataObject, NaturalKeyFields);
	
EndProcedure

// Called after data object export. See the details in the OnRegisterDataExportHandlers.
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - container manager of data export.
//	ObjectExportManager - DataProcessorObject.ExportImportDataInfobaseDataExportManager -
//	 an export manager of the current object.
//	Serializer - XDTOSerializer - a serializer initialized with reference annotation support.
//	Object - ConstantValueManager, CatalogObject, DocumentObject, BusinessProcessObject, TaskObject - 
//		   - ChartOfAccountsObject, ExchangePlanObject, ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject -  
//		   - CalculationRegisterRecordSet, AccountingRegisterRecordSet, AccumulationRegisterRecordSet - 
//		   - InformationRegisterRecordSet - a data object.
//	Artifacts - Array of XDTODataObject - additional information set 
Procedure AfterExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts) Export
	
	MetadataObject = Object.Metadata();
	FullMetadataObjectName = MetadataObject.FullName();
	
	FieldsToControlReferencesToUnsharedData =
		ExportImportSharedDataCached.ControlReferencesToUnsharedDataInPartitionedDataWhenUnloading().Get(
			FullMetadataObjectName);
	
	If FieldsToControlReferencesToUnsharedData <> Undefined Then
		ControlOfReferencesToUnsharedDataDuringUnloading(Container, Object, FieldsToControlReferencesToUnsharedData);
	EndIf;
	
	If Container.AdditionalProperties.GeneralDataRequiringLinkMatching.Find(MetadataObject) <> Undefined Then
		
		If Not CommonCTL.IsRefData(MetadataObject) Then 
			Raise NStr("ru = 'Подмена ссылок доступна только в ссылочных данных';
									|en = 'Reference substitution is only available for reference data';");
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(FullMetadataObjectName);
		
		NaturalKeyFields = ObjectManager.NaturalKeyFields();
		
		NaturalKey = New Structure();
		For Each NaturalKeyField In NaturalKeyFields Do
			NaturalKey.Insert(NaturalKeyField, Object[NaturalKeyField]);
		EndDo;
		
		ObjectExportManager.YouNeedToMatchLinkWhenDownloading(Object.Ref, NaturalKey);
		
	EndIf;
	
EndProcedure

Procedure ControlUseOfReferencesToUnsharedDataInPartitioned() Export
	
	Try
		
		ExportImportSharedDataCached.ControlReferencesToUnsharedDataInPartitionedDataWhenUnloading();
		
	Except
		
		ErrorText = CloudTechnology.ShortErrorText(ErrorInfo());
		Raise StrTemplate(NStr("ru = 'Обнаружены ошибки в структуре метаданных конфигурации: %1';
										|en = 'Errors found in the structure of metadata configuration: %1';", Metadata.DefaultLanguage.LanguageCode),
			ErrorText);
		
	EndTry;
	
EndProcedure

Procedure ControlFillingOfNaturalKeyFieldsForUnsharedObjects() Export
	
	Try
		
		ExportImportSharedDataCached.DependenciesOfUnsharedMetadataObjects();
		
	Except
		
		ErrorText = CloudTechnology.ShortErrorText(ErrorInfo());
		Raise StrTemplate(NStr("ru = 'Обнаружены ошибки в структуре метаданных конфигурации: %1';
										|en = 'Errors found in the structure of metadata configuration: %1';", Metadata.DefaultLanguage.LanguageCode),
			ErrorText);
		
	EndTry;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Checks the objects for natural key duplicates.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager
//	MetadataObject - MetadataObject - a metadata object to be exported.
//	NaturalKeyFields - Array of String - an array of strings with natural key names.
//
Procedure CheckForDuplicatesOfNaturalKeys(Val Container, Val MetadataObject, Val NaturalKeyFields)
	
	TableName = MetadataObject.FullName();
	
	QueryText = StrReplace(
	"SELECT
	|	&SelectionFields1,
	|	MAX(_Table_OfCatalog_First.Ref) AS Ref,
	|	COUNT(*) AS Cnt
	|INTO TTDoubles
	|FROM
	|	&Table AS _Table_OfCatalog_First
	|
	|GROUP BY
	|	&GroupFields
	|
	|HAVING
	|	COUNT(*) > 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 5
	|	PRESENTATION(_Table_OfCatalog_First.Ref) AS ItemPresentation
	|FROM
	|	TTDoubles AS TTDoubles
	|		INNER JOIN &Table AS _Table_OfCatalog_First
	|		ON TTDoubles.Ref <> _Table_OfCatalog_First.Ref
	|		AND &AdditionalRequestText", "&Table", TableName);
	
	AdditionalRequestText = "";
	FieldSelectionText_ = "";
	
	For Each NaturalKeyField In NaturalKeyFields Do 
		
		FieldSelectionText_ = FieldSelectionText_ + StrTemplate("_Table_OfCatalog_First.%1, 
			|", NaturalKeyField);
		
		AdditionalRequestText = AdditionalRequestText
			+ StrTemplate("AND (_Table_OfCatalog_First.%1 = TTDoubles.%1) ", NaturalKeyField);
		
	EndDo;
	
	QueryText = StrReplace(QueryText, "&SelectionFields1,", FieldSelectionText_);
	QueryText = StrReplace(
		QueryText, "&GroupFields", Mid(FieldSelectionText_, 1, StrLen(FieldSelectionText_) - 3));
	QueryText = StrReplace(
		QueryText, "AND &AdditionalRequestText", AdditionalRequestText);
	
	Query = New Query;
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	ItemsList = StrConcat(
		QueryResult.Unload().UnloadColumn("ItemPresentation"), Chars.LF);
	KeysNames = RepresentationOfNaturalKeyFields(MetadataObject, NaturalKeyFields);
	
	// Populate the warning text.
	MessageText = StrTemplate(NStr("ru = 'У некоторых объектов %1: 
		|%2
		|
		|дублируются поля:
		|%3.
		|
		|Рекомендуется выполнить удаление дублирующихся элементов.';
		|en = 'Several objects %1:
		|%2
		|
		|have duplicate fields:
		|%3.
		|
		|We recommend that you delete duplicate items.';"),
		TableName, ItemsList, KeysNames);
	
	Container.AddWarning(MessageText);
	
EndProcedure

// Checks a metadata object for natural keys.
//
// Parameters:
//	MetadataObject - MetadataObject - a metadata object to be exported.
//	NaturalKeyFields - Array of String - an array of strings with natural key names.
//
Procedure CheckNaturalKeyFields(Val MetadataObject, Val NaturalKeyFields)
	
	If NaturalKeyFields = Undefined Or NaturalKeyFields.Count() = 0 Then
		
		Raise StrTemplate(NStr("ru = 'Для типа данных %1 не указаны естественные ключи для замены ссылок.
                  |Проверьте обработчик %2.';
					|en = 'Natural keys for reference replacement are not specified for the %1 data type.
					|Check the %2 handler.';"),
			MetadataObject.FullName(),
			"WhenDeterminingTypesThatRequireUploadingToLocalVersion");
		
	EndIf;
	
EndProcedure

Function RepresentationOfNaturalKeyFields(MetadataObject, NaturalKeyFields)
	
	FieldsPresentation = New Array();
	
	NamesOfPropertiesOfDetails = New Array();
	NamesOfPropertiesOfDetails.Add("StandardAttributes");
	
	If Not CommonCTL.IsEnum(MetadataObject) Then
		NamesOfPropertiesOfDetails.Add("Attributes");
	EndIf;
	
	If CommonCTL.IsTask(MetadataObject) Then
		NamesOfPropertiesOfDetails.Add("AddressingAttributes");
	EndIf;
	
	For Each NaturalKeyField In NaturalKeyFields Do
		
		AttributeSynonym = "";
		PropsFound = False;
		
		For Each PropertyName In NamesOfPropertiesOfDetails Do
			
			For Each AttributeObject In MetadataObject[PropertyName] Do
				
				If AttributeObject.Name = NaturalKeyField Then
					
					AttributeSynonym = AttributeObject.Synonym;
					PropsFound = True;
					
					Break;
					
				EndIf;
				
			EndDo;
			
			If PropsFound Then
				Break;
			EndIf;
			
		EndDo;
		
		FieldPresentation = ?(IsBlankString(AttributeSynonym),
			NaturalKeyField,
			StrTemplate("%1 (%2)", AttributeSynonym, NaturalKeyField));
		FieldsPresentation.Add(FieldPresentation);
		
	EndDo;
	
	Return StrConcat(FieldsPresentation, Chars.LF);
	
EndFunction

Procedure ControlOfReferencesToUnsharedDataDuringUnloading(Container, Val Object, FieldsToControlReferencesToUnsharedData)
	
	MetadataObject = Object.Metadata();
	FullMetadataObjectName = MetadataObject.FullName();
	ObjectNameStructure = StrSplit(FullMetadataObjectName, ".");
	
	For Each FieldForControllingReferencesToUnsharedData In FieldsToControlReferencesToUnsharedData Do
		
		FieldNameStructure = StrSplit(FieldForControllingReferencesToUnsharedData, ".");
		
		If ObjectNameStructure[0] <> FieldNameStructure[0] Or ObjectNameStructure[1] <> FieldNameStructure[1] Then
			
			Raise NStr("ru = 'Некорректный кэш контроля неразделенных данных при выгрузке.';
									|en = 'Invalid shared data control cache on export.';");
			
		EndIf;
		
		If CommonCTL.IsConstant(MetadataObject) Then
			
			ControllingReferenceToUnsharedDataWhenUnloading(
				Container,
				Object.Value,
				Object,
				MetadataObject,
				FieldForControllingReferencesToUnsharedData);
			
		ElsIf CommonCTL.IsRefData(MetadataObject) Then
			
			If FieldNameStructure[2] = "Attribute" Or FieldNameStructure[2] = "Attribute" Then // Not localizable.
				
				ControllingReferenceToUnsharedDataWhenUnloading(
					Container,
					Object[FieldNameStructure[3]],
					Object,
					MetadataObject,
					FieldForControllingReferencesToUnsharedData);
				
			ElsIf FieldNameStructure[2] = "TabularSection" Or FieldNameStructure[2] = "TabularSection" Then // Not localizable.
				
				TabularSectionName = FieldNameStructure[3];
				
				If FieldNameStructure[4] = "Attribute" Or FieldNameStructure[4] = "Attribute" Then // Not localizable.
					
					AttributeName = FieldNameStructure[5];
					
					For Each LineOfATabularSection In Object[TabularSectionName] Do
						
						ControllingReferenceToUnsharedDataWhenUnloading(
							Container,
							LineOfATabularSection[AttributeName],
							Object,
							MetadataObject,
							FieldForControllingReferencesToUnsharedData);
						
					EndDo;
					
				Else
					
					Raise NStr("ru = 'Некорректный кэш контроля неразделенных данных при выгрузке.';
											|en = 'Invalid shared data control cache on export.';");
					
				EndIf;
				
			Else
				
				Raise NStr("ru = 'Некорректный кэш контроля неразделенных данных при выгрузке.';
										|en = 'Invalid shared data control cache on export.';");
				
			EndIf;
			
		ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
			
			If FieldNameStructure[2] = "Dimension" Or FieldNameStructure[2] = "Dimension"
					Or FieldNameStructure[2] = "Resource" Or FieldNameStructure[2] = "Resource"
					Or FieldNameStructure[2] = "Attribute" Or FieldNameStructure[2] = "Attribute" Then // Not localizable.
				
				For Each Record In Object Do
					
					ControllingReferenceToUnsharedDataWhenUnloading(
						Container,
						Record[FieldNameStructure[3]],
						Object,
						MetadataObject,
						FieldForControllingReferencesToUnsharedData);
					
				EndDo;
				
			Else
				
				Raise NStr("ru = 'Некорректный кэш контроля неразделенных данных при выгрузке.';
										|en = 'Invalid shared data control cache on export.';");
				
			EndIf;
			
		Else
			Raise StrTemplate(NStr("ru = 'Объект метаданных %1 не поддерживается.';
											|en = 'Metadata object %1 is not supported.';", Metadata.DefaultLanguage.LanguageCode),
				FullMetadataObjectName);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ControllingReferenceToUnsharedDataWhenUnloading(Container, Val RefToCheck, Val InitialObject, Val SourceMetadataObject, Val FieldName)
	
	If Not ValueIsFilled(RefToCheck) Then
		// If an attribute value is not filled in, control is not required.
		Return;
	EndIf;
	
	ValueType = TypeOf(RefToCheck);
	
	If Not Common.IsReference(ValueType) Then
		// Control is required only for reference type values.
		Return;
	EndIf;
	
	MetadataObject = RefToCheck.Metadata();
	
	If CommonCTL.IsEnum(MetadataObject) Then
		// When referring to enumeration members, the same
		// UUID is used across all infobases of a configuration.
		// Therefore, they do not require mapping on import.
		Return;
	EndIf;
	
	If CommonCTL.IsRefDataSupportingPredefinedItems(MetadataObject) Then
		If RefToCheck.Predefined Then
			// References to predefined items are mapped in a dedicated mechanism.
			// See the "ExportImportPredefinedData" common module.
			Return;
		EndIf;
	EndIf;
	
	If MetadataObjectIsSeparatedByAtLeastOneSeparator(MetadataObject, Container.AdditionalProperties.LocalCacheOfDelimiterCompositions) Then
		// Separated data will be imported with the original UUID. New references are generated
		// for objects whose separator type is "Independent and shared".
		Return;
	EndIf;
	
	If Container.AdditionalProperties.GeneralDataRequiringLinkMatching.Find(MetadataObject) <> Undefined Then
		// If a metadata object the developer specified a list of fields for a natural key,
		// the references will be mapped on import using the values of these fields.
		Return;
	EndIf;
	
	If Not Common.RefExists(RefToCheck) Then
		// Broken references do not help the developer to troubleshoot reference mapping on import.
		// 
		Return;
	EndIf;
	
	ErrorTemplate =
		NStr("ru = 'Объект метаданных %1 включен в перечень объектов, для которых не требуется сопоставление ссылок при выгрузке / загрузке
              |данных (в переопределяемой процедуре 
              |%2,
              |но при этом для него не обеспечивается требования отсутствия несопоставляемых ссылок при выгрузке.
              |
              |Несопоставляемая ссылка обнаружена при выгрузке объекта %3, у которого в качестве значения реквизита %4
              |установлена ссылка на объект %1, которая не сможет быть корректно сопоставлена при загрузке данных.
              |Требуется пересмотреть логику использования объекта %1 и обеспечить для него отсутствие несопоставляемых ссылок
              |в выгружаемых данных.
              |
              |Диагностическая информация:
              |1. Сериализация выгружаемого объекта:
              |---------------------------------------------------------------------------------------------------------------------------
              |%5
              |---------------------------------------------------------------------------------------------------------------------------
              |2. Сериализация объекта несопоставляемой ссылки
              |---------------------------------------------------------------------------------------------------------------------------
              |%6
              |---------------------------------------------------------------------------------------------------------------------------';
				|en = 'The %1 metadata object is included in the list of objects that do not require to map references upon data export or import
				|(in overridable procedure
				|%2
				|but it does not meet the requirement for no unmapped references upon export.
				|
				|An unmapped reference is detected when exporting the %3 object, which has a reference to the %1 object as the %4 attribute value.
				|This reference cannot be correctly mapped upon data import.
				|Revise the %1 object usage logic and make sure it has no unmapped references
				|in the data to export.
				|
				|Diagnostic information:
				|1. Serialize the object to export:
				|---------------------------------------------------------------------------------------------------------------------------
				|%5
				|---------------------------------------------------------------------------------------------------------------------------
				|2. Serialize the unmapped reference object
				|---------------------------------------------------------------------------------------------------------------------------
				|%6
				|---------------------------------------------------------------------------------------------------------------------------';");
	
	ErrorText = StrTemplate(
		ErrorTemplate,
		MetadataObject,
		"ExportImportDataOverridable.OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport",
		SourceMetadataObject,
		FieldName,
		Common.ValueToXMLString(InitialObject),
		Common.ValueToXMLString(RefToCheck.GetObject()));
	
	Raise ErrorText;
	
EndProcedure

#EndRegion

