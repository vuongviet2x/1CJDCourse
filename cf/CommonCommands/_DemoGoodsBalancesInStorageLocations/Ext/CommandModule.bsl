///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Filter = New Structure;
	Filter.Insert("Recorder", CommandParameter);
	
	FormParameters = New Structure("Filter", Filter);
	
	OpenForm("AccumulationRegister._DemoGoodsBalancesInStorageLocations.ListForm", FormParameters, 
		CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, 
			CommandExecuteParameters.Window, CommandExecuteParameters.URL);
			
EndProcedure

#EndRegion
