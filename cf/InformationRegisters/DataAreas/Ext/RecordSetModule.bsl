#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

// @skip-check data-exchange-load
Procedure OnWrite(Cancel, Replacing)
	
	// Do not run "DataExchange.Load" to prevent adding invalid records.
	// The check must be run in "OnWrite" as it has "DataAreaAuxiliaryData" filled.
	For Each Record In ThisObject Do
		//@skip-warning
		If Record.DataAreaAuxiliaryData = 0 Then
			Raise NStr("ru = 'Запрещено использовать область со значением разделителя 0';
									|en = 'Cannot use an area with a separator value of 0';");
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
