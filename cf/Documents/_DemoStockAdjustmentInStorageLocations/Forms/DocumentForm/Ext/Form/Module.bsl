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
Procedure OnReadAtServer(CurrentObject)
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
EndProcedure

#EndRegion
#Region FormTableItemsEventHandlersRegisterRecords

&AtClient
Procedure RegisterRecords_DemoAvailableStockInStorageLocationsOnStartEdit(Item, NewRow, Copy)
	If NewRow Then
		DataString = Items.RegisterRecords_DemoAvailableStockInStorageLocations.CurrentData;
		DataString.Period = Object.Date;
		DataString.RecordType = AccumulationRecordType.Receipt;
	EndIf;
EndProcedure


#EndRegion