////////////////////////////////////////////////////////////////////////////////
// APPLICATION MANAGEMENT MESSAGE INTERFACE HANDLER
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns a namespace of the current (used by the calling code) message interface version.
// Returns:
//	String - 
Function Package() Export
	
	Return "http://www.1c.ru/1cFresh/ManageApplication/Messages/1.0";
	
EndFunction

// Returns the current (used by the calling code) message interface version.
// Returns:
//	String - 
Function Version() Export
	
	Return "1.0.0.1";
	
EndFunction

// Returns the name of the message API.
// Returns:
//	String - 
Function Public() Export
	
	Return "ManageApplicationMessages";
	
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

// Returns a message of type {http://www.1c.ru/1cFresh/ManageApplication/Messages/a.b.c.d}RevokeUserAccess.
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTOValueType, XDTOObjectType - message type.
//
Function RevokeUserAccessMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "RevokeUserAccess");
	
EndFunction

#EndRegion

#Region Private

Function GenerateMessageType(Val PackageToUse, Val Type)
	
	If PackageToUse = Undefined Then
		PackageToUse = Package();
	EndIf;
	
	Return XDTOFactory.Type(PackageToUse, Type);
	
EndFunction

#EndRegion
