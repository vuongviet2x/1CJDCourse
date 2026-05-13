///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2018, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Process incoming messages whose type is {http://www.1c.ru/1cFresh/ManageSynopticExchange/a.b.c.d}SetSynopticExchange.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataAreaCode - Number - code of data area,
//  Parameters - Structure - backup ID,
//
Procedure ConfigureUploadingToSummaryApp_(DataAreaCode, Parameters) Export 
EndProcedure

// Process incoming messages whose type is {http://www.1c.ru/1cFresh/ManageSynopticExchange/a.b.c.d}SetCorrSynopticExchange.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataAreaCode - Number - code of data area,
//  Parameters - Structure - backup ID,
//
Procedure ConfigureUploadingToSummaryApp(DataAreaCode, Parameters) Export 
EndProcedure

// Process incoming messages whose type is {http://www.1c.ru/1cFresh/ManageSynopticExchange/a.b.c.d}PushSynopticExchangeStep1.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataAreaCode - Number - code of data area,
//  Parameters - Structure - backup ID,
//
Procedure InteractiveLaunchOfUploadingToSummaryApplication(DataAreaCode, Parameters) Export 
EndProcedure

// Process incoming messages whose type is {http://www.1c.ru/1cFresh/ManageSynopticExchange/a.b.c.d}PushSynopticExchangeStep2.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataAreaCode - Number - code of data area,
//  Parameters - Structure - backup ID,
//
Procedure InteractiveLaunchOfDownloadToSummaryApplication(DataAreaCode, Parameters) Export 
EndProcedure

#EndRegion
