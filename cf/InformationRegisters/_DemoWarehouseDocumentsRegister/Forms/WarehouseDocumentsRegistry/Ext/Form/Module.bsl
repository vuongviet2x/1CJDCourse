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
	
	TypesIDs = New Array;
	TypesIDs.Add(Common.MetadataObjectID("Document._DemoReceivedGoodsRecording"));
	TypesIDs.Add(Common.MetadataObjectID("Document._DemoInventoryTransfer"));
	TypesIDs.Add(Common.MetadataObjectID("Document._DemoGoodsWriteOff"));
	
	TypesMetadata = New Array;
	TypesMetadata.Add(Metadata.Documents._DemoReceivedGoodsRecording);
	TypesMetadata.Add(Metadata.Documents._DemoInventoryTransfer);
	TypesMetadata.Add(Metadata.Documents._DemoGoodsWriteOff);
	
	RightsByIDs = AccessManagement.RightsByIDs(TypesIDs);
	
	Update = False;
	FilterDocumentTypes = New Array;
	For Each Id In TypesIDs Do
		Rights = RightsByIDs.Get(Id);
		If Not Rights.Read Then
			Continue;
		EndIf;
		FilterDocumentTypes.Add(Id);
		If Rights.Update Then
			Update = True;
		EndIf;
		If Rights.Create Then
			MetadataObject = TypesMetadata[TypesIDs.Find(Id)];
			Command = Commands.Add(NameOfCreateCommand() + MetadataObject.Name);
			Command.Action = "Attachable_Create";
			Command.Title = MetadataObject.Presentation();
			Button = Items.Add(NameOfCreateCommand() + MetadataObject.Name, Type("FormButton"), Items.Create);
			Button.CommandName = Command.Name;
			Button = Items.Add("ListContextMenuCreate" + MetadataObject.Name, Type("FormButton"),
				Items.ListContextMenuCreate);
			Button.CommandName = Command.Name;
		EndIf;
	EndDo;
	
	If Not Update Then
		ReadOnly = False;
		
		Items.Copy.Visible = False;
		Items.ListContextMenuCopy.Visible = False;
		
		Items.MarkToDelete.Visible = False;
		Items.ListContextMenuMarkToDelete.Visible = False;
		
		Items.Post.Visible = False;
		Items.ListContextMenuPost.Visible = False;
		
		Items.CancelPosting.Visible = False;
		Items.ListContextMenuCancelPosting.Visible = False;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"RefType",
		FilterDocumentTypes,
		DataCompositionComparisonType.InList,
		,
		True);
	
	If Not Common.SubsystemExists("StandardSubsystems.BatchEditObjects")
	 Or Not AccessRight("Edit", Metadata.InformationRegisters._DemoWarehouseDocumentsRegister) Then
		
		Items.FormChangeSelectedItems.Visible = False;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.FormCommands;
	PlacementParameters.Sources = Metadata.InformationRegisters._DemoWarehouseDocumentsRegister.Dimensions.Ref.Type;
	PlacementParameters.CommandsOwner = Items.List;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.CommandBarSalesList;
	PlacementParameters.Sources = New TypeDescription("DocumentRef._DemoGoodsSales");
	PlacementParameters.GroupsPrefix = "SalesList";
	PlacementParameters.CommandsOwner = Items.SalesList;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	If Common.IsMobileClient() Then
		
		Items.Comment.Visible = False;
		Items.EmployeeResponsible.Visible = False;
		Items.SalesListComment.Visible = False;
		Items.SalesListEmployeeResponsible.Visible = False;
		Items.Create.Representation = ButtonRepresentation.Picture;
		MobileDeviceCommandBarContent.Add(Items.CommandBar);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write__DemoReceivedGoodsRecording"
	 Or EventName = "Write__DemoInventoryTransfer"
	 Or EventName = "Write__DemoGoodsWriteOff" Then
	
		AttachIdleHandler("UpdateList", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
#If MobileClient Then
		ChangeCommandBarCompositionOnMobileDevice();
#EndIf
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenCurrentDocument();
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	RowAvailable = Item.CurrentData <> Undefined;
	
	Items.Copy.Enabled = RowAvailable;
	Items.ListContextMenuCopy.Enabled = RowAvailable;
	
	Items.MarkToDelete.Enabled = RowAvailable;
	Items.ListContextMenuMarkToDelete.Enabled = RowAvailable;
	
	Items.Post.Enabled = RowAvailable;
	Items.ListContextMenuPost.Enabled = RowAvailable;
	
	Items.CancelPosting.Enabled = RowAvailable;
	Items.ListContextMenuCancelPosting.Enabled = RowAvailable;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	OpenCurrentDocument();
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	AttachIdleHandler("MarkForDeletionUncheck", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers


// Parameters:
//   Command - FormCommand
//
&AtClient
Procedure Attachable_Create(Command)
	
	NameOfDocumentForm = "Document." + Mid(Command.Name, StrLen(NameOfCreateCommand() +1)) + ".ObjectForm";
	
	OpenForm(NameOfDocumentForm, , Items.List);
	
EndProcedure

&AtClient
Procedure Copy(Command)
	
	If Items.List.CurrentData = Undefined Then
		Return;
	EndIf;
	
	Document = Items.List.CurrentData.Ref;
	NameOfDocumentForm = NameOfDocumentForm(Document);
	
	FormParameters = New Structure;
	FormParameters.Insert("CopyingValue", Document);
	
	OpenForm(NameOfDocumentForm, FormParameters, Items.List);
	
EndProcedure

&AtClient
Procedure MarkToDelete(Command)
	
	MarkForDeletionUncheck();
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure SetPeriod(Command)
	
	Dialog = New StandardPeriodEditDialog();
	Dialog.Period = PeriodSet;
	Dialog.Show(New NotifyDescription("SetPeriodCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure Post(Command)
	
	SetPostings(True);
	
EndProcedure

&AtClient
Procedure CancelPosting(Command)
	
	SetPostings(False);
	
EndProcedure

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
EndProcedure

&AtClient
Procedure UpdateList()
	
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure OpenCurrentDocument()
	
	If Items.List.CurrentData = Undefined Then
		Return;
	EndIf;
	
	Document = Items.List.CurrentData.Ref;
	NameOfDocumentForm = NameOfDocumentForm(Document);
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", Document);
	
	OpenForm(NameOfDocumentForm, FormParameters, Items.List);
	
EndProcedure

&AtClient
Procedure MarkForDeletionUncheck()
	
	If Items.List.CurrentData = Undefined Then
		Return;
	EndIf;
	CurrentData = Items.List.CurrentData;
	
	If CurrentData.DeletionMark Then
		QuestionTemplate = NStr("ru = 'Снять с ""%1"" пометку на удаление?';
							|en = 'Do you want to clear a deletion mark for ""%1""?';");
	Else
		QuestionTemplate = NStr("ru = 'Пометить ""%1"" на удаление?';
							|en = 'Do you want to mark %1 for deletion?';");
	EndIf;
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(QuestionTemplate, String(CurrentData.Ref));
	
	Context = New Structure;
	Context.Insert("Ref",          CurrentData.Ref);
	Context.Insert("DeletionMark", CurrentData.DeletionMark);
	
	ShowQueryBox(New NotifyDescription("MarkForDeletionUncheckCompletion", ThisObject, Context),
		QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure MarkForDeletionUncheckCompletion(Response, Context) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	MarkForDeletionClearMarkAtServer(Context.Ref);
	
	NotificationText1 = ?(Context.DeletionMark,
		NStr("ru = 'Пометка удаления снята';
			|en = 'Deletion mark cleared';"),
		NStr("ru = 'Пометка удаления установлена';
			|en = 'Deletion mark set';"));
	
	
	NotifyChanged(Context.Ref);
	
	ShowUserNotification(NotificationText1,
		GetURL(Context.Ref), String(Context.Ref), PictureLib.DialogInformation);
	
EndProcedure

&AtServer
Procedure MarkForDeletionClearMarkAtServer(Ref)
	
	LockDataForEdit(Ref);
	DocumentObject = Ref.GetObject();
	
	DocumentObject.DeletionMark = Not DocumentObject.DeletionMark;
	
	If DocumentObject.Posted Then
		DocumentObject.Write(DocumentWriteMode.UndoPosting);
	Else
		DocumentObject.Write(DocumentWriteMode.Write);
	EndIf;
	
	Items.List.Refresh();
	
EndProcedure

// End of SetPeriod procedure.
&AtClient
Procedure SetPeriodCompletion(Period, Context) Export
	
	If Period = Undefined Then
		Return;
	EndIf;
	PeriodSet = Period;
	
	List.Parameters.SetParameterValue("BeginOfPeriod", PeriodSet.StartDate);
	List.Parameters.SetParameterValue("EndOfPeriod",
		?(ValueIsFilled(PeriodSet.EndDate),
			EndOfDay(PeriodSet.EndDate),
			PeriodSet.EndDate));
	
EndProcedure

&AtClient
Function NameOfDocumentForm(Ref)
	
	If TypeOf(Ref) = Type("DocumentRef._DemoReceivedGoodsRecording") Then
		NameOfDocumentForm = "Document._DemoReceivedGoodsRecording.ObjectForm"
		
	ElsIf TypeOf(Ref) = Type("DocumentRef._DemoInventoryTransfer") Then
		NameOfDocumentForm = "Document._DemoInventoryTransfer.ObjectForm"
	
	ElsIf TypeOf(Ref) = Type("DocumentRef._DemoGoodsWriteOff") Then
		NameOfDocumentForm = "Document._DemoGoodsWriteOff.ObjectForm"
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неизвестный тип документа %1';
				|en = 'Unknown document type %1';"), TypeOf(Ref));
	EndIf;
	
	Return NameOfDocumentForm;
	
EndFunction

&AtClient
Procedure SetPostings(Post)
	
	If Items.List.CurrentData = Undefined Then
		Return;
	EndIf;
	CurrentData = Items.List.CurrentData;
	
	SetPostingsAtServer(CurrentData.Ref, Post);
	
	NotifyChanged(CurrentData.Ref);
	
	ShowUserNotification(NStr("ru = 'Изменение';
										|en = 'Update';"),
		GetURL(CurrentData.Ref), String(CurrentData.Ref), PictureLib.DialogInformation);
		
EndProcedure

&AtServer
Procedure SetPostingsAtServer(Ref, Post)
	
	LockDataForEdit(Ref);
	DocumentObject = Ref.GetObject(); // DocumentObject
	
	If Post Then
		DocumentObject.Write(DocumentWriteMode.Posting);
	Else
		DocumentObject.Write(DocumentWriteMode.UndoPosting);
	EndIf;
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure ChangeCommandBarCompositionOnMobileDevice()
	
	ItemsToRemove = New Array;
	For Each CommandBarItem In MobileDeviceCommandBarContent Do
		ItemsToRemove.Add(CommandBarItem);
	EndDo;
	For Each ItemToRemove In ItemsToRemove Do
		MobileDeviceCommandBarContent.Delete(ItemToRemove);
	EndDo;
	
	CommandBarItem = ?(Items.Pages.CurrentPage = Items.WarehouseDocumentsPage,
		Items.CommandBar, Items.CommandBarSalesList);
		
	MobileDeviceCommandBarContent.Add(CommandBarItem);
	
EndProcedure

&AtClientAtServerNoContext
Function NameOfCreateCommand()
	Return "Create";
EndFunction

#EndRegion
