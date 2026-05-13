////////////////////////////////////////////////////////////////////////////////
// Tariffication common module.

// The procedure for obtaining/releasing licenses on unique services:
// 1. Send a request to obtain/release the license. For example, at the beginning of the transaction.
//    The operation's UID is passed to the Billing system.
// 2. The request is either confirmed or rejected (for example, before completing the transaction).
//    NOTE: In CTL, an active operation is terminated after a 15-minute timeout.
//
// 
// 

#Region Public

// Returns a reference to a service by its ID and a service provider ID.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  ServiceID - String - a service ID.
//  VendorID - String - Service provider ID.
//	RaiseException1 - Boolean - indicates if it is necessary to raise an exception in case if the service is not found
//
// Returns:
//  CatalogRef.SaaSServices - a reference to a service.
//
Function ServiceByIDAndProviderID(Val ServiceID, Val VendorID, RaiseException1 = True) Export
EndFunction

// Checks whether the service tariffication system allows
// the specified user to use the specified unlimited service.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  VendorID - String - SaaS vendor UUID in the cloud service.
//  ServiceID - String - Service UUID in the cloud service.
//
// Returns:
//  Boolean - check result (True = the license is registered).
//
Function UnlimitedServiceLicenseRegistered(VendorID, ServiceID) Export
EndFunction

// Checks whether the specified ID of
// a license for using the specified unique limited service is registered in the service tariffication system.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  VendorID - String - SaaS vendor UUID in the cloud service.
//  ServiceID - String - Service UUID in the cloud service.
//  LicenseName - String - String(200) - Human-readable unique license presentation.
//  LicenseContext - String - String(200) - License context.
//
// Returns:
//  Boolean - check result (True = the license is registered).
//
Function UniqueServiceLicenseRegistered(VendorID, ServiceID, LicenseName, LicenseContext = "") Export
EndFunction

// Attempts to receive licenses for using a unique service in the service tariffication system.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  VendorID - String - SaaS vendor UUID in the cloud service.
//  ServiceID - String - Service UUID in the cloud service.
//  LicenseName - String - String(200) - Human-readable unique license presentation.
//  OperationID - UUID - an operation UUID required for confirmation.
//  LicenseContext - String - String(200) - License context that indicates that the license is unique.
//
// Returns:
//  Structure - Structure with the following properties:
//    * Result - Boolean - execution result (True = license is successfully obtained).
//    * AvailableLicenses_ - Number - Maximum number of licenses available to the subscriber for the specified service. If it's set to -1, there's no limit.
//    * BusyLicenses - Number - the number of service licenses already received (used).
//    * NumberOfLicenses - Number - the number of free licenses (if -1, the number is unlimited).
//
Function BorrowUniqueServiceLicense(VendorID, ServiceID, LicenseName, OperationID, LicenseContext = "") Export
EndFunction

// Attempts to unlock a unique service license in the service tariffication system.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  VendorID - String - SaaS vendor UUID in the cloud service.
//  ServiceID - String - Service UUID in the cloud service.
//  LicenseName - String - String(200) - Human-readable unique license presentation.
//  OperationID - UUID - an operation UUID required for confirmation.
//  DataAreaCode - Number - a data area code (when calling a function from a shared session).
//  LicenseContext - String - String(200) - License context that indicates that the license is unique.
//  RemoveLicenseInAllDataAreas - Boolean - whether to delete this license by data areas.
//
// Returns:
//  Boolean - execution result (True = the license is successfully unlocked, False - the license was not found).
//
Function ReleaseLicenseForUniqueService(VendorID, ServiceID, LicenseName, 
	OperationID, DataAreaCode = Undefined,
	LicenseContext = "", RemoveLicenseInAllDataAreas = False) Export
EndFunction

// Attempts to receive licenses for using a limited service in the service.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  VendorID - String - SaaS vendor UUID in the cloud service.
//  ServiceID - String - Service UUID in the cloud service.
//  LicensesCount - Number - the required number of licenses (a positive integer, 10 digits).
//  DataAreaCode - Number - a data area code (when calling a function from a shared session).
//
// Returns:
//  Structure - Structure with the following properties:
//    * Result - Boolean - execution result (True = license is successfully obtained).
//    * AvailableLicenses_ - Number - Maximum number of licenses available to the subscriber for the specified service. If it's set to -1, there's no limit.
//    * BusyLicenses - Number - the number of service licenses already received (used).
//    * NumberOfLicenses - Number - the number of free licenses (if -1, the number is unlimited).
//
Function ObtainingLimitedServiceLicense(VendorID, ServiceID, LicensesCount, DataAreaCode = Undefined) Export
EndFunction

// Attempts to unlock licenses for using a limited service in the service.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  VendorID - String - SaaS vendor UUID in the cloud service.
//  ServiceID - String - Service UUID in the cloud service.
//  LicensesCount - Number - the required number of licenses (a positive integer, 10 digits).
//  DataAreaCode - Number - a data area code (when calling a function from a shared session).
//
// Returns:
//  Boolean - execution result (True = license is successfully unlocked).
//
Function ReleaseLimitedServiceLicenses(VendorID, ServiceID, LicensesCount, DataAreaCode = Undefined) Export
EndFunction

// Confirms the previously requested operation with licenses (receive and unlock).
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  OperationID - UUID - an operation ID that was passed upon operation request.
//
// Returns:
//  Boolean - operation result (True = operation is confirmed).
//
Function ConfirmOperation(OperationID) Export
EndFunction

// Cancels the previously requested operation with licenses (receive and unlock).
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  OperationID - UUID - an operation ID that was passed upon operation request.
//
// Returns:
//    Boolean - operation result (True = operation is canceled).
//
Function CancelOperation(OperationID) Export
EndFunction

// Attempts to receive a number of free licenses for using a unique service in the service tariffication system.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  VendorID - String - SaaS vendor UUID in the cloud service.
//  ServiceID - String - Service UUID in the cloud service.
//
// Returns:
//  Structure - Has the following keys:
//    * AvailableLicenses_ - Number - Maximum number of licenses available to the subscriber for the specified service. If it's set to -1, there's no limit.
//    * BusyLicenses - Number - the number of service licenses already received (used).
//    * NumberOfLicenses - Number - the number of free licenses (if -1, the number is unlimited).
//
Function NumberOfLicensesForUniqueService(VendorID, ServiceID) Export
EndFunction

// Attempts to receive a number of limited service licenses in the service.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  VendorID - String - SaaS vendor UUID in the cloud service.
//  ServiceID - String - Service UUID in the cloud service.
//  DataAreaCode - Number - a data area code (when calling a function from a shared session).
//
// Returns:
//  Structure - Has the following keys:
//    * AvailableLicenses_ - Number - Maximum number of licenses available to the subscriber for the specified service. If it's set to -1, there's no limit.
//    * BusyLicenses - Number - the number of service licenses already received (used).
//    * NumberOfLicenses - Number - the number of free licenses (if -1, the number is unlimited).
//
Function NumberOfLimitedServiceLicenses(VendorID, ServiceID, DataAreaCode = Undefined) Export
EndFunction

// Returns a flag indicating that the current session is locked by billing.
// 
// Returns:
//  Boolean -
Function CurrentSessionBlocked() Export
	Return False;	
EndFunction

#EndRegion

#Region Internal

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.AvailableLicenses);
	Types.Add(Metadata.InformationRegisters.LockedLicenses);
	
	ExportImportData.AddTypeExcludedFromUploadingUploads(
		Types,
		Metadata.Catalogs.SaaSServices,
		ExportImportData.ActionWithLinksDoNotChange());	
	
	ExportImportData.AddTypeExcludedFromUploadingUploads(
		Types,
		Metadata.Catalogs.SaaSServicesSuppliers,
		ExportImportData.ActionWithLinksDoNotChange());	

	Types.Add(Metadata.Constants.UseTarifficationControl);
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
// 	Settings - See ScheduledJobsOverridable.OnDefineScheduledJobSettings.Settings
//
Procedure OnDefineScheduledJobSettings(Settings) Export
EndProcedure

// See MessageInterfacesSaaSOverridable.FillInReceivedMessageHandlers.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
// 	HandlersArray - See MessageInterfacesSaaSOverridable.FillInReceivedMessageHandlers.HandlersArray
//
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
EndProcedure

// See MessageInterfacesSaaSOverridable.FillInHandlersForSendingMessages.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
// 	HandlersArray - See MessageInterfacesSaaSOverridable.FillInHandlersForSendingMessages.HandlersArray
//
Procedure RecordingOutgoingMessageInterfaces(HandlersArray) Export
EndProcedure

// Handler of the OnSetServiceManagerEndpoint event.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure OnSetServiceManagerEndpoint() Export
EndProcedure

// Adds update handler procedures required by this subsystem.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export
EndProcedure

// Registers services to be tariffed that are supported by this configuration in the Service Manager.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure RegisterChargedServices_RoutineTask() Export
EndProcedure

// Attempts to request licenses of unique services from Service Manager.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure RequestLicensesForUniqueServices_RoutineTask() Export
EndProcedure

// @skip-warning EmptyMethod - Implementation feature.
//
Procedure FormGetProcessing(Source, FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing) Export
EndProcedure

#EndRegion
