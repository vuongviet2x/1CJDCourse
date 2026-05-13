#Region Public

// Registers configuration services to be tariffed from Structure.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  ServiceProviders - Array of Structure - Service provider details:
// 	 * Id - String - Service provider ID (String - String(50)).
// 	 * Description - String - Service provider description (String - String(150)).
// 	 * Services - Array of Structure - Service provider services with the following required keys:
// 	   ** Id - String - a service ID (type String - String(50))
// 	   ** Description - String - a service description (type String - String(150))
// 	   ** ServiceType - EnumRef.ServicesTypes - service type.
//
Procedure OnCreateServicesList(ServiceProviders) Export
	
	
EndProcedure

// An event that is called when changing license activation.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
// 	LicenseInformation - Structure - License details:
// 	 * OperationService - CatalogRef.SaaSServices - service.
// 	 * LicenseName - String - license name.
// 	 * LicenseContext - String - license context.
// 	LicenseActivated - Boolean - indicates whether license is activated or not.
//
Procedure OnChangeLicenseActivationState(LicenseInformation, LicenseActivated) Export
EndProcedure

// An event that is called when updating available licenses.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//	LicenseParameters - Structure - matches the composition of attributes, measurements and resources of the AvailableLicenses information register.:
// 	 * SubscriptionID - UUID - an internal subscription ID.
// 	 * OperationService - CatalogRef.SaaSServices - service.
// 	 * ValidityStartDate - Date - subscription start date.
// 	 * ValidityEndDate - Date - subscription end date.
// 	 * LicensesCount - Number - number of licenses.
// 	 * SubscriptionNumber - String - subscription number.
// 	 * ChangeDate - Date - date modified.
//
Procedure OnUpdateAvailableLicenses(LicenseParameters) Export
EndProcedure

// An event that is called when deleting available licenses.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//	LicenseParameters - See OnUpdateAvailableLicenses.LicenseParameters
//
Procedure OnDeleteAvailableLicenses(LicenseParameters) Export
EndProcedure

#EndRegion
