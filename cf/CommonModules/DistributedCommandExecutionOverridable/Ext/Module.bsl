// @strict-types

#Region Public

// Called when receiving a message that a file from another data area is passed.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//	FileName - String - a full name to the file being passed.
//	CallID - UUID - to identify a specific call.
//	SenderCode - Number - a code of the data area, from which the file was passed.
//	CallParameters - Structure - Additional call parameters:
//						*Code (Number), *Body (String).
//	Processed - Boolean - indicates that message is processed successfully.
//
Procedure ProcessFileTransferRequest(FileName, CallID, SenderCode, CallParameters, Processed) Export

EndProcedure

// Called when receiving the "Success" receipt for passing a file from another data area.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//	CallID - UUID - to identify a specific call.
//	SenderCode - Number - a code of the data area, from which the file was passed.
//	CallParameters - Structure - Additional call parameters:
//						*Code (Number), *Body (String).
//	Processed - Boolean - indicates that message is processed successfully.
//
Procedure ProcessResponseToFileTransfer(CallID, SenderCode, CallParameters, Processed) Export

EndProcedure

// Called when receiving the "Error" receipt for passing a file from another data area.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//	CallID - UUID - to identify a specific call.
//	SenderCode - Number - a code of the data area, from which the file was passed.
//	ErrorText - String - an error description 
//	Processed - Boolean - indicates that message is processed successfully.
//
Procedure HandleFileTransferError(CallID, SenderCode, ErrorText, Processed) Export

EndProcedure

#EndRegion