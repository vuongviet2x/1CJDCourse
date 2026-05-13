#Region Public

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export	
	
	Types.Add(Metadata.InformationRegisters.ViewedInformationCenterData);
		
EndProcedure

// Fills a structure with arrays of supported versions of the subsystems that are subject to versioning.
// Subsystem names are used as structure keys.
// Implements the InterfaceVersion web service functionality.
// When integrating, change the procedure body so that it returns current version sets (see the example below).
//
// Parameters:
// SupportedVersionsStructure - Structure - Details: Key - Subsystem name, Value - Array of supported versions names.
//
// Example:
//	// FilesTransferService
//	VersionsArray = New Array;
//	VersionsArray.Add("1.0.1.1");	
//	VersionsArray.Add("1.0.2.1"); 
//	SupportedVersionsStructure.Insert("FilesTransferService", VersionsArray);
//	// End FilesTransferService
//
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export

	VersionsArray = New Array;
	VersionsArray.Add("1.0.1.1");
	SupportedVersionsStructure.Insert("SupportServiceData", VersionsArray);
	
	VersionsArray = New Array;
	VersionsArray.Add("1.0.1.1");
	SupportedVersionsStructure.Insert("InformationReferences", VersionsArray);
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
//	Settings -  See ScheduledJobsOverridable.OnDefineScheduledJobSettings.Settings
//@skip-warning EmptyMethod - Implementation feature.
//
Procedure OnDefineScheduledJobSettings(Settings) Export
	
EndProcedure

// Generates a list of infobase parameters.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
// ParametersTable - ValueTable:
//  * Name - String - Parameter name.
//  * LongDesc - String - Parameter details to be displayed in the interface.
//  * ForbiddenReading - Boolean - Unreadable parameter flag. For example, can be set for passwords.
//                            
//  * RecordBan - Boolean - Immutable parameter flag.
//  * Type - TypeDescription - Parameter value type.
//                          Valid are primitive types and enumerations that exist in the managed application.
//
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
EndProcedure

// Called before an attempt to write values of infobase parameters to
// constants with the same name.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
// ParameterValues - Structure - Parameter values to assign.
// If the value is assigned in this procedure, delete the corresponding KeyAndValue pair from the structure.
// 
//
Procedure OnSetIBParametersValues(Val ParameterValues) Export
	
EndProcedure

// Receives a list of message handlers that are processed by the library subsystems.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//  Handlers - ValueTable - See the field list in MessageExchange.NewMessagesHandlersTable.
// 
Procedure OnDefineMessagesChannelsHandlers(Handlers) Export
	
EndProcedure

// Fills in the passed array with the common modules used as
//  incoming message interface handlers.
//  @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  HandlersArray - Array - 
// 
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
		
EndProcedure

// Register the default master data handlers
//
// When receiving a notification about that new shared data is available, the
// NewDataAvailable procedure is called from modules registered with GetSuppliedDataHandlers.
// XDTODataObject Descriptor is passed to the procedure.
// 
// If NewDataAvailable sets Import to True, 
// the data is imported, the descriptor and the data file path are passed to the 
// ProcessNewData procedure. The file is automatically deleted once the procedure is executed.
// If a file is not specified in the Service Manager - the argument value is Undefined.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters: 
//   Handlers-  ValueTable - Table to add handlers to. Has the following columns:
//   * DataKind - String - Code of the kind of the data being handled.
//   * HandlerCode - String - Intended for recovery after the handler fails. The length is 20 characters. 
//   * Handler - CommonModule - Module with the following export procedures:
//        NewDataAvailable(Descriptor, Import)  
//        ProcessNewData(Descriptor, PathToFile)
//        DataProcessingCanceled(Descriptor)
//
Procedure OnDefineSuppliedDataHandlers(Handlers) Export
	
	RegisterSuppliedDataHandlers(Handlers);
	
EndProcedure

// Adds update handler procedures required by the subsystem to the Handlers list.
//
// Parameters:
//   Handlers - See InfobaseUpdate.NewUpdateHandlerTable
// 
Procedure RegisterUpdateHandlers(Handlers) Export
	
	If SaaSOperations.DataSeparationEnabled() Then
		
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.ExclusiveMode = False;
		Handler.SharedData = True;
		Handler.InitialFilling = True;
		Handler.Procedure = "InformationCenterInternal.CreateDictionaryOfCompletePathsToFormsInServiceModel";
		Handler.Comment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Сформировать словарь полных путей к формам в справочнике ""%1"".';
				|en = 'Generate a dictionary of full paths to forms in the ""%1"" catalog.';"),
			Metadata.Catalogs.FullPathsToForms);
			
	Else
		
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.Id = New UUID("f93cd97f-a84c-4a28-bda3-7c39d4fa55fd");
		Handler.InitialFilling = True;
		Handler.ExecutionMode = "Deferred";
		Handler.Procedure = "InformationCenterInternal.GenerateDictionaryOfCompletePathsToForms";
		Handler.Comment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Сформировать словарь полных путей к формам в справочнике ""%1"".';
				|en = 'Generate a dictionary of full paths to forms in the ""%1"" catalog.';"),
			Metadata.Catalogs.FullPathsToForms);
		
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.5.12";
	Handler.ExclusiveMode = False;
	Handler.SharedData = True;
	Handler.InitialFilling = True;
	Handler.Procedure = "InformationCenterInternal.FillInHashOfFullPathToForm";
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.3.35";
	Handler.ExclusiveMode = False;
	Handler.SharedData = True;
	Handler.InitialFilling = True;
	Handler.Procedure = "InformationCenterInternal.FillInEndDateOfRelevanceOfInformationLinks";
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.7.2";
	Handler.ExclusiveMode = False;
	Handler.SharedData = True;
	Handler.InitialFilling = True;
	Handler.Procedure = "InformationCenterInternal.FillInInformationLinkFromConfiguration";
	
	If SaaSOperations.DataSeparationEnabled() Then
		
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.ExclusiveMode = False;
		Handler.SharedData = True;
		Handler.Procedure = "InformationCenterInternal.UpdateInformationLinksForFormsInServiceModel";
		
	Else
		
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.ExecutionMode = "Deferred";
		Handler.Id = New UUID("a6710034-fd9d-4f46-8ba5-e44ba86bf8fa");
		Handler.Procedure = "InformationCenterInternal.UpdateInformationLinksForFormsInLocalMode";
		Handler.Comment = NStr("ru = 'Обновление информационных ссылок для форм.';
										|en = 'Update external links for forms.';");
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region Internal

Procedure CreateDictionaryOfCompletePathsToFormsInServiceModel(Parameters = Undefined) Export

	GenerateDictionaryOfCompletePathsToForms(Parameters);
	
EndProcedure

// Populates the FullPathsToForms catalog with full paths to forms.
//
Procedure GenerateDictionaryOfCompletePathsToForms(Parameters = Undefined) Export
	
	If SaaSOperations.SessionSeparatorUsage() Then
		Return;
	EndIf;
	
	ArrayOfForms = New Array; // Array of String
	ArrayOfForms.Add("DataProcessor.InformationCenter.Form.InformationCenter");
	
	InformationCenterServerOverridable.FormsWithInformationLinks(ArrayOfForms);
	
	// Generating a table with the list of full configuration forms
	TableOfForms = New ValueTable;
	TableOfForms.Columns.Add("FullFormPath", New TypeDescription("String"));
	TableOfForms.Columns.Add("Hash", New TypeDescription("String"));
	
	For Each FullFormPath In ArrayOfForms Do
		
		NewRow = TableOfForms.Add();
		NewRow.FullFormPath = FullFormPath;
		NewRow.Hash = InformationCenterServer.HashOfFullPathToForm(FullFormPath);
		
	EndDo;
	
	// Populate the FullPathsToForms catalog.
	Query = New Query;
	Query.SetParameter("TableOfForms", TableOfForms);
	Query.Text =
	"SELECT
	|	TableOfForms.FullFormPath AS FullFormPath,
	|	SUBSTRING(TableOfForms.Hash, 1, 32) AS Hash
	|INTO TableOfForms
	|FROM
	|	&TableOfForms AS TableOfForms
	|
	|INDEX BY
	|	Hash
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FullPathsToForms.Ref AS Ref,
	|	FullPathsToForms.Hash AS Hash
	|INTO ExistingCompletePathsToForms
	|FROM
	|	Catalog.FullPathsToForms AS FullPathsToForms
	|
	|INDEX BY
	|	Hash
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfForms.FullFormPath AS FullFormPath
	|FROM
	|	TableOfForms AS TableOfForms
	|		LEFT JOIN ExistingCompletePathsToForms AS ExistingCompletePathsToForms
	|		ON TableOfForms.Hash = ExistingCompletePathsToForms.Hash
	|WHERE
	|	ExistingCompletePathsToForms.Ref IS NULL ";
	SelectingForms = Query.Execute().Select();
	While SelectingForms.Next() Do
		If ThereIsFormAlongFullPath(SelectingForms.FullFormPath) Then
			AddFullNameToCatalog(SelectingForms.FullFormPath);
		EndIf;
	EndDo;
	
EndProcedure

// During configuration updates, update the list of external links.
// To do so, use the Service Manager.
//
Procedure UpdateInformationLinksForFormsInServiceModel() Export
	
	Try
		
		UpdateInformationLinksForFormsInLocalMode();
			
		If SaaSOperations.ServiceManagerEndpointConfigured() Then
			SetPrivilegedMode(True);
			ConfigurationName = Metadata.Name;
			ProxyWebService = InformationCenterServer.GetProxyInformationCenter_1_0_1_1();
			SetPrivilegedMode(False);
			Result = ProxyWebService.UpdateInfoReference(ConfigurationName);
			If Result Then 
				Return;
			EndIf;
			
			ErrorText = NStr("ru = 'Не удалось обновить Информационные ссылки';
								|en = 'Cannot update external links';");
			EventName = InformationCenterServer.GetEventNameForLog();
			WriteLogEvent(EventName, EventLogLevel.Error,,, ErrorText);
		EndIf;
		
	Except
		
		EventName = InformationCenterServer.GetEventNameForLog();
		WriteLogEvent(EventName, EventLogLevel.Error,,, 
			DetailErrorDescription(ErrorInfo()));
			
	EndTry;
	
EndProcedure

// During configuration updates, update the list of external links.
// To do so, use the Service Manager.
//
Procedure UpdateInformationLinksForFormsInLocalMode(Parameters = Undefined) Export
	
	If SaaSOperations.SessionSeparatorUsage() Then
		Return;
	EndIf;
	
	ClearDuplicatesOfPredefinedElements();
	
	EventName = InformationCenterServer.GetEventNameForLog();
	
	CommonTemplates = InformationCenterServer.GetCommonTemplatesForInformationalLinks();
	For Each CommonTemplate In CommonTemplates Do
		
		PathToFile = GetTempFileName("xml");
		TextDocument = CommonTemplate;
		TextDocument.Write(PathToFile);
		
		Try
			DownloadInformationalLinks(PathToFile);
		Except
			ErrorInfo = ErrorInfo();
			WriteLogEvent(EventName, EventLogLevel.Error,,, 
				DetailErrorDescription(ErrorInfo));
		EndTry;
		
		Try
			DeleteFiles(PathToFile);
		Except
			ErrorInfo = ErrorInfo();
			WriteLogEvent(EventName, EventLogLevel.Error,,, 
				DetailErrorDescription(ErrorInfo));
		EndTry;
		
	EndDo;
	
EndProcedure

// If an item 0f the InformationReferencesForForms catalog has an empty end date, the method populates it with "31.12.3999". 
// 
//
Procedure FillInEndDateOfRelevanceOfInformationLinks() Export 
	
	Query = New Query;
	Query.SetParameter("RelevantTo", '00010101000000');
	Query.Text =
	"SELECT
	|	InformationReferencesForForms.Ref AS InformationLink
	|FROM
	|	Catalog.InformationReferencesForForms AS InformationReferencesForForms
	|WHERE
	|	InformationReferencesForForms.RelevantTo = &RelevantTo
	|	AND NOT InformationReferencesForForms.DeletionMark";
	Selection = Query.Execute().Select();
	While Selection.Next() Do 
		
		InformationLink = Selection.InformationLink.GetObject(); // CatalogObject.InformationReferencesForForms
		InformationLink.Write();
		
	EndDo;
	
EndProcedure

// Generates MD5 hash of the full path to the FullPathsToForms catalog form.
//
Procedure FillInHashOfFullPathToForm() Export
	
	Query = New Query(
		"SELECT
		|	FullPathsToForms.Ref
		|FROM
		|	Catalog.FullPathsToForms AS FullPathsToForms
		|WHERE
		|	FullPathsToForms.Hash = &Hash");
	Query.SetParameter("Hash", "");
	Selection = Query.Execute().Select();
	While Selection.Next() Do 
		RecordObject_ = Selection.Ref.GetObject(); // CatalogObject.FullPathsToForms
		RecordObject_.Write();
	EndDo;
	
EndProcedure

// Sets the FromConfiguration flag in external links.
//
Procedure FillInInformationLinkFromConfiguration() Export
	
	EventName = InformationCenterServer.GetEventNameForLog();
	CommonTemplates = InformationCenterServer.GetCommonTemplatesForInformationalLinks();
	
	For Each CommonTemplate In CommonTemplates Do
		
		PathToFile = GetTempFileName("xml");
		TextDocument = CommonTemplate;
		TextDocument.Write(PathToFile);
		
		Namespace = DefineNamespaceByFile(PathToFile);
		If Namespace = Undefined Then 
			Continue;
		EndIf;
		
		ReadingInformationalLinks = New XMLReader; 
		ReadingInformationalLinks.OpenFile(PathToFile); 
		ReadingInformationalLinks.MoveToContent();
		ReadingInformationalLinks.Read();
		
		While ReadingInformationalLinks.NodeType = XMLNodeType.StartElement Do
			
			TypeOfInformationLink = XDTOFactory.Type(Namespace, "reference");
			InformationLink = XDTOFactory.ReadXML(ReadingInformationalLinks, TypeOfInformationLink);
			URL = InformationLink.address;
			If IsBlankString(URL) Then
				Continue;
			EndIf;
			
			Query = New Query(
				"SELECT
				|	InformationReferencesForForms.Ref AS InformationLink
				|FROM
				|	Catalog.InformationReferencesForForms AS InformationReferencesForForms
				|WHERE
				|	InformationReferencesForForms.Address LIKE &URL");
			Query.SetParameter("URL", URL);
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				ReferenceObject = Selection.InformationLink.GetObject();
				ReferenceObject.FromConfiguration = True;
				ReferenceObject.DataExchange.Load = True;
				ReferenceObject.Write();
			EndDo;
			
		EndDo;
		
		ReadingInformationalLinks.Close();
		
		Try
			DeleteFiles(PathToFile);
		Except
			ErrorInfo = ErrorInfo();
			WriteLogEvent(EventName, EventLogLevel.Error,,, 
				DetailErrorDescription(ErrorInfo));
		EndTry;
		
	EndDo;
	
EndProcedure

Procedure NewDataAvailable(Val Descriptor, ToImport, Val JSONDescriptor = False) Export
	
	If Descriptor.DataType = "InformationReferences" Then
		
		ConfigurationName = GetConfigurationNameByHandle(Descriptor);
		If ConfigurationName = Undefined Then 
			ToImport = False;
			Return;
		EndIf;
		
		ToImport = ?((Upper(Metadata.Name)) = Upper(ConfigurationName), True, False);
		
	EndIf;
	
EndProcedure

Procedure NewJSONDataAvailable(Val Descriptor, ToImport) Export
	
	NewDataAvailable(Descriptor, ToImport, True);
	
EndProcedure

Procedure ProcessNewData(Val Descriptor, Val PathToFile, Val JSONDescriptor = False) Export
	
	If Descriptor.DataType = "InformationReferences" Then
		ProcessInformationalLinks(Descriptor, PathToFile);
	EndIf;
	
EndProcedure

Procedure ProcessNewJSONData(Val Descriptor, Val PathToFile) Export
	
	ProcessNewData(Descriptor, PathToFile, True);
	
EndProcedure

// Runs if data processing is failed due to an error.
//
Procedure DataProcessingCanceled(Val Descriptor) Export 
	
	Return;
	
EndProcedure

// Detailed error text.
// 
// Parameters:
//  ErrorInfo - ErrorInfo - Error details.
// 
// Returns:
//  String - Detailed error text.
Function DetailedErrorText(ErrorInfo) Export
	
	Return ErrorProcessing.DetailErrorDescription(ErrorInfo);

EndFunction

// Brief error text.
// 
// Parameters:
//  ErrorInfo - ErrorInfo - Error details.
// 
// Returns:
//  String - Brief error text.
Function ShortErrorText(ErrorInfo) Export
	
	Return ErrorProcessing.BriefErrorDescription(ErrorInfo);

EndFunction

#EndRegion

#Region Private

Procedure ClearDuplicatesOfPredefinedElements()
	
	Query = New Query(
		"SELECT
		|	LinksForForms.Ref AS InformationLink
		|FROM
		|	Catalog.InformationReferencesForForms AS LinksForForms
		|		INNER JOIN Catalog.InformationReferencesForForms AS LinksForForms1
		|		ON LinksForForms.PredefinedDataName = LinksForForms1.PredefinedDataName
		|		AND LinksForForms.Ref < LinksForForms1.Ref
		|WHERE
		|	NOT LinksForForms.DeletionMark
		|	AND
		|	NOT LinksForForms1.DeletionMark
		|	AND LinksForForms.PredefinedDataName <> """"
		|	AND LinksForForms1.PredefinedDataName <> """"");
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		InformationLink = Selection.InformationLink.GetObject();
		InformationLink.PredefinedDataName = "";
		InformationLink.DeletionMark = True;
		InformationLink.DataExchange.Load = True;
		InformationLink.Write();
		
	EndDo;
	
EndProcedure

Function HierarchyOfTags()
	
	TagsTree = New ValueTree;
	TagsTree.Columns.Add("Name", New TypeDescription("String"));
	
	// Read a common template.
	ContentOfTemplate = GetCommonTemplate("TagsMapToCommonForms").GetText();
	
	RecordsOfMatchingTagsAndForms = New XMLReader;
	RecordsOfMatchingTagsAndForms.SetString(ContentOfTemplate);
	
	CurTagInTree = Undefined;
	While RecordsOfMatchingTagsAndForms.Read() Do
		
		// Read the current tag.
		ThisIsTag = RecordsOfMatchingTagsAndForms.NodeType = 
			XMLNodeType.StartElement And Upper(TrimAll(RecordsOfMatchingTagsAndForms.Name)) = Upper("tag");
			
		If ThisIsTag Then 
			While RecordsOfMatchingTagsAndForms.ReadAttribute() Do 
				If Upper(RecordsOfMatchingTagsAndForms.Name) = Upper("name") Then
					CurTagInTree     = TagsTree.Rows.Add();
					CurTagInTree.Name = RecordsOfMatchingTagsAndForms.Value;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		// Read a form.
		ThisIsForm = RecordsOfMatchingTagsAndForms.NodeType = 
			XMLNodeType.StartElement And Upper(TrimAll(RecordsOfMatchingTagsAndForms.Name)) = Upper("form");
			
		If Not ThisIsForm Then
			Continue;
		EndIf;	 
		
		While RecordsOfMatchingTagsAndForms.ReadAttribute() Do
			 
			If Upper(RecordsOfMatchingTagsAndForms.Name) = Upper("path") Then
				
				If CurTagInTree = Undefined Then 
					Break;
				EndIf;
				
				CurTreeElement     = CurTagInTree.Rows.Add();
				CurTreeElement.Name = RecordsOfMatchingTagsAndForms.Value;
				
				Break;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return TagsTree;
	
EndFunction

// Registers default master data handlers for one day and for all time.
//
// Parameters:
//	Handlers - See MessagesExchangeOverridable.GetMessagesChannelsHandlers.Handlers
//
Procedure RegisterSuppliedDataHandlers(Val Handlers)
	
	Handler                = Handlers.Add();
	Handler.DataKind      = "InformationReferences";
	Handler.HandlerCode = "InformationReferences";
	Handler.Handler     = InformationCenterInternal;
	
EndProcedure

// Processes external links retrieved by the default master data mechanism.
//
// Parameters:
//  Descriptor - Structure - Descriptor.
//  PathToFile - String - File path.
//
Procedure ProcessInformationalLinks(Descriptor, PathToFile)
	
	DownloadInformationalLinks(PathToFile);
	
EndProcedure

// The configuration name by descriptor.
//
// Parameters:
//  Descriptor - Structure - Descriptor.
//
// Returns:
//  String - Configuration name.
//
Function GetConfigurationNameByHandle(Descriptor)
	
	For Each Characteristic In Descriptor.Properties.Property Do
		If Characteristic.Code = "PlacementObject" Then
			Try
				Return Characteristic.Value;
			Except
				EventName = InformationCenterServer.GetEventNameForLog();
				WriteLogEvent(EventName, EventLogLevel.Error,,,
					DetailErrorDescription(ErrorInfo()));
				Return Undefined;
			EndTry;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Imports external links into a catalog.
//
// Parameters:
//  PathToFile - String - File path.
//  LocalMode_ - Boolean - If True, the local mode. Otherwise, False.
//
Procedure DownloadInformationalLinks(PathToFile, LocalMode_ = True)
	
	// Generate a tag tree.
	TagsTree = HierarchyOfTags();
	
	UpdateDate = CurrentSessionDate();
	
	Namespace = DefineNamespaceByFile(PathToFile);
	If Namespace = Undefined Then
		Return;
	EndIf;
	TypeOfInformationLink = XDTOFactory.Type(Namespace, "reference"); 
	
	ReadingInformationalLinks = New XMLReader; 
	ReadingInformationalLinks.OpenFile(PathToFile); 
	ReadingInformationalLinks.MoveToContent();
	ReadingInformationalLinks.Read();
	
	While ReadingInformationalLinks.NodeType = XMLNodeType.StartElement Do
		
		InformationLink = XDTOFactory.ReadXML(ReadingInformationalLinks, TypeOfInformationLink);
		
		// Predefined item.
		If Not IsBlankString(InformationLink.namePredifined) Then 
			Try
				WritePredefinedInformationLink(InformationLink, LocalMode_);
			Except
				EventName = InformationCenterServer.GetEventNameForLog();
				WriteLogEvent(EventName, EventLogLevel.Error,,,
					DetailErrorDescription(ErrorInfo()));
			EndTry;
			Continue;
		EndIf;
		
		// Ordinary item.
		For Each Context In InformationLink.context Do 
			Try
				WriteLinkByContext(TagsTree, InformationLink, Context, UpdateDate, LocalMode_);
			Except
				EventName = InformationCenterServer.GetEventNameForLog();
				WriteLogEvent(EventName, EventLogLevel.Error,,,
					DetailErrorDescription(ErrorInfo()));
			EndTry;
		EndDo;
		
	EndDo;
	
	ReadingInformationalLinks.Close();
	
	ClearNonUpdatedLinks(UpdateDate, LocalMode_);
	
EndProcedure

Procedure WritePredefinedInformationLink(ReferenceObject, LocalMode_)
	
	Try
		RefValue = Catalogs.InformationReferencesForForms[ReferenceObject.namePredifined];
		CatalogItem = RefValue.GetObject(); // CatalogObject.InformationReferencesForForms
	Except
		EventName = InformationCenterServer.GetEventNameForLog();
		WriteLogEvent(EventName, EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	CatalogItem.Address                     = ReferenceObject.address;
	CatalogItem.RelevantFrom    = ReferenceObject.dateFrom;
	CatalogItem.RelevantTo = ReferenceObject.dateTo;
	CatalogItem.Description              = ReferenceObject.name;
	CatalogItem.ToolTip                 = ReferenceObject.helpText;
	CatalogItem.FromConfiguration            = LocalMode_;
	CatalogItem.Write();
	
EndProcedure

Procedure ClearNonUpdatedLinks(UpdateDate, ClearLocal)
	
	SetPrivilegedMode(True);
	
	Query = New Query(
		"SELECT
		|	InformationReferencesForForms.Ref AS InformationLink
		|FROM
		|	Catalog.InformationReferencesForForms AS InformationReferencesForForms
		|WHERE
		|	InformationReferencesForForms.FromConfiguration = &Local_1
		|	AND InformationReferencesForForms.UpdateDate <> &UpdateDate
		|	AND NOT InformationReferencesForForms.Predefined");
	Query.SetParameter("Local_1", ClearLocal);
	Query.SetParameter("UpdateDate", UpdateDate);
	Selection = Query.Execute().Select();
	While Selection.Next() Do 
		
		Object = Selection.InformationLink.GetObject();
		Object.DataExchange.Load = True;
		Object.Delete();
		
	EndDo;
	
EndProcedure

Procedure WriteLinkByContext(TagsTree, ReferenceObject, Context, UpdateDate, LocalMode_)
	
	Result = CheckForFormNameByTag(Context.tag);
	If Result.ThisIsPathToForm Then 
		WriteLinkByContext_(ReferenceObject, Context, Result.FormPath, UpdateDate, LocalMode_);
		Return;
	EndIf;
	
	Tag             = Context.tag;
	FoundRow = TagsTree.Rows.Find(Tag, "Name");
	If FoundRow = Undefined Then 
		RecordLinkById(ReferenceObject, Context, UpdateDate, LocalMode_);
		Return;
	EndIf;
	
	For Each TreeRow In FoundRow.Rows Do 
		
		FormName = TreeRow.Name;
		LinkToFormPath = FormPathReferenceInCatalog(FormName);
		If LinkToFormPath.IsEmpty() Then 
			Continue;
		EndIf;
		
		WriteLinkByContext_(ReferenceObject, Context, LinkToFormPath, UpdateDate, LocalMode_);
		
	EndDo;
	
EndProcedure

Procedure RecordLinkById(ReferenceObject, Context, UpdateDate, LocalMode_)
	
	CatalogItem = Catalogs.InformationReferencesForForms.CreateItem();
	CatalogItem.Address                     = ReferenceObject.address;
	CatalogItem.Id             = Context.tag;
	CatalogItem.Weight                       = Context.weight;
	CatalogItem.RelevantFrom    = ReferenceObject.dateFrom;
	CatalogItem.RelevantTo = ReferenceObject.dateTo;
	CatalogItem.Description              = ReferenceObject.name;
	CatalogItem.ToolTip                 = ReferenceObject.helpText;
	CatalogItem.UpdateDate            = UpdateDate;
	CatalogItem.FromConfiguration            = LocalMode_;
	CatalogItem.Write();
	
EndProcedure

Procedure WriteLinkByContext_(ReferenceObject, Context, LinkToFormPath, UpdateDate, LocalMode_)
	
	Ref = ThereIsInformationLinkForThisForm(ReferenceObject.address, LinkToFormPath);
	
	If Ref = Undefined Then 
		CatalogItem = Catalogs.InformationReferencesForForms.CreateItem();
	Else
		CatalogItem = Ref.GetObject();
	EndIf;
	
	CatalogItem.Address                     = ReferenceObject.address;
	CatalogItem.Weight                       = Context.weight;
	CatalogItem.RelevantFrom    = ReferenceObject.dateFrom;
	CatalogItem.RelevantTo = ReferenceObject.dateTo;
	CatalogItem.Description              = ReferenceObject.name;
	CatalogItem.ToolTip                 = ReferenceObject.helpText;
	CatalogItem.FullFormPath          = LinkToFormPath;
	CatalogItem.UpdateDate            = UpdateDate;
	CatalogItem.Write();
	
EndProcedure

Function ThereIsInformationLinkForThisForm(Address, LinkToFormPath)
	
	Query = New Query;
	Query.SetParameter("FullFormPath", LinkToFormPath);
	Query.SetParameter("Address",            Address);
	Query.Text = "SELECT
	               |	InformationReferencesForForms.Ref AS Ref
	               |FROM
	               |	Catalog.InformationReferencesForForms AS InformationReferencesForForms
	               |WHERE
	               |	InformationReferencesForForms.FullFormPath = &FullFormPath
	               |	AND InformationReferencesForForms.Address LIKE &Address";
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do 
		Return Selection.Ref;
	EndDo;
	
	Return Undefined;
	
EndFunction

Function CheckForFormNameByTag(Tag_)
	
	Result = New Structure("ThisIsPathToForm", False);
	
	Query = New Query;
	Query.SetParameter("FullFormPath", Tag_);
	Query.Text = 
	"SELECT
	|	FullPathsToForms.Ref AS Ref
	|FROM
	|	Catalog.FullPathsToForms AS FullPathsToForms
	|WHERE
	|	FullPathsToForms.FullFormPath LIKE &FullFormPath";
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then 
		Return Result;
	EndIf;
	
	Result.ThisIsPathToForm = True;
	QuerySelection = QueryResult.Select();
	While QuerySelection.Next() Do 
		Result.Insert("FormPath", QuerySelection.Ref);
		Return Result;
	EndDo;
	
	Raise StrTemplate(NStr("ru = 'Не удалось определить имя формы по тегу - %1';
									|en = 'Cannot determine the form name by tag %1';"), Tag_);
	
EndFunction

Procedure AddFullNameToCatalog(FullFormName)
	
	SetPrivilegedMode(True);
	CatalogItem = Catalogs.FullPathsToForms.CreateItem();
	CatalogItem.Description     = FullFormName;
	CatalogItem.FullFormPath = FullFormName;
	CatalogItem.Write();
	
EndProcedure

Function FormPathReferenceInCatalog(FullFormName)
	
	Query = New Query;
	Query.SetParameter("FullFormPath", FullFormName);
	Query.Text = 
	"SELECT
	|	FullPathsToForms.Ref AS Ref
	|FROM
	|	Catalog.FullPathsToForms AS FullPathsToForms
	|WHERE
	|	FullPathsToForms.FullFormPath LIKE &FullFormPath";
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	While Selection.Next() Do 
		Return Selection.Ref;
	EndDo;
	
	Return Catalogs.FullPathsToForms.EmptyRef();
	
EndFunction

Function DefineNamespaceByFile(PathToFile)
	
	ReadingInformationalLinks = New XMLReader; 
	ReadingInformationalLinks.OpenFile(PathToFile); 
	ReadingInformationalLinks.MoveToContent();
	ReadingInformationalLinks.Read();
	
	While ReadingInformationalLinks.NodeType = XMLNodeType.StartElement Do
		
		InformationLink = XDTOFactory.ReadXML(ReadingInformationalLinks);
		ReadingInformationalLinks.Close();
		
		If ValueIsFilled(InformationLink.Type().NamespaceURI) Then
			Return InformationLink.Type().NamespaceURI;
		Else
			EventName = InformationCenterServer.GetEventNameForLog() + 
			"." + NStr("ru = 'Информационные ссылки';
						|en = 'External links';", Common.DefaultLanguageCode());
			XMLWriter = New XMLWriter;
			XMLWriter.SetString();
			XDTOFactory.WriteXML(XMLWriter, InformationLink);
			ObjectPresentation = XMLWriter.Close();
			WriteLogEvent(EventName,EventLogLevel.Error,,,
				NStr("ru = 'Не удалось определить тип информационной ссылки:';
					|en = 'Cannot determine an external link type:';")
				+ Chars.LF + Chars.LF + ObjectPresentation);
			
			Return Undefined;
			
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

// Returns a flag value that defines whether the configuration contains a form with the given full path.
//
// Parameters:
//  FullFormPath - String - Full path to form.
//  WriteErrorToVZHR - Boolean - Flag indicating whether to log an error if the form with the given path is missing.
//
// Returns:
//  Boolean - True if the form exists. Otherwise, False.
//
Function ThereIsFormAlongFullPath(FullFormPath, WriteErrorToVZHR = True)
	
	If Metadata.FindByFullName(FullFormPath) <> Undefined Then
		Return True;
	EndIf;
	
	If WriteErrorToVZHR Then
		EventNameLR = InformationCenterServer.GetEventNameForLog()
			+ "."
			+ NStr("ru = 'Информационные ссылки';
					|en = 'External links';", Common.DefaultLanguageCode());
		
		WriteLogEvent(EventNameLR, EventLogLevel.Error,,,
			NStr("ru = 'При обновлении списка форм, в конфигурации не найдена в форма с полным путем:';
				|en = 'Form with the full path was not found in the configuration when updating the form list:';", 
				Common.DefaultLanguageCode()) + FullFormPath);
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion
