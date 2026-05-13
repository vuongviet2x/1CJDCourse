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
	
	Text = Parameters.QueryText;
	QueryText.SetText(GenerateQueryTextForDesigner(Text));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function GenerateQueryTextForDesigner(Text)
	
	Result = """";
	Text = Parameters.QueryText;
	Linefeed = Chars.CR+Chars.LF;
	For Counter = 1 To StrLineCount(Text) Do
		CurRow = StrGetLine(Text, Counter);
		If Counter > 1 Then 
			CurRow = StrReplace(CurRow,"""","""""");
			Result = Result + Linefeed + "|"+ CurRow;
		Else
			CurRow = StrReplace(CurRow,"""","""""");
			Result = Result + CurRow;
		EndIf;
	EndDo;
	Result = Result + """";
	Return Result;
	
EndFunction

#EndRegion
