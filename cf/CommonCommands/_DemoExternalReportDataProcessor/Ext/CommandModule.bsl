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
	
	// Allows to open external reports and data processors under any user
	// in the unsafe mode (for testing purposes).
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Dialog.Title = NStr("ru = 'Выберите файл внешнего отчета или обработки';
												|en = 'Select a file with external report or data processor';");
	ImportParameters.Dialog.Filter = NStr("ru = 'Внешний отчет, обработка (*.erf, *.epf)|*.erf;*.epf|Внешний отчет (*.erf)|*.erf|Внешняя обработка (*.epf)|*.epf';
											|en = 'External report, data processor (*.erf, *.epf)|*.erf;*.epf|External report (*.erf)|*.erf|External data processor (*.epf)|*.epf';");
	FileSystemClient.ImportFile_(New NotifyDescription("ProcessCommandAfterPutFile", ThisObject), ImportParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ProcessCommandAfterPutFile(FileThatWasPut, AdditionalParameters) Export
	
	If Not ValueIsFilled(FileThatWasPut) Then
		Return;
	EndIf;
	
	FileProperties = CommonClientServer.ParseFullFileName(FileThatWasPut.Name);
	
	If StrEndsWith(Lower(FileProperties.Name), Lower(".epf"))
	 Or StrEndsWith(Lower(FileProperties.Name), Lower(".epf.dat")) Then
		
		IsExternalDataProcessor = True;
		
	ElsIf StrEndsWith(Lower(FileProperties.Name), Lower(".erf"))
	      Or StrEndsWith(Lower(FileProperties.Name), Lower(".erf.dat")) Then
		
		IsExternalDataProcessor = False;
	Else
		ShowMessageBox(, NStr("ru = 'Выбранный файл не является внешним отчетом или обработкой.';
										|en = 'The selected file is not an external report or data processor.';"));
		Return;
	EndIf;
	
	ExternalObjectName = NewExternalReportOrDataProcessor(FileThatWasPut.Location, IsExternalDataProcessor, FileProperties.Name);
	
	If IsExternalDataProcessor Then
		FormName = "ExternalDataProcessor." + ExternalObjectName + ".Form";
	Else
		FormName = "ExternalReport." + ExternalObjectName + ".Form";
	EndIf;
	
	OpenForm(FormName);
	
EndProcedure

&AtServer
Function NewExternalReportOrDataProcessor(Address, IsExternalDataProcessor, FileName)
	
	If IsExternalDataProcessor Then
		Manager = ExternalDataProcessors;
	Else
		Manager = ExternalReports;
	EndIf;
	
	// ACC:552-off, ACC:553-off - No.669.1. It is acceptable to attach
	// external reports and data processors for testing purposes.
	ExternalObjectName = Manager.Connect(Address, , False);
	Manager.Create(ExternalObjectName);
	// ACC:553-on, ACC:552-on
	
	Return ExternalObjectName;
	
EndFunction

#EndRegion
