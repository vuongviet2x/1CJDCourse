///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ReportsOptions

// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ViewAnswersSimpleQuestions");
	OptionSettings.LongDesc = NStr("ru = 'Информация о том, как отвечали респонденты на простые вопросы.';
										|en = 'Information about how respondents answered basic questions.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ViewTableQuestionsFlatView");
	OptionSettings.LongDesc = 
		NStr("ru = 'Информация о том, как отвечали респонденты на табличные вопросы.
		|Выводится в виде списка с группировками.';
		|en = 'Information about replies the respondents gave to question charts.
		|Displayed as a list with grouping.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ViewTableQuestionsTableView");
	OptionSettings.LongDesc = 
		NStr("ru = 'Информация о том, как  отвечали респонденты на табличные вопросы.
		|Каждый ответ респондента представлен в виде таблицы.';
		|en = 'Information about replies the respondents gave to table questions.
		|Each reply is displayed as a table.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "SimpleQuestionsAnswerCount");
	OptionSettings.LongDesc = NStr("ru = 'Информация о том, сколько раз был дан вариант ответа на простой вопрос.';
										|en = 'Information on how many times the response option was given to a basic question.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "SimpleQuestionsAggregatedIndicators");
	OptionSettings.LongDesc = 
		NStr("ru = 'Информация о среднем, минимальном, максимальном ответе на простой вопрос,
		|который требует числового ответа.';
		|en = 'Information on average, minimum, and maximum response to a basic question
		|that requires a numeric value.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "TableQuestionsAnswerCount");
	OptionSettings.LongDesc = 
		NStr("ru = 'Информация о том, сколько раз был дан варианта ответа для табличных вопросов,
		|который требует указания числового значения.';
		|en = 'Information on how many times the response option which requires a numeric value 
		|was given in question charts.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "TableQuestionsAggregatedParameters");
	OptionSettings.LongDesc = 
		NStr("ru = 'Информация о среднем, минимальном, максимальном ответе в ячейке табличного вопроса,
		|который требует указания числового значения.';
		|en = 'Information on average, minimum, and maximum response in the cell of a question chart
		|that requires a numeric value.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "SimpleQuestionsAnswerCountComparisonBySurveys");
	OptionSettings.LongDesc = 
		NStr("ru = 'Сравнительный анализ количества данных вариантов ответов 
		|на простые вопросы в разных опросах.';
		|en = 'Comparative analysis of the responses
		|to basic questions in surveys.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "TableQuestionsAggregatedParametersComparisonBySurveys");
	OptionSettings.LongDesc = 
		NStr("ru = 'Сравнительный анализ агрегируемых показателей ответов в ячейках
		|табличных вопросов разных опросов.';
		|en = 'Comparative analysis of the aggregated responses
		|to question charts in surveys.';");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf