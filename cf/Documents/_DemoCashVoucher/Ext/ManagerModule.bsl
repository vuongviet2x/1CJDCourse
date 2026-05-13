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

// StandardSubsystems.Print

// Overrides object's print settings.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// Populates a list of print commands.
// 
// Parameters:
//  PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "CashPaymentToAdvanceHolder";
	PrintCommand.Presentation = NStr("ru = 'Выдача средств подотчетнику';
										|en = 'Cash payment to advance holder';");
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand, "BusinessOperation",
		Enums._DemoBusinessOperations.IssueCashToAdvanceHolder);
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "SalaryPayment";
	PrintCommand.Presentation = NStr("ru = 'Выдача зарплаты';
										|en = 'Salary payment';");
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand, "BusinessOperation",
		Enums._DemoBusinessOperations.SalaryPayment);
		
EndProcedure

// Generates print forms.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "CashPaymentToAdvanceHolder");
	If PrintForm <> Undefined Then
		SpreadsheetDocument = New SpreadsheetDocument;
		Area = SpreadsheetDocument.Area(1, 1, 1, 1);
		Area.Text = NStr("ru = 'Демонстрация динамической видимости команд печати. Печатная форма ""Выдача средств подотчетнику"".';
							|en = 'Demonstration of dynamic visibility of print commands. Print form ""Cash payment to advance holder"".';");
		PrintForm.SpreadsheetDocument = SpreadsheetDocument;
	EndIf;
	
	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "SalaryPayment");
	If PrintForm <> Undefined Then
		SpreadsheetDocument = New SpreadsheetDocument;
		Area = SpreadsheetDocument.Area(1, 1, 1, 1);
		Area.Text = NStr("ru = 'Демонстрация динамической видимости команд печати. Печатная форма ""Выдача зарплаты"".';
							|en = 'Demonstration of dynamic visibility of print commands. Print form ""Salary payment"".';");
		PrintForm.SpreadsheetDocument = SpreadsheetDocument;
	EndIf;
	
EndProcedure

// End StandardSubsystems.Print

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(CashAccount.Owner)
	|	AND ValueAllowed(CashAccount)
	|	AND ValueAllowed(BusinessOperation)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf