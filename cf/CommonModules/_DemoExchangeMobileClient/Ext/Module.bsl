#Region Private

// Generates an exchange package to be sent to "ExchangeNode". 
//
// Parameters:
//  ExchangeNode - ExchangePlanRef - "Mobile" node that participates in the exchange.
//
// Returns:
//  ValueStorage - Generated exchange package.
//
Function GenerateExchangeBatch(ExchangeNode) Export
	
	XMLFileName = GenerateXML(ExchangeNode);
	Package = New BinaryData(XMLFileName);
	StoragePackage = New ValueStorage(Package);
	Return StoragePackage;
	
EndFunction

// Writes to the infobase changes received from "ExchangeNode". 
//
// Parameters:
//  ExchangeNode - ExchangePlanRef - "Mobile" node that participates in the exchange.
//  ExchangeData - ValueStorage - Data package received from "ExchangeNode".
//
Procedure ReceiveExchangeBatch(ExchangeNode, ExchangeData) Export
	
	FileName = GetTempFileName("xml");
	BinaryData = ExchangeData.Get(); // BinaryData
	BinaryData.Write(FileName);
	
	SetPrivilegedMode(True);
	XMLReader = New XMLReader;
	XMLReader.OpenFile(FileName,,,"UTF-8");
	MessageReader = ExchangePlans.CreateMessageReader();
	MessageReader.BeginRead(XMLReader);
	ExchangePlans.DeleteChangeRecords(MessageReader.Sender,MessageReader.ReceivedNo);
	
	BeginTransaction();
	Try
		While CanReadXML(XMLReader) Do
			Data = ReadData(XMLReader);
			If Data <> Undefined Then
				Data.DataExchange.Sender = MessageReader.Sender;
				Data.DataExchange.Load = True;
				Data.Write();
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
	EndTry;
	
	MessageReader.EndRead();
	XMLReader.Close();
	
	DeleteFiles(FileName);
	
EndProcedure

// Writes the data as XML.
//
// Parameters:
//  XMLWriter - XMLWriter
//  Data - Arbitrary - Source data.
//
Procedure WriteData(XMLWriter, Data) Export
	
	// In this case, there's no data that requires ad-hoc processing.
	// Write data using the standard method.
	
	If TypeOf(Data) = Type("CatalogObject.ReportsOptions") Then
		ReportOptionsInHTML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.Users") Then
		UsersInHTML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("InformationRegisterRecordSet.ReportsSnapshots") Then
		ReportsSnapshotsIntoXML(XMLWriter, Data);
	EndIf;
	
	#If MobileStandaloneServer Then
		Constants._DemoRecordsSent.Set(Constants._DemoRecordsSent.Get() + 1);
	#EndIf
	
EndProcedure

// Reads data passed as XML.
//
// Parameters:
//  XMLReader - XMLReader
//
// Returns:
//  Arbitrary - Value that is read.
//
Function ReadData(XMLReader)
	
	If XMLReader.Name = "CatalogObject.ReportsOptions" Then
		Data = ReportOptionsFromXML(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.Users" Then
		Data = UsersFromXML(XMLReader);
	ElsIf XMLReader.Name = "InformationRegisterRecordSet.ReportsSnapshots" Then
		Data = ReportsSnapshotsFromXML(XMLReader);
	EndIf;
	
#If Not MobileStandaloneServer Then
#Else
	Constants._DemoRecordsReceived.Set(Constants._DemoRecordsReceived.Get() + 1);
#EndIf
	
	Return Data;
	
EndFunction

// Registers changes for all the data included in the exchange plan.
//
// Parameters:
//  ExchangeNode - Exchange plan node for which changes are being registered.
//
Procedure RecordDataChanges(ExchangeNode) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	ReportsSnapshots.Variant AS Variant
	|FROM
	|	InformationRegister.ReportsSnapshots AS ReportsSnapshots
	|WHERE
	|	ReportsSnapshots.Variant REFS Catalog.ReportsOptions";
	
	ExchangePlanContent = ExchangeNode.Metadata().Content;
	For Each ExchangePlanContentItem In ExchangePlanContent Do
		
		If ExchangePlanContentItem.Metadata = Metadata.Catalogs.ReportsOptions Then
			// @skip-check query-in-loop - Single-stage data processing
			ReferencesArrray = Query.Execute().Unload().UnloadColumn("Variant");
			ExchangePlans.RecordChanges(ExchangeNode, ReferencesArrray);
		Else
			ExchangePlans.RecordChanges(ExchangeNode,ExchangePlanContentItem.Metadata);
		EndIf;
		
	EndDo;
	
EndProcedure

Function GenerateXML(ExchangeNode)
	
	SetPrivilegedMode(True);
	XMLWriter = New XMLWriter;
	
	FileName = GetTempFileName("xml");
	XMLWriter.OpenFile(FileName, "UTF-8");
	
	XMLWriter.WriteXMLDeclaration();
	
	WriteMessage1 = ExchangePlans.CreateMessageWriter();
	WriteMessage1.BeginWrite(XMLWriter, ExchangeNode);
	
	XMLWriter.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
	XMLWriter.WriteNamespaceMapping("v8",  "http://v8.1c.ru/data");
	
	ChangesSelection = ExchangePlans.SelectChanges(ExchangeNode, WriteMessage1.MessageNo);
	While ChangesSelection.Next() Do
		Data = ChangesSelection.Get();
		WriteData(XMLWriter, Data);
	EndDo;
	
	WriteMessage1.EndWrite();
	XMLWriter.Close();
	
	Return FileName;
	
EndFunction

#Region DataExport

Procedure ReportOptionsInHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.ReportsOptions");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure UsersInHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.Users");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("IBUserID");
	XMLWriter.WriteText(String(Data.IBUserID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure ReportsSnapshotsIntoXML(XMLWriter, Data)
	
	If Data.Count() = 0 Then
		Return;
	EndIf;
	
	XMLWriter.WriteStartElement("InformationRegisterRecordSet.ReportsSnapshots");
	
	XMLWriter.WriteStartElement("User");
	XMLWriter.WriteText(String(Data[0].User.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Report");
	XMLWriter.WriteText(String(Data[0].Report.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ValueTypeReport");
	If TypeOf(Data[0].Report) = Type("CatalogRef.MetadataObjectIDs") Then
		XMLWriter.WriteText("MetadataObjectIDs");
	ElsIf TypeOf(Data[0].Report) = Type("CatalogRef.ExtensionObjectIDs") Then
		XMLWriter.WriteText("ExtensionObjectIDs");
	Else
		XMLWriter.WriteText("AdditionalReportsAndDataProcessors");
	EndIf;
	XMLWriter.WriteEndElement();

	XMLWriter.WriteStartElement("ReportVariant");
	XMLWriter.WriteText(String(Data[0].Variant.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("OptionValueType");
	XMLWriter.WriteText(?(TypeOf(Data[0].Variant) = Type("CatalogRef.ReportsOptions"),
							"ReportsOptions",
							""));
	XMLWriter.WriteEndElement();

	XMLWriter.WriteStartElement("UserSettingsHash");
	XMLWriter.WriteText(Data[0].UserSettingsHash);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ReportResult");
	ReportResult = XDTOSerializer.WriteXDTO(Data[0].ReportResult);
	XDTOFactory.WriteXML(XMLWriter, ReportResult, "ValueStorage", "http://v8.1c.ru/8.1/data/core", ,
		XMLTypeAssignment.Explicit);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("UpdateDate");
	XMLWriter.WriteText(String(Data[0].UpdateDate));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("LastViewedDate");
	XMLWriter.WriteText(String(Data[0].LastViewedDate));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ReportUpdateError");
	XMLWriter.WriteText(String(Data[0].ReportUpdateError));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

#EndRegion

#Region DataImport

Function ReportOptionsFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	DataReference = Catalogs.ReportsOptions.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Catalogs.ReportsOptions.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	
	Return Data;
	
EndFunction

Function UsersFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	DataReference = Catalogs.Users.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Catalogs.Users.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	Data.IBUserID = New UUID(XDTODataObject.IBUserID);
	
	Return Data;
	
EndFunction

Function ReportsSnapshotsFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);

	User = Catalogs.Users.GetRef(New UUID(XDTODataObject.User));
	If XDTODataObject.ValueTypeReport = "MetadataObjectIDs" Then
		Report = Catalogs.MetadataObjectIDs.GetRef(
			New UUID(XDTODataObject.Report));
	ElsIf XDTODataObject.ValueTypeReport = "ExtensionObjectIDs" Then
		Report = Catalogs.ExtensionObjectIDs.GetRef(
			New UUID(XDTODataObject.Report));
	Else
		Report = Catalogs.AdditionalReportsAndDataProcessors.GetRef(
			New UUID(XDTODataObject.Report));
	EndIf;
	If XDTODataObject.OptionValueType = "ReportsOptions" Then
		Variant = Catalogs.ReportsOptions.GetRef(New UUID(XDTODataObject.ReportVariant));
	Else
		Variant = Undefined;
	EndIf;

	RecordManager = InformationRegisters.ReportsSnapshots.CreateRecordManager();

	RecordManager.User = User;
	RecordManager.Report = Report;
	RecordManager.Variant = Variant;
	RecordManager.UserSettingsHash = XDTODataObject.UserSettingsHash;

	RecordManager.ReportResult = XDTODataObject.ReportResult.ValueStorage;
	RecordManager.UpdateDate = Date(XDTODataObject.UpdateDate);
	RecordManager.LastViewedDate = Date(XDTODataObject.LastViewedDate);

	RecordManager.ReportUpdateError = Boolean(XDTODataObject.ReportUpdateError);

	Try
		RecordManager.Write();
	Except
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось записать снимок отчета %1 по причине: 
				 |%2';
				|en = 'Cannot save the %1 report snapshot due to: 
				|%2';"), ?(ValueIsFilled(Variant), Variant, Report), ErrorProcessing.DetailErrorDescription(
			ErrorInfo()));
#If MobileStandaloneServer Then
		Common.MessageToUser(MessageText);
#Else
		WriteLogEvent(NStr("ru = 'Загрузка снимка отчета из XML';
										|en = 'Import a report snapshot from XML';", Common.DefaultLanguageCode()),
			EventLogLevel.Error, Metadata.InformationRegisters.ReportsSnapshots, , MessageText);
#EndIf
	EndTry;

	Return Undefined;
	
EndFunction

Procedure RegisterChangesForStandaloneModeOnWrite(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If TypeOf(Source) = Type("CatalogObject.ReportsOptions") Then
		Query = New Query;
		Query.SetParameter("Variant", Source.Ref);
		Query.Text =
		"SELECT TOP 1
		|	ReportsSnapshots.Variant AS Variant
		|FROM
		|	InformationRegister.ReportsSnapshots AS ReportsSnapshots
		|WHERE
		|	ReportsSnapshots.Variant = &Variant";
		If Query.Execute().IsEmpty() Then
			Return;
		EndIf;
	EndIf;
	
	NodesForRegistration = NodesForRegistration();
	
	RegisterChangesForExchangeNodes(NodesForRegistration, Source);
	
EndProcedure

// Returns an array of exchange plan nodes (except for the excluded ones).
//
// Returns:
//  Array of ExchangePlanRef._DemoMobileClient
//
Function NodesForRegistration()
	
	SetPrivilegedMode(True);
	
	Query = New Query("SELECT
	|	_DemoMobileClient.Ref
	|FROM
	|	ExchangePlan._DemoMobileClient AS _DemoMobileClient
	|WHERE
	|	NOT _DemoMobileClient.DeletionMark
	|	AND NOT _DemoMobileClient.ThisNode");
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
EndFunction

// Registers objects in mobile app's exchange nodes.
//
// Parameters:
//  NodesArray - Array of ExchangePlanRef._DemoMobileClient
//  Object - CatalogObject, InformationRegisterRecordSet - Object whose changes are being registered.
//
Procedure RegisterChangesForExchangeNodes(NodesArray, Object)
	
	If NodesArray.Count() = 0 Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	If TypeOf(Object) = Type("Array") Then
		ExchangePlans.RecordChanges(NodesArray, Object);
	Else
		ExchangePlans.RecordChanges(NodesArray, Object.Ref);
	EndIf;
	
EndProcedure

Procedure RegisterChangesForStandaloneModeRegistersOnWrite(Source, Cancel, Replacing) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	NodesForRegistration = NodesForRegistration();
	
	RegisterChangesForExchangeNodesRegisters(NodesForRegistration, Source);
	
	If TypeOf(Source) = Type("InformationRegisterRecordSet.ReportsSnapshots") Then
		ReferencesArrray = New Array;
		For Each Record In Source Do
			ReferencesArrray.Add(Record.Variant);
			ReferencesArrray.Add(Record.User);
		EndDo;
	EndIf;
	
	If ReferencesArrray.Count() > 0 Then
		RegisterChangesForExchangeNodes(NodesForRegistration, ReferencesArrray);
	EndIf;
	
EndProcedure

// Registers objects in mobile app's exchange nodes.
//
// Parameters:
//  NodesArray - Array of ExchangePlanRef._DemoMobileClient
//  RecordSet - InformationRegisterRecordSet - Object whose changes are being registered.
//
Procedure RegisterChangesForExchangeNodesRegisters(NodesArray, RecordSet)
	
	If NodesArray.Count() = 0 Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	ExchangePlans.RecordChanges(NodesArray, RecordSet);
	
EndProcedure

#EndRegion

#EndRegion
