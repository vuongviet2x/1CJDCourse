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
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "LetterOfGuarantee") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
						PrintFormsCollection,
						"LetterOfGuarantee", NStr("ru = 'Гарантийное письмо';
													|en = 'Warranty letter';"),
						Documents._DemoCustomerProformaInvoice.PrintingALetterOfGuarantee(ObjectsArray, PrintObjects),
						,
						"Document._DemoCustomerProformaInvoice.PF_MXL_LetterOfGuarantee");
	EndIf;

	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "GoodsWriteOffOpenOfficeXML");
	If PrintForm <> Undefined Then
		
		TemplateName = "GoodsWriteOffOpenOfficeXML";
		ObjectTemplateAndData = PrintManagementServerCall.TemplatesAndObjectsDataToPrint("DataProcessor._DemoPrintForm", TemplateName, ObjectsArray);
		
		OfficeDocuments = New Map;
		
		Template = NStr("ru = 'Списание товаров (№[Number] от [Date])';
						|en = 'Inventory write-off (#[Number], [Date])';");
		DocumentsAttributesValues = Common.ObjectsAttributesValues(ObjectsArray, "Number,Date,Ref");
		For Each Ref In ObjectsArray Do
			
			DocumentAttributesValues = DocumentsAttributesValues[Ref];
			DocumentAttributesValues.Date = Format(DocumentAttributesValues.Date, "DLF=D");
			DocumentAttributesValues.Number = ObjectsPrefixesClientServer.NumberForPrinting(DocumentAttributesValues.Number);
			DocumentName = StringFunctionsClientServer.InsertParametersIntoString(Template, DocumentsAttributesValues[Ref]);
			
			OfficeDocumentStorageAddress = PrintGoodsWriteOff(Ref, ObjectTemplateAndData, TemplateName);
			
			OfficeDocuments.Insert(OfficeDocumentStorageAddress, DocumentName);
			
		EndDo;
		
		PrintForm.TemplateSynonym    = NStr("ru = 'Списание товаров (документ Microsoft Word)';
												|en = 'Inventory write-off (Microsoft Word document)';");
		PrintForm.OfficeDocuments = OfficeDocuments;
		
	EndIf;
	
EndProcedure

// Prepares object data for printout.
// 
// Parameters:
//  DocumentsArray - Array - References to objects, for which printing data is requested.
//  TemplatesNamesArray - Array - Names of the templates the print data to insert to.
//
// Returns:
//  Map of KeyAndValue - Collection of references to objects and their data.:
//   * Key - AnyRef - Reference to an infobase object.
//   * Value - Structure:
//    ** Key - String - Template name.
//    ** Value - Structure - Object data.
//
Function GetPrintInfo(Val DocumentsArray, Val TemplatesNamesArray) Export
	
	DataByAllObjects = New Map;
	
	For Each ObjectRef In DocumentsArray Do
		ObjectDataByTemplates = New Map;
		For Each TemplateName In TemplatesNamesArray Do
			ObjectDataByTemplates.Insert(TemplateName, GetObjectData(ObjectRef));
		EndDo;
		DataByAllObjects.Insert(ObjectRef, ObjectDataByTemplates);
	EndDo;
	
	AreasDetails = New Map;
	TemplatesBinaryData = New Map;
	
	For Each TemplateName In TemplatesNamesArray Do
		TemplatesBinaryData.Insert(TemplateName, PrintManagement.PrintFormTemplate("DataProcessor._DemoPrintForm.PF_DOC_GoodsConsumption"));
		AreasDetails.Insert(TemplateName, GetADescriptionOfTheAreasOfTheOfficeDocumentLayout());
	EndDo;
	
	Templates = New Structure("AreasDetails, TemplatesBinaryData");
	Templates.AreasDetails = AreasDetails;
	Templates.TemplatesBinaryData = TemplatesBinaryData;
	
	Result = New Structure("Data, Templates");
	Result.Data = DataByAllObjects;
	Result.Templates = Templates;
	
	Return Result;
	
EndFunction

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#Region Private

#Region PrintDocument_DemoGoodsWriteOff

////////////////////////////////////////////////////////////////////////////////
// Office document template management.

Function GetObjectData(ObjectReference)
	
	Object = ObjectReference.GetObject();
	
	ObjectData = New Structure;
	
	ObjectData.Insert("Organization",	Object.Organization);
	ObjectData.Insert("StorageLocation",	Object.StorageLocation);
	ObjectData.Insert("EmployeeResponsible",	Object.EmployeeResponsible);
	
	ObjectData.Insert("Goods", New Array);
	
	For Each LineOfATabularSection In Object.Goods Do
		RowOfProductsTable = New Structure;
		RowOfProductsTable.Insert("Products",LineOfATabularSection.Products);
		RowOfProductsTable.Insert("Count",  LineOfATabularSection.Count);
		ObjectData.Goods.Add(RowOfProductsTable);
	EndDo;
	
	Return ObjectData;
	
EndFunction

Function GetADescriptionOfTheAreasOfTheOfficeDocumentLayout()
	
	AreasDetails = New Structure;
	
	PrintManagement.AddAreaDetails(AreasDetails, "DocumentHeader",	"Shared3");
	PrintManagement.AddAreaDetails(AreasDetails, "TableHeader",		"TableRow");
	PrintManagement.AddAreaDetails(AreasDetails, "TableRow",	"TableRow");
	
	Return AreasDetails;
	
EndFunction

Function PrintGoodsWriteOff(DocumentRef, ObjectTemplateAndData, TemplateName)
	
	TemplateType				= ObjectTemplateAndData.Templates.TemplateTypes[TemplateName];
	TemplatesBinaryData	= ObjectTemplateAndData.Templates.TemplatesBinaryData;
	Areas					= ObjectTemplateAndData.Templates.AreasDetails;
	ObjectData			= ObjectTemplateAndData.Data[DocumentRef][TemplateName];
	
	Template = PrintManagement.InitializeOfficeDocumentTemplate(TemplatesBinaryData[TemplateName], TemplateType, TemplateName);
	If Template = Undefined Then
		Return "";
	EndIf;
	
	ClosePrintFormWindow = False;
	Try
		PrintForm = PrintManagement.InitializePrintForm(TemplateType, Template.TemplatePagesSettings, Template);
		PrintFormStorageAddress = "";
		If PrintForm = Undefined Then
			PrintManagement.ClearRefs(Template);
			Return "";
		EndIf;
				
		// Display the document header: Common area with parameters.
		Area = PrintManagement.TemplateArea(Template, Areas[TemplateName]["DocumentHeader"]);
		PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
		
		If ObjectData.Goods.Count() > 0 Then
			// Output a data collection from the infobase as a table.
			Area = PrintManagement.TemplateArea(Template, Areas[TemplateName]["TableHeader"]);
			PrintManagement.AttachArea(PrintForm, Area, False);
			
			Area = PrintManagement.TemplateArea(Template, Areas[TemplateName]["TableRow"]);
			PrintManagement.JoinAndFillCollection(PrintForm, Area, ObjectData.Goods, False);
		EndIf;
					
		PrintFormStorageAddress = PrintManagement.GenerateDocument(PrintForm);
	Except
		Common.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		ClosePrintFormWindow = True;
		Return "";
	EndTry;
	
	PrintManagement.ClearRefs(PrintForm, ClosePrintFormWindow);
	PrintManagement.ClearRefs(Template);
	
	Return PrintFormStorageAddress;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
