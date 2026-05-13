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

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.DataExchange

// Populates the settings that affect the exchange plan usage.
// 
// Parameters:
//  Settings - See DataExchangeServer.DefaultExchangePlanSettings
//
Procedure OnGetSettings(Settings) Export
	
	SetPrivilegedMode(True);
	
	Settings.ExchangePlanPurpose = "DIBWithFilter";
	
	// Use the filter by company to determine the exchange plan's allocation
	// in order to autotest DIB updates in different modes.
	If Common.DebugMode() Then
		Query = New Query;
		Query.Text = 
		"SELECT TOP 1
		|	CompaniesFromNode.Organization AS Organization
		|FROM
		|	ExchangePlan._DemoDistributedInfobaseExchange.Companies AS CompaniesFromNode
		|WHERE
		|	NOT CompaniesFromNode.Ref.ThisNode
		|	AND NOT CompaniesFromNode.Ref.DeletionMark";
		If Query.Execute().IsEmpty() Then
			Settings.ExchangePlanPurpose = "DIB";
		EndIf;
	EndIf;
	
	Settings.Algorithms.OnGetSettingOptionDetails = True;	
	Settings.Algorithms.OnSaveDataSynchronizationSettings = True;

EndProcedure

// Populates a set of parameters that define the exchange setting option.
// 
// Parameters:
//  OptionDetails       - See DataExchangeServer.DefaultExchangeSettingOptionDetails
//  SettingID - String - Data exchange setup option ID.
//  ContextParameters     - See DataExchangeServer.ContextParametersOfSettingOptionDetailsReceipt
//
Procedure OnGetSettingOptionDetails(OptionDetails, SettingID, ContextParameters) Export
	
	BriefExchangeInfo = NStr("ru = 'Распределенная информационная база представляет собой иерархическую структуру, 
	|состоящую из отдельных информационных баз системы 1С:Предприятие - узлов распределенной информационной базы, между 
	|которыми организована синхронизация конфигурации и данных. Главной особенностью распределенных информационных баз 
	|является передача изменений конфигурации в подчиненные узлы. 
	|Имеется возможность настраивать ограничения миграции данных, например по организациям.';
	|en = 'Distributed infobase is a hierarchical structure 
	|containing separate infobases of 1C:Enterprise system that are the distributed infobase nodes.
	| Synchronization of data and configuration is arranged between the nodes. Distributed infobases 
	| transfer configuration changes to subordinate nodes. 
	|Data migration can be restricted, for example, by companies.';");
	BriefExchangeInfo = StrReplace(BriefExchangeInfo, Chars.LF, "");
	
	DetailedExchangeInformation = "https://its.1c.eu/bmk/bsp/sync_ib";
	
	OptionDetails.BriefExchangeInfo   = BriefExchangeInfo;
	OptionDetails.DetailedExchangeInformation = DetailedExchangeInformation;
	OptionDetails.NewDataExchangeCreationCommandTitle = NStr("ru = 'Распределенная информационная база';
																			|en = 'Distributed infobase';");
	OptionDetails.DataSyncSettingsWizardFormName =
		"ExchangePlan._DemoDistributedInfobaseExchange.Form.DataSynchronizationSettingsWizard";
	OptionDetails.CommonNodeData = "DocumentsExportStartDate, UseFilterByCompanies, Companies";
	OptionDetails.InitialImageCreationFormName = "CommonForm.CreateInitialImageWithFiles";
	
EndProcedure

// Populates an exchange node with import and export settings (data transfer restrictions and default values).
//
// Parameters:
//  Peer - ExchangePlanObject - The exchange plan node that contains the peer infobase.
//  FillingData - Structure - Structure of import and export settings.
//
Procedure OnSaveDataSynchronizationSettings(Peer, FillingData) Export
	
	FillPropertyValues(Peer, FillingData, 
		"DocumentsExportStartDate,
		|UseFilterByCompanies,
		|UseFilterByWarehouses,
		|UseFilterByDepartments");
	
	Peer.Companies.Load(FillingData.Companies);
	Peer.Warehouses.Load(FillingData.Warehouses);
	Peer.Departments.Load(FillingData.Departments);
	
EndProcedure

// End StandardSubsystems.DataExchange

// StandardSubsystems.BatchEditObjects

// Returns the object attributes that are not recommended to be edited
// using a bulk attribute modification data processor.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("RegisterChanges");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

#EndRegion

#EndRegion

#EndIf
