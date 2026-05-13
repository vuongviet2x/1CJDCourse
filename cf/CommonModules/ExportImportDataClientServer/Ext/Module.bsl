////////////////////////////////////////////////////////////////////////////////
// "Data import export" subsystem.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Export file name.
// 
// Returns: 
//  String - Export file name.
Function NameOfDataUploadFile() Export

	Return "data_dump.zip"

EndFunction

Function LongTermOperationHint() Export
	Return NStr("ru = 'Операция может занять длительное время. Пожалуйста, подождите...';
				|en = 'The operation might take a long time. Please wait...';");
EndFunction

Function ExportImportDataAreaPreparationStateView(importDataArea) Export
	If importDataArea Then
		StatusPresentation = NStr("ru = 'Выполняется подготовка к загрузке данных.';
										|en = 'Preparing to import data.';");
	Else
		StatusPresentation = NStr("ru = 'Выполняется подготовка к выгрузке данных.';
										|en = 'Preparing to export data.';");
	EndIf;
	Return StatusPresentation;
EndFunction

#EndRegion