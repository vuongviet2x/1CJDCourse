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

// StandardSubsystems.AdditionalReportsAndDataProcessors

// Returns info about an external data processor.
//
// Returns:
//   See AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo
//
Function ExternalDataProcessorInfo() Export
	RegistrationParameters = AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo("2.4.1.1");
	RegistrationParameters.Information = NStr("ru = 'Демонстрирует обновление данных подсистемы ""Дополнительные отчеты и обработки"" на основании отчетов и обработок из метаданных конфигурации.';
											|en = 'Demonstrates update of the ""Additional reports and data processors"" subsystem data on the basis of reports and data processors from configuration metadata.';");
	RegistrationParameters.Kind = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalDataProcessor();
	RegistrationParameters.Version = "3.0.2.1";
	RegistrationParameters.SafeMode = False;
	
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Обновить дополнительные отчеты и обработки';
								|en = 'Update additional reports and data processors';");
	Command.Id = "UpdateAdditionalReportsAndDataProcessors";
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeServerMethodCall();
	Command.ShouldShowUserNotification = True;
	
	Return RegistrationParameters;
EndFunction

// Server commands handler.
//
// Parameters:
//   CommandName           - String    - Command name given in function ExternalDataProcessorInfo().
//   ExecutionParameters  - Structure - Command execution context:
//       * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - Data processor reference.
//           Can be used to read data processor parameters.
//           As an example, see the comments to function AdditionalReportsAndDataProcessorsClientServer.CommandTypeOpenForm().
//
Procedure ExecuteCommand(Val CommandName, Val ExecutionParameters) Export
#If ThickClientOrdinaryApplication Then
		Return;
#EndIf
	
	ReportsAndDataProcessors = New ValueTable();
	ReportsAndDataProcessors.Columns.Add("MetadataObject");
	ReportsAndDataProcessors.Columns.Add("OldObjectsNames", New TypeDescription("Array"));
	ReportsAndDataProcessors.Columns.Add("OldFilesNames",   New TypeDescription("Array"));
	
	// Reports.
	
	TableRow = ReportsAndDataProcessors.Add();
	TableRow.MetadataObject = Metadata.Reports._DemoProformaInvoicesReportGlobal;
	TableRow.OldObjectsNames.Add("GlobalReport");
	TableRow.OldObjectsNames.Add("_DemoAdditionalReport");
	TableRow.OldFilesNames.Add("GlobalReport.erf");
	TableRow.OldFilesNames.Add("_DemoAdditionalReport.erf");
	TableRow.OldFilesNames.Add("AdditionalReport.erf");
	
	TableRow = ReportsAndDataProcessors.Add();
	TableRow.MetadataObject = Metadata.Reports._DemoProformaInvoicesReportContextual;
	TableRow.OldObjectsNames.Add("Report");
	TableRow.OldObjectsNames.Add("_DemoContextReport");
	TableRow.OldObjectsNames.Add("_DemoAdditionalReportAssignable");
	TableRow.OldObjectsNames.Add("_DemoAdditionalReportContext");
	TableRow.OldFilesNames.Add("Report.erf");
	TableRow.OldFilesNames.Add("_DemoAdditionalReportAssignable.erf");
	TableRow.OldFilesNames.Add("ContextReport.erf");
	
	// DataProcessors.
	
	TableRow = ReportsAndDataProcessors.Add();
	TableRow.MetadataObject = Metadata.DataProcessors._DemoFullTextSearchManagement;
	TableRow.OldObjectsNames.Add("GlobalDataProcessor");
	TableRow.OldObjectsNames.Add("_DemoAdditionalDataProcessor");
	TableRow.OldFilesNames.Add("GlobalDataProcessor.epf");
	TableRow.OldFilesNames.Add("_DemoAdditionalDataProcessor.epf");
	TableRow.OldFilesNames.Add("AdditionalDataProcessor.epf");
	
	TableRow = ReportsAndDataProcessors.Add();
	TableRow.MetadataObject = Metadata.DataProcessors._DemoCounterpartiesFilling;
	TableRow.OldObjectsNames.Add("ObjectFilling");
	TableRow.OldObjectsNames.Add("_DemoAdditionalDataProcessorFillingAssignable");
	TableRow.OldFilesNames.Add("_DemoAdditionalDataProcessorFillingAssignable.epf");
	TableRow.OldFilesNames.Add("ObjectFilling.epf");
	
	TableRow = ReportsAndDataProcessors.Add();
	TableRow.MetadataObject = Metadata.DataProcessors._DemoImportBusinessEntitiesForCounterparties;
	TableRow.OldObjectsNames.Add("_DemoAdditionalDataProcessorImportFromFile");
	TableRow.OldFilesNames.Add("_DemoAdditionalDataProcessorImportFromFile.epf");
	TableRow.OldFilesNames.Add("ImportCounterpartiesFromFIle.epf");
	
	TableRow = ReportsAndDataProcessors.Add();
	TableRow.MetadataObject = Metadata.DataProcessors._DemoPrintGoodsWriteOffsOpenOfficeXML;
	TableRow.OldObjectsNames.Add("PrintForm");
	TableRow.OldObjectsNames.Add("_DemoAdditionalDataProcessorPrintMSWordAssignable");
	TableRow.OldObjectsNames.Add("_DemoPrintGoodsWriteOffUsingMSWordTemplate");
	TableRow.OldObjectsNames.Add("_DemoPrintGoodsWriteOffUsingTemplateOpenOfficeXML");
	TableRow.OldFilesNames.Add("_DemoPrintGoodsWriteOffUsingMSWordTemplate.epf");
	TableRow.OldFilesNames.Add("_DemoAdditionalDataProcessorPrintMSWordAssignable.epf");
	TableRow.OldFilesNames.Add("Print_MSWord_OO.epf");
	TableRow.OldFilesNames.Add("PrintWord.epf");
	
	TableRow = ReportsAndDataProcessors.Add();
	TableRow.MetadataObject = Metadata.DataProcessors._DemoPrintCustomerProformaInvoices;
	TableRow.OldObjectsNames.Add("PrintForm");
	TableRow.OldObjectsNames.Add("_DemoAdditionalDataProcessorPrintMXLAssignable");
	TableRow.OldFilesNames.Add("_DemoAdditionalDataProcessorPrintMXLAssignable.epf");
	TableRow.OldFilesNames.Add("Print_MXL.epf");
	
	TableRow = ReportsAndDataProcessors.Add();
	TableRow.MetadataObject = Metadata.DataProcessors._DemoInputBasedOnGoodsReceipts;
	TableRow.OldObjectsNames.Add("CreateBasedOn");
	TableRow.OldObjectsNames.Add("_DemoAdditionalDataProcessorRelatedObjectCreationAssignable");
	TableRow.OldFilesNames.Add("_DemoAdditionalDataProcessorRelatedObjectCreationAssignable.epf");
	TableRow.OldFilesNames.Add("RelatedObjectsCreation.epf");
	
	TableRow = ReportsAndDataProcessors.Add();
	TableRow.MetadataObject = Metadata.DataProcessors._DemoImportProductsFromPriceListSecurityProfiles;
	TableRow.OldObjectsNames.Add("ImportPriceList1");
	TableRow.OldObjectsNames.Add("_DemoAdditionalDataProcessorImportPriceList");
	TableRow.OldObjectsNames.Add("_DemoAdditionalDataProcessorImportPriceListWithProfile");
	TableRow.OldFilesNames.Add("ImportPriceList1.epf");
	TableRow.OldFilesNames.Add("_DemoAdditionalDataProcessorImportPriceList.epf");
	TableRow.OldFilesNames.Add("_DemoAdditionalDataProcessorImportPriceListWithProfile.epf");
	
	TableRow = ReportsAndDataProcessors.Add();
	TableRow.MetadataObject = Metadata.DataProcessors._DemoCustomerOrderMessageTemplate;
	
	AdditionalReportsAndDataProcessors.ImportAdditionalReportsAndDataProcessorsFromMetadata(ReportsAndDataProcessors);
EndProcedure

// End StandardSubsystems.AdditionalReportsAndDataProcessors

#EndRegion

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf