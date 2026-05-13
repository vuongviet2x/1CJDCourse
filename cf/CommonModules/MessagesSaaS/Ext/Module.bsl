
#Region Public

// Returns a new message.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  MessageBodyType - XDTOObjectType - body type for the message to be created.
//
// Returns:
//  XDTODataObject - object of the specified type.
//  
Function NewMessage(Val MessageBodyType) Export
EndFunction

// Sends a message
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  Message - XDTODataObject - a message.
//  Recipient - ExchangePlanRef.MessagesExchange - a message recipient.
//  Now - Boolean - flag specifying whether the message will be sent through the quick message delivery.
//
Procedure SendMessage(Val Message, Val Recipient = Undefined,
		Val Now = False) Export
EndProcedure

// Receives a list of message handlers by the namespace.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//  Handlers - ValueTable - Has the following columns:
//    * Canal - String - Message channel.
//    * Handler - CommonModule - Message handler.
//  Namespace - String - URI of a namespace that determines message body types.
//  CommonModule - CommonModule - Common module containing message handlers.
// 
Procedure GetMessagesChannelsHandlers(Val Handlers,
		Val Namespace, Val CommonModule) Export
EndProcedure

// Delivers quick messages.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure DeliverQuickMessages() Export
EndProcedure

// Returns a type that is basic for all message body types in SaaS mode.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//  XDTOObjectType - base body type for messages SaaS.
//
Function TypeBody() Export
EndFunction

#EndRegion

#Region Internal

// @skip-warning EmptyMethod - Implementation feature.
Procedure SetAreaKeyWhenRestoringFromUpload(Message) Export	
EndProcedure

// Reads a message from untyped body of the message.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  UntypedBody - String - untyped message body.
//
// Returns:
//  XDTODataObject - {http://www.1c.ru/SaaS/Messages}Message - message.
//
Function ReadMessageFromUntypedBody(Val UntypedBody) Export
EndFunction

// Returns a message channel name that matches a message type.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  MessageType - XDTOObjectType - a type of remote administration message.
//
// Returns:
//  String - name of a message channel matching the sent message type.
//
Function ChannelNameByMessageType(Val MessageType) Export	
EndFunction

#EndRegion

