////////////////////////////////////////////////////////////////////////////////
// InfobaseUpdateCTL: 1C:Cloud Technology Library.
// CTL procedures and functions.
//
////////////////////////////////////////////////////////////////////////////////
//


#Region Public

// See InfobaseUpdateSSL.OnAddSubsystem
// Parameters:
//	LongDesc - See InfobaseUpdateSSL.OnAddSubsystem.LongDesc
Procedure OnAddSubsystem(LongDesc) Export
	
	LongDesc.Name    = "CloudTechnologyLibrary";
	LongDesc.Version = CloudTechnology.LibraryVersion();
	
	// 1C:Standard Subsystems Library is required.
	LongDesc.RequiredSubsystems1.Add("StandardSubsystems");
	
	LongDesc.OnlineSupportID = "SMTL";
	
EndProcedure

// Adds infobase data update handlers
// for all supported versions of the library or configuration to the list.
// Called before starting infobase data update to build an update plan.
//
// Parameters:
//  Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
// Example:
//  Add a handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Version              = "1.0.0.0";
//  Handler.Procedure           = "IBUpdate.RestoreVersion_1_1_0_0";
//  Handler.ExclusiveMode    = False;
//  Handler.Optional        = True;
// 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	// Mandatory subsystems
	CloudTechnology.RegisterUpdateHandlers(Handlers);
	
	// Optional subsystems
	
	If Common.SubsystemExists("CloudTechnology.ExportImportData") Then
		ModuleExportImportDataInternal = Common.CommonModule("ExportImportDataInternal");
		ModuleExportImportDataInternal.RegisterUpdateHandlers(Handlers);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.InformationCenter") Then
		ModuleInformationCenterInternal = Common.CommonModule("InformationCenterInternal");
		ModuleInformationCenterInternal.RegisterUpdateHandlers(Handlers);
	EndIf;
	
	If SaaSOperations.DataSeparationEnabled()
		And Common.SubsystemExists("CloudTechnology.QualityControlCenter") Then
		ModuleQCCIncidentsInternal = Common.CommonModule("IncidentsQCCInternal");
		ModuleQCCIncidentsInternal.RegisterUpdateHandlers(Handlers);
	EndIf;
	
	SaaSOperationsCTL.OnAddUpdateHandlers(Handlers);
	CTLSubsystemsIntegration.OnAddCTLUpdateHandlers(Handlers);
	
	If Common.SubsystemExists("CloudTechnology.ExtensionsSaaS") Then
		ModuleExtensionsSaaS = Common.CommonModule("ExtensionsSaaS");
		ModuleExtensionsSaaS.OnAddUpdateHandlers(Handlers);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.TariffsManagement") Then
		ModuleTariffication = Common.CommonModule("Tariffication");
		ModuleTariffication.OnAddUpdateHandlers(Handlers);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.JobsQueueExternalInterface") Then
		TaskQueueModuleExternalInterface = Common.CommonModule("JobsQueueExternalInterface");
		TaskQueueModuleExternalInterface.OnAddUpdateHandlers(Handlers);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.ApplicationsMigration") Then
		ApplicationMigrationModule = Common.CommonModule("ApplicationsMigration");
		ApplicationMigrationModule.OnAddUpdateHandlers(Handlers);
	EndIf;
	
	SaaSOperations.OnAddUpdateHandlers(Handlers);
	JobsQueueInternalDataSeparation.OnAddUpdateHandlers(Handlers);
	MessagesExchangeInner.OnAddUpdateHandlers(Handlers);
	JobsQueueInternal.OnAddUpdateHandlers(Handlers);
	
EndProcedure

// Called before handler procedures of the infobase data update.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure BeforeUpdateInfobase() Export
EndProcedure

// Called after the infobase data update is completed.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//   PreviousVersion - String - The initial version number. For empty infobases, "0.0.0.0".
//   CurrentVersion - String - Version number after the update.
//   CompletedHandlers - ValueTree - List of completed update handler procedures.
//		List items are grouped by infobase version.
//   OutputUpdatesDetails - Boolean - (Return value) If True, display the release notes form.
//		By default, True.
//   ExclusiveMode - Boolean - If True, the infobase was updated in exclusive mode.
//   
// Example:
// 
//	Iterating through the completed update handlers:
//	For Each Version In CompletedHandlers.Rows Do
//		
//		If Version.Version = "*" Then
//			// A handler that runs for each new version.
//		Else
//			// A handler that runs for a specific version.
//		EndIf;
//		
//		For Each Handler In Version.Rows Do
//			…
//		EndDo;
//		
//	EndDo;
//
Procedure AfterUpdateInfobase(Val PreviousVersion, Val CurrentVersion,
		Val CompletedHandlers, OutputUpdatesDetails, ExclusiveMode) Export
EndProcedure

// Called when preparing a spreadsheet document with details of changes in the application.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//   Template - SpreadsheetDocument - Update details for the configuration and the libraries.
//           The template can be modified or replaced.
//           See the AppReleaseNotes common template.
//
Procedure OnPrepareUpdateDetailsTemplate(Val Template) Export
EndProcedure

// Adds handler procedures of migration from another application (with a different configuration name) to the list.
// For example, to migrate between different applications of the same family: BASE -> PROF -> CORP.
// The procedure is called before the infobase data update.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//  Handlers - ValueTable - Has the following columns:
//    * PreviousConfigurationName - String - Name of the source configuration.
//    * Procedure                 - String - Full name of the handler procedure to migrate from PreviousConfigurationName. 
//                                  For example, "MEMInfobaseUpdate.FillAccountingPolicy"
//                                  It must be an export procedure.
//                                  
// Example:
//  Handler = Handlers.Add();
//  Handler.PreviousConfigurationName = "TradeManagement";
//  Handler.Procedure = "MEMInfobaseUpdate.FillAccountingPolicy";
//
Procedure OnAddApplicationMigrationHandlers(Handlers) Export
EndProcedure

// Overrides the infobase update mode.
// Intended for custom migration scenarios.
// 
//
// Parameters:
//   DataUpdateMode - String - Takes one of the values:
//              InitialFilling - The first start of an empty infobase or data area.
//              VersionUpdate - The first start after a configuration update.
//              MigrationFromAnotherApplication - The first start after a configuration update that changes the configuration name. 
//                                          
//
//   StandardProcessing  - Boolean - If False, the standard procedure of the update mode identification is skipped.
//                                    Instead, the DataUpdateMode value is assigned. 
//                                    
//
Procedure OnDefineDataUpdateMode(DataUpdateMode, StandardProcessing) Export
	
	StandardProcessing = False;
	DataUpdateMode = "VersionUpdate";
	
EndProcedure 

// Called after all the handler procedures of migration from another application (with a different configuration name) are executed
// and before the infobase data update is started.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  PreviousConfigurationName    - String - Configuration name before migration.
//  PreviousConfigurationVersion - String - Old configuration version.
//  Parameters                    - Structure - Structure with the following properties: 
//    * ExecuteUpdateFromVersion   - Boolean - By default, True. 
//        If False, run only required update handlers (whose version is "*").
//    * ConfigurationVersion           - String - The version number after migration. 
//        By default, it repeats the configuration version in metadata properties.
//        To run, for example, all migration handlers from PreviousConfigurationVersion, set the parameter to PreviousConfigurationVersion. 
//        To run all update handlers regardless of the version, set the value to "0.0.0.1".
//        
//    * ClearPreviousConfigurationInfo - Boolean - By default, True. 
//        False if the previous configuration name matches the current configuration subsystem name.
//        
//
Procedure OnCompleteApplicationMigration(Val PreviousConfigurationName, Val PreviousConfigurationVersion, Parameters) Export
EndProcedure

#EndRegion
