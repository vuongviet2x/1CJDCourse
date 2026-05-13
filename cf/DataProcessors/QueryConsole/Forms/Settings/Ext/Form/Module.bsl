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
	
	TransferParameters = GetFromTempStorage(Parameters.StorageAddress);
	Object.UseAutosave                = TransferParameters.UseAutosave;
	Object.AutoSavePeriod                      = TransferParameters.AutoSavePeriod;
	Object.OutputRefValuesInQueryResults = TransferParameters.OutputRefValuesInQueryResults;
	Object.TabOrderType                                 = TransferParameters.TabOrderType;
	Object.AlternatingColorsByQuery       = TransferParameters.AlternatingColorsByQuery;
	
	Items.TabOrderType.ChoiceList.Add("Auto");
	Items.TabOrderType.ChoiceList.Add("Direct");
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Write(Command)
	TransferParameters = PutSettingsInStructure();
	
	// Pass parameters to opening form.
	Close();
	
	Notify("PassSettingsParameters" , TransferParameters);
	Notify("PassAutoSavingSettingsParameters");
EndProcedure

#EndRegion

#Region Private
&AtServer
Function DataProcessorObject2()
	Return FormAttributeToValue("Object");
EndFunction

&AtServer
Function PutSettingsInStructure()
	TransferParameters = New Structure;
	TransferParameters.Insert("StorageAddress", DataProcessorObject2().PutSettingsInTempStorage(Object));
	Return TransferParameters;
EndFunction	

#EndRegion
