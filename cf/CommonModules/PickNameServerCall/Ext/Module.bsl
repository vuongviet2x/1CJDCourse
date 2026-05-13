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
// CommonModule.PickNameServerCall.
//
// Server procedures for name classifier management:
//  - Return classifier entries by the passed search parameters
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// See PickName.Pick.
//
Function Pick(
		Val SearchMode_,
		Val FullNameData,
		Val Gender,
		Val SelectionSize) Export
	
	Return PickName.Pick(
		SearchMode_,
		FullNameData,
		Gender,
		SelectionSize);
	
EndFunction

// See PickName.DetermineGender.
//
Function DetermineGender(Val FullNameData) Export
	
	Return PickName.DetermineGender(FullNameData);
	
EndFunction

// See PickName.FindName.
//
Function FindName(
		Val NameComponents,
		Val CompleteCoincidence = True) Export
	
	Return PickName.FindName(
		NameComponents,
		CompleteCoincidence);
	
EndFunction

#EndRegion
