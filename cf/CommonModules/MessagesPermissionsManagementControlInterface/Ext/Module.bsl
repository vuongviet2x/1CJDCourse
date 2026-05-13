////////////////////////////////////////////////////////////////////////////////
// HANDLER OF INTERFACE OF PERMISSION MANAGEMENT CONTROL MESSAGES
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns a namespace of the current (used by the calling code) message interface version.
//
// Returns:
//	String - 
Function Package() Export
	
	Return "http://www.1c.ru/1cFresh/Application/Permissions/Control/" + Version(); // @Non-NLS-1
	
EndFunction

// Returns the current (used by the calling code) message interface version.
//
// Returns:
//	String - 
Function Version() Export
	
	Return "1.0.0.1";
	
EndFunction

// Returns the name of the message API.
//
// Returns:
//	String - 
Function Public() Export
	
	Return "ApplicationPermissionsControl";
	
EndFunction

// Registers message handlers as message exchange channel handlers.
//
// Parameters:
//  HandlersArray - Array - an array of handlers.
//
Procedure MessagesChannelsHandlers(Val HandlersArray) Export
	
	HandlersArray.Add(MessagesPermissionsManagementControlMessageHandler_1_0_0_1);
	
EndProcedure

// Registers message translation handlers.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  HandlersArray - Array - an array of handlers.
//
Procedure MessagesTranslationHandlers(Val HandlersArray) Export
EndProcedure

// Returns message type {http://www.1c.ru/1cFresh/Application/Permissions/Control/a.b.c.d}InfoBasePermissionsRequestProcessed
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTOValueType, XDTOObjectType - message type.
//
Function MessageInformationBasePermissionRequestProcessed(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "InfoBasePermissionsRequestProcessed");
	
EndFunction

// Returns message type {http://www.1c.ru/1cFresh/Application/Permissions/Control/a.b.c.d}ApplicationPermissionsRequestProcessed
//
// Parameters:
//  PackageToUse - String - a namespace of the message interface version, for which
//    the message type is being received.
//
// Returns:
//  XDTOValueType, XDTOObjectType - message type.
//
Function MessageProcessedRequestForDataAreaPermissions(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ApplicationPermissionsRequestProcessed");
	
EndFunction

// Dictionary of conversion of enumeration items to schema
// {http://www.1c.ru/1cFresh/Application/Permissions/Control/1.0.0.1}PermissionRequestProcessingResultTypes
// into the ExternalResourcesUsageQueriesProcessingResultsSaaS enumeration items.
//
// Returns:
//	FixedStructure - with the following fields::
//	* Approved - EnumRef.ExternalResourcesUsageQueriesProcessingResultsSaaS - approved.
//	* Rejected - EnumRef.ExternalResourcesUsageQueriesProcessingResultsSaaS - rejected.
Function DictionaryOfQueryResultTypes() Export
	
	Result = New Structure();
	
	Result.Insert("Approved", Enums.ExternalResourcesUsageQueriesProcessingResultsSaaS.RequestApproved);
	Result.Insert("Rejected", Enums.ExternalResourcesUsageQueriesProcessingResultsSaaS.RequestRejected);
	
	Return New FixedStructure(Result);
	
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
