// @strict-types

#Region Public

// Opens the extension object form from the Extension Store.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
// 	PublicId - String - Public ID of an extension from the Service Manager.
// 	NotifyDescription - NotifyDescription - (Optional) Provides for form closing processing.
// 		The procedure that will process the notification details call is specified as the first parameter.
// 		It gets the value of type EnumRef.ExtensionStates that describe the extension status at the moment it was closed.
// 		For details, see the OpenForm global context method.
//
Procedure OpenExtensionObject(Val PublicId, Val NotifyDescription = Undefined) Export
EndProcedure

// Opens the Extension Store.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure OpenExtensionsDirectory() Export 
EndProcedure

// Offer the user to rate the extension. 
// Can only be used after a successful call to ExtensionsDirectory.UserRatingInformation.
// Analyze the result and, if necessary, call
// ExtensionsDirectoryClient.SuggestUserToRateExtension.
// When calling this procedure, the user will be shown a question with three 
// answer options: "Rate", "Rate later", and "Don't suggest again".
// If the user has previously selected the "Don't suggest again" response, the question dialog box will not appear.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//  PublicId - String - Public ID of an extension from the Service Manager.
//  SuggestionText - String - Text of the offer shown to the user.
//   If the text is not specified, the standard one will be used.
Procedure SuggestUserToRateExtension(PublicId, SuggestionText = "") Export
EndProcedure

#EndRegion
