///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "OnlineUserSupport.PickName" subsystem.
// CommonModule.PickNameClient.
//
// Client procedures for name classifier management:
//  - Return classifier entries by the passed search parameters
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the search result. Or an empty array if nothing is found.
//
// Parameters:
//  SearchMode_ - String - Valid search mode values are::
//    "LastName", "Name" (meaning, first name), "MiddleName", "LastFirstName".
//  FullNameData - Structure, Undefined - Describes the full name passed for searching.
//    The structure is used to determine the gender if "Gender" is not specified:
//    * LastName - String, Undefined - Person's last name (if "SearchMode_" is set to "LastName"). Optional.
//      
//    * Name - String, Undefined - Person's first name (if "SearchMode_" is set to "Name"). Optional.
//      
//    * MiddleName - String, Undefined - Person's middle name (if "SearchMode_" is set to "MiddleName"). Optional.
//      
//    * Presentation - String - Person's full name (if "SearchMode_" is set to "LastFirstName"). Optional.
//      
//  Gender - Number - The person's gender that will be used in the search. Valid values are::
//    0 - None (will be auto-determined from "FullNameData"; 1 - Male; 2 - Female; 3 - Either one is possible.
//  SelectionSize - Number - Determines the dataset size.
// Returns:
//   Array of String - Search data sorted by frequency.
//
Function Pick(
		SearchMode_,
		FullNameData = Undefined,
		Gender = 0,
		SelectionSize = 10) Export
	
	Return PickNameServerCall.Pick(
		SearchMode_,
		FullNameData,
		Gender,
		SelectionSize);
	
EndFunction

// Returns the auto-determined person's gender.
//
// Parameters:
//  FullNameData - Structure, Undefined - Data of the last name used in the search.
//    * LastName - String, Undefined - Person's last name (if the SearchMode is set to "LastName").
//      Data of the last name used in the search.
//    * LastName - String, Undefined - Person's last name (if the SearchMode is set to "LastName").               
//      
//    
//      
//  Returns:
//    Number - Valid values are::
//      1 - Male; 2 - Female; 3 - Either one is possible.
//
Function DetermineGender(FullNameData) Export
	
	Return PickNameServerCall.DetermineGender(FullNameData);
	
EndFunction

// Searches for classifier entries by the passed name components.
//
// Parameters:
//  NameComponents - Array of String - Data to be searched.
//  CompleteCoincidence - Boolean - If set to "True", the "Equal" operator is used.
//   If set to "False", the "Like" operator is used.
//   The function supports a wildcard character to search by substrings. For example, "Tom%".
//   
//
//  Returns:
//    Structure - Search result:
//    * LastNames - Array of Structure - Found last names:
//      ** Value - String - Found value.
//      ** DisplayPriority - Number - Value priority. Optional.
//      
//    * Names - Array of Structure - Found first names:
//      ** Value - String - Found value.
//      ** DisplayPriority - Number - Value priority.
//    * MiddleNames - Array of Structure - Found middle names:
//      ** Value - String - Found value.
//
// Example:
//	NameComponents = New Array;
//	NameComponents.Add("Tom%");
//	Result = PickName.FindName(NameComponents, False);
//
Function FindName(
		NameComponents,
		CompleteCoincidence = True) Export
	
	Return PickNameServerCall.FindName(
		NameComponents,
		CompleteCoincidence);
	
EndFunction

#EndRegion