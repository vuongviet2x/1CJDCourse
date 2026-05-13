///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Internal

Procedure Initialize(ExchangeComponents, Analysis = False) Export

	ExchangeComponents.RunMeasurements = ExchangeComponents.IsExchangeViaExchangePlan 
		And Constants.UsePerformanceMonitoringOfDataSynchronization.Get();
		
	If Not ExchangeComponents.RunMeasurements Then
		Return;
	EndIf;
	
	ExchangeSession = Catalogs.DataExchangesSessions.CreateItem();
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	DescriptionTemplate = NStr("ru = '%1 в %2 для ""%3"" (%4)';
								|en = '%1 on %2 for %3 (%4)';", DefaultLanguageCode); // Send on 7/18/2022 3:09 PM for "Enterprise Accounting 3.0"
	Description = StrTemplate(DescriptionTemplate,
		ExchangeComponents.ExchangeDirection,
		CurrentSessionDate(),
		ExchangeComponents.CorrespondentNode,
		ExchangeComponents.CorrespondentNode.Code);
				
	If Analysis Then
		Description = Description + " " + NStr("ru = '(Анализ)';
												|en = '(Analysis)';", DefaultLanguageCode);
	EndIf;
	
	ExchangeSession.Description = Description;
		
	ExchangeSession.InfobaseNode = ExchangeComponents.CorrespondentNode;
	ExchangeSession.Begin = CurrentSessionDate();
	
	If ExchangeComponents.ExchangeDirection = "Send" Then
		ExchangeSession.Send = True;
	ElsIf ExchangeComponents.ExchangeDirection = "Receive" Then
		ExchangeSession.Receive = True;
	EndIf;
	
	ExchangeSession.Write();
		
	ExchangeComponents.ExchangeSession = ExchangeSession;
	
	NameOfTemporaryMeasurementDirectory = 
		DataExchangeCached.TempFilesStorageDirectory() + String(New UUID);
		
	CreateDirectory(NameOfTemporaryMeasurementDirectory);
		
	NameOfTemporaryMeasurementFile = CommonClientServer.GetFullFileName(
		NameOfTemporaryMeasurementDirectory, "log.txt"); //ACC:441 - The temporary file will be deleted upon summing up
		
	ExchangeComponents.NameOfTemporaryMeasurementDirectory = NameOfTemporaryMeasurementDirectory;
	ExchangeComponents.NameOfTemporaryMeasurementFile = NameOfTemporaryMeasurementFile;
	ExchangeComponents.RecordingMeasurements = New TextWriter(NameOfTemporaryMeasurementFile, TextEncoding.UTF8);
	
	LogHeader = NStr("ru = 'Начало замера; Время выполнения; Тип события; Событие; Комментарий';
						|en = 'Sampling start; Runtime; Event type; Event; Comment';");
	ExchangeComponents.RecordingMeasurements.WriteLine(LogHeader, DefaultLanguageCode);
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.DataExchangesSessions");
		LockItem.SetValue("InfobaseNode", ExchangeComponents.CorrespondentNode);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	DataExchangesSessions.Ref,
			|	DataExchangesSessions.Begin AS Begin
			|FROM
			|	Catalog.DataExchangesSessions AS DataExchangesSessions
			|WHERE
			|	DataExchangesSessions.InfobaseNode = &Node
			|	AND DataExchangesSessions.Send = &Send
			|	AND DataExchangesSessions.Receive = &Receive
			|
			|ORDER BY
			|	Begin";
			
		Query.SetParameter("Node", ExchangeComponents.CorrespondentNode);
		Query.SetParameter("Send", ExchangeSession.Send);
		Query.SetParameter("Receive", ExchangeSession.Receive);
		
		SessionTable = Query.Execute().Unload();
		
		For Cnt = 1 To SessionTable.Count() - 5 Do
			ExchangeSession = SessionTable[0].Ref.GetObject();
			ExchangeSession.Delete();
			SessionTable.Delete(0);
		EndDo;
		
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
	
		MessageString = NStr("ru = 'Ошибка при попытке удаления сеанса обмена: %1. Описание ошибки: %2';
								|en = 'An error occurred when deleting the exchange session: %1. Error details: %2';",
			Common.DefaultLanguageCode());
			
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
			ExchangeSession, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
		WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
			EventLogLevel.Error,,, MessageString);
			
	EndTry
	
EndProcedure

Procedure ExitApp(ExchangeComponents) Export
	
	If Not ExchangeComponents.RunMeasurements Then
		Return;
	EndIf;
		
	ExchangeSession = ExchangeComponents.ExchangeSession;
	NameOfTemporaryMeasurementFile = ExchangeComponents.NameOfTemporaryMeasurementFile;
	
	ExchangeComponents.RunMeasurements = False;
	ExchangeComponents.RecordingMeasurements.Close();
	
	BeginTime = ExchangeSession.Begin;
	EndTime = CurrentSessionDate();
	
	NameOfTemporaryMeasurementDirectory = ExchangeComponents.NameOfTemporaryMeasurementDirectory;
	NameOfTemporaryTotalsFile = CommonClientServer.GetFullFileName(NameOfTemporaryMeasurementDirectory, "total.txt");
	ArchiveTempFileName = CommonClientServer.GetFullFileName(NameOfTemporaryMeasurementDirectory, "archive.zip");
	
	RecordingResults = New TextWriter(NameOfTemporaryTotalsFile);
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	// The header
	RecordingResults.WriteLine(NStr("ru = '--- Сеанс обмена ---';
									|en = '--- Exchange session ---';", DefaultLanguageCode));
	RecordingResults.WriteLine(NStr("ru = 'Направление обмена:';
									|en = 'Exchange direction:';", DefaultLanguageCode) + ExchangeComponents.ExchangeDirection);
	
	Template = NStr("ru = 'Узел: %1 (%2)';
					|en = 'Node: %1 (%2)';", DefaultLanguageCode); 
	RecordingResults.WriteLine(StrTemplate(Template, 
		ExchangeComponents.CorrespondentNode,
		ExchangeComponents.CorrespondentNode.Code));
	
	RecordingResults.WriteLine(NStr("ru = 'Начало:';
									|en = 'Start:';", DefaultLanguageCode) + BeginTime);
	RecordingResults.WriteLine(NStr("ru = 'Окончание:';
									|en = 'End:';", DefaultLanguageCode) + EndTime);
	RecordingResults.WriteLine(NStr("ru = 'Время выполнения (сек):';
									|en = 'Runtime (sec):';", DefaultLanguageCode) + (EndTime - BeginTime));
	RecordingResults.WriteLine("");
	
	// Event type summary
	RecordingResults.WriteLine(NStr("ru = '--- Итоговые значения по типам ---';
									|en = '--- Totals by event type ---';", DefaultLanguageCode));
	RecordingResults.WriteLine(NStr("ru = 'Тип события; Время выполнения';
									|en = 'Event type; Runtime';", DefaultLanguageCode));
	
	TableOfMeasurementsByEventType = ExchangeComponents.TableOfMeasurementsByEvents.Copy(, "EventType, RunTime");
	TableOfMeasurementsByEventType.GroupBy("EventType", "RunTime");
	
	Template = "%1; %2";
	For Each TableRow In TableOfMeasurementsByEventType Do
	
		String = StrTemplate(Template, 
			TableRow.EventType,
			TableRow.RunTime);
		
		RecordingResults.WriteLine(String);
			
	EndDo;
	
	RecordingResults.WriteLine("");
	
	// Event summary
	RecordingResults.WriteLine(NStr("ru = '--- Итоговые значения по событиям ---';
									|en = '--- Totals by event ---';", DefaultLanguageCode));
	RecordingResults.WriteLine(NStr("ru = 'Процент; Ср. время; Время; Кол-во событий; Тип события; Событие';
									|en = 'Percentage; Average time; Time; Number of events; Event type; Event';", DefaultLanguageCode));
	
	MeasurementsTable = ExchangeComponents.TableOfMeasurementsByEvents;
	MeasurementsTable.Sort("RunTime Desc");
	
	LeadTimeTotal = MeasurementsTable.Total("RunTime"); 
	
	Template = "%1; %2; %3; %4; %5; %6";
		
	For Each TableRow In MeasurementsTable Do
		
		If LeadTimeTotal > 0 Then
			Percent = Round(TableRow.RunTime / LeadTimeTotal * 100, 3);
		Else
			Percent = 0;
		EndIf;
		Percent = StringFunctionsClientServer.SupplementString(Percent, 7, " ", "Left");
				
		AverageLeadTime = Round(TableRow.RunTime / TableRow.Count, 3);
		AverageLeadTime = StringFunctionsClientServer.SupplementString(AverageLeadTime, 7, " ", "Left");
		
		RunTime = Round(TableRow.RunTime, 3);
		RunTime = Format(RunTime,"NG=;");
		RunTime = StringFunctionsClientServer.SupplementString(RunTime, 7, " ", "Left");
		
		Count = Format(TableRow.Count,"NG=;");
		Count = StringFunctionsClientServer.SupplementString(Count, 7, " ", "Left");
		EventType = StringFunctionsClientServer.SupplementString(TableRow.EventType, 11, " ", "Right");
		
		String = StrTemplate(Template,
			Percent,
			AverageLeadTime,
			RunTime,
			Count,
			EventType,
			TableRow.Event); 
			
		RecordingResults.WriteLine(String);
		
	EndDo;
	
	RecordingResults.Close();
	
	//	
	ExchangeSession.Ending = EndTime;
	ExchangeSession.RunTime = EndTime - BeginTime;
	
	Archive = New ZipFileWriter(ArchiveTempFileName);
	Archive.Add(NameOfTemporaryMeasurementFile);
	Archive.Add(NameOfTemporaryTotalsFile);
	Archive.Write();
		
	ExchangeSession.PerformanceMeasurements = New ValueStorage(New BinaryData(ArchiveTempFileName));
	ExchangeSession.Write();
	
	// Delete the temporary files
	DeleteFiles(NameOfTemporaryMeasurementDirectory);
	
EndProcedure

Function StartMeasurement() Export
		
	Return CurrentUniversalDateInMilliseconds();
	
EndFunction

Procedure FinishMeasurement(BeginTime, Event, Object, ExchangeComponents, EventType) Export

	If Event = "" Or Not ExchangeComponents.RunMeasurements Then
		Return;
	EndIf;
	
	Begin = Date(1,1,1) + BeginTime / 1000;
	
	EndTime = CurrentUniversalDateInMilliseconds();
	RunTime = Round((EndTime - BeginTime) / 1000, 3);
	
	ObjectPresentation = ObjectPresentation(Object);
	
	// Log
	StringPattern = "%1; %2; %3; %4; %5";
		
	String = StrTemplate(StringPattern,
		Begin,
		Format(RunTime,"NG=;"),
		EventType,
		Event,
		ObjectPresentation);
		
	RecordingMeasurements = ExchangeComponents.RecordingMeasurements;
	RecordingMeasurements.WriteLine(String);
	
	// Event summary data
	MeasurementsTable = ExchangeComponents.TableOfMeasurementsByEvents;
	Measurement = MeasurementsTable.Find(Event, "Event");
	
	If Measurement = Undefined Then
		NewMeasurement = MeasurementsTable.Add();
		NewMeasurement.Event = Event;
		NewMeasurement.EventType = EventType;
		NewMeasurement.Count = 1;
		NewMeasurement.RunTime = RunTime;
	Else 
		Measurement.Count = Measurement.Count + 1;
		Measurement.RunTime = Measurement.RunTime + RunTime;
	EndIf;
	
EndProcedure

Function TableOfMeasurementsByEvents() Export

	Table = New ValueTable;
	Table.Columns.Add("Event");
	Table.Columns.Add("EventType");
	Table.Columns.Add("Count");
	Table.Columns.Add("RunTime");

	Table.Indexes.Add("Event");
	
	Return Table;
	
EndFunction

Function EventTypeRule() Export

	Return NStr("ru = 'Правила обменов';
				|en = 'Exchange rules';", Common.DefaultLanguageCode());
	
EndFunction

Function EventTypeLibrary() Export

	Return NStr("ru = 'Подсистема обменов';
				|en = 'Exchange subsystem';", Common.DefaultLanguageCode());
	
EndFunction

Function EventTypeApplied() Export

	Return NStr("ru = 'Остальная конфигурация';
				|en = 'Other configuration components';", Common.DefaultLanguageCode());
	
EndFunction	

#EndRegion

#Region Private

Function ObjectPresentation(Object)

	If TypeOf(Object) = Type("Structure") Then
		
		ArrayOfKeysAndValues = New Array;
		Template = "%1 = ""%2""";
		
		If Object.Property("KeyProperties") Then
			
			For Each KeyAndValue In Object.KeyProperties Do
				
				If Not ValueIsFilled(KeyAndValue.Value) 
					Or TypeOf(KeyAndValue.Value) = Type("Structure") Then
					Continue;
				EndIf;
				
				String = StrTemplate(Template, KeyAndValue.Key, KeyAndValue.Value); 
				ArrayOfKeysAndValues.Add(String);
				
			EndDo;
			
		EndIf;
		
		Return StrConcat(ArrayOfKeysAndValues, ", ");
		
	Else
		
		Return String(Object);
		
	EndIf;

EndFunction

#EndRegion