///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Variables

&AtClient
Var ChoiceContext;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();

	SetPrivilegedMode(True);
	AuthorAsString = String(Object.Author);
	SetPrivilegedMode(False);
	
	// For new objects, run the form initializer in "OnCreateAtServer".
	// For existing objects, in "OnReadAtServer".
	If Object.Ref.IsEmpty() Then
		InitializeTheForm();
	EndIf;
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	InitializeTheForm();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If Upper(ChoiceSource.FormName) = Upper("CommonForm.SelectPerformerRole") Then

		If TypeOf(ValueSelected) = Type("Structure") Then
			If ChoiceContext = "RoleClick" Then
				SetRole(ValueSelected);
			ElsIf ChoiceContext = "SupervisorRoleClick" Then
				SetSupervisorRole(ValueSelected);
			EndIf;
		EndIf;

	EndIf;

EndProcedure

&AtClient
Procedure PerformerTypeOnChange(Item)
	SetRole(Undefined);
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)

	If TypeOf(PerformerType) = Type("CatalogRef.Users") Then
		Object.Performer = PerformerByAssignment;
		Object.PerformerRole = Undefined;
	ElsIf TypeOf(PerformerType) <> Type("CatalogRef.PerformerRoles") Then
		Object.Performer = ExternalUserByAuthorizationObject(PerformerByAssignment);
		Object.PerformerRole = Undefined;
	EndIf;

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	If TypeOf(PerformerType) <> Type("CatalogRef.Users") Then
		SetPerformerByFormData();
	EndIf;
	
	// On each step, checks if required data is present (not only at start).
	If InitialStartFlag And CurrentObject.Started 
		Or (Not InitialStartFlag And Not CurrentObject.Started) Then

		If Not CurrentObject.CheckFilling() Then
			Cancel = True;
		EndIf;

	EndIf;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MainTaskClick(Item, StandardProcessing)

	ShowValue(, Object.MainTask);
	StandardProcessing = False;

EndProcedure

&AtClient
Procedure RoleClick(Item, StandardProcessing)

	StandardProcessing = False;

	ChoiceContext = "RoleClick";

	FormParameters = BusinessProcessesAndTasksClient.PerformerRoleChoiceFormParameters(Object.PerformerRole,
		Object.MainAddressingObject, Object.AdditionalAddressingObject);
	
	BusinessProcessesAndTasksClient.OpenPerformerRoleChoiceForm(FormParameters, ThisObject);

EndProcedure

&AtClient
Procedure SubjectOfClick(Item, StandardProcessing)

	ShowValue(, Object.SubjectOf);
	StandardProcessing = False;

EndProcedure

&AtClient
Procedure SupervisorRoleClick(Item, StandardProcessing)

	StandardProcessing = False;

	ChoiceContext = "SupervisorRoleClick";

	FormParameters = BusinessProcessesAndTasksClient.PerformerRoleChoiceFormParameters(Object.SupervisorRole,
		Object.MainAddressingObject, Object.AdditionalAddressingObject);
	
	BusinessProcessesAndTasksClient.OpenPerformerRoleChoiceForm(FormParameters, ThisObject);

EndProcedure

&AtClient
Procedure SupervisorOnChange(Item)

	If Object.CheckExecution And ValueIsFilled(SupervisorByAssignment) Then
		If TypeOf(SupervisorType) = Type("CatalogRef.PerformerRoles") Then
			Object.SupervisorRole = SupervisorByAssignment;
			Object.Supervisor = Undefined;
		Else
			Object.Supervisor = SupervisorByAssignment;
			Object.SupervisorRole = Undefined;
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure CheckExecutionOnChange(Item)
	SetItemsState();
EndProcedure

&AtClient
Procedure SupervisorStartChoice(Item, ChoiceData, StandardProcessing)

	If TypeOf(SupervisorType) = Type("CatalogRef.PerformerRoles") Then
		If Not UsersClient.IsExternalUserSession() Then
			StandardProcessing = False;
			ChoiceContext = "SupervisorRoleClick";
			
			FormParameters = BusinessProcessesAndTasksClient.PerformerRoleChoiceFormParameters(Object.SupervisorRole,
				Object.MainAddressingObject, Object.AdditionalAddressingObject);
	
			BusinessProcessesAndTasksClient.OpenPerformerRoleChoiceForm(FormParameters, ThisObject);
			
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure PerformerOpening(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure PerformerStartChoice(Item, ChoiceData, StandardProcessing)

	If TypeOf(PerformerType) = Type("CatalogRef.PerformerRoles") Then
		If Not UsersClient.IsExternalUserSession() Then
			StandardProcessing = False;
			ChoiceContext = "RoleClick";
			
			FormParameters = BusinessProcessesAndTasksClient.PerformerRoleChoiceFormParameters(Object.PerformerRole,
				Object.MainAddressingObject, Object.AdditionalAddressingObject);
	
			BusinessProcessesAndTasksClient.OpenPerformerRoleChoiceForm(FormParameters, ThisObject);
			
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure PerformerOnChange(Item)

	If UsersClient.IsExternalUserSession() Then
		Object.PerformerRole = PerformerByAssignment;
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)

	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;

	Write();
	Close();

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Performer.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AddressingType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Performer");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Role.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AddressingType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PerformerRole");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Supervisor.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SupervisorAddressingType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Supervisor");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupervisorRole.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SupervisorAddressingType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupervisorRole");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

EndProcedure

&AtServer
Procedure InitializeTheForm()

	UseDateAndTimeInTaskDeadlines = GetFunctionalOption("UseDateAndTimeInTaskDeadlines");
	Items.Date.Format = ?(UseDateAndTimeInTaskDeadlines, "DLF=DT", "DLF=D");

	Items.StateGroup.Visible = Object.Completed Or Object.Started;
	If Object.Completed Then
		EndDateAsString = ?(UseDateAndTimeInTaskDeadlines, Format(Object.CompletedOn, "DLF=DT"), Format(
			Object.CompletedOn, "DLF=D"));
		Items.TextDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"ru = 'Задание выполнено %1.';
			|en = 'The duty is completed on %1.';"), EndDateAsString);

		For Each Item In Items Do
			If TypeOf(Item) <> Type("FormField") And TypeOf(Item) <> Type("FormGroup") Then
				Continue;
			EndIf;
			Item.ReadOnly = True;
		EndDo;
	Else
		StateText = ?(GetFunctionalOption("ChangeJobsBackdated"), NStr("ru = 'Изменения формулировки, важности, автора, а также перенос сроков исполнения и проверки задания 
																							|вступят в силу немедленно для ранее выданной задачи.';
																							|en = 'Changes to the wording, priority, author, deadlines, and revision
																							|will take into effect immediately for the previous task.';"),
			NStr("ru = 'Изменения формулировки, важности, автора, а также перенос сроков исполнения и проверки задания 
				 |не будут отражены в ранее выданной задаче.';
				|en = 'Changes to the wording, priority, author, deadlines, and revision
				|will not apply to the previous task.';"));
		Items.TextDecoration.Title = StateText;

	EndIf;

	Items.FormStartAndClose.Visible = Not Object.Started;
	Items.FormStartAndClose.DefaultButton = Not Object.Started;
	Items.FormStart.Visible = Not Object.Started;
	Items.FormWriteAndClose.Visible = Object.Started;
	Items.FormWriteAndClose.DefaultButton = Object.Started;

	Items.SubjectOf.Hyperlink = Object.SubjectOf <> Undefined And Not Object.SubjectOf.IsEmpty();
	SubjectString = Common.SubjectString(Object.SubjectOf);
	InitialStartFlag = Object.Started;
	SetItemsState();

	If Object.MainTask = Undefined Or Object.MainTask.IsEmpty() Then
		Items.MainTask.Hyperlink = False;
		MainTaskString = NStr("ru = 'не задана';
									|en = 'not specified';");
	Else
		MainTaskString = String(Object.MainTask);
	EndIf;

	If Not GetFunctionalOption("UseSubordinateBusinessProcesses") Then
		Items.MainTask.Visible = False;
	EndIf;

	Items.PerformerType.ChoiceList.Clear();
	Items.SupervisorType.ChoiceList.Clear();
	Items.PerformerType.ChoiceList.Add(Catalogs.PerformerRoles.EmptyRef(), 
		NStr("ru = 'Роль исполнителя';
			|en = 'Business role';"));
	Items.SupervisorType.ChoiceList.Add(Catalogs.PerformerRoles.EmptyRef(), 
		NStr("ru = 'Роль исполнителя';
			|en = 'Business role';"));

	If Users.IsExternalUserSession() Then
		DetermineFormDisplayForExternalUser();
	Else
		DetermineFormDisplayForUser();
	EndIf;

EndProcedure

&AtServer
Procedure DetermineFormDisplayForUser()

	Items.PerformerType.ChoiceList.Add(Catalogs.Users.EmptyRef(), NStr("ru = 'Пользователь';
																								|en = 'User';"));
	Items.SupervisorType.ChoiceList.Add(Catalogs.Users.EmptyRef(), NStr("ru = 'Пользователь';
																								|en = 'User';"));

	If AccessRight("Read", Metadata.Catalogs.ExternalUsers) Then
		For Each ExternalPerformerType In Metadata.DefinedTypes.ExternalUser.Type.Types() Do
			If Not Common.IsReference(ExternalPerformerType) Then
				Continue;
			EndIf;
			ObjectMetadata = Metadata.FindByType(ExternalPerformerType);
			Presentation = Common.ObjectPresentation(ObjectMetadata);
			Value = Catalogs[ObjectMetadata.Name].EmptyRef();
			Items.PerformerType.ChoiceList.Add(Value, Presentation);
		EndDo;
	EndIf;

	If ValueIsFilled(Object.SubjectOf) Then
		ObjectMetadata = Object.SubjectOf.Metadata();
		If ObjectMetadata.Attributes.Find("EmployeeResponsible") <> Undefined Then
			ResponsibleForSubject = Common.ObjectAttributeValue(Object.SubjectOf, "EmployeeResponsible");  
			If Common.IsReference(TypeOf(ResponsibleForSubject)) Then
				SupervisorType = Items.PerformerType.ChoiceList.FindByValue(
					Catalogs[ResponsibleForSubject.Metadata().Name].EmptyRef()).Value;
			EndIf;
		EndIf;
	EndIf;

	If ValueIsFilled(Object.Performer) Then
		If TypeOf(Object.Performer) = Type("CatalogRef.ExternalUsers") Then
			PerformerByAssignment = Common.ObjectAttributeValue(Object.Performer, "AuthorizationObject");	
			PerformerType = Items.PerformerType.ChoiceList.FindByValue(
				Catalogs[PerformerByAssignment.Metadata().Name].EmptyRef()).Value;
		ElsIf TypeOf(Object.Performer) = Type("CatalogRef.Users") Then
			PerformerType = Items.PerformerType.ChoiceList.FindByValue(
				Catalogs.Users.EmptyRef()).Value;
			PerformerByAssignment = Object.Performer;
		EndIf;
	Else
		PerformerType = Items.PerformerType.ChoiceList.FindByValue(
			Catalogs.PerformerRoles.EmptyRef()).Value;
		PerformerByAssignment = Object.PerformerRole;
	EndIf;

	If ValueIsFilled(Object.Supervisor) Then
		SupervisorType = Items.SupervisorType.ChoiceList.FindByValue(
			Catalogs.Users.EmptyRef()).Value;
		SupervisorByAssignment = Object.Supervisor;
	Else
		SupervisorType = Items.SupervisorType.ChoiceList.FindByValue(
			Catalogs.PerformerRoles.EmptyRef()).Value;
		SupervisorByAssignment = Object.SupervisorRole;
	EndIf;

EndProcedure

&AtServer
Procedure DetermineFormDisplayForExternalUser()

	If Object.Ref.IsEmpty() Then
		PerformerType = Catalogs.PerformerRoles.EmptyRef();
		AuthorizationObject = Common.ObjectAttributeValue(ExternalUsers.CurrentExternalUser(), "AuthorizationObject");
		AuthorizationObjectEmptyRef = Catalogs[AuthorizationObject.Metadata().Name].EmptyRef();
		Object.Performer = Catalogs.PerformerRoles.EmptyRef();

		RoleTable = RoleTable(AuthorizationObjectEmptyRef);

		Items.Performer.TypeLink = New TypeLink;
		PerformerByAssignment = Catalogs.PerformerRoles.EmptyRef();

		If RoleTable.Count() = 1 Then
			PerformerByAssignment = RoleTable.Get(0).Ref;
			Object.PerformerRole = PerformerByAssignment;
		EndIf;
	Else
		If ValueIsFilled(Object.PerformerRole) Then
			PerformerType = Object.PerformerRole;
			PerformerByAssignment = Object.PerformerRole;
		Else
			PerformerString = String(Object.Performer);
			Items.PerformerString.Visible = True;
			Items.Performer.Visible = False;
			Items.Performer.ReadOnly = True;
		EndIf;
	EndIf;

	Items.Author.Visible = False;
	Items.AuthorAsString.Visible = True;
	Items.CheckCompletionGroup.Visible = False;
	Items.PerformerType.Visible = False;
	Items.Performer.TitleLocation = FormItemTitleLocation.Auto;

EndProcedure

// For internal use.
//
// Parameters:
//   UsersType - CatalogRef - User type.
// 
// Returns:
//   ValueTable - a collection of roles for the specified user type:
//     * Ref - CatalogRef.PerformerRoles - Role reference.
//
&AtServerNoContext
Function RoleTable(UsersType)

	Query = New Query("SELECT ALLOWED
						  |	ExecutorRolesAssignment.Ref AS Ref
						  |FROM
						  |	Catalog.PerformerRoles.Purpose AS ExecutorRolesAssignment
						  |WHERE
						  |	ExecutorRolesAssignment.UsersType = &UsersType");
	Query.SetParameter("UsersType", UsersType);

	Return Query.Execute().Unload();

EndFunction

&AtServer
Procedure SetItemsState()
	RoleString = RoleString(Object.MainAddressingObject, Object.AdditionalAddressingObject);
	Items.Role.Visible = ?(ValueIsFilled(RoleString), True, False);

	SupervisorRoleString = RoleString(Object.MainAddressingObjectSupervisor,
		Object.AdditionalAddressingObjectSupervisor);
	Items.SupervisorRole.Visible = ?(ValueIsFilled(SupervisorRoleString), True, False);

	Items.CheckingGroup.Enabled = Object.CheckExecution;

EndProcedure

&AtServer
Function RoleString(MainAddressingObject, AdditionalAddressingObject)
	Result = "";
	If MainAddressingObject <> Undefined Then
		Result = NStr("ru = 'Объект адресации';
						|en = 'Business object';") + ": " + String(MainAddressingObject);
		If AdditionalAddressingObject <> Undefined Then
			Result = Result + " ," + String(AdditionalAddressingObject);
		EndIf;
	EndIf;
	Return Result;
EndFunction

&AtServer
Procedure SetPerformerByFormData()

	If ValueIsFilled(PerformerByAssignment) Then
		If TypeOf(PerformerType) = Type("CatalogRef.PerformerRoles") Then
			If Users.IsExternalUserSession() Then
				Object.Performer = Catalogs.Users.EmptyRef();
				Object.PerformerRole = PerformerByAssignment;
			EndIf;
			SetItemsState();
		Else
			Object.Performer = ExternalUserByAuthorizationObject(PerformerByAssignment);
			Object.PerformerRole = Undefined;
		EndIf;
	EndIf;

EndProcedure

&AtServerNoContext
Function ExternalUserByAuthorizationObject(PerformerByAssignment)

	Query = New Query;
	Query.Text =
	"SELECT
	|	ExternalUsers.Ref
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.AuthorizationObject = &PerformerByAssignment";

	Query.SetParameter("PerformerByAssignment", PerformerByAssignment);

	QueryResult = Query.Execute();

	SelectionDetailRecords = QueryResult.Select();

	If SelectionDetailRecords.Next() Then
		Return SelectionDetailRecords.Ref;
	EndIf;

	Return Catalogs.ExternalUsers.EmptyRef();

EndFunction

&AtServer
Procedure SetSupervisorRole(Val InfoAboutRole)
	Object.Supervisor = Catalogs.Users.EmptyRef();
	Object.SupervisorRole = InfoAboutRole.PerformerRole;
	SupervisorByAssignment = InfoAboutRole.PerformerRole;
	Object.MainAddressingObjectSupervisor = InfoAboutRole.MainAddressingObject;
	Object.AdditionalAddressingObjectSupervisor = InfoAboutRole.AdditionalAddressingObject;
	SetItemsState();
EndProcedure

&AtServer
Procedure SetRole(Val InfoAboutRole)
	Object.Performer = Catalogs.Users.EmptyRef();

	If ValueIsFilled(InfoAboutRole) Then
		Object.PerformerRole = InfoAboutRole.PerformerRole;
		PerformerByAssignment = InfoAboutRole.PerformerRole;
		Object.MainAddressingObject = InfoAboutRole.MainAddressingObject;
		Object.AdditionalAddressingObject = InfoAboutRole.AdditionalAddressingObject;
	Else
		Object.PerformerRole = Undefined;
		PerformerByAssignment = Undefined;
		Object.MainAddressingObject = Undefined;
		Object.AdditionalAddressingObject = Undefined;
	EndIf;
	SetItemsState();
	SetPerformerByFormData();
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion