///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2018, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Process incoming messages with the type {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d}PlanZoneBackup.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataAreaCode - Number - code of data area,
//  BackupID - UUID - backup ID,
//  BackupMoment - Date - date and time of backup,
//  Forcibly - Boolean - forced backup creation flag.
//  ForSupport - Boolean - indicates that a backup for technical support is created.
//
Procedure PlanToCreateBackupOfArea(Val DataAreaCode,
		Val BackupID, Val BackupMoment,
		Val Forcibly, Val ForSupport) Export
EndProcedure

// Process incoming messages with the type {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d}CancelZoneBackup.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataAreaCode - Number - code of data area,
//  BackupID - UUID - backup ID.
//
Procedure CancelBackupOfArea(Val DataAreaCode, Val BackupID) Export
EndProcedure

// Process incoming messages with the type
// {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d}UpdateScheduledZoneBackupSettings.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataArea - Number - value of the data area separator.
//  Settings - Structure - new backup settings.
//
Procedure UpdatePeriodicBackupSettings(Val DataArea, Val Settings) Export
EndProcedure

// Process incoming messages with the type {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d}CancelScheduledZoneBackup.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  DataArea - Number - value of the data area separator.
//
Procedure CancelPeriodicBackups(Val DataArea) Export
EndProcedure

#EndRegion
