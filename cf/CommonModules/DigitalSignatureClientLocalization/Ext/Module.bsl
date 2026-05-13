///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Procedure OnDefineTechnicalSupportRequestRecipient(Recipient) Export
	
	
EndProcedure

Procedure OnGetFilterForSelectingSignatures(Filter) Export
	
	
EndProcedure

Procedure OnGetChoiceListWithMRLOAs(Form, CurrentData, ChoiceList) Export
	
	
EndProcedure

Procedure OnSelectMRLOA(CompletionHandler, CurrentData) Export
	
	
EndProcedure

Procedure OnDefineMRLOAFiles(MRLOAFiles,
		SignaturesCollection) Export
		
	
EndProcedure

Async Function InstalledTokens(ComponentObject = Undefined, SuggestInstall = False) Export

	Result = New Structure;
	Result.Insert("CheckCompleted", False);
	Result.Insert("Tokens", New Array);
	Result.Insert("Error", "");
	
	
	Return Result; 
	
EndFunction

Async Function TokenCertificates(Token, ComponentObject = Undefined, SuggestInstall = False) Export
	
	Result = New Structure;
	Result.Insert("CheckCompleted", False);
	Result.Insert("Certificates", New Array);
	Result.Insert("Error", "");
	
	
	Return Result;
	
EndFunction

Function IsIncorrectPinCodeError(ErrorText) Export
	Return False;
EndFunction 


#EndRegion
