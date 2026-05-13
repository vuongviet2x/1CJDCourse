///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2019, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Defines events, to which OSL can subscribe.
//
// Returns:
//   События - Structure - Structure property keys are names of events, to which
//             OSL can be subscribed.
//
Function SubscriptionsSSL() Export
	
	Subscriptions = OSLSubsystemsIntegrationClient.OSLEvents();
	If CommonClient.SubsystemExists("StandardSubsystems") Then
		ModuleSSLSubsystemsIntegrationClient = CommonClient.CommonModule("SSLSubsystemsIntegrationClient");
		ModuleSSLSubsystemsIntegrationClient.OnDefineEventsSubscriptionsOSL(Subscriptions);
	EndIf;
	
	Return Subscriptions;
	
EndFunction

#EndRegion