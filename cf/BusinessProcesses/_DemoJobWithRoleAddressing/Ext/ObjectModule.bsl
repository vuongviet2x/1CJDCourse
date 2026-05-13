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

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.AccessManagement

// Parameters:
//   Table - See AccessManagement.AccessValuesSetsTable
//
Procedure FillAccessValuesSets(Table) Export
	
	// The restriction logic for
	// - "Read": Author OR Performer OR Supervisor OR (SubjectOf AND <assignee or supervisor from addressing>).
	// - "Update": Author.
	//
	// "SubjectOf" (topic) is ignored if the business process has no basis.
	// 
	
	// Read, Update: Set #1.
	String = Table.Add();
	String.SetNumber     = 1;
	String.Read          = True;
	String.Update       = True;
	String.AccessValue = Author;
	
	// Read: Set #2.
	String = Table.Add();
	String.SetNumber     = 2;
	String.Read          = True;
	String.AccessValue = Performer;
	
	// Read: Set #3.
	String = Table.Add();
	String.SetNumber     = 3;
	String.Read          = True;
	String.AccessValue = Supervisor;

	ModuleAccessManagement = Common.CommonModule("AccessManagement");
	If TypeOf(SubjectOf) = Type("CatalogRef.Users") Then
		String = Table.Add();
		String.SetNumber     = 4;
		String.Read          = True;
		String.AccessValue = TaskPerformersGroup;

		String = Table.Add();
		String.SetNumber     = 5;
		String.Read          = True;
		String.AccessValue = TaskPerformersGroupSupervisor;

		String = Table.Add();
		String.SetNumber     = 6;
		String.AccessValue = SubjectOf;

	ElsIf ValueIsFilled(SubjectOf) And ModuleAccessManagement.CanFillAccessValuesSets(SubjectOf) Then

		PerformerAccessGroupSets = AccessManagement.AccessValuesSetsTable();
		String = PerformerAccessGroupSets.Add();
		String.SetNumber     = 1;
		String.Read          = True;
		String.AccessValue = TaskPerformersGroup;

		String = PerformerAccessGroupSets.Add();
		String.SetNumber     = 2;
		String.Read          = True;
		String.AccessValue = TaskPerformersGroupSupervisor;

		SubjectSets = AccessManagement.AccessValuesSetsTable();
		AccessManagement.FillAccessValuesSets(SubjectOf, SubjectSets, Ref);
		SubjectSets = SubjectSets.Copy(SubjectSets.FindRows(New Structure("Read", True)));
		
		// Multiply subject sets by assignee access group sets.
		AccessManagement.AddAccessValuesSets(SubjectSets, PerformerAccessGroupSets, True);
		
		// Append the result to the table of sets.
		AccessManagement.AddAccessValuesSets(Table, SubjectSets);

	Else // Regardless of the subject.
		String = Table.Add();
		String.SetNumber     = 4;
		String.Read          = True;
		String.AccessValue = TaskPerformersGroup;

		String = Table.Add();
		String.SetNumber     = 5;
		String.Read          = True;
		String.AccessValue = TaskPerformersGroupSupervisor;
	EndIf;

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;

	BusinessProcessesAndTasksServer.ValidateRightsToChangeBusinessProcessState(ThisObject);

	SetPrivilegedMode(True);
	TaskPerformersGroup = BusinessProcessesAndTasksServer.TaskPerformersGroup(
		PerformerRole, MainAddressingObject, AdditionalAddressingObject);
	TaskPerformersGroupSupervisor = BusinessProcessesAndTasksServer.TaskPerformersGroup(
		SupervisorRole, MainAddressingObjectSupervisor, AdditionalAddressingObjectSupervisor);
	SetPrivilegedMode(False);

EndProcedure

// End StandardSubsystems.AccessManagement

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	NotCheckedAttributeArray = New Array;
	If AddressingAttributesAreFilled() Then
		NotCheckedAttributeArray.Add("Performer");
	EndIf;
	If Not CheckExecution Or Not SupervisorRole.IsEmpty() Then
		NotCheckedAttributeArray.Add("Supervisor");
	EndIf;
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
		// When adding a duty, external users can assign it only to a business role.
	If Users.IsExternalUserSession() And InvalidPerformerForExternalUser() Then
		Cancel = True;
	EndIf;

EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)

	If IsNew() Then
		Author = Users.AuthorizedUser();
		TaskDueDate = CurrentSessionDate();
		State = Enums.BusinessProcessStates.Running;
		If TypeOf(FillingData) = Type("CatalogRef.Users") Then
			Performer = FillingData;
		EndIf;
	EndIf;

	If FillingData <> Undefined And TypeOf(FillingData) <> Type("Structure") 
		And FillingData <> Tasks.PerformerTask.EmptyRef() Then
		SubjectOf = FillingData;
	EndIf;

	If TypeOf(FillingData) = Type("DocumentRef._DemoCustomerProformaInvoice") Then
		If Not Users.IsExternalUserSession() 
			And AccessRight("Read", Metadata.Catalogs.ExternalUsers) Then
			FillingProcessingForExternalUser(FillingData);
		EndIf;
		Supervisor = Users.AuthorizedUser();
	EndIf;

	BusinessProcessesAndTasksServer.FillMainTask(ThisObject, FillingData);

EndProcedure

Procedure OnCopy(CopiedObject)

	CompletedOn = '00010101000000';
	State = Enums.BusinessProcessStates.Running;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Handlers of flowchart item events.

// Handler of the BeforeTasksCreation event. 
// 
// Parameters:
//  BusinessProcessRoutePoint - BusinessProcessRoutePointRef._DemoJobWithRoleAddressing - The business process route point
//      that hosts the new tasks.
//  TasksBeingFormed - Array of TaskObject.PerformerTask - An array of new tasks.
//  Cancel - Boolean - Flag indicating whether the task addition has been canceled.
//                   If True, tasks will not be written.
// 
Procedure ExecuteWhenCreatingTasks(BusinessProcessRoutePoint, TasksBeingFormed, Cancel)

	If Not AddressingAttributesAreFilled() Then

		Cancel = True;
		Return;

	EndIf;
	
	// Sets addressing attributes and additional attributes for each task.
	For Each Task In TasksBeingFormed Do

		Task.Author = Author;
		Task.Performer = ?(ValueIsFilled(Performer), Performer, Undefined);
		Task.PerformerRole = ?(ValueIsFilled(PerformerRole), PerformerRole, Undefined);
		Task.MainAddressingObject = MainAddressingObject;
		Task.AdditionalAddressingObject = AdditionalAddressingObject;
		Task.Description = Description;
		Task.TaskDueDate = TaskDueDate;
		Task.SubjectOf = SubjectOf;
		Task.LongDesc = LongDesc;

	EndDo;

EndProcedure

Procedure AssignmentToTheExecutorWhenExecuting(BusinessProcessRoutePoint, Task, Cancel)

	If Common.ObjectAttributeValue(Task, "CompletionDate") > CurrentSessionDate() Then
		Common.MessageToUser(
			NStr("ru = 'Фактическая дата выполнения задачи не может быть больше текущей даты.';
				|en = 'The date when the duty is completed cannot be later than today.';"), Task,
			"Object.CompletionDate");
		Cancel = True;
		Return;
	EndIf;

EndProcedure

Procedure CheckTheFulfillmentOfTheConditionCheck(BusinessProcessRoutePoint, Result)
	Result = CheckExecution;
EndProcedure

// Handler of the OnCreateNestedBusinessProcesses event
// 
// Parameters:
//  BusinessProcessRoutePoint - BusinessProcessRoutePointRef._DemoJobWithRoleAddressing - The business process route point
// 	                                                              that hosts the nested business processes.
//  BusinessProcessesBeingFormed - Array of BusinessProcessObject._DemoJobWithRoleAddressing - An array of business processes being created.
//  Cancel - Boolean - Flag indicating whether nested business processes shell not be written and started.
//                   If True, nested business processes will not be written and started.
// 
Procedure CheckWhenCreatingNestedBusinessProcesses(BusinessProcessRoutePoint, BusinessProcessesBeingFormed, Cancel)

	For Each CheckBusinessProcess In BusinessProcessesBeingFormed Do
		CheckBusinessProcess.Performer = Supervisor;
		CheckBusinessProcess.PerformerRole = SupervisorRole;
		CheckBusinessProcess.MainAddressingObject = MainAddressingObjectSupervisor;
		CheckBusinessProcess.AdditionalAddressingObject = AdditionalAddressingObjectSupervisor;
		CheckBusinessProcess.Description = NStr("ru = 'Проверить:';
													|en = 'Revise:';") + " " + Description;
		CheckBusinessProcess.Author = Author;
		CheckBusinessProcess.TaskDueDate = VerificationDueDate;
		CheckBusinessProcess.SubjectOf = SubjectOf;
		CheckBusinessProcess.Write();
	EndDo;

EndProcedure

Procedure CompletionAtCompletion(BusinessProcessRoutePoint, Cancel)

	CompletedOn = BusinessProcessesAndTasksServer.BusinessProcessCompletionDate(Ref);
	Write();

EndProcedure

#EndRegion

#Region Private

Procedure FillingProcessingForExternalUser(Val CustomerProformaInvoice)
	
	Query = New Query(
		"SELECT ALLOWED
		|	ExternalUsers.Ref AS Ref
		|FROM
		|	Catalog.ExternalUsers AS ExternalUsers
		|WHERE
		|	ExternalUsers.AuthorizationObject = &AuthorizationObject");

	Query.SetParameter("AuthorizationObject", Common.ObjectAttributeValue(CustomerProformaInvoice, "Partner"));
	QueryResult = Query.Execute().Select();

	If QueryResult.Next() Then
		Performer = QueryResult.Ref;
	EndIf;

EndProcedure

Function AddressingAttributesAreFilled()

	Return ValueIsFilled(Performer) Or Not PerformerRole.IsEmpty();

EndFunction

Function InvalidPerformerForExternalUser()

	If TypeOf(PerformerRole) = TypeOf(Catalogs.PerformerRoles.EmptyRef()) 
		And Not ValueIsFilled(Performer) Then
		
		AuthorizationObject = ExternalUsers.GetExternalUserAuthorizationObject();
		AuthorizationObjectEmptyRef = Catalogs[AuthorizationObject.Metadata().Name].EmptyRef();

		Query = New Query;
		Query.Text = "SELECT TOP 1
		|	ExecutorRolesAssignment.Ref
		|FROM
		|	Catalog.PerformerRoles.Purpose AS ExecutorRolesAssignment
		|WHERE
		|	ExecutorRolesAssignment.UsersType = &UsersType
		|	AND ExecutorRolesAssignment.Ref = &Ref";

		Query.SetParameter("Ref", PerformerRole);
		Query.SetParameter("UsersType", AuthorizationObjectEmptyRef);

		Return Query.Execute().IsEmpty();
	EndIf;

	Return True;
EndFunction

#EndRegion

#Else
	Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
							|en = 'Invalid object call on the client.';");
#EndIf