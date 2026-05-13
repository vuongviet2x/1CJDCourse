///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	For Each Record In ThisObject Do
		
		If Record.DebugMode Then
			
			ExchangePlanID = Common.MetadataObjectID(Metadata.ExchangePlans[Record.ExchangePlanName]);
			ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
			SecurityProfileName = ModuleSafeModeManagerInternal.ExternalModuleAttachmentMode(ExchangePlanID);
			
			If SecurityProfileName <> Undefined Then
				SetSafeMode(SecurityProfileName);
			EndIf;
			
			IsFileInfobase = Common.FileInfobase();
			
			If Record.ExportDebugMode Then
				
				CheckExternalDataProcessorFileExistence(Record.ExportDebuggingDataProcessorFileName, IsFileInfobase, Cancel);
				
			EndIf;
			
			If Record.ImportDebugMode Then
				
				CheckExternalDataProcessorFileExistence(Record.ImportDebuggingDataProcessorFileName, IsFileInfobase, Cancel);
				
			EndIf;
			
			If Record.DataExchangeLoggingMode Then
				
				CheckExchangeProtocolFileAvailability(Record.ExchangeProtocolFileName, Cancel);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckExternalDataProcessorFileExistence(FileToCheckName, IsFileInfobase, Cancel)
	
	FileNameStructure = CommonClientServer.ParseFullFileName(FileToCheckName);
	CheckDirectoryName	 = FileNameStructure.Path;
	CheckDirectory = New File(CheckDirectoryName);
	FileOnHardDrive = New File(FileToCheckName);
	DirectoryLocation = ? (IsFileInfobase, NStr("ru = 'на клиенте';
													|en = 'on client';"), NStr("ru = 'на сервере';
																				|en = 'on the server';"));
	
	If Not CheckDirectory.Exists() Then
		
		MessageString = NStr("ru = 'Каталог ""%1"" не найден %2.';
								|en = 'Directory %1 not found %2.';");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, CheckDirectoryName, DirectoryLocation);
		Cancel = True;
		
	ElsIf Not FileOnHardDrive.Exists() Then 
		
		MessageString = NStr("ru = 'Файл внешней обработки ""%1"" не найден %2.';
								|en = 'File of external data processor %1 not found %2.';");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, FileToCheckName, DirectoryLocation);
		Cancel = True;
		
	Else
		
		Return;
		
	EndIf;
	
	Common.MessageToUser(MessageString,,,, Cancel);
	
EndProcedure

Procedure CheckExchangeProtocolFileAvailability(ExchangeProtocolFileName, Cancel)
	
	FileNameStructure = CommonClientServer.ParseFullFileName(ExchangeProtocolFileName);
	CheckDirectoryName = FileNameStructure.Path;
	CheckDirectory = New File(CheckDirectoryName);
	CheckFileName = "test.tmp";
	
	If Not CheckDirectory.Exists() Then
		
		MessageString = NStr("ru = 'Папка файла протокола обмена ""%1"" не найдена.';
								|en = 'Exchange protocol file folder ""%1"" is not found.';");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, CheckDirectoryName);
		Cancel = True;
		
	ElsIf Not CreateCheckFile(CheckDirectoryName, CheckFileName) Then
		
		MessageString = NStr("ru = 'Не удалось создать файл в папке протокола обмена: ""%1"".';
								|en = 'Cannot create a file in the exchange protocol folder: ""%1"".';");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, CheckDirectoryName);
		Cancel = True;
		
	ElsIf Not DeleteCheckFile(CheckDirectoryName, CheckFileName) Then
		
		MessageString = NStr("ru = 'Не удалось удалить файл в папке протокола обмена: ""%1"".';
								|en = 'Cannot delete a file from the exchange protocol folder: ""%1"".';");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, CheckDirectoryName);
		Cancel = True;
		
	Else
		
		Return;
		
	EndIf;
	
	Common.MessageToUser(MessageString,,,, Cancel);
	
EndProcedure

Function CreateCheckFile(CheckDirectoryName, CheckFileName)
	
	TextDocument = New TextDocument;
	TextDocument.AddLine(NStr("ru = 'Временный файл проверки';
											|en = 'Temporary file for checking';"));
	
	Try
		TextDocument.Write(CheckDirectoryName + "/" + CheckFileName);
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Function DeleteCheckFile(CheckDirectoryName, CheckFileName)
	
	Try
		DeleteFiles(CheckDirectoryName, CheckFileName);
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf