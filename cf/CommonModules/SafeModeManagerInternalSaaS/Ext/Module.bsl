////////////////////////////////////////////////////////////////////////////////
// Subsystem "Core SaaS".
// Common server procedures and functions:
// - Support of security profiles.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Fills a structure with arrays of supported versions of the subsystems that are subject to versioning.
// Subsystem names are used as structure keys.
// Implements the InterfaceVersion web service functionality.
// When integrating, change the procedure body so that it returns current version sets (see the example below).
//
// Parameters:
// SupportedVersionsStructure - Structure - Where:
//  Keys are subsystem names 
//  Values are arrays of supported versions names
//
// Example:
//
//	// FilesTransferService
//	VersionsArray = New Array;
//	VersionsArray.Add("1.0.1.1");	
//	VersionsArray.Add("1.0.2.1"); 
//	SupportedVersionsStructure.Insert("FilesTransferService", VersionsArray);
//	// End FilesTransferService
//
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export
	
	If SafeModeManagerInternal.SecurityProfilesUsageAvailable() Then
		VersionsArray = New Array;
		VersionsArray.Add("1.0.0.2");
		SupportedVersionsStructure.Insert("SecurityProfileCompatibilityMode", VersionsArray);
	EndIf;
	
EndProcedure

// Called when checking whether security profiles can be set up
//
// Parameters:
//  Cancel - Boolean - If the infobase doesn't support security profiles, set it to True.
//    
//
Procedure OnCheckCanSetupSecurityProfiles(Cancel) Export
	
	If Common.DataSeparationEnabled() Then
		
		// In SaaS, security profiles are centrally managed in the Service Manager.
		// 
		Cancel = True;
		
	EndIf;
	
EndProcedure

// Called when creating a permission request to use external resources.
//
// Parameters:
//  ProgramModule - AnyRef - Reference to the infobase object that represents the module the permissions are requested for.
//    
//  Owner - AnyRef - Reference to the infobase object that owns the requested permissions to use external resources.
//    
//  ReplacementMode - Boolean - indicates that permissions granted earlier by owner are replaced,
//  PermissionsToAdd - Array of XDTODataObject - an array of permissions being added,
//  PermissionsToDelete - Array of XDTODataObject - an array of permissions being deleted,
//  StandardProcessing - Boolean - indicates that a standard data processor to create a request to use
//    external resources is processed.
//  Result - UUID - a request ID (if StandardProcessing parameter
//    value is set to False in the handler).
//
Procedure OnRequestPermissionsToUseExternalResources(Val ProgramModule, Val Owner, Val ReplacementMode, 
	Val PermissionsToAdd, Val PermissionsToDelete, StandardProcessing, Result) Export
	
	If Common.DataSeparationEnabled() Then
		
		StandardProcessing = False;
		
		If ProgramModule = Undefined Then
			ProgramModule = Catalogs.MetadataObjectIDs.EmptyRef();
		EndIf;
		
		If Owner = Undefined Then
			Owner = ProgramModule;
		EndIf;
		
		If GetFunctionalOption("UseSecurityProfiles") Then
			
			If Common.SeparatedDataUsageAvailable() Then
				
				RequestRegister = InformationRegisters.RequestPermissionsToAccessExternalResourcesForDataAreas;
				
			Else
				
				RequestRegister = InformationRegisters.RequestPermissionsToAccessExternalResourcesSaaS;
				
			EndIf;
			
			PermissionsRequest = RequestRegister.CreateRecordManager();
			
			PermissionsRequest.QueryID = New UUID;
			
			If SafeModeManager.SafeModeSet() Then
				PermissionsRequest.SafeMode = SafeMode();
			Else
				PermissionsRequest.SafeMode = False;
			EndIf;
			
			SoftwareModuleKey = RegisterKeyByReference(ProgramModule);
			PermissionsRequest.ProgramModuleType = SoftwareModuleKey.Type;
			PermissionsRequest.ModuleID = SoftwareModuleKey.Id;
			
			OwnerSKey = RegisterKeyByReference(Owner);
			PermissionsRequest.OwnerType = OwnerSKey.Type;
			PermissionsRequest.OwnerID = OwnerSKey.Id;
			
			PermissionsRequest.ReplacementMode = ReplacementMode;
			
			If PermissionsToAdd <> Undefined Then
				
				PermissionsArray = New Array();
				For Each NewPermission In PermissionsToAdd Do
					PermissionsArray.Add(Common.XDTODataObjectToXMLString(NewPermission));
				EndDo;
				
				If PermissionsArray.Count() > 0 Then
					PermissionsRequest.PermissionsToAdd = Common.ValueToXMLString(PermissionsArray);
				EndIf;
				
			EndIf;
			
			If PermissionsToDelete <> Undefined Then
				
				PermissionsArray = New Array();
				For Each PermissionToRevoke In PermissionsToDelete Do
					PermissionsArray.Add(Common.XDTODataObjectToXMLString(PermissionToRevoke));
				EndDo;
				
				If PermissionsArray.Count() > 0 Then
					PermissionsRequest.PermissionsToDelete = Common.ValueToXMLString(PermissionsArray);
				EndIf;
				
			EndIf;
			
			PermissionsRequest.Write();
			
			Result = PermissionsRequest.QueryID;
			
		Else
			
			Result = New UUID();
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Called when requesting to create a security profile.
//
// Parameters:
//  ProgramModule - AnyRef - Reference to the infobase object that represents the module the permissions are requested for.
//    
//  StandardProcessing - Boolean - indicates that a standard data processor is being executed,
//  Result - UUID - a request ID (if StandardProcessing parameter
//    value is set to False in the handler).
//
Procedure OnRequestToCreateSecurityProfile(Val ProgramModule, StandardProcessing, Result) Export
	
	WhenRequestingChangesToSecurityProfiles(ProgramModule, StandardProcessing, Result);
	
EndProcedure

// Called when requesting to create a security profile.
//
// Parameters:
//  ProgramModule - AnyRef - Reference to the infobase object that represents the module the permissions are requested for.
//    
//  StandardProcessing - Boolean - indicates that a standard data processor is being executed,
//  Result - UUID - a request ID (if StandardProcessing parameter
//    value is set to False in the handler).
//
Procedure OnRequestToDeleteSecurityProfile(Val ProgramModule, StandardProcessing, Result) Export
	
	WhenRequestingChangesToSecurityProfiles(ProgramModule, StandardProcessing, Result);
	
EndProcedure

// Called when attaching an external module. In the handler procedure body, you can change
// the safe mode, in which the module is attached.
//
// Parameters:
//  ExternalModule - AnyRef - Reference to the infobase object that represents the external module to be attached.
//    
//  SafeMode - DefinedType.SafeMode - a safe mode, in which the external
//    module will be attached to the infobase. Can be changed within the procedure.
//
Procedure OnAttachExternalModule(Val ExternalModule, SafeMode) Export
	
	If Common.DataSeparationEnabled() Then
		
		SafeMode = SafeModeManagerSaaS.ExternalModuleExecutionMode(ExternalModule);
		
	EndIf;
	
EndProcedure

// Generates the list of infobase parameters.
//
// Parameters:
// ParametersTable - ValueTable - Table describing parameters.
// For column content details,
//                                       ().
//
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "UseSecurityProfiles");
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, 
		"InfobaseSecurityProfile");
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, 
		"AutomaticallyConfigurePermissionsInSecurityProfiles");
	
EndProcedure

// Fills in the passed array with the common modules used as
//  incoming message interface handlers.
//
// Parameters:
//  HandlersArray - Array - handlers.
//
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
	
	HandlersArray.Add(MessagesPermissionsManagementControlInterface);
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.Constants.MasterApplicationExternalAddress);
	
	Types.Add(Metadata.InformationRegisters.RequestPermissionsToAccessExternalResourcesSaaS);
	Types.Add(Metadata.InformationRegisters.RequestPermissionsToAccessExternalResourcesForDataAreas);
	
	Types.Add(Metadata.InformationRegisters.PermissionsToUseExternalResourcesSaaS);
	Types.Add(Metadata.InformationRegisters.PermissionsToUseExternalResourcesForDataAreas);
	
	Types.Add(Metadata.InformationRegisters.ExternalModulesConnectionOptionsSaaS);
	Types.Add(Metadata.InformationRegisters.DataAreaExternalModulesAttachmentModes);
	
	Types.Add(Metadata.InformationRegisters.ApplyPermissionsToUseExternalResourcesSaaS);
	Types.Add(Metadata.InformationRegisters.ApplyPermissionsToUseExternalResourcesForDataAreas);Types.Add(Metadata.InformationRegisters.TimeConsumingOperations);
	
EndProcedure

// Parameters:
// 	Ref - CatalogRef.MetadataObjectIDs - 
// 	
// Returns:
// 	Structure - Details.:
// * Type - CatalogRef.MetadataObjectIDs - a metadata object ID 
// * Id - UUID - 
// 
Function RegisterKeyByReference(Val Ref) Export
	
	Result = New Structure("Type,Id");
	
	If Ref = Catalogs.MetadataObjectIDs.EmptyRef() Then
		
		Result.Type = Catalogs.MetadataObjectIDs.EmptyRef();
		Result.Id = New UUID("00000000-0000-0000-0000-000000000000");
		
	Else
		
		Result.Type = Common.MetadataObjectID(Ref.Metadata());
		Result.Id = Ref.UUID();
		
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters: 
//  Type - CatalogRef.MetadataObjectIDs
//  Id - UUID
// 
// Returns: 
//  AnyRef - Reference by register key.
Function ReferenceByRegisterKey(Val Type, Val Id) Export
	
	If Type = Catalogs.MetadataObjectIDs.EmptyRef() Then
		Return Type;
	Else
		
		MetadataObject = Common.MetadataObjectByID(Type);
		Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
		
		Return Manager.GetRef(Id);
		
	EndIf;
	
EndFunction

// Generates a permission key (to be used in registers, in which the granted
// permission details are stored).
//
// Parameters:
//  Resolution - XDTODataObject -
//
// Returns:
//   String - key.
//
Function PermissionKey(Val Resolution) Export
	
	Hashing = New DataHashing(HashFunction.MD5);
	Hashing.Append(Common.XDTODataObjectToXMLString(Resolution));
	
	Var_Key = XDTOFactory.Create(XDTOFactory.Type("http://www.w3.org/2001/XMLSchema", "hexBinary"), 
		Hashing.HashSum).LexicalValue;
	
	If StrLen(Var_Key) > 32 Then
		Raise NStr("ru = 'Превышение длины ключа';
								|en = 'Key length exceeded';");
	EndIf;
	
	Return Var_Key;
	
EndFunction

// Returns a permission table row that meets the filter condition.
// If the table does not contain rows meeting the filter condition, a new one can be added.
// If the table contains more than one row meeting the filter condition, an exception is generated.
//
// Parameters:
//  PermissionsTable - ValueTable - 
//  Filter - Structure - 
//  AddIfAbsent - Boolean - 
//
// Returns:
//   ValueTableRow, Undefined - 
//
Function PermissionsTableRow(Val PermissionsTable, Val Filter, Val AddIfAbsent = True) Export
	
	Rows = PermissionsTable.FindRows(Filter);
	
	If Rows.Count() = 0 Then
		
		If AddIfAbsent Then
			
			String = PermissionsTable.Add();
			FillPropertyValues(String, Filter);
			Return String;
			
		Else
			
			Return Undefined;
			
		EndIf;
		
	ElsIf Rows.Count() = 1 Then
		
		Return Rows.Get(0);
		
	Else
		
		Raise StrTemplate(NStr("ru = 'Нарушение уникальности строк в таблице разрешений по отбору %1';
										|en = 'Row uniqueness violation in permission table filtered by %1';"),
			Common.ValueToXMLString(Filter));
		
	EndIf;
	
EndFunction

// Sets an exclusive managed lock for tables of all registers used
// for storing a list of granted permissions.
//
// Parameters:
//  ProgramModule - AnyRef - a reference to the catalog item that corresponds to the external module whose information
//    on previously granted permissions must be cleared. If the parameter value is not specified,
//    information on granted permissions in all external modules will be blocked.
// BlockConnectionModesOfExternalModules - Boolean - indicates that additional lock of
//    external module attachment modes is required.
//
Procedure LockRegistersOfGrantedPermissions(Val ProgramModule = Undefined, 
	Val BlockConnectionModesOfExternalModules = True) Export
	
	If Not TransactionActive() Then
		Raise NStr("ru = 'Транзакция не активна';
								|en = 'Transaction is not active';");
	EndIf;
	
	Registers = New Array();
	
	If Common.SeparatedDataUsageAvailable() Then
		
		Registers.Add(InformationRegisters.PermissionsToUseExternalResourcesForDataAreas);
		
		If BlockConnectionModesOfExternalModules Then
			Registers.Add(InformationRegisters.ExternalModulesConnectionOptionsSaaS);
		EndIf;
		
	Else
		
		Registers.Add(InformationRegisters.PermissionsToUseExternalResourcesForDataAreas);
		
		If BlockConnectionModesOfExternalModules Then
			Registers.Add(InformationRegisters.ExternalModulesConnectionOptionsSaaS);
		EndIf;
		
	EndIf;
	
	If ProgramModule <> Undefined Then
		Var_Key = RegisterKeyByReference(ProgramModule);
	EndIf;
	
	Block = New DataLock();
	
	For Each Register In Registers Do
		RegisterLock = Block.Add(Register.CreateRecordSet().Metadata().FullName());
		If ProgramModule <> Undefined Then
			RegisterLock.SetValue("ProgramModuleType", Var_Key.Type);
			RegisterLock.SetValue("ModuleID", Var_Key.Id);
		EndIf;
	EndDo;
	
	Block.Lock();
	
EndProcedure

// Returns the current slice of granted permissions.
//
// Parameters:
//  ByOwners - Boolean - if True, the return table will contain information on permission owners.
//    Otherwise, the current slice will be collapsed by owner.
//  NoDetails1 - Boolean - If True, the slice is returned with its permissions having the Description field cleared.
//
// Returns:
// ValueTable - Following columns:
// * ProgramModuleType - CatalogRef.MetadataObjectIDs - 
// * ModuleID - UUID - 
// * OwnerType - CatalogRef.MetadataObjectIDs -
// * OwnerID - UUID - 
// * Type - String - an XDTO type name describing permissions,
// * Permissions - Map of KeyAndValue - Permission details:
//   ** Key - String - Permission key.
//      See the PermissionKey function in the register manager module PermissionsToUseExternalResources.
//   ** Value - XDTODataObject - Permission details in XDTO format.
// * PermissionsAdditions - Map of KeyAndValue - permission addition details:
//   ** Key - String - Permission key.
//      See the PermissionKey function in the register manager module PermissionsToUseExternalResources.
//   ** Value - See InformationRegisters.PermissionsToUseExternalResources.PermissionAddition
//
Function PermissionsSlice(Val ByOwners = True, Val NoDetails1 = False) Export
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.PermissionsToUseExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.PermissionsToUseExternalResourcesSaaS;
	EndIf;
	
	Result = New ValueTable();
	
	Result.Columns.Add("ProgramModuleType", 
		New TypeDescription("CatalogRef.MetadataObjectIDs"));
	Result.Columns.Add("ModuleID", New TypeDescription("UUID"));
	If ByOwners Then
		Result.Columns.Add("OwnerType", 
			New TypeDescription("CatalogRef.MetadataObjectIDs"));
		Result.Columns.Add("OwnerID", New TypeDescription("UUID"));
	EndIf;
	Result.Columns.Add("Type", New TypeDescription("String"));
	Result.Columns.Add("Permissions", New TypeDescription("Map"));
	
	Selection = Register.Select();
	
	While Selection.Next() Do
		
		Resolution = Common.XDTODataObjectFromXMLString(Selection.PermissionBody);
		
		FilterByTable = New Structure();
		FilterByTable.Insert("ProgramModuleType", Selection.ProgramModuleType);
		FilterByTable.Insert("ModuleID", Selection.ModuleID);
		If ByOwners Then
			FilterByTable.Insert("OwnerType", Selection.OwnerType);
			FilterByTable.Insert("OwnerID", Selection.OwnerID);
		EndIf;
		FilterByTable.Insert("Type", Resolution.Type().Name);
		
		String = PermissionsTableRow(Result, FilterByTable);
		
		PermissionBody = Selection.PermissionBody;
		PermissionKey = Selection.PermissionKey;
		
		If NoDetails1 Then
			
			If ValueIsFilled(Resolution.Description) Then
				
				Resolution.Description = "";
				PermissionBody = Common.XDTODataObjectToXMLString(Resolution);
				PermissionKey = PermissionKey(Resolution);
				
			EndIf;
			
		EndIf;
		
		String.Permissions.Insert(PermissionKey, PermissionBody);
		
	EndDo;
	
	Return Result;
	
EndFunction

// Writes a permission to the register.
//
// Parameters:
//  ProgramModuleType - CatalogRef.MetadataObjectIDs - 
//  ModuleID - UUID - 
//  OwnerType - CatalogRef.MetadataObjectIDs - 
//  OwnerID - UUID - 
//  PermissionKey - String - a permission key
//  Resolution - XDTODataObject - XDTO permission presentation
//  PermissionAddition - Arbitrary - serialized into XDTO.
//
Procedure AddPermission(Val ProgramModuleType, Val ModuleID, Val OwnerType, 
	Val OwnerID, Val PermissionKey, Val Resolution, Val PermissionAddition = Undefined) Export
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.PermissionsToUseExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.PermissionsToUseExternalResourcesSaaS;
	EndIf;
	
	Manager = Register.CreateRecordManager();
	Manager.ProgramModuleType = ProgramModuleType;
	Manager.ModuleID = ModuleID;
	Manager.OwnerType = OwnerType;
	Manager.OwnerID = OwnerID;
	Manager.PermissionKey = PermissionKey;
	
	Manager.Read();
	
	If Manager.Selected() Then
		
		Raise StrTemplate("%1
                  |- ProgramModuleType: %2
                  |- ModuleID: %3
                  |- OwnerType: %4
                  |- OwnerID: %5
                  |- PermissionKey: %6.",
			NStr("ru = 'Дублирование разрешений по ключевым полям:';
				|en = 'Duplicate permissions by key fields:';"),
			String(ProgramModuleType),
			String(ModuleID),
			String(OwnerType),
			String(OwnerID),
			PermissionKey);
		
	Else
		
		Manager.ProgramModuleType = ProgramModuleType;
		Manager.ModuleID = ModuleID;
		Manager.OwnerType = OwnerType;
		Manager.OwnerID = OwnerID;
		Manager.PermissionKey = PermissionKey;
		Manager.PermissionBody = Common.XDTODataObjectToXMLString(Resolution);
		
		Manager.Write(False);
		
	EndIf;
	
EndProcedure

// Deletes the permission from the register.
//
// Parameters:
//  ProgramModuleType - CatalogRef.MetadataObjectIDs - 
//  ModuleID - UUID -
//  OwnerType - CatalogRef.MetadataObjectIDs - 
//  OwnerID - UUID -
//  PermissionKey - String - a permission key
//  Resolution - XDTODataObject - XDTO permission presentation.
//
Procedure DeletePermission(Val ProgramModuleType, Val ModuleID, Val OwnerType, 
	Val OwnerID, Val PermissionKey, Val Resolution) Export
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.PermissionsToUseExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.PermissionsToUseExternalResourcesSaaS;
	EndIf;
	
	Manager = Register.CreateRecordManager();
	Manager.ProgramModuleType = ProgramModuleType;
	Manager.ModuleID = ModuleID;
	Manager.OwnerType = OwnerType;
	Manager.OwnerID = OwnerID;
	Manager.PermissionKey = PermissionKey;
	
	Manager.Read();
	
	If Manager.Selected() Then
		
		If Manager.PermissionBody <> Common.XDTODataObjectToXMLString(Resolution) Then
			
			Raise StrTemplate("%1
	                  |- ProgramModuleType: %2
	                  |- ModuleID: %3
	                  |- OwnerType: %4
	                  |- OwnerID: %5
	                  |- PermissionKey: %6.",
				NStr("ru = 'Коллизия разрешений по ключам:';
					|en = 'Permission collision by keys:';"),
				String(ProgramModuleType),
				String(ModuleID),
				String(OwnerType),
				String(OwnerID),
				PermissionKey);
				
		EndIf;
		
		Manager.Delete();
		
	Else
		
		Raise StrTemplate("%1
                  |- ProgramModuleType: %2
                  |- ModuleID: %3
                  |- OwnerType: %4
                  |- OwnerID: %5
                  |- PermissionKey: %6.",
			NStr("ru = 'Попытка удаления несуществующего разрешения:';
				|en = 'Attempt to delete a non-existing permission:';"),
			String(ProgramModuleType),
			String(ModuleID),
			String(OwnerType),
			String(OwnerID),
			PermissionKey);
		
	EndIf;
	
EndProcedure

// Deletes requests to use external resources.
//
// Parameters:
//  RequestsIDs - Array of UUID - IDs of deleted requests.
//
Procedure DeleteRequests(Val RequestsIDs) Export
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.RequestPermissionsToAccessExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.RequestPermissionsToAccessExternalResourcesSaaS;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		For Each QueryID In RequestsIDs Do
			
			Manager = Register.CreateRecordManager();
			Manager.QueryID = QueryID;
			Manager.Delete();
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Clears irrelevant requests to use external resources.
//
Procedure ClearObsoleteRequests() Export
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.RequestPermissionsToAccessExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.RequestPermissionsToAccessExternalResourcesSaaS;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		Selection = Register.Select();
		
		While Selection.Next() Do
			
			Try
				
				Var_Key = Register.CreateRecordKey(New Structure("QueryID", Selection.QueryID));
				LockDataForEdit(Var_Key);
				
			Except
				
				// Do not handle exceptions. The expected exception:
				// An attempt to delete the same register record in another session.
				Continue;
				
			EndTry;
			
			Manager = Register.CreateRecordManager();
			Manager.QueryID = Selection.QueryID;
			Manager.Delete();
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Creates and initializes a manager for requests to use external resources.
//
// Parameters:
//  RequestsIDs - Array of UUID - request IDs, for
//   which a manager is created.
//
// Returns:
//   DataProcessorObject.ExternalResourcesPermissionsSetup - manager.
//
Function PermissionsApplicationManager(Val RequestsIDs) Export
	
	Manager = DataProcessors.ExternalResourcesPermissionsSetupSaaS.Create();
	
	If Common.SeparatedDataUsageAvailable() Then
		Register = InformationRegisters.RequestPermissionsToAccessExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.RequestPermissionsToAccessExternalResourcesSaaS;
	EndIf;
	
	QueryText =
		"SELECT
		|	Queries.ProgramModuleType,
		|	Queries.ModuleID,
		|	Queries.OwnerType,
		|	Queries.OwnerID,
		|	Queries.ReplacementMode,
		|	Queries.PermissionsToAdd,
		|	Queries.PermissionsToDelete,
		|	Queries.QueryID
		|FROM
		|	&Table AS Queries
		|WHERE
		|	Queries.QueryID IN(&RequestsIDs)";
	
	QueryText = StrReplace(QueryText, "&Table", Register.CreateRecordSet().Metadata().FullName());
	
	Query = New Query(QueryText);
	Query.SetParameter("RequestsIDs", RequestsIDs);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		RecordKey = Register.CreateRecordKey(New Structure("QueryID", Selection.QueryID));
		LockDataForEdit(RecordKey);
		
		PermissionsToAdd = New Array();
		If ValueIsFilled(Selection.PermissionsToAdd) Then
			
			Array = Common.ValueFromXMLString(Selection.PermissionsToAdd);
			
			For Each ArrayElement In Array Do
				PermissionsToAdd.Add(Common.XDTODataObjectFromXMLString(ArrayElement));
			EndDo;
			
		EndIf;
		
		PermissionsToDelete = New Array();
		If ValueIsFilled(Selection.PermissionsToDelete) Then
			
			Array = Common.ValueFromXMLString(Selection.PermissionsToDelete);
			
			For Each ArrayElement In Array Do
				PermissionsToDelete.Add(Common.XDTODataObjectFromXMLString(ArrayElement));
			EndDo;
			
		EndIf;
		
		Manager.AddRequestID(Selection.QueryID);
		
		Manager.AddRequestForPermissionsToUseExternalResources(
			Selection.ProgramModuleType,
			Selection.ModuleID,
			Selection.OwnerType,
			Selection.OwnerID,
			Selection.ReplacementMode,
			PermissionsToAdd,
			PermissionsToDelete);
		
	EndDo;
	
	Manager.CalculateRequestsApplication();
	
	Return Manager;
	
EndFunction

// ID of the applied request package.
// 
// Parameters: 
//  State - String - XML string.
// 
// Returns:
//  UUID
Function PackageOfAppliedRequests(Val State) Export
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.ApplyPermissionsToUseExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.ApplyPermissionsToUseExternalResourcesSaaS;
	EndIf;
	
	Manager = Register.CreateRecordManager();
	Manager.IDOfPackage = New UUID();
	Manager.State = State;
	
	Manager.Write();
	
	Return Manager.IDOfPackage;
	
EndFunction

// Parameters: 
//  IDOfPackage - String
// 
// Returns: 
//  EnumRef.ExternalResourcesUsageQueriesProcessingResultsSaaS
Function PackageProcessingResult(Val IDOfPackage) Export
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.ApplyPermissionsToUseExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.ApplyPermissionsToUseExternalResourcesSaaS;
	EndIf;
	
	Manager = Register.CreateRecordManager();
	Manager.IDOfPackage = New UUID();
	Manager.Read();
	
	If Manager.Selected() Then
		
		Return Manager.Result;
		
	Else
		
		Raise StrTemplate(
			NStr("ru = 'Не найден пакет запросов %1';
				|en = 'Query pack %1 is not found';"), IDOfPackage);
		
	EndIf;
	
EndFunction

Procedure SetResultOfPacketProcessing(Val Result) Export
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.ApplyPermissionsToUseExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.ApplyPermissionsToUseExternalResourcesSaaS;
	EndIf;
	
	Manager = Register.CreateRecordManager();
	Manager.IDOfPackage = New UUID();
	Manager.Result = Result;
	Manager.Write();
	
EndProcedure

// Package application manager.
// 
// Parameters: 
//  IDOfPackage - UUID
// 
// Returns: 
//  DataProcessorObject.ExternalResourcesPermissionsSetupSaaS
Function PackageApplicationManager (Val IDOfPackage) Export
	
	Manager = DataProcessors.ExternalResourcesPermissionsSetupSaaS.Create();
	Manager.ReadStateFromXMLString(StateOfPacketProcessing(IDOfPackage));
	
	Return Manager;
	
EndFunction

// Serializes requests for using external resources to send to the Service Manager.
//
// Parameters:
//  RequestsIDs - Array of UUID - request IDs.
//
// Returns:
//	XDTODataObject - {http://www.1c.ru/1cFresh/Application/Permissions/Management/a.b.c.d}PermissionsRequestsList.
//
Function SerializeRequestsForExternalResources(Val RequestsIDs) Export
	
	Envelope = XDTOFactory.Create(XDTOFactory.Type(PackageAdministrationOfPermissions(), "PermissionsRequestsList"));
	
	QueryText =
		"SELECT
		|	Queries.ProgramModuleType,
		|	Queries.ModuleID,
		|	Queries.OwnerType,
		|	Queries.OwnerID,
		|	Queries.ReplacementMode,
		|	Queries.PermissionsToAdd,
		|	Queries.PermissionsToDelete
		|FROM
		|	&Table AS Queries
		|WHERE
		|	Queries.QueryID IN(&RequestsIDs)";
	
	If SaaSOperations.SeparatedDataUsageAvailable() Then
		
		QueryText = StrReplace(QueryText, "&Table", 
			"InformationRegister.RequestPermissionsToAccessExternalResourcesForDataAreas");
		
	Else
		
		QueryText = StrReplace(QueryText, "&Table", 
			"InformationRegister.RequestPermissionsToAccessExternalResourcesSaaS");
		
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("RequestsIDs", RequestsIDs);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		PermissionsRequest = XDTOFactory.Create(XDTOFactory.Type(PackageAdministrationOfPermissions(), "PermissionsRequest"));
		
		PermissionsRequest.UUID = Selection.QueryID;
		
		ProgramModule = ReferenceByRegisterKey(Selection.ProgramModuleType, Selection.ModuleID);
		Owner = ReferenceByRegisterKey(Selection.OwnerType, Selection.OwnerID);
		
		SoftwareModulePresentation = Undefined;
		OwnerPresentation = Undefined;
		
		StandardProcessing = True;
		
		If Common.SubsystemExists(
			"StandardSubsystems.SaaSOperations.AdditionalReportsAndDataProcessorsSaaS") Then
			
			ModuleAdditionalReportsAndDataProcessorsSaaS = 
				Common.CommonModule("AdditionalReportsAndDataProcessorsSaaS");
			ModuleAdditionalReportsAndDataProcessorsSaaS.OnSerializeExternalResourceUsagePermissionsOwner(
				Owner, StandardProcessing, OwnerPresentation);
			
		EndIf;
		
		If StandardProcessing Then
			
			If ProgramModule = Catalogs.MetadataObjectIDs.EmptyRef() Then
				
				SoftwareModulePresentation = XDTOFactory.Create(XDTOFactory.Type(PackageAdministrationOfPermissions(), 
					"PermissionModuleApplication"));
				
			Else
				
				Raise StrTemplate(
					NStr("ru = 'Не сериализован программный модуль по ключу:
                          |- Тип: %1
                          |- Идентификатор: %2';
							|en = 'Unserialized key program module:
							|- Type: %1
							|- ID: %2';"),
					Selection.ProgramModuleType,
					Selection.ModuleID);
				
			EndIf;
			
			If Owner = Catalogs.MetadataObjectIDs.EmptyRef() Then
				
				OwnerPresentation = XDTOFactory.Create(XDTOFactory.Type(PackageAdministrationOfPermissions(), 
					"PermissionsOwnerApplication"));
				
			Else
				
				OwnerPresentation = XDTOFactory.Create(XDTOFactory.Type(PackageAdministrationOfPermissions(), 
					"PermissionsOwnerApplicationObject"));
				OwnerPresentation.Type = Selection.Owner.Metadata().FullName();
				OwnerPresentation.UUID = Selection.Owner.UUID();
				OwnerPresentation.Description = String(Selection.Owner);
				
			EndIf;
			
		EndIf;
		
		PermissionsRequest.Module = SoftwareModulePresentation;
		PermissionsRequest.Owner = OwnerPresentation;
		
		PermissionsToAdd = XDTOFactory.Create(XDTOFactory.Type(PackageAdministrationOfPermissions(), "PermissionsList"));
		If Not IsBlankString(Selection.PermissionsToAdd) Then
			PermissionsArray = Common.ValueFromXMLString(Selection.PermissionsToAdd);
			For Each ArrayElement In PermissionsArray Do
				PermissionsList = PermissionsToAdd.Permission; // XDTOList
				PermissionsList.Add(Common.XDTODataObjectFromXMLString(ArrayElement));
			EndDo;
		EndIf;
		PermissionsRequest.GrantPermissions = PermissionsToAdd;
		
		PermissionsToDelete = XDTOFactory.Create(XDTOFactory.Type(PackageAdministrationOfPermissions(), "PermissionsList"));
		If Not IsBlankString(Selection.PermissionsToDelete) Then
			PermissionsArray = Common.ValueFromXMLString(Selection.PermissionsToDelete);
			For Each ArrayElement In PermissionsArray Do
				PermissionsList = PermissionsToDelete.Permission; // XDTOList
				PermissionsList.Add(Common.XDTODataObjectFromXMLString(ArrayElement));
			EndDo;
		EndIf;
		PermissionsRequest.CancelPermissions = PermissionsToDelete;
		
		PermissionsRequest.ReplaceOwnerPermissions = Selection.ReplacementMode;
		
		ListOfRequests = Envelope.Request; // XDTOList
		ListOfRequests.Add(PermissionsRequest);
		
	EndDo;
	
	Return Envelope;
	
EndFunction

// Permission administration package.
// 
// Returns:
//  String
Function PackageAdministrationOfPermissions() Export
	
	Return "http://www.1c.ru/1cFresh/Application/Permissions/Management/1.0.0.1";
	
EndFunction

#EndRegion

#Region Private

Function StateOfPacketProcessing(Val IDOfPackage)
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.ApplyPermissionsToUseExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.ApplyPermissionsToUseExternalResourcesSaaS;
	EndIf;
	
	Manager = Register.CreateRecordManager();
	Manager.IDOfPackage = New UUID();
	Manager.Read();
	
	If Manager.Selected() Then
		
		Return Manager.State;
		
	Else
		
		Raise StrTemplate(NStr("ru = 'Не найден пакет запросов %1';
										|en = 'Query pack %1 is not found';"), IDOfPackage);
		
	EndIf;
	
EndFunction

Procedure WhenRequestingChangesToSecurityProfiles(Val ProgramModule, StandardProcessing, Result)
	
	If Common.DataSeparationEnabled() Then
		
		StandardProcessing = False;
		Result  = New UUID();
		
	EndIf;
	
EndProcedure

#EndRegion