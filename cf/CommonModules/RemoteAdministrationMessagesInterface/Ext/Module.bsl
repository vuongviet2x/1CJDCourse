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
//  HandlersArray - Array - an array of handlers.
//
Procedure MessagesChannelsHandlers(Val HandlersArray) Export
EndProcedure

// Registers message translation handlers.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  HandlersArray - Array - an array of handlers.
//
Procedure MessagesTranslationHandlers(Val HandlersArray) Export
EndProcedure

#EndRegion