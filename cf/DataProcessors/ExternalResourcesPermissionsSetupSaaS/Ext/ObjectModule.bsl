#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

////////////////////////////////////////////////////////////////////////////////
// 
// 
// 
//
////////////////////////////////////////////////////////////////////////////////

#Region Variables

// 
Var RequestsIDs; // Array of UUID - request IDs.

// 
Var RequestsApplicationPlan; // Structure - Structure with the following fields:
//  * Замещаемые - ValueTable - :
//     ** ТипПрограммногоМодуля - CatalogRef.MetadataObjectIDs,
//     ** ИдентификаторПрограммногоМодуля - UUID,
//     ** ТипВладельца - CatalogRef.MetadataObjectIDs,
//     ** ИдентификаторВладельца - UUID,
//  * Добавляемые - ValueTable - :
//     ** ТипПрограммногоМодуля - CatalogRef.MetadataObjectIDs,
//     ** ИдентификаторПрограммногоМодуля - UUID,
//     ** ТипВладельца - CatalogRef.MetadataObjectIDs,
//     ** ИдентификаторВладельца - UUID,
//     ** Тип - String -  name of the XDTO type that describes permissions,
//     ** Разрешения - Map - :
//        *** Ключ - String -  (See InformationRegisters.PermissionsToUseExternalResources.PermissionKey)
//        *** Значение - XDTODataObject - 
//  * Удаляемые - ValueTable - :
//     ** ТипПрограммногоМодуля - CatalogRef.MetadataObjectIDs,
//     ** ИдентификаторПрограммногоМодуля - UUID,
//     ** ТипВладельца - CatalogRef.MetadataObjectIDs,
//     ** ИдентификаторВладельца - UUID,
//     ** Тип - String -  name of the XDTO type that describes permissions,
//     ** Разрешения - Map - :
//        *** Ключ - String -  (See InformationRegisters.PermissionsToUseExternalResources.PermissionKey)
//        *** Значение - XDTODataObject -  

// 
Var SourcePermissionSliceByOwners; // ValueTable - Columns:
// * ТипПрограммногоМодуля - CatalogRef.MetadataObjectIDs,
// * ИдентификаторПрограммногоМодуля - UUID,
// * ТипВладельца - CatalogRef.MetadataObjectIDs,
// * ИдентификаторВладельца - UUID,
// * Тип - String -  name of the XDTO type that describes permissions,
// * Разрешения - Map - :
//   ** Ключ - String -  (See InformationRegisters.PermissionsToUseExternalResources.PermissionKey)
//   ** Значение - XDTODataObject -  XDTO - description of the permission.

//  
Var SourcePermissionSliceIgnoringOwners; // ValueTable - Columns:
// * ТипПрограммногоМодуля - CatalogRef.MetadataObjectIDs,
// * ИдентификаторПрограммногоМодуля - UUID,
// * Тип - String -  name of the XDTO type that describes permissions,
// * Разрешения - Map - :
//   ** Ключ - String -  (See InformationRegisters.PermissionsToUseExternalResources.PermissionKey)
//   ** Значение - XDTODataObject -  XDTO - description of the permission.

// 
Var RequestsApplicationResultByOwners; // ValueTable - Columns:
// * ТипПрограммногоМодуля - CatalogRef.MetadataObjectIDs,
// * ИдентификаторПрограммногоМодуля - UUID,
// * ТипВладельца - CatalogRef.MetadataObjectIDs,
// * ИдентификаторВладельца - UUID,
// * Тип - String -  name of the XDTO type that describes permissions,
// * Разрешения - Map - :
//   ** Ключ - String -  (See InformationRegisters.PermissionsToUseExternalResources.PermissionKey)
//   ** Значение - XDTODataObject -  XDTO - description of the permission.

// 
Var RequestsApplicationResultIgnoringOwners; // ValueTable - Columns:
// * ТипПрограммногоМодуля - CatalogRef.MetadataObjectIDs,
// * ИдентификаторПрограммногоМодуля - UUID,
// * Тип - String -  name of the XDTO type that describes permissions,
// * Разрешения - Map - :
//   ** Ключ - String - 
//      
//   ** Значение - XDTODataObject -  XDTO - description of the permission.

// 
Var DeltaByOwners; // Structure - Fields:
//  * Добавляемые - ValueTable - :
//    ** ТипПрограммногоМодуля - CatalogRef.MetadataObjectIDs,
//    ** ИдентификаторПрограммногоМодуля - UUID,
//    ** ТипВладельца - CatalogRef.MetadataObjectIDs,
//    ** ИдентификаторВладельца - UUID,
//    ** Тип - String -  name of the XDTO type that describes permissions,
//    ** Разрешения - Map - :
//       *** Ключ - String -  (See InformationRegisters.PermissionsToUseExternalResources.PermissionKey)
//       *** Значение - XDTODataObject - 
//  * Удаляемые - ValueTable - :
//    ** ТипПрограммногоМодуля - CatalogRef.MetadataObjectIDs,
//    ** ИдентификаторПрограммногоМодуля - UUID,
//    ** ТипВладельца - CatalogRef.MetadataObjectIDs,
//    ** ИдентификаторВладельца - UUID,
//    ** Тип - String -  name of the XDTO type that describes permissions,
//    ** Разрешения - Map - :
//       *** Ключ - String -  (See InformationRegisters.PermissionsToUseExternalResources.PermissionKey)
//       *** Значение - XDTODataObject -  XDTO - description of the permission.

// 
Var DeltaIgnoringOwners; // Structure:
//  * Добавляемые - ValueTable - :
//    ** ТипПрограммногоМодуля - CatalogRef.MetadataObjectIDs,
//    ** ИдентификаторПрограммногоМодуля - UUID,
//    ** Тип - String -  name of the XDTO type that describes permissions,
//    ** Разрешения - Map of KeyAndValue - :
//       *** Ключ - String -  (See InformationRegisters.PermissionsToUseExternalResources.PermissionKey)
//       *** Значение - XDTODataObject - 
//  * Удаляемые - ValueTable - :
//    ** ТипПрограммногоМодуля - CatalogRef.MetadataObjectIDs,
//    ** ИдентификаторПрограммногоМодуля - UUID,
//    ** Тип - String -  name of the XDTO type that describes permissions,
//    ** Разрешения - Map of KeyAndValue - :
//       *** Ключ - String -  (See InformationRegisters.PermissionsToUseExternalResources.PermissionKey)
//       *** Значение - XDTODataObject -  XDTO - description of the permission.

#EndRegion

#Region Private

// Adds a permission ID to the list of permissions to be processed. Once the permissions are applied, the
// requests with added IDs are cleared.
//
// Parameters:
//  QueryID - UUID - an ID of the request to use external resources.
//
Procedure AddRequestID(Val QueryID) Export
	
	RequestsIDs.Add(QueryID);

EndProcedure

// Adds properties of the request for permissions to use external resources to the request application plan.
//
// Parameters:
//  ProgramModuleType - CatalogRef.MetadataObjectIDs - 
//  ModuleID - UUID - 
//  OwnerType - CatalogRef.MetadataObjectIDs - 
//  OwnerID - UUID - 
//  ReplacementMode - Boolean - 
//  PermissionsToAdd - Array of XDTODataObject, Undefined - permissions being added.
//  PermissionsToDelete - Array of XDTODataObject, Undefined - permissions being deleted.
//
Procedure AddRequestForPermissionsToUseExternalResources(
		Val ProgramModuleType, Val ModuleID,
		Val OwnerType, Val OwnerID,
		Val ReplacementMode,
		Val PermissionsToAdd = Undefined,
		Val PermissionsToDelete = Undefined) Export
	
	If ReplacementMode Then
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", ProgramModuleType);
		Filter.Insert("ModuleID", ModuleID);
		Filter.Insert("OwnerType", OwnerType);
		Filter.Insert("OwnerID", OwnerID);
		
		SafeModeManagerInternalSaaS.PermissionsTableRow(
			RequestsApplicationPlan.PermissionsToReplace, Filter);
		
	EndIf;
	
	If PermissionsToAdd <> Undefined Then
		
		For Each PermissionToAdd In PermissionsToAdd Do
			
			Filter = New Structure();
			Filter.Insert("ProgramModuleType", ProgramModuleType);
			Filter.Insert("ModuleID", ModuleID);
			Filter.Insert("OwnerType", OwnerType);
			Filter.Insert("OwnerID", OwnerID);
			Filter.Insert("Type", PermissionToAdd.Type().Name);
			
			String = SafeModeManagerInternalSaaS.PermissionsTableRow(
				RequestsApplicationPlan.ItemsToAdd, Filter);
			
			PermissionKey = SafeModeManagerInternalSaaS.PermissionKey(PermissionToAdd);
			String.Permissions.Insert(PermissionKey, Common.XDTODataObjectToXMLString(PermissionToAdd));
			
		EndDo;
		
	EndIf;
	
	If PermissionsToDelete <> Undefined Then
		
		For Each PermissionToDelete In PermissionsToDelete Do
			
			Filter = New Structure();
			Filter.Insert("ProgramModuleType", ProgramModuleType);
			Filter.Insert("ModuleID", ModuleID);
			Filter.Insert("OwnerType", OwnerType);
			Filter.Insert("OwnerID", OwnerID);
			Filter.Insert("Type", PermissionToAdd.Type().Name);
			
			String = SafeModeManagerInternalSaaS.PermissionsTableRow(
				RequestsApplicationPlan.ItemsToDelete, Filter);
			
			PermissionKey = SafeModeManagerInternalSaaS.PermissionKey(PermissionToDelete);
			String.Permissions.Add(PermissionKey, Common.XDTODataObjectToXMLString(PermissionToDelete));
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Calculates a result of application of requests to use external resources.
//
Procedure CalculateRequestsApplication() Export
	
	ExternalTransaction = TransactionActive();
	
	If Not ExternalTransaction Then
		BeginTransaction();
	EndIf;
	
	Try
		
		SafeModeManagerInternalSaaS.LockRegistersOfGrantedPermissions();
		
		SourcePermissionSliceByOwners = SafeModeManagerInternalSaaS.PermissionsSlice();
		CalculateRequestsApplicationResultByOwners();
		CalculateDeltaByOwners();
		
		SourcePermissionSliceIgnoringOwners = SafeModeManagerInternalSaaS.PermissionsSlice(False, True);
		CalculateRequestsApplicationResultIgnoringOwners();
		CalculateDeltaIgnoringOwners();
		
		If Not ExternalTransaction Then
			RollbackTransaction();
		EndIf;
		
	Except
		
		If Not ExternalTransaction Then
			RollbackTransaction();
		EndIf;
		
		Raise;
		
	EndTry;
	
EndProcedure

// Calculates a request application result by owners.
//
Procedure CalculateRequestsApplicationResultByOwners()
	
	RequestsApplicationResultByOwners = New ValueTable();
	
	For Each SourceColumn In SourcePermissionSliceByOwners.Columns Do
		RequestsApplicationResultByOwners.Columns.Add(SourceColumn.Name, SourceColumn.ValueType);
	EndDo;
	
	For Each InitialString In SourcePermissionSliceByOwners Do
		NewRow = RequestsApplicationResultByOwners.Add();
		FillPropertyValues(NewRow, InitialString);
	EndDo;
	
	// Apply the plan.
	
	// Overwrite.
	For Each ReplacementTableRow In RequestsApplicationPlan.PermissionsToReplace Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", ReplacementTableRow.ProgramModuleType);
		Filter.Insert("ModuleID", ReplacementTableRow.ModuleID);
		Filter.Insert("OwnerType", ReplacementTableRow.OwnerType);
		Filter.Insert("OwnerID", ReplacementTableRow.OwnerID);
		
		Rows = RequestsApplicationResultByOwners.FindRows(Filter);
		
		For Each String In Rows Do
			RequestsApplicationResultByOwners.Delete(String);
		EndDo;
		
	EndDo;
	
	// Add permissions.
	For Each PermissionsToAddRow In RequestsApplicationPlan.ItemsToAdd Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", PermissionsToAddRow.ProgramModuleType);
		Filter.Insert("ModuleID", PermissionsToAddRow.ModuleID);
		Filter.Insert("OwnerType", PermissionsToAddRow.OwnerType);
		Filter.Insert("OwnerID", PermissionsToAddRow.OwnerID);
		Filter.Insert("Type", PermissionsToAddRow.Type);
		
		String = SafeModeManagerInternalSaaS.PermissionsTableRow(
			RequestsApplicationResultByOwners, Filter);
		
		For Each KeyAndValue In PermissionsToAddRow.Permissions Do
			String.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
		
	EndDo;
	
	// Delete permissions
	For Each ItemsToDeleteRow In RequestsApplicationPlan.ItemsToDelete Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", ItemsToDeleteRow.ProgramModuleType);
		Filter.Insert("ModuleID", ItemsToDeleteRow.ModuleID);
		Filter.Insert("OwnerType", ItemsToDeleteRow.OwnerType);
		Filter.Insert("OwnerID", ItemsToDeleteRow.OwnerID);
		Filter.Insert("Type", ItemsToDeleteRow.Type);
		
		String = SafeModeManagerInternalSaaS.PermissionsTableRow(
			RequestsApplicationResultByOwners, Filter);
		
		For Each KeyAndValue In ItemsToDeleteRow.Permissions Do
			String.Permissions.Delete(KeyAndValue.Key);
		EndDo;
		
	EndDo;
	
EndProcedure

// Calculates a request application result ignoring owners.
//
Procedure CalculateRequestsApplicationResultIgnoringOwners()
	
	RequestsApplicationResultIgnoringOwners = New ValueTable();
	If TypeOf(SourcePermissionSliceIgnoringOwners) = Type("ValueTable") Then
		For Each SourceColumn In SourcePermissionSliceIgnoringOwners.Columns Do
			RequestsApplicationResultIgnoringOwners.Columns.Add(SourceColumn.Name, SourceColumn.ValueType);
		EndDo;
	EndIf;
	
	For Each ResultString1 In RequestsApplicationResultByOwners Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", ResultString1.ProgramModuleType);
		Filter.Insert("ModuleID", ResultString1.ModuleID);
		Filter.Insert("Type", ResultString1.Type);
		
		String = SafeModeManagerInternalSaaS.PermissionsTableRow(
			RequestsApplicationResultIgnoringOwners, Filter);
		
		For Each KeyAndValue In ResultString1.Permissions Do
			
			SourcePermission = Common.XDTODataObjectFromXMLString(KeyAndValue.Value);
			SourcePermission.Description = ""; // Details must not affect hash sums for an option without owners
			
			PermissionKey = SafeModeManagerInternalSaaS.PermissionKey(SourcePermission);
			
			Resolution = String.Permissions.Get(PermissionKey);
			
			If Resolution = Undefined Then
				
				If ResultString1.Type = "FileSystemAccess" Then
					
					// Search for nested or parent permissions in order to use the file system directory.
					// 
					
					If SourcePermission.AllowedRead Then
						
						If SourcePermission.AllowedWrite Then
							
							// Searching for the read permission for the same catalog.
							
							PermissionCopy = Common.XDTODataObjectFromXMLString(Common.XDTODataObjectToXMLString(SourcePermission));
							PermissionCopy.AllowedWrite = False;
							CopyKey = SafeModeManagerInternalSaaS.PermissionKey(PermissionCopy);
							
							NestedPermission = String.Permissions.Get(CopyKey);
							
							If NestedPermission <> Undefined Then
								
								// Deleting the nested permission. It becomes useless once the current one is added
								String.Permissions.Delete(CopyKey);
								
							EndIf;
							
						Else
							
							// Searching for a permission to read and write to the same catalog.
							
							PermissionCopy = Common.XDTODataObjectFromXMLString(Common.XDTODataObjectToXMLString(SourcePermission));
							PermissionCopy.AllowedWrite = True;
							CopyKey = SafeModeManagerInternalSaaS.PermissionKey(PermissionCopy);
							
							ParentPermission = String.Permissions.Get(CopyKey);
							
							If ParentPermission <> Undefined Then
								
								// No need to process the permission, the catalog is available by the parent permission.
								Continue;
								
							EndIf;
							
						EndIf;
						
					EndIf;
					
				EndIf;
				
				String.Permissions.Insert(PermissionKey, Common.XDTODataObjectToXMLString(SourcePermission));
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Calculates a delta between two permission slices by owners.
//
Procedure CalculateDeltaByOwners()
	
	DeltaByOwners = New Structure();
	
	DeltaByOwners.Insert("ItemsToAdd", New ValueTable);
	DeltaByOwners.ItemsToAdd.Columns.Add("ProgramModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaByOwners.ItemsToAdd.Columns.Add("ModuleID", New TypeDescription("UUID"));
	DeltaByOwners.ItemsToAdd.Columns.Add("OwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaByOwners.ItemsToAdd.Columns.Add("OwnerID", New TypeDescription("UUID"));
	DeltaByOwners.ItemsToAdd.Columns.Add("Type", New TypeDescription("String"));
	DeltaByOwners.ItemsToAdd.Columns.Add("Permissions", New TypeDescription("Map"));
	
	DeltaByOwners.Insert("ItemsToDelete", New ValueTable);
	DeltaByOwners.ItemsToDelete.Columns.Add("ProgramModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaByOwners.ItemsToDelete.Columns.Add("ModuleID", New TypeDescription("UUID"));
	DeltaByOwners.ItemsToDelete.Columns.Add("OwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaByOwners.ItemsToDelete.Columns.Add("OwnerID", New TypeDescription("UUID"));
	DeltaByOwners.ItemsToDelete.Columns.Add("Type", New TypeDescription("String"));
	DeltaByOwners.ItemsToDelete.Columns.Add("Permissions", New TypeDescription("Map"));
	
	// Comparing source permissions with the resulting ones
	
	For Each String In SourcePermissionSliceByOwners Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", String.ProgramModuleType);
		Filter.Insert("ModuleID", String.ModuleID);
		Filter.Insert("OwnerType", String.OwnerType);
		Filter.Insert("OwnerID", String.OwnerID);
		Filter.Insert("Type", String.Type);
		
		Rows = RequestsApplicationResultByOwners.FindRows(Filter);
		If Rows.Count() > 0 Then
			ResultString1 = Rows.Get(0);
		Else
			ResultString1 = Undefined;
		EndIf;
		
		For Each KeyAndValue In String.Permissions Do
			
			If ResultString1 = Undefined Or ResultString1.Permissions.Get(KeyAndValue.Key) = Undefined Then
				
				// The permission was in the source ones  but it is absent in the resulting ones, it is a permission being deleted.
				
				ItemsToDeleteRow = SafeModeManagerInternalSaaS.PermissionsTableRow(
					DeltaByOwners.ItemsToDelete, Filter);
				
				If ItemsToDeleteRow.Permissions.Get(KeyAndValue.Key) = Undefined Then
					ItemsToDeleteRow.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// Comparing the resulting permissions with the source ones
	
	For Each String In RequestsApplicationResultByOwners Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", String.ProgramModuleType);
		Filter.Insert("ModuleID", String.ModuleID);
		Filter.Insert("OwnerType", String.OwnerType);
		Filter.Insert("OwnerID", String.OwnerID);
		Filter.Insert("Type", String.Type);
		
		Rows = SourcePermissionSliceByOwners.FindRows(Filter);
		If Rows.Count() > 0 Then
			InitialString = Rows.Get(0);
		Else
			InitialString = Undefined;
		EndIf;
		
		For Each KeyAndValue In String.Permissions Do
			
			If InitialString = Undefined Or InitialString.Permissions.Get(KeyAndValue.Key) = Undefined Then
				
				// The permission is in resulting ones but it is absent in the source ones, it is a permission being added.
				
				PermissionsToAddRow = SafeModeManagerInternalSaaS.PermissionsTableRow(
					DeltaByOwners.ItemsToAdd, Filter);
				
				If PermissionsToAddRow.Permissions.Get(KeyAndValue.Key) = Undefined Then
					PermissionsToAddRow.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Calculates a delta between two permission slices ignoring owners.
//
Procedure CalculateDeltaIgnoringOwners()
	
	DeltaIgnoringOwners = New Structure();
	
	DeltaIgnoringOwners.Insert("ItemsToAdd", New ValueTable);
	DeltaIgnoringOwners.ItemsToAdd.Columns.Add("ProgramModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaIgnoringOwners.ItemsToAdd.Columns.Add("ModuleID", New TypeDescription("UUID"));
	DeltaIgnoringOwners.ItemsToAdd.Columns.Add("Type", New TypeDescription("String"));
	DeltaIgnoringOwners.ItemsToAdd.Columns.Add("Permissions", New TypeDescription("Map"));
	
	DeltaIgnoringOwners.Insert("ItemsToDelete", New ValueTable);
	DeltaIgnoringOwners.ItemsToDelete.Columns.Add("ProgramModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaIgnoringOwners.ItemsToDelete.Columns.Add("ModuleID", New TypeDescription("UUID"));
	DeltaIgnoringOwners.ItemsToDelete.Columns.Add("Type", New TypeDescription("String"));
	DeltaIgnoringOwners.ItemsToDelete.Columns.Add("Permissions", New TypeDescription("Map"));
	
	// Comparing source permissions with the resulting ones
	
	For Each String In SourcePermissionSliceIgnoringOwners Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", String.ProgramModuleType);
		Filter.Insert("ModuleID", String.ModuleID);
		Filter.Insert("Type", String.Type);
		
		Rows = RequestsApplicationResultIgnoringOwners.FindRows(Filter);
		If Rows.Count() > 0 Then
			ResultString1 = Rows.Get(0);
		Else
			ResultString1 = Undefined;
		EndIf;
		
		For Each KeyAndValue In String.Permissions Do
			
			If ResultString1 = Undefined Or ResultString1.Permissions.Get(KeyAndValue.Key) = Undefined Then
				
				// The permission was in the source ones  but it is absent in the resulting ones, it is a permission being deleted.
				
				ItemsToDeleteRow = SafeModeManagerInternalSaaS.PermissionsTableRow(
					DeltaIgnoringOwners.ItemsToDelete, Filter);
				
				If ItemsToDeleteRow.Permissions.Get(KeyAndValue.Key) = Undefined Then
					ItemsToDeleteRow.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// Comparing the resulting permissions with the source ones
	
	For Each String In RequestsApplicationResultIgnoringOwners Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", String.ProgramModuleType);
		Filter.Insert("ModuleID", String.ModuleID);
		Filter.Insert("Type", String.Type);
		
		Rows = SourcePermissionSliceIgnoringOwners.FindRows(Filter);
		If Rows.Count() > 0 Then
			InitialString = Rows.Get(0);
		Else
			InitialString = Undefined;
		EndIf;
		
		For Each KeyAndValue In String.Permissions Do
			
			If InitialString = Undefined Or InitialString.Permissions.Get(KeyAndValue.Key) = Undefined Then
				
				// The permission is in resulting ones but it is absent in the source ones, it is a permission being added.
				
				PermissionsToAddRow = SafeModeManagerInternalSaaS.PermissionsTableRow(
					DeltaIgnoringOwners.ItemsToAdd, Filter);
				
				If PermissionsToAddRow.Permissions.Get(KeyAndValue.Key) = Undefined Then
					PermissionsToAddRow.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Returns:
// Structure:
//  * ItemsToAdd - ValueTable - Details of the permissions being added. Contains the following columns:
//    ** ProgramModuleType - CatalogRef.MetadataObjectIDs,
//    ** ModuleID - UUID,
//    ** Type - String - an XDTO type name describing permissions,
//    ** Permissions - Map of KeyAndValue - Permission details:
//       *** Key - String - Permission key (See InformationRegisters.PermissionsToUseExternalResources.PermissionKey)
//                           .
//       *** Value - XDTODataObject - Permission details in XDTO format.
//  * ItemsToDelete - ValueTable - Details of the permissions being deleted. Contains the following columns:
//    ** ProgramModuleType - CatalogRef.MetadataObjectIDs,
//    ** ModuleID - UUID,
//    ** Type - String - an XDTO type name describing permissions,
//    ** Permissions - Map of KeyAndValue - Permission details:
//       *** Key - String - Permission key (See InformationRegisters.PermissionsToUseExternalResources.PermissionKey)
//                           .
//       *** Value - XDTODataObject - Permission details in XDTO format.
//
Function DeltaIgnoringOwners() Export
	
	Return DeltaIgnoringOwners;
	
EndFunction

// Checks whether permissions must be applied in the server cluster.
//
// Returns:
//   Boolean - 
//
Function MustApplyPermissionsInServersCluster() Export
	
	Return DeltaIgnoringOwners.ItemsToAdd.Count() > 0 Or DeltaIgnoringOwners.ItemsToDelete.Count() > 0;
	
EndFunction

// Checks whether the permissions must be written to registers.
//
// Returns:
//   Boolean - indicates whether it is necessary to write the permission.
//
Function RecordPermissionsToRegisterRequired() Export
	
	Return DeltaByOwners.ItemsToAdd.Count() > 0 Or DeltaByOwners.ItemsToDelete.Count() > 0;
	
EndFunction


// Serializes an internal state of the object.
// 
// Returns:
// 	String - an object state.
Function WriteStateToXMLString() Export
	
	State = New Structure();
	
	State.Insert("SourcePermissionSliceByOwners", SourcePermissionSliceByOwners);
	State.Insert("RequestsApplicationResultByOwners", RequestsApplicationResultByOwners);
	State.Insert("DeltaByOwners", DeltaByOwners);
	State.Insert("SourcePermissionSliceIgnoringOwners", SourcePermissionSliceIgnoringOwners);
	State.Insert("RequestsApplicationResultIgnoringOwners", RequestsApplicationResultIgnoringOwners);
	State.Insert("DeltaIgnoringOwners", DeltaIgnoringOwners);
	State.Insert("RequestsIDs", RequestsIDs);
	
	Return Common.ValueToXMLString(State);
	
EndFunction

// Deserializes an internal object state.
//
// Parameters:
//  XMLLine - String - a result returned by the WriteStateToXMLString() function.
//
Procedure ReadStateFromXMLString(Val XMLLine) Export
	
	State = Common.ValueFromXMLString(XMLLine);
	
	SourcePermissionSliceByOwners = State.SourcePermissionSliceByOwners;
	RequestsApplicationResultByOwners = State.RequestsApplicationResultByOwners;
	DeltaByOwners = State.DeltaByOwners;
	SourcePermissionSliceIgnoringOwners = State.SourcePermissionSliceIgnoringOwners;
	RequestsApplicationResultIgnoringOwners = State.RequestsApplicationResultIgnoringOwners;
	DeltaIgnoringOwners = State.DeltaIgnoringOwners;
	RequestsIDs = State.RequestsIDs;
	
EndProcedure

// Saves in the infobase the fact that requests to use external resource are applied.
//
Procedure CompleteApplyRequestsToUseExternalResources() Export
	
	BeginTransaction();
	
	Try
		
		If RecordPermissionsToRegisterRequired() Then
			
			For Each ItemsToDelete In DeltaByOwners.ItemsToDelete Do
				
				For Each KeyAndValue In ItemsToDelete.Permissions Do
					
					SafeModeManagerInternalSaaS.DeletePermission(
						ItemsToDelete.ProgramModuleType,
						ItemsToDelete.ModuleID,
						ItemsToDelete.OwnerType,
						ItemsToDelete.OwnerID,
						KeyAndValue.Key,
						Common.XDTODataObjectFromXMLString(KeyAndValue.Value));
					
				EndDo;
				
			EndDo;
			
			For Each ItemsToAdd In DeltaByOwners.ItemsToAdd Do
				
				For Each KeyAndValue In ItemsToAdd.Permissions Do
					
					SafeModeManagerInternalSaaS.AddPermission(
						ItemsToAdd.ProgramModuleType,
						ItemsToAdd.ModuleID,
						ItemsToAdd.OwnerType,
						ItemsToAdd.OwnerID,
						KeyAndValue.Key,
						Common.XDTODataObjectFromXMLString(KeyAndValue.Value));
					
				EndDo;
				
			EndDo;
			
		EndIf;
		
		SafeModeManagerInternalSaaS.DeleteRequests(RequestsIDs);
		SafeModeManagerInternalSaaS.ClearObsoleteRequests();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

Procedure CancelRequestsToUseExternalResources() Export
	
	SafeModeManagerInternalSaaS.DeleteRequests(RequestsIDs);
	
EndProcedure

#EndRegion

#Region Initialize

RequestsIDs = New Array();

RequestsApplicationPlan = New Structure();

MOIDType = New TypeDescription("CatalogRef.MetadataObjectIDs");

RequestsApplicationPlan.Insert("PermissionsToReplace", New ValueTable);
RequestsApplicationPlan.PermissionsToReplace.Columns.Add("ProgramModuleType", MOIDType);
RequestsApplicationPlan.PermissionsToReplace.Columns.Add("ModuleID", New TypeDescription("UUID"));
RequestsApplicationPlan.PermissionsToReplace.Columns.Add("OwnerType", MOIDType);
RequestsApplicationPlan.PermissionsToReplace.Columns.Add("OwnerID", New TypeDescription("UUID"));

RequestsApplicationPlan.Insert("ItemsToAdd", New ValueTable);
RequestsApplicationPlan.ItemsToAdd.Columns.Add("ProgramModuleType", MOIDType);
RequestsApplicationPlan.ItemsToAdd.Columns.Add("ModuleID", New TypeDescription("UUID"));
RequestsApplicationPlan.ItemsToAdd.Columns.Add("OwnerType", MOIDType);
RequestsApplicationPlan.ItemsToAdd.Columns.Add("OwnerID", New TypeDescription("UUID"));
RequestsApplicationPlan.ItemsToAdd.Columns.Add("Type", New TypeDescription("String"));
RequestsApplicationPlan.ItemsToAdd.Columns.Add("Permissions", New TypeDescription("Map"));

RequestsApplicationPlan.Insert("ItemsToDelete", New ValueTable);
RequestsApplicationPlan.ItemsToDelete.Columns.Add("ProgramModuleType", MOIDType);
RequestsApplicationPlan.ItemsToDelete.Columns.Add("ModuleID", New TypeDescription("UUID"));
RequestsApplicationPlan.ItemsToDelete.Columns.Add("OwnerType", MOIDType);
RequestsApplicationPlan.ItemsToDelete.Columns.Add("OwnerID", New TypeDescription("UUID"));
RequestsApplicationPlan.ItemsToDelete.Columns.Add("Type", New TypeDescription("String"));
RequestsApplicationPlan.ItemsToDelete.Columns.Add("Permissions", New TypeDescription("Map"));

AdministrationOperations = New ValueTable;
AdministrationOperations.Columns.Add("ProgramModuleType", MOIDType);
AdministrationOperations.Columns.Add("ModuleID", New TypeDescription("UUID"));
AdministrationOperations.Columns.Add("Operation", New TypeDescription("EnumRef.SecurityProfileAdministrativeOperations"));
AdministrationOperations.Columns.Add("Name", New TypeDescription("String"));

#EndRegion

#EndIf
