// @strict-types

#Region Public

#Region ReturnCodes

// Returns the data error code.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//	Number - a standard return code by the method name.
//
Function ReturnCodeDataError() Export
EndFunction

// Returns the authorization rejection code.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//	Number - a standard return code by the method name.
//
Function AuthorizationDeniedReturnCode() Export
EndFunction

// Returns the internal error code.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//	Number - a standard return code by the method name.
//
Function ReturnCodeInternalError() Export
EndFunction

// Returns the code of runtime with warnings.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//	Number - a standard return code by the method name.
//
Function ReturnCodeCompletedWithWarnings() Export
EndFunction

// Returns the code of succeeded runtime.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//	Number - a standard return code by the method name.
//
Function ReturnCodeCompleted() Export
EndFunction

// Returns the code of data wait.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//	Number - Standard return code by method name.
//
Function StateCodePending() Export
EndFunction

// Returns the code of data missing.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//	Number - a standard return code by the method name.
//
Function ReturnCodeNotFound() Export
EndFunction

#EndRegion

#Region FilesTypes

// Returns a line with the JSON file type
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//	String - "json"
//
Function JSONType() Export
EndFunction

// Returns a line with the XLSX file type
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//	String - "xlsx"
//
Function TypeXLSX() Export
EndFunction

// Returns a line with the PDF file type
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//	String - "pdf"
//
Function TypePDF() Export
EndFunction

#EndRegion

#EndRegion
