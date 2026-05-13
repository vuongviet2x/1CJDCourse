////////////////////////////////////////////////////////////////////////////////
// Subsystem "Core SaaS".
// Common server procedures and functions:
// - Support of security profiles.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Called when requests to use external resources are confirmed.
//
// Parameters:
//  RequestsIDs - Array of UUID - Request IDs.
//  OwnerForm - ClientApplicationForm - Form that must be locked before permissions are applied.
//  ClosingNotification1 - NotifyDescription - Notification triggered when permissions are granted.
//  StandardProcessing - Boolean - indicates that the standard processing of usage of permissions to use
//    external resources is executed (connection to a service agent via COM connection or to an administration server
//    requesting cluster connection parameters from the user). Can be set to False
//    in the event handler. In this case, standard session termination processing is not performed.
//
Procedure OnConfirmRequestsToUseExternalResources(Val RequestsIDs, OwnerForm, ClosingNotification1, StandardProcessing) Export
	
	If CommonClient.DataSeparationEnabled() Then
		
		StartInitializingRequestForPermissionsToUseExternalResources(RequestsIDs, OwnerForm, ClosingNotification1, False);
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

Procedure StartInitializingRequestForPermissionsToUseExternalResources(Val IDs, OwnerForm, ClosingNotification1, CheckMode = False) Export
	
	If SafeModeManagerClient.DisplayPermissionSetupAssistant() Then
		
		ProcessingResult = ExternalResourcesPermissionsSetupSaaSServerCall.ProcessRequestsToUseExternalResources(
			IDs);
		
		If ProcessingResult.PermissionApplicationRequired Then
			
			If CommonClient.SeparatedDataUsageAvailable() Then
				
				FormName = "DataProcessor.ExternalResourcesPermissionsSetupSaaS.Form.RequestPermissionsFromSubscriberAdministrator";
				
			Else
				
				FormName = "DataProcessor.ExternalResourcesPermissionsSetupSaaS.Form.RequestPermissionsFromServiceAdministrator";
				
			EndIf;
			
			FormParameters = New Structure();
			FormParameters.Insert("IDOfPackage", IDs);
			
			NotifyDescription = New NotifyDescription(
				"AfterSetUpPermissionsToUseExternalResources",
				ExternalResourcesPermissionsSetupSaaSClient,
				FormParameters);
			
			OpenForm(
				FormName,
				FormParameters,
				OwnerForm,
				,
				,
				,
				NotifyDescription,
				FormWindowOpeningMode.LockWholeInterface);
			
		Else
			
			CompleteSetUpPermissionsToUseExternalResourcesAsynchronously(ClosingNotification1);
			
		EndIf;
		
	Else
		
		CompleteSetUpPermissionsToUseExternalResourcesAsynchronously(ClosingNotification1);
		
	EndIf;
	
EndProcedure

Procedure AfterSetUpPermissionsToUseExternalResources(Result, State) Export
	
	If Result = DialogReturnCode.OK Then
		
		CompleteSetUpPermissionsToUseExternalResourcesAsynchronously(State.NotifyDescription);
		
	Else
		
		CancelSetUpPermissionsToUseExternalResourcesAsynchronously(State.NotifyDescription);
		
	EndIf;
	
EndProcedure

// Synchronously (relative to the code, from which the wizard was called) processes the notification details
// that were initially passed from the form, for which the wizard was opened in a pseudo modal mode.
//
// Parameters:
//  ReturnCode - DialogReturnCode - 
//
Procedure CompleteSetUpPermissionsToUseExternalResourcesSynchronously(Val ReturnCode) Export
	
	NameOfAlert = "CloudTechnology.NotificationOnApplyExternalResourceRequest";
	ClosingNotification1 = ApplicationParameters[NameOfAlert];
	ApplicationParameters[NameOfAlert] = Undefined;
	If ClosingNotification1 <> Undefined Then
		ExecuteNotifyProcessing(ClosingNotification1, ReturnCode);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Asynchronously (relative to the code, from which the wizard was called) processes the notification details
// that were initially passed from the form, for which the wizard was opened returning
// the return code OK.
//
// Parameters:
//  NotifyDescription - NotifyDescription - Description passed from the calling code.
//
Procedure CompleteSetUpPermissionsToUseExternalResourcesAsynchronously(Val NotifyDescription)
	
	ParameterName = "CloudTechnology.NotificationOnApplyExternalResourceRequest";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	ApplicationParameters[ParameterName] = NotifyDescription;
	AttachIdleHandler("FinishConfiguringPermissionsToUseExternalResourcesInServiceModel", 0.1, True);
	
EndProcedure

// Asynchronously (relative to the code, from which the wizard was called) processes the notification details
// that were initially passed from the form, for which the wizard was opened in a pseudo modal mode returning
// the return code Cancel.
//
// Parameters:
//  NotifyDescription - NotifyDescription - Description passed from the calling code.
//
Procedure CancelSetUpPermissionsToUseExternalResourcesAsynchronously(Val NotifyDescription)
	
	ParameterName = "CloudTechnology.NotificationOnApplyExternalResourceRequest";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	ApplicationParameters[ParameterName] = NotifyDescription;
	AttachIdleHandler("AbortSettingPermissionsToUseExternalResourcesInServiceModel", 0.1, True);
	
EndProcedure

#EndRegion