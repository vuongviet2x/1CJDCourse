// @strict-types

#Region Public

// Called when generating a list of available data to return and when receiving data. 
// Determines the list of data to return attached to the subsystem.
// @skip-warning EmptyMethod - Overridable method.
// 
// Parameters:
//  AvailableReturnData - Map of KeyAndValue - Available return data to be populated:
//    * Key - String - data ID.
//    * Value - See AsyncDataReceipt.NewDescriptionOfReturnedData
//
Procedure SetAvailableReturnData(AvailableReturnData) Export
EndProcedure

// Called upon the initial processing of an incoming query. Allows to execute applied logic
// related to incoming query validation and, if necessary, refuse to process the query.
// @skip-warning EmptyMethod - Overridable method.
// 
// Parameters:
//  DataID - String - data ID. It can be overridden upon processing.
//                                 It is specified as a name of the file returned as a result.
//  Parameters - BinaryData - passed parameters of getting data.
//  Cancel - Boolean - Return parameter. Authorization rejection flag. To reject authorization, set Cancel to True.
//  ErrorMessage - String - Return parameter. Text of the authorization rejection error message.
//  
Procedure AuthorizeRequest(DataID, Parameters, Cancel, ErrorMessage) Export
EndProcedure

#EndRegion