//@strict-types

#Region Internal

// Parameters: 
//  FileName - String
//  FileSize - Number
// 
// Returns: 
//  String - File presentation.
Function FilePresentation(FileName, FileSize) Export

	FSObject = New File(FileName);
	Return StrTemplate("%1 (%2)", FSObject.Name, FileSizePresentation(FileSize));

EndFunction

// Parameters: 
//  FileSize - Number
// 
// Returns: 
//  String - File size presentation.
Function FileSizePresentation(FileSize) Export
	
	If FileSize < 1024 Then
		Result = StrTemplate(NStr("ru = '%1 байт';
									|en = '%1 Bytes';"), FileSize);
	ElsIf FileSize < 1024 * 1024 Then
		Result = StrTemplate(NStr("ru = '%1 Кб';
									|en = '%1 KB';"), Format(FileSize / 1024, "NFD=0"));
	ElsIf FileSize < 1024 * 1024 * 1024 Then
		Result = StrTemplate(NStr("ru = '%1 Мб';
									|en = '%1 MB';"), Format(FileSize / 1024 / 1024, "NFD=0"));
	Else
		Result = StrTemplate(NStr("ru = '%1 Гб';
									|en = '%1 GB';"), Format(FileSize / 1024 / 1024 / 1024, "NFD=0"));
	EndIf;

	Return Result;

EndFunction

// Parameters: 
//  FileSize - Number 
// 
// Returns: 
//  Number - Data chunk size to process.
Function ProcessingPortionSize(FileSize) Export
	
	If FileSize > 100 * 1024 * 1024 Then
		Result = 10 * 1024 * 1024;
	ElsIf FileSize > 10 * 1024 * 1024 Then
		Result = 1024 * 1024;
	Else
		Result = Round(FileSize / 10);
	EndIf;
	
	Return Max(Result, 1);
	
EndFunction

// Temp storage max size.
// 
// Returns: 
//  Number - Temp storage max size.
Function MaximumSizeOfTemporaryStorage() Export

	Return 4 * 1024 * 1024 * 1024;

EndFunction

// - Max temp storage size.
// 
// Returns: 
//  Number - Acceptable temp storage size.
Function AcceptableSizeOfTemporaryStorage() Export

	Return 100 * 1024 * 1024;

EndFunction

#EndRegion