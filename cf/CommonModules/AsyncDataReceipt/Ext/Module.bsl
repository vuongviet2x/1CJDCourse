// @strict-types

#Region Public

// Returns a storage id as a String.
// @skip-check module-empty-method - Design feature.
// @skip-warning - Backward compatibility.
// 
// Returns:
//	String - Storage ID. 
//
Function StorageID() Export
EndFunction

// Returns a new structure that describes return data.
// @skip-check module-empty-method - Design feature.
// @skip-warning - Backward compatibility.
// 
// Returns:
//	Structure:
//	 * ModuleManager_ - CommonModule, CatalogsManager, ReportsManager - Data get manager module.
//	 * Description - String - Description of a return data record.
//	 * LongDesc - String - return data details.
//	 * ResultTypes - Array of String - return data types.
//	 
Function NewDescriptionOfReturnedData() Export
EndFunction

// Returns a list of available data
// @skip-check module-empty-method - Design feature.
// @skip-warning - Backward compatibility.
// 
// Returns:
//	Map of KeyAndValue - A list of available return data:
//	 * Key - String - data ID.
//	 * Value - See AsyncDataReceipt.NewDescriptionOfReturnedData
//	
Function AvailableReturnData() Export
EndFunction

// See JobsQueueOverridable.OnDefineHandlerAliases.
// @skip-check module-empty-method - Design feature.
// @skip-warning - Backward compatibility.
// 
// Parameters:
//  NamesAndAliasesMap - See JobsQueueOverridable.OnDefineHandlerAliases.NamesAndAliasesMap
// 
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
EndProcedure

#Region JobsQueueHandlers

// Generates data to respond for the received parameters.
// @skip-check module-empty-method - Design feature.
// @skip-warning - Backward compatibility.
//
// Parameters:
//	DataID - String - ID of the data record to be retrieved.
//	ParameterId_ - UUID - ID of the retrieval settings file.
//
Procedure PrepareData(DataID, ParameterId_) Export
EndProcedure

#EndRegion

#EndRegion
 
