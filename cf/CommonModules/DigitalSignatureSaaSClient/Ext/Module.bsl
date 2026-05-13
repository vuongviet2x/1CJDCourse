///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2019, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns:
// 	Boolean
//
Function UsageAllowed() Export
	
	Return StandardSubsystemsClient.ClientRunParameters()["UsingElectronicSignatureInServiceModelIsPossible"];
	
EndFunction

// Procedure - change settings of getting temporary passwords
//
// Parameters:
//  Certificate - Arbitrary - certificate
//  CallbackOnCompletion - NotifyDescription - a completion notification.
//  FormParameters - Structure - Optional. Contains additional parameters upon form opening.
//
Procedure ChangeSettingsForGettingTemporaryPasswords(Certificate, 
													CallbackOnCompletion = Undefined, 
													FormParameters = Undefined) Export
	If FormParameters = Undefined Then
		FormParameters = New Structure;
	EndIf;
	
	FormParameters.Insert("Certificate", Certificate);
	
	OpenForm(
		"CommonForm.TemporaryPasswordsDeliverySettings",
		FormParameters,,,,,
		CallbackOnCompletion);
	
EndProcedure

// Procedure - change the cryptooperation confirmation method.
//
// Parameters:
//  Certificate - Arbitrary - certificate
//  CallbackOnCompletion - NotifyDescription - a completion notification.
//  FormParameters - Structure - Optional. Contains additional parameters upon form opening.
//
Procedure ChangeWayCryptoOperationsAreConfirmed(Certificate, 
													CallbackOnCompletion = Undefined, 
													FormParameters = Undefined) Export
	
	If FormParameters = Undefined Then
		FormParameters = New Structure;
	EndIf;
	
	FormParameters.Insert("Certificate", Certificate);
	
	OpenForm(
		"CommonForm.CryptoOperationsConfirmationSetting",
		FormParameters,,,,,
		CallbackOnCompletion);
	
EndProcedure

// Procedure - disable confirmation of cryptooperations
//
// Parameters:
//  Certificate - Arbitrary - certificate
//  CallbackOnCompletion - NotifyDescription - a completion notification.
//  FormParameters - Structure - Optional. Contains additional parameters upon form opening.
//
Procedure DisableConfirmationOfCryptoOperations(Certificate, 
												CallbackOnCompletion = Undefined, 
												FormParameters = Undefined) Export
	
	If FormParameters = Undefined Then
		FormParameters = New Structure;
	EndIf;
	
	FormParameters.Insert("Certificate", Certificate);
	
	OpenForm(
		"CommonForm.DisableCryptoOperationsConfirmation",
		FormParameters,,,,,
		CallbackOnCompletion);
	
EndProcedure

#EndRegion