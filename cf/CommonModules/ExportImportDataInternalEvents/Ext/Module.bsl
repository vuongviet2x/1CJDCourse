////////////////////////////////////////////////////////////////////////////////
// Subsystem "Data export and import".
//
// 
// 
////////////////////////////////////////////////////////////////////////////////
// 

#Region Internal

// Returns an interface version 1.0.0.0 of export import handlers.
// Returns:
//	String - version.
//
Function HandlerVersion1_0_0_0() Export
	
	Return "1.0.0.0";
	
EndFunction

// Returns an interface version 1.0.0.1 of export import handlers.
// Returns:
//	String - version.
//
Function HandlerVersion1_0_0_1() Export
	
	Return "1.0.0.1";
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Initializes events during data export

// Generates an array of metadata that requires reference annotation upon export.
//
// Returns:
//	FixedArray of MetadataObjectCatalog - Metadata array.
//
Function GetTypesThatRequireAnnotationOfLinksWhenUnloading() Export
	
	Types = New Array();
	
	// Library event handlers
	CTLSubsystemsIntegration.OnFillTypesThatRequireRefAnnotationOnImport(Types);
	
	// Integrated handlers.
	ExportImportSharedData.OnFillTypesThatRequireRefAnnotationOnImport(Types);
	ExportImportCommonSeparatedData.OnFillTypesThatRequireRefAnnotationOnImport(Types);
	ExportImportPredefinedData.OnFillTypesThatRequireRefAnnotationOnImport(Types);
	ExportImportExchangePlansNodes.OnFillTypesThatRequireRefAnnotationOnImport(Types);
	
	// Overridable procedure.
	ExportImportDataOverridable.OnFillTypesThatRequireRefAnnotationOnImport(Types);
	
	Return New FixedArray(Types);
	
EndFunction

// Generates an array of metadata that supports reference mapping upon import.
//
// Returns:
//	FixedArray of MetadataObject - Metadata array.:
//	* StandardAttributes - StandardAttributeDescriptions - standard attributes:
//		** Ref - MetadataObject - attribute metadata.
Function GetSharedDataTypesThatSupportLinkMappingWhenLoading() Export
	
	Types = New Array();
	
	// Library event handlers
	CTLSubsystemsIntegration.OnFillCommonDataTypesSupportingRefMappingOnExport(Types);
	
	// Overridable procedure.
	ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefMappingOnExport(Types);
	
	Return New FixedArray(Types);
	
EndFunction

// Generates an array of metadata that does not require reference mapping upon import.
//
// Returns:
//	FixedArray of MetadataObject - Metadata array.
//
Function GetSharedDataTypesThatDoNotRequireLinkMappingWhenLoading() Export
	
	Types = New Array();
	
	// Library event handlers
	CTLSubsystemsIntegration.OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport(Types);
	
	// Overridable procedure.
	ExportImportDataOverridable.OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport(Types);
	
	Return New FixedArray(Types);
	
EndFunction

// Generates an array of metadata excluded from import and export.
//
// Returns:
//	FixedArray of MetadataObject - Metadata array.
//
Function GetTypesExcludedFromUploadUpload() Export
	
	Types = TypesFromTypeDescriptions(
		DescriptionsOfTypesExcludedFromUploadingDownloads());

	Return New FixedArray(Types);
	
EndFunction

// Returns:
//	FixedArray of MetadataObject, FixedStructure: 
//		* Type - MetadataObject
//		* Action - String - 
//		To add a structure, we recommend that you use ExportImportData.
//
Function DescriptionsOfTypesExcludedFromUploadingDownloads() Export 
	
	Types = New Array();
	
	SafeModeManagerInternalSaaS.OnFillTypesExcludedFromExportImport(Types);
	
	If Common.SubsystemExists("CloudTechnology.InformationCenter") Then
		ModuleInformationCenterInternal = Common.CommonModule("InformationCenterInternal");
		ModuleInformationCenterInternal.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		ModuleDataExchangeSaaS.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.ExtensionsSaaS") Then
		ModuleExtensionsSaaS = Common.CommonModule("ExtensionsSaaS");
		ModuleExtensionsSaaS.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If SaaSOperations.DataSeparationEnabled()
		And Common.SubsystemExists("CloudTechnology.QualityControlCenter") Then
		ModuleQCCIncidentsServer = Common.CommonModule("QCCIncidentsServer");
		ModuleQCCIncidentsServer.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.TariffsManagement") Then
		ModuleTariffication = Common.CommonModule("Tariffication");
		ModuleTariffication.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.CheckingAndCorrectingData") Then
		ModuleCheckingAndCorrectingData = Common.CommonModule("CheckingAndCorrectingData");
		ModuleCheckingAndCorrectingData.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.ApplicationsMigration") Then
		ApplicationMigrationModule = Common.CommonModule("ApplicationsMigration");
		ApplicationMigrationModule.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.JobsQueueExternalInterface") Then
		TaskQueueModuleExternalInterface = Common.CommonModule("JobsQueueExternalInterface");
		TaskQueueModuleExternalInterface.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.DataAreasFiles") Then
		ModuleSuppliedSubscriberData = Common.CommonModule("DataAreasFiles");
		ModuleSuppliedSubscriberData.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.DataAreasObjectsIntegration") Then
		ModuleIntegrationOfDataDomainObjects = Common.CommonModule("DataAreasObjectsIntegration");
		ModuleIntegrationOfDataDomainObjects.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.SuppliedData") Then
		ModuleSuppliedData = Common.CommonModule("SuppliedData");
		ModuleSuppliedData.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.SummaryApplications") Then
		ModuleSummaryApplications = Common.CommonModule("SummaryApplications");
		ModuleSummaryApplications.OnFillTypesExcludedFromExportImport(Types);
	EndIf;

	// Library event handlers
	CTLSubsystemsIntegration.OnFillTypesExcludedFromExportImport(Types);
	
	// Overridable procedure.
	ExportImportDataOverridable.OnFillTypesExcludedFromExportImport(Types);
	
	Return New FixedArray(Types);
	
EndFunction

// Converts an array of details of types excluded from export and import into an array of types.
//
// Parameters:
//  TypeDescriptions - Array of MetadataObject, FixedStructure: 
//		* Type - MetadataObject
//		* Action - String
//		
// Returns:
//	Array of Type
//
Function TypesFromTypeDescriptions(TypeDescriptions) Export
	
	Types = New Array; // Array of Type
	
	TypeFixedStructure = Type("FixedStructure");
	StructureType = Type("Structure");
	
	For Each LongDesc In TypeDescriptions Do
		DescriptionType = TypeOf(LongDesc);
		If DescriptionType = TypeFixedStructure Or DescriptionType = StructureType Then
			Type = LongDesc.Type;
		Else
			Type = LongDesc;
		EndIf;
		
		Types.Add(Type);
	EndDo;
		
	Return Types;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Initializes events upon data import


// Returns type dependencies when replacing references.
//
// Returns:
//  FixedMap of KeyAndValue:
//	 * Key - String - a full name of the dependent metadata object,
//	 * Value - Array of String - full names of metadata objects, on which this metadata object depends.
//
Function GetTypeDependenciesWhenReplacingReferences() Export
	
	// Integrated handlers.
	Return ExportImportSharedData.TypeDependenciesWhenReplacingReferences();
	
EndFunction

// Executes a number of actions after importing data
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - Container manager used for data import.
//    For details, see comments to the API of ExportImportDataContainerManager.
//    
//  Serialization - XDTODataObject - XDTODataObject {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}InfoBaseUser,
//    infobase user serialization.
//  IBUser - InfoBaseUser -  a user deserialized from the export,
//  Cancel - Boolean -  when setting this parameter value inside this procedure
//    to False, infobase user import is skipped.
//
Procedure PerformActionsWhenLoadingUserOfInformationBase(Container, Serialization, IBUser, Cancel) Export
	
	// Library event handlers
	CTLSubsystemsIntegration.OnImportInfobaseUser(Container, Serialization, IBUser, Cancel);
	
	// Overridable procedure.
	ExportImportDataOverridable.OnImportInfobaseUser(Container, Serialization, IBUser, Cancel);
	
EndProcedure

// Executes a number of actions after importing an infobase user.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - Container manager used for data import.
//    For details, see comments to the API of ExportImportDataContainerManager.
//    
//  Serialization - XDTODataObject - XDTODataObject {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}InfoBaseUser,
//    infobase user serialization.
//  IBUser - InfoBaseUser - User deserialized from the export.
//
Procedure PerformActionsAfterLoadingUserInformationBase(Container, Serialization, IBUser) Export
	
	// Library event handlers
	CTLSubsystemsIntegration.AfterImportInfobaseUser(Container, Serialization, IBUser);
	
	// Overridable procedure.
	ExportImportDataOverridable.AfterImportInfobaseUser(Container, Serialization, IBUser);
	
EndProcedure

// Executes a number of actions after importing infobase users.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - Container manager used for data import.
//    For details, see comments to the API of ExportImportDataContainerManager.
//    
//
Procedure PerformActionsAfterLoadingInformationBaseUsers(Container) Export
	
	// Library event handlers
	CTLSubsystemsIntegration.AfterImportInfobaseUsers(Container);
	
	// Overridable procedure.
	ExportImportDataOverridable.AfterImportInfobaseUsers(Container);
	
EndProcedure

#EndRegion
