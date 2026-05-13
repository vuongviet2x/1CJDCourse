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
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// StandardSubsystems.AccountingAudit
	AccountingAudit.OnCreateListFormAtServer(ThisObject, "List");
	// End StandardSubsystems.AccountingAudit
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	// StandardSubsystems.AccountingAudit
	AccountingAudit.OnGetDataAtServer(Settings, Rows);
	// End StandardSubsystems.AccountingAudit
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.AccountingAudit
&AtClient
Procedure Attachable_Selection(Item, RowSelected, Field, StandardProcessing)
	AccountingAuditClient.OpenListedIssuesReport(ThisObject, "List", Field, StandardProcessing);
EndProcedure
// End StandardSubsystems.AccountingAudit

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
EndProcedure

#EndRegion

