#Region Public

// Returns managers of logical storages.
//
// Returns:
//  FixedMap - Logical storage managers.:
//    * Key - String - a logical storage ID;
//    * Value - CommonModule - a logical storage manager.
//
Function AllLogicalStorageManagers() Export
	
	Return DataTransferCached.LogicalStorageManagers();
	
EndFunction

// Returns physical storage managers.
//
// Returns:
//  FixedMap - Physical storage managers.:
//    * Key - String - a physical storage ID.
//    * Value - CommonModule - a physical storage manager.
//
Function AllPhysicalStorageManagers() Export
	
	Return DataTransferCached.PhysicalStorageManagers();
	
EndFunction

// Gets data from a logical storage.
//
// Parameters:
//   AccessParameters - Structure - The following fields:
//     * URL - String - Mandatory service URL.
//     * UserName - String - username;
//     * Password - String - User password.
//     * Cache - Map - (Optional) Empty mapping. If specified, it can be used for caching.
//   StorageID - String - Logical storage ID.
//   Id - String - data ID in a logical storage.
//   Span - Structure - 
//     * Start - Number - First byte.
//     * Start - Number - First byte.
//   FileName - String, Undefined - Name of the file to write the data to.
//
// Returns:
//   Structure - File details.:
//	   * Name - String - a file name;
//	   * FullName - String - full file name including a file path.
//
Function GetFromLogicalStorage(AccessParameters, StorageID, Id, Span = Undefined, FileName = Undefined) Export
	
	Return DataTransferInternal.Get(AccessParameters, False, StorageID, Id, Span, FileName);
	
EndFunction

// Retrieves the file information from the logic storage.
//
// Parameters:
//   AccessParameters - Structure - The following fields:
//     * URL - String - Mandatory service URL.
//     * UserName - String - Username.
//     * Password - String - User password.
//   StorageID - String - Logical storage ID.
//   Id - String - data ID in a logical storage.
//
// Returns:
//   Number - file size in bytes.
//
Function GetFileSizeFromLogicalStorage(AccessParameters, StorageID, Id) Export
	
	Return DataTransferInternal.GetFileSize(AccessParameters, False, StorageID, Id);
	
EndFunction

// Gets data from a physical storage.
//
// Parameters:
//   AccessParameters - Structure - The following fields:
//     * URL - String - Mandatory service URL.
//     * UserName - String - username;
//     * Password - String - User password.
//   StorageID - String - a physical storage ID.
//   Id - String - data ID in a physical storage.
//   FileName - String, Undefined - Name of the file to write the data to.
//
// Returns:
//   Structure - File details.:
//	   * Name - String - a file name;
//	   * FullName - String - full file name including a file path.
//
Function GetFromPhysicalStorage(AccessParameters, StorageID, Id, FileName = Undefined) Export
	
	Return DataTransferInternal.Get(AccessParameters, True, StorageID, Id,, FileName);
	
EndFunction

// Sends data to a logical storage.
//
// Parameters:
//   AccessParameters - Structure - The following fields:
//     * URL - String - Mandatory service URL.
//     * UserName - String - username;
//     * Password - String - User password.
//   StorageID - String - Logical storage ID.
//   Data - String - data address in a temporary storage.
//          - String - full file name including a file path.
//          - File - a file object.
//          - BinaryData - value in the binary data format.
//   FileName - String - name of the file to be passed.
//   AdditionalParameters - Structure - a structure with the values to be serialized to JSON.
//
Function SendToLogicalStorage(AccessParameters, StorageID, Data, Val FileName, AdditionalParameters = Undefined) Export
	
	Return DataTransferInternal.Send(AccessParameters, False, StorageID, Data, FileName, AdditionalParameters);
	
EndFunction

// Starts uploading the file to the logical storage.
//
// Parameters:
//   AccessParameters - Structure - The following fields:
//     * URL - String - Mandatory service URL.
//     * UserName - String - Username.
//     * Password - String - User password.
//   StorageID - String - Logical storage ID.
//   Data - String - data address in a temporary storage.
//          - String - full file name including a file path.
//          - File - a file object.
//          - BinaryData - value in the binary data format.
//   FileName - String - name of the file to be passed.
//   AdditionalParameters - Structure - a structure with the values to be serialized to JSON.
//
// Returns:
//   Structure - The following fields::
//     Location - String -
//     SetCookie - String - 
//     S3Address - String - 
//     S3FileID - String - 
//     ShouldSendInChunks - Boolean - 
//
Function StartSendingToLogicalStorage(AccessParameters, StorageID, Data, Val FileName, AdditionalParameters = Undefined) Export
	
	Return DataTransferInternal.StartSending(AccessParameters, False, StorageID, Data, FileName, AdditionalParameters);
	
EndFunction

// Sends the next data chunk.
//
// Parameters:
//   AccessParameters - Structure - The following fields:
//     * URL - String - Mandatory service URL.
//     * UserName - String - Username.
//     * Password - String - User password.
//   SendOptions - Structure - The following fields::
//     Location - String -
//     SetCookie - String - 
//     S3Address - String - 
//     S3FileID - String - 
//     ShouldSendInChunks - Boolean - 
// 
// Returns:
//   Number, Undefined - If sent successfully, the byte count. Otherwise, Undefined.
//
Function SendPartOfFileToLogicalStorage(AccessParameters, SendOptions, Data, LastPart = True, Offset = 0) Export
	
	Return DataTransferInternal.SendPartOfFile(AccessParameters, SendOptions, Data, LastPart, Offset);
	
EndFunction

// Sends data to a physical storage.
//
// Parameters:
//   AccessParameters - Structure - The following fields:
//     * URL - String - Mandatory service URL.
//     * UserName - String - username;
//     * Password - String - User password.
//   StorageID - String - a physical storage ID.
//   Data - String - data address in a temporary storage.
//          - String - full file name including a file path.
//          - File - a file object.
//          - BinaryData - value in the binary data format.
//   FileName - String - name of the file to be passed.
//
Function SendToPhysicalStorage(AccessParameters, StorageID, Data, Val FileName) Export
	
	Return DataTransferInternal.Send(AccessParameters, True, StorageID, Data, FileName);
	
EndFunction

#EndRegion