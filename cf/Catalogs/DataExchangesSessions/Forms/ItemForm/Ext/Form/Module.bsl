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
Procedure PerformanceMeasurements(Command)
	
	FileAddress = GetFileAddressOnServer();
	Title = NStr("ru = 'Сохранение файла';
					|en = 'Save file';");
		
	FileName = NStr("ru = 'Замеры производительности.zip';
					|en = 'Samples.zip';", CommonClient.DefaultLanguageCode());
		
	DialogParameters = New GetFilesDialogParameters(Title, True);
	BeginGetFileFromServer(FileAddress, FileName, DialogParameters);

EndProcedure

&AtServer
Function GetFileAddressOnServer()
	
	BinaryData = FormAttributeToValue("Object").PerformanceMeasurements.Get();	
	Address = PutToTempStorage(BinaryData);
	
	Return Address;
	
EndFunction

#EndRegion
