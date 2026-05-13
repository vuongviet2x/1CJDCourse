///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Private

#Region Surveys

Procedure FillNote(ObjectsArray, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	OpenForm("CommonForm._DemoRemark", 
		New Structure("AttachableCommandsParameters", Form.AttachableCommandsParameters), 
		Form, Form.UUID);	
	
EndProcedure

#EndRegion

#Region Core

// See CommonClientOverridable.
Procedure SuggestOpenWebSiteOnStart(Parameters, AdditionalParameters) Export
	
	Notification = New NotifyDescription("SuggestOpenWebSiteOnStartCompletion", ThisObject, Parameters);
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
		"ru = 'Перед началом работы с приложением рекомендуется ознакомиться с его документацией.
		|Перейти на сайт сейчас?
		|
		|Этот пример демонстрирует открытие диалогов, блокирующих запуск приложения,
		|из общего модуля %1.';
		|en = 'We recommend that you read the documentation first before using the application.
		|Visit the website now?
		|
		|This example demonstrates blocking dialogs implemented
		|in the %1 common module.';"),
		"CommonClientOverridable");
		
	Buttons = New ValueList();
	Buttons.Add("GoTo", NStr("ru = 'Перейти на сайт';
									|en = 'Visit website';"));
	Buttons.Add("Continue", NStr("ru = 'Продолжить';
										|en = 'Continue';"));
	Buttons.Add("ExitApp", NStr("ru = 'Завершить работу';
										|en = 'End session';"));
	Buttons.Add("Restart", NStr("ru = 'Перезапустить приложение';
											|en = 'Restart application';"));
	
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.Title = NStr("ru = 'Переход на сайт';
										|en = 'Visit our website';");
	QuestionParameters.LockWholeInterface = True;
	
	StandardSubsystemsClient.ShowQuestionToUser(Notification, QueryText, Buttons, QuestionParameters);
	
EndProcedure

Procedure SuggestOpenWebSiteOnStartCompletion(QuestionResult, Parameters) Export
	
	If QuestionResult <> Undefined Then
		If QuestionResult.Value = "GoTo" Then
			FileSystemClient.OpenURL(
				StandardSubsystemsClient.ClientParametersOnStart().ConfigurationWebsiteAddress);
		ElsIf QuestionResult.Value = "ExitApp" Then
			Parameters.Cancel = True;
		ElsIf QuestionResult.Value = "Restart" Then
			Parameters.Cancel = True;
			Parameters.Restart = True;
		EndIf;
		
		If QuestionResult.NeverAskAgain Then
			CommonServerCall.CommonSettingsStorageSave(
				"UserCommonSettings",
				"SuggestOpenWebSiteOnStart",
				False);
		EndIf;
	EndIf;
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

#EndRegion

#Region ReportsOptions

// See ReportsClientOverridable.HandlerCommands.
Procedure StartReportEditing(ReportForm) Export 
	
	FormParameters = StandardSubsystemsClient.SpreadsheetEditorParameters();
	FormParameters.DocumentName = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Редактирование таблицы сформированного отчета ""%1""';
			|en = 'Editing the table of the ""%1"" generated report';"),
		ReportForm.Title);
	FormParameters.Edit = True;
	StandardSubsystemsClient.ShowSpreadsheetEditor(ReportForm.ReportSpreadsheetDocument, FormParameters);
	
EndProcedure

// See ReportsClientOverridable.HandlerCommands.
Procedure RegisterSelectedReportAreas(ReportForm, DataCategory) Export 
	
	If StrEndsWith(DataCategory, "InvalidData") Then 
		ColorOfDesign = WebColors.LightPink;
	ElsIf StrEndsWith(DataCategory, "CorrectData") Then 
		ColorOfDesign = WebColors.LightGreen;
	ElsIf StrEndsWith(DataCategory, "DubiousData") Then 
		ColorOfDesign = WebColors.LightYellow;
	Else
		Return;
	EndIf;
	
	SpreadsheetDocument = ReportForm.ReportSpreadsheetDocument;
	For Each Area In SpreadsheetDocument.SelectedAreas Do 
		For LineNumber = Area.Top To Area.Bottom Do 
			For ColumnNumber = Area.Left To Area.Right Do 
				Cell = SpreadsheetDocument.Area(LineNumber, ColumnNumber); // SpreadsheetDocumentRange
				Cell.BackColor = ColorOfDesign;
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

#Region AccountingAudit

// Opens the form for posting _DemoTaxInvoiceReceived documents
// that are detected by the unposted document search check.
// See _DemoStandardSubsystems.CheckReceivedTaxInvoicePosting.
//
// Parameters:
//    PatchParameters  - Structure:
//      * CheckID - String - Check string ID.
//      * CheckKind           - CatalogRef.ChecksKinds - Kind the performed check belongs to.
//                                
//    AdditionalParameters - Undefined - Obsolete parameter.
//
Procedure PostTaxInvoicesForTroublesomeCounterparties(PatchParameters, AdditionalParameters) Export
	
	OpenForm("Document._DemoTaxInvoiceReceived.Form.DocumentsPosting", PatchParameters);
	
EndProcedure

#EndRegion

#Region ContactInformation

// Opens a filled form of the "Appointment" document.
// 
// Parameters:
//  ContactInformation    - 
//  AdditionalParameters - 
//
Procedure OpenMeetingDocForm(ContactInformation, AdditionalParameters) Export

	FillingValues = New Structure;
	FillingValues.Insert("MeetingPlace", ContactInformation.Presentation);
	If TypeOf(AdditionalParameters.ContactInformationOwner) = Type("DocumentRef._DemoSalesOrder") Then
		FillingValues.Insert("SubjectOf", AdditionalParameters.ContactInformationOwner);
		FillingValues.Insert("Contact", "");
	Else
		FillingValues.Insert("Contact", AdditionalParameters.ContactInformationOwner);
		FillingValues.Insert("SubjectOf", "");
	EndIf;

	OpenForm("Document.Meeting.ObjectForm", New Structure("FillingValues", FillingValues),
		AdditionalParameters.Form);

EndProcedure	

#EndRegion

#Region MachineReadableLettersOfAuthority

// See "MachineReadableLettersOfAuthorityFTSClientOverridable.OnChangeLetterOfAuthorityStatus".
Procedure OnChangeLetterOfAuthorityStatus(StatusesOfAuthorizationLetters) Export
	If StatusesOfAuthorizationLetters.Count() = 1 Then
		Text = NStr("ru = 'Демо: Изменился статус МЧД';
					|en = 'Demo: Status of letter of authority changed';");
		For Each StatusOfLetterOfAuthority In StatusesOfAuthorizationLetters Do
			URL = GetURL(StatusOfLetterOfAuthority.Key);
			Explanation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1: %2';
					|en = '%1: %2';"),
				StatusOfLetterOfAuthority.Value.NewStatus, StatusOfLetterOfAuthority.Key);
		EndDo;
	Else
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Демо: Изменился статус МЧД (%1)';
				|en = 'Demo: Statuses of letters of authority changed (%1)';"),
			StatusesOfAuthorizationLetters.Count());
		URL = "e1cib/list/Catalog.MachineReadableLettersOfAuthorityFTS";
		Explanation = NStr("ru = 'Открыть список';
						|en = 'Open list';");
	EndIf;
	
	ShowUserNotification(Text, URL, Explanation);
EndProcedure

// See "MachineReadableLettersOfAuthorityFTSClientOverridable.OnLOARegistration".
Procedure OnLOARegistration(LetterOfAuthority, StandardProcessing, CompletionHandler) Export
	
	StandardProcessing = False;
	NotifyDescription = New NotifyDescription("OnLOARegistrationFollowUp", ThisObject, CompletionHandler);
	QueryText = NStr("ru = 'Будет выполнена регистрация доверенности в реестре ФТС. Продолжить?';
						|en = 'The letter of authority will be registered in the Federal Customs Service registry. Continue?';");
	ShowQueryBox(NotifyDescription, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	
EndProcedure

Procedure OnLOARegistrationFollowUp(QuestionResult, CompletionHandler) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ExecuteNotifyProcessing(CompletionHandler);
	EndIf;
	
EndProcedure

#EndRegion

#Region Print

// Checks unposted document print output.
//  Runs before preparing a document for printing
//  ("Demo: Unposted document print" is used as an additional right with access restriction).
//
// Parameters:
//  PrintParameters - See PrintManagementClient.DescriptionOfPrintParameters
//
// Returns:
//  Undefined - Do not return the result.
//
Function CheckPrintPermission(PrintParameters) Export
	ShowMessageBox(, _DemoStandardSubsystemsServerCall.PrintingEnabled(PrintParameters.PrintObjects[0]));
	Return Undefined;
EndFunction

#EndRegion

#Region AttachableCommands

// Parameters:
//  ReferencesArrray - Array of CatalogRef
//  ExecutionParameters - Structure:
//    * Form - ClientApplicationForm:
//     ** Object - FormDataStructure:
//      *** Description - String
//
Procedure FillDescription(ReferencesArrray, ExecutionParameters) Export
	
	Object = ExecutionParameters.Form.Object;
	NewValue = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Наименование заполнено %1.';
			|en = 'The description is populated %1.';"),
		Format(CommonClient.SessionDate(), "DF=yyyy-MM-dd"));
	
	If Not IsBlankString(Object.Description) And Object.Description = NewValue Then
		ShowUserNotification(, , NStr("ru = 'Наименование уже заполнено.';
												|en = 'The description is already populated.';"), PictureLib.DialogInformation);
		Return;
	EndIf;
	
	Object.Description = NewValue;
	ShowUserNotification(, , NStr("ru = 'Наименование успешно заполнено.';
											|en = 'The description is successfully populated.';"), PictureLib.Success32);
	ExecutionParameters.Form.Modified = True;

EndProcedure

#EndRegion

#Region DigitalSignature

// See DigitalSignatureOverridable.OnAdditionalCertificateCheck.
Procedure OnAdditionalCertificateCheck(Parameters) Export
	
	Context = New Structure;
	Context.Insert("Parameters", Parameters);
	
	If Parameters.Validation = "TestOperationConnection" Then
		
		Parameters.WaitForContinue = True;
		BeginAttachingFileSystemExtension(New NotifyDescription(
			"OnAdditionalCertificateCheckAfterAttachFileSystemExtension", ThisObject, Context));
		
	EndIf;
	
EndProcedure

// Continuation of the OnAdditionalCertificateCheck procedure.
//
// Parameters:
//  Context - Structure:
//   * Parameters - See DigitalSignatureOverridable.OnAdditionalCertificateCheck.Parameters
//
Procedure OnAdditionalCertificateCheckAfterAttachFileSystemExtension(Attached, Context) Export
	
	ExecuteNotifyProcessing(Context.Parameters.Notification);
	
EndProcedure

// See DigitalSignatureClientOverridable.AfterAddingElectronicSignatureCertificatesToDirectory.
Procedure AfterAddingElectronicSignatureCertificatesToDirectory(Parameters) Export
	
	For Each Certificate In Parameters.Certificates Do
		
		If Not ValueIsFilled(Certificate.OldCertificate) Then
			Continue;
		EndIf;
		
		ShowUserNotification(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Вместо сертификата %1 выпущен сертификат %2';
				|en = 'Certificate %2 replaces %1';"), Certificate.OldCertificate,
			Certificate.NewCertificate),,,,UserNotificationStatus.Important);
		
	EndDo
	
EndProcedure

#EndRegion

#Region MonitoringCenter

Procedure OnStartMonitoringCenterSystem() Export
    
    SystemInfo = New SystemInfo();
    RAM = Format((Int(SystemInfo.RAM/512) + 1) * 512, "NG=0");
    OperationName = "_DemoClientStatistics.SystemInformation.RAM." + RAM; 
    
    MonitoringCenterClient.WriteBusinessStatisticsOperationDay(OperationName, 1);
    
EndProcedure

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated. Checks backward compatibility of the "Print tools" subsystem API.
// Generates the _DemoCustomerProformaInvoice document print forms using a template in the office document format.
//
// Parameters:
//  PrintParameters - See PrintManagementClient.DescriptionOfPrintParameters
//
// Returns:
//  Undefined - Do not return the result.
//
Function PrintCustomerProformaInvoices(PrintParameters) Export
	
#If WebClient Then
	Raise NStr("ru = 'Для формирования этой печатной формы воспользуйтесь тонким клиентом.';
							|en = 'Use thin client to generate this print from.';");
#EndIf
	
	PrintManagerName = PrintParameters.PrintManager;
	TemplateName = PrintParameters.Id;
	DocumentsComposition = PrintParameters.PrintObjects;
	
	MessageText = ?(DocumentsComposition.Count() > 1, 
		NStr("ru = 'Выполняется формирование печатных форм...';
			|en = 'Generating print forms…';"),
		NStr("ru = 'Выполняется формирование печатной формы...';
			|en = 'Generating a print form…';"));
	Status(MessageText);
	
	ObjectTemplateAndData = PrintManagementServerCall.TemplatesAndObjectsDataToPrint(PrintManagerName, TemplateName, DocumentsComposition);
	
	For Each DocumentRef In DocumentsComposition Do
		PrintCustomerProformaInvoice(DocumentRef, ObjectTemplateAndData, TemplateName);
	EndDo;
	
	Return Undefined;
	
EndFunction

// Deprecated. Checks backward compatibility of the "Print tools" subsystem API.
// Generates the _DemoCustomerProformaInvoice document print form using a template in the office document format.
//
Procedure PrintCustomerProformaInvoice(DocumentRef, ObjectTemplateAndData, TemplateName)
	
	TemplateType				= ObjectTemplateAndData.Templates.TemplateTypes[TemplateName];
	TemplatesBinaryData	= ObjectTemplateAndData.Templates.TemplatesBinaryData;
	Areas					= ObjectTemplateAndData.Templates.AreasDetails;
	ObjectData = ObjectTemplateAndData.Data[DocumentRef][TemplateName];
	
	Template = PrintManagementClient.InitializeOfficeDocumentTemplate(TemplatesBinaryData[TemplateName], TemplateType, TemplateName);
	If Template = Undefined Then
		Return;
	EndIf;
	
	ClosePrintFormWindow = False;
	Try
		PrintForm = PrintManagementClient.InitializePrintForm(TemplateType, Template.TemplatePagesSettings, Template);
		If PrintForm = Undefined Then
			PrintManagementClient.ClearRefs(Template);
			Return;
		EndIf;
		
		// Display document headers and footers.
		Area = PrintManagementClient.TemplateArea(Template, Areas[TemplateName]["Header"]);
		PrintManagementClient.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
		
		Area = PrintManagementClient.TemplateArea(Template, Areas[TemplateName]["Footer"]);
		PrintManagementClient.AttachArea(PrintForm, Area);
		
		// Display the document header: Common area with parameters.
		Area = PrintManagementClient.TemplateArea(Template, Areas[TemplateName]["Title"]);
		PrintManagementClient.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
		
		// Export data collection from the infobase as a table.
		Area = PrintManagementClient.TemplateArea(Template, Areas[TemplateName]["TableHeaderProductsText"]);
		PrintManagementClient.AttachArea(PrintForm, Area, False);
		Area = PrintManagementClient.TemplateArea(Template, Areas[TemplateName]["ProductsTableHeader"]);
		PrintManagementClient.AttachArea(PrintForm, Area, False);
		Area = PrintManagementClient.TemplateArea(Template, Areas[TemplateName]["RowTableProducts"]);
		PrintManagementClient.JoinAndFillCollection(PrintForm, Area, ObjectData.Goods, False);
		
		// Export data collection from the infobase as a numbered list.
		Area = PrintManagementClient.TemplateArea(Template, Areas[TemplateName]["TheProductsNomenclatureHeader"]);
		PrintManagementClient.AttachArea(PrintForm, Area, False);
		Area = PrintManagementClient.TemplateArea(Template, Areas[TemplateName]["GoodsProducts"]);
		PrintManagementClient.JoinAndFillCollection(PrintForm, Area, ObjectData.Goods, False);
		
		// Export data collection from the infobase as a list.
		Area = PrintManagementClient.TemplateArea(Template, Areas[TemplateName]["TheProductsTotalHeader"]);
		PrintManagementClient.AttachArea(PrintForm, Area, False);
		Area = PrintManagementClient.TemplateArea(Template, Areas[TemplateName]["GoodsTotal"]);
		PrintManagementClient.JoinAndFillCollection(PrintForm, Area, ObjectData.Goods, False);
		
		// Display the document footer: Common area with parameters.
		Area = PrintManagementClient.TemplateArea(Template, Areas[TemplateName]["BottomPart"]);
		PrintManagementClient.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
		
		PrintManagementClient.ShowDocument(PrintForm);
	Except
		CommonClient.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		ClosePrintFormWindow = True;
		Return;
	EndTry;
	
	PrintManagementClient.ClearRefs(PrintForm, ClosePrintFormWindow);
	PrintManagementClient.ClearRefs(Template);
	
EndProcedure

#EndRegion

#EndRegion
