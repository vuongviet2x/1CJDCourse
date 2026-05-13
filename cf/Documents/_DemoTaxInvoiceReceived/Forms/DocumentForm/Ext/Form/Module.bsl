///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	If Common.IsMobileClient() Then
		Items.Date.TitleLocation = FormItemTitleLocation.Top;
		Items.Number.TitleLocation = FormItemTitleLocation.Top;
		Items.Comment.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	
	// StandardSubsystems.AccountingAudit
	AccountingAudit.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccountingAudit
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	AccountingAudit.AfterWriteAtServer(CurrentObject);
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.AccountingAudit
&AtClient
Procedure Attachable_OpenIssuesReport(ItemOrCommand, Var_URL, StandardProcessing)
	AccountingAuditClient.OpenObjectIssuesReport(ThisObject, Object.Ref, StandardProcessing);
EndProcedure
// End StandardSubsystems.AccountingAudit

#EndRegion