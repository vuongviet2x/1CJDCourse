///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

//////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
//  
// 
// 
//
//  
// 
// 
// 
// 
// 
// 
// 
// 
// 
//
//   
//  
// 
// 
// 
// 
// 
//  
//  
// 
// 
// 
//
//  
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
//
//  
// 
// 
// 
// 
// 
// 
//
// 
//////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	// 
	TableOfTransitionsByScenario1();
	
	// 
	SetNavigationNumber(1);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	WarningText = NStr("ru = 'Закрыть помощник?';
								|en = 'Close wizard?';");
	CommonClient.ShowArbitraryFormClosingConfirmation(
		ThisObject, Cancel, Exit, WarningText, "ForceCloseForm");
	
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
	
	ForceCloseForm = True;
	
	Close();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// 

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
	
	// 
	ExecuteNavigationEventHandlers(IsMoveNext);
	
	// 
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("ru = 'Не определена страница для отображения.';
								|en = 'The page to display is not specified.';");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	Items.PanelMain.CurrentPage  = Items[NavigationRowCurrent.MainPageName];
	Items.NavigationPanel.CurrentPage = Items[NavigationRowCurrent.NavigationPageName];
	
	If Not IsBlankString(NavigationRowCurrent.DecorationPageName) Then
		
		Items.DecorationPanel.CurrentPage = Items[NavigationRowCurrent.DecorationPageName];
		
	EndIf;
	
	// 
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
	
	// 
	If IsMoveNext Then
		
		NavigationRows = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber - 1));
		
		If NavigationRows.Count() > 0 Then
			
			NavigationRow = NavigationRows[0];
			
			// 
			If Not IsBlankString(NavigationRow.OnNavigationToNextPageHandlerName)
				And Not NavigationRow.TimeConsumingOperation Then
				
				ProcedureName = "Attachable_[HandlerName](Cancel)";
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
			
			// 
			If Not IsBlankString(NavigationRow.OnSwitchToPreviousPageHandlerName)
				And Not NavigationRow.TimeConsumingOperation Then
				
				ProcedureName = "Attachable_[HandlerName](Cancel)";
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
	
	// 
	If Not IsBlankString(NavigationRowCurrent.OnOpenHandlerName) Then
		
		ProcedureName = "Attachable_[HandlerName](Cancel, SkipPage, IsMoveNext)";
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
	
	// 
	If Not IsBlankString(NavigationRowCurrent.TimeConsumingOperationHandlerName) Then
		
		ProcedureName = "Attachable_[HandlerName](Cancel, GoToNext)";
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

////////////////////////////////////////////////////////////////////////////////
// 

// The handler for going further (to the next page) when leaving the page of the assistant "Pageadwa".
//
// Parameters:
//   Cancel - Boolean -  the flag for refusing to perform the transition next;
//					if this flag is raised in the handler, the transition to the next page will not be performed.
//
&AtClient
Function Attachable_PageTwoOnGoNext(Cancel)
	
	If IUnderstandConditions Then
		CommonClient.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выполняется обработчик %1 страницы № 2';
				|en = 'The %1 handler of page 2 is running.';"), "OnTransitionNext"));
	Else
		CommonClient.MessageToUser(NStr("ru = 'Сначала ознакомьтесь с условиями.';
														|en = 'First read the conditions.';"),, "IUnderstandConditions");
		Cancel = True;
	EndIf;
	
	Return Undefined;
	
EndFunction

// The handler for going back (to the previous page) when leaving the page of the assistant "Pageadwa".
//
// Parameters:
//   Cancel - Boolean -  flag for refusing to perform a backward transition;
//					if this flag is raised in the handler, the transition to the previous page will not be performed.
//
&AtClient
Function Attachable_PageTwoOnGoBack(Cancel)
	
	CommonClient.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Выполняется обработчик %1 страницы № 2';
			|en = 'The %1 handler of page 2 is running.';"), "OnGoingBack"));
	
	Return Undefined;
	
EndFunction

// The handler is executed when the page of the assistant "Pageadwa" is opened.
//
// Parameters:
//
//  Cancel - Boolean -  the flag for refusing to open the page;
//			if this flag is raised in the handler, the transition to the page will not be performed,
//			the previous page of the assistant will remain open according to the direction of transition (forward or backward).
//
//  SkipPage - Boolean -  if you raise this flag, the page will be skipped
//			and the control will move to the next page of the assistant according to the direction of transition (forward or backward).
//
//  IsMoveNext (read only) - The Boolean flag determines the direction of the transition.
//			True - the transition is performed further; False - the transition is performed backwards.
//
&AtClient
Function Attachable_PageTwoOnOpen(Cancel, SkipPage, Val IsMoveNext)
	
	CommonClient.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Выполняется обработчик %1 страницы № 2';
			|en = 'The %1 handler of page 2 is running.';"), "OnOpen"));
	
	Return Undefined;
	
EndFunction

// The handler for going further (to the next page) when leaving the page of the "Waiting Page" assistant.
//
// Parameters:
//   Cancel - Boolean -  the flag for refusing to perform the transition next;
//					if this flag is raised in the handler, the transition to the next page will not be performed.
//
&AtClient
Function Attachable_WaitingPageTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	ExecuteLongActionAtServer();
	
	Return Undefined;
	
EndFunction

&AtServer
Procedure ExecuteLongActionAtServer()
	
	// 
	OperationStartDate = CurrentSessionDate();
	While CurrentSessionDate() - OperationStartDate < 5 Do
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// The procedure defines the transition table according to scenario #1.
//
&AtClient
Procedure TableOfTransitionsByScenario1()
	
	NavigationTable.Clear();
	
	Transition = NavigationTable.Add();
	Transition.NavigationNumber = 1;
	Transition.MainPageName     = "OnePage";
	Transition.NavigationPageName    = "NavigationStartPage";
	Transition.DecorationPageName    = "DecorationPageStart";
	
	Transition = NavigationTable.Add();
	Transition.NavigationNumber = 2;
	Transition.MainPageName     = "TwoPage";
	Transition.NavigationPageName    = "NavigationPageFollowUp";
	Transition.DecorationPageName    = "DecorationPageFollowUp";
	Transition.OnOpenHandlerName = "PageTwoOnOpen";
	Transition.OnNavigationToNextPageHandlerName = "PageTwoOnGoNext";
	Transition.OnSwitchToPreviousPageHandlerName = "PageTwoOnGoBack";
	
	Transition = NavigationTable.Add();
	Transition.NavigationNumber = 3;
	Transition.MainPageName     = "PageThree";
	Transition.NavigationPageName    = "NavigationPageFollowUp";
	Transition.DecorationPageName    = "DecorationPageFollowUp";
	
	Transition = NavigationTable.Add();
	Transition.NavigationNumber = 4;
	Transition.MainPageName     = "PageFour";
	Transition.NavigationPageName    = "NavigationPageFollowUp";
	Transition.DecorationPageName    = "DecorationPageFollowUp";
	
	Transition = NavigationTable.Add();
	Transition.NavigationNumber = 5;
	Transition.MainPageName     = "WaitingPage";
	Transition.NavigationPageName    = "NavigationWaitPage";
	Transition.DecorationPageName    = "DecorationPageFollowUp";
	Transition.TimeConsumingOperation      = True;
	Transition.TimeConsumingOperationHandlerName = "WaitingPageTimeConsumingOperationProcessing";
	
	Transition = NavigationTable.Add();
	Transition.NavigationNumber = 6;
	Transition.MainPageName     = "PageFive";
	Transition.NavigationPageName    = "NavigationEndPage";
	Transition.DecorationPageName    = "DecorationPageEnd";
	
EndProcedure

#EndRegion
