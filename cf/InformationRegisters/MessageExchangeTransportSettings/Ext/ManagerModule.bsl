#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// For internal use.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//	Endpoint - ExchangePlanRef.MessagesExchange - an endpoint,
//	AuthenticationParameters - String - password, or
//							- Structure - with the following fields::
//								* UseCurrentUser - Boolean - 
//								* Password - String - not required.
//		
// Returns:
//	Structure - with the following fields::
//		* DefaultExchangeMessagesTransportKind - EnumRef.ExchangeMessagesTransportTypes - 
//		* WSWebServiceURL - String -
//		* WSUserName - String -
//		* WSRememberPassword - Boolean -
//		* WSPassword - String -
Function TransportSettingsWS(Endpoint, AuthenticationParameters = Undefined) Export
EndFunction

#EndRegion

#EndIf