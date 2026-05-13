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

	If Parameters.Owner.IsEmpty() Then
		MessageText = NStr("ru = 'Данная форма предназначена для открытия только из вопросов для анкетирования.';
								|en = 'This form can be opened only from survey questions.';");
		Common.MessageToUser(MessageText);
		Cancel = True;
		Return;
	EndIf;

	Object.Owner = Parameters.Owner;
	If Not Parameters.ReplyType.IsEmpty() Then
		Items.OpenEndedQuestion.Visible = (Parameters.ReplyType = Enums.TypesOfAnswersToQuestion.MultipleOptionsFor);
	Else
		ReplyType = Common.ObjectAttributeValue(Object.Owner, "ReplyType");
		Items.OpenEndedQuestion.Visible = (ReplyType = Enums.TypesOfAnswersToQuestion.MultipleOptionsFor);
	EndIf;

	If Not IsBlankString(Parameters.Description) Then
		Object.Description = Parameters.Description;
	EndIf;

EndProcedure

#EndRegion