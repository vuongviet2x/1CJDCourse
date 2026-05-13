///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Verify that the form is opened with the required parameters
	If Not Parameters.Property("TemplateName") Then
		
		Raise NStr("ru = 'Эта форма не предназначена для непосредственного открытия.';
								|en = 'This is a dependent form and opens from a different form.';", Common.DefaultLanguageCode());
		
	EndIf;
	
	HTMLDocumentField = StandaloneModeInternal.InstructionTextFromTemplate(Parameters.TemplateName);
	
	Parameters.Property("Title", Title);
	
EndProcedure

#EndRegion
