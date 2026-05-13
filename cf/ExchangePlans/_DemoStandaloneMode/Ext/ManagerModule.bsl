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
	
	Settings.ExchangePlanUsedInSaaS = True;
	
	Settings.ExchangePlanPurpose = "DIBWithFilter";
	
	Settings.Algorithms.OnGetSettingOptionDetails = True;
	Settings.Algorithms.DataTransferRestrictionsDetails     = True;
	
EndProcedure

// Populates a set of parameters that define the exchange setting option.
// 
// Parameters:
//  OptionDetails       - See DataExchangeServer.DefaultExchangeSettingOptionDetails
//  SettingID - String - Data exchange setup option ID.
//  ContextParameters     - See DataExchangeServer.ContextParametersOfSettingOptionDetailsReceipt
//
Procedure OnGetSettingOptionDetails(OptionDetails, SettingID, ContextParameters) Export
	
	OptionDetails.UseDataExchangeCreationWizard = False;
	
	OptionDetails.BriefExchangeInfo = NStr("ru = 'Предназначен для обеспечения работы с приложением в автономном режиме.';
														|en = 'It is designed to provide application work in standalone mode.';");
	
	OptionDetails.CorrespondentConfigurationDescription = NStr("ru = '1С:Библиотека стандартных подсистем';
																	|en = '1C:Standard Subsystems Library';");
	
	OptionDetails.NewDataExchangeCreationCommandTitle = NStr("ru = 'Демо: Автономная работа';
																			|en = 'Demo: Standalone mode';");
	
	UsedExchangeMessagesTransports = New Array;
	UsedExchangeMessagesTransports.Add(Enums.ExchangeMessagesTransportTypes.WS);
	OptionDetails.UsedExchangeMessagesTransports = UsedExchangeMessagesTransports;
	
	// Filters
	CompanyTabularSectionStructure = New Structure;
	CompanyTabularSectionStructure.Insert("Organization", New Array);
	
	OptionDetails.Filters.Insert("UseFilterByCompanies", False);
	OptionDetails.Filters.Insert("Companies", CompanyTabularSectionStructure);
	
EndProcedure

// Returns a string with data migration restriction details for a user.
// Based on the filter set on the node, a developer should create 
// a human-readable string containing the restriction description.
// 
// Parameters:
//  NodeFiltersSetting - Structure - Filter structure for the exchange plan node.
//  CorrespondentVersion   - String    - Peer infobase version.
//  SettingID - String    - Data exchange setup option ID.
//
// Returns:
//  String - details of data migration restrictions for user.
//
Function DataTransferRestrictionsDetails(NodeFiltersSetting, CorrespondentVersion, SettingID) Export
	
	LongDesc = ?(NodeFiltersSetting.UseFilterByCompanies,
		NStr("ru = 'В автономном рабочем месте доступна только часть данных.';
			|en = 'Only a part of data is available in standalone workstation.';"),
		NStr("ru = 'В автономном рабочем месте доступны все данные.';
			|en = 'All data is available in standalone workstation.';"));
	
	Return LongDesc;
	
EndFunction

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