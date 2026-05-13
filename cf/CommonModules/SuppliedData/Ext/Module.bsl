///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2018, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Receive data descriptors by the given criteria.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataKind - String - Built-in data kind name.
//  Filter - Array - the items should contain the following fields: Code (string) and Value (string).
//
// Returns:
//    XDTODataObject - ArrayOfDescriptor type.
//
Function DescriptorsOfSuppliedDataFromManager(Val DataKind, Val Filter = Undefined) Export  
EndFunction

// Initiates data processing.
//
// Can be used with SuppliedDataFromCacheDescriptors to 
// initiate data processing manually. After calling the method, the system behaves 
// as if it has just received a notification that new data is available, 
// with the specified descriptor - NewDataAvailable is called, then, if necessary, 
// ProcessNewData is called for the corresponding handlers.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//   Descriptor - XDTODataObject - Descriptor.
//
Procedure UploadAndProcessData(Val Descriptor) Export
EndProcedure
	
// Saves data to the SuppliedData catalog to either a hard drive or to a field in the SuppliedData table.
//
// The save option depends on StoreFilesInVolumesOnHardDrive and the volume availability. 
// The data can be later extracted either using search by attributes or by specifying a UUID that was passed to the Descriptor.FileGUID field. 
// If the infobase already contains data with the same data kind and set of key characteristics, it is replaced with the new data. 
// The existing catalog item is updated (no new item is created). 
// @skip-warning EmptyMethod - Implementation feature. 
//  
// 
// 
//
// Parameters:
//   Descriptor - XDTODataObject - Descriptor or Structure with the following fields:
//	 	DataKind, AddedOn, FileID, Characteristics.
//    	Characteristics is an array of Structure with the following fields: Code, Value, Key.
//   PathToFile - String - Extracted file full name.
//
Procedure SaveSuppliedDataToCache(Val Descriptor, Val PathToFile) Export
EndProcedure

// Deletes a file from the cache.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  LinkOrID - CatalogRef.SuppliedData - Reference to the default master data.
//                         - UUID - UUID.
//
Procedure DeleteSuppliedDataFromCache(Val LinkOrID) Export
EndProcedure

// Receives a descriptor of data in cache.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  LinkOrID - CatalogRef.SuppliedData - Reference to the default master data.
//                         - UUID - UUID,
//  InFormOfXDTO - Boolean - Return value format.
//
// Returns:
//    XDTODataObject - ArrayOfDescriptor type.
//
Function DescriptorOfSuppliedDataFromCache(Val LinkOrID, Val InFormOfXDTO = False) Export
EndFunction

// Returns binary data of an attachment.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  LinkOrID - CatalogRef.SuppliedData - Reference to a default master data record.
//                         - UUID - UUID.
//
// Returns:
//  BinaryData - binary data of supplied data.
//
Function SuppliedDataFromCache(Val LinkOrID) Export
EndFunction

// Checks the availability of the data with the specified key characteristics in cache.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//   Descriptor - XDTODataObject - Descriptor.
//
// Returns:
//  Boolean - the presence of descriptor in the cache.
//
Function AvailableInCache(Val Descriptor) Export
EndFunction

// Returns the array of references to the data that meets the specified criteria.
//
// Parameters:
//  DataKind - String - Name of a default master data kind.
//  Filter - Array - Items must contain the fields Code (String) and Value (String).
//
// Returns:
//    Array of AnyRef - array of data references.
//
Function ReferencesSuppliedDataFromCache(Val DataKind, Val Filter = Undefined) Export

	Return New Array();
	
EndFunction

// Receive data by the given criteria.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataKind - String - Built-in data kind name.
//  Filter - Array - Items must contain the fields Code (String) and Value (String).
//  InFormOfXDTO - Boolean - Return value format.
//
// Returns:
//    XDTODataObject - Has the ArrayOfDescriptor type. Or it's an Array of Structure with the fields:
//    DataKind, AddedOn, FileID, Characteristics.
//    Characteristics - Array of Structure with the fields: Code, Value, KeyStructure.
//	  To get the file, call GetSuppliedDataFromCache.
//
//
Function DescriptorsOfSuppliedDataFromCache(Val DataKind, Val Filter = Undefined, Val InFormOfXDTO = False) Export
EndFunction	

// Returns the user presentation of a default master data descriptor.
// Can be used when writing messages to the event log.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  Descriptor - XDTODataObject - Descriptor or Structure with the following fields:
//	 	DataKind, AddedOn, FileID, Characteristics.
//    	Characteristics is an array of Structure with the following fields: Code, Value.
//	JSONDescriptor - Boolean - JSON format description flag.
//
// Returns:
//  String - custom descriptor presentation.
//
Function GetDataDescription(Val Descriptor, Val JSONDescriptor = False) Export
EndFunction

// Returns registered default master data handlers.
// Starts a procedure that checks and imports new default master data.
// Also can be used to receive a list of supported default master data kinds.
//
// Returns:
//	ValueTable - Table with the following columns:
//		* DataKind - String - Code of the data kind being processed by the handler.
//		* HandlerCode - String - Intended to recover a failed data processor.
//		* Handler - CommonModule - Module with the following export procedures:
//			NewDataAvailable(Descriptor, Import)  
//			ProcessNewData(Descriptor, PathToFile)
//			DataProcessingCanceled(Descriptor)
//
Function GetHandlers() Export
	
	Handlers = New ValueTable;
	Handlers.Columns.Add("DataKind");
	Handlers.Columns.Add("Handler");
	Handlers.Columns.Add("HandlerCode");
	
	CTLSubsystemsIntegration.OnDefineSuppliedDataHandlers(Handlers);
	SuppliedDataOverridable.GetHandlersForSuppliedData(Handlers);
	
	Return Handlers;
	
EndFunction	

///////////////////////////////////////////////////////////////////////////////////
// Update information in data areas.

// Returns a list of data areas where default master data has not been copied yet.
// @skip-warning EmptyMethod - Implementation feature.
//
// On the first function call, the full set of available areas is returned.
// On the further call, when restoring after an error, only
// unprocessed areas are returned. After the data is copied to the areas, call AreaProcessed.
//
// Parameters:
//  FileID - UUID - Default master data file ID.
//  HandlerCode - String - Handler code.
//  IncludingUndivided - Boolean - if True,  add to all the current areas an area with the code "-1".
// 
// Returns:
//  Array of Number - areas that require processing.
//
Function AreasRequiringProcessing(Val FileID, Val HandlerCode, Val IncludingUndivided = False) Export
EndFunction

// Deletes an area from the list of unprocessed areas. Disables session separation (if it was enabled)
// as saving to a shared register is denied when separation is enabled.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  FileID - UUID - Default master data file ID.
//  HandlerCode - String - Handler code.
//  DataArea - Number - Processed area ID.
// 
Procedure AreaProcessed(Val FileID, Val HandlerCode, Val DataArea) Export
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Subsystem event handlers.

// See JobsQueueOverridable.OnDefineHandlerAliases.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
EndProcedure

// See MessagesExchangeOverridable.GetMessagesChannelsHandlers.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure OnDefineMessagesChannelsHandlers(Handlers) Export
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.SuppliedDataRequiringProcessingInAreas);
	
EndProcedure

#Region OutdatedProgrammingInterface

// Deprecated. Initiate a notification about all default master data that is available in the service manager (except for those
// marked with "Notification restricted".
// @skip-warning EmptyMethod - implementation feature.
// 
//
Procedure RequestAllData() Export
EndProcedure

#EndRegion

#EndRegion
