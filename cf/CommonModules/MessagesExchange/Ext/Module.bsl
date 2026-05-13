
#Region Public

// Sends a message to the targeted channel.
// Messaging type is "Endpoint-to-Endpoint".
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  MessagesChannel - String - Targeted channel ID.
//  Body - Arbitrary - Body of the outgoing system message.
//  Recipient - Undefined - Message recipient is not specified. 
//  							    The message will be sent to the endpoints that are defined by the current information system settings:
//                              - In the MessagesExchangeOverridable.MessageRecipients handler (programmatically), and 
//                              - In the SenderSettings information register (by system settings) 
//                              
//             - ExchangePlanRef.MessagesExchange - exchange plan node matching 
//                                                   the message recipient endpoint. 
//                                                   The message is delivered to the specified 
//                                                   endpoint.
//             - Array - array of message recipient names; all array items must 
//             				conform to ExchangePlanRef.MessageExchange type.
//                        	The message is delivered to all endpoints listed in the array.
//
Procedure SendMessage(MessagesChannel, Body = Undefined, Recipient = Undefined) Export
EndProcedure

// Sends a message to the targeted channel.
// Messaging type is "Endpoint-to-Endpoint".
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  MessagesChannel - String - Targeted channel ID.
//  Body - Arbitrary - Body of the outgoing system message.
//  Recipient - Undefined - Message recipient is not specified. 
//  							    The message will be sent to the endpoints that are defined by the current information system settings: 
//                              - In the MessagesExchangeOverridable.MessageRecipients handler (programmatically), and 
//                              - In the SenderSettings information register (by system settings) 
//                              
//             - ExchangePlanRef.MessagesExchange - exchange plan node 
//                                                   matching the message recipient 
//                                                   endpoint. The message is delivered
//                                                   to the specified endpoint.
//             - Array - array of message recipient names; all array items must 
//                        conform to ExchangePlanRef.MessageExchange type. The message is delivered to all 
//                        endpoints listed in the array.
//
Procedure SendMessageNow(MessagesChannel, Body = Undefined, Recipient = Undefined) Export
EndProcedure

// Sends a message to the broadcast message channel.
// Matches the "Publication/Subscription" sending type.
// The message will be delivered to endpoints that are subscribed to the broadcast channel.
// Broadcast channel subscriptions are set up using the RecipientSubscriptions information register.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  MessagesChannel - String - Broadcast message channel ID.
//  Body - Arbitrary - Body of the outgoing system message.
//
Procedure SendMessageToSubscribers(MessagesChannel, Body = Undefined) Export
EndProcedure

// Sends a quick message to the broadcast message channel.
// Matches the "Publication/Subscription" sending type.
// The message will be delivered to endpoints that are subscribed to the broadcast channel.
// Broadcast channel subscriptions are set up using the RecipientSubscriptions information register.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  MessagesChannel - String - Broadcast message channel ID.
//  Body - Arbitrary - Body of the outgoing system message.
//
Procedure SendMessageToSubscribersNow(MessagesChannel, Body = Undefined) Export	
EndProcedure

// Sends quick messages from the public queue immediately.
// Messages are being sent in the cycle until all the quick messages from the queue 
// are sent.
// While the messages are being sent, sending messages from other sessions immediately is locked.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure DeliverMessages() Export
EndProcedure

// Connect the endpoint.
// Before connecting the endpoint, checks whether the connection 
// of the sender with the recipient and of the recipient with the sender is established. 
// Also, checks whether the recipient connection settings specify the current sender.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  Cancel - Boolean - Error flag. 
//   
//  SenderConnectionSettings - Structure - Sender connection parameters. Contains the following properties:: 
//   The DataExchangeServer.WSParameterStructure function is used for initialization. 
//    * WSWebServiceURL   - String - URL of the endpoint to be connected.
//    * WSUserName  - String - Name of the user to be authenticated at the endpoint to be connected
//                          when working via the message exchange subsystem web service.
//    * WSPassword - String - User password in the endpoint to be connected.
//  RecipientConnectionSettings - Structure - Recipient connection parameters. Contains the following properties::
//   The DataExchangeServer.WSParameterStructure function is used for initialization. 
//    * WSWebServiceURL   - String - URL of the infobase from the endpoint 
//    	to be connected.
//    * WSUserName - String - Name of the user to be authenticated at the infobase 
//                          when working via the message exchange subsystem web service.
//    * WSPassword - String - User password for this infobase.
//  Endpoint - ExchangePlanRef.MessagesExchange, Undefined - If the endpoint connection is successful, 
//		returns a reference to the exchange plan node matching the connected endpoint.
//     If the endpoint connection failed, returns Undefined.
//     
//  RecipientEndpointName - String - Description of the endpoint to be connected. 
//     If not specified, the set to the endpoint configuration synonym.
//     
//  SenderEndpointName - String - Description of the endpoint corresponding to this infobase.
//     If not specified, the infobase configuration synonym is used.
//     
//
Procedure ConnectEndpoint(Cancel, SenderConnectionSettings, RecipientConnectionSettings,
	Endpoint = Undefined, RecipientEndpointName = "", 
	SenderEndpointName = "") Export	
EndProcedure

// Updates connection settings for the endpoint.
// Updates settings of connecting the infobase to the specified endpoint
// and settings of connecting the endpoint to the infobase.
// Before the settings are applied, the connection is checked for the correct settings specification.
// Also, checks whether the recipient connection settings specify the current sender.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  Cancel - Boolean - Error flag.
//  Endpoint - ExchangePlanRef.MessagesExchange - Reference to the exchange plan node matching the endpoint. 
//   
//   
//  SenderConnectionSettings - Structure - Sender connection parameters. Contains the following properties::
//   The DataExchangeServer.WSParameterStructure function is used for initialization. 
//    * WSWebServiceURL   - String - URL of the endpoint to be connected.
//    * WSUserName - String - Name of the user to be authenticated at the endpoint to be connected
//                          when working via the message exchange subsystem web service.
//    * WSPassword - String - User password in the endpoint to be connected.
//  RecipientConnectionSettings - Structure - Recipient connection parameters. Contains the following properties:: 
//   The DataExchangeServer.WSParameterStructure function is used for initialization. 
//    * WSWebServiceURL   - String - URL of the infobase from the endpoint 
//    		to be connected.
//    * WSUserName - String - Name of the user to be authenticated at the infobase 
//                          when working via the message exchange subsystem web service.
//    * WSPassword - String - User password for this infobase.
//
Procedure UpdateEndpointConnectionSettings(Cancel, Endpoint,
	SenderConnectionSettings, RecipientConnectionSettings) Export
EndProcedure

#EndRegion

