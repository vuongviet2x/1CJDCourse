#Region Public

// Determines logical storage managers.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   AllLogicalStorageManagers - Map -  Logical storage managers.
//    * Key - String - Logical storage ID.
//     Logical storage managers.
//    * Key - String - Logical storage ID.
//
Procedure LogicalStorageManagers(AllLogicalStorageManagers) Export
	
EndProcedure

// Determines physical storage managers.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   AllPhysicalStorageManagers - Map - * Value - CommonModule - Physical storage manager.
//    
//    * Value - CommonModule - Physical storage manager.
//
Procedure PhysicalStorageManagers(AllPhysicalStorageManagers) Export
	
EndProcedure

// Determines the ID validity period.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   ValidityPeriodOfTemporaryID - Number - validity period of a temporary ID.
//
Procedure ValidityPeriodOfTemporaryID(ValidityPeriodOfTemporaryID) Export
	
EndProcedure

// Determines the size of the data chunk being imported.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   DataBlockSize - Number - a size of the block for getting data (in bytes).
//
Procedure DataBlockSize(DataBlockSize) Export
	
EndProcedure

// Determines the size of the data chunk being exported.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   BlockSizeForSendingData - Number - a size of the block for sending data (in bytes).
//
Procedure BlockSizeForSendingData(BlockSizeForSendingData) Export
	
EndProcedure

// Runs upon a data import error.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   Response - HTTPServiceResponse - a service response when getting data.
//
Procedure ErrorReceivingData(Response) Export
	
EndProcedure

// Runs upon a data export error.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   Response - HTTPServiceResponse - a service response when sending data.
//
Procedure AnErrorOccurredWhileSendingData(Response) Export
	
EndProcedure

// Runs upon getting the temp file name.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   TempFileName - String - a temporary file name.
//   Extension - String - a desired extension of the temporary file name.
//   AdditionalParameters - Structure - Temp file additional parameters.
//
Procedure OnGetTemporaryFileName(TempFileName, Extension, AdditionalParameters) Export
	
EndProcedure

// Runs upon extending the temp ID validity period.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   Id - String - query ID.
//   Date - Date - a request registration date.
//   Query - Structure - * BasicURL - String - Fixed part of a URL request, which is the service name.
//    * Headers - FixedMap - HTTP request headers.
//                        * RelativeURL - String - Relative part of a URL address.
//                        * URLParameters - FixedMap - Parameterized parts of URL address.
//                        * RequestParameters - FixedMap - Request parameters that follow the query symbol.
//                        * RequestID - String - Request UUID.
//                        QueryType - String - Request type.
//                        * TempFileName- String - Name of the temp file.
//    * BasicURL - String - Fixed part of a URL request, which is the service name.
//    * Headers - FixedMap - HTTP request headers.
//    * RelativeURL - String - Relative part of a URL address.
//    * URLParameters - FixedMap - Parameterized parts of URL address.
//    * RequestParameters - FixedMap - Request parameters that follow the query symbol.
//    * RequestID - String - Request UUID.
//    QueryType - String - Request type.
//    * TempFileName- String - Name of the temp file.
//
Procedure OnExtendTemporaryIDValidity(Id, Date, Query) Export

EndProcedure

#EndRegion