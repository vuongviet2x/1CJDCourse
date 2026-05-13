#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the object attributes that are not recommended to be edited
// using the processing of the bulk attribute modification.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//  Array of String - a list of object attribute names.
Function AttributesToSkipInBatchProcessing() Export
EndFunction

#EndRegion

#EndIf