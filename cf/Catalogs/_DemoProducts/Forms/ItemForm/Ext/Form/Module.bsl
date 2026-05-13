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
	
	// Set a value to the PictureURL attribute.
	If Not ValueIsFilled(Object.Ref) Then
		If Not Object.PicturesFile.IsEmpty() Then
			PictureAddress = GetPictureURL(Object.PicturesFile, UUID);
		Else
			PictureAddress = "";
		EndIf;
	EndIf;
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	// StandardSubsystems.Properties
	LabelsDisplayParameters = PropertyManager.LabelsDisplayParameters();
	LabelsDisplayParameters.LabelsDestinationElementName = "GroupLabels";
	LabelsDisplayParameters.MaxLabelsOnForm = 3;
	LabelsDisplayParameters.LabelsDisplayOption = Enums.LabelsDisplayOptions.Label;

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("LabelsDisplayParameters", LabelsDisplayParameters);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnCreateAccessValueForm(ThisObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.MonitoringCenter
	
	// Calculate how many times the form was created, using standard dot delimiter (.).
	Comment = String(GetClientConnectionSpeed());
	MonitoringCenter.WriteBusinessStatisticsOperation("Catalog._DemoProducts.OnCreateAtServer", 1,
		Comment);
	
	// Calculate how many times the form was created with a picture and without a picture, using custom semicolon delimiter (;).
	If ValueIsFilled(PictureAddress) Then
		BusinessStatisticsParameter = "HasPicture";
	Else
		BusinessStatisticsParameter = "NoPicture";
	EndIf;
	OperationName = "Catalog;_DemoProducts;OnCreateAtServer;" + BusinessStatisticsParameter;
	MonitoringCenter.WriteBusinessStatisticsOperation(OperationName, 1, Comment, ";");
	
	// End StandardSubsystems.MonitoringCenter
	
	
	// StandardSubsystems.StoredFiles
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";

	FieldParameters = FilesOperations.FileField();
	FieldParameters.Location  = "GroupPicture";
	FieldParameters.DataPath = "Object.PicturesFile";
	FieldParameters.PathToPictureData = "PictureAddress";

	ItemsToAdd1 = New Array;
	ItemsToAdd1.Add(HyperlinkParameters);
	ItemsToAdd1.Add(FieldParameters);

	SettingsOfFileManagementInForm = FilesOperations.SettingsOfFileManagementInForm();
	SettingsOfFileManagementInForm.DuplicateAttachedFiles = True;
	FilesOperations.OnCreateAtServer(ThisObject, ItemsToAdd1, SettingsOfFileManagementInForm);
	// End StandardSubsystems.StoredFiles
	
	// StandardSubsystems.NationalLanguageSupport
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.NationalLanguageSupport
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.PerformanceMonitor
	MeasurementUUID1 = PerformanceMonitorClient.TimeMeasurement("_DemoOnOpenManualMeasurement", False,
		False);
	PerformanceMonitorClient.StopTimeMeasurement(MeasurementUUID1);
	// End StandardSubsystems.PerformanceMonitor
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.StoredFiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.StoredFiles
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
    // End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.StoredFiles
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.StoredFiles

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	If Not CurrentObject.PicturesFile.IsEmpty() Then
		PictureAddress = GetPictureURL(CurrentObject.PicturesFile, UUID);
	Else
		PictureAddress = "";
	EndIf;

	RecordedProductKind = CurrentObject.ProductKind;
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AccountingAudit
	AccountingAudit.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccountingAudit
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.NationalLanguageSupport
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.NationalLanguageSupport
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
    // End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.NationalLanguageSupport
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.NationalLanguageSupport

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)

	RecordedProductKind = CurrentObject.ProductKind;
	
	// StandardSubsystems.StoredFiles
	FilesOperations.OnWriteAtServer(Cancel, CurrentObject, WriteParameters, ThisObject);
	// End StandardSubsystems.StoredFiles
	

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	// StandardSubsystems.NationalLanguageSupport
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.NationalLanguageSupport

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductKindOnChange(Item)
	
	// StandardSubsystems.Properties
	UpdateAdditionalAttributesItems();
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure OriginCountryChoiceProcessing(Item, ValueSelected, StandardProcessing)
	// StandardSubsystems.ContactInformation
	ContactsManagerClient.WorldCountryChoiceProcessing(Item, ValueSelected, StandardProcessing);
	// End StandardSubsystems.ContactInformation
EndProcedure

// StandardSubsystems.StoredFiles
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters,
		StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters,
		StandardProcessing);

EndProcedure
// End StandardSubsystems.StoredFiles

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined,
	StandardProcessing = Undefined)

	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);

EndProcedure

// End StandardSubsystems.Properties


// StandardSubsystems.ImportDataFromFile

&AtClient
Procedure LoadingFromFile(Command)

	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "_DemoProducts.Substitutes";
	ImportParameters.Title = NStr("ru = 'Загрузка списка аналогов из файла';
										|en = 'Import list of substitutes from file';");
	
	// Describes columns for a picking import template.
	ImportParameters.TemplateColumns = DetailsOfTemplateColumnsToImportSubstitutes();
	ImportParameters.AdditionalParameters.Insert("ProductKind", Object.ProductKind);

	Notification = New NotifyDescription("ImportSubstituteProductsFromFileCompletion", ThisObject);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);

EndProcedure

// End StandardSubsystems.ImportDataFromFile

// StandardSubsystems.StoredFiles
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.StoredFiles

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure ImageAlbumToPDF(Command)
	Pictures = AttachedImages(Object.Ref);
	NotifyDescription = New NotifyDescription("ImageAlbumToPDFCompletion", ThisObject);
	GraphicDocumentConversionParameters = FilesOperationsClient.GraphicDocumentConversionParameters();
	FilesOperationsClient.CombineToMultipageFile(NotifyDescription, Pictures,
		GraphicDocumentConversionParameters);
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function GetPictureURL(PicturesFile, FormIdentifier)

	Try

		FileParameters = FilesOperationsClientServer.FileDataParameters();
		FileParameters.FormIdentifier = FormIdentifier;
		FileParameters.RaiseException1 = False;
		Return FilesOperations.FileData(PicturesFile, FileParameters).RefToBinaryFileData;

	Except
		Return Undefined;
	EndTry;

EndFunction

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisObject,,
		RecordedProductKind <> Object.ProductKind);

EndProcedure

// End StandardSubsystems.Properties

// StandardSubsystems.ImportDataFromFile

&AtServer
Function DetailsOfTemplateColumnsToImportSubstitutes()

	TemplateColumns = ImportDataFromFile.GenerateColumnDetails(Object.Substitutes);
	ImportDataFromFileClientServer.DeleteTemplateColumn("Substitute", TemplateColumns);
	
	NameOfTypeOfProduct = Common.ObjectAttributeValue(Object.ProductKind, "Description");
	If NameOfTypeOfProduct = "OperationService" Then
		// Services have no barcode.
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("BarcodeSKU",
			Common.StringTypeDetails(20), NStr("ru = 'Артикул';
															|en = 'Product ID';"));
	Else
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("BarcodeSKU",
			Common.StringTypeDetails(20), NStr("ru = 'Штрихкод и Артикул';
															|en = 'Barcode and Product ID';"));
	EndIf;
	Column.IsRequiredInfo = True;
	Column.Position = 1;
	Column.Group = NStr("ru = 'Номенклатура';
							|en = 'Products';");
	Column.Parent = "Substitute";
	Column.ToolTip = NStr("ru = 'Штрихкод аналогичного товара для сопоставления.';
							|en = 'Barcode of similar goods for mapping.';");
	TemplateColumns.Add(Column);

	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Description",
		Common.StringTypeDetails(100));
	Column.Group = NStr("ru = 'Номенклатура';
							|en = 'Products';");
	Column.Title = NStr("ru = 'Номенклатура';
							|en = 'Products';");
	Column.Parent = "Substitute";
	Column.Position = 2;
	Column.ToolTip = NStr("ru = 'Наименование аналогичного товара, который полностью идентичен
							 |по своему функциональному назначению и техническим характеристикам.';
							|en = 'Description of similar goods that are identical
							|by their purpose and technical characteristics.';");
	TemplateColumns.Add(Column);

	Column = ImportDataFromFileClientServer.TemplateColumn("Compatibility", TemplateColumns);
	Column.Title = NStr("ru = 'Совместимость';
							|en = 'Compatibility';");
	Column.Position = 3;

	Return TemplateColumns;
EndFunction

&AtClient
Procedure ImportSubstituteProductsFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export

	If ImportedDataAddress = Undefined Then
		Return;
	EndIf;

	ImportSubstitutesFromServerFile(ImportedDataAddress);

EndProcedure

&AtServer
Procedure ImportSubstitutesFromServerFile(ImportedDataAddress)

	ImportedData = GetFromTempStorage(ImportedDataAddress);

	ProductsAdded_ = False;

	For Each TableRow In ImportedData Do
		If Not ValueIsFilled(TableRow.Substitute) Then
			Continue;
		EndIf;

		NewLineProducts = Object.Substitutes.Add();
		FillPropertyValues(NewLineProducts, TableRow);
		ProductsAdded_ = True;
	EndDo;

	If ProductsAdded_ Then
		Modified = True;
	EndIf;

EndProcedure

// End StandardSubsystems.ImportDataFromFile

// StandardSubsystems.ObjectAttributesLock

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)

	ObjectAttributesLockClient.AllowObjectAttributeEdit(ThisObject);

EndProcedure

// End StandardSubsystems.ObjectAttributesLock

// StandardSubsystems.AccountingAudit

&AtClient
Procedure Attachable_OpenIssuesReport(ItemOrCommand, Var_URL, StandardProcessing)
	AccountingAuditClient.OpenObjectIssuesReport(ThisObject, Object.Ref, StandardProcessing);
EndProcedure

// End StandardSubsystems.AccountingAudit

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
EndProcedure

&AtServerNoContext
Function AttachedImages(FileOwner)

	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	_DemoProductsAttachedFiles.Ref AS Ref
	|FROM
	|	Catalog._DemoProductsAttachedFiles AS _DemoProductsAttachedFiles
	|WHERE
	|	_DemoProductsAttachedFiles.FileOwner = &FileOwner
	|	AND _DemoProductsAttachedFiles.Extension IN (&ImageExtensions)";

	Query.SetParameter("FileOwner", FileOwner);
	ImageExtensions = StrSplit(Lower("BMP,JPG,GIF,PNG,TIF"), ",");
	Query.SetParameter("ImageExtensions", ImageExtensions);

	Return Query.Execute().Unload().UnloadColumn("Ref");

EndFunction

&AtClient
Procedure ImageAlbumToPDFCompletion(Result, AdditionalParameters) Export
	If Result.Success Then
		FileSystemClient.OpenFile(Result.ResultFileName);
	Else
		CommonClient.MessageToUser(Result.ErrorDescription);
	EndIf;
EndProcedure

#EndRegion