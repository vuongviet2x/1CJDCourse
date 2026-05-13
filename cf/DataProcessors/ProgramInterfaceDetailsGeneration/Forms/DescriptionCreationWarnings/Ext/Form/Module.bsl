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
	
	WarningsTree = FormAttributeToValue("Warnings");
	// Included in the API by mistake.
	If Parameters.DetailsGenerationLog.InvalidProgramming.Count() > 0 Then
		LongDesc = NStr("ru = 'Ошибочно включены в программный интерфейс';
						|en = 'Included in the API by mistake';");
		String = WarningsTree.Rows.Add();
		String.IssueKind = LongDesc;
		AddWarningsTree(Parameters.DetailsGenerationLog.InvalidProgramming, String.Rows);
	EndIf;
	
	// Long comment.
	If Parameters.DetailsGenerationLog.LongComment.Count() > 0 Then
		LongDesc = NStr("ru = 'Длинный комментарий';
						|en = 'Long comment';");
		String = WarningsTree.Rows.Add();
		String.IssueKind = LongDesc;
		AddWarningsTree(Parameters.DetailsGenerationLog.LongComment, String.Rows);
	EndIf;
	
	// Enclose the hyperlink in quotes.
	If Parameters.DetailsGenerationLog.HyperlinkInQuotes.Count() > 0 Then
		LongDesc = NStr("ru = 'Гиперссылка выводится в кавычках';
						|en = 'Enclose the hyperlink in quotes';");
		String = WarningsTree.Rows.Add();
		String.IssueKind = LongDesc;
		AddWarningsTree(Parameters.DetailsGenerationLog.HyperlinkInQuotes, String.Rows);
	EndIf;
	
	// Cannot add a hyperlink.
	If Parameters.DetailsGenerationLog.HyperlinkNotFound.Count() > 0 Then
		LongDesc = NStr("ru = 'Не удалось добавить гиперссылку';
						|en = 'Cannot add a hyperlink';");
		String = WarningsTree.Rows.Add();
		String.IssueKind = LongDesc;
		AddWarningsTree(Parameters.DetailsGenerationLog.HyperlinkNotFound, String.Rows, True);
	EndIf;
	
	// Obsolete methods outside of the ObsoleteProceduresAndFunctions area.
	If Parameters.DetailsGenerationLog.ObsoleteMethods.Count() > 0 Then
		LongDesc = NStr("ru = 'Устаревшие методы вне области %1';
						|en = 'Obsolete methods are outside area %1';");
		LongDesc = StringFunctionsClientServer.SubstituteParametersToString(LongDesc, "ObsoleteProceduresAndFunctions");
		String = WarningsTree.Rows.Add();
		String.IssueKind = LongDesc;
		AddWarningsTree(Parameters.DetailsGenerationLog.ObsoleteMethods, String.Rows);
	EndIf;
	
	ValueToFormAttribute(WarningsTree, "Warnings");
	
EndProcedure

&AtServer
Procedure AddWarningsTree(Issues, TreeBranch, List = False)
	Number = 1;
	For Each Issue1 In Issues Do
		String = TreeBranch.Add();
		If List Then
			String.DetectionLocation = Issue1.Value;
			String.LongDesc         = Issue1.Presentation;
		Else
			String.DetectionLocation = Issue1;
		EndIf;
		String.Number = Number;
		Number = Number + 1;
	EndDo;
EndProcedure

#EndRegion

