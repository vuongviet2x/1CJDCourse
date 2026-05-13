///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2018, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
// @strict-types

#Region Public

// Generates a list of the queue job templates.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  JobTemplates - Array of String - Add to the parameter names of predefined shared scheduled jobs
//   that will be used as queued job templates.
//   
//
Procedure OnGetTemplateList(JobTemplates) Export
EndProcedure

// Fills in a mapping of method names and their aliases to call from the job queue.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  NamesAndAliasesMap - Map of KeyAndValue:
//    * Key - String - a method alias, for example, ClearDataArea.
//    * Value - String - Name of the method to be called. For example, SaaS.ClearDataArea.
//        If Undefined, it is assumed that the name matches the alias. 
//        
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
EndProcedure

// Fills in a mapping of error handlers methods and method aliases upon
// errors where they are called.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  ErrorHandlers - Map of KeyAndValue:
//    * Key - String - Method alias. For example, ClearDataArea.
//    * Value - String - Name of an error handler. 
//        The error handler is called when a job fails.
//        The error handler is always called in the same data area as the failed job.
//        The error handler method can be called by the queue mechanisms.
//        Error handler parameters:
//          JobParameters - Structure - Job parameters
//          AttemptNumber
//          RestartCountOnFailure
//          LastRunStartDate.
//          
//
Procedure OnDefineErrorHandlers(ErrorHandlers) Export
EndProcedure

// Generates a table of scheduled jobs with a flag indicating that they are used in SaaS mode.
// @skip-warning EmptyMethod - Overridable method.
// 
// Parameters:
//  UsageTable - ValueTable - Details:
//	* ScheduledJob - String - a name of scheduled job.
//  * Use - Boolean - indicates usage.
//
Procedure OnDefineScheduledJobsUsage(UsageTable) Export
EndProcedure

#EndRegion
