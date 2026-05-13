
#Region Public

#Region EventHandlersSSL
// Handle software events that occur in SSL subsystems.
// Intended only for calls from SSL to CTL.

// Defines events, to which this library is subscribed.
//
// Parameters:
//  Subscriptions - Structure - Structure's property keys are names of events,
//           to which this library is subscribed.
//
Procedure OnDefineEventSubscriptionsSSL(Subscriptions) Export
	
	// Core
	Subscriptions.BeforeStart = True;
	Subscriptions.OnStart = True;
	
	// UsersSessions
	Subscriptions.OnEndSessions = True;
	
	// SecurityProfiles
	Subscriptions.OnConfirmRequestsToUseExternalResources = True;
	
EndProcedure

#Region Core

// See the CommonClientOverridable.BeforeStart procedure
// Parameters:
//	Parameters - See CommonClientOverridable.BeforeStart.Parameters
Procedure BeforeStart(Parameters) Export
	
	Parameters.Modules.Add(SaaSOperationsClient);
	Parameters.Modules.Insert(0, ExportImportDataClient);
	
EndProcedure

// See the CommonClientOverridable.OnStart procedure.
// Parameters:
//	Parameters - Structure:
//	 * Modules - Array - references to modules.
Procedure OnStart(Parameters) Export
	
	Parameters.Modules.Add(ApplicationsMigrationClient);
	
EndProcedure

#EndRegion

#Region UsersSessions

// See the RemoteAdministrationCTLClient.OnEndSessions procedure.
Procedure OnEndSessions(OwnerForm, Val SessionsNumbers, StandardProcessing, Val NotificationAfterTerminateSession = Undefined) Export
	
	RemoteAdministrationCTLClient.OnEndSessions(OwnerForm, SessionsNumbers, StandardProcessing, NotificationAfterTerminateSession);
	
EndProcedure

#EndRegion

#Region SecurityProfiles

// See the SafeModeManagerClientOverridable.OnConfirmRequestsToUseExternalResources procedure.
Procedure OnConfirmRequestsToUseExternalResources(Val RequestsIDs, OwnerForm, ClosingNotification1, StandardProcessing) Export

	ExternalResourcesPermissionsSetupSaaSClient.OnConfirmRequestsToUseExternalResources(
		RequestsIDs, OwnerForm, ClosingNotification1, StandardProcessing);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Internal

#Region InformationCenter

// See ContactOnlineSupportClient.NotificationProcessing.
Procedure IntegrationOnlineSupportCallClientNotificationProcessing(EventName, Item) Export
	
	If CTLSubsystemsIntegrationClientCached.SubscriptionsSSL().IntegrationOnlineSupportCallClientNotificationProcessing Then
		SSLSubsystemsIntegrationClient.IntegrationOnlineSupportCallClientNotificationProcessing(EventName, Item);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Defines events, to which other libraries can subscribe.
//
// Returns:
//   Structure - Structure property keys are names of events, to which libraries can be subscribed.:
//   * IntegrationOnlineSupportCallClientNotificationProcessing - Boolean - By default, False.
//
Function EventsCTL() Export
	
	Events = New Structure;
	
	// ExportImportData
	Events.Insert("IntegrationOnlineSupportCallClientNotificationProcessing", False);
	
	Return Events;
	
EndFunction

#EndRegion