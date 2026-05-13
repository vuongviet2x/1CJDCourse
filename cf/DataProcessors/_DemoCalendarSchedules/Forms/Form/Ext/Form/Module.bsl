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
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	Calendars.Ref
	|FROM
	|	Catalog.Calendars AS Calendars";
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Calendar	= Selection.Ref;
	EndIf;
	
	Date			= CurrentSessionDate();
	DaysCount	= 3;
	
	DatesOnCalendarTable.Add().DaysCount = 2;
	DatesOnCalendarTable.Add().DaysCount = 3;
	DatesOnCalendarTable.Add().DaysCount = 5;
	
	WorkdaysDates.Add().Date = '20160818000000';
	WorkdaysDates.Add().Date = '20160613000000';
	WorkdaysDates.Add().Date = '20161104000000';
	WorkdaysDates.Add().Date = '20200330000000';
	WorkdaysDates.Add().Date = '20241231000000';
	
	StartDate = CurrentSessionDate();
	EndDate = StartDate + 7 * 86400; // 86,400 seconds is one day.
	
	If Common.IsMobileClient() Then
		Items.Calendar.TitleLocation = FormItemTitleLocation.Top;
		Items.EndDate.TitleHeight = 2;
		Items.DateDiff.TitleLocation = FormItemTitleLocation.Auto;
		Items.DateDiff.ToolTipRepresentation = ToolTipRepresentation.None;
		Items.DateByCalendar.TitleLocation = FormItemTitleLocation.Auto;
	Else
		Items.IndentBetween.Visible = False;
		Items.IndentAfter.Visible = False;
		Items.IndentBeforeExamples.Visible = False;
	EndIf;
	
	SetFormItemsProperties(ThisObject);
	FillNonWorkPeriods(ThisObject);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CalendarOnChange(Item)
	SetFormItemsProperties(ThisObject);
	FillNonWorkPeriods(ThisObject);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CalculateDate(Command)
	
	Try
		DateByCalendar = DateByCalendar(Calendar, Date, DaysCount);
		
	Except
		CommonClient.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()), Calendar);
	EndTry;
	
EndProcedure

&AtClient
Procedure CalculateDatesArray(Command)
	
	Try
		DaysArray = New Array;
		
		For Each TableRow In DatesOnCalendarTable Do
			DaysArray.Add(TableRow.DaysCount);
		EndDo;
		
		DatesArray = DatesByCalendar(Calendar, Date, DaysArray, CalculateNextDateFromPrevious);
		
		For Each TableRow In DatesOnCalendarTable Do
			TableRow.DateByCalendar = DatesArray[DatesOnCalendarTable.IndexOf(TableRow)];
		EndDo;
		
	Except
		CommonClient.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()), Calendar);
	EndTry;
	
EndProcedure

&AtClient
Procedure CalculateDaysCount(Command)
	
	Try
		DateDiff = GetDatesDiffByCalendar(Calendar, StartDate, EndDate);
	Except
		CommonClient.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()), Calendar);
	EndTry;
	
EndProcedure

&AtClient
Procedure GetWorkdaysDates(Command)
	
	FillWorkdaysDates();
	
EndProcedure

#EndRegion

#Region Private

// Calls a function of the CalendarSchedules common module to get a calendar date.
//
// Parameters:
//   WorkScheduleCalendar	- CatalogRef.Calendars
//   Date			- Date
//   DaysCount	- Number
//
// Returns:
//  Data - Given date offset by the number of days in the schedule.
//
&AtServerNoContext
Function DateByCalendar(Calendar, Date, DaysCount)
	
	Return CalendarSchedules.DateByCalendar(Calendar, Date, DaysCount);
	
EndFunction

// Calls a function of the CalendarSchedules common module to get a date array by the calendar.
//
// Parameters:
//   WorkScheduleCalendar	- CatalogRef.Calendars
//   Date			- Date
//   DaysArray		- Array of Number
//
// Returns
//  DatesArray		- Array of dates increased by the number of days included in the schedule.
//
&AtServerNoContext
Function DatesByCalendar(Calendar, Date, DaysArray, CalculateNextDateFromPrevious)
	
	Return CalendarSchedules.DatesByCalendar(Calendar, Date, DaysArray, CalculateNextDateFromPrevious);
	
EndFunction

// Calls a function of the CalendarSchedules common module to get a calendar date.
//
// Parameters:
//   WorkScheduleCalendar	- CatalogRef.Calendars
//   StartDate		- Date
//   EndDate	- Date
//
// Returns:
//  CalendarDate - Given date offset by the number of days in the schedule.
//
&AtServerNoContext
Function GetDatesDiffByCalendar(Calendar, StartDate, EndDate)
	
	Return CalendarSchedules.DateDiffByCalendar(Calendar, StartDate, EndDate);
	
EndFunction

&AtServer
Procedure FillWorkdaysDates()
	
	If TypeOf(Calendar) = Type("CatalogRef.BusinessCalendars") Then
		ReceivingParameters = CalendarSchedules.NearestWorkDatesReceivingParameters();
		ReceivingParameters.GetPrevious = GetPrevious;
		ReceivingParameters.ConsiderNonWorkPeriods = ConsiderNonWorkPeriods;
		ReceivingParameters.NonWorkPeriods = Common.UnloadColumn(
			NonWorkPeriods.FindRows(New Structure("Consider", True)), "Number");
		ReceivingParameters.ShouldGetDatesIfCalendarNotFilled = ShouldGetDatesIfCalendarNotFilled;
		WorkDates = CalendarSchedules.NearestWorkDates(
			Calendar, WorkdaysDates.Unload().UnloadColumn("Date"), ReceivingParameters);
	Else
		ReceivingParameters = WorkSchedules.NearestDatesByScheduleReceivingParameters();
		ReceivingParameters.GetPrevious = GetPrevious;
		WorkDates = WorkSchedules.NearestDatesIncludedInSchedule(
			Calendar, WorkdaysDates.Unload().UnloadColumn("Date"), ReceivingParameters);
	EndIf;
	
	For Each TableRow In WorkdaysDates Do
		TableRow.WorkingDate = WorkDates[TableRow.Date];
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetFormItemsProperties(Form)
	
	CommonClientServer.SetFormItemProperty(Form.Items, "ConsiderNonWorkPeriods",
		"Enabled", TypeOf(Form.Calendar) = Type("CatalogRef.BusinessCalendars"));
	CommonClientServer.SetFormItemProperty(Form.Items, "ShouldGetDatesIfCalendarNotFilled",
		"Visible", TypeOf(Form.Calendar) = Type("CatalogRef.BusinessCalendars"));
		
EndProcedure

&AtClientAtServerNoContext
Procedure FillNonWorkPeriods(Form)
	
	Form.NonWorkPeriods.Clear();
	
	If TypeOf(Form.Calendar) <> Type("CatalogRef.BusinessCalendars") Then
		Return;
	EndIf;
	
	For Each Period In NonWorkDaysPeriods(Form.Calendar) Do
		NewRow = Form.NonWorkPeriods.Add();
		FillPropertyValues(NewRow, Period);
		NewRow.Consider = True;
	EndDo;

EndProcedure

&AtServerNoContext
Function NonWorkDaysPeriods(BusinessCalendar)
	Return CalendarSchedules.NonWorkDaysPeriods(BusinessCalendar, New StandardPeriod());
EndFunction

#EndRegion
