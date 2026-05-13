#Region Internal

// Returns details of data types that contain primitive types.
//
// Returns:
//   TypeDescription - Details.
//
Function DescriptionOfPrimitiveTypes() Export
	
	Return New TypeDescription("Number, String, Boolean, Date, UUID, TypeDescription");
	
EndFunction

// Returns type details that contain all reference types of metadata objects
// in the configuration.
//
// Returns:
//   TypeDescription - Details.
//
Function RefTypesDetails() Export
	
	AnyXDTORefTypeDetails = XDTOFactory.Create(XDTOFactory.Type("http://v8.1c.ru/8.1/data/core", "TypeDescription"));
	AnyXDTORefTypeDetails.TypeSet.Add(XDTOSerializer.WriteXDTO(New XMLExpandedName(
		"http://v8.1c.ru/8.1/data/enterprise/current-config", "AnyRef")));
	AnyRefTypeDetails = XDTOSerializer.ReadXDTO(AnyXDTORefTypeDetails);
	
	ReferenceTypesOfExtensions = ExtensionsDirectory.ReferenceTypesAddedByExtensions();
	
	If ReferenceTypesOfExtensions.Count() <> 0 Then
		AnyRefTypeDetails = New TypeDescription(AnyRefTypeDetails, ReferenceTypesOfExtensions);
	EndIf;
		
	Return AnyRefTypeDetails;
	
EndFunction

// Returns references of business processes route points.
//
// Returns:
//   FixedMap of КлючИЗнчение:
//    * Key - Type - BusinessProcessRoutePointRef type
//    * Value - String - a business process name.
//
Function BusinessProcessesRoutePointsRefs() Export
	
	BusinessProcessesRoutePointsRefs = New Map();
	For Each BusinessProcess In Metadata.BusinessProcesses Do
		BusinessProcessesRoutePointsRefs.Insert(Type("BusinessProcessRoutePointRef." + BusinessProcess.Name), BusinessProcess.Name);
	EndDo;
	
	Return New FixedMap(BusinessProcessesRoutePointsRefs);
	
EndFunction

// Configuration model.
// 
// Returns:
//  FixedStructure - Configuration model.:
// * AllEnumerations - FixedMap of KeyAndValue:
//    ** Key - MetadataObjectEnum
//    ** Value - Boolean
// * AllCatalogs - FixedMap of KeyAndValue:
//    ** Key - MetadataObjectCatalog
//    ** Value - Boolean
// * AllChartsOfCharacteristicTypes - FixedMap of KeyAndValue:
//    ** Key - MetadataObjectChartOfCharacteristicTypes
//    ** Value - Boolean
// * AllAccountPlans - FixedMap of KeyAndValue:
//    ** Key - MetadataObjectChartOfAccounts
//    ** Value - Boolean
// * AllPlansTypesOfCalculation - FixedMap of KeyAndValue:
//    ** Key - MetadataObjectChartOfCalculationTypes
//    ** Value - Boolean
// * AllExchangePlans - FixedMap of KeyAndValue:
//    ** Key - MetadataObjectExchangePlan
//    ** Value - Boolean
// * AllRecordSets - FixedMap of KeyAndValue:
//    ** Key - MetadataObject
//    ** Value - Boolean
// * AllInformationRegisters - FixedMap of KeyAndValue:
//    ** Key - MetadataObjectInformationRegister
//    ** Value - Boolean
// * AllAccumulationRegisters - FixedMap of KeyAndValue:
//    ** Key - MetadataObjectAccumulationRegister
//    ** Value - Boolean
// * AllAccountingRegisters - FixedMap of KeyAndValue:
//    ** Key - MetadataObjectAccountingRegister
//    ** Value - Boolean
// * AllCalculationRegisters - FixedMap of KeyAndValue:
//    ** Key - MetadataObjectCalculationRegister
//    ** Value - Boolean
// * AllIndependentRecordSets - FixedMap of KeyAndValue:
//    ** Key - MetadataObject
//    ** Value - Boolean
// * AllReferenceDataSupportingPredefinedElements - FixedMap of KeyAndValue:
//    ** Key - MetadataObject
//    ** Value - Boolean
// * AllSetsOfSequenceRecords - FixedMap of KeyAndValue:
//    ** Key - MetadataObject
//    ** Value - Boolean
// * AllRecordSetsAreRecalculated - FixedMap of KeyAndValue:
//    ** Key - MetadataObject
//    ** Value - Boolean
Function ConfigurationModel() Export
	
	AllConstants = New Map;
	AllReferenceData = New Map;
	AllEnumerations = New Map;
	AllCatalogs = New Map;
	AllChartsOfCharacteristicTypes = New Map;
	AllAccountPlans = New Map;
	AllPlansTypesOfCalculation = New Map;
	AllExchangePlans = New Map;
	AllRecordSets = New Map;
	AllInformationRegisters = New Map;
	AllAccumulationRegisters = New Map;
	AllAccountingRegisters = New Map;
	AllCalculationRegisters = New Map;
	AllIndependentRecordSets = New Map;
	AllReferenceDataSupportingPredefinedElements = New Map;
	AllSetsOfSequenceRecords = New Map;
	AllRecordSetsAreRecalculated = New Map;
	AllDocumentLogs = New Map;
	AllRoutineTasks = New Map;
	AllExternalDataSources = New Map;
	AllSubsystems = New Map;
	AllSessionParameters = New Map;
	AllGeneralDetails = New Map;
	AllTasks = New Map;
	
	For Each MetadataObject In Metadata.Constants Do
		AllConstants.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.Catalogs Do
		AllReferenceData.Insert(MetadataObject, True);
		AllCatalogs.Insert(MetadataObject, True);
		AllReferenceDataSupportingPredefinedElements.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.Documents Do
		AllReferenceData.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.BusinessProcesses Do
		AllReferenceData.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.Tasks Do
		AllReferenceData.Insert(MetadataObject, True);
		AllTasks.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.ChartsOfAccounts Do
		AllReferenceData.Insert(MetadataObject, True);
		AllAccountPlans.Insert(MetadataObject, True);
		AllReferenceDataSupportingPredefinedElements.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.ExchangePlans Do
		AllReferenceData.Insert(MetadataObject, True);
		AllExchangePlans.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.ChartsOfCharacteristicTypes Do
		AllReferenceData.Insert(MetadataObject, True);
		AllChartsOfCharacteristicTypes.Insert(MetadataObject, True);
		AllReferenceDataSupportingPredefinedElements.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.ChartsOfCalculationTypes Do
		AllReferenceData.Insert(MetadataObject, True);
		AllPlansTypesOfCalculation.Insert(MetadataObject, True);
		AllReferenceDataSupportingPredefinedElements.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.Enums Do
		AllReferenceData.Insert(MetadataObject, True);
		AllEnumerations.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.InformationRegisters Do
		AllRecordSets.Insert(MetadataObject, True);
		AllInformationRegisters.Insert(MetadataObject, True);
		If MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
			AllIndependentRecordSets.Insert(MetadataObject, True);
		EndIf;
	EndDo;
	
	For Each MetadataObject In Metadata.AccumulationRegisters Do
		AllRecordSets.Insert(MetadataObject, True);
		AllAccumulationRegisters.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.AccountingRegisters Do
		AllRecordSets.Insert(MetadataObject, True);
		AllAccountingRegisters.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.CalculationRegisters Do
		AllRecordSets.Insert(MetadataObject, True);
		AllCalculationRegisters.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.Sequences Do
		AllRecordSets.Insert(MetadataObject, True);
		AllSetsOfSequenceRecords.Insert(MetadataObject, True);
	EndDo;
	
	For Each CalculationRegister In Metadata.CalculationRegisters Do
		For Each Recalculation In CalculationRegister.Recalculations Do
			AllRecordSets.Insert(Recalculation, True);
			AllRecordSetsAreRecalculated.Insert(Recalculation, True);
		EndDo;
	EndDo;
	
	For Each MetadataObject In Metadata.DocumentJournals Do
		AllDocumentLogs.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.ScheduledJobs Do
		AllRoutineTasks.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.ExternalDataSources Do
		AllExternalDataSources.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.Subsystems Do
		AllSubsystems.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.SessionParameters Do
		AllSessionParameters.Insert(MetadataObject, True);
	EndDo;
	
	For Each MetadataObject In Metadata.CommonAttributes Do
		AllGeneralDetails.Insert(MetadataObject, True);
	EndDo;
	
	Model = New Structure;
	Model.Insert("AllConstants", New FixedMap(AllConstants));
	Model.Insert("AllReferenceData", New FixedMap(AllReferenceData));
	Model.Insert("AllEnumerations", New FixedMap(AllEnumerations));
	Model.Insert("AllCatalogs", New FixedMap(AllCatalogs));
	Model.Insert("AllChartsOfCharacteristicTypes", New FixedMap(AllChartsOfCharacteristicTypes));
	Model.Insert("AllAccountPlans", New FixedMap(AllAccountPlans));
	Model.Insert("AllPlansTypesOfCalculation", New FixedMap(AllPlansTypesOfCalculation));
	Model.Insert("AllExchangePlans", New FixedMap(AllExchangePlans));
	Model.Insert("AllRecordSets", New FixedMap(AllRecordSets));
	Model.Insert("AllInformationRegisters", New FixedMap(AllInformationRegisters));
	Model.Insert("AllAccumulationRegisters", New FixedMap(AllAccumulationRegisters));
	Model.Insert("AllAccountingRegisters", New FixedMap(AllAccountingRegisters));
	Model.Insert("AllCalculationRegisters", New FixedMap(AllCalculationRegisters));
	Model.Insert("AllIndependentRecordSets", New FixedMap(AllIndependentRecordSets));
	Model.Insert("AllReferenceDataSupportingPredefinedElements", New FixedMap(AllReferenceDataSupportingPredefinedElements));
	Model.Insert("AllSetsOfSequenceRecords", New FixedMap(AllSetsOfSequenceRecords));
	Model.Insert("AllRecordSetsAreRecalculated", New FixedMap(AllRecordSetsAreRecalculated));
	Model.Insert("AllDocumentLogs", New FixedMap(AllDocumentLogs));
	Model.Insert("AllRoutineTasks", New FixedMap(AllRoutineTasks));
	Model.Insert("AllExternalDataSources", New FixedMap(AllExternalDataSources));
	Model.Insert("AllSubsystems", New FixedMap(AllSubsystems));
	Model.Insert("AllSessionParameters", New FixedMap(AllSessionParameters));
	Model.Insert("AllGeneralDetails", New FixedMap(AllGeneralDetails));
	Model.Insert("AllTasks", New FixedMap(AllTasks));
	
	Return New FixedStructure(Model);
	
EndFunction

#EndRegion

#Region Private

// Returns:
// 	FixedMap of KeyAndValue:
// 	 * Key - Arbitrary
//   * Value - Arbitrary
Function ConfigurationDataModelDetails() Export
	
	Model = New Map();
	
	FillModelBySubsystems(Model);
	FillModelByMetadataCollection(Model, "SessionParameters");
	FillModelByMetadataCollection(Model, "CommonAttributes");
	FillModelByMetadataCollection(Model, "ExchangePlans");
	FillModelByMetadataCollection(Model, "ScheduledJobs");
	FillModelByMetadataCollection(Model, "Constants");
	FillModelByMetadataCollection(Model, "Catalogs");
	FillModelByMetadataCollection(Model, "Documents");
	FillModelByMetadataCollection(Model, "Sequences");
	FillModelByMetadataCollection(Model, "DocumentJournals");
	FillModelByMetadataCollection(Model, "Enums");
	FillModelByMetadataCollection(Model, "ChartsOfCharacteristicTypes");
	FillModelByMetadataCollection(Model, "ChartsOfAccounts");
	FillModelByMetadataCollection(Model, "ChartsOfCalculationTypes");
	FillModelByMetadataCollection(Model, "InformationRegisters");
	FillModelByMetadataCollection(Model, "AccumulationRegisters");
	FillModelByMetadataCollection(Model, "AccountingRegisters");
	FillModelByMetadataCollection(Model, "CalculationRegisters");
	FillModelByRecalculations(Model);
	FillModelByMetadataCollection(Model, "BusinessProcesses");
	FillModelByMetadataCollection(Model, "Tasks");
	FillModelByMetadataCollection(Model, "ExternalDataSources");
	FillModelByFunctionalOptions(Model);
	FillModelBySeparators(Model);
	
	Return FixModel(Model);
	
EndFunction

// Returns:
// 	FixedStructure:
// * ExternalDataSources - Number -
// * ScheduledJobs - Number -
// *  - Number -
// * CalculationRegisters - Number -
// * AccountingRegisters - Number -
// * AccumulationRegisters - Number -
// * InformationRegisters - Number -
// * Sequences - Number -
// * DocumentJournals - Number -
// * ExchangePlans - Number -
// * Tasks - Number -
// * BusinessProcesses - Number -
// * ChartsOfCalculationTypes - Number -
// * ChartsOfAccounts - Number -
// * ChartsOfCharacteristicTypes - Number -
// * Enums - Number -
// * Documents - Number -
// * Catalogs - Number -
// * Constants - Number -
// * CommonAttributes - Number -
// * SessionParameters - Number -
// * Subsystems - Number -
Function MetadataClassesInConfigurationModel() Export
	
	CurrentMetadataClasses = New Structure();
	CurrentMetadataClasses.Insert("Subsystems", 1);
	CurrentMetadataClasses.Insert("SessionParameters", 2);
	CurrentMetadataClasses.Insert("CommonAttributes", 3);
	CurrentMetadataClasses.Insert("Constants", 4);
	CurrentMetadataClasses.Insert("Catalogs", 5);
	CurrentMetadataClasses.Insert("Documents", 6);
	CurrentMetadataClasses.Insert("Enums", 7);
	CurrentMetadataClasses.Insert("ChartsOfCharacteristicTypes", 8);
	CurrentMetadataClasses.Insert("ChartsOfAccounts", 9);
	CurrentMetadataClasses.Insert("ChartsOfCalculationTypes", 10);
	CurrentMetadataClasses.Insert("BusinessProcesses", 11);
	CurrentMetadataClasses.Insert("Tasks", 12);
	CurrentMetadataClasses.Insert("ExchangePlans", 13);
	CurrentMetadataClasses.Insert("DocumentJournals", 14);
	CurrentMetadataClasses.Insert("Sequences", 15);
	CurrentMetadataClasses.Insert("InformationRegisters", 16);
	CurrentMetadataClasses.Insert("AccumulationRegisters", 17);
	CurrentMetadataClasses.Insert("AccountingRegisters", 18);
	CurrentMetadataClasses.Insert("CalculationRegisters", 19);
	CurrentMetadataClasses.Insert("Recalculations", 20);
	CurrentMetadataClasses.Insert("ScheduledJobs", 21);
	CurrentMetadataClasses.Insert("ExternalDataSources", 22);
	
	Return New FixedStructure(CurrentMetadataClasses);
	
EndFunction

// Returns a template of object details for the given configuration data model.
// 
// Returns: 
//	Structure -- Details.:
//	 * DataSeparation - Structure:
//		** DataAreaAuxiliaryData - String
//	 * FunctionalOptions - Array of String
//	 * Dependencies - Map of String
//	 * Presentation - String
//	 * FullName - String
Function NewObjectDescription() Export

	ObjectDetails = New Structure();
	ObjectDetails.Insert("FullName", "");
	ObjectDetails.Insert("Presentation", "");
	ObjectDetails.Insert("Dependencies", New Map);
	ObjectDetails.Insert("FunctionalOptions", New Array);
	ObjectDetails.Insert("DataSeparation", New Structure);

	Return ObjectDetails;
	
EndFunction

Function MetadataClasses()
	
	Return CommonCTLCached.MetadataClassesInConfigurationModel();
	
EndFunction

Function DataModelsGroup(Val Model, Val Class)
	
	Group = Model.Get(Class);
	
	If Group = Undefined Then
		Group = New Map();
		Model.Insert(Class, Group);
	EndIf;
	
	Return Group;
	
EndFunction

Procedure FillModelBySubsystems(Val Model)
	
	SubsystemsGroup = DataModelsGroup(Model, MetadataClasses().Subsystems);
	
	For Each Subsystem In Metadata.Subsystems Do
		FillModelBySubsystem(SubsystemsGroup, Subsystem);
	EndDo;
	
EndProcedure

Procedure FillModelBySubsystem(Val ModelGroup, Val Subsystem)
	
	FillModelByMetadataObject(ModelGroup, Subsystem, MetadataClasses().Subsystems);
	
	For Each NestedSubsystem In Subsystem.Subsystems Do
		FillModelBySubsystem(ModelGroup, NestedSubsystem);
	EndDo;
	
EndProcedure

Procedure FillModelByRecalculations(Val Model)
	
	ModelGroup = DataModelsGroup(Model, MetadataClasses().Recalculations);
	
	For Each CalculationRegister In Metadata.CalculationRegisters Do
		
		For Each Recalculation In CalculationRegister.Recalculations Do
			
			FillModelByMetadataObject(ModelGroup, Recalculation, MetadataClasses().Recalculations);
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure FillModelByMetadataCollection(Val Model, Val CollectionName)
	
	Class = MetadataClasses()[CollectionName];
	ModelGroup = DataModelsGroup(Model, Class);
	
	MetadataCollection = Metadata[CollectionName];
	For Each MetadataObject In MetadataCollection Do
		FillModelByMetadataObject(ModelGroup, MetadataObject, Class);
	EndDo;
	
EndProcedure

Procedure FillModelByMetadataObject(Val ModelGroup, Val MetadataObject, Val Class)
	
	ObjectDetails = NewObjectDescription();
	ObjectDetails.FullName = MetadataObject.FullName();
	ObjectDetails.Presentation = MetadataObject.Presentation();
	
	ModelGroup.Insert(MetadataObject.Name, ObjectDetails);
	
	FillModelByMetadataObjectDependencies(ObjectDetails.Dependencies, MetadataObject, Class);
	
EndProcedure

Procedure FillModelByMetadataObjectDependencies(Val ObjectDependencies, Val MetadataObject, Val Class)
	
	If Class = MetadataClasses().Constants Then
		
		FillModelByMetadataObjectDependenciesTypes(ObjectDependencies, MetadataObject.Type);
		
	ElsIf (Class = MetadataClasses().Catalogs
			Or Class = MetadataClasses().Documents
			Or Class = MetadataClasses().ChartsOfCharacteristicTypes
			Or Class = MetadataClasses().ChartsOfAccounts
			Or Class = MetadataClasses().ChartsOfCalculationTypes
			Or Class = MetadataClasses().BusinessProcesses
			Or Class = MetadataClasses().Tasks
			Or Class = MetadataClasses().ExchangePlans) Then
		
		// Standard attributes.
		For Each StandardAttribute In MetadataObject.StandardAttributes Do
			FillModelByMetadataObjectDependenciesTypes(ObjectDependencies, StandardAttribute.Type);
		EndDo;
		
		// Standard tables.
		If (Class = MetadataClasses().ChartsOfAccounts Or Class = MetadataClasses().ChartsOfCalculationTypes) Then
			
			For Each StandardTabularSection In MetadataObject.StandardTabularSections Do
				For Each StandardAttribute In StandardTabularSection.StandardAttributes Do
					FillModelByMetadataObjectDependenciesTypes(ObjectDependencies, StandardAttribute.Type);
				EndDo;
			EndDo;
			
		EndIf;
		
		// Attributes.
		For Each Attribute In MetadataObject.Attributes Do
			FillModelByMetadataObjectDependenciesTypes(ObjectDependencies, Attribute.Type);
		EndDo;
		
		// Tables.
		For Each TabularSection In MetadataObject.TabularSections Do
			// Standard attributes.
			For Each StandardAttribute In TabularSection.StandardAttributes Do
				FillModelByMetadataObjectDependenciesTypes(ObjectDependencies, StandardAttribute.Type);
			EndDo;
			// Attributes.
			For Each Attribute In TabularSection.Attributes Do
				FillModelByMetadataObjectDependenciesTypes(ObjectDependencies, Attribute.Type);
			EndDo;
		EndDo;
		
		If Class = MetadataClasses().Tasks Then
			
			// Addressing attributes.
			For Each AddressingAttribute In MetadataObject.AddressingAttributes Do
				FillModelByMetadataObjectDependenciesTypes(ObjectDependencies, AddressingAttribute.Type);
			EndDo;
			
		EndIf;
		
		If Class = MetadataClasses().Documents Then
			
			// Register records.
			For Each Register In MetadataObject.RegisterRecords Do
				ObjectDependencies.Insert(Register.FullName(), True);
			EndDo;
			
		EndIf;
		
		If Class = MetadataClasses().ChartsOfCharacteristicTypes Then
			
			// Characteristic types.
			FillModelByMetadataObjectDependenciesTypes(ObjectDependencies, MetadataObject.Type);
			
			// Additional characteristic values.
			If MetadataObject.CharacteristicExtValues <> Undefined Then
				ObjectDependencies.Insert(MetadataObject.CharacteristicExtValues.FullName(), True);
			EndIf;
			
		EndIf;
		
		If Class = MetadataClasses().ChartsOfAccounts Then
			
			// Accounting flags.
			For Each AccountingFlag In MetadataObject.AccountingFlags Do
				FillModelByMetadataObjectDependenciesTypes(ObjectDependencies, AccountingFlag.Type);
			EndDo;
			
			// Extra dimension types.
			If MetadataObject.ExtDimensionTypes <> Undefined Then
				ObjectDependencies.Insert(MetadataObject.ExtDimensionTypes.FullName(), True);
			EndIf;
			
			// Extra dimension accounting flags.
			For Each ExtDimensionAccountingFlag In MetadataObject.ExtDimensionAccountingFlags Do
				FillModelByMetadataObjectDependenciesTypes(ObjectDependencies, ExtDimensionAccountingFlag.Type);
			EndDo;
			
		EndIf;
		
		If Class = MetadataClasses().ChartsOfCalculationTypes Then
			
			// Baseline calculation types.
			For Each BaseCalculationType In MetadataObject.BaseCalculationTypes Do
				ObjectDependencies.Insert(BaseCalculationType.FullName(), True);
			EndDo;
			
		EndIf;
		
	ElsIf Class = MetadataClasses().Sequences Then
		
		// Dimensions.
		For Each Dimension In MetadataObject.Dimensions Do
			FillModelByMetadataObjectDependenciesTypes(ObjectDependencies, Dimension.Type);
		EndDo;
		
		// Incoming documents.
		For Each IncomingDocument In MetadataObject.Documents Do
			ObjectDependencies.Insert(IncomingDocument.FullName(), True);
		EndDo;
		
		// Register records.
		For Each Register In MetadataObject.RegisterRecords Do
			ObjectDependencies.Insert(Register.FullName(), True);
		EndDo;
		
	ElsIf (Class = MetadataClasses().InformationRegisters
			Or Class = MetadataClasses().AccumulationRegisters
			Or Class = MetadataClasses().AccountingRegisters
			Or Class = MetadataClasses().CalculationRegisters) Then
		
		// Standard attributes.
		For Each StandardAttribute In MetadataObject.StandardAttributes Do
			FillModelByMetadataObjectDependenciesTypes(ObjectDependencies, StandardAttribute.Type);
		EndDo;
		
		// Dimensions.
		For Each Dimension In MetadataObject.Dimensions Do
			FillModelByMetadataObjectDependenciesTypes(ObjectDependencies, Dimension.Type);
		EndDo;
		
		// Resources.
		For Each Resource In MetadataObject.Resources Do
			FillModelByMetadataObjectDependenciesTypes(ObjectDependencies, Resource.Type);
		EndDo;
		
		// Attributes.
		For Each Attribute In MetadataObject.Attributes Do
			FillModelByMetadataObjectDependenciesTypes(ObjectDependencies, Attribute.Type);
		EndDo;
		
		If Class = MetadataClasses().AccountingRegisters Then
			
			// Chart of accounts.
			If MetadataObject.ChartOfAccounts <> Undefined Then
				ObjectDependencies.Insert(MetadataObject.ChartOfAccounts.FullName(), True);
			EndIf;
			
		EndIf;
		
		If Class = MetadataClasses().CalculationRegisters Then
			
			// Chart of calculation types.
			If MetadataObject.ChartOfCalculationTypes <> Undefined Then
				ObjectDependencies.Insert(MetadataObject.ChartOfCalculationTypes.FullName(), True);
			EndIf;
			
			// Timetable.
			If MetadataObject.Schedule <> Undefined Then
				ObjectDependencies.Insert(MetadataObject.Schedule.FullName(), True);
			EndIf;
			
		EndIf;
		
	ElsIf Class = MetadataClasses().DocumentJournals Then
		
		For Each Document In MetadataObject.RegisteredDocuments Do
			ObjectDependencies.Insert(Document.FullName(), True);
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure FillModelByMetadataObjectDependenciesTypes(Val Result, Val TypeDescription)
	
	If CommonCTL.IsRefsTypesSet(TypeDescription) Then
		Return;
	EndIf;
	
	For Each Type In TypeDescription.Types() Do
		
		If CommonCTL.IsReferenceType(Type) Then
			
			Dependence = CommonCTL.MetadataObjectByRefType(Type);
			
			If Result.Get(Dependence.FullName()) = Undefined Then
				
				Result.Insert(Dependence.FullName(), True);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillModelByFunctionalOptions(Val Model)
	
	For Each FunctionalOption In Metadata.FunctionalOptions Do
		
		For Each CompositionItem In FunctionalOption.Content Do
			
			If CompositionItem.Object = Undefined Then
				Continue;
			EndIf;
			
			ObjectDetails = CommonCTL.ConfigurationModelObjectProperties(Model, CompositionItem.Object); // See NewObjectDescription
			 
			If ObjectDetails <> Undefined Then
				ObjectDetails.FunctionalOptions.Add(FunctionalOption.Name);
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure FillModelBySeparators(Val Model)
	
	// Populate from the common attribute content.
	
	For Each CommonAttribute In Metadata.CommonAttributes Do
		
		If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
			
			UseCommonAttribute = Metadata.ObjectProperties.CommonAttributeUse.Use;
				AutoUseCommonAttribute = Metadata.ObjectProperties.CommonAttributeUse.Auto;
				CommonAttributeAutoUse = 
					(CommonAttribute.AutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse.Use);
			
			For Each CompositionItem In CommonAttribute.Content Do
				
				If (CommonAttributeAutoUse And CompositionItem.Use = AutoUseCommonAttribute)
						Or CompositionItem.Use = UseCommonAttribute Then
					
					ObjectDetails = CommonCTL.ConfigurationModelObjectProperties(Model, CompositionItem.Metadata);
					
					If CompositionItem.ConditionalSeparation <> Undefined Then
						ConditionalSeparationItem = CompositionItem.ConditionalSeparation.FullName();
					Else
						ConditionalSeparationItem = "";
					EndIf;
					
					ObjectDetails.DataSeparation.Insert(CommonAttribute.Name, ConditionalSeparationItem);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	// Make an assumption that sequences that contain separated documents are separated sequences.
	
	For Each Sequence In Metadata.Sequences Do
		
		If Sequence.Documents.Count() > 0 Then
			
			SequenceDetails = CommonCTL.ConfigurationModelObjectProperties(Model, Sequence);
			
			For Each Document In Sequence.Documents Do
				
				DocumentDetails = CommonCTL.ConfigurationModelObjectProperties(Model, Document);
				
				For Each KeyAndValue In DocumentDetails.DataSeparation Do
					
					SequenceDetails.DataSeparation.Insert(KeyAndValue.Key, KeyAndValue.Value);
					
				EndDo;
				
				Break;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	// Make an assumption that document journals that contain separated documents are separated document journals.
	
	For Each DocumentJournal In Metadata.DocumentJournals Do
		
		If DocumentJournal.RegisteredDocuments.Count() > 0 Then
			
			JournalDetails = CommonCTL.ConfigurationModelObjectProperties(Model, DocumentJournal);
			
			For Each Document In DocumentJournal.RegisteredDocuments Do
				
				DocumentDetails = CommonCTL.ConfigurationModelObjectProperties(Model, Document);
				
				For Each KeyAndValue In DocumentDetails.DataSeparation Do
					
					JournalDetails.DataSeparation.Insert(KeyAndValue.Key, KeyAndValue.Value);
					
				EndDo;
				
				Break;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	// Make an assumption that recalculations that are subordinate to separated calculation registers are separated recalculations.
	
	For Each CalculationRegister In Metadata.CalculationRegisters Do
		
		If CalculationRegister.Recalculations.Count() > 0 Then
			
			CalculationRegisterDetails = CommonCTL.ConfigurationModelObjectProperties(Model, CalculationRegister);
			
			For Each Recalculation In CalculationRegister.Recalculations Do
				
				RecalculationDetails = CommonCTL.ConfigurationModelObjectProperties(Model, Recalculation);
				
				For Each KeyAndValue In CalculationRegisterDetails.DataSeparation Do
					
					RecalculationDetails.DataSeparation.Insert(KeyAndValue.Key, KeyAndValue.Value);
					
				EndDo;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function FixModel(Val Model)
	
	If TypeOf(Model) = Type("Array") Then
		
		Result = New Array();
		For Each Item In Model Do
			Result.Add(FixModel(Item));
		EndDo;
		Return New FixedArray(Result);
		
	ElsIf TypeOf(Model) = Type("Structure") Then
		
		Result = New Structure();
		For Each KeyAndValue In Model Do
			Result.Insert(KeyAndValue.Key, FixModel(KeyAndValue.Value));
		EndDo;
		Return New FixedStructure(Result);
		
	ElsIf  TypeOf(Model) = Type("Map") Then
		
		Result = New Map();
		For Each KeyAndValue In Model Do
			Result.Insert(KeyAndValue.Key, FixModel(KeyAndValue.Value));
		EndDo;
		Return New FixedMap(Result);
		
	Else
		
		Return Model;
		
	EndIf;
	
EndFunction


#EndRegion
