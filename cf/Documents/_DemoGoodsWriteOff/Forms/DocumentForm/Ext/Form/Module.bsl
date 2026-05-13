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
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	IsGoods = Not Common.EmptyClipboard("Goods");
	Items.GoodsInsertRows.Enabled = IsGoods;
	Items.GoodsInsertMenuRows.Enabled = IsGoods;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	If Common.IsMobileClient() Then
		Items.GoodsLineNumber.Visible = False;
		Items.NumberDateGroup.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.CompanyStorageLocation.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.EmployeeResponsibleComment.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
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
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "DataCopiedToClipboard" Then
		IsGoods = (Parameter.CopySource = "Goods");
		Items.GoodsInsertRows.Enabled = IsGoods;
		Items.GoodsInsertMenuRows.Enabled = IsGoods;
	EndIf;
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	Notify("Write__DemoGoodsWriteOff", New Structure, Object.Ref);
	
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

#EndRegion

#Region FormCommandsEventHandlers

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

&AtClient
Procedure CopyRows(Command)
	
	If Items.Goods.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CopyLinesOnServer();
	ShowUserNotification(NStr("ru = 'Копирование в буфер обмена';
										|en = 'Copy to clipboard';"), Window.GetURL(), 
		StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Скопировано товаров: %1';
																	|en = 'Copied goods: %1';"), Items.Goods.SelectedRows.Count()));
	Notify("DataCopiedToClipboard", New Structure("CopySource", "Goods"), Object.Ref);
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	Count = InsertRowsOnServer();
	If Count > 0 Then
		ShowUserNotification(NStr("ru = 'Вставка из буфера обмена';
											|en = 'Paste';"), Window.GetURL(), 
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Вставлено товаров: %1';
																		|en = 'Inserted goods: %1';"), Count));
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CopyLinesOnServer()
	
	Common.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows, "Goods");
	
EndProcedure

&AtServer
Function InsertRowsOnServer()
	
	DataFromClipboard = Common.RowsFromClipboard();
	If DataFromClipboard.Source <> "Goods" Then
		Return 0;
	EndIf;
		
	Table = DataFromClipboard.Data;
	For Each TableRow In Table Do
		FillPropertyValues(Object.Goods.Add(), TableRow);
	EndDo;
	Return Table.Count();
	
EndFunction

#EndRegion