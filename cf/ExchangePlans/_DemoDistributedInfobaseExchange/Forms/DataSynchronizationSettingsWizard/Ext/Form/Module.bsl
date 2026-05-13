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
	
	CheckCanUseForm(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	InitializeFormAttributes();
	
	InitializeFormProperties();
	
	SetInitialFormItemsView();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetNavigationNumber(1);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseFilterByCompaniesOnChange(Item)
	
	Items.Companies.Enabled = UseFilterByCompanies;
	
EndProcedure

&AtClient
Procedure UseFilterByDepartmentsOnChange(Item)
	
	Items.Departments.Enabled = UseFilterByDepartments;
	
EndProcedure

&AtClient
Procedure UseFilterByWarehousesOnChange(Item)
	
	Items.Warehouses.Enabled = UseFilterByWarehouses;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure NextCommand(Command)
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure BackCommand(Command)
	
	ChangeNavigationNumber(-1);
	
EndProcedure

&AtClient
Procedure DoneCommand(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

#Region NavigationEventHandlers

////////////////////////////////////////////////////////////////////////////////
// Overridable part - Navigation event handlers.

&AtClient
Function Attachable_WaitingPageTimeConsumingOperation(Cancel, GoToNext)
	
	GoToNext = False;
	
	OnStartSaveSetting();
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region SaveSynchronizationSetting

&AtClient
Procedure OnStartSaveSetting()
	
	ContinueWait = True;
	OnStartSaveSynchronizationSettingAtServer(ContinueWait);
	
	If ContinueWait Then
		InitIdleHandlerParameters(
			SettingsSavingIdleHandlerParameters);
			
		AttachIdleHandler("OnWaitForSaveSetting",
			SettingsSavingIdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteSaveSetting();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForSaveSetting()
	
	ContinueWait = False;
	OnWaitForSaveSettingAtServer(SettingsSavingHandlerParameters, ContinueWait);
	
	If ContinueWait Then
		UpdateIdleHandlerParameters(SettingsSavingIdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForSaveSetting",
			SettingsSavingIdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteSaveSetting();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteSaveSetting()
	
	SettingsSavingIdleHandlerParameters = Undefined;
	
	Cancel = False;
	ErrorMessage = "";
	OnCompleteSaveSettingAtServer(Cancel, ErrorMessage);
	
	If Cancel Then
		ChangeNavigationNumber(-1);
		CommonClient.MessageToUser(ErrorMessage);
	Else
		ChangeNavigationNumber(+1);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartSaveSynchronizationSettingAtServer(ContinueWait)
	
	SynchronizationSettings = New Structure;
	SynchronizationSettings.Insert("ExchangeNode",       ExchangeNode);
	SynchronizationSettings.Insert("FillingData", New Structure);
	
	SynchronizationSettings.FillingData.Insert("DocumentsExportStartDate",      DocumentsExportStartDate);
	SynchronizationSettings.FillingData.Insert("UseFilterByCompanies",   UseFilterByCompanies);
	SynchronizationSettings.FillingData.Insert("UseFilterByWarehouses",        UseFilterByWarehouses);
	SynchronizationSettings.FillingData.Insert("UseFilterByDepartments", UseFilterByDepartments);
	
	SynchronizationSettings.FillingData.Insert("Companies",   Companies.Unload());
	SynchronizationSettings.FillingData.Insert("Warehouses",        Warehouses.Unload());
	SynchronizationSettings.FillingData.Insert("Departments", Departments.Unload());
		
	SettingsSavingHandlerParameters = Undefined;
	DataExchangeServer.OnStartSaveSynchronizationSettings(
		SynchronizationSettings, SettingsSavingHandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnWaitForSaveSettingAtServer(HandlerParameters, ContinueWait)
	
	DataExchangeServer.OnWaitForSaveSynchronizationSettings(
		HandlerParameters, ContinueWait);
	
EndProcedure

&AtServer
Procedure OnCompleteSaveSettingAtServer(Cancel, ErrorMessage)
	
	CompletionStatus = Undefined;
	DataExchangeServer.OnCompleteSaveSynchronizationSettings(
		SettingsSavingHandlerParameters, CompletionStatus);
	SettingsSavingHandlerParameters = Undefined;
		
	If CompletionStatus.Cancel Then
		Cancel = True;
		ErrorMessage = CompletionStatus.ErrorMessage;
		Return;
	Else
		
		If Not CompletionStatus.Result.SettingsSaved Then
			Cancel = True;
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
			Return;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InitIdleHandlerParameters(IdleHandlerParameters)
	
	IdleHandlerParameters = New Structure;
	IdleHandlerParameters.Insert("MinInterval", 1);
	IdleHandlerParameters.Insert("MaxInterval", 15);
	IdleHandlerParameters.Insert("CurrentInterval", 1);
	IdleHandlerParameters.Insert("IntervalIncreaseCoefficient", 1.4);
	
EndProcedure

&AtClient
Procedure UpdateIdleHandlerParameters(IdleHandlerParameters)
	
	IdleHandlerParameters.CurrentInterval = Min(IdleHandlerParameters.MaxInterval,
		Round(IdleHandlerParameters.CurrentInterval * IdleHandlerParameters.IntervalIncreaseCoefficient, 1));
	
EndProcedure

#EndRegion


#Region FormInitializationOnCreate

&AtServer
Procedure CheckCanUseForm(Cancel = False)
	
	// Sync setup wizard parameters must be passed.
	If Not ValueIsFilled(Parameters.ExchangeNode) Then
		MessageText = NStr("ru = 'Форма не предназначена для непосредственного использования.';
								|en = 'The form cannot be opened manually.';");
		Common.MessageToUser(MessageText, , , , Cancel);
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeFormAttributes()
	
	ExchangeNode = Parameters.ExchangeNode;
	
	Query = New Query(
	"SELECT
	|	_DemoDistributedInfobaseExchange.DocumentsExportStartDate AS DocumentsExportStartDate,
	|	_DemoDistributedInfobaseExchange.UseFilterByCompanies AS UseFilterByCompanies,
	|	_DemoDistributedInfobaseExchange.UseFilterByWarehouses AS UseFilterByWarehouses,
	|	_DemoDistributedInfobaseExchange.UseFilterByDepartments AS UseFilterByDepartments,
	|	_DemoDistributedInfobaseExchange.Companies.(
	|		Organization AS Organization
	|	) AS Companies,
	|	_DemoDistributedInfobaseExchange.Warehouses.(
	|		SourceWarehouse AS SourceWarehouse,
	|		DestinationWarehouse AS DestinationWarehouse
	|	) AS Warehouses,
	|	_DemoDistributedInfobaseExchange.Departments.(
	|		Department AS Department
	|	) AS Departments
	|FROM
	|	ExchangePlan._DemoDistributedInfobaseExchange AS _DemoDistributedInfobaseExchange
	|WHERE
	|	_DemoDistributedInfobaseExchange.Ref = &Ref");
	Query.SetParameter("Ref", ExchangeNode);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(ThisObject, Selection,
			"DocumentsExportStartDate,
			|UseFilterByCompanies,
			|UseFilterByWarehouses,
			|UseFilterByDepartments");
		
		Companies.Load(Selection.Companies.Unload());
		Warehouses.Load(Selection.Warehouses.Unload());
		Departments.Load(Selection.Departments.Unload());
	EndIf;
	
	FillNavigationTable();
	
EndProcedure

&AtServer
Procedure InitializeFormProperties()
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Настройка синхронизации данных с ""%1""';
			|en = 'Setup of data synchronization with %1';"),
		ExchangeNode);
	
EndProcedure

&AtServer
Procedure SetInitialFormItemsView()
	
	Items.Companies.Enabled = UseFilterByCompanies;
	Items.Departments.Enabled = UseFilterByDepartments;
	Items.Warehouses.Enabled = UseFilterByWarehouses;
	
EndProcedure

#EndRegion

#Region WizardScenarios

&AtServer
Function AddNavigationTableRow(MainPageName, NavigationPageName, DecorationPageName = "")
	
	NavigationsString = NavigationTable.Add();
	NavigationsString.NavigationNumber = NavigationTable.Count();
	NavigationsString.MainPageName = MainPageName;
	NavigationsString.NavigationPageName = NavigationPageName;
	NavigationsString.DecorationPageName = DecorationPageName;
	
	Return NavigationsString;
	
EndFunction

&AtServer
Procedure FillNavigationTable()
	
	NavigationTable.Clear();
	
	NewNavigation = AddNavigationTableRow("FilterByDatePage", "PageNavigationStart");
	
	NewNavigation = AddNavigationTableRow("FilterByCompanyPage", "PageNavigationFollowUp");
	
	NewNavigation = AddNavigationTableRow("FilterByDepartmentPage", "PageNavigationFollowUp");
	
	NewNavigation = AddNavigationTableRow("FilterByWarehousePage", "PageNavigationFollowUp");
	
	NewNavigation = AddNavigationTableRow("PageWait", "PageNavigationFollowUp");
	NewNavigation.TimeConsumingOperation = True;
	NewNavigation.TimeConsumingOperationHandlerName = "Attachable_WaitingPageTimeConsumingOperation";
	
	NewNavigation = AddNavigationTableRow("PageCompletion", "PageNavigationEnd");
	
EndProcedure

#EndRegion

#Region AdditionalNavigationHandlers

////////////////////////////////////////////////////////////////////////////////
// Built-in part

&AtClient
Procedure ChangeNavigationNumber(Iterator_SSLy)
	
	ClearMessages();
	
	SetNavigationNumber(NavigationNumber + Iterator_SSLy);
	
EndProcedure

&AtClient
Procedure SetNavigationNumber(Val Value)
	
	IsMoveNext = (Value > NavigationNumber);
	
	NavigationNumber = Value;
	
	If NavigationNumber < 0 Then
		
		NavigationNumber = 0;
		
	EndIf;
	
	NavigationNumberOnChange(IsMoveNext);
	
EndProcedure

&AtClient
Procedure NavigationNumberOnChange(Val IsMoveNext)
	
	// Run navigation event handlers.
	ExecuteNavigationEventHandlers(IsMoveNext);
	
	// Set up page view.
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("ru = 'Не определена страница для отображения.';
								|en = 'The page to display is not specified.';");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	Items.PanelMain.CurrentPage  = Items[NavigationRowCurrent.MainPageName];
	Items.NavigationPanel.CurrentPage = Items[NavigationRowCurrent.NavigationPageName];
	
	Items.NavigationPanel.CurrentPage.Enabled = Not (IsMoveNext And NavigationRowCurrent.TimeConsumingOperation);
	
	// Set the default button.
	NextButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "NextCommand");
	
	If NextButton <> Undefined Then
		
		NextButton.DefaultButton = True;
		
	Else
		
		ConfirmButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "DoneCommand");
		
		If ConfirmButton <> Undefined Then
			
			ConfirmButton.DefaultButton = True;
			
		EndIf;
		
	EndIf;
	
	If IsMoveNext And NavigationRowCurrent.TimeConsumingOperation Then
		
		AttachIdleHandler("ExecuteTimeConsumingOperationHandler", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteNavigationEventHandlers(Val IsMoveNext)
	
	// Navigation event handlers.
	If IsMoveNext Then
		
		NavigationRows = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber - 1));
		
		If NavigationRows.Count() > 0 Then
			
			NavigationRow = NavigationRows[0];
			
			// OnNavigationToNextPage handler.
			If Not IsBlankString(NavigationRow.OnNavigationToNextPageHandlerName)
				And Not NavigationRow.TimeConsumingOperation Then
				
				ProcedureName = "[HandlerName](Cancel)";
				ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnNavigationToNextPageHandlerName);
				
				Cancel = False;
				
				Result = Eval(ProcedureName);
				
				If Cancel Then
					
					NavigationNumber = NavigationNumber - 1;
					Return;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	Else
		
		NavigationRows = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber + 1));
		
		If NavigationRows.Count() > 0 Then
			
			NavigationRow = NavigationRows[0];
			
			// OnNavigationToPreviousPage handler.
			If Not IsBlankString(NavigationRow.OnSwitchToPreviousPageHandlerName)
				And Not NavigationRow.TimeConsumingOperation Then
				
				ProcedureName = "[HandlerName](Cancel)";
				ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnSwitchToPreviousPageHandlerName);
				
				Cancel = False;
				
				Result = Eval(ProcedureName);
				
				If Cancel Then
					
					NavigationNumber = NavigationNumber + 1;
					Return;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("ru = 'Не определена страница для отображения.';
								|en = 'The page to display is not specified.';");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	If NavigationRowCurrent.TimeConsumingOperation And Not IsMoveNext Then
		
		SetNavigationNumber(NavigationNumber - 1);
		Return;
	EndIf;
	
	// OnOpen handler.
	If Not IsBlankString(NavigationRowCurrent.OnOpenHandlerName) Then
		
		ProcedureName = "[HandlerName](Cancel, SkipPage, IsMoveNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.OnOpenHandlerName);
		
		Cancel = False;
		SkipPage = False;
		
		Result = Eval(ProcedureName);
		
		If Cancel Then
			
			NavigationNumber = NavigationNumber - 1;
			Return;
			
		ElsIf SkipPage Then
			
			If IsMoveNext Then
				
				SetNavigationNumber(NavigationNumber + 1);
				Return;
				
			Else
				
				SetNavigationNumber(NavigationNumber - 1);
				Return;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTimeConsumingOperationHandler()
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("ru = 'Не определена страница для отображения.';
								|en = 'The page to display is not specified.';");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	// TimeConsumingOperationProcessing handler.
	If Not IsBlankString(NavigationRowCurrent.TimeConsumingOperationHandlerName) Then
		
		ProcedureName = "[HandlerName](Cancel, GoToNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.TimeConsumingOperationHandlerName);
		
		Cancel = False;
		GoToNext = True;
		
		Result = Eval(ProcedureName);
		
		If Cancel Then
			
			NavigationNumber = NavigationNumber - 1;
			Return;
			
		ElsIf GoToNext Then
			
			SetNavigationNumber(NavigationNumber + 1);
			Return;
			
		EndIf;
		
	Else
		
		SetNavigationNumber(NavigationNumber + 1);
		Return;
		
	EndIf;
	
EndProcedure

&AtClient
Function GetFormButtonByCommandName(FormItem, CommandName)
	
	For Each Item In FormItem.ChildItems Do
		
		If TypeOf(Item) = Type("FormGroup") Then
			
			FormItemByCommandName = GetFormButtonByCommandName(Item, CommandName);
			
			If FormItemByCommandName <> Undefined Then
				
				Return FormItemByCommandName;
				
			EndIf;
			
		ElsIf TypeOf(Item) = Type("FormButton")
			And StrFind(Item.CommandName, CommandName) > 0 Then
			
			Return Item;
			
		Else
			
			Continue;
			
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion