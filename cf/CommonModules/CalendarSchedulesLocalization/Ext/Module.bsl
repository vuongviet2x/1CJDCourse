///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Requests a file with calendar classifier data. 
// Converts the retrieved file into a structure with calendar tables and their data.
// If the classifier file cannot be retrieved, throws an exception.
//
// Parameters:
//  ClassifierData - Structure:
//   * BusinessCalendars - Structure:
//     * TableName - String          - Table name.
//     * Data     - ValueTable - A calendar data table converted from XML.
//   * BusinessCalendarsData - Structure:
//     * TableName - String          - Table name.
//     * Data     - ValueTable - A calendar data table converted from XML.
//
Procedure WhenReceivingClassifierData(ClassifierData) Export
	
	
EndProcedure

#EndRegion