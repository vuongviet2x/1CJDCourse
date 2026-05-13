
#Region Public

// Event handler upon receiving a message.
// The handler of this event is called when the message is received form the XML stream.
// The handler is called for every incoming message.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  MessagesChannel - String - an ID of a message channel used to receive the message.
//  Body - Arbitrary - Body of the received message. 
//   In this event handler, the message body can be modified.
//  MessageObject1 - Arbitrary - Incoming message object.
//
Procedure OnReceiveMessage(MessagesChannel, Body, MessageObject1) Export
EndProcedure

// Event handler upon sending a message.
// The handler of this event is called before the message is put to the XML stream.
// The handler is called for every outgoing message.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  MessagesChannel - String - ID of a message channel used to receive the message.
//  Body - Arbitrary - Body of the outgoing message.
//    The handler can change the parameter value.
//  MessageObject1 - Arbitrary - Outgoing message object.
//
Procedure OnSendMessage(MessagesChannel, Body, MessageObject1) Export
EndProcedure

// The procedure is called at the start of incoming message processing.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Message - XDTODataObject - an incoming message,
//  Sender - ExchangePlanRef.MessagesExchange - exchange plan node matching
//    the infobase used to send the message.
//
Procedure OnMessageProcessingStart(Val Message, Val Sender) Export
EndProcedure

// The procedure is called after incoming message processing.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Message - XDTODataObject - an incoming message,
//  Sender - ExchangePlanRef.MessagesExchange - exchange plan node matching
//    the infobase used to send the message
//  MessageProcessed - Boolean - Flag indicating whether the message was processed successfully.
//    If False, an exception is raised after this procedure is complete. 
//    The procedure can change the parameter value.
//
Procedure AfterProcessingMessage(Val Message, Val Sender, MessageProcessed) Export
EndProcedure

// The procedure is called when a message processing error occurs.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Message - XDTODataObject - an incoming message,
//  Sender - ExchangePlanRef.MessagesExchange - exchange plan node matching
//    the infobase used to send the message.
//
Procedure OnMessageProcessingError(Val Message, Val Sender) Export
EndProcedure

#EndRegion
