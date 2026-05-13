////////////////////////////////////////////////////////////////////////////////
// MESSAGE CHANNEL HANDLER FOR VERSION 1.0.3.5
//  OF REMOTE ADMINISTRATION MESSAGE INTERFACE
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns a message interface version namespace.
//
// Returns:
//	String - 
Function Package() Export
	
	Return "http://www.1c.ru/1cFresh/Application/Permissions/Control/" + Version(); // @Non-NLS-1
	
EndFunction

// Returns a message interface version supported by the handler.
//
// Returns:
//	String - 
Function Version() Export
	
	Return "1.0.0.1";
	
EndFunction

// Returns a base type for version messages.
//
// Returns:
//	XDTOObjectType - 
Function BaseType() Export
	
	Return MessagesSaaSCached.TypeBody();
	
EndFunction

// Processing incoming SaaS messages
//
// Parameters:
//  Message - XDTODataObject - an incoming message,
//  Sender - ExchangePlanRef.MessagesExchange - exchange plan node that matches the message sender
//  MessageProcessed - Boolean - indicates whether the message is successfully processed. The parameter value must be
//    set to If True, the message was successfully read in this handler.
//
Procedure ProcessSaaSMessage(Val Message, Val Sender, MessageProcessed) Export
	
	MessageProcessed = True;
	
	Dictionary = MessagesPermissionsManagementControlInterface;
	MessageType = Message.Body.Type();
	
	If MessageType = Dictionary.MessageInformationBasePermissionRequestProcessed(Package()) Then
		UnsharedSessionRequestProcessed(Message, Sender);
	ElsIf MessageType = Dictionary.MessageProcessedRequestForDataAreaPermissions(Package()) Then
		SplitSessionRequestProcessed(Message, Sender);
	Else
		MessageProcessed = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure UnsharedSessionRequestProcessed(Val Message, Val Sender)
	
	BeginTransaction();
	
	Try
		
		For Each RequestProcessingResult In Message.Body.ProcessingResultList.ProcessingResult Do
			
			MessagesPermissionsManagementControlImplementation.UnsharedSessionRequestProcessed(
				RequestProcessingResult.RequestUUID,
				MessagesPermissionsManagementControlInterface.DictionaryOfQueryResultTypes()[RequestProcessingResult.ProcessingResultType],
				RequestProcessingResult.RejectReason);
				
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

Procedure SplitSessionRequestProcessed(Val Message, Val Sender)
	
	BeginTransaction();
	
	Try
		
		For Each RequestProcessingResult In Message.Body.ProcessingResultList.ProcessingResult Do
			
			MessagesPermissionsManagementControlImplementation.SplitSessionRequestProcessed(
				RequestProcessingResult.RequestUUID,
				MessagesPermissionsManagementControlInterface.DictionaryOfQueryResultTypes()[RequestProcessingResult.ProcessingResultType],
				RequestProcessingResult.RejectReason);
				
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion
