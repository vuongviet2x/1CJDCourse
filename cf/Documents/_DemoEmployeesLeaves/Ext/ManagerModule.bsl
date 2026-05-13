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

// StandardSubsystems.AttachableCommands

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
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection.
//
Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PF_MXL_T6a";
	PrintCommand.Presentation = NStr("ru = 'Приказ о предоставлении отпуска работникам (Т-6а)';
										|en = 'Order on granting leave to employees (T-6a)';");
	PrintCommand.CheckPostingBeforePrint = True;

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
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PF_MXL_T6a") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"PF_MXL_T6a",
			NStr("ru = 'Приказ о предоставлении отпуска работникам (Т-6а)';
				|en = 'Order on granting leave to employees (T-6a)';"),
			ToFormPrintedFormT6A(ObjectsArray, PrintObjects),
			,
			"Document._DemoEmployeesLeaves.PF_MXL_T6a");
	EndIf;
	
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

Function ToFormPrintedFormT6A(ObjectsArray, PrintObjects)

	QueryText = 
	"SELECT
	|	_DemoEmployeesLeaves.Ref AS Ref,
	|	_DemoEmployeesLeaves.Number AS Number,
	|	_DemoEmployeesLeaves.Date AS Date,
	|	_DemoEmployeesLeaves.Organization AS Organization,
	|	_DemoEmployeesLeaves.Manager AS Manager,
	|	_DemoEmployeesLeaves.Employees_.(
	|		Employee AS Employee,
	|		StartDate AS StartDate,
	|		EndDate AS EndDate,
	|		DaysCount AS DaysCount
	|	) AS Employees_
	|FROM
	|	Document._DemoEmployeesLeaves AS _DemoEmployeesLeaves
	|WHERE
	|	_DemoEmployeesLeaves.Ref IN(&DocumentsList)";

	Query = New Query(QueryText);
	Query.SetParameter("DocumentsList", ObjectsArray);

	Header = Query.Execute().Select();

	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PF_MXL_T6a";

	Template = PrintManagement.PrintFormTemplate("Document._DemoEmployeesLeaves.PF_MXL_T6a");

	ArrayOfLayoutAreas = New Array;
	ArrayOfLayoutAreas.Add("Header");
	ArrayOfLayoutAreas.Add("TableHeader");
	ArrayOfLayoutAreas.Add("String");
	ArrayOfLayoutAreas.Add("Footer");

	While Header.Next() Do
		If SpreadsheetDocument.TableHeight > 0 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;

		RowNumberStart = SpreadsheetDocument.TableHeight + 1;

		PrintData = New Structure;
			
		PrintData.Insert("Number", ObjectsPrefixesClientServer.NumberForPrinting(Header.Number, True, True));
		PrintData.Insert("Date", Format(Header.Date, "DLF=D"));
		PrintData.Insert("Organization", Header.Organization);
		PrintData.Insert("ManagerLastFirstName", Header.Manager);
	
		TableEmployees = Header.Employees_.Unload();

		For Each AreaName In ArrayOfLayoutAreas Do
			TemplateArea = Template.GetArea(AreaName);
			If StrCompare(AreaName,"String") <> 0 Then
				FillPropertyValues(TemplateArea.Parameters, PrintData);
				SpreadsheetDocument.Put(TemplateArea);
			Else
				Account = 1;
				For Each TableRow In TableEmployees Do
					TemplateArea.Parameters.Fill(TableRow);
					TemplateArea.Parameters.TabNumber = Format(Account,"ND=4; NLZ=; NG=");
					SpreadsheetDocument.Put(TemplateArea);
					Account = Account+1;
				EndDo;
			EndIf;
		EndDo;

		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, Header.Ref);

	EndDo;

	Return SpreadsheetDocument;

EndFunction

#EndRegion

#EndIf
