#Region Public

// Returns a number of the current application interface version.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//   String   - API version number.
//
Function Version() Export
EndFunction

// Returns a namespace of the current (used by the calling code) version of the message interface.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//   String   - API namespace.
//
Function Package() Export
EndFunction

// Returns a name of the application message interface.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//   String   - API name.
//
Function Public() Export
EndFunction

// Registers message handlers as handlers of message exchange channels.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//	HandlersArray - Array - Channel handlers. 
//
Procedure MessagesChannelsHandlers(HandlersArray) Export
EndProcedure

// Registers message translation handlers.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//	HandlersArray - Array - Channel handlers.
//
Procedure MessagesTranslationHandlers(HandlersArray) Export
EndProcedure

#EndRegion