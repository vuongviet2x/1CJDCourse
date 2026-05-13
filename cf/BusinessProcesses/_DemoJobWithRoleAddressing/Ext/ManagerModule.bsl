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

// StandardSubsystems.BusinessProcessesAndTasks

// Gets a structure with task performance form details.
// Runs when the task performance form opens.
//
// Parameters:
//   TaskRef  - TaskRef.PerformerTask - Task.
//   BusinessProcessRoutePoint - BusinessProcessRoutePointRef - Route point.
//
// Returns:
//   Structure   - a structure with description of the task execution form.
//                 Key FormName contains the form name that is passed to the OpenForm() context method. 
//                 Key FormOptions contains the form parameters. 
//
Function TaskExecutionForm(TaskRef, BusinessProcessRoutePoint) Export
	// The business process has no applied forms of direction execution.
	Return New Structure;

EndFunction

// Runs when a task is forwarded.
//
// Parameters:
//   TaskRef  - TaskRef.PerformerTask - Task.
//   NewTaskRef  - TaskRef.PerformerTask - Task for a new assignee.
//
Procedure OnForwardTask(TaskRef, NewTaskRef) Export

EndProcedure

// Runs when a task is started from a list form.
//
// Parameters:
//   TaskRef - TaskRef.PerformerTask - Task.
//   BusinessProcessRef - AnyRef - The reference to a business process.
//   BusinessProcessRoutePoint - AnyRef - Route point.
//
Procedure DefaultCompletionHandler(TaskRef, BusinessProcessRef, BusinessProcessRoutePoint) Export

EndProcedure

// Populates the MainTask attribute with fill data.
//
// Parameters:
//  BusinessProcessObject  - BusinessProcessObject - Business process.
//  FillingData     - Arbitrary        - Fill data to pass to the population handler.
//  StandardProcessing - Boolean              - If False, the standard filling processing is skipped.
//                                               
//
Procedure OnFillMainBusinessProcessTask(BusinessProcessObject, FillingData, StandardProcessing) Export

EndProcedure

// End StandardSubsystems.BusinessProcessesAndTasks

// StandardSubsystems.BatchEditObjects

// Returns object attributes that can be edited using the bulk attribute modification data processor.
// 
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export

	Result = New Array;
	Result.Add("Author");
	Result.Add("Performer");
	Result.Add("CheckExecution");
	Result.Add("Supervisor");
	Result.Add("TaskDueDate");
	Result.Add("VerificationDueDate");

	Return Result;

EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the ObjectsVersioning subsystem.
//
// Parameters:
//  Settings - Structure - Subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	// Topic:
	//   DocumentRef._DemoCustomerProformaInvoice,
	//   DocumentRef._DemoSalesOrder,
	//   CatalogRef.Files,
	//   CatalogRef.Users.

	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS _DemoJobWithRoleAddressing
	|
	|LEFT JOIN InformationRegister.TaskPerformers AS TaskPerformers
	|ON
	|	TaskPerformers.PerformerRole = _DemoJobWithRoleAddressing.PerformerRole
	|	AND TaskPerformers.MainAddressingObject = _DemoJobWithRoleAddressing.MainAddressingObject
	|	AND TaskPerformers.AdditionalAddressingObject = _DemoJobWithRoleAddressing.AdditionalAddressingObject
	|
	|LEFT JOIN InformationRegister.TaskPerformers AS TaskSupervisors
	|ON
	|	TaskSupervisors.PerformerRole = _DemoJobWithRoleAddressing.SupervisorRole
	|	AND TaskSupervisors.MainAddressingObject = _DemoJobWithRoleAddressing.MainAddressingObjectSupervisor
	|	AND TaskSupervisors.AdditionalAddressingObject = _DemoJobWithRoleAddressing.AdditionalAddressingObjectSupervisor
	|;
	|AllowRead
	|WHERE
	|	ValueAllowed(Author)
	|	OR ValueAllowed(Performer)
	|	OR ValueAllowed(Supervisor)
	|	OR (    ValueAllowed(TaskPerformers.Performer)
	|	     OR ValueAllowed(TaskSupervisors.Performer) )
	|	  AND (    ValueAllowed(SubjectOf ONLY Catalog.Users)
	|	     OR ObjectReadingAllowed(SubjectOf Not (Catalog.Users, Catalog.Files))
	|	     OR ObjectReadingAllowed(CAST(SubjectOf AS Catalog.Files).FileOwner Not BusinessProcess._DemoJobWithRoleAddressing))
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(Author)";

	Restriction.TextForExternalUsers1 =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Performer)
	|	OR ValueAllowed(Author)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.AttachableCommands

// Defines the list of generation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export

EndProcedure

// Intended for use by the AddGenerationCommands procedure in other object manager modules.
// Adds this object to the list of generation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - Details of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export

	Return GenerateFrom.AddGenerationCommand(GenerationCommands,
		Metadata.BusinessProcesses._DemoJobWithRoleAddressing);

EndFunction

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#EndIf