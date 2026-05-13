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
	
	Cancel = False;
	
	TempStorageAddress = "";
	
	GetSecondInfobaseDataExchangeSettingsAtServer(Cancel, TempStorageAddress, CommandParameter);
	
	If Cancel Then
		
		ShowMessageBox(, NStr("ru = 'Возникли ошибки при получении настроек обмена данными.';
										|en = 'Cannot get data exchange settings.';"));
		
	Else
		
		SavingParameters = FileSystemClient.FileSavingParameters();
		SavingParameters.Dialog.Filter = "Files XML (*.xml)|*.xml";

		FileSystemClient.SaveFile(
			Undefined,
			TempStorageAddress,
			NStr("ru = 'Настройки синхронизации данных.xml';
				|en = 'Synchronization settings.xml';"),
			SavingParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GetSecondInfobaseDataExchangeSettingsAtServer(Cancel, TempStorageAddress, InfobaseNode)
	
	DataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard().Create();
	DataExchangeCreationWizard.Initialize(InfobaseNode);
	DataExchangeCreationWizard.ExportWizardParametersToTempStorage(Cancel, TempStorageAddress);
	
EndProcedure

#EndRegion
