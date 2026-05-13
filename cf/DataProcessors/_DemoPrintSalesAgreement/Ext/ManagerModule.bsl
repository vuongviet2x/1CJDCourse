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

// Defines the API parts for calling from the configuration code.
//
// Parameters:
//  InterfaceSettings4 - Structure:
//   * AddPrintCommands - Boolean
//   * Location - Array
//
Procedure OnDefineSettings(InterfaceSettings4) Export
	
	InterfaceSettings4.Location.Add(Metadata.Documents._DemoSalesOrder);
	InterfaceSettings4.Location.Add(Metadata.Documents._DemoCustomerProformaInvoice);
	InterfaceSettings4.Location.Add(Metadata.Documents._DemoGoodsSales);
	
	InterfaceSettings4.AddPrintCommands = True;
	
EndProcedure

// Populates a list of print commands.
// 
// Parameters:
//  PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "PrintManagement";
	PrintCommand.Id = "DataProcessor._DemoPrintSalesAgreement.PrintForm_MXL_SalesAgreement";
	PrintCommand.Presentation = NStr("ru = 'Договор купли-продажи (общий макет)';
										|en = 'Sales agreement (common template)';");

EndProcedure

#EndRegion

#EndIf
