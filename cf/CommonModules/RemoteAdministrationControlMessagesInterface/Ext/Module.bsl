#Region Public

// Returns the current (used by the calling code) version of the message interface.
// @skip-warning EmptyMethod - Implementation feature.
// Returns:
//	String - 
Function Version() Export
EndFunction

// Returns a namespace of the current (used by the calling code) version of the message interface.
// @skip-warning EmptyMethod - Implementation feature.
// Returns:
//	String - 
Function Package() Export
EndFunction

// Returns a name of the application message interface.
// @skip-warning EmptyMethod - Implementation feature.
// Returns:
//	String - 
Function Public() Export
EndFunction

// Registers message handlers as handlers of message exchange channels.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  HandlersArray - Array - message handlers.
//
Procedure MessagesChannelsHandlers(Val HandlersArray) Export
EndProcedure

// Registers message translation handlers.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  HandlersArray - Array - message handlers.
//
Procedure MessagesTranslationHandlers(Val HandlersArray) Export
EndProcedure

// Returns a message type {http://www.1c.ru/SaaS/RemoteAdministration/Control/a.b.c.d}ApplicationPrepared.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTOValueType, XDTOObjectType - message type.
//
Function MessageDataAreaPrepared(Val PackageToUse = Undefined) Export
EndFunction

// Returns a message type {http://www.1c.ru/SaaS/RemoteAdministration/Control/a.b.c.d}ApplicationDeleted.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTOValueType, XDTOObjectType - message type.
//
Function MessageDataAreaDeleted(Val PackageToUse = Undefined) Export
EndFunction

// Returns a message type {http://www.1c.ru/SaaS/RemoteAdministration/Control/a.b.c.d}ApplicationPrepareFailed.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTOValueType, XDTOObjectType - message type.
//
Function DataAreaPreparationErrorMessage(Val PackageToUse = Undefined) Export
EndFunction

// Returns a message type {http://www.1c.ru/SaaS/RemoteAdministration/Control/a.b.c.d}ApplicationPrepareFailedConversionRequired
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTOValueType, XDTOObjectType - message type.
//
Function ErrorMessagePreparingDataAreaConversionRequired(Val PackageToUse = Undefined) Export
EndFunction

// Returns a message type {http://www.1c.ru/SaaS/RemoteAdministration/Control/a.b.c.d}ApplicationDeleteFailed.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTOValueType, XDTOObjectType - message type.
//
Function MessageErrorDeletingDataArea(Val PackageToUse = Undefined) Export
EndFunction

// Returns a message type {http://www.1c.ru/SaaS/RemoteAdministration/Control/a.b.c.d}ApplicationReady.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTOValueType, XDTOObjectType - message type.
//
Function MessageDataAreaIsReadyForUse(Val PackageToUse = Undefined) Export
EndFunction

#EndRegion