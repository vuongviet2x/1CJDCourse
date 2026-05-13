///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// Infobase update.
// CommonModule.InfobaseUpdateISL.
//
// 1C:Online Support
//
// The library allows the users to get assistance when using 1C:Enterprise-driven apps.
// The online support covers only the solutions provided by 1C Company and its certified partners.
// See the list of solutions at https://portal.1c.eu.
// Some service interfaces are embedded into the solutions and enhance their functionality.
//
// The API code is the core of 1C:Online Support Library.
// Some OSL subsystems can be integrated into any 1C:Enterprise-based solutions,
// while others only to solutions that meet certain requirements.
// Such requirements are based on the service's features and purposes.
// You can find these requirements in the subsystem documentation.
// 
// 
//
// 
// 
// 
// 
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Fills in main information about the library or base configuration.
// The library that has the same name as the base configuration name in the metadata is considered as a base configuration.
// 
// Parameters:
//  LongDesc - Structure - library info:
//
//   * Name                 - String - a library name (for example, "StandardSubsystems").
//   * Version              - String - a version number in a four-digit format (for example, "2.1.3.1").
//
//   * RequiredSubsystems1 - Array - names of other libraries (String) the current library depends on.
//                                    Update handlers of such libraries must be called earlier than
//                                    update handlers of the current library.
//                                    If they have circular dependencies or, on the contrary, no dependencies,
//                                    the update handlers are called by the order of adding modules in the
//                                    SubsystemsOnAdd procedure of the
//                                    ConfigurationSubsystemsOverridable common module.
//   * DeferredHandlersExecutionMode - String - Sequentially - deferred update handlers run
//                                    sequentially in the interval from the infobase version
//                                    number to the configuration version number. Parallel - once the first data batch is processed,
//                                    the deferred handler passes control to another handler;
//                                    once the last handler finishes work, the cycle is repeated.
//
Procedure OnAddSubsystem(LongDesc) Export
	
	LongDesc.Name                            = "OnlineUserSupport";
	LongDesc.Version                         = OnlineUserSupportClientServer.LibraryVersion();
	LongDesc.OnlineSupportID = "ISL";
	
	// 1C:Standard Subsystems Library is required.
	LongDesc.RequiredSubsystems1.Add("StandardSubsystems");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Infobase update handlers.

// Adds infobase data update handlers
// for all supported versions of the library or configuration to the list.
// Called before starting infobase data update to build an update plan.
//
// Parameters:
//	Handlers - ValueTable - see field details in the
//		InfobaseUpdate.NewUpdateHandlersTable() procedure.
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	// CoreISL
	OnlineUserSupport.OnAddUpdateHandlers(Handlers);
	// End CoreISL
	
	// LoadAndCostEfficiencyData
	If Common.SubsystemExists("OnlineUserSupport.ДанныеНагрузкиИРентабельности") Then
		ModuleLoadandCostEfficiencyData = Common.CommonModule("ДанныеНагрузкиИРентабельности");
		ModuleLoadandCostEfficiencyData.OnAddUpdateHandlers(Handlers);
	EndIf;
	
	// OneCITSPortalDashboard
	If Common.SubsystemExists("OnlineUserSupport.PortalMonitor1CITS") Then
		ModuleOneCITSPortalDashboard = Common.CommonModule("PortalMonitor1CITS");
		ModuleOneCITSPortalDashboard.OnAddUpdateHandlers(Handlers);
	EndIf;
	// End OneCITSPortalDashboard
	
	// News
	If Common.SubsystemExists("OnlineUserSupport.News_") Then
		ModuleNewsProcessingInternal = Common.CommonModule("ОбработкаНовостейСлужебный");
		ModuleNewsProcessingInternal.OnAddUpdateHandlers(Handlers);
	EndIf;
	// End News
	
	// OnlinePayment
	If Common.SubsystemExists("OnlineUserSupport.OnlinePayment") Then
		ModuleOnlinePaymentInternal = Common.CommonModule("OnlinePaymentInternal");
		ModuleOnlinePaymentInternal.OnAddUpdateHandlers(Handlers);
	EndIf;
	// End OnlinePayment
	
	// EnableMaintenanceServices
	If Common.SubsystemExists("OnlineUserSupport.EnableMaintenanceServices") Then
		ModuleMaintenanceServicesActivation = Common.CommonModule("EnableMaintenanceServices");
		ModuleMaintenanceServicesActivation.OnAddUpdateHandlers(Handlers);
	EndIf;
	// End EnableMaintenanceServices
	
	// GetApplicationUpdates
	If Common.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		ModuleGetApplicationUpdates = Common.CommonModule("GetApplicationUpdates");
		ModuleGetApplicationUpdates.OnAddUpdateHandlers(Handlers);
	EndIf;
	// End GetApplicationUpdates
	
	// SPARKRisks
	If Common.SubsystemExists("OnlineUserSupport.SparkRisks") Then
		ModuleSPARKRisks = Common.CommonModule("SparkRisks");
		ModuleSPARKRisks.OnAddUpdateHandlers(Handlers);
	EndIf;
	// End SPARKRisks
	
	// CounterpartiesFunctions
	If Common.SubsystemExists("OnlineUserSupport.WorkingWithCounterparties") Then
		ModuleCounterpartiesFunctions = Common.CommonModule("WorkingWithCounterparties");
		ModuleCounterpartiesFunctions.OnAddUpdateHandlers(Handlers);
	EndIf;
	// End CounterpartiesFunctions
	
	// ClassifiersOperations
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		ModuleClassifiersOperations.OnAddUpdateHandlers(Handlers);
	EndIf;
	// End ClassifiersOperations
	
	// GetAddIns
	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		ModuleGetAddIns = Common.CommonModule("GetAddIns");
		ModuleGetAddIns.OnAddUpdateHandlers(Handlers);
	EndIf;
	// End GetAddIns
	
	// IntegrationWithConnect
	If Common.SubsystemExists("OnlineUserSupport.IntegrationWithConnect") Then
		ModuleIntegrationWithConnect = Common.CommonModule("IntegrationWithConnect");
		ModuleIntegrationWithConnect.OnAddUpdateHandlers(Handlers);
	EndIf;
	// End IntegrationWithConnect
	
	// InstantPayments.BasicFPSFeatures
	If Common.SubsystemExists("OnlineUserSupport.InstantPayments.BasicFPSFeatures") Then
		ModuleFasterPaymentSystemInternal = Common.CommonModule("InstantPaymentsInternal");
		ModuleFasterPaymentSystemInternal.OnAddUpdateHandlers(Handlers);
	EndIf;
	// End InstantPayments.BasicFPSFeatures
	
	// GettingStatutoryReports
	If Common.SubsystemExists("OnlineUserSupport.GettingStatutoryReports") Then
		StatutoryReportsGetterModule = Common.CommonModule("GettingStatutoryReports");
		StatutoryReportsGetterModule.OnAddUpdateHandlers(Handlers);
	EndIf;
	// End GettingStatutoryReports
	
EndProcedure

// Called prior to infobase data update handlers.
//
//@skip-warning
Procedure BeforeUpdateInfobase() Export
	
	
	
EndProcedure

// The procedure is called after the infobase data is updated.
// 
// Parameters:
//   PreviousIBVersion - String - The initial version number. For empty infobases, "0.0.0.0".
//   CurrentIBVersion - String - Version number after the update.
//   CompletedHandlers - ValueTree - List of completed update handler procedures.
//                                             List items are grouped by infobase version.
//   OutputUpdatesDetails - Boolean - if True, the update details
//                                form is output. The default value is True.
//                                A return value.
//   ExclusiveMode           - Boolean - True if update was executed in an exclusive mode.
//
//@skip-warning
Procedure AfterUpdateInfobase(Val PreviousIBVersion, Val CurrentIBVersion,
		Val CompletedHandlers, OutputUpdatesDetails, ExclusiveMode) Export
	
	
	
EndProcedure

// The procedure is called when preparing a spreadsheet document with the release notes.
//
// Parameters:
//  Template - SpreadsheetDocument - Update details. See also the SystemReleaseNotes common template.
//
//@skip-warning
Procedure OnPrepareUpdateDetailsTemplate(Val Template) Export
	
	
	
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
//   StandardProcessing  - Boolean - if False is attributed, the standard procedure
//                                    of the update mode identification is not executed, 
//                                    the DataUpdateMode is used instead.
//
//@skip-warning
Procedure OnDefineDataUpdateMode(DataUpdateMode, StandardProcessing) Export
	
	
	
EndProcedure

// Adds handlers of migration from another application to the list.
// For example, to migrate between different applications of the same family: Base -> Standard -> CORP.
// The procedure is called before the infobase data update.
//
// Parameters:
//	Handlers - ValueTable - Table with the following columns:
//		* PreviousConfigurationName - String - a name of the configuration to migrate from
//			or an asterisk (*) if must be executed while migrating from any configuration.
//		* Procedure - String - Full name of the handler procedure to migrate from PreviousConfigurationName. 
//			For example, "MEMInfobaseUpdate.FillAccountingPolicy"
//			It must be an export procedure.
//
// Example:
//	Handler = Handlers.Add();
//	Handler.PreviousConfigurationName = "TradeManagement";
//	Handler.Procedure = "MEMInfobaseUpdate.FillAccountingPolicy";
//
//@skip-warning
Procedure OnAddApplicationMigrationHandlers(Handlers) Export
	
	
	
EndProcedure

// Called when all the application migration handlers have been executed
// but before the infobase data update.
//
// Parameters:
//  PreviousConfigurationName    - String - Configuration name before migration.
//  PreviousConfigurationVersion - String - Old configuration version.
//  Parameters                    - Structure - :
//    * ExecuteUpdateFromVersion   - Boolean - By default, True. 
//        If False, run only required update handlers (whose version is "*").
//    * ConfigurationVersion           - String - The version number after migration. 
//        By default, it repeats the configuration version in metadata properties.
//        To run, for example, all migration handlers from PreviousConfigurationVersion, set the parameter to PreviousConfigurationVersion. 
//        To run all update handlers regardless of the version, set the value to "0.0.0.1".
//        
//    * ClearPreviousConfigurationInfo - Boolean - By default, True. 
//        Set to False if the previous configuration name matches a subsystem name in the current configuration.
//
//@skip-warning
Procedure OnCompleteApplicationMigration(Val PreviousConfigurationName, 
	Val PreviousConfigurationVersion, Parameters) Export
	
	
	
EndProcedure

#EndRegion
