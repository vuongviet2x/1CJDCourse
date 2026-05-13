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

//////////////////////////////////////////////////////////////////////////////
// "_Demo" document subscription event handlers.

Procedure _DemoFillInTheDateOfTheDocumentByTheWorkingDateProcessingOfTheFilling(Source, FillingData, FillingText, StandardProcessing) Export
	
	Source.Date = Common.CurrentUserDate();

EndProcedure

Procedure _DemoFillDocumentDateByWorkingDateOnCopy(Source, CopiedObject) Export
	
	Source.Date = Common.CurrentUserDate();

EndProcedure

Procedure _DemoUpdateInventoryDocumentRegistryWhenRecording(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	InformationRegisters._DemoWarehouseDocumentsRegister.UpdateWarehouseDocumentsRegistry(Source);
	
EndProcedure

#EndRegion
