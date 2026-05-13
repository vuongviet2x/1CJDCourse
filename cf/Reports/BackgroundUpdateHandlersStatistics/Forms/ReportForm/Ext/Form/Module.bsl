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
Procedure ImportData(Command)
	
	StartLogImportToServer(False);
	
EndProcedure

&AtClient
Procedure GenerateReport(Command)
	
	If Not IsTempStorageURL(Report.DataAddress) Then
		StartLogImportToServer(True);
		Return;
	EndIf;
	
	GenerateReportOnServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateReportOnServer()
	
	Result.Clear();
	
	DetailInformation = Undefined;
	FormAttributeToValue("Report").ComposeResult(Result, DetailInformation);
	DetailsData = PutToTempStorage(DetailInformation, UUID);
	Items.Result.StatePresentation.Visible = False;
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
	
EndProcedure

&AtClient
Procedure StartLogImportToServer(Val GenerateAfterImport)
	
	NotifyDescription = New NotifyDescription("ProcessPutFileResult", 
		ThisObject, GenerateAfterImport);
	FileSystemClient.ImportFile_(NotifyDescription);
	
EndProcedure

&AtClient
Procedure ProcessPutFileResult(FileThatWasPut, AdditionalParameters) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	Report.DataAddress = FileThatWasPut.Location;
	If AdditionalParameters Then
		GenerateReportOnServer();
	EndIf;
	
EndProcedure

#EndRegion