///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InfobaseFolderStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	ChoiceDialog.Directory = InfobaseFolder;
	
	Context = New Structure("ChoiceDialog", ChoiceDialog);
	
	Notification = New NotifyDescription("InfobaseFolderStartChoiceCompletion", ThisObject, Context);
	FileSystemClient.ShowSelectionDialog(Notification, ChoiceDialog);
	
EndProcedure

&AtClient
Procedure InfobaseFolderStartChoiceCompletion(SelectedFiles, Context) Export
	
	ChoiceDialog = Context.ChoiceDialog;
	
	If (SelectedFiles <> Undefined) Then
		InfobaseFolder = ChoiceDialog.Directory;
	EndIf;
	
EndProcedure

&AtClient
Procedure AuthenticationTypeOnChange(Item)
	Items.GroupAuthentication.Enabled = (AuthenticationType = 0);
EndProcedure

&AtClient
Procedure InfobaseTypeOnChange(Item)
	
	If InfobaseType = 0 Then
		Items.InfobaseTypeGroup.CurrentPage = Items.FileInfobaseGroup;
	Else
		Items.InfobaseTypeGroup.CurrentPage = Items.ServerInfobaseGroup;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TestConnection(Command)
	
	If CommonClient.FileInfobase() Then
		Notification = New NotifyDescription("TestConnectionAfterCheckCOMConnector", ThisObject);
		CommonClient.RegisterCOMConnector(False, Notification);
	Else 
		TestConnectionAfterCheckCOMConnector(True, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure TestConnectionAfterCheckCOMConnector(IsRegistered, Context) Export
	
	SettingsStructure_ = COMConnectionParameters();
	
	MessageText = COMConnectionErrorsAtServer(SettingsStructure_);
	If IsBlankString(MessageText) Then
		// No errors. Notify about success.
		MessageText = NStr("ru = 'Проверка подключения успешно завершена.';
								|en = 'Connection test succeeded.';");
	EndIf;
	
	ClearMessages();
	ShowMessageBox(, MessageText);
	
EndProcedure

&AtClient
Procedure MoveTo_(Command)
	
	MoveUsers();
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Function UsersToTransfer(Val Source, Result = Undefined)
	
	If Result = Undefined Then
		Result = New Map;
	EndIf;
	
	For Each String In Source.GetItems() Do
		If String.Check = 0 Then
			Continue;
		EndIf;
		
		// Current row.
		Group = Result[String.UsersGroup];
		If Group = Undefined Then
			Group = New Map;
			Result[String.UsersGroup] = Group;
		EndIf;
		
		If ValueIsFilled(String.User) Then
			Group[String.User] = True;
		EndIf;
		
		// Subordinate rows.
		UsersToTransfer(String, Result); 
	EndDo;
	
	Return Result;
EndFunction

&AtClient
Procedure UserMarkChange(Val RowsCollection, Val RawData)
	
	For Each String In RowsCollection Do
		
		If String <> RawData And String.User = RawData.User Then
			String.Check = RawData.Check;
			SetMarksDown(String);
			SetMarksUp(String);
		EndIf;
		
		UserMarkChange(String.GetItems(), RawData);
	EndDo;
	
EndProcedure

&AtClient
Procedure SetMarksDown(Val RowData)
	Value = RowData.Check;
	For Each Child In RowData.GetItems() Do
		Child.Check = Value;
		SetMarksDown(Child);
	EndDo;
EndProcedure

&AtClient
Procedure SetMarksUp(Val RowData)
	
	RowParent = RowData.GetParent();
	If RowParent <> Undefined Then
		AllTrue = True;
		NotAllFalse = False;
		For Each Child In RowParent.GetItems() Do
			AllTrue = AllTrue And (Child.Check = 1);
			NotAllFalse = NotAllFalse Or Boolean(Child.Check);
		EndDo;
		If AllTrue Then
			RowParent.Check = 1;
		ElsIf NotAllFalse Then
			RowParent.Check = 2;
		Else
			RowParent.Check = 0;
		EndIf;
		SetMarksUp(RowParent);
	EndIf;
	
EndProcedure

&AtClient
Function COMConnectionParameters()
	
	Result = CommonClientServer.ParametersStructureForExternalConnection();
	
	Result.InfobaseOperatingMode = InfobaseType;
	Result.InfobaseDirectory       = InfobaseFolder;
	
	Result.NameOf1CEnterpriseServer                     = InfobaseServer;
	Result.NameOfInfobaseOn1CEnterpriseServer = BaseName;
	Result.OperatingSystemAuthentication           = ?(AuthenticationType = 1, True, False);
	
	Result.UserName    = User;
	Result.UserPassword = Password;
	
	Return Result;
EndFunction

&AtServerNoContext
Function COMConnectionErrorsAtServer(Val SettingsStructure_)
	
	Result = DataExchangeServer.ExternalConnectionToInfobase(SettingsStructure_);
	If Result.Join = Undefined Then
		Return Result.BriefErrorDetails;
	EndIf;
	
	Return "";
EndFunction

// Start migration after the security parameter check is completed successfully.
&AtClient
Procedure MoveUsers()
	
	If CommonClient.FileInfobase() Then
		Notification = New NotifyDescription("MoveUsersAfterCOMConnectorCheck", ThisObject);
		CommonClient.RegisterCOMConnector(False, Notification);
	Else 
		MoveUsersAfterCOMConnectorCheck(True, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure MoveUsersAfterCOMConnectorCheck(IsRegistered, Context) Export
	
	If IsRegistered Then 
		
		TimeConsumingOperation = StartDataUploadOnServer(UUID, COMConnectionParameters());
		
		CallbackOnCompletion = New NotifyDescription("TransferUserInfoCompletion", ThisObject);
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow       = True;
		IdleParameters.OutputMessages          = True;
		IdleParameters.OutputProgressBar = False;
		
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure RowsLevelCorrection(Val TreeRowsCollection, Val ParentValue)
	
	Position = TreeRowsCollection.Count() - 1;
	While Position >= 0 Do
		TreeRow = TreeRowsCollection[Position];
		Position = Position - 1;
		
		ChildLines = TreeRow.Rows;
		CurrentGroup  = TreeRow.UsersGroup;
		
		RowsLevelCorrection(ChildLines, CurrentGroup);
		
		IsGroupRow = TreeRow.User = NULL;
		If CurrentGroup = ParentValue And IsGroupRow Then
			For Each String In ChildLines Do
				FillPropertyValues(TreeRowsCollection.Add(), String);
			EndDo;
			TreeRowsCollection.Delete(TreeRow);
			
		Else
			If IsGroupRow Then
				TreeRow.IconIndex = 1;
			EndIf;
			
		EndIf;
		
	EndDo;

EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure TransferUserInfoCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;
	
	MessageText = GetFromTempStorage(Result.ResultAddress);
	If ValueIsFilled(MessageText) Then
		ShowMessageBox(, MessageText);
	EndIf;
	
EndProcedure

&AtServer
Function StartDataUploadOnServer(Val FormIdentifier, Val ConnectionParameters)
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ConnectionParameters", ConnectionParameters);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormIdentifier);
	ExecutionParameters.BackgroundJobDescription =
		NStr("ru = 'Перенос сведений о пользователях в другое приложение';
			|en = 'Transfer user information to another application';");
	ExecutionParameters.RefinementErrors =
		NStr("ru = 'Не удалось выполнить перенос сведений о пользователях по причине:';
			|en = 'Cannot transfer user information records. Reason:';");
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors._DemoUserInformationTransferToAnotherApplication.TransferUserInfo", 
		ProcedureParameters, 
		ExecutionParameters);
	
EndFunction

#EndRegion
