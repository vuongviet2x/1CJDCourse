// @strict-types

#Region Public

// Calls the command that starts the given additional data processor and passes parameters to the command.
// Registers a runtime result message for the Service Manager.
// NOTE. The method is called as a background job.
// @skip-warning - EmptyMethod - Implementation feature.
//
// Parameters:
//	ProcessingID - String - specifies data processor whose command needs to be performed.
//	CommandID - String - a name of the command to be performed as it is specified in the data processor.
//	OperationID - String - allows to identify separate calls (for example, for logging).
//	InformManager - Boolean - Flag indicating whether to send the command result to the Service Manager.
//
Procedure ExecuteAdditionalProcessingCommand(ProcessingID, CommandID, OperationID, InformManager = False) Export
EndProcedure 

// Calls a command that passes a file from the current data area to any other data 
// area of the service.
// Warning! If any parameter is passed incorrectly, an exception is called.
// @skip-warning - EmptyMethod - Implementation feature.
//
// Parameters:
//	FileName - String - a full name to the file being passed.
//	RecipientCode - Number - a code of the data area, to which the file is passed.
//	FastTransfer - Boolean - indicates that you need to use quick messages to pass the file. 
//	CallParameters - Structure - additional call parameters:
//		* Code - Number - a response code,
//		* Body - String - response body.
//
// Returns:
//   UUID - a call ID.
//
Function TransferFileToApplication(FileName, RecipientCode, FastTransfer = False, CallParameters = Undefined) Export
EndFunction

// Sends a message-receipt that the previously received file is received (processing is completed,
// etc.) to an area-recipient.
// Warning! If any parameter is passed incorrectly, an exception is called.
// @skip-warning - EmptyMethod - Implementation feature.
//
// Parameters:
//	CallID - UUID - an ID earlier issued b the PassFileToApplication function
//	RecipientCode - Number - a code of the data area, to which the receipt is passed.
//	FastTransfer - Boolean - indicates that you need to use quick messages to pass the file. 
//	CallParameters - Structure - additional call parameters:
//	  * Code - Number - a response code,
//	  * Body - String - response body.
//
Procedure SendFileTransferReceipt(CallID, RecipientCode, FastTransfer = False, CallParameters = Undefined) Export
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//	NamesAndAliasesMap - See JobsQueueOverridable.OnDefineHandlerAliases.NamesAndAliasesMap
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export 
EndProcedure

#EndRegion