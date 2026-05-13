
#Region Public

// The function translates an arbitrary XDTO object 
// between versions by translation handlers registered in the system
// defining a resulting version by a namespace of a resulting message.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  InitialObject - XDTODataObject - Object to be translated.
//  ResultingVersion - String - Number of the final API version in the- format RR.{S|SS}.ZZ.CC.
//  SourceVersionPackage - String - message version namespace.
//
// Returns:
//  XDTODataObject - object translation result.
//
Function TranslateToVersion(Val InitialObject, Val ResultingVersion,
		Val SourceVersionPackage = "") Export
EndFunction

// The function translates an arbitrary XDTO object 
// between versions by translation handlers registered in the system
// defining a resulting version by a namespace of a resulting message.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  InitialObject - XDTODataObject - Object to be translated.
//  ResultingVersionPackage - String - Final version namespace.
//  SourceVersionPackage - String - message version namespace.
//
// Returns:
//  XDTODataObject - object translation result.
//
Function TranslateToNamespace(Val InitialObject,
		Val ResultingVersionPackage, Val SourceVersionPackage = "") Export
EndFunction

#EndRegion
