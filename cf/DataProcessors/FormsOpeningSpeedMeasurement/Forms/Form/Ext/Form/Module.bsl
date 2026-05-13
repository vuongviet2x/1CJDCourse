///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Variables

&AtClient
Var OpenedFormSearchCounter;

&AtClient
Var OpenStart;

&AtClient
Var NumberOfMeasurements;

&AtClient
Var Counter;

&AtClient
Var FormSelectedFromList;

&AtClient
Var Measurements;

#EndRegion

#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	NumberOfMeasurements = 0;
	AttachIdleHandler("FillFormsSelectionList", 1, True);
	If MeasurementsCount = 0 Then
		MeasurementsCount = 5;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PerformMeasurement(Command)
	If Not CheckFilling() Then
		Return;
	EndIf;
	CurFroze = MeasurementDetails();
	If MeasurementDetails <> CurFroze Then
		MeasurementDetails = CurFroze;
		NumberOfMeasurements = 0;
		Measurements = New Array;
	EndIf;
	Counter = MeasurementsCount;
	FormSelectedFromList = Items.FormName.ChoiceList.FindByValue(NameOfFormToOpen_) <> Undefined;
	StartMeasurement();
EndProcedure

&AtClient
Procedure ClearResults(Command)
	NumberOfMeasurements = 0;
	Measurements = New Array;
	MeasurementsResults.Clear();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure FillFormsSelectionList()
	Status(NStr("ru = 'Подготовка данных для анализа...';
					|en = 'Preparing data for analysis…';"));
	FillListOfAvailableForms();
	Status(NStr("ru = 'Подготовка данных завершена.';
					|en = 'Data is prepared.';"));
EndProcedure

&AtServer
Procedure FillListOfAvailableForms()
	For Each Form In ListOfAllConfigurationForms() Do
		Items.FormName.ChoiceList.Add(Form);
	EndDo;
EndProcedure

&AtServer
Function ListOfAllConfigurationForms()
	
	MetadataObjectsCollections = New Array;
	MetadataObjectsCollections.Add("CommonForms");
	MetadataObjectsCollections.Add("Catalogs");
	MetadataObjectsCollections.Add("Documents");
	MetadataObjectsCollections.Add("DocumentJournals");
	MetadataObjectsCollections.Add("Enums");
	MetadataObjectsCollections.Add("Reports");
	MetadataObjectsCollections.Add("DataProcessors");
	MetadataObjectsCollections.Add("ChartsOfCharacteristicTypes");
	MetadataObjectsCollections.Add("ChartsOfAccounts");
	MetadataObjectsCollections.Add("ChartsOfCalculationTypes");
	MetadataObjectsCollections.Add("InformationRegisters");
	MetadataObjectsCollections.Add("AccumulationRegisters");
	MetadataObjectsCollections.Add("AccountingRegisters");
	MetadataObjectsCollections.Add("CalculationRegisters");
	MetadataObjectsCollections.Add("BusinessProcesses");
	MetadataObjectsCollections.Add("Tasks");
	MetadataObjectsCollections.Add("ExchangePlans");
	MetadataObjectsCollections.Add("FilterCriteria");
	MetadataObjectsCollections.Add("SettingsStorages");

	Result = New Array;
	For Each MetadataObjectCollection In MetadataObjectsCollections Do
		For Each MetadataObject In Metadata[MetadataObjectCollection] Do
			If Metadata[MetadataObjectCollection] = Metadata.CommonForms Then
				Result.Add(MetadataObject.FullName());
			Else
				For Each Form In MetadataObject.Forms Do
					Result.Add(Form.FullName());
				EndDo;
			EndIf;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Function OpeningParameters()
	Result = New Structure;
	For Each ParameterDetails In OpeningParameters Do
		Result.Insert(ParameterDetails.Name, ParameterDetails.Value);
	EndDo;
	Return Result;
EndFunction

&AtClient
Procedure StartMeasurement()
	FormOpenParameters = OpeningParameters();
	OpenStart = CurrentUniversalDateInMilliseconds();
	Try
		OpenForm(NameOfFormToOpen_, FormOpenParameters);
	Except
		DetachIdleHandler("CommitOpenForm");
		Raise;
	EndTry;
	OpenedFormSearchCounter = 0;
	CommitOpenForm();
EndProcedure

&AtClient
Procedure FinishMeasurement()
	
	OpeningTime = CurrentUniversalDateInMilliseconds() - OpenStart;
	Measurements.Add(OpeningTime);
	
	If Measurements.Count() = 1 Then
		If MeasurementsResults.Count() > 0 Then
			MeasurementsResults.Add("");
		EndIf;
		MeasurementsResults.Add(MeasurementDetails);
	EndIf;
	
	If Measurements.Count() = 1 Then
		ResultTemplate = NStr("ru = '[%1] %2мс (измерение: %3, исключено из подсчета среднего)';
								|en = '[%1] %2 ms (dimension: %3, is excluded from calculation of the mean)';");
		MeasurementResultPresentation =  StrReplace(StrReplace(StrReplace(ResultTemplate,
			"%1", Format(CurrentDate(), "DLF=T")), // CAC:143 - the current session date is not required.
			"%2", OpeningTime),
			"%3", Measurements.Count());
	Else
		ResultTemplate = NStr("ru = '[%1] %2мс (измерение: %3, в среднем: %4 ± %5 мс, минимум: %6, максимум: %7)';
								|en = '[%1] %2ms (dimension: %3, at the mean: %4 ± %5ms, min: %6, max: %7)';");
		MeasurementResultPresentation = StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(ResultTemplate,
			"%1", Format(CurrentDate(), "DLF=T")), // CAC:143 - the current session date is not required.
			"%2", OpeningTime),
			"%3", Measurements.Count()),
			"%4", ArithmeticMeanOfMeasurementTime()),
			"%5", RootMeanSquareVariance()),
			"%6", MinMeasurementValue()),
			"%7", MaxMeasurementValue());
	EndIf;
		
	MeasurementsResults.Add(MeasurementResultPresentation);
	CurrentItem = Items.MeasurementsResults;
	Items.MeasurementsResults.CurrentRow = MeasurementsResults.Count() - 1;
	
	If Counter = 1 And MeasurementsCount > 1 Then
		ResultTemplate = NStr("ru = 'Среднее время открытия формы: %1 ± %2 мс (измерений: %3)';
								|en = 'Average form opening time: %1 ± %2 ms (measurements: %3)';");
		MeasurementResultPresentation =  StrReplace(StrReplace(StrReplace(ResultTemplate,
			"%1", ArithmeticMeanOfMeasurementTime()),
			"%2", RootMeanSquareVariance()),
			"%3", Measurements.Count());
		ShowUserNotification(NStr("ru = 'Замер выполнен';
											|en = 'Measured';"), , MeasurementResultPresentation);
	EndIf;
	
EndProcedure

&AtClient
Function MeasurementDetails()
	Return NameOfFormToOpen_ + ParametersPresentation();
EndFunction

&AtClient
Function ParametersPresentation()
	Result = "";
	For Each ParameterDetails In OpeningParameters Do
		If Not IsBlankString(Result) Then
			Result = Result + ", ";
		EndIf;
		Result = Result + ParameterDetails.Name + "='" + String(ParameterDetails.Value) + "'";
	EndDo;
	If Not IsBlankString(Result) Then
		Result = " (" + Result + ")";
	EndIf;
	Return Result;
EndFunction

&AtClient
Procedure CommitOpenForm()
	OpenedFormSearchCounter = OpenedFormSearchCounter + 1;
	OpenWindow = ActiveWindow();
	Form = OpenWindow.Content[0];
	If Form.IsOpen()
		And ((FormSelectedFromList And Form.FormName = NameOfFormToOpen_)
		Or (Not FormSelectedFromList And Form <> ThisObject)) Then
		FinishMeasurement();
		Form.Close();
		Counter = Counter - 1;
		If Counter > 0 Then
			AttachIdleHandler("StartMeasurement", 0.1, True);
		EndIf;
	Else
		If OpenedFormSearchCounter > 50 Then
			Waiting = (CurrentUniversalDateInMilliseconds() - OpenStart) / 1000;
			If Waiting > 2 Then
				Status(NStr("ru = 'Ожидается открытие формы...';
								|en = 'Waiting for the form to open…';"));
			EndIf;
			If Waiting > 10 Then
				Status(NStr("ru = 'Замер прекращен.';
								|en = 'Measurement aborted.';"));
				ShowMessageBox(, NStr("ru = 'Не удалось зафиксировать открытие формы. Замер прекращен.';
												|en = 'Failed to record form opening. Measurement aborted.';"));
				Return;
			EndIf;
			AttachIdleHandler("CommitOpenForm", 0.1, True);
		Else
			CommitOpenForm();
		EndIf;
	EndIf;
EndProcedure

&AtClient
Function ArithmeticMeanOfMeasurementTime()
	If Measurements = Undefined Or Measurements.Count() < 2 Then
		Return 0;
	EndIf;
	
	MeasurementsSum1 = 0;
	For MeasurementNumber = 1 To Measurements.UBound() Do
		Measurement = Measurements[MeasurementNumber];
		MeasurementsSum1 = MeasurementsSum1 + Measurement;
	EndDo;
	
	Return Round(MeasurementsSum1 / Measurements.UBound());
EndFunction

&AtClient
Function RootMeanSquareVariance()
	If Measurements = Undefined Or Measurements.Count() < 2 Then
		Return 0;
	EndIf;
	
	AverageTime = ArithmeticMeanOfMeasurementTime();
	SumOfSquaredResiduals = 0;
	For MeasurementNumber = 1 To Measurements.UBound() Do
		Measurement = Measurements[MeasurementNumber];
		SumOfSquaredResiduals = SumOfSquaredResiduals + Pow(Measurement - AverageTime, 2);
	EndDo;
	
	Return Round(Pow(SumOfSquaredResiduals / Measurements.UBound(), 1/2));
EndFunction

&AtClient
Function MinMeasurementValue()
	If Measurements = Undefined Or Measurements.Count() < 2 Then
		Return 0;
	EndIf;
	
	Minimum = 99999;
	
	For MeasurementNumber = 1 To Measurements.UBound() Do
		Measurement = Measurements[MeasurementNumber];
		Minimum = Min(Minimum, Measurement);
	EndDo;
	
	Return Minimum;
EndFunction

&AtClient
Function MaxMeasurementValue()
	If Measurements = Undefined Or Measurements.Count() < 2 Then
		Return 0;
	EndIf;
	
	Maximum = 0;
	
	For MeasurementNumber = 1 To Measurements.UBound() Do
		Measurement = Measurements[MeasurementNumber];
		Maximum = Max(Maximum, Measurement);
	EndDo;
	
	Return Maximum;
EndFunction

#EndRegion

