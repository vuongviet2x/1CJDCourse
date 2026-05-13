////////////////////////////////////////////////////////////////////////////////
// Subsystem "Core SaaS".
// Common server procedures and functions:
// - Support of the SaaS mode.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Generates passed data signature using the passed key with the HMAC-SHA256 algorithm.
//
// Parameters:
//   Var_Key - BinaryData - binary data of a signature key.
//   Data - String - data to be signed.
//
// Returns:
//   String - a signature in the Base64 format.
//
Function Signature(Var_Key, Data) Export
	
	Return Base64String(HMACSHA256(Var_Key, GetBinaryDataFromString(Data)));
	
EndFunction

#EndRegion 

#Region Internal

// Returns HMACSHA-256.
// 
// Parameters: 
//  Var_Key - BinaryData
//  Data - BinaryData
// 
// Returns:
//  BinaryData
Function HMACSHA256(Val Var_Key, Val Data) Export
	
	Return HMAC(Var_Key, Data, HashFunction.SHA256, 64);
	
EndFunction

// Parameters: 
//  Data - Structure
// 
// Returns: 
//  String - Line from a JSON structure.
Function StringFromJSONStructure(Data) Export
	
	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, Data, , "ConvertingJSONValues", SaaSOperationsCTL);
	Return JSONWriter.Close();
	
EndFunction

// Parameters:
// 	String - String - a string in the JSON format.
// 	DateTypeProperties - Array of String - names of properties with the "Date" type.
// 
// Returns:
// 	Arbitrary, Structure - Retrieved structure.:
// 	* Field - Arbitrary - Arbitrary list of fields.
//
Function StructureFromJSONString(String, DateTypeProperties = Undefined) Export
	
	JSONReader = New JSONReader;
	JSONReader.SetString(String);
	Response = ReadJSON(JSONReader,, DateTypeProperties, JSONDateFormat.ISO); 
	Return Response;
	
EndFunction

// Parameters:
// 	DataStream - FileStream, MemoryStream - a data stream.
// 	DateTypeProperties - Array of String - names of properties with the "Date" type.
// 
// Returns:
// 	Arbitrary, Structure - Retrieved structure.:
// 	* Field - Arbitrary - Arbitrary list of fields.
//
Function StructureFromJSONStream(DataStream, DateTypeProperties = Undefined) Export
	
	JSONReader = New JSONReader;
	JSONReader.OpenStream(DataStream);
	Response = ReadJSON(JSONReader, , DateTypeProperties, JSONDateFormat.ISO);
	JSONReader.Close();
	Return Response;
	
EndFunction

// Sends data to the specified address in the Service manager.
//
// Parameters:
//  Method - String - a HTTP method name according to standard RFC7230 (https://tools.ietf.org/html/rfc7230).
//  Address  - String - an address to which data is sent, for example, "hs/ext_api/execute".
//  Data - Structure - Data to send to the Service Manager.
//  ConnectionCache - Boolean - use connection cache upon sending requests.
//  Timeout - String - Service Manager response time.
// 
// Returns:
//  HTTPResponse - a response of a HTTP service of the Service manager. 
//
Function SendRequestToServiceManager(Method, Address, Val Data = Undefined, ConnectionCache = True, Timeout = 60) Export
	
	SetPrivilegedMode(True);
	
	FullAddress = StrTemplate("%1/%2", SaaSOperations.InternalServiceManagerURL(), Address);

	ServerData = CommonClientServer.URIStructure(FullAddress);

	SetSafeModeDisabled(True);

	If ConnectionCache Then
		Join = SaaSOperationsCTLCached.ConnectingToServiceManager(ServerData, Timeout);
	Else
		Join = ConnectingToServiceManager(ServerData, Timeout);
	EndIf;

	Query = New HTTPRequest(ServerData.PathAtServer);
	Query.Headers.Insert("Content-Type", "application/json; charset=utf-8");

	If TypeOf(Data) = Type("Structure") Then
		Data = StringFromJSONStructure(Data);
		Query.SetBodyFromString(Data);
	ElsIf TypeOf(Data) = Type("BinaryData") Then
		Query.SetBodyFromBinaryData(Data);
	ElsIf TypeOf(Data) = Type("String") Then
		Query.SetBodyFromString(Data);
	EndIf;

	Return Join.CallHTTPMethod(Method, Query);

EndFunction
 
// Returns the HTTP connection with the manager service.
// The calling code must set the privilege mode.
//
// Parameters:
//	ServerData - Structure - See CommonClientServer.URIStructure.
//	Timeout - Number - a server response timeout
// 
// Returns:
//  HTTPConnection - a connection with the Service manager.
//
Function ConnectingToServiceManager(ServerData, Timeout = 60) Export

	SSLScheme = "https";
	If Lower(ServerData.Schema) = SSLScheme Then
		SecureConnection =  New OpenSSLSecureConnection(, New OSCertificationAuthorityCertificates);
	Else
		SecureConnection = Undefined;
	EndIf;

	Join = New HTTPConnection(ServerData.Host, ServerData.Port,
		SaaSOperations.ServiceManagerInternalUserName(),
		SaaSOperations.ServiceManagerInternalUserPassword(),
		GetFilesFromInternet.GetProxy(ServerData.Schema), Timeout, SecureConnection);

	Return Join;

EndFunction

// Parameters template for the 
// 
// Returns:
//  Structure:
//   * ApplicationTimeZone - Undefined
//   * ApplicationPresentation - Undefined
//   * UsersList - Undefined
//   * DataAreaCode - Undefined
Function NewActionOptionsAttachDataArea() Export
	
	Parameters = New Structure;
	Parameters.Insert("DataAreaCode", Undefined);
	Parameters.Insert("UsersList", Undefined);
	Parameters.Insert("ApplicationPresentation", Undefined);
	Parameters.Insert("ApplicationTimeZone", Undefined);
	
	Return Parameters;
	
EndFunction

// Returns the user by service user ID.
// 
// Parameters: 
//  ServiceUserID - UUID
// 
// Returns:
//  CatalogRef.Users - Retrieved user.
Function DomainUserByServiceUserID(Val ServiceUserID) Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	Users.Ref AS Ref
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.ServiceUserID = &ServiceUserID";
	Query.SetParameter("ServiceUserID", ServiceUserID);
	
	Block = New DataLock;
	Block.Add("Catalog.Users");
	
	BeginTransaction();
	Try
		Block.Lock();
		Result = Query.Execute();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Result.IsEmpty() Then
		MessageTemplate = NStr("ru = 'Не найден пользователь с идентификатором пользователя сервиса %1';
								|en = 'The user with service user ID %1 is not found';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, ServiceUserID);
		Raise(MessageText);
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Return Selection.Ref;
	
EndFunction

// Called when setting an endpoint of Service Manager.
// @skip-warning EmptyMethod - Implementation feature.
// @skip-check module-empty-method
Procedure OnSetServiceManagerEndpoint() Export
EndProcedure

#EndRegion

#Region Private

// Adds infobase data update handlers
// for all supported versions of the library or configuration to the list.
// Called before starting infobase data update to build an update plan.
//
// Parameters:
//  Handlers - ValueTable - See field details in the 
//                                  InfobaseUpdate.NewUpdateHandlerTable procedure.
//
// Example:
//  // Add a handler to the list:
//  Handler = Handlers.Add();
//  Handler.Version              = "1.0.0.0";
//  Handler.Procedure           = "IBUpdate.SwitchToVersion_1_1_0_0";
//  Handler.ExclusiveMode    = False;
//  Handler.Optional        = True;
// 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	If Common.DataSeparationEnabled() Then
		
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.Procedure = "SaaSOperationsCTL.CreateUnsharedPredefinedElements";
		Handler.Priority = 99;
		Handler.SharedData = True;
		Handler.ExclusiveMode = False;
				
				
		
	EndIf;
	
EndProcedure

// Fills in separated data handler that depends on shared data change.
//
// Parameters:
//   Parameters - Structure - Parameters of the update handlers:
//     * SeparatedHandlers - See InfobaseUpdate.NewUpdateHandlerTable
// 
Procedure FillSeparatedDataHandlers(Parameters = Undefined) Export
	
	
EndProcedure

// Called when enabling data separation by data area.
//
Procedure OnEnableSeparationByDataAreas() Export
	
	CreateUnsharedPredefinedElements();
	
EndProcedure

// Generates the list of infobase parameters.
//
// Parameters:
// ParametersTable - See SaaSOperations.IBParameters
//
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "MasterApplicationExternalAddress");
	
EndProcedure

// Handler of creation or update of predefined items
// of shared metadata objects.
//
Procedure CreateUnsharedPredefinedElements() Export
	
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then
		
		Raise NStr("ru = 'Операция может быть выполнена только в сеансе, в котором не установлены значения разделителей';
								|en = 'Operation can only be performed in a session without specified separator values';");
		
	EndIf;
	
	InitializePredefinedData();
	
EndProcedure

// Handler for creating/updating access groups of built-in profiles.
//
Procedure UpdateAccessGroupsOfSuppliedProfiles(Parameters = Undefined) Export
EndProcedure

// Called when creating a configuration manifest.
//
// Parameters:
//  AdvancedInformation - Array of XDTODataObject - objects of the XDTODataObject type with XDTOType
//    must be added to this array in the handler procedure. XDTOType is inherited from
//    {http://www.1c.ru/1cFresh/Application/Manifest/a.b.c.d}ExtendedInfoItem.
//
Procedure OnGenerateConfigurationManifest(AdvancedInformation) Export
	
	If TransactionActive() Then
		Raise NStr("ru = 'Операция не может быть выполнена при активной внешней транзакции';
								|en = 'Operation cannot be completed when an external transaction is active';");
	EndIf;
	
	CallInUndividedIB = Not Common.DataSeparationEnabled();
	
	BeginTransaction();
	
	Try
		
		PermissionsDetails = XDTOFactory.Create(
			XDTOFactory.Type("http://www.1c.ru/1cFresh/Application/Permissions/Manifes/1.0.0.1", "RequiredPermissions"));
		
		AddInsDetails = XDTOFactory.Create(
			XDTOFactory.Type("http://www.1c.ru/1cFresh/Application/Permissions/Manifes/1.0.0.1", "Addins"));
		
		TemplatesForExternalComponents = New Map();
		UseSeparationByDataAreas = Constants.UseSeparationByDataAreas.Get();
		DisableSeparationByDataAreas = False;
		
		If CallInUndividedIB Then
			
			If Not UseSeparationByDataAreas Then
				Constants.UseSeparationByDataAreas.Set(True);
				DisableSeparationByDataAreas = True;
			EndIf; 
			
			RefreshReusableValues();
			
		EndIf;
		
		Constants.UseSecurityProfiles.Set(True);
		Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Set(True);
		
		RequestsIDs = SafeModeManager.RequestsToUpdateApplicationPermissions();
		
		ApplicationManager = SafeModeManagerInternalSaaS.PermissionsApplicationManager(RequestsIDs);
		Delta = ApplicationManager.DeltaIgnoringOwners();
		
		TemplatesForExternalComponents = New Array();
		
		For Each DeltaElement In Delta.ItemsToAdd Do
			
			For Each KeyAndValue In DeltaElement.Permissions Do
				
				Resolution = Common.XDTODataObjectFromXMLString(KeyAndValue.Value);
				PermissionsDetails.Permission.Add(Resolution);
				
				If Resolution.Type() = XDTOFactory.Type("http://www.1c.ru/1cFresh/Application/Permissions/1.0.0.1", "AttachAddin") Then
					TemplatesForExternalComponents.Add(Resolution.TemplateName);
				EndIf;
				
			EndDo;
			
		EndDo;
		
		For Each TemplateName In TemplatesForExternalComponents Do
			
			AddInDetails = XDTOFactory.Create(XDTOFactory.Type("http://www.1c.ru/1cFresh/Application/Permissions/Manifes/1.0.0.1", "AddinBundle"));
			AddInDetails.TemplateName = TemplateName;
			
			FilesDetails1 = SafeModeManager.AddInBundleFilesChecksum(TemplateName);
			
			For Each KeyAndValue In FilesDetails1 Do
				
				FileDetails = XDTOFactory.Create(XDTOFactory.Type("http://www.1c.ru/1cFresh/Application/Permissions/Manifes/1.0.0.1", "AddinFile"));
				FileDetails.FileName = KeyAndValue.Key;
				FileDetails.Hash = KeyAndValue.Value;
				
				AddInDetails.Files.Add(FileDetails);
				
			EndDo;
			
			AddInsDetails.Bundles.Add(AddInDetails);
			
		EndDo;
		
		AdvancedInformation.Add(PermissionsDetails);
		AdvancedInformation.Add(AddInsDetails);
		
		If DisableSeparationByDataAreas Then
			Constants.UseSeparationByDataAreas.Set(False);
		EndIf; 
		
	Except
		
		RollbackTransaction();
		If CallInUndividedIB Then
			RefreshReusableValues();
		EndIf;
		
		Raise;
		
	EndTry;
	
	RollbackTransaction();
	If CallInUndividedIB Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure

// Returns the internal Service Manager URL.
//
// Returns:
//  String - Internal Service Manager URL.
//
Function InternalServiceManagerURL() Export
	
	Return Constants.InternalServiceManagerURL.Get();
	
EndFunction

// Sets the internal Service Manager URL.
//
// Parameters:
//  Value - String - Internal Service Manager URL.
//
Procedure SetInternalAddressOfServiceManager(Val Value) Export
	
	Constants.InternalServiceManagerURL.Set(Value);
	
EndProcedure

// Returns the username of the Service Manager utility user.
// The calling code must set the privilege mode.
//
// Returns:
//  String - Username of the Service Manager utility user.
//
Function ServiceManagerInternalUserName() Export
	
	Owner = Common.MetadataObjectID("Constant.InternalServiceManagerURL");
	InternalUsername = Common.ReadDataFromSecureStorage(Owner, "ServiceManagerInternalUserName", True);
	
	Return InternalUsername;
	
EndFunction

// Returns the password of the Service Manager utility user.
// The calling code must set the privilege mode.
//
// Returns:
//  String - Password of the Service Manager utility user.
//
Function ServiceManagerInternalUserPassword() Export
	
	Owner = Common.MetadataObjectID("Constant.InternalServiceManagerURL");
	InternalUserPassword = Common.ReadDataFromSecureStorage(Owner, "ServiceManagerInternalUserPassword", True);
	
	Return InternalUserPassword;
	
EndFunction

// Returns the endpoint for sending messages to the Service Manager.
//
// Returns:
//  ExchangePlanRef.MessagesExchange - node matching the service manager.
//
Function ServiceManagerEndpoint() Export
	
	SetPrivilegedMode(True);
	Return Constants.ServiceManagerEndpoint.Get();
	
EndFunction

Procedure PrepareAndAttachDataArea(Val DataAreaCode, Val UsersList, Val ApplicationPresentation, Val ApplicationTimeZone, Val InitialDataFileID) Export
	
	Try
		PrepareDataArea(DataAreaCode, InitialDataFileID);
		ActionParameters = NewActionOptionsAttachDataArea();
		ActionParameters.DataAreaCode = DataAreaCode;
		ActionParameters.UsersList = UsersList;
		ActionParameters.ApplicationPresentation = ApplicationPresentation;
		ActionParameters.ApplicationTimeZone = ApplicationTimeZone;		
		AttachDataArea(ActionParameters);
	Except
		ErrorInfo = ErrorInfo();
		NotifyAreaPreparationErrorManager(DataAreaCode, 
			CloudTechnology.DetailedErrorText(ErrorInfo));
		Raise;
	EndTry;
	
EndProcedure

Procedure PrepareDataArea(Val DataAreaCode, Val InitialDataFileID)
	
	If Not Users.IsFullUser(, True) Then
		Raise(NStr("ru = 'Недостаточно прав для выполнения операции';
								|en = 'Insufficient rights to perform the operation.';"));
	EndIf;
	
	SetPrivilegedMode(True);
	
	AreaKey = SaaSOperations.CreateAuxiliaryDataInformationRegisterEntryKey(
		InformationRegisters.DataAreas,
		New Structure(SaaSOperations.AuxiliaryDataSeparator(), DataAreaCode));
	LockDataForEdit(AreaKey);
	
	Try
		SaaSOperations.GetDataAreaRecordManager(DataAreaCode, Enums.DataAreaStatuses.EmptyRef());
		
		If CurrentRunMode() <> Undefined Then
			
			ErrorMessage = "";
			
			UsersInternal.AuthenticateCurrentUser();
			
			ResultOfPreparation = SaaSOperations.PrepareDataAreaForUseFromReference(DataAreaCode, InitialDataFileID, "Standart", ErrorMessage);
			
			If ResultOfPreparation <> "Success" Then
				EventName = SaaSOperations.LogEventPreparingDataArea();
				WriteLogEvent(EventName, EventLogLevel.Error, , , ErrorMessage);
				MessageType = RemoteAdministrationControlMessagesInterface.DataAreaPreparationErrorMessage();
				SendMessageAboutStateOfDataArea(MessageType, DataAreaCode, ErrorMessage);
				Raise ErrorMessage;
			EndIf;
			
		EndIf;
			
	Except
		UnlockDataForEdit(AreaKey);
		Raise;
	EndTry;
	
	UnlockDataForEdit(AreaKey);
	
EndProcedure

Procedure PrepareAreaFromUpload(Val DataAreaCode, Val DataExportedID, 
		Val UserMatching, Val SharedData = False, StateID = Undefined) Export
				
	DataBlocked = False;

	Try
			
		If Not Users.IsFullUser(, True) Then
			Raise(NStr("ru = 'Недостаточно прав для выполнения операции';
									|en = 'Insufficient rights to perform the operation.';"));
		EndIf;
		
		SetPrivilegedMode(True);
		
		AreaKey = SaaSOperations.CreateAuxiliaryDataInformationRegisterEntryKey(
			InformationRegisters.DataAreas,
			New Structure(SaaSOperations.AuxiliaryDataSeparator(), DataAreaCode));
			
		//@skip-check empty-except-statement
		Try
			LockDataForEdit(AreaKey);
			DataBlocked = True;
		Except
		EndTry;
	
		FilterJobs = New Structure;
		FilterJobs.Insert("MethodName", SaaSOperations.ClearDataAreaMethodName());
		FilterJobs.Insert("Key"     , "1");
		FilterJobs.Insert("DataArea", DataAreaCode);
		FilterJobs.Insert("JobState", Enums.JobsStates.Running);
		
		If Not DataBlocked
			Or JobsQueue.GetJobs(FilterJobs).Count() > 0 Then 
			
			If DataBlocked Then 
				UnlockDataForEdit(AreaKey);
			EndIf;
						
			AreaPreparationParameters = AreaPreparationParameters(
				DataAreaCode,
				DataExportedID,
				UserMatching,
				SharedData,
				StateID);
				
			AddTaskPrepareAreaFromUpload(
				AreaPreparationParameters,
				DataAreaCode,
				SharedData,
				True);
		
			Return;
		EndIf;
		
		EventName = SaaSOperations.LogEventPreparingDataArea();

		If SharedData Then
			SaaSOperations.SignInToDataArea(DataAreaCode);
		EndIf;
			
		BeginTransaction();
		Try

			Block = New DataLock;
			Item = Block.Add("InformationRegister.DataAreas");
			Item.SetValue("DataAreaAuxiliaryData", DataAreaCode);
			Item.Mode = DataLockMode.Shared;
			Block.Lock();
			
			RecordManager = InformationRegisters.DataAreas.CreateRecordManager();
			RecordManager.DataAreaAuxiliaryData = DataAreaCode;
			RecordManager.Read();
			
			SuitableStatuses = New Array;
			SuitableStatuses.Add(Enums.DataAreaStatuses.EmptyRef());
			SuitableStatuses.Add(Enums.DataAreaStatuses.isDeleted);

			If Not RecordManager.Selected() Then
				MessageTemplate = NStr("ru = 'Область данных %1 не найдена';
										|en = '%1 data area is not found';");
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, 
					DataAreaCode);
					
				Raise(MessageText);
			ElsIf SuitableStatuses.Find(RecordManager.Status) = Undefined Then
				MessageTemplate = NStr("ru = 'Статус области данных %1 не равен ""%2""';
										|en = 'Status of data area %1 is not ""%2""';");
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, 
					DataAreaCode, StrConcat(SuitableStatuses, """/"""));
				Raise(MessageText);
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			WriteLogEvent(EventName, EventLogLevel.Error,,, 
				DetailErrorDescription(ErrorInfo()));
			Raise;
		EndTry;
			
		
		If CurrentRunMode() <> Undefined Then
			UsersInternal.AuthenticateCurrentUser();
		EndIf;
		
		If Not Common.SubsystemExists("CloudTechnology.ExportImportDataAreas") Then
			SaaSOperations.CauseExceptionMissingSubsystemCTL("CloudTechnology.ExportImportDataAreas");
		EndIf;
		
		If ExtensionsDirectory.Used() Then
			ExtensionData_ = ExtensionsDirectory.GetExtensionsForNewArea(DataAreaCode);
		Else 
			ExtensionData_ = Undefined;
		EndIf;
		
		FileID = DataExportedID;
		If TypeOf(DataExportedID) = Type("Structure") Then
			FileID = DataExportedID.DifferentialCopyFileID
		EndIf;
		
		TimeCatalog = GetTempFileName() + GetPathSeparator();
		CreateDirectory(TimeCatalog);
		Archive = ZipArchives.ReadArchive(FileID);
		ZipArchives.ExtractFile(Archive, "DumpInfo.xml", TimeCatalog);
		
		UploadInformation = ExportImportDataInternal.ReadXDTOObjectFromFile(
			TimeCatalog + "DumpInfo.xml", XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "DumpInfo"));
		
		If  Not ExportImportDataInternal.UploadingToArchiveIsCompatibleWithCurConfiguration(UploadInformation)
			Or Not ExportImportDataInternal.UploadingToArchiveIsCompatibleWithCurVersionOfConfiguration(UploadInformation) Then
		
			ErrorMessage = NStr("ru = 'Требуется конвертация';
									|en = 'Conversion is required';");
			WriteLogEvent(EventName, EventLogLevel.Error, , , ErrorMessage);
			MessageType = 
				RemoteAdministrationControlMessagesInterface.ErrorMessagePreparingDataAreaConversionRequired();
			
			AdditionalProperties = New Structure();
			AdditionalProperties.Insert("DataExportedID", DataExportedID);
			AdditionalProperties.Insert("ConfigurationName", Metadata.Name);
			AdditionalProperties.Insert("ConfigurationVersion", Metadata.Version);
			
			SendMessageAboutStateOfDataArea(MessageType, DataAreaCode, ErrorMessage, 
				AdditionalProperties);
			UnlockDataForEdit(AreaKey);
			If SharedData Then
				SaaSOperations.SignOutOfDataArea();
			EndIf;
			Return;
		EndIf;
		
		ImportParameters = New Structure();
		If ValueIsFilled(StateID) Then
			ImportParameters.Insert("StateID", StateID);
		EndIf;

		ImportResult1 = ExportImportDataAreas.ImportCurrentAreaFromVolume(
			DataExportedID,,,
			UserMatching,
			ExtensionData_,
			ImportParameters);
		
		If ImportResult1 = Undefined Then
			Return;
		EndIf;
		
		ExtensionsDirectory.RecordDataOfRecoverableAreaExtensions(Undefined);
		RecordManager.Status = Enums.DataAreaStatuses.Used;
		
		// Send a message to the Service Manager about the data area being ready.
		MessageType = RemoteAdministrationControlMessagesInterface.MessageDataAreaPrepared();
		Message = MessagesSaaS.NewMessage(MessageType);
		Message.AdditionalInfo = XDTOSerializer.WriteXDTO(ImportResult1);	
		Message.Body.Zone = RecordManager.DataAreaAuxiliaryData;
		
		BeginTransaction();
		Try
			MessagesSaaS.SendMessage(
				Message,
				SaaSOperationsCached.ServiceManagerEndpoint());
			
			RecordManager.Write();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		UnlockDataForEdit(AreaKey);
		
		If SharedData Then
			SaaSOperations.SignOutOfDataArea();
		EndIf;
		
	Except
		If DataBlocked Then
			UnlockDataForEdit(AreaKey);
		EndIf;
		
		If SharedData Then
			SaaSOperations.SignOutOfDataArea();
		EndIf;
		
		Raise;
	EndTry;
	
EndProcedure

Function AreaPreparationParameters(DataAreaCode, DataExportedID, UserMatching, SharedData, StateID) Export
	PreparationParameters = New Array;
	PreparationParameters.Add(DataAreaCode);
	PreparationParameters.Add(DataExportedID);
	PreparationParameters.Add(UserMatching);
	PreparationParameters.Add(SharedData);
	PreparationParameters.Add(StateID);
	Return PreparationParameters;
EndFunction

Procedure AddTaskPrepareAreaFromUpload(AreaPreparationParameters, DataAreaCode, Undivided, Deferred2 = False) Export 

	JobParameters = New Structure;
	JobParameters.Insert("MethodName", SaaSOperations.MethodNamePrepareAreaFromUpload());
	JobParameters.Insert("Parameters", AreaPreparationParameters);
	
	If Undivided Then
		JobParameters.Insert("DataArea", -1);
	Else
		JobParameters.Insert("DataArea", DataAreaCode);
	EndIf;
	
	JobParameters.Insert("ExclusiveExecution", True);
	
	If Deferred2 Then
		SecondsIn10Minutes = 600;
		JobParameters.Insert("ScheduledStartTime", CurrentSessionDate() + SecondsIn10Minutes);
	EndIf;
	
	JobParameters.Insert("Key", XMLString(DataAreaCode));	
	
	JobsQueue.AddJob(JobParameters);

EndProcedure

Procedure OnErrorPrepareDataAreaFromExport(JobParameters, ErrorInfo) Export
	
	PreparationParameters = JobParameters.Parameters;
	DataArea = PreparationParameters[0];
	
	DataAreaManager = InformationRegisters.DataAreas.CreateRecordManager();
	DataAreaManager.DataAreaAuxiliaryData = DataArea;
	DataAreaManager.Read();
	
	If Not DataAreaManager.Selected() Then
		Raise StrTemplate(NStr("ru = 'Область данных %1 не найдена';
										|en = '%1 data area is not found';"), DataArea);
	EndIf;
			
	JobsFilter = New Structure();
	
	JobKey = XMLString(DataArea);
	JobsFilter.Insert(
		"Key",
		JobKey); 
	JobsFilter.Insert(
		"MethodName",
		SaaSOperations.MethodNamePrepareAreaFromUpload());

	Jobs = JobsQueue.GetJobs(JobsFilter);
	
	If Not ValueIsFilled(Jobs) Then		
		JobsFilter.Delete("Key");
		AllTasks_ = JobsQueue.GetJobs(JobsFilter);
		For Each Job In AllTasks_ Do
			LinesByArea = New Array;
			If Job.Parameters[0] = DataArea Then
				LinesByArea.Add(Job);	
			EndIf;			
		EndDo;
		Jobs = AllTasks_.Copy(LinesByArea);
	EndIf;
	
	EmergencyJob = Jobs.Find(
		Enums.JobsStates.ErrorHandlerOnFailure,
		"JobState");
		
	CommentParts = New Array;

	If EmergencyJob = Undefined Then
		CommentParts.Add(NStr("ru = 'Процесс подготовки области данных завершился с ошибкой';
										|en = 'Data area preparation completed with error';"));		
	Else	
		CommentParts.Add(NStr("ru = 'Процесс подготовки области данных аварийно завершился';
										|en = 'Data area preparation crashed';"));		
	EndIf;
	
	Repeat = DataAreaManager.Repeat;
	
	RetryOnAbnormalTermination = DataAreaManager.RetryOnAbnormalTermination;
	MaximumRestartsNumberOnFailure = 15;	
	
	RepeatAtEndByError = Max(Repeat - RetryOnAbnormalTermination, 0);
	MaximumRestartsNumberOnFailureByError = 3;
	
	AttemptLimitExceeded = RepeatAtEndByError > MaximumRestartsNumberOnFailureByError 
		Or RetryOnAbnormalTermination > MaximumRestartsNumberOnFailure;

	If AttemptLimitExceeded Then
		CommentParts.Add(NStr("ru = 'Исчерпано количество попыток подготовки.';
										|en = 'Exceeded maximum number of preparation attempts.';"));		
	Else
		
		Repeat = Repeat + 1;
		
		If EmergencyJob = Undefined Then
			RepeatAtEndByError = RepeatAtEndByError + 1;	
		Else
			RetryOnAbnormalTermination = RetryOnAbnormalTermination + 1;		
		EndIf;
		
		CommentParts.Add(NStr("ru = 'Запланирована следующая попытка подготовки.';
										|en = 'The next preparation attempt is scheduled.';"));
		
	EndIf;
		
	AttemptsDescription = StrTemplate(NStr("ru = 'Повтор при ошибке %1 из %2
		|Повтор при аварийном завершении %3 из %4';
		|en = 'Retry on error %1 out of %2
		|Retry on abnormal termination %3 out of %4';"),
		RepeatAtEndByError,
		MaximumRestartsNumberOnFailureByError,
		RetryOnAbnormalTermination,
		MaximumRestartsNumberOnFailure);
	CommentParts.Add(AttemptsDescription);	
	
	EnterInArea = Not Common.SeparatedDataUsageAvailable();
	
	BeginTransaction();	
	Try
				
		DataAreaManager.Repeat = Repeat;
		DataAreaManager.RetryOnAbnormalTermination = RetryOnAbnormalTermination;
		DataAreaManager.Write();		
		
		For Each Job In Jobs Do
			JobsQueue.DeleteJob(Job.Id);	
		EndDo;

		If AttemptLimitExceeded Then
			NotifyAreaPreparationErrorManager(
				DataArea, 
				CloudTechnology.DetailedErrorText(ErrorInfo));	
		Else
						
			SharedData = PreparationParameters[3];
			
			AreaPreparationParameters = AreaPreparationParameters(
				DataArea,
				PreparationParameters[1],
				PreparationParameters[2],
				SharedData,
				PreparationParameters[4]);
			
			AddTaskPrepareAreaFromUpload(
				AreaPreparationParameters,
				DataArea,
				SharedData,
				True);
			
		EndIf;
		
		If EnterInArea Then
			SaaSOperations.SignInToDataArea(DataArea);	
		EndIf;
		
		WriteLogEvent(
			NStr("ru = 'Область данных.Ошибка при загрузке из файла';
				|en = 'Data area.Error importing from file';", Common.DefaultLanguageCode()),
			EventLogLevel.Warning,,,
			StrConcat(CommentParts, Chars.LF),
			EventLogEntryTransactionMode.Transactional);
			
		If EnterInArea Then
			SaaSOperations.SignOutOfDataArea();	
		EndIf;
	
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure AttachDataArea(Parameters) Export
	
	DataAreaCode = Parameters.DataAreaCode;
	UsersList = Parameters.UsersList;
	ApplicationPresentation = Parameters.ApplicationPresentation;
	ApplicationTimeZone = Parameters.ApplicationTimeZone;
	
	SetPrivilegedMode(True);
	
	If ExtensionsDirectory.Used() Then
		ExtensionData_ = ExtensionsDirectory.GetExtensionsForNewArea(DataAreaCode);
	Else 
		ExtensionData_ = Undefined;
	EndIf;
	
	If ExtensionData_ <> Undefined And ExtensionData_.Property("RecoveryExtensions")
		And ExtensionData_.RecoveryExtensions.Count() > 0 Then
		
		If ExtensionData_.Property("DataAreaKey") Then
			
			Constants.DataAreaKey.Set(ExtensionData_.DataAreaKey);
			If UsersList.Count() = 1 Then
				ServiceUserID = UsersList[0].UserServiceID;
				ExtensionsDirectory.RestoreExtensionsToNewArea(ExtensionData_.RecoveryExtensions, 
					ServiceUserID);
			Else
				ExtensionsDirectory.RestoreExtensionsToNewArea(ExtensionData_.RecoveryExtensions);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	BeginTransaction();
	Try
		
		// Setting data area parameters.
		Block = New DataLock;
		Block.Add("InformationRegister.DataAreas");
		Block.Lock();
		
		RecordManager = InformationRegisters.DataAreas.CreateRecordManager();
		RecordManager.Read();
		If Not RecordManager.Selected() Then
			MessageTemplate = NStr("ru = 'Область данных %1 не существует.';
									|en = '%1 data area does not exist.';");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, DataAreaCode);
			Raise(MessageText);
		EndIf;
		
		RecordManager.Status = Enums.DataAreaStatuses.Used;
		ManagerSCopy = InformationRegisters.DataAreas.CreateRecordManager();
		FillPropertyValues(ManagerSCopy, RecordManager);
		RecordManager = ManagerSCopy;
		RecordManager.Write();
		
		
		// Creating administrators in the area.
		For Each UserDetails In UsersList Do
			
			UserLanguage = LanguageByCode(UserDetails.Language);
			
			Mail = "";
			Phone = "";
			If ValueIsFilled(UserDetails.EMail) Then
				Mail = UserDetails.EMail;
			EndIf;
			
			If ValueIsFilled(UserDetails.Phone) Then
				Phone = UserDetails.Phone;
			EndIf;
			
			ItemInstanceAddressStructure = CompositionOfPostalAddress(Mail);
			
			Query = New Query;
			Query.Text =
			"SELECT
			|    Users.Ref AS Ref
			|FROM
			|    Catalog.Users AS Users
			|WHERE
			|    Users.ServiceUserID = &ServiceUserID";
			Query.SetParameter("ServiceUserID", UserDetails.UserServiceID);
			
			Block = New DataLock;
			Block.Add("Catalog.Users");
			Block.Lock();
			
			Result = Query.Execute();
			If Result.IsEmpty() Then
				DataAreaUser = Undefined;
			Else
				Selection = Result.Select();
				Selection.Next();
				DataAreaUser = Selection.Ref;
			EndIf;
			
			If Not ValueIsFilled(DataAreaUser) Then
				UserObject = Catalogs.Users.CreateItem();
				UserObject.ServiceUserID = UserDetails.UserServiceID;
			Else
				UserObject = DataAreaUser.GetObject();
			EndIf;
			
			UserObject.Description = UserDetails.FullName;
			
			UpdateEmailAddress(UserObject, Mail, ItemInstanceAddressStructure);
			
			UpdatePhone(UserObject, Phone);
			
			IBUserDetails = Users.NewIBUserDetails();
			
			IBUserDetails.Name = UserDetails.Name;
			
			IBUserDetails.StandardAuthentication = True;
			IBUserDetails.OpenIDAuthentication = True;
			IBUserDetails.ShowInList = False;
			
			IBUserDetails.StoredPasswordValue = UserDetails.StoredPasswordValue;
			
			IBUserDetails.Language = UserLanguage;
			
			// These properties are supported starting from version 1.0.3.7.
			FAProperties = New Structure("OSAuthentication, OSUser");
			FillPropertyValues(FAProperties, UserDetails);
			IBUserDetails.OSAuthentication = FAProperties.OSAuthentication;
			IBUserDetails.OSUser   = FAProperties.OSUser;
			
			Roles = New Array;
			Roles.Add("FullAccess");
			IBUserDetails.Roles = Roles;
			
			IBUserDetails.Insert("Action", "Write");
			UserObject.AdditionalProperties.Insert("IBUserDetails", IBUserDetails);
			UserObject.AdditionalProperties.Insert("CreateAdministrator",
				NStr("ru = 'Создание администратора области данных из менеджера сервиса.';
					|en = 'Create data area administrator from the service manager.';"));
			
			UserObject.AdditionalProperties.Insert("RemoteAdministrationChannelMessageProcessing");
			UserObject.Write();
			
			DataAreaUser = UserObject.Ref;
			
			If UsersInternal.CannotEditRoles()
				And Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
			
				ModuleAccessManagementInternalSaaS = Common.CommonModule("AccessManagementInternalSaaS");
				ModuleAccessManagementInternalSaaS.SetUserBelongingToAdministratorGroup(DataAreaUser, True);
			EndIf;
		EndDo;
		
		UpdatePredefinedNodesCode();
		If Not IsBlankString(ApplicationPresentation) Then
			UpdatePropertiesOfPredefinedNodes(ApplicationPresentation);
		EndIf;
	
		Message = MessagesSaaS.NewMessage(RemoteAdministrationControlMessagesInterface.MessageDataAreaIsReadyForUse());
		Message.Body.Zone = DataAreaCode;
		
		MessagesSaaS.SendMessage(Message, SaaSOperationsCTLCached.ServiceManagerEndpoint(), True);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
	CheckNeedAndConnectToInteractionSystem(Parameters);
	
	UpdateCurDataAreaParameters(ApplicationPresentation, ApplicationTimeZone);
	
	MessagesSaaS.DeliverQuickMessages();
	
EndProcedure

// @skip-warning EmptyMethod - Implementation feature.
// @skip-check module-empty-method
Procedure CheckNeedAndConnectToInteractionSystem(ParametersForAttachingArea)
	
EndProcedure

Procedure SendMessageAboutStateOfDataArea(Val MessageType, Val DataAreaCode, Val ErrorMessage, AdditionalProperties = Undefined)
	
	Message = MessagesSaaS.NewMessage(MessageType);
	Message.Body.Zone = DataAreaCode;
	If Message.Body.Properties().Get("ErrorDescription") <> Undefined Then
		Message.Body.ErrorDescription = ErrorMessage;
	EndIf;
	If ValueIsFilled(AdditionalProperties) Then
		Message.AdditionalInfo = XDTOSerializer.WriteXDTO(AdditionalProperties);
	EndIf;
	BeginTransaction();
	Try
		MessagesSaaS.SendMessage(
			Message,
			SaaSOperationsCached.ServiceManagerEndpoint());
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Parameters: 
//  LanguageCode - String
// 
// Returns: 
//  String - Language by code.
//
Function LanguageByCode(Val LanguageCode) Export
	
	If ValueIsFilled(LanguageCode) Then
		
		For Each Language In Metadata.Languages Do
			If Language.LanguageCode = LanguageCode Then
				Return Language.Name;
			EndIf;
		EndDo;
		
		MessageTemplate = NStr("ru = 'Неподдерживаемый код языка: %1';
								|en = 'Unsupported language code: %1';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, LanguageCode);
		Raise(MessageText);
		
	Else
		
		Return Metadata.DefaultLanguage.Name;
		
	EndIf;
	
EndFunction

// Email address composition.
// 
// Parameters: 
//  EMAddress - String -Email address
// 
// Returns:
// Structure: 
//   * Status - Boolean - the validation result: successful or failed.
//   * Value - Array of Structure:
//    ** Address - String - Send-to email.
//    ** Presentation - String - Recipient name.
//   * ErrorMessage - String - (Available if Status = False) Error details.
// (See CommonClientServer.ParseStringWithEmailAddresses.)
Function CompositionOfPostalAddress(Val EMAddress) Export
	
	If ValueIsFilled(EMAddress) Then
		
		Try
			ItemInstanceAddressStructure = CommonClientServer.ParseStringWithEmailAddresses(EMAddress);
		Except
			MessageTemplate = NStr("ru = 'Указан некорректный адрес электронной почты: %1
				|Ошибка: %2';
				|en = 'Invalid email address: %1
				|Error: %2';");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, EMAddress, ErrorInfo().Description);
			Raise(MessageText);
		EndTry;
		
		Return ItemInstanceAddressStructure;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Procedure UpdateEmailAddress(Val UserObject, Val Address, Val ItemInstanceAddressStructure) Export
	
	CIKind = Catalogs.ContactInformationKinds.UserEmail;
	
	If ItemInstanceAddressStructure = Undefined Then
		LineOfATabularSection = UserObject.ContactInformation.Find(CIKind, "Kind");
		If LineOfATabularSection <> Undefined Then
			UserObject.ContactInformation.Delete(LineOfATabularSection);
		EndIf;
	Else
		ContactsManager.AddContactInformation(UserObject, Address, CIKind);
	EndIf;
	
EndProcedure

Procedure UpdatePhone(Val UserObject, Val Phone) Export
	
	CIKind = Catalogs.ContactInformationKinds.UserPhone;
	
	If IsBlankString(Phone) Then
		LineOfATabularSection = UserObject.ContactInformation.Find(CIKind, "Kind");
		If LineOfATabularSection <> Undefined Then
			UserObject.ContactInformation.Delete(LineOfATabularSection);
		EndIf;
	Else
		ContactsManager.AddContactInformation(UserObject, Phone, CIKind);
	EndIf;
	
EndProcedure

Procedure UpdatePropertiesOfPredefinedNodes(Val Description) Export

	If Not Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		Return;
		
	EndIf;
	
	ModuleDataExchangeCached = Common.CommonModule("DataExchangeCached");
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		If SaaSOperations.IsSeparatedMetadataObject(ExchangePlan) Then
			
			Query = New Query(
			"SELECT TOP 1
			|	TRUE
			|FROM
			|	&ExchangePlanTableName AS ExchangePlan
			|WHERE
			|	ExchangePlan.ThisNode");
			
			Query.Text = StrReplace(Query.Text, "&ExchangePlanTableName", "ExchangePlan." + ExchangePlan.Name);
			
			If Query.Execute().IsEmpty() Then
				
				NewNodeObject = ExchangePlans[ExchangePlan.Name].CreateNode();
				NewNodeObject.ThisNode = True;
				NewNodeObject.DataExchange.Load = True;
				NewNodeObject.Write();
				
			EndIf;
			
		EndIf;
			
		If ModuleDataExchangeCached.ExchangePlanUsedInSaaS(ExchangePlan.Name) Then
			
			ThisNode = ExchangePlans[ExchangePlan.Name].ThisNode();
			NodeDescription = Common.ObjectAttributeValue(ThisNode, "Description");
			
			If NodeDescription <> Description Then
				
				ThisNodeObject = ThisNode.GetObject();
				ThisNodeObject.Description = Description;
				ThisNodeObject.Write();
				
			EndIf;
			
		EndIf;
		
	EndDo;

EndProcedure

Procedure UpdatePredefinedNodesCode() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		Return;
		
	EndIf;
	
	ModuleDataExchangeCached = Common.CommonModule("DataExchangeCached");
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		If SaaSOperations.IsSeparatedMetadataObject(ExchangePlan) Then
			
			Query = New Query(
			"SELECT TOP 1
			|	TRUE
			|FROM
			|	&ExchangePlanTableName AS ExchangePlan
			|WHERE
			|	ExchangePlan.ThisNode");
			
			Query.Text = StrReplace(Query.Text, "&ExchangePlanTableName", "ExchangePlan." + ExchangePlan.Name);
			
			If Query.Execute().IsEmpty() Then
				
				NewNode = ExchangePlans[ExchangePlan.Name].CreateNode();
				NewNode.ThisNode = True;
				NewNode.DataExchange.Load = True;
				NewNode.Write();
				
			EndIf;
			
		EndIf;
			
		If ModuleDataExchangeCached.ExchangePlanUsedInSaaS(ExchangePlan.Name) Then
			
			ThisNode = ExchangePlans[ExchangePlan.Name].ThisNode();
			NodeCode = Common.ObjectAttributeValue(ThisNode, "Code");
			
			If DataExchangeServer.IsXDTOExchangePlan(ExchangePlan.Name) Then
				
				NodeNewCode = String(ThisNode.UUID());
				
			Else
				
				NodeNewCode = RemoteAdministrationMessagesImplementation.ExchangePlanNodeCodeInService(SaaSOperations.SessionSeparatorValue());
				
			EndIf;
			
			If NodeCode <> NodeNewCode Then
				
				ThisNodeObject = ThisNode.GetObject();
				ThisNodeObject.Code = NodeNewCode;
				ThisNodeObject.Write();
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure UpdateCurDataAreaParameters(Val Presentation, Val TimeZone) Export
	
	Constants.DataAreaPresentation.Set(Presentation);
	Constants.DataAreaTimeZone.Set(TimeZone);
	
	If GetInfoBaseTimeZone() <> TimeZone Then
	
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		
		BeginTransaction();
		
		MessageChannel = "ExclusiveMode\SetIBTimeZone";
		Body = New Structure;
		Body.Insert("TimeZone", TimeZone);
		Body.Insert("DataArea", ModuleSaaSOperations.SessionSeparatorValue());
		
		MessagesExchange.SendMessage(
			MessageChannel,
			Body,
			MessagesExchangeInner.ThisNode());
			
		CommitTransaction();
		
	EndIf;
	
EndProcedure

// Fills mapping of method names and their aliases for calling from a job queue.
//
// Parameters:
//  NamesAndAliasesMap - Map of KeyAndValue:
//   * Key - String - a method alias, for example, ClearDataArea.
//   * Value - String - a method name to be called, for example, SaaS.ClearDataArea.
//   
// Example:
//    You can specify Undefined as a value, 
//    in this case, the name is assumed to be the same as an alias.
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert("SaaSOperationsCTL.PrepareAndAttachDataArea");
	NamesAndAliasesMap.Insert(SaaSOperations.MethodNamePrepareAreaFromUpload());
	
EndProcedure

// See JobsQueueOverridable.OnDefineErrorHandlers
Procedure OnDefineErrorHandlers(ErrorHandlers) Export
	
	ErrorHandlers.Insert(SaaSOperations.MethodNamePrepareAreaFromUpload(), "SaaSOperationsCTL.OnErrorPrepareDataAreaFromExport");
	
EndProcedure

// @skip-check module-empty-method - Implementation feature.
Procedure NotifyAreaPreparationErrorManager(DataAreaCode, ErrorMessage)
EndProcedure

#Region Cryptography

Function Hash(BinaryData, Type)
	
	Hashing = New DataHashing(Type);
	Hashing.Append(BinaryData);
	
	Return Hashing.HashSum;
		
EndFunction

Function HMAC(Val Var_Key, Val Data, Type, BlockSize)
	
	If Var_Key.Size() > BlockSize Then
		Var_Key = Hash(Var_Key, Type);
	EndIf;
	
	If Var_Key.Size() < BlockSize Then
		Var_Key = GetHexStringFromBinaryData(Var_Key);
		Var_Key = Left(Var_Key + RepeatLine("00", BlockSize), BlockSize * 2);
	EndIf;
	
	Var_Key = GetBinaryDataBufferFromBinaryData(GetBinaryDataFromHexString(Var_Key));
	
	ipad = GetBinaryDataBufferFromHexString(RepeatLine("36", BlockSize));
	opad = GetBinaryDataBufferFromHexString(RepeatLine("5c", BlockSize));
	
	ipad.WriteBitwiseXor(0, Var_Key);
	ikeypad = GetBinaryDataFromBinaryDataBuffer(ipad);
	
	opad.WriteBitwiseXor(0, Var_Key);
	okeypad = GetBinaryDataFromBinaryDataBuffer(opad);
	
	Return Hash(GlueBinaryData(okeypad, Hash(GlueBinaryData(ikeypad, Data), Type)), Type);
	
EndFunction

Function GlueBinaryData(BinaryData1, BinaryData2)
	
	BinaryDataArray = New Array;
	BinaryDataArray.Add(BinaryData1);
	BinaryDataArray.Add(BinaryData2);
	
	Return ConcatBinaryData(BinaryDataArray);
	
EndFunction

Function RepeatLine(String, Count)
	
	Parts = New Array(Count);
	For K = 1 To Count Do
		Parts.Add(String);
	EndDo;
	
	Return StrConcat(Parts, "");
	
EndFunction

#EndRegion

// The function of converting JSON values.
//  See the WriteJSON global context function.
//
// Returns:
//  String - UUID -> String(UUID)
//
Function ConvertingJSONValues(Property, Value, AdditionalParameters, Cancel) Export 
	
    If TypeOf(Value) = Type("UUID") Then
        Return String(Value);
    EndIf; 
    
    Return Value;
	
EndFunction

#EndRegion

#Region Checks

// Exclusion control of separated objects in controlling subscriptions.
// 
// Parameters: 
//  RaiseException1 - Boolean
// 
// Returns:
//  Undefined, Structure - If no errors, Undefined:
//  * MetadataObjects - Array of MetadataObject
//  * ExceptionText - String
Function ControllingExclusionOfSharedObjectsInControllingSubscriptions(RaiseException1 = True) Export
	
	MetadataControlRules = New Map;
	
	MetadataControlRules.Insert(Metadata.Constants, "ConstantValueManager.%1");
	MetadataControlRules.Insert(Metadata.Catalogs, "CatalogObject.%1");
	MetadataControlRules.Insert(Metadata.Documents, "DocumentObject.%1");
	MetadataControlRules.Insert(Metadata.BusinessProcesses, "BusinessProcessObject.%1");
	MetadataControlRules.Insert(Metadata.Tasks, "TaskObject.%1");
	MetadataControlRules.Insert(Metadata.ChartsOfCalculationTypes, "ChartOfCalculationTypesObject.%1");
	MetadataControlRules.Insert(Metadata.ChartsOfCharacteristicTypes, "ChartOfCharacteristicTypesObject.%1");
	MetadataControlRules.Insert(Metadata.ExchangePlans, "ExchangePlanObject.%1");
	MetadataControlRules.Insert(Metadata.ChartsOfAccounts, "ChartOfAccountsObject.%1");
	MetadataControlRules.Insert(Metadata.AccountingRegisters, "AccountingRegisterRecordSet.%1");
	MetadataControlRules.Insert(Metadata.AccumulationRegisters, "AccumulationRegisterRecordSet.%1");
	MetadataControlRules.Insert(Metadata.CalculationRegisters, "CalculationRegisterRecordSet.%1");
	MetadataControlRules.Insert(Metadata.InformationRegisters, "InformationRegisterRecordSet.%1");
	
	StandardSeparators = New Array; // Array of MetadataObject
	StandardSeparators.Add(Metadata.CommonAttributes.DataAreaMainData);
	StandardSeparators.Add(Metadata.CommonAttributes.DataAreaAuxiliaryData);
	
	ControlProcedures = New Array;
	ControlProcedures.Add(Metadata.EventSubscriptions.CheckSharedRecordSetsOnWriteSaaSTechnology.Handler);
	ControlProcedures.Add(Metadata.EventSubscriptions.CheckSharedObjectsOnWriteSaaSTechnology.Handler);
	
	ControllingSubscriptions = New Array; // Array of MetadataObjectEventSubscription
	For Each EventSubscription In Metadata.EventSubscriptions Do
		If ControlProcedures.Find(EventSubscription.Handler) <> Undefined Then
			ControllingSubscriptions.Add(EventSubscription);
		EndIf;
	EndDo;
	
	ViolationsOfControlExclusionOfSeparatedObjectsInControllingSubscriptions = New Array();
	
	MetadataObjectsWithViolations = New Array;
	
	For Each MetadataControlRule In MetadataControlRules Do
		
		ControlledMetadataObjects = MetadataControlRule.Key; // Array of MetadataObject
		ConstructorForMetadataObjectType = MetadataControlRule.Value;
		
		For Each ControlledMetadataObject In ControlledMetadataObjects Do
			
			
			// 2. Check if shared metadata objects are included in managing event subscriptions.
			// 
			
			If ValueIsFilled(ConstructorForMetadataObjectType) Then
				
				MetadataObjectType = Type(StringFunctionsClientServer.SubstituteParametersToString(ConstructorForMetadataObjectType, ControlledMetadataObject.Name));
				
				ProvidedControlOfExclusionOfSharedObjectsInUnsharedSubscriptions = True;
				
				For Each ControllingSubscription In ControllingSubscriptions Do
					
					If ControllingSubscription.Source.ContainsType(MetadataObjectType) Then
						For Each StandardSeparator In StandardSeparators Do
							If SaaSOperations.IsSeparatedMetadataObject(ControlledMetadataObject, StandardSeparator.Name) Then
								ProvidedControlOfExclusionOfSharedObjectsInUnsharedSubscriptions = False;
							EndIf;
						EndDo;
					EndIf;
					
				EndDo;
				
				If Not ProvidedControlOfExclusionOfSharedObjectsInUnsharedSubscriptions Then
					ViolationsOfControlExclusionOfSeparatedObjectsInControllingSubscriptions.Add(ControlledMetadataObject);
					MetadataObjectsWithViolations.Add(ControlledMetadataObject);
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	ExceptionsRaised = New Array();
	
	If ViolationsOfControlExclusionOfSeparatedObjectsInControllingSubscriptions.Count() > 0 Then
		
		ExceptionText = "";
		
		For Each OffendingMetadataObject In ViolationsOfControlExclusionOfSeparatedObjectsInControllingSubscriptions Do
			
			If Not IsBlankString(ExceptionText) Then
				ExceptionText = ExceptionText + ", ";
			EndIf;
			
			ExceptionText = ExceptionText + OffendingMetadataObject.FullName();
			
		EndDo;
		
		SubscriptionText = "";
		For Each ControllingSubscription In ControllingSubscriptions Do
			
			If Not IsBlankString(SubscriptionText) Then
				SubscriptionText = SubscriptionText + ", ";
			EndIf;
			
			SubscriptionText = SubscriptionText + ControllingSubscription.Name;
			
		EndDo;
		
		ExceptionsRaised.Add(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Разделенные объекты метаданных конфигурации не должны входить в состав подписок на события (%1).
                  |Следующие объекты не удовлетворяют этому критерию: %2';
					|en = 'Separated configuration metadata objects cannot be included into event subscriptions (%1).
					|The following objects do not meet this criterion: %2';"),
			SubscriptionText, ExceptionText));
		
	EndIf;
	
	ResultingException = "";
	Iterator_SSLy = 1;
	
	For Each RaisedException In ExceptionsRaised Do
		
		If Not IsBlankString(ResultingException) Then
			ResultingException = ResultingException + Chars.LF + Chars.CR;
		EndIf;
		
		ResultingException = ResultingException + Format(Iterator_SSLy, "NFD=0; NG=0") + ". " + RaisedException;
		Iterator_SSLy = Iterator_SSLy + 1;
		
	EndDo;
	
	If Not IsBlankString(ResultingException) Then
		
		ResultingException = NStr("ru = 'Обнаружены ошибки в структуре метаданных конфигурации:';
										|en = 'The following errors are found in the applied solution metadata structure:';") + Chars.LF + Chars.CR + ResultingException;
		
		If RaiseException1 Then
			
			Raise ResultingException;
			
		Else
			
			Return New Structure("MetadataObjects, ExceptionText", MetadataObjectsWithViolations, ResultingException);
			
		EndIf;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion
