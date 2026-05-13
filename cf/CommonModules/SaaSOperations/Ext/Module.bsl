///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2018, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the name of the common attribute that is a separator of main data.
//
// Returns:
//   String - name of the common attribute that is a separator of main data.
//
Function MainDataSeparator() Export
	
	Return Metadata.CommonAttributes.DataAreaMainData.Name;
	
EndFunction

// Returns the name of the common attribute that is a separator of auxiliary data.
//
// Returns:
//   String - name of the common attribute that is a separator of auxiliary data.
//
Function AuxiliaryDataSeparator() Export
	
	Return Metadata.CommonAttributes.DataAreaAuxiliaryData.Name;
	
EndFunction

// Returns the data separation mode flag
// (conditional separation).
// 
// Returns False if the configuration does not support data separation mode
// (does not contain attributes to share).
//
// Returns:
//  Boolean - If True, separation is enabled.
//  Boolean - False is separation is disabled or not supported.
//
Function DataSeparationEnabled() Export
	
	Return SaaSOperationsCached.DataSeparationEnabled();
	
EndFunction

// Returns a flag indicating whether separated data (included in the separators) can be accessed.
// The flag is session-specific, but can change its value if data separation is enabled
// on the session run. So, check the flag right before addressing the shared data.
// 
// Returns If True, the configuration does not support data separation mode
// (does not contain attributes to share).
//
// Returns:
//   Boolean - If True, separation is not supported or disabled.
//                    Or separation is enabled and separators are set.
//   Boolean - If False, separation is enabled and separators are not set.
//
Function SeparatedDataUsageAvailable() Export
	
	If Not DataSeparationEnabled() Then
		Return True;
	EndIf;
	
	Return SessionSeparatorUsage();
	
EndFunction

// Clears all session parameters except associated 
// with common DataArea attribute.
//
Procedure ClearAllSessionParametersExceptDelimiters() Export
	
	Common.ClearSessionParameters(, "DataAreaValue,DataAreaUsage");
	
EndProcedure

// Checks whether the data area is locked.
//
// Parameters:
//  DataArea -  Number - separator value of the data area 
//   whose lock state must be checked.
//
// Returns:
//  Boolean - if True, the data area is locked, otherwise, no.
//
Function DataAreaLocked(Val DataArea) Export
	
	Var_Key = CreateAuxiliaryDataInformationRegisterEntryKey(
	    InformationRegisters.DataAreas,
	    New Structure(AuxiliaryDataSeparator(), DataArea));
	
	Try
		
		LockDataForEdit(Var_Key);
		
	Except
		
		Return True;
		
	EndTry;
	
	UnlockDataForEdit(Var_Key);
	
	If Not SeparatedDataUsageAvailable() Then
		
		Try
			
			SignInToDataArea(DataArea);
			
		Except
			
			SignOutOfDataArea();
			Return True;
			
		EndTry;
		
		SignOutOfDataArea();
		
	EndIf;
	
	Return False;
	
EndFunction

// Prepares the data area for use. Starts the infobase update procedure, if necessary,
// fills in the demo data, and sets a new status in the DataAreas register.
// 
// Parameters: 
//   DataArea - Number - a separator of the data area to be prepared for use.
//   UploadFileID - UUID - file ID.
//   Variant - String - initial data option.
// 
Procedure PrepareDataAreaForUse(Val DataArea, Val UploadFileID, 
												 Val Variant = Undefined) Export
	
	If Not Users.IsFullUser(, True) Then
		Raise(NStr("ru = 'Недостаточно прав для выполнения операции';
								|en = 'Insufficient rights to perform the operation.';"));
	EndIf;
	
	SetPrivilegedMode(True);
	
	AreaKey = CreateAuxiliaryDataInformationRegisterEntryKey(
		InformationRegisters.DataAreas,
		New Structure(AuxiliaryDataSeparator(), DataArea));
	LockDataForEdit(AreaKey);
	
	Try
		RecordManager = GetDataAreaRecordManager(DataArea, Enums.DataAreaStatuses.IsNew);
		
		If CurrentRunMode() <> Undefined Then
			
			UsersInternal.AuthenticateCurrentUser();
			
		EndIf;
		
		ErrorMessage = "";
		If Not ValueIsFilled(Variant) Then
			
			ResultOfPreparation = PrepareDataAreaForUseFromUpload(DataArea, UploadFileID, 
				ErrorMessage);
			
		Else
			
			ResultOfPreparation = PrepareDataAreaForUseFromReference(DataArea, UploadFileID, 
				Variant, ErrorMessage);
				
		EndIf;
		
		ChangeAreaStatusAndNotifyManager(RecordManager, ResultOfPreparation, ErrorMessage);

	Except
		UnlockDataForEdit(AreaKey);
		Raise;
	EndTry;
	
	UnlockDataForEdit(AreaKey);

EndProcedure

// Copies the data of area data to another data area.
// 
// Parameters: 
//   SourceArea_1 - Number - value of data area separator of data source.
//   ReceivingArea - Number - value of data area separator of destination data.
// 
Procedure CopyAreaData(Val SourceArea_1, Val ReceivingArea) Export
	
	If Not Users.IsFullUser(, True) Then
		Raise(NStr("ru = 'Недостаточно прав для выполнения операции';
								|en = 'Insufficient rights to perform the operation.';"));
	EndIf;
	
	SetPrivilegedMode(True);
	
	SignInToDataArea(SourceArea_1);
	
	UploadFileName = Undefined;
	
	If Not Common.SubsystemExists("CloudTechnology.ExportImportDataAreas") Then
		
		CauseExceptionMissingSubsystemCTL("CloudTechnology.ExportImportDataAreas");
		
	EndIf;
	
	Try
		UploadFileName = ExportImportDataAreas.UploadCurAreaToArchive().FileName;
	Except
		WriteLogEvent(LogEventCopyingDataArea(), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		If UploadFileName <> Undefined Then
			Try
				DeleteFiles(UploadFileName);
			Except
				WriteLogEvent(LogEventCopyingDataArea(), 
					EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EndTry;
		EndIf;
		Raise;
	EndTry;
	
	SignOutOfDataArea();
	SignInToDataArea(ReceivingArea);
	
	Try
		ExportImportDataAreas.ImportCurrentAreaFromArchive(UploadFileName);
	Except
		WriteLogEvent(LogEventCopyingDataArea(), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Try
			DeleteFiles(UploadFileName);
		Except
			WriteLogEvent(LogEventCopyingDataArea(), 
				EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		Raise;
	EndTry;
	
	Try
		DeleteFiles(UploadFileName);
	Except
		WriteLogEvent(LogEventCopyingDataArea(), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

// The procedure of the same name scheduled job.
// Finds all data areas with statuses that require processing
// by the application and if necessary schedules
// a maintenance background job.
// 
Procedure DataAreaMaintenance() Export
	
	If Not DataSeparationEnabled() Then
		Return;
	EndIf;
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DataAreaMaintenance);
	
	MaximumNumberOfRepetitions = 3;
	
	SetPrivilegedMode(True);
	
	InformationRegisters.DataOfClearedArea.RecoverInformationAboutDeletedAreas();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DataAreas.DataAreaAuxiliaryData AS DataArea,
	|	DataAreas.Status AS Status,
	|	DataAreas.DataExportedID AS DataExportedID,
	|	DataAreas.Variant AS Variant
	|FROM
	|	InformationRegister.DataAreas AS DataAreas
	|WHERE
	|	DataAreas.Status IN (VALUE(Enum.DataAreaStatuses.IsNew), VALUE(Enum.DataAreaStatuses.ForDeletion))
	|	AND DataAreas.ProcessingError = FALSE
	|
	|ORDER BY
	|	DataArea";
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		Var_Key = CreateAuxiliaryDataInformationRegisterEntryKey(
			InformationRegisters.DataAreas,
			New Structure(AuxiliaryDataSeparator(), Selection.DataArea));
		
		Try
			LockDataForEdit(Var_Key);
		Except
			Continue;
		EndTry;
		
		Manager = InformationRegisters.DataAreas.CreateRecordManager();
		Manager.DataAreaAuxiliaryData = Selection.DataArea;
		Manager.Read();
		
		IsAreaClearing = Manager.Status = Enums.DataAreaStatuses.ForDeletion;
		
		If IsAreaClearing Then 
			MethodName = ClearDataAreaMethodName();
		ElsIf Manager.Status = Enums.DataAreaStatuses.IsNew Then
			MethodName = "SaaSOperations.PrepareDataAreaForUse";
		Else
			UnlockDataForEdit(Var_Key);
			Continue;
		EndIf;
		
		If Manager.Repeat < MaximumNumberOfRepetitions Then
		
			FilterJobs = New Structure;
			FilterJobs.Insert("MethodName", MethodName);
			FilterJobs.Insert("Key"     , "1");
			FilterJobs.Insert("DataArea", Selection.DataArea);
			
			Jobs = JobsQueue.GetJobs(FilterJobs);
			
			If Jobs.Count() > 0 Then
				UnlockDataForEdit(Var_Key);
				Continue;
			EndIf;
			
			Manager.Repeat = Manager.Repeat + 1;
			
			ManagerSCopy = InformationRegisters.DataAreas.CreateRecordManager();
			FillPropertyValues(ManagerSCopy, Manager);
			Manager = ManagerSCopy;
			
			Manager.Write();
			
			If IsAreaClearing Then
				
				CreateTaskToClearDataArea(Selection.DataArea);
				
			Else

				MethodParameters = New Array;
				MethodParameters.Add(Selection.DataArea);
				MethodParameters.Add(Selection.DataExportedID);
				
				If ValueIsFilled(Selection.Variant) Then
					MethodParameters.Add(Selection.Variant);
				EndIf;
				
				JobParameters = New Structure;
				JobParameters.Insert("MethodName", MethodName);
				JobParameters.Insert("Parameters", MethodParameters);
				JobParameters.Insert("Key", "1");
				JobParameters.Insert("DataArea", Selection.DataArea);
				JobParameters.Insert("ExclusiveExecution", True);
							
				JobsQueue.AddJob(JobParameters);
				
			EndIf;
			
			UnlockDataForEdit(Var_Key);
			
		Else
			
			ChangeAreaStatusAndNotifyManager(Manager, ?(Manager.Status = Enums.DataAreaStatuses.IsNew,
				"FatalError", "DeletionError"), NStr("ru = 'Исчерпано количество попыток обработки области';
															|en = 'Number of attempts to process the area is up';"));
			
			UnlockDataForEdit(Var_Key);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns the web service proxy for syncing administrative operations on the service.
// The calling code must set the privilege mode.
// 
// Parameters:
//  UserPassword - String - password for connection.
// 
// Returns: 
//   WSProxy - service manager proxy. 
// 
Function GetProxyServiceManager(Val UserPassword = Undefined) Export
	
	AuthorizationParameters = RemoteAdministrationCTLInternal.AuthorizationParametersForManagingApplication(UserPassword);
	MaxVersion = RemoteAdministrationCTLInternal.VersionOfManagementApplicationServiceUsed(AuthorizationParameters);
	If CommonClientServer.CompareVersions(MaxVersion, "1.0.3.1") < 0 Then
		Raise NStr("ru = 'Требуемая версия управляющего приложения не поддерживается.';
								|en = 'The required version of the managing application is not supported.';");
	ElsIf CommonClientServer.CompareVersions(MaxVersion, "1.0.3.5") < 0 Then
		Return RemoteAdministrationCTLInternal.ProxyServiceOfManagingApplication(AuthorizationParameters, "1.0.3.1");
	EndIf;

	Return RemoteAdministrationCTLInternal.ProxyServiceOfManagingApplication(AuthorizationParameters);
	
EndFunction

// Deprecated. Depending on the case, use one of the following procedures:
// See SaaSOperations.SignInToDataArea 
// See SaaSOperations.SignOutOfDataArea
//
// Parameters:
//  Use - Boolean - a flag that shows whether the DataArea separator is used in the session.
//  DataArea - Number - DataArea separator value.
//
Procedure SetSessionSeparation(Val Use = Undefined, Val DataArea = Undefined) Export
	
	If Not SessionWithoutSeparators() Then
		Raise(NStr("ru = 'Изменить разделение сеанса возможно только из сеанса запущенного без указания разделителей';
								|en = 'Changing separation settings is only allowed from sessions started without separation';"));
	EndIf;
	
	SetPrivilegedMode(True);
	
	If DataArea <> Undefined Then
		If SessionParameters.DataAreaUsage Then
			// If enabled, exit the area to log authorization errors to the shared sessions log. 
			// 
			SessionParameters.DataAreaUsage = False;
			OnChangeDataArea();
			SessionParameters.DataAreaValue = DataArea;
			SessionParameters.DataAreaUsage = True;
		Else
			SessionParameters.DataAreaValue = DataArea;
		EndIf;
	EndIf;
	
	If Use <> Undefined Then
		SessionParameters.DataAreaUsage = Use;
	EndIf;
	
	OnChangeDataArea();
	
EndProcedure

// Signs in to a data area. Applicable only for shared sessions.
// 
// Parameters:
// 	DataArea - Number - 
Procedure SignInToDataArea(Val DataArea) Export
	
	If Not SessionWithoutSeparators() Then
		Raise(NStr("ru = 'Изменить разделение сеанса возможно только из сеанса запущенного без указания разделителей';
								|en = 'Changing separation settings is only allowed from sessions started without separation';"));
	EndIf;
	
	If DataArea <= 0 Then
		Raise(NStr("ru = 'Номер области должен быть больше 0';
								|en = 'Area number must be greater than 0';"));
	EndIf;
	
	SetPrivilegedMode(True);
	
	If SessionParameters.DataAreaUsage Then
		Raise NStr("ru = 'Перед входом в новую область данных, нужно выйти из предыдущей';
								|en = 'Before logging in to a new data area, log out of the previous one';");
	EndIf;
	
	SessionParameters.DataAreaValue = DataArea;
	SessionParameters.DataAreaUsage = True;
	
	OnChangeDataArea();
	
EndProcedure

// Signs out of a data area.
//
Procedure SignOutOfDataArea() Export
	
	If Not SessionWithoutSeparators() Then
		Raise(NStr("ru = 'Изменить разделение сеанса возможно только из сеанса запущенного без указания разделителей';
								|en = 'Changing separation settings is only allowed from sessions started without separation';"));
	EndIf;
	
	SetPrivilegedMode(True);
	
	SessionParameters.DataAreaUsage = False;
	SessionParameters.DataAreaValue = 0;
	
	OnChangeDataArea();
	
EndProcedure

// Returns a value of the current data area separator.
// An error occurs if the value is not set.
// 
// Returns: 
//   Number - value of the current data area separator. 
// 
Function SessionSeparatorValue() Export
	
	If Not DataSeparationEnabled() Then
		Return 0;
	Else
		If Not SessionSeparatorUsage() Then
			Raise(NStr("ru = 'Не установлено значение разделителя';
									|en = 'The separator value is not specified.';"));
		EndIf;
		
		// Getting value of the current data area separator.
		Return SessionParameters.DataAreaValue;
	EndIf;
	
EndFunction

// Returns the flag that shows whether DataArea separator is used.
//
// Returns: 
//  Boolean - if True if, separation is used, otherwise, False.
//
Function SessionSeparatorUsage() Export
	
	Return SessionParameters.DataAreaUsage;
	
EndFunction

// Adds parameter details to the parameter table by the constant name.
// Returns the added parameter.
//
// Parameters: 
//   ParametersTable - See IBParameters
//   ConstantName - String - name of the constant to be added to the infobase parameters.
//
// Returns: 
//   ValueTableRow - Details of the added parameter.:
//    * Name - String
//    * LongDesc - String
//    * Type - TypeDescription
// 
Function AddConstantToInformationSecurityParameterTable(Val ParametersTable, Val ConstantName) Export
	
	MetadataConstants = Metadata.Constants[ConstantName]; // MetadataObjectConstant
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = MetadataConstants.Name;
	ParameterString.LongDesc = MetadataConstants.Presentation();
	ParameterString.Type = MetadataConstants.Type;
	
	Return ParameterString;
	
EndFunction

// Gets an application name as set by the subscriber.
//
// Returns:
//   String - application name.
//
Function GetAppName() Export
	
	SetPrivilegedMode(True);
	Return Constants.DataAreaPresentation.Get();
	
EndFunction

// Returns the block size in MB to transfer a large file in parts.
//
// Returns:
//   Number - file transfer block size in megabytes.
//
Function GetFileTransferBlockSize() Export
	
	SetPrivilegedMode(True);
	
	FileTransferBlockSize = Constants.FileTransferBlockSize.Get(); // MB.
	If Not ValueIsFilled(FileTransferBlockSize) Then
		FileTransferBlockSize = 20;
	EndIf;
	Return FileTransferBlockSize;

EndFunction

// Serializes a structural type object.
//
// Parameters:
//   MeaningOfStructuralType - Array, Structure, Map - serialized object.
//
// Returns:
//   String - a serialized value of a structure type object.
//
Function WriteStructureObjectXDTOToString(Val MeaningOfStructuralType) Export
	
	XDTODataObject = StructuralObjectToXDTOObject(MeaningOfStructuralType);
	
	Return WriteValueToString(XDTODataObject);
	
EndFunction

// Encodes a string value using the Base64 algorithm.
//
// Parameters:
//   String - String - original string to be encoded.
//
// Returns:
//   String - encoded string.
//
Function LineInBase64(Val String) Export
	
	Store = New ValueStorage(String, New Deflation(9));
	
	Return XMLString(Store);
	
EndFunction

// Decodes Base64 presentation of the string into the original value.
//
// Parameters:
//   Base64Row - String - original string to be decoded.
//
// Returns:
//   String - decoded string.
//
Function Base64BString(Val Base64Row) Export
	
	Store = XMLValue(Type("ValueStorage"), Base64Row);
	
	Return Store.Get();
	
EndFunction

// Returns the data area time zone.
// Is intended to be called from the sessions where the separation
// is disabled. In the sessions where the separation is enabled,
// use GetInfobaseTimeZone() instead.
//
// Parameters:
//  DataArea - Number - separator of the data area whose time
//   zone is retrieved.
//
// Returns:
//  String, Undefined - a data area time zone, Undefined
//   if the time zone is not specified.
//
Function GetTimeZoneOfDataArea(Val DataArea) Export
	
	Manager = Constants.DataAreaTimeZone.CreateValueManager();
	Manager.DataAreaAuxiliaryData = DataArea;
	Manager.Read();
	TimeZone = Manager.Value;
	
	If Not ValueIsFilled(TimeZone) Then
		TimeZone = Undefined;
	EndIf;
	
	Return TimeZone;
	
EndFunction

// Returns the flag indicating whether the Service Manager has a configured endpoint.
//
// Returns:
//  Boolean - If True, the endpoint is configured and the username is assigned a value in the transport settings.
//
Function ServiceManagerEndpointConfigured() Export
	
	Result = False;
	
	Endpoint = ServiceManagerEndpoint();
	If ValueIsFilled(Endpoint) Then
		SettingsStructure_ = InformationRegisters.MessageExchangeTransportSettings.TransportSettingsWS(Endpoint);
		
		Result = ValueIsFilled(SettingsStructure_.WSUserName)
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the internal Service Manager URL.
//
// Returns:
//  String - Internal Service Manager URL.
//
Function InternalServiceManagerURL() Export
	
	Return SaaSOperationsCTL.InternalServiceManagerURL();
	
EndFunction

// Returns the username of the Service Manager utility user.
// The calling code must set the privilege mode.
//
// Returns:
//  String - Username of the Service Manager utility user.
//
Function ServiceManagerInternalUserName() Export
	
	Return SaaSOperationsCTL.ServiceManagerInternalUserName();
	
EndFunction

// Returns the password of the Service Manager utility user.
// The calling code must set the privilege mode.
//
// Returns:
//  String - Password of the Service Manager utility user.
//
Function ServiceManagerInternalUserPassword() Export
	
	Return SaaSOperationsCTL.ServiceManagerInternalUserPassword();
	
EndFunction

// Handles web service errors.
// If the passed error info is not empty, writes
// the error details to the event log and raises
// an exception with the brief error description.
//
// Parameters:
//   ErrorInfo - ErrorInfo - error details,
//   SubsystemName - String - subsystem name,
//   WebServiceName - String - web service name,
//   OperationName - String - operation name.
//
Procedure HandleWebServiceErrorInfo(Val ErrorInfo, Val SubsystemName = "", Val WebServiceName = "", Val OperationName = "") Export
	
	If ErrorInfo = Undefined Then
		Return;
	EndIf;
	
	If IsBlankString(SubsystemName) Then
		SubsystemName = Metadata.Subsystems.CloudTechnology.Name;
	EndIf;
	
	EventName = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = '%1.Ошибка вызова операции web-сервиса';
			|en = '%1.Error calling the web service operation';", Common.DefaultLanguageCode()),
		SubsystemName);
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Ошибка при вызове операции %1 веб-сервиса %2: %3';
			|en = 'An error occurred when calling operation %1 of web service %2: %3';", Common.DefaultLanguageCode()),
		OperationName,
		WebServiceName,
		ErrorInfo.DetailErrorDescription);
	
	WriteLogEvent(
		EventName,
		EventLogLevel.Error,
		,
		,
		ErrorText);
		
	Raise ErrorInfo.BriefErrorDescription;
	
EndProcedure

// Returns the user alias to be used in the interface.
//
// Parameters:
//   UserIdentificator - UUID - user ID.
//
// Returns:
//   String - Infobase user alias to be shown in interface.
//
Function AliasOfUserOfInformationBase(Val UserIdentificator) Export
	
	Alias = "";
	
	CTLSubsystemsIntegration.OnDefineUserAlias(UserIdentificator, Alias);
	Return Alias;
	
EndFunction

// Gets the record manager for the DataAreas register in the transaction.
//
// Parameters:
//  DataArea - Number - data area number.
//  Status - EnumRef.DataAreaStatuses - expected data area status.
//
// Returns:
//  InformationRegisterRecordManager.DataAreas - a data area record manager.
//
Function GetDataAreaRecordManager(Val DataArea, Val Status) Export
	
	BeginTransaction();
	Try
		Block = New DataLock;
		Item = Block.Add("InformationRegister.DataAreas");
		Item.SetValue("DataAreaAuxiliaryData", DataArea);
		Item.Mode = DataLockMode.Shared;
		Block.Lock();
		
		RecordManager = InformationRegisters.DataAreas.CreateRecordManager();
		RecordManager.DataAreaAuxiliaryData = DataArea;
		RecordManager.Read();
		
		If Not RecordManager.Selected() Then
			MessageTemplate = NStr("ru = 'Область данных %1 не найдена';
									|en = '%1 data area is not found';");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, DataArea);
			Raise(MessageText);
		ElsIf RecordManager.Status <> Status Then
			MessageTemplate = NStr("ru = 'Статус области данных %1 не равен ""%2""';
									|en = 'Status of data area %1 is not ""%2""';");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, DataArea, Status);
			Raise(MessageText);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(LogEventPreparingDataArea(), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
	Return RecordManager;
	
EndFunction

// Imports data into the "standard" area.
// 
// Parameters: 
//   DataArea - Number - number of the data area to be filled.
//   UploadFileID - UUID - initial data file ID.
//   Variant - String - initial data option.
//   ErrorMessage - String - an error description (the return value).
//
// Returns:
//  String - "Success" or "FatalError".
//
Function PrepareDataAreaForUseFromReference(Val DataArea, Val UploadFileID, 
												 		  Val Variant, ErrorMessage) Export
	
	If Constants.CopyDataAreasFromPrototype.Get() Then
		
		Result = ImportAreaFormSuppliedData(DataArea, UploadFileID, Variant, ErrorMessage);
		If Result <> "Success" Then
			Return Result;
		EndIf;
		
	Else
		
		Result = "Success";
		
	EndIf;
	
	InfobaseUpdate.UpdateInfobase();
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Shared data control.

// The handler of the CheckSharedObjectsOnWrite event subscription.
//
Procedure CheckSharedObjectsOnWrite(Source, Cancel) Export
	
	// No need to run "DataExchange.Load".
	// Writing shared data from a separated session is prohibited.
	ControlOfUnsharedDataWhenWriting(Source);
	
EndProcedure

// The handler of the CheckSharedRecordsSetsOnWrite event subscription.
//
Procedure CheckSharedRecordsSetsOnWrite(Source, Cancel, Replacing) Export
	
	// No need to run "DataExchange.Load".
	// Writing shared data from a separated session is prohibited.
	ControlOfUnsharedDataWhenWriting(Source);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// File management

// Returns the full name of the file received from the Service Manager file storage by file ID.
//
// Parameters:
//   FileID_ - UUID - File ID in the Service Manager file storage.
//
// Returns:
//   String - a full name of the extracted file.
//
Function GetFileFromServiceManagerStorage(Val FileID_) Export

	CauseExceptionMissingExtensionCTL();
	Return Undefined;

EndFunction

// Adds a file to the Service Manager storage.
//
// Parameters:
//   AddressDataFile - String - a file address in a temporary storage,
//                   - BinaryData - binary file data,
//                   - File - file.
//   FileName - String - Stored file name.
//   AdditionalParameters - Structure - data to be serialized to JSON.
//		
// Returns:
//   UUID - File ID in the storage.
//
Function PlaceFileInStorageOfServiceManager(Val AddressDataFile, Val FileName = "",
	AdditionalParameters = Undefined) Export

	CauseExceptionMissingExtensionCTL();
	Return Undefined;

EndFunction

////////////////////////////////////////////////////////////////////////////////
// Functions that determine object type by full metadata object name.
// 

// Reference data types

// Determines whether the metadata object is one of Document type objects by the full metadata
//  object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is a document.
//
Function ThisIsFullNameOfDocument(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "Document", "Document");
	
EndFunction

// Determines whether the metadata object is one of Catalog type objects by the full metadata
//  object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is a catalog.
//
Function ThisIsFullNameOfCatalog(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "Catalog", "Catalog");
	
EndFunction

// Determines whether the metadata object is one of Enumeration type objects by the full metadata
//  object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is an enumeration.
//
Function ThisIsFullNameOfEnumeration(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "Enum", "Enum");
	
EndFunction

// Determines whether the metadata object is one of Exchange plan type objects by the full metadata
//  object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is an exchange plan.
//
Function ThisIsFullNameOfExchangePlan(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "ExchangePlan", "ExchangePlan");
	
EndFunction

// Determines whether the metadata object is one of Chart of characteristic types type objects
//  by the full metadata object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is a chart of characteristic types.
//
Function ThisIsFullNameOfKindsOfCharacteristicsPlan(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "ChartOfCharacteristicTypes", "ChartOfCharacteristicTypes");
	
EndFunction

// Determines whether the metadata object is one of Business process type objects by the full metadata
//  object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is a business process.
//
Function ThisIsFullNameOfBusinessProcess(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "BusinessProcess", "BusinessProcess");
	
EndFunction

// Determines whether the metadata object is one of Task type objects by the full metadata object
//  name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
// 
// Returns:
//  Boolean - True if the object is a task.
//
Function ThisIsFullNameOfTask(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "Task", "Task");
	
EndFunction

// Determines whether the metadata object is one of Chart of accounts type objects by the full metadata object
//  name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is a chart of accounts.
//
Function ThisIsFullNameOfChartOfAccounts(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "ChartOfAccounts", "ChartOfAccounts");
	
EndFunction

// Determines whether the metadata object is one of Chart of calculation types type objects by the full metadata
//  object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is a chart of calculation types.
//
Function ThisIsFullNameOfPlanForCalculation(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "ChartOfCalculationTypes", "ChartOfCalculationTypes");
	
EndFunction

// Registers

// Determines whether the metadata object is one of Information register type objects by the full metadata
//  object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is an information register.
//
Function ThisIsFullNameOfInformationRegister(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "InformationRegister", "InformationRegister");
	
EndFunction

// Determines whether the metadata object is one of Accumulation register type objects by the full metadata
//  object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is an accumulation register.
//
Function ThisIsFullNameOfAccumulationRegister(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "AccumulationRegister", "AccumulationRegister");
	
EndFunction

// Determines whether the metadata object is one of Accounting register type objects by the full metadata
//  object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is an accounting register.
//
Function ThisIsFullNameOfAccountingRegister(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "AccountingRegister", "AccountingRegister");
	
EndFunction

// Determines whether the metadata object is one of Calculation register type objects by the full metadata
//  object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is a calculation register.
//
Function ThisIsFullNameOfCalculationRegister(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "CalculationRegister", "CalculationRegister")
		And Not ThisIsFullNameOfRecalculation(FullName);
	
EndFunction

// Recalculations

// Determines whether the metadata object is one of Recalculation type objects by the full metadata
//  object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is a recalculation.
//
Function ThisIsFullNameOfRecalculation(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "Recalculation", "Recalculation", 2);
	
EndFunction

// Constants

// Determines whether the metadata object is one of Constant type objects by the full metadata
//  object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is a constant.
//
Function ThisIsFullNameOfConstant(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "Constant", "Constant");
	
EndFunction

// Document journals

// Determines whether the metadata object is one of Document journal type objects by the full metadata
//  object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is a document journal.
//
Function ThisIsFullNameOfDocumentLog(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "DocumentJournal", "DocumentJournal");
	
EndFunction

// Sequences

// Determines whether the metadata object is one of Sequence type objects by the full metadata
//  object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is a sequence.
//
Function ThisIsFullNameOfSequence(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "Sequence", "Sequence");
	
EndFunction

// ScheduledJobs

// Determines whether the metadata object is one of Scheduled job type objects by the full metadata
//  object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is a scheduled job.
//
Function ThisIsFullNameOfRoutineAssignment(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "ScheduledJob", "ScheduledJob");
	
EndFunction

// Common

// Determines whether the metadata object is one of register type objects by the full metadata object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object is a register.
//
Function ThisIsFullRegisterName(Val FullName) Export
	
	Return ThisIsFullNameOfInformationRegister(FullName)
		Or ThisIsFullNameOfAccumulationRegister(FullName)
		Or ThisIsFullNameOfAccountingRegister(FullName)
		Or ThisIsFullNameOfCalculationRegister(FullName);
	
EndFunction

// Determines whether the metadata object is one of reference type objects by the full metadata object name.
//
// Parameters:
//  FullName - String - full name of the metadata object whose type must be compared
//   with the specified type.
//
// Returns:
//  Boolean - True if the object has a reference type.
//
Function ThisIsFullNameOfObjectOfReferenceType(Val FullName) Export
	
	Return ThisIsFullNameOfCatalog(FullName)
		Or ThisIsFullNameOfDocument(FullName)
		Or ThisIsFullNameOfBusinessProcess(FullName)
		Or ThisIsFullNameOfTask(FullName)
		Or ThisIsFullNameOfChartOfAccounts(FullName)
		Or ThisIsFullNameOfExchangePlan(FullName)
		Or ThisIsFullNameOfKindsOfCharacteristicsPlan(FullName)
		Or ThisIsFullNameOfPlanForCalculation(FullName);
	
EndFunction

// Identifies whether the metadata object supports the predefined data by a full metadata object name.
//
// Parameters:
//  FullName - String - Full name of the metadata object to identify
//   whether it supports the predefined data or not.
//
// Returns:
//  Boolean - True if the metadata object supports predefined data.
//
Function IsFullNameOfObjectWithPredefinedData(Val FullName) Export
	
	Return ThisIsFullNameOfCatalog(FullName)
		Or ThisIsFullNameOfChartOfAccounts(FullName)
		Or ThisIsFullNameOfKindsOfCharacteristicsPlan(FullName)
		Or ThisIsFullNameOfPlanForCalculation(FullName);
	
EndFunction

// Selection parameters by the full name of the metadata object.
// 
// Parameters: 
//  FullMetadataObjectName - String - Full name of a metadata object.
// 
// Returns: 
//	Structure - Dataset parameters.:
//	 * Table - String - metadata object name.
//	 * FieldNameLogger - String - a name of the recorder field.
Function SelectionParameters(Val FullMetadataObjectName) Export
	
	Result = New Structure("Table,FieldNameLogger");
	
	If ThisIsFullRegisterName(FullMetadataObjectName)
			Or ThisIsFullNameOfSequence(FullMetadataObjectName) Then
		
		Result.Table = FullMetadataObjectName;
		Result.FieldNameLogger = "Recorder";
		
	ElsIf ThisIsFullNameOfRecalculation(FullMetadataObjectName) Then
		
		Substrings = StrSplit(FullMetadataObjectName, ".");
		Result.Table = Substrings[0] + "." + Substrings[1] + "." + Substrings[3];
		Result.FieldNameLogger = "RecalculationObject";
		
	Else
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Функция %1 не должна использоваться для объекта %2.';
				|en = 'The %1 function cannot be used for the %2 object.';"),
			"SelectionParameters",
			FullMetadataObjectName);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Name of the event in the event log to record data area copy errors.
//
// Returns:
//	String - error event name.
//
Function LogEventCopyingDataArea() Export
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Работа в модели сервиса.Копирование области данных';
				|en = 'SaaS.Copy data area';", Common.DefaultLanguageCode());
	
EndFunction

// Name of the event in the event log to record data area lock errors.
//
// Returns:
//	String - error event name.
//
Function LogEventDataAreaLock() Export
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Работа в модели сервиса.Блокировка области данных';
				|en = 'SaaS.Lock data area';", Common.DefaultLanguageCode());
	
EndFunction

// Name of the event in the event log to record data area preparation errors.
//
// Returns:
//	String - error event name.
//
Function LogEventPreparingDataArea() Export
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Работа в модели сервиса.Подготовка области данных';
				|en = 'SaaS.Prepare data area';", Common.DefaultLanguageCode());
	
EndFunction

// Name of the event in the event log to record errors occurred while receiving file form storage.
//
// Returns:
//	String - error event name.
//
Function LogEventRetrievingFileFromStorage() Export
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Работа в модели сервиса.Получение файла из хранилища';
				|en = 'SaaS.Get file from storage';", Common.DefaultLanguageCode());
	
EndFunction

// Name of the event in the event log to record errors occurred while adding file on exchange through the file system.
//
// Returns:
//	String - error event name.
//
Function LogEventAddFileExchangeViaFS() Export
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Работа в модели сервиса.Добавление файла.Обмен через ФС';
				|en = 'SaaS.Add file.Exchange using file system';", Common.DefaultLanguageCode());
	
EndFunction

// Name of the event in the event log to record errors occurred while adding file on exchange not through the file system.
//
// Returns:
//	String - error event name.
//
Function LogEventAddFileExchangeNotViaFS() Export
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Работа в модели сервиса.Добавление файла.Обмен не через ФС';
				|en = 'SaaS.Add file.Exchange not using file system';", Common.DefaultLanguageCode());
	
EndFunction

// Name of the event in the event log to record errors occurred while deleting the temporary file.
//
// Returns:
//	String - error event name.
//
Function TempFileDeletionEventLogEvent() Export
	
	// @skip-check module-nstr-camelcase - Check error.
	Return NStr("ru = 'Работа в модели сервиса.Удаление временного файла';
				|en = 'SaaS.Delete temporary file';", Common.DefaultLanguageCode());
	
EndFunction

// Miscellaneous.

// See SaaSOperationsOverridable.OnFillIIBParametersTable.
// Parameters:
// 	ParametersTable - See IBParameters
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	
	If IsSeparatedConfiguration() Then
		AddConstantToInformationSecurityParameterTable(ParametersTable, "UseSeparationByDataAreas");
		
		AddConstantToInformationSecurityParameterTable(ParametersTable, "InfobaseUsageMode");
		
		AddConstantToInformationSecurityParameterTable(ParametersTable, "CopyDataAreasFromPrototype");
		
		AddConstantToInformationSecurityParameterTable(ParametersTable, "CloseSessionsWithoutWarningByDefaultSaaS");
		
	EndIf;
	
	AddConstantToInformationSecurityParameterTable(ParametersTable, "InternalServiceManagerURL");
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "InternalServiceManagerURL";
	ParameterString.LongDesc = NStr("ru = 'Внутренний адрес Менеджера сервиса';
									|en = 'Internal Service Manager URL';");
	ParameterString.Type = New TypeDescription("String");
	
	// URLService is required for compatibility with earlier versions.
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "URLOfService";
	ParameterString.LongDesc = NStr("ru = 'Внутренний адрес Менеджера сервиса';
									|en = 'Internal Service Manager URL';");
	ParameterString.Type = New TypeDescription("String");
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "ServiceManagerInternalUserName";
	ParameterString.LongDesc = "ServiceManagerInternalUserName";
	ParameterString.Type = New TypeDescription("String");
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "ServiceManagerInternalUserPassword";
	ParameterString.LongDesc = "ServiceManagerInternalUserPassword";
	ParameterString.Type = New TypeDescription("String");
	ParameterString.ForbiddenReading = True;
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "InternalServiceUserName";
	ParameterString.LongDesc = "InternalServiceUserName";
	ParameterString.Type = New TypeDescription("String");
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "InternalServiceUserPassword";
	ParameterString.LongDesc = "InternalServiceUserPassword";
	ParameterString.Type = New TypeDescription("String");
	ParameterString.ForbiddenReading = True;
	// End For obsolete version compatibility.
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "ConfigurationVersion";
	ParameterString.LongDesc = NStr("ru = 'Версия конфигурации';
									|en = 'Configuration version';");
	ParameterString.RecordBan = True;
	ParameterString.Type = New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable));
	
	AddConstantToInformationSecurityParameterTable(
		ParametersTable,
		"SetPriorityOfDataProcessingInSpecifiedTimeInterval");
	AddConstantToInformationSecurityParameterTable(
		ParametersTable,
		"BeginningOfDataProcessingPriorityTimeInterval");
	AddConstantToInformationSecurityParameterTable(
		ParametersTable,
		"EndOfDataProcessingPriorityTimeInterval");
	
	NumberOfUpdateThreadsConstantName = "InfobaseUpdateThreadCount";
	If Metadata.Constants.Find(NumberOfUpdateThreadsConstantName) <> Undefined Then
		AddConstantToInformationSecurityParameterTable(
			ParametersTable,
			NumberOfUpdateThreadsConstantName);
	EndIf;
	
	CTLSubsystemsIntegration.OnFillIIBParametersTable(ParametersTable);
	
EndProcedure

// Writes the test file to the hard drive returning its name and size.
// The calling side must delete this file.
//
// Returns:
//   String - a test file name without a path.
//
Function RecordTrialFile() Export
	
	NewID = New UUID;
	FileProperties = New File(FilesCTL.SharedDirectoryOfTemporaryFiles() + NewID + ".tmp");
	
	Text = New TextWriter(FileProperties.FullName, TextEncoding.ANSI);
	Text.Write(NewID);
	Text.Close();
	
	Return FileProperties.Name;
	
EndFunction

// Additional actions when changing session separation.
//
Procedure OnChangeDataArea() Export
	
	ClearAllSessionParametersExceptDelimiters();
	
	If CurrentRunMode() <> Undefined 
		And SeparatedDataUsageAvailable() Then
		
		RecordManager = InformationRegisters.DataAreas.CreateRecordManager();
		RecordManager.Read();
		
		If RecordManager.Selected() Then
			
			If Not (RecordManager.ProcessingError
				Or RecordManager.Status = Enums.DataAreaStatuses.ForDeletion
				Or RecordManager.Status = Enums.DataAreaStatuses.isDeleted) Then
		
				AuthenticateCurrentUser();
			EndIf;
			
		Else
			AuthenticateCurrentUser();	
		EndIf;
		
	EndIf;
	
EndProcedure

// Registers default master data handlers for the day and for all time.
//
// Parameters:
//   Handlers - ValueTable - a table of handlers.
//
Procedure RegisterSuppliedDataHandlers(Val Handlers) Export
	
	Handler = Handlers.Add();
	Handler.DataKind = "DataAreaPrototype";
	Handler.HandlerCode = "DataAreaPrototype";
	Handler.Handler = SaaSOperations;
	
EndProcedure

// The procedure is called when a new data notification is received.
// In the procedure body, check whether the application requires this data. 
// If it requires, select the Import check box.
// 
// Parameters:
//   Descriptor - XDTODataObject, Structure - Descriptor.
//   ToImport - Boolean - If True, run import. Otherwise, False.
//	 JSONDescriptor - Boolean - indicates that the descriptor was obtained in the JSON format
//
Procedure NewDataAvailable(Val Descriptor, ToImport, Val JSONDescriptor = False) Export
	
	If Descriptor.DataType = "DataAreaPrototype" Then
		ConfigurationNameCondition = False;
		ConfigurationVersionCondition = False;
		For Each Characteristic In Descriptor.Properties.Property Do
			If Not ConfigurationNameCondition Then
				ConfigurationNameCondition = Characteristic.Code = "ConfigurationName" And Characteristic.Value = Metadata.Name;
			EndIf;
			If Not ConfigurationVersionCondition Then
				ConfigurationVersionCondition = Characteristic.Code = "ConfigurationVersion"
					And CommonClientServer.CompareVersions(Characteristic.Value, Metadata.Version) >= 0;
			EndIf;
		EndDo;
		ToImport = ConfigurationNameCondition And ConfigurationVersionCondition;
	EndIf;
	
EndProcedure

// The procedure is called when a new data notification is received.
// In the procedure body, check whether the application requires this data. 
// If it requires, select the Import check box.
// 
// Parameters:
//   Descriptor - Structure - Descriptor.
//   ToImport - Boolean - If True, run import. Otherwise, False.
//
Procedure NewJSONDataAvailable(Val Descriptor, ToImport) Export
	
	NewDataAvailable(Descriptor, ToImport, True);
	
EndProcedure

// The procedure is called after calling NewDataAvailable, it parses the data.
//
// Parameters:
//   Descriptor - XDTODataObject, Structure - Descriptor.
//   PathToFile - String - Full name of the extracted file. 
//                  The file is automatically deleted once the procedure is completed.
//                  If a file is not specified, it is set to Undefined.
//	 JSONDescriptor - Boolean - indicates that the descriptor was obtained in the JSON format
//
Procedure ProcessNewData(Val Descriptor, Val PathToFile, Val JSONDescriptor = False) Export
	
	If Descriptor.DataType = "DataAreaPrototype" Then
		ProcessSuppliedConfigurationReference(Descriptor, PathToFile);
	EndIf;
	
EndProcedure

// The procedure is called after calling NewDataAvailable, it parses the data.
//
// Parameters:
//   Descriptor - Structure - Descriptor.
//   PathToFile - String - Full name of the extracted file. 
//                  The file is automatically deleted once the procedure is completed.
//                  If a file is not specified, it is set to Undefined.
//
Procedure ProcessNewJSONData(Val Descriptor, Val PathToFile) Export
	
	ProcessNewData(Descriptor, PathToFile, True);
	
EndProcedure

// The procedure is called if data processing is canceled due to an error.
//
// Parameters:
//   Descriptor - XDTODataObject - Descriptor.
//
Procedure DataProcessingCanceled(Val Descriptor) Export 
	Return;	
EndProcedure

// For SaaSCached common module.

// Determines if the session is started with separators.
//
// Returns:
//   Boolean - True if the session is started without separators.
//
Function SessionWithoutSeparators() Export
	
	Return InfoBaseUsers.CurrentUser().DataSeparation.Count() = 0;
	
EndFunction

// Returns a flag indicating if there are any common separators in the configuration.
//
// Returns:
//   Boolean - True if the configuration is separated.
//
Function IsSeparatedConfiguration() Export
	
	Return SaaSOperationsCached.IsSeparatedConfiguration();
	
EndFunction

// Returns a flag that shows whether the metadata object is used in common separators.
//
// Parameters:
//   MetadataObject - String - metadata object name.
//   Separator - String - a name of the common separator attribute that is checked if it separates the metadata object.
//
// Returns:
//   Boolean - True if the object is separated.
//
Function IsSeparatedMetadataObject(Val MetadataObject, Val Separator = Undefined) Export
	
	If TypeOf(MetadataObject) = Type("String") Then
		FullMetadataObjectName = MetadataObject;
	Else
		FullMetadataObjectName = MetadataObject.FullName();
	EndIf;
	
	Return SaaSOperationsCached.IsSeparatedMetadataObject(FullMetadataObjectName, Separator);
	
EndFunction

// Returns an array of serialized structural types currently supported.
//
// Returns:
//   FixedArray of Type - Array From Types.
//
Function SerializableStructuralTypes() Export
	
	Return SaaSOperationsCached.SerializableStructuralTypes();
	
EndFunction

// Returns the endpoint for sending messages to the Service Manager.
//
// Returns:
//  ExchangePlanRef.MessagesExchange - node matching the service manager.
//
Function ServiceManagerEndpoint() Export
	
	Return SaaSOperationsCTL.ServiceManagerEndpoint();
	
EndFunction

// Returns mapping between user contact information kinds and kinds.
// Contact information used in the XDTO SaaS.
//
// Returns:
//  Map of KeyAndValue- Contact information kind mapping.:
//  * Key - CatalogRef.ContactInformationKinds
//  * Value - String
//
Function MatchingUserSAITypesToXDTO() Export
	
	Return SaaSOperationsCached.MatchingUserSAITypesToXDTO();
	
EndFunction

// Returns mapping between user contact information kinds and custom XDTO kinds.
// 
// Returns: 
//  Map of KeyAndValue -- Contact information kind mapping.:
//  * Key - String
//  * Value - CatalogRef.ContactInformationKinds
Function ComplianceOfKixdtoTypesWithUserKiTypes() Export
	
	Return SaaSOperationsCached.ComplianceOfKixdtoTypesWithUserKiTypes();
	
EndFunction

// Returns mapping between XDTO rights used in SaaS and possible
// actions with SaaS user.
// 
// Returns:
//  Map of KeyAndValue - Mapping between rights and actions:
//  * Key - String
//  * Value - String
//
Function ComplianceOfXDTORightsWithActionsWithServiceUser() Export
	
	Return SaaSOperationsCached.ComplianceOfXDTORightsWithActionsWithServiceUser();
	
EndFunction

// Returns data model details of data area.
//
// Returns:
//  FixedMap of KeyAndValue - Area data model.:
//    * Key - MetadataObject - Metadata object.
//    * Value - String - a name of the common attribute separator.
//
Function GetAreaDataModel() Export
	
	Return SaaSOperationsCached.GetAreaDataModel();
	
EndFunction

// Returns an array of the separators that are in the configuration.
//
// Returns:
//   FixedArray of String - an array of names of common attributes which
//     serve as separators.
//
Function ConfigurationSeparators() Export
	
	Return SaaSOperationsCached.ConfigurationSeparators();
	
EndFunction

// Returns the common attribute content by the passed name.
//
// Parameters:
//   Name - String - a name of a common attribute.
//
// Returns:
//   CommonAttributeContent - list of metadata objects that include the common attribute.
//
Function CommonAttributeContent(Val Name) Export
	
	Return SaaSOperationsCached.CommonAttributeContent(Name);
	
EndFunction

// Returns a data area status.
//
// Parameters:
//  DataArea -  Number - separator of the data area 
//   whose status is retrieved.
//
// Returns:
//  EnumRef.DataAreaStatuses - data area status.
//
Function DataAreaStatus(DataArea) Export
	
	Query = New Query;
	Query.Text =
		"SELECT TOP 1
		|	DataAreas.Status AS Status
		|FROM
		|	InformationRegister.DataAreas AS DataAreas
		|WHERE
		|	DataAreas.DataAreaAuxiliaryData = &DataArea";
	Query.SetParameter("DataArea", DataArea);
	Result = Query.Execute().Unload();
	If Result.Count() = 0 Then
		Return Undefined;
	Else
		Return Result[0].Status;
	EndIf;
	
EndFunction

// Returns the infobase parameter table.
//
// Returns:
// ValueTable - Infobase parameters. Contains the following columns:
//  * Name - String - a parameter name.
//  * LongDesc - String - Parameter details to be displayed in the interface.
//  * ForbiddenReading - Boolean - Unreadable parameter flag. For example, can be set for passwords.
//                            
//  * RecordBan - Boolean - Immutable parameter flag.
//  * Type - TypeDescription - Parameter value type.
//                          Valid are primitive types and enumerations that exist in the managed application.
//
Function IBParameters() Export
	
	ParametersTable = InformationSecurityParameterTemplate();
	
	OnFillIIBParametersTable(ParametersTable);
	
	SaaSOperationsOverridable.OnFillIIBParametersTable(ParametersTable);
	
	Return ParametersTable;
	
EndFunction

// Returns a flag that shows whether user modification is available.
//
// Returns:
// 	Boolean - True if user modification is available. Otherwise, False.
//
Function CanChangeUsers() Export
	
	Return Constants.InfobaseUsageMode.Get() 
		<> Enums.InfobaseUsageModes.Demo;
	
EndFunction

// Returns a collection of data areas being used.
//
// Returns:
//   QueryResult - a result of a query containing a list of data areas.
//
Function DataAreasUsed() Export
	Query = New Query();
	Query.Text = 
	"SELECT
	|	DataAreas.DataAreaAuxiliaryData AS DataArea
	|FROM
	|	InformationRegister.DataAreas AS DataAreas
	|WHERE
	|	DataAreas.Status = VALUE(Enum.DataAreaStatuses.Used)
	|ORDER BY
	|	DataArea";
	
	Result = Query.Execute();
	
	Return Result;
EndFunction

// Creates the record key for the information register included in the DataAreaAuxiliaryData separator content.
//
// Parameters:
//  Manager - InformationRegisterManager - an information register manager whose record key is created,
//  KeyValues - Structure - a structure containing values used for filling record key properties.
//                              Structure item names must correspond with the names of key fields.
//
// Returns:
//  InformationRegisterRecordKeyInformationRegisterName - a record key.
//
Function CreateAuxiliaryDataInformationRegisterEntryKey(Val Manager, Val KeyValues) Export
	
	Var_Key = Manager.CreateRecordKey(KeyValues);
	
	DataArea = Undefined;
	Separator = AuxiliaryDataSeparator();
	
	If KeyValues.Property(Separator, DataArea) Then
		
		If Var_Key[Separator] <> DataArea Then
			
			Object = XDTOSerializer.WriteXDTO(Var_Key);
			Object[Separator] = DataArea;
			Var_Key = XDTOSerializer.ReadXDTO(Object);
			
		EndIf;
		
	EndIf;
	
	Return Var_Key;
	
EndFunction

// Sets a flag of user activity in the current area.
// A flag is a value of jointly separated LastClientSessionStartDate constant.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure SetUserActivityFlagInArea() Export
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated. Obsolete. Use the SetExclusiveMode(True) platform method.
//
// Parameters:
//  CheckNoOtherSessions - Boolean - flag that shows whether a search for other user sessions.
//  SharedLocking - Boolean - this lock is separated.
//
Procedure LockCurDataArea(Val CheckNoOtherSessions = False, Val SharedLocking = False) Export
	
	If Not SeparatedDataUsageAvailable() Then
		Raise(NStr("ru = 'Блокировка области может быть установлена только при включенном использовании разделителей';
								|en = 'Area can be locked only when separator usage is enabled';"));
	EndIf;
	
	Var_Key = CreateAuxiliaryDataInformationRegisterEntryKey(
		InformationRegisters.DataAreas,
		New Structure(AuxiliaryDataSeparator(), SessionSeparatorValue()));
	
	AttemptsNumber = 5;
	CurrentAttempt = 0;
	While True Do
		Try
			LockDataForEdit(Var_Key);
			Break;
		Except
			CurrentAttempt = CurrentAttempt + 1;
			
			If CurrentAttempt = AttemptsNumber Then
				CommentTemplate = NStr("ru = 'Не удалось установить блокировку области данных по причине:
					|%1';
					|en = 'Cannot lock the data area due to:
					|%1';");
				CommentText1 = StringFunctionsClientServer.SubstituteParametersToString(
					CommentTemplate, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				WriteLogEvent(LogEventDataAreaLock(),
					EventLogLevel.Error,
					,
					,
					CommentText1);
					
				TextTemplate1 = NStr("ru = 'Не удалось установить блокировку области данных по причине:
					|%1';
					|en = 'Cannot lock the data area due to:
					|%1';");
				Text = StringFunctionsClientServer.SubstituteParametersToString(
					TextTemplate1, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
					
				Raise(Text);
			EndIf;
		EndTry;
	EndDo;
	
	If CheckNoOtherSessions Then
		
		ConflictingSessions = New Array; // Array of InfoBaseSession
		
		For Each Session In GetInfoBaseSessions() Do
			If Session.SessionNumber = InfoBaseSessionNumber() Then
				Continue;
			EndIf;
			
			ClientApplications = New Array;
			ClientApplications.Add(Upper("1CV8"));
			ClientApplications.Add(Upper("1CV8C"));
			ClientApplications.Add(Upper("WebClient"));
			ClientApplications.Add(Upper("COMConnection"));
			ClientApplications.Add(Upper("WSConnection"));
			ClientApplications.Add(Upper("BackgroundJob"));
			If ClientApplications.Find(Upper(Session.ApplicationName)) = Undefined Then
				Continue;
			EndIf;
			
			ConflictingSessions.Add(Session);
			
		EndDo;
		
		If ConflictingSessions.Count() > 0 Then
			
			UnlockDataForEdit(Var_Key);
			
			TextSessions = "";
			For Each ConflictingSession In ConflictingSessions Do
				
				If Not IsBlankString(TextSessions) Then
					TextSessions = TextSessions + ", ";
				EndIf;
				
				TextSessions = TextSessions + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '%1 (сеанс - %2)';
						|en = '%1 (session %2)';", Common.DefaultLanguageCode()),
					ConflictingSession.User.Name,
					Format(ConflictingSession.SessionNumber, "NG=0"));
				
			EndDo;
			
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Операция не может быть выполнена, т.к. в приложении работают другие пользователи: %1';
					|en = 'Operation cannot be performed as other users are using the application: %1';",
					Common.DefaultLanguageCode()),
				TextSessions);
				
			Raise ExceptionText;
			
		EndIf;
		
	EndIf;
	
	If Not SharedLocking Then
		SetExclusiveMode(True);
		Return;
	EndIf;
	
	DataModel = SaaSOperationsCached.GetAreaDataModel();
	
	Block = New DataLock;
	
	For Each ModelItem In DataModel Do
		
		FullMetadataObjectName = ModelItem.Key;
		MetadataObjectDetails = ModelItem.Value; // MetadataObject
		
		LockSpace = FullMetadataObjectName;
		
		If ThisIsFullRegisterName(FullMetadataObjectName) Then
			
			BlockSets = True;
			If ThisIsFullNameOfInformationRegister(FullMetadataObjectName) Then
				AreaMetadataObject = Metadata.InformationRegisters.Find(MetadataObjectDetails.Name);
				If AreaMetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
					BlockSets = False;
				EndIf;
			EndIf;
			
			If BlockSets Then
				LockSpace = LockSpace + ".RecordSet";
			EndIf;
			
		ElsIf ThisIsFullNameOfSequence(FullMetadataObjectName) Then
			
			LockSpace = LockSpace + ".Records";
			
		ElsIf ThisIsFullNameOfDocumentLog(FullMetadataObjectName)
				Or ThisIsFullNameOfEnumeration(FullMetadataObjectName)
				Or ThisIsFullNameOfSequence(FullMetadataObjectName)
				Or ThisIsFullNameOfRoutineAssignment(FullMetadataObjectName) Then
			
			Continue;
			
		EndIf;
		
		LockItem = Block.Add(LockSpace);
		
		If SharedLocking Then
			
			LockItem.Mode = DataLockMode.Shared;
			
		EndIf;
		
	EndDo;
	
	Block.Lock();
	
EndProcedure

// Deprecated. Obsolete. Use the SetExclusiveMode(False) platform method.
Procedure UnlockCurDataArea() Export
	
	Var_Key = CreateAuxiliaryDataInformationRegisterEntryKey(
		InformationRegisters.DataAreas,
		New Structure(AuxiliaryDataSeparator(), SessionSeparatorValue()));
		
	UnlockDataForEdit(Var_Key);
	
	SetExclusiveMode(False);
	
EndProcedure

// Deprecated. Writes a value of the reference type separated by the AuxiliaryDataSeparator separator.
// Toggles session separation during the writing process.
//
// Parameters:
//  AuxiliaryDataObject - CatalogObject
//  							- ChartOfCharacteristicTypesObject
//  							- DocumentObject - an object of reference type or ObjectDeletion.
//
Procedure WriteAuxiliaryData(AuxiliaryDataObject) Export
	
	AuxiliaryDataObject.Write();
	
EndProcedure

// Deprecated. Deletes reference type values delimited with AuxiliaryDataSeparator.
// During writing, toggles the session.
//
// Parameters:
//  AuxiliaryDataObject - CatalogObject
//  							- ChartOfCharacteristicTypesObject
//  							- DocumentObject - object of reference type.
//
Procedure DeleteAuxiliaryData(AuxiliaryDataObject) Export
	
	AuxiliaryDataObject.Delete();
	
EndProcedure

// Deprecated. Obsolete. Instead, use SaaS.GetFileFromServiceManagerStorage.
// Retrieves file description by its ID in the File register.
// If disk storage and PathNotData = True, 
// Data in the result structure = Undefined, FullName = Full file name.
// Otherwise Data is binary file data, FullName - Undefined.
// The Name key value always contains the name in the storage.
//
// Parameters:
//   FileID - UUID - a file UUID.
//   ConnectionParameters - Structure - The following fields:
//							* URL - String - Mandatory service URL.
//							* UserName - String - service user name,
//							* Password - String - service user password,
//   PathInsteadOfData - Boolean - what to return,
//   CheckForExistence - Boolean - indicates whether the file existence must be checked if it cannot be retrieved.
//		
// Returns:
//   Structure - File details.:
//	   * Name - String - file name in the storage.
//	   * Data - BinaryData - file data.
//	   * FullName - String - file full name (the file is automatically deleted once the temporary file storing time is up).
//
Function GetFileFromStorage(Val FileID, Val ConnectionParameters, 
	Val PathInsteadOfData = False, Val CheckForExistence = False) Export
	
	ExecutionStarted = CurrentUniversalDate();
	
	ProxyDescription = DescriptionOfFileTransferProxyService(ConnectionParameters);
	
	ExchangeViaFS = CanBeTransmittedViaFSSServer(ProxyDescription.Proxy, ProxyDescription.ThereIsSupportFor2ndVersion);
	
	If ExchangeViaFS Then
			
		Try
			Try
				FileName = ProxyDescription.Proxy.WriteFileToFS(FileID);
			Except
				ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				If CheckForExistence And Not ProxyDescription.Proxy.FileExists(FileID) Then
					Return Undefined;
				EndIf;
				Raise ErrorDescription;
			EndTry;
			
			FileProperties = New File(FilesCTL.SharedDirectoryOfTemporaryFiles() + FileName);
			If FileProperties.Exists() Then
				FileDetails = CreateFileDescription();
				FileDetails.Name = FileProperties.Name;
				
				SizeOfReceivedFile = FileProperties.Size();
				
				If PathInsteadOfData Then
					FileDetails.Data = Undefined;
					FileDetails.FullName = FileProperties.FullName;
				Else
					FileDetails.Data = New BinaryData(FileProperties.FullName);
					FileDetails.FullName = Undefined;
					Try
						DeleteFiles(FileProperties.FullName);
					Except
						WriteLogEvent(LogEventRetrievingFileFromStorage(),
							EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
					EndTry;
				EndIf;
				
				LogFileStorageEvent(
					NStr("ru = 'Извлечение';
						|en = 'Extract';", Common.DefaultLanguageCode()),
					FileID,
					SizeOfReceivedFile,
					CurrentUniversalDate() - ExecutionStarted,
					ExchangeViaFS);
				
				Return FileDetails;
			Else
				ExchangeViaFS = False;
			EndIf;
		Except
			WriteLogEvent(LogEventRetrievingFileFromStorage(),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			ExchangeViaFS = False;
		EndTry;
			
	EndIf; // ExchangeOverFS
	
	PartCount = Undefined;
	FileTransferBlockSize = GetFileTransferBlockSize();
	Try
		If ProxyDescription.ThereIsSupportFor2ndVersion Then
			TransferID = ProxyDescription.Proxy.PrepareGetFile(FileID, FileTransferBlockSize * 1024, PartCount);
		Else
			TransferID = Undefined;
			ProxyDescription.Proxy.PrepareGetFile(FileID, FileTransferBlockSize * 1024, TransferID, PartCount);
		EndIf;
	Except
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		If CheckForExistence And Not ProxyDescription.Proxy.FileExists(FileID) Then
			Return Undefined;
		EndIf;
		Raise ErrorDescription;
	EndTry;
	
	FilesNames = New Array;
	
	BuildDirectory = CreateAssemblyDirectory();
	
	If ProxyDescription.ThereIsSupportFor2ndVersion Then
		For PartNumber = 1 To PartCount Do
			PartData = ProxyDescription.Proxy.GetFilePart(TransferID, PartNumber, PartCount);
			PartFileName = BuildDirectory + "part" + Format(PartNumber, "ND=4; NLZ=; NG=");
			If TypeOf(PartData) = Type("BinaryData") Then
				PartData.Write(PartFileName);
			EndIf;
			FilesNames.Add(PartFileName);
		EndDo;
	Else // 1st version.
		For PartNumber = 1 To PartCount Do
			PartData = Undefined;
			ProxyDescription.Proxy.GetFilePart(TransferID, PartNumber, PartData);
			PartFileName = BuildDirectory + "part" + Format(PartNumber, "ND=4; NLZ=; NG=");
			If TypeOf(PartData) = Type("BinaryData") Then
				PartData.Write(PartFileName);
			EndIf;
			FilesNames.Add(PartFileName);
		EndDo;
	EndIf;
	PartData = Undefined;
	
	ProxyDescription.Proxy.ReleaseFile(TransferID);
	
	ArchiveName = GetTempFileName("zip");
	
	Try
	
		MergeFiles(FilesNames, ArchiveName);
		FileMerged = True;
		
	Except
		
		FileMerged = False;
		WriteLogEvent(NStr("ru = 'Выполнение операции объединения файлов';
										|en = 'Merging files';", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
	EndTry;
	
	If FileMerged Then
		
		Try
		
			ZipFileReader = New ZipFileReader(ArchiveName);
			ZipFileRead = True;
			
		Except
			
			ZipFileRead = False;
			WriteLogEvent(NStr("ru = 'Выполнение операции чтения zip файла';
											|en = 'Reading zip file';", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
		EndTry;
		
		If ZipFileRead Then
			
			ResultingArchiveContainsMoreThanOneFile = ZipFileReader.Items.Count() > 1;
			
			If Not ResultingArchiveContainsMoreThanOneFile Then
				
				FileName = BuildDirectory + ZipFileReader.Items.Get(0).Name;
				ZipFileReader.Extract(ZipFileReader.Items.Get(0), BuildDirectory);
				ZipFileReader.Close();
				
				ResultFile = New File(GetTempFileName());
				MoveFile(FileName, ResultFile.FullName);
				SizeOfReceivedFile = ResultFile.Size();
				
				FileDetails = CreateFileDescription();
				FileDetails.Name = ResultFile.Name;
				
				If PathInsteadOfData Then
					
					FileDetails.Data = Undefined;
					FileDetails.FullName = ResultFile.FullName;
					
				Else
					
					FileDetails.Data = New BinaryData(ResultFile.FullName);
					FileDetails.FullName = Undefined;
					
					Try
						
						DeleteFiles(ResultFile.FullName);
						
					Except
						
						WriteLogEvent(LogEventRetrievingFileFromStorage(),
							EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
							
					EndTry;
						
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	FileIsTemporary = New File(ArchiveName);
	
	If FileIsTemporary.Exists() Then
		
		Try
			
			FileIsTemporary.SetReadOnly(False);
			DeleteFiles(ArchiveName);
			
		Except
			
			WriteLogEvent(NStr("ru = 'Выполнение операции удаления временного файла';
											|en = 'Deleting temporary file';", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
		EndTry;
		
	EndIf;
	
	Try
		
		DeleteFiles(BuildDirectory);
		
	Except
		
		WriteLogEvent(LogEventRetrievingFileFromStorage(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
	EndTry;
		
	If Not ZipFileRead Then
		
		Raise(NStr("ru = 'При чтении zip файла произошла ошибка.';
								|en = 'An error occurred when reading zip file.';"));
		
	EndIf;
	
	If ResultingArchiveContainsMoreThanOneFile Then
		
		Raise(NStr("ru = 'В полученном архиве содержится более одного файла.';
								|en = 'The archive contains more than one file.';"));
		
	EndIf;
	
	LogFileStorageEvent(
		NStr("ru = 'Извлечение';
			|en = 'Extract';", Common.DefaultLanguageCode()),
		FileID,
		SizeOfReceivedFile,
		CurrentUniversalDate() - ExecutionStarted,
		ExchangeViaFS);
	
	Return FileDetails;
	
EndFunction

// Deprecated. Obsolete. Instead, use SaaS.PutFileInServiceManagerStorage.
// It adds a file to the Service Manager storage.
//
// Parameters:
//  AddressDataFile - String, BinaryData, File - String, BinaryData, File - String/BinaryData/File - temporary storage address/file data/file.
//  ConnectionParameters - Structure - with the following fields::
//   * URL - String - Mandatory service URL.
//	 * UserName - String - Service user username.
//	 * Password - String - Service user password.
//  FileName - String - Stored file name.
//
// Returns:
// UUID - file ID in the storage.
//
Function PutFileInStorage(Val AddressDataFile, Val ConnectionParameters, Val FileName = "") Export
	
	DeleteTemporaryFile = False;
	ExecutionStarted = CurrentUniversalDate();
	
	ProxyDescription = DescriptionOfFileTransferProxyService(ConnectionParameters);
	
	LongDesc = GetNameOfDataFile(AddressDataFile, FileName);
	
	If IsBlankString(LongDesc.Name) Then
		
		LongDesc.Name = GetTempFileName();
		DeleteTemporaryFile = True;
		
	EndIf;
	
	FileProperties = New File(LongDesc.Name);
	
	ExchangeViaFS = CanBeTransmittedViaFSToServer(ProxyDescription.Proxy, ProxyDescription.ThereIsSupportFor2ndVersion);
	
	If ExchangeViaFS Then
		
		// Save data to file.
		CommonDirectory = FilesCTL.SharedDirectoryOfTemporaryFiles();
		TargetFile = New File(CommonDirectory + FileProperties.Name);
		If TargetFile.Exists() Then
			// This is the same file. It can be read from the server.
			If FileProperties.FullName = TargetFile.FullName Then
				Result = ProxyDescription.Proxy.ReadFileFromFS(TargetFile.Name, FileProperties.Name);
				SourceFileSize = TargetFile.Size();
				LogFileStorageEvent(
					NStr("ru = 'Помещение';
						|en = 'Put';", Common.DefaultLanguageCode()),
					Result,
					SourceFileSize,
					CurrentUniversalDate() - ExecutionStarted,
					ExchangeViaFS);
				Return Result;
				// Cannot be deleted because it is a source file too.
			EndIf;
			// The source and the destination are different files. To avoid rewriting a wrong file, give the destination a unique name.
			NewID = New UUID;
			TargetFile = New File(CommonDirectory + NewID + FileProperties.Extension);
		EndIf;
		
		Try
			If LongDesc.Data = Undefined Then
				FileCopy(FileProperties.FullName, TargetFile.FullName);
			Else
				LongDesc.Data.Write(TargetFile.FullName);
			EndIf;
			Result = ProxyDescription.Proxy.ReadFileFromFS(TargetFile.Name, FileProperties.Name);
			SourceFileSize = TargetFile.Size();
			LogFileStorageEvent(
				NStr("ru = 'Помещение';
					|en = 'Put';", Common.DefaultLanguageCode()),
				Result,
				SourceFileSize,
				CurrentUniversalDate() - ExecutionStarted,
				ExchangeViaFS);
		Except
			WriteLogEvent(LogEventAddFileExchangeViaFS(),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			ExchangeViaFS = False;
		EndTry;
		
		DeleteTempFiles(TargetFile.FullName);
		If DeleteTemporaryFile Then
			DeleteTempFiles(LongDesc.Name)
		EndIf;
		
	EndIf; // ExchangeOverFS
		
	If Not ExchangeViaFS Then
		
		If LongDesc.Data = Undefined Then
			
			If FileProperties.Exists() Then
				
				BuildDirectory = Undefined;
				FullFileName = FileProperties.FullName;
				
			Else
				
				Raise(StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Добавление файла в хранилище. Не найден файл %1.';
						|en = 'Add file to the storage. File %1 not found.';"),
					FileProperties.FullName));
					
			EndIf;
				
		Else
			
			Try
				
				BuildDirectory = CreateAssemblyDirectory();
				FullFileName = BuildDirectory + FileProperties.Name;
				LongDesc.Data.Write(FullFileName);
				
			Except
				
				DeleteTempFiles(BuildDirectory);
				Raise;
				
			EndTry;
			
		EndIf;
		
		// Compress file.
		Try
			
			ArchiveFileName = GetTempFileName("zip");
			Archiver = New ZipFileWriter(ArchiveFileName,,,, ZIPCompressionLevel.Minimum);
			Archiver.Add(FullFileName);
			Archiver.Write();
			
		Except
			
			If DeleteTemporaryFile Then
				
				DeleteTempFiles(LongDesc.Name);
				
			EndIf;
			
			DeleteTempFiles(ArchiveFileName);

			If ValueIsFilled(BuildDirectory) Then
				
				DeleteTempFiles(BuildDirectory);
				
			EndIf;
			
			Raise;
				
		EndTry;
		
		If DeleteTemporaryFile Then
			
			DeleteTempFiles(LongDesc.Name);
			
		EndIf;
		
		If ValueIsFilled(BuildDirectory) Then
			
			DeleteTempFiles(BuildDirectory);
			
		EndIf;
		
		FileTransferBlockSize = GetFileTransferBlockSize() * 1024 * 1024;
		TransferID = New UUID;
		
		ArchiveFile1 = New File(ArchiveFileName);
		ArchiveFileSize = ArchiveFile1.Size();
		
		PartCount = Round((ArchiveFileSize / FileTransferBlockSize) + 0.5, 0, RoundMode.Round15as10);
		
		ReaderStream = Undefined;
		
		Try
			
			ReaderStream = FileStreams.OpenForRead(ArchiveFileName);
			ReaderStream.Seek(0, PositionInStream.Begin);
			
			PartNumber = 0;
			
			While ReaderStream.CurrentPosition() < ArchiveFileSize - 1 Do
				
				PartNumber = PartNumber + 1;
				Buffer = New BinaryDataBuffer(Min(FileTransferBlockSize, ArchiveFileSize - ReaderStream.CurrentPosition()));
				ReaderStream.Read(Buffer, 0, Buffer.Size);
				
				AttemptsNumber = 10;
				
				For AttemptNumber = 1 To AttemptsNumber Do
				
					Try
						
						If ProxyDescription.ThereIsSupportFor2ndVersion Then
							
							ProxyDescription.Proxy.PutFilePart(TransferID, PartNumber, GetBinaryDataFromBinaryDataBuffer(Buffer), PartCount);
							
						Else // 1st version.
							
							ProxyDescription.Proxy.PutFilePart(TransferID, PartNumber, GetBinaryDataFromBinaryDataBuffer(Buffer));
							
						EndIf;
						
						Break;
						
					Except
						
						If AttemptNumber = AttemptsNumber Then
							
							Raise;
							
						EndIf;
						
					EndTry;
					
				EndDo;
				
			EndDo;
			
		Except
			
			If ReaderStream <> Undefined Then
				
				ReaderStream.Close();
				
			EndIf;
			
			ExceptionDetails = ErrorDescription();
			
			DeleteTempFiles(ArchiveFileName);
			
			Try
				
				ProxyDescription.Proxy.ReleaseFile(TransferID);
				
			Except
				
				ExceptionDetails = ExceptionDetails + Chars.LF + ErrorDescription();
				
			EndTry;
			
			Raise ExceptionDetails;
			
		EndTry;
		
		ReaderStream.Close();
		DeleteTempFiles(ArchiveFileName);
		
		If ProxyDescription.ThereIsSupportFor2ndVersion Then
			
			Result = ProxyDescription.Proxy.SaveFileFromParts(TransferID, PartCount);
			
		Else // 1st version.
			
			Result = Undefined;
			ProxyDescription.Proxy.SaveFileFromParts(TransferID, PartCount, Result);
			
		EndIf;
		
		LogFileStorageEvent(
			NStr("ru = 'Помещение';
				|en = 'Put';", Common.DefaultLanguageCode()),
			Result,
			SourceFileSize,
			CurrentUniversalDate() - ExecutionStarted,
			ExchangeViaFS);
		
	EndIf; // Not ExchangeOverFS
	
	Return Result;
	
EndFunction

#EndRegion

// Checking for data area lock on start.
// To be called only from StandardSubsystemsServer.AddClientParametersOnStart().
// 
// Parameters:
//  ErrorDescription - String - Error details text.
Procedure OnCheckDataAreaLockOnStart(ErrorDescription) Export
	
	If DataSeparationEnabled()
			And SeparatedDataUsageAvailable()
			And DataAreaLocked(SessionSeparatorValue()) Then
		
		ErrorDescription =
			NStr("ru = 'Запуск приложения временно недоступен.
			           |Выполняются регламентные операции по обслуживанию приложения.
			           |
			           |Попробуйте запустить приложение через несколько минут.';
						|en = 'Cannot start the application.
						|Scheduled jobs are running.
						|
						|Please wait a few minutes and restart the application.';");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

// Deletes all data from the area. Sets the Deleted status for the data area.
// Sends the status change message to the service
// manager. Once the actions is performed, the data area becomes unusable.
//
// If all data must be deleted without changing the data area status
//  and the data area must stay usable, use the ClearAreaData() procedure instead.
//
// Parameters: 
//  DataArea - Number - a separator of the data area to be cleared.
//   When the procedure is called, the data separation must already be switched to this area.
//
Procedure ClearDataArea(DataArea) Export
	
	If Not Users.IsFullUser(, True) Then
		Raise(NStr("ru = 'Недостаточно прав для выполнения операции';
								|en = 'Insufficient rights to perform the operation.';"));
	EndIf;
	
	SetPrivilegedMode(True);
	
	AreaKey = CreateAuxiliaryDataInformationRegisterEntryKey(
		InformationRegisters.DataAreas,
		New Structure(AuxiliaryDataSeparator(), DataArea));
	LockDataForEdit(AreaKey);
	
	Try
		
		RecordManager = GetDataAreaRecordManager(
			DataArea,
			Enums.DataAreaStatuses.ForDeletion);
		
		SaaSOperationsOverridable.OnDeleteDataArea(DataArea);
		
		ClearAreaData();
		
		ChangeAreaStatusAndNotifyManager(RecordManager, "AreaRemoved", "");
		
	Except
		UnlockDataForEdit(AreaKey);
		Raise;
	EndTry;
	
	UnlockDataForEdit(AreaKey);
	
EndProcedure

Procedure ClearAreaData() Export
	
	If DataSeparationEnabled() Then
		
		DeleteApplicationData();
		
	Else
		
		ClearInformationDatabaseData(True);
		
	EndIf;
	
EndProcedure

Procedure ClearInformationDatabaseData(ExtensionsDeleting) Export
	
	If Common.DataSeparationEnabled() Then
		Raise  NStr("ru = 'В информационной базе включено разделение, допустимо использование метода РаботаВМоделиСервиса.ОчиститьДанныеОбласти';
								|en = 'Data separation is enabled in the infobase. You can use the SaaSOperations.ClearAreaData method.';");	
	EndIf;
	
	// Data.
	ClearDataByAreaDataModel();
		
	// Users.
	DeleteAreaUsers();
		
	// Clean up the history.
	ClearUserWorkHistory();
		
	// Settings.
	ClearSettingsStorages();
		
	If ExtensionsDeleting Then
		// Extensions.
		RemoveAreaExtensions();
	EndIf;	
	
EndProcedure

Procedure CreateTaskToClearDataArea(DataArea) Export
	
	MethodParameters = New Array;
	MethodParameters.Add(DataArea);
	
	JobParameters = New Structure();
	JobParameters.Insert("MethodName", ClearDataAreaMethodName());
	JobParameters.Insert("Parameters", MethodParameters);
	JobParameters.Insert("Key", "1");
	JobParameters.Insert("DataArea", DataArea);
	JobParameters.Insert("ExclusiveExecution", True);
	
	JobsQueue.AddJob(JobParameters);
	
EndProcedure

// Returns a list of full names of all metadata objects used in the common separator attribute
//  (whose name is passed in the Separator parameter) and values of object metadata properties
//  that can be required for further processing in universal algorithms.
// In case of sequences and document journals the function determines whether they are separated by included documents: any one from the sequence or journal.
//
// Parameters:
//  Separator - String - a name of a common attribute.
//
// Returns:
// FixedMap of KeyAndValue:
//  * Key - String - a full name of a metadata object,
//  * Value - FixedStructure:
//    ** Name - String - a metadata object name
//    ** Separator - String - a name of the separator that separates the metadata object,
//    ** ConditionalSeparation - String - a full name of the metadata object that shows whether the metadata object data
//      separation is enabled.
//
Function SeparatedMetadataObjects(Val Separator) Export
	
	Return SaaSOperationsCached.SeparatedMetadataObjects(Separator);
	
EndFunction

// Parameters:
//  MetadataJob - MetadataObject - predefined scheduled job metadata.
//  Use     - Boolean - If True, the job must be enabled. Otherwise, False.
//
Procedure SetPredefinedScheduledJobUsage(MetadataJob, Use) Export
	
	Template = JobsQueue.TemplateByName_(MetadataJob.Name);
	
	FilterJobs = New Structure;
	FilterJobs.Insert("Template", Template);
	Jobs = JobsQueue.GetJobs(FilterJobs);
	
	If Jobs.Count() = 0 Then
		ExclusiveModeSet = ExclusiveMode();
		If Not ExclusiveModeSet Then
			Try
				SetExclusiveMode(True);
				ExclusiveModeSet = True;
			Except
				ExclusiveModeSet = False;
			EndTry;
		EndIf;
		If ExclusiveMode() Then
			Try
				JobsQueueInternalDataSeparation.CreateQueueJobsUsingTemplatesInCurScope();
				UpdateComplete = True;
			Except
				UpdateComplete = False;
			EndTry;
			If UpdateComplete Then
				Jobs = JobsQueue.GetJobs(FilterJobs);
			EndIf;
		EndIf;
		If ExclusiveModeSet Then
			SetExclusiveMode(False);
		EndIf;
	EndIf;
	If Jobs.Count() = 0 Then
		MessageTemplate = NStr("ru = 'Не найдено задание в очереди для предопределенного задания с именем %1';
								|en = 'Job in the queue for predefined job with the %1 name is not found.';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, MetadataJob.Name);
		Raise(MessageText);
	EndIf;
	
	JobParameters = New Structure("Use", Use);
	JobsQueue.ChangeJob(Jobs.Get(0).Id, JobParameters);
	
EndProcedure

// Checks whether the configuration can be used SaaS.
//  If the configuration cannot be used SaaS, generates an exception indicating
//  why the configuration cannot be used SaaS.
//
Procedure CheckIfConfigurationCanBeUsedInServiceModel() Export
	
	SubsystemsDetails = Common.SubsystemsDetails(); // Array of Structure
	
	DetailsCTL = Undefined;
	
	For Each SubsystemDetails In SubsystemsDetails Do
		
		If SubsystemDetails.Name = "CloudTechnologyLibrary" Then
			
			DetailsCTL = SubsystemDetails;
			Break;
			
		EndIf;
		
	EndDo;
	
	If DetailsCTL = Undefined Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В конфигурацию не внедрена библиотека ""1С:Библиотека технологии сервиса"".
                  |Без внедрения этой библиотеки конфигурация не может использоваться в модели сервиса.
                  |
                  |Для использования этой конфигурации в модели сервиса требуется внедрить библиотеку
                  |""1С:Библиотека технологии сервиса"" версии не младше %1.';
					|en = '1C:Cloud Technology Library was not integrated into the configuration.
					|
					|To use the configuration in SaaS, integrate 1C:Cloud Technology Library version %1 or later.';", Metadata.DefaultLanguage.LanguageCode),
			RequiredCTLVersion());
		
	Else
		
		CTLVersion = DetailsCTL.Version;
		
		If CommonClientServer.CompareVersions(CTLVersion, RequiredCTLVersion()) < 0 Then
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Для использования конфигурации в модели сервиса с текущей версией БСП требуется
                      |обновить используемую версию библиотеки ""1С:Библиотека технологии сервиса"".
                      |
                      |Используемая версия: %1, требуется версия не младше %2.';
						|en = 'To use the configuration in SaaS with the current SSL version,
						|update the current version of library 1C:Cloud Technology Library.
						|
						|Current version: %1, version not earlier than %2 is required.';", Metadata.DefaultLanguage.LanguageCode),
				CTLVersion, RequiredCTLVersion());
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Calls an exception if there is no required subsystem from the SaaS Technology Library.
//
// Parameters:
//  SubsystemName - String - subsystem name. 
//
Procedure CauseExceptionMissingSubsystemCTL(Val SubsystemName) Export
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Невозможно выполнить операцию по причине - в конфигурации не внедрена подсистема ""%1"".
              |Данная подсистема поставляется в состав библиотеки технологии сервиса, которая должна отдельно внедряться в состав конфигурации.
              |Проверьте наличие и корректность внедрения подсистемы ""%1"".';
				|en = 'Cannot execute operation: subsystem ""%1"" is not implemented in the configuration.
				|This subsystem is included in service technology library which should be implemented separately in the configuration set.
				|Check the existence of subsystem ""%1"" and verify its proper implementation.';"),
		SubsystemName);
	
EndProcedure

// Raises an exception if a valid CTL extension is not found.
//
Procedure CauseExceptionMissingExtensionCTL() Export

	ExtensionVersion = CloudTechnology.LibraryExtensionVersion();
	If ValueIsFilled(ExtensionVersion) Then
		ErrorText = StrTemplate(NStr(
		"ru = 'Невозможно выполнить операцию: текущая версия %1 расширения для работы в режиме сервиса
		|не подходит для работы с версией %2 библиотеки технологии сервиса';
		|en = 'Cannot perform the operation: the current version %1 of the SaaS mode extension
		|is not suitable for Cloud Technology Library version %2';"), ExtensionVersion,
			CloudTechnology.LibraryVersion());
	Else
		ErrorText = NStr(
		"ru = 'Невозможно выполнить операцию: не установлено расширение библиотеки технологии сервиса
		|для работы в режиме сервиса';
		|en = 'Cannot perform the operation: Cloud Technology Library extension
		|for SaaS mode is not installed';");
	EndIf;

	Raise ErrorText;

EndProcedure

// Tries to execute a query in several attempts.
// Is used for reading fast-changing data outside a transaction.
// If it is called in a transaction, leads to an error.
//
// Parameters:
//  Query - Query - query to be executed.
//
// Returns:
//  QueryResult - request result.
//
Function ExecuteQueryOutsideTransaction(Val Query) Export
	
	If TransactionActive() Then
		Raise(NStr("ru = 'Транзакция активна. Выполнение запроса вне транзакции невозможно.';
								|en = 'The transaction is active. Cannot execute a query outside the transaction.';"));
	EndIf;
	
	AttemptsNumber = 0;
	
	Result = Undefined;
	While True Do
		Try
			Result = Query.Execute(); // Reading outside a transaction. This might cause the following error:
			                                // "Could not continue scan with NOLOCK due to data movement"
			                                // In case of the error, try to read again.
			Break;
		Except
			AttemptsNumber = AttemptsNumber + 1;
			If AttemptsNumber = 5 Then
				Raise;
			EndIf;
		EndTry;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns XML presentation of the XDTO type.
//
// Parameters:
//  XDTOType - XDTOObjectType, XDTOValueType - XDTO type whose XML presentation will be retrieved.
//   XML presentation.
//
// Returns:
//  String - XML presentation of the XDTO type.
//
Function XDTOTypePresentation(XDTOType) Export
	
	Return XDTOSerializer.XMLString(New XMLExpandedName(XDTOType.NamespaceURI, XDTOType.Name))
	
EndFunction

// For internal use.
// Returns:
//	CommonAttributeContent - composition.
Function DataAreaMainDataContent() Export
	Return Metadata.CommonAttributes.DataAreaMainData.Content;
EndFunction

// For internal use.
// Returns:
//	Number - data area.
Function GetDataAreasQueryResult() Export
	Query = New Query();
	Query.Text = 
	"SELECT
	|	DataAreas.DataAreaAuxiliaryData AS DataArea
	|FROM
	|	InformationRegister.DataAreas AS DataAreas
	|WHERE
	|	DataAreas.Status = VALUE(Enum.DataAreaStatuses.Used)
	|ORDER BY
	|	DataArea";
	
	Result = Query.Execute();
	
	Return Result;
EndFunction

// Scheduled job handler.
Procedure DeletingIrrelevantData() Export
	
	CauseExceptionMissingExtensionCTL();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See JobsQueueOverridable.OnDefineHandlerAliases.
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert("SaaSOperations.PrepareDataAreaForUse");
	NamesAndAliasesMap.Insert(ClearDataAreaMethodName());
	NamesAndAliasesMap.Insert("SaaSOperations.DeleteFile");
	
EndProcedure

// See JobsQueueOverridable.OnDefineScheduledJobsUsage.
// Parameters:
// 	UsageTable  - ValueTable - Details:
//	 * ScheduledJob - String - a name of scheduled job.
//	 * Use - Boolean - Usage flag.
Procedure OnDefineScheduledJobsUsage(UsageTable) Export
	
	NewRow = UsageTable.Add();
	NewRow.ScheduledJob = "DataAreaMaintenance";
	NewRow.Use       = True;
	
	NewRow = UsageTable.Add();
	NewRow.ScheduledJob = "DeletingIrrelevantData";
	NewRow.Use       = True;
	
	NewRow = UsageTable.Add();
	NewRow.ScheduledJob = "HandlingUserAlerts";
	NewRow.Use       = True;
	
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport.
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.JobsQueue.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.Constants.DataAreaKey);
	Types.Add(Metadata.InformationRegisters.DataAreas);
	Types.Add(Metadata.Constants.InformationAboutImportProcedure);
	Types.Add(Metadata.Constants.ParametersForLaunchingInteractiveImportProcedure);
	Types.Add(Metadata.Constants.DataAreaPresentation);
	Types.Add(Metadata.InformationRegisters.TemporaryStorageFiles);
	Types.Add(Metadata.InformationRegisters.ServiceUserDetails);
	Types.Add(Metadata.InformationRegisters.ExportImportDataAreasStates);
	Types.Add(Metadata.InformationRegisters.ExportImportMetadataObjects);
	Types.Add(Metadata.Constants.ExclusiveLockSet);
	Types.Add(Metadata.InformationRegisters.ExportImportDataAreasParts);
	
EndProcedure

// See SaaSOperationsOverridable.OnEnableSeparationByDataAreas.
Procedure OnEnableSeparationByDataAreas() Export
	
	CheckIfConfigurationCanBeUsedInServiceModel();
	
	SaaSOperationsOverridable.OnEnableSeparationByDataAreas();
	
EndProcedure

// See SuppliedDataOverridable.GetHandlersForSuppliedData.
Procedure OnDefineSuppliedDataHandlers(Handlers) Export
	
	RegisterSuppliedDataHandlers(Handlers);
	
EndProcedure

// Verifying the safe mode of data separation.
// To be called only from the session module.
//
Procedure OnCheckDataSeparationSafeModeEnabled() Export
	
	If SafeMode() = False
		And DataSeparationEnabled()
		And SeparatedDataUsageAvailable()
		And Not SessionWithoutSeparators() Then
		
		If Not DataSeparationSafeMode(AuxiliaryDataSeparator()) Then
			
			SetDataSeparationSafeMode(AuxiliaryDataSeparator(), True);
			
		EndIf;
		
		If Not DataSeparationSafeMode(MainDataSeparator()) Then
			
			SetDataSeparationSafeMode(MainDataSeparator(), True);
			
		EndIf;
	
	EndIf;
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "SaaSOperations.ControllingDelimitersWhenUpdating";
	Handler.SharedData = True;
	Handler.ExecuteInMandatoryGroup = True;
	Handler.Priority = 99;
	Handler.ExclusiveMode = False;
	
	If DataSeparationEnabled() Then
		
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.Procedure = "SaaSOperations.CheckIfConfigurationCanBeUsedInServiceModel";
		Handler.SharedData = True;
		Handler.ExecuteInMandatoryGroup = True;
		Handler.Priority = 99;
		Handler.ExclusiveMode = False;
		
		Handler = Handlers.Add();
		Handler.Version = "2.0.6.6";
		Handler.Procedure = "SaaSOperations.DeleteArea0";
		Handler.SharedData = True;
		Handler.ExecuteInMandatoryGroup = True;
		Handler.Priority = 99;
		Handler.ExclusiveMode = False;
		
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	OnAddClientParameters(Parameters);
	
EndProcedure

// See CommonOverridable.OnAddClientParameters.
Procedure OnAddClientParameters(Parameters) Export
	
	If Not DataSeparationEnabled()
		Or Not SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DataAreaPresentation.Value AS Presentation
	|FROM
	|	Constant.DataAreaPresentation AS DataAreaPresentation
	|WHERE
	|	DataAreaPresentation.DataAreaAuxiliaryData = &DataAreaAuxiliaryData";
	SetPrivilegedMode(True);
	Query.SetParameter("DataAreaAuxiliaryData", SessionSeparatorValue());
	// Considering that the data is unchangeable.
	Result = Query.Execute();
	SetPrivilegedMode(False);
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		If SessionWithoutSeparators() Then
			Parameters.Insert("DataAreaPresentation", 
				Format(SessionSeparatorValue(), "NZ=0; NG=") +  " - " + Selection.Presentation);
		ElsIf Not IsBlankString(Selection.Presentation) Then
			Parameters.Insert("DataAreaPresentation", Selection.Presentation);
		EndIf;
	EndIf;
	
EndProcedure

// See CTLSubsystemsIntegration.OnDefineSharedDataExceptions
// 
// Parameters:
//	Exceptions - Array of MetadataObject - Exceptions.
//
Procedure OnDefineSharedDataExceptions(Exceptions) Export
	
	Exceptions.Add(Metadata.InformationRegisters.DataOfClearedArea);
	
EndProcedure

// See ExportImportDataOverridable.AfterImportData.
Procedure AfterImportData(Container) Export
	
	UsersInternal.AfterImportData(Container);
	
	If Common.SubsystemExists("StandardSubsystems.TotalsAndAggregatesManagement") Then
		
		ModuleName = "TotalsAndAggregatesManagementInternal";
		ModuleTotalsAndAggregatesInternal = Common.CommonModule(ModuleName);
		ModuleTotalsAndAggregatesInternal.CalculateTotals();
		
	EndIf;
	
EndProcedure

// Get the file size from the Service Manager storage.
// 
// Parameters:
//  FileID - UUID
// 
// Returns:
//  Undefined, Number - file size.
Function GetFileSizeFromServiceManagerStorage(FileID) Export
	
	ServiceManagerURL = InternalServiceManagerURL();
	
	If Not ValueIsFilled(ServiceManagerURL) Then
		
		Raise(NStr("ru = 'Не установлены параметры связи с менеджером сервиса.';
								|en = 'Service manager connection parameters are not specified.';"));
		
	EndIf;
	
	SetPrivilegedMode(True);
	StorageAccessSettings = New Structure;
	StorageAccessSettings.Insert("URL", ServiceManagerURL);
	StorageAccessSettings.Insert("UserName", ServiceManagerInternalUserName());
	StorageAccessSettings.Insert("Password", ServiceManagerInternalUserPassword());
	SetPrivilegedMode(False);
	
	If Common.SubsystemExists("CloudTechnology.DataTransfer") Then
		
		SupportedVersions = Common.GetInterfaceVersions(StorageAccessSettings, "DataTransfer");
		
		If SupportedVersions.Count() > 0 Then
			
			ModuleDataTransferServer = Common.CommonModule("DataTransferServer");
			Return ModuleDataTransferServer.GetFileSizeFromLogicalStorage(StorageAccessSettings, "files", FileID);
			
		EndIf;
		
	EndIf;
	
	// Not supported.
	Return Undefined;
	
EndFunction

Procedure ClearMetadataObjectData(FullMetadataObjectName, MetadataObjectDetails) Export

	If ThisIsFullNameOfConstant(FullMetadataObjectName) Then

		AreaMetadataObject = Metadata.Constants.Find(MetadataObjectDetails.Name);
		ValueManager = Constants[MetadataObjectDetails.Name].CreateValueManager();
		ValueManager.DataExchange.Load = True;
		ValueManager.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		ValueManager.AdditionalProperties.Insert("DontControlObjectsToDelete");
		ValueManager.Value = AreaMetadataObject.Type.AdjustValue();
		ValueManager.Write();

		DisableAndClearDataHistory(AreaMetadataObject);
		
	ElsIf ThisIsFullNameOfObjectOfReferenceType(FullMetadataObjectName) Then
		
		ObjectParameters = NewParametersOfObjectBeingDeleted();
		ObjectParameters.PredefinedSupported = IsFullNameOfObjectWithPredefinedData(
			FullMetadataObjectName);
		
		Manager = Common.ObjectManagerByFullName(FullMetadataObjectName);
		Selection = Manager.Select();
		
		While Selection.Next() Do

			RemovableObject = Selection.GetObject(); // CatalogObject
			If ExcludeObjectFromCleanup(RemovableObject, ObjectParameters) Then
				Continue;
			EndIf;
			
			DeleteDataObject(RemovableObject);

		EndDo;
		
		AreaMetadataObject = Metadata.FindByFullName(FullMetadataObjectName);
		DisableAndClearDataHistory(AreaMetadataObject);
		
	ElsIf ThisIsFullRegisterName(FullMetadataObjectName) Or ThisIsFullNameOfRecalculation(FullMetadataObjectName)
		Or ThisIsFullNameOfSequence(FullMetadataObjectName) Then

		IsAccumulationRegister = ThisIsFullNameOfAccumulationRegister(FullMetadataObjectName);
		IsAccountingRegister = ThisIsFullNameOfAccountingRegister(FullMetadataObjectName);
		IsInformationRegister = ThisIsFullNameOfInformationRegister(FullMetadataObjectName);

		Manager = Common.ObjectManagerByFullName(FullMetadataObjectName); // AccumulationRegisterManagerAccumulationRegisterName

		IsIndependentInformationRegister = False;
		RecalcTotals = False;

		If IsAccumulationRegister Then

			MetadataRegister = Metadata.AccumulationRegisters.Find(MetadataObjectDetails.Name);

			If MetadataRegister.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Balance Then

				If Manager.GetMinTotalsPeriod() <> '00010101'
					Or Manager.GetMaxTotalsPeriod() <> EndOfMonth('00010101') Then

					Manager.SetMinAndMaxTotalsPeriods('00010101', '00010101');

				EndIf;

				If Manager.GetPresentTotalsUsing() Then

					Manager.SetPresentTotalsUsing(False);

				EndIf;

				If Manager.GetTotalsUsing() Then

					Manager.SetTotalsUsing(False);

				EndIf;
			
			ElsIf MetadataRegister.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers Then 

				AggregateMode = Manager.GetAggregatesMode();

				If AggregateMode And Manager.GetAggregatesUsing() Then
					
					Manager.SetAggregatesUsing(False);
					
				EndIf;
			
				If Not AggregateMode And Manager.GetTotalsUsing() Then

					Manager.SetTotalsUsing(False);
					RecalcTotals = True;

				EndIf;
			
			EndIf;

		ElsIf IsAccountingRegister Then

			If Manager.GetMinTotalsPeriod() <> '00010101'
				Or Manager.GetMaxTotalsPeriod() <> '00010101' Then

				Manager.SetMinAndMaxTotalsPeriods('00010101', '00010101');

			EndIf;

			If Manager.GetPresentTotalsUsing() Then

				Manager.SetPresentTotalsUsing(False);

			EndIf;

			If Manager.GetTotalsUsing() Then

				Manager.SetTotalsUsing(False);

			EndIf;

		ElsIf IsInformationRegister Then

			MetadataRegister = Metadata.InformationRegisters.Find(MetadataObjectDetails.Name);

			If MetadataRegister.EnableTotalsSliceFirst Or MetadataRegister.EnableTotalsSliceLast Then

				If Manager.GetTotalsUsing() Then

					Manager.SetTotalsUsing(False);
					RecalcTotals = True;

				EndIf;

			EndIf;

			IsIndependentInformationRegister = (MetadataRegister.WriteMode
				= Metadata.ObjectProperties.RegisterWriteMode.Independent);

		EndIf;

		If IsIndependentInformationRegister Then

			RecordSet = Manager.CreateRecordSet();
			RecordSet.DataExchange.Load = True;
			RecordSet.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
			RecordSet.AdditionalProperties.Insert("DontControlObjectsToDelete");
			RecordSet.Write();

		Else

			SelectionParameters = SelectionParameters(FullMetadataObjectName);
			FieldNameLogger = SelectionParameters.FieldNameLogger;

			Query = New Query;
			Query.Text = StrReplace(
				"SELECT DISTINCT
				|	T.Recorder AS Recorder
				|FROM
				|	&Table AS T", "&Table", SelectionParameters.Table);

			If FieldNameLogger <> "Recorder" Then

				Query.Text = StrReplace(Query.Text, "Recorder", FieldNameLogger);

			EndIf;

			QueryResult = Query.Execute();
			Selection = QueryResult.Select();

			While Selection.Next() Do

				RecordSet = Manager.CreateRecordSet();
				FilterRecorder = RecordSet.Filter[FieldNameLogger]; // FilterItem
				FilterRecorder.Set(Selection[FieldNameLogger]);
				RecordSet.DataExchange.Load = True;
				RecordSet.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
				RecordSet.AdditionalProperties.Insert("DontControlObjectsToDelete");
				RecordSet.Write();

			EndDo;

		EndIf;
		
		If RecalcTotals Then
			
			If IsAccumulationRegister
				And MetadataRegister.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers
				And Manager.GetAggregatesMode() Then
				
				Manager.SetAggregatesUsing(True);
				Manager.SetAggregatesUsing(False);
				
			Else
			
				Manager.SetTotalsUsing(True);
				Manager.SetTotalsUsing(False);
				
			EndIf;
			
		EndIf;
		
		If IsInformationRegister Then
			DisableAndClearDataHistory(MetadataRegister);
		EndIf;

	ElsIf ThisIsFullNameOfRoutineAssignment(FullMetadataObjectName) Then

		AreaMetadataObject = Metadata.ScheduledJobs.Find(MetadataObjectDetails.Name);
		For Each ScheduledJob In ScheduledJobs.GetScheduledJobs(
			New Structure("Metadata", AreaMetadataObject)) Do
			If ScheduledJob.Predefined Then
				ScheduledJob.Use = False;
				ScheduledJob.Write();
			Else
				ScheduledJob.Delete();
			EndIf;
		EndDo;

	EndIf;
EndProcedure

Procedure RemoveAreaExtensions() Export
	
	ScopeExtensions = ConfigurationExtensions.Get();
	For Each AreaExpansion In ScopeExtensions Do
		
		If AreaExpansion.Scope <> ConfigurationExtensionScope.DataSeparation Then
			Continue;
		EndIf;
				
		AreaExpansion.Delete();
		
	EndDo;
	
	CleaningKit = InformationRegisters.UseSuppliedExtensionsInDataAreas.CreateRecordSet();
	CleaningKit.Write();
	
EndProcedure

// Intended for deferred file deletion using the job queue. 
// Parameters:
//   FileName - String - File to delete.
//
Procedure DeleteFile(FileName) Export
	
	File = New File(FileName);
	If File.Exists() Then
		DeleteFiles(FileName);
	EndIf;
	
EndProcedure

// Update handler that deletes the areas whose delimiter is 0.
//
Procedure DeleteArea0() Export
	
	SetPrivilegedMode(True);
	
	Record = InformationRegisters.DataAreas.CreateRecordManager();
	Record.DataAreaAuxiliaryData = 0;
	Record.Read();
	If Record.Selected() Then
		Record.Delete();
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	JobsQueue.Ref
	|FROM
	|	Catalog.JobsQueue AS JobsQueue
	|WHERE
	|	JobsQueue.JobState <> VALUE(Enum.JobsStates.Deleted)
	|	AND JobsQueue.Template <> VALUE(Catalog.QueueJobTemplates.EmptyRef)
	|	AND JobsQueue.DataAreaAuxiliaryData = 0
	|
	|UNION ALL
	|
	|SELECT
	|	JobsQueue.Ref
	|FROM
	|	Catalog.JobsQueue AS JobsQueue
	|WHERE
	|	JobsQueue.JobState <> VALUE(Enum.JobsStates.Deleted)
	|	AND JobsQueue.Template = VALUE(Catalog.QueueJobTemplates.EmptyRef)
	|	AND JobsQueue.DataAreaAuxiliaryData = 0
	|	AND JobsQueue.MethodName IN
	|		(SELECT DISTINCT
	|			QueueAreas.MethodName
	|		FROM
	|			Catalog.JobsQueue AS QueueAreas
	|		WHERE
	|			QueueAreas.DataAreaAuxiliaryData > 0
	|			AND QueueAreas.Template = VALUE(Catalog.QueueJobTemplates.EmptyRef))";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		CatObject = Selection.Ref.GetObject(); // CatalogObject.JobsQueue
		CatObject.Use = False;
		CatObject.JobState = Enums.JobsStates.Deleted;
		CatObject.DataExchange.Load = True;
		CatObject.Write();
	EndDo;
	
EndProcedure

Function MethodNamePrepareAreaFromUpload() Export
	
	Return "SaaSOperationsCTL.PrepareAreaFromUpload";
	
EndFunction

Function ClearDataAreaMethodName() Export
	
	Return "SaaSOperations.ClearDataArea";
	
EndFunction

Procedure SetExclusiveLock(UseMultithreading = False) Export
	
	If UseMultithreading And GetFunctionalOption("ExclusiveLockSet")
		Or Not UseMultithreading And ExclusiveMode() Then
		Return;
	EndIf;
	
	SetExclusiveMode(True);
	
	If UseMultithreading Then
		Constants.ExclusiveLockSet.Set(True);
		SetExclusiveMode(False);
	EndIf;
	
EndProcedure

Procedure RemoveExclusiveLock(UseMultithreading = False) Export
	
	If UseMultithreading And Not GetFunctionalOption("ExclusiveLockSet")
		Or Not UseMultithreading And Not ExclusiveMode() Then
		Return;
	EndIf;
	
	If UseMultithreading Then
		Constants.ExclusiveLockSet.Set(False);
	Else
		SetExclusiveMode(False);
	EndIf;
	
EndProcedure

Function MethodsAllowedToRunNames() Export
	
	MethodNames = New Array();
	MethodNames.Add(ExportImportDataInternal.ExportImportDataInThreadMethodName());
	
	Return MethodNames;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated. Use See FilesCTL.NewTemporaryStorageFile
// Schedules the queued task that will delete the file.
// Parameters:
//   FileName - String - File to delete.
//   Timeout - Number - Time before the file will be deleted, in seconds.
//   
// Returns:
//   CatalogRef.JobsQueue - Scheduled task.
//
Function ScheduleFileDeletion(FileName, Timeout) Export

	MethodParameters = New Array();
	MethodParameters.Add(FileName);
		
	JobParameters = New Structure;
	JobParameters.Insert("Use", True);
	JobParameters.Insert("ScheduledStartTime", CurrentSessionDate() + Timeout);
	JobParameters.Insert("MethodName", "SaaSOperations.DeleteFile");
	JobParameters.Insert("Parameters", MethodParameters);
	JobParameters.Insert("RestartCountOnFailure", 3);
	
	Return JobsQueue.AddJob(JobParameters);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Prepare data areas.

// Updates data area statuses in the DataAreas register. Sends a message to the Service Manager.
//
// Parameters:
//  RecordManager - InformationRegisterRecordManager.DataAreas - a record manager
//  ResultOfPreparation - String - one of "Success", "ConversionRequired", "FatalError",
//    "DeletionError", or "AreaDeleted".
//  ErrorMessage - String - an error message text. 
//
Procedure ChangeAreaStatusAndNotifyManager(Val RecordManager, Val ResultOfPreparation, Val ErrorMessage)
	
	ManagerSCopy = InformationRegisters.DataAreas.CreateRecordManager();
	FillPropertyValues(ManagerSCopy, RecordManager);
	RecordManager = ManagerSCopy;

	IncludeErrorMessage = False;
	
	CalledModule = Common.CommonModule("RemoteAdministrationControlMessagesInterface");
	If ResultOfPreparation = "Success" Then
		RecordManager.Status = Enums.DataAreaStatuses.Used;
		MessageType = CalledModule.MessageDataAreaPrepared();
	ElsIf ResultOfPreparation = "ConversionIsRequired" Then
		RecordManager.Status = Enums.DataAreaStatuses.ImportFromFile;
		MessageType = CalledModule.ErrorMessagePreparingDataAreaConversionRequired();
	ElsIf ResultOfPreparation = "AreaRemoved" Then
		RecordManager.Status = Enums.DataAreaStatuses.isDeleted;
		MessageType = CalledModule.MessageDataAreaDeleted();
	ElsIf ResultOfPreparation = "FatalError" Then
		WriteLogEvent(LogEventPreparingDataArea(), 
			EventLogLevel.Error, , , ErrorMessage);
		RecordManager.ProcessingError = True;
		MessageType = CalledModule.DataAreaPreparationErrorMessage();
		IncludeErrorMessage = True;
	ElsIf ResultOfPreparation = "DeletionError" Then
		RecordManager.ProcessingError = True;
		MessageType = CalledModule.MessageErrorDeletingDataArea();
		IncludeErrorMessage = True;
	Else
		Raise NStr("ru = 'Неожиданный код возврата';
								|en = 'Unexpected return code';");
	EndIf;
	
	// Send a message to the Service Manager about the data area being ready.
	Message = MessagesSaaS.NewMessage(MessageType);
	Message.Body.Zone = RecordManager.DataAreaAuxiliaryData;
	If IncludeErrorMessage Then
		Message.Body.ErrorDescription = ErrorMessage;
	EndIf;

	BeginTransaction();
	Try
		MessagesSaaS.SendMessage(
			Message,
			ServiceManagerEndpoint());
		
		RecordManager.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Imports data to the area from the custom exported data.
//
// Parameters:
//   DataArea - Number - number of the data area to be filled.
//   UploadFileID - String - Initial data file ID.
//   ErrorMessage - String - an error description (the return value).
//
// Returns:
//  String - "ConversionRequired", "Success", or "FatalError".
//
Function PrepareDataAreaForUseFromUpload(Val DataArea, Val UploadFileID, ErrorMessage)
	
	UploadFileName = GetFileFromServiceManagerStorage(UploadFileID);
	
	If UploadFileName = Undefined Then
		
		ErrorMessage = NStr("ru = 'Нет файла начальных данных для области';
								|en = 'No initial data file for the data area';");
		
		Return "FatalError";
	EndIf;
	
	If Not Common.SubsystemExists("CloudTechnology.ExportImportDataAreas") Then
		
		CauseExceptionMissingSubsystemCTL("CloudTechnology.ExportImportDataAreas");
		
	EndIf;
	
	If Not ExportImportDataAreas.UploadingToArchiveIsCompatibleWithCurConfiguration(UploadFileName) Then
		Result = "ConversionIsRequired";
	Else
		
		ExportImportDataAreas.ImportCurrentAreaFromArchive(UploadFileName);
		Result = "Success";
		
	EndIf;
	
	Try
		DeleteFiles(UploadFileName);
	Except
		WriteLogEvent(LogEventPreparingDataArea(), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Functions that determine object type by full metadata object name.
// 

Function CheckingTypeOfMetadataObjectByItsFullName(Val FullName, Val RussianLocalization, Val EnglishLocalization, Val SubstringPosition = 0)
	
	Substrings = StrSplit(FullName, ".");
	If Substrings.Count() > SubstringPosition Then
		TypeName = Substrings.Get(SubstringPosition);
		Return TypeName = RussianLocalization Or TypeName = EnglishLocalization;
	Else
		Return False;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// File management

// Returns a structure with a name and data of the file by the address in the temporary storage / details in the File object / binary
// data.
//
// Parameters:
//	AddressDataFile - String, BinaryData, File - String/BinaryData/File - address of the file data storage/file data/file.
//	FileName - String - Filename. 
//
// Returns:
// Structure - Return data.:
//   * Data - BinaryData - file data.
//   * Name - String - Filename.
//
Function GetNameOfDataFile(Val AddressDataFile, Val FileName = "")
	
	If TypeOf(AddressDataFile) = Type("String") Then // Address of the data file in the temporary storage.
		If IsBlankString(AddressDataFile) Then
			Raise(NStr("ru = 'Неверный адрес хранилища.';
									|en = 'Invalid storage address.';"));
		EndIf;
		FileData = GetFromTempStorage(AddressDataFile);
	ElsIf TypeOf(AddressDataFile) = Type("File") Then // Object of the File type.
		If Not AddressDataFile.Exists() Then
			Raise(NStr("ru = 'Файл не найден.';
									|en = 'File not found.';"));
		EndIf;
		FileData = Undefined;
		FileName = AddressDataFile.FullName;
	ElsIf TypeOf(AddressDataFile) = Type("BinaryData") Then // File data.
		FileData = AddressDataFile;
	Else
		Raise(NStr("ru = 'Неверный тип данных';
								|en = 'Invalid data type';"));
	EndIf;
	
	Return New Structure("Data, Name", FileData, FileName);
	
EndFunction

// Checks whether file transfer from server to client through the file system is possible.
//
// Parameters:
//  Proxy - WSProxy - FilesTransfer* service proxy.
//  ThereIsSupportFor2ndVersion - Boolean -
//
// Returns:
//  Boolean - flag.
//
Function CanBeTransmittedViaFSSServer(Val Proxy, Val ThereIsSupportFor2ndVersion)
	
	If Not ThereIsSupportFor2ndVersion Then
		Return False;
	EndIf;
	
	FileName = Proxy.WriteTestFile();
	If FileName = "" Then 
		Return False;
	EndIf;
	
	Result = ReadTrialFile(FileName);
	
	Proxy.DeleteTestFile(FileName);
	
	Return Result;
	
EndFunction

// Checks whether file transfer from client to server through the file system is possible.
//
// Parameters:
//  Proxy - WSProxy - FilesTransfer* service proxy.
//  ThereIsSupportFor2ndVersion - Boolean - 
//
// Returns:
//  Boolean - flag.
//
Function CanBeTransmittedViaFSToServer(Val Proxy, Val ThereIsSupportFor2ndVersion)
	
	If Not ThereIsSupportFor2ndVersion Then
		Return False;
	EndIf;
	
	FileName = RecordTrialFile();
	If FileName = "" Then 
		Return False;
	EndIf;
	
	Result = Proxy.ReadTestFile(FileName);
	
	FullFileName = FilesCTL.SharedDirectoryOfTemporaryFiles() + FileName;
	DeleteTempFiles(FullFileName);
	
	Return Result;
	
EndFunction

// Create directory with a unique name to contain parts of the separated file.
//
// Returns:
// String - Directory name.
//
Function CreateAssemblyDirectory()
	
	BuildDirectory = GetTempFileName();
	CreateDirectory(BuildDirectory);
	Return BuildDirectory + GetPathSeparator();
	
EndFunction

// Reads the test file from the hard drive, comparing the content and name that must match.
// The calling side must delete this file.
//
// Parameters:
// FileName - String - Without the path.
//
// Returns:
// Boolean - True if the file is successfully read and the content match its name.
//
Function ReadTrialFile(Val FileName)
	
	FileProperties = New File(FilesCTL.SharedDirectoryOfTemporaryFiles() + FileName);
	If FileProperties.Exists() Then
		Text = New TextReader(FileProperties.FullName, TextEncoding.ANSI);
		TestID = Text.Read();
		Text.Close();
		Return TestID = FileProperties.BaseName;
	Else
		Return False;
	EndIf;
	
EndFunction

// Creates a blank structure of a necessary format.
//
// Returns:
// Structure - Has the following fields::
//   Name - String - File name in the storage.
//   Data - BinaryData - File data.
// 	 FullName - String - File name followed by the file path.
//
Function CreateFileDescription()
	
	FileDetails = New Structure;
	FileDetails.Insert("Name");
	FileDetails.Insert("Data");
	FileDetails.Insert("FullName");
	FileDetails.Insert("RequiredParameters2", "Name"); // Mandatory parameters.
	Return FileDetails;
	
EndFunction

// Retrieves the WSProxy object of the Web service specified by the base name.
//
// Parameters:
// ConnectionParameters - Structure - with the following fields::
//	* URL - String - Mandatory service URL.
//	* UserName - String - Service user username.
//	* Password - String - Service user password.
// Returns:
//  Structure - with the following fields::
//   * Proxy - WSProxy - proxy,
//   * ThereIsSupportFor2ndVersion - Boolean - flag.
//
Function DescriptionOfFileTransferProxyService(Val ConnectionParameters)
	
	BaseNameOfService = "FilesTransfer";
	
	ArrayOfSupportedVersions = Common.GetInterfaceVersions(ConnectionParameters, "FileTransferService");
	If ArrayOfSupportedVersions.Find("1.0.2.1") = Undefined Then
		ThereIsSupportFor2ndVersion = False;
		InterfaceVersion = "1.0.1.1"
	Else
		ThereIsSupportFor2ndVersion = True;
		InterfaceVersion = "1.0.2.1";
	EndIf;
	
	If ConnectionParameters.Property("UserName")
		And ValueIsFilled(ConnectionParameters.UserName) Then
		
		UserName = ConnectionParameters.UserName;
		UserPassword = ConnectionParameters.Password;
	Else
		UserName = Undefined;
		UserPassword = Undefined;
	EndIf;
	
	If InterfaceVersion = Undefined Or InterfaceVersion = "1.0.1.1" Then // 1st version.
		ServiceName = BaseNameOfService;
	Else // Version 2 and later.
		ServiceName = BaseNameOfService + "_" + StrReplace(InterfaceVersion, ".", "_");
	EndIf;
	
	ServiceAddress = ConnectionParameters.URL + StringFunctionsClientServer.SubstituteParametersToString("/ws/%1?wsdl", ServiceName);
	
	ConnectionParameters = Common.WSProxyConnectionParameters();
	ConnectionParameters.WSDLAddress = ServiceAddress;
	ConnectionParameters.NamespaceURI = "http://www.1c.ru/SaaS/1.0/WS";
	ConnectionParameters.ServiceName = ServiceName;
	ConnectionParameters.UserName = UserName;
	ConnectionParameters.Password = UserPassword;
	ConnectionParameters.Timeout = 600;
	Proxy = Common.CreateWSProxy(ConnectionParameters);
	
	Return New Structure("Proxy, ThereIsSupportFor2ndVersion", Proxy, ThereIsSupportFor2ndVersion);
		
EndFunction

Procedure LogFileStorageEvent(Val Event,
	Val FileID_, Val Size, Val Duration, Val TransferViaFileSystem)
	
	EventData = New Structure;
	EventData.Insert("FileID_", FileID_);
	EventData.Insert("Size", Size);
	EventData.Insert("Duration", Duration);
	
	If TransferViaFileSystem Then
		EventData.Insert("Transport", "file");
	Else
		EventData.Insert("Transport", "ws");
	EndIf;
	
	WriteLogEvent(
		NStr("ru = 'Хранилище файлов';
			|en = 'File storage';", Common.DefaultLanguageCode()) + "." + Event,
		EventLogLevel.Information,
		,
		,
		Common.ValueToXMLString(EventData));
	
EndProcedure

/////////////////////////////////////////////////////////////////////////////////
// Temp files.

// Deletes file(s) from the hard drive.
// If a mask with a path is passed as the file name, it is split to the path and the mask.
//
Procedure DeleteTempFiles(Val FileName)
	
	Try
		If StrEndsWith(FileName, "*") Then // Mask.
			IndexOf = StrFind(FileName, GetPathSeparator(), SearchDirection.FromEnd);
			If IndexOf > 0 Then
				PathToFile = Left(FileName, IndexOf - 1);
				FileMask = Mid(FileName, IndexOf + 1);
				If FindFiles(PathToFile, FileMask, False).Count() > 0 Then
					DeleteFiles(PathToFile, FileMask);
				EndIf;
			EndIf;
		Else
			FileProperties = New File(FileName);
			If FileProperties.Exists() Then
				FileProperties.SetReadOnly(False); // Clear the attribute.
				DeleteFiles(FileProperties.FullName);
			EndIf;
		EndIf;
	Except
		WriteLogEvent(TempFileDeletionEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
EndProcedure

/////////////////////////////////////////////////////////////////////////////////
// Serialization.

Function WriteValueToString(Val Value)
	
	Record = New XMLWriter;
	Record.SetString();
	
	If TypeOf(Value) = Type("XDTODataObject") Then
		XDTOFactory.WriteXML(Record, Value, , , , XMLTypeAssignment.Explicit);
	Else
		XDTOSerializer.WriteXML(Record, Value, XMLTypeAssignment.Explicit);
	EndIf;
	
	Return Record.Close();
		
EndFunction

// Indicates whether this type is serialized.
//
// Parameters:
//  StructuralType - Type - 
//
// Returns:
//  Boolean - flag.
//
Function SerializableStructuralType(StructuralType);
	
	ArrayOfSerializableTypes = SaaSOperationsCached.SerializableStructuralTypes();
	
	For Each SerializableType In ArrayOfSerializableTypes Do 
		If StructuralType = SerializableType Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
		
EndFunction

// Receives XDTO presentation of structural type object.
//
// Parameters:
//   MeaningOfStructuralType - Array of Structure - 
//   						  - Array of Map - or their fixed analogs.
//
// Returns:
//   XDTODataObject - a XDTO presentation of a structural type object.
//
Function StructuralObjectToXDTOObject(Val MeaningOfStructuralType)
	
	StructuralType = TypeOf(MeaningOfStructuralType);
	
	If Not SerializableStructuralType(StructuralType) Then
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Тип %1 не является структурным или его сериализация в настоящее время не поддерживается.';
				|en = 'Type ""%1"" is not structural or currently its serialization is not supported.';"),
			StructuralType);
		Raise(ErrorMessage);
	EndIf;
	
	XMLValueType = XDTOSerializer.XMLTypeOf(MeaningOfStructuralType);
	StructureType = XDTOFactory.Type(XMLValueType);
	XDTOStructure = XDTOFactory.Create(StructureType);
	
	// Iterating allowed structural types.
	
	If StructuralType = Type("Structure") Or StructuralType = Type("FixedStructure") Then
		
		TypeProperty = StructureType.Properties.Get("Property").Type;
		
		For Each KeyAndValue In MeaningOfStructuralType Do
			Property = XDTOFactory.Create(TypeProperty);
			Property.name = KeyAndValue.Key;
			Property.Value = TypeValueToXDTOValue(KeyAndValue.Value);
			PropertiesList = XDTOStructure.Property; // XDTOList
			PropertiesList.Add(Property);
		EndDo;
		
	ElsIf StructuralType = Type("Array") Or StructuralType = Type("FixedArray") Then 
		
		For Each ElementValue In MeaningOfStructuralType Do
			ValuesList = XDTOStructure.Value; // XDTOList
			ValuesList.Add(TypeValueToXDTOValue(ElementValue));
		EndDo;
		
	ElsIf StructuralType = Type("Map") Or StructuralType = Type("FixedMap") Then
		
		For Each KeyAndValue In MeaningOfStructuralType Do
			KeyValueList = XDTOStructure.pair; // XDTOList
			KeyValueList.Add(StructuralObjectToXDTOObject(KeyAndValue));
		EndDo;
	
	ElsIf StructuralType = Type("KeyAndValue")	Then	
		
		XDTOStructure.key = TypeValueToXDTOValue(MeaningOfStructuralType.Key);
		XDTOStructure.value = TypeValueToXDTOValue(MeaningOfStructuralType.Value);
		
	ElsIf StructuralType = Type("ValueTable") Then
		
		XDTOTypeColumnVt = StructureType.Properties.Get("column").Type;
		
		For Each Column In MeaningOfStructuralType.Columns Do
			
			XDTOColumn = XDTOFactory.Create(XDTOTypeColumnVt);
			
			XDTOColumn.Name = TypeValueToXDTOValue(Column.Name);
			XDTOColumn.ValueType = XDTOSerializer.WriteXDTO(Column.ValueType);
			XDTOColumn.Title = TypeValueToXDTOValue(Column.Title);
			XDTOColumn.Width = TypeValueToXDTOValue(Column.Width);
			
			ColumnsList_ = XDTOStructure.column; // XDTOList
			ColumnsList_.Add(XDTOColumn);
			
		EndDo;
		
		XDTOTypeIndexVt = StructureType.Properties.Get("index").Type;
		
		For Each IndexOf In MeaningOfStructuralType.Indexes Do
			
			XDTOIndex = XDTOFactory.Create(XDTOTypeIndexVt);
			
			For Each FieldOfIndex In IndexOf Do
				ColumnList = XDTOIndex.column; // XDTOList
				ColumnList.Add(TypeValueToXDTOValue(FieldOfIndex));
			EndDo;
			
			IndexList = XDTOStructure.index; // XDTOList
			IndexList.Add(XDTOIndex);
			
		EndDo;
		
		XDTOTypeStringVt = StructureType.Properties.Get("row").Type;
		
		For Each SpecificationRow In MeaningOfStructuralType Do
			
			XDTORow = XDTOFactory.Create(XDTOTypeStringVt);
			
			For Each ColumnValue In SpecificationRow Do
				ListValue_1 = XDTORow.value; // XDTOList
				ListValue_1.Add(TypeValueToXDTOValue(ColumnValue));
			EndDo;
			
			TableRowList = XDTOStructure.row; // XDTOList
			TableRowList.Add(XDTORow);
			
		EndDo;
		
	EndIf;
	
	Return XDTOStructure;
	
EndFunction

// Retrieves structural type object from XDTO object.
//
// Parameters:
//  XDTODataObject - XDTODataObject - object.
//
// Returns:
//  Array, Structure, Map, FixedArray, FixedStructure, FixedMap - Structural object.
//
Function XDTOObjectStructuralObject(XDTODataObject)
	
	XMLDataType = New XMLDataType(XDTODataObject.Type().Name, XDTODataObject.Type().NamespaceURI);
	If AbilityToReadXMLDataType(XMLDataType) Then
		StructuralType = XDTOSerializer.FromXMLType(XMLDataType);
	Else
		Return XDTODataObject;
	EndIf;
	
	If StructuralType = Type("String") Then
		Return "";
	EndIf;
	
	If Not SerializableStructuralType(StructuralType) Then
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Тип %1 не является структурным или его сериализация в настоящее время не поддерживается.';
				|en = 'Type ""%1"" is not structural or currently its serialization is not supported.';"),
			StructuralType);
		Raise(ErrorMessage);
	EndIf;
	
	If StructuralType = Type("Structure")	Or StructuralType = Type("FixedStructure") Then
		
		StructuralObject = New Structure;
		
		For Each Property In XDTODataObject.Property Do
			StructuralObject.Insert(Property.name, ValueOfXDTOIsValueOfType(Property.Value));          
		EndDo;
		
		If StructuralType = Type("Structure") Then
			Return StructuralObject;
		Else 
			Return New FixedStructure(StructuralObject);
		EndIf;
		
	ElsIf StructuralType = Type("Array") Or StructuralType = Type("FixedArray") Then 
		
		StructuralObject = New Array;
		
		For Each ArrayElement In XDTODataObject.Value Do
			StructuralObject.Add(ValueOfXDTOIsValueOfType(ArrayElement));          
		EndDo;
		
		If StructuralType = Type("Array") Then
			Return StructuralObject;
		Else 
			Return New FixedArray(StructuralObject);
		EndIf;
		
	ElsIf StructuralType = Type("Map") Or StructuralType = Type("FixedMap") Then
		
		StructuralObject = New Map;
		
		For Each XdtoKeyAndValue In XDTODataObject.pair Do
			KeyAndValue = XDTOObjectStructuralObject(XdtoKeyAndValue);
			StructuralObject.Insert(KeyAndValue.Ключ, KeyAndValue.Value);
		EndDo;
		
		If StructuralType = Type("Map") Then
			Return StructuralObject;
		Else 
			Return New FixedMap(StructuralObject);
		EndIf;
	
	ElsIf StructuralType = Type("KeyAndValue")	Then	
		
		StructuralObject = New Structure("Key, Value");
		StructuralObject.Key = ValueOfXDTOIsValueOfType(XDTODataObject.key);
		StructuralObject.Value = ValueOfXDTOIsValueOfType(XDTODataObject.value);
		
		Return StructuralObject;
		
	ElsIf StructuralType = Type("ValueTable") Then
		
		StructuralObject = New ValueTable;
		
		For Each Column In XDTODataObject.column Do
			
			StructuralObject.Columns.Add(
				ValueOfXDTOIsValueOfType(Column.Name), 
				XDTOSerializer.ReadXDTO(Column.ValueType), 
				ValueOfXDTOIsValueOfType(Column.Title), 
				ValueOfXDTOIsValueOfType(Column.Width));
				
		EndDo;
		For Each IndexOf In XDTODataObject.index Do
			
			IndexAsString = "";
			For Each FieldOfIndex In IndexOf.column Do
				IndexAsString = IndexAsString + FieldOfIndex + ", ";
			EndDo;
			IndexAsString = TrimAll(IndexAsString);
			If StrLen(IndexAsString) > 0 Then
				IndexAsString = Left(IndexAsString, StrLen(IndexAsString) - 1);
			EndIf;
			
			StructuralObject.Indexes.Add(IndexAsString);
		EndDo;
		For Each XDTORow In XDTODataObject.row Do
			
			SpecificationRow = StructuralObject.Add();
			
			NumberOfColumns_ = StructuralObject.Columns.Count();
			For IndexOf = 0 To NumberOfColumns_ - 1 Do 
				TableColumn2 = StructuralObject.Columns[IndexOf]; // ValueTableColumn
				SpecificationRow[TableColumn2.Name] = ValueOfXDTOIsValueOfType(XDTORow.value[IndexOf]);
			EndDo;
			
		EndDo;
		
		Return StructuralObject;
		
	EndIf;
	
EndFunction

Function AbilityToReadXMLDataType(Val XMLDataType)
	
	Record = New XMLWriter;
	Record.SetString();
	Record.WriteStartElement("Dummy");
	Record.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
	Record.WriteNamespaceMapping("ns1", XMLDataType.NamespaceURI);
	Record.WriteAttribute("xsi:type", "ns1:" + XMLDataType.TypeName);
	Record.WriteEndElement();
	
	String = Record.Close();
	
	Read = New XMLReader;
	Read.SetString(String);
	Read.MoveToContent();
	
	Return XDTOSerializer.CanReadXML(Read);
	
EndFunction

// Gets a value of the simple type in the XDTO context.
//
// Parameters:
// 	TypeValue - Arbitrary - Arbitrary type value.
//
// Returns:
// 	XDTODataObject, XDTODataValue - Value type.
Function TypeValueToXDTOValue(Val TypeValue)
	
	If TypeValue = Undefined
		Or TypeOf(TypeValue) = Type("XDTODataObject")
		Or TypeOf(TypeValue) = Type("XDTODataValue") Then
		
		Return TypeValue;
		
	Else
		
		If TypeOf(TypeValue) = Type("String") Then
			XDTOType = XDTOFactory.Type("http://www.w3.org/2001/XMLSchema", "string")
		Else
			XMLType = XDTOSerializer.XMLTypeOf(TypeValue);
			XDTOType = XDTOFactory.Type(XMLType);
		EndIf;
		
		If TypeOf(XDTOType) = Type("XDTOObjectType") Then // Structural type value.
			Return StructuralObjectToXDTOObject(TypeValue);
		Else
			Return XDTOFactory.Create(XDTOType, TypeValue); // For example, UUID.
		EndIf;
		
	EndIf;
	
EndFunction

// Receives the platform analog of the XDTO type value.
//
// Parameters:
// XDTODataValue - XDTODataValue -Arbitrary XDTO type value.
//
// Returns:
//	Arbitrary - a value.
//
Function ValueOfXDTOIsValueOfType(XDTODataValue)
	
	If TypeOf(XDTODataValue) = Type("XDTODataValue") Then
		Return XDTODataValue.Value;
	ElsIf TypeOf(XDTODataValue) = Type("XDTODataObject") Then
		Return XDTOObjectStructuralObject(XDTODataValue);
	Else
		Return XDTODataValue;
	EndIf;
	
EndFunction

// Populates a data area with default master data to prepare it for use.
//
// Parameters:
//   DataArea - Number - number of the data area to be filled.
//   UploadFileID - UUID - initial data file ID.
//   Variant - String - initial data option.
//   UseMode - demo or production.
//
// Returns:
//  String - "Success" or "FatalError".
//
Function ImportAreaFormSuppliedData(Val DataArea, Val UploadFileID, Val Variant, FatalErrorMessage)
	
	If Not Users.IsFullUser(, True) Then
		Raise(NStr("ru = 'Недостаточно прав для выполнения операции';
								|en = 'Insufficient rights to perform the operation.';"));
	EndIf;
	
	Filter = New Array();
	Filter.Add(New Structure("Code, Value", "ConfigurationName", Metadata.Name));
	Filter.Add(New Structure("Code, Value", "ConfigurationVersion", Metadata.Version));
	Filter.Add(New Structure("Code, Value", "Variant", Variant));
	Filter.Add(New Structure("Code, Value", "Mode", 
		?(Constants.InfobaseUsageMode.Get() 
			= Enums.InfobaseUsageModes.Demo, 
			"Demo", "Work")));

	Descriptors = SuppliedData.DescriptorsOfSuppliedDataFromManager("DataAreaPrototype", Filter);
	
	If Descriptors.Descriptor.Count() = 0 Then
		FatalErrorMessage = 
		NStr("ru = 'В менеджере сервиса нет файла начальных данных для текущей версии конфигурации.';
			|en = 'The service manager has no initial data file for the current applied solution version.';");
		Return "FatalError";
	EndIf;
	
	Id = Descriptors.Descriptor[0].FileGUID;
	
	BinaryDataOfSuppliedData = SuppliedData.SuppliedDataFromCache(Id);
	If ValueIsFilled(BinaryDataOfSuppliedData) Then	
		UploadFileName = GetTempFileName();
		BinaryDataOfSuppliedData.Write(UploadFileName);	
	Else	
		UploadFileName = GetFileFromServiceManagerStorage(Id);			
		If UploadFileName = Undefined Then
			FatalErrorMessage = 
			NStr("ru = 'В менеджере сервиса больше нет требуемого файла начальных данных, вероятно он был заменен. Область не может быть подготовлена.';
				|en = 'Service manager no longer contains the required file with initial data, it might have been replaced. Area cannot be prepared.';");
			Return "FatalError";
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Not Common.SubsystemExists("CloudTechnology.ExportImportDataAreas") Then
		
		CauseExceptionMissingSubsystemCTL("CloudTechnology.ExportImportDataAreas");
		
	EndIf;
	
	Try
		
		UploadingInformationSecurityUsers = False;
		CollapseUsers = (Not Constants.InfobaseUsageMode.Get() = Enums.InfobaseUsageModes.Demo);
		ExportImportDataAreas.ImportCurrentAreaFromArchive(UploadFileName, UploadingInformationSecurityUsers, CollapseUsers);
		
	Except
		
		WriteLogEvent(LogEventCopyingDataArea(), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Try
			DeleteFiles(UploadFileName);
		Except
			WriteLogEvent(LogEventCopyingDataArea(), 
				EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
		Raise;
	EndTry;
	
	Try
		DeleteFiles(UploadFileName);
	Except
		WriteLogEvent(LogEventCopyingDataArea(), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return "Success";

EndFunction

////////////////////////////////////////////////////////////////////////////////
// Shared data control.

// Checks whether it is possible to write separated data item. Raises exception if the data item cannot be written.
//
Procedure ControlOfUnsharedDataWhenWriting(Val Source)
	
	If DataSeparationEnabled() And SeparatedDataUsageAvailable() Then
		
		ExceptionPresentation = NStr("ru = 'Нарушение прав доступа.';
										|en = 'Access violation.';", Common.DefaultLanguageCode());
		
		WriteLogEvent(
			ExceptionPresentation,
			EventLogLevel.Error,
			Source.Metadata());
		
		Raise ExceptionPresentation;
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Handling auxiliary area data.

////////////////////////////////////////////////////////////////////////////////
// DEFAULT MASTER DATA GET HANDLERS

Procedure ProcessSuppliedConfigurationReference(Val Descriptor, Val PathToFile)
	
	If ValueIsFilled(PathToFile) Then
		
		SuppliedData.SaveSuppliedDataToCache(Descriptor, PathToFile);
		
		DeleteIrrelevantDataAreaBenchmarks(Metadata.Version);
		
	Else
		
		Filter = New Array;
		For Each Characteristic In Descriptor.Properties.Property Do
			If Characteristic.IsKey Then
				Filter.Add(New Structure("Code, Value", Characteristic.Code, Characteristic.Value));
			EndIf;
		EndDo;

		For Each Ref In SuppliedData.ReferencesSuppliedDataFromCache(Descriptor.DataType, Filter) Do
		
			SuppliedData.DeleteSuppliedDataFromCache(Ref);
		
		EndDo;
	EndIf;
	
EndProcedure

// Removes obsolete data area prototypes whose version is earlier than the specified (latest).
//
// Parameters:
//  CurrentConfigurationVersion_ - String - the latest configuration version.
//
Procedure DeleteIrrelevantDataAreaBenchmarks(CurrentConfigurationVersion_)
	
	Query = New Query(
		"SELECT DISTINCT
		|	SuppliedDataDataCharacteristics.Ref.Ref AS SuppliedData,
		|	CAST(SuppliedDataDataCharacteristics.Value AS STRING(150)) AS ConfigurationVersion
		|FROM
		|	Catalog.SuppliedData.DataCharacteristics AS SuppliedDataDataCharacteristics
		|WHERE
		|	SuppliedDataDataCharacteristics.Characteristic = ""ConfigurationVersion""
		|	AND SuppliedDataDataCharacteristics.Ref.DataKind = ""DataAreaPrototype""");
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If CommonClientServer.CompareVersions(CurrentConfigurationVersion_, Selection.ConfigurationVersion) > 0 Then
			SuppliedData.DeleteSuppliedDataFromCache(Selection.SuppliedData);
		EndIf;
	EndDo;
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// INFOBASE UPDATE HANDLERS

// Verifies the metadata structure. Shared data must be protected from writing
// from sessions with separators disabled.
// 
// Parameters:
//  RaiseException1 - Boolean - Throw an exception in case of a control error.
// 
// Returns:
//	Structure:
//		* ThereIsNoUndividedDataInControllingSubscription - Array of MetadataObject
//		* TextForExcludingUnsharedData - String
//		* ObjectsWithMultipleSeparators - Array of MetadataObject
//		* ExceptionTextWithMultipleDelimiters - String
//		* MetadataObjects - Array of MetadataObject - Obsolete property.
//		* ExceptionText - String - Obsolete property.
//
Function ControlOfUnsharedDataWhenUpdating(RaiseException1 = True) Export
	
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
	
	Exceptions = New Array();
	
	Exceptions.Add(Metadata.InformationRegisters.ProgramInterfaceCache);
	Exceptions.Add(Metadata.Constants.InstantMessageSendingLocked);
	Exceptions.Add(Metadata.InformationRegisters.SafeDataStorage);
	
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		Exceptions.Add(Metadata.InformationRegisters.Find("DeleteExchangeTransportSettings"));
		Exceptions.Add(Metadata.InformationRegisters.Find("DataExchangesStates"));
		Exceptions.Add(Metadata.InformationRegisters.Find("SuccessfulDataExchangesStates"));
		
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		
		Exceptions.Add(Metadata.Catalogs.Find("KeyOperations"));
		Exceptions.Add(Metadata.Catalogs.Find("KeyOperationProfiles"));
		Exceptions.Add(Metadata.InformationRegisters.Find("TimeMeasurements"));
		Exceptions.Add(Metadata.InformationRegisters.Find("TimeMeasurementsTechnological"));
		
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
		
		Exceptions.Add(Metadata.InformationRegisters.Find("PlatformDumps"));
		Exceptions.Add(Metadata.InformationRegisters.Find("StatisticsOperations"));
		Exceptions.Add(Metadata.InformationRegisters.Find("StatisticsComments"));
		Exceptions.Add(Metadata.InformationRegisters.Find("StatisticsAreas"));
		Exceptions.Add(Metadata.InformationRegisters.Find("StatisticsOperationComments"));
		Exceptions.Add(Metadata.InformationRegisters.Find("StatisticsOperationsClipboard"));
		Exceptions.Add(Metadata.InformationRegisters.Find("MeasurementsStatisticsOperations"));
		Exceptions.Add(Metadata.InformationRegisters.Find("MeasurementsStatisticsComments"));
		Exceptions.Add(Metadata.InformationRegisters.Find("MeasurementsStatisticsAreas"));
		Exceptions.Add(Metadata.InformationRegisters.Find("ConfigurationStatistics"));
		Exceptions.Add(Metadata.InformationRegisters.Find("PackagesToSend"));
        Exceptions.Add(Metadata.InformationRegisters.Find("StatisticsMeasurements"));
		
	EndIf;
	
	CTLSubsystemsIntegration.OnDefineSharedDataExceptions(Exceptions);
	
	StandardSeparators = New Array; // Array of MetadataObjectCommonAttribute
	StandardSeparators.Add(Metadata.CommonAttributes.DataAreaMainData);
	StandardSeparators.Add(Metadata.CommonAttributes.DataAreaAuxiliaryData);
	
	ControlProcedures = New Array;
	ControlProcedures.Add(Metadata.EventSubscriptions.CheckSharedRecordsSetsOnWrite.Handler);
	ControlProcedures.Add(Metadata.EventSubscriptions.CheckSharedObjectsOnWrite.Handler);
	ControlProcedures.Add(Metadata.EventSubscriptions.CheckSharedRecordSetsOnWriteSaaSTechnology.Handler);
	ControlProcedures.Add(Metadata.EventSubscriptions.CheckSharedObjectsOnWriteSaaSTechnology.Handler);
	
	ControllingSubscriptions = New Array; // Array of MetadataObjectEventSubscription
	
	For Each EventSubscription In Metadata.EventSubscriptions Do
		
		If ControlProcedures.Find(EventSubscription.Handler) <> Undefined Then
			
			ControllingSubscriptions.Add(EventSubscription);
			
		EndIf;
		
	EndDo;
	
	ThereIsNoUndividedDataInControllingSubscription = New Array;
	ObjectsWithMultipleSeparators = New Array;
	MetadataObjectsWithViolations = New Array;
	
	For Each MetadataControlRule In MetadataControlRules Do
		
		ControlledMetadataObjects = MetadataControlRule.Key; // Array of MetadataObject
		ConstructorForMetadataObjectType = MetadataControlRule.Value;
		
		For Each ControlledMetadataObject In ControlledMetadataObjects Do
			
			// 1. Verify metadata object being separated by multiple separators.
			
			NumberOfSeparators = 0;
			
			For Each StandardSeparator In StandardSeparators Do
				
				If IsSeparatedMetadataObject(ControlledMetadataObject, StandardSeparator.Name) Then
					
					NumberOfSeparators = NumberOfSeparators + 1;
					
				EndIf;
				
			EndDo;
			
			If NumberOfSeparators > 1 Then
				
				ObjectsWithMultipleSeparators.Add(ControlledMetadataObject);
				MetadataObjectsWithViolations.Add(ControlledMetadataObject);
				
			EndIf;
			
			// 2. Check if shared metadata objects are included in managing event subscriptions.
			// 
			
			If ValueIsFilled(ConstructorForMetadataObjectType) Then
				
				If Exceptions.Find(ControlledMetadataObject) <> Undefined Then
					
					Continue;
					
				EndIf;
				
				MetadataObjectType = Type(StringFunctionsClientServer.SubstituteParametersToString(ConstructorForMetadataObjectType, ControlledMetadataObject.Name));
				
				VerificationRequired = True;
				
				For Each StandardSeparator In StandardSeparators Do
					
					If IsSeparatedMetadataObject(ControlledMetadataObject, StandardSeparator.Name) Then
						
						VerificationRequired = False;
						
					EndIf;
					
				EndDo;
				
				ControlIsProvided = False;
				
				If VerificationRequired Then
					
					For Each ControllingSubscription In ControllingSubscriptions Do
						
						If ControllingSubscription.Source.ContainsType(MetadataObjectType) Then
							
							ControlIsProvided = True;
							
						EndIf;
						
					EndDo;
					
				EndIf;
				
				If VerificationRequired And Not ControlIsProvided Then
					
					ThereIsNoUndividedDataInControllingSubscription.Add(ControlledMetadataObject);
					MetadataObjectsWithViolations.Add(ControlledMetadataObject);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	ExceptionsRaised = New Array;
	
	DelimiterText = "";
	
	For Each StandardSeparator In StandardSeparators Do
		
		If Not IsBlankString(DelimiterText) Then
			
			DelimiterText = DelimiterText + ", ";
			
		EndIf;
		
		DelimiterText = DelimiterText + StandardSeparator.Name;
		
	EndDo;
	
	TextForExcludingUnsharedData = "";
	
	If ThereIsNoUndividedDataInControllingSubscription.Count() > 0 Then
		
		TextProblematicObjects = "";
		
		If RaiseException1 Then
			
			For Each ObjectWithIssue In ThereIsNoUndividedDataInControllingSubscription Do
				
				If Not IsBlankString(TextProblematicObjects) Then
					
					TextProblematicObjects = TextProblematicObjects + ", ";
					
				EndIf;
				
				TextProblematicObjects = TextProblematicObjects + ObjectWithIssue.FullName();
				
			EndDo;
			
		EndIf;
		
		SubscriptionText = "";
		
		For Each ControllingSubscription In ControllingSubscriptions Do
			
			If Not IsBlankString(SubscriptionText) Then
				
				SubscriptionText = SubscriptionText + ", ";
				
			EndIf;
			
			SubscriptionText = SubscriptionText + ControllingSubscription.Name;
			
		EndDo;
		
		TextForExcludingUnsharedData = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Объекты метаданных, не входящие в состав разделителей %1,
						|должны быть включены в состав одной из подписок на события, контролирующих
						|невозможность записи неразделенных данных в разделенных сеансах: 
						|%2.';
						|en = 'Metadata objects that are not included in the %1 separators
						|must be included in one of the event subscriptions
						|that control the inability to save shared data in separated sessions: 
						|%2.';"),
					DelimiterText, SubscriptionText);
					
		If RaiseException1 Then
						
			ExceptionText = TextForExcludingUnsharedData + Chars.LF + Chars.LF 
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Следующие объекты метаданных не удовлетворяют этому критерию: 
						|%1.';
						|en = 'The following metadata objects do not meet this criterion: 
						|%1.';"),
				TextProblematicObjects);
			ExceptionsRaised.Add(ExceptionText);
			
		EndIf;
		
	EndIf;
	
	ExceptionTextWithMultipleDelimiters = "";
	
	If ObjectsWithMultipleSeparators.Count() > 0 Then
		
		TextProblematicObjects = "";
		
		For Each ObjectWithIssue In ObjectsWithMultipleSeparators Do
			
			If Not IsBlankString(TextProblematicObjects) Then
				
				TextProblematicObjects = TextProblematicObjects + ", ";
				
			EndIf;
			
			TextProblematicObjects = TextProblematicObjects + ObjectWithIssue.FullName();
			
		EndDo;
		
		ExceptionTextWithMultipleDelimiters = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Объекты метаданных конфигурации должны быть разделены не более чем одним разделителем: %1.';
				|en = 'Configuration metadata objects must be separated only with one separator: %1.';"),
			DelimiterText, TextProblematicObjects);
			
		If RaiseException1 Then
			
			ExceptionText = ExceptionTextWithMultipleDelimiters + Chars.LF + Chars.LF 
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Следующие объекты не удовлетворяют этому критерию:
						|%2';
						|en = 'The following objects do not meet this criterion:
						|%2';"),
					TextProblematicObjects);
			ExceptionsRaised.Add(ExceptionText);
			
		EndIf;
		
	EndIf;
	
	ExceptionText = "";
	Result = New Structure;
	Result.Insert("MetadataObjects", MetadataObjectsWithViolations); // For backward compatibility purposes.
	Result.Insert("ExceptionText", ExceptionText); // For backward compatibility purposes.
	Result.Insert("ThereIsNoUndividedDataInControllingSubscription", ThereIsNoUndividedDataInControllingSubscription);
	Result.Insert("TextForExcludingUnsharedData", TextForExcludingUnsharedData);
	Result.Insert("ObjectsWithMultipleSeparators", ObjectsWithMultipleSeparators);
	Result.Insert("ExceptionTextWithMultipleDelimiters", ExceptionTextWithMultipleDelimiters);
	
	Iterator_SSLy = 1;
	
	For Each RaisedException In ExceptionsRaised Do
		
		If Not IsBlankString(Result.ExceptionText) Then
			
			Result.ExceptionText = Result.ExceptionText + Chars.LF + Chars.CR;
			
		EndIf;
		
		Result.ExceptionText = Result.ExceptionText + Format(Iterator_SSLy, "NFD=0; NG=0") + ". " + RaisedException;
		Iterator_SSLy = Iterator_SSLy + 1;
		
	EndDo;
	
	If RaiseException1 Then
		
		If Not IsBlankString(Result.ExceptionText) Then
			
			Raise NStr("ru = 'Обнаружены ошибки в структуре метаданных конфигурации:';
									|en = 'Errors are found in the configuration metadata structure:';") 
				+ Chars.LF + Chars.CR + Result.ExceptionText;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Verifies the metadata structure. Common data must be ordered in the configuration
// metadata tree.
//
Procedure ControllingDelimitersWhenUpdating() Export
	
	OrderOfApplicationData = 99;
	InternalDataOrder = 99;
	
	ApplicationSeparator = Metadata.CommonAttributes.DataAreaMainData;
	InternalSeparator = Metadata.CommonAttributes.DataAreaAuxiliaryData;
	
	Iterator_SSLy = 0;
	For Each CommonConfigurationProps In Metadata.CommonAttributes Do
		
		If CommonConfigurationProps = ApplicationSeparator Then
			OrderOfApplicationData = Iterator_SSLy;
		ElsIf CommonConfigurationProps = InternalSeparator Then
			InternalDataOrder = Iterator_SSLy;
		EndIf;
		
		Iterator_SSLy = Iterator_SSLy + 1;
		
	EndDo;
	
	If OrderOfApplicationData <= InternalDataOrder Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Обнаружено нарушение структуры метаданных конфигурации: общий реквизит %1 должен
                  |быть расположен в дереве метаданных конфигурации до общего реквизита
                  |%2 по порядку.';
					|en = 'Configuration metadata structure violation detected: common attribute %1
					|must be placed before common attribute
					|%2 in the configuration metadata tree.';"),
			InternalSeparator.Name,
			ApplicationSeparator.Name);
		
	EndIf;
	
EndProcedure

// Returns the earliest 1C:SaaS Technology Library version supported
// by the current SSL version.
//
// Returns:
//   String - earliest supported CTL version in the RR.{S|SS}.ZZ.CC format.
//
Function RequiredCTLVersion()
	
	Return "1.0.2.1";
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Processing infobase parameters

// Returns an empty table of infobase parameters.
//
Function InformationSecurityParameterTemplate()
	
	Result = New ValueTable;
	Result.Columns.Add("Name", New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable)));
	Result.Columns.Add("LongDesc", New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable)));
	Result.Columns.Add("ForbiddenReading", New TypeDescription("Boolean"));
	Result.Columns.Add("RecordBan", New TypeDescription("Boolean"));
	Result.Columns.Add("Type", New TypeDescription("TypeDescription"));
	Return Result;
	
EndFunction

#Region DataClearing

Procedure DeleteApplicationData(DataArea = Undefined)
	
	If Not SeparatedDataUsageAvailable() Then
		Raise NStr("ru = 'Удаление данных приложения может быть выполнено только при включенном использовании разделителей';
								|en = 'You can delete the application data only when the separators are enabled';");
	EndIf;
	
	If DataArea = Undefined Then
		DataArea = SessionSeparatorValue();
	EndIf;
	
	StoredData = New Structure();
	ExternalMonopolyModeIsSet = ExclusiveMode();
	ExclusiveModeSet = False;
	
	Try
	
		If Not ExternalMonopolyModeIsSet Then
			SetExclusiveMode(True);
			ExclusiveModeSet = True;
		EndIf;
		
		BeforeDeletingApplicationData(DataArea, StoredData);
		
		If ExtensionsSaaS.ThereAreInstalledExtensionsModifyingDataStructure() Then
			
			// Separately delete the extension and run a background job to clear app data to bypass the
			// 1C:Enterprise bug that prevents data of table extensions from being cleaned up.
			RemoveAreaExtensions();
			DeleteAppDataInBackground(DataArea);
			
		Else
			
			ProceedApplicationDataDeletion();
			
		EndIf;
		
		AfterDeletingApplicationData(DataArea, StoredData);
		
		If ExclusiveModeSet Then
			SetExclusiveMode(False);
			ExclusiveModeSet = False;
		EndIf;
		
	Except
		
		If ExclusiveModeSet Then
			SetExclusiveMode(False);
		EndIf;
		
		Raise;
		
	EndTry;
	
EndProcedure

Procedure DeleteAppDataInBackground(DataArea)
	
	DataAreaAsString = Format(DataArea, "NG=0;");
	Job = ConfigurationExtensions.ExecuteBackgroundJobWithoutExtensions(
		"SaaSOperations.ProceedApplicationDataDeletion",
		,
		DataAreaAsString,
		StrTemplate(NStr("ru = 'Очистка данных приложения %1';
						|en = 'Clear the %1 application data';"), DataAreaAsString));
	Job = Job.WaitForExecutionCompletion();
	
	If Job.State = BackgroundJobState.Canceled Then
		Raise NStr("ru = 'Задание очистки данных приложения отменено';
								|en = 'The job to clear the application data is canceled';");
	ElsIf Job.State = BackgroundJobState.Failed Then
		Raise ErrorProcessing.DetailErrorDescription(Job.ErrorInfo);
	EndIf;
	
EndProcedure

Procedure ProceedApplicationDataDeletion() Export
	
	EraseInfoBaseData();
	DeleteAreaUsers();
	
EndProcedure

Procedure DeleteAreaUsers()
	
	FirstAdministrator = Undefined;
	
	For Each IBUser In InfoBaseUsers.GetUsers() Do
		
		If FirstAdministrator = Undefined
			And Users.IsFullUser(IBUser, True, False) Then
			
			// Postpone the deletion of the administrator until all infobase users are deleted.
			// 
			FirstAdministrator = IBUser;
			
		Else
			
			IBUser.Delete();
			
		EndIf;
		
	EndDo;
	
	If FirstAdministrator <> Undefined Then
		
		FirstAdministrator.Delete();
		
	EndIf;
	
EndProcedure

Procedure BeforeDeletingApplicationData(DataArea, StoredData)
	
	If Not InformationRegisters.DataOfClearedArea.AreaDataIsSaved(DataArea) Then
		InformationRegisters.DataOfClearedArea.SaveAreaData(DataArea);
	EndIf;
	
	StoredData.Insert("DataAreaKey", Constants.DataAreaKey.Get());
	
EndProcedure

Procedure AfterDeletingApplicationData(DataArea, StoredData)
	
	Constants.DataAreaKey.Set(StoredData.DataAreaKey);
	
	DataModel = SaaSOperationsCached.GetAreaDataModel();
	
	For Each ModelItem In DataModel Do
		
		If IsFullNameOfObjectWithPredefinedData(ModelItem.Key) Then
			DisablePredefinedDataInitialization(ModelItem.Key);
		EndIf;
		
	EndDo;
	
	InformationRegisters.DataOfClearedArea.RestoreAreaData(DataArea);
	
EndProcedure

Procedure DisablePredefinedDataInitialization(FullMetadataObjectName)
	
	Manager = Common.ObjectManagerByFullName(FullMetadataObjectName);
	Manager.SetPredefinedDataInitialization(False);
	
EndProcedure

Procedure DeleteDataObject(RemovableObject)
	
	RemovableObject.DataExchange.Load = True;
	RemovableObject.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	RemovableObject.AdditionalProperties.Insert("DontControlObjectsToDelete");
	RemovableObject.Delete();

EndProcedure

Function ExcludeObjectFromCleanup(Object, ObjectParameters)
	
	ExcludeObject = False;
	
	If ObjectParameters.PredefinedSupported Then
		ExcludeObject = Object.Predefined;
	EndIf;
	
	Return ExcludeObject;
	
EndFunction

Function NewParametersOfObjectBeingDeleted()
	
	ObjectParameters = New Structure();
	ObjectParameters.Insert("PredefinedSupported", False);
	
	Return ObjectParameters;
	
EndFunction

Procedure DisableAndClearDataHistory(MetadataObject)
	
	If MetadataObject = Undefined Then
		Return;
	EndIf;
	
	DataHistory.DeleteVersions(MetadataObject);
	
	HistorySettings = DataHistory.GetSettings(MetadataObject);
	If HistorySettings <> Undefined Then
		DataHistory.SetSettings(MetadataObject, Undefined);
	EndIf;
	
EndProcedure

Procedure ClearDataByAreaDataModel()
	
	DataModel = SaaSOperationsCached.GetAreaDataModel();
	
	CleanupExceptions = New Array();
	CleanupExceptions.Add(Metadata.InformationRegisters.DataAreas.FullName());
	CleanupExceptions.Add(Metadata.Constants.InformationAboutImportProcedure.FullName());
	CleanupExceptions.Add(Metadata.Constants.ParametersForLaunchingInteractiveImportProcedure.FullName());
	CleanupExceptions.Add(Metadata.Constants.DataAreaKey.FullName());
	CleanupExceptions.Add(Metadata.Constants.ExclusiveLockSet.FullName());
	CleanupExceptions.Add(
		Metadata.InformationRegisters.UseSuppliedExtensionsInDataAreas.FullName());
		
	For Each ModelItem In DataModel Do
		
		FullMetadataObjectName = ModelItem.Key;
		MetadataObjectDetails = ModelItem.Value; // MetadataObject
		
		If CleanupExceptions.Find(FullMetadataObjectName) <> Undefined Then
			Continue;
		EndIf;
		
		ClearMetadataObjectData(FullMetadataObjectName, MetadataObjectDetails);
		
	EndDo;
	
EndProcedure

Procedure ClearUserWorkHistory()
	
	UserWorkHistory.ClearAll();
	
EndProcedure

Procedure ClearSettingsStorages()
	
	Repositories = New Array;
	Repositories.Add(ReportsVariantsStorage);
	Repositories.Add(FormDataSettingsStorage);
	Repositories.Add(CommonSettingsStorage);
	Repositories.Add(ReportsUserSettingsStorage);
	Repositories.Add(SystemSettingsStorage);
	Repositories.Add(DynamicListsUserSettingsStorage);
	
	For Each Store In Repositories Do
		
		If TypeOf(Store) <> Type("StandardSettingsStorageManager") Then
			
			// Settings is deleted when clearing data.
			Continue;
			
		EndIf;
		
		Store.Delete(Undefined, Undefined, Undefined);
		
	EndDo;
	
EndProcedure

#EndRegion

Procedure AuthenticateCurrentUser()
	
	If ExtensionsSaaS.ThereAreInstalledExtensionsModifyingDataStructure() Then
		
		Job = CloudTechnology.CompleteTaskWithExtensions(
			"UsersInternal.AuthenticateCurrentUser",
			Undefined,
			New UUID,
			NStr("ru = 'Авторизация текущего пользователя';
				|en = 'Current user authorization';"))
			.WaitForExecutionCompletion();
		
		If Job.State = BackgroundJobState.Canceled Then
			Raise NStr("ru = 'Задание отменено';
									|en = 'Job is canceled';");
		ElsIf Job.State = BackgroundJobState.Failed Then
			Raise ErrorProcessing.DetailErrorDescription(Job.ErrorInfo);
		EndIf;
		
		UsersInternal.AuthenticateCurrentUser();
	Else
		UsersInternal.AuthenticateCurrentUser();
	EndIf;
	
EndProcedure

#EndRegion
