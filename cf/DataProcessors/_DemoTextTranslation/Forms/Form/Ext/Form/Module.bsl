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
	
	For Each Item In TextTranslationTool.AvailableLanguages() Do
		Items.SourceLanguage.ChoiceList.Add(Item.Value, Item.Presentation);
		Items.TranslationLanguage.ChoiceList.Add(Item.Value, Item.Presentation);
	EndDo;
	
	TranslationLanguage = Common.DefaultLanguageCode();
	
EndProcedure


#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SourceLanguageOnChange(Item)
	
	TranslateText();
	
EndProcedure

&AtClient
Procedure TranslationLanguageOnChange(Item)
	
	TranslateText();
	
EndProcedure

&AtClient
Procedure TranslationLanguageClearing(Item, StandardProcessing)
	
	TranslationLanguage = CommonClient.DefaultLanguageCode();
	
EndProcedure

&AtClient
Procedure SourceTextEditTextChange(Item, Text, StandardProcessing)
	
	TranslateText(Text);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeTranslationDirection(Command)
	
	If ValueIsFilled(SourceLanguage) Then
		TextLanguage = SourceLanguage;
	EndIf;
	SourceLanguage = TranslationLanguage;
	TranslationLanguage = TextLanguage;
	
	Text = SourceText;
	SourceText = TranslationText;
	TranslationText = Text;
	
	TranslateText();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure TranslateText(Val Text = Undefined)
	
	If Not ValueIsFilled(Text) Then
		Text = SourceText;
	EndIf;
	
	TextLanguage = SourceLanguage;
	If ValueIsFilled(Text) Then
		TranslationText = TranslateTextOnTheServer(Text, TranslationLanguage, TextLanguage);
		If Not ValueIsFilled(SourceLanguage) And ValueIsFilled(TextLanguage) Then
			Item = Items.SourceLanguage.ChoiceList.FindByValue(TextLanguage);
			Items.SourceLanguage.InputHint = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1 (определен автоматически)';
					|en = '%1 (determined automatically)';"), Item.Presentation);
		EndIf;
	Else
		TranslationText = "";
	EndIf;
	
EndProcedure
	
&AtServerNoContext
Function TranslateTextOnTheServer(SourceText, TranslationLanguage, SourceLanguage)
	
	Return TextTranslationTool.TranslateText(SourceText, TranslationLanguage, SourceLanguage);
	
EndFunction

#EndRegion
