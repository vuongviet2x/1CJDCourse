#Region Internal

// Returns: 
//  String - Warning text on active extensions that modify data structure.
Function WarningTextAboutActiveExtensionsThatChangeDataStructure() Export
	
	SetPrivilegedMode(True);
	
	ActiveExtensionsThatChangeDataStructure = CommonCTL.ActiveExtensionsThatChangeDataStructure();

	If Not ValueIsFilled(ActiveExtensionsThatChangeDataStructure) Then
		Return "";
	EndIf;

	PartsOfWarningText = New Array;
	PartsOfWarningText.Add(
		NStr("ru = 'В приложении установлены и активны расширения конфигурации, изменяющие структуру данных:';
			|en = 'Configuration extensions that change the data structure are installed and active in the application:';"));

	PartsOfWarningText.Add(Chars.LF);
	PartsOfWarningText.Add(Chars.LF);
	
	For Each Extension In ActiveExtensionsThatChangeDataStructure Do
		PartsOfWarningText.Add("● ");
		PartsOfWarningText.Add(Extension.Synonym);
		PartsOfWarningText.Add(Chars.LF);
	EndDo;
	
	Return StrConcat(PartsOfWarningText);		
		
EndFunction

// Import is aborted.
// 
// Returns:
//  Boolean
Function DownloadAborted() Export
	If Not SaaSOperations.SeparatedDataUsageAvailable() Then
		Return False;
	EndIf;	
	SetPrivilegedMode(True);
	Return ExportImportDataInternal.DownloadAborted();
EndFunction
	
#EndRegion