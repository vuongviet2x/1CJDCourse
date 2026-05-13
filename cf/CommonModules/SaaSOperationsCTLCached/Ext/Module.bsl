////////////////////////////////////////////////////////////////////////////////
// Subsystem "Core SaaS".
// Common server procedures and functions:
// - Support of the SaaS mode.
//
////////////////////////////////////////////////////////////////////////////////
// 
//@strict-types

#Region Public

// Returns the endpoint for sending messages to the Service Manager.
//
// Returns:
//  ExchangePlanRef.MessagesExchange - node matching the service manager.
//
Function ServiceManagerEndpoint() Export
	
	Return SaaSOperationsCTL.ServiceManagerEndpoint();
	
EndFunction

// Returns the HTTP connection with the manager service.
// The calling code must set the privilege mode.
// 
// Parameters: 
//  ServerData - See CommonClientServer.URIStructure
//  Timeout - Number - See SaaSOperationsCTL.ConnectingToServiceManager.Timeout
// 
// Returns: 
//  HTTPConnection - Connection with the Service Manager.
// (See SaaSOperationsCTL.ConnectingToServiceManager)
Function ConnectingToServiceManager(ServerData, Timeout = 60) Export
	
	Return SaaSOperationsCTL.ConnectingToServiceManager(ServerData, Timeout);
	
EndFunction
 
#EndRegion
