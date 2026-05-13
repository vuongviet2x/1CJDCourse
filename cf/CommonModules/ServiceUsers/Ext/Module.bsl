
#Region Public

// Returns a flag indicating that common user authentication settings are used in the service.
// @skip-warning
// @skip-check module-empty-method - Implementation feature.
// 
// Returns:
//  Boolean
Function UseCommonSettingsOfServiceUserAuthorization() Export
EndFunction

// Update the service user activity.
// @skip-warning
// @skip-check module-empty-method - Implementation feature.
// 
// Parameters:
//  CurrentUser - Undefined - Current authorized user.
//  					- CatalogRef.Users
//  LastActivityDate - Undefined - Start of day of the current session date.
//							- Date
Procedure UpdateActivityOfServiceUser(
	CurrentUser = Undefined,
	LastActivityDate = Undefined) Export
EndProcedure

#EndRegion
