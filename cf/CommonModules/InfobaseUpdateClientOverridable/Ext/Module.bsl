///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// Is called by following a link or double-clicking a cell 
// of a spreadsheet document that contains application release notes (common template AppReleaseNotes).
//
// Parameters:
//   Area - SpreadsheetDocumentRange - a document area 
//             that was clicked.
//
Procedure OnClickUpdateDetailsDocumentHyperlink(Val Area) Export
	
	// _Demo Example Start
	If Area.Name = "_DemoHyperlinkExample" Then
		ShowMessageBox(,NStr("ru = 'Нажата гиперссылка.';
									|en = 'Hyperlink clicked.';"));
	EndIf;
	
	// _Demo Example End

EndProcedure

// Is called in the BeforeStart handler. Checks for
// an update to a current version of a program.
//
// Parameters:
//  DataVersion - String - data version of a main configuration that is to be updated
//                          (from the SubsystemsVersions information register).
//
Procedure OnDetermineUpdateAvailability(Val DataVersion) Export
	
	// _Demo Example Start
	AvailableVersion = "2.1.0";
	
	DataVersionWithoutBuildNumber = CommonClientServer.ConfigurationVersionWithoutBuildNumber(DataVersion);
	Result = CommonClientServer.CompareVersionsWithoutBuildNumber(DataVersionWithoutBuildNumber, AvailableVersion);
	If DataVersion <> "0.0.0.0" And Result < 0 Then
		Message = NStr("ru = 'Обновление на текущую версию допустимо только с версии %1 и выше.
			|(Недопустимая попытка обновления с версии %2)
			|Восстановите информационную базу из резервной копии
			|и повторить обновление согласно файлу 1cv8upd.htm';
			|en = 'Only version %1 or later can be updated to the current version.
			|(Update from version %2 was attempted.)
			|Restore the infobase from the backup
			|and try updating again as described in file 1cv8upd.htm';");
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message, AvailableVersion, DataVersion);
		Raise Message;
	EndIf;
	// _Demo Example End
	
EndProcedure

#EndRegion
