#Region Public

// Checks whether the passed metadata object is ConfigurationMetadataObject.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a configuration.
//
Function IsConfigurationMetadataObject(Val MetadataObject) Export
	
	Return TypeOf(MetadataObject) = Type("ConfigurationMetadataObject");
	
EndFunction

// Checks whether the passed metadata object is a subsystem.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a subsystem.
//
Function IsSubsystem(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllSubsystems.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a session parameter.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a session parameter.
//
Function IsSessionParameter(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllSessionParameters.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a common attribute.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a common attribute.
//
Function IsCommonAttribute(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllGeneralDetails.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a constant.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a constant.
//
Function IsConstant(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllConstants.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a catalog.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a catalog.
//
Function IsCatalog(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllCatalogs.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a document.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a document.
//
Function IsDocument(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllDocuments.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is an enumeration.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is an enumeration.
//
Function IsEnum(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllEnumerations.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a business process.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a business process.
//
Function IsBusinessProcess(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllBusinessProcesses.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a task.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a task.
//
Function IsTask(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllTasks.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a chart of accounts.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a chart of accounts.
//
Function IsChartOfAccounts(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllAccountPlans.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is an exchange plan.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is an exchange plan.
//
Function IsExchangePlan(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllExchangePlans.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a chart of calculation types.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a chart of calculation types.
//
Function IsChartOfCalculationTypes(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllPlansTypesOfCalculation.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a chart of calculation types.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a chart of characteristic types.
//
Function IsChartOfCharacteristicTypes(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllChartsOfCharacteristicTypes.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a reference object.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a reference object.
//
Function IsRefData(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllReferenceData.Get(MetadataObject) = True;
		
EndFunction

// Checks whether the passed metadata object has a reference type that supports predefined items.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object supports predefined items.
//
Function IsRefDataSupportingPredefinedItems(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllReferenceDataSupportingPredefinedElements.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is an information register.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is an information register.
//
Function IsInformationRegister(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllInformationRegisters.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is an accumulation register.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is an accumulation register.
//
Function IsAccumulationRegister(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllAccumulationRegisters.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is an accounting register.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is an accounting register.
//
Function IsAccountingRegister(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllAccountingRegisters.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a calculation register.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a calculation register.
//
Function IsCalculationRegister(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllCalculationRegisters.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a recalculation.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a recalculation.
//
Function IsRecalculationRecordSet(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllRecordSetsAreRecalculated.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a sequence.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a sequence.
//
Function IsSequenceRecordSet(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllSetsOfSequenceRecords.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a record set.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a record set.
//
Function IsRecordSet(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllRecordSets.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is an independent record set.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is an independent record set.
//
Function IsIndependentRecordSet(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllIndependentRecordSets.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a record set that supports totals.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object supports totals.
//
Function IsRecordSetSupportingTotals(Val MetadataObject) Export
	
	If IsInformationRegister(MetadataObject) Then
		
		If TypeOf(MetadataObject) = Type("String") Then
			MetadataObject = Metadata.FindByFullName(MetadataObject);
		EndIf;
		
		Return (MetadataObject.EnableTotalsSliceFirst Or MetadataObject.EnableTotalsSliceLast);
		
	ElsIf IsAccumulationRegister(MetadataObject) Then
		
		Return True;
		
	ElsIf IsAccountingRegister(MetadataObject) Then
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

// Checks whether the passed metadata object is a document journal.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a document journal.
//
Function IsDocumentJournal(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllDocumentLogs.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a scheduled job.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if the object is a scheduled job.
//
Function IsScheduledJob(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllRoutineTasks.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is an external data source.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - If True, the object is an external data source.
//
Function ThisIsExternalDataSource(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllExternalDataSources.Get(MetadataObject) = True;
	
EndFunction

// Returns the flag indicating whether this is a primitive type.
//
// Parameters:
//  TypeToCheck - Type - Data type being checked.
//
// Returns:
//   Boolean - True if the type is primitive.
//
Function IsPrimitiveType(Val TypeToCheck) Export
	
	Return CommonCTLCached.DescriptionOfPrimitiveTypes().ContainsType(TypeToCheck);
	
EndFunction

// Returns the flag indicating whether this is a reference object.
//
// Parameters:
//  TypeToCheck - Type - Data type being checked.
//
// Returns:
//   Boolean - True if the type is primitive.
//
Function IsReferenceType(Val TypeToCheck) Export
	
	Return CommonCTLCached.RefTypesDetails().ContainsType(TypeToCheck);
	
EndFunction

// Checks that the type contains a set of reference types.
//
// Parameters:
//  TypeDescription - TypeDescription - Set of reference types.
//
// Returns:
//   Boolean - True if the type contains a set of reference types.
//
Function IsRefsTypesSet(Val TypeDescription) Export
	
	If TypeDescription.Types().Count() < 2 Then
		Return False;
	EndIf;
	
	TypesDetailsSerialization = XDTOSerializer.WriteXDTO(TypeDescription);
	
	If TypesDetailsSerialization.TypeSet.Count() > 0 Then
		
		ContainsRefsSets = False;
		
		For Each TypesSet In TypesDetailsSerialization.TypeSet Do
			
			If TypesSet.NamespaceURI = "http://v8.1c.ru/8.1/data/enterprise/current-config" Then
				
				If TypesSet.LocalName = "AnyRef"
						Or TypesSet.LocalName = "CatalogRef"
						Or TypesSet.LocalName = "DocumentRef"
						Or TypesSet.LocalName = "BusinessProcessRef"
						Or TypesSet.LocalName = "TaskRef"
						Or TypesSet.LocalName = "ChartOfAccountsRef"
						Or TypesSet.LocalName = "ExchangePlanRef"
						Or TypesSet.LocalName = "ChartOfCharacteristicTypesRef"
						Or TypesSet.LocalName = "ChartOfCalculationTypesRef" Then
					
					ContainsRefsSets = True;
					Break;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		Return ContainsRefsSets;
		
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns a metadata object by reference type.
//
// Parameters:
//  RefType - Type - Reference type.
//
// Returns: 
//	MetadataObject - a metadata object
//
Function MetadataObjectByRefType(Val RefType) Export
	
	BusinessProcess = CommonCTLCached.BusinessProcessesRoutePointsRefs().Get(RefType);
	If BusinessProcess = Undefined Then
		Ref = New(RefType);
		RefMetadata = Ref.Metadata();
	Else
		RefMetadata = Metadata.BusinessProcesses[BusinessProcess];
	EndIf;
	
	Return RefMetadata;
	
EndFunction

// Checks whether the metadata object is included in the separator content in a mode that enables data separation.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//  SeparatorName - String - Name of the common attribute (separator).
//
// Returns:
//   Boolean - True if the object is separated.
//
Function IsSeparatedMetadataObject(Val MetadataObject, Val SeparatorName) Export
	
	Properties = ConfigurationModelObjectProperties(CommonCTLCached.ConfigurationDataModelDetails(), MetadataObject);
	Return Properties.DataSeparation.Property(SeparatorName);
	
EndFunction

// Returns a list of the objects whose references are stored in the source metadata object.
// Reference sets and references stored in a value storage are ignored.
//
// Parameters:
//  MetadataObject - MetadataObject - Source metadata object.
//
// Returns: 
//	Array of String - an array of full metadata object names.
//
Function MetadataObjectDependencies(Val MetadataObject) Export
	
	Properties = ConfigurationModelObjectProperties(CommonCTLCached.ConfigurationDataModelDetails(), MetadataObject);
	Return Properties.Dependencies;
	
EndFunction

// Checks whether the metadata objects are available by the current values of functional options.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean - True if an object is available by the current functional options.
//
Function MetadataObjectAvailableByFunctionalOptions(Val MetadataObject) Export
	
	Properties = ConfigurationModelObjectProperties(CommonCTLCached.ConfigurationDataModelDetails(), MetadataObject);
	
	If Properties.FunctionalOptions.Count() = 0 Then
		Return True;
	Else
		Result = False;
		For Each FunctionalOption In Properties.FunctionalOptions Do
			If GetFunctionalOption(FunctionalOption) Then
				Result = True;
			EndIf;
		EndDo;
		Return Result;
	EndIf;
	
EndFunction

// Returns a metadata object presentation.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object.
//
// Returns: 
//	String - Metadata object presentation.
//
Function MetadataObjectPresentation(Val MetadataObject) Export
	
	Properties = ConfigurationModelObjectProperties(CommonCTLCached.ConfigurationDataModelDetails(), MetadataObject);
	Return Properties.Presentation;
	
EndFunction

// Returns a list (with a classification) of the rights available for the metadata object.
//
// Parameters:
//  MetadataObject - MetadataObject - Metadata object.
//
// Returns: 
//	ValueTable - Table of valid rights.:
//	 * Name - String - Name of the right type that can be used for the AccessRight() function.
//	 * Interactive - Boolean - Restricted manual operation right flag.
//	 * Read - Boolean - Object data read right flag.
//		
//	 * Update - Boolean - Object modification right flag.
//		
//	 * InfobaseAdministration - Boolean - Administrator right flag.
//		Implies the infobase global administration.
//	 * DataAreaAdministration - Boolean - Administrator right flag.
//		Implies the data area global administration.
//		
//
Function AllowedRightsForMetadataObject(Val MetadataObject) Export
	
	RightsKinds = New ValueTable();
	RightsKinds.Columns.Add("Name", New TypeDescription("String"));
	RightsKinds.Columns.Add("Interactive", New TypeDescription("Boolean"));
	RightsKinds.Columns.Add("Read", New TypeDescription("Boolean"));
	RightsKinds.Columns.Add("Update", New TypeDescription("Boolean"));
	RightsKinds.Columns.Add("InfobaseAdministration", New TypeDescription("Boolean"));
	RightsKinds.Columns.Add("DataAreaAdministration", New TypeDescription("Boolean"));
	
	If IsConfigurationMetadataObject(MetadataObject) Then
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Administration";
		RightKind.InfobaseAdministration = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "DataAdministration";
		RightKind.DataAreaAdministration = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "UpdateDataBaseConfiguration";
		RightKind.InfobaseAdministration = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "ExclusiveMode";
		RightKind.DataAreaAdministration = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "ActiveUsers";
		RightKind.DataAreaAdministration = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "EventLog";
		RightKind.DataAreaAdministration = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "ThinClient";
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "WebClient";
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "ThickClient";
		RightKind.InfobaseAdministration = True;
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "ExternalConnection";
		RightKind.InfobaseAdministration = True;
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Automation";
		RightKind.InfobaseAdministration = True;
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "AllFunctionsMode";
		RightKind.InfobaseAdministration = True;
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "SaveUserData";
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "InteractiveOpenExtDataProcessors";
		RightKind.InfobaseAdministration = True;
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "InteractiveOpenExtReports";
		RightKind.InfobaseAdministration = True;
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Output";
		RightKind.Interactive = True;
		
	ElsIf IsSessionParameter(MetadataObject) Then
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Get";
		RightKind.Read = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Set";
		RightKind.Update = True;
		
	ElsIf IsCommonAttribute(MetadataObject) Then
		
		RightKind = RightsKinds.Add();
		RightKind = "View";
		RightKind.Interactive = True;
		RightKind.Read = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Edit";
		RightKind.Interactive = True;
		RightKind.Update = True;
		
	ElsIf IsConstant(MetadataObject) Then
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Read";
		RightKind.Read = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Update";
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "View";
		RightKind.Interactive = True;
		RightKind.Read = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Edit";
		RightKind.Interactive = True;
		RightKind.Update = True;
		
	ElsIf IsRefData(MetadataObject) Then
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Read";
		RightKind.Read = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Create";
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Update";
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Delete";
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "View";
		RightKind.Interactive = True;
		RightKind.Read = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "InteractiveInsert";
		RightKind.Interactive = True;
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Edit";
		RightKind.Interactive = True;
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "InteractiveDelete";
		RightKind.Interactive = True;
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "InteractiveDeletionMark";
		RightKind.Interactive = True;
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "InteractiveClearDeletionMark";
		RightKind.Interactive = True;
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "InteractiveDeleteMarked";
		RightKind.Interactive = True;
		RightKind.Update = True;
		
		If IsDocument(MetadataObject) Then
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "Posting";
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "UndoPosting";
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractivePosting";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractivePostingRegular";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveUndoPosting";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveChangeOfPosted";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
		EndIf;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "InputByString";
		RightKind.Interactive = True;
		RightKind.Read = True;
		
		If IsBusinessProcess(MetadataObject) Then
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveActivate";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "Start";
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveStart";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
		EndIf;
		
		If IsTask(MetadataObject) Then
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveActivate";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "Perform";
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveExecute";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
		EndIf;
		
		If IsRefDataSupportingPredefinedItems(MetadataObject) Then
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveDeletePredefinedData";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveSetDeletionMarkPredefinedData";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveClearDeletionMarkPredefinedData";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveDeleteMarkedPredefinedData";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
		EndIf;
		
	ElsIf IsRecordSet(MetadataObject) Then
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Read";
		RightKind.Read = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Update";
		RightKind.Update = True;
		
		If Not IsSequenceRecordSet(MetadataObject) And Not IsRecalculationRecordSet(MetadataObject) Then
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "View";
			RightKind.Interactive = True;
			RightKind.Read = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "Edit";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
		EndIf;
		
		If IsRecordSetSupportingTotals(MetadataObject) Then
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "TotalsControl";
			RightKind.DataAreaAdministration = True;
			
		EndIf;
		
	ElsIf IsDocumentJournal(MetadataObject) Then
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Read";
		RightKind.Read = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "View";
		RightKind.Interactive = True;
		RightKind.Read = True;
		
	EndIf;
	
	Return RightsKinds;
	
EndFunction

// Returns an empty UUID.
//
// Returns:
//  UUID - UUID.
//
Function BlankUUID() Export
	
	Return New UUID("00000000-0000-0000-0000-000000000000");
	
EndFunction

// Stops code execution for a specified time.
// Use only in a background job.
//
// Parameters:
//  Seconds - Number - Suspend time in seconds.
//
Procedure Pause(Seconds) Export
	
	CurrentInfobaseSession1 = GetCurrentInfoBaseSession();
	BackgroundJob = CurrentInfobaseSession1.GetBackgroundJob();
	
	If BackgroundJob = Undefined Then
		WriteLogEvent(
			NStr("ru = 'Ошибка выполнения';
				|en = 'Runtime error';"), 
			EventLogLevel.Error, 
			, 
			, 
			NStr("ru = 'ОбщегоНазначенияБТС.Пауза() разрешается использовать только в фоновом задании.';
				|en = 'You can use CommonCTL.Pause() only in the background job.';"));
		Parameters = New Array;
		Parameters.Add(Seconds);
		BackgroundJob = BackgroundJobs.Execute("CommonCTL.Pause", Parameters);
	EndIf;
		
	BackgroundJob.WaitForExecutionCompletion(Seconds);
	
EndProcedure

// Writes an event to the Technological Log.
//
// Parameters:
//  Event	 - String - Event name to filter Technological Log entries using settings from logcfg.xml.
//  Context - Structure - Arbitrary data to write to the Technological Log.
//		To increase the write speed, we recommended that you add only data of primitive types.
//
Procedure TechnologyLogEntry(Event, Context) Export
	
	Try
		
		Record = New JSONWriter;
		Record.SetString();
		
		Try
			
			WriteJSON(Record, Context);
			
		Except
		
			XDTOSerializer.WriteJSON(Record, Context);
			
		EndTry;
		
		Query = New Query(
		"SELECT
		|	&Event AS Event,
		|	&Context AS Context");
		
		Query.SetParameter("Event", "TJEvent." + Event);
		Query.SetParameter("Context", Record.Close());
		
		Query.Execute();
		
	Except
		
		WriteLogEvent("TechnologyLogEntry", EventLogLevel.Error,,, 
			CloudTechnology.DetailedErrorText(ErrorInfo()));
		
	EndTry;
	
EndProcedure

#EndRegion

#Region Internal

// Active extensions that modify the data structure.
// 
// Returns:
//  Array of ConfigurationExtension
Function ActiveExtensionsThatChangeDataStructure() Export
	
	ActiveExtensionsThatChangeDataStructure = New Array;
	
	For Each ConfigurationExtension In ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionApplied) Do	
		If ConfigurationExtension.Active
			And ConfigurationExtension.ModifiesDataStructure() Then
			ActiveExtensionsThatChangeDataStructure.Add(ConfigurationExtension)
		EndIf;
	EndDo;
	
	Return ActiveExtensionsThatChangeDataStructure;
EndFunction

// Parameters: 
//  String - String - Source string.
// 
// Returns: 
//  String - Only digits extracted from the string.
Function NumbersOnly(Val String) Export
	
	ProcessedString_ = "";

	For CharacterNumber = 1 To StrLen(String) Do
		Char = Mid(String, CharacterNumber, 1);
		If Char >= "0" And Char <= "9" Then
			ProcessedString_ = ProcessedString_ + Char;
		EndIf;
	EndDo;
	
	Return ProcessedString_;
	
EndFunction

// Gets the header value case-insensitively.
//
// Parameters: 
//  RequestResponse - HTTPRequest, HTTPResponse, HTTPServiceRequest, HTTPServiceResponse - Either request or respond.
//  Title - String - Title name.
//
// Returns:
//  String, Undefined - Title value.
//
Function HTTPHeader(RequestResponse, Val Title) Export
	
	Title = Lower(Title);
	For Each KeyAndValue In RequestResponse.Headers Do
		If Lower(KeyAndValue.Key) = Title Then
			Return KeyAndValue.Value;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Returns:
//  Array of String -
//
Function InteractiveApplicationNames() Export
	ApplicationNames = New Array();
	ApplicationNames.Add("1CV8");
	ApplicationNames.Add("1CV8C");
	ApplicationNames.Add("WebClient");
	ApplicationNames.Add("MobileClient");
	Return ApplicationNames;
EndFunction

#EndRegion

#Region Private

// Checks whether 1C:SSL is integrated into the configuration.
//
// Returns:
//   Boolean - result.
//
Function ConfigurationContainsSSL()
	
	Return (Metadata.Subsystems.Find("StandardSubsystems") <> Undefined);
	
EndFunction

// Checks whether the configuration supports SSL events.
//
// Returns:
//   Boolean - support of CTL events. 
//
Function SoftwareEventsAreSupported()
	
	If Not ConfigurationContainsSSL() Then
		Return False;
	EndIf;
	
	Try
		
		SetSafeMode(True);
		
		Execute("StandardSubsystemsCached.ProgramEventOptions()");
		Return True;
		
	Except
		Return False;
	EndTry;
	
EndFunction

// (Obsolete) Returns SSL event handlers.
//
// Parameters:
//  Event - String - Event name.
// Returns:
//	Array of Arbitrary - handlers.
Function GetProgramEventHandlersSSL(Val Event) Export
	
	If SoftwareEventsAreSupported() Then
		
		SetSafeMode(True);
		Return Eval("Common.ServiceEventHandlers(Event)");
		
	Else
		Return New Array();
	EndIf;
	
EndFunction

// Properties of the configuration model object.
// 
// Parameters: 
//  Model - FixedArray of Structure:
//  * Value - Map of KeyAndValue:
//  		   - FixedMap of KeyAndValue:
//  			  * Key - String
//  			  * Value - See CommonCTLCached.NewObjectDescription
//  MetadataObject - MetadataObject - Metadata object.
// 
// Returns:  See CommonCTLCached.NewObjectDescription
//
Function ConfigurationModelObjectProperties(Val Model, Val MetadataObject) Export
	
	If TypeOf(MetadataObject) = Type("MetadataObject") Then
		Name = MetadataObject.Name;
		FullName = MetadataObject.FullName();
	Else
		FullName = MetadataObject;
		Name = StrSplit(FullName, ".").Get(1);
	EndIf;
	
	For Each ModelClass In Model Do
		Value = ModelClass.Value;
		If TypeOf(Value) = Type("Map")  Or TypeOf(Value) = Type("FixedMap") Then
			ObjectDetails = Value.Get(Name); // See CommonCTLCached.NewObjectDescription
		Else
			ObjectDetails = Undefined;
		EndIf;
		If ObjectDetails <> Undefined Then
			If FullName = ObjectDetails.FullName Then
				Return ObjectDetails;
			EndIf;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

#EndRegion