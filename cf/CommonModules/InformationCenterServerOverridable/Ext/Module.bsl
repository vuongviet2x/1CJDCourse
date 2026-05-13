
#Region Public

// Defines information search reference.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//	InformationSearchRef - String - Address.
//	
// Example:
//	If you append a search string to a link and follow this link, the search result page will open.
//	
//	
Procedure DefineInformationSearchLink(InformationSearchRef) Export
EndProcedure

// Defines common templates with external links.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//  ArrayOfTemplates - Array of SpreadsheetDocument - Array of common templates.
//
Procedure CommonTemplatesWithInformationLinks(ArrayOfTemplates) Export
EndProcedure

// Determines an array of full paths to the forms that contain external links.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  ArrayOfForms - Array of String - Array of full paths to forms.
//
Procedure FormsWithInformationLinks(ArrayOfForms) Export
EndProcedure

#EndRegion