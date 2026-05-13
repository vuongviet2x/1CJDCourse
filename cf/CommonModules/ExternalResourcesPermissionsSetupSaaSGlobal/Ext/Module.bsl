////////////////////////////////////////////////////////////////////////////////
// Subsystem "Core SaaS".
// Common server procedures and functions:
// - Support of security profiles.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Performs an asynchronous processing of a notification of closing external resource permissions
// setup wizard form when the call is executed using an idle handler.
// DialogReturnCode.OK is passed as a result to the handler.
//
// The procedure is not intended for direct call.
//
Procedure FinishConfiguringPermissionsToUseExternalResourcesInServiceModel() Export
	
	ExternalResourcesPermissionsSetupSaaSClient.CompleteSetUpPermissionsToUseExternalResourcesSynchronously(DialogReturnCode.OK);
	
EndProcedure

// Performs an asynchronous processing of a notification of closing external resource permissions
// setup wizard form when the call is executed using an idle handler.
// DialogReturnCode.OK is passed as a result to the handler.
//
// The procedure is not intended for direct call.
//
Procedure AbortSettingPermissionsToUseExternalResourcesInServiceModel() Export
	
	ExternalResourcesPermissionsSetupSaaSClient.CompleteSetUpPermissionsToUseExternalResourcesSynchronously(DialogReturnCode.Cancel);
	
EndProcedure

#EndRegion