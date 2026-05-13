///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2019, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// See JobsQueueOverridable.OnDefineHandlerAliases.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
EndProcedure

#Region JobsQueueHandlers

// Processes default subscriber data.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//	FileID - String - ID of the file to be processed. The length is 36 characters.
//
// Example:
// An example of the file content: {"upload": [{"file":"base_data.json","handler":"base_data"}]}
//  - upload - Describes the processing order. It can contain multiple items.
//  - file - Name of the initial data file for processing.
//  - handler - ID of the initial data handler.
//
Procedure ProcessData__(FileID) Export
EndProcedure

#EndRegion

#EndRegion

