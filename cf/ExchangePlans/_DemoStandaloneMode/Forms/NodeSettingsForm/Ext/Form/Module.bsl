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
	
	DataExchangeServer.NodeSettingsFormOnCreateAtServer(ThisObject, "_DemoStandaloneMode");
	
	DataSynchronizationMode =
		?(UseFilterByCompanies, "SynchronizeDataForSelectedCompaniesOnly", "SynchronizeAllData");
	
	CompaniesToDisplay.Load(AllApplicationCompanies());
	
	For Each TableRow In Companies Do
		
		CompaniesToDisplay.FindRows(New Structure("Organization", TableRow.Organization))[0].Use = True;
		
	EndDo;
	
	Modified = False;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	DataSynchronizationModeOnChangeValue();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New NotifyDescription("SelectAndClose", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DataSynchronizationModeOnChange(Item)
	
	DataSynchronizationModeOnChangeValue();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	SelectAndClose();
	
EndProcedure

&AtClient
Procedure EnableAllCompanies(Command)
	
	EnableDisableAllItemsInTable(True, "CompaniesToDisplay");
	
EndProcedure

&AtClient
Procedure DisableAllCompanies(Command)
	
	EnableDisableAllItemsInTable(False, "CompaniesToDisplay");
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	
	WriteAndCloseOnServer();
	DataExchangeClient.NodeSettingsFormCloseFormCommand(ThisObject);
	
EndProcedure

&AtClient
Procedure DataSynchronizationModeOnChangeValue()
	
	Items.Companies.Enabled =
		(DataSynchronizationMode = "SynchronizeDataForSelectedCompaniesOnly");
	
EndProcedure

&AtClient
Procedure EnableDisableAllItemsInTable(Enable, TableName)
	
	For Each CollectionItem In ThisObject[TableName] Do
		
		CollectionItem.Use = Enable;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure WriteAndCloseOnServer()
	
	UseFilterByCompanies =
		(DataSynchronizationMode = "SynchronizeDataForSelectedCompaniesOnly");
	
	If UseFilterByCompanies Then
		
		Companies.Load(CompaniesToDisplay.Unload(New Structure("Use", True), "Organization"));
		
	Else
		
		Companies.Clear();
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function AllApplicationCompanies()
	
	SetPrivilegedMode(True);
	
	QueryText =
	"SELECT
	|	FALSE AS Use,
	|	Companies.Ref AS Organization
	|FROM
	|	Catalog._DemoCompanies AS Companies
	|WHERE
	|	NOT Companies.DeletionMark
	|
	|ORDER BY
	|	Companies.Description";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Return Query.Execute().Unload();
EndFunction

#EndRegion
