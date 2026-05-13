///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2018, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns a number of the version, from which the translation by handler is used.
// @skip-warning - EmptyMethod - Implementation feature.
// 
// Returns:
//   String - a source version.
//
Function SourceVersion() Export
EndFunction

// Returns a namespace of the version, from which the translation by handler is used.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//   String - a source version package.
//
Function SourceVersionPackage() Export
EndFunction

// Returns a number of the version, to which the translation by handler is used.
// @skip-warning - EmptyMethod - Implementation feature.
// 
// Returns:
//   String - a resulting version.
//
Function ResultingVersion() Export
EndFunction

// Returns a namespace of the version, to which the translation by handler is used.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//   String - a resulting version package.
//
Function ResultingVersionPackage() Export
EndFunction

// Handler of checking the standard translation processing execution.
// @skip-warning - EmptyMethod - Implementation feature.
//
// Parameters:
//  SourceMessage - XDTODataObject - a message being translated,
//  StandardProcessing - Boolean - set
//    this parameter to False within this procedure to cancel standard translation processing.
//    The function is called instead of the standard translation processing
//    MessageTranslation() of the translation handler.
//
Procedure BeforeTranslate(Val SourceMessage, StandardProcessing) Export
EndProcedure

// Handler of executing an arbitrary message translation. It is only called
//  if the value of the StandardProcessing parameter
//  was set to False when executing the BeforeTranslation procedure.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  SourceMessage - XDTODataObject - a message being translated.
//
// Returns:
//  XDTODataObject - a result of arbitrary message translation.
//
Function MessageTranslation(Val SourceMessage) Export
EndFunction

#EndRegion



