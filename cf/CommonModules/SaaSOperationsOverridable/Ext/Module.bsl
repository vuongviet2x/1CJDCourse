///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2018, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
// @strict-types

#Region Public

// Called when deleting data areas.
// Delete in the procedure the data area data that cannot be deleted with a standard mechanism.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   DataArea - Number - value of the separator of the data area to be deleted.
//
Procedure OnDeleteDataArea(Val DataArea) Export
EndProcedure

// Generates a list of infobase parameters.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   ParametersTable - See SaaSOperations.IBParameters
//
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
EndProcedure

// Called before an attempt to receive values of infobase parameters from constants with the same name.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   ParameterNames - Array - parameter names whose values are to be received.
//     							If the parameter value is received in this procedure, the processed parameter name 
//     							must be removed from the array.
//   ParameterValues - Structure - Parameter values.
//
Procedure OnGetIBParameterValues(Val ParameterNames, Val ParameterValues) Export
EndProcedure

// Called before an attempt to write values of infobase parameters to constants with the same name.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   ParameterValues - Structure - parameter values to be set.
//     If the parameter value is set in the procedure, the matching KeyAndValue pair must be deleted
//     from the structure.
//
Procedure OnSetIBParametersValues(Val ParameterValues) Export
EndProcedure

// Called when enabling data separation by data area,
// when starting the configuration with the "InitializeSeparatedIB" parameter for the first time.
// Here place a code to enable scheduled jobs used only with enabled 
// data separation and, accordingly, to disable jobs used only with disabled data separation.
// @skip-warning EmptyMethod - Overridable method.
//
Procedure OnEnableSeparationByDataAreas() Export
EndProcedure

// Sets default user rights.
// Runs in SaaS when updating user rights in Service Manager without administrator rights.
// @skip-warning EmptyMethod - Overridable method.
// 
//
// Parameters:
//  User - CatalogRef.Users - user, for which
//   default rights are to be set.
//
Procedure SetDefaultRights(User) Export
EndProcedure

#EndRegion
