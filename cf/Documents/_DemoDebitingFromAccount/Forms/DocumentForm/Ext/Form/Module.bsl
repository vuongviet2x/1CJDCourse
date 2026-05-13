
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
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	If Common.IsMobileClient() Then
		Items.Date.TitleLocation = FormItemTitleLocation.Top;
		Items.Number.TitleLocation = FormItemTitleLocation.Top;
		Items.Comment.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	
	SetCurrency();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure


#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BankAccountOnChange(Item)
	SetCurrency();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PaymentPurposeFillFromTemplate(Command)
	
	If Modified Or Object.Ref.IsEmpty() Then
		ShowQueryBox(New NotifyDescription("PaymentPurposeFillFromTemplateQuestion", ThisObject),
			NStr("ru = 'Для продолжения необходимо записать документ. Продолжить?';
				|en = 'To continue, the changes should be saved. Continue?';"),
			QuestionDialogMode.YesNo);
	Else
		PaymentPurposeFillFromTemplateFollowUp();
	EndIf;
	
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

#Region Private

&AtServer
Procedure SetCurrency()
	Currency = Common.ObjectAttributeValue(Object.BankAccount, "Currency");
EndProcedure

&AtClient
Procedure PaymentPurposeFillFromTemplateQuestion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes And Write() Then
		PaymentPurposeFillFromTemplateFollowUp();
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentPurposeFillFromTemplateFollowUp()
	
	MessageTemplatesClient.SelectTemplate(
		New NotifyDescription("PaymentPurposeFillFromTemplateCompletion", ThisObject),
		"Arbitrary",
		Object.Ref,
		TemplateOwner());
	
EndProcedure

&AtServerNoContext
Function TemplateOwner()
	Return Common.MetadataObjectID("Document._DemoDebitingFromAccount");
EndFunction

&AtClient
Procedure PaymentPurposeFillFromTemplateCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Object.PaymentPurposes = PurposeOfPaymentText(Result, Object.Ref, UUID);
	
EndProcedure

&AtServerNoContext
Function PurposeOfPaymentText(Template, SubjectOf, UUID)
	
	Result = MessageTemplates.GenerateMessage(Template, SubjectOf, UUID);
	
	Return Result.Text;
	
EndFunction

#EndRegion