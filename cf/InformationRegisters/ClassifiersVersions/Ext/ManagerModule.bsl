///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2019, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// For internal use only.
Procedure ListFormOnCreateAtServer(Form) Export
	
	Form.ReadOnly = True;
	
EndProcedure

// For internal use only.
Procedure RecordFormOnCreateAtServer(Form) Export
	
	Form.ReadOnly = True;
	
EndProcedure

#EndRegion

#EndIf