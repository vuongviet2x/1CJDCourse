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

// 1C-supplied add-ins.
// 
// Returns:
//  Array - IDs of 1C-supplied add-ins
//
Function SuppliedAddIns() Export

	UsedAddIns = UsedAddIns();
	Return UsedAddIns.UnloadColumn("Id");
		
EndFunction

// Add-in presentation for the event log
//
Function AddInPresentation(Id, Version) Export

	If ValueIsFilled(Version) Then
		AddInPresentation = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 (версии %2)';
																								|en = '%1(version %2)';"), Id, Version);
	Else
		AddInPresentation = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 (последней версии)';
																								|en = '%1 (latest version)';"), Id);
	EndIf;

	Return AddInPresentation;

EndFunction

// Checks whether the add-ins import from the portal is allowed.
//
// Returns:
//  Boolean - flag of availability.
//
Function CanImportFromPortal() Export

	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		ModuleGetAddIns = Common.CommonModule("GetAddIns");
		Return ModuleGetAddIns.LoadingExternalComponentsIsAvailable();
	EndIf;

	Return False;

EndFunction

// Returns information about an add-in from its file.
//
// Parameters:
//  BinaryData - BinaryData - add-in binary data.
//  ParseInfoFile - Boolean - whether INFO.XML file data is required
//          to analyze additionally.
//  AdditionalInformationSearchParameters - See AddInsClient.ImportParameters.
//
// Returns:
//  Structure:
//      * Disassembled - Boolean - True if information about an add-in is successfully extracted.
//      * Attributes - See AddInAttributes
//      * BinaryData - BinaryData - add-in file export.
//      * AdditionalInformation - Map - information received by passed search parameters.
//      * ErrorDescription - String - an error text if Disassembled = False.
//      * ErrorInfo - ErrorInfo, Undefined - In case of exception if Disassembled = False.
//      * IsFileOfService - Boolean - Flag indicating whether the add-in file was downloaded from the 1C:ITS Portal interactively.
//
Function InformationOnAddInFromFile(BinaryData, ParseInfoFile = True,
	Val AdditionalInformationSearchParameters = Undefined) Export

	Result = New Structure;
	Result.Insert("Disassembled", False);
	Result.Insert("Attributes", New Structure);
	Result.Insert("BinaryData", Undefined);
	Result.Insert("AdditionalInformation", New Map);
	Result.Insert("ErrorDescription", "");
	Result.Insert("ErrorInfo", Undefined);
	Result.Insert("IsFileOfService", False);
	
	Attributes = AddInAttributes();
	If AdditionalInformationSearchParameters = Undefined Then
		AdditionalInformationSearchParameters = New Map;
	EndIf;
	AdditionalInformation = New Map;
	ManifestIsFound = False;

	Try
		Stream = BinaryData.OpenStreamForRead();
		ReadingArchive = New ZipFileReader(Stream);
	Except
		Result.ErrorDescription = NStr("ru = 'В файле отсутствует информация о компоненте.';
										|en = 'Add-in information is missing in the file.';");
		Return Result;
	EndTry;

	TempDirectory = FileSystem.CreateTemporaryDirectory("ExtComp");
	For Each ArchiveItem In ReadingArchive.Items Do

		If ArchiveItem.Encrypted Then

			// Clear temporary files and memory.
			FileSystem.DeleteTemporaryDirectory(TempDirectory);
			ReadingArchive.Close();
			Stream.Close();

			Result.ErrorDescription = NStr("ru = 'ZIP-архив не должен быть зашифрован.';
											|en = 'ZIP archive must not be encrypted.';");
			Return Result;

		EndIf;

		Try
			
			OriginalFullName = Lower(ArchiveItem.OriginalFullName);

			If OriginalFullName = "external-components.json" Then
				Result.IsFileOfService = True;
				Result.ErrorDescription = NStr("ru = 'Это файл для загрузки компонент с Портала 1С:ИТС.';
												|en = 'This is a file to import add-ins from 1C:ITS Portal.';");
				Return Result;
			EndIf;
			
			// Manifest search and parsing.
			If OriginalFullName = "manifest.xml" Then

				Attributes.VersionDate = ArchiveItem.Modified;

				ReadingArchive.Extract(ArchiveItem, TempDirectory);
				ManifestXMLFile = TempDirectory + GetPathSeparator() + ArchiveItem.FullName;
				FillAttributesByManifestXML(ManifestXMLFile, Attributes.TargetPlatforms);

				ManifestIsFound = True;

			EndIf;

			If OriginalFullName = "info.xml" And ParseInfoFile Then

				ReadingArchive.Extract(ArchiveItem, TempDirectory);
				InfoXMLFile = TempDirectory + GetPathSeparator() + ArchiveItem.FullName;
				FillAttributesByInfoXML(InfoXMLFile, Attributes);

			EndIf;

			For Each SearchParameter In AdditionalInformationSearchParameters Do

				XMLFileName = SearchParameter.Value.XMLFileName;

				If OriginalFullName = Lower(XMLFileName) Then

					AdditionalInformationKey = SearchParameter.Key;
					XPathExpression = SearchParameter.Value.XPathExpression;

					ReadingArchive.Extract(ArchiveItem, TempDirectory);
					ManifestXMLFile = TempDirectory + GetPathSeparator() + ArchiveItem.FullName;

					DOMDocument = DOMDocument(ManifestXMLFile);
					XPathValue = EvaluateXPathExpression(XPathExpression, DOMDocument);

					AdditionalInformation.Insert(AdditionalInformationKey, XPathValue);

				EndIf;

			EndDo;

		Except
			Result.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Некорректный файл %1';
					|en = 'Incorrect file %1';"), ArchiveItem.OriginalFullName);
			Result.ErrorInfo = ErrorInfo();
			Return Result;
		EndTry;
	EndDo;

	// Clear temporary files and memory.
	FileSystem.DeleteTemporaryDirectory(TempDirectory);
	ReadingArchive.Close();
	Stream.Close();

	// Add-in compatibility control.
	If Not ManifestIsFound Then
		ErrorText = NStr("ru = 'В архиве компоненты отсутствует обязательный файл MANIFEST.XML.';
							|en = 'The required file MANIFEST.XML is missing from the archive.';");

		Result.ErrorDescription = ErrorText;
		Return Result;
	EndIf;

	Result.Disassembled = True;
	Result.Attributes = Attributes;
	Result.BinaryData = BinaryData;
	Result.AdditionalInformation = AdditionalInformation;

	Return Result;

EndFunction

Procedure CheckTheLocationOfTheComponent(Id, Location) Export

	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.AddInsSaaS") Then
		ModuleAddInsSaaSInternal = Common.CommonModule("AddInsSaaSInternal");
		If ModuleAddInsSaaSInternal.IsComponentFromStorage(Location) Then
			Return;
		EndIf;
	EndIf;

	// In the SaaS mode, it's unsafe to attach add-ins on the 1C:Enterprise server from the "Add-ins" catalog. 
	// It's acceptable to attach add-ins only from the "Common add-ins" catalog.
	If Not (Common.DataSeparationEnabled()
			And Common.SeparatedDataUsageAvailable()) Then
		If Not StrStartsWith(Location, "e1cib/data/Catalog.AddIns.AddInStorage") Then
			If Common.SubsystemExists("StandardSubsystems.SaaSOperations.AddInsSaaS") Then
				ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не удалось подключить компоненту ""%1"" по причине:
					|Доступ запрещен. Обратитесь к администратору сервиса, чтобы разместить внешнюю компоненту в справочник ""Общие внешние компоненты"".';
					|en = 'Cannot attach the %1 add-in due to:
					|Access forbidden. Contact the service administrator to place the add-in in the ""Common add-ins"" catalog.';"), Id);
			Else
				ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не удалось подключить компоненту ""%1"" по причине:
					|Доступ запрещен.';
					|en = 'Cannot attach the %1 add-in due to:
					|Access forbidden.';"), Id);
				EndIf;
			Raise ExceptionText;
		EndIf;
	EndIf;

	If StrStartsWith(Location, "e1cib/data/Catalog.AddIns.AddInStorage") Then
		Return;
	EndIf;

	Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не удалось подключить компоненту ""%1"" по причине:
		|Недопустимое местоположение компоненты ""%2"".';
		|en = 'Cannot attach the %1 add-in due to:
		|Invalid %2 add-in location.';"), Id, Location);

EndProcedure

Function TemplateAddInCompatibilityError(Location) Export
	
	AddInInfo = TemplateAddInInfo(Location);
		 
	If AddInInfo <> Undefined 
		And Not OperatingSystemSupportedByAddInn(AddInInfo.Attributes.TargetPlatforms) Then
		Return CompatibilityErrorDetails();
	EndIf;
	
	Return "";
	
EndFunction

// Import parameters.
// 
// Returns:
//  Structure:
//   * Id - String
//   * Description - String
//   * Version - String
//   * FileName - String
//   * ErrorDescription - String - information about add-in import
//   * UpdateFrom1CITSPortal - Boolean
//   * Data - String - binary data address to temporary storage 
//          - BinaryData
//
Function ImportParameters() Export
	
	Result = New Structure;
	Result.Insert("Id", "");
	Result.Insert("Description", "");
	Result.Insert("Version", "");
	Result.Insert("FileName", "");
	Result.Insert("ErrorDescription", "");
	Result.Insert("UpdateFrom1CITSPortal", True);
	Result.Insert("Data", "");
	
	Return Result;
	
EndFunction

// Adds a binary data add-in to a catalog.
// 
// Parameters:
//  Parameters - See ImportParameters
//  ParseInfoFile - Boolean - whether INFO.XML file data is required
//          to analyze additionally
//  UsedAddIns - See UsedAddIns
//
Procedure LoadAComponentFromBinaryData(Parameters, ParseInfoFile = True, UsedAddIns = Undefined) Export
	
	If TypeOf(Parameters.Data) = Type("String") Then
		If IsBlankString(Parameters.Data) Then
			ExceptionText = NStr("ru = 'Не заполнены данные.';
									|en = 'Data is not filled in.';");
			Raise ExceptionText;
		Else
			If IsTempStorageURL(Parameters.Data) Then
				BinaryData = GetFromTempStorage(Parameters.Data);
			Else
				Raise NStr("ru = 'Адрес данных не является адресом временного хранилища.';
										|en = 'The data address is not a temporary storage address.';");
			EndIf;
		EndIf;
	Else
		BinaryData = Parameters.Data;
	EndIf;
	
	If TypeOf(BinaryData) <> Type("BinaryData") Then
		ExceptionText =  NStr("ru = 'Данные файла не являются двоичными данными.';
								|en = 'The file data is not binary data.';");
		Raise ExceptionText;
	EndIf;
	
	Information = InformationOnAddInFromFile(BinaryData, ParseInfoFile);

	If Not Information.Disassembled Then
		
		ExceptionText = Information.ErrorDescription + ?(Information.ErrorInfo = Undefined, "",
			 ": " + ErrorProcessing.BriefErrorDescription(Information.ErrorInfo));
		
		WriteLogEvent(NStr("ru = 'Добавление внешней компоненты';
										|en = 'Add add-in';", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , ExceptionText);
		Raise ExceptionText;
	EndIf;
	
	Id = ?(ValueIsFilled(Parameters.Id), Parameters.Id, Information.Attributes.Id);
	
	If Not ValueIsFilled(Id) Then
		ExceptionText = NStr("ru = 'Не указан идентификатор, необходимо ввести его вручную.';
								|en = 'Enter the ID.';");
		Raise ExceptionText;
	EndIf;
	
	BeginTransaction();
	Try

		Block = New DataLock;
		Block.Add("Catalog.AddIns");
		Block.Lock();

		Component = Catalogs.AddIns.FindByID(Id);

		If ValueIsFilled(Component) Then
			Object = Component.GetObject();
			Try
				TheResultOfComparingVersions = CommonClientServer.CompareVersions(Object.Version, Parameters.Version);
			Except
				// Overwrite the add-in if version comparison has failed.
				TheResultOfComparingVersions = -1;
			EndTry;
			If TheResultOfComparingVersions >= 0 Then
				RollbackTransaction();
				Return;
			EndIf;
		Else
			Object = Catalogs.AddIns.CreateItem();
			// Create an add-in instance.
			Object.Fill(Undefined); // Default constructor.
		EndIf;
		
		 // According to manifest data.
		FillPropertyValues(Object, Information.Attributes, , "Description, Version, FileName");
		
		Object.Id = Id;
		// If parameters Description, Version, and FileName are not assigned values, get the values from the information records.
		Object.Description = ?(ValueIsFilled(Parameters.Description), Parameters.Description, Information.Attributes.Description);
		Object.Version = ?(ValueIsFilled(Parameters.Version), Parameters.Version, Information.Attributes.Version);
		Object.FileName = ?(ValueIsFilled(Parameters.FileName), Parameters.FileName, Information.Attributes.FileName);
		Object.ErrorDescription = Parameters.ErrorDescription;
		Object.UpdateFrom1CITSPortal = Parameters.UpdateFrom1CITSPortal;
		Object.TargetPlatforms = New ValueStorage(Information.Attributes.TargetPlatforms);
		
		If UsedAddIns <> Undefined Then
			RowOfAddIn = UsedAddIns.Find(Id, "Id");
			If RowOfAddIn <> Undefined Then
				Object.UpdateFrom1CITSPortal = RowOfAddIn.AutoUpdate;
			EndIf;
		EndIf;
		
		Object.AdditionalProperties.Insert("ComponentBinaryData", Information.BinaryData);
		
		Object.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(NStr("ru = 'Добавление внешней компоненты';
										|en = 'Add add-in';", Common.DefaultLanguageCode()), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure


#Region ConfigurationSubsystemsEventHandlers

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export

	Objects.Insert(Metadata.Catalogs.AddIns.FullName(), "AttributesToEditInBatchProcessing");

EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
Procedure OnFillTypesExcludedFromExportImport(Types) Export

	ModuleExportImportData = Common.CommonModule("ExportImportData");
	ModuleExportImportData.AddTypeExcludedFromUploadingUploads(Types,
		Metadata.Catalogs.AddIns,
		ModuleExportImportData.ActionWithClearLinks());

EndProcedure

// 
Procedure OnSendDataToMaster(DataElement, ItemSend,
		Recipient) Export

	If TypeOf(DataElement) = Type("CatalogObject.AddIns") Then
		ItemSend = DataItemSend.Ignore;
	EndIf;

EndProcedure

// See StandardSubsystemsServer.OnSendDataToSlave.
Procedure OnSendDataToSlave(DataElement, ItemSend,
		InitialImageCreating, Recipient) Export

	If TypeOf(DataElement) = Type("CatalogObject.AddIns") Then
		ItemSend = DataItemSend.Ignore;
	EndIf;

EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromMaster.
Procedure OnReceiveDataFromMaster(DataElement, ItemReceive,
		SendBack, Sender) Export

	If TypeOf(DataElement) = Type("CatalogObject.AddIns") Then
		ItemReceive = DataItemReceive.Ignore;
	EndIf;

EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromSlave.
Procedure OnReceiveDataFromSlave(DataElement, ItemReceive,
		SendBack, Sender) Export

	If TypeOf(DataElement) = Type("CatalogObject.AddIns") Then
		ItemReceive = DataItemReceive.Ignore;
	EndIf;

EndProcedure

// See CommonOverridable.OnAddServerNotifications
Procedure OnAddServerNotifications(Notifications) Export
	
	Notification = ServerNotifications.NewServerNotification(
		"StandardSubsystems.AddIns");
	
	Notification.NotificationSendModuleName  = "AddInsInternal";
	Notification.NotificationReceiptModuleName = "AddInsInternalClient";
	
	Notifications.Insert(Notification.Name, Notification);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// ToDoList subsystem event handlers.

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Users.IsExternalUserSession() Or Not Users.IsFullUser() Then
		Return;
	EndIf;

	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.Catalogs.AddIns.FullName());

	UnusedAddInsCount = UnusedAddInsCount();
	For Each Section In Sections Do
		ToDoItem = ToDoList.Add ();
		ToDoItem.Id  = "DeleteUnusedAddIns";
		ToDoItem.HasToDoItems       = UnusedAddInsCount > 0;
		ToDoItem.Presentation  = NStr("ru = 'Удалить неиспользуемые компоненты';
									|en = 'Delete unused add-ins';");
		ToDoItem.Count     = UnusedAddInsCount;
		ToDoItem.Important         = False;
		ToDoItem.Form          = "Catalog.AddIns.ListForm";
		ToDoItem.FormParameters = New Structure("UseFilter", 3);
		ToDoItem.Owner       = Section;
	EndDo;

EndProcedure

#EndRegion

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.10.107";
	Handler.Id = New UUID("25e8efe8-37d5-47b4-a3c6-7e5277161b95");
	Handler.Procedure = "Catalogs.AddIns.ProcessDataForMigrationToNewVersion";
	Handler.InitialFilling = True;
	Handler.Comment = NStr("ru = 'Заполнение реквизитов совместимости компонент и добавление стандартных компонент в справочник Внешние компоненты.';
									|en = 'Fill in the add-in compatibility attributes and add standard add-ins to the Add-ins catalog.';");
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs.AddIns.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead      = "Catalog.AddIns";
	Handler.ObjectsToChange    = "Catalog.AddIns";
	
EndProcedure

#EndRegion

#Region Private

// Add-ins used in the configuration.
// 
// Returns:
//  ValueTable:
//   * Id - String
//   * AutoUpdate - Boolean 
//
Function UsedAddIns() Export
	
	UsedAddIns = New ValueTable;
	UsedAddIns.Columns.Add("Id",          Common.StringTypeDetails(50));
	UsedAddIns.Columns.Add("AutoUpdate", New TypeDescription("Boolean"));
	
	SSLSubsystemsIntegration.OnDefineUsedAddIns(UsedAddIns);
	
	Return UsedAddIns;
	
EndFunction

// Checks whether add-ins can be imported from the portal interactively.
//
// Returns:
//  Boolean - flag of availability.
//
Function CanImportFromPortalInteractively() Export

	If Common.SubsystemExists("OnlineUserSupport") 
		And Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		ModuleOnlineUserSupportClientServer = Common.CommonModule("OnlineUserSupportClientServer");
		If CommonClientServer.CompareVersions(
			ModuleOnlineUserSupportClientServer.LibraryVersion(), "2.7.2.0") >= 0 Then
			ModuleGetAddIns = Common.CommonModule("GetAddIns");
			Return ModuleGetAddIns.LoadingExternalComponentsIsAvailable();
		EndIf;
	EndIf;

	Return False;

EndFunction

// Returns a table of add-in details.
//
// Parameters:
//  Variant - String - Valid values::
//    ForUpdate - Add-ins from a catalog with the UpdateFrom1CITSPortal flag set.
//    ForImport - Add-ins used in the configuration.
//
// Returns:
//   ValueTable:
//    * Id - String
//    * Version - String
//    * Description - String
//    * VersionDate - Date
//    * AutoUpdate - Boolean
//
Function AddInsData(Variant = "ForUpdate") Export
	
	Query = New Query;
	
	If Variant = "ForUpdate" Then
		Query.Text = 
			"SELECT
			|	AddIns.Id AS Id,
			|	AddIns.Version AS Version,
			|	AddIns.Description AS Description,
			|	AddIns.VersionDate AS VersionDate,
			|	AddIns.UpdateFrom1CITSPortal AS AutoUpdate
			|FROM
			|	Catalog.AddIns AS AddIns
			|WHERE
			|	AddIns.UpdateFrom1CITSPortal";
			
	ElsIf Variant = "ForImport" Then
		
		Query.Text =
			"SELECT
			|	UsedAddIns.Id,
			|	UsedAddIns.AutoUpdate
			|INTO UsedAddIns
			|FROM
			|	&UsedAddIns AS UsedAddIns
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ISNULL(AddIns.Id, UsedAddIns.Id) AS Id,
			|	ISNULL(AddIns.Version, """") AS Version,
			|	ISNULL(AddIns.Description, """") AS Description,
			|	ISNULL(AddIns.VersionDate, DATETIME(1, 1, 1)) AS VersionDate,
			|	ISNULL(AddIns.UpdateFrom1CITSPortal, UsedAddIns.AutoUpdate) AS
			|		AutoUpdate
			|FROM
			|	Catalog.AddIns AS AddIns
			|		FULL JOIN UsedAddIns AS UsedAddIns
			|		ON AddIns.Id = UsedAddIns.Id";
			
			Query.SetParameter("UsedAddIns", UsedAddIns());
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неизвестный параметр ""%1"" в ""%2"".';
				|en = 'Unknown parameter %1 in %2.';"), Variant,
			"AddInsInternal.AddInsData");
	EndIf;
	
	QueryResult = Query.Execute();
	AddInsDetails = QueryResult.Unload();
	
	Return AddInsDetails;

EndFunction

Procedure DeleteUnusedAddIns() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AddIns.Ref AS Ref
	|FROM
	|	Catalog.AddIns AS AddIns
	|WHERE
	|	NOT AddIns.DeletionMark
	|	AND NOT AddIns.Id IN (&IDs)";

	Query.SetParameter("IDs", SuppliedAddIns());

	Selection = Query.Execute().Select();
	While Selection.Next() Do

		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add("Catalog.AddIns");
			LockItem.SetValue("Ref", Selection.Ref);
			Block.Lock();

			Object = Selection.Ref.GetObject();
			Object.DeletionMark = True;
			Object.Write();
			CommitTransaction();
		Except
			RollbackTransaction();
			WriteLogEvent(NStr("ru = 'Удаление внешней компоненты';
											|en = 'Delete the add-in';", Common.DefaultLanguageCode()),
				EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(
				ErrorInfo()));
			Raise;
		EndTry;
		
	EndDo;
	
	NotifyAllSessionsAboutAddInChange();
	
EndProcedure

Function UnusedAddInsCount()
	
	UnusedAddInsCount = 0;
	
	Query = New Query;
	Query.Text = 
			"SELECT
			|	COUNT(AddIns.Ref) AS UnusedAddInsCount
			|FROM
			|	Catalog.AddIns AS AddIns
			|WHERE
			|	NOT AddIns.DeletionMark
			|	AND NOT AddIns.Id IN (&IDs)";
	
	Query.SetParameter("IDs", SuppliedAddIns());
		
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Return Selection.UnusedAddInsCount;
	EndDo;
	
	Return UnusedAddInsCount;
	
EndFunction

Procedure NotifyAllSessionsAboutAddInChange() Export
	
	ServerNotifications.SendServerNotification(
		"StandardSubsystems.AddIns", "", Undefined, True);
	
EndProcedure

// See StandardSubsystemsServer.OnSendServerNotification
Procedure OnSendServerNotification(NameOfAlert, ParametersVariants) Export
	
	If NameOfAlert <> "StandardSubsystems.AddIns" Then
		Return;
	EndIf;
	
	ParameterName = "StandardSubsystems.AddIns.Versions";
	PreviousValue2 = StandardSubsystemsServer.ExtensionParameter(ParameterName, True);
	NewValue = AddInsVersionsChecksum();
	
	If PreviousValue2 = NewValue Then
		Return;
	EndIf;
	
	ServerNotifications.SendServerNotification(NameOfAlert, "", Undefined);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ExtensionVersionParameters");
	LockItem.SetValue("ExtensionsVersion", Catalogs.ExtensionsVersions.EmptyRef());
	LockItem.SetValue("ParameterName", ParameterName);
	
	BeginTransaction();
	Try
		Block.Lock();
		PreviousValue2 = StandardSubsystemsServer.ExtensionParameter(ParameterName, True);
		If PreviousValue2 <> NewValue Then
			StandardSubsystemsServer.SetExtensionParameter(ParameterName, NewValue, True);
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Function AddInsVersionsChecksum()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AddIns.Ref AS Ref,
	|	AddIns.DataVersion AS DataVersion
	|FROM
	|	Catalog.AddIns AS AddIns";
	
	Selection = Query.Execute().Select();
	
	VersionsList = New ValueList;
	AddAddInVersions(VersionsList, Selection);
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.AddInsSaaS") Then
		ModuleAddInsSaaSInternal = Common.CommonModule("AddInsSaaSInternal");
		Selection = ModuleAddInsSaaSInternal.SharedAddInVersions();
		AddAddInVersions(VersionsList, Selection);
	EndIf;
	
	VersionsList.SortByValue();
	Versions = StrConcat(VersionsList.UnloadValues(), Chars.LF);
	Hashing = New DataHashing(HashFunction.SHA256);
	Hashing.Append(Versions);
	StringHashSum = Base64String(Hashing.HashSum);
	
	Return StringHashSum;
	
EndFunction

// Parameters:
//  VersionsList - ValueList
//  Selection - DataSelection:
//   * Ref - CatalogRef
//   * DataVersion - String
//
Procedure AddAddInVersions(VersionsList, Selection)
	
	While Selection.Next() Do
		VersionsList.Add(Lower(Selection.Ref.UUID())
			+ " " + Selection.DataVersion);
	EndDo;
	
EndProcedure

// Checks whether an add-in from the add-in storage 
// based on Native API or COM technologies can be attached on 1C:Enterprise server.
//
// Parameters:
//   Id - String - the add-in identification code.
//   Version        - String - an add-in version.
//   ConnectionParameters - See AddInsServer.ConnectionParameters.
//
// Returns:
//   String - brief error message. 
//
Function CheckAddInAttachmentAbility(Val Id,
		Val Version = Undefined,
		Val ConnectionParameters = Undefined) Export

	If ConnectionParameters = Undefined Then
		ConnectionParameters = AddInsServer.ConnectionParameters();
	EndIf;

	If IsBlankString(Id) Then
		AddInContainsOneObjectClass = (ConnectionParameters.ObjectsCreationIDs.Count() = 0);
		If AddInContainsOneObjectClass Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Недопустимо одновременно не указывать %1 и %2 при подключении внешней компоненты.';
					|en = 'When attaching an external add-in, ""%1"" and ""%2"" cannot be empty at the same time.';"),
				"Id", "ObjectsCreationIDs");
		EndIf;
		Id = StrConcat(ConnectionParameters.ObjectsCreationIDs, ", ");
	EndIf;

	Result = New Structure;
	Result.Insert("Location", "");
	Result.Insert("Id", Id);
	Result.Insert("ErrorDescription", "");
	Result.Insert("Version", "");

	Information = AddInsInternalServerCall.SavedAddInInformation(Id, Version, ConnectionParameters.FullTemplateName);
	Result.Insert("Version", Version);
	If Information.State = "DisabledByAdministrator" Then
		Result.ErrorDescription = NStr("ru = 'Компонента отключена администратором.';
										|en = 'The add-in is disabled by the administrator.';");
		Return Result;
	ElsIf Information.State = "NotFound1" Then
		Result.ErrorDescription = NStr("ru = 'Компонента отсутствует в списке разрешенных внешних компонент.';
										|en = 'The add-in is missing from the list of allowed add-ins.';");
		Return Result;
	ElsIf Information.IsTargetPlatformsFilled And Not OperatingSystemSupportedByAddInn(Information.Attributes.TargetPlatforms) Then
		Result.ErrorDescription = CompatibilityErrorDetails();
		Return Result;
	EndIf;
	
	CheckTheLocationOfTheComponent(Id, Information.Location);
	Result.Location = Information.Location;
	Return Result;

EndFunction

Function CompatibilityErrorDetails()
	
	SystemInfo = New SystemInfo;
	NameOfThePlatformType = CommonClientServer.NameOfThePlatformType(SystemInfo.PlatformType);
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не предусмотрена работа компоненты в операционной системе %1';
			|en = 'The add-in does not work in the %1 operating system.';"), NameOfThePlatformType);
	
EndFunction

Function TemplateAddInInfo(Location) Export
	
	If Not Common.TemplateExists(Location) Then
		Return Undefined;
	EndIf;
	
	LayoutLocationSplit = StrSplit(Location, ".");
	TemplateName = LayoutLocationSplit.Get(LayoutLocationSplit.UBound());
	
	If LayoutLocationSplit.Count() = 2 Then
		ComponentBinaryData = GetCommonTemplate(TemplateName);
	Else
		LayoutLocationSplit.Delete(LayoutLocationSplit.UBound());
		LayoutLocationSplit.Delete(LayoutLocationSplit.UBound());
		ObjectManagerByFullName =  Common.ObjectManagerByFullName(StrConcat(LayoutLocationSplit, "."));
		ComponentBinaryData = ObjectManagerByFullName.GetTemplate(TemplateName);
	EndIf;
	
	InformationOnAddInFromFile = InformationOnAddInFromFile(ComponentBinaryData);
	
	If Not InformationOnAddInFromFile.Disassembled Then
		Return Undefined;
	EndIf;
	
	Return InformationOnAddInFromFile;
	
EndFunction

#Region SavedAddInInformation

Function OperatingSystemSupportedByAddInn(AddInAttributes)

	SystemInfo = New SystemInfo;
	
	NameOfThePlatformType = CommonClientServer.NameOfThePlatformType(SystemInfo.PlatformType);

	If NameOfThePlatformType = "Linux_x86" Then
		Return AddInAttributes.Linux_x86;
	ElsIf NameOfThePlatformType = "Linux_x86_64" Then
		Return AddInAttributes.Linux_x86_64;
	ElsIf NameOfThePlatformType = "MacOS_x86" Then
		Return AddInAttributes.MacOS_x86;
	ElsIf NameOfThePlatformType = "MacOS_x86_64" Then
		Return AddInAttributes.MacOS_x86_64;
	ElsIf NameOfThePlatformType = "Windows_x86" Then
		Return AddInAttributes.Windows_x86;
	ElsIf NameOfThePlatformType = "Windows_x86_64" Then
		Return AddInAttributes.Windows_x86_64;
	ElsIf NameOfThePlatformType = "Linux_ARM64" Then
		Return AddInAttributes.Linux_ARM64;
	ElsIf NameOfThePlatformType = "Linux_E2K" Then
		Return AddInAttributes.Linux_E2K;
	ElsIf NameOfThePlatformType = "Android_ARM" Then
		Return AddInAttributes.Android_ARM;
	ElsIf NameOfThePlatformType = "Android_ARM_64" Then
		Return AddInAttributes.Android_ARM64;
	ElsIf NameOfThePlatformType = "Android_x86" Then
		Return AddInAttributes.Android_x86;
	ElsIf NameOfThePlatformType = "Android_x86_64" Then
		Return AddInAttributes.Android_x86_64;
	ElsIf NameOfThePlatformType = "iOS_ARM" Then
		Return AddInAttributes.iOS_ARM;
	ElsIf NameOfThePlatformType = "iOS_ARM_64" Then
		Return AddInAttributes.iOS_ARM64;
	ElsIf NameOfThePlatformType = "WinRT_ARM" Then
		Return AddInAttributes.WindowsRT_ARM;
	ElsIf NameOfThePlatformType = "WinRT_x86" Then
		Return AddInAttributes.WindowsRT_x86;
	ElsIf NameOfThePlatformType = "WinRT_x86_64" Then
		Return AddInAttributes.WindowsRT_x86_64;
	EndIf;

	Return False;

EndFunction

Function ImportFromFileIsAvailable()

	Return Users.IsFullUser(, , False);

EndFunction

// Parameters:
//   Id - String               - the add-in identification code.
//   Version        - String
//                 - Undefined - an add-in version.
//   ThePathToTheLayoutToSearchForTheLatestVersion 
//                 - Undefined
//                  -String
//
// Returns:
//  Structure:
//    * CanImportFromPortal - Boolean
//    * ImportFromFileIsAvailable - Boolean
//    * State - String - "NotFound", "FoundInStorage", "FoundInSharedStorage", "DisabledByAdministrator" 
//    * Location - String
//    * Ref - AnyRef
//    * Attributes - See AddInAttributes
//    * IsTargetPlatformsFilled - Boolean
//    * TheLatestVersionOfComponentsFromTheLayout 
//    		- See StandardSubsystemsCached.TheLatestVersionOfComponentsFromTheLayout
//    		- Undefined
//
Function SavedAddInInformation(Id, Version = Undefined, ThePathToTheLayoutToSearchForTheLatestVersion = Undefined) Export

	Result = New Structure;
	Result.Insert("Ref");
	Result.Insert("Attributes", AddInAttributes());
	Result.Insert("Location");
	Result.Insert("State");
	Result.Insert("ImportFromFileIsAvailable", ImportFromFileIsAvailable());
	Result.Insert("CanImportFromPortal", CanImportFromPortal());
	Result.Insert("TheLatestVersionOfComponentsFromTheLayout");
	Result.Insert("IsTargetPlatformsFilled", False);

	If Common.DataSeparationEnabled()
		And Common.SubsystemExists("StandardSubsystems.SaaSOperations.AddInsSaaS") Then
	
		ModuleAddInsSaaSInternal = Common.CommonModule("AddInsSaaSInternal");
		ModuleAddInsSaaSInternal.FillAddInInformation(Result, Version, Id);
	Else	
		ReferenceFromStorage = Catalogs.AddIns.FindByID(Id, Version);
		If ReferenceFromStorage.IsEmpty() Then
			Result.State = "NotFound1";
		Else
			Result.State = "FoundInStorage";
			Result.Ref = ReferenceFromStorage;
		EndIf
	EndIf;
	
	If ThePathToTheLayoutToSearchForTheLatestVersion <> Undefined Then
		Result.TheLatestVersionOfComponentsFromTheLayout = StandardSubsystemsCached.TheLatestVersionOfComponentsFromTheLayout(
			ThePathToTheLayoutToSearchForTheLatestVersion);
	EndIf;

	If Result.State = "NotFound1" Then
		Return Result;
	EndIf;

	Attributes = AddInAttributes();
	If Result.State = "FoundInStorage" Then
		Attributes.Insert("Use");
	EndIf;
	If Result.State = "FoundInSharedStorage" Then
		Attributes.Delete("FileName");
	EndIf;
	Attributes.TargetPlatforms = Undefined;
	
	ObjectAttributes = Common.ObjectAttributesValues(Result.Ref, Attributes);
	
	ObjectAttributes.TargetPlatforms = ObjectAttributes.TargetPlatforms.Get();
	If ObjectAttributes.TargetPlatforms = Undefined Then
		
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не заполнена информация о совместимости компоненты %1.';
				|en = 'Compatibility information for the %1 add-in is not filled in.';"), Id);
		WriteLogEvent(NStr("ru = 'Проверка совместимости компоненты';
										|en = 'Add-in compatibility check';",
			Common.DefaultLanguageCode()), EventLogLevel.Warning, , Result.Ref, WarningText);
		
		ObjectAttributes.TargetPlatforms = TargetPlatforms();
	Else
		Result.IsTargetPlatformsFilled = True;
	EndIf;

	FillPropertyValues(Result.Attributes, ObjectAttributes);
	Result.Location = GetURL(Result.Ref, "AddInStorage");

	If Result.State = "FoundInStorage" Then
		If ObjectAttributes.Use <> Enums.AddInUsageOptions.Used Then
			Result.State = "DisabledByAdministrator";
		EndIf;
	EndIf;
	
	Return Result;

EndFunction

// Returns:
//  Structure:
//    * TargetPlatforms - See TargetPlatforms
//    * Id - String
//    * Description - String
//    * Version - String
//    * VersionDate - Date
//    * FileName - String
//
Function AddInAttributes()

	Attributes = New Structure;
	Attributes.Insert("Id");
	Attributes.Insert("Description");
	Attributes.Insert("Version");
	Attributes.Insert("VersionDate");
	Attributes.Insert("FileName");
	Attributes.Insert("TargetPlatforms", TargetPlatforms());

	Return Attributes;

EndFunction

// Returns:
//  Structure:
//    * Windows_x86 - Boolean
//    * Windows_x86_64 - Boolean
//    * Linux_x86 - Boolean
//    * Linux_x86_64 - Boolean
//    * Windows_x86_Firefox - Boolean
//    * Linux_x86_Firefox - Boolean
//    * Linux_x86_64_Firefox - Boolean
//    * Windows_x86_MSIE - Boolean
//    * Windows_x86_64_MSIE - Boolean
//    * Windows_x86_Chrome - Boolean
//    * Linux_x86_Chrome - Boolean
//    * Linux_x86_64_Chrome - Boolean
//    * MacOS_x86_64_Safari - Boolean
//    * MacOS_x86_64_Chrome - Boolean
//    * MacOS_x86_64_Firefox - Boolean
//    * Windows_x86_YandexBrowser - Boolean
//    * Windows_x86_64_YandexBrowser - Boolean
//    * Linux_x86_YandexBrowser - Boolean
//    * Linux_x86_64_YandexBrowser - Boolean
//    * MacOS_x86_64_YandexBrowser - Boolean
//    * Linux_E2K - Boolean
//    * Linux_E2K_Firefox - Boolean
//    * Linux_E2K_YandexBrowser - Boolean
//    * Linux_E2K_Chrome - Boolean
//    * Linux_ARM64 - Boolean
//    * iOS_ARM - Boolean
//    * iOS_ARM64 - Boolean
//    * Android_ARM - Boolean
//    * Android_x86_64 - Boolean
//    * Android_x86 - Boolean
//    * Android_ARM64 - Boolean
//    * WindowsRT_ARM - Boolean
//    * WindowsRT_x86 - Boolean
//    * WindowsRT_x86_64 - Boolean
//
Function TargetPlatforms()

	Attributes = New Structure;
	Attributes.Insert("Windows_x86",                  False);
	Attributes.Insert("Windows_x86_64",               False);
	Attributes.Insert("Linux_x86",                    False);
	Attributes.Insert("Linux_x86_64",                 False);
	Attributes.Insert("Windows_x86_Firefox",          False);
	Attributes.Insert("Linux_x86_Firefox",            False);
	Attributes.Insert("Linux_x86_64_Firefox",         False);
	Attributes.Insert("Windows_x86_MSIE",             False);
	Attributes.Insert("Windows_x86_64_MSIE",          False);
	Attributes.Insert("Windows_x86_Chrome",           False);
	Attributes.Insert("Linux_x86_Chrome",             False);
	Attributes.Insert("Linux_x86_64_Chrome",          False);
	Attributes.Insert("MacOS_x86_64",                 False);
	Attributes.Insert("MacOS_x86_64_Safari",          False);
	Attributes.Insert("MacOS_x86_64_Chrome",          False);
	Attributes.Insert("MacOS_x86_64_Firefox",         False);
	Attributes.Insert("Windows_x86_YandexBrowser",    False);
	Attributes.Insert("Windows_x86_64_YandexBrowser", False);
	Attributes.Insert("Linux_x86_YandexBrowser",      False);
	Attributes.Insert("Linux_x86_64_YandexBrowser",   False);
	Attributes.Insert("MacOS_x86_64_YandexBrowser",   False);
	Attributes.Insert("Linux_E2K",                    False);
	Attributes.Insert("Linux_E2K_Firefox",            False);
	Attributes.Insert("Linux_E2K_YandexBrowser",      False);
	Attributes.Insert("Linux_E2K_Chrome",             False);
	Attributes.Insert("Linux_ARM64",                  False);
	Attributes.Insert("Linux_ARM64_Firefox",          False);
	Attributes.Insert("Linux_ARM64_YandexBrowser",    False);
	Attributes.Insert("Linux_ARM64_Chrome",           False);
	Attributes.Insert("iOS_ARM",                      False);
	Attributes.Insert("iOS_ARM64",                    False);
	Attributes.Insert("Android_ARM",                  False);
	Attributes.Insert("Android_x86_64",               False);
	Attributes.Insert("Android_x86",                  False);
	Attributes.Insert("Android_ARM64",                False);
	Attributes.Insert("WindowsRT_ARM",                False);
	Attributes.Insert("WindowsRT_x86",                False);
	Attributes.Insert("WindowsRT_x86_64",             False);
	
	Return Attributes;

EndFunction

#EndRegion

#Region GetInformationFromComponentFile

Procedure FillAttributesByManifestXML(ManifestXMLFileName, Attributes)

	XMLReader = New XMLReader;
	XMLReader.OpenFile(ManifestXMLFileName);

	XMLReader.MoveToContent();
	If XMLReader.Name = "bundle" And XMLReader.NodeType = XMLNodeType.StartElement Then
		While XMLReader.Read() Do
			If XMLReader.Name = "component" And XMLReader.NodeType = XMLNodeType.StartElement Then

				OperatingSystem = Lower(XMLReader.AttributeValue("os"));
				ComponentType = Lower(XMLReader.AttributeValue("type"));
				PlatformArchitecture = Lower(XMLReader.AttributeValue("arch"));
				Viewer = Lower(XMLReader.AttributeValue("client"));

				If OperatingSystem = "windows" And (ComponentType = "native" Or ComponentType = "com") Then

					If PlatformArchitecture = "i386" Then
						Attributes.Windows_x86 = True;
						Continue;
					EndIf;

					If PlatformArchitecture = "x86_64" Then
						Attributes.Windows_x86_64 = True;
						Continue;
					EndIf;
					
					Continue;
				EndIf;
				
				If OperatingSystem = "linux" And ComponentType = "native" Then
				
					If PlatformArchitecture = "i386" Then
						Attributes.Linux_x86 = True;
						Continue;
					EndIf;
	
					If PlatformArchitecture = "x86_64" Then
						Attributes.Linux_x86_64 = True;
						Continue;
					EndIf;
					
					If PlatformArchitecture = "arm64" Then
						Attributes.Linux_ARM64 = True;
						Continue;
					EndIf;
					
					If PlatformArchitecture = "e2k" Then
						Attributes.Linux_E2K = True;
						Continue;
					EndIf;
					
					Continue;
				EndIf;
				
				If OperatingSystem = "macos" And ComponentType = "native" And (PlatformArchitecture = "x86_64"
						Or PlatformArchitecture = "universal") Then
					Attributes.MacOS_x86_64 = True;
					Continue;
				EndIf;
				
				If OperatingSystem = "windowsruntime" Then

					If PlatformArchitecture = "arm" Then
						Attributes.WindowsRT_ARM = True;
					ElsIf PlatformArchitecture = "x86_64" Then
						Attributes.WindowsRT_x86_64 = True;
					ElsIf PlatformArchitecture = "x86" Then
						Attributes.WindowsRT_x86 = True;
					EndIf;
					
					Continue;
					
				EndIf;
				
				If OperatingSystem = "android" Then

					If PlatformArchitecture = "arm" Then
						Attributes.Android_ARM = True;
					ElsIf PlatformArchitecture = "arm64" Then
						Attributes.Android_ARM64 = True;
					ElsIf PlatformArchitecture = "x86_64" Then
						Attributes.Android_x86_64 = True;
					ElsIf PlatformArchitecture = "i386" Then
						Attributes.Android_x86 = True;
					EndIf;
					
					Continue;
					
				EndIf;
				
				If OperatingSystem = "ios" Then

					If PlatformArchitecture = "arm" Or PlatformArchitecture = "universal" Then
						Attributes.iOS_ARM = True;
					EndIf;
					
					If PlatformArchitecture = "arm64" Or PlatformArchitecture = "universal" Then
						Attributes.iOS_ARM64 = True;
					EndIf;
					
					Continue;
					
				EndIf;
				
				If OperatingSystem = "linux" And ComponentType = "plugin" Then

					If PlatformArchitecture = "i386" And Viewer = "firefox" Then
						Attributes.Linux_x86_Firefox = True;
						Continue;
					EndIf;

					If PlatformArchitecture = "x86_64" And Viewer = "firefox" Then
						Attributes.Linux_x86_64_Firefox = True;
						Continue;
					EndIf;
					
					If PlatformArchitecture = "arm64" And Viewer = "firefox" Then
						Attributes.Linux_ARM64_Firefox = True;
						Continue;
					EndIf;
					
					If PlatformArchitecture = "e2k" And Viewer = "firefox" Then
						Attributes.Linux_E2K_Firefox = True;
						Continue;
					EndIf;
					
					If PlatformArchitecture = "i386" And (Viewer = "yandexbrowser" Or Viewer = "anychromiumbased") Then
						Attributes.Linux_x86_YandexBrowser = True;
					EndIf;
					
					If PlatformArchitecture = "i386" And (Viewer = "chrome" Or Viewer = "anychromiumbased") Then
						Attributes.Linux_x86_Chrome = True;
					EndIf;

					If PlatformArchitecture = "x86_64" And (Viewer = "yandexbrowser" Or Viewer = "anychromiumbased") Then
						Attributes.Linux_x86_64_YandexBrowser = True;
					EndIf;

					If PlatformArchitecture = "x86_64" And (Viewer = "chrome" Or Viewer = "anychromiumbased") Then
						Attributes.Linux_x86_64_Chrome = True;
					EndIf;
					
					If PlatformArchitecture = "arm64" And (Viewer = "yandexbrowser" Or Viewer = "anychromiumbased") Then
						Attributes.Linux_ARM64_YandexBrowser = True;
					EndIf;

					If PlatformArchitecture = "arm64" And (Viewer = "chrome" Or Viewer = "anychromiumbased") Then
						Attributes.Linux_ARM64_Chrome = True;
					EndIf;
					
					If PlatformArchitecture = "e2k" And (Viewer = "yandexbrowser" Or Viewer = "anychromiumbased") Then
						Attributes.Linux_E2K_YandexBrowser = True;
					EndIf;

					If PlatformArchitecture = "e2k" And (Viewer = "chrome" Or Viewer = "anychromiumbased") Then
						Attributes.Linux_E2K_Chrome = True;
					EndIf;
					
					Continue;
				EndIf;
				
				If OperatingSystem = "windows" And ComponentType = "plugin" Then
					
					If PlatformArchitecture = "i386" And Viewer = "msie" Then
						Attributes.Windows_x86_MSIE = True;
						Continue;
					EndIf;
	
					If PlatformArchitecture = "x86_64" And Viewer = "msie" Then
						Attributes.Windows_x86_64_MSIE = True;
						Continue;
					EndIf;
					
					If PlatformArchitecture = "i386" And Viewer = "firefox" Then
						Attributes.Windows_x86_Firefox = True;
						Continue;
					EndIf;
					
					If PlatformArchitecture = "i386" And (Viewer = "chrome" Or Viewer = "anychromiumbased") Then
						Attributes.Windows_x86_Chrome = True;
					EndIf;
					
					If PlatformArchitecture = "i386" And (Viewer = "yandexbrowser" Or Viewer = "anychromiumbased") Then
						Attributes.Windows_x86_YandexBrowser = True;
					EndIf;
					
					If PlatformArchitecture = "x86_64" And (Viewer = "yandexbrowser" Or Viewer = "anychromiumbased") Then
						Attributes.Windows_x86_64_YandexBrowser = True;
					EndIf;
		
					Continue;
					
				EndIf;
				
				If OperatingSystem = "macos" And ComponentType = "plugin" Then

					If  (PlatformArchitecture = "x86_64" Or PlatformArchitecture = "universal") And Viewer = "safari" Then
						Attributes.MacOS_x86_64_Safari = True;
						Continue;
					EndIf;
								
					If (PlatformArchitecture = "x86_64" Or PlatformArchitecture = "universal") And Viewer = "firefox" Then
						Attributes.MacOS_x86_64_Firefox = True;
						Continue;
					EndIf;
					
					If (PlatformArchitecture = "x86_64" Or PlatformArchitecture = "universal") And (Viewer = "chrome" Or Viewer = "anychromiumbased") Then
						Attributes.MacOS_x86_64_Chrome = True;
					EndIf;
					
					If (PlatformArchitecture = "x86_64" Or PlatformArchitecture = "universal") And (Viewer = "yandexbrowser" 
							Or Viewer = "anychromiumbased") Then
						Attributes.MacOS_x86_64_YandexBrowser = True;
					EndIf;
				
					Continue;
					
				EndIf;
				
			EndIf;
		EndDo;
	EndIf;
	XMLReader.Close();

EndProcedure

Procedure FillAttributesByInfoXML(InfoXMLFileName, Attributes)

	FileRead = False;

	// TryingToParseByPLFormat
	XMLReader = New XMLReader;
	XMLReader.OpenFile(InfoXMLFileName);

	XMLReader.MoveToContent();
	If XMLReader.Name = "drivers" And XMLReader.NodeType = XMLNodeType.StartElement Then
		While XMLReader.Read() Do
			If XMLReader.Name = "component" And XMLReader.NodeType = XMLNodeType.StartElement Then

				Id = XMLReader.AttributeValue("progid");
				
				Attributes.Id = Mid(Id, StrFind(Id, ".") + 1);
				Attributes.Description = XMLReader.AttributeValue("name");
				Attributes.Version = XMLReader.AttributeValue("version");

				FileRead = True;

			EndIf;
		EndDo;
	EndIf;
	XMLReader.Close();

	If FileRead Then
		Return;
	EndIf;

	// Trying to parse by EDL format.
	XMLReader = New XMLReader;
	XMLReader.OpenFile(InfoXMLFileName);

	InformationOfAddIn = XDTOFactory.ReadXML(XMLReader);
	Attributes.Id = InformationOfAddIn.progid;
	Attributes.Description = InformationOfAddIn.name;
	Attributes.Version = InformationOfAddIn.version;

	XMLReader.Close();

EndProcedure

Function EvaluateXPathExpression(Expression, DOMDocument)

	XPathValue = Undefined;

	Dereferencer = DOMDocument.CreateNSResolver();
	XPathResult = DOMDocument.EvaluateXPathExpression(Expression, DOMDocument, Dereferencer);

	ResultNode = XPathResult.IterateNext();
	If TypeOf(ResultNode) = Type("DOMAttribute") Then
		XPathValue = ResultNode.Value;
	EndIf;

	Return XPathValue
EndFunction

Function DOMDocument(PathToFile)

	XMLReader = New XMLReader;
	XMLReader.OpenFile(PathToFile);
	DOMBuilder = New DOMBuilder;
	DOMDocument = DOMBuilder.Read(XMLReader);
	XMLReader.Close();

	Return DOMDocument;

EndFunction

#EndRegion

#Region ImportFromPortal

Procedure CheckImportFromPortalAvailability()

	If Not CanImportFromPortal() Then
		Raise NStr("ru = 'Обновление внешних компонент с портала 1С:ИТС не доступно.';
								|en = 'Cannot update add-ins from the 1C:ITS portal.';");
	EndIf;

EndProcedure

// Returns:
//  Structure:
//   * Id - String
//   * Version - String
//   * AutoUpdate - Boolean
//
Function ComponentParametersFromThePortal() Export
	
	Result = New Structure;
	Result.Insert("Id", "");
	Result.Insert("Version", "");
	Result.Insert("AutoUpdate", True);
	Return Result;
	
EndFunction
	
// Parameters:
//  ProcedureParameters - See ComponentParametersFromThePortal.
//  ResultAddress - String
//
Procedure NewAddInsFromPortal(ProcedureParameters, ResultAddress) Export

	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then

		Id = ProcedureParameters.Id;
		Version = ProcedureParameters.Version;

		CheckImportFromPortalAvailability();

		ModuleGetAddIns = Common.CommonModule("GetAddIns");

		AddInsDetails = ModuleGetAddIns.AddInsDetails();
		AddInDetails = AddInsDetails.Add();
		AddInDetails.Id = Id;
		AddInDetails.Version = Version;

		If Not ValueIsFilled(Version) Then
			OperationResult = ModuleGetAddIns.CurrentVersionsOfExternalComponents(AddInsDetails);
		Else
			OperationResult = ModuleGetAddIns.VersionsOfExternalComponents(AddInsDetails);
		EndIf;

		If ValueIsFilled(OperationResult.ErrorCode) Then
			ExceptionText = ?(Users.IsFullUser(), OperationResult.ErrorInfo, OperationResult.ErrorMessage);
			Raise ExceptionText;
		EndIf;

		If OperationResult.AddInsData.Count() = 0 Then
			ExceptionText = NStr("ru = 'На портале 1С:ИТС внешняя компонента отсутствует.';
									|en = 'Add-in is not found on 1C:ITS portal.';");
			WriteLogEvent(NStr("ru = 'Обновление внешних компонент';
											|en = 'Updating add-ins';", Common.DefaultLanguageCode()), EventLogLevel.Error, , , ExceptionText);
			Raise ExceptionText;
		EndIf;

		ResultString1 = OperationResult.AddInsData[0];
		ErrorCode = ResultString1.ErrorCode;

		If ValueIsFilled(ErrorCode) Then

			ErrorInfo = "";
			If ErrorCode = "ComponentNotFound" Then
				ErrorInfo = NStr("ru = 'На портале 1С:ИТС нет требуемой внешней компоненты %1.';
											|en = 'The required add-in %1 is missing from the 1C:ITS portal';");
			ElsIf ErrorCode = "VersionNotFound" Then
				ErrorInfo = NStr("ru = 'На портале 1С:ИТС нет требуемой версии внешней компоненты %1.';
											|en = 'The required version of the %1 add-in is missing from the 1C:ITS portal.';");
			ElsIf ErrorCode = "FileNotImported" Or ErrorCode = "LatestVersion" Then
				ErrorInfo = NStr("ru = 'Не удалось загрузить внешнюю компоненту %1 по непредвиденной причине (код %2).';
											|en = 'Cannot import the %1 add-in due to an unexpected reason (code %2).';");
			EndIf;

			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorInfo, 
				AddInPresentation(Id, Version), ErrorCode);
			WriteLogEvent(NStr("ru = 'Обновление внешних компонент';
											|en = 'Updating add-ins';", Common.DefaultLanguageCode()), 
				EventLogLevel.Error, , , ErrorText);
			Raise ErrorText;
		EndIf;

		BinaryData = GetFromTempStorage(ResultString1.FileAddress);
		Information = InformationOnAddInFromFile(BinaryData, False);

		If Not Information.Disassembled Then
			
			ExceptionText = Information.ErrorDescription + ?(Information.ErrorInfo = Undefined, "",
			 ": " + ErrorProcessing.BriefErrorDescription(Information.ErrorInfo));
				
			WriteLogEvent(NStr("ru = 'Обновление внешних компонент';
											|en = 'Updating add-ins';", Common.DefaultLanguageCode()), 
				EventLogLevel.Error, , , ExceptionText);
			Raise ExceptionText;
		EndIf;

		SetPrivilegedMode(True);

		BeginTransaction();
		Try
			// Create an add-in instance.
			Object = Catalogs.AddIns.CreateItem();
			Object.Fill(Undefined); // Default constructor
			FillPropertyValues(Object, Information.Attributes); // According to manifest data.
			FillPropertyValues(Object, ResultString1); // By data from the website.
			Object.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Загружена с Портала 1С:ИТС. %1.';
					|en = 'Imported from 1C:ITS Portal. %1.';"), CurrentSessionDate());
			Object.TargetPlatforms = New ValueStorage(Information.Attributes.TargetPlatforms);
			Object.AdditionalProperties.Insert("ComponentBinaryData", Information.BinaryData);

			If Not ValueIsFilled(Version) Then // If the specific version is requested, then skip.
				Object.UpdateFrom1CITSPortal = Object.ThisIsTheLatestVersionComponent()
					And ProcedureParameters.AutoUpdate;
			EndIf;

			Object.Write();
			CommitTransaction();
		Except
			RollbackTransaction();
			WriteLogEvent(NStr("ru = 'Обновление внешних компонент';
											|en = 'Updating add-ins';", Common.DefaultLanguageCode()), EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Raise;
		EndTry;
		NotifyAllSessionsAboutAddInChange();
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Действие недоступно, т.к. отсутствует подсистема ""%1"".';
				|en = 'Operation is unavailable. Subsystem ""%1"" is required.';"),
			"OnlineUserSupport.GetAddIns");
	EndIf;

EndProcedure

// Returns:
//   Structure:
//     * AddInsToUpdate - Array of CatalogRef.AddIns 
//  
Function ParametersForUpdatingAComponentFromThePortal() Export
	
	Result = New Structure;
	Result.Insert("AddInsToUpdate", New Array);
	Return Result;
	
EndFunction

// Parameters:
//  ProcedureParameters - See ParametersForUpdatingAComponentFromThePortal
//  ResultAddress - String
//
Procedure UpdateAddInsFromPortal(ProcedureParameters, ResultAddress) Export

	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then

		CheckImportFromPortalAvailability();

		ModuleGetAddIns = Common.CommonModule("GetAddIns");
		AddInsDetails = ModuleGetAddIns.AddInsDetails();

		AddInsToUpdate = ProcedureParameters.AddInsToUpdate;
		Attributes = Common.ObjectsAttributesValues(AddInsToUpdate, "Id, Version");
		For Each AddInToUpdate In AddInsToUpdate Do
			ComponentDetails = AddInsDetails.Add();
			ComponentDetails.Id = Attributes[AddInToUpdate].Id;
			ComponentDetails.Version = Attributes[AddInToUpdate].Version;
		EndDo;

		OperationResult = ModuleGetAddIns.CurrentVersionsOfExternalComponents(AddInsDetails);
		If ValueIsFilled(OperationResult.ErrorCode) Then
			ExceptionText = ?(Users.IsFullUser(), OperationResult.ErrorInfo, OperationResult.ErrorMessage);
			Raise ExceptionText;
		EndIf;

		AddInsServer.UpdateAddIns(OperationResult.AddInsData, ResultAddress);
		NotifyAllSessionsAboutAddInChange();
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Действие недоступно, т.к. отсутствует подсистема ""%1"".';
				|en = 'Operation is unavailable. Subsystem ""%1"" is required.';"),
			"OnlineUserSupport.GetAddIns");
	EndIf;

EndProcedure

#EndRegion

#EndRegion