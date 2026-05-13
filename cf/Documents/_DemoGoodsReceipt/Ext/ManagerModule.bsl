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

// Defines the list of report commands.
//
// Parameters:
//  ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//  Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

// End StandardSubsystems.ReportsOptions

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the ObjectsVersioning subsystem.
//
// Parameters:
//  Settings - Structure - Subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

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
	PrintCommand.Id = "Document._DemoGoodsReceipt.PF_MXL_GoodsReceipt";
	PrintCommand.Presentation = NStr("en = 'Goods receipt';");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.PrintManager = "PrintManagement";

	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "WarehouseReceipt";
	PrintCommand.Presentation = NStr("en = 'Receipt at warehouse';");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.Order = 10;

	Warehouse = Catalogs._DemoStorageLocations.FindByDescription("Storage #1", True);
	If ValueIsFilled(Warehouse) Then
		PrintManagement.AddCommandVisibilityCondition(
			PrintCommand,
			"StorageLocation",
			Warehouse,
			ComparisonType.Equal
		);
	EndIf;
	
	// Document set.
	CommandsID = New Array;
	CommandsID.Add("WarehouseReceipt");
	CommandsID.Add("WarehouseReceipt");
	CommandsID.Add("DataProcessor.PrintGoodsReceipt1.GoodsReceipt1");
	CommandsID.Add("DataProcessor.PrintGoodsReceipt2.GoodsReceipt2");
	CommandsID.Add("DataProcessor.PrintGoodsReceipt2.GoodsReceipt3");
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = StrConcat(CommandsID, ",");
	PrintCommand.Presentation = NStr("en = 'Document set';");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.FixedSet = True;
	PrintCommand.Order = 75;
	
	// Document set.
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "Document._DemoGoodsReceipt.PF_MXL_GoodsReceipt,Document._DemoGoodsReceipt.PF_MXL_WarehouseReceipt";
	PrintCommand.Presentation = NStr("en = 'Document set 2';");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.FixedSet = True;
	PrintCommand.Order = 75;
	PrintCommand.PrintManager = "PrintManagement";
	
	If ValueIsFilled(Warehouse) Then
		PrintManagement.AddCommandVisibilityCondition(
			PrintCommand,
			"StorageLocation",
			Warehouse,
			ComparisonType.Equal
		);
	EndIf;
	
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
	
	// Print a warehouse receipt
	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "WarehouseReceipt");
	If PrintForm <> Undefined Then
		PrintForm.SpreadsheetDocument = PrintWarehouseReceipt(ObjectsArray, PrintObjects);
		PrintForm.TemplateSynonym = NStr("en = 'Warehouse receipt'");
		PrintForm.FullTemplatePath = "Document._DemoGoodsReceipt.PF_MXL_WarehouseReceipt";
	EndIf;
	
EndProcedure

Function PrintWarehouseReceipt(RefsToObjects, PrintObjects)

	Spreadsheet = New SpreadsheetDocument;
	Spreadsheet.PrintParametersKey = "PrintParameters_DemoGoodsReceiptWarehouseReceipt";
	
	Template = PrintManagement.PrintFormTemplate("Document._DemoGoodsReceipt.PF_MXL_WarehouseReceipt");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	_DemoGoodsReceipt.Ref AS Ref,
	|	_DemoGoodsReceipt.EmployeeResponsible,
	|	_DemoGoodsReceipt.Organization,
	|	_DemoGoodsReceipt.Partner,
	|	_DemoGoodsReceipt.StorageLocation,
	|	_DemoGoodsReceipt.Goods.(
	|		LineNumber,
	|		Products,
	|		Count,
	|		Price
	|	)
	|FROM
	|	Document._DemoGoodsReceipt AS _DemoGoodsReceipt
	|WHERE
	|	_DemoGoodsReceipt.Ref IN (&Refs)";
	
	Query.Parameters.Insert("Refs", RefsToObjects);
	
	Selection = Query.Execute().Select();

	AreaCaption = Template.GetArea("Caption");
	Header = Template.GetArea("Header");
	AreaGoodsHeader = Template.GetArea("GoodsHeader");
	AreaGoods = Template.GetArea("Goods");
	Footer = Template.GetArea("Footer");

	InsertPageBreak = False;
	While Selection.Next() Do
		If InsertPageBreak Then
			Spreadsheet.PutHorizontalPageBreak();
		EndIf;
		RowNumberStart = Spreadsheet.TableHeight + 1;

		Spreadsheet.Put(AreaCaption);

		Header.Parameters.Fill(Selection);
		Spreadsheet.Put(Header, Selection.Level());

		Spreadsheet.Put(AreaGoodsHeader);
		SelectionGoods = Selection.Goods.Select();
		While SelectionGoods.Next() Do
			AreaGoods.Parameters.Fill(SelectionGoods);
			Spreadsheet.Put(AreaGoods, SelectionGoods.Level());
		EndDo;

		Footer.Parameters.Fill(Selection);
		Spreadsheet.Put(Footer);

		InsertPageBreak = True;
		
		PrintManagement.SetDocumentPrintArea(Spreadsheet, RowNumberStart, PrintObjects, Selection.Ref);
	EndDo;

	Return Spreadsheet;
	
EndFunction

// End StandardSubsystems.Print

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(StorageLocation)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.AttachableCommands

// Defines the list of generation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents._DemoGoodsSales.AddGenerateCommand(GenerationCommands);
	Documents._DemoGoodsWriteOff.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Intended for use by the AddGenerationCommands procedure in other object manager modules.
// Adds this object to the list of generation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - Details of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents._DemoGoodsReceipt);
	
EndFunction

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#EndIf