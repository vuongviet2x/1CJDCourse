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
	
	SafeMode = False;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ImportDataProcessorFile();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not ValueIsFilled(NameOfDataProcessorFile) Or Not ValueIsFilled(DataProcessorFileAddress) Then
		Common.MessageToUser(NStr("ru = 'Укажите файл внешнего отчета или обработки.';
													|en = 'Specify an external report file or a data processor file.';"),, 
			"NameOfDataProcessorFile");
		Cancel = True;
	Else
		FileProperties = CommonClientServer.ParseFullFileName(NameOfDataProcessorFile);
		If Lower(FileProperties.Extension) <> Lower(".epf") And Lower(FileProperties.Extension) <> Lower(".erf") Then
			Common.MessageToUser(NStr("ru = 'Выбранный файл не является внешним отчетом или обработкой.';
														|en = 'The selected file is not an external report or data processor.';"),,
				"NameOfDataProcessorFile");
			Cancel = True;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(SafeMode) Then
		Common.MessageToUser(NStr("ru = 'Укажите безопасный режим для подключения внешнего модуля.';
													|en = 'Specify the safe mode for the external module connection.';"),, 
			"SafeMode");
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NameOfDataProcessorFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	ImportDataProcessorFile();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AttachAndOpen(Command)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;	
	
	FileProperties = CommonClientServer.ParseFullFileName(NameOfDataProcessorFile);
	IsExternalDataProcessor = (Lower(FileProperties.Extension) = Lower(".epf"));
	
	ExternalObjectName = AttachOnServer(IsExternalDataProcessor);
	If IsExternalDataProcessor Then
		ExternalFormName = "ExternalDataProcessor." + ExternalObjectName + ".Form";
	Else
		ExternalFormName = "ExternalReport." + ExternalObjectName + ".Form";
	EndIf;
	
	OpenForm(ExternalFormName, , FormOwner);
	Close();
		
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ImportDataProcessorFile()
	
	Notification = New NotifyDescription("ImportDataProcessorFileCompletion", ThisObject);
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	FileSystemClient.ImportFile_(Notification);

EndProcedure

&AtClient
Procedure ImportDataProcessorFileCompletion(FileThatWasPut, AdditionalParameters) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	NameOfDataProcessorFile = FileThatWasPut.Name;
	DataProcessorFileAddress = FileThatWasPut.Location;
	
	FileProperties = CommonClientServer.ParseFullFileName(NameOfDataProcessorFile);
	If Lower(FileProperties.Extension) <> Lower(".epf") And Lower(FileProperties.Extension) <> Lower(".erf") Then
		ShowMessageBox(, NStr("ru = 'Выбранный файл не является внешним отчетом или обработкой.';
										|en = 'The selected file is not an external report or data processor.';"));
	EndIf;
	
EndProcedure

&AtServer
Function AttachOnServer(IsExternalDataProcessor)
	
	VerifyAccessRights("Administration", Metadata);
	
	If IsExternalDataProcessor Then
		Manager = ExternalDataProcessors;
	Else
		Manager = ExternalReports;
	EndIf;
	
	Return Manager.Connect(DataProcessorFileAddress,, SafeMode); // ACC:552; ACC:553 Secure connection.
	
EndFunction

#EndRegion
