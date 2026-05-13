// @strict-types

#Region Public

// Fills in the passed array with the common modules used as incoming message interface handlers.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  HandlersArray - Array of CommonModule - array elements are common modules.
//
Procedure FillInReceivedMessageHandlers(HandlersArray) Export	
EndProcedure

// Fills in the passed array with the common modules used as outgoing message interface handlers.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  HandlersArray - Array of CommonModule - Array of common modules.
//
Procedure FillInHandlersForSendingMessages(HandlersArray) Export
EndProcedure

// The procedure is called when identifying a message interface version supported both by the correspondent infobase 
// and the current infobase. This procedure is used to implement functionality for supporting backward compatibility 
// with earlier versions of correspondent infobases.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  MessageInterface - String - Name of the message API to determine the version for.
//  ConnectionParameters - Structure - Peer infobase connection parameters.
//  RecipientPresentation1 - String - Peer infobase presentation.
//  Result - String - Determinable version. The procedure can change the parameter value.
//
Procedure OnDefineCorrespondentInterfaceVersion(Val MessageInterface, Val ConnectionParameters, Val RecipientPresentation1, Result) Export	
EndProcedure

#EndRegion
