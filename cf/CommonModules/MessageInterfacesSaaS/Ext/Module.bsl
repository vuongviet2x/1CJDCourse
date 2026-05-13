// @strict-types

#Region Public

// Returns the message interface versions supported by the correspondent infobase.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  MessageInterface - String - Message API name.
//  ConnectionParameters - Structure - Peer infobase connection parameters.
//  RecipientPresentation1 - String - Peer infobase presentation.
//  CurIBInterface - String - Application interface name for the current infobase.
//    Used for backward compatibility purposes.
//
// Returns:
//  String - the latest interface version supported both by the correspondent infobase and the current infobase.
//
Function CorrespondentInterfaceVersion(Val MessageInterface, Val ConnectionParameters, 
	Val RecipientPresentation1, Val CurIBInterface = "") Export	
EndFunction

#EndRegion

#Region Internal

// See CommonOverridable.OnDefineSupportedInterfaceVersions
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//	SupportedVersionsStructure 
//	 - See CommonOverridable.OnDefineSupportedInterfaceVersions.SupportedVersions
//
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export
EndProcedure

// See MessagesExchangeOverridable.GetMessagesChannelsHandlers
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//	Handlers - See MessagesExchangeOverridable.GetMessagesChannelsHandlers.Handlers
//
Procedure OnDefineMessagesChannelsHandlers(Handlers) Export
EndProcedure

// Returns the fixed array filled in with common modules 
// that are handlers of incoming message interface.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//  FixedArray of CommonModule
//
Function GetHandlersForReceivedMessageInterfaces() Export
EndFunction

// Returns message channel names from the specified package.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  PackageURI - String - URI of XDTO package whose message types to be received.
//  BaseType - XDTODataObject - a base type.
//
// Returns:
//  FixedArray of String - channel names in the package.
//
Function GetPackageChannels(Val PackageURI, Val BaseType) Export	
EndFunction

#EndRegion

