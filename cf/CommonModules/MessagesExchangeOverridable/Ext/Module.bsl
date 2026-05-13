
#Region Public

// Receives a list of message handlers that are processed by this information system.
// @skip-warning EmptyMethod - Overridable method.
// 
// Parameters:
//  Handlers - ValueTable - Has the following columns:
//    * Canal - String - Message channel.
//    * Handler - CommonModule - Message handler.
//
Procedure GetMessagesChannelsHandlers(Handlers) Export	
EndProcedure

// The handler that receives a dynamic list of endpoints.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  MessagesChannel - String - ID of the message channel whose endpoints are to be determined. 
//   
//  Recipients - Array - Array of endpoints assigned as message recipients.
//                            Contains items of ExchangePlanRef.MessageExchange type.
//                            This parameter must be defined in the handler body.
//
Procedure MessageRecipients(Val MessagesChannel, Recipients) Export
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Message send/receipt handlers.

// The event handler that handles message sending.
// The handler of this event is called before the message is put to the XML stream.
// The handler is called for every outgoing message.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  MessagesChannel - String - ID of a message channel used to receive the message.
//  Body - Arbitrary - Body of the outgoing message.
//                                The handler can change the parameter value.
//
Procedure OnSendMessage(MessagesChannel, Body) Export	
EndProcedure

// The event handler that handles message receipt.
// The handler of this event is called when the message is received form the XML stream.
// The handler is called for every incoming message.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  MessagesChannel - String - ID of the message channel used to receive the message.
//  Body - Arbitrary - Body of the received message.
//                                 The handler can change the parameter value.
//
Procedure OnReceiveMessage(MessagesChannel, Body) Export	
EndProcedure

// @skip-check module-empty-method - Implementation feature.
// 
Procedure OnMessageProcessingAttemptsExhausting(MessagesChannel, Body, Sender, DetailErrorDescription) Export
EndProcedure

#EndRegion
