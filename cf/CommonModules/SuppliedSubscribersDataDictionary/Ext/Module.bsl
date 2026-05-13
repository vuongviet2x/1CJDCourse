///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2019, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
// @strict-types

#Region Public

#Region ReturnCodes

// Returns the data error code.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//   Number - a standard return code by the method name.
//
Function ReturnCodeDataError() Export
EndFunction

// Returns an internal error code.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//   Number - a standard return code by the method name.
//
Function ReturnCodeInternalError() Export
EndFunction

// Returns a runtime code with warnings.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//   Number - a standard return code by the method name. 
//
Function ReturnCodeCompletedWithWarnings() Export
EndFunction
	
// Returns a successful runtime code.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//   Number - a standard return code by the method name.
//
Function ReturnCodeCompleted() Export
EndFunction

// Returns a missed data code.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//   Number - a standard return code by the method name.
//
Function ReturnCodeNotFound() Export
EndFunction

#EndRegion

#EndRegion

