#Region Internal

// Error detailed presentation.
// Intended for handling warnings about obsolete methods in configurations with compatibility mode with v.8.3.17 and earlier.
// 
// Parameters:
// 	ErrorInfo - ErrorInfo
// Returns:
// 	String
Function DetailedErrorText(ErrorInfo) Export
	
	//@skip-warning
	Return ErrorProcessing.DetailErrorDescription(ErrorInfo);
	
EndFunction

// Error brief presentation.
// Intended for handling warnings about obsolete methods in configurations with compatibility mode with v.8.3.17 and earlier.
// 
// Parameters:
// 	ErrorInfo - ErrorInfo
// Returns:
// 	String
Function ShortErrorText(ErrorInfo) Export
	
	//@skip-warning
	Return ErrorProcessing.BriefErrorDescription(ErrorInfo);
	
EndFunction
	
#EndRegion