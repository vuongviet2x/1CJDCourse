///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "OnlineUserSupport.SaaS.ClassifiersOperations" subsystem.
// CommonModule.ClassifiersOperationsSaaSOverridable.
//
// Server overridable procedures for importing classifiers:
//  - Determine classifier IDs
//  - Determine data area processing algorithms
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Determines classifier IDs that must be included to the configuration manifest for the Service Manager.
// Fill the method implementation in cases where classifier import depends
// on configuration settings (such as functional options and constants).
// 
//
// Parameters:
//  IDs - Array of String - A classifier ID to add to the manifest.
//
// Example:
//	IDs.Ass("CentralBankRefinancingRate");
//
//@skip-warning
Procedure OnDefineClassifiersIDs(IDs) Export
	
	
EndProcedure

// Algorithms for processing the area are redefined after importing default master data from classifiers.
// 
//
// Parameters:
//  Id           - String - FileAddress - String - a file address in a temporary storage.
//                            It is defined in the OnAddClassifiers procedure.
//  Version                  - Number - a number of the imported version.
//  AdditionalParameters - Structure - contains additional processing parameters
//                            that were filled in the
//                            ClassifiersOperationsOverridable.OnImportClassifier overridable method
//                            and in the OSLSubsystemsIntegration.OnImportClassifier method.
//
// Example:
//	If ID = "CentralBankRefinancingRate" Then
//		Documents.CompensationForLateSalaryPayment.CompensationForLateSalaryPaymentRecalculation();
//	EndIf;
//
//@skip-warning
Procedure OnProcessDataArea(Id, Version, AdditionalParameters) Export
	
	
EndProcedure

#EndRegion
