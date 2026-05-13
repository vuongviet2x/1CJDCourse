#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns object attributes that can be edited using the bulk attribute modification data processor.
// 
//
// Returns:
//  Array of String - a list of object attribute names.
Function AttributesToEditInBatchProcessing() Export
	
	Return FilesOperations.AttributesToEditInBatchProcessing();
	
EndFunction

#EndRegion

#EndIf
