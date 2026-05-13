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
	
	// Title layout.
	If Not IsBlankString(Parameters.Title) Then
		Title = Parameters.Title;
		TitleWidth = 1.3 * StrLen(Title);
		If TitleWidth > 40 And TitleWidth < 80 Then
			Width = TitleWidth;
		ElsIf TitleWidth >= 80 Then
			Width = 80;
		EndIf;
	EndIf;
	
	// Text layout.
	MessageText = Parameters.MessageText;
	
	MinMarginWidth = 50;
	ApproximateMarginHeight = CountOfRows(Parameters.MessageText, MinMarginWidth);
	Items.MultilineMessageText.Width = MinMarginWidth;
	Items.MultilineMessageText.Height = Min(ApproximateMarginHeight, 10);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReplyYes(Command)
	
	CloseFormResponseReceived(DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure ReplyNo(Command)
	
	CloseFormResponseReceived(DialogReturnCode.No);
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Client.

&AtClient
Procedure CloseFormResponseReceived(Response)
	
	SelectionResult = New Structure;
	SelectionResult.Insert("NeverAskAgain", NeverAskAgain);
	SelectionResult.Insert("Value", Response);
	
	Close(SelectionResult);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server.

// Determines the approximate number of lines including wrapped ones.
&AtServerNoContext
Function CountOfRows(Text, CutoffByWidth, BringToFormItemSize = True)
	
	CountOfRows = StrLineCount(Text);
	HyphenationCount = 0;
	For LineNumber = 1 To CountOfRows Do
		String = StrGetLine(Text, LineNumber);
		HyphenationCount = HyphenationCount + Int(StrLen(String)/CutoffByWidth);
	EndDo;
	
	EstimatedLineCount = CountOfRows + HyphenationCount;
	
	If BringToFormItemSize Then
		ZoomRatio = 2 / 3; // Single-window interface can contain up to 3 lines of text.
		EstimatedLineCount = Int((EstimatedLineCount + 1) * ZoomRatio);
	EndIf;
	
	If EstimatedLineCount = 2 Then
		EstimatedLineCount = 3;
	EndIf;
	
	Return EstimatedLineCount;
	
EndFunction

#EndRegion
