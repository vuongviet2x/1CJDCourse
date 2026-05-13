#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in settings that affect the exchange plan usage.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//  Settings - See DataExchangeServer.ExchangePlanSettings
//
Procedure OnGetSettings(Settings) Export	
EndProcedure

// Fills in a set of parameters that define an exchange setup option.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//	OptionDetails - See DataExchangeServer.SettingOptionDetails
//  SettingID - String - ID of data exchange setup option.
//  ContextParameters - Structure - See DataExchangeServer.ContextParametersOfSettingOptionDetailsReceipt 
//  								 Function return value details. 
//
Procedure OnGetSettingOptionDetails(OptionDetails, SettingID,
	ContextParameters) Export
EndProcedure

// Returns the object attributes that are not recommended to be edited
// using the processing of the bulk attribute modification.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//  Array of String - a list of object attribute names.
//  
Function AttributesToSkipInBatchProcessing() Export	
EndFunction

#EndRegion

#EndIf