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

#Region Public

// Exports RLS texts of 2.x (older) and 3.x (newer) versions to files for further control over discrepancies.
//
// Parameters:
//  Parameters - Structure:
//   * ConfigurationExportFolder - String - Folder containing configuration dump files. To export roles is enough.
//   * NewDescriptionFolder       - String - Folder restriction texts export to.
//   * ReferenceDescriptionFolder   - String - Optional: Folder with the previous export results to be compared.
//                                          
//
//   * RLSControlServiceConnectionString  - String - Optional parameter, for internal use only.
//   * Project                                - String - Optional parameter, for internal use only.
//   * ProjectVersion                         - String - Optional parameter, for internal use only.
//
//   * Tables_Selection - See DetailsNew.Tables_Selection
//
Procedure ExportRestrictionsTexts(Val Parameters = Undefined) Export
	
	If TypeOf(Parameters) = Type("Structure") Then
		FillPropertyValues(ThisObject, Parameters);
		Tables_Selection = ?(Parameters.Property("Tables_Selection"), Parameters.Tables_Selection, Undefined);
		If Parameters.Property("RLSControlServiceConnectionString") Then
			Parameters.Insert("ConnectionString", InfoBaseConnectionString());
			Parameters.Insert("IBConfigurationName", Metadata.Name);
			Parameters.Insert("IBConfigurationDescription", Metadata.Synonym);
			Parameters.Insert("IBConfigurationVersion", Metadata.Version);
			Parameters.Insert("ComputerName", ComputerName());
			Parameters.Insert("DataCollectionDate", CurrentDate()); // ACC:143 - The computer date is required.
			Parameters.Insert("RestrictionsDetails1", DetailsNew(Tables_Selection));
			SendRestrictionsTexts(Parameters);
			Return;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(NewDescriptionFolder) Then
		ErrorText = NStr("ru = 'Не указана папка выгрузки новых описаний.';
							|en = 'A folder for exporting new description is not specified.';");
		Raise ErrorText;
	EndIf;
	
	CreateDirectory(NewDescriptionFolder);
	
	Otherness = New ValueList;
	For Each LongDesc In DetailsNew(Tables_Selection) Do
		Table = LongDesc.Key;
		NewDetailsText = LongDesc.Value;
		
		FileName = NewDescriptionFolder + Table + ".txt";
		TextWriter = New TextWriter(FileName);
		TextWriter.Write(NewDetailsText);
		TextWriter.Close();
		
		FileName = ReferenceDescriptionFolder + Table + ".txt";
		ReferenceText = ReadFile(FileName);
		
		If NewDetailsText <> ReferenceText Then
			Otherness.Add(Table);
		EndIf;
	EndDo;
	Otherness.SortByValue();
	Otherness = Otherness.UnloadValues();
	
	If ValueIsFilled(ReferenceDescriptionFolder) Then
		FileName = NewDescriptionFolder + "Otherness.txt";
		TextWriter = New TextWriter(FileName);
		TextWriter.WriteLine(StrConcat(Otherness, Chars.LF));
		TextWriter.Close();
	EndIf;
	
EndProcedure

// Returns RLS texts of versions 3.x (new) by tables.
//
// Parameters:
//  Tables_Selection - Undefined - Without filter
//              - Structure:
//                 * Subsystems - Map of KeyAndValue:
//                    ** Key - MetadataObject - Subsystem metadata object.
//                    ** Value - Boolean - If set to "True", the nested items are included.
//                 * OnlyObjectsInSpecifiedSubsystems - Boolean - If set to "False", then objects that belong to the specified subsystems will be skipped.
//                     
//
// Returns:
//  Map - a table name and RLS texts.
//
Function DetailsNew(Tables_Selection = Undefined) Export
	
	Result = New Map;
	
	TableOfConstraints = AccessRestrictionsFromUploadingConfigurationToFiles(ConfigurationExportFolder,, Tables_Selection);
	For Each TableRow In TableOfConstraints Do
		TableRow.Restriction = RemoveRestrictingAccessBracketsAtRecordLevelUniversal(TableRow.Restriction);
	EndDo;
	
	TempTable = TableOfConstraints.Copy(, "Table");
	TempTable.GroupBy("Table");
	TempTable.Sort("Table");
	TablesList = TempTable.UnloadColumn("Table");
	
	AllRestrictionsInRoles = AllRestrictionsInRoles(TableOfConstraints);
	RestrictedAccessLists = RestrictedAccessLists();
	
	For Each Table In TablesList Do
		RestrictionsInModules = RestrictionsInModules(Table, RestrictedAccessLists);
		RestrictionsInRoles = TableRestrictionsInRoles(Table, AllRestrictionsInRoles);
		NewDetailsText = RestrictionTextsAsString(RestrictionsInModules, RestrictionsInRoles);
		
		Result.Insert(Table, NewDetailsText);
	EndDo;
	
	Return Result;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Checks if restriction texts in different roles within an object/right/etc repeat each other.
// 
//
// Parameters:
//  AllParameters - Structure:
//   * UploadFolder   - String - Full path to the folder containing configuration dump files.
//   * ErrorsInDataExported - String - Return value.
//                       Not empty if exported directory specified in ExportFolder contains errors.
//
Procedure CheckAccessRestrictionsUse(AllParameters) Export
	
	AllParameters.Insert("ErrorsInDataExported", "");
	
	AccessRestrictions = AccessRestrictionsFromUploadingConfigurationToFiles(
		AllParameters.UploadFolder, AllParameters.ErrorsInDataExported);
	
	If ValueIsFilled(AllParameters.ErrorsInDataExported) Then
		Return;
	EndIf;
	
	AccessRestrictionKinds = New ValueTable;
	AccessRestrictionKinds.Columns.Add("Table",          New TypeDescription("String"));
	AccessRestrictionKinds.Columns.Add("Right",            New TypeDescription("String"));
	AccessRestrictionKinds.Columns.Add("AccessKind",       New TypeDescription("String"));
	AccessRestrictionKinds.Columns.Add("LongDesc",         New TypeDescription("String"));
	AccessRestrictionKinds.Columns.Add("ObjectTable",   New TypeDescription("String"));
	AccessRestrictionKinds.Columns.Add("CollectionOrder", New TypeDescription("Number"));
	AccessRestrictionKinds.Columns.Add("RightsOrder",      New TypeDescription("Number"));
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("AccessRestrictions",  AccessRestrictions);
	ProcedureParameters.Insert("AccessRestrictionKinds", AccessRestrictionKinds);
	
	DefineTypesOfRightsRestrictions(ProcedureParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Exports the current infobase configuration to files.
//
// Parameters:
//  UploadFolder   - String - Directory to export to.
//
//  UserName - Undefined - Use the name of the current user.
//                  - String - Name of the user who will run export.
//
//  Password          - Undefined - Use a blank password. If not blank, throw an error.
//                  - String - Use the specified password. If does not match, throw an error.
// 
//
Procedure ExportCurrentConfigurationToFiles(UploadFolder, UserName = Undefined, Password = Undefined)
	
	If Common.DataSeparationEnabled() Then
		ErrorText = NStr("ru = 'Модель сервиса не поддерживается.';
							|en = 'SaaS is not supported.';");
		Raise ErrorText;
	EndIf;
	
	If UserName = Undefined Then
		IBUser = InfoBaseUsers.FindByName(UserName);
	Else
		SetPrivilegedMode(True);
		IBUser = InfoBaseUsers.FindByName(UserName);
		SetPrivilegedMode(False);
	EndIf;
	
	If Not AccessRight("Administration", Metadata, IBUser) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'У пользователя ""%1"" нет права Администрирование,
			           |необходимого для выгрузки конфигурации в файлы.';
						|en = 'User ""%1"" does not have the Administration right
						|that is required to export configuration to files.';"),
			IBUser.Name);
		Raise ErrorText;
	EndIf;
	
	If Password = Undefined Then
		UsedPassword = "";
		If IBUser.PasswordIsSet Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'У пользователя ""%1"" установлен пароль, который не передан в процедуру,
				           |но является необходимым для выгрузки конфигурации в файлы.';
							|en = 'User ""%1"" has a password that is not passed to the procedure,
							|but it is necessary to export the configuration to files.';"),
				IBUser.Name);
			Raise ErrorText;
		EndIf;
	Else
		UsedPassword = Password;
		Properties = New Structure("PasswordHashAlgorithmType", Null);
		FillPropertyValues(Properties, IBUser);
		If Properties.PasswordHashAlgorithmType <> Null Then
			// ACC:488-off - Support of new 1C:Enterprise methods (the executable code is safe)
			PasswordMatches = Eval("CheckUserPasswordComplianceWithStoredValue(Password, IBUser)");
			// ACC:488-on
		Else
			PasswordMatches = IBUser.StoredPasswordValue
				= Users.PasswordHashString(Password);
		EndIf;
		If Not PasswordMatches Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'У пользователя ""%1"" установлен пароль, который не совпадает с переданным в процедуру,
				           |но является необходимым для выгрузки конфигурации в файлы.';
							|en = 'User ""%1"" has a password that does not match the one passed to the procedure,
							|but it is necessary to export the configuration to files.';"),
				IBUser.Name);
			Raise ErrorText;
		EndIf;
	EndIf;
	
	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("Password", UsedPassword);
	ConnectionParameters.Insert("User", UserName());
	
	ConnectionString = InfoBaseConnectionString();
	
	If StrStartsWith(ConnectionString, "File=") > 0 And DesignerIsOpened() Then
		CurrentIBDirectory = Mid(ConnectionString, 7, StrLen(ConnectionString) - 8);
		TempDirectory = GetTempFileName("");
		CreateDirectory(TempDirectory);
		FileCopy(CurrentIBDirectory + "\1Cv8.1CD", TempDirectory + "\1Cv8.1CD");
		ConnectionString = "File=""" + TempDirectory + """;";
	Else
		TempDirectory = "";
	EndIf;
	
	ConnectionParameters.Insert("ConnectionString", ConnectionString);
	
	DumpConfigurationToFiles(UploadFolder, ConnectionParameters);
	
	If ValueIsFilled(TempDirectory) Then
		DeleteFiles(TempDirectory);
	EndIf;
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// For internal use only.
Procedure DefineTypesOfRightsRestrictions(Parameters) Export
	
	AccessRestrictionKinds = Parameters.AccessRestrictionKinds;
	AccessRestrictions  = Parameters.AccessRestrictions; // ValueTable
	
	AccessRestrictions.Indexes.Add("Table, Role, Right, Fields, Restriction");
	AccessRestrictions.Sort("Table, Role, Right, Fields, Restriction");
	
	RolesAssignment = Users.RolesAssignment();
	
	RolesForExternalUsersOnly =
		RolesAssignment.ForExternalUsersOnly;
	
	RolesSharedBetweenUsersAndExternalUsers =
		RolesAssignment.BothForUsersAndExternalUsers;
	
	Restrictions = New ValueTable;
	Restrictions.Columns.Add("Table");
	Restrictions.Columns.Add("Role");
	Restrictions.Columns.Add("RoleForUsers");
	Restrictions.Columns.Add("RoleForExternalUsers");
	Restrictions.Columns.Add("Right");
	Restrictions.Columns.Add("Fields");
	Restrictions.Columns.Add("Restriction");
	Restrictions.Columns.Add("RestrictionWithoutComment");
	
	Restrictions.Columns.Add("SpecifiedTable"); // Table specified in the restriction.
	Restrictions.Columns.Add("SpecifiedRight");   // Right specified in the restriction.
	
	
	For Each String In AccessRestrictions Do
		
		Properties = New Structure("Table, Role, Right, Fields, Restriction, RestrictionWithoutComment");
		FillPropertyValues(Properties, String);
		
		Properties.Restriction = RemoveRestrictingAccessBracketsAtRecordLevelUniversal(Properties.Restriction);
		
		// Replace tabs with spaces.
		Properties.Restriction = StrReplace(Properties.Restriction, "	", "    ");
		
		// Delete newline characters at the beginning and end of the text.
		Properties.Restriction = TrimAll(Properties.Restriction);
		
		// Delete comments.
		Result = "";
		For RestrictionLineNumber = 1 To StrLineCount(Properties.Restriction) Do
			String = StrGetLine(Properties.Restriction, RestrictionLineNumber);
			CommentPosition = StrFind(String, "//");
			If CommentPosition > 0 Then
				String = Mid(String, 1, CommentPosition - 1);
			EndIf;
			If Not IsBlankString(Result) Then
				Result = Result + Chars.LF;
			EndIf;
			Result = Result + String;
		EndDo;
		Properties.RestrictionWithoutComment = TrimAll(Result);
		Restriction = Properties.RestrictionWithoutComment;
		
		If Upper(Properties.Role) = Upper("FullAccess")
			Or Upper(Properties.Role) = Upper("SystemAdministrator") Then
			Continue;
		EndIf;
		
		NewRow = Restrictions.Add();
		FillPropertyValues(NewRow, Properties);
		NewRow.RoleForUsers =
			RolesForExternalUsersOnly.Find(Properties.Role) = Undefined;
		NewRow.RoleForExternalUsers =
			RolesForExternalUsersOnly.Find(Properties.Role) <> Undefined
			Or RolesSharedBetweenUsersAndExternalUsers.Find(Properties.Role) <> Undefined;
		
		If Upper(Properties.Right) = Upper("Create")
		 Or Upper(Properties.Right) = Upper("Delete") Then
		
			// These access rights are not used in atomic access restrictions.
			// The "Insert" restriction matches the "Update" restriction.
			// The "Delete" restriction is either not used or matches the "Update" restriction.
			SkipToRight = True;
		Else
			SkipToRight = False;
		EndIf;
		
		Restriction = StrReplace(Restriction, Chars.LF, " ");
		While StrFind(Restriction, ", ") > 0 Do
			Restriction = StrReplace(Restriction, ", ", ",");
		EndDo;
		While StrFind(Restriction, " ,") > 0 Do
			Restriction = StrReplace(Restriction, " ,", ",");
		EndDo;
		
		If Upper(Left(Restriction, StrLen("#ByValues("))) = Upper("#ByValues(") Then
			
			Position = StrFind(Restriction, """");
			String = Mid(Restriction, Position + 1);
			
			NewRow.SpecifiedTable = Left(String, StrFind(String, """,""") - 1);
			
			CurrentRow = Mid(String, StrFind(String, """,""") + 3);
			NewRow.SpecifiedRight = Left(CurrentRow, StrFind(CurrentRow, """,""") - 1);
			
			If SkipToRight Then
				Continue;
			EndIf;
			
			Position = StrFind(Restriction, """,""");
			String = Mid(Restriction, Position + 3);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			While Position > 0 Do
				
				AccessKind = Left(String, StrFind(String, """,""")-1);
				
				If ValueIsFilled(AccessKind) Then
					
					Position = StrFind(String, """,""");
					String = Mid(String, Position + 3);
					
					FullFieldName1 = Left(String, StrFind(String, """,""")-1);
					// @skip-check query-in-loop - Obsolete code (the standard RLS variant)
					AddAccessType(NewRow, AccessRestrictionKinds, AccessKind, FullFieldName1, "");
					
					Position = StrFind(String, """,""");
					String = Mid(String, Position + 3);
				Else
					Break;
				EndIf;
			EndDo;
			
		ElsIf Upper(Left(Restriction, StrLen("#ByValuesExtended("))) = Upper("#ByValuesExtended(") Then
			
			Position = StrFind(Restriction, """");
			String = Mid(Restriction, Position + 1);
			
			NewRow.SpecifiedTable = Left(String, StrFind(String, """,""") - 1);
			
			CurrentRow = Mid(String, StrFind(String, """,""") + 3);
			NewRow.SpecifiedRight = Left(CurrentRow, StrFind(CurrentRow, """,""") - 1);
			
			If SkipToRight Then
				Continue;
			EndIf;
			
			Position = StrFind(Restriction, """,""");
			String = Mid(Restriction, Position + 3);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			AttachedTables = Left(String, StrFind(String, """,""")-1);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			While Position > 0 Do
				
				AccessKind = Left(String, StrFind(String, """,""")-1);
				
				If ValueIsFilled(AccessKind) Then
					
					Position = StrFind(String, """,""");
					String = Mid(String, Position + 3);
					
					FullFieldName1 = Left(String, StrFind(String, """,""")-1);
					// @skip-check query-in-loop - Obsolete code (the standard RLS variant)
					AddAccessType(NewRow, AccessRestrictionKinds, AccessKind, FullFieldName1, AttachedTables);
					
					Position = StrFind(String, """,""");
					String = Mid(String, Position + 3);
					
					Position = StrFind(String, """,""");
					String = Mid(String, Position + 3);
				Else
					Break;
				EndIf;
			EndDo;
			
		ElsIf Upper(Left(Restriction, StrLen("#ByValuesAndSetsAdvanced("))) = Upper("#ByValuesAndSetsAdvanced(") Then
			
			Position = StrFind(Restriction, """");
			String = Mid(Restriction, Position + 1);
			
			NewRow.SpecifiedTable = Left(String, StrFind(String, """,""") - 1);
			
			CurrentRow = Mid(String, StrFind(String, """,""") + 3);
			NewRow.SpecifiedRight = Left(CurrentRow, StrFind(CurrentRow, """,""") - 1);
			
			If SkipToRight Then
				Continue;
			EndIf;
			
			Position = StrFind(Restriction, """,""");
			String = Mid(Restriction, Position + 3);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			AttachedTables = Left(String, StrFind(String, """,""")-1);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			While Position > 0 Do
				
				AccessKind = Left(String, StrFind(String, """,""")-1);
				
				If ValueIsFilled(AccessKind) Then
					
					Position = StrFind(String, """,""");
					String = Mid(String, Position + 3);
					
					FullFieldName1 = Left(String, StrFind(String, """,""")-1);
					// @skip-check query-in-loop - Obsolete code (the standard RLS variant)
					AddAccessType(NewRow, AccessRestrictionKinds, AccessKind, FullFieldName1, AttachedTables);
					
					Position = StrFind(String, """,""");
					String = Mid(String, Position + 3);
					
					Position = StrFind(String, """,""");
					String = Mid(String, Position + 3);
				Else
					Break;
				EndIf;
			EndDo;
			
		ElsIf Upper(Left(Restriction, StrLen("#BySetsOfValues("))) = Upper("#BySetsOfValues(") Then
			
			Position = StrFind(Restriction, """");
			String = Mid(Restriction, Position + 1);
			
			NewRow.SpecifiedTable = Left(String, StrFind(String, """,""") - 1);
			
			CurrentRow = Mid(String, StrFind(String, """,""") + 3);
			NewRow.SpecifiedRight = Left(CurrentRow, StrFind(CurrentRow, """,""") - 1);
			
			If SkipToRight Then
				Continue;
			EndIf;
			
			Position = StrFind(Restriction, """,""");
			String = Mid(Restriction, Position + 3);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			Position = StrFind(String, """,""");
			String = Mid(String, Position + 3);
			
			FullFieldName1 = Left(String, StrFind(String, """,""")-1);
			
			AccessKind = "Object";
			
			If Not ValueIsFilled(FullFieldName1) Then
				FullFieldName1 = "Ref"; // @query-part-1
			EndIf;
			// @skip-check query-in-loop - Obsolete code (the standard RLS variant)
			AddAccessType(NewRow, AccessRestrictionKinds, AccessKind, FullFieldName1, "");
		EndIf;
	EndDo;
	
	// Remove the RightsSettings restriction kinds, for which the field has no types of right setting owners.
	Filter = New Structure("AccessKind, ObjectTable", "RightsSettings", "");
	FoundRows = AccessRestrictionKinds.FindRows(Filter);
	For Each String In FoundRows Do
		AccessRestrictionKinds.Delete(AccessRestrictionKinds.IndexOf(String));
	EndDo;
	
EndProcedure

#EndRegion

// For internal use only.
//
// Parameters:
//  UploadFolder - String
//  ErrorsInDataExported - String
//  Tables_Selection - See DetailsNew.Tables_Selection
//
// Returns:
//  ValueTable:
//    * Table - String
//    * Role - String
//    * Right - String
//    * Fields - String
//    * Restriction - String
//
Function AccessRestrictionsFromUploadingConfigurationToFiles(UploadFolder = "", ErrorsInDataExported = "",
			Tables_Selection = Undefined) Export
	
	If Not ValueIsFilled(UploadFolder) Then
		TempDirectory = GetTempFileName();
		CreateDirectory(TempDirectory);
		ExportCurrentConfigurationToFiles(TempDirectory);
		UploadFolder = TempDirectory;
	EndIf;
	
	RightsRestrictions = New ValueTable;
	RightsRestrictions.Columns.Add("Table",     New TypeDescription("String"));
	RightsRestrictions.Columns.Add("Role",        New TypeDescription("String"));
	RightsRestrictions.Columns.Add("Right",       New TypeDescription("String"));
	RightsRestrictions.Columns.Add("Fields",        New TypeDescription("String"));
	RightsRestrictions.Columns.Add("Restriction", New TypeDescription("String"));
	
	ErrorsInDataExported = "";
	For Each Role In Metadata.Roles Do
		AddRoleRightsRestrictions(RightsRestrictions, Role.Name, UploadFolder, ErrorsInDataExported, Tables_Selection);
	EndDo;
	
	If ValueIsFilled(TempDirectory) Then
		DeleteFiles(TempDirectory);
	EndIf;
	
	Return RightsRestrictions;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

// For procedure ExportCurrentConfigurationToFiles.
Function DesignerIsOpened()
	
	Sessions = GetInfoBaseSessions();
	
	For Each Session In Sessions Do
		If Session.ApplicationName = "Designer" Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// For procedure ExportCurrentConfigurationToFiles.
Procedure DumpConfigurationToFiles(UploadFolder, Parameters)
	
	MessagesFileName = UploadFolder + "\UploadConfigurationToFilesMessages.txt";
	
	ObjectsListFileName = GetTempFileName();
	TextWriter = New TextWriter(ObjectsListFileName);
	TextWriter.Write(StrConcat(AllRoles(), Chars.LF));
	TextWriter.Close();
	
	StartupCommand = New Array;
	StartupCommand.Add(BinDir() + "1cv8.exe");
	StartupCommand.Add("DESIGNER");
	StartupCommand.Add("/IBConnectionString");
	StartupCommand.Add(Parameters.ConnectionString);
	StartupCommand.Add("/N");
	StartupCommand.Add(Parameters.User);
	StartupCommand.Add("/P");
	StartupCommand.Add(Parameters.Password);
	StartupCommand.Add("/DumpConfigToFiles");
	StartupCommand.Add(UploadFolder);
	StartupCommand.Add("-listFile");
	StartupCommand.Add(ObjectsListFileName);
	StartupCommand.Add("/Out");
	StartupCommand.Add(MessagesFileName);
	StartupCommand.Add("/DisableStartupMessages");
	StartupCommand.Add("/DisableStartupDialogs");
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	
	Result = FileSystem.StartApplication(StartupCommand, ApplicationStartupParameters);
	
	DeleteFiles(ObjectsListFileName);
	
	If Result.ReturnCode <> 0 Then
		Try
			Text = New TextDocument;
			Text.Read(MessagesFileName);
			Messages = Text.GetText();
		Except
			Messages = "";
		EndTry;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось выполнить выгрузку конфигурации в файлы по причине:
			           |%1';
						|en = 'Failed to import configuration to files due to:
						|%1';"), Messages);
		Raise ErrorText;
	EndIf;
	
EndProcedure

// For procedure DumpConfigurationToFiles.
Function AllRoles()
	Result = New Array;
	For Each Role In Metadata.Roles Do
		If Role.ConfigurationExtension() = Undefined Then
			Result.Add(Role.FullName());
		EndIf;
	EndDo;
	Return Result;
EndFunction

#Region ObsoleteProceduresAndFunctions

// For procedure DefineAccessRestrictionsKinds.
Procedure AddAccessType(Val Properties, Val AccessRestrictionKinds,
		Val AccessTypesSet, Val FullFieldName1, Val AttachedTables)
	
	AccessKinds = StrSplit(AccessTypesSet, ",", False);
	
	For Each AccessKind In AccessKinds Do
		If AccessKind <> "Condition"
		   And AccessKind <> "ReadRight1"
		   And AccessKind <> "ReadRightByID"
		   And AccessKind <> "EditRight" Then
			
			Filter = New Structure("Table, Right, AccessKind, ObjectTable");
			
			Filter.Table    = Properties.Table;
			Filter.Right      = Properties.Right;
			Filter.AccessKind = AccessKind;
			
			If AccessKind = "Object" Or AccessKind = "RightsSettings" Then
				
				QueryText =
				"SELECT
				| &FullFieldName1 AS RequiredTypesField
				|FROM
				|	&TableName AS T
				|" + AttachedTables + "
				|WHERE
				|	FALSE"; // @query-part-1
				QueryText = StrReplace(QueryText, "&FullFieldName1", FullFieldName1);
				QueryText = StrReplace(QueryText, "&TableName", Properties.Table);
				Query = New Query(QueryText);
				
				If AccessKind = "RightsSettings" Then
					AvailableRights = AccessManagementInternal.RightsForObjectsRightsSettingsAvailable();
					RightsOwners = AvailableRights.ByFullNames;
				EndIf;
				// @skip-check query-in-loop - Obsolete code (the standard RLS variant)
				For Each Type In Query.Execute().Unload().Columns.RequiredTypesField.ValueType.Types() Do
					// ACC:1443-off - No.644.3.5. It's acceptable to access the metadata object as
					// the developer tool is integral to the subsystem to which the object belongs.
					If Metadata.InformationRegisters.AccessValuesSets.Dimensions.Object.Type.Types().Find(Type) <> Undefined Then
					// ACC:1443-on
						TypeMetadata = Metadata.FindByType(Type);
						TypeTable = TypeMetadata.FullName();
						If AccessKind = "RightsSettings" And RightsOwners.Get(TypeTable) = Undefined Then
							Continue;
						EndIf;
						Filter.ObjectTable = TypeTable;
						If AccessRestrictionKinds.FindRows(Filter).Count() = 0 Then
							FillPropertyValues(AccessRestrictionKinds.Add(), Filter);
						EndIf
					EndIf;
				EndDo;
				
			ElsIf AccessManagementInternal.AccessKindProperties(AccessKind) = Undefined Then
				
			Else
				Filter.ObjectTable = "";
				If AccessRestrictionKinds.FindRows(Filter).Count() = 0 Then
					FillPropertyValues(AccessRestrictionKinds.Add(), Filter);
				EndIf
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

// For procedure AccessRestrictionsFromConfigurationExportToFiles.
Procedure AddRoleRightsRestrictions(RightsRestrictions, Role, UploadFolder, ErrorDescription, Tables_Selection)
	
	Context = New Structure;
	Context.Insert("Paths",   New Structure("FolderForRightsExport", UploadFolder));
	Context.Insert("Log", New Structure("Text", ""));
	Context.Insert("ObjectsArray",       New Array);
	Context.Insert("MatchingObjects", New Map);
	Context.Insert("TemplatesArray1",       New Array);
	Context.Insert("PatternMatching", New Map);
	
	HasErrors = False;
	Try
		AddRoleRights(Role, Context, HasErrors);
	Except
		ErrorInfo = ErrorInfo();
		WriteMessage(Context.Log, Context.RoleRightsReadingErrorHeader,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		HasErrors = True;
	EndTry;
	
	If HasErrors Then
		ErrorDescription = Context.Log.Text;
		Return;
	EndIf;
	
	Rights = New Map;
	Rights.Insert("Read",   "Read");
	Rights.Insert("Insert", "Create");
	Rights.Insert("Update", "Update");
	Rights.Insert("Delete", "Delete");
	
	MatchingObjects = Context.MatchingObjects;
	SelectionSet = TypeOf(Tables_Selection) = Type("Structure");
	
	For Each ObjectDetails In MatchingObjects Do
		If StrOccurrenceCount(ObjectDetails.Key, ".") <> 1 Then
			Continue;
		EndIf;
		MetadataObject = Common.MetadataObjectByFullName(ObjectDetails.Key);
		If MetadataObject = Undefined Then
			WriteMessage(Context.Log, Context.RoleRightsReadingErrorHeader, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось найти объект метаданных ""%1"".';
					|en = 'Cannot find the ""%1"" metadata object.';"), ObjectDetails.Key));
			HasErrors = True;
			If SelectionSet Then
				Continue;
			EndIf;
		EndIf;
		If SelectionSet
		   And ObjectIsPartOfOneOfSubsystems(MetadataObject, Tables_Selection.Subsystems)
		     = Tables_Selection.OnlyObjectsInSpecifiedSubsystems Then
			Continue;
		EndIf;
		FullName = MetadataObject.FullName();
		
		RightsMap = ObjectDetails.Value.RightsMap;
		For Each RightDetails In RightsMap Do
			FieldRestrictions = RightDetails.Value.FieldRestrictions;
			If Not ValueIsFilled(FieldRestrictions) Then
				Continue;
			EndIf;
			Right = Rights[RightDetails.Key];
			For Each RestrictionDetails In FieldRestrictions Do
				If RestrictionDetails.Key = "" And Not ValueIsFilled(RestrictionDetails.Value) Then
					Continue;
				EndIf;
				Fields = ?(RestrictionDetails.Key = "", "<" + NStr("ru = 'Прочие поля';
																	|en = 'Other fields';") + ">", RestrictionDetails.Key);
				NewRow = RightsRestrictions.Add();
				NewRow.Table     = FullName;
				NewRow.Role        = Role;
				NewRow.Right       = Right;
				NewRow.Fields        = Fields;
				NewRow.Restriction = RestrictionDetails.Value;
			EndDo;
		EndDo;
	EndDo;
	
	If HasErrors Then
		ErrorDescription = Context.Log.Text;
		Return;
	EndIf;
	
EndProcedure

Function ObjectIsPartOfOneOfSubsystems(MetadataObject, CompositionOfSubsystems)
	
	For Each KeyAndValue In CompositionOfSubsystems Do
		If ObjectIsIncludedInSubsystem(MetadataObject, KeyAndValue.Key, KeyAndValue.Value) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Parameters:
//  MetadataObject - MetadataObject
//  Subsystem - MetadataObjectSubsystem
//  IncludingNested - Boolean
//
Function ObjectIsIncludedInSubsystem(MetadataObject, Subsystem, IncludingNested)
	
	If Subsystem.Content.Contains(MetadataObject) Then
		Return True;
	EndIf;
	
	If Not IncludingNested Then
		Return False;
	EndIf;
	
	For Each NestedSubsystem In Subsystem.Subsystems Do
		If ObjectIsIncludedInSubsystem(MetadataObject, NestedSubsystem, IncludingNested) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// For procedure AddRoleRightsRestrictions.
Procedure AddRoleRights(Role, Context, HasErrors)
	
	ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Права роли %1 не прочитаны по причине:';
			|en = 'Cannot read the %1 role access rights due to:';"), Role);
	
	Context.Insert("RoleRightsReadingErrorHeader", ErrorTitle);
	
	If Context.Property("OldFileNameFormat") Then
		RoleFileName = "Role." + Role + ".Rights.xml";
	Else
		
		RoleFileName = StrReplace("Roles\" + Role + "\Ext\Rights.xml", "\", GetPathSeparator());
	EndIf;
	RoleFullFileName = AddLastPathSeparator(Context.Paths.FolderForRightsExport) + RoleFileName;
	
	XMLReader = New XMLReader;
	Try
		XMLReader.OpenFile(RoleFullFileName);
	Except
		ErrorInfo = ErrorInfo();
		WriteMessage(Context.Log, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось открыть для чтения файл XML по причине:
			           |%1';
						|en = 'Cannot open an XML file for reading due to:
						|%1';"), ErrorProcessing.BriefErrorDescription(ErrorInfo)));
		HasErrors = True;
		Return;
	EndTry;
	
	If Not XMLReader.Read()
	 Or Not XMLReader.NodeType = XMLNodeType.StartElement
	 Or Not XMLReader.HasName
	 Or Not XMLReader.Name = "Rights"
	 Or Not XMLReader.NamespaceURI = "http://v8.1c.ru/8.2/roles"
	 Or Not XMLReader.Read()
	 Or Not ReadItemAndGoNext(XMLReader, "setForNewObjects") <> Undefined
	 Or Not ReadItemAndGoNext(XMLReader, "setForAttributesByDefault") <> Undefined
	 Or Not ReadItemAndGoNext(XMLReader, "independentRightsOfChildObjects") <> Undefined
	 Or Not XMLReader.HasName Then
		
		WriteMessage(Context.Log, ErrorTitle, NStr("ru = 'Некорректный файл прав';
																|en = 'Incorrect rights file';"));
		HasErrors = True;
		Return;
	EndIf;
	
	While Not (  XMLReader.Name = "Rights"
	         And XMLReader.NodeType = XMLNodeType.EndElement) Do
		
		If XMLReader.Name = "object" Then
			Try
				ReadObject(XMLReader, Context, ErrorTitle, HasErrors);
			Except
				ErrorInfo = ErrorInfo();
				WriteMessage(Context.Log, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось прочитать элемент %1 по причине:
					           |%2';
								|en = 'Cannot read the %1 object due to:
								|%2.';"),
					"object",
					ErrorProcessing.BriefErrorDescription(ErrorInfo)));
				HasErrors = True;
				Return;
			EndTry;
			
		ElsIf XMLReader.Name = "restrictionTemplate" Then
			Try
				ReadRestrictionTemplate(XMLReader, Context, ErrorTitle, HasErrors);
			Except
				ErrorInfo = ErrorInfo();
				WriteMessage(Context.Log, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось прочитать элемент %1 по причине:
					           |%2';
								|en = 'Cannot read the %1 object due to:
								|%2.';"),
					"restrictionTemplate",
					ErrorProcessing.BriefErrorDescription(ErrorInfo)));
				HasErrors = True;
				Return;
			EndTry;
		Else
			WriteMessage(Context.Log, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось прочитать файл прав, т.к. обнаружен неизвестный элемент %1';
					|en = 'Cannot read the rights file as an unknown item %1 is found';"), XMLReader.Name));
			HasErrors = True;
			Return;
		EndIf;
		If Not XMLReader.HasName Then
			WriteMessage(Context.Log, ErrorTitle, NStr("ru = 'В структуре XML элемент не завершен';
																	|en = 'XML element is not finished in the structure';"));
			HasErrors = True;
			Return;
		EndIf;
	EndDo;
	
EndProcedure

// For procedure AddRoleRights.
Procedure ReadObject(XMLReader, Context, ErrorTitle, HasErrors)
	
	XMLReader.Read();
	
	ObjectName = ReadItemAndGoNext(XMLReader, "name");
	If ObjectName = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не найдено свойство %1 (имя объекта)';
				|en = 'The %1 property (object name) is not found.';"), "name");
		Raise ErrorText;
	EndIf;
	
	ObjectProperties = Context.MatchingObjects.Get(ObjectName);
	If ObjectProperties = Undefined Then
		Context.ObjectsArray.Add(ObjectName);
		ObjectProperties = New Structure;
		ObjectProperties.Insert("RightsArray",       New Array);
		ObjectProperties.Insert("RightsMap", New Map);
		Context.MatchingObjects.Insert(ObjectName, ObjectProperties);
	EndIf;
	
	While XMLReader.NodeType = XMLNodeType.StartElement
	   And XMLReader.HasName
	   And XMLReader.Name = "right" Do
		
		Try
			ReadObjectSRight(XMLReader, Context, ObjectName, ObjectProperties, HasErrors);
		Except
			ErrorInfo = ErrorInfo();
			WriteMessage(Context.Log, ErrorTitle, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось прочитать элемент %1 элемента %2 с именем
				           |%3
				           |по причине:
				           |%4';
							|en = 'Cannot read the %1 item of the %2 item named
							|%3
							|due to:
							|%4.';"),
				"right",
				"object",
				ObjectName,
				ErrorProcessing.BriefErrorDescription(ErrorInfo)));
			HasErrors = True;
			Return;
		EndTry;
	EndDo;
	
	If Not XMLReader.NodeType = XMLNodeType.EndElement
	 Or Not XMLReader.HasName
	 Or Not XMLReader.Name = "object" Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось найти конец элемента %1 с именем:
			           |%2';
						|en = 'Cannot find the %1 item end named:
						|%2.';"),
			"object",
			ObjectName);
		Raise ErrorText;
	EndIf;
	
	XMLReader.Read();
	
EndProcedure

// For procedure ReadObject.
Procedure ReadObjectSRight(XMLReader, Context, ObjectName, ObjectProperties, HasErrors)
	
	XMLReader.Read();
	
	NameOfRight = ReadItemAndGoNext(XMLReader, "name");
	If NameOfRight = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не найдено свойство %1 (имя права)';
				|en = 'The %1 property (right name) is not found.';"),
			"name");
		Raise ErrorText;
	EndIf;
	
	RightsValue = ReadItemAndGoNext(XMLReader, "value");
	If NameOfRight = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не найдено свойство %1 (значение права с именем %2)';
				|en = 'The %1 property (right value named %2) is not found.';"),
			"value",
			NameOfRight);
		Raise ErrorText;
	EndIf;
	
	RightsValue = XMLValue(Type("Boolean"), RightsValue);
	
	RightProperties = ObjectProperties.RightsMap.Get(NameOfRight);
	If RightProperties = Undefined Then
		ObjectProperties.RightsArray.Add(NameOfRight);
		RightProperties = New Structure;
		RightProperties.Insert("Value",         RightsValue);
		RightProperties.Insert("FieldRestrictions", Undefined);
		ObjectProperties.RightsMap.Insert(NameOfRight, RightProperties);
	Else
		If RightsValue = True Then
			RightProperties.Value = True;
		EndIf;
	EndIf;
	
	FieldRestrictions = New Map;
	
	While XMLReader.NodeType = XMLNodeType.StartElement
	   And XMLReader.HasName
	   And XMLReader.Name = "restrictionByCondition" Do
		
		Try
			ReadFieldRestriction(XMLReader, Context, FieldRestrictions, ObjectName, NameOfRight, RightProperties);
		Except
			HasErrors = True;
			ErrorInfo = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось прочитать элемент %1 права %2 по причине:
				           |%3';
							|en = 'Couldn''t read element ""%1"" of right ""%2"". Reason:
							|%3.';"),
				"restrictionByCondition",
				NameOfRight,
				ErrorProcessing.BriefErrorDescription(ErrorInfo));
			Raise ErrorText;
		EndTry;
	EndDo;
	
	If RightsValue = True Then
		AddFieldRestrictions(Context, FieldRestrictions, ObjectName, NameOfRight, RightProperties, HasErrors);
	EndIf;
	
	If Not XMLReader.NodeType = XMLNodeType.EndElement
	 Or Not XMLReader.HasName
	 Or Not XMLReader.Name = "right" Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось найти конец элемента %1 с именем:
			           |%2';
						|en = 'Cannot find the %1 item end named:
						|%2.';"),
			"right", NameOfRight);
		Raise ErrorText;
	EndIf;
	
	XMLReader.Read();
	
EndProcedure

// For procedure ReadObjectRight.
Procedure ReadFieldRestriction(XMLReader, Context, FieldRestrictions, ObjectName, NameOfRight, RightProperties)
	
	XMLReader.Read();
	
	Fields = New Array;
	
	While XMLReader.NodeType = XMLNodeType.StartElement
	   And XMLReader.HasName
	   And XMLReader.Name = "field" Do
		
		FieldName = ReadItemAndGoNext(XMLReader, "field");
		If FieldName = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'У элемента %1 некорректное свойство %2';
					|en = 'Element ""%1"" has invalid property ""%2""';"),
				"restrictionByCondition",
				"field");
			Raise ErrorText;
		EndIf;
		Fields.Add(FieldName);
	EndDo;
	
	If Fields.Count() = 0 Then
		Fields.Add(""); // Other fields.
	EndIf;
	
	Restriction = ReadItemAndGoNext(XMLReader, "condition");
	If Restriction = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'У элемента %1 не найдено свойство %2';
				|en = 'Cannot find property ""%2"" of element ""%1""';"),
			"restrictionByCondition",
			"condition");
		Raise ErrorText;
	EndIf;
	
	For Each Field In Fields Do
		FieldRestrictions.Insert(Field, Restriction);
	EndDo;
	
	If Not XMLReader.NodeType = XMLNodeType.EndElement
	 Or Not XMLReader.HasName
	 Or Not XMLReader.Name = "restrictionByCondition" Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось найти конец элемента %1';
				|en = 'Cannot find the %1 item end.';"),
			"restrictionByCondition");
		Raise ErrorText;
	EndIf;
	
	XMLReader.Read();
	
EndProcedure

// For procedure ReadObjectRight.
Procedure AddFieldRestrictions(Context, FieldRestrictions, ObjectName, NameOfRight, RightProperties, HasErrors)
	
	If FieldRestrictions.Count() > 0
	   And FieldRestrictions.Get("") = Undefined Then
		
		// The "Other fields" restriction is always present (either empty or filled).
		FieldRestrictions.Insert("", "");
	EndIf;
	
	If RightProperties.FieldRestrictions = Undefined Then
		// Restrictions of the current right fields are processed for the first time.
		RightProperties.FieldRestrictions = FieldRestrictions;
		Return;
		
	ElsIf RightProperties.FieldRestrictions.Count() = 0 Then
		// One of the roles has no right restrictions to any of the fields.
		Return;
	EndIf;
	
	If FieldRestrictions.Count() = 0 Then
		// The current role has no right restrictions to any of the fields.
		RightProperties.FieldRestrictions = New Map;
		Return;
	EndIf;
	
	NewOtherFieldsRestriction = FieldRestrictions.Get("");
	
	// Check or update the current restrictions of some fields by a new restriction for other fields.
	For Each KeyAndValue In RightProperties.FieldRestrictions Do
		FieldName         = KeyAndValue.Key;
		FieldRestriction = KeyAndValue.Value;
		If FieldRestrictions.Get(FieldName) <> Undefined Then
			// This field has a new individual restriction setting.
			Continue;
		EndIf;
		If FieldRestriction = "" Then
			// This field has no restriction, therefore it must not match the new common restriction.
			Continue;
		EndIf;
		If NewOtherFieldsRestriction = "" Then
			RightProperties.FieldRestrictions[FieldName] = "";
		ElsIf FieldRestriction <> NewOtherFieldsRestriction Then
			HasErrors = True;
			WriteMessage(Context.Log, Context.RoleRightsReadingErrorHeader, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В объекте
				           |%1
				           |для права %2 ограничение поля с именем %3, загруженное ранее:
				           |%4
				           |не совпадает с указанным:
				           |%5';
							|en = 'In object
							|%1,
							|for the %2 right, restriction of the %3 field imported earlier
							|%4
							|does not match the specified one:
							|%5';"),
				ObjectName, NameOfRight, FieldName, FieldRestriction, NewOtherFieldsRestriction));
		EndIf;
	EndDo;
	
	// Check the current field restrictions using the new restrictions.
	// Apply restrictions to new individual fields.
	OldOtherFieldsRestriction = RightProperties.FieldRestrictions.Get("");
	For Each KeyAndValue In FieldRestrictions Do
		Field        = KeyAndValue.Key;
		Restriction = KeyAndValue.Value;
		
		FieldRestriction = RightProperties.FieldRestrictions.Get(Field);
		If FieldRestriction = Undefined Then
			FieldRestriction = OldOtherFieldsRestriction;
			RightProperties.FieldRestrictions.Insert(Field, FieldRestriction);
		EndIf;
		
		If FieldRestriction = "" Then
			// A field without a restriction cannot become a field with a restriction.
		ElsIf Restriction = "" Then
			RightProperties.FieldRestrictions[Field] = "";
		ElsIf FieldRestriction <> Restriction Then
			HasErrors = True;
			FieldName = ?(ValueIsFilled(Field), Field, "<" + NStr("ru = 'Прочие поля';
																	|en = 'Other fields';") + ">");
			WriteMessage(Context.Log, Context.RoleRightsReadingErrorHeader, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В объекте
				           |%1
				           |для права %2 ограничение поля с именем %3, загруженное ранее:
				           |%4
				           |не совпадает с указанным:
				           |%5';
							|en = 'In object
							|%1,
							|for the %2 right, restriction of the %3 field imported earlier
							|%4
							|does not match the specified one:
							|%5';"),
				ObjectName, NameOfRight, FieldName, FieldRestriction, Restriction));
		EndIf;
	EndDo;
	
EndProcedure

// For procedure AddRoleRights.
Procedure ReadRestrictionTemplate(XMLReader, Context, ErrorTitle, HasErrors)
	
	XMLReader.Read();
	
	TemplateName = ReadItemAndGoNext(XMLReader, "name");
	If TemplateName = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не найдено свойство %1 (имя шаблона)';
				|en = 'The %1 property (a template name) is not found.';"),
			"name");
		Raise ErrorText;
	EndIf;
	
	Template = ReadItemAndGoNext(XMLReader, "condition");
	If Template = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не найдено свойство %1 (текст шаблона)';
				|en = 'The %1 property (a template text) is not found.';"),
			"condition");
		Raise ErrorText;
	EndIf;
	
	TemplateText = Context.PatternMatching.Get(TemplateName);
	If TemplateText = Undefined Then
		Context.TemplatesArray1.Add(TemplateName);
		Context.PatternMatching.Insert(TemplateName, Template);
		
	ElsIf TemplateText <> Template Then
		HasErrors = True;
		WriteMessage(Context.Log, Context.RoleRightsReadingErrorHeader, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Текст шаблона с именем %1, загруженный ранее:
			           |%2
			           |не совпадает с указанным:
			           |%3';
						|en = 'Template text %1 imported earlier:
						|%2
						|does not match the specified one:
						|%3';"),
			TemplateName, TemplateText, Template));
	EndIf;
	
	If Not XMLReader.NodeType = XMLNodeType.EndElement
	 Or Not XMLReader.HasName
	 Or Not XMLReader.Name = "restrictionTemplate" Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось найти конец элемента %1';
				|en = 'Cannot find the %1 item end.';"),
			"restrictionTemplate");
		Raise ErrorText;
	EndIf;
	
	XMLReader.Read();
	
EndProcedure

// For procedures AddRoleRights, ReadObject, ReadObjectRight,
// ReadFieldsRestriction, ReadRestrictionTemplate.
//
Function ReadItemAndGoNext(XMLReader, TagName)
	
	If Not XMLReader.NodeType = XMLNodeType.StartElement
	 Or Not XMLReader.HasName
	 Or Not XMLReader.Name = TagName Then
		Return Undefined;
	EndIf;
	
	XMLReader.Read();
	
	If XMLReader.NodeType = XMLNodeType.EndElement
	   And XMLReader.HasName
	   And XMLReader.Name = TagName Then
		
		XMLReader.Read();
		Return "";
	EndIf;
	
	If Not XMLReader.NodeType = XMLNodeType.Text
	 Or Not XMLReader.HasValue Then
		Return Undefined;
	EndIf;
	
	Value = XMLReader.Value;
	
	XMLReader.Skip();
	
	If Not XMLReader.NodeType = XMLNodeType.EndElement
	 Or Not XMLReader.HasName
	 Or Not XMLReader.Name = TagName Then
		Return Undefined;
	EndIf;
	
	XMLReader.Read();
	
	Return Value;
	
EndFunction

// For procedures AddRoleRightsRestrictions, AddRoleRights,
// ReadObject, AddFieldsRestrictions, ReadRestrictionTemplate.
//
Procedure WriteMessage(Log, Title = "", LongDesc = "")
	
	If TypeOf(Log) <> Type("Structure") Then
		TextWriter = New TextWriter(Log, "UTF-8",, True);
	EndIf;
	
	If ValueIsFilled(Title)
	 Or ValueIsFilled(LongDesc) Then
		
		String = TrimAll(Title + Chars.LF + LongDesc) + Chars.LF;
		
		If TypeOf(Log) <> Type("Structure") Then
			TextWriter.WriteLine(String);
		Else
			Log.Text = Log.Text + Chars.LF + String;
		EndIf;
	EndIf;
	
	If TypeOf(Log) <> Type("Structure") Then
		TextWriter.Close();
	EndIf;
	
EndProcedure

// For procedure AddRoleRights.
Function AddLastPathSeparator(DirectoryPath)
	
	If IsBlankString(DirectoryPath) Then
		Return DirectoryPath;
	EndIf;
	
	CharToAdd = GetPathSeparator();
	
	If StrEndsWith(DirectoryPath, CharToAdd) Then
		Return DirectoryPath;
	Else 
		Return DirectoryPath + CharToAdd;
	EndIf;
	
EndFunction

Function RemoveRestrictingAccessBracketsAtRecordLevelUniversal(Val RestrictionText)
	
	RestrictionText = TrimAll(RestrictionText);
	
	If StrStartsWith(RestrictionText, "#If &RecordLevelAccessRestrictionIsUniversal") Then
		SearchText = "#Else";
		Position = StrFind(RestrictionText, SearchText);
		If Position > 0 Then
			RestrictionText = Mid(RestrictionText, Position + StrLen(SearchText));
			SearchText = "#EndIf";
			If StrEndsWith(RestrictionText, SearchText) Then
				RestrictionText = Left(RestrictionText, StrLen(RestrictionText) - StrLen(SearchText));
			EndIf;
		EndIf;
	EndIf;
	
	Return RestrictionText;
	
EndFunction

#Region ComparePreviousAndNewRLS

Function RestrictedAccessLists()
	RestrictedAccessLists = New Map;
	SSLSubsystemsIntegration.OnFillListsWithAccessRestriction(RestrictedAccessLists);
	AccessManagementOverridable.OnFillListsWithAccessRestriction(RestrictedAccessLists);
	Return RestrictedAccessLists;
EndFunction

Function AllRestrictionsInRoles(TableOfConstraints)
	
	For Each RestrictionDetails In TableOfConstraints Do
		RestrictionDetails.Restriction = ClearFromNonNativeChars(RestrictionDetails.Restriction);
	EndDo;
	
	TableOfConstraints.GroupBy("Table,Right,Restriction,Role");
	
	RestrictionsForUsers = TableOfConstraints.Copy();
	RestrictionsForUsers.Clear();
	RestrictionsForExternalUsers = RestrictionsForUsers.Copy();
	
	RolesAssignment = Users.RolesAssignment();
	
	For Each Restriction In TableOfConstraints Do
		ForExternalUsers = RolesAssignment.ForExternalUsersOnly.Find(Restriction.Role) <> Undefined;
		BothForUsersAndExternalUsers = RolesAssignment.BothForUsersAndExternalUsers.Find(Restriction.Role) <> Undefined;
		
		If ForExternalUsers Or BothForUsersAndExternalUsers Then
			FillPropertyValues(RestrictionsForExternalUsers.Add(), Restriction);
		EndIf;
		
		If Not ForExternalUsers Then
			FillPropertyValues(RestrictionsForUsers.Add(), Restriction);
		EndIf;
	EndDo;
	
	RestrictionsForUsers.GroupBy("Table,Right,Restriction,Role");
	RestrictionsForExternalUsers.GroupBy("Table,Right,Restriction,Role");
	
	AllRestrictions = RestrictionsForUsers;
	AllRestrictions.Columns.Add("Rights");
	AllRestrictions.Columns.Add("ForUsers", New TypeDescription("Boolean"));
	AllRestrictions.Columns.Add("ForExternalUsers", New TypeDescription("Boolean"));
	AllRestrictions.Columns.Add("Read", New TypeDescription("Boolean"));
	AllRestrictions.Columns.Add("Create", New TypeDescription("Boolean"));
	AllRestrictions.Columns.Add("Update", New TypeDescription("Boolean"));
	AllRestrictions.Columns.Add("Delete", New TypeDescription("Boolean"));
	AllRestrictions.FillValues(True, "ForUsers");
	
	For Each Restriction In RestrictionsForExternalUsers Do
		NewRow = AllRestrictions.Add();
		FillPropertyValues(NewRow, Restriction);
		NewRow.ForExternalUsers = True;
	EndDo;
	
	For Each Restriction In AllRestrictions Do
		If Restriction.Right = "Read" Then
			Restriction.Read = True;
		ElsIf Restriction.Right = "Update" Then
			Restriction.Update = True;
		ElsIf Restriction.Right = "Create" Then
			Restriction.Create = True;
		ElsIf Restriction.Right = "Delete" Then
			Restriction.Delete = True;
		EndIf;
	EndDo;
	
	AllRestrictions.GroupBy("Table,Restriction,Role", "Read,Update,Create,Delete,ForUsers,ForExternalUsers");
	AllRestrictions.Sort("Table,ForUsers Desc,ForExternalUsers Desc,Role,Read Desc,Update Desc,Create Desc,Delete Desc");
	
	Return AllRestrictions;
	
EndFunction

Procedure GroupRolesInRestrictionsTable(TableOfConstraints)
	
	Filters = TableOfConstraints.Copy();
	Filters.GroupBy("Restriction");
	
	For Each Filter In Filters Do
		FilterStructure1 = New Structure;
		For Each Column In Filters.Columns Do
			FilterStructure1.Insert(Column.Name, Filter[Column.Name]);
		EndDo;
		
		FoundRows = TableOfConstraints.FindRows(FilterStructure1);
		TempTable = TableOfConstraints.Copy(FoundRows);
		
		Roles = New Array;
		For Each Restriction In TempTable Do
			For Each Right In StrSplit("Read,Update,Create,Delete", ",", False) Do
				If Restriction[Right] Then
					Roles.Add(Restriction.Role + "." + Right);
				EndIf;
			EndDo;
		EndDo;
		
		RolesAsString = StrConcat(Roles, ", ");
		
		For Each TableRow In FoundRows Do
			TableRow.Role = RolesAsString;
		EndDo;
	EndDo;
	
	TableOfConstraints.GroupBy("Restriction,Role", "Read,Update,Create,Delete,ForUsers,ForExternalUsers");
	TableOfConstraints.Sort("ForUsers Desc,ForExternalUsers Desc,Read Desc,Update Desc,Create Desc,Delete Desc,Role");
	
EndProcedure

Function TableRestrictionsInRoles(Table, RestrictionsInRoles)
	
	FoundRows = RestrictionsInRoles.FindRows(New Structure("Table", Table));
	RestrictionsByTable = RestrictionsInRoles.Copy(FoundRows);
	
	GroupRolesInRestrictionsTable(RestrictionsByTable);
	
	Return RestrictionsByTable;
	
EndFunction

Function RestrictionsCollectionAsString(RestrictionsCollection, HasRestrictionsForUsersInModules, HasRestrictionsForExternalUsersInModules)
	
	Result = New Array;
	
	OutputRolesNamesForInternalUsers = HasDifferentRLSForOneRight(RestrictionsCollection, "ForUsers");
	OutputRolesNamesForExternalUsers = HasDifferentRLSForOneRight(RestrictionsCollection, "ForExternalUsers");
	
	For Each Restriction In RestrictionsCollection Do
		Rows = New Array;
		If Restriction.ForUsers Then
			If Restriction.ForExternalUsers Then
				Rows.Add(NStr("ru = 'Внутренние и внешние пользователи:';
									|en = 'Internal and external users:';"));
			Else
				Rows.Add(NStr("ru = 'Внутренние пользователи:';
									|en = 'Internal users:';"));
			EndIf
		Else
			If Restriction.ForExternalUsers Then
				Rows.Add(NStr("ru = 'Внешние пользователи:';
									|en = 'External users:';"));
			Else
				Rows.Add(NStr("ru = 'Ни для внутренних и ни для внешних пользователей:';
									|en = 'Neither for internal nor for external users:';"));
			EndIf
		EndIf;
		
		Rights = New Array;
		For Each Right In StrSplit("Read,Update,Create,Delete", ",", False) Do
			If Restriction[Right] Then
				Rights.Add(Right);
			EndIf;
		EndDo;
		
		If Restriction.ForUsers And OutputRolesNamesForInternalUsers
			Or Restriction.ForExternalUsers And OutputRolesNamesForExternalUsers Then
			For Each RoleRight In StrSplit(Restriction.Role, ", ", False) Do
				Rows.Add("Role." + RoleRight);
			EndDo;
		Else
			Rows.Add(StrConcat(Rights, ", "));
		EndIf;
		Rows.Add(Restriction.Restriction);
		
		Result.Add(StrConcat(Rows, Chars.LF));
	EndDo;
	
	If Not ValueIsFilled(Result) And HasRestrictionsForUsersInModules And HasRestrictionsForExternalUsersInModules Then
		Result.Add(NStr("ru = 'Внутренние и внешние пользователи:';
								|en = 'Internal and external users:';"));
		Result.Add(NStr("ru = '<не указан>';
								|en = '<not specified>';"));
	Else
		If Not HasRestrictionsForUsersInRoles(RestrictionsCollection) And HasRestrictionsForUsersInModules Then
			Rows.Insert(0, NStr("ru = 'Внутренние пользователи:';
									|en = 'Internal users:';"));
			Rows.Insert(1, NStr("ru = '<не указан>';
									|en = '<not specified>';"));
		EndIf;
		
		If Not HasRestrictionsForExternalUsersInRoles(RestrictionsCollection) And HasRestrictionsForExternalUsersInModules Then
			Rows.Add(NStr("ru = 'Внешние пользователи:';
								|en = 'External users:';"));
			Rows.Add(NStr("ru = '<не указан>';
								|en = '<not specified>';"));
		EndIf;
	EndIf;
	
	Return StrConcat(Result, Chars.LF + Chars.LF);
	
EndFunction

Function HasDifferentRLSForOneRight(RestrictionsCollection, Filter)
	
	For Each Right In StrSplit("Read,Update,Create,Delete", ",", False) Do
		Var_167_Filter = New Structure;
		Var_167_Filter.Insert(Filter, True);
		Var_167_Filter.Insert(Right, True);
		
		FoundRows = RestrictionsCollection.FindRows(Var_167_Filter);
		If FoundRows.Count() > 1 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function ClearFromNonNativeChars(SourceText)
	Result = "";
	
	For LineNumber = 1 To StrLineCount(SourceText) Do
		String = StrGetLine(SourceText, LineNumber);
		If Not StrStartsWith(TrimL(String), "//") Then
			Result = Result + String + Chars.LF;
		EndIf;
	EndDo;
	
	Result = StrReplace(Result, """Read""", """""");
	Result = StrReplace(Result, """Update""", """""");
	Result = StrReplace(Result, """Create""", """""");
	Result = StrReplace(Result, """Delete""", """""");
	
	Return TrimAll(Result);
EndFunction

Function RestrictionsInModules(Table, ListsWithRestriction)
	
	Restriction = New Structure;
	Restriction.Insert("Text", "");
	Restriction.Insert("TextForExternalUsers1", "");
	Restriction.Insert("ByOwnerWithoutSavingAccessKeys", Undefined);
	Restriction.Insert("ByOwnerWithoutSavingAccessKeysForExternalUsers", Undefined);
	Restriction.Insert("TextInManagerModule", False);
	Restriction.Insert("OnFillListsWithAccessRestriction", False);
	
	MetadataObject = Common.MetadataObjectByFullName(Table);
	TextInManagerModule = ListsWithRestriction.Get(MetadataObject);
	If TextInManagerModule = Undefined Then
		Return Restriction;
	EndIf;
	
	Restriction.OnFillListsWithAccessRestriction = True;
	Restriction.TextInManagerModule = TextInManagerModule;
	
	// ACC:280-off - No.499.3.4. It's acceptable to skip the exception handling as
	// an empty restriction text will be generated for comparison.
	// The exception will be handled when calling the procedure
	// "AccessManagementInternal.AccessRestrictionErrors" in the 1C-supplied report "SSLImplementationCheck".
	
	If TextInManagerModule Then
		Manager = Common.ObjectManagerByFullName(Table);
		Try
			Manager.OnFillAccessRestriction(Restriction);
		Except
			// Processing is not required.
		EndTry;
	Else
		Try
			AccessManagementOverridable.OnFillAccessRestriction(MetadataObject, Restriction);
		Except
			// Processing is not required.
		EndTry;
	EndIf;
	
	// ACC:280-on
	
	Return Restriction;
	
EndFunction

Function RestrictionTextsAsString(RestrictionsInModules, RestrictionsInRoles)
	
	HasRestrictionsForUsersInModules = ValueIsFilled(RestrictionsInModules.Text);
	HasRestrictionsForExternalUsersInModules = ValueIsFilled(RestrictionsInModules.TextForExternalUsers1);
	
	TextsInRoles = RestrictionsCollectionAsString(RestrictionsInRoles, HasRestrictionsForUsersInModules, HasRestrictionsForExternalUsersInModules);
	
	Rows = New Array;
	
	Rows.Add("RLS In offormat BSP 2.x");
	Rows.Add("");
	Rows.Add(TextsInRoles);
	Rows.Add("");
	Rows.Add("RLS In offormat BSP 3.x");
	Rows.Add("");
	
	Text = StrReplace(RestrictionsInModules.Text, Chars.LF, Chars.LF + "|");
	TextForExternalUsers1 = StrReplace(RestrictionsInModules.TextForExternalUsers1, Chars.LF, Chars.LF + "|");
	
	If Text = TextForExternalUsers1 Then
		If HasRestrictionsForUsersInRoles(RestrictionsInRoles) Then
			If HasRestrictionsForExternalUsersInRoles(RestrictionsInRoles) Then
				Rows.Add(NStr("ru = 'Внутренние и внешние пользователи:';
									|en = 'Internal and external users:';"));
			Else
				Rows.Add(NStr("ru = 'Внутренние пользователи:';
									|en = 'Internal users:';"));
			EndIf;
		Else
			Rows.Add(NStr("ru = 'Внешние пользователи:';
								|en = 'External users:';"));
		EndIf;
		
		If Not ValueIsFilled(Text) Then
			If RestrictionsInModules.OnFillListsWithAccessRestriction Then
				If RestrictionsInModules.TextInManagerModule Then
					Text = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = '<не указан в процедуре %1 модуля менеджера>';
							|en = '<Not specified in procedure ""%1"" of manager module>';"),
						"OnFillAccessRestriction");
				Else
					Text = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = '<не указан в %1>';
							|en = '<Not specified in %1>';"),
						"AccessManagementOverridable.OnFillAccessRestriction");
				EndIf;
			Else
				Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '<не подключен в %1>';
						|en = '<Not attached in %1>';"),
					"AccessManagementOverridable.OnFillListsWithAccessRestriction");
			EndIf;
		EndIf;
		Rows.Add(Text);
	Else
		If ValueIsFilled(Text) Then
			Rows.Add(NStr("ru = 'Внутренние пользователи:';
								|en = 'Internal users:';"));
			Rows.Add(Text);
		EndIf;
		If ValueIsFilled(TextForExternalUsers1) Then
			If ValueIsFilled(Text) Then
				Rows.Add("");
			EndIf;
			Rows.Add(NStr("ru = 'Внешние пользователи:';
								|en = 'External users:';"));
			Rows.Add(TextForExternalUsers1);
		EndIf;
	EndIf;
	
	Result = StrConcat(Rows, Chars.LF);
	
	Return Result;
	
EndFunction

Function HasRestrictionsForUsersInRoles(RestrictionsInRoles)
	Return RestrictionsInRoles.FindRows(New Structure("ForUsers", True)).Count() > 0;
EndFunction

Function HasRestrictionsForExternalUsersInRoles(RestrictionsInRoles)
	Return RestrictionsInRoles.FindRows(New Structure("ForExternalUsers", True)).Count() > 0;
EndFunction

Function ReadFile(FullModuleName)
	
	File = New File(FullModuleName);
	If Not File.Exists() Then
		Return Undefined;
	EndIf;
	
	TextReader = New TextReader(FullModuleName);
	ModuleText = TextReader.Read();
	TextReader.Close();
	
	Return ModuleText;
	
EndFunction

Function SendRestrictionsTexts(SendOptions)
	
	URIStructure = CommonClientServer.URIStructure(SendOptions.RLSControlServiceConnectionString);
	SecureConnection = ?(URIStructure.Schema = "https", CommonClientServer.NewSecureConnection(), Undefined);
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/x-www-form-urlencoded");
	
	HTTPRequest = New HTTPRequest(URIStructure.PathAtServer, Headers);
	HTTPRequest.SetBodyFromString(Common.ValueToJSON(SendOptions));
	
	HTTPResponse = Undefined;
	
	EventNameInEventLog = NStr("ru = 'Контроль изменения текстов RLS';
										|en = 'Control of RLS text change';", Common.DefaultLanguageCode());
	ErrorMessageTemplate = NStr("ru = 'Отправка текстов ограничений не выполнена по причине:';
									|en = 'Restriction texts are not sent due to:';") + Chars.LF + "%1";
	
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		Proxy = ModuleNetworkDownload.GetProxy(URIStructure.Schema);
	EndIf;
	
	Try
		Join = New HTTPConnection(URIStructure.Host, URIStructure.Port, URIStructure.Login,
			URIStructure.Password, Proxy, 600, SecureConnection);
			
		HTTPResponse = Join.Post(HTTPRequest);
	Except
		WriteLogEvent(EventNameInEventLog, EventLogLevel.Error, , ,
			StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageTemplate, ErrorProcessing.DetailErrorDescription(ErrorInfo())));
			
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorMessageTemplate, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If HTTPResponse.StatusCode <> 200 Then
		Explanation = HTTPResponse.GetBodyAsString();
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorMessageTemplate, NStr("ru = 'Код состояния:';
											|en = 'Status code:';")) + " " + HTTPResponse.StatusCode + ?(ValueIsFilled(Explanation), Chars.LF + Explanation, "");
		Raise ErrorText;
	EndIf;
	
	Return HTTPResponse.GetBodyAsString();
	
EndFunction

#EndRegion

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf