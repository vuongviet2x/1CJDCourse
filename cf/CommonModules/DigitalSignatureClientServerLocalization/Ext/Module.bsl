///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Private

Procedure OnGetCertificatePresentation(Val Certificate, Val UTCOffset, Presentation) Export
	
	
EndProcedure

Procedure OnGetSubjectPresentation(Val Certificate, Presentation) Export
	
	
EndProcedure

Procedure OnGetExtendedCertificateSubjectProperties(Val Subject, Properties) Export
	
	
EndProcedure

Procedure OnGetExtendedCertificateIssuerProperties(Val Issuer, Properties) Export
	
	
EndProcedure

Procedure WhenComparingCertificates(PropertiesOfNew, PropertiesOfOld, Result) Export
	
	
EndProcedure

Procedure OnReceivingXMLEnvelope(Parameters, XMLEnvelope) Export
	
	
EndProcedure

Procedure OnGetDefaultEnvelopeVariant(XMLEnvelope) Export

	
EndProcedure

// Address of the revocation list located on a different resource.
// 
// Parameters:
//  CertificateAuthorityName - String - Issuer's name (lower case, Latin letters)
//  Certificate  - BinaryData
//              - String
// 
// Returns:
//  Structure:
//   * InternalAddress - String - ID for searching within the infobase
//   * ExternalAddress - String - Resource address (for downloading)
//
Function RevocationListInternalAddress(CertificateAuthorityName, Certificate, CataloguesOfReviewListsOfUTS) Export
	
	Result = New Structure("ExternalAddress, InternalAddress");
	
	CertificateAuthorityName = StrReplace(CertificateAuthorityName, " ", "_");
	CertificateAuthorityName = TrimAll(StrConcat(StrSplit(CertificateAuthorityName, "!*'();«»:@&=+$,/?%#[]\|<>", True), ""));
	
	CertificateAuthorityName = CommonClientServer.ReplaceProhibitedCharsInFileName(CertificateAuthorityName, "");
	
	If Not ValueIsFilled(CertificateAuthorityName) Then
		Return Result;
	EndIf;
	
	CertificateAdditionalProperties = 
		DigitalSignatureInternalClientServer.CertificateAdditionalProperties(Certificate, 0);
	
	If Not ValueIsFilled(CertificateAdditionalProperties.CertificateAuthorityKeyID) Then
		Return Result;
	EndIf;
	
	Result.InternalAddress = StrTemplate("%1/%2", CertificateAuthorityName, Lower(CertificateAdditionalProperties.CertificateAuthorityKeyID));
	
	
	Return Result;
	
EndFunction

Function CataloguesOfReviewListsOfUTS(AccreditedCertificationCenters) Export
	
	Return "";
	
EndFunction

// Returns:
//  Undefined, Structure - Certificate authority data:
//   * IsState - Boolean
//   * AllowedUncredited - Boolean
//   * ActionPeriods - Undefined, Array of Structure
//     **DateFrom - Date
//     **DateBy - Date, Undefined
//   * ValidityEndDate - Undefined, Date
//   * UpdateDate  - Undefined, Date
//   * FurtherSettings - Map
//
Function CertificationAuthorityData(SearchValues, AccreditedCertificationCenters) Export
	
	Result = Undefined;
	
	
	Return Result;
	
EndFunction

Procedure OnDefineRefToAppsGuide(Section, URL) Export
	
	
EndProcedure

Procedure OnDefiningRefToAppsTroubleshootingGuide(URL, SectionName = "") Export
	
	
EndProcedure

Procedure OnDefineRefToSearchByErrorsWhenManagingDigitalSignature(URL, SearchString = "") Export
	
	
EndProcedure

// Convert the name of the passed algorithm (depending on the passed presentation).
// 
// Parameters:
//  EncryptAlgorithm  - String
// 
// Returns:
//  String
//
Function ConvertedEncryptionAlgorithm(EncryptAlgorithm) Export
	
	Result = "";
	
	
	If IsBlankString(Result) Then
		Result = EncryptAlgorithm;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure WhenSettingCryptographyManagerParameters(ApplicationDetails, Manager, EncryptAlgorithm, Result) Export
	
	
EndProcedure

Procedure WhenInstallingSetsOfAlgorithmsForSignatureCreation(Sets) Export
	
	
EndProcedure

Procedure WhenInstallingSetsOfEncryptionAlgorithms(Sets) Export
	
	
EndProcedure

Function AppsRelevantAlgorithms() Export
	
	Result = New Array;
	
	
	Return Result;
	
EndFunction



#EndRegion