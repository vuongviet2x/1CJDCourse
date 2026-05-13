///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The Online Support subsystem.
// CommonModule.LicensingClientClient.
//
// Client procedures and functions for setting up the licensing client.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ForCallsFromOtherSubsystems

// Attaches a request handler of licensing client parameters.
//
Procedure AttachLicensingClientSettingsRequest() Export
	
	// Attaching a query handler of licensing client parameters
	If Not CommonClient.DataSeparationEnabled() Then
		Try
			GlobalMethodName = "OnRequestLicensingClientSettings";
			AttachLicensingClientParametersRequestHandler(GlobalMethodName);
		Except
			EventLogClient.AddMessageForEventLog(
				NStr("ru = 'Интернет-поддержка пользователей';
					|en = 'Online support';", CommonClient.DefaultLanguageCode()),
				"Error",
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось подключить обработчик запроса настроек клиента лицензирования.
						|%1';
						|en = 'Cannot connect handler of request for licensing client settings.
						|%1';"),
					ErrorProcessing.DetailErrorDescription(ErrorInfo())));
		EndTry;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
