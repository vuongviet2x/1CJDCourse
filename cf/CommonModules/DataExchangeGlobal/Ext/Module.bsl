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

// Checks whether infobase configuration update in the subordinate node is required.
//
Procedure CheckSubordinateNodeConfigurationUpdateRequired() Export
	
	UpdateRequired = StandardSubsystemsClient.ClientRunParameters().DIBNodeConfigurationUpdateRequired;
	CheckUpdateRequired(UpdateRequired);
	
EndProcedure

// Checks whether infobase configuration update in the subordinate node is required. The check is performed on application startup.
//
Procedure CheckSubordinateNodeConfigurationUpdateRequiredOnStart() Export
	
	UpdateRequired = StandardSubsystemsClient.ClientParametersOnStart().DIBNodeConfigurationUpdateRequired;
	CheckUpdateRequired(UpdateRequired);
	
EndProcedure

Procedure CheckUpdateRequired(DIBNodeConfigurationUpdateRequired)
	
	If DIBNodeConfigurationUpdateRequired Then
		Explanation = NStr("ru = 'Получено обновление программы из ""%1"".
			|Установите обновление программы, после чего синхронизация данных будет продолжена.';
			|en = 'The application update is received from ""%1"".
			|Install the update to continue the synchronization.';");
		Explanation = StringFunctionsClientServer.SubstituteParametersToString(Explanation, StandardSubsystemsClient.ClientRunParameters().MasterNode);
		ShowUserNotification(NStr("ru = 'Установить обновление';
											|en = 'Install update';"), "e1cib/app/DataProcessor.DataExchangeExecution",
			Explanation, PictureLib.Warning32);
		Notify("DataExchangeCompleted");
	EndIf;
	
	AttachIdleHandler("CheckSubordinateNodeConfigurationUpdateRequired", 60 * 60, True); // Once an hour.
	
EndProcedure

#EndRegion
