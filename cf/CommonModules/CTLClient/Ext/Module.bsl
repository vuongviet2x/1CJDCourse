// @strict-types

#Region Public

#Region ExtensionStatistics

// Registers the extension operation event in the "Custom" event group
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//	EventIdentifier - String - Event ID obtained from a user account in the Service Manager. The length is 36 characters.
//
// Example:
//	CTLClient.RegisterExtensionStatisticsEvent("2f1df77a-9f07-11e9-9d8c-0242ac1d0004")
//
Procedure CaptureExtensionStatisticsEvent(Val EventIdentifier) Export
EndProcedure

#EndRegion

#EndRegion