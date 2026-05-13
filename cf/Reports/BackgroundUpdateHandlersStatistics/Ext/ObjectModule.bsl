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

#Region Private

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	Template = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.GetSettings(), DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(Template, New Structure("Table", UpdateExecutionProtocol()), DetailsData);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

Function UpdateExecutionProtocol()
	
	Result = New ValueTable;
	Result.Columns.Add("LineNumber", New TypeDescription("Number", New NumberQualifiers(15, 0, AllowedSign.Nonnegative)));
	Result.Columns.Add("Library", New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable)));
	Result.Columns.Add("Version", New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable)));
	Result.Columns.Add("RegistrationVersion", New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable)));
	Result.Columns.Add("Procedure", New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable)));
	Result.Columns.Add("Duration", New TypeDescription("Number", New NumberQualifiers(15, 3)));
	Result.Columns.Add("DataAreaUsage", New TypeDescription("Boolean"));
	Result.Columns.Add("DataAreaValue", New TypeDescription("Number", New NumberQualifiers(7, 0)));
	
	SchemaFileName = GetTempFileName("xsd");
	GetTemplate("JournalSchema").Write(SchemaFileName);
	
	Factory = CreateXDTOFactory(SchemaFileName);
	
	DeleteFiles(SchemaFileName);
	
	TypeLRRecording = Factory.Type("http://v8.1c.ru/eventLog", "Event");
	
	DataFileName = GetTempFileName("xml");
	
	BinaryData = GetFromTempStorage(DataAddress); // BinaryData
	BinaryData.Write(DataFileName);
	
	Read = New XMLReader;
	Read.OpenFile(DataFileName);
	Read.MoveToContent();
	Read.Read();
	
	OldEventName = InfobaseUpdateInternal.EventLogEvent() + ". " + NStr("ru = 'Протокол выполнения';
																										|en = 'Execution log';", Common.DefaultLanguageCode());
	EventName = InfobaseUpdateInternal.EventLogEventProtocol();
	
	LineNumber = 1;
	While Read.NodeType = XMLNodeType.StartElement Do
		EventLogRecord = Factory.ReadXML(Read, TypeLRRecording);
		
		If EventLogRecord.Event <> EventName
			And EventLogRecord.Event <> OldEventName Then
			Continue;
		EndIf;
		
		HandlerDetails = ValueFromXMLString(EventLogRecord.Comment);
		
		HandlerRow = Result.Add();
		HandlerRow.LineNumber = LineNumber;
		FillPropertyValues(HandlerRow, HandlerDetails);
		
		LineNumber = LineNumber + 1;
	EndDo;
	
	Read.Close();
	DeleteFiles(DataFileName);
	
	Return Result;
	
EndFunction

// Returns a value restored from the XML string. 
// Applicable only to serializable objects. 
// 
//
// Parameters:
//   XMLLine - Arbitrary - Value to serialize into an XML string.
//
// Returns:
//   String - XML string.
//
Function ValueFromXMLString(XMLLine) Export
	
	XMLReader = New XMLReader;
	XMLReader.SetString(XMLLine);
	
	Return XDTOSerializer.ReadXML(XMLReader);
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf