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

#Region Internal

// Handler that handles background export of data to an app.
//
Procedure TransferUserInfo(Val Parameters, Val StorageAddress) Export
	
	UniversalDataExport = DataProcessors.UniversalDataExchangeXML.Create();
	
	MessageText = "";
	
	ImportExchangeRules(UniversalDataExport, MessageText);
	
	If IsBlankString(MessageText) Then
		ExecuteTransfer(UniversalDataExport, Parameters, MessageText);
	EndIf;
	
	PutToTempStorage(MessageText, StorageAddress);
EndProcedure

#EndRegion

#Region Private

Procedure ImportExchangeRules(Val DataExportProcessing, MessageText)
	
	DataExportProcessing.ExchangeRulesFileName = GetTempFileName("xml");
	
	ExchangeRuleTemplate = GetTemplate("DataTransferRules");
	ExchangeRuleTemplate.Write(DataExportProcessing.ExchangeRulesFileName);
	
	DataExportProcessing.ImportExchangeRules();
	
	DeleteFiles(DataExportProcessing.ExchangeRulesFileName);
	
	If DataExportProcessing.FlagErrors Then
		MessageText = NStr("ru = 'Ошибка при загрузке правил переноса данных.';
								|en = 'An error occurred when importing data transfer rules.';");
	EndIf;
	
EndProcedure

Procedure ExecuteTransfer(Val DataExportProcessing, Val Parameters, MessageText)
	
	// Migration parameters.
	DataExportProcessing.ExportAllowedObjectsOnly                      = True;
	DataExportProcessing.FlagDebugMode                                = False;
	DataExportProcessing.ExecuteDataExchangeInOptimizedFormat   = True;
	DataExportProcessing.DirectReadingInDestinationIB              = True;
	DataExportProcessing.InfobaseToConnectPlatformVersion = "V83";
	DataExportProcessing.DontOutputInfoMessagesToUser = True;
	
	// Connection parameters.
	ConnectionParameters = Parameters.ConnectionParameters;
	
	DataExportProcessing.InfobaseToConnectType                   = ConnectionParameters.InfobaseOperatingMode = 0;
	DataExportProcessing.InfobaseToConnectWindowsAuthentication = ConnectionParameters.OperatingSystemAuthentication;
	
	DataExportProcessing.InfobaseToConnectDirectory      = ConnectionParameters.InfobaseDirectory;
	DataExportProcessing.InfobaseToConnectServerName   = ConnectionParameters.NameOf1CEnterpriseServer;
	DataExportProcessing.InfobaseToConnectNameOnServer = ConnectionParameters.NameOfInfobaseOn1CEnterpriseServer;
	
	DataExportProcessing.InfobaseToConnectUser = ConnectionParameters.UserName;
	DataExportProcessing.InfobaseToConnectPassword       = ConnectionParameters.UserPassword;
	
	DataExportProcessing.ExecuteExport();
	
	If DataExportProcessing.FlagErrors Then
		MessageText = NStr("ru = 'При переносе сведений о пользователях произошли ошибки.';
								|en = 'Errors occurred when transferring user information records.';");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
