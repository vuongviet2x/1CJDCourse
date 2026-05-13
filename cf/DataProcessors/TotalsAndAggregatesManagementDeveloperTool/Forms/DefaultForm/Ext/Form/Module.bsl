///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormCommandsEventHandlers

&AtClient
Procedure TotalsAndAggregatesClearDates(Command)
	TotalsAndAggregatesClearDatesServer();
	If IsOpen() Then
		Close();
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure TotalsAndAggregatesClearDatesServer()
	TotalsParameters = New Structure;
	TotalsParameters.Insert("HasTotalsRegisters", True);
	TotalsParameters.Insert("TotalsCalculationDate",  AddMonth(CurrentSessionDate(), -12)); // Previous year.
	
	TotalsAndAggregatesManagementInternal.WriteTotalsAndAggregatesParameters(TotalsParameters);
EndProcedure

#EndRegion
