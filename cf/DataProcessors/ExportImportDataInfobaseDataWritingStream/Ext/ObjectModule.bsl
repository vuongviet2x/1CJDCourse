#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var CurInitialization; // Boolean
Var CurRecordingStream; // XMLWriter
Var CurObjectCounter; 
Var CurSerializer;
Var CurFileStream;
Var CurFileName;

#EndRegion

#Region Internal

Procedure OpenFile(Val FileName, Val Serializer = Undefined, TypeOfDataObject = Undefined) Export
	
	If CurInitialization Then
		Raise NStr("ru = 'Объект уже был инициализирован ранее';
								|en = 'The object has already been initialized earlier';");
	EndIf;
		
	If Serializer = Undefined Then
		CurSerializer = XDTOSerializer;
	Else
		CurSerializer = Serializer;
	EndIf;
	
	CurFileName = FileName;
	CurFileStream = FileStreams.OpenForWrite(FileName);
	
	CurRecordingStream = New XMLWriter();
	CurRecordingStream.OpenStream(CurFileStream);
	CurRecordingStream.WriteXMLDeclaration();
		
	CurRecordingStream.WriteStartElement("Data");
	
	If ValueIsFilled(TypeOfDataObject) Then
		
		CurRecordingStream.WriteAttribute("Type", TypeOfDataObject);
		
	Else
		
		CurRecordingStream.WriteAttribute("Type", ExportImportDataInternal.InfobaseData());
		
	EndIf;
	
	NamespacesPrefixes = ExportImportDataInternal.NamespacesPrefixes();
	For Each NamespacesPrefix In NamespacesPrefixes Do
		CurRecordingStream.WriteNamespaceMapping(NamespacesPrefix.Value, NamespacesPrefix.Key);
	EndDo;
	
	CurObjectCounter = 0;
		
	CurInitialization = True;
	
EndProcedure

Procedure WriteInformationDatabaseDataObject(Object, Artifacts) Export
	
	CurRecordingStream.WriteStartElement("DumpElement");
	
	If Artifacts.Count() > 0 Then
		
		CurRecordingStream.WriteStartElement("Artefacts");
		For Each Artifact In Artifacts Do 
			
			XDTOFactory.WriteXML(CurRecordingStream, Artifact);
			
		EndDo;
		CurRecordingStream.WriteEndElement();
		
	EndIf;
	
	Try
		
		CurSerializer.WriteXML(CurRecordingStream, Object);
		
	Except
		
		SourceErrorText = CloudTechnology.DetailedErrorText(ErrorInfo());
		SourceErrorTextWithoutInvalidCharacters = CommonClientServer.ReplaceProhibitedXMLChars(
			SourceErrorText,
			Char(65533));
		
		Raise StrTemplate(NStr("ru = 'При выгрузке объекта %1 произошла ошибка: %2';
										|en = 'Error exporting object %1: %2';"),
			Object,
			SourceErrorTextWithoutInvalidCharacters);
		
	EndTry;
	
	CurRecordingStream.WriteEndElement();
	
	CurObjectCounter = CurObjectCounter + 1;
	
EndProcedure

// The object count.
// 
// Returns:
//  Number
Function ObjectCount() Export
	
	Return CurObjectCounter;
	
EndFunction

Procedure Close() Export
	
	CurRecordingStream.WriteEndElement();
	CurRecordingStream.Close();
	CurFileStream.Close();
	
EndProcedure

// Filename.
// 
// Returns:
//  String
Function FileName() Export
	
	Return CurFileName;
	
EndFunction

// The actual size exceeds the recommended one.
// 
// Returns:
//  Boolean
Function LargerThanRecommended() Export
	
	Return CurFileStream.Size() > 100 * 1024 * 1024; // 
	
EndFunction

#EndRegion

#Region Initialize

CurInitialization = False;

#EndRegion

#EndIf