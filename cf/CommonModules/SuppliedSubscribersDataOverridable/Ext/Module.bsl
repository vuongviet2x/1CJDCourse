///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2019, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions intended for the "SuppliedSubscribersData" subsystem.
// Common module "SuppliedSubscribersDataOverridable".
//

#Region Public

// Import data handler.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  DataStream - FileStream - Data thread to be processed.
//  Handler  - String - Import data handler ID.
//  DataProcessed - Boolean - Data process flag. If True, data is processed.
//                     Cannot be set to False because True can be set earlier.
//  ReturnCode - Number - Return code for handler values InformationRegisters.JobsProperties.StatusesCodes()
//  ErrorDescription - String - Data processing error details (if the procession has failed).
//
Procedure ProcessReceivedData(DataStream, Handler, DataProcessed, ReturnCode, ErrorDescription) Export
EndProcedure

#EndRegion
