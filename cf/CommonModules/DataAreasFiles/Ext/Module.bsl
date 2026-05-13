
#Region Public

// Parameters:
//	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
//
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.DataAreasFiles);
	
EndProcedure

// Returns a name, size, location, or binary data of a file by an ID.
// If the file is stored on hard drive, file location is returned to the FullName value.
// If the file is stored in the infobase, binary data is returned to the Data value. 
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//  DataArea - Number - data area number.
//  Id - String - File ID. The length is 36 characters.
// 
// Returns:
//  Structure - File details, see NewDescriptionOfFile:
//	 * FileName - String - file name
//	 * Size - Number - the file size in bytes
//	 * FullName - String, Undefined - file location on the volume.
//	 * Data - BinaryData, Undefined - binary file data.
//	 * CRC32 - Number - a checksum of file data.
//	 * SetTemporaryOnGet - Boolean - a flag of a temporary file upon receipt.
//
Function FileDetails(Val DataArea, Val Id) Export
EndFunction

// Returns binary data of a file by an ID.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//  DataArea - Number - data area number.
//  Id - String - File ID. The length is 36 characters.
//
// Returns:
//  BinaryData - binary file data.
//
Function FileBinaryData(Val DataArea, Val Id) Export
EndFunction

// Puts file data to a temporary storage and returns details
// to save or open the file.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataArea - Number - data area number.
//  FileID - UUID - file ID. 
//  FormIdentifier - UUID - the form ID to put.
// 
// Returns:
//  TransferableFileDescription - DetailsOfFileToPass - details to save or open the file.
//
Function TransferableFileDescription(Val DataArea, FileID, FormIdentifier) Export
EndFunction

// Saves data as a file record to the DataAreaFiles information register.
// If the Data parameter = Undefined, fill in the FullName parameter = a full name of a file with a path.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataArea - Number - data area number.
//  Name - String - file name in the storage.
//  Data - BinaryData, String, Undefined - binary file data if FullName = Undefined.
//  FullName - String, Undefined - a full file name with a path if Data = Undefined.
//  Temp - Boolean - - indicates that a file is temporary and it will be deleted according to the schedule of the TemporaryDataAreasFilesDeletion scheduled job.
//  SetTemporaryOnGet - Boolean - set the flag of a temporary file upon first receipt.
//
// Returns:
//  UUID - File ID.
//
Function ImportFile_(Val DataArea, Val Name, Data = Undefined, FullName = Undefined, 
	Temp = False, SetTemporaryOnGet = False) Export
EndFunction

// Sets a file flag "Temporary" = True.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataArea - Number - data area number.
//  FileID - UUID -  file ID.
//  
// Returns:
//	Boolean - True if the flag is set, otherwise, False.
Function SetTemporaryFlag(Val DataArea, Val FileID) Export
EndFunction

// Delete a file from the infobase
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataArea - Number - data area number.
//  FileID - UUID -  an ID of the file being deleted.
//  DeleteIfOnDisk - Boolean - if False and file is stored on the hard drive, it is registered as temporary and not deleted from the hard drive.
//
// Returns:
//  Boolean - Deletion flag.
//
Function DeleteFile(Val DataArea, Val FileID, Val DeleteIfOnDisk = True) Export
EndFunction

#EndRegion
