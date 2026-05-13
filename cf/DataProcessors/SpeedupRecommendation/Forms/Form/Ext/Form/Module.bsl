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
	CommonParameters = Common.CommonCoreParameters();
	RecommendedSize = CommonParameters.RecommendedRAM;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Cancel = True;
	
	SystemInfo = New SystemInfo;
	AvailableMemorySize = Round(SystemInfo.RAM / 1024, 1);
	
	If AvailableMemorySize >= RecommendedSize Then
		Return;
	EndIf;
	
	MessageText = NStr("ru = 'На компьютере установлено %1 Гб оперативной памяти.
		|Для того чтобы приложение работало быстрее, 
		|рекомендуется увеличить объем памяти до %2 Гб.';
		|en = 'Your computer has %1 GB of RAM.
		|Recommended RAM size is %2 GB.';");
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, AvailableMemorySize, RecommendedSize);
	
	MessageTitle = NStr("ru = 'Рекомендация по повышению скорости работы';
								|en = 'Speedup recommendation';");
	
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.Title = MessageTitle;
	QuestionParameters.Picture = PictureLib.DialogExclamation;
	QuestionParameters.Insert("CheckBoxText", NStr("ru = 'Не показывать в течение двух месяцев';
													|en = 'Remind in two months';"));
	
	Buttons = New ValueList;
	Buttons.Add("ContinueWork", NStr("ru = 'Продолжить работу';
											|en = 'Continue';"));
	
	NotifyDescription = New NotifyDescription("AfterShowRecommendation", ThisObject);
	StandardSubsystemsClient.ShowQuestionToUser(NotifyDescription, MessageText, Buttons, QuestionParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterShowRecommendation(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	RAMRecommendation = New Structure;
	RAMRecommendation.Insert("Show", Not Result.NeverAskAgain);
	RAMRecommendation.Insert("PreviousShowDate", CommonClient.SessionDate());
	
	CommonServerCall.CommonSettingsStorageSave("UserCommonSettings",
		"RAMRecommendation", RAMRecommendation);
EndProcedure

#EndRegion
