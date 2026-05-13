////////////////////////////////////////////////////////////////////////////////
// Remote administration subsystem.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Handlers of SSL subsystem events.

// Called before an attempt to write infobase parameters as
// constants with the same name.
//
// Parameters:
// ParameterValues - Structure - Parameter values to assign.
// If the value is assigned in this procedure, delete the corresponding KeyAndValue pair from the structure.
// 
//
Procedure OnSetIBParametersValues(Val ParameterValues) Export
	
	If ParameterValues.Property("InternalServiceManagerURL") Then
		
		SaaSOperationsCTL.SetInternalAddressOfServiceManager(ParameterValues.InternalServiceManagerURL);
		ParameterValues.Delete("InternalServiceManagerURL");
		
	EndIf;
	
	If ParameterValues.Property("URLOfService") Then
		
		SaaSOperationsCTL.SetInternalAddressOfServiceManager(ParameterValues.URLOfService);
		ParameterValues.Delete("URLOfService");
		
	EndIf;
	
	Owner = Common.MetadataObjectID("Constant.InternalServiceManagerURL");
	
	If ParameterValues.Property("InternalServiceUserName") Then
		
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Owner, ParameterValues.InternalServiceUserName, "ServiceManagerInternalUserName");
		SetPrivilegedMode(False);
		
		ParameterValues.Delete("InternalServiceUserName");
		
	EndIf;
	
	If ParameterValues.Property("InternalServiceUserPassword") Then
		
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Owner, ParameterValues.InternalServiceUserPassword, "ServiceManagerInternalUserPassword");
		SetPrivilegedMode(False);
		
		ParameterValues.Delete("InternalServiceUserPassword");
		
	EndIf;
	
	If ParameterValues.Property("ServiceManagerInternalUserName") Then
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Owner, ParameterValues.ServiceManagerInternalUserName, "ServiceManagerInternalUserName");
		SetPrivilegedMode(False);
		ParameterValues.Delete("ServiceManagerInternalUserName");
	EndIf;
	
	If ParameterValues.Property("ServiceManagerInternalUserPassword") Then
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Owner, ParameterValues.ServiceManagerInternalUserPassword, "ServiceManagerInternalUserPassword");
		SetPrivilegedMode(False);
		ParameterValues.Delete("ServiceManagerInternalUserPassword");
	EndIf;
	
EndProcedure

// Fills in the passed array with the common modules used as
//  incoming message interface handlers.
//
// Parameters:
//  HandlersArray - Array - an array of handlers. 
//
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
	
	HandlersArray.Add(RemoteAdministrationMessagesInterface);
	
EndProcedure

// Fills in the passed array with the common modules used as
//  outgoing message interface handlers.
//
// Parameters:
//  HandlersArray - Array - an array of handlers.
//
//
Procedure RecordingOutgoingMessageInterfaces(HandlersArray) Export
	
	HandlersArray.Add(RemoteAdministrationControlMessagesInterface);
	HandlersArray.Add(ApplicationManagementMessagesInterface);
	
EndProcedure

#EndRegion
