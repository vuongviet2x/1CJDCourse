
#Region Public

// Obsolete. Avoid using it in the application code.
// Returns a 1C-supplied extension that corresponds to the used extension.
//
// Parameters:
//	UsedExtensionID - UUID - Extension ID.
//
// Returns:
//	CatalogRef.SuppliedExtensions - Reference to the 1C-supplied extension.
//
Function SuppliedExtension(UsedExtensionID) Export
	
	Return Undefined;
	
EndFunction

// Populates an array with metadata object names whose data might include references to metadata objects,
// but these references are ignored in the application business logic.
//
// Parameters:
//  Array - Array of String - For example, InformationRegiste.ObjectsVersions.
//
Procedure OnAddReferenceSearchExceptions(Array) Export
	
	Array.Add(Metadata.InformationRegisters.UseSuppliedExtensionsInDataAreas.FullName());
	
EndProcedure

// See SaaSOperationsOverridable.OnFillIIBParametersTable
// 
// Parameters:
//	ParametersTable - See SaaSOperations.IBParameters
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "UseExtensionCatalogInSaaS");
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "UseSecurityProfilesForExtensions");
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "IndependentUsageOfExtensionsSaaS");
	
EndProcedure

// See SaaSOperationsOverridable.OnSetIBParametersValues.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure OnSetIBParametersValues(Val ParameterValues) Export
EndProcedure

// See MessageInterfacesSaaSOverridable.FillInReceivedMessageHandlers.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
// 	HandlersArray - Array of CommonModule - Handlers.
//
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
EndProcedure

// See MessageInterfacesSaaSOverridable.FillInHandlersForSendingMessages.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
// 	HandlersArray - Array of CommonModule - Handlers.
//
Procedure RecordingOutgoingMessageInterfaces(HandlersArray) Export	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export	
EndProcedure

// See SuppliedDataOverridable.GetHandlersForSuppliedData.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
// 	Handlers - See SuppliedDataOverridable.GetHandlersForSuppliedData.Handlers
//
Procedure OnDefineSuppliedDataHandlers(Handlers) Export
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.UseSuppliedExtensionsInDataAreas);
	Types.Add(Metadata.InformationRegisters.SuppliedExtensionInstallationQueueInDataArea);
	Types.Add(Metadata.InformationRegisters.ExtensionsForNotificationsQueue);
	Types.Add(Metadata.InformationRegisters.SuppliedExtensionsToUpdateQueueInDataAreas);
	
EndProcedure

#EndRegion

#Region Internal

// Returns the information about the extensions registered in UseSuppliedExtensionsInDataAreas for the given data area.
// 
//
// Returns:
//	Undefined, ValueTable - Following fields:
//		* SuppliedExtension - CatalogRef.SuppliedExtensions
//		* ExtensionToUse - UUID
//		* Installation - UUID
//		* Disabled - Boolean - See Catalog.SuppliedExtensions
//		* DisableReason - EnumRef.ReasonsForDisablingExtensionsSaaS - See Catalog.SuppliedExtensions
//		* Description - String - See Catalog.SuppliedExtensions
//		* VersionID - UUID - See InformationRegister.UseSuppliedExtensionsInDataAreas.
//
Function CurDataAreaExtensions() Export

	Return Undefined;

EndFunction // CurrentDataAreaExtension()

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export
EndProcedure

// There are attached extensions that modify data structure.
// 
// Returns:
// 	Boolean - There are attached extensions that modify data structure.
Function ThereAreInstalledExtensionsModifyingDataStructure() Export 
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	ThereAreExtensionsInstalled = False;
	
	ScopeExtensions = ConfigurationExtensions.Get();
	For Each AreaExpansion In ScopeExtensions Do
		
		If DataSeparationEnabled 
			And AreaExpansion.Scope <> ConfigurationExtensionScope.DataSeparation Then
			Continue;
		EndIf;
		
		ThereAreExtensionsInstalled = Max(
			ThereAreExtensionsInstalled, 
			AreaExpansion.ModifiesDataStructure());
		
	EndDo;
	
	Return ThereAreExtensionsInstalled;
	
EndFunction

#EndRegion