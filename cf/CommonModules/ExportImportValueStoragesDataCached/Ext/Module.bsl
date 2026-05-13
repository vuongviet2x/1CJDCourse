////////////////////////////////////////////////////////////////////////////////
// "Data import and export" subsystem.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns a list of metadata objects that have properties using the ValueStorage type.
// 
// Returns: 
//	See ExportImportDataInternal.ReferencesToTypes
//
Function ListOfMetadataObjectsThatHaveValueStore() Export
	
	Types = CommonClientServer.ValueInArray(
		Type("ValueStorage"));
	
	Return ExportImportDataInternal.ReferencesToTypes(Types);
	
EndFunction

#EndRegion
